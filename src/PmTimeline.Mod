MODULE PmTimeline;
(* PmTimeline: Mermaid's timelines (`timeline`), read into a model of
   their own: the periods, in order, each with its events; the
   sections they are in; the title and the direction.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   timeline/parser/timeline.jison, and what timelineDb.js and the
   renderers make of it:

   - the first line is "timeline", "timeline LR" or "timeline TD"
     (top down); keywords are read in any case;
   - "%%" and "#" at the start of a statement start a comment, to the
     end of the line, but "#name;" and "#123;" are Mermaid's entities;
     ";" is text, not the end of a statement;
   - "title text": the rest of the line is the title;
   - "section name": the periods that follow are in it; a section's
     name has no ":";
   - a period is text up to a ":", a "#" or the end of the line;
   - ": event": an event of the last period, up to a ":" followed by
     a blank or the end of the line; a ":" followed by anything else
     is in the event. Events follow their period on its line or on the
     lines after it;
   - accTitle and accDescr are read and skipped.

   The sections drawn are the sections' names, each once, in the order
   they are first named, each with every period under that name, in
   order. With sections, periods before the first one are in none and
   are not drawn, as Mermaid does not draw them; pomermaid says so. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml;

TYPE
  Str = L.Str;
  Labels* = POINTER TO ARRAY OF F.Label;

  Period* = POINTER TO PeriodDesc;

  Section* = POINTER TO SectionDesc;
  SectionDesc* = RECORD
    text*: F.Label;
    periods*: POINTER TO ARRAY OF Period;  (* in order *)
    count*: INTEGER;    (* the periods in it *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Section;
    name: Str
  END;

  PeriodDesc* = RECORD
    text*: F.Label;
    events*: Labels;
    nEvents*: INTEGER;
    section*: Section;  (* or NIL *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Period;
    sectionName: Str    (* "" for none *)
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;        (* the title and the configuration *)
    td*: BOOLEAN;       (* top down, "timeline TD" *)
    multicolor*: BOOLEAN;  (* without sections, each period its own
                              colour: not timeline.disableMulticolor *)
    periods*: Period; nPeriods*: INTEGER;
    sections*: Section; nSections*: INTEGER;
    lastPeriod: Period
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
  WHILE (k < sc.len) & L.IsWordChar(sc.t[k]) DO INC(k) END;
  RETURN (k > p + 1) & (k < sc.len) & (sc.t[k] = ";")
END IsEntity;

(* Whether ch is white space, as a regular expression's \s *)
PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN L.IsBlank(ch) OR (ch = 0AX) OR (ch = 0DX) OR (ch = 0CX) OR (ch = 0BX)
END IsSpace;

(* Skips blanks, line ends, and comments and directives *)
PROCEDURE SkipSpace;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF sc.Ch() = 0AX THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSIF (sc.Ch() = "#") & ~IsEntity(sc.pos) THEN sc.SkipLine
    ELSE EXIT
    END
  END
END SkipSpace;

(* Trims the blanks at the end of t[start .. end-1] *)
PROCEDURE Trim(start: LONGINT; VAR end: LONGINT);
BEGIN
  WHILE (end > start) & IsSpace(sc.t[end - 1]) DO DEC(end) END
END Trim;

(* Moves to the end of the line, or, with colon, to a ":"; returns where
   it started, after blanks, and in end where it ends, before blanks *)
PROCEDURE Rest(colon: BOOLEAN; VAR end: LONGINT): LONGINT;
  VAR start: LONGINT;
BEGIN
  sc.SkipBlanks; start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & ~(colon & (sc.Ch() = ":")) DO INC(sc.pos) END;
  end := sc.pos; Trim(start, end);
  RETURN start
END Rest;

PROCEDURE Title;
  VAR start, end: LONGINT;
BEGIN
  start := Rest(FALSE, end);
  IF end > start THEN d.g.title := F.MakeLabel(sc.t^, start, end, FALSE) END
END Title;

PROCEDURE SectionStmt;
  VAR start, end: LONGINT; s, last: Section;
BEGIN
  start := Rest(TRUE, end);
  IF sc.Ch() = ":" THEN sc.Error("a section's name cannot have a colon") END;
  IF start = end THEN sc.Error("expected the section's name") END;
  section := L.Sub(sc.t^, start, end - start);
  s := d.sections; last := NIL;
  WHILE (s # NIL) & ~L.Equal(s.name, section) DO last := s; s := s.next END;
  IF s = NIL THEN
    NEW(s); s.name := section; s.text := F.PlainLabel(section);
    s.count := 0; s.index := d.nSections; INC(d.nSections); s.next := NIL;
    IF last = NIL THEN d.sections := s ELSE last.next := s END
  END
END SectionStmt;

PROCEDURE PeriodStmt;
  VAR p: Period; start, end: LONGINT;
BEGIN
  start := sc.pos;
  LOOP
    IF sc.AtEnd() OR (sc.Ch() = 0AX) OR (sc.Ch() = ":") THEN EXIT
    ELSIF sc.Ch() = "#" THEN
      IF ~IsEntity(sc.pos) THEN EXIT END;
      WHILE sc.Ch() # ";" DO INC(sc.pos) END;
      INC(sc.pos)
    ELSE INC(sc.pos)
    END
  END;
  end := sc.pos; Trim(start, end);
  NEW(p); p.text := F.MakeLabel(sc.t^, start, end, FALSE);
  p.sectionName := section; p.section := NIL; p.next := NIL;
  NEW(p.events, 4); p.nEvents := 0;
  p.index := d.nPeriods; INC(d.nPeriods);
  IF d.periods = NIL THEN d.periods := p ELSE d.lastPeriod.next := p END;
  d.lastPeriod := p
END PeriodStmt;

(* ": event", at the ":" *)
PROCEDURE EventStmt;
  VAR p: Period; start, end: LONGINT; k: INTEGER; e: Labels;
BEGIN
  IF ~L.IsBlank(sc.Peek(1)) THEN
    IF (sc.Peek(1) = 0AX) OR (sc.Peek(1) = 0X) THEN sc.Error("expected an event after the colon")
    ELSE sc.Error("expected a blank after the colon")
    END
  END;
  IF d.lastPeriod = NIL THEN sc.Error("an event must follow a period") END;
  INC(sc.pos, 2); start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & ~((sc.Ch() = ":") & IsSpace(sc.Peek(1))) DO
    INC(sc.pos)
  END;
  IF sc.pos = start THEN sc.Error("expected an event after the colon") END;
  end := sc.pos; Trim(start, end);
  WHILE (start < end) & L.IsBlank(sc.t[start]) DO INC(start) END;
  p := d.lastPeriod;
  IF p.nEvents = LEN(p.events^) THEN
    NEW(e, 2 * p.nEvents);
    FOR k := 0 TO p.nEvents - 1 DO e[k] := p.events[k] END;
    p.events := e
  END;
  p.events[p.nEvents] := F.MakeLabel(sc.t^, start, end, FALSE); INC(p.nEvents)
END EventStmt;

PROCEDURE Statement;
BEGIN
  IF KwBlank("title") THEN INC(sc.pos, 5); Title
  ELSIF KwBlank("section") THEN INC(sc.pos, 7); SectionStmt
  ELSIF Kw("acctitle") OR Kw("accdescr") THEN F.Accessibility
  ELSIF sc.Ch() = ":" THEN EventStmt
  ELSE PeriodStmt
  END
END Statement;

(* The sections drawn: each name once, with its periods *)
PROCEDURE Finish;
  VAR p: Period; s: Section; dropped: BOOLEAN;
BEGIN
  p := d.periods;
  WHILE p # NIL DO
    IF p.sectionName[0] # 0X THEN
      s := d.sections;
      WHILE ~L.Equal(s.name, p.sectionName) DO s := s.next END;
      INC(s.count); p.section := s
    END;
    p := p.next
  END;
  s := d.sections;
  WHILE s # NIL DO NEW(s.periods, s.count + 1); s.count := 0; s := s.next END;
  dropped := FALSE; p := d.periods;
  WHILE p # NIL DO
    IF p.section # NIL THEN
      s := p.section; s.periods[s.count] := p; INC(s.count)
    ELSIF d.sections # NIL THEN dropped := TRUE
    END;
    p := p.next
  END;
  IF dropped THEN PmIO.Warn("periods before the first section are not drawn, as in Mermaid") END
END Finish;

(* Whether the scanner's text, after front matter and comments, starts
   with "timeline" *)
PROCEDURE IsTimeline*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s;
  r := Kw("timeline");
  s.pos := save;
  RETURN r
END IsTimeline;

(* Reads the timeline in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR q: Y.Pair;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Timeline, d.g); sc := s;
  d.td := FALSE; d.periods := NIL; d.nPeriods := 0; d.lastPeriod := NIL;
  d.sections := NIL; d.nSections := 0;
  q := Y.Find(d.g.config, "config.timeline.disableMulticolor");
  d.multicolor := (q = NIL) OR ~L.Is(q.value, "true");
  section := L.New("");
  IF ~Kw("timeline") THEN sc.Error("expected timeline") END;
  INC(sc.pos, 8);
  IF L.IsBlank(sc.Ch()) THEN
    sc.SkipBlanks;
    IF Kw("td") THEN d.td := TRUE; INC(sc.pos, 2)
    ELSIF Kw("lr") THEN INC(sc.pos, 2)
    END
  END;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Finish
END Read;

END PmTimeline.
