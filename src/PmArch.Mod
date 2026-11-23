MODULE PmArch;
(* PmArch: Mermaid's architecture diagrams (`architecture-beta`): its
   groups, services, junctions, edges and alignments, read as Mermaid
   12.3.0 reads them, and the grid positions Mermaid's database gives
   the services and junctions.

   The reader follows packages/parser/src/language/architecture/
   architecture.langium, its token builder and value converter, and
   diagrams/architecture/architectureParser.ts and architectureDb.ts:

   - blanks, "%%" comments and directives are skipped between tokens
     (a directive with the line end after it); line ends are not: each
     statement and each title ends a line;
   - the diagram starts with "architecture-beta";
   - "title text", "accTitle: text" and "accDescr: text" (or
     "accDescr { text }") may come anywhere; Mermaid does not draw the
     title, and nor does pomermaid;
   - "group id(icon)[title] in parent", "service id(icon)[title] in
     parent" (or "service id \"text\"[title]", a text in the icon's
     place), "junction id in parent", the icon, title and parent each
     optional;
   - an edge, "a{group}:R <-[title]-> L:b{group}": its ends' sides
     (L, R, T or B), "<" or ">" for an arrow at either end, "--" or a
     title between "-" and "-", and "{group}" to start or end it
     outside the end's group;
   - "align row a b ..." or "align column a b ...".

   As in Mermaid's lexer, a token is the first kind that matches, not
   the longest: a capital L, R, T or B is a side wherever it comes,
   and "title" a title; a keyword followed by more of an id is an id.
   An id is ASCII letters, digits and "_", with "-" inside.

   The model is filled as Mermaid's populateDb fills it: the groups,
   then the services, the junctions, the edges and the alignments,
   each in the order read, with Mermaid's messages for its errors. An
   edge to a group, which stops Mermaid, is an error.

   The services and junctions are then placed on grids, as Mermaid's
   getDataStructures places them for its layout: from the first not
   yet placed, breadth first, each edge's far end one step from its
   near end, by the edge's sides (y up); one grid for each connected
   part.

   The configuration is config.architecture's padding (40), iconSize
   (80) and fontSize (16). *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml;

CONST
  (* tokens *)
  tEOF = 0; tNewline = 1; tAccDescr = 2; tAccTitle = 3; tTitle = 4; tKeyword = 5;
  tJunction = 6; tService = 7; tColumn = 8; tGroup = 9; tAlign = 10; tRow = 11; tIn = 12;
  tDashDash = 13; tDash = 14; tColon = 15; tDir = 16; tArrowGroup = 17; tInto = 18;
  tString = 19; tId = 20; tIcon = 21; tArchTitle = 22; tError = 23;

  LF = 0AX; CR = 0DX; TAB = 09X;

TYPE
  Str = L.Str;

  Group* = POINTER TO GroupDesc;
  GroupDesc* = RECORD
    id-, icon-, in-: Str;     (* in: its parent's id, or NIL *)
    title-: F.Label;          (* or NIL *)
    titleText-: Str;
    parent-: Group;
    index-, depth-: LONGINT;  (* depth: 0 outside any group *)
    empty-: BOOLEAN;          (* no service or junction is in it *)
    next-: Group;
    pos: LONGINT
  END;

  (* An edge's far end, from a node, by the pair of sides, the near
     end's then the far end's *)
  Adj = POINTER TO AdjDesc;
  AdjDesc = RECORD
    pair: ARRAY 3 OF CHAR;
    other: LONGINT;           (* its node's index *)
    next: Adj
  END;

  (* A service or a junction *)
  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    id-, icon-, in-: Str;
    junction-: BOOLEAN;
    iconText-: Str;           (* a service's text in its icon's place, or NIL *)
    iconLabel-: F.Label;
    title-: F.Label;
    titleText-: Str;
    parent-: Group;
    index-: LONGINT;
    map-, gx-, gy-: LONGINT;  (* its grid, from 0, and place on it, y up *)
    next-: Node;
    adj, lastAdj: Adj;
    pos: LONGINT
  END;

  Edge* = POINTER TO EdgeDesc;
  EdgeDesc* = RECORD
    lhs-, rhs-: Node;
    lhsDir-, rhsDir-: CHAR;   (* "L", "R", "T" or "B" *)
    lhsInto-, rhsInto-, lhsGroup-, rhsGroup-: BOOLEAN;
    title-: F.Label;
    titleText-: Str;
    next-: Edge;
    lhsId, rhsId: Str;
    pos: LONGINT
  END;

  Nodes* = POINTER TO ARRAY OF Node;
  Strs = POINTER TO ARRAY OF Str;
  Ints = POINTER TO ARRAY OF LONGINT;

  Align* = POINTER TO AlignDesc;
  AlignDesc* = RECORD
    column-: BOOLEAN;
    members-: Nodes;
    n-: LONGINT;
    next-: Align;
    ids: Strs;
    at: Ints;
    pos: LONGINT
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;                       (* the configuration *)
    title-, accTitle-, accDescr-: Str; (* or NIL *)
    groups-: Group;
    nodes-: Node;                      (* the services, then the junctions *)
    edges-: Edge;
    aligns-: Align;
    nGroups-, nNodes-, nEdges-, nMaps-: LONGINT;
    padding-, iconSize-, fontSize-: LONGREAL;
    byIndex-: Nodes;
    lastGroup: Group; lastNode: Node; lastEdge: Edge; lastAlign: Align
  END;

  Token = RECORD
    kind: INTEGER;
    start, end: LONGINT;  (* its text *)
    a0, a1: LONGINT       (* a title's text; a1 < 0: "title" before more of a word *)
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;
  (* as read *)
  groups, lastGroup: Group;
  services, lastService, junctions, lastJunction: Node;
  edges, lastEdge: Edge;
  aligns, lastAlign: Align;

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
BEGIN
  PutS(n, s^)
END PutStr;

PROCEDURE PutInt(VAR n: LONGINT; k: LONGINT);
  VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  IF k < 0 THEN Put(n, "-"); k := -k END;
  i := 0; REPEAT dg[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
  WHILE i > 0 DO DEC(i); Put(n, dg[i]) END
END PutInt;

PROCEDURE Fail(at, n: LONGINT);
BEGIN
  buf[n] := 0X; sc.ErrorAt(at, buf^)
END Fail;

(* Warns, at at, a *)
PROCEDURE Warn(at: LONGINT; a: ARRAY OF CHAR);
  VAR line, col, n: LONGINT;
BEGIN
  sc.Where(at, line, col);
  n := 0; PutS(n, sc.name); Put(n, ":"); PutInt(n, line); Put(n, ":"); PutInt(n, col);
  PutS(n, ": "); PutS(n, a); buf[n] := 0X;
  PmIO.Warn(buf^)
END Warn;

(* The lexer *)

PROCEDURE Ch(p: LONGINT): CHAR;
BEGIN
  IF p < sc.len THEN RETURN sc.t[p] ELSE RETURN 0X END
END Ch;

PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = TAB) OR (ch = LF) OR (ch = CR) OR (ch = 0BX) OR (ch = 0CX)
END IsSpace;

PROCEDURE IsBlank(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = TAB)
END IsBlank;

PROCEDURE IsLineEnd(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = LF) OR (ch = CR)
END IsLineEnd;

(* JavaScript's \w *)
PROCEDURE IsWord(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "a") & (ch <= "z") OR (ch >= "A") & (ch <= "Z") OR (ch >= "0") & (ch <= "9")
    OR (ch = "_")
END IsWord;

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

(* Where p is after what is skipped: blanks, comments and directives,
   with the line end after a directive, not other line ends *)
PROCEDURE Hidden(p: LONGINT): LONGINT;
  VAR e, save: LONGINT;
BEGIN
  LOOP
    IF p >= sc.len THEN EXIT END;
    IF IsBlank(sc.t[p]) THEN INC(p)
    ELSIF At(p, "%%{") THEN
      save := sc.pos; sc.pos := p; e := sc.DirectiveEnd(); sc.pos := save;
      IF e >= 0 THEN
        p := e;
        IF Ch(p) = LF THEN INC(p) ELSIF (Ch(p) = CR) & (Ch(p + 1) = LF) THEN INC(p, 2) END
      ELSE WHILE (p < sc.len) & ~IsLineEnd(sc.t[p]) DO INC(p) END
      END
    ELSIF At(p, "%%") THEN
      WHILE (p < sc.len) & ~IsLineEnd(sc.t[p]) DO INC(p) END
    ELSE EXIT
    END
  END;
  RETURN p
END Hidden;

(* accDescr, accTitle or title at p; FALSE if none *)
PROCEDURE AccOrTitle(p: LONGINT; VAR t: Token): BOOLEAN;
  VAR e: LONGINT;
BEGIN
  IF At(p, "accDescr") THEN
    e := p + 8; WHILE IsBlank(Ch(e)) DO INC(e) END;
    IF Ch(e) = ":" THEN
      t.a0 := e + 1;
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      t.kind := tAccDescr; t.end := e; t.a1 := e; RETURN TRUE
    END;
    e := p + 8; WHILE IsSpace(Ch(e)) DO INC(e) END;
    IF Ch(e) = "{" THEN
      t.a0 := e + 1;
      WHILE (e < sc.len) & (sc.t[e] # "}") DO INC(e) END;
      IF e < sc.len THEN t.kind := tAccDescr; t.a1 := e; t.end := e + 1; RETURN TRUE END
    END;
    RETURN FALSE
  ELSIF At(p, "accTitle") THEN
    e := p + 8; WHILE IsBlank(Ch(e)) DO INC(e) END;
    IF Ch(e) = ":" THEN
      t.a0 := e + 1;
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      t.kind := tAccTitle; t.end := e; t.a1 := e; RETURN TRUE
    END;
    RETURN FALSE
  ELSIF At(p, "title") THEN
    e := p + 5; t.kind := tTitle; t.a0 := e; t.a1 := e;
    IF IsBlank(Ch(e)) THEN
      INC(e); t.a0 := e;
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) & ~At(e, "%%") DO INC(e) END;
      t.a1 := e
    ELSIF IsWord(Ch(e)) OR (Ch(e) = "-") THEN t.a1 := -1
    END;
    t.end := e; RETURN TRUE
  END;
  RETURN FALSE
END AccOrTitle;

(* The end of the id at p, or p if none *)
PROCEDURE IdEnd(p: LONGINT): LONGINT;
  VAR e: LONGINT;
BEGIN
  IF ~IsWord(Ch(p)) THEN RETURN p END;
  e := p + 1;
  WHILE IsWord(Ch(e)) OR (Ch(e) = "-") DO INC(e) END;
  WHILE Ch(e - 1) = "-" DO DEC(e) END;
  RETURN e
END IdEnd;

(* Keyword w at p, kind kind, unless an id goes on past it *)
PROCEDURE Keyword(p: LONGINT; w: ARRAY OF CHAR; kind: INTEGER; VAR t: Token): BOOLEAN;
  VAR e: LONGINT;
BEGIN
  IF ~At(p, w) THEN RETURN FALSE END;
  e := p + L.Length(w);
  IF IdEnd(p) > e THEN RETURN FALSE END;
  t.kind := kind; t.end := e;
  RETURN TRUE
END Keyword;

(* The end of the quoted string at p, or -1 *)
PROCEDURE StringEnd(p: LONGINT): LONGINT;
  VAR q: CHAR; e: LONGINT;
BEGIN
  q := sc.t[p]; e := p + 1;
  WHILE (e < sc.len) & (sc.t[e] # q) DO
    IF (sc.t[e] = "\") & (e + 1 < sc.len) & ~IsLineEnd(sc.t[e + 1]) THEN INC(e) END;
    INC(e)
  END;
  IF e < sc.len THEN RETURN e + 1 END;
  RETURN -1
END StringEnd;

(* The token at p, after what is skipped *)
PROCEDURE Lex(p: LONGINT; VAR t: Token);
  VAR ch: CHAR; e: LONGINT;
BEGIN
  p := Hidden(p);
  t.start := p; t.a0 := -1; t.a1 := -1;
  IF p >= sc.len THEN t.kind := tEOF; t.end := p; RETURN END;
  ch := sc.t[p];
  IF Keyword(p, "architecture-beta", tKeyword, t) OR Keyword(p, "junction", tJunction, t)
    OR Keyword(p, "service", tService, t) OR Keyword(p, "column", tColumn, t)
    OR Keyword(p, "group", tGroup, t) OR Keyword(p, "align", tAlign, t)
    OR Keyword(p, "row", tRow, t) OR Keyword(p, "in", tIn, t)
  THEN (* done *)
  ELSIF At(p, "--") THEN t.kind := tDashDash; t.end := p + 2
  ELSIF ch = "-" THEN t.kind := tDash; t.end := p + 1
  ELSIF ch = ":" THEN t.kind := tColon; t.end := p + 1
  ELSIF (ch = "L") OR (ch = "R") OR (ch = "T") OR (ch = "B") THEN t.kind := tDir; t.end := p + 1
  ELSIF At(p, "{group}") THEN t.kind := tArrowGroup; t.end := p + 7
  ELSIF (ch = "<") OR (ch = ">") THEN t.kind := tInto; t.end := p + 1
  ELSIF AccOrTitle(p, t) THEN (* done *)
  ELSIF (ch = '"') OR (ch = "'") THEN
    e := StringEnd(p);
    IF e > 0 THEN t.kind := tString; t.end := e ELSE t.kind := tError; t.end := p + 1 END
  ELSIF IsWord(ch) THEN t.kind := tId; t.end := IdEnd(p)
  ELSIF ch = LF THEN t.kind := tNewline; t.end := p + 1
  ELSIF (ch = CR) & (Ch(p + 1) = LF) THEN t.kind := tNewline; t.end := p + 2
  ELSIF ch = "(" THEN
    e := p + 1;
    WHILE IsWord(Ch(e)) OR (Ch(e) = "-") OR (Ch(e) = ":") DO INC(e) END;
    IF (e > p + 1) & (Ch(e) = ")") THEN t.kind := tIcon; t.end := e + 1
    ELSE t.kind := tError; t.end := p + 1
    END
  ELSIF ch = "[" THEN
    t.kind := tError; t.end := p + 1;
    IF (Ch(p + 1) = '"') OR (Ch(p + 1) = "'") THEN
      e := StringEnd(p + 1);
      IF (e > 0) & (Ch(e) = "]") THEN t.kind := tArchTitle; t.end := e + 1 END
    END;
    IF t.kind = tError THEN
      e := p + 1;
      WHILE (e < sc.len) & (sc.t[e] # "[") & (sc.t[e] # "]") & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      IF (e > p + 1) & (Ch(e) = "]") THEN t.kind := tArchTitle; t.end := e + 1 END
    END
  ELSE t.kind := tError; t.end := p + 1
  END
END Lex;

(* Fails at t, which is not what was expected, what *)
PROCEDURE Unexpected(VAR t: Token; what: ARRAY OF CHAR);
  VAR n: LONGINT;
BEGIN
  n := 0; PutS(n, "expected "); PutS(n, what);
  CASE t.kind OF
    tEOF: PutS(n, ", not the end")
  | tNewline: PutS(n, ", not the end of the line")
  ELSE
    PutS(n, ", not '");
    IF t.end - t.start > 40 THEN PutText(n, t.start, t.start + 40); PutS(n, "...")
    ELSE PutText(n, t.start, t.end)
    END;
    Put(n, "'");
    IF (t.kind = tDir) & (IsWord(Ch(t.end)) OR (Ch(t.end) = "-")) THEN
      PutS(n, ": Mermaid reads a capital L, R, T or B as a side, even at the start of an id")
    ELSIF (t.kind = tTitle) & (t.a1 < 0) THEN
      PutS(n, ": Mermaid reads 'title' as a title, even at the start of an id")
    END
  END;
  Fail(t.start, n)
END Unexpected;

(* The line's end, or the text's, after a statement or a title *)
PROCEDURE Eol(VAR p: LONGINT);
  VAR t: Token;
BEGIN
  Lex(p, t);
  IF (t.kind # tNewline) & (t.kind # tEOF) THEN Unexpected(t, "the end of the line") END;
  p := t.end
END Eol;

(* Values *)

PROCEDURE IsTrim(ch: CHAR): BOOLEAN;
BEGIN
  RETURN IsSpace(ch) OR (ch = 0A0X)
END IsTrim;

(* The text from a to b, trimmed, its runs of blanks made one blank *)
PROCEDURE Collapsed(a, b: LONGINT): Str;
  VAR n: LONGINT;
BEGIN
  WHILE (a < b) & IsSpace(sc.t[a]) DO INC(a) END;
  WHILE (b > a) & IsSpace(sc.t[b - 1]) DO DEC(b) END;
  n := 0;
  WHILE a < b DO
    IF IsBlank(sc.t[a]) THEN
      Put(n, " "); WHILE (a < b) & IsBlank(sc.t[a]) DO INC(a) END
    ELSE Put(n, sc.t[a]); INC(a)
    END
  END;
  buf[n] := 0X;
  RETURN L.Sub(buf^, 0, n)
END Collapsed;

(* An id token's text *)
PROCEDURE Id(VAR t: Token): Str;
BEGIN
  RETURN L.Sub(sc.t^, t.start, t.end - t.start)
END Id;

(* An icon token's name, without its parentheses *)
PROCEDURE Icon(VAR t: Token): Str;
BEGIN
  RETURN L.Sub(sc.t^, t.start + 1, t.end - t.start - 2)
END Icon;

(* A string token's text, without its quotation marks, its escapes
   undone ("\n", "\t" and the like are blanks, as in an SVG text) *)
PROCEDURE StringText(VAR t: Token; VAR text: Str; VAR lab: F.Label);
  VAR n, k: LONGINT; ch: CHAR;
BEGIN
  n := 0; k := t.start + 1;
  WHILE k < t.end - 1 DO
    ch := sc.t[k];
    IF ch = "\" THEN
      INC(k); ch := sc.t[k];
      IF (ch = "b") OR (ch = "f") OR (ch = "n") OR (ch = "r") OR (ch = "t") OR (ch = "v")
        OR (ch = "0")
      THEN ch := " "
      END
    END;
    IF IsSpace(ch) THEN ch := " " END;
    Put(n, ch); INC(k)
  END;
  buf[n] := 0X;
  text := L.Sub(buf^, 0, n);
  lab := F.TextLabel(buf^, 0, n)
END StringText;

(* A title token's text: without its brackets, trimmed, and, if in
   quotation marks, without them, \" and \' undone, and trimmed
   again; a markdown label *)
PROCEDURE TitleText(VAR t: Token; VAR text: Str; VAR lab: F.Label);
  VAR a, b, n: LONGINT; q: CHAR;
BEGIN
  a := t.start + 1; b := t.end - 1;
  WHILE (a < b) & IsTrim(sc.t[a]) DO INC(a) END;
  WHILE (b > a) & IsTrim(sc.t[b - 1]) DO DEC(b) END;
  n := 0;
  IF (b - a >= 2) & ((sc.t[a] = '"') OR (sc.t[a] = "'")) & (sc.t[b - 1] = sc.t[a]) THEN
    q := sc.t[a]; INC(a); DEC(b);
    WHILE a < b DO
      IF (sc.t[a] = "\") & (a + 1 < b) & ((sc.t[a + 1] = '"') OR (sc.t[a + 1] = "'")) THEN INC(a) END;
      Put(n, sc.t[a]); INC(a)
    END;
    a := 0; b := n;
    WHILE (a < b) & IsTrim(buf[a]) DO INC(a) END;
    WHILE (b > a) & IsTrim(buf[b - 1]) DO DEC(b) END;
    buf[b] := 0X;
    text := L.Sub(buf^, a, b - a)
  ELSE text := L.Sub(sc.t^, a, b - a)
  END;
  lab := F.MarkdownLabel(text^, 0, L.Length(text^))
END TitleText;

(* The statements *)

(* "in parent" and the line's end *)
PROCEDURE InEol(VAR p: LONGINT; VAR in: Str; label: BOOLEAN);
  VAR t: Token;
BEGIN
  Lex(p, t);
  IF t.kind = tIn THEN
    Lex(t.end, t);
    IF t.kind # tId THEN Unexpected(t, "a group's id") END;
    in := Id(t); p := t.end
  END;
  Lex(p, t);
  IF (t.kind # tNewline) & (t.kind # tEOF) THEN
    IF label THEN Unexpected(t, "a title in brackets, 'in' or the end of the line")
    ELSE Unexpected(t, "'in' or the end of the line")
    END
  END;
  p := t.end
END InEol;

PROCEDURE ReadGroup(VAR p: LONGINT);
  VAR t: Token; gr: Group;
BEGIN
  NEW(gr); gr.icon := NIL; gr.in := NIL; gr.title := NIL; gr.titleText := NIL;
  gr.parent := NIL; gr.next := NIL; gr.depth := 0;
  Lex(p, t); gr.pos := t.start;
  Lex(t.end, t);
  IF t.kind # tId THEN Unexpected(t, "a group's id") END;
  gr.id := Id(t); p := t.end;
  Lex(p, t);
  IF t.kind = tIcon THEN gr.icon := Icon(t); p := t.end; Lex(p, t) END;
  IF t.kind = tArchTitle THEN TitleText(t, gr.titleText, gr.title); p := t.end END;
  InEol(p, gr.in, gr.title = NIL);
  IF groups = NIL THEN groups := gr ELSE lastGroup.next := gr END;
  lastGroup := gr
END ReadGroup;

PROCEDURE NewNode(pos: LONGINT; junction: BOOLEAN): Node;
  VAR n: Node;
BEGIN
  NEW(n); n.pos := pos; n.junction := junction;
  n.icon := NIL; n.in := NIL; n.iconText := NIL; n.iconLabel := NIL;
  n.title := NIL; n.titleText := NIL; n.parent := NIL; n.next := NIL;
  n.adj := NIL; n.lastAdj := NIL; n.map := -1; n.gx := 0; n.gy := 0;
  RETURN n
END NewNode;

PROCEDURE ReadService(VAR p: LONGINT);
  VAR t: Token; n: Node;
BEGIN
  Lex(p, t); n := NewNode(t.start, FALSE);
  Lex(t.end, t);
  IF t.kind # tId THEN Unexpected(t, "a service's id") END;
  n.id := Id(t); p := t.end;
  Lex(p, t);
  IF t.kind = tString THEN StringText(t, n.iconText, n.iconLabel); p := t.end; Lex(p, t)
  ELSIF t.kind = tIcon THEN n.icon := Icon(t); p := t.end; Lex(p, t)
  END;
  IF t.kind = tArchTitle THEN TitleText(t, n.titleText, n.title); p := t.end END;
  InEol(p, n.in, n.title = NIL);
  IF services = NIL THEN services := n ELSE lastService.next := n END;
  lastService := n
END ReadService;

PROCEDURE ReadJunction(VAR p: LONGINT);
  VAR t: Token; n: Node;
BEGIN
  Lex(p, t); n := NewNode(t.start, TRUE);
  Lex(t.end, t);
  IF t.kind # tId THEN Unexpected(t, "a junction's id") END;
  n.id := Id(t); p := t.end;
  InEol(p, n.in, FALSE);
  IF junctions = NIL THEN junctions := n ELSE lastJunction.next := n END;
  lastJunction := n
END ReadJunction;

(* An edge's side, at p *)
PROCEDURE Side(VAR p: LONGINT): CHAR;
  VAR t: Token;
BEGIN
  Lex(p, t);
  IF t.kind # tDir THEN Unexpected(t, "a side, L, R, T or B") END;
  p := t.end;
  RETURN sc.t[t.start]
END Side;

PROCEDURE Colon(VAR p: LONGINT);
  VAR t: Token;
BEGIN
  Lex(p, t);
  IF t.kind # tColon THEN Unexpected(t, "':'") END;
  p := t.end
END Colon;

PROCEDURE ReadEdge(VAR p: LONGINT);
  VAR t: Token; e: Edge;
BEGIN
  NEW(e); e.title := NIL; e.titleText := NIL; e.next := NIL;
  e.lhsInto := FALSE; e.rhsInto := FALSE; e.lhsGroup := FALSE; e.rhsGroup := FALSE;
  e.lhs := NIL; e.rhs := NIL;
  Lex(p, t); e.pos := t.start; e.lhsId := Id(t); p := t.end;
  Lex(p, t);
  IF t.kind = tArrowGroup THEN e.lhsGroup := TRUE; p := t.end END;
  Colon(p);
  e.lhsDir := Side(p);
  Lex(p, t);
  IF t.kind = tInto THEN e.lhsInto := TRUE; p := t.end; Lex(p, t) END;
  IF t.kind = tDashDash THEN p := t.end
  ELSIF t.kind = tDash THEN
    Lex(t.end, t);
    IF t.kind # tArchTitle THEN Unexpected(t, "a title in brackets") END;
    TitleText(t, e.titleText, e.title);
    Lex(t.end, t);
    IF t.kind # tDash THEN Unexpected(t, "'-'") END;
    p := t.end
  ELSE Unexpected(t, "'--' or '-'")
  END;
  Lex(p, t);
  IF t.kind = tInto THEN e.rhsInto := TRUE; p := t.end END;
  e.rhsDir := Side(p);
  Colon(p);
  Lex(p, t);
  IF t.kind # tId THEN Unexpected(t, "an id") END;
  e.rhsId := Id(t); p := t.end;
  Lex(p, t);
  IF t.kind = tArrowGroup THEN e.rhsGroup := TRUE; p := t.end END;
  Eol(p);
  IF edges = NIL THEN edges := e ELSE lastEdge.next := e END;
  lastEdge := e
END ReadEdge;

PROCEDURE ReadAlign(VAR p: LONGINT);
  VAR t: Token; a: Align; k: LONGINT; ids: Strs; at: Ints;
BEGIN
  NEW(a); a.next := NIL; a.n := 0; a.members := NIL;
  NEW(a.ids, 4); NEW(a.at, 4);
  Lex(p, t); a.pos := t.start;
  Lex(t.end, t);
  IF t.kind = tRow THEN a.column := FALSE
  ELSIF t.kind = tColumn THEN a.column := TRUE
  ELSE Unexpected(t, "'row' or 'column'")
  END;
  p := t.end;
  LOOP
    Lex(p, t);
    IF t.kind = tId THEN
      IF a.n = LEN(a.ids^) THEN
        NEW(ids, 2 * a.n); NEW(at, 2 * a.n);
        FOR k := 0 TO a.n - 1 DO ids[k] := a.ids[k]; at[k] := a.at[k] END;
        a.ids := ids; a.at := at
      END;
      a.ids[a.n] := Id(t); a.at[a.n] := t.start; INC(a.n); p := t.end
    ELSIF (a.n >= 2) & ((t.kind = tNewline) OR (t.kind = tEOF)) THEN p := t.end; EXIT
    ELSIF a.n >= 2 THEN Unexpected(t, "an id or the end of the line")
    ELSE Unexpected(t, "an id")
    END
  END;
  IF aligns = NIL THEN aligns := a ELSE lastAlign.next := a END;
  lastAlign := a
END ReadAlign;

(* The model *)

PROCEDURE FindGroup(id: Str): Group;
  VAR gr: Group;
BEGIN
  gr := d.groups;
  WHILE (gr # NIL) & ~L.Equal(gr.id, id) DO gr := gr.next END;
  RETURN gr
END FindGroup;

PROCEDURE FindNode(id: Str): Node;
  VAR n: Node;
BEGIN
  n := d.nodes;
  WHILE (n # NIL) & ~L.Equal(n.id, id) DO n := n.next END;
  RETURN n
END FindNode;

(* Fails, at at, for id, of kind what, already in use or its parent
   in not right *)
PROCEDURE CheckNew(at: LONGINT; what: ARRAY OF CHAR; id, in: Str; VAR parent: Group);
  VAR n: LONGINT;
BEGIN
  n := 0;
  IF FindNode(id) # NIL THEN
    PutS(n, "The "); PutS(n, what); PutS(n, " id ["); PutStr(n, id);
    PutS(n, "] is already in use by another node"); Fail(at, n)
  ELSIF FindGroup(id) # NIL THEN
    PutS(n, "The "); PutS(n, what); PutS(n, " id ["); PutStr(n, id);
    PutS(n, "] is already in use by another group"); Fail(at, n)
  END;
  parent := NIL;
  IF in # NIL THEN
    IF L.Equal(id, in) THEN
      PutS(n, "The "); PutS(n, what); PutS(n, " ["); PutStr(n, id);
      PutS(n, "] cannot be placed within itself"); Fail(at, n)
    END;
    parent := FindGroup(in);
    IF parent = NIL THEN
      PutS(n, "The "); PutS(n, what); PutS(n, " ["); PutStr(n, id);
      IF FindNode(in) # NIL THEN PutS(n, "]'s parent is not a group")
      ELSE
        PutS(n, "]'s parent does not exist. Please make sure the parent is created before this ");
        PutS(n, what)
      END;
      Fail(at, n)
    END
  END
END CheckNew;

PROCEDURE AddNode(n: Node; what: ARRAY OF CHAR);
BEGIN
  CheckNew(n.pos, what, n.id, n.in, n.parent);
  n.index := d.nNodes; INC(d.nNodes); n.next := NIL;
  IF d.nodes = NIL THEN d.nodes := n ELSE d.lastNode.next := n END;
  d.lastNode := n
END AddNode;

(* The node an edge's end names, side side ("left" or "right") *)
PROCEDURE EdgeEnd(e: Edge; id: Str; side: ARRAY OF CHAR): Node;
  VAR n: Node; k: LONGINT;
BEGIN
  n := FindNode(id); k := 0;
  IF n = NIL THEN
    PutS(k, "The "); PutS(k, side); PutS(k, "-hand id ["); PutStr(k, id);
    IF FindGroup(id) # NIL THEN
      PutS(k, "] is a group: an edge must join services or junctions (Mermaid fails here)")
    ELSE
      PutS(k, "] does not yet exist. Please create the service/group before declaring an edge to it.")
    END;
    Fail(e.pos, k)
  END;
  RETURN n
END EdgeEnd;

PROCEDURE AddAdj(n: Node; a, b: CHAR; other: Node);
  VAR j: Adj;
BEGIN
  IF (a = b) OR (n = NIL) THEN RETURN END;  (* LL, RR, TT and BB are no pair *)
  j := n.adj;
  WHILE (j # NIL) & ((j.pair[0] # a) OR (j.pair[1] # b)) DO j := j.next END;
  IF j = NIL THEN
    NEW(j); j.pair[0] := a; j.pair[1] := b; j.pair[2] := 0X; j.next := NIL;
    IF n.adj = NIL THEN n.adj := j ELSE n.lastAdj.next := j END;
    n.lastAdj := j
  END;
  j.other := other.index
END AddAdj;

PROCEDURE AddEdge(e: Edge);
  VAR n: LONGINT;
BEGIN
  IF (e.lhsDir # "L") & (e.lhsDir # "R") & (e.lhsDir # "T") & (e.lhsDir # "B") THEN HALT(100) END;
  e.lhs := EdgeEnd(e, e.lhsId, "left");
  e.rhs := EdgeEnd(e, e.rhsId, "right");
  n := 0;
  IF (e.lhs.parent # NIL) & (e.lhs.parent = e.rhs.parent) THEN
    IF e.lhsGroup THEN
      PutS(n, "The left-hand id ["); PutStr(n, e.lhsId);
      PutS(n, "] is modified to traverse the group boundary, but the edge does not pass through two groups.");
      Fail(e.pos, n)
    ELSIF e.rhsGroup THEN
      PutS(n, "The right-hand id ["); PutStr(n, e.rhsId);
      PutS(n, "] is modified to traverse the group boundary, but the edge does not pass through two groups.");
      Fail(e.pos, n)
    END
  END;
  e.next := NIL;
  IF d.edges = NIL THEN d.edges := e ELSE d.lastEdge.next := e END;
  d.lastEdge := e; INC(d.nEdges)
END AddEdge;

PROCEDURE AddAlign(a: Align);
  VAR k, j, n: LONGINT; m: Node;
BEGIN
  n := 0;
  IF a.n < 2 THEN
    PutS(n, "An align directive requires at least two members; got "); PutInt(n, a.n);
    Fail(a.pos, n)
  END;
  NEW(a.members, a.n);
  FOR k := 0 TO a.n - 1 DO
    m := FindNode(a.ids[k]);
    IF m = NIL THEN
      PutS(n, "align ");
      IF a.column THEN PutS(n, "column") ELSE PutS(n, "row") END;
      PutS(n, " references ["); PutStr(n, a.ids[k]);
      PutS(n, "], which is not a service or junction"); Fail(a.at[k], n)
    END;
    FOR j := 0 TO k - 1 DO
      IF a.members[j] = m THEN
        PutS(n, "align ");
        IF a.column THEN PutS(n, "column") ELSE PutS(n, "row") END;
        PutS(n, " lists ["); PutStr(n, a.ids[k]); PutS(n, "] more than once"); Fail(a.at[k], n)
      END
    END;
    a.members[k] := m
  END;
  a.next := NIL;
  IF d.aligns = NIL THEN d.aligns := a ELSE d.lastAlign.next := a END;
  d.lastAlign := a
END AddAlign;

(* The model filled, as populateDb fills it *)
PROCEDURE Populate;
  VAR gr, nextGr: Group; n, nextN: Node; e, nextE: Edge; a, nextA: Align; p: Group;
BEGIN
  gr := groups;
  WHILE gr # NIL DO
    nextGr := gr.next;
    CheckNew(gr.pos, "group", gr.id, gr.in, gr.parent);
    gr.index := d.nGroups; INC(d.nGroups); gr.next := NIL;
    p := gr.parent; gr.depth := 0; WHILE p # NIL DO INC(gr.depth); p := p.parent END;
    IF d.groups = NIL THEN d.groups := gr ELSE d.lastGroup.next := gr END;
    d.lastGroup := gr;
    gr := nextGr
  END;
  n := services;
  WHILE n # NIL DO nextN := n.next; AddNode(n, "service"); n := nextN END;
  n := junctions;
  WHILE n # NIL DO nextN := n.next; AddNode(n, "junction"); n := nextN END;
  e := edges;
  WHILE e # NIL DO nextE := e.next; AddEdge(e); e := nextE END;
  a := aligns;
  WHILE a # NIL DO nextA := a.next; AddAlign(a); a := nextA END;
  (* the empty groups *)
  gr := d.groups; WHILE gr # NIL DO gr.empty := TRUE; gr := gr.next END;
  n := d.nodes;
  WHILE n # NIL DO
    p := n.parent; WHILE p # NIL DO p.empty := FALSE; p := p.parent END;
    n := n.next
  END;
  gr := d.groups;
  WHILE gr # NIL DO
    IF gr.empty THEN Warn(gr.pos, "this group has no service or junction in it, and is not drawn") END;
    gr := gr.next
  END
END Populate;

(* The grids, as getDataStructures makes them *)

(* (x, y) moved by pair *)
PROCEDURE Shift(VAR pair: ARRAY OF CHAR; VAR x, y: LONGINT);
  VAR a, b: CHAR;
BEGIN
  a := pair[0]; b := pair[1];
  IF (a = "L") OR (a = "R") THEN
    IF a = "L" THEN DEC(x) ELSE INC(x) END;
    IF b = "T" THEN INC(y) ELSIF b = "B" THEN DEC(y) END
  ELSE
    IF b = "L" THEN INC(x) ELSIF b = "R" THEN DEC(x) END;
    IF a = "T" THEN INC(y) ELSE DEC(y) END
  END
END Shift;

PROCEDURE Place;
  VAR n: Node; e: Edge; j: Adj; k, head, tail: LONGINT; x, y: LONGINT;
    queue, q2: POINTER TO ARRAY OF LONGINT; visited: POINTER TO ARRAY OF BOOLEAN;
    m: Node;
BEGIN
  NEW(d.byIndex, d.nNodes + 1);
  n := d.nodes; WHILE n # NIL DO d.byIndex[n.index] := n; n := n.next END;
  (* each node's edges, in the order added *)
  n := d.nodes;
  WHILE n # NIL DO
    e := d.edges;
    WHILE e # NIL DO
      IF e.lhs = n THEN AddAdj(n, e.lhsDir, e.rhsDir, e.rhs)
      ELSIF e.rhs = n THEN AddAdj(n, e.rhsDir, e.lhsDir, e.lhs)
      END;
      IF (e.lhs = n) & (e.rhs = n) THEN AddAdj(n, e.lhsDir, e.rhsDir, e.rhs) END;
      e := e.next
    END;
    n := n.next
  END;
  NEW(visited, d.nNodes + 1); FOR k := 0 TO d.nNodes - 1 DO visited[k] := FALSE END;
  NEW(queue, d.nNodes + 16);
  d.nMaps := 0; n := d.nodes;
  WHILE n # NIL DO
    IF ~visited[n.index] THEN
      n.map := d.nMaps; n.gx := 0; n.gy := 0;
      head := 0; tail := 0; queue[tail] := n.index; INC(tail);
      WHILE head < tail DO
        m := d.byIndex[queue[head]]; INC(head);
        visited[m.index] := TRUE;
        x := m.gx; y := m.gy;
        j := m.adj;
        WHILE j # NIL DO
          IF ~visited[j.other] THEN
            k := j.other;
            d.byIndex[k].map := d.nMaps; d.byIndex[k].gx := x; d.byIndex[k].gy := y;
            Shift(j.pair, d.byIndex[k].gx, d.byIndex[k].gy);
            IF tail = LEN(queue^) THEN
              NEW(q2, 2 * tail);
              FOR k := head TO tail - 1 DO q2[k - head] := queue[k] END;
              tail := tail - head; head := 0; queue := q2;
              k := j.other
            END;
            queue[tail] := k; INC(tail)
          END;
          j := j.next
        END
      END;
      INC(d.nMaps)
    END;
    n := n.next
  END
END Place;

(* The configuration *)

(* config.architecture.name, a number, or default *)
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
  IF ~digits OR (s[i] # 0X) OR neg THEN RETURN default END;
  RETURN x
END Conf;

PROCEDURE Configure;
BEGIN
  d.padding := Conf("config.architecture.padding", 40);
  IF d.padding > 1000 THEN d.padding := 40 END;
  d.iconSize := Conf("config.architecture.iconSize", 80);
  IF (d.iconSize < 1) OR (d.iconSize > 1000) THEN d.iconSize := 80 END;
  d.fontSize := Conf("config.architecture.fontSize", 16);
  IF (d.fontSize < 1) OR (d.fontSize > 200) THEN d.fontSize := 16 END
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "architecture" *)
PROCEDURE IsArch*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("architecture");
  s.pos := save;
  RETURN r
END IsArch;

(* Reads the architecture diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR p: LONGINT; t: Token;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Architecture, d.g); sc := s;
  d.title := NIL; d.accTitle := NIL; d.accDescr := NIL;
  d.groups := NIL; d.nodes := NIL; d.edges := NIL; d.aligns := NIL;
  d.nGroups := 0; d.nNodes := 0; d.nEdges := 0; d.nMaps := 0;
  groups := NIL; services := NIL; junctions := NIL; edges := NIL; aligns := NIL;
  Configure;
  p := sc.pos;
  REPEAT Lex(p, t); p := t.end UNTIL t.kind # tNewline;
  IF t.kind # tKeyword THEN Unexpected(t, "architecture-beta") END;
  LOOP
    Lex(p, t);
    CASE t.kind OF
      tEOF: EXIT
    | tNewline: p := t.end
    | tTitle:
        IF t.a1 < 0 THEN
          Unexpected(t, "a group, a service, a junction, an edge, 'align', a title or the end of the line")
        END;
        d.title := Collapsed(t.a0, t.a1);
        p := t.end; Eol(p)
    | tAccTitle: d.accTitle := Collapsed(t.a0, t.a1); p := t.end; Eol(p)
    | tAccDescr: d.accDescr := Collapsed(t.a0, t.a1); p := t.end; Eol(p)
    | tGroup: ReadGroup(p)
    | tService: ReadService(p)
    | tJunction: ReadJunction(p)
    | tAlign: ReadAlign(p)
    | tId: ReadEdge(p)
    ELSE Unexpected(t, "a group, a service, a junction, an edge, 'align', a title or the end of the line")
    END
  END;
  Populate;
  Place;
  groups := NIL; services := NIL; junctions := NIL; edges := NIL; aligns := NIL;
  lastGroup := NIL; lastService := NIL; lastJunction := NIL; lastEdge := NIL; lastAlign := NIL;
  sc.pos := sc.len
END Read;

BEGIN
  NEW(buf, 256)
END PmArch.
