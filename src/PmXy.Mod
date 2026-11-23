MODULE PmXy;
(* PmXy: Mermaid's XY charts (`xychart`, or `xychart-beta`), read into a
   model of their own: the orientation, the axes, the plots, lines and
   bars, and the configuration, config.xyChart.

   The reader follows Mermaid 12.3.0's grammar, packages/mermaid/src/
   diagrams/xychart/parser/xychart.jison, and what xychartDb.ts makes
   of it. Its lexer is jison's, rule for rule: the first rule that
   matches, in the file's order, makes the token; keywords are read in
   any case, and end where a letter, digit or "_" does not follow;
   some rules hold only in a state, which the tokens push and pop:

   - "x-axis" and "y-axis" push the axis state, where "[" pushes the
     band state, "-->" is an arrow, and a number, [+-]digits[.digits]
     or [+-].digits, is one; "line" and "bar" push the data state,
     where "[" pushes the data's inner state, where a number is one too;
     "]" pops the band and inner states, and a line end the axis and
     data states;
   - "%%" starts a comment, to the end of the line, and takes the
     character before it, a line end too, but for "}";
   - blanks are skipped, and the line ends after them; a line end, or
     ";", may end a statement, and statements need no end;
   - a text is a string in quotation marks, "...", its text trimmed, or
     a markdown string, "`...`", whose text is shown as it is, or
     tokens of letters, digits and + = * # _ . & -, joined without the
     blanks between them.

   The statements are:

   - "xychart" or "xychart-beta", then "horizontal" or "vertical", in
     any case, but only "horizontal" in small letters makes the chart
     horizontal, before the others;
   - "title text";
   - "x-axis text", "x-axis [text, ...]", the categories, or
     "x-axis n --> m", with a text before the data or not;
   - "y-axis text", "y-axis n --> m", or both;
   - "line [n, ...]" and "bar [n, ...]", with a text, the plot's
     title, before the data or not; in a line's data, each number may
     have a string after it, the point's label.

   A plot's data are taken as Mermaid's xychartDb.ts takes them: with
   no x axis set, the first plot's makes it linear, from 1 to the
   number of data; with categories, the data are cut to as many; with
   no y range set, each plot's data widen it. *)

IMPORT L := PmLex, F := PmFlow, Y := PmYaml;

CONST
  (* the tokens *)
  TEnd = 0; TNewline = 1; TSemi = 2; TTitle = 3; TXychart = 4; TOrient = 5;
  TXAxis = 6; TYAxis = 7; TLine = 8; TBar = 9; TNumber = 10; TArrow = 11;
  TOpen = 12; TClose = 13; TStr = 14; TMdStr = 15; TAlnum = 16; TColon = 17;
  TComma = 18;
  (* the lexer's states *)
  SInitial = 0; SAxis = 1; SBand = 2; SData = 3; SInner = 4;

  Inf = 1.0D300;  (* for JavaScript's Infinity *)

TYPE
  Str = L.Str;
  Labels* = POINTER TO ARRAY OF F.Label;
  Strs* = POINTER TO ARRAY OF Str;
  Ints = POINTER TO ARRAY OF INTEGER;

  (* An axis's settings, config.xyChart.xAxis or yAxis, in pixels *)
  AxisConfig* = RECORD
    showLabel*, showTitle*, showTick*, showAxisLine*: BOOLEAN;
    labelFontSize*, labelPadding*, titleFontSize*, titlePadding*,
    tickLength*, tickWidth*, axisLineWidth*: LONGREAL;
    labelRotation*: LONGREAL      (* degrees, from -90 to 90 *)
  END;

  Axis* = RECORD
    linear*: BOOLEAN;             (* or a band, of categories *)
    title*: F.Label;              (* or NIL *)
    cat*: Labels; key*: Strs;     (* the categories, as shown and as text *)
    nCat*: LONGINT;
    min*, max*: LONGREAL          (* a linear axis's range; a y axis
                                     with no data has min > max *)
  END;

  (* A datum: its x, a category or a number, as Mermaid keeps it, and
     its y *)
  Datum* = RECORD
    key*: Str;                    (* the x, as text *)
    num*: LONGREAL; isNum*: BOOLEAN;  (* the x, made from a number *)
    y*: LONGREAL;
    def*: BOOLEAN;                (* whether there is a y *)
    shown*: Str;                  (* y, as JavaScript writes it *)
    label*: F.Label               (* a line's point's label, or NIL *)
  END;
  Data* = POINTER TO ARRAY OF Datum;

  Plot* = POINTER TO PlotDesc;
  PlotDesc* = RECORD
    bar*: BOOLEAN;                (* or a line *)
    title*: F.Label;              (* or NIL *)
    index*: INTEGER;              (* its colour's, in the palette *)
    data*: Data; n*: LONGINT;
    next*: Plot
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;                  (* the title and the configuration *)
    horizontal*: BOOLEAN;
    x*, y*: Axis;
    plots*: Plot; nPlots*: INTEGER;
    (* config.xyChart, in Mermaid's pixels *)
    width*, height*, titleFontSize*, titlePadding*, legendFontSize*,
    legendPadding*, reserved*: LONGREAL;  (* plotReservedSpacePercent *)
    showDataLabel*, outside*,     (* showDataLabelOutsideBar *)
    showTitle*, showLegend*: BOOLEAN;
    axis*: ARRAY 2 OF AxisConfig  (* x, y *)
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;
  lastPlot: Plot;
  hasSetX, hasSetY: BOOLEAN;
  (* the lexer *)
  stack: Ints;
  depth: LONGINT;
  tok: INTEGER;
  tokStart, tokEnd: LONGINT;      (* the token's text; a string's inside *)
  lowerHorizontal: BOOLEAN;       (* TOrient is "horizontal" *)

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

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

PROCEDURE IsAlpha(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z")
END IsAlpha;

(* JavaScript's \w *)
PROCEDURE IsWord(ch: CHAR): BOOLEAN;
BEGIN
  RETURN IsAlpha(ch) OR L.IsDigit(ch) OR (ch = "_")
END IsWord;

(* JavaScript's \s, in ASCII *)
PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch >= 09X) & (ch <= 0DX)
END IsSpace;

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

(* Whether the keyword w is at the position: in any case, and with no
   letter, digit or "_" after it *)
PROCEDURE Word(w: ARRAY OF CHAR): BOOLEAN;
  VAR n: LONGINT;
BEGIN
  n := L.Length(w);
  RETURN At(sc.pos, w) & ((sc.pos + n >= sc.len) OR ~IsWord(sc.t[sc.pos + n]))
END Word;

PROCEDURE Push(s: INTEGER);
  VAR b: Ints; k: LONGINT;
BEGIN
  IF depth = LEN(stack^) THEN
    NEW(b, 2 * LEN(stack^));
    FOR k := 0 TO depth - 1 DO b[k] := stack[k] END;
    stack := b
  END;
  stack[depth] := s; INC(depth)
END Push;

PROCEDURE Pop;
BEGIN
  IF depth > 1 THEN DEC(depth) END
END Pop;

PROCEDURE Top(): INTEGER;
BEGIN
  RETURN stack[depth - 1]
END Top;

(* Moves to the end of the line, before its line end *)
PROCEDURE ToLineEnd;
BEGIN
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) DO INC(sc.pos) END
END ToLineEnd;

PROCEDURE SkipSpaces(VAR p: LONGINT);
BEGIN
  WHILE (p < sc.len) & IsSpace(sc.t[p]) DO INC(p) END
END SkipSpaces;

(* accTitle: text, accDescr: text, or accDescr { text }, at the
   position, skipped; FALSE if there is none *)
PROCEDURE Accessibility(): BOOLEAN;
  VAR p: LONGINT;
BEGIN
  IF At(sc.pos, "accTitle") OR At(sc.pos, "accDescr") THEN
    p := sc.pos + 8; SkipSpaces(p);
    IF (p < sc.len) & (sc.t[p] = ":") THEN
      sc.pos := p + 1; ToLineEnd; RETURN TRUE
    ELSIF (p < sc.len) & (sc.t[p] = "{") & At(sc.pos, "accDescr") THEN
      sc.pos := p + 1;
      WHILE ~sc.AtEnd() & (sc.Ch() # "}") DO INC(sc.pos) END;
      IF sc.AtEnd() THEN sc.Error("accDescr { has no }") END;
      INC(sc.pos); RETURN TRUE
    END
  END;
  RETURN FALSE
END Accessibility;

(* A number, [+-]?(\d+(\.\d+)?|\.\d+), at the position: its length,
   or 0 *)
PROCEDURE NumberAt(): LONGINT;
  VAR p, q: LONGINT;
BEGIN
  p := sc.pos;
  IF (sc.t[p] = "+") OR (sc.t[p] = "-") THEN INC(p) END;
  q := p;
  WHILE (q < sc.len) & L.IsDigit(sc.t[q]) DO INC(q) END;
  IF q > p THEN
    IF (q + 1 < sc.len) & (sc.t[q] = ".") & L.IsDigit(sc.t[q + 1]) THEN
      INC(q);
      WHILE (q < sc.len) & L.IsDigit(sc.t[q]) DO INC(q) END
    END;
    RETURN q - sc.pos
  ELSIF (q + 1 < sc.len) & (sc.t[q] = ".") & L.IsDigit(sc.t[q + 1]) THEN
    INC(q);
    WHILE (q < sc.len) & L.IsDigit(sc.t[q]) DO INC(q) END;
    RETURN q - sc.pos
  END;
  RETURN 0
END NumberAt;

(* The next token, in tok *)
PROCEDURE Next;
  VAR ch: CHAR; top: INTEGER; n: LONGINT;

  PROCEDURE Take(t: INTEGER; len: LONGINT);
  BEGIN
    tok := t; tokStart := sc.pos; INC(sc.pos, len); tokEnd := sc.pos
  END Take;

BEGIN
  LOOP
    IF sc.AtEnd() THEN tok := TEnd; tokStart := sc.pos; tokEnd := sc.pos; RETURN END;
    top := Top(); ch := sc.Ch();
    IF sc.LookingAt("%%") & (sc.Peek(2) # "{") THEN ToLineEnd
    ELSIF (ch # "}") & (sc.Peek(1) = "%") & (sc.Peek(2) = "%") THEN INC(sc.pos); ToLineEnd
    ELSIF ((top = SAxis) OR (top = SData))
      & ((ch = 0AX) OR (ch = 0DX) & (sc.Peek(1) = 0AX)) THEN
      Pop;
      IF ch = 0DX THEN Take(TNewline, 2) ELSE Take(TNewline, 1) END;
      RETURN
    ELSIF (ch = 0AX) OR (ch = 0DX) THEN
      tokStart := sc.pos;
      WHILE (sc.Ch() = 0AX) OR (sc.Ch() = 0DX) DO INC(sc.pos) END;
      tok := TNewline; tokEnd := sc.pos; RETURN
    ELSIF sc.LookingAt("%%") THEN ToLineEnd
    ELSIF Word("title") THEN Take(TTitle, 5); RETURN
    ELSIF Accessibility() THEN
    ELSIF Word("xychart-beta") THEN Take(TXychart, 12); RETURN
    ELSIF Word("xychart") THEN Take(TXychart, 7); RETURN
    ELSIF At(sc.pos, "vertical") THEN
      lowerHorizontal := FALSE; Take(TOrient, 8); RETURN
    ELSIF At(sc.pos, "horizontal") THEN
      lowerHorizontal := sc.LookingAt("horizontal"); Take(TOrient, 10); RETURN
    ELSIF Word("x-axis") THEN Push(SAxis); Take(TXAxis, 6); RETURN
    ELSIF Word("y-axis") THEN Push(SAxis); Take(TYAxis, 6); RETURN
    ELSIF (top = SAxis) & (ch = "[") THEN Push(SBand); Take(TOpen, 1); RETURN
    ELSIF (top = SAxis) & sc.LookingAt("-->") THEN Take(TArrow, 3); RETURN
    ELSIF Word("line") THEN Push(SData); Take(TLine, 4); RETURN
    ELSIF Word("bar") THEN Push(SData); Take(TBar, 3); RETURN
    ELSIF (top = SData) & (ch = "[") THEN Push(SInner); Take(TOpen, 1); RETURN
    ELSIF ((top = SAxis) OR (top = SInner)) & (NumberAt() > 0) THEN
      Take(TNumber, NumberAt()); RETURN
    ELSIF ((top = SInner) OR (top = SBand)) & (ch = "]") THEN Pop; Take(TClose, 1); RETURN
    ELSIF sc.LookingAt('"`') THEN
      INC(sc.pos, 2); tokStart := sc.pos;
      WHILE ~sc.AtEnd() & ~sc.LookingAt('`"') & (sc.Ch() # 0AX) & (sc.Ch() # 0DX) DO
        INC(sc.pos)
      END;
      tokEnd := sc.pos;
      IF tokEnd > tokStart THEN tok := TMdStr; RETURN END;
      IF sc.AtEnd() THEN tok := TEnd; RETURN END;
      IF ~sc.LookingAt('`"') THEN sc.Error("a markdown string cannot hold a line end") END;
      INC(sc.pos, 2)
    ELSIF ch = '"' THEN
      INC(sc.pos); tokStart := sc.pos;
      WHILE ~sc.AtEnd() & (sc.Ch() # '"') DO INC(sc.pos) END;
      tokEnd := sc.pos;
      IF ~sc.AtEnd() THEN INC(sc.pos) END;
      IF tokEnd > tokStart THEN tok := TStr; RETURN END
    ELSIF (ch = "[") THEN Take(TOpen, 1); RETURN
    ELSIF (ch = "]") THEN Take(TClose, 1); RETURN
    ELSIF IsAlpha(ch) THEN
      n := 0;
      WHILE (sc.pos + n < sc.len) & IsAlpha(sc.t[sc.pos + n]) DO INC(n) END;
      Take(TAlnum, n); RETURN
    ELSIF ch = ":" THEN Take(TColon, 1); RETURN
    ELSIF ch = "," THEN Take(TComma, 1); RETURN
    ELSIF (ch = "+") OR (ch = "=") OR (ch = "*") OR (ch = "#") OR (ch = "_") OR (ch = ".")
      OR (ch = "&") OR (ch = "-") THEN
      Take(TAlnum, 1); RETURN
    ELSIF L.IsDigit(ch) THEN
      n := 0;
      WHILE (sc.pos + n < sc.len) & L.IsDigit(sc.t[sc.pos + n]) DO INC(n) END;
      Take(TAlnum, n); RETURN
    ELSIF IsSpace(ch) THEN
      WHILE ~sc.AtEnd() & IsSpace(sc.Ch()) DO INC(sc.pos) END
    ELSIF ch = ";" THEN Take(TSemi, 1); RETURN
    ELSE sc.Error("unexpected character")
    END
  END
END Next;

(* Whether the token may start a text *)
PROCEDURE IsText(): BOOLEAN;
BEGIN
  RETURN (tok = TAlnum) OR (tok = TStr) OR (tok = TMdStr)
END IsText;

(* buf[0 .. n-1], with line ends and tabs as blanks, trimmed, as a
   label; NIL if it is empty *)
PROCEDURE Trimmed(n: LONGINT): F.Label;
  VAR q, k: LONGINT;
BEGIN
  FOR k := 0 TO n - 1 DO
    IF IsSpace(buf[k]) THEN buf[k] := " " END
  END;
  WHILE (n > 0) & (buf[n - 1] = " ") DO DEC(n) END;
  q := 0;
  WHILE (q < n) & (buf[q] = " ") DO INC(q) END;
  buf[n] := 0X;
  IF n = q THEN RETURN NIL END;
  RETURN F.TextLabel(buf^, q, n)
END Trimmed;

(* A text, at the token, read into buf[0 .. n-1] *)
PROCEDURE ReadText(VAR n: LONGINT);
  VAR k: LONGINT;
BEGIN
  n := 0;
  IF (tok = TStr) OR (tok = TMdStr) THEN
    FOR k := tokStart TO tokEnd - 1 DO Put(n, sc.t[k]) END;
    Next
  ELSE
    WHILE tok = TAlnum DO
      FOR k := tokStart TO tokEnd - 1 DO Put(n, sc.t[k]) END;
      Next
    END
  END;
  Put(n, 0X); DEC(n)
END ReadText;

(* A text, at the token, trimmed, as a label, or NIL; key is its text *)
PROCEDURE Text(VAR key: Str): F.Label;
  VAR n, q: LONGINT; lab: F.Label;
BEGIN
  ReadText(n);
  lab := Trimmed(n);
  n := L.Length(buf^);
  WHILE (n > 0) & (buf[n - 1] = " ") DO DEC(n) END;
  q := 0;
  WHILE (q < n) & (buf[q] = " ") DO INC(q) END;
  key := L.Sub(buf^, q, n - q);
  RETURN lab
END Text;

(* The number at the token, its value x and its text as JavaScript
   writes it, shown *)
PROCEDURE Number(VAR x: LONGREAL; VAR shown: Str);
  VAR p, e, is, ie, fs, fe, k: LONGINT; neg: BOOLEAN; f, pw: LONGREAL;
BEGIN
  IF tok # TNumber THEN sc.ErrorAt(tokStart, "expected a number") END;
  p := tokStart; e := tokEnd; neg := sc.t[p] = "-";
  IF (sc.t[p] = "-") OR (sc.t[p] = "+") THEN INC(p) END;
  is := p; x := 0;
  WHILE (p < e) & L.IsDigit(sc.t[p]) DO x := x * 10 + (ORD(sc.t[p]) - ORD("0")); INC(p) END;
  ie := p; fs := p; fe := p;
  IF (p < e) & (sc.t[p] = ".") THEN
    INC(p); fs := p; f := 0; pw := 1;
    WHILE p < e DO f := f * 10 + (ORD(sc.t[p]) - ORD("0")); pw := pw * 10; INC(p) END;
    fe := p; x := x + f / pw
  END;
  WHILE (ie - is > 0) & (sc.t[is] = "0") DO INC(is) END;
  WHILE (fe > fs) & (sc.t[fe - 1] = "0") DO DEC(fe) END;
  k := 0;
  IF neg & (x # 0) THEN Put(k, "-") END;
  IF ie = is THEN Put(k, "0") END;
  WHILE is < ie DO Put(k, sc.t[is]); INC(is) END;
  IF fe > fs THEN
    Put(k, ".");
    WHILE fs < fe DO Put(k, sc.t[fs]); INC(fs) END
  END;
  buf[k] := 0X; shown := L.Sub(buf^, 0, k);
  IF neg THEN x := -x END;
  Next
END Number;

(* x as JavaScript writes it, to 15 digits *)
PROCEDURE JsNumber*(x: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR digits: ARRAY 32 OF CHAR; e, k, i, n: LONGINT; m: LONGREAL;
BEGIN
  i := 0;
  IF x # x THEN COPY("NaN", s); RETURN END;
  IF x < 0 THEN s[0] := "-"; i := 1; x := -x END;
  IF x = 0 THEN s[i] := "0"; s[i + 1] := 0X; RETURN END;
  (* 15 significant digits, x = 0.d1d2... * 10^e *)
  e := 0; m := x;
  WHILE m >= 1 DO m := m / 10; INC(e) END;
  WHILE m < 0.1D0 DO m := m * 10; DEC(e) END;
  n := 0;
  WHILE n < 15 DO
    m := m * 10; k := ENTIER(m);
    IF k > 9 THEN k := 9 END;
    digits[n] := CHR(ORD("0") + k); m := m - k; INC(n)
  END;
  IF m >= 0.5D0 THEN
    k := n - 1;
    LOOP
      IF k < 0 THEN
        FOR k := n - 1 TO 1 BY -1 DO digits[k] := digits[k - 1] END;
        digits[0] := "1"; INC(e); EXIT
      ELSIF digits[k] = "9" THEN digits[k] := "0"; DEC(k)
      ELSE digits[k] := CHR(ORD(digits[k]) + 1); EXIT
      END
    END
  END;
  WHILE (n > 1) & (digits[n - 1] = "0") DO DEC(n) END;
  IF e <= 0 THEN
    s[i] := "0"; s[i + 1] := "."; INC(i, 2);
    WHILE e < 0 DO s[i] := "0"; INC(i); INC(e) END;
    FOR k := 0 TO n - 1 DO s[i] := digits[k]; INC(i) END
  ELSE
    FOR k := 0 TO n - 1 DO
      IF k = e THEN s[i] := "."; INC(i) END;
      s[i] := digits[k]; INC(i)
    END;
    FOR k := n TO e - 1 DO s[i] := "0"; INC(i) END
  END;
  s[i] := 0X
END JsNumber;

(* JavaScript's Number(s), for a decimal number with blanks round it,
   or nothing, 0; FALSE if it is not one, NaN *)
PROCEDURE JsParse*(s: Str; VAR x: LONGREAL): BOOLEAN;
  VAR i, ex: LONGINT; neg, eneg, digits: BOOLEAN; f, p: LONGREAL;
BEGIN
  i := 0; x := 0; neg := FALSE; digits := FALSE;
  WHILE IsSpace(s[i]) DO INC(i) END;
  IF s[i] = 0X THEN RETURN TRUE END;
  IF (s[i] = "-") OR (s[i] = "+") THEN neg := s[i] = "-"; INC(i) END;
  WHILE L.IsDigit(s[i]) DO x := x * 10 + (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE END;
  IF s[i] = "." THEN
    INC(i); f := 0; p := 1;
    WHILE L.IsDigit(s[i]) DO f := f * 10 + (ORD(s[i]) - ORD("0")); p := p * 10; INC(i); digits := TRUE END;
    x := x + f / p
  END;
  IF ~digits THEN RETURN FALSE END;
  IF (s[i] = "e") OR (s[i] = "E") THEN
    INC(i); eneg := FALSE; ex := 0;
    IF (s[i] = "-") OR (s[i] = "+") THEN eneg := s[i] = "-"; INC(i) END;
    IF ~L.IsDigit(s[i]) THEN RETURN FALSE END;
    WHILE L.IsDigit(s[i]) DO
      IF ex < 1000 THEN ex := ex * 10 + (ORD(s[i]) - ORD("0")) END; INC(i)
    END;
    WHILE ex > 0 DO
      IF eneg THEN x := x / 10 ELSE x := x * 10 END;
      DEC(ex)
    END
  END;
  WHILE IsSpace(s[i]) DO INC(i) END;
  IF s[i] # 0X THEN RETURN FALSE END;
  IF neg THEN x := -x END;
  RETURN TRUE
END JsParse;

(* The keys of a linear x axis's data, n of them, into p.data *)
PROCEDURE LinearKeys(p: Plot);
  VAR k: LONGINT; step, x: LONGREAL; s: ARRAY 64 OF CHAR;
BEGIN
  IF p.n = 1 THEN step := 0 ELSE step := (d.x.max - d.x.min) / (p.n - 1) END;
  FOR k := 0 TO p.n - 1 DO
    x := d.x.min + k * step;
    JsNumber(x, s);
    p.data[k].key := L.New(s); p.data[k].num := x; p.data[k].isNum := TRUE
  END
END LinearKeys;

(* "[n "label", ...]": a plot's data, read into p, as xychartDb.ts's
   transformDataWithoutCategory makes them *)
PROCEDURE PlotData(p: Plot; line: BOOLEAN);
  VAR v: Data; n, k, m: LONGINT; key: Str; any: BOOLEAN; b: Data;
BEGIN
  IF tok # TOpen THEN sc.ErrorAt(tokStart, "expected the data, [n, ...]") END;
  Next;
  NEW(v, 8); n := 0; any := FALSE;
  LOOP
    IF n = LEN(v^) THEN
      NEW(b, 2 * n);
      FOR k := 0 TO n - 1 DO b[k] := v[k] END;
      v := b
    END;
    Number(v[n].y, v[n].shown); v[n].def := TRUE; v[n].label := NIL;
    IF tok = TStr THEN
      v[n].label := Text(key);
      IF ~line THEN v[n].label := NIL END;  (* a bar's are not shown *)
      IF v[n].label # NIL THEN any := TRUE END
    END;
    INC(n);
    IF tok = TClose THEN Next; EXIT END;
    IF tok # TComma THEN sc.ErrorAt(tokStart, "expected , or ] in the data") END;
    Next
  END;
  IF ~any THEN
    FOR k := 0 TO n - 1 DO v[k].label := NIL END
  END;
  IF ~hasSetX THEN
    d.x.linear := TRUE; d.x.min := 1; d.x.max := n; hasSetX := TRUE
  END;
  IF ~d.x.linear & (n > d.x.nCat) THEN n := d.x.nCat END;
  IF ~hasSetY THEN
    FOR k := 0 TO n - 1 DO
      IF v[k].y < d.y.min THEN d.y.min := v[k].y END;
      IF v[k].y > d.y.max THEN d.y.max := v[k].y END
    END
  END;
  IF d.x.linear THEN
    p.data := v; p.n := n; LinearKeys(p)
  ELSE
    m := d.x.nCat; NEW(p.data, m); p.n := m;
    FOR k := 0 TO m - 1 DO
      IF k < n THEN p.data[k] := v[k]
      ELSE p.data[k].def := FALSE; p.data[k].shown := NIL; p.data[k].label := NIL; p.data[k].y := 0
      END;
      IF k < LEN(v^) THEN p.data[k].label := v[k].label END;
      p.data[k].key := d.x.key[k]; p.data[k].isNum := FALSE; p.data[k].num := 0
    END
  END
END PlotData;

(* "line ..." or "bar ...", after the keyword *)
PROCEDURE PlotStmt(bar: BOOLEAN);
  VAR p: Plot; key: Str;
BEGIN
  NEW(p); p.bar := bar; p.title := NIL; p.index := d.nPlots; p.next := NIL;
  IF IsText() THEN p.title := Text(key) END;
  PlotData(p, ~bar);
  IF d.plots = NIL THEN d.plots := p ELSE lastPlot.next := p END;
  lastPlot := p; INC(d.nPlots)
END PlotStmt;

(* "n --> m", a linear axis's range *)
PROCEDURE Range(VAR a: Axis);
  VAR s: Str;
BEGIN
  Number(a.min, s);
  IF tok # TArrow THEN sc.ErrorAt(tokStart, "expected -->") END;
  Next;
  Number(a.max, s);
  a.linear := TRUE
END Range;

(* "[text, ...]", the x axis's categories *)
PROCEDURE Categories;
  VAR n, k: LONGINT; cat, c: Labels; key, ky: Strs;
BEGIN
  Next;
  NEW(cat, 8); NEW(key, 8); n := 0;
  LOOP
    IF ~IsText() THEN sc.ErrorAt(tokStart, "expected a category") END;
    IF n = LEN(cat^) THEN
      NEW(c, 2 * n); NEW(ky, 2 * n);
      FOR k := 0 TO n - 1 DO c[k] := cat[k]; ky[k] := key[k] END;
      cat := c; key := ky
    END;
    cat[n] := Text(key[n]); INC(n);
    IF tok = TClose THEN Next; EXIT END;
    IF tok # TComma THEN sc.ErrorAt(tokStart, "expected , or ] after a category") END;
    Next
  END;
  d.x.linear := FALSE; d.x.cat := cat; d.x.key := key; d.x.nCat := n
END Categories;

(* "x-axis ..." (x) or "y-axis ...", after the keyword *)
PROCEDURE AxisStmt(x: BOOLEAN);
  VAR title: F.Label; key: Str; text: BOOLEAN;
BEGIN
  title := NIL; text := IsText();
  IF text THEN title := Text(key) END;
  IF x & (tok = TOpen) THEN Categories; hasSetX := TRUE
  ELSIF tok = TNumber THEN
    IF x THEN Range(d.x); hasSetX := TRUE ELSE Range(d.y); hasSetY := TRUE END
  ELSIF ~text THEN
    IF x THEN sc.ErrorAt(tokStart, "expected the x axis's title or data")
    ELSE sc.ErrorAt(tokStart, "expected the y axis's title or range")
    END
  END;
  IF x THEN d.x.title := title ELSE d.y.title := title END
END AxisStmt;

PROCEDURE Statement;
  VAR key: Str;
BEGIN
  CASE tok OF
    TNewline, TSemi: Next
  | TTitle:
    Next;
    IF ~IsText() THEN sc.ErrorAt(tokStart, "expected the title") END;
    d.g.title := Text(key)
  | TXAxis: Next; AxisStmt(TRUE)
  | TYAxis: Next; AxisStmt(FALSE)
  | TLine: Next; PlotStmt(FALSE)
  | TBar: Next; PlotStmt(TRUE)
  | TXychart: sc.ErrorAt(tokStart, "unexpected xychart")
  ELSE sc.ErrorAt(tokStart, "expected a statement")
  END
END Statement;

(* config.xyChart.name, or default *)
PROCEDURE Find(name: ARRAY OF CHAR): Y.Pair;
  VAR full: ARRAY 64 OF CHAR; i, j: LONGINT;
BEGIN
  full := "config.xyChart."; i := L.Length(full); j := 0;
  WHILE name[j] # 0X DO full[i] := name[j]; INC(i); INC(j) END;
  full[i] := 0X;
  RETURN Y.Find(d.g.config, full)
END Find;

(* config.xyChart.name, a number, or default *)
PROCEDURE Num(name: ARRAY OF CHAR; default: LONGREAL): LONGREAL;
  VAR q: Y.Pair; x: LONGREAL;
BEGIN
  q := Find(name);
  IF (q = NIL) OR ~JsParse(q.value, x) OR (q.value[0] = 0X) THEN RETURN default END;
  RETURN x
END Num;

(* config.xyChart.name, true or false, or default *)
PROCEDURE Bool(name: ARRAY OF CHAR; default: BOOLEAN): BOOLEAN;
  VAR q: Y.Pair;
BEGIN
  q := Find(name);
  IF q = NIL THEN RETURN default END;
  IF L.Is(q.value, "true") THEN RETURN TRUE END;
  IF L.Is(q.value, "false") THEN RETURN FALSE END;
  RETURN default
END Bool;

PROCEDURE AxisConf(VAR a: AxisConfig; name: ARRAY OF CHAR);
  VAR key: ARRAY 48 OF CHAR;

  PROCEDURE K(n: ARRAY OF CHAR);
    VAR i, j: LONGINT;
  BEGIN
    i := 0;
    WHILE name[i] # 0X DO key[i] := name[i]; INC(i) END;
    key[i] := "."; INC(i); j := 0;
    WHILE n[j] # 0X DO key[i] := n[j]; INC(i); INC(j) END;
    key[i] := 0X
  END K;

BEGIN
  K("showLabel"); a.showLabel := Bool(key, TRUE);
  K("labelFontSize"); a.labelFontSize := Num(key, 14);
  K("labelPadding"); a.labelPadding := Num(key, 5);
  K("showTitle"); a.showTitle := Bool(key, TRUE);
  K("titleFontSize"); a.titleFontSize := Num(key, 16);
  K("titlePadding"); a.titlePadding := Num(key, 5);
  K("showTick"); a.showTick := Bool(key, TRUE);
  K("tickLength"); a.tickLength := Num(key, 5);
  K("tickWidth"); a.tickWidth := Num(key, 2);
  K("showAxisLine"); a.showAxisLine := Bool(key, TRUE);
  K("axisLineWidth"); a.axisLineWidth := Num(key, 2);
  K("labelRotation"); a.labelRotation := Num(key, 0);
  IF (a.labelRotation < -90) OR (a.labelRotation > 90) THEN a.labelRotation := 0 END
END AxisConf;

PROCEDURE Configure;
  VAR q: Y.Pair;
BEGIN
  d.width := Num("width", 700); d.height := Num("height", 500);
  IF d.width < 1 THEN d.width := 700 END;
  IF d.height < 1 THEN d.height := 500 END;
  d.titleFontSize := Num("titleFontSize", 20); d.titlePadding := Num("titlePadding", 10);
  d.showDataLabel := Bool("showDataLabel", FALSE);
  d.outside := Bool("showDataLabelOutsideBar", FALSE);
  d.showTitle := Bool("showTitle", TRUE); d.showLegend := Bool("showLegend", TRUE);
  d.legendFontSize := Num("legendFontSize", 14); d.legendPadding := Num("legendPadding", 10);
  d.reserved := Num("plotReservedSpacePercent", 50);
  q := Find("chartOrientation");
  d.horizontal := (q # NIL) & L.Is(q.value, "horizontal");
  AxisConf(d.axis[0], "xAxis"); AxisConf(d.axis[1], "yAxis")
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "xychart" *)
PROCEDURE IsXy*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("xychart");
  s.pos := save;
  RETURN r
END IsXy;

(* Reads the XY chart in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR seen: BOOLEAN;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Xy, d.g); sc := s;
  d.plots := NIL; d.nPlots := 0; lastPlot := NIL;
  d.x.linear := FALSE; d.x.title := NIL; d.x.cat := NIL; d.x.key := NIL; d.x.nCat := 0;
  d.x.min := Inf; d.x.max := -Inf;
  d.y := d.x; d.y.linear := TRUE;
  hasSetX := FALSE; hasSetY := FALSE;
  Configure;
  NEW(stack, 16); stack[0] := SInitial; depth := 1;
  Next; seen := FALSE;
  LOOP
    IF tok = TXychart THEN
      seen := TRUE; Next;
      IF tok = TOrient THEN d.horizontal := lowerHorizontal; Next END
    ELSIF (tok = TNewline) OR (tok = TSemi) THEN Next
    ELSE EXIT
    END
  END;
  IF ~seen THEN sc.ErrorAt(tokStart, "expected xychart") END;
  WHILE tok # TEnd DO Statement END;
  IF d.plots = NIL THEN sc.Error("No Plot to render, please provide a plot with some data") END
END Read;

BEGIN
  NEW(buf, 256)
END PmXy.
