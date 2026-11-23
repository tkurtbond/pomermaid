MODULE PmMindmap;
(* PmMindmap: Mermaid's mindmaps (`mindmap`), read into a tree of
   nodes, each with its label, shape, level, depth and section, and the
   configuration, config.mindmap.

   The reader follows Mermaid 12.3.0's grammar,
   packages/mermaid/src/diagrams/mindmap/parser/mindmap.jison, its
   lexer's rules tried in its order, the first that matches taken, and
   what mindmapDb.ts, its db, makes of them:

   - the diagram starts with "mindmap", in any case;
   - each node is on a line of its own, indented; its level is the
     number of blanks before it (a tab is one); the first node is the
     root, and its indentation is subtracted from every other's;
   - a node's parent is the last node before it with a smaller level;
     a node with none is an error, "There can be only one root";
   - a node is a text, its id and its label, or an id, which may be
     left out, and its label between delimiters, which give its shape:
     "[...]" a box, "(...)" a rounded box, "((...))" a circle,
     ")...(" a cloud, "))...((" a bang, "{{...}}" a hexagon, and any
     other pair a default node; the label may be in quotation marks,
     "`...`" in them a markdown string, and may span lines; it is
     markdown, bold and italic kept;
   - "::icon(...)" and ":::class ..." on a line of their own decorate
     the node before them; pomermaid reads them, warns and draws
     neither;
   - "%%" begins a comment, to the end of its line, between nodes and
     after a node's closing delimiter; a node written as a text keeps
     a "%%" in it, as Mermaid does.

   The sections are mindmapDb.ts's: the root has none (-1); each of
   its children, in order, has the next of 11, and its descendants
   its; with config.mindmap.colorBy "depth", a node's section is its
   depth less 1, modulo 11. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml, X := PmXy;

CONST
  (* shapes, mindmapDb.ts's numbers *)
  Default* = 0; Rounded* = 1; Rect* = 2; Circle* = 3; Cloud* = 4; Bang* = 5; Hexagon* = 6;
  Sections* = 11;  (* MAX_SECTIONS less 1 *)

  (* tokens *)
  tEOF = 0; tNL = 1; tSpaceLine = 2; tSpaceList = 3; tMindmap = 4; tClass = 5; tIcon = 6;
  tId = 7; tStart = 8;

  LF = 0AX;

TYPE
  Str = L.Str;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    index-: LONGINT;        (* from 0, in order read *)
    id-, descr-: Str;       (* as written, without blanks at either end *)
    label-: F.Label;        (* descr, as markdown *)
    shape-: INTEGER;
    level-: LONGINT;        (* its indentation, less the root's *)
    depth-: LONGINT;        (* from the root, 0 *)
    section-: INTEGER;      (* -1 for the root *)
    icon-, class-: Str;     (* or NIL *)
    parent-, children-, next-: Node;  (* next: the next sibling *)
    nChildren-: LONGINT;
    lastChild, prev: Node   (* prev: the node read before it *)
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;            (* the configuration *)
    root-: Node;
    nNodes-: LONGINT;
    (* config.mindmap *)
    padding-, maxNodeWidth-: LONGREAL;
    byDepth-: BOOLEAN;      (* colorBy: depth *)
    last: Node;             (* the node read last *)
    baseLevel: LONGINT
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  tok: INTEGER;             (* the token *)
  tokStart, tokEnd: LONGINT;  (* its text, t[tokStart .. tokEnd-1] *)
  buf: Str;

(* Strings *)

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

(* Warns about the text at at: "NAME:LINE:COL: a" *)
PROCEDURE Warn(at: LONGINT; a: ARRAY OF CHAR);
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
  PutS(n, a); buf[n] := 0X;
  PmIO.Warn(buf^)
END Warn;

(* Whether ch is JavaScript's \s, as far as pomermaid reads it *)
PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = 09X) OR (ch = LF) OR (ch = 0BX) OR (ch = 0CX) OR (ch = 0DX)
END IsSpace;

(* The character at p, or 0X past the end *)
PROCEDURE At(p: LONGINT): CHAR;
BEGIN
  IF p < sc.len THEN RETURN sc.t[p] ELSE RETURN 0X END
END At;

(* Whether the text at p is w *)
PROCEDURE Is(p: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE w[i] # 0X DO
    IF At(p + i) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END Is;

(* Whether the text at p is w, w in lower case, in any case *)
PROCEDURE IsCaseless(p: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT; ch: CHAR;
BEGIN
  i := 0;
  WHILE w[i] # 0X DO
    ch := At(p + i);
    IF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch) + 32) END;
    IF ch # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END IsCaseless;

(* The text t[start .. end-1], without blanks at either end *)
PROCEDURE Trimmed(start, end: LONGINT): Str;
BEGIN
  WHILE (start < end) & IsSpace(sc.t[start]) DO INC(start) END;
  WHILE (end > start) & IsSpace(sc.t[end - 1]) DO DEC(end) END;
  RETURN L.Sub(sc.t^, start, end - start)
END Trimmed;

(* The label of t[start .. end-1], markdown, each of its lines without
   blanks at either end, as Mermaid's markdown makes them *)
PROCEDURE MakeLabel(start, end: LONGINT): F.Label;
  VAR n, p, e: LONGINT;
BEGIN
  n := 0; p := start;
  WHILE (p < end) & IsSpace(sc.t[p]) DO INC(p) END;
  WHILE (end > p) & IsSpace(sc.t[end - 1]) DO DEC(end) END;
  WHILE p < end DO
    e := p; WHILE (e < end) & (sc.t[e] # LF) DO INC(e) END;
    WHILE (p < e) & IsSpace(sc.t[p]) DO INC(p) END;
    WHILE (e > p) & IsSpace(sc.t[e - 1]) & (sc.t[e - 1] # LF) DO DEC(e) END;
    WHILE p < e DO Put(n, sc.t[p]); INC(p) END;
    WHILE (p < end) & (sc.t[p] # LF) DO INC(p) END;
    IF p < end THEN Put(n, LF); INC(p) END
  END;
  buf[n] := 0X;
  RETURN F.MarkdownLabel(buf^, 0, n)
END MakeLabel;

(* The lexer, its INITIAL state *)

(* Reads the token at the position *)
PROCEDURE Next;
  VAR p, q, k: LONGINT; ch: CHAR;
BEGIN
  p := sc.pos; tokStart := p;
  IF p >= sc.len THEN tok := tEOF; tokEnd := p; RETURN END;
  (* \s*%%.* *)
  q := p; WHILE IsSpace(At(q)) DO INC(q) END;
  IF Is(q, "%%") THEN
    WHILE (q < sc.len) & (sc.t[q] # LF) DO INC(q) END;
    tok := tSpaceLine; tokEnd := q; sc.pos := q; RETURN
  END;
  (* "mindmap", a word *)
  IF IsCaseless(p, "mindmap") & ~L.IsWordChar(At(p + 7)) THEN
    tok := tMindmap; tokEnd := p + 7; sc.pos := tokEnd; RETURN
  END;
  (* ":::" .+ *)
  IF Is(p, ":::") THEN
    q := p + 3; tokStart := q;
    WHILE (q < sc.len) & (sc.t[q] # LF) DO INC(q) END;
    tok := tClass; tokEnd := q; sc.pos := q; RETURN
  END;
  (* "::icon(" [^)]+ ")" *)
  IF IsCaseless(p, "::icon(") THEN
    q := p + 7; tokStart := q;
    WHILE (q < sc.len) & (sc.t[q] # ")") DO INC(q) END;
    IF q >= sc.len THEN sc.ErrorAt(p, "expected ) to end the icon") END;
    tok := tIcon; tokEnd := q; sc.pos := q + 1; RETURN
  END;
  (* [\s]+[\n] *)
  q := p; WHILE IsSpace(At(q)) DO INC(q) END;
  k := q - 1; WHILE (k > p) & (sc.t[k] # LF) DO DEC(k) END;
  IF (k > p) & (sc.t[k] = LF) THEN
    tok := tSpaceLine; tokEnd := k + 1; sc.pos := tokEnd; RETURN
  END;
  (* [\n]+ *)
  IF sc.t[p] = LF THEN
    q := p; WHILE At(q) = LF DO INC(q) END;
    tok := tNL; tokEnd := q; sc.pos := q; RETURN
  END;
  (* the delimiters that start a node *)
  IF Is(p, "-)") OR Is(p, "(-") OR Is(p, "))") OR Is(p, "((") OR Is(p, "{{") THEN
    tok := tStart; tokEnd := p + 2; sc.pos := tokEnd; RETURN
  END;
  IF (sc.t[p] = ")") OR (sc.t[p] = "(") OR (sc.t[p] = "[") THEN
    tok := tStart; tokEnd := p + 1; sc.pos := tokEnd; RETURN
  END;
  (* [\s]+ *)
  IF IsSpace(sc.t[p]) THEN
    q := p; WHILE IsSpace(At(q)) DO INC(q) END;
    tok := tSpaceList; tokEnd := q; sc.pos := q; RETURN
  END;
  (* [^(\[\n){}]+ *)
  q := p;
  LOOP
    ch := At(q);
    IF (q >= sc.len) OR (ch = "(") OR (ch = "[") OR (ch = LF) OR (ch = ")") OR (ch = "{")
      OR (ch = "}") THEN EXIT
    END;
    INC(q)
  END;
  IF q = p THEN sc.ErrorAt(p, "unexpected character") END;
  tok := tId; tokEnd := q; sc.pos := q
END Next;

(* The db *)

(* The type of a node from its delimiters, start and end *)
PROCEDURE Shape(start, end: Str): INTEGER;
BEGIN
  IF L.Is(start, "[") THEN RETURN Rect
  ELSIF L.Is(start, "(") THEN
    IF L.Is(end, ")") THEN RETURN Rounded ELSE RETURN Cloud END
  ELSIF L.Is(start, "((") THEN RETURN Circle
  ELSIF L.Is(start, ")") THEN RETURN Cloud
  ELSIF L.Is(start, "))") THEN RETURN Bang
  ELSIF L.Is(start, "{{") THEN RETURN Hexagon
  END;
  RETURN Default
END Shape;

(* Adds the node with id, its label t[start .. end-1], of shape shape,
   indented level, at at *)
PROCEDURE AddNode(at, level: LONGINT; id: Str; start, end: LONGINT; shape: INTEGER);
  VAR n, p: Node; k: LONGINT;
BEGIN
  NEW(n); n.index := d.nNodes; n.id := id; n.descr := Trimmed(start, end);
  n.label := MakeLabel(start, end); n.shape := shape; n.section := -1;
  n.icon := NIL; n.class := NIL; n.children := NIL; n.lastChild := NIL; n.next := NIL;
  n.nChildren := 0; n.parent := NIL;
  IF d.root = NIL THEN
    d.baseLevel := level; n.level := 0; n.depth := 0; d.root := n
  ELSE
    n.level := level - d.baseLevel;
    p := d.last;
    WHILE (p # NIL) & (p.level >= n.level) DO p := p.prev END;
    IF p = NIL THEN
      k := 0; PutS(k, 'There can be only one root. No parent could be found for ("');
      PutS(k, n.descr^); PutS(k, '")'); buf[k] := 0X;
      sc.ErrorAt(at, buf^)
    END;
    n.parent := p; n.depth := p.depth + 1;
    IF p.lastChild = NIL THEN p.children := n ELSE p.lastChild.next := n END;
    p.lastChild := n; INC(p.nChildren)
  END;
  n.prev := d.last; d.last := n; INC(d.nNodes)
END AddNode;

(* An icon or a class, t[tokStart .. tokEnd-1], for the last node *)
PROCEDURE Decorate(icon: BOOLEAN);
  VAR s: Str;
BEGIN
  IF d.last = NIL THEN
    IF icon THEN sc.ErrorAt(tokStart, "an icon before any node")
    ELSE sc.ErrorAt(tokStart, "a class before any node")
    END
  END;
  s := Trimmed(tokStart, tokEnd);
  IF icon THEN
    d.last.icon := s; Warn(tokStart, "icons are not drawn")
  ELSE
    d.last.class := s; Warn(tokStart, "classes are not drawn")
  END
END Decorate;

(* The parser *)

(* A node's delimited label, its NODE state, after its start: returns
   its text, t[start .. end-1], and the delimiter that ends it, taken *)
PROCEDURE Delimited(VAR start, end: LONGINT; VAR close: Str);
  VAR p, q, at: LONGINT; n: INTEGER; ch: CHAR;
BEGIN
  n := 0; p := sc.pos; at := tokStart;
  LOOP
    IF p >= sc.len THEN sc.ErrorAt(at, "the node's label has no end") END;
    ch := sc.t[p];
    IF Is(p, '"`') THEN
      q := p + 2; WHILE (q < sc.len) & (sc.t[q] # "`") & (sc.t[q] # '"') DO INC(q) END;
      IF ~Is(q, '`"') THEN sc.ErrorAt(p, 'expected `" to end the string') END;
      IF q > p + 2 THEN start := p + 2; end := q; INC(n) END;
      p := q + 2
    ELSIF ch = '"' THEN
      q := p + 1; WHILE (q < sc.len) & (sc.t[q] # '"') DO INC(q) END;
      IF q >= sc.len THEN sc.ErrorAt(p, 'expected " to end the string') END;
      IF q > p + 1 THEN start := p + 1; end := q; INC(n) END;
      p := q + 1
    ELSIF Is(p, "))") OR Is(p, "}}") OR Is(p, "(-") OR Is(p, "-)") OR Is(p, "((") THEN
      close := L.Sub(sc.t^, p, 2); p := p + 2; EXIT
    ELSIF (ch = ")") OR (ch = "]") OR (ch = "(") THEN
      close := L.Sub(sc.t^, p, 1); p := p + 1; EXIT
    ELSIF ch # "}" THEN  (* [^)\](}]+ *)
      q := p;
      WHILE (q < sc.len) & (sc.t[q] # ")") & (sc.t[q] # "]") & (sc.t[q] # "(") & (sc.t[q] # "}") DO
        INC(q)
      END;
      start := p; end := q; INC(n); p := q
    ELSE  (* .+ *)
      q := p; WHILE (q < sc.len) & (sc.t[q] # LF) DO INC(q) END;
      start := p; end := q; INC(n); p := q
    END;
    IF n > 1 THEN sc.ErrorAt(p, "expected the end of the node's label") END
  END;
  IF n = 0 THEN sc.ErrorAt(at, "the node has no label") END;
  sc.pos := p
END Delimited;

(* A node, at the token, an id or a start, indented level *)
PROCEDURE NodeStmt(level: LONGINT);
  VAR at, start, end, idStart, idEnd: LONGINT; id, open, close: Str;
BEGIN
  at := tokStart; id := NIL;
  IF tok = tId THEN
    idStart := tokStart; idEnd := tokEnd; id := Trimmed(idStart, idEnd);
    Next;
    IF tok # tStart THEN AddNode(at, level, id, idStart, idEnd, Default); RETURN END
  END;
  open := L.Sub(sc.t^, tokStart, tokEnd - tokStart);
  Delimited(start, end, close);
  IF id = NIL THEN id := Trimmed(start, end) END;
  AddNode(at, level, id, start, end, Shape(open, close));
  Next
END NodeStmt;

(* A statement, at the token *)
PROCEDURE Statement;
  VAR level: LONGINT;
BEGIN
  IF tok = tSpaceLine THEN Next
  ELSE
    level := 0;
    IF tok = tSpaceList THEN level := tokEnd - tokStart; Next END;
    IF (tok = tId) OR (tok = tStart) THEN NodeStmt(level)
    ELSIF tok = tIcon THEN Decorate(TRUE); Next
    ELSIF tok = tClass THEN Decorate(FALSE); Next
    ELSIF level = 0 THEN sc.ErrorAt(tokStart, "expected a node")
    END
  END
END Statement;

(* The end of a statement: a line end, a comment or the end *)
PROCEDURE Stop;
BEGIN
  IF tok = tSpaceList THEN Next END;  (* blanks at the end, as Mermaid's text ends with a line end *)
  IF (tok # tNL) & (tok # tSpaceLine) & (tok # tEOF) THEN
    sc.ErrorAt(tokStart, "expected the end of the line")
  END;
  IF tok # tEOF THEN Next END;
  WHILE tok = tNL DO Next END
END Stop;

(* Configuration *)

PROCEDURE Strings(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
  VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE a[i] # 0X DO INC(i) END;
  j := 0; WHILE (b[j] # 0X) & (i < LEN(a) - 1) DO a[i] := b[j]; INC(i); INC(j) END;
  a[i] := 0X
END Strings;

(* config.mindmap.name, or NIL *)
PROCEDURE FindConf(name: ARRAY OF CHAR): Y.Pair;
  VAR key: ARRAY 64 OF CHAR;
BEGIN
  key := "config.mindmap."; Strings(key, name);
  RETURN Y.Find(d.g.config, key)
END FindConf;

(* config.mindmap.name, a number at least least, or default *)
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

PROCEDURE Configure;
  VAR q: Y.Pair;
BEGIN
  d.padding := Num("padding", 10, 0);
  d.maxNodeWidth := Num("maxNodeWidth", 200, 1);
  q := FindConf("colorBy");
  d.byDepth := (q # NIL) & L.Is(q.value, "depth")
END Configure;

(* The sections, from n down *)
PROCEDURE Assign(n: Node; section: INTEGER);
  VAR c: Node; k: INTEGER;
BEGIN
  IF n.parent = NIL THEN n.section := -1
  ELSIF d.byDepth THEN n.section := SHORT((n.depth - 1) MOD Sections)
  ELSE n.section := section
  END;
  c := n.children; k := 0;
  WHILE c # NIL DO
    IF n.parent = NIL THEN Assign(c, k MOD Sections) ELSE Assign(c, section) END;
    INC(k); c := c.next
  END
END Assign;

(* Whether the scanner's text, after front matter and comments, starts
   with "mindmap", as Mermaid's detector: in this case only *)
PROCEDURE IsMindmap*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("mindmap");
  s.pos := save;
  RETURN r
END IsMindmap;

(* Reads the mindmap in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Mindmap, d.g); sc := s;
  d.root := NIL; d.nNodes := 0; d.last := NIL; d.baseLevel := 0;
  Configure;
  Next;
  IF tok # tMindmap THEN sc.Error("expected mindmap") END;
  Next;
  IF tok = tNL THEN Next END;
  REPEAT Statement; Stop UNTIL tok = tEOF;
  IF d.root = NIL THEN sc.Error("expected a node") END;
  Assign(d.root, 0)
END Read;

BEGIN
  NEW(buf, 256)
END PmMindmap.
