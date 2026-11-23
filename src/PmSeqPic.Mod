MODULE PmSeqPic;
(* PmSeqPic: a laid out sequence diagram, PmSeqLayout's, written in
   pic, for groff, with PmPic's helpers: the same colours, text and
   picture as a flowchart's.

   The drawing, from the back: the boxes round participants, the rects,
   the lifelines, the activation bars, the blocks' frames, the
   messages with their numbers, the notes, the participants at the top
   and, drawn again, at the bottom, a cross where one is destroyed, and
   the title. The colours are Mermaid's default theme's for sequence
   diagrams, changed by its themeVariables (PmStyle.SeqColours).

   The participants' icons, the arrowheads and the frames' labels are
   drawn after Mermaid's, not as its (decision 2): an actor as a stick
   figure, a boundary, a control and an entity as their UML symbols, a
   database as a cylinder, a queue as one on its side, collections as
   two boxes; a message to itself as three straight lines. *)

IMPORT Math, PmIO, F := PmFlow, G := PmGeom, S := PmStyle, P := PmPic,
  Q := PmSeq, SL := PmSeqLayout;

CONST
  NoColour = S.NoColour;
  Samples = 12;         (* the points of a quarter of an ellipse *)
  BoxLine = 0808080H;   (* a box's outline: Mermaid's black at half opacity *)

TYPE
  Style = S.Style;

VAR
  l: SL.Layout;
  px: REAL;
  t: S.SeqTheme;
  actor, lifeline, signal, label, frame, note, bar, number, plain: Style;
  actorText, signalText, labelText, loopText, noteText, numberText,
  titleColour: INTEGER;

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

(* Drawing *)

(* A box from (x1, y1) to (x2, y2), its corners rounded rad points *)
PROCEDURE Box(x1, y1, x2, y2, rad: REAL; VAR st: Style);
BEGIN
  P.W("box wid "); P.In(x2 - x1); P.W(" ht "); P.In(y2 - y1);
  P.At((x1 + x2) / 2, (y1 + y2) / 2);
  IF rad > 0 THEN P.W(" rad "); P.In(rad) END;
  P.Paint(st, TRUE); PmIO.WriteLn
END Box;

PROCEDURE Line(x1, y1, x2, y2: REAL; VAR st: Style);
BEGIN
  IF st.line = NoColour THEN RETURN END;
  P.W("line from "); P.Pt(x1, y1); P.W(" to "); P.Pt(x2, y2);
  P.Paint(st, FALSE); PmIO.WriteLn
END Line;

(* The open path p[0 .. n-1] *)
PROCEDURE Path(VAR p: ARRAY OF G.Point; n: INTEGER; VAR st: Style);
  VAR k: INTEGER;
BEGIN
  IF (st.line = NoColour) OR (n < 2) THEN RETURN END;
  P.W("line from "); P.Pt(p[0].x, p[0].y);
  FOR k := 1 TO n - 1 DO
    IF k MOD 4 = 0 THEN P.W(" \"); PmIO.WriteLn; P.W(" ") END;
    P.W(" to "); P.Pt(p[k].x, p[k].y)
  END;
  P.Paint(st, FALSE); PmIO.WriteLn
END Path;

PROCEDURE Circle(x, y, r: REAL; VAR st: Style);
BEGIN
  P.W("circle rad "); P.In(r); P.At(x, y); P.Paint(st, TRUE); PmIO.WriteLn
END Circle;

(* Adds to p, at p[n], the points of the arc of the ellipse about (cx,
   cy), radii rx and ry, from angle a to angle b, in quarter turns,
   y down *)
PROCEDURE Arc(VAR p: ARRAY OF G.Point; VAR n: INTEGER; cx, cy, rx, ry: REAL; a, b: INTEGER);
  VAR k, steps: INTEGER; u: REAL;
BEGIN
  steps := ABS(b - a) * Samples;
  FOR k := 0 TO steps DO
    u := (a + (b - a) * k / steps) * 1.5707963;
    G.Set(p[n], cx + rx * Math.cos(u), cy - ry * Math.sin(u)); INC(n)
  END
END Arc;

(* A participant of type type, its box (or icon) from x - w/2 to x + w/2
   and y to y + l.h *)
PROCEDURE Shape(type: INTEGER; x, w, y: REAL);
  VAR p: G.Points; n: INTEGER; h, rx, ry, r, cy, x1, x2: REAL; fig: Style;
BEGIN
  h := l.h; x1 := x - w / 2; x2 := x + w / 2;
  fig := actor; fig.width := 1.5 * px;
  CASE type OF
  | Q.Person:
    r := 7 * px; cy := y + r;
    Circle(x, cy, r, fig);
    Line(x, cy + r, x, y + 28 * px, fig);
    Line(x - 12 * px, y + 19 * px, x + 12 * px, y + 19 * px, fig);
    Line(x, y + 28 * px, x - 10 * px, y + SL.IconH * px, fig);
    Line(x, y + 28 * px, x + 10 * px, y + SL.IconH * px, fig)
  | Q.Boundary:
    r := 14 * px; cy := y + SL.IconH * px / 2;
    Line(x - 22 * px, cy - r, x - 22 * px, cy + r, fig);
    Line(x - 22 * px, cy, x + 4 * px - r, cy, fig);
    Circle(x + 4 * px, cy, r, fig)
  | Q.Control:
    r := 14 * px; cy := y + SL.IconH * px / 2 + 3 * px;
    Circle(x, cy, r, fig);
    Line(x + 2 * px, cy - r, x + 8 * px, cy - r - 5 * px, fig);
    Line(x + 2 * px, cy - r, x + 8 * px, cy - r + 5 * px, fig)
  | Q.Entity:
    r := 14 * px; cy := y + r + 4 * px;
    Circle(x, cy, r, fig);
    Line(x - r, cy + r + 4 * px, x + r, cy + r + 4 * px, fig)
  | Q.Database:
    ry := 8 * px; IF ry > h / 6 THEN ry := h / 6 END;
    p := G.NewPoints(4 * Samples + 4); n := 0;
    Arc(p^, n, x, y + ry, w / 2, ry, 0, 2);      (* the top's back *)
    Arc(p^, n, x, y + h - ry, w / 2, ry, 2, 4);  (* the bottom *)
    P.Polygon(p^, n, actor);
    n := 0; Arc(p^, n, x, y + ry, w / 2, ry, 4, 2);  (* the top's front *)
    Path(p^, n, actor)
  | Q.Queue:
    rx := 8 * px; IF rx > w / 8 THEN rx := w / 8 END;
    p := G.NewPoints(4 * Samples + 4); n := 0;
    Arc(p^, n, x2 - rx, y + h / 2, rx, h / 2, -1, 1);  (* the right end *)
    Arc(p^, n, x1 + rx, y + h / 2, rx, h / 2, 1, 3);   (* the left end *)
    P.Polygon(p^, n, actor);
    n := 0; Arc(p^, n, x2 - rx, y + h / 2, rx, h / 2, 1, 3);  (* the right end's back *)
    Path(p^, n, actor)
  | Q.Collections:
    Box(x1 + 6 * px, y, x2, y + h - 6 * px, 0, actor);
    Box(x1, y + 6 * px, x2 - 6 * px, y + h, 0, actor)
  ELSE
    Box(x1, y, x2, y + h, 3 * px, actor)
  END
END Shape;

(* Participant i, its top at y *)
PROCEDURE Participant(i: INTEGER; y: REAL);
BEGIN
  Shape(l.actors[i].type, l.x[i], l.w[i], y);
  P.Lines(l.actors[i].label, l.x[i], y + l.ly[i] - l.top[i], actorText, 0, FALSE)
END Participant;

(* A message's end of kind kind at (x, y), reached going in the
   direction (ux, uy) *)
PROCEDURE Head(kind: INTEGER; x, y, ux, uy: REAL);
  VAR p: ARRAY 4 OF G.Point; sx, sy, cx, cy: REAL; st: Style;

  PROCEDURE Pt(i: INTEGER; along, side: REAL);  (* along back, side across *)
  BEGIN
    G.Set(p[i], x - ux * along * px + sx * side * px, y - uy * along * px + sy * side * px)
  END Pt;

BEGIN
  sx := uy; sy := -ux;     (* the upper side, going right *)
  st := signal; st.dash := 0; st.fill := st.line; st.line := NoColour;
  CASE kind OF
  | Q.Filled:
    Pt(0, 0, 0); Pt(1, 10, 5); Pt(2, 10, -5); P.Polygon(p, 3, st)
  | Q.Open:
    Pt(0, 0, 0); Pt(1, 10, 6); Pt(2, 5, 0); Pt(3, 10, -6); P.Polygon(p, 4, st)
  | Q.SolidTop:
    Pt(0, 0, 0); Pt(1, 10, 8); Pt(2, 10, 0); P.Polygon(p, 3, st)
  | Q.SolidBottom:
    Pt(0, 0, 0); Pt(1, 10, -8); Pt(2, 10, 0); P.Polygon(p, 3, st)
  | Q.StickTop:
    Pt(0, 0, 0); Pt(1, 7, 7); st := signal; st.dash := 0; Line(p[0].x, p[0].y, p[1].x, p[1].y, st)
  | Q.StickBottom:
    Pt(0, 0, 0); Pt(1, 7, -7); st := signal; st.dash := 0; Line(p[0].x, p[0].y, p[1].x, p[1].y, st)
  | Q.Cross:
    st := signal; st.dash := 0;
    Pt(0, 8, 4); Pt(1, 0, -4); Line(p[0].x, p[0].y, p[1].x, p[1].y, st);
    Pt(0, 8, -4); Pt(1, 0, 4); Line(p[0].x, p[0].y, p[1].x, p[1].y, st)
  ELSE
  END
END Head;

(* The direction (ux, uy) from (x1, y1) to (x2, y2), of length 1 *)
PROCEDURE Direction(x1, y1, x2, y2: REAL; VAR ux, uy: REAL);
BEGIN
  ux := 0; uy := 0;
  IF x2 > x1 THEN ux := 1 ELSIF x2 < x1 THEN ux := -1 ELSIF y2 > y1 THEN uy := 1 ELSIF y2 < y1 THEN uy := -1 END
END Direction;

PROCEDURE Message(e: Q.Event);
  VAR g: SL.Geom; p: ARRAY 4 OF G.Point; st, dot: Style; ux, uy, ex, ey: REAL;
BEGIN
  g := l.geom[e.index]; st := signal;
  IF e.dotted THEN st.dash := 3 * px END;
  G.Set(p[0], g.x1, g.y1);
  IF g.self THEN
    G.Set(p[1], g.x2, g.y1); G.Set(p[2], g.x2, g.y2); G.Set(p[3], g.x3, g.y2);
    Path(p, 4, st);
    ex := g.x3; ey := g.y2;
    Head(e.head, g.x3, g.y2, -1, 0); Head(e.tail, g.x1, g.y1, -1, 0)
  ELSE
    Line(g.x1, g.y1, g.x2, g.y2, st);
    ex := g.x2; ey := g.y2;
    Direction(g.x1, g.y1, g.x2, g.y2, ux, uy);
    Head(e.head, g.x2, g.y2, ux, uy); Head(e.tail, g.x1, g.y1, -ux, -uy)
  END;
  dot := signal; dot.dash := 0; dot.fill := dot.line;
  IF Q.CentralTo IN e.central THEN Circle(ex, ey, 5 * px, dot) END;
  IF Q.CentralFrom IN e.central THEN Circle(g.x1, g.y1, 5 * px, dot) END;
  IF e.text # NIL THEN P.Lines(e.text, g.tx, g.ty, signalText, 0, FALSE) END;
  IF e.number # NIL THEN
    Circle(g.x1, g.y1, SL.NumR * px, number);
    P.Lines(F.PlainLabel(e.number), g.x1, g.y1, numberText, SL.NumSize * px, FALSE)
  END
END Message;

PROCEDURE Note(e: Q.Event);
  VAR g: SL.Geom;
BEGIN
  g := l.geom[e.index];
  Box(g.x1, g.y1, g.x2, g.y2, 0, note);
  P.Lines(e.text, g.tx, g.ty, noteText, 0, FALSE)
END Note;

PROCEDURE Frame(f: SL.Frame);
  VAR p: ARRAY 5 OF G.Point; s: SL.Section;
BEGIN
  Box(f.x1, f.y1, f.x2, f.y2, 0, frame);
  G.Set(p[0], f.x1, f.y1); G.Set(p[1], f.x1 + f.lw, f.y1);
  G.Set(p[2], f.x1 + f.lw, f.y1 + f.lh - 7 * px);
  G.Set(p[3], f.x1 + f.lw - 8.4 * px, f.y1 + f.lh); G.Set(p[4], f.x1, f.y1 + f.lh);
  P.Polygon(p, 5, label);
  P.Lines(f.label, f.x1 + f.lw / 2, f.y1 + f.lh / 2, labelText, 0, FALSE);
  IF f.text # NIL THEN P.Lines(f.text, f.tx, f.ty, loopText, 0, FALSE) END;
  s := f.sections;
  WHILE s # NIL DO
    Line(f.x1, s.y, f.x2, s.y, frame);
    IF s.text # NIL THEN P.Lines(s.text, s.tx, s.ty, loopText, 0, FALSE) END;
    s := s.next
  END
END Frame;

(* Styles *)

(* The styles, each colour added to PmStyle's table; the rects' and
   boxes' too, so that P.Begin defines them all *)
PROCEDURE Styles;
  VAR f: SL.Frame; k, c: INTEGER;
BEGIN
  S.Reset(l.d.g, px); S.SeqColours(t);
  Make(actor, t.actorFill, t.actorLine, 1, 0);
  Make(lifeline, -1, t.lifeline, 0.5, 0);
  Make(signal, -1, t.signal, 1.5, 0);
  Make(label, t.labelFill, t.labelLine, 1, 0);
  Make(frame, -1, t.labelLine, 2, 2);
  Make(note, t.noteFill, t.noteLine, 1, 0);
  Make(bar, t.barFill, t.barLine, 1, 0);
  Make(number, t.number, -1, 0, 0);
  Make(plain, -1, BoxLine, 1, 0);
  actorText := C(t.actorText); signalText := C(t.signalText);
  labelText := C(t.labelText); loopText := C(t.loopText);
  noteText := C(t.noteText); numberText := C(t.numberText);
  titleColour := C(t.title);
  f := l.frames;
  WHILE f # NIL DO
    IF (f.kind = Q.Rect) & (f.fill # Q.NoColour) THEN c := C(f.fill) END;
    f := f.next
  END;
  FOR k := 0 TO l.d.nBoxes - 1 DO
    IF l.boxes[k].fill # Q.NoColour THEN c := C(l.boxes[k].fill) END
  END
END Styles;

(* The width of the widest line Write draws for lay, in points *)
PROCEDURE Widest*(lay: SL.Layout): REAL;
BEGIN
  RETURN 2 * lay.px
END Widest;

(* Writes lay's sequence diagram in pic, its labels in the groff font
   font *)
PROCEDURE Write*(lay: SL.Layout; font: ARRAY OF CHAR);
  VAR i, k: INTEGER; e: Q.Event; f: SL.Frame; b: SL.Bar; st: Style; cy, x, y, r: REAL;
BEGIN
  l := lay; px := l.px;
  P.Setup(font, l.font, px);
  Styles;
  P.Begin(l.size, l.vs);
  (* the boxes round participants *)
  FOR k := 0 TO l.d.nBoxes - 1 DO
    st := plain; st.fill := C(l.boxes[k].fill);
    Box(l.bx1[k], l.by1[k], l.bx2[k], l.by2[k], 0, st);
    IF l.boxes[k].title # NIL THEN P.Lines(l.boxes[k].title, l.btx[k], l.bty[k], actorText, 0, FALSE) END
  END;
  (* the rects *)
  f := l.frames;
  WHILE f # NIL DO
    IF f.kind = Q.Rect THEN
      Make(st, f.fill, -1, 0, 0); Box(f.x1, f.y1, f.x2, f.y2, 0, st)
    END;
    f := f.next
  END;
  FOR i := 0 TO l.d.nActors - 1 DO Line(l.x[i], l.life1[i], l.x[i], l.life2[i], lifeline) END;
  b := l.bars;
  WHILE b # NIL DO Box(b.x1, b.y1, b.x2, b.y2, 0, bar); b := b.next END;
  f := l.frames;
  WHILE f # NIL DO
    IF f.kind # Q.Rect THEN Frame(f) END;
    f := f.next
  END;
  e := l.d.events;
  WHILE e # NIL DO
    IF e.kind = Q.Msg THEN Message(e) ELSIF e.kind = Q.Note THEN Note(e) END;
    e := e.next
  END;
  FOR i := 0 TO l.d.nActors - 1 DO
    Participant(i, l.top[i]);
    IF l.footer[i] THEN Participant(i, l.foot[i]) END;
    IF l.actors[i].destroyed # NIL THEN
      x := l.x[i]; y := l.life2[i]; r := 9 * px; st := actor; st.width := 2 * px;
      Line(x - r, y - r, x + r, y + r, st); Line(x - r, y + r, x + r, y - r, st)
    END
  END;
  IF (l.title # NIL) & (l.title.n > 0) THEN
    cy := l.titleY - 0.3 * l.titleSize;
    P.W("box invis wid "); P.In(l.titleW); P.W(" ht "); P.In(l.titleH); P.At(l.titleX, cy);
    PmIO.WriteLn;
    P.Lines(l.title, l.titleX, cy, titleColour, l.titleSize, FALSE)
  END;
  P.End
END Write;

END PmSeqPic.
