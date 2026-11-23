MODULE PmState;
(* PmState: Mermaid's state diagrams (`stateDiagram-v2` and
   `stateDiagram`), read into PmFlow's model, which the layout and the
   writers take as they take a flowchart.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   state/parser/stateDiagram.jison, and what stateDb.ts and
   dataFetcher.ts make of it:

   - keywords are read in any case; "%%" and "#" start comments;
   - a state is an id, or "[*]": the start, before "-->" or alone,
     or the end, after it, one of each for the diagram ("root_start",
     "root_end") and for each composite state or region;
   - "A --> B : text" is a transition; "A : text" a description: the
     first is the state's name, and more make a state with
     descriptions, the name above a line and the descriptions below;
   - "state X <<fork>>", "<<join>>", "<<choice>>" (or "[[fork]]" ...)
     give a state its shape when it is first mentioned, as in Mermaid;
     "state "text" as X" its name;
   - "state X { ... }" is a composite state, a cluster with its
     states, drawn top to bottom unless a direction statement in it
     says otherwise; "--" divides it into concurrent regions;
   - a state is in the composite state or region where it was last
     mentioned;
   - "note left of X : text", "note right of X : text", or the note's
     lines up to "end note": the note is a box in X's cluster, joined
     to X by a dashed line;
   - classDef, class, style, ":::" in a transition and click count at
     the top level only, and class, style and click apply to states
     wherever they are, as in Mermaid;
   - labels are markdown: a line end breaks a line, and bold and italic
     are kept.

   "hide empty description", "scale", accTitle and accDescr are
   skipped, and so are floating notes ("note "text" as N"), which
   Mermaid does not draw. *)

IMPORT L := PmLex, F := PmFlow;

CONST
  ClassP = 0; StyleP = 1; ClickP = 2; (* what a top-level statement does *)

TYPE
  Str = L.Str;
  Ints = POINTER TO ARRAY OF INTEGER;
  Longs = POINTER TO ARRAY OF LONGINT;

  (* A top-level class, style or click statement, applied at the end *)
  Pending = POINTER TO PendingDesc;
  PendingDesc = RECORD
    kind: INTEGER;
    id, a, b: Str;     (* the state; the class name, the properties, or
                          the URL and the tooltip *)
    next: Pending
  END;

VAR
  sc: L.Scanner;
  g: F.Graph;
  current: F.Cluster;  (* the composite state being read, or NIL *)
  segDir: INTEGER;     (* the direction statement of the region being read *)
  regions: INTEGER;    (* the regions of current so far *)
  items: INTEGER;      (* Mermaid's graphItemCount: transitions and notes *)
  dividers: INTEGER;   (* regions made, for their ids *)
  pending, lastPending: Pending;
  descs: Ints; (* each node's descriptions *)
  descPos: Longs; (* where its second was *)

(* Text *)

PROCEDURE Cap(c: CHAR): CHAR;
BEGIN
  IF (c >= "a") & (c <= "z") THEN RETURN CHR(ORD(c) - 32) END;
  RETURN c
END Cap;

(* Whether the text at the position starts with w, in any case *)
PROCEDURE At(w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE w[i] # 0X DO
    IF Cap(sc.Peek(i)) # Cap(w[i]) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END At;

(* Whether the text at the position is the keyword w, in any case,
   with a blank after it *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN At(w) & L.IsBlank(sc.Peek(L.Length(w)))
END Kw;

(* a + b *)
PROCEDURE Cat(a: Str; b: ARRAY OF CHAR): Str;
  VAR r: Str; i, k: LONGINT;
BEGIN
  NEW(r, L.Length(a^) + L.Length(b) + 1);
  i := 0; WHILE a[i] # 0X DO r[i] := a[i]; INC(i) END;
  k := 0; WHILE b[k] # 0X DO r[i] := b[k]; INC(i); INC(k) END;
  r[i] := 0X;
  RETURN r
END Cat;

PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 8 OF CHAR; k, i: INTEGER;
BEGIN
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  i := 0; WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END;
  s[i] := 0X
END Num;

(* The text t[start .. end-1] without blanks at its ends *)
PROCEDURE Trimmed(start, end: LONGINT): Str;
BEGIN
  WHILE (start < end) & (L.IsBlank(sc.t[start]) OR (sc.t[start] = 0AX)) DO INC(start) END;
  WHILE (end > start) & (L.IsBlank(sc.t[end - 1]) OR (sc.t[end - 1] = 0AX)) DO DEC(end) END;
  RETURN L.Sub(sc.t^, start, end - start)
END Trimmed;

PROCEDURE Label(s: Str): F.Label;
BEGIN
  RETURN F.MarkdownLabel(s^, 0, L.Length(s^))
END Label;

(* Skips what is between statements, "#" comments too *)
PROCEDURE SkipSpace;
BEGIN
  LOOP
    sc.SkipSpace;
    IF sc.Ch() = "#" THEN sc.SkipLine ELSE EXIT END
  END
END SkipSpace;

(* Whether the statement ends here, after blanks: at a line end, ";",
   a comment, the end, or a composite state's "}" *)
PROCEDURE AtEnd(): BOOLEAN;
  VAR r: BOOLEAN;
BEGIN
  r := sc.AtStatementEnd();
  RETURN r OR (sc.Ch() = "#") OR (current # NIL) & (sc.Ch() = "}")
END AtEnd;

PROCEDURE ExpectEnd;
BEGIN
  IF ~AtEnd() THEN sc.Error("unexpected text") END
END ExpectEnd;

(* A state's id: anything but blanks, line ends, ":", "-", "{", "}",
   ";" and a comment's "%%" *)
PROCEDURE Id(): Str;
  VAR start: LONGINT; ch: CHAR;
BEGIN
  start := sc.pos;
  LOOP
    ch := sc.Ch();
    IF sc.AtEnd() OR L.IsBlank(ch) OR (ch = 0AX) OR (ch = ":") OR (ch = "-") OR (ch = "{")
       OR (ch = "}") OR (ch = ";") OR sc.LookingAt("%%") THEN EXIT
    END;
    INC(sc.pos)
  END;
  IF sc.pos = start THEN RETURN NIL END;
  RETURN L.Sub(sc.t^, start, sc.pos - start)
END Id;

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

(* The model *)

(* The state id, made with shape shape if it is new; it is in the
   cluster being read now *)
PROCEDURE State(id: Str; shape: INTEGER): F.Node;
  VAR n: F.Node; d: Ints; p: Longs; i: LONGINT;
BEGIN
  n := F.FindNode(id^);
  IF n = NIL THEN
    n := F.GetNode(id); n.shape := shape;
    IF n.index >= LEN(descs^) THEN
      NEW(d, 2 * LEN(descs^)); NEW(p, 2 * LEN(descs^));
      FOR i := 0 TO LEN(descs^) - 1 DO d[i] := descs[i]; p[i] := descPos[i] END;
      descs := d; descPos := p
    END;
    descs[n.index] := 0; descPos[n.index] := 0
  END;
  n.cluster := current;
  RETURN n
END State;

(* The start ("[*]" before "-->", or alone) or the end of the cluster
   being read *)
PROCEDURE StartEnd(start: BOOLEAN): F.Node;
  VAR id: Str;
BEGIN
  IF current = NIL THEN id := L.New("root") ELSE id := current.id END;
  IF start THEN RETURN State(Cat(id, "_start"), F.SmCircle) END;
  RETURN State(Cat(id, "_end"), F.FrCircle)
END StartEnd;

(* Adds the description s, read at pos, to n: the first is its name,
   and more make a state with descriptions *)
PROCEDURE Describe(n: F.Node; s: Str; pos: LONGINT);
  VAR lab: F.Label; l: F.Line;
BEGIN
  lab := Label(s);
  IF descs[n.index] = 0 THEN n.label := lab; n.shape := F.StateBox
  ELSE
    l := n.label.lines; WHILE l.next # NIL DO l := l.next END;
    l.next := lab.lines; INC(n.label.n, lab.n);
    n.shape := F.StateDesc;
    IF descs[n.index] = 1 THEN descPos[n.index] := pos END
  END;
  INC(descs[n.index])
END Describe;

PROCEDURE AddPending(kind: INTEGER; id, a, b: Str);
  VAR p: Pending;
BEGIN
  NEW(p); p.kind := kind; p.id := id; p.a := a; p.b := b; p.next := NIL;
  IF pending = NIL THEN pending := p ELSE lastPending.next := p END;
  lastPending := p
END AddPending;

(* The cluster id, or NIL *)
PROCEDURE FindCluster(id: Str): F.Cluster;
  VAR c: F.Cluster;
BEGIN
  c := g.clusters;
  WHILE (c # NIL) & ~L.Equal(c.id, id) DO c := c.next END;
  IF c = NIL THEN
    c := current;
    WHILE (c # NIL) & ~L.Equal(c.id, id) DO c := c.parent END
  END;
  RETURN c
END FindCluster;

(* Ends a region of composite state c: the states and composite states
   now directly in c go into a new region, and its start and end are
   renamed for it *)
PROCEDURE Region(c: F.Cluster);
  VAR r, k: F.Cluster; n: F.Node; num: ARRAY 8 OF CHAR; start, end: Str;
BEGIN
  INC(dividers); Num(dividers, num);
  r := F.NewCluster(Cat(L.New("divider-id-"), num), NIL, c, F.Region);
  r.dir := segDir; segDir := F.TB;
  start := Cat(c.id, "_start"); end := Cat(c.id, "_end");
  n := g.nodes;
  WHILE n # NIL DO
    IF n.cluster = c THEN
      n.cluster := r;
      IF L.Equal(n.id, start) THEN n.id := Cat(r.id, "_start")
      ELSIF L.Equal(n.id, end) THEN n.id := Cat(r.id, "_end")
      END
    END;
    n := n.next
  END;
  k := g.clusters;
  WHILE k # NIL DO
    IF (k.parent = c) & (k.kind # F.Region) THEN k.parent := r END;
    k := k.next
  END;
  F.AddCluster(r);
  INC(regions)
END Region;

(* Statements *)

PROCEDURE ^ Statement;

(* The rest of "state id {" or "state "text" as id {", the state id
   made, from after its "{": the composite state's statements, to its
   "}"; pos is where the statement was *)
PROCEDURE Composite(id: Str; pos: LONGINT);
  VAR c, saveCur: F.Cluster; saveDir, saveRegions: INTEGER; n: F.Node; open: LONGINT;
    left: BOOLEAN; k: F.Cluster;
BEGIN
  open := sc.pos - 1;
  IF FindCluster(id) # NIL THEN sc.ErrorAt(pos, "a composite state with this name is already there") END;
  c := F.NewCluster(id, NIL, current, F.Composite);
  saveCur := current; saveDir := segDir; saveRegions := regions;
  current := c; segDir := F.TB; regions := 0;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN sc.ErrorAt(open, "a composite state has no }") END;
    IF sc.Ch() = "}" THEN INC(sc.pos); EXIT END;
    Statement
  END;
  IF regions > 0 THEN
    (* the last region, if it holds anything *)
    left := FALSE;
    n := g.nodes; WHILE n # NIL DO IF n.cluster = c THEN left := TRUE END; n := n.next END;
    k := g.clusters; WHILE k # NIL DO IF (k.parent = c) & (k.kind # F.Region) THEN left := TRUE END; k := k.next END;
    IF left THEN Region(c) END;
    c.dir := F.TB
  ELSE c.dir := segDir
  END;
  F.AddCluster(c);
  current := saveCur; segDir := saveDir; regions := saveRegions;
  ExpectEnd
END Composite;

(* The text of a description or a one-line note, to the statement's end *)
PROCEDURE Text(): Str;
  VAR start: LONGINT;
BEGIN
  sc.SkipBlanks; start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & (sc.Ch() # ";") & ~((current # NIL) & (sc.Ch() = "}")) DO
    INC(sc.pos)
  END;
  RETURN Trimmed(start, sc.pos)
END Text;

(* Where the last w on the line, from the position to e, starts, in
   any case; or -1 *)
PROCEDURE Marker(e: LONGINT; w: ARRAY OF CHAR): LONGINT;
  VAR p, save, r: LONGINT;
BEGIN
  save := sc.pos; r := -1; p := sc.pos;
  WHILE p < e DO
    sc.pos := p; IF At(w) THEN r := p END;
    INC(p)
  END;
  sc.pos := save;
  RETURN r
END Marker;

(* "state id <<fork>>" (or "<<join>>", "<<choice>>", "[[fork]]" ...),
   "state "text" as id", with "{ ... }" or not, or "state id { ... }" *)
PROCEDURE StateStmt;
  VAR e, m, pos, start, end, colon, i: LONGINT; shape, k: INTEGER; id, desc: Str; n: F.Node;
    w: ARRAY 12 OF CHAR;
BEGIN
  sc.SkipBlanks; pos := sc.pos;
  e := sc.pos; WHILE (e < sc.len) & (sc.t[e] # 0AX) DO INC(e) END;
  m := -1; k := 0;
  WHILE (m < 0) & (k < 6) DO
    CASE k OF
      0: w := "<<fork>>"; shape := F.Fork
    | 1: w := "<<join>>"; shape := F.Fork
    | 2: w := "<<choice>>"; shape := F.Choice
    | 3: w := "[[fork]]"; shape := F.Fork
    | 4: w := "[[join]]"; shape := F.Fork
    | 5: w := "[[choice]]"; shape := F.Choice
    END;
    m := Marker(e, w); INC(k)
  END;
  IF m >= 0 THEN
    id := Trimmed(sc.pos, m);
    IF id[0] = 0X THEN sc.Error("expected a state's name") END;
    n := State(id, shape);
    sc.pos := m + L.Length(w);
    ExpectEnd
  ELSIF sc.Ch() = 22X THEN
    desc := Quoted();
    sc.SkipBlanks;
    IF ~Kw("as") THEN sc.Error("expected as and the state's name") END;
    INC(sc.pos, 2); sc.SkipBlanks;
    start := sc.pos;
    WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & (sc.Ch() # "{") & ~sc.LookingAt("%%") DO INC(sc.pos) END;
    end := sc.pos;
    colon := -1; i := start;
    WHILE (i < end) & (colon < 0) DO IF sc.t[i] = ":" THEN colon := i END; INC(i) END;
    IF colon >= 0 THEN id := Trimmed(start, colon) ELSE id := Trimmed(start, end) END;
    IF id[0] = 0X THEN sc.ErrorAt(start, "expected a state's name") END;
    n := State(id, F.StateBox);
    Describe(n, desc, pos);
    (* "id:text" is a second description *)
    IF colon >= 0 THEN Describe(n, Trimmed(colon + 1, end), colon) END;
    IF sc.Ch() = "{" THEN INC(sc.pos); Composite(id, pos) ELSE ExpectEnd END
  ELSE
    id := Id();
    IF id = NIL THEN sc.Error("expected a state's name") END;
    sc.SkipBlanks;
    IF sc.Ch() = "{" THEN
      n := State(id, F.StateBox);
      INC(sc.pos); Composite(id, pos)
    ELSIF ~AtEnd() THEN
      (* "state X" alone says nothing, as in Mermaid *)
      IF Marker(e, "{") >= 0 THEN sc.ErrorAt(pos, "a state's name must be one word") END;
      sc.Error("unexpected text")
    END
  END
END StateStmt;

(* A state in a transition: an id or "[*]", the start if first, else
   the end; with ":::class", which counts at the top level *)
PROCEDURE Ref(first: BOOLEAN): F.Node;
  VAR n: F.Node; id: Str; save, start: LONGINT;
BEGIN
  IF sc.Accept("[*]") THEN n := StartEnd(first)
  ELSE
    id := Id();
    IF id = NIL THEN sc.Error("expected a state") END;
    n := State(id, F.StateBox)
  END;
  save := sc.pos; sc.SkipBlanks;
  IF sc.Accept(":::") THEN
    start := sc.pos;
    WHILE ~sc.AtEnd() & L.IsWordChar(sc.Ch()) OR (sc.Ch() = "-") & (sc.Peek(1) # "-") DO INC(sc.pos) END;
    IF sc.pos = start THEN sc.Error("expected a class name") END;
    IF current = NIL THEN F.AddClass(n, L.Sub(sc.t^, start, sc.pos - start)) END
  ELSE sc.pos := save
  END;
  RETURN n
END Ref;

(* "a", "a --> b", each with ": text" or not *)
PROCEDURE IdStatement;
  VAR n1, n2: F.Node; e: F.Edge; lab: F.Label; p: LONGINT; standalone: BOOLEAN;
BEGIN
  standalone := ~sc.LookingAt("[*]");
  n1 := Ref(TRUE);
  sc.SkipBlanks;
  IF sc.Accept("-->") THEN
    sc.SkipBlanks;
    n2 := Ref(FALSE);
    sc.SkipBlanks; lab := NIL;
    IF sc.Accept(":") THEN lab := Label(Text()) END;
    e := F.NewEdge(n1, n2, F.Arrow, F.None, F.Normal, lab);
    INC(items)
  ELSIF sc.Ch() = ":" THEN
    p := sc.pos; INC(sc.pos);
    Describe(n1, Text(), p)
  END;
  ExpectEnd
END IdStatement;

(* "note left of id : text", "note right of id", its lines, "end note",
   or a floating note, "note "text" as id", which is not drawn *)
PROCEDURE Note;
  VAR right: BOOLEAN; id, text: Str; n, note: F.Node; pos, start, p, q: LONGINT; e: F.Edge;
    num: ARRAY 8 OF CHAR;
BEGIN
  pos := sc.pos - 4;
  sc.SkipBlanks;
  IF sc.Ch() = 22X THEN sc.SkipLine; RETURN END;
  IF Kw("left") THEN INC(sc.pos, 4); right := FALSE
  ELSIF Kw("right") THEN INC(sc.pos, 5); right := TRUE
  ELSE sc.Error("expected left of or right of")
  END;
  sc.SkipBlanks;
  IF ~Kw("of") THEN sc.Error("expected of") END;
  INC(sc.pos, 2); sc.SkipBlanks;
  id := Id();
  IF id = NIL THEN sc.Error("expected a state") END;
  sc.SkipBlanks;
  IF sc.Accept(":") THEN text := Text(); ExpectEnd
  ELSE
    IF sc.Ch() # 0AX THEN sc.Error("expected : or the note's lines") END;
    start := sc.pos; p := start; q := -1;
    WHILE (q < 0) & (p < sc.len) DO
      IF sc.t[p] = 0AX THEN
        sc.pos := p + 1; sc.SkipBlanks;
        IF At("end note") THEN q := p END
      END;
      INC(p)
    END;
    IF q < 0 THEN sc.ErrorAt(pos, 'a note has no "end note"') END;
    text := Trimmed(start, q);
    INC(sc.pos, 8); ExpectEnd
  END;
  Num(items, num); INC(items);
  note := State(Cat(Cat(id, "----note-"), num), F.Rect);
  note.label := Label(text);
  n := State(id, F.StateBox);
  IF right THEN e := F.NewEdge(n, note, F.None, F.None, F.Dotted, NIL)
  ELSE e := F.NewEdge(note, n, F.None, F.None, F.Dotted, NIL)
  END
END Note;

(* The ids of a class, style or click statement, "a,b,c", each to be
   given kind with a and b *)
PROCEDURE Ids(kind: INTEGER; a, b: Str; ids: Str);
  VAR i, start: LONGINT;
BEGIN
  i := 0;
  WHILE ids[i] # 0X DO
    start := i;
    WHILE (ids[i] # 0X) & (ids[i] # ",") DO INC(i) END;
    IF i > start THEN AddPending(kind, L.Sub(ids^, start, i - start), a, b) END;
    IF ids[i] = "," THEN INC(i) END
  END
END Ids;

(* The first word of a class, style or click statement *)
PROCEDURE Word(): Str;
  VAR start: LONGINT;
BEGIN
  sc.SkipBlanks; start := sc.pos;
  WHILE ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) & (sc.Ch() # ";") DO INC(sc.pos) END;
  IF sc.pos = start THEN sc.Error("expected a state") END;
  RETURN L.Sub(sc.t^, start, sc.pos - start)
END Word;

(* "class ids name", "style ids props": a class's ids may have blanks
   after their commas, as in Mermaid *)
PROCEDURE ClassOrStyle(kind: INTEGER);
  VAR ids, s: Str; start, i, k: LONGINT;
BEGIN
  sc.SkipBlanks; start := sc.pos;
  LOOP
    WHILE L.IsWordChar(sc.Ch()) DO INC(sc.pos) END;
    IF sc.Ch() # "," THEN EXIT END;
    INC(sc.pos);
    IF kind = ClassP THEN sc.SkipBlanks END
  END;
  IF sc.pos = start THEN sc.Error("expected a state") END;
  ids := L.Sub(sc.t^, start, sc.pos - start);
  i := 0; k := 0;
  WHILE ids[i] # 0X DO IF ~L.IsBlank(ids[i]) THEN ids[k] := ids[i]; INC(k) END; INC(i) END;
  ids[k] := 0X;
  s := sc.Rest();
  IF s[0] = 0X THEN
    IF kind = ClassP THEN sc.Error("expected a class name") ELSE sc.Error("expected a style") END
  END;
  Ids(kind, s, NIL, ids)
END ClassOrStyle;

(* "click id "url" "tooltip"" or "click id href "url" "tooltip"" *)
PROCEDURE Click;
  VAR ids, url, tip: Str;
BEGIN
  ids := Word();
  sc.SkipBlanks;
  IF Kw("href") THEN INC(sc.pos, 4); sc.SkipBlanks END;
  IF sc.Ch() # 22X THEN sc.Error("expected a URL in quotation marks") END;
  url := Quoted(); sc.SkipBlanks; tip := NIL;
  IF sc.Ch() = 22X THEN tip := Quoted() END;
  ExpectEnd;
  Ids(ClickP, url, tip, ids)
END Click;

(* "direction TB" (BT, LR, RL): the diagram's, or the region's *)
PROCEDURE Direction;
  VAR d: INTEGER;
BEGIN
  sc.SkipBlanks;
  IF At("TB") THEN d := F.TB ELSIF At("BT") THEN d := F.BT
  ELSIF At("LR") THEN d := F.LR ELSIF At("RL") THEN d := F.RL
  ELSE sc.Error("expected TB, BT, LR or RL")
  END;
  INC(sc.pos, 2); ExpectEnd;
  IF current = NIL THEN g.dir := d ELSE segDir := d END
END Direction;

PROCEDURE Statement;
BEGIN
  IF Kw("state") THEN INC(sc.pos, 5); StateStmt
  ELSIF Kw("note") THEN INC(sc.pos, 4); Note
  ELSIF Kw("direction") THEN INC(sc.pos, 9); Direction
  ELSIF Kw("classDef") OR Kw("class") OR Kw("style") OR Kw("click") THEN
    IF current # NIL THEN sc.SkipLine (* they count at the top level only *)
    ELSIF Kw("classDef") THEN INC(sc.pos, 8); F.ClassDefStmt
    ELSIF Kw("class") THEN INC(sc.pos, 5); ClassOrStyle(ClassP)
    ELSIF Kw("style") THEN INC(sc.pos, 5); ClassOrStyle(StyleP)
    ELSE INC(sc.pos, 5); Click
    END
  ELSIF Kw("scale") OR At("hide empty description") THEN sc.SkipLine
  ELSIF At("accTitle") OR At("accDescr") THEN F.Accessibility
  ELSIF sc.LookingAt("--") & ~sc.LookingAt("-->") THEN
    IF current = NIL THEN sc.Error("-- divides only a composite state") END;
    INC(sc.pos, 2); Region(current); ExpectEnd
  ELSE IdStatement
  END
END Statement;

(* The end: the class, style and click statements applied, the
   composite states' titles, the alternate colour, and labels *)
PROCEDURE Finish;
  VAR p: Pending; n: F.Node; c, k: F.Cluster; depth: INTEGER;
BEGIN
  p := pending;
  WHILE p # NIL DO
    n := F.FindNode(p.id^);
    CASE p.kind OF
      ClassP:
        IF n # NIL THEN F.AddClass(n, p.a) END;
        c := FindCluster(p.id);
        IF c # NIL THEN F.AddName(c.classes, p.a) END
    | StyleP: IF n # NIL THEN n.style := F.Props(p.a) END
    | ClickP: IF n # NIL THEN n.link := p.a; n.tooltip := p.b END
    END;
    p := p.next
  END;
  c := g.clusters;
  WHILE c # NIL DO
    depth := 0; k := c.parent;
    WHILE k # NIL DO INC(depth); k := k.parent END;
    c.alt := ODD(depth);
    IF c.kind = F.Composite THEN
      n := F.FindNode(c.id^);
      IF descs[n.index] > 1 THEN
        sc.ErrorAt(descPos[n.index], "a composite state can have only one name, not descriptions")
      END;
      IF n.label = NIL THEN n.label := Label(n.id) END;
      c.title := n.label
    END;
    c := c.next
  END;
  n := g.nodes;
  WHILE n # NIL DO
    IF n.label = NIL THEN n.label := Label(n.id) END;
    n := n.next
  END;
  F.Finish
END Finish;

(* Whether the scanner's text, after front matter and comments, starts
   with "stateDiagram" *)
PROCEDURE IsState*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("stateDiagram");
  s.pos := save;
  RETURN r
END IsState;

(* Reads the state diagram in s's text into graph *)
PROCEDURE Read*(s: L.Scanner; VAR graph: F.Graph);
BEGIN
  F.Begin(s, F.State, g); graph := g; sc := s;
  current := NIL; segDir := F.TB; regions := 0; items := 0; dividers := 0;
  pending := NIL; lastPending := NIL;
  NEW(descs, 64); NEW(descPos, 64);
  IF ~(sc.Accept("stateDiagram-v2") OR sc.Accept("stateDiagram")) THEN
    sc.Error("expected stateDiagram-v2 or stateDiagram")
  END;
  ExpectEnd;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Finish
END Read;

END PmState.
