MODULE PmGanttTimeTest;
(* Tests of PmGanttTime, run with TZ=America/New_York and
   SOURCE_DATE_EPOCH=1700000000 (2023-11-14 17:13:20 EST). *)

IMPORT T := PmGanttTime, PmIO, L := PmLex;

VAR t: HUGEINT;

PROCEDURE Int(n: HUGEINT);
  VAR d: ARRAY 24 OF CHAR; c: ARRAY 2 OF CHAR; k: INTEGER;
BEGIN
  c[1] := 0X;
  IF n < 0 THEN PmIO.WriteString("-"); n := -n END;
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + SHORT(SHORT(n MOD 10))); n := n DIV 10; INC(k) UNTIL n = 0;
  WHILE k > 0 DO DEC(k); c[0] := d[k]; PmIO.WriteString(c) END
END Int;

(* t in ISO form, local *)
PROCEDURE Show(t: HUGEINT);
  VAR s: L.Str;
BEGIN
  IF T.Format(t, "YYYY-MM-DD HH:mm:ss.SSS Z", s) THEN PmIO.WriteString(s^) END
END Show;

PROCEDURE Fmt(t: HUGEINT; f: ARRAY OF CHAR);
  VAR s: L.Str;
BEGIN
  PmIO.WriteString("format "); PmIO.WriteString(f); PmIO.WriteString(": ");
  IF T.Format(t, f, s) THEN PmIO.WriteString(s^) ELSE PmIO.WriteString("FAILED") END;
  PmIO.WriteLn
END Fmt;

PROCEDURE Parse(in, f: ARRAY OF CHAR);
  VAR t: HUGEINT; failed: BOOLEAN;
BEGIN
  PmIO.WriteString("parse "); PmIO.WriteString(in); PmIO.WriteString(" / ");
  PmIO.WriteString(f); PmIO.WriteString(": ");
  IF T.Parse(in, f, t, failed) THEN Int(t); PmIO.WriteString(" "); Show(t)
  ELSIF failed THEN PmIO.WriteString("FAILED")
  ELSE PmIO.WriteString("invalid")
  END;
  PmIO.WriteLn
END Parse;

PROCEDURE Date(in: ARRAY OF CHAR);
  VAR t: HUGEINT;
BEGIN
  PmIO.WriteString("date "); PmIO.WriteString(in); PmIO.WriteString(": ");
  IF T.DateParse(in, t) THEN Int(t); PmIO.WriteString(" "); Show(t)
  ELSE PmIO.WriteString("invalid")
  END;
  PmIO.WriteLn
END Date;

(* n to one decimal, as PmIO.WriteReal(n, 1), beyond a LONGINT too *)
PROCEDURE Amount(n: LONGREAL);
  VAR r: HUGEINT; c: ARRAY 2 OF CHAR;
BEGIN
  IF n < 0 THEN PmIO.WriteString("-"); n := -n END;
  r := T.Round(n * 10); Int(r DIV 10);
  IF r MOD 10 # 0 THEN
    c[0] := CHR(ORD("0") + SHORT(SHORT(r MOD 10))); c[1] := 0X;
    PmIO.WriteString("."); PmIO.WriteString(c)
  END
END Amount;

PROCEDURE Add(t: HUGEINT; n: LONGREAL; u: ARRAY OF CHAR);
  VAR r: HUGEINT;
BEGIN
  PmIO.WriteString("add "); Show(t); PmIO.WriteString(" ");
  Amount(n); PmIO.WriteString(u); PmIO.WriteString(": ");
  IF T.Add(t, n, u, r) THEN Show(r) ELSE PmIO.WriteString("invalid") END;
  PmIO.WriteLn
END Add;

PROCEDURE Local(y, m, d, h, mi: LONGINT): HUGEINT;
  VAR t: HUGEINT;
BEGIN
  IF ~T.Local(y, m, d, h, mi, 0, 0, t) THEN t := 0 END;
  RETURN t
END Local;

BEGIN
  PmIO.WriteString("now "); Int(T.Now()); PmIO.WriteString(" "); Show(T.Now()); PmIO.WriteLn;
  PmIO.WriteString("today "); Int(T.Today()); PmIO.WriteString(" "); Show(T.Today()); PmIO.WriteLn;
  PmIO.WriteString("floor "); Int(T.Floor(-1.5D0)); PmIO.WriteString(" ");
  Int(T.Floor(1.0D13 + 0.5D0)); PmIO.WriteString(" "); Int(T.Trunc(-2.7D0));
  PmIO.WriteString(" "); Int(T.Round(-2.5D0)); PmIO.WriteLn;

  (* local times, and the gap and overlap of 2023 *)
  t := Local(2014, 0, 6, 0, 0); Int(t); PmIO.WriteLn;
  t := Local(2023, 2, 12, 2, 30); Int(t); PmIO.WriteString(" "); Show(t); PmIO.WriteLn;
  t := Local(2023, 10, 5, 1, 30); Int(t); PmIO.WriteString(" "); Show(t); PmIO.WriteLn;
  t := Local(2014, 12, 32, 25, 0); Show(t); PmIO.WriteLn;
  t := Local(50, 0, 1, 0, 0); Show(t); PmIO.WriteLn;

  (* formats *)
  t := Local(2014, 0, 6, 15, 4);
  Fmt(t, "");
  Fmt(t, "YYYY-MM-DD");
  Fmt(t, "YY M D d dd ddd dddd");
  Fmt(t, "MMM MMMM, h:mm a A hh H");
  Fmt(t, "Do [of] MMMM, Q, W WW GGGG");
  Fmt(t, "k kk X x ZZ SSS S");
  Fmt(Local(2014, 0, 6, 0, 0), "k kk");
  Fmt(Local(2014, 0, 22, 0, 0), "Do");
  Fmt(Local(2014, 0, 13, 0, 0), "Do");
  Fmt(Local(2014, 0, 1, 0, 0), "[YYYY] YYYY [W]W");
  Fmt(t, "w");
  Fmt(t, "zzz");
  Fmt(Local(5, 0, 1, 0, 0) - 1900 * 365 * T.Day, "YYYY YY");

  (* strict parses *)
  Parse("2014-01-06", "YYYY-MM-DD");
  Parse("2014-1-6", "YYYY-MM-DD");
  Parse("2014-01-06", "YYYY-M-D");
  Parse("2014-1-6", "YYYY-M-D");
  Parse("2014-02-30", "YYYY-MM-DD");
  Parse("10:30", "HH:mm");
  Parse("1388984400000", "x");
  Parse("1388984400", "X");
  Parse("06/01/14", "DD/MM/YY");
  Parse("Jan 6 2014", "MMM D YYYY");
  Parse("January 6th 2014", "MMMM Do YYYY");
  Parse("6th January", "Do MMMM");
  Parse("2014-01-06 3:04 PM", "YYYY-MM-DD h:mm A");
  Parse("2014-01-06T10:00:00Z", "YYYY-MM-DDTHH:mm:ssZ");
  Parse("2014-01-06T10:00:00-05:00", "YYYY-MM-DDTHH:mm:ssZ");
  Parse("2014-01-06", "");
  Parse("2014", "YYYY");
  Parse("2014-01-06", "L");
  Parse("2014-01-06", "YYYY-MM-DD ww");
  Parse("2014 week", "YYYY [week]");

  (* JavaScript's Date *)
  Date("2014-01-06");
  Date("2014-01");
  Date("2014-01-06T10:00");
  Date("2014-01-06T10:00:00.5Z");
  Date("2014-01-06T10:00+02:00");
  Date("+002014-01-06");
  Date("2014-1-6");
  Date("2014/01/06 10:00");
  Date("01/06/2014");
  Date("1/6/14");
  Date("Jan 6, 2014");
  Date("Monday, 6 January 2014 10:00 pm");
  Date("6 Jan 2014 10:00 GMT");
  Date("Jan 6 2014 10:00:00 GMT+0100 (CET)");
  Date("2014-13-01");
  Date("tomorrow");
  Date("");

  (* dayjs's add *)
  t := Local(2014, 0, 31, 10, 0);
  Add(t, 1, "M"); Add(t, 13, "M"); Add(t, -1, "y"); Add(Local(2016, 1, 29, 0, 0), 1, "y");
  Add(t, 1.5, "d"); Add(t, 2.5, "d"); Add(t, 1, "w"); Add(t, 0.5, "w");
  Add(t, 1.5, "h"); Add(t, 30, "m"); Add(t, 1.0005, "s"); Add(t, 1.9, "ms");
  t := Local(2023, 2, 11, 2, 30);
  Add(t, 1, "d"); Add(t, 24, "h");
  Add(t, 1.0D9, "y"); Add(t, 1.0D9, "ms");
  PmIO.CloseOutput
END PmGanttTimeTest.
