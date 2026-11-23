MODULE PmKanbanLayout;
(* PmKanbanLayout: a kanban board, PmKanban's, laid out in Mermaid's
   pixels, taken at the drawing's size, 16 pixels to the size, and
   drawn as Mermaid 12.3.0's kanban renderer draws it. Lengths are in
   points, y down.

   - Section k, from 1, is a box sectionWidth wide, its corners rounded
     to 5, its middle sectionWidth * k + 5 * (k - 1) across; its top is
     1.5 * sectionWidth above the origin. Its label, wrapped at
     sectionWidth, is centred along its top.
   - The sections' items start below the tallest label, at least 25
     high. Each item is sectionWidth - 15 wide, in the middle of its
     section, 5 below the one before. Its label, wrapped at 10 less
     than the item, is 10 from its left; the ticket is below it, at the
     left, and assigned, at the right. The item is the label's height
     and 20 high, and half the taller of the ticket and assigned;
     its corners are rounded to 5. A priority is a line, 4 wide, 2
     from the item's left: red for "Very High", orange for "High",
     blue for "Low" and light blue for "Very Low"; none for any other.
   - A section is as high as its items and 30, at least 50, and as much
     as the tallest label is over 25.
   - Section k is filled and outlined with cScale(k+1) lightened by 10,
     its label cScaleLabel(k+1); sections past the tenth take the first
     ten's colours again (decision 53). Items are filled with
     background and outlined with nodeBorder, their text textColor.

   The bounds are every item's, widened by 10 on each side. *)

IMPORT M := PmMetrics, F := PmFlow, S := PmStyle, K := PmKanban, D := PmDraw,
  FL := PmFlowLayout, L := PmLex;

CONST
  Size = 16;            (* the labels', in pixels *)
  Gap = 5;              (* between sections, and between items *)
  Pad = 10;             (* an item's label from its left *)

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: K.Diagram
  END;

VAR
  l: Layout;
  d: K.Diagram;
  th: S.KanbanTheme;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a ELSE RETURN b END
END Max;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a ELSE RETURN b END
END Min;

(* lab wrapped at maxW pixels, and its size, w by h; an empty label's is 0 *)
PROCEDURE Wrapped(lab: F.Label; maxW: LONGREAL; VAR w, h: LONGREAL): F.Label;
BEGIN
  lab := FL.Wrap(l.font, lab, Size * l.px, SHORT(maxW * l.px));
  IF lab.n = 0 THEN w := 0; h := 0 ELSE D.Measure(l, lab, Size, w, h) END;
  RETURN lab
END Wrapped;

(* The label of s, a ticket or assigned, wrapped at maxW pixels, and
   its size, w by h; NIL's is empty, 0 by 0, as an empty text's in
   Mermaid *)
PROCEDURE Text(s: L.Str; maxW: LONGREAL; VAR w, h: LONGREAL): F.Label;
BEGIN
  IF s = NIL THEN w := 0; h := 0; RETURN NIL END;
  RETURN Wrapped(F.MarkdownLabel(s^, 0, L.Length(s^)), maxW, w, h)
END Text;

(* The colour of priority p, or -1 *)
PROCEDURE Priority(p: L.Str): LONGINT;
BEGIN
  IF p = NIL THEN RETURN -1
  ELSIF L.Is(p, "Very High") THEN RETURN 0FF0000H
  ELSIF L.Is(p, "High") THEN RETURN 0FFA500H
  ELSIF L.Is(p, "Low") THEN RETURN 00000FFH
  ELSIF L.Is(p, "Very Low") THEN RETURN 0ADD8E6H
  END;
  RETURN -1
END Priority;

(* Item n, its top at y, its middle at x across, drawn if draw; returns
   the next item's top *)
PROCEDURE Item(n: K.Node; x, y: LONGREAL; draw: BOOLEAN): LONGREAL;
  VAR lab, tk, as: F.Label; w, lw, lh, tw, tkh, aw, ah, hA, h, top, bot, bh, cy, left: LONGREAL;
    c: LONGINT;
BEGIN
  w := d.sectionWidth - 1.5D0 * Pad;
  lab := Wrapped(n.label, w - 10, lw, lh);
  tk := Text(n.ticket, w - 10, tw, tkh);
  as := Text(n.assigned, w - 10, aw, ah);
  hA := Max(tkh, ah) / 2;
  h := lh + 20 + hA;
  (* the item's bounds about its origin, as Mermaid measures them *)
  top := -h / 2; bot := h / 2;
  IF lh > 0 THEN top := Min(top, -hA - lh / 2) END;
  bot := Max(bot, Max(-hA + lh / 2 + tkh, -hA + lh / 2 + ah));
  bh := bot - top;
  cy := y + bh / 2;
  IF draw THEN
    left := x - w / 2;
    D.AddRect(l, left, cy - h / 2, w, h, 5, th.itemFill, th.itemLine, 1);
    c := Priority(n.priority);
    IF c >= 0 THEN D.AddLine(l, left + 2, cy - h / 2 + 2, left + 2, cy + h / 2 - 2, c, 4, 0) END;
    D.AddText(l, lab, left + Pad + lw / 2, cy - hA, Size, 0, th.text);
    IF tk # NIL THEN
      D.AddText(l, tk, left + Pad + tw / 2, cy - hA + lh / 2 + tkh / 2, Size, 0, th.text)
    END;
    IF as # NIL THEN
      D.AddText(l, as, x + w / 2 + Pad - aw - 2 * Pad + aw / 2, cy - hA + lh / 2 + ah / 2, Size, 0,
        th.text)
    END
  END;
  RETURN cy + bh / 2 + Gap
END Item;

(* The items of section s, the first's top at y, s's middle at x
   across, drawn if draw; returns the last's bottom and Gap *)
PROCEDURE Items(s: K.Node; x, y: LONGREAL; draw: BOOLEAN): LONGREAL;
  VAR n: K.Node;
BEGIN
  n := d.nodes;
  WHILE n # NIL DO
    IF (n.section # NIL) & L.Is(n.section.id, s.id^) THEN y := Item(n, x, y, draw) END;
    n := n.next
  END;
  RETURN y
END Items;

(* d laid out at size points, in lay *)
PROCEDURE Make*(dg: K.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR s: K.Node; lab: F.Label; W, top, maxLH, x, w, h, y, height: LONGREAL; cnt, k: LONGINT;
BEGIN
  NEW(l); lay := l; d := dg; l.d := d; D.Init(l, d.g, font, size);
  S.Reset(d.g, l.px); S.KanbanColours(th);
  W := d.sectionWidth; top := -1.5D0 * W;
  maxLH := 25; s := d.nodes;
  WHILE s # NIL DO
    IF s.section = NIL THEN lab := Wrapped(s.label, W, w, h); maxLH := Max(maxLH, h) END;
    s := s.next
  END;
  s := d.nodes; cnt := 0;
  WHILE s # NIL DO
    IF s.section = NIL THEN
      INC(cnt); x := W * cnt + (cnt - 1) * Gap;
      y := Items(s, x, top + maxLH, FALSE);
      height := Max(y - (top + maxLH) + 3 * Pad, 50) + (maxLH - 25);
      k := (cnt - 1) MOD 10 + 2;
      D.AddRect(l, x - W / 2, top, W, height, 5, th.fill[k], th.fill[k], 1);
      lab := Wrapped(s.label, W, w, h);
      D.AddText(l, lab, x, top + h / 2, Size, 0, th.label[k])
    END;
    s := s.next
  END;
  s := d.nodes; cnt := 0;
  WHILE s # NIL DO
    IF s.section = NIL THEN
      INC(cnt); x := W * cnt + (cnt - 1) * Gap;
      y := Items(s, x, top + maxLH, TRUE)
    END;
    s := s.next
  END;
  D.Finish(l, 10);
  l := NIL; d := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: K.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmKanbanLayout.
