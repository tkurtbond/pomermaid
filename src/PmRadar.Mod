MODULE PmRadar;
(* PmRadar: Mermaid's radar charts (`radar-beta`), read into a model
   of their own: the axes, in order, each with its name and label; the
   curves, in order, each with its name, its label and a value for each
   axis; the options; the title; and the configuration, config.radar.

   The reader follows Mermaid 12.3.0's grammar, packages/parser/src/
   language/radar/radar.langium and common.langium, and what the
   radar's db.ts makes of it:

   - the chart starts with "radar-beta", or "radar-beta:"; keywords
     are read in this case only;
   - blanks, "%%" comments and "%%{ ... }%%" directives are skipped;
     line ends separate nothing but are allowed only between
     statements and in a curve's braces; statements may follow each
     other on a line;
   - "title text": the rest of the line, up to a "%%"; accTitle and
     accDescr are read and skipped;
   - "axis a, b["label"], c": axes, each a name and, in brackets, a
     string, its label, else its name;
   - "curve a{1, 2, 3}, b["label"]{x: 1, y 2, z: 3}": curves, each a
     name, a label, and in braces its values, all numbers, one for each
     axis in order, or all an axis's name, ":" if wanted, and a number,
     put in the axes' order; line ends may follow "{" and each "," and
     come before "}";
   - options, separated by ",": "showLegend true|false", "ticks N",
     "max N", "min N", "graticule circle|polygon"; the last given is
     kept;
   - several axis, curve and option statements add to those before;
   - a name is a letter, a digit or "_", then those and "-", not
     ending in "-"; Mermaid's lexer reads a name that is a keyword, or
     starts with a digit, "true", "false", "circle", "polygon" or
     "title", as something else, so pomermaid does not take one
     either;
   - a number is digits, "." and digits, or an integer, "0" or digits
     not starting with "0", with no sign; no "." may follow it;
   - a string is in double or single quotation marks, its escapes read
     as Langium reads them, as PmPie's;
   - a curve whose values are given by axis needs the axes (all of
     them, wherever they are given) and a value for each, else it is
     Mermaid's error; a value for no axis is ignored, and one given
     twice is the first;
   - ticks above 32 are 32, with a warning, as Mermaid's. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml, X := PmXy;

CONST
  MaxTicks* = 32;

TYPE
  Str = L.Str;
  Reals* = POINTER TO ARRAY OF LONGREAL;
  Strs = POINTER TO ARRAY OF Str;
  Positions = POINTER TO ARRAY OF LONGINT;

  Axis* = POINTER TO AxisDesc;
  AxisDesc* = RECORD
    name-: Str;
    label*: F.Label;
    labelText-: Str;     (* the label, as read *)
    next*: Axis
  END;

  Curve* = POINTER TO CurveDesc;
  CurveDesc* = RECORD
    name-: Str;
    label*: F.Label;
    n*: LONGINT;         (* the values *)
    value*: Reals;       (* value[0 .. n-1], in the axes' order *)
    index*: INTEGER;     (* from 0, in order *)
    next*: Curve;
    at: LONGINT;         (* where it is, for an error *)
    key: Strs            (* each value's axis, or NIL for plain values *)
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;         (* the title and the configuration *)
    axes*: Axis; nAxes*: LONGINT;
    curves*: Curve; nCurves*: INTEGER;
    (* the options *)
    showLegend*: BOOLEAN;
    ticks*: LONGREAL;
    hasMax*: BOOLEAN; max*: LONGREAL;  (* max, if given *)
    min*: LONGREAL;
    polygon*: BOOLEAN;   (* the graticule's: polygons, else circles *)
    (* config.radar *)
    width*, height*, marginTop*, marginRight*, marginBottom*, marginLeft*,
    axisScaleFactor*, axisLabelFactor*, curveTension*: LONGREAL;
    lastAxis: Axis; lastCurve: Curve
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;

(* Skips blanks and comments, not line ends *)
PROCEDURE Hidden;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSE EXIT
    END
  END
END Hidden;

(* Skips blanks, line ends, comments and directives *)
PROCEDURE SkipSpace;
BEGIN
  LOOP
    Hidden;
    IF sc.Ch() = 0AX THEN INC(sc.pos) ELSE EXIT END
  END
END SkipSpace;

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

PROCEDURE IsIdChar(ch: CHAR): BOOLEAN;
BEGIN
  RETURN L.IsLetter(ch) OR L.IsDigit(ch) OR (ch = "_")
END IsIdChar;

(* Whether the text at the position is the keyword w *)
PROCEDURE Keyword(w: ARRAY OF CHAR): BOOLEAN;
  VAR n: LONGINT; ch: CHAR;
BEGIN
  n := L.Length(w); ch := sc.Peek(n);
  RETURN sc.LookingAt(w) & ~IsIdChar(ch) & ~((ch = "-") & IsIdChar(sc.Peek(n + 1)))
END Keyword;

(* Whether a name may start at the position: not a keyword, nor a
   word Mermaid's lexer takes before a name *)
PROCEDURE NameStarts(): BOOLEAN;
BEGIN
  RETURN (L.IsLetter(sc.Ch()) OR (sc.Ch() = "_"))
    & ~sc.LookingAt("true") & ~sc.LookingAt("false") & ~sc.LookingAt("circle")
    & ~sc.LookingAt("polygon") & ~sc.LookingAt("title")
    & ~Keyword("axis") & ~Keyword("curve") & ~Keyword("showLegend") & ~Keyword("ticks")
    & ~Keyword("max") & ~Keyword("min") & ~Keyword("graticule") & ~Keyword("radar-beta")
END NameStarts;

(* A name, at the position *)
PROCEDURE Name(): Str;
  VAR start, end: LONGINT;
BEGIN
  IF ~NameStarts() THEN sc.Error("expected a name") END;
  start := sc.pos;
  WHILE IsIdChar(sc.Ch()) OR (sc.Ch() = "-") DO INC(sc.pos) END;
  end := sc.pos;
  WHILE sc.t[end - 1] = "-" DO DEC(end) END;
  sc.pos := end;
  RETURN L.Sub(sc.t^, start, end - start)
END Name;

(* A number at the position *)
PROCEDURE Number(VAR x: LONGREAL);
  VAR start: LONGINT; f, p: LONGREAL;
BEGIN
  IF ~L.IsDigit(sc.Ch()) THEN sc.Error("expected a number") END;
  start := sc.pos; x := 0;
  WHILE L.IsDigit(sc.Ch()) DO x := x * 10 + (ORD(sc.Ch()) - ORD("0")); INC(sc.pos) END;
  IF (sc.Ch() = ".") & L.IsDigit(sc.Peek(1)) THEN
    INC(sc.pos); f := 0; p := 1;
    WHILE L.IsDigit(sc.Ch()) DO
      f := f * 10 + (ORD(sc.Ch()) - ORD("0")); p := p * 10; INC(sc.pos)
    END;
    x := x + f / p
  ELSIF (sc.pos - start > 1) & (sc.t[start] = "0") THEN
    sc.ErrorAt(start, "a number cannot start with 0")
  END;
  IF sc.Ch() = "." THEN sc.Error("unexpected .") END;
  IF IsIdChar(sc.Ch()) THEN sc.Error("unexpected text after the number") END
END Number;

(* An optional label, '["text"]', at the position: label and its text,
   or NIL *)
PROCEDURE Label(VAR label: F.Label; VAR text: Str);
  VAR n: LONGINT;
BEGIN
  label := NIL; text := NIL;
  Hidden;
  IF sc.Ch() = "[" THEN
    INC(sc.pos); Hidden;
    IF (sc.Ch() # '"') & (sc.Ch() # "'") THEN sc.Error("expected a quoted label") END;
    String(n); text := L.Sub(buf^, 0, n); label := F.TextLabel(buf^, 0, n);
    Hidden;
    IF sc.Ch() # "]" THEN sc.Error("expected ]") END;
    INC(sc.pos)
  END
END Label;

(* "axis a, b, ...", after "axis" *)
PROCEDURE AxisStmt;
  VAR a: Axis;
BEGIN
  LOOP
    Hidden;
    NEW(a); a.name := Name(); Label(a.label, a.labelText);
    IF a.label = NIL THEN
      a.labelText := a.name; a.label := F.TextLabel(a.name^, 0, L.Length(a.name^))
    END;
    a.next := NIL;
    IF d.axes = NIL THEN d.axes := a ELSE d.lastAxis.next := a END;
    d.lastAxis := a; INC(d.nAxes);
    Hidden;
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos)
  END
END AxisStmt;

(* A curve's entries, after "{", to its "}" *)
PROCEDURE Entries(c: Curve);
  VAR byAxis: BOOLEAN; v: Reals; k: Strs; x: LONGREAL; key: Str; i: LONGINT;
BEGIN
  SkipSpace;
  byAxis := ~L.IsDigit(sc.Ch());
  NEW(c.value, 8); NEW(c.key, 8); c.n := 0;
  LOOP
    key := NIL;
    IF byAxis THEN
      key := Name(); Hidden;
      IF sc.Ch() = ":" THEN INC(sc.pos); Hidden END
    END;
    Number(x);
    IF c.n = LEN(c.value^) THEN
      NEW(v, 2 * c.n); NEW(k, 2 * c.n);
      FOR i := 0 TO c.n - 1 DO v[i] := c.value[i]; k[i] := c.key[i] END;
      c.value := v; c.key := k
    END;
    c.value[c.n] := x; c.key[c.n] := key; INC(c.n);
    Hidden;
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos); SkipSpace
  END;
  SkipSpace;
  IF sc.Ch() # "}" THEN
    IF byAxis THEN sc.Error("expected , or } after the entry, an axis's name and a number")
    ELSE sc.Error("expected , or } after the number")
    END
  END;
  INC(sc.pos);
  IF ~byAxis THEN c.key := NIL END
END Entries;

(* "curve a{...}, b{...}", after "curve" *)
PROCEDURE CurveStmt;
  VAR c: Curve; text: Str;
BEGIN
  LOOP
    Hidden;
    NEW(c); c.at := sc.pos; c.name := Name(); Label(c.label, text);
    IF c.label = NIL THEN c.label := F.TextLabel(c.name^, 0, L.Length(c.name^)) END;
    Hidden;
    IF sc.Ch() # "{" THEN sc.Error("expected { and the curve's values") END;
    INC(sc.pos);
    Entries(c);
    c.index := d.nCurves; INC(d.nCurves); c.next := NIL;
    IF d.curves = NIL THEN d.curves := c ELSE d.lastCurve.next := c END;
    d.lastCurve := c;
    Hidden;
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos)
  END
END CurveStmt;

(* An option, at its name *)
PROCEDURE Option;
  VAR x: LONGREAL;
BEGIN
  IF Keyword("showLegend") THEN
    INC(sc.pos, 10); Hidden;
    IF Keyword("true") THEN d.showLegend := TRUE; INC(sc.pos, 4)
    ELSIF Keyword("false") THEN d.showLegend := FALSE; INC(sc.pos, 5)
    ELSE sc.Error("expected true or false")
    END
  ELSIF Keyword("ticks") THEN
    INC(sc.pos, 5); Hidden; Number(d.ticks)
  ELSIF Keyword("max") THEN
    INC(sc.pos, 3); Hidden; Number(x); d.max := x; d.hasMax := TRUE
  ELSIF Keyword("min") THEN
    INC(sc.pos, 3); Hidden; Number(d.min)
  ELSE (* graticule *)
    INC(sc.pos, 9); Hidden;
    IF Keyword("circle") THEN d.polygon := FALSE; INC(sc.pos, 6)
    ELSIF Keyword("polygon") THEN d.polygon := TRUE; INC(sc.pos, 7)
    ELSE sc.Error("expected circle or polygon")
    END
  END
END Option;

PROCEDURE IsOption(): BOOLEAN;
BEGIN
  RETURN Keyword("showLegend") OR Keyword("ticks") OR Keyword("max") OR Keyword("min")
    OR Keyword("graticule")
END IsOption;

PROCEDURE OptionStmt;
BEGIN
  LOOP
    Hidden;
    IF ~IsOption() THEN sc.Error("expected an option") END;
    Option;
    Hidden;
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos)
  END
END OptionStmt;

(* "title" and the end of its line *)
PROCEDURE TitleStmt;
BEGIN
  INC(sc.pos, 5); Title
END TitleStmt;

PROCEDURE Statement;
BEGIN
  IF sc.LookingAt("title") THEN TitleStmt
  ELSIF sc.LookingAtWord("accTitle") OR sc.LookingAtWord("accDescr") THEN F.Accessibility
  ELSIF Keyword("axis") THEN INC(sc.pos, 4); AxisStmt
  ELSIF Keyword("curve") THEN INC(sc.pos, 5); CurveStmt
  ELSIF IsOption() THEN OptionStmt
  ELSE sc.Error("expected axis, curve, an option, or title")
  END
END Statement;

(* Fails with msg and the text s after it, at the position at *)
PROCEDURE Fail(at: LONGINT; msg: ARRAY OF CHAR; s: Str);
  VAR n, i: LONGINT; m: POINTER TO ARRAY OF CHAR;
BEGIN
  NEW(m, L.Length(msg) + L.Length(s^) + 1); n := 0; i := 0;
  WHILE msg[i] # 0X DO m[n] := msg[i]; INC(n); INC(i) END;
  i := 0;
  WHILE s[i] # 0X DO m[n] := s[i]; INC(n); INC(i) END;
  m[n] := 0X;
  sc.ErrorAt(at, m^)
END Fail;

(* The curves' values given by axis, put in the axes' order *)
PROCEDURE Resolve;
  VAR c: Curve; a: Axis; v: Reals; k, j: LONGINT;
BEGIN
  c := d.curves;
  WHILE c # NIL DO
    IF c.key # NIL THEN
      IF d.axes = NIL THEN
        sc.ErrorAt(c.at, "Axes must be populated before curves for reference entries")
      END;
      NEW(v, d.nAxes + 1); a := d.axes; k := 0;
      WHILE a # NIL DO
        j := 0;
        WHILE (j < c.n) & ~L.Equal(c.key[j], a.name) DO INC(j) END;
        IF j = c.n THEN Fail(c.at, "Missing entry for axis ", a.labelText) END;
        v[k] := c.value[j]; INC(k);
        a := a.next
      END;
      c.value := v; c.n := k; c.key := NIL
    END;
    c := c.next
  END
END Resolve;

(* config.radar.name, a number, or default *)
PROCEDURE Conf(name: ARRAY OF CHAR; default, least: LONGREAL): LONGREAL;
  VAR q: Y.Pair; x: LONGREAL; i: LONGINT;
BEGIN
  q := Y.Find(d.g.config, name);
  IF q = NIL THEN RETURN default END;
  i := 0;
  WHILE L.IsBlank(q.value[i]) DO INC(i) END;
  IF (q.value[i] = 0X) OR ~X.JsParse(q.value, x) OR (x < least) THEN RETURN default END;
  RETURN x
END Conf;

PROCEDURE Configure;
BEGIN
  d.width := Conf("config.radar.width", 600, 1);
  d.height := Conf("config.radar.height", 600, 1);
  d.marginTop := Conf("config.radar.marginTop", 50, 0);
  d.marginRight := Conf("config.radar.marginRight", 50, 0);
  d.marginBottom := Conf("config.radar.marginBottom", 50, 0);
  d.marginLeft := Conf("config.radar.marginLeft", 50, 0);
  d.axisScaleFactor := Conf("config.radar.axisScaleFactor", 1, 0);
  d.axisLabelFactor := Conf("config.radar.axisLabelFactor", 1.05D0, 0);
  d.curveTension := Conf("config.radar.curveTension", 0.17D0, 0);
  IF d.curveTension > 1 THEN d.curveTension := 0.17D0 END
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "radar-beta" *)
PROCEDURE IsRadar*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("radar-beta");
  s.pos := save;
  RETURN r
END IsRadar;

(* Reads the radar chart in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR t: ARRAY 24 OF CHAR; x: LONGREAL;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Radar, d.g); sc := s;
  d.axes := NIL; d.nAxes := 0; d.curves := NIL; d.nCurves := 0;
  d.lastAxis := NIL; d.lastCurve := NIL;
  d.showLegend := TRUE; d.ticks := 5; d.hasMax := FALSE; d.max := 0; d.min := 0;
  d.polygon := FALSE;
  Configure;
  IF ~Keyword("radar-beta") THEN sc.Error("expected radar-beta") END;
  INC(sc.pos, 10); Hidden;
  IF sc.Ch() = ":" THEN INC(sc.pos) END;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Resolve;
  IF d.ticks > MaxTicks THEN
    x := d.ticks; X.JsNumber(x, t);
    PmIO.Message3("radar-beta's ticks (", t, ") are more than 32; 32 are drawn");
    d.ticks := MaxTicks
  END
END Read;

BEGIN
  NEW(buf, 256)
END PmRadar.
