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

CONST
  Sub = 60; Collapsed = 61; (* pomermaid.mp's pm_sub and pm_collapsed *)

TYPE
  Styles = POINTER TO ARRAY OF S.Style;
  Edges = POINTER TO ARRAY OF F.Edge;
  Nodes = POINTER TO ARRAY OF F.Node;

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
  VAR line: F.Line; i, end: LONGINT; ch: CHAR; st: INTEGER;
BEGIN
  W('"');
  IF lab # NIL THEN
    line := lab.lines;
    WHILE line # NIL DO
      i := 0; end := Lx.Length(line.text^); st := 0;
      IF line.underline THEN W("\underbar{") END;
      WHILE i < end DO
        ch := line.text[i];
        IF (line.style # NIL) & (line.style[i] # st) THEN
          IF st # 0 THEN W("}") END;
          st := line.style[i];
          IF st = F.Bold THEN W("{\bf ") ELSIF st = F.Italic THEN W("{\it ")
          ELSIF st # 0 THEN W("{\bi ")
          END
        END;
        CASE ch OF
          '"', "#", "$", "%", "&", "\", "^", "_", "{", "}", "~":
            W("{\char"); I(ORD(ch)); W("}")
        ELSE
          IF ch >= " " THEN PmIO.WriteChar(ch) END
        END;
        INC(i)
      END;
      IF st # 0 THEN W("}") END;
      IF line.underline THEN W("}") END;
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

(* s as a MetaPost string, a line of plain text: "" for NIL *)
PROCEDURE Cell(s: F.Str);
BEGIN
  IF s = NIL THEN W('""') ELSE Label(F.PlainLabel(s)) END
END Cell;

(* entity n, node v, styled st: its rows' colours and its attributes *)
PROCEDURE Er(v: INTEGER; n: F.Node; VAR st: S.Style);
  VAR odd, even: S.Style; a: F.Attr; k: INTEGER;
BEGIN
  S.RowStyles(st, odd, even);
  k := 0; a := n.attrs;
  WHILE a # NIL DO INC(k); a := a.next END;
  PmIO.WriteLn; W("pm_er("); I(v); C; I(k); C; I(odd.fill); C; I(even.fill); W(");");
  k := 0; a := n.attrs;
  WHILE a # NIL DO
    PmIO.WriteLn; W("pm_erow("); I(v); C; I(k); C; Cell(a.type); C; Cell(a.name); C;
    Cell(a.keys); C; Cell(a.comment); W(");");
    INC(k); a := a.next
  END
END Er;

(* Writes the layout of scope sc as calls of the macros, from pm_begin
   to pm_end, or, for an isolated subgraph's, pm_endsub *)
PROCEDURE Block(l: FL.Layout; sc: FL.Scope; maxW: REAL; VAR nst, est, cst: Styles;
  nodes: Nodes; edges: Edges);
  VAR lg: L.Graph; e: F.Edge; ln: L.Node; le: L.Edge; v, k, j, i: INTEGER;
    lc: L.Cluster;
BEGIN
  lg := sc.g;
  IF sc.cluster >= 0 THEN maxW := 0 END;
  W("pm_begin("); I(lg.dir); C; R(l.size); C; R(maxW); C; I(lg.nNodes); C;
  I(lg.nEdges); C; I(lg.nRanks); C; I(lg.nClusters); W(");"); PmIO.WriteLn;
  IF sc.cluster >= 0 THEN
    W("pm_ranksep := "); R(lg.ranksep * FL.MermaidSize / l.size / 2); W(";"); PmIO.WriteLn
  END;
  FOR k := 0 TO lg.nClusters - 1 DO
    lc := lg.cluster[k]; i := sc.clus[k];
    W("pm_cluster("); I(k); C; I(lc.parent); C; I(lc.minRank); C; I(lc.maxRank); C;
    Label(l.clusterLabel[i]); W(");"); PmIO.WriteLn;
    W("pm_cstyle("); I(k); C; Style(cst[i], TRUE); W(");"); PmIO.WriteLn;
    IF cst[i].inner # S.NoColour THEN
      W("pm_cinner("); I(k); C; I(cst[i].inner); W(");"); PmIO.WriteLn
    END
  END;
  (* the nodes, then the dummies and borders *)
  FOR v := 0 TO lg.nNodes - 1 DO
    ln := lg.node[v];
    W("pm_node("); I(v); C; I(ln.kind); C; I(ln.rank); C; I(ln.order); C;
    IF (lg.dir = L.LR) OR (lg.dir = L.RL) THEN R(ln.y) ELSE R(ln.x) END; C;
    IF ln.kind = L.Real THEN
      i := sc.node[v];
      IF i >= 0 THEN
        I(nodes[i].shape); C; I(ln.edge); C; Label(l.nodeLabel[i]); W(");");
        PmIO.WriteLn;
        W("pm_style("); I(v); C; Style(nst[i], TRUE); W(");");
        IF nodes[i].shape = F.StateDesc THEN
          PmIO.WriteLn; W("pm_lines("); I(v); C; I(l.nodeLabel[i].n); W(");")
        ELSIF (nodes[i].shape = F.ClassBox) OR (nodes[i].shape = F.ReqBox) THEN
          PmIO.WriteLn; W("pm_class("); I(v); C; Label(nodes[i].annotation); C;
          Label(nodes[i].members); C; Label(nodes[i].methods); W(");")
        ELSIF (nodes[i].shape = F.ErBox) & (nodes[i].attrs # NIL) THEN
          Er(v, nodes[i], nst[i])
        END
      ELSIF l.isolated[-1 - i] THEN
        I(Sub); C; I(ln.edge); W(', "");'); PmIO.WriteLn;
        W("pm_subnode("); I(v); C; I(-1 - i); W(");")
      ELSE
        I(Collapsed); C; I(ln.edge); C; Label(l.clusterLabel[-1 - i]); W(");");
        PmIO.WriteLn;
        W("pm_style("); I(v); C; Style(cst[-1 - i], TRUE); W(");")
      END
    ELSIF (ln.kind = L.LeftBorder) OR (ln.kind = L.RightBorder) THEN
      W("0, "); I(ln.cluster); W(', "");')
    ELSE
      W("0, "); I(ln.edge); W(', "");')
    END;
    PmIO.WriteLn
  END;
  FOR k := 0 TO lg.nEdges - 1 DO
    j := sc.edge[k]; e := edges[j]; le := lg.edge[k];
    W("pm_edge("); I(k); C; I(le.from); C; I(le.to); C; I(le.fromC); C; I(le.toC); C;
    IF le.reversed THEN W("1") ELSE W("0") END; C;
    I(le.labelNode); C; I(e.head); C; I(e.tail); C;
    IF e.line = F.Invisible THEN W("0") ELSE W("1") END; C;
    Style(est[j], FALSE); C;
    IF le.hasLabel THEN Label(l.edgeLabel[j]) ELSE W('""') END;
    W(")(");
    FOR i := 0 TO le.nChain - 1 DO
      IF i > 0 THEN C END;
      I(le.chain[i])
    END;
    W(");"); PmIO.WriteLn;
    IF (e.startLabel # NIL) OR (e.endLabel # NIL) THEN
      W("pm_cardinality("); I(k); C; Label(e.startLabel); C; Label(e.endLabel); W(");");
      PmIO.WriteLn
    END;
    IF e.curve # F.Basis THEN
      W("pm_curve("); I(k); C; I(e.curve); W(");"); PmIO.WriteLn
    END
  END;
  IF sc.cluster >= 0 THEN
    W("pm_endsub("); I(sc.cluster); W(");"); PmIO.WriteLn
  ELSE
    IF (l.title # NIL) & (l.title.n > 0) THEN
      W("pm_title := "); Label(l.title); W("; pm_titlec := "); I(S.TitleColour()); W(";");
      PmIO.WriteLn
    END;
    W("pm_end;"); PmIO.WriteLn
  END
END Block;

(* Writes l's flowchart as a \startMPcode block; wider than maxW points
   (0 for no limit), it is scaled down to maxW. With input, the macros
   are input, not copied. Each isolated subgraph's layout comes first,
   the inner first, each kept as a picture for a node of the next. *)
PROCEDURE Write*(l: FL.Layout; maxW: REAL; input: BOOLEAN);
  VAR
    g: F.Graph; n: F.Node; e: F.Edge; k: INTEGER; rgb: LONGINT;
    nst, est, cst: Styles; nodes: Nodes; edges: Edges; cn: POINTER TO ARRAY OF F.Node; sc: FL.Scope;
BEGIN
  g := l.graph;
  S.Reset(g, l.size / 16);
  NEW(nst, g.nNodes + 1); NEW(est, g.nEdges + 1); NEW(edges, g.nEdges + 1);
  NEW(nodes, g.nNodes + 1);
  n := g.nodes;
  WHILE n # NIL DO S.NodeStyle(g, n, nst[n.index]); nodes[n.index] := n; n := n.next END;
  e := g.edges;
  WHILE e # NIL DO S.EdgeStyle(g, e, est[e.index]); edges[e.index] := e; e := e.next END;
  NEW(cst, g.nClusters + 1); NEW(cn, g.nClusters + 1);
  FOR k := 0 TO g.nClusters - 1 DO cn[k] := NIL END;
  n := g.nodes;
  WHILE n # NIL DO
    IF l.stands[n.index] >= 0 THEN cn[l.stands[n.index]] := n END;
    n := n.next
  END;
  FOR k := 0 TO g.nClusters - 1 DO S.ClusterStyle(g, k, cn[k], cst[k]) END;
  W("\startMPcode"); PmIO.WriteLn;
  IF input THEN W("input pomermaid ;"); PmIO.WriteLn ELSE PmMpMacros.Write END;
  FOR k := 0 TO S.nColours - 1 DO
    rgb := S.Rgb(k);
    W("pm_colour("); I(k); C; PmIO.WriteReal(rgb DIV 10000H / 255, 4); C;
    PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); C;
    PmIO.WriteReal(rgb MOD 100H / 255, 4); W(");"); PmIO.WriteLn
  END;
  IF ~S.DefaultLabelBackground() THEN
    rgb := S.LabelBackgroundRgb();
    IF rgb < 0 THEN W("pm_labelbox := false;")
    ELSE
      W("pm_labelback := ("); PmIO.WriteReal(rgb DIV 10000H / 255, 4); C;
      PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); C;
      PmIO.WriteReal(rgb MOD 100H / 255, 4); W(");")
    END;
    PmIO.WriteLn
  END;
  sc := l.scopes;
  WHILE sc # NIL DO Block(l, sc, maxW, nst, est, cst, nodes, edges); sc := sc.next END;
  W("\stopMPcode"); PmIO.WriteLn
END Write;

END PmMp.
