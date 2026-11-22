MODULE PmSvg;
(* PmSvg: SVG, made from the pic drawing through groff (decision 10).

   The pic drawing is put in a groff document whose page is the
   drawing's size with a margin of at least MinMargin points, more for
   lines wider than 2 points (WriteDocument; -t
   svg-ms writes only this). groff -p -Tpdf makes a one-page PDF of it,
   and mutool draw (MuPDF), or pdftocairo (poppler) where mutool is
   missing, turns that into SVG, in a temporary directory.

   pic draws a picture with its top at the baseline of its first line,
   one line space (.vs) below where it starts, and groff cannot move
   above the top of the page; so the page is one line space taller than
   the drawing and its margins, and the SVG's root element is given a
   viewBox and a height without that band (Crop). *)

IMPORT PmIO, FL := PmFlowLayout, PmPic, R := PmRun;

CONST
  MinMargin = 2; (* points round the drawing, at least, for lines' widths *)

  (* engines *)
  Auto* = 0; Mutool* = 1; Pdftocairo* = 2;

VAR
  vs, margin, pageW, pageH: REAL; (* pic's line space, the margin, and the
                                     page's size, in points *)

(* The page's size for l, rounded as it is written *)
PROCEDURE PageSize(l: FL.Layout);
BEGIN
  vs := ENTIER(l.vs * 100 + 0.5) / 100;
  margin := ENTIER(PmPic.Widest(l) / 2 + 1.99);
  IF margin < MinMargin THEN margin := MinMargin END;
  pageW := ENTIER((l.g.width + 2 * margin) * 100 + 0.5) / 100;
  pageH := ENTIER((l.g.height + 2 * margin) * 100 + 0.5) / 100 + vs
END PageSize;

(* Writes the groff document for l, its labels in the groff font font:
   a page the size of the drawing, its margins and one line space, for
   groff -p -Tpdf -P-p<height>,<width>, which its first line gives. *)
PROCEDURE WriteDocument*(l: FL.Layout; font: ARRAY OF CHAR);
BEGIN
  PageSize(l);
  PmIO.WriteString('.\" pomermaid -t svg: groff -p -Tpdf -P-p');
  PmIO.WriteReal(pageH, 2); PmIO.WriteString("p,");
  PmIO.WriteReal(pageW, 2); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".pl "); PmIO.WriteReal(pageH, 2); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".po "); PmIO.WriteReal(margin, 0); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".ll "); PmIO.WriteReal(l.g.width, 2); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".sp "); PmIO.WriteReal(margin, 0); PmIO.WriteString("p"); PmIO.WriteLn;
  PmPic.Write(l, font)
END WriteDocument;

(* Crop *)

(* Whether t[i ..] starts with s *)
PROCEDURE At(t: PmIO.Text; len, i: LONGINT; s: ARRAY OF CHAR): BOOLEAN;
  VAR j: LONGINT;
BEGIN
  j := 0;
  WHILE (j < LEN(s)) & (s[j] # 0X) & (i + j < len) & (t[i + j] = s[j]) DO INC(j) END;
  RETURN (j >= LEN(s)) OR (s[j] = 0X)
END At;

(* A decimal number at t[i], maybe signed; i is left after it. FALSE if
   there is none. *)
PROCEDURE Number(t: PmIO.Text; len: LONGINT; VAR i: LONGINT; VAR x: REAL): BOOLEAN;
  VAR frac: REAL; neg, digits: BOOLEAN;
BEGIN
  x := 0; neg := FALSE; digits := FALSE;
  IF (i < len) & (t[i] = "-") THEN neg := TRUE; INC(i) END;
  WHILE (i < len) & (t[i] >= "0") & (t[i] <= "9") DO
    x := x * 10 + (ORD(t[i]) - ORD("0")); INC(i); digits := TRUE
  END;
  IF (i < len) & (t[i] = ".") THEN
    INC(i); frac := 1;
    WHILE (i < len) & (t[i] >= "0") & (t[i] <= "9") DO
      frac := frac / 10; x := x + frac * (ORD(t[i]) - ORD("0")); INC(i); digits := TRUE
    END
  END;
  IF neg THEN x := -x END;
  RETURN digits
END Number;

PROCEDURE Spaces(t: PmIO.Text; len: LONGINT; VAR i: LONGINT);
BEGIN
  WHILE (i < len) & ((t[i] = " ") OR (t[i] = ",")) DO INC(i) END
END Spaces;

(* Writes the SVG t[0 .. len-1] with the band of top points cut from the
   top of its page: the root element's height and viewBox lose top, and
   the viewBox starts top lower. The rest is written as it is. FALSE,
   and nothing written, if the root element has no height or viewBox
   that can be read. *)
PROCEDURE Crop*(t: PmIO.Text; len: LONGINT; top: REAL): BOOLEAN;
  VAR i, start, end, hAt, hEnd, vAt, vEnd, k: LONGINT; h: REAL;
    vb: ARRAY 4 OF REAL; n: INTEGER; ok: BOOLEAN;
BEGIN
  (* the root element, t[start .. end-1] *)
  i := 0;
  WHILE (i < len) & ~(At(t, len, i, "<svg") & (i + 4 < len) & (t[i + 4] <= " ")) DO INC(i) END;
  start := i;
  WHILE (i < len) & (t[i] # ">") DO INC(i) END;
  end := i;
  IF end >= len THEN RETURN FALSE END;
  (* its height's number and viewBox's value *)
  hAt := -1; vAt := -1; i := start + 4;
  WHILE i < end DO
    IF (t[i - 1] <= " ") & At(t, len, i, 'height="') THEN
      hAt := i + 8; hEnd := hAt;
      ok := Number(t, len, hEnd, h);
      IF ~ok THEN RETURN FALSE END
    ELSIF (t[i - 1] <= " ") & At(t, len, i, 'viewBox="') THEN
      vAt := i + 9; vEnd := vAt; n := 0; ok := TRUE;
      WHILE ok & (n < 4) DO
        Spaces(t, len, vEnd); ok := Number(t, len, vEnd, vb[n]); INC(n)
      END;
      IF ~ok OR (vEnd >= len) OR (t[vEnd] # '"') THEN RETURN FALSE END
    END;
    INC(i)
  END;
  IF (hAt < 0) OR (vAt < 0) OR (h <= top) OR (vb[3] <= top) THEN RETURN FALSE END;
  IF hAt < vAt THEN
    PmIO.WriteChars(t^, 0, hAt); PmIO.WriteReal(h - top, 2);
    PmIO.WriteChars(t^, hEnd, vAt - hEnd)
  ELSE
    PmIO.WriteChars(t^, 0, vAt)
  END;
  PmIO.WriteReal(vb[0], 2); PmIO.WriteChar(" ");
  PmIO.WriteReal(vb[1] + top, 2); PmIO.WriteChar(" ");
  PmIO.WriteReal(vb[2], 2); PmIO.WriteChar(" ");
  PmIO.WriteReal(vb[3] - top, 2);
  k := vEnd;
  IF vAt < hAt THEN
    PmIO.WriteChars(t^, vEnd, hAt - vEnd); PmIO.WriteReal(h - top, 2); k := hEnd
  END;
  PmIO.WriteChars(t^, k, len - k);
  RETURN TRUE
END Crop;

(* SVG *)

(* Appends x, x >= 0, to p in points, with two decimals: "12.5p" *)
PROCEDURE AppendPoints(VAR p: ARRAY OF CHAR; x: REAL);
  VAR n: LONGINT;
BEGIN
  n := ENTIER(x * 100 + 0.5);
  R.AppendInt(p, n DIV 100);
  IF n MOD 100 # 0 THEN
    R.Append(p, ".");
    IF n MOD 100 < 10 THEN R.Append(p, "0") END;
    R.AppendInt(p, n MOD 100)
  END;
  R.Append(p, "p")
END AppendPoints;

(* Adds groff's -F for each directory of the colon-separated path p *)
PROCEDURE AddFontPath(c: R.Command; p: ARRAY OF CHAR);
  VAR d: R.Path; i, j: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(p)) & (p[i] # 0X) DO
    j := 0;
    WHILE (i < LEN(p)) & (p[i] # 0X) & (p[i] # ":") DO
      IF j < LEN(d) - 1 THEN d[j] := p[i]; INC(j) END;
      INC(i)
    END;
    d[j] := 0X;
    IF j > 0 THEN R.AddText(c, " -F"); R.Add(c, d) END;
    IF (i < LEN(p)) & (p[i] = ":") THEN INC(i) END
  END
END AddFontPath;

(* Writes l as SVG to the file output, or to standard output if it is ""
   or "-": its labels in the groff font font, found in fontPath if that
   is not "" (groff's -F); the glyphs drawn as outlines if outline, else
   as text; made with engine, Auto for mutool if it is found and else
   pdftocairo. Ends pomermaid with 47 if a program is missing, 43 if one
   fails. *)
PROCEDURE Write*(l: FL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
  VAR dir, tr, pdf, svg, arg: R.Path; c: R.Command; ok: BOOLEAN; t: PmIO.Text; len: LONGINT;

  PROCEDURE Fail(msg: ARRAY OF CHAR; code: INTEGER);
  BEGIN
    R.RemoveDir(dir); PmIO.Fail("", msg, code)
  END Fail;

BEGIN
  IF ~R.Found("groff") THEN PmIO.Fail("", "groff not found; SVG needs it", PmIO.ProgramNotFound) END;
  IF engine = Auto THEN
    IF R.Found("mutool") THEN engine := Mutool
    ELSIF R.Found("pdftocairo") THEN engine := Pdftocairo
    ELSE PmIO.Fail("", "neither mutool nor pdftocairo found; SVG needs one", PmIO.ProgramNotFound)
    END
  ELSIF (engine = Mutool) & ~R.Found("mutool") THEN
    PmIO.Fail("", "mutool not found", PmIO.ProgramNotFound)
  ELSIF (engine = Pdftocairo) & ~R.Found("pdftocairo") THEN
    PmIO.Fail("", "pdftocairo not found", PmIO.ProgramNotFound)
  END;
  R.MakeTempDir(dir, ok);
  IF ~ok THEN PmIO.Fail("", "cannot make a temporary directory", PmIO.IOError) END;
  COPY(dir, tr); R.Append(tr, "/diagram.tr");
  COPY(dir, pdf); R.Append(pdf, "/diagram.pdf");
  COPY(dir, svg); R.Append(svg, "/diagram.svg");
  PmIO.OpenOutput(tr); WriteDocument(l, font); PmIO.CloseOutput;
  c := R.New(); R.AddText(c, "groff -p -Tpdf");
  IF fontPath # "" THEN AddFontPath(c, fontPath) END;
  COPY("-P-p", arg); AppendPoints(arg, pageH); R.Append(arg, ",");
  AppendPoints(arg, pageW); R.Add(c, arg); R.Add(c, tr);
  R.AddText(c, " >"); R.Add(c, pdf);
  IF R.Run(c) # 0 THEN Fail("groff failed", PmIO.ProgramError) END;
  c := R.New();
  IF engine = Mutool THEN
    R.AddText(c, "mutool draw -q -F svg -O");
    IF outline THEN R.Add(c, "text=path") ELSE R.Add(c, "text=text") END;
    R.AddText(c, " -o"); R.Add(c, svg); R.Add(c, pdf)
  ELSE
    R.AddText(c, "pdftocairo -svg"); R.Add(c, pdf); R.Add(c, svg)
  END;
  IF R.Run(c) # 0 THEN
    IF engine = Mutool THEN Fail("mutool failed", PmIO.ProgramError)
    ELSE Fail("pdftocairo failed", PmIO.ProgramError)
    END
  END;
  IF ~PmIO.Exists(svg) THEN Fail("no SVG was made", PmIO.ProgramError) END;
  PmIO.ReadFile(svg, t, len);
  PmIO.OpenOutput(output);
  IF ~Crop(t, len, vs) THEN Fail("the SVG made has no height or viewBox pomermaid can read", PmIO.ProgramError) END;
  PmIO.CloseOutput;
  R.RemoveDir(dir)
END Write;

END PmSvg.
