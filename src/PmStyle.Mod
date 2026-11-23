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
  MaxColours = 256;
  NoColour* = -1;
  (* Mermaid's default theme *)
  NodeFill = 0ECECFFH; NodeLine = 09370DBH; TextColour = 0333333H;
  EdgeLine = 0333333H;
  LabelBack = 0E8E8E8H;  (* behind an edge's label *)
  ClusterFill = 0FFFFDEH; ClusterLine = 0AAAA33H;
  (* and its state diagrams' *)
  NoteFill = 0FFF5ADH; NoteLine = 0AAAA33H;
  CompositeBack = 0FFFFFFH; AltBack = 0F0F0F0H;
  None = -1;  (* a theme's colour that is none *)

TYPE
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
  noteFill, noteLine, noteText, compositeBack, altBack: LONGINT;


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
PROCEDURE ParseLength(VAR s: ARRAY OF CHAR; VAR x: REAL): BOOLEAN;
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
PROCEDURE Apply(VAR st: Style; p: F.Prop);
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

(* The index of the diagram's title's colour, or NoColour *)
PROCEDURE TitleColour*(): INTEGER;
BEGIN
  RETURN ThemeColour(textColour)
END TitleColour;

(* The theme's colours: Mermaid's default theme's, changed by g's
   themeVariables, a variable the flowchart uses (mainBkg, nodeBorder,
   ...) after those it is made from (border1, ...), as Mermaid does *)
PROCEDURE Theme(g: F.Graph);
  VAR set: BOOLEAN;

  (* c, the themeVariable name's colour, if g sets it *)
  PROCEDURE Var(name: ARRAY OF CHAR; VAR c: LONGINT): BOOLEAN;
    VAR q: Y.Pair; key: ARRAY 64 OF CHAR; v: ARRAY 128 OF CHAR;
      rgb: LONGINT; none: BOOLEAN; i, j: INTEGER;
  BEGIN
    IF g.config = NIL THEN RETURN FALSE END;
    key := "config.themeVariables."; i := 0;
    WHILE key[i] # 0X DO INC(i) END;
    j := 0;
    WHILE name[j] # 0X DO key[i] := name[j]; INC(i); INC(j) END;
    key[i] := 0X;
    q := Y.Find(g.config, key);
    IF q = NIL THEN RETURN FALSE END;
    Clean(q.value, v);
    IF ParseColour(v, rgb, none) THEN
      IF none THEN c := None ELSE c := rgb END;
      RETURN TRUE
    END;
    PmIO.Message3("ignoring the colour ", v, ", which pomermaid does not know");
    RETURN FALSE
  END Var;

BEGIN
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
  set := Var("altBackground", altBack)
END Theme;

(* Empties the colour table, and sets the theme's colours from g's
   themeVariables; lengths in pixels are taken as pixel points each
   from now on *)
PROCEDURE Reset*(g: F.Graph; pixel: REAL);
BEGIN
  nColours := 0; px := pixel;
  Theme(g)
END Reset;

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
   the notes' colours *)
PROCEDURE NodeStyle*(g: F.Graph; n: F.Node; VAR st: Style);
  VAR c: F.Name;
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
  END;
  ApplyClass(g, st, "default");
  c := n.classes;
  WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END;
  Apply(st, n.style)
END NodeStyle;

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

(* st, edge e's style: Mermaid's default theme for its kind of line,
   then its class statements', then its linkStyle *)
PROCEDURE EdgeStyle*(g: F.Graph; e: F.Edge; VAR st: Style);
  VAR c: F.Name;
BEGIN
  st.fill := NoColour; st.line := ThemeColour(edgeLine); st.text := ThemeColour(nodeText);
  st.width := 2 * px; st.dash := 0; st.inner := NoColour;
  IF g.kind = F.State THEN
    (* transitions are 1 pixel wide; a note's edge is dashed *)
    st.width := px;
    IF e.line = F.Dotted THEN st.dash := 5 * px END
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
  compositeBack := CompositeBack; altBack := AltBack
END PmStyle.
