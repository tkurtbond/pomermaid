MODULE PmDump;
(* PmDump: the flowchart model written out as text, one line per node,
   edge, subgraph and class definition, for the tests (-t dump). The
   lines come in the model's order, so the same input always gives the
   same output. *)

IMPORT PmIO, F := PmFlow;

PROCEDURE Quoted(s: F.Str);
  VAR i: LONGINT;
BEGIN
  PmIO.WriteChar(22X);
  IF s # NIL THEN
    i := 0;
    WHILE s[i] # 0X DO
      IF (s[i] = 22X) OR (s[i] = "\") THEN PmIO.WriteChar("\") END;
      PmIO.WriteChar(s[i]); INC(i)
    END
  END;
  PmIO.WriteChar(22X)
END Quoted;

PROCEDURE Label(name: ARRAY OF CHAR; lab: F.Label);
  VAR l: F.Line;
BEGIN
  IF lab # NIL THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
    IF lab.markdown THEN PmIO.WriteString("md:") END;
    l := lab.lines;
    WHILE l # NIL DO
      Quoted(l.text);
      IF l.next # NIL THEN PmIO.WriteChar("/") END;
      l := l.next
    END
  END
END Label;

PROCEDURE Props(name: ARRAY OF CHAR; p: F.Prop);
BEGIN
  IF p # NIL THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
    WHILE p # NIL DO
      PmIO.WriteString(p.name^); PmIO.WriteChar(":"); Quoted(p.value);
      IF p.next # NIL THEN PmIO.WriteChar(",") END;
      p := p.next
    END
  END
END Props;

PROCEDURE Dir(d: INTEGER);
BEGIN
  CASE d OF
    F.TB: PmIO.WriteString("TB")
  | F.BT: PmIO.WriteString("BT")
  | F.LR: PmIO.WriteString("LR")
  | F.RL: PmIO.WriteString("RL")
  ELSE PmIO.WriteString("-")
  END
END Dir;

PROCEDURE Shape(s: INTEGER);
BEGIN
  CASE s OF
    F.Rect: PmIO.WriteString("rect")
  | F.Round: PmIO.WriteString("round")
  | F.Stadium: PmIO.WriteString("stadium")
  | F.Subroutine: PmIO.WriteString("subroutine")
  | F.Cylinder: PmIO.WriteString("cylinder")
  | F.Circle: PmIO.WriteString("circle")
  | F.Asymmetric: PmIO.WriteString("asymmetric")
  | F.Diamond: PmIO.WriteString("diamond")
  | F.Hexagon: PmIO.WriteString("hexagon")
  | F.LeanRight: PmIO.WriteString("lean-right")
  | F.LeanLeft: PmIO.WriteString("lean-left")
  | F.Trapezoid: PmIO.WriteString("trapezoid")
  | F.InvTrapezoid: PmIO.WriteString("inv-trapezoid")
  | F.DoubleCircle: PmIO.WriteString("double-circle")
  END
END Shape;

PROCEDURE End(e: INTEGER);
BEGIN
  CASE e OF
    F.None: PmIO.WriteString("none")
  | F.Arrow: PmIO.WriteString("arrow")
  | F.CircleEnd: PmIO.WriteString("circle")
  | F.Cross: PmIO.WriteString("cross")
  END
END End;

PROCEDURE LineKind(l: INTEGER);
BEGIN
  CASE l OF
    F.Normal: PmIO.WriteString("normal")
  | F.Thick: PmIO.WriteString("thick")
  | F.Dotted: PmIO.WriteString("dotted")
  | F.Invisible: PmIO.WriteString("invisible")
  END
END LineKind;

(* Writes g *)
PROCEDURE Write*(g: F.Graph);
  VAR n: F.Node; e: F.Edge; c: F.Cluster; d: F.ClassDef; k: F.Name;
BEGIN
  PmIO.WriteString("direction "); Dir(g.dir); PmIO.WriteLn;
  n := g.nodes;
  WHILE n # NIL DO
    PmIO.WriteString("node "); PmIO.WriteString(n.id^);
    PmIO.WriteString(" shape="); Shape(n.shape);
    Label("label", n.label);
    IF n.classes # NIL THEN
      PmIO.WriteString(" class=");
      k := n.classes;
      WHILE k # NIL DO
        PmIO.WriteString(k.name^);
        IF k.next # NIL THEN PmIO.WriteChar(",") END;
        k := k.next
      END
    END;
    Props("style", n.style);
    IF n.cluster # NIL THEN PmIO.WriteString(" cluster="); PmIO.WriteString(n.cluster.id^) END;
    PmIO.WriteLn;
    n := n.next
  END;
  e := g.edges;
  WHILE e # NIL DO
    PmIO.WriteString("edge "); PmIO.WriteString(e.from.id^); PmIO.WriteString(" -> ");
    PmIO.WriteString(e.to.id^);
    PmIO.WriteString(" head="); End(e.head);
    PmIO.WriteString(" tail="); End(e.tail);
    PmIO.WriteString(" line="); LineKind(e.line);
    PmIO.WriteString(" len="); PmIO.WriteInt(e.length);
    Label("label", e.label);
    Props("style", e.style);
    PmIO.WriteLn;
    e := e.next
  END;
  c := g.clusters;
  WHILE c # NIL DO
    PmIO.WriteString("cluster "); PmIO.WriteString(c.id^);
    Label("title", c.title);
    PmIO.WriteString(" parent=");
    IF c.parent = NIL THEN PmIO.WriteChar("-") ELSE PmIO.WriteString(c.parent.id^) END;
    IF c.dir # F.NoDir THEN PmIO.WriteString(" direction="); Dir(c.dir) END;
    PmIO.WriteLn;
    c := c.next
  END;
  d := g.classDefs;
  WHILE d # NIL DO
    PmIO.WriteString("classDef "); PmIO.WriteString(d.name^);
    Props("props", d.props);
    PmIO.WriteLn;
    d := d.next
  END
END Write;

END PmDump.
