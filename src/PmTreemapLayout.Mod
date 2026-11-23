MODULE PmTreemapLayout;
(* PmTreemapLayout: a treemap, PmTreemap's, laid out in Mermaid's
   pixels, taken at the drawing's size, 16 pixels to the size, and
   drawn as Mermaid 12.3.0 draws it, with d3's hierarchy and treemap.
   Lengths are in points, y down.

   - Each section's value is the sum of its children's; each node's
     children are sorted by value, the largest first, those with the
     same value in the order read.
   - The treemap is width by height, below the title, 30 high if there
     is one. Each node with children keeps 35 above them, 10 on the
     other sides, and padding between them; they are laid out by d3's
     squarify, golden ratio, and every side is rounded to a pixel.
   - A section is filled with its name's colour, cScale, at 0.6, and
     outlined with its peer, cScalePeer, at 0.4, 2 wide; its name is
     bold, 12 pixels, 6 from its left, 12.5 from its top, shortened
     with "..." to fit; its value, if values are shown, italic, 10
     pixels, ends 10 from its right. A leaf is filled with its
     section's colour at 0.3 and outlined with it, 3 wide; its name and
     value are in the middle, the name 38 pixels or less to fit, the
     value 0.6 of that (16 and 14 if there are more than 20 leaves).
     Leaves at the top have no section: they are neither filled nor
     outlined. Opacity is drawn by blending the colour with what is
     under it (decision 33).
   - The colours are d3 ordinal scales keyed by name, in the order the
     names are first used: cScale's first colour is none, then cScale0
     to cScale11; the text colours are cScaleLabel0 to cScaleLabel11.
   - A class's fill, stroke and stroke-width replace the colours and
     widths, at the same opacity; its color, the text's.
   - Mermaid clips the names; pomermaid cannot, so a name that would be
     clipped is not drawn (decision 34). A node that is no wide or no
     high is not drawn, nor its text.

   The bounds are every item's, widened by diagramPadding on each
   side. *)

IMPORT M := PmMetrics, F := PmFlow, S := PmStyle, T := PmTreemap, D := PmDraw, L := PmLex;

CONST
  White = 0FFFFFFH;
  Header = 25;          (* a section's name's band *)
  Inner = 10;           (* a section's padding at the sides and bottom *)
  Phi = 1.618033988749895D0;
  Big = 1.0D9;          (* rounded only below this *)

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: T.Diagram
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;
  Ints = POINTER TO ARRAY OF LONGINT;
  Nodes = POINTER TO ARRAY OF T.Node;
  Keys = POINTER TO ARRAY OF L.Str;

VAR
  l: Layout;
  d: T.Diagram;
  tl: S.TimelineTheme;
  peer: ARRAY 12 OF LONGINT;
  n: LONGINT;                      (* nodes, the root's index *)
  x0, y0, x1, y1, val: Reals;      (* by Id *)
  shown: Ints;                     (* the colour drawn, by Id *)
  first, count: Ints;              (* each node's children in kids *)
  kids: Nodes;
  bfs, leaves: Nodes; nBfs, nLeaves: LONGINT;
  cKeys, lKeys: Keys; nC, nL: LONGINT;  (* the scales' keys *)
  top: LONGREAL;                   (* the title's height *)
  buf: L.Str;

PROCEDURE Id(nd: T.Node): LONGINT;
BEGIN
  IF nd.index < 0 THEN RETURN n END;
  RETURN nd.index
END Id;

(* rgb at opacity a over back *)
PROCEDURE Over(rgb: LONGINT; a: LONGREAL; back: LONGINT): LONGINT;
  VAR k, c, b, r, m: LONGINT;
BEGIN
  IF rgb < 0 THEN RETURN back END;
  r := 0; m := 10000H;
  FOR k := 0 TO 2 DO
    c := rgb DIV m MOD 100H; b := back DIV m MOD 100H;
    r := r * 100H + ENTIER(c * a + b * (1 - a) + 0.5D0);
    m := m DIV 100H
  END;
  RETURN r
END Over;

(* JavaScript's Math.round *)
PROCEDURE Round(x: LONGREAL): LONGREAL;
BEGIN
  IF (x > -Big) & (x < Big) THEN RETURN ENTIER(x + 0.5D0) END;
  RETURN x
END Round;

(* lab with every byte in style st *)
PROCEDURE Styled(lab: F.Label; st: SHORTINT): F.Label;
  VAR r: F.Label; line, nl, last: F.Line; k, len: LONGINT;
BEGIN
  NEW(r); r^ := lab^; r.lines := NIL; last := NIL;
  line := lab.lines;
  WHILE line # NIL DO
    NEW(nl); nl^ := line^; nl.next := NIL;
    len := 0; WHILE line.text[len] # 0X DO INC(len) END;
    NEW(nl.style, len + 1);
    FOR k := 0 TO len - 1 DO nl.style[k] := st END;
    nl.style[len] := F.Roman;
    IF last = NIL THEN r.lines := nl ELSE last.next := nl END;
    last := nl;
    line := line.next
  END;
  RETURN r
END Styled;

(* The hierarchy *)

(* nd's value, the sum of its children's, and its children sorted *)
PROCEDURE Sum(nd: T.Node; VAR next: LONGINT);
  VAR c, t: T.Node; k, j, i: LONGINT; s: LONGREAL;
BEGIN
  i := Id(nd);
  first[i] := next; count[i] := nd.nChildren; INC(next, nd.nChildren);
  IF nd.leaf THEN s := nd.value ELSE s := 0 END;
  c := nd.children; k := first[i];
  WHILE c # NIL DO Sum(c, next); s := s + val[Id(c)]; kids[k] := c; INC(k); c := c.next END;
  val[i] := s;
  (* stable, the largest first *)
  FOR k := first[i] + 1 TO first[i] + count[i] - 1 DO
    t := kids[k]; j := k;
    WHILE (j > first[i]) & (val[Id(kids[j - 1])] < val[Id(t)]) DO kids[j] := kids[j - 1]; DEC(j) END;
    kids[j] := t
  END
END Sum;

(* d3's treemapDice (along x) or treemapSlice (along y): kids[a .. b-1],
   their values summing to sum, in (bx0, by0, bx1, by1) *)
PROCEDURE Row(a, b: LONGINT; sum: LONGREAL; dice: BOOLEAN; bx0, by0, bx1, by1: LONGREAL);
  VAR k, i: LONGINT; f: LONGREAL;
BEGIN
  IF dice THEN
    IF sum # 0 THEN f := (bx1 - bx0) / sum ELSE f := 0 END;
    FOR k := a TO b - 1 DO
      i := Id(kids[k]);
      y0[i] := by0; y1[i] := by1; x0[i] := bx0; bx0 := bx0 + val[i] * f; x1[i] := bx0
    END
  ELSE
    IF sum # 0 THEN f := (by1 - by0) / sum ELSE f := 0 END;
    FOR k := a TO b - 1 DO
      i := Id(kids[k]);
      x0[i] := bx0; x1[i] := bx1; y0[i] := by0; by0 := by0 + val[i] * f; y1[i] := by0
    END
  END
END Row;

(* d3's squarify, golden ratio: nd's children in (bx0, by0, bx1, by1).
   Where JavaScript's arithmetic would give infinities, every node left
   goes in one row; where it would give NaN, with nothing left to share
   out, they are no wide or no high. *)
PROCEDURE Squarify(nd: T.Node; bx0, by0, bx1, by1: LONGREAL);
  VAR i0, i1, e: LONGINT; value, dx, dy, sum, minV, maxV, v, alpha, beta, ratio, newRatio: LONGREAL;
    degenerate: BOOLEAN;
BEGIN
  i0 := first[Id(nd)]; e := i0 + count[Id(nd)]; i1 := i0;
  value := val[Id(nd)];
  WHILE i0 < e DO
    dx := bx1 - bx0; dy := by1 - by0;
    REPEAT sum := val[Id(kids[i1])]; INC(i1) UNTIL (sum # 0) OR (i1 >= e);
    minV := sum; maxV := sum;
    degenerate := (value <= 0) OR (dx <= 0) OR (dy <= 0);
    IF degenerate THEN
      WHILE i1 < e DO sum := sum + val[Id(kids[i1])]; INC(i1) END
    ELSIF sum # 0 THEN
      IF dy / dx > dx / dy THEN alpha := dy / dx ELSE alpha := dx / dy END;
      alpha := alpha / (value * Phi);
      beta := sum * sum * alpha;
      IF maxV / beta > beta / minV THEN ratio := maxV / beta ELSE ratio := beta / minV END;
      LOOP
        IF i1 >= e THEN EXIT END;
        v := val[Id(kids[i1])];
        IF v = 0 THEN EXIT END;  (* its ratio is infinite *)
        sum := sum + v;
        IF v < minV THEN minV := v END;
        IF v > maxV THEN maxV := v END;
        beta := sum * sum * alpha;
        IF maxV / beta > beta / minV THEN newRatio := maxV / beta ELSE newRatio := beta / minV END;
        IF newRatio > ratio THEN sum := sum - v; EXIT END;
        ratio := newRatio; INC(i1)
      END
    END;
    IF dx < dy THEN
      IF value <= 0 THEN Row(i0, i1, sum, TRUE, bx0, by0, bx1, by0)
      ELSIF dy # 0 THEN Row(i0, i1, sum, TRUE, bx0, by0, bx1, by0 + dy * sum / value); by0 := by0 + dy * sum / value
      ELSE Row(i0, i1, sum, TRUE, bx0, by0, bx1, by1)
      END
    ELSE
      IF value <= 0 THEN Row(i0, i1, sum, FALSE, bx0, by0, bx0, by1)
      ELSIF dx # 0 THEN Row(i0, i1, sum, FALSE, bx0, by0, bx0 + dx * sum / value, by1); bx0 := bx0 + dx * sum / value
      ELSE Row(i0, i1, sum, FALSE, bx0, by0, bx1, by1)
      END
    END;
    value := value - sum; i0 := i1
  END
END Squarify;

(* d3's treemap's positionNode, for nd and those under it *)
PROCEDURE Position(nd: T.Node; depth: LONGINT);
  VAR i, k: LONGINT; p, a0, b0, a1, b1: LONGREAL;
BEGIN
  i := Id(nd);
  IF depth = 0 THEN p := 0 ELSE p := d.padding / 2 END;
  a0 := x0[i] + p; b0 := y0[i] + p; a1 := x1[i] - p; b1 := y1[i] - p;
  IF a1 < a0 THEN a0 := (a0 + a1) / 2; a1 := a0 END;
  IF b1 < b0 THEN b0 := (b0 + b1) / 2; b1 := b0 END;
  x0[i] := a0; y0[i] := b0; x1[i] := a1; y1[i] := b1;
  IF count[i] > 0 THEN
    p := d.padding / 2;
    a0 := a0 + Inner - p; b0 := b0 + Header + Inner - p; a1 := a1 - (Inner - p); b1 := b1 - (Inner - p);
    IF a1 < a0 THEN a0 := (a0 + a1) / 2; a1 := a0 END;
    IF b1 < b0 THEN b0 := (b0 + b1) / 2; b1 := b0 END;
    Squarify(nd, a0, b0, a1, b1);
    FOR k := first[i] TO first[i] + count[i] - 1 DO Position(kids[k], depth + 1) END
  END
END Position;

(* bfs, the nodes with children, breadth first; leaves, those without,
   in pre-order *)
PROCEDURE Orders;
  VAR h, k, i: LONGINT; nd: T.Node;

  PROCEDURE Pre(nd: T.Node);
    VAR k, i: LONGINT;
  BEGIN
    i := Id(nd);
    IF count[i] = 0 THEN leaves[nLeaves] := nd; INC(nLeaves) END;
    FOR k := first[i] TO first[i] + count[i] - 1 DO Pre(kids[k]) END
  END Pre;

BEGIN
  nBfs := 0; nLeaves := 0;
  NEW(bfs, n + 1); NEW(leaves, n + 1);
  bfs[0] := d.root; h := 0; nBfs := 1;
  WHILE h < nBfs DO
    nd := bfs[h]; i := Id(nd); INC(h);
    FOR k := first[i] TO first[i] + count[i] - 1 DO bfs[nBfs] := kids[k]; INC(nBfs) END
  END;
  (* keep those with children *)
  h := 0;
  FOR k := 0 TO nBfs - 1 DO
    IF count[Id(bfs[k])] > 0 THEN bfs[h] := bfs[k]; INC(h) END
  END;
  nBfs := h;
  Pre(d.root)
END Orders;

(* The ordinal scales *)

PROCEDURE Key(VAR keys: Keys; VAR nk: LONGINT; name: L.Str): LONGINT;
  VAR k: LONGINT;
BEGIN
  k := 0;
  WHILE (k < nk) & ~L.Equal(keys[k], name) DO INC(k) END;
  IF k = nk THEN keys[nk] := name; INC(nk) END;
  RETURN k
END Key;

(* name's colour: none, or cScale0..11 *)
PROCEDURE Colour(name: L.Str): LONGINT;
  VAR k: LONGINT;
BEGIN
  k := Key(cKeys, nC, name) MOD 13;
  IF k = 0 THEN RETURN -1 END;
  RETURN tl.scale[k - 1]
END Colour;

PROCEDURE Peer(name: L.Str): LONGINT;
  VAR k: LONGINT;
BEGIN
  k := Key(cKeys, nC, name) MOD 13;
  IF k = 0 THEN RETURN -1 END;
  RETURN peer[k - 1]
END Peer;

PROCEDURE LabelColour(name: L.Str): LONGINT;
BEGIN
  RETURN tl.label[Key(lKeys, nL, name) MOD 12]
END LabelColour;

(* Keys the scales in the order Mermaid first uses them *)
PROCEDURE Scales;
  VAR k: LONGINT; c: LONGINT; nd: T.Node;
BEGIN
  NEW(cKeys, n + 2); NEW(lKeys, n + 2); nC := 0; nL := 0;
  FOR k := 0 TO nBfs - 1 DO c := Colour(bfs[k].name) END;
  FOR k := 0 TO nBfs - 1 DO IF bfs[k] # d.root THEN c := LabelColour(bfs[k].name) END END;
  FOR k := 0 TO nLeaves - 1 DO
    nd := leaves[k];
    IF nd.parent # NIL THEN c := Colour(nd.parent.name) ELSE c := Colour(nd.name) END;
    c := LabelColour(nd.name)
  END
END Scales;

(* A class's colour, s, in rgb (-1 for none); FALSE if there is none *)
PROCEDURE ClassColour(s: L.Str; VAR rgb: LONGINT): BOOLEAN;
  VAR none: BOOLEAN; c: LONGINT;
BEGIN
  IF s = NIL THEN RETURN FALSE END;
  IF S.ParseColour(s^, c, none) THEN
    IF none THEN rgb := -1 ELSE rgb := c END;
    RETURN TRUE
  END;
  RETURN FALSE
END ClassColour;

(* A class's width, s, in pixels *)
PROCEDURE ClassWidth(s: L.Str; VAR w: LONGREAL);
  VAR x: REAL;
BEGIN
  IF (s # NIL) & S.ParseLength(s^, x) THEN w := x / l.px END
END ClassWidth;

(* A label of name's first k bytes, and "..." if dots *)
PROCEDURE Cut(lab: F.Label; k: LONGINT; dots: BOOLEAN): F.Label;
  VAR i, m: LONGINT; t: L.Str;
BEGIN
  t := lab.lines.text; m := 0;
  IF LEN(buf^) < k + 8 THEN NEW(buf, k + 8) END;
  FOR i := 0 TO k - 1 DO buf[m] := t[i]; INC(m) END;
  IF dots THEN buf[m] := "."; buf[m + 1] := "."; buf[m + 2] := "."; INC(m, 3) END;
  buf[m] := 0X;
  RETURN F.PlainLabel(L.Sub(buf^, 0, m))
END Cut;

(* The width of lab, size pixels *)
PROCEDURE Width(lab: F.Label; size: LONGREAL): LONGREAL;
  VAR w, h: LONGREAL;
BEGIN
  IF (lab = NIL) OR (lab.n = 0) THEN RETURN 0 END;
  D.Measure(l, lab, size, w, h);
  RETURN w
END Width;

(* nd's name, bold, shortened to avail pixels as Mermaid shortens it, a
   code point at a time; NIL if nothing fits *)
PROCEDURE Shortened(nd: T.Node; avail: LONGREAL): F.Label;
  VAR lab: F.Label; k: LONGINT; t: L.Str;
BEGIN
  lab := Styled(nd.label, F.Bold);
  IF (lab.n = 0) OR (Width(lab, 12) <= avail) THEN RETURN lab END;
  t := nd.label.lines.text;
  k := 0; WHILE t[k] # 0X DO INC(k) END;
  LOOP
    DEC(k); WHILE (k > 0) & (ORD(t[k]) DIV 64 = 2) DO DEC(k) END;
    IF k <= 0 THEN
      lab := Styled(Cut(nd.label, 0, TRUE), F.Bold);
      IF Width(lab, 12) > avail THEN RETURN NIL END;
      RETURN lab
    END;
    lab := Styled(Cut(nd.label, k, TRUE), F.Bold);
    IF Width(lab, 12) <= avail THEN RETURN lab END
  END
END Shortened;

(* The drawing *)

PROCEDURE Sections;
  VAR k, i: LONGINT; nd: T.Node; fill, line, back, text: LONGINT; w, h, width, avail, lw: LONGREAL;
    lab: F.Label; s: ARRAY 4400 OF CHAR; vl: F.Label;
BEGIN
  FOR k := 0 TO nBfs - 1 DO
    nd := bfs[k]; i := Id(nd);
    w := x1[i] - x0[i]; h := y1[i] - y0[i];
    IF nd = d.root THEN shown[i] := White
    ELSE
      back := shown[Id(nd.parent)];
      fill := Colour(nd.name); IF ClassColour(nd.fill, fill) THEN END;
      line := Peer(nd.name); IF ClassColour(nd.stroke, line) THEN END;
      width := 2; ClassWidth(nd.strokeWidth, width);
      shown[i] := Over(fill, 0.6D0, back);
      IF line >= 0 THEN line := Over(line, 0.4D0, back) END;
      IF (w > 0) & (h > 0) THEN
        IF fill >= 0 THEN fill := shown[i] END;
        D.AddRect(l, x0[i], y0[i] + top, w, h, 0, fill, line, width);
        text := LabelColour(nd.name); IF ClassColour(nd.color, text) THEN END;
        IF d.showValues & (val[i] # 0) THEN avail := w - 56 ELSE avail := w - 12 END;
        IF avail < 15 THEN avail := 15 END;
        lab := Shortened(nd, avail);
        IF lab # NIL THEN
          lw := Width(lab, 12);
          IF 6 + lw <= w - 6 THEN D.AddFittedText(l, lab, x0[i] + 6 + lw / 2, y0[i] + top + Header / 2, 12, 0, text) END
        END;
        IF d.showValues & (val[i] # 0) THEN
          T.Format(d, val[i], s);
          vl := Styled(F.PlainLabel(L.New(s)), F.Italic);
          lw := Width(vl, 10);
          D.AddFittedText(l, vl, x1[i] - 10 - lw / 2, y0[i] + top + Header / 2, 10, 0, text)
        END
      END
    END
  END
END Sections;

PROCEDURE Leaves;
  VAR k, i: LONGINT; nd: T.Node; fill, line, back, text: LONGINT; w, h, width, aw, ah, fs, vfs, vt: LONGREAL;
    base, baseV, minL, minV, pad, thr, sp: LONGREAL; s: ARRAY 4400 OF CHAR; vl: F.Label; name: L.Str;

  PROCEDURE ValueSize(fs: LONGREAL): LONGREAL;
    VAR v: LONGREAL;
  BEGIN
    v := Round(fs * 0.6D0);
    IF v > baseV THEN v := baseV END;
    IF v < minV THEN v := minV END;
    RETURN v
  END ValueSize;

BEGIN
  IF nLeaves > 20 THEN base := 16; baseV := 14; minL := 4; minV := 4; pad := 2; thr := 8; sp := 1
  ELSE base := 38; baseV := 28; minL := 8; minV := 6; pad := 4; thr := 10; sp := 2
  END;
  FOR k := 0 TO nLeaves - 1 DO
    nd := leaves[k]; i := Id(nd);
    w := x1[i] - x0[i]; h := y1[i] - y0[i];
    IF nd.parent # NIL THEN back := shown[Id(nd.parent)]; name := nd.parent.name
    ELSE back := White; name := nd.name
    END;
    fill := Colour(name); IF ClassColour(nd.fill, fill) THEN END;
    line := Colour(name); IF ClassColour(nd.stroke, line) THEN END;
    width := 3; ClassWidth(nd.strokeWidth, width);
    IF fill >= 0 THEN fill := Over(fill, 0.3D0, back) END;
    IF line < 0 THEN width := 0 END;
    IF (w > 0) & (h > 0) THEN
      D.AddRect(l, x0[i], y0[i] + top, w, h, 0, fill, line, width);
      text := LabelColour(nd.name); IF ClassColour(nd.color, text) THEN END;
      aw := w - 2 * pad; ah := h - 2 * pad;
      IF (aw >= thr) & (ah >= thr) & (nd.label.n > 0) THEN
        fs := base;
        WHILE (Width(nd.label, fs) > aw) & (fs > minL) DO fs := fs - 1 END;
        WHILE (fs + sp + ValueSize(fs) > ah) & (fs > minL) DO fs := fs - 1 END;
        IF (Width(nd.label, fs) <= aw) & (fs >= minL) & (ah >= fs) THEN
          D.AddFittedText(l, nd.label, x0[i] + w / 2, y0[i] + top + h / 2, fs, 0, text);
          IF d.showValues & (val[i] # 0) THEN
            vfs := ValueSize(fs);
            vt := h / 2 + fs / 2 + sp;
            T.Format(d, val[i], s);
            vl := F.PlainLabel(L.New(s));
            IF (Width(vl, vfs) <= aw) & (vt + vfs <= h - 4) THEN
              D.AddFittedText(l, vl, x0[i] + w / 2, y0[i] + top + vt + vfs / 2, vfs, 0, text)
            END
          END
        END
      END
    END
  END
END Leaves;

(* Lays d out, its text set in font, the drawing at size points, into lay *)
PROCEDURE Make*(dg: T.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR next, i: LONGINT;
BEGIN
  d := dg; n := d.nNodes;
  NEW(l); lay := l; l.d := d; D.Init(l, d.g, font, size);
  S.Reset(d.g, l.px);
  S.TimelineColours(tl); S.PeerColours(peer);
  NEW(x0, n + 1); NEW(y0, n + 1); NEW(x1, n + 1); NEW(y1, n + 1); NEW(val, n + 1);
  NEW(shown, n + 1); NEW(first, n + 1); NEW(count, n + 1); NEW(kids, n + 1);
  next := 0; Sum(d.root, next);
  x0[n] := 0; y0[n] := 0; x1[n] := d.width; y1[n] := d.height;
  Position(d.root, 0);
  FOR i := 0 TO n DO
    x0[i] := Round(x0[i]); y0[i] := Round(y0[i]); x1[i] := Round(x1[i]); y1[i] := Round(y1[i])
  END;
  Orders; Scales;
  IF d.g.title # NIL THEN
    top := 30;
    D.AddText(l, d.g.title, d.width / 2, 15, 14, 0, S.Rgb(S.TitleColour()))
  ELSE top := 0
  END;
  Sections; Leaves;
  D.Finish(l, d.diagramPadding);
  d := NIL; x0 := NIL; y0 := NIL; x1 := NIL; y1 := NIL; val := NIL; shown := NIL;
  first := NIL; count := NIL; kids := NIL; bfs := NIL; leaves := NIL; cKeys := NIL; lKeys := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: T.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

BEGIN
  NEW(buf, 256)
END PmTreemapLayout.
