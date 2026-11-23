MODULE PmMindmapDump;
(* PmMindmapDump: a mindmap's model, PmMindmap's, written as text, one
   line for each configuration value, the diagram's options and each
   node, in the order read, for the tests (-t dump); its layout is
   written by PmDrawDump *)

IMPORT PmIO, Y := PmYaml, H := PmMindmap, X := PmXy, D := PmDump;

PROCEDURE Num(name: ARRAY OF CHAR; x: LONGREAL);
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  X.JsNumber(x, s);
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteString(s)
END Num;

PROCEDURE Int(name: ARRAY OF CHAR; n: LONGINT);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteInt(n)
END Int;

PROCEDURE Shape(s: INTEGER);
BEGIN
  PmIO.WriteString(" shape=");
  CASE s OF
    H.Default: PmIO.WriteString("default")
  | H.Rounded: PmIO.WriteString("rounded")
  | H.Rect: PmIO.WriteString("rect")
  | H.Circle: PmIO.WriteString("circle")
  | H.Cloud: PmIO.WriteString("cloud")
  | H.Bang: PmIO.WriteString("bang")
  | H.Hexagon: PmIO.WriteString("hexagon")
  END
END Shape;

PROCEDURE Node(n: H.Node);
  VAR c: H.Node;
BEGIN
  PmIO.WriteString("node "); PmIO.WriteInt(n.index);
  IF n.parent # NIL THEN Int("parent", n.parent.index) END;
  Int("level", n.level); Int("depth", n.depth); Int("section", n.section);
  Shape(n.shape);
  PmIO.WriteString(" id="); D.Quoted(n.id);
  D.Label("label", n.label);
  IF n.icon # NIL THEN PmIO.WriteString(" icon="); D.Quoted(n.icon) END;
  IF n.class # NIL THEN PmIO.WriteString(" class="); D.Quoted(n.class) END;
  PmIO.WriteLn;
  c := n.children;
  WHILE c # NIL DO Node(c); c := c.next END
END Node;

(* Writes d's model *)
PROCEDURE Write*(d: H.Diagram);
  VAR q: Y.Pair;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("mindmap");
  Num("padding", d.padding); Num("maxNodeWidth", d.maxNodeWidth);
  IF d.byDepth THEN PmIO.WriteString(" colorBy=depth") ELSE PmIO.WriteString(" colorBy=branch") END;
  Int("nodes", d.nNodes);
  PmIO.WriteLn;
  Node(d.root)
END Write;

END PmMindmapDump.
