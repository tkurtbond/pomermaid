MODULE PmPieMp;
(* PmPieMp: a laid out pie chart, PmPieLayout's, written in MetaPost,
   for ConTeXt: a \startMPcode block that draws it as PmPiePic does, in
   the same order and colours, with ConTeXt's text.

   What depends on the text is placed in MetaPost, from the width of
   textext's pictures (decision 3): the legend's widest text, L, which
   moves the pie for a legend on the left, the legend for one at the
   top, the bottom or the centre, and widens the drawing for one at the
   right or the left; and the title, which widens the drawing, on both
   sides, when it is wider. The rest, the pie's radius, the slices'
   angles and the rows' heights, is PmPieLayout's, written as numbers,
   in points. The slices' arcs are sampled every 5 degrees or less and
   joined smoothly. Text is written as PmMp writes it. *)

IMPORT Math, PmIO, F := PmFlow, S := PmStyle, P := PmPie, PL := PmPieLayout,
  GP := PmGanttPic, PmMp;

CONST
  Left = 0; Centre = 1;
  White = 0FFFFFFH;

VAR
  l: PL.Layout;
  px: REAL;
  t: S.PieTheme;

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

PROCEDURE Ln;
BEGIN
  PmIO.WriteLn
END Ln;

PROCEDURE R(x: REAL);
BEGIN
  PmIO.WriteReal(x, 3)
END R;

(* x points *)
PROCEDURE Pt(x: REAL);
BEGIN
  R(x); W("pt")
END Pt;

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

(* Slice k's fill and outline, and the outline's width *)
PROCEDURE Colours(k: INTEGER; VAR fill, line: LONGINT; VAR w: REAL);
BEGIN
  fill := t.pie[l.colour[k]]; line := t.stroke; w := t.strokeWidth;
  IF l.highlighted[k] THEN w := w * PL.Highlight
  ELSE
    IF fill >= 0 THEN fill := GP.Over(fill, t.opacity, White) END;
    IF line >= 0 THEN line := GP.Over(line, t.opacity, White) END
  END
END Colours;

(* The path p, filled with fill and outlined with line, w points wide;
   -1 for neither *)
PROCEDURE Paint(p: ARRAY OF CHAR; fill, line: LONGINT; w: REAL);
BEGIN
  IF fill >= 0 THEN W("fill "); W(p); W(" withcolor "); Col(fill); W(";"); Ln END;
  IF (line >= 0) & (w > 0) THEN
    W("draw "); W(p); W(" withcolor "); Col(line);
    W(" withpen pencircle scaled "); Pt(w); W(";"); Ln
  END
END Paint;

(* Slice k, its path pmqs *)
PROCEDURE Slice(k: INTEGER);
  VAR fill, line: LONGINT; w, r, hole, a0, a1: REAL;
BEGIN
  Colours(k, fill, line, w);
  r := l.r; hole := l.hole;
  IF l.highlighted[k] THEN r := r * PL.Highlight; hole := hole * PL.Highlight END;
  a0 := l.a0[k] * 180 / Math.pi; a1 := l.a1[k] * 180 / Math.pi;
  IF a1 - a0 > 360 - 0.01 THEN
    W("pmqs := fullcircle scaled "); Pt(2 * r); W(" shifted pmqc;"); Ln;
    Paint("pmqs", fill, line, w);
    IF hole > 0 THEN
      W("pmqs := fullcircle scaled "); Pt(2 * hole); W(" shifted pmqc;"); Ln;
      Paint("pmqs", White, line, w)
    END
  ELSE
    W("pmqs := (pmqarc("); Pt(r); W(", "); R(a0); W(", "); R(a1); W(") -- ");
    IF hole > 0 THEN
      W("reverse pmqarc("); Pt(hole); W(", "); R(a0); W(", "); R(a1); W(")")
    ELSE W("(0, 0)")
    END;
    W(" -- cycle) shifted pmqc;"); Ln;
    Paint("pmqs", fill, line, w)
  END
END Slice;

(* lab, size points, at the point p, an expression, centred or
   starting there, in rgb *)
PROCEDURE Text(lab: F.Label; size: REAL; p: ARRAY OF CHAR; x, y: REAL;
  anchor: INTEGER; rgb: LONGINT);
BEGIN
  IF (lab = NIL) OR (lab.n = 0) THEN RETURN END;
  W("pmqtext("); Picture(lab, size); W(", "); W(p); W(" + ("); Pt(x); W(", "); Pt(-y);
  W("), "); PmIO.WriteInt(anchor); W(", "); Col(rgb); W(");"); Ln
END Text;

(* Writes lay's pie chart as a \startMPcode block *)
PROCEDURE Write*(lay: PL.Layout);
  VAR k: INTEGER; d: P.Diagram; box: REAL;
BEGIN
  l := lay; px := l.px; d := l.d;
  S.Reset(d.g, px); S.PieColours(t);
  box := PL.Box * px;
  W("\startMPcode"); Ln;
  W("numeric pmqL, pmqox, pmqw, pmqa, pmqbx; pair pmqc; path pmqs; picture pmqt;"); Ln;
  W("vardef pmqwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;"); Ln;
  (* the arc of radius r from b to c degrees, clockwise from 12
     o'clock, about (0, 0) *)
  W("vardef pmqarc(expr r, b, c) = save n; n := max(2, ceiling(abs(c - b) / 5));"); Ln;
  W("  (r * sind(b), r * cosd(b)) for i = 1 upto n:"); Ln;
  W("    .. (r * sind(b + (c - b) * i / n), r * cosd(b + (c - b) * i / n)) endfor"); Ln;
  W("enddef;"); Ln;
  (* the picture p, its middle (a = 1) or the middle of its left side
     (0) at q, in the colour c *)
  W("def pmqtext(expr p, q, a, c) ="); Ln;
  W("  draw p shifted (q - (if a = 0: xpart llcorner p else: xpart center p fi,");
  W(" ypart center p)) withcolor c;"); Ln;
  W("enddef;"); Ln;
  (* L, the legend's widest text *)
  W("pmqL := 0;"); Ln;
  FOR k := 0 TO l.n - 1 DO
    W("pmqL := max(pmqL, pmqwd("); Picture(l.text[k], l.size); W("));"); Ln
  END;
  W("pmqox := "); IF d.legend = P.Left THEN Pt(PL.Row * px); W(" + pmqL") ELSE W("0") END;
  W(";"); Ln;
  W("pmqw := "); Pt((PL.Size + PL.Margin) * px);
  IF (d.legend = P.Left) OR (d.legend = P.Right) THEN W(" + "); Pt(PL.Row * px); W(" + pmqL") END;
  W(";"); Ln;
  W("pmqbx := ");
  CASE d.legend OF
    P.Right: Pt((PL.Size / 2 + PL.RightX) * px)
  | P.Left: Pt((PL.Size / 2 - PL.Radius - PL.Row) * px)
  | P.Center, P.Top, P.Bottom: Pt((PL.Size / 2 - PL.Row) * px); W(" - pmqL / 2")
  END;
  W(";"); Ln;
  W("pmqc := ("); Pt(PL.Size / 2 * px); W(" + pmqox, "); Pt(-l.cy); W(");"); Ln;
  (* the drawing, from the back *)
  IF (t.outerStroke >= 0) & (t.outerWidth > 0) THEN
    W("draw fullcircle scaled "); Pt(2 * l.r + t.outerWidth); W(" shifted pmqc withcolor ");
    Col(t.outerStroke); W(" withpen pencircle scaled "); Pt(t.outerWidth); W(";"); Ln
  END;
  FOR k := 0 TO l.nSlices - 1 DO Slice(k) END;
  FOR k := 0 TO l.nSlices - 1 DO
    Text(l.percent[k], l.size, "pmqc", l.tx[k] - l.cx, l.ty[k] - l.cy, Centre, t.section)
  END;
  FOR k := 0 TO l.n - 1 DO
    W("pmqs := unitsquare scaled "); Pt(box); W(" shifted (pmqbx, "); Pt(-l.by[k] - box);
    W(");"); Ln;
    Paint("pmqs", t.pie[l.legendColour[k]], t.pie[l.legendColour[k]], px);
    Text(l.text[k], l.size, "(pmqbx, 0)", PL.Row * px, l.ly[k], Left, t.legend)
  END;
  (* the title, centred over the pie, and the drawing widened for it *)
  W("pmqa := 0;"); Ln;
  IF l.title # NIL THEN
    W("pmqt := "); Picture(l.title, l.titleSize); W(";"); Ln;
    W("pmqtext(pmqt, (xpart pmqc, "); Pt(-l.titleY); W("), 1, "); Col(t.title); W(");"); Ln;
    W("pmqa := max(0, pmqwd(pmqt) / 2 - xpart pmqc);"); Ln;
    W("pmqw := max(pmqw + pmqa, xpart pmqc + pmqa + pmqwd(pmqt) / 2);"); Ln
  END;
  W("currentpicture := currentpicture shifted (pmqa, 0);"); Ln;
  W("setbounds currentpicture to (0, 0) -- (pmqw, 0) -- (pmqw, "); Pt(-l.height);
  W(") -- (0, "); Pt(-l.height); W(") -- cycle;"); Ln;
  W("\stopMPcode"); Ln
END Write;

END PmPieMp.
