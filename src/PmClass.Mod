MODULE PmClass;
(* PmClass: Mermaid's class diagrams (`classDiagram` and
   `classDiagram-v2`), read into PmFlow's model, which the layout and
   the writers take as they take a flowchart.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   class/parser/classDiagram.jison, and what classDb.ts and
   classTypes.ts make of it:

   - statements end at a line end; "%%" starts a comment;
   - a class's name is letters, digits, "_", "-", "." and UTF-8, or
     text in backquotes, with a generic type, "~T~", after it or not;
     "Square~Shape~" is the class Square, titled "Square<Shape>";
   - "A <|-- B", with "--" or "..", a marker at either end or both
     ("<|", "*", "o", "<", "()" and their mirror images), cardinalities
     in quotation marks before and after the line, and a label after
     ":", is a relation; a lollipop, "()", with no marker at the other
     end, makes an interface, a circle and its name, joined to the
     class;
   - "class X", "class X["label"]", with ":::style" or "<<annotation>>",
     and with members in braces or not, declares a class; "X : member"
     adds a member, and "<<annotation>> X" an annotation, of which the
     first is shown;
   - a member with ")" is a method, drawn below the attributes; "+",
     "-", "#" and "~" before it are its visibility, "*" or "$" after
     it make it italic (abstract) or underlined (static), and "~T~" in
     it is shown as "<T>";
   - "note for X "text"" is a note joined to X by a dotted line; "note
     "text"" a note alone;
   - "namespace N { ... }" holds classes, notes and namespaces: a
     cluster; a dotted name, "a.b", makes the namespaces it is in;
   - classDef, style, cssClass, ":::", click, link and callback act as
     in Mermaid, on classes declared before them;
   - "direction TB" (BT, LR, RL) is the diagram's direction.

   Keywords and markers are whole words here, as Mermaid's lexer does
   not always take them: a class named "obj" is "obj", not an
   aggregation's "o" and "bj". accTitle and accDescr are skipped. *)

IMPORT L := PmLex, F := PmFlow, Y := PmYaml;

TYPE
  Str = L.Str;
  Strs = POINTER TO ARRAY OF Str;

  (* A namespace, as classDb.ts keeps it *)
  Ns = POINTER TO NsDesc;
  NsDesc = RECORD
    id, label: Str;
    parent: Ns;
    explicit: BOOLEAN;
    cluster: F.Cluster;
    next: Ns
  END;
  NsArray = POINTER TO ARRAY OF Ns;

  Note = POINTER TO NoteDesc;
  NoteDesc = RECORD
    id, cls, text: Str;  (* cls: the class it is for, or NIL *)
    pos: LONGINT;        (* where its text was *)
    parent: Ns;
    next: Note
  END;

  Interface = POINTER TO InterfaceDesc;
  InterfaceDesc = RECORD
    id, label: Str;
    next: Interface
  END;

  Relation = POINTER TO RelationDesc;
  RelationDesc = RECORD
    id1, id2: Str;
    type1, type2, line: INTEGER;  (* F.None, F.Extension ...; F.Normal, F.Dotted *)
    title1, title2: Str;          (* the cardinalities, or NIL *)
    label: F.Label;
    next: Relation
  END;

  (* What a namespace's body holds directly *)
  Held = POINTER TO HeldDesc;
  HeldDesc = RECORD
    node: F.Node;  (* a class, or NIL *)
    note: Note;    (* or a note *)
    next: Held
  END;

VAR
  sc: L.Scanner;
  g: F.Graph;
  depth: INTEGER;  (* the namespaces being read *)
  spaces, lastSpace: Ns;
  notes, lastNote: Note; nNotes: INTEGER;
  interfaces, lastInterface: Interface; nInterfaces: INTEGER;
  relations, lastRelation: Relation;
  nsOf: NsArray;   (* each class's namespace, by its node's index *)

(* Text *)

(* a + b *)
PROCEDURE Cat*(a: Str; b: ARRAY OF CHAR): Str;
  VAR r: Str; i, k: LONGINT;
BEGIN
  NEW(r, L.Length(a^) + L.Length(b) + 1);
  i := 0; WHILE a[i] # 0X DO r[i] := a[i]; INC(i) END;
  k := 0; WHILE b[k] # 0X DO r[i] := b[k]; INC(i); INC(k) END;
  r[i] := 0X;
  RETURN r
END Cat;

(* a + b *)
PROCEDURE CatS*(a, b: Str): Str;
BEGIN RETURN Cat(a, b^)
END CatS;

PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 8 OF CHAR; k, i: INTEGER;
BEGIN
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  i := 0; WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END;
  s[i] := 0X
END Num;

(* s without blanks at its ends *)
PROCEDURE Trim(s: Str): Str;
  VAR start, end: LONGINT;
BEGIN
  start := 0; end := L.Length(s^);
  WHILE (start < end) & L.IsBlank(s[start]) DO INC(start) END;
  WHILE (end > start) & L.IsBlank(s[end - 1]) DO DEC(end) END;
  RETURN L.Sub(s^, start, end - start)
END Trim;

(* The index of the first ch in s, or -1 *)
PROCEDURE Index(s: Str; ch: CHAR): LONGINT;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO IF s[i] = ch THEN RETURN i END; INC(i) END;
  RETURN -1
END Index;

PROCEDURE Tildes(s: Str): LONGINT;
  VAR i, n: LONGINT;
BEGIN
  i := 0; n := 0;
  WHILE s[i] # 0X DO IF s[i] = "~" THEN INC(n) END; INC(i) END;
  RETURN n
END Tildes;

(* Mermaid's processSet: the outermost pairs of "~" in x made "<" and
   ">", in turn; a first "~" is kept when there is an odd number *)
PROCEDURE ProcessSet(x: Str): Str;
  VAR n, len, i, first, last: LONGINT; c: Str; tilde: BOOLEAN;
BEGIN
  n := Tildes(x);
  IF n <= 1 THEN RETURN x END;
  len := L.Length(x^);
  tilde := ODD(n) & (x[0] = "~");
  IF tilde THEN c := L.Sub(x^, 1, len - 1) ELSE c := L.Sub(x^, 0, len) END;
  len := L.Length(c^);
  LOOP
    first := -1; last := -1;
    FOR i := 0 TO len - 1 DO
      IF c[i] = "~" THEN
        IF first < 0 THEN first := i END;
        last := i
      END
    END;
    IF (first < 0) OR (first = last) THEN EXIT END;
    c[first] := "<"; c[last] := ">"
  END;
  IF tilde THEN c := Cat(L.New("~"), c^) END;
  RETURN c
END ProcessSet;

(* Mermaid's parseGenericTypes: "List~int~" is "List<int>", and
   "Map~K, V~" "Map<K, V>" *)
PROCEDURE Generic*(s: Str): Str;
  VAR sets, out: Strs; n, m, i, start, len: LONGINT; this, r: Str;
BEGIN
  len := L.Length(s^);
  NEW(sets, 2 * len + 2); n := 0; start := 0;
  FOR i := 0 TO len - 1 DO
    IF s[i] = "," THEN
      sets[n] := L.Sub(s^, start, i - start); sets[n + 1] := L.New(",");
      INC(n, 2); start := i + 1
    END
  END;
  sets[n] := L.Sub(s^, start, len - start); INC(n);
  NEW(out, n); m := 0; i := 0;
  WHILE i < n DO
    this := sets[i];
    IF L.Is(this, ",") & (i > 0) & (i + 1 < n) & (Tildes(sets[i - 1]) = 1)
       & (Tildes(sets[i + 1]) = 1) THEN
      this := Cat(Cat(sets[i - 1], ","), sets[i + 1]^); INC(i); DEC(m)
    END;
    out[m] := ProcessSet(this); INC(m); INC(i)
  END;
  r := L.New("");
  FOR i := 0 TO m - 1 DO r := Cat(r, out[i]^) END;
  RETURN r
END Generic;

(* Labels *)

(* Gives each byte of lab's lines style st, or underlines them *)
PROCEDURE SetStyle(lab: F.Label; st: SHORTINT; underline: BOOLEAN);
  VAR l: F.Line; i, n: LONGINT;
BEGIN
  l := lab.lines;
  WHILE l # NIL DO
    IF st # F.Roman THEN
      n := L.Length(l.text^);
      NEW(l.style, n + 1);
      FOR i := 0 TO n - 1 DO l.style[i] := st END;
      l.style[n] := F.Roman
    END;
    l.underline := underline;
    l := l.next
  END
END SetStyle;

(* Adds src's lines to lab's, which may be NIL *)
PROCEDURE AddLines(VAR lab: F.Label; src: F.Label);
  VAR l: F.Line;
BEGIN
  IF lab = NIL THEN lab := src
  ELSE
    l := lab.lines; WHILE l.next # NIL DO l := l.next END;
    l.next := src.lines; INC(lab.n, src.n)
  END
END AddLines;

PROCEDURE IsVisibility(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch = "+") OR (ch = "-") OR (ch = "#") OR (ch = "~")
END IsVisibility;

(* The id of a member, as Mermaid trims it: one blank kept before it *)
PROCEDURE MemberId(s: Str): Str;
BEGIN
  IF s[0] = " " THEN RETURN CatS(L.New(" "), Trim(s)) END;
  RETURN Trim(s)
END MemberId;

(* A member's line, as classTypes.ts's ClassMember shows it: the
   visibility, the name, a method's parameters and return type, with
   "~T~" as "<T>", italic for "*" and underlined for "$" *)
PROCEDURE Member(m: Str; method: BOOLEAN): F.Label;
  VAR len, i, lp, rp, start, end: LONGINT; vis: ARRAY 2 OF CHAR; cls: CHAR;
    id, params, ret, d: Str; lab: F.Label;
BEGIN
  len := L.Length(m^); vis[0] := 0X; vis[1] := 0X; cls := 0X; params := NIL; ret := NIL;
  IF method THEN
    (* as classTypes.ts's method pattern: visibility, name, "(", parameters, ")", classifier, return type *)
    rp := len - 1; WHILE (rp >= 0) & (m[rp] # ")") DO DEC(rp) END;
    lp := rp - 1; WHILE (lp >= 1) & (m[lp] # "(") DO DEC(lp) END;
    IF (rp > 1) & (lp >= 1) THEN
      start := 0;
      IF IsVisibility(m[0]) & (lp >= 2) THEN vis[0] := m[0]; start := 1 END;
      id := L.Sub(m^, start, lp - start);
      params := Trim(L.Sub(m^, lp + 1, rp - lp - 1));
      i := rp + 1;
      IF (i < len) & (L.IsBlank(m[i]) OR (m[i] = "$") OR (m[i] = "*")) THEN
        IF ~L.IsBlank(m[i]) THEN cls := m[i] END;
        INC(i)
      END;
      ret := Trim(L.Sub(m^, i, len - i));
      end := L.Length(ret^);
      IF (cls = 0X) & (end > 0) & ((ret[end - 1] = "$") OR (ret[end - 1] = "*")) THEN
        cls := ret[end - 1]; ret := L.Sub(ret^, 0, end - 1)
      END
    ELSE id := m (* Mermaid fails here *)
    END
  ELSE
    start := 0; end := len;
    IF (len > 0) & IsVisibility(m[0]) THEN vis[0] := m[0]; start := 1 END;
    IF (len > 0) & ((m[len - 1] = "$") OR (m[len - 1] = "*")) THEN cls := m[len - 1]; DEC(end) END;
    IF end < start THEN end := start END;
    id := L.Sub(m^, start, end - start)
  END;
  d := CatS(L.New(vis), Generic(MemberId(id)));
  IF params # NIL THEN
    d := Cat(CatS(Cat(d, "("), Generic(params)), ")");
    IF ret[0] # 0X THEN d := CatS(Cat(d, " : "), Generic(ret)) END
  END;
  lab := F.PlainLabel(d);
  IF cls = "*" THEN SetStyle(lab, F.Italic, FALSE)
  ELSIF cls = "$" THEN SetStyle(lab, F.Roman, TRUE)
  END;
  RETURN lab
END Member;

(* The scanner *)

(* Skips what is between statements: blanks, line ends, comments and
   directives *)
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
   comment, the end, or a namespace's "}" *)
PROCEDURE AtEnd(): BOOLEAN;
BEGIN
  sc.SkipBlanks;
  RETURN sc.AtEnd() OR (sc.Ch() = 0AX) OR sc.LookingAt("%%") OR (depth > 0) & (sc.Ch() = "}")
END AtEnd;

PROCEDURE ExpectEnd;
BEGIN
  IF ~AtEnd() THEN sc.Error("unexpected text") END
END ExpectEnd;

(* Whether the text at the position is the keyword w, with a blank
   after it *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN sc.LookingAt(w) & L.IsBlank(sc.Peek(L.Length(w)))
END Kw;

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

(* Whether ch is in a class's name at the position: "-" and "." are,
   but not "--" and ".." *)
PROCEDURE NameChar(): BOOLEAN;
  VAR ch: CHAR;
BEGIN
  ch := sc.Ch();
  IF sc.AtEnd() THEN RETURN FALSE END;
  IF (ch = "-") OR (ch = ".") THEN RETURN sc.Peek(1) # ch END;
  RETURN L.IsWordChar(ch)
END NameChar;

(* A class's or namespace's name: its letters, or text in backquotes;
   with generic, "~T~" after it, kept as it is; NIL if there is none *)
PROCEDURE Name(generic: BOOLEAN): Str;
  VAR start: LONGINT; s: Str;
BEGIN
  IF sc.Ch() = "`" THEN
    INC(sc.pos); start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # "`") DO INC(sc.pos) END;
    IF sc.AtEnd() OR (sc.pos = start) THEN sc.ErrorAt(start - 1, "unterminated name in backquotes") END;
    s := L.Sub(sc.t^, start, sc.pos - start);
    INC(sc.pos)
  ELSE
    start := sc.pos;
    WHILE NameChar() DO INC(sc.pos) END;
    IF sc.pos = start THEN RETURN NIL END;
    s := L.Sub(sc.t^, start, sc.pos - start)
  END;
  IF generic & (sc.Ch() = "~") THEN
    INC(sc.pos); start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # "~") DO INC(sc.pos) END;
    IF sc.AtEnd() THEN sc.ErrorAt(start - 1, "a generic type has no closing ~") END;
    s := Cat(CatS(Cat(s, "~"), L.Sub(sc.t^, start, sc.pos - start)), "~");
    INC(sc.pos)
  END;
  RETURN s
END Name;

(* A class's name, which must be there *)
PROCEDURE ClassName(): Str;
  VAR s: Str;
BEGIN
  sc.SkipBlanks;
  s := Name(TRUE);
  IF s = NIL THEN sc.Error("expected a class's name") END;
  RETURN s
END ClassName;

(* A word: a style class's or annotation's name *)
PROCEDURE Word(what: ARRAY OF CHAR): Str;
  VAR start: LONGINT;
BEGIN
  sc.SkipBlanks; start := sc.pos;
  WHILE L.IsWordChar(sc.Ch()) OR (sc.Ch() = "-") DO INC(sc.pos) END;
  IF sc.pos = start THEN sc.Error(what) END;
  RETURN L.Sub(sc.t^, start, sc.pos - start)
END Word;

(* The model *)

(* name's class and generic type: "Square~Shape~" is Square and Shape *)
PROCEDURE Split(name: Str; VAR cls, type: Str);
  VAR k, e: LONGINT;
BEGIN
  k := Index(name, "~");
  IF k > 0 THEN
    cls := L.Sub(name^, 0, k);
    e := k + 1; WHILE (name[e] # 0X) & (name[e] # "~") DO INC(e) END;
    type := L.Sub(name^, k + 1, e - k - 1)
  ELSE cls := name; type := NIL
  END
END Split;

PROCEDURE ClassId(name: Str): Str;
  VAR cls, type: Str;
BEGIN
  Split(name, cls, type); RETURN cls
END ClassId;

(* The class's title, bold: its label and its generic type *)
PROCEDURE Title(n: F.Node; label, type: Str);
  VAR s: Str;
BEGIN
  s := label;
  IF (type # NIL) & (type[0] # 0X) THEN s := Cat(Cat(Cat(s, "<"), type^), ">") END;
  n.label := F.PlainLabel(s); SetStyle(n.label, F.Bold, FALSE)
END Title;

(* The class name, ~T~ and all, which is made if it is new *)
PROCEDURE Class(name: Str): F.Node;
  VAR n: F.Node; cls, type: Str; a: NsArray; i: LONGINT;
BEGIN
  Split(name, cls, type);
  n := F.FindNode(cls^);
  IF n = NIL THEN
    n := F.GetNode(cls); n.shape := F.ClassBox;
    Title(n, cls, type);
    IF n.index >= LEN(nsOf^) THEN
      NEW(a, 2 * LEN(nsOf^));
      FOR i := 0 TO LEN(nsOf^) - 1 DO a[i] := nsOf[i] END;
      nsOf := a
    END;
    nsOf[n.index] := NIL
  END;
  RETURN n
END Class;

(* The class name if it is there, or NIL *)
PROCEDURE Existing(name: Str): F.Node;
  VAR id: Str;
BEGIN
  id := ClassId(name); RETURN F.FindNode(id^)
END Existing;

PROCEDURE Annotate(n: F.Node; ann: Str);
BEGIN
  (* only the first is shown, in guillemets *)
  IF n.annotation = NIL THEN
    n.annotation := F.PlainLabel(Cat(Cat(L.New("«"), ann^), "»"))
  END
END Annotate;

(* classDb.ts's addMember: "<<x>>" is an annotation, text with ")"
   after its start a method, and other text an attribute *)
PROCEDURE AddMember(n: F.Node; m: Str);
  VAR len: LONGINT;
BEGIN
  m := Trim(m); len := L.Length(m^);
  IF (len >= 4) & (m[0] = "<") & (m[1] = "<") & (m[len - 2] = ">") & (m[len - 1] = ">") THEN
    Annotate(n, L.Sub(m^, 2, len - 4))
  ELSIF Index(m, ")") > 0 THEN AddLines(n.methods, Member(m, TRUE))
  ELSIF len > 0 THEN AddLines(n.members, Member(m, FALSE))
  END
END AddMember;

(* Gives the classes ids, "a,b", the style class cls *)
PROCEDURE CssClass(ids, cls: Str);
  VAR i, start: LONGINT; n: F.Node;
BEGIN
  i := 0;
  LOOP
    start := i;
    WHILE (ids[i] # 0X) & (ids[i] # ",") DO INC(i) END;
    n := Existing(L.Sub(ids^, start, i - start));
    IF n # NIL THEN F.AddClass(n, cls) END;
    IF ids[i] = 0X THEN EXIT END;
    INC(i)
  END
END CssClass;

(* The namespace id, or NIL *)
PROCEDURE FindNs(id: Str): Ns;
  VAR s: Ns;
BEGIN
  s := spaces;
  WHILE (s # NIL) & ~L.Equal(s.id, id) DO s := s.next END;
  RETURN s
END FindNs;

(* classDb.ts's addNamespace: the namespace id, dotted ("a.b"), and the
   namespaces it is in, made if they are new *)
PROCEDURE AddNamespace(id, label: Str): Ns;
  VAR s, parent: Ns; i: LONGINT; part, cur: Str;
BEGIN
  s := FindNs(id);
  IF s # NIL THEN
    s.explicit := TRUE;
    IF label # NIL THEN s.label := label END;
    RETURN s
  END;
  parent := NIL; i := 0;
  LOOP
    WHILE (id[i] # 0X) & (id[i] # ".") DO INC(i) END;
    cur := L.Sub(id^, 0, i);
    s := FindNs(cur);
    IF s = NIL THEN
      NEW(s); s.id := cur; s.parent := parent; s.cluster := NIL; s.next := NIL;
      part := cur; IF parent # NIL THEN part := L.Sub(cur^, L.Length(parent.id^) + 1, i - L.Length(parent.id^) - 1) END;
      s.explicit := id[i] = 0X;
      IF (id[i] = 0X) & (label # NIL) THEN s.label := label ELSE s.label := part END;
      IF spaces = NIL THEN spaces := s ELSE lastSpace.next := s END;
      lastSpace := s
    ELSIF id[i] = 0X THEN s.explicit := TRUE
    END;
    parent := s;
    IF id[i] = 0X THEN EXIT END;
    INC(i)
  END;
  RETURN s
END AddNamespace;

PROCEDURE AddNote(cls, text: Str; pos: LONGINT): Note;
  VAR n: Note; num: ARRAY 8 OF CHAR;
BEGIN
  NEW(n); Num(nNotes, num); INC(nNotes);
  n.id := Cat(L.New("note"), num); n.cls := cls; n.text := text; n.pos := pos;
  n.parent := NIL; n.next := NIL;
  IF notes = NIL THEN notes := n ELSE lastNote.next := n END;
  lastNote := n;
  RETURN n
END AddNote;

(* An interface named label, for a lollipop; its id *)
PROCEDURE AddInterface(label: Str): Str;
  VAR i: Interface; num: ARRAY 8 OF CHAR;
BEGIN
  NEW(i); Num(nInterfaces, num); INC(nInterfaces);
  i.id := Cat(L.New("interface"), num); i.label := label; i.next := NIL;
  IF interfaces = NIL THEN interfaces := i ELSE lastInterface.next := i END;
  lastInterface := i;
  RETURN i.id
END AddInterface;

(* classDb.ts's addRelation *)
PROCEDURE AddRelation(r: Relation);
  PROCEDURE None(t: INTEGER): BOOLEAN;
  BEGIN RETURN t = F.None
  END None;
  PROCEDURE Title(s: Str): Str;
  BEGIN
    IF s = NIL THEN RETURN NIL END;
    s := Trim(s);
    IF L.Is(s, "none") THEN RETURN NIL END;
    RETURN s
  END Title;
  VAR n: F.Node;
BEGIN
  IF (r.type1 = F.Lollipop) & None(r.type2) THEN
    n := Class(r.id2); r.id1 := AddInterface(r.id1)
  ELSIF (r.type2 = F.Lollipop) & None(r.type1) THEN
    n := Class(r.id1); r.id2 := AddInterface(r.id2)
  ELSE n := Class(r.id1); n := Class(r.id2)
  END;
  r.id1 := ClassId(r.id1); r.id2 := ClassId(r.id2);
  r.title1 := Title(r.title1); r.title2 := Title(r.title2);
  r.next := NIL;
  IF relations = NIL THEN relations := r ELSE lastRelation.next := r END;
  lastRelation := r
END AddRelation;

(* Statements *)

(* A relation's marker at the position, F.None if there is none; left
   says it is before the line *)
PROCEDURE Marker(left: BOOLEAN): INTEGER;
  VAR t: INTEGER; ch: CHAR;
BEGIN
  sc.SkipBlanks; t := F.None; ch := sc.Ch();
  IF sc.LookingAt("<|") OR sc.LookingAt("|>") THEN t := F.Extension; INC(sc.pos, 2)
  ELSIF sc.LookingAt("()") THEN t := F.Lollipop; INC(sc.pos, 2)
  ELSIF (ch = "<") OR (ch = ">") THEN t := F.Dependency; INC(sc.pos)
  ELSIF ch = "*" THEN t := F.Composition; INC(sc.pos)
  ELSIF (ch = "o") & (left & (sc.LookingAt("o--") OR sc.LookingAt("o.."))
     OR ~left & ~L.IsWordChar(sc.Peek(1)) & (sc.Peek(1) # "`")) THEN
    t := F.Aggregation; INC(sc.pos)
  END;
  RETURN t
END Marker;

(* Whether a relation starts at the position, after a class's name *)
PROCEDURE AtRelation(): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN; t: INTEGER;
BEGIN
  save := sc.pos;
  sc.SkipBlanks;
  r := sc.Ch() = 22X;
  IF ~r THEN
    t := Marker(TRUE); sc.SkipBlanks;
    r := sc.LookingAt("--") OR sc.LookingAt("..")
  END;
  sc.pos := save;
  RETURN r
END AtRelation;

(* Text after ":" in a relation or a member: to ":", ";" or the line's
   end *)
PROCEDURE ColonText(): Str;
  VAR start: LONGINT;
BEGIN
  INC(sc.pos); start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & (sc.Ch() # ":") & (sc.Ch() # ";") DO INC(sc.pos) END;
  RETURN Trim(L.Sub(sc.t^, start, sc.pos - start))
END ColonText;

(* "A rel B" with cardinalities and a label, "A : member", or "A" *)
PROCEDURE IdStatement;
  VAR name: Str; r: Relation; text: Str;
BEGIN
  name := ClassName();
  IF AtRelation() THEN
    NEW(r); r.id1 := name; r.title1 := NIL; r.title2 := NIL; r.label := NIL;
    sc.SkipBlanks;
    IF sc.Ch() = 22X THEN r.title1 := Quoted() END;
    r.type1 := Marker(TRUE); sc.SkipBlanks;
    IF sc.Accept("--") THEN r.line := F.Normal
    ELSIF sc.Accept("..") THEN r.line := F.Dotted
    ELSE sc.Error("expected -- or ..")
    END;
    r.type2 := Marker(FALSE); sc.SkipBlanks;
    IF sc.Ch() = 22X THEN r.title2 := Quoted() END;
    r.id2 := ClassName();
    sc.SkipBlanks;
    IF (sc.Ch() = ":") & ~sc.LookingAt(":::") THEN
      text := ColonText();
      IF text[0] # 0X THEN r.label := F.MarkdownLabel(text^, 0, L.Length(text^)) END
    END;
    ExpectEnd;
    AddRelation(r)
  ELSE
    sc.SkipBlanks;
    IF (sc.Ch() = ":") & ~sc.LookingAt(":::") THEN
      text := ColonText(); ExpectEnd;
      AddMember(Class(name), text)
    ELSE ExpectEnd (* a class's name alone does nothing *)
    END
  END
END IdStatement;

(* The members in braces, from after "{", to its "}" *)
PROCEDURE Body(n: F.Node);
  VAR open, start: LONGINT;
BEGIN
  open := sc.pos - 1;
  LOOP
    start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & (sc.Ch() # "{") & (sc.Ch() # "}") DO INC(sc.pos) END;
    IF sc.AtEnd() THEN sc.ErrorAt(open, "a class has no }") END;
    IF sc.Ch() = "{" THEN sc.Error("a class's members cannot have {") END;
    AddMember(n, L.Sub(sc.t^, start, sc.pos - start));
    IF sc.Ch() = "}" THEN INC(sc.pos); EXIT END;
    INC(sc.pos)
  END
END Body;

(* "class X", with ["label"], ":::style" or "<<annotation>>", and
   "{ members }"; X's node *)
PROCEDURE ClassStmt(): F.Node;
  VAR n: F.Node; name, label, type, cls: Str;
BEGIN
  name := ClassName();
  n := Class(name);
  sc.SkipBlanks;
  IF sc.Ch() = "[" THEN
    INC(sc.pos); sc.SkipBlanks;
    IF sc.Ch() # 22X THEN sc.Error("expected a label in quotation marks") END;
    label := Quoted(); sc.SkipBlanks;
    IF ~sc.Accept("]") THEN sc.Error("expected ]") END;
    Split(name, cls, type);
    Title(n, label, type);
    sc.SkipBlanks
  END;
  IF sc.Accept(":::") THEN
    CssClass(name, Word("expected a style class's name")); sc.SkipBlanks
  ELSIF sc.Accept("<<") THEN
    Annotate(n, Word("expected an annotation"));
    sc.SkipBlanks;
    IF ~sc.Accept(">>") THEN sc.Error("expected >>") END;
    sc.SkipBlanks
  END;
  IF sc.Accept("{") THEN Body(n) END;
  ExpectEnd;
  RETURN n
END ClassStmt;

(* "<<annotation>> X" *)
PROCEDURE AnnotationStmt;
  VAR ann, name: Str; n: F.Node; pos: LONGINT;
BEGIN
  ann := Word("expected an annotation");
  sc.SkipBlanks;
  IF ~sc.Accept(">>") THEN sc.Error("expected >>") END;
  sc.SkipBlanks; pos := sc.pos;
  name := ClassName(); ExpectEnd;
  n := Existing(name);
  IF n = NIL THEN sc.ErrorAt(pos, "an annotation must be for a class declared before it") END;
  Annotate(n, ann)
END AnnotationStmt;

(* "note for X "text"" or "note "text""; the note *)
PROCEDURE NoteStmt(): Note;
  VAR cls, text: Str; pos: LONGINT;
BEGIN
  sc.SkipBlanks; cls := NIL;
  IF Kw("for") THEN INC(sc.pos, 3); cls := ClassName(); sc.SkipBlanks END;
  IF sc.Ch() # 22X THEN sc.Error("expected the note's text in quotation marks") END;
  pos := sc.pos;
  text := Quoted(); ExpectEnd;
  RETURN AddNote(cls, text, pos)
END NoteStmt;

(* "namespace N ["label"] { ... }", in namespace outer, or NIL *)
PROCEDURE Namespace(outer: Ns);
  VAR id, label: Str; s: Ns; open: LONGINT; held, h: Held; any: BOOLEAN;
BEGIN
  sc.SkipBlanks;
  id := Name(FALSE);
  IF id = NIL THEN sc.Error("expected a namespace's name") END;
  IF outer # NIL THEN id := Cat(Cat(outer.id, "."), id^) END;
  sc.SkipBlanks; label := NIL;
  IF sc.Ch() = "[" THEN
    INC(sc.pos); sc.SkipBlanks;
    IF sc.Ch() # 22X THEN sc.Error("expected a label in quotation marks") END;
    label := Quoted(); sc.SkipBlanks;
    IF ~sc.Accept("]") THEN sc.Error("expected ]") END;
    sc.SkipBlanks
  END;
  s := AddNamespace(id, label);
  IF sc.Ch() # "{" THEN sc.Error("expected {") END;
  open := sc.pos; INC(sc.pos);
  INC(depth); held := NIL; any := FALSE;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN sc.ErrorAt(open, "a namespace has no }") END;
    IF sc.Ch() = "}" THEN INC(sc.pos); EXIT END;
    NEW(h); h.node := NIL; h.note := NIL;
    IF Kw("class") THEN INC(sc.pos, 5); h.node := ClassStmt()
    ELSIF Kw("note") THEN INC(sc.pos, 4); h.note := NoteStmt()
    ELSIF Kw("namespace") THEN INC(sc.pos, 9); Namespace(s)
    ELSE sc.Error("a namespace holds only classes, notes and namespaces")
    END;
    h.next := held; held := h; any := TRUE
  END;
  IF ~any THEN sc.ErrorAt(open, "a namespace must hold something") END;
  DEC(depth);
  (* classDb.ts's addClassesToNamespace, after the body *)
  h := held;
  WHILE h # NIL DO
    IF h.node # NIL THEN nsOf[h.node.index] := s
    ELSIF h.note # NIL THEN h.note.parent := s
    END;
    h := h.next
  END;
  ExpectEnd
END Namespace;

(* "click X call f(args) "tip"", "click X href "url" "tip" target",
   "callback X "f" "tip"" and "link X "url" "tip" target": callbacks
   are JavaScript, and are not kept *)
PROCEDURE Click(kind: INTEGER);
  CONST Clk = 0; Callback = 1; Link = 2;
  VAR name, url, tip, target: Str; n: F.Node;
BEGIN
  name := ClassName(); sc.SkipBlanks;
  url := NIL; tip := NIL; target := NIL;
  IF kind = Clk THEN
    IF Kw("call") THEN
      INC(sc.pos, 4); sc.SkipBlanks;
      WHILE ~sc.AtEnd() & (sc.Ch() # "(") & (sc.Ch() # 0AX) DO INC(sc.pos) END;
      IF ~sc.Accept("(") THEN sc.Error("expected ( after the function's name") END;
      WHILE ~sc.AtEnd() & (sc.Ch() # ")") DO INC(sc.pos) END;
      IF ~sc.Accept(")") THEN sc.Error("expected )") END
    ELSIF Kw("href") THEN
      INC(sc.pos, 4); sc.SkipBlanks;
      IF sc.Ch() # 22X THEN sc.Error("expected a URL in quotation marks") END;
      url := Quoted()
    ELSE sc.Error("expected call or href")
    END
  ELSE
    IF sc.Ch() # 22X THEN
      IF kind = Link THEN sc.Error("expected a URL in quotation marks")
      ELSE sc.Error("expected a function's name in quotation marks")
      END
    END;
    url := Quoted();
    IF kind = Callback THEN url := NIL END
  END;
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN tip := Quoted(); sc.SkipBlanks END;
  IF (url # NIL) & (sc.LookingAt("_self") OR sc.LookingAt("_blank")
     OR sc.LookingAt("_parent") OR sc.LookingAt("_top")) THEN
    target := sc.Word()
  END;
  ExpectEnd;
  n := Existing(name);
  IF n # NIL THEN
    IF url # NIL THEN
      n.link := url;
      IF target = NIL THEN n.linkTarget := L.New("_blank") ELSE n.linkTarget := target END
    END;
    IF tip # NIL THEN n.tooltip := tip END;
    F.AddClass(n, L.New("clickable"))
  END
END Click;

(* "style X props" *)
PROCEDURE Style;
  VAR id: Str; n: F.Node;
BEGIN
  sc.SkipBlanks;
  id := sc.Word();
  IF id = NIL THEN sc.Error("expected a class's name") END;
  n := F.FindNode(id^);
  IF n # NIL THEN F.AppendProps(n.style, F.Props(sc.Rest())) ELSE id := sc.Rest() END;
  ExpectEnd
END Style;

(* "cssClass "ids" name" *)
PROCEDURE CssClassStmt;
  VAR ids: Str;
BEGIN
  sc.SkipBlanks;
  IF sc.Ch() # 22X THEN sc.Error("expected classes' names in quotation marks") END;
  ids := Quoted();
  CssClass(ids, Word("expected a style class's name"));
  ExpectEnd
END CssClassStmt;

(* "direction TB" (BT, LR, RL) *)
PROCEDURE Direction;
BEGIN
  sc.SkipBlanks;
  IF sc.LookingAt("TB") THEN g.dir := F.TB ELSIF sc.LookingAt("BT") THEN g.dir := F.BT
  ELSIF sc.LookingAt("LR") THEN g.dir := F.LR ELSIF sc.LookingAt("RL") THEN g.dir := F.RL
  ELSE sc.Error("expected TB, BT, LR or RL")
  END;
  INC(sc.pos, 2); ExpectEnd
END Direction;

PROCEDURE Statement;
  VAR note: Note;
BEGIN
  IF Kw("namespace") THEN INC(sc.pos, 9); Namespace(NIL)
  ELSIF Kw("class") THEN INC(sc.pos, 5); IF ClassStmt() = NIL THEN END
  ELSIF Kw("note") THEN INC(sc.pos, 4); note := NoteStmt()
  ELSIF Kw("classDef") THEN INC(sc.pos, 8); F.ClassDefStmt; ExpectEnd
  ELSIF Kw("style") THEN INC(sc.pos, 5); Style
  ELSIF Kw("cssClass") THEN INC(sc.pos, 8); CssClassStmt
  ELSIF Kw("click") THEN INC(sc.pos, 5); Click(0)
  ELSIF Kw("callback") THEN INC(sc.pos, 8); Click(1)
  ELSIF Kw("link") THEN INC(sc.pos, 4); Click(2)
  ELSIF Kw("direction") THEN INC(sc.pos, 9); Direction
  ELSIF sc.LookingAt("accTitle") OR sc.LookingAt("accDescr") THEN F.Accessibility
  ELSIF sc.Accept("<<") THEN AnnotationStmt
  ELSE IdStatement
  END
END Statement;

(* The end: the namespaces' clusters, deepest first, the notes, the
   interfaces and the relations, in the order classDb.ts's getData
   gives them *)
PROCEDURE Finish;
  VAR s, k: Ns; hier: BOOLEAN; q: Y.Pair; n, c: F.Node; note: Note; i: Interface;
    r: Relation; e: F.Edge; d, maxDepth: INTEGER;

  PROCEDURE Depth(s: Ns): INTEGER;
    VAR d: INTEGER;
  BEGIN
    d := 0; WHILE s.parent # NIL DO INC(d); s := s.parent END;
    RETURN d
  END Depth;

  (* The cluster of namespace s, as the classes in it are drawn *)
  PROCEDURE ClusterOf(s: Ns): F.Cluster;
  BEGIN
    IF ~hier THEN WHILE (s # NIL) & ~s.explicit DO s := s.parent END END;
    IF s = NIL THEN RETURN NIL END;
    RETURN s.cluster
  END ClusterOf;

BEGIN
  q := Y.Find(g.config, "config.class.hierarchicalNamespaces");
  hier := (q = NIL) OR ~L.Is(q.value, "false");
  maxDepth := 0; s := spaces;
  WHILE s # NIL DO
    IF Depth(s) > maxDepth THEN maxDepth := Depth(s) END;
    IF hier THEN s.cluster := F.NewCluster(s.id, F.PlainLabel(s.label), NIL, F.Plain)
    ELSIF s.explicit THEN s.cluster := F.NewCluster(s.id, F.PlainLabel(s.id), NIL, F.Plain)
    END;
    s := s.next
  END;
  IF hier THEN
    s := spaces;
    WHILE s # NIL DO
      IF s.parent # NIL THEN s.cluster.parent := s.parent.cluster END;
      s := s.next
    END
  END;
  FOR d := maxDepth TO 0 BY -1 DO
    s := spaces;
    WHILE s # NIL DO
      IF (s.cluster # NIL) & (Depth(s) = d) THEN F.AddCluster(s.cluster) END;
      s := s.next
    END
  END;
  n := g.nodes;
  WHILE n # NIL DO
    n.cluster := ClusterOf(nsOf[n.index]);
    n := n.next
  END;
  note := notes;
  WHILE note # NIL DO
    n := F.GetNode(note.id); n.shape := F.Rect;
    n.label := F.MarkdownLabel(note.text^, 0, L.Length(note.text^));
    n.cluster := ClusterOf(note.parent);
    note := note.next
  END;
  i := interfaces;
  WHILE i # NIL DO
    n := F.GetNode(i.id); n.shape := F.Interface; n.label := F.PlainLabel(i.label);
    i := i.next
  END;
  note := notes;
  WHILE note # NIL DO
    IF note.cls # NIL THEN
      c := F.FindNode(note.cls^);
      IF (c # NIL) & (c.shape = F.ClassBox) THEN
        e := F.NewEdge(F.FindNode(note.id^), c, F.None, F.None, F.Normal, NIL)
      END
    END;
    note := note.next
  END;
  r := relations;
  WHILE r # NIL DO
    e := F.NewEdge(F.FindNode(r.id1^), F.FindNode(r.id2^), r.type2, r.type1, r.line, r.label);
    IF r.title1 # NIL THEN e.startLabel := F.PlainLabel(r.title1) END;
    IF r.title2 # NIL THEN e.endLabel := F.PlainLabel(r.title2) END;
    r := r.next
  END;
  F.Finish
END Finish;

(* Whether the scanner's text, after front matter and comments, starts
   with "classDiagram" *)
PROCEDURE IsClass*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("classDiagram");
  s.pos := save;
  RETURN r
END IsClass;

(* Reads the class diagram in s's text into graph *)
PROCEDURE Read*(s: L.Scanner; VAR graph: F.Graph);
BEGIN
  F.Begin(s, F.Class, g); graph := g; sc := s;
  depth := 0; spaces := NIL; lastSpace := NIL;
  notes := NIL; lastNote := NIL; nNotes := 0;
  interfaces := NIL; lastInterface := NIL; nInterfaces := 0;
  relations := NIL; lastRelation := NIL;
  NEW(nsOf, 64);
  IF ~(sc.Accept("classDiagram-v2") OR sc.Accept("classDiagram")) THEN
    sc.Error("expected classDiagram or classDiagram-v2")
  END;
  ExpectEnd;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Finish
END Read;

END PmClass.
