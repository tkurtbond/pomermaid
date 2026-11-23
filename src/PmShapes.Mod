MODULE PmShapes;
(* PmShapes: the shapes a flowchart's node gets only by name, with
   "@{ shape: name }" (PmFlow's DataStore to LinDoc): their sizes,
   their drawings and their outlines.

   A drawing is a few parts, each a list of points: the body, filled
   and outlined in the node's style; lines, outlined only; solids,
   filled and outlined in the node's line colour; and fills, filled
   only. Arcs and waves are drawn as many short lines. The outline,
   which edges are cut at, is a polygon too.

   The sizes and shapes follow Mermaid's (rendering-util's shapes),
   with its sizes in pixels scaled from its 16 pixel text, and are
   drawn freely where Mermaid's are hand drawn. mp/pomermaid.mp draws
   the same shapes in MetaPost; keep the two alike.

   Coordinates are in points, y down, as in the layout. *)

IMPORT Math, F := PmFlow, G := PmGeom;

CONST
  (* the kinds of parts *)
  Body* = 0; Line* = 1; Solid* = 2; Fill* = 3;
  MaxParts* = 8;
  MaxPoints = 400;
  PadNum = 15; PadDen = 16;  (* the padding, as PmMetrics's *)
  ArcSteps = 12;             (* the lines of an arc of 90 degrees *)
  WaveSteps = 32;            (* the lines of a wave *)
  Pi = 3.14159265;

TYPE
  Part* = RECORD
    kind*: INTEGER;
    n*: INTEGER;       (* points p[0 .. n-1] *)
    p*: G.Points
  END;

  Drawing* = RECORD
    n*: INTEGER;                    (* parts part[0 .. n-1], drawn in order *)
    part*: ARRAY MaxParts OF Part;
    outline*: Part;                 (* the outline, a closed polygon *)
    label*: BOOLEAN;                (* whether the label is drawn *)
    lx*, ly*: REAL                  (* the label's centre *)
  END;

VAR
  cur: Part;         (* the part being made *)
  ox, oy: REAL;      (* the node's centre *)

(* Whether shape is one of PmShapes's *)
PROCEDURE Has*(shape: INTEGER): BOOLEAN;
BEGIN
  RETURN (shape >= F.DataStore) & (shape <= F.LinDoc)
END Has;

PROCEDURE Max(a, b: REAL): REAL;
BEGIN
  IF a > b THEN RETURN a ELSE RETURN b END
END Max;

PROCEDURE Min(a, b: REAL): REAL;
BEGIN
  IF a < b THEN RETURN a ELSE RETURN b END
END Min;

PROCEDURE Clamp(x, lo, hi: REAL): REAL;
BEGIN
  RETURN Max(lo, Min(x, hi))
END Clamp;

(* The width and height of a node of shape shape, one of PmShapes's,
   around text tw by th points at size points; dir is the diagram's
   direction *)
PROCEDURE Size*(shape, dir: INTEGER; tw, th, size: REAL; VAR w, h: REAL);
  VAR p, px, q, r, rx, t, a: REAL;
BEGIN
  p := size * PadNum / PadDen; px := size / 16;
  w := tw + 2 * p; h := th + 2 * p;
  CASE shape OF
    F.DataStore: w := tw + 4 * p
  | F.Folder:
      q := 12 * px; w := Max(tw + 2 * q, 90 * px);
      h := th + 2 * q + Clamp(0.16 * w, 8 * px, 14 * px)
  | F.Bucket:
      q := 12 * px; w := Max(tw + 2 * q, 80 * px);
      h := th + 2 * q + Clamp(0.08 * w, 5 * px, 12 * px)
  | F.Console:
      q := 12 * px; w := Max(tw + 2 * q, 90 * px); h := th + 2 * q + 20 * px
  | F.Browser:
      q := 12 * px; w := Max(tw + 2 * q, 90 * px); h := th + 2 * q + 18 * px
  | F.Person:
      q := 20 * px; w := Max(tw + 2 * q, 100 * px);
      r := Clamp(0.23 * w, 16 * px, 56 * px) / 2;
      h := 1.6 * r + th + 2 * q
  | F.Bang, F.Cloud:
      (* the text's box in an ellipse 0.8 of the node's *)
      w := (tw + p) * 1.77; h := (th + p) * 1.77
  | F.TextShape: w := tw + p; h := th + p
  | F.NotchRect: w := tw + p + 12 * px; h := th + p
  | F.LinRect, F.LinDoc: w := w + 16 * px
  | F.SmCircle, F.FrCircle, F.FCircle: w := 14 * px; h := w
  | F.Fork:
      IF (dir = F.LR) OR (dir = F.RL) THEN w := 10 * px; h := 70 * px
      ELSE w := 70 * px; h := 10 * px
      END
  | F.Hourglass: w := 30 * px; h := w
  | F.Brace, F.BraceR, F.Braces:
      h := th + p; r := Max(5 * px, 0.1 * h);
      IF shape = F.Braces THEN w := tw + p + 4 * r ELSE w := tw + p + 2 * r END
  | F.Bolt: w := 35 * px; h := 70 * px
  | F.Doc, F.TagDoc: h := h + h / 8
  | F.Delay: w := w + h / 2
  | F.HCylinder: rx := h / 2 / (2.5 + h / 50); w := w + 3 * rx
  | F.LinCylinder: h := h + w / (2.5 + w / 50)
  | F.CurvTrap: w := w + h
  | F.DivRect: h := 1.2 * h
  | F.Triangle, F.FlipTriangle:
      (* a band th + p high at the base as wide as the text *)
      t := th + p; w := tw + p + 1.155 * t; h := Max(0.866 * w, 2 * t)
  | F.WinPane: w := w + 5 * px; h := h + 5 * px
  | F.NotchPent:
  | F.SlRect: h := 1.5 * h
  | F.Docs: w := w + 10 * px; h := h + h / 8 + 10 * px
  | F.StRect: w := w + 10 * px; h := h + 10 * px
  | F.BowRect: a := h / 2 / (2.5 + h / 50); w := w + 2 * a
  | F.CrossCircle: w := 60 * px; h := w
  | F.TagRect:
  | F.Flag: h := h + h / 4
  ELSE
  END
END Size;

(* Making parts *)

PROCEDURE Begin(kind: INTEGER);
BEGIN
  cur.kind := kind; cur.n := 0; cur.p := G.NewPoints(MaxPoints)
END Begin;

(* Adds (x, y), from the node's centre, to the part *)
PROCEDURE P(x, y: REAL);
BEGIN
  IF cur.n < MaxPoints THEN G.Set(cur.p[cur.n], ox + x, oy + y); INC(cur.n) END
END P;

PROCEDURE End(VAR d: Drawing);
BEGIN
  IF d.n < MaxParts THEN d.part[d.n] := cur; INC(d.n) END
END End;

(* The part made is the outline too *)
PROCEDURE EndOutline(VAR d: Drawing);
BEGIN
  d.outline := cur; End(d)
END EndOutline;

(* The points of an arc of the ellipse centred at (cx, cy), radii rx
   and ry, from angle a to angle b, in degrees: 0 is to the right, 90
   down *)
PROCEDURE Arc(cx, cy, rx, ry, a, b: REAL);
  VAR k, n: INTEGER; t: REAL;
BEGIN
  n := SHORT(ENTIER(ABS(b - a) / 90 * ArcSteps)) + 1;
  FOR k := 0 TO n DO
    t := (a + (b - a) * k / n) * Pi / 180;
    P(cx + rx * Math.cos(t), cy + ry * Math.sin(t))
  END
END Arc;

PROCEDURE Circle(cx, cy, r: REAL);
BEGIN
  Arc(cx, cy, r, r, 0, 360)
END Circle;

(* A box from (x0, y0) to (x1, y1), its corners rounded to radius r,
   clockwise from its top left *)
PROCEDURE RBox(x0, y0, x1, y1, r: REAL);
BEGIN
  Arc(x1 - r, y0 + r, r, r, 270, 360); Arc(x1 - r, y1 - r, r, r, 0, 90);
  Arc(x0 + r, y1 - r, r, r, 90, 180); Arc(x0 + r, y0 + r, r, r, 180, 270)
END RBox;

PROCEDURE Box(x0, y0, x1, y1: REAL);
BEGIN
  P(x0, y0); P(x1, y0); P(x1, y1); P(x0, y1)
END Box;

(* The y of a wave of amplitude a about mid, of n cycles across a w
   wide node, at x: down first, from the left *)
PROCEDURE WaveY(x, w, mid, a, n: REAL): REAL;
BEGIN
  RETURN mid + a * Math.sin(2 * Pi * n * (x + w / 2) / w)
END WaveY;

(* The points of that wave from x0 to x1 *)
PROCEDURE Wave(x0, x1, w, mid, a, n: REAL);
  VAR k: INTEGER; x: REAL;
BEGIN
  FOR k := 0 TO WaveSteps DO
    x := x0 + (x1 - x0) * k / WaveSteps; P(x, WaveY(x, w, mid, a, n))
  END
END Wave;

(* A document w by h centred at (cx, cy) from the node's centre: its
   bottom a wave of amplitude h / 9, 0.8 of a cycle *)
PROCEDURE Document(cx, cy, w, h: REAL);
  VAR a: REAL;
BEGIN
  a := h / 9;
  P(cx - w / 2, cy - h / 2); P(cx + w / 2, cy - h / 2);
  ox := ox + cx; oy := oy + cy;
  Wave(w / 2, -w / 2, w, h / 2 - a, a, 0.8);
  ox := ox - cx; oy := oy - cy
END Document;

(* A curly brace, open to the right, its point at x0, from y0 to y1,
   r its radius; mirrored if m is -1 *)
PROCEDURE Brace(x0, y0, y1, r, m: REAL);
  VAR k: INTEGER;
BEGIN
  Begin(Line);
  Arc(x0 + 2 * r, y0 + r, r, r, 270, 180);
  Arc(x0, -r, r, r, 0, 90);
  Arc(x0, r, r, r, 270, 360);
  Arc(x0 + 2 * r, y1 - r, r, r, 180, 90);
  IF m < 0 THEN
    FOR k := 0 TO cur.n - 1 DO cur.p[k].x := 2 * ox - cur.p[k].x END
  END
END Brace;

(* The drawing of a node of shape shape, one of PmShapes's, w by h,
   centred at (cx, cy), around text th points high at size points *)
PROCEDURE Draw*(shape: INTEGER; cx, cy, w, h, th, size: REAL; VAR d: Drawing);
  VAR p, px, x0, y0, x1, y1, q, r, rx, ry, t, a, b, h0, yb, o: REAL; k: INTEGER;
BEGIN
  p := size * PadNum / PadDen; px := size / 16;
  ox := cx; oy := cy;
  x0 := -w / 2; y0 := -h / 2; x1 := w / 2; y1 := h / 2;
  d.n := 0; d.label := TRUE; d.lx := cx; d.ly := cy;
  d.outline.n := 0; d.outline.kind := Body;
  CASE shape OF
    F.DataStore:
      Begin(Fill); Box(x0, y0, x1, y1); EndOutline(d);
      Begin(Line); P(x0, y0); P(x1, y0); End(d);
      Begin(Line); P(x0, y1); P(x1, y1); End(d)
  | F.Folder:
      t := Clamp(0.16 * w, 8 * px, 14 * px); a := Max(0.38 * w, 28 * px);
      Begin(Body);
      P(x0, y0); P(x0 + a, y0); P(x0 + a + t, y0 + t); P(x1, y0 + t); P(x1, y1); P(x0, y1);
      EndOutline(d);
      d.ly := cy + t / 2
  | F.Bucket:
      ry := Clamp(0.08 * w, 5 * px, 12 * px);
      Begin(Body);
      Arc(0, y0 + ry, w / 2, ry, 180, 360); P(0.36 * w, y1); P(-0.36 * w, y1);
      EndOutline(d);
      Begin(Line); Arc(0, y0 + ry, w / 2, ry, 0, 180); End(d);
      d.ly := cy + ry / 2
  | F.Console:
      Begin(Body); RBox(x0, y0, x1, y1, 12 * px); EndOutline(d);
      Begin(Line);
      P(x0 + 12 * px, y0 + 8 * px); P(x0 + 17 * px, y0 + 12 * px); P(x0 + 12 * px, y0 + 16 * px);
      End(d);
      Begin(Line); P(x0 + 19 * px, y0 + 16 * px); P(x0 + 26 * px, y0 + 16 * px); End(d);
      d.ly := cy + 10 * px
  | F.Browser:
      Begin(Body); RBox(x0, y0, x1, y1, 12 * px); EndOutline(d);
      Begin(Line); P(x0, y0 + 18 * px); P(x1, y0 + 18 * px); End(d);
      FOR k := 0 TO 2 DO
        Begin(Solid); Circle(x0 + (12 + 8 * k) * px, y0 + 9 * px, 2.5 * px); End(d)
      END;
      Begin(Line);
      Box(x0 + 38 * px, y0 + 4 * px, x1 - 12 * px, y0 + 14 * px); P(x0 + 38 * px, y0 + 4 * px);
      End(d);
      d.ly := cy + 9 * px
  | F.Person:
      r := Clamp(0.23 * w, 16 * px, 56 * px) / 2;  (* the head's radius *)
      yb := y0 + 1.6 * r;                           (* the body's top *)
      q := Min(0.2 * w, w / 2 - 0.8 * r);           (* its shoulders' radius *)
      Begin(Body);
      Arc(x1 - q, yb + q, q, q, 270, 360); P(x1, y1); P(x0, y1);
      Arc(x0 + q, yb + q, q, q, 180, 270);
      Arc(0, y0 + r, r, r, 143.1301, 396.8699);
      EndOutline(d);
      d.ly := cy + 0.8 * r
  | F.Bang:
      Begin(Body);
      FOR k := 0 TO 31 DO
        t := (k * 360 / 32 - 90) * Pi / 180;
        IF ODD(k) THEN a := 0.82 ELSE a := 1 END;
        P(a * w / 2 * Math.cos(t), a * h / 2 * Math.sin(t))
      END;
      EndOutline(d)
  | F.Cloud:
      (* bumps between 10 points on an ellipse 0.8 of the node's *)
      Begin(Body);
      b := 0.1 * Min(w, h);
      FOR k := 0 TO 9 DO
        t := (k * 36 - 90) * Pi / 180; a := ((k + 1) * 36 - 90) * Pi / 180;
        x0 := 0.4 * w * Math.cos(t); y0 := 0.4 * h * Math.sin(t);
        x1 := 0.4 * w * Math.cos(a); y1 := 0.4 * h * Math.sin(a);
        rx := y1 - y0; ry := x0 - x1;   (* outwards, as the points go clockwise *)
        q := Math.sqrt(rx * rx + ry * ry); o := Min(0.35 * q, b);
        rx := rx / q * o; ry := ry / q * o;
        o := 0;
        WHILE o < 7.5 DO
          t := Math.sin(Pi * o / 8);
          P(x0 + (x1 - x0) * o / 8 + rx * t, y0 + (y1 - y0) * o / 8 + ry * t);
          o := o + 1
        END
      END;
      EndOutline(d)
  | F.TextShape:
      Begin(Body); Box(x0, y0, x1, y1); d.outline := cur
  | F.NotchRect:
      Begin(Body);
      P(x0 + 12 * px, y0); P(x1, y0); P(x1, y1); P(x0, y1); P(x0, y0 + 12 * px);
      EndOutline(d)
  | F.LinRect:
      Begin(Body); Box(x0, y0, x1, y1); EndOutline(d);
      Begin(Line); P(x0 + 8 * px, y0); P(x0 + 8 * px, y1); End(d);
      d.lx := cx + 4 * px
  | F.SmCircle, F.FCircle:
      Begin(Solid); Circle(0, 0, w / 2); EndOutline(d); d.label := FALSE
  | F.FrCircle:
      Begin(Body); Circle(0, 0, w / 2); EndOutline(d);
      Begin(Solid); Circle(0, 0, 2.5 * px); End(d); d.label := FALSE
  | F.Fork:
      Begin(Solid); Box(x0, y0, x1, y1); EndOutline(d); d.label := FALSE
  | F.Hourglass:
      Begin(Body); P(x0, y0); P(x1, y0); P(x0, y1); P(x1, y1); EndOutline(d); d.label := FALSE
  | F.Brace, F.BraceR, F.Braces:
      Begin(Body); Box(x0, y0, x1, y1); d.outline := cur;
      r := Max(5 * px, 0.1 * h);
      IF shape # F.BraceR THEN Brace(x0, y0, y1, r, 1); End(d) END;
      IF shape # F.Brace THEN Brace(x0, y0, y1, r, -1); End(d) END;
      IF shape = F.Brace THEN d.lx := cx + r ELSIF shape = F.BraceR THEN d.lx := cx - r END
  | F.Bolt:
      a := w / 35; b := h / 70;
      Begin(Body);
      P(17.5 * a, -35 * b); P(-17.5 * a, 3.5 * b); P(3.5 * a, 3.5 * b);
      P(-17.5 * a, 35 * b); P(17.5 * a, -3.5 * b); P(-3.5 * a, -3.5 * b);
      EndOutline(d); d.label := FALSE
  | F.Doc, F.TagDoc:
      Begin(Body); Document(0, 0, w, h); EndOutline(d);
      h0 := h * 8 / 9; a := h / 9;
      IF shape = F.TagDoc THEN
        t := 0.2 * h0;
        Begin(Line);
        P(x1 - t, WaveY(x1 - t, w, y1 - a, a, 0.8)); P(x1, WaveY(x1, w, y1 - a, a, 0.8) - t);
        End(d)
      END;
      d.ly := cy - a / 2
  | F.Delay:
      Begin(Body); P(x0, y0); Arc(x1 - h / 2, 0, h / 2, h / 2, 270, 450); P(x0, y1);
      EndOutline(d);
      d.lx := cx - h / 4
  | F.HCylinder:
      rx := h / 2 / (2.5 + h / 50);
      Begin(Body);
      Arc(x1 - rx, 0, rx, h / 2, 270, 450); Arc(x0 + rx, 0, rx, h / 2, 90, 270);
      EndOutline(d);
      Begin(Line); Arc(x1 - rx, 0, rx, h / 2, 90, 270); End(d);
      d.lx := cx - rx
  | F.LinCylinder:
      ry := w / 2 / (2.5 + w / 50);
      Begin(Body);
      Arc(0, y0 + ry, w / 2, ry, 180, 360); Arc(0, y1 - ry, w / 2, ry, 0, 180);
      EndOutline(d);
      Begin(Line); Arc(0, y0 + ry, w / 2, ry, 0, 180); End(d);
      Begin(Line); Arc(0, y0 + ry + 0.1 * h, w / 2, ry, 0, 180); End(d);
      d.ly := cy + ry
  | F.CurvTrap:
      Begin(Body);
      P(x0, 0); P(x0 + h / 2, y0); Arc(x1 - h / 2, 0, h / 2, h / 2, 270, 450); P(x0 + h / 2, y1);
      EndOutline(d)
  | F.DivRect:
      h0 := h / 1.2;
      Begin(Body); Box(x0, y0, x1, y1); EndOutline(d);
      Begin(Line); P(x0, y0 + 0.2 * h0); P(x1, y0 + 0.2 * h0); End(d);
      d.ly := cy + 0.1 * h0
  | F.Triangle:
      Begin(Body); P(0, y0); P(x1, y1); P(x0, y1); EndOutline(d);
      d.ly := cy + y1 - (th + p) / 2
  | F.FlipTriangle:
      Begin(Body); P(x0, y0); P(x1, y0); P(0, y1); EndOutline(d);
      d.ly := cy + y0 + (th + p) / 2
  | F.WinPane:
      Begin(Body); Box(x0, y0, x1, y1); EndOutline(d);
      Begin(Line); P(x0 + 5 * px, y0); P(x0 + 5 * px, y1); End(d);
      Begin(Line); P(x0, y0 + 5 * px); P(x1, y0 + 5 * px); End(d);
      d.lx := cx + 2.5 * px; d.ly := cy + 2.5 * px
  | F.NotchPent:
      Begin(Body);
      P(-0.4 * w, y0); P(0.4 * w, y0); P(x1, -0.3 * h); P(x1, y1); P(x0, y1); P(x0, -0.3 * h);
      EndOutline(d)
  | F.SlRect:
      h0 := h / 1.5;
      Begin(Body); P(x0, y0 + h0 / 2); P(x1, y0); P(x1, y1); P(x0, y1); EndOutline(d);
      d.ly := cy + h0 / 4
  | F.Docs:
      o := 5 * px;
      FOR k := 1 TO -1 BY -1 DO
        Begin(Body); Document(k * o, -k * o, w - 2 * o, h - 2 * o); End(d)
      END;
      Begin(Body); Box(x0, y0, x1, y1); d.outline := cur;
      d.lx := cx - o; d.ly := cy + o - (h - 2 * o) / 18
  | F.StRect:
      o := 5 * px;
      FOR k := 1 TO -1 BY -1 DO
        Begin(Body); Box(x0 + o + k * o, y0 + o - k * o, x1 - o + k * o, y1 - o - k * o); End(d)
      END;
      Begin(Body);
      P(x0 + 2 * o, y0); P(x1, y0); P(x1, y1 - 2 * o); P(x1 - o, y1 - 2 * o); P(x1 - o, y1 - o);
      P(x1 - 2 * o, y1 - o); P(x1 - 2 * o, y1); P(x0, y1); P(x0, y0 + 2 * o); P(x0 + o, y0 + 2 * o);
      P(x0 + o, y0 + o); P(x0 + 2 * o, y0 + o);
      d.outline := cur;
      d.lx := cx - o; d.ly := cy + o
  | F.BowRect:
      rx := h / 2 / (2.5 + h / 50);
      Begin(Body);
      Arc(x1, 0, rx, h / 2, 270, 90); Arc(x0 + rx, 0, rx, h / 2, 90, 270);
      EndOutline(d)
  | F.CrossCircle:
      r := w / 2; a := r * 0.7071;
      Begin(Body); Circle(0, 0, r); EndOutline(d);
      Begin(Line); P(-a, -a); P(a, a); End(d);
      Begin(Line); P(-a, a); P(a, -a); End(d);
      d.label := FALSE
  | F.TagRect:
      t := 0.2 * h;
      Begin(Body); Box(x0, y0, x1, y1); EndOutline(d);
      Begin(Line); P(x1 - t, y1); P(x1, y1 - t); End(d)
  | F.Flag:
      a := h / 10;
      Begin(Body); Wave(x0, x1, w, y0 + a, a, 1); Wave(x1, x0, w, y1 - a, a, 1);
      EndOutline(d)
  | F.LinDoc:
      a := h / 9;
      Begin(Body); Document(0, 0, w, h); EndOutline(d);
      Begin(Line); P(x0 + 8 * px, y0); P(x0 + 8 * px, WaveY(x0 + 8 * px, w, y1 - a, a, 0.8)); End(d);
      d.lx := cx + 4 * px; d.ly := cy - a / 2
  ELSE
    Begin(Body); Box(x0, y0, x1, y1); EndOutline(d)
  END
END Draw;

(* The outline of a node of shape shape, one of PmShapes's, w by h,
   centred at (cx, cy), at size points: pts[0 .. n-1] *)
PROCEDURE Outline*(shape: INTEGER; cx, cy, w, h, size: REAL; VAR pts: G.Points; VAR n: INTEGER);
  VAR d: Drawing;
BEGIN
  Draw(shape, cx, cy, w, h, 0, size, d);
  pts := d.outline.p; n := d.outline.n
END Outline;

END PmShapes.
