MODULE PmGanttPic;
(* PmGanttPic: a laid out Gantt chart, PmGanttLayout's, written in pic,
   for groff, with PmPic's helpers.

   The drawing, as Mermaid's ganttRenderer.js draws it, from the back:
   the excluded days; the background rows; the grid, its lines and
   their labels; the tasks' bars, milestones and vertical markers, then
   their text; the section names; the today line; and the title. The
   colours are Mermaid's default theme's and its Gantt styles'
   (PmStyle.GanttColours), by each task's section's colour number, from
   0 to numberSectionStyles - 1, of which Mermaid's styles colour 0 to
   3: a bar of a higher number is black, without an outline, and its
   text black.

   pic has no transparency, so what Mermaid draws see-through is drawn
   in the colour it gives over what is behind it: the rows (opacity
   0.2, over white, or over an excluded day's colour where they cross
   one) and the grid (opacity 0.8, over white). The grid is drawn over
   the rows, where Mermaid draws it under them. *)

IMPORT Math, PmIO, L := PmLex, G := PmGeom, S := PmStyle, P := PmPic, F := PmFlow,
  GL := PmGanttLayout;

CONST
  NoColour = S.NoColour;
  Samples = 4;          (* the points of a milestone's rounded corner *)
  RowOpacity = 0.2;
  GridOpacity* = 0.8;
  Styled* = 4;           (* Mermaid's styles colour sections 0 to 3 *)
  LineW = 2;            (* the bars' outlines, in pixels *)
  TodayW = 2;           (* the today line's *)
  GridW = 1;            (* the grid's *)

TYPE
  Style = S.Style;

VAR
  l: GL.Layout;
  px: REAL;
  t-: S.GanttTheme;    (* the colours, from Use *)
  todaySt: Style;

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* rgb at opacity a over back *)
PROCEDURE Over*(rgb: LONGINT; a: REAL; back: LONGINT): LONGINT;
  VAR k, c, b, r, m: LONGINT;
BEGIN
  IF rgb < 0 THEN RETURN back END;
  r := 0; m := 10000H;
  FOR k := 0 TO 2 DO
    c := rgb DIV m MOD 100H; b := back DIV m MOD 100H;
    r := r * 100H + ENTIER(c * a + b * (1 - a) + 0.5);
    m := m DIV 100H
  END;
  RETURN r
END Over;

(* st: filled with fill, its line line, width pixels wide *)
PROCEDURE Make(VAR st: Style; fill, line: LONGINT; width: REAL);
BEGIN
  st.fill := C(fill); st.line := C(line); st.text := NoColour; st.inner := NoColour;
  st.width := width * px; st.dash := 0
END Make;

(* A box, its top left corner at (x, y), w by h, its corners rounded
   rad points, at most half its width and height *)
PROCEDURE Box(x, y, w, h, rad: REAL; VAR st: Style);
BEGIN
  IF (st.fill = NoColour) & (st.line = NoColour) THEN RETURN END;
  IF rad > w / 2 THEN rad := w / 2 END;
  IF rad > h / 2 THEN rad := h / 2 END;
  P.W("box wid "); P.In(w); P.W(" ht "); P.In(h); P.At(x + w / 2, y + h / 2);
  IF rad > 0 THEN P.W(" rad "); P.In(rad) END;
  P.Paint(st, TRUE); PmIO.WriteLn
END Box;

PROCEDURE Line(x1, y1, x2, y2: REAL; VAR st: Style);
BEGIN
  IF st.line = NoColour THEN RETURN END;
  P.W("line from "); P.Pt(x1, y1); P.W(" to "); P.Pt(x2, y2);
  P.Paint(st, FALSE); PmIO.WriteLn
END Line;

(* The milestone in the box at (x, y), w by h, its corners rounded r
   points: turned 45 degrees and scaled by 0.8 about its middle *)
PROCEDURE Milestone(x, y, w, h, r: REAL; VAR st: Style);
  VAR p: ARRAY 4 * (Samples + 1) OF G.Point; n, c, i: INTEGER;
    cx, cy, a, dx, dy, ox, oy, k: REAL;
BEGIN
  IF r > w / 2 THEN r := w / 2 END;
  IF r > h / 2 THEN r := h / 2 END;
  cx := x + w / 2; cy := y + h / 2; k := 0.8 * Math.sqrt(0.5);
  n := 0;
  FOR c := 0 TO 3 DO   (* the corners, clockwise from the top right *)
    CASE c OF
      0: ox := w / 2 - r; oy := -h / 2 + r
    | 1: ox := w / 2 - r; oy := h / 2 - r
    | 2: ox := -w / 2 + r; oy := h / 2 - r
    | 3: ox := -w / 2 + r; oy := -h / 2 + r
    END;
    FOR i := 0 TO Samples DO
      a := (c - 1 + i / Samples) * 1.5707963;
      dx := ox + r * Math.cos(a); dy := oy + r * Math.sin(a);
      G.Set(p[n], cx + (dx - dy) * k, cy + (dx + dy) * k); INC(n)
    END
  END;
  P.Polygon(p, n, st)
END Milestone;

(* Task i's bar's fill and outline, 0RRGGBBH or -1 for none *)
PROCEDURE BarColours*(i: INTEGER; VAR fill, line: LONGINT);
  VAR task: GL.Tasks;
BEGIN
  task := l.task;
  IF l.colour[i] >= Styled THEN fill := 0; line := -1
  ELSIF task[i].active & task[i].crit THEN fill := t.activeFill; line := t.critLine
  ELSIF task[i].active THEN fill := t.activeFill; line := t.activeLine
  ELSIF task[i].done & task[i].crit THEN fill := t.doneFill; line := t.critLine
  ELSIF task[i].done THEN fill := t.doneFill; line := t.doneLine
  ELSIF task[i].crit THEN fill := t.critFill; line := t.critLine
  ELSE fill := t.taskFill; line := t.taskLine
  END;
  IF task[i].vert THEN line := t.vert END
END BarColours;

(* Task i's bar's style *)
PROCEDURE BarStyle(i: INTEGER; VAR st: Style);
  VAR fill, line: LONGINT;
BEGIN
  BarColours(i, fill, line); Make(st, fill, line, LineW)
END BarStyle;

(* Task i's text's colour, as Mermaid's styles choose it, the text at
   place *)
PROCEDURE PlacedColour*(i, place: INTEGER): LONGINT;
  VAR styled, outside: BOOLEAN; task: GL.Tasks;
BEGIN
  task := l.task;
  styled := l.colour[i] < Styled;
  outside := (place = GL.OutsideLeft) OR (place = GL.OutsideRight);
  IF place = GL.VertText THEN RETURN t.vert
  ELSIF task[i].done & outside & styled THEN RETURN t.outsideText
  ELSIF task[i].clickable THEN RETURN t.linkText
  ELSIF (task[i].active OR task[i].done) & styled THEN RETURN t.darkText
  ELSIF outside & styled THEN RETURN t.outsideText
  ELSIF outside THEN RETURN t.darkText
  ELSIF styled THEN RETURN t.taskText
  END;
  RETURN 0
END PlacedColour;

(* Task i's text's colour, at its place *)
PROCEDURE TextColour*(i: INTEGER): LONGINT;
BEGIN
  RETURN PlacedColour(i, l.place[i])
END TextColour;

(* The row colour of colour number c, as drawn over back *)
PROCEDURE RowColour*(c: INTEGER; back: LONGINT): LONGINT;
  VAR a: REAL;
BEGIN
  IF c >= Styled THEN RETURN Over(0, RowOpacity, back) END;
  a := RowOpacity;
  IF c = 0 THEN a := a * t.sectionAlpha END;
  IF t.section[c] < 0 THEN RETURN -1 END;
  RETURN Over(t.section[c], a, back)
END RowColour;

(* The excluded days and the rows, each piece of a row over an excluded
   range in the colour of both *)
PROCEDURE Background;
  VAR k, e: INTEGER; st: Style; y1, y2: REAL; c: LONGINT;
BEGIN
  FOR e := 0 TO l.nEx - 1 DO
    Make(st, t.exclude, -1, 0); Box(l.exX[e], l.exY, l.exW[e], l.exH, 0, st)
  END;
  FOR k := 0 TO l.nRows - 1 DO
    c := RowColour(l.rowColour[k], 0FFFFFFH);
    Make(st, c, -1, 0); Box(0, l.rowY[k], l.rowW, l.rowH, 0, st);
    IF t.exclude >= 0 THEN
      y1 := l.rowY[k]; y2 := y1 + l.rowH;
      IF y1 < l.exY THEN y1 := l.exY END;
      IF y2 > l.exY + l.exH THEN y2 := l.exY + l.exH END;
      IF (y2 > y1) & (c >= 0) THEN
        Make(st, RowColour(l.rowColour[k], t.exclude), -1, 0);
        FOR e := 0 TO l.nEx - 1 DO
          IF l.exX[e] < l.rowW THEN Box(l.exX[e], y1, l.exW[e], y2 - y1, 0, st) END
        END
      END
    END
  END
END Background;

(* s with runs of blanks made one space, and none at either end, as
   SVG shows text *)
PROCEDURE Collapsed*(s: L.Str): L.Str;
  VAR r: L.Str; i, j: LONGINT;
BEGIN
  NEW(r, L.Length(s^) + 1); i := 0; j := 0;
  WHILE s[i] # 0X DO
    IF L.IsBlank(s[i]) THEN
      WHILE L.IsBlank(s[i]) DO INC(i) END;
      IF (j > 0) & (s[i] # 0X) THEN r[j] := " "; INC(j) END
    ELSE r[j] := s[i]; INC(i); INC(j)
    END
  END;
  r[j] := 0X;
  RETURN r
END Collapsed;

(* The grid: its lines and their labels *)
PROCEDURE Grid;
  VAR k: INTEGER; st: Style; text: INTEGER; lab: F.Label;
BEGIN
  Make(st, -1, Over(t.grid, GridOpacity, 0FFFFFFH), GridW);
  IF t.text < 0 THEN text := NoColour ELSE text := C(Over(t.text, GridOpacity, 0FFFFFFH)) END;
  FOR k := 0 TO l.nTicks - 1 DO
    lab := F.PlainLabel(Collapsed(l.tickLabel[k]));
    Line(l.tickX[k], l.gridY1, l.tickX[k], l.gridY2, st);
    P.Anchored(lab, l.tickX[k], l.labelY, text, l.tickSize, P.Centre);
    IF l.topAxis THEN
      Line(l.tickX[k], l.topY1, l.tickX[k], l.topY2, st);
      P.Anchored(lab, l.tickX[k], l.topLabelY, text, l.tickSize, P.Centre)
    END
  END
END Grid;

(* The tasks' bars, then their text *)
PROCEDURE Tasks;
  VAR i, anchor: INTEGER; st: Style;
BEGIN
  FOR i := 0 TO l.nTasks - 1 DO
    BarStyle(i, st);
    IF l.task[i].milestone & ~l.task[i].vert THEN
      Milestone(l.bx[i], l.by[i], l.bw[i], l.bh[i], l.radius, st)
    ELSE Box(l.bx[i], l.by[i], l.bw[i], l.bh[i], l.radius, st)
    END
  END;
  FOR i := 0 TO l.nTasks - 1 DO
    CASE l.place[i] OF
      GL.OutsideRight: anchor := P.Left
    | GL.OutsideLeft: anchor := P.Right
    ELSE anchor := P.Centre
    END;
    P.Anchored(l.text[i], l.tx[i], l.ty[i], C(TextColour(i)), l.tsize[i], anchor)
  END
END Tasks;

(* The section names *)
PROCEDURE Sections;
  VAR k: INTEGER; c: LONGINT;
BEGIN
  FOR k := 0 TO l.nSections - 1 DO
    IF (l.secColour[k] >= 0) & (l.secColour[k] < Styled) THEN c := t.title ELSE c := 0 END;
    P.Anchored(l.secText[k], l.secX, l.secY[k], C(c), l.secSize, P.Left)
  END
END Sections;

(* The today line, in todayMarker's style *)
PROCEDURE Today;
BEGIN
  IF l.today THEN Line(l.todayX, l.todayY1, l.todayX, l.todayY2, todaySt) END
END Today;

(* The today line's style: todayMarker's over Mermaid's *)
PROCEDURE TodayStyle*(VAR st: Style);
BEGIN
  Make(st, -1, t.today, TodayW);
  IF (l.todayStyle # NIL) & (l.todayStyle[0] # 0X) THEN S.Apply(st, F.Props(l.todayStyle)) END
END TodayStyle;

(* Adds the colours the drawing uses to PmStyle's table, so that
   PmPic.Begin defines them all; and makes the today line's style *)
PROCEDURE Colours;
  VAR i, k: INTEGER; st: Style; c: LONGINT;
BEGIN
  IF l.nEx > 0 THEN c := C(t.exclude) END;
  FOR k := 0 TO l.nRows - 1 DO
    c := C(RowColour(l.rowColour[k], 0FFFFFFH));
    IF (l.nEx > 0) & (t.exclude >= 0) THEN c := C(RowColour(l.rowColour[k], t.exclude)) END
  END;
  IF l.nTicks > 0 THEN
    c := C(Over(t.grid, GridOpacity, 0FFFFFFH));
    IF t.text >= 0 THEN c := C(Over(t.text, GridOpacity, 0FFFFFFH)) END
  END;
  FOR i := 0 TO l.nTasks - 1 DO BarStyle(i, st); c := C(TextColour(i)) END;
  FOR k := 0 TO l.nSections - 1 DO
    IF (l.secColour[k] >= 0) & (l.secColour[k] < Styled) THEN c := C(t.title) ELSE c := C(0) END
  END;
  IF l.today THEN TodayStyle(todaySt) END;
  IF l.title # NIL THEN c := C(t.title) END
END Colours;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: GL.Layout): REAL;
BEGIN
  RETURN LineW * lay.px
END Widest;

(* Makes lay the chart the procedures above draw or colour, and t its
   colours *)
PROCEDURE Use*(lay: GL.Layout);
BEGIN
  l := lay; px := l.px;
  S.Reset(l.d.g, px); S.GanttColours(t)
END Use;

(* Writes lay's Gantt chart in pic, its labels in the groff font font *)
PROCEDURE Write*(lay: GL.Layout; font: ARRAY OF CHAR);
BEGIN
  Use(lay);
  P.Setup(font, l.font, px);
  Colours;
  P.Begin(l.size, l.size * 1.2);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(l.width); P.W(" ht "); P.In(l.height);
  P.At(l.width / 2, l.height / 2); PmIO.WriteLn;
  Background; Grid; Tasks; Sections; Today;
  IF l.title # NIL THEN
    P.Anchored(l.title, l.titleX, l.titleY, C(t.title), l.titleSize, P.Centre)
  END;
  P.End
END Write;

END PmGanttPic.
