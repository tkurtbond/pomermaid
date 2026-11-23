MODULE PmGitPic;
(* PmGitPic: a laid out git graph, PmGitLayout's, written in pic, for
   groff, with PmPic's helpers: its items in their order; each circle a
   circle, each rectangle a box, rounded as the layout's, each polygon
   PmPic's, each line a line, dashed or not; each curve, an arrow, a
   line through its Béziers, each sampled, with a filled circle at each
   end for its round caps, which pic has not; each text centred at its
   middle, or, turned, along its turned middle line. *)

IMPORT PmIO, Math, S := PmStyle, P := PmPic, G := PmGeom, HL := PmGitLayout;

CONST
  NoColour = S.NoColour;
  Samples = 8;          (* the segments of a curved Bézier *)
  Hairline = 0.05;      (* points *)

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: HL.Layout): REAL;
  VAR it: HL.Item; w: REAL;
BEGIN
  w := 0; it := lay.items;
  WHILE it # NIL DO
    IF (it.line >= 0) & (it.kind # HL.Text) & (it.width > w) THEN w := it.width END;
    it := it.next
  END;
  RETURN w
END Widest;

PROCEDURE Style(it: HL.Item; VAR st: S.Style);
BEGIN
  st.fill := C(it.fill); st.line := C(it.line); st.text := NoColour; st.inner := NoColour;
  st.width := it.width; st.dash := it.dash
END Style;

(* " from p[0] to p[1] ..." *)
PROCEDURE Path(VAR p: ARRAY OF G.Point; n: INTEGER);
  VAR k: INTEGER;
BEGIN
  P.W(" from "); P.Pt(p[0].x, p[0].y);
  FOR k := 1 TO n - 1 DO
    IF k MOD 4 = 0 THEN P.W(" \"); PmIO.WriteLn; P.W(" ") END;
    P.W(" to "); P.Pt(p[k].x, p[k].y)
  END
END Path;

(* Whether the Bézier p[k] .. p[k+3] is straight: its control points
   its ends *)
PROCEDURE Straight(it: HL.Item; k: INTEGER): BOOLEAN;
BEGIN
  RETURN (it.p[k + 1].x = it.p[k].x) & (it.p[k + 1].y = it.p[k].y)
    & (it.p[k + 2].x = it.p[k + 3].x) & (it.p[k + 2].y = it.p[k + 3].y)
END Straight;

PROCEDURE Curve(it: HL.Item);
  VAR q: G.Points; n, k, j: INTEGER; st, cap: S.Style; r: REAL;
BEGIN
  q := G.NewPoints((it.n DIV 3) * Samples + 1);
  q[0] := it.p[0]; n := 1; k := 0;
  WHILE k + 3 < it.n DO
    IF Straight(it, k) THEN q[n] := it.p[k + 3]; INC(n)
    ELSE
      FOR j := 1 TO Samples DO
        G.OnCurve(it.p[k], it.p[k + 1], it.p[k + 2], it.p[k + 3], j / Samples, q[n]); INC(n)
      END
    END;
    INC(k, 3)
  END;
  Style(it, st);
  P.W("line"); Path(q^, n); P.Paint(st, FALSE); PmIO.WriteLn;
  cap.fill := st.line; cap.line := NoColour; cap.text := NoColour; cap.inner := NoColour;
  cap.width := 0; cap.dash := 0; r := it.width / 2;
  P.W("circle rad "); P.In(r); P.At(q[0].x, q[0].y); P.Paint(cap, TRUE); PmIO.WriteLn;
  P.W("circle rad "); P.In(r); P.At(q[n - 1].x, q[n - 1].y); P.Paint(cap, TRUE); PmIO.WriteLn
END Curve;

PROCEDURE Text(it: HL.Item);
  VAR a, dx, dy: REAL;
BEGIN
  IF it.angle = 0 THEN P.Anchored(it.lab, it.x, it.y, C(it.line), it.size, P.Centre)
  ELSE
    a := it.angle * Math.pi / 180; dx := Math.cos(a) * it.w / 2; dy := Math.sin(a) * it.w / 2;
    P.Along(it.lab, it.x - dx, it.y - dy, it.x + dx, it.y + dy, C(it.line), it.size)
  END
END Text;

(* Writes lay's git graph in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: HL.Layout; font: ARRAY OF CHAR);
  VAR it: HL.Item; c: INTEGER; st: S.Style;
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
    IF it.kind = HL.Circle THEN
      Style(it, st);
      P.W("circle rad "); P.In(it.r); P.At(it.x, it.y); P.Paint(st, TRUE); PmIO.WriteLn
    ELSIF it.kind = HL.Rect THEN
      Style(it, st);
      (* an unstroked rounded box: thickness 0's corner arcs come out of
         mutool as SVG arcs of the default width, scaled with them *)
      IF (it.r > 0) & (st.line = NoColour) & (st.fill # NoColour) THEN
        st.line := st.fill; st.width := Hairline
      END;
      P.W("box wid "); P.In(it.w); P.W(" ht "); P.In(it.h);
      IF it.r > 0 THEN P.W(" rad "); P.In(it.r) END;
      P.At(it.x + it.w / 2, it.y + it.h / 2); P.Paint(st, TRUE); PmIO.WriteLn
    ELSIF it.kind = HL.Poly THEN Style(it, st); P.Polygon(it.p^, it.n, st)
    ELSIF it.kind = HL.Line THEN
      Style(it, st); P.W("line"); Path(it.p^, 2); P.Paint(st, FALSE); PmIO.WriteLn
    ELSIF it.kind = HL.Curve THEN Curve(it)
    ELSE Text(it)
    END;
    it := it.next
  END;
  P.End
END Write;

END PmGitPic.
