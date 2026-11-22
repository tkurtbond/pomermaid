MODULE PmLex;
(* PmLex: what every diagram reader needs to read the Mermaid text.

   A Scanner is the text read whole, and a position in it. The readers
   look at the text through it: the character at the position and those
   after it, blanks and comments skipped, words and strings taken. An
   error names the input, the line and the column (in characters, not
   bytes) and ends pomermaid with PmIO.ParseError.

   Str is a string of the size it needs, ended by 0X. *)

IMPORT PmIO;

CONST
  Tab = 09X; LF = 0AX; CR = 0DX;

TYPE
  Str* = POINTER TO ARRAY OF CHAR;

  Scanner* = POINTER TO ScannerDesc;
  ScannerDesc* = RECORD
    t*: PmIO.Text;    (* the text; t[len] is 0X *)
    len*: LONGINT;
    pos*: LONGINT;    (* where the scanner is *)
    name: ARRAY 256 OF CHAR (* the input, for messages *)
  END;

(* Strings *)

(* Length of s up to its 0X *)
PROCEDURE Length*(s: ARRAY OF CHAR): LONGINT;
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
  RETURN i
END Length;

(* A new Str of the bytes s[start .. start+n-1] *)
PROCEDURE Sub*(VAR s: ARRAY OF CHAR; start, n: LONGINT): Str;
  VAR r: Str; i: LONGINT;
BEGIN
  IF n < 0 THEN n := 0 END;
  NEW(r, n + 1);
  FOR i := 0 TO n - 1 DO r[i] := s[start + i] END;
  r[n] := 0X;
  RETURN r
END Sub;

(* A new Str holding s *)
PROCEDURE New*(s: ARRAY OF CHAR): Str;
BEGIN
  RETURN Sub(s, 0, Length(s))
END New;

(* Whether a and b hold the same string; NIL is "" *)
PROCEDURE Equal*(a, b: Str): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF a = NIL THEN RETURN (b = NIL) OR (b[0] = 0X) END;
  IF b = NIL THEN RETURN a[0] = 0X END;
  i := 0;
  WHILE (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END;
  RETURN a[i] = b[i]
END Equal;

(* Whether s holds the string w *)
PROCEDURE Is*(s: Str; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF s = NIL THEN RETURN w[0] = 0X END;
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) & (s[i] = w[i]) DO INC(i) END;
  RETURN ((i = LEN(w)) OR (w[i] = 0X)) & (s[i] = 0X)
END Is;

(* Characters *)

PROCEDURE IsBlank*(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch = " ") OR (ch = Tab) OR (ch = CR)
END IsBlank;

PROCEDURE IsLetter*(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z")
END IsLetter;

PROCEDURE IsDigit*(ch: CHAR): BOOLEAN;
BEGIN RETURN (ch >= "0") & (ch <= "9")
END IsDigit;

(* A letter, a digit, "_", or a byte of a UTF-8 sequence *)
PROCEDURE IsWordChar*(ch: CHAR): BOOLEAN;
BEGIN RETURN IsLetter(ch) OR IsDigit(ch) OR (ch = "_") OR (ch >= 80X)
END IsWordChar;

(* The scanner *)

(* A scanner on t[0 .. len-1], read from the input name ("-" for
   standard input). t gets a 0X after the text. *)
PROCEDURE Open*(VAR t: PmIO.Text; len: LONGINT; name: ARRAY OF CHAR): Scanner;
  VAR s: Scanner;
BEGIN
  PmIO.Reserve(t, len, len + 1);
  t[len] := 0X;
  NEW(s); s.t := t; s.len := len; s.pos := 0;
  IF name = "-" THEN s.name := "<stdin>" ELSE COPY(name, s.name) END;
  RETURN s
END Open;

(* The character at pos + k, or 0X past the end *)
PROCEDURE (s: Scanner) Peek*(k: LONGINT): CHAR;
BEGIN
  IF s.pos + k < s.len THEN RETURN s.t[s.pos + k] ELSE RETURN 0X END
END Peek;

(* The character at the position *)
PROCEDURE (s: Scanner) Ch*(): CHAR;
BEGIN
  IF s.pos < s.len THEN RETURN s.t[s.pos] ELSE RETURN 0X END
END Ch;

(* Whether the scanner is past the end *)
PROCEDURE (s: Scanner) AtEnd*(): BOOLEAN;
BEGIN RETURN s.pos >= s.len
END AtEnd;

(* Whether the text at the position starts with w *)
PROCEDURE (s: Scanner) LookingAt*(w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF s.Peek(i) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END LookingAt;

(* Whether the text at the position is the word w, not followed by a
   word character; case matters *)
PROCEDURE (s: Scanner) LookingAtWord*(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN s.LookingAt(w) & ~IsWordChar(s.Peek(Length(w)))
END LookingAtWord;

(* Moves past w if the text there starts with it *)
PROCEDURE (s: Scanner) Accept*(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF s.LookingAt(w) THEN INC(s.pos, Length(w)); RETURN TRUE END;
  RETURN FALSE
END Accept;

(* Skips blanks (not line ends) *)
PROCEDURE (s: Scanner) SkipBlanks*;
BEGIN
  WHILE (s.pos < s.len) & IsBlank(s.t[s.pos]) DO INC(s.pos) END
END SkipBlanks;

(* Skips to the end of the line, leaving the position at its LF *)
PROCEDURE (s: Scanner) SkipLine*;
BEGIN
  WHILE (s.pos < s.len) & (s.t[s.pos] # LF) DO INC(s.pos) END
END SkipLine;

(* Skips blanks, line ends, ";" and "%%" comments: what is between
   statements *)
PROCEDURE (s: Scanner) SkipSpace*;
BEGIN
  LOOP
    s.SkipBlanks;
    IF (s.Ch() = LF) OR (s.Ch() = ";") THEN INC(s.pos)
    ELSIF s.LookingAt("%%") THEN s.SkipLine
    ELSE EXIT
    END
  END
END SkipSpace;

(* Whether the position is at the end of a statement: a line end, ";",
   a "%%" comment or the end of the text, after blanks, which are
   skipped *)
PROCEDURE (s: Scanner) AtStatementEnd*(): BOOLEAN;
BEGIN
  s.SkipBlanks;
  RETURN (s.pos >= s.len) OR (s.Ch() = LF) OR (s.Ch() = ";") OR s.LookingAt("%%")
END AtStatementEnd;

(* The word at the position (IsWordChar), taken; NIL if there is none *)
PROCEDURE (s: Scanner) Word*(): Str;
  VAR start: LONGINT;
BEGIN
  start := s.pos;
  WHILE (s.pos < s.len) & IsWordChar(s.t[s.pos]) DO INC(s.pos) END;
  IF s.pos = start THEN RETURN NIL END;
  RETURN Sub(s.t^, start, s.pos - start)
END Word;

(* The rest of the statement, to a line end, ";" or the end, without
   blanks at either end, taken *)
PROCEDURE (s: Scanner) Rest*(): Str;
  VAR start, end: LONGINT;
BEGIN
  s.SkipBlanks;
  start := s.pos;
  WHILE (s.pos < s.len) & (s.t[s.pos] # LF) & (s.t[s.pos] # ";") DO INC(s.pos) END;
  end := s.pos;
  WHILE (end > start) & IsBlank(s.t[end - 1]) DO DEC(end) END;
  RETURN Sub(s.t^, start, end - start)
END Rest;

(* The line and column of the byte at p, from 1; the column counts
   characters of UTF-8 *)
PROCEDURE (s: Scanner) Where*(p: LONGINT; VAR line, col: LONGINT);
  VAR i: LONGINT;
BEGIN
  line := 1; col := 1; i := 0;
  WHILE (i < p) & (i < s.len) DO
    IF s.t[i] = LF THEN INC(line); col := 1
    ELSIF (s.t[i] < 80X) OR (s.t[i] >= 0C0X) THEN INC(col)
    END;
    INC(i)
  END
END Where;

(* Writes "pomermaid: NAME:LINE:COL: msg" for the byte at p and ends
   pomermaid with PmIO.ParseError *)
PROCEDURE (s: Scanner) ErrorAt*(p: LONGINT; msg: ARRAY OF CHAR);
  VAR line, col: LONGINT; m: ARRAY 512 OF CHAR;
  PROCEDURE Num(n: LONGINT);
    VAR d: ARRAY 24 OF CHAR; i, k: INTEGER;
  BEGIN
    i := 0; REPEAT d[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
    k := SHORT(Length(m));
    WHILE (i > 0) & (k < LEN(m) - 1) DO DEC(i); m[k] := d[i]; INC(k) END;
    m[k] := 0X
  END Num;
  PROCEDURE Add(t: ARRAY OF CHAR);
    VAR i, k: LONGINT;
  BEGIN
    k := Length(m); i := 0;
    WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(m) - 1) DO m[k] := t[i]; INC(k); INC(i) END;
    m[k] := 0X
  END Add;
BEGIN
  s.Where(p, line, col);
  m := ""; Add(s.name); Add(":"); Num(line); Add(":"); Num(col);
  PmIO.Fail(m, msg, PmIO.ParseError)
END ErrorAt;

(* An error at the position *)
PROCEDURE (s: Scanner) Error*(msg: ARRAY OF CHAR);
BEGIN
  s.ErrorAt(s.pos, msg)
END Error;

END PmLex.
