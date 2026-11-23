MODULE PmGanttScale;
(* PmGanttScale: a Gantt chart's time scale, its ticks and their labels,
   as Mermaid's ganttRenderer.js makes them with d3 7: d3-scale's
   scaleTime with rangeRound, d3-time's intervals and automatic ticks,
   and d3-time-format's timeFormat with its en-US locale, all in local
   time (decision 16).

   - The scale maps [d0, d1] to [0, r], each x rounded as Math.round
     rounds; when d0 = d1 every time is at r / 2.
   - An interval is d3-time's: a kind (millisecond, second, minute, hour,
     day, a week starting on a given weekday, month, year) and a step,
     its "every": a step above 1 keeps the times whose field (the day of
     the month less 1, the month from 0, the hour, the minute, the
     second, or for weeks the count of weeks from 1970) is a multiple of
     the step; millisecond and year steps are multiples of the step
     itself. Range gives the times of an interval in [start, stop), as
     interval.range does.
   - Auto is d3's tickInterval for a count of 10: the interval among
     1, 5, 15 and 30 seconds and minutes, 1, 3, 6 and 12 hours, 1 and 2
     days, 1 week (from Sunday), 1 and 3 months and 1 year nearest the
     domain's tenth, or years or milliseconds by d3-array's tickStep
     beyond them.
   - Format is timeFormat's strftime: %a %A %b %B %c %d %e %f %g %G %H
     %I %j %L %m %M %p %q %Q %s %S %u %U %V %w %W %x %X %y %Y %Z %%, with
     the padding flags "-", "_" and "0"; a "%" before any other
     character gives that character. *)

IMPORT T := PmGanttTime, L := PmLex;

CONST
  (* the kinds of interval *)
  Millisecond* = 0; Second* = 1; Minute* = 2; Hour* = 3; Day* = 4;
  Week* = 5; Month* = 6; Year* = 7;

  maxLoop = 100000;   (* the most steps a filter looks through *)

  sqrt50 = 7.0710678118654755D0; sqrt10 = 3.1622776601683795D0;
  sqrt2 = 1.4142135623730951D0;

TYPE
  Str = L.Str;

  Scale* = RECORD
    d0*, d1*: HUGEINT;   (* the domain *)
    r*: LONGREAL         (* the range's end; it starts at 0 *)
  END;

  Interval* = RECORD
    kind*: INTEGER;
    step*: HUGEINT;      (* every step; 1 for each *)
    weekday*: LONGINT    (* the first day of a week: 0 Sunday .. 6 *)
  END;

  Times* = POINTER TO ARRAY OF HUGEINT;

VAR
  bad: BOOLEAN;        (* a time went beyond those PmGanttTime keeps *)
  buf: Str; bufLen: LONGINT;

(* The scale *)

(* x rounded as JavaScript's Math.round *)
PROCEDURE RoundJS(x: LONGREAL): LONGREAL;
  VAR f: LONGREAL;
BEGIN
  f := T.Floor(x);
  IF x - f >= 0.5D0 THEN f := f + 1 END;
  RETURN f
END RoundJS;

(* Sets s's domain and range *)
PROCEDURE Init*(VAR s: Scale; d0, d1: HUGEINT; r: LONGREAL);
BEGIN
  s.d0 := d0; s.d1 := d1; s.r := r
END Init;

(* t's place on s, as rangeRound's scale gives it *)
PROCEDURE X*(VAR s: Scale; t: HUGEINT): LONGREAL;
  VAR u: LONGREAL;
BEGIN
  IF s.d1 = s.d0 THEN u := 0.5D0
  ELSE u := (t - s.d0) / (s.d1 - s.d0 + 0.0D0)
  END;
  RETURN RoundJS(s.r * u)
END X;

(* Intervals *)

(* JavaScript's new Date(year, month0, day, ...) with setFullYear's
   years: 0 .. 99 are not 1900 .. 1999. The Gregorian calendar repeats
   every 400 years, 146097 days. *)
PROCEDURE Local(year, month0, day, hour, minute, second, ms: LONGINT): HUGEINT;
  VAR t, d: HUGEINT;
BEGIN
  IF (year >= 0) & (year <= 99) THEN
    IF ~T.Local(year + 400, month0, day, hour, minute, second, ms, t) THEN bad := TRUE; t := 0
    ELSE d := 146097; t := t - d * T.Day
    END
  ELSIF ~T.Local(year, month0, day, hour, minute, second, ms, t) THEN bad := TRUE; t := 0
  END;
  RETURN t
END Local;

(* The local day number of p's date: days from 1970-01-01 *)
PROCEDURE DayNumber(VAR p: T.Parts): HUGEINT;
  VAR t: HUGEINT; ok: BOOLEAN;
BEGIN
  IF (p.year >= 0) & (p.year <= 99) THEN   (* UTC reads them as 1900 .. 1999 *)
    ok := T.UTC(p.year + 400, p.month - 1, p.day, 0, 0, 0, 0, t);
    t := t - 146097 * T.Day
  ELSE ok := T.UTC(p.year, p.month - 1, p.day, 0, 0, 0, 0, t)
  END;
  IF ~ok THEN t := 0 END;
  RETURN t DIV T.Day
END DayNumber;

(* JavaScript's a % b, for b > 0: with a's sign *)
PROCEDURE Rem(a: HUGEINT; b: LONGINT): HUGEINT;
BEGIN
  IF a < 0 THEN RETURN -((-a) MOD b) ELSE RETURN a MOD b END
END Rem;

(* The day number of the first day, wd (0 Sunday .. 6), of the week that
   holds day number dn; 1970-01-01 was a Thursday *)
PROCEDURE WeekStart(dn: HUGEINT; wd: LONGINT): HUGEINT;
BEGIN
  RETURN dn - ((dn + 4) MOD 7 + 7 - wd) MOD 7
END WeekStart;

(* d3's count of weeks (starting on wd) from day number a's to b's *)
PROCEDURE WeekCount(a, b: HUGEINT; wd: LONGINT): HUGEINT;
BEGIN
  RETURN (WeekStart(b, wd) - WeekStart(a, wd)) DIV 7
END WeekCount;

(* The day number of the first day of p's year *)
PROCEDURE YearStart(VAR p: T.Parts): HUGEINT;
  VAR q: T.Parts;
BEGIN
  q := p; q.month := 1; q.day := 1;
  RETURN DayNumber(q)
END YearStart;

(* The kind's floori *)
PROCEDURE BaseFloor(kind: INTEGER; wd: LONGINT; t: HUGEINT): HUGEINT;
  VAR p: T.Parts; x: HUGEINT;
BEGIN
  IF kind = Millisecond THEN RETURN t END;
  T.Break(t, p);
  CASE kind OF
    Second: x := p.ms; RETURN t - x
  | Minute: x := p.second; RETURN t - p.ms - x * T.Second
  | Hour: x := p.minute; RETURN t - p.ms - p.second * T.Second - x * T.Minute
  | Day: RETURN Local(p.year, p.month - 1, p.day, 0, 0, 0, 0)
  | Week: RETURN Local(p.year, p.month - 1, p.day - (p.weekday + 7 - wd) MOD 7, 0, 0, 0, 0)
  | Month: RETURN Local(p.year, p.month - 1, 1, 0, 0, 0, 0)
  | Year: RETURN Local(p.year, 0, 1, 0, 0, 0, 0)
  END
END BaseFloor;

(* The kind's offseti *)
PROCEDURE BaseOffset(kind: INTEGER; t, n: HUGEINT): HUGEINT;
  VAR p: T.Parts; k: LONGINT;
BEGIN
  CASE kind OF
    Millisecond: RETURN t + n
  | Second: RETURN t + n * T.Second
  | Minute: RETURN t + n * T.Minute
  | Hour: RETURN t + n * T.Hour
  ELSE
    IF ABS(n) > 1000000 THEN bad := TRUE; RETURN t END;
    k := SHORT(n);
    T.Break(t, p);
    CASE kind OF
      Day: RETURN Local(p.year, p.month - 1, p.day + k, p.hour, p.minute, p.second, p.ms)
    | Week: RETURN Local(p.year, p.month - 1, p.day + 7 * k, p.hour, p.minute, p.second, p.ms)
    | Month: RETURN Local(p.year, p.month - 1 + k, p.day, p.hour, p.minute, p.second, p.ms)
    | Year: RETURN Local(p.year + k, p.month - 1, p.day, p.hour, p.minute, p.second, p.ms)
    END
  END
END BaseOffset;

(* Whether every's filter keeps t *)
PROCEDURE Keep(VAR iv: Interval; t: HUGEINT): BOOLEAN;
  VAR p: T.Parts; f, a, b: HUGEINT;
BEGIN
  T.Break(t, p);
  CASE iv.kind OF
    Second: f := (t DIV 1000) MOD 60     (* getUTCSeconds *)
  | Minute: f := p.minute
  | Hour: f := p.hour
  | Day: f := p.day - 1
  | Month: f := p.month - 1
  | Week:
    (* interval.count(0, t): the weeks between the floors of 0 and t,
       in local days *)
    b := DayNumber(p); T.Break(0, p); a := DayNumber(p);
    f := WeekCount(a, b, iv.weekday)
  END;
  RETURN f MOD iv.step = 0
END Keep;

(* iv's floor of t *)
PROCEDURE Floor*(VAR iv: Interval; t: HUGEINT): HUGEINT;
  VAR n: LONGINT; y, k: HUGEINT; p: T.Parts;
BEGIN
  IF iv.step <= 1 THEN RETURN BaseFloor(iv.kind, iv.weekday, t)
  ELSIF iv.kind = Millisecond THEN RETURN t DIV iv.step * iv.step
  ELSIF iv.kind = Year THEN
    T.Break(t, p); y := p.year; k := y DIV iv.step * iv.step;
    RETURN Local(SHORT(k), 0, 1, 0, 0, 0, 0)
  ELSE
    n := 0; t := BaseFloor(iv.kind, iv.weekday, t);
    WHILE ~bad & ~Keep(iv, t) & (n < maxLoop) DO
      t := BaseFloor(iv.kind, iv.weekday, t - 1); INC(n)
    END;
    IF n = maxLoop THEN bad := TRUE END;
    RETURN t
  END
END Floor;

(* iv's offset of t by one *)
PROCEDURE Next(VAR iv: Interval; t: HUGEINT): HUGEINT;
  VAR n: LONGINT;
BEGIN
  IF iv.step <= 1 THEN RETURN BaseOffset(iv.kind, t, 1)
  ELSIF iv.kind = Millisecond THEN RETURN t + iv.step
  ELSIF iv.kind = Year THEN
    IF iv.step > 100000 THEN bad := TRUE; RETURN t END;
    RETURN BaseOffset(Year, t, iv.step)
  ELSE
    n := 0;
    REPEAT t := BaseOffset(iv.kind, t, 1); INC(n)
    UNTIL bad OR Keep(iv, t) OR (n = maxLoop);
    IF n = maxLoop THEN bad := TRUE END;
    RETURN t
  END
END Next;

(* Sets iv to kind.every(step), weeks starting on weekday *)
PROCEDURE Every*(kind: INTEGER; step: HUGEINT; weekday: LONGINT; VAR iv: Interval);
BEGIN
  iv.kind := kind; iv.step := step; iv.weekday := weekday
END Every;

(* The times of iv in [start, stop), at most max of them, as
   interval.range(start, stop); n is how many. NIL if there are none, or
   more than max, or a time goes beyond those kept. *)
PROCEDURE Range*(VAR iv: Interval; start, stop: HUGEINT; max: LONGINT; VAR n: LONGINT): Times;
  VAR r, r2: Times; t, prev: HUGEINT; i: LONGINT;
BEGIN
  bad := FALSE; n := 0; r := NIL;
  t := Floor(iv, start - 1); t := Next(iv, t); t := Floor(iv, t);   (* ceil *)
  IF bad OR (t >= stop) THEN RETURN NIL END;
  NEW(r, 16);
  REPEAT
    IF n = LEN(r^) THEN
      NEW(r2, 2 * LEN(r^)); FOR i := 0 TO n - 1 DO r2[i] := r[i] END; r := r2
    END;
    r[n] := t; INC(n); prev := t;
    t := Next(iv, t); t := Floor(iv, t)
  UNTIL bad OR (n > max) OR ~(prev < t) OR ~(t < stop);
  IF bad OR (n > max) THEN n := 0; r := NIL END;
  RETURN r
END Range;

(* Automatic ticks *)

(* 10 to the k, as Math.pow gives it *)
PROCEDURE Pow10(k: LONGINT): LONGREAL;
  VAR x: LONGREAL;
BEGIN
  IF k < 0 THEN RETURN 1 / Pow10(-k) END;
  x := 1;
  WHILE k > 0 DO x := x * 10; DEC(k) END;
  RETURN x
END Pow10;

(* d3-array's tickStep(start, stop, count), for start <= stop *)
PROCEDURE TickStep*(start, stop, count: LONGREAL): LONGREAL;
  VAR step, error, factor: LONGREAL; power: LONGINT;
BEGIN
  step := (stop - start) / count;
  IF step <= 0 THEN RETURN 0 END;
  power := 0;
  IF step >= 1 THEN
    WHILE step >= Pow10(power + 1) DO INC(power) END
  ELSE
    WHILE step < Pow10(power) DO DEC(power) END
  END;
  error := step / Pow10(power);
  IF error >= sqrt50 THEN factor := 10
  ELSIF error >= sqrt10 THEN factor := 5
  ELSIF error >= sqrt2 THEN factor := 2
  ELSE factor := 1
  END;
  IF power < 0 THEN RETURN 1 / (Pow10(-power) / factor)
  ELSE RETURN Pow10(power) * factor
  END
END TickStep;

(* Sets iv to d3's tickInterval(start, stop, 10), local time's *)
PROCEDURE Auto*(start, stop: HUGEINT; VAR iv: Interval);
  CONST n = 18; year = 365.0D0 * T.Day;
  VAR kinds: ARRAY n OF INTEGER; steps: ARRAY n OF INTEGER; d: ARRAY n OF LONGREAL;
    target, s: LONGREAL; i: INTEGER;

  PROCEDURE Set(i, kind, step: INTEGER; unit: LONGREAL);
  BEGIN
    kinds[i] := kind; steps[i] := step; d[i] := step * unit
  END Set;

BEGIN
  Set(0, Second, 1, T.Second); Set(1, Second, 5, T.Second);
  Set(2, Second, 15, T.Second); Set(3, Second, 30, T.Second);
  Set(4, Minute, 1, T.Minute); Set(5, Minute, 5, T.Minute);
  Set(6, Minute, 15, T.Minute); Set(7, Minute, 30, T.Minute);
  Set(8, Hour, 1, T.Hour); Set(9, Hour, 3, T.Hour);
  Set(10, Hour, 6, T.Hour); Set(11, Hour, 12, T.Hour);
  Set(12, Day, 1, T.Day); Set(13, Day, 2, T.Day);
  Set(14, Week, 1, 7.0D0 * T.Day);
  Set(15, Month, 1, 30.0D0 * T.Day); Set(16, Month, 3, 30.0D0 * T.Day);
  Set(17, Year, 1, year);
  target := ABS(stop - start) / 10.0D0;
  i := 0;
  WHILE (i < n) & (d[i] <= target) DO INC(i) END;   (* bisect right *)
  IF i = n THEN
    s := T.Floor(TickStep(start / year, stop / year, 10));
    Every(Year, T.Floor(s), 0, iv)
  ELSIF i = 0 THEN
    s := T.Floor(TickStep(start, stop, 10));
    IF s < 1 THEN s := 1 END;
    Every(Millisecond, T.Floor(s), 0, iv)
  ELSE
    IF target / d[i - 1] < d[i] / target THEN DEC(i) END;
    Every(kinds[i], steps[i], 0, iv)
  END
END Auto;

(* timeFormat *)

PROCEDURE Put(ch: CHAR);
  VAR b: Str; i: LONGINT;
BEGIN
  IF bufLen + 1 >= LEN(buf^) THEN
    NEW(b, 2 * LEN(buf^));
    FOR i := 0 TO bufLen - 1 DO b[i] := buf[i] END;
    buf := b
  END;
  buf[bufLen] := ch; INC(bufLen)
END Put;

PROCEDURE PutS(s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(s[i]); INC(i) END
END PutS;

(* d3-time-format's pad(value, fill, width): the sign, then fill to
   width, then the digits; fill 0X pads with nothing *)
PROCEDURE Pad(n: HUGEINT; fill: CHAR; width: INTEGER);
  VAR d: ARRAY 24 OF CHAR; k: INTEGER;
BEGIN
  IF n < 0 THEN Put("-"); n := -n END;
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + SHORT(SHORT(n MOD 10))); n := n DIV 10; INC(k) UNTIL n = 0;
  IF fill # 0X THEN
    WHILE width > k DO Put(fill); DEC(width) END
  END;
  WHILE k > 0 DO DEC(k); Put(d[k]) END
END Pad;

(* The Thursday of p's ISO week, as d3's dISO: the Thursday on or before
   p if p is Thursday to Sunday, else the one after *)
PROCEDURE IsoThursday(VAR p, q: T.Parts);
  VAR t: HUGEINT;
BEGIN
  IF (p.weekday >= 4) OR (p.weekday = 0) THEN
    t := Local(p.year, p.month - 1, p.day - (p.weekday + 7 - 4) MOD 7, 0, 0, 0, 0)
  ELSE
    t := Local(p.year, p.month - 1, p.day + (4 - p.weekday), 0, 0, 0, 0)
  END;
  T.Break(t, q)
END IsoThursday;

PROCEDURE Spec(t: HUGEINT; spec: ARRAY OF CHAR);
  VAR i, n: LONGINT; c, fill: CHAR; p, q: T.Parts; name: ARRAY 12 OF CHAR;
    x: HUGEINT;
BEGIN
  T.Break(t, p);
  n := 0; WHILE (n < LEN(spec)) & (spec[n] # 0X) DO INC(n) END;
  i := 0;
  WHILE i < n DO
    IF spec[i] = "%" THEN
      INC(i); IF i < n THEN c := spec[i] ELSE c := 0X END;
      IF (c = "-") OR (c = "_") OR (c = "0") THEN
        IF c = "-" THEN fill := 0X ELSIF c = "_" THEN fill := " " ELSE fill := "0" END;
        INC(i); IF i < n THEN c := spec[i] ELSE c := 0X END
      ELSIF c = "e" THEN fill := " "
      ELSE fill := "0"
      END;
      CASE c OF
        "a": T.WeekdayName(p.weekday, name); name[3] := 0X; PutS(name)
      | "A": T.WeekdayName(p.weekday, name); PutS(name)
      | "b": T.MonthName(p.month, name); name[3] := 0X; PutS(name)
      | "B": T.MonthName(p.month, name); PutS(name)
      | "c": Spec(t, "%x, %X")
      | "d", "e": Pad(p.day, fill, 2)
      | "f": Pad(p.ms, fill, 3); PutS("000")
      | "g": IsoThursday(p, q); Pad(Rem(q.year, 100), fill, 2)
      | "G": IsoThursday(p, q); Pad(Rem(q.year, 10000), fill, 4)
      | "H": Pad(p.hour, fill, 2)
      | "I": IF p.hour MOD 12 = 0 THEN Pad(12, fill, 2) ELSE Pad(p.hour MOD 12, fill, 2) END
      | "j": Pad(1 + DayNumber(p) - YearStart(p), fill, 3)
      | "L": Pad(p.ms, fill, 3)
      | "m": Pad(p.month, fill, 2)
      | "M": Pad(p.minute, fill, 2)
      | "p": IF p.hour >= 12 THEN PutS("PM") ELSE PutS("AM") END
      | "q": Pad(1 + (p.month - 1) DIV 3, 0X, 0)
      | "Q": Pad(t, 0X, 0)
      | "s": Pad(t DIV 1000, 0X, 0)
      | "S": Pad(p.second, fill, 2)
      | "u": IF p.weekday = 0 THEN Pad(7, 0X, 0) ELSE Pad(p.weekday, 0X, 0) END
      | "U": Pad(WeekCount(YearStart(p) - 1, DayNumber(p), 0), fill, 2)
      | "V":
        IsoThursday(p, q);
        x := WeekCount(YearStart(q), DayNumber(q), 4);
        IF (YearStart(q) + 4) MOD 7 = 4 THEN INC(x) END;
        Pad(x, fill, 2)
      | "w": Pad(p.weekday, 0X, 0)
      | "W": Pad(WeekCount(YearStart(p) - 1, DayNumber(p), 1), fill, 2)
      | "x": Spec(t, "%-m/%-d/%Y")
      | "X": Spec(t, "%-I:%M:%S %p")
      | "y": Pad(Rem(p.year, 100), fill, 2)
      | "Y": Pad(Rem(p.year, 10000), fill, 4)
      | "Z":
        x := p.offset DIV 60;   (* minutes east *)
        IF x < 0 THEN Put("-"); x := -x ELSE Put("+") END;
        Pad(x DIV 60, "0", 2); Pad(x MOD 60, "0", 2)
      | "%": Put("%")
      | 0X:
      ELSE Put(c)
      END
    ELSE Put(spec[i])
    END;
    INC(i)
  END
END Spec;

(* t formatted by spec, as d3's timeFormat(spec)(t) *)
PROCEDURE Format*(t: HUGEINT; spec: ARRAY OF CHAR; VAR s: Str);
BEGIN
  bufLen := 0; Spec(t, spec);
  s := L.Sub(buf^, 0, bufLen); bufLen := 0
END Format;

BEGIN
  NEW(buf, 256); bufLen := 0
END PmGanttScale.
