MODULE PmSankeyPic;
(* PmSankeyPic: a laid out sankey diagram, PmSankeyLayout's, written in
   pic, for groff, with PmPic's helpers: its items in their order, each
   link a filled polygon, its outline, or, for a gradient, a polygon
   for each of its slices, each in its colour; each node a filled box;
   each label at its anchor. The links are opaque, blended over white
   by the layout (decision 23). *)

IMPORT PmIO, S := PmStyle, P := PmPic, G := PmGeom, KL := PmSankeyLayout;

CONST
  NoColour = S.NoColour;

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* The width of the widest line Write draws for lay, in points: none *)
PROCEDURE Widest*(lay: KL.Layout): REAL;
BEGIN
  RETURN 0
END Widest;

PROCEDURE Fill(colour: LONGINT; VAR st: S.Style);
BEGIN
  st.fill := C(colour); st.line := NoColour; st.text := NoColour; st.inner := NoColour;
  st.width := 0; st.dash := 0
END Fill;

(* Defines the colours of the link it *)
PROCEDURE LinkColours(it: KL.Item);
  VAR p: ARRAY 2 * KL.Samples + 2 OF G.Point; k, n, c: INTEGER; rgb: LONGINT;
BEGIN
  IF KL.Plain(it) THEN c := C(it.fill)
  ELSE
    FOR k := 0 TO KL.Samples - 1 DO KL.Slice(it, k, p, n, rgb); c := C(rgb) END
  END
END LinkColours;

PROCEDURE Link(it: KL.Item);
  VAR p: ARRAY 2 * KL.Samples + 2 OF G.Point; k, n: INTEGER; rgb: LONGINT; st: S.Style;
BEGIN
  IF KL.Plain(it) THEN
    KL.Outline(it, p, n); Fill(it.fill, st); P.Polygon(p, n, st)
  ELSE
    FOR k := 0 TO KL.Samples - 1 DO
      KL.Slice(it, k, p, n, rgb); Fill(rgb, st); P.Polygon(p, n, st)
    END
  END
END Link;

(* Writes lay's sankey diagram in pic, its labels in the groff font
   font *)
PROCEDURE Write*(lay: KL.Layout; font: ARRAY OF CHAR);
  VAR it: KL.Item; c: INTEGER; st: S.Style;
BEGIN
  P.Setup(font, lay.font, lay.px);
  S.Reset(lay.d.g, lay.px);
  (* the colours, all known before P.Begin defines them *)
  it := lay.items;
  WHILE it # NIL DO
    IF it.kind = KL.Link THEN LinkColours(it) ELSE c := C(it.fill); c := C(it.line) END;
    it := it.next
  END;
  P.Begin(lay.size, lay.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(lay.width); P.W(" ht "); P.In(lay.height);
  P.At(lay.width / 2, lay.height / 2); PmIO.WriteLn;
  it := lay.items;
  WHILE it # NIL DO
    IF it.kind = KL.Link THEN Link(it)
    ELSIF it.kind = KL.Rect THEN
      Fill(it.fill, st);
      P.W("box wid "); P.In(it.w); P.W(" ht "); P.In(it.h);
      P.At(it.x + it.w / 2, it.y + it.h / 2); P.Paint(st, TRUE); PmIO.WriteLn
    ELSIF it.anchor = KL.Start THEN P.Anchored(it.lab, it.x, it.y, C(it.line), it.size, P.Left)
    ELSE P.Anchored(it.lab, it.x, it.y, C(it.line), it.size, P.Right)
    END;
    it := it.next
  END;
  P.End
END Write;

END PmSankeyPic.
