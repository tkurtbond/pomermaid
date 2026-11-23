MODULE PmKanban;
(* PmKanban: Mermaid's kanban diagrams (`kanban`), read into a list of
   nodes, the board's sections (its columns) and their items (its
   cards), each with its label, shape, indentation and metadata, and
   the configuration.

   The reader follows Mermaid 12.3.0's grammar,
   packages/mermaid/src/diagrams/kanban/parser/kanban.jison, its
   lexer's rules tried in its order, the first that matches taken, and
   what kanbanDb.ts, its db, makes of them:

   - the diagram starts with "kanban", in any case;
   - each node is on a line of its own, indented; its level is the
     number of blanks before it (a tab is one);
   - the first node is a section, and so is every node indented as it
     is; any other node is an item of the last section before it; a
     node indented less than the first is an error, found when the
     next node is read, "Items without section detected";
   - a node is a text, its id and its label, or an id, which may be
     left out, and its label between delimiters, the mindmap's: "[...]",
     "(...)", "((...))", ")...(", "))...((", "{{...}}"; the label may be
     in quotation marks, "`...`" in them a markdown string; it is
     markdown, bold and italic kept; "[...]", "(...)" and "{{...}}"
     double the node's padding;
   - "@{ ... }" right after a node is its metadata, YAML: label,
     ticket, assigned, priority and icon; a shape not in lower case, or
     with "_", is an error;
   - "::icon(...)" and ":::class ..." on a line of their own decorate
     the node before them; Mermaid draws neither, nor the metadata's
     icon, and pomermaid reads them and draws none;
   - with config.kanban.ticketBaseUrl, Mermaid makes each ticket a
     link; pomermaid does not, and warns (decision 54);
   - "%%" begins a comment, to the end of its line. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml, X := PmXy;

CONST
  (* shapes, kanbanDb.ts's numbers *)
  Default* = 0; Rounded* = 1; Rect* = 2; Circle* = 3; Cloud* = 4; Bang* = 5; Hexagon* = 6;

  (* tokens *)
  tEOF = 0; tNL = 1; tSpaceLine = 2; tSpaceList = 3; tKanban = 4; tClass = 5; tIcon = 6;
  tId = 7; tStart = 8; tShape = 9;

  LF = 0AX;

TYPE
  Str = L.Str;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    index-: LONGINT;        (* from 0, in order read *)
    id-, descr-: Str;       (* as written, without blanks at either end *)
    label-: F.Label;        (* descr, or the metadata's label, as markdown *)
    shape-: INTEGER;
    level-: LONGINT;        (* its indentation *)
    padding-: LONGREAL;     (* config.mindmap.padding, doubled for some shapes *)
    icon-, class-: Str;     (* or NIL *)
    ticket-, assigned-, priority-: Str;  (* the metadata's, or NIL *)
    ticketAt: LONGINT;      (* where the ticket is *)
    section-: Node;         (* an item's section, NIL for a section *)
    next-: Node             (* the node read after it *)
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;            (* the configuration *)
    nodes-: Node;           (* in order read *)
    nNodes-, nSections-: LONGINT;
    padding-: LONGREAL;     (* config.mindmap.padding, as Mermaid takes it *)
    sectionWidth-: LONGREAL;  (* config.kanban.sectionWidth *)
    ticketBaseUrl-: Str;    (* config.kanban.ticketBaseUrl, or NIL *)
    last: Node              (* the node read last *)
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
PROCEDURE MakeLabel(VAR t: ARRAY OF CHAR; start, end: LONGINT): F.Label;
  VAR n, p, e: LONGINT;
BEGIN
  n := 0; p := start;
  WHILE (p < end) & IsSpace(t[p]) DO INC(p) END;
  WHILE (end > p) & IsSpace(t[end - 1]) DO DEC(end) END;
  WHILE p < end DO
    e := p; WHILE (e < end) & (t[e] # LF) DO INC(e) END;
    WHILE (p < e) & IsSpace(t[p]) DO INC(p) END;
    WHILE (e > p) & IsSpace(t[e - 1]) & (t[e - 1] # LF) DO DEC(e) END;
    WHILE p < e DO Put(n, t[p]); INC(p) END;
    WHILE (p < end) & (t[p] # LF) DO INC(p) END;
    IF p < end THEN Put(n, LF); INC(p) END
  END;
  buf[n] := 0X;
  RETURN F.MarkdownLabel(buf^, 0, n)
END MakeLabel;

(* The lexer, its INITIAL state *)

(* Reads the token at the position; "@{" is left at the position *)
PROCEDURE Next;
  VAR p, q, k: LONGINT; ch: CHAR;
BEGIN
  p := sc.pos; tokStart := p;
  IF p >= sc.len THEN tok := tEOF; tokEnd := p; RETURN END;
  (* "@{" *)
  IF Is(p, "@{") THEN tok := tShape; tokEnd := p + 2; RETURN END;
  (* \s*%%.* *)
  q := p; WHILE IsSpace(At(q)) DO INC(q) END;
  IF Is(q, "%%") THEN
    WHILE (q < sc.len) & (sc.t[q] # LF) DO INC(q) END;
    tok := tSpaceLine; tokEnd := q; sc.pos := q; RETURN
  END;
  (* "kanban", a word *)
  IF IsCaseless(p, "kanban") & ~L.IsWordChar(At(p + 6)) THEN
    tok := tKanban; tokEnd := p + 6; sc.pos := tokEnd; RETURN
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
  (* [^(\[\n){}@]+ *)
  q := p;
  LOOP
    ch := At(q);
    IF (q >= sc.len) OR (ch = "(") OR (ch = "[") OR (ch = LF) OR (ch = ")") OR (ch = "{")
      OR (ch = "}") OR (ch = "@") THEN EXIT
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

(* Whether the value of q is one JavaScript takes as true: not "",
   "false", "0" or "null" *)
PROCEDURE Truthy(q: Y.Pair): BOOLEAN;
BEGIN
  RETURN (q # NIL) & (q.value[0] # 0X) & ~L.Is(q.value, "false") & ~L.Is(q.value, "0")
    & ~L.Is(q.value, "null")
END Truthy;

(* The metadata, meta, of n, at at *)
PROCEDURE Meta(n: Node; meta: Y.Pair);
  VAR q: Y.Pair; i, k: LONGINT; ch: CHAR;
BEGIN
  q := Y.Find(meta, "shape");
  IF Truthy(q) THEN
    i := 0;
    WHILE q.value[i] # 0X DO
      ch := q.value[i];
      IF (ch >= "A") & (ch <= "Z") OR (ch = "_") THEN
        k := 0; PutS(k, "No such shape: "); PutS(k, q.value^);
        PutS(k, ". Shape names should be lowercase."); buf[k] := 0X;
        sc.ErrorAt(q.pos, buf^)
      END;
      INC(i)
    END
  END;
  q := Y.Find(meta, "label");
  IF Truthy(q) THEN
    n.label := MakeLabel(q.value^, 0, L.Length(q.value^)); n.descr := q.value
  END;
  q := Y.Find(meta, "icon");
  IF Truthy(q) THEN n.icon := q.value END;
  q := Y.Find(meta, "assigned"); IF Truthy(q) THEN n.assigned := q.value END;
  q := Y.Find(meta, "ticket"); IF Truthy(q) THEN n.ticket := q.value; n.ticketAt := q.pos END;
  q := Y.Find(meta, "priority"); IF Truthy(q) THEN n.priority := q.value END
END Meta;

(* Adds the node with id, its label t[start .. end-1], of shape shape,
   indented level, with metadata meta (or NIL), at at *)
PROCEDURE AddNode(at, level: LONGINT; id: Str; start, end: LONGINT; shape: INTEGER;
  meta: Y.Pair);
  VAR n, p, last: Node; k: LONGINT;
BEGIN
  NEW(n); n.index := d.nNodes; n.id := id; n.descr := Trimmed(start, end);
  n.label := MakeLabel(sc.t^, start, end); n.shape := shape; n.level := level;
  n.padding := d.padding;
  IF (shape = Rounded) OR (shape = Rect) OR (shape = Hexagon) THEN n.padding := 2 * d.padding END;
  n.icon := NIL; n.class := NIL; n.ticket := NIL; n.assigned := NIL; n.priority := NIL;
  n.section := NIL; n.next := NIL;
  IF meta # NIL THEN Meta(n, meta) END;
  (* kanbanDb.ts's getSection *)
  IF d.nodes # NIL THEN
    p := d.nodes; last := NIL;
    WHILE p # NIL DO
      IF p.level = d.nodes.level THEN last := p END;
      p := p.next
    END;
    (* the error is for the last node indented less than the first *)
    p := d.nodes; k := -1;
    WHILE p # NIL DO
      IF p.level < d.nodes.level THEN k := p.index; last := p END;
      p := p.next
    END;
    IF k >= 0 THEN
      k := 0; PutS(k, 'Items without section detected, found section ("');
      PutS(k, last.descr^); PutS(k, '")'); buf[k] := 0X;
      sc.ErrorAt(at, buf^)
    END;
    IF level # d.nodes.level THEN n.section := last END
  END;
  IF n.section = NIL THEN INC(d.nSections) END;
  IF d.last = NIL THEN d.nodes := n ELSE d.last.next := n END;
  d.last := n; INC(d.nNodes)
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
  IF icon THEN d.last.icon := s ELSE d.last.class := s END
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

(* The metadata at the token, "@{ ... }", or NIL *)
PROCEDURE MetaData(): Y.Pair;
  VAR p: LONGINT; inStr: BOOLEAN; ch: CHAR;
BEGIN
  IF tok # tShape THEN RETURN NIL END;
  (* the shapeData state has no rule for "^" outside quotation marks *)
  p := tokEnd; inStr := FALSE;
  LOOP
    ch := At(p);
    IF p >= sc.len THEN EXIT
    ELSIF ch = '"' THEN inStr := ~inStr
    ELSIF ~inStr & (ch = "}") THEN EXIT
    ELSIF ~inStr & (ch = "^") THEN sc.ErrorAt(p, "unexpected ^ in @{ ... }")
    END;
    INC(p)
  END;
  sc.pos := tokStart;
  RETURN F.MetaData()
END MetaData;

(* A node, at the token, an id or a start, indented level *)
PROCEDURE NodeStmt(level: LONGINT);
  VAR at, start, end, idStart, idEnd: LONGINT; id, open, close: Str;
BEGIN
  at := tokStart; id := NIL;
  IF tok = tId THEN
    idStart := tokStart; idEnd := tokEnd; id := Trimmed(idStart, idEnd);
    Next;
    IF tok # tStart THEN
      AddNode(at, level, id, idStart, idEnd, Default, MetaData());
      IF tok = tShape THEN Next END;
      RETURN
    END
  END;
  open := L.Sub(sc.t^, tokStart, tokEnd - tokStart);
  Delimited(start, end, close);
  IF id = NIL THEN id := Trimmed(start, end) END;
  Next;
  AddNode(at, level, id, start, end, Shape(open, close), MetaData());
  IF tok = tShape THEN Next END
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

(* config.name, a number at least least, or default *)
PROCEDURE Num(name: ARRAY OF CHAR; default, least: LONGREAL): LONGREAL;
  VAR q: Y.Pair; x: LONGREAL; i: LONGINT;
BEGIN
  q := Y.Find(d.g.config, name);
  IF q = NIL THEN RETURN default END;
  i := 0;
  WHILE L.IsBlank(q.value[i]) DO INC(i) END;
  IF (q.value[i] = 0X) OR ~X.JsParse(q.value, x) OR (x < least) THEN RETURN default END;
  RETURN x
END Num;

PROCEDURE Configure;
  VAR q: Y.Pair;
BEGIN
  d.padding := Num("config.mindmap.padding", 10, 0);
  d.sectionWidth := Num("config.kanban.sectionWidth", 200, 1);
  q := Y.Find(d.g.config, "config.kanban.ticketBaseUrl");
  IF (q # NIL) & (q.value[0] # 0X) THEN d.ticketBaseUrl := q.value ELSE d.ticketBaseUrl := NIL END
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "kanban", as Mermaid's detector: in this case only *)
PROCEDURE IsKanban*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("kanban");
  s.pos := save;
  RETURN r
END IsKanban;

(* Reads the kanban diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR n: Node;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Kanban, d.g); sc := s;
  d.nodes := NIL; d.nNodes := 0; d.nSections := 0; d.last := NIL;
  Configure;
  Next;
  IF tok # tKanban THEN sc.ErrorAt(tokStart, "expected kanban") END;
  Next;
  IF tok = tNL THEN Next END;
  REPEAT Statement; Stop UNTIL tok = tEOF;
  IF d.ticketBaseUrl # NIL THEN
    n := d.nodes;
    WHILE (n # NIL) & (n.ticket = NIL) DO n := n.next END;
    IF n # NIL THEN Warn(n.ticketAt, "tickets are not made links to ticketBaseUrl") END
  END
END Read;

BEGIN
  NEW(buf, 256)
END PmKanban.
