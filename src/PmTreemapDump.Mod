MODULE PmTreemapDump;
(* PmTreemapDump: a treemap's model, PmTreemap's, written as text, one
   line for each configuration value, the diagram's options and each
   section and leaf, as a tree, for the tests (-t dump); its layout is
   written by PmDrawDump *)

IMPORT PmIO, Y := PmYaml, L := PmLex, T := PmTreemap, X := PmXy, D := PmDump;

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

PROCEDURE Opt(name: ARRAY OF CHAR; s: L.Str);
BEGIN
  IF s # NIL THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); D.Quoted(s)
  END
END Opt;

PROCEDURE Node(d: T.Diagram; n: T.Node);
  VAR c: T.Node; s: ARRAY 4400 OF CHAR;
BEGIN
  IF n.leaf THEN PmIO.WriteString("leaf ") ELSE PmIO.WriteString("section ") END;
  PmIO.WriteInt(n.index);
  IF n.parent # NIL THEN Int("parent", n.parent.index) END;
  Int("level", n.level);
  PmIO.WriteString(" name="); D.Quoted(n.name);
  D.Label("label", n.label);
  IF n.leaf THEN
    Num("value", n.value);
    T.Format(d, n.value, s); PmIO.WriteString(" shown="); PmIO.WriteChar('"');
    PmIO.WriteString(s); PmIO.WriteChar('"')
  END;
  Opt("class", n.class); Opt("fill", n.fill); Opt("stroke", n.stroke);
  Opt("strokeWidth", n.strokeWidth); Opt("color", n.color);
  PmIO.WriteLn;
  c := n.children;
  WHILE c # NIL DO Node(d, c); c := c.next END
END Node;

(* Writes d's model *)
PROCEDURE Write*(d: T.Diagram);
  VAR q: Y.Pair; c: T.Node;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("treemap");
  Num("width", d.width); Num("height", d.height); Num("padding", d.padding);
  Num("diagramPadding", d.diagramPadding);
  IF d.showValues THEN PmIO.WriteString(" showValues=true") ELSE PmIO.WriteString(" showValues=false") END;
  PmIO.WriteString(" valueFormat="); D.Quoted(d.valueFormat);
  Int("nodes", d.nNodes);
  D.Label("title", d.g.title);
  PmIO.WriteLn;
  c := d.root.children;
  WHILE c # NIL DO Node(d, c); c := c.next END
END Write;

END PmTreemapDump.
