MODULE PmGanttScaleTest;
(* Tests of PmGanttScale, run with TZ=America/New_York and
   SOURCE_DATE_EPOCH=1700000000. *)

IMPORT S := PmGanttScale, T := PmGanttTime, PmIO, L := PmLex;

VAR s: S.Scale; t: HUGEINT;

PROCEDURE Int(n: HUGEINT);
  VAR d: ARRAY 24 OF CHAR; c: ARRAY 2 OF CHAR; k: INTEGER;
BEGIN
  c[1] := 0X;
  IF n < 0 THEN PmIO.WriteString("-"); n := -n END;
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + SHORT(SHORT(n MOD 10))); n := n DIV 10; INC(k) UNTIL n = 0;
  WHILE k > 0 DO DEC(k); c[0] := d[k]; PmIO.WriteString(c) END
END Int;

(* x, to 6 decimals *)
PROCEDURE Real(x: LONGREAL);
  VAR n: HUGEINT; f: ARRAY 8 OF CHAR; i: INTEGER;
BEGIN
  IF x < 0 THEN PmIO.WriteString("-"); x := -x END;
  n := T.Round(x * 1000000);
  Int(n DIV 1000000); PmIO.WriteString(".");
  n := n MOD 1000000;
  FOR i := 5 TO 0 BY -1 DO f[i] := CHR(ORD("0") + SHORT(SHORT(n MOD 10))); n := n DIV 10 END;
  f[6] := 0X; PmIO.WriteString(f)
END Real;

PROCEDURE Local(y, m, d, h, mi, sec, ms: LONGINT): HUGEINT;
  VAR t: HUGEINT;
BEGIN
  IF ~T.Local(y, m, d, h, mi, sec, ms, t) THEN t := 0 END;
  RETURN t
END Local;

PROCEDURE Fmt(t: HUGEINT; spec: ARRAY OF CHAR);
  VAR r: L.Str;
BEGIN
  S.Format(t, spec, r);
  PmIO.WriteString("format "); PmIO.WriteString(spec); PmIO.WriteString(": [");
  PmIO.WriteString(r^); PmIO.WriteString("]"); PmIO.WriteLn
END Fmt;

PROCEDURE X(t: HUGEINT);
BEGIN
  PmIO.WriteString(" "); Real(S.X(s, t))
END X;

PROCEDURE ShowInterval(VAR iv: S.Interval);
BEGIN
  CASE iv.kind OF
    S.Millisecond: PmIO.WriteString("millisecond")
  | S.Second: PmIO.WriteString("second")
  | S.Minute: PmIO.WriteString("minute")
  | S.Hour: PmIO.WriteString("hour")
  | S.Day: PmIO.WriteString("day")
  | S.Week: PmIO.WriteString("week"); Int(iv.weekday)
  | S.Month: PmIO.WriteString("month")
  | S.Year: PmIO.WriteString("year")
  END;
  PmIO.WriteString(" every "); Int(iv.step)
END ShowInterval;

PROCEDURE Ticks(VAR iv: S.Interval; start, stop: HUGEINT; max: LONGINT; spec: ARRAY OF CHAR);
  VAR r: S.Times; n, i: LONGINT; f: L.Str;
BEGIN
  PmIO.WriteString("  "); ShowInterval(iv); PmIO.WriteString(":");
  r := S.Range(iv, start, stop + 1, max, n);
  IF r = NIL THEN PmIO.WriteString(" none") END;
  FOR i := 0 TO n - 1 DO
    S.Format(r[i], spec, f); PmIO.WriteString(" "); PmIO.WriteString(f^)
  END;
  PmIO.WriteLn
END Ticks;

PROCEDURE Auto(start, stop: HUGEINT; spec: ARRAY OF CHAR);
  VAR iv: S.Interval; f: L.Str;
BEGIN
  PmIO.WriteString("auto "); S.Format(start, spec, f); PmIO.WriteString(f^);
  PmIO.WriteString(" .. "); S.Format(stop, spec, f); PmIO.WriteString(f^);
  PmIO.WriteLn;
  S.Auto(start, stop, iv);
  Ticks(iv, start, stop, 10000, spec)
END Auto;

PROCEDURE Every(kind: INTEGER; step: HUGEINT; wd: LONGINT; start, stop: HUGEINT; max: LONGINT;
  spec: ARRAY OF CHAR);
  VAR iv: S.Interval;
BEGIN
  S.Every(kind, step, wd, iv);
  Ticks(iv, start, stop, max, spec)
END Every;

PROCEDURE Step(a, b: LONGREAL);
BEGIN
  PmIO.WriteString("tickStep "); Real(a); PmIO.WriteString(" "); Real(b);
  PmIO.WriteString(": "); Real(S.TickStep(a, b, 10)); PmIO.WriteLn
END Step;

BEGIN
  (* the scale *)
  S.Init(s, Local(2014, 0, 6, 0, 0, 0, 0), Local(2014, 0, 20, 0, 0, 0, 0), 1050);
  PmIO.WriteString("scale");
  X(s.d0); X(s.d1); X(Local(2014, 0, 13, 0, 0, 0, 0)); X(Local(2014, 0, 6, 0, 9, 36, 0));
  X(Local(2014, 0, 6, 0, 28, 48, 0)); X(Local(2014, 0, 1, 0, 0, 0, 0));
  X(Local(2014, 0, 6, 0, 28, 47, 999));
  PmIO.WriteLn;
  S.Init(s, s.d0, s.d0, 1050);
  PmIO.WriteString("scale"); X(s.d0); X(0); PmIO.WriteLn;

  (* tickStep *)
  Step(0, 1); Step(0, 100); Step(0, 37); Step(0, 0.37D0); Step(0, 14);
  Step(44.5D0, 74.6D0); Step(3, 3);

  (* automatic ticks *)
  Auto(Local(2014, 0, 6, 0, 0, 0, 0), Local(2014, 0, 20, 0, 0, 0, 0), "%Y-%m-%d");
  Auto(Local(2014, 0, 6, 0, 0, 0, 0), Local(2014, 3, 6, 0, 0, 0, 0), "%Y-%m-%d %a");
  Auto(Local(2014, 0, 6, 0, 0, 0, 0), Local(2015, 0, 6, 0, 0, 0, 0), "%Y-%m-%d");
  Auto(Local(2014, 1, 6, 0, 0, 0, 0), Local(2016, 3, 6, 0, 0, 0, 0), "%Y-%m-%d");
  Auto(Local(1990, 5, 1, 0, 0, 0, 0), Local(2020, 0, 6, 0, 0, 0, 0), "%Y");
  Auto(Local(2014, 0, 6, 10, 0, 0, 0), Local(2014, 0, 6, 10, 0, 5, 0), "%H:%M:%S.%L");
  Auto(Local(2014, 0, 6, 10, 0, 0, 0), Local(2014, 0, 6, 10, 0, 0, 7), "%S.%L");
  Auto(Local(2023, 2, 12, 0, 0, 0, 0), Local(2023, 2, 12, 6, 0, 0, 0), "%H:%M %Z");
  Auto(Local(2023, 2, 1, 0, 0, 0, 0), Local(2023, 2, 20, 0, 0, 0, 0), "%m-%d %H:%M");
  Auto(Local(2014, 0, 6, 9, 0, 0, 0), Local(2014, 0, 6, 17, 0, 0, 0), "%H:%M");
  Auto(Local(2014, 0, 6, 0, 0, 0, 0), Local(2014, 0, 6, 0, 0, 0, 0), "%Y-%m-%d");

  (* every *)
  PmIO.WriteString("every"); PmIO.WriteLn;
  t := Local(2014, 0, 28, 0, 0, 0, 0);
  Every(S.Day, 2, 0, t, Local(2014, 1, 10, 0, 0, 0, 0), 10000, "%m-%d");
  Every(S.Day, 1, 0, t, Local(2014, 1, 3, 12, 0, 0, 0), 10000, "%m-%d");
  Every(S.Week, 1, 1, t, Local(2014, 2, 1, 0, 0, 0, 0), 10000, "%m-%d %a");
  Every(S.Week, 2, 1, t, Local(2014, 3, 1, 0, 0, 0, 0), 10000, "%m-%d %a");
  Every(S.Week, 1, 0, t, Local(2014, 2, 1, 0, 0, 0, 0), 10000, "%m-%d %a");
  Every(S.Week, 3, 4, t, Local(2014, 3, 1, 0, 0, 0, 0), 10000, "%m-%d %a");
  Every(S.Month, 3, 0, t, Local(2015, 3, 1, 0, 0, 0, 0), 10000, "%Y-%m-%d");
  Every(S.Month, 1, 0, Local(2014, 0, 31, 12, 0, 0, 0), Local(2014, 4, 1, 0, 0, 0, 0), 10000, "%Y-%m-%d");
  Every(S.Hour, 3, 0, Local(2023, 2, 11, 18, 0, 0, 0), Local(2023, 2, 12, 12, 0, 0, 0), 10000, "%d %H:%M %Z");
  Every(S.Hour, 1, 0, Local(2023, 10, 5, 0, 0, 0, 0), Local(2023, 10, 5, 3, 0, 0, 0), 10000, "%H:%M %Z");
  Every(S.Day, 1, 0, Local(2023, 10, 4, 0, 0, 0, 0), Local(2023, 10, 7, 0, 0, 0, 0), 10000, "%m-%d %H:%M %Z");
  Every(S.Minute, 15, 0, Local(2014, 0, 6, 10, 7, 0, 0), Local(2014, 0, 6, 11, 0, 0, 0), 10000, "%H:%M");
  Every(S.Second, 20, 0, Local(2014, 0, 6, 10, 0, 1, 0), Local(2014, 0, 6, 10, 1, 0, 0), 10000, "%M:%S");
  Every(S.Millisecond, 250, 0, Local(2014, 0, 6, 10, 0, 0, 100), Local(2014, 0, 6, 10, 0, 1, 0), 10000, "%S.%L");
  Every(S.Year, 5, 0, Local(1990, 5, 1, 0, 0, 0, 0), Local(2020, 0, 6, 0, 0, 0, 0), 10000, "%Y");
  Every(S.Day, 1, 0, t, Local(2014, 1, 10, 0, 0, 0, 0), 5, "%m-%d");
  Every(S.Day, 1000, 0, t, Local(2014, 2, 10, 0, 0, 0, 0), 10000, "%m-%d");
  Every(S.Day, 1, 0, Local(2014, 1, 10, 0, 0, 0, 0), t, 10000, "%m-%d");

  (* formats *)
  t := Local(2014, 0, 6, 15, 4, 5, 7);
  Fmt(t, "%Y-%m-%d %H:%M:%S.%L");
  Fmt(t, "%a %A %b %B %d %e %j %w %u %U %W %V %G %g");
  Fmt(t, "%I %p %y %q %f %Z %%");
  Fmt(t, "%c|%x|%X");
  Fmt(t, "%Q %s");
  Fmt(t, "%-d %_m %0e %-H %_j %e");
  Fmt(t, "%k %E %");
  Fmt(t, "100%-");
  Fmt(t, "");
  Fmt(Local(2014, 0, 6, 0, 30, 0, 0), "%I %p %X");
  Fmt(Local(2014, 6, 6, 12, 30, 0, 0), "%I %p %Z");
  Fmt(Local(2023, 0, 1, 0, 0, 0, 0), "%a %j %U %W %V %G %g");
  Fmt(Local(2024, 11, 31, 0, 0, 0, 0), "%a %j %U %W %V %G %g");
  Fmt(Local(2021, 0, 1, 0, 0, 0, 0), "%a %j %U %W %V %G %g");
  Fmt(Local(2026, 0, 1, 0, 0, 0, 0), "%a %j %U %W %V %G %g");
  Fmt(Local(2020, 11, 31, 0, 0, 0, 0), "%a %j %U %W %V %G %g");
  Fmt(Local(-5, 0, 1, 0, 0, 0, 0), "%Y %y");
  Fmt(Local(12345 - 10000, 0, 1, 0, 0, 0, 0), "%Y %y %-Y");
  PmIO.CloseOutput
END PmGanttScaleTest.
