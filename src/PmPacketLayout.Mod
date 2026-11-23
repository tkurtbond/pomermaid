MODULE PmPacketLayout;
(* PmPacketLayout: a packet diagram, PmPacket's, laid out in Mermaid's
   pixels, taken at the drawing's size, 16 pixels to the size, and
   drawn as Mermaid 12.3.0's packet renderer draws it. Lengths are in
   points, y down.

   - The drawing is bitWidth * bitsPerRow + 2 wide and (rowHeight +
     paddingY) * (rows + 1) high, less rowHeight without a title: the
     box Mermaid's view box is, which is in the drawing, unseen.
   - Row r's top is r * (rowHeight + paddingY) + paddingY. A field's
     part starts at its first bit's column in its row, bitWidth a
     column, 1 from the left; it is bits * bitWidth - paddingX wide and
     rowHeight high. With bitOrder descending, the columns are counted
     from the right, the highest bit on the left.
   - The label is in the middle of the box. With showBits, the box's
     first bit (its last if descending) starts at its left and its
     last bit ends at its right, their baselines 2 above it; a box of
     one bit has one number, over its middle.
   - The title is in the middle of the last row's band, below the
     rows.
   - The colours and sizes are those of themeVariables' packet,
     PmStyle.PacketColours. *)

IMPORT M := PmMetrics, F := PmFlow, S := PmStyle, P := PmPacket, D := PmDraw, L := PmLex;

CONST
  Mid = 0.35D0;  (* a text's middle above its baseline, in sizes *)
  Above = 2;     (* the bit numbers' baseline above the box *)

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: P.Diagram
  END;

VAR
  l: Layout;
  th: S.PacketTheme;

(* The label of n *)
PROCEDURE Number(n: LONGINT): F.Label;
  VAR s: ARRAY 24 OF CHAR; dg: ARRAY 24 OF CHAR; i, k: INTEGER;
BEGIN
  i := 0; REPEAT dg[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  k := 0; WHILE i > 0 DO DEC(i); s[k] := dg[i]; INC(k) END;
  s[k] := 0X;
  RETURN F.PlainLabel(L.New(s))
END Number;

(* A text, lab, its left (or its right if right) at x, its baseline
   at y *)
PROCEDURE Anchored(lab: F.Label; x, y, size: LONGREAL; right: BOOLEAN; colour: LONGINT);
  VAR w, h: LONGREAL;
BEGIN
  D.Measure(l, lab, size, w, h);
  IF right THEN x := x - w / 2 ELSE x := x + w / 2 END;
  D.AddText(l, lab, x, y - Mid * size, size, 0, colour)
END Anchored;

(* Row r's part of a field, b *)
PROCEDURE Block(d: P.Diagram; b: P.Block; r: LONGINT);
  VAR bits, first, column, lead, trail: LONGINT; x, y, w: LONGREAL;
BEGIN
  y := r * (d.rowHeight + d.paddingY) + d.paddingY;
  bits := b.end - b.start + 1;
  first := b.start MOD d.bitsPerRow;
  IF d.descending THEN column := d.bitsPerRow - first - bits ELSE column := first END;
  x := column * d.bitWidth + 1;
  w := bits * d.bitWidth - d.paddingX;
  IF w > 0 THEN D.AddRect(l, x, y, w, d.rowHeight, 0, th.blockFill, th.blockLine, th.blockWidth) END;
  D.AddText(l, b.label, x + w / 2, y + d.rowHeight / 2, th.labelSize, 0, th.label);
  IF d.showBits THEN
    IF d.descending THEN lead := b.end; trail := b.start ELSE lead := b.start; trail := b.end END;
    IF bits = 1 THEN
      D.AddText(l, Number(lead), x + w / 2, y - Above - Mid * th.byteSize, th.byteSize, 0,
        th.startByte)
    ELSE
      Anchored(Number(lead), x, y - Above, th.byteSize, FALSE, th.startByte);
      Anchored(Number(trail), x + w, y - Above, th.byteSize, TRUE, th.endByte)
    END
  END
END Block;

(* d laid out at size points, in lay *)
PROCEDURE Make*(d: P.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR wd: P.Word; b: P.Block; r: LONGINT; total, width, height: LONGREAL;
BEGIN
  NEW(l); lay := l; l.d := d; D.Init(l, d.g, font, size);
  S.Reset(d.g, l.px); S.PacketColours(th);
  total := d.rowHeight + d.paddingY;
  width := d.bitWidth * d.bitsPerRow + 2;
  height := total * (d.nWords + 1);
  IF d.g.title = NIL THEN height := height - d.rowHeight END;
  D.AddRect(l, 0, 0, width, height, 0, -1, -1, 0);
  wd := d.words; r := 0;
  WHILE wd # NIL DO
    b := wd.blocks;
    WHILE b # NIL DO Block(d, b, r); b := b.next END;
    wd := wd.next; INC(r)
  END;
  IF d.g.title # NIL THEN
    D.AddText(l, d.g.title, width / 2, height - total / 2, th.titleSize, 0, th.title)
  END;
  D.Finish(l, 0);
  l := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: P.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
  VAR k: INTEGER;
BEGIN
  Make(d, font, size, lay); k := 0;
  WHILE (maxW > 0) & (lay.width > maxW) & (k < 5) & (size > 0.2D0) DO
    size := ENTIER(size * maxW / lay.width * 10) / 10;
    IF size >= lay.size THEN size := lay.size - 0.1 END;
    IF size < 0.1 THEN size := 0.1 END;
    Make(d, font, size, lay); INC(k)
  END
END Fit;

END PmPacketLayout.
