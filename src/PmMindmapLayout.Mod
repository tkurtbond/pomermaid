MODULE PmMindmapLayout;
(* PmMindmapLayout: a mindmap, PmMindmap's, laid out in Mermaid's
   pixels, taken at the drawing's size, 16 pixels to the size, and
   drawn as Mermaid 12.3.0 draws its nodes and edges, its classic look.
   Lengths are in points, y down.

   Mermaid places the nodes with cose-bilkent, a force-directed layout
   that pomermaid does not follow; it lays the tree out tidily on two
   sides of the root instead (decision 29): the root's children, in
   order, go left and right in turn, the first left; each node's
   children are stacked one under another, 20 pixels apart, each
   subtree in a band of its own, and the node is set in the middle of
   them; a child's inner side is 40 pixels from its parent's outer side,
   30 for the root's children.

   The nodes' sizes and shapes are Mermaid's, about their labels, 16
   pixels, wrapped at maxNodeWidth:

   - the default node: a box, its corners rounded to 5, padding wider
     on each side, half of it above and below, with a line, 3 wide,
     along its bottom;
   - "[...]": a box, 20 wider on each side, 10 above and below;
   - "(...)": a box, its corners rounded to 5, 15 about the label;
   - "((...))": a circle, 10 beyond the label's corners;
   - "{{...}}": a hexagon;
   - ")...(": a cloud and "))...((": a bang, their arcs drawn as
     polygons.

   A node in section s is filled with cScale(s+1) and its text and
   bottom line are cScaleLabel(s+1) and cScaleInv(s+1); the root is
   git0, gitBranchLabel0 and cScaleInv0. An edge is a Bézier from its
   parent's middle to its child's, level at both ends, in the child's
   cScale, under the nodes; it is 14 less 3 times its depth (its
   parent's level and 1) wide, or 3 when that is less than 1.

   The bounds are every item's, widened by padding on each side. *)

IMPORT MathL, M := PmMetrics, F := PmFlow, S := PmStyle, H := PmMindmap, D := PmDraw,
  FL := PmFlowLayout;

CONST
  Size = 16;            (* the labels', in pixels *)
  Gap = 20;             (* between siblings' bands *)
  Step = 40;            (* from a parent's side to its child's *)
  RootStep = 30;        (* from the root's side to its children's *)
  MaxPts = 512;
  Steps = 16;           (* the lines an arc is drawn with *)

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: H.Diagram
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;
  Labels = POINTER TO ARRAY OF F.Label;

VAR
  l: Layout;
  d: H.Diagram;
  tl: S.TimelineTheme;
  gt: S.GitTheme;
  lab: Labels;                          (* by node index: the wrapped labels *)
  lw, lh, hw, hh, band, nx, ny: Reals;  (* the labels' sizes, the half sizes,
                                           the bands, the middles *)
  qx, qy: ARRAY MaxPts OF LONGREAL;     (* an outline *)
  nq: INTEGER;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

(* Outlines *)

PROCEDURE Pt(x, y: LONGREAL);
BEGIN
  IF nq < MaxPts THEN qx[nq] := x; qy[nq] := y; INC(nq) END
END Pt;

(* The angle from (ux, uy) to (vx, vy) *)
PROCEDURE Angle(ux, uy, vx, vy: LONGREAL): LONGREAL;
BEGIN
  RETURN MathL.arctan2(ux * vy - uy * vx, ux * vx + uy * vy)
END Angle;

(* SVG's relative arc, "a rx ry rot large sweep dx dy", from the
   outline's last point, as Steps lines (SVG 1.1, F.6.5 and F.6.6) *)
PROCEDURE Arc(rx, ry, rot: LONGREAL; large, sweep: BOOLEAN; dx, dy: LONGREAL);
  VAR
    x1, y1, x2, y2, c, s, xp, yp, lam, num, den, coef, cxp, cyp, cx, cy, t1, dt, t: LONGREAL;
    k: INTEGER;
BEGIN
  x1 := qx[nq - 1]; y1 := qy[nq - 1]; x2 := x1 + dx; y2 := y1 + dy;
  IF (dx = 0) & (dy = 0) THEN RETURN END;
  rx := ABS(rx); ry := ABS(ry);
  IF (rx = 0) OR (ry = 0) THEN Pt(x2, y2); RETURN END;
  c := MathL.cos(rot * MathL.pi / 180); s := MathL.sin(rot * MathL.pi / 180);
  xp := c * (x1 - x2) / 2 + s * (y1 - y2) / 2;
  yp := -s * (x1 - x2) / 2 + c * (y1 - y2) / 2;
  lam := xp * xp / (rx * rx) + yp * yp / (ry * ry);
  IF lam > 1 THEN rx := rx * MathL.sqrt(lam); ry := ry * MathL.sqrt(lam) END;
  num := rx * rx * ry * ry - rx * rx * yp * yp - ry * ry * xp * xp;
  den := rx * rx * yp * yp + ry * ry * xp * xp;
  IF num < 0 THEN num := 0 END;
  coef := MathL.sqrt(num / den);
  IF large = sweep THEN coef := -coef END;
  cxp := coef * rx * yp / ry; cyp := -coef * ry * xp / rx;
  cx := c * cxp - s * cyp + (x1 + x2) / 2; cy := s * cxp + c * cyp + (y1 + y2) / 2;
  t1 := Angle(1, 0, (xp - cxp) / rx, (yp - cyp) / ry);
  dt := Angle((xp - cxp) / rx, (yp - cyp) / ry, (-xp - cxp) / rx, (-yp - cyp) / ry);
  IF ~sweep & (dt > 0) THEN dt := dt - 2 * MathL.pi
  ELSIF sweep & (dt < 0) THEN dt := dt + 2 * MathL.pi
  END;
  FOR k := 1 TO Steps - 1 DO
    t := t1 + dt * k / Steps;
    Pt(cx + rx * c * MathL.cos(t) - ry * s * MathL.sin(t),
      cy + rx * s * MathL.cos(t) + ry * c * MathL.sin(t))
  END;
  Pt(x2, y2)
END Arc;

(* The outline of n's cloud, bang or hexagon, about (x, y) *)
PROCEDURE Outline(n: H.Node; x, y: LONGREAL);
  VAR w, h, p, m, r1, r2, r3, r4, ew, eh, r: LONGREAL;
BEGIN
  nq := 0; p := d.padding; w := lw[n.index]; h := lh[n.index];
  IF n.shape = H.Hexagon THEN
    h := h + 2 * p; m := h / 4; w := w + 2 * m + 2 * p;
    x := x - w / 2; y := y + h / 2;
    Pt(x + m, y); Pt(x + w - m, y); Pt(x + w, y - h / 2);
    Pt(x + w - m, y - h); Pt(x + m, y - h); Pt(x, y - h / 2)
  ELSIF n.shape = H.Cloud THEN
    w := w + p; h := h + p;
    r1 := 0.15D0 * w; r2 := 0.25D0 * w; r3 := 0.35D0 * w; r4 := 0.2D0 * w;
    Pt(x - w / 2, y - h / 2);
    Arc(r1, r1, 0, FALSE, TRUE, 0.25D0 * w, -0.1D0 * w);
    Arc(r3, r3, 1, FALSE, TRUE, 0.4D0 * w, -0.1D0 * w);
    Arc(r2, r2, 1, FALSE, TRUE, 0.35D0 * w, 0.2D0 * w);
    Arc(r1, r1, 1, FALSE, TRUE, 0.15D0 * w, 0.35D0 * h);
    Arc(r4, r4, 1, FALSE, TRUE, -0.15D0 * w, 0.65D0 * h);
    Arc(r2, r1, 1, FALSE, TRUE, -0.25D0 * w, 0.15D0 * w);
    Arc(r3, r3, 1, FALSE, TRUE, -0.5D0 * w, 0);
    Arc(r1, r1, 1, FALSE, TRUE, -0.25D0 * w, -0.15D0 * w);
    Arc(r1, r1, 1, FALSE, TRUE, -0.1D0 * w, -0.35D0 * h);
    Arc(r4, r4, 1, FALSE, TRUE, 0.1D0 * w, -0.65D0 * h)
  ELSIF n.shape = H.Bang THEN
    w := w + 5 * p; h := h + 4 * p;
    ew := Max(w, lw[n.index] + 20); eh := Max(h, lh[n.index] + 20); r := 0.15D0 * w;
    Pt(x - ew / 2, y - eh / 2);
    Arc(r, r, 1, FALSE, FALSE, 0.25D0 * ew, -0.1D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, 0.25D0 * ew, 0);
    Arc(r, r, 1, FALSE, FALSE, 0.25D0 * ew, 0);
    Arc(r, r, 1, FALSE, FALSE, 0.25D0 * ew, 0.1D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, 0.15D0 * ew, 0.33D0 * eh);
    Arc(0.8D0 * r, 0.8D0 * r, 1, FALSE, FALSE, 0, 0.34D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, -0.15D0 * ew, 0.33D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, -0.25D0 * ew, 0.15D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, -0.25D0 * ew, 0);
    Arc(r, r, 1, FALSE, FALSE, -0.25D0 * ew, 0);
    Arc(r, r, 1, FALSE, FALSE, -0.25D0 * ew, -0.15D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, -0.1D0 * ew, -0.33D0 * eh);
    Arc(0.8D0 * r, 0.8D0 * r, 1, FALSE, FALSE, 0, -0.34D0 * eh);
    Arc(r, r, 1, FALSE, FALSE, 0.1D0 * ew, -0.33D0 * eh)
  END;
  (* an outline closed back at its start is drawn without its last point *)
  IF (nq > 1) & (ABS(qx[nq - 1] - qx[0]) < 1.0D-6) & (ABS(qy[nq - 1] - qy[0]) < 1.0D-6) THEN
    DEC(nq)
  END
END Outline;

(* Sizes *)

(* n's box, w by h, or its circle's diameter *)
PROCEDURE Box(n: H.Node; VAR w, h: LONGREAL);
  VAR bw, bh, p: LONGREAL;
BEGIN
  bw := lw[n.index]; bh := lh[n.index]; p := d.padding;
  CASE n.shape OF
    H.Default: w := bw + 4 * p; h := bh + p
  | H.Rect: w := bw + 40; h := bh + 20
  | H.Rounded: w := bw + 30; h := bh + 30
  | H.Circle: w := MathL.sqrt(bw * bw + bh * bh) + 20; h := w
  ELSE w := 0; h := 0
  END
END Box;

PROCEDURE Measure(n: H.Node);
  VAR k: LONGINT; w, h, x0, x1, y0, y1: LONGREAL; i: INTEGER;
BEGIN
  k := n.index;
  lab[k] := FL.Wrap(l.font, n.label, Size * l.px, SHORT(d.maxNodeWidth * l.px));
  D.Measure(l, lab[k], Size, lw[k], lh[k]);
  IF (n.shape = H.Cloud) OR (n.shape = H.Bang) OR (n.shape = H.Hexagon) THEN
    Outline(n, 0, 0);
    x0 := 0; x1 := 0; y0 := 0; y1 := 0;
    FOR i := 0 TO nq - 1 DO
      IF qx[i] < x0 THEN x0 := qx[i] END; IF qx[i] > x1 THEN x1 := qx[i] END;
      IF qy[i] < y0 THEN y0 := qy[i] END; IF qy[i] > y1 THEN y1 := qy[i] END
    END;
    hw[k] := Max(-x0, x1); hh[k] := Max(-y0, y1)
  ELSE Box(n, w, h); hw[k] := w / 2; hh[k] := h / 2
  END
END Measure;

(* Places *)

(* The band of n's subtree, its height *)
PROCEDURE Band(n: H.Node): LONGREAL;
  VAR c: H.Node; s: LONGREAL;
BEGIN
  Measure(n);
  s := 0; c := n.children;
  WHILE c # NIL DO
    s := s + Band(c);
    IF c.next # NIL THEN s := s + Gap END;
    c := c.next
  END;
  band[n.index] := Max(2 * hh[n.index], s);
  RETURN band[n.index]
END Band;

(* The children of n, those on side (-1 left, 1 right; 0 for both),
   placed in a column step from n's side, about y *)
PROCEDURE PlaceChildren(n: H.Node; side, which: INTEGER; step, y: LONGREAL);
  VAR c: H.Node; s, top: LONGREAL; k: LONGINT;

  PROCEDURE Takes(k: LONGINT): BOOLEAN;
  BEGIN
    RETURN (which = 0) OR (which = -1) & ~ODD(k) OR (which = 1) & ODD(k)
  END Takes;

  PROCEDURE Place(c: H.Node; x, y: LONGREAL);
  BEGIN
    nx[c.index] := x; ny[c.index] := y;
    PlaceChildren(c, side, 0, Step, y)
  END Place;

BEGIN
  s := 0; c := n.children; k := 0;
  WHILE c # NIL DO
    IF Takes(k) THEN
      IF s > 0 THEN s := s + Gap END;
      s := s + band[c.index]
    END;
    c := c.next; INC(k)
  END;
  top := y - s / 2; c := n.children; k := 0;
  WHILE c # NIL DO
    IF Takes(k) THEN
      Place(c, nx[n.index] + side * (hw[n.index] + step + hw[c.index]), top + band[c.index] / 2);
      top := top + band[c.index] + Gap
    END;
    c := c.next; INC(k)
  END
END PlaceChildren;

(* Drawing *)

(* An edge's width, as its depth's class sets it *)
PROCEDURE EdgeWidth(n: H.Node): LONGREAL;
  VAR w: LONGINT;
BEGIN
  w := 14 - 3 * (n.level + 1);
  IF (w < 1) OR (n.level + 1 > 11) THEN w := 3 END;
  RETURN w
END EdgeWidth;

PROCEDURE Edges(n: H.Node);
  VAR c: H.Node; x0, y0, x1, y1, xm: LONGREAL;
BEGIN
  c := n.children;
  WHILE c # NIL DO
    x0 := nx[n.index]; y0 := ny[n.index]; x1 := nx[c.index]; y1 := ny[c.index];
    xm := (x0 + x1) / 2;
    D.MoveTo(x0, y0); D.CurveTo(xm, y0, xm, y1, x1, y1);
    D.AddPath(l, tl.scale[c.section + 1], EdgeWidth(n));
    Edges(c);
    c := c.next
  END
END Edges;

PROCEDURE Nodes(n: H.Node);
  VAR c: H.Node; k: LONGINT; x, y, w, h: LONGREAL; fill, text, line: LONGINT;
BEGIN
  k := n.index; x := nx[k]; y := ny[k];
  IF n.parent = NIL THEN fill := gt.git[0]; text := gt.label[0]; line := tl.inv[0]
  ELSE fill := tl.scale[n.section + 1]; text := tl.label[n.section + 1]; line := tl.inv[n.section + 1]
  END;
  CASE n.shape OF
    H.Default:
      Box(n, w, h);
      D.AddRect(l, x - w / 2, y - h / 2, w, h, 5, fill, -1, 0);
      D.AddLine(l, x - w / 2, y + h / 2, x + w / 2, y + h / 2, line, 3, 0)
  | H.Rect:
      Box(n, w, h); D.AddRect(l, x - w / 2, y - h / 2, w, h, 0, fill, -1, 0)
  | H.Rounded:
      Box(n, w, h); D.AddRect(l, x - w / 2, y - h / 2, w, h, 5, fill, -1, 0)
  | H.Circle:
      D.AddCircle(l, x, y, hw[k], fill, -1, 0)
  ELSE
    Outline(n, x, y); D.AddPoly(l, qx, qy, nq, fill, -1, 0)
  END;
  D.AddText(l, lab[k], x, y, Size, 0, text);
  c := n.children;
  WHILE c # NIL DO Nodes(c); c := c.next END
END Nodes;

(* Lays d out, its text set in font, the drawing at size points, into lay *)
PROCEDURE Make*(dg: H.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR r: H.Node; dummy: LONGREAL;
BEGIN
  d := dg;
  NEW(l); lay := l; l.d := d; D.Init(l, d.g, font, size);
  S.Reset(d.g, l.px);
  S.TimelineColours(tl); S.GitColours(gt);
  NEW(lab, d.nNodes);
  NEW(lw, d.nNodes); NEW(lh, d.nNodes); NEW(hw, d.nNodes); NEW(hh, d.nNodes);
  NEW(band, d.nNodes); NEW(nx, d.nNodes); NEW(ny, d.nNodes);
  r := d.root;
  dummy := Band(r);
  nx[r.index] := 0; ny[r.index] := 0;
  PlaceChildren(r, -1, -1, RootStep, 0);
  PlaceChildren(r, 1, 1, RootStep, 0);
  Edges(r);
  Nodes(r);
  D.Finish(l, d.padding);
  d := NIL; lab := NIL; lw := NIL; lh := NIL; hw := NIL; hh := NIL; band := NIL; nx := NIL; ny := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: H.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
  VAR k: INTEGER;
BEGIN
  Make(d, font, size, lay); k := 0;
  WHILE (maxW > 0) & (lay.width > maxW) & (k < 5) & (size > 0.2D0) DO
    size := ENTIER(size * maxW / lay.width * 10) / 10;
    IF size >= lay.size THEN size := lay.size - 0.1 END;
    IF size < 0.1 THEN size := 0.1 END;
    Make(d, font, size, lay); INC(k)
  END
END Fit;

END PmMindmapLayout.
