MODULE PmDrawDump;
(* PmDrawDump: a drawing, PmDraw's, written as text, for the tests
   (-t layout) *)

IMPORT PmIO, D := PmDraw, PmDump, P := PmPic;

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

(* Writes the layout l (-t layout): its size and each item, in drawing
   order, in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: D.Drawing);
  VAR it: D.Item; k: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Real("width", l.width); Real("height", l.height); PmIO.WriteLn;
  it := l.items;
  WHILE it # NIL DO
    IF it.kind = D.Circle THEN
      PmIO.WriteString("circle"); Pt("at", it.x, it.y); Real("r", it.r)
    ELSIF it.kind = D.Rect THEN
      PmIO.WriteString("rect"); Pt("at", it.x, it.y); Real("w", it.w); Real("h", it.h);
      IF it.r # 0 THEN Real("r", it.r) END
    ELSIF it.kind = D.Text THEN
      PmIO.WriteString("text"); Pt("at", it.x, it.y); Real("size", it.size); Real("w", it.w);
      IF it.angle # 0 THEN Real("angle", it.angle) END;
      IF it.fit THEN PmIO.WriteString(" fit") END
    ELSE
      IF it.kind = D.Poly THEN PmIO.WriteString("poly")
      ELSIF it.kind = D.Line THEN PmIO.WriteString("line")
      ELSE PmIO.WriteString("curve")
      END;
      FOR k := 0 TO it.n - 1 DO Pt("", it.p[k].x, it.p[k].y) END;
      IF it.dash # 0 THEN Real("dash", it.dash) END
    END;
    IF it.kind # D.Text THEN Colour("fill", it.fill) END;
    Colour("line", it.line);
    IF it.width # 0 THEN Real("width", it.width) END;
    IF it.kind = D.Text THEN PmDump.Label("text", it.lab) END;
    PmIO.WriteLn;
    it := it.next
  END
END WriteLayout;

END PmDrawDump.
