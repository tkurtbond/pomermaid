MODULE PmMetrics;
(* PmMetrics: the widths of text in groff's fonts, and the sizes of
   nodes that hold it.

   A font is read from groff's font description files, groff_font(5):
   DESC gives the device's resolution, unitwidth and sizescale; the
   font file gives each glyph's width, the kerning pairs and the
   ligatures. Text is measured as troff sets it: each character's
   glyph, kerned with the one before it, with the ligatures ff, fi,
   fl, ffi and ffl formed where the font has them, each width rounded
   to the device's units as troff rounds it.

   Characters are found by their Unicode code points. A glyph's code
   point is the one groff 1.25's font files give after "--"; for older
   files it comes from its name: a name of one character is that
   character, "uXXXX" is U+XXXX, and the other names are groff's
   special characters (groff_char(7)), the ones below.

   The fonts are looked for in the directories the font path names, in
   order, in the subdirectory dev<device>, devpdf, then devps. The
   path is set by SetPath, or else is groff's own: GROFF_FONT_PATH, then
   the site-font and current/font directories of the groff found in
   PATH and of the usual places groff is installed, then /usr/lib/font. *)

IMPORT Platform, PmIO, L := PmLex, F := PmFlow;

CONST
  MaxDirs = 32;
  Unknown* = -1;
  (* Mermaid's padding inside a node, 15 pixels when its text is 16, as
     a fraction of the size *)
  PadNum = 15; PadDen = 16;

TYPE
  Glyph = RECORD
    code: LONGINT;   (* Unknown for an empty slot *)
    width: LONGINT   (* at unitwidth *)
  END;
  Glyphs = POINTER TO ARRAY OF Glyph;

  Kern = RECORD
    a, b: LONGINT;   (* code points; a = Unknown for an empty slot *)
    amount: LONGINT
  END;
  Kerns = POINTER TO ARRAY OF Kern;

  (* A name in the font, and its code point *)
  NameCode = POINTER TO NameCodeDesc;
  NameCodeDesc = RECORD
    name: L.Str;
    code: LONGINT;
    next: NameCode
  END;

  (* A kerning pair as written, by names, until the charset is read *)
  RawKern = POINTER TO RawKernDesc;
  RawKernDesc = RECORD
    a, b: L.Str;
    amount: LONGINT;
    next: RawKern
  END;

  Font* = POINTER TO FontDesc;
  FontDesc* = RECORD
    name*: ARRAY 64 OF CHAR;
    file*: ARRAY 512 OF CHAR;  (* where it was read from *)
    res, unitwidth, sizescale: LONGINT;
    spacewidth: LONGINT;
    glyphs: Glyphs; nGlyphs: LONGINT;
    kerns: Kerns; nKerns: LONGINT;
    ligatures: SET;            (* of Ff, Fi, Fl, Ffi, Ffl *)
    names: NameCode            (* while reading *)
  END;

  (* A reader of the lines of a file, split into words *)
  Words = RECORD
    t: PmIO.Text; len, pos: LONGINT;
    w: ARRAY 8 OF RECORD start, end: LONGINT END;
    n: INTEGER
  END;

CONST
  Ff = 0; Fi = 1; Fl = 2; Ffi = 3; Ffl = 4;

VAR
  dirs: ARRAY MaxDirs OF ARRAY 512 OF CHAR;
  nDirs: INTEGER;
  pathSet: BOOLEAN;
  specials: NameCode;      (* groff's special characters *)

(* Text *)

PROCEDURE Append(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
  VAR i, k: LONGINT;
BEGIN
  k := L.Length(s); i := 0;
  WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END;
  s[k] := 0X
END Append;

(* The value of the hexadecimal digits s[start .. end-1], or Unknown *)
PROCEDURE Hex(VAR s: ARRAY OF CHAR; start, end: LONGINT): LONGINT;
  VAR c: LONGINT; ch: CHAR;
BEGIN
  IF (end - start < 4) OR (end - start > 6) THEN RETURN Unknown END;
  c := 0;
  WHILE start < end DO
    ch := s[start];
    IF (ch >= "0") & (ch <= "9") THEN c := c * 16 + ORD(ch) - ORD("0")
    ELSIF (ch >= "A") & (ch <= "F") THEN c := c * 16 + ORD(ch) - ORD("A") + 10
    ELSE RETURN Unknown
    END;
    INC(start)
  END;
  RETURN c
END Hex;

(* The code point of the UTF-8 sequence at s[i], and i moved past it *)
PROCEDURE Decode*(VAR s: ARRAY OF CHAR; VAR i: LONGINT; end: LONGINT): LONGINT;
  VAR c: LONGINT; n: INTEGER; ch: CHAR;
BEGIN
  ch := s[i]; INC(i);
  IF ch < 80X THEN RETURN ORD(ch)
  ELSIF ch >= 0F0X THEN c := ORD(ch) MOD 8; n := 3
  ELSIF ch >= 0E0X THEN c := ORD(ch) MOD 16; n := 2
  ELSIF ch >= 0C0X THEN c := ORD(ch) MOD 32; n := 1
  ELSE RETURN 0FFFDH
  END;
  WHILE (n > 0) & (i < end) & (s[i] >= 80X) & (s[i] < 0C0X) DO
    c := c * 64 + ORD(s[i]) MOD 64; INC(i); DEC(n)
  END;
  IF n > 0 THEN RETURN 0FFFDH END;
  RETURN c
END Decode;

(* groff's special characters *)

PROCEDURE Special(name: ARRAY OF CHAR; code: LONGINT);
  VAR n: NameCode;
BEGIN
  NEW(n); n.name := L.New(name); n.code := code; n.next := specials; specials := n
END Special;

(* groff names the accented letters of Latin-1 by an accent and the
   letter: 'e is é *)
PROCEDURE InitSpecials;
BEGIN
  specials := NIL;
  (* Latin-1 *)
  Special("r!", 0A1H); Special("ct", 0A2H); Special("Po", 0A3H); Special("Cs", 0A4H);
  Special("Ye", 0A5H); Special("bb", 0A6H); Special("sc", 0A7H); Special("ad", 0A8H);
  Special("co", 0A9H); Special("Of", 0AAH); Special("Fo", 0ABH); Special("no", 0ACH);
  Special("rg", 0AEH); Special("a-", 0AFH); Special("de", 0B0H); Special("+-", 0B1H);
  Special("S2", 0B2H); Special("S3", 0B3H); Special("aa", 0B4H); Special("mc", 0B5H);
  Special("ps", 0B6H); Special("pc", 0B7H); Special("ac", 0B8H); Special("S1", 0B9H);
  Special("Om", 0BAH); Special("Fc", 0BBH); Special("14", 0BCH); Special("12", 0BDH);
  Special("34", 0BEH); Special("r?", 0BFH);
  Special("`A", 0C0H); Special("`E", 0C8H); Special("`I", 0CCH);
  Special("`O", 0D2H); Special("`U", 0D9H); Special("`a", 0E0H);
  Special("`e", 0E8H); Special("`i", 0ECH); Special("`o", 0F2H);
  Special("`u", 0F9H);
  Special("'A", 0C1H); Special("'E", 0C9H); Special("'I", 0CDH);
  Special("'O", 0D3H); Special("'U", 0DAH); Special("'Y", 0DDH);
  Special("'a", 0E1H); Special("'e", 0E9H); Special("'i", 0EDH);
  Special("'o", 0F3H); Special("'u", 0FAH); Special("'y", 0FDH);
  Special("^A", 0C2H); Special("^E", 0CAH); Special("^I", 0CEH);
  Special("^O", 0D4H); Special("^U", 0DBH); Special("^a", 0E2H);
  Special("^e", 0EAH); Special("^i", 0EEH); Special("^o", 0F4H);
  Special("^u", 0FBH);
  Special("~A", 0C3H); Special("~N", 0D1H); Special("~O", 0D5H);
  Special("~a", 0E3H); Special("~n", 0F1H); Special("~o", 0F5H);
  Special(":A", 0C4H); Special(":E", 0CBH); Special(":I", 0CFH);
  Special(":O", 0D6H); Special(":U", 0DCH); Special(":a", 0E4H);
  Special(":e", 0EBH); Special(":i", 0EFH); Special(":o", 0F6H);
  Special(":u", 0FCH); Special(":y", 0FFH); Special(":Y", 178H);
  Special(",C", 0C7H); Special(",c", 0E7H);
  Special("oA", 0C5H); Special("oa", 0E5H);
  Special("/O", 0D8H); Special("/o", 0F8H); Special("/L", 141H);
  Special("/l", 142H);
  Special("vS", 160H); Special("vs", 161H); Special("vZ", 17DH);
  Special("vz", 17EH);
  Special("AE", 0C6H); Special("ae", 0E6H); Special("-D", 0D0H); Special("Sd", 0F0H);
  Special("mu", 0D7H); Special("di", 0F7H); Special("TP", 0DEH); Special("Tp", 0FEH);
  Special("ss", 0DFH);
  (* Latin Extended-A, and a few more *)
  Special(".i", 131H); Special("OE", 152H); Special("oe", 153H); Special("Fn", 192H);
  Special("a^", 2C6H); Special("a~", 2DCH); Special("ab", 2D8H); Special("a.", 2D9H);
  Special("ao", 2DAH); Special("ho", 2DBH); Special('a"', 2DDH); Special("ah", 2C7H);
  (* punctuation *)
  Special("hy", 2010H); Special("en", 2013H); Special("em", 2014H);
  Special("oq", 2018H); Special("cq", 2019H); Special("bq", 201AH);
  Special("lq", 201CH); Special("rq", 201DH); Special("Bq", 201EH);
  Special("dg", 2020H); Special("dd", 2021H); Special("bu", 2022H);
  Special("%0", 2030H); Special("fm", 2032H); Special("sd", 2033H);
  Special("fo", 2039H); Special("fc", 203AH); Special("Eu", 20ACH); Special("eu", 20ACH);
  Special("tm", 2122H); Special("mi", 2212H); Special("\-", 2212H);
  (* ligatures *)
  Special("ff", 0FB00H); Special("fi", 0FB01H); Special("fl", 0FB02H);
  Special("Fi", 0FB03H); Special("Fl", 0FB04H)
END InitSpecials;

PROCEDURE SpecialCode(VAR name: ARRAY OF CHAR): LONGINT;
  VAR n: NameCode;
BEGIN
  n := specials;
  WHILE n # NIL DO
    IF n.name^ = name THEN RETURN n.code END;
    n := n.next
  END;
  RETURN Unknown
END SpecialCode;

(* The code point groff gives the glyph name, or Unknown *)
PROCEDURE NameToCode(VAR name: ARRAY OF CHAR): LONGINT;
  VAR n, i: LONGINT; c: LONGINT;
BEGIN
  n := L.Length(name);
  IF n = 1 THEN RETURN ORD(name[0]) END;
  IF (n >= 5) & (name[0] = "u") THEN
    c := Hex(name, 1, n);
    IF c # Unknown THEN RETURN c END
  END;
  i := 0;
  RETURN SpecialCode(name)
END NameToCode;

(* The tables *)

PROCEDURE NewGlyphs(n: LONGINT): Glyphs;
  VAR t: Glyphs; i: LONGINT;
BEGIN
  NEW(t, n);
  FOR i := 0 TO n - 1 DO t[i].code := Unknown END;
  RETURN t
END NewGlyphs;

PROCEDURE PutGlyph(f: Font; code, width: LONGINT);
  VAR i, k: LONGINT; old: Glyphs;
BEGIN
  IF 2 * (f.nGlyphs + 1) > LEN(f.glyphs^) THEN
    old := f.glyphs; f.glyphs := NewGlyphs(2 * LEN(old^)); f.nGlyphs := 0;
    FOR k := 0 TO LEN(old^) - 1 DO
      IF old[k].code # Unknown THEN PutGlyph(f, old[k].code, old[k].width) END
    END
  END;
  i := code MOD LEN(f.glyphs^);
  WHILE (f.glyphs[i].code # Unknown) & (f.glyphs[i].code # code) DO
    i := (i + 1) MOD LEN(f.glyphs^)
  END;
  IF f.glyphs[i].code = Unknown THEN
    f.glyphs[i].code := code; f.glyphs[i].width := width; INC(f.nGlyphs)
  END
  (* a glyph already there keeps its width: troff takes the first *)
END PutGlyph;

(* The width of code at unitwidth, or Unknown *)
PROCEDURE GlyphWidth(f: Font; code: LONGINT): LONGINT;
  VAR i: LONGINT;
BEGIN
  i := code MOD LEN(f.glyphs^);
  WHILE f.glyphs[i].code # Unknown DO
    IF f.glyphs[i].code = code THEN RETURN f.glyphs[i].width END;
    i := (i + 1) MOD LEN(f.glyphs^)
  END;
  RETURN Unknown
END GlyphWidth;

PROCEDURE NewKerns(n: LONGINT): Kerns;
  VAR t: Kerns; i: LONGINT;
BEGIN
  NEW(t, n);
  FOR i := 0 TO n - 1 DO t[i].a := Unknown END;
  RETURN t
END NewKerns;

PROCEDURE KernHash(a, b, n: LONGINT): LONGINT;
BEGIN
  RETURN (a MOD 4093 * 31 + b MOD 4093) MOD n
END KernHash;

PROCEDURE PutKern(f: Font; a, b, amount: LONGINT);
  VAR i, k: LONGINT; old: Kerns;
BEGIN
  IF 2 * (f.nKerns + 1) > LEN(f.kerns^) THEN
    old := f.kerns; f.kerns := NewKerns(2 * LEN(old^)); f.nKerns := 0;
    FOR k := 0 TO LEN(old^) - 1 DO
      IF old[k].a # Unknown THEN PutKern(f, old[k].a, old[k].b, old[k].amount) END
    END
  END;
  i := KernHash(a, b, LEN(f.kerns^));
  WHILE (f.kerns[i].a # Unknown) & ((f.kerns[i].a # a) OR (f.kerns[i].b # b)) DO
    i := (i + 1) MOD LEN(f.kerns^)
  END;
  IF f.kerns[i].a = Unknown THEN INC(f.nKerns) END;
  f.kerns[i].a := a; f.kerns[i].b := b; f.kerns[i].amount := amount
END PutKern;

PROCEDURE KernAmount(f: Font; a, b: LONGINT): LONGINT;
  VAR i: LONGINT;
BEGIN
  i := KernHash(a, b, LEN(f.kerns^));
  WHILE f.kerns[i].a # Unknown DO
    IF (f.kerns[i].a = a) & (f.kerns[i].b = b) THEN RETURN f.kerns[i].amount END;
    i := (i + 1) MOD LEN(f.kerns^)
  END;
  RETURN 0
END KernAmount;

(* The font path *)

PROCEDURE AddDir(d: ARRAY OF CHAR);
BEGIN
  IF (d # "") & (nDirs < MaxDirs) THEN COPY(d, dirs[nDirs]); INC(nDirs) END
END AddDir;

(* Adds the directories of the list s, separated by ":" *)
PROCEDURE AddList(VAR s: ARRAY OF CHAR);
  VAR i, k: LONGINT; d: ARRAY 512 OF CHAR;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    k := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (s[i] # ":") DO
      IF k < LEN(d) - 1 THEN d[k] := s[i]; INC(k) END;
      INC(i)
    END;
    d[k] := 0X; AddDir(d);
    IF (i < LEN(s)) & (s[i] = ":") THEN INC(i) END
  END
END AddList;

(* Adds prefix/share/groff/site-font and prefix/share/groff/current/font *)
PROCEDURE AddPrefix(prefix: ARRAY OF CHAR);
  VAR d: ARRAY 512 OF CHAR;
BEGIN
  COPY(prefix, d); Append(d, "/share/groff/site-font"); AddDir(d);
  COPY(prefix, d); Append(d, "/share/groff/current/font"); AddDir(d)
END AddPrefix;

(* The prefix of the groff found in PATH, "" if there is none *)
PROCEDURE GroffPrefix(VAR prefix: ARRAY OF CHAR);
  VAR path: ARRAY 4096 OF CHAR; d, f: ARRAY 512 OF CHAR; i, k: LONGINT;
BEGIN
  prefix[0] := 0X;
  IF ~Platform.getEnv("PATH", path) THEN RETURN END;
  i := 0;
  WHILE path[i] # 0X DO
    k := 0;
    WHILE (path[i] # 0X) & (path[i] # ":") DO
      IF k < LEN(d) - 1 THEN d[k] := path[i]; INC(k) END;
      INC(i)
    END;
    d[k] := 0X;
    IF path[i] = ":" THEN INC(i) END;
    COPY(d, f); Append(f, "/groff");
    IF (d # "") & PmIO.Exists(f) THEN
      (* d is prefix/bin *)
      k := L.Length(d);
      IF (k >= 4) & (d[k - 4] = "/") & (d[k - 3] = "b") & (d[k - 2] = "i") & (d[k - 1] = "n") THEN
        d[k - 4] := 0X; COPY(d, prefix); RETURN
      END
    END
  END
END GroffPrefix;

PROCEDURE DefaultPath;
  VAR s: ARRAY 4096 OF CHAR; prefix: ARRAY 512 OF CHAR;
BEGIN
  nDirs := 0;
  IF Platform.getEnv("GROFF_FONT_PATH", s) THEN AddList(s) END;
  GroffPrefix(prefix);
  IF prefix # "" THEN AddPrefix(prefix) END;
  AddPrefix("/usr/local"); AddPrefix("/usr/pkg"); AddPrefix("/usr");
  AddDir("/usr/lib/font")
END DefaultPath;

(* Sets the font path to the directories of s, separated by ":" *)
PROCEDURE SetPath*(s: ARRAY OF CHAR);
BEGIN
  nDirs := 0; AddList(s); pathSet := TRUE
END SetPath;

(* Reading *)

(* Reads the next line that has words; FALSE at the end *)
PROCEDURE NextLine(VAR r: Words): BOOLEAN;
  VAR ch: CHAR;
BEGIN
  LOOP
    IF r.pos >= r.len THEN RETURN FALSE END;
    r.n := 0;
    WHILE (r.pos < r.len) & (r.t[r.pos] # 0AX) DO
      ch := r.t[r.pos];
      IF ch = "#" THEN
        WHILE (r.pos < r.len) & (r.t[r.pos] # 0AX) DO INC(r.pos) END
      ELSIF (ch = " ") OR (ch = 09X) OR (ch = 0DX) THEN INC(r.pos)
      ELSE
        IF r.n < LEN(r.w) THEN r.w[r.n].start := r.pos END;
        WHILE (r.pos < r.len) & (r.t[r.pos] > " ") DO INC(r.pos) END;
        IF r.n < LEN(r.w) THEN r.w[r.n].end := r.pos; INC(r.n) END
      END
    END;
    IF r.pos < r.len THEN INC(r.pos) END;
    IF r.n > 0 THEN RETURN TRUE END
  END
END NextLine;

PROCEDURE WordIs(VAR r: Words; k: INTEGER; w: ARRAY OF CHAR): BOOLEAN;
  VAR i, n: LONGINT;
BEGIN
  IF k >= r.n THEN RETURN FALSE END;
  n := r.w[k].end - r.w[k].start;
  IF n # L.Length(w) THEN RETURN FALSE END;
  FOR i := 0 TO n - 1 DO
    IF r.t[r.w[k].start + i] # w[i] THEN RETURN FALSE END
  END;
  RETURN TRUE
END WordIs;

PROCEDURE WordStr(VAR r: Words; k: INTEGER): L.Str;
BEGIN
  RETURN L.Sub(r.t^, r.w[k].start, r.w[k].end - r.w[k].start)
END WordStr;

(* The integer that starts word k (up to a "," or its end), or def *)
PROCEDURE WordInt(VAR r: Words; k: INTEGER; def: LONGINT): LONGINT;
  VAR i, n: LONGINT; neg: BOOLEAN;
BEGIN
  IF k >= r.n THEN RETURN def END;
  i := r.w[k].start; neg := FALSE;
  IF r.t[i] = "-" THEN neg := TRUE; INC(i) END;
  IF (i >= r.w[k].end) OR (r.t[i] < "0") OR (r.t[i] > "9") THEN RETURN def END;
  n := 0;
  WHILE (i < r.w[k].end) & (r.t[i] >= "0") & (r.t[i] <= "9") DO
    n := n * 10 + ORD(r.t[i]) - ORD("0"); INC(i)
  END;
  IF neg THEN n := -n END;
  RETURN n
END WordInt;

(* Opens dir/dev<device>/name; FALSE if it is not there *)
PROCEDURE Find(name: ARRAY OF CHAR; VAR file: ARRAY OF CHAR; VAR r: Words): BOOLEAN;
  VAR i: INTEGER; dev: INTEGER; f: ARRAY 512 OF CHAR;
BEGIN
  IF ~pathSet & (nDirs = 0) THEN DefaultPath END;
  FOR dev := 0 TO 1 DO
    FOR i := 0 TO nDirs - 1 DO
      COPY(dirs[i], f);
      IF dev = 0 THEN Append(f, "/devpdf/") ELSE Append(f, "/devps/") END;
      Append(f, name);
      IF PmIO.Exists(f) THEN
        COPY(f, file);
        PmIO.ReadFile(f, r.t, r.len); r.pos := 0;
        RETURN TRUE
      END
    END
  END;
  RETURN FALSE
END Find;

PROCEDURE ReadDesc(f: Font; dir: ARRAY OF CHAR);
  VAR r: Words; d: ARRAY 512 OF CHAR;
BEGIN
  f.res := 72000; f.unitwidth := 1000; f.sizescale := 1;
  COPY(dir, d); Append(d, "DESC");
  IF ~PmIO.Exists(d) THEN RETURN END;
  PmIO.ReadFile(d, r.t, r.len); r.pos := 0;
  WHILE NextLine(r) DO
    IF WordIs(r, 0, "res") THEN f.res := WordInt(r, 1, f.res)
    ELSIF WordIs(r, 0, "unitwidth") THEN f.unitwidth := WordInt(r, 1, f.unitwidth)
    ELSIF WordIs(r, 0, "sizescale") THEN f.sizescale := WordInt(r, 1, f.sizescale)
    ELSIF WordIs(r, 0, "charset") THEN RETURN
    END
  END
END ReadDesc;

(* The code point of name in the font being read, or Unknown *)
PROCEDURE CodeOf(f: Font; VAR name: ARRAY OF CHAR): LONGINT;
  VAR n: NameCode;
BEGIN
  n := f.names;
  WHILE n # NIL DO
    IF n.name^ = name THEN RETURN n.code END;
    n := n.next
  END;
  RETURN NameToCode(name)
END CodeOf;

(* Loads the font name ("TR", "HB", ...): FALSE if no font file of that
   name is on the path *)
PROCEDURE Load*(name: ARRAY OF CHAR; VAR font: Font): BOOLEAN;
  VAR f: Font; r: Words; section: INTEGER; k, i: INTEGER; code, width, last, w: LONGINT;
    gname, s: L.Str; raw, rk: RawKern; n: NameCode; dir: ARRAY 512 OF CHAR;
BEGIN
  NEW(f); COPY(name, f.name);
  IF ~Find(name, f.file, r) THEN font := NIL; RETURN FALSE END;
  COPY(f.file, dir); i := SHORT(L.Length(dir));
  WHILE (i > 0) & (dir[i - 1] # "/") DO DEC(i) END;
  dir[i] := 0X;
  ReadDesc(f, dir);
  f.spacewidth := 0; f.glyphs := NewGlyphs(512); f.nGlyphs := 0;
  f.kerns := NewKerns(1024); f.nKerns := 0; f.ligatures := {}; f.names := NIL;
  section := 0; raw := NIL; last := Unknown;
  WHILE NextLine(r) DO
    IF WordIs(r, 0, "kernpairs") & (r.n = 1) THEN section := 1
    ELSIF WordIs(r, 0, "charset") & (r.n = 1) THEN section := 2
    ELSIF section = 0 THEN
      IF WordIs(r, 0, "spacewidth") THEN f.spacewidth := WordInt(r, 1, 0)
      ELSIF WordIs(r, 0, "ligatures") THEN
        FOR k := 1 TO r.n - 1 DO
          IF WordIs(r, k, "ff") THEN INCL(f.ligatures, Ff)
          ELSIF WordIs(r, k, "fi") THEN INCL(f.ligatures, Fi)
          ELSIF WordIs(r, k, "fl") THEN INCL(f.ligatures, Fl)
          ELSIF WordIs(r, k, "ffi") THEN INCL(f.ligatures, Ffi)
          ELSIF WordIs(r, k, "ffl") THEN INCL(f.ligatures, Ffl)
          END
        END
      END
    ELSIF (section = 1) & (r.n >= 3) THEN
      NEW(rk); rk.a := WordStr(r, 0); rk.b := WordStr(r, 1); rk.amount := WordInt(r, 2, 0);
      rk.next := raw; raw := rk
    ELSIF (section = 2) & (r.n >= 2) THEN
      gname := WordStr(r, 0);
      IF WordIs(r, 1, 22X) THEN
        (* another name for the glyph before *)
        w := width
      ELSE
        w := WordInt(r, 1, 0); width := w
      END;
      code := Unknown;
      (* groff 1.25: "-- XXXX" at the end *)
      k := 2;
      WHILE (k < r.n - 1) & ~WordIs(r, k, "--") DO INC(k) END;
      IF (k < r.n - 1) & ~WordIs(r, 1, 22X) THEN
        code := Hex(r.t^, r.w[k + 1].start, r.w[k + 1].end)
      END;
      IF (code = Unknown) & WordIs(r, 1, 22X) THEN
        s := gname; code := NameToCode(s^);
        IF code = Unknown THEN code := last END
      END;
      IF code = Unknown THEN code := NameToCode(gname^) END;
      IF ~WordIs(r, 0, "---") THEN
        IF ~WordIs(r, 1, 22X) THEN last := code END;
        IF code # Unknown THEN
          PutGlyph(f, code, w);
          NEW(n); n.name := gname; n.code := code; n.next := f.names; f.names := n
        END
      END
    END
  END;
  rk := raw;
  WHILE rk # NIL DO
    code := CodeOf(f, rk.a^); w := CodeOf(f, rk.b^);
    IF (code # Unknown) & (w # Unknown) THEN PutKern(f, code, w, rk.amount) END;
    rk := rk.next
  END;
  f.names := NIL;
  font := f;
  RETURN TRUE
END Load;

(* Measuring *)

(* x * size / unitwidth, rounded as groff's scale() rounds *)
PROCEDURE Scale(f: Font; x, size: LONGINT): LONGINT;
  VAR r: LONGINT;
BEGIN
  IF x >= 0 THEN r := (x * size + f.unitwidth DIV 2) DIV f.unitwidth
  ELSE r := -((-x * size + f.unitwidth DIV 2) DIV f.unitwidth)
  END;
  RETURN r
END Scale;

(* The width, in the device's units, of s[start .. end-1] (UTF-8) in f
   at size, in points; unknown characters count half an em *)
PROCEDURE Units*(f: Font; VAR s: ARRAY OF CHAR; start, end: LONGINT; size: REAL): LONGINT;
  (* As groff sets a word (node.cpp's merge_glyph_node): each character
     either makes a ligature with the glyph before it, which it replaces,
     the kern before that glyph staying, or is kerned against it. So
     "ffi" in a font without ff is f, the kern f f, and fi. *)
  VAR total, i, c, prev, prevW, w, sz, lig: LONGINT; unknown: BOOLEAN;
  PROCEDURE Lig(a, b: LONGINT): LONGINT;
    VAR r: LONGINT;
  BEGIN
    r := Unknown;
    IF a = ORD("f") THEN
      IF (b = ORD("f")) & (Ff IN f.ligatures) THEN r := 0FB00H
      ELSIF (b = ORD("i")) & (Fi IN f.ligatures) THEN r := 0FB01H
      ELSIF (b = ORD("l")) & (Fl IN f.ligatures) THEN r := 0FB02H
      END
    ELSIF a = 0FB00H THEN
      IF (b = ORD("i")) & (Ffi IN f.ligatures) THEN r := 0FB03H
      ELSIF (b = ORD("l")) & (Ffl IN f.ligatures) THEN r := 0FB04H
      END
    END;
    IF (r # Unknown) & (GlyphWidth(f, r) = Unknown) THEN r := Unknown END;
    RETURN r
  END Lig;
BEGIN
  sz := ENTIER(size * f.sizescale + 0.5);
  total := 0; prev := Unknown; prevW := 0; i := start;
  WHILE i < end DO
    c := Decode(s, i, end);
    lig := Unknown;
    IF prev # Unknown THEN lig := Lig(prev, c) END;
    IF lig # Unknown THEN
      w := Scale(f, GlyphWidth(f, lig), sz);
      INC(total, w - prevW); prev := lig; prevW := w
    ELSE
      unknown := FALSE;
      IF c = ORD(" ") THEN w := f.spacewidth
      ELSE
        w := GlyphWidth(f, c);
        IF (w = Unknown) & (c = 0A0H) THEN w := f.spacewidth END;
        IF w = Unknown THEN w := f.unitwidth DIV 2; unknown := TRUE END
      END;
      IF (prev # Unknown) & ~unknown & (c # ORD(" ")) THEN INC(total, Scale(f, KernAmount(f, prev, c), sz)) END;
      w := Scale(f, w, sz);
      INC(total, w);
      IF unknown OR (c = ORD(" ")) THEN prev := Unknown ELSE prev := c END;
      prevW := w
    END
  END;
  RETURN total
END Units;

(* The width of s[start .. end-1] in f at size, in points *)
PROCEDURE Width*(f: Font; VAR s: ARRAY OF CHAR; start, end: LONGINT; size: REAL): REAL;
BEGIN
  RETURN Units(f, s, start, end, size) * 72.0 / f.res
END Width;

(* The width of the widest line of lab, and the height of its lines,
   in points, set at size with vs points from line to line *)
PROCEDURE LabelSize*(f: Font; lab: F.Label; size, vs: REAL; VAR w, h: REAL);
  VAR l: F.Line; x: REAL;
BEGIN
  w := 0; h := 0;
  IF lab = NIL THEN RETURN END;
  l := lab.lines;
  WHILE l # NIL DO
    x := Width(f, l.text^, 0, L.Length(l.text^), size);
    IF x > w THEN w := x END;
    l := l.next
  END;
  h := lab.n * vs
END LabelSize;

(* The width and height of a node of shape s around text tw by th
   points, at size, as Mermaid sizes its shapes (rendering-util's
   shapes), with its padding *)
PROCEDURE ShapeSize*(shape: INTEGER; tw, th, size: REAL; VAR w, h: REAL);
  VAR p, r, ry: REAL;
BEGIN
  p := size * PadNum / PadDen;   (* on each side *)
  w := tw + 2 * p; h := th + 2 * p;
  CASE shape OF
    F.Rect, F.Round:
  | F.Stadium: w := tw + h / 2 + 2 * p
  | F.Subroutine: w := w + size
  | F.Cylinder:
      ry := w / 2 / (2.5 + w / 50); h := h + 2 * ry
  | F.Circle, F.DoubleCircle:
      r := tw; IF th > r THEN r := th END;
      r := r / 2 + p;
      IF shape = F.DoubleCircle THEN r := r + size * 5 / 16 END;
      w := 2 * r; h := w
  | F.Asymmetric: w := w + h / 2
  | F.Diamond: w := w + h; h := w
  | F.Hexagon: w := w + h / 2
  | F.LeanRight, F.LeanLeft, F.Trapezoid, F.InvTrapezoid: w := w + 2 * h / 3
  END
END ShapeSize;

BEGIN
  InitSpecials; nDirs := 0; pathSet := FALSE
END PmMetrics.
