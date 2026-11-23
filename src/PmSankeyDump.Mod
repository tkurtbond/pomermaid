MODULE PmSankeyDump;
(* PmSankeyDump: a sankey diagram's model, PmSankey's, written as text,
   one line for the title, each configuration value, the diagram's
   configuration, each node and each link, for the tests (-t dump); and
   its layout, PmSankeyLayout's (-t layout) *)

IMPORT PmIO, Y := PmYaml, K := PmSankey, X := PmXy, D := PmDump, KL := PmSankeyLayout,
  P := PmPic, G := PmGeom;

PROCEDURE Num(name: ARRAY OF CHAR; x: LONGREAL);
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  X.JsNumber(x, s);
  PmIO.WriteChar(" ");
  IF name # "" THEN PmIO.WriteString(name); PmIO.WriteChar("=") END;
  PmIO.WriteString(s)
END Num;

PROCEDURE Bool(name: ARRAY OF CHAR; b: BOOLEAN);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF b THEN PmIO.WriteString("true") ELSE PmIO.WriteString("false") END
END Bool;

PROCEDURE Colour(name: ARRAY OF CHAR; c: LONGINT);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF c < 0 THEN PmIO.WriteString("none") ELSE PmIO.WriteChar("#"); P.Hex(c, 6) END
END Colour;

(* Writes d's model *)
PROCEDURE Write*(d: K.Diagram);
  VAR q: Y.Pair; n: K.Node; k: K.Link;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("sankey");
  Num("width", d.width); Num("height", d.height);
  Num("nodeWidth", d.nodeWidth); Num("nodePadding", d.nodePadding);
  PmIO.WriteString(" nodeAlignment=");
  IF d.align = K.Left THEN PmIO.WriteString("left")
  ELSIF d.align = K.Right THEN PmIO.WriteString("right")
  ELSIF d.align = K.Center THEN PmIO.WriteString("center")
  ELSE PmIO.WriteString("justify")
  END;
  Bool("showValues", d.showValues);
  PmIO.WriteString(" prefix="); D.Quoted(d.prefix);
  PmIO.WriteString(" suffix="); D.Quoted(d.suffix);
  IF d.outlined THEN PmIO.WriteString(" labelStyle=outlined")
  ELSE PmIO.WriteString(" labelStyle=legacy")
  END;
  PmIO.WriteString(" linkColor=");
  IF d.linkColor = K.Gradient THEN PmIO.WriteString("gradient")
  ELSIF d.linkColor = K.Source THEN PmIO.WriteString("source")
  ELSIF d.linkColor = K.Target THEN PmIO.WriteString("target")
  ELSE D.Quoted(d.linkText); Colour("rgb", d.linkRgb)
  END;
  PmIO.WriteLn;
  n := d.nodes;
  WHILE n # NIL DO
    PmIO.WriteString("node "); PmIO.WriteInt(n.index); PmIO.WriteChar(" "); D.Quoted(n.name);
    IF n.colour >= 0 THEN Colour("colour", n.colour) END;
    PmIO.WriteLn;
    n := n.next
  END;
  k := d.links;
  WHILE k # NIL DO
    PmIO.WriteString("link "); PmIO.WriteInt(k.source.index); PmIO.WriteString(" -> ");
    PmIO.WriteInt(k.target.index); Num("value", k.value); PmIO.WriteLn;
    k := k.next
  END
END Write;

PROCEDURE Real(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Real;

PROCEDURE Pt(name: ARRAY OF CHAR; p: G.Point);
BEGIN
  PmIO.WriteChar(" ");
  IF name # "" THEN PmIO.WriteString(name); PmIO.WriteChar("=") END;
  PmIO.WriteChar("(");
  PmIO.WriteReal(p.x, 2); PmIO.WriteChar(","); PmIO.WriteReal(p.y, 2); PmIO.WriteChar(")")
END Pt;

(* Writes the layout l (-t layout): its size and each item, in drawing
   order, in points, rounded to 2 decimals; a link by its centre line *)
PROCEDURE WriteLayout*(l: KL.Layout);
  VAR it: KL.Item; p: G.Point;
BEGIN
  PmIO.WriteString("layout"); Real("width", l.width); Real("height", l.height); PmIO.WriteLn;
  it := l.items;
  WHILE it # NIL DO
    IF it.kind = KL.Link THEN
      PmIO.WriteString("link"); Pt("from", it.e[0]); Pt("to", it.e[1]); Real("width", it.width);
      Colour("from", it.fill); Colour("to", it.line)
    ELSIF it.kind = KL.Rect THEN
      G.Set(p, it.x, it.y);
      PmIO.WriteString("rect"); Pt("at", p); Real("w", it.w); Real("h", it.h);
      Colour("fill", it.fill)
    ELSE
      G.Set(p, it.x, it.y);
      PmIO.WriteString("text"); Pt("at", p); Real("size", it.size); Real("w", it.w);
      IF it.anchor = KL.Start THEN PmIO.WriteString(" start") ELSE PmIO.WriteString(" end") END;
      Colour("colour", it.line); D.Label("text", it.lab)
    END;
    PmIO.WriteLn;
    it := it.next
  END
END WriteLayout;

END PmSankeyDump.
