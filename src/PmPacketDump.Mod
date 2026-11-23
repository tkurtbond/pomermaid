MODULE PmPacketDump;
(* PmPacketDump: a packet diagram's model, PmPacket's, written as text,
   one line for each configuration value, the diagram's options, each
   row and each field's part in it, for the tests (-t dump); its layout
   is written by PmDrawDump *)

IMPORT PmIO, Y := PmYaml, P := PmPacket, X := PmXy, D := PmDump;

PROCEDURE Num(name: ARRAY OF CHAR; x: LONGREAL);
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  X.JsNumber(x, s);
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteString(s)
END Num;

PROCEDURE Int(name: ARRAY OF CHAR; n: LONGINT);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteInt(n)
END Int;

(* Writes d's model *)
PROCEDURE Write*(d: P.Diagram);
  VAR q: Y.Pair; w: P.Word; b: P.Block; k: LONGINT;
BEGIN
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("packet");
  Int("bitsPerRow", d.bitsPerRow); Num("rowHeight", d.rowHeight); Num("bitWidth", d.bitWidth);
  Num("paddingX", d.paddingX); Num("paddingY", d.paddingY);
  IF d.showBits THEN PmIO.WriteString(" showBits=true") ELSE PmIO.WriteString(" showBits=false") END;
  IF d.descending THEN PmIO.WriteString(" bitOrder=descending")
  ELSE PmIO.WriteString(" bitOrder=ascending")
  END;
  Int("fields", d.nFields); Int("rows", d.nWords);
  D.Label("title", d.g.title);
  PmIO.WriteLn;
  w := d.words; k := 0;
  WHILE w # NIL DO
    PmIO.WriteString("row "); PmIO.WriteInt(k); Int("blocks", w.nBlocks); PmIO.WriteLn;
    b := w.blocks;
    WHILE b # NIL DO
      PmIO.WriteString("  block"); Int("start", b.start); Int("end", b.end);
      Int("bits", b.end - b.start + 1);
      PmIO.WriteString(" text="); D.Quoted(b.text);
      D.Label("label", b.label);
      PmIO.WriteLn;
      b := b.next
    END;
    w := w.next; INC(k)
  END
END Write;

END PmPacketDump.
