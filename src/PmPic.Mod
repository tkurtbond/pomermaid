MODULE PmPic;
(* PmPic: a laid out flowchart written in pic, for groff.

   The output is a .defcolor line for each colour, then the picture: the
   size and line spacing the labels were measured at, set before .PS and
   put back after .PE, and the drawing, edges first, then their labels,
   then the nodes, as Mermaid draws them. Coordinates are in inches,
   y up; a label is set in its font with \f[...] and its colour with
   \m[...], and characters outside ASCII are written \[uXXXX], so groff
   needs no -k.

   The colours, line widths and dashes are PmStyle's. Colours are named
   after their value, pm-rrggbb, so the same colour has the same name
   in every diagram.

   Edges are pic splines through the layout's points: pic's spline, as
   d3's curveBasis Mermaid draws with, is a B-spline that starts at
   the first point and ends at the last. A dashed or dotted edge is
   sampled along the curve, as pic does not dash splines, and each dash
   is a line of its own. *)

IMPORT Math, PmIO, F := PmFlow, M := PmMetrics, G := PmGeom, L := PmLayout,
  FL := PmFlowLayout, Lx := PmLex, S := PmStyle, Shp := PmShapes, Cv := PmCurves;

CONST
  NoColour = S.NoColour;
  Samples = 8;       (* the points per curve of a dashed edge *)

TYPE
  Style = S.Style;
  Styles = POINTER TO ARRAY OF Style;

VAR
  px: REAL;          (* a Mermaid pixel, in points *)
  fontName: ARRAY 64 OF CHAR;
  labelFont: M.Font; (* the labels' font, with its styles *)

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
  W('"pm-'); Hex(S.Rgb(c), 6); W('"')
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
PROCEDURE EscapedPart(VAR s: ARRAY OF CHAR; i, end: LONGINT);
  VAR c: LONGINT;
BEGIN
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
END EscapedPart;

PROCEDURE Escaped(VAR s: ARRAY OF CHAR);
BEGIN
  EscapedPart(s, 0, Lx.Length(s))
END Escaped;

(* line's text, which has styles, each run of a style in its font, each starting from
   the font before the label and going back to it *)
PROCEDURE Runs(line: F.Line);
  VAR i, j, end: LONGINT; st: INTEGER;
BEGIN
  end := Lx.Length(line.text^); i := 0;
  WHILE i < end DO
    j := i; st := line.style[i];
    WHILE (j < end) & (line.style[j] = st) DO INC(j) END;
    W("\f[");
    IF (st = F.Roman) OR (labelFont = NIL) THEN W(fontName) ELSE W(labelFont.styled[st].name) END;
    W("]"); EscapedPart(line.text^, i, j); W("\f[]");
    i := j
  END
END Runs;

(* The lines of lab, centred at (x, y), in colour c *)
(* The text of lab, in colour c, at (x, y), at size points, or the
   current size for 0 *)
PROCEDURE SizedText(lab: F.Label; x, y: REAL; c: INTEGER; size: REAL);
  VAR line: F.Line;
BEGIN
  IF (lab = NIL) OR (lab.n = 0) THEN RETURN END;
  line := lab.lines;
  WHILE line # NIL DO
    W('"');
    IF size > 0 THEN W("\s["); PmIO.WriteReal(size, 2); W("]") END;
    IF line.style = NIL THEN W("\f["); W(fontName); W("]") END;
    IF c # NoColour THEN W("\m[pm-"); Hex(S.Rgb(c), 6); W("]") END;
    IF line.style = NIL THEN Escaped(line.text^) ELSE Runs(line) END;
    IF c # NoColour THEN W("\m[]") END;
    IF line.style = NIL THEN W("\f[]") END;
    IF size > 0 THEN W("\s[0]") END;
    W('" ');
    line := line.next
  END;
  At(x, y); PmIO.WriteLn
END SizedText;

PROCEDURE Text(lab: F.Label; x, y: REAL; c: INTEGER);
BEGIN
  SizedText(lab, x, y, c, 0)
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

(* The closed polygon p[0 .. n-1] in st. pic fills no line, and its
   polygon is groff 1.24's, so the fill is troff's \D'P', in a string
   at p[0]: pic sets a string 0.22m below its point, and \v'-0.22m'
   takes that back. The coordinates are rounded to thousandths of an
   inch, as pic's own, and each step is their difference. *)
PROCEDURE Polygon(VAR p: ARRAY OF G.Point; n: INTEGER; VAR st: Style);
  VAR closed: G.Points; i: INTEGER; x0, y0, x1, y1: LONGINT;

  PROCEDURE Milli(v: REAL): LONGINT;
  BEGIN
    IF v < 0 THEN RETURN -PmIO.Round(v / 72, 3)
    ELSE RETURN PmIO.Round(v / 72, 3)
    END
  END Milli;

BEGIN
  IF n < 2 THEN RETURN END;
  IF st.fill # NoColour THEN
    W('"\M[pm-'); Hex(S.Rgb(st.fill), 6); W("]\v'-0.22m'\D'P");
    x0 := Milli(p[0].x); y0 := Milli(p[0].y);
    FOR i := 1 TO n - 1 DO
      x1 := Milli(p[i].x); y1 := Milli(p[i].y);
      W(" "); PmIO.WriteReal((x1 - x0) / 1000, 3); W("i ");
      PmIO.WriteReal((y1 - y0) / 1000, 3); W("i");
      x0 := x1; y0 := y1
    END;
    W("'\M[]"); W('" ljust'); At(p[0].x, p[0].y); PmIO.WriteLn
  END;
  IF st.line # NoColour THEN
    closed := G.NewPoints(n + 1);
    FOR i := 0 TO n - 1 DO closed[i] := p[i] END;
    closed[n] := p[0];
    W("line"); Path(closed^, n + 1); Paint(st, FALSE); PmIO.WriteLn
  END
END Polygon;

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
  IF e.curve # F.Basis THEN
    (* another curve, as the line through its corners or its samples *)
    Cv.Make(e.curve, p^, n, b, nb);
    Cv.Sample(Cv.Straight(e.curve, n), b^, nb, Samples, p, n)
  END;
  IF st.dash > 0 THEN
    (* the curve, sampled, then dashed *)
    IF (n > 2) & (e.curve = F.Basis) THEN
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
    IF (n = 2) OR (e.curve # F.Basis) THEN W("line") ELSE W("spline") END;
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
  IF back # NoColour THEN
    W("box wid "); In(le.labelW); W(" ht "); In(le.labelH); At(le.labelX, le.labelY);
    W(" shaded "); ColourName(back); W(" outlined "); ColourName(back); W(" thickness 0");
    PmIO.WriteLn
  END;
  Text(l.edgeLabel[e.index], le.labelX, le.labelY, st.text)
END DrawLabel;

(* A part of a drawing of PmShapes's, in st *)
PROCEDURE DrawPart(VAR pt: Shp.Part; VAR st: Style);
  VAR s: Style;
BEGIN
  IF pt.n < 2 THEN RETURN END;
  s := st;
  IF pt.kind = Shp.Line THEN
    W("line"); Path(pt.p^, pt.n); Paint(s, FALSE); PmIO.WriteLn
  ELSE
    IF pt.kind = Shp.Solid THEN
      IF s.line # NoColour THEN s.fill := s.line ELSE s.line := s.fill END
    ELSIF pt.kind = Shp.Fill THEN s.line := NoColour
    END;
    Polygon(pt.p^, pt.n, s)
  END
END DrawPart;

PROCEDURE DrawNode(l: FL.Layout; n: F.Node; VAR st: Style);
  VAR
    ln: L.Node; x, y, w, h, ry, r, d: REAL; pts: G.Points; i, k: INTEGER; body: Style;
    dr: Shp.Drawing;
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
    IF Shp.Has(n.shape) THEN
      Shp.Draw(n.shape, x, y, w, h, l.textH[n.index], l.size, dr);
      FOR i := 0 TO dr.n - 1 DO DrawPart(dr.part[i], st) END;
      IF ~dr.label THEN RETURN END;
      x := dr.lx; y := dr.ly; k := -1
    ELSE FL.Outline(n.shape, x, y, w, h, l.size, pts, k)
    END;
    IF k < 0 THEN
    ELSIF k > 0 THEN
      Polygon(pts^, k, st)
    ELSE
      W("box wid "); In(w); W(" ht "); In(h); At(x, y); Paint(st, TRUE); PmIO.WriteLn
    END
  END;
  Text(l.nodeLabel[n.index], x, y, st.text)
END DrawNode;

(* Cluster c's box, its title at its top *)
PROCEDURE DrawCluster(l: FL.Layout; c: INTEGER; VAR st: Style);
  VAR lc: L.Cluster; d: REAL; k: INTEGER; line: Style;
BEGIN
  lc := l.g.cluster[c];
  IF l.collapsed[c] THEN
    (* Mermaid's collapsedGroup: its title FL.GroupTitle pixels above its
       centre, a dashed line below the title, three dots below that *)
    W("box wid "); In(lc.w); W(" ht "); In(lc.h); At(lc.x, lc.y); W(" rad "); In(8 * px);
    Paint(st, TRUE); PmIO.WriteLn;
    Text(l.clusterLabel[c], lc.titleX, lc.titleY, st.text);
    d := lc.y - lc.h / 2 + 16 * px + (lc.h - FL.GroupExtra * px);
    IF st.line # NoColour THEN
      line := st; line.dash := 3 * px;
      W("line from "); Pt(lc.x - lc.w / 2 + 8 * px, d); W(" to "); Pt(lc.x + lc.w / 2 - 8 * px, d);
      Paint(line, FALSE); PmIO.WriteLn;
      FOR k := -1 TO 1 DO
        W("circle rad "); In(2.5 * px); At(lc.x + 10 * k * px, d + 10 * px);
        W(" shaded "); ColourName(st.line); W(" outlined "); ColourName(st.line);
        W(" thickness 0"); PmIO.WriteLn
      END
    END
  ELSIF lc.w > 0 THEN
    W("box wid "); In(lc.w); W(" ht "); In(lc.h); At(lc.x, lc.y); Paint(st, TRUE); PmIO.WriteLn;
    Text(l.clusterLabel[c], lc.titleX, lc.titleY, st.text)
  END
END DrawCluster;

(* The diagram's title, centred above the drawing, its baseline
   Mermaid's titleTopMargin above the drawing's top, in colour c; an
   invisible box its size takes its place in the picture's bounds *)
PROCEDURE DrawTitle(l: FL.Layout; c: INTEGER);
  VAR cy: REAL;
BEGIN
  IF (l.title = NIL) OR (l.title.n = 0) THEN RETURN END;
  cy := l.titleY - 0.3 * l.titleSize;
  W("box invis wid "); In(l.titleW); W(" ht "); In(l.titleH); At(l.titleX, cy);
  PmIO.WriteLn;
  SizedText(l.title, l.titleX, cy, c, l.titleSize)
END DrawTitle;

(* The styles of l's nodes, edges and clusters, by index; the colour
   table reset first *)
PROCEDURE MakeStyles(l: FL.Layout; VAR ns, es, cs: Styles);
  VAR g: F.Graph; n: F.Node; e: F.Edge; k: INTEGER; cn: POINTER TO ARRAY OF F.Node;
BEGIN
  g := l.graph;
  px := l.size / 16; S.Reset(l.graph, px);
  NEW(ns, g.nNodes + 1); NEW(es, g.nEdges + 1);
  n := g.nodes;
  WHILE n # NIL DO S.NodeStyle(g, n, ns[n.index]); n := n.next END;
  e := g.edges;
  WHILE e # NIL DO S.EdgeStyle(g, e, es[e.index]); e := e.next END;
  NEW(cs, g.nClusters + 1); NEW(cn, g.nClusters + 1);
  FOR k := 0 TO g.nClusters - 1 DO cn[k] := NIL END;
  n := g.nodes;
  WHILE n # NIL DO
    IF l.stands[n.index] >= 0 THEN cn[l.stands[n.index]] := n END;
    n := n.next
  END;
  FOR k := 0 TO g.nClusters - 1 DO S.ClusterStyle(g, k, cn[k], cs[k]) END
END MakeStyles;

(* The width of the widest line Write draws for l, in points *)
PROCEDURE Widest*(l: FL.Layout): REAL;
  VAR ns, es, cs: Styles; g: F.Graph; n: F.Node; e: F.Edge; k: INTEGER; w: REAL;
BEGIN
  MakeStyles(l, ns, es, cs); g := l.graph; w := 0;
  n := g.nodes;
  WHILE n # NIL DO
    IF (l.g.node[n.index].kind # L.Hidden) & (ns[n.index].width > w) THEN w := ns[n.index].width END;
    n := n.next
  END;
  e := g.edges;
  WHILE e # NIL DO IF es[e.index].width > w THEN w := es[e.index].width END; e := e.next END;
  FOR k := 0 TO g.nClusters - 1 DO IF cs[k].width > w THEN w := cs[k].width END END;
  RETURN w
END Widest;

(* Writes l's flowchart in pic, its labels in the groff font font *)
PROCEDURE Write*(l: FL.Layout; font: ARRAY OF CHAR);
  VAR
    g: F.Graph; n: F.Node; e: F.Edge; ns, es, cs: Styles; back, title, k: INTEGER;

  PROCEDURE DrawClusters(c: INTEGER);  (* c, then those it holds *)
    VAR d: INTEGER;
  BEGIN
    DrawCluster(l, c, cs[c]);
    FOR d := 0 TO l.g.nClusters - 1 DO
      IF l.g.cluster[d].parent = c THEN DrawClusters(d) END
    END
  END DrawClusters;

BEGIN
  g := l.graph; COPY(font, fontName); labelFont := l.font;
  MakeStyles(l, ns, es, cs);
  back := S.LabelBackground(); title := S.TitleColour();
  FOR k := 0 TO S.nColours - 1 DO
    W(".defcolor pm-"); Hex(S.Rgb(k), 6); W(" rgb #"); Hex(S.Rgb(k), 6); PmIO.WriteLn
  END;
  W(".nr pm*ps \n[.ps]"); PmIO.WriteLn;
  W(".nr pm*vs \n[.v]"); PmIO.WriteLn;
  W(".ps "); PmIO.WriteReal(l.size, 2); PmIO.WriteLn;
  W(".vs "); PmIO.WriteReal(l.vs, 2); W("p"); PmIO.WriteLn;
  W(".PS"); PmIO.WriteLn;
  W("maxpswid = 1000; maxpsht = 1000"); PmIO.WriteLn;
  W("arrowht = "); In(8 * px); W("; arrowwid = "); In(8 * px); PmIO.WriteLn;
  (* the clusters, each before those it holds *)
  FOR k := 0 TO g.nClusters - 1 DO
    IF l.g.cluster[k].parent < 0 THEN DrawClusters(k) END
  END;
  e := g.edges;
  WHILE e # NIL DO DrawEdge(e, l.g.edge[e.index], es[e.index]); e := e.next END;
  e := g.edges;
  WHILE e # NIL DO DrawLabel(l, e, l.g.edge[e.index], es[e.index], back); e := e.next END;
  n := g.nodes;
  WHILE n # NIL DO
    IF l.g.node[n.index].kind # L.Hidden THEN DrawNode(l, n, ns[n.index]) END;
    n := n.next
  END;
  DrawTitle(l, title);
  W(".PE"); PmIO.WriteLn;
  W(".ps \n[pm*ps]u"); PmIO.WriteLn;
  W(".vs \n[pm*vs]u"); PmIO.WriteLn
END Write;

END PmPic.
