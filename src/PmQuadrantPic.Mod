MODULE PmQuadrantPic;
(* PmQuadrantPic: a laid out quadrant chart, PmQuadrantLayout's,
   written in pic, for groff, with PmPic's helpers, in Mermaid's order:
   the quadrants, each a box in its fill and its text; the borders; the
   points, each a circle and its text; the axes' texts, the y axis's
   turned to read upward; and the title. *)

IMPORT PmIO, S := PmStyle, P := PmPic, QL := PmQuadrantLayout;

CONST
  NoColour = S.NoColour;

TYPE
  Style = S.Style;

VAR
  l: QL.Layout;

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* st: filled with fill, its line line, width points wide *)
PROCEDURE Make(VAR st: Style; fill, line: LONGINT; width: REAL);
BEGIN
  st.fill := C(fill); st.line := C(line); st.text := NoColour; st.inner := NoColour;
  st.width := width; st.dash := 0;
  IF width <= 0 THEN st.line := NoColour END
END Make;

(* Registers the colour of the text t, if any *)
PROCEDURE Register(t: QL.Text);
  VAR c: INTEGER;
BEGIN
  IF t # NIL THEN c := C(t.colour) END
END Register;

(* The text t, if any *)
PROCEDURE Text(t: QL.Text);
  VAR c: INTEGER; a, b: REAL;
BEGIN
  IF t = NIL THEN RETURN END;
  c := C(t.colour);
  IF t.rotated THEN
    IF t.anchor = QL.Start THEN a := t.y; b := t.y - t.w
    ELSE a := t.y + t.w / 2; b := t.y - t.w / 2
    END;
    P.Rotated(t.lab, t.x, a, b, c, t.size)
  ELSIF t.anchor = QL.Start THEN P.Anchored(t.lab, t.x, t.y, c, t.size, P.Left)
  ELSE P.Anchored(t.lab, t.x, t.y, c, t.size, P.Centre)
  END
END Text;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: QL.Layout): REAL;
  VAR w: REAL; k: INTEGER;
BEGIN
  w := 0;
  FOR k := 0 TO 5 DO IF lay.border[k].width > w THEN w := lay.border[k].width END END;
  FOR k := 0 TO lay.nPoints - 1 DO
    IF lay.point[k].strokeWidth > w THEN w := lay.point[k].strokeWidth END
  END;
  RETURN w
END Widest;

(* Writes lay's quadrant chart in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: QL.Layout; font: ARRAY OF CHAR);
  VAR
    k: INTEGER; colour: ARRAY 6 OF INTEGER;
    qSt: ARRAY 5 OF Style; pointSt: POINTER TO ARRAY OF Style;
BEGIN
  l := lay;
  P.Setup(font, l.font, l.px);
  S.Reset(l.d.g, l.px);
  (* the colours, all known before P.Begin defines them *)
  FOR k := 1 TO 4 DO Make(qSt[k], l.qFill[k], -1, 0); Register(l.qText[k]) END;
  FOR k := 0 TO 5 DO colour[k] := C(l.border[k].colour) END;
  NEW(pointSt, l.nPoints + 1);
  FOR k := 0 TO l.nPoints - 1 DO
    Make(pointSt[k], l.point[k].fill, l.point[k].stroke, l.point[k].strokeWidth);
    Register(l.point[k].text)
  END;
  FOR k := 0 TO 3 DO Register(l.axis[k]) END;
  Register(l.title);
  P.Begin(l.size, l.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(l.width); P.W(" ht "); P.In(l.height);
  P.At(l.width / 2, l.height / 2); PmIO.WriteLn;
  FOR k := 1 TO 4 DO
    P.W("box wid "); P.In(l.qw); P.W(" ht "); P.In(l.qh);
    P.At(l.qx[k] + l.qw / 2, l.qy[k] + l.qh / 2); P.Paint(qSt[k], TRUE); PmIO.WriteLn;
    Text(l.qText[k])
  END;
  FOR k := 0 TO 5 DO
    IF (colour[k] # NoColour) & (l.border[k].width > 0) THEN
      P.W("line from "); P.Pt(l.border[k].x1, l.border[k].y1); P.W(" to ");
      P.Pt(l.border[k].x2, l.border[k].y2); P.W(" outlined "); P.ColourName(colour[k]);
      P.W(" thickness "); PmIO.WriteReal(l.border[k].width, 3); PmIO.WriteLn
    END
  END;
  FOR k := 0 TO l.nPoints - 1 DO
    P.W("circle rad "); P.In(l.point[k].r); P.At(l.point[k].x, l.point[k].y);
    P.Paint(pointSt[k], TRUE); PmIO.WriteLn;
    Text(l.point[k].text)
  END;
  FOR k := 0 TO 3 DO Text(l.axis[k]) END;
  Text(l.title);
  P.End
END Write;

END PmQuadrantPic.
