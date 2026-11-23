MODULE PmGit;
(* PmGit: Mermaid's git graphs (`gitGraph`), read into a model of their
   own: the commits, in the order Mermaid keeps them, each with its id,
   message, type, tags, parents and branch; the branches, each with its
   name, order and tip; the direction; the title; and the
   configuration, config.gitGraph.

   The reader follows Mermaid 12.3.0's grammar, packages/parser/src/
   language/gitGraph/gitGraph.langium, reference.langium and
   common.langium, gitGraphParser.ts, and what gitGraphAst.ts, its db,
   makes of it:

   - the graph starts with "gitGraph", "gitGraph:", or "gitGraph LR:",
     "TB:" or "BT:"; keywords are read in this case only;
   - blanks, "%%" comments and "%%{ ... }%%" directives are skipped;
     each statement ends its line;
   - "title text": the rest of the line, up to a "%%"; accTitle and
     accDescr are read and skipped;
   - "commit", then any of `id: "x"`, `msg: "x"` or just `"x"`,
     `tag: "x"`, `type: NORMAL|REVERSE|HIGHLIGHT`; the last id,
     message and type are kept, every tag;
   - "branch name", then `order: N`, an integer;
   - "merge name", then any of id:, tag: and type:;
   - "checkout name" or "switch name";
   - "cherry-pick", then any of id:, tag: and `parent: "x"`;
   - a name is a reference, a letter, a digit or "_", then those and
     "-", "." and "/", not ending in "." or "/", or a string; a keyword
     followed by more of a reference is a reference, as Mermaid's lexer
     reads it;
   - a string is in double or single quotation marks, its escapes read
     as Langium reads them, as PmPie's.

   The db's rules, and its errors, are Mermaid's: a commit's parent is
   the head, the current branch's tip, if any; a branch starts at the
   head and is checked out; a merge commit's parents are the head and
   the merged branch's tip; a cherry-pick's are the head and the
   commit picked. A commit with an id already used replaces the one
   before it, in its place. A commit with no id is given one, its
   sequence number, "-" and 7 hexadecimal digits: Mermaid's are random,
   pomermaid's a hash of the number, the branch and the message
   (decision 24). *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml, X := PmXy;

CONST
  (* commit types, Mermaid's numbers *)
  Normal* = 0; Reverse* = 1; Highlight* = 2; Merge* = 3; CherryPick* = 4;
  (* directions *)
  LR* = 0; TB* = 1; BT* = 2;

TYPE
  Str = L.Str;

  Tag* = POINTER TO TagDesc;
  TagDesc* = RECORD
    text-: Str;
    next-: Tag
  END;

  Branch* = POINTER TO BranchDesc;

  Commit* = POINTER TO CommitDesc;
  CommitDesc* = RECORD
    id-, msg-: Str;
    seq-: LONGINT;          (* from 0, in order made *)
    type-: INTEGER;
    customType-: INTEGER;   (* a merge's type:, or -1 *)
    customId-: BOOLEAN;     (* whether a merge's id was given *)
    tags-: Tag; nTags-: INTEGER;
    parents-: ARRAY 2 OF Str;  (* ids, NIL if fewer *)
    nParents-: INTEGER;
    branch-: Branch;
    next-: Commit           (* in Mermaid's order, its Map's *)
  END;

  BranchDesc* = RECORD
    name-: Str;
    order-: LONGREAL;
    index-: INTEGER;        (* its place, from 0, ordered by order *)
    tip: Str;               (* its last commit's id, or NIL *)
    next-: Branch           (* in the order made *)
  END;

  Branches* = POINTER TO ARRAY OF Branch;
  Commits* = POINTER TO ARRAY OF Commit;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;            (* the title and the configuration *)
    dir-: INTEGER;
    commits-: Commit; nCommits-: LONGINT;
    branches-: Branch; nBranches-: INTEGER;
    sorted-: Branches;      (* sorted[0 .. nBranches-1], by order *)
    bySeq-: Commits;        (* bySeq[0 .. nCommits-1], by seq *)
    (* config.gitGraph *)
    titleTopMargin-, diagramPadding-: LONGREAL;
    showCommitLabel-, showBranches-, rotateCommitLabel-, parallelCommits-: BOOLEAN;
    mainBranchName-: Str;
    lastCommit: Commit; lastBranch: Branch;
    cur: Branch; head: Commit;
    seq: LONGINT
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;

(* Skips blanks and comments, not line ends *)
PROCEDURE Hidden;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSE EXIT
    END
  END
END Hidden;

(* Skips blanks, line ends, comments and directives *)
PROCEDURE SkipSpace;
BEGIN
  LOOP
    Hidden;
    IF sc.Ch() = 0AX THEN INC(sc.pos) ELSE EXIT END
  END
END SkipSpace;

PROCEDURE Put(VAR n: LONGINT; ch: CHAR);
  VAR b: Str; k: LONGINT;
BEGIN
  IF n + 1 >= LEN(buf^) THEN
    NEW(b, 2 * LEN(buf^));
    FOR k := 0 TO n - 1 DO b[k] := buf[k] END;
    buf := b
  END;
  buf[n] := ch; INC(n)
END Put;

(* Appends s to buf[0 .. n-1] *)
PROCEDURE PutS(VAR n: LONGINT; s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(n, s[i]); INC(i) END
END PutS;

(* Fails at the position at with a, s and b *)
PROCEDURE Fail(at: LONGINT; a: ARRAY OF CHAR; s: Str; b: ARRAY OF CHAR);
  VAR n: LONGINT;
BEGIN
  n := 0; PutS(n, a); PutS(n, s^); PutS(n, b); buf[n] := 0X;
  sc.ErrorAt(at, buf^)
END Fail;

(* Fails at at with a, s, b, t and c *)
PROCEDURE Fail2(at: LONGINT; a: ARRAY OF CHAR; s: Str; b: ARRAY OF CHAR; t: Str;
  c: ARRAY OF CHAR);
  VAR n: LONGINT;
BEGIN
  n := 0; PutS(n, a); PutS(n, s^); PutS(n, b); PutS(n, t^); PutS(n, c); buf[n] := 0X;
  sc.ErrorAt(at, buf^)
END Fail2;

(* Warns about the text at at with a, s and b: "NAME:LINE:COL: asb" *)
PROCEDURE Warn(at: LONGINT; a: ARRAY OF CHAR; s: Str; b: ARRAY OF CHAR);
  VAR n, line, col: LONGINT;
  PROCEDURE Num(k: LONGINT);
    VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
  BEGIN
    i := 0; REPEAT dg[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
    WHILE i > 0 DO DEC(i); Put(n, dg[i]) END
  END Num;
BEGIN
  sc.Where(at, line, col);
  n := 0; PutS(n, sc.name); Put(n, ":"); Num(line); Put(n, ":"); Num(col); PutS(n, ": ");
  PutS(n, a); PutS(n, s^); PutS(n, b); buf[n] := 0X;
  PmIO.Warn(buf^)
END Warn;

(* Whether ch may be in a reference *)
PROCEDURE IsWord(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "a") & (ch <= "z") OR (ch >= "A") & (ch <= "Z") OR L.IsDigit(ch)
    OR (ch = "_")
END IsWord;

(* The length of the reference at the position, 0 if there is none *)
PROCEDURE RefLength(): LONGINT;
  VAR i, n: LONGINT; ch: CHAR;
BEGIN
  IF ~IsWord(sc.Ch()) THEN RETURN 0 END;
  n := 1; i := 1;
  LOOP
    ch := sc.Peek(i);
    IF IsWord(ch) OR (ch = "-") THEN INC(i); n := i
    ELSIF (ch = ".") OR (ch = "/") THEN INC(i)
    ELSE EXIT
    END
  END;
  RETURN n
END RefLength;

(* Whether the text at the position is the keyword w, not the start of
   a longer reference *)
PROCEDURE Keyword(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN sc.LookingAt(w) & (RefLength() <= L.Length(w))
END Keyword;

(* "title text", after "title" *)
PROCEDURE Title;
  VAR start, end: LONGINT;
BEGIN
  IF ~sc.AtEnd() & ~L.IsBlank(sc.Ch()) & (sc.Ch() # 0AX) THEN
    sc.Error("expected a blank after title")
  END;
  sc.SkipBlanks; start := sc.pos;
  WHILE ~sc.AtEnd() & (sc.Ch() # 0AX) & ~sc.LookingAt("%%") DO INC(sc.pos) END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  IF end > start THEN d.g.title := F.TextLabel(sc.t^, start, end) ELSE d.g.title := NIL END
END Title;

(* A string, at its quotation mark: its text, its escapes read *)
PROCEDURE String(): Str;
  VAR q, ch: CHAR; n: LONGINT;
BEGIN
  q := sc.Ch(); INC(sc.pos); n := 0;
  LOOP
    IF sc.AtEnd() OR (sc.Ch() = 0AX) THEN sc.Error("the string has no closing quotation mark") END;
    ch := sc.Ch(); INC(sc.pos);
    IF ch = q THEN EXIT
    ELSIF ch = "\" THEN
      IF sc.AtEnd() THEN sc.Error("the string has no closing quotation mark") END;
      ch := sc.Ch(); INC(sc.pos);
      CASE ch OF
        "b", "f", "n", "r", "t", "v", "0": Put(n, " ")
      ELSE Put(n, ch)
      END
    ELSE Put(n, ch)
    END
  END;
  buf[n] := 0X;
  RETURN L.Sub(buf^, 0, n)
END String;

PROCEDURE IsString(): BOOLEAN;
BEGIN
  RETURN (sc.Ch() = '"') OR (sc.Ch() = "'")
END IsString;

(* A string, after a keyword such as "id:" *)
PROCEDURE StringArg(what: ARRAY OF CHAR): Str;
  VAR n: LONGINT;
BEGIN
  Hidden;
  IF ~IsString() THEN
    n := 0; PutS(n, "expected a quoted string after "); PutS(n, what); buf[n] := 0X;
    sc.Error(buf^)
  END;
  RETURN String()
END StringArg;

(* A branch's name: a reference or a string *)
PROCEDURE Name(): Str;
  VAR n, start: LONGINT;
BEGIN
  Hidden;
  IF IsString() THEN RETURN String() END;
  n := RefLength();
  IF n = 0 THEN sc.Error("expected a branch's name") END;
  start := sc.pos; INC(sc.pos, n);
  RETURN L.Sub(sc.t^, start, n)
END Name;

(* The end of a statement: its line's end, or the text's *)
PROCEDURE Eol;
BEGIN
  Hidden;
  IF ~sc.AtEnd() & (sc.Ch() # 0AX) THEN sc.Error("expected the end of the line") END
END Eol;

(* type: NORMAL, REVERSE or HIGHLIGHT, after "type:" *)
PROCEDURE Type(): INTEGER;
BEGIN
  Hidden;
  IF Keyword("NORMAL") THEN INC(sc.pos, 6); RETURN Normal
  ELSIF Keyword("REVERSE") THEN INC(sc.pos, 7); RETURN Reverse
  ELSIF Keyword("HIGHLIGHT") THEN INC(sc.pos, 9); RETURN Highlight
  END;
  sc.Error("expected NORMAL, REVERSE or HIGHLIGHT");
  RETURN Normal
END Type;

PROCEDURE AddTag(VAR first, last: Tag; VAR n: INTEGER; s: Str);
  VAR t: Tag;
BEGIN
  NEW(t); t.text := s; t.next := NIL; INC(n);
  IF first = NIL THEN first := t ELSE last.next := t END;
  last := t
END AddTag;

(* The branch named name, or NIL *)
PROCEDURE FindBranch(name: Str): Branch;
  VAR b: Branch;
BEGIN
  b := d.branches;
  WHILE (b # NIL) & ~L.Equal(b.name, name) DO b := b.next END;
  RETURN b
END FindBranch;

(* The commit with the id id, or NIL *)
PROCEDURE Find*(dg: Diagram; id: Str): Commit;
  VAR c: Commit;
BEGIN
  IF id = NIL THEN RETURN NIL END;
  c := dg.commits;
  WHILE (c # NIL) & ~L.Equal(c.id, id) DO c := c.next END;
  RETURN c
END Find;

(* id, or, if it is NIL or empty, the made id: the sequence number,
   "-" and 7 hexadecimal digits, a hash of the number, the branch's
   name and the message *)
PROCEDURE MakeId(id: Str; msg: Str): Str;
  VAR h, k: LONGINT; n, i: LONGINT; num: ARRAY 24 OF CHAR; x: LONGREAL;
    hex: ARRAY 8 OF CHAR;

  PROCEDURE Mix(s: ARRAY OF CHAR);
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE (j < LEN(s)) & (s[j] # 0X) DO
      h := (h MOD 800000H) * 131 + ORD(s[j]); INC(j)
    END;
    h := (h MOD 800000H) * 131 + 1
  END Mix;

BEGIN
  IF (id # NIL) & (id[0] # 0X) THEN RETURN id END;
  x := d.seq; X.JsNumber(x, num);
  h := 7; Mix(num); Mix(d.cur.name^); Mix(msg^);
  h := h MOD 10000000H;
  FOR k := 6 TO 0 BY -1 DO
    i := h MOD 16; h := h DIV 16;
    IF i < 10 THEN hex[k] := CHR(ORD("0") + i) ELSE hex[k] := CHR(ORD("a") + i - 10) END
  END;
  hex[7] := 0X;
  n := 0; PutS(n, num); Put(n, "-"); PutS(n, hex); buf[n] := 0X;
  RETURN L.Sub(buf^, 0, n)
END MakeId;

(* Adds the commit c, made at the head of the current branch by the
   statement at at *)
PROCEDURE Add(c: Commit; at: LONGINT);
  VAR p, q: Commit;
BEGIN
  c.seq := d.seq; INC(d.seq);
  c.branch := d.cur; c.next := NIL;
  p := d.commits; q := NIL;
  WHILE (p # NIL) & ~L.Equal(p.id, c.id) DO q := p; p := p.next END;
  IF p # NIL THEN  (* replaces p, in its place *)
    Warn(at, "commit ID ", c.id, " already exists");
    c.next := p.next;
    IF q = NIL THEN d.commits := c ELSE q.next := c END;
    IF d.lastCommit = p THEN d.lastCommit := c END
  ELSE
    IF d.lastCommit = NIL THEN d.commits := c ELSE d.lastCommit.next := c END;
    d.lastCommit := c; INC(d.nCommits)
  END;
  d.head := c; d.cur.tip := c.id
END Add;

PROCEDURE NewCommit(): Commit;
  VAR c: Commit;
BEGIN
  NEW(c); c.id := NIL; c.msg := L.New(""); c.type := Normal; c.customType := -1;
  c.customId := FALSE; c.tags := NIL; c.nTags := 0;
  c.parents[0] := NIL; c.parents[1] := NIL; c.nParents := 0;
  RETURN c
END NewCommit;

(* a, s, b and t, joined *)
PROCEDURE Concat(a: ARRAY OF CHAR; s: Str; b: ARRAY OF CHAR; t: Str): Str;
  VAR n: LONGINT;
BEGIN
  n := 0; PutS(n, a); PutS(n, s^); PutS(n, b);
  IF t # NIL THEN PutS(n, t^) END;
  buf[n] := 0X;
  RETURN L.Sub(buf^, 0, n)
END Concat;

(* "commit" and what follows *)
PROCEDURE CommitStmt(at: LONGINT);
  VAR c: Commit; last: Tag; id: Str;
BEGIN
  c := NewCommit(); last := NIL; id := NIL;
  LOOP
    Hidden;
    IF Keyword("id:") THEN INC(sc.pos, 3); id := StringArg("id:")
    ELSIF Keyword("msg:") THEN INC(sc.pos, 4); c.msg := StringArg("msg:")
    ELSIF IsString() THEN c.msg := String()
    ELSIF Keyword("tag:") THEN INC(sc.pos, 4); AddTag(c.tags, last, c.nTags, StringArg("tag:"))
    ELSIF Keyword("type:") THEN INC(sc.pos, 5); c.type := Type()
    ELSE EXIT
    END
  END;
  Eol;
  c.id := MakeId(id, c.msg);
  IF d.head # NIL THEN c.parents[0] := d.head.id; c.nParents := 1 END;
  Add(c, at)
END CommitStmt;

(* Checks out the branch named name, from at *)
PROCEDURE Checkout(at: LONGINT; name: Str);
  VAR b: Branch;
BEGIN
  b := FindBranch(name);
  IF b = NIL THEN
    Fail(at, 'Trying to checkout branch which is not yet created. (Help try using "branch ',
      name, '")')
  END;
  d.cur := b; d.head := Find(d, b.tip)
END Checkout;

PROCEDURE NewBranch(name: Str; order: LONGREAL);
  VAR b: Branch;
BEGIN
  NEW(b); b.name := name; b.order := order; b.tip := NIL; b.next := NIL; b.index := 0;
  IF d.head # NIL THEN b.tip := d.head.id END;
  IF d.lastBranch = NIL THEN d.branches := b ELSE d.lastBranch.next := b END;
  d.lastBranch := b; INC(d.nBranches)
END NewBranch;

(* "branch name" and what follows *)
PROCEDURE BranchStmt(at: LONGINT);
  VAR name: Str; order: LONGREAL; start: LONGINT; ok: BOOLEAN; n: ARRAY 64 OF CHAR;
BEGIN
  (* without an order, Mermaid's is parseFloat("0." + i), i the
     branch's place in the order made: 0.1 for the second *)
  X.JsNumber(d.nBranches, n); order := 0;
  ok := X.JsParse(Concat("0.", L.New(n), "", NIL), order);
  name := Name(); Hidden;
  IF Keyword("order:") THEN
    INC(sc.pos, 6); Hidden; start := sc.pos;
    IF sc.Ch() = "0" THEN INC(sc.pos)
    ELSIF (sc.Ch() >= "1") & (sc.Ch() <= "9") THEN
      WHILE L.IsDigit(sc.Ch()) DO INC(sc.pos) END
    END;
    IF (sc.pos = start) OR (sc.Ch() = ".") THEN sc.ErrorAt(start, "expected an integer, the order") END;
    ok := X.JsParse(L.Sub(sc.t^, start, sc.pos - start), order)
  END;
  Eol;
  IF FindBranch(name) # NIL THEN
    Fail(at, 'Trying to create an existing branch. (Help: Either use a new name if you want create a new branch or try using "checkout ',
      name, '")')
  END;
  NewBranch(name, order);
  Checkout(at, name)
END BranchStmt;

(* "merge name" and what follows *)
PROCEDURE MergeStmt(at: LONGINT);
  VAR name, id: Str; c, cur, other: Commit; b: Branch; last: Tag; type: INTEGER;
BEGIN
  name := Name(); id := NIL; type := -1;
  c := NewCommit(); last := NIL;
  LOOP
    Hidden;
    IF Keyword("id:") THEN INC(sc.pos, 3); id := StringArg("id:")
    ELSIF Keyword("tag:") THEN INC(sc.pos, 4); AddTag(c.tags, last, c.nTags, StringArg("tag:"))
    ELSIF Keyword("type:") THEN INC(sc.pos, 5); type := Type()
    ELSE EXIT
    END
  END;
  Eol;
  b := FindBranch(name);
  cur := Find(d, d.cur.tip); other := NIL;
  IF b # NIL THEN other := Find(d, b.tip) END;
  IF (cur # NIL) & (other # NIL) & L.Equal(cur.branch.name, name) THEN
    Fail(at, "Cannot merge branch '", name, "' into itself.")
  END;
  IF b = d.cur THEN
    sc.ErrorAt(at, 'Incorrect usage of "merge". Cannot merge a branch to itself')
  END;
  IF cur = NIL THEN
    Fail(at, 'Incorrect usage of "merge". Current branch (', d.cur.name, ")has no commits")
  END;
  IF b = NIL THEN
    Fail(at, 'Incorrect usage of "merge". Branch to be merged (', name, ") does not exist")
  END;
  IF other = NIL THEN
    Fail(at, 'Incorrect usage of "merge". Branch to be merged (', name, ") has no commits")
  END;
  IF cur = other THEN
    sc.ErrorAt(at, 'Incorrect usage of "merge". Both branches have same head')
  END;
  IF (id # NIL) & (id[0] # 0X) & (Find(d, id) # NIL) THEN
    Fail(at, 'Incorrect usage of "merge". Commit with id:', id, " already exists, use different custom id")
  END;
  c.customId := (id # NIL) & (id[0] # 0X);
  c.customType := type; c.type := Merge;
  c.msg := Concat("merged branch ", name, " into ", d.cur.name);
  c.id := MakeId(id, c.msg);
  IF d.head # NIL THEN
    c.parents[0] := d.head.id; c.parents[1] := b.tip; c.nParents := 2
  END;
  Add(c, at)
END MergeStmt;

(* "cherry-pick" and what follows *)
PROCEDURE CherryPickStmt(at: LONGINT);
  VAR id, parent, s: Str; c, src: Commit; last: Tag; given: BOOLEAN; t, u: Tag;
    n: INTEGER; k: INTEGER;
BEGIN
  id := NIL; parent := NIL; given := FALSE;
  c := NewCommit(); last := NIL;
  LOOP
    Hidden;
    IF Keyword("id:") THEN INC(sc.pos, 3); id := StringArg("id:")
    ELSIF Keyword("tag:") THEN
      INC(sc.pos, 4); AddTag(c.tags, last, c.nTags, StringArg("tag:")); given := TRUE
    ELSIF Keyword("parent:") THEN INC(sc.pos, 7); parent := StringArg("parent:")
    ELSE EXIT
    END
  END;
  Eol;
  src := NIL;
  IF (id # NIL) & (id[0] # 0X) THEN src := Find(d, id) END;
  IF src = NIL THEN
    sc.ErrorAt(at, 'Incorrect usage of "cherryPick". Source commit id should exist and provided')
  END;
  IF (parent # NIL) & (parent[0] # 0X) THEN
    k := 0;
    WHILE (k < src.nParents) & ~L.Equal(src.parents[k], parent) DO INC(k) END;
    IF k = src.nParents THEN
      sc.ErrorAt(at, "Invalid operation: The specified parent commit is not an immediate parent of the cherry-picked commit.")
    END
  END;
  IF (src.type = Merge) & ((parent = NIL) OR (parent[0] = 0X)) THEN
    sc.ErrorAt(at, "Incorrect usage of cherry-pick: If the source commit is a merge commit, an immediate parent commit must be specified.")
  END;
  IF src.branch = d.cur THEN
    sc.ErrorAt(at, 'Incorrect usage of "cherryPick". Source commit is already on current branch')
  END;
  IF Find(d, d.cur.tip) = NIL THEN
    Fail(at, 'Incorrect usage of "cherry-pick". Current branch (', d.cur.name, ")has no commits")
  END;
  c.type := CherryPick;
  c.msg := Concat("cherry-picked ", src.msg, " into ", d.cur.name);
  IF given THEN  (* the tags given, but empty ones *)
    t := c.tags; c.tags := NIL; last := NIL; n := 0;
    WHILE t # NIL DO
      u := t.next;
      IF t.text[0] # 0X THEN AddTag(c.tags, last, n, t.text) END;
      t := u
    END;
    c.nTags := n
  ELSE
    IF src.type = Merge THEN
      s := Concat("cherry-pick:", src.id, "|parent:", parent)
    ELSE s := Concat("cherry-pick:", src.id, "", NIL)
    END;
    AddTag(c.tags, last, c.nTags, s)
  END;
  c.id := MakeId(NIL, c.msg);
  IF d.head # NIL THEN
    c.parents[0] := d.head.id; c.parents[1] := src.id; c.nParents := 2
  END;
  Add(c, at)
END CherryPickStmt;

(* "title" and the end of its line *)
PROCEDURE TitleStmt;
BEGIN
  INC(sc.pos, 5); Title
END TitleStmt;

PROCEDURE Statement;
  VAR at: LONGINT;
BEGIN
  at := sc.pos;
  IF sc.LookingAt("title") & (RefLength() <= 5) THEN TitleStmt
  ELSIF sc.LookingAtWord("accTitle") OR sc.LookingAtWord("accDescr") THEN F.Accessibility
  ELSIF Keyword("commit") THEN INC(sc.pos, 6); CommitStmt(at)
  ELSIF Keyword("branch") THEN INC(sc.pos, 6); BranchStmt(at)
  ELSIF Keyword("merge") THEN INC(sc.pos, 5); MergeStmt(at)
  ELSIF Keyword("checkout") THEN INC(sc.pos, 8); Checkout(at, Name()); Eol
  ELSIF Keyword("switch") THEN INC(sc.pos, 6); Checkout(at, Name()); Eol
  ELSIF Keyword("cherry-pick") THEN INC(sc.pos, 11); CherryPickStmt(at)
  ELSE sc.Error("expected commit, branch, merge, checkout, switch, cherry-pick, or title")
  END
END Statement;

PROCEDURE Strings(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
  VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE a[i] # 0X DO INC(i) END;
  j := 0; WHILE (b[j] # 0X) & (i < LEN(a) - 1) DO a[i] := b[j]; INC(i); INC(j) END;
  a[i] := 0X
END Strings;

(* config.gitGraph.name, or NIL *)
PROCEDURE FindConf(name: ARRAY OF CHAR): Y.Pair;
  VAR key: ARRAY 64 OF CHAR;
BEGIN
  key := "config.gitGraph."; Strings(key, name);
  RETURN Y.Find(d.g.config, key)
END FindConf;

(* config.gitGraph.name, a number at least least, or default *)
PROCEDURE Num(name: ARRAY OF CHAR; default, least: LONGREAL): LONGREAL;
  VAR q: Y.Pair; x: LONGREAL; i: LONGINT;
BEGIN
  q := FindConf(name);
  IF q = NIL THEN RETURN default END;
  i := 0;
  WHILE L.IsBlank(q.value[i]) DO INC(i) END;
  IF (q.value[i] = 0X) OR ~X.JsParse(q.value, x) OR (x < least) THEN RETURN default END;
  RETURN x
END Num;

PROCEDURE Bool(name: ARRAY OF CHAR; default: BOOLEAN): BOOLEAN;
  VAR q: Y.Pair;
BEGIN
  q := FindConf(name);
  IF q = NIL THEN RETURN default END;
  IF L.Is(q.value, "true") THEN RETURN TRUE END;
  IF L.Is(q.value, "false") THEN RETURN FALSE END;
  RETURN default
END Bool;

PROCEDURE Configure;
  VAR q: Y.Pair;
BEGIN
  d.titleTopMargin := Num("titleTopMargin", 25, 0);
  d.diagramPadding := Num("diagramPadding", 8, -1.0D300);
  d.showCommitLabel := Bool("showCommitLabel", TRUE);
  d.showBranches := Bool("showBranches", TRUE);
  d.rotateCommitLabel := Bool("rotateCommitLabel", TRUE);
  d.parallelCommits := Bool("parallelCommits", FALSE);
  q := FindConf("mainBranchName");
  IF (q # NIL) & (q.value[0] # 0X) THEN d.mainBranchName := q.value
  ELSE d.mainBranchName := L.New("main")
  END;
  NewBranch(d.mainBranchName, Num("mainBranchOrder", 0, -1.0D300));
  d.cur := d.branches
END Configure;

(* The branches sorted, stably, by order, and the commits by seq *)
PROCEDURE Sort;
  VAR b, t: Branch; c: Commit; i, j: LONGINT;
BEGIN
  NEW(d.sorted, d.nBranches); b := d.branches; i := 0;
  WHILE b # NIL DO
    j := i;
    WHILE (j > 0) & (d.sorted[j - 1].order > b.order) DO d.sorted[j] := d.sorted[j - 1]; DEC(j) END;
    d.sorted[j] := b; INC(i); b := b.next
  END;
  FOR i := 0 TO d.nBranches - 1 DO t := d.sorted[i]; t.index := SHORT(i) END;
  NEW(d.bySeq, d.nCommits + 1); c := d.commits; i := 0;
  WHILE c # NIL DO
    j := i;
    WHILE (j > 0) & (d.bySeq[j - 1].seq > c.seq) DO d.bySeq[j] := d.bySeq[j - 1]; DEC(j) END;
    d.bySeq[j] := c; INC(i); c := c.next
  END
END Sort;

(* Whether the scanner's text, after front matter and comments, starts
   with "gitGraph" *)
PROCEDURE IsGit*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("gitGraph");
  s.pos := save;
  RETURN r
END IsGit;

(* Reads the git graph in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Git, d.g); sc := s;
  d.dir := LR; d.commits := NIL; d.nCommits := 0; d.branches := NIL; d.nBranches := 0;
  d.lastCommit := NIL; d.lastBranch := NIL; d.head := NIL; d.seq := 0;
  Configure;
  IF ~Keyword("gitGraph") & ~sc.LookingAt("gitGraph:") THEN sc.Error("expected gitGraph") END;
  INC(sc.pos, 8); Hidden;
  IF sc.Ch() = ":" THEN INC(sc.pos)
  ELSIF Keyword("LR") OR Keyword("TB") OR Keyword("BT") THEN
    IF sc.LookingAt("TB") THEN d.dir := TB ELSIF sc.LookingAt("BT") THEN d.dir := BT END;
    INC(sc.pos, 2); Hidden;
    IF sc.Ch() # ":" THEN sc.Error("expected : after the direction") END;
    INC(sc.pos)
  END;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  Sort
END Read;

BEGIN
  NEW(buf, 256)
END PmGit.
