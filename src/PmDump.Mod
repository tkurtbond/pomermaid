MODULE PmDump;
(* PmDump: the flowchart model written out as text, one line per node,
   edge, subgraph and class definition, for the tests (-t dump). The
   lines come in the model's order, so the same input always gives the
   same output. *)

IMPORT PmIO, Y := PmYaml, F := PmFlow, FL := PmFlowLayout, L := PmLayout;

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
  VAR l: F.Line; i: LONGINT;
BEGIN
  IF lab # NIL THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
    IF lab.markdown THEN PmIO.WriteString("md:") END;
    l := lab.lines;
    WHILE l # NIL DO
      Quoted(l.text);
      IF l.style # NIL THEN
        PmIO.WriteChar("="); i := 0;
        WHILE l.text[i] # 0X DO PmIO.WriteChar(CHR(ORD("0") + l.style[i])); INC(i) END
      END;
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
  | F.DataStore: PmIO.WriteString("datastore")
  | F.Folder: PmIO.WriteString("folder")
  | F.Bucket: PmIO.WriteString("bucket")
  | F.Console: PmIO.WriteString("console")
  | F.Browser: PmIO.WriteString("browser")
  | F.Person: PmIO.WriteString("person")
  | F.Bang: PmIO.WriteString("bang")
  | F.Cloud: PmIO.WriteString("cloud")
  | F.TextShape: PmIO.WriteString("text")
  | F.NotchRect: PmIO.WriteString("notch-rect")
  | F.LinRect: PmIO.WriteString("lin-rect")
  | F.SmCircle: PmIO.WriteString("sm-circ")
  | F.FrCircle: PmIO.WriteString("fr-circ")
  | F.Fork: PmIO.WriteString("fork")
  | F.Hourglass: PmIO.WriteString("hourglass")
  | F.Brace: PmIO.WriteString("brace")
  | F.BraceR: PmIO.WriteString("brace-r")
  | F.Braces: PmIO.WriteString("braces")
  | F.Bolt: PmIO.WriteString("bolt")
  | F.Doc: PmIO.WriteString("doc")
  | F.Delay: PmIO.WriteString("delay")
  | F.HCylinder: PmIO.WriteString("h-cyl")
  | F.LinCylinder: PmIO.WriteString("lin-cyl")
  | F.CurvTrap: PmIO.WriteString("curv-trap")
  | F.DivRect: PmIO.WriteString("div-rect")
  | F.Triangle: PmIO.WriteString("tri")
  | F.WinPane: PmIO.WriteString("win-pane")
  | F.FCircle: PmIO.WriteString("f-circ")
  | F.NotchPent: PmIO.WriteString("notch-pent")
  | F.FlipTriangle: PmIO.WriteString("flip-tri")
  | F.SlRect: PmIO.WriteString("sl-rect")
  | F.Docs: PmIO.WriteString("docs")
  | F.StRect: PmIO.WriteString("st-rect")
  | F.BowRect: PmIO.WriteString("bow-rect")
  | F.CrossCircle: PmIO.WriteString("cross-circ")
  | F.TagDoc: PmIO.WriteString("tag-doc")
  | F.TagRect: PmIO.WriteString("tag-rect")
  | F.Flag: PmIO.WriteString("flag")
  | F.LinDoc: PmIO.WriteString("lin-doc")
  | F.Choice: PmIO.WriteString("choice")
  | F.StateBox: PmIO.WriteString("state")
  | F.StateDesc: PmIO.WriteString("state-desc")
  ELSE PmIO.WriteString("?")
  END
END Shape;

PROCEDURE Curve(c: INTEGER);
BEGIN
  CASE c OF
    F.Basis: PmIO.WriteString("basis")
  | F.Linear: PmIO.WriteString("linear")
  | F.Step: PmIO.WriteString("step")
  | F.StepBefore: PmIO.WriteString("stepBefore")
  | F.StepAfter: PmIO.WriteString("stepAfter")
  | F.Cardinal: PmIO.WriteString("cardinal")
  | F.CatmullRom: PmIO.WriteString("catmullRom")
  | F.Natural: PmIO.WriteString("natural")
  | F.MonotoneX: PmIO.WriteString("monotoneX")
  | F.MonotoneY: PmIO.WriteString("monotoneY")
  | F.BumpX: PmIO.WriteString("bumpX")
  | F.BumpY: PmIO.WriteString("bumpY")
  ELSE PmIO.WriteString("?")
  END
END Curve;

PROCEDURE Names(name: ARRAY OF CHAR; k: F.Name);
BEGIN
  IF k # NIL THEN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
    WHILE k # NIL DO
      PmIO.WriteString(k.name^);
      IF k.next # NIL THEN PmIO.WriteChar(",") END;
      k := k.next
    END
  END
END Names;

PROCEDURE Field(name: ARRAY OF CHAR; s: F.Str);
BEGIN
  IF s # NIL THEN PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); Quoted(s) END
END Field;

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

PROCEDURE Num(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Num;

(* Writes g *)
PROCEDURE Write*(g: F.Graph);
  VAR n: F.Node; e: F.Edge; c: F.Cluster; d: F.ClassDef; q: Y.Pair;
BEGIN
  PmIO.WriteString("direction "); Dir(g.dir); PmIO.WriteLn;
  IF g.title # NIL THEN PmIO.WriteString("title"); Label("text", g.title); PmIO.WriteLn END;
  IF g.curve # F.Basis THEN PmIO.WriteString("curve "); Curve(g.curve); PmIO.WriteLn END;
  q := g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("="); Quoted(q.value);
    PmIO.WriteLn;
    q := q.next
  END;
  n := g.nodes;
  WHILE n # NIL DO
    PmIO.WriteString("node "); PmIO.WriteString(n.id^);
    PmIO.WriteString(" shape="); Shape(n.shape);
    Label("label", n.label);
    Names("class", n.classes);
    Props("style", n.style);
    Field("link", n.link); Field("target", n.linkTarget); Field("tooltip", n.tooltip);
    Field("icon", n.icon); Field("img", n.img); Field("form", n.form); Field("pos", n.pos);
    IF n.assetW # 0 THEN Num("w", n.assetW) END;
    IF n.assetH # 0 THEN Num("h", n.assetH) END;
    IF n.constraint THEN PmIO.WriteString(" constraint") END;
    IF n.cluster # NIL THEN PmIO.WriteString(" cluster="); PmIO.WriteString(n.cluster.id^) END;
    PmIO.WriteLn;
    n := n.next
  END;
  e := g.edges;
  WHILE e # NIL DO
    PmIO.WriteString("edge "); PmIO.WriteString(e.from.id^); PmIO.WriteString(" -> ");
    PmIO.WriteString(e.to.id^);
    IF e.id # NIL THEN PmIO.WriteString(" id="); PmIO.WriteString(e.id^) END;
    PmIO.WriteString(" head="); End(e.head);
    PmIO.WriteString(" tail="); End(e.tail);
    PmIO.WriteString(" line="); LineKind(e.line);
    PmIO.WriteString(" len="); PmIO.WriteInt(e.length);
    Label("label", e.label);
    Props("style", e.style);
    Names("class", e.classes);
    IF e.curve # g.curve THEN PmIO.WriteString(" curve="); Curve(e.curve) END;
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
    Names("class", c.classes);
    IF c.collapsed THEN PmIO.WriteString(" collapsed") END;
    IF c.kind = F.Composite THEN PmIO.WriteString(" composite")
    ELSIF c.kind = F.Region THEN PmIO.WriteString(" region")
    END;
    IF c.alt THEN PmIO.WriteString(" alt") END;
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

PROCEDURE Pt(x, y: REAL);
BEGIN
  PmIO.WriteChar("("); PmIO.WriteReal(x, 2); PmIO.WriteChar(","); PmIO.WriteReal(y, 2);
  PmIO.WriteChar(")")
END Pt;

(* Writes the layout l of a flowchart (-t layout): its size, then each
   node's rank (on the grid of half ranks), place in its rank, centre
   and size, then each edge's points and its label's centre, in
   points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: FL.Layout);
  VAR n: F.Node; e: F.Edge; c: F.Cluster; ln: L.Node; le: L.Edge; lc: L.Cluster; i: INTEGER;
BEGIN
  PmIO.WriteString("layout direction "); Dir(l.graph.dir);
  Num("width", l.g.width); Num("height", l.g.height); PmIO.WriteLn;
  n := l.graph.nodes;
  WHILE n # NIL DO
    ln := l.g.node[n.index];
    PmIO.WriteString("node "); PmIO.WriteString(n.id^);
    IF ln.kind = L.Hidden THEN PmIO.WriteString(" hidden") END;
    PmIO.WriteString(" rank="); PmIO.WriteInt(ln.rank);
    PmIO.WriteString(" order="); PmIO.WriteInt(ln.order);
    Num("x", ln.x); Num("y", ln.y); Num("w", ln.w); Num("h", ln.h);
    PmIO.WriteLn;
    n := n.next
  END;
  e := l.graph.edges;
  WHILE e # NIL DO
    le := l.g.edge[e.index];
    PmIO.WriteString("edge "); PmIO.WriteString(e.from.id^); PmIO.WriteString(" -> ");
    PmIO.WriteString(e.to.id^);
    IF le.hidden THEN PmIO.WriteString(" hidden") END;
    IF le.reversed THEN PmIO.WriteString(" reversed") END;
    PmIO.WriteString(" points=");
    FOR i := 0 TO le.nPoints - 1 DO
      IF i > 0 THEN PmIO.WriteChar(" ") END;
      Pt(le.points[i].x, le.points[i].y)
    END;
    IF le.hasLabel THEN PmIO.WriteString(" label="); Pt(le.labelX, le.labelY) END;
    PmIO.WriteLn;
    e := e.next
  END;
  c := l.graph.clusters;
  WHILE c # NIL DO
    lc := l.g.cluster[c.index];
    PmIO.WriteString("cluster "); PmIO.WriteString(c.id^);
    IF l.collapsed[c.index] THEN PmIO.WriteString(" collapsed") END;
    IF l.isolated[c.index] THEN PmIO.WriteString(" isolated") END;
    IF lc.w > 0 THEN
      Num("x", lc.x); Num("y", lc.y); Num("w", lc.w); Num("h", lc.h);
      PmIO.WriteString(" title="); Pt(lc.titleX, lc.titleY)
    ELSE
      PmIO.WriteString(" empty")
    END;
    PmIO.WriteLn;
    c := c.next
  END
END WriteLayout;

END PmDump.
