MODULE PmC4;
(* PmC4: Mermaid's C4 diagrams (C4Context, C4Container, C4Component,
   C4Dynamic and C4Deployment): their people, systems, containers,
   components, boundaries, deployment nodes and relationships, read as
   Mermaid 12.3.0 reads them.

   The reader follows diagrams/c4/parser/c4Diagram.jison and c4Db.ts.
   The text is first cleaned as Mermaid cleans it: line ends made LF,
   the directives taken out, then each comment on a line of its own,
   with the blank lines before it; blanks at the start are dropped, and
   a line end is added. Positions in the cleaned text are mapped back
   to the input's for messages.

   The lexer is Mermaid's: the first rule that matches, not the
   longest. Between statements:

   - a line with "direction" followed by TB, BT, RL or LR in it, from
     where the lexer is, is a direction, which Mermaid's grammar takes
     only alone, so it is always an error;
   - "title" and one blank, then the rest up to "#", ";" or the line's
     end; "accDescription" likewise; "accTitle:" (a title too) and
     "accDescr:" to the line's end; "accDescr { ... }";
   - "%%" to the line's end, with the line ends after it, is skipped:
     a comment after a statement joins the next line to it;
   - blanks with a line end in them are a line end; other blanks are
     skipped;
   - a diagram's or an element's keyword is a whole word; "{" and "}".

   An element's keyword is followed at once by "(" and its arguments,
   as Mermaid's lexer reads them: "," between them, an empty one
   ("" or ",,"), a string in quotation marks, "$key=\"value\"" and
   otherwise all up to the next comma, ")" and line ends included, so
   that an unquoted last argument takes the rest of the text with it,
   as in Mermaid. Each argument is trimmed.

   The grammar is the diagram's keyword, a line end and at least one
   statement; a title or an accessibility statement may be followed by
   an element without a line end. A boundary or a deployment node is
   its keyword and arguments, "{" (on that line or the next) and the
   statements inside it, the first an element, and "}".

   The database is c4Db.ts's: an element, boundary or relationship
   defined again is changed in place; the arguments are put in their
   places by position, and "$key" puts its value under key instead.
   The label, descr, techn and type are texts; a value set by
   UpdateElementStyle in one of those is kept as it is ("raw"), and
   Mermaid draws nothing for it. A relationship without its from, to
   or label is left out, as Mermaid leaves it out, with a warning.
   pomermaid stops where Mermaid would go wrong: "$key" in an alias,
   a label, from or to (decision 58), and a boundary called "global"
   or "" (Mermaid recurses until its stack is exhausted). "$alias",
   "$parentBoundary", "$typeC4Shape", "$from", "$to" and "$wrap" are
   warned of and ignored. *)

IMPORT PmIO, L := PmLex, F := PmFlow;

CONST
  (* tokens *)
  tEOF = 0; tNewline = 1; tTitle = 2; tAccDescription = 3; tAccTitle = 4; tAccDescr = 5;
  tDirection = 6; tDiagram = 7; tElement = 8; tLBrace = 9; tRBrace = 10; tError = 11;

  (* what an element's keyword does *)
  cSystem = 1;      (* addPersonOrSystem *)
  cContainer = 2;   (* addContainer and addComponent *)
  cBoundary = 3;    (* addPersonOrSystemBoundary *)
  cContBoundary = 4;
  cNode = 5;
  cRel = 6;
  cRelIndex = 7;
  cUpdateEl = 8;
  cUpdateRel = 9;
  cUpdateLayout = 10;

  MaxArgs = 16;
  MaxKw = 56;
  MaxInRow = 1000000;

  LF = 0AX; CR = 0DX; TAB = 09X;

TYPE
  Str = L.Str;

  (* A value set on an element, a boundary or a relationship *)
  Attr* = POINTER TO AttrDesc;
  AttrDesc* = RECORD
    key-, value-: Str;
    raw-: BOOLEAN;      (* a text's value set by UpdateElementStyle: not drawn *)
    next-: Attr
  END;

  (* A person, system, container or component *)
  Shape* = POINTER TO ShapeDesc;
  ShapeDesc* = RECORD
    alias-, type-, parent-: Str;  (* type: Mermaid's typeC4Shape, as "external_system_db" *)
    attrs-: Attr;
    index-: LONGINT;
    next-: Shape;
    pos-: LONGINT                 (* where it was first defined, in the input *)
  END;

  (* A boundary or a deployment node; the first is "global" *)
  Boundary* = POINTER TO BoundaryDesc;
  BoundaryDesc* = RECORD
    alias-, parent-: Str;
    attrs-: Attr;
    index-: LONGINT;
    next-: Boundary;
    pos-: LONGINT
  END;

  Rel* = POINTER TO RelDesc;
  RelDesc* = RECORD
    kind-: Str;          (* "rel", "birel", "rel_b", "rel_u" and the like *)
    kindSet-: BOOLEAN;   (* "$type" has replaced the kind: neither birel nor rel_b *)
    from-, to-: Str;
    attrs-: Attr;
    index-: LONGINT;
    next-: Rel;
    pos-: LONGINT
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;                  (* the configuration *)
    c4Type-: Str;                 (* "C4Context" and the like *)
    title-, accDescr-: Str;       (* or NIL *)
    shapes-: Shape;
    boundaries-: Boundary;
    rels-: Rel;
    nShapes-, nBoundaries-, nRels-: LONGINT;
    shapeInRow-, boundaryInRow-: LONGINT;
    lastShape: Shape; lastBoundary: Boundary; lastRel: Rel
  END;

  Token = RECORD
    kind: INTEGER;
    start, end: LONGINT;  (* in the cleaned text *)
    a0, a1: LONGINT;      (* a title's text *)
    kw: INTEGER           (* an element's or a diagram's keyword *)
  END;

  Arg = RECORD
    kv: BOOLEAN;
    key, value: Str;
    pos: LONGINT          (* in the cleaned text *)
  END;

  Ints = POINTER TO ARRAY OF LONGINT;

  KwName = ARRAY 24 OF CHAR;

  (* The boundaries being read, innermost first *)
  Open = POINTER TO OpenDesc;
  OpenDesc = RECORD alias: Str; next: Open END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;
  ct: Str;              (* the cleaned text *)
  cm: Ints;             (* its positions in the input *)
  cn: LONGINT;          (* its length *)
  args: ARRAY MaxArgs OF Arg;
  nArgs: LONGINT;
  open: Open;           (* the current boundary is open.alias *)
  kwName, kwType: ARRAY MaxKw OF KwName;
  kwClass: ARRAY MaxKw OF INTEGER;
  nKw: INTEGER;
  diagramNames: ARRAY 5 OF KwName;
  empty: Str;

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

PROCEDURE PutS(VAR n: LONGINT; s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(n, s[i]); INC(i) END
END PutS;

(* The cleaned text from start to end *)
PROCEDURE PutText(VAR n: LONGINT; start, end: LONGINT);
BEGIN
  WHILE start < end DO Put(n, ct[start]); INC(start) END
END PutText;

PROCEDURE PutInt(VAR n: LONGINT; k: LONGINT);
  VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  IF k < 0 THEN Put(n, "-"); k := -k END;
  i := 0; REPEAT dg[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
  WHILE i > 0 DO DEC(i); Put(n, dg[i]) END
END PutInt;

(* Stops with buf's n characters, at p in the cleaned text *)
PROCEDURE Fail(p, n: LONGINT);
BEGIN
  buf[n] := 0X; sc.ErrorAt(cm[p], buf^)
END Fail;

PROCEDURE Error(p: LONGINT; msg: ARRAY OF CHAR);
BEGIN
  sc.ErrorAt(cm[p], msg)
END Error;

(* Warns, at p in the cleaned text, buf's n characters *)
PROCEDURE Warn(p, n: LONGINT);
  VAR line, col, m: LONGINT; s: Str;
BEGIN
  buf[n] := 0X; s := L.Sub(buf^, 0, n);
  sc.Where(cm[p], line, col);
  m := 0; PutS(m, sc.name); Put(m, ":"); PutInt(m, line); Put(m, ":"); PutInt(m, col);
  PutS(m, ": "); PutS(m, s^); buf[m] := 0X;
  PmIO.Warn(buf^)
END Warn;

(* The cleaned text *)

PROCEDURE Ch(p: LONGINT): CHAR;
BEGIN
  IF p < cn THEN RETURN ct[p] ELSE RETURN 0X END
END Ch;

(* JavaScript's \s, as far as ASCII goes *)
PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = TAB) OR (ch = LF) OR (ch = CR) OR (ch = 0BX) OR (ch = 0CX)
END IsSpace;

(* JavaScript's \w *)
PROCEDURE IsWord(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "a") & (ch <= "z") OR (ch >= "A") & (ch <= "Z") OR (ch >= "0") & (ch <= "9")
    OR (ch = "_")
END IsWord;

(* Whether the cleaned text at p is w *)
PROCEDURE At(p: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF Ch(p + i) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END At;

(* The cleaned text from a to b, trimmed *)
PROCEDURE Trimmed(a, b: LONGINT): Str;
BEGIN
  WHILE (a < b) & IsSpace(ct[a]) DO INC(a) END;
  WHILE (b > a) & IsSpace(ct[b - 1]) DO DEC(b) END;
  RETURN L.Sub(ct^, a, b - a)
END Trimmed;

(* Cleans the input from sc.pos into ct and cm, as Mermaid cleans it *)
PROCEDURE Clean;
  VAR t1: Str; m1: Ints; n1, p, e, q, r: LONGINT; save: LONGINT; ch: CHAR;
BEGIN
  NEW(t1, sc.len - sc.pos + 2); NEW(m1, sc.len - sc.pos + 2);
  (* line ends and directives *)
  p := sc.pos; n1 := 0;
  WHILE p < sc.len DO
    ch := sc.t[p];
    IF ch = CR THEN
      t1[n1] := LF; m1[n1] := p; INC(n1);
      IF (p + 1 < sc.len) & (sc.t[p + 1] = LF) THEN INC(p, 2) ELSE INC(p) END
    ELSIF (ch = "%") & (p + 2 < sc.len) & (sc.t[p + 1] = "%") & (sc.t[p + 2] = "{") THEN
      save := sc.pos; sc.pos := p; e := sc.DirectiveEnd(); sc.pos := save;
      IF e >= 0 THEN p := e ELSE t1[n1] := ch; m1[n1] := p; INC(n1); INC(p) END
    ELSE t1[n1] := ch; m1[n1] := p; INC(n1); INC(p)
    END
  END;
  (* comments on lines of their own, with the blank lines before them *)
  NEW(ct, n1 + 2); NEW(cm, n1 + 2);
  p := 0; cn := 0;
  WHILE p < n1 DO
    (* p is at a line's start *)
    r := p; WHILE (r < n1) & IsSpace(t1[r]) DO INC(r) END;
    IF (r + 2 < n1) & (t1[r] = "%") & (t1[r + 1] = "%") & (t1[r + 2] # "{") & (t1[r + 2] # LF) THEN
      q := r + 2; WHILE (q < n1) & (t1[q] # LF) DO INC(q) END;
      IF q < n1 THEN INC(q) END;
      p := q
    ELSE
      REPEAT ct[cn] := t1[p]; cm[cn] := m1[p]; INC(cn); INC(p) UNTIL (p >= n1) OR (t1[p - 1] = LF)
    END
  END;
  (* blanks at the start *)
  p := 0; WHILE (p < cn) & IsSpace(ct[p]) DO INC(p) END;
  IF p > 0 THEN
    FOR q := p TO cn - 1 DO ct[q - p] := ct[q]; cm[q - p] := cm[q] END;
    DEC(cn, p)
  END;
  ct[cn] := LF; cm[cn] := sc.len; INC(cn);
  ct[cn] := 0X; cm[cn] := sc.len
END Clean;

(* The lexer *)

(* The keyword that is the word from p to e, or -1 *)
PROCEDURE Keyword(p, e: LONGINT): INTEGER;
  VAR k, i: INTEGER; ok: BOOLEAN;
BEGIN
  FOR k := 0 TO nKw - 1 DO
    i := 0; ok := TRUE;
    WHILE ok & (kwName[k][i] # 0X) DO
      IF (p + i >= e) OR (ct[p + i] # kwName[k][i]) THEN ok := FALSE END;
      INC(i)
    END;
    IF ok & (p + i = e) THEN RETURN k END
  END;
  RETURN -1
END Keyword;

PROCEDURE DiagramKeyword(p, e: LONGINT): INTEGER;
  VAR k, i: INTEGER; ok: BOOLEAN;
BEGIN
  FOR k := 0 TO 4 DO
    i := 0; ok := TRUE;
    WHILE ok & (diagramNames[k][i] # 0X) DO
      IF (p + i >= e) OR (ct[p + i] # diagramNames[k][i]) THEN ok := FALSE END;
      INC(i)
    END;
    IF ok & (p + i = e) THEN RETURN k END
  END;
  RETURN -1
END DiagramKeyword;

(* Whether the line from p has "direction", blanks and TB, BT, RL or LR
   in it, the end of the line in e *)
PROCEDURE Direction(p: LONGINT; VAR e: LONGINT): BOOLEAN;
  VAR q, r: LONGINT; found: BOOLEAN;
BEGIN
  q := p; found := FALSE;
  WHILE (q < cn) & (ct[q] # LF) DO
    IF At(q, "direction") & IsSpace(Ch(q + 9)) THEN
      r := q + 9; WHILE IsSpace(Ch(r)) DO INC(r) END;
      IF At(r, "TB") OR At(r, "BT") OR At(r, "RL") OR At(r, "LR") THEN
        found := TRUE; e := r + 2
      END
    END;
    INC(q)
  END;
  IF found THEN WHILE (e < cn) & (ct[e] # LF) DO INC(e) END END;
  RETURN found
END Direction;

(* The token at p, in Mermaid's INITIAL state *)
PROCEDURE Lex(p: LONGINT; VAR t: Token);
  VAR e, q: LONGINT;
BEGIN
  LOOP
    t.start := p; t.kw := -1;
    IF p >= cn THEN t.kind := tEOF; t.end := p; RETURN END;
    IF Direction(p, e) THEN t.kind := tDirection; t.end := e; RETURN END;
    IF At(p, "title") & IsSpace(Ch(p + 5)) & (Ch(p + 6) # "#") & (Ch(p + 6) # LF) & (Ch(p + 6) # ";")
      & (p + 6 < cn) THEN
      e := p + 6; WHILE (e < cn) & (ct[e] # "#") & (ct[e] # LF) & (ct[e] # ";") DO INC(e) END;
      t.kind := tTitle; t.a0 := p + 6; t.a1 := e; t.end := e; RETURN
    END;
    IF At(p, "accDescription") & IsSpace(Ch(p + 14)) & (Ch(p + 15) # "#") & (Ch(p + 15) # LF)
      & (Ch(p + 15) # ";") & (p + 15 < cn) THEN
      e := p + 15; WHILE (e < cn) & (ct[e] # "#") & (ct[e] # LF) & (ct[e] # ";") DO INC(e) END;
      t.kind := tAccDescription; t.a0 := p + 15; t.a1 := e; t.end := e; RETURN
    END;
    IF At(p, "accTitle") THEN
      e := p + 8; WHILE IsSpace(Ch(e)) DO INC(e) END;
      IF Ch(e) = ":" THEN
        INC(e); WHILE IsSpace(Ch(e)) DO INC(e) END;
        t.a0 := e; WHILE (e < cn) & (ct[e] # LF) DO INC(e) END;
        t.kind := tAccTitle; t.a1 := e; t.end := e; RETURN
      END
    END;
    IF At(p, "accDescr") THEN
      e := p + 8; WHILE IsSpace(Ch(e)) DO INC(e) END;
      IF Ch(e) = ":" THEN
        INC(e); WHILE IsSpace(Ch(e)) DO INC(e) END;
        t.a0 := e; WHILE (e < cn) & (ct[e] # LF) DO INC(e) END;
        t.kind := tAccDescr; t.a1 := e; t.end := e; RETURN
      ELSIF Ch(e) = "{" THEN
        INC(e); WHILE IsSpace(Ch(e)) DO INC(e) END;
        IF Ch(e) = "}" THEN p := e + 1 (* no value: no token *)
        ELSE
          t.a0 := e; WHILE (e < cn) & (ct[e] # "}") DO INC(e) END;
          t.kind := tAccDescr; t.a1 := e;
          IF e < cn THEN INC(e) END;
          t.end := e; RETURN
        END
      END
    END;
    IF p = t.start THEN
      IF At(p, "%%") THEN
        e := p; WHILE (e < cn) & (ct[e] # LF) DO INC(e) END;
        WHILE Ch(e) = LF DO INC(e) END;
        p := e
      ELSIF IsSpace(ct[p]) THEN
        e := p; q := -1;
        WHILE IsSpace(Ch(e)) DO IF ct[e] = LF THEN q := e + 1 END; INC(e) END;
        IF q >= 0 THEN t.kind := tNewline; t.end := q; RETURN END;
        p := e
      ELSIF IsWord(ct[p]) THEN
        e := p; WHILE IsWord(Ch(e)) DO INC(e) END;
        t.end := e;
        t.kw := DiagramKeyword(p, e);
        IF t.kw >= 0 THEN t.kind := tDiagram; RETURN END;
        t.kw := Keyword(p, e);
        IF t.kw >= 0 THEN t.kind := tElement ELSE t.kind := tError END;
        RETURN
      ELSIF ct[p] = "{" THEN t.kind := tLBrace; t.end := p + 1; RETURN
      ELSIF ct[p] = "}" THEN t.kind := tRBrace; t.end := p + 1; RETURN
      ELSE
        t.kind := tError; e := p + 1;
        WHILE (e < cn) & (ORD(ct[e]) >= 80H) & (ORD(ct[e]) < 0C0H) DO INC(e) END;
        t.end := e; RETURN
      END
    END
  END
END Lex;

(* Stops: what was expected, not t *)
PROCEDURE Unexpected(VAR t: Token; what: ARRAY OF CHAR);
  VAR n, e: LONGINT;
BEGIN
  n := 0; PutS(n, "expected "); PutS(n, what);
  CASE t.kind OF
    tEOF: PutS(n, ", not the end")
  | tNewline: PutS(n, ", not the end of the line")
  ELSE
    e := t.end; WHILE (e > t.start) & IsSpace(ct[e - 1]) DO DEC(e) END;
    PutS(n, ", not '");
    IF e - t.start > 40 THEN PutText(n, t.start, t.start + 40); PutS(n, "...")
    ELSE PutText(n, t.start, e)
    END;
    Put(n, "'");
    IF t.kind = tDirection THEN
      PutS(n, ": Mermaid reads a line with 'direction' and TB, BT, RL or LR in it as a direction, which its C4 diagrams do not take")
    END
  END;
  Fail(t.start, n)
END Unexpected;

(* The arguments *)

(* How many arguments are kept *)
PROCEDURE Have(): LONGINT;
BEGIN
  IF nArgs < MaxArgs THEN RETURN nArgs ELSE RETURN MaxArgs END
END Have;

PROCEDURE AddArg(kv: BOOLEAN; key, value: Str; pos: LONGINT);
BEGIN
  IF nArgs < MaxArgs THEN
    args[nArgs].kv := kv; args[nArgs].key := key; args[nArgs].value := value;
    args[nArgs].pos := pos
  END;
  INC(nArgs)
END AddArg;

(* Reads an element's arguments, from p, after its keyword, in t *)
PROCEDURE Arguments(VAR p: LONGINT; VAR t: Token);
  VAR q, r, s, e, n: LONGINT; key: Str;
BEGIN
  nArgs := 0;
  IF p >= cn THEN Unexpected(t, "'(' after it") END;
  IF ct[p] = "(" THEN
    r := p + 1; WHILE Ch(r) = " " DO INC(r) END;
    IF Ch(r) = "," THEN AddArg(FALSE, NIL, empty, p); p := r + 1 ELSE INC(p) END
  ELSIF ct[p] = ")" THEN
    Error(p, "expected '(' and the arguments, not ')'")
  ELSE
    n := 0; PutS(n, "expected '(' right after '"); PutText(n, t.start, t.end); PutS(n, "', not '");
    IF IsSpace(ct[p]) THEN PutS(n, "a blank") ELSE Put(n, ct[p]) END;
    Put(n, "'"); Fail(p, n)
  END;
  q := p;
  LOOP
    IF q >= cn THEN EXIT END;
    IF ct[q] = ")" THEN
      IF nArgs = 0 THEN Error(q, "expected an argument, not ')'") END;
      INC(q); EXIT
    ELSIF At(q, ",,") THEN AddArg(FALSE, NIL, empty, q); INC(q, 2)
    ELSIF ct[q] = "," THEN INC(q)
    ELSE
      r := q; WHILE Ch(r) = " " DO INC(r) END;
      IF (Ch(r) = '"') & (Ch(r + 1) = '"') THEN AddArg(FALSE, NIL, empty, r); q := r + 2
      ELSIF Ch(r) = '"' THEN
        s := r + 1; e := s; WHILE (e < cn) & (ct[e] # '"') DO INC(e) END;
        IF e < cn THEN AddArg(FALSE, NIL, Trimmed(s, e), r); q := e + 1
        ELSE
          IF e > s THEN AddArg(FALSE, NIL, Trimmed(s, e), r) END;
          AddArg(FALSE, NIL, empty, e); q := cn; EXIT
        END
      ELSIF Ch(r) = "$" THEN
        s := r + 1; e := s; WHILE (e < cn) & (ct[e] # "=") DO INC(e) END;
        key := Trimmed(s, e);
        IF e >= cn THEN Error(r, "expected '=' and a value in quotation marks after '$' and a key, not the end") END;
        q := e + 1; WHILE Ch(q) = " " DO INC(q) END;
        IF Ch(q) # '"' THEN Error(e, "expected a value in quotation marks after '='") END;
        s := q + 1; e := s; WHILE (e < cn) & (ct[e] # '"') DO INC(e) END;
        IF e = s THEN Error(q, "expected a value, not an empty string: Mermaid takes none") END;
        AddArg(TRUE, key, Trimmed(s, e), r);
        IF e < cn THEN q := e + 1 ELSE q := cn; EXIT END
      ELSE
        e := q; WHILE (e < cn) & (ct[e] # ",") DO INC(e) END;
        AddArg(FALSE, NIL, Trimmed(q, e), q); q := e
      END
    END
  END;
  IF nArgs = 0 THEN Error(q, "expected an argument") END;
  p := q
END Arguments;

(* The attribute bag *)

(* The value named key in a, or NIL *)
PROCEDURE Find*(a: Attr; key: ARRAY OF CHAR): Attr;
BEGIN
  WHILE (a # NIL) & ~L.Is(a.key, key) DO a := a.next END;
  RETURN a
END Find;

(* The text named key in a: NIL if there is none, or it is raw *)
PROCEDURE Text*(a: Attr; key: ARRAY OF CHAR): Str;
BEGIN
  a := Find(a, key);
  IF (a = NIL) OR a.raw THEN RETURN NIL END;
  RETURN a.value
END Text;

(* The value named key in a, raw or not, or NIL *)
PROCEDURE Value*(a: Attr; key: ARRAY OF CHAR): Str;
BEGIN
  a := Find(a, key);
  IF a = NIL THEN RETURN NIL END;
  RETURN a.value
END Value;

PROCEDURE SetS(VAR list: Attr; key: Str; value: Str; raw: BOOLEAN);
  VAR a, last: Attr;
BEGIN
  a := list; last := NIL;
  WHILE (a # NIL) & ~L.Equal(a.key, key) DO last := a; a := a.next END;
  IF a = NIL THEN
    NEW(a); a.key := key; a.next := NIL;
    IF last = NIL THEN list := a ELSE last.next := a END
  END;
  a.value := value; a.raw := raw
END SetS;

PROCEDURE Set(VAR list: Attr; key: ARRAY OF CHAR; value: Str);
BEGIN
  SetS(list, L.New(key), value, FALSE)
END Set;

PROCEDURE IsTextKey(key: Str): BOOLEAN;
BEGIN
  RETURN L.Is(key, "label") OR L.Is(key, "descr") OR L.Is(key, "techn") OR L.Is(key, "type")
END IsTextKey;

(* Whether "$key" in argument k is one pomermaid ignores, with a warning *)
PROCEDURE Ignored(k: LONGINT): BOOLEAN;
  VAR key: Str; n: LONGINT;
BEGIN
  key := args[k].key;
  IF L.Is(key, "alias") OR L.Is(key, "parentBoundary") OR L.Is(key, "typeC4Shape")
    OR L.Is(key, "from") OR L.Is(key, "to") OR L.Is(key, "wrap") THEN
    n := 0; PutS(n, "'$"); PutS(n, key^);
    PutS(n, "' would change how Mermaid's database holds the diagram; pomermaid ignores it");
    Warn(args[k].pos, n);
    RETURN TRUE
  END;
  RETURN FALSE
END Ignored;

(* Argument k, "$key", into the list *)
PROCEDURE SetKv(VAR list: Attr; k: LONGINT; raw: BOOLEAN);
BEGIN
  IF ~Ignored(k) THEN SetS(list, args[k].key, args[k].value, raw & IsTextKey(args[k].key)) END
END SetKv;

(* Argument k, a text named field: if there is none, an empty text
   unless the list has one *)
PROCEDURE TextArg(VAR list: Attr; field: ARRAY OF CHAR; k: LONGINT);
BEGIN
  IF k >= Have() THEN
    IF Find(list, field) = NIL THEN Set(list, field, empty) END
  ELSIF args[k].kv THEN SetKv(list, k, FALSE)
  ELSE Set(list, field, args[k].value)
  END
END TextArg;

(* Argument k, a value named field, if there is one *)
PROCEDURE ValueArg(VAR list: Attr; field: ARRAY OF CHAR; k: LONGINT);
BEGIN
  IF k < Have() THEN
    IF args[k].kv THEN SetKv(list, k, FALSE) ELSE Set(list, field, args[k].value) END
  END
END ValueArg;

(* Argument k, set by UpdateElementStyle or UpdateRelStyle *)
PROCEDURE RawArg(VAR list: Attr; field: ARRAY OF CHAR; k: LONGINT);
  VAR key: Str;
BEGIN
  IF k < Have() THEN
    IF args[k].kv THEN SetKv(list, k, TRUE)
    ELSE key := L.New(field); SetS(list, key, args[k].value, IsTextKey(key))
    END
  END
END RawArg;

(* Argument k, a string: an alias, a label, from or to (decision 58);
   NIL if there is none *)
PROCEDURE Plain(k: LONGINT; what: ARRAY OF CHAR): Str;
  VAR n: LONGINT;
BEGIN
  IF k >= Have() THEN RETURN NIL END;
  IF args[k].kv THEN
    n := 0; PutS(n, "expected "); PutS(n, what); PutS(n, ", not '$"); PutS(n, args[k].key^);
    PutS(n, "': Mermaid cannot use a named value there");
    Fail(args[k].pos, n)
  END;
  RETURN args[k].value
END Plain;

(* The database *)

PROCEDURE FindShape*(dg: Diagram; alias: Str): Shape;
  VAR s: Shape;
BEGIN
  s := dg.shapes;
  WHILE (s # NIL) & ~L.Equal(s.alias, alias) DO s := s.next END;
  RETURN s
END FindShape;

PROCEDURE FindBoundary*(dg: Diagram; alias: Str): Boundary;
  VAR b: Boundary;
BEGIN
  b := dg.boundaries;
  WHILE (b # NIL) & ~L.Equal(b.alias, alias) DO b := b.next END;
  RETURN b
END FindBoundary;

PROCEDURE FindRel(from, to: Str): Rel;
  VAR r: Rel;
BEGIN
  r := d.rels;
  WHILE (r # NIL) & ~(L.Equal(r.from, from) & L.Equal(r.to, to)) DO r := r.next END;
  RETURN r
END FindRel;

PROCEDURE NewBoundary(alias: Str; pos: LONGINT): Boundary;
  VAR b: Boundary;
BEGIN
  NEW(b); b.alias := alias; b.parent := empty; b.attrs := NIL; b.next := NIL;
  b.index := d.nBoundaries; INC(d.nBoundaries); b.pos := pos;
  IF d.lastBoundary = NIL THEN d.boundaries := b ELSE d.lastBoundary.next := b END;
  d.lastBoundary := b;
  RETURN b
END NewBoundary;

(* A person, system, container or component, kw's *)
PROCEDURE AddShape(kw: INTEGER; pos: LONGINT);
  VAR alias, label: Str; s: Shape; k: LONGINT;
BEGIN
  alias := Plain(0, "an alias"); label := Plain(1, "a label");
  s := FindShape(d, alias);
  IF s = NIL THEN
    NEW(s); s.alias := alias; s.attrs := NIL; s.next := NIL; s.pos := cm[pos];
    s.index := d.nShapes; INC(d.nShapes);
    IF d.lastShape = NIL THEN d.shapes := s ELSE d.lastShape.next := s END;
    d.lastShape := s
  END;
  IF label = NIL THEN label := empty END;
  Set(s.attrs, "label", label);
  k := 2;
  IF kwClass[kw] = cContainer THEN TextArg(s.attrs, "techn", k); INC(k) END;
  TextArg(s.attrs, "descr", k);
  ValueArg(s.attrs, "sprite", k + 1); ValueArg(s.attrs, "tags", k + 2); ValueArg(s.attrs, "link", k + 3);
  s.type := L.New(kwType[kw]); s.parent := open.alias
END AddShape;

(* Inserts s as argument k, as JavaScript's splice *)
PROCEDURE Splice(k: LONGINT; s: Str; pos: LONGINT);
  VAR i: LONGINT;
BEGIN
  IF k > nArgs THEN k := nArgs END;
  IF nArgs < MaxArgs THEN INC(nArgs) END;
  FOR i := nArgs - 1 TO k + 1 BY -1 DO args[i] := args[i - 1] END;
  IF k < MaxArgs THEN args[k].kv := FALSE; args[k].key := NIL; args[k].value := s; args[k].pos := pos END
END Splice;

(* A boundary or a deployment node, kw's; it is made the current one *)
PROCEDURE AddBoundary(kw: INTEGER; pos: LONGINT);
  VAR alias, label, par: Str; b, pb: Boundary; o: Open; c: INTEGER; k: LONGINT;
BEGIN
  c := kwClass[kw];
  IF (c # cNode) & (kwType[kw] # "") THEN Splice(2, L.New(kwType[kw]), pos) END;
  alias := Plain(0, "an alias"); label := Plain(1, "a label");
  IF L.Is(alias, "global") OR L.Is(alias, "") THEN
    Error(args[0].pos, "a boundary cannot be called 'global' or '': Mermaid would draw it inside itself")
  END;
  (* a boundary made inside itself: Mermaid would recurse until its
     stack ran out *)
  par := open.alias; k := 0;
  WHILE (par # NIL) & (k <= d.nBoundaries) & ~L.Equal(par, alias) DO
    pb := FindBoundary(d, par);
    IF pb = NIL THEN par := NIL ELSE par := pb.parent END;
    INC(k)
  END;
  IF (par # NIL) & L.Equal(par, alias) THEN
    Error(args[0].pos, "a boundary cannot be inside itself: Mermaid would draw it inside itself")
  END;
  b := FindBoundary(d, alias);
  IF b = NIL THEN b := NewBoundary(alias, cm[pos]) END;
  IF label = NIL THEN label := empty END;
  Set(b.attrs, "label", label);
  IF 2 >= Have() THEN
    IF c = cNode THEN Set(b.attrs, "type", L.New("node"))
    ELSIF c = cContBoundary THEN Set(b.attrs, "type", L.New("container"))
    ELSE Set(b.attrs, "type", L.New("system"))
    END
  ELSIF args[2].kv THEN SetKv(b.attrs, 2, FALSE)
  ELSE Set(b.attrs, "type", args[2].value)
  END;
  IF c = cNode THEN
    TextArg(b.attrs, "descr", 3);
    ValueArg(b.attrs, "tags", 5); ValueArg(b.attrs, "link", 6);
    Set(b.attrs, "nodeType", L.New(kwType[kw]))
  ELSE
    ValueArg(b.attrs, "tags", 3); ValueArg(b.attrs, "link", 4)
  END;
  b.parent := open.alias;
  NEW(o); o.alias := alias; o.next := open; open := o
END AddBoundary;

(* A relationship, kw's *)
PROCEDURE AddRel(kw: INTEGER; pos: LONGINT);
  VAR from, to, label: Str; r: Rel; i, n: LONGINT;
BEGIN
  IF kwClass[kw] = cRelIndex THEN
    FOR i := 1 TO Have() - 1 DO args[i - 1] := args[i] END;
    DEC(nArgs)
  END;
  from := Plain(0, "the alias it is from"); to := Plain(1, "the alias it is to");
  label := Plain(2, "a label");
  IF label = NIL THEN
    n := 0; PutS(n, "a relationship needs from, to and a label; Mermaid leaves this one out, and so does pomermaid");
    Warn(pos, n)
  ELSE
    r := FindRel(from, to);
    IF r = NIL THEN
      NEW(r); r.from := from; r.to := to; r.attrs := NIL; r.next := NIL; r.pos := cm[pos];
      r.index := d.nRels; INC(d.nRels);
      IF d.lastRel = NIL THEN d.rels := r ELSE d.lastRel.next := r END;
      d.lastRel := r
    END;
    r.kind := L.New(kwType[kw]); r.kindSet := FALSE;
    Set(r.attrs, "label", label);
    TextArg(r.attrs, "techn", 3); TextArg(r.attrs, "descr", 4);
    ValueArg(r.attrs, "sprite", 5); ValueArg(r.attrs, "tags", 6); ValueArg(r.attrs, "link", 7);
    IF Find(r.attrs, "type") # NIL THEN r.kindSet := TRUE END
  END
END AddRel;

PROCEDURE UpdateElement;
  VAR s: Shape; b: Boundary; name: Str;
BEGIN
  IF args[0].kv THEN RETURN END;
  name := args[0].value;
  s := FindShape(d, name);
  IF s # NIL THEN
    RawArg(s.attrs, "bgColor", 1); RawArg(s.attrs, "fontColor", 2); RawArg(s.attrs, "borderColor", 3);
    RawArg(s.attrs, "shadowing", 4); RawArg(s.attrs, "shape", 5); RawArg(s.attrs, "sprite", 6);
    RawArg(s.attrs, "techn", 7); RawArg(s.attrs, "legendText", 8); RawArg(s.attrs, "legendSprite", 9)
  ELSE
    b := FindBoundary(d, name);
    IF b # NIL THEN
      RawArg(b.attrs, "bgColor", 1); RawArg(b.attrs, "fontColor", 2); RawArg(b.attrs, "borderColor", 3);
      RawArg(b.attrs, "shadowing", 4); RawArg(b.attrs, "shape", 5); RawArg(b.attrs, "sprite", 6);
      RawArg(b.attrs, "techn", 7); RawArg(b.attrs, "legendText", 8); RawArg(b.attrs, "legendSprite", 9)
    END
  END
END UpdateElement;

PROCEDURE UpdateRel;
  VAR r: Rel;
BEGIN
  IF (nArgs < 2) OR args[0].kv OR args[1].kv THEN RETURN END;
  r := FindRel(args[0].value, args[1].value);
  IF r # NIL THEN
    RawArg(r.attrs, "textColor", 2); RawArg(r.attrs, "lineColor", 3);
    RawArg(r.attrs, "offsetX", 4); RawArg(r.attrs, "offsetY", 5);
    IF Find(r.attrs, "type") # NIL THEN r.kindSet := TRUE END
  END
END UpdateRel;

(* JavaScript's parseInt of s: FALSE for NaN; clamped *)
PROCEDURE ParseInt*(s: Str; VAR v: LONGINT): BOOLEAN;
  VAR i, base, dg: LONGINT; neg, any: BOOLEAN; ch: CHAR;
BEGIN
  v := 0;
  IF s = NIL THEN RETURN FALSE END;
  i := 0; WHILE IsSpace(s[i]) DO INC(i) END;
  neg := FALSE;
  IF (s[i] = "-") OR (s[i] = "+") THEN neg := s[i] = "-"; INC(i) END;
  base := 10;
  IF (s[i] = "0") & ((s[i + 1] = "x") OR (s[i + 1] = "X")) THEN base := 16; INC(i, 2) END;
  any := FALSE;
  LOOP
    ch := s[i];
    IF (ch >= "0") & (ch <= "9") THEN dg := ORD(ch) - ORD("0")
    ELSIF (base = 16) & (ch >= "a") & (ch <= "f") THEN dg := ORD(ch) - ORD("a") + 10
    ELSIF (base = 16) & (ch >= "A") & (ch <= "F") THEN dg := ORD(ch) - ORD("A") + 10
    ELSE EXIT
    END;
    any := TRUE;
    IF v < MaxInRow THEN v := v * base + dg END;
    INC(i)
  END;
  IF v > MaxInRow THEN v := MaxInRow END;
  IF neg THEN v := -v END;
  RETURN any
END ParseInt;

PROCEDURE UpdateLayout;
  VAR v: LONGINT;
BEGIN
  IF (nArgs > 0) & ParseInt(args[0].value, v) & (v >= 1) THEN d.shapeInRow := v END;
  IF (nArgs > 1) & ParseInt(args[1].value, v) & (v >= 1) THEN d.boundaryInRow := v END
END UpdateLayout;

(* The parser *)

PROCEDURE ^Statements(VAR p: LONGINT; inBoundary: BOOLEAN);

(* The element whose keyword is t, its arguments from p *)
PROCEDURE Element(VAR p: LONGINT; VAR t: Token);
  VAR c: INTEGER; u: Token;
BEGIN
  p := t.end;
  Arguments(p, t);
  c := kwClass[t.kw];
  CASE c OF
    cSystem, cContainer: AddShape(t.kw, t.start)
  | cBoundary, cContBoundary, cNode:
      AddBoundary(t.kw, t.start);
      Lex(p, u);
      IF u.kind = tLBrace THEN
        p := u.end; Lex(p, u);
        IF u.kind # tNewline THEN Unexpected(u, "the end of the line after '{'") END;
        p := u.end
      ELSIF u.kind = tNewline THEN
        p := u.end; Lex(p, u);
        IF u.kind # tLBrace THEN Unexpected(u, "'{'") END;
        p := u.end; Lex(p, u);
        IF u.kind = tNewline THEN p := u.end END
      ELSE Unexpected(u, "'{' or the end of the line")
      END;
      Statements(p, TRUE);
      Lex(p, u); p := u.end;  (* "}" *)
      open := open.next
  | cRel, cRelIndex: AddRel(t.kw, t.start)
  | cUpdateEl: UpdateElement
  | cUpdateRel: UpdateRel
  | cUpdateLayout: UpdateLayout
  END
END Element;

(* Reads statements from p to the end, the end of the text or, in a
   boundary, "}", which is not taken *)
PROCEDURE Statements(VAR p: LONGINT; inBoundary: BOOLEAN);
  CONST start = 0; afterOther = 1; afterElement = 2; afterNewline = 3;
  VAR t: Token; state: INTEGER;
BEGIN
  state := start;
  LOOP
    Lex(p, t);
    IF (t.kind = tEOF) & ~inBoundary OR (t.kind = tRBrace) & inBoundary THEN
      IF state = start THEN
        IF inBoundary THEN Unexpected(t, "an element, a relationship or a boundary")
        ELSE Unexpected(t, "an element, a relationship, a boundary or a title")
        END
      END;
      EXIT
    END;
    CASE t.kind OF
      tNewline:
        IF (state = afterOther) OR (state = afterElement) THEN state := afterNewline
        ELSE Unexpected(t, "an element, a relationship, a boundary or a title")
        END;
        p := t.end
    | tTitle, tAccDescription, tAccTitle, tAccDescr:
        IF (state = afterOther) OR (state = afterElement) OR (state = start) & inBoundary THEN
          IF state = afterElement THEN Unexpected(t, "the end of the line")
          ELSE Unexpected(t, "an element, a relationship or a boundary")
          END
        END;
        IF (t.kind = tTitle) OR (t.kind = tAccTitle) THEN d.title := Trimmed(t.a0, t.a1)
        ELSE d.accDescr := Trimmed(t.a0, t.a1)
        END;
        state := afterOther; p := t.end
    | tElement:
        IF state = afterElement THEN Unexpected(t, "the end of the line") END;
        Element(p, t); state := afterElement
    ELSE
      IF state = afterElement THEN Unexpected(t, "the end of the line")
      ELSIF inBoundary THEN Unexpected(t, "an element, a relationship, a boundary or '}'")
      ELSE Unexpected(t, "an element, a relationship, a boundary, a title or the end")
      END
    END
  END
END Statements;

(* Whether the scanner's text, after front matter and comments, starts
   with C4Context, C4Container, C4Component, C4Dynamic or C4Deployment *)
PROCEDURE IsC4*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAtWord("C4Context") OR s.LookingAtWord("C4Container") OR s.LookingAtWord("C4Component")
    OR s.LookingAtWord("C4Dynamic") OR s.LookingAtWord("C4Deployment");
  s.pos := save;
  RETURN r
END IsC4;

(* Reads the C4 diagram in s's text into diagram *)
(* Stops at a relationship from or to what is neither a shape nor a
   boundary, as Mermaid stops when it draws it *)
PROCEDURE Ends;
  VAR r: Rel; n: LONGINT;

  PROCEDURE Known(a: Str): BOOLEAN;
  BEGIN
    RETURN (FindShape(d, a) # NIL) OR (FindBoundary(d, a) # NIL) & ~L.Is(a, "global")
  END Known;

BEGIN
  r := d.rels;
  WHILE r # NIL DO
    IF ~Known(r.from) OR ~Known(r.to) THEN
      n := 0; PutS(n, 'C4 rel "'); PutS(n, r.from^); PutS(n, '" -> "'); PutS(n, r.to^);
      PutS(n, '" references an unknown shape or boundary');
      buf[n] := 0X; sc.ErrorAt(r.pos, buf^)
    END;
    r := r.next
  END
END Ends;

PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR p: LONGINT; t: Token; b: Boundary;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.C4, d.g); sc := s;
  d.title := NIL; d.accDescr := NIL; d.shapes := NIL; d.boundaries := NIL; d.rels := NIL;
  d.nShapes := 0; d.nBoundaries := 0; d.nRels := 0; d.shapeInRow := 4; d.boundaryInRow := 2;
  d.lastShape := NIL; d.lastBoundary := NIL; d.lastRel := NIL;
  Clean;
  b := NewBoundary(L.New("global"), sc.pos);
  Set(b.attrs, "label", L.New("global")); Set(b.attrs, "type", L.New("global"));
  NEW(open); open.alias := b.alias; open.next := NIL;
  p := 0;
  Lex(p, t);
  IF t.kind # tDiagram THEN
    Unexpected(t, "C4Context, C4Container, C4Component, C4Dynamic or C4Deployment")
  END;
  d.c4Type := L.New(diagramNames[t.kw]);
  p := t.end; Lex(p, t);
  IF t.kind # tNewline THEN Unexpected(t, "the end of the line") END;
  p := t.end;
  Statements(p, FALSE);
  Ends;
  ct := NIL; cm := NIL; open := NIL;
  FOR p := 0 TO MaxArgs - 1 DO args[p].key := NIL; args[p].value := NIL END;
  sc.pos := sc.len
END Read;

PROCEDURE Kw(name: ARRAY OF CHAR; class: INTEGER; type: ARRAY OF CHAR);
BEGIN
  COPY(name, kwName[nKw]); kwClass[nKw] := class; COPY(type, kwType[nKw]); INC(nKw)
END Kw;

BEGIN
  NEW(buf, 256); empty := L.New("");
  diagramNames[0] := "C4Context"; diagramNames[1] := "C4Container"; diagramNames[2] := "C4Component";
  diagramNames[3] := "C4Dynamic"; diagramNames[4] := "C4Deployment";
  nKw := 0;
  Kw("Person_Ext", cSystem, "external_person"); Kw("Person", cSystem, "person");
  Kw("SystemQueue_Ext", cSystem, "external_system_queue"); Kw("SystemDb_Ext", cSystem, "external_system_db");
  Kw("System_Ext", cSystem, "external_system"); Kw("SystemQueue", cSystem, "system_queue");
  Kw("SystemDb", cSystem, "system_db"); Kw("System", cSystem, "system");
  Kw("Boundary", cBoundary, ""); Kw("Enterprise_Boundary", cBoundary, "ENTERPRISE");
  Kw("System_Boundary", cBoundary, "SYSTEM");
  Kw("ContainerQueue_Ext", cContainer, "external_container_queue");
  Kw("ContainerDb_Ext", cContainer, "external_container_db");
  Kw("Container_Ext", cContainer, "external_container"); Kw("ContainerQueue", cContainer, "container_queue");
  Kw("ContainerDb", cContainer, "container_db"); Kw("Container", cContainer, "container");
  Kw("Container_Boundary", cContBoundary, "CONTAINER");
  Kw("ComponentQueue_Ext", cContainer, "external_component_queue");
  Kw("ComponentDb_Ext", cContainer, "external_component_db");
  Kw("Component_Ext", cContainer, "external_component"); Kw("ComponentQueue", cContainer, "component_queue");
  Kw("ComponentDb", cContainer, "component_db"); Kw("Component", cContainer, "component");
  Kw("Deployment_Node", cNode, "node"); Kw("Node", cNode, "node");
  Kw("Node_L", cNode, "nodeL"); Kw("Node_R", cNode, "nodeR");
  Kw("Rel", cRel, "rel"); Kw("BiRel", cRel, "birel");
  Kw("Rel_Up", cRel, "rel_u"); Kw("Rel_U", cRel, "rel_u");
  Kw("Rel_Down", cRel, "rel_d"); Kw("Rel_D", cRel, "rel_d");
  Kw("Rel_Left", cRel, "rel_l"); Kw("Rel_L", cRel, "rel_l");
  Kw("Rel_Right", cRel, "rel_r"); Kw("Rel_R", cRel, "rel_r");
  Kw("Rel_Back", cRel, "rel_b"); Kw("RelIndex", cRelIndex, "rel");
  Kw("UpdateElementStyle", cUpdateEl, ""); Kw("UpdateRelStyle", cUpdateRel, "");
  Kw("UpdateLayoutConfig", cUpdateLayout, "")
END PmC4.
