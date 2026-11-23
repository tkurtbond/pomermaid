(* PmCurves: the curves an edge is drawn with, as d3's curve factories
   draw them through an edge's points, for the curves of Mermaid's
   `curve` (config.flowchart.curve, linkStyle's `curve` and an edge's
   `e1@{curve: ...}`). Each curve comes back as cubic Bézier curves, in
   PmGeom.Basis's form: the start, then three points for each curve,
   its two control points and its end; a straight piece has its
   control points at its thirds. The curves are PmFlow's numbers. *)
MODULE PmCurves;

IMPORT Math, F := PmFlow, G := PmGeom;

TYPE
  Builder = RECORD
    b: G.Points; nb: INTEGER
  END;

PROCEDURE Add(VAR c: Builder; x, y: REAL);
BEGIN
  c.b[c.nb].x := x; c.b[c.nb].y := y; INC(c.nb)
END Add;

PROCEDURE LineTo(VAR c: Builder; x, y: REAL);
  VAR sx, sy: REAL;
BEGIN
  sx := c.b[c.nb - 1].x; sy := c.b[c.nb - 1].y;
  IF (sx = x) & (sy = y) THEN RETURN END;
  Add(c, (2 * sx + x) / 3, (2 * sy + y) / 3);
  Add(c, (sx + 2 * x) / 3, (sy + 2 * y) / 3);
  Add(c, x, y)
END LineTo;

PROCEDURE CurveTo(VAR c: Builder; x1, y1, x2, y2, x, y: REAL);
BEGIN
  Add(c, x1, y1); Add(c, x2, y2); Add(c, x, y)
END CurveTo;

(* d3's curveStep, curveStepBefore and curveStepAfter: t is where the
   step is, 0.5 midway, 0 at the start, 1 at the end *)
PROCEDURE Step(VAR c: Builder; VAR p: ARRAY OF G.Point; n: INTEGER; t: REAL);
  VAR k: INTEGER; x: REAL;
BEGIN
  FOR k := 1 TO n - 1 DO
    IF t = 0 THEN
      LineTo(c, p[k - 1].x, p[k].y)
    ELSIF t = 1 THEN
      LineTo(c, p[k].x, p[k - 1].y)
    ELSE
      x := p[k - 1].x * (1 - t) + p[k].x * t;
      LineTo(c, x, p[k - 1].y); LineTo(c, x, p[k].y)
    END;
    LineTo(c, p[k].x, p[k].y)
  END
END Step;

(* d3's curveCardinal, with its tension 0, and curveCatmullRom, with
   its alpha 0.5: the piece from p[k] to p[k + 1], with p[k - 1] and
   p[k + 2] the points beside it, the ends doubled *)
PROCEDURE Interpolating(VAR c: Builder; VAR p: ARRAY OF G.Point; n: INTEGER; catmull: BOOLEAN);
  CONST Eps = 1.0E-6;
  VAR k: INTEGER; p0, p1, p2, p3: G.Point; x1, y1, x2, y2: REAL;
    l01, l12, l23, l01a, l12a, l23a, a, m: REAL;

  PROCEDURE Dist(VAR a, b: G.Point): REAL;
  BEGIN
    RETURN Math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
  END Dist;

BEGIN
  FOR k := 0 TO n - 2 DO
    p1 := p[k]; p2 := p[k + 1];
    IF k > 0 THEN p0 := p[k - 1] ELSE p0 := p1 END;
    IF k + 2 < n THEN p3 := p[k + 2] ELSE p3 := p2 END;
    IF catmull THEN
      l01 := Dist(p0, p1); l12 := Dist(p1, p2); l23 := Dist(p2, p3);
      l01a := Math.sqrt(l01); l12a := Math.sqrt(l12); l23a := Math.sqrt(l23);
      x1 := p1.x; y1 := p1.y; x2 := p2.x; y2 := p2.y;
      IF l01a > Eps THEN
        a := 2 * l01 + 3 * l01a * l12a + l12;
        m := 3 * l01a * (l01a + l12a);
        x1 := (p1.x * a - p0.x * l12 + p2.x * l01) / m;
        y1 := (p1.y * a - p0.y * l12 + p2.y * l01) / m
      END;
      IF l23a > Eps THEN
        a := 2 * l23 + 3 * l23a * l12a + l12;
        m := 3 * l23a * (l23a + l12a);
        x2 := (p2.x * a + p1.x * l23 - p3.x * l12) / m;
        y2 := (p2.y * a + p1.y * l23 - p3.y * l12) / m
      END
    ELSE
      x1 := p1.x + (p2.x - p0.x) / 6; y1 := p1.y + (p2.y - p0.y) / 6;
      x2 := p2.x - (p3.x - p1.x) / 6; y2 := p2.y - (p3.y - p1.y) / 6
    END;
    CurveTo(c, x1, y1, x2, y2, p2.x, p2.y)
  END
END Interpolating;

(* d3's curveNatural: the natural cubic spline through the points, x
   and y each a function of the point's number *)
PROCEDURE Natural(VAR c: Builder; VAR p: ARRAY OF G.Point; n: INTEGER);
  VAR ax, bx: G.Points; k: INTEGER;

  (* d3's controlPoints, for one coordinate: v[0 .. n-1] gives a[0 ..
     n-2], the first control points, and b, the second *)
  PROCEDURE Controls(VAR v: ARRAY OF REAL; VAR a, b: ARRAY OF REAL);
    VAR i, m: INTEGER; r: REAL; aa, bb: POINTER TO ARRAY OF REAL;
  BEGIN
    m := n - 1;
    NEW(aa, m); NEW(bb, m);
    aa[0] := 0; bb[0] := 2; a[0] := v[0] + 2 * v[1];
    FOR i := 1 TO m - 2 DO
      aa[i] := 1; bb[i] := 4; a[i] := 4 * v[i] + 2 * v[i + 1]
    END;
    aa[m - 1] := 2; bb[m - 1] := 7; a[m - 1] := 8 * v[m - 1] + v[m];
    FOR i := 1 TO m - 1 DO
      r := aa[i] / bb[i - 1]; bb[i] := bb[i] - r; a[i] := a[i] - r * a[i - 1]
    END;
    a[m - 1] := a[m - 1] / bb[m - 1];
    FOR i := m - 2 TO 0 BY -1 DO a[i] := (a[i] - a[i + 1]) / bb[i] END;
    b[m - 1] := (v[m] + a[m - 1]) / 2;
    FOR i := 0 TO m - 2 DO b[i] := 2 * v[i + 1] - a[i + 1] END
  END Controls;

  PROCEDURE Coords(VAR a, b: G.Points);
    VAR v, ra, rb: POINTER TO ARRAY OF REAL; i: INTEGER;
  BEGIN
    NEW(v, n); NEW(ra, n); NEW(rb, n);
    FOR i := 0 TO n - 1 DO v[i] := p[i].x END;
    Controls(v^, ra^, rb^);
    a := G.NewPoints(n); b := G.NewPoints(n);
    FOR i := 0 TO n - 2 DO a[i].x := ra[i]; b[i].x := rb[i] END;
    FOR i := 0 TO n - 1 DO v[i] := p[i].y END;
    Controls(v^, ra^, rb^);
    FOR i := 0 TO n - 2 DO a[i].y := ra[i]; b[i].y := rb[i] END
  END Coords;

BEGIN
  IF n = 2 THEN LineTo(c, p[1].x, p[1].y); RETURN END;
  Coords(ax, bx);
  FOR k := 0 TO n - 2 DO
    CurveTo(c, ax[k].x, ax[k].y, bx[k].x, bx[k].y, p[k + 1].x, p[k + 1].y)
  END
END Natural;

(* d3's curveMonotoneX, and curveMonotoneY with x and y swapped: a
   cubic Hermite spline, monotone in x, with Steffen's slopes *)
PROCEDURE Monotone(VAR c: Builder; VAR p: ARRAY OF G.Point; n: INTEGER; swap: BOOLEAN);
  VAR q: G.Points; k: INTEGER; t: POINTER TO ARRAY OF REAL; h: REAL;

  PROCEDURE Sign(v: REAL): REAL;
  BEGIN
    IF v < 0 THEN RETURN -1 ELSIF v > 0 THEN RETURN 1 ELSE RETURN 0 END
  END Sign;

  PROCEDURE Min(a, b: REAL): REAL;
  BEGIN
    IF a < b THEN RETURN a ELSE RETURN b END
  END Min;

  (* d3's slope3, at q[i], between q[i - 1] and q[i + 1]; a slope over
     no width is infinite *)
  PROCEDURE Slope3(i: INTEGER): REAL;
    VAR h0, h1, d0, d1, s0, s1, pp: REAL;
  BEGIN
    h0 := q[i].x - q[i - 1].x; h1 := q[i + 1].x - q[i].x;
    d0 := q[i].y - q[i - 1].y; d1 := q[i + 1].y - q[i].y;
    IF (h0 = 0) & (h1 = 0) THEN RETURN 0
    ELSIF h0 = 0 THEN
      IF d0 = 0 THEN RETURN 0 END;
      s1 := d1 / h1; RETURN (Sign(d0) + Sign(s1)) * ABS(s1)
    ELSIF h1 = 0 THEN
      IF d1 = 0 THEN RETURN 0 END;
      s0 := d0 / h0; RETURN (Sign(s0) + Sign(d1)) * ABS(s0)
    ELSIF h0 + h1 = 0 THEN RETURN 0
    END;
    s0 := d0 / h0; s1 := d1 / h1;
    pp := (s0 * h1 + s1 * h0) / (h0 + h1);
    RETURN (Sign(s0) + Sign(s1)) * Min(Min(ABS(s0), ABS(s1)), 0.5 * ABS(pp))
  END Slope3;

  (* d3's slope2, at the end of the piece from q[i] to q[i + 1], whose
     other end has the slope s *)
  PROCEDURE Slope2(i: INTEGER; s: REAL): REAL;
    VAR h: REAL;
  BEGIN
    h := q[i + 1].x - q[i].x;
    IF h = 0 THEN RETURN s ELSE RETURN (3 * (q[i + 1].y - q[i].y) / h - s) / 2 END
  END Slope2;

  PROCEDURE Piece(i: INTEGER; t0, t1: REAL);
    VAR dx: REAL; a, b, e: G.Point;
  BEGIN
    dx := (q[i + 1].x - q[i].x) / 3;
    a.x := q[i].x + dx; a.y := q[i].y + dx * t0;
    b.x := q[i + 1].x - dx; b.y := q[i + 1].y - dx * t1;
    e := q[i + 1];
    IF swap THEN
      CurveTo(c, a.y, a.x, b.y, b.x, e.y, e.x)
    ELSE
      CurveTo(c, a.x, a.y, b.x, b.y, e.x, e.y)
    END
  END Piece;

BEGIN
  IF n = 2 THEN LineTo(c, p[1].x, p[1].y); RETURN END;
  q := G.NewPoints(n);
  FOR k := 0 TO n - 1 DO
    IF swap THEN q[k].x := p[k].y; q[k].y := p[k].x ELSE q[k] := p[k] END
  END;
  NEW(t, n);
  FOR k := 1 TO n - 2 DO t[k] := Slope3(k) END;
  t[0] := Slope2(0, t[1]);
  (* slope2 at the last point, from the piece before it, reversed *)
  h := q[n - 1].x - q[n - 2].x;
  IF h = 0 THEN t[n - 1] := t[n - 2]
  ELSE t[n - 1] := (3 * (q[n - 1].y - q[n - 2].y) / h - t[n - 2]) / 2
  END;
  FOR k := 0 TO n - 2 DO Piece(k, t[k], t[k + 1]) END
END Monotone;

(* d3's curveBumpX and curveBumpY *)
PROCEDURE Bump(VAR c: Builder; VAR p: ARRAY OF G.Point; n: INTEGER; y: BOOLEAN);
  VAR k: INTEGER; m: REAL;
BEGIN
  FOR k := 1 TO n - 1 DO
    IF y THEN
      m := (p[k - 1].y + p[k].y) / 2;
      CurveTo(c, p[k - 1].x, m, p[k].x, m, p[k].x, p[k].y)
    ELSE
      m := (p[k - 1].x + p[k].x) / 2;
      CurveTo(c, m, p[k - 1].y, m, p[k].y, p[k].x, p[k].y)
    END
  END
END Bump;

(* TRUE if curve draws only straight pieces through n points *)
PROCEDURE Straight*(curve: INTEGER; n: INTEGER): BOOLEAN;
BEGIN
  RETURN (n <= 2) & (curve # F.BumpX) & (curve # F.BumpY)
    OR (curve = F.Linear) OR (curve = F.Step) OR (curve = F.StepBefore)
    OR (curve = F.StepAfter)
END Straight;

(* The Bézier curves that draw curve through p[0 .. n-1], in b[0 ..
   nb-1]; a curve not known is drawn as basis *)
PROCEDURE Make*(curve: INTEGER; VAR p: ARRAY OF G.Point; n: INTEGER; VAR b: G.Points; VAR nb: INTEGER);
  VAR c: Builder; k: INTEGER;
BEGIN
  IF (curve = F.Basis) OR (curve < F.Basis) OR (curve > F.BumpY) THEN
    G.Basis(p, n, b, nb); RETURN
  END;
  c.b := G.NewPoints(9 * n + 4); c.nb := 0;
  IF n > 0 THEN Add(c, p[0].x, p[0].y) END;
  IF n >= 2 THEN
    CASE curve OF
      F.Linear: FOR k := 1 TO n - 1 DO LineTo(c, p[k].x, p[k].y) END
    | F.Step: Step(c, p, n, 0.5)
    | F.StepBefore: Step(c, p, n, 0)
    | F.StepAfter: Step(c, p, n, 1)
    | F.Cardinal: Interpolating(c, p, n, FALSE)
    | F.CatmullRom: Interpolating(c, p, n, TRUE)
    | F.Natural: Natural(c, p, n)
    | F.MonotoneX: Monotone(c, p, n, FALSE)
    | F.MonotoneY: Monotone(c, p, n, TRUE)
    | F.BumpX: Bump(c, p, n, FALSE)
    | F.BumpY: Bump(c, p, n, TRUE)
    END
  END;
  b := c.b; nb := c.nb
END Make;

(* The points of the curve, from Make's b[0 .. nb-1]: for a straight
   curve its corners, else samples, each Bézier curve in s pieces *)
PROCEDURE Sample*(straight: BOOLEAN; VAR b: ARRAY OF G.Point; nb, s: INTEGER; VAR r: G.Points; VAR nr: INTEGER);
  VAR k, t: INTEGER;
BEGIN
  IF straight THEN s := 1 END;
  r := G.NewPoints(1 + (nb - 1) DIV 3 * s); nr := 0;
  IF nb = 0 THEN RETURN END;
  r[0] := b[0]; nr := 1;
  k := 0;
  WHILE k + 3 < nb DO
    IF straight THEN r[nr] := b[k + 3]; INC(nr)
    ELSE
      FOR t := 1 TO s DO G.OnCurve(b[k], b[k + 1], b[k + 2], b[k + 3], t / s, r[nr]); INC(nr) END
    END;
    INC(k, 3)
  END
END Sample;

END PmCurves.
