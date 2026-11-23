MODULE PmDraw;
(* PmDraw: a drawing as a list of items, for the diagrams laid out in
   Mermaid's pixels and written by PmDrawPic, PmDrawMp and PmDrawDump:
   circles, boxes, polygons, lines, curves and texts. A layout extends
   Drawing; Init starts it, the Add procedures add its items, in
   drawing order, in pixels, and Finish bounds it and moves it to
   start at (0, 0).

   Lengths are in points, y down; a pixel is the drawing's size over
   16. A text's (x, y) is its middle, before it is turned. Each place
   and size is rounded once, as it is made, to a 1/8192 point
   (Snap). *)

IMPORT MathL, M := PmMetrics, F := PmFlow, G := PmGeom;

CONST
  MermaidSize* = 16;
  Kappa* = 0.5522847498D0;      (* a quarter circle's Bézier *)
  MaxPath = 256;
  (* items *)
  Circle* = 0; Rect* = 1; Poly* = 2; Line* = 3; Curve* = 4; Text* = 5;

TYPE
  (* A circle: centre (x, y), radius r;
     a rectangle: (x, y) its top left corner, w by h, its corners
     rounded to r;
     a polygon: p[0 .. n-1];
     a line: from p[0] to p[1], dashed dash on and off, if dash > 0;
     a curve: Béziers, p[0], then 3 points each, its control points
     and its end, n points in all, with round caps;
     a text: lab, size points, its middle (x, y), w by h, turned
     angle degrees, clockwise, in colour line; if fit, set no wider
     than w where the writer measures text itself (ConTeXt).
     Each is filled with fill and outlined with line width wide; -1 is
     neither *)
  Item* = POINTER TO ItemDesc;
  ItemDesc* = RECORD
    kind-: INTEGER;
    x-, y-, w-, h-, r-: REAL;
    p-: G.Points; n-: INTEGER;
    fill-, line-: LONGINT;
    width-, dash-: REAL;
    lab-: F.Label;
    size-, angle-: REAL;
    fit-: BOOLEAN;
    next-: Item
  END;

  Drawing* = POINTER TO DrawingDesc;
  DrawingDesc* = RECORD
    g-: F.Graph;
    font-: M.Font;
    size-, vs-, px-: REAL;      (* the drawing's size, line spacing, a pixel *)
    width-, height-: REAL;
    items-: Item;               (* in drawing order *)
    last: Item;
    pixel: LONGREAL
  END;

VAR
  (* the bounds, from Bounds, in points *)
  minX*, minY*, maxX*, maxY*: LONGREAL;
  (* the path being made, in pixels *)
  qx, qy: ARRAY MaxPath OF LONGREAL; nq: INTEGER;

(* x rounded to a 1/8192 point *)
PROCEDURE Snap*(x: LONGREAL): REAL;
BEGIN
  IF ABS(x) < 2048 THEN RETURN SHORT(ENTIER(x * 8192 + 0.5D0) / 8192.0D0) END;
  RETURN SHORT(x)
END Snap;

(* Starts d, empty, for g, its text set in font, at size points *)
PROCEDURE Init*(d: Drawing; g: F.Graph; font: M.Font; size: REAL);
BEGIN
  d.g := g; d.font := font; d.size := size; d.vs := size * 1.2;
  d.pixel := size / MermaidSize; d.px := SHORT(d.pixel);
  d.width := 0; d.height := 0; d.items := NIL; d.last := NIL
END Init;

(* x pixels in points, snapped *)
PROCEDURE P*(d: Drawing; x: LONGREAL): REAL;
BEGIN
  RETURN Snap(x * d.pixel)
END P;

(* Items *)

PROCEDURE NewItem(d: Drawing; kind: INTEGER; fill, line: LONGINT; width: LONGREAL): Item;
  VAR it: Item;
BEGIN
  NEW(it); it.kind := kind; it.p := NIL; it.n := 0;
  it.fill := fill; it.line := line;
  IF line < 0 THEN it.width := 0 ELSE it.width := P(d, width) END;
  it.dash := 0; it.lab := NIL; it.size := 0; it.angle := 0; it.fit := FALSE;
  it.x := 0; it.y := 0; it.w := 0; it.h := 0; it.r := 0;
  it.next := NIL;
  IF d.last = NIL THEN d.items := it ELSE d.last.next := it END;
  d.last := it;
  RETURN it
END NewItem;

(* The circle at (x, y), radius r, filled with fill, outlined with line
   width wide; -1 is neither; in pixels *)
PROCEDURE AddCircle*(d: Drawing; x, y, r: LONGREAL; fill, line: LONGINT; width: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(d, Circle, fill, line, width);
  it.x := P(d, x); it.y := P(d, y); it.r := P(d, r)
END AddCircle;

(* The box from (x, y), w by h, its corners rounded to r *)
PROCEDURE AddRect*(d: Drawing; x, y, w, h, r: LONGREAL; fill, line: LONGINT; width: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(d, Rect, fill, line, width);
  it.x := P(d, x); it.y := P(d, y); it.w := P(d, w); it.h := P(d, h); it.r := P(d, r)
END AddRect;

(* The line from (x0, y0) to (x1, y1), dashed dash on and off if
   dash > 0 *)
PROCEDURE AddLine*(d: Drawing; x0, y0, x1, y1: LONGREAL; line: LONGINT; width, dash: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(d, Line, -1, line, width);
  it.p := G.NewPoints(2); it.n := 2;
  G.Set(it.p[0], P(d, x0), P(d, y0)); G.Set(it.p[1], P(d, x1), P(d, y1));
  it.dash := P(d, dash)
END AddLine;

(* The polygon (x[k], y[k]), k < n *)
PROCEDURE AddPoly*(d: Drawing; VAR x, y: ARRAY OF LONGREAL; n: INTEGER; fill, line: LONGINT;
  width: LONGREAL);
  VAR it: Item; k: INTEGER;
BEGIN
  it := NewItem(d, Poly, fill, line, width);
  it.p := G.NewPoints(n); it.n := n;
  FOR k := 0 TO n - 1 DO G.Set(it.p[k], P(d, x[k]), P(d, y[k])) END
END AddPoly;

(* lab's width and height, in pixels, at size pixels *)
PROCEDURE Measure*(d: Drawing; lab: F.Label; size: LONGREAL; VAR w, h: LONGREAL);
  VAR rw, rh: REAL;
BEGIN
  M.LabelSize(d.font, lab, SHORT(size * d.pixel), SHORT(size * d.pixel * 1.2D0), rw, rh);
  w := rw / d.pixel; h := rh / d.pixel
END Measure;

(* lab, size pixels, its middle (x, y), turned angle degrees, in colour *)
PROCEDURE AddText*(d: Drawing; lab: F.Label; x, y, size, angle: LONGREAL; colour: LONGINT);
  VAR it: Item;
BEGIN
  IF lab.n = 0 THEN RETURN END;
  it := NewItem(d, Text, -1, colour, 0);
  it.lab := lab; it.size := SHORT(size * d.pixel); it.angle := SHORT(angle);
  M.LabelSize(d.font, lab, it.size, it.size * 1.2, it.w, it.h);
  it.x := P(d, x); it.y := P(d, y)
END AddText;

(* As AddText, but the text is set no wider than pomermaid measures it,
   for a box that does not grow to fit it (the writers that measure
   text themselves shrink it) *)
PROCEDURE AddFittedText*(d: Drawing; lab: F.Label; x, y, size, angle: LONGREAL; colour: LONGINT);
BEGIN
  IF lab.n = 0 THEN RETURN END;
  AddText(d, lab, x, y, size, angle, colour);
  d.last.fit := TRUE
END AddFittedText;

(* Paths, in pixels *)

(* Starts a path at (x, y) *)
PROCEDURE MoveTo*(x, y: LONGREAL);
BEGIN
  qx[0] := x; qy[0] := y; nq := 1
END MoveTo;

PROCEDURE Put(x, y: LONGREAL);
BEGIN
  IF nq < MaxPath THEN qx[nq] := x; qy[nq] := y; INC(nq) END
END Put;

(* A line to (x, y) *)
PROCEDURE LineTo*(x, y: LONGREAL);
BEGIN
  Put(qx[nq - 1], qy[nq - 1]); Put(x, y); Put(x, y)
END LineTo;

(* A Bézier to (x, y), its control points (x1, y1) and (x2, y2) *)
PROCEDURE CurveTo*(x1, y1, x2, y2, x, y: LONGREAL);
BEGIN
  Put(x1, y1); Put(x2, y2); Put(x, y)
END CurveTo;

(* The quarter circle to (x, y), clockwise if sweep, as SVG's arc with
   sweep-flag sweep *)
PROCEDURE ArcTo*(sweep: BOOLEAN; x, y: LONGREAL);
  VAR ax, ay, ox, oy: LONGREAL;
BEGIN
  ax := qx[nq - 1]; ay := qy[nq - 1];
  (* the centre: (ax, y) turns clockwise when (y - ay) (x - ax) > 0 *)
  IF ((y - ay) * (x - ax) > 0) = sweep THEN ox := ax; oy := y ELSE ox := x; oy := ay END;
  Put(ax + Kappa * (x - ox), ay + Kappa * (y - oy));
  Put(x + Kappa * (ax - ox), y + Kappa * (ay - oy));
  Put(x, y)
END ArcTo;

(* The path made, a curve, in colour, width pixels wide *)
PROCEDURE AddPath*(d: Drawing; colour: LONGINT; width: LONGREAL);
  VAR it: Item; k: INTEGER;
BEGIN
  it := NewItem(d, Curve, -1, colour, width);
  it.p := G.NewPoints(nq); it.n := nq;
  FOR k := 0 TO nq - 1 DO G.Set(it.p[k], P(d, qx[k]), P(d, qy[k])) END
END AddPath;

(* The last item made dashed, its dashes dash pixels long *)
PROCEDURE Dash*(d: Drawing; dash: LONGREAL);
BEGIN
  d.last.dash := P(d, dash)
END Dash;

(* Bounds *)

PROCEDURE Bound(x0, y0, x1, y1: LONGREAL);
BEGIN
  IF x0 < minX THEN minX := x0 END;
  IF y0 < minY THEN minY := y0 END;
  IF x1 > maxX THEN maxX := x1 END;
  IF y1 > maxY THEN maxY := y1 END
END Bound;

PROCEDURE BoundItem(it: Item);
  VAR k: INTEGER; c, s, u, v: LONGREAL;
BEGIN
  IF it.kind = Circle THEN Bound(it.x - it.r, it.y - it.r, it.x + it.r, it.y + it.r)
  ELSIF it.kind = Rect THEN Bound(it.x, it.y, it.x + it.w, it.y + it.h)
  ELSIF it.kind = Text THEN
    c := MathL.cos(it.angle * MathL.pi / 180); s := MathL.sin(it.angle * MathL.pi / 180);
    FOR k := 0 TO 3 DO
      IF k MOD 2 = 0 THEN u := -it.w / 2 ELSE u := it.w / 2 END;
      IF k < 2 THEN v := -it.h / 2 ELSE v := it.h / 2 END;
      Bound(it.x + u * c - v * s, it.y + u * s + v * c, it.x + u * c - v * s, it.y + u * s + v * c)
    END
  ELSE
    FOR k := 0 TO it.n - 1 DO Bound(it.p[k].x, it.p[k].y, it.p[k].x, it.p[k].y) END
  END
END BoundItem;

(* Sets minX, minY, maxX and maxY to the bounds of d's items, in
   points, without the lines' widths; a turned text's are its turned
   box's *)
PROCEDURE Bounds*(d: Drawing);
  VAR it: Item;
BEGIN
  it := d.items;
  IF it # NIL THEN
    minX := MAX(REAL); minY := MAX(REAL); maxX := -MAX(REAL); maxY := -MAX(REAL)
  ELSE minX := 0; minY := 0; maxX := 0; maxY := 0
  END;
  WHILE it # NIL DO BoundItem(it); it := it.next END
END Bounds;

PROCEDURE Move(it: Item; dx, dy: LONGREAL);
  VAR k: INTEGER;
BEGIN
  FOR k := 0 TO it.n - 1 DO G.Set(it.p[k], Snap(it.p[k].x + dx), Snap(it.p[k].y + dy)) END;
  it.x := Snap(it.x + dx); it.y := Snap(it.y + dy)
END Move;

(* Bounds d, widened by pad pixels on each side, sets its width and
   height, and moves its items for the bounds to start at (0, 0) *)
PROCEDURE Finish*(d: Drawing; pad: LONGREAL);
  VAR it: Item; ddx, ddy: LONGREAL;
BEGIN
  Bounds(d);
  pad := pad * d.pixel;
  ddx := pad - minX; ddy := pad - minY;
  d.width := Snap(maxX - minX + 2 * pad); d.height := Snap(maxY - minY + 2 * pad);
  it := d.items;
  WHILE it # NIL DO Move(it, ddx, ddy); it := it.next END
END Finish;

END PmDraw.
