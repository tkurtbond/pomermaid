MODULE PmFlowLayout;
(* PmFlowLayout: a flowchart laid out. Each node is sized by its label,
   measured in a groff font (PmMetrics), and its shape; each edge label
   by its text. PmLayout places them. Then each edge's ends are moved
   in from its nodes' boxes to their outlines, as Mermaid's intersect
   functions do.

   A label wider than Mermaid's wrappingWidth, 200 pixels, is wrapped
   at spaces, as Mermaid wraps it; its box is as wide as its widest
   line, where Mermaid's is 200 pixels wide.

   The spacing is Mermaid's, nodeSpacing and rankSpacing 50 pixels for
   its 16 pixel text, scaled to the size of the labels.

   Each subgraph is a cluster of the layout, its title measured as a
   label. A node with a subgraph's id, where that subgraph holds nodes,
   stands for the subgraph, as in Mermaid: it is hidden, and an edge to
   it goes to the first node the subgraph holds and ends at the
   subgraph's box. A subgraph that holds no node has no box. *)

IMPORT Math, F := PmFlow, M := PmMetrics, G := PmGeom, L := PmLayout, Lx := PmLex,
  Shp := PmShapes;

CONST
  Spacing = 50;    (* Mermaid's nodeSpacing and rankSpacing, in pixels *)
  ErNodeSpacing = 140; ErRankSpacing = 80; (* an ER diagram's, in pixels *)
  EdgeSpacing = 20; (* dagre's edgesep *)
  MermaidSize* = 16; (* Mermaid's font size, in pixels *)
  WrapWidth = 200;  (* Mermaid's wrappingWidth: wider labels wrap, in pixels *)
  TitleSize = 18;   (* the title's font size, in pixels *)
  TitleMargin* = 25; (* Mermaid's titleTopMargin: from the title's baseline
                        to the drawing's top, in pixels *)
  ClusterRankGap = 25; (* added to the rank spacing of an isolated
                        subgraph's layout, in pixels *)
  (* Mermaid's collapsedGroup, in pixels: at least GroupWidth wide, its
     title's width and GroupPad; its title's height and GroupExtra
     high; its title GroupTitle above its centre *)
  GroupWidth* = 80; GroupPad* = 16; GroupExtra* = 44; GroupTitle* = 14;

TYPE
  Flags* = POINTER TO ARRAY OF BOOLEAN;

  (* A class box's parts, as offsets down from its top, in points: the
     centres of its annotation, title, members and methods, and its two
     dividers; and P, its padding *)
  ClassPart* = RECORD
    annY-, titleY-, d1-, memY-, d2-, metY-, pad-: REAL
  END;
  ClassParts* = POINTER TO ARRAY OF ClassPart;

  (* An ER diagram's entity box's parts, in points: the height of its
     name's row; the widths of its table's columns, type, name, keys and
     comment, 0 for the keys' or the comment's if no attribute has them;
     each row's height; and the padding, 10 pixels, from a column's left
     side to its text *)
  ErPart* = RECORD
    nameH-, rowH-, pad-: REAL;
    col-: ARRAY 4 OF REAL
  END;
  ErParts* = POINTER TO ARRAY OF ErPart;

  (* A layout of one scope: the whole flowchart, or an isolated
     subgraph *)
  Scope* = POINTER TO ScopeDesc;
  ScopeDesc* = RECORD
    cluster-: INTEGER;  (* the isolated subgraph, or -1 for the whole *)
    g-: L.Graph;        (* its layout, from (0, 0) *)
    node-: L.Ints;      (* for each node of g, not a dummy, the
                           flowchart's node of that index, or -1-k for
                           the box of subgraph k, isolated or collapsed *)
    edge-: L.Ints;      (* for each edge of g, the flowchart's *)
    clus-: L.Ints;      (* for each cluster of g, the subgraph *)
    x-, y-: REAL;       (* where g's (0, 0) is in the drawing *)
    next-: Scope        (* the next, inner ones first, the whole last *)
  END;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    graph-: F.Graph;
    font-: M.Font;         (* the labels' font *)
    g-: L.Graph;           (* node i is graph's node of index i; edge j, edge j;
                              cluster k, subgraph k; each where it is in the
                              drawing, not laid out itself *)
    scopes-: Scope;        (* the layouts, inner first *)
    collapsed-, isolated-: Flags; (* each subgraph's:
                              the outermost of those collapsed, or isolated *)
    textW-, textH-: POINTER TO ARRAY OF REAL; (* each node's label's size *)
    nodeLabel-, edgeLabel-: POINTER TO ARRAY OF F.Label; (* the labels, wrapped *)
    clusterLabel-: POINTER TO ARRAY OF F.Label; (* the subgraphs' titles, wrapped;
                              cluster i of g is the subgraph of index i *)
    stands-: L.Ints; (* for each node, the cluster it
                              stands for, or -1 *)
    parts-: ClassParts;    (* each node's, if it is a class box *)
    er-: ErParts;          (* each node's, if it is an entity box *)
    size-, vs-: REAL;      (* the labels' size and line spacing *)
    title-: F.Label;       (* the diagram's title, or NIL *)
    titleSize-, titleW-, titleH-: REAL; (* its size, and its width and height *)
    titleX-, titleY-: REAL (* its baseline's centre, above the drawing *)
  END;

(* The outline of a node of shape shape, w by h, centred at (cx, cy):
   pts[0 .. n-1], the corners of a polygon, for the shapes drawn as
   polygons; n is 0 for the others (rectangles, rounded and stadium
   shapes, subroutines, cylinders, circles), whose outline is their
   box or, for circles, the circle in it; PmShapes's for its shapes,
   at size points. y runs down. *)
PROCEDURE Outline*(shape: INTEGER; cx, cy, w, h, size: REAL; VAR pts: G.Points; VAR n: INTEGER);
  VAR x0, top, bot, m: REAL;

  PROCEDURE P(x, y: REAL);
  BEGIN
    G.Set(pts[n], x, y); INC(n)
  END P;

BEGIN
  IF Shp.Has(shape) THEN Shp.Outline(shape, cx, cy, w, h, size, pts, n); RETURN END;
  pts := G.NewPoints(6); n := 0;
  x0 := cx - w / 2; top := cy - h / 2; bot := cy + h / 2;
  CASE shape OF
    F.Diamond: P(cx, top); P(x0 + w, cy); P(cx, bot); P(x0, cy)
  | F.Hexagon:
      m := h / 4;
      P(x0 + m, top); P(x0 + w - m, top); P(x0 + w, cy);
      P(x0 + w - m, bot); P(x0 + m, bot); P(x0, cy)
  | F.LeanRight: P(x0, bot); P(x0 + w - h / 2, bot); P(x0 + w, top); P(x0 + h / 2, top)
  | F.LeanLeft: P(x0 + h / 2, bot); P(x0 + w, bot); P(x0 + w - h / 2, top); P(x0, top)
  | F.Trapezoid: P(x0, bot); P(x0 + w, bot); P(x0 + w - h / 2, top); P(x0 + h / 2, top)
  | F.InvTrapezoid: P(x0, top); P(x0 + w, top); P(x0 + w - h / 2, bot); P(x0 + h / 2, bot)
  | F.Asymmetric: P(x0, top); P(x0 + w, top); P(x0 + w, bot); P(x0, bot); P(x0 + h / 2, cy)
  ELSE
  END
END Outline;

(* The end (x, y) of an edge at node n, of shape shape, moved from
   (qx, qy), where it meets n's box, in to n's outline: along the edge's
   last piece, from (px, py), if that meets the outline, else towards
   n's centre. Either way the end stays in n's box, so it passes through
   no other node. Circles are clipped as polygons of 48 sides. *)
PROCEDURE Clip(shape: INTEGER; n: L.Node; size, qx, qy, px, py: REAL; VAR x, y: REAL);
  VAR pts: G.Points; k: INTEGER; dx, dy, d, a: REAL;
BEGIN
  x := qx; y := qy;
  IF (shape = F.Circle) OR (shape = F.DoubleCircle) THEN
    pts := G.NewPoints(48);
    FOR k := 0 TO 47 DO
      a := k * 2 * 3.14159265 / 48;
      G.Set(pts[k], n.x + n.w / 2 * Math.cos(a), n.y + n.h / 2 * Math.sin(a))
    END;
    k := 48
  ELSE
    Outline(shape, n.x, n.y, n.w, n.h, size, pts, k)
  END;
  IF k > 0 THEN
    dx := qx - px; dy := qy - py; d := Math.sqrt(dx * dx + dy * dy);
    IF (d = 0) OR ~G.FirstHit(px, py, qx + dx / d * (n.w + n.h), qy + dy / d * (n.w + n.h), pts^, k, x, y) THEN
      IF ~G.FirstHit(qx, qy, n.x, n.y, pts^, k, x, y) THEN x := qx; y := qy END
    END
  END
END Clip;

(* lab with each line wider than maxW points broken at spaces, as
   Mermaid wraps a label wider than its wrappingWidth: each line as many
   words as fit, a word wider than maxW on a line of its own. lab itself
   when no line is too wide. *)
PROCEDURE Wrap(font: M.Font; lab: F.Label; size, maxW: REAL): F.Label;
  VAR
    r: F.Label; line, last: F.Line; t: Lx.Str; len, start, end, brk, k: LONGINT;
    wide: BOOLEAN;

  PROCEDURE Add(VAR s: ARRAY OF CHAR; from, to: LONGINT);
    VAR nl: F.Line; k: LONGINT;
  BEGIN
    NEW(nl); nl.text := Lx.Sub(s, from, to - from); nl.style := NIL; nl.underline := line.underline; nl.next := NIL;
    IF line.style # NIL THEN
      NEW(nl.style, to - from + 1);
      FOR k := from TO to - 1 DO nl.style[k - from] := line.style[k] END;
      nl.style[to - from] := 0
    END;
    IF last = NIL THEN r.lines := nl ELSE last.next := nl END;
    last := nl; INC(r.n)
  END Add;

BEGIN
  IF lab = NIL THEN RETURN NIL END;
  wide := FALSE; line := lab.lines;
  WHILE line # NIL DO
    IF M.LineWidth(font, line, 0, Lx.Length(line.text^), size) > maxW THEN wide := TRUE END;
    line := line.next
  END;
  IF ~wide THEN RETURN lab END;
  NEW(r); r.lines := NIL; r.n := 0; r.markdown := lab.markdown; last := NIL;
  line := lab.lines;
  WHILE line # NIL DO
    t := line.text; len := Lx.Length(t^); start := 0;
    WHILE (start < len) & (t[start] = " ") DO INC(start) END;
    IF start = len THEN Add(t^, 0, len) END;
    WHILE start < len DO
      (* the most words from start that fit, or one *)
      end := start; WHILE (end < len) & (t[end] # " ") DO INC(end) END;
      brk := end;
      LOOP
        k := brk; WHILE (k < len) & (t[k] = " ") DO INC(k) END;
        IF k = len THEN EXIT END;
        WHILE (k < len) & (t[k] # " ") DO INC(k) END;
        IF M.LineWidth(font, line, start, k, size) > maxW THEN EXIT END;
        brk := k
      END;
      Add(t^, start, brk);
      start := brk; WHILE (start < len) & (t[start] = " ") DO INC(start) END
    END;
    line := line.next
  END;
  RETURN r
END Wrap;

(* Whether (x, y) is inside cluster c's box *)
PROCEDURE InBox(c: L.Cluster; x, y: REAL): BOOLEAN;
BEGIN
  RETURN (ABS(x - c.x) < c.w / 2) & (ABS(y - c.y) < c.h / 2)
END InBox;

(* Edge e's route cut where it leaves cluster c's box: at its start if
   start, else at its end. The points inside the box are dropped, and
   the edge starts (ends) where the piece that leaves the box meets it. *)
PROCEDURE CutBox(e: L.Edge; c: L.Cluster; start: BOOLEAN);
  VAR i, j, k, n: INTEGER; p: G.Points; ix, iy, ox, oy, mx, my: REAL;

  PROCEDURE Ix(i: INTEGER): INTEGER;  (* the i-th point from the cut end *)
  BEGIN
    IF start THEN RETURN i ELSE RETURN n - 1 - i END
  END Ix;

BEGIN
  n := e.nPoints;
  IF n < 2 THEN RETURN END;
  (* i, the first point outside, counting from the cut end *)
  i := 0;
  WHILE (i < n) & InBox(c, e.points[Ix(i)].x, e.points[Ix(i)].y) DO INC(i) END;
  IF (i = 0) OR (i = n) THEN RETURN END;
  ix := e.points[Ix(i - 1)].x; iy := e.points[Ix(i - 1)].y;
  ox := e.points[Ix(i)].x; oy := e.points[Ix(i)].y;
  FOR k := 1 TO 40 DO
    mx := (ix + ox) / 2; my := (iy + oy) / 2;
    IF InBox(c, mx, my) THEN ix := mx; iy := my ELSE ox := mx; oy := my END
  END;
  p := G.NewPoints(n - i + 1);
  G.Set(p[0], ox, oy);
  FOR j := i TO n - 1 DO p[j - i + 1] := e.points[Ix(j)] END;
  IF ~start THEN
    FOR j := 0 TO (n - i + 1) DIV 2 - 1 DO
      k := n - i - j; mx := p[j].x; my := p[j].y; p[j] := p[k]; G.Set(p[k], mx, my)
    END
  END;
  L.SetPoints(e, p, n - i + 1)
END CutBox;

(* The ends of g's edges moved from its nodes' boxes to their outlines,
   or, for an edge to a cluster, cut where it leaves the cluster's box.
   node[v] is the flowchart's node of g's node v, or < 0 for a box,
   whose outline is the box; shape, the flowchart's nodes' shapes. *)
PROCEDURE Ends(g: L.Graph; node, shape: L.Ints; size: REAL);
  VAR k, sf, st: INTEGER; le: L.Edge; x, y: REAL;
BEGIN
  FOR k := 0 TO g.nEdges - 1 DO
    le := g.edge[k];
    sf := F.Rect; st := F.Rect;
    IF node[le.from] >= 0 THEN sf := shape[node[le.from]] END;
    IF node[le.to] >= 0 THEN st := shape[node[le.to]] END;
    IF le.from = le.to THEN
      (* a self-loop's ends are on the node's box: moved in to its
         outline, towards its centre *)
      Clip(sf, g.node[le.from], size, le.points[0].x, le.points[0].y,
        le.points[0].x, le.points[0].y, x, y);
      G.Set(le.points[0], x, y);
      Clip(st, g.node[le.to], size, le.points[le.nPoints - 1].x, le.points[le.nPoints - 1].y,
        le.points[le.nPoints - 1].x, le.points[le.nPoints - 1].y, x, y);
      G.Set(le.points[le.nPoints - 1], x, y)
    ELSIF le.nPoints >= 2 THEN
      IF le.fromC >= 0 THEN CutBox(le, g.cluster[le.fromC], TRUE)
      ELSE
        Clip(sf, g.node[le.from], size, le.points[0].x, le.points[0].y,
          le.points[1].x, le.points[1].y, x, y);
        G.Set(le.points[0], x, y)
      END;
      IF le.toC >= 0 THEN CutBox(le, g.cluster[le.toC], FALSE)
      ELSE
        Clip(st, g.node[le.to], size, le.points[le.nPoints - 1].x, le.points[le.nPoints - 1].y,
          le.points[le.nPoints - 2].x, le.points[le.nPoints - 2].y, x, y);
        G.Set(le.points[le.nPoints - 1], x, y)
      END
    END
  END
END Ends;

(* The size w by h of class box n, its labels set in font at size
   points with line spacing vs, and its parts, as Mermaid's classBox
   lays them out: P, 12 pixels, above the annotation and title, and
   below them to the first divider; the members, then the methods,
   each P below their divider, P above the next; an empty compartment
   1.5 P (2.5 P for the members', or 2 P for the methods', when the
   other is not empty). Lines are vs apart, not Mermaid's 24 pixels. *)
PROCEDURE ClassSize(font: M.Font; n: F.Node; size, vs: REAL; VAR part: ClassPart;
  VAR w, h: REAL);
  VAR p, aw, ah, tw, th, mw, mh, dw, dh: REAL;
BEGIN
  p := 12 * size / MermaidSize; part.pad := p;
  aw := 0; ah := 0; mw := 0; mh := 0; dw := 0; dh := 0;
  IF n.annotation # NIL THEN M.LabelSize(font, n.annotation, size, vs, aw, ah) END;
  M.LabelSize(font, n.label, size, vs, tw, th);
  IF n.members # NIL THEN M.LabelSize(font, n.members, size, vs, mw, mh) END;
  IF n.methods # NIL THEN M.LabelSize(font, n.methods, size, vs, dw, dh) END;
  part.annY := p + ah / 2; part.titleY := p + ah + th / 2;
  part.d1 := p + ah + th + p;
  part.memY := part.d1 + p + mh / 2;
  IF n.members # NIL THEN part.d2 := part.d1 + 2 * p + mh
  ELSIF n.methods # NIL THEN part.d2 := part.d1 + 2.5 * p
  ELSE part.d2 := part.d1 + 1.5 * p
  END;
  part.metY := part.d2 + p + dh / 2;
  IF n.methods # NIL THEN h := part.d2 + 2 * p + dh
  ELSIF n.members # NIL THEN h := part.d2 + 2 * p
  ELSE h := part.d2 + 1.5 * p
  END;
  w := aw;
  IF tw > w THEN w := tw END;
  IF mw > w THEN w := mw END;
  IF dw > w THEN w := dw END;
  w := w + 2 * p
END ClassSize;

(* The size w by h of entity box n, its labels set in font at size
   points with line spacing vs, and its parts, as Mermaid's erBox lays
   them out: with no attributes, its name and 20 pixels on each side, at
   least 100 pixels wide, and 30 pixels above and below; with them, a
   row for its name, 7.5 pixels above and below, then a row for each
   attribute, its cells 7.5 pixels above and below and 10 pixels on each
   side, its columns widened alike, if need be, to be as wide as its
   name and 20 pixels on each side. *)
PROCEDURE ErSize(font: M.Font; n: F.Node; size, vs: REAL; VAR part: ErPart; VAR w, h: REAL);
  VAR p, tw, th, sum, extra: REAL; a: F.Attr; i, k: INTEGER;

  PROCEDURE Max(VAR c: REAL; s: F.Str);
    VAR x: REAL;
  BEGIN
    IF s # NIL THEN
      x := M.Width(font, s^, 0, Lx.Length(s^), size) + 2 * p;
      IF x > c THEN c := x END
    END
  END Max;

BEGIN
  p := 10 * size / MermaidSize; part.pad := p;
  M.LabelSize(font, n.label, size, vs, tw, th);
  FOR i := 0 TO 3 DO part.col[i] := 0 END;
  IF n.attrs = NIL THEN
    part.nameH := 0; part.rowH := 0;
    w := tw + 4 * p;
    IF w < 10 * p THEN w := 10 * p END;
    h := th + 6 * p;
    RETURN
  END;
  part.nameH := th + 1.5 * p; part.rowH := vs + 1.5 * p;
  part.col[0] := 2 * p; part.col[1] := 2 * p;
  a := n.attrs; k := 0;
  WHILE a # NIL DO
    Max(part.col[0], a.type); Max(part.col[1], a.name);
    Max(part.col[2], a.keys); Max(part.col[3], a.comment);
    INC(k); a := a.next
  END;
  sum := 0; i := 0;
  FOR k := 0 TO 3 DO
    IF part.col[k] > 0 THEN sum := sum + part.col[k]; INC(i) END
  END;
  IF tw + 4 * p > sum THEN
    extra := (tw + 4 * p - sum) / i;
    FOR k := 0 TO 3 DO
      IF part.col[k] > 0 THEN part.col[k] := part.col[k] + extra END
    END;
    sum := tw + 4 * p
  END;
  w := sum;
  h := part.nameH;
  a := n.attrs;
  WHILE a # NIL DO h := h + part.rowH; a := a.next END
END ErSize;

(* Where edge e's cardinality at its start (at its end, if ~start) is
   centred, (x, y), as Mermaid's calcTerminalLabelPosition puts it: 25
   pixels along the edge's points from that end, and 10 more if the
   end has a marker, a point c; then 10 pixels, and half the marker's
   10, to the side of the middle of the end and c *)
PROCEDURE Cardinality*(l: Layout; e: F.Edge; start: BOOLEAN; VAR x, y: REAL);
  VAR le: L.Edge; i, n: INTEGER; m, left, sx, sy, ax, ay, bx, by, cx, cy, d, a, scale: REAL;

  PROCEDURE P(i: INTEGER; VAR px, py: REAL);  (* the i-th point from the end *)
  BEGIN
    IF ~start THEN i := n - 1 - i END;
    px := le.points[i].x; py := le.points[i].y
  END P;

BEGIN
  le := l.g.edge[e.index]; n := le.nPoints; x := 0; y := 0;
  IF n = 0 THEN RETURN END;
  scale := l.size / MermaidSize;
  m := 0;
  IF start & (e.tail # F.None) OR ~start & (e.head # F.None) THEN m := 10 END;
  P(0, sx, sy); cx := sx; cy := sy; left := (25 + m) * scale; i := 1;
  WHILE (i < n) & (left > 0) DO
    P(i - 1, ax, ay); P(i, bx, by);
    d := Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
    IF d >= left THEN
      cx := ax + (bx - ax) * left / d; cy := ay + (by - ay) * left / d; left := 0
    ELSE
      cx := bx; cy := by; left := left - d
    END;
    INC(i)
  END;
  d := (10 + m / 2) * scale;
  a := Math.arctan2(sy - cy, sx - cx);
  x := Math.sin(a) * d + (sx + cx) / 2;
  y := -Math.cos(a) * d + (sy + cy) / 2
END Cardinality;

PROCEDURE Dir(d: INTEGER): INTEGER;
BEGIN
  CASE d OF
    F.BT: RETURN L.BT
  | F.LR: RETURN L.LR
  | F.RL: RETURN L.RL
  ELSE RETURN L.TB
  END
END Dir;

(* Lays out graph, its labels set in font at size points: the result
   in l.

   First the collapsed subgraphs, as Mermaid's flowDb collapses them:
   each outermost one is a node of its own, sized as Mermaid's
   collapsedGroup, and what it holds, nodes and subgraphs, is hidden;
   edges to them go to it, and an edge that then joins it to itself is
   dropped.

   Then the isolated subgraphs, as Mermaid's adjustClustersAndEdges
   finds them: a subgraph is connected if an edge has one end among
   what it holds (not the subgraph itself) and the other outside. An
   edge to a connected subgraph goes to its anchor, the first node it
   holds, or, if that node's subgraph is another, held by it and not
   connected, that subgraph; the anchor's subgraph is connected then.
   Each subgraph that holds nodes and is not connected is isolated: it
   is laid out by itself, with its own direction, or, without one, TB
   in an LR, RL or BT layout and LR in a TB one, with 25 pixels more
   between ranks; and it is a node, of its size, of the layout that
   holds it. Each layout is a scope: inner ones first, the whole last.
   An edge's ends are both in one scope; where they would not be, the
   deeper end is moved out to the box of the isolated subgraph that
   holds it.

   l.g holds the parts of every scope, each where it is in the drawing:
   graph's nodes, edges and subgraphs, by their indices. *)
PROCEDURE Make*(graph: F.Graph; font: M.Font; size: REAL; VAR l: Layout);
  VAR
    n: F.Node; e: F.Edge; c: F.Cluster; scale, w, h, tw, th, pad, x, y: REAL;
    k, j, v, i, nC, nN, nE, a, b, s, from, to, fc, tc: INTEGER;
    shape, rep, par, col, item, anchor, nodeCl, sdir, eFrom, eTo, eFc, eTc,
    locN, locB, locC, boxNode, eOwn: L.Ints;
    nw, nh, ctw, cth, sw, sh, srs, ox, oy: POINTER TO ARRAY OF REAL; ns, rs: REAL;
    hidN, cmap, hidC, group, ext, iso, drop: Flags;
    nodes: POINTER TO ARRAY OF F.Node; edges: POINTER TO ARRAY OF F.Edge;
    clus: POINTER TO ARRAY OF F.Cluster;
    scope: POINTER TO ARRAY OF Scope; sc: Scope; sg, hg: L.Graph; ln: L.Node; le: L.Edge;

  PROCEDURE Ints(n: INTEGER): L.Ints;
    VAR a: L.Ints; i: INTEGER;
  BEGIN
    NEW(a, n + 1); FOR i := 0 TO n DO a[i] := -1 END;
    RETURN a
  END Ints;

  PROCEDURE Bools(n: INTEGER): Flags;
    VAR a: Flags; i: INTEGER;
  BEGIN
    NEW(a, n + 1); FOR i := 0 TO n DO a[i] := FALSE END;
    RETURN a
  END Bools;

  (* the subgraph an item is in: for a node, its own; for subgraph k,
     -1-k, the one that holds k *)
  PROCEDURE Container(it: INTEGER): INTEGER;
  BEGIN
    IF it >= 0 THEN RETURN nodeCl[it] ELSE RETURN par[-1 - it] END
  END Container;

  (* whether the item it is held by subgraph d, d not it itself *)
  PROCEDURE Within(it, d: INTEGER): BOOLEAN;
    VAR k: INTEGER;
  BEGIN
    k := Container(it);
    WHILE (k >= 0) & (k # d) DO k := par[k] END;
    RETURN (k = d) & (d >= 0)
  END Within;

  (* the innermost isolated subgraph that holds subgraph k, or -1 *)
  PROCEDURE Outer(k: INTEGER): INTEGER;
  BEGIN
    WHILE (k >= 0) & ~iso[k] DO k := par[k] END;
    RETURN k
  END Outer;

  (* the scope of an item: that of the innermost isolated subgraph that
     holds it, or nC, the whole's *)
  PROCEDURE ScopeOf(it: INTEGER): INTEGER;
    VAR k: INTEGER;
  BEGIN
    k := Outer(Container(it));
    IF k < 0 THEN RETURN nC ELSE RETURN k END
  END ScopeOf;

  PROCEDURE Depth(k: INTEGER): INTEGER;
    VAR d: INTEGER;
  BEGIN
    d := 0; WHILE k >= 0 DO INC(d); k := par[k] END;
    RETURN d
  END Depth;

  (* the node of the scope's layout for the item it *)
  PROCEDURE Loc(it: INTEGER): INTEGER;
  BEGIN
    IF it >= 0 THEN RETURN locN[it] ELSE RETURN locB[-1 - it] END
  END Loc;

BEGIN
  NEW(l); l.graph := graph; l.font := font; l.size := size; l.vs := size * 1.2;
  scale := size / MermaidSize;
  IF graph.kind = F.Er THEN ns := ErNodeSpacing * scale; rs := ErRankSpacing * scale
  ELSE ns := Spacing * scale; rs := ns
  END;
  nN := graph.nNodes; nE := graph.nEdges; nC := graph.nClusters;
  (* the title, at Mermaid's 18 pixels, not wrapped *)
  l.title := graph.title; l.titleSize := size * TitleSize / MermaidSize;
  l.titleW := 0; l.titleH := 0;
  IF l.title # NIL THEN
    M.LabelSize(font, l.title, l.titleSize, l.titleSize * 1.2, l.titleW, l.titleH)
  END;
  NEW(l.textW, nN + 1); NEW(l.textH, nN + 1);
  shape := Ints(nN); nodeCl := Ints(nN); NEW(nw, nN + 1); NEW(nh, nN + 1); NEW(nodes, nN + 1);
  NEW(l.nodeLabel, nN + 1); NEW(l.edgeLabel, nE + 1); NEW(l.parts, nN + 1); NEW(l.er, nN + 1);
  n := graph.nodes;
  WHILE n # NIL DO
    nodes[n.index] := n;
    IF (n.shape = F.ClassBox) OR (n.shape = F.ErBox) THEN l.nodeLabel[n.index] := n.label
    ELSE l.nodeLabel[n.index] := Wrap(font, n.label, size, WrapWidth * scale)
    END;
    M.LabelSize(font, l.nodeLabel[n.index], size, l.vs, tw, th);
    l.textW[n.index] := tw; l.textH[n.index] := th; shape[n.index] := n.shape;
    IF n.shape = F.ClassBox THEN ClassSize(font, n, size, l.vs, l.parts[n.index], w, h)
    ELSIF n.shape = F.ErBox THEN ErSize(font, n, size, l.vs, l.er[n.index], w, h)
    ELSIF n.shape = F.Interface THEN M.ShapeSize(F.Rect, tw, th, size, w, h)
    ELSIF Shp.Has(n.shape) THEN Shp.Size(n.shape, graph.dir, tw, th, size, w, h)
    ELSE M.ShapeSize(n.shape, tw, th, size, w, h)
    END;
    nw[n.index] := w; nh[n.index] := h;
    IF n.cluster # NIL THEN nodeCl[n.index] := n.cluster.index END;
    n := n.next
  END;
  (* the subgraphs, the nodes they hold, and those that stand for them *)
  NEW(l.clusterLabel, nC + 1); rep := Ints(nC); par := Ints(nC); NEW(clus, nC + 1);
  NEW(ctw, nC + 1); NEW(cth, nC + 1);
  l.stands := Ints(nN);
  c := graph.clusters;
  WHILE c # NIL DO
    clus[c.index] := c;
    l.clusterLabel[c.index] := Wrap(font, c.title, size, WrapWidth * scale);
    M.LabelSize(font, l.clusterLabel[c.index], size, l.vs, ctw[c.index], cth[c.index]);
    IF c.parent # NIL THEN par[c.index] := c.parent.index END;
    c := c.next
  END;
  FOR i := 0 TO nN - 1 DO
    c := graph.clusters;
    WHILE c # NIL DO
      IF Lx.Equal(c.id, nodes[i].id) THEN l.stands[i] := c.index END;
      c := c.next
    END
  END;
  (* each subgraph's first node, not one that stands for a subgraph *)
  FOR i := 0 TO nN - 1 DO
    IF l.stands[i] < 0 THEN
      k := nodeCl[i];
      WHILE k >= 0 DO
        IF rep[k] < 0 THEN rep[k] := i END;
        k := par[k]
      END
    END
  END;
  hidN := Bools(nN);
  FOR i := 0 TO nN - 1 DO
    IF l.stands[i] >= 0 THEN
      IF rep[l.stands[i]] >= 0 THEN hidN[i] := TRUE ELSE l.stands[i] := -1 END
    END
  END;
  (* collapsed subgraphs: col[k], the outermost collapsed one that is
     k or holds it *)
  col := Ints(nC); hidC := Bools(nC); group := Bools(nC);
  FOR k := 0 TO nC - 1 DO
    a := k;
    WHILE a >= 0 DO
      IF clus[a].collapsed & (rep[a] >= 0) THEN col[k] := a END;
      a := par[a]
    END;
    IF col[k] = k THEN group[k] := TRUE ELSIF col[k] >= 0 THEN hidC[k] := TRUE END
  END;
  (* each node as an item: itself, or the collapsed subgraph that holds
     it, or for one that stands for subgraph k, -1-k *)
  item := Ints(nN); cmap := Bools(nN);
  FOR i := 0 TO nN - 1 DO
    item[i] := i; k := nodeCl[i];
    IF l.stands[i] >= 0 THEN k := l.stands[i]; item[i] := -1 - k END;
    IF (k >= 0) & (col[k] >= 0) THEN item[i] := -1 - col[k]; cmap[i] := TRUE; hidN[i] := TRUE END
  END;
  (* the edges' ends, as items; those that join a collapsed subgraph to
     itself dropped *)
  NEW(edges, nE + 1); eFrom := Ints(nE); eTo := Ints(nE); eFc := Ints(nE); eTc := Ints(nE);
  drop := Bools(nE);
  e := graph.edges;
  WHILE e # NIL DO
    j := e.index; edges[j] := e;
    l.edgeLabel[j] := Wrap(font, e.label, size, WrapWidth * scale);
    eFrom[j] := item[e.from.index]; eTo[j] := item[e.to.index];
    drop[j] := (eFrom[j] = eTo[j]) & (cmap[e.from.index] OR cmap[e.to.index]);
    e := e.next
  END;
  (* connected subgraphs, and their anchors *)
  ext := Bools(nC); anchor := Ints(nC);
  FOR k := 0 TO nC - 1 DO
    IF (rep[k] >= 0) & (col[k] < 0) THEN
      FOR j := 0 TO nE - 1 DO
        IF ~drop[j] & (Within(eFrom[j], k) # Within(eTo[j], k)) THEN ext[k] := TRUE END
      END
    END
  END;
  FOR k := 0 TO nC - 1 DO
    IF (rep[k] >= 0) & (col[k] < 0) THEN
      i := 0;
      WHILE (i < nN) & ((l.stands[i] >= 0) OR ~Within(item[i], k)) DO INC(i) END;
      a := item[i]; b := Container(a);
      IF (b # k) & ~ext[b] THEN anchor[k] := -1 - b ELSE anchor[k] := a END
    END
  END;
  (* edges to connected subgraphs go to their anchors *)
  FOR j := 0 TO nE - 1 DO
    IF ~drop[j] THEN
      a := eFrom[j];
      IF (a < 0) & ~group[-1 - a] & ext[-1 - a] THEN
        eFc[j] := -1 - a; eFrom[j] := anchor[-1 - a];
        b := Container(eFrom[j]); IF b >= 0 THEN ext[b] := TRUE END
      END;
      a := eTo[j];
      IF (a < 0) & ~group[-1 - a] & ext[-1 - a] THEN
        eTc[j] := -1 - a; eTo[j] := anchor[-1 - a];
        b := Container(eTo[j]); IF b >= 0 THEN ext[b] := TRUE END
      END
    END
  END;
  iso := Bools(nC);
  FOR k := 0 TO nC - 1 DO iso[k] := (rep[k] >= 0) & (col[k] < 0) & ~ext[k] END;
  (* both ends of each edge in one scope *)
  eOwn := Ints(nE);
  FOR j := 0 TO nE - 1 DO
    IF ~drop[j] THEN
      LOOP
        a := Outer(Container(eFrom[j])); b := Outer(Container(eTo[j]));
        IF a = b THEN EXIT END;
        IF Depth(a) >= Depth(b) THEN eFrom[j] := -1 - a ELSE eTo[j] := -1 - b END
      END;
      eOwn[j] := ScopeOf(eFrom[j])
    END
  END;
  (* each scope's direction and rank spacing, the outer first *)
  sdir := Ints(nC); NEW(srs, nC + 1); NEW(sw, nC + 1); NEW(sh, nC + 1);
  NEW(ox, nC + 1); NEW(oy, nC + 1);
  sdir[nC] := Dir(graph.dir); srs[nC] := rs;
  FOR k := nC - 1 TO 0 BY -1 DO
    IF iso[k] THEN
      s := ScopeOf(-1 - k);
      IF clus[k].dir # F.NoDir THEN sdir[k] := Dir(clus[k].dir)
      ELSIF sdir[s] = L.TB THEN sdir[k] := L.LR
      ELSE sdir[k] := L.TB
      END;
      srs[k] := srs[s] + ClusterRankGap * scale
    END
  END;
  (* each scope laid out, the inner first *)
  NEW(scope, nC + 1); locN := Ints(nN); locB := Ints(nC); locC := Ints(nC);
  boxNode := Ints(nC);
  pad := size / 4;
  FOR s := 0 TO nC DO
    IF (s = nC) OR iso[s] THEN
      sg := L.New(sdir[s], ns, EdgeSpacing * scale, srs[s]);
      NEW(sc); sc.g := sg; sc.next := NIL; sc.x := 0; sc.y := 0;
      IF s = nC THEN sc.cluster := -1 ELSE sc.cluster := s END;
      sc.node := Ints(nN + nC); sc.edge := Ints(nE); sc.clus := Ints(nC);
      FOR i := 0 TO nN - 1 DO locN[i] := -1 END;
      FOR k := 0 TO nC - 1 DO locB[k] := -1; locC[k] := -1 END;
      (* the nodes: those hidden in the whole's *)
      FOR i := 0 TO nN - 1 DO
        IF hidN[i] & (s = nC) OR ~hidN[i] & (ScopeOf(i) = s) THEN
          v := L.AddNode(sg, nw[i], nh[i]); locN[i] := v; sc.node[v] := i
        END
      END;
      FOR i := 0 TO nN - 1 DO
        IF hidN[i] & (s = nC) THEN L.Hide(sg, locN[i]) END
      END;
      (* the boxes of isolated and collapsed subgraphs *)
      FOR k := 0 TO nC - 1 DO
        IF (iso[k] OR group[k]) & (ScopeOf(-1 - k) = s) THEN
          IF iso[k] THEN w := sw[k]; h := sh[k]
          ELSE
            w := ctw[k] + GroupPad * scale;
            IF w < GroupWidth * scale THEN w := GroupWidth * scale END;
            h := cth[k] + GroupExtra * scale
          END;
          v := L.AddNode(sg, w, h); locB[k] := v; sc.node[v] := -1 - k; boxNode[k] := v
        END
      END;
      (* the subgraphs: the isolated one itself, and those in it, not
         isolated or collapsed *)
      FOR k := 0 TO nC - 1 DO
        IF (k = s) OR (col[k] < 0) & ~iso[k] & (ScopeOf(-1 - k) = s) THEN
          locC[k] := L.AddCluster(sg, ctw[k], cth[k]); sc.clus[locC[k]] := k
        END
      END;
      FOR k := 0 TO nC - 1 DO
        IF (locC[k] >= 0) & (k # s) & (par[k] >= 0) THEN
          ASSERT(locC[par[k]] >= 0);
          L.SetParent(sg, locC[k], locC[par[k]])
        END
      END;
      FOR i := 0 TO nN - 1 DO
        IF (locN[i] >= 0) & (nodeCl[i] >= 0) THEN
          IF locC[nodeCl[i]] >= 0 THEN L.SetCluster(sg, locN[i], locC[nodeCl[i]])
          ELSE ASSERT(hidN[i])
          END
        END
      END;
      FOR k := 0 TO nC - 1 DO
        IF (locB[k] >= 0) & (par[k] >= 0) THEN L.SetCluster(sg, locB[k], locC[par[k]]) END
      END;
      (* the edges *)
      FOR j := 0 TO nE - 1 DO
        IF ~drop[j] & (eOwn[j] = s) THEN
          e := edges[j]; from := Loc(eFrom[j]); to := Loc(eTo[j]);
          ASSERT((from >= 0) & (to >= 0));
          IF e.label # NIL THEN
            M.LabelSize(font, l.edgeLabel[j], size, l.vs, tw, th);
            k := L.AddEdge(sg, from, to, e.length, 1, tw + 2 * pad, th, TRUE)
          ELSE
            k := L.AddEdge(sg, from, to, e.length, 1, 0, 0, FALSE)
          END;
          sc.edge[k] := j;
          IF (eFc[j] >= 0) OR (eTc[j] >= 0) THEN
            fc := -1; tc := -1;
            IF eFc[j] >= 0 THEN fc := locC[eFc[j]] END;
            IF eTc[j] >= 0 THEN tc := locC[eTc[j]] END;
            L.EdgeClusters(sg, k, fc, tc)
          END
        END
      END;
      L.Layout(sg);
      Ends(sg, sc.node, shape, size);
      IF s < nC THEN sw[s] := sg.width; sh[s] := sg.height END;
      scope[s] := sc
    END
  END;
  (* the scopes, inner first: l.scopes was built the other way *)
  l.scopes := NIL;
  FOR s := nC TO 0 BY -1 DO
    IF (s = nC) OR iso[s] THEN scope[s].next := l.scopes; l.scopes := scope[s] END
  END;
  (* where each scope is in the drawing, the outer first *)
  ox[nC] := 0; oy[nC] := 0;
  FOR k := nC - 1 TO 0 BY -1 DO
    IF iso[k] THEN
      s := ScopeOf(-1 - k); ln := scope[s].g.node[boxNode[k]];
      ox[k] := ox[s] + ln.x - ln.w / 2; oy[k] := oy[s] + ln.y - ln.h / 2;
      scope[k].x := ox[k]; scope[k].y := oy[k]
    END
  END;
  (* the parts of every scope, where they are in the drawing *)
  hg := L.New(Dir(graph.dir), ns, EdgeSpacing * scale, rs);
  FOR i := 0 TO nN - 1 DO v := L.AddNode(hg, nw[i], nh[i]) END;
  FOR k := 0 TO nC - 1 DO v := L.AddCluster(hg, ctw[k], cth[k]) END;
  FOR k := 0 TO nC - 1 DO
    IF par[k] >= 0 THEN L.SetParent(hg, k, par[k]) END
  END;
  FOR i := 0 TO nN - 1 DO
    IF nodeCl[i] >= 0 THEN L.SetCluster(hg, i, nodeCl[i]) END
  END;
  FOR j := 0 TO nE - 1 DO
    e := edges[j];
    v := L.AddEdge(hg, e.from.index, e.to.index, e.length, 1, 0, 0, FALSE)
  END;
  sc := l.scopes;
  WHILE sc # NIL DO
    sg := sc.g; x := sc.x; y := sc.y;
    FOR v := 0 TO sg.nReal - 1 DO
      ln := sg.node[v]; i := sc.node[v];
      IF i >= 0 THEN L.Place(hg, i, ln, x, y)
      ELSIF group[-1 - i] THEN
        L.SetBox(hg, -1 - i, ln.x + x, ln.y + y, ln.w, ln.h,
          ln.x + x, ln.y + y - GroupTitle * scale)
      END
    END;
    FOR k := 0 TO sg.nClusters - 1 DO L.PlaceCluster(hg, sc.clus[k], sg.cluster[k], x, y) END;
    FOR k := 0 TO sg.nEdges - 1 DO
      j := sc.edge[k]; L.PlaceEdge(hg, j, sg.edge[k], x, y);
      L.EdgeClusters(hg, j, eFc[j], eTc[j])
    END;
    sc := sc.next
  END;
  FOR j := 0 TO nE - 1 DO IF drop[j] THEN L.HideEdge(hg, j) END END;
  L.SetSize(hg, scope[nC].g.width, scope[nC].g.height);
  l.g := hg; l.collapsed := group; l.isolated := iso;
  (* room above the drawing for the title: its baseline TitleMargin
     pixels above the drawing's top, its box centred 0.3 of its size
     above the baseline, as pic sets text *)
  l.titleX := 0; l.titleY := 0;
  IF (l.title # NIL) & (l.title.n > 0) THEN
    L.Reserve(l.g, l.titleW, TitleMargin * scale + 0.3 * l.titleSize + l.titleH / 2);
    l.titleX := l.g.width / 2; l.titleY := 0.3 * l.titleSize + l.titleH / 2
  END
END Make;

(* Lays out graph as Make does, its labels at size points, or at a
   smaller size, to a tenth of a point, if that is wider than maxW
   points (0 for no limit). Every length in the layout grows with the
   size, so the width does too. *)
PROCEDURE Fit*(graph: F.Graph; font: M.Font; size, maxW: REAL; VAR l: Layout);
  VAR k: INTEGER;
BEGIN
  Make(graph, font, size, l); k := 0;
  WHILE (maxW > 0) & (l.g.width > maxW) & (k < 5) & (size > 0.2) DO
    size := ENTIER(size * maxW / l.g.width * 10) / 10;
    IF size >= l.size THEN size := l.size - 0.1 END;
    IF size < 0.1 THEN size := 0.1 END;
    Make(graph, font, size, l); INC(k)
  END
END Fit;

END PmFlowLayout.
