MODULE PmBlockLayout;
(* PmBlockLayout: a block diagram, PmBlock's, laid out in Mermaid's
   pixels, the drawing's size taken as 16 pixels, and drawn as Mermaid
   12.3.0 draws it (blockRenderer.ts, layout.ts, renderHelpers.ts and
   the shapes). Lengths are in points, y down.

   - Each block's natural size is its shape's, drawn round its label,
     16 pixels, with padding (config.block.padding, 8): a box is 4
     paddings wider than its label and 2 higher; a composite block is
     its label's size, none if it has no label.
   - Then, as layout.ts's setBlockSizes, from the root down: every
     child is made as wide as the widest, by columns, and as high as
     the highest, spaces apart; a block with children is as wide as
     its columns of children and as high as their rows, with padding
     between them and round them; one smaller than its siblings is
     made theirs, its children shrunk to fit.
   - layoutBlocks places the children in rows of the block's columns,
     all in one row if they are auto, a block that would overflow its
     row cut short; each row as high as its highest child.
   - Each block is drawn in its shape, at its place: boxes, composite
     blocks, hexagons, the leaning shapes, trapezoids, the arrow box
     and subroutines grow to fill their cells; circles, diamonds and
     stadiums keep their natural sizes; a double circle is its cell's
     width and 2 paddings wide inside, and 5 more outside; a block
     arrow grows only if it spans columns. Composite blocks are drawn
     before their children; spaces are not drawn.
   - An edge is a line from its start's middle to its end's, cut where
     it leaves each shape's outline, 2 pixels wide in lineColor, 3.5
     if thick, dashed 3 if dotted, with an arrowhead (8 pixels long,
     8 wide), a circle (5.5 radius) or a cross at either end; its
     label is on the edge labels' background at the line's middle.

   The bounds are every item's, widened by 5 on each side. *)

IMPORT MathL, M := PmMetrics, F := PmFlow, S := PmStyle, B := PmBlock, D := PmDraw, G := PmGeom;

CONST
  Size = 16;            (* the labels', in pixels *)
  Gap = 5;              (* a double circle's *)
  MaxPts = 128;
  Steps = 16;           (* the lines a stadium's or a cylinder's half arc is drawn with *)
  ArrowLen = 8; ArrowHalf = 4; MarkR = 5.5D0;
  (* the outlines *)
  kRect = 0; kCircle = 1; kDouble = 2; kPoly = 3; kStadium = 4; kSub = 5; kCylinder = 6;

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: B.Diagram
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;
  Flags = POINTER TO ARRAY OF BOOLEAN;

VAR
  l: Layout;
  d: B.Diagram;
  pad: LONGREAL;
  (* a block's shape, from Shape, about its middle (0, 0) *)
  kind: INTEGER;
  qx, qy: ARRAY MaxPts OF LONGREAL; nq: INTEGER;  (* a polygon *)
  rw, rh, rr: LONGREAL;      (* a box or a stadium: w by h, its corners r *)
  cr, inner: LONGREAL;       (* a circle's radius; a double circle's inner one *)
  sw: LONGREAL;              (* a subroutine's inner width *)
  cw, ch, cry: LONGREAL;     (* a cylinder: w, its body's h, its ellipses' ry *)
  tx, ty: LONGREAL;          (* the label's middle *)
  lw, lh: LONGREAL;          (* the label's size *)
  bx0, by0, bx1, by1: LONGREAL;  (* the shape's and its label's bounds *)

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a END;
  RETURN b
END Min;

PROCEDURE Pt(x, y: LONGREAL);
BEGIN
  IF nq < MaxPts THEN qx[nq] := x; qy[nq] := y; INC(nq) END
END Pt;

(* Moves the polygon by (dx, dy) *)
PROCEDURE Shift(dx, dy: LONGREAL);
  VAR k: INTEGER;
BEGIN
  FOR k := 0 TO nq - 1 DO qx[k] := qx[k] + dx; qy[k] := qy[k] + dy END
END Shift;

(* The half arc of the ellipse about (x, y), radii a and b, from angle
   t0 to t1 degrees, y down, its first point left out *)
PROCEDURE Arc(x, y, a, b, t0, t1: LONGREAL);
  VAR k: INTEGER; t: LONGREAL;
BEGIN
  FOR k := 1 TO Steps DO
    t := (t0 + (t1 - t0) * k / Steps) * MathL.pi / 180;
    Pt(x + a * MathL.cos(t), y + b * MathL.sin(t))
  END
END Arc;

(* A block arrow's polygon, from blockArrow.ts's getArrowPoints *)
PROCEDURE ArrowPoints(dirs: SET; w, h, m, p: LONGREAL);
  VAR r, lf, u, dn: BOOLEAN;
BEGIN
  r := B.Right IN dirs; lf := B.Left IN dirs; u := B.Up IN dirs; dn := B.Down IN dirs;
  nq := 0;
  IF r & lf & u & dn THEN
    Pt(0, 0); Pt(m, 0); Pt(w / 2, 2 * p); Pt(w - m, 0); Pt(w, 0); Pt(w, -h / 3);
    Pt(w + 2 * p, -h / 2); Pt(w, -2 * h / 3); Pt(w, -h); Pt(w - m, -h); Pt(w / 2, -h - 2 * p);
    Pt(m, -h); Pt(0, -h); Pt(0, -2 * h / 3); Pt(-2 * p, -h / 2); Pt(0, -h / 3)
  ELSIF r & lf & u THEN
    Pt(m, 0); Pt(w - m, 0); Pt(w, -h / 2); Pt(w - m, -h); Pt(m, -h); Pt(0, -h / 2)
  ELSIF r & lf & dn THEN
    Pt(0, 0); Pt(m, -h); Pt(w - m, -h); Pt(w, 0)
  ELSIF r & u & dn THEN
    Pt(0, 0); Pt(w, -m); Pt(w, -h + m); Pt(0, -h)
  ELSIF lf & u & dn THEN
    Pt(w, 0); Pt(0, -m); Pt(0, -h + m); Pt(w, -h)
  ELSIF r & lf THEN
    Pt(m, 0); Pt(m, -p); Pt(w - m, -p); Pt(w - m, 0); Pt(w, -h / 2); Pt(w - m, -h);
    Pt(w - m, -h + p); Pt(m, -h + p); Pt(m, -h); Pt(0, -h / 2)
  ELSIF u & dn THEN
    Pt(w / 2, 0); Pt(0, -p); Pt(m, -p); Pt(m, -h + p); Pt(0, -h + p); Pt(w / 2, -h);
    Pt(w, -h + p); Pt(w - m, -h + p); Pt(w - m, -p); Pt(w, -p)
  ELSIF r & u THEN
    Pt(0, 0); Pt(w, -m); Pt(0, -h)
  ELSIF r & dn THEN
    Pt(0, 0); Pt(w, 0); Pt(0, -h)
  ELSIF lf & u THEN
    Pt(w, 0); Pt(0, -m); Pt(w, -h)
  ELSIF lf & dn THEN
    Pt(w, 0); Pt(0, 0); Pt(w, -h)
  ELSIF r THEN
    Pt(m, -p); Pt(m, -p); Pt(w - m, -p); Pt(w - m, 0); Pt(w, -h / 2); Pt(w - m, -h);
    Pt(w - m, -h + p); Pt(m, -h + p); Pt(m, -h + p)
  ELSIF lf THEN
    Pt(m, 0); Pt(m, -p); Pt(w - m, -p); Pt(w - m, -h + p); Pt(m, -h + p); Pt(m, -h); Pt(0, -h / 2)
  ELSIF u THEN
    Pt(m, -p); Pt(m, -h + p); Pt(0, -h + p); Pt(w / 2, -h); Pt(w, -h + p); Pt(w - m, -h + p);
    Pt(w - m, -p)
  ELSIF dn THEN
    Pt(w / 2, 0); Pt(0, -p); Pt(m, -p); Pt(m, -h + p); Pt(w - m, -h + p); Pt(w - m, -p); Pt(w, -p)
  ELSE Pt(0, 0)
  END
END ArrowPoints;

(* b's label's size, lw by lh *)
PROCEDURE LabelSize(b: B.Block);
BEGIN
  IF (b.label = NIL) OR (b.label.n = 0) THEN lw := 0; lh := 0
  ELSE
    D.Measure(l, b.label, Size, lw, lh);
    IF lw = 0 THEN lh := 0 END  (* a composite block's empty label *)
  END
END LabelSize;

(* b's shape, about (0, 0), in a cell w by h, or its natural shape if
   not positioned, as Mermaid's shapes draw it, and its bounds *)
PROCEDURE Shape(b: B.Block; w, h: LONGREAL; positioned: BOOLEAN);
  VAR p, s, m, x, y, notch, ry0, nw, nh, aw, ah, inscribed, cap: LONGREAL; k: INTEGER;
BEGIN
  LabelSize(b);
  p := pad; tx := 0; ty := 0; nq := 0; rr := 0;
  IF ~positioned THEN w := 0; h := 0 END;
  CASE b.type OF
  | B.Composite:
    kind := kRect;
    IF positioned THEN rw := w; rh := h ELSE rw := lw; rh := lh END
  | B.Circle:
    kind := kCircle; cr := MathL.sqrt(lw * lw + lh * lh) / 2 + p / 2
  | B.DoubleCircle:
    kind := kDouble;
    IF w > 0 THEN inner := w / 2 + p ELSE inner := MathL.sqrt(lw * lw + lh * lh) / 2 + p END;
    cr := inner + Gap
  | B.Diamond:
    kind := kPoly; s := (lw + p) + (lh + p);
    Pt(s / 2, 0); Pt(s, -s / 2); Pt(s / 2, -s); Pt(0, -s / 2);
    Shift(-s / 2 + 0.5D0, s / 2)
  | B.Hexagon:
    kind := kPoly;
    IF w = 0 THEN h := lh + p; w := lw + 2 * (h / 4) + p END;
    m := h / 4;
    Pt(m, 0); Pt(w - m, 0); Pt(w, -h / 2); Pt(w - m, -h); Pt(m, -h); Pt(0, -h / 2);
    Shift(-w / 2, h / 2)
  | B.LeanRight, B.LeanLeft, B.Trapezoid, B.InvTrapezoid:
    kind := kPoly;
    IF b.type = B.InvTrapezoid THEN nh := Max(lh + 2 * p, h); nw := Max(lw + 2 * p, w - nh)
    ELSE nh := Max(lh + p, h); nw := Max(lw + p, w - nh)
    END;
    IF b.type = B.LeanRight THEN Pt(-nh / 2, 0); Pt(nw, 0); Pt(nw + nh / 2, -nh); Pt(0, -nh)
    ELSIF b.type = B.LeanLeft THEN Pt(0, 0); Pt(nw + nh / 2, 0); Pt(nw, -nh); Pt(-nh / 2, -nh)
    ELSIF b.type = B.Trapezoid THEN Pt(-nh / 2, 0); Pt(nw + nh / 2, 0); Pt(nw, -nh); Pt(0, -nh)
    ELSE Pt(0, 0); Pt(nw, 0); Pt(nw + nh / 2, -nh); Pt(-nh / 2, -nh)
    END;
    Shift(-nw / 2, nh / 2)
  | B.LeftArrow:
    kind := kPoly;
    nh := Max(lh + p, h); nw := Max(lw + p, w - nh / 4);
    x := -nw / 2; y := -nh / 2; notch := y / 2;
    Pt(x + notch, y); Pt(x, 0); Pt(x + notch, -y); Pt(-x, -y); Pt(-x, y);
    Shift(-notch / 2, 0); tx := -notch / 2
  | B.Stadium:
    kind := kStadium;
    rh := lh + p;
    inscribed := rh * MathL.cos(MathL.pi / (2 * 49));
    cap := MathL.sqrt(Max(0, inscribed * inscribed - lh * lh));
    rw := Max(Max(lw + rh / 4 + p, 1.5D0 * rh + (rh - inscribed)), lw + p + rh - cap);
    rr := rh / 2;
    (* the outline, for edges *)
    Pt(-rw / 2 + rr, -rh / 2); Pt(rw / 2 - rr, -rh / 2);
    Arc(rw / 2 - rr, 0, rr, rr, -90, 90);
    Pt(-rw / 2 + rr, rh / 2);
    Arc(-rw / 2 + rr, 0, rr, rr, 90, 270)
  | B.Subroutine:
    kind := kSub;
    rw := Max(lw + 16 + p, w); rh := Max(lh + p, h); sw := rw - 16
  | B.Cylinder:
    kind := kCylinder;
    nw := 0; nh := 0;
    IF w > 0 THEN
      nw := Max(w - p, 8);
      IF h > 0 THEN ry0 := (w / 2) / (2.5D0 + w / 50); nh := Max(h - p - 3 * ry0, 8) END
    END;
    cw := Max(nw, lw) + p;
    cry := (cw / 2) / (2.5D0 + cw / 50);
    ch := Max(nh, lh) + p + cry;
    ty := p / 1.5D0;
    (* the outline: the left side down, the bottom, the right side up, the top *)
    Pt(-cw / 2, -ch / 2);
    Pt(-cw / 2, ch / 2);
    Arc(0, ch / 2, cw / 2, cry, 180, 0);
    Pt(cw / 2, -ch / 2);
    Arc(0, -ch / 2, cw / 2, cry, 0, -180)
  | B.BlockArrow:
    kind := kPoly;
    ah := lh + 2 * p; m := ah / 2;
    aw := lw + 2 * m + p;
    IF positioned & (b.wic > 1) & (w > aw) THEN aw := w END;
    ArrowPoints(b.dirs, aw, ah, m, p / 2);
    Shift(-aw / 2, ah / 2)
  ELSE (* Na, Square, Round, Space *)
    kind := kRect; rw := Max(lw + 4 * p, w); rh := Max(lh + 2 * p, h);
    IF b.type = B.Round THEN rr := 5 END
  END;
  (* the bounds *)
  bx0 := tx - lw / 2; bx1 := tx + lw / 2; by0 := ty - lh / 2; by1 := ty + lh / 2;
  IF (kind = kRect) OR (kind = kSub) THEN
    bx0 := Min(bx0, -rw / 2); bx1 := Max(bx1, rw / 2); by0 := Min(by0, -rh / 2); by1 := Max(by1, rh / 2)
  ELSIF (kind = kCircle) OR (kind = kDouble) THEN
    bx0 := Min(bx0, -cr); bx1 := Max(bx1, cr); by0 := Min(by0, -cr); by1 := Max(by1, cr)
  ELSE
    FOR k := 0 TO nq - 1 DO
      bx0 := Min(bx0, qx[k]); bx1 := Max(bx1, qx[k]); by0 := Min(by0, qy[k]); by1 := Max(by1, qy[k])
    END
  END
END Shape;

(* The blocks' natural sizes, in b's tree *)
PROCEDURE Natural(b: B.Block);
  VAR c: B.Block;
BEGIN
  c := b.children;
  WHILE c # NIL DO
    IF c.type = B.Space THEN c.w := 0; c.h := 0
    ELSE Shape(c, 0, 0, FALSE); c.w := bx1 - bx0; c.h := by1 - by0
    END;
    c.x := 0; c.y := 0;
    Natural(c);
    c := c.next
  END
END Natural;

(* layout.ts's setBlockSizes *)
PROCEDURE Sizes(b: B.Block; sibW, sibH: LONGREAL);
  VAR c: B.Block; maxW, maxH, width, height, cwid, chei, nw: LONGREAL;
    numItems, xSize, ySize, num, cols: LONGINT;
BEGIN
  IF b.w = 0 THEN b.w := sibW; b.h := sibH; b.x := 0; b.y := 0 END;
  IF b.children # NIL THEN
    c := b.children;
    WHILE c # NIL DO Sizes(c, 0, 0); c := c.next END;
    maxW := 0; maxH := 0; c := b.children;
    WHILE c # NIL DO
      IF c.type # B.Space THEN
        nw := c.w / c.wic;
        IF nw > maxW THEN maxW := nw END;
        IF c.h > maxH THEN maxH := c.h END
      END;
      c := c.next
    END;
    c := b.children;
    WHILE c # NIL DO
      c.w := maxW * c.wic + pad * (c.wic - 1); c.h := maxH; c.x := 0; c.y := 0;
      c := c.next
    END;
    c := b.children;
    WHILE c # NIL DO Sizes(c, maxW, maxH); c := c.next END;
    cols := b.columns;
    numItems := 0; c := b.children;
    WHILE c # NIL DO numItems := numItems + c.wic; c := c.next END;
    xSize := b.nChildren;
    IF (cols > 0) & (cols < numItems) THEN xSize := cols END;
    ySize := (numItems + xSize - 1) DIV xSize;
    width := xSize * (maxW + pad) + pad;
    height := ySize * (maxH + pad) + pad;
    IF width < sibW THEN
      width := sibW; height := sibH;
      cwid := (sibW - xSize * pad - pad) / xSize;
      chei := (sibH - ySize * pad - pad) / ySize;
      c := b.children;
      WHILE c # NIL DO c.w := cwid; c.h := chei; c.x := 0; c.y := 0; c := c.next END
    END;
    IF width < b.w THEN
      width := b.w;
      IF cols > 0 THEN num := cols; IF b.nChildren < num THEN num := b.nChildren END
      ELSE num := b.nChildren
      END;
      IF num > 0 THEN
        cwid := (width - num * pad - pad) / num;
        c := b.children;
        WHILE c # NIL DO c.w := cwid; c := c.next END
      END
    END;
    b.w := width; b.h := height; b.x := 0; b.y := 0
  END
END Sizes;

(* layout.ts's calculateBlockPosition: the row of position pos *)
PROCEDURE Row(cols, pos: LONGINT): LONGINT;
BEGIN
  IF cols < 0 THEN RETURN 0
  ELSIF cols = 1 THEN RETURN pos
  END;
  RETURN pos DIV cols
END Row;

(* What a child, wic columns wide, at pos fills of its row *)
PROCEDURE Filled(cols, pos, wic: LONGINT): LONGINT;
BEGIN
  IF (cols > 0) & (wic > cols - pos MOD cols) THEN RETURN cols - pos MOD cols END;
  RETURN wic
END Filled;

(* layout.ts's layoutBlocks *)
PROCEDURE Place(b: B.Block);
  VAR c: B.Block; cols, pos, py, rowPos, n, k: LONGINT; startX, off, rowH: LONGREAL;
    heights, offsets: Reals; seen: Flags;
BEGIN
  IF b.children = NIL THEN RETURN END;
  cols := b.columns; n := b.nChildren + 1;
  NEW(heights, n); NEW(offsets, n); NEW(seen, n);
  FOR k := 0 TO n - 1 DO heights[k] := 0; offsets[k] := 0; seen[k] := FALSE END;
  pos := 0; c := b.children;
  WHILE c # NIL DO
    py := Row(cols, pos);
    seen[py] := TRUE;
    IF c.h > heights[py] THEN heights[py] := c.h END;
    pos := pos + Filled(cols, pos, c.wic);
    c := c.next
  END;
  off := 0;
  FOR k := 0 TO n - 1 DO
    IF seen[k] THEN offsets[k] := off; off := off + heights[k] + pad END
  END;
  (* as Mermaid, a block whose x is 0 starts its rows at -padding *)
  IF b.x # 0 THEN startX := b.x - b.w / 2 ELSE startX := -pad END;
  pos := 0; rowPos := 0; c := b.children;
  WHILE c # NIL DO
    py := Row(cols, pos);
    IF py # rowPos THEN
      rowPos := py;
      IF b.x # 0 THEN startX := b.x - b.w / 2 ELSE startX := -pad END
    END;
    c.x := startX + pad + c.w / 2;
    startX := c.x + c.w / 2;
    rowH := heights[py];
    c.y := b.y - b.h / 2 + offsets[py] + rowH / 2 + pad;
    Place(c);
    pos := pos + Filled(cols, pos, c.wic);
    c := c.next
  END
END Place;

PROCEDURE Rgb(c: INTEGER): LONGINT;
BEGIN
  IF c = S.NoColour THEN RETURN -1 END;
  RETURN S.Rgb(c)
END Rgb;

(* Draws the polygon, moved to (x, y) *)
PROCEDURE Poly(x, y: LONGREAL; fill, line: LONGINT; width: LONGREAL);
  VAR px, py: ARRAY MaxPts OF LONGREAL; k: INTEGER;
BEGIN
  FOR k := 0 TO nq - 1 DO px[k] := qx[k] + x; py[k] := qy[k] + y END;
  D.AddPoly(l, px, py, nq, fill, line, width)
END Poly;

(* Draws b, then its children *)
PROCEDURE Draw(b: B.Block);
  VAR c: B.Block; st: S.Style; fill, line: LONGINT; width: LONGREAL;
BEGIN
  c := b.children;
  WHILE c # NIL DO
    IF c.type # B.Space THEN
      Shape(c, c.w, c.h, TRUE);
      S.BlockStyle(d.g, c.type = B.Composite, c.classes, c.style, st);
      fill := Rgb(st.fill); line := Rgb(st.line); width := st.width / l.px;
      CASE kind OF
      | kRect, kStadium: D.AddRect(l, c.x - rw / 2, c.y - rh / 2, rw, rh, rr, fill, line, width)
      | kCircle: D.AddCircle(l, c.x, c.y, cr, fill, line, width)
      | kDouble:
        D.AddCircle(l, c.x, c.y, cr, fill, line, width);
        D.AddCircle(l, c.x, c.y, inner, fill, line, width)
      | kPoly: Poly(c.x, c.y, fill, line, width)
      | kSub:
        D.AddRect(l, c.x - rw / 2, c.y - rh / 2, rw, rh, 0, fill, line, width);
        IF line # -1 THEN
          D.AddLine(l, c.x - sw / 2, c.y - rh / 2, c.x - sw / 2, c.y + rh / 2, line, width, 0);
          D.AddLine(l, c.x + sw / 2, c.y - rh / 2, c.x + sw / 2, c.y + rh / 2, line, width, 0)
        END
      | kCylinder:
        Poly(c.x, c.y, fill, line, width);
        IF line # -1 THEN
          (* the top's near half *)
          D.MoveTo(c.x - cw / 2, c.y - ch / 2);
          D.ArcTo(FALSE, c.x, c.y - ch / 2 + cry);
          D.ArcTo(FALSE, c.x + cw / 2, c.y - ch / 2);
          D.AddPath(l, line, width)
        END
      END;
      IF lw > 0 THEN D.AddText(l, c.label, c.x + tx, c.y + ty, Size, 0, Rgb(st.text)) END
    END;
    Draw(c);
    c := c.next
  END
END Draw;

(* Where the line from b's middle towards (px, py) leaves its outline *)
PROCEDURE Cut(b: B.Block; px, py: LONGREAL; VAR x, y: LONGREAL);
  VAR poly: G.Points; k: INTEGER; rx, ry: REAL;
BEGIN
  x := b.x; y := b.y;
  IF b.type = B.Space THEN RETURN END;
  Shape(b, b.w, b.h, TRUE);
  IF (kind = kRect) OR (kind = kSub) THEN
    G.RectIntersect(SHORT(b.x), SHORT(b.y), SHORT(rw), SHORT(rh), SHORT(px), SHORT(py), rx, ry)
  ELSIF (kind = kCircle) OR (kind = kDouble) THEN
    G.EllipseIntersect(SHORT(b.x), SHORT(b.y), SHORT(cr), SHORT(cr), SHORT(px), SHORT(py), rx, ry)
  ELSE
    IF kind = kStadium THEN
      (* rw, rh and rr make the box; the outline is in the polygon *)
    END;
    poly := G.NewPoints(nq);
    FOR k := 0 TO nq - 1 DO G.Set(poly[k], SHORT(qx[k] + b.x), SHORT(qy[k] + b.y)) END;
    G.PolygonIntersect(SHORT(b.x), SHORT(b.y), poly^, nq, SHORT(px), SHORT(py), rx, ry)
  END;
  x := rx; y := ry
END Cut;

(* A marker of kind at (x, y), the line reaching it in direction
   (ux, uy); how far back the line must stop, in back *)
PROCEDURE Marker(kind: INTEGER; x, y, ux, uy: LONGREAL; line: LONGINT; width: LONGREAL; VAR back: LONGREAL);
  VAR px, py: ARRAY 3 OF LONGREAL; cx, cy, r: LONGREAL;
BEGIN
  back := 0;
  IF line = -1 THEN RETURN END;
  IF kind = F.Arrow THEN
    px[0] := x; py[0] := y;
    px[1] := x - ArrowLen * ux - ArrowHalf * uy; py[1] := y - ArrowLen * uy + ArrowHalf * ux;
    px[2] := x - ArrowLen * ux + ArrowHalf * uy; py[2] := y - ArrowLen * uy - ArrowHalf * ux;
    D.AddPoly(l, px, py, 3, line, line, 0);
    back := ArrowLen / 2
  ELSIF kind = F.CircleEnd THEN
    cx := x - MarkR * ux; cy := y - MarkR * uy;
    D.AddCircle(l, cx, cy, MarkR, line, line, 0);
    back := MarkR
  ELSIF kind = F.Cross THEN
    cx := x - MarkR * ux; cy := y - MarkR * uy; r := MarkR * 0.7D0;
    D.AddLine(l, cx - r, cy - r, cx + r, cy + r, line, width, 0);
    D.AddLine(l, cx - r, cy + r, cx + r, cy - r, line, width, 0);
    back := MarkR
  END
END Marker;

(* Draws the edges *)
PROCEDURE Edges;
  VAR e: B.Edge; st: S.Style; sx, sy, ex, ey, mx, my, ux, uy, len, b0, b1, width, w, h: LONGREAL;
    line: LONGINT;
BEGIN
  e := d.edges;
  WHILE e # NIL DO
    IF e.from.inTree & e.to.inTree THEN
      S.BlockEdgeStyle(e.thick, e.dotted, st);
      S.Apply(st, NIL);
      line := Rgb(st.line); width := st.width / l.px;
      mx := e.from.x + (e.to.x - e.from.x) / 2; my := e.from.y + (e.to.y - e.from.y) / 2;
      Cut(e.from, mx, my, sx, sy); Cut(e.to, mx, my, ex, ey);
      len := MathL.sqrt((ex - sx) * (ex - sx) + (ey - sy) * (ey - sy));
      IF len > 0 THEN
        ux := (ex - sx) / len; uy := (ey - sy) / len;
        Marker(e.endMark, ex, ey, ux, uy, line, width, b1);
        Marker(e.startMark, sx, sy, -ux, -uy, line, width, b0);
        IF (line # -1) & (b0 + b1 < len) THEN
          D.AddLine(l, sx + b0 * ux, sy + b0 * uy, ex - b1 * ux, ey - b1 * uy, line, width, st.dash / l.px)
        END
      END;
      IF (e.label # NIL) & (e.label.n > 0) THEN
        D.Measure(l, e.label, Size, w, h);
        IF S.LabelBackgroundRgb() # -1 THEN
          D.AddRect(l, mx - w / 2, my - h / 2, w, h, 0, S.LabelBackgroundRgb(), -1, 0)
        END;
        D.AddText(l, e.label, mx, my, Size, 0, Rgb(st.text))
      END
    END;
    e := e.next
  END
END Edges;

(* Lays d out, its text set in font, the drawing at size points, into lay *)
PROCEDURE Make*(dg: B.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
BEGIN
  d := dg; pad := d.padding;
  NEW(l); lay := l; l.d := d; D.Init(l, d.g, font, size);
  S.Reset(d.g, l.px);
  d.root.w := 0; d.root.h := 0; d.root.x := 0; d.root.y := 0;
  Natural(d.root);
  Sizes(d.root, 0, 0);
  Place(d.root);
  Draw(d.root);
  Edges;
  D.Finish(l, 5);
  d := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: B.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmBlockLayout.
