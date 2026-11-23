MODULE PmPiePic;
(* PmPiePic: a laid out pie chart, PmPieLayout's, written in pic, for
   groff, with PmPic's helpers.

   The drawing, as Mermaid's pieRenderer.ts draws it, from the back:
   the circle around the pie; the slices, each a polygon, its arcs
   sampled, filled in its colour and outlined; the percentages; the
   title; and the legend, each item a square, filled and outlined in
   its colour, and its text. The colours and lengths are Mermaid's
   (PmStyle.PieColours). pic has no transparency: the slices'
   opacity, pieOpacity, is taken over white, for their fill and their
   outline. The highlighted slice is drawn 1.05 times as large, about
   the centre, its outline too, at full opacity. *)

IMPORT Math, PmIO, G := PmGeom, S := PmStyle, P := PmPic, GP := PmGanttPic,
  PL := PmPieLayout;

CONST
  NoColour = S.NoColour;
  Steps = 96;           (* the points of a whole circle's arc *)
  White = 0FFFFFFH;

TYPE
  Style = S.Style;

VAR
  l: PL.Layout;
  px: REAL;
  t: S.PieTheme;

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

(* Adds to p the arc of radius r from angle a0 to a1 *)
PROCEDURE Arc(VAR p: ARRAY OF G.Point; VAR n: INTEGER; r, a0, a1: REAL);
  VAR k, m: INTEGER; a: REAL;
BEGIN
  m := SHORT(ENTIER(ABS(a1 - a0) / (2 * Math.pi) * Steps)) + 2;
  FOR k := 0 TO m DO
    a := a0 + (a1 - a0) * k / m;
    G.Set(p[n], l.cx + r * Math.sin(a), l.cy - r * Math.cos(a)); INC(n)
  END
END Arc;

(* The circle of radius r about the centre, in st *)
PROCEDURE Circle(r: REAL; VAR st: Style);
  VAR p: ARRAY Steps + 4 OF G.Point; n: INTEGER;
BEGIN
  n := 0; Arc(p, n, r, 0, 2 * Math.pi); DEC(n);  (* the last is the first *)
  P.Polygon(p, n, st)
END Circle;

(* The styles of slice k: st, and hole, a donut's hole when the slice
   is the whole circle *)
PROCEDURE SliceStyles(k: INTEGER; VAR st, hole: Style);
  VAR fill, line: LONGINT; w: REAL;
BEGIN
  fill := t.pie[l.colour[k]]; line := t.stroke; w := t.strokeWidth;
  IF l.highlighted[k] THEN w := w * PL.Highlight
  ELSE
    IF fill >= 0 THEN fill := GP.Over(fill, t.opacity, White) END;
    IF line >= 0 THEN line := GP.Over(line, t.opacity, White) END
  END;
  Make(st, fill, line, w);
  Make(hole, White, line, w)
END SliceStyles;

(* Slice k, in st, its hole in hole *)
PROCEDURE Slice(k: INTEGER; VAR st, holeSt: Style);
  VAR p: ARRAY 2 * Steps + 12 OF G.Point; n: INTEGER; r, hole: REAL;
BEGIN
  r := l.r; hole := l.hole;
  IF l.highlighted[k] THEN r := r * PL.Highlight; hole := hole * PL.Highlight END;
  IF l.a1[k] - l.a0[k] > 2 * Math.pi - 0.0001 THEN
    (* a circle, and the hole, as d3 draws them: no line across *)
    Circle(r, st);
    IF hole > 0 THEN Circle(hole, holeSt) END
  ELSE
    n := 0;
    Arc(p, n, r, l.a0[k], l.a1[k]);
    IF hole > 0 THEN Arc(p, n, hole, l.a1[k], l.a0[k])
    ELSE G.Set(p[n], l.cx, l.cy); INC(n)
    END;
    P.Polygon(p, n, st)
  END
END Slice;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: PL.Layout): REAL;
  VAR th: S.PieTheme; w: REAL;
BEGIN
  S.Reset(lay.d.g, lay.px); S.PieColours(th);
  w := th.strokeWidth * PL.Highlight;
  IF th.outerWidth > w THEN w := th.outerWidth END;
  RETURN w
END Widest;

(* Writes lay's pie chart in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: PL.Layout; font: ARRAY OF CHAR);
  VAR
    k, cSection, cTitle, cLegend, cOuter: INTEGER; s: REAL;
    sliceSt, holeSt, legendSt: POINTER TO ARRAY OF Style;
BEGIN
  l := lay; px := l.px;
  P.Setup(font, l.font, px);
  S.Reset(l.d.g, px); S.PieColours(t);
  (* the colours, all known before P.Begin defines them *)
  NEW(sliceSt, l.nSlices + 1); NEW(holeSt, l.nSlices + 1); NEW(legendSt, l.n + 1);
  FOR k := 0 TO l.nSlices - 1 DO SliceStyles(k, sliceSt[k], holeSt[k]) END;
  FOR k := 0 TO l.n - 1 DO
    Make(legendSt[k], t.pie[l.legendColour[k]], t.pie[l.legendColour[k]], px)
  END;
  cSection := C(t.section); cTitle := C(t.title); cLegend := C(t.legend);
  cOuter := C(t.outerStroke);
  P.Begin(l.size, l.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(l.width); P.W(" ht "); P.In(l.height);
  P.At(l.width / 2, l.height / 2); PmIO.WriteLn;
  IF (cOuter # NoColour) & (t.outerWidth > 0) THEN
    P.W("circle rad "); P.In(l.r + t.outerWidth / 2); P.At(l.cx, l.cy);
    P.W(" outlined "); P.ColourName(cOuter);
    P.W(" thickness "); PmIO.WriteReal(t.outerWidth, 3); PmIO.WriteLn
  END;
  FOR k := 0 TO l.nSlices - 1 DO Slice(k, sliceSt[k], holeSt[k]) END;
  FOR k := 0 TO l.nSlices - 1 DO
    P.Anchored(l.percent[k], l.tx[k], l.ty[k], cSection, l.size, P.Centre)
  END;
  IF l.title # NIL THEN
    P.Anchored(l.title, l.titleX, l.titleY, cTitle, l.titleSize, P.Centre)
  END;
  s := PL.Box * px;
  FOR k := 0 TO l.n - 1 DO
    P.W("box wid "); P.In(s); P.W(" ht "); P.In(s);
    P.At(l.bx[k] + s / 2, l.by[k] + s / 2); P.Paint(legendSt[k], TRUE); PmIO.WriteLn;
    P.Anchored(l.text[k], l.lx[k], l.ly[k], cLegend, l.size, P.Left)
  END;
  P.End
END Write;

END PmPiePic.
