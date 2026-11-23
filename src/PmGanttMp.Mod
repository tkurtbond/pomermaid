MODULE PmGanttMp;
(* PmGanttMp: a laid out Gantt chart, PmGanttLayout's, written in
   MetaPost, for ConTeXt: a \startMPcode block that draws it as
   PmGanttPic does, in the same order and colours (PmGanttPic's), with
   ConTeXt's text.

   The chart is as wide as the layout, --width, and nothing in it
   depends on the text but where a task's text goes, inside its bar or
   beside it, and so its colour (decision 3): that is decided in
   MetaPost, from the width of ConTeXt's text, as Mermaid decides it
   from the browser's, between the places PmGanttLayout offers. The
   rest of the layout, in points, is written as numbers. Each text is a
   textext picture, centred on its place, or starting or ending there,
   scaled from the document's size, taken to be the layout's, to the
   text's. Text is written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, S := PmStyle, GL := PmGanttLayout, GP := PmGanttPic, PmMp;

CONST
  Left = 0; Centre = 1; Right = 2;
  LineW = 2;         (* the bars' outlines, in pixels, as PmGanttPic's *)
  GridW = 1;

VAR
  l: GL.Layout;
  px: REAL;

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

PROCEDURE Ln;
BEGIN
  PmIO.WriteLn
END Ln;

(* x points *)
PROCEDURE Pt(x: REAL);
BEGIN
  PmIO.WriteReal(x, 3); W("pt")
END Pt;

(* The colour rgb, 0RRGGBBH, as a MetaPost colour; black for -1 *)
PROCEDURE Col(rgb: LONGINT);
BEGIN
  IF rgb < 0 THEN rgb := 0 END;
  W("("); PmIO.WriteReal(rgb DIV 10000H / 255, 4); W(",");
  PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); W(",");
  PmIO.WriteReal(rgb MOD 100H / 255, 4); W(")")
END Col;

(* The box at (x, y), w by h, its corners rounded r points, at most
   half its width and height, as a path *)
PROCEDURE Path(x, y, w, h, r: REAL);
BEGIN
  IF r > w / 2 THEN r := w / 2 END;
  IF r > h / 2 THEN r := h / 2 END;
  IF r < 0.001 THEN r := 0 END;
  W("pmgbox("); Pt(x); W(", "); Pt(y); W(", "); Pt(w); W(", "); Pt(h); W(", "); Pt(r); W(")")
END Path;

(* The path p written by Path, filled with fill and outlined with line,
   width points wide; -1 for neither *)
PROCEDURE Paint(fill, line: LONGINT; width: REAL; milestone: BOOLEAN;
  x, y, w, h, r: REAL);

  PROCEDURE Shape;
  BEGIN
    Path(x, y, w, h, r);
    IF milestone THEN
      W(" shifted -pmgp("); Pt(x + w / 2); W(", "); Pt(y + h / 2); W(") rotated 45 scaled 0.8");
      W(" shifted pmgp("); Pt(x + w / 2); W(", "); Pt(y + h / 2); W(")")
    END
  END Shape;

BEGIN
  IF fill >= 0 THEN W("fill "); Shape; W(" withcolor "); Col(fill); W(";"); Ln END;
  IF (line >= 0) & (width > 0) THEN
    W("draw "); Shape; W(" withcolor "); Col(line); W(" withpen pencircle scaled ");
    Pt(width); W(";"); Ln
  END
END Paint;

(* A line from (x1, y1) to (x2, y2) in rgb, width points wide, dashed
   dash points, or 0 *)
PROCEDURE Line(x1, y1, x2, y2: REAL; rgb: LONGINT; width, dash: REAL);
BEGIN
  IF rgb < 0 THEN RETURN END;
  W("draw pmgp("); Pt(x1); W(", "); Pt(y1); W(") -- pmgp("); Pt(x2); W(", "); Pt(y2);
  W(") withcolor "); Col(rgb); W(" withpen pencircle scaled "); Pt(width);
  IF dash > 0 THEN W(" dashed dashpattern(on "); Pt(dash); W(" off "); Pt(dash); W(")") END;
  W(";"); Ln
END Line;

(* lab as a picture, its lines centred or flush with the anchor, size
   points *)
PROCEDURE Picture(lab: F.Label; size: REAL; anchor: INTEGER);
BEGIN
  W('textext("\framed[frame=off,offset=0pt,align=');
  CASE anchor OF
    Left: W("flushleft")
  | Right: W("flushright")
  ELSE W("middle")
  END;
  W(']{" & '); PmMp.Label(lab); W(' & "}") scaled '); PmIO.WriteReal(size / l.size, 4)
END Picture;

(* lab, size points, at (x, y) as anchor says, in rgb *)
PROCEDURE Text(lab: F.Label; x, y: REAL; rgb: LONGINT; size: REAL; anchor: INTEGER);
BEGIN
  IF (lab = NIL) OR (lab.n = 0) THEN RETURN END;
  W("pmgtext("); Picture(lab, size, anchor);
  W(", "); Pt(x); W(", "); Pt(y); W(", "); PmIO.WriteInt(anchor); W(", "); Col(rgb); W(");"); Ln
END Text;

(* Task i's text, inside its bar if it fits, else right of it, or left
   if there is no room on the right, as Mermaid places it, by its
   width in MetaPost *)
PROCEDURE TaskText(i: INTEGER);
BEGIN
  W("pmgt := "); Picture(l.text[i], l.tsize[i], Centre); W("; pmgw := pmgwd(pmgt);"); Ln;
  W("if pmgw > "); Pt(l.pRoom[i]); W(": if pmgw > "); Pt(l.pRight[i]);
  W(": pmga := 2; else: pmga := 0; fi pmgc := "); Col(GP.PlacedColour(i, GL.OutsideRight));
  W(";"); Ln;
  W("  else: pmga := 1; pmgc := "); Col(GP.PlacedColour(i, GL.Inside)); W("; fi"); Ln;
  W("pmgtext(pmgt, if pmgw > "); Pt(l.xRoom[i]); W(": if pmgw > "); Pt(l.xRight[i]); W(": ");
  Pt(l.leftX[i]); W(" else: "); Pt(l.rightX[i]); W(" fi else: "); Pt(l.inX[i]); W(" fi, ");
  Pt(l.ty[i]); W(", pmga, pmgc);"); Ln
END TaskText;

(* The excluded days and the rows, as PmGanttPic draws them *)
PROCEDURE Background;
  VAR k, e: INTEGER; y1, y2: REAL; c: LONGINT;
BEGIN
  FOR e := 0 TO l.nEx - 1 DO
    Paint(GP.t.exclude, -1, 0, FALSE, l.exX[e], l.exY, l.exW[e], l.exH, 0)
  END;
  FOR k := 0 TO l.nRows - 1 DO
    c := GP.RowColour(l.rowColour[k], 0FFFFFFH);
    Paint(c, -1, 0, FALSE, 0, l.rowY[k], l.rowW, l.rowH, 0);
    IF GP.t.exclude >= 0 THEN
      y1 := l.rowY[k]; y2 := y1 + l.rowH;
      IF y1 < l.exY THEN y1 := l.exY END;
      IF y2 > l.exY + l.exH THEN y2 := l.exY + l.exH END;
      IF (y2 > y1) & (c >= 0) THEN
        c := GP.RowColour(l.rowColour[k], GP.t.exclude);
        FOR e := 0 TO l.nEx - 1 DO
          IF l.exX[e] < l.rowW THEN Paint(c, -1, 0, FALSE, l.exX[e], y1, l.exW[e], y2 - y1, 0) END
        END
      END
    END
  END
END Background;

(* The grid: its lines and their labels *)
PROCEDURE Grid;
  VAR k: INTEGER; line, text: LONGINT; lab: F.Label;
BEGIN
  line := GP.Over(GP.t.grid, GP.GridOpacity, 0FFFFFFH);
  IF GP.t.text < 0 THEN text := 0 ELSE text := GP.Over(GP.t.text, GP.GridOpacity, 0FFFFFFH) END;
  FOR k := 0 TO l.nTicks - 1 DO
    lab := F.PlainLabel(GP.Collapsed(l.tickLabel[k]));
    Line(l.tickX[k], l.gridY1, l.tickX[k], l.gridY2, line, GridW * px, 0);
    Text(lab, l.tickX[k], l.labelY, text, l.tickSize, Centre);
    IF l.topAxis THEN
      Line(l.tickX[k], l.topY1, l.tickX[k], l.topY2, line, GridW * px, 0);
      Text(lab, l.tickX[k], l.topLabelY, text, l.tickSize, Centre)
    END
  END
END Grid;

(* The tasks' bars, then their text *)
PROCEDURE Tasks;
  VAR i: INTEGER; fill, line: LONGINT;
BEGIN
  FOR i := 0 TO l.nTasks - 1 DO
    GP.BarColours(i, fill, line);
    Paint(fill, line, LineW * px, l.task[i].milestone & ~l.task[i].vert,
      l.bx[i], l.by[i], l.bw[i], l.bh[i], l.radius)
  END;
  FOR i := 0 TO l.nTasks - 1 DO
    IF (l.text[i] = NIL) OR (l.text[i].n = 0) THEN (* none *)
    ELSIF l.place[i] = GL.VertText THEN
      Text(l.text[i], l.tx[i], l.ty[i], GP.TextColour(i), l.tsize[i], Centre)
    ELSE TaskText(i)
    END
  END
END Tasks;

(* The section names *)
PROCEDURE Sections;
  VAR k: INTEGER; c: LONGINT;
BEGIN
  FOR k := 0 TO l.nSections - 1 DO
    IF (l.secColour[k] >= 0) & (l.secColour[k] < GP.Styled) THEN c := GP.t.title ELSE c := 0 END;
    Text(l.secText[k], l.secX, l.secY[k], c, l.secSize, Left)
  END
END Sections;

(* The today line, in todayMarker's style *)
PROCEDURE Today;
  VAR st: S.Style;
BEGIN
  IF l.today THEN
    GP.TodayStyle(st);
    IF st.line # S.NoColour THEN
      Line(l.todayX, l.todayY1, l.todayX, l.todayY2, S.Rgb(st.line), st.width, st.dash)
    END
  END
END Today;

(* Writes lay's Gantt chart as a \startMPcode block *)
PROCEDURE Write*(lay: GL.Layout);
BEGIN
  l := lay; px := l.px;
  GP.Use(lay);
  W("\startMPcode"); Ln;
  W("picture pmgt; numeric pmgw, pmga; color pmgc;"); Ln;
  W("vardef pmgp(expr a, b) = (a, -b) enddef;"); Ln;
  W("vardef pmgwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;"); Ln;
  (* the box at (x, y), w by h, its corners rounded r *)
  W("vardef pmgbox(expr x, y, w, h, r) ="); Ln;
  W("  if r > 0: (x + r, -y) -- (x + w - r, -y) {right} .. {down} (x + w, -y - r)"); Ln;
  W("    -- (x + w, -y - h + r) {down} .. {left} (x + w - r, -y - h)"); Ln;
  W("    -- (x + r, -y - h) {left} .. {up} (x, -y - h + r)"); Ln;
  W("    -- (x, -y - r) {up} .. {right} cycle"); Ln;
  W("  else: (x, -y) -- (x + w, -y) -- (x + w, -y - h) -- (x, -y - h) -- cycle fi"); Ln;
  W("enddef;"); Ln;
  (* the picture p at (x, y): its middle (a = 1), or the middle of its
     left (0) or right (2) side, in the colour c *)
  W("def pmgtext(expr p, x, y, a, c) ="); Ln;
  W("  draw p shifted (pmgp(x, y) - (if a = 0: xpart llcorner p elseif a = 2: xpart urcorner p");
  Ln;
  W("    else: xpart center p fi, ypart center p)) withcolor c;"); Ln;
  W("enddef;"); Ln;
  Background; Grid; Tasks; Sections; Today;
  IF l.title # NIL THEN Text(l.title, l.titleX, l.titleY, GP.t.title, l.titleSize, Centre) END;
  W("setbounds currentpicture to pmgp(0, 0) -- pmgp("); Pt(l.width); W(", 0) -- pmgp(");
  Pt(l.width); W(", "); Pt(l.height); W(") -- pmgp(0, "); Pt(l.height); W(") -- cycle;"); Ln;
  W("\stopMPcode"); Ln
END Write;

END PmGanttMp.
