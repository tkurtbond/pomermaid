MODULE PmIO;
(* PmIO: pomermaid's input and output, and its messages (after podoc's
   PdIO).

   Input is read whole into a flat array of bytes (a Text). Output goes
   to standard output or to one file, through a buffer, as strings,
   characters and numbers. A message is written to standard error as
   "pomermaid: ..."; Fail writes one and ends the program with one of
   the exit statuses below, which are podoc's (and so pandoc's) where
   the error is the same kind. *)

IMPORT SYSTEM, Platform, Err, Out;

CONST
  (* exit statuses *)
  IOError* = 1;       (* a file cannot be read or written *)
  OptionError* = 6;   (* a bad option value *)
  UnknownWriter* = 22; (* -t names no output format *)
  ProgramError* = 43; (* groff or mutool failed *)
  ProgramNotFound* = 47; (* groff or mutool is not installed *)
  ParseError* = 64;   (* the diagram cannot be read *)

  BufSize = 8192;
  ReadChunk = 65536;

TYPE
  (* A text read whole: its bytes are t[0 .. len-1], len kept apart. *)
  Text* = POINTER TO ARRAY OF CHAR;

VAR
  out: Platform.FileHandle;
  outIsFile: BOOLEAN;
  outName: ARRAY 4096 OF CHAR;
  buf: ARRAY BufSize OF CHAR;
  bufLen: LONGINT;

(* Messages *)

(* Writes "pomermaid: " to standard error, to start a message. *)
PROCEDURE Start;
BEGIN
  Out.Flush;
  Err.String("pomermaid: ")
END Start;

(* Writes "pomermaid: msg" and a new line to standard error. *)
PROCEDURE Message*(msg: ARRAY OF CHAR);
BEGIN
  Start; Err.String(msg); Err.Ln; Err.Flush
END Message;

(* Writes "pomermaid: abc", the strings a, b and c, and a new line to
   standard error. *)
PROCEDURE Message3*(a, b, c: ARRAY OF CHAR);
BEGIN
  Start; Err.String(a); Err.String(b); Err.String(c); Err.Ln; Err.Flush
END Message3;

(* Writes "pomermaid: [WARNING] msg" and a new line to standard error. *)
PROCEDURE Warn*(msg: ARRAY OF CHAR);
BEGIN
  Start; Err.String("[WARNING] "); Err.String(msg); Err.Ln; Err.Flush
END Warn;

(* Ends the program with the exit status code, after writing what is
   buffered for standard output. *)
PROCEDURE Exit*(code: INTEGER);
BEGIN
  Out.Flush; Err.Flush;
  Platform.Exit(code)
END Exit;

(* Writes "pomermaid: name: msg" to standard error and ends the program with
   the exit status code; name is left out when it is empty. *)
PROCEDURE Fail*(name, msg: ARRAY OF CHAR; code: INTEGER);
BEGIN
  Start;
  IF name # "" THEN Err.String(name); Err.String(": ") END;
  Err.String(msg); Err.Ln;
  Exit(code)
END Fail;

(* Input *)

(* Makes t hold at least need bytes, keeping its first len; t may be
   NIL. *)
PROCEDURE Reserve*(VAR t: Text; len, need: LONGINT);
  VAR n: Text; size, i: LONGINT;
BEGIN
  IF t = NIL THEN size := ReadChunk ELSE size := LEN(t^) END;
  WHILE size < need DO size := size * 2 END;
  IF (t = NIL) OR (size > LEN(t^)) THEN
    NEW(n, size);
    i := 0; WHILE i < len DO n[i] := t[i]; INC(i) END;
    t := n
  END
END Reserve;

(* Reads all of h into t; len is how many bytes. *)
PROCEDURE ReadHandle(h: Platform.FileHandle; VAR t: Text; VAR len: LONGINT): Platform.ErrorCode;
  VAR n: LONGINT; e: Platform.ErrorCode;
BEGIN
  t := NIL; len := 0;
  LOOP
    IF (t = NIL) OR (LEN(t^) - len < ReadChunk) THEN Reserve(t, len, len + ReadChunk) END;
    e := Platform.Read(h, SYSTEM.ADR(t[len]), LEN(t^) - len, n);
    IF e # 0 THEN
      IF ~Platform.Interrupted(e) THEN RETURN e END
    ELSIF n = 0 THEN
      EXIT
    ELSE
      INC(len, n)
    END
  END;
  RETURN 0
END ReadHandle;

(* Whether the file name exists (it may still be unreadable). *)
PROCEDURE Exists*(name: ARRAY OF CHAR): BOOLEAN;
  VAR h: Platform.FileHandle; e: Platform.ErrorCode;
    n: ARRAY 4096 OF CHAR;
BEGIN
  COPY(name, n);
  e := Platform.OldRO(n, h);
  IF e # 0 THEN RETURN ~Platform.Absent(e) END;
  e := Platform.Close(h);
  RETURN TRUE
END Exists;

(* Reads the file name, or standard input when name is "-", whole into
   t; len is its length in bytes. A file that cannot be read ends the
   program with a message and IOError. *)
PROCEDURE ReadFile*(name: ARRAY OF CHAR; VAR t: Text; VAR len: LONGINT);
  VAR h: Platform.FileHandle; e, e2: Platform.ErrorCode;
    n: ARRAY 4096 OF CHAR;
BEGIN
  IF name = "-" THEN
    e := ReadHandle(Platform.StdIn, t, len);
    IF e # 0 THEN Fail("standard input", "cannot be read", IOError) END
  ELSE
    COPY(name, n);
    e := Platform.OldRO(n, h);
    IF e # 0 THEN
      IF Platform.Absent(e) THEN Fail(name, "does not exist", IOError)
      ELSE Fail(name, "cannot be opened", IOError)
      END
    END;
    e := ReadHandle(h, t, len);
    e2 := Platform.Close(h);
    IF e # 0 THEN Fail(name, "cannot be read", IOError) END
  END
END ReadFile;

(* Output *)

(* Ends the program because the output cannot be written. *)
PROCEDURE WriteFailed;
BEGIN
  bufLen := 0;
  IF outIsFile THEN Fail(outName, "cannot be written", IOError)
  ELSE Fail("standard output", "cannot be written", IOError)
  END
END WriteFailed;

(* Sends what is buffered to the output. *)
PROCEDURE FlushBuf;
BEGIN
  IF bufLen > 0 THEN
    IF Platform.Write(out, SYSTEM.ADR(buf[0]), bufLen) # 0 THEN WriteFailed END;
    bufLen := 0
  END
END FlushBuf;

(* Makes the file name the output, or standard output when name is "" or
   "-". The file is created, or emptied if it is there. *)
PROCEDURE OpenOutput*(name: ARRAY OF CHAR);
  VAR e: Platform.ErrorCode;
BEGIN
  FlushBuf;
  IF (name = "") OR (name = "-") THEN
    out := Platform.StdOut; outIsFile := FALSE; outName := ""
  ELSE
    COPY(name, outName);
    e := Platform.New(outName, out);
    IF e # 0 THEN Fail(name, "cannot be created", IOError) END;
    outIsFile := TRUE
  END
END OpenOutput;

(* Writes the bytes t[start .. start+len-1]. *)
PROCEDURE WriteChars*(VAR t: ARRAY OF CHAR; start, len: LONGINT);
BEGIN
  IF len >= BufSize THEN
    FlushBuf;
    IF Platform.Write(out, SYSTEM.ADR(t[start]), len) # 0 THEN WriteFailed END
  ELSE
    IF bufLen + len > BufSize THEN FlushBuf END;
    WHILE len > 0 DO buf[bufLen] := t[start]; INC(bufLen); INC(start); DEC(len) END
  END
END WriteChars;

(* Writes the character ch. *)
PROCEDURE WriteChar*(ch: CHAR);
BEGIN
  IF bufLen = BufSize THEN FlushBuf END;
  buf[bufLen] := ch; INC(bufLen)
END WriteChar;

(* Writes the string s, up to its 0X. *)
PROCEDURE WriteString*(s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO WriteChar(s[i]); INC(i) END
END WriteString;

(* Writes a new line. *)
PROCEDURE WriteLn*;
BEGIN
  WriteChar(0AX)
END WriteLn;

(* Writes the integer n in decimal. *)
PROCEDURE WriteInt*(n: LONGINT);
  VAR d: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  IF n < 0 THEN WriteChar("-"); n := -n END;
  i := 0;
  REPEAT d[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  WHILE i > 0 DO DEC(i); WriteChar(d[i]) END
END WriteInt;

(* Writes x rounded to d decimals (0 to 4), without trailing zeros or
   a trailing point, and "0" for what rounds to zero: the same x gives
   the same text everywhere. *)
PROCEDURE WriteReal*(x: REAL; d: INTEGER);
  VAR scale, n, ip: LONGINT; i: INTEGER; neg: BOOLEAN; frac: ARRAY 8 OF CHAR;
BEGIN
  scale := 1; FOR i := 1 TO d DO scale := scale * 10 END;
  neg := x < 0; IF neg THEN x := -x END;
  n := ENTIER(x * scale + 0.5);
  IF n = 0 THEN WriteChar("0")
  ELSE
    IF neg THEN WriteChar("-") END;
    ip := n DIV scale; n := n MOD scale;
    WriteInt(ip);
    IF n # 0 THEN
      i := d;
      WHILE i > 0 DO DEC(i); frac[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10 END;
      i := d; WHILE frac[i - 1] = "0" DO DEC(i) END;
      frac[i] := 0X;
      WriteChar("."); WriteString(frac)
    END
  END
END WriteReal;

(* Writes what is buffered and closes the output if it is a file. *)
PROCEDURE CloseOutput*;
BEGIN
  FlushBuf;
  IF outIsFile THEN
    IF Platform.Close(out) # 0 THEN WriteFailed END;
    outIsFile := FALSE
  END;
  out := Platform.StdOut
END CloseOutput;

BEGIN
  out := Platform.StdOut; outIsFile := FALSE; outName := ""; bufLen := 0
END PmIO.
