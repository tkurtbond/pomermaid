MODULE PmSeqMp;
(* PmSeqMp: a sequence diagram written in MetaPost, for ConTeXt: a
   \startMPcode block that the macros of mp/pomermaid-seq.mp lay out
   and draw.

   This writes the diagram, not its layout, as calls of the macros:
   the colours, the participants, the boxes and the events, in order.
   The macros set the text in the document's font and lay the diagram
   out as PmSeqLayout does, with those sizes, then draw it as PmSeqPic
   does.

   The macros are copied into the block (PmSeqMacros, made from
   mp/pomermaid-seq.mp), or, with input set, "input pomermaid-seq ;" is
   written, for a document that has pomermaid-seq.mp where ConTeXt
   finds it. Text is written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, S := PmStyle, Q := PmSeq, PmMp, PmSeqMacros;

CONST
  BoxLine = 0808080H;   (* a box's outline, as PmSeqPic's *)

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

PROCEDURE I(n: LONGINT);
BEGIN
  PmIO.WriteInt(n)
END I;

PROCEDURE C;
BEGIN
  W(", ")
END C;

PROCEDURE B(b: BOOLEAN);
BEGIN
  IF b THEN W("1") ELSE W("0") END
END B;

(* The index of the colour rgb, or -1 for none *)
PROCEDURE Col(rgb: LONGINT): INTEGER;
BEGIN
  IF rgb < 0 THEN RETURN -1 ELSE RETURN S.Colour(rgb) END
END Col;

PROCEDURE Ix(e: Q.Event): INTEGER;
BEGIN
  IF e = NIL THEN RETURN -1 ELSE RETURN e.index END
END Ix;

(* Writes d's sequence diagram as a \startMPcode block, its labels at
   size points; wider than maxW points (0 for no limit), it is scaled
   down to maxW. With input, the macros are input, not copied. *)
PROCEDURE Write*(d: Q.Diagram; size, maxW: REAL; input: BOOLEAN);
  VAR
    t: S.SeqTheme; a: Q.Actor; bx: Q.Box; e: Q.Event; k: INTEGER; rgb: LONGINT;
    th: ARRAY 19 OF INTEGER;
BEGIN
  S.Reset(d.g, size / 16); S.SeqColours(t);
  th[0] := Col(t.actorFill); th[1] := Col(t.actorLine); th[2] := Col(t.actorText);
  th[3] := Col(t.lifeline); th[4] := Col(t.signal); th[5] := Col(t.signalText);
  th[6] := Col(t.labelFill); th[7] := Col(t.labelLine); th[8] := Col(t.labelText);
  th[9] := Col(t.loopText); th[10] := Col(t.noteFill); th[11] := Col(t.noteLine);
  th[12] := Col(t.noteText); th[13] := Col(t.barFill); th[14] := Col(t.barLine);
  th[15] := Col(t.number); th[16] := Col(t.numberText); th[17] := Col(t.title);
  th[18] := Col(BoxLine);
  (* the boxes' and rects' fills, so that all the colours come first *)
  bx := d.boxes;
  WHILE bx # NIL DO k := Col(bx.fill); bx := bx.next END;
  e := d.events;
  WHILE e # NIL DO
    IF (e.kind = Q.BlockStart) & (e.block = Q.Rect) THEN k := Col(e.fill) END;
    e := e.next
  END;
  W("\startMPcode"); PmIO.WriteLn;
  IF input THEN W("input pomermaid-seq ;"); PmIO.WriteLn ELSE PmSeqMacros.Write END;
  W("pms_begin("); PmIO.WriteReal(maxW, 3); C; I(d.nActors); C; I(d.nEvents); C;
  I(d.nBoxes); C; B(d.mirror); W(");"); PmIO.WriteLn;
  FOR k := 0 TO S.nColours - 1 DO
    rgb := S.Rgb(k);
    W("pms_colour("); I(k); C; PmIO.WriteReal(rgb DIV 10000H / 255, 4); C;
    PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); C;
    PmIO.WriteReal(rgb MOD 100H / 255, 4); W(");"); PmIO.WriteLn
  END;
  W("pms_theme(");
  FOR k := 0 TO 18 DO
    IF k > 0 THEN C END;
    I(th[k])
  END;
  W(");"); PmIO.WriteLn;
  bx := d.boxes;
  WHILE bx # NIL DO
    W("pms_box("); I(bx.index); C; I(Col(bx.fill)); C; PmMp.Label(bx.title); W(");");
    PmIO.WriteLn;
    bx := bx.next
  END;
  a := d.actors;
  WHILE a # NIL DO
    W("pms_actor("); I(a.index); C; I(a.type); C;
    IF a.box = NIL THEN I(-1) ELSE I(a.box.index) END; C;
    I(Ix(a.created)); C; I(Ix(a.destroyed)); C; PmMp.Label(a.label); W(");");
    PmIO.WriteLn;
    a := a.next
  END;
  e := d.events;
  WHILE e # NIL DO
    CASE e.kind OF
      Q.Msg:
        W("pms_msg("); I(e.index); C; I(e.from.index); C; I(e.to.index); C;
        B(e.dotted); C; I(e.head); C; I(e.tail); C; B(e.activate); C;
        B(Q.CentralTo IN e.central); C; B(Q.CentralFrom IN e.central); C;
        IF e.number = NIL THEN W('""') ELSE PmMp.Label(F.PlainLabel(e.number)) END; C;
        PmMp.Label(e.text)
    | Q.Note:
        W("pms_note("); I(e.index); C; I(e.from.index); C; I(e.to.index); C;
        I(e.placement); C; PmMp.Label(e.text)
    | Q.BlockStart:
        W("pms_start("); I(e.index); C; I(e.block); C; I(Col(e.fill)); C;
        PmMp.Label(e.text)
    | Q.Section:
        W("pms_else("); I(e.index); C; PmMp.Label(e.text)
    | Q.BlockEnd:
        W("pms_stop("); I(e.index)
    | Q.Activate:
        W("pms_activate("); I(e.index); C; I(e.from.index)
    | Q.Deactivate:
        W("pms_deactivate("); I(e.index); C; I(e.from.index)
    END;
    W(");"); PmIO.WriteLn;
    e := e.next
  END;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    W("pms_title := "); PmMp.Label(d.g.title); W(";"); PmIO.WriteLn
  END;
  W("pms_end;"); PmIO.WriteLn;
  W("\stopMPcode"); PmIO.WriteLn
END Write;

END PmSeqMp.
