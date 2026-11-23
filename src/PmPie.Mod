MODULE PmPie;
(* PmPie: Mermaid's pie charts (`pie`), read into a model of their own:
   the sections, in order, each with its label and value; the title;
   showData and the configuration, config.pie.

   The reader follows Mermaid 12.3.0's grammar, packages/parser/src/
   language/pie/pie.langium and common.langium, and what pieDb.ts makes
   of it:

   - the chart starts with "pie", then "showData", if given; keywords
     are read in this case only;
   - blanks are skipped, as are "%%" comments and "%%{ ... }%%"
     directives; ";" is not the end of a statement;
   - "title text": the rest of the line, up to a "%%", is the title;
     an empty one is none, and the last one is kept. It may be on the
     line of "pie";
   - accTitle and accDescr are read and skipped;
   - a section is a string, a ":" and a number, then the end of the
     line: "label": 42. A string is in double or single quotation
     marks, with escapes, as Langium reads them: "\n", "\t" and the
     others, which are white space, drawn as a blank, as SVG does;
     "\c" is c;
   - a number is an integer, "0" or digits not starting with "0", or
     digits, "." and digits, either with "-" before it; it may not be
     followed by a ".". A negative value is an error;
   - a label given again is ignored: the first section with it is
     kept. *)

IMPORT L := PmLex, F := PmFlow, Y := PmYaml;

CONST
  (* legend positions, config.pie.legendPosition *)
  Right* = 0; Left* = 1; Top* = 2; Bottom* = 3; Center* = 4;

TYPE
  Str = L.Str;

  Section* = POINTER TO SectionDesc;
  SectionDesc* = RECORD
    text*: F.Label;
    name-: Str;          (* the label's text, as read *)
    value*: LONGREAL;
    shown*: Str;         (* the value, as written: no leading zeros,
                            no trailing zeros in the fraction *)
    index*: INTEGER;     (* from 0, in order *)
    next*: Section
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;         (* the title and the configuration *)
    showData*: BOOLEAN;  (* the values in the legend *)
    sections*: Section; nSections*: INTEGER;
    sum*: LONGREAL;      (* of all values, in order *)
    textPosition*: REAL; (* where the percentages are, from the centre,
                            as a fraction of the radius *)
    donutHole*: REAL;    (* the hole's radius, as a fraction; 0 for none *)
    legend*: INTEGER;    (* Right ... Center *)
    highlight*: Str;     (* the label of the slice drawn larger, or NIL *)
    last: Section
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;

(* Skips blanks, line ends, comments and directives *)
PROCEDURE SkipSpace;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF sc.Ch() = 0AX THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSE EXIT
    END
  END
END SkipSpace;

(* Skips blanks and a comment; the end of a statement must follow *)
PROCEDURE EndOfLine;
  VAR e: LONGINT;
BEGIN
  sc.SkipBlanks;
  IF sc.LookingAt("%%") THEN
    e := sc.DirectiveEnd();
    IF e >= 0 THEN sc.pos := e; RETURN ELSE sc.SkipLine END
  END;
  IF ~sc.AtEnd() & (sc.Ch() # 0AX) THEN sc.Error("expected the end of the line") END
END EndOfLine;

PROCEDURE Put(VAR n: LONGINT; ch: CHAR);
  VAR b: Str; k: LONGINT;
BEGIN
  IF n + 1 >= LEN(buf^) THEN
    NEW(b, 2 * LEN(buf^));
    FOR k := 0 TO n - 1 DO b[k] := buf[k] END;
    buf := b
  END;
  buf[n] := ch; INC(n)
END Put;

(* "title text", after "title" *)
PROCEDURE Title;
  VAR start, end: LONGINT;
BEGIN
  IF ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) THEN
    sc.Error("expected a blank after title")
  END;
  sc.SkipBlanks; start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & ~sc.LookingAt("%%") DO INC(sc.pos) END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  IF end > start THEN d.g.title := F.TextLabel(sc.t^, start, end) ELSE d.g.title := NIL END
END Title;

(* A string, at its quotation mark; its text, its escapes read, is
   left in buf[0 .. n-1] *)
PROCEDURE String(VAR n: LONGINT);
  VAR q, ch: CHAR;
BEGIN
  q := sc.Ch(); INC(sc.pos); n := 0;
  LOOP
    IF sc.AtEnd() THEN sc.Error("the string has no closing quotation mark") END;
    ch := sc.Ch(); INC(sc.pos);
    IF ch = q THEN EXIT
    ELSIF ch = "\" THEN
      IF sc.AtEnd() THEN sc.Error("the string has no closing quotation mark") END;
      ch := sc.Ch(); INC(sc.pos);
      CASE ch OF
        "b", "f", "n", "r", "t", "v", "0": Put(n, " ")
      ELSE Put(n, ch)
      END
    ELSE Put(n, ch)
    END
  END;
  buf[n] := 0X
END String;

(* A number at the position: its value, and in shown its text,
   normalised *)
PROCEDURE Number(VAR x: LONGREAL; VAR shown: Str);
  VAR neg: BOOLEAN; start, fs, fe, ie, k: LONGINT; f, p: LONGREAL;
BEGIN
  neg := sc.Ch() = "-";
  IF neg THEN INC(sc.pos) END;
  IF ~L.IsDigit(sc.Ch()) THEN sc.Error("expected a number") END;
  start := sc.pos; x := 0;
  WHILE L.IsDigit(sc.Ch()) DO x := x * 10 + (ORD(sc.Ch()) - ORD("0")); INC(sc.pos) END;
  ie := sc.pos; fs := ie; fe := ie;
  IF (sc.Ch() = ".") & L.IsDigit(sc.Peek(1)) THEN
    INC(sc.pos); fs := sc.pos; f := 0; p := 1;
    WHILE L.IsDigit(sc.Ch()) DO
      f := f * 10 + (ORD(sc.Ch()) - ORD("0")); p := p * 10; INC(sc.pos)
    END;
    fe := sc.pos; x := x + f / p
  ELSIF (ie - start > 1) & (sc.t[start] = "0") THEN
    sc.ErrorAt(start, "a number cannot start with 0")
  END;
  IF sc.Ch() = "." THEN sc.Error("unexpected .") END;
  IF L.IsWordChar(sc.Ch()) THEN sc.Error("expected the end of the line") END;
  (* the text shown *)
  WHILE (ie - start > 1) & (sc.t[start] = "0") DO INC(start) END;
  WHILE (fe > fs) & (sc.t[fe - 1] = "0") DO DEC(fe) END;
  k := 0;
  IF neg & ((x # 0) OR (fe > fs)) THEN Put(k, "-") END;
  WHILE start < ie DO Put(k, sc.t[start]); INC(start) END;
  IF fe > fs THEN
    Put(k, ".");
    WHILE fs < fe DO Put(k, sc.t[fs]); INC(fs) END
  END;
  buf[k] := 0X; shown := L.Sub(buf^, 0, k);
  IF neg THEN x := -x END
END Number;

(* Fails with Mermaid's message for a negative value *)
PROCEDURE Negative(at: LONGINT; name, shown: Str);
  VAR n: LONGINT; m: POINTER TO ARRAY OF CHAR;

  PROCEDURE Add(s: ARRAY OF CHAR);
    VAR i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO m[n] := s[i]; INC(n); INC(i) END
  END Add;

BEGIN
  NEW(m, L.Length(name^) + L.Length(shown^) + 160); n := 0;
  Add('"'); Add(name^); Add('" has invalid value: '); Add(shown^);
  Add(". Negative values are not allowed in pie charts. All slice values must be >= 0.");
  m[n] := 0X;
  sc.ErrorAt(at, m^)
END Negative;

(* Whether a section has the label name *)
PROCEDURE Known(name: Str): BOOLEAN;
  VAR s: Section;
BEGIN
  s := d.sections;
  WHILE (s # NIL) & ~L.Equal(s.name, name) DO s := s.next END;
  RETURN s # NIL
END Known;

(* "label": value *)
PROCEDURE SectionStmt;
  VAR s: Section; n, at: LONGINT; name: Str;
BEGIN
  String(n); name := L.Sub(buf^, 0, n);
  NEW(s); s.name := name; s.text := F.TextLabel(buf^, 0, n);
  sc.SkipBlanks;
  IF sc.Ch() # ":" THEN sc.Error("expected : after the label") END;
  INC(sc.pos); sc.SkipBlanks;
  at := sc.pos;
  Number(s.value, s.shown);
  EndOfLine;
  IF s.value < 0 THEN Negative(at, name, s.shown) END;
  s.next := NIL;
  IF ~Known(name) THEN
    s.index := d.nSections; INC(d.nSections); d.sum := d.sum + s.value;
    IF d.sections = NIL THEN d.sections := s ELSE d.last.next := s END;
    d.last := s
  END
END SectionStmt;

PROCEDURE Statement;
BEGIN
  IF sc.LookingAt("title") & ~L.IsWordChar(sc.Peek(5)) THEN INC(sc.pos, 5); Title
  ELSIF sc.LookingAtWord("accTitle") OR sc.LookingAtWord("accDescr") THEN F.Accessibility
  ELSIF (sc.Ch() = '"') OR (sc.Ch() = "'") THEN SectionStmt
  ELSE sc.Error("expected a section, a quoted label, a colon and a value")
  END
END Statement;

(* config.pie.name, a number, or default *)
PROCEDURE Conf(name: ARRAY OF CHAR; default: REAL): REAL;
  VAR q: Y.Pair; i: LONGINT; x, f: REAL; neg, digits: BOOLEAN; s: Str;
BEGIN
  q := Y.Find(d.g.config, name);
  IF q = NIL THEN RETURN default END;
  s := q.value; i := 0; x := 0; neg := FALSE; digits := FALSE;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF (s[i] = "-") OR (s[i] = "+") THEN neg := s[i] = "-"; INC(i) END;
  WHILE L.IsDigit(s[i]) DO x := x * 10 + (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE END;
  IF s[i] = "." THEN
    INC(i); f := 0.1;
    WHILE L.IsDigit(s[i]) DO x := x + f * (ORD(s[i]) - ORD("0")); f := f / 10; INC(i); digits := TRUE END
  END;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF ~digits OR (s[i] # 0X) THEN RETURN default END;
  IF neg THEN x := -x END;
  RETURN x
END Conf;

PROCEDURE Configure;
  VAR q: Y.Pair;
BEGIN
  d.textPosition := Conf("config.pie.textPosition", 0.75);
  d.donutHole := Conf("config.pie.donutHole", 0);
  IF (d.donutHole <= 0) OR (d.donutHole > 0.9) THEN d.donutHole := 0 END;
  d.legend := Right;
  q := Y.Find(d.g.config, "config.pie.legendPosition");
  IF q # NIL THEN
    IF L.Is(q.value, "left") THEN d.legend := Left
    ELSIF L.Is(q.value, "top") THEN d.legend := Top
    ELSIF L.Is(q.value, "bottom") THEN d.legend := Bottom
    ELSIF L.Is(q.value, "center") THEN d.legend := Center
    END
  END;
  q := Y.Find(d.g.config, "config.pie.highlightSlice");
  IF q # NIL THEN d.highlight := q.value ELSE d.highlight := NIL END
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "pie" *)
PROCEDURE IsPie*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("pie");
  s.pos := save;
  RETURN r
END IsPie;

(* Reads the pie chart in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Pie, d.g); sc := s;
  d.showData := FALSE; d.sections := NIL; d.nSections := 0; d.sum := 0; d.last := NIL;
  Configure;
  IF ~sc.LookingAtWord("pie") THEN sc.Error("expected pie") END;
  INC(sc.pos, 3);
  sc.SkipBlanks;
  IF sc.LookingAtWord("showData") THEN d.showData := TRUE; INC(sc.pos, 8) END;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END
END Read;

BEGIN
  NEW(buf, 256)
END PmPie.
