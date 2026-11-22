MODULE PmLayoutTest;
(* Tests of PmLayout and PmGeom on small graphs whose layout is known,
   and of PmFlowLayout on the user's diagrams (test/cases), with the
   made-up font test/fonts/devpdf/TS: no two boxes overlap, and no edge
   passes through a node other than its own two. *)

IMPORT Out, PmIO, G := PmGeom, L := PmLayout, FL := PmFlowLayout, F := PmFlow,
  M := PmMetrics, Lex := PmLex;

VAR failures: INTEGER; font: M.Font;

PROCEDURE Check(name: ARRAY OF CHAR; got, want: LONGINT);
BEGIN
  IF got = want THEN Out.String("ok   - ") ELSE Out.String("FAIL - "); INC(failures) END;
  Out.String(name);
  IF got # want THEN Out.String(": got "); Out.Int(got, 0); Out.String(", want "); Out.Int(want, 0) END;
  Out.Ln
END Check;

PROCEDURE B(b: BOOLEAN): LONGINT;
BEGIN
  IF b THEN RETURN 1 END;
  RETURN 0
END B;

PROCEDURE Append(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE (t[j] # 0X) & (i < LEN(s) - 1) DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Append;

(* x in hundredths *)
PROCEDURE R(x: REAL): LONGINT;
BEGIN
  RETURN ENTIER(x * 100 + 0.5)
END R;

PROCEDURE NewG(dir: INTEGER; n: INTEGER): L.Graph;
  VAR g: L.Graph; i, k: INTEGER;
BEGIN
  g := L.New(dir, 30, 10, 30);
  FOR i := 0 TO n - 1 DO k := L.AddNode(g, 40, 20) END;
  RETURN g
END NewG;

PROCEDURE E(g: L.Graph; a, b: INTEGER);
  VAR k: INTEGER;
BEGIN
  k := L.AddEdge(g, a, b, 1, 1, 0, 0, FALSE)
END E;

(* Whether boxes (x, y, w, h), centred, overlap by more than a hair *)
PROCEDURE Overlap(x1, y1, w1, h1, x2, y2, w2, h2: REAL): BOOLEAN;
BEGIN
  RETURN (ABS(x1 - x2) < (w1 + w2) / 2 - 0.01) & (ABS(y1 - y2) < (h1 + h2) / 2 - 0.01)
END Overlap;

(* Whether (x, y) is inside the box, by more than a hair *)
PROCEDURE Inside(x, y, cx, cy, w, h: REAL): BOOLEAN;
BEGIN
  RETURN (ABS(x - cx) < w / 2 - 0.5) & (ABS(y - cy) < h / 2 - 0.5)
END Inside;

(* The number of overlaps among g's nodes and edge labels, and of edges
   whose curve passes through another node *)
PROCEDURE Faults(g: L.Graph; VAR overlaps, crossings: INTEGER);
  VAR
    i, j, k, nb, t: INTEGER; a, c: L.Node; e, f: L.Edge; b: G.Points; p: G.Point;
    hit: BOOLEAN;
BEGIN
  overlaps := 0; crossings := 0;
  FOR i := 0 TO g.nReal - 1 DO
    a := g.node[i];
    FOR j := i + 1 TO g.nReal - 1 DO
      c := g.node[j];
      IF Overlap(a.x, a.y, a.w, a.h, c.x, c.y, c.w, c.h) THEN INC(overlaps) END
    END;
    FOR k := 0 TO g.nEdges - 1 DO
      e := g.edge[k];
      IF e.hasLabel & Overlap(a.x, a.y, a.w, a.h, e.labelX, e.labelY, e.labelW, e.labelH) THEN
        INC(overlaps)
      END
    END
  END;
  FOR k := 0 TO g.nEdges - 1 DO
    e := g.edge[k];
    FOR j := k + 1 TO g.nEdges - 1 DO
      f := g.edge[j];
      IF e.hasLabel & f.hasLabel
         & Overlap(e.labelX, e.labelY, e.labelW, e.labelH, f.labelX, f.labelY, f.labelW, f.labelH) THEN
        INC(overlaps)
      END
    END;
    G.Basis(e.points^, e.nPoints, b, nb);
    hit := FALSE;
    FOR i := 0 TO g.nReal - 1 DO
      IF (i # e.from) & (i # e.to) THEN
        a := g.node[i];
        j := 0;
        WHILE j + 3 < nb DO
          FOR t := 0 TO 20 DO
            G.OnCurve(b[j], b[j + 1], b[j + 2], b[j + 3], t / 20, p);
            IF Inside(p.x, p.y, a.x, a.y, a.w, a.h) THEN hit := TRUE END
          END;
          INC(j, 3)
        END
      END
    END;
    IF hit THEN INC(crossings) END
  END
END Faults;

PROCEDURE Chain;
  VAR g: L.Graph;
BEGIN
  g := NewG(L.TB, 3); E(g, 0, 1); E(g, 1, 2); L.Layout(g);
  Check("chain: ranks", g.node[0].rank * 100 + g.node[1].rank * 10 + g.node[2].rank, 24);
  Check("chain: straight", B((g.node[0].x = g.node[1].x) & (g.node[1].x = g.node[2].x)), 1);
  Check("chain: y of the second", R(g.node[1].y), R(10 + 20 + 30));
  Check("chain: width", R(g.width), 4000);
  Check("chain: height", R(g.height), R(3 * 20 + 2 * 30));
  Check("chain: edge points", g.edge[0].nPoints, 3);
  Check("chain: leaves the bottom", R(g.edge[0].points[0].y), 2000);
  Check("chain: reaches the top", R(g.edge[0].points[2].y), 5000)
END Chain;

PROCEDURE Diamond;
  VAR g: L.Graph; o, c: INTEGER;
BEGIN
  g := NewG(L.TB, 4); E(g, 0, 1); E(g, 0, 2); E(g, 1, 3); E(g, 2, 3); L.Layout(g);
  Check("diamond: ranks", g.node[0].rank * 1000 + g.node[1].rank * 100 + g.node[2].rank * 10 + g.node[3].rank, 224);
  Check("diamond: orders", g.node[1].order * 10 + g.node[2].order, 1);
  Check("diamond: top centred", R(g.node[0].x), R((g.node[1].x + g.node[2].x) / 2));
  Check("diamond: bottom centred", R(g.node[3].x), R(g.node[0].x));
  Check("diamond: apart", R(g.node[2].x - g.node[1].x), R(40 + 30));
  Faults(g, o, c);
  Check("diamond: no overlaps", o, 0); Check("diamond: no crossings", c, 0)
END Diamond;

PROCEDURE Cycle;
  VAR g: L.Graph; n, i: INTEGER;
BEGIN
  g := NewG(L.TB, 3); E(g, 0, 1); E(g, 1, 2); E(g, 2, 0); L.Layout(g);
  n := 0; FOR i := 0 TO 2 DO IF g.edge[i].reversed THEN INC(n) END END;
  Check("cycle: one edge turned", n, 1);
  Check("cycle: the closing one", B(g.edge[2].reversed), 1);
  Check("cycle: ranks", g.node[0].rank * 100 + g.node[1].rank * 10 + g.node[2].rank, 24);
  Check("cycle: turned edge starts at its tail",
    B(g.edge[2].points[0].y > g.edge[2].points[g.edge[2].nPoints - 1].y), 1)
END Cycle;

PROCEDURE LongEdge;
  VAR g: L.Graph; o, c, k: INTEGER;
BEGIN
  g := NewG(L.TB, 3); E(g, 0, 1); E(g, 1, 2); E(g, 0, 2); L.Layout(g);
  Check("long edge: dummies", g.edge[2].nChain, 3);
  Check("long edge: points", g.edge[2].nPoints, 5);
  Check("long edge: beside the middle node", B(g.node[g.edge[2].chain[1]].x # g.node[1].x), 1);
  Faults(g, o, c);
  Check("long edge: no overlaps", o, 0); Check("long edge: no crossings", c, 0);
  g := NewG(L.TB, 2); k := L.AddEdge(g, 0, 1, 2, 1, 0, 0, FALSE); L.Layout(g);
  Check("minlen 2: rank", g.node[1].rank, 4)
END LongEdge;

PROCEDURE Labels;
  VAR g: L.Graph; k, o, c: INTEGER;
BEGIN
  g := NewG(L.TB, 2); k := L.AddEdge(g, 0, 1, 1, 1, 60, 12, TRUE); L.Layout(g);
  Check("label: its dummy", B(g.edge[0].labelNode >= 0), 1);
  Check("label: at the middle rank", g.node[g.edge[0].labelNode].rank, 1);
  Check("label: between the nodes", R(g.edge[0].labelY), R((g.node[0].y + g.node[1].y) / 2));
  Check("label: widens the drawing", R(g.width), 6000);
  Faults(g, o, c); Check("label: no overlaps", o, 0)
END Labels;

PROCEDURE SelfLoop;
  VAR g: L.Graph; k: INTEGER; e: L.Edge;
BEGIN
  g := NewG(L.TB, 2); E(g, 0, 1); k := L.AddEdge(g, 0, 0, 1, 1, 30, 12, TRUE); L.Layout(g);
  e := g.edge[1];
  Check("self-loop: points", e.nPoints, 4);
  Check("self-loop: its dummy", g.node[e.chain[0]].kind, L.SelfDummy);
  Check("self-loop: to the right", B(e.points[2].x > g.node[0].x + 20), 1);
  Check("self-loop: from its node", R(e.points[0].x), R(g.node[0].x + 20));
  Check("self-loop: back to its node", R(e.points[0].x), R(e.points[3].x));
  Check("self-loop: left of its label", B(e.points[1].x <= e.labelX - 15), 1);
  Check("self-loop: label right of the node", B(e.labelX - 15 >= g.node[0].x + 20), 1);
  Check("self-loop: ranks", g.node[1].rank, 2)
END SelfLoop;

PROCEDURE Directions;
  VAR g: L.Graph;
BEGIN
  g := NewG(L.LR, 2); E(g, 0, 1); L.Layout(g);
  Check("LR: across", B((g.node[1].x > g.node[0].x) & (g.node[1].y = g.node[0].y)), 1);
  Check("LR: gap", R(g.node[1].x - g.node[0].x), R(40 + 30));
  Check("LR: height", R(g.height), 2000);
  g := NewG(L.RL, 2); E(g, 0, 1); L.Layout(g);
  Check("RL: back", B(g.node[1].x < g.node[0].x), 1);
  Check("RL: at 0", R(g.node[1].x), 2000);
  g := NewG(L.BT, 2); E(g, 0, 1); L.Layout(g);
  Check("BT: up", B(g.node[1].y < g.node[0].y), 1);
  Check("BT: edge goes up", B(g.edge[0].points[0].y > g.edge[0].points[2].y), 1)
END Directions;

PROCEDURE Components;
  VAR g: L.Graph;
BEGIN
  g := NewG(L.TB, 4); E(g, 0, 1); E(g, 2, 3); L.Layout(g);
  Check("two parts: both from rank 0", g.node[0].rank + g.node[2].rank, 0);
  Check("two parts: side by side", B(g.node[0].x # g.node[2].x), 1)
END Components;

PROCEDURE Crossing;
  VAR g: L.Graph; o, c: INTEGER;
BEGIN
  (* drawn in the given order, 0-3 and 1-2 would cross *)
  g := NewG(L.TB, 4); E(g, 0, 3); E(g, 1, 2); E(g, 0, 2); L.Layout(g);
  Check("crossing: ordered away", B((g.node[0].order < g.node[1].order) = (g.node[3].order < g.node[2].order)), 1);
  Faults(g, o, c); Check("crossing: no overlaps", o, 0)
END Crossing;

(* Dense graphs from a simple generator, in each direction, some edges
   labelled or long *)
PROCEDURE Dense;
  VAR g: L.Graph; seed: LONGINT; i, k, n, d, o, c, a, b, t: INTEGER;

  PROCEDURE Next(m: INTEGER): INTEGER;
  BEGIN
    seed := (seed * 1103 + 12345) MOD 65536;
    RETURN SHORT(seed DIV 16 MOD m)
  END Next;

BEGIN
  seed := 1; t := 0;
  FOR d := L.TB TO L.RL DO
    n := 12 + 6 * d;
    g := L.New(d, 30, 10, 30);
    FOR i := 0 TO n - 1 DO k := L.AddNode(g, 30 + Next(40), 15 + Next(30)) END;
    FOR i := 0 TO 2 * n - 1 DO
      a := Next(n); b := Next(n);
      k := L.AddEdge(g, a, b, 1 + Next(2), 1, 20 + Next(30), 10, Next(3) = 0)
    END;
    L.Layout(g);
    Faults(g, o, c);
    Check("dense graph: no overlaps", o, 0);
    INC(t, c)
  END;
  Out.String("# dense graphs: edges through other nodes: "); Out.Int(t, 0); Out.Ln
END Dense;

PROCEDURE Geometry;
  VAR p: ARRAY 3 OF G.Point; b, poly: G.Points; nb: INTEGER; x, y: REAL;
BEGIN
  G.Set(p[0], 0, 0); G.Set(p[1], 60, 0); G.Set(p[2], 60, 60);
  G.Basis(p, 3, b, nb);
  Check("basis: points", nb, 13);
  Check("basis: starts", R(b[0].x) + R(b[0].y), 0);
  Check("basis: ends", R(b[12].x) * 10000 + R(b[12].y), 6000 * 10000 + 6000);
  Check("basis: first piece", R(b[3].x), 1000);
  G.Basis(p, 2, b, nb);
  Check("basis: a line", nb, 4);
  G.RectIntersect(0, 0, 40, 20, 100, 0, x, y);
  Check("rect: side", R(x) * 10000 + R(y), 2000 * 10000);
  G.RectIntersect(0, 0, 40, 20, 0, -50, x, y);
  Check("rect: top", R(y), -1000);
  G.EllipseIntersect(0, 0, 10, 10, 30, 40, x, y);
  Check("circle", R(x) * 10000 + R(y), 600 * 10000 + 800);
  poly := G.NewPoints(4);
  G.Set(poly[0], 0, -10); G.Set(poly[1], 20, 0); G.Set(poly[2], 0, 10); G.Set(poly[3], -20, 0);
  G.PolygonIntersect(0, 0, poly^, 4, 100, 0, x, y);
  Check("diamond: right corner", R(x), 2000);
  G.PolygonIntersect(0, 0, poly^, 4, 1, 1, x, y);
  Check("diamond: a side", R(x) * 10000 + R(y), R(20 / 3) * 10000 + R(20 / 3))
END Geometry;

(* The user's diagram name, laid out in each direction *)
PROCEDURE Diagram(name: ARRAY OF CHAR);
  VAR
    text: PmIO.Text; len: LONGINT; sc: Lex.Scanner; g: F.Graph; l: FL.Layout;
    o, c, d: INTEGER; path, msg, msg2: ARRAY 128 OF CHAR;
BEGIN
  path := "../../../test/cases/"; Append(path, name); Append(path, ".mmd");
  FOR d := F.TB TO F.RL DO
    PmIO.ReadFile(path, text, len);
    sc := Lex.Open(text, len, path);
    F.Read(sc, g);
    g.dir := d;
    FL.Make(g, font, 10, l);
    Faults(l.g, o, c);
    COPY(name, msg);
    CASE d OF
      F.TB: Append(msg, " TB") | F.BT: Append(msg, " BT")
    | F.LR: Append(msg, " LR") | F.RL: Append(msg, " RL")
    END;
    COPY(msg, msg2);
    Append(msg, ": no overlaps"); Check(msg, o, 0);
    Append(msg2, ": no crossings"); Check(msg2, c, 0)
  END
END Diagram;

BEGIN
  failures := 0;
  Chain; Diamond; Cycle; LongEdge; Labels; SelfLoop; Directions; Components; Crossing;
  Dense; Geometry;
  M.SetPath("../../../test/fonts");
  Check("load TS", B(M.Load("TS", font)), 1);
  Diagram("gbh-overview"); Diagram("gbh-map"); Diagram("aftermath");
  Diagram("edges"); Diagram("shapes")
END PmLayoutTest.
