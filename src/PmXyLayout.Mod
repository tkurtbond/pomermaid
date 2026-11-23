MODULE PmXyLayout;
(* PmXyLayout: an XY chart, PmXy's, laid out as Mermaid 12.3.0's
   xychart chart builder lays it out (orchestrator.ts and its
   components), in its pixels, taken at the labels' size, 16 pixels to
   the size. Lengths are in points, y down.

   The chart is width by height pixels; the plot takes
   plotReservedSpacePercent of each; of the rest, the title takes its
   height, then the axes theirs, the x axis's below the plot and the y
   axis's at its left (vertical), or the x axis's at the left and the y
   axis's above (horizontal); the legend, at the plot's right, its
   width; and the plot takes what is left. An axis shows its line, its
   labels, its ticks and its title, each if it fits; a linear axis's
   ticks are d3's, about 10 round numbers; a band axis's, its
   categories, the first and last at its ends, or one in its middle.
   Bars are 0.95 of the smaller of the ticks' distance and twice the
   axis's outer padding wide.

   The drawing is a list of items, in Mermaid's order: the
   background; the title; the plots, each bar plot's bars and their
   data labels, each line plot's line and its points' labels; the
   legend's markers and texts; the x axis's line, labels, ticks and
   title; and the y axis's.

   Text the chart cannot hold widens the drawing (decision 19): its
   bounds are the chart's and every item's, and everything is moved for
   them to start at (0, 0); the background is the whole drawing.

   The arithmetic is LONGREAL, and each item's places and sizes are
   rounded once, as it is made, to a 1/8192 point (Snap): REAL's,
   rounded at each step, comes out a digit apart on i386, whose x87
   rounds differently, and so does a value rounded to the nearest
   REAL where it is close to halfway between two. *)

IMPORT MathL, M := PmMetrics, F := PmFlow, G := PmGeom, L := PmLex, S := PmStyle, X := PmXy;

CONST
  MermaidSize* = 16;
  Eps = 0.001D0;   (* a thousandth of a pixel, for comparisons that may be equalities *)
  (* items *)
  Rect* = 0; Path* = 1; Text* = 2;
  (* a text's anchor *)
  Start* = 0; Centre* = 1; End* = 2;
  (* an axis's position *)
  Left = 0; Bottom = 1; Top = 2;
  (* a text's vertical position *)
  Middle = 0; Upper = 1; Hanging = 2; Baseline = 3;

TYPE
  (* A rectangle, filled: (x, y) its top left corner, w by h;
     a path: its points p[0 .. n-1], width wide;
     a text: lab, size points, its anchor point (x, y), on its middle
     line, where it starts, its middle or its end is; turned by angle
     degrees, clockwise, about that point; w by h *)
  Item* = POINTER TO ItemDesc;
  ItemDesc* = RECORD
    kind-: INTEGER;
    x-, y-, w-, h-: REAL;
    colour-: LONGINT;
    width-: REAL;
    p-: G.Points; n-: INTEGER;
    lab-: F.Label;
    size-, angle-: REAL;
    anchor-: INTEGER;
    next-: Item
  END;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: X.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;      (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    items-: Item                (* in drawing order, the background first *)
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;
  LReals = POINTER TO ARRAY OF LONGREAL;

  (* An axis being laid out, as Mermaid's BaseAxis *)
  AxisL = RECORD
    a: X.Axis;
    c: X.AxisConfig;
    labelColour, lineColour, titleColour: LONGINT;
    pos: INTEGER;
    bx, by, bw, bh, r0, r1, op: LONGREAL;
    showLine, showLabel, showTick, showTitle: BOOLEAN;
    titleH, labelW, labelH, rot, rotH: LONGREAL;
    nTicks: LONGINT;
    tick: LReals;               (* a linear axis's ticks *)
    label: X.Labels;            (* each tick's text *)
    d0, d1: LONGREAL            (* a linear axis's domain *)
  END;

VAR
  l: Layout;
  last: Item;
  px: LONGREAL;
  minX, minY, maxX, maxY: LONGREAL;

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

(* x rounded to a 1/8192 point, as a REAL: such a value is a REAL
   exactly, the same on every machine, where x rounded to the nearest
   REAL can come out a REAL apart on i386, whose x87 rounds differently
   in the last place, and be written a digit apart *)
PROCEDURE Snap(x: LONGREAL): REAL;
BEGIN
  IF ABS(x) < 2048 THEN RETURN SHORT(ENTIER(x * 8192 + 0.5D0) / 8192.0D0) END;
  RETURN SHORT(x)
END Snap;

PROCEDURE Empty(lab: F.Label): BOOLEAN;
BEGIN
  RETURN (lab = NIL) OR (lab.n = 0)
END Empty;

(* JavaScript's MathL.round *)
PROCEDURE Round(x: LONGREAL): LONGREAL;
BEGIN
  RETURN ENTIER(x + 0.5D0)
END Round;

(* lab's width and height at size Mermaid pixels, in Mermaid pixels *)
PROCEDURE Measure(lab: F.Label; size: LONGREAL; VAR w, h: LONGREAL);
  VAR rw, rh: REAL;
BEGIN
  IF Empty(lab) THEN w := 0; h := 0
  ELSE
    M.LabelSize(l.font, lab, SHORT(size * px), SHORT(size * px * 1.2D0), rw, rh);
    w := rw / px; h := rh / px
  END
END Measure;

PROCEDURE Add(it: Item);
BEGIN
  it.next := NIL;
  IF last = NIL THEN l.items := it ELSE last.next := it END;
  last := it
END Add;

(* A rectangle, in Mermaid pixels *)
PROCEDURE AddRect(x, y, w, h: LONGREAL; colour: LONGINT);
  VAR it: Item;
BEGIN
  NEW(it); it.kind := Rect;
  it.x := Snap(x * px); it.y := Snap(y * px); it.w := Snap(w * px); it.h := Snap(h * px);
  it.colour := colour; Add(it)
END AddRect;

(* A path of n points, to be set, width Mermaid pixels wide *)
PROCEDURE NewPath(n: INTEGER; width: LONGREAL; colour: LONGINT): Item;
  VAR it: Item;
BEGIN
  NEW(it); it.kind := Path; it.p := G.NewPoints(n); it.n := n; it.width := Snap(width * px);
  it.colour := colour; Add(it);
  RETURN it
END NewPath;

(* The line from (x1, y1) to (x2, y2), in Mermaid pixels *)
PROCEDURE AddLine(x1, y1, x2, y2, width: LONGREAL; colour: LONGINT);
  VAR it: Item;
BEGIN
  it := NewPath(2, width, colour);
  G.Set(it.p[0], Snap(x1 * px), Snap(y1 * px)); G.Set(it.p[1], Snap(x2 * px), Snap(y2 * px))
END AddLine;

(* lab, size Mermaid pixels, at (x, y), by Mermaid's anchor and
   vertical position, turned by angle degrees *)
PROCEDURE AddText(lab: F.Label; x, y, size: LONGREAL; anchor, vpos: INTEGER; angle: LONGREAL;
  colour: LONGINT);
  VAR it: Item; dy, a: LONGREAL;
BEGIN
  IF Empty(lab) OR (size <= 0) THEN RETURN END;
  NEW(it); it.kind := Text; it.lab := lab; it.size := SHORT(size * px); it.anchor := anchor;
  it.angle := SHORT(angle); it.colour := colour;
  M.LabelSize(l.font, lab, it.size, it.size * 1.2, it.w, it.h);
  IF (vpos = Upper) OR (vpos = Hanging) THEN dy := size / 2
  ELSIF vpos = Baseline THEN dy := -size * 0.35D0
  ELSE dy := 0
  END;
  (* the middle line, dy down in the text's own direction *)
  a := angle * MathL.pi / 180;
  it.x := Snap((x - dy * MathL.sin(a)) * px); it.y := Snap((y + dy * MathL.cos(a)) * px);
  Add(it)
END AddText;

(* Adds the box from (x0, y0) to (x1, y1) to the bounds *)
PROCEDURE Bound(x0, y0, x1, y1: LONGREAL);
BEGIN
  IF x0 < minX THEN minX := x0 END;
  IF y0 < minY THEN minY := y0 END;
  IF x1 > maxX THEN maxX := x1 END;
  IF y1 > maxY THEN maxY := y1 END
END Bound;

PROCEDURE BoundItem(it: Item);
  VAR k: INTEGER; a, b, c, s, x, y, u, v, hw: LONGREAL;
BEGIN
  IF it.kind = Rect THEN Bound(it.x, it.y, it.x + it.w, it.y + it.h)
  ELSIF it.kind = Path THEN
    hw := it.width / 2;
    FOR k := 0 TO it.n - 1 DO
      Bound(it.p[k].x - hw, it.p[k].y - hw, it.p[k].x + hw, it.p[k].y + hw)
    END
  ELSE
    IF it.anchor = Start THEN a := 0 ELSIF it.anchor = End THEN a := -it.w ELSE a := -it.w / 2 END;
    b := a + it.w;
    c := MathL.cos(it.angle * MathL.pi / 180); s := MathL.sin(it.angle * MathL.pi / 180);
    FOR k := 0 TO 3 DO
      IF ODD(k) THEN u := b ELSE u := a END;
      IF k < 2 THEN v := -it.h / 2 ELSE v := it.h / 2 END;
      x := it.x + u * c - v * s; y := it.y + u * s + v * c;
      Bound(x, y, x, y)
    END
  END
END BoundItem;

PROCEDURE Move(it: Item; dx, dy: LONGREAL);
  VAR k: INTEGER;
BEGIN
  IF it.kind = Path THEN
    FOR k := 0 TO it.n - 1 DO G.Set(it.p[k], Snap(it.p[k].x + dx), Snap(it.p[k].y + dy)) END
  ELSE it.x := Snap(it.x + dx); it.y := Snap(it.y + dy)
  END
END Move;

(* 10 to the k, as MathL.pow gives it *)
PROCEDURE Pow10(k: LONGINT): LONGREAL;
  VAR x: LONGREAL;
BEGIN
  IF k < 0 THEN RETURN 1 / Pow10(-k) END;
  x := 1;
  WHILE k > 0 DO x := x * 10; DEC(k) END;
  RETURN x
END Pow10;

(* d3's tickSpec, for start < stop: the ticks i1 * inc .. i2 * inc, or
   i / -inc for inc < 0 *)
PROCEDURE TickSpec(start, stop, count: LONGREAL; VAR i1, i2, inc: LONGREAL);
  CONST sqrt50 = 7.0710678118654755D0; sqrt10 = 3.1622776601683795D0;
    sqrt2 = 1.4142135623730951D0;
  VAR step, error, factor: LONGREAL; power: LONGINT;
BEGIN
  step := (stop - start) / count;
  power := 0;
  IF step >= 1 THEN
    WHILE step >= Pow10(power + 1) DO INC(power) END
  ELSE
    WHILE step < Pow10(power) DO DEC(power) END
  END;
  error := step / Pow10(power);
  IF error >= sqrt50 THEN factor := 10
  ELSIF error >= sqrt10 THEN factor := 5
  ELSIF error >= sqrt2 THEN factor := 2
  ELSE factor := 1
  END;
  IF power < 0 THEN
    inc := Pow10(-power) / factor;
    i1 := Round(start * inc); i2 := Round(stop * inc);
    IF i1 / inc < start THEN i1 := i1 + 1 END;
    IF i2 / inc > stop THEN i2 := i2 - 1 END;
    inc := -inc
  ELSE
    inc := Pow10(power) * factor;
    i1 := Round(start / inc); i2 := Round(stop / inc);
    IF i1 * inc < start THEN i1 := i1 + 1 END;
    IF i2 * inc > stop THEN i2 := i2 - 1 END
  END;
  IF (i2 < i1) & (0.5D0 <= count) & (count < 2) THEN TickSpec(start, stop, count * 2, i1, i2, inc) END
END TickSpec;

(* a's ticks, d3's ticks(d0, d1, 10), and their texts *)
PROCEDURE LinearTicks(VAR a: AxisL);
  VAR i1, i2, inc, lo, hi, t: LONGREAL; n, k: LONGINT; reverse: BOOLEAN;
    s: ARRAY 64 OF CHAR;
BEGIN
  a.nTicks := 0;
  IF a.d0 = a.d1 THEN NEW(a.tick, 1); a.tick[0] := a.d0; a.nTicks := 1
  ELSE
    reverse := a.d1 < a.d0;
    IF reverse THEN lo := a.d1; hi := a.d0 ELSE lo := a.d0; hi := a.d1 END;
    TickSpec(lo, hi, 10, i1, i2, inc);
    IF i2 >= i1 THEN
      n := ENTIER(i2 - i1) + 1; NEW(a.tick, n); a.nTicks := n;
      FOR k := 0 TO n - 1 DO
        IF reverse THEN t := i2 - k ELSE t := i1 + k END;
        IF inc < 0 THEN a.tick[k] := t / (-inc) ELSE a.tick[k] := t * inc END
      END
    END
  END;
  NEW(a.label, a.nTicks + 1);
  FOR k := 0 TO a.nTicks - 1 DO
    X.JsNumber(a.tick[k], s); a.label[k] := F.PlainLabel(L.New(s))
  END
END LinearTicks;

(* Sets up a for the axis ax, of configuration c, in colours from t's
   k-th axis *)
PROCEDURE InitAxis(VAR a: AxisL; VAR ax: X.Axis; VAR c: X.AxisConfig; VAR t: S.XyTheme;
  k: INTEGER);
  VAR j: LONGINT; w, h: LONGREAL;
BEGIN
  a.a := ax; a.c := c;
  a.titleColour := t.axisTitle[k]; a.labelColour := t.axisLabel[k]; a.tick := NIL;
  a.lineColour := t.axisLine[k]; a.titleH := 0; a.op := 0; a.r0 := 0; a.r1 := 10;
  a.bx := 0; a.by := 0; a.bw := 0; a.bh := 0;
  a.showLine := FALSE; a.showLabel := FALSE; a.showTick := FALSE; a.showTitle := FALSE;
  IF (c.labelRotation >= -90) & (c.labelRotation <= 90) THEN a.rot := c.labelRotation
  ELSE a.rot := 0
  END;
  IF ax.linear THEN
    IF ax.min <= ax.max THEN a.d0 := ax.min; a.d1 := ax.max
    ELSE a.d0 := 0; a.d1 := 0
    END;
    LinearTicks(a)
  ELSE
    a.nTicks := ax.nCat; NEW(a.label, ax.nCat + 1);
    FOR j := 0 TO ax.nCat - 1 DO a.label[j] := ax.cat[j] END
  END;
  a.labelW := 0; a.labelH := 0;
  FOR j := 0 TO a.nTicks - 1 DO
    Measure(a.label[j], c.labelFontSize, w, h);
    a.labelW := Max(a.labelW, w); a.labelH := Max(a.labelH, h)
  END;
  a.rotH := a.labelH
END InitAxis;

PROCEDURE SetRange(VAR a: AxisL; r0, r1: LONGREAL);
BEGIN
  a.r0 := r0; a.r1 := r1;
  IF a.pos = Left THEN a.bh := r1 - r0 ELSE a.bw := r1 - r0 END
END SetRange;

PROCEDURE TickDistance(VAR a: AxisL): LONGREAL;
BEGIN
  IF a.nTicks = 0 THEN RETURN 0 END;   (* Mermaid's Infinity, or NaN *)
  RETURN ABS((a.r1 - a.op) - (a.r0 + a.op)) / a.nTicks
END TickDistance;

PROCEDURE PaddingForBars(VAR a: AxisL);
BEGIN
  IF 0.7D0 * TickDistance(a) > a.op * 2 THEN a.op := ENTIER(0.7D0 * TickDistance(a) / 2) END
END PaddingForBars;

(* The space a takes of availW by availH, as Mermaid's calculateSpace *)
PROCEDURE Calc(VAR a: AxisL; availW, availH: LONGREAL);
  VAR avail, need, w, h, r: LONGREAL;
BEGIN
  IF a.pos = Left THEN avail := availW ELSE avail := availH END;
  IF a.c.showAxisLine & (avail > a.c.axisLineWidth) THEN
    avail := avail - a.c.axisLineWidth; a.showLine := TRUE
  END;
  IF a.c.showLabel THEN
    IF a.pos = Left THEN
      a.op := Min(a.labelH / 2, 0.2D0 * availH);
      need := a.labelW + 2 * a.c.labelPadding
    ELSE
      a.op := Min(a.labelW / 2, 0.2D0 * availW);
      need := a.labelH;
      IF (a.pos = Bottom) & (a.rot # 0) THEN
        r := a.rot * MathL.pi / 180;
        need := Max(need, ABS(MathL.sin(r) * a.labelW) + ABS(MathL.cos(r) * a.labelH))
      END;
      a.rotH := need;
      need := need + 2 * a.c.labelPadding
    END;
    IF need <= avail THEN avail := avail - need; a.showLabel := TRUE END
  END;
  IF a.c.showTick & (avail >= a.c.tickLength) THEN
    a.showTick := TRUE; avail := avail - a.c.tickLength
  END;
  IF a.c.showTitle & ~Empty(a.a.title) THEN
    Measure(a.a.title, a.c.titleFontSize, w, h);
    need := h + 2 * a.c.titlePadding; a.titleH := h;
    IF need <= avail THEN avail := avail - need; a.showTitle := TRUE END
  END;
  IF a.pos = Left THEN a.bw := availW - avail; a.bh := availH
  ELSE a.bw := availW; a.bh := availH - avail
  END
END Calc;

(* Where the linear axis a puts v *)
PROCEDURE ScaleValue(VAR a: AxisL; v: LONGREAL): LONGREAL;
  VAR d0, d1, r0, r1: LONGREAL;
BEGIN
  r0 := a.r0 + a.op; r1 := a.r1 - a.op;
  IF a.pos = Left THEN d0 := a.d1; d1 := a.d0 ELSE d0 := a.d0; d1 := a.d1 END;
  IF d0 = d1 THEN RETURN (r0 + r1) / 2 END;
  RETURN r0 + (v - d0) / (d1 - d0) * (r1 - r0)
END ScaleValue;

(* Where the band axis a puts its k-th distinct category, of n *)
PROCEDURE BandAt(VAR a: AxisL; k, n: LONGINT): LONGREAL;
  VAR r0, r1: LONGREAL;
BEGIN
  r0 := a.r0 + a.op; r1 := a.r1 - a.op;
  IF n <= 1 THEN RETURN r0 + (r1 - r0) / 2 END;
  RETURN r0 + (r1 - r0) / (n - 1) * k
END BandAt;

(* Where the band axis a puts the category key: d3's scaleBand, whose
   domain has each category once; its start for none *)
PROCEDURE ScaleKey(VAR a: AxisL; key: L.Str): LONGREAL;
  VAR i, j, n, k: LONGINT; dup: BOOLEAN;
BEGIN
  n := 0; k := -1;
  FOR i := 0 TO a.a.nCat - 1 DO
    dup := FALSE; j := 0;
    WHILE ~dup & (j < i) DO dup := L.Equal(a.a.key[j], a.a.key[i]); INC(j) END;
    IF ~dup THEN
      IF (k < 0) & L.Equal(a.a.key[i], key) THEN k := n END;
      INC(n)
    END
  END;
  IF k < 0 THEN RETURN a.r0 + a.op END;
  RETURN BandAt(a, k, n)
END ScaleKey;

(* Where a puts its j-th tick *)
PROCEDURE TickAt(VAR a: AxisL; j: LONGINT): LONGREAL;
BEGIN
  IF a.a.linear THEN RETURN ScaleValue(a, a.tick[j]) END;
  RETURN ScaleKey(a, a.a.key[j])
END TickAt;

(* Where the x axis a puts datum v; FALSE if nowhere *)
PROCEDURE XAt(VAR a: AxisL; VAR v: X.Datum; VAR at: LONGREAL): BOOLEAN;
BEGIN
  IF a.a.linear THEN
    IF ~v.isNum THEN RETURN FALSE END;
    at := ScaleValue(a, v.num)
  ELSE at := ScaleKey(a, v.key)
  END;
  RETURN TRUE
END XAt;

(* The items for the axis a, as Mermaid's getDrawableElements *)
PROCEDURE DrawAxis(VAR a: AxisL; tickColour: LONGINT);
  VAR j: LONGINT; x, y, lw, tl, at: LONGREAL; size: LONGREAL;
BEGIN
  lw := a.c.axisLineWidth; tl := a.c.tickLength; size := a.c.labelFontSize;
  IF a.pos = Left THEN
    IF a.showLine THEN
      x := a.bx + a.bw - lw / 2; AddLine(x, a.by, x, a.by + a.bh, lw, a.lineColour)
    END;
    IF a.showLabel THEN
      x := a.bx + a.bw - a.c.labelPadding;
      IF a.showTick THEN x := x - tl END;
      IF a.showLine THEN x := x - lw END;
      FOR j := 0 TO a.nTicks - 1 DO
        AddText(a.label[j], x, TickAt(a, j), size, End, Middle, 0, a.labelColour)
      END
    END;
    IF a.showTick THEN
      x := a.bx + a.bw; IF a.showLine THEN x := x - lw END;
      FOR j := 0 TO a.nTicks - 1 DO
        at := TickAt(a, j); AddLine(x, at, x - tl, at, a.c.tickWidth, tickColour)
      END
    END;
    IF a.showTitle THEN
      AddText(a.a.title, a.bx + a.c.titlePadding, a.by + a.bh / 2,
        a.c.titleFontSize, Centre, Upper, 270, a.titleColour)
    END
  ELSIF a.pos = Bottom THEN
    IF a.showLine THEN
      y := a.by + lw / 2; AddLine(a.bx, y, a.bx + a.bw, y, lw, a.lineColour)
    END;
    IF a.showLabel THEN
      y := a.by + a.c.labelPadding;
      IF a.showTick THEN y := y + tl END;
      IF a.showLine THEN y := y + lw END;
      (* decision 20: each label turned about its centre, in the middle
         of the height kept for them *)
      FOR j := 0 TO a.nTicks - 1 DO
        AddText(a.label[j], TickAt(a, j), y + a.rotH / 2, size, Centre, Middle, a.rot, a.labelColour)
      END
    END;
    IF a.showTick THEN
      y := a.by; IF a.showLine THEN y := y + lw END;
      FOR j := 0 TO a.nTicks - 1 DO
        at := TickAt(a, j); AddLine(at, y, at, y + tl, a.c.tickWidth, tickColour)
      END
    END;
    IF a.showTitle THEN
      AddText(a.a.title, a.r0 + (a.r1 - a.r0) / 2,
        a.by + a.bh - a.c.titlePadding - a.titleH,
        a.c.titleFontSize, Centre, Upper, 0, a.titleColour)
    END
  ELSE  (* Top *)
    IF a.showLine THEN
      y := a.by + a.bh - lw / 2; AddLine(a.bx, y, a.bx + a.bw, y, lw, a.lineColour)
    END;
    IF a.showLabel THEN
      y := a.by + a.c.labelPadding;
      IF a.showTitle THEN y := y + a.titleH + 2 * a.c.titlePadding END;
      FOR j := 0 TO a.nTicks - 1 DO
        AddText(a.label[j], TickAt(a, j), y, size, Centre, Upper, 0, a.labelColour)
      END
    END;
    IF a.showTick THEN
      y := a.by + a.bh; IF a.showLine THEN y := y - lw END;
      FOR j := 0 TO a.nTicks - 1 DO
        at := TickAt(a, j); AddLine(at, y, at, y - tl, a.c.tickWidth, tickColour)
      END
    END;
    IF a.showTitle THEN
      AddText(a.a.title, a.bx + a.bw / 2, a.by + a.c.titlePadding,
        a.c.titleFontSize, Centre, Upper, 0, a.titleColour)
    END
  END
END DrawAxis;

PROCEDURE Length(s: L.Str): LONGINT;
BEGIN
  RETURN L.Length(s^)
END Length;

(* p's bars, at plotX, plotY, plotW by plotH, and their data labels *)
PROCEDURE Bars(d: X.Diagram; p: X.Plot; VAR xa, ya: AxisL; plotX, plotY, plotH: LONGREAL;
  colour, labelColour: LONGINT);
  VAR
    k, n: LONGINT; bw, xs, ys, x, y, w, h, fs, tw, cx, least: LONGREAL;
    bx, by, bwid, bht: Reals; ok: POINTER TO ARRAY OF BOOLEAN; any: BOOLEAN;
BEGIN
  n := p.n;
  NEW(bx, n + 1); NEW(by, n + 1); NEW(bwid, n + 1); NEW(bht, n + 1); NEW(ok, n + 1);
  bw := Min(xa.op * 2, TickDistance(xa)) * 0.95D0;
  FOR k := 0 TO n - 1 DO
    ok[k] := p.data[k].def & XAt(xa, p.data[k], xs);
    IF ok[k] THEN
      ys := ScaleValue(ya, p.data[k].y);
      IF d.horizontal THEN x := plotX; y := xs - bw / 2; w := ys - plotX; h := bw
      ELSE x := xs - bw / 2; y := ys; w := bw; h := plotY + plotH - ys
      END;
      bx[k] := x; by[k] := y; bwid[k] := w; bht[k] := h;
      AddRect(x, y, w, h, colour)
    END
  END;
  IF ~d.showDataLabel THEN RETURN END;
  (* the data labels: one size, the largest that fits every bar *)
  any := FALSE; least := 0;
  FOR k := 0 TO n - 1 DO
    IF ok[k] & (bwid[k] > 0) & (bht[k] > 0) THEN
      tw := Length(p.data[k].shown) * 0.7D0;
      IF d.horizontal THEN
        fs := bht[k] * 0.7D0;
        WHILE ~(fs * tw <= bwid[k] - 10 + Eps) & (fs > 0) DO fs := fs - 1 END
      ELSE
        (* fs * tw is bwid[k] here, which fits; Eps keeps it fitting
           however the last bit is rounded *)
        fs := bwid[k] / tw; cx := bx[k] + bwid[k] / 2;
        WHILE ~((cx - fs * tw / 2 >= bx[k] - Eps) & (cx + fs * tw / 2 <= bx[k] + bwid[k] + Eps)
          & (by[k] + 10 + fs <= by[k] + bht[k] + Eps)) & (fs > 0) DO
          fs := fs - 1
        END
      END;
      IF ~any OR (fs < least) THEN least := fs END;
      any := TRUE
    ELSE ok[k] := FALSE
    END
  END;
  IF ~any THEN RETURN END;
  fs := ENTIER(least);
  IF fs <= 0 THEN RETURN END;
  FOR k := 0 TO n - 1 DO
    IF ok[k] THEN
      IF d.horizontal THEN
        IF d.outside THEN
          AddText(F.PlainLabel(p.data[k].shown), bx[k] + bwid[k] + 10, by[k] + bht[k] / 2, fs,
            Start, Middle, 0, labelColour)
        ELSE
          AddText(F.PlainLabel(p.data[k].shown), bx[k] + bwid[k] - 10, by[k] + bht[k] / 2, fs,
            End, Middle, 0, labelColour)
        END
      ELSIF d.outside THEN
        AddText(F.PlainLabel(p.data[k].shown), bx[k] + bwid[k] / 2, by[k] - 10, fs,
          Centre, Baseline, 0, labelColour)
      ELSE
        AddText(F.PlainLabel(p.data[k].shown), bx[k] + bwid[k] / 2, by[k] + 10, fs,
          Centre, Hanging, 0, labelColour)
      END
    END
  END
END Bars;

(* p's line and its points' labels *)
PROCEDURE Line(d: X.Diagram; p: X.Plot; VAR xa, ya: AxisL; colour: LONGINT);
  VAR k, n: LONGINT; xs, ys: LONGREAL; it: Item; xv, yv: Reals; ok: POINTER TO ARRAY OF BOOLEAN;
BEGIN
  NEW(xv, p.n + 1); NEW(yv, p.n + 1); NEW(ok, p.n + 1);
  n := 0;   (* the points before the first undefined one *)
  FOR k := 0 TO p.n - 1 DO
    ok[k] := p.data[k].def & XAt(xa, p.data[k], xs);
    IF ok[k] THEN
      ys := ScaleValue(ya, p.data[k].y);
      IF d.horizontal THEN xv[k] := ys; yv[k] := xs ELSE xv[k] := xs; yv[k] := ys END;
      IF n = k THEN INC(n) END
    END
  END;
  IF n >= 2 THEN
    it := NewPath(SHORT(n), 2, colour);
    FOR k := 0 TO n - 1 DO G.Set(it.p[k], Snap(xv[k] * px), Snap(yv[k] * px)) END
  END;
  FOR k := 0 TO p.n - 1 DO
    IF ok[k] & ~Empty(p.data[k].label) THEN
      IF d.horizontal THEN AddText(p.data[k].label, xv[k] + 10, yv[k], 12, Start, Middle, 0, colour)
      ELSE AddText(p.data[k].label, xv[k], yv[k] - 10, 12, Centre, Middle, 0, colour)
      END
    END
  END
END Line;

(* The legend's width and height, if it fits in availW by availH, else 0 *)
PROCEDURE LegendSpace(d: X.Diagram; availW, availH: LONGREAL; VAR w, h: LONGREAL);
  VAR p: X.Plot; n: INTEGER; tw, th, fs: LONGREAL;
BEGIN
  w := 0; h := 0; n := 0; tw := 0;
  IF ~d.showLegend THEN RETURN END;
  fs := d.legendFontSize;
  p := d.plots;
  WHILE p # NIL DO
    IF ~Empty(p.title) THEN Measure(p.title, fs, w, th); tw := Max(tw, w); INC(n) END;
    p := p.next
  END;
  w := 0;
  IF n = 0 THEN RETURN END;
  w := d.legendPadding * 2 + fs * 0.75D0 + fs * 0.35D0 + tw;
  h := d.legendPadding * 2 + n * fs + (n - 1) * fs * 0.5D0;
  IF (w > availW) OR (h > availH) THEN w := 0; h := 0 END
END LegendSpace;

PROCEDURE Legend(d: X.Diagram; VAR t: S.XyTheme; x, y: LONGREAL);
  VAR p: X.Plot; i: INTEGER; fs, m, sx, sy, row, my: LONGREAL;
BEGIN
  fs := d.legendFontSize; m := fs * 0.75D0; row := fs + fs * 0.5D0;
  sx := x + d.legendPadding; sy := y + d.legendPadding;
  p := d.plots; i := 0;
  WHILE p # NIL DO
    IF ~Empty(p.title) THEN
      IF p.bar THEN AddRect(sx, sy + i * row, m, m, t.palette[p.index MOD t.nPalette]) END;
      INC(i)
    END;
    p := p.next
  END;
  p := d.plots; i := 0;
  WHILE p # NIL DO
    IF ~Empty(p.title) THEN
      IF ~p.bar THEN
        my := sy + i * row + m / 2;
        AddLine(sx, my, sx + m, my, 2, t.palette[p.index MOD t.nPalette])
      END;
      INC(i)
    END;
    p := p.next
  END;
  p := d.plots; i := 0;
  WHILE p # NIL DO
    IF ~Empty(p.title) THEN
      AddText(p.title, sx + m + fs * 0.35D0, sy + i * row + m / 2, fs, Start, Middle, 0, t.legend);
      INC(i)
    END;
    p := p.next
  END
END Legend;

(* Lays d out, its text set in font at size points, into lay *)
PROCEDURE Make*(d: X.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR
    t: S.XyTheme; xa, ya: AxisL; p: X.Plot; it, back: Item;
    W, H, chartW, chartH, availW, availH, plotX, plotY, titleY, titleW, titleH, th,
    legW, legH, half, centre, dx, dy: LONGREAL;
    showTitle, anyBar: BOOLEAN;
BEGIN
  NEW(l); lay := l; l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := SHORT(px); l.items := NIL; last := NIL;
  S.Reset(d.g, l.px); S.XyColours(t);
  IF t.nPalette = 0 THEN t.palette[0] := 0; t.nPalette := 1 END;
  InitAxis(xa, d.x, d.axis[0], t, 0); InitAxis(ya, d.y, d.axis[1], t, 1);
  W := d.width; H := d.height;
  chartW := ENTIER(W * d.reserved / 100); chartH := ENTIER(H * d.reserved / 100);
  availW := W - chartW; availH := H - chartH;
  (* the title *)
  Measure(d.g.title, d.titleFontSize, titleW, titleH);
  th := titleH + 2 * d.titlePadding;
  showTitle := d.showTitle & ~Empty(d.g.title) & (th <= availH);
  IF ~showTitle THEN th := 0 END;
  availH := availH - th;
  IF ~d.horizontal THEN
    plotY := th;
    xa.pos := Bottom; Calc(xa, availW, availH); availH := availH - xa.bh;
    ya.pos := Left; Calc(ya, availW, availH); plotX := ya.bw; availW := availW - ya.bw
  ELSE
    titleY := th;
    xa.pos := Left; Calc(xa, availW, availH); availW := availW - xa.bw; plotX := xa.bw;
    ya.pos := Top; Calc(ya, availW, availH); availH := availH - ya.bh; plotY := titleY + ya.bh
  END;
  LegendSpace(d, availW, chartH, legW, legH);
  availW := availW - legW;
  IF availW > 0 THEN chartW := chartW + availW END;
  IF availH > 0 THEN chartH := chartH + availH END;
  IF ~d.horizontal THEN
    SetRange(xa, plotX, plotX + chartW); xa.bx := plotX; xa.by := plotY + chartH;
    SetRange(ya, plotY, plotY + chartH); ya.bx := 0; ya.by := plotY
  ELSE
    SetRange(ya, plotX, plotX + chartW); ya.bx := plotX; ya.by := titleY;
    SetRange(xa, plotY, plotY + chartH); xa.bx := 0; xa.by := plotY
  END;
  anyBar := FALSE; p := d.plots;
  WHILE p # NIL DO anyBar := anyBar OR p.bar; p := p.next END;
  IF anyBar THEN PaddingForBars(xa) END;
  (* the items: the background, sized at the end *)
  AddRect(0, 0, W, H, t.background); back := last;
  IF showTitle THEN
    half := Min(titleW, W) / 2;
    centre := Min(Max(plotX + chartW / 2, half), W - half);
    AddText(d.g.title, centre, th / 2, d.titleFontSize, Centre, Middle, 0, t.title)
  END;
  p := d.plots;
  WHILE p # NIL DO
    IF p.bar THEN
      Bars(d, p, xa, ya, plotX, plotY, chartH, t.palette[p.index MOD t.nPalette], t.dataLabel)
    ELSE Line(d, p, xa, ya, t.palette[p.index MOD t.nPalette])
    END;
    p := p.next
  END;
  IF legW > 0 THEN Legend(d, t, plotX + chartW, plotY + Max((chartH - legH) / 2, 0)) END;
  DrawAxis(xa, t.axisTick[0]); DrawAxis(ya, t.axisTick[1]);
  (* the bounds, and everything moved for them *)
  minX := 0; minY := 0; maxX := W * px; maxY := H * px;
  it := l.items;
  WHILE it # NIL DO BoundItem(it); it := it.next END;
  dx := -minX; dy := -minY;
  l.width := Snap(maxX - minX); l.height := Snap(maxY - minY);
  IF (dx # 0) OR (dy # 0) THEN
    it := l.items;
    WHILE it # NIL DO Move(it, dx, dy); it := it.next END
  END;
  back.x := 0; back.y := 0; back.w := l.width; back.h := l.height
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: X.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmXyLayout.
