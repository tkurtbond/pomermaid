MODULE PmJourneyPic;
(* PmJourneyPic: a laid out user journey, PmJourneyLayout's, written in
   pic, for groff, with PmPic's helpers.

   The drawing, as Mermaid's svgDraw.js draws it, from the back: the
   legend, the sections' boxes, then for each task its dashed line, its
   face, its box with its text and the circles of the people in it; then
   the activity line, an arrow, and the title. The colours are Mermaid's
   (PmStyle.JourneyColours): each section and its tasks in the fill of
   the section's number, 0 to 6, round again after 7. *)

IMPORT Math, PmIO, G := PmGeom, S := PmStyle, P := PmPic,
  J := PmJourney, JL := PmJourneyLayout;

CONST
  NoColour = S.NoColour;
  Samples = 12;         (* the points of a quarter of a circle *)
  Black = 0;

TYPE
  Style = S.Style;

VAR
  l: JL.Layout;
  px: REAL;
  t: S.JourneyTheme;
  boxes: ARRAY 8 OF Style;
  legend, person, face, eye, mouth, taskLine, activity: Style;
  text, boxText, titleColour: INTEGER;

(* The index of the colour rgb, or NoColour for -1 *)
PROCEDURE C(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN NoColour ELSE RETURN S.Colour(rgb) END
END C;

(* st: filled with fill, its line line, width pixels wide, dashes of
   dash pixels *)
PROCEDURE Make(VAR st: Style; fill, line: LONGINT; width, dash: REAL);
BEGIN
  st.fill := C(fill); st.line := C(line); st.text := NoColour; st.inner := NoColour;
  st.width := width * px; st.dash := dash * px
END Make;

(* A box, its top left corner at (x, y), w by h, its corners rounded
   rad points *)
PROCEDURE Box(x, y, w, h, rad: REAL; VAR st: Style);
BEGIN
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

PROCEDURE Circle(x, y, r: REAL; VAR st: Style);
BEGIN
  P.W("circle rad "); P.In(r); P.At(x, y); P.Paint(st, TRUE); PmIO.WriteLn
END Circle;

(* Half a circle about (cx, cy), radius r, from angle a to a + 2
   quarter turns, y down *)
PROCEDURE HalfCircle(cx, cy, r: REAL; a: INTEGER; VAR st: Style);
  VAR k: INTEGER; u: REAL;
BEGIN
  P.W("line from ");
  FOR k := 0 TO 2 * Samples DO
    u := (a + k / Samples) * 1.5707963;
    IF k > 0 THEN
      IF k MOD 4 = 0 THEN P.W(" \"); PmIO.WriteLn; P.W(" ") END;
      P.W(" to ")
    END;
    P.Pt(cx + r * Math.cos(u), cy - r * Math.sin(u))
  END;
  P.Paint(st, FALSE); PmIO.WriteLn
END HalfCircle;

(* A face for score score, centred at (x, y) *)
PROCEDURE Face(x, y, score: REAL);
BEGIN
  Circle(x, y, JL.FaceR * px, face);
  Circle(x - 5 * px, y - 5 * px, 2.5 * px, eye);
  Circle(x + 5 * px, y - 5 * px, 2.5 * px, eye);
  IF score > 3 THEN HalfCircle(x, y + 2 * px, 7 * px, 2, mouth)
  ELSIF score < 3 THEN HalfCircle(x, y + 7 * px, 7 * px, 0, mouth)
  ELSE Line(x - 5 * px, y + 7 * px, x + 5 * px, y + 7 * px, mouth)
  END
END Face;

(* The fill of the boxes of task or section index num *)
PROCEDURE Num(s: J.Section): INTEGER;
BEGIN
  IF s = NIL THEN RETURN 0 ELSE RETURN s.index MOD 7 END
END Num;

(* The styles, each colour added to PmStyle's table *)
PROCEDURE Styles;
  VAR k: INTEGER;
BEGIN
  S.Reset(l.d.g, px); S.JourneyColours(t);
  FOR k := 0 TO 7 DO Make(boxes[k], t.fill[k], t.boxLine, 1, 0) END;
  Make(legend, Black, Black, 1, 0);
  Make(person, Black, Black, 1, 0);
  Make(face, t.face, t.faceLine, 2, 0);
  Make(eye, t.mouth, -1, 0, 0);
  Make(mouth, -1, t.mouth, 1.5, 0);
  Make(taskLine, -1, t.line, 1, 4);
  Make(activity, t.line, t.line, JL.ActivityW, 0);
  (* the actors' colours, so that P.Begin defines them *)
  FOR k := 0 TO l.d.nActors - 1 DO
    IF k < 6 THEN legend.fill := C(t.actor[k]) END
  END;
  text := C(t.text); boxText := C(t.boxText); titleColour := C(t.title)
END Styles;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: JL.Layout): REAL;
BEGIN
  RETURN JL.ActivityW * lay.px
END Widest;

(* Writes lay's user journey in pic, its labels in the groff font
   font *)
PROCEDURE Write*(lay: JL.Layout; font: ARRAY OF CHAR);
  VAR
    k, i: INTEGER; tk: J.Task; st: Style; x, y, a: REAL;
    p: ARRAY 3 OF G.Point;
BEGIN
  l := lay; px := l.px;
  P.Setup(font, l.font, px);
  Styles;
  P.Begin(l.size, l.vs);
  (* the whole drawing, so that its margins are in the picture *)
  P.W("box invis wid "); P.In(l.width); P.W(" ht "); P.In(l.height);
  P.At(l.width / 2, l.height / 2); PmIO.WriteLn;
  (* the legend *)
  FOR k := 0 TO l.d.nActors - 1 DO
    st := legend; st.fill := C(t.actor[k MOD 6]);
    Circle(l.cx[k], l.cy[k], JL.LegendR * px, st);
    P.Lines(l.names[k], l.nx[k], l.ny[k], text, 0, TRUE)
  END;
  (* the sections *)
  FOR k := 0 TO l.d.nSections - 1 DO
    Box(l.sx[k], l.sy[k], l.sw[k], l.sh[k], 3 * px, boxes[Num(l.sections[k])]);
    P.Lines(l.stext[k], l.sx[k] + l.sw[k] / 2, l.sy[k] + l.sh[k] / 2, boxText, 0, FALSE)
  END;
  (* the tasks *)
  FOR k := 0 TO l.d.nTasks - 1 DO
    tk := l.tasks[k];
    Line(l.fx[k], l.lineY1, l.fx[k], l.lineY2, taskLine);
    Face(l.fx[k], l.fy[k], tk.score);
    Box(l.tx[k], l.ty[k], l.tw[k], l.th[k], 3 * px, boxes[Num(tk.section)]);
    P.Lines(l.ttext[k], l.tx[k] + l.tw[k] / 2, l.ty[k] + l.th[k] / 2, boxText, 0, FALSE);
    x := l.tx[k] + 14 * px;
    FOR i := 0 TO tk.nPeople - 1 DO
      st := person; st.fill := C(t.actor[tk.people[i] MOD 6]);
      Circle(x, l.ty[k], JL.LegendR * px, st);
      x := x + 10 * px
    END
  END;
  (* the activity line *)
  a := 6 * JL.ActivityW * px;
  Line(l.ax1, l.ay, l.ax2 - a, l.ay, activity);
  G.Set(p[0], l.ax2 - a, l.ay - a / 3); G.Set(p[1], l.ax2, l.ay);
  G.Set(p[2], l.ax2 - a, l.ay + a / 3);
  st := activity; st.width := px;
  P.Polygon(p, 3, st);
  IF l.title # NIL THEN
    y := l.titleY;
    P.W("box invis wid "); P.In(l.titleW); P.W(" ht "); P.In(l.titleH);
    P.At(l.titleX + l.titleW / 2, y); PmIO.WriteLn;
    P.Lines(l.title, l.titleX, y, titleColour, l.titleSize, TRUE)
  END;
  P.End
END Write;

END PmJourneyPic.
