MODULE PmTimelineDump;
(* PmTimelineDump: a timeline's model, PmTimeline's, written as text,
   one line for the title, each configuration value, the direction,
   each section and each period, with its events, for the tests
   (-t dump); and its layout, PmTimelineLayout's (-t layout) *)

IMPORT PmIO, Y := PmYaml, T := PmTimeline, D := PmDump, TL := PmTimelineLayout;

(* Writes d's model *)
PROCEDURE Write*(d: T.Diagram);
  VAR q: Y.Pair; s: T.Section; p: T.Period; k: INTEGER;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  IF d.td THEN PmIO.WriteString("direction TD") ELSE PmIO.WriteString("direction LR") END;
  IF ~d.multicolor THEN PmIO.WriteString(" multicolor=false") END;
  PmIO.WriteLn;
  s := d.sections;
  WHILE s # NIL DO
    PmIO.WriteString("section "); PmIO.WriteInt(s.index);
    PmIO.WriteString(" periods=");
    IF s.count = 0 THEN PmIO.WriteString("none") END;
    FOR k := 0 TO s.count - 1 DO
      IF k > 0 THEN PmIO.WriteChar(",") END;
      PmIO.WriteInt(s.periods[k].index)
    END;
    D.Label("text", s.text); PmIO.WriteLn;
    s := s.next
  END;
  p := d.periods;
  WHILE p # NIL DO
    PmIO.WriteString("period "); PmIO.WriteInt(p.index);
    IF p.section # NIL THEN PmIO.WriteString(" section="); PmIO.WriteInt(p.section.index) END;
    D.Label("text", p.text); PmIO.WriteLn;
    FOR k := 0 TO p.nEvents - 1 DO
      PmIO.WriteString("  event "); PmIO.WriteInt(k); D.Label("text", p.events[k]); PmIO.WriteLn
    END;
    p := p.next
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

(* Writes the layout l (-t layout): its size; the title; each node's
   kind, colour, box and the lines of its text; each dashed line; the
   activity line or axis; in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: TL.Layout);
  VAR i: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Num("width", l.width); Num("height", l.height); PmIO.WriteLn;
  IF l.title # NIL THEN
    PmIO.WriteString("title"); Pt("at", l.titleX, l.titleY); Num("w", l.titleW); PmIO.WriteLn
  END;
  FOR i := 0 TO l.n - 1 DO
    CASE l.kind[i] OF
      TL.SectionNode: PmIO.WriteString("section")
    | TL.PeriodNode: PmIO.WriteString("period")
    | TL.EventNode: PmIO.WriteString("event")
    END;
    PmIO.WriteString(" colour="); PmIO.WriteInt(l.colour[i]);
    Pt("at", l.x[i], l.y[i]); Num("w", l.w[i]); Num("h", l.h[i]);
    D.Label("text", l.text[i]); PmIO.WriteLn
  END;
  FOR i := 0 TO l.nLines - 1 DO
    PmIO.WriteString("line"); Pt("from", l.x1[i], l.y1[i]); Pt("to", l.x2[i], l.y2[i]);
    PmIO.WriteLn
  END;
  IF l.d.td THEN PmIO.WriteString("axis") ELSE PmIO.WriteString("activity") END;
  Pt("from", l.ax1, l.ay1); Pt("to", l.ax2, l.ay2); PmIO.WriteLn
END WriteLayout;

END PmTimelineDump.
