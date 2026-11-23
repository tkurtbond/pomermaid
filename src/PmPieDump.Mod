MODULE PmPieDump;
(* PmPieDump: a pie chart's model, PmPie's, written as text, one line
   for the title, each configuration value, the settings and each
   section, for the tests (-t dump); and its layout, PmPieLayout's
   (-t layout) *)

IMPORT PmIO, Y := PmYaml, P := PmPie, D := PmDump, PL := PmPieLayout;

(* Writes d's model *)
PROCEDURE Write*(d: P.Diagram);
  VAR q: Y.Pair; s: P.Section;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("pie");
  IF d.showData THEN PmIO.WriteString(" showData") END;
  PmIO.WriteString(" textPosition="); PmIO.WriteReal(d.textPosition, 2);
  PmIO.WriteString(" donutHole="); PmIO.WriteReal(d.donutHole, 2);
  PmIO.WriteString(" legend=");
  CASE d.legend OF
    P.Right: PmIO.WriteString("right")
  | P.Left: PmIO.WriteString("left")
  | P.Top: PmIO.WriteString("top")
  | P.Bottom: PmIO.WriteString("bottom")
  | P.Center: PmIO.WriteString("center")
  END;
  IF d.highlight # NIL THEN PmIO.WriteString(" highlight="); D.Quoted(d.highlight) END;
  PmIO.WriteLn;
  s := d.sections;
  WHILE s # NIL DO
    PmIO.WriteString("section "); PmIO.WriteInt(s.index);
    PmIO.WriteString(" value="); PmIO.WriteString(s.shown^);
    D.Label("text", s.text); PmIO.WriteLn;
    s := s.next
  END
END Write;

PROCEDURE Num(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Num;

PROCEDURE Pt(name: ARRAY OF CHAR; x, y: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteString("=(");
  PmIO.WriteReal(x, 2); PmIO.WriteChar(","); PmIO.WriteReal(y, 2); PmIO.WriteChar(")")
END Pt;

(* Writes the layout l (-t layout): its size; the pie; each slice's
   angles, in degrees, colour and percentage; each legend item; the
   title; in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: PL.Layout);
  VAR i: INTEGER; deg: REAL;
BEGIN
  deg := 180 / 3.14159265;
  PmIO.WriteString("layout"); Num("width", l.width); Num("height", l.height); PmIO.WriteLn;
  PmIO.WriteString("pie"); Pt("centre", l.cx, l.cy); Num("r", l.r); Num("hole", l.hole);
  PmIO.WriteLn;
  FOR i := 0 TO l.nSlices - 1 DO
    PmIO.WriteString("slice"); Num("from", l.a0[i] * deg); Num("to", l.a1[i] * deg);
    PmIO.WriteString(" colour="); PmIO.WriteInt(l.colour[i]);
    IF l.highlighted[i] THEN PmIO.WriteString(" highlighted") END;
    Pt("text", l.tx[i], l.ty[i]); D.Label("percent", l.percent[i]); PmIO.WriteLn
  END;
  FOR i := 0 TO l.n - 1 DO
    PmIO.WriteString("legend colour="); PmIO.WriteInt(l.legendColour[i]);
    Pt("box", l.bx[i], l.by[i]); Pt("text", l.lx[i], l.ly[i]);
    D.Label("text", l.text[i]); PmIO.WriteLn
  END;
  IF l.title # NIL THEN
    PmIO.WriteString("title"); Pt("at", l.titleX, l.titleY); Num("w", l.titleW);
    Num("size", l.titleSize); PmIO.WriteLn
  END
END WriteLayout;

END PmPieDump.
