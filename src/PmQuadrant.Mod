MODULE PmQuadrant;
(* PmQuadrant: Mermaid's quadrant charts (`quadrantChart`), read into a
   model of their own: the title, the axes' texts, the quadrants'
   texts, the points with their styles, and the configuration,
   config.quadrantChart.

   The reader follows Mermaid 12.3.0's grammar, packages/mermaid/src/
   diagrams/quadrant-chart/parser/quadrant.jison, and what quadrantDb.ts
   and quadrantBuilder.ts make of it:

   - keywords are read in any case; a statement ends at a line end or
     ";"; "%%" starts a comment, to the end of the line;
   - "title text": the rest of the line, ";" and "%%" too, is the
     title; accTitle and accDescr are read and skipped;
   - "x-axis left", "x-axis left --> right", or "x-axis left -->",
     which adds " ⟶ " to left; "y-axis bottom --> top" likewise. The
     delimiter is two or more "-" and ">". A text not given keeps the
     one given before;
   - "quadrant-1 text" ... "quadrant-4 text": quadrant 1 is the top
     right, 2 the top left, 3 the bottom left, 4 the bottom right;
   - "classDef name styles";
   - a point: "text: [x, y]", or "text:::class: [x, y]", then styles,
     if any. x and y are 1, or 0 or 0.d...; a point's styles override
     its class's, which are looked up when the chart is drawn: a later
     classDef of the name replaces an earlier one;
   - styles are "key: value", separated by commas: radius, digits;
     color and stroke-color, a hexadecimal colour of 3 or 6 digits, "#"
     before it or not (without, Mermaid's SVG has no colour, and the
     default is drawn); stroke-width, digits and "px";
   - a text is words: letters, digits, blanks and punctuation, but
     not ":", ";", ( ) [ ] < > { } | @ ~ ^, a "-->" or a keyword; it
     starts with neither a blank nor "-". It may start with a string in
     quotation marks, "...", anything but '"', or a markdown string,
     "`...`", drawn as its text. It is trimmed.

   Points are kept in the order Mermaid draws them: the last first. *)

IMPORT L := PmLex, F := PmFlow, Y := PmYaml;

CONST
  NoColour* = -1;        (* a colour not given *)
  Invalid* = -2;         (* a colour given without "#": the default is drawn *)

TYPE
  Str = L.Str;

  (* A point's or a class's styles; -1 for each not given *)
  Styles* = RECORD
    radius*: LONGINT;
    colour*, stroke*: LONGINT;   (* 0RRGGBBH, NoColour or Invalid *)
    strokeWidth*: LONGINT        (* pixels *)
  END;

  Class* = POINTER TO ClassDesc;
  ClassDesc* = RECORD
    name-: Str;
    st*: Styles;
    next*: Class
  END;

  Point* = POINTER TO PointDesc;
  PointDesc* = RECORD
    text*: F.Label;
    x*, y*: REAL;          (* from 0 to 1 *)
    class*: Str;           (* or NIL *)
    st*: Styles;           (* its own *)
    next*: Point
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;           (* the title and the configuration *)
    quadrant*: ARRAY 5 OF F.Label;  (* 1 .. 4, or NIL *)
    xLeft*, xRight*, yBottom*, yTop*: F.Label;  (* or NIL *)
    points*: Point; nPoints*: INTEGER;  (* the last read first *)
    classes*: Class;
    (* config.quadrantChart, in Mermaid's pixels *)
    chartWidth*, chartHeight*, titlePadding*, titleFontSize*,
    quadrantPadding*, quadrantTextTopPadding*, quadrantLabelFontSize*,
    xAxisLabelPadding*, yAxisLabelPadding*, xAxisLabelFontSize*,
    yAxisLabelFontSize*, pointTextPadding*, pointLabelFontSize*,
    pointRadius*, internalBorder*, externalBorder*: REAL;
    xAxisTop*, yAxisLeft*: BOOLEAN
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;

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

(* Appends t to s *)
PROCEDURE Append(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
  VAR i, j: LONGINT;
BEGIN
  i := L.Length(s); j := 0;
  WHILE (j < LEN(t)) & (t[j] # 0X) & (i < LEN(s) - 1) DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Append;

PROCEDURE AppendChar(VAR s: ARRAY OF CHAR; ch: CHAR);
  VAR t: ARRAY 2 OF CHAR;
BEGIN
  t[0] := ch; t[1] := 0X; Append(s, t)
END AppendChar;

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether the text at p starts with w, in any case *)
PROCEDURE At(p: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF (p + i >= sc.len) OR (Lower(sc.t[p + i]) # Lower(w[i])) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END At;

(* Whether the text at the position starts with w, in any case *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN At(sc.pos, w)
END Kw;

PROCEDURE IsAlpha(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z")
END IsAlpha;

(* Whether a keyword starts at p *)
PROCEDURE Keyword(p: LONGINT): BOOLEAN;
BEGIN
  RETURN At(p, "title") OR At(p, "classDef") OR At(p, "x-axis") OR At(p, "y-axis")
    OR At(p, "quadrantChart")
    OR At(p, "quadrant-") & (p + 9 < sc.len) & (sc.t[p + 9] >= "1") & (sc.t[p + 9] <= "4")
END Keyword;

(* The length of an axis's delimiter, "-->", at p, or 0 *)
PROCEDURE Arrow(p: LONGINT): LONGINT;
  VAR q: LONGINT;
BEGIN
  q := p;
  WHILE (q < sc.len) & (sc.t[q] = "-") DO INC(q) END;
  IF (q - p >= 2) & (q < sc.len) & (sc.t[q] = ">") THEN RETURN q + 1 - p END;
  RETURN 0
END Arrow;

(* Skips blanks and a comment; the end of the statement must follow,
   and is skipped if it is a ";" *)
PROCEDURE EndOfStatement;
BEGIN
  sc.SkipBlanks;
  IF sc.LookingAt("%%") THEN sc.SkipLine END;
  IF sc.Ch() = ";" THEN INC(sc.pos)
  ELSIF ~sc.AtEnd() & (sc.Ch() # 0AX) THEN sc.Error("expected the end of the statement")
  END
END EndOfStatement;

(* Skips blanks, line ends, ";", comments and directives *)
PROCEDURE SkipSpace;
BEGIN
  sc.SkipSpace
END SkipSpace;

(* The rest of the line, trimmed, as a label; NIL if it is empty *)
PROCEDURE RestOfLine(): F.Label;
  VAR start, end: LONGINT;
BEGIN
  sc.SkipBlanks; start := sc.pos;
  sc.SkipLine; end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  IF end > start THEN RETURN F.TextLabel(sc.t^, start, end) END;
  RETURN NIL
END RestOfLine;

(* A text, at the position, as a label; what names it in a message *)
PROCEDURE Text(what: ARRAY OF CHAR): F.Label;
  VAR n, q: LONGINT; ch: CHAR; plain: BOOLEAN; m: ARRAY 64 OF CHAR;
BEGIN
  n := 0; plain := TRUE;
  IF sc.LookingAt('"`') THEN
    INC(sc.pos, 2);
    WHILE ~sc.AtEnd() & (sc.Ch() # "`") & (sc.Ch() # '"') DO Put(n, sc.Ch()); INC(sc.pos) END;
    IF ~sc.LookingAt('`"') OR (n = 0) THEN sc.Error('a markdown string must end with `"') END;
    INC(sc.pos, 2); plain := FALSE
  ELSIF sc.Ch() = '"' THEN
    INC(sc.pos);
    WHILE ~sc.AtEnd() & (sc.Ch() # '"') DO Put(n, sc.Ch()); INC(sc.pos) END;
    IF sc.AtEnd() THEN sc.Error("the string has no closing quotation mark") END;
    INC(sc.pos); plain := FALSE
  END;
  IF plain THEN
    IF sc.AtEnd() OR (sc.Ch() = 0AX) OR (sc.Ch() = ";") OR sc.LookingAt("%%") THEN
      m := "expected "; Append(m, what); sc.Error(m)
    ELSIF (sc.Ch() = "-") OR (sc.Ch() = ":") THEN
      m := "a "; Append(m, what); Append(m, " cannot start with "); AppendChar(m, sc.Ch());
      sc.Error(m)
    END
  END;
  LOOP
    IF sc.AtEnd() THEN EXIT END;
    ch := sc.Ch();
    IF (ch = 0AX) OR (ch = ";") OR (ch = ":") OR sc.LookingAt("%%") OR (Arrow(sc.pos) > 0) THEN
      EXIT
    ELSIF (ch = '"') OR (ch = "(") OR (ch = ")") OR (ch = "[") OR (ch = "]") OR (ch = "<")
      OR (ch = ">") OR (ch = "{") OR (ch = "}") OR (ch = "|") OR (ch = "@") OR (ch = "~")
      OR (ch = "^") THEN
      m := "unexpected "; AppendChar(m, ch); Append(m, " in a text");
      sc.Error(m)
    ELSIF IsAlpha(ch) & Keyword(sc.pos)
      & ((sc.pos = 0) OR ~IsAlpha(sc.t[sc.pos - 1]) OR (n = 0)) THEN
      sc.Error("a keyword cannot be in a text")
    END;
    Put(n, ch); INC(sc.pos)
  END;
  WHILE (n > 0) & L.IsBlank(buf[n - 1]) DO DEC(n) END;
  q := 0;
  WHILE (q < n) & L.IsBlank(buf[q]) DO INC(q) END;
  buf[n] := 0X;
  RETURN F.TextLabel(buf^, q, n)
END Text;

(* lab with " ⟶ " after it, trimmed *)
PROCEDURE WithArrow(lab: F.Label): F.Label;
  VAR n: LONGINT; s: Str; i: LONGINT;
BEGIN
  s := lab.lines.text; n := 0; i := 0;
  WHILE s[i] # 0X DO Put(n, s[i]); INC(i) END;
  Put(n, " "); Put(n, 0E2X); Put(n, 09FX); Put(n, 0B6X);
  buf[n] := 0X;
  RETURN F.TextLabel(buf^, 0, n)
END WithArrow;

(* "x-axis ..." (x) or "y-axis ...", after the keyword *)
PROCEDURE Axis(x: BOOLEAN);
  VAR a, b: F.Label; k: LONGINT;
BEGIN
  sc.SkipBlanks;
  a := Text("text for the axis"); b := NIL;
  sc.SkipBlanks; k := Arrow(sc.pos);
  IF k > 0 THEN
    INC(sc.pos, k); sc.SkipBlanks;
    IF sc.AtEnd() OR (sc.Ch() = 0AX) OR (sc.Ch() = ";") OR sc.LookingAt("%%") THEN
      a := WithArrow(a)
    ELSE b := Text("text for the axis")
    END
  END;
  IF x THEN d.xLeft := a; IF b # NIL THEN d.xRight := b END
  ELSE d.yBottom := a; IF b # NIL THEN d.yTop := b END
  END;
  EndOfStatement
END Axis;

(* Whether s is a hexadecimal colour, "#" before it or not, of 3 or 6
   digits; c is its value, or Invalid without "#" *)
PROCEDURE Hex(s: ARRAY OF CHAR; VAR c: LONGINT): BOOLEAN;
  VAR i, n, v, k: LONGINT; ch: CHAR; hash: BOOLEAN;
BEGIN
  i := 0; hash := s[0] = "#";
  IF hash THEN i := 1 END;
  n := 0; v := 0;
  LOOP
    ch := s[i + n];
    IF (ch >= "0") & (ch <= "9") THEN k := ORD(ch) - ORD("0")
    ELSIF (ch >= "a") & (ch <= "f") THEN k := ORD(ch) - ORD("a") + 10
    ELSIF (ch >= "A") & (ch <= "F") THEN k := ORD(ch) - ORD("A") + 10
    ELSE EXIT
    END;
    v := v * 16 + k; INC(n)
  END;
  IF (s[i + n] # 0X) OR (n # 3) & (n # 6) THEN RETURN FALSE END;
  IF n = 3 THEN
    v := (v DIV 256) * 11H * 10000H + (v DIV 16 MOD 16) * 11H * 100H + v MOD 16 * 11H
  END;
  IF hash THEN c := v ELSE c := Invalid END;
  RETURN TRUE
END Hex;

(* Fails with Mermaid's message for a style's invalid value *)
PROCEDURE BadValue(at: LONGINT; key, value, kind: ARRAY OF CHAR);
  VAR m: ARRAY 512 OF CHAR;
BEGIN
  m := "value for "; Append(m, key); AppendChar(m, " "); Append(m, value);
  Append(m, " is invalid, please use a valid "); Append(m, kind);
  sc.ErrorAt(at, m)
END BadValue;

(* One style, key: value, in s, read into st *)
PROCEDURE Style(at: LONGINT; s: ARRAY OF CHAR; VAR st: Styles);
  VAR key, value, m: ARRAY 256 OF CHAR; i, j, n: LONGINT;
BEGIN
  i := 0; j := 0;
  WHILE (s[i] # 0X) & (s[i] # ":") & ~L.IsBlank(s[i]) DO
    IF j < LEN(key) - 1 THEN key[j] := s[i]; INC(j) END; INC(i)
  END;
  key[j] := 0X;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF s[i] = ":" THEN
    INC(i);
    WHILE L.IsBlank(s[i]) DO INC(i) END;
    j := 0;
    WHILE (s[i] # 0X) & (s[i] # ":") & ~L.IsBlank(s[i]) DO
      IF j < LEN(value) - 1 THEN value[j] := s[i]; INC(j) END; INC(i)
    END;
    value[j] := 0X
  ELSE
    (* the key and something after blanks: JavaScript's split gives
       one part, the whole *)
    IF s[i] # 0X THEN
      j := 0; i := 0;
      WHILE s[i] # 0X DO IF j < LEN(key) - 1 THEN key[j] := s[i]; INC(j) END; INC(i) END;
      key[j] := 0X
    END;
    value := "undefined"
  END;
  IF key = "radius" THEN
    n := 0; i := 0;
    WHILE L.IsDigit(value[i]) DO n := n * 10 + (ORD(value[i]) - ORD("0")); INC(i) END;
    IF (i = 0) OR (value[i] # 0X) THEN BadValue(at, key, value, "number") END;
    st.radius := n
  ELSIF key = "color" THEN
    IF ~Hex(value, st.colour) THEN BadValue(at, key, value, "hex code") END
  ELSIF key = "stroke-color" THEN
    IF ~Hex(value, st.stroke) THEN BadValue(at, key, value, "hex code") END
  ELSIF key = "stroke-width" THEN
    n := 0; i := 0;
    WHILE L.IsDigit(value[i]) DO n := n * 10 + (ORD(value[i]) - ORD("0")); INC(i) END;
    IF (i = 0) OR (value[i] # "p") OR (value[i + 1] # "x") OR (value[i + 2] # 0X) THEN
      BadValue(at, key, value, "number of pixels (eg. 10px)")
    END;
    st.strokeWidth := n
  ELSE
    m := "style named "; Append(m, key); Append(m, " is not supported.");
    sc.ErrorAt(at, m)
  END
END Style;

PROCEDURE NoStyles(VAR st: Styles);
BEGIN
  st.radius := -1; st.colour := NoColour; st.stroke := NoColour; st.strokeWidth := -1
END NoStyles;

(* Styles, "key: value, ...", to the end of the statement, into st *)
PROCEDURE ReadStyles(VAR st: Styles);
  VAR s: ARRAY 256 OF CHAR; n, at: LONGINT; ch: CHAR; m: ARRAY 64 OF CHAR;
BEGIN
  LOOP
    sc.SkipBlanks; at := sc.pos; n := 0;
    WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & (sc.Ch() # ";") & (sc.Ch() # ",")
      & ~sc.LookingAt("%%") DO
      ch := sc.Ch();
      IF ~(IsAlpha(ch) OR L.IsDigit(ch) OR L.IsBlank(ch) OR (ch = ":") OR (ch = "#")
        OR (ch = "-")) THEN
        m := "unexpected "; AppendChar(m, ch); Append(m, " in a style");
        sc.Error(m)
      END;
      IF n < LEN(s) - 1 THEN s[n] := ch; INC(n) END;
      INC(sc.pos)
    END;
    WHILE (n > 0) & L.IsBlank(s[n - 1]) DO DEC(n) END;
    s[n] := 0X;
    IF n = 0 THEN sc.Error("expected a style, key: value") END;
    Style(at, s, st);
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos)
  END
END ReadStyles;

(* Whether the statement ends here, after blanks *)
PROCEDURE AtEnd(): BOOLEAN;
BEGIN
  sc.SkipBlanks;
  RETURN sc.AtEnd() OR (sc.Ch() = 0AX) OR (sc.Ch() = ";") OR sc.LookingAt("%%")
END AtEnd;

(* "classDef name styles", after the keyword *)
PROCEDURE ClassDef;
  VAR c: Class; start: LONGINT;
BEGIN
  IF ~L.IsBlank(sc.Ch()) THEN sc.Error("expected a blank after classDef") END;
  sc.SkipBlanks; start := sc.pos;
  WHILE ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) & (sc.Ch() # ";") DO INC(sc.pos) END;
  IF sc.pos = start THEN sc.Error("expected a class's name") END;
  NEW(c); c.name := L.Sub(sc.t^, start, sc.pos - start); NoStyles(c.st);
  IF AtEnd() THEN sc.Error("expected the class's styles") END;
  ReadStyles(c.st);
  c.next := d.classes; d.classes := c;
  EndOfStatement
END ClassDef;

(* 1, or 0 or 0.d..., a point's x or y *)
PROCEDURE Coordinate(): REAL;
  VAR x, f: REAL;
BEGIN
  IF sc.Ch() = "1" THEN INC(sc.pos); RETURN 1 END;
  IF sc.Ch() # "0" THEN sc.Error("a point's x and y are 1, or 0 or 0. and digits") END;
  INC(sc.pos); x := 0;
  IF (sc.Ch() = ".") & L.IsDigit(sc.Peek(1)) THEN
    INC(sc.pos); f := 0.1;
    WHILE L.IsDigit(sc.Ch()) DO x := x + f * (ORD(sc.Ch()) - ORD("0")); f := f / 10; INC(sc.pos) END
  END;
  RETURN x
END Coordinate;

(* A point: "text: [x, y] styles" *)
PROCEDURE PointStmt;
  VAR p: Point; start: LONGINT;
BEGIN
  NEW(p); p.text := Text("a point's text, or a statement"); p.class := NIL; NoStyles(p.st);
  IF sc.LookingAt(":::") THEN
    INC(sc.pos, 3); start := sc.pos;
    WHILE L.IsWordChar(sc.Ch()) DO INC(sc.pos) END;
    IF sc.pos = start THEN sc.Error("expected a class's name after :::") END;
    p.class := L.Sub(sc.t^, start, sc.pos - start)
  END;
  sc.SkipBlanks;
  IF sc.Ch() # ":" THEN sc.Error("expected : and the point, [x, y]") END;
  INC(sc.pos); sc.SkipBlanks;
  IF sc.Ch() # "[" THEN sc.Error("expected the point, [x, y]") END;
  INC(sc.pos); sc.SkipBlanks;
  p.x := Coordinate();
  sc.SkipBlanks;
  IF sc.Ch() # "," THEN sc.Error("expected , between the point's x and y") END;
  INC(sc.pos); sc.SkipBlanks;
  p.y := Coordinate();
  sc.SkipBlanks;
  IF sc.Ch() # "]" THEN sc.Error("expected ] after the point's y") END;
  INC(sc.pos);
  IF ~AtEnd() THEN ReadStyles(p.st) END;
  p.next := d.points; d.points := p; INC(d.nPoints);
  EndOfStatement
END PointStmt;

PROCEDURE Statement;
  VAR k: INTEGER;
BEGIN
  IF Kw("title") THEN INC(sc.pos, 5); d.g.title := RestOfLine()
  ELSIF Kw("accTitle") OR Kw("accDescr") THEN F.Accessibility
  ELSIF Kw("x-axis") THEN INC(sc.pos, 6); Axis(TRUE)
  ELSIF Kw("y-axis") THEN INC(sc.pos, 6); Axis(FALSE)
  ELSIF Kw("quadrantChart") THEN sc.Error("unexpected quadrantChart")
  ELSIF Kw("quadrant-") & (sc.Peek(9) >= "1") & (sc.Peek(9) <= "4") THEN
    k := ORD(sc.Peek(9)) - ORD("0"); INC(sc.pos, 10); sc.SkipBlanks;
    d.quadrant[k] := Text("text for the quadrant");
    EndOfStatement
  ELSIF Kw("classDef") THEN INC(sc.pos, 8); ClassDef
  ELSE PointStmt
  END
END Statement;

(* The class named name, the last defined; NIL if there is none *)
PROCEDURE FindClass*(d: Diagram; name: Str): Class;
  VAR c: Class;
BEGIN
  c := d.classes;
  WHILE (c # NIL) & ~L.Equal(c.name, name) DO c := c.next END;
  RETURN c
END FindClass;

(* p's styles: its own, over its class's *)
PROCEDURE PointStyles*(d: Diagram; p: Point; VAR st: Styles);
  VAR c: Class;
BEGIN
  st := p.st;
  IF p.class # NIL THEN
    c := FindClass(d, p.class);
    IF c # NIL THEN
      IF st.radius < 0 THEN st.radius := c.st.radius END;
      IF st.colour = NoColour THEN st.colour := c.st.colour END;
      IF st.stroke = NoColour THEN st.stroke := c.st.stroke END;
      IF st.strokeWidth < 0 THEN st.strokeWidth := c.st.strokeWidth END
    END
  END
END PointStyles;

(* config.quadrantChart.name, a number, or default *)
PROCEDURE Conf(name: ARRAY OF CHAR; default: REAL): REAL;
  VAR q: Y.Pair; i: LONGINT; x, f: REAL; neg, digits: BOOLEAN; s: Str;
    full: ARRAY 64 OF CHAR;
BEGIN
  full := "config.quadrantChart."; Append(full, name);
  q := Y.Find(d.g.config, full);
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
  IF ~digits OR (s[i] # 0X) OR neg THEN RETURN default END;
  RETURN x
END Conf;

PROCEDURE Configure;
  VAR q: Y.Pair;
BEGIN
  d.chartWidth := Conf("chartWidth", 500); d.chartHeight := Conf("chartHeight", 500);
  IF d.chartWidth < 1 THEN d.chartWidth := 500 END;
  IF d.chartHeight < 1 THEN d.chartHeight := 500 END;
  d.titlePadding := Conf("titlePadding", 10); d.titleFontSize := Conf("titleFontSize", 20);
  d.quadrantPadding := Conf("quadrantPadding", 5);
  d.quadrantTextTopPadding := Conf("quadrantTextTopPadding", 5);
  d.quadrantLabelFontSize := Conf("quadrantLabelFontSize", 16);
  d.xAxisLabelPadding := Conf("xAxisLabelPadding", 5);
  d.yAxisLabelPadding := Conf("yAxisLabelPadding", 5);
  d.xAxisLabelFontSize := Conf("xAxisLabelFontSize", 16);
  d.yAxisLabelFontSize := Conf("yAxisLabelFontSize", 16);
  d.pointTextPadding := Conf("pointTextPadding", 5);
  d.pointLabelFontSize := Conf("pointLabelFontSize", 12);
  d.pointRadius := Conf("pointRadius", 5);
  d.internalBorder := Conf("quadrantInternalBorderStrokeWidth", 1);
  d.externalBorder := Conf("quadrantExternalBorderStrokeWidth", 2);
  q := Y.Find(d.g.config, "config.quadrantChart.xAxisPosition");
  d.xAxisTop := (q = NIL) OR ~L.Is(q.value, "bottom");
  q := Y.Find(d.g.config, "config.quadrantChart.yAxisPosition");
  d.yAxisLeft := (q = NIL) OR ~L.Is(q.value, "right")
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "quadrantChart", in any case *)
PROCEDURE IsQuadrant*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s; r := Kw("quadrantChart");
  s.pos := save;
  RETURN r
END IsQuadrant;

(* Reads the quadrant chart in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR k: INTEGER;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Quadrant, d.g); sc := s;
  FOR k := 0 TO 4 DO d.quadrant[k] := NIL END;
  d.xLeft := NIL; d.xRight := NIL; d.yBottom := NIL; d.yTop := NIL;
  d.points := NIL; d.nPoints := 0; d.classes := NIL;
  Configure;
  IF ~Kw("quadrantChart") THEN sc.Error("expected quadrantChart") END;
  INC(sc.pos, 13);
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END
END Read;

BEGIN
  NEW(buf, 256)
END PmQuadrant.
