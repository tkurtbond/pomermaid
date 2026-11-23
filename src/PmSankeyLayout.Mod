MODULE PmSankeyLayout;
(* PmSankeyLayout: a sankey diagram, PmSankey's, laid out as Mermaid
   12.3.0's sankeyRenderer.ts lays it out with d3-sankey 0.12.3, in its
   pixels, taken at the labels' size, 16 pixels to the size. Lengths
   are in points, y down; a text's y is its middle.

   d3-sankey places the nodes in width by height pixels:

   - a node's value is the greater of its links' values in and out;
   - its depth is the length of the longest path to it, its height
     of the longest from it;
   - its layer, its column, is by nodeAlignment: justify, its depth,
     but the last column for a node no link leaves; left, its depth;
     right, the last column less its height; center, its depth, but a
     node no link enters goes a column before the first of its
     targets;
   - the columns are spread over the width, each node nodeWidth wide;
   - the nodes of each column are stacked, nodePadding apart (15 more
     when showValues), with the scale, ky pixels to the unit of value,
     that fills the fullest column; then moved, in 6 rounds, towards
     the links that join them, each column after the move kept in
     order, by the nodes' tops, and kept from overlapping;
   - each link is as wide as its value at ky, and leaves its source
     and enters its target at its place in the source's links out,
     and the target's in, ordered by the other ends' places.

   The drawing is a list of items, in this order (decision 23):

   - the links, each a band, the Bézier d3's sankeyLinkHorizontal
     makes, from (source.x1, y0) to (target.x0, y1), its control points
     half way across, max(1, width) wide; its colour, by linkColor, the
     source's, the target's, a gradient from the source's to the
     target's across the band, or a fixed colour, at half opacity over
     white; the band is kept as its two sides, Samples + 1 points each;
   - the nodes, each a rectangle in its colour: nodeColors's for the
     node, else d3's schemeTableau10, the 10 in turn, in the nodes'
     order, over the nodes nodeColors does not name;
   - the labels, each the node's name, and with showValues a space,
     prefix, the value rounded to 2 decimals and suffix, 14 pixels, in
     the theme's text colour, its middle at the node's middle, or its
     baseline with showValues; 6 pixels right of the node, or left of
     it, anchored at its end, for a node on the right half of the
     width (labelStyle legacy) or in a column before that of the node
     of greatest value (outlined).

   The bounds are every item's, and everything is moved for them to
   start at (0, 0).

   The arithmetic is LONGREAL, as d3's, and each item's places and
   sizes are rounded once, as it is made, to a 1/8192 point (Snap). *)

IMPORT MathL, L := PmLex, M := PmMetrics, F := PmFlow, G := PmGeom, S := PmStyle,
  GP := PmGanttPic, X := PmXy, K := PmSankey;

CONST
  MermaidSize* = 16;
  LabelSize = 14;
  LabelGap = 6;
  ValuesPad = 15;       (* more nodePadding with showValues *)
  Iterations = 6;
  Samples* = 32;        (* the segments of a link's sides *)
  LinkOpacity = 0.5;
  White = 0FFFFFFH;
  (* items *)
  Link* = 0; Rect* = 1; Text* = 2;
  (* a text's anchor *)
  Start* = 0; End* = 2;

TYPE
  (* A link: its centre line from e[0] to e[1]; its sides p[0 .. Samples]
     and q[0 .. Samples], from source to target, p the upper; width
     wide; coloured fill at the source's end and line at the target's,
     x = e[0].x and x + w = e[1].x the gradient's ends;
     a rectangle: (x, y) its top left corner, w by h, filled with fill;
     a text: lab, size points, its anchor point (x, y), on its middle
     line, where it starts or ends, in colour line; w by h *)
  Item* = POINTER TO ItemDesc;
  ItemDesc* = RECORD
    kind-: INTEGER;
    x-, y-, w-, h-: REAL;
    e-, p-, q-: G.Points;
    fill-, line-: LONGINT;
    width-: REAL;
    lab-: F.Label;
    size-: REAL;
    anchor-: INTEGER;
    next-: Item
  END;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: K.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;      (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    items-: Item                (* in drawing order *)
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;
  Ints = POINTER TO ARRAY OF LONGINT;
  Lists = POINTER TO ARRAY OF Ints;

VAR
  l: Layout;
  last: Item;
  px: LONGREAL;
  minX, minY, maxX, maxY: LONGREAL;
  tableau: ARRAY 10 OF LONGINT;

  (* d3-sankey's graph: the nodes and links by index *)
  nn, nl, layers: LONGINT;
  nx0, nx1, ny0, ny1, nval: Reals;
  depth, height, layer: Ints;
  srcs, tgts: Lists;            (* a node's links out, in *)
  nsrc, ntgt: Ints;
  ls, lt: Ints;                 (* a link's source, target *)
  lval, lwidth, ly0, ly1: Reals;
  placed: POINTER TO ARRAY OF BOOLEAN;  (* whether the node's y0 is set *)
  cols: Lists; ncol: Ints;      (* the columns' nodes *)
  py, ky, dx, width, height0: LONGREAL;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a END;
  RETURN b
END Min;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

(* x rounded to a 1/8192 point, as a REAL, as PmXyLayout's Snap *)
PROCEDURE Snap(x: LONGREAL): REAL;
BEGIN
  IF ABS(x) < 2048 THEN RETURN SHORT(ENTIER(x * 8192 + 0.5D0) / 8192.0D0) END;
  RETURN SHORT(x)
END Snap;

(* Graph *)

PROCEDURE Push(VAR list: Ints; VAR n: LONGINT; x: LONGINT);
  VAR b: Ints; k: LONGINT;
BEGIN
  IF list = NIL THEN NEW(list, 4)
  ELSIF n = LEN(list^) THEN
    NEW(b, 2 * n);
    FOR k := 0 TO n - 1 DO b[k] := list[k] END;
    list := b
  END;
  list[n] := x; INC(n)
END Push;

(* computeNodeLinks and computeNodeValues *)
PROCEDURE NodeLinks(d: K.Diagram);
  VAR k: K.Link; i, j: LONGINT; si, ti: LONGREAL;
BEGIN
  nn := d.nNodes; nl := d.nLinks;
  NEW(nx0, nn); NEW(nx1, nn); NEW(ny0, nn); NEW(ny1, nn); NEW(nval, nn);
  NEW(depth, nn); NEW(height, nn); NEW(layer, nn); NEW(placed, nn);
  NEW(srcs, nn); NEW(tgts, nn); NEW(nsrc, nn); NEW(ntgt, nn);
  NEW(ls, nl); NEW(lt, nl); NEW(lval, nl); NEW(lwidth, nl); NEW(ly0, nl); NEW(ly1, nl);
  FOR i := 0 TO nn - 1 DO
    srcs[i] := NIL; tgts[i] := NIL; nsrc[i] := 0; ntgt[i] := 0; placed[i] := FALSE;
    ny0[i] := 0; ny1[i] := 0
  END;
  k := d.links; j := 0;
  WHILE k # NIL DO
    ls[j] := k.source.index; lt[j] := k.target.index; lval[j] := k.value;
    lwidth[j] := 0; ly0[j] := 0; ly1[j] := 0;
    Push(srcs[ls[j]], nsrc[ls[j]], j); Push(tgts[lt[j]], ntgt[lt[j]], j);
    k := k.next; INC(j)
  END;
  FOR i := 0 TO nn - 1 DO
    si := 0; FOR j := 0 TO nsrc[i] - 1 DO si := si + lval[srcs[i][j]] END;
    ti := 0; FOR j := 0 TO ntgt[i] - 1 DO ti := ti + lval[tgts[i][j]] END;
    nval[i] := Max(si, ti)
  END
END NodeLinks;

(* computeNodeDepths, forward, and computeNodeHeights, not; PmSankey
   has found no cycle *)
PROCEDURE Levels(forward: BOOLEAN; VAR level: Ints);
  VAR cur, next: POINTER TO ARRAY OF BOOLEAN; i, j, x, m: LONGINT; any: BOOLEAN;
BEGIN
  NEW(cur, nn); NEW(next, nn);
  FOR i := 0 TO nn - 1 DO cur[i] := TRUE END;
  x := 0; any := nn > 0;
  WHILE any DO
    FOR i := 0 TO nn - 1 DO next[i] := FALSE END;
    FOR i := 0 TO nn - 1 DO
      IF cur[i] THEN
        level[i] := x;
        IF forward THEN
          FOR j := 0 TO nsrc[i] - 1 DO next[lt[srcs[i][j]]] := TRUE END
        ELSE
          FOR j := 0 TO ntgt[i] - 1 DO next[ls[tgts[i][j]]] := TRUE END
        END
      END
    END;
    INC(x); any := FALSE;
    FOR i := 0 TO nn - 1 DO cur[i] := next[i]; any := any OR next[i] END;
    ASSERT(x <= nn + 1)
  END;
  m := 0
END Levels;

(* align's column for node i, of n *)
PROCEDURE Align(align, i, n: LONGINT): LONGINT;
  VAR c, j, t: LONGINT;
BEGIN
  IF align = K.Left THEN c := depth[i]
  ELSIF align = K.Right THEN c := n - 1 - height[i]
  ELSIF align = K.Center THEN
    IF ntgt[i] > 0 THEN c := depth[i]
    ELSIF nsrc[i] > 0 THEN
      c := MAX(LONGINT);
      FOR j := 0 TO nsrc[i] - 1 DO
        t := depth[lt[srcs[i][j]]];
        IF t < c THEN c := t END
      END;
      DEC(c)
    ELSE c := 0
    END
  ELSE
    IF nsrc[i] > 0 THEN c := depth[i] ELSE c := n - 1 END
  END;
  IF c > n - 1 THEN c := n - 1 END;
  IF c < 0 THEN c := 0 END;
  RETURN c
END Align;

(* computeNodeLayers *)
PROCEDURE NodeLayers(d: K.Diagram);
  VAR i, c: LONGINT; kx: LONGREAL;
BEGIN
  layers := 0;
  FOR i := 0 TO nn - 1 DO
    IF depth[i] + 1 > layers THEN layers := depth[i] + 1 END
  END;
  kx := (width - dx) / (layers - 1);
  NEW(cols, layers); NEW(ncol, layers);
  FOR c := 0 TO layers - 1 DO cols[c] := NIL; ncol[c] := 0 END;
  FOR i := 0 TO nn - 1 DO
    c := Align(d.align, i, layers);
    layer[i] := c;
    nx0[i] := c * kx; nx1[i] := nx0[i] + dx;
    Push(cols[c], ncol[c], i)
  END
END NodeLayers;

(* Sorting, stable *)

(* Whether link a goes after link b in a node's links out, by its
   target's top, then by its index: d3's ascendingTargetBreadth; a top
   not yet set is NaN, and the indexes decide *)
PROCEDURE AfterByTarget(a, b: LONGINT): BOOLEAN;
  VAR c: LONGREAL;
BEGIN
  IF placed[lt[a]] & placed[lt[b]] THEN
    c := ny0[lt[a]] - ny0[lt[b]];
    IF c # 0 THEN RETURN c > 0 END
  END;
  RETURN a > b
END AfterByTarget;

(* The same, for links in, by the sources' tops: ascendingSourceBreadth *)
PROCEDURE AfterBySource(a, b: LONGINT): BOOLEAN;
  VAR c: LONGREAL;
BEGIN
  IF placed[ls[a]] & placed[ls[b]] THEN
    c := ny0[ls[a]] - ny0[ls[b]];
    IF c # 0 THEN RETURN c > 0 END
  END;
  RETURN a > b
END AfterBySource;

PROCEDURE SortLinks(list: Ints; n: LONGINT; byTarget: BOOLEAN);
  VAR i, j, x: LONGINT; after: BOOLEAN;
BEGIN
  FOR i := 1 TO n - 1 DO
    x := list[i]; j := i;
    LOOP
      IF j = 0 THEN EXIT END;
      IF byTarget THEN after := AfterByTarget(list[j - 1], x)
      ELSE after := AfterBySource(list[j - 1], x)
      END;
      IF ~after THEN EXIT END;
      list[j] := list[j - 1]; DEC(j)
    END;
    list[j] := x
  END
END SortLinks;

(* A column's nodes by their tops: ascendingBreadth *)
PROCEDURE SortColumn(list: Ints; n: LONGINT);
  VAR i, j, x: LONGINT;
BEGIN
  FOR i := 1 TO n - 1 DO
    x := list[i]; j := i;
    WHILE (j > 0) & (ny0[list[j - 1]] - ny0[x] > 0) DO list[j] := list[j - 1]; DEC(j) END;
    list[j] := x
  END
END SortColumn;

(* reorderLinks, for the nodes of column c *)
PROCEDURE ReorderLinks(c: LONGINT);
  VAR k, i: LONGINT;
BEGIN
  FOR k := 0 TO ncol[c] - 1 DO
    i := cols[c][k];
    SortLinks(srcs[i], nsrc[i], TRUE); SortLinks(tgts[i], ntgt[i], FALSE)
  END
END ReorderLinks;

(* reorderNodeLinks: the links of the nodes node i is linked with *)
PROCEDURE ReorderNodeLinks(i: LONGINT);
  VAR k, s, t: LONGINT;
BEGIN
  FOR k := 0 TO ntgt[i] - 1 DO
    s := ls[tgts[i][k]]; SortLinks(srcs[s], nsrc[s], TRUE)
  END;
  FOR k := 0 TO nsrc[i] - 1 DO
    t := lt[srcs[i][k]]; SortLinks(tgts[t], ntgt[t], FALSE)
  END
END ReorderNodeLinks;

(* Breadths *)

(* initializeNodeBreadths *)
PROCEDURE InitBreadths;
  VAR c, k, i, j: LONGINT; sum, y, x: LONGREAL; any: BOOLEAN;
BEGIN
  any := FALSE; ky := 0;
  FOR c := 0 TO layers - 1 DO
    IF ncol[c] > 0 THEN
      sum := 0;
      FOR k := 0 TO ncol[c] - 1 DO sum := sum + nval[cols[c][k]] END;
      IF sum > 0 THEN
        x := (height0 - (ncol[c] - 1) * py) / sum;
        IF ~any OR (x < ky) THEN ky := x; any := TRUE END
      END
    END
  END;
  FOR c := 0 TO layers - 1 DO
    y := 0;
    FOR k := 0 TO ncol[c] - 1 DO
      i := cols[c][k];
      ny0[i] := y; ny1[i] := y + nval[i] * ky; placed[i] := TRUE;
      y := ny1[i] + py;
      FOR j := 0 TO nsrc[i] - 1 DO lwidth[srcs[i][j]] := lval[srcs[i][j]] * ky END
    END;
    y := (height0 - y + py) / (ncol[c] + 1);
    FOR k := 0 TO ncol[c] - 1 DO
      i := cols[c][k];
      ny0[i] := ny0[i] + y * (k + 1); ny1[i] := ny1[i] + y * (k + 1)
    END;
    ReorderLinks(c)
  END
END InitBreadths;

(* targetTop: the top of target t that would make the link from s
   straight *)
PROCEDURE TargetTop(s, t: LONGINT): LONGREAL;
  VAR y: LONGREAL; k, j: LONGINT;
BEGIN
  y := ny0[s] - (nsrc[s] - 1) * py / 2;
  k := 0;
  LOOP
    IF k = nsrc[s] THEN EXIT END;
    j := srcs[s][k];
    IF lt[j] = t THEN EXIT END;
    y := y + lwidth[j] + py; INC(k)
  END;
  k := 0;
  LOOP
    IF k = ntgt[t] THEN EXIT END;
    j := tgts[t][k];
    IF ls[j] = s THEN EXIT END;
    y := y - lwidth[j]; INC(k)
  END;
  RETURN y
END TargetTop;

(* sourceTop: the top of source s that would make the link to t
   straight *)
PROCEDURE SourceTop(s, t: LONGINT): LONGREAL;
  VAR y: LONGREAL; k, j: LONGINT;
BEGIN
  y := ny0[t] - (ntgt[t] - 1) * py / 2;
  k := 0;
  LOOP
    IF k = ntgt[t] THEN EXIT END;
    j := tgts[t][k];
    IF ls[j] = s THEN EXIT END;
    y := y + lwidth[j] + py; INC(k)
  END;
  k := 0;
  LOOP
    IF k = nsrc[s] THEN EXIT END;
    j := srcs[s][k];
    IF lt[j] = t THEN EXIT END;
    y := y - lwidth[j]; INC(k)
  END;
  RETURN y
END SourceTop;

PROCEDURE Shift(i: LONGINT; dy: LONGREAL);
BEGIN
  ny0[i] := ny0[i] + dy; ny1[i] := ny1[i] + dy
END Shift;

(* resolveCollisionsTopToBottom *)
PROCEDURE Down(c: LONGINT; y: LONGREAL; k: LONGINT; alpha: LONGREAL);
  VAR i: LONGINT; dy: LONGREAL;
BEGIN
  WHILE k < ncol[c] DO
    i := cols[c][k];
    dy := (y - ny0[i]) * alpha;
    IF dy > 1.0D-6 THEN Shift(i, dy) END;
    y := ny1[i] + py; INC(k)
  END
END Down;

(* resolveCollisionsBottomToTop *)
PROCEDURE Up(c: LONGINT; y: LONGREAL; k: LONGINT; alpha: LONGREAL);
  VAR i: LONGINT; dy: LONGREAL;
BEGIN
  WHILE k >= 0 DO
    i := cols[c][k];
    dy := (ny1[i] - y) * alpha;
    IF dy > 1.0D-6 THEN Shift(i, -dy) END;
    y := ny0[i] - py; DEC(k)
  END
END Up;

PROCEDURE ResolveCollisions(c: LONGINT; alpha: LONGREAL);
  VAR k, i: LONGINT;
BEGIN
  IF ncol[c] = 0 THEN RETURN END;
  k := ncol[c] DIV 2; i := cols[c][k];
  Up(c, ny0[i] - py, k - 1, alpha);
  Down(c, ny1[i] + py, k + 1, alpha);
  Up(c, height0, ncol[c] - 1, alpha);
  Down(c, 0, 0, alpha)
END ResolveCollisions;

(* relaxLeftToRight, leftward FALSE, and relaxRightToLeft, TRUE *)
PROCEDURE Relax(leftward: BOOLEAN; alpha, beta: LONGREAL);
  VAR c, k, i, j, m, o: LONGINT; y, w, v, dy: LONGREAL;
BEGIN
  IF leftward THEN c := layers - 2 ELSE c := 1 END;
  WHILE (c >= 0) & (c < layers) DO
    FOR k := 0 TO ncol[c] - 1 DO
      i := cols[c][k];
      y := 0; w := 0;
      IF leftward THEN
        FOR m := 0 TO nsrc[i] - 1 DO
          j := srcs[i][m]; o := lt[j];
          v := lval[j] * (layer[o] - layer[i]);
          y := y + SourceTop(i, o) * v; w := w + v
        END
      ELSE
        FOR m := 0 TO ntgt[i] - 1 DO
          j := tgts[i][m]; o := ls[j];
          v := lval[j] * (layer[i] - layer[o]);
          y := y + TargetTop(o, i) * v; w := w + v
        END
      END;
      IF w > 0 THEN
        dy := (y / w - ny0[i]) * alpha;
        Shift(i, dy);
        ReorderNodeLinks(i)
      END
    END;
    SortColumn(cols[c], ncol[c]);
    ResolveCollisions(c, beta);
    IF leftward THEN DEC(c) ELSE INC(c) END
  END
END Relax;

(* computeNodeBreadths and computeLinkBreadths *)
PROCEDURE Breadths;
  VAR c, most, k, i, j: LONGINT; alpha, beta, y0, y1: LONGREAL;
BEGIN
  most := 0;
  FOR c := 0 TO layers - 1 DO
    IF ncol[c] > most THEN most := ncol[c] END
  END;
  IF most > 1 THEN py := Min(py, height0 / (most - 1)) END;
  InitBreadths;
  alpha := 1;
  FOR k := 0 TO Iterations - 1 DO
    beta := Max(1 - alpha, (k + 1) / Iterations);
    Relax(TRUE, alpha, beta);
    Relax(FALSE, alpha, beta);
    alpha := alpha * 0.99D0
  END;
  FOR i := 0 TO nn - 1 DO
    y0 := ny0[i]; y1 := y0;
    FOR k := 0 TO nsrc[i] - 1 DO
      j := srcs[i][k]; ly0[j] := y0 + lwidth[j] / 2; y0 := y0 + lwidth[j]
    END;
    FOR k := 0 TO ntgt[i] - 1 DO
      j := tgts[i][k]; ly1[j] := y1 + lwidth[j] / 2; y1 := y1 + lwidth[j]
    END
  END
END Breadths;

(* Items *)

PROCEDURE Add(it: Item);
BEGIN
  it.next := NIL;
  IF last = NIL THEN l.items := it ELSE last.next := it END;
  last := it
END Add;

PROCEDURE NewItem(kind: INTEGER; fill, line: LONGINT): Item;
  VAR it: Item;
BEGIN
  NEW(it); it.kind := kind; it.e := NIL; it.p := NIL; it.q := NIL;
  it.fill := fill; it.line := line; it.width := 0; it.lab := NIL;
  it.x := 0; it.y := 0; it.w := 0; it.h := 0; it.size := 0; it.anchor := Start;
  Add(it);
  RETURN it
END NewItem;

(* The colours of the nodes, 0RRGGBBH *)
PROCEDURE NodeColours(d: K.Diagram; VAR colour: Ints);
  VAR n: K.Node; k: LONGINT;
BEGIN
  NEW(colour, nn); n := d.nodes; k := 0;
  WHILE n # NIL DO
    IF n.colour >= 0 THEN colour[n.index] := n.colour
    ELSE colour[n.index] := tableau[k MOD 10]; INC(k)
    END;
    n := n.next
  END
END NodeColours;

(* The link from (x0, y0) to (x1, y1), in pixels, w wide, its colours
   c0 and c1 at half opacity over white *)
PROCEDURE AddLink(x0, y0, x1, y1, w: LONGREAL; c0, c1: LONGINT);
  VAR it: Item; k: INTEGER; t, u, bx, by, tx, ty, xm, len, hw: LONGREAL;
BEGIN
  it := NewItem(Link, GP.Over(c0, LinkOpacity, White), GP.Over(c1, LinkOpacity, White));
  it.width := Snap(w * px);
  it.e := G.NewPoints(2);
  G.Set(it.e[0], Snap(x0 * px), Snap(y0 * px)); G.Set(it.e[1], Snap(x1 * px), Snap(y1 * px));
  it.x := it.e[0].x; it.w := Snap(x1 * px - x0 * px);
  it.p := G.NewPoints(Samples + 1); it.q := G.NewPoints(Samples + 1);
  xm := (x0 + x1) / 2; hw := w / 2;
  FOR k := 0 TO Samples DO
    t := k / Samples; u := 1 - t;
    (* the Bézier (x0, y0), (xm, y0), (xm, y1), (x1, y1) and its tangent *)
    bx := u * u * u * x0 + 3 * u * u * t * xm + 3 * u * t * t * xm + t * t * t * x1;
    by := u * u * u * y0 + 3 * u * u * t * y0 + 3 * u * t * t * y1 + t * t * t * y1;
    tx := 3 * u * u * (xm - x0) + 3 * t * t * (x1 - xm);
    ty := 6 * u * t * (y1 - y0);
    len := MathL.sqrt(tx * tx + ty * ty);
    IF len = 0 THEN tx := 1; ty := 0 ELSE tx := tx / len; ty := ty / len END;
    G.Set(it.p[k], Snap((bx + ty * hw) * px), Snap((by - tx * hw) * px));
    G.Set(it.q[k], Snap((bx - ty * hw) * px), Snap((by + tx * hw) * px))
  END
END AddLink;

PROCEDURE Links(d: K.Diagram; colour: Ints);
  VAR j, c0, c1: LONGINT;
BEGIN
  IF (d.linkColor = K.Fixed) & (d.linkRgb < 0) THEN RETURN END;
  FOR j := 0 TO nl - 1 DO
    IF d.linkColor = K.Fixed THEN c0 := d.linkRgb; c1 := c0
    ELSIF d.linkColor = K.Source THEN c0 := colour[ls[j]]; c1 := c0
    ELSIF d.linkColor = K.Target THEN c0 := colour[lt[j]]; c1 := c0
    ELSE c0 := colour[ls[j]]; c1 := colour[lt[j]]
    END;
    AddLink(nx1[ls[j]], ly0[j], nx0[lt[j]], ly1[j], Max(1, lwidth[j]), c0, c1)
  END
END Links;

PROCEDURE Nodes(colour: Ints);
  VAR i: LONGINT; it: Item;
BEGIN
  FOR i := 0 TO nn - 1 DO
    it := NewItem(Rect, colour[i], -1);
    it.x := Snap(nx0[i] * px); it.y := Snap(ny0[i] * px);
    it.w := Snap((nx1[i] - nx0[i]) * px); it.h := Snap((ny1[i] - ny0[i]) * px)
  END
END Nodes;

(* n's label's text *)
PROCEDURE LabelText(d: K.Diagram; n: K.Node): L.Str;
  VAR s: L.Str; num: ARRAY 64 OF CHAR; len, i: LONGINT;

  PROCEDURE Cat(a: ARRAY OF CHAR);
    VAR k: LONGINT;
  BEGIN
    k := 0;
    WHILE a[k] # 0X DO s[i] := a[k]; INC(i); INC(k) END
  END Cat;

BEGIN
  IF ~d.showValues THEN RETURN n.name END;
  X.JsNumber(ENTIER(nval[n.index] * 100 + 0.5D0) / 100.0D0, num);
  len := L.Length(n.name^) + L.Length(d.prefix^) + L.Length(num) + L.Length(d.suffix^) + 2;
  NEW(s, len); i := 0;
  Cat(n.name^); Cat(" "); Cat(d.prefix^); Cat(num); Cat(d.suffix^);
  s[i] := 0X;
  RETURN s
END LabelText;

PROCEDURE Labels(d: K.Diagram);
  VAR n: K.Node; i, central: LONGINT; most, x, y: LONGREAL; it: Item; left: BOOLEAN;
    lab: F.Label;
BEGIN
  most := 0; central := 0;
  FOR i := 0 TO nn - 1 DO
    IF nval[i] > most THEN most := nval[i]; central := layer[i] END
  END;
  n := d.nodes;
  WHILE n # NIL DO
    i := n.index;
    IF d.outlined THEN left := layer[i] < central ELSE left := nx0[i] >= width / 2 END;
    lab := F.PlainLabel(LabelText(d, n));
    IF lab.n > 0 THEN
      it := NewItem(Text, -1, S.TextRgb());
      it.lab := lab; it.size := SHORT(LabelSize * px);
      M.LabelSize(l.font, lab, it.size, it.size * 1.2, it.w, it.h);
      IF left THEN x := nx0[i] - LabelGap; it.anchor := End
      ELSE x := nx1[i] + LabelGap; it.anchor := Start
      END;
      y := (ny0[i] + ny1[i]) / 2;
      IF d.showValues THEN y := y - LabelSize * 0.35D0 END;
      it.x := Snap(x * px); it.y := Snap(y * px)
    END;
    n := n.next
  END
END Labels;

(* The colour of the gradient at x, from it's fill to its line *)
PROCEDURE ColourAt(it: Item; x: REAL): LONGINT;
  VAR f: LONGREAL; r, g, b, k, c0, c1: LONGINT;

  PROCEDURE Mix(a, b: LONGINT): LONGINT;
  BEGIN
    RETURN ENTIER(a + (b - a) * f + 0.5D0)
  END Mix;

BEGIN
  IF it.fill = it.line THEN RETURN it.fill END;
  IF it.w <= 0 THEN f := 1 ELSE f := Min(1, Max(0, (x - it.x) / it.w)) END;
  c0 := it.fill; c1 := it.line;
  r := Mix(c0 DIV 10000H, c1 DIV 10000H);
  g := Mix(c0 DIV 100H MOD 100H, c1 DIV 100H MOD 100H);
  b := Mix(c0 MOD 100H, c1 MOD 100H);
  k := r * 10000H + g * 100H + b;
  RETURN k
END ColourAt;

(* Whether the link it is in one colour *)
PROCEDURE Plain*(it: Item): BOOLEAN;
BEGIN
  RETURN it.fill = it.line
END Plain;

(* The outline of the link it, its upper side and its lower back, into
   p[0 .. n-1] *)
PROCEDURE Outline*(it: Item; VAR p: ARRAY OF G.Point; VAR n: INTEGER);
  VAR k: INTEGER;
BEGIN
  n := 0;
  FOR k := 0 TO Samples DO p[n] := it.p[k]; INC(n) END;
  FOR k := Samples TO 0 BY -1 DO p[n] := it.q[k]; INC(n) END
END Outline;

(* The k-th slice of the link it, of Samples, into p[0 .. n-1], and its
   colour: the band from the k-th sample to the (k+2)-th, or the last,
   so that the next slice, drawn over it, leaves no gap *)
PROCEDURE Slice*(it: Item; k: INTEGER; VAR p: ARRAY OF G.Point; VAR n: INTEGER;
  VAR colour: LONGINT);
  VAR j, e: INTEGER; x: REAL;
BEGIN
  e := k + 2;
  IF e > Samples THEN e := Samples END;
  n := 0;
  FOR j := k TO e DO p[n] := it.p[j]; INC(n) END;
  FOR j := e TO k BY -1 DO p[n] := it.q[j]; INC(n) END;
  x := (it.p[k].x + it.p[k + 1].x + it.q[k].x + it.q[k + 1].x) / 4;
  colour := ColourAt(it, x)
END Slice;

(* Bounds *)

PROCEDURE Bound(x0, y0, x1, y1: LONGREAL);
BEGIN
  IF x0 < minX THEN minX := x0 END;
  IF y0 < minY THEN minY := y0 END;
  IF x1 > maxX THEN maxX := x1 END;
  IF y1 > maxY THEN maxY := y1 END
END Bound;

PROCEDURE BoundPoints(p: G.Points);
  VAR k: LONGINT;
BEGIN
  FOR k := 0 TO LEN(p^) - 1 DO Bound(p[k].x, p[k].y, p[k].x, p[k].y) END
END BoundPoints;

PROCEDURE BoundItem(it: Item);
  VAR a: LONGREAL;
BEGIN
  IF it.kind = Link THEN BoundPoints(it.p); BoundPoints(it.q)
  ELSIF it.kind = Rect THEN Bound(it.x, it.y, it.x + it.w, it.y + it.h)
  ELSE
    IF it.anchor = Start THEN a := 0 ELSE a := -it.w END;
    Bound(it.x + a, it.y - it.h / 2, it.x + a + it.w, it.y + it.h / 2)
  END
END BoundItem;

PROCEDURE MovePoints(p: G.Points; dx, dy: LONGREAL);
  VAR k: LONGINT;
BEGIN
  IF p # NIL THEN
    FOR k := 0 TO LEN(p^) - 1 DO G.Set(p[k], Snap(p[k].x + dx), Snap(p[k].y + dy)) END
  END
END MovePoints;

PROCEDURE Move(it: Item; dx, dy: LONGREAL);
BEGIN
  MovePoints(it.e, dx, dy); MovePoints(it.p, dx, dy); MovePoints(it.q, dx, dy);
  it.x := Snap(it.x + dx); it.y := Snap(it.y + dy)
END Move;

(* Lays d out, its text set in font at size points, into lay *)
PROCEDURE Make*(d: K.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR colour: Ints; ddx, ddy: LONGREAL; it: Item;
BEGIN
  NEW(l); lay := l; l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := SHORT(px); l.items := NIL; last := NIL;
  S.Reset(d.g, l.px);
  width := d.width; height0 := d.height; dx := d.nodeWidth;
  py := d.nodePadding;
  IF d.showValues THEN py := py + ValuesPad END;
  NodeLinks(d);
  Levels(TRUE, depth); Levels(FALSE, height);
  NodeLayers(d);
  Breadths;
  NodeColours(d, colour);
  Links(d, colour);
  Nodes(colour);
  Labels(d);
  (* the bounds, and everything moved for them *)
  it := l.items;
  IF it # NIL THEN
    minX := MAX(REAL); minY := MAX(REAL); maxX := -MAX(REAL); maxY := -MAX(REAL)
  ELSE minX := 0; minY := 0; maxX := 0; maxY := 0
  END;
  WHILE it # NIL DO BoundItem(it); it := it.next END;
  ddx := -minX; ddy := -minY;
  l.width := Snap(maxX - minX); l.height := Snap(maxY - minY);
  IF (ddx # 0) OR (ddy # 0) THEN
    it := l.items;
    WHILE it # NIL DO Move(it, ddx, ddy); it := it.next END
  END
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

BEGIN
  tableau[0] := 4E79A7H; tableau[1] := 0F28E2CH; tableau[2] := 0E15759H;
  tableau[3] := 76B7B2H; tableau[4] := 59A14FH; tableau[5] := 0EDC949H;
  tableau[6] := 0AF7AA1H; tableau[7] := 0FF9DA7H; tableau[8] := 9C755FH;
  tableau[9] := 0BAB0ABH
END PmSankeyLayout.
