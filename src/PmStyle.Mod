MODULE PmStyle;
(* PmStyle: the colours, line widths and dashes of a flowchart's nodes
   and edges, for the writers. They are Mermaid's default theme's, with
   lengths in Mermaid's pixels scaled to the labels' size (16 pixels to
   the size), changed by classDef "default", the node's classes and its
   style statements, in that order, and by linkStyle for edges.

   The colours a diagram uses are kept in a table, each once, in the
   order they are first used; a style refers to them by their index. *)

IMPORT PmIO, F := PmFlow, Lx := PmLex;

CONST
  MaxColours = 256;
  NoColour* = -1;
  (* Mermaid's default theme *)
  NodeFill = 0ECECFFH; NodeLine = 09370DBH; TextColour = 0333333H;
  EdgeLine = 0333333H;
  LabelBack* = 0E8E8E8H;  (* behind an edge's label *)

TYPE
  Style* = RECORD
    fill*, line*, text*: INTEGER;  (* indexes into the colours, or NoColour *)
    width*, dash*: REAL            (* points; dash 0 for a solid line *)
  END;

VAR
  colour: ARRAY MaxColours OF LONGINT;
  nColours-: INTEGER;   (* the colours in the table *)
  px: REAL;             (* a Mermaid pixel, in points *)

(* Empties the colour table; lengths in pixels are taken as pixel
   points each from now on *)
PROCEDURE Reset*(pixel: REAL);
BEGIN
  nColours := 0; px := pixel
END Reset;

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
   n's classes and its style statements *)
PROCEDURE NodeStyle*(g: F.Graph; n: F.Node; VAR st: Style);
  VAR c: F.Name;
BEGIN
  st.fill := Colour(NodeFill); st.line := Colour(NodeLine); st.text := Colour(TextColour);
  st.width := px; st.dash := 0;
  ApplyClass(g, st, "default");
  c := n.classes;
  WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END;
  Apply(st, n.style)
END NodeStyle;

(* st, edge e's style: Mermaid's default theme for its kind of line,
   then its linkStyle *)
PROCEDURE EdgeStyle*(e: F.Edge; VAR st: Style);
BEGIN
  st.fill := NoColour; st.line := Colour(EdgeLine); st.text := Colour(TextColour);
  st.width := 2 * px; st.dash := 0;
  IF e.line = F.Thick THEN st.width := 3.5 * px
  ELSIF e.line = F.Dotted THEN st.dash := 3 * px
  END;
  Apply(st, e.style)
END EdgeStyle;

BEGIN
  nColours := 0; px := 1
END PmStyle.
