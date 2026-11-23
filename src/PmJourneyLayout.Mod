MODULE PmJourneyLayout;
(* PmJourneyLayout: a user journey, PmJourney's, laid out as Mermaid's
   journeyRenderer.ts lays it out, in its pixels, taken at the labels'
   size, 16 pixels to the size. Lengths are in points, y down.

   The legend is at the left: for each actor, a circle and its name,
   wrapped at 360 pixels. The tasks are in a row to its right, 150
   pixels wide and 200 apart, and each section's box spans its tasks,
   above them. Below the tasks is the activity line, an arrow along
   the row; below that, each task's face, higher for a higher score,
   on a dashed line down from the task.

   Mermaid's lengths are kept but for these: the drawing starts 150
   pixels to the right of the widest actor's name, or 50 pixels in
   with no actors; the title, at 1.5 times the size, in bold, is above
   the sections, not over them; a task's or a section's text is wrapped
   to its box, less 10 pixels, and the sections' or the tasks' boxes
   grow to hold the highest, moving down what is below them; and faces
   for scores far out of 1 to 5 move the drawing down so that they fit.

   PmJourneyPic draws this layout; PmJourneyMp lays the journey out
   again, in the same way, with ConTeXt's text sizes. A change here is
   made there too. *)

IMPORT F := PmFlow, M := PmMetrics, J := PmJourney, FL := PmFlowLayout;

CONST
  MermaidSize* = 16;
  (* in Mermaid's pixels *)
  Margin* = 10;          (* around the drawing *)
  LegendX* = 20;         (* the legend's circles' centres *)
  LegendTextX* = 50;     (* its text's left *)
  LegendR* = 7;          (* its circles *)
  LegendW* = 360;        (* its text is wrapped at this *)
  LegendStep* = 20;      (* from one actor to the next, a line at least *)
  LegendTop* = 10;       (* below the top: the first circle *)
  LeftGap* = 150;        (* from the widest name to the tasks *)
  NoActorsLeft* = 50;
  TaskW* = 150; TaskH* = 50; TaskStep* = 200;
  TaskTop* = 60;         (* below the top *)
  TextPad* = 5;          (* in a box, each side of its text *)
  ActivityY* = 150;      (* the activity line, below the top *)
  ActivityW* = 4;
  MinArrow* = 100;
  FaceTop* = 250;        (* a face for score 5, below the top *)
  FaceStep* = 30;        (* for each point of the score *)
  FaceR* = 15;
  LineEnd* = 400;        (* the tasks' lines, below the top *)
  TitleGap* = 15;        (* below the title *)
  TitleScale* = 1.5;

TYPE
  Reals* = POINTER TO ARRAY OF REAL;
  Labels* = POINTER TO ARRAY OF F.Label;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: J.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;   (* the labels' size, line spacing, a pixel *)
    width-, height-: REAL;
    left-: REAL;             (* the first task's left *)
    top-: REAL;              (* the sections' top: Mermaid's y 50 *)
    (* the actors, by index: the legend's circles' centres, the names
       wrapped, their left and their centre *)
    names-: Labels;
    cx-, cy-, nx-, ny-: Reals;
    (* the sections, by index: the box's top left, width and height,
       the text, wrapped, centred in it *)
    sections-: POINTER TO ARRAY OF J.Section;
    sx-, sy-, sw-, sh-: Reals;
    stext-: Labels;
    (* the tasks, by index: the box, its text, and the face's centre *)
    tasks-: POINTER TO ARRAY OF J.Task;
    tx-, ty-, tw-, th-, fx-, fy-: Reals;
    ttext-: Labels;
    lineY1-, lineY2-: REAL;  (* each task's line, from and to *)
    (* the activity line, at ay, from ax1 to ax2, its arrow's tip *)
    ax1-, ax2-, ay-: REAL;
    title-: F.Label;         (* in bold, its left at titleX, centred
                                at titleY *)
    titleSize-, titleW-, titleH-, titleX-, titleY-: REAL
  END;

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

(* Lays out d with its labels at size points *)
PROCEDURE Make*(d: J.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR
    l: Layout; px, w, h, y, x, right, bottom, minFace, top, secH, taskH, extra: REAL; k, nA, nS, nT: INTEGER;
    t: J.Task; s: J.Section;
BEGIN
  NEW(l); l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := px;
  nA := d.nActors; nS := d.nSections; nT := d.nTasks;
  (* the title *)
  l.title := NIL; l.titleSize := size * TitleScale; l.titleW := 0; l.titleH := 0;
  top := Margin * px;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    l.title := Bold(d.g.title);
    M.LabelSize(font, l.title, l.titleSize, l.titleSize * 1.2, l.titleW, l.titleH);
    l.titleY := top + l.titleH / 2;
    top := top + l.titleH + TitleGap * px
  END;
  (* faces far down for high scores move everything down *)
  minFace := 0; t := d.tasks;
  WHILE t # NIL DO
    y := FaceTop + (5 - t.score) * FaceStep - FaceR - Margin;
    IF y < minFace THEN minFace := y END;
    t := t.next
  END;
  IF top + minFace * px < Margin * px THEN top := (Margin - minFace) * px END;
  l.top := top;
  (* the legend *)
  NEW(l.names, nA + 1); NEW(l.cx, nA + 1); NEW(l.cy, nA + 1); NEW(l.nx, nA + 1);
  NEW(l.ny, nA + 1);
  y := top + LegendTop * px; right := 0;
  FOR k := 0 TO nA - 1 DO
    l.names[k] := FL.Wrap(font, F.PlainLabel(d.actors[k]), size, LegendW * px);
    M.LabelSize(font, l.names[k], size, l.vs, w, h);
    IF w > right THEN right := w END;
    l.cx[k] := LegendX * px; l.cy[k] := y;
    l.nx[k] := LegendTextX * px; l.ny[k] := y + (l.names[k].n - 1) * l.vs / 2;
    y := y + Max(LegendStep, LegendStep * l.names[k].n) * px
  END;
  bottom := y - LegendStep * px + LegendR * px;
  IF nA > 0 THEN
    bottom := Max(bottom, l.ny[nA - 1] + l.names[nA - 1].n * l.vs / 2);
    l.left := (LegendTextX + LeftGap) * px + right
  ELSE l.left := NoActorsLeft * px
  END;
  bottom := Max(bottom, top + LineEnd * px);
  IF l.title # NIL THEN l.titleX := l.left END;
  (* the sections, all as high as the highest *)
  NEW(l.sections, nS + 1); NEW(l.sx, nS + 1); NEW(l.sy, nS + 1); NEW(l.sw, nS + 1);
  NEW(l.sh, nS + 1); NEW(l.stext, nS + 1);
  secH := TaskH * px; s := d.sections;
  WHILE s # NIL DO
    k := s.index; l.sections[k] := s;
    l.sx[k] := l.left + s.first * TaskStep * px; l.sy[k] := top;
    l.sw[k] := (TaskW * s.count + (TaskStep - TaskW) * (s.count - 1)) * px;
    l.stext[k] := FL.Wrap(font, s.text, size, l.sw[k] - 2 * TextPad * px);
    M.LabelSize(font, l.stext[k], size, l.vs, w, h);
    secH := Max(secH, h + 2 * TextPad * px);
    s := s.next
  END;
  FOR k := 0 TO nS - 1 DO l.sh[k] := secH END;
  (* the tasks, all as high as the highest, below the sections *)
  NEW(l.tasks, nT + 1); NEW(l.tx, nT + 1); NEW(l.ty, nT + 1); NEW(l.tw, nT + 1);
  NEW(l.th, nT + 1); NEW(l.fx, nT + 1); NEW(l.fy, nT + 1); NEW(l.ttext, nT + 1);
  taskH := TaskH * px; t := d.tasks;
  WHILE t # NIL DO
    k := t.index; l.tasks[k] := t;
    l.tw[k] := TaskW * px;
    l.ttext[k] := FL.Wrap(font, t.text, size, l.tw[k] - 2 * TextPad * px);
    M.LabelSize(font, l.ttext[k], size, l.vs, w, h);
    taskH := Max(taskH, h + 2 * TextPad * px);
    t := t.next
  END;
  (* what is below the tasks moves down as much as they grew *)
  extra := secH + taskH - 2 * TaskH * px;
  t := d.tasks;
  WHILE t # NIL DO
    k := t.index;
    l.tx[k] := l.left + k * TaskStep * px; l.ty[k] := top + secH + (TaskTop - TaskH) * px;
    l.th[k] := taskH;
    l.fx[k] := l.tx[k] + l.tw[k] / 2;
    l.fy[k] := top + extra + (FaceTop + (5 - t.score) * FaceStep) * px;
    bottom := Max(bottom, Max(l.fy[k] + FaceR * px, l.ty[k] + l.th[k]));
    t := t.next
  END;
  l.lineY1 := top + secH + (TaskTop - TaskH) * px; l.lineY2 := top + extra + LineEnd * px;
  bottom := Max(bottom, l.lineY2);
  (* the activity line *)
  l.ax1 := l.left; l.ax2 := l.left + Max(nT * TaskStep, MinArrow) * px;
  l.ay := top + extra + ActivityY * px;
  x := Max(l.ax2, l.left + l.titleW);
  IF nT > 0 THEN x := Max(x, l.tx[nT - 1] + l.tw[nT - 1]) END;
  l.width := x + Margin * px; l.height := bottom + Margin * px;
  lay := l
END Make;

(* Lays out d as Make does, at size points, or at a smaller size, to a
   tenth of a point, if that is wider than maxW points (0 for no
   limit) *)
PROCEDURE Fit*(d: J.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmJourneyLayout.
