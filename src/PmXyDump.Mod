MODULE PmXyDump;
(* PmXyDump: an XY chart's model, PmXy's, written as text, one line
   for the title, each configuration value, the chart's settings, each
   axis's, the axes and each plot and its data, for the tests
   (-t dump); and its layout, PmXyLayout's (-t layout) *)

IMPORT PmIO, Y := PmYaml, F := PmFlow, X := PmXy, D := PmDump, XL := PmXyLayout, P := PmPic;

PROCEDURE Num(name: ARRAY OF CHAR; x: LONGREAL);
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  X.JsNumber(x, s);
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteString(s)
END Num;

PROCEDURE Bool(name: ARRAY OF CHAR; b: BOOLEAN);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF b THEN PmIO.WriteString("true") ELSE PmIO.WriteString("false") END
END Bool;

PROCEDURE AxisConfig(name: ARRAY OF CHAR; VAR a: X.AxisConfig);
BEGIN
  PmIO.WriteString(name);
  Bool("showLabel", a.showLabel); Num("labelFontSize", a.labelFontSize);
  Num("labelPadding", a.labelPadding); Bool("showTitle", a.showTitle);
  Num("titleFontSize", a.titleFontSize); Num("titlePadding", a.titlePadding);
  Bool("showTick", a.showTick); Num("tickLength", a.tickLength);
  Num("tickWidth", a.tickWidth); Bool("showAxisLine", a.showAxisLine);
  Num("axisLineWidth", a.axisLineWidth); Num("labelRotation", a.labelRotation);
  PmIO.WriteLn
END AxisConfig;

PROCEDURE Axis(name: ARRAY OF CHAR; VAR a: X.Axis);
  VAR k: LONGINT;
BEGIN
  PmIO.WriteString(name);
  IF a.title # NIL THEN D.Label("title", a.title) END;
  IF a.linear THEN
    PmIO.WriteString(" linear");
    IF a.min <= a.max THEN Num("min", a.min); Num("max", a.max) END
  ELSE
    PmIO.WriteString(" band");
    FOR k := 0 TO a.nCat - 1 DO
      IF a.cat[k] = NIL THEN PmIO.WriteString(' cat=""') ELSE D.Label("cat", a.cat[k]) END
    END
  END;
  PmIO.WriteLn
END Axis;

(* Writes d's model *)
PROCEDURE Write*(d: X.Diagram);
  VAR q: Y.Pair; p: X.Plot; k: LONGINT;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("xychart");
  IF d.horizontal THEN PmIO.WriteString(" horizontal") ELSE PmIO.WriteString(" vertical") END;
  Num("width", d.width); Num("height", d.height);
  Num("titleFontSize", d.titleFontSize); Num("titlePadding", d.titlePadding);
  Bool("showTitle", d.showTitle); Bool("showLegend", d.showLegend);
  Num("legendFontSize", d.legendFontSize); Num("legendPadding", d.legendPadding);
  Bool("showDataLabel", d.showDataLabel); Bool("showDataLabelOutsideBar", d.outside);
  Num("plotReservedSpacePercent", d.reserved);
  PmIO.WriteLn;
  AxisConfig("xAxis", d.axis[0]); AxisConfig("yAxis", d.axis[1]);
  Axis("x-axis", d.x); Axis("y-axis", d.y);
  p := d.plots;
  WHILE p # NIL DO
    IF p.bar THEN PmIO.WriteString("bar") ELSE PmIO.WriteString("line") END;
    PmIO.WriteString(" "); PmIO.WriteInt(p.index);
    IF p.title # NIL THEN D.Label("title", p.title) END;
    PmIO.WriteLn;
    FOR k := 0 TO p.n - 1 DO
      PmIO.WriteString("  ");
      D.Quoted(p.data[k].key);
      IF p.data[k].def THEN PmIO.WriteChar(" "); PmIO.WriteString(p.data[k].shown^)
      ELSE PmIO.WriteString(" none")
      END;
      IF p.data[k].label # NIL THEN D.Label("label", p.data[k].label) END;
      PmIO.WriteLn
    END;
    p := p.next
  END
END Write;

PROCEDURE Real(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Real;

PROCEDURE Pt(name: ARRAY OF CHAR; x, y: REAL);
BEGIN
  PmIO.WriteChar(" ");
  IF name # "" THEN PmIO.WriteString(name); PmIO.WriteChar("=") END;
  PmIO.WriteChar("(");
  PmIO.WriteReal(x, 2); PmIO.WriteChar(","); PmIO.WriteReal(y, 2); PmIO.WriteChar(")")
END Pt;

PROCEDURE Colour(c: LONGINT);
BEGIN
  PmIO.WriteString(" colour=");
  IF c < 0 THEN PmIO.WriteString("none") ELSE PmIO.WriteChar("#"); P.Hex(c, 6) END
END Colour;

(* Writes the layout l (-t layout): its size and each item, in drawing
   order, in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: XL.Layout);
  VAR it: XL.Item; k: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Real("width", l.width); Real("height", l.height); PmIO.WriteLn;
  it := l.items;
  WHILE it # NIL DO
    IF it.kind = XL.Rect THEN
      PmIO.WriteString("rect"); Pt("at", it.x, it.y); Real("w", it.w); Real("h", it.h)
    ELSIF it.kind = XL.Path THEN
      PmIO.WriteString("path");
      FOR k := 0 TO it.n - 1 DO Pt("", it.p[k].x, it.p[k].y) END;
      Real("width", it.width)
    ELSE
      PmIO.WriteString("text"); Pt("at", it.x, it.y); Real("size", it.size); Real("w", it.w);
      IF it.anchor = XL.Start THEN PmIO.WriteString(" start")
      ELSIF it.anchor = XL.End THEN PmIO.WriteString(" end")
      ELSE PmIO.WriteString(" centre")
      END;
      IF it.angle # 0 THEN Real("angle", it.angle) END
    END;
    Colour(it.colour);
    IF it.kind = XL.Text THEN D.Label("text", it.lab) END;
    PmIO.WriteLn;
    it := it.next
  END
END WriteLayout;

END PmXyDump.
