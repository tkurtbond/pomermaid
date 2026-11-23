MODULE PmSeqDump;
(* PmSeqDump: a sequence diagram's model, PmSeq's, written as text,
   one line for the title, each configuration value, box, participant
   and event, for the tests (-t dump); and its layout, PmSeqLayout's
   (-t layout) *)

IMPORT PmIO, Y := PmYaml, F := PmFlow, Q := PmSeq, D := PmDump, SL := PmSeqLayout;

PROCEDURE Hex(n: LONGINT);
  VAR k: INTEGER; digit: LONGINT; s: ARRAY 7 OF CHAR;
BEGIN
  FOR k := 5 TO 0 BY -1 DO
    digit := n MOD 16; n := n DIV 16;
    IF digit < 10 THEN s[k] := CHR(ORD("0") + digit) ELSE s[k] := CHR(ORD("a") + digit - 10) END
  END;
  s[6] := 0X;
  PmIO.WriteChar("#"); PmIO.WriteString(s)
END Hex;

PROCEDURE Type(t: INTEGER);
BEGIN
  CASE t OF
    Q.Participant: PmIO.WriteString("participant")
  | Q.Person: PmIO.WriteString("actor")
  | Q.Boundary: PmIO.WriteString("boundary")
  | Q.Control: PmIO.WriteString("control")
  | Q.Entity: PmIO.WriteString("entity")
  | Q.Database: PmIO.WriteString("database")
  | Q.Collections: PmIO.WriteString("collections")
  | Q.Queue: PmIO.WriteString("queue")
  END
END Type;

PROCEDURE Head(h: INTEGER);
BEGIN
  CASE h OF
    Q.NoHead: PmIO.WriteString("none")
  | Q.Filled: PmIO.WriteString("filled")
  | Q.Open: PmIO.WriteString("open")
  | Q.Cross: PmIO.WriteString("cross")
  | Q.SolidTop: PmIO.WriteString("solid-top")
  | Q.SolidBottom: PmIO.WriteString("solid-bottom")
  | Q.StickTop: PmIO.WriteString("stick-top")
  | Q.StickBottom: PmIO.WriteString("stick-bottom")
  END
END Head;

PROCEDURE Block(b: INTEGER);
BEGIN
  CASE b OF
    Q.Loop: PmIO.WriteString("loop")
  | Q.Opt: PmIO.WriteString("opt")
  | Q.Alt: PmIO.WriteString("alt")
  | Q.Par: PmIO.WriteString("par")
  | Q.ParOver: PmIO.WriteString("par_over")
  | Q.Critical: PmIO.WriteString("critical")
  | Q.Break: PmIO.WriteString("break")
  | Q.Rect: PmIO.WriteString("rect")
  END
END Block;

(* Writes d's model *)
PROCEDURE Write*(d: Q.Diagram);
  VAR q: Y.Pair; b: Q.Box; a: Q.Actor; e: Q.Event;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  IF ~d.mirror THEN PmIO.WriteString("mirror off"); PmIO.WriteLn END;
  b := d.boxes;
  WHILE b # NIL DO
    PmIO.WriteString("box "); PmIO.WriteInt(b.index);
    IF b.fill # Q.NoColour THEN PmIO.WriteString(" fill="); Hex(b.fill) END;
    D.Label("title", b.title); PmIO.WriteLn;
    b := b.next
  END;
  a := d.actors;
  WHILE a # NIL DO
    PmIO.WriteString("participant "); D.Quoted(a.id);
    PmIO.WriteString(" type="); Type(a.type);
    IF a.box # NIL THEN PmIO.WriteString(" box="); PmIO.WriteInt(a.box.index) END;
    IF a.created # NIL THEN PmIO.WriteString(" created="); PmIO.WriteInt(a.created.index) END;
    IF a.destroyed # NIL THEN PmIO.WriteString(" destroyed="); PmIO.WriteInt(a.destroyed.index) END;
    D.Label("label", a.label); PmIO.WriteLn;
    a := a.next
  END;
  e := d.events;
  WHILE e # NIL DO
    PmIO.WriteInt(e.index); PmIO.WriteChar(" ");
    CASE e.kind OF
      Q.Msg:
        PmIO.WriteString("message "); D.Quoted(e.from.id); PmIO.WriteString(" -> ");
        D.Quoted(e.to.id);
        IF e.dotted THEN PmIO.WriteString(" dotted") END;
        PmIO.WriteString(" head="); Head(e.head);
        IF e.tail # Q.NoHead THEN PmIO.WriteString(" tail="); Head(e.tail) END;
        IF Q.CentralFrom IN e.central THEN PmIO.WriteString(" central-from") END;
        IF Q.CentralTo IN e.central THEN PmIO.WriteString(" central-to") END;
        IF e.activate THEN PmIO.WriteString(" activate") END;
        IF e.number # NIL THEN PmIO.WriteString(" number="); PmIO.WriteString(e.number^) END
    | Q.Note:
        PmIO.WriteString("note ");
        CASE e.placement OF
          Q.LeftOf: PmIO.WriteString("left of ")
        | Q.RightOf: PmIO.WriteString("right of ")
        | Q.Over: PmIO.WriteString("over ")
        END;
        D.Quoted(e.from.id);
        IF e.to # e.from THEN PmIO.WriteChar(","); D.Quoted(e.to.id) END
    | Q.BlockStart:
        PmIO.WriteString("start "); Block(e.block);
        IF e.fill # Q.NoColour THEN PmIO.WriteString(" fill="); Hex(e.fill) END
    | Q.Section: PmIO.WriteString("section "); Block(e.block)
    | Q.BlockEnd: PmIO.WriteString("end "); Block(e.block)
    | Q.Activate: PmIO.WriteString("activate "); D.Quoted(e.from.id)
    | Q.Deactivate: PmIO.WriteString("deactivate "); D.Quoted(e.from.id)
    END;
    D.Label("text", e.text); PmIO.WriteLn;
    e := e.next
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

(* Writes the layout l (-t layout): its size; each actor's centre,
   width, top, lifeline and footer; each box; each message's and note's
   points and text's centre; each frame with its sections; each
   activation bar; in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: SL.Layout);
  VAR i: INTEGER; e: Q.Event; g: SL.Geom; f: SL.Frame; s: SL.Section; b: SL.Bar;
BEGIN
  PmIO.WriteString("layout"); Num("width", l.width); Num("height", l.height);
  Num("actor-height", l.h); PmIO.WriteLn;
  IF (l.title # NIL) & (l.title.n > 0) THEN
    PmIO.WriteString("title"); Pt("at", l.titleX, l.titleY); PmIO.WriteLn
  END;
  FOR i := 0 TO l.d.nBoxes - 1 DO
    PmIO.WriteString("box "); PmIO.WriteInt(i); Pt("from", l.bx1[i], l.by1[i]);
    Pt("to", l.bx2[i], l.by2[i]); Pt("title", l.btx[i], l.bty[i]); PmIO.WriteLn
  END;
  FOR i := 0 TO l.d.nActors - 1 DO
    PmIO.WriteString("participant "); D.Quoted(l.actors[i].id);
    Num("x", l.x[i]); Num("w", l.w[i]); Num("top", l.top[i]); Num("label-y", l.ly[i]);
    Num("life", l.life1[i]); Num("to", l.life2[i]);
    IF l.footer[i] THEN Num("footer", l.foot[i]) END;
    PmIO.WriteLn
  END;
  FOR i := 0 TO l.d.nEvents - 1 DO
    e := l.events[i]; g := l.geom[i];
    IF e.kind = Q.Msg THEN
      PmIO.WriteInt(i);
      IF g.self THEN
        PmIO.WriteString(" self"); Pt("from", g.x1, g.y1); Num("out", g.x2); Num("back", g.x3);
        Num("down", g.y2)
      ELSE
        PmIO.WriteString(" message"); Pt("from", g.x1, g.y1); Pt("to", g.x2, g.y2)
      END;
      IF g.tw > 0 THEN Pt("text", g.tx, g.ty) END;
      PmIO.WriteLn
    ELSIF e.kind = Q.Note THEN
      PmIO.WriteInt(i); PmIO.WriteString(" note"); Pt("from", g.x1, g.y1); Pt("to", g.x2, g.y2);
      Pt("text", g.tx, g.ty); PmIO.WriteLn
    END
  END;
  f := l.frames;
  WHILE f # NIL DO
    PmIO.WriteString("frame "); Block(f.kind); Num("depth", f.depth);
    Pt("from", f.x1, f.y1); Pt("to", f.x2, f.y2);
    IF f.label # NIL THEN Num("label-w", f.lw); Num("label-h", f.lh) END;
    IF f.text # NIL THEN Pt("text", f.tx, f.ty) END;
    PmIO.WriteLn;
    s := f.sections;
    WHILE s # NIL DO
      PmIO.WriteString("section"); Num("y", s.y);
      IF s.text # NIL THEN Pt("text", s.tx, s.ty) END;
      PmIO.WriteLn; s := s.next
    END;
    f := f.next
  END;
  b := l.bars;
  WHILE b # NIL DO
    PmIO.WriteString("bar "); D.Quoted(l.actors[b.actor].id);
    Pt("from", b.x1, b.y1); Pt("to", b.x2, b.y2); PmIO.WriteLn;
    b := b.next
  END
END WriteLayout;

END PmSeqDump.
