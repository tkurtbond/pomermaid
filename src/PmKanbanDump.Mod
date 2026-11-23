MODULE PmKanbanDump;
(* PmKanbanDump: a kanban board's model, PmKanban's, written as text,
   one line for each configuration value, the board's options and each
   node, a section or an item, for the tests (-t dump); its layout is
   written by PmDrawDump *)

IMPORT PmIO, Y := PmYaml, K := PmKanban, X := PmXy, D := PmDump, L := PmLex;

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

(* Writes d's model *)
PROCEDURE Write*(d: K.Diagram);
  VAR q: Y.Pair; n: K.Node;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("kanban");
  Num("sectionWidth", d.sectionWidth); Num("padding", d.padding);
  Opt("ticketBaseUrl", d.ticketBaseUrl);
  Int("sections", d.nSections); Int("nodes", d.nNodes);
  PmIO.WriteLn;
  n := d.nodes;
  WHILE n # NIL DO
    IF n.section = NIL THEN PmIO.WriteString("section") ELSE PmIO.WriteString("  item") END;
    Int("index", n.index); Int("level", n.level); Int("shape", n.shape);
    Num("padding", n.padding);
    PmIO.WriteString(" id="); D.Quoted(n.id);
    IF n.section # NIL THEN Int("section", n.section.index) END;
    D.Label("label", n.label);
    Opt("ticket", n.ticket); Opt("assigned", n.assigned); Opt("priority", n.priority);
    Opt("icon", n.icon); Opt("class", n.class);
    PmIO.WriteLn;
    n := n.next
  END
END Write;

END PmKanbanDump.
