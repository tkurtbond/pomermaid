MODULE PmQuadrantDump;
(* PmQuadrantDump: a quadrant chart's model, PmQuadrant's, written as
   text, one line for the title, each configuration value, the
   settings, each quadrant, each axis, each class and each point, for
   the tests (-t dump); and its layout, PmQuadrantLayout's (-t layout) *)

IMPORT PmIO, Y := PmYaml, F := PmFlow, Q := PmQuadrant, D := PmDump,
  QL := PmQuadrantLayout, P := PmPic;

PROCEDURE Num(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Num;

PROCEDURE Pt(name: ARRAY OF CHAR; x, y: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteString("=(");
  PmIO.WriteReal(x, 2); PmIO.WriteChar(","); PmIO.WriteReal(y, 2); PmIO.WriteChar(")")
END Pt;

(* " name=#rrggbb", "invalid" or "none"; nothing for NoColour if skip *)
PROCEDURE Colour(name: ARRAY OF CHAR; c: LONGINT; skip: BOOLEAN);
BEGIN
  IF skip & (c = Q.NoColour) THEN RETURN END;
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF c = Q.Invalid THEN PmIO.WriteString("invalid")
  ELSIF c < 0 THEN PmIO.WriteString("none")
  ELSE PmIO.WriteChar("#"); P.Hex(c, 6)
  END
END Colour;

PROCEDURE Int(name: ARRAY OF CHAR; x: LONGINT);
BEGIN
  IF x >= 0 THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteInt(x)
  END
END Int;

PROCEDURE Styles(VAR st: Q.Styles);
BEGIN
  Int("radius", st.radius); Colour("color", st.colour, TRUE);
  Colour("stroke", st.stroke, TRUE); Int("strokeWidth", st.strokeWidth)
END Styles;

PROCEDURE Axis(name: ARRAY OF CHAR; a, b: F.Label);
BEGIN
  IF (a # NIL) OR (b # NIL) THEN
    PmIO.WriteString(name);
    IF a # NIL THEN D.Label("from", a) END;
    IF b # NIL THEN D.Label("to", b) END;
    PmIO.WriteLn
  END
END Axis;

(* Writes d's model *)
PROCEDURE Write*(d: Q.Diagram);
  VAR q: Y.Pair; c: Q.Class; p: Q.Point; k: INTEGER;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("quadrantChart");
  Num("width", d.chartWidth); Num("height", d.chartHeight);
  IF d.xAxisTop THEN PmIO.WriteString(" xAxis=top") ELSE PmIO.WriteString(" xAxis=bottom") END;
  IF d.yAxisLeft THEN PmIO.WriteString(" yAxis=left") ELSE PmIO.WriteString(" yAxis=right") END;
  PmIO.WriteLn;
  PmIO.WriteString("sizes");
  Num("titlePadding", d.titlePadding); Num("titleFontSize", d.titleFontSize);
  Num("quadrantPadding", d.quadrantPadding); Num("quadrantTextTopPadding", d.quadrantTextTopPadding);
  Num("quadrantLabelFontSize", d.quadrantLabelFontSize);
  Num("xAxisLabelPadding", d.xAxisLabelPadding); Num("yAxisLabelPadding", d.yAxisLabelPadding);
  Num("xAxisLabelFontSize", d.xAxisLabelFontSize); Num("yAxisLabelFontSize", d.yAxisLabelFontSize);
  Num("pointTextPadding", d.pointTextPadding); Num("pointLabelFontSize", d.pointLabelFontSize);
  Num("pointRadius", d.pointRadius); Num("internalBorder", d.internalBorder);
  Num("externalBorder", d.externalBorder);
  PmIO.WriteLn;
  FOR k := 1 TO 4 DO
    IF d.quadrant[k] # NIL THEN
      PmIO.WriteString("quadrant "); PmIO.WriteInt(k); D.Label("text", d.quadrant[k]); PmIO.WriteLn
    END
  END;
  Axis("x-axis", d.xLeft, d.xRight);
  Axis("y-axis", d.yBottom, d.yTop);
  c := d.classes;
  WHILE c # NIL DO
    PmIO.WriteString("classDef "); PmIO.WriteString(c.name^); Styles(c.st); PmIO.WriteLn;
    c := c.next
  END;
  p := d.points;
  WHILE p # NIL DO
    PmIO.WriteString("point"); D.Label("text", p.text); Pt("at", p.x, p.y);
    IF p.class # NIL THEN PmIO.WriteString(" class="); PmIO.WriteString(p.class^) END;
    Styles(p.st); PmIO.WriteLn;
    p := p.next
  END
END Write;

PROCEDURE Text(name: ARRAY OF CHAR; t: QL.Text);
BEGIN
  IF t = NIL THEN RETURN END;
  PmIO.WriteString(name); Pt("at", t.x, t.y); Num("size", t.size); Num("w", t.w);
  IF t.anchor = QL.Start THEN PmIO.WriteString(" start") ELSE PmIO.WriteString(" centre") END;
  IF t.rotated THEN PmIO.WriteString(" rotated") END;
  Colour("colour", t.colour, FALSE); D.Label("text", t.lab); PmIO.WriteLn
END Text;

(* Writes the layout l (-t layout): its size; each quadrant, border,
   point and text; in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: QL.Layout);
  VAR k: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Num("width", l.width); Num("height", l.height); PmIO.WriteLn;
  FOR k := 1 TO 4 DO
    PmIO.WriteString("quadrant "); PmIO.WriteInt(k); Pt("at", l.qx[k], l.qy[k]);
    Num("w", l.qw); Num("h", l.qh); Colour("fill", l.qFill[k], FALSE); PmIO.WriteLn;
    Text("  text", l.qText[k])
  END;
  FOR k := 0 TO 5 DO
    PmIO.WriteString("border"); Pt("from", l.border[k].x1, l.border[k].y1);
    Pt("to", l.border[k].x2, l.border[k].y2); Num("width", l.border[k].width);
    Colour("colour", l.border[k].colour, FALSE); PmIO.WriteLn
  END;
  FOR k := 0 TO l.nPoints - 1 DO
    PmIO.WriteString("point"); Pt("at", l.point[k].x, l.point[k].y); Num("r", l.point[k].r);
    Colour("fill", l.point[k].fill, FALSE); Colour("stroke", l.point[k].stroke, FALSE);
    Num("strokeWidth", l.point[k].strokeWidth); PmIO.WriteLn;
    Text("  text", l.point[k].text)
  END;
  Text("x-axis left", l.axis[0]); Text("x-axis right", l.axis[1]);
  Text("y-axis bottom", l.axis[2]); Text("y-axis top", l.axis[3]);
  Text("title", l.title)
END WriteLayout;

END PmQuadrantDump.
