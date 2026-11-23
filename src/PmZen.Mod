MODULE PmZen;
(* PmZen: ZenUML's sequence diagrams (`zenuml`, Mermaid's plugin
   @mermaid-js/mermaid-zenuml), read into PmSeq's model, which
   PmSeqLayout and the writers draw.

   The text after "zenuml" is read as @zenuml/core's lexer and parser,
   sequenceLexer.g4 and sequenceParser.g4, read it, and its meaning is
   theirs (From.ts, Owner.js, Origin.js, RetContext.js, ToCollector.js
   and OrderedParticipants.ts):

   - blanks and line ends separate tokens; "const", "readonly",
     "static" and "await" are skipped; "//" to the line's end is a
     comment, kept for the statement after it; a line whose first
     characters, after blanks, are "==" is a divider;
   - "title" at the start, not followed by ".", "=" or "(", takes the
     rest of its line as the diagram's title;
   - ":" takes the rest of its line as a message's text;
   - the head: participants, "@Type <<stereotype>> [emoji] name width
     as label #colour", and "group name { participants }", then
     "@Starter(name)"; a name starts a participant unless "->", "-->",
     ".", ":", "=", "(", "-", "{", "," or ";" follows it;
   - the statements: sync messages, "A.m(x)", "A->B.m(x)", "m(x)",
     with an assignment, "type x = ...", and a block, "{ ... }", or
     ";"; async messages, "A->B: text", "B: text"; creations, "x = new
     A(params)"; returns, "return expr", "@return A->B: text", "A-->B:
     text"; "if (c) { } else if (c) { } else { }"; "par", "opt" and
     "critical", each "(c) { }"; "while", "for", "foreach", "forEach"
     and "loop", "(c) { }"; "section (text) { }" or "frame", or a bare
     "{ }"; "try { } catch (e) { } finally { }"; "ref(text,
     participants)".

   Texts are made as ZenUML's getFormattedText makes them, from the
   source: line ends and runs of blanks become one blank, blanks
   around ",", ";" and "." and around "(", and before ")", go, and one
   pair of quotation marks around the whole is taken off.

   A message's sender, if it names none, is the receiver of the
   message, or creation, whose block it is in, or else the starter; a
   return goes back to the sender of the message or creation it is
   in. The starter is "@Starter"'s, or else an unnamed person put
   first, when a message needs it or there is nothing else to draw.
   The participants are in the order they are first named: the head's,
   the starter, and then, in order, each message's sender and receiver,
   each creation's participant, each "ref"'s and each return's.

   pomermaid's drawing is Mermaid's sequence diagram's (decisions 64
   to 70): a sync message is a solid line with a filled head and
   activates its receiver for its block; an async message has an open
   head; creations and returns are dashed with an open head; a sync
   message or creation with an assignment returns its assignee; the
   fragments are Mermaid's blocks, "try" and "section" PmSeq's own;
   "ref" is a block around a note over its participants; a divider is a
   note across the diagram, and a comment a note over its statement's
   participants. What ZenUML leaves to its editor, an unfinished
   statement drawn with a placeholder, stops pomermaid with an error. *)

IMPORT L := PmLex, F := PmFlow, Q := PmSeq;

CONST
  LF = 0AX; CR = 0DX; Tab = 09X;

  (* tokens *)
  tEOF = 0; tName = 1; tString = 2; tInt = 3; tNum = 4; tAnnot = 5; tStarter = 6;
  tAnnotRet = 7; tPayload = 8; tTitle = 9; tDivider = 10; tColor = 11;
  tArrow = 12; tRetArrow = 13; tColon = 14; tSOpen = 15; tSClose = 16;
  tLBrack = 17; tRBrack = 18; tOp = 19; tMinus = 20; tSemi = 21; tComma = 22;
  tAssign = 23; tLPar = 24; tRPar = 25; tLBrace = 26; tRBrace = 27; tDot = 28;
  tOther = 29; tLt = 30; tGt = 31;

  (* statements *)
  sSync = 0; sAsync = 1; sCreate = 2; sRet = 3; sDivider = 4; sFrag = 5; sRef = 6;

  (* returns *)
  rPlain = 0; rArrow = 1; rAnnot = 2;

TYPE
  Str = L.Str;

  Token = RECORD
    kind: INTEGER;
    start, end: LONGINT;  (* its text, t[start .. end-1]: a payload's
                             and a title's are what follows ":" and
                             "title" *)
    nl: BOOLEAN;          (* a line end before it *)
    comment: Str          (* the comments just before it, or NIL *)
  END;
  Tokens = POINTER TO ARRAY OF Token;

  Name = POINTER TO NameDesc;
  NameDesc = RECORD s: Str; next: Name END;

  Stat = POINTER TO StatDesc;

  Branch = POINTER TO BranchDesc;
  BranchDesc = RECORD
    text: Str;            (* its condition, or NIL *)
    body: Stat;
    next: Branch
  END;

  StatDesc = RECORD
    kind: INTEGER;        (* sSync ... *)
    frag: INTEGER;        (* a fragment's block, Q.Alt ... *)
    ret: INTEGER;         (* a return's form, rPlain ... *)
    from, to: Str;        (* those named, or NIL *)
    text: Str;            (* a message's, a condition, a divider's *)
    assignee, type: Str;  (* an assignment's, or NIL *)
    body: Stat;           (* a message's or creation's block; a
                             fragment's first *)
    branches: Branch;     (* a fragment's others *)
    names: Name;          (* ref's participants *)
    comment: Str;
    pos: LONGINT;
    next: Stat
  END;

  Part = POINTER TO PartDesc;
  PartDesc = RECORD
    name, label, stereo, type: Str;
    box: Q.Box;
    starter: BOOLEAN;     (* the unnamed starter *)
    actor: Q.Actor;
    next: Part
  END;

VAR
  sc: L.Scanner;
  d: Q.Diagram;
  tk: Tokens; nTk, p: LONGINT;
  comment: Str;           (* the comments not yet given to a token *)
  buf: Str; bufN: LONGINT;
  parts, lastPart: Part;
  starter: Str;           (* @Starter's, or NIL *)
  missFrom: BOOLEAN;      (* a message with no sender *)
  nMsgs: LONGINT;
  defStarter: Q.Actor;

(* Text *)

PROCEDURE Put(ch: CHAR);
  VAR n: Str; i: LONGINT;
BEGIN
  IF bufN + 1 >= LEN(buf^) THEN
    NEW(n, 2 * LEN(buf^));
    FOR i := 0 TO bufN - 1 DO n[i] := buf[i] END;
    buf := n
  END;
  buf[bufN] := ch; INC(bufN)
END Put;

PROCEDURE PutS(s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(s[i]); INC(i) END
END PutS;

PROCEDURE Take(): Str;
  VAR r: Str;
BEGIN
  r := L.Sub(buf^, 0, bufN); bufN := 0;
  RETURN r
END Take;

PROCEDURE IsSpace(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch = " ") OR (ch = Tab) OR (ch = LF) OR (ch = CR) OR (ch = 0BX) OR (ch = 0CX)
END IsSpace;

PROCEDURE Tight(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch = ",") OR (ch = ";") OR (ch = ".") OR (ch = "(")
END Tight;

(* sc's t[start .. end-1] as ZenUML's formatText makes it; NIL if it is
   empty *)
PROCEDURE Format(start, end: LONGINT): Str;
  VAR i, k, n: LONGINT; s: Str; ch: CHAR;
BEGIN
  bufN := 0; i := start;
  WHILE i < end DO
    ch := sc.t[i];
    IF IsSpace(ch) THEN
      WHILE (i < end) & IsSpace(sc.t[i]) DO INC(i) END;
      Put(" ")
    ELSE Put(ch); INC(i)
    END
  END;
  s := Take();
  (* blanks around ",", ";", ".", "(", and before ")" *)
  n := L.Length(s^); k := 0;
  FOR i := 0 TO n - 1 DO
    IF (s[i] = " ") & ((k > 0) & Tight(buf[k - 1]) OR (i + 1 < n) & (Tight(s[i + 1]) OR (s[i + 1] = ")"))) THEN
    ELSE Put(s[i]); INC(k)
    END
  END;
  WHILE (bufN > 0) & (buf[bufN - 1] = " ") DO DEC(bufN) END;
  IF (bufN > 0) & (buf[0] = " ") THEN   (* not drawn: HTML's *)
    FOR i := 1 TO bufN - 1 DO buf[i - 1] := buf[i] END;
    DEC(bufN)
  END;
  IF (bufN >= 2) & (buf[0] = '"') & (buf[bufN - 1] = '"') THEN
    s := L.Sub(buf^, 1, bufN - 2); bufN := 0
  ELSE s := Take()
  END;
  IF s[0] = 0X THEN s := NIL END;
  RETURN s
END Format;

(* s, without blanks at either end *)
PROCEDURE Trim(s: Str): Str;
  VAR i, j: LONGINT;
BEGIN
  i := 0; j := L.Length(s^);
  WHILE (i < j) & IsSpace(s[i]) DO INC(i) END;
  WHILE (j > i) & IsSpace(s[j - 1]) DO DEC(j) END;
  RETURN L.Sub(s^, i, j - i)
END Trim;

(* s without a "[style]" at its start, as ZenUML draws comments and
   dividers *)
PROCEDURE Unstyle(s: Str): Str;
  VAR i: LONGINT;
BEGIN
  IF (s # NIL) & (s[0] = "[") THEN
    i := 1;
    WHILE (s[i] # 0X) & (s[i] # "]") & (s[i] # LF) DO INC(i) END;
    IF s[i] = "]" THEN s := Trim(L.Sub(s^, i + 1, L.Length(s^) - i - 1)) END
  END;
  RETURN s
END Unstyle;

PROCEDURE Cat3(a: Str; b: ARRAY OF CHAR; c: Str): Str;
BEGIN
  bufN := 0;
  IF a # NIL THEN PutS(a^) END;
  PutS(b);
  IF c # NIL THEN PutS(c^) END;
  RETURN Take()
END Cat3;

(* A label of s's lines, as they are: no entities, no markdown *)
PROCEDURE Label(s: Str): F.Label;
  VAR lab: F.Label; ln, last: F.Line; i, j: LONGINT;
BEGIN
  NEW(lab); lab.lines := NIL; lab.n := 0; lab.markdown := FALSE; last := NIL;
  IF s = NIL THEN s := L.New("") END;
  i := 0;
  LOOP
    j := i;
    WHILE (s[j] # 0X) & (s[j] # LF) DO INC(j) END;
    NEW(ln); ln.text := L.Sub(s^, i, j - i); ln.style := NIL; ln.underline := FALSE; ln.next := NIL;
    IF last = NIL THEN lab.lines := ln ELSE last.next := ln END;
    last := ln; INC(lab.n);
    IF s[j] = 0X THEN EXIT END;
    i := j + 1
  END;
  RETURN lab
END Label;

(* The lexer *)

PROCEDURE Add(kind: INTEGER; start, end: LONGINT; nl: BOOLEAN);
  VAR n: Tokens; i: LONGINT;
BEGIN
  IF nTk = LEN(tk^) THEN
    NEW(n, 2 * LEN(tk^));
    FOR i := 0 TO nTk - 1 DO n[i] := tk[i] END;
    tk := n
  END;
  tk[nTk].kind := kind; tk[nTk].start := start; tk[nTk].end := end;
  tk[nTk].nl := nl; tk[nTk].comment := comment;
  comment := NIL; INC(nTk)
END Add;

(* Adds the comment t[start .. end-1], "//" and all, to those waiting *)
PROCEDURE AddComment(start, end: LONGINT);
  VAR s: Str;
BEGIN
  s := Trim(L.Sub(sc.t^, start + 2, end - start - 2));
  IF comment = NIL THEN comment := s ELSE comment := Cat3(comment, 0AX, s) END
END AddComment;

PROCEDURE At(i: LONGINT): CHAR;
BEGIN
  IF i < sc.len THEN RETURN sc.t[i] ELSE RETURN 0X END
END At;

PROCEDURE IsHex(ch: CHAR): BOOLEAN;
BEGIN RETURN L.IsDigit(ch) OR (ch >= "a") & (ch <= "f") OR (ch >= "A") & (ch <= "F")
END IsHex;

PROCEDURE IsNameStart(ch: CHAR): BOOLEAN;
BEGIN RETURN L.IsLetter(ch) OR (ch = "_") OR (ch >= 80X)
END IsNameStart;

(* Whether t[i .. j-1] is w *)
PROCEDURE SrcIs(i, j: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  IF j - i # L.Length(w) THEN RETURN FALSE END;
  FOR k := 0 TO j - i - 1 DO
    IF sc.t[i + k] # w[k] THEN RETURN FALSE END
  END;
  RETURN TRUE
END SrcIs;

(* The text from "from" to the end, as tokens, in tk *)
PROCEDURE Lex(from: LONGINT);
  VAR i, j, k, n: LONGINT; ch: CHAR; seen, nl, start: BOOLEAN;

  PROCEDURE Tok(kind: INTEGER; len: LONGINT);
  BEGIN
    Add(kind, i, i + len, nl); nl := FALSE; seen := TRUE; INC(i, len)
  END Tok;

BEGIN
  NEW(tk, 256); nTk := 0; comment := NIL;
  i := from; n := sc.len; seen := FALSE; nl := FALSE;
  WHILE i < n DO
    ch := sc.t[i];
    start := (i = from) OR (sc.t[i - 1] = LF) OR (sc.t[i - 1] = CR);
    j := i;
    IF start THEN
      WHILE (j < n) & ((sc.t[j] = " ") OR (sc.t[j] = Tab)) DO INC(j) END
    END;
    IF start & (At(j) = "=") & (At(j + 1) = "=") THEN
      k := j;
      WHILE (k < n) & (sc.t[k] # LF) & (sc.t[k] # CR) DO INC(k) END;
      Add(tDivider, j, k, nl); nl := FALSE; seen := TRUE; i := k
    ELSIF (ch = LF) OR (ch = CR) THEN nl := TRUE; INC(i)
    ELSIF (ch = " ") OR (ch = Tab) THEN INC(i)
    ELSIF (ch = "/") & (At(i + 1) = "/") THEN
      k := i;
      WHILE (k < n) & (sc.t[k] # LF) & (sc.t[k] # CR) DO INC(k) END;
      AddComment(i, k); i := k
    ELSIF IsNameStart(ch) THEN
      j := i;
      WHILE (j < n) & L.IsWordChar(sc.t[j]) DO INC(j) END;
      IF SrcIs(i, j, "const") OR SrcIs(i, j, "readonly") OR SrcIs(i, j, "static")
        OR SrcIs(i, j, "await") THEN
        i := j
      ELSIF ~seen & SrcIs(i, j, "title") THEN
        k := j;
        WHILE (k < n) & ((sc.t[k] = " ") OR (sc.t[k] = Tab)) DO INC(k) END;
        IF (At(k) = ".") OR (At(k) = "=") OR (At(k) = "(") THEN Tok(tName, j - i)
        ELSE
          k := j;
          WHILE (k < n) & (sc.t[k] # LF) & (sc.t[k] # CR) DO INC(k) END;
          Add(tTitle, j, k, nl); nl := FALSE; seen := TRUE; i := k
        END
      ELSE Tok(tName, j - i)
      END
    ELSIF L.IsDigit(ch) THEN
      j := i;
      WHILE (j < n) & L.IsDigit(sc.t[j]) DO INC(j) END;
      IF (j < n) & IsNameStart(sc.t[j]) THEN
        WHILE (j < n) & L.IsWordChar(sc.t[j]) DO INC(j) END;
        Tok(tName, j - i)
      ELSIF At(j) = "." THEN
        INC(j);
        WHILE (j < n) & L.IsWordChar(sc.t[j]) DO INC(j) END;
        Tok(tNum, j - i)
      ELSE Tok(tInt, j - i)
      END
    ELSIF (ch = ".") & L.IsDigit(At(i + 1)) THEN
      j := i + 1;
      WHILE (j < n) & L.IsWordChar(sc.t[j]) DO INC(j) END;
      Tok(tNum, j - i)
    ELSIF ch = "@" THEN
      j := i + 1;
      WHILE (j < n) & (L.IsLetter(sc.t[j]) OR L.IsDigit(sc.t[j]) OR (sc.t[j] = "_")) DO INC(j) END;
      IF SrcIs(i, j, "@Starter") OR SrcIs(i, j, "@starter") THEN Tok(tStarter, j - i)
      ELSIF SrcIs(i, j, "@Return") OR SrcIs(i, j, "@return") OR SrcIs(i, j, "@Reply")
        OR SrcIs(i, j, "@reply") THEN
        Tok(tAnnotRet, j - i)
      ELSE Tok(tAnnot, j - i)
      END
    ELSIF ch = '"' THEN
      j := i + 1;
      LOOP
        IF (j >= n) OR (sc.t[j] = LF) OR (sc.t[j] = CR) THEN
          sc.ErrorAt(i, "a string has no closing quotation mark")
        ELSIF sc.t[j] = '"' THEN
          IF At(j + 1) = '"' THEN INC(j, 2) ELSE INC(j); EXIT END
        ELSE INC(j)
        END
      END;
      Tok(tString, j - i)
    ELSIF (ch = "#") & IsHex(At(i + 1)) THEN
      j := i + 1;
      WHILE (j < n) & IsHex(sc.t[j]) DO INC(j) END;
      Tok(tColor, j - i)
    ELSIF ch = "-" THEN
      IF (At(i + 1) = "-") & (At(i + 2) = ">") THEN Tok(tRetArrow, 3)
      ELSIF At(i + 1) = ">" THEN Tok(tArrow, 2)
      ELSE Tok(tMinus, 1)
      END
    ELSIF ch = "<" THEN
      IF At(i + 1) = "<" THEN Tok(tSOpen, 2)
      ELSIF At(i + 1) = "=" THEN Tok(tOp, 2)
      ELSE Tok(tLt, 1)
      END
    ELSIF ch = ">" THEN
      IF At(i + 1) = ">" THEN Tok(tSClose, 2)
      ELSIF At(i + 1) = "=" THEN Tok(tOp, 2)
      ELSE Tok(tGt, 1)
      END
    ELSIF ch = "=" THEN
      IF At(i + 1) = "=" THEN Tok(tOp, 2) ELSE Tok(tAssign, 1) END
    ELSIF ch = "!" THEN
      IF At(i + 1) = "=" THEN Tok(tOp, 2) ELSE Tok(tOp, 1) END
    ELSIF (ch = "|") & (At(i + 1) = "|") OR (ch = "&") & (At(i + 1) = "&") THEN Tok(tOp, 2)
    ELSIF (ch = "+") OR (ch = "*") OR (ch = "/") OR (ch = "%") OR (ch = "^") THEN Tok(tOp, 1)
    ELSIF (ch = "$") & L.IsDigit(At(i + 1)) THEN
      j := i + 1;
      WHILE (j < n) & (L.IsDigit(sc.t[j]) OR (sc.t[j] = ".")) DO INC(j) END;
      Tok(tNum, j - i)
    ELSIF ch = ":" THEN
      Tok(tColon, 1);
      k := i;
      WHILE (k < n) & (sc.t[k] # LF) & (sc.t[k] # CR) DO INC(k) END;
      IF k > i THEN Add(tPayload, i, k, FALSE); i := k END
    ELSIF ch = "[" THEN Tok(tLBrack, 1)
    ELSIF ch = "]" THEN Tok(tRBrack, 1)
    ELSIF ch = ";" THEN Tok(tSemi, 1)
    ELSIF ch = "," THEN Tok(tComma, 1)
    ELSIF ch = "(" THEN Tok(tLPar, 1)
    ELSIF ch = ")" THEN Tok(tRPar, 1)
    ELSIF ch = "{" THEN Tok(tLBrace, 1)
    ELSIF ch = "}" THEN Tok(tRBrace, 1)
    ELSIF ch = "." THEN Tok(tDot, 1)
    ELSE Tok(tOther, 1)
    END
  END;
  Add(tEOF, n, n, TRUE)
END Lex;

(* The parser *)

PROCEDURE K(): INTEGER;
BEGIN RETURN tk[p].kind
END K;

PROCEDURE KAt(i: LONGINT): INTEGER;
BEGIN
  IF i < nTk THEN RETURN tk[i].kind ELSE RETURN tEOF END
END KAt;

(* Whether token i is the word w *)
PROCEDURE IsW(i: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN (i < nTk) & (tk[i].kind = tName) & SrcIs(tk[i].start, tk[i].end, w)
END IsW;

PROCEDURE IsKeyword(i: LONGINT): BOOLEAN;
BEGIN
  RETURN IsW(i, "if") OR IsW(i, "else") OR IsW(i, "while") OR IsW(i, "for") OR IsW(i, "foreach")
    OR IsW(i, "forEach") OR IsW(i, "loop") OR IsW(i, "return") OR IsW(i, "new") OR IsW(i, "par")
    OR IsW(i, "group") OR IsW(i, "opt") OR IsW(i, "critical") OR IsW(i, "section")
    OR IsW(i, "frame") OR IsW(i, "ref") OR IsW(i, "as") OR IsW(i, "try") OR IsW(i, "catch")
    OR IsW(i, "finally") OR IsW(i, "true") OR IsW(i, "false") OR IsW(i, "nil")
    OR IsW(i, "null") OR IsW(i, "in")
END IsKeyword;

(* Whether token i is a name: a word that is not a keyword, or a string *)
PROCEDURE IsName(i: LONGINT): BOOLEAN;
BEGIN
  RETURN (KAt(i) = tName) & ~IsKeyword(i) OR (KAt(i) = tString)
END IsName;

PROCEDURE Err(msg: ARRAY OF CHAR);
BEGIN
  sc.ErrorAt(tk[p].start, msg)
END Err;

PROCEDURE Expect(kind: INTEGER; msg: ARRAY OF CHAR);
BEGIN
  IF K() # kind THEN Err(msg) END;
  INC(p)
END Expect;

(* The name at p, after an emoji, "[name]", if there is one, taken *)
PROCEDURE TakeName(msg: ARRAY OF CHAR): Str;
  VAR s: Str;
BEGIN
  IF (K() = tLBrack) & IsName(p + 1) & (KAt(p + 2) = tRBrack) THEN INC(p, 3) END;
  IF ~IsName(p) THEN Err(msg) END;
  s := Format(tk[p].start, tk[p].end); INC(p);
  IF s = NIL THEN s := L.New("") END;
  RETURN s
END TakeName;

(* p is after "("; the tokens to the ")" that matches it are passed
   over, and p is left at that ")". Returns where they start and end
   in the text. *)
PROCEDURE Balanced(VAR start, end: LONGINT);
  VAR depth: INTEGER; open: LONGINT;
BEGIN
  open := p - 1; depth := 0; start := tk[p].start; end := start;
  LOOP
    CASE K() OF
      tEOF: sc.ErrorAt(tk[open].start, 'a "(" has no ")"')
    | tLPar: INC(depth)
    | tRPar: IF depth = 0 THEN EXIT END; DEC(depth)
    ELSE
    END;
    end := tk[p].end; INC(p)
  END
END Balanced;

(* "(condition)", formatted; NIL if empty *)
PROCEDURE ParExpr(): Str;
  VAR start, end: LONGINT; s: Str;
BEGIN
  Expect(tLPar, 'expected "("');
  Balanced(start, end); s := Format(start, end); INC(p);
  RETURN s
END ParExpr;

(* The parameters in t[start .. end-1], as ZenUML writes a creation's:
   each formatted, "name = value" as "name=value", "type name" as it
   is; joined by "," *)
PROCEDURE Params(open: LONGINT): Str;
  VAR depth: INTEGER; i, first, n: LONGINT; out: Str; s, v: Str;

  PROCEDURE One(a, b: LONGINT);   (* tokens a .. b-1 *)
  BEGIN
    IF a >= b THEN RETURN END;
    IF (b - a >= 2) & (tk[a].kind = tName) & (tk[a + 1].kind = tAssign) THEN
      v := Format(tk[a + 2].start, tk[b - 1].end);
      IF b - a = 2 THEN v := NIL END;
      s := Cat3(L.Sub(sc.t^, tk[a].start, tk[a].end - tk[a].start), "=", v)
    ELSIF (b - a = 2) & IsName(a) & IsName(a + 1) THEN
      s := Cat3(L.Sub(sc.t^, tk[a].start, tk[a].end - tk[a].start), " ",
        L.Sub(sc.t^, tk[a + 1].start, tk[a + 1].end - tk[a + 1].start))
    ELSE s := Format(tk[a].start, tk[b - 1].end)
    END;
    IF s # NIL THEN
      IF n > 0 THEN out := Cat3(out, ",", s) ELSE out := s END;
      INC(n)
    END
  END One;

BEGIN
  n := 0; out := NIL; depth := 0;
  i := open + 1; first := i;
  LOOP
    IF tk[i].kind = tEOF THEN EXIT
    ELSIF tk[i].kind = tLPar THEN INC(depth)
    ELSIF tk[i].kind = tRPar THEN
      IF depth = 0 THEN EXIT END;
      DEC(depth)
    ELSIF (tk[i].kind = tComma) & (depth = 0) THEN One(first, i); first := i + 1
    END;
    INC(i)
  END;
  One(first, i);
  RETURN out
END Params;

PROCEDURE ^ Block(): Stat;

PROCEDURE NewStat(kind: INTEGER): Stat;
  VAR s: Stat;
BEGIN
  NEW(s); s.kind := kind; s.frag := 0; s.ret := rPlain; s.from := NIL; s.to := NIL;
  s.text := NIL; s.assignee := NIL; s.type := NIL; s.body := NIL; s.branches := NIL;
  s.names := NIL; s.comment := NIL; s.pos := tk[p].start; s.next := NIL;
  RETURN s
END NewStat;

PROCEDURE BraceBlock(): Stat;
  VAR b: Stat; open: LONGINT;
BEGIN
  open := p;
  Expect(tLBrace, 'expected "{"');
  b := Block();
  IF K() # tRBrace THEN sc.ErrorAt(tk[open].start, 'a "{" has no "}"') END;
  INC(p);
  RETURN b
END BraceBlock;

PROCEDURE OptBlock(): Stat;
BEGIN
  IF K() = tLBrace THEN RETURN BraceBlock() END;
  RETURN NIL
END OptBlock;

PROCEDURE AddBranch(s: Stat; text: Str; body: Stat);
  VAR b, x: Branch;
BEGIN
  NEW(b); b.text := text; b.body := body; b.next := NIL;
  IF s.branches = NIL THEN s.branches := b
  ELSE x := s.branches; WHILE x.next # NIL DO x := x.next END; x.next := b
  END
END AddBranch;

(* A sync message's methods, "m1(x).m2()", formatted, joined by "." *)
PROCEDURE Func(): Str;
  VAR s, t: Str; start, a, b: LONGINT;
BEGIN
  s := NIL;
  LOOP
    start := p;
    IF (K() = tLBrack) & IsName(p + 1) & (KAt(p + 2) = tRBrack) THEN INC(p, 3) END;
    IF ~IsName(p) THEN Err("expected a method") END;
    INC(p);
    IF K() = tLPar THEN INC(p); Balanced(a, b); INC(p) END;
    t := Format(tk[start].start, tk[p - 1].end);
    IF s = NIL THEN s := t ELSE s := Cat3(s, ".", t) END;
    IF K() # tDot THEN EXIT END;
    INC(p)
  END;
  RETURN s
END Func;

(* The rest of a message, after its block, ";" or nothing *)
PROCEDURE MessageEnd(s: Stat);
BEGIN
  IF K() = tSemi THEN INC(p)
  ELSIF K() = tLBrace THEN s.body := BraceBlock()
  END
END MessageEnd;

(* A return's expression: to ";", "}" or the line's end, outside
   parentheses *)
PROCEDURE Expr(): Str;
  VAR depth: INTEGER; first, start, end: LONGINT;
BEGIN
  depth := 0; first := p; start := tk[p].start; end := start;
  LOOP
    IF (K() = tEOF) OR (depth = 0) & ((K() = tSemi) OR (K() = tRBrace) OR (p > first) & tk[p].nl) THEN
      EXIT
    END;
    IF K() = tLPar THEN INC(depth) ELSIF (K() = tRPar) & (depth > 0) THEN DEC(depth) END;
    end := tk[p].end; INC(p)
  END;
  RETURN Format(start, end)
END Expr;

(* An async message, after "@return": "[from ->] to: text" *)
PROCEDURE AnnotRet(s: Stat);
BEGIN
  s.kind := sRet; s.ret := rAnnot;
  s.to := TakeName("expected a participant");
  IF K() = tArrow THEN
    INC(p); s.from := s.to; s.to := TakeName("expected the participant the message goes to")
  END;
  Expect(tColon, 'expected ":"');
  IF K() = tPayload THEN s.text := Format(tk[p].start, tk[p].end); INC(p) END
END AnnotRet;

(* A message, a creation or a return that starts with a name *)
PROCEDURE Message(s: Stat);
  VAR i, start: LONGINT; n1: Str;
BEGIN
  (* an assignment: "type x =", "x =", "x, y =" *)
  IF IsName(p) & IsName(p + 1) & (KAt(p + 2) = tAssign) THEN
    s.type := Format(tk[p].start, tk[p].end); s.assignee := Format(tk[p + 1].start, tk[p + 1].end);
    INC(p, 3)
  ELSIF IsName(p) & ((KAt(p + 1) = tAssign) OR (KAt(p + 1) = tComma)) THEN
    i := p + 1;
    WHILE (KAt(i) = tComma) & IsName(i + 1) DO INC(i, 2) END;
    IF KAt(i) = tAssign THEN
      s.assignee := Format(tk[p].start, tk[i - 1].end); p := i + 1
    END
  END;
  IF IsW(p, "new") THEN
    s.kind := sCreate; INC(p);
    s.to := TakeName("expected the participant created");
    s.text := NIL;
    IF K() = tLPar THEN
      s.text := Params(p); INC(p); Balanced(i, start); INC(p)
    END;
    IF s.text = NIL THEN s.text := L.New("create") END;
    s.text := Cat3(L.New("«"), "", Cat3(s.text, "»", NIL));
    MessageEnd(s);
    RETURN
  END;
  start := p;
  IF ~IsName(p) & (K() # tLBrack) THEN Err("expected a statement") END;
  n1 := TakeName("expected a participant");
  CASE K() OF
    tArrow:
      INC(p);
      s.from := n1; s.to := TakeName("expected the participant the message goes to");
      IF K() = tDot THEN INC(p); s.kind := sSync; s.text := Func(); MessageEnd(s)
      ELSE
        IF s.assignee # NIL THEN Err('expected "."') END;
        s.kind := sAsync;
        IF K() = tColon THEN
          INC(p);
          IF K() = tPayload THEN s.text := Format(tk[p].start, tk[p].end); INC(p) END
        END
      END
  | tRetArrow:
      IF s.assignee # NIL THEN Err("expected a message") END;
      INC(p); s.kind := sRet; s.ret := rArrow; s.from := n1;
      IF IsName(p) OR (K() = tLBrack) THEN s.to := TakeName("expected a participant") END;
      IF K() = tColon THEN
        INC(p);
        IF K() = tPayload THEN s.text := Format(tk[p].start, tk[p].end); INC(p) END
      END
  | tColon:
      IF s.assignee # NIL THEN Err("expected a message") END;
      INC(p); s.kind := sAsync; s.to := n1;
      IF K() = tPayload THEN s.text := Format(tk[p].start, tk[p].end); INC(p) END
  | tDot:
      INC(p); s.kind := sSync; s.to := n1; s.text := Func(); MessageEnd(s)
  | tMinus:
      Err('expected "->" or "-->"')
  ELSE
    p := start; s.kind := sSync; s.text := Func(); MessageEnd(s)
  END
END Message;

PROCEDURE Statement(): Stat;
  VAR s: Stat; c: Str; text: Str; nm, last: Name; i: LONGINT;
BEGIN
  c := tk[p].comment;
  s := NewStat(sFrag); s.comment := c;
  IF IsW(p, "if") THEN
    s.frag := Q.Alt; INC(p); s.text := ParExpr(); s.body := OptBlock();
    WHILE IsW(p, "else") DO
      INC(p);
      IF IsW(p, "if") THEN INC(p); text := ParExpr(); AddBranch(s, text, OptBlock())
      ELSE AddBranch(s, L.New("else"), OptBlock())
      END
    END
  ELSIF IsW(p, "par") OR IsW(p, "opt") OR IsW(p, "critical") THEN
    IF IsW(p, "par") THEN s.frag := Q.Par ELSIF IsW(p, "opt") THEN s.frag := Q.Opt
    ELSE s.frag := Q.Critical
    END;
    INC(p);
    IF K() = tLPar THEN s.text := ParExpr() END;
    s.body := OptBlock()
  ELSIF IsW(p, "while") OR IsW(p, "for") OR IsW(p, "foreach") OR IsW(p, "forEach")
    OR IsW(p, "loop") THEN
    s.frag := Q.Loop; INC(p);
    IF K() = tLPar THEN s.text := ParExpr() END;
    s.body := OptBlock()
  ELSIF IsW(p, "section") OR IsW(p, "frame") THEN
    s.frag := Q.Frame; INC(p);
    IF K() = tLPar THEN s.text := ParExpr() END;
    s.body := OptBlock()
  ELSIF K() = tLBrace THEN
    s.frag := Q.Frame; s.body := BraceBlock()
  ELSIF IsW(p, "try") THEN
    s.frag := Q.Try; INC(p); s.body := BraceBlock();
    WHILE IsW(p, "catch") DO
      INC(p); text := L.New("catch");
      IF K() = tLPar THEN
        text := Params(p);
        IF text # NIL THEN text := Cat3(L.New("catch"), " ", text) ELSE text := L.New("catch") END;
        INC(p); Balanced(i, i); INC(p)
      END;
      AddBranch(s, text, BraceBlock())
    END;
    IF IsW(p, "finally") THEN INC(p); AddBranch(s, L.New("finally"), BraceBlock()) END
  ELSIF IsW(p, "ref") THEN
    s.kind := sRef; INC(p);
    Expect(tLPar, 'expected "("');
    s.text := TakeName("expected what is referred to"); last := NIL;
    WHILE K() = tComma DO
      INC(p);
      WHILE IsName(p) DO
        NEW(nm); nm.s := L.Sub(sc.t^, tk[p].start, tk[p].end - tk[p].start); nm.next := NIL;
        IF last = NIL THEN s.names := nm ELSE last.next := nm END;
        last := nm; INC(p)
      END
    END;
    Expect(tRPar, 'expected ")"');
    IF K() = tSemi THEN INC(p) END
  ELSIF IsW(p, "return") THEN
    s.kind := sRet; s.ret := rPlain; INC(p);
    s.text := Expr();
    IF K() = tSemi THEN INC(p) END
  ELSIF K() = tAnnotRet THEN
    INC(p); AnnotRet(s)
  ELSIF K() = tDivider THEN
    s.kind := sDivider;
    s.text := Format(tk[p].start, tk[p].end);
    i := 0; WHILE s.text[i] = "=" DO INC(i) END;
    s.text := L.Sub(s.text^, i, L.Length(s.text^) - i);
    i := L.Length(s.text^); WHILE (i > 0) & (s.text[i - 1] = "=") DO DEC(i) END;
    s.text := Unstyle(Trim(L.Sub(s.text^, 0, i)));
    INC(p)
  ELSIF IsName(p) OR (K() = tLBrack) OR IsW(p, "new") THEN Message(s)
  ELSIF K() = tPayload THEN Err("expected a statement")
  ELSE Err("expected a statement")
  END;
  RETURN s
END Statement;

PROCEDURE Block(): Stat;
  VAR first, last, s: Stat;
BEGIN
  first := NIL; last := NIL;
  WHILE (K() # tRBrace) & (K() # tEOF) DO
    s := Statement();
    IF last = NIL THEN first := s ELSE last.next := s END;
    last := s
  END;
  RETURN first
END Block;

(* The participants *)

PROCEDURE FindPart(name: Str): Part;
  VAR q: Part;
BEGIN
  q := parts;
  WHILE (q # NIL) & ~(~q.starter & L.Equal(q.name, name)) DO q := q.next END;
  RETURN q
END FindPart;

PROCEDURE NonEmpty(s: Str): BOOLEAN;
BEGIN RETURN (s # NIL) & (s[0] # 0X)
END NonEmpty;

(* Adds the participant name, or gives it the values it has none of *)
PROCEDURE AddPart(name, label, stereo, type: Str; box: Q.Box);
  VAR q: Part;
BEGIN
  IF ~NonEmpty(name) THEN RETURN END;
  q := FindPart(name);
  IF q = NIL THEN
    NEW(q); q.name := name; q.label := NIL; q.stereo := NIL; q.type := NIL; q.box := NIL;
    q.starter := FALSE; q.actor := NIL; q.next := NIL;
    IF lastPart = NIL THEN parts := q ELSE lastPart.next := q END;
    lastPart := q
  END;
  IF ~NonEmpty(q.label) THEN q.label := label END;
  IF ~NonEmpty(q.stereo) THEN q.stereo := stereo END;
  IF ~NonEmpty(q.type) THEN q.type := type END;
  IF q.box = NIL THEN q.box := box END
END AddPart;

PROCEDURE Mention(s: Str);
BEGIN
  AddPart(s, NIL, NIL, NIL, NIL)
END Mention;

(* Whether a participant starts at token i, in the head *)
PROCEDURE IsParticipant(i: LONGINT): BOOLEAN;
  VAR k: INTEGER;
BEGIN
  IF (KAt(i) = tAnnot) OR (KAt(i) = tSOpen) OR (KAt(i) = tLt) THEN RETURN TRUE END;
  IF (KAt(i) = tLBrack) & IsName(i + 1) & (KAt(i + 2) = tRBrack) THEN INC(i, 3) END;
  IF ~IsName(i) THEN RETURN FALSE END;
  k := KAt(i + 1);
  RETURN (k # tArrow) & (k # tRetArrow) & (k # tDot) & (k # tColon) & (k # tAssign)
    & (k # tLPar) & (k # tMinus) & (k # tLBrace) & (k # tComma) & (k # tSemi)
END IsParticipant;

PROCEDURE Participant(box: Q.Box);
  VAR name, label, stereo, type: Str;
BEGIN
  label := NIL; stereo := NIL; type := NIL;
  IF K() = tAnnot THEN
    type := L.Sub(sc.t^, tk[p].start + 1, tk[p].end - tk[p].start - 1); INC(p)
  END;
  IF (K() = tSOpen) OR (K() = tLt) THEN
    INC(p);
    IF IsName(p) THEN stereo := Format(tk[p].start, tk[p].end); INC(p) END;
    IF (K() = tSClose) OR (K() = tGt) THEN INC(p) END
  END;
  name := TakeName("expected the participant's name");
  IF K() = tInt THEN INC(p) END;
  IF IsW(p, "as") THEN
    INC(p);
    IF IsName(p) THEN label := Format(tk[p].start, tk[p].end); INC(p) END
  END;
  IF K() = tColor THEN INC(p) END;
  AddPart(name, label, stereo, type, box)
END Participant;

PROCEDURE Head;
  VAR box: Q.Box; name: Str;
BEGIN
  LOOP
    IF IsW(p, "group") THEN
      INC(p); name := NIL;
      IF IsName(p) THEN name := Format(tk[p].start, tk[p].end); INC(p) END;
      IF name # NIL THEN box := Q.AddBox(Label(name)) ELSE box := Q.AddBox(NIL) END;
      IF K() = tLBrace THEN
        INC(p);
        WHILE IsParticipant(p) DO Participant(box) END;
        Expect(tRBrace, 'expected "}"')
      END
    ELSIF IsParticipant(p) THEN Participant(NIL)
    ELSE EXIT
    END
  END;
  IF K() = tStarter THEN
    INC(p);
    IF K() = tLPar THEN
      INC(p);
      IF K() # tRPar THEN starter := TakeName("expected the starter") END;
      Expect(tRPar, 'expected ")"')
    END;
    IF starter # NIL THEN Mention(starter) END
  END
END Head;

(* The participants named in s and after it, in order; origin is the
   sender of a message that names none, retTo the receiver of a return
   that names none: NIL for the starter. *)
PROCEDURE Collect(s: Stat; origin, retTo: Str);
  VAR b: Branch; nm: Name; from: Str;
BEGIN
  WHILE s # NIL DO
    CASE s.kind OF
      sSync, sAsync:
        INC(nMsgs);
        IF s.from # NIL THEN Mention(s.from) END;
        IF s.to # NIL THEN Mention(s.to) END;
        IF s.from # NIL THEN from := s.from ELSE from := origin END;
        IF from = NIL THEN missFrom := TRUE END;
        IF s.to # NIL THEN Collect(s.body, s.to, from) ELSE Collect(s.body, origin, from) END
    | sCreate:
        INC(nMsgs);
        IF origin = NIL THEN missFrom := TRUE END;
        IF s.assignee # NIL THEN Mention(Cat3(s.assignee, ":", s.to)) ELSE Mention(s.to) END;
        IF s.assignee # NIL THEN Collect(s.body, Cat3(s.assignee, ":", s.to), origin)
        ELSE Collect(s.body, s.to, origin)
        END
    | sRet:
        INC(nMsgs);
        IF s.from # NIL THEN from := s.from ELSE from := origin END;
        IF from = NIL THEN missFrom := TRUE END;
        IF s.ret # rAnnot THEN
          IF from # NIL THEN Mention(from) END;
          IF s.to # NIL THEN Mention(s.to) ELSIF retTo # NIL THEN Mention(retTo) END
        END;
        IF s.from # NIL THEN Mention(s.from) END;
        IF s.to # NIL THEN Mention(s.to) END
    | sFrag:
        Collect(s.body, origin, retTo);
        b := s.branches;
        WHILE b # NIL DO Collect(b.body, origin, retTo); b := b.next END
    | sRef:
        nm := s.names;
        WHILE nm # NIL DO Mention(nm.s); nm := nm.next END
    | sDivider:
    END;
    s := s.next
  END
END Collect;

(* PmSeq's type for annotation t *)
PROCEDURE Type(t: Str): INTEGER;
  VAR s: ARRAY 32 OF CHAR; i: LONGINT;
BEGIN
  IF t = NIL THEN RETURN Q.Participant END;
  i := 0;
  WHILE (t[i] # 0X) & (i < LEN(s) - 1) DO
    IF (t[i] >= "A") & (t[i] <= "Z") THEN s[i] := CHR(ORD(t[i]) + 32) ELSE s[i] := t[i] END;
    INC(i)
  END;
  s[i] := 0X;
  IF s = "actor" THEN RETURN Q.Person
  ELSIF s = "boundary" THEN RETURN Q.Boundary
  ELSIF s = "control" THEN RETURN Q.Control
  ELSIF s = "entity" THEN RETURN Q.Entity
  ELSIF s = "database" THEN RETURN Q.Database
  ELSIF (s = "collection") OR (s = "collections") THEN RETURN Q.Collections
  ELSIF s = "queue" THEN RETURN Q.Queue
  END;
  RETURN Q.Participant
END Type;

PROCEDURE Actors;
  VAR q: Part; text: Str; nl: ARRAY 2 OF CHAR;
BEGIN
  nl[0] := LF; nl[1] := 0X;
  q := parts;
  WHILE q # NIL DO
    IF q.starter THEN
      q.actor := Q.AddActor(L.New("_STARTER_"), Label(NIL), Q.Person, NIL); defStarter := q.actor
    ELSE
      IF NonEmpty(q.label) THEN text := q.label ELSE text := q.name END;
      IF NonEmpty(q.stereo) THEN text := Cat3(Cat3(Cat3(L.New("«"), "", q.stereo), "»", NIL), nl, text) END;
      q.actor := Q.AddActor(q.name, Label(text), Type(q.type), q.box)
    END;
    q := q.next
  END
END Actors;

(* The events *)

(* The participant named s; NIL is the starter *)
PROCEDURE Actor(s: Str): Q.Actor;
  VAR q: Part;
BEGIN
  IF s = NIL THEN RETURN defStarter END;
  q := FindPart(s);
  ASSERT(q # NIL);
  RETURN q.actor
END Actor;

PROCEDURE Msg(from, to: Q.Actor; text: Str; dotted: BOOLEAN; head: INTEGER): Q.Event;
  VAR e: Q.Event;
BEGIN
  e := Q.AddEvent(Q.Msg); e.from := from; e.to := to; e.dotted := dotted; e.head := head;
  IF text # NIL THEN e.text := Label(text) END;
  RETURN e
END Msg;

PROCEDURE Act(kind: INTEGER; a: Q.Actor);
  VAR e: Q.Event;
BEGIN
  e := Q.AddEvent(kind); e.from := a
END Act;

PROCEDURE NoteOver(a, b: Q.Actor; text: Str): Q.Event;
  VAR e: Q.Event;
BEGIN
  e := Q.AddEvent(Q.Note); e.from := a; e.to := b; e.placement := Q.Over; e.text := Label(text);
  RETURN e
END NoteOver;

(* Whether a is in an event before e *)
PROCEDURE Named(a: Q.Actor; e: Q.Event): BOOLEAN;
  VAR x: Q.Event;
BEGIN
  x := d.events;
  WHILE x # e DO
    IF (x.from = a) OR (x.to = a) THEN RETURN TRUE END;
    x := x.next
  END;
  RETURN FALSE
END Named;

PROCEDURE ^ Events(s: Stat; origin, retTo: Str);

PROCEDURE Event(s: Stat; origin, retTo: Str);
  VAR
    e, note, x: Q.Event; fa, ta: Q.Actor; from, owner, text: Str; b: Branch; nm: Name;
    lo, hi: INTEGER;

  PROCEDURE Span(a: Q.Actor);
  BEGIN
    IF a # NIL THEN
      IF (lo < 0) OR (a.index < lo) THEN lo := a.index END;
      IF a.index > hi THEN hi := a.index END
    END
  END Span;

BEGIN
  note := NIL;
  IF s.comment # NIL THEN text := Unstyle(s.comment);
    note := NoteOver(Actor(origin), Actor(origin), text);
    note.text := F.MarkdownLabel(text^, 0, L.Length(text^)) END;
  CASE s.kind OF
    sSync:
      IF s.from # NIL THEN from := s.from ELSE from := origin END;
      IF s.to # NIL THEN owner := s.to ELSE owner := origin END;
      fa := Actor(from); ta := Actor(owner);
      text := s.text;
      IF (fa = ta) & (s.assignee # NIL) THEN
        IF s.type # NIL THEN text := Cat3(Cat3(s.assignee, ":", s.type), " = ", text)
        ELSE text := Cat3(s.assignee, " = ", text)
        END
      END;
      e := Msg(fa, ta, text, FALSE, Q.Filled); e.activate := TRUE;
      Act(Q.Activate, ta);
      Events(s.body, owner, from);
      IF (fa # ta) & (s.assignee # NIL) THEN
        IF s.type # NIL THEN text := Cat3(s.assignee, ":", s.type) ELSE text := s.assignee END;
        e := Msg(ta, fa, text, TRUE, Q.Open)
      END;
      Act(Q.Deactivate, ta)
  | sCreate:
      IF s.assignee # NIL THEN owner := Cat3(s.assignee, ":", s.to) ELSE owner := s.to END;
      fa := Actor(origin); ta := Actor(owner);
      e := Msg(fa, ta, s.text, TRUE, Q.Open); e.activate := TRUE;
      IF (fa # ta) & ~Named(ta, e) THEN ta.created := e END;
      Act(Q.Activate, ta);
      Events(s.body, owner, origin);
      IF (fa # ta) & (s.assignee # NIL) THEN e := Msg(ta, fa, s.assignee, TRUE, Q.Open) END;
      Act(Q.Deactivate, ta)
  | sAsync:
      IF s.from # NIL THEN from := s.from ELSE from := origin END;
      e := Msg(Actor(from), Actor(s.to), s.text, FALSE, Q.Open)
  | sRet:
      IF s.from # NIL THEN from := s.from ELSE from := origin END;
      IF s.to # NIL THEN owner := s.to ELSE owner := retTo END;
      e := Msg(Actor(from), Actor(owner), s.text, TRUE, Q.Open)
  | sDivider:
      fa := d.actors; WHILE fa.next # NIL DO fa := fa.next END;
      e := NoteOver(d.actors, fa, s.text)
  | sFrag:
      e := Q.AddEvent(Q.BlockStart); e.block := s.frag;
      IF s.text # NIL THEN e.text := Label(s.text) END;
      Events(s.body, origin, retTo);
      b := s.branches;
      WHILE b # NIL DO
        e := Q.AddEvent(Q.Section); e.block := s.frag;
        IF b.text # NIL THEN e.text := Label(b.text) END;
        Events(b.body, origin, retTo);
        b := b.next
      END;
      e := Q.AddEvent(Q.BlockEnd); e.block := s.frag
  | sRef:
      e := Q.AddEvent(Q.BlockStart); e.block := Q.Ref;
      lo := -1; hi := -1;
      nm := s.names;
      WHILE nm # NIL DO Span(Actor(nm.s)); nm := nm.next END;
      IF lo < 0 THEN Span(Actor(origin)) END;
      fa := d.actors; WHILE fa.index # lo DO fa := fa.next END;
      ta := d.actors; WHILE ta.index # hi DO ta := ta.next END;
      e := NoteOver(fa, ta, s.text);
      e := Q.AddEvent(Q.BlockEnd); e.block := Q.Ref
  END;
  IF note # NIL THEN
    (* over a message's participants, or those of the events in a
       fragment *)
    lo := -1; hi := -1; x := note.next;
    WHILE x # NIL DO
      IF (x.kind = Q.Msg) OR (x.kind = Q.Note) THEN Span(x.from); Span(x.to) END;
      IF (s.kind # sFrag) & (s.kind # sRef) THEN x := NIL ELSE x := x.next END
    END;
    IF lo >= 0 THEN
      fa := d.actors; WHILE fa.index # lo DO fa := fa.next END;
      ta := d.actors; WHILE ta.index # hi DO ta := ta.next END;
      note.from := fa; note.to := ta
    END
  END
END Event;

PROCEDURE Events(s: Stat; origin, retTo: Str);
BEGIN
  WHILE s # NIL DO Event(s, origin, retTo); s := s.next END
END Events;

(* Whether the scanner's text, after front matter and comments, starts
   with "zenuml" *)
PROCEDURE IsZen*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  r := s.LookingAt("zenuml");
  s.pos := save;
  RETURN r
END IsZen;

(* Reads the ZenUML diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Q.Diagram);
  VAR g: F.Graph; body: Stat; q: Part; title: Str;
BEGIN
  sc := s; NEW(buf, 256); bufN := 0;
  F.Begin(s, F.Zen, g);
  IF ~sc.LookingAt("zenuml") THEN sc.Error("expected zenuml") END;
  INC(sc.pos, 6);
  NEW(d); diagram := d;
  Q.Start(d, g, FALSE);
  parts := NIL; lastPart := NIL; starter := NIL; missFrom := FALSE; nMsgs := 0; defStarter := NIL;
  Lex(sc.pos);
  p := 0; title := NIL;
  IF K() = tTitle THEN title := Trim(L.Sub(sc.t^, tk[p].start, tk[p].end - tk[p].start)); INC(p) END;
  IF title # NIL THEN g.title := Label(title) END;
  Head;
  body := Block();
  IF K() # tEOF THEN Err('a "}" has no "{"') END;
  Collect(body, starter, starter);
  IF missFrom OR (nMsgs = 0) & (parts = NIL) THEN
    NEW(q); q.name := NIL; q.label := NIL; q.stereo := NIL; q.type := NIL; q.box := NIL;
    q.starter := TRUE; q.actor := NIL; q.next := parts; parts := q;
    IF lastPart = NIL THEN lastPart := q END
  END;
  Actors;
  Events(body, starter, starter)
END Read;

END PmZen.
