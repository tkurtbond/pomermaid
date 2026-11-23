MODULE PmFlow;
(* PmFlow: Mermaid's flowcharts (`flowchart` and `graph`): the model,
   and the reader that builds it from the text.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   flowchart/parser/flow.jison, and its database, flowDb.ts, for what
   the statements mean:

   - statements end at a line end or ";"; "%%" starts a comment;
   - a node is an id, with a shape and its text in brackets ("A[text]",
     "B{text}", ...) and ":::class" after them, all optional; a node
     mentioned again with a shape takes the later text and shape;
   - an edge joins two nodes, or two groups of nodes joined by "&",
     each node of the first to each of the second; a statement may
     chain several ("A --> B --> C");
   - a subgraph holds the nodes its statements mention that no
     subgraph inside it took, as flowDb's makeUniq leaves them;
   - classDef, class, style and linkStyle keep their properties as
     written; the writers give them meaning.

   Text is decoded as Mermaid shows it: the entities "&amp;", "&lt;",
   "&gt;", "&quot;", "&nbsp;", "&#N;", and Mermaid's own "#quot;" and
   "#N;", and "<br>" (in any of its forms) breaks a line. *)

IMPORT PmIO, L := PmLex, Y := PmYaml, Em := PmEmphasis;

CONST
  Roman* = Em.Roman; Bold* = Em.Bold; Italic* = Em.Italic; (* label styles *)

  (* directions *)
  TB* = 0; BT* = 1; LR* = 2; RL* = 3; NoDir* = -1;

  (* node shapes *)
  Rect* = 0; Round* = 1; Stadium* = 2; Subroutine* = 3; Cylinder* = 4;
  Circle* = 5; Asymmetric* = 6; Diamond* = 7; Hexagon* = 8;
  LeanRight* = 9; LeanLeft* = 10; Trapezoid* = 11; InvTrapezoid* = 12;
  DoubleCircle* = 13;
  (* the shapes that have only a name, "@{ shape: name }" *)
  DataStore* = 14; Folder* = 15; Bucket* = 16; Console* = 17; Browser* = 18;
  Person* = 19; Bang* = 20; Cloud* = 21; TextShape* = 22; NotchRect* = 23;
  LinRect* = 24; SmCircle* = 25; FrCircle* = 26; Fork* = 27; Hourglass* = 28;
  Brace* = 29; BraceR* = 30; Braces* = 31; Bolt* = 32; Doc* = 33; Delay* = 34;
  HCylinder* = 35; LinCylinder* = 36; CurvTrap* = 37; DivRect* = 38;
  Triangle* = 39; WinPane* = 40; FCircle* = 41; NotchPent* = 42;
  FlipTriangle* = 43; SlRect* = 44; Docs* = 45; StRect* = 46; BowRect* = 47;
  CrossCircle* = 48; TagDoc* = 49; TagRect* = 50; Flag* = 51; LinDoc* = 52;
  (* a state diagram's (PmState): a choice, a state, and a state with
     descriptions, its name the label's first line *)
  Choice* = 53; StateBox* = 54; StateDesc* = 55;
  (* a class diagram's (PmClass): a class's box, its title, members and
     methods, and a lollipop's interface, its label alone *)
  ClassBox* = 56; Interface* = 57;
  (* an entity relationship diagram's (PmEr): an entity's box, its name
     and its attributes' table *)
  ErBox* = 58;
  (* a requirement diagram's (PmReq): a requirement's or element's box,
     its type, name and fields *)
  ReqBox* = 59;
  NShapes* = 60;

  (* the kinds of diagram *)
  Flowchart* = 0; State* = 1; Class* = 2; Er* = 3; Req* = 4; Seq* = 5; Journey* = 6;
  Timeline* = 7;
  Gantt* = 8;
  Pie* = 9;
  Quadrant* = 10;
  Xy* = 11;
  Radar* = 12;
  Sankey* = 13;
  Git* = 14;
  Mindmap* = 15;
  Treemap* = 16;

  (* the kinds of cluster: a flowchart's subgraph, a composite state,
     a composite state's concurrent region *)
  Plain* = 0; Composite* = 1; Region* = 2;

  (* edge curves, d3's: an edge's curve, or the diagram's *)
  Basis* = 0; Linear* = 1; Step* = 2; StepBefore* = 3; StepAfter* = 4;
  Cardinal* = 5; CatmullRom* = 6; Natural* = 7; MonotoneX* = 8;
  MonotoneY* = 9; BumpX* = 10; BumpY* = 11; DefaultCurve* = -1;

  (* edge ends *)
  None* = 0; Arrow* = 1; CircleEnd* = 2; Cross* = 3;
  (* a class diagram's relations' ends *)
  Extension* = 4; Composition* = 5; Aggregation* = 6; Dependency* = 7;
  Lollipop* = 8;
  (* an entity relationship diagram's (PmEr): crow's foot notation *)
  OnlyOne* = 9; ZeroOrOne* = 10; OneOrMore* = 11; ZeroOrMore* = 12;
  (* a requirement diagram's (PmReq): contains, a circle with a cross,
     and the open arrow of the others *)
  ReqContains* = 13; ReqArrow* = 14;

  (* edge lines *)
  Normal* = 0; Thick* = 1; Dotted* = 2; Invisible* = 3;

TYPE
  Str* = L.Str;
  Styles* = Em.Styles;

  (* A line of a label *)
  Line* = POINTER TO LineDesc;
  LineDesc* = RECORD
    text*: Str;
    style*: Styles;  (* each byte's style, Bold, Italic or both; NIL if
                        every byte is Roman *)
    underline*: BOOLEAN; (* a class's static member, underlined *)
    next*: Line
  END;

  (* The text of a node, an edge or a subgraph, in lines *)
  Label* = POINTER TO LabelDesc;
  LabelDesc* = RECORD
    lines*: Line;
    n*: INTEGER;        (* how many lines *)
    markdown*: BOOLEAN  (* written as a markdown string, "`...`" *)
  END;

  (* A style property, "name:value" *)
  Prop* = POINTER TO PropDesc;
  PropDesc* = RECORD
    name*, value*: Str;
    next*: Prop
  END;

  (* A name in a list *)
  Name* = POINTER TO NameDesc;
  NameDesc* = RECORD
    name*: Str;
    next*: Name
  END;

  ClassDef* = POINTER TO ClassDefDesc;
  ClassDefDesc* = RECORD
    name*: Str;
    props*: Prop;
    next*: ClassDef
  END;

  Cluster* = POINTER TO ClusterDesc;

  (* An entity's attribute, a row of its table: its type, name, keys
     ("PK,FK"; NIL if none) and comment (NIL if none) *)
  Attr* = POINTER TO AttrDesc;
  AttrDesc* = RECORD
    type*, name*, keys*, comment*: Str;
    next*: Attr
  END;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    id*: Str;
    label*: Label;      (* the id when no text was given *)
    shape*: INTEGER;
    classes*: Name;     (* class and ::: names, in order *)
    style*: Prop;       (* style statements' properties, in order *)
    link*, linkTarget*: Str; (* click's or href's URL and target, or NIL *)
    tooltip*: Str;      (* click's tooltip, or NIL *)
    icon*, img*, form*, pos*: Str; (* from "@{ ... }", or NIL; not drawn *)
    assetW*, assetH*: REAL; (* "@{ w: , h: }", or 0 *)
    constraint*: BOOLEAN; (* "@{ constraint: on }" *)
    annotation*, members*, methods*: Label; (* a ClassBox's, or NIL *)
    attrs*: Attr;       (* an ErBox's, in order, or NIL *)
    cluster*: Cluster;  (* the innermost subgraph holding it, or NIL *)
    index*: INTEGER;    (* from 0, in order of first mention *)
    next*: Node
  END;

  NodeList* = POINTER TO NodeListDesc;
  NodeListDesc* = RECORD
    node*: Node;
    next*: NodeList
  END;

  ClusterDesc* = RECORD
    id*: Str;
    title*: Label;
    parent*: Cluster;
    dir*: INTEGER;      (* its direction statement, or NoDir *)
    classes*: Name;     (* class statements' names *)
    collapsed*: BOOLEAN; (* "@{ view: collapsed }" *)
    kind*: INTEGER;     (* Plain (a subgraph), Composite or Region *)
    alt*: BOOLEAN;      (* a composite state or region at an alternate
                           depth, filled with the alternate colour *)
    mentioned: NodeList; (* the nodes its statements mention *)
    lastMentioned: NodeList;
    index*: INTEGER;    (* from 0, in order of their "end" *)
    next*: Cluster
  END;

  Edge* = POINTER TO EdgeDesc;
  EdgeDesc* = RECORD
    id*: Str;           (* the id written before its link, or NIL *)
    from*, to*: Node;
    label*: Label;      (* NIL for none *)
    startLabel*, endLabel*: Label; (* a relation's cardinalities, at from
                           and at to, or NIL *)
    head*, tail*: INTEGER; (* the ends at to and at from *)
    line*: INTEGER;
    length*: INTEGER;   (* 1, or more for a longer arrow *)
    style*: Prop;       (* from linkStyle *)
    classes*: Name;     (* class statements' names, by its id *)
    curve*: INTEGER;    (* Basis ...: its own, or else the diagram's *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Edge
  END;

  Graph* = POINTER TO GraphDesc;
  GraphDesc* = RECORD
    kind*: INTEGER;     (* Flowchart or State *)
    dir*: INTEGER;
    nodes*: Node; nNodes*: INTEGER;
    edges*: Edge; nEdges*: INTEGER;
    clusters*: Cluster; nClusters*: INTEGER; (* in order of their "end" *)
    classDefs*: ClassDef;
    title*: Label;      (* front matter's title, or NIL *)
    curve*: INTEGER;    (* the edges' curve, Basis ... *)
    config*: Y.Pair;    (* front matter's config and the init directives'
                           settings, as "config.flowchart.curve" *)
    lastNode: Node; lastEdge: Edge; lastCluster: Cluster; lastClassDef: ClassDef
  END;

  (* What an arrow says *)
  ArrowDesc = RECORD
    head, tail, line, length: INTEGER;
    label: Label;
    id: Str             (* the link's id, or NIL *)
  END;

VAR
  sc: L.Scanner;
  g: Graph;
  current: Cluster;      (* the subgraph being read, or NIL *)
  autoIds: INTEGER;      (* subgraphs given an id *)
  defaultLinkStyle: Prop;
  defaultCurve: INTEGER;  (* linkStyle default interpolate *)
  buf: L.Str;            (* text being decoded *)
  bufLen: LONGINT;
  breaks: BOOLEAN;       (* "<br>" breaks a line in what is decoded *)

(* Text *)

PROCEDURE PutByte(ch: CHAR);
  VAR n: L.Str; i: LONGINT;
BEGIN
  IF bufLen + 1 >= LEN(buf^) THEN
    NEW(n, 2 * LEN(buf^));
    FOR i := 0 TO bufLen - 1 DO n[i] := buf[i] END;
    buf := n
  END;
  buf[bufLen] := ch; INC(bufLen)
END PutByte;

(* Puts the code point c in UTF-8 *)
PROCEDURE PutCode(c: LONGINT);
BEGIN
  IF (c <= 0) OR (c > 10FFFFH) THEN c := 0FFFDH END;
  IF c < 80H THEN PutByte(CHR(c))
  ELSIF c < 800H THEN
    PutByte(CHR(0C0H + c DIV 40H)); PutByte(CHR(80H + c MOD 40H))
  ELSIF c < 10000H THEN
    PutByte(CHR(0E0H + c DIV 1000H)); PutByte(CHR(80H + c DIV 40H MOD 40H));
    PutByte(CHR(80H + c MOD 40H))
  ELSE
    PutByte(CHR(0F0H + c DIV 40000H)); PutByte(CHR(80H + c DIV 1000H MOD 40H));
    PutByte(CHR(80H + c DIV 40H MOD 40H)); PutByte(CHR(80H + c MOD 40H))
  END
END PutCode;

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether t[i ..] starts with w, ignoring case *)
PROCEDURE At(VAR t: ARRAY OF CHAR; i, end: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  k := 0;
  WHILE (k < LEN(w)) & (w[k] # 0X) DO
    IF (i + k >= end) OR (Lower(t[i + k]) # w[k]) THEN RETURN FALSE END;
    INC(k)
  END;
  RETURN TRUE
END At;

(* If t[i ..] is "<br>", "<br/>" or "<br />" (any case, blanks allowed
   before ">"), returns its length, or else 0 *)
PROCEDURE Br(VAR t: ARRAY OF CHAR; i, end: LONGINT): LONGINT;
  VAR k: LONGINT;
BEGIN
  IF ~At(t, i, end, "<br") THEN RETURN 0 END;
  k := i + 3;
  WHILE (k < end) & L.IsBlank(t[k]) DO INC(k) END;
  IF (k < end) & (t[k] = "/") THEN INC(k) END;
  IF (k < end) & (t[k] = ">") THEN RETURN k + 1 - i END;
  RETURN 0
END Br;

(* If t[i ..] is an entity, puts its character and returns its length,
   or else returns 0. amp is "&" or "#" (Mermaid's own form). *)
PROCEDURE Entity(VAR t: ARRAY OF CHAR; i, end: LONGINT): LONGINT;
  VAR k: LONGINT; c: LONGINT; hex: BOOLEAN; d: INTEGER;
BEGIN
  IF At(t, i + 1, end, "amp;") THEN PutByte("&"); RETURN 5
  ELSIF At(t, i + 1, end, "lt;") THEN PutByte("<"); RETURN 4
  ELSIF At(t, i + 1, end, "gt;") THEN PutByte(">"); RETURN 4
  ELSIF At(t, i + 1, end, "quot;") THEN PutByte(22X); RETURN 6
  ELSIF At(t, i + 1, end, "apos;") THEN PutByte("'"); RETURN 6
  ELSIF At(t, i + 1, end, "nbsp;") THEN PutCode(0A0H); RETURN 6
  END;
  k := i + 1;
  IF (t[i] = "&") & (k < end) & (t[k] = "#") THEN INC(k) END;
  IF (t[i] = "&") & (k = i + 1) THEN RETURN 0 END;
  hex := (k < end) & ((t[k] = "x") OR (t[k] = "X")) & (t[i] = "&");
  IF hex THEN INC(k) END;
  c := 0; d := 0;
  LOOP
    IF k >= end THEN RETURN 0 END;
    IF L.IsDigit(t[k]) THEN IF hex THEN c := c * 16 ELSE c := c * 10 END; c := c + ORD(t[k]) - ORD("0")
    ELSIF hex & (Lower(t[k]) >= "a") & (Lower(t[k]) <= "f") THEN c := c * 16 + ORD(Lower(t[k])) - ORD("a") + 10
    ELSE EXIT
    END;
    INC(k); INC(d);
    IF d > 7 THEN RETURN 0 END
  END;
  IF (d = 0) OR (t[k] # ";") THEN RETURN 0 END;
  PutCode(c);
  RETURN k + 1 - i
END Entity;

(* Adds the decoded buf to lab as a line, without blanks at its ends *)
PROCEDURE AddLine(lab: Label);
  VAR start, end: LONGINT; l, p: Line;
BEGIN
  start := 0; end := bufLen;
  WHILE (start < end) & L.IsBlank(buf[start]) DO INC(start) END;
  WHILE (end > start) & L.IsBlank(buf[end - 1]) DO DEC(end) END;
  NEW(l); l.text := L.Sub(buf^, start, end - start); l.style := NIL; l.underline := FALSE; l.next := NIL;
  IF lab.lines = NIL THEN lab.lines := l
  ELSE p := lab.lines; WHILE p.next # NIL DO p := p.next END; p.next := l
  END;
  INC(lab.n);
  bufLen := 0
END AddLine;

(* A markdown string's bold and italic: lab's lines, joined by line
   feeds, read by PmEmphasis and split again; a line that has a style
   but Roman keeps it in its style *)
PROCEDURE Emphasize(lab: Label);
  VAR l, first, last, nl: Line; len, i, k, n, start: LONGINT; s, t: Em.Text;
    st: Styles; styled, any: BOOLEAN;
BEGIN
  len := 0; l := lab.lines;
  WHILE l # NIL DO INC(len, L.Length(l.text^) + 1); l := l.next END;
  IF len = 0 THEN RETURN END;
  NEW(s, len + 1); k := 0; l := lab.lines;
  WHILE l # NIL DO
    i := 0; WHILE l.text[i] # 0X DO s[k] := l.text[i]; INC(k); INC(i) END;
    l := l.next;
    IF l # NIL THEN s[k] := 0AX; INC(k) END
  END;
  s[k] := 0X;
  Em.Parse(s^, k, t, st, n, styled);
  first := NIL; last := NIL; lab.n := 0; start := 0;
  FOR i := 0 TO n DO
    IF (i = n) OR (t[i] = 0AX) THEN
      NEW(nl); nl.text := L.Sub(t^, start, i - start); nl.style := NIL; nl.underline := FALSE; nl.next := NIL;
      any := FALSE;
      FOR k := start TO i - 1 DO IF st[k] # Em.Roman THEN any := TRUE END END;
      IF any THEN
        NEW(nl.style, i - start + 1);
        FOR k := start TO i - 1 DO nl.style[k - start] := st[k] END;
        nl.style[i - start] := Em.Roman
      END;
      IF last = NIL THEN first := nl ELSE last.next := nl END;
      last := nl; INC(lab.n); start := i + 1
    END
  END;
  lab.lines := first
END Emphasize;

(* The label of t[start .. end-1], decoded; markdown says it is a
   markdown string's text *)
PROCEDURE Decode(VAR t: ARRAY OF CHAR; start, end: LONGINT; markdown: BOOLEAN): Label;
  VAR lab: Label; i, n: LONGINT;
BEGIN
  NEW(lab); lab.lines := NIL; lab.n := 0; lab.markdown := markdown;
  bufLen := 0; i := start;
  WHILE i < end DO
    IF breaks THEN n := Br(t, i, end) ELSE n := 0 END;
    IF n > 0 THEN AddLine(lab); INC(i, n)
    ELSIF t[i] = 0AX THEN
      IF lab.markdown THEN AddLine(lab) ELSE PutByte(" ") END;
      INC(i)
    ELSIF (t[i] = "&") OR (t[i] = "#") THEN
      n := Entity(t, i, end);
      IF n > 0 THEN INC(i, n) ELSE PutByte(t[i]); INC(i) END
    ELSE PutByte(t[i]); INC(i)
    END
  END;
  AddLine(lab);
  IF lab.markdown THEN Emphasize(lab) END;
  RETURN lab
END Decode;

(* The label of t[start .. end-1], decoded; quoted says it was in
   quotation marks, where "`...`" makes a markdown string *)
PROCEDURE MakeLabel*(VAR t: ARRAY OF CHAR; start, end: LONGINT; quoted: BOOLEAN): Label;
BEGIN
  IF quoted & (end - start >= 2) & (t[start] = "`") & (t[end - 1] = "`") THEN
    RETURN Decode(t, start + 1, end - 1, TRUE)
  END;
  RETURN Decode(t, start, end, FALSE)
END MakeLabel;

(* The label of t[start .. end-1] read as markdown, as a markdown
   string's text is: a line end breaks a line, and bold and italic are
   kept *)
PROCEDURE MarkdownLabel*(VAR t: ARRAY OF CHAR; start, end: LONGINT): Label;
BEGIN
  RETURN Decode(t, start, end, TRUE)
END MarkdownLabel;

(* The label of t[start .. end-1], decoded, but for "<br>", which is
   text: one line, as d3's text() writes it *)
PROCEDURE TextLabel*(VAR t: ARRAY OF CHAR; start, end: LONGINT): Label;
  VAR lab: Label;
BEGIN
  breaks := FALSE;
  lab := Decode(t, start, end, FALSE);
  breaks := TRUE;
  RETURN lab
END TextLabel;

(* A label of one line, s *)
PROCEDURE PlainLabel*(s: Str): Label;
BEGIN
  RETURN MakeLabel(s^, 0, L.Length(s^), FALSE)
END PlainLabel;

(* Reads text that ends at close: a quoted string, then close, or
   anything up to close. Returns its label. *)
PROCEDURE Text(close: ARRAY OF CHAR; what: ARRAY OF CHAR): Label;
  VAR start, end, open: LONGINT; lab: Label;
BEGIN
  open := sc.pos;
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN
    INC(sc.pos); start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # 22X) DO INC(sc.pos) END;
    IF sc.AtEnd() THEN sc.ErrorAt(start - 1, "unterminated string") END;
    end := sc.pos; INC(sc.pos);
    lab := MakeLabel(sc.t^, start, end, TRUE);
    sc.SkipBlanks;
    IF ~sc.Accept(close) THEN sc.Error("expected the end of the text") END
  ELSE
    start := sc.pos;
    WHILE ~sc.AtEnd() & ~sc.LookingAt(close) & (sc.Ch() # 0AX) DO INC(sc.pos) END;
    IF ~sc.LookingAt(close) THEN sc.ErrorAt(open, what) END;
    end := sc.pos; INC(sc.pos, L.Length(close));
    lab := MakeLabel(sc.t^, start, end, FALSE)
  END;
  RETURN lab
END Text;

(* Properties: "name:value,name:value"; a comma in parentheses does not
   separate *)
PROCEDURE Props*(s: Str): Prop;
  VAR first, last, p: Prop; i, start, colon, end, depth: LONGINT;
  PROCEDURE Trim(VAR a, b: LONGINT);
  BEGIN
    WHILE (a < b) & L.IsBlank(s[a]) DO INC(a) END;
    WHILE (b > a) & L.IsBlank(s[b - 1]) DO DEC(b) END
  END Trim;
BEGIN
  first := NIL; last := NIL; i := 0;
  WHILE s[i] # 0X DO
    start := i; colon := -1; depth := 0;
    WHILE (s[i] # 0X) & ((s[i] # ",") OR (depth > 0)) DO
      IF s[i] = "(" THEN INC(depth) ELSIF (s[i] = ")") & (depth > 0) THEN DEC(depth)
      ELSIF (s[i] = ":") & (colon < 0) THEN colon := i
      END;
      INC(i)
    END;
    end := i;
    IF s[i] = "," THEN INC(i) END;
    IF colon > 0 THEN
      NEW(p); p.next := NIL;
      end := colon; Trim(start, end); p.name := L.Sub(s^, start, end - start);
      start := colon + 1; end := i; IF s[end - 1] = "," THEN DEC(end) END;
      Trim(start, end); p.value := L.Sub(s^, start, end - start);
      IF first = NIL THEN first := p ELSE last.next := p END;
      last := p
    END
  END;
  RETURN first
END Props;

(* Appends b to the list a *)
PROCEDURE AppendProps*(VAR a: Prop; b: Prop);
  VAR p: Prop;
BEGIN
  IF a = NIL THEN a := b
  ELSE p := a; WHILE p.next # NIL DO p := p.next END; p.next := b
  END
END AppendProps;

(* The model *)

(* The node id, made if it is new *)
PROCEDURE GetNode*(id: Str): Node;
  VAR n: Node;
BEGIN
  n := g.nodes;
  WHILE (n # NIL) & ~L.Equal(n.id, id) DO n := n.next END;
  IF n = NIL THEN
    NEW(n); n.id := id; n.label := NIL; n.shape := Rect; n.classes := NIL;
    n.style := NIL; n.link := NIL; n.linkTarget := NIL; n.tooltip := NIL;
    n.icon := NIL; n.img := NIL; n.form := NIL; n.pos := NIL;
    n.assetW := 0; n.assetH := 0; n.constraint := FALSE;
    n.annotation := NIL; n.members := NIL; n.methods := NIL; n.attrs := NIL;
    n.cluster := NIL; n.index := g.nNodes; n.next := NIL;
    INC(g.nNodes);
    IF g.nodes = NIL THEN g.nodes := n ELSE g.lastNode.next := n END;
    g.lastNode := n
  END;
  RETURN n
END GetNode;

(* Makes first, a list of the graph's nodes linked by their next, the
   graph's nodes, numbered in that order *)
PROCEDURE SetNodes*(first: Node);
  VAR n: Node;
BEGIN
  g.nodes := first; g.lastNode := NIL; g.nNodes := 0; n := first;
  WHILE n # NIL DO n.index := g.nNodes; INC(g.nNodes); g.lastNode := n; n := n.next END
END SetNodes;

(* Records that the statement being read in a subgraph mentions n *)
PROCEDURE Mention(n: Node);
  VAR m: NodeList;
BEGIN
  IF current # NIL THEN
    m := current.mentioned;
    WHILE (m # NIL) & (m.node # n) DO m := m.next END;
    IF m = NIL THEN
      NEW(m); m.node := n; m.next := NIL;
      IF current.mentioned = NIL THEN current.mentioned := m ELSE current.lastMentioned.next := m END;
      current.lastMentioned := m
    END
  END
END Mention;

PROCEDURE AddName*(VAR list: Name; name: Str);
  VAR c, p: Name;
BEGIN
  NEW(c); c.name := name; c.next := NIL;
  IF list = NIL THEN list := c
  ELSE p := list; WHILE p.next # NIL DO p := p.next END; p.next := c
  END
END AddName;

PROCEDURE AddClass*(n: Node; name: Str);
BEGIN AddName(n.classes, name)
END AddClass;

(* The node id, or NIL *)
PROCEDURE FindNode*(id: ARRAY OF CHAR): Node;
  VAR n: Node;
BEGIN
  n := g.nodes;
  WHILE (n # NIL) & ~L.Is(n.id, id) DO n := n.next END;
  RETURN n
END FindNode;

(* The edge whose id is id, or NIL *)
PROCEDURE FindEdge(id: ARRAY OF CHAR): Edge;
  VAR e: Edge;
BEGIN
  e := g.edges;
  WHILE (e # NIL) & ((e.id = NIL) OR ~L.Is(e.id, id)) DO e := e.next END;
  RETURN e
END FindEdge;

(* The subgraph id, ended already, or NIL *)
PROCEDURE FindCluster(id: ARRAY OF CHAR): Cluster;
  VAR c: Cluster;
BEGIN
  c := g.clusters;
  WHILE (c # NIL) & ~L.Is(c.id, id) DO c := c.next END;
  RETURN c
END FindCluster;

(* The edge from from to to; id is its id, or NIL. An id already taken
   is not given, as in Mermaid. *)
PROCEDURE AddEdge(from, to: Node; VAR a: ArrowDesc; id: Str);
  VAR e: Edge;
BEGIN
  NEW(e); e.from := from; e.to := to; e.label := a.label;
  e.startLabel := NIL; e.endLabel := NIL;
  e.head := a.head; e.tail := a.tail; e.line := a.line; e.length := a.length;
  IF e.length > 10 THEN e.length := 10 END;
  e.id := NIL;
  IF (id # NIL) & (FindEdge(id^) = NIL) THEN e.id := id END;
  e.style := NIL; e.classes := NIL; e.curve := DefaultCurve;
  e.index := g.nEdges; e.next := NIL;
  INC(g.nEdges);
  IF g.edges = NIL THEN g.edges := e ELSE g.lastEdge.next := e END;
  g.lastEdge := e
END AddEdge;

(* Statements *)

(* A node id: word characters, with single "-" and "." between them *)
PROCEDURE Id(): Str;
  VAR start: LONGINT; ch: CHAR;
BEGIN
  start := sc.pos;
  LOOP
    ch := sc.Ch();
    IF L.IsWordChar(ch) THEN INC(sc.pos)
    ELSIF ((ch = "-") OR (ch = ".")) & (sc.pos > start) & L.IsWordChar(sc.Peek(1)) THEN INC(sc.pos)
    ELSE EXIT
    END
  END;
  IF sc.pos = start THEN RETURN NIL END;
  RETURN L.Sub(sc.t^, start, sc.pos - start)
END Id;

(* Messages *)

(* Appends s to msg *)
PROCEDURE Cat(VAR msg: ARRAY OF CHAR; s: ARRAY OF CHAR);
  VAR i, k: LONGINT;
BEGIN
  k := L.Length(msg); i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) & (k < LEN(msg) - 1) DO msg[k] := s[i]; INC(k); INC(i) END;
  msg[k] := 0X
END Cat;

PROCEDURE CatNum(VAR msg: ARRAY OF CHAR; n: LONGINT);
  VAR d: ARRAY 24 OF CHAR; r: ARRAY 24 OF CHAR; k, i: INTEGER;
BEGIN
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  i := 0; WHILE k > 0 DO DEC(k); r[i] := d[k]; INC(i) END; r[i] := 0X;
  Cat(msg, r)
END CatNum;

(* A warning about the text at p: "name:line:col: msg" *)
PROCEDURE WarnAt(p: LONGINT; a, b, c: ARRAY OF CHAR);
  VAR msg: ARRAY 512 OF CHAR; line, col: LONGINT;
BEGIN
  sc.Where(p, line, col);
  msg := ""; Cat(msg, sc.name); Cat(msg, ":"); CatNum(msg, line); Cat(msg, ":");
  CatNum(msg, col); Cat(msg, ": "); Cat(msg, a); Cat(msg, b); Cat(msg, c);
  PmIO.Warn(msg)
END WarnAt;

(* An error at p, "abc" *)
PROCEDURE ErrorAt3(p: LONGINT; a, b, c: ARRAY OF CHAR);
  VAR msg: ARRAY 512 OF CHAR;
BEGIN
  msg := ""; Cat(msg, a); Cat(msg, b); Cat(msg, c);
  sc.ErrorAt(p, msg)
END ErrorAt3;

(* Shape names *)

(* The shape named name, as Mermaid's shapes.ts names them, or -1.
   undocumented is set for the names Mermaid does not document, drawn
   as the nearest shape pomermaid has. *)
PROCEDURE ShapeNamed(name: ARRAY OF CHAR; VAR undocumented: BOOLEAN): INTEGER;
  VAR i: INTEGER;

  PROCEDURE In(names: ARRAY OF CHAR): BOOLEAN;
    VAR k, j: LONGINT;
  BEGIN
    k := 0;
    WHILE names[k] # 0X DO
      j := 0;
      WHILE (names[k + j] # 0X) & (names[k + j] # " ") & (names[k + j] = name[j]) DO INC(j) END;
      IF ((names[k + j] = 0X) OR (names[k + j] = " ")) & (name[j] = 0X) THEN RETURN TRUE END;
      WHILE (names[k] # 0X) & (names[k] # " ") DO INC(k) END;
      IF names[k] = " " THEN INC(k) END
    END;
    RETURN FALSE
  END In;

BEGIN
  undocumented := In("note state bpmn-activity bpmn-data-store bpmn-start bpmn-intermediate bpmn-boundary bpmn-end choice bpmn-gateway icon anchor bpmn-annotation bpmn-data");
  IF In("rect proc process rectangle note icon") THEN i := Rect
  ELSIF In("rounded event state bpmn-activity") THEN i := Round
  ELSIF In("stadium terminal pill") THEN i := Stadium
  ELSIF In("fr-rect subprocess subproc framed-rectangle subroutine") THEN i := Subroutine
  ELSIF In("cyl db database cylinder bpmn-data-store") THEN i := Cylinder
  ELSIF In("circle circ bpmn-start bpmn-intermediate bpmn-boundary bpmn-end") THEN i := Circle
  ELSIF In("odd") THEN i := Asymmetric
  ELSIF In("diam decision diamond question choice bpmn-gateway") THEN i := Diamond
  ELSIF In("hex hexagon prepare") THEN i := Hexagon
  ELSIF In("lean-r lean-right in-out") THEN i := LeanRight
  ELSIF In("lean-l lean-left out-in") THEN i := LeanLeft
  ELSIF In("trap-b priority trapezoid-bottom trapezoid") THEN i := Trapezoid
  ELSIF In("trap-t manual trapezoid-top inv-trapezoid") THEN i := InvTrapezoid
  ELSIF In("dbl-circ double-circle doublecircle") THEN i := DoubleCircle
  ELSIF In("datastore data-store") THEN i := DataStore
  ELSIF In("folder directory") THEN i := Folder
  ELSIF In("bucket") THEN i := Bucket
  ELSIF In("console") THEN i := Console
  ELSIF In("browser") THEN i := Browser
  ELSIF In("person") THEN i := Person
  ELSIF In("bang") THEN i := Bang
  ELSIF In("cloud") THEN i := Cloud
  ELSIF In("text") THEN i := TextShape
  ELSIF In("notch-rect card notched-rectangle") THEN i := NotchRect
  ELSIF In("lin-rect lined-rectangle lined-process lin-proc shaded-process") THEN i := LinRect
  ELSIF In("sm-circ start small-circle") THEN i := SmCircle
  ELSIF In("fr-circ stop framed-circle") THEN i := FrCircle
  ELSIF In("fork join") THEN i := Fork
  ELSIF In("hourglass collate") THEN i := Hourglass
  ELSIF In("brace comment brace-l bpmn-annotation") THEN i := Brace
  ELSIF In("brace-r") THEN i := BraceR
  ELSIF In("braces") THEN i := Braces
  ELSIF In("bolt com-link lightning-bolt") THEN i := Bolt
  ELSIF In("doc document bpmn-data") THEN i := Doc
  ELSIF In("delay half-rounded-rectangle") THEN i := Delay
  ELSIF In("h-cyl das horizontal-cylinder") THEN i := HCylinder
  ELSIF In("lin-cyl disk lined-cylinder") THEN i := LinCylinder
  ELSIF In("curv-trap curved-trapezoid display") THEN i := CurvTrap
  ELSIF In("div-rect div-proc divided-rectangle divided-process") THEN i := DivRect
  ELSIF In("tri extract triangle") THEN i := Triangle
  ELSIF In("win-pane internal-storage window-pane") THEN i := WinPane
  ELSIF In("f-circ junction filled-circle anchor") THEN i := FCircle
  ELSIF In("notch-pent loop-limit notched-pentagon") THEN i := NotchPent
  ELSIF In("flip-tri manual-file flipped-triangle") THEN i := FlipTriangle
  ELSIF In("sl-rect manual-input sloped-rectangle") THEN i := SlRect
  ELSIF In("docs documents st-doc stacked-document") THEN i := Docs
  ELSIF In("st-rect procs processes stacked-rectangle") THEN i := StRect
  ELSIF In("bow-rect stored-data bow-tie-rectangle") THEN i := BowRect
  ELSIF In("cross-circ summary crossed-circle") THEN i := CrossCircle
  ELSIF In("tag-doc tagged-document") THEN i := TagDoc
  ELSIF In("tag-rect tagged-rectangle tag-proc tagged-process") THEN i := TagRect
  ELSIF In("flag paper-tape") THEN i := Flag
  ELSIF In("lin-doc lined-document") THEN i := LinDoc
  ELSE i := -1
  END;
  RETURN i
END ShapeNamed;

(* The curve named name, d3's names as Mermaid takes them, or -1 *)
PROCEDURE CurveNamed*(name: ARRAY OF CHAR): INTEGER;
BEGIN
  IF name = "basis" THEN RETURN Basis
  ELSIF name = "linear" THEN RETURN Linear
  ELSIF name = "step" THEN RETURN Step
  ELSIF name = "stepBefore" THEN RETURN StepBefore
  ELSIF name = "stepAfter" THEN RETURN StepAfter
  ELSIF name = "cardinal" THEN RETURN Cardinal
  ELSIF name = "catmullRom" THEN RETURN CatmullRom
  ELSIF name = "natural" THEN RETURN Natural
  ELSIF name = "monotoneX" THEN RETURN MonotoneX
  ELSIF name = "monotoneY" THEN RETURN MonotoneY
  ELSIF name = "bumpX" THEN RETURN BumpX
  ELSIF name = "bumpY" THEN RETURN BumpY
  END;
  RETURN -1
END CurveNamed;

(* The curve named s, at p in the text; an unknown one is warned about
   and is basis *)
PROCEDURE Curve(s: Str; p: LONGINT): INTEGER;
  VAR c: INTEGER;
BEGIN
  c := CurveNamed(s^);
  IF c < 0 THEN WarnAt(p, "unknown curve ", s^, ", drawn as basis"); c := Basis END;
  RETURN c
END Curve;

(* The number in s, as JavaScript's Number() reads a decimal, or 0 *)
PROCEDURE Number(s: Str): REAL;
  VAR i: LONGINT; x, f: REAL; neg, digits: BOOLEAN;
BEGIN
  i := 0; x := 0; neg := FALSE; digits := FALSE;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF (s[i] = "-") OR (s[i] = "+") THEN neg := s[i] = "-"; INC(i) END;
  WHILE L.IsDigit(s[i]) DO x := x * 10 + (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE END;
  IF s[i] = "." THEN
    INC(i); f := 0.1;
    WHILE L.IsDigit(s[i]) DO x := x + f * (ORD(s[i]) - ORD("0")); f := f / 10; INC(i); digits := TRUE END
  END;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF ~digits OR (s[i] # 0X) THEN RETURN 0 END;
  IF neg THEN x := -x END;
  RETURN x
END Number;

(* Metadata *)

(* "@{ ... }" at the position: its text, to the first "}" outside
   double quotes, read as Mermaid reads it: as a flow mapping when it
   is on one line, or else as a block mapping *)
PROCEDURE MetaData*(): Y.Pair;
  VAR start, end, p: LONGINT; nl, inStr: BOOLEAN; list: Y.Pair; ch: CHAR;
BEGIN
  INC(sc.pos, 2); start := sc.pos; nl := FALSE; inStr := FALSE;
  LOOP
    IF sc.AtEnd() THEN sc.ErrorAt(start - 2, "a @{ has no }") END;
    ch := sc.Ch();
    IF ch = 22X THEN inStr := ~inStr
    ELSIF (ch = "}") & ~inStr THEN EXIT
    ELSIF (ch = 0AX) & ~inStr THEN nl := TRUE
    END;
    INC(sc.pos)
  END;
  end := sc.pos; INC(sc.pos);
  IF nl THEN Y.Block(sc, start, end, TRUE, "", list)
  ELSE p := Y.Flow(sc, start, end, FALSE, TRUE, "", list)
  END;
  RETURN list
END MetaData;

(* Whether the value of q is one JavaScript takes as true: not "",
   "false", "0" or "null" *)
PROCEDURE Truthy(q: Y.Pair): BOOLEAN;
BEGIN
  RETURN (q # NIL) & (q.value[0] # 0X) & ~L.Is(q.value, "false") & ~L.Is(q.value, "0")
    & ~L.Is(q.value, "null")
END Truthy;

(* Whether n's text is still its id, as when it was given none *)
PROCEDURE TextIsId(n: Node): BOOLEAN;
BEGIN
  RETURN (n.label = NIL) OR (n.label.n = 1) & L.Equal(n.label.lines.text, n.id)
END TextIsId;

(* An empty label *)
PROCEDURE EmptyLabel(): Label;
  VAR lab: Label;
BEGIN
  NEW(lab); lab.lines := NIL; lab.n := 0; lab.markdown := FALSE;
  bufLen := 0; AddLine(lab);
  RETURN lab
END EmptyLabel;

(* The metadata list of the edge e *)
PROCEDURE EdgeMeta(e: Edge; list: Y.Pair);
  VAR q: Y.Pair;
BEGIN
  (* animate, animation and step are read and not drawn *)
  q := Y.Find(list, "curve");
  IF q # NIL THEN e.curve := Curve(q.value, q.pos) END
END EdgeMeta;

(* The metadata list of the node n, as flowDb's addVertex takes it *)
PROCEDURE NodeMeta(n: Node; list: Y.Pair);
  VAR q, label: Y.Pair; shape: INTEGER; i: LONGINT; undoc: BOOLEAN;
BEGIN
  q := Y.Find(list, "shape");
  IF Truthy(q) THEN
    i := 0;
    WHILE (q.value[i] # 0X) & ~((q.value[i] >= "A") & (q.value[i] <= "Z")) & (q.value[i] # "_") DO INC(i) END;
    IF q.value[i] # 0X THEN
      ErrorAt3(q.pos, "no such shape: ", q.value^, "; shape names are lower case")
    END;
    shape := ShapeNamed(q.value^, undoc);
    IF shape < 0 THEN ErrorAt3(q.pos, "no such shape: ", q.value^, "") END;
    IF undoc THEN WarnAt(q.pos, "Mermaid does not document the shape ", q.value^, "; drawn as the nearest one") END;
    n.shape := shape
  END;
  label := Y.Find(list, "label");
  IF Truthy(label) THEN
    n.label := MakeLabel(label.value^, 0, L.Length(label.value^), TRUE);
    q := Y.Find(list, "labelType");
    IF (q # NIL) & L.Is(q.value, "markdown") & ~n.label.markdown THEN
      n.label.markdown := TRUE; Emphasize(n.label)
    END
  END;
  q := Y.Find(list, "icon");
  IF Truthy(q) THEN
    n.icon := q.value;
    IF ((label = NIL) OR (label.value[0] = 0X)) & TextIsId(n) THEN n.label := EmptyLabel() END
  END;
  q := Y.Find(list, "form"); IF Truthy(q) THEN n.form := q.value END;
  q := Y.Find(list, "pos"); IF Truthy(q) THEN n.pos := q.value END;
  q := Y.Find(list, "img");
  IF Truthy(q) THEN
    n.img := q.value;
    IF ((label = NIL) OR (label.value[0] = 0X)) & TextIsId(n) THEN n.label := EmptyLabel() END
  END;
  q := Y.Find(list, "constraint"); IF Truthy(q) THEN n.constraint := L.Is(q.value, "on") END;
  q := Y.Find(list, "w"); IF q # NIL THEN n.assetW := Number(q.value) END;
  q := Y.Find(list, "h"); IF q # NIL THEN n.assetH := Number(q.value) END
END NodeMeta;

(* The metadata list for id: a subgraph's, an edge's or a node's, in
   that order, as flowDb's addVertex looks for them *)
PROCEDURE Meta(id: Str; list: Y.Pair);
  VAR c: Cluster; e: Edge; q: Y.Pair;
BEGIN
  c := FindCluster(id^);
  IF c # NIL THEN
    q := Y.Find(list, "view");
    IF q # NIL THEN c.collapsed := L.Is(q.value, "collapsed") END
  ELSE
    e := FindEdge(id^);
    IF e # NIL THEN EdgeMeta(e, list) ELSE NodeMeta(GetNode(id), list) END
  END
END Meta;

(* The shape after a node's id, and its text, if there is one *)
PROCEDURE Shape(n: Node);
  VAR shape: INTEGER; close: ARRAY 4 OF CHAR; lab: Label; start: LONGINT;
BEGIN
  start := sc.pos;
  IF sc.Accept("(((") THEN shape := DoubleCircle; close := ")))"
  ELSIF sc.Accept("((") THEN shape := Circle; close := "))"
  ELSIF sc.Accept("([") THEN shape := Stadium; close := "])"
  ELSIF sc.Accept("(") THEN shape := Round; close := ")"
  ELSIF sc.Accept("[[") THEN shape := Subroutine; close := "]]"
  ELSIF sc.Accept("[(") THEN shape := Cylinder; close := ")]"
  ELSIF sc.Accept("[/") THEN shape := LeanRight; close := "/]"
  ELSIF sc.Accept("[\") THEN shape := LeanLeft; close := "\]"
  ELSIF sc.Accept("[") THEN shape := Rect; close := "]"
  ELSIF sc.Accept("{{") THEN shape := Hexagon; close := "}}"
  ELSIF sc.Accept("{") THEN shape := Diamond; close := "}"
  ELSIF sc.Accept(">") THEN shape := Asymmetric; close := "]"
  ELSE RETURN
  END;
  IF (shape = LeanRight) OR (shape = LeanLeft) THEN
    (* [/text/] and [\text\], or the trapezoids [/text\] and [\text/] *)
    IF sc.Ch() = 22X THEN
      lab := Text(close, "")
    ELSE
      start := sc.pos;
      WHILE ~sc.AtEnd() & ~sc.LookingAt("/]") & ~sc.LookingAt("\]") & (sc.Ch() # 0AX) DO INC(sc.pos) END;
      IF sc.AtEnd() OR (sc.Ch() = 0AX) THEN sc.ErrorAt(start - 2, "a node's text has no end") END;
      lab := MakeLabel(sc.t^, start, sc.pos, FALSE);
      IF (shape = LeanRight) & sc.LookingAt("\]") THEN shape := Trapezoid
      ELSIF (shape = LeanLeft) & sc.LookingAt("/]") THEN shape := InvTrapezoid
      END;
      INC(sc.pos, 2)
    END
  ELSE
    lab := Text(close, "a node's text has no end")
  END;
  n.shape := shape; n.label := lab
END Shape;

(* A node, with its shape, classes and metadata. "id@{ ... }" where
   id is an edge's or an ended subgraph's sets their metadata and
   gives NIL. *)
PROCEDURE NodeRef(): Node;
  VAR id, cls: Str; n: Node; meta: Y.Pair;
BEGIN
  id := Id();
  IF id = NIL THEN sc.Error("expected a node"); RETURN NIL END;
  IF sc.LookingAt("@{") & ((FindEdge(id^) # NIL) OR (FindCluster(id^) # NIL)) THEN
    Meta(id, MetaData()); RETURN NIL
  END;
  n := GetNode(id);
  Shape(n);
  IF sc.Accept(":::") THEN
    cls := sc.Word();
    IF cls = NIL THEN sc.Error("expected a class name") END;
    AddClass(n, cls)
  END;
  IF sc.LookingAt("@{") THEN meta := MetaData(); NodeMeta(n, meta) END;
  Mention(n);
  RETURN n
END NodeRef;

(* Nodes joined by "&" *)
PROCEDURE Group(): NodeList;
  VAR first, last, m: NodeList;
BEGIN
  first := NIL; last := NIL;
  LOOP
    sc.SkipBlanks;
    NEW(m); m.node := NodeRef(); m.next := NIL;
    IF first = NIL THEN first := m ELSE last.next := m END;
    last := m;
    sc.SkipBlanks;
    IF ~sc.Accept("&") THEN EXIT END
  END;
  RETURN first
END Group;

(* The end of a link: head kind for ">", "x" or "o" *)
PROCEDURE HeadKind(ch: CHAR): INTEGER;
BEGIN
  IF ch = ">" THEN RETURN Arrow ELSIF ch = "x" THEN RETURN Cross ELSIF ch = "o" THEN RETURN CircleEnd END;
  RETURN None
END HeadKind;

(* Reads the body of a link at the position, after its tail: "--...>",
   "==...>", "-..->", "~~~"; sets line, length and head. With text,
   "-- " (and "== ", "-. ") starting text is accepted, and opens is set. *)
PROCEDURE LinkBody(VAR a: ArrowDesc; text: BOOLEAN; VAR opens: BOOLEAN): BOOLEAN;
  VAR n: INTEGER; c: CHAR; save: LONGINT;
BEGIN
  save := sc.pos; opens := FALSE;
  IF sc.LookingAt("--") OR sc.LookingAt("==") THEN
    c := sc.Ch();
    IF c = "-" THEN a.line := Normal ELSE a.line := Thick END;
    n := 0; WHILE sc.Ch() = c DO INC(n); INC(sc.pos) END;
    IF (sc.Ch() = ">") OR (((sc.Ch() = "x") OR (sc.Ch() = "o")) & ~L.IsWordChar(sc.Peek(1))) THEN
      a.head := HeadKind(sc.Ch()); INC(sc.pos); a.length := n - 1
    ELSIF n >= 3 THEN
      a.head := None; a.length := n - 2
    ELSIF text & (n = 2) & L.IsBlank(sc.Ch()) THEN
      opens := TRUE
    ELSE
      sc.pos := save; RETURN FALSE
    END;
    RETURN TRUE
  ELSIF sc.LookingAt("-.") OR sc.LookingAt(".") THEN
    a.line := Dotted;
    IF sc.Ch() = "-" THEN INC(sc.pos) END;
    n := 0; WHILE sc.Ch() = "." DO INC(n); INC(sc.pos) END;
    IF sc.Ch() = "-" THEN
      INC(sc.pos);
      a.head := HeadKind(sc.Ch());
      IF a.head # None THEN INC(sc.pos) END;
      a.length := n;
      RETURN TRUE
    ELSIF text & (n = 1) & L.IsBlank(sc.Ch()) & (sc.t[save] = "-") THEN
      opens := TRUE; RETURN TRUE
    END;
    sc.pos := save; RETURN FALSE
  ELSIF sc.LookingAt("~~~") THEN
    a.line := Invisible; a.head := None;
    n := 0; WHILE sc.Ch() = "~" DO INC(n); INC(sc.pos) END;
    a.length := n - 2;
    RETURN TRUE
  END;
  RETURN FALSE
END LinkBody;

(* An edge's id before its link, "e1@-->": the characters up to the
   last "@" not followed by "{" or a quotation mark, in a run of
   characters other than blanks and "[](){}|, as Mermaid's LINK_ID *)
PROCEDURE LinkId(VAR a: ArrowDesc);
  VAR i, at: LONGINT; ch: CHAR;
BEGIN
  i := sc.pos; at := -1;
  LOOP
    IF i >= sc.len THEN EXIT END;
    ch := sc.t[i];
    IF L.IsBlank(ch) OR (ch = 0AX) OR (ch = 0DX) OR (ch = 22X) OR (ch = "[") OR (ch = "]")
       OR (ch = "(") OR (ch = ")") OR (ch = "{") OR (ch = "}") OR (ch = "|") THEN EXIT
    END;
    IF (ch = "@") & (i > sc.pos) & (i + 1 < sc.len) & (sc.t[i + 1] # "{") & (sc.t[i + 1] # 22X) THEN at := i END;
    INC(i)
  END;
  IF at > 0 THEN a.id := L.Sub(sc.t^, sc.pos, at - sc.pos); sc.pos := at + 1 END
END LinkId;

(* Reads a link with its text, if there is one there *)
PROCEDURE Link(VAR a: ArrowDesc): BOOLEAN;
  VAR save, start, end: LONGINT; opens, dummy: BOOLEAN; line: INTEGER; ch: CHAR;
BEGIN
  save := sc.pos;
  sc.SkipBlanks;
  a.tail := None; a.head := None; a.label := NIL; a.length := 1; a.id := NIL;
  LinkId(a);
  ch := sc.Ch();
  IF (ch = "<") OR (ch = "x") OR (ch = "o") THEN
    IF (ch = "<") OR sc.LookingAt("x--") OR sc.LookingAt("o--") OR sc.LookingAt("x==")
       OR sc.LookingAt("o==") OR sc.LookingAt("x-.") OR sc.LookingAt("o-.") THEN
      a.tail := HeadKind(ch); IF ch = "<" THEN a.tail := Arrow END;
      INC(sc.pos)
    END
  END;
  IF ~LinkBody(a, TRUE, opens) THEN sc.pos := save; RETURN FALSE END;
  IF opens THEN
    (* "-- text -->": the text runs to the link that ends it *)
    line := a.line; start := sc.pos;
    LOOP
      IF sc.AtEnd() OR (sc.Ch() = 0AX) THEN sc.ErrorAt(start, "the text of an edge has no end") END;
      IF (line = Normal) & sc.LookingAt("--") OR (line = Thick) & sc.LookingAt("==")
         OR (line = Dotted) & (sc.LookingAt(".-") OR sc.LookingAt("-.")) THEN
        end := sc.pos;
        IF LinkBody(a, FALSE, dummy) THEN EXIT END
      END;
      INC(sc.pos)
    END;
    WHILE (start < end) & L.IsBlank(sc.t[start]) DO INC(start) END;
    WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
    IF (end - start >= 2) & (sc.t[start] = 22X) & (sc.t[end - 1] = 22X) THEN
      a.label := MakeLabel(sc.t^, start + 1, end - 1, TRUE)
    ELSE
      a.label := MakeLabel(sc.t^, start, end, FALSE)
    END
  END;
  sc.SkipBlanks;
  IF sc.Accept("|") THEN
    a.label := Text("|", "the text of an edge has no end")
  END;
  RETURN TRUE
END Link;

(* A statement of nodes and edges *)
PROCEDURE Chain;
  VAR left, right, l, r: NodeList; a: ArrowDesc;
BEGIN
  left := Group();
  WHILE Link(a) DO
    sc.SkipBlanks;
    right := Group();
    l := left;
    WHILE l # NIL DO
      r := right;
      WHILE r # NIL DO
        IF (l.node = NIL) OR (r.node = NIL) THEN sc.Error("an edge's or a subgraph's metadata cannot be joined by an edge") END;
        (* the id goes to the edge from the last node to the first *)
        IF (l.next = NIL) & (r = right) THEN AddEdge(l.node, r.node, a, a.id)
        ELSE AddEdge(l.node, r.node, a, NIL)
        END;
        r := r.next
      END;
      l := l.next
    END;
    left := right
  END;
  IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END
END Chain;

(* A direction: TB, TD, BT, RL, LR, or >, <, ^, v *)
PROCEDURE Direction(): INTEGER;
  VAR d: INTEGER;
BEGIN
  sc.SkipBlanks;
  IF sc.LookingAtWord("TB") OR sc.LookingAtWord("TD") THEN d := TB
  ELSIF sc.LookingAtWord("BT") THEN d := BT
  ELSIF sc.LookingAtWord("LR") THEN d := LR
  ELSIF sc.LookingAtWord("RL") THEN d := RL
  ELSIF sc.Ch() = ">" THEN d := LR; INC(sc.pos); RETURN d
  ELSIF sc.Ch() = "<" THEN d := RL; INC(sc.pos); RETURN d
  ELSIF sc.Ch() = "^" THEN d := BT; INC(sc.pos); RETURN d
  ELSIF sc.LookingAtWord("v") THEN d := TB; INC(sc.pos); RETURN d
  ELSE sc.Error("expected a direction: TB, TD, BT, RL or LR"); RETURN TB
  END;
  INC(sc.pos, 2);
  RETURN d
END Direction;

(* "subgraph id", "subgraph id [title]", "subgraph title", "subgraph
   "title"" *)
PROCEDURE Subgraph;
  VAR c: Cluster; start, end: LONGINT; raw: Str; spaces: BOOLEAN; i: LONGINT;
    num: ARRAY 16 OF CHAR; k, n: INTEGER;
BEGIN
  NEW(c); c.parent := current; c.dir := NoDir; c.mentioned := NIL; c.lastMentioned := NIL;
  c.id := NIL; c.title := NIL; c.next := NIL; c.index := -1;
  c.classes := NIL; c.collapsed := FALSE; c.kind := Plain; c.alt := FALSE;
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN
    c.title := Text("", "")
  ELSE
    start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # "[") & (sc.Ch() # 0AX) & (sc.Ch() # ";") DO INC(sc.pos) END;
    end := sc.pos;
    WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
    raw := L.Sub(sc.t^, start, end - start);
    IF sc.Accept("[") THEN
      c.id := raw; c.title := Text("]", "a subgraph's title has no end")
    ELSE
      spaces := FALSE;
      i := 0; WHILE raw[i] # 0X DO IF L.IsBlank(raw[i]) THEN spaces := TRUE END; INC(i) END;
      IF ~spaces THEN c.id := raw END;
      c.title := PlainLabel(raw)
    END;
    IF (c.id # NIL) & (c.id[0] = 0X) THEN sc.ErrorAt(start, "expected a subgraph's id or title") END
  END;
  IF c.id = NIL THEN
    n := autoIds; INC(autoIds); k := 0;
    REPEAT num[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    raw := NIL; NEW(raw, 9 + k + 1);
    COPY("subGraph", raw^); i := 8;
    WHILE k > 0 DO DEC(k); raw[i] := num[k]; INC(i) END;
    raw[i] := 0X;
    c.id := raw
  END;
  current := c;
  IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END
END Subgraph;

(* "end": the subgraph takes the nodes it mentions that are not taken *)
PROCEDURE End;
  VAR c, p: Cluster; m: NodeList;
BEGIN
  c := current;
  IF c = NIL THEN sc.ErrorAt(sc.pos - 3, '"end" without a subgraph') END;
  m := c.mentioned;
  WHILE m # NIL DO
    IF m.node.cluster = NIL THEN m.node.cluster := c END;
    m := m.next
  END;
  c.index := g.nClusters; INC(g.nClusters);
  IF g.clusters = NIL THEN g.clusters := c ELSE g.lastCluster.next := c END;
  g.lastCluster := c;
  current := c.parent;
  (* the outer subgraph mentions what the inner one did *)
  IF current # NIL THEN
    m := c.mentioned;
    WHILE m # NIL DO Mention(m.node); m := m.next END
  END;
  IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END
END End;

(* "classDef a,b props" *)
PROCEDURE ClassDefStmt*;
  VAR names, props: Str; i, start: LONGINT; d: ClassDef; p: Prop;
BEGIN
  sc.SkipBlanks;
  start := sc.pos;
  WHILE ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) & (sc.Ch() # ";") DO INC(sc.pos) END;
  names := L.Sub(sc.t^, start, sc.pos - start);
  IF names[0] = 0X THEN sc.Error("expected a class name") END;
  props := sc.Rest();
  i := 0;
  WHILE names[i] # 0X DO
    start := i;
    WHILE (names[i] # 0X) & (names[i] # ",") DO INC(i) END;
    IF i > start THEN
      NEW(d); d.name := L.Sub(names^, start, i - start); d.props := Props(props); d.next := NIL;
      IF g.classDefs = NIL THEN g.classDefs := d ELSE g.lastClassDef.next := d END;
      g.lastClassDef := d
    END;
    IF names[i] = "," THEN INC(i) END
  END;
  p := NIL
END ClassDefStmt;

(* "class a,b name": the class is given to the nodes, edges (by their
   ids) and subgraphs named that are there already; as in Mermaid's
   setClass, nothing is made *)
PROCEDURE ClassStmt;
  VAR ids, name: Str; i, start: LONGINT; id: Str; n: Node; e: Edge; c: Cluster;
BEGIN
  sc.SkipBlanks;
  start := sc.pos;
  WHILE ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) & (sc.Ch() # ";") DO INC(sc.pos) END;
  ids := L.Sub(sc.t^, start, sc.pos - start);
  IF ids[0] = 0X THEN sc.Error("expected a node id") END;
  name := sc.Rest();
  IF name[0] = 0X THEN sc.Error("expected a class name") END;
  i := 0;
  WHILE ids[i] # 0X DO
    start := i;
    WHILE (ids[i] # 0X) & (ids[i] # ",") DO INC(i) END;
    id := L.Sub(ids^, start, i - start);
    n := FindNode(id^); IF n # NIL THEN AddClass(n, name) END;
    e := FindEdge(id^); IF e # NIL THEN AddName(e.classes, name) END;
    c := FindCluster(id^); IF c # NIL THEN AddName(c.classes, name) END;
    IF ids[i] = "," THEN INC(i) END
  END
END ClassStmt;

(* "style id props" *)
PROCEDURE StyleStmt;
  VAR id: Str; n: Node;
BEGIN
  sc.SkipBlanks;
  id := Id();
  IF id = NIL THEN sc.Error("expected a node id") END;
  n := GetNode(id);
  AppendProps(n.style, Props(sc.Rest()))
END StyleStmt;

(* "linkStyle 0,1 props" or "linkStyle default props", with
   "interpolate curve" before the props *)
PROCEDURE LinkStyleStmt;
  VAR nums: ARRAY 256 OF INTEGER; n, i, k, curve: INTEGER; props, name: Str; e: Edge;

  PROCEDURE Interpolate;
    VAR at: LONGINT;
  BEGIN
    sc.SkipBlanks;
    IF sc.LookingAtWord("interpolate") THEN
      INC(sc.pos, 11); sc.SkipBlanks; at := sc.pos;
      name := sc.Word();
      IF name = NIL THEN sc.Error("expected a curve's name") END;
      curve := Curve(name, at)
    END
  END Interpolate;

BEGIN
  sc.SkipBlanks;
  n := 0; curve := DefaultCurve;
  IF sc.LookingAtWord("default") THEN
    INC(sc.pos, 7);
    Interpolate;
    IF curve # DefaultCurve THEN defaultCurve := curve END;
    AppendProps(defaultLinkStyle, Props(sc.Rest()))
  ELSE
    LOOP
      sc.SkipBlanks;
      IF ~L.IsDigit(sc.Ch()) THEN sc.Error("expected an edge's number") END;
      k := 0;
      WHILE L.IsDigit(sc.Ch()) DO
        IF k < 10000 THEN k := k * 10 + ORD(sc.Ch()) - ORD("0") END;
        INC(sc.pos)
      END;
      IF n < LEN(nums) THEN nums[n] := k; INC(n) END;
      IF ~sc.Accept(",") THEN EXIT END
    END;
    Interpolate;
    props := sc.Rest();
    FOR i := 0 TO n - 1 DO
      e := g.edges;
      WHILE (e # NIL) & (e.index # nums[i]) DO e := e.next END;
      IF e = NIL THEN sc.Error("linkStyle names an edge that is not there") END;
      IF curve # DefaultCurve THEN e.curve := curve END;
      AppendProps(e.style, Props(props))
    END
  END
END LinkStyleStmt;

(* A string in double quotation marks at the position *)
PROCEDURE Quoted(): Str;
  VAR start: LONGINT;
BEGIN
  INC(sc.pos); start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 22X) & (sc.Ch() # 0AX) DO INC(sc.pos) END;
  IF sc.Ch() # 22X THEN sc.ErrorAt(start - 1, "unterminated string") END;
  INC(sc.pos);
  RETURN L.Sub(sc.t^, start, sc.pos - 1 - start)
END Quoted;

(* "click ids ...": a link, "href "url"" or ""url"", with a tooltip
   and a target, or a callback, "call f(args)" or "f", with a tooltip.
   Callbacks are JavaScript, and are not kept; their tooltips are. *)
PROCEDURE Click*;
  VAR ids, url, tip, target, id: Str; i, start: LONGINT; callback: BOOLEAN; n: Node;
BEGIN
  sc.SkipBlanks;
  start := sc.pos;
  WHILE ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) & (sc.Ch() # ";") DO INC(sc.pos) END;
  ids := L.Sub(sc.t^, start, sc.pos - start);
  IF ids[0] = 0X THEN sc.Error("expected a node id") END;
  sc.SkipBlanks;
  url := NIL; tip := NIL; target := NIL; callback := FALSE;
  IF sc.LookingAtWord("call") THEN
    INC(sc.pos, 4); sc.SkipBlanks;
    IF sc.Word() = NIL THEN sc.Error("expected a function's name") END;
    IF sc.Ch() = "(" THEN
      WHILE ~sc.AtEnd() & (sc.Ch() # ")") & (sc.Ch() # 0AX) DO INC(sc.pos) END;
      IF ~sc.Accept(")") THEN sc.Error("expected )") END
    END;
    callback := TRUE
  ELSIF sc.LookingAtWord("href") THEN
    INC(sc.pos, 4); sc.SkipBlanks;
    IF sc.Ch() # 22X THEN sc.Error("expected a URL in quotation marks") END;
    url := Quoted()
  ELSIF sc.Ch() = 22X THEN url := Quoted()
  ELSE
    IF sc.Word() = NIL THEN sc.Error("expected a URL or a function's name") END;
    callback := TRUE
  END;
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN tip := Quoted(); sc.SkipBlanks END;
  IF (url # NIL) & (sc.LookingAtWord("_self") OR sc.LookingAtWord("_blank")
     OR sc.LookingAtWord("_parent") OR sc.LookingAtWord("_top")) THEN
    target := sc.Word()
  END;
  IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END;
  i := 0;
  WHILE ids[i] # 0X DO
    start := i;
    WHILE (ids[i] # 0X) & (ids[i] # ",") DO INC(i) END;
    id := L.Sub(ids^, start, i - start);
    n := FindNode(id^);
    IF n # NIL THEN
      IF url # NIL THEN n.link := url; n.linkTarget := target END;
      IF tip # NIL THEN n.tooltip := tip END;
      AddClass(n, L.New("clickable"))
    END;
    IF ids[i] = "," THEN INC(i) END
  END
END Click;

(* "accTitle: text", "accDescr: text" and "accDescr { ... }" are for
   readers of the web page; they are skipped *)
PROCEDURE Accessibility*;
BEGIN
  WHILE ~sc.AtEnd() & (sc.Ch() # ":") & (sc.Ch() # "{") & (sc.Ch() # 0AX) DO INC(sc.pos) END;
  IF sc.Ch() = "{" THEN
    WHILE ~sc.AtEnd() & (sc.Ch() # "}") DO INC(sc.pos) END;
    IF sc.AtEnd() THEN sc.Error("accDescr { has no }") END;
    INC(sc.pos)
  ELSE sc.SkipLine
  END
END Accessibility;

PROCEDURE Statement;
BEGIN
  IF sc.LookingAtWord("subgraph") THEN INC(sc.pos, 8); Subgraph
  ELSIF sc.LookingAtWord("end") THEN INC(sc.pos, 3); End
  ELSIF sc.LookingAtWord("classDef") THEN INC(sc.pos, 8); ClassDefStmt
  ELSIF sc.LookingAtWord("class") THEN INC(sc.pos, 5); ClassStmt
  ELSIF sc.LookingAtWord("style") THEN INC(sc.pos, 5); StyleStmt
  ELSIF sc.LookingAtWord("linkStyle") THEN INC(sc.pos, 9); LinkStyleStmt
  ELSIF sc.LookingAtWord("click") THEN INC(sc.pos, 5); Click
  ELSIF sc.LookingAtWord("accTitle") OR sc.LookingAtWord("accDescr") THEN Accessibility
  ELSIF sc.LookingAtWord("direction") THEN
    INC(sc.pos, 9);
    IF current # NIL THEN current.dir := Direction() ELSE g.dir := Direction() END;
    IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END
  ELSE Chain
  END
END Statement;

(* The pairs of list whose names start with "config." *)
PROCEDURE ConfigPairs(list: Y.Pair): Y.Pair;
  VAR first, last, q: Y.Pair;
BEGIN
  first := NIL; last := NIL;
  WHILE list # NIL DO
    q := list; list := list.next;
    IF (q.name[0] = "c") & (q.name[1] = "o") & (q.name[2] = "n") & (q.name[3] = "f")
       & (q.name[4] = "i") & (q.name[5] = "g") & (q.name[6] = ".")
       OR L.Is(q.name, "displayMode") THEN
      q.next := NIL;
      IF first = NIL THEN first := q ELSE last.next := q END;
      last := q
    END
  END;
  RETURN first
END ConfigPairs;

(* A front matter block, "---" lines around YAML, if the text starts
   with one. With read, its title and config go into g. *)
PROCEDURE FrontMatter(read: BOOLEAN);
  VAR start: LONGINT; list, q: Y.Pair;
BEGIN
  sc.SkipBlanks;
  IF sc.LookingAt("---") THEN
    sc.SkipLine; start := sc.pos;
    LOOP
      IF sc.AtEnd() THEN sc.Error("the front matter has no closing ---") END;
      INC(sc.pos);
      IF sc.LookingAt("---") THEN EXIT END;
      sc.SkipLine
    END;
    IF read THEN
      Y.Block(sc, start + 1, sc.pos, FALSE, "", list);
      q := Y.Find(list, "title");
      IF (q # NIL) & (q.value[0] # 0X) THEN g.title := PlainLabel(q.value) END;
      Y.Append(g.config, ConfigPairs(list))
    END;
    sc.SkipLine
  END
END FrontMatter;

(* The "%%{init: ...}%%" directives, anywhere at the start of a line:
   their settings go into g.config, renamed "config." *)
PROCEDURE Directives;
  VAR save, e, i, k, p: LONGINT; list, q: Y.Pair; name: Str;
BEGIN
  save := sc.pos; sc.pos := 0;
  WHILE ~sc.AtEnd() DO
    sc.SkipBlanks;
    e := sc.DirectiveEnd();
    IF e >= 0 THEN
      i := sc.pos + 3;
      WHILE (i < e) & (L.IsBlank(sc.t[i]) OR (sc.t[i] = 0AX)) DO INC(i) END;
      IF (sc.t[i] = "i") & (sc.t[i + 1] = "n") & (sc.t[i + 2] = "i") & (sc.t[i + 3] = "t") THEN
        p := Y.Flow(sc, sc.pos + 3, e - 3, FALSE, FALSE, "", list);
        q := list;
        WHILE q # NIL DO
          (* "init.X" or "initialize.X" become "config.X" *)
          k := 0; WHILE (q.name[k] # 0X) & (q.name[k] # ".") DO INC(k) END;
          IF q.name[k] = "." THEN
            NEW(name, L.Length(q.name^) - k + 7);
            COPY("config", name^); i := 6;
            WHILE q.name[k] # 0X DO name[i] := q.name[k]; INC(i); INC(k) END;
            name[i] := 0X;
            q.name := name
          END;
          q := q.next
        END;
        Y.Append(g.config, ConfigPairs(list))
      END;
      sc.pos := e
    END;
    sc.SkipLine; IF ~sc.AtEnd() THEN INC(sc.pos) END
  END;
  sc.pos := save
END Directives;

(* Building a graph, for the readers of other diagrams (PmState) *)

(* Begins graph, a new one of kind kind (Flowchart or State), for the
   text of s: its front matter and its directives are read, and the
   scanner is left at the diagram's first word *)
PROCEDURE Begin*(s: L.Scanner; kind: INTEGER; VAR graph: Graph);
BEGIN
  sc := s; current := NIL; autoIds := 0; defaultLinkStyle := NIL; defaultCurve := DefaultCurve;
  NEW(g); g.kind := kind; g.dir := TB; g.nodes := NIL; g.nNodes := 0; g.edges := NIL;
  g.nEdges := 0; g.clusters := NIL; g.nClusters := 0; g.classDefs := NIL;
  g.title := NIL; g.config := NIL; g.curve := Basis;
  g.lastNode := NIL; g.lastEdge := NIL; g.lastCluster := NIL; g.lastClassDef := NIL;
  FrontMatter(TRUE); Directives; sc.SkipSpace;
  graph := g
END Begin;

(* A new edge from from to to, with ends head and tail (None, Arrow
   ...), line line (Normal ...) and label label, or NIL *)
PROCEDURE NewEdge*(from, to: Node; head, tail, line: INTEGER; label: Label): Edge;
  VAR a: ArrowDesc;
BEGIN
  a.head := head; a.tail := tail; a.line := line; a.length := 1; a.label := label; a.id := NIL;
  AddEdge(from, to, a, NIL);
  RETURN g.lastEdge
END NewEdge;

(* A new cluster id of kind kind, with title title and in parent, or
   NIL; it is not in the graph until AddCluster *)
PROCEDURE NewCluster*(id: Str; title: Label; parent: Cluster; kind: INTEGER): Cluster;
  VAR c: Cluster;
BEGIN
  NEW(c); c.id := id; c.title := title; c.parent := parent; c.dir := NoDir;
  c.classes := NIL; c.collapsed := FALSE; c.kind := kind; c.alt := FALSE;
  c.mentioned := NIL; c.lastMentioned := NIL; c.index := -1; c.next := NIL;
  RETURN c
END NewCluster;

(* Puts cluster c in the graph, after those there: a cluster must be
   added after those it holds *)
PROCEDURE AddCluster*(c: Cluster);
BEGIN
  c.index := g.nClusters; INC(g.nClusters);
  IF g.clusters = NIL THEN g.clusters := c ELSE g.lastCluster.next := c END;
  g.lastCluster := c
END AddCluster;

(* Ends the graph: a node with no label is labelled with its id, and
   the edges get the diagram's curve: linkStyle default's, or a
   flowchart's configuration's, or else Basis *)
PROCEDURE Finish*;
  VAR e: Edge; n: Node; q: Y.Pair;
BEGIN
  n := g.nodes;
  WHILE n # NIL DO
    IF n.label = NIL THEN n.label := PlainLabel(n.id) END;
    n := n.next
  END;
  IF defaultCurve # DefaultCurve THEN g.curve := defaultCurve
  ELSIF g.kind = Flowchart THEN
    q := Y.Find(g.config, "config.flowchart.curve");
    IF q # NIL THEN g.curve := Curve(q.value, q.pos) END
  END;
  e := g.edges;
  WHILE e # NIL DO
    IF e.curve = DefaultCurve THEN e.curve := g.curve END;
    e := e.next
  END;
  IF defaultLinkStyle # NIL THEN
    e := g.edges;
    WHILE e # NIL DO
      IF e.style = NIL THEN e.style := defaultLinkStyle END;
      e := e.next
    END
  END
END Finish;

(* Moves s past the front matter, if there is one, and what is between
   statements: to the diagram's first word *)
PROCEDURE SkipFrontMatter*(s: L.Scanner);
BEGIN
  sc := s; FrontMatter(FALSE); sc.SkipSpace
END SkipFrontMatter;

(* Whether the scanner's text, after front matter and comments, starts
   with "flowchart" or "graph" *)
PROCEDURE IsFlowchart*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  sc := s; save := sc.pos;
  FrontMatter(FALSE); sc.SkipSpace;
  r := sc.LookingAtWord("flowchart") OR sc.LookingAtWord("graph") OR sc.LookingAtWord("flowchart-elk")
    OR sc.LookingAt("flowchart-elk");
  sc.pos := save;
  RETURN r
END IsFlowchart;

(* Reads the flowchart in s's text into g *)
PROCEDURE Read*(s: L.Scanner; VAR graph: Graph);
BEGIN
  Begin(s, Flowchart, graph);
  IF sc.Accept("flowchart-elk") OR sc.Accept("flowchart") OR sc.Accept("graph") THEN
    IF ~sc.AtStatementEnd() THEN g.dir := Direction() END;
    IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END
  ELSE sc.Error("expected flowchart or graph")
  END;
  LOOP
    sc.SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  IF current # NIL THEN sc.Error('a subgraph has no "end"') END;
  Finish
END Read;

BEGIN
  NEW(buf, 256); bufLen := 0; breaks := TRUE
END PmFlow.
