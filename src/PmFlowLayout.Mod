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

IMPORT Math, F := PmFlow, M := PmMetrics, G := PmGeom, L := PmLayout, Lx := PmLex;

CONST
  Spacing = 50;    (* Mermaid's nodeSpacing and rankSpacing, in pixels *)
  EdgeSpacing = 20; (* dagre's edgesep *)
  MermaidSize = 16; (* Mermaid's font size, in pixels *)
  WrapWidth = 200;  (* Mermaid's wrappingWidth: wider labels wrap, in pixels *)

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    graph-: F.Graph;
    g-: L.Graph;           (* node i is graph's node of index i; edge j, edge j *)
    textW-, textH-: POINTER TO ARRAY OF REAL; (* each node's label's size *)
    nodeLabel-, edgeLabel-: POINTER TO ARRAY OF F.Label; (* the labels, wrapped *)
    clusterLabel-: POINTER TO ARRAY OF F.Label; (* the subgraphs' titles, wrapped;
                              cluster i of g is the subgraph of index i *)
    stands-: POINTER TO ARRAY OF INTEGER; (* for each node, the cluster it
                              stands for, or -1 *)
    size-, vs-: REAL       (* the labels' size and line spacing *)
  END;

(* The outline of a node of shape shape, w by h, centred at (cx, cy):
   pts[0 .. n-1], the corners of a polygon, for the shapes drawn as
   polygons; n is 0 for the others (rectangles, rounded and stadium
   shapes, subroutines, cylinders, circles), whose outline is their
   box or, for circles, the circle in it. y runs down. *)
PROCEDURE Outline*(shape: INTEGER; cx, cy, w, h: REAL; VAR pts: G.Points; VAR n: INTEGER);
  VAR x0, top, bot, m: REAL;

  PROCEDURE P(x, y: REAL);
  BEGIN
    G.Set(pts[n], x, y); INC(n)
  END P;

BEGIN
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
PROCEDURE Clip(shape: INTEGER; n: L.Node; qx, qy, px, py: REAL; VAR x, y: REAL);
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
    Outline(shape, n.x, n.y, n.w, n.h, pts, k)
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
    VAR nl: F.Line;
  BEGIN
    NEW(nl); nl.text := Lx.Sub(s, from, to - from); nl.next := NIL;
    IF last = NIL THEN r.lines := nl ELSE last.next := nl END;
    last := nl; INC(r.n)
  END Add;

BEGIN
  IF lab = NIL THEN RETURN NIL END;
  wide := FALSE; line := lab.lines;
  WHILE line # NIL DO
    IF M.Width(font, line.text^, 0, Lx.Length(line.text^), size) > maxW THEN wide := TRUE END;
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
        IF M.Width(font, t^, start, k, size) > maxW THEN EXIT END;
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
   in l *)
PROCEDURE Make*(graph: F.Graph; font: M.Font; size: REAL; VAR l: Layout);
  VAR
    n: F.Node; e: F.Edge; c: F.Cluster; scale, w, h, tw, th, pad, x, y: REAL;
    k, from, to, fc, tc: INTEGER;
    shape, rep: POINTER TO ARRAY OF INTEGER; le: L.Edge;
BEGIN
  NEW(l); l.graph := graph; l.size := size; l.vs := size * 1.2;
  scale := size / MermaidSize;
  l.g := L.New(Dir(graph.dir), Spacing * scale, EdgeSpacing * scale, Spacing * scale);
  NEW(l.textW, graph.nNodes + 1); NEW(l.textH, graph.nNodes + 1);
  NEW(shape, graph.nNodes + 1);
  NEW(l.nodeLabel, graph.nNodes + 1); NEW(l.edgeLabel, graph.nEdges + 1);
  n := graph.nodes;
  WHILE n # NIL DO
    l.nodeLabel[n.index] := Wrap(font, n.label, size, WrapWidth * scale);
    M.LabelSize(font, l.nodeLabel[n.index], size, l.vs, tw, th);
    l.textW[n.index] := tw; l.textH[n.index] := th; shape[n.index] := n.shape;
    M.ShapeSize(n.shape, tw, th, size, w, h);
    k := L.AddNode(l.g, w, h);
    ASSERT(k = n.index);
    n := n.next
  END;
  (* the subgraphs, the nodes they hold, and those that stand for them *)
  NEW(l.clusterLabel, graph.nClusters + 1); NEW(rep, graph.nClusters + 1);
  NEW(l.stands, graph.nNodes + 1);
  c := graph.clusters;
  WHILE c # NIL DO
    l.clusterLabel[c.index] := Wrap(font, c.title, size, WrapWidth * scale);
    M.LabelSize(font, l.clusterLabel[c.index], size, l.vs, tw, th);
    k := L.AddCluster(l.g, tw, th);
    ASSERT(k = c.index);
    c := c.next
  END;
  c := graph.clusters;
  WHILE c # NIL DO
    IF c.parent # NIL THEN L.SetParent(l.g, c.index, c.parent.index) END;
    rep[c.index] := -1;
    c := c.next
  END;
  n := graph.nodes;
  WHILE n # NIL DO
    l.stands[n.index] := -1;
    IF n.cluster # NIL THEN L.SetCluster(l.g, n.index, n.cluster.index) END;
    n := n.next
  END;
  n := graph.nodes;
  WHILE n # NIL DO
    c := graph.clusters;
    WHILE c # NIL DO
      IF Lx.Equal(c.id, n.id) THEN l.stands[n.index] := c.index END;
      c := c.next
    END;
    n := n.next
  END;
  (* each cluster's first node, not one that stands for a cluster *)
  n := graph.nodes;
  WHILE n # NIL DO
    IF l.stands[n.index] < 0 THEN
      c := n.cluster;
      WHILE c # NIL DO
        IF rep[c.index] < 0 THEN rep[c.index] := n.index END;
        c := c.parent
      END
    END;
    n := n.next
  END;
  n := graph.nodes;
  WHILE n # NIL DO
    IF l.stands[n.index] >= 0 THEN
      IF rep[l.stands[n.index]] >= 0 THEN L.Hide(l.g, n.index) ELSE l.stands[n.index] := -1 END
    END;
    n := n.next
  END;
  pad := size / 4;
  e := graph.edges;
  WHILE e # NIL DO
    l.edgeLabel[e.index] := Wrap(font, e.label, size, WrapWidth * scale);
    from := e.from.index; to := e.to.index; fc := l.stands[from]; tc := l.stands[to];
    IF fc >= 0 THEN from := rep[fc] END;
    IF tc >= 0 THEN to := rep[tc] END;
    IF e.label # NIL THEN
      M.LabelSize(font, l.edgeLabel[e.index], size, l.vs, tw, th);
      k := L.AddEdge(l.g, from, to, e.length, 1, tw + 2 * pad, th, TRUE)
    ELSE
      k := L.AddEdge(l.g, from, to, e.length, 1, 0, 0, FALSE)
    END;
    ASSERT(k = e.index);
    IF (fc >= 0) OR (tc >= 0) THEN L.EdgeClusters(l.g, k, fc, tc) END;
    e := e.next
  END;
  L.Layout(l.g);
  (* the ends on the outlines *)
  FOR k := 0 TO l.g.nEdges - 1 DO
    le := l.g.edge[k];
    IF le.from = le.to THEN
      (* a self-loop's ends are on the node's box: moved in to its
         outline, towards its centre *)
      Clip(shape[le.from], l.g.node[le.from], le.points[0].x, le.points[0].y,
        le.points[0].x, le.points[0].y, x, y);
      G.Set(le.points[0], x, y);
      Clip(shape[le.to], l.g.node[le.to], le.points[le.nPoints - 1].x, le.points[le.nPoints - 1].y,
        le.points[le.nPoints - 1].x, le.points[le.nPoints - 1].y, x, y);
      G.Set(le.points[le.nPoints - 1], x, y)
    ELSIF le.nPoints >= 2 THEN
      IF le.fromC >= 0 THEN CutBox(le, l.g.cluster[le.fromC], TRUE)
      ELSE
        Clip(shape[le.from], l.g.node[le.from], le.points[0].x, le.points[0].y,
          le.points[1].x, le.points[1].y, x, y);
        G.Set(le.points[0], x, y)
      END;
      IF le.toC >= 0 THEN CutBox(le, l.g.cluster[le.toC], FALSE)
      ELSE
        Clip(shape[le.to], l.g.node[le.to], le.points[le.nPoints - 1].x, le.points[le.nPoints - 1].y,
          le.points[le.nPoints - 2].x, le.points[le.nPoints - 2].y, x, y);
        G.Set(le.points[le.nPoints - 1], x, y)
      END
    END
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
