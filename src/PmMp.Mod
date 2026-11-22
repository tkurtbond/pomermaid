MODULE PmMp;
(* PmMp: a flowchart written in MetaPost, for ConTeXt: a \startMPcode
   block that the macros of mp/pomermaid.mp lay out and draw.

   pomermaid lays the flowchart out, its labels measured in a groff font
   at a size, the estimate; this writes the topology of that layout as
   calls of the macros (see mp/pomermaid.mp): each node of the layout,
   dummies too, with its rank, its place in its rank, where the estimate
   put it along the rank, its shape and label; each edge with its nodes
   and dummies; each subgraph, a cluster of the layout, with its ranks
   and its title, its borders as nodes of the layout; the styles, as
   PmStyle's. The macros set the labels in
   the document's font and do the rest, so the drawing fits the
   document's labels, not the estimate's.

   The macros are copied into the block (PmMpMacros, made from
   mp/pomermaid.mp), or, with input set, "input pomermaid ;" is written,
   for a document that has pomermaid.mp where ConTeXt finds it.

   Labels are written for ConTeXt: their lines joined with \\, the
   characters TeX treats specially, and '"', which would end a MetaPost
   string, as {\charN}; other characters, UTF-8 included, as they are. *)

IMPORT PmIO, F := PmFlow, L := PmLayout, FL := PmFlowLayout, Lx := PmLex,
  S := PmStyle, PmMpMacros;

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

PROCEDURE I(n: LONGINT);
BEGIN
  PmIO.WriteInt(n)
END I;

PROCEDURE R(x: REAL);
BEGIN
  PmIO.WriteReal(x, 3)
END R;

PROCEDURE C;
BEGIN
  W(", ")
END C;

(* lab as a MetaPost string of ConTeXt text: "" for none *)
PROCEDURE Label(lab: F.Label);
  VAR line: F.Line; i, end: LONGINT; ch: CHAR;
BEGIN
  W('"');
  IF lab # NIL THEN
    line := lab.lines;
    WHILE line # NIL DO
      i := 0; end := Lx.Length(line.text^);
      WHILE i < end DO
        ch := line.text[i];
        CASE ch OF
          '"', "#", "$", "%", "&", "\", "^", "_", "{", "}", "~":
            W("{\char"); I(ORD(ch)); W("}")
        ELSE
          IF ch >= " " THEN PmIO.WriteChar(ch) END
        END;
        INC(i)
      END;
      line := line.next;
      IF line # NIL THEN W("\\") END
    END
  END;
  W('"')
END Label;

(* The style st: its colours, line width and dashes *)
PROCEDURE Style(VAR st: S.Style; node: BOOLEAN);
BEGIN
  IF node THEN I(st.fill); C END;
  I(st.line); C; I(st.text); C; R(st.width); C; R(st.dash)
END Style;

(* Writes l's flowchart as a \startMPcode block; wider than maxW points
   (0 for no limit), it is scaled down to maxW. With input, the macros
   are input, not copied. *)
PROCEDURE Write*(l: FL.Layout; maxW: REAL; input: BOOLEAN);
  VAR
    g: F.Graph; lg: L.Graph; n: F.Node; e: F.Edge; ln: L.Node; le: L.Edge;
    v, k, j: INTEGER; rgb: LONGINT; nst, est, cst: POINTER TO ARRAY OF S.Style;
    cn: POINTER TO ARRAY OF F.Node; lc: L.Cluster;
BEGIN
  g := l.graph; lg := l.g;
  S.Reset(l.size / 16);
  NEW(nst, g.nNodes + 1); NEW(est, g.nEdges + 1);
  n := g.nodes;
  WHILE n # NIL DO S.NodeStyle(g, n, nst[n.index]); n := n.next END;
  e := g.edges;
  WHILE e # NIL DO S.EdgeStyle(e, est[e.index]); e := e.next END;
  NEW(cst, g.nClusters + 1); NEW(cn, g.nClusters + 1);
  FOR k := 0 TO g.nClusters - 1 DO cn[k] := NIL END;
  n := g.nodes;
  WHILE n # NIL DO
    IF l.stands[n.index] >= 0 THEN cn[l.stands[n.index]] := n END;
    n := n.next
  END;
  FOR k := 0 TO g.nClusters - 1 DO S.ClusterStyle(g, cn[k], cst[k]) END;
  W("\startMPcode"); PmIO.WriteLn;
  IF input THEN W("input pomermaid ;"); PmIO.WriteLn ELSE PmMpMacros.Write END;
  W("pm_begin("); I(lg.dir); C; R(l.size); C; R(maxW); C; I(lg.nNodes); C;
  I(lg.nEdges); C; I(lg.nRanks); C; I(lg.nClusters); W(");"); PmIO.WriteLn;
  FOR k := 0 TO S.nColours - 1 DO
    rgb := S.Rgb(k);
    W("pm_colour("); I(k); C; PmIO.WriteReal(rgb DIV 10000H / 255, 4); C;
    PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); C;
    PmIO.WriteReal(rgb MOD 100H / 255, 4); W(");"); PmIO.WriteLn
  END;
  FOR k := 0 TO lg.nClusters - 1 DO
    lc := lg.cluster[k];
    W("pm_cluster("); I(k); C; I(lc.parent); C; I(lc.minRank); C; I(lc.maxRank); C;
    Label(l.clusterLabel[k]); W(");"); PmIO.WriteLn;
    W("pm_cstyle("); I(k); C; Style(cst[k], TRUE); W(");"); PmIO.WriteLn
  END;
  (* the nodes, then the dummies and borders *)
  n := g.nodes;
  FOR v := 0 TO lg.nNodes - 1 DO
    ln := lg.node[v];
    W("pm_node("); I(v); C; I(ln.kind); C; I(ln.rank); C; I(ln.order); C;
    IF (lg.dir = L.LR) OR (lg.dir = L.RL) THEN R(ln.y) ELSE R(ln.x) END; C;
    IF ln.kind = L.Real THEN
      WHILE n.index # v DO n := n.next END;
      I(n.shape); C; I(ln.edge); C; Label(l.nodeLabel[v]); W(");"); PmIO.WriteLn;
      W("pm_style("); I(v); C; Style(nst[v], TRUE); W(");")
    ELSIF (ln.kind = L.LeftBorder) OR (ln.kind = L.RightBorder) THEN
      W("0, "); I(ln.cluster); W(', "");')
    ELSE
      W("0, "); I(ln.edge); W(', "");')
    END;
    PmIO.WriteLn
  END;
  e := g.edges;
  WHILE e # NIL DO
    j := e.index; le := lg.edge[j];
    W("pm_edge("); I(j); C; I(le.from); C; I(le.to); C; I(le.fromC); C; I(le.toC); C;
    IF le.reversed THEN W("1") ELSE W("0") END; C;
    I(le.labelNode); C; I(e.head); C; I(e.tail); C;
    IF e.line = F.Invisible THEN W("0") ELSE W("1") END; C;
    Style(est[j], FALSE); C;
    IF le.hasLabel THEN Label(l.edgeLabel[j]) ELSE W('""') END;
    W(")(");
    FOR k := 0 TO le.nChain - 1 DO
      IF k > 0 THEN C END;
      I(le.chain[k])
    END;
    W(");"); PmIO.WriteLn;
    e := e.next
  END;
  W("pm_end;"); PmIO.WriteLn;
  W("\stopMPcode"); PmIO.WriteLn
END Write;

END PmMp.
