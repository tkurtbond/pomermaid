MODULE PmBlock;
(* PmBlock: Mermaid's block diagrams (`block-beta` or `block`), read
   into a tree of blocks, with their shapes, labels, widths in
   columns, classes and styles, and a list of edges.

   The reader follows Mermaid 12.3.0's grammar, packages/mermaid/src/
   diagrams/block/parser/block.jison, its lexer's rules tried in its
   order, the first that matches taken, and what blockDB.ts makes of
   the statements:

   - comments that are a line of their own and directives are removed
     first, as Mermaid removes them; white space, line ends included,
     is skipped between tokens, and so is "" outside a block's label;
     "%%" in a line is part of a block's id;
   - the diagram starts with "block-beta" or "block"; these and
     "block:" are matched as prefixes, as are "space" and "space:N";
   - a block is its id, any bytes but ( [ ) { } - < > : = and white
     space, then, if it has a shape, the shape's opening, a label in
     double quotation marks, not empty, and the shape's closing, with
     nothing between them: ["..."], ("..."), (("...")), >"..."],
     {"..."}, {{"..."}}, (["..."]), [["..."]], [("...")],
     ((("..."))), [/"..."/], [\"..."\], [/"..."\], [\"..."/]; other
     pairs are a plain box. A block arrow is <["..."]>( directions ),
     the directions right, left, x (both), y, up and down, separated by
     commas; one with blanks after it, or before it without a comma,
     is ignored, as Mermaid ignores it;
   - ":N" after a block is its width in columns;
   - a link is "-->", "---", "==>", "-.->" and the like, with x, o or >
     at its end, < at its start; with a label, "-- "label" -->". It
     joins two blocks: "a --> b", the first of which may have a width;
   - "columns N" or "columns auto" sets the columns of the block it is
     in, the last such statement winning; "space" or "space:N" is N
     empty cells;
   - "block:id" and a block, then statements and "end", is a
     composite block, with the block's id, label and width; "block",
     statements and "end", one without an id or a label;
   - "classDef name styles", "class ids name" and "style id styles"
     style blocks, as in a flowchart.

   As blockDB.ts's populateBlockDatabase does, a block whose id was seen
   before is not added again: its shape is changed, unless it has none,
   and its label, unless it is its id. So a block named by class before
   it is defined is never drawn, nor is one with the id "root", the
   diagram's own; pomermaid warns of them. Edges join blocks by id.

   pomermaid's own rules (PLAN.md's decisions): a chain of links, a link
   in a composite block's header, a width of 0 columns and "columns 0"
   are errors; so is style on an unknown block or on a list of blocks,
   on which Mermaid fails. class on an id with blanks before it (after
   a comma) is warned of and ignored. A class name with blanks is
   several classes. Generated ids are "id-N", N counting spaces and
   composite blocks in the order they end. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml;

CONST
  (* the blocks' types *)
  Na* = 0; Square* = 1; Round* = 2; Circle* = 3; LeftArrow* = 4; Diamond* = 5;
  Hexagon* = 6; Stadium* = 7; Subroutine* = 8; Cylinder* = 9; DoubleCircle* = 10;
  LeanRight* = 11; LeanLeft* = 12; Trapezoid* = 13; InvTrapezoid* = 14;
  BlockArrow* = 15; Composite* = 16; Space* = 17;
  (* a block arrow's directions *)
  Right* = 0; Left* = 1; Up* = 2; Down* = 3;

  (* tokens *)
  tEOF = 0; tKey = 1; tIdBlock = 2; tColumns = 3; tSpace = 4; tClassDef = 5;
  tClass = 6; tStyle = 7; tEnd = 8; tDStart = 9; tArrow = 10; tId = 11; tLink = 12;
  tSize = 13; tString = 14; tReserved = 15; tError = 16;

  (* statements *)
  sNode = 0; sComposite = 1; sSpace = 2; sColumns = 3; sEdge = 4; sClassDef = 5;
  sClass = 6; sStyle = 7;

  MaxCount = 10000;     (* columns, widths and spaces *)
  LF = 0AX; CR = 0DX; TAB = 09X;

TYPE
  Str = L.Str;

  Block* = POINTER TO BlockDesc;
  BlockDesc* = RECORD
    id-: Str;
    label-: F.Label;
    type-: INTEGER;
    wic-: LONGINT;           (* its width in columns *)
    dirs-: SET;              (* a block arrow's, Right .. Down *)
    columns-: LONGINT;       (* a composite's; -1 for auto *)
    classes-: F.Name;
    style-: F.Prop;          (* its style statement's *)
    children-, next-: Block;
    nChildren-: LONGINT;
    inTree-: BOOLEAN;        (* in the tree, so drawn *)
    phantom: BOOLEAN;        (* made by class *)
    pos-: LONGINT;           (* where it is in the text *)
    x*, y*, w*, h*: LONGREAL; (* the layout's: its middle and size *)
    sized*: BOOLEAN;
    last, dbNext: Block
  END;

  Edge* = POINTER TO EdgeDesc;
  EdgeDesc* = RECORD
    id-: Str;                (* "N-from-to", N counting the edges between them *)
    from-, to-: Block;
    label-: F.Label;         (* or NIL *)
    startMark-, endMark-: INTEGER;  (* F.None, F.Arrow, F.CircleEnd or F.Cross *)
    thick-, dotted-: BOOLEAN;
    pos-: LONGINT;
    next-: Edge
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;             (* the classDefs and the configuration *)
    root-: Block;            (* its children the blocks at the top *)
    edges-: Edge;
    nBlocks-, nEdges-: LONGINT;
    padding-: LONGREAL       (* config.block.padding *)
  END;

  Token = RECORD
    kind: INTEGER;
    start, end: LONGINT;     (* its text *)
    a0, a1, b0, b1: LONGINT; (* a classDef's name and styles; class's
                                and style's ids and the rest; a link's
                                text and its label, b0 < 0 for none *)
    n: LONGINT               (* a number: columns, a width *)
  END;

  Stmt = POINTER TO StmtDesc;
  StmtDesc = RECORD
    kind: INTEGER;
    id: Str;
    label: F.Label;          (* or NIL *)
    labelText: Str;          (* its text, as written, or NIL *)
    type: INTEGER;
    wic, n: LONGINT;
    dirs: SET;
    children, next: Stmt;
    pos: LONGINT;
    a0, a1, b0, b1: LONGINT;
    from, to: Str;
    startMark, endMark: INTEGER;
    thick, dotted: BOOLEAN
  END;

  Pending = POINTER TO PendingDesc;  (* an edge before its ends are found *)
  PendingDesc = RECORD
    s: Stmt;
    next: Pending
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;
  textStart: LONGINT;
  idCount: LONGINT;          (* generated ids *)
  db: Block;                 (* every block, by dbNext *)
  pending, lastPending: Pending;
  lastEdge: Edge;

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

PROCEDURE PutText(VAR n: LONGINT; start, end: LONGINT);
BEGIN
  WHILE start < end DO Put(n, sc.t[start]); INC(start) END
END PutText;

PROCEDURE PutStr(VAR n: LONGINT; s: Str);
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE s[i] # 0X DO Put(n, s[i]); INC(i) END
END PutStr;

PROCEDURE PutInt(VAR n: LONGINT; k: LONGINT);
  VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  IF k < 0 THEN Put(n, "-"); k := -k END;
  i := 0; REPEAT dg[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
  WHILE i > 0 DO DEC(i); Put(n, dg[i]) END
END PutInt;

(* Warns about the text at at: "NAME:LINE:COL: buf[0 .. n-1]" *)
PROCEDURE WarnBuf(at: LONGINT; n: LONGINT);
  VAR line, col: LONGINT; m: Str; k: LONGINT;
  PROCEDURE Add(s: ARRAY OF CHAR);
    VAR i: LONGINT;
  BEGIN
    i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO m[k] := s[i]; INC(k); INC(i) END
  END Add;
  PROCEDURE Num(x: LONGINT);
    VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
  BEGIN
    i := 0; REPEAT dg[i] := CHR(ORD("0") + x MOD 10); x := x DIV 10; INC(i) UNTIL x = 0;
    WHILE i > 0 DO DEC(i); m[k] := dg[i]; INC(k) END
  END Num;
BEGIN
  sc.Where(at, line, col);
  NEW(m, n + L.Length(sc.name) + 64); k := 0;
  Add(sc.name); Add(":"); Num(line); Add(":"); Num(col); Add(": ");
  FOR line := 0 TO n - 1 DO m[k] := buf[line]; INC(k) END;
  m[k] := 0X;
  PmIO.Warn(m^)
END WarnBuf;

(* The lexer *)

PROCEDURE Ch(p: LONGINT): CHAR;
BEGIN
  IF (p >= 0) & (p < sc.len) THEN RETURN sc.t[p] ELSE RETURN 0X END
END Ch;

(* JavaScript's \s, in ASCII *)
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

PROCEDURE IsDigit(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "0") & (ch <= "9")
END IsDigit;

(* A byte of a block's id: [^\(\[\n\-\)\{\}\s\<\>:=] *)
PROCEDURE IsIdChar(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch # 0X) & (ch # "(") & (ch # "[") & (ch # ")") & (ch # "-") & (ch # "{")
    & (ch # "}") & (ch # "<") & (ch # ">") & (ch # ":") & (ch # "=") & ~IsSpace(ch)
END IsIdChar;

(* Whether the text at p is w *)
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

(* Whether the text at p is the word w, as jison matches a rule ending
   in a word character: not followed by one *)
PROCEDURE Kw(p: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < LEN(w)) & (w[i] # 0X) DO INC(i) END;
  RETURN At(p, w) & ~IsWord(Ch(p + i))
END Kw;

PROCEDURE LineStart(p: LONGINT): BOOLEAN;
BEGIN
  RETURN (p <= textStart) OR (sc.t[p - 1] = LF) OR (sc.t[p - 1] = CR)
END LineStart;

(* If a comment that is a line of its own, with the white space before
   it, starts at p, a line's start, where it ends, after its line end,
   or else -1: Mermaid removes /^\s*%%(?!{)[^\n]+\n?/ *)
PROCEDURE CommentLine(p: LONGINT): LONGINT;
BEGIN
  WHILE IsSpace(Ch(p)) DO INC(p) END;
  IF At(p, "%%") & (Ch(p + 2) # "{") & (Ch(p + 2) # LF) & (p + 2 < sc.len) THEN
    p := p + 2;
    WHILE (p < sc.len) & (sc.t[p] # LF) DO INC(p) END;
    IF p < sc.len THEN INC(p) END;
    RETURN p
  END;
  RETURN -1
END CommentLine;

(* Where p is after what is skipped: comments that are lines of their
   own, white space, directives and "" *)
PROCEDURE Hidden(p: LONGINT): LONGINT;
  VAR e, save: LONGINT;
BEGIN
  LOOP
    IF p >= sc.len THEN EXIT END;
    IF LineStart(p) THEN e := CommentLine(p) ELSE e := -1 END;
    IF e >= 0 THEN p := e
    ELSIF IsSpace(sc.t[p]) THEN INC(p)
    ELSIF At(p, "%%{") THEN
      save := sc.pos; sc.pos := p; e := sc.DirectiveEnd(); sc.pos := save;
      IF e >= 0 THEN p := e ELSE EXIT END
    ELSIF At(p, '""') THEN INC(p, 2)
    ELSE EXIT
    END
  END;
  RETURN p
END Hidden;

(* Digits at p: their value, at most MaxCount + 1, in n; where they end *)
PROCEDURE Digits(p: LONGINT; VAR n: LONGINT): LONGINT;
BEGIN
  n := 0;
  WHILE IsDigit(Ch(p)) DO
    IF n <= MaxCount THEN n := n * 10 + ORD(Ch(p)) - ORD("0") END;
    INC(p)
  END;
  IF n > MaxCount THEN n := MaxCount + 1 END;
  RETURN p
END Digits;

(* Ids at p, one or more words separated by commas and white space: where they end, or -1 *)
PROCEDURE Ids(p: LONGINT): LONGINT;
  VAR q: LONGINT;
BEGIN
  IF ~IsWord(Ch(p)) THEN RETURN -1 END;
  WHILE IsWord(Ch(p)) DO INC(p) END;
  LOOP
    IF Ch(p) # "," THEN EXIT END;
    q := p + 1; WHILE IsSpace(Ch(q)) DO INC(q) END;
    IF ~IsWord(Ch(q)) THEN EXIT END;
    p := q; WHILE IsWord(Ch(p)) DO INC(p) END
  END;
  RETURN p
END Ids;

PROCEDURE LineEnd(p: LONGINT): LONGINT;
BEGIN
  WHILE (p < sc.len) & (sc.t[p] # LF) DO INC(p) END;
  RETURN p
END LineEnd;

(* A shape's opening at p, NODE_DSTART: its length, or 0 *)
PROCEDURE Opener(p: LONGINT): LONGINT;
BEGIN
  IF At(p, "-)") OR At(p, "(-") OR At(p, "))") THEN RETURN 2
  ELSIF At(p, ")") THEN RETURN 1
  ELSIF At(p, "(((") THEN RETURN 3
  ELSIF At(p, "((") OR At(p, "{{") THEN RETURN 2
  ELSIF At(p, "{") OR At(p, ">") THEN RETURN 1
  ELSIF At(p, "([") THEN RETURN 2
  ELSIF At(p, "(") THEN RETURN 1
  ELSIF At(p, "[[") OR At(p, "[|") OR At(p, "[(") OR At(p, "[\") OR At(p, "[/") THEN RETURN 2
  ELSIF At(p, "[") THEN RETURN 1
  END;
  RETURN 0
END Opener;

(* A shape's closing at p, NODE_DEND: its length, or 0 *)
PROCEDURE Closer(p: LONGINT): LONGINT;
BEGIN
  IF At(p, "(((") OR At(p, ")))") THEN RETURN 3
  ELSIF At(p, "))") OR At(p, "}}") THEN RETURN 2
  ELSIF At(p, "}") THEN RETURN 1
  ELSIF At(p, "(-") OR At(p, "-)") OR At(p, "((") OR At(p, "]]") THEN RETURN 2
  ELSIF At(p, "(") THEN RETURN 1
  ELSIF At(p, "])") OR At(p, "\]") OR At(p, "/]") OR At(p, ")]") THEN RETURN 2
  ELSIF At(p, ")") THEN RETURN 1
  ELSIF At(p, "]>") THEN RETURN 2
  ELSIF At(p, "]") THEN RETURN 1
  END;
  RETURN 0
END Closer;

PROCEDURE IsEndMark(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = "x") OR (ch = "o") OR (ch = ">")
END IsEndMark;

(* A link at p, without a label: where it ends, or -1 *)
PROCEDURE Link(p: LONGINT): LONGINT;
  VAR q, r: LONGINT;
BEGIN
  q := p; IF (Ch(q) = "x") OR (Ch(q) = "o") OR (Ch(q) = "<") THEN INC(q) END;
  (* [xo<]?--+[-xo>] *)
  r := q; WHILE Ch(r) = "-" DO INC(r) END;
  IF r - q >= 2 THEN
    IF IsEndMark(Ch(r)) THEN RETURN r + 1 ELSIF r - q >= 3 THEN RETURN r END
  END;
  (* [xo<]?==+[=xo>] *)
  r := q; WHILE Ch(r) = "=" DO INC(r) END;
  IF r - q >= 2 THEN
    IF IsEndMark(Ch(r)) THEN RETURN r + 1 ELSIF r - q >= 3 THEN RETURN r END
  END;
  (* [xo<]?-?\.+-[xo>]? *)
  r := q; IF Ch(r) = "-" THEN INC(r) END;
  IF Ch(r) = "." THEN
    WHILE Ch(r) = "." DO INC(r) END;
    IF Ch(r) = "-" THEN
      INC(r); IF IsEndMark(Ch(r)) THEN INC(r) END;
      RETURN r
    END
  END;
  RETURN -1
END Link;

(* A link's start, before a label, at p: where it ends, or -1 *)
PROCEDURE StartLink(p: LONGINT): LONGINT;
  VAR q: LONGINT;
BEGIN
  q := p; IF (Ch(q) = "x") OR (Ch(q) = "o") OR (Ch(q) = "<") THEN INC(q) END;
  IF At(q, "--") OR At(q, "==") OR At(q, "-.") THEN RETURN q + 2 END;
  RETURN -1
END StartLink;

(* A link with a label: its start, from p to e, then white space, the
   label in double quotation marks and the link's end, in t *)
PROCEDURE LabelledLink(p, e: LONGINT; VAR t: Token);
  VAR q: LONGINT;
BEGIN
  WHILE IsSpace(Ch(e)) DO INC(e) END;
  IF Ch(e) # '"' THEN sc.ErrorAt(e, "expected a link's label in double quotation marks") END;
  q := e + 1; WHILE (q < sc.len) & (sc.t[q] # '"') DO INC(q) END;
  IF q >= sc.len THEN sc.ErrorAt(e, "unterminated string") END;
  IF q = e + 1 THEN sc.ErrorAt(e, "a link's label is empty") END;
  t.b0 := e + 1; t.b1 := q;
  q := q + 1; WHILE IsSpace(Ch(q)) DO INC(q) END;
  e := Link(q);
  IF e < 0 THEN sc.ErrorAt(q, "expected the end of the link, such as -->") END;
  t.a0 := q; t.a1 := e; t.kind := tLink; t.end := e
END LabelledLink;

(* "classDef", white space, a name, white space and styles to the
   line's end, at p, in t; FALSE if none *)
PROCEDURE ClassDefToken(p: LONGINT; VAR t: Token): BOOLEAN;
  VAR q, r: LONGINT;
BEGIN
  IF ~At(p, "classDef") OR ~IsSpace(Ch(p + 8)) THEN RETURN FALSE END;
  q := p + 8; WHILE IsSpace(Ch(q)) DO INC(q) END;
  IF At(q, "DEFAULT") & IsSpace(Ch(q + 7)) THEN t.kind := tReserved; t.start := q; t.end := q + 7; RETURN TRUE END;
  r := q; WHILE IsWord(Ch(r)) DO INC(r) END;
  IF (r = q) OR ~IsSpace(Ch(r)) THEN t.kind := tError; t.start := r; t.end := r + 1; RETURN TRUE END;
  t.a0 := q; t.a1 := r;
  WHILE IsSpace(Ch(r)) DO INC(r) END;
  t.b0 := r; t.b1 := LineEnd(r);
  t.kind := tClassDef; t.end := t.b1;
  RETURN TRUE
END ClassDefToken;

(* word ("class" or "style"), white space, ids and the rest of the line,
   at p, in t, as kind; FALSE if none *)
PROCEDURE Applied(p: LONGINT; word: ARRAY OF CHAR; kind: INTEGER; VAR t: Token): BOOLEAN;
  VAR q, e: LONGINT;
BEGIN
  IF ~At(p, word) OR ~IsSpace(Ch(p + 5)) THEN RETURN FALSE END;
  q := p + 5; WHILE IsSpace(Ch(q)) DO INC(q) END;
  e := Ids(q);
  IF e < 0 THEN t.kind := tError; t.start := q; t.end := q + 1; RETURN TRUE END;
  t.a0 := q; t.a1 := e; t.b0 := e; t.b1 := LineEnd(e);
  t.kind := kind; t.end := t.b1;
  RETURN TRUE
END Applied;

(* accTitle or accDescr at p; FALSE if none *)
PROCEDURE Acc(p: LONGINT; VAR t: Token): BOOLEAN;
  VAR q: LONGINT;
BEGIN
  IF At(p, "accTitle") OR At(p, "accDescr") THEN
    q := p + 8; WHILE IsSpace(Ch(q)) DO INC(q) END;
    IF (Ch(q) = ":") OR At(p, "accDescr") & (Ch(q) = "{") THEN
      t.kind := tReserved; t.end := q + 1; RETURN TRUE
    END
  END;
  RETURN FALSE
END Acc;

(* Where p is after white space *)
PROCEDURE SkipWs(p: LONGINT): LONGINT;
BEGIN
  WHILE IsSpace(Ch(p)) DO INC(p) END;
  RETURN p
END SkipWs;

PROCEDURE Set(VAR t: Token; kind: INTEGER; end: LONGINT);
BEGIN
  t.kind := kind; t.end := end
END Set;

(* The token at p, after what is skipped *)
PROCEDURE Lex(p: LONGINT; VAR t: Token);
  VAR e, q, k: LONGINT;
BEGIN
  p := Hidden(p);
  t.start := p; t.a0 := -1; t.a1 := -1; t.b0 := -1; t.b1 := -1; t.n := 0;
  IF p >= sc.len THEN t.kind := tEOF; t.end := p; RETURN END;
  IF Kw(p, "block-beta") THEN Set(t, tKey, p + 10)
  ELSIF At(p, "block:") THEN Set(t, tIdBlock, p + 6)
  ELSIF Kw(p, "block") THEN Set(t, tKey, p + 5)
  ELSIF At(p, "columns") & IsSpace(Ch(p + 7))
    & (Kw(SkipWs(p + 7), "auto") OR IsDigit(Ch(SkipWs(p + 7)))) THEN
    q := SkipWs(p + 7);
    IF Kw(q, "auto") THEN t.n := -1; Set(t, tColumns, q + 4)
    ELSE Set(t, tColumns, Digits(q, t.n))
    END
  ELSIF Ch(p) = '"' THEN
    e := p + 1; WHILE (e < sc.len) & (sc.t[e] # '"') DO INC(e) END;
    IF e < sc.len THEN INC(e) END;
    Set(t, tString, e)
  ELSIF At(p, "space:") & IsDigit(Ch(p + 6)) THEN Set(t, tSpace, Digits(p + 6, t.n))
  ELSIF Kw(p, "space") THEN t.n := 1; Set(t, tSpace, p + 5)
  ELSIF Kw(p, "default") THEN Set(t, tReserved, p + 7)
  ELSIF Kw(p, "linkStyle") THEN Set(t, tReserved, p + 9)
  ELSIF Kw(p, "interpolate") THEN Set(t, tReserved, p + 11)
  ELSIF ClassDefToken(p, t) THEN (* done *)
  ELSIF Applied(p, "class", tClass, t) THEN (* done *)
  ELSIF Applied(p, "style", tStyle, t) THEN (* done *)
  ELSIF Acc(p, t) THEN (* done *)
  ELSIF At(p, "end") & ~IsWord(Ch(p + 3)) THEN Set(t, tEnd, p + 3)
  ELSE
    k := Opener(p);
    IF k > 0 THEN Set(t, tDStart, p + k)
    ELSIF At(p, "<[") THEN Set(t, tArrow, p + 2)
    ELSIF IsIdChar(sc.t[p]) THEN
      e := p; WHILE IsIdChar(Ch(e)) DO INC(e) END;
      Set(t, tId, e)
    ELSE
      e := Link(p);
      IF e >= 0 THEN t.a0 := p; t.a1 := e; Set(t, tLink, e)
      ELSE
        e := StartLink(p);
        IF e >= 0 THEN LabelledLink(p, e, t)
        ELSIF (sc.t[p] = ":") & IsDigit(Ch(p + 1)) THEN Set(t, tSize, Digits(p + 1, t.n))
        ELSE Set(t, tError, p + 1)
        END
      END
    END
  END
END Lex;

(* Fails at t, which is not what was expected, what *)
PROCEDURE Unexpected(VAR t: Token; what: ARRAY OF CHAR);
  VAR n: LONGINT;
BEGIN
  n := 0; PutS(n, "expected "); PutS(n, what);
  IF t.kind = tEOF THEN PutS(n, ", not the end")
  ELSIF t.kind = tError THEN PutS(n, ", not '"); Put(n, Ch(t.start)); Put(n, "'")
  ELSE
    PutS(n, ", not '");
    IF t.end - t.start > 40 THEN PutText(n, t.start, t.start + 40); PutS(n, "...")
    ELSE PutText(n, t.start, t.end)
    END;
    Put(n, "'")
  END;
  buf[n] := 0X;
  sc.ErrorAt(t.start, buf^)
END Unexpected;

(* The parser: statements *)

PROCEDURE NewStmt(kind: INTEGER; pos: LONGINT): Stmt;
  VAR s: Stmt;
BEGIN
  NEW(s); s.kind := kind; s.pos := pos; s.id := NIL; s.label := NIL; s.labelText := NIL;
  s.type := Na; s.wic := 1; s.n := 0; s.dirs := {}; s.children := NIL; s.next := NIL;
  s.a0 := -1; s.a1 := -1; s.b0 := -1; s.b1 := -1; s.from := NIL; s.to := NIL;
  s.startMark := F.None; s.endMark := F.None; s.thick := FALSE; s.dotted := FALSE;
  RETURN s
END NewStmt;

PROCEDURE GeneratedId(): Str;
  VAR n: LONGINT;
BEGIN
  INC(idCount);
  n := 0; PutS(n, "id-"); PutInt(n, idCount); buf[n] := 0X;
  RETURN L.Sub(buf^, 0, n)
END GeneratedId;

(* A label in double quotation marks at p, not empty, in s; p after it *)
PROCEDURE Label(VAR p: LONGINT; s: Stmt);
  VAR e: LONGINT;
BEGIN
  IF Ch(p) # '"' THEN sc.ErrorAt(p, "expected a label in double quotation marks") END;
  IF Ch(p + 1) = "`" THEN sc.ErrorAt(p, "a markdown string, which block diagrams do not have") END;
  e := p + 1; WHILE (e < sc.len) & (sc.t[e] # '"') DO INC(e) END;
  IF e >= sc.len THEN sc.ErrorAt(p, "unterminated string") END;
  IF e = p + 1 THEN sc.ErrorAt(p, "a block's label is empty") END;
  s.label := F.MakeLabel(sc.t^, p + 1, e, FALSE);
  s.labelText := L.Sub(sc.t^, p + 1, e - p - 1);
  p := e + 1
END Label;

(* The type of the shape whose opening is sc.t[a .. b-1] and closing
   sc.t[c .. e-1] *)
PROCEDURE TypeOf(a, b, c, e: LONGINT): INTEGER;
  VAR s: ARRAY 8 OF CHAR; n: INTEGER;
BEGIN
  n := 0;
  WHILE a < b DO s[n] := sc.t[a]; INC(n); INC(a) END;
  WHILE c < e DO s[n] := sc.t[c]; INC(n); INC(c) END;
  s[n] := 0X;
  IF s = "[]" THEN RETURN Square
  ELSIF s = "()" THEN RETURN Round
  ELSIF s = "(())" THEN RETURN Circle
  ELSIF s = ">]" THEN RETURN LeftArrow
  ELSIF s = "{}" THEN RETURN Diamond
  ELSIF s = "{{}}" THEN RETURN Hexagon
  ELSIF s = "([])" THEN RETURN Stadium
  ELSIF s = "[[]]" THEN RETURN Subroutine
  ELSIF s = "[()]" THEN RETURN Cylinder
  ELSIF s = "((()))" THEN RETURN DoubleCircle
  ELSIF s = "[//]" THEN RETURN LeanRight
  ELSIF s = "[\\]" THEN RETURN LeanLeft
  ELSIF s = "[/\]" THEN RETURN Trapezoid
  ELSIF s = "[\/]" THEN RETURN InvTrapezoid
  END;
  RETURN Na
END TypeOf;

(* A block arrow's direction at q, in dirs; FALSE if none *)
PROCEDURE Dir(VAR q: LONGINT; VAR dirs: SET): BOOLEAN;
  VAR m, e, len: LONGINT; comma, valid: BOOLEAN; k: INTEGER; set: SET;
BEGIN
  m := q; comma := Ch(m) = ",";
  IF comma THEN INC(m) END;
  WHILE IsSpace(Ch(m)) DO INC(m) END;
  k := 0;
  LOOP
    CASE k OF
      0: len := 5; set := {Right}; IF At(m, "right") THEN EXIT END
    | 1: len := 4; set := {Left}; IF At(m, "left") THEN EXIT END
    | 2: len := 1; set := {Right, Left}; IF At(m, "x") THEN EXIT END
    | 3: len := 1; set := {Up, Down}; IF At(m, "y") THEN EXIT END
    | 4: len := 2; set := {Up}; IF At(m, "up") THEN EXIT END
    | 5: len := 4; set := {Down}; IF At(m, "down") THEN EXIT END
    | 6: RETURN FALSE
    END;
    INC(k)
  END;
  e := m + len; WHILE IsSpace(Ch(e)) DO INC(e) END;
  (* Mermaid keeps the text without /^,\s*/; it must be the name *)
  valid := (e = m + len) & (comma OR (m = q));
  IF valid THEN dirs := dirs + set END;
  q := e;
  RETURN TRUE
END Dir;

(* A block, its id t, and its shape and label, if any; p after it *)
PROCEDURE Node(VAR p: LONGINT; VAR t: Token): Stmt;
  VAR s: Stmt; u: Token; q, k, n: LONGINT;
BEGIN
  s := NewStmt(sNode, t.start); s.id := L.Sub(sc.t^, t.start, t.end - t.start);
  p := t.end;
  Lex(p, u);
  IF u.kind = tDStart THEN
    q := u.end; Label(q, s);
    k := Closer(q);
    IF k = 0 THEN sc.ErrorAt(q, "expected the end of the block's shape") END;
    s.type := TypeOf(u.start, u.end, q, q + k);
    p := q + k
  ELSIF u.kind = tArrow THEN
    q := u.end; Label(q, s);
    IF ~At(q, "]>") THEN sc.ErrorAt(q, "expected ]> after a block arrow's label") END;
    INC(q, 2); WHILE IsSpace(Ch(q)) DO INC(q) END;
    IF Ch(q) # "(" THEN sc.ErrorAt(q, "expected ( and a block arrow's directions") END;
    INC(q); n := 0;
    LOOP
      IF Ch(q) = ")" THEN
        IF n = 0 THEN sc.ErrorAt(q, "expected a direction: right, left, x, y, up or down") END;
        INC(q); EXIT
      END;
      IF ~Dir(q, s.dirs) THEN
        sc.ErrorAt(q, "expected a direction: right, left, x, y, up or down")
      END;
      INC(n)
    END;
    s.type := BlockArrow; p := q
  END;
  RETURN s
END Node;

PROCEDURE Width(VAR t: Token): LONGINT;
BEGIN
  IF t.n = 0 THEN sc.ErrorAt(t.start, "a block's width must be at least one column") END;
  IF t.n > MaxCount THEN sc.ErrorAt(t.start, "the width is too large") END;
  RETURN t.n
END Width;

(* The link t's ends, line and label, in e *)
PROCEDURE LinkOf(VAR t: Token; e: Stmt);
  VAR k: LONGINT; first, last: CHAR;
BEGIN
  first := sc.t[t.a0]; last := sc.t[t.a1 - 1];
  IF first = "x" THEN e.startMark := F.Cross
  ELSIF first = "o" THEN e.startMark := F.CircleEnd
  ELSIF first = "<" THEN e.startMark := F.Arrow
  END;
  IF last = "x" THEN e.endMark := F.Cross
  ELSIF last = "o" THEN e.endMark := F.CircleEnd
  ELSIF last = ">" THEN e.endMark := F.Arrow
  END;
  FOR k := t.a0 TO t.a1 - 2 DO
    IF (sc.t[k] = "=") & (sc.t[k + 1] = "=") THEN e.thick := TRUE END;
    IF (sc.t[k] = ".") & (sc.t[k + 1] = "-") THEN e.dotted := TRUE END
  END;
  IF t.b0 >= 0 THEN e.label := F.MakeLabel(sc.t^, t.b0, t.b1, FALSE) END
END LinkOf;

PROCEDURE Document(VAR p: LONGINT; inBlock: BOOLEAN): Stmt;
  VAR first, last, s, s2, e: Stmt; t, u, v: Token; linked: BOOLEAN;

  PROCEDURE Add(s: Stmt);
  BEGIN
    IF first = NIL THEN first := s ELSE last.next := s END;
    last := s
  END Add;

BEGIN
  first := NIL; last := NIL; linked := FALSE;
  LOOP
    Lex(p, t);
    IF (t.kind = tEOF) OR (t.kind = tEnd) THEN
      IF first = NIL THEN Unexpected(t, "a statement") END;
      IF (t.kind = tEOF) & inBlock THEN Unexpected(t, "a statement or end") END;
      IF (t.kind = tEnd) & ~inBlock THEN Unexpected(t, "a statement") END;
      p := t.end; EXIT
    END;
    CASE t.kind OF
      tId:
        s := Node(p, t); Lex(p, u);
        IF u.kind = tSize THEN s.wic := Width(u); p := u.end; Lex(p, u) END;
        Add(s); linked := FALSE;
        IF u.kind = tLink THEN
          s.wic := 1; p := u.end; Lex(p, v);
          IF v.kind # tId THEN Unexpected(v, "a block") END;
          s2 := Node(p, v);
          e := NewStmt(sEdge, u.start); e.from := s.id; e.to := s2.id; LinkOf(u, e);
          Add(e); Add(s2); linked := TRUE
        END
    | tIdBlock:
        p := t.end; Lex(p, u);
        IF u.kind # tId THEN Unexpected(u, "a block's id") END;
        s := Node(p, u); Lex(p, v);
        IF v.kind = tSize THEN s.wic := Width(v); p := v.end; Lex(p, v) END;
        IF v.kind = tLink THEN sc.ErrorAt(v.start, "a link in a composite block's header") END;
        s.kind := sComposite; s.type := Composite;
        s.children := Document(p, TRUE);
        INC(idCount);
        Add(s); linked := FALSE
    | tKey:
        p := t.end;
        s := NewStmt(sComposite, t.start); s.type := Composite;
        s.children := Document(p, TRUE);
        s.id := GeneratedId();
        Add(s); linked := FALSE
    | tColumns:
        IF t.n = 0 THEN sc.ErrorAt(t.start, "columns must not be 0") END;
        IF t.n > MaxCount THEN sc.ErrorAt(t.start, "too many columns") END;
        s := NewStmt(sColumns, t.start); s.n := t.n; p := t.end; Add(s); linked := FALSE
    | tSpace:
        IF t.n > MaxCount THEN sc.ErrorAt(t.start, "too many spaces") END;
        s := NewStmt(sSpace, t.start); s.n := t.n; s.id := GeneratedId(); s.type := Space;
        p := t.end; Add(s); linked := FALSE
    | tClassDef, tClass, tStyle:
        IF t.kind = tClassDef THEN s := NewStmt(sClassDef, t.start)
        ELSIF t.kind = tClass THEN s := NewStmt(sClass, t.start)
        ELSE s := NewStmt(sStyle, t.start)
        END;
        s.a0 := t.a0; s.a1 := t.a1; s.b0 := t.b0; s.b1 := t.b1;
        p := t.end; Add(s); linked := FALSE
    | tLink:
        IF linked THEN sc.ErrorAt(t.start, "a chain of links: pomermaid reads one link a statement") END;
        Unexpected(t, "a statement")
    | tSize:
        IF linked THEN sc.ErrorAt(t.start, "a width after a link's second block") END;
        Unexpected(t, "a statement")
    ELSE Unexpected(t, "a statement")
    END
  END;
  RETURN first
END Document;

(* The model, as blockDB.ts's populateBlockDatabase makes it *)

PROCEDURE Find(id: Str): Block;
  VAR b: Block;
BEGIN
  b := db; WHILE (b # NIL) & ~L.Equal(b.id, id) DO b := b.dbNext END;
  RETURN b
END Find;

PROCEDURE NewBlock(id: Str; type: INTEGER; pos: LONGINT): Block;
  VAR b: Block;
BEGIN
  NEW(b); b.id := id; b.label := NIL; b.type := type; b.wic := 1; b.dirs := {};
  b.columns := -1; b.classes := NIL; b.style := NIL; b.children := NIL; b.next := NIL;
  b.nChildren := 0; b.inTree := FALSE; b.phantom := FALSE; b.pos := pos;
  b.x := 0; b.y := 0; b.w := 0; b.h := 0; b.sized := FALSE; b.last := NIL; b.dbNext := NIL;
  RETURN b
END NewBlock;

(* b in the database, replacing a block with its id *)
PROCEDURE Register(b: Block);
  VAR c, prev: Block;
BEGIN
  prev := NIL; c := db;
  WHILE (c # NIL) & ~L.Equal(c.id, b.id) DO prev := c; c := c.dbNext END;
  IF c # NIL THEN
    b.dbNext := c.dbNext;
    IF prev = NIL THEN db := b ELSE prev.dbNext := b END
  ELSE b.dbNext := db; db := b
  END
END Register;

PROCEDURE Push(parent, b: Block; inTree: BOOLEAN);
BEGIN
  b.inTree := inTree; b.next := NIL;
  IF parent.children = NIL THEN parent.children := b ELSE parent.last.next := b END;
  parent.last := b; INC(parent.nChildren);
  IF inTree THEN INC(d.nBlocks) END
END Push;

(* sc.t[a .. b-1] without white space at either end *)
PROCEDURE Trimmed(a, b: LONGINT): Str;
BEGIN
  WHILE (a < b) & IsSpace(sc.t[a]) DO INC(a) END;
  WHILE (b > a) & IsSpace(sc.t[b - 1]) DO DEC(b) END;
  RETURN L.Sub(sc.t^, a, b - a)
END Trimmed;

PROCEDURE ClassDef(s: Stmt);
  VAR c, p: F.ClassDef; n, k, a: LONGINT; cut: BOOLEAN; st: Str;
BEGIN
  NEW(c); c.name := Trimmed(s.a0, s.a1); c.next := NIL;
  (* each style, split at ",", loses its first ";" *)
  st := Trimmed(s.b0, s.b1);
  n := 0; cut := FALSE; k := 0;
  WHILE st[k] # 0X DO
    IF st[k] = "," THEN Put(n, ","); cut := FALSE
    ELSIF (st[k] = ";") & ~cut THEN cut := TRUE
    ELSE Put(n, st[k])
    END;
    INC(k)
  END;
  buf[n] := 0X; a := n;
  c.props := F.Props(L.Sub(buf^, 0, a));
  IF d.g.classDefs = NIL THEN d.g.classDefs := c
  ELSE p := d.g.classDefs; WHILE p.next # NIL DO p := p.next END; p.next := c
  END
END ClassDef;

PROCEDURE NotDrawn(b: Block; pos: LONGINT);
  VAR n: LONGINT;
BEGIN
  n := 0; PutS(n, "the block "); PutStr(n, b.id); PutS(n, " is not drawn");
  IF b = d.root THEN PutS(n, ": root is the diagram's own id")
  ELSIF b.phantom THEN PutS(n, ": class named it before it was defined")
  ELSE PutS(n, ": it is in a composite block defined a second time")
  END;
  WarnBuf(pos, n)
END NotDrawn;

PROCEDURE ApplyClass(s: Stmt);
  VAR ids, names: Str; a, k, n: LONGINT; b: Block; id: Str;
BEGIN
  ids := Trimmed(s.a0, s.a1); names := Trimmed(s.b0, s.b1);
  a := 0;
  LOOP
    k := a; WHILE (ids[k] # 0X) & (ids[k] # ",") DO INC(k) END;
    IF IsSpace(ids[a]) THEN
      n := 0; PutS(n, "class: the id "); PutText(n, s.a0 + a, s.a0 + k);
      PutS(n, " has blanks before it; it is ignored");
      WarnBuf(s.pos, n)
    ELSE
      id := L.Sub(ids^, a, k - a);
      b := Find(id);
      IF b = NIL THEN b := NewBlock(id, Na, s.pos); b.phantom := TRUE; Register(b) END;
      n := 0;
      WHILE names[n] # 0X DO
        WHILE IsSpace(names[n]) DO INC(n) END;
        a := n; WHILE (names[n] # 0X) & ~IsSpace(names[n]) DO INC(n) END;
        IF n > a THEN F.AddName(b.classes, L.Sub(names^, a, n - a)) END
      END
    END;
    IF ids[k] = 0X THEN EXIT END;
    a := k + 1
  END
END ApplyClass;

PROCEDURE ApplyStyle(s: Stmt);
  VAR id, st: Str; b: Block; k, n: LONGINT;
BEGIN
  id := Trimmed(s.a0, s.a1);
  k := 0; WHILE (id[k] # 0X) & (id[k] # ",") DO INC(k) END;
  IF id[k] = "," THEN sc.ErrorAt(s.a0, "style names one block, not a list of blocks") END;
  b := Find(id);
  IF b = NIL THEN
    n := 0; PutS(n, "style: there is no block "); PutStr(n, id); buf[n] := 0X;
    sc.ErrorAt(s.a0, buf^)
  END;
  st := Trimmed(s.b0, s.b1);
  (* Mermaid puts the styles in a CSS style attribute, where ";" ends a
     declaration as "," does here *)
  k := 0; WHILE st[k] # 0X DO IF st[k] = ";" THEN st[k] := "," END; INC(k) END;
  IF st[0] # 0X THEN b.style := F.Props(st) END
END ApplyStyle;

PROCEDURE Populate(list: Stmt; parent: Block; inTree: BOOLEAN);
  VAR s: Stmt; column, j, n: LONGINT; b, throw: Block; pe: Pending; id: Str;
BEGIN
  column := -1; s := list;
  WHILE (s # NIL) & (s.kind # sColumns) DO s := s.next END;
  IF s # NIL THEN column := s.n END;
  s := list;
  WHILE s # NIL DO
    IF (column > 0) & ((s.kind = sNode) OR (s.kind = sComposite)) & (s.wic > column) THEN
      n := 0; PutS(n, "the block "); PutStr(n, s.id); PutS(n, "'s width, ");
      PutInt(n, s.wic); PutS(n, ", is more than its columns, "); PutInt(n, column);
      WarnBuf(s.pos, n)
    END;
    CASE s.kind OF
      sClassDef: ClassDef(s)
    | sClass: ApplyClass(s)
    | sStyle: ApplyStyle(s)
    | sColumns: parent.columns := s.n
    | sEdge:
        NEW(pe); pe.s := s; pe.next := NIL;
        IF pending = NIL THEN pending := pe ELSE lastPending.next := pe END;
        lastPending := pe
    | sSpace:
        FOR j := 0 TO s.n - 1 DO
          n := 0; PutStr(n, s.id); Put(n, "-"); PutInt(n, j); buf[n] := 0X;
          id := L.Sub(buf^, 0, n);
          b := NewBlock(id, Space, s.pos); b.label := F.PlainLabel(L.New(""));
          Register(b); Push(parent, b, inTree)
        END
    | sNode, sComposite:
        IF s.label = NIL THEN
          IF s.kind = sComposite THEN s.labelText := L.New("") ELSE s.labelText := s.id END;
          s.label := F.PlainLabel(s.labelText)
        END;
        b := Find(s.id);
        IF b = NIL THEN
          b := NewBlock(s.id, s.type, s.pos);
          b.label := s.label; b.wic := s.wic; b.dirs := s.dirs;
          Register(b);
          IF s.children # NIL THEN Populate(s.children, b, inTree) END;
          IF ~inTree & (s.kind = sNode) THEN NotDrawn(b, s.pos) END;
          Push(parent, b, inTree)
        ELSE
          IF s.type # Na THEN b.type := s.type END;
          IF ~L.Equal(s.labelText, s.id) THEN b.label := s.label END;
          IF ~b.inTree OR (b = d.root) THEN NotDrawn(b, s.pos) END;
          IF s.children # NIL THEN
            throw := NewBlock(s.id, Composite, s.pos);
            Populate(s.children, throw, FALSE)
          END
        END
    END;
    s := s.next
  END
END Populate;

(* The edges, their ends found by id; those whose ends are not drawn
   are left out, with a warning *)
PROCEDURE Edges;
  VAR pe: Pending; e, f: Edge; a, b: Block; n, count: LONGINT; s: Stmt;
BEGIN
  pe := pending;
  WHILE pe # NIL DO
    s := pe.s;
    a := Find(s.from); b := Find(s.to);
    IF (a = NIL) OR (b = NIL) OR ~a.inTree OR ~b.inTree OR (a = d.root) OR (b = d.root) THEN
      n := 0; PutS(n, "the link from "); PutStr(n, s.from); PutS(n, " to "); PutStr(n, s.to);
      PutS(n, " is not drawn, as one of its blocks is not");
      WarnBuf(s.pos, n)
    ELSE
      NEW(e); e.from := a; e.to := b; e.label := s.label; e.startMark := s.startMark;
      e.endMark := s.endMark; e.thick := s.thick; e.dotted := s.dotted; e.pos := s.pos;
      e.next := NIL;
      count := 1; f := d.edges;
      WHILE f # NIL DO IF (f.from = a) & (f.to = b) THEN INC(count) END; f := f.next END;
      n := 0; PutInt(n, count); Put(n, "-"); PutStr(n, s.from); Put(n, "-"); PutStr(n, s.to);
      buf[n] := 0X; e.id := L.Sub(buf^, 0, n);
      IF d.edges = NIL THEN d.edges := e ELSE lastEdge.next := e END;
      lastEdge := e; INC(d.nEdges)
    END;
    pe := pe.next
  END
END Edges;

(* config.block.name, a number, or default *)
PROCEDURE Conf(name: ARRAY OF CHAR; default: LONGREAL): LONGREAL;
  VAR q: Y.Pair; i: LONGINT; x, f: LONGREAL; neg, digits: BOOLEAN; s: Str;
BEGIN
  q := Y.Find(d.g.config, name);
  IF q = NIL THEN RETURN default END;
  s := q.value; i := 0; x := 0; neg := FALSE; digits := FALSE;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF (s[i] = "-") OR (s[i] = "+") THEN neg := s[i] = "-"; INC(i) END;
  WHILE L.IsDigit(s[i]) DO x := x * 10 + (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE END;
  IF s[i] = "." THEN
    INC(i); f := 0.1D0;
    WHILE L.IsDigit(s[i]) DO x := x + f * (ORD(s[i]) - ORD("0")); f := f / 10; INC(i); digits := TRUE END
  END;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF ~digits OR (s[i] # 0X) THEN RETURN default END;
  IF neg THEN x := -x END;
  RETURN x
END Conf;

(* Whether the scanner's text, after front matter and comments, starts
   with "block" *)
PROCEDURE IsBlock*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("block");
  s.pos := save;
  RETURN r
END IsBlock;

(* Reads the block diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR p: LONGINT; t: Token; list: Stmt;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Block, d.g); sc := s;
  textStart := sc.pos; idCount := 0; db := NIL; pending := NIL; lastPending := NIL;
  lastEdge := NIL;
  d.edges := NIL; d.nBlocks := 0; d.nEdges := 0;
  d.padding := Conf("config.block.padding", 8);
  d.root := NewBlock(L.New("root"), Composite, sc.pos);
  d.root.label := F.PlainLabel(L.New("")); d.root.inTree := TRUE;
  Register(d.root);
  Lex(sc.pos, t);
  IF t.kind # tKey THEN Unexpected(t, "block-beta") END;
  p := t.end;
  list := Document(p, FALSE);
  Populate(list, d.root, TRUE);
  Edges;
  db := NIL; pending := NIL; lastPending := NIL; lastEdge := NIL;
  sc.pos := sc.len
END Read;

(* The name of type t, as Mermaid's, in s *)
PROCEDURE TypeName*(t: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  CASE t OF
    Na: COPY("na", s)
  | Square: COPY("square", s)
  | Round: COPY("round", s)
  | Circle: COPY("circle", s)
  | LeftArrow: COPY("rect_left_inv_arrow", s)
  | Diamond: COPY("diamond", s)
  | Hexagon: COPY("hexagon", s)
  | Stadium: COPY("stadium", s)
  | Subroutine: COPY("subroutine", s)
  | Cylinder: COPY("cylinder", s)
  | DoubleCircle: COPY("doublecircle", s)
  | LeanRight: COPY("lean_right", s)
  | LeanLeft: COPY("lean_left", s)
  | Trapezoid: COPY("trapezoid", s)
  | InvTrapezoid: COPY("inv_trapezoid", s)
  | BlockArrow: COPY("block_arrow", s)
  | Composite: COPY("composite", s)
  | Space: COPY("space", s)
  END
END TypeName;

BEGIN
  NEW(buf, 256)
END PmBlock.
