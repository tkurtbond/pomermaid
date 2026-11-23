MODULE PmRadarLayout;
(* PmRadarLayout: a radar chart, PmRadar's, laid out as Mermaid 12.3.0's
   radar renderer.ts lays it out, in its pixels, taken at the labels'
   size, 16 pixels to the size. Lengths are in points, y down; a text's
   y is its middle.

   The chart is width by height pixels in its margins; its centre is
   at (marginLeft + width/2, marginTop + height/2), and its radius is
   half the smaller of width and height. The axes, n of them, start at
   12 o'clock and go clockwise, the i-th at the angle 2 i pi / n. The
   drawing is a list of items, in Mermaid's order, but for the fills
   (decision 22):

   - the graticule: for ticks rings, the i-th of radius (i + 1)/ticks
     of the radius, circles, or polygons with a corner on each axis;
     from the largest in, each filled with graticuleColor at
     graticuleOpacity over the fill beneath it, white beneath the
     largest, and outlined in graticuleColor;
   - the axes: each a line from the centre axisScaleFactor of the
     radius long, and its label at axisLabelFactor of the radius and 4
     pixels further, anchored at its start, its end or its middle as
     the axis points right, left or up and down, and below, above or
     on its point as the axis points down, up or across;
   - the curves that have a value for each axis, each value v at
     (v - min)/(max - min) of the radius on its axis, v clipped to min
     and max; max is the option's, else the greatest value; closed
     Catmull-Rom curves through the points, with curveTension, for a
     circle graticule, else polygons; all the fills first, each the
     curve's colour at curveOpacity over white, then all the outlines,
     in the curve's colour; at an opacity of 0, there is no fill;
   - the legend: from ((width/2 + marginRight) 3/4,
     -(height/2 + marginTop) 3/4) from the centre, a row for each
     curve, 20 pixels apart, a 12 pixel square filled and outlined as
     the curve, and its label 16 pixels right, its top at the square's;
   - the title, its top at the drawing's top, centred over the centre,
     16 pixels.

   A curve's colour is cScale of its index, the 12 used in turn: in
   Mermaid, a curve after the 12th has no style and is black.

   Text the margins cannot hold widens the drawing (decision 19): its
   bounds are the chart's and every item's, and everything is moved for
   them to start at (0, 0).

   The arithmetic is LONGREAL, and each item's places and sizes are
   rounded once, as it is made, to a 1/8192 point (Snap), as
   PmXyLayout's are. *)

IMPORT MathL, M := PmMetrics, F := PmFlow, G := PmGeom, S := PmStyle, GP := PmGanttPic,
  R := PmRadar;

CONST
  MermaidSize* = 16;
  TitleSize = 16;       (* fontSize *)
  LabelPad = 4;
  LegendRow = 20;
  LegendBox = 12;
  LegendText = 16;
  Colours* = 12;
  White = 0FFFFFFH;
  (* items *)
  Shape* = 0; Line* = 1; Rect* = 2; Text* = 3;
  (* a shape's form *)
  Circle* = 0; Polygon* = 1; Curve* = 2;
  (* a text's anchor *)
  Start* = 0; Centre* = 1; End* = 2;
  (* a text's vertical position, Mermaid's dominant-baseline *)
  Central = 0; Hanging = 1; Auto = 2;

TYPE
  (* A shape: a circle, its centre (x, y) and radius r; a polygon, its
     corners p[0 .. n-1]; a closed curve, its points p[0 .. n-1], the
     Bézier from p[k] to p[k+1], the last to p[0], with the control
     points c1[k] and c2[k]; filled with fill and outlined with line,
     width wide (each 0RRGGBBH or -1 for none);
     a line: from p[0] to p[1], in line, width wide;
     a rectangle: (x, y) its top left corner, w by h, filled with fill
     and outlined with line, width wide;
     a text: lab, size points, its anchor point (x, y), on its middle
     line, where it starts, its middle or its end is, in colour line; w
     by h *)
  Item* = POINTER TO ItemDesc;
  ItemDesc* = RECORD
    kind-, form-: INTEGER;
    x-, y-, w-, h-, r-: REAL;
    p-, c1-, c2-: G.Points; n-: INTEGER;
    fill-, line-: LONGINT;
    width-: REAL;
    lab-: F.Label;
    size-: REAL;
    anchor-: INTEGER;
    next-: Item
  END;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: R.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;      (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    items-: Item                (* in drawing order *)
  END;

  LReals = POINTER TO ARRAY OF LONGREAL;

VAR
  l: Layout;
  last: Item;
  px, ox, oy: LONGREAL;         (* a pixel; the centre, in pixels *)
  minX, minY, maxX, maxY: LONGREAL;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a END;
  RETURN b
END Min;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

(* x rounded to a 1/8192 point, as a REAL, as PmXyLayout's Snap *)
PROCEDURE Snap(x: LONGREAL): REAL;
BEGIN
  IF ABS(x) < 2048 THEN RETURN SHORT(ENTIER(x * 8192 + 0.5D0) / 8192.0D0) END;
  RETURN SHORT(x)
END Snap;

PROCEDURE Add(it: Item);
BEGIN
  it.next := NIL;
  IF last = NIL THEN l.items := it ELSE last.next := it END;
  last := it
END Add;

(* p, the point (x, y) pixels from the centre, in points *)
PROCEDURE Set(VAR p: G.Point; x, y: LONGREAL);
BEGIN
  G.Set(p, Snap((ox + x) * px), Snap((oy + y) * px))
END Set;

PROCEDURE NewItem(kind: INTEGER; fill, line: LONGINT; width: LONGREAL): Item;
  VAR it: Item;
BEGIN
  NEW(it); it.kind := kind; it.form := Polygon; it.n := 0; it.p := NIL; it.c1 := NIL; it.c2 := NIL;
  it.fill := fill; it.line := line; it.width := Snap(width * px); it.lab := NIL;
  it.x := 0; it.y := 0; it.w := 0; it.h := 0; it.r := 0; it.size := 0; it.anchor := Start;
  Add(it);
  RETURN it
END NewItem;

(* The circle of radius r pixels about the centre *)
PROCEDURE AddCircle(r: LONGREAL; fill, line: LONGINT; width: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(Shape, fill, line, width); it.form := Circle;
  it.x := Snap(ox * px); it.y := Snap(oy * px); it.r := Snap(r * px)
END AddCircle;

(* The line from (x1, y1) to (x2, y2), pixels from the centre *)
PROCEDURE AddLine(x1, y1, x2, y2, width: LONGREAL; colour: LONGINT);
  VAR it: Item;
BEGIN
  it := NewItem(Line, -1, colour, width); it.p := G.NewPoints(2); it.n := 2;
  Set(it.p[0], x1, y1); Set(it.p[1], x2, y2)
END AddLine;

(* lab, size Mermaid pixels, at (x, y) pixels from the centre, by
   Mermaid's anchor and dominant-baseline *)
PROCEDURE AddText(lab: F.Label; x, y, size: LONGREAL; anchor, vpos: INTEGER; colour: LONGINT);
  VAR it: Item;
BEGIN
  IF (lab = NIL) OR (lab.n = 0) OR (size <= 0) THEN RETURN END;
  it := NewItem(Text, -1, colour, 0);
  it.lab := lab; it.size := SHORT(size * px); it.anchor := anchor;
  M.LabelSize(l.font, lab, it.size, it.size * 1.2, it.w, it.h);
  IF vpos = Hanging THEN y := y + size / 2
  ELSIF vpos = Auto THEN y := y - size * 0.35D0
  END;
  it.x := Snap((ox + x) * px); it.y := Snap((oy + y) * px)
END AddText;

(* The axis k's angle, of n *)
PROCEDURE Angle(k, n: LONGINT): LONGREAL;
BEGIN
  RETURN 2 * k * MathL.pi / n - MathL.pi / 2
END Angle;

(* A polygon item of the n points (x[k], y[k]), pixels from the centre *)
PROCEDURE AddPolygon(VAR x, y: ARRAY OF LONGREAL; n: LONGINT; fill, line: LONGINT;
  width: LONGREAL);
  VAR it: Item; k: INTEGER;
BEGIN
  it := NewItem(Shape, fill, line, width); it.form := Polygon;
  it.n := SHORT(n); it.p := G.NewPoints(it.n);
  FOR k := 0 TO it.n - 1 DO Set(it.p[k], x[k], y[k]) END
END AddPolygon;

(* A closed Catmull-Rom curve through the n points (x[k], y[k]),
   pixels from the centre, with tension t, as Mermaid's
   closedRoundCurve makes it *)
PROCEDURE AddCurve(VAR x, y: ARRAY OF LONGREAL; n: LONGINT; t: LONGREAL; fill, line: LONGINT;
  width: LONGREAL);
  VAR it: Item; k, k0, k2, k3: LONGINT;
BEGIN
  it := NewItem(Shape, fill, line, width); it.form := Curve;
  it.n := SHORT(n); it.p := G.NewPoints(it.n); it.c1 := G.NewPoints(it.n);
  it.c2 := G.NewPoints(it.n);
  FOR k := 0 TO n - 1 DO
    k0 := (k - 1 + n) MOD n; k2 := (k + 1) MOD n; k3 := (k + 2) MOD n;
    Set(it.p[k], x[k], y[k]);
    Set(it.c1[k], x[k] + (x[k2] - x[k0]) * t, y[k] + (y[k2] - y[k0]) * t);
    Set(it.c2[k], x[k2] - (x[k3] - x[k]) * t, y[k2] - (y[k3] - y[k]) * t)
  END
END AddCurve;

(* The graticule's rings, from the largest in *)
PROCEDURE Graticule(d: R.Diagram; VAR t: S.RadarTheme; radius: LONGREAL);
  VAR rings, i, k, n: LONGINT; r: LONGREAL; fill, f: LONGINT; x, y: LReals;
BEGIN
  IF d.ticks <= 0 THEN RETURN END;
  rings := ENTIER(d.ticks);
  IF rings < d.ticks THEN INC(rings) END;
  n := d.nAxes;
  NEW(x, n + 1); NEW(y, n + 1);
  fill := White;
  FOR i := rings - 1 TO 0 BY -1 DO
    r := radius * (i + 1) / d.ticks;
    fill := GP.Over(t.graticule, t.graticuleOpacity, fill);
    IF t.graticuleOpacity > 0 THEN f := fill ELSE f := -1 END;
    IF ~d.polygon THEN AddCircle(r, f, t.graticule, t.graticuleWidth)
    ELSIF n > 0 THEN
      FOR k := 0 TO n - 1 DO
        x[k] := r * MathL.cos(Angle(k, n)); y[k] := r * MathL.sin(Angle(k, n))
      END;
      AddPolygon(x^, y^, n, f, t.graticule, t.graticuleWidth)
    END
  END
END Graticule;

(* The axes and their labels *)
PROCEDURE Axes(d: R.Diagram; VAR t: S.RadarTheme; radius: LONGREAL);
  VAR a: R.Axis; k: LONGINT; c, s, len, lr: LONGREAL; anchor, vpos: INTEGER;
BEGIN
  a := d.axes; k := 0;
  WHILE a # NIL DO
    c := MathL.cos(Angle(k, d.nAxes)); s := MathL.sin(Angle(k, d.nAxes));
    len := radius * d.axisScaleFactor;
    AddLine(0, 0, len * c, len * s, t.axisWidth, t.axis);
    IF c > 0.01D0 THEN anchor := Start ELSIF c < -0.01D0 THEN anchor := End ELSE anchor := Centre END;
    IF s > 0.01D0 THEN vpos := Hanging ELSIF s < -0.01D0 THEN vpos := Auto ELSE vpos := Central END;
    lr := radius * d.axisLabelFactor + LabelPad;
    AddText(a.label, lr * c, lr * s, t.axisLabelSize, anchor, vpos, t.text);
    a := a.next; INC(k)
  END
END Axes;

(* Whether curve c is drawn *)
PROCEDURE Drawn(d: R.Diagram; c: R.Curve; maxValue: LONGREAL): BOOLEAN;
BEGIN
  RETURN (c.n = d.nAxes) & (c.n >= 2) & (maxValue # d.min)
END Drawn;

(* Curve c, its fill if fill, else its outline *)
PROCEDURE CurveItem(d: R.Diagram; VAR t: S.RadarTheme; c: R.Curve; radius, maxValue: LONGREAL;
  fill: BOOLEAN);
  VAR x, y: LReals; k: LONGINT; v, r: LONGREAL; colour, f, line: LONGINT; w: LONGREAL;
BEGIN
  NEW(x, c.n); NEW(y, c.n);
  FOR k := 0 TO c.n - 1 DO
    v := Min(Max(c.value[k], d.min), maxValue);
    r := radius * (v - d.min) / (maxValue - d.min);
    x[k] := r * MathL.cos(Angle(k, c.n)); y[k] := r * MathL.sin(Angle(k, c.n))
  END;
  colour := t.scale[c.index MOD Colours];
  IF fill THEN f := GP.Over(colour, t.curveOpacity, White); line := -1; w := 0
  ELSE f := -1; line := colour; w := t.curveWidth
  END;
  IF d.polygon THEN AddPolygon(x^, y^, c.n, f, line, w)
  ELSE AddCurve(x^, y^, c.n, d.curveTension, f, line, w)
  END
END CurveItem;

PROCEDURE Curves(d: R.Diagram; VAR t: S.RadarTheme; radius: LONGREAL);
  VAR c: R.Curve; maxValue: LONGREAL; k: LONGINT; any: BOOLEAN;
BEGIN
  IF d.hasMax THEN maxValue := d.max
  ELSE
    any := FALSE; maxValue := 0; c := d.curves;
    WHILE c # NIL DO
      FOR k := 0 TO c.n - 1 DO
        IF ~any OR (c.value[k] > maxValue) THEN maxValue := c.value[k]; any := TRUE END
      END;
      c := c.next
    END
  END;
  IF t.curveOpacity > 0 THEN
    c := d.curves;
    WHILE c # NIL DO
      IF Drawn(d, c, maxValue) THEN CurveItem(d, t, c, radius, maxValue, TRUE) END;
      c := c.next
    END
  END;
  c := d.curves;
  WHILE c # NIL DO
    IF Drawn(d, c, maxValue) THEN CurveItem(d, t, c, radius, maxValue, FALSE) END;
    c := c.next
  END
END Curves;

PROCEDURE Legend(d: R.Diagram; VAR t: S.RadarTheme);
  VAR c: R.Curve; x, y: LONGREAL; it: Item; colour, f: LONGINT;
BEGIN
  x := (d.width / 2 + d.marginRight) * 3 / 4;
  y := -(d.height / 2 + d.marginTop) * 3 / 4;
  c := d.curves;
  WHILE c # NIL DO
    colour := t.scale[c.index MOD Colours];
    IF t.curveOpacity > 0 THEN f := GP.Over(colour, t.curveOpacity, White) ELSE f := -1 END;
    it := NewItem(Rect, f, colour, 1);
    it.x := Snap((ox + x) * px); it.y := Snap((oy + y) * px);
    it.w := Snap(LegendBox * px); it.h := it.w;
    AddText(c.label, x + LegendText, y, t.legendSize, Start, Hanging, t.text);
    y := y + LegendRow;
    c := c.next
  END
END Legend;

(* Adds the box from (x0, y0) to (x1, y1) to the bounds *)
PROCEDURE Bound(x0, y0, x1, y1: LONGREAL);
BEGIN
  IF x0 < minX THEN minX := x0 END;
  IF y0 < minY THEN minY := y0 END;
  IF x1 > maxX THEN maxX := x1 END;
  IF y1 > maxY THEN maxY := y1 END
END Bound;

PROCEDURE BoundPoints(p: G.Points; n: INTEGER; hw: LONGREAL);
  VAR k: INTEGER;
BEGIN
  FOR k := 0 TO n - 1 DO Bound(p[k].x - hw, p[k].y - hw, p[k].x + hw, p[k].y + hw) END
END BoundPoints;

PROCEDURE BoundItem(it: Item);
  VAR a, hw: LONGREAL;
BEGIN
  hw := it.width / 2;
  IF it.line < 0 THEN hw := 0 END;
  IF it.kind = Shape THEN
    IF it.form = Circle THEN
      Bound(it.x - it.r - hw, it.y - it.r - hw, it.x + it.r + hw, it.y + it.r + hw)
    ELSE
      BoundPoints(it.p, it.n, hw);
      IF it.form = Curve THEN BoundPoints(it.c1, it.n, hw); BoundPoints(it.c2, it.n, hw) END
    END
  ELSIF it.kind = Line THEN BoundPoints(it.p, it.n, hw)
  ELSIF it.kind = Rect THEN Bound(it.x - hw, it.y - hw, it.x + it.w + hw, it.y + it.h + hw)
  ELSE
    IF it.anchor = Start THEN a := 0 ELSIF it.anchor = End THEN a := -it.w ELSE a := -it.w / 2 END;
    Bound(it.x + a, it.y - it.h / 2, it.x + a + it.w, it.y + it.h / 2)
  END
END BoundItem;

PROCEDURE MovePoints(p: G.Points; n: INTEGER; dx, dy: LONGREAL);
  VAR k: INTEGER;
BEGIN
  IF p # NIL THEN
    FOR k := 0 TO n - 1 DO G.Set(p[k], Snap(p[k].x + dx), Snap(p[k].y + dy)) END
  END
END MovePoints;

PROCEDURE Move(it: Item; dx, dy: LONGREAL);
BEGIN
  MovePoints(it.p, it.n, dx, dy); MovePoints(it.c1, it.n, dx, dy); MovePoints(it.c2, it.n, dx, dy);
  it.x := Snap(it.x + dx); it.y := Snap(it.y + dy)
END Move;

(* Lays d out, its text set in font at size points, into lay *)
PROCEDURE Make*(d: R.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR t: S.RadarTheme; radius, dx, dy: LONGREAL; it: Item;
BEGIN
  NEW(l); lay := l; l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := SHORT(px); l.items := NIL; last := NIL;
  S.Reset(d.g, l.px); S.RadarColours(t);
  ox := d.marginLeft + d.width / 2; oy := d.marginTop + d.height / 2;
  radius := Min(d.width, d.height) / 2;
  Graticule(d, t, radius);
  Axes(d, t, radius);
  Curves(d, t, radius);
  IF d.showLegend THEN Legend(d, t) END;
  AddText(d.g.title, 0, -d.height / 2 - d.marginTop, TitleSize, Centre, Hanging, t.text);
  (* the bounds, and everything moved for them *)
  minX := 0; minY := 0;
  maxX := (d.width + d.marginLeft + d.marginRight) * px;
  maxY := (d.height + d.marginTop + d.marginBottom) * px;
  it := l.items;
  WHILE it # NIL DO BoundItem(it); it := it.next END;
  dx := -minX; dy := -minY;
  l.width := Snap(maxX - minX); l.height := Snap(maxY - minY);
  IF (dx # 0) OR (dy # 0) THEN
    it := l.items;
    WHILE it # NIL DO Move(it, dx, dy); it := it.next END
  END
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: R.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmRadarLayout.
