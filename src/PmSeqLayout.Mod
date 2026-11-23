MODULE PmSeqLayout;
(* PmSeqLayout: a sequence diagram, PmSeq's, laid out: the participants
   in a row, each with its lifeline down the page, and the events from
   the top down. Lengths are in points, y down; Mermaid's pixels are
   taken at the labels' size, 16 pixels to the size.

   Mermaid's lengths are followed where they are simple (an actor at
   least 150 pixels wide and 65 high, 50 pixels between actors,
   activation bars 10 pixels wide, nested 5 pixels apart), but not its
   layout (decision 2): every text is at the labels' size, and the
   columns are placed in one pass from the left, each actor as far
   left as these allow:

   - two neighbours: half of each one's width and 50 pixels, and 20
     more if they are in different boxes;
   - a message between two: its text's width and 30 pixels;
   - a message to itself: its text's width (at least 30 pixels) and 25
     pixels, to the next actor;
   - a note to the right or left of one: the note's width and 20
     pixels, to the next or the one before;
   - a note over one: half its width and 10 pixels to each side;
     over two, its width less 50 pixels between them.

   Then, from the top: the boxes' titles, the actors, and each event
   in turn, the room it takes below the one before. A block's frame
   spans what it holds, 10 pixels more on each side than the frame in
   it. Everything is moved right so the drawing starts at 0, and down
   for the title.

   PmSeqPic draws this layout; the MetaPost macros
   (mp/pomermaid-seq.mp) lay the diagram out again, in the same way,
   with ConTeXt's text sizes. A change here is made there too. *)

IMPORT F := PmFlow, M := PmMetrics, Lx := PmLex, Q := PmSeq;

CONST
  MermaidSize* = 16;
  (* in Mermaid's pixels *)
  ActorW = 150; ActorH = 65; ActorGap = 50; BoxGap = 20;
  Pad* = 10;          (* inside an actor, a note, a box, a frame *)
  IconH* = 40;        (* an actor drawn as an icon: the icon's height *)
  IconGap* = 5;       (* from the icon to its text *)
  MsgGap = 20; TextGap = 6; SelfW* = 30; SelfH* = 20; SelfMargin = 25;
  MsgMargin = 30;
  NoteGap = 10; NoteMargin = 10; NoteOver = 25;
  BlockGap = 10;
  LabelW* = 50; LabelH* = 20; (* a frame's label's box, at least *)
  SectionGap = 3;
  BarW* = 10; BarStep* = 5;
  EndGap = 20;
  NumR* = 9;          (* a sequence number's circle *)
  NumSize* = 12;      (* its text *)
  TitleSize = 18; TitleMargin = 25;

TYPE
  Reals* = POINTER TO ARRAY OF REAL;
  Flags* = POINTER TO ARRAY OF BOOLEAN;
  Labels* = POINTER TO ARRAY OF F.Label;

  (* Where an event is drawn. A message: its line from (x1, y1) to
     (x2, y2), or, to itself, out from (x1, y1) to x2 and back, at y2,
     to x3; its text centred at (tx, ty), tw by th; its number's
     circle at (x1, y1). A note: its box from (x1, y1) to (x2, y2), its
     text centred at (tx, ty). *)
  Geom* = RECORD
    x1*, y1*, x2*, y2*, x3*, tx*, ty*, tw*, th*: REAL;
    self*: BOOLEAN
  END;
  Geoms* = POINTER TO ARRAY OF Geom;

  (* A line across a frame, "else", "and" or "option", at y, its text
     ("[...]") centred at (tx, ty) *)
  Section* = POINTER TO SectionDesc;
  SectionDesc* = RECORD
    y*, tx*, ty*, tw*: REAL;
    text*: F.Label;
    next*: Section
  END;

  (* A block's frame, from (x1, y1) to (x2, y2); its kind's label in a
     box lw by lh at its top left corner, the label centred in it; its
     text ("[...]") centred at (tx, ty). A rect is filled, and has no
     label or text. *)
  Frame* = POINTER TO FrameDesc;
  FrameDesc* = RECORD
    kind*: INTEGER;     (* PmSeq's Loop ... *)
    fill*: LONGINT;     (* a rect's *)
    x1*, y1*, x2*, y2*: REAL;
    label*: F.Label; lw*, lh*: REAL;
    text*: F.Label; tx*, ty*, tw*: REAL;
    sections*: Section;
    depth*: INTEGER;    (* 0 for the outermost *)
    next*: Frame;       (* in the order they start *)
    parent: Frame; lastSection: Section;
    lo, hi: REAL; has: BOOLEAN  (* the extent of what it holds *)
  END;

  (* An activation bar of actor actor, from (x1, y1) to (x2, y2) *)
  Bar* = POINTER TO BarDesc;
  BarDesc* = RECORD
    actor*: INTEGER;
    x1*, y1*, x2*, y2*: REAL;
    next*: Bar;
    below: Bar          (* the one it is on, still open *)
  END;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: Q.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;   (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    (* the actors, by index: each one's centre x, its width, the top of
       its box, its label's size and centre, where its lifeline starts
       and ends, and whether it is drawn again at the bottom, its top
       at foot *)
    actors-: POINTER TO ARRAY OF Q.Actor;
    x-, w-, top-, tw-, th-, ly-, life1-, life2-, foot-: Reals;
    footer-: Flags;
    h-: REAL;                (* every actor's box's height *)
    (* the events, by index *)
    events-: POINTER TO ARRAY OF Q.Event;
    geom-: Geoms;
    frames-: Frame;
    bars-: Bar;
    (* the boxes, by index: from (bx1, by1) to (bx2, by2), the title
       centred at (btx, bty) *)
    boxes-: POINTER TO ARRAY OF Q.Box;
    bx1-, by1-, bx2-, by2-, btx-, bty-: Reals;
    title-: F.Label;
    titleSize-, titleW-, titleH-, titleX-, titleY-: REAL
  END;

VAR
  l: Layout;
  px: REAL;
  n: INTEGER;              (* actors *)
  gap: Reals;              (* gap[i * n + j], i < j: x[j] - x[i] at least *)
  open: Frame;             (* the innermost open frame *)
  lastFrame: Frame;
  lastBar: Bar;
  stack: POINTER TO ARRAY OF Bar; (* each actor's open bar, or NIL *)
  levels: POINTER TO ARRAY OF INTEGER; (* each actor's open bars *)
  minX, maxX: REAL;

PROCEDURE Max(a, b: REAL): REAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

PROCEDURE Min(a, b: REAL): REAL;
BEGIN
  IF a < b THEN RETURN a END;
  RETURN b
END Min;

PROCEDURE Size(lab: F.Label; VAR w, h: REAL);
BEGIN
  M.LabelSize(l.font, lab, l.size, l.vs, w, h)
END Size;

(* A copy of line's text with pre before it and post after it *)
PROCEDURE Wrapped(line: F.Line; pre, post: ARRAY OF CHAR): F.Line;
  VAR r: F.Line; a, b, c, i: LONGINT;
BEGIN
  NEW(r); r.underline := line.underline; r.next := NIL;
  a := Lx.Length(pre); b := Lx.Length(line.text^); c := Lx.Length(post);
  NEW(r.text, a + b + c + 1);
  FOR i := 0 TO a - 1 DO r.text[i] := pre[i] END;
  FOR i := 0 TO b - 1 DO r.text[a + i] := line.text[i] END;
  FOR i := 0 TO c - 1 DO r.text[a + b + i] := post[i] END;
  r.text[a + b + c] := 0X;
  IF line.style = NIL THEN r.style := NIL
  ELSE
    NEW(r.style, a + b + c + 1);
    FOR i := 0 TO a + b + c DO r.style[i] := F.Roman END;
    FOR i := 0 TO b - 1 DO r.style[a + i] := line.style[i] END
  END;
  RETURN r
END Wrapped;

(* lab in brackets, "[" before its first line and "]" after its last,
   as Mermaid writes a block's and a section's text; NIL for NIL *)
PROCEDURE Bracketed*(lab: F.Label): F.Label;
  VAR r: F.Label; line, last, nl: F.Line;
BEGIN
  IF (lab = NIL) OR (lab.n = 0) THEN RETURN NIL END;
  NEW(r); r.n := lab.n; r.markdown := lab.markdown; r.lines := NIL; last := NIL;
  line := lab.lines;
  WHILE line # NIL DO
    IF (line = lab.lines) & (line.next = NIL) THEN nl := Wrapped(line, "[", "]")
    ELSIF line = lab.lines THEN nl := Wrapped(line, "[", "")
    ELSIF line.next = NIL THEN nl := Wrapped(line, "", "]")
    ELSE nl := Wrapped(line, "", "")
    END;
    IF last = NIL THEN r.lines := nl ELSE last.next := nl END;
    last := nl; line := line.next
  END;
  RETURN r
END Bracketed;

(* A block's kind as its frame's label, in bold; NIL for a rect *)
PROCEDURE KindLabel*(kind: INTEGER): F.Label;
  VAR s: ARRAY 16 OF CHAR; lab: F.Label; i: LONGINT;
BEGIN
  CASE kind OF
    Q.Loop: s := "loop"
  | Q.Opt: s := "opt"
  | Q.Alt: s := "alt"
  | Q.Par, Q.ParOver: s := "par"
  | Q.Critical: s := "critical"
  | Q.Break: s := "break"
  | Q.Rect: RETURN NIL
  END;
  lab := F.PlainLabel(Lx.New(s));
  NEW(lab.lines.style, Lx.Length(s) + 1);
  FOR i := 0 TO Lx.Length(s) DO lab.lines.style[i] := F.Bold END;
  RETURN lab
END KindLabel;

(* Whether actors of type t are drawn as an icon over their text *)
PROCEDURE IsIcon*(t: INTEGER): BOOLEAN;
BEGIN
  RETURN (t = Q.Person) OR (t = Q.Boundary) OR (t = Q.Control) OR (t = Q.Entity)
END IsIcon;

PROCEDURE Ext(a, b: REAL);
BEGIN
  IF a < minX THEN minX := a END;
  IF b > maxX THEN maxX := b END
END Ext;

(* What the innermost open frame holds spans a .. b *)
PROCEDURE Holds(a, b: REAL);
BEGIN
  Ext(a, b);
  IF open # NIL THEN
    IF ~open.has THEN open.lo := a; open.hi := b; open.has := TRUE
    ELSE open.lo := Min(open.lo, a); open.hi := Max(open.hi, b)
    END
  END
END Holds;

PROCEDURE Need(i, j: INTEGER; v: REAL);
  VAR t: INTEGER;
BEGIN
  IF i > j THEN t := i; i := j; j := t END;
  IF (i # j) & (v > gap[i * n + j]) THEN gap[i * n + j] := v END
END Need;

(* The columns: the constraints, then each x as far left as they allow *)
PROCEDURE Columns;
  VAR e: Q.Event; i, j: INTEGER; tw, th, v: REAL; a: Q.Actor; bw: Reals; alone: BOOLEAN;
BEGIN
  NEW(gap, n * n + 1);
  FOR i := 0 TO n * n - 1 DO gap[i] := 0 END;
  (* a box of one actor is as wide as its title *)
  NEW(bw, n + 1);
  FOR i := 0 TO n - 1 DO bw[i] := l.w[i] END;
  FOR i := 0 TO n - 1 DO
    a := l.actors[i];
    IF (a.box # NIL) & (a.box.title # NIL) THEN
      alone := TRUE;
      FOR j := 0 TO n - 1 DO
        IF (j # i) & (l.actors[j].box = a.box) THEN alone := FALSE END
      END;
      Size(a.box.title, tw, th);
      IF alone THEN bw[i] := Max(bw[i], tw) END
    END
  END;
  FOR i := 0 TO n - 2 DO
    v := (bw[i] + bw[i + 1]) / 2 + ActorGap * px;
    IF l.actors[i].box # l.actors[i + 1].box THEN v := v + BoxGap * px END;
    Need(i, i + 1, v)
  END;
  e := l.d.events;
  WHILE e # NIL DO
    IF e.kind = Q.Msg THEN
      Size(e.text, tw, th); i := e.from.index; j := e.to.index;
      IF i # j THEN Need(i, j, tw + MsgMargin * px)
      ELSIF i < n - 1 THEN Need(i, i + 1, Max(tw, SelfW * px) + SelfMargin * px)
      END
    ELSIF e.kind = Q.Note THEN
      Size(e.text, tw, th); tw := tw + 2 * Pad * px; i := e.from.index; j := e.to.index;
      IF e.placement = Q.RightOf THEN
        IF i < n - 1 THEN Need(i, i + 1, tw + (NoteMargin + Pad) * px) END
      ELSIF e.placement = Q.LeftOf THEN
        IF i > 0 THEN Need(i - 1, i, tw + (NoteMargin + Pad) * px) END
      ELSIF i = j THEN
        IF i < n - 1 THEN Need(i, i + 1, tw / 2 + Pad * px) END;
        IF i > 0 THEN Need(i - 1, i, tw / 2 + Pad * px) END
      ELSE Need(i, j, tw - 2 * NoteOver * px)
      END
    END;
    e := e.next
  END;
  IF n > 0 THEN l.x[0] := 0 END;
  FOR j := 1 TO n - 1 DO
    v := l.x[0] + gap[j];
    FOR i := 1 TO j - 1 DO v := Max(v, l.x[i] + gap[i * n + j]) END;
    l.x[j] := v
  END
END Columns;

(* Activation bars: the edges of actor i's bars, k of them open *)
PROCEDURE RightEdge(i, k: INTEGER): REAL;
BEGIN
  IF k = 0 THEN RETURN l.x[i] END;
  RETURN l.x[i] + BarW * px / 2 + (k - 1) * BarStep * px
END RightEdge;

PROCEDURE LeftEdge(i, k: INTEGER): REAL;
BEGIN
  IF k = 0 THEN RETURN l.x[i] END;
  RETURN l.x[i] - BarW * px / 2 + (k - 1) * BarStep * px
END LeftEdge;

PROCEDURE StartBar(i: INTEGER; y: REAL);
  VAR b: Bar;
BEGIN
  NEW(b); b.actor := i; b.next := NIL;
  b.x1 := l.x[i] - BarW * px / 2 + levels[i] * BarStep * px; b.x2 := b.x1 + BarW * px;
  b.y1 := y; b.y2 := y;
  b.below := stack[i]; stack[i] := b; INC(levels[i]);
  IF lastBar = NIL THEN l.bars := b ELSE lastBar.next := b END;
  lastBar := b
END StartBar;

PROCEDURE EndBar(i: INTEGER; y: REAL);
  VAR b: Bar;
BEGIN
  b := stack[i];
  IF b # NIL THEN
    b.y2 := Max(y, b.y1); stack[i] := b.below; DEC(levels[i])
  END
END EndBar;

(* Lays out d, its text in font at size points *)
PROCEDURE Make*(d: Q.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR
    i, k, nE, nB: INTEGER; a: Q.Actor; e: Q.Event; bx: Q.Box; fr: Frame; sec: Section;
    y, yA, lastLine, lineY, tw, th, h, bandH, x, dx, dy, bottom: REAL;
    g: Geom;

  PROCEDURE Message(e: Q.Event);
    VAR i, j: INTEGER; k: INTEGER;
  BEGIN
    i := e.from.index; j := e.to.index;
    g.tw := 0; g.th := 0;
    IF e.text # NIL THEN Size(e.text, g.tw, g.th) END;
    y := y + MsgGap * px;
    lineY := y + g.th;
    IF g.th > 0 THEN lineY := lineY + TextGap * px END;
    g.self := i = j;
    IF g.self THEN
      g.x1 := RightEdge(i, levels[i]); g.y1 := lineY;
      g.x2 := g.x1 + SelfW * px; g.y2 := lineY + SelfH * px;
      k := levels[i]; IF e.activate THEN INC(k) END;
      g.x3 := RightEdge(i, k);
      g.tx := g.x1 + 5 * px + g.tw / 2; g.ty := lineY - TextGap * px - g.th / 2;
      Holds(Min(g.x1, g.tx - g.tw / 2), Max(g.x2, g.tx + g.tw / 2));
      y := g.y2
    ELSE
      IF e.to.created = e THEN lineY := Max(lineY, y + l.h / 2) END;
      g.y1 := lineY; g.y2 := lineY;
      k := levels[j]; IF e.activate THEN INC(k) END;
      IF l.x[i] < l.x[j] THEN
        g.x1 := RightEdge(i, levels[i]); g.x2 := LeftEdge(j, k);
        IF e.to.created = e THEN g.x2 := l.x[j] - l.w[j] / 2 END
      ELSE
        g.x1 := LeftEdge(i, levels[i]); g.x2 := RightEdge(j, k);
        IF e.to.created = e THEN g.x2 := l.x[j] + l.w[j] / 2 END
      END;
      g.x3 := g.x2;
      g.tx := (g.x1 + g.x2) / 2; g.ty := lineY - TextGap * px - g.th / 2;
      Holds(Min(Min(g.x1, g.x2), g.tx - g.tw / 2), Max(Max(g.x1, g.x2), g.tx + g.tw / 2));
      y := lineY;
      IF e.to.created = e THEN
        l.top[j] := lineY - l.h / 2; y := lineY + l.h / 2
      END
    END;
    IF e.number # NIL THEN Ext(g.x1 - NumR * px, g.x1 + NumR * px) END;
    IF e.to.destroyed = e THEN l.life2[j] := lineY END;
    IF e.from.destroyed = e THEN l.life2[i] := lineY END;
    lastLine := lineY
  END Message;

  PROCEDURE Note(e: Q.Event);
    VAR i, j: INTEGER; lo, hi, w, nh: REAL;
  BEGIN
    i := e.from.index; j := e.to.index;
    Size(e.text, g.tw, g.th);
    w := g.tw + 2 * Pad * px; nh := g.th + 2 * Pad * px;
    y := y + NoteGap * px;
    IF e.placement = Q.RightOf THEN
      g.x1 := RightEdge(i, levels[i]) + NoteMargin * px; g.x2 := g.x1 + w
    ELSIF e.placement = Q.LeftOf THEN
      g.x2 := LeftEdge(i, levels[i]) - NoteMargin * px; g.x1 := g.x2 - w
    ELSIF i = j THEN
      g.x1 := l.x[i] - w / 2; g.x2 := g.x1 + w
    ELSE
      lo := Min(l.x[i], l.x[j]) - NoteOver * px; hi := Max(l.x[i], l.x[j]) + NoteOver * px;
      IF hi - lo < w THEN lo := (lo + hi - w) / 2; hi := lo + w END;
      g.x1 := lo; g.x2 := hi
    END;
    g.y1 := y; g.y2 := y + nh;
    g.tx := (g.x1 + g.x2) / 2; g.ty := y + nh / 2;
    g.self := FALSE; g.x3 := g.x2;
    Holds(g.x1, g.x2);
    y := g.y2; lastLine := y
  END Note;

  PROCEDURE Start(e: Q.Event);
    VAR f: Frame; kw, kh, hh: REAL;
  BEGIN
    y := y + BlockGap * px;
    NEW(f); f.kind := e.block; f.fill := e.fill; f.y1 := y;
    f.sections := NIL; f.lastSection := NIL; f.has := FALSE; f.next := NIL;
    f.parent := open;
    IF open = NIL THEN f.depth := 0 ELSE f.depth := open.depth + 1 END;
    f.label := KindLabel(e.block); f.lw := 0; f.lh := 0; hh := 0;
    IF f.label # NIL THEN
      Size(f.label, kw, kh);
      f.lw := Max(LabelW * px, kw + 2 * Pad * px); f.lh := Max(LabelH * px, kh + 4 * px);
      hh := f.lh
    END;
    f.text := Bracketed(e.text); f.tw := 0;
    IF (f.text # NIL) & (e.block # Q.Rect) THEN
      Size(f.text, f.tw, kh);
      hh := Max(hh, kh); f.ty := y + hh / 2
    ELSE f.text := NIL; f.ty := y + hh / 2
    END;
    y := y + hh;
    IF lastFrame = NIL THEN l.frames := f ELSE lastFrame.next := f END;
    lastFrame := f; open := f; lastLine := y
  END Start;

  PROCEDURE Sect(e: Q.Event);
    VAR s: Section; th: REAL;
  BEGIN
    IF open = NIL THEN RETURN END;
    y := y + BlockGap * px;
    NEW(s); s.y := y; s.next := NIL; s.text := Bracketed(e.text); s.tw := 0; th := 0;
    IF s.text # NIL THEN Size(s.text, s.tw, th) END;
    s.ty := y + SectionGap * px + th / 2;
    IF th > 0 THEN y := y + SectionGap * px + th END;
    IF open.lastSection = NIL THEN open.sections := s ELSE open.lastSection.next := s END;
    open.lastSection := s; lastLine := y
  END Sect;

  PROCEDURE End;
    VAR f: Frame; s: Section; need, c: REAL;
  BEGIN
    IF open = NIL THEN RETURN END;
    f := open;
    y := y + BlockGap * px; f.y2 := y;
    IF ~f.has THEN
      IF n > 0 THEN f.lo := l.x[0] ELSE f.lo := 0 END;
      f.hi := f.lo
    END;
    f.x1 := f.lo - Pad * px; f.x2 := f.hi + Pad * px;
    need := f.tw + 2 * f.lw + 2 * Pad * px;
    s := f.sections;
    WHILE s # NIL DO need := Max(need, s.tw + 2 * Pad * px); s := s.next END;
    IF f.x2 - f.x1 < need THEN
      c := (f.x1 + f.x2) / 2; f.x1 := c - need / 2; f.x2 := c + need / 2
    END;
    f.tx := (f.x1 + f.x2) / 2;
    s := f.sections;
    WHILE s # NIL DO s.tx := f.tx; s := s.next END;
    open := f.parent;
    Holds(f.x1, f.x2);
    lastLine := y
  END End;

  PROCEDURE Shift(VAR v: REAL; by: REAL);
  BEGIN
    v := v + by
  END Shift;

BEGIN
  NEW(l); l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := px;
  n := d.nActors; nE := d.nEvents; nB := d.nBoxes;
  NEW(l.actors, n + 1); NEW(l.x, n + 1); NEW(l.w, n + 1); NEW(l.top, n + 1);
  NEW(l.tw, n + 1); NEW(l.th, n + 1); NEW(l.ly, n + 1); NEW(l.life1, n + 1);
  NEW(l.life2, n + 1); NEW(l.foot, n + 1); NEW(l.footer, n + 1);
  NEW(stack, n + 1); NEW(levels, n + 1);
  NEW(l.events, nE + 1); NEW(l.geom, nE + 1);
  NEW(l.boxes, nB + 1); NEW(l.bx1, nB + 1); NEW(l.by1, nB + 1); NEW(l.bx2, nB + 1);
  NEW(l.by2, nB + 1); NEW(l.btx, nB + 1); NEW(l.bty, nB + 1);
  l.frames := NIL; l.bars := NIL; lastFrame := NIL; lastBar := NIL; open := NIL;
  minX := 0; maxX := 0;
  (* the actors' sizes, and the height of their row *)
  l.h := ActorH * px;
  a := d.actors;
  WHILE a # NIL DO
    i := a.index; l.actors[i] := a; stack[i] := NIL; levels[i] := 0;
    Size(a.label, l.tw[i], l.th[i]);
    l.w[i] := Max(ActorW * px, l.tw[i] + 2 * Pad * px);
    IF IsIcon(a.type) THEN h := (IconH + IconGap + Pad) * px + l.th[i]
    ELSE h := l.th[i] + 2 * Pad * px
    END;
    l.h := Max(l.h, h);
    a := a.next
  END;
  Columns;
  (* the boxes' titles' row *)
  bandH := 0;
  bx := d.boxes;
  WHILE bx # NIL DO
    l.boxes[bx.index] := bx;
    IF bx.title # NIL THEN Size(bx.title, tw, th); bandH := Max(bandH, th + Pad * px / 2) END;
    bx := bx.next
  END;
  IF nB > 0 THEN yA := Pad * px + bandH ELSE yA := 0 END;
  FOR i := 0 TO n - 1 DO l.top[i] := yA END;
  (* the events, from the top *)
  y := yA + l.h; lastLine := y;
  e := d.events;
  WHILE e # NIL DO
    l.events[e.index] := e;
    g.x1 := 0; g.y1 := 0; g.x2 := 0; g.y2 := 0; g.x3 := 0;
    g.tx := 0; g.ty := 0; g.tw := 0; g.th := 0; g.self := FALSE;
    CASE e.kind OF
      Q.Msg: Message(e)
    | Q.Note: Note(e)
    | Q.BlockStart: Start(e)
    | Q.Section: Sect(e)
    | Q.BlockEnd: End
    | Q.Activate: StartBar(e.from.index, lastLine)
    | Q.Deactivate: EndBar(e.from.index, lastLine)
    END;
    l.geom[e.index] := g;
    e := e.next
  END;
  WHILE open # NIL DO End END;
  FOR i := 0 TO n - 1 DO
    WHILE stack[i] # NIL DO EndBar(i, y) END
  END;
  y := y + EndGap * px;
  (* the lifelines, and the actors again at the bottom *)
  bottom := y;
  FOR i := 0 TO n - 1 DO
    a := l.actors[i];
    IF IsIcon(a.type) THEN l.ly[i] := l.top[i] + (IconH + IconGap) * px + l.th[i] / 2
    ELSE l.ly[i] := l.top[i] + l.h / 2
    END;
    IF IsIcon(a.type) THEN l.life1[i] := l.ly[i] + l.th[i] / 2 ELSE l.life1[i] := l.top[i] + l.h END;
    l.footer[i] := (a.destroyed = NIL) & d.mirror;
    IF a.destroyed = NIL THEN l.life2[i] := y END;
    l.foot[i] := y;
    IF l.footer[i] THEN bottom := y + l.h END;
    Ext(l.x[i] - l.w[i] / 2, l.x[i] + l.w[i] / 2)
  END;
  (* the boxes *)
  bx := d.boxes;
  WHILE bx # NIL DO
    k := bx.index; l.bx1[k] := 0; l.bx2[k] := 0;
    i := 0;
    WHILE (i < n) & (l.actors[i].box # bx) DO INC(i) END;
    IF i < n THEN l.bx1[k] := l.x[i] - l.w[i] / 2; l.bx2[k] := l.x[i] + l.w[i] / 2 END;
    FOR i := 0 TO n - 1 DO
      IF l.actors[i].box = bx THEN
        l.bx1[k] := Min(l.bx1[k], l.x[i] - l.w[i] / 2); l.bx2[k] := Max(l.bx2[k], l.x[i] + l.w[i] / 2)
      END
    END;
    l.bx1[k] := l.bx1[k] - Pad * px; l.bx2[k] := l.bx2[k] + Pad * px;
    IF bx.title # NIL THEN
      Size(bx.title, tw, th);
      IF l.bx2[k] - l.bx1[k] < tw + 2 * Pad * px THEN
        x := (l.bx1[k] + l.bx2[k]) / 2;
        l.bx1[k] := x - tw / 2 - Pad * px; l.bx2[k] := x + tw / 2 + Pad * px
      END
    END;
    l.by1[k] := 0; l.by2[k] := bottom + Pad * px;
    l.btx[k] := (l.bx1[k] + l.bx2[k]) / 2; l.bty[k] := (Pad * px + bandH) / 2;
    Ext(l.bx1[k], l.bx2[k]);
    bx := bx.next
  END;
  IF nB > 0 THEN bottom := bottom + Pad * px END;
  l.width := maxX - minX; l.height := bottom;
  (* the title, at Mermaid's 18 pixels, its baseline 25 pixels above
     the drawing *)
  l.title := d.g.title; l.titleSize := size * TitleSize / MermaidSize;
  l.titleW := 0; l.titleH := 0; l.titleX := 0; l.titleY := 0;
  dx := -minX; dy := 0;
  IF (l.title # NIL) & (l.title.n > 0) THEN
    M.LabelSize(font, l.title, l.titleSize, l.titleSize * 1.2, l.titleW, l.titleH);
    IF l.titleW > l.width THEN dx := dx + (l.titleW - l.width) / 2; l.width := l.titleW END;
    dy := TitleMargin * px + 0.3 * l.titleSize + l.titleH / 2;
    l.titleX := l.width / 2; l.titleY := 0.3 * l.titleSize + l.titleH / 2;
    l.height := l.height + dy
  END;
  (* everything moved by (dx, dy) *)
  FOR i := 0 TO n - 1 DO
    Shift(l.x[i], dx); Shift(l.top[i], dy); Shift(l.ly[i], dy);
    Shift(l.life1[i], dy); Shift(l.life2[i], dy); Shift(l.foot[i], dy)
  END;
  FOR i := 0 TO nE - 1 DO
    Shift(l.geom[i].x1, dx); Shift(l.geom[i].x2, dx); Shift(l.geom[i].x3, dx);
    Shift(l.geom[i].tx, dx);
    Shift(l.geom[i].y1, dy); Shift(l.geom[i].y2, dy); Shift(l.geom[i].ty, dy)
  END;
  fr := l.frames;
  WHILE fr # NIL DO
    Shift(fr.x1, dx); Shift(fr.x2, dx); Shift(fr.tx, dx);
    Shift(fr.y1, dy); Shift(fr.y2, dy); Shift(fr.ty, dy);
    sec := fr.sections;
    WHILE sec # NIL DO Shift(sec.tx, dx); Shift(sec.y, dy); Shift(sec.ty, dy); sec := sec.next END;
    fr := fr.next
  END;
  lastBar := l.bars;
  WHILE lastBar # NIL DO
    Shift(lastBar.x1, dx); Shift(lastBar.x2, dx); Shift(lastBar.y1, dy); Shift(lastBar.y2, dy);
    lastBar := lastBar.next
  END;
  FOR k := 0 TO nB - 1 DO
    Shift(l.bx1[k], dx); Shift(l.bx2[k], dx); Shift(l.btx[k], dx);
    Shift(l.by1[k], dy); Shift(l.by2[k], dy); Shift(l.bty[k], dy)
  END;
  lay := l; l := NIL; gap := NIL; stack := NIL; levels := NIL
END Make;

(* Lays out d as Make does, at size points, or at a smaller size, to a
   tenth of a point, if that is wider than maxW points (0 for no
   limit) *)
PROCEDURE Fit*(d: Q.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmSeqLayout.
