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
   viewBox and a height without that band (Crop).

   A node's click link or tooltip is written after the drawing, as
   Mermaid's htmlLabels do not make it in a drawing made this way: an
   <a> element, or a <g> for a tooltip alone, holding the tooltip as a
   <title> and a rectangle over the node's bounds, filled but clear. *)

IMPORT PmIO, F := PmFlow, FL := PmFlowLayout, L := PmLayout, PmPic, R := PmRun,
  SL := PmSeqLayout, PmSeqPic, JL := PmJourneyLayout, PmJourneyPic,
  TL := PmTimelineLayout, PmTimelinePic, GL := PmGanttLayout, PmGanttPic,
  PL := PmPieLayout, PmPiePic;

CONST
  MinMargin = 2; (* points round the drawing, at least, for lines' widths *)

  (* engines *)
  Auto* = 0; Mutool* = 1; Pdftocairo* = 2;

VAR
  vs, margin, pageW, pageH: REAL; (* pic's line space, the margin, and the
                                     page's size, in points *)
  flow: FL.Layout; seq: SL.Layout; journey: JL.Layout; timeline: TL.Layout;
  gantt: GL.Layout; pie: PL.Layout;   (* what Write draws: one of them *)

(* The page's size for a drawing w by h points, pic's line space
   lvs, its widest line widest points wide, rounded as it is written *)
PROCEDURE PageSize(lvs, widest, w, h: REAL);
BEGIN
  vs := ENTIER(lvs * 100 + 0.5) / 100;
  margin := ENTIER(widest / 2 + 1.99);
  IF margin < MinMargin THEN margin := MinMargin END;
  pageW := ENTIER((w + 2 * margin) * 100 + 0.5) / 100;
  pageH := ENTIER((h + 2 * margin) * 100 + 0.5) / 100 + vs
END PageSize;

(* The start of the groff document for a drawing w by h points: a page
   the size of the drawing, its margins and one line space, for
   groff -p -Tpdf -P-p<height>,<width>, which its first line gives *)
PROCEDURE Header(lvs, widest, w, h: REAL);
BEGIN
  PageSize(lvs, widest, w, h);
  PmIO.WriteString('.\" pomermaid -t svg: groff -p -Tpdf -P-p');
  PmIO.WriteReal(pageH, 2); PmIO.WriteString("p,");
  PmIO.WriteReal(pageW, 2); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".pl "); PmIO.WriteReal(pageH, 2); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".po "); PmIO.WriteReal(margin, 0); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".ll "); PmIO.WriteReal(w, 2); PmIO.WriteString("p"); PmIO.WriteLn;
  PmIO.WriteString(".sp "); PmIO.WriteReal(margin, 0); PmIO.WriteString("p"); PmIO.WriteLn
END Header;

(* Writes the groff document for l, its labels in the groff font font *)
PROCEDURE WriteDocument*(l: FL.Layout; font: ARRAY OF CHAR);
BEGIN
  Header(l.vs, PmPic.Widest(l), l.g.width, l.g.height);
  PmPic.Write(l, font)
END WriteDocument;

(* Writes the groff document for the sequence diagram l *)
PROCEDURE WriteSeqDocument*(l: SL.Layout; font: ARRAY OF CHAR);
BEGIN
  Header(l.vs, PmSeqPic.Widest(l), l.width, l.height);
  PmSeqPic.Write(l, font)
END WriteSeqDocument;

(* Writes the groff document for the user journey l *)
PROCEDURE WriteJourneyDocument*(l: JL.Layout; font: ARRAY OF CHAR);
BEGIN
  Header(l.vs, PmJourneyPic.Widest(l), l.width, l.height);
  PmJourneyPic.Write(l, font)
END WriteJourneyDocument;

(* Writes the timeline l as WriteDocument does a flowchart *)
PROCEDURE WriteTimelineDocument*(l: TL.Layout; font: ARRAY OF CHAR);
BEGIN
  Header(l.vs, PmTimelinePic.Widest(l), l.width, l.height);
  PmTimelinePic.Write(l, font)
END WriteTimelineDocument;

(* Writes the Gantt chart l as WriteDocument does a flowchart *)
PROCEDURE WriteGanttDocument*(l: GL.Layout; font: ARRAY OF CHAR);
BEGIN
  Header(l.size * 1.2, PmGanttPic.Widest(l), l.width, l.height);
  PmGanttPic.Write(l, font)
END WriteGanttDocument;

(* Writes the pie chart l as WriteDocument does a flowchart *)
PROCEDURE WritePieDocument*(l: PL.Layout; font: ARRAY OF CHAR);
BEGIN
  Header(l.vs, PmPiePic.Widest(l), l.width, l.height);
  PmPiePic.Write(l, font)
END WritePieDocument;

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

(* Links *)

(* Whether t[start .. end-1] holds s after a blank *)
PROCEDURE Declares(t: PmIO.Text; start, end: LONGINT; s: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := start + 1 TO end - 1 DO
    IF (t[i - 1] <= " ") & At(t, end, i, s) THEN RETURN TRUE END
  END;
  RETURN FALSE
END Declares;

(* s, escaped for an attribute's value or text *)
PROCEDURE Xml(s: F.Str);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    CASE s[i] OF
      "&": PmIO.WriteString("&amp;")
    | "<": PmIO.WriteString("&lt;")
    | ">": PmIO.WriteString("&gt;")
    | 22X: PmIO.WriteString("&quot;")
    ELSE
      IF s[i] >= " " THEN PmIO.WriteChar(s[i]) END
    END;
    INC(i)
  END
END Xml;

PROCEDURE Lower(c: CHAR): CHAR;
BEGIN
  IF (c >= "A") & (c <= "Z") THEN c := CHR(ORD(c) + 32) END;
  RETURN c
END Lower;

(* Whether url is one Mermaid's sanitizeUrl (@braintree/sanitize-url)
   makes about:blank: it has a scheme, and after any characters that
   are not letters, digits or "_" it starts with javascript, data or
   vbscript, in any case *)
PROCEDURE Unsafe(url: F.Str): BOOLEAN;
  VAR i, k: LONGINT; colon: BOOLEAN;

  PROCEDURE Is(w: ARRAY OF CHAR): BOOLEAN;
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE (w[j] # 0X) & (Lower(url[i + j]) = w[j]) DO INC(j) END;
    RETURN w[j] = 0X
  END Is;

BEGIN
  colon := FALSE; k := 0;
  WHILE url[k] # 0X DO IF url[k] = ":" THEN colon := TRUE END; INC(k) END;
  IF ~colon OR (url[0] = ".") OR (url[0] = "/") THEN RETURN FALSE END;
  i := 0;
  WHILE (url[i] # 0X) & ~((Lower(url[i]) >= "a") & (Lower(url[i]) <= "z") OR
      (url[i] >= "0") & (url[i] <= "9") OR (url[i] = "_")) DO INC(i) END;
  RETURN Is("javascript") OR Is("data") OR Is("vbscript")
END Unsafe;

(* Writes the links and tooltips of l's nodes, in the page's points,
   with xlink:href as well as href if xlink is declared *)
PROCEDURE Links(l: FL.Layout; xlink: BOOLEAN);
  VAR n: F.Node; ln: L.Node; first: BOOLEAN;

  PROCEDURE Num(name: ARRAY OF CHAR; x: REAL);
  BEGIN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteString('="');
    PmIO.WriteReal(x, 2); PmIO.WriteChar(22X)
  END Num;

  PROCEDURE Href(name: ARRAY OF CHAR; url: F.Str);
  BEGIN
    PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteString('="');
    IF Unsafe(url) THEN PmIO.WriteString("about:blank") ELSE Xml(url) END;
    PmIO.WriteChar(22X)
  END Href;

BEGIN
  PageSize(l.vs, PmPic.Widest(l), l.g.width, l.g.height); first := TRUE;
  n := l.graph.nodes;
  WHILE n # NIL DO
    IF (n.link # NIL) OR (n.tooltip # NIL) THEN
      IF first THEN PmIO.WriteString('<g class="pm-links">'); PmIO.WriteLn; first := FALSE END;
      IF n.link # NIL THEN
        PmIO.WriteString("<a");
        Href("href", n.link);
        IF xlink THEN Href("xlink:href", n.link) END;
        IF n.linkTarget # NIL THEN
          PmIO.WriteString(' target="'); Xml(n.linkTarget); PmIO.WriteChar(22X)
        END;
        PmIO.WriteChar(">")
      ELSE PmIO.WriteString("<g>")
      END;
      IF n.tooltip # NIL THEN
        PmIO.WriteString("<title>"); Xml(n.tooltip); PmIO.WriteString("</title>")
      END;
      ln := l.g.node[n.index];
      PmIO.WriteString("<rect");
      Num("x", margin + ln.x - ln.w / 2); Num("y", margin + vs + ln.y - ln.h / 2);
      Num("width", ln.w); Num("height", ln.h);
      PmIO.WriteString(' fill="#ffffff" fill-opacity="0"/>');
      IF n.link # NIL THEN PmIO.WriteString("</a>") ELSE PmIO.WriteString("</g>") END;
      PmIO.WriteLn
    END;
    n := n.next
  END;
  IF ~first THEN PmIO.WriteString("</g>"); PmIO.WriteLn END
END Links;

(* Writes the SVG t[0 .. len-1] with the band of top points cut from the
   top of its page: the root element's height and viewBox lose top, and
   the viewBox starts top lower. The rest is written as it is, and the
   links of the layout l, if it is not NIL, before the last </svg>. FALSE,
   and nothing written, if the root element has no height or viewBox
   that can be read. *)
PROCEDURE Crop*(t: PmIO.Text; len: LONGINT; top: REAL; l: FL.Layout): BOOLEAN;
  VAR i, start, end, hAt, hEnd, vAt, vEnd, k, close: LONGINT; h: REAL;
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
  close := len - 6;
  WHILE (close > k) & ~At(t, len, close, "</svg>") DO DEC(close) END;
  IF (l = NIL) OR (close <= k) THEN close := len END;
  PmIO.WriteChars(t^, k, close - k);
  IF close < len THEN
    Links(l, Declares(t, start, end, "xmlns:xlink="));
    PmIO.WriteChars(t^, close, len - close)
  END;
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
PROCEDURE Run(font, fontPath, output: ARRAY OF CHAR;
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
  PmIO.OpenOutput(tr);
  IF seq # NIL THEN WriteSeqDocument(seq, font)
  ELSIF journey # NIL THEN WriteJourneyDocument(journey, font)
  ELSIF timeline # NIL THEN WriteTimelineDocument(timeline, font)
  ELSIF gantt # NIL THEN WriteGanttDocument(gantt, font)
  ELSIF pie # NIL THEN WritePieDocument(pie, font)
  ELSE WriteDocument(flow, font) END;
  PmIO.CloseOutput;
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
  IF ~Crop(t, len, vs, flow) THEN Fail("the SVG made has no height or viewBox pomermaid can read", PmIO.ProgramError) END;
  PmIO.CloseOutput;
  R.RemoveDir(dir)
END Run;

PROCEDURE Write*(l: FL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
BEGIN
  flow := l; seq := NIL; journey := NIL; timeline := NIL; gantt := NIL; pie := NIL; Run(font, fontPath, output, outline, engine)
END Write;

(* Writes the sequence diagram l as SVG, as Write does a flowchart *)
PROCEDURE WriteSeq*(l: SL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
BEGIN
  flow := NIL; seq := l; journey := NIL; timeline := NIL; gantt := NIL; pie := NIL; Run(font, fontPath, output, outline, engine)
END WriteSeq;

(* Writes the user journey l as SVG, as Write does a flowchart *)
PROCEDURE WriteJourney*(l: JL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
BEGIN
  flow := NIL; seq := NIL; journey := l; timeline := NIL; gantt := NIL; pie := NIL; Run(font, fontPath, output, outline, engine)
END WriteJourney;

(* Writes the timeline l as SVG, as Write does a flowchart *)
PROCEDURE WriteTimeline*(l: TL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
BEGIN
  flow := NIL; seq := NIL; journey := NIL; timeline := l; gantt := NIL; pie := NIL;
  Run(font, fontPath, output, outline, engine)
END WriteTimeline;

(* Writes the Gantt chart l as SVG, as Write does a flowchart *)
PROCEDURE WriteGantt*(l: GL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
BEGIN
  flow := NIL; seq := NIL; journey := NIL; timeline := NIL; gantt := l; pie := NIL;
  Run(font, fontPath, output, outline, engine)
END WriteGantt;

(* Writes the pie chart l as SVG, as Write does a flowchart *)
PROCEDURE WritePie*(l: PL.Layout; font, fontPath, output: ARRAY OF CHAR;
  outline: BOOLEAN; engine: INTEGER);
BEGIN
  flow := NIL; seq := NIL; journey := NIL; timeline := NIL; gantt := NIL; pie := l;
  Run(font, fontPath, output, outline, engine)
END WritePie;

END PmSvg.
