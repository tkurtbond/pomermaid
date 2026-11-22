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
  FL := PmFlowLayout, Lx := PmLex, S := PmStyle;

CONST
  NoColour = S.NoColour;
  Samples = 8;       (* the points per curve of a dashed edge *)

TYPE
  Style = S.Style;
  Styles = POINTER TO ARRAY OF Style;

VAR
  px: REAL;          (* a Mermaid pixel, in points *)
  fontName: ARRAY 64 OF CHAR;

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
    IF c # NoColour THEN W("\m[pm-"); Hex(S.Rgb(c), 6); W("]") END;
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

(* Cluster c's box, its title at its top *)
PROCEDURE DrawCluster(l: FL.Layout; c: INTEGER; VAR st: Style);
  VAR lc: L.Cluster;
BEGIN
  lc := l.g.cluster[c];
  IF lc.w > 0 THEN
    W("box wid "); In(lc.w); W(" ht "); In(lc.h); At(lc.x, lc.y); Paint(st, TRUE); PmIO.WriteLn;
    Text(l.clusterLabel[c], lc.titleX, lc.titleY, st.text)
  END
END DrawCluster;

(* Writes l's flowchart in pic, its labels in the groff font font *)
PROCEDURE Write*(l: FL.Layout; font: ARRAY OF CHAR);
  VAR
    g: F.Graph; n: F.Node; e: F.Edge; ns, es, cs: Styles; back, k: INTEGER;
    cn: POINTER TO ARRAY OF F.Node;

  PROCEDURE DrawClusters(c: INTEGER);  (* c, then those it holds *)
    VAR d: INTEGER;
  BEGIN
    DrawCluster(l, c, cs[c]);
    FOR d := 0 TO l.g.nClusters - 1 DO
      IF l.g.cluster[d].parent = c THEN DrawClusters(d) END
    END
  END DrawClusters;

BEGIN
  g := l.graph; COPY(font, fontName);
  px := l.size / 16; S.Reset(px);
  NEW(ns, g.nNodes + 1); NEW(es, g.nEdges + 1);
  n := g.nodes;
  WHILE n # NIL DO S.NodeStyle(g, n, ns[n.index]); n := n.next END;
  e := g.edges;
  WHILE e # NIL DO S.EdgeStyle(e, es[e.index]); e := e.next END;
  NEW(cs, g.nClusters + 1); NEW(cn, g.nClusters + 1);
  FOR k := 0 TO g.nClusters - 1 DO cn[k] := NIL END;
  n := g.nodes;
  WHILE n # NIL DO
    IF l.stands[n.index] >= 0 THEN cn[l.stands[n.index]] := n END;
    n := n.next
  END;
  FOR k := 0 TO g.nClusters - 1 DO S.ClusterStyle(g, cn[k], cs[k]) END;
  back := S.Colour(S.LabelBack);
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
  W(".PE"); PmIO.WriteLn;
  W(".ps \n[pm*ps]z"); PmIO.WriteLn;
  W(".vs \n[pm*vs]u"); PmIO.WriteLn
END Write;

END PmPic.
