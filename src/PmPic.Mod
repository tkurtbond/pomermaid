MODULE PmPic;
(* PmPic: a laid out flowchart written in pic, for groff.

   The output is a .defcolor line for each colour, then the picture: the
   size and line spacing the labels were measured at, set before .PS and
   put back after .PE, and the drawing, edges first, then their labels,
   then the nodes, as Mermaid draws them. Coordinates are in inches,
   y up; a label is set in its font with \f[...] and its colour with
   \m[...], and characters outside ASCII are written \[uXXXX], so groff
   needs no -k.

   The colours, line widths and dashes are Mermaid's default theme's,
   with lengths in Mermaid's pixels scaled to the labels' size (16
   pixels to the size), changed by classDef "default", the node's
   classes and its style statements, in that order, and by linkStyle
   for edges. Colours are named after their value, pm-rrggbb, so the
   same colour has the same name in every diagram.

   Edges are pic splines through the layout's points: pic's spline, as
   d3's curveBasis Mermaid draws with, is a B-spline that starts at
   the first point and ends at the last. A dashed or dotted edge is
   sampled along the curve, as pic does not dash splines, and each dash
   is a line of its own. *)

IMPORT Math, PmIO, F := PmFlow, M := PmMetrics, G := PmGeom, L := PmLayout,
  FL := PmFlowLayout, Lx := PmLex;

CONST
  MaxColours = 256;
  NoColour = -1;
  Samples = 8;       (* the points per curve of a dashed edge *)
  (* Mermaid's default theme *)
  NodeFill = 0ECECFFH; NodeLine = 09370DBH; TextColour = 0333333H;
  EdgeLine = 0333333H; LabelBack = 0E8E8E8H;

TYPE
  Style = RECORD
    fill, line, text: INTEGER;  (* indexes into colour, or NoColour *)
    width, dash: REAL           (* points; dash 0 for a solid line *)
  END;
  Styles = POINTER TO ARRAY OF Style;

VAR
  colour: ARRAY MaxColours OF LONGINT;
  nColours: INTEGER;
  px: REAL;          (* a Mermaid pixel, in points *)
  fontName: ARRAY 64 OF CHAR;

(* Colours *)

(* The index of colour rgb, added if it is new *)
PROCEDURE Colour(rgb: LONGINT): INTEGER;
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
PROCEDURE ParseColour(VAR s: ARRAY OF CHAR; VAR rgb: LONGINT; VAR none: BOOLEAN): BOOLEAN;
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

PROCEDURE NodeStyle(g: F.Graph; n: F.Node; VAR st: Style);
  VAR c: F.Name;
BEGIN
  st.fill := Colour(NodeFill); st.line := Colour(NodeLine); st.text := Colour(TextColour);
  st.width := px; st.dash := 0;
  ApplyClass(g, st, "default");
  c := n.classes;
  WHILE c # NIL DO ApplyClass(g, st, c.name^); c := c.next END;
  Apply(st, n.style)
END NodeStyle;

PROCEDURE EdgeStyle(e: F.Edge; VAR st: Style);
BEGIN
  st.fill := NoColour; st.line := Colour(EdgeLine); st.text := Colour(TextColour);
  st.width := 2 * px; st.dash := 0;
  IF e.line = F.Thick THEN st.width := 3.5 * px
  ELSIF e.line = F.Dotted THEN st.dash := 3 * px
  END;
  Apply(st, e.style)
END EdgeStyle;

(* Output *)

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

(* x in hexadecimal, digits of it, in lower case; upper case if up *)
PROCEDURE HexCase(x: LONGINT; digits: INTEGER; up: BOOLEAN);
  VAR d: ARRAY 9 OF CHAR; i: INTEGER; a: CHAR;
BEGIN
  IF up THEN a := "A" ELSE a := "a" END;
  FOR i := digits - 1 TO 0 BY -1 DO
    IF x MOD 16 < 10 THEN d[i] := CHR(ORD("0") + x MOD 16)
    ELSE d[i] := CHR(ORD(a) + x MOD 16 - 10)
    END;
    x := x DIV 16
  END;
  d[digits] := 0X; W(d)
END HexCase;

PROCEDURE Hex(x: LONGINT; digits: INTEGER);
BEGIN
  HexCase(x, digits, FALSE)
END Hex;

PROCEDURE ColourName(c: INTEGER);
BEGIN
  W('"pm-'); Hex(colour[c], 6); W('"')
END ColourName;

(* A length in points, in inches *)
PROCEDURE In(x: REAL);
BEGIN
  PmIO.WriteReal(x / 72, 3)
END In;

(* The point (x, y) of the layout, y down, as pic's (x, -y) *)
PROCEDURE Pt(x, y: REAL);
BEGIN
  W("("); In(x); W(", "); In(-y); W(")")
END Pt;

(* " at (x, y)" *)
PROCEDURE At(x, y: REAL);
BEGIN
  W(" at "); Pt(x, y)
END At;

(* The fill, outline, thickness and dashes of st *)
PROCEDURE Paint(VAR st: Style; filled: BOOLEAN);
BEGIN
  IF filled & (st.fill # NoColour) THEN W(" shaded "); ColourName(st.fill) END;
  IF st.line # NoColour THEN
    W(" outlined "); ColourName(st.line); W(" thickness "); PmIO.WriteReal(st.width, 3);
    IF st.dash > 0 THEN W(" dashed "); In(st.dash) END
  ELSIF filled & (st.fill # NoColour) THEN
    W(" outlined "); ColourName(st.fill); W(" thickness 0")
  ELSE W(" invis")
  END
END Paint;

(* A line of text, s[0 ..], escaped for groff: "\" as \e, '"' as \(dq,
   anything outside ASCII as \[uXXXX] *)
PROCEDURE Escaped(VAR s: ARRAY OF CHAR);
  VAR i, end, c: LONGINT;
BEGIN
  i := 0; end := Lx.Length(s);
  WHILE i < end DO
    IF s[i] >= 80X THEN
      c := M.Decode(s, i, end);
      W("\[u"); IF c > 0FFFFH THEN HexCase(c, 5, TRUE) ELSE HexCase(c, 4, TRUE) END; W("]")
    ELSE
      IF s[i] = "\" THEN W("\e")
      ELSIF s[i] = '"' THEN W("\(dq")
      ELSIF s[i] >= " " THEN PmIO.WriteChar(s[i])
      END;
      INC(i)
    END
  END
END Escaped;

(* The lines of lab, centred at (x, y), in colour c *)
PROCEDURE Text(lab: F.Label; x, y: REAL; c: INTEGER);
  VAR line: F.Line;
BEGIN
  IF (lab = NIL) OR (lab.n = 0) THEN RETURN END;
  line := lab.lines;
  WHILE line # NIL DO
    W('"\f['); W(fontName); W("]");
    IF c # NoColour THEN W("\m[pm-"); Hex(colour[c], 6); W("]") END;
    Escaped(line.text^);
    IF c # NoColour THEN W("\m[]") END;
    W('\f[]" ');
    line := line.next
  END;
  At(x, y); PmIO.WriteLn
END Text;

(* The direction (ux, uy), of length 1, in which an edge reaches its
   last point, p[n-1] *)
PROCEDURE EndDirection(VAR p: ARRAY OF G.Point; n: INTEGER; VAR ux, uy: REAL);
  VAR k: INTEGER; d: REAL;
BEGIN
  ux := 0; uy := 0; k := n - 2;
  WHILE (k >= 0) & (ABS(p[k].x - p[n - 1].x) + ABS(p[k].y - p[n - 1].y) < 0.01) DO DEC(k) END;
  IF k >= 0 THEN
    ux := p[n - 1].x - p[k].x; uy := p[n - 1].y - p[k].y;
    d := Math.sqrt(ux * ux + uy * uy); ux := ux / d; uy := uy / d
  END
END EndDirection;

(* A circle or a cross at an edge's end p[n-1], in st's line colour *)
PROCEDURE Marker(kind: INTEGER; VAR p: ARRAY OF G.Point; n: INTEGER; VAR st: Style);
  VAR ux, uy, r, cx, cy: REAL;
BEGIN
  IF (kind # F.CircleEnd) & (kind # F.Cross) OR (st.line = NoColour) THEN RETURN END;
  EndDirection(p, n, ux, uy);
  r := 5.5 * px;
  cx := p[n - 1].x - ux * r; cy := p[n - 1].y - uy * r;
  IF kind = F.CircleEnd THEN
    W("circle rad "); In(r); At(cx, cy);
    W(" shaded "); ColourName(st.line); W(" outlined "); ColourName(st.line);
    W(" thickness 0"); PmIO.WriteLn
  ELSE
    r := r * 0.7;
    W("line from "); Pt(cx - r, cy - r); W(" to "); Pt(cx + r, cy + r);
    W(" outlined "); ColourName(st.line); W(" thickness "); PmIO.WriteReal(st.width, 3); PmIO.WriteLn;
    W("line from "); Pt(cx - r, cy + r); W(" to "); Pt(cx + r, cy - r);
    W(" outlined "); ColourName(st.line); W(" thickness "); PmIO.WriteReal(st.width, 3); PmIO.WriteLn
  END
END Marker;

(* The points p[0 .. n-1] as "from P to P ...", four to a line *)
PROCEDURE Path(VAR p: ARRAY OF G.Point; n: INTEGER);
  VAR k: INTEGER;
BEGIN
  W(" from "); Pt(p[0].x, p[0].y);
  FOR k := 1 TO n - 1 DO
    IF k MOD 4 = 0 THEN W(" \"); PmIO.WriteLn; W(" ") END;
    W(" to "); Pt(p[k].x, p[k].y)
  END
END Path;

(* The line colour and thickness of st *)
PROCEDURE Stroke(VAR st: Style);
BEGIN
  W(" outlined "); ColourName(st.line); W(" thickness "); PmIO.WriteReal(st.width, 3)
END Stroke;

(* The polyline s[0 .. ns-1] dashed: dashes of st.dash points with gaps
   as long, each a line of its own. groff dashes each piece of a line
   separately, so a line of many short pieces would come out solid. *)
PROCEDURE Dashes(VAR s: ARRAY OF G.Point; ns: INTEGER; VAR st: Style);
  VAR
    piece: G.Points; np, k: INTEGER; on: BOOLEAN;
    left, pos, len, dx, dy: REAL;

  PROCEDURE Add(x, y: REAL);
  BEGIN
    G.Set(piece[np], x, y); INC(np)
  END Add;

  PROCEDURE Flush;
  BEGIN
    IF np >= 2 THEN W("line"); Path(piece^, np); Stroke(st); PmIO.WriteLn END;
    np := 0
  END Flush;

BEGIN
  piece := G.NewPoints(ns + 2); np := 0;
  on := TRUE; left := st.dash; Add(s[0].x, s[0].y);
  FOR k := 1 TO ns - 1 DO
    dx := s[k].x - s[k - 1].x; dy := s[k].y - s[k - 1].y;
    len := Math.sqrt(dx * dx + dy * dy); pos := 0;
    IF len > 0 THEN
      WHILE len - pos > left DO
        pos := pos + left;
        IF on THEN Add(s[k - 1].x + dx * pos / len, s[k - 1].y + dy * pos / len); Flush
        ELSE Add(s[k - 1].x + dx * pos / len, s[k - 1].y + dy * pos / len)
        END;
        on := ~on; left := st.dash
      END;
      left := left - (len - pos);
      IF on THEN Add(s[k].x, s[k].y) END
    END
  END;
  IF on THEN Flush END
END Dashes;

(* An arrowhead at the end p[n-1] of a path, drawn as a short solid line
   along the path's last direction *)
PROCEDURE Head(VAR p: ARRAY OF G.Point; n: INTEGER; VAR st: Style);
  VAR ux, uy: REAL;
BEGIN
  EndDirection(p, n, ux, uy);
  IF (ux # 0) OR (uy # 0) THEN
    W("line -> from "); Pt(p[n - 1].x - ux * px, p[n - 1].y - uy * px);
    W(" to "); Pt(p[n - 1].x, p[n - 1].y); Stroke(st); PmIO.WriteLn
  END
END Head;

PROCEDURE DrawEdge(e: F.Edge; le: L.Edge; VAR st: Style);
  VAR b, s, r: G.Points; nb, ns, k, t, n: INTEGER; p: G.Points;
BEGIN
  IF (e.line = F.Invisible) OR (st.line = NoColour) THEN RETURN END;
  p := le.points; n := le.nPoints;
  IF n < 2 THEN RETURN END;
  IF st.dash > 0 THEN
    (* the curve, sampled, then dashed *)
    IF n > 2 THEN
      G.Basis(p^, n, b, nb);
      s := G.NewPoints(1 + (nb - 1) DIV 3 * Samples);
      s[0] := b[0]; ns := 1;
      k := 0;
      WHILE k + 3 < nb DO
        FOR t := 1 TO Samples DO G.OnCurve(b[k], b[k + 1], b[k + 2], b[k + 3], t / Samples, s[ns]); INC(ns) END;
        INC(k, 3)
      END
    ELSE s := p; ns := n
    END;
    Dashes(s^, ns, st);
    IF e.head = F.Arrow THEN Head(s^, ns, st) END;
    IF e.tail = F.Arrow THEN
      r := G.NewPoints(ns);
      FOR k := 0 TO ns - 1 DO r[k] := s[ns - 1 - k] END;
      Head(r^, ns, st)
    END
  ELSE
    IF n = 2 THEN W("line") ELSE W("spline") END;
    IF (e.head = F.Arrow) & (e.tail = F.Arrow) THEN W(" <->")
    ELSIF e.head = F.Arrow THEN W(" ->")
    ELSIF e.tail = F.Arrow THEN W(" <-")
    END;
    Path(p^, n); Stroke(st); PmIO.WriteLn
  END;
  Marker(e.head, p^, n, st);
  IF e.tail # F.None THEN
    (* the start, as the end of the points reversed *)
    s := G.NewPoints(n);
    FOR k := 0 TO n - 1 DO s[k] := p[n - 1 - k] END;
    Marker(e.tail, s^, n, st)
  END
END DrawEdge;

PROCEDURE DrawLabel(l: FL.Layout; e: F.Edge; le: L.Edge; VAR st: Style; back: INTEGER);
BEGIN
  IF (e.label = NIL) OR ~le.hasLabel THEN RETURN END;
  W("box wid "); In(le.labelW); W(" ht "); In(le.labelH); At(le.labelX, le.labelY);
  W(" shaded "); ColourName(back); W(" outlined "); ColourName(back); W(" thickness 0");
  PmIO.WriteLn;
  Text(l.edgeLabel[e.index], le.labelX, le.labelY, st.text)
END DrawLabel;

PROCEDURE DrawNode(l: FL.Layout; n: F.Node; VAR st: Style);
  VAR
    ln: L.Node; x, y, w, h, ry, r, d: REAL; pts, closed: G.Points; i, k: INTEGER; body: Style;
BEGIN
  ln := l.g.node[n.index]; x := ln.x; y := ln.y; w := ln.w; h := ln.h;
  CASE n.shape OF
    F.Rect, F.Round, F.Stadium, F.Subroutine:
      W("box wid "); In(w); W(" ht "); In(h); At(x, y);
      IF n.shape = F.Round THEN W(" rad "); In(5 * px)
      ELSIF n.shape = F.Stadium THEN W(" rad "); In(h / 2)
      END;
      Paint(st, TRUE); PmIO.WriteLn;
      IF (n.shape = F.Subroutine) & (st.line # NoColour) THEN
        d := l.size / 2;
        W("line from "); Pt(x - w / 2 + d, y - h / 2); W(" to "); Pt(x - w / 2 + d, y + h / 2);
        Paint(st, FALSE); PmIO.WriteLn;
        W("line from "); Pt(x + w / 2 - d, y - h / 2); W(" to "); Pt(x + w / 2 - d, y + h / 2);
        Paint(st, FALSE); PmIO.WriteLn
      END
  | F.Cylinder:
      (* the bottom ellipse, the body over its top half, its sides and
         the top ellipse *)
      ry := w / 2 / (2.5 + w / 50);
      W("ellipse wid "); In(w); W(" ht "); In(2 * ry); At(x, y + h / 2 - ry);
      Paint(st, TRUE); PmIO.WriteLn;
      IF st.fill # NoColour THEN
        body := st; body.line := NoColour;
        W("box wid "); In(w); W(" ht "); In(h - 2 * ry); At(x, y); Paint(body, TRUE); PmIO.WriteLn
      END;
      IF st.line # NoColour THEN
        W("line from "); Pt(x - w / 2, y - h / 2 + ry); W(" to "); Pt(x - w / 2, y + h / 2 - ry);
        Paint(st, FALSE); PmIO.WriteLn;
        W("line from "); Pt(x + w / 2, y - h / 2 + ry); W(" to "); Pt(x + w / 2, y + h / 2 - ry);
        Paint(st, FALSE); PmIO.WriteLn
      END;
      W("ellipse wid "); In(w); W(" ht "); In(2 * ry); At(x, y - h / 2 + ry);
      Paint(st, TRUE); PmIO.WriteLn;
      y := y + ry
  | F.Circle, F.DoubleCircle:
      r := w / 2;
      W("circle rad "); In(r); At(x, y); Paint(st, TRUE); PmIO.WriteLn;
      IF n.shape = F.DoubleCircle THEN
        W("circle rad "); In(r - l.size * 5 / 16); At(x, y); Paint(st, TRUE); PmIO.WriteLn
      END
  ELSE
    FL.Outline(n.shape, x, y, w, h, pts, k);
    IF k > 0 THEN
      closed := G.NewPoints(k + 1);
      FOR i := 0 TO k - 1 DO closed[i] := pts[i] END;
      closed[k] := pts[0];
      W("line"); Path(closed^, k + 1); Paint(st, TRUE); PmIO.WriteLn
    END
  END;
  Text(l.nodeLabel[n.index], x, y, st.text)
END DrawNode;

(* Writes l's flowchart in pic, its labels in the groff font font *)
PROCEDURE Write*(l: FL.Layout; font: ARRAY OF CHAR);
  VAR
    g: F.Graph; n: F.Node; e: F.Edge; ns, es: Styles; back, k: INTEGER;
BEGIN
  g := l.graph; COPY(font, fontName);
  nColours := 0; px := l.size / 16;
  NEW(ns, g.nNodes + 1); NEW(es, g.nEdges + 1);
  n := g.nodes;
  WHILE n # NIL DO NodeStyle(g, n, ns[n.index]); n := n.next END;
  e := g.edges;
  WHILE e # NIL DO EdgeStyle(e, es[e.index]); e := e.next END;
  back := Colour(LabelBack);
  FOR k := 0 TO nColours - 1 DO
    W(".defcolor pm-"); Hex(colour[k], 6); W(" rgb #"); Hex(colour[k], 6); PmIO.WriteLn
  END;
  W(".nr pm*ps \n[.ps]"); PmIO.WriteLn;
  W(".nr pm*vs \n[.v]"); PmIO.WriteLn;
  W(".ps "); PmIO.WriteReal(l.size, 2); PmIO.WriteLn;
  W(".vs "); PmIO.WriteReal(l.vs, 2); W("p"); PmIO.WriteLn;
  W(".PS"); PmIO.WriteLn;
  W("maxpswid = 1000; maxpsht = 1000"); PmIO.WriteLn;
  W("arrowht = "); In(8 * px); W("; arrowwid = "); In(8 * px); PmIO.WriteLn;
  e := g.edges;
  WHILE e # NIL DO DrawEdge(e, l.g.edge[e.index], es[e.index]); e := e.next END;
  e := g.edges;
  WHILE e # NIL DO DrawLabel(l, e, l.g.edge[e.index], es[e.index], back); e := e.next END;
  n := g.nodes;
  WHILE n # NIL DO DrawNode(l, n, ns[n.index]); n := n.next END;
  W(".PE"); PmIO.WriteLn;
  W(".ps \n[pm*ps]z"); PmIO.WriteLn;
  W(".vs \n[pm*vs]u"); PmIO.WriteLn
END Write;

END PmPic.
