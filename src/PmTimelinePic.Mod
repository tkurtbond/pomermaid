MODULE PmTimelinePic;
(* PmTimelinePic: a laid out timeline, PmTimelineLayout's, written in
   pic, for groff, with PmPic's helpers.

   The drawing, as Mermaid's svgDraw.js draws it, from the back: top
   down, the axis; the dashed lines, each with its arrowhead; the
   nodes, each filled, its top corners rounded, with a line along its
   bottom and its text centred in it; left to right, the activity line,
   an arrow; and the title. The colours are Mermaid's (PmStyle.
   TimelineColours): node colour k is cScale k, its text cScaleLabel k
   and its bottom line cScaleInv k, for k from 0 to 11, round again
   after 12; an event's colours are brighter, by a fifth. *)

IMPORT Math, PmIO, G := PmGeom, S := PmStyle, P := PmPic, TL := PmTimelineLayout;

CONST
  NoColour = S.NoColour;
  Samples = 6;          (* the points of a rounded corner *)

TYPE
  Style = S.Style;
  Ints = POINTER TO ARRAY OF INTEGER;

VAR
  l: TL.Layout;
  px: REAL;
  t: S.TimelineTheme;
  fill, label, inv: Ints;   (* each node's colours, indexes *)
  dashed, arrow, axis, titleColour: INTEGER;
  dashSt, headSt, axisSt: Style;

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* rgb a fifth brighter, each channel at most FF *)
PROCEDURE Brighter*(rgb: LONGINT): LONGINT;
  VAR r, g, b: LONGINT;

  PROCEDURE Up(c: LONGINT): LONGINT;
  BEGIN
    c := (c * 12 + 5) DIV 10;
    IF c > 255 THEN c := 255 END;
    RETURN c
  END Up;

BEGIN
  IF rgb < 0 THEN RETURN rgb END;
  r := rgb DIV 10000H MOD 100H; g := rgb DIV 100H MOD 100H; b := rgb MOD 100H;
  RETURN (Up(r) * 100H + Up(g)) * 100H + Up(b)
END Brighter;

(* st: filled with fill, its line line, width pixels wide, dashes of
   dash pixels *)
PROCEDURE Make(VAR st: Style; fill, line: INTEGER; width, dash: REAL);
BEGIN
  st.fill := fill; st.line := line; st.text := NoColour; st.inner := NoColour;
  st.width := width * px; st.dash := dash * px
END Make;

PROCEDURE Line(x1, y1, x2, y2: REAL; VAR st: Style);
BEGIN
  IF st.line = NoColour THEN RETURN END;
  P.W("line from "); P.Pt(x1, y1); P.W(" to "); P.Pt(x2, y2);
  P.Paint(st, FALSE); PmIO.WriteLn
END Line;

(* An arrow from (x1, y1) to its tip at (x2, y2), its head len long and
   wide wide, on a line drawn in st *)
PROCEDURE Arrow(x1, y1, x2, y2, len, wide: REAL; VAR st, head: Style);
  VAR d, ux, uy, bx, by: REAL; p: ARRAY 3 OF G.Point;
BEGIN
  d := Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
  IF d <= 0 THEN RETURN END;
  ux := (x2 - x1) / d; uy := (y2 - y1) / d;
  bx := x2 - ux * len; by := y2 - uy * len;
  Line(x1, y1, bx, by, st);
  G.Set(p[0], bx - uy * wide / 2, by + ux * wide / 2); G.Set(p[1], x2, y2);
  G.Set(p[2], bx + uy * wide / 2, by - ux * wide / 2);
  P.Polygon(p, 3, head)
END Arrow;

(* Node k: its box, its top corners rounded, filled; its bottom line;
   its text *)
PROCEDURE Node(k: INTEGER);
  VAR p: ARRAY 4 * Samples + 8 OF G.Point; n, i: INTEGER; x, y, w, h, r, a: REAL;
    st: Style;
BEGIN
  x := l.x[k]; y := l.y[k]; w := l.w[k]; h := l.h[k]; r := TL.Radius * px;
  n := 0;
  G.Set(p[n], x, y + h); INC(n);
  FOR i := 0 TO Samples DO   (* the top left corner *)
    a := (2 - i / Samples) * 1.5707963;
    G.Set(p[n], x + r + r * Math.cos(a), y + r - r * Math.sin(a)); INC(n)
  END;
  FOR i := 0 TO Samples DO   (* the top right corner *)
    a := (1 - i / Samples) * 1.5707963;
    G.Set(p[n], x + w - r + r * Math.cos(a), y + r - r * Math.sin(a)); INC(n)
  END;
  G.Set(p[n], x + w, y + h); INC(n);
  Make(st, fill[k], NoColour, 0, 0);
  IF st.fill # NoColour THEN P.Polygon(p, n, st) END;
  Make(st, NoColour, inv[k], TL.BottomW, 0);
  Line(x, y + h, x + w, y + h, st);
  P.Lines(l.text[k], x + w / 2, y + h / 2, label[k], 0, FALSE)
END Node;

(* The styles, each colour added to PmStyle's table *)
PROCEDURE Styles;
  VAR k, c: INTEGER; f, lb, iv: LONGINT;
BEGIN
  S.Reset(l.d.g, px); S.TimelineColours(t);
  NEW(fill, l.n + 1); NEW(label, l.n + 1); NEW(inv, l.n + 1);
  FOR k := 0 TO l.n - 1 DO
    c := l.colour[k] MOD 12;
    f := t.scale[c]; lb := t.label[c]; iv := t.inv[c];
    IF l.kind[k] = TL.EventNode THEN f := Brighter(f); lb := Brighter(lb); iv := Brighter(iv) END;
    fill[k] := C(f); label[k] := C(lb); inv[k] := C(iv)
  END;
  dashed := C(t.line); arrow := dashed; axis := dashed;
  Make(dashSt, NoColour, dashed, TL.DashW, TL.Dash);
  Make(headSt, arrow, arrow, 1, 0);
  Make(axisSt, axis, axis, TL.AxisW, 0);
  titleColour := C(t.title)
END Styles;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: TL.Layout): REAL;
BEGIN
  RETURN TL.AxisW * lay.px
END Widest;

(* Writes lay's timeline in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: TL.Layout; font: ARRAY OF CHAR);
  VAR k: INTEGER; y: REAL;
BEGIN
  l := lay; px := l.px;
  P.Setup(font, l.font, px);
  Styles;
  P.Begin(l.size, l.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(l.width); P.W(" ht "); P.In(l.height);
  P.At(l.width / 2, l.height / 2); PmIO.WriteLn;
  IF l.d.td THEN
    Arrow(l.ax1, l.ay1, l.ax2, l.ay2, 24 * px, 16 * px, axisSt, headSt)
  END;
  FOR k := 0 TO l.nLines - 1 DO
    Arrow(l.x1[k], l.y1[k], l.x2[k], l.y2[k], 12 * px, 8 * px, dashSt, headSt)
  END;
  FOR k := 0 TO l.n - 1 DO Node(k) END;
  IF ~l.d.td THEN
    Arrow(l.ax1, l.ay1, l.ax2, l.ay2, 24 * px, 16 * px, axisSt, headSt)
  END;
  IF l.title # NIL THEN
    y := l.titleY;
    P.W("box invis wid "); P.In(l.titleW); P.W(" ht "); P.In(l.titleH);
    P.At(l.titleX + l.titleW / 2, y); PmIO.WriteLn;
    P.Lines(l.title, l.titleX, y, titleColour, l.titleSize, TRUE)
  END;
  P.End
END Write;

END PmTimelinePic.
