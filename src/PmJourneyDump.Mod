MODULE PmJourneyDump;
(* PmJourneyDump: a user journey's model, PmJourney's, written as text,
   one line for the title, each configuration value, actor, section and
   task, for the tests (-t dump); and its layout, PmJourneyLayout's
   (-t layout) *)

IMPORT PmIO, Y := PmYaml, J := PmJourney, D := PmDump, JL := PmJourneyLayout;

(* Writes d's model *)
PROCEDURE Write*(d: J.Diagram);
  VAR q: Y.Pair; s: J.Section; t: J.Task; k: INTEGER;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  FOR k := 0 TO d.nActors - 1 DO
    PmIO.WriteString("actor "); PmIO.WriteInt(k); PmIO.WriteChar(" "); D.Quoted(d.actors[k]);
    PmIO.WriteLn
  END;
  s := d.sections;
  WHILE s # NIL DO
    PmIO.WriteString("section "); PmIO.WriteInt(s.index);
    PmIO.WriteString(" tasks="); PmIO.WriteInt(s.first); PmIO.WriteString("..");
    PmIO.WriteInt(s.first + s.count - 1); D.Label("text", s.text); PmIO.WriteLn;
    s := s.next
  END;
  t := d.tasks;
  WHILE t # NIL DO
    PmIO.WriteString("task "); PmIO.WriteInt(t.index);
    PmIO.WriteString(" score="); PmIO.WriteReal(t.score, 4);
    IF t.section # NIL THEN PmIO.WriteString(" section="); PmIO.WriteInt(t.section.index) END;
    IF t.nPeople > 0 THEN
      PmIO.WriteString(" people=");
      FOR k := 0 TO t.nPeople - 1 DO
        IF k > 0 THEN PmIO.WriteChar(",") END;
        PmIO.WriteInt(t.people[k])
      END
    END;
    D.Label("text", t.text); PmIO.WriteLn;
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

(* Writes the layout l (-t layout): its size; the title; each actor's
   circle and name; each section's and task's box, with the lines of
   its text; each face; the activity line; in points, rounded to 2
   decimals *)
PROCEDURE WriteLayout*(l: JL.Layout);
  VAR i: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Num("width", l.width); Num("height", l.height);
  Num("left", l.left); Num("top", l.top); PmIO.WriteLn;
  IF l.title # NIL THEN
    PmIO.WriteString("title"); Pt("at", l.titleX, l.titleY); Num("w", l.titleW); PmIO.WriteLn
  END;
  FOR i := 0 TO l.d.nActors - 1 DO
    PmIO.WriteString("actor "); PmIO.WriteInt(i); Pt("circle", l.cx[i], l.cy[i]);
    Pt("name", l.nx[i], l.ny[i]); PmIO.WriteString(" lines="); PmIO.WriteInt(l.names[i].n);
    PmIO.WriteLn
  END;
  FOR i := 0 TO l.d.nSections - 1 DO
    PmIO.WriteString("section "); PmIO.WriteInt(i); Pt("at", l.sx[i], l.sy[i]);
    Num("w", l.sw[i]); Num("h", l.sh[i]); D.Label("text", l.stext[i]); PmIO.WriteLn
  END;
  FOR i := 0 TO l.d.nTasks - 1 DO
    PmIO.WriteString("task "); PmIO.WriteInt(i); Pt("at", l.tx[i], l.ty[i]);
    Num("w", l.tw[i]); Num("h", l.th[i]); Pt("face", l.fx[i], l.fy[i]);
    D.Label("text", l.ttext[i]); PmIO.WriteLn
  END;
  PmIO.WriteString("lines"); Num("from", l.lineY1); Num("to", l.lineY2); PmIO.WriteLn;
  PmIO.WriteString("activity"); Pt("from", l.ax1, l.ay); Pt("to", l.ax2, l.ay); PmIO.WriteLn
END WriteLayout;

END PmJourneyDump.
