MODULE WidthCheck;
(* WidthCheck: for tools/checkwidths. Reads, from standard input, a
   first line "FONT SIZE" and then lines of text, and writes the width
   of each line, in groff's units, as PmMetrics measures it in FONT at
   SIZE points. *)

IMPORT PmIO, M := PmMetrics;

VAR
  t: PmIO.Text; len, i, start: LONGINT; font: ARRAY 64 OF CHAR; k: INTEGER;
  size: REAL; f: M.Font; frac: REAL;

BEGIN
  PmIO.ReadFile("-", t, len);
  i := 0; k := 0;
  WHILE (i < len) & (t[i] # " ") DO font[k] := t[i]; INC(k); INC(i) END;
  font[k] := 0X; INC(i);
  size := 0; frac := 0;
  WHILE (i < len) & (t[i] >= "0") & (t[i] <= "9") DO size := size * 10 + ORD(t[i]) - ORD("0"); INC(i) END;
  IF (i < len) & (t[i] = ".") THEN
    INC(i); frac := 1;
    WHILE (i < len) & (t[i] >= "0") & (t[i] <= "9") DO frac := frac / 10; size := size + frac * (ORD(t[i]) - ORD("0")); INC(i) END
  END;
  WHILE (i < len) & (t[i] # 0AX) DO INC(i) END;
  INC(i);
  IF ~M.Load(font, f) THEN PmIO.Fail("", "no such font", 1) END;
  PmIO.OpenOutput("");
  WHILE i < len DO
    start := i;
    WHILE (i < len) & (t[i] # 0AX) DO INC(i) END;
    PmIO.WriteInt(M.Units(f, t^, start, i, size)); PmIO.WriteLn;
    INC(i)
  END;
  PmIO.CloseOutput
END WidthCheck.
