MODULE PmGanttDump;
(* PmGanttDump: a Gantt chart's model, PmGantt's, written as text, one
   line for the title, each configuration value, the settings, each
   section and each task, with its dates in local time, for the tests
   (-t dump) *)

IMPORT PmIO, L := PmLex, Y := PmYaml, G := PmGantt, T := PmGanttTime, D := PmDump,
  GL := PmGanttLayout;

PROCEDURE Date(name: ARRAY OF CHAR; t: HUGEINT);
  VAR s: L.Str;
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF T.Format(t, "YYYY-MM-DDTHH:mm:ss.SSS", s) THEN PmIO.WriteString(s^) END
END Date;

PROCEDURE Setting(name: ARRAY OF CHAR; s: L.Str);
BEGIN
  IF s # NIL THEN
    PmIO.WriteString(name); PmIO.WriteChar(" "); D.Quoted(s); PmIO.WriteLn
  END
END Setting;

PROCEDURE Words(name: ARRAY OF CHAR; w: G.Word);
BEGIN
  IF w # NIL THEN
    PmIO.WriteString(name);
    WHILE w # NIL DO PmIO.WriteChar(" "); D.Quoted(w.s); w := w.next END;
    PmIO.WriteLn
  END
END Words;

PROCEDURE Tag(on: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  IF on THEN PmIO.WriteChar(" "); PmIO.WriteString(name) END
END Tag;

(* Writes d's model *)
PROCEDURE Write*(d: G.Diagram);
  VAR q: Y.Pair; w: G.Word; t: G.Task; n: LONGINT;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  Setting("dateFormat", d.dateFormat);
  Setting("axisFormat", d.axisFormat);
  Setting("tickInterval", d.tickInterval);
  IF d.todayMarker[0] # 0X THEN Setting("todayMarker", d.todayMarker) END;
  Words("includes", d.includes);
  Words("excludes", d.excludes);
  PmIO.WriteString("weekday "); PmIO.WriteInt(d.weekday);
  PmIO.WriteString(" weekend "); PmIO.WriteInt(d.weekend);
  Tag(d.inclusiveEndDates, "inclusiveEndDates"); Tag(d.topAxis, "topAxis");
  Tag(d.compact, "compact");
  PmIO.WriteLn;
  w := d.sections; n := 0;
  WHILE w # NIL DO
    PmIO.WriteString("section "); PmIO.WriteInt(n); PmIO.WriteChar(" "); D.Quoted(w.s);
    PmIO.WriteLn; INC(n); w := w.next
  END;
  t := d.tasks;
  WHILE t # NIL DO
    PmIO.WriteString("task "); PmIO.WriteInt(t.index);
    PmIO.WriteString(" id="); D.Quoted(t.id);
    PmIO.WriteString(" order="); PmIO.WriteInt(t.order);
    IF t.section[0] # 0X THEN PmIO.WriteString(" section="); D.Quoted(t.section) END;
    Date("start", t.start); Date("end", t.end);
    IF t.hasRenderEnd THEN Date("renderEnd", t.renderEnd) END;
    Tag(t.active, "active"); Tag(t.done, "done"); Tag(t.crit, "crit");
    Tag(t.milestone, "milestone"); Tag(t.vert, "vert"); Tag(t.clickable, "clickable");
    IF t.link # NIL THEN PmIO.WriteString(" link="); D.Quoted(t.link) END;
    PmIO.WriteString(" text="); D.Quoted(t.text);
    PmIO.WriteLn;
    t := t.next
  END
END Write;

PROCEDURE Num(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Num;

PROCEDURE Pt(name: ARRAY OF CHAR; x, y: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteString("=(");
  PmIO.WriteReal(x, 2); PmIO.WriteChar(","); PmIO.WriteReal(y, 2); PmIO.WriteChar(")")
END Pt;

(* Writes the layout l (-t layout): its size; the excluded days; the
   ticks; the background rows; each task's box, colour and text; the
   section names; the title; the today line; in points, rounded to 2
   decimals *)
PROCEDURE WriteLayout*(l: GL.Layout);
  VAR i: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Num("width", l.width); Num("height", l.height);
  Num("px", l.px); PmIO.WriteLn;
  IF l.nEx > 0 THEN
    PmIO.WriteString("excludes"); Num("y", l.exY); Num("h", l.exH); PmIO.WriteLn;
    FOR i := 0 TO l.nEx - 1 DO
      PmIO.WriteString("exclude"); Num("x", l.exX[i]); Num("w", l.exW[i]); PmIO.WriteLn
    END
  END;
  PmIO.WriteString("grid"); Num("y1", l.gridY1); Num("y2", l.gridY2); Num("labelY", l.labelY);
  Num("size", l.tickSize);
  IF l.topAxis THEN
    PmIO.WriteString(" top"); Num("y1", l.topY1); Num("y2", l.topY2); Num("labelY", l.topLabelY)
  END;
  PmIO.WriteLn;
  FOR i := 0 TO l.nTicks - 1 DO
    PmIO.WriteString("tick"); Num("x", l.tickX[i]); PmIO.WriteChar(" "); D.Quoted(l.tickLabel[i]);
    PmIO.WriteLn
  END;
  PmIO.WriteString("rows"); Num("w", l.rowW); Num("h", l.rowH); PmIO.WriteLn;
  FOR i := 0 TO l.nRows - 1 DO
    PmIO.WriteString("row colour="); PmIO.WriteInt(l.rowColour[i]); Num("y", l.rowY[i]); PmIO.WriteLn
  END;
  FOR i := 0 TO l.nTasks - 1 DO
    IF l.task[i].vert THEN PmIO.WriteString("vert")
    ELSIF l.task[i].milestone THEN PmIO.WriteString("milestone")
    ELSE PmIO.WriteString("task")
    END;
    PmIO.WriteString(" colour="); PmIO.WriteInt(l.colour[i]);
    Pt("at", l.bx[i], l.by[i]); Num("w", l.bw[i]); Num("h", l.bh[i]);
    CASE l.place[i] OF
      GL.Inside: PmIO.WriteString(" inside")
    | GL.OutsideRight: PmIO.WriteString(" right")
    | GL.OutsideLeft: PmIO.WriteString(" left")
    | GL.VertText: PmIO.WriteString(" vert")
    END;
    Pt("text", l.tx[i], l.ty[i]); Num("size", l.tsize[i]);
    D.Label("text", l.text[i]); PmIO.WriteLn
  END;
  FOR i := 0 TO l.nSections - 1 DO
    PmIO.WriteString("section colour="); PmIO.WriteInt(l.secColour[i]);
    Pt("at", l.secX, l.secY[i]); Num("size", l.secSize); D.Label("text", l.secText[i]); PmIO.WriteLn
  END;
  IF l.title # NIL THEN
    PmIO.WriteString("title"); Pt("at", l.titleX, l.titleY); Num("size", l.titleSize); PmIO.WriteLn
  END;
  IF l.today THEN
    PmIO.WriteString("today"); Pt("from", l.todayX, l.todayY1); Pt("to", l.todayX, l.todayY2);
    IF l.todayStyle[0] # 0X THEN PmIO.WriteChar(" "); D.Quoted(l.todayStyle) END;
    PmIO.WriteLn
  END
END WriteLayout;

END PmGanttDump.
