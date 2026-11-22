MODULE PmLayout;
(* PmLayout: a layered layout of a directed graph, after dagre's
   (https://github.com/dagrejs/dagre), the layout Mermaid uses for
   flowcharts, which follows Gansner et al., "A Technique for Drawing
   Directed Graphs" (1993), and Brandes and Köpf, "Fast and Simple
   Horizontal Coordinate Assignment" (2001).

   The graph knows nothing of what it draws: nodes are boxes of a width
   and a height, edges join two nodes and may carry a label box. It is
   laid out in two halves:

   - Topology, which needs no sizes: the edges of a set that breaks
     every cycle are turned around (a depth-first search, as dagre's
     default); each node gets a rank (longest paths, then the network
     simplex), on a grid of half ranks, so that each edge's minimum
     length is doubled and there is a rank between any two nodes for
     its label, as dagre does; an edge that spans more than one rank
     is a chain of dummy nodes, its label's dummy in the middle; the
     nodes of each rank are ordered to reduce crossings (barycentres,
     sweeping up and down, the best order kept); a self-loop gets a
     dummy beside its node, for its label.
   - Geometry, from the sizes: the ranks are placed one after another,
     the nodes along them by Brandes and Köpf's method (four
     alignments, balanced); each edge's points are its dummies'
     centres, between the points where it leaves its two nodes' boxes;
     then the drawing is turned for BT, LR and RL, and moved so that
     its top left corner is (0, 0).

   Coordinates are in points, x to the right and y down. A node's x
   and y are its centre. While the layout works, ranks run down the
   page ("frame" sizes are a node's sizes turned for LR and RL). *)

IMPORT G := PmGeom;

CONST
  (* directions *)
  TB* = 0; BT* = 1; LR* = 2; RL* = 3;
  (* kinds of node *)
  Real* = 0;        (* a node of the graph *)
  Dummy* = 1;       (* a point on a long edge *)
  LabelDummy* = 2;  (* the point of a long edge that holds its label *)
  SelfDummy* = 3;   (* beside a node, where its self-loop turns *)

  Inf = MAX(INTEGER);

TYPE
  Ints* = POINTER TO ARRAY OF INTEGER;
  Reals = POINTER TO ARRAY OF REAL;
  Bools = POINTER TO ARRAY OF BOOLEAN;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    w-, h-: REAL;       (* its size *)
    x-, y-: REAL;       (* its centre, after Layout *)
    rank-: INTEGER;     (* on the grid of half ranks, from 0 *)
    order-: INTEGER;    (* its place in its rank, from 0 *)
    kind-: INTEGER;
    edge-: INTEGER;     (* for a dummy, its edge; -1 for a node *)
    fw, fh: REAL        (* its size in the frame *)
  END;

  Edge* = POINTER TO EdgeDesc;
  EdgeDesc* = RECORD
    from-, to-: INTEGER;   (* the nodes *)
    minlen-: INTEGER;      (* the least number of ranks it spans *)
    weight-: INTEGER;      (* how much keeping it short and straight matters *)
    labelW-, labelH-: REAL;
    hasLabel-: BOOLEAN;
    reversed-: BOOLEAN;    (* turned around to break a cycle *)
    chain-: Ints;          (* its dummies, in rank order *)
    nChain-: INTEGER;
    labelNode-: INTEGER;   (* the dummy of its label, or -1 *)
    points-: G.Points;     (* its route, from "from" to "to" *)
    nPoints-: INTEGER;
    labelX-, labelY-: REAL; (* the centre of its label *)
    u, v: INTEGER          (* from and to, turned around if reversed *)
  END;

  Nodes = POINTER TO ARRAY OF Node;
  Edges = POINTER TO ARRAY OF Edge;
  Layers = POINTER TO ARRAY OF Ints;

  Graph* = POINTER TO GraphDesc;
  GraphDesc* = RECORD
    dir-: INTEGER;
    nodesep-, edgesep-, ranksep-: REAL;
    node-: Nodes; nNodes-: INTEGER;
    nReal-: INTEGER;        (* nodes 0 .. nReal-1 are the graph's *)
    edge-: Edges; nEdges-: INTEGER;
    layer-: Layers;         (* each rank's nodes, in order *)
    layerLen-: Ints;
    nRanks-: INTEGER;
    rankH: POINTER TO ARRAY OF REAL; (* each rank's height, its tallest node's *)
    width-, height-: REAL;  (* the drawing's size, after Layout *)
    (* the segments: the edges between neighbouring ranks, from the
       chains *)
    nSeg: INTEGER;
    segU, segV, segW: Ints;
    nCsr: INTEGER;          (* nodes with in and out lists *)
    inStart, inList, outStart, outList: Ints
  END;

(* Arrays *)

PROCEDURE NewInts(n: INTEGER): Ints;
  VAR a: Ints;
BEGIN
  IF n < 1 THEN n := 1 END;
  NEW(a, n);
  RETURN a
END NewInts;

PROCEDURE NewReals(n: INTEGER): Reals;
  VAR a: Reals;
BEGIN
  IF n < 1 THEN n := 1 END;
  NEW(a, n);
  RETURN a
END NewReals;

PROCEDURE NewBools(n: INTEGER): Bools;
  VAR a: Bools; i: INTEGER;
BEGIN
  IF n < 1 THEN n := 1 END;
  NEW(a, n);
  FOR i := 0 TO n - 1 DO a[i] := FALSE END;
  RETURN a
END NewBools;

(* a with room for n, its first k kept *)
PROCEDURE GrowInts(VAR a: Ints; k, n: INTEGER);
  VAR b: Ints; i: INTEGER;
BEGIN
  IF (a = NIL) OR (LEN(a^) < n) THEN
    b := NewInts(2 * n);
    FOR i := 0 TO k - 1 DO b[i] := a[i] END;
    a := b
  END
END GrowInts;

(* Building the graph *)

(* A new graph, laid out in the direction dir, with nodesep between
   neighbouring nodes of a rank, edgesep between neighbouring edges,
   and ranksep between ranks *)
PROCEDURE New*(dir: INTEGER; nodesep, edgesep, ranksep: REAL): Graph;
  VAR g: Graph;
BEGIN
  NEW(g);
  g.dir := dir; g.nodesep := nodesep; g.edgesep := edgesep; g.ranksep := ranksep;
  NEW(g.node, 16); g.nNodes := 0; g.nReal := 0;
  NEW(g.edge, 16); g.nEdges := 0;
  g.layer := NIL; g.layerLen := NIL; g.nRanks := 0;
  g.width := 0; g.height := 0;
  g.nSeg := 0; g.segU := NewInts(16); g.segV := NewInts(16); g.segW := NewInts(16);
  g.nCsr := 0;
  RETURN g
END New;

PROCEDURE NewNode(g: Graph; kind: INTEGER; w, h: REAL; rank, edge: INTEGER): INTEGER;
  VAR n: Node; a: Nodes; i: INTEGER;
BEGIN
  IF g.nNodes = LEN(g.node^) THEN
    NEW(a, 2 * g.nNodes);
    FOR i := 0 TO g.nNodes - 1 DO a[i] := g.node[i] END;
    g.node := a
  END;
  NEW(n);
  n.w := w; n.h := h; n.x := 0; n.y := 0;
  n.rank := rank; n.order := 0; n.kind := kind; n.edge := edge;
  IF (g.dir = LR) OR (g.dir = RL) THEN n.fw := h; n.fh := w ELSE n.fw := w; n.fh := h END;
  g.node[g.nNodes] := n; INC(g.nNodes);
  RETURN g.nNodes - 1
END NewNode;

(* Adds a node w by h points; returns its number, from 0, in order.
   Every node is added before the first edge. *)
PROCEDURE AddNode*(g: Graph; w, h: REAL): INTEGER;
BEGIN
  ASSERT(g.nEdges = 0);
  g.nReal := g.nNodes + 1;
  RETURN NewNode(g, Real, w, h, 0, -1)
END AddNode;

(* Adds an edge from node from to node to, spanning minlen ranks or more
   (1 for Mermaid's "-->", 2 for "--->"), of weight weight (1 by
   default), with a label labelW by labelH points if hasLabel; returns
   its number, from 0, in order *)
PROCEDURE AddEdge*(g: Graph; from, to, minlen, weight: INTEGER;
                   labelW, labelH: REAL; hasLabel: BOOLEAN): INTEGER;
  VAR e: Edge; a: Edges; i: INTEGER;
BEGIN
  ASSERT((from >= 0) & (from < g.nReal) & (to >= 0) & (to < g.nReal));
  IF g.nEdges = LEN(g.edge^) THEN
    NEW(a, 2 * g.nEdges);
    FOR i := 0 TO g.nEdges - 1 DO a[i] := g.edge[i] END;
    g.edge := a
  END;
  NEW(e);
  e.from := from; e.to := to;
  IF minlen < 1 THEN minlen := 1 END;
  e.minlen := minlen; e.weight := weight;
  e.labelW := labelW; e.labelH := labelH; e.hasLabel := hasLabel;
  e.reversed := FALSE; e.chain := NIL; e.nChain := 0; e.labelNode := -1;
  e.points := NIL; e.nPoints := 0; e.labelX := 0; e.labelY := 0;
  e.u := from; e.v := to;
  g.edge[g.nEdges] := e; INC(g.nEdges);
  RETURN g.nEdges - 1
END AddEdge;

PROCEDURE IsSelf(e: Edge): BOOLEAN;
BEGIN RETURN e.from = e.to
END IsSelf;

(* Cycles: dagre's dfsFAS. A depth-first search from each node in
   order, over the out edges in order; an edge to a node on the search's
   stack closes a cycle and is turned around. *)
PROCEDURE Acyclic(g: Graph);
  VAR visited, onStack: Bools; start, list: Ints; i, k: INTEGER; e: Edge;

  PROCEDURE Dfs(v: INTEGER);
    VAR j: INTEGER; e: Edge;
  BEGIN
    visited[v] := TRUE; onStack[v] := TRUE;
    FOR j := start[v] TO start[v + 1] - 1 DO
      e := g.edge[list[j]];
      IF onStack[e.to] THEN e.reversed := TRUE
      ELSIF ~visited[e.to] THEN Dfs(e.to)
      END
    END;
    onStack[v] := FALSE
  END Dfs;

BEGIN
  visited := NewBools(g.nReal); onStack := NewBools(g.nReal);
  start := NewInts(g.nReal + 1); list := NewInts(g.nEdges);
  FOR i := 0 TO g.nReal DO start[i] := 0 END;
  FOR i := 0 TO g.nEdges - 1 DO list[i] := -1 END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    IF ~IsSelf(e) THEN INC(start[e.from + 1]) END
  END;
  FOR i := 1 TO g.nReal DO start[i] := start[i] + start[i - 1] END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    IF ~IsSelf(e) THEN
      k := start[e.from];
      WHILE list[k] # -1 DO INC(k) END;
      list[k] := i
    END
  END;
  FOR i := 0 TO g.nReal - 1 DO
    IF ~visited[i] THEN Dfs(i) END
  END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    IF e.reversed THEN e.u := e.to; e.v := e.from ELSE e.u := e.from; e.v := e.to END
  END
END Acyclic;

(* Ranks *)

(* The network simplex on one connected part of the graph: its nodes
   nodes[0 .. n-1], and its edges, turned to point down, merged where
   they join the same two nodes (weights added, the longest minlen kept),
   as dagre's simplify. Sets rank[nodes[i]], the least being 0. *)
PROCEDURE Simplex(g: Graph; VAR nodes: ARRAY OF INTEGER; n: INTEGER; VAR loc: ARRAY OF INTEGER;
                  VAR rank: ARRAY OF INTEGER);
  VAR
    m, i, j, e, f, v, w, delta, best, s, nextLim, guard, minRank: INTEGER;
    su, sv, sml, swt, r, incStart, inc, low, lim, parentEdge, cut, byLim: Ints;
    inTree, isTree, visited: Bools;
    ed: Edge; found: BOOLEAN; count: INTEGER;

  PROCEDURE Slack(e: INTEGER): INTEGER;
  BEGIN RETURN r[sv[e]] - r[su[e]] - sml[e]
  END Slack;

  PROCEDURE Other(e, v: INTEGER): INTEGER;
  BEGIN
    IF su[e] = v THEN RETURN sv[e] ELSE RETURN su[e] END
  END Other;

  PROCEDURE Longest(v: INTEGER): INTEGER;
    VAR j, e, k, x: INTEGER;
  BEGIN
    IF ~visited[v] THEN
      visited[v] := TRUE;
      x := Inf;
      FOR j := incStart[v] TO incStart[v + 1] - 1 DO
        e := inc[j];
        IF su[e] = v THEN
          k := Longest(sv[e]) - sml[e];
          IF k < x THEN x := k END
        END
      END;
      IF x = Inf THEN x := 0 END;
      r[v] := x
    END;
    RETURN r[v]
  END Longest;

  PROCEDURE Tight(v: INTEGER);
    VAR j, e, w: INTEGER;
  BEGIN
    FOR j := incStart[v] TO incStart[v + 1] - 1 DO
      e := inc[j]; w := Other(e, v);
      IF ~inTree[w] & (Slack(e) = 0) THEN
        inTree[w] := TRUE; isTree[e] := TRUE; INC(count);
        Tight(w)
      END
    END
  END Tight;

  PROCEDURE LowLim(v, pe: INTEGER);
    VAR j, e, l: INTEGER;
  BEGIN
    visited[v] := TRUE; l := nextLim;
    parentEdge[v] := pe;
    FOR j := incStart[v] TO incStart[v + 1] - 1 DO
      e := inc[j];
      IF isTree[e] & ~visited[Other(e, v)] THEN LowLim(Other(e, v), e) END
    END;
    low[v] := l; lim[v] := nextLim; byLim[nextLim] := v; INC(nextLim)
  END LowLim;

  PROCEDURE InitLowLim;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO n - 1 DO visited[i] := FALSE END;
    nextLim := 0;
    LowLim(0, -1)
  END InitLowLim;

  (* dagre's calcCutValue for the tree edge above child *)
  PROCEDURE CutValue(child: INTEGER);
    VAR pe, j, e, x: INTEGER; childIsTail, isOut, toHead: BOOLEAN;
  BEGIN
    pe := parentEdge[child];
    childIsTail := su[pe] = child;
    x := swt[pe];
    FOR j := incStart[child] TO incStart[child + 1] - 1 DO
      e := inc[j];
      IF e # pe THEN
        isOut := su[e] = child;
        toHead := isOut = childIsTail;
        IF toHead THEN INC(x, swt[e]) ELSE DEC(x, swt[e]) END;
        IF isTree[e] THEN
          IF toHead THEN DEC(x, cut[e]) ELSE INC(x, cut[e]) END
        END
      END
    END;
    cut[pe] := x
  END CutValue;

  PROCEDURE InitCut;
    VAR k: INTEGER;
  BEGIN
    (* in postorder, children first; the root, last, has no edge above *)
    FOR k := 0 TO n - 2 DO CutValue(byLim[k]) END
  END InitCut;

  PROCEDURE IsDesc(x, root: INTEGER): BOOLEAN;
  BEGIN RETURN (low[root] <= lim[x]) & (lim[x] <= lim[root])
  END IsDesc;

  PROCEDURE UpdateRanks(v: INTEGER);
    VAR j, e, w: INTEGER;
  BEGIN
    visited[v] := TRUE;
    FOR j := incStart[v] TO incStart[v + 1] - 1 DO
      e := inc[j]; w := Other(e, v);
      IF isTree[e] & ~visited[w] THEN
        IF su[e] = w THEN r[w] := r[v] - sml[e] ELSE r[w] := r[v] + sml[e] END;
        UpdateRanks(w)
      END
    END
  END UpdateRanks;

BEGIN
  IF n = 1 THEN rank[nodes[0]] := 0; RETURN END;
  (* the edges, merged *)
  m := 0;
  su := NewInts(g.nEdges); sv := NewInts(g.nEdges); sml := NewInts(g.nEdges); swt := NewInts(g.nEdges);
  FOR i := 0 TO g.nEdges - 1 DO
    ed := g.edge[i];
    IF ~IsSelf(ed) & (loc[ed.u] >= 0) & (nodes[loc[ed.u]] = ed.u) THEN
      v := loc[ed.u]; w := loc[ed.v];
      j := 0; WHILE (j < m) & ~((su[j] = v) & (sv[j] = w)) DO INC(j) END;
      IF j = m THEN su[m] := v; sv[m] := w; sml[m] := 2 * ed.minlen; swt[m] := ed.weight; INC(m)
      ELSE
        INC(swt[j], ed.weight);
        IF 2 * ed.minlen > sml[j] THEN sml[j] := 2 * ed.minlen END
      END
    END
  END;
  (* each node's edges *)
  incStart := NewInts(n + 1); inc := NewInts(2 * m);
  FOR i := 0 TO n DO incStart[i] := 0 END;
  FOR e := 0 TO m - 1 DO INC(incStart[su[e] + 1]); INC(incStart[sv[e] + 1]) END;
  FOR i := 1 TO n DO incStart[i] := incStart[i] + incStart[i - 1] END;
  low := NewInts(n);
  FOR i := 0 TO n - 1 DO low[i] := incStart[i] END;
  FOR e := 0 TO m - 1 DO
    inc[low[su[e]]] := e; INC(low[su[e]]);
    inc[low[sv[e]]] := e; INC(low[sv[e]])
  END;
  r := NewInts(n); lim := NewInts(n); parentEdge := NewInts(n); byLim := NewInts(n);
  cut := NewInts(m);
  inTree := NewBools(n); isTree := NewBools(m); visited := NewBools(n);
  (* longest paths from the sources *)
  FOR i := 0 TO n - 1 DO
    found := FALSE;
    FOR j := incStart[i] TO incStart[i + 1] - 1 DO
      IF sv[inc[j]] = i THEN found := TRUE END
    END;
    IF ~found THEN s := Longest(i) END
  END;
  (* a feasible tree of tight edges *)
  inTree[0] := TRUE; count := 1;
  LOOP
    FOR i := 0 TO n - 1 DO
      IF inTree[i] THEN Tight(i) END
    END;
    IF count >= n THEN EXIT END;
    best := Inf; f := -1;
    FOR e := 0 TO m - 1 DO
      IF (inTree[su[e]] # inTree[sv[e]]) & (Slack(e) < best) THEN best := Slack(e); f := e END
    END;
    IF inTree[su[f]] THEN delta := Slack(f) ELSE delta := -Slack(f) END;
    FOR i := 0 TO n - 1 DO
      IF inTree[i] THEN INC(r[i], delta) END
    END
  END;
  InitLowLim; InitCut;
  (* exchange edges while a tree edge has a negative cut value *)
  guard := 0;
  LOOP
    e := 0; WHILE (e < m) & ~(isTree[e] & (cut[e] < 0)) DO INC(e) END;
    IF (e = m) OR (guard > 10 * m + 100) THEN EXIT END;
    INC(guard);
    (* dagre's enterEdge *)
    v := su[e]; w := sv[e];
    IF lim[v] > lim[w] THEN s := w; found := TRUE ELSE s := v; found := FALSE END;
    best := Inf; f := -1;
    FOR j := 0 TO m - 1 DO
      IF (found = IsDesc(su[j], s)) & (found # IsDesc(sv[j], s)) & (Slack(j) < best) THEN
        best := Slack(j); f := j
      END
    END;
    IF f < 0 THEN EXIT END;
    isTree[e] := FALSE; isTree[f] := TRUE;
    InitLowLim; InitCut;
    FOR i := 0 TO n - 1 DO visited[i] := FALSE END;
    UpdateRanks(byLim[n - 1])
  END;
  minRank := Inf;
  FOR i := 0 TO n - 1 DO
    IF r[i] < minRank THEN minRank := r[i] END
  END;
  FOR i := 0 TO n - 1 DO rank[nodes[i]] := r[i] - minRank END
END Simplex;

(* Ranks every node: each connected part of the graph alone, from rank
   0 *)
PROCEDURE Rank(g: Graph);
  VAR comp, nodes, loc, rank: Ints; i, c, n: INTEGER; e: Edge; done: Bools;

  PROCEDURE Find(x: INTEGER): INTEGER;
  BEGIN
    WHILE comp[x] # x DO comp[x] := comp[comp[x]]; x := comp[x] END;
    RETURN x
  END Find;

BEGIN
  comp := NewInts(g.nReal); nodes := NewInts(g.nReal); loc := NewInts(g.nReal);
  rank := NewInts(g.nReal); done := NewBools(g.nReal);
  FOR i := 0 TO g.nReal - 1 DO comp[i] := i; loc[i] := -1 END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    IF Find(e.u) # Find(e.v) THEN comp[Find(e.u)] := Find(e.v) END
  END;
  FOR c := 0 TO g.nReal - 1 DO
    IF ~done[Find(c)] THEN
      done[Find(c)] := TRUE;
      n := 0;
      FOR i := 0 TO g.nReal - 1 DO
        IF Find(i) = Find(c) THEN nodes[n] := i; loc[i] := n; INC(n) END
      END;
      Simplex(g, nodes^, n, loc^, rank^);
      FOR i := 0 TO n - 1 DO loc[nodes[i]] := -1 END
    END
  END;
  FOR i := 0 TO g.nReal - 1 DO g.node[i].rank := rank[i] END
END Rank;

(* Dummies: each edge a chain of dummies through the ranks between its
   ends, its label's dummy at the middle rank; and the segments between
   them *)
PROCEDURE AddSegment(g: Graph; u, v, w: INTEGER);
BEGIN
  GrowInts(g.segU, g.nSeg, g.nSeg + 1); GrowInts(g.segV, g.nSeg, g.nSeg + 1);
  GrowInts(g.segW, g.nSeg, g.nSeg + 1);
  g.segU[g.nSeg] := u; g.segV[g.nSeg] := v; g.segW[g.nSeg] := w; INC(g.nSeg)
END AddSegment;

PROCEDURE MakeChains(g: Graph);
  VAR i, r, ru, rv, labelRank, d, prev: INTEGER; e: Edge;
BEGIN
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    IF ~IsSelf(e) THEN
      ru := g.node[e.u].rank; rv := g.node[e.v].rank;
      labelRank := ru + (rv - ru) DIV 2;
      e.chain := NewInts(rv - ru); e.nChain := 0;
      prev := e.u;
      FOR r := ru + 1 TO rv - 1 DO
        IF e.hasLabel & (r = labelRank) THEN
          d := NewNode(g, LabelDummy, e.labelW, e.labelH, r, i); e.labelNode := d
        ELSE
          d := NewNode(g, Dummy, 0, 0, r, i)
        END;
        e.chain[e.nChain] := d; INC(e.nChain);
        AddSegment(g, prev, d, e.weight);
        prev := d
      END;
      AddSegment(g, prev, e.v, e.weight)
    END
  END
END MakeChains;

(* Each node's segments in and out *)
PROCEDURE MakeLists(g: Graph);
  VAR i, s, n: INTEGER; fillIn, fillOut: Ints;
BEGIN
  n := g.nNodes; g.nCsr := n;
  g.inStart := NewInts(n + 1); g.outStart := NewInts(n + 1);
  g.inList := NewInts(g.nSeg); g.outList := NewInts(g.nSeg);
  FOR i := 0 TO n DO g.inStart[i] := 0; g.outStart[i] := 0 END;
  FOR s := 0 TO g.nSeg - 1 DO INC(g.inStart[g.segV[s] + 1]); INC(g.outStart[g.segU[s] + 1]) END;
  FOR i := 1 TO n DO
    g.inStart[i] := g.inStart[i] + g.inStart[i - 1];
    g.outStart[i] := g.outStart[i] + g.outStart[i - 1]
  END;
  fillIn := NewInts(n); fillOut := NewInts(n);
  FOR i := 0 TO n - 1 DO fillIn[i] := g.inStart[i]; fillOut[i] := g.outStart[i] END;
  FOR s := 0 TO g.nSeg - 1 DO
    g.inList[fillIn[g.segV[s]]] := s; INC(fillIn[g.segV[s]]);
    g.outList[fillOut[g.segU[s]]] := s; INC(fillOut[g.segU[s]])
  END
END MakeLists;

(* Order *)

PROCEDURE Crossings(g: Graph): LONGINT;
  VAR a, b: INTEGER; c: LONGINT; d1, d2: INTEGER;
BEGIN
  c := 0;
  FOR a := 0 TO g.nSeg - 1 DO
    FOR b := a + 1 TO g.nSeg - 1 DO
      IF g.node[g.segU[a]].rank = g.node[g.segU[b]].rank THEN
        d1 := g.node[g.segU[a]].order - g.node[g.segU[b]].order;
        d2 := g.node[g.segV[a]].order - g.node[g.segV[b]].order;
        IF (d1 < 0) & (d2 > 0) OR (d1 > 0) & (d2 < 0) THEN
          INC(c, LONG(g.segW[a]) * g.segW[b])
        END
      END
    END
  END;
  RETURN c
END Crossings;

(* dagre's sort, for one rank, by the barycentres of each node's
   neighbours in the rank above (down) or below (up). A node with no
   neighbours there keeps its place. Ties keep the old order, or the
   reverse if biasRight. *)
PROCEDURE SortLayer(g: Graph; r: INTEGER; down, biasRight: BOOLEAN);
  VAR
    n, i, j, k, s, v, nb, nu, vsIndex: INTEGER;
    sum, weight: REAL;
    bary: Reals; has: Bools; idx, sortable, unsortable, out: Ints;
    layer: Ints;

  PROCEDURE Before(a, b: INTEGER): BOOLEAN;  (* sortable entry a sorts before b *)
  BEGIN
    IF bary[a] # bary[b] THEN RETURN bary[a] < bary[b]
    ELSIF biasRight THEN RETURN a > b
    ELSE RETURN a < b
    END
  END Before;

BEGIN
  layer := g.layer[r]; n := g.layerLen[r];
  bary := NewReals(n); has := NewBools(n);
  sortable := NewInts(n); unsortable := NewInts(n); out := NewInts(n); idx := NewInts(n);
  FOR i := 0 TO n - 1 DO
    v := layer[i]; sum := 0; weight := 0;
    IF v < g.nCsr THEN
      IF down THEN
        FOR k := g.inStart[v] TO g.inStart[v + 1] - 1 DO
          s := g.inList[k];
          sum := sum + g.segW[s] * g.node[g.segU[s]].order; weight := weight + g.segW[s]
        END
      ELSE
        FOR k := g.outStart[v] TO g.outStart[v + 1] - 1 DO
          s := g.outList[k];
          sum := sum + g.segW[s] * g.node[g.segV[s]].order; weight := weight + g.segW[s]
        END
      END
    END;
    IF weight > 0 THEN bary[i] := sum / weight; has[i] := TRUE END
  END;
  nb := 0; nu := 0;
  FOR i := 0 TO n - 1 DO
    IF has[i] THEN
      (* insertion sort: stable for the given order *)
      j := nb;
      WHILE (j > 0) & Before(i, sortable[j - 1]) DO sortable[j] := sortable[j - 1]; DEC(j) END;
      sortable[j] := i; INC(nb)
    ELSE
      unsortable[nu] := i; INC(nu)
    END
  END;
  (* the unsortable keep their places among the sorted *)
  k := 0; vsIndex := 0; j := 0;
  WHILE (j < nu) & (unsortable[j] <= vsIndex) DO out[k] := unsortable[j]; INC(k); INC(j); INC(vsIndex) END;
  FOR i := 0 TO nb - 1 DO
    out[k] := sortable[i]; INC(k); INC(vsIndex);
    WHILE (j < nu) & (unsortable[j] <= vsIndex) DO out[k] := unsortable[j]; INC(k); INC(j); INC(vsIndex) END
  END;
  WHILE j < nu DO out[k] := unsortable[j]; INC(k); INC(j) END;
  FOR i := 0 TO n - 1 DO idx[i] := layer[out[i]] END;
  FOR i := 0 TO n - 1 DO layer[i] := idx[i]; g.node[idx[i]].order := i END
END SortLayer;

PROCEDURE Order(g: Graph);
  VAR
    i, r, v, maxRank, lastBest: INTEGER;
    bestCC, cc: LONGINT;
    visited: Bools; byRank, best: Ints; count: Ints;

  PROCEDURE Visit(v: INTEGER);
    VAR k, r: INTEGER;
  BEGIN
    IF ~visited[v] THEN
      visited[v] := TRUE;
      r := g.node[v].rank;
      g.layer[r][g.layerLen[r]] := v; g.node[v].order := g.layerLen[r]; INC(g.layerLen[r]);
      FOR k := g.outStart[v] TO g.outStart[v + 1] - 1 DO Visit(g.segV[g.outList[k]]) END
    END
  END Visit;

  PROCEDURE Save;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO g.nNodes - 1 DO best[i] := g.node[i].order END
  END Save;

BEGIN
  maxRank := 0;
  FOR i := 0 TO g.nNodes - 1 DO
    IF g.node[i].rank > maxRank THEN maxRank := g.node[i].rank END
  END;
  g.nRanks := maxRank + 1;
  count := NewInts(g.nRanks);
  FOR r := 0 TO maxRank DO count[r] := 0 END;
  FOR i := 0 TO g.nNodes - 1 DO INC(count[g.node[i].rank]) END;
  NEW(g.layer, g.nRanks); g.layerLen := NewInts(g.nRanks);
  FOR r := 0 TO maxRank DO g.layer[r] := NewInts(count[r]); g.layerLen[r] := 0 END;
  (* dagre's initOrder: depth first from the nodes in rank order *)
  visited := NewBools(g.nNodes); byRank := NewInts(g.nNodes);
  i := 0;
  FOR r := 0 TO maxRank DO
    FOR v := 0 TO g.nNodes - 1 DO
      IF g.node[v].rank = r THEN byRank[i] := v; INC(i) END
    END
  END;
  FOR i := 0 TO g.nNodes - 1 DO Visit(byRank[i]) END;
  (* sweeps *)
  best := NewInts(g.nNodes); Save;
  bestCC := MAX(LONGINT); lastBest := 0; i := 0;
  WHILE lastBest < 4 DO
    IF ODD(i) THEN
      FOR r := 1 TO maxRank DO SortLayer(g, r, TRUE, i MOD 4 >= 2) END
    ELSE
      FOR r := maxRank - 1 TO 0 BY -1 DO SortLayer(g, r, FALSE, i MOD 4 >= 2) END
    END;
    cc := Crossings(g);
    IF cc < bestCC THEN lastBest := 0; Save; bestCC := cc END;
    INC(i); INC(lastBest)
  END;
  FOR v := 0 TO g.nNodes - 1 DO
    g.node[v].order := best[v]; g.layer[g.node[v].rank][best[v]] := v
  END
END Order;

(* Self-loops: a dummy for each, just after its node in its rank, as wide
   as its label (dagre's insertSelfEdges) *)
PROCEDURE InsertSelfLoops(g: Graph);
  VAR r, i, j, n, k, d, v: INTEGER; e: Edge; layer, count: Ints;
BEGIN
  count := NewInts(g.nRanks);
  FOR r := 0 TO g.nRanks - 1 DO count[r] := g.layerLen[r] END;
  FOR j := 0 TO g.nEdges - 1 DO
    IF IsSelf(g.edge[j]) THEN INC(count[g.node[g.edge[j].from].rank]) END
  END;
  FOR r := 0 TO g.nRanks - 1 DO
    IF count[r] > g.layerLen[r] THEN
      layer := NewInts(count[r]); n := 0;
      FOR i := 0 TO g.layerLen[r] - 1 DO
        v := g.layer[r][i];
        layer[n] := v; g.node[v].order := n; INC(n);
        FOR j := 0 TO g.nEdges - 1 DO
          e := g.edge[j];
          IF IsSelf(e) & (e.from = v) THEN
            d := NewNode(g, SelfDummy, e.labelW, e.labelH, r, j);
            e.chain := NewInts(1); e.chain[0] := d; e.nChain := 1;
            IF e.hasLabel THEN e.labelNode := d END;
            layer[n] := d; g.node[d].order := n; INC(n)
          END
        END
      END;
      g.layer[r] := layer; g.layerLen[r] := n
    END
  END;
  k := 0 (* unused *)
END InsertSelfLoops;

(* The topology half: cycles broken, ranks, chains and orders *)
PROCEDURE Topology*(g: Graph);
BEGIN
  Acyclic(g);
  Rank(g);
  MakeChains(g);
  MakeLists(g);
  Order(g);
  InsertSelfLoops(g)
END Topology;

(* Geometry *)

PROCEDURE IsDummy(g: Graph; v: INTEGER): BOOLEAN;
BEGIN RETURN g.node[v].kind # Real
END IsDummy;

(* The ranks, one below another *)
PROCEDURE PositionY(g: Graph);
  VAR r, i: INTEGER; y, maxH: REAL; n: Node;
BEGIN
  y := 0; NEW(g.rankH, g.nRanks + 1);
  FOR r := 0 TO g.nRanks - 1 DO
    maxH := 0;
    FOR i := 0 TO g.layerLen[r] - 1 DO
      n := g.node[g.layer[r][i]];
      IF n.fh > maxH THEN maxH := n.fh END
    END;
    g.rankH[r] := maxH;
    FOR i := 0 TO g.layerLen[r] - 1 DO g.node[g.layer[r][i]].y := y + maxH / 2 END;
    y := y + maxH + g.ranksep / 2   (* half, for the grid of half ranks *)
  END
END PositionY;

(* Brandes and Köpf, as dagre's position/bk.js *)
PROCEDURE PositionX(g: Graph);
  VAR
    nn, a, i, k, r, v, s, best: INTEGER;
    conflict: Bools;
    root, align, pos: Ints;
    xs: ARRAY 4 OF Reals;
    width, lo, hi, minW, delta, t: REAL;
    vals: ARRAY 4 OF REAL;
    minX, maxX: ARRAY 4 OF REAL;
    up, left: BOOLEAN;
    bStart, bList, bInStart, bInList: Ints; bu, bv: Ints; bw: Reals; nb: INTEGER;
    xr: Reals; done: Bools;

  (* the j-th node of the k-th rank of the alignment's layering *)
  PROCEDURE Adj(k, j: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN
    IF up THEN r := k ELSE r := g.nRanks - 1 - k END;
    IF left THEN RETURN g.layer[r][j] ELSE RETURN g.layer[r][g.layerLen[r] - 1 - j] END
  END Adj;

  PROCEDURE AdjLen(k: INTEGER): INTEGER;
  BEGIN
    IF up THEN RETURN g.layerLen[k] ELSE RETURN g.layerLen[g.nRanks - 1 - k] END
  END AdjLen;

  (* dagre's findType1Conflicts: a segment that crosses an inner
     segment, one between two dummies, is marked *)
  PROCEDURE Type1;
    VAR r, i, j, k, k0, k1, scanPos, v, w, s, u, uPos, n: INTEGER;
  BEGIN
    FOR r := 1 TO g.nRanks - 1 DO
      k0 := 0; scanPos := 0; n := g.layerLen[r];
      FOR i := 0 TO n - 1 DO
        v := g.layer[r][i];
        w := -1;
        IF IsDummy(g, v) & (v < g.nCsr) THEN
          FOR k := g.inStart[v] TO g.inStart[v + 1] - 1 DO
            u := g.segU[g.inList[k]];
            IF (w < 0) & IsDummy(g, u) THEN w := u END
          END
        END;
        IF w >= 0 THEN k1 := g.node[w].order ELSE k1 := g.layerLen[r - 1] END;
        IF (w >= 0) OR (i = n - 1) THEN
          FOR j := scanPos TO i DO
            v := g.layer[r][j];
            IF v < g.nCsr THEN
              FOR k := g.inStart[v] TO g.inStart[v + 1] - 1 DO
                s := g.inList[k]; u := g.segU[s]; uPos := g.node[u].order;
                IF ((uPos < k0) OR (k1 < uPos)) & ~(IsDummy(g, u) & IsDummy(g, v)) THEN
                  conflict[s] := TRUE
                END
              END
            END
          END;
          scanPos := i + 1; k0 := k1
        END
      END
    END
  END Type1;

  (* dagre's verticalAlignment: each node aligned with a median neighbour
     in the rank before it in the alignment's layering *)
  PROCEDURE Align;
    VAR k, j, v, w, n, i, m, prevIdx, lo, hi, c, s: INTEGER; ws, segs: Ints;
  BEGIN
    FOR v := 0 TO nn - 1 DO root[v] := v; align[v] := v END;
    FOR k := 0 TO g.nRanks - 1 DO
      FOR j := 0 TO AdjLen(k) - 1 DO pos[Adj(k, j)] := j END
    END;
    ws := NewInts(g.nSeg + 1); segs := NewInts(g.nSeg + 1);
    FOR k := 0 TO g.nRanks - 1 DO
      prevIdx := -1;
      FOR j := 0 TO AdjLen(k) - 1 DO
        v := Adj(k, j);
        n := 0;
        IF v < g.nCsr THEN
          IF up THEN lo := g.inStart[v]; hi := g.inStart[v + 1] ELSE lo := g.outStart[v]; hi := g.outStart[v + 1] END;
          FOR i := lo TO hi - 1 DO
            IF up THEN s := g.inList[i]; w := g.segU[s] ELSE s := g.outList[i]; w := g.segV[s] END;
            (* insert by pos, once *)
            c := 0; WHILE (c < n) & (ws[c] # w) DO INC(c) END;
            IF c = n THEN
              c := n;
              WHILE (c > 0) & (pos[ws[c - 1]] > pos[w]) DO ws[c] := ws[c - 1]; segs[c] := segs[c - 1]; DEC(c) END;
              ws[c] := w; segs[c] := s; INC(n)
            ELSIF conflict[s] THEN segs[c] := s
            END
          END
        END;
        IF n > 0 THEN
          m := (n - 1) DIV 2;
          FOR i := m TO n DIV 2 DO
            w := ws[i];
            IF (align[v] = v) & (prevIdx < pos[w]) & ~conflict[segs[i]] THEN
              align[w] := v; root[v] := root[w]; align[v] := root[v];
              prevIdx := pos[w]
            END
          END
        END
      END
    END
  END Align;

  PROCEDURE Sep(v, u: INTEGER): REAL;
    VAR x: REAL;
  BEGIN
    x := g.node[v].fw / 2 + g.node[u].fw / 2;
    IF IsDummy(g, v) THEN x := x + g.edgesep / 2 ELSE x := x + g.nodesep / 2 END;
    IF IsDummy(g, u) THEN x := x + g.edgesep / 2 ELSE x := x + g.nodesep / 2 END;
    RETURN x
  END Sep;

  PROCEDURE Pass1(b: INTEGER);
    VAR k, e: INTEGER; x: REAL;
  BEGIN
    IF ~done[b] THEN
      done[b] := TRUE; x := 0;
      FOR k := bInStart[b] TO bInStart[b + 1] - 1 DO
        e := bInList[k]; Pass1(bu[e]);
        IF xr[bu[e]] + bw[e] > x THEN x := xr[bu[e]] + bw[e] END
      END;
      xr[b] := x
    END
  END Pass1;

  PROCEDURE Pass2(b: INTEGER);
    VAR k, e: INTEGER; x: REAL; any: BOOLEAN;
  BEGIN
    IF ~done[b] THEN
      done[b] := TRUE; any := FALSE; x := 0;
      FOR k := bStart[b] TO bStart[b + 1] - 1 DO
        e := bList[k]; Pass2(bv[e]);
        IF ~any OR (xr[bv[e]] - bw[e] < x) THEN x := xr[bv[e]] - bw[e]; any := TRUE END
      END;
      IF any & (x > xr[b]) THEN xr[b] := x END
    END
  END Pass2;

  (* dagre's horizontalCompaction: the blocks placed as far left as
     they go, then each moved right as far as the blocks right of it
     let it *)
  PROCEDURE Compact(VAR x: Reals);
    VAR k, j, u, v, e, i: INTEGER; fill: Ints;
  BEGIN
    nb := 0;
    FOR k := 0 TO g.nRanks - 1 DO
      FOR j := 1 TO AdjLen(k) - 1 DO
        u := Adj(k, j - 1); v := Adj(k, j);
        bu[nb] := root[u]; bv[nb] := root[v]; bw[nb] := Sep(v, u); INC(nb)
      END
    END;
    FOR i := 0 TO nn DO bStart[i] := 0; bInStart[i] := 0 END;
    FOR e := 0 TO nb - 1 DO INC(bStart[bu[e] + 1]); INC(bInStart[bv[e] + 1]) END;
    FOR i := 1 TO nn DO bStart[i] := bStart[i] + bStart[i - 1]; bInStart[i] := bInStart[i] + bInStart[i - 1] END;
    fill := NewInts(2 * nn);
    FOR i := 0 TO nn - 1 DO fill[i] := bStart[i]; fill[nn + i] := bInStart[i] END;
    FOR e := 0 TO nb - 1 DO
      bList[fill[bu[e]]] := e; INC(fill[bu[e]]);
      bInList[fill[nn + bv[e]]] := e; INC(fill[nn + bv[e]])
    END;
    FOR i := 0 TO nn - 1 DO done[i] := FALSE; xr[i] := 0 END;
    FOR i := 0 TO nn - 1 DO
      IF root[i] = i THEN Pass1(i) END
    END;
    FOR i := 0 TO nn - 1 DO done[i] := FALSE END;
    FOR i := 0 TO nn - 1 DO
      IF root[i] = i THEN Pass2(i) END
    END;
    x := NewReals(nn);
    FOR i := 0 TO nn - 1 DO x[i] := xr[root[i]] END
  END Compact;

BEGIN
  nn := g.nNodes;
  IF nn = 0 THEN RETURN END;
  conflict := NewBools(g.nSeg);
  root := NewInts(nn); align := NewInts(nn); pos := NewInts(nn);
  bu := NewInts(nn); bv := NewInts(nn); bw := NewReals(nn);
  bStart := NewInts(nn + 1); bInStart := NewInts(nn + 1); bList := NewInts(nn); bInList := NewInts(nn);
  xr := NewReals(nn); done := NewBools(nn);
  Type1;
  FOR a := 0 TO 3 DO
    up := a < 2; left := ~ODD(a);   (* ul, ur, dl, dr *)
    Align;
    Compact(xs[a]);
    IF ~left THEN
      FOR i := 0 TO nn - 1 DO xs[a][i] := -xs[a][i] END
    END
  END;
  (* the narrowest alignment; the others moved to its left or right edge *)
  best := 0; minW := 0;
  FOR a := 0 TO 3 DO
    lo := 0; hi := 0; minX[a] := 0; maxX[a] := 0;
    FOR i := 0 TO nn - 1 DO
      t := xs[a][i] - g.node[i].fw / 2; IF (i = 0) OR (t < lo) THEN lo := t END;
      t := xs[a][i] + g.node[i].fw / 2; IF (i = 0) OR (t > hi) THEN hi := t END;
      IF (i = 0) OR (xs[a][i] < minX[a]) THEN minX[a] := xs[a][i] END;
      IF (i = 0) OR (xs[a][i] > maxX[a]) THEN maxX[a] := xs[a][i] END
    END;
    width := hi - lo;
    IF (a = 0) OR (width < minW) THEN minW := width; best := a END
  END;
  FOR a := 0 TO 3 DO
    IF a # best THEN
      IF ~ODD(a) THEN delta := minX[best] - minX[a] ELSE delta := maxX[best] - maxX[a] END;
      FOR i := 0 TO nn - 1 DO xs[a][i] := xs[a][i] + delta END
    END
  END;
  (* balanced: the mean of the two middle values *)
  FOR v := 0 TO nn - 1 DO
    FOR a := 0 TO 3 DO
      t := xs[a][v]; k := a;
      WHILE (k > 0) & (vals[k - 1] > t) DO vals[k] := vals[k - 1]; DEC(k) END;
      vals[k] := t
    END;
    g.node[v].x := (vals[1] + vals[2]) / 2
  END;
  r := 0; s := 0 (* unused *)
END PositionX;

(* Turns (x, y) from the frame to the direction of the drawing *)
PROCEDURE Turn(g: Graph; VAR x, y: REAL);
  VAR t: REAL;
BEGIN
  IF (g.dir = BT) OR (g.dir = RL) THEN y := -y END;
  IF (g.dir = LR) OR (g.dir = RL) THEN t := x; x := y; y := t END
END Turn;

(* Where the line from n's centre towards (px, py), in another rank,
   crosses the face of n's box that faces that rank: on the bottom face
   if (px, py) is below, the top face if above, at the corner if the
   line leaves by a side. dagre's intersectRect lets an edge leave by a
   side, and then run along the rank, through the nodes beside n. *)
PROCEDURE Face(n: Node; px, py: REAL; VAR x, y: REAL);
  VAR dy, hw, hh: REAL;
BEGIN
  dy := py - n.y; hw := n.fw / 2; hh := n.fh / 2;
  IF dy = 0 THEN G.RectIntersect(n.x, n.y, n.fw, n.fh, px, py, x, y)
  ELSE
    IF dy < 0 THEN hh := -hh END;
    y := n.y + hh; x := n.x + (px - n.x) * hh / dy;
    IF x > n.x + hw THEN x := n.x + hw ELSIF x < n.x - hw THEN x := n.x - hw END
  END
END Face;

(* Where an edge's end node is shorter than its rank, a point straight
   out from its face to the edge of the rank's band, so that the edge
   leaves the band before it turns aside, and does not pass through a
   taller neighbour in the same rank. The point is doubled, so that the
   curve through the points turns at it and stays out of the band. *)
PROCEDURE Bands(g: Graph; e: Edge; nu, nv: Node);
  VAR p: G.Points; n, j: INTEGER; addU, addV: BOOLEAN; yu, yv: REAL;

  PROCEDURE Need(nd: Node; fy, py: REAL; VAR y: REAL): BOOLEAN;
    VAR hh: REAL;
  BEGIN
    hh := g.rankH[nd.rank] / 2;
    IF py > nd.y THEN y := nd.y + hh ELSE y := nd.y - hh END;
    RETURN (nd.fh < 2 * hh - 1) & (ABS(py - nd.y) > hh) & (ABS(y - fy) > 0.5)
  END Need;

BEGIN
  n := e.nPoints;
  addU := Need(nu, e.points[0].y, e.points[1].y, yu);
  addV := Need(nv, e.points[n - 1].y, e.points[n - 2].y, yv);
  IF addU OR addV THEN
    p := G.NewPoints(n + 4); j := 0;
    p[j] := e.points[0]; INC(j);
    IF addU THEN G.Set(p[j], e.points[0].x, yu); p[j + 1] := p[j]; INC(j, 2) END;
    FOR n := 1 TO e.nPoints - 2 DO p[j] := e.points[n]; INC(j) END;
    IF addV THEN G.Set(p[j], e.points[e.nPoints - 1].x, yv); p[j + 1] := p[j]; INC(j, 2) END;
    p[j] := e.points[e.nPoints - 1]; INC(j);
    e.points := p; e.nPoints := j
  END
END Bands;

PROCEDURE Routes(g: Graph);
  VAR i, j, k: INTEGER; e: Edge; n, d, nu, nv: Node; x, y, dx, dy: REAL; p: G.Point;
BEGIN
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    IF IsSelf(e) THEN
      (* out of the node's right side, round through the gap between
         it and its dummy, and back in lower down; the label, at the
         dummy, is right of the loop. (dagre's positionSelfEdges starts
         and ends the loop away from the node, round the dummy's
         centre.) Through these four points the curve reaches 11/12 of
         the way across the gap. *)
      n := g.node[e.from]; d := g.node[e.chain[0]];
      x := n.x + n.fw / 2; y := n.y; dx := d.x - d.fw / 2 - x; dy := n.fh / 2;
      e.points := G.NewPoints(4); e.nPoints := 4;
      G.Set(e.points[0], x, y - dy / 2);
      G.Set(e.points[1], x + dx, y - dy);
      G.Set(e.points[2], x + dx, y + dy);
      G.Set(e.points[3], x, y + dy / 2)
    ELSE
      nu := g.node[e.u]; nv := g.node[e.v];
      e.points := G.NewPoints(e.nChain + 2); e.nPoints := e.nChain + 2;
      FOR j := 0 TO e.nChain - 1 DO
        d := g.node[e.chain[j]]; G.Set(e.points[j + 1], d.x, d.y)
      END;
      IF e.nChain > 0 THEN
        Face(nu, e.points[1].x, e.points[1].y, x, y);
        G.Set(e.points[0], x, y);
        Face(nv, e.points[e.nChain].x, e.points[e.nChain].y, x, y);
        G.Set(e.points[e.nChain + 1], x, y)
      ELSE
        Face(nu, nv.x, nv.y, x, y); G.Set(e.points[0], x, y);
        Face(nv, nu.x, nu.y, x, y); G.Set(e.points[1], x, y)
      END;
      Bands(g, e, nu, nv);
      IF e.reversed THEN
        FOR j := 0 TO e.nPoints DIV 2 - 1 DO
          k := e.nPoints - 1 - j;
          p := e.points[j]; e.points[j] := e.points[k]; e.points[k] := p
        END
      END
    END;
    IF e.labelNode >= 0 THEN
      e.labelX := g.node[e.labelNode].x; e.labelY := g.node[e.labelNode].y
    END
  END
END Routes;

(* Turns the drawing and moves it to (0, 0) *)
PROCEDURE Finish(g: Graph);
  VAR i, j: INTEGER; n: Node; e: Edge; minX, minY, maxX, maxY: REAL; first: BOOLEAN;

  PROCEDURE Box(x, y, w, h: REAL);
  BEGIN
    IF first OR (x - w / 2 < minX) THEN minX := x - w / 2 END;
    IF first OR (y - h / 2 < minY) THEN minY := y - h / 2 END;
    IF first OR (x + w / 2 > maxX) THEN maxX := x + w / 2 END;
    IF first OR (y + h / 2 > maxY) THEN maxY := y + h / 2 END;
    first := FALSE
  END Box;

BEGIN
  FOR i := 0 TO g.nNodes - 1 DO n := g.node[i]; Turn(g, n.x, n.y) END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    FOR j := 0 TO e.nPoints - 1 DO Turn(g, e.points[j].x, e.points[j].y) END;
    Turn(g, e.labelX, e.labelY)
  END;
  first := TRUE; minX := 0; minY := 0; maxX := 0; maxY := 0;
  FOR i := 0 TO g.nNodes - 1 DO
    n := g.node[i];
    IF n.kind = Real THEN Box(n.x, n.y, n.w, n.h) END
  END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    FOR j := 0 TO e.nPoints - 1 DO Box(e.points[j].x, e.points[j].y, 0, 0) END;
    IF e.hasLabel THEN Box(e.labelX, e.labelY, e.labelW, e.labelH) END
  END;
  FOR i := 0 TO g.nNodes - 1 DO n := g.node[i]; n.x := n.x - minX; n.y := n.y - minY END;
  FOR i := 0 TO g.nEdges - 1 DO
    e := g.edge[i];
    FOR j := 0 TO e.nPoints - 1 DO
      e.points[j].x := e.points[j].x - minX; e.points[j].y := e.points[j].y - minY
    END;
    e.labelX := e.labelX - minX; e.labelY := e.labelY - minY
  END;
  g.width := maxX - minX; g.height := maxY - minY
END Finish;

(* The geometry half: positions, routes, the turn *)
PROCEDURE Geometry*(g: Graph);
BEGIN
  PositionY(g);
  PositionX(g);
  Routes(g);
  Finish(g)
END Geometry;

(* Lays g out: Topology, then Geometry *)
PROCEDURE Layout*(g: Graph);
BEGIN
  Topology(g);
  Geometry(g)
END Layout;

END PmLayout.
