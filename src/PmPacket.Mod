MODULE PmPacket;
(* PmPacket: Mermaid's packet diagrams (`packet` or `packet-beta`),
   read into rows ("words") of bit fields, each with its first and last
   bit and its label, and the configuration, config.packet.

   The reader follows Mermaid 12.3.0's grammar, packages/parser/src/
   language/packet/packet.langium, and what parser.ts and db.ts make of
   it:

   - blanks, "%%" comments and directives are skipped between tokens;
     line ends are not: each field and each title ends a line;
   - the diagram starts with "packet-beta" or "packet";
   - "title text", "accTitle: text" and "accDescr: text" (or
     "accDescr { text }") may come anywhere; the last title is kept,
     and an empty one is none;
   - a field is "start: label", "start-end: label" or "+bits: label";
     the numbers are 0 or digits that do not start with 0, and the
     label is a string in double or single quotation marks, which may
     span lines, with "\" escapes ("\n", "\t" and the like are blanks
     here, as they are in an SVG text; "\x" is x);
   - a field without a start starts after the last; one with a start
     must start there, its end must not be before its start, and "+0"
     is an error, with Mermaid's messages;
   - fields are split where rows end, bitsPerRow bits a row, each part
     with the field's label; after 10000 rows the rest is left out, as
     Mermaid leaves it out, with a warning.

   The configuration is config.packet's rowHeight (32), bitWidth (32),
   bitsPerRow (32), paddingX (5), paddingY (5), showBits (true) and
   bitOrder ("ascending" or "descending"); with showBits, paddingY is
   10 more, as Mermaid makes it. A number that is not one, or out of
   range, is the default. *)

IMPORT PmIO, L := PmLex, F := PmFlow, Y := PmYaml;

CONST
  (* tokens *)
  tEOF = 0; tNewline = 1; tAccDescr = 2; tAccTitle = 3; tTitle = 4; tKeyword = 5;
  tDash = 6; tPlus = 7; tColon = 8; tInt = 9; tString = 10; tError = 11;

  LF = 0AX; CR = 0DX; TAB = 09X;

  MaxRows* = 10000;        (* Mermaid's maxPacketSize *)
  MaxNumber = 999999999;   (* a field's numbers' largest *)
  MaxBitsPerRow = 100000;

TYPE
  Str = L.Str;

  (* A field, or the part of it in a row *)
  Block* = POINTER TO BlockDesc;
  BlockDesc* = RECORD
    start-, end-: LONGINT;  (* its first and last bit *)
    label-: F.Label;
    text-: Str;             (* its label's text, as read *)
    next-: Block
  END;

  Word* = POINTER TO WordDesc;
  WordDesc* = RECORD
    blocks-: Block;
    nBlocks-: LONGINT;
    next-: Word;
    last: Block
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;                (* the title and the configuration *)
    words-: Word;               (* the rows *)
    nWords-, nFields-: LONGINT;
    rowHeight-, bitWidth-, paddingX-, paddingY-: LONGREAL;
    bitsPerRow-: LONGINT;
    showBits-, descending-: BOOLEAN;
    lastWord: Word
  END;

  Token = RECORD
    kind: INTEGER;
    start, end: LONGINT;  (* its text *)
    a0, a1: LONGINT       (* a title's text *)
  END;

  (* A field as read *)
  Field = POINTER TO FieldDesc;
  FieldDesc = RECORD
    start, end, bits: LONGINT;  (* -1 if not given *)
    text: Str;
    label: F.Label;
    pos: LONGINT;
    next: Field
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  buf: Str;
  fields, lastField: Field;
  textStart: LONGINT;

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

PROCEDURE PutInt(VAR n: LONGINT; k: LONGINT);
  VAR dg: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  IF k < 0 THEN Put(n, "-"); k := -k END;
  i := 0; REPEAT dg[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
  WHILE i > 0 DO DEC(i); Put(n, dg[i]) END
END PutInt;

(* Warns about the text at at: "NAME:LINE:COL: a" *)
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

PROCEDURE IsDigit(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "0") & (ch <= "9")
END IsDigit;

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
   not line ends *)
PROCEDURE Hidden(p: LONGINT): LONGINT;
  VAR e, save: LONGINT;
BEGIN
  LOOP
    IF p >= sc.len THEN EXIT END;
    IF IsBlank(sc.t[p]) THEN INC(p)
    ELSIF At(p, "%%{") THEN
      save := sc.pos; sc.pos := p; e := sc.DirectiveEnd(); sc.pos := save;
      IF e >= 0 THEN p := e ELSE WHILE (p < sc.len) & ~IsLineEnd(sc.t[p]) DO INC(p) END END
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
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      t.kind := tAccDescr; t.end := e; RETURN TRUE
    END;
    e := p + 8; WHILE IsSpace(Ch(e)) DO INC(e) END;
    IF Ch(e) = "{" THEN
      WHILE (e < sc.len) & (sc.t[e] # "}") DO INC(e) END;
      IF e < sc.len THEN t.kind := tAccDescr; t.end := e + 1; RETURN TRUE END
    END;
    RETURN FALSE
  ELSIF At(p, "accTitle") THEN
    e := p + 8; WHILE IsBlank(Ch(e)) DO INC(e) END;
    IF Ch(e) = ":" THEN
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) DO INC(e) END;
      t.kind := tAccTitle; t.end := e; RETURN TRUE
    END;
    RETURN FALSE
  ELSIF At(p, "title") THEN
    e := p + 5; t.kind := tTitle; t.a0 := e; t.a1 := e;
    IF IsBlank(Ch(e)) THEN
      INC(e); t.a0 := e;
      WHILE (e < sc.len) & ~IsLineEnd(sc.t[e]) & ~At(e, "%%") DO INC(e) END;
      t.a1 := e
    END;
    t.end := e; RETURN TRUE
  END;
  RETURN FALSE
END AccOrTitle;

(* The token at p, after what is skipped *)
PROCEDURE Lex(p: LONGINT; VAR t: Token);
  VAR ch, q: CHAR; e: LONGINT;
BEGIN
  p := Hidden(p);
  t.start := p; t.a0 := -1; t.a1 := -1;
  IF p >= sc.len THEN t.kind := tEOF; t.end := p; RETURN END;
  ch := sc.t[p];
  IF ch = LF THEN t.kind := tNewline; t.end := p + 1
  ELSIF (ch = CR) & (Ch(p + 1) = LF) THEN t.kind := tNewline; t.end := p + 2
  ELSIF AccOrTitle(p, t) THEN (* done *)
  ELSIF At(p, "packet-beta") THEN t.kind := tKeyword; t.end := p + 11
  ELSIF At(p, "packet") THEN t.kind := tKeyword; t.end := p + 6
  ELSIF ch = "-" THEN t.kind := tDash; t.end := p + 1
  ELSIF ch = "+" THEN t.kind := tPlus; t.end := p + 1
  ELSIF ch = ":" THEN t.kind := tColon; t.end := p + 1
  ELSIF IsDigit(ch) THEN
    e := p + 1;
    IF ch # "0" THEN WHILE IsDigit(Ch(e)) DO INC(e) END END;
    IF Ch(e) = "." THEN
      (* not an integer *)
      INC(e); WHILE IsDigit(Ch(e)) DO INC(e) END;
      t.kind := tError; t.end := e
    ELSE t.kind := tInt; t.end := e
    END
  ELSIF (ch = '"') OR (ch = "'") THEN
    q := ch; e := p + 1;
    WHILE (e < sc.len) & (sc.t[e] # q) DO
      IF (sc.t[e] = "\") & (e + 1 < sc.len) THEN INC(e) END;
      INC(e)
    END;
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
  | tNewline: PutS(n, ", not the end of the line")
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

(* An integer token's value *)
PROCEDURE Int(VAR t: Token): LONGINT;
  VAR k, x, n: LONGINT;
BEGIN
  x := 0;
  FOR k := t.start TO t.end - 1 DO
    IF x > (MaxNumber - (ORD(sc.t[k]) - ORD("0"))) DIV 10 THEN
      n := 0; PutS(n, "the number "); PutText(n, t.start, t.end);
      PutS(n, " is too large"); buf[n] := 0X;
      sc.ErrorAt(t.start, buf^)
    END;
    x := x * 10 + (ORD(sc.t[k]) - ORD("0"))
  END;
  RETURN x
END Int;

(* A string token's text, without its quotation marks, its escapes
   undone, in f *)
PROCEDURE Label(VAR t: Token; f: Field);
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
  f.text := L.Sub(buf^, 0, n);
  f.label := F.TextLabel(buf^, 0, n)
END Label;

(* The line's end, or the text's, after a field or a title *)
PROCEDURE Eol(VAR p: LONGINT);
  VAR t: Token;
BEGIN
  Lex(p, t);
  IF (t.kind # tNewline) & (t.kind # tEOF) THEN Unexpected(t, "the end of the line") END;
  p := t.end
END Eol;

(* A field at p *)
PROCEDURE ReadField(VAR p: LONGINT);
  VAR t: Token; f: Field;
BEGIN
  NEW(f); f.start := -1; f.end := -1; f.bits := -1; f.next := NIL;
  Lex(p, t); f.pos := t.start;
  IF t.kind = tInt THEN
    f.start := Int(t); p := t.end; Lex(p, t);
    IF t.kind = tDash THEN
      Lex(t.end, t);
      IF t.kind # tInt THEN Unexpected(t, "a number") END;
      f.end := Int(t); p := t.end; Lex(p, t)
    END
  ELSE (* tPlus *)
    Lex(t.end, t);
    IF t.kind # tInt THEN Unexpected(t, "a number") END;
    f.bits := Int(t); p := t.end; Lex(p, t)
  END;
  IF t.kind # tColon THEN Unexpected(t, "':'") END;
  Lex(t.end, t);
  IF t.kind # tString THEN Unexpected(t, "a string") END;
  Label(t, f); p := t.end;
  Eol(p);
  IF fields = NIL THEN fields := f ELSE lastField.next := f END;
  lastField := f
END ReadField;

(* The rows *)

PROCEDURE PushWord(w: Word);
BEGIN
  IF w.blocks # NIL THEN
    IF d.words = NIL THEN d.words := w ELSE d.lastWord.next := w END;
    d.lastWord := w; INC(d.nWords)
  END
END PushWord;

PROCEDURE NewWord(): Word;
  VAR w: Word;
BEGIN
  NEW(w); w.blocks := NIL; w.last := NIL; w.nBlocks := 0; w.next := NIL;
  RETURN w
END NewWord;

PROCEDURE AddBlock(w: Word; start, end: LONGINT; f: Field);
  VAR b: Block;
BEGIN
  NEW(b); b.start := start; b.end := end; b.label := f.label; b.text := f.text; b.next := NIL;
  IF w.blocks = NIL THEN w.blocks := b ELSE w.last.next := b END;
  w.last := b; INC(w.nBlocks)
END AddBlock;

(* The fields made rows, as parser.ts's populate makes them *)
PROCEDURE Populate;
  VAR f: Field; lastBit, row, start, end, n, rowEnd: LONGINT; w: Word; warned: BOOLEAN;
BEGIN
  lastBit := -1; row := 1; w := NewWord(); warned := FALSE;
  f := fields;
  WHILE f # NIL DO
    IF (f.start >= 0) & (f.end >= 0) & (f.end < f.start) THEN
      n := 0; PutS(n, "Packet block "); PutInt(n, f.start); PutS(n, " - "); PutInt(n, f.end);
      PutS(n, " is invalid. End must be greater than start."); buf[n] := 0X;
      sc.ErrorAt(f.pos, buf^)
    END;
    IF f.start < 0 THEN f.start := lastBit + 1 END;
    IF f.start # lastBit + 1 THEN
      n := 0; PutS(n, "Packet block "); PutInt(n, f.start); PutS(n, " - ");
      IF f.end >= 0 THEN PutInt(n, f.end) ELSE PutInt(n, f.start) END;
      PutS(n, " is not contiguous. It should start from "); PutInt(n, lastBit + 1);
      PutS(n, "."); buf[n] := 0X;
      sc.ErrorAt(f.pos, buf^)
    END;
    IF f.bits = 0 THEN
      n := 0; PutS(n, "Packet block "); PutInt(n, f.start);
      PutS(n, " is invalid. Cannot have a zero bit field."); buf[n] := 0X;
      sc.ErrorAt(f.pos, buf^)
    END;
    IF f.end < 0 THEN
      IF f.bits > 0 THEN f.end := f.start + f.bits - 1 ELSE f.end := f.start END
    END;
    lastBit := f.end;
    start := f.start; end := f.end;
    LOOP
      IF d.nWords >= MaxRows THEN
        IF ~warned THEN
          Warn(f.pos, "more than 10000 rows: the rest is left out, as Mermaid leaves it out");
          warned := TRUE
        END;
        EXIT
      END;
      rowEnd := row * d.bitsPerRow - 1;
      IF end <= rowEnd THEN
        AddBlock(w, start, end, f);
        IF end = rowEnd THEN PushWord(w); w := NewWord(); INC(row) END;
        EXIT
      END;
      AddBlock(w, start, rowEnd, f);
      PushWord(w); w := NewWord(); INC(row);
      start := rowEnd + 1
    END;
    INC(d.nFields);
    f := f.next
  END;
  PushWord(w)
END Populate;

(* The configuration *)

(* config.packet.name, a number, or default *)
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

(* A length, config.packet.name, not negative, or default *)
PROCEDURE Length(name: ARRAY OF CHAR; default: LONGREAL): LONGREAL;
  VAR x: LONGREAL;
BEGIN
  x := Conf(name, default);
  IF (x < 0) OR (x > 1.0D6) THEN x := default END;
  RETURN x
END Length;

PROCEDURE Configure;
  VAR q: Y.Pair; x: LONGREAL;
BEGIN
  d.rowHeight := Length("config.packet.rowHeight", 32);
  d.bitWidth := Length("config.packet.bitWidth", 32);
  d.paddingX := Length("config.packet.paddingX", 5);
  d.paddingY := Length("config.packet.paddingY", 5);
  x := Conf("config.packet.bitsPerRow", 32);
  IF (x < 1) OR (x > MaxBitsPerRow) OR (x # ENTIER(x)) THEN
    q := Y.Find(d.g.config, "config.packet.bitsPerRow");
    Warn(q.pos, "bitsPerRow must be a whole number from 1 to 100000: it is 32");
    x := 32
  END;
  d.bitsPerRow := ENTIER(x);
  q := Y.Find(d.g.config, "config.packet.showBits");
  d.showBits := (q = NIL) OR ~L.Is(q.value, "false");
  IF d.showBits THEN d.paddingY := d.paddingY + 10 END;
  q := Y.Find(d.g.config, "config.packet.bitOrder");
  d.descending := (q # NIL) & L.Is(q.value, "descending")
END Configure;

(* Whether the scanner's text, after front matter and comments, starts
   with "packet" *)
PROCEDURE IsPacket*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("packet");
  s.pos := save;
  RETURN r
END IsPacket;

(* Reads the packet diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR p, n: LONGINT; t: Token;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Packet, d.g); sc := s;
  d.words := NIL; d.lastWord := NIL; d.nWords := 0; d.nFields := 0;
  fields := NIL; lastField := NIL;
  textStart := sc.pos;
  Configure;
  p := sc.pos;
  REPEAT Lex(p, t); p := t.end UNTIL t.kind # tNewline;
  IF t.kind # tKeyword THEN Unexpected(t, "packet") END;
  LOOP
    Lex(p, t);
    CASE t.kind OF
      tEOF: EXIT
    | tNewline: p := t.end
    | tTitle:
        n := t.a1; WHILE (n > t.a0) & IsBlank(sc.t[n - 1]) DO DEC(n) END;
        WHILE (t.a0 < n) & IsBlank(sc.t[t.a0]) DO INC(t.a0) END;
        IF n > t.a0 THEN d.g.title := F.TextLabel(sc.t^, t.a0, n) ELSE d.g.title := NIL END;
        p := t.end; Eol(p)
    | tAccTitle, tAccDescr: p := t.end; Eol(p)
    | tInt, tPlus: ReadField(p)
    ELSE Unexpected(t, "a field, a title or the end of the line")
    END
  END;
  Populate;
  fields := NIL; lastField := NIL;
  sc.pos := sc.len
END Read;

BEGIN
  NEW(buf, 256)
END PmPacket.
