MODULE PmPieLayout;
(* PmPieLayout: a pie chart, PmPie's, laid out as Mermaid's
   pieRenderer.ts lays it out, in its pixels, taken at the labels'
   size, the slices' and the legend's 17 pixels to the size. Lengths
   are in points, y down; a text's y is its middle, 0.3 of its size
   above Mermaid's baseline. Angles are in radians, clockwise from 12
   o'clock.

   The pie is 450 pixels square, its centre at (225, 225), its radius
   185, a donut's hole donutHole of that. A section of less than 1% of
   the sum of the values is not drawn; the others fill the circle, in
   order, and each has its percentage of the sum, rounded, in the
   middle of its angle at textPosition of the radius. The slice
   named by highlightSlice is drawn 1.05 times as large.

   The legend has every section: an 18 pixel square in its colour and,
   4 pixels right of it, its label, with its value in brackets for
   showData; rows 22 pixels apart, L the widest text. It is, by
   legendPosition:

   - right, the default: at x 441, its rows centred at y 225; the
     drawing 512 + L wide;
   - left: at x 18; the pie moved right by L + 22, the drawing as
     wide;
   - center: over the pie, its rows centred at (225, 225);
   - top: centred at x 225, from y 40; the pie moved down by 22 for
     each row and 22 more, the drawing as much higher;
   - bottom: centred at x 225, from y 432; the drawing 22 higher for
     each row.

   The title, 25 pixels high, has its baseline at y 25, centred over
   the pie; Mermaid centres it at x 225 when the pie is moved right
   too. A title wider than the drawing widens it.

   Colours are numbered from 0, a section's by its place among all the
   sections, the 12 used in turn. PmPiePic draws this layout;
   PmPieMp places the legend and the title again, with ConTeXt's text
   widths. *)

IMPORT Math, L := PmLex, F := PmFlow, M := PmMetrics, P := PmPie;

CONST
  MermaidSize* = 17;     (* the slices' and the legend's text, at the labels' size *)
  Drop* = 0.3;           (* a text's middle, above its baseline, of its size *)
  Colours* = 12;
  (* in Mermaid's pixels *)
  Size* = 450;           (* the pie's square *)
  Margin* = 40;
  Radius* = 185;         (* Size / 2 - Margin *)
  Box* = 18;             (* a legend's square *)
  Spacing* = 4;          (* from it to its text *)
  Row* = 22;             (* Box + Spacing *)
  TextBase* = 14;        (* a legend's baseline, below its square's top *)
  RightX* = 216;         (* the legend, right of the centre *)
  TitleSize* = 25;
  TitleBase* = 25;       (* the title's baseline *)
  Highlight* = 1.05;
  MinPercent = 1;        (* smaller sections are not drawn *)

TYPE
  Reals* = POINTER TO ARRAY OF REAL;
  Ints* = POINTER TO ARRAY OF INTEGER;
  Labels* = POINTER TO ARRAY OF F.Label;
  Bools* = POINTER TO ARRAY OF BOOLEAN;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: P.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;   (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    cx-, cy-, r-, hole-: REAL;  (* the pie's centre, radius, the hole's *)
    (* the slices, in order: each one's angles, from a0 to a1, colour,
       whether it is highlighted, its percentage and its text's middle *)
    nSlices-: INTEGER;
    a0-, a1-: Reals;
    colour-: Ints;
    highlighted-: Bools;
    percent-: Labels;
    tx-, ty-: Reals;
    (* the legend, every section: its square's top left, its colour,
       its text, the text's left and middle *)
    n-: INTEGER;
    bx-, by-: Reals;
    legendColour-: Ints;
    text-: Labels;
    lx-, ly-: Reals;
    legendW-: REAL;          (* the widest text, L *)
    title-: F.Label;         (* or NIL; centred at (titleX, titleY) *)
    titleSize-, titleW-, titleX-, titleY-: REAL
  END;

VAR
  buf: L.Str;

PROCEDURE Max(a, b: REAL): REAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

PROCEDURE Put(VAR n: LONGINT; ch: CHAR);
  VAR b: L.Str; k: LONGINT;
BEGIN
  IF n + 1 >= LEN(buf^) THEN
    NEW(b, 2 * LEN(buf^));
    FOR k := 0 TO n - 1 DO b[k] := buf[k] END;
    buf := b
  END;
  buf[n] := ch; INC(n)
END Put;

PROCEDURE PutStr(VAR n: LONGINT; s: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(n, s[i]); INC(i) END
END PutStr;

(* A section's legend text: its label, and with showData its value *)
PROCEDURE LegendText(d: P.Diagram; s: P.Section): F.Label;
  VAR n: LONGINT;
BEGIN
  IF ~d.showData THEN RETURN s.text END;
  n := 0; PutStr(n, s.name^); PutStr(n, " ["); PutStr(n, s.shown^); Put(n, "]");
  buf[n] := 0X;
  RETURN F.TextLabel(buf^, 0, n)
END LegendText;

(* p per cent, rounded half up, as toFixed(0) rounds, and "%" *)
PROCEDURE Percent(p: LONGREAL): F.Label;
  VAR k, n: LONGINT; digits: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  k := ENTIER(p + 0.5D0); i := 0;
  REPEAT digits[i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) UNTIL k = 0;
  n := 0;
  WHILE i > 0 DO DEC(i); Put(n, digits[i]) END;
  Put(n, "%"); buf[n] := 0X;
  RETURN F.TextLabel(buf^, 0, n)
END Percent;

(* Lays d out, its text set in font at size points, into lay *)
PROCEDURE Make*(d: P.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR
    l: Layout; px, w, h, lw, ox, oy, top, rows, chartW, chartH, mid, a, tr: REAL;
    s: P.Section; k, n: INTEGER; acc, kept: LONGREAL;
BEGIN
  NEW(l); lay := l; l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := px;
  n := d.nSections; l.n := n;
  NEW(l.a0, n + 1); NEW(l.a1, n + 1); NEW(l.colour, n + 1); NEW(l.highlighted, n + 1);
  NEW(l.percent, n + 1); NEW(l.tx, n + 1); NEW(l.ty, n + 1);
  NEW(l.bx, n + 1); NEW(l.by, n + 1); NEW(l.legendColour, n + 1); NEW(l.text, n + 1);
  NEW(l.lx, n + 1); NEW(l.ly, n + 1);
  (* the legend's text, L *)
  lw := 0; s := d.sections; k := 0;
  WHILE s # NIL DO
    l.text[k] := LegendText(d, s); l.legendColour[k] := s.index MOD Colours;
    M.LabelSize(font, l.text[k], size, l.vs, w, h);
    lw := Max(lw, w);
    s := s.next; INC(k)
  END;
  l.legendW := lw;
  (* where the pie is, and the legend, in pixels but L, in points *)
  rows := Row * n;
  ox := 0; oy := 0; chartW := Size + Margin; chartH := Size;
  CASE d.legend OF
    P.Right: chartW := chartW + Row + lw / px; top := Size / 2 - rows / 2
  | P.Left: chartW := chartW + Row + lw / px; ox := Row + lw / px; top := Size / 2 - rows / 2
  | P.Center: top := Size / 2 - rows / 2
  | P.Top: chartH := chartH + rows; oy := rows + Row; top := Size / 2 - Radius
  | P.Bottom: chartH := chartH + rows; top := Size / 2 + Radius + Row
  END;
  l.cx := (Size / 2 + ox) * px; l.cy := (Size / 2 + oy) * px;
  l.r := Radius * px; l.hole := d.donutHole * l.r;
  FOR k := 0 TO n - 1 DO
    CASE d.legend OF
      P.Right: l.bx[k] := (Size / 2 + RightX) * px
    | P.Left: l.bx[k] := (Size / 2 - Radius - Row) * px
    | P.Center, P.Top, P.Bottom: l.bx[k] := (Size / 2 - Row) * px - lw / 2
    END;
    l.by[k] := (top + Row * k) * px;
    l.lx[k] := l.bx[k] + Row * px;
    l.ly[k] := l.by[k] + TextBase * px - Drop * size
  END;
  (* the slices *)
  kept := 0; s := d.sections;
  WHILE s # NIL DO
    IF (d.sum > 0) & (s.value / d.sum * 100 >= MinPercent) THEN kept := kept + s.value END;
    s := s.next
  END;
  acc := 0; k := 0; s := d.sections; tr := d.textPosition * l.r;
  WHILE s # NIL DO
    IF (d.sum > 0) & (s.value / d.sum * 100 >= MinPercent) THEN
      l.a0[k] := SHORT(acc / kept * 2 * Math.pi);
      acc := acc + s.value;
      l.a1[k] := SHORT(acc / kept * 2 * Math.pi);
      l.colour[k] := s.index MOD Colours;
      l.highlighted[k] := (d.highlight # NIL) & L.Equal(d.highlight, s.name);
      l.percent[k] := Percent(s.value / d.sum * 100);
      mid := (l.a0[k] + l.a1[k]) / 2;
      l.tx[k] := l.cx + tr * Math.sin(mid);
      l.ty[k] := l.cy - tr * Math.cos(mid) - Drop * size;
      INC(k)
    END;
    s := s.next
  END;
  l.nSlices := k;
  (* the title *)
  l.title := NIL; l.titleSize := size * TitleSize / MermaidSize; l.titleW := 0;
  l.titleX := l.cx; l.titleY := TitleBase * px - Drop * l.titleSize;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    l.title := d.g.title;
    M.LabelSize(font, l.title, l.titleSize, l.titleSize * 1.2, l.titleW, h)
  END;
  l.width := chartW * px; l.height := chartH * px;
  (* a wide title widens the drawing, on both sides *)
  a := l.titleW / 2 - l.titleX;
  IF a > 0 THEN
    l.cx := l.cx + a; l.titleX := l.titleX + a; l.width := l.width + a;
    FOR k := 0 TO l.nSlices - 1 DO l.tx[k] := l.tx[k] + a END;
    FOR k := 0 TO n - 1 DO l.bx[k] := l.bx[k] + a; l.lx[k] := l.lx[k] + a END
  END;
  l.width := Max(l.width, l.titleX + l.titleW / 2)
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: P.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
  VAR k: INTEGER;
BEGIN
  Make(d, font, size, lay); k := 0;
  WHILE (maxW > 0) & (lay.width > maxW) & (k < 5) & (size > 0.2) DO
    size := ENTIER(size * maxW / lay.width * 10) / 10;
    IF size >= lay.size THEN size := lay.size - 0.1 END;
    IF size < 0.1 THEN size := 0.1 END;
    Make(d, font, size, lay); INC(k)
  END
END Fit;

BEGIN
  NEW(buf, 256)
END PmPieLayout.
