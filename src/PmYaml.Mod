MODULE PmYaml;
(* PmYaml: the part of YAML that Mermaid's metadata uses: front matter,
   "%%{init: ...}%%" directives and the "@{ ... }" of a node or an edge.

   That is mappings, in block form (keys indented under their parent)
   and in flow form ("{key: value, ...}"), whose values are scalars:
   plain, 'single-quoted' or "double-quoted". Each scalar comes out as
   a Pair whose name is its keys joined by ".", as "config.flowchart.
   curve". Sequences ("- item", "[a, b]") and block scalars ("|", ">")
   are skipped. A key given twice keeps its later value (Find finds
   the last).

   The text is the scanner's; an error is reported at its place, with
   PmLex's ErrorAt. *)

IMPORT PmIO, L := PmLex;

CONST
  LF = 0AX;

TYPE
  Pair* = POINTER TO PairDesc;
  PairDesc* = RECORD
    name*, value*: L.Str;
    pos*: LONGINT;       (* where the value starts in the text *)
    next*: Pair
  END;

VAR
  sc: L.Scanner;
  t: PmIO.Text;          (* sc's text *)
  p, end: LONGINT;       (* the position, and the end of the text read *)
  first, last: Pair;
  breaks: BOOLEAN;       (* a line end in "..." is "<br/>" *)
  buf: L.Str; bufLen: LONGINT;

PROCEDURE Put(ch: CHAR);
  VAR n: L.Str; i: LONGINT;
BEGIN
  IF bufLen + 1 >= LEN(buf^) THEN
    NEW(n, 2 * LEN(buf^));
    FOR i := 0 TO bufLen - 1 DO n[i] := buf[i] END;
    buf := n
  END;
  buf[bufLen] := ch; INC(bufLen)
END Put;

PROCEDURE PutStr(s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(s[i]); INC(i) END
END PutStr;

PROCEDURE Ch(): CHAR;
BEGIN
  IF p < end THEN RETURN t[p] ELSE RETURN 0X END
END Ch;

PROCEDURE Blank(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch = " ") OR (ch = 09X) OR (ch = 0DX)
END Blank;

PROCEDURE SkipBlanks;
BEGIN
  WHILE (p < end) & Blank(t[p]) DO INC(p) END
END SkipBlanks;

(* Skips blanks, line ends and comments, as between flow items *)
PROCEDURE SkipSpace;
BEGIN
  LOOP
    SkipBlanks;
    IF Ch() = LF THEN INC(p)
    ELSIF Ch() = "#" THEN WHILE (p < end) & (t[p] # LF) DO INC(p) END
    ELSE EXIT
    END
  END
END SkipSpace;

(* Adds the pair prefix.key = buf *)
PROCEDURE Add(prefix: ARRAY OF CHAR; key: L.Str; at: LONGINT);
  VAR q: Pair; k, i, n: LONGINT;
BEGIN
  NEW(q); q.value := L.Sub(buf^, 0, bufLen); q.pos := at; q.next := NIL;
  n := L.Length(prefix);
  NEW(q.name, n + L.Length(key^) + 2);
  k := 0;
  FOR i := 0 TO n - 1 DO q.name[k] := prefix[i]; INC(k) END;
  IF n > 0 THEN q.name[k] := "."; INC(k) END;
  i := 0; WHILE key[i] # 0X DO q.name[k] := key[i]; INC(k); INC(i) END;
  q.name[k] := 0X;
  IF first = NIL THEN first := q ELSE last.next := q END;
  last := q
END Add;

(* prefix.key, as a new string *)
PROCEDURE Join(prefix: ARRAY OF CHAR; key: L.Str): L.Str;
  VAR s: L.Str; k, i, n: LONGINT;
BEGIN
  n := L.Length(prefix);
  NEW(s, n + L.Length(key^) + 2);
  k := 0;
  FOR i := 0 TO n - 1 DO s[k] := prefix[i]; INC(k) END;
  IF n > 0 THEN s[k] := "."; INC(k) END;
  i := 0; WHILE key[i] # 0X DO s[k] := key[i]; INC(k); INC(i) END;
  s[k] := 0X;
  RETURN s
END Join;

(* A quoted scalar at p, into buf *)
PROCEDURE Quoted;
  VAR q: CHAR; start: LONGINT;
BEGIN
  q := t[p]; start := p; INC(p); bufLen := 0;
  LOOP
    IF p >= end THEN sc.ErrorAt(start, "unterminated string") END;
    IF t[p] = q THEN
      IF (q = "'") & (p + 1 < end) & (t[p + 1] = "'") THEN Put("'"); INC(p, 2)
      ELSE INC(p); EXIT
      END
    ELSIF (q = 22X) & (t[p] = "\") & (p + 1 < end) THEN
      INC(p);
      CASE t[p] OF
        "n": Put(LF)
      | "t": Put(09X)
      | LF:
      ELSE Put(t[p])
      END;
      INC(p)
    ELSIF t[p] = LF THEN
      IF breaks THEN PutStr("<br/>") ELSE Put(" ") END;
      INC(p);
      WHILE (p < end) & (Blank(t[p]) OR (t[p] = LF)) DO INC(p) END
    ELSE Put(t[p]); INC(p)
    END
  END
END Quoted;

(* A plain scalar at p, into buf: to a line end or a comment, and in
   flow to "," "}" or "]" too; without blanks at its ends *)
PROCEDURE Plain(flow: BOOLEAN);
  VAR start, e: LONGINT;
BEGIN
  start := p;
  WHILE (p < end) & (t[p] # LF)
     & ~((t[p] = "#") & (p > start) & Blank(t[p - 1]))
     & ~(flow & ((t[p] = ",") OR (t[p] = "}") OR (t[p] = "]"))) DO
    INC(p)
  END;
  e := p;
  WHILE (e > start) & Blank(t[e - 1]) DO DEC(e) END;
  bufLen := 0;
  WHILE start < e DO Put(t[start]); INC(start) END
END Plain;

(* A key at p, up to its ":" *)
PROCEDURE Key(flow: BOOLEAN): L.Str;
  VAR start, e: LONGINT;
BEGIN
  IF (Ch() = 22X) OR (Ch() = "'") THEN
    Quoted
  ELSE
    start := p;
    WHILE (p < end) & (t[p] # LF) & ~((t[p] = ":") & ((p + 1 >= end) OR Blank(t[p + 1])
          OR (t[p + 1] = LF) OR flow & ((t[p + 1] = ",") OR (t[p + 1] = "}") OR (t[p + 1] = 22X) OR (t[p + 1] = "'"))))
       & ~(flow & ((t[p] = ",") OR (t[p] = "}"))) DO
      INC(p)
    END;
    e := p;
    WHILE (e > start) & Blank(t[e - 1]) DO DEC(e) END;
    bufLen := 0;
    WHILE start < e DO Put(t[start]); INC(start) END
  END;
  SkipBlanks;
  IF Ch() # ":" THEN sc.ErrorAt(p, 'expected ":" after a key') END;
  INC(p);
  RETURN L.Sub(buf^, 0, bufLen)
END Key;

(* Skips a flow sequence or mapping at p, with what is nested in it *)
PROCEDURE SkipFlow;
  VAR depth: INTEGER; start: LONGINT;
BEGIN
  depth := 0; start := p;
  LOOP
    IF p >= end THEN sc.ErrorAt(start, "a [ or { has no end") END;
    IF (t[p] = "[") OR (t[p] = "{") THEN INC(depth); INC(p)
    ELSIF (t[p] = "]") OR (t[p] = "}") THEN DEC(depth); INC(p); IF depth = 0 THEN EXIT END
    ELSIF (t[p] = 22X) OR (t[p] = "'") THEN Quoted
    ELSE INC(p)
    END
  END
END SkipFlow;

(* The items of a flow mapping, at p after its "{", to its "}" (taken)
   or, if braced is FALSE, to the end *)
PROCEDURE FlowItems(prefix: ARRAY OF CHAR; braced: BOOLEAN);
  VAR key, full: L.Str; at: LONGINT;
BEGIN
  LOOP
    SkipSpace;
    IF p >= end THEN
      IF braced THEN sc.ErrorAt(p, "a { has no }") END;
      EXIT
    END;
    IF Ch() = "}" THEN
      IF ~braced THEN sc.ErrorAt(p, "unexpected }") END;
      INC(p); EXIT
    END;
    key := Key(TRUE);
    SkipSpace;
    at := p;
    IF Ch() = "{" THEN INC(p); full := Join(prefix, key); FlowItems(full^, TRUE)
    ELSIF Ch() = "[" THEN SkipFlow
    ELSE
      IF (Ch() = 22X) OR (Ch() = "'") THEN Quoted ELSE Plain(TRUE) END;
      Add(prefix, key, at)
    END;
    SkipSpace;
    IF Ch() = "," THEN INC(p)
    ELSIF (Ch() # "}") & (p < end) THEN sc.ErrorAt(p, 'expected "," or "}"')
    END
  END
END FlowItems;

(* The indentation of the line at p, which is at a line's start; p is
   left at its first character *)
PROCEDURE Indent(): LONGINT;
  VAR start: LONGINT;
BEGIN
  start := p;
  WHILE (p < end) & ((t[p] = " ") OR (t[p] = 09X)) DO INC(p) END;
  RETURN p - start
END Indent;

(* Moves p to the start of the next line that has something on it
   other than a comment *)
PROCEDURE NextLine;
  VAR save: LONGINT;
BEGIN
  LOOP
    IF p >= end THEN EXIT END;
    save := p;
    SkipBlanks;
    IF (p >= end) OR (Ch() = LF) OR (Ch() = "#") THEN
      WHILE (p < end) & (t[p] # LF) DO INC(p) END;
      IF p < end THEN INC(p) END
    ELSE p := save; EXIT
    END
  END
END NextLine;

(* Skips the lines indented more than indent, from the start of the
   next one *)
PROCEDURE SkipDeeper(indent: LONGINT);
  VAR save: LONGINT;
BEGIN
  LOOP
    NextLine;
    IF p >= end THEN EXIT END;
    save := p;
    IF Indent() <= indent THEN p := save; EXIT END;
    WHILE (p < end) & (t[p] # LF) DO INC(p) END;
    IF p < end THEN INC(p) END
  END
END SkipDeeper;

(* Skips a sequence whose items are at indent, from the start of its
   first item's line, and what is indented more *)
PROCEDURE SkipSequence(indent: LONGINT);
  VAR save, ind: LONGINT;
BEGIN
  LOOP
    NextLine;
    IF p >= end THEN EXIT END;
    save := p; ind := Indent();
    IF (ind < indent) OR (ind = indent) & (Ch() # "-") THEN p := save; EXIT END;
    WHILE (p < end) & (t[p] # LF) DO INC(p) END;
    IF p < end THEN INC(p) END
  END
END SkipSequence;

(* A block mapping whose keys are indented more than outer, from the
   start of a line *)
PROCEDURE BlockMap(prefix: ARRAY OF CHAR; outer: LONGINT);
  VAR save, at, ind, indent: LONGINT; key, full: L.Str; done: BOOLEAN;
BEGIN
  indent := -1;
  LOOP
    NextLine;
    IF p >= end THEN EXIT END;
    save := p;
    ind := Indent();
    IF ind <= outer THEN p := save; EXIT END;
    IF indent < 0 THEN indent := ind
    ELSIF ind # indent THEN sc.ErrorAt(p, "a key is not in line with the others")
    END;
    IF (Ch() = "-") & ((p + 1 >= end) OR Blank(t[p + 1]) OR (t[p + 1] = LF)) THEN
      (* a sequence: skipped *)
      WHILE (p < end) & (t[p] # LF) DO INC(p) END;
      SkipDeeper(ind)
    ELSE
      key := Key(FALSE);
      SkipBlanks;
      at := p; done := FALSE;  (* done: p is at a line's start *)
      IF (Ch() = LF) OR (Ch() = "#") OR (p >= end) THEN
        WHILE (p < end) & (t[p] # LF) DO INC(p) END;
        IF p < end THEN INC(p) END;
        (* a sequence may stand at the key's own indentation *)
        NextLine; save := p;
        IF (p < end) & (Indent() = ind) & (Ch() = "-") THEN p := save; SkipSequence(ind)
        ELSE p := save; full := Join(prefix, key); BlockMap(full^, ind)
        END;
        done := TRUE
      ELSIF Ch() = "{" THEN INC(p); full := Join(prefix, key); FlowItems(full^, TRUE)
      ELSIF Ch() = "[" THEN SkipFlow
      ELSIF (Ch() = "|") OR (Ch() = ">") THEN
        WHILE (p < end) & (t[p] # LF) DO INC(p) END;
        SkipDeeper(ind); done := TRUE
      ELSE
        IF (Ch() = 22X) OR (Ch() = "'") THEN Quoted ELSE Plain(FALSE) END;
        Add(prefix, key, at)
      END;
      IF ~done THEN
        SkipBlanks;
        IF Ch() = "#" THEN WHILE (p < end) & (t[p] # LF) DO INC(p) END END;
        IF (p < end) & (t[p] # LF) THEN sc.ErrorAt(p, "unexpected text after a value") END;
        IF p < end THEN INC(p) END
      END
    END
  END
END BlockMap;

PROCEDURE Start(s: L.Scanner; from, to: LONGINT);
BEGIN
  sc := s; t := s.t; p := from; end := to; first := NIL; last := NIL
END Start;

(* The block mapping in s's text from from to to, its keys under
   prefix. lineBreaks is as for Flow. *)
PROCEDURE Block*(s: L.Scanner; from, to: LONGINT; lineBreaks: BOOLEAN;
  prefix: ARRAY OF CHAR; VAR list: Pair);
BEGIN
  Start(s, from, to); breaks := lineBreaks;
  BlockMap(prefix, -1);
  list := first
END Block;

(* The flow mapping in s's text from from to to: at "{", or, if braced
   is FALSE, its items without braces. lineBreaks makes a line end in a
   double-quoted string "<br/>", as Mermaid reads a node's metadata.
   Returns where the mapping ended. *)
PROCEDURE Flow*(s: L.Scanner; from, to: LONGINT; braced, lineBreaks: BOOLEAN;
  prefix: ARRAY OF CHAR; VAR list: Pair): LONGINT;
BEGIN
  Start(s, from, to); breaks := lineBreaks;
  IF braced THEN
    SkipSpace;
    IF Ch() # "{" THEN sc.ErrorAt(p, "expected {") END;
    INC(p)
  END;
  FlowItems(prefix, braced);
  list := first;
  RETURN p
END Flow;

(* The last pair named name in list, or NIL *)
PROCEDURE Find*(list: Pair; name: ARRAY OF CHAR): Pair;
  VAR r: Pair;
BEGIN
  r := NIL;
  WHILE list # NIL DO
    IF L.Is(list.name, name) THEN r := list END;
    list := list.next
  END;
  RETURN r
END Find;

(* Appends b to the list a *)
PROCEDURE Append*(VAR a: Pair; b: Pair);
  VAR q: Pair;
BEGIN
  IF a = NIL THEN a := b
  ELSE q := a; WHILE q.next # NIL DO q := q.next END; q.next := b
  END
END Append;

BEGIN
  NEW(buf, 64); bufLen := 0
END PmYaml.
