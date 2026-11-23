MODULE PmGantt;
(* PmGantt: Mermaid's Gantt charts (`gantt`), read into a model of their
   own: the tasks, in order, each with its start and end, its section,
   and its tags; and the settings the chart is drawn with.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   gantt/parser/gantt.jison, whose lexer tries its rules in order at
   each token, and what ganttDb.js makes of the tokens:

   - "%%" starts a comment to the end of the line, as does a "%" at a
     token's start, or after any character but "}";
   - the keywords are read in any case: "dateFormat", "axisFormat",
     "tickInterval", "includes" and "excludes" take the rest of the
     line up to a "#" or ";"; "todayMarker" up to a ";"; "title" and
     "section" the rest of the line; "inclusiveEndDates", "topAxis",
     "weekday monday" ... and "weekend friday" or "saturday" take
     nothing;
   - "click id" with "href "link"" or "call name(args)", or both: the
     tasks with the ids, separated by ",", are clickable, and href
     links them;
   - a task is text up to a ":", then its data up to a "#", ";" or the
     end of the line: tags ("active", "done", "crit", "milestone",
     "vert"), then one to three fields: the end; the start and the end;
     or the id, the start and the end. A start is a date, read with
     the dateFormat, or "after id ...", the latest end of those tasks;
     an end is a date, a duration ("3d", "1.5w", "2M", "30m", "10ms"),
     or "until id ...", the earliest start of those tasks. A task with
     only the end starts where the task before it ends.

   The dates are computed as ganttDb.js's getTasks computes them, in
   up to 11 passes, with the excludes, by PmGanttTime. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml, T := PmGanttTime;

CONST
  (* how a task's start is given *)
  AfterPrevious = 0; FromData = 1;

TYPE
  Str = L.Str;

  (* A list of words: includes and excludes, section names *)
  Word* = POINTER TO WordDesc;
  WordDesc* = RECORD
    s*: Str;
    next*: Word
  END;

  Task* = POINTER TO TaskDesc;
  TaskDesc* = RECORD
    text*: Str;           (* trimmed *)
    id*: Str;             (* given, or "task1", "task2" ... *)
    section*: Str;        (* "" before the first section *)
    start*, end*: HUGEINT;    (* milliseconds, PmGanttTime's *)
    renderEnd*: HUGEINT;  (* the end drawn, with excludes *)
    hasRenderEnd*: BOOLEAN;
    active*, done*, crit*, milestone*, vert*: BOOLEAN;
    clickable*: BOOLEAN;  (* named by a click *)
    link*: Str;           (* href's, or NIL *)
    order*: LONGINT;      (* from 0, in order, but -1 for vert *)
    index*: LONGINT;      (* from 0, in order *)
    next*: Task;
    pos: LONGINT;         (* where it is in the text *)
    kind: INTEGER;
    prevId, startData, endData: Str;
    startSet, endSet, processed, manualEnd: BOOLEAN
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;          (* the title and the configuration *)
    dateFormat*: Str;     (* trimmed; "" if none *)
    axisFormat*: Str;     (* as given; NIL if none *)
    tickInterval*: Str;   (* as given; NIL if none *)
    todayMarker*: Str;    (* as given; "" if none *)
    inclusiveEndDates*, topAxis*, compact*: BOOLEAN;
    weekday*: LONGINT;    (* the weeks' first day, 0 Sunday .. 6 Saturday *)
    weekend*: LONGINT;    (* the weekend's first day: 5 Friday, 6 Saturday *)
    includes*, excludes*: Word;
    sections*: Word;      (* as named, in order *)
    tasks*: Task; nTasks*: LONGINT;
    last: Task; lastSection: Word
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  section: Str;           (* the current section *)
  lastId: Str;            (* the last task's id, or NIL *)
  taskCount, lastOrder: LONGINT;
  msg: ARRAY 1024 OF CHAR; mlen: LONGINT;

(* Messages *)

PROCEDURE M(s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) & (mlen < LEN(msg) - 1) DO
    msg[mlen] := s[i]; INC(mlen); INC(i)
  END;
  msg[mlen] := 0X
END M;

PROCEDURE M0(s: ARRAY OF CHAR);
BEGIN
  mlen := 0; M(s)
END M0;

(* n in decimal, appended to the message *)
PROCEDURE MInt(n: LONGINT);
  VAR d: ARRAY 24 OF CHAR; c: ARRAY 2 OF CHAR; k: INTEGER;
BEGIN
  c[1] := 0X; k := 0;
  REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  WHILE k > 0 DO DEC(k); c[0] := d[k]; M(c) END
END MInt;

(* The lexer *)

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether ch is white space, as a regular expression's \s *)
PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN L.IsBlank(ch) OR (ch = 0AX) OR (ch = 0DX) OR (ch = 0CX) OR (ch = 0BX)
END IsSpace;

PROCEDURE At(p: LONGINT): CHAR;
BEGIN
  IF (p >= 0) & (p < sc.len) THEN RETURN sc.t[p] END;
  RETURN 0X
END At;

(* Whether the text at p is w, which is in lower case, in any case *)
PROCEDURE LookingAtIAt(p: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF Lower(At(p + i)) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END LookingAtIAt;

PROCEDURE LookingAtI(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN LookingAtIAt(sc.pos, w)
END LookingAtI;

(* Whether ch is one of stops, or a line end *)
PROCEDURE Stop(ch: CHAR; stops: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF (ch = 0AX) OR (ch = 0X) THEN RETURN TRUE END;
  i := 0;
  WHILE (i < LEN(stops)) & (stops[i] # 0X) DO
    IF ch = stops[i] THEN RETURN TRUE END;
    INC(i)
  END;
  RETURN FALSE
END Stop;

(* The rule w\s[^stops\n]+: whether the text at the position is it; if
   so, its value, after the keyword and the white space character, is
   in v, and the position is after it *)
PROCEDURE KwValue(w, stops: ARRAY OF CHAR; VAR v: Str): BOOLEAN;
  VAR n, k, e: LONGINT;
BEGIN
  n := L.Length(w);
  IF ~LookingAtI(w) OR ~IsSpace(At(sc.pos + n)) THEN RETURN FALSE END;
  k := sc.pos + n + 1; e := k;
  WHILE (e < sc.len) & ~Stop(sc.t[e], stops) DO INC(e) END;
  IF e = k THEN RETURN FALSE END;
  v := L.Sub(sc.t^, k, e - k); sc.pos := e;
  RETURN TRUE
END KwValue;

(* The rule w\s+day: whether the text at the position is it; if so, the
   position is after it *)
PROCEDURE KwDay(w, day: ARRAY OF CHAR): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  IF ~LookingAtI(w) THEN RETURN FALSE END;
  k := sc.pos + L.Length(w);
  IF ~IsSpace(At(k)) THEN RETURN FALSE END;
  WHILE IsSpace(At(k)) DO INC(k) END;
  IF ~LookingAtIAt(k, day) THEN RETURN FALSE END;
  sc.pos := k + L.Length(day);
  RETURN TRUE
END KwDay;

(* s with the white space at its ends taken off, as JavaScript's trim *)
PROCEDURE TrimStr(VAR s: ARRAY OF CHAR; start, end: LONGINT): Str;
BEGIN
  WHILE (start < end) & IsSpace(s[start]) DO INC(start) END;
  WHILE (end > start) & IsSpace(s[end - 1]) DO DEC(end) END;
  RETURN L.Sub(s, start, end - start)
END TrimStr;

PROCEDURE Trim(s: Str): Str;
BEGIN
  RETURN TrimStr(s^, 0, L.Length(s^))
END Trim;

(* Adds the words of s, split at white space and ",", in lower case,
   to list, each once, as mergeTokens does *)
PROCEDURE Merge(VAR list: Word; s: Str);
  VAR i, k, n: LONGINT; w: Str; p, last: Word; found: BOOLEAN;
BEGIN
  n := L.Length(s^); i := 0;
  WHILE i < n DO
    WHILE (i < n) & (IsSpace(s[i]) OR (s[i] = ",")) DO INC(i) END;
    k := i;
    WHILE (k < n) & ~IsSpace(s[k]) & (s[k] # ",") DO s[k] := Lower(s[k]); INC(k) END;
    IF k > i THEN
      w := L.Sub(s^, i, k - i);
      p := list; last := NIL; found := FALSE;
      WHILE p # NIL DO
        IF L.Equal(p.s, w) THEN found := TRUE END;
        last := p; p := p.next
      END;
      IF ~found THEN
        NEW(p); p.s := w; p.next := NIL;
        IF last = NIL THEN list := p ELSE last.next := p END
      END
    END;
    i := k
  END
END Merge;

(* Whether w is in list *)
PROCEDURE In(list: Word; w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  WHILE list # NIL DO
    IF L.Is(list.s, w) THEN RETURN TRUE END;
    list := list.next
  END;
  RETURN FALSE
END In;

(* The last task so far with the id, as findTaskById finds it, or NIL *)
PROCEDURE Find(id: ARRAY OF CHAR): Task;
  VAR t, r: Task;
BEGIN
  r := NIL; t := d.tasks;
  WHILE t # NIL DO
    IF L.Is(t.id, id) THEN r := t END;
    t := t.next
  END;
  RETURN r
END Find;

(* Statements *)

(* "click ids" with href and call: the tasks are clickable, and href
   links them *)
PROCEDURE Click;
  VAR start: LONGINT; ids, link: Str; hasHref, hasCall: BOOLEAN; t: Task;
    i, k, n: LONGINT; id: Str;

  (* Whether the text at the position is w followed by white space; if
     so, the position is after the white space *)
  PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
    VAR k: LONGINT;
  BEGIN
    IF ~LookingAtI(w) OR ~IsSpace(sc.Peek(L.Length(w))) THEN RETURN FALSE END;
    k := sc.pos + L.Length(w);
    WHILE IsSpace(At(k)) DO INC(k) END;
    sc.pos := k;
    RETURN TRUE
  END Kw;

BEGIN
  (* "click" and the white space after it have been read *)
  start := sc.pos;
  WHILE (sc.pos < sc.len) & ~IsSpace(sc.Ch()) DO INC(sc.pos) END;
  ids := L.Sub(sc.t^, start, sc.pos - start);
  IF sc.pos < sc.len THEN INC(sc.pos) END;
  hasHref := FALSE; hasCall := FALSE; link := NIL;
  LOOP
    sc.SkipBlanks;
    IF ~hasHref & LookingAtI("href") & IsSpace(sc.Peek(4)) THEN
      k := sc.pos + 4; WHILE IsSpace(At(k)) DO INC(k) END;
      IF At(k) # 22X THEN EXIT END;
      sc.pos := k + 1; start := sc.pos;
      WHILE (sc.pos < sc.len) & (sc.Ch() # 22X) DO INC(sc.pos) END;
      IF sc.pos = start THEN sc.Error("href needs a link") END;
      link := L.Sub(sc.t^, start, sc.pos - start);
      IF sc.pos < sc.len THEN INC(sc.pos) END;
      hasHref := TRUE
    ELSIF ~hasCall & Kw("call") THEN
      start := sc.pos;
      WHILE (sc.pos < sc.len) & (sc.Ch() # "(") & (sc.Ch() # 0AX) DO INC(sc.pos) END;
      IF sc.pos = start THEN sc.Error("call needs a function's name") END;
      IF sc.Ch() = "(" THEN
        WHILE (sc.pos < sc.len) & (sc.Ch() # ")") DO INC(sc.pos) END;
        IF sc.pos < sc.len THEN INC(sc.pos) END
      END;
      hasCall := TRUE
    ELSE EXIT
    END
  END;
  IF ~hasHref & ~hasCall THEN sc.Error("expected href or call") END;
  (* the tasks *)
  n := L.Length(ids^); i := 0;
  WHILE i <= n DO
    k := i; WHILE (k < n) & (ids[k] # ",") DO INC(k) END;
    id := L.Sub(ids^, i, k - i);
    t := Find(id^);
    IF t # NIL THEN
      t.clickable := TRUE;
      IF hasHref THEN t.link := link END
    END;
    i := k + 1
  END
END Click;

(* A task: its text, and its data after the ":" *)
PROCEDURE TaskStmt;
  VAR start, textEnd, dataStart, n, i, k, idx, m: LONGINT; t: Task; data: Str;
    fields: POINTER TO ARRAY OF Str; matched: BOOLEAN;

  (* Whether field f is the tag, with white space around it *)
  PROCEDURE Tag(f: Str; tag: ARRAY OF CHAR): BOOLEAN;
    VAR s: Str;
  BEGIN
    s := Trim(f);
    RETURN L.Is(s, tag)
  END Tag;

  PROCEDURE TestTag(tag: ARRAY OF CHAR; VAR flag: BOOLEAN);
  BEGIN
    IF idx >= n THEN
      sc.ErrorAt(start, "a task needs more than its tags: its end, or its start and end")
    END;
    IF Tag(fields[idx], tag) THEN flag := TRUE; INC(idx); matched := TRUE END
  END TestTag;

BEGIN
  start := sc.pos;
  IF sc.Ch() = ":" THEN sc.Error("expected a task's text before the :") END;
  WHILE (sc.pos < sc.len) & (sc.Ch() # ":") & (sc.Ch() # 0AX) DO INC(sc.pos) END;
  textEnd := sc.pos;
  IF sc.Ch() # ":" THEN sc.ErrorAt(start, "expected a task: its text, a : and its data") END;
  INC(sc.pos); dataStart := sc.pos;
  WHILE (sc.pos < sc.len) & ~Stop(sc.Ch(), "#;") DO INC(sc.pos) END;
  IF sc.pos = dataStart THEN sc.ErrorAt(start, "expected the task's data after the :") END;
  data := L.Sub(sc.t^, dataStart, sc.pos - dataStart);

  NEW(t); t.text := TrimStr(sc.t^, start, textEnd); t.section := section;
  t.pos := start; t.next := NIL; t.link := NIL; t.clickable := FALSE;
  t.active := FALSE; t.done := FALSE; t.crit := FALSE; t.milestone := FALSE; t.vert := FALSE;
  t.startSet := FALSE; t.endSet := FALSE; t.processed := FALSE; t.manualEnd := FALSE;
  t.hasRenderEnd := FALSE; t.start := 0; t.end := 0; t.renderEnd := 0;
  t.prevId := NIL; t.startData := NIL; t.endData := NIL;

  (* the fields, split at "," *)
  n := 1; FOR i := 0 TO L.Length(data^) - 1 DO IF data[i] = "," THEN INC(n) END END;
  NEW(fields, n);
  i := 0; k := 0;
  WHILE k < n DO
    m := i; WHILE (data[m] # 0X) & (data[m] # ",") DO INC(m) END;
    fields[k] := L.Sub(data^, i, m - i); INC(k); i := m + 1
  END;
  (* the tags, as getTaskTags reads them *)
  idx := 0;
  REPEAT
    matched := FALSE;
    TestTag("active", t.active); TestTag("done", t.done); TestTag("crit", t.crit);
    TestTag("milestone", t.milestone); TestTag("vert", t.vert)
  UNTIL ~matched;
  FOR i := idx TO n - 1 DO fields[i] := Trim(fields[i]) END;
  m := n - idx;
  IF m = 1 THEN
    INC(taskCount); M0("task"); MInt(taskCount); t.id := L.New(msg);
    t.kind := AfterPrevious; t.prevId := lastId; t.endData := fields[idx]
  ELSIF m = 2 THEN
    INC(taskCount); M0("task"); MInt(taskCount); t.id := L.New(msg);
    t.kind := FromData; t.startData := fields[idx]; t.endData := fields[idx + 1]
  ELSE
    IF m > 3 THEN
      sc.ErrorAt(start, "a task has at most three fields after its tags: an id, its start and its end")
    END;
    t.id := fields[idx];
    t.kind := FromData; t.startData := fields[idx + 1]; t.endData := fields[idx + 2]
  END;
  IF t.vert THEN t.order := -1 ELSE t.order := lastOrder; INC(lastOrder) END;
  t.index := d.nTasks; INC(d.nTasks);
  IF d.last = NIL THEN d.tasks := t ELSE d.last.next := t END;
  d.last := t;
  lastId := t.id
END TaskStmt;

PROCEDURE SectionStmt(name: Str);
  VAR w: Word;
BEGIN
  section := Trim(name);
  NEW(w); w.s := section; w.next := NIL;
  IF d.lastSection = NIL THEN d.sections := w ELSE d.lastSection.next := w END;
  d.lastSection := w
END SectionStmt;

(* One of the lexer's tokens, and its statement, at the position *)
PROCEDURE Statement;
  VAR ch: CHAR; e, k: LONGINT; v: Str;
BEGIN
  ch := sc.Ch();
  IF sc.LookingAt("%%{") THEN
    e := sc.DirectiveEnd();
    IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
  ELSIF LookingAtI("acctitle") OR LookingAtI("accdescr") THEN
    k := sc.pos + 8; WHILE IsSpace(At(k)) DO INC(k) END;
    IF (At(k) = ":") OR LookingAtI("accdescr") & (At(k) = "{") THEN F.Accessibility
    ELSE TaskStmt
    END
  ELSIF (ch = "%") OR (ch # "}") & (sc.Peek(1) = "%") THEN sc.SkipLine
  ELSIF IsSpace(ch) THEN INC(sc.pos)
  ELSIF LookingAtI("href") & IsSpace(sc.Peek(4)) THEN
    k := sc.pos + 4; WHILE IsSpace(At(k)) DO INC(k) END;
    IF At(k) = 22X THEN sc.Error("href is only allowed after click id") END;
    TaskStmt
  ELSIF LookingAtI("call") & IsSpace(sc.Peek(4)) THEN
    sc.Error("call is only allowed after click id")
  ELSIF LookingAtI("click") & IsSpace(sc.Peek(5)) THEN
    INC(sc.pos, 5); WHILE IsSpace(sc.Ch()) DO INC(sc.pos) END;
    Click
  ELSIF LookingAtI("gantt") THEN sc.Error("unexpected gantt")
  ELSIF KwValue("dateformat", "#;", v) THEN d.dateFormat := Trim(v)
  ELSIF LookingAtI("inclusiveenddates") THEN INC(sc.pos, 17); d.inclusiveEndDates := TRUE
  ELSIF LookingAtI("topaxis") THEN INC(sc.pos, 7); d.topAxis := TRUE
  ELSIF KwValue("axisformat", "#;", v) THEN d.axisFormat := v
  ELSIF KwValue("tickinterval", "#;", v) THEN d.tickInterval := v
  ELSIF KwValue("includes", "#;", v) THEN Merge(d.includes, v)
  ELSIF KwValue("excludes", "#;", v) THEN Merge(d.excludes, v)
  ELSIF KwValue("todaymarker", ";", v) THEN d.todayMarker := v
  ELSIF KwDay("weekday", "monday") THEN d.weekday := 1
  ELSIF KwDay("weekday", "tuesday") THEN d.weekday := 2
  ELSIF KwDay("weekday", "wednesday") THEN d.weekday := 3
  ELSIF KwDay("weekday", "thursday") THEN d.weekday := 4
  ELSIF KwDay("weekday", "friday") THEN d.weekday := 5
  ELSIF KwDay("weekday", "saturday") THEN d.weekday := 6
  ELSIF KwDay("weekday", "sunday") THEN d.weekday := 0
  ELSIF KwDay("weekend", "friday") THEN d.weekend := 5
  ELSIF KwDay("weekend", "saturday") THEN d.weekend := 6
  ELSIF L.IsDigit(ch) & L.IsDigit(sc.Peek(1)) & L.IsDigit(sc.Peek(2)) & L.IsDigit(sc.Peek(3))
    & (sc.Peek(4) = "-") & L.IsDigit(sc.Peek(5)) & L.IsDigit(sc.Peek(6))
    & (sc.Peek(7) = "-") & L.IsDigit(sc.Peek(8)) & L.IsDigit(sc.Peek(9)) THEN
    sc.Error("a task's text cannot start with a date")
  ELSIF KwValue("title", "", v) THEN
    e := sc.pos; k := e - L.Length(v^);
    WHILE (k < e) & IsSpace(sc.t[k]) DO INC(k) END;
    WHILE (e > k) & IsSpace(sc.t[e - 1]) DO DEC(e) END;
    IF e > k THEN d.g.title := F.MakeLabel(sc.t^, k, e, FALSE) ELSE d.g.title := NIL END
  ELSIF KwValue("accdescription", "#;", v) THEN sc.Error("unexpected accDescription")
  ELSIF KwValue("section", "", v) THEN SectionStmt(v)
  ELSE TaskStmt
  END
END Statement;

(* The dates *)

PROCEDURE Fail(t: Task; s1, s2, s3: ARRAY OF CHAR);
BEGIN
  M0(s1); M(s2); M(s3);
  sc.ErrorAt(t.pos, msg)
END Fail;

(* Whether s starts with the keyword w, then white space and ids, as
   /^w\s+(?<ids>[\d\w- ]+)/ finds them; the ids' text, from where it
   starts, in ids *)
PROCEDURE Refs(s: Str; w: ARRAY OF CHAR; VAR ids: Str): BOOLEAN;
  VAR n, k, e, ws: LONGINT;

  PROCEDURE IdChar(ch: CHAR): BOOLEAN;
  BEGIN
    RETURN L.IsWordChar(ch) OR (ch = "-") OR (ch = " ")
  END IdChar;

BEGIN
  n := L.Length(w);
  k := 0;
  WHILE k < n DO IF s[k] # w[k] THEN RETURN FALSE END; INC(k) END;
  ws := k;
  WHILE IsSpace(s[k]) DO INC(k) END;
  IF k = ws THEN RETURN FALSE END;
  e := k; WHILE (s[e] # 0X) & IdChar(s[e]) DO INC(e) END;
  IF (e = k) & ~((k - ws >= 2) & (s[k - 1] = " ")) THEN RETURN FALSE END;
  ids := L.Sub(s^, k, e - k);
  RETURN TRUE
END Refs;

(* The ids of ids, split at " ", in turn: from i, the next one in id;
   FALSE at the end *)
PROCEDURE NextId(ids: Str; VAR i: LONGINT; VAR id: Str): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  WHILE ids[i] = " " DO INC(i) END;
  IF ids[i] = 0X THEN RETURN FALSE END;
  k := i; WHILE (ids[k] # 0X) & (ids[k] # " ") DO INC(k) END;
  id := L.Sub(ids^, i, k - i); i := k;
  RETURN TRUE
END NextId;

PROCEDURE WarnUnknown(keyword: ARRAY OF CHAR; unknown: Str);
BEGIN
  M0('Gantt: the "'); M(keyword); M('" statement references unknown task id(s): ');
  M(unknown^);
  M('. Make sure the referenced tasks exist and declare an id. Milestones need both an id and a duration, e.g. "Milestone :milestone, m1, 2023-01-01, 0d".');
  PmIO.Warn(msg)
END WarnUnknown;

(* Adds id to the list of unknown ids, separated by ", " *)
PROCEDURE AddUnknown(VAR unknown: Str; id: Str);
  VAR save: ARRAY 1024 OF CHAR;
BEGIN
  COPY(msg, save);
  IF unknown = NIL THEN M0(id^) ELSE M0(unknown^); M(", "); M(id^) END;
  unknown := L.New(msg);
  COPY(save, msg)
END AddUnknown;

(* A strict parse with the date format; Mermaid fails where the format
   has tokens it cannot format *)
PROCEDURE ParseDate(t: Task; s: Str; VAR r: HUGEINT): BOOLEAN;
  VAR failed, ok: BOOLEAN;
BEGIN
  ok := T.Parse(s^, d.dateFormat^, r, failed);
  IF failed THEN
    Fail(t, 'the dateFormat "', d.dateFormat^, '" has w, ww, wo, gggg, z or zzz, which Mermaid cannot format')
  END;
  RETURN ok
END ParseDate;

(* getStartDate: the start s gives; FALSE where it gives none, "after" a
   task that has no end yet. With warn, warns of unknown ids. *)
PROCEDURE StartDate(t: Task; s: Str; warn: BOOLEAN; VAR r: HUGEINT): BOOLEAN;
  VAR ids, id, unknown: Str; i: LONGINT; p, latest: Task; n: HUGEINT; all: BOOLEAN;
BEGIN
  IF L.Is(d.dateFormat, "x") OR L.Is(d.dateFormat, "X") THEN
    all := s[0] # 0X; i := 0;
    WHILE s[i] # 0X DO IF ~L.IsDigit(s[i]) THEN all := FALSE END; INC(i) END;
    IF all THEN
      n := 0; i := 0;
      WHILE (s[i] # 0X) & (n < 100000000000000) DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
      IF (s[i] # 0X) OR ~T.Valid(n) THEN Fail(t, "invalid date: ", s^, "") END;
      r := n; RETURN TRUE
    END
  END;
  IF Refs(s, "after", ids) THEN
    latest := NIL; unknown := NIL; i := 0;
    WHILE NextId(ids, i, id) DO
      p := Find(id^);
      IF p = NIL THEN AddUnknown(unknown, id)
      ELSIF (latest = NIL) OR p.endSet & latest.endSet & (p.end > latest.end) THEN latest := p
      END
    END;
    IF warn & (unknown # NIL) THEN WarnUnknown("after", unknown) END;
    IF latest # NIL THEN r := latest.end; RETURN latest.endSet END;
    r := T.Today(); RETURN TRUE
  END;
  IF ParseDate(t, s, r) THEN RETURN TRUE END;
  IF ~T.DateParse(s^, r) THEN Fail(t, "invalid date: ", s^, "") END;
  RETURN TRUE
END StartDate;

(* parseDuration: a number and a unit, M, d, h, m, s, w, y or ms *)
PROCEDURE Duration(s: Str; VAR n: LONGREAL; VAR unit: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT; f: LONGREAL;
BEGIN
  i := 0; n := 0;
  IF ~L.IsDigit(s[0]) THEN RETURN FALSE END;
  WHILE L.IsDigit(s[i]) DO n := n * 10 + (ORD(s[i]) - ORD("0")); INC(i) END;
  IF (s[i] = ".") & L.IsDigit(s[i + 1]) THEN
    INC(i); f := 0.1D0;
    WHILE L.IsDigit(s[i]) DO n := n + f * (ORD(s[i]) - ORD("0")); f := f / 10; INC(i) END
  END;
  IF (s[i] = "m") & (s[i + 1] = "s") & (s[i + 2] = 0X) THEN COPY("ms", unit); RETURN TRUE END;
  IF (s[i] = 0X) OR (s[i + 1] # 0X) THEN RETURN FALSE END;
  CASE s[i] OF
  | "M", "d", "h", "m", "s", "w", "y": unit[0] := s[i]; unit[1] := 0X; RETURN TRUE
  ELSE RETURN FALSE
  END
END Duration;

(* getEndDate: the end t's endData gives, from its start; FALSE where
   it gives none, "until" a task that has no start yet *)
PROCEDURE EndDate(t: Task; warn: BOOLEAN; VAR r: HUGEINT): BOOLEAN;
  VAR s, ids, id, unknown: Str; i: LONGINT; p, earliest: Task; n: LONGREAL;
    unit: ARRAY 4 OF CHAR;
BEGIN
  s := t.endData;
  IF Refs(s, "until", ids) THEN
    earliest := NIL; unknown := NIL; i := 0;
    WHILE NextId(ids, i, id) DO
      p := Find(id^);
      IF p = NIL THEN AddUnknown(unknown, id)
      ELSIF (earliest = NIL) OR p.startSet & earliest.startSet & (p.start < earliest.start) THEN
        earliest := p
      END
    END;
    IF warn & (unknown # NIL) THEN WarnUnknown("until", unknown) END;
    IF earliest # NIL THEN r := earliest.start; RETURN earliest.startSet END;
    r := T.Today(); RETURN TRUE
  END;
  IF ParseDate(t, s, r) THEN
    IF d.inclusiveEndDates & ~T.Add(r, 1, "d", r) THEN Fail(t, "invalid date: ", s^, "") END;
    RETURN TRUE
  END;
  r := t.start;
  IF ~Duration(s, n, unit) THEN
    IF warn THEN
      M0('Gantt: "'); M(s^); M('" is neither a valid date for the "'); M(d.dateFormat^);
      M('" date format nor a valid duration (e.g. "3d"), so it is ignored and the task gets a zero duration. Milestones need a duration too, e.g. "Milestone :milestone, m1, 2023-01-01, 0d".');
      PmIO.Warn(msg)
    END
  ELSIF ~T.Add(t.start, n, unit, r) THEN r := t.start
  END;
  RETURN TRUE
END EndDate;

(* isInvalidDate: whether the day of t is excluded; ok is FALSE, and
   the day not excluded, if the dateFormat cannot be formatted *)
PROCEDURE Invalid(t: HUGEINT; VAR ok: BOOLEAN): BOOLEAN;
  VAR formatted, dateOnly, day: Str; iso, i: LONGINT;
BEGIN
  ok := T.Format(t, d.dateFormat^, formatted);
  IF ~ok THEN RETURN FALSE END;
  IF ~T.Format(t, "YYYY-MM-DD", dateOnly) THEN END;
  IF In(d.includes, formatted^) OR In(d.includes, dateOnly^) THEN RETURN FALSE END;
  iso := T.IsoWeekday(t);
  IF In(d.excludes, "weekends") & ((iso = d.weekend) OR (iso = d.weekend + 1)) THEN RETURN TRUE END;
  IF T.Format(t, "dddd", day) THEN
    FOR i := 0 TO L.Length(day^) - 1 DO day[i] := Lower(day[i]) END
  END;
  IF In(d.excludes, day^) THEN RETURN TRUE END;
  RETURN In(d.excludes, formatted^) OR In(d.excludes, dateOnly^)
END Invalid;

(* Whether the day of t is excluded, for task *)
PROCEDURE Excluded(task: Task; t: HUGEINT): BOOLEAN;
  VAR ok, r: BOOLEAN;
BEGIN
  r := Invalid(t, ok);
  IF ~ok THEN
    Fail(task, 'the dateFormat "', d.dateFormat^, '" has w, ww, wo, gggg, z or zzz, which Mermaid cannot format')
  END;
  RETURN r
END Excluded;

(* Whether the day of t is excluded from diagram's chart, by its
   excludes and includes, as isInvalidDate finds it; FALSE if its
   dateFormat cannot be formatted *)
PROCEDURE IsExcluded*(diagram: Diagram; t: HUGEINT): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  d := diagram;
  RETURN Invalid(t, ok)
END IsExcluded;

PROCEDURE AddDay(t: Task; x: HUGEINT): HUGEINT;
  VAR r: HUGEINT;
BEGIN
  IF ~T.Add(x, 1, "d", r) THEN Fail(t, "a date is beyond the years 9999 and -9999", "", "") END;
  RETURN r
END AddDay;

(* checkTaskDates and fixTaskDates: the end moved past the excluded
   days, and the end drawn *)
PROCEDURE CheckDates(t: Task);
  VAR s, e, maxEnd: HUGEINT; invalid: BOOLEAN;
BEGIN
  IF (d.excludes = NIL) OR t.manualEnd THEN RETURN END;
  s := AddDay(t, t.start); e := t.end;
  IF ~T.Add(e, 10000, "d", maxEnd) THEN maxEnd := e END;
  invalid := FALSE; t.hasRenderEnd := FALSE;
  WHILE s <= e DO
    IF ~invalid THEN t.renderEnd := e; t.hasRenderEnd := TRUE END;
    invalid := Excluded(t, s);
    IF invalid THEN
      e := AddDay(t, e);
      IF e > maxEnd THEN
        Fail(t, "Failed to find a valid date that was not excluded by `excludes` after 10,000 iterations.", "", "")
      END
    END;
    s := AddDay(t, s)
  END;
  t.end := e
END CheckDates;

(* compileTasks: a pass over the tasks; whether each has its dates *)
PROCEDURE Pass(warn: BOOLEAN): BOOLEAN;
  VAR t, p: Task; r: HUGEINT; all, failed: BOOLEAN;
BEGIN
  all := TRUE; t := d.tasks;
  WHILE t # NIL DO
    IF t.kind = AfterPrevious THEN
      IF t.prevId = NIL THEN
        Fail(t, "the first task has no start: give it a date, or after and a task's id", "", "")
      END;
      p := Find(t.prevId^);
      t.start := p.end; t.startSet := p.endSet
    ELSIF StartDate(t, t.startData, warn, r) THEN
      t.start := r; t.startSet := TRUE
    END;
    IF t.startSet THEN
      t.endSet := EndDate(t, warn, r);
      IF t.endSet THEN
        t.end := r; t.processed := TRUE;
        t.manualEnd := T.Parse(t.endData^, "YYYY-MM-DD", r, failed);
        CheckDates(t)
      END
    END;
    all := all & t.processed;
    t := t.next
  END;
  RETURN all
END Pass;

(* getTasks: the passes, up to 11 *)
PROCEDURE Compile;
  VAR n: INTEGER; t: Task;
BEGIN
  n := 1;
  IF ~Pass(TRUE) THEN
    WHILE (n < 11) & ~Pass(FALSE) DO INC(n) END
  END;
  t := d.tasks;
  WHILE t # NIL DO
    IF ~t.startSet OR ~t.endSet THEN
      Fail(t, "the task's start or end depends on itself, through after or until", "", "")
    END;
    t := t.next
  END
END Compile;

(* Whether the scanner's text, after front matter and comments, starts
   with "gantt" *)
PROCEDURE IsGantt*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s;
  r := LookingAtI("gantt");
  s.pos := save;
  RETURN r
END IsGantt;

(* Reads the Gantt chart in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR q: Y.Pair;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Gantt, d.g); sc := s;
  d.dateFormat := L.New(""); d.axisFormat := NIL; d.tickInterval := NIL;
  d.todayMarker := L.New("");
  d.inclusiveEndDates := FALSE; d.topAxis := FALSE; d.compact := FALSE;
  d.weekday := 0; d.weekend := 6;
  d.includes := NIL; d.excludes := NIL; d.sections := NIL; d.lastSection := NIL;
  d.tasks := NIL; d.nTasks := 0; d.last := NIL;
  section := L.New(""); lastId := NIL; taskCount := 0; lastOrder := 0;
  IF ~LookingAtI("gantt") THEN sc.Error("expected gantt") END;
  INC(sc.pos, 5);
  WHILE ~sc.AtEnd() DO Statement END;
  q := Y.Find(d.g.config, "displayMode");
  IF (q # NIL) & L.Is(q.value, "compact") THEN d.compact := TRUE END;
  q := Y.Find(d.g.config, "config.gantt.displayMode");
  IF (q # NIL) & L.Is(q.value, "compact") THEN d.compact := TRUE END;
  Compile
END Read;

END PmGantt.
