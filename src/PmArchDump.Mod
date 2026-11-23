MODULE PmArchDump;
(* PmArchDump: an architecture diagram's model, PmArch's, written as
   text, one line for each configuration value, the diagram's options,
   each group, service and junction (with its grid and place on it),
   edge and alignment, for the tests (-t dump); its layout is written
   by PmDrawDump *)

IMPORT PmIO, Y := PmYaml, A := PmArch, X := PmXy, D := PmDump, L := PmLex;

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

PROCEDURE Flag(name: ARRAY OF CHAR; b: BOOLEAN);
BEGIN
  IF b THEN PmIO.WriteChar(" "); PmIO.WriteString(name) END
END Flag;

(* Writes d's model *)
PROCEDURE Write*(d: A.Diagram);
  VAR q: Y.Pair; gr: A.Group; n: A.Node; e: A.Edge; a: A.Align; k: LONGINT;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("architecture");
  Num("padding", d.padding); Num("iconSize", d.iconSize); Num("fontSize", d.fontSize);
  Int("groups", d.nGroups); Int("nodes", d.nNodes); Int("edges", d.nEdges); Int("maps", d.nMaps);
  Opt("title", d.title); Opt("accTitle", d.accTitle); Opt("accDescr", d.accDescr);
  PmIO.WriteLn;
  gr := d.groups;
  WHILE gr # NIL DO
    PmIO.WriteString("group"); Int("index", gr.index); Int("depth", gr.depth);
    PmIO.WriteString(" id="); D.Quoted(gr.id);
    Opt("icon", gr.icon);
    IF gr.title # NIL THEN D.Label("title", gr.title) END;
    Opt("in", gr.in);
    PmIO.WriteLn;
    gr := gr.next
  END;
  n := d.nodes;
  WHILE n # NIL DO
    IF n.junction THEN PmIO.WriteString("junction") ELSE PmIO.WriteString("service") END;
    Int("index", n.index);
    PmIO.WriteString(" id="); D.Quoted(n.id);
    Opt("icon", n.icon);
    IF n.iconLabel # NIL THEN D.Label("iconText", n.iconLabel) END;
    IF n.title # NIL THEN D.Label("title", n.title) END;
    Opt("in", n.in);
    Int("map", n.map); Int("x", n.gx); Int("y", n.gy);
    PmIO.WriteLn;
    n := n.next
  END;
  e := d.edges;
  WHILE e # NIL DO
    PmIO.WriteString("edge lhs="); D.Quoted(e.lhs.id);
    PmIO.WriteString(" lhsDir="); PmIO.WriteChar(e.lhsDir);
    Flag("lhsInto", e.lhsInto); Flag("lhsGroup", e.lhsGroup);
    PmIO.WriteString(" rhs="); D.Quoted(e.rhs.id);
    PmIO.WriteString(" rhsDir="); PmIO.WriteChar(e.rhsDir);
    Flag("rhsInto", e.rhsInto); Flag("rhsGroup", e.rhsGroup);
    IF e.title # NIL THEN D.Label("title", e.title) END;
    PmIO.WriteLn;
    e := e.next
  END;
  a := d.aligns;
  WHILE a # NIL DO
    PmIO.WriteString("align");
    IF a.column THEN PmIO.WriteString(" column") ELSE PmIO.WriteString(" row") END;
    FOR k := 0 TO a.n - 1 DO PmIO.WriteChar(" "); D.Quoted(a.members[k].id) END;
    PmIO.WriteLn;
    a := a.next
  END
END Write;

END PmArchDump.
