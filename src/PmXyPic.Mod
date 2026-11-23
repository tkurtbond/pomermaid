MODULE PmXyPic;
(* PmXyPic: a laid out XY chart, PmXyLayout's, written in pic, for
   groff, with PmPic's helpers: its items in their order, each rect a
   filled box, each path a line through its points, each text at its
   anchor, a turned text along a line in its direction *)

IMPORT PmIO, Math, S := PmStyle, P := PmPic, XL := PmXyLayout;

CONST
  NoColour = S.NoColour;

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: XL.Layout): REAL;
  VAR w: REAL; it: XL.Item;
BEGIN
  w := 0; it := lay.items;
  WHILE it # NIL DO
    IF (it.kind = XL.Path) & (it.width > w) THEN w := it.width END;
    it := it.next
  END;
  RETURN w
END Widest;

(* The text it *)
PROCEDURE Text(it: XL.Item; c: INTEGER);
  VAR a, dx, dy, x1, y1, x2, y2: REAL;
BEGIN
  IF it.angle = 0 THEN
    IF it.anchor = XL.Start THEN P.Anchored(it.lab, it.x, it.y, c, it.size, P.Left)
    ELSIF it.anchor = XL.End THEN P.Anchored(it.lab, it.x, it.y, c, it.size, P.Right)
    ELSE P.Anchored(it.lab, it.x, it.y, c, it.size, P.Centre)
    END
  ELSE
    a := it.angle * Math.pi / 180; dx := Math.cos(a) * it.w; dy := Math.sin(a) * it.w;
    IF it.anchor = XL.Start THEN x1 := it.x; y1 := it.y; x2 := it.x + dx; y2 := it.y + dy
    ELSIF it.anchor = XL.End THEN x1 := it.x - dx; y1 := it.y - dy; x2 := it.x; y2 := it.y
    ELSE x1 := it.x - dx / 2; y1 := it.y - dy / 2; x2 := it.x + dx / 2; y2 := it.y + dy / 2
    END;
    P.Along(it.lab, x1, y1, x2, y2, c, it.size)
  END
END Text;

(* Writes lay's XY chart in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: XL.Layout; font: ARRAY OF CHAR);
  VAR it: XL.Item; c, k: INTEGER; st: S.Style;
BEGIN
  P.Setup(font, lay.font, lay.px);
  S.Reset(lay.d.g, lay.px);
  (* the colours, all known before P.Begin defines them *)
  it := lay.items;
  WHILE it # NIL DO c := C(it.colour); it := it.next END;
  P.Begin(lay.size, lay.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(lay.width); P.W(" ht "); P.In(lay.height);
  P.At(lay.width / 2, lay.height / 2); PmIO.WriteLn;
  it := lay.items;
  WHILE it # NIL DO
    c := C(it.colour);
    IF c = NoColour THEN (* not drawn *)
    ELSIF it.kind = XL.Rect THEN
      IF (it.w > 0) & (it.h > 0) THEN
        st.fill := c; st.line := NoColour; st.text := NoColour; st.inner := NoColour;
        st.width := 0; st.dash := 0;
        P.W("box wid "); P.In(it.w); P.W(" ht "); P.In(it.h);
        P.At(it.x + it.w / 2, it.y + it.h / 2); P.Paint(st, TRUE); PmIO.WriteLn
      END
    ELSIF it.kind = XL.Path THEN
      IF (it.n >= 2) & (it.width > 0) THEN
        P.W("line from "); P.Pt(it.p[0].x, it.p[0].y);
        FOR k := 1 TO it.n - 1 DO P.W(" to "); P.Pt(it.p[k].x, it.p[k].y) END;
        P.W(" outlined "); P.ColourName(c); P.W(" thickness "); PmIO.WriteReal(it.width, 3);
        PmIO.WriteLn
      END
    ELSE Text(it, c)
    END;
    it := it.next
  END;
  P.End
END Write;

END PmXyPic.
