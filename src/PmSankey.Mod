MODULE PmSankey;
(* PmSankey: Mermaid's sankey diagrams (`sankey-beta`, `sankey`), read
   into a model of their own: the nodes, in the order they first
   appear, each with its name; the links, in order, each a source, a
   target and a value; and the configuration, config.sankey.

   The reader follows Mermaid 12.3.0's grammar, diagrams/sankey/
   parser/sankey.jison, sankeyUtils.ts and what sankeyDB.ts makes of
   it:

   - the diagram starts with "sankey-beta" or "sankey", then a line
     end; front matter and "%%{ ... }%%" directives come before it;
   - each line after it is a record, CSV's, of three fields, a source,
     a target and a value, separated by ","; a line whose first
     character, after blanks, is "%%" is a comment; blank lines are
     skipped;
   - a field is in double quotation marks, where "," and line ends are
     text and "" is a quotation mark, or is anything up to the next
     "," or line end, but a quotation mark; blanks around a field are
     not its own;
   - a node is named by its source or target field, the same name
     the same node;
   - the value is the number at the start of its field, as
     JavaScript's parseFloat reads it.

   Mermaid takes characters only from ASCII, its lexer's CSV text, and
   fails on others; pomermaid takes any. A value that is not a number,
   that is negative, or links that make a cycle (Mermaid's "circular
   link") are errors. *)

IMPORT L := PmLex, F := PmFlow, Y := PmYaml, X := PmXy, S := PmStyle;

CONST
  (* alignments *)
  Justify* = 0; Left* = 1; Right* = 2; Center* = 3;
  (* link colours *)
  Gradient* = 0; Source* = 1; Target* = 2; Fixed* = 3;

TYPE
  Str = L.Str;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    name-: Str;          (* as read, its quotation marks gone *)
    index-: INTEGER;     (* from 0, in order *)
    colour-: LONGINT;    (* nodeColors', or -1 *)
    next-: Node
  END;

  Link* = POINTER TO LinkDesc;
  LinkDesc* = RECORD
    source-, target-: Node;
    value-: LONGREAL;
    index-: INTEGER;
    next-: Link;
    at: LONGINT          (* where its record starts, for an error *)
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;         (* the title and the configuration *)
    nodes-: Node; nNodes-: INTEGER;
    links-: Link; nLinks-: INTEGER;
    (* config.sankey *)
    width-, height-, nodeWidth-, nodePadding-: LONGREAL;
    align-: INTEGER;
    showValues-, outlined-: BOOLEAN;
    prefix-, suffix-: Str;
    linkColor-: INTEGER;
    linkRgb-: LONGINT;   (* Fixed's colour *)
    linkText-: Str;      (* linkColor, as given *)
    lastNode: Node; lastLink: Link
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;

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

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether the text at the position is w, w lower case, in any case *)
PROCEDURE LookingAtCi(w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE w[i] # 0X DO
    IF Lower(sc.Peek(i)) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END LookingAtCi;

(* Skips blank lines and comment lines, leaving the position at the
   start of a record, or at the end *)
PROCEDURE SkipLines;
  VAR start, e: LONGINT;
BEGIN
  LOOP
    start := sc.pos; sc.SkipBlanks;
    IF sc.Ch() = 0AX THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSIF sc.AtEnd() THEN EXIT
    ELSE sc.pos := start; EXIT
    END
  END
END SkipLines;

(* A field: its text, unquoted and trimmed, is left in buf[0 .. n-1] *)
PROCEDURE Field(VAR n: LONGINT);
  VAR ch: CHAR;
BEGIN
  n := 0; sc.SkipBlanks;
  IF sc.Ch() = '"' THEN
    INC(sc.pos);
    LOOP
      IF sc.AtEnd() THEN sc.Error("the field has no closing quotation mark") END;
      ch := sc.Ch(); INC(sc.pos);
      IF ch = '"' THEN
        IF sc.Ch() = '"' THEN Put(n, '"'); INC(sc.pos) ELSE EXIT END
      ELSE Put(n, ch)
      END
    END;
    sc.SkipBlanks;
    IF ~sc.AtEnd() & (sc.Ch() # ",") & (sc.Ch() # 0AX) THEN
      sc.Error("expected a comma or a line end after the quoted field")
    END
  ELSE
    WHILE ~sc.AtEnd() & (sc.Ch() # ",") & (sc.Ch() # 0AX) DO
      IF sc.Ch() = '"' THEN sc.Error("a quotation mark in a field that is not quoted") END;
      Put(n, sc.Ch()); INC(sc.pos)
    END
  END;
  WHILE (n > 0) & L.IsBlank(buf[n - 1]) DO DEC(n) END;
  buf[n] := 0X
END Field;

(* The field's text, from buf, trimmed of leading blanks *)
PROCEDURE Text(n: LONGINT): Str;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < n) & L.IsBlank(buf[i]) DO INC(i) END;
  RETURN L.Sub(buf^, i, n - i)
END Text;

PROCEDURE Comma;
BEGIN
  IF sc.Ch() # "," THEN sc.Error("expected a comma: a record is a source, a target and a value") END;
  INC(sc.pos)
END Comma;

(* config.sankey.nodeColors's colour for the node named name, or -1 *)
PROCEDURE NodeColour(name: Str): LONGINT;
  VAR key: Str; q: Y.Pair; i, k: LONGINT; rgb: LONGINT; none: BOOLEAN;
    v: ARRAY 64 OF CHAR;
  CONST P = "config.sankey.nodeColors.";
BEGIN
  NEW(key, LEN(P) + L.Length(name^) + 1); i := 0;
  WHILE P[i] # 0X DO key[i] := P[i]; INC(i) END;
  k := 0;
  WHILE name[k] # 0X DO key[i] := name[k]; INC(i); INC(k) END;
  key[i] := 0X;
  q := Y.Find(d.g.config, key^);
  IF q = NIL THEN RETURN -1 END;
  COPY(q.value^, v);
  (* a colour CSS does not know leaves SVG's fill, black *)
  IF ~S.ParseColour(v, rgb, none) OR none THEN rgb := 0 END;
  RETURN rgb
END NodeColour;

(* The node named name, made if new *)
PROCEDURE GetNode(name: Str): Node;
  VAR n: Node;
BEGIN
  n := d.nodes;
  WHILE (n # NIL) & ~L.Equal(n.name, name) DO n := n.next END;
  IF n = NIL THEN
    NEW(n); n.name := name; n.index := d.nNodes; INC(d.nNodes); n.next := NIL;
    n.colour := NodeColour(name);
    IF d.lastNode = NIL THEN d.nodes := n ELSE d.lastNode.next := n END;
    d.lastNode := n
  END;
  RETURN n
END GetNode;

(* The number at the start of buf[0 .. n-1], after blanks, as
   JavaScript's parseFloat reads it, into x; FALSE if there is none *)
PROCEDURE Number(n: LONGINT; VAR x: LONGREAL): BOOLEAN;
  VAR i, j, start: LONGINT; digits: BOOLEAN; s: Str;
BEGIN
  i := 0;
  WHILE (i < n) & L.IsBlank(buf[i]) DO INC(i) END;
  start := i;
  IF (i < n) & ((buf[i] = "+") OR (buf[i] = "-")) THEN INC(i) END;
  digits := FALSE;
  WHILE (i < n) & L.IsDigit(buf[i]) DO INC(i); digits := TRUE END;
  IF (i < n) & (buf[i] = ".") THEN
    INC(i);
    WHILE (i < n) & L.IsDigit(buf[i]) DO INC(i); digits := TRUE END
  END;
  IF ~digits THEN RETURN FALSE END;
  IF (i < n) & ((buf[i] = "e") OR (buf[i] = "E")) THEN
    j := i + 1;
    IF (j < n) & ((buf[j] = "+") OR (buf[j] = "-")) THEN INC(j) END;
    IF (j < n) & L.IsDigit(buf[j]) THEN
      WHILE (j < n) & L.IsDigit(buf[j]) DO INC(j) END;
      i := j
    END
  END;
  s := L.Sub(buf^, start, i - start);
  RETURN X.JsParse(s, x) & (x = x) & (x - x = 0)
END Number;

(* A record, at its first field *)
PROCEDURE Record;
  VAR at, n: LONGINT; src, tgt: Str; k: Link; x: LONGREAL;
BEGIN
  at := sc.pos;
  Field(n); src := Text(n); Comma;
  Field(n); tgt := Text(n); Comma;
  Field(n);
  IF ~Number(n, x) THEN sc.Error("expected a number, the link's value") END;
  IF x < 0 THEN sc.Error("a link's value cannot be negative") END;
  sc.SkipBlanks;
  IF sc.Ch() = "," THEN sc.Error("a record has three fields: a source, a target and a value") END;
  NEW(k); k.source := GetNode(src); k.target := GetNode(tgt); k.value := x;
  k.index := d.nLinks; INC(d.nLinks); k.at := at; k.next := NIL;
  IF d.lastLink = NIL THEN d.links := k ELSE d.lastLink.next := k END;
  d.lastLink := k
END Record;

(* Reports a link in a cycle, if the links make one *)
PROCEDURE Cycles;
  VAR state: POINTER TO ARRAY OF SHORTINT; n: Node; bad: Link;

  (* Visits the node with index i: 1 while on the path, 2 when done *)
  PROCEDURE Visit(i: INTEGER);
    VAR k: Link;
  BEGIN
    state[i] := 1; k := d.links;
    WHILE (k # NIL) & (bad = NIL) DO
      IF k.source.index = i THEN
        IF state[k.target.index] = 1 THEN bad := k
        ELSIF state[k.target.index] = 0 THEN Visit(k.target.index)
        END
      END;
      k := k.next
    END;
    state[i] := 2
  END Visit;

BEGIN
  NEW(state, d.nNodes); bad := NIL;
  n := d.nodes;
  WHILE n # NIL DO state[n.index] := 0; n := n.next END;
  n := d.nodes;
  WHILE (n # NIL) & (bad = NIL) DO
    IF state[n.index] = 0 THEN Visit(n.index) END;
    n := n.next
  END;
  IF bad # NIL THEN sc.ErrorAt(bad.at, "circular link: the links make a cycle") END
END Cycles;

PROCEDURE Strings(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
  VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE a[i] # 0X DO INC(i) END;
  j := 0; WHILE (b[j] # 0X) & (i < LEN(a) - 1) DO a[i] := b[j]; INC(i); INC(j) END;
  a[i] := 0X
END Strings;

(* config.sankey.name, or NIL *)
PROCEDURE Find(name: ARRAY OF CHAR): Y.Pair;
  VAR key: ARRAY 64 OF CHAR;
BEGIN
  key := "config.sankey."; Strings(key, name);
  RETURN Y.Find(d.g.config, key)
END Find;

(* config.sankey.name, a number at least least, or default *)
PROCEDURE Num(name: ARRAY OF CHAR; default, least: LONGREAL): LONGREAL;
  VAR q: Y.Pair; x: LONGREAL; i: LONGINT;
BEGIN
  q := Find(name);
  IF q = NIL THEN RETURN default END;
  i := 0;
  WHILE L.IsBlank(q.value[i]) DO INC(i) END;
  IF (q.value[i] = 0X) OR ~X.JsParse(q.value, x) OR (x < least) THEN RETURN default END;
  RETURN x
END Num;

PROCEDURE Bool(name: ARRAY OF CHAR; default: BOOLEAN): BOOLEAN;
  VAR q: Y.Pair;
BEGIN
  q := Find(name);
  IF q = NIL THEN RETURN default END;
  IF L.Is(q.value, "true") THEN RETURN TRUE END;
  IF L.Is(q.value, "false") THEN RETURN FALSE END;
  RETURN default
END Bool;

PROCEDURE Text0(name: ARRAY OF CHAR): Str;
  VAR q: Y.Pair;
BEGIN
  q := Find(name);
  IF q = NIL THEN RETURN L.New("") END;
  RETURN q.value
END Text0;

PROCEDURE Configure;
  VAR q: Y.Pair; v: ARRAY 64 OF CHAR; none: BOOLEAN;
BEGIN
  d.width := Num("width", 600, 1);
  d.height := Num("height", 400, 1);
  d.nodeWidth := Num("nodeWidth", 10, 0);
  d.nodePadding := Num("nodePadding", 12, 0);
  d.showValues := Bool("showValues", TRUE);
  d.prefix := Text0("prefix"); d.suffix := Text0("suffix");
  q := Find("nodeAlignment"); d.align := Justify;
  IF q # NIL THEN
    IF L.Is(q.value, "left") THEN d.align := Left
    ELSIF L.Is(q.value, "right") THEN d.align := Right
    ELSIF L.Is(q.value, "center") THEN d.align := Center
    END
  END;
  q := Find("labelStyle");
  d.outlined := (q # NIL) & L.Is(q.value, "outlined");
  q := Find("linkColor"); d.linkColor := Gradient; d.linkRgb := 0; d.linkText := L.New("gradient");
  IF q # NIL THEN
    d.linkText := q.value;
    IF L.Is(q.value, "gradient") THEN d.linkColor := Gradient
    ELSIF L.Is(q.value, "source") THEN d.linkColor := Source
    ELSIF L.Is(q.value, "target") THEN d.linkColor := Target
    ELSE
      d.linkColor := Fixed; COPY(q.value^, v);
      (* a colour CSS does not know leaves SVG's stroke, none *)
      IF ~S.ParseColour(v, d.linkRgb, none) OR none THEN d.linkRgb := -1 END
    END
  END
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "sankey" *)
PROCEDURE IsSankey*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("sankey");
  s.pos := save;
  RETURN r
END IsSankey;

(* Reads the sankey diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Sankey, d.g); sc := s;
  d.nodes := NIL; d.nNodes := 0; d.links := NIL; d.nLinks := 0;
  d.lastNode := NIL; d.lastLink := NIL;
  Configure;
  IF ~sc.LookingAt("sankey") THEN sc.Error("expected sankey-beta or sankey") END;
  INC(sc.pos, 6);
  IF LookingAtCi("-beta") THEN INC(sc.pos, 5) END;
  sc.SkipBlanks;
  IF ~sc.AtEnd() & (sc.Ch() # 0AX) THEN sc.Error("expected a line end after sankey-beta") END;
  SkipLines;
  IF sc.AtEnd() THEN sc.Error("expected a record: a source, a target and a value") END;
  REPEAT
    Record;
    IF ~sc.AtEnd() THEN INC(sc.pos) END;  (* the line end *)
    SkipLines
  UNTIL sc.AtEnd();
  Cycles
END Read;

BEGIN
  NEW(buf, 256)
END PmSankey.
