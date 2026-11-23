MODULE PmQuadrantLayout;
(* PmQuadrantLayout: a quadrant chart, PmQuadrant's, laid out as
   Mermaid 12.3.0's quadrantBuilder.ts lays it out, in its pixels,
   taken at the labels' size, the quadrants' 16 pixels to the size.
   Lengths are in points, y down; a text's y is its middle, half its
   size below its top for a "hanging" text, as Mermaid sets most of
   them.

   The chart is chartWidth by chartHeight pixels, 500 by 500. Above
   it, for a title, titleFontSize and titlePadding above and below;
   then the x axis's texts, xAxisLabelFontSize and xAxisLabelPadding
   above and below, at the top (xAxisPosition) if there are no points,
   else at the bottom; the y axis's at the left or the right
   (yAxisPosition), turned to read upward; the quadrants fill the rest,
   quadrantPadding inside it, with their texts centred in them, or at
   their top, quadrantTextTopPadding below it, if there are points. An
   axis is shown if it has a text. An axis with its second text has its
   texts in the middle of its halves, else its first text starts at the
   quadrants' corner.

   Points are at x and y, from 0 to 1, across the quadrants, from the
   bottom left; each one's text centred below it, pointTextPadding
   down. The borders: the quadrants' outline, external, and the lines
   between them, internal.

   Text the chart cannot hold, a long title or point text near its
   edge, widens or heightens the drawing (decision 18): its bounds are
   the chart's and every text's and point's, and everything is moved
   for them to start at (0, 0).

   The colours are resolved here, from the theme (PmStyle's
   QuadrantColours) and the points' styles. PmQuadrantPic and
   PmQuadrantMp draw this layout, in Mermaid's order: the quadrants,
   each one's text, the borders, the points, each with its text, the
   axes' texts and the title. *)

IMPORT M := PmMetrics, F := PmFlow, S := PmStyle, Q := PmQuadrant;

CONST
  MermaidSize* = 16;      (* the quadrants' text, at the labels' size *)
  Hanging = 0; Middle = 1;
  (* a text's anchor *)
  Start* = 0; Centre* = 1;

TYPE
  (* A text: its middle at (x, y) and its start there (Start) or its
     middle; turned to read upward if rotated, its middle then on the
     vertical line x, its start or its middle at y *)
  Text* = POINTER TO TextDesc;
  TextDesc* = RECORD
    lab-: F.Label;
    x-, y-, size-, w-, h-: REAL;
    anchor-: INTEGER;
    rotated-: BOOLEAN;
    colour-: LONGINT
  END;

  Line* = RECORD
    x1-, y1-, x2-, y2-, width-: REAL;
    colour-: LONGINT
  END;

  Spot* = RECORD           (* a point *)
    x-, y-, r-: REAL;
    fill-, stroke-: LONGINT;  (* -1 for none *)
    strokeWidth-: REAL;
    text-: Text
  END;

  Spots* = POINTER TO ARRAY OF Spot;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: Q.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;      (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    (* the quadrants, 1 .. 4: top left corner, size, fill and text *)
    qx-, qy-: ARRAY 5 OF REAL;
    qw-, qh-: REAL;
    qFill-: ARRAY 5 OF LONGINT;
    qText-: ARRAY 5 OF Text;    (* or NIL *)
    border-: ARRAY 6 OF Line;   (* top, right, bottom, left, then the inner two *)
    nPoints-: INTEGER;
    point-: Spots;              (* in drawing order *)
    axis-: ARRAY 4 OF Text;     (* x left, x right, y bottom, y top; or NIL *)
    title-: Text                (* or NIL *)
  END;

VAR
  l: Layout;
  px: REAL;
  minX, minY, maxX, maxY: REAL;

PROCEDURE Max(a, b: REAL): REAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

PROCEDURE Empty(lab: F.Label): BOOLEAN;
BEGIN
  RETURN (lab = NIL) OR (lab.n = 0)
END Empty;

(* Adds the box from (x0, y0) to (x1, y1) to the bounds *)
PROCEDURE Bound(x0, y0, x1, y1: REAL);
BEGIN
  IF x0 < minX THEN minX := x0 END;
  IF y0 < minY THEN minY := y0 END;
  IF x1 > maxX THEN maxX := x1 END;
  IF y1 > maxY THEN maxY := y1 END
END Bound;

(* lab, size Mermaid pixels, at (x, y) in Mermaid pixels, by Mermaid's
   anchor and baseline; NIL for no text *)
PROCEDURE NewText(lab: F.Label; x, y, size: REAL; anchor, base: INTEGER;
  rotated: BOOLEAN; colour: LONGINT): Text;
  VAR t: Text;
BEGIN
  IF Empty(lab) THEN RETURN NIL END;
  NEW(t); t.lab := lab; t.size := size * px; t.anchor := anchor;
  t.rotated := rotated; t.colour := colour;
  M.LabelSize(l.font, lab, t.size, t.size * 1.2, t.w, t.h);
  t.x := x * px; t.y := y * px;
  IF base = Hanging THEN
    IF rotated THEN t.x := t.x + t.size / 2 ELSE t.y := t.y + t.size / 2 END
  END;
  RETURN t
END NewText;

(* Adds t's box to the bounds *)
PROCEDURE TextBound(t: Text);
  VAR a, b: REAL;
BEGIN
  IF t = NIL THEN RETURN END;
  IF t.anchor = Start THEN a := 0; b := t.w ELSE a := -t.w / 2; b := t.w / 2 END;
  IF t.rotated THEN Bound(t.x - t.h / 2, t.y - b, t.x + t.h / 2, t.y - a)
  ELSE Bound(t.x + a, t.y - t.h / 2, t.x + b, t.y + t.h / 2)
  END
END TextBound;

PROCEDURE Move(t: Text; dx, dy: REAL);
BEGIN
  IF t # NIL THEN t.x := t.x + dx; t.y := t.y + dy END
END Move;

PROCEDURE SetLine(VAR ln: Line; x1, y1, x2, y2, width: REAL; colour: LONGINT);
BEGIN
  ln.x1 := x1 * px; ln.y1 := y1 * px; ln.x2 := x2 * px; ln.y2 := y2 * px;
  ln.width := width * px; ln.colour := colour
END SetLine;

(* Lays d out, its text set in font at size points, into lay *)
PROCEDURE Make*(d: Q.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR
    t: S.QuadrantTheme; st: Q.Styles; p: Q.Point;
    showX, showY, showTitle, xTop, middle: BOOLEAN;
    xTopSpace, xBottomSpace, yLeftSpace, yRightSpace, titleSpace,
    qLeft, qTop, qW, qH, halfW, halfH, hw, ax, ay, dx, dy, r: REAL;
    k, anchor: INTEGER;
BEGIN
  NEW(l); lay := l; l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := px;
  S.Reset(d.g, px); S.QuadrantColours(t);
  showX := ~Empty(d.xLeft) OR ~Empty(d.xRight);
  showY := ~Empty(d.yBottom) OR ~Empty(d.yTop);
  showTitle := ~Empty(d.g.title);
  xTop := d.xAxisTop & (d.nPoints = 0);
  xTopSpace := 0; xBottomSpace := 0; yLeftSpace := 0; yRightSpace := 0; titleSpace := 0;
  IF showX THEN
    IF xTop THEN xTopSpace := 2 * d.xAxisLabelPadding + d.xAxisLabelFontSize
    ELSE xBottomSpace := 2 * d.xAxisLabelPadding + d.xAxisLabelFontSize
    END
  END;
  IF showY THEN
    IF d.yAxisLeft THEN yLeftSpace := 2 * d.yAxisLabelPadding + d.yAxisLabelFontSize
    ELSE yRightSpace := 2 * d.yAxisLabelPadding + d.yAxisLabelFontSize
    END
  END;
  IF showTitle THEN titleSpace := d.titleFontSize + 2 * d.titlePadding END;
  qLeft := d.quadrantPadding + yLeftSpace;
  qTop := d.quadrantPadding + xTopSpace + titleSpace;
  qW := d.chartWidth - 2 * d.quadrantPadding - yLeftSpace - yRightSpace;
  qH := d.chartHeight - 2 * d.quadrantPadding - xTopSpace - xBottomSpace - titleSpace;
  halfW := qW / 2; halfH := qH / 2;
  (* the quadrants *)
  l.qw := halfW * px; l.qh := halfH * px;
  FOR k := 1 TO 4 DO
    IF (k = 1) OR (k = 4) THEN ax := qLeft + halfW ELSE ax := qLeft END;
    IF k <= 2 THEN ay := qTop ELSE ay := qTop + halfH END;
    l.qx[k] := ax * px; l.qy[k] := ay * px; l.qFill[k] := t.fill[k];
    IF d.nPoints = 0 THEN
      l.qText[k] := NewText(d.quadrant[k], ax + halfW / 2, ay + halfH / 2,
        d.quadrantLabelFontSize, Centre, Middle, FALSE, t.text[k])
    ELSE
      l.qText[k] := NewText(d.quadrant[k], ax + halfW / 2, ay + d.quadrantTextTopPadding,
        d.quadrantLabelFontSize, Centre, Hanging, FALSE, t.text[k])
    END
  END;
  (* the borders *)
  hw := d.externalBorder / 2;
  SetLine(l.border[0], qLeft - hw, qTop, qLeft + qW + hw, qTop, d.externalBorder, t.external);
  SetLine(l.border[1], qLeft + qW, qTop + hw, qLeft + qW, qTop + qH - hw, d.externalBorder, t.external);
  SetLine(l.border[2], qLeft - hw, qTop + qH, qLeft + qW + hw, qTop + qH, d.externalBorder, t.external);
  SetLine(l.border[3], qLeft, qTop + hw, qLeft, qTop + qH - hw, d.externalBorder, t.external);
  SetLine(l.border[4], qLeft + halfW, qTop + hw, qLeft + halfW, qTop + qH - hw,
    d.internalBorder, t.internal);
  SetLine(l.border[5], qLeft + hw, qTop + halfH, qLeft + qW - hw, qTop + halfH,
    d.internalBorder, t.internal);
  (* the points *)
  l.nPoints := d.nPoints; NEW(l.point, d.nPoints + 1);
  p := d.points; k := 0;
  WHILE p # NIL DO
    Q.PointStyles(d, p, st);
    ax := qLeft + p.x * qW; ay := qTop + qH - p.y * qH;
    l.point[k].x := ax * px; l.point[k].y := ay * px;
    IF st.radius >= 0 THEN r := st.radius ELSE r := d.pointRadius END;
    l.point[k].r := r * px;
    IF st.colour >= 0 THEN l.point[k].fill := st.colour
    ELSIF st.colour = Q.Invalid THEN l.point[k].fill := t.textFill
    ELSE l.point[k].fill := t.pointFill
    END;
    IF st.stroke >= 0 THEN l.point[k].stroke := st.stroke
    ELSIF st.stroke = Q.Invalid THEN l.point[k].stroke := -1
    ELSE l.point[k].stroke := t.pointStroke
    END;
    IF st.strokeWidth >= 0 THEN l.point[k].strokeWidth := st.strokeWidth * px
    ELSE l.point[k].strokeWidth := 0
    END;
    IF l.point[k].strokeWidth <= 0 THEN l.point[k].stroke := -1 END;
    l.point[k].text := NewText(p.text, ax, ay + d.pointTextPadding, d.pointLabelFontSize,
      Centre, Hanging, FALSE, t.pointText);
    p := p.next; INC(k)
  END;
  (* the axes' texts *)
  FOR k := 0 TO 3 DO l.axis[k] := NIL END;
  IF showX THEN
    middle := ~Empty(d.xRight);
    IF middle THEN anchor := Centre ELSE anchor := Start END;
    IF xTop THEN ay := d.xAxisLabelPadding + titleSpace
    ELSE ay := d.xAxisLabelPadding + qTop + qH + d.quadrantPadding
    END;
    IF middle THEN dx := halfW / 2 ELSE dx := 0 END;
    l.axis[0] := NewText(d.xLeft, qLeft + dx, ay, d.xAxisLabelFontSize, anchor, Hanging,
      FALSE, t.xAxis);
    l.axis[1] := NewText(d.xRight, qLeft + halfW + dx, ay, d.xAxisLabelFontSize, anchor,
      Hanging, FALSE, t.xAxis)
  END;
  IF showY THEN
    middle := ~Empty(d.yTop);
    IF middle THEN anchor := Centre; dy := halfH / 2 ELSE anchor := Start; dy := 0 END;
    IF d.yAxisLeft THEN ax := d.yAxisLabelPadding
    ELSE ax := d.yAxisLabelPadding + qLeft + qW + d.quadrantPadding
    END;
    l.axis[2] := NewText(d.yBottom, ax, qTop + qH - dy, d.yAxisLabelFontSize, anchor,
      Hanging, TRUE, t.yAxis);
    l.axis[3] := NewText(d.yTop, ax, qTop + halfH - dy, d.yAxisLabelFontSize, anchor,
      Hanging, TRUE, t.yAxis)
  END;
  (* the title *)
  l.title := NIL;
  IF showTitle THEN
    l.title := NewText(d.g.title, d.chartWidth / 2, d.titlePadding, d.titleFontSize, Centre,
      Hanging, FALSE, t.title)
  END;
  (* the bounds, and everything moved for them *)
  minX := 0; minY := 0; maxX := d.chartWidth * px; maxY := d.chartHeight * px;
  FOR k := 1 TO 4 DO TextBound(l.qText[k]) END;
  FOR k := 0 TO l.nPoints - 1 DO
    r := l.point[k].r + l.point[k].strokeWidth / 2;
    Bound(l.point[k].x - r, l.point[k].y - r, l.point[k].x + r, l.point[k].y + r);
    TextBound(l.point[k].text)
  END;
  FOR k := 0 TO 3 DO TextBound(l.axis[k]) END;
  TextBound(l.title);
  dx := -minX; dy := -minY;
  l.width := maxX - minX; l.height := maxY - minY;
  IF (dx # 0) OR (dy # 0) THEN
    FOR k := 1 TO 4 DO l.qx[k] := l.qx[k] + dx; l.qy[k] := l.qy[k] + dy; Move(l.qText[k], dx, dy) END;
    FOR k := 0 TO 5 DO
      l.border[k].x1 := l.border[k].x1 + dx; l.border[k].x2 := l.border[k].x2 + dx;
      l.border[k].y1 := l.border[k].y1 + dy; l.border[k].y2 := l.border[k].y2 + dy
    END;
    FOR k := 0 TO l.nPoints - 1 DO
      l.point[k].x := l.point[k].x + dx; l.point[k].y := l.point[k].y + dy;
      Move(l.point[k].text, dx, dy)
    END;
    FOR k := 0 TO 3 DO Move(l.axis[k], dx, dy) END;
    Move(l.title, dx, dy)
  END
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: Q.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
  VAR k: INTEGER;
BEGIN
  Make(d, font, size, lay); k := 0;
  WHILE (maxW > 0) & (lay.width > maxW) & (k < 5) & (size > 0.2) DO
    size := ENTIER(size * maxW / lay.width * 10) / 10;
    IF size >= lay.size THEN size := lay.size - 0.1 END;
    IF size < 0.1 THEN size := 0.1 END;
    Make(d, font, size, lay); INC(k)
  END
END Fit;

END PmQuadrantLayout.
