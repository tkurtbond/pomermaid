MODULE PmTimelineLayout;
(* PmTimelineLayout: a timeline, PmTimeline's, laid out as Mermaid's
   timelineRenderer.ts (left to right) and timelineRendererVertical.ts
   (top down) lay it out, in their pixels, taken at the labels' size,
   16 pixels to the size. Lengths are in points, y down.

   Each section, period and event is a node: a box, its text wrapped
   to it and centred in it. A node is as high as its text, plus 8.8
   pixels (Mermaid's 0.55 of the font size) and its padding; the nodes
   of a kind are as high as the highest, but events.

   Left to right: the sections in a row, each over its periods, as wide
   as they are; the periods 190 pixels wide and 200 apart, 50 below
   the sections; each period's events stacked below it, from 200
   pixels below its top, 10 apart, on a dashed line down from the
   period; and the activity line, an arrow, 50 pixels below the
   periods, from 50 pixels left of the first to 50 right of the last.
   Padding is 20 pixels.

   Top down: the sections across the width, 590 pixels, each followed
   by its periods, 210 pixels wide, left of a vertical axis, and each
   period's events, 310 wide, 50 right of it, on dashed lines from it;
   the axis, an arrow down, from 32 pixels above the first node to 28
   below the last. Padding is 5 pixels.

   Each section and what is in it is in the colour of its number;
   without sections, each period and its events is in the colour of
   its number, or all in the first with timeline.disableMulticolor.

   Mermaid's lengths are kept but for these: a section's text is
   wrapped to its width, not 150 pixels, and the sections' height is
   the highest's; the title, at 1.5 times the size, in bold, is above
   the drawing, its left at the first node's; top down, a section
   starts 20 pixels below what is above it, and the axis and dashed
   lines have arrowheads.

   PmTimelinePic draws this layout; PmTimelineMp lays the timeline out
   again, in the same way, with ConTeXt's text sizes. A change here is
   made there too. *)

IMPORT F := PmFlow, M := PmMetrics, T := PmTimeline, FL := PmFlowLayout;

CONST
  MermaidSize* = 16;
  (* the kinds of node *)
  SectionNode* = 0; PeriodNode* = 1; EventNode* = 2;
  (* in Mermaid's pixels *)
  Margin* = 10;          (* around the drawing *)
  TextExtra* = 8.8;      (* a node's height, beyond its text and padding *)
  Radius* = 5;           (* a node's top corners *)
  BottomW* = 3;          (* the line along its bottom *)
  AxisW* = 4;            (* the activity line, the axis *)
  DashW* = 2; Dash* = 5; (* the dashed lines *)
  TitleGap* = 15;        (* below the title *)
  TitleScale* = 1.5;
  (* left to right *)
  LrPad* = 20;
  LrNodeW* = 150;        (* a period's or an event's text *)
  LrStep* = 200;         (* from one period to the next *)
  LrLineLeft* = 50;      (* the activity line, left of the first period *)
  LrGap* = 50;           (* below the sections, below the periods *)
  LrMinEvent* = 50;      (* an event's least height *)
  LrEventTop* = 200;     (* the first event, below its period's top *)
  LrEventGap* = 10;
  LrGrow* = 20;          (* the sections and periods, above the highest text *)
  (* top down *)
  TdPad* = 5;
  TdPeriodW* = 200; TdEventW* = 300; TdSectionW* = 580;
  TdAxisGap* = 20;       (* from a period to the axis *)
  TdEventGap* = 50;      (* from the axis to its events *)
  TdSectionGap* = 20;    (* below a section *)
  TdPeriodGap* = 30;     (* between periods *)
  TdEventSpace* = 10;    (* between events *)
  TdAxisTop* = 32;       (* the axis, above the first node *)
  TdAxisBottom* = 28;    (* and below the last *)

TYPE
  Reals* = POINTER TO ARRAY OF REAL;
  Ints* = POINTER TO ARRAY OF INTEGER;
  Labels* = POINTER TO ARRAY OF F.Label;
  PeriodArray = POINTER TO ARRAY OF T.Period;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: T.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;   (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    (* the nodes, in the order they are drawn: each one's kind, colour
       number, box (its top left, width and height) and text *)
    n-: INTEGER;
    kind-, colour-: Ints;
    x-, y-, w-, h-: Reals;
    text-: Labels;
    (* the dashed lines, from (x1, y1) to their arrows' tips at
       (x2, y2) *)
    nLines-: INTEGER;
    x1-, y1-, x2-, y2-: Reals;
    (* the activity line, or the axis, to its arrow's tip *)
    ax1-, ay1-, ax2-, ay2-: REAL;
    title-: F.Label;         (* in bold, its left at titleX, centred
                                at titleY *)
    titleSize-, titleW-, titleH-, titleX-, titleY-: REAL
  END;

VAR
  l: Layout;
  px: REAL;

PROCEDURE Max(a, b: REAL): REAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

(* lab with every byte in bold *)
PROCEDURE Bold(lab: F.Label): F.Label;
  VAR r: F.Label; line, nl, last: F.Line; k, len: LONGINT;
BEGIN
  NEW(r); r^ := lab^; r.lines := NIL; last := NIL;
  line := lab.lines;
  WHILE line # NIL DO
    NEW(nl); nl^ := line^; nl.next := NIL;
    len := 0; WHILE line.text[len] # 0X DO INC(len) END;
    NEW(nl.style, len + 1);
    FOR k := 0 TO len - 1 DO nl.style[k] := F.Bold END;
    nl.style[len] := F.Roman;
    IF last = NIL THEN r.lines := nl ELSE last.next := nl END;
    last := nl;
    line := line.next
  END;
  RETURN r
END Bold;

(* The height of a node of text lab wrapped at w pixels, padding pad
   pixels; the label wrapped in wrapped *)
PROCEDURE Height(lab: F.Label; w, pad: REAL; VAR wrapped: F.Label): REAL;
  VAR tw, th: REAL;
BEGIN
  wrapped := FL.Wrap(l.font, lab, l.size, w * px);
  M.LabelSize(l.font, wrapped, l.size, l.vs, tw, th);
  RETURN wrapped.n * l.vs + (TextExtra + pad) * px
END Height;

(* Adds a node *)
PROCEDURE Node(kind, colour: INTEGER; x, y, w, h: REAL; text: F.Label);
  VAR k: INTEGER;
BEGIN
  k := l.n; INC(l.n);
  l.kind[k] := kind; l.colour[k] := colour; l.x[k] := x; l.y[k] := y; l.w[k] := w;
  l.h[k] := h; l.text[k] := text
END Node;

(* Adds a dashed line *)
PROCEDURE Line(x1, y1, x2, y2: REAL);
  VAR k: INTEGER;
BEGIN
  k := l.nLines; INC(l.nLines);
  l.x1[k] := x1; l.y1[k] := y1; l.x2[k] := x2; l.y2[k] := y2
END Line;

(* The periods drawn, in order, and each one's colour number *)
PROCEDURE Periods(d: T.Diagram; VAR ps: PeriodArray; VAR cs: Ints;
  VAR n: INTEGER);
  VAR s: T.Section; p: T.Period; k: INTEGER;
BEGIN
  NEW(ps, d.nPeriods + 1); NEW(cs, d.nPeriods + 1); n := 0;
  IF d.sections # NIL THEN
    s := d.sections;
    WHILE s # NIL DO
      FOR k := 0 TO s.count - 1 DO ps[n] := s.periods[k]; cs[n] := s.index; INC(n) END;
      s := s.next
    END
  ELSE
    p := d.periods;
    WHILE p # NIL DO
      ps[n] := p;
      IF d.multicolor THEN cs[n] := n ELSE cs[n] := 0 END;
      INC(n); p := p.next
    END
  END
END Periods;

(* Lays out d with its labels at size points *)
PROCEDURE Make*(d: T.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR
    ps: PeriodArray; cs: Ints; n, nNodes, k, i, j: INTEGER;
    pw, ew, pad: REAL;
    ptext: Labels; ph: Reals;        (* the periods' wrapped text, heights *)
    etext: POINTER TO ARRAY OF Labels; eh: POINTER TO ARRAY OF Reals;
    stack: Reals;                    (* each period's events' height *)
    top, left, x, y, secH, taskH, maxStack, block, spacing, right, bottom, h,
    axis, ex, sw: REAL;
    s: T.Section; p: T.Period; lab: F.Label;
BEGIN
  NEW(l); l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := px;
  IF d.td THEN pad := TdPad; pw := TdPeriodW; ew := TdEventW
  ELSE pad := LrPad; pw := LrNodeW; ew := LrNodeW
  END;
  Periods(d, ps, cs, n);
  nNodes := d.nSections + n;
  FOR k := 0 TO n - 1 DO INC(nNodes, ps[k].nEvents) END;
  NEW(l.kind, nNodes + 1); NEW(l.colour, nNodes + 1); NEW(l.x, nNodes + 1);
  NEW(l.y, nNodes + 1); NEW(l.w, nNodes + 1); NEW(l.h, nNodes + 1);
  NEW(l.text, nNodes + 1); l.n := 0;
  NEW(l.x1, nNodes + 1); NEW(l.y1, nNodes + 1); NEW(l.x2, nNodes + 1);
  NEW(l.y2, nNodes + 1); l.nLines := 0;
  (* the title *)
  l.title := NIL; l.titleSize := size * TitleScale; l.titleW := 0; l.titleH := 0;
  top := Margin * px; left := Margin * px;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    l.title := Bold(d.g.title);
    M.LabelSize(font, l.title, l.titleSize, l.titleSize * 1.2, l.titleW, l.titleH);
    l.titleY := top + l.titleH / 2;
    top := top + l.titleH + TitleGap * px
  END;
  (* the periods and events: their text and heights *)
  NEW(ptext, n + 1); NEW(ph, n + 1); NEW(etext, n + 1); NEW(eh, n + 1); NEW(stack, n + 1);
  taskH := 0; maxStack := 0;
  FOR k := 0 TO n - 1 DO
    p := ps[k];
    ph[k] := Height(p.text, pw, pad, ptext[k]);
    taskH := Max(taskH, ph[k]);
    NEW(etext[k], p.nEvents + 1); NEW(eh[k], p.nEvents + 1); stack[k] := 0;
    FOR i := 0 TO p.nEvents - 1 DO
      h := Height(p.events[i], ew, pad, etext[k][i]);
      IF ~d.td THEN h := Max(h, LrMinEvent * px) END;
      eh[k][i] := h; stack[k] := stack[k] + h;
      IF i > 0 THEN
        IF d.td THEN stack[k] := stack[k] + TdEventSpace * px
        ELSE stack[k] := stack[k] + LrEventGap * px
        END
      END
    END;
    maxStack := Max(maxStack, stack[k])
  END;
  bottom := top;
  IF ~d.td THEN
    (* left to right *)
    IF n > 0 THEN taskH := taskH + LrGrow * px END;
    secH := 0; s := d.sections;
    WHILE s # NIL DO
      sw := LrStep * Max(s.count, 1) - LrStep + LrNodeW;
      secH := Max(secH, Height(s.text, sw, pad, lab) + LrGrow * px);
      s := s.next
    END;
    x := left + LrLineLeft * px; right := x;
    y := top;
    IF d.sections # NIL THEN y := top + secH + LrGap * px END;
    s := d.sections; j := 0;
    LOOP
      IF s # NIL THEN
        sw := (LrStep * Max(s.count, 1) - LrStep + LrNodeW + 2 * pad) * px;
        h := Height(s.text, sw / px - 2 * pad, pad, lab);
        Node(SectionNode, s.index, x, top, sw, secH, lab);
        right := Max(right, x + sw);
        i := s.count
      ELSE i := n
      END;
      FOR k := j TO j + i - 1 DO
        p := ps[k];
        Node(PeriodNode, cs[k], x, y, (LrNodeW + 2 * pad) * px, taskH, ptext[k]);
        right := Max(right, x + (LrNodeW + 2 * pad) * px);
        Line(x + (LrNodeW / 2 + pad) * px, y + taskH, x + (LrNodeW / 2 + pad) * px,
          y + taskH + LrEventTop * px + maxStack);
        bottom := Max(bottom, y + taskH + LrEventTop * px + maxStack);
        h := y + LrEventTop * px;
        FOR i := 0 TO p.nEvents - 1 DO
          Node(EventNode, cs[k], x, h, (LrNodeW + 2 * pad) * px, eh[k][i], etext[k][i]);
          h := h + eh[k][i] + LrEventGap * px
        END;
        x := x + LrStep * px
      END;
      IF s # NIL THEN
        IF s.count = 0 THEN x := x + LrStep * px END;
        j := j + s.count; s := s.next
      END;
      IF s = NIL THEN EXIT END
    END;
    l.ax1 := left; l.ay1 := y + taskH + LrGap * px;
    l.ax2 := right + LrLineLeft * px; l.ay2 := l.ay1;
    IF n = 0 THEN l.ax2 := Max(l.ax2, left + 2 * LrLineLeft * px) END;
    bottom := Max(bottom, l.ay1 + AxisW * 2 * px);
    right := l.ax2;
    IF l.title # NIL THEN l.titleX := left + LrLineLeft * px END
  ELSE
    (* top down *)
    block := Max(taskH, maxStack); spacing := block + TdPeriodGap * px;
    secH := 0; s := d.sections;
    WHILE s # NIL DO
      secH := Max(secH, Height(s.text, TdSectionW, pad, lab));
      s := s.next
    END;
    axis := left + (TdPeriodW + 2 * pad + TdAxisGap) * px;
    ex := axis + TdEventGap * px;
    right := ex + (TdEventW + 2 * pad) * px;
    l.ax1 := axis; l.ay1 := top; l.ax2 := axis;
    y := top + TdAxisTop * px;
    s := d.sections; j := 0;
    LOOP
      IF s # NIL THEN
        h := Height(s.text, TdSectionW, pad, lab);
        Node(SectionNode, s.index, left, y, (TdSectionW + 2 * pad) * px, secH, lab);
        y := y + secH + TdSectionGap * px;
        bottom := Max(bottom, y - TdSectionGap * px);
        i := s.count
      ELSE i := n
      END;
      FOR k := j TO j + i - 1 DO
        p := ps[k];
        Node(PeriodNode, cs[k], axis - TdAxisGap * px - (TdPeriodW + 2 * pad) * px, y,
          (TdPeriodW + 2 * pad) * px, taskH, ptext[k]);
        bottom := Max(bottom, y + taskH);
        h := y;
        FOR i := 0 TO p.nEvents - 1 DO
          Node(EventNode, cs[k], ex, h, (TdEventW + 2 * pad) * px, eh[k][i], etext[k][i]);
          Line(axis, h + eh[k][i] / 2, ex, h + eh[k][i] / 2);
          h := h + eh[k][i];
          bottom := Max(bottom, h);
          h := h + TdEventSpace * px
        END;
        y := y + spacing
      END;
      IF s # NIL THEN
        IF s.count > 0 THEN y := y - TdPeriodGap * px + TdSectionGap * px END;
        j := j + s.count; s := s.next
      END;
      IF s = NIL THEN EXIT END
    END;
    l.ay2 := Max(bottom, top + TdAxisTop * px) + TdAxisBottom * px;
    bottom := l.ay2;
    IF l.title # NIL THEN l.titleX := left END
  END;
  IF l.title # NIL THEN right := Max(right, l.titleX + l.titleW) END;
  l.width := right + Margin * px;
  l.height := bottom + Margin * px;
  lay := l
END Make;

(* Lays out d as Make does, at size points, or at a smaller size, to a
   tenth of a point, if that is wider than maxW points (0 for no
   limit) *)
PROCEDURE Fit*(d: T.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmTimelineLayout.
