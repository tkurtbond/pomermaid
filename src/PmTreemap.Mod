MODULE PmTreemap;
(* PmTreemap: Mermaid's treemaps (`treemap` or `treemap-beta`), read
   into a tree of sections and leaves, each with its name, its value,
   its level and its class's styles, and the configuration,
   config.treemap.

   The reader follows Mermaid 12.3.0's grammar, packages/parser/src/
   language/treemap/treemap.langium, with its lexer's tokens tried in
   its order, the first that matches taken, and what parser.ts, utils.ts
   and db.ts make of them:

   - comments that are a line of their own are removed first, as
     Mermaid removes them; other "%%" comments and line ends are
     skipped between tokens; blanks are not: they are a token,
     INDENTATION;
   - the diagram starts with "treemap-beta" or "treemap";
   - "title text", "accTitle: text" and "accDescr: text" (or
     "accDescr { text }") may come anywhere; the last title is kept,
     and an empty one is none;
   - each row is blanks, which may be left out, and a section, a leaf
     or a classDef. Its level is the number of blanks (a tab is one);
     none is level 0. Blanks at the end of a line are the next row's
     blanks: two together are an error, as is blanks at the end;
   - a section is a string, in double or single quotation marks,
     without escapes, which may span lines; a leaf is a string, a ":"
     or ",", and a number, with blanks allowed around the ":" or ",";
     either may be followed by ":::" and a class name;
   - a leaf's number is digits, "_", "." and ","; its value is the
     number JavaScript reads from it, which must be digits with a "."
     in or around them: one with "_" or "," is an error, as pomermaid
     cannot draw it (Mermaid draws nothing sensible);
   - "classDef name styles" defines a class; the name has at least two
     characters, and the styles go to the end of the line or a ";",
     split at "," and ";" ("\," is a comma in a style). A class applies
     to sections and leaves before its classDef too; a class given
     again adds its styles. fill, stroke, stroke-width and color are
     drawn; others are warned of;
   - a row's parent is the last section before it with a smaller
     level; one with none is at the top, a child of the root, which
     has no name and is not drawn.

   valueFormat is d3-format's specifier, with Mermaid's "$" rules: "$0,0"
   is "$" and ","; "$" with a "," is "$" and "," with the specifier's
   first precision; another "$..." is "$" and the rest. An invalid
   specifier is "," but an invalid rest after "$" is an error, as it is
   in Mermaid when values are shown. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml, PmFormat;

CONST
  (* tokens *)
  tEOF = 0; tBoolean = 1; tAccDescr = 2; tAccTitle = 3; tTitle = 4; tKeyword = 5;
  tClassDef = 6; tStyleSep = 7; tSep = 8; tComma = 9; tIndent = 10; tId = 11;
  tNumber = 12; tString = 13; tError = 14;

  LF = 0AX; CR = 0DX; TAB = 09X;

TYPE
  Str = L.Str;

  Node* = POINTER TO NodeDesc;
  NodeDesc* = RECORD
    index-: LONGINT;        (* from 0, in order read; the root's -1 *)
    name-: Str;             (* as written, without its quotation marks *)
    label-: F.Label;        (* name, its line ends blanks *)
    leaf-: BOOLEAN;         (* else a section *)
    value-: LONGREAL;       (* a leaf's; 0 for a section *)
    level-: LONGINT;        (* its blanks *)
    class-: Str;            (* after ":::", or NIL *)
    fill-, stroke-, strokeWidth-, color-: Str;  (* its class's, or NIL *)
    pos-: LONGINT;          (* where it is in the text *)
    parent-, children-, next-: Node;
    nChildren-: LONGINT;
    last: Node
  END;

  Class = POINTER TO ClassDesc;
  ClassDesc = RECORD
    name: Str;
    fill, stroke, strokeWidth, color: Str;
    next: Class
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;               (* the title and the configuration *)
    root-: Node;               (* no name; its children the rows at the top *)
    nNodes-: LONGINT;          (* the rows, sections and leaves *)
    width-, height-: LONGREAL; (* the treemap's, below the title *)
    padding-: LONGREAL;        (* between siblings *)
    diagramPadding-: LONGREAL; (* around the drawing *)
    showValues-: BOOLEAN;
    valueFormat-: Str;         (* as given; "," by default *)
    dollar-: BOOLEAN;          (* "$" before each value *)
    format-: PmFormat.Format
  END;

  Token = RECORD
    kind: INTEGER;
    start, end: LONGINT;     (* its text *)
    a0, a1, b0, b1: LONGINT  (* a classDef's name and styles, b0 < 0 for
                                none; a title's text *)
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;
  classes: Class;
  rows, lastRow: Node;       (* in order read *)
  textStart: LONGINT;        (* the diagram's text starts here, after its
                                front matter and directives *)

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

(* Warns about the text at at: "NAME:LINE:COL: a"; its own buffer, as
   buf may hold the text being read *)
PROCEDURE Warn(at: LONGINT; a: ARRAY OF CHAR);
  VAR line, col: LONGINT; m: ARRAY 512 OF CHAR; n: INTEGER;
  PROCEDURE Add(s: ARRAY OF CHAR);
    VAR i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (n < LEN(m) - 1) DO m[n] := s[i]; INC(n); INC(i) END
  END Add;
  PROCEDURE Num(k: LONGINT);
    VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
  BEGIN
    i := 0; REPEAT dg[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
    WHILE (i > 0) & (n < LEN(m) - 1) DO DEC(i); m[n] := dg[i]; INC(n) END
  END Num;
BEGIN
  sc.Where(at, line, col);
  n := 0; Add(sc.name); Add(":"); Num(line); Add(":"); Num(col); Add(": ");
  Add(a); m[n] := 0X;
  PmIO.Warn(m)
END Warn;

(* The lexer *)

PROCEDURE Ch(p: LONGINT): CHAR;
BEGIN
  IF p < sc.len THEN RETURN sc.t[p] ELSE RETURN 0X END
END Ch;

(* JavaScript's \s, in ASCII *)
PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = TAB) OR (ch = LF) OR (ch = CR) OR (ch = 0BX) OR (ch = 0CX)
END IsSpace;

PROCEDURE IsBlank(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = " ") OR (ch = TAB)
END IsBlank;

PROCEDURE IsIdStart(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "a") & (ch <= "z") OR (ch >= "A") & (ch <= "Z") OR (ch = "_")
END IsIdStart;

PROCEDURE IsIdChar(ch: CHAR): BOOLEAN;
BEGIN
  RETURN IsIdStart(ch) OR (ch >= "0") & (ch <= "9")
END IsIdChar;

PROCEDURE IsLineEnd(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = LF) OR (ch = CR)
END IsLineEnd;

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

(* Whether p starts a line *)
PROCEDURE LineStart(p: LONGINT): BOOLEAN;
BEGIN
  RETURN (p <= textStart) OR IsLineEnd(sc.t[p - 1])
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

(* Where p is after what is skipped: comments, line ends and
   directives *)
PROCEDURE Hidden(p: LONGINT): LONGINT;
  VAR e, save: LONGINT;
BEGIN
  LOOP
    IF p >= sc.len THEN EXIT END;
    IF LineStart(p) THEN e := CommentLine(p) ELSE e := -1 END;
    IF e >= 0 THEN p := e
    ELSIF IsLineEnd(sc.t[p]) THEN INC(p)
    ELSIF At(p, "%%{") THEN
      save := sc.pos; sc.pos := p; e := sc.DirectiveEnd(); sc.pos := save;
      IF e >= 0 THEN p := e ELSE WHILE (p < sc.len) & (sc.t[p] # LF) DO INC(p) END END
    ELSIF At(p, "%%") THEN
      WHILE (p < sc.len) & (sc.t[p] # LF) DO INC(p) END
    ELSE EXIT
    END
  END;
  RETURN p
END Hidden;

(* accDescr, accTitle or title at p, after blanks; FALSE if none *)
PROCEDURE AccOrTitle(p: LONGINT; VAR t: Token): BOOLEAN;
  VAR q, e: LONGINT;
BEGIN
  q := p; WHILE IsBlank(Ch(q)) DO INC(q) END;
  IF At(q, "accDescr") THEN
    e := q + 8; WHILE IsBlank(Ch(e)) DO INC(e) END;
    IF Ch(e) = ":" THEN
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      t.kind := tAccDescr; t.end := e; RETURN TRUE
    END;
    e := q + 8; WHILE IsSpace(Ch(e)) DO INC(e) END;
    IF Ch(e) = "{" THEN
      WHILE (e < sc.len) & (sc.t[e] # "}") DO INC(e) END;
      IF e < sc.len THEN t.kind := tAccDescr; t.end := e + 1; RETURN TRUE END
    END;
    RETURN FALSE
  ELSIF At(q, "accTitle") THEN
    e := q + 8; WHILE IsBlank(Ch(e)) DO INC(e) END;
    IF Ch(e) = ":" THEN
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      t.kind := tAccTitle; t.end := e; RETURN TRUE
    END;
    RETURN FALSE
  ELSIF At(q, "title") THEN
    e := q + 5; t.kind := tTitle; t.a0 := e; t.a1 := e;
    IF IsBlank(Ch(e)) THEN
      INC(e); t.a0 := e;
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) & ~At(e, "%%") DO INC(e) END;
      t.a1 := e
    END;
    t.end := e; RETURN TRUE
  END;
  RETURN FALSE
END AccOrTitle;

(* classDef at p: "classDef", white space, a name of two characters or more, then, after white space, styles up to ";" or the line's end, and a ";" *)
PROCEDURE ClassDefToken(p: LONGINT; VAR t: Token): BOOLEAN;
  VAR e, s: LONGINT;
BEGIN
  IF ~At(p, "classDef") THEN RETURN FALSE END;
  e := p + 8;
  IF ~IsSpace(Ch(e)) THEN RETURN FALSE END;
  WHILE IsSpace(Ch(e)) DO INC(e) END;
  IF ~IsIdStart(Ch(e)) OR ~IsIdChar(Ch(e + 1)) THEN RETURN FALSE END;
  t.a0 := e; INC(e, 2);
  WHILE IsIdChar(Ch(e)) DO INC(e) END;
  t.a1 := e; t.b0 := -1; t.b1 := -1;
  IF IsSpace(Ch(e)) THEN
    s := e; WHILE IsSpace(Ch(s)) DO INC(s) END;
    t.b0 := s;
    WHILE (s < sc.len) & (sc.t[s] # ";") & ~IsLineEnd(sc.t[s]) DO INC(s) END;
    t.b1 := s; e := s
  END;
  IF Ch(e) = ";" THEN INC(e) END;
  t.kind := tClassDef; t.end := e;
  RETURN TRUE
END ClassDefToken;

(* The token at p, after what is skipped *)
PROCEDURE Lex(p: LONGINT; VAR t: Token);
  VAR ch, q: CHAR; e: LONGINT;
BEGIN
  p := Hidden(p);
  t.start := p; t.a0 := -1; t.a1 := -1; t.b0 := -1; t.b1 := -1;
  IF p >= sc.len THEN t.kind := tEOF; t.end := p; RETURN END;
  ch := sc.t[p];
  IF At(p, "true") THEN t.kind := tBoolean; t.end := p + 4
  ELSIF At(p, "false") THEN t.kind := tBoolean; t.end := p + 5
  ELSIF AccOrTitle(p, t) THEN (* done *)
  ELSIF At(p, "treemap-beta") THEN t.kind := tKeyword; t.end := p + 12
  ELSIF At(p, "treemap") THEN t.kind := tKeyword; t.end := p + 7
  ELSIF ClassDefToken(p, t) THEN (* done *)
  ELSIF At(p, ":::") THEN t.kind := tStyleSep; t.end := p + 3
  ELSIF ch = ":" THEN t.kind := tSep; t.end := p + 1
  ELSIF ch = "," THEN t.kind := tComma; t.end := p + 1
  ELSIF IsBlank(ch) THEN
    e := p; WHILE IsBlank(Ch(e)) DO INC(e) END;
    t.kind := tIndent; t.end := e
  ELSIF IsIdStart(ch) THEN
    e := p; WHILE IsIdChar(Ch(e)) DO INC(e) END;
    t.kind := tId; t.end := e
  ELSIF (ch >= "0") & (ch <= "9") OR (ch = "_") OR (ch = ".") OR (ch = ",") THEN
    e := p;
    WHILE (Ch(e) >= "0") & (Ch(e) <= "9") OR (Ch(e) = "_") OR (Ch(e) = ".") OR (Ch(e) = ",") DO
      INC(e)
    END;
    t.kind := tNumber; t.end := e
  ELSIF (ch = '"') OR (ch = "'") THEN
    q := ch; e := p + 1;
    WHILE (e < sc.len) & (sc.t[e] # q) DO INC(e) END;
    IF e < sc.len THEN t.kind := tString; t.end := e + 1
    ELSE t.kind := tError; t.end := p + 1
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
  | tIndent:
      IF IsLineEnd(Ch(t.end)) OR (Hidden(t.end) >= sc.len) OR (Ch(t.end) = "%") THEN
        PutS(n, ", not blanks at the end of a line")
      ELSE PutS(n, ", not blanks")
      END
  | tError: PutS(n, ", not "); Put(n, "'"); Put(n, sc.t[t.start]); Put(n, "'")
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

(* Classes *)

PROCEDURE FindClass(name: Str): Class;
  VAR c: Class;
BEGIN
  c := classes;
  WHILE (c # NIL) & ~L.Equal(c.name, name) DO c := c.next END;
  RETURN c
END FindClass;

(* buf[a .. b-1], without blanks at either end *)
PROCEDURE Trimmed(a, b: LONGINT): Str;
BEGIN
  WHILE (a < b) & IsSpace(buf[a]) DO INC(a) END;
  WHILE (b > a) & IsSpace(buf[b - 1]) DO DEC(b) END;
  RETURN L.Sub(buf^, a, b - a)
END Trimmed;

PROCEDURE Append(VAR m: ARRAY OF CHAR; a: ARRAY OF CHAR);
  VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE m[i] # 0X DO INC(i) END;
  j := 0;
  WHILE (j < LEN(a)) & (a[j] # 0X) & (i < LEN(m) - 1) DO m[i] := a[j]; INC(i); INC(j) END;
  m[i] := 0X
END Append;

(* The style buf[a .. b-1], "key:value", in c; at is where its
   classDef is *)
PROCEDURE Style(c: Class; a, b, at: LONGINT);
  VAR k: LONGINT; key, value: Str; m: ARRAY 160 OF CHAR; i, j: INTEGER;
BEGIN
  k := a; WHILE (k < b) & (buf[k] # ":") DO INC(k) END;
  key := Trimmed(a, k);
  IF k < b THEN
    (* Mermaid splits at every ":" and keeps the second part *)
    a := k + 1; k := a; WHILE (k < b) & (buf[k] # ":") DO INC(k) END;
    value := Trimmed(a, k)
  ELSE value := NIL
  END;
  IF key[0] = 0X THEN RETURN END;
  IF L.Is(key, "fill") THEN c.fill := value
  ELSIF L.Is(key, "stroke") THEN c.stroke := value
  ELSIF L.Is(key, "stroke-width") THEN c.strokeWidth := value
  ELSIF L.Is(key, "color") THEN c.color := value
  ELSE
    m := "the style "; i := 10; j := 0;
    WHILE (key[j] # 0X) & (i < 100) DO m[i] := key[j]; INC(i); INC(j) END;
    m[i] := 0X;
    Append(m, " is not drawn");
    Warn(at, m)
  END
END Style;

(* A classDef token: its styles added to its class *)
PROCEDURE ClassDef(VAR t: Token);
  VAR c: Class; name: Str; n, a, k: LONGINT;
BEGIN
  name := L.Sub(sc.t^, t.a0, t.a1 - t.a0);
  c := FindClass(name);
  IF c = NIL THEN
    NEW(c); c.name := name; c.fill := NIL; c.stroke := NIL; c.strokeWidth := NIL;
    c.color := NIL; c.next := classes; classes := c
  END;
  IF t.b0 < 0 THEN RETURN END;
  (* "\," is a comma; "," and ";" end a style *)
  n := 0; k := t.b0;
  WHILE k < t.b1 DO
    IF (sc.t[k] = "\") & (k + 1 < t.b1) & (sc.t[k + 1] = ",") THEN Put(n, 1X); INC(k, 2)
    ELSIF sc.t[k] = "," THEN Put(n, ";"); INC(k)
    ELSE Put(n, sc.t[k]); INC(k)
    END
  END;
  buf[n] := 0X;
  a := 0; k := 0;
  LOOP
    IF (k = n) OR (buf[k] = ";") THEN
      Style(c, a, k, t.start);
      IF k = n THEN EXIT END;
      a := k + 1
    END;
    INC(k)
  END
END ClassDef;

(* The commas kept by "\," in the classes' styles *)
PROCEDURE Commas(s: Str);
  VAR i: LONGINT;
BEGIN
  IF s # NIL THEN
    i := 0; WHILE s[i] # 0X DO IF s[i] = 1X THEN s[i] := "," END; INC(i) END
  END
END Commas;

(* Rows *)

(* A leaf's number, t: its value; an error unless JavaScript's Number
   reads it *)
PROCEDURE Value(VAR t: Token): LONGREAL;
  VAR k, frac, dots, digits: LONGINT; m, p: LONGREAL; n: LONGINT;
BEGIN
  m := 0; frac := 0; dots := 0; digits := 0;
  FOR k := t.start TO t.end - 1 DO
    IF sc.t[k] = "." THEN INC(dots)
    ELSIF (sc.t[k] >= "0") & (sc.t[k] <= "9") THEN
      INC(digits); m := m * 10 + (ORD(sc.t[k]) - ORD("0"));
      IF dots > 0 THEN INC(frac) END
    ELSE dots := 2
    END
  END;
  IF (dots > 1) OR (digits = 0) THEN
    n := 0; PutS(n, "the value "); PutText(n, t.start, t.end);
    PutS(n, " is not a number"); buf[n] := 0X;
    sc.ErrorAt(t.start, buf^)
  END;
  p := 1; WHILE frac > 0 DO p := p * 10; DEC(frac) END;
  m := m / p;
  IF m > MAX(LONGREAL) THEN sc.ErrorAt(t.start, "the value is too large") END;
  RETURN m
END Value;

(* A string token's text, without its quotation marks: name, and its
   label *)
PROCEDURE Name(VAR t: Token; nd: Node);
  VAR n, k: LONGINT;
BEGIN
  nd.name := L.Sub(sc.t^, t.start + 1, t.end - t.start - 2);
  n := 0;
  FOR k := t.start + 1 TO t.end - 2 DO
    IF IsSpace(sc.t[k]) THEN Put(n, " ") ELSE Put(n, sc.t[k]) END
  END;
  buf[n] := 0X;
  nd.label := F.TextLabel(buf^, 0, n)
END Name;

PROCEDURE NewNode(): Node;
  VAR nd: Node;
BEGIN
  NEW(nd); nd.index := -1; nd.name := NIL; nd.label := NIL; nd.leaf := FALSE; nd.value := 0;
  nd.level := 0; nd.class := NIL; nd.fill := NIL; nd.stroke := NIL; nd.strokeWidth := NIL;
  nd.color := NIL; nd.pos := 0; nd.parent := NIL; nd.children := NIL; nd.next := NIL;
  nd.nChildren := 0; nd.last := NIL;
  RETURN nd
END NewNode;

(* A row at p: blanks, if any, and a section, a leaf or a classDef *)
PROCEDURE Row(VAR p: LONGINT);
  VAR t, u: Token; nd: Node; level: LONGINT;
BEGIN
  Lex(p, t); level := 0;
  IF t.kind = tIndent THEN level := t.end - t.start; p := t.end; Lex(p, t) END;
  IF t.kind = tClassDef THEN ClassDef(t); p := t.end
  ELSIF t.kind = tString THEN
    nd := NewNode(); nd.level := level; nd.pos := t.start; Name(t, nd);
    p := t.end;
    Lex(p, u);
    IF u.kind = tIndent THEN Lex(u.end, u) END;
    IF (u.kind = tSep) OR (u.kind = tComma) THEN
      nd.leaf := TRUE;
      p := u.end; Lex(p, t);
      IF t.kind = tIndent THEN p := t.end; Lex(p, t) END;
      IF t.kind # tNumber THEN Unexpected(t, "a number") END;
      nd.value := Value(t); p := t.end
    END;
    Lex(p, t);
    IF t.kind = tStyleSep THEN
      p := t.end; Lex(p, t);
      IF t.kind # tId THEN Unexpected(t, "a class name") END;
      nd.class := L.Sub(sc.t^, t.start, t.end - t.start); p := t.end
    END;
    nd.index := d.nNodes; INC(d.nNodes);
    IF rows = NIL THEN rows := nd ELSE lastRow.next := nd END;
    lastRow := nd
  ELSE Unexpected(t, "a section, a leaf or classDef")
  END
END Row;

PROCEDURE AddChild(parent, c: Node);
BEGIN
  c.parent := parent; c.next := NIL;
  IF parent.children = NIL THEN parent.children := c ELSE parent.last.next := c END;
  parent.last := c; INC(parent.nChildren)
END AddChild;

(* The rows made a tree, as utils.ts's buildHierarchy makes it, with
   their classes' styles *)
PROCEDURE Build;
  VAR nd, next: Node; stack: POINTER TO ARRAY OF Node; top: LONGINT; c: Class;
BEGIN
  c := classes;
  WHILE c # NIL DO
    Commas(c.fill); Commas(c.stroke); Commas(c.strokeWidth); Commas(c.color);
    c := c.next
  END;
  NEW(stack, d.nNodes + 1); top := 0;
  nd := rows;
  WHILE nd # NIL DO
    next := nd.next;
    IF nd.class # NIL THEN
      c := FindClass(nd.class);
      IF c # NIL THEN
        nd.fill := c.fill; nd.stroke := c.stroke; nd.strokeWidth := c.strokeWidth;
        nd.color := c.color
      END
    END;
    WHILE (top > 0) & (stack[top - 1].level >= nd.level) DO DEC(top) END;
    IF top = 0 THEN AddChild(d.root, nd) ELSE AddChild(stack[top - 1], nd) END;
    IF ~nd.leaf THEN stack[top] := nd; INC(top) END;
    nd := next
  END
END Build;

(* The configuration *)

(* config.treemap.name, a number, or default *)
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

PROCEDURE Configure;
  VAR q: Y.Pair; s, rest: Str; spec: ARRAY 64 OF CHAR; i, k: LONGINT; comma: BOOLEAN;
BEGIN
  d.width := Conf("config.treemap.nodeWidth", 0);
  IF d.width > 0 THEN d.width := d.width * 10 ELSE d.width := 960 END;
  d.height := Conf("config.treemap.nodeHeight", 0);
  IF d.height > 0 THEN d.height := d.height * 10 ELSE d.height := 500 END;
  d.padding := Conf("config.treemap.padding", 10);
  IF d.padding < 0 THEN d.padding := 10 END;
  d.diagramPadding := Conf("config.treemap.diagramPadding", 8);
  IF d.diagramPadding < 0 THEN d.diagramPadding := 8 END;
  q := Y.Find(d.g.config, "config.treemap.showValues");
  d.showValues := (q = NIL) OR ~L.Is(q.value, "false");
  q := Y.Find(d.g.config, "config.treemap.valueFormat");
  IF (q = NIL) OR (q.value[0] = 0X) THEN s := L.New(",") ELSE s := q.value END;
  d.valueFormat := s; d.dollar := FALSE;
  IF L.Is(s, "$0,0") THEN d.dollar := TRUE; IF PmFormat.New(",", d.format) THEN END
  ELSIF s[0] = "$" THEN
    d.dollar := TRUE; rest := L.Sub(s^, 1, L.Length(s^) - 1);
    comma := FALSE; i := 0; WHILE s[i] # 0X DO IF s[i] = "," THEN comma := TRUE END; INC(i) END;
    IF comma THEN
      (* "," and the first /\.\d+/ *)
      spec := ","; k := 1; i := 0;
      WHILE (s[i] # 0X) & ~((s[i] = ".") & L.IsDigit(s[i + 1])) DO INC(i) END;
      IF s[i] = "." THEN
        spec[k] := "."; INC(k); INC(i);
        WHILE L.IsDigit(s[i]) & (k < LEN(spec) - 1) DO spec[k] := s[i]; INC(k); INC(i) END
      END;
      spec[k] := 0X;
      IF ~PmFormat.New(spec, d.format) THEN IF PmFormat.New(",", d.format) THEN END END
    ELSIF ~PmFormat.New(rest^, d.format) THEN
      IF d.showValues THEN
        sc.ErrorAt(q.pos, "valueFormat: what follows $ is not a format specifier")
      END;
      IF PmFormat.New(",", d.format) THEN END
    END
  ELSIF ~PmFormat.New(s^, d.format) THEN
    IF PmFormat.New(",", d.format) THEN END
  END
END Configure;

(* x as valueFormat writes it, in s *)
PROCEDURE Format*(dg: Diagram; x: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR t: ARRAY 4400 OF CHAR; i: LONGINT;
BEGIN
  PmFormat.Apply(dg.format, x, t);
  IF dg.dollar THEN
    s[0] := "$"; i := 0;
    WHILE (t[i] # 0X) & (i + 2 < LEN(s)) DO s[i + 1] := t[i]; INC(i) END;
    s[i + 1] := 0X
  ELSE COPY(t, s)
  END
END Format;

(* Whether the scanner's text, after front matter and comments, starts
   with "treemap" *)
PROCEDURE IsTreemap*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("treemap");
  s.pos := save;
  RETURN r
END IsTreemap;

(* Reads the treemap in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR p, n: LONGINT; t: Token;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Treemap, d.g); sc := s;
  d.nNodes := 0; d.root := NewNode(); d.root.name := L.New(""); d.root.label := F.TextLabel(buf^, 0, 0);
  classes := NIL; rows := NIL; lastRow := NIL;
  textStart := sc.pos;
  Configure;
  Lex(sc.pos, t);
  IF t.kind # tKeyword THEN Unexpected(t, "treemap") END;
  p := t.end;
  LOOP
    Lex(p, t);
    CASE t.kind OF
      tEOF: EXIT
    | tTitle:
        n := t.a1; WHILE (n > t.a0) & IsBlank(sc.t[n - 1]) DO DEC(n) END;
        WHILE (t.a0 < n) & IsBlank(sc.t[t.a0]) DO INC(t.a0) END;
        IF n > t.a0 THEN d.g.title := F.TextLabel(sc.t^, t.a0, n) ELSE d.g.title := NIL END;
        p := t.end
    | tAccTitle, tAccDescr: p := t.end
    | tIndent, tString, tClassDef: Row(p)
    ELSE Unexpected(t, "a section, a leaf or classDef")
    END
  END;
  Build;
  sc.pos := sc.len
END Read;

BEGIN
  NEW(buf, 256)
END PmTreemap.
