MODULE PmRadarDump;
(* PmRadarDump: a radar chart's model, PmRadar's, written as text, one
   line for the title, each configuration value, the chart's options
   and configuration, each axis and each curve and its values, for the
   tests (-t dump); and its layout, PmRadarLayout's (-t layout) *)

IMPORT PmIO, Y := PmYaml, R := PmRadar, X := PmXy, D := PmDump, RL := PmRadarLayout,
  P := PmPic, G := PmGeom;

PROCEDURE Num(name: ARRAY OF CHAR; x: LONGREAL);
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  X.JsNumber(x, s);
  PmIO.WriteChar(" ");
  IF name # "" THEN PmIO.WriteString(name); PmIO.WriteChar("=") END;
  PmIO.WriteString(s)
END Num;

PROCEDURE Bool(name: ARRAY OF CHAR; b: BOOLEAN);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF b THEN PmIO.WriteString("true") ELSE PmIO.WriteString("false") END
END Bool;

(* Writes d's model *)
PROCEDURE Write*(d: R.Diagram);
  VAR q: Y.Pair; a: R.Axis; c: R.Curve; k: LONGINT;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("radar");
  Bool("showLegend", d.showLegend); Num("ticks", d.ticks);
  IF d.hasMax THEN Num("max", d.max) END;
  Num("min", d.min);
  IF d.polygon THEN PmIO.WriteString(" graticule=polygon") ELSE PmIO.WriteString(" graticule=circle") END;
  Num("width", d.width); Num("height", d.height);
  Num("marginTop", d.marginTop); Num("marginRight", d.marginRight);
  Num("marginBottom", d.marginBottom); Num("marginLeft", d.marginLeft);
  Num("axisScaleFactor", d.axisScaleFactor); Num("axisLabelFactor", d.axisLabelFactor);
  Num("curveTension", d.curveTension);
  PmIO.WriteLn;
  a := d.axes;
  WHILE a # NIL DO
    PmIO.WriteString("axis "); PmIO.WriteString(a.name^); D.Label("label", a.label); PmIO.WriteLn;
    a := a.next
  END;
  c := d.curves;
  WHILE c # NIL DO
    PmIO.WriteString("curve "); PmIO.WriteInt(c.index); PmIO.WriteChar(" ");
    PmIO.WriteString(c.name^); D.Label("label", c.label);
    PmIO.WriteString(" values");
    FOR k := 0 TO c.n - 1 DO Num("", c.value[k]) END;
    PmIO.WriteLn;
    c := c.next
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

PROCEDURE Colour(name: ARRAY OF CHAR; c: LONGINT);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF c < 0 THEN PmIO.WriteString("none") ELSE PmIO.WriteChar("#"); P.Hex(c, 6) END
END Colour;

PROCEDURE Points(p: G.Points; n: INTEGER);
  VAR k: INTEGER;
BEGIN
  FOR k := 0 TO n - 1 DO Pt("", p[k].x, p[k].y) END
END Points;

(* Writes the layout l (-t layout): its size and each item, in drawing
   order, in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: RL.Layout);
  VAR it: RL.Item; k: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Real("width", l.width); Real("height", l.height); PmIO.WriteLn;
  it := l.items;
  WHILE it # NIL DO
    IF it.kind = RL.Shape THEN
      IF it.form = RL.Circle THEN
        PmIO.WriteString("circle"); Pt("at", it.x, it.y); Real("r", it.r)
      ELSIF it.form = RL.Polygon THEN
        PmIO.WriteString("polygon"); Points(it.p, it.n)
      ELSE
        PmIO.WriteString("curve");
        FOR k := 0 TO it.n - 1 DO
          Pt("", it.p[k].x, it.p[k].y); PmIO.WriteString(" ..");
          Pt("", it.c1[k].x, it.c1[k].y); Pt("", it.c2[k].x, it.c2[k].y); PmIO.WriteString(" ..")
        END
      END;
      Colour("fill", it.fill); Colour("line", it.line); Real("width", it.width)
    ELSIF it.kind = RL.Line THEN
      PmIO.WriteString("line"); Points(it.p, it.n); Colour("line", it.line); Real("width", it.width)
    ELSIF it.kind = RL.Rect THEN
      PmIO.WriteString("rect"); Pt("at", it.x, it.y); Real("w", it.w); Real("h", it.h);
      Colour("fill", it.fill); Colour("line", it.line); Real("width", it.width)
    ELSE
      PmIO.WriteString("text"); Pt("at", it.x, it.y); Real("size", it.size); Real("w", it.w);
      IF it.anchor = RL.Start THEN PmIO.WriteString(" start")
      ELSIF it.anchor = RL.End THEN PmIO.WriteString(" end")
      ELSE PmIO.WriteString(" centre")
      END;
      Colour("colour", it.line); D.Label("text", it.lab)
    END;
    PmIO.WriteLn;
    it := it.next
  END
END WriteLayout;

END PmRadarDump.
