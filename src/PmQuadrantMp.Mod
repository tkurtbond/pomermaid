MODULE PmQuadrantMp;
(* PmQuadrantMp: a laid out quadrant chart, PmQuadrantLayout's,
   written in MetaPost, for ConTeXt: a \startMPcode block that draws it
   as PmQuadrantPic does, in the same order and colours, with
   ConTeXt's text, textext's pictures, the y axis's turned 90 degrees.
   The places are PmQuadrantLayout's, in points; the drawing's bounds
   are the layout's, widened for any text ConTeXt sets wider than
   pomermaid measured it (decision 18). Text is written as PmMp writes
   it. *)

IMPORT PmIO, F := PmFlow, QL := PmQuadrantLayout, PmMp;

VAR
  l: QL.Layout;

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

PROCEDURE Ln;
BEGIN
  PmIO.WriteLn
END Ln;

(* x points *)
PROCEDURE Pt(x: REAL);
BEGIN
  PmIO.WriteReal(x, 3); W("pt")
END Pt;

(* The point (x, y), y down, as MetaPost's (x, -y) *)
PROCEDURE At(x, y: REAL);
BEGIN
  W("("); Pt(x); W(", "); Pt(-y); W(")")
END At;

(* The colour rgb, 0RRGGBBH, as a MetaPost colour; black for -1 *)
PROCEDURE Col(rgb: LONGINT);
BEGIN
  IF rgb < 0 THEN rgb := 0 END;
  W("("); PmIO.WriteReal(rgb DIV 10000H / 255, 4); W(",");
  PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); W(",");
  PmIO.WriteReal(rgb MOD 100H / 255, 4); W(")")
END Col;

(* lab as a picture, size points *)
PROCEDURE Picture(lab: F.Label; size: REAL);
BEGIN
  W('textext("\framed[frame=off,offset=0pt,align=flushleft]{" & ');
  PmMp.Label(lab); W(' & "}") scaled '); PmIO.WriteReal(size / l.size, 4)
END Picture;

(* The text t, if any *)
PROCEDURE Text(t: QL.Text);
BEGIN
  IF t = NIL THEN RETURN END;
  W("pmqtext("); Picture(t.lab, t.size);
  IF t.rotated THEN W(" rotated 90") END;
  W(", "); At(t.x, t.y); W(", ");
  IF t.rotated THEN PmIO.WriteInt(2 + t.anchor) ELSE PmIO.WriteInt(t.anchor) END;
  W(", "); Col(t.colour); W(");"); Ln
END Text;

(* Writes lay's quadrant chart as a \startMPcode block *)
PROCEDURE Write*(lay: QL.Layout);
  VAR k: INTEGER; s: QL.Spot;
BEGIN
  l := lay;
  W("\startMPcode"); Ln;
  W("numeric pmqx[]; picture pmqp;"); Ln;
  W("pmqx0 := 0; pmqx1 := "); Pt(-l.height); W("; pmqx2 := "); Pt(l.width);
  W("; pmqx3 := 0;"); Ln;
  (* the picture p at q: a = 0, the middle of its left side there; 1,
     its middle; 2, turned, the middle of its bottom; 3, turned, its
     middle; in the colour c; the bounds widened for it *)
  W("def pmqtext(expr p, q, a, c) ="); Ln;
  W("  pmqp := p shifted (q - (if (a = 0): xpart llcorner p else: xpart center p fi,");
  W(" if (a = 2): ypart llcorner p else: ypart center p fi));"); Ln;
  W("  draw pmqp withcolor c;"); Ln;
  W("  pmqx0 := min(pmqx0, xpart llcorner pmqp); pmqx1 := min(pmqx1, ypart llcorner pmqp);"); Ln;
  W("  pmqx2 := max(pmqx2, xpart urcorner pmqp); pmqx3 := max(pmqx3, ypart urcorner pmqp);"); Ln;
  W("enddef;"); Ln;
  FOR k := 1 TO 4 DO
    W("fill unitsquare xscaled "); Pt(l.qw); W(" yscaled "); Pt(l.qh);
    W(" shifted "); At(l.qx[k], l.qy[k] + l.qh); W(" withcolor "); Col(l.qFill[k]); W(";"); Ln;
    Text(l.qText[k])
  END;
  FOR k := 0 TO 5 DO
    IF (l.border[k].colour >= 0) & (l.border[k].width > 0) THEN
      W("draw "); At(l.border[k].x1, l.border[k].y1); W(" -- "); At(l.border[k].x2, l.border[k].y2);
      W(" withcolor "); Col(l.border[k].colour); W(" withpen pencircle scaled ");
      Pt(l.border[k].width); W(";"); Ln
    END
  END;
  FOR k := 0 TO l.nPoints - 1 DO
    s := l.point[k];
    IF s.fill >= 0 THEN
      W("fill fullcircle scaled "); Pt(2 * s.r); W(" shifted "); At(s.x, s.y);
      W(" withcolor "); Col(s.fill); W(";"); Ln
    END;
    IF (s.stroke >= 0) & (s.strokeWidth > 0) THEN
      W("draw fullcircle scaled "); Pt(2 * s.r); W(" shifted "); At(s.x, s.y);
      W(" withcolor "); Col(s.stroke); W(" withpen pencircle scaled "); Pt(s.strokeWidth);
      W(";"); Ln
    END;
    Text(s.text)
  END;
  FOR k := 0 TO 3 DO Text(l.axis[k]) END;
  Text(l.title);
  W("setbounds currentpicture to (pmqx0, pmqx1) -- (pmqx2, pmqx1) -- (pmqx2, pmqx3)");
  W(" -- (pmqx0, pmqx3) -- cycle;"); Ln;
  W("\stopMPcode"); Ln
END Write;

END PmQuadrantMp.
