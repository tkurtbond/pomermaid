MODULE PmJourney;
(* PmJourney: Mermaid's user journeys (`journey`), read into a model of
   their own: the tasks, in order, each with its score and the people
   in it; the sections they are in; and the actors, everyone in a task,
   each once.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   user-journey/parser/journey.jison, and what journeyDb.js and
   journeyRenderer.ts make of it:

   - statements end at a line end or ";"; "%%" and "#" start a comment,
     but "#name;" and "#123;" are Mermaid's entities; keywords are read
     in any case;
   - "title text": the rest of the statement is the title, so a task
     whose name starts with "title " is read as a title, as Mermaid
     reads it;
   - "section name": the tasks that follow are in it; a section's name
     has no ":";
   - "name: score: person, person": a task; the score is a number,
     taken as JavaScript's Number takes it (nothing is 0), the people
     are split at "," and their blanks trimmed; what follows a second
     ":" is ignored;
   - accTitle and accDescr are read and skipped.

   The actors are the people, each once, sorted by their bytes as
   JavaScript sorts strings (the same order but for characters beyond
   U+FFFF). The sections drawn are the runs of tasks one after the
   other with the same section's name, as Mermaid draws them: tasks
   before the first section are in none, a section with no task is not
   drawn, and a section named again after another is drawn again. *)

IMPORT L := PmLex, F := PmFlow;

CONST
  MaxPeople = 1024;      (* in one task *)

TYPE
  Str = L.Str;
  Ints* = POINTER TO ARRAY OF INTEGER;

  (* A section drawn: a run of tasks one after the other *)
  Section* = POINTER TO SectionDesc;
  SectionDesc* = RECORD
    text*: F.Label;
    first*, count*: INTEGER; (* its tasks: first .. first + count - 1 *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Section
  END;

  Task* = POINTER TO TaskDesc;
  TaskDesc* = RECORD
    text*: F.Label;
    score*: REAL;
    people*: Ints;      (* the actors' indexes, as named *)
    nPeople*: INTEGER;
    section*: Section;  (* or NIL, before the first section *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Task;
    sectionName: Str;   (* "" for none *)
    names: POINTER TO ARRAY OF Str
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;        (* the title and the configuration *)
    tasks*: Task; nTasks*: INTEGER;
    sections*: Section; nSections*: INTEGER;
    actors*: POINTER TO ARRAY OF Str; (* sorted *)
    nActors*: INTEGER;
    lastTask: Task
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  section: Str;          (* the current section's name *)

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether the text at the position is w, which is in lower case, in
   any case *)
PROCEDURE LookingAtI(w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF Lower(sc.Peek(i)) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END LookingAtI;

(* Whether the text at the position is the keyword w, in any case, not
   followed by a word character *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN LookingAtI(w) & ~L.IsWordChar(sc.Peek(L.Length(w)))
END Kw;

(* Whether the text at the position is the keyword w, in any case,
   followed by a blank *)
PROCEDURE KwBlank(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN LookingAtI(w) & L.IsBlank(sc.Peek(L.Length(w)))
END KwBlank;

(* Whether the text at p is an entity, "#name;" or "#123;" *)
PROCEDURE IsEntity(p: LONGINT): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  k := p + 1;
  WHILE (k < LEN(sc.t^)) & L.IsWordChar(sc.t[k]) DO INC(k) END;
  RETURN (k > p + 1) & (k < LEN(sc.t^)) & (sc.t[k] = ";")
END IsEntity;

(* Skips blanks, line ends, ";", and comments and directives *)
PROCEDURE SkipSpace;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF (sc.Ch() = 0AX) OR (sc.Ch() = ";") THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSIF (sc.Ch() = "#") & ~IsEntity(sc.pos) THEN sc.SkipLine
    ELSE EXIT
    END
  END
END SkipSpace;

(* Moves to the end of the text from the position that stops at a line
   end, ";", a comment, or, with colon, ":"; returns where it started,
   after blanks, and in end where it ends, before blanks *)
PROCEDURE Span(colon: BOOLEAN; VAR end: LONGINT): LONGINT;
  VAR start: LONGINT; ch: CHAR;
BEGIN
  sc.SkipBlanks;
  start := sc.pos;
  LOOP
    IF sc.AtEnd() THEN EXIT END;
    ch := sc.Ch();
    IF (ch = 0AX) OR (ch = ";") OR colon & (ch = ":") OR sc.LookingAt("%%") THEN EXIT
    ELSIF ch = "#" THEN
      IF ~IsEntity(sc.pos) THEN EXIT END;
      WHILE sc.Ch() # ";" DO INC(sc.pos) END;
      INC(sc.pos)
    ELSE INC(sc.pos)
    END
  END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  RETURN start
END Span;

(* The score in t[start .. end-1], as JavaScript's Number reads it:
   blanks are trimmed, nothing is 0; FALSE if it is not a number *)
PROCEDURE Score(start, end: LONGINT; VAR x: REAL): BOOLEAN;
  VAR i, e: LONGINT; neg, eneg, digits: BOOLEAN; f, p: REAL;
BEGIN
  WHILE (start < end) & L.IsBlank(sc.t[start]) DO INC(start) END;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  x := 0; i := start; neg := FALSE; digits := FALSE;
  IF i = end THEN RETURN TRUE END;
  IF (sc.t[i] = "+") OR (sc.t[i] = "-") THEN neg := sc.t[i] = "-"; INC(i) END;
  WHILE (i < end) & L.IsDigit(sc.t[i]) DO
    x := x * 10 + (ORD(sc.t[i]) - ORD("0")); INC(i); digits := TRUE
  END;
  IF (i < end) & (sc.t[i] = ".") THEN
    INC(i); f := 0.1;
    WHILE (i < end) & L.IsDigit(sc.t[i]) DO
      x := x + f * (ORD(sc.t[i]) - ORD("0")); f := f / 10; INC(i); digits := TRUE
    END
  END;
  IF ~digits THEN RETURN FALSE END;
  IF (i < end) & ((sc.t[i] = "e") OR (sc.t[i] = "E")) THEN
    INC(i); eneg := FALSE; e := 0;
    IF (i < end) & ((sc.t[i] = "+") OR (sc.t[i] = "-")) THEN eneg := sc.t[i] = "-"; INC(i) END;
    IF (i = end) OR ~L.IsDigit(sc.t[i]) THEN RETURN FALSE END;
    WHILE (i < end) & L.IsDigit(sc.t[i]) DO
      IF e < 100 THEN e := e * 10 + (ORD(sc.t[i]) - ORD("0")) END;
      INC(i)
    END;
    IF e > 30 THEN RETURN FALSE END;
    p := 1; WHILE e > 0 DO p := p * 10; DEC(e) END;
    IF eneg THEN x := x / p ELSE x := x * p END
  END;
  IF neg THEN x := -x END;
  RETURN i = end
END Score;

PROCEDURE Title;
  VAR start, end: LONGINT;
BEGIN
  start := Span(FALSE, end);
  IF end > start THEN d.g.title := F.MakeLabel(sc.t^, start, end, FALSE) END
END Title;

PROCEDURE SectionStmt;
  VAR start, end: LONGINT;
BEGIN
  start := Span(TRUE, end);
  IF sc.Ch() = ":" THEN sc.Error("a section's name cannot have a colon") END;
  IF start = end THEN sc.Error("expected the section's name") END;
  section := L.Sub(sc.t^, start, end - start)
END SectionStmt;

PROCEDURE TaskStmt;
  VAR
    t: Task; start, end, p, q: LONGINT; k, n: INTEGER;
    names: ARRAY MaxPeople OF Str;
BEGIN
  start := Span(TRUE, end);
  IF start = end THEN sc.Error("expected a task") END;
  IF sc.Ch() # ":" THEN sc.Error('expected ":" and the score after a task') END;
  NEW(t); t.text := F.MakeLabel(sc.t^, start, end, FALSE);
  t.sectionName := section; t.section := NIL; t.next := NIL;
  INC(sc.pos);
  p := sc.pos;
  start := Span(FALSE, end);
  IF sc.pos = p THEN sc.Error("expected the task's score") END;
  (* the score, to a ":" or the end *)
  q := start; WHILE (q < end) & (sc.t[q] # ":") DO INC(q) END;
  IF ~Score(start, q, t.score) THEN sc.ErrorAt(start, "a task's score must be a number") END;
  n := 0;
  IF q < end THEN
    (* the people, to the next ":" *)
    p := q + 1;
    LOOP
      q := p; WHILE (q < end) & (sc.t[q] # ",") & (sc.t[q] # ":") DO INC(q) END;
      start := p; WHILE (start < q) & L.IsBlank(sc.t[start]) DO INC(start) END;
      k := 0;
      WHILE (q - k > start) & L.IsBlank(sc.t[q - k - 1]) DO INC(k) END;
      IF n = MaxPeople THEN sc.Error("too many people in one task") END;
      names[n] := L.Sub(sc.t^, start, q - k - start); INC(n);
      IF (q = end) OR (sc.t[q] = ":") THEN EXIT END;
      p := q + 1
    END
  END;
  t.nPeople := n; NEW(t.names, n + 1); NEW(t.people, n + 1);
  FOR k := 0 TO n - 1 DO t.names[k] := names[k]; t.people[k] := -1 END;
  t.index := d.nTasks; INC(d.nTasks);
  IF d.tasks = NIL THEN d.tasks := t ELSE d.lastTask.next := t END;
  d.lastTask := t
END TaskStmt;

PROCEDURE Statement;
BEGIN
  IF KwBlank("title") THEN INC(sc.pos, 5); Title
  ELSIF KwBlank("section") THEN INC(sc.pos, 7); SectionStmt
  ELSIF Kw("acctitle") OR Kw("accdescr") THEN F.Accessibility
  ELSE TaskStmt
  END
END Statement;

(* Whether a < b, by their bytes *)
PROCEDURE Less(a, b: Str): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END;
  RETURN ORD(a[i]) < ORD(b[i])
END Less;

(* The actors, each person once, sorted; each task's people as the
   actors' indexes; the sections drawn *)
PROCEDURE Finish;
  VAR
    t: Task; s, last: Section; k, i, j, n: INTEGER; x: Str; found: BOOLEAN;
    prev: Str;
BEGIN
  n := 0; t := d.tasks;
  WHILE t # NIL DO INC(n, t.nPeople); t := t.next END;
  NEW(d.actors, n + 1); d.nActors := 0;
  t := d.tasks;
  WHILE t # NIL DO
    FOR k := 0 TO t.nPeople - 1 DO
      found := FALSE; i := 0;
      WHILE ~found & (i < d.nActors) DO found := L.Equal(d.actors[i], t.names[k]); INC(i) END;
      IF ~found THEN d.actors[d.nActors] := t.names[k]; INC(d.nActors) END
    END;
    t := t.next
  END;
  FOR i := 1 TO d.nActors - 1 DO
    x := d.actors[i]; j := i;
    WHILE (j > 0) & Less(x, d.actors[j - 1]) DO d.actors[j] := d.actors[j - 1]; DEC(j) END;
    d.actors[j] := x
  END;
  t := d.tasks;
  WHILE t # NIL DO
    FOR k := 0 TO t.nPeople - 1 DO
      i := 0; WHILE ~L.Equal(d.actors[i], t.names[k]) DO INC(i) END;
      t.people[k] := i
    END;
    t := t.next
  END;
  d.sections := NIL; d.nSections := 0; last := NIL; s := NIL;
  prev := L.New(""); t := d.tasks;
  WHILE t # NIL DO
    IF ~L.Equal(t.sectionName, prev) THEN
      NEW(s); s.text := F.PlainLabel(t.sectionName); s.first := t.index; s.count := 0;
      s.index := d.nSections; INC(d.nSections); s.next := NIL;
      IF last = NIL THEN d.sections := s ELSE last.next := s END;
      last := s; prev := t.sectionName
    END;
    IF s # NIL THEN INC(s.count) END;
    t.section := s;
    t := t.next
  END
END Finish;

(* Whether the scanner's text, after front matter and comments, starts
   with "journey" *)
PROCEDURE IsJourney*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s;
  r := Kw("journey");
  s.pos := save;
  RETURN r
END IsJourney;

(* Reads the user journey in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Journey, d.g); sc := s;
  d.tasks := NIL; d.nTasks := 0; d.lastTask := NIL; d.sections := NIL; d.nSections := 0;
  d.actors := NIL; d.nActors := 0;
  section := L.New("");
  IF ~Kw("journey") THEN sc.Error("expected journey") END;
  INC(sc.pos, 7);
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Finish
END Read;

END PmJourney.
