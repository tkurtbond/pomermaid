MODULE PmC4Layout;
(* PmC4Layout: a C4 diagram, PmC4's, laid out in Mermaid's pixels,
   taken at the drawing's size, 16 pixels to the size, and drawn as
   Mermaid 12.3.0's C4 renderer draws it. Lengths are in pixels, y
   down.

   The placement is Mermaid's grid (c4Renderer.ts): the boundaries,
   from "global" down, each placed below its parent's last row, or
   beside the one before it while fewer than c4BoundaryInRow are in
   the row; in each, its elements in rows of at most c4ShapeInRow,
   c4ShapeMargin apart, a new row too where the next would reach the
   boundary's width limit, its parent's divided among the boundaries
   in a row, 1920 pixels at the top (decision 57); then the boundaries
   inside it. The count of elements in a row carries on from one
   boundary to the next at the same depth, as in Mermaid.

   An element is its name, bold, its stereotype ("[Software System]",
   "[Container: techn]") and its description, smaller, each centred
   and wrapped at the element's text width when config.c4.wrap is not
   false, in white or its fontColor; in a person (a rounded body under
   a head), a rounded box, a cylinder (a database), a cylinder on its
   side (a queue) or a box with lines inside its ends (a component),
   chosen by its shape, sprite or tags, or its type. The colours are
   config.c4's <type>_bg_color and <type>_border_color, or its
   bgColor and borderColor; a curved outline is drawn as a polygon.

   A boundary is a box, dashed unless it is a deployment node, its
   label, bold, "[type]" and description at its top. pomermaid draws
   the boundaries beneath the elements; Mermaid draws them over them
   (decision 59).

   A relationship runs between the edges of its ends, toward their
   middles: the first a line, the others curves; with an arrowhead at
   its end, but at its start for Rel_Back, and at both for BiRel. Its
   label, numbered in C4Dynamic, starts at its middle, moved by
   offsetX and offsetY, and its technology is under it in italics. *)

IMPORT MathL, M := PmMetrics, F := PmFlow, S := PmStyle, C := PmC4, D := PmDraw,
  FL := PmFlowLayout, L := PmLex, Y := PmYaml;

CONST
  (* the shapes *)
  kRounded = 0; kPerson = 1; kCylinder = 2; kHCyl = 3; kComponent = 4;
  Grey = 444444H; White = 0FFFFFFH;
  NSamples = 24;    (* points to a quarter ellipse, for a filled outline *)
  MaxPts = 256;

TYPE
  Str = L.Str;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: C.Diagram
  END;

  (* An element's shape, size and texts *)
  Elem = RECORD
    kind: INTEGER;
    x, y, w, h: LONGREAL;          (* its box, from its top left *)
    lab: ARRAY 3 OF F.Label;       (* name, stereotype, description *)
    lh, ls: ARRAY 3 OF LONGREAL;   (* their heights and sizes *)
    bh: LONGREAL;                  (* the texts' height *)
    a, b: LONGREAL;                (* a person's body height; a cylinder's rx and ry *)
    fill, line, text: LONGINT;
    placed: BOOLEAN
  END;
  Elems = POINTER TO ARRAY OF Elem;

  Bound = RECORD
    x, y, w, h: LONGREAL;
    lab: ARRAY 3 OF F.Label;       (* label, type, description *)
    ly, ls: ARRAY 3 OF LONGREAL;   (* their middles below the top, and sizes *)
    placed, boxed: BOOLEAN
  END;
  Bounds = POINTER TO ARRAY OF Bound;

  (* Mermaid's Bounds: data and nextData *)
  Box = RECORD
    x0, x1, y0, y1, limit: LONGREAL;
    nx0, nx1, ny0, ny1: LONGREAL;
    cnt: LONGINT
  END;

VAR
  l: Layout;
  d: C.Diagram;
  el: Elems;
  bd: Bounds;
  maxX, maxY: LONGREAL;              (* globalBoundaryMaxX and Y *)
  marginX, marginY, shapeMargin, padding, width, bfs, mfs: LONGREAL;
  wrap: BOOLEAN;
  px, py: ARRAY MaxPts OF LONGREAL; np: INTEGER;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a ELSE RETURN b END
END Max;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a ELSE RETURN b END
END Min;

(* The configuration *)

(* name, "config.c4." and s, in n *)
PROCEDURE Name(s, t: ARRAY OF CHAR; VAR n: ARRAY OF CHAR);
  VAR i, j: INTEGER; p: ARRAY 12 OF CHAR;
BEGIN
  p := "config.c4."; i := 0;
  WHILE p[i] # 0X DO n[i] := p[i]; INC(i) END;
  j := 0; WHILE (j < LEN(s)) & (s[j] # 0X) & (i < LEN(n) - 1) DO n[i] := s[j]; INC(i); INC(j) END;
  j := 0; WHILE (j < LEN(t)) & (t[j] # 0X) & (i < LEN(n) - 1) DO n[i] := t[j]; INC(i); INC(j) END;
  n[i] := 0X
END Name;

(* config.c4.s t, a number, or default *)
PROCEDURE Conf(s, t: ARRAY OF CHAR; default: LONGREAL): LONGREAL;
  VAR q: Y.Pair; i: LONGINT; x, f: LONGREAL; neg, digits: BOOLEAN; v: Str; n: ARRAY 96 OF CHAR;
BEGIN
  Name(s, t, n);
  q := Y.Find(d.g.config, n);
  IF q = NIL THEN RETURN default END;
  v := q.value; i := 0; x := 0; neg := FALSE; digits := FALSE;
  WHILE L.IsBlank(v[i]) DO INC(i) END;
  IF (v[i] = "-") OR (v[i] = "+") THEN neg := v[i] = "-"; INC(i) END;
  WHILE L.IsDigit(v[i]) DO x := x * 10 + (ORD(v[i]) - ORD("0")); INC(i); digits := TRUE END;
  IF v[i] = "." THEN
    INC(i); f := 0.1D0;
    WHILE L.IsDigit(v[i]) DO x := x + f * (ORD(v[i]) - ORD("0")); f := f / 10; INC(i); digits := TRUE END
  END;
  WHILE L.IsBlank(v[i]) DO INC(i) END;
  IF ~digits OR (v[i] # 0X) OR neg OR (x > 10000) THEN RETURN default END;
  RETURN x
END Conf;

(* The colour s, or default if s is NIL or not a colour; -1 for none *)
PROCEDURE Colour(s: Str; default: LONGINT): LONGINT;
  VAR rgb: LONGINT; none: BOOLEAN;
BEGIN
  IF (s = NIL) OR ~S.ParseColour(s^, rgb, none) THEN RETURN default END;
  IF none THEN RETURN -1 END;
  RETURN rgb
END Colour;

(* The colour config.c4.<type>_<what>_color, or default *)
PROCEDURE ConfColour(type: Str; what: ARRAY OF CHAR; default: LONGINT): LONGINT;
  VAR q: Y.Pair; n: ARRAY 96 OF CHAR;
BEGIN
  Name(type^, what, n);
  q := Y.Find(d.g.config, n);
  IF q = NIL THEN RETURN default END;
  RETURN Colour(q.value, default)
END ConfColour;

(* Texts *)

(* lab with every byte in style st *)
PROCEDURE Styled(lab: F.Label; st: SHORTINT): F.Label;
  VAR r: F.Label; line, nl, last: F.Line; k, len: LONGINT;
BEGIN
  NEW(r); r^ := lab^; r.lines := NIL; last := NIL;
  line := lab.lines;
  WHILE line # NIL DO
    NEW(nl); nl^ := line^; nl.next := NIL;
    len := 0; WHILE line.text[len] # 0X DO INC(len) END;
    NEW(nl.style, len + 1);
    FOR k := 0 TO len - 1 DO nl.style[k] := st END;
    nl.style[len] := F.Roman;
    IF last = NIL THEN r.lines := nl ELSE last.next := nl END;
    last := nl;
    line := line.next
  END;
  RETURN r
END Styled;

(* s as a label in style st, size pixels, wrapped at maxW if maxW > 0,
   and its size, w by h; NIL or empty is an empty label, 0 by 0 *)
PROCEDURE Text(s: Str; st: SHORTINT; size, maxW: LONGREAL; VAR w, h: LONGREAL): F.Label;
  VAR lab: F.Label;
BEGIN
  IF (s = NIL) OR (s[0] = 0X) THEN
    NEW(lab); lab.lines := NIL; lab.n := 0; lab.markdown := FALSE; w := 0; h := 0;
    RETURN lab
  END;
  lab := F.PlainLabel(s);
  IF st # F.Roman THEN lab := Styled(lab, st) END;
  IF maxW > 0 THEN lab := FL.Wrap(l.font, lab, SHORT(size * l.px), SHORT(maxW * l.px)) END;
  D.Measure(l, lab, size, w, h);
  RETURN lab
END Text;

(* "[" s "]", or s, if brackets, after prefix p and s *)
PROCEDURE Join(p: ARRAY OF CHAR; s: Str; q: ARRAY OF CHAR; brackets: BOOLEAN): Str;
  VAR r: Str; n, i: LONGINT;
BEGIN
  NEW(r, L.Length(p) + L.Length(s^) + L.Length(q) + 3); n := 0;
  IF brackets THEN r[n] := "["; INC(n) END;
  i := 0; WHILE (i < LEN(p)) & (p[i] # 0X) DO r[n] := p[i]; INC(n); INC(i) END;
  i := 0; WHILE s[i] # 0X DO r[n] := s[i]; INC(n); INC(i) END;
  i := 0; WHILE (i < LEN(q)) & (q[i] # 0X) DO r[n] := q[i]; INC(n); INC(i) END;
  IF brackets THEN r[n] := "]"; INC(n) END;
  r[n] := 0X;
  RETURN r
END Join;

(* Whether s ends with t *)
PROCEDURE Ends(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR): BOOLEAN;
  VAR n, m, i: LONGINT;
BEGIN
  n := L.Length(s); m := L.Length(t);
  IF m > n THEN RETURN FALSE END;
  FOR i := 0 TO m - 1 DO
    IF s[n - m + i] # t[i] THEN RETURN FALSE END
  END;
  RETURN TRUE
END Ends;

(* An element's stereotype: its type without "external_", "_db" and
   "_queue", named *)
PROCEDURE Stereotype(sh: C.Shape): Str;
  VAR t, techn: Str; n, i, k: LONGINT;
BEGIN
  n := L.Length(sh.type^); i := 0;
  IF (n > 9) & (sh.type[0] = "e") & (sh.type[8] = "_") THEN i := 9 END;
  IF Ends(sh.type^, "_db") THEN DEC(n, 3) ELSIF Ends(sh.type^, "_queue") THEN DEC(n, 6) END;
  t := L.Sub(sh.type^, i, n - i);
  IF L.Is(t, "person") THEN t := L.New("Person")
  ELSIF L.Is(t, "system") THEN t := L.New("Software System")
  ELSIF L.Is(t, "container") THEN t := L.New("Container")
  ELSIF L.Is(t, "component") THEN t := L.New("Component")
  ELSE
    k := 0; WHILE t[k] # 0X DO IF t[k] = "_" THEN t[k] := " " END; INC(k) END
  END;
  techn := C.Text(sh.attrs, "techn");
  IF (techn # NIL) & (techn[0] # 0X) THEN
    t := Join("", t, ": ", FALSE); t := Join("", t, techn^, FALSE)
  END;
  RETURN Join("", t, "", TRUE)
END Stereotype;

(* Shapes *)

(* Whether s, its blanks dropped, is w, in any case *)
PROCEDURE Word(VAR s: ARRAY OF CHAR; from, to: LONGINT; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT; a, b: CHAR;
BEGIN
  WHILE (from < to) & L.IsBlank(s[from]) DO INC(from) END;
  WHILE (to > from) & L.IsBlank(s[to - 1]) DO DEC(to) END;
  i := 0;
  WHILE (from + i < to) & (i < LEN(w)) & (w[i] # 0X) DO
    a := CAP(s[from + i]); b := CAP(w[i]);
    IF a # b THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN (from + i = to) & ((i = LEN(w)) OR (w[i] = 0X))
END Word;

(* The shape s[from, to) names, or -1 *)
PROCEDURE Keyword(VAR s: ARRAY OF CHAR; from, to: LONGINT): INTEGER;
BEGIN
  IF Word(s, from, to, "person") THEN RETURN kPerson
  ELSIF Word(s, from, to, "box") OR Word(s, from, to, "rounded") THEN RETURN kRounded
  ELSIF Word(s, from, to, "cylinder") OR Word(s, from, to, "database") OR Word(s, from, to, "db") THEN
    RETURN kCylinder
  ELSIF Word(s, from, to, "queue") OR Word(s, from, to, "pipe") THEN RETURN kHCyl
  ELSIF Word(s, from, to, "component") THEN RETURN kComponent
  END;
  RETURN -1
END Keyword;

PROCEDURE Kind(sh: C.Shape): INTEGER;
  VAR s: Str; k: INTEGER; i, j: LONGINT;
BEGIN
  s := C.Value(sh.attrs, "shape");
  IF s # NIL THEN k := Keyword(s^, 0, L.Length(s^)); IF k >= 0 THEN RETURN k END END;
  s := C.Value(sh.attrs, "sprite");
  IF s # NIL THEN k := Keyword(s^, 0, L.Length(s^)); IF k >= 0 THEN RETURN k END END;
  s := C.Value(sh.attrs, "tags");
  IF s # NIL THEN
    i := 0;
    WHILE s[i] # 0X DO
      j := i; WHILE (s[j] # 0X) & (s[j] # ",") DO INC(j) END;
      k := Keyword(s^, i, j); IF k >= 0 THEN RETURN k END;
      i := j; IF s[i] = "," THEN INC(i) END
    END
  END;
  IF L.Is(sh.type, "person") OR L.Is(sh.type, "external_person") THEN RETURN kPerson
  ELSIF Ends(sh.type^, "_db") THEN RETURN kCylinder
  ELSIF Ends(sh.type^, "_queue") THEN RETURN kHCyl
  END;
  RETURN kRounded
END Kind;

(* The default colours of an element of type t *)
PROCEDURE Defaults(t: Str; VAR bg, border: LONGINT);
  PROCEDURE Starts(w: ARRAY OF CHAR): BOOLEAN;
    VAR i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i < LEN(w)) & (w[i] # 0X) DO
      IF t[i] # w[i] THEN RETURN FALSE END;
      INC(i)
    END;
    RETURN TRUE
  END Starts;
BEGIN
  IF L.Is(t, "person") THEN bg := 08427BH; border := 073B6FH
  ELSIF L.Is(t, "external_person") THEN bg := 686868H; border := 8A8A8AH
  ELSIF Starts("system") THEN bg := 1168BDH; border := 3C7FC0H
  ELSIF Starts("external_system") THEN bg := 999999H; border := 8A8A8AH
  ELSIF Starts("container") THEN bg := 438DD5H; border := 3C7FC0H
  ELSIF Starts("external_container") THEN bg := 0B3B3B3H; border := 0A6A6A6H
  ELSIF Starts("component") THEN bg := 85BBF0H; border := 78A8D8H
  ELSIF Starts("external_component") THEN bg := 0CCCCCCH; border := 0BFBFBFH
  ELSE bg := 1168BDH; border := 3C7FC0H
  END
END Defaults;

(* Element sh's shape, texts and size *)
PROCEDURE Measure(sh: C.Shape; VAR e: Elem);
  VAR fs, maxW, w, bw, headR, overlap, bodyR, rx, ry: LONGREAL; k: INTEGER; bg, border: LONGINT;

  PROCEDURE Section(s: Str; st: SHORTINT; size: LONGREAL);
  BEGIN
    e.lab[k] := Text(s, st, size, maxW, w, e.lh[k]); e.ls[k] := size;
    IF w > bw THEN bw := w END;
    IF e.lab[k].n > 0 THEN
      IF e.bh > 0 THEN e.bh := e.bh + 3 END;
      e.bh := e.bh + e.lh[k]
    END;
    INC(k)
  END Section;

BEGIN
  e.kind := Kind(sh); e.placed := FALSE;
  fs := Conf(sh.type^, "FontSize", 14);
  IF ~wrap THEN maxW := 0
  ELSIF e.kind = kCylinder THEN maxW := width - 3 * padding
  ELSIF e.kind = kHCyl THEN maxW := width - 2.5D0 * padding
  ELSE maxW := width - 2 * padding
  END;
  IF wrap & (maxW < 1) THEN maxW := 1 END;
  k := 0; bw := 0; e.bh := 0;
  Section(C.Text(sh.attrs, "label"), F.Bold, fs);
  Section(Stereotype(sh), F.Roman, 0.75D0 * fs);
  Section(C.Text(sh.attrs, "descr"), F.Roman, 0.82D0 * fs);
  CASE e.kind OF
    kRounded:
      e.w := Max(bw + 2 * padding, width); e.h := e.bh + 2 * padding
  | kPerson:
      w := Max(Max(bw + 2 * padding, width), 100);
      headR := Min(Max(0.23D0 * w, 16), 56); overlap := 0.27D0 * headR;
      e.a := e.bh + 2 * padding;
      bodyR := Min(0.177D0 * w, 0.45D0 * e.a);
      e.w := w; e.h := e.a + 2 * headR - overlap; e.b := bodyR
  | kCylinder:
      w := Max(width - padding, bw) + padding; rx := w / 2; ry := rx / (2.5D0 + w / 50);
      e.a := rx; e.b := ry;
      e.w := w; e.h := e.bh + padding + ry + 2 * ry
  | kHCyl:
      e.h := e.bh + padding / 2; ry := e.h / 2; rx := ry / (2.5D0 + e.h / 50);
      e.a := rx; e.b := ry;
      e.w := Max(width - padding / 2, bw) + rx + padding / 2 + 2 * rx
  | kComponent:
      e.w := Max(bw + 2 * padding - 4, width); e.h := e.bh + padding
  END;
  Defaults(sh.type, bg, border);
  e.fill := Colour(C.Value(sh.attrs, "bgColor"), ConfColour(sh.type, "_bg_color", bg));
  e.line := Colour(C.Value(sh.attrs, "borderColor"), ConfColour(sh.type, "_border_color", border));
  e.text := Colour(C.Value(sh.attrs, "fontColor"), White)
END Measure;

(* Outlines, as polygons, in px and py *)

PROCEDURE Pt(x, y: LONGREAL);
BEGIN
  IF np < MaxPts THEN px[np] := x; py[np] := y; INC(np) END
END Pt;

(* The ellipse's arc, centre (cx, cy), from angle a0 to a1, y down *)
PROCEDURE Arc(cx, cy, rx, ry, a0, a1: LONGREAL; n: INTEGER);
  VAR k: INTEGER; a: LONGREAL;
BEGIN
  FOR k := 0 TO n DO
    a := a0 + (a1 - a0) * k / n;
    Pt(cx + rx * MathL.cos(a), cy + ry * MathL.sin(a))
  END
END Arc;

(* The rounded box from (x, y), w by h, its corners r *)
PROCEDURE RoundBox(x, y, w, h, r: LONGREAL);
BEGIN
  Arc(x + w - r, y + r, r, r, -MathL.pi / 2, 0, 6);
  Arc(x + w - r, y + h - r, r, r, 0, MathL.pi / 2, 6);
  Arc(x + r, y + h - r, r, r, MathL.pi / 2, MathL.pi, 6);
  Arc(x + r, y + r, r, r, MathL.pi, 1.5D0 * MathL.pi, 6)
END RoundBox;

(* e's outline, about its middle (cx, cy) *)
PROCEDURE Outline(VAR e: Elem; cx, cy: LONGREAL);
  VAR hw, hh: LONGREAL;
BEGIN
  np := 0;
  IF e.kind = kCylinder THEN
    hw := e.w / 2; hh := e.h / 2 - e.b;
    Arc(cx, cy - hh, hw, e.b, MathL.pi, 2 * MathL.pi, 2 * NSamples);
    Arc(cx, cy + hh, hw, e.b, 0, MathL.pi, 2 * NSamples)
  ELSIF e.kind = kHCyl THEN
    hw := e.w / 2 - e.a; hh := e.h / 2;
    Arc(cx - hw, cy, e.a, hh, MathL.pi / 2, 1.5D0 * MathL.pi, 2 * NSamples);
    Arc(cx + hw, cy, e.a, hh, -MathL.pi / 2, MathL.pi / 2, 2 * NSamples)
  END
END Outline;

(* Intersections *)

(* dagre's intersect.rect: where the line from (cx, cy), the middle of
   a box w by h, toward (x, y) leaves it *)
PROCEDURE Rect(cx, cy, w, h, x, y: LONGREAL; VAR ox, oy: LONGREAL);
  VAR dx, dy, sx, sy: LONGREAL;
BEGIN
  dx := x - cx; dy := y - cy; w := w / 2; h := h / 2;
  IF ABS(dy) * w > ABS(dx) * h THEN
    IF dy < 0 THEN h := -h END;
    IF dy = 0 THEN sx := 0 ELSE sx := h * dx / dy END;
    sy := h
  ELSE
    IF dx < 0 THEN w := -w END;
    sx := w;
    IF dx = 0 THEN sy := 0 ELSE sy := w * dy / dx END
  END;
  ox := cx + sx; oy := cy + sy
END Rect;

(* The last crossing of the polygon px, py by the line from (cx, cy) to
   (x, y), as a fraction of it, or -1 *)
PROCEDURE Crossing(cx, cy, x, y: LONGREAL): LONGREAL;
  VAR k, j: INTEGER; best, den, t, u, ax, ay, bx, by, dx, dy: LONGREAL;
BEGIN
  best := -1; dx := x - cx; dy := y - cy;
  FOR k := 0 TO np - 1 DO
    j := (k + 1) MOD np;
    ax := px[k]; ay := py[k]; bx := px[j] - ax; by := py[j] - ay;
    den := dx * by - dy * bx;
    IF den # 0 THEN
      t := ((ax - cx) * by - (ay - cy) * bx) / den;
      u := ((ax - cx) * dy - (ay - cy) * dx) / den;
      IF (t >= 0) & (t <= 1) & (u >= 0) & (u <= 1) & (t > best) THEN best := t END
    END
  END;
  RETURN best
END Crossing;

(* Where the line from e's middle toward (x, y) leaves it *)
PROCEDURE Intersect(VAR e: Elem; x, y: LONGREAL; VAR ox, oy: LONGREAL);
  VAR cx, cy, v, t, t2, top, headR: LONGREAL;
BEGIN
  cx := e.x + e.w / 2; cy := e.y + e.h / 2;
  Rect(cx, cy, e.w, e.h, x, y, ox, oy);
  IF e.kind = kCylinder THEN
    v := ox - cx;
    IF (e.a # 0) & ((ABS(v) < e.w / 2) OR (ABS(v) = e.w / 2) & (ABS(oy - cy) > e.h / 2 - e.b)) THEN
      t := e.b * e.b * (1 - v * v / (e.a * e.a));
      IF t > 0 THEN t := MathL.sqrt(t) END;
      t := e.b - t;
      IF y - cy > 0 THEN t := -t END;
      oy := oy + t
    END
  ELSIF e.kind = kHCyl THEN
    v := oy - cy;
    IF (e.b # 0) & ((ABS(v) < e.h / 2) OR (ABS(v) = e.h / 2) & (ABS(ox - cx) > e.w / 2 - e.a)) THEN
      t := e.a * e.a * (1 - v * v / (e.b * e.b));
      IF t # 0 THEN t := MathL.sqrt(ABS(t)) END;
      t := e.a - t;
      IF x - cx > 0 THEN t := -t END;
      ox := ox + t
    END
  ELSIF e.kind = kPerson THEN
    (* the head and the body, each a polygon: the last crossing of either *)
    headR := (e.h - e.a) / (2 - 0.27D0); top := cy - e.h / 2;
    np := 0; Arc(cx, top + headR, headR, headR, 0, 2 * MathL.pi, 4 * NSamples);
    t := Crossing(cx, cy, x, y);
    np := 0; RoundBox(e.x, e.y + e.h - e.a, e.w, e.a, e.b);
    t2 := Crossing(cx, cy, x, y);
    IF t2 > t THEN t := t2 END;
    IF t >= 0 THEN ox := cx + t * (x - cx); oy := cy + t * (y - cy) END
  END
END Intersect;

(* Placement: c4Renderer.ts's Bounds and drawInsideBoundary *)

PROCEDURE SetData(VAR b: Box; x0, x1, y0, y1: LONGREAL);
BEGIN
  b.x0 := x0; b.nx0 := x0; b.x1 := x1; b.nx1 := x1;
  b.y0 := y0; b.ny0 := y0; b.y1 := y1; b.ny1 := y1
END SetData;

PROCEDURE Insert(VAR b: Box; VAR e: Elem);
  VAR x0, x1, y0, y1: LONGREAL;
BEGIN
  INC(b.cnt);
  IF b.nx0 = b.nx1 THEN x0 := b.nx1 + shapeMargin ELSE x0 := b.nx1 + 2 * shapeMargin END;
  x1 := x0 + e.w;
  y0 := b.ny0 + 2 * shapeMargin; y1 := y0 + e.h;
  IF (x0 >= b.limit) OR (x1 >= b.limit) OR (b.cnt > d.shapeInRow) THEN
    x0 := b.nx0 + shapeMargin + Conf("nextLinePaddingX", "", 0);
    y0 := b.ny1 + 2 * shapeMargin;
    x1 := x0 + e.w; b.nx1 := x1;
    b.ny0 := b.ny1;
    y1 := y0 + e.h; b.ny1 := y1;
    b.cnt := 1
  END;
  e.x := x0; e.y := y0; e.placed := TRUE;
  b.x0 := Min(x0, b.x0); b.y0 := Min(y0, b.y0); b.x1 := Max(x1, b.x1); b.y1 := Max(y1, b.y1);
  b.nx0 := Min(x0, b.nx0); b.ny0 := Min(y0, b.ny0); b.nx1 := Max(x1, b.nx1); b.ny1 := Max(y1, b.ny1)
END Insert;

(* The boundaries in parent, placed in pb, and what is in them *)
PROCEDURE Inside(parent: Str; VAR pb: Box);
  VAR cur: Box; b: C.Boundary; sh: C.Shape; i, n: LONGINT; k: INTEGER; y, w, h, x0, y0: LONGREAL;
    s: Str;
BEGIN
  n := 0; b := d.boundaries;
  WHILE b # NIL DO
    IF L.Equal(b.parent, parent) & ~bd[b.index].placed THEN INC(n) END;
    b := b.next
  END;
  IF n = 0 THEN RETURN END;
  cur.cnt := 0;
  IF d.boundaryInRow < n THEN cur.limit := pb.limit / d.boundaryInRow ELSE cur.limit := pb.limit / n END;
  SetData(cur, 0, 0, 0, 0);
  i := 0; b := d.boundaries;
  WHILE b # NIL DO
    IF L.Equal(b.parent, parent) & ~bd[b.index].placed THEN
      bd[b.index].placed := TRUE;
      (* the texts at its top *)
      y := 0;
      s := C.Value(b.attrs, "sprite");
      IF (s # NIL) & (s[0] # 0X) THEN y := 48 END;
      IF wrap THEN w := cur.limit ELSE w := 0 END;
      k := 0;
      bd[b.index].lab[0] := Text(C.Text(b.attrs, "label"), F.Bold, bfs + 2, w, x0, h);
      bd[b.index].ls[0] := bfs + 2; bd[b.index].ly[0] := y + 8; y := y + 8 + h;
      s := C.Text(b.attrs, "type");
      IF (s # NIL) & (s[0] # 0X) THEN
        bd[b.index].lab[1] := Text(Join("", s, "", TRUE), F.Roman, bfs, w, x0, h);
        bd[b.index].ly[1] := y + 5; y := y + 5 + h
      ELSE bd[b.index].lab[1] := Text(NIL, F.Roman, bfs, 0, x0, h)
      END;
      bd[b.index].ls[1] := bfs;
      s := C.Text(b.attrs, "descr");
      IF (s # NIL) & (s[0] # 0X) THEN
        bd[b.index].lab[2] := Text(s, F.Roman, bfs - 2, w, x0, h);
        bd[b.index].ly[2] := y + 20; y := y + 20 + h
      ELSE bd[b.index].lab[2] := Text(NIL, F.Roman, bfs - 2, 0, x0, h)
      END;
      bd[b.index].ls[2] := bfs - 2;
      IF (i = 0) OR (i MOD d.boundaryInRow = 0) THEN
        x0 := pb.x0 + marginX; y0 := pb.y1 + marginY + y
      ELSE
        IF cur.x1 # cur.x0 THEN x0 := cur.x1 + marginX ELSE x0 := cur.x0 END;
        y0 := cur.y0
      END;
      SetData(cur, x0, x0, y0, y0);
      (* its elements, then the boundaries in it *)
      sh := d.shapes; k := 0;
      WHILE sh # NIL DO
        IF L.Equal(sh.parent, b.alias) & ~el[sh.index].placed THEN Insert(cur, el[sh.index]); k := 1 END;
        sh := sh.next
      END;
      IF k > 0 THEN cur.x1 := cur.x1 + shapeMargin; cur.y1 := cur.y1 + shapeMargin END;
      Inside(b.alias, cur);
      IF b.index # 0 THEN
        bd[b.index].boxed := TRUE;
        bd[b.index].x := cur.x0; bd[b.index].y := cur.y0;
        bd[b.index].w := cur.x1 - cur.x0; bd[b.index].h := cur.y1 - cur.y0
      END;
      pb.y1 := Max(cur.y1 + shapeMargin, pb.y1);
      pb.x1 := Max(cur.x1 + shapeMargin, pb.x1);
      maxX := Max(maxX, pb.x1); maxY := Max(maxY, pb.y1);
      INC(i)
    END;
    b := b.next
  END
END Inside;

(* Drawing *)

PROCEDURE DrawBoundary(b: C.Boundary);
  VAR fill, line: LONGINT; k: INTEGER; x, y, w, h: LONGREAL;
BEGIN
  fill := Colour(C.Value(b.attrs, "bgColor"), -1);
  line := Colour(C.Value(b.attrs, "borderColor"), Grey);
  x := bd[b.index].x; y := bd[b.index].y; w := bd[b.index].w; h := bd[b.index].h;
  IF C.Find(b.attrs, "nodeType") # NIL THEN D.AddRect(l, x, y, w, h, 2.5D0, fill, line, 1)
  ELSE
    (* dashed: the box filled, then its outline, square cornered, as
       dashes would break a 2.5 pixel corner into dots *)
    IF fill >= 0 THEN D.AddRect(l, x, y, w, h, 2.5D0, fill, -1, 0) END;
    IF line >= 0 THEN
      D.MoveTo(x, y); D.LineTo(x + w, y); D.LineTo(x + w, y + h);
      D.LineTo(x, y + h); D.LineTo(x, y);
      D.AddPath(l, line, 1); D.Dash(l, 7)
    END
  END;
  x := x + w / 2;
  FOR k := 0 TO 2 DO
    D.AddText(l, bd[b.index].lab[k], x, bd[b.index].y + bd[b.index].ly[k], bd[b.index].ls[k], 0, Grey)
  END
END DrawBoundary;

PROCEDURE DrawElem(VAR e: Elem);
  VAR cx, cy, top, headR, y, hw, ty: LONGREAL; k: INTEGER;
BEGIN
  cx := e.x + e.w / 2; cy := e.y + e.h / 2;
  CASE e.kind OF
    kRounded:
      D.AddRect(l, e.x, e.y, e.w, e.h, 12, e.fill, e.line, 2)
  | kPerson:
      headR := (e.h - e.a) / (2 - 0.27D0); top := e.y;
      D.AddRect(l, e.x, e.y + e.h - e.a, e.w, e.a, e.b, e.fill, e.line, 2);
      D.AddCircle(l, cx, top + headR, headR, e.fill, e.line, 2);
      cy := e.y + e.h - e.a / 2
  | kCylinder:
      Outline(e, cx, cy);
      D.AddPoly(l, px, py, np, e.fill, e.line, 2);
      hw := e.w / 2; ty := cy - e.h / 2 + e.b;
      D.MoveTo(cx - hw, ty); D.ArcTo(FALSE, cx, ty + e.b); D.ArcTo(FALSE, cx + hw, ty);
      D.AddPath(l, e.line, 2);
      cy := cy + padding / 1.5D0
  | kHCyl:
      Outline(e, cx, cy);
      D.AddPoly(l, px, py, np, e.fill, e.line, 2);
      hw := e.w / 2 - e.a;
      D.MoveTo(cx + hw, cy - e.h / 2); D.ArcTo(FALSE, cx + hw - e.a, cy); D.ArcTo(FALSE, cx + hw, cy + e.h / 2);
      D.AddPath(l, e.line, 2);
      cx := cx - e.a
  | kComponent:
      D.AddRect(l, e.x, e.y, e.w, e.h, 0, e.fill, e.line, 2);
      D.AddLine(l, e.x + 8, e.y, e.x + 8, e.y + e.h, e.line, 2, 0);
      D.AddLine(l, e.x + e.w - 8, e.y, e.x + e.w - 8, e.y + e.h, e.line, 2, 0)
  END;
  y := cy - e.bh / 2;
  FOR k := 0 TO 2 DO
    IF e.lab[k].n > 0 THEN
      D.AddText(l, e.lab[k], cx, y + e.lh[k] / 2, e.ls[k], 0, e.text);
      y := y + e.lh[k] + 3
    END
  END
END DrawElem;

(* The middle, the box and the intersection of the end called alias *)
PROCEDURE End(alias: Str; x, y: LONGREAL; VAR ox, oy: LONGREAL);
  VAR sh: C.Shape; b: C.Boundary;
BEGIN
  sh := C.FindShape(d, alias);
  IF sh # NIL THEN Intersect(el[sh.index], x, y, ox, oy)
  ELSE
    b := C.FindBoundary(d, alias);
    Rect(bd[b.index].x + bd[b.index].w / 2, bd[b.index].y + bd[b.index].h / 2,
      bd[b.index].w, bd[b.index].h, x, y, ox, oy)
  END
END End;

PROCEDURE Middle(alias: Str; VAR x, y: LONGREAL);
  VAR sh: C.Shape; b: C.Boundary;
BEGIN
  sh := C.FindShape(d, alias);
  IF sh # NIL THEN x := el[sh.index].x + el[sh.index].w / 2; y := el[sh.index].y + el[sh.index].h / 2
  ELSE
    b := C.FindBoundary(d, alias);
    x := bd[b.index].x + bd[b.index].w / 2; y := bd[b.index].y + bd[b.index].h / 2
  END
END Middle;

(* An arrowhead, its tip at (x, y), pointing along (ux, uy) *)
PROCEDURE Arrow(x, y, ux, uy: LONGREAL);
  VAR n: LONGREAL; ax, ay: ARRAY 3 OF LONGREAL;
BEGIN
  n := MathL.sqrt(ux * ux + uy * uy);
  IF n = 0 THEN RETURN END;
  ux := ux / n; uy := uy / n;
  ax[0] := x; ay[0] := y;
  ax[1] := x - 10 * ux - 5 * uy; ay[1] := y - 10 * uy + 5 * ux;
  ax[2] := x - 10 * ux + 5 * uy; ay[2] := y - 10 * uy - 5 * ux;
  D.AddPoly(l, ax, ay, 3, S.TextRgb(), -1, 0)
END Arrow;

PROCEDURE DrawRel(r: C.Rel; first: BOOLEAN; i: LONGINT);
  VAR sx, sy, ex, ey, ax, ay, bx, by, qx, qy, mx, my, ox, oy, w, h, tw, th, n: LONGREAL;
    colour, text: LONGINT; lab, techn: F.Label; s: Str; v: LONGINT; num: ARRAY 24 OF CHAR;
    k, j: INTEGER;
BEGIN
  Middle(r.from, ax, ay); Middle(r.to, bx, by);
  End(r.from, bx, by, sx, sy); End(r.to, ax, ay, ex, ey);
  colour := Colour(C.Value(r.attrs, "lineColor"), Grey);
  text := Colour(C.Value(r.attrs, "textColor"), Grey);
  IF first THEN
    D.AddLine(l, sx, sy, ex, ey, colour, 1, 0);
    qx := sx; qy := sy
  ELSE
    qx := sx + (ex - sx) / 4; qy := sy + (ey - sy) / 2;
    D.MoveTo(sx, sy);
    D.CurveTo(sx + 2 * (qx - sx) / 3, sy + 2 * (qy - sy) / 3, ex + 2 * (qx - ex) / 3, ey + 2 * (qy - ey) / 3, ex, ey);
    D.AddPath(l, colour, 1)
  END;
  (* the arrowheads: their tips 1 past the ends *)
  IF ~L.Is(r.kind, "rel_b") OR r.kindSet THEN
    IF first THEN ax := ex - sx; ay := ey - sy ELSE ax := ex - qx; ay := ey - qy END;
    n := MathL.sqrt(ax * ax + ay * ay);
    IF n > 0 THEN Arrow(ex + ax / n, ey + ay / n, ax, ay) END
  END;
  IF ~r.kindSet & (L.Is(r.kind, "birel") OR L.Is(r.kind, "rel_b")) THEN
    IF first THEN ax := sx - ex; ay := sy - ey ELSE ax := sx - qx; ay := sy - qy END;
    n := MathL.sqrt(ax * ax + ay * ay);
    IF n > 0 THEN Arrow(sx + ax / n, sy + ay / n, ax, ay) END
  END;
  (* the label and the technology *)
  s := C.Text(r.attrs, "label");
  IF s = NIL THEN s := L.New("") END;
  IF L.Is(d.c4Type, "C4Dynamic") THEN
    v := i; k := 0;
    REPEAT num[k] := CHR(ORD("0") + v MOD 10); v := v DIV 10; INC(k) UNTIL v = 0;
    FOR j := 0 TO k DIV 2 - 1 DO
      num[23] := num[j]; num[j] := num[k - 1 - j]; num[k - 1 - j] := num[23]
    END;
    num[k] := 0X;
    s := Join(num, L.New(": "), s^, FALSE)
  END;
  lab := Text(s, F.Roman, mfs, 0, w, h);
  IF ~C.ParseInt(C.Value(r.attrs, "offsetX"), v) THEN v := 0 END; ox := v;
  IF ~C.ParseInt(C.Value(r.attrs, "offsetY"), v) THEN v := 0 END; oy := v;
  mx := Min(sx, ex) + ABS(ex - sx) / 2 + ox; my := Min(sy, ey) + ABS(ey - sy) / 2 + oy;
  D.AddText(l, lab, mx + w / 2, my, mfs, 0, text);
  s := C.Text(r.attrs, "techn");
  IF (s # NIL) & (s[0] # 0X) THEN
    techn := Text(Join("", s, "", TRUE), F.Italic, mfs, 0, tw, th);
    D.AddText(l, techn, mx + Max(w, tw) / 2, my + mfs + 5, mfs, 0, text)
  END
END DrawRel;

(* d laid out at size points, in lay *)
PROCEDURE Make*(dg: C.Diagram; font: M.Font; sz: REAL; VAR lay: Layout);
  VAR screen: Box; sh: C.Shape; b: C.Boundary; r: C.Rel; i: LONGINT; q: Y.Pair;
    extra, tw, th, bw: LONGREAL; title: F.Label;
BEGIN
  NEW(l); lay := l; d := dg; l.d := d; D.Init(l, d.g, font, sz);
  S.Reset(d.g, l.px);
  marginX := Conf("diagramMarginX", "", 50); marginY := Conf("diagramMarginY", "", 10);
  shapeMargin := Conf("c4ShapeMargin", "", 50); padding := Conf("c4ShapePadding", "", 20);
  width := Conf("width", "", 216);
  bfs := Conf("boundaryFontSize", "", 14); mfs := Conf("messageFontSize", "", 12);
  IF bfs < 3 THEN bfs := 3 END;
  IF mfs < 1 THEN mfs := 1 END;
  q := Y.Find(d.g.config, "config.c4.wrap");
  wrap := (q = NIL) OR ~L.Is(q.value, "false");
  NEW(el, d.nShapes + 1); NEW(bd, d.nBoundaries + 1);
  sh := d.shapes; WHILE sh # NIL DO Measure(sh, el[sh.index]); sh := sh.next END;
  FOR i := 0 TO d.nBoundaries DO bd[i].placed := FALSE; bd[i].boxed := FALSE END;
  screen.cnt := 0; SetData(screen, marginX, marginX, marginY, marginY); screen.limit := 1920;
  maxX := marginX; maxY := marginY;
  Inside(L.New(""), screen);
  b := d.boundaries;
  WHILE b # NIL DO IF bd[b.index].boxed THEN DrawBoundary(b) END; b := b.next END;
  sh := d.shapes;
  WHILE sh # NIL DO IF el[sh.index].placed THEN DrawElem(el[sh.index]) END; sh := sh.next END;
  r := d.rels; i := 1;
  WHILE r # NIL DO DrawRel(r, i = 1, i); INC(i); r := r.next END;
  bw := maxX - marginX; extra := 0;
  IF d.title # NIL THEN
    extra := 60;
    title := Text(d.title, F.Roman, 16, 0, tw, th);
    D.AddText(l, title, bw / 2 - 4 * marginX + tw / 2, marginY + marginY - 0.35D0 * 16, 16, 0, S.TextRgb())
  END;
  D.AddRect(l, marginX - marginX, -(marginY + extra), bw + 2 * marginX,
    maxY - marginY + 2 * marginY + extra, 0, -1, -1, 0);
  D.Finish(l, 0);
  l := NIL; d := NIL; el := NIL; bd := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: C.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
  VAR k: INTEGER;
BEGIN
  Make(d, font, size, lay); k := 0;
  WHILE (maxW > 0) & (lay.width > maxW) & (k < 5) & (size > 0.2D0) DO
    size := ENTIER(size * maxW / lay.width * 10) / 10;
    IF size >= lay.size THEN size := lay.size - 0.1 END;
    IF size < 0.1 THEN size := 0.1 END;
    Make(d, font, size, lay); INC(k)
  END
END Fit;

END PmC4Layout.
