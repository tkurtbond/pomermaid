MODULE PmEr;
(* PmEr: Mermaid's entity relationship diagrams (`erDiagram`), read
   into PmFlow's model, which the layout and the writers take as they
   take a flowchart.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   er/parser/erDiagram.jison, and what erDb.ts makes of it:

   - statements end at a line end; "%%" starts a comment; keywords and
     cardinalities are read in any case, as Mermaid's lexer reads them;
   - an entity's name is letters, digits, "_", "-", "*", "." and UTF-8,
     or text in quotation marks without "%" or "\";
   - "A ||--o{ B : role" is a relationship: a cardinality at each end
     ("|o", "||", "}o", "}|" and their mirror images, or words: "one or
     zero", "zero or one", "one", "only one", "1", "zero or more",
     "zero or many", "many", "many(0)", "0+", "one or more", "one or
     many", "many(1)", "1+"; "u", a parent, is drawn with no marker), a
     line, "--" or "to" (identifying, solid), "..", ".-", "-." or
     "optionally to" (non-identifying, dashed), and a role, a word or
     text in quotation marks, which must be there;
   - "A", "A[alias]", with ":::classes" and "{ attributes }" or not,
     declares an entity: its box is titled with its alias, if it has
     one, or its name; each attribute is a type ("string", "string?",
     "List~T~", shown as "List<T>"), a name, keys (PK, FK and UK, with
     "," between them) and a comment in quotation marks, the last two
     optional, drawn as a row of the box's table;
   - "subgraph id [title words]" ... "end" holds the entities its
     statements name and the subgraphs in it, but not those an earlier
     subgraph holds, as erDb.ts's makeUniq has it;
   - "direction TB" (BT, LR, RL) is the diagram's direction, or, in a
     subgraph, that subgraph's;
   - classDef, class, style and ":::" act as in Mermaid, on entities and
     subgraphs declared before them; accTitle and accDescr are skipped.

   Keywords and cardinalities are whole words here, where Mermaid's
   lexer takes the "one" of "oneway" as a cardinality and the "class"
   of "classroom" as the keyword. *)

IMPORT L := PmLex, F := PmFlow, C := PmClass;

TYPE
  Str = L.Str;

  (* An entity, or a subgraph, a statement in a subgraph names *)
  Item = POINTER TO ItemDesc;
  ItemDesc = RECORD
    name: Str;
    next: Item
  END;

  (* A subgraph being read *)
  Frame = POINTER TO FrameDesc;
  FrameDesc = RECORD
    id, title: Str;
    dir: INTEGER;
    items, lastItem: Item;
    open: LONGINT;     (* where its "subgraph" was *)
    outer: Frame
  END;

  (* What subgraph holds an entity, or a subgraph *)
  Owner = POINTER TO OwnerDesc;
  OwnerDesc = RECORD
    name: Str;
    cluster: F.Cluster;
    next: Owner
  END;

  Relation = POINTER TO RelationDesc;
  RelationDesc = RECORD
    a, b: Str;          (* the entities, left and right *)
    cardA, cardB: INTEGER; (* the ends at a and at b *)
    line: INTEGER;      (* F.Normal or F.Dotted *)
    role: Str;
    next: Relation
  END;

VAR
  sc: L.Scanner;
  g: F.Graph;
  frame: Frame;        (* the innermost subgraph being read, or NIL *)
  owners: Owner;
  relations, lastRelation: Relation;

(* Text *)

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether ch is in an entity's name *)
PROCEDURE IsNameChar(ch: CHAR): BOOLEAN;
BEGIN RETURN L.IsWordChar(ch) OR (ch = "-") OR (ch = "*") OR (ch = ".")
END IsNameChar;

(* Whether the text k bytes from the position starts with a
   relationship's line, "--", "..", ".-" or "-." *)
PROCEDURE LineAt(k: LONGINT): BOOLEAN;
  VAR a, b: CHAR;
BEGIN
  a := sc.Peek(k); b := sc.Peek(k + 1);
  RETURN ((a = "-") OR (a = ".")) & ((b = "-") OR (b = "."))
END LineAt;

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
   followed by a character of a name *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN LookingAtI(w) & ~IsNameChar(sc.Peek(L.Length(w)))
END Kw;

(* Whether the text at the position is the word w, in any case, of a
   relationship: not followed by a character of a name, unless that
   starts a line, "--" *)
PROCEDURE RelWord(w: ARRAY OF CHAR): BOOLEAN;
  VAR n: LONGINT; ch: CHAR;
BEGIN
  n := L.Length(w);
  IF ~LookingAtI(w) THEN RETURN FALSE END;
  ch := w[n - 1];
  IF (ch = "+") OR (ch = ")") THEN RETURN TRUE END;
  RETURN ~IsNameChar(sc.Peek(n)) OR LineAt(n)
END RelWord;

(* Skips blanks, line ends and "%%" comments and directives *)
PROCEDURE SkipSpace;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF sc.Ch() = 0AX THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSE EXIT
    END
  END
END SkipSpace;

(* Whether the statement ends here, after blanks: at a line end, a
   comment or the end *)
PROCEDURE AtEnd(): BOOLEAN;
BEGIN
  sc.SkipBlanks;
  RETURN sc.AtEnd() OR (sc.Ch() = 0AX) OR sc.LookingAt("%%")
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

(* An entity's name, at the position: its letters, or text in
   quotation marks; NIL if there is none *)
PROCEDURE Name(): Str;
  VAR start, i: LONGINT; s: Str;
BEGIN
  IF sc.Ch() = 22X THEN
    start := sc.pos;
    s := Quoted();
    i := 0;
    WHILE s[i] # 0X DO
      IF (s[i] = "%") OR (s[i] = "\") OR (s[i] = 0AX) OR (s[i] = 0DX) THEN
        sc.ErrorAt(start, "an entity's name in quotation marks cannot have %, \ or a line end")
      END;
      INC(i)
    END;
    IF s[0] = 0X THEN sc.ErrorAt(start, "an entity's name cannot be empty") END;
    RETURN s
  END;
  start := sc.pos;
  WHILE ~sc.AtEnd() & IsNameChar(sc.Ch()) DO INC(sc.pos) END;
  IF sc.pos = start THEN RETURN NIL END;
  RETURN L.Sub(sc.t^, start, sc.pos - start)
END Name;

(* An entity's name, which must be there *)
PROCEDURE EntityName(): Str;
  VAR s: Str;
BEGIN
  sc.SkipBlanks;
  s := Name();
  IF s = NIL THEN sc.Error("expected an entity's name") END;
  RETURN s
END EntityName;

(* The model *)

(* The entity name, made if it is new *)
PROCEDURE Entity(name: Str): F.Node;
  VAR n: F.Node;
BEGIN
  n := F.FindNode(name^);
  IF n = NIL THEN
    n := F.GetNode(name); n.shape := F.ErBox; n.label := NIL
  END;
  RETURN n
END Entity;

(* The subgraph id, if it has ended, or NIL *)
PROCEDURE Subgraph(id: Str): F.Cluster;
  VAR c: F.Cluster;
BEGIN
  c := g.clusters;
  WHILE (c # NIL) & ~L.Equal(c.id, id) DO c := c.next END;
  RETURN c
END Subgraph;

(* Records that the statement being read names name, in its subgraph *)
PROCEDURE Mention(name: Str);
  VAR it: Item;
BEGIN
  IF frame # NIL THEN
    NEW(it); it.name := name; it.next := NIL;
    IF frame.items = NIL THEN frame.items := it ELSE frame.lastItem.next := it END;
    frame.lastItem := it
  END
END Mention;

PROCEDURE FindOwner(name: Str): Owner;
  VAR o: Owner;
BEGIN
  o := owners;
  WHILE (o # NIL) & ~L.Equal(o.name, name) DO o := o.next END;
  RETURN o
END FindOwner;

(* Gives the entities and subgraphs named in names, "a,b", the style
   classes in classes, "c,d" *)
PROCEDURE SetClass(names, classes: Str);
  VAR i, start, k, kstart: LONGINT; id: Str; n: F.Node; c: F.Cluster;
BEGIN
  i := 0;
  LOOP
    start := i;
    WHILE (names[i] # 0X) & (names[i] # ",") DO INC(i) END;
    id := L.Sub(names^, start, i - start);
    n := F.FindNode(id^); c := Subgraph(id);
    k := 0;
    LOOP
      kstart := k;
      WHILE (classes[k] # 0X) & (classes[k] # ",") DO INC(k) END;
      IF k > kstart THEN
        IF n # NIL THEN F.AddClass(n, L.Sub(classes^, kstart, k - kstart)) END;
        IF c # NIL THEN F.AddName(c.classes, L.Sub(classes^, kstart, k - kstart)) END
      END;
      IF classes[k] = 0X THEN EXIT END;
      INC(k)
    END;
    IF names[i] = 0X THEN EXIT END;
    INC(i)
  END
END SetClass;

(* Statements *)

(* Names, "a,b" or "a, b", of entities or style classes: words of
   letters, digits, "_", "-" and "*" with "," between them *)
PROCEDURE IdList(what: ARRAY OF CHAR): Str;
  VAR r: Str; start: LONGINT;
BEGIN
  r := NIL;
  LOOP
    sc.SkipBlanks; start := sc.pos;
    WHILE ~sc.AtEnd() & (L.IsWordChar(sc.Ch()) OR (sc.Ch() = "-") OR (sc.Ch() = "*")) DO INC(sc.pos) END;
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

(* A cardinality at the position, an end, F.OnlyOne ... (F.None for a
   parent, "u"), taken; or -1 if there is none *)
PROCEDURE Cardinality(): INTEGER;
  VAR t: INTEGER;

  PROCEDURE Is(w: ARRAY OF CHAR; end: INTEGER): BOOLEAN;
  BEGIN
    IF RelWord(w) THEN INC(sc.pos, L.Length(w)); t := end; RETURN TRUE END;
    RETURN FALSE
  END Is;

  PROCEDURE Sym(w: ARRAY OF CHAR; end: INTEGER): BOOLEAN;
  BEGIN
    IF LookingAtI(w) THEN INC(sc.pos, 2); t := end; RETURN TRUE END;
    RETURN FALSE
  END Sym;

BEGIN
  sc.SkipBlanks; t := -1;
  IF Sym("|o", F.ZeroOrOne) OR Sym("||", F.OnlyOne) OR Sym("}o", F.ZeroOrMore)
     OR Sym("}|", F.OneOrMore) OR Sym("|{", F.OneOrMore)
     OR Sym("o|", F.ZeroOrOne) OR Sym("o{", F.ZeroOrMore) THEN
  ELSIF Is("one or zero", F.ZeroOrOne) OR Is("one or more", F.OneOrMore)
     OR Is("one or many", F.OneOrMore) OR Is("only one", F.OnlyOne)
     OR Is("zero or one", F.ZeroOrOne) OR Is("zero or more", F.ZeroOrMore)
     OR Is("zero or many", F.ZeroOrMore) OR Is("one", F.OnlyOne)
     OR Is("many(0)", F.ZeroOrMore) OR Is("many(1)", F.OneOrMore)
     OR Is("many", F.ZeroOrMore) OR Is("1+", F.OneOrMore) OR Is("0+", F.ZeroOrMore)
     OR Is("1", F.OnlyOne) THEN
  ELSIF (Lower(sc.Ch()) = "u") & ((sc.Peek(1) = ".") OR (sc.Peek(1) = "-") OR (sc.Peek(1) = "|")) THEN
    INC(sc.pos); t := F.None
  END;
  RETURN t
END Cardinality;

(* A relationship's line at the position, F.Normal or F.Dotted; or -1 *)
PROCEDURE RelType(): INTEGER;
BEGIN
  sc.SkipBlanks;
  IF sc.Accept("--") THEN RETURN F.Normal
  ELSIF sc.Accept("..") OR sc.Accept(".-") OR sc.Accept("-.") THEN RETURN F.Dotted
  ELSIF RelWord("to") THEN INC(sc.pos, 2); RETURN F.Normal
  ELSIF RelWord("optionally to") THEN INC(sc.pos, 13); RETURN F.Dotted
  END;
  RETURN -1
END RelType;

(* Whether a relationship starts at the position, after an entity's
   name: a cardinality and a line *)
PROCEDURE AtRelation(): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := sc.pos;
  r := (Cardinality() # -1) & (RelType() # -1);
  sc.pos := save;
  RETURN r
END AtRelation;

(* The rest of a relationship, after its first entity a and its
   classes, or NIL *)
PROCEDURE RelationRest(a, classesA: Str);
  VAR r: Relation; classesB: Str; n: F.Node; start: LONGINT;
BEGIN
  NEW(r); r.a := a; r.next := NIL;
  r.cardA := Cardinality();
  r.line := RelType();
  r.cardB := Cardinality();
  IF r.cardB = -1 THEN sc.Error("expected a cardinality") END;
  r.b := EntityName();
  sc.SkipBlanks; classesB := NIL;
  IF sc.Accept(":::") THEN classesB := IdList("expected a style class's name") END;
  sc.SkipBlanks;
  IF sc.Ch() # ":" THEN sc.Error("expected : and the relationship's role") END;
  INC(sc.pos); sc.SkipBlanks;
  IF sc.Ch() = 22X THEN r.role := Quoted()
  ELSE
    start := sc.pos;
    r.role := Name();
    IF r.role = NIL THEN sc.Error("expected the relationship's role") END
  END;
  ExpectEnd;
  n := Entity(a); n := Entity(r.b);
  IF classesA # NIL THEN SetClass(a, classesA) END;
  IF classesB # NIL THEN SetClass(r.b, classesB) END;
  IF relations = NIL THEN relations := r ELSE lastRelation.next := r END;
  lastRelation := r;
  Mention(a); Mention(r.b)
END RelationRest;

(* An attribute's type or name, at the position: a word, a word with
   "~" in it, to the last "~" on its line, or text in backquotes *)
PROCEDURE AttrWord(what: ARRAY OF CHAR): Str;
  VAR start, i, first, last: LONGINT; ch: CHAR;

  PROCEDURE Space(c: CHAR): BOOLEAN;
  BEGIN RETURN L.IsBlank(c) OR (c = 0AX) OR (c = 0X)
  END Space;

BEGIN
  start := sc.pos; ch := sc.Ch();
  IF ch = "`" THEN
    INC(sc.pos); start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # "`") DO INC(sc.pos) END;
    IF sc.AtEnd() OR (sc.pos = start) THEN sc.ErrorAt(start - 1, "unterminated word in backquotes") END;
    INC(sc.pos);
    RETURN L.Sub(sc.t^, start, sc.pos - 1 - start)
  END;
  (* a "~" in the word, and another after it on the line *)
  i := start; first := -1;
  WHILE ~Space(sc.t[i]) & (i < sc.len) DO
    IF (sc.t[i] = "~") & (first < 0) THEN first := i END;
    INC(i)
  END;
  IF first >= 0 THEN
    i := first + 1; last := -1;
    WHILE (i < sc.len) & (sc.t[i] # 0AX) DO
      IF sc.t[i] = "~" THEN last := i END;
      INC(i)
    END;
    IF last > first THEN
      sc.pos := last + 1;
      WHILE (sc.pos < sc.len) & ~Space(sc.Ch()) DO INC(sc.pos) END;
      RETURN L.Sub(sc.t^, start, sc.pos - start)
    END
  END;
  IF ~(L.IsLetter(ch) OR (ch = "_") OR (ch = "*") OR (ch >= 80X)) THEN sc.Error(what) END;
  INC(sc.pos);
  LOOP
    ch := sc.Ch();
    IF sc.AtEnd() OR ~(L.IsWordChar(ch) OR (ch = "-") OR (ch = "[") OR (ch = "]") OR (ch = "(")
       OR (ch = ")") OR (ch = ".") OR (ch = ",") OR (ch = "*")) THEN EXIT
    END;
    INC(sc.pos)
  END;
  RETURN L.Sub(sc.t^, start, sc.pos - start)
END AttrWord;

(* Whether a key, PK, FK or UK in any case, is at the position *)
PROCEDURE KeyAt(): BOOLEAN;
  VAR a: CHAR;
BEGIN
  a := Lower(sc.Ch());
  RETURN ((a = "p") OR (a = "f") OR (a = "u")) & (Lower(sc.Peek(1)) = "k")
    & ~(L.IsLetter(sc.Peek(2)) OR L.IsDigit(sc.Peek(2)) OR (sc.Peek(2) = "_"))
END KeyAt;

(* The attributes in braces, from after "{", to its "}", added to n *)
PROCEDURE Block(n: F.Node);
  VAR open: LONGINT; a, last: F.Attr; keys: Str;
BEGIN
  open := sc.pos - 1;
  last := n.attrs; IF last # NIL THEN WHILE last.next # NIL DO last := last.next END END;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN sc.ErrorAt(open, "an entity's attributes have no }") END;
    IF sc.Ch() = "}" THEN INC(sc.pos); EXIT END;
    NEW(a); a.keys := NIL; a.comment := NIL; a.next := NIL;
    a.type := AttrWord("expected an attribute's type");
    SkipSpace;
    IF sc.Ch() = "?" THEN INC(sc.pos); a.type := C.Cat(a.type, "?"); SkipSpace END;
    IF sc.AtEnd() OR (sc.Ch() = "}") THEN sc.Error("expected an attribute's name") END;
    a.name := AttrWord("expected an attribute's name");
    SkipSpace;
    IF KeyAt() THEN
      keys := L.Sub(sc.t^, sc.pos, 2); INC(sc.pos, 2); SkipSpace;
      WHILE sc.Ch() = "," DO
        INC(sc.pos); SkipSpace;
        IF ~KeyAt() THEN sc.Error("expected PK, FK or UK") END;
        keys := C.CatS(C.Cat(keys, ","), L.Sub(sc.t^, sc.pos, 2)); INC(sc.pos, 2); SkipSpace
      END;
      a.keys := keys
    END;
    IF sc.Ch() = 22X THEN a.comment := Quoted() END;
    IF last = NIL THEN n.attrs := a ELSE last.next := a END;
    last := a
  END
END Block;

(* "A", "A[alias]", with ":::classes" and "{ attributes }", or a
   relationship *)
PROCEDURE EntityStmt;
  VAR name, alias, classes: Str; n: F.Node;
BEGIN
  name := EntityName();
  sc.SkipBlanks; alias := NIL; classes := NIL;
  IF sc.Ch() = "[" THEN
    INC(sc.pos);
    alias := EntityName();
    sc.SkipBlanks;
    IF ~sc.Accept("]") THEN sc.Error("expected ]") END;
    sc.SkipBlanks
  END;
  IF sc.Accept(":::") THEN classes := IdList("expected a style class's name"); sc.SkipBlanks END;
  IF (alias = NIL) & AtRelation() THEN RelationRest(name, classes); RETURN END;
  n := Entity(name);
  IF (alias # NIL) & (n.label = NIL) THEN n.label := F.PlainLabel(C.Generic(alias)) END;
  IF classes # NIL THEN SetClass(name, classes) END;
  IF sc.Accept("{") THEN Block(n) END;
  ExpectEnd;
  Mention(name)
END EntityStmt;

(* "style ids props" *)
PROCEDURE Style;
  VAR ids, id, props: Str; i, start: LONGINT; n: F.Node; c: F.Cluster;
BEGIN
  ids := IdList("expected an entity's name");
  props := sc.Rest();
  i := 0;
  LOOP
    start := i;
    WHILE (ids[i] # 0X) & (ids[i] # ",") DO INC(i) END;
    id := L.Sub(ids^, start, i - start);
    n := F.FindNode(id^); c := Subgraph(id);
    IF (n = NIL) & (c # NIL) THEN n := F.GetNode(id) END;
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
  ids := IdList("expected an entity's name");
  SetClass(ids, IdList("expected a style class's name"));
  ExpectEnd
END ClassStmt;

(* "direction TB" (BT, LR, RL), the rest of the line ignored, as
   Mermaid's lexer has it *)
PROCEDURE Direction;
  VAR d: INTEGER;
BEGIN
  sc.SkipBlanks;
  IF LookingAtI("tb") THEN d := F.TB ELSIF LookingAtI("bt") THEN d := F.BT
  ELSIF LookingAtI("lr") THEN d := F.LR ELSIF LookingAtI("rl") THEN d := F.RL
  ELSE sc.Error("expected TB, BT, LR or RL")
  END;
  sc.SkipLine;
  IF frame # NIL THEN frame.dir := d ELSE g.dir := d END
END Direction;

(* "subgraph id" or "subgraph id [title words]" *)
PROCEDURE SubgraphStmt;
  VAR f: Frame; w: Str;
BEGIN
  NEW(f); f.open := sc.pos - 8; f.id := EntityName(); f.title := f.id; f.dir := F.NoDir;
  f.items := NIL; f.lastItem := NIL;
  sc.SkipBlanks;
  IF sc.Accept("[") THEN
    f.title := EntityName();
    LOOP
      sc.SkipBlanks;
      IF sc.Accept("]") THEN EXIT END;
      w := Name();
      IF w = NIL THEN sc.Error("expected ]") END;
      f.title := C.Cat(C.Cat(f.title, " "), w^)
    END
  END;
  IF sc.Ch() = ";" THEN INC(sc.pos) END;
  ExpectEnd;
  f.outer := frame; frame := f
END SubgraphStmt;

(* "end": the subgraph, a cluster, holds what its statements named and
   no earlier subgraph holds *)
PROCEDURE End;
  VAR f: Frame; c, k: F.Cluster; it: Item; o: Owner;
BEGIN
  IF frame = NIL THEN sc.Error("end without subgraph") END;
  ExpectEnd;
  f := frame; frame := f.outer;
  c := F.NewCluster(f.id, F.PlainLabel(f.title), NIL, F.Plain);
  c.dir := f.dir;
  it := f.items;
  WHILE it # NIL DO
    IF ~L.Equal(it.name, f.id) & (FindOwner(it.name) = NIL) THEN
      k := Subgraph(it.name);
      IF k # NIL THEN k.parent := c END;
      NEW(o); o.name := it.name; o.cluster := c; o.next := owners; owners := o
    END;
    it := it.next
  END;
  F.AddCluster(c);
  Mention(f.id)
END End;

PROCEDURE Statement;
BEGIN
  IF Kw("subgraph") THEN INC(sc.pos, 8); SubgraphStmt
  ELSIF Kw("end") THEN INC(sc.pos, 3); End
  ELSIF Kw("classdef") THEN INC(sc.pos, 8); F.ClassDefStmt; IF sc.Ch() = ";" THEN INC(sc.pos) END; ExpectEnd
  ELSIF Kw("class") THEN INC(sc.pos, 5); ClassStmt
  ELSIF Kw("style") THEN INC(sc.pos, 5); Style
  ELSIF Kw("direction") THEN INC(sc.pos, 9); Direction
  ELSIF sc.LookingAt("accTitle") OR sc.LookingAt("accDescr") THEN F.Accessibility
  ELSE EntityStmt
  END
END Statement;

(* The end: each entity is labelled with its alias or its name, and is
   put in its subgraph; the relationships are the edges *)
PROCEDURE Finish;
  VAR n: F.Node; o: Owner; r: Relation; e: F.Edge; a: F.Attr; lab: F.Label;
BEGIN
  n := g.nodes;
  WHILE n # NIL DO
    IF n.shape = F.ErBox THEN
      IF n.label = NIL THEN n.label := F.PlainLabel(C.Generic(n.id)) END;
      a := n.attrs;
      WHILE a # NIL DO
        a.type := C.Generic(a.type); a.name := C.Generic(a.name);
        IF a.keys # NIL THEN a.keys := C.Generic(a.keys) END;
        IF a.comment # NIL THEN a.comment := C.Generic(a.comment) END;
        a := a.next
      END
    END;
    o := FindOwner(n.id);
    IF o # NIL THEN n.cluster := o.cluster END;
    n := n.next
  END;
  r := relations;
  WHILE r # NIL DO
    lab := NIL;
    IF r.role[0] # 0X THEN lab := F.MarkdownLabel(r.role^, 0, L.Length(r.role^)) END;
    e := F.NewEdge(F.FindNode(r.a^), F.FindNode(r.b^), r.cardB, r.cardA, r.line, lab);
    r := r.next
  END;
  F.Finish
END Finish;

(* Whether the scanner's text, after front matter and comments, starts
   with "erDiagram" *)
PROCEDURE IsEr*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s;
  r := LookingAtI("erdiagram");
  s.pos := save;
  RETURN r
END IsEr;

(* Reads the entity relationship diagram in s's text into graph *)
PROCEDURE Read*(s: L.Scanner; VAR graph: F.Graph);
BEGIN
  F.Begin(s, F.Er, g); graph := g; sc := s;
  frame := NIL; owners := NIL; relations := NIL; lastRelation := NIL;
  IF ~LookingAtI("erdiagram") THEN sc.Error("expected erDiagram") END;
  INC(sc.pos, 9);
  ExpectEnd;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  IF frame # NIL THEN sc.ErrorAt(frame.open, "a subgraph has no end") END;
  Finish
END Read;

END PmEr.
