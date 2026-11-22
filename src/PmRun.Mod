MODULE PmRun;
(* PmRun: running other programs, and a temporary directory for them
   (after podoc's PdRun).

   A command is built as text for /bin/sh, each argument in POSIX single
   quotes, and run with Platform.System, so pomermaid needs no C of its
   own to run a program and no library that is built for one size model
   only. The temporary directory is made under TMPDIR, or /tmp, and
   removed with everything in it. *)

IMPORT Platform;

CONST
  PathLen* = 4096;

TYPE
  Path* = ARRAY PathLen OF CHAR;
  Chars = POINTER TO ARRAY OF CHAR;

  (* A command line for /bin/sh: its text is s[0 .. len-1], with a 0X
     after it. *)
  Command* = POINTER TO CommandDesc;
  CommandDesc* = RECORD
    s: Chars;
    len: LONGINT
  END;

VAR
  serial: LONGINT; (* the number of the next temporary directory *)

(* Commands *)

(* An empty command. *)
PROCEDURE New*(): Command;
  VAR c: Command;
BEGIN
  NEW(c); NEW(c.s, 256); c.s[0] := 0X; c.len := 0;
  RETURN c
END New;

(* Adds the character ch to c's text. *)
PROCEDURE AddChar(c: Command; ch: CHAR);
  VAR n: Chars; i: LONGINT;
BEGIN
  IF c.len + 1 >= LEN(c.s^) THEN
    NEW(n, LEN(c.s^) * 2);
    i := 0; WHILE i < c.len DO n[i] := c.s[i]; INC(i) END;
    c.s := n
  END;
  c.s[c.len] := ch; INC(c.len); c.s[c.len] := 0X
END AddChar;

(* Adds the text s to c as it is, for the shell to read: redirections,
   operators and the like. *)
PROCEDURE AddText*(c: Command; s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO AddChar(c, s[i]); INC(i) END
END AddText;

(* Adds s to c in single quotes, a space before it unless c is empty,
   so that the shell reads it as one word whatever is in it. *)
PROCEDURE Add*(c: Command; s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  IF c.len > 0 THEN AddChar(c, " ") END;
  AddChar(c, "'"); i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF s[i] = "'" THEN AddChar(c, "'"); AddChar(c, "\"); AddChar(c, "'"); AddChar(c, "'")
    ELSE AddChar(c, s[i])
    END;
    INC(i)
  END;
  AddChar(c, "'")
END Add;

(* Runs c with /bin/sh and returns its exit status, 0 to 255; a command
   killed by a signal gives 128 and the signal's number, as the shell
   reports it. *)
PROCEDURE Run*(c: Command): INTEGER;
  VAR st: LONGINT;
BEGIN
  st := Platform.System(c.s^);
  (* the wait status, narrowed to INTEGER, which is 16 bits under -O2 *)
  IF st < 0 THEN st := st + 65536 END;
  IF st MOD 256 # 0 THEN RETURN SHORT(128 + st MOD 128) END;
  RETURN SHORT(st DIV 256 MOD 256)
END Run;

(* Whether the program prog can be run: a path to an executable file,
   or a name found in PATH. *)
PROCEDURE Found*(prog: ARRAY OF CHAR): BOOLEAN;
  VAR c: Command;
BEGIN
  c := New(); AddText(c, "command -v"); Add(c, prog);
  AddText(c, " >/dev/null 2>&1");
  RETURN Run(c) = 0
END Found;

(* Paths *)

(* Appends s to the path p. *)
PROCEDURE Append*(VAR p: ARRAY OF CHAR; s: ARRAY OF CHAR);
  VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE (i < LEN(p)) & (p[i] # 0X) DO INC(i) END;
  j := 0;
  WHILE (j < LEN(s)) & (s[j] # 0X) & (i < LEN(p) - 1) DO p[i] := s[j]; INC(i); INC(j) END;
  IF i < LEN(p) THEN p[i] := 0X END
END Append;

(* Appends the number n, n >= 0, to p. *)
PROCEDURE AppendInt*(VAR p: ARRAY OF CHAR; n: LONGINT);
  VAR r, d: ARRAY 24 OF CHAR; i, k: INTEGER;
BEGIN
  i := 0;
  REPEAT r[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  k := 0;
  WHILE i > 0 DO DEC(i); d[k] := r[i]; INC(k) END;
  d[k] := 0X;
  Append(p, d)
END AppendInt;

(* The temporary directory *)

(* Makes a new, empty directory under TMPDIR, or /tmp, readable only by
   the user, and sets dir to its absolute path; ok is FALSE if none
   could be made. *)
PROCEDURE MakeTempDir*(VAR dir: ARRAY OF CHAR; VAR ok: BOOLEAN);
  VAR base: Path; c: Command; tries: INTEGER;
BEGIN
  IF ~Platform.getEnv("TMPDIR", base) OR (base = "") THEN base := "/tmp" END;
  IF base[0] # "/" THEN
    COPY(Platform.CWD, dir); Append(dir, "/"); Append(dir, base); COPY(dir, base)
  END;
  tries := 0; ok := FALSE;
  WHILE ~ok & (tries < 100) DO
    COPY(base, dir); Append(dir, "/pomermaid");
    AppendInt(dir, Platform.PID MOD 65536); Append(dir, "-"); AppendInt(dir, serial);
    INC(serial); INC(tries);
    c := New(); AddText(c, "mkdir -m 700"); Add(c, dir); AddText(c, " 2>/dev/null");
    ok := Run(c) = 0
  END
END MakeTempDir;

(* Removes the directory dir and everything in it. *)
PROCEDURE RemoveDir*(dir: ARRAY OF CHAR);
  VAR c: Command; st: INTEGER;
BEGIN
  c := New(); AddText(c, "rm -rf"); Add(c, dir);
  st := Run(c)
END RemoveDir;

BEGIN
  serial := 0
END PmRun.
