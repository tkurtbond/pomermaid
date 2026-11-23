MODULE PmStyle;
(* PmStyle: the colours, line widths and dashes of a flowchart's nodes,
   edges and subgraphs, for the writers. They are Mermaid's default theme's, with
   lengths in Mermaid's pixels scaled to the labels' size (16 pixels to
   the size), changed by classDef "default", the node's classes and its
   style statements, in that order, and by linkStyle for edges. The
   theme's colours can be changed by themeVariables, the default
   theme's that the flowchart's styles use.

   The colours a diagram uses are kept in a table, each once, in the
   order they are first used; a style refers to them by their index. *)

IMPORT PmIO, F := PmFlow, Lx := PmLex, Y := PmYaml;

CONST
  MaxColours = 4096;
  NoColour* = -1;
  (* Mermaid's default theme *)
  NodeFill = 0ECECFFH; NodeLine = 09370DBH; TextColour = 0333333H;
  EdgeLine = 0333333H;
  LabelBack = 0E8E8E8H;  (* behind an edge's label *)
  ClusterFill = 0FFFFDEH; ClusterLine = 0AAAA33H;
  (* and its state diagrams' *)
  NoteFill = 0FFF5ADH; NoteLine = 0AAAA33H;
  CompositeBack = 0FFFFFFH; AltBack = 0F0F0F0H;
  (* and its ER diagrams', an entity's attributes' rows *)
  RowOdd = 0FFFFFFH; RowEven = 0F1F1FFH;
  None = -1;  (* a theme's colour that is none *)

TYPE
  (* A sequence diagram's colours, as 0RRGGBBH, or -1 for none *)
  SeqTheme* = RECORD
    actorFill*, actorLine*, actorText*, lifeline*,
    signal*, signalText*,
    labelFill*, labelLine*, labelText*, loopText*,
    noteFill*, noteLine*, noteText*,
    barFill*, barLine*, number*, numberText*, title*: LONGINT
  END;

  (* A user journey's colours, as 0RRGGBBH, or -1 for none *)
  JourneyTheme* = RECORD
    fill*: ARRAY 8 OF LONGINT;   (* the sections' and tasks', fillType0..7 *)
    actor*: ARRAY 6 OF LONGINT;  (* the actors' circles, actor0..5 *)
    face*, faceLine*, mouth*, line*, text*, boxLine*, boxText*, title*: LONGINT
  END;

  (* A timeline's colours, as 0RRGGBBH *)
  TimelineTheme* = RECORD
    scale*, label*, inv*: ARRAY 12 OF LONGINT;  (* cScale0..11, the nodes'
                                    fills; cScaleLabel0..11, their text;
                                    cScaleInv0..11, their bottom lines *)
    line*, title*: LONGINT       (* the dashed lines and activity line, the
                                    title *)
  END;

  (* A Gantt chart's colours, as 0RRGGBBH, or -1 for none *)
  GanttTheme* = RECORD
    section*: ARRAY 4 OF LONGINT;  (* the rows', section0 .. section3:
                                    sectionBkgColor, altSectionBkgColor,
                                    sectionBkgColor2, altSectionBkgColor *)
    sectionAlpha*: REAL;         (* sectionBkgColor's alpha *)
    exclude*, grid*, today*, vert*,
    taskFill*, taskLine*, activeFill*, activeLine*, doneFill*, doneLine*,
    critFill*, critLine*,
    taskText*, outsideText*, darkText*, linkText*, title*, text*: LONGINT
  END;

  (* A pie chart's colours, as 0RRGGBBH, or -1 for none, and its
     lengths, in points *)
  PieTheme* = RECORD
    pie*: ARRAY 12 OF LONGINT;   (* the slices', pie1 .. pie12 *)
    stroke*, outerStroke*, title*, section*, legend*: LONGINT;
    strokeWidth*, outerWidth*: REAL;
    opacity*: REAL               (* the slices', from 0 to 1 *)
  END;

  QuadrantTheme* = RECORD
    fill*, text*: ARRAY 5 OF LONGINT;  (* quadrants 1 .. 4' *)
    pointFill*, pointStroke*: LONGINT; (* the points' defaults; -1 for none *)
    pointText*, xAxis*, yAxis*, title*, internal*, external*: LONGINT;
    textFill*: LONGINT                 (* textColor: a point whose colour is invalid *)
  END;

  (* An XY chart's colours, as 0RRGGBBH *)
  XyTheme* = RECORD
    background*, title*, dataLabel*, legend*: LONGINT;
    axisTitle*, axisLabel*, axisTick*, axisLine*: ARRAY 2 OF LONGINT;  (* x, y *)
    palette*: ARRAY 32 OF LONGINT;     (* the plots', plotColorPalette *)
    nPalette*: INTEGER
  END;

  (* A radar chart's colours, as 0RRGGBBH, or -1 for none, and its
     lengths, in Mermaid's pixels *)
  RadarTheme* = RECORD
    scale*: ARRAY 12 OF LONGINT;       (* the curves', cScale0 .. cScale11 *)
    axis*, graticule*, text*: LONGINT;
    axisWidth*, curveWidth*, graticuleWidth*: REAL;
    axisLabelSize*, legendSize*: REAL;
    curveOpacity*, graticuleOpacity*: REAL  (* from 0 to 1 *)
  END;

  (* A packet diagram's colours, as 0RRGGBBH, or -1 for none, and its
     sizes, in Mermaid's pixels *)
  PacketTheme* = RECORD
    startByte*, endByte*, label*, title*: LONGINT;  (* the texts' *)
    blockLine*, blockFill*: LONGINT;
    byteSize*, labelSize*, titleSize*, blockWidth*: REAL
  END;

  (* A kanban board's colours, as 0RRGGBBH, or -1 for none *)
  KanbanTheme* = RECORD
    fill*, label*: ARRAY 12 OF LONGINT;  (* section k's, from 1: cScale(k+1)
                                    lightened by 10, its fill and outline,
                                    and cScaleLabel(k+1), its text *)
    itemFill*, itemLine*, text*: LONGINT  (* the items': background,
                                    nodeBorder and textColor *)
  END;

  (* An architecture diagram's colours, as 0RRGGBBH *)
  ArchTheme* = RECORD
    edge*, arrow*, groupLine*, text*: LONGINT  (* archEdgeColor,
                                    archEdgeArrowColor, archGroupBorderColor
                                    and the text's *)
  END;

  (* A git graph's colours, as 0RRGGBBH, or -1 for none, and its
     sizes, in Mermaid's pixels *)
  GitTheme* = RECORD
    git*, inv*, label*: ARRAY 8 OF LONGINT;  (* git0 .., gitInv0 .., gitBranchLabel0 .. *)
    primary*, text*, line*: LONGINT;         (* primaryColor, textColor, the branches' lines *)
    tagText*, tagFill*, tagLine*: LONGINT;
    commitText*, commitFill*: LONGINT;       (* commitFill blended over white at 0.5 *)
    commitSize*, tagSize*: REAL
  END;

  Style* = RECORD
    fill*, line*, text*: INTEGER;  (* indexes into the colours, or NoColour *)
    inner*: INTEGER;               (* a composite state's body's fill, below
                                      its title, or NoColour *)
    width*, dash*: REAL            (* points; dash 0 for a solid line *)
  END;

VAR
  colour: ARRAY MaxColours OF LONGINT;
  nColours-: INTEGER;   (* the colours in the table *)
  px: REAL;             (* a Mermaid pixel, in points *)
  (* the theme's colours, as 0RRGGBBH, or None *)
  nodeFill, nodeLine, nodeText, textColour, titleColour, edgeLine,
  labelBack, clusterFill, clusterLine,
  noteFill, noteLine, noteText, compositeBack, altBack, rowOdd, rowEven: LONGINT;
  themed: F.Graph;      (* the graph whose themeVariables are read *)


(* The colour of index c, as 0RRGGBBH *)
PROCEDURE Rgb*(c: INTEGER): LONGINT;
BEGIN
  RETURN colour[c]
END Rgb;

(* The index of colour rgb, added if it is new *)
PROCEDURE Colour*(rgb: LONGINT): INTEGER;
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < nColours) & (colour[i] # rgb) DO INC(i) END;
  IF i = nColours THEN
    IF nColours = MaxColours THEN RETURN 0 END;  (* too many: the first *)
    colour[i] := rgb; INC(nColours)
  END;
  RETURN i
END Colour;

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

PROCEDURE HexDigit(ch: CHAR; VAR d: INTEGER): BOOLEAN;
BEGIN
  ch := Lower(ch);
  IF (ch >= "0") & (ch <= "9") THEN d := ORD(ch) - ORD("0")
  ELSIF (ch >= "a") & (ch <= "f") THEN d := ORD(ch) - ORD("a") + 10
  ELSE RETURN FALSE
  END;
  RETURN TRUE
END HexDigit;

(* The value v, without blanks round it or "!important", lower case,
   in w *)
PROCEDURE Clean(v: Lx.Str; VAR w: ARRAY OF CHAR);
  VAR i, j, k: LONGINT;
BEGIN
  i := 0; j := 0;
  WHILE (i < LEN(v^)) & (v[i] # 0X) & Lx.IsBlank(v[i]) DO INC(i) END;
  WHILE (i < LEN(v^)) & (v[i] # 0X) & (v[i] # "!") & (j < LEN(w) - 1) DO
    w[j] := Lower(v[i]); INC(i); INC(j)
  END;
  k := j;
  WHILE (k > 0) & Lx.IsBlank(w[k - 1]) DO DEC(k) END;
  w[k] := 0X
END Clean;

(* A decimal number at s[i], i moved past it *)
PROCEDURE Number(VAR s: ARRAY OF CHAR; VAR i: INTEGER; VAR x: REAL): BOOLEAN;
  VAR frac: REAL; digits, neg: BOOLEAN;
BEGIN
  x := 0; digits := FALSE; neg := FALSE;
  WHILE Lx.IsBlank(s[i]) DO INC(i) END;
  IF s[i] = "-" THEN neg := TRUE; INC(i) END;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO
    x := x * 10 + (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE
  END;
  IF s[i] = "." THEN
    INC(i); frac := 1;
    WHILE (s[i] >= "0") & (s[i] <= "9") DO
      frac := frac / 10; x := x + frac * (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE
    END
  END;
  IF neg THEN x := -x END;
  RETURN digits
END Number;

(* The colour CSS writes as s: "#rgb", "#rrggbb" (with an alpha digit
   or two, ignored), "rgb(r, g, b)", "rgba(r, g, b, a)" or a name.
   none is TRUE for "none" and "transparent". FALSE if s is none of
   these. *)
PROCEDURE ParseColour*(VAR s: ARRAY OF CHAR; VAR rgb: LONGINT; VAR none: BOOLEAN): BOOLEAN;
  VAR i, n, d, k: INTEGER; x: REAL; c: ARRAY 3 OF LONGINT;

  PROCEDURE Is(name: ARRAY OF CHAR; value: LONGINT): BOOLEAN;
  BEGIN
    IF s = name THEN rgb := value; RETURN TRUE END;
    RETURN FALSE
  END Is;

BEGIN
  none := FALSE; rgb := 0;
  IF s[0] = "#" THEN
    n := 1;
    WHILE HexDigit(s[n], d) DO INC(n) END;
    IF s[n] # 0X THEN RETURN FALSE END;
    DEC(n);
    IF (n = 3) OR (n = 4) THEN
      FOR k := 1 TO 3 DO
        IF HexDigit(s[k], d) THEN END;
        rgb := rgb * 256 + d * 17
      END
    ELSIF (n = 6) OR (n = 8) THEN
      FOR k := 1 TO 6 DO
        IF HexDigit(s[k], d) THEN END;
        rgb := rgb * 16 + d
      END
    ELSE RETURN FALSE
    END;
    RETURN TRUE
  ELSIF (s[0] = "r") & (s[1] = "g") & (s[2] = "b") THEN
    i := 3; IF s[i] = "a" THEN INC(i) END;
    IF s[i] # "(" THEN RETURN FALSE END;
    INC(i);
    FOR k := 0 TO 2 DO
      IF ~Number(s, i, x) THEN RETURN FALSE END;
      IF s[i] = "%" THEN x := x * 255 / 100; INC(i) END;
      IF x < 0 THEN x := 0 ELSIF x > 255 THEN x := 255 END;
      c[k] := ENTIER(x + 0.5);
      WHILE Lx.IsBlank(s[i]) OR (s[i] = ",") DO INC(i) END
    END;
    rgb := (c[0] * 256 + c[1]) * 256 + c[2];
    RETURN TRUE
  ELSIF (s = "none") OR (s = "transparent") THEN none := TRUE; RETURN TRUE
  END;
  RETURN Is("black", 0) OR Is("white", 0FFFFFFH) OR Is("red", 0FF0000H)
    OR Is("green", 08000H) OR Is("blue", 0FFH) OR Is("yellow", 0FFFF00H)
    OR Is("orange", 0FFA500H) OR Is("purple", 0800080H) OR Is("gray", 0808080H)
    OR Is("grey", 0808080H) OR Is("silver", 0C0C0C0H) OR Is("maroon", 0800000H)
    OR Is("olive", 0808000H) OR Is("lime", 0FF00H) OR Is("aqua", 0FFFFH)
    OR Is("cyan", 0FFFFH) OR Is("teal", 08080H) OR Is("navy", 080H)
    OR Is("fuchsia", 0FF00FFH) OR Is("magenta", 0FF00FFH) OR Is("pink", 0FFC0CBH)
    OR Is("brown", 0A52A2AH) OR Is("gold", 0FFD700H) OR Is("lightgray", 0D3D3D3H)
    OR Is("lightgrey", 0D3D3D3H) OR Is("darkgray", 0A9A9A9H) OR Is("darkgrey", 0A9A9A9H)
    OR Is("lightblue", 0ADD8E6H) OR Is("lightgreen", 090EE90H) OR Is("darkblue", 08BH)
    OR Is("darkgreen", 06400H) OR Is("darkred", 08B0000H) OR Is("violet", 0EE82EEH)
END ParseColour;

(* A length, "4px", "4" (pixels) or "3pt", in points *)
PROCEDURE ParseLength*(VAR s: ARRAY OF CHAR; VAR x: REAL): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  i := 0;
  IF ~Number(s, i, x) OR (x < 0) THEN RETURN FALSE END;
  IF (s[i] = "p") & (s[i + 1] = "t") THEN INC(i, 2)
  ELSE
    IF (s[i] = "p") & (s[i + 1] = "x") THEN INC(i, 2) END;
    x := x * px
  END;
  RETURN s[i] = 0X
END ParseLength;

(* Changes st by the properties p *)
PROCEDURE Apply*(VAR st: Style; p: F.Prop);
  VAR v: ARRAY 128 OF CHAR; rgb: LONGINT; none: BOOLEAN; i: INTEGER; x: REAL;

  PROCEDURE SetColour(VAR c: INTEGER);
  BEGIN
    IF ParseColour(v, rgb, none) THEN
      IF none THEN c := NoColour ELSE c := Colour(rgb) END
    ELSE PmIO.Message3("ignoring the colour ", v, ", which pomermaid does not know")
    END
  END SetColour;

BEGIN
  WHILE p # NIL DO
    Clean(p.value, v);
    IF Lx.Is(p.name, "fill") THEN SetColour(st.fill)
    ELSIF Lx.Is(p.name, "stroke") THEN SetColour(st.line)
    ELSIF Lx.Is(p.name, "color") THEN SetColour(st.text)
    ELSIF Lx.Is(p.name, "stroke-width") THEN
      IF ParseLength(v, x) THEN st.width := x END
    ELSIF Lx.Is(p.name, "stroke-dasharray") THEN
      i := 0;
      IF Number(v, i, x) & (x >= 0) THEN st.dash := x * px
      ELSIF v = "none" THEN st.dash := 0
      END
    END;
    p := p.next
  END
END Apply;

(* The colour of index rgb, or NoColour for None *)
PROCEDURE ThemeColour(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb = None THEN RETURN NoColour ELSE RETURN Colour(rgb) END
END ThemeColour;

(* The index of the colour behind edges' labels, or NoColour *)
PROCEDURE LabelBackground*(): INTEGER;
BEGIN
  RETURN ThemeColour(labelBack)
END LabelBackground;

(* The colour behind edges' labels, as 0RRGGBBH, or -1 for none *)
PROCEDURE LabelBackgroundRgb*(): LONGINT;
BEGIN
  RETURN labelBack
END LabelBackgroundRgb;

(* TRUE if the colour behind edges' labels is the default theme's *)
PROCEDURE DefaultLabelBackground*(): BOOLEAN;
BEGIN
  RETURN labelBack = LabelBack
END DefaultLabelBackground;

(* The theme's text colour, textColor, 0RRGGBBH, as Reset set it *)
PROCEDURE TextRgb*(): LONGINT;
BEGIN
  RETURN textColour
END TextRgb;

(* The index of the diagram's title's colour, or NoColour *)
PROCEDURE TitleColour*(): INTEGER;
BEGIN
  RETURN ThemeColour(textColour)
END TitleColour;

(* c, the themeVariable name's colour, if the graph themed sets it *)
PROCEDURE Var(name: ARRAY OF CHAR; VAR c: LONGINT): BOOLEAN;
  VAR q: Y.Pair; key: ARRAY 64 OF CHAR; v: ARRAY 128 OF CHAR;
    rgb: LONGINT; none: BOOLEAN; i, j: INTEGER;
BEGIN
  IF (themed = NIL) OR (themed.config = NIL) THEN RETURN FALSE END;
  key := "config.themeVariables."; i := 0;
  WHILE key[i] # 0X DO INC(i) END;
  j := 0;
  WHILE name[j] # 0X DO key[i] := name[j]; INC(i); INC(j) END;
  key[i] := 0X;
  q := Y.Find(themed.config, key);
  IF q = NIL THEN RETURN FALSE END;
  Clean(q.value, v);
  IF ParseColour(v, rgb, none) THEN
    IF none THEN c := None ELSE c := rgb END;
    RETURN TRUE
  END;
  PmIO.Message3("ignoring the colour ", v, ", which pomermaid does not know");
  RETURN FALSE
END Var;

(* The text of the themeVariable name, cleaned, in v, if the graph
   themed sets it *)
PROCEDURE VarText(name: ARRAY OF CHAR; VAR v: ARRAY OF CHAR): BOOLEAN;
  VAR q: Y.Pair; key: ARRAY 64 OF CHAR; i, j: INTEGER;
BEGIN
  IF (themed = NIL) OR (themed.config = NIL) THEN RETURN FALSE END;
  key := "config.themeVariables."; i := 0;
  WHILE key[i] # 0X DO INC(i) END;
  j := 0;
  WHILE name[j] # 0X DO key[i] := name[j]; INC(i); INC(j) END;
  key[i] := 0X;
  q := Y.Find(themed.config, key);
  IF q = NIL THEN RETURN FALSE END;
  Clean(q.value, v);
  RETURN TRUE
END VarText;

(* x, the themeVariable name's length, in points, if the graph themed
   sets it to one, in pixels or points *)
PROCEDURE VarLength(name: ARRAY OF CHAR; VAR x: REAL): BOOLEAN;
  VAR v: ARRAY 128 OF CHAR; y: REAL;
BEGIN
  IF ~VarText(name, v) THEN RETURN FALSE END;
  IF ParseLength(v, y) THEN x := y; RETURN TRUE END;
  PmIO.Message3("ignoring the length ", v, ", which pomermaid does not know");
  RETURN FALSE
END VarLength;

(* x, the themeVariable name's number, if the graph themed sets it to
   one *)
PROCEDURE VarNumber(name: ARRAY OF CHAR; VAR x: REAL): BOOLEAN;
  VAR v: ARRAY 128 OF CHAR; i: INTEGER; y: REAL;
BEGIN
  IF ~VarText(name, v) THEN RETURN FALSE END;
  i := 0;
  IF Number(v, i, y) & (v[i] = 0X) THEN x := y; RETURN TRUE END;
  PmIO.Message3("ignoring the number ", v, ", which pomermaid does not know");
  RETURN FALSE
END VarNumber;

(* The theme's colours: Mermaid's default theme's, changed by g's
   themeVariables, a variable the flowchart uses (mainBkg, nodeBorder,
   ...) after those it is made from (border1, ...), as Mermaid does *)
PROCEDURE Theme(g: F.Graph);
  VAR set: BOOLEAN;
BEGIN
  themed := g;
  nodeFill := NodeFill; nodeLine := NodeLine; textColour := TextColour;
  edgeLine := EdgeLine; labelBack := LabelBack;
  clusterFill := ClusterFill; clusterLine := ClusterLine;
  set := Var("mainBkg", nodeFill);
  IF ~Var("nodeBorder", nodeLine) THEN set := Var("border1", nodeLine) END;
  set := Var("textColor", textColour);
  nodeText := textColour; titleColour := textColour;
  set := Var("nodeTextColor", nodeText);
  set := Var("titleColor", titleColour);
  set := Var("lineColor", edgeLine);
  IF ~Var("edgeLabelBackground", labelBack) THEN set := Var("labelBackground", labelBack) END;
  IF ~Var("clusterBkg", clusterFill) THEN set := Var("secondBkg", clusterFill) END;
  IF ~Var("clusterBorder", clusterLine) THEN set := Var("border2", clusterLine) END;
  noteFill := NoteFill; noteLine := NoteLine; noteText := textColour;
  compositeBack := CompositeBack; altBack := AltBack;
  set := Var("noteBkgColor", noteFill);
  set := Var("noteBorderColor", noteLine);
  set := Var("noteTextColor", noteText);
  IF ~Var("compositeBackground", compositeBack) THEN set := Var("background", compositeBack) END;
  set := Var("altBackground", altBack);
  rowOdd := RowOdd; rowEven := RowEven;
  set := Var("rowOdd", rowOdd);
  set := Var("rowEven", rowEven)
END Theme;

(* Empties the colour table, and sets the theme's colours from g's
   themeVariables; lengths in pixels are taken as pixel points each
   from now on *)
PROCEDURE Reset*(g: F.Graph; pixel: REAL);
BEGIN
  nColours := 0; px := pixel;
  Theme(g)
END Reset;

(* t, a sequence diagram's colours: the default theme's, as the
   theme's colours Reset set, changed by the themeVariables of the
   sequence diagram (actorBkg, actorBorder, ...) *)
PROCEDURE SeqColours*(VAR t: SeqTheme);
  VAR set: BOOLEAN;
BEGIN
  t.actorFill := nodeFill; t.actorLine := nodeLine; t.actorText := 0;
  set := Var("actorBkg", t.actorFill);
  set := Var("actorBorder", t.actorLine);
  set := Var("actorTextColor", t.actorText);
  t.lifeline := t.actorLine; set := Var("actorLineColor", t.lifeline);
  t.signal := textColour; set := Var("signalColor", t.signal);
  t.signalText := textColour; set := Var("signalTextColor", t.signalText);
  t.labelFill := t.actorFill; set := Var("labelBoxBkgColor", t.labelFill);
  t.labelLine := t.actorLine; set := Var("labelBoxBorderColor", t.labelLine);
  t.labelText := 0; set := Var("labelTextColor", t.labelText);
  t.loopText := 0; set := Var("loopTextColor", t.loopText);
  t.noteFill := noteFill; t.noteLine := noteLine; t.noteText := 0;
  set := Var("noteTextColor", t.noteText);
  t.barFill := 0F4F4F4H; set := Var("activationBkgColor", t.barFill);
  t.barLine := 0666666H; set := Var("activationBorderColor", t.barLine);
  t.number := t.signal;
  t.numberText := 0FFFFFFH; set := Var("sequenceNumberColor", t.numberText);
  t.title := titleColour
END SeqColours;

(* t, a user journey's colours: the default theme's and Mermaid's
   journey's (sectionFills, actorColours and its styles), changed by
   the themeVariables fillType0 to fillType7, actor0 to actor5,
   faceColor, textColor and titleColor *)
PROCEDURE JourneyColours*(VAR t: JourneyTheme);
  VAR set: BOOLEAN; k: INTEGER; name: ARRAY 16 OF CHAR;
BEGIN
  t.fill[0] := 0ECECFFH; t.fill[1] := 0FFFFDEH; t.fill[2] := 0FFECFEH;
  t.fill[3] := 0DEFFE0H; t.fill[4] := 0ECFFFEH; t.fill[5] := 0FFDEE0H;
  t.fill[6] := 0FFEFECH; t.fill[7] := 0DEFBFFH;
  t.actor[0] := 08FBC8FH; t.actor[1] := 07CFC00H; t.actor[2] := 000FFFFH;
  t.actor[3] := 020B2AAH; t.actor[4] := 0B0E0E6H; t.actor[5] := 0FFFFE0H;
  name := "fillType0";
  FOR k := 0 TO 7 DO name[8] := CHR(ORD("0") + k); set := Var(name, t.fill[k]) END;
  name := "actor0";
  FOR k := 0 TO 5 DO name[5] := CHR(ORD("0") + k); set := Var(name, t.actor[k]) END;
  t.face := 0FFF8DCH; set := Var("faceColor", t.face);
  t.faceLine := 0999999H; t.mouth := 0666666H;
  t.line := textColour; t.text := textColour;
  t.boxLine := 0666666H; t.boxText := 0333333H;
  t.title := titleColour
END JourneyColours;

(* t, a timeline's colours: the default theme's cScale0 to cScale11,
   cScaleLabel0 to cScaleLabel11 and cScaleInv0 to cScaleInv11, each
   changed by its themeVariable *)
PROCEDURE TimelineColours*(VAR t: TimelineTheme);
  VAR set: BOOLEAN; k: INTEGER; name: ARRAY 20 OF CHAR;

  PROCEDURE Name(base: ARRAY OF CHAR; k: INTEGER);
    VAR i: INTEGER;
  BEGIN
    COPY(base, name); i := 0; WHILE name[i] # 0X DO INC(i) END;
    IF k >= 10 THEN name[i] := "1"; INC(i) END;
    name[i] := CHR(ORD("0") + k MOD 10); name[i + 1] := 0X
  END Name;

BEGIN
  t.scale[0] := 08686FFH; t.scale[1] := 0FFFF78H; t.scale[2] := 0D7FF86H;
  t.scale[3] := 0C286FFH; t.scale[4] := 0FF86FFH; t.scale[5] := 0FF86C3H;
  t.scale[6] := 0FF8686H; t.scale[7] := 0FFC286H; t.scale[8] := 0C3FF86H;
  t.scale[9] := 086FFC3H; t.scale[10] := 086FFFFH; t.scale[11] := 086C2FFH;
  t.inv[0] := 0FFFFB9H; t.inv[1] := 0ABABFFH; t.inv[2] := 0D0B9FFH;
  t.inv[3] := 0DCFFB9H; t.inv[4] := 0B9FFB9H; t.inv[5] := 0B9FFDCH;
  t.inv[6] := 0B9FFFFH; t.inv[7] := 0B9DCFFH; t.inv[8] := 0DCB9FFH;
  t.inv[9] := 0FFB9DCH; t.inv[10] := 0FFB9B9H; t.inv[11] := 0FFDCB9H;
  FOR k := 0 TO 11 DO t.label[k] := 0 END;
  t.label[0] := 0FFFFFFH; t.label[3] := 0FFFFFFH;
  FOR k := 0 TO 11 DO
    Name("cScale", k); set := Var(name, t.scale[k]);
    Name("cScaleLabel", k); set := Var(name, t.label[k]);
    Name("cScaleInv", k); set := Var(name, t.inv[k])
  END;
  t.line := 0; t.title := titleColour
END TimelineColours;

(* peer, the colour scale's peers, cScalePeer0..11, a treemap's section
   outlines: those Mermaid's default theme makes from its cScale
   colours, each changed by its themeVariable *)
PROCEDURE PeerColours*(VAR peer: ARRAY OF LONGINT);
  VAR set: BOOLEAN; k, i: INTEGER; name: ARRAY 20 OF CHAR;
BEGIN
  peer[0] := 03939FFH; peer[1] := 0F7F700H; peer[2] := 0B5FF20H;
  peer[3] := 09C39FFH; peer[4] := 0FF39FFH; peer[5] := 0FF399CH;
  peer[6] := 0FF3939H; peer[7] := 0FF9C39H; peer[8] := 09CFF39H;
  peer[9] := 039FF9CH; peer[10] := 039FFFFH; peer[11] := 0399CFFH;
  FOR k := 0 TO 11 DO
    name := "cScalePeer"; i := 10;
    IF k >= 10 THEN name[i] := "1"; INC(i) END;
    name[i] := CHR(ORD("0") + k MOD 10); name[i + 1] := 0X;
    set := Var(name, peer[k])
  END
END PeerColours;

(* t, a Gantt chart's colours: the default theme's, each changed by its
   themeVariable, sectionBkgColor, altSectionBkgColor, sectionBkgColor2,
   excludeBkgColor, gridColor, todayLineColor, vertLineColor,
   taskBkgColor, taskBorderColor, activeTaskBkgColor,
   activeTaskBorderColor, doneTaskBkgColor, doneTaskBorderColor,
   critBkgColor, critBorderColor, taskTextColor (else
   taskTextLightColor), taskTextOutsideColor (else taskTextDarkColor),
   taskTextDarkColor and taskTextClickableColor. sectionBkgColor's
   alpha is the default's, 0.49, unless it is set, when it is 1. *)
PROCEDURE GanttColours*(VAR t: GanttTheme);
  VAR set: BOOLEAN;
BEGIN
  t.section[0] := 06666FFH; t.sectionAlpha := 0.49;
  IF Var("sectionBkgColor", t.section[0]) THEN t.sectionAlpha := 1 END;
  t.section[1] := 0FFFFFFH; set := Var("altSectionBkgColor", t.section[1]);
  t.section[2] := 0FFF400H; set := Var("sectionBkgColor2", t.section[2]);
  t.section[3] := t.section[1];
  t.exclude := 0EEEEEEH; set := Var("excludeBkgColor", t.exclude);
  t.grid := 0D3D3D3H; set := Var("gridColor", t.grid);
  t.today := 0FF0000H; set := Var("todayLineColor", t.today);
  t.vert := 080H; set := Var("vertLineColor", t.vert);
  t.taskFill := 08A90DDH; set := Var("taskBkgColor", t.taskFill);
  t.taskLine := 0534FBCH; set := Var("taskBorderColor", t.taskLine);
  t.activeFill := 0BFC7FFH; set := Var("activeTaskBkgColor", t.activeFill);
  t.activeLine := 0534FBCH; set := Var("activeTaskBorderColor", t.activeLine);
  t.doneFill := 0D3D3D3H; set := Var("doneTaskBkgColor", t.doneFill);
  t.doneLine := 0808080H; set := Var("doneTaskBorderColor", t.doneLine);
  t.critFill := 0FF0000H; set := Var("critBkgColor", t.critFill);
  t.critLine := 0FF8888H; set := Var("critBorderColor", t.critLine);
  t.darkText := 0; set := Var("taskTextDarkColor", t.darkText);
  IF ~Var("taskTextColor", t.taskText) THEN
    t.taskText := 0FFFFFFH; set := Var("taskTextLightColor", t.taskText)
  END;
  IF ~Var("taskTextOutsideColor", t.outsideText) THEN t.outsideText := t.darkText END;
  t.linkText := 03163H; set := Var("taskTextClickableColor", t.linkText);
  t.title := titleColour; t.text := textColour
END GanttColours;

(* t, a pie chart's colours and lengths: the default theme's, each
   changed by its themeVariable: pie1 to pie12, pieStrokeColor,
   pieOuterStrokeColor, pieTitleTextColor, pieSectionTextColor (else
   textColor), pieLegendTextColor, pieStrokeWidth, pieOuterStrokeWidth
   and pieOpacity *)
PROCEDURE PieColours*(VAR t: PieTheme);
  VAR set: BOOLEAN; k: INTEGER; name: ARRAY 8 OF CHAR;
BEGIN
  t.pie[0] := 0ECECFFH; t.pie[1] := 0FFFFDEH; t.pie[2] := 0B5FF20H;
  t.pie[3] := 0B9B9FFH; t.pie[4] := 0FFFF45H; t.pie[5] := 0D7FF86H;
  t.pie[6] := 0FF86FFH; t.pie[7] := 020FFFFH; t.pie[8] := 0FF2020H;
  t.pie[9] := 0FF20FFH; t.pie[10] := 020FF90H; t.pie[11] := 0FF5353H;
  name := "pie";
  FOR k := 0 TO 11 DO
    IF k < 9 THEN name[3] := CHR(ORD("1") + k); name[4] := 0X
    ELSE name[3] := "1"; name[4] := CHR(ORD("0") + k - 9); name[5] := 0X
    END;
    set := Var(name, t.pie[k])
  END;
  t.stroke := 0; set := Var("pieStrokeColor", t.stroke);
  t.outerStroke := 0; set := Var("pieOuterStrokeColor", t.outerStroke);
  t.title := 0; set := Var("pieTitleTextColor", t.title);
  t.section := textColour; set := Var("pieSectionTextColor", t.section);
  t.legend := 0; set := Var("pieLegendTextColor", t.legend);
  t.strokeWidth := 2 * px; set := VarLength("pieStrokeWidth", t.strokeWidth);
  t.outerWidth := 2 * px; set := VarLength("pieOuterStrokeWidth", t.outerWidth);
  t.opacity := 0.7;
  IF VarNumber("pieOpacity", t.opacity) THEN
    IF t.opacity < 0 THEN t.opacity := 0 ELSIF t.opacity > 1 THEN t.opacity := 1 END
  END
END PieColours;

(* t, a quadrant chart's colours: the default theme's, changed by
   themeVariables. The points' default fill, quadrantPointFill, is an
   invalid colour in Mermaid's default theme, so the points are drawn
   in the text's colour, inherited, and not outlined; a
   quadrantPointFill given is their fill and their outline. *)
PROCEDURE QuadrantColours*(VAR t: QuadrantTheme);
  VAR set: BOOLEAN; k: INTEGER; name: ARRAY 24 OF CHAR;
BEGIN
  t.fill[1] := 0ECECFFH; t.fill[2] := 0F1F1FFH; t.fill[3] := 0F6F6FFH; t.fill[4] := 0FBFBFFH;
  t.text[1] := 0131300H; t.text[2] := 00E0E00H; t.text[3] := 0090900H; t.text[4] := 0040400H;
  FOR k := 1 TO 4 DO
    name := "quadrant1Fill"; name[8] := CHR(ORD("0") + k); set := Var(name, t.fill[k]);
    name := "quadrant1TextFill"; name[8] := CHR(ORD("0") + k); set := Var(name, t.text[k])
  END;
  t.textFill := textColour; t.pointFill := textColour; t.pointStroke := -1;
  IF Var("quadrantPointFill", t.pointFill) THEN t.pointStroke := t.pointFill END;
  t.pointText := 0131300H; set := Var("quadrantPointTextFill", t.pointText);
  t.xAxis := 0131300H; set := Var("quadrantXAxisTextFill", t.xAxis);
  t.yAxis := 0131300H; set := Var("quadrantYAxisTextFill", t.yAxis);
  t.title := 0131300H; set := Var("quadrantTitleFill", t.title);
  t.internal := 0C7C7F1H; set := Var("quadrantInternalBorderStrokeFill", t.internal);
  t.external := 0C7C7F1H; set := Var("quadrantExternalBorderStrokeFill", t.external)
END QuadrantColours;

(* t, an XY chart's colours: the default theme's, changed by
   themeVariables: background and primaryTextColor, and those of
   xyChart, which override them. plotColorPalette is colours separated
   by commas; one pomermaid does not know is left out. *)
PROCEDURE XyColours*(VAR t: XyTheme);
  VAR set: BOOLEAN; text: LONGINT; k: INTEGER; i, j: LONGINT;
    v, w: ARRAY 512 OF CHAR; rgb: LONGINT; none: BOOLEAN;
BEGIN
  t.background := 0FFFFFFH; set := Var("background", t.background);
  set := Var("xyChart.backgroundColor", t.background);
  text := 0131300H; set := Var("primaryTextColor", text);
  t.title := text; set := Var("xyChart.titleColor", t.title);
  t.dataLabel := text; set := Var("xyChart.dataLabelColor", t.dataLabel);
  t.legend := text; set := Var("xyChart.legendTextColor", t.legend);
  FOR k := 0 TO 1 DO
    t.axisTitle[k] := text; t.axisLabel[k] := text; t.axisTick[k] := text; t.axisLine[k] := text
  END;
  set := Var("xyChart.xAxisTitleColor", t.axisTitle[0]);
  set := Var("xyChart.xAxisLabelColor", t.axisLabel[0]);
  set := Var("xyChart.xAxisTickColor", t.axisTick[0]);
  set := Var("xyChart.xAxisLineColor", t.axisLine[0]);
  set := Var("xyChart.yAxisTitleColor", t.axisTitle[1]);
  set := Var("xyChart.yAxisLabelColor", t.axisLabel[1]);
  set := Var("xyChart.yAxisTickColor", t.axisTick[1]);
  set := Var("xyChart.yAxisLineColor", t.axisLine[1]);
  IF ~VarText("xyChart.plotColorPalette", v) THEN
    v := "#ececff,#8493a6,#ffc3a0,#dcdde1,#b8e994,#d1a36f,#c3cde6,#ffb6c1,#496078,#f8f3e3"
  END;
  t.nPalette := 0; i := 0;
  LOOP
    WHILE v[i] = " " DO INC(i) END;
    j := 0;
    WHILE (v[i] # 0X) & (v[i] # ",") DO
      IF j < LEN(w) - 1 THEN w[j] := v[i]; INC(j) END; INC(i)
    END;
    WHILE (j > 0) & (w[j - 1] = " ") DO DEC(j) END;
    w[j] := 0X;
    IF (j > 0) & (t.nPalette < LEN(t.palette)) THEN
      IF ParseColour(w, rgb, none) & ~none THEN t.palette[t.nPalette] := rgb; INC(t.nPalette)
      ELSE PmIO.Message3("ignoring the colour ", w, ", which pomermaid does not know")
      END
    END;
    IF v[i] = 0X THEN EXIT END;
    INC(i)
  END;
  IF t.nPalette = 0 THEN t.palette[0] := 0ECECFFH; t.nPalette := 1 END
END XyColours;

(* t, a radar chart's colours and lengths: the default theme's,
   changed by themeVariables: cScale0 to cScale11, textColor, and
   radar's axisColor (else lineColor), axisStrokeWidth,
   axisLabelFontSize, curveOpacity, curveStrokeWidth, graticuleColor,
   graticuleStrokeWidth, graticuleOpacity and legendFontSize; a number
   given as 0 is 0, as Mermaid's styles merge them over the theme's;
   the opacities are kept to 0 to 1 *)
PROCEDURE RadarColours*(VAR t: RadarTheme);
  VAR tl: TimelineTheme; set: BOOLEAN; k: INTEGER;

  PROCEDURE Num(name: ARRAY OF CHAR; VAR x: REAL; default: REAL);
    VAR y: REAL;
  BEGIN
    x := default;
    IF VarNumber(name, y) THEN x := y END
  END Num;

BEGIN
  TimelineColours(tl);
  FOR k := 0 TO 11 DO t.scale[k] := tl.scale[k] END;
  t.axis := edgeLine; set := Var("radar.axisColor", t.axis);
  t.graticule := 0DEDEDEH; set := Var("radar.graticuleColor", t.graticule);
  t.text := textColour;
  Num("radar.axisStrokeWidth", t.axisWidth, 2);
  Num("radar.axisLabelFontSize", t.axisLabelSize, 12);
  Num("radar.curveOpacity", t.curveOpacity, 0.5);
  Num("radar.curveStrokeWidth", t.curveWidth, 2);
  Num("radar.graticuleStrokeWidth", t.graticuleWidth, 1);
  Num("radar.graticuleOpacity", t.graticuleOpacity, 0.3);
  Num("radar.legendFontSize", t.legendSize, 12);
  IF t.curveOpacity < 0 THEN t.curveOpacity := 0 ELSIF t.curveOpacity > 1 THEN t.curveOpacity := 1 END;
  IF t.graticuleOpacity < 0 THEN t.graticuleOpacity := 0
  ELSIF t.graticuleOpacity > 1 THEN t.graticuleOpacity := 1
  END
END RadarColours;

(* x, the themeVariable name's length in pixels, "10px" or "10", if
   the graph themed sets it to one *)
PROCEDURE VarPixels(name: ARRAY OF CHAR; VAR x: REAL);
  VAR v: ARRAY 128 OF CHAR; i: INTEGER; y: REAL;
BEGIN
  IF VarText(name, v) THEN
    i := 0;
    IF Number(v, i, y) & (y >= 0)
      & ((v[i] = 0X) OR (v[i] = "p") & (v[i + 1] = "x") & (v[i + 2] = 0X))
    THEN x := y
    ELSE PmIO.Message3("ignoring the length ", v, ", which pomermaid does not know")
    END
  END
END VarPixels;

(* t, a packet diagram's colours and sizes: Mermaid's, for every
   theme, changed by themeVariables' packet: startByteColor,
   endByteColor, labelColor, titleColor, blockStrokeColor,
   blockFillColor, byteFontSize, labelFontSize, titleFontSize and
   blockStrokeWidth *)
PROCEDURE PacketColours*(VAR t: PacketTheme);
  VAR set: BOOLEAN;
BEGIN
  t.startByte := 0; t.endByte := 0; t.label := 0; t.title := 0;
  t.blockLine := 0; t.blockFill := 0EFEFEFH;
  set := Var("packet.startByteColor", t.startByte);
  set := Var("packet.endByteColor", t.endByte);
  set := Var("packet.labelColor", t.label);
  set := Var("packet.titleColor", t.title);
  set := Var("packet.blockStrokeColor", t.blockLine);
  set := Var("packet.blockFillColor", t.blockFill);
  t.byteSize := 10; t.labelSize := 12; t.titleSize := 14; t.blockWidth := 1;
  VarPixels("packet.byteFontSize", t.byteSize);
  VarPixels("packet.labelFontSize", t.labelSize);
  VarPixels("packet.titleFontSize", t.titleSize);
  VarPixels("packet.blockStrokeWidth", t.blockWidth)
END PacketColours;

(* rgb lightened as khroma's lighten does: its HSL lightness raised
   by amount percent, to at most 100, rounded *)
PROCEDURE Lighten*(rgb: LONGINT; amount: LONGREAL): LONGINT;
  VAR r, g, b, mx, mn, h, s, l, d, q, p: LONGREAL;

  PROCEDURE Hue(t: LONGREAL): LONGREAL;
  BEGIN
    IF t < 0 THEN t := t + 1 END;
    IF t > 1 THEN t := t - 1 END;
    IF t < 1 / 6.0D0 THEN RETURN p + (q - p) * 6 * t
    ELSIF t < 0.5D0 THEN RETURN q
    ELSIF t < 2 / 3.0D0 THEN RETURN p + (q - p) * (2 / 3.0D0 - t) * 6
    END;
    RETURN p
  END Hue;

  PROCEDURE Byte(x: LONGREAL): LONGINT;
  BEGIN
    x := ENTIER(x * 255 + 0.5D0);
    IF x < 0 THEN x := 0 ELSIF x > 255 THEN x := 255 END;
    RETURN ENTIER(x)
  END Byte;

BEGIN
  IF rgb = None THEN RETURN None END;
  r := (rgb DIV 10000H) / 255.0D0; g := (rgb DIV 100H MOD 100H) / 255.0D0;
  b := (rgb MOD 100H) / 255.0D0;
  mx := r; IF g > mx THEN mx := g END; IF b > mx THEN mx := b END;
  mn := r; IF g < mn THEN mn := g END; IF b < mn THEN mn := b END;
  l := (mx + mn) / 2; d := mx - mn; h := 0; s := 0;
  IF d > 0 THEN
    IF l > 0.5D0 THEN s := d / (2 - mx - mn) ELSE s := d / (mx + mn) END;
    IF mx = r THEN h := (g - b) / d; IF g < b THEN h := h + 6 END
    ELSIF mx = g THEN h := (b - r) / d + 2
    ELSE h := (r - g) / d + 4
    END;
    h := h / 6
  END;
  l := l + amount / 100;
  IF l > 1 THEN l := 1 ELSIF l < 0 THEN l := 0 END;
  IF s = 0 THEN r := l; g := l; b := l
  ELSE
    IF l < 0.5D0 THEN q := l * (1 + s) ELSE q := l + s - l * s END;
    p := 2 * l - q;
    r := Hue(h + 1 / 3.0D0); g := Hue(h); b := Hue(h - 1 / 3.0D0)
  END;
  RETURN Byte(r) * 10000H + Byte(g) * 100H + Byte(b)
END Lighten;

(* t, a kanban board's colours: the timeline's colour scale,
   TimelineColours', its cScale colours lightened by 10, as Mermaid's
   kanban styles make them, and background (white), nodeBorder and
   textColor, each changed by its themeVariable *)
PROCEDURE KanbanColours*(VAR t: KanbanTheme);
  VAR tl: TimelineTheme; set: BOOLEAN; k: INTEGER;
BEGIN
  TimelineColours(tl);
  FOR k := 0 TO 11 DO t.fill[k] := Lighten(tl.scale[k], 10); t.label[k] := tl.label[k] END;
  t.itemFill := 0FFFFFFH; set := Var("background", t.itemFill);
  t.itemLine := nodeLine; t.text := textColour
END KanbanColours;

(* t, an architecture diagram's colours: lineColor for the edges and
   their arrows, 09370DB for the groups' outlines and textColor, changed
   by archEdgeColor, archEdgeArrowColor and archGroupBorderColor *)
PROCEDURE ArchColours*(VAR t: ArchTheme);
  VAR set: BOOLEAN;
BEGIN
  t.edge := edgeLine; set := Var("archEdgeColor", t.edge);
  t.arrow := edgeLine; set := Var("archEdgeArrowColor", t.arrow);
  t.groupLine := 09370DBH; set := Var("archGroupBorderColor", t.groupLine);
  t.text := textColour
END ArchColours;

(* t, a git graph's colours and sizes: the default theme's, changed by
   themeVariables: git0 to git7, gitInv0 to gitInv7, gitBranchLabel0
   to gitBranchLabel7, primaryColor, textColor, commitLineColor (else
   lineColor), tagLabelColor, tagLabelBackground, tagLabelBorder,
   commitLabelColor, commitLabelBackground, commitLabelFontSize and
   tagLabelFontSize. The default theme computes git0 .. git7 twice,
   darkening them twice, and gitInv0 .. gitInv7 from the first; these
   are its results. *)
PROCEDURE GitColours*(VAR t: GitTheme);
  VAR set: BOOLEAN; k: INTEGER; name: ARRAY 20 OF CHAR; x: REAL; c: LONGINT;

  PROCEDURE Name(base: ARRAY OF CHAR; k: INTEGER);
    VAR i: INTEGER;
  BEGIN
    COPY(base, name); i := 0; WHILE name[i] # 0X DO INC(i) END;
    name[i] := CHR(ORD("0") + k); name[i + 1] := 0X
  END Name;

  PROCEDURE Blend(a: LONGINT): LONGINT;  (* a at 0.5 over white, rounded *)
  BEGIN
    RETURN ((a DIV 10000H + 256) DIV 2) * 10000H + ((a DIV 100H MOD 100H + 256) DIV 2) * 100H
      + (a MOD 100H + 256) DIV 2
  END Blend;

BEGIN
  t.git[0] := 00000ECH; t.git[1] := 0DEDE00H; t.git[2] := 09DEC00H; t.git[3] := 00076ECH;
  t.git[4] := 000ECECH; t.git[5] := 000EC76H; t.git[6] := 0EC00ECH; t.git[7] := 0EC0000H;
  t.inv[0] := 0121200H; t.inv[1] := 00000A1H; t.inv[2] := 0310092H; t.inv[3] := 0924900H;
  t.inv[4] := 0920000H; t.inv[5] := 0920049H; t.inv[6] := 0009200H; t.inv[7] := 0009292H;
  FOR k := 0 TO 7 DO t.label[k] := 0 END;
  t.label[0] := 0FFFFFFH; t.label[3] := 0FFFFFFH;
  FOR k := 0 TO 7 DO
    Name("git", k); set := Var(name, t.git[k]);
    Name("gitInv", k); set := Var(name, t.inv[k]);
    Name("gitBranchLabel", k); set := Var(name, t.label[k])
  END;
  t.primary := 0ECECFFH; set := Var("primaryColor", t.primary);
  t.text := textColour;
  t.line := edgeLine; set := Var("commitLineColor", t.line);
  t.tagText := 0131300H; set := Var("tagLabelColor", t.tagText);
  t.tagFill := 0ECECFFH; set := Var("tagLabelBackground", t.tagFill);
  t.tagLine := 0C7C7F1H; set := Var("tagLabelBorder", t.tagLine);
  t.commitText := 0000021H; set := Var("commitLabelColor", t.commitText);
  c := 0FFFFDEH; set := Var("commitLabelBackground", c);
  IF c = None THEN t.commitFill := None ELSE t.commitFill := Blend(c) END;
  t.commitSize := 10; t.tagSize := 10;
  IF VarLength("commitLabelFontSize", x) THEN t.commitSize := x / px END;
  IF VarLength("tagLabelFontSize", x) THEN t.tagSize := x / px END
END GitColours;

(* Applies the classDefs named name *)
PROCEDURE ApplyClass(g: F.Graph; VAR st: Style; name: ARRAY OF CHAR);
  VAR c: F.ClassDef;
BEGIN
  c := g.classDefs;
  WHILE c # NIL DO
    IF c.name^ = name THEN Apply(st, c.props) END;
    c := c.next
  END
END ApplyClass;

(* st, node n's style: Mermaid's default theme, then classDef default,
   n's classes and its style statements. In a state diagram, start and
   end markers and forks are in the line colour, and notes (Rect) in
   the notes' colours; in a class diagram, notes too, and an interface
   (a lollipop's) has no box *)
PROCEDURE NodeStyle*(g: F.Graph; n: F.Node; VAR st: Style);
  VAR c: F.Name; k: INTEGER;
BEGIN
  st.fill := ThemeColour(nodeFill); st.line := ThemeColour(nodeLine); st.text := ThemeColour(nodeText);
  st.width := px; st.dash := 0; st.inner := NoColour;
  IF g.kind = F.State THEN
    IF (n.shape = F.SmCircle) OR (n.shape = F.Fork) THEN
      st.fill := ThemeColour(edgeLine); st.line := st.fill
    ELSIF n.shape = F.FrCircle THEN
      st.line := ThemeColour(edgeLine); st.width := 2 * px
    ELSIF n.shape = F.Rect THEN
      st.fill := ThemeColour(noteFill); st.line := ThemeColour(noteLine); st.text := ThemeColour(noteText)
    END
  ELSIF g.kind = F.Class THEN
    IF n.shape = F.Rect THEN
      st.fill := ThemeColour(noteFill); st.line := ThemeColour(noteLine); st.text := ThemeColour(noteText)
    ELSIF n.shape = F.Interface THEN
      st.fill := NoColour; st.line := NoColour
    END
  END;
  ApplyClass(g, st, "default");
  c := n.classes;
  WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END;
  Apply(st, n.style);
  IF n.attrs # NIL THEN
    (* the colours of its rows, in the table before the drawing *)
    k := ThemeColour(rowOdd); k := ThemeColour(rowEven)
  END
END NodeStyle;

(* The styles of an entity box's rows, from node, the box's: the first,
   third ... rows, odd, in rowOdd, the others, even, in rowEven, or in
   the box's fill, if a class or a style statement changed it; each
   outlined as the box *)
PROCEDURE RowStyles*(VAR node, odd, even: Style);
BEGIN
  odd := node; odd.fill := ThemeColour(rowOdd);
  even := node;
  IF node.fill = ThemeColour(nodeFill) THEN even.fill := ThemeColour(rowEven) END
END RowStyles;

(* st, subgraph k's style: Mermaid's default theme's, then its class
   statements', as Mermaid's flowDb compiles them, then the classes and
   style statements of n, the node with the subgraph's id, if not NIL.
   A composite state's title band is filled as a state, its body
   (inner) white, or grey if it alternates; a region is grey and
   dashed *)
PROCEDURE ClusterStyle*(g: F.Graph; k: INTEGER; n: F.Node; VAR st: Style);
  VAR c: F.Name; cl: F.Cluster;
BEGIN
  st.fill := ThemeColour(clusterFill); st.line := ThemeColour(clusterLine); st.text := ThemeColour(titleColour);
  st.width := px; st.dash := 0; st.inner := NoColour;
  cl := g.clusters; WHILE (cl # NIL) & (cl.index # k) DO cl := cl.next END;
  IF (cl # NIL) & (cl.kind = F.Composite) THEN
    st.fill := ThemeColour(nodeFill); st.line := ThemeColour(nodeLine); st.text := ThemeColour(nodeText);
    IF cl.alt THEN st.inner := ThemeColour(altBack) ELSE st.inner := ThemeColour(compositeBack) END
  ELSIF (cl # NIL) & (cl.kind = F.Region) THEN
    st.fill := ThemeColour(altBack); st.line := ThemeColour(nodeLine); st.dash := 10 * px
  END;
  IF cl # NIL THEN
    c := cl.classes;
    WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END
  END;
  IF n # NIL THEN
    c := n.classes;
    WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END;
    Apply(st, n.style)
  END
END ClusterStyle;

(* rgb at opacity a over white, rounded, or None *)
PROCEDURE Fade(rgb: LONGINT; a: LONGREAL): LONGINT;
  VAR k, c, r, m: LONGINT;
BEGIN
  IF rgb = None THEN RETURN None END;
  r := 0; m := 1;
  FOR k := 0 TO 2 DO
    c := rgb DIV m MOD 100H;
    r := r + ENTIER(c * a + 255 * (1 - a) + 0.5D0) * m;
    m := m * 100H
  END;
  RETURN r
END Fade;

(* st, a block's style in a block diagram: a composite block's is the
   clusters' colours, its fill at 0.5 and its outline at 0.2 over
   white, any other's the nodes'; then classDef default, if it has no
   classes, or its classes', then its style statement's *)
PROCEDURE BlockStyle*(g: F.Graph; composite: BOOLEAN; classes: F.Name; style: F.Prop; VAR st: Style);
BEGIN
  IF composite THEN
    st.fill := ThemeColour(Fade(clusterFill, 0.5D0)); st.line := ThemeColour(Fade(clusterLine, 0.2D0))
  ELSE st.fill := ThemeColour(nodeFill); st.line := ThemeColour(nodeLine)
  END;
  st.text := ThemeColour(nodeText); st.width := px; st.dash := 0; st.inner := NoColour;
  IF classes = NIL THEN ApplyClass(g, st, "default")
  ELSE
    WHILE classes # NIL DO ApplyClass(g, st, classes.name^); classes := classes.next END
  END;
  Apply(st, style)
END BlockStyle;

(* st, an edge's style in a block diagram: the line colour, 2 pixels
   wide, 3.5 if thick, dashed 3 if dotted; its label in the text
   colour *)
PROCEDURE BlockEdgeStyle*(thick, dotted: BOOLEAN; VAR st: Style);
BEGIN
  st.fill := NoColour; st.line := ThemeColour(edgeLine); st.text := ThemeColour(textColour);
  st.width := 2 * px; st.dash := 0; st.inner := NoColour;
  IF thick THEN st.width := 3.5 * px END;
  IF dotted THEN st.dash := 3 * px END
END BlockEdgeStyle;

(* st, edge e's style: Mermaid's default theme for its kind of line
   and diagram, then its class statements', then its linkStyle *)
PROCEDURE EdgeStyle*(g: F.Graph; e: F.Edge; VAR st: Style);
  VAR c: F.Name;
BEGIN
  st.fill := NoColour; st.line := ThemeColour(edgeLine); st.text := ThemeColour(nodeText);
  st.width := 2 * px; st.dash := 0; st.inner := NoColour;
  IF g.kind = F.State THEN
    (* transitions are 1 pixel wide; a note's edge is dashed *)
    st.width := px;
    IF e.line = F.Dotted THEN st.dash := 5 * px END
  ELSIF g.kind = F.Class THEN
    (* relations are 1 pixel wide; a note's edge is dotted *)
    st.width := px;
    IF e.from.shape = F.Rect THEN st.dash := 2 * px
    ELSIF e.line = F.Dotted THEN st.dash := 3 * px
    END
  ELSIF g.kind = F.Er THEN
    (* relationships are 1 pixel wide; non-identifying ones dashed *)
    st.width := px;
    IF e.line = F.Dotted THEN st.dash := 8 * px END;
    IF (e.head = F.ZeroOrOne) OR (e.head = F.ZeroOrMore) OR (e.tail = F.ZeroOrOne)
       OR (e.tail = F.ZeroOrMore) THEN
      st.inner := Colour(0FFFFFFH)  (* a circle's fill, in the table *)
    END
  ELSIF g.kind = F.Req THEN
    (* relationships are 1 pixel wide; all but contains dashed *)
    st.width := px;
    IF e.line = F.Dotted THEN st.dash := 10 * px END
  ELSIF e.line = F.Thick THEN st.width := 3.5 * px
  ELSIF e.line = F.Dotted THEN st.dash := 3 * px
  END;
  c := e.classes;
  WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END;
  Apply(st, e.style)
END EdgeStyle;

BEGIN
  nColours := 0; px := 1;
  nodeFill := NodeFill; nodeLine := NodeLine; nodeText := TextColour;
  textColour := TextColour; titleColour := TextColour; edgeLine := EdgeLine;
  labelBack := LabelBack; clusterFill := ClusterFill; clusterLine := ClusterLine;
  noteFill := NoteFill; noteLine := NoteLine; noteText := TextColour;
  compositeBack := CompositeBack; altBack := AltBack; rowOdd := RowOdd; rowEven := RowEven
END PmStyle.
