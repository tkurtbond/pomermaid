MODULE PmGanttTime;
(* PmGanttTime: the dates and times of a Gantt chart, as Mermaid's
   ganttDb.js reads and computes them, with dayjs 1.11 and JavaScript's
   Date, in local time (decision 16).

   A time is a HUGEINT count of milliseconds since 1970-01-01 UTC, as a
   JavaScript Date's value is. It is broken into the local date and time
   of day, and made from them, through poDateTime's TimeZones.Local, the
   C library's zone, so that TZ is honoured; a local time in a gap of
   daylight saving time is read with the offset before it, and one in an
   overlap as the earlier instant, as JavaScript reads them. Times are
   kept to the years -9999 .. 9999.

   What dayjs does, and pomermaid with it:

   - Parse, dayjs(str, format, true): customParseFormat's strict parse.
     The format's tokens are read in order; each value is looked for in
     what is left of the text after the literal text before it, and is
     then taken out of the text. Fields not given come from today: the
     day if neither the year nor the month is given, else 1; the year;
     the month if the year is not given. With a zone ("Z") the time is
     UTC less the offset; else it is local. The text is the date only if
     the date formatted by the format gives the text back. Formats with
     localizedFormat's tokens (L, LL, l ...) never give a date, as
     Mermaid does not load that plugin to format them; "w" and "ww"
     need the week plugin, which it does not load either.
   - Format, dayjs's format with advancedFormat and isoWeek: "Q", "Do",
     "W", "WW", "GGGG", "k", "kk", "X", "x", then the core's tokens;
     "[text]" is text. "w", "ww", "wo", "gggg", "z" and "zzz" need
     plugins Mermaid does not load, and make Mermaid fail; Format
     returns FALSE for them.
   - Add, dayjs's add: months and years keep the day if the month has
     it, else the month's last day; days and weeks are local days, the
     count rounded; hours, minutes, seconds and milliseconds are exact.
   - DateParse, JavaScript's Date(str), V8's: the ISO forms (a date
     alone is UTC midnight, a date and time without a zone is local
     time), and a part of the older forms: "2014-1-6 10:00",
     "2014/01/06", "01/06/2014", "Jan 6, 2014", "6 January 2014 10:00
     pm", with a weekday's name before, and with "Z", "UTC", "GMT" or
     an offset after, read as local time when they have no zone.
   - Now is today and the time: SOURCE_DATE_EPOCH's seconds if it is
     set, else the clock (decision 14). *)

IMPORT Platform, Calendar, Instants, TimeZones, L := PmLex;

CONST
  Second* = 1000; Minute* = 60000; Hour* = 3600000; Day* = 86400000;
  (* the times kept to: -9999-01-03 and 9999-12-29, UTC, so that the
     local dates are in poDateTime's years *)
  minTime = -377705116800000 + 2 * Day;
  maxTime = 253402300799000 - 2 * Day;

TYPE
  Str = L.Str;

  (* A time's local date and time of day *)
  Parts* = RECORD
    year*, month*, day*: LONGINT;   (* month 1 .. 12 *)
    hour*, minute*, second*, ms*: LONGINT;
    weekday*: LONGINT;    (* 0 Sunday .. 6 Saturday *)
    offset*: LONGINT      (* seconds east of UTC *)
  END;

VAR
  zone: TimeZones.Zone;
  now: HUGEINT; nowSet: BOOLEAN;
  months: ARRAY 12, 10 OF CHAR;
  weekdays: ARRAY 7, 10 OF CHAR;
  buf: Str; bufLen: LONGINT;      (* what Format and the parse build *)

(* Numbers *)

(* x rounded down, for x's whose quotient by 10^9 a LONGINT holds *)
PROCEDURE Floor*(x: LONGREAL): HUGEINT;
  VAR q: LONGINT; h: HUGEINT;
BEGIN
  q := ENTIER(x / 1.0D9);
  h := q;
  RETURN h * 1000000000 + ENTIER(x - q * 1.0D9)
END Floor;

(* x rounded toward zero *)
PROCEDURE Trunc*(x: LONGREAL): HUGEINT;
BEGIN
  IF x >= 0 THEN RETURN Floor(x) ELSE RETURN -Floor(-x) END
END Trunc;

(* x rounded as JavaScript's Math.round: half up *)
PROCEDURE Round*(x: LONGREAL): HUGEINT;
BEGIN
  RETURN Floor(x + 0.5D0)
END Round;

PROCEDURE IsDigit(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch >= "0") & (ch <= "9")
END IsDigit;

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* The number written in s[start .. end-1], an optional sign and
   digits; FALSE if it is not one or is beyond 10^15 *)
PROCEDURE Int(VAR s: ARRAY OF CHAR; start, end: LONGINT; VAR n: HUGEINT): BOOLEAN;
  VAR neg: BOOLEAN;
BEGIN
  neg := FALSE; n := 0;
  IF (start < end) & ((s[start] = "+") OR (s[start] = "-")) THEN
    neg := s[start] = "-"; INC(start)
  END;
  IF start >= end THEN RETURN FALSE END;
  WHILE start < end DO
    IF ~IsDigit(s[start]) OR (n > 100000000000000) THEN RETURN FALSE END;
    n := n * 10 + (ORD(s[start]) - ORD("0")); INC(start)
  END;
  IF neg THEN n := -n END;
  RETURN TRUE
END Int;

(* The buffer *)

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

(* n, as JavaScript's String(n), padded as dayjs's padStart pads it: with
   "0"s before it to width characters, sign and all *)
PROCEDURE PutInt(n: HUGEINT; width: INTEGER);
  VAR d: ARRAY 24 OF CHAR; k, len: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + SHORT(SHORT(n MOD 10))); n := n DIV 10; INC(k) UNTIL n = 0;
  len := k; IF neg THEN INC(len) END;
  WHILE len < width DO Put("0"); INC(len) END;
  IF neg THEN Put("-") END;
  WHILE k > 0 DO DEC(k); Put(d[k]) END
END PutInt;

(* The buffer's text, as a new Str *)
PROCEDURE Take(): Str;
  VAR s: Str;
BEGIN
  s := L.Sub(buf^, 0, bufLen); bufLen := 0;
  RETURN s
END Take;

(* Local dates and times *)

(* The local date and time of day of t *)
PROCEDURE Break*(t: HUGEINT; VAR p: Parts);
  VAR it: Instants.Instant; odt: Calendar.OffsetDateTime;
BEGIN
  Instants.FromUnixMilliseconds(it, t);
  TimeZones.ToLocal(zone, it, odt);
  p.year := odt.year; p.month := odt.month; p.day := odt.day;
  p.hour := odt.hour; p.minute := odt.minute; p.second := odt.second;
  p.ms := odt.nanosecond DIV 1000000;
  p.weekday := Calendar.DayOfWeek(odt) MOD 7;
  p.offset := odt.offset
END Break;

(* The milliseconds of the date and time of day, as UTC, normalised as
   JavaScript's MakeDay and MakeTime normalise them: month0 is from 0,
   and any field may be beyond its range; a year 0 .. 99 is 1900 ..
   1999. FALSE beyond the years. *)
PROCEDURE Compose(year, month0, day, hour, minute, second, ms: LONGINT; VAR r: HUGEINT): BOOLEAN;
  VAR date: Calendar.Date; x: HUGEINT;
BEGIN
  IF (year >= 0) & (year <= 99) THEN INC(year, 1900) END;
  INC(year, month0 DIV 12); month0 := month0 MOD 12;
  IF (year < Calendar.minYear) OR (year > Calendar.maxYear) THEN RETURN FALSE END;
  date.year := year; date.month := month0 + 1; date.day := 1;
  r := Calendar.DayNumber(date) + day - 1;
  r := r * Day;
  x := hour; r := r + x * Hour;
  x := minute; r := r + x * Minute;
  x := second; r := r + x * Second + ms;
  RETURN (r >= minTime) & (r <= maxTime)
END Compose;

(* The time of a local date and time of day, as JavaScript's new
   Date(year, month0, day, hour, minute, second, ms) *)
PROCEDURE Local*(year, month0, day, hour, minute, second, ms: LONGINT; VAR t: HUGEINT): BOOLEAN;
  VAR local: HUGEINT; u, it: Instants.Instant; dt: Calendar.DateTime;
BEGIN
  IF ~Compose(year, month0, day, hour, minute, second, ms, local) THEN RETURN FALSE END;
  Instants.FromUnixMilliseconds(u, local);
  Calendar.FromUTCInstant(dt, u);
  IF ~TimeZones.ToInstant(zone, dt, TimeZones.earlier, it) THEN RETURN FALSE END;
  t := Instants.UnixMilliseconds(it);
  RETURN (t >= minTime) & (t <= maxTime)
END Local;

(* The time of a UTC date and time of day, as JavaScript's Date.UTC *)
PROCEDURE UTC*(year, month0, day, hour, minute, second, ms: LONGINT; VAR t: HUGEINT): BOOLEAN;
BEGIN
  RETURN Compose(year, month0, day, hour, minute, second, ms, t)
END UTC;

(* Whether t is a time pomermaid keeps *)
PROCEDURE Valid*(t: HUGEINT): BOOLEAN;
BEGIN
  RETURN (t >= minTime) & (t <= maxTime)
END Valid;

(* Today and the time now: SOURCE_DATE_EPOCH's, or the clock's *)
PROCEDURE Now*(): HUGEINT;
  VAR s: ARRAY 64 OF CHAR; n: HUGEINT; odt: Calendar.OffsetDateTime; it: Instants.Instant;
BEGIN
  IF ~nowSet THEN
    IF Platform.getEnv("SOURCE_DATE_EPOCH", s) & Int(s, 0, L.Length(s), n)
      & (n * Second >= minTime) & (n * Second <= maxTime) THEN
      now := n * Second
    ELSE
      TimeZones.Now(zone, odt); Calendar.ToInstant(odt, it);
      now := Instants.UnixMilliseconds(it)
    END;
    nowSet := TRUE
  END;
  RETURN now
END Now;

(* The local midnight that starts t's day, as setHours(0, 0, 0, 0) *)
PROCEDURE StartOfDay*(t: HUGEINT): HUGEINT;
  VAR p: Parts; r: HUGEINT;
BEGIN
  Break(t, p);
  IF ~Local(p.year, p.month - 1, p.day, 0, 0, 0, 0, r) THEN r := t END;
  RETURN r
END StartOfDay;

(* Today's local midnight *)
PROCEDURE Today*(): HUGEINT;
BEGIN
  RETURN StartOfDay(Now())
END Today;

(* dayjs's isoWeekday of t: 1 Monday .. 7 Sunday *)
PROCEDURE IsoWeekday*(t: HUGEINT): LONGINT;
  VAR p: Parts;
BEGIN
  Break(t, p);
  IF p.weekday = 0 THEN RETURN 7 END;
  RETURN p.weekday
END IsoWeekday;

(* dayjs's add: t plus n of unit, one of "y", "M", "w", "d", "h", "m",
   "s" and "ms"; FALSE beyond the years *)
PROCEDURE Add*(t: HUGEINT; n: LONGREAL; unit: ARRAY OF CHAR; VAR r: HUGEINT): BOOLEAN;
  VAR p: Parts; y, m, dim: LONGINT; x: LONGREAL; ok: BOOLEAN;
BEGIN
  Break(t, p);
  IF ((unit = "M") OR (unit = "y") OR (unit = "d") OR (unit = "w")) & (ABS(n) > 1.0D8) THEN
    RETURN FALSE   (* beyond every valid date *)
  END;
  IF (unit = "M") OR (unit = "y") THEN
    y := p.year; m := p.month - 1;
    IF unit = "M" THEN x := m; m := SHORT(Trunc(x + n))
    ELSE x := y; y := SHORT(Trunc(x + n))
    END;
    INC(y, m DIV 12); m := m MOD 12;
    IF (y < Calendar.minYear) OR (y > Calendar.maxYear) THEN RETURN FALSE END;
    dim := Calendar.DaysInMonth(y, m + 1);
    IF p.day < dim THEN dim := p.day END;
    ok := Local(y, m, dim, p.hour, p.minute, p.second, p.ms, r)
  ELSIF (unit = "d") OR (unit = "w") THEN
    IF unit = "w" THEN n := n * 7 END;
    IF ABS(n) > 1.0D7 THEN RETURN FALSE END;
    ok := Local(p.year, p.month - 1, p.day + SHORT(Round(n)), p.hour, p.minute, p.second, p.ms, r)
  ELSE
    x := t;
    IF unit = "h" THEN x := x + n * Hour
    ELSIF unit = "m" THEN x := x + n * Minute
    ELSIF unit = "s" THEN x := x + n * Second
    ELSE x := x + n
    END;
    ok := (x >= minTime) & (x <= maxTime);
    IF ok THEN r := Trunc(x) END
  END;
  RETURN ok
END Add;

(* Formatting *)

(* dayjs's utcOffset, in minutes, rounded to 15 as it rounds it *)
PROCEDURE UtcOffset(VAR p: Parts): LONGINT;
  VAR x: LONGREAL;
BEGIN
  x := -p.offset; x := x / 60 / 15;
  RETURN -SHORT(Round(x)) * 15
END UtcOffset;

(* dayjs's padZoneStr: "+01:00", or "+0100" without colon *)
PROCEDURE PutZone(VAR p: Parts; colon: BOOLEAN);
  VAR neg, minutes: LONGINT;
BEGIN
  neg := -UtcOffset(p); minutes := ABS(neg);
  IF neg <= 0 THEN Put("+") ELSE Put("-") END;
  PutInt(minutes DIV 60, 2);
  IF colon THEN Put(":") END;
  PutInt(minutes MOD 60, 2)
END PutZone;

(* The English locale's ordinal: "1st", "2nd", "11th" *)
PROCEDURE PutOrdinal(n: LONGINT);
  VAR v, k: LONGINT;
BEGIN
  PutInt(n, 0);
  v := n MOD 100;
  IF v >= 20 THEN k := (v - 20) MOD 10 ELSE k := v END;
  IF k = 1 THEN PutS("st") ELSIF k = 2 THEN PutS("nd") ELSIF k = 3 THEN PutS("rd")
  ELSE PutS("th")
  END
END PutOrdinal;

(* The length of the run of ch at f[i], up to max *)
PROCEDURE Run(VAR f: ARRAY OF CHAR; i: LONGINT; ch: CHAR; max: INTEGER): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := 0;
  WHILE (n < max) & (i + n < LEN(f)) & (f[i + n] = ch) DO INC(n) END;
  RETURN n
END Run;

(* The end of the "[text]" at f[i], after its "]", or -1: the text has
   one or more characters, none "]" *)
PROCEDURE Bracket(VAR f: ARRAY OF CHAR; i: LONGINT): LONGINT;
  VAR k: LONGINT;
BEGIN
  IF f[i] # "[" THEN RETURN -1 END;
  k := i + 1;
  WHILE (k < LEN(f)) & (f[k] # 0X) & (f[k] # "]") DO INC(k) END;
  IF (k < LEN(f)) & (f[k] = "]") & (k > i + 1) THEN RETURN k + 1 END;
  RETURN -1
END Bracket;

(* advancedFormat's pass; FALSE for a token Mermaid fails on *)
PROCEDURE Advanced(t: HUGEINT; VAR p: Parts; VAR f: ARRAY OF CHAR): BOOLEAN;
  VAR i, e, wy, w: LONGINT; n: INTEGER; ch: CHAR; date: Calendar.Date; q: HUGEINT;
BEGIN
  i := 0;
  WHILE (i < LEN(f)) & (f[i] # 0X) DO
    ch := f[i]; e := Bracket(f, i);
    IF e >= 0 THEN WHILE i < e DO Put(f[i]); INC(i) END
    ELSIF ch = "Q" THEN PutInt((p.month + 2) DIV 3, 0); INC(i)
    ELSIF (ch = "w") OR (ch = "z") THEN RETURN FALSE
    ELSIF ch = "W" THEN
      n := Run(f, i, "W", 2);
      date.year := p.year; date.month := p.month; date.day := p.day;
      Calendar.IsoWeek(date, wy, w); PutInt(w, n); INC(i, n)
    ELSIF (ch = "g") & (Run(f, i, "g", 4) = 4) THEN RETURN FALSE
    ELSIF (ch = "G") & (Run(f, i, "G", 4) = 4) THEN
      date.year := p.year; date.month := p.month; date.day := p.day;
      Calendar.IsoWeek(date, wy, w); PutInt(wy, 0); INC(i, 4)
    ELSIF (ch = "D") & (i + 1 < LEN(f)) & (f[i + 1] = "o") THEN
      Put("["); PutOrdinal(p.day); Put("]"); INC(i, 2)
    ELSIF ch = "X" THEN
      q := t DIV Second; PutInt(q, 0); INC(i)
    ELSIF ch = "x" THEN PutInt(t, 0); INC(i)
    ELSIF ch = "k" THEN
      n := Run(f, i, "k", 2);
      IF p.hour = 0 THEN PutInt(24, n) ELSE PutInt(p.hour, n) END;
      INC(i, n)
    ELSE Put(ch); INC(i)
    END
  END;
  RETURN TRUE
END Advanced;

(* The core's pass *)
PROCEDURE Core(VAR p: Parts; VAR f: ARRAY OF CHAR);
  VAR i, e, h: LONGINT; n: INTEGER; ch: CHAR; s: ARRAY 12 OF CHAR;
BEGIN
  i := 0;
  WHILE (i < LEN(f)) & (f[i] # 0X) DO
    ch := f[i]; e := Bracket(f, i);
    IF e >= 0 THEN
      INC(i); WHILE i < e - 1 DO Put(f[i]); INC(i) END; i := e
    ELSIF (ch = "Y") & (Run(f, i, "Y", 4) = 4) THEN PutInt(p.year, 4); INC(i, 4)
    ELSIF (ch = "Y") & (Run(f, i, "Y", 2) = 2) THEN
      (* String(year).slice(-2) *)
      bufLen := bufLen; PutInt(p.year, 0);
      IF ABS(p.year) >= 10 THEN
        (* keep the last two of what was put *)
        h := 2; IF p.year < 0 THEN h := 2 END;
        s[0] := buf[bufLen - 2]; s[1] := buf[bufLen - 1];
        WHILE (bufLen > 0) & ((buf[bufLen - 1] = "-") OR IsDigit(buf[bufLen - 1])) DO DEC(bufLen) END;
        Put(s[0]); Put(s[1])
      END;
      INC(i, 2)
    ELSIF ch = "M" THEN
      n := Run(f, i, "M", 4);
      IF n = 1 THEN PutInt(p.month, 0)
      ELSIF n = 2 THEN PutInt(p.month, 2)
      ELSIF n = 3 THEN
        COPY(months[p.month - 1], s); s[3] := 0X; PutS(s)
      ELSE PutS(months[p.month - 1])
      END;
      INC(i, n)
    ELSIF ch = "D" THEN
      n := Run(f, i, "D", 2); PutInt(p.day, n); INC(i, n)
    ELSIF ch = "d" THEN
      n := Run(f, i, "d", 4);
      IF n = 1 THEN PutInt(p.weekday, 0)
      ELSIF n = 4 THEN PutS(weekdays[p.weekday])
      ELSE COPY(weekdays[p.weekday], s); s[n] := 0X; PutS(s)
      END;
      INC(i, n)
    ELSIF ch = "H" THEN
      n := Run(f, i, "H", 2); PutInt(p.hour, n); INC(i, n)
    ELSIF ch = "h" THEN
      n := Run(f, i, "h", 2); h := p.hour MOD 12; IF h = 0 THEN h := 12 END;
      PutInt(h, n); INC(i, n)
    ELSIF ch = "a" THEN
      IF p.hour < 12 THEN PutS("am") ELSE PutS("pm") END; INC(i)
    ELSIF ch = "A" THEN
      IF p.hour < 12 THEN PutS("AM") ELSE PutS("PM") END; INC(i)
    ELSIF ch = "m" THEN
      n := Run(f, i, "m", 2); PutInt(p.minute, n); INC(i, n)
    ELSIF ch = "s" THEN
      n := Run(f, i, "s", 2); PutInt(p.second, n); INC(i, n)
    ELSIF ch = "Z" THEN
      n := Run(f, i, "Z", 2); PutZone(p, n = 1); INC(i, n)
    ELSIF (ch = "S") & (Run(f, i, "S", 3) = 3) THEN PutInt(p.ms, 3); INC(i, 3)
    ELSE Put(ch); INC(i)
    END
  END
END Core;

(* t formatted as dayjs's format(fmt) formats it, with advancedFormat
   and isoWeek; an empty format is dayjs's default,
   "YYYY-MM-DDTHH:mm:ssZ". FALSE for the tokens that make Mermaid
   fail: "w", "ww", "wo", "gggg", "z", "zzz". *)
PROCEDURE Format*(t: HUGEINT; fmt: ARRAY OF CHAR; VAR s: Str): BOOLEAN;
  VAR p: Parts; pass: Str;
BEGIN
  Break(t, p); bufLen := 0;
  IF fmt = "" THEN COPY("YYYY-MM-DDTHH:mm:ssZ", fmt) END;
  IF (LEN(fmt) < 21) & (fmt[0] = 0X) THEN
    pass := L.New("YYYY-MM-DDTHH:mm:ssZ")
  ELSE
    IF ~Advanced(t, p, fmt) THEN bufLen := 0; RETURN FALSE END;
    pass := Take()
  END;
  Core(p, pass^);
  s := Take();
  RETURN TRUE
END Format;

(* Parsing *)

CONST
  (* the regular expressions of customParseFormat's values *)
  match1 = 1; match2 = 2; match3 = 3; match4 = 4; match1to2 = 5;
  matchSigned = 6; matchOffset = 7; matchWord = 8;

TYPE
  Fields = RECORD
    year, month, day, hours, minutes, seconds, ms, week, offset: HUGEINT;
    hasZone, dayGiven, afternoon, hasMeridiem: BOOLEAN
  END;

(* Whether ch is one of what matchWord's [^-_:/,()\s\d] leaves out *)
PROCEDURE NotWord(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = "-") OR (ch = "_") OR (ch = ":") OR (ch = "/") OR (ch = ",")
    OR (ch = "(") OR (ch = ")") OR (ch = " ") OR (ch = 09X) OR (ch = 0AX)
    OR (ch = 0BX) OR (ch = 0CX) OR (ch = 0DX) OR IsDigit(ch)
END NotWord;

(* The leftmost match of the expression kind in s[from ..], its start in
   ms and its length in ml *)
PROCEDURE Search(kind: INTEGER; VAR s: ARRAY OF CHAR; from: LONGINT; VAR ms, ml: LONGINT): BOOLEAN;
  VAR i, k, len, need: LONGINT;
BEGIN
  len := L.Length(s);
  i := from;
  WHILE i < len DO
    CASE kind OF
    | match1, match2, match3, match4:
      need := kind; k := 0;
      WHILE (k < need) & (i + k < len) & IsDigit(s[i + k]) DO INC(k) END;
      IF k = need THEN ms := i; ml := need; RETURN TRUE END
    | match1to2:
      IF IsDigit(s[i]) THEN
        ms := i; ml := 1; IF IsDigit(s[i + 1]) THEN ml := 2 END; RETURN TRUE
      END
    | matchSigned:
      k := i; IF ((s[k] = "+") OR (s[k] = "-")) & IsDigit(s[k + 1]) THEN INC(k) END;
      IF IsDigit(s[k]) THEN
        WHILE IsDigit(s[k]) DO INC(k) END;
        ms := i; ml := k - i; RETURN TRUE
      END
    | matchOffset:
      IF ((s[i] = "+") OR (s[i] = "-")) & IsDigit(s[i + 1]) & IsDigit(s[i + 2]) THEN
        k := i + 3;
        IF s[k] = ":" THEN INC(k) END;
        IF IsDigit(s[k]) & IsDigit(s[k + 1]) THEN INC(k, 2) END;
        ms := i; ml := k - i; RETURN TRUE
      ELSIF s[i] = "Z" THEN ms := i; ml := 1; RETURN TRUE
      END
    | matchWord:
      k := i; WHILE IsDigit(s[k]) DO INC(k) END;
      IF (k < len) & ~NotWord(s[k]) THEN
        WHILE (k < len) & ~NotWord(s[k]) DO INC(k) END;
        ms := i; ml := k - i; RETURN TRUE
      END
    END;
    INC(i)
  END;
  RETURN FALSE
END Search;

(* Takes the first occurrence of s[ms .. ms+ml-1] out of s, as
   String.replace(value, "") does *)
PROCEDURE Remove(VAR s: ARRAY OF CHAR; ms, ml: LONGINT);
  VAR i, k, len: LONGINT; v: Str;
BEGIN
  v := L.Sub(s, ms, ml); len := L.Length(s);
  i := 0;
  LOOP
    k := 0;
    WHILE (k < ml) & (s[i + k] = v[k]) DO INC(k) END;
    IF k = ml THEN EXIT END;
    INC(i)
  END;
  WHILE i + ml <= len DO s[i] := s[i + ml]; INC(i) END
END Remove;

(* The index of the month whose name, or whose name's first three
   letters with short, is s[ms .. ms+ml-1], from 1; 0 if none *)
PROCEDURE MonthNamed(VAR s: ARRAY OF CHAR; ms, ml: LONGINT; short: BOOLEAN): LONGINT;
  VAR m, k: LONGINT;
BEGIN
  FOR m := 0 TO 11 DO
    IF (short & (ml = 3)) OR (~short & (ml = L.Length(months[m]))) THEN
      k := 0;
      WHILE (k < ml) & (s[ms + k] = months[m][k]) DO INC(k) END;
      IF k = ml THEN RETURN m + 1 END
    END
  END;
  RETURN 0
END MonthNamed;

(* Whether s[ms .. ms+ml-1] is w *)
PROCEDURE Is(VAR s: ARRAY OF CHAR; ms, ml: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  IF ml # L.Length(w) THEN RETURN FALSE END;
  FOR k := 0 TO ml - 1 DO IF s[ms + k] # w[k] THEN RETURN FALSE END END;
  RETURN TRUE
END Is;

(* Reads the value of token tok, f[ts .. ts+tl-1], at input[start ..]
   into fl; FALSE where dayjs throws *)
PROCEDURE Value(VAR f: ARRAY OF CHAR; ts, tl: LONGINT; VAR input: ARRAY OF CHAR;
                start: LONGINT; VAR fl: Fields): BOOLEAN;
  VAR kind: INTEGER; ch: CHAR; ms, ml, k: LONGINT; n: HUGEINT; ok: BOOLEAN;
BEGIN
  ch := f[ts];
  IF (ch = "A") OR (ch = "a") OR (ch = "M") & (tl >= 3) OR (ch = "D") & (tl = 2) & (f[ts + 1] = "o") THEN
    kind := matchWord
  ELSIF ch = "Q" THEN kind := match1
  ELSIF ch = "S" THEN kind := SHORT(tl)
  ELSIF (ch = "D") & (tl = 2) OR (ch = "w") & (tl = 2) OR (ch = "M") & (tl = 2) THEN kind := match2
  ELSIF ch = "Y" THEN
    IF tl = 1 THEN kind := matchSigned ELSIF tl = 2 THEN kind := match2 ELSE kind := match4 END
  ELSIF ch = "Z" THEN kind := matchOffset
  ELSE kind := match1to2
  END;
  IF (start > L.Length(input)) OR ~Search(kind, input, start, ms, ml) THEN RETURN FALSE END;
  ok := TRUE;
  IF (kind # matchWord) & (kind # matchOffset) THEN ok := Int(input, ms, ms + ml, n) END;
  IF ~ok THEN RETURN FALSE END;
  IF ch = "A" THEN fl.hasMeridiem := TRUE; fl.afternoon := Is(input, ms, ml, "PM")
  ELSIF ch = "a" THEN fl.hasMeridiem := TRUE; fl.afternoon := Is(input, ms, ml, "pm")
  ELSIF ch = "Q" THEN fl.month := (n - 1) * 3 + 1
  ELSIF ch = "S" THEN
    IF tl = 1 THEN fl.ms := n * 100 ELSIF tl = 2 THEN fl.ms := n * 10 ELSE fl.ms := n END
  ELSIF ch = "s" THEN fl.seconds := n
  ELSIF ch = "m" THEN fl.minutes := n
  ELSIF (ch = "H") OR (ch = "h") THEN fl.hours := n
  ELSIF (ch = "D") & (tl = 2) & (f[ts + 1] = "o") THEN
    (* the first digits; then the English ordinals, "1st" .. "31st" *)
    k := ms; WHILE (k < ms + ml) & ~IsDigit(input[k]) DO INC(k) END;
    IF k = ms + ml THEN RETURN FALSE END;
    n := 0;
    WHILE (k < ms + ml) & IsDigit(input[k]) & (n < 100000000) DO
      n := n * 10 + ORD(input[k]) - ORD("0"); INC(k)
    END;
    fl.day := n; fl.dayGiven := TRUE
  ELSIF ch = "D" THEN fl.day := n
  ELSIF ch = "w" THEN fl.week := n
  ELSIF ch = "M" THEN
    IF tl <= 2 THEN fl.month := n
    ELSE
      n := MonthNamed(input, ms, ml, tl = 3);
      IF n = 0 THEN RETURN FALSE END;
      fl.month := n
    END
  ELSIF ch = "Y" THEN
    IF tl = 2 THEN
      IF n > 68 THEN fl.year := n + 1900 ELSE fl.year := n + 2000 END
    ELSE fl.year := n
    END
  ELSIF ch = "Z" THEN
    fl.hasZone := TRUE; fl.offset := 0;
    IF input[ms] # "Z" THEN
      n := (ORD(input[ms + 1]) - ORD("0")) * 10 + ORD(input[ms + 2]) - ORD("0");
      n := n * 60;
      k := ms + 3; IF input[k] = ":" THEN INC(k) END;
      IF (k + 1 < ms + ml) THEN n := n + (ORD(input[k]) - ORD("0")) * 10 + ORD(input[k + 1]) - ORD("0") END;
      IF input[ms] = "+" THEN fl.offset := -n ELSE fl.offset := n END
    END
  END;
  Remove(input, ms, ml);
  RETURN TRUE
END Value;

(* Whether ch is one of formattingTokens' separators, [-_:/.,()\s] *)
PROCEDURE IsSep(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = "-") OR (ch = "_") OR (ch = ":") OR (ch = "/") OR (ch = ".") OR (ch = ",")
    OR (ch = "(") OR (ch = ")") OR (ch = " ") OR (ch = 09X) OR (ch = 0AX)
    OR (ch = 0BX) OR (ch = 0CX) OR (ch = 0DX)
END IsSep;

(* The length of the value token at f[i], or 0: A|a|Q|YYYY|YY?|ww?|
   MM?M?M?|Do|DD?|hh?|HH?|mm?|ss?|S{1,3}|z|ZZ? *)
PROCEDURE Token(VAR f: ARRAY OF CHAR; i: LONGINT): INTEGER;
  VAR ch: CHAR;
BEGIN
  ch := f[i];
  IF (ch = "A") OR (ch = "a") OR (ch = "Q") OR (ch = "z") THEN RETURN 1
  ELSIF ch = "Y" THEN
    IF Run(f, i, "Y", 4) = 4 THEN RETURN 4 END;
    RETURN Run(f, i, "Y", 2)
  ELSIF ch = "M" THEN RETURN Run(f, i, "M", 4)
  ELSIF ch = "D" THEN
    IF f[i + 1] = "o" THEN RETURN 2 END;
    RETURN Run(f, i, "D", 2)
  ELSIF (ch = "w") OR (ch = "h") OR (ch = "H") OR (ch = "m") OR (ch = "s") OR (ch = "Z") THEN
    RETURN Run(f, i, ch, 2)
  ELSIF ch = "S" THEN RETURN Run(f, i, "S", 3)
  END;
  RETURN 0
END Token;

(* Whether the format has localizedFormat's tokens, LTS?|l{1,4}|L{1,4},
   outside "[...]" *)
PROCEDURE Localized(VAR f: ARRAY OF CHAR): BOOLEAN;
  VAR i, e: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(f)) & (f[i] # 0X) DO
    e := Bracket(f, i);
    IF e >= 0 THEN i := e
    ELSIF (f[i] = "L") OR (f[i] = "l") THEN RETURN TRUE
    ELSE INC(i)
    END
  END;
  RETURN FALSE
END Localized;

(* customParseFormat's parse of input by format, without the strict
   check *)
PROCEDURE ParseFields(VAR input, f: ARRAY OF CHAR; VAR t: HUGEINT): BOOLEAN;
  VAR i, k, e, len, start: LONGINT; tl: INTEGER; in: Str; fl: Fields;
    p: Parts; y, m, d: HUGEINT; ok: BOOLEAN;
BEGIN
  in := L.New(input);
  fl.year := 0; fl.month := 0; fl.day := 0; fl.hours := 0; fl.minutes := 0;
  fl.seconds := 0; fl.ms := 0; fl.week := 0; fl.offset := 0;
  fl.hasZone := FALSE; fl.dayGiven := FALSE; fl.hasMeridiem := FALSE; fl.afternoon := FALSE;
  len := L.Length(f); i := 0; start := 0;
  WHILE i < len DO
    IF f[i] = "[" THEN
      (* \[[^[]*\]: to the last "]" before the next "[" *)
      k := i + 1; e := -1;
      WHILE (k < len) & (f[k] # "[") DO IF f[k] = "]" THEN e := k END; INC(k) END;
      IF e >= 0 THEN
        (* the brackets taken off, the text's length *)
        INC(start, e - i - 1); i := e + 1
      ELSE INC(i)
      END
    ELSIF IsSep(f[i]) THEN
      k := i; WHILE (k < len) & IsSep(f[k]) DO INC(k) END;
      INC(start, k - i); i := k
    ELSE
      tl := Token(f, i);
      IF tl = 0 THEN INC(i)
      ELSIF f[i] = "z" THEN INC(start); INC(i)
      ELSE
        IF ~Value(f, i, tl, in^, start, fl) THEN RETURN FALSE END;
        INC(i, tl)
      END
    END
  END;
  IF fl.hasMeridiem THEN
    IF fl.afternoon THEN IF fl.hours < 12 THEN INC(fl.hours, 12) END
    ELSIF fl.hours = 12 THEN fl.hours := 0
    END
  END;
  IF fl.week # 0 THEN RETURN FALSE END;   (* the week plugin is not loaded *)
  Break(Now(), p);
  IF fl.day # 0 THEN d := fl.day
  ELSIF fl.dayGiven THEN d := 0
  ELSIF (fl.year = 0) & (fl.month = 0) THEN d := p.day
  ELSE d := 1
  END;
  IF fl.year # 0 THEN y := fl.year ELSE y := p.year END;
  IF (fl.year # 0) & (fl.month = 0) THEN m := 0
  ELSIF fl.month > 0 THEN m := fl.month - 1
  ELSE m := p.month - 1
  END;
  IF (ABS(y) > 1000000) OR (ABS(d) > 1000000) OR (fl.hours > 1000000) OR (fl.minutes > 1000000)
    OR (fl.seconds > 1000000) OR (fl.ms > 1000000) OR (ABS(m) > 1000000) THEN
    RETURN FALSE
  END;
  IF fl.hasZone THEN
    ok := UTC(SHORT(y), SHORT(m), SHORT(d), SHORT(fl.hours), SHORT(fl.minutes),
      SHORT(fl.seconds), SHORT(fl.ms + fl.offset * Minute), t)
  ELSE
    ok := Local(SHORT(y), SHORT(m), SHORT(d), SHORT(fl.hours), SHORT(fl.minutes),
      SHORT(fl.seconds), SHORT(fl.ms), t)
  END;
  RETURN ok
END ParseFields;

(* Whether a and b hold the same text *)
PROCEDURE Same(VAR a, b: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(a)) & (i < LEN(b)) & (a[i] = b[i]) & (a[i] # 0X) DO INC(i) END;
  RETURN ((i = LEN(a)) OR (a[i] = 0X)) & ((i = LEN(b)) OR (b[i] = 0X))
END Same;

(* dayjs(input, format, true), the strict parse: the time in t; FALSE if
   it is not a date. failed is TRUE where Mermaid fails, a format with
   a token that needs a plugin it does not load. *)
PROCEDURE Parse*(input, format: ARRAY OF CHAR; VAR t: HUGEINT; VAR failed: BOOLEAN): BOOLEAN;
  VAR n: HUGEINT; s: Str; ok: BOOLEAN;
BEGIN
  failed := FALSE;
  IF (format = "x") OR (format = "X") THEN
    ok := Int(input, 0, L.Length(input), n);
    IF ok & (format = "X") THEN
      IF ABS(n) > 1000000000000 THEN ok := FALSE ELSE n := n * Second END
    END;
    ok := ok & Valid(n);
    IF ok THEN t := n END
  ELSIF Localized(format) THEN ok := FALSE
  ELSE ok := ParseFields(input, format, t)
  END;
  IF ok THEN
    IF Format(t, format, s) THEN ok := Same(s^, input)
    ELSE ok := FALSE; failed := TRUE
    END
  END;
  RETURN ok
END Parse;

(* JavaScript's Date(str) *)

VAR
  ds: Str; dp: LONGINT;     (* the text DateParse reads, and where *)

(* The number at ds[dp], its digits in nd; ds[dp] is a digit *)
PROCEDURE Num(VAR nd: LONGINT): HUGEINT;
  VAR n: HUGEINT;
BEGIN
  n := 0; nd := 0;
  WHILE IsDigit(ds[dp]) DO
    IF n < 10000000000 THEN n := n * 10 + ORD(ds[dp]) - ORD("0") END;
    INC(dp); INC(nd)
  END;
  RETURN n
END Num;

(* The number of exactly k digits at ds[dp], or -1 *)
PROCEDURE Digits(k: LONGINT): LONGINT;
  VAR n, i: LONGINT;
BEGIN
  n := 0;
  FOR i := 0 TO k - 1 DO
    IF ~IsDigit(ds[dp + i]) THEN RETURN -1 END;
    n := n * 10 + ORD(ds[dp + i]) - ORD("0")
  END;
  INC(dp, k);
  RETURN n
END Digits;

(* The ISO form, ES's Date Time String Format, as V8 reads it *)
PROCEDURE Iso(VAR t: HUGEINT): BOOLEAN;
  VAR y, m, d, h, mi, s, ms, sign, nd, off, k: LONGINT; zoned, timed: BOOLEAN;
BEGIN
  dp := 0; m := 1; d := 1; h := 0; mi := 0; s := 0; ms := 0; off := 0;
  zoned := FALSE; timed := FALSE;
  IF (ds[0] = "+") OR (ds[0] = "-") THEN
    IF ds[0] = "-" THEN sign := -1 ELSE sign := 1 END;
    dp := 1; y := Digits(6);
    IF y < 0 THEN RETURN FALSE END;
    y := y * sign
  ELSE
    y := Digits(4); IF y < 0 THEN RETURN FALSE END
  END;
  IF ds[dp] = "-" THEN
    INC(dp); m := Digits(2); IF m < 0 THEN RETURN FALSE END;
    IF ds[dp] = "-" THEN INC(dp); d := Digits(2); IF d < 0 THEN RETURN FALSE END END
  END;
  IF (ds[dp] = "T") OR (ds[dp] = "t") THEN
    timed := TRUE; INC(dp);
    h := Digits(2); IF (h < 0) OR (ds[dp] # ":") THEN RETURN FALSE END;
    INC(dp); mi := Digits(2); IF mi < 0 THEN RETURN FALSE END;
    IF ds[dp] = ":" THEN
      INC(dp); s := Digits(2); IF s < 0 THEN RETURN FALSE END;
      IF ds[dp] = "." THEN
        INC(dp); IF ~IsDigit(ds[dp]) THEN RETURN FALSE END;
        nd := 0; k := 100;
        WHILE IsDigit(ds[dp]) DO
          ms := ms + (ORD(ds[dp]) - ORD("0")) * k; k := k DIV 10; INC(dp)
        END
      END
    END;
    IF (ds[dp] = "Z") OR (ds[dp] = "z") THEN zoned := TRUE; INC(dp)
    ELSIF (ds[dp] = "+") OR (ds[dp] = "-") THEN
      IF ds[dp] = "-" THEN sign := -1 ELSE sign := 1 END;
      INC(dp); k := Digits(2); IF (k < 0) OR (ds[dp] # ":") THEN RETURN FALSE END;
      INC(dp); off := Digits(2); IF off < 0 THEN RETURN FALSE END;
      off := sign * (k * 60 + off); zoned := TRUE
    END
  END;
  IF ds[dp] # 0X THEN RETURN FALSE END;
  IF (m < 1) OR (m > 12) OR (d < 1) OR (d > Calendar.DaysInMonth(y, m))
    OR (h > 24) OR (mi > 59) OR (s > 59) OR (h = 24) & ((mi # 0) OR (s # 0) OR (ms # 0)) THEN
    RETURN FALSE
  END;
  IF timed & ~zoned THEN RETURN Local(y, m - 1, d, h, mi, s, ms, t) END;
  (* the year as given: Date.UTC's 0 .. 99 would make it 1900 .. 1999 *)
  IF ~UTC(y, m - 1, d, h, mi - off, s, ms, t) THEN RETURN FALSE END;
  IF (y >= 0) & (y <= 99) THEN
    IF ~UTC(y + 400, m - 1, d, h, mi - off, s, ms, t) THEN RETURN FALSE END;
    t := t - 12622780800000   (* 400 years *)
  END;
  RETURN Valid(t)
END Iso;

(* Whether the word ds[ws .. ws+wl-1] is w, in any case *)
PROCEDURE WordIs(ws, wl: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  IF wl # L.Length(w) THEN RETURN FALSE END;
  FOR k := 0 TO wl - 1 DO IF Lower(ds[ws + k]) # w[k] THEN RETURN FALSE END END;
  RETURN TRUE
END WordIs;

(* The month the word names, by its first three letters or more, from 1;
   or 0 *)
PROCEDURE MonthWord(ws, wl: LONGINT): LONGINT;
  VAR m, k: LONGINT;
BEGIN
  IF wl < 3 THEN RETURN 0 END;
  FOR m := 0 TO 11 DO
    k := 0;
    WHILE (k < wl) & (k < L.Length(months[m])) & (Lower(ds[ws + k]) = Lower(months[m][k])) DO INC(k) END;
    IF k = wl THEN RETURN m + 1 END
  END;
  RETURN 0
END MonthWord;

PROCEDURE WeekdayWord(ws, wl: LONGINT): BOOLEAN;
  VAR w, k: LONGINT;
BEGIN
  IF wl < 3 THEN RETURN FALSE END;
  FOR w := 0 TO 6 DO
    k := 0;
    WHILE (k < wl) & (k < L.Length(weekdays[w])) & (Lower(ds[ws + k]) = Lower(weekdays[w][k])) DO INC(k) END;
    IF k = wl THEN RETURN TRUE END
  END;
  RETURN FALSE
END WeekdayWord;

(* The older forms, the part of V8's legacy parser pomermaid has *)
PROCEDURE Legacy(VAR t: HUGEINT): BOOLEAN;
  VAR nums: ARRAY 3 OF HUGEINT; digits: ARRAY 3 OF LONGINT; nn, nd, ws, wl, k: LONGINT;
    month, h, mi, s, ms, off, sign: LONGINT; y, m, d: HUGEINT;
    timed, zoned, pm, am: BOOLEAN; n: HUGEINT;
BEGIN
  dp := 0; nn := 0; month := 0; h := 0; mi := 0; s := 0; ms := 0; off := 0;
  timed := FALSE; zoned := FALSE; pm := FALSE; am := FALSE;
  LOOP
    IF ds[dp] = 0X THEN EXIT
    ELSIF IsDigit(ds[dp]) THEN
      n := Num(nd);
      IF ds[dp] = ":" THEN
        IF timed OR (n > 24) THEN RETURN FALSE END;
        timed := TRUE; h := SHORT(n);
        INC(dp); IF ~IsDigit(ds[dp]) THEN RETURN FALSE END;
        mi := SHORT(Num(nd)); IF mi > 59 THEN RETURN FALSE END;
        IF ds[dp] = ":" THEN
          INC(dp); IF ~IsDigit(ds[dp]) THEN RETURN FALSE END;
          s := SHORT(Num(nd)); IF s > 59 THEN RETURN FALSE END;
          IF (ds[dp] = ".") & IsDigit(ds[dp + 1]) THEN
            INC(dp); k := 100;
            WHILE IsDigit(ds[dp]) DO ms := ms + (ORD(ds[dp]) - ORD("0")) * k; k := k DIV 10; INC(dp) END
          END
        END
      ELSE
        IF nn = 3 THEN RETURN FALSE END;
        nums[nn] := n; digits[nn] := nd; INC(nn)
      END
    ELSIF ((ds[dp] = "+") OR (ds[dp] = "-")) & timed & IsDigit(ds[dp + 1]) THEN
      IF ds[dp] = "-" THEN sign := -1 ELSE sign := 1 END;
      INC(dp); n := Num(nd);
      IF ds[dp] = ":" THEN
        INC(dp); IF ~IsDigit(ds[dp]) THEN RETURN FALSE END;
        k := SHORT(Num(nd)); off := SHORT(n) * 60 + k
      ELSIF nd <= 2 THEN off := SHORT(n) * 60
      ELSE off := SHORT(n DIV 100) * 60 + SHORT(n MOD 100)
      END;
      off := sign * off; zoned := TRUE
    ELSIF Lower(ds[dp]) # Lower(ds[dp]) THEN RETURN FALSE
    ELSIF (Lower(ds[dp]) >= "a") & (Lower(ds[dp]) <= "z") THEN
      ws := dp; WHILE (Lower(ds[dp]) >= "a") & (Lower(ds[dp]) <= "z") DO INC(dp) END;
      wl := dp - ws;
      IF WordIs(ws, wl, "am") THEN am := TRUE
      ELSIF WordIs(ws, wl, "pm") THEN pm := TRUE
      ELSIF WordIs(ws, wl, "z") OR WordIs(ws, wl, "utc") OR WordIs(ws, wl, "gmt")
        OR WordIs(ws, wl, "ut") THEN zoned := TRUE
      ELSIF WordIs(ws, wl, "t") THEN
      ELSIF WeekdayWord(ws, wl) THEN
      ELSIF (month = 0) & (MonthWord(ws, wl) > 0) THEN month := MonthWord(ws, wl)
      ELSE RETURN FALSE
      END
    ELSIF ds[dp] = "(" THEN
      WHILE (ds[dp] # 0X) & (ds[dp] # ")") DO INC(dp) END;
      IF ds[dp] = ")" THEN INC(dp) END
    ELSIF (ds[dp] = " ") OR (ds[dp] = ",") OR (ds[dp] = "/") OR (ds[dp] = "-")
      OR (ds[dp] = ".") OR (ds[dp] = 09X) THEN INC(dp)
    ELSE RETURN FALSE
    END
  END;
  IF month # 0 THEN
    IF nn = 2 THEN
      IF (nums[0] > 31) OR (digits[0] >= 3) THEN y := nums[0]; d := nums[1]; nd := digits[0]
      ELSE d := nums[0]; y := nums[1]; nd := digits[1]
      END
    ELSIF (nn = 1) & ((nums[0] > 31) OR (digits[0] >= 3)) THEN y := nums[0]; d := 1; nd := digits[0]
    ELSE RETURN FALSE
    END;
    m := month
  ELSIF nn = 3 THEN
    IF (nums[0] > 31) OR (digits[0] >= 3) THEN
      y := nums[0]; m := nums[1]; d := nums[2]; nd := digits[0]
    ELSE m := nums[0]; d := nums[1]; y := nums[2]; nd := digits[2]
    END
  ELSE RETURN FALSE
  END;
  IF nd <= 2 THEN
    IF y < 50 THEN INC(y, 2000) ELSE INC(y, 1900) END
  END;
  IF (m < 1) OR (m > 12) OR (d < 1) OR (d > 31) OR (y > 9999) THEN RETURN FALSE END;
  IF am OR pm THEN
    IF (h < 1) OR (h > 12) THEN RETURN FALSE END;
    IF am & (h = 12) THEN h := 0 ELSIF pm & (h < 12) THEN INC(h, 12) END
  END;
  IF zoned THEN RETURN UTC(SHORT(y), SHORT(m) - 1, SHORT(d), h, mi - off, s, ms, t) END;
  RETURN Local(SHORT(y), SHORT(m) - 1, SHORT(d), h, mi, s, ms, t)
END Legacy;

(* JavaScript's new Date(str), as V8 reads it, in part: see the module's
   comment. FALSE if it is not a date pomermaid reads. *)
PROCEDURE DateParse*(str: ARRAY OF CHAR; VAR t: HUGEINT): BOOLEAN;
BEGIN
  ds := L.New(str);
  RETURN Iso(t) OR Legacy(t)
END DateParse;

PROCEDURE Names;
BEGIN
  months[0] := "January"; months[1] := "February"; months[2] := "March";
  months[3] := "April"; months[4] := "May"; months[5] := "June";
  months[6] := "July"; months[7] := "August"; months[8] := "September";
  months[9] := "October"; months[10] := "November"; months[11] := "December";
  weekdays[0] := "Sunday"; weekdays[1] := "Monday"; weekdays[2] := "Tuesday";
  weekdays[3] := "Wednesday"; weekdays[4] := "Thursday"; weekdays[5] := "Friday";
  weekdays[6] := "Saturday"
END Names;

(* The English names, for the axis's labels *)
PROCEDURE MonthName*(m: LONGINT; VAR s: ARRAY OF CHAR);
BEGIN
  COPY(months[m - 1], s)
END MonthName;

PROCEDURE WeekdayName*(w: LONGINT; VAR s: ARRAY OF CHAR);
BEGIN
  COPY(weekdays[w], s)
END WeekdayName;

BEGIN
  zone := TimeZones.Local(); nowSet := FALSE;
  NEW(buf, 256); bufLen := 0;
  Names
END PmGanttTime.
