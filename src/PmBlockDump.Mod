MODULE PmBlockDump;
(* PmBlockDump: a block diagram's model, PmBlock's, written as text, one
   line for each configuration value, class definition, the diagram's
   options, each block, indented as the tree is, and each edge, for the
   tests (-t dump); its layout is written by PmDrawDump *)

IMPORT PmIO, Y := PmYaml, L := PmLex, F := PmFlow, B := PmBlock, X := PmXy, D := PmDump;

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

PROCEDURE Props(name: ARRAY OF CHAR; p: F.Prop);
BEGIN
  IF p # NIL THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteString("=[");
    WHILE p # NIL DO
      D.Quoted(p.name); PmIO.WriteChar(":"); D.Quoted(p.value);
      p := p.next;
      IF p # NIL THEN PmIO.WriteChar(" ") END
    END;
    PmIO.WriteChar("]")
  END
END Props;

PROCEDURE Mark(name: ARRAY OF CHAR; m: INTEGER);
BEGIN
  IF m # F.None THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
    IF m = F.Arrow THEN PmIO.WriteString("arrow")
    ELSIF m = F.CircleEnd THEN PmIO.WriteString("circle")
    ELSIF m = F.Cross THEN PmIO.WriteString("cross")
    END
  END
END Mark;

PROCEDURE Block(b: B.Block; depth: INTEGER);
  VAR c: B.Block; k: INTEGER; s: ARRAY 32 OF CHAR; n: F.Name;
BEGIN
  FOR k := 1 TO depth DO PmIO.WriteString("  ") END;
  B.TypeName(b.type, s); PmIO.WriteString(s);
  PmIO.WriteString(" id="); D.Quoted(b.id);
  IF (b.type # B.Space) & (b.type # B.Composite) OR (b.label.n > 0) & (b.type = B.Composite) THEN
    D.Label("label", b.label)
  END;
  IF b.wic # 1 THEN Int("width", b.wic) END;
  IF b.type = B.Composite THEN
    IF b.columns < 0 THEN PmIO.WriteString(" columns=auto") ELSE Int("columns", b.columns) END
  END;
  IF b.type = B.BlockArrow THEN
    PmIO.WriteString(" dirs=");
    IF B.Right IN b.dirs THEN PmIO.WriteChar("r") END;
    IF B.Left IN b.dirs THEN PmIO.WriteChar("l") END;
    IF B.Up IN b.dirs THEN PmIO.WriteChar("u") END;
    IF B.Down IN b.dirs THEN PmIO.WriteChar("d") END
  END;
  n := b.classes;
  IF n # NIL THEN
    PmIO.WriteString(" classes=");
    WHILE n # NIL DO D.Quoted(n.name); n := n.next; IF n # NIL THEN PmIO.WriteChar(",") END END
  END;
  Props("style", b.style);
  PmIO.WriteLn;
  c := b.children;
  WHILE c # NIL DO Block(c, depth + 1); c := c.next END
END Block;

(* Writes d's model *)
PROCEDURE Write*(d: B.Diagram);
  VAR q: Y.Pair; c: B.Block; cd: F.ClassDef; e: B.Edge;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  cd := d.g.classDefs;
  WHILE cd # NIL DO
    PmIO.WriteString("classDef "); D.Quoted(cd.name); Props("props", cd.props); PmIO.WriteLn;
    cd := cd.next
  END;
  PmIO.WriteString("block");
  Num("padding", d.padding); Int("blocks", d.nBlocks); Int("edges", d.nEdges);
  IF d.root.columns < 0 THEN PmIO.WriteString(" columns=auto") ELSE Int("columns", d.root.columns) END;
  PmIO.WriteLn;
  c := d.root.children;
  WHILE c # NIL DO Block(c, 1); c := c.next END;
  e := d.edges;
  WHILE e # NIL DO
    PmIO.WriteString("edge id="); D.Quoted(e.id);
    PmIO.WriteString(" from="); D.Quoted(e.from.id);
    PmIO.WriteString(" to="); D.Quoted(e.to.id);
    Mark("start", e.startMark); Mark("end", e.endMark);
    IF e.thick THEN PmIO.WriteString(" thick") END;
    IF e.dotted THEN PmIO.WriteString(" dotted") END;
    IF e.label # NIL THEN D.Label("label", e.label) END;
    PmIO.WriteLn;
    e := e.next
  END
END Write;

END PmBlockDump.
