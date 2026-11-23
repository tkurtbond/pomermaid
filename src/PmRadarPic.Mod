MODULE PmRadarPic;
(* PmRadarPic: a laid out radar chart, PmRadarLayout's, written in pic,
   for groff, with PmPic's helpers: its items in their order, each
   circle a pic circle, each polygon a filled polygon and its outline,
   each closed curve the same, its Béziers taken at Samples points
   each, each line a line, each rectangle a box, each text at its
   anchor. The fills are opaque, blended by the layout (decision 22). *)

IMPORT PmIO, S := PmStyle, P := PmPic, G := PmGeom, RL := PmRadarLayout;

CONST
  NoColour = S.NoColour;
  Samples = 16;         (* the points of each Bézier of a curve *)

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: RL.Layout): REAL;
  VAR w: REAL; it: RL.Item;
BEGIN
  w := 0; it := lay.items;
  WHILE it # NIL DO
    IF (it.kind # RL.Text) & (it.line >= 0) & (it.width > w) THEN w := it.width END;
    it := it.next
  END;
  RETURN w
END Widest;

(* it's style *)
PROCEDURE Style(it: RL.Item; VAR st: S.Style);
BEGIN
  st.fill := C(it.fill); st.line := C(it.line); st.text := NoColour; st.inner := NoColour;
  st.width := it.width; st.dash := 0;
  IF st.width <= 0 THEN st.line := NoColour END
END Style;

(* The closed curve it, as a polygon *)
PROCEDURE Curve(it: RL.Item; VAR st: S.Style);
  VAR p: G.Points; k, j, n, m: INTEGER;
BEGIN
  n := it.n; p := G.NewPoints(n * Samples); m := 0;
  FOR k := 0 TO n - 1 DO
    FOR j := 0 TO Samples - 1 DO
      G.OnCurve(it.p[k], it.c1[k], it.c2[k], it.p[(k + 1) MOD n], j / Samples, p[m]); INC(m)
    END
  END;
  P.Polygon(p^, m, st)
END Curve;

(* Writes lay's radar chart in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: RL.Layout; font: ARRAY OF CHAR);
  VAR it: RL.Item; c: INTEGER; st: S.Style;
BEGIN
  P.Setup(font, lay.font, lay.px);
  S.Reset(lay.d.g, lay.px);
  (* the colours, all known before P.Begin defines them *)
  it := lay.items;
  WHILE it # NIL DO c := C(it.fill); c := C(it.line); it := it.next END;
  P.Begin(lay.size, lay.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(lay.width); P.W(" ht "); P.In(lay.height);
  P.At(lay.width / 2, lay.height / 2); PmIO.WriteLn;
  it := lay.items;
  WHILE it # NIL DO
    Style(it, st);
    IF it.kind = RL.Text THEN
      IF it.anchor = RL.Start THEN P.Anchored(it.lab, it.x, it.y, st.line, it.size, P.Left)
      ELSIF it.anchor = RL.End THEN P.Anchored(it.lab, it.x, it.y, st.line, it.size, P.Right)
      ELSE P.Anchored(it.lab, it.x, it.y, st.line, it.size, P.Centre)
      END
    ELSIF (st.fill = NoColour) & (st.line = NoColour) THEN (* not drawn *)
    ELSIF it.kind = RL.Line THEN
      P.W("line from "); P.Pt(it.p[0].x, it.p[0].y); P.W(" to "); P.Pt(it.p[1].x, it.p[1].y);
      P.Stroke(st); PmIO.WriteLn
    ELSIF it.kind = RL.Rect THEN
      P.W("box wid "); P.In(it.w); P.W(" ht "); P.In(it.h);
      P.At(it.x + it.w / 2, it.y + it.h / 2); P.Paint(st, TRUE); PmIO.WriteLn
    ELSIF it.form = RL.Circle THEN
      P.W("circle rad "); P.In(it.r); P.At(it.x, it.y); P.Paint(st, TRUE); PmIO.WriteLn
    ELSIF it.form = RL.Polygon THEN P.Polygon(it.p^, it.n, st)
    ELSE Curve(it, st)
    END;
    it := it.next
  END;
  P.End
END Write;

END PmRadarPic.
