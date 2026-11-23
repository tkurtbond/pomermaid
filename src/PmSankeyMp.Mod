MODULE PmSankeyMp;
(* PmSankeyMp: a laid out sankey diagram, PmSankeyLayout's, written in
   MetaPost, for ConTeXt: a \startMPcode block that draws it as
   PmSankeyPic does, in the same order and colours, with ConTeXt's
   text, textext's pictures, each placed by its anchor. The places are
   PmSankeyLayout's, in points; the drawing's bounds are the layout's,
   widened for any text ConTeXt sets wider than pomermaid measured it
   (decision 18). Text is written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, G := PmGeom, KL := PmSankeyLayout, PmMp;

VAR
  l: KL.Layout;

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

(* Fills the polygon p[0 .. n-1] with the colour rgb *)
PROCEDURE Polygon(VAR p: ARRAY OF G.Point; n: INTEGER; rgb: LONGINT);
  VAR k: INTEGER;
BEGIN
  W("fill ");
  FOR k := 0 TO n - 1 DO At(p[k].x, p[k].y); W(" -- ") END;
  W("cycle withcolor "); Col(rgb); W(";"); Ln
END Polygon;

PROCEDURE Link(it: KL.Item);
  VAR p: ARRAY 2 * KL.Samples + 2 OF G.Point; k, n: INTEGER; rgb: LONGINT;
BEGIN
  IF KL.Plain(it) THEN KL.Outline(it, p, n); Polygon(p, n, it.fill)
  ELSE
    FOR k := 0 TO KL.Samples - 1 DO KL.Slice(it, k, p, n, rgb); Polygon(p, n, rgb) END
  END
END Link;

(* Writes lay's sankey diagram as a \startMPcode block *)
PROCEDURE Write*(lay: KL.Layout);
  VAR it: KL.Item;
BEGIN
  l := lay;
  W("\startMPcode"); Ln;
  W("numeric pmxx[]; picture pmxp;"); Ln;
  W("pmxx0 := 0; pmxx1 := "); Pt(-l.height); W("; pmxx2 := "); Pt(l.width);
  W("; pmxx3 := 0;"); Ln;
  (* the picture p with its anchor at q: a = 0, the middle of its left
     side; 2, the middle of its right side; in the colour c; the bounds
     widened for it *)
  W("def pmxtext(expr p, q, a, c) ="); Ln;
  W("  pmxp := p shifted -(if (a = 0): xpart llcorner p else: xpart lrcorner p fi,");
  W(" ypart center p) shifted q;"); Ln;
  W("  draw pmxp withcolor c;"); Ln;
  W("  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);"); Ln;
  W("  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);"); Ln;
  W("enddef;"); Ln;
  it := l.items;
  WHILE it # NIL DO
    IF it.kind = KL.Link THEN Link(it)
    ELSIF it.kind = KL.Rect THEN
      W("fill unitsquare xscaled "); Pt(it.w); W(" yscaled "); Pt(it.h);
      W(" shifted "); At(it.x, it.y + it.h); W(" withcolor "); Col(it.fill); W(";"); Ln
    ELSIF (it.lab # NIL) & (it.lab.n > 0) THEN
      W("pmxtext("); Picture(it.lab, it.size); W(", "); At(it.x, it.y); W(", ");
      IF it.anchor = KL.Start THEN W("0") ELSE W("2") END;
      W(", "); Col(it.line); W(");"); Ln
    END;
    it := it.next
  END;
  W("setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3)");
  W(" -- (pmxx0, pmxx3) -- cycle;"); Ln;
  W("\stopMPcode"); Ln
END Write;

END PmSankeyMp.
