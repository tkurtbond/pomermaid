MODULE PmDrawMp;
(* PmDrawMp: a drawing, PmDraw's, written in MetaPost, for ConTeXt:
   a \startMPcode block that draws it as PmDrawPic does, in
   the same order and colours: circles, boxes, rounded as the layout's,
   polygons and lines, with butt caps, as SVG's; the curves, the
   arrows, as their Béziers, with round caps; ConTeXt's text,
   textext's pictures, each centred at its middle and turned. The
   places are PmDraw's, in points; the drawing's bounds are the
   layout's, widened for any text ConTeXt sets wider than pomermaid
   measured it (decision 18), but a fitted text, in a box that does not
   grow, is shrunk to no wider than pomermaid measured it. Text is
   written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, D := PmDraw, PmMp;

VAR
  l: D.Drawing;

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
  W('textext("\framed[frame=off,offset=0pt,align=middle]{" & ');
  PmMp.Label(lab); W(' & "}") scaled '); PmIO.WriteReal(size / l.size, 4)
END Picture;

(* The closed path of the item it, a circle, a box or a polygon *)
PROCEDURE Shape(it: D.Item);
  VAR k: INTEGER;
BEGIN
  IF it.kind = D.Circle THEN
    W("fullcircle scaled "); Pt(2 * it.r); W(" shifted "); At(it.x, it.y)
  ELSIF it.kind = D.Rect THEN
    W("pmhbox("); Pt(it.x); W(", "); Pt(it.y); W(", "); Pt(it.w); W(", "); Pt(it.h);
    W(", "); Pt(it.r); W(")")
  ELSE
    FOR k := 0 TO it.n - 1 DO
      At(it.p[k].x, it.p[k].y); W(" -- ");
      IF k MOD 4 = 3 THEN Ln; W("  ") END
    END;
    W("cycle")
  END
END Shape;

PROCEDURE Filled(it: D.Item);
BEGIN
  IF it.fill >= 0 THEN W("fill "); Shape(it); W(" withcolor "); Col(it.fill); W(";"); Ln END;
  IF (it.line >= 0) & (it.width > 0) THEN
    W("draw "); Shape(it); W(" withcolor "); Col(it.line);
    W(" withpen pencircle scaled "); Pt(it.width); W(";"); Ln
  END
END Filled;

PROCEDURE Stroked(it: D.Item);
  VAR k: INTEGER;
BEGIN
  IF (it.line < 0) OR (it.width <= 0) OR (it.n < 2) THEN RETURN END;
  IF it.kind = D.Curve THEN W("begingroup interim linecap := rounded; ") END;
  W("draw "); At(it.p[0].x, it.p[0].y);
  IF it.kind = D.Line THEN W(" -- "); At(it.p[1].x, it.p[1].y)
  ELSE
    k := 0;
    WHILE k + 3 < it.n DO
      Ln; W("  .. controls "); At(it.p[k + 1].x, it.p[k + 1].y); W(" and ");
      At(it.p[k + 2].x, it.p[k + 2].y); W(" .. "); At(it.p[k + 3].x, it.p[k + 3].y);
      INC(k, 3)
    END
  END;
  W(" withcolor "); Col(it.line); W(" withpen pencircle scaled "); Pt(it.width);
  IF it.dash > 0 THEN W(" dashed dashpattern(on "); Pt(it.dash); W(" off "); Pt(it.dash); W(")") END;
  W(";");
  IF it.kind = D.Curve THEN W(" endgroup;") END;
  Ln
END Stroked;

(* Writes the drawing lay as a \startMPcode block *)
PROCEDURE Write*(lay: D.Drawing);
  VAR it: D.Item; fit: BOOLEAN;
BEGIN
  l := lay;
  fit := FALSE; it := l.items;
  WHILE it # NIL DO fit := fit OR it.fit; it := it.next END;
  W("\startMPcode"); Ln;
  W("numeric pmxx[]; picture pmxp;"); Ln;
  W("pmxx0 := 0; pmxx1 := "); Pt(-l.height); W("; pmxx2 := "); Pt(l.width);
  W("; pmxx3 := 0;"); Ln;
  (* the picture p with its middle at q, turned clockwise by d degrees
     about it, in the colour c; the bounds widened for it *)
  W("def pmxtext(expr p, q, d, c) ="); Ln;
  W("  pmxp := p shifted -center p rotated -d shifted q;"); Ln;
  W("  draw pmxp withcolor c;"); Ln;
  W("  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);"); Ln;
  W("  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);"); Ln;
  W("enddef;"); Ln;
  IF fit THEN
    (* the picture p, shrunk to no wider than w *)
    W("vardef pmxfit(expr p, w) ="); Ln;
    W("  if xpart urcorner p - xpart llcorner p > w:"); Ln;
    W("    p scaled (w / (xpart urcorner p - xpart llcorner p)) else: p fi"); Ln;
    W("enddef;"); Ln
  END;
  (* the box from (x, y), y down, w by h, its corners rounded to r *)
  W("vardef pmhbox(expr x, y, w, h, r) ="); Ln;
  W("  if r > 0: (x + r, -y) -- (x + w - r, -y) {right} .. {down} (x + w, -y - r)"); Ln;
  W("    -- (x + w, -y - h + r) {down} .. {left} (x + w - r, -y - h)"); Ln;
  W("    -- (x + r, -y - h) {left} .. {up} (x, -y - h + r)"); Ln;
  W("    -- (x, -y - r) {up} .. {right} cycle"); Ln;
  W("  else: (x, -y) -- (x + w, -y) -- (x + w, -y - h) -- (x, -y - h) -- cycle fi"); Ln;
  W("enddef;"); Ln;
  W("begingroup interim linecap := butt;"); Ln;
  it := l.items;
  WHILE it # NIL DO
    IF (it.kind = D.Circle) OR (it.kind = D.Rect) OR (it.kind = D.Poly) THEN Filled(it)
    ELSIF (it.kind = D.Line) OR (it.kind = D.Curve) THEN Stroked(it)
    ELSIF (it.lab # NIL) & (it.lab.n > 0) THEN
      W("pmxtext(");
      IF it.fit THEN W("pmxfit("); Picture(it.lab, it.size); W(", "); Pt(it.w); W(")")
      ELSE Picture(it.lab, it.size)
      END;
      W(", "); At(it.x, it.y); W(", ");
      PmIO.WriteReal(it.angle, 3); W(", "); Col(it.line); W(");"); Ln
    END;
    it := it.next
  END;
  W("endgroup;"); Ln;
  W("setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3)");
  W(" -- (pmxx0, pmxx3) -- cycle;"); Ln;
  W("\stopMPcode"); Ln
END Write;

END PmDrawMp.
