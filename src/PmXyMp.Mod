MODULE PmXyMp;
(* PmXyMp: a laid out XY chart, PmXyLayout's, written in MetaPost, for
   ConTeXt: a \startMPcode block that draws it as PmXyPic does, in the
   same order and colours, with ConTeXt's text, textext's pictures,
   each placed by its anchor and turned by its angle. The places are
   PmXyLayout's, in points; the drawing's bounds are the layout's,
   widened for any text ConTeXt sets wider than pomermaid measured it
   (decision 18). Text is written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, XL := PmXyLayout, PmMp;

VAR
  l: XL.Layout;

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

(* The colour rgb, 0RRGGBBH, as a MetaPost colour *)
PROCEDURE Col(rgb: LONGINT);
BEGIN
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

(* Writes lay's XY chart as a \startMPcode block *)
PROCEDURE Write*(lay: XL.Layout);
  VAR it: XL.Item; k: INTEGER;
BEGIN
  l := lay;
  W("\startMPcode"); Ln;
  W("numeric pmxx[]; picture pmxp;"); Ln;
  W("pmxx0 := 0; pmxx1 := "); Pt(-l.height); W("; pmxx2 := "); Pt(l.width);
  W("; pmxx3 := 0;"); Ln;
  (* the picture p with its anchor at q: a = 0, the middle of its left
     side; 1, its middle; 2, the middle of its right side; turned
     clockwise by d degrees about it; in the colour c; the bounds
     widened for it *)
  W("def pmxtext(expr p, q, a, d, c) ="); Ln;
  W("  pmxp := p shifted -(if (a = 0): xpart llcorner p elseif (a = 1): xpart center p");
  W(" else: xpart lrcorner p fi, ypart center p) rotated -d shifted q;"); Ln;
  W("  draw pmxp withcolor c;"); Ln;
  W("  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);"); Ln;
  W("  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);"); Ln;
  W("enddef;"); Ln;
  W("begingroup interim linecap := butt;"); Ln;
  it := l.items;
  WHILE it # NIL DO
    IF it.colour < 0 THEN (* not drawn *)
    ELSIF it.kind = XL.Rect THEN
      IF (it.w > 0) & (it.h > 0) THEN
        W("fill unitsquare xscaled "); Pt(it.w); W(" yscaled "); Pt(it.h);
        W(" shifted "); At(it.x, it.y + it.h); W(" withcolor "); Col(it.colour); W(";"); Ln
      END
    ELSIF it.kind = XL.Path THEN
      IF (it.n >= 2) & (it.width > 0) THEN
        W("draw "); At(it.p[0].x, it.p[0].y);
        FOR k := 1 TO it.n - 1 DO W(" -- "); At(it.p[k].x, it.p[k].y) END;
        W(" withcolor "); Col(it.colour); W(" withpen pencircle scaled ");
        Pt(it.width); W(";"); Ln
      END
    ELSIF (it.lab # NIL) & (it.lab.n > 0) THEN
      W("pmxtext("); Picture(it.lab, it.size); W(", "); At(it.x, it.y); W(", ");
      IF it.anchor = XL.Start THEN W("0") ELSIF it.anchor = XL.End THEN W("2") ELSE W("1") END;
      W(", "); PmIO.WriteReal(it.angle, 3); W(", "); Col(it.colour); W(");"); Ln
    END;
    it := it.next
  END;
  W("endgroup;"); Ln;
  W("setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3)");
  W(" -- (pmxx0, pmxx3) -- cycle;"); Ln;
  W("\stopMPcode"); Ln
END Write;

END PmXyMp.
