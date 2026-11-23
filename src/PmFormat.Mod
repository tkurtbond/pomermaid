MODULE PmFormat;
(* PmFormat: numbers formatted as d3-format 3.1.0's format(specifier)
   formats them in its default locale (en-US: "," between thousands,
   "$" for currency, "." for the decimal point and U+2212 for minus),
   for the treemap's valueFormat.

   A specifier is [[fill]align][sign][symbol][0][width][,][.precision][~][type],
   as d3's.  The types e, f, g, r, p, s and % round on the exact
   decimal value of the binary number, half up, as JavaScript's
   toExponential, toFixed and toPrecision do; b, o, x and X are exact.
   Where JavaScript writes a number by its shortest decimal that
   reads back the same (the type c, d above 2^53, and f at 10^21 and
   above), PmFormat writes it to 15 significant digits.  A width
   above MaxWidth is not accepted. *)

CONST
  MaxDigits = 1100;     (* the digits of a binary number written exactly *)
  MaxWidth* = 1000;     (* the widest width accepted *)
  Two26 = 67108864.0D0;
  Two52 = 4503599627370496.0D0;
  Two53 = 9007199254740992.0D0;
  Shortest = 15;        (* the digits written for JavaScript's shortest *)

TYPE
  Text = ARRAY 4400 OF CHAR;

  Format* = POINTER TO FormatDesc;
  FormatDesc = RECORD
    fill: ARRAY 8 OF CHAR;     (* one character, in UTF-8 *)
    align, sign, symbol, type: CHAR;
    zero, comma, trim, maybeSuffix: BOOLEAN;
    width, precision: LONGINT;  (* width -1: none *)
    prefix, suffix: ARRAY 8 OF CHAR
  END;

  (* a positive number's exact decimal digits: 0.d[0] .. d[n-1] * 10^e,
     d[0] not "0" and d[n-1] not "0" *)
  Decimal = RECORD
    d: ARRAY MaxDigits OF CHAR;
    n, e: LONGINT
  END;

VAR
  big: ARRAY MaxDigits OF INTEGER;    (* a natural number's digits, least first *)
  len: LONGINT;
  prefixExp: LONGINT;                 (* the last s's SI exponent, as d3's *)
  dc: Decimal;

(* Strings *)

PROCEDURE Len(VAR s: ARRAY OF CHAR): LONGINT;
  VAR n: LONGINT;
BEGIN
  n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
  RETURN n
END Len;

PROCEDURE CatCh(VAR s: ARRAY OF CHAR; ch: CHAR);
  VAR n: LONGINT;
BEGIN
  n := Len(s);
  IF n + 1 < LEN(s) THEN s[n] := ch; s[n + 1] := 0X END
END CatCh;

PROCEDURE Cat(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
  VAR n, k: LONGINT;
BEGIN
  n := Len(s); k := 0;
  WHILE (k < LEN(t)) & (t[k] # 0X) & (n + 1 < LEN(s)) DO s[n] := t[k]; INC(n); INC(k) END;
  s[n] := 0X
END Cat;

(* s[from .. to - 1] onto the end of d *)
PROCEDURE CatSub(VAR d: ARRAY OF CHAR; VAR s: ARRAY OF CHAR; from, to: LONGINT);
  VAR n: LONGINT;
BEGIN
  n := Len(d);
  WHILE (from < to) & (n + 1 < LEN(d)) DO d[n] := s[from]; INC(n); INC(from) END;
  d[n] := 0X
END CatSub;

PROCEDURE Zeros(VAR s: ARRAY OF CHAR; k: LONGINT);
BEGIN
  WHILE k > 0 DO CatCh(s, "0"); DEC(k) END
END Zeros;

PROCEDURE CatInt(VAR s: ARRAY OF CHAR; n: LONGINT);
  VAR d: ARRAY 24 OF CHAR; k: INTEGER;
BEGIN
  k := 0;
  REPEAT d[k] := CHR(ORD("0") + SHORT(n MOD 10)); n := n DIV 10; INC(k) UNTIL n = 0;
  WHILE k > 0 DO DEC(k); CatCh(s, d[k]) END
END CatInt;

(* s's length in UTF-16 units, as JavaScript counts it *)
PROCEDURE Units(VAR s: ARRAY OF CHAR): LONGINT;
  VAR n, k: LONGINT;
BEGIN
  n := 0; k := 0;
  WHILE (k < LEN(s)) & (s[k] # 0X) DO
    IF (s[k] < 80X) OR (s[k] >= 0C0X) THEN INC(n) END;
    IF s[k] >= 0F0X THEN INC(n) END;
    INC(k)
  END;
  RETURN n
END Units;

(* Natural numbers, in big *)

PROCEDURE Mul(k: LONGINT);
  VAR i, c, t: LONGINT;
BEGIN
  c := 0;
  FOR i := 0 TO len - 1 DO
    t := big[i] * k + c; big[i] := SHORT(t MOD 10); c := t DIV 10
  END;
  WHILE c > 0 DO big[len] := SHORT(c MOD 10); c := c DIV 10; INC(len) END
END Mul;

PROCEDURE Add(k: LONGINT);
  VAR i, t: LONGINT;
BEGIN
  i := 0;
  WHILE k > 0 DO
    IF i = len THEN big[len] := 0; INC(len) END;
    t := big[i] + k; big[i] := SHORT(t MOD 10); k := t DIV 10; INC(i)
  END
END Add;

(* x, positive and finite, as m * 2^e, m an integer in [2^52, 2^53) *)
PROCEDURE Split(x: LONGREAL; VAR m: LONGREAL; VAR e: LONGINT);
BEGIN
  m := x; e := 0;
  WHILE m >= Two53 DO m := m / 2; INC(e) END;
  WHILE m < Two52 DO m := m * 2; DEC(e) END
END Split;

(* x's exact decimal digits, into dc; x positive and finite *)
PROCEDURE Exact(x: LONGREAL);
  VAR m: LONGREAL; e, hi, lo, k, scale: LONGINT;
BEGIN
  Split(x, m, e);
  hi := ENTIER(m / Two26); lo := ENTIER(m - hi * Two26);
  big[0] := 0; len := 1;
  Add(hi); Mul(ENTIER(Two26)); Add(lo);
  scale := 0;
  IF e >= 0 THEN
    WHILE e > 0 DO
      k := e; IF k > 20 THEN k := 20 END;
      Mul(ASH(1, k)); DEC(e, k)
    END
  ELSE
    scale := e; e := -e;
    WHILE e > 0 DO
      IF e >= 11 THEN Mul(48828125); DEC(e, 11) ELSE Mul(5); DEC(e) END
    END
  END;
  dc.n := len; dc.e := len + scale;
  FOR k := 0 TO len - 1 DO dc.d[k] := CHR(ORD("0") + big[len - 1 - k]) END;
  WHILE (dc.n > 1) & (dc.d[dc.n - 1] = "0") DO DEC(dc.n) END
END Exact;

(* dc to k >= 1 significant digits, rounded half up: r, k digits, the
   number 0.r * 10^e *)
PROCEDURE Sig(k: LONGINT; VAR r: ARRAY OF CHAR; VAR e: LONGINT);
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO k - 1 DO
    IF i < dc.n THEN r[i] := dc.d[i] ELSE r[i] := "0" END
  END;
  r[k] := 0X; e := dc.e;
  IF (k < dc.n) & (dc.d[k] >= "5") THEN
    i := k - 1;
    WHILE (i >= 0) & (r[i] = "9") DO r[i] := "0"; DEC(i) END;
    IF i >= 0 THEN r[i] := CHR(ORD(r[i]) + 1) ELSE r[0] := "1"; INC(e) END
  END
END Sig;

(* Whether x, finite and not negative, is an integer below 2^53 *)
PROCEDURE SmallInt(x: LONGREAL): BOOLEAN;
  VAR hi: LONGINT;
BEGIN
  IF x >= Two53 THEN RETURN FALSE END;
  hi := ENTIER(x / Two26);
  RETURN x - hi * Two26 = ENTIER(x - hi * Two26)
END SmallInt;

(* x, an integer in [0, 2^53), *)
PROCEDURE Huge(x: LONGREAL): HUGEINT;
  VAR hi: LONGINT; h: HUGEINT;
BEGIN
  hi := ENTIER(x / Two26); h := hi;
  RETURN h * 67108864 + ENTIER(x - hi * Two26)
END Huge;

(* The digits of h, base b, upper case if up, onto s *)
PROCEDURE CatHuge(VAR s: ARRAY OF CHAR; h: HUGEINT; b: INTEGER; up: BOOLEAN);
  VAR d: ARRAY 72 OF CHAR; k, v: INTEGER;
BEGIN
  k := 0;
  REPEAT
    v := SHORT(SHORT(h MOD b));
    IF v < 10 THEN d[k] := CHR(ORD("0") + v)
    ELSIF up THEN d[k] := CHR(ORD("A") + v - 10)
    ELSE d[k] := CHR(ORD("a") + v - 10)
    END;
    h := h DIV b; INC(k)
  UNTIL h = 0;
  WHILE k > 0 DO DEC(k); CatCh(s, d[k]) END
END CatHuge;

(* x's digits as JavaScript's shortest, to Shortest digits: r, k of
   them, the number 0.r * 10^e; x positive and finite *)
PROCEDURE Short(x: LONGREAL; VAR r: ARRAY OF CHAR; VAR k, e: LONGINT);
BEGIN
  IF SmallInt(x) THEN
    r[0] := 0X; CatHuge(r, Huge(x), 10, FALSE); k := Len(r); e := k
  ELSE Exact(x); Sig(Shortest, r, e); k := Shortest
  END;
  WHILE (k > 1) & (r[k - 1] = "0") DO DEC(k) END;
  r[k] := 0X
END Short;

(* JavaScript's x + "", to Shortest digits *)
PROCEDURE ToString(x: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 32 OF CHAR; k, n: LONGINT;
BEGIN
  s[0] := 0X;
  IF x # x THEN Cat(s, "NaN"); RETURN END;
  IF x < 0 THEN Cat(s, "-"); x := -x END;
  IF x = 0 THEN Cat(s, "0")
  ELSIF x - x # 0 THEN Cat(s, "Infinity")
  ELSE
    Short(x, r, k, n);
    IF (k <= n) & (n <= 21) THEN Cat(s, r); Zeros(s, n - k)
    ELSIF (0 < n) & (n <= 21) THEN CatSub(s, r, 0, n); CatCh(s, "."); CatSub(s, r, n, k)
    ELSIF (-6 < n) & (n <= 0) THEN Cat(s, "0."); Zeros(s, -n); Cat(s, r)
    ELSE
      CatCh(s, r[0]);
      IF k > 1 THEN CatCh(s, "."); CatSub(s, r, 1, k) END;
      CatCh(s, "e");
      IF n - 1 >= 0 THEN CatCh(s, "+"); CatInt(s, n - 1) ELSE CatCh(s, "-"); CatInt(s, 1 - n) END
    END
  END
END ToString;

(* JavaScript's x.toFixed(f), x not negative *)
PROCEDURE Fixed(x: LONGREAL; f: LONGINT; VAR s: ARRAY OF CHAR);
  VAR n: Text; r: ARRAY MaxDigits OF CHAR; k, e, l: LONGINT;
BEGIN
  s[0] := 0X; n[0] := 0X;
  IF (x - x # 0) OR (x >= 1.0D21) THEN ToString(x, s); RETURN END;
  IF x = 0 THEN Cat(n, "0")
  ELSE
    Exact(x); k := dc.e + f;
    IF k < 0 THEN Cat(n, "0")
    ELSIF k = 0 THEN
      IF dc.d[0] >= "5" THEN Cat(n, "1") ELSE Cat(n, "0") END
    ELSE
      Sig(k, r, e); Cat(n, r);
      IF e > dc.e THEN Cat(n, "0") END
    END
  END;
  l := Len(n);
  IF l < f + 1 THEN Zeros(s, f + 1 - l) END;
  Cat(s, n); l := Len(s);
  IF f > 0 THEN
    n[0] := 0X; CatSub(n, s, l - f, l); s[l - f] := "."; s[l - f + 1] := 0X; Cat(s, n)
  END
END Fixed;

(* x's first p significant digits, rounded: r, and the exponent of
   r[0], ee, as formatDecimalParts's; x positive or zero, finite *)
PROCEDURE Parts(x: LONGREAL; p: LONGINT; VAR r: ARRAY OF CHAR; VAR ee: LONGINT);
  VAR e, k: LONGINT;
BEGIN
  IF x = 0 THEN
    FOR k := 0 TO p - 1 DO r[k] := "0" END; r[p] := 0X; ee := 0
  ELSIF p = 0 THEN Short(x, r, k, e); ee := e - 1
  ELSE Exact(x); Sig(p, r, e); ee := e - 1
  END
END Parts;

PROCEDURE Exponent(VAR s: ARRAY OF CHAR; ee: LONGINT);
BEGIN
  CatCh(s, "e");
  IF ee >= 0 THEN CatCh(s, "+"); CatInt(s, ee) ELSE CatCh(s, "-"); CatInt(s, -ee) END
END Exponent;

(* JavaScript's x.toExponential(f), x not negative *)
PROCEDURE Exponential(x: LONGREAL; f: LONGINT; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 32 OF CHAR; ee: LONGINT;
BEGIN
  s[0] := 0X;
  IF x - x # 0 THEN ToString(x, s); RETURN END;
  Parts(x, f + 1, r, ee);
  CatCh(s, r[0]);
  IF f > 0 THEN CatCh(s, "."); CatSub(s, r, 1, f + 1) END;
  Exponent(s, ee)
END Exponential;

(* JavaScript's x.toPrecision(p), x not negative *)
PROCEDURE Precision(x: LONGREAL; p: LONGINT; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 32 OF CHAR; ee: LONGINT;
BEGIN
  s[0] := 0X;
  IF x - x # 0 THEN ToString(x, s); RETURN END;
  Parts(x, p, r, ee);
  IF (ee < -6) OR (ee >= p) THEN
    CatCh(s, r[0]);
    IF p > 1 THEN CatCh(s, "."); CatSub(s, r, 1, p) END;
    Exponent(s, ee)
  ELSIF ee = p - 1 THEN Cat(s, r)
  ELSIF ee >= 0 THEN CatSub(s, r, 0, ee + 1); CatCh(s, "."); CatSub(s, r, ee + 1, p)
  ELSE Cat(s, "0."); Zeros(s, -(ee + 1)); Cat(s, r)
  END
END Precision;

(* d3's formatRounded *)
PROCEDURE Rounded(x: LONGREAL; p: LONGINT; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 32 OF CHAR; ee: LONGINT;
BEGIN
  s[0] := 0X;
  IF x - x # 0 THEN ToString(x, s); RETURN END;
  Parts(x, p, r, ee);
  IF ee < 0 THEN Cat(s, "0."); Zeros(s, -ee - 1); Cat(s, r)
  ELSIF p > ee + 1 THEN CatSub(s, r, 0, ee + 1); CatCh(s, "."); CatSub(s, r, ee + 1, p)
  ELSE Cat(s, r); Zeros(s, ee - p + 1)
  END
END Rounded;

(* d3's formatPrefixAuto *)
PROCEDURE PrefixAuto(x: LONGREAL; p: LONGINT; VAR s: ARRAY OF CHAR);
  VAR r, r2: ARRAY 32 OF CHAR; ee, i, q, ee2: LONGINT;
BEGIN
  s[0] := 0X;
  IF x - x # 0 THEN ToString(x, s); RETURN END;
  Parts(x, p, r, ee);
  q := ee DIV 3;
  IF q < -8 THEN q := -8 ELSIF q > 8 THEN q := 8 END;
  prefixExp := q * 3;
  i := ee - prefixExp + 1;
  IF i = p THEN Cat(s, r)
  ELSIF i > p THEN Cat(s, r); Zeros(s, i - p)
  ELSIF i > 0 THEN CatSub(s, r, 0, i); CatCh(s, "."); CatSub(s, r, i, p)
  ELSE
    Cat(s, "0."); Zeros(s, -i);
    q := p + i - 1; IF q < 0 THEN q := 0 END;
    Parts(x, q, r2, ee2); Cat(s, r2)
  END
END PrefixAuto;

(* x rounded as JavaScript's Math.round; x not negative and finite *)
PROCEDURE Round(x: LONGREAL): LONGREAL;
  VAR hi: LONGINT; f: LONGREAL;
BEGIN
  IF x >= Two52 THEN RETURN x END;
  hi := ENTIER(x / Two26);
  f := hi * Two26 + ENTIER(x - hi * Two26);
  IF x - f >= 0.5D0 THEN f := f + 1 END;
  RETURN f
END Round;

(* JavaScript's Math.round(x).toString(2^b), x not negative *)
PROCEDURE Radix(x: LONGREAL; b: INTEGER; up: BOOLEAN; VAR s: ARRAY OF CHAR);
  VAR m: LONGREAL; e: LONGINT; h: HUGEINT; k: INTEGER;
BEGIN
  s[0] := 0X;
  IF x - x # 0 THEN
    IF up THEN Cat(s, "INFINITY") ELSE Cat(s, "Infinity") END; RETURN
  END;
  x := Round(x);
  IF x < Two53 THEN CatHuge(s, Huge(x), SHORT(ASH(1, b)), up)
  ELSE
    Split(x, m, e); h := Huge(m);
    FOR k := 1 TO SHORT(e MOD b) DO h := h * 2 END;
    CatHuge(s, h, SHORT(ASH(1, b)), up);
    Zeros(s, e DIV b)
  END
END Radix;

(* d3's formatDecimal, x not negative *)
PROCEDURE Dec(x: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 32 OF CHAR; k, e: LONGINT;
BEGIN
  s[0] := 0X;
  IF x - x # 0 THEN CatCh(s, 0E2X); CatCh(s, 088X); CatCh(s, 09EX); RETURN END;  (* ∞ *)
  x := Round(x);
  IF x = 0 THEN Cat(s, "0")
  ELSE Short(x, r, k, e); Cat(s, r); Zeros(s, e - k)
  END
END Dec;

(* d3's formatTrim *)
PROCEDURE Trim(VAR s: ARRAY OF CHAR);
  VAR n, i, i0, i1: LONGINT; t: Text;
BEGIN
  n := Len(s); i := 1; i0 := -1; i1 := 0;
  LOOP
    IF i >= n THEN EXIT END;
    IF s[i] = "." THEN i0 := i; i1 := i
    ELSIF s[i] = "0" THEN
      IF i0 = 0 THEN i0 := i END;
      i1 := i
    ELSIF (s[i] >= "1") & (s[i] <= "9") THEN
      IF i0 > 0 THEN i0 := 0 END
    ELSE EXIT
    END;
    INC(i)
  END;
  IF i0 > 0 THEN
    t[0] := 0X; CatSub(t, s, 0, i0); CatSub(t, s, i1 + 1, n); COPY(t, s)
  END
END Trim;

(* Whether JavaScript's +s is 0, s a formatted number *)
PROCEDURE IsZero(VAR s: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT; digit: BOOLEAN;
BEGIN
  i := 0; digit := FALSE;
  WHILE (s[i] = "0") OR (s[i] = ".") DO
    IF s[i] = "0" THEN digit := TRUE END;
    INC(i)
  END;
  IF digit & (s[i] = "e") THEN
    INC(i);
    IF (s[i] = "+") OR (s[i] = "-") THEN INC(i) END;
    WHILE (s[i] >= "0") & (s[i] <= "9") DO INC(i) END
  END;
  RETURN digit & (s[i] = 0X)
END IsZero;

(* d3's formatGroup([3], ","): s's digits grouped, to width *)
PROCEDURE Group(VAR s: ARRAY OF CHAR; width: LONGINT);
  VAR from, to: ARRAY 2200 OF INTEGER; i, g, length, n, k, a: LONGINT; t: Text;
BEGIN
  i := Len(s); n := 0; g := 3; length := 0;
  LOOP
    IF (i <= 0) OR (g <= 0) THEN EXIT END;
    IF length + g + 1 > width THEN g := width - length; IF g < 1 THEN g := 1 END END;
    a := i - g; IF a < 0 THEN a := 0 END;
    from[n] := SHORT(a); to[n] := SHORT(i); INC(n);
    i := i - g;
    length := length + g + 1;
    IF length > width THEN EXIT END;
    g := 3
  END;
  t[0] := 0X;
  FOR k := n - 1 TO 0 BY -1 DO
    CatSub(t, s, from[k], to[k]);
    IF k > 0 THEN CatCh(t, ",") END
  END;
  COPY(t, s)
END Group;

(* The specifier *)

PROCEDURE IsAlign(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = "<") OR (ch = ">") OR (ch = "=") OR (ch = "^")
END IsAlign;

PROCEDURE In(ch: CHAR; set: ARRAY OF CHAR): BOOLEAN;
  VAR k: INTEGER;
BEGIN
  k := 0;
  WHILE set[k] # 0X DO
    IF set[k] = ch THEN RETURN TRUE END;
    INC(k)
  END;
  RETURN FALSE
END In;

(* A number of decimal digits, at s[i], to at most limit *)
PROCEDURE Digits(VAR s: ARRAY OF CHAR; VAR i: LONGINT; limit: LONGINT): LONGINT;
  VAR n: LONGINT;
BEGIN
  n := 0;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO
    IF n <= limit THEN n := n * 10 + ORD(s[i]) - ORD("0") END;
    INC(i)
  END;
  RETURN n
END Digits;

(* f, the format the specifier spec gives; FALSE if spec is not one *)
PROCEDURE New*(spec: ARRAY OF CHAR; VAR f: Format): BOOLEAN;
  VAR i, k, n: LONGINT; t: CHAR;
BEGIN
  NEW(f);
  COPY(" ", f.fill); f.align := ">"; f.sign := "-"; f.symbol := 0X; f.type := 0X;
  f.zero := FALSE; f.comma := FALSE; f.trim := FALSE;
  f.width := -1; f.precision := -1;
  i := 0;
  (* [[fill]align]: the fill one character of one UTF-16 unit, not a
     line end *)
  IF spec[0] # 0X THEN
    n := 1;
    IF spec[0] >= 0F0X THEN n := 0
    ELSIF spec[0] >= 0E0X THEN n := 3
    ELSIF spec[0] >= 0C0X THEN n := 2
    ELSIF spec[0] >= 80X THEN n := 0
    END;
    FOR k := 1 TO n - 1 DO
      IF (spec[k] < 80X) OR (spec[k] >= 0C0X) THEN n := 0 END
    END;
    IF (n > 0) & (spec[0] # 0AX) & (spec[0] # 0DX) & IsAlign(spec[n]) THEN
      FOR k := 0 TO n - 1 DO f.fill[k] := spec[k] END;
      f.fill[n] := 0X; f.align := spec[n]; i := n + 1
    ELSIF IsAlign(spec[0]) THEN f.align := spec[0]; i := 1
    END
  END;
  IF In(spec[i], "+-( ") THEN f.sign := spec[i]; INC(i) END;
  IF (spec[i] = "$") OR (spec[i] = "#") THEN f.symbol := spec[i]; INC(i) END;
  IF spec[i] = "0" THEN f.zero := TRUE; INC(i) END;
  IF (spec[i] >= "0") & (spec[i] <= "9") THEN
    f.width := Digits(spec, i, MaxWidth);
    IF f.width > MaxWidth THEN RETURN FALSE END
  END;
  IF spec[i] = "," THEN f.comma := TRUE; INC(i) END;
  IF spec[i] = "." THEN
    INC(i);
    IF (spec[i] < "0") OR (spec[i] > "9") THEN RETURN FALSE END;
    f.precision := Digits(spec, i, 1000)
  END;
  IF spec[i] = "~" THEN f.trim := TRUE; INC(i) END;
  t := spec[i];
  IF ((CAP(t) >= "A") & (CAP(t) <= "Z")) OR (t = "%") THEN f.type := t; INC(i) END;
  IF spec[i] # 0X THEN RETURN FALSE END;

  (* n is ",g"; anything else unknown, the empty type among them, is
     ".12~g" *)
  t := f.type;
  IF t = "n" THEN f.comma := TRUE; f.type := "g"
  ELSIF ~In(t, "%bcdefgoprsXx") OR (t = 0X) THEN
    IF f.precision < 0 THEN f.precision := 12 END;
    f.trim := TRUE; f.type := "g"
  END;
  IF f.zero OR (f.fill = "0") & (f.align = "=") THEN
    f.zero := TRUE; COPY("0", f.fill); f.align := "="
  END;
  f.prefix := ""; f.suffix := "";
  IF f.symbol = "$" THEN f.prefix := "$"
  ELSIF (f.symbol = "#") & In(f.type, "boxX") THEN
    f.prefix[0] := "0"; f.prefix[1] := f.type; f.prefix[2] := 0X;
    IF f.type = "X" THEN f.prefix[1] := "x" END
  END;
  IF (f.symbol # "$") & In(f.type, "%p") THEN f.suffix := "%" END;
  f.maybeSuffix := In(f.type, "defgprs%");
  IF f.precision < 0 THEN f.precision := 6
  ELSIF In(f.type, "gprs") THEN
    IF f.precision < 1 THEN f.precision := 1 ELSIF f.precision > 21 THEN f.precision := 21 END
  ELSIF f.precision > 20 THEN f.precision := 20
  END;
  RETURN TRUE
END New;

PROCEDURE Type(f: Format; x: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR p: LONGINT;
BEGIN
  p := f.precision;
  CASE f.type OF
    "%": Fixed(x * 100, p, s)
  | "b": Radix(x, 1, FALSE, s)
  | "d": Dec(x, s)
  | "e": Exponential(x, p, s)
  | "f": Fixed(x, p, s)
  | "g": Precision(x, p, s)
  | "o": Radix(x, 3, FALSE, s)
  | "p": Rounded(x * 100, p, s)
  | "r": Rounded(x, p, s)
  | "s": PrefixAuto(x, p, s)
  | "X": Radix(x, 4, TRUE, s)
  | "x": Radix(x, 4, FALSE, s)
  END
END Type;

PROCEDURE SiPrefix(VAR s: ARRAY OF CHAR);
  VAR q: LONGINT;
BEGIN
  q := prefixExp DIV 3;
  CASE q OF
    -8: Cat(s, "y") | -7: Cat(s, "z") | -6: Cat(s, "a") | -5: Cat(s, "f")
  | -4: Cat(s, "p") | -3: Cat(s, "n") | -2: CatCh(s, 0C2X); CatCh(s, 0B5X)  (* µ *)
  | -1: Cat(s, "m") | 0: | 1: Cat(s, "k") | 2: Cat(s, "M") | 3: Cat(s, "G")
  | 4: Cat(s, "T") | 5: Cat(s, "P") | 6: Cat(s, "E") | 7: Cat(s, "Z") | 8: Cat(s, "Y")
  END
END SiPrefix;

(* x formatted by f, into s *)
PROCEDURE Apply*(f: Format; x: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR value, pre, suf, pad, t: Text; neg: BOOLEAN; i, n, length, w: LONGINT;
BEGIN
  COPY(f.prefix, pre); COPY(f.suffix, suf);
  IF f.type = "c" THEN
    ToString(x, t); Cat(t, suf); COPY(t, suf); value := ""
  ELSE
    neg := (x < 0) OR (x = 0) & (1 / x < 0);
    IF x # x THEN value := "NaN" ELSE Type(f, ABS(x), value) END;
    IF f.trim THEN Trim(value) END;
    IF neg & IsZero(value) & (f.sign # "+") THEN neg := FALSE END;
    t := "";
    IF neg THEN
      IF f.sign = "(" THEN Cat(t, "(") ELSE CatCh(t, 0E2X); CatCh(t, 088X); CatCh(t, 092X) END  (* − *)
    ELSIF (f.sign # "-") & (f.sign # "(") THEN CatCh(t, f.sign)
    END;
    Cat(t, pre); COPY(t, pre);
    t := "";
    IF f.type = "s" THEN SiPrefix(t) END;
    Cat(t, suf);
    IF neg & (f.sign = "(") THEN Cat(t, ")") END;
    COPY(t, suf);
    IF f.maybeSuffix THEN
      n := Len(value); i := 0;
      WHILE (i < n) & (value[i] >= "0") & (value[i] <= "9") DO INC(i) END;
      IF i < n THEN
        t := ""; CatSub(t, value, i, n); Cat(t, suf); COPY(t, suf); value[i] := 0X
      END
    END
  END;
  IF f.comma & ~f.zero THEN Group(value, MAX(LONGINT)) END;
  length := Units(pre) + Units(value) + Units(suf);
  pad := ""; n := 0;
  IF (f.width >= 0) & (length < f.width) THEN
    n := f.width - length;
    FOR i := 1 TO n DO Cat(pad, f.fill) END
  END;
  IF f.comma & f.zero THEN
    t := pad; Cat(t, value); COPY(t, value);
    IF n > 0 THEN w := f.width - Units(suf) ELSE w := MAX(LONGINT) END;
    Group(value, w); pad := ""; n := 0
  END;
  t := "";
  CASE f.align OF
    "<": Cat(t, pre); Cat(t, value); Cat(t, suf); Cat(t, pad)
  | "=": Cat(t, pre); Cat(t, pad); Cat(t, value); Cat(t, suf)
  | "^":
      FOR i := 1 TO n DIV 2 DO Cat(t, f.fill) END;
      Cat(t, pre); Cat(t, value); Cat(t, suf);
      FOR i := n DIV 2 + 1 TO n DO Cat(t, f.fill) END
  | ">": Cat(t, pad); Cat(t, pre); Cat(t, value); Cat(t, suf)
  END;
  COPY(t, s)
END Apply;

BEGIN
  prefixExp := 0
END PmFormat.
