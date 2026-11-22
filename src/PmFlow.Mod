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

IMPORT PmIO, L := PmLex;

CONST
  (* directions *)
  TB* = 0; BT* = 1; LR* = 2; RL* = 3; NoDir* = -1;

  (* node shapes *)
  Rect* = 0; Round* = 1; Stadium* = 2; Subroutine* = 3; Cylinder* = 4;
  Circle* = 5; Asymmetric* = 6; Diamond* = 7; Hexagon* = 8;
  LeanRight* = 9; LeanLeft* = 10; Trapezoid* = 11; InvTrapezoid* = 12;
  DoubleCircle* = 13;

  (* edge ends *)
  None* = 0; Arrow* = 1; CircleEnd* = 2; Cross* = 3;

  (* edge lines *)
  Normal* = 0; Thick* = 1; Dotted* = 2; Invisible* = 3;

TYPE
  Str* = L.Str;

  (* A line of a label *)
  Line* = POINTER TO LineDesc;
  LineDesc* = RECORD
    text*: Str;
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

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    id*: Str;
    label*: Label;      (* the id when no text was given *)
    shape*: INTEGER;
    classes*: Name;     (* class and ::: names, in order *)
    style*: Prop;       (* style statements' properties, in order *)
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
    mentioned: NodeList; (* the nodes its statements mention *)
    lastMentioned: NodeList;
    index*: INTEGER;    (* from 0, in order of their "end" *)
    next*: Cluster
  END;

  Edge* = POINTER TO EdgeDesc;
  EdgeDesc* = RECORD
    from*, to*: Node;
    label*: Label;      (* NIL for none *)
    head*, tail*: INTEGER; (* the ends at to and at from *)
    line*: INTEGER;
    length*: INTEGER;   (* 1, or more for a longer arrow *)
    style*: Prop;       (* from linkStyle *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Edge
  END;

  Graph* = POINTER TO GraphDesc;
  GraphDesc* = RECORD
    dir*: INTEGER;
    nodes*: Node; nNodes*: INTEGER;
    edges*: Edge; nEdges*: INTEGER;
    clusters*: Cluster; nClusters*: INTEGER; (* in order of their "end" *)
    classDefs*: ClassDef;
    lastNode: Node; lastEdge: Edge; lastCluster: Cluster; lastClassDef: ClassDef
  END;

  (* What an arrow says *)
  ArrowDesc = RECORD
    head, tail, line, length: INTEGER;
    label: Label
  END;

VAR
  sc: L.Scanner;
  g: Graph;
  current: Cluster;      (* the subgraph being read, or NIL *)
  autoIds: INTEGER;      (* subgraphs given an id *)
  defaultLinkStyle: Prop;
  buf: L.Str;            (* text being decoded *)
  bufLen: LONGINT;

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
  NEW(l); l.text := L.Sub(buf^, start, end - start); l.next := NIL;
  IF lab.lines = NIL THEN lab.lines := l
  ELSE p := lab.lines; WHILE p.next # NIL DO p := p.next END; p.next := l
  END;
  INC(lab.n);
  bufLen := 0
END AddLine;

(* The label of t[start .. end-1], decoded; quoted says it was in
   quotation marks, where "`...`" makes a markdown string *)
PROCEDURE MakeLabel(VAR t: ARRAY OF CHAR; start, end: LONGINT; quoted: BOOLEAN): Label;
  VAR lab: Label; i, n: LONGINT;
BEGIN
  NEW(lab); lab.lines := NIL; lab.n := 0; lab.markdown := FALSE;
  IF quoted & (end - start >= 2) & (t[start] = "`") & (t[end - 1] = "`") THEN
    lab.markdown := TRUE; INC(start); DEC(end)
  END;
  bufLen := 0; i := start;
  WHILE i < end DO
    n := Br(t, i, end);
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
  RETURN lab
END MakeLabel;

(* A label of one line, s *)
PROCEDURE PlainLabel(s: Str): Label;
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
PROCEDURE Props(s: Str): Prop;
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
PROCEDURE AppendProps(VAR a: Prop; b: Prop);
  VAR p: Prop;
BEGIN
  IF a = NIL THEN a := b
  ELSE p := a; WHILE p.next # NIL DO p := p.next END; p.next := b
  END
END AppendProps;

(* The model *)

(* The node id, made if it is new *)
PROCEDURE GetNode(id: Str): Node;
  VAR n: Node;
BEGIN
  n := g.nodes;
  WHILE (n # NIL) & ~L.Equal(n.id, id) DO n := n.next END;
  IF n = NIL THEN
    NEW(n); n.id := id; n.label := NIL; n.shape := Rect; n.classes := NIL;
    n.style := NIL; n.cluster := NIL; n.index := g.nNodes; n.next := NIL;
    INC(g.nNodes);
    IF g.nodes = NIL THEN g.nodes := n ELSE g.lastNode.next := n END;
    g.lastNode := n
  END;
  RETURN n
END GetNode;

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

PROCEDURE AddClass(n: Node; name: Str);
  VAR c, p: Name;
BEGIN
  NEW(c); c.name := name; c.next := NIL;
  IF n.classes = NIL THEN n.classes := c
  ELSE p := n.classes; WHILE p.next # NIL DO p := p.next END; p.next := c
  END
END AddClass;

PROCEDURE AddEdge(from, to: Node; VAR a: ArrowDesc);
  VAR e: Edge;
BEGIN
  NEW(e); e.from := from; e.to := to; e.label := a.label;
  e.head := a.head; e.tail := a.tail; e.line := a.line; e.length := a.length;
  e.style := NIL; e.index := g.nEdges; e.next := NIL;
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
  ELSIF sc.LookingAt("@{") THEN sc.Error("the @{ ... } form of a node is not supported yet"); shape := Rect
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

(* A node, with its shape and classes *)
PROCEDURE NodeRef(): Node;
  VAR id, cls: Str; n: Node;
BEGIN
  id := Id();
  IF id = NIL THEN sc.Error("expected a node"); RETURN NIL END;
  n := GetNode(id);
  Shape(n);
  IF sc.Accept(":::") THEN
    cls := sc.Word();
    IF cls = NIL THEN sc.Error("expected a class name") END;
    AddClass(n, cls)
  END;
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

(* Reads a link with its text, if there is one there *)
PROCEDURE Link(VAR a: ArrowDesc): BOOLEAN;
  VAR save, start, end: LONGINT; opens, dummy: BOOLEAN; line: INTEGER; ch: CHAR;
BEGIN
  save := sc.pos;
  sc.SkipBlanks;
  a.tail := None; a.head := None; a.label := NIL; a.length := 1;
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
      WHILE r # NIL DO AddEdge(l.node, r.node, a); r := r.next END;
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
PROCEDURE ClassDefStmt;
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

(* "class a,b name" *)
PROCEDURE ClassStmt;
  VAR ids: ARRAY 64 OF Node; n, i: INTEGER; name, id: Str;
BEGIN
  n := 0;
  LOOP
    sc.SkipBlanks;
    id := Id();
    IF id = NIL THEN sc.Error("expected a node id") END;
    IF n < LEN(ids) THEN ids[n] := GetNode(id); INC(n) END;
    sc.SkipBlanks;
    IF ~sc.Accept(",") THEN EXIT END
  END;
  name := sc.Rest();
  IF name[0] = 0X THEN sc.Error("expected a class name") END;
  FOR i := 0 TO n - 1 DO AddClass(ids[i], name) END
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

(* "linkStyle 0,1 props" or "linkStyle default props" *)
PROCEDURE LinkStyleStmt;
  VAR nums: ARRAY 256 OF INTEGER; n, i, k: INTEGER; props: Str; e: Edge;
BEGIN
  sc.SkipBlanks;
  n := 0;
  IF sc.LookingAtWord("default") THEN
    INC(sc.pos, 7);
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
    props := sc.Rest();
    FOR i := 0 TO n - 1 DO
      e := g.edges;
      WHILE (e # NIL) & (e.index # nums[i]) DO e := e.next END;
      IF e = NIL THEN sc.Error("linkStyle names an edge that is not there") END;
      AppendProps(e.style, Props(props))
    END
  END
END LinkStyleStmt;

(* "accTitle: text", "accDescr: text" and "accDescr { ... }" are for
   readers of the web page; they are skipped *)
PROCEDURE Accessibility;
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
  ELSIF sc.LookingAtWord("click") THEN sc.SkipLine
  ELSIF sc.LookingAtWord("accTitle") OR sc.LookingAtWord("accDescr") THEN Accessibility
  ELSIF sc.LookingAtWord("direction") THEN
    INC(sc.pos, 9);
    IF current # NIL THEN current.dir := Direction() ELSE g.dir := Direction() END;
    IF ~sc.AtStatementEnd() THEN sc.Error("unexpected text") END
  ELSE Chain
  END
END Statement;

(* Skips a front matter block, "---" lines around YAML, if the text
   starts with one *)
PROCEDURE FrontMatter;
BEGIN
  sc.SkipBlanks;
  IF sc.LookingAt("---") THEN
    sc.SkipLine;
    LOOP
      IF sc.AtEnd() THEN sc.Error("the front matter has no closing ---") END;
      INC(sc.pos);
      IF sc.LookingAt("---") THEN sc.SkipLine; EXIT END;
      sc.SkipLine
    END
  END
END FrontMatter;

(* Whether the scanner's text, after front matter and comments, starts
   with "flowchart" or "graph" *)
PROCEDURE IsFlowchart*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  sc := s; save := sc.pos;
  FrontMatter; sc.SkipSpace;
  r := sc.LookingAtWord("flowchart") OR sc.LookingAtWord("graph") OR sc.LookingAtWord("flowchart-elk")
    OR sc.LookingAt("flowchart-elk");
  sc.pos := save;
  RETURN r
END IsFlowchart;

(* Reads the flowchart in s's text into g *)
PROCEDURE Read*(s: L.Scanner; VAR graph: Graph);
  VAR e: Edge; n: Node;
BEGIN
  sc := s; current := NIL; autoIds := 0; defaultLinkStyle := NIL;
  NEW(g); g.dir := TB; g.nodes := NIL; g.nNodes := 0; g.edges := NIL; g.nEdges := 0;
  g.clusters := NIL; g.nClusters := 0; g.classDefs := NIL;
  FrontMatter; sc.SkipSpace;
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
  n := g.nodes;
  WHILE n # NIL DO
    IF n.label = NIL THEN n.label := PlainLabel(n.id) END;
    n := n.next
  END;
  IF defaultLinkStyle # NIL THEN
    e := g.edges;
    WHILE e # NIL DO
      IF e.style = NIL THEN e.style := defaultLinkStyle END;
      e := e.next
    END
  END;
  graph := g
END Read;

BEGIN
  NEW(buf, 256); bufLen := 0
END PmFlow.
