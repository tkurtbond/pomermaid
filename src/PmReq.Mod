MODULE PmReq;
(* PmReq: Mermaid's requirement diagrams (`requirementDiagram`), read
   into PmFlow's model, which the layout and the writers take as they
   take a flowchart.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   requirement/parser/requirementDiagram.jison, and what
   requirementDb.ts makes of it:

   - statements end at a line end; "%%" and "#" start a comment;
     keywords are read in any case, as Mermaid's lexer reads them;
   - "requirement name {" (or functionalRequirement,
     interfaceRequirement, performanceRequirement, physicalRequirement,
     designConstraint), with ":::classes" before the "{" or not, then
     lines "id: ...", "text: ...", "risk: low|medium|high" and
     "verifyMethod: analysis|demonstration|inspection|test", any of
     them, and "}", defines a requirement;
   - "element name {", with the lines "type: ..." and "docref: ...",
     defines an element;
   - a name is text in quotation marks, or a word character and what
     follows it up to ":", ",", "{", "<", ">", "-", "=" or the line's
     end, without blanks at its ends; a value is text in quotation
     marks or the rest of its line;
   - the first definition of a name is kept, later ones are read and
     ignored;
   - "a - verb -> b" and "b <- verb - a" are relationships from a to b,
     where verb is contains, copies, derives, satisfies, verifies,
     refines or traces; a and b must be defined, before or after;
   - "direction TB" (BT, LR, RL) anywhere in a statement's line is the
     diagram's direction, as Mermaid's lexer has it;
   - classDef, class, style and "name:::classes" act as in Mermaid, on
     the requirements and elements defined before them; accTitle and
     accDescr are skipped.

   Each requirement and element is a box, F.ReqBox: its type in
   guillemets ("<<Requirement>>", "<<Element>>"), the node's
   annotation; its name, bold, the node's label; and its fields, one
   to a line ("ID: ...", "Text: ...", "Risk: ...", "Verification: ...",
   "Type: ...", "Doc Ref: ..."), the node's members. All of it is read
   as markdown. The requirements come first in the graph, then the
   elements, as requirementDb.ts's getData has them.

   Mermaid reads a value without quotation marks as a word, which
   cannot have ":" or "," in it and cannot be a keyword ("test", "low",
   "type" ...); here it is the rest of the line. *)

IMPORT L := PmLex, F := PmFlow, C := PmClass;

CONST
  NoField = -1;
  (* fields *)
  Id = 0; Text = 1; Risk = 2; Verify = 3; EType = 4; DocRef = 5;

TYPE
  Str = L.Str;

  (* A requirement or element, as defined *)
  Def = POINTER TO DefDesc;
  DefDesc = RECORD
    node: F.Node;
    element: BOOLEAN;
    type: Str;           (* a requirement's type, as Mermaid shows it *)
    field: ARRAY 6 OF Str; (* by Id ...; NIL if not given *)
    next: Def
  END;

  Relation = POINTER TO RelationDesc;
  RelationDesc = RECORD
    src, dst: Str;
    srcPos, dstPos: LONGINT; (* where they are named *)
    verb: Str;
    next: Relation
  END;

VAR
  sc: L.Scanner;
  g: F.Graph;
  defs, lastDef: Def;
  relations, lastRelation: Relation;

(* Text *)

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether the text at the position is w, which is in lower case, in
   any case *)
PROCEDURE LookingAtI(w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF Lower(sc.Peek(i)) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END LookingAtI;

(* Whether the text at the position is the keyword w, in any case, not
   followed by a word character *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN LookingAtI(w) & ~L.IsWordChar(sc.Peek(L.Length(w)))
END Kw;

(* Skips blanks, line ends, and "%%" and "#" comments and directives *)
PROCEDURE SkipSpace;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF sc.Ch() = 0AX THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSIF sc.Ch() = "#" THEN sc.SkipLine
    ELSE EXIT
    END
  END
END SkipSpace;

(* Whether the statement ends here, after blanks: at a line end, a
   comment or the end *)
PROCEDURE AtEnd(): BOOLEAN;
BEGIN
  sc.SkipBlanks;
  RETURN sc.AtEnd() OR (sc.Ch() = 0AX) OR sc.LookingAt("%%") OR (sc.Ch() = "#")
END AtEnd;

PROCEDURE ExpectEnd;
BEGIN
  IF ~AtEnd() THEN sc.Error("unexpected text") END
END ExpectEnd;

(* A string in quotation marks, which the position is at, without them *)
PROCEDURE Quoted(): Str;
  VAR start: LONGINT;
BEGIN
  INC(sc.pos); start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 22X) DO INC(sc.pos) END;
  IF sc.AtEnd() THEN sc.ErrorAt(start - 1, "unterminated string") END;
  INC(sc.pos);
  RETURN L.Sub(sc.t^, start, sc.pos - 1 - start)
END Quoted;

(* A name at the position: text in quotation marks, or a word
   character and what follows it up to ":", ",", "{", "<", ">", "-",
   "=" or a line end, without blanks at its end; NIL if there is none *)
PROCEDURE Name(): Str;
  VAR start, end: LONGINT; ch: CHAR;
BEGIN
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN RETURN Quoted() END;
  IF ~L.IsWordChar(sc.Ch()) THEN RETURN NIL END;
  start := sc.pos;
  LOOP
    ch := sc.Ch();
    IF sc.AtEnd() OR (ch = ":") OR (ch = ",") OR (ch = "{") OR (ch = "<") OR (ch = ">")
       OR (ch = "-") OR (ch = "=") OR (ch = 0AX) THEN EXIT
    END;
    INC(sc.pos)
  END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  RETURN L.Sub(sc.t^, start, end - start)
END Name;

(* A name, which must be there *)
PROCEDURE MustName(what: ARRAY OF CHAR): Str;
  VAR s: Str;
BEGIN
  s := Name();
  IF s = NIL THEN sc.Error(what) END;
  RETURN s
END MustName;

(* A field's value: text in quotation marks, or the rest of the line
   without blanks at its ends *)
PROCEDURE Value(): Str;
  VAR start, end: LONGINT; s: Str;
BEGIN
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN s := Quoted(); ExpectEnd; RETURN s END;
  start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) DO INC(sc.pos) END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  RETURN L.Sub(sc.t^, start, end - start)
END Value;

(* Names, "a,b" or "a, b", of nodes or style classes: words with ","
   between them *)
PROCEDURE IdList(what: ARRAY OF CHAR): Str;
  VAR r: Str; start: LONGINT;
BEGIN
  r := NIL;
  LOOP
    sc.SkipBlanks; start := sc.pos;
    WHILE ~sc.AtEnd() & (L.IsWordChar(sc.Ch()) OR (sc.Ch() = "-")) DO INC(sc.pos) END;
    IF sc.pos = start THEN sc.Error(what) END;
    IF r = NIL THEN r := L.Sub(sc.t^, start, sc.pos - start)
    ELSE r := C.CatS(C.Cat(r, ","), L.Sub(sc.t^, start, sc.pos - start))
    END;
    sc.SkipBlanks;
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos)
  END;
  RETURN r
END IdList;

(* The model *)

(* Gives the nodes named in names, "a,b", the style classes in classes,
   "c,d" *)
PROCEDURE SetClass(names, classes: Str);
  VAR i, start, k, kstart: LONGINT; id: Str; n: F.Node;
BEGIN
  i := 0;
  LOOP
    start := i;
    WHILE (names[i] # 0X) & (names[i] # ",") DO INC(i) END;
    id := L.Sub(names^, start, i - start);
    n := F.FindNode(id^);
    IF n # NIL THEN
      k := 0;
      LOOP
        kstart := k;
        WHILE (classes[k] # 0X) & (classes[k] # ",") DO INC(k) END;
        IF k > kstart THEN F.AddClass(n, L.Sub(classes^, kstart, k - kstart)) END;
        IF classes[k] = 0X THEN EXIT END;
        INC(k)
      END
    END;
    IF names[i] = 0X THEN EXIT END;
    INC(i)
  END
END SetClass;

(* Statements *)

(* The field named at the position, taken, of a requirement or an
   element; NoField if there is none *)
PROCEDURE Field(element: BOOLEAN): INTEGER;
  VAR f: INTEGER;

  PROCEDURE Is(w: ARRAY OF CHAR; k: INTEGER): BOOLEAN;
  BEGIN
    IF Kw(w) THEN INC(sc.pos, L.Length(w)); f := k; RETURN TRUE END;
    RETURN FALSE
  END Is;

BEGIN
  f := NoField;
  IF element THEN
    IF Is("type", EType) OR Is("docref", DocRef) THEN END
  ELSIF Is("id", Id) OR Is("text", Text) OR Is("risk", Risk) OR Is("verifymethod", Verify) THEN
  END;
  RETURN f
END Field;

(* The word, in any case, at the position that is one of words, "a,b",
   taken, and given as names has it, "A,B"; NIL if there is none *)
PROCEDURE OneOf(words, names: ARRAY OF CHAR): Str;
  VAR i, k, start, kstart: LONGINT; w: ARRAY 32 OF CHAR;
BEGIN
  i := 0; k := 0;
  LOOP
    start := i;
    WHILE (words[i] # 0X) & (words[i] # ",") DO w[i - start] := words[i]; INC(i) END;
    w[i - start] := 0X;
    kstart := k;
    WHILE (names[k] # 0X) & (names[k] # ",") DO INC(k) END;
    IF Kw(w) THEN INC(sc.pos, i - start); RETURN L.Sub(names, kstart, k - kstart) END;
    IF words[i] = 0X THEN EXIT END;
    INC(i); INC(k)
  END;
  RETURN NIL
END OneOf;

(* A definition's body, from after its "{" to its "}" *)
PROCEDURE Body(d: Def);
  VAR open: LONGINT; f: INTEGER; v: Str;
BEGIN
  open := sc.pos - 1;
  ExpectEnd;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN sc.ErrorAt(open, "a definition has no }") END;
    IF sc.Ch() = "}" THEN INC(sc.pos); EXIT END;
    f := Field(d.element);
    IF f = NoField THEN
      IF d.element THEN sc.Error("expected type or docref")
      ELSE sc.Error("expected id, text, risk or verifyMethod")
      END
    END;
    sc.SkipBlanks;
    IF ~sc.Accept(":") THEN sc.Error("expected :") END;
    sc.SkipBlanks;
    IF f = Risk THEN
      v := OneOf("low,medium,high", "Low,Medium,High");
      IF v = NIL THEN sc.Error("expected low, medium or high") END;
      ExpectEnd
    ELSIF f = Verify THEN
      v := OneOf("analysis,demonstration,inspection,test", "Analysis,Demonstration,Inspection,Test");
      IF v = NIL THEN sc.Error("expected analysis, demonstration, inspection or test") END;
      ExpectEnd
    ELSE v := Value()
    END;
    d.field[f] := v
  END
END Body;

(* A requirement of type type, or an element (type NIL), after its
   keyword: "name [:::classes] { ... }" *)
PROCEDURE Definition(type: ARRAY OF CHAR; element: BOOLEAN);
  VAR d: Def; name, classes: Str; i: INTEGER;
BEGIN
  name := MustName("expected a name");
  sc.SkipBlanks; classes := NIL;
  IF sc.Accept(":::") THEN classes := IdList("expected a style class's name"); sc.SkipBlanks END;
  IF ~sc.Accept("{") THEN sc.Error("expected {") END;
  NEW(d); d.element := element; d.type := L.New(type); d.next := NIL;
  FOR i := 0 TO LEN(d.field) - 1 DO d.field[i] := NIL END;
  Body(d);
  IF F.FindNode(name^) = NIL THEN
    d.node := F.GetNode(name); d.node.shape := F.ReqBox;
    IF defs = NIL THEN defs := d ELSE lastDef.next := d END;
    lastDef := d;
    IF classes # NIL THEN SetClass(name, classes) END
  END
END Definition;

(* "a - verb -> b", "b <- verb - a", or "a:::classes", after its first
   name, a, found at pos *)
PROCEDURE Relationship(a: Str; pos: LONGINT);
  VAR r: Relation; left: BOOLEAN; b, verb: Str; bpos: LONGINT;
BEGIN
  sc.SkipBlanks;
  IF sc.Accept(":::") THEN SetClass(a, IdList("expected a style class's name")); ExpectEnd; RETURN END;
  IF sc.Accept("<-") THEN left := TRUE
  ELSIF sc.Accept("-") THEN left := FALSE
  ELSE sc.Error("expected - or <-")
  END;
  sc.SkipBlanks;
  verb := OneOf("contains,copies,derives,satisfies,verifies,refines,traces",
    "contains,copies,derives,satisfies,verifies,refines,traces");
  IF verb = NIL THEN
    sc.Error("expected contains, copies, derives, satisfies, verifies, refines or traces")
  END;
  sc.SkipBlanks;
  IF left THEN
    IF ~sc.Accept("-") OR (sc.Ch() = ">") THEN sc.Error("expected -") END
  ELSIF ~sc.Accept("->") THEN sc.Error("expected ->")
  END;
  sc.SkipBlanks; bpos := sc.pos;
  b := MustName("expected a name");
  ExpectEnd;
  NEW(r); r.verb := verb; r.next := NIL;
  IF left THEN r.src := b; r.srcPos := bpos; r.dst := a; r.dstPos := pos
  ELSE r.src := a; r.srcPos := pos; r.dst := b; r.dstPos := bpos
  END;
  IF relations = NIL THEN relations := r ELSE lastRelation.next := r END;
  lastRelation := r
END Relationship;

(* "style ids props" *)
PROCEDURE Style;
  VAR ids, id, props: Str; i, start: LONGINT; n: F.Node;
BEGIN
  ids := IdList("expected a name");
  props := sc.Rest();
  i := 0;
  LOOP
    start := i;
    WHILE (ids[i] # 0X) & (ids[i] # ",") DO INC(i) END;
    id := L.Sub(ids^, start, i - start);
    n := F.FindNode(id^);
    IF n # NIL THEN F.AppendProps(n.style, F.Props(props)) END;
    IF ids[i] = 0X THEN EXIT END;
    INC(i)
  END;
  IF sc.Ch() = ";" THEN INC(sc.pos) END;
  ExpectEnd
END Style;

(* "class ids classes" *)
PROCEDURE ClassStmt;
  VAR ids: Str;
BEGIN
  ids := IdList("expected a name");
  SetClass(ids, IdList("expected a style class's name"));
  ExpectEnd
END ClassStmt;

(* Whether the line from the position has "direction TB" (BT, LR, RL)
   in it, in any case; if so, sets the diagram's direction and skips
   the line *)
PROCEDURE Direction(): BOOLEAN;
  VAR save, k: LONGINT; d: INTEGER;
BEGIN
  save := sc.pos; d := F.NoDir;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & (d = F.NoDir) DO
    IF LookingAtI("direction") & L.IsBlank(sc.Peek(9)) THEN
      k := 9; WHILE L.IsBlank(sc.Peek(k)) DO INC(k) END;
      INC(sc.pos, k);
      IF LookingAtI("tb") THEN d := F.TB ELSIF LookingAtI("bt") THEN d := F.BT
      ELSIF LookingAtI("lr") THEN d := F.LR ELSIF LookingAtI("rl") THEN d := F.RL
      END
    ELSE INC(sc.pos)
    END
  END;
  IF d = F.NoDir THEN sc.pos := save; RETURN FALSE END;
  g.dir := d; sc.SkipLine;
  RETURN TRUE
END Direction;

PROCEDURE Statement;
  VAR pos: LONGINT; a: Str;
BEGIN
  IF Direction() THEN
  ELSIF Kw("requirement") THEN INC(sc.pos, 11); Definition("Requirement", FALSE)
  ELSIF Kw("functionalrequirement") THEN INC(sc.pos, 21); Definition("Functional Requirement", FALSE)
  ELSIF Kw("interfacerequirement") THEN INC(sc.pos, 20); Definition("Interface Requirement", FALSE)
  ELSIF Kw("performancerequirement") THEN INC(sc.pos, 22); Definition("Performance Requirement", FALSE)
  ELSIF Kw("physicalrequirement") THEN INC(sc.pos, 19); Definition("Physical Requirement", FALSE)
  ELSIF Kw("designconstraint") THEN INC(sc.pos, 16); Definition("Design Constraint", FALSE)
  ELSIF Kw("element") THEN INC(sc.pos, 7); Definition("Element", TRUE)
  ELSIF Kw("classdef") THEN INC(sc.pos, 8); F.ClassDefStmt; IF sc.Ch() = ";" THEN INC(sc.pos) END; ExpectEnd
  ELSIF Kw("class") THEN INC(sc.pos, 5); ClassStmt
  ELSIF Kw("style") THEN INC(sc.pos, 5); Style
  ELSIF Kw("title") THEN sc.Error("a requirement diagram has no title statement")
  ELSIF LookingAtI("acctitle") OR LookingAtI("accdescr") THEN F.Accessibility
  ELSE
    pos := sc.pos;
    a := MustName("expected a requirement, an element or a relationship");
    Relationship(a, pos)
  END
END Statement;

(* The label of s, markdown *)
PROCEDURE Markdown(s: Str): F.Label;
BEGIN
  RETURN F.MarkdownLabel(s^, 0, L.Length(s^))
END Markdown;

(* Makes lab's lines bold *)
PROCEDURE Embolden(lab: F.Label);
  VAR l: F.Line; i, n: LONGINT;
BEGIN
  l := lab.lines;
  WHILE l # NIL DO
    n := L.Length(l.text^);
    IF l.style = NIL THEN
      NEW(l.style, n + 1);
      FOR i := 0 TO n DO l.style[i] := F.Roman END
    END;
    FOR i := 0 TO n - 1 DO IF ~ODD(l.style[i]) THEN INC(l.style[i], F.Bold) END END;
    l := l.next
  END
END Embolden;

(* The box's labels: d's type in guillemets, its name in bold, and its
   fields *)
PROCEDURE Labels(d: Def);
  VAR n: F.Node; body: Str; nl: ARRAY 2 OF CHAR;

  PROCEDURE Add(k: INTEGER; prefix: ARRAY OF CHAR);
  BEGIN
    IF (d.field[k] # NIL) & (d.field[k][0] # 0X) THEN
      IF body = NIL THEN body := L.New(prefix) ELSE body := C.Cat(C.Cat(body, nl), prefix) END;
      body := C.CatS(body, d.field[k])
    END
  END Add;

BEGIN
  n := d.node; nl[0] := 0AX; nl[1] := 0X;
  n.annotation := Markdown(C.Cat(C.Cat(L.New("<<"), d.type^), ">>"));
  n.label := Markdown(n.id);
  Embolden(n.label);
  body := NIL;
  IF d.element THEN Add(EType, "Type: "); Add(DocRef, "Doc Ref: ")
  ELSE Add(Id, "ID: "); Add(Text, "Text: "); Add(Risk, "Risk: "); Add(Verify, "Verification: ")
  END;
  IF body # NIL THEN n.members := Markdown(body) END
END Labels;

(* The node named name, which must be defined; pos is where it is
   named *)
PROCEDURE Named(name: Str; pos: LONGINT): F.Node;
  VAR n: F.Node;
BEGIN
  n := F.FindNode(name^);
  IF n = NIL THEN sc.ErrorAt(pos, "no requirement or element has this name") END;
  RETURN n
END Named;

(* The end: the boxes' labels; the requirements, then the elements, in
   the graph; the relationships are the edges *)
PROCEDURE Finish;
  VAR d: Def; r: Relation; e: F.Edge; first, last: F.Node; elements: BOOLEAN;
    from, to: F.Node; lab: F.Label;
BEGIN
  first := NIL; last := NIL;
  elements := FALSE;
  LOOP
    d := defs;
    WHILE d # NIL DO
      IF d.element = elements THEN
        Labels(d);
        IF first = NIL THEN first := d.node ELSE last.next := d.node END;
        last := d.node
      END;
      d := d.next
    END;
    IF elements THEN EXIT END;
    elements := TRUE
  END;
  IF last # NIL THEN last.next := NIL END;
  F.SetNodes(first);
  r := relations;
  WHILE r # NIL DO
    from := Named(r.src, r.srcPos); to := Named(r.dst, r.dstPos);
    lab := Markdown(C.Cat(C.Cat(L.New("<<"), r.verb^), ">>"));
    IF L.Is(r.verb, "contains") THEN
      e := F.NewEdge(from, to, F.None, F.ReqContains, F.Normal, lab)
    ELSE
      e := F.NewEdge(from, to, F.ReqArrow, F.None, F.Dotted, lab)
    END;
    r := r.next
  END;
  F.Finish
END Finish;

(* Whether the scanner's text, after front matter and comments, starts
   with "requirementDiagram" *)
PROCEDURE IsReq*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s;
  r := Kw("requirementdiagram");
  s.pos := save;
  RETURN r
END IsReq;

(* Reads the requirement diagram in s's text into graph *)
PROCEDURE Read*(s: L.Scanner; VAR graph: F.Graph);
BEGIN
  F.Begin(s, F.Req, g); graph := g; sc := s;
  defs := NIL; lastDef := NIL; relations := NIL; lastRelation := NIL;
  IF ~Kw("requirementdiagram") THEN sc.Error("expected requirementDiagram") END;
  INC(sc.pos, 18);
  ExpectEnd;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Finish
END Read;

END PmReq.
