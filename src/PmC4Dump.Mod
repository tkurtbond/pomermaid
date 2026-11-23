MODULE PmC4Dump;
(* PmC4Dump: a C4 diagram's model, PmC4's, written as text, one line for
   each configuration value, the diagram, each boundary, element and
   relationship with its values, for the tests (-t dump); its layout is
   written by PmDrawDump. A value set by UpdateElementStyle in a text is
   written "key:raw". *)

IMPORT PmIO, Y := PmYaml, C := PmC4, D := PmDump, L := PmLex;

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

PROCEDURE Attrs(a: C.Attr);
BEGIN
  WHILE a # NIL DO
    PmIO.WriteChar(" "); PmIO.WriteString(a.key^);
    IF a.raw THEN PmIO.WriteString(":raw") END;
    PmIO.WriteChar("="); D.Quoted(a.value);
    a := a.next
  END
END Attrs;

(* Writes d's model *)
PROCEDURE Write*(d: C.Diagram);
  VAR q: Y.Pair; b: C.Boundary; s: C.Shape; r: C.Rel;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("c4 type="); D.Quoted(d.c4Type);
  Int("shapeInRow", d.shapeInRow); Int("boundaryInRow", d.boundaryInRow);
  Opt("title", d.title); Opt("accDescr", d.accDescr);
  PmIO.WriteLn;
  b := d.boundaries;
  WHILE b # NIL DO
    PmIO.WriteString("boundary"); Int("index", b.index);
    PmIO.WriteString(" alias="); D.Quoted(b.alias);
    PmIO.WriteString(" parent="); D.Quoted(b.parent);
    Attrs(b.attrs); PmIO.WriteLn;
    b := b.next
  END;
  s := d.shapes;
  WHILE s # NIL DO
    PmIO.WriteString("shape"); Int("index", s.index);
    PmIO.WriteString(" type="); PmIO.WriteString(s.type^);
    PmIO.WriteString(" alias="); D.Quoted(s.alias);
    PmIO.WriteString(" parent="); D.Quoted(s.parent);
    Attrs(s.attrs); PmIO.WriteLn;
    s := s.next
  END;
  r := d.rels;
  WHILE r # NIL DO
    PmIO.WriteString("rel"); Int("index", r.index);
    PmIO.WriteString(" kind="); PmIO.WriteString(r.kind^);
    IF r.kindSet THEN PmIO.WriteString(" kindSet") END;
    PmIO.WriteString(" from="); D.Quoted(r.from);
    PmIO.WriteString(" to="); D.Quoted(r.to);
    Attrs(r.attrs); PmIO.WriteLn;
    r := r.next
  END
END Write;

END PmC4Dump.
