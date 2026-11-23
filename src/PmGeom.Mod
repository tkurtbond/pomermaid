MODULE PmGeom;
(* PmGeom: points, and the geometry the layout and the writers share:
   where a line from a shape's centre leaves its outline, and the cubic
   Bézier curves of a B-spline.

   Coordinates are in points, x to the right and y down, as in the
   layout; the pic writer turns y over. *)

IMPORT Math;

TYPE
  Point* = RECORD x*, y*: REAL END;
  Points* = POINTER TO ARRAY OF Point;

(* A new array of n points or more *)
PROCEDURE NewPoints*(n: INTEGER): Points;
  VAR p: Points;
BEGIN
  IF n < 1 THEN n := 1 END;
  NEW(p, n);
  RETURN p
END NewPoints;

(* Sets p to (x, y) *)
PROCEDURE Set*(VAR p: Point; x, y: REAL);
BEGIN
  p.x := x; p.y := y
END Set;

(* Where the line from the centre (cx, cy) of a w by h rectangle
   towards (px, py) leaves the rectangle (dagre's intersectRect).
   (x, y) is the centre when the two points are the same. *)
PROCEDURE RectIntersect*(cx, cy, w, h, px, py: REAL; VAR x, y: REAL);
  VAR dx, dy, hw, hh: REAL;
BEGIN
  dx := px - cx; dy := py - cy; hw := w / 2; hh := h / 2;
  IF (dx = 0) & (dy = 0) THEN x := cx; y := cy
  ELSIF ABS(dy) * hw > ABS(dx) * hh THEN
    IF dy < 0 THEN hh := -hh END;
    x := cx + hh * dx / dy; y := cy + hh
  ELSE
    IF dx < 0 THEN hw := -hw END;
    x := cx + hw; y := cy + hw * dy / dx
  END
END RectIntersect;

(* Where the line from the centre (cx, cy) of an ellipse of radii rx
   and ry towards (px, py) leaves it *)
PROCEDURE EllipseIntersect*(cx, cy, rx, ry, px, py: REAL; VAR x, y: REAL);
  VAR dx, dy, d: REAL;
BEGIN
  dx := px - cx; dy := py - cy;
  IF ((dx = 0) & (dy = 0)) OR (rx <= 0) OR (ry <= 0) THEN x := cx; y := cy
  ELSE
    d := Math.sqrt(dx * dx / (rx * rx) + dy * dy / (ry * ry));
    x := cx + dx / d; y := cy + dy / d
  END
END EllipseIntersect;

(* Where the segment from (ax, ay) to (bx, by) meets the one from
   (cx, cy) to (dx, dy): t along the first, from 0 to 1. FALSE when
   they do not meet or are parallel. *)
PROCEDURE SegmentsMeet*(ax, ay, bx, by, cx, cy, dx, dy: REAL; VAR t: REAL): BOOLEAN;
  VAR den, u: REAL;
BEGIN
  den := (bx - ax) * (dy - cy) - (by - ay) * (dx - cx);
  IF den = 0 THEN RETURN FALSE END;
  t := ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / den;
  u := ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / den;
  RETURN (t >= 0) & (t <= 1) & (u >= 0) & (u <= 1)
END SegmentsMeet;

(* Where the line from the centre (cx, cy) of the polygon
   poly[0 .. n-1] towards (px, py) leaves it: of the points where the
   line meets the polygon's sides, the one nearest (px, py), as
   Mermaid's intersectPolygon. The line is taken as far as is needed
   to reach the outline. (x, y) is the centre when it meets no side. *)
PROCEDURE PolygonIntersect*(cx, cy: REAL; VAR poly: ARRAY OF Point; n: INTEGER;
                            px, py: REAL; VAR x, y: REAL);
  VAR i, j: INTEGER; t, best, dx, dy, far, len: REAL; found: BOOLEAN;
BEGIN
  x := cx; y := cy;
  dx := px - cx; dy := py - cy;
  IF (dx = 0) & (dy = 0) THEN RETURN END;
  (* a point beyond every corner, on the line *)
  far := 0;
  FOR i := 0 TO n - 1 DO
    len := ABS(poly[i].x - cx) + ABS(poly[i].y - cy);
    IF len > far THEN far := len END
  END;
  len := Math.sqrt(dx * dx + dy * dy);
  IF len < far * 2 THEN dx := dx * far * 2 / len; dy := dy * far * 2 / len END;
  found := FALSE; best := 0;
  FOR i := 0 TO n - 1 DO
    j := (i + 1) MOD n;
    IF SegmentsMeet(cx, cy, cx + dx, cy + dy, poly[i].x, poly[i].y, poly[j].x, poly[j].y, t)
       & (~found OR (t > best)) THEN
      best := t; found := TRUE
    END
  END;
  IF found THEN x := cx + best * dx; y := cy + best * dy END
END PolygonIntersect;

(* Where the segment from (ax, ay) to (bx, by) first meets a side of
   the polygon poly[0 .. n-1], the point nearest (ax, ay). FALSE if it
   meets none. *)
PROCEDURE FirstHit*(ax, ay, bx, by: REAL; VAR poly: ARRAY OF Point; n: INTEGER;
                    VAR x, y: REAL): BOOLEAN;
  VAR i, j: INTEGER; t, best: REAL; found: BOOLEAN;
BEGIN
  found := FALSE; best := 0;
  FOR i := 0 TO n - 1 DO
    j := (i + 1) MOD n;
    IF SegmentsMeet(ax, ay, bx, by, poly[i].x, poly[i].y, poly[j].x, poly[j].y, t)
       & (~found OR (t < best)) THEN
      best := t; found := TRUE
    END
  END;
  IF found THEN x := ax + best * (bx - ax); y := ay + best * (by - ay) END;
  RETURN found
END FirstHit;

(* The cubic Bézier curves that draw the uniform B-spline whose control
   points are p[0 .. n-1], as d3's curveBasis draws it: it starts at
   p[0] and ends at p[n-1], with a straight piece at each end. b gets
   the start and then three points for each curve, the two control
   points and its end, nb of them in all; a straight piece is a curve
   with its control points at its thirds. *)
PROCEDURE Basis*(VAR p: ARRAY OF Point; n: INTEGER; VAR b: Points; VAR nb: INTEGER);
  VAR k: INTEGER; x0, y0, x1, y1: REAL;

  PROCEDURE Add(x, y: REAL);
  BEGIN
    b[nb].x := x; b[nb].y := y; INC(nb)
  END Add;

  PROCEDURE LineTo(x, y: REAL);
    VAR sx, sy: REAL;
  BEGIN
    sx := b[nb - 1].x; sy := b[nb - 1].y;
    Add((2 * sx + x) / 3, (2 * sy + y) / 3);
    Add((sx + 2 * x) / 3, (sy + 2 * y) / 3);
    Add(x, y)
  END LineTo;

  PROCEDURE Curve(x0, y0, x1, y1, x, y: REAL);
  BEGIN
    Add((2 * x0 + x1) / 3, (2 * y0 + y1) / 3);
    Add((x0 + 2 * x1) / 3, (y0 + 2 * y1) / 3);
    Add((x0 + 4 * x1 + x) / 6, (y0 + 4 * y1 + y) / 6)
  END Curve;

BEGIN
  b := NewPoints(3 * n + 4); nb := 0;
  IF n <= 0 THEN RETURN END;
  Add(p[0].x, p[0].y);
  IF n = 1 THEN RETURN END;
  IF n = 2 THEN LineTo(p[1].x, p[1].y); RETURN END;
  x0 := p[0].x; y0 := p[0].y; x1 := p[1].x; y1 := p[1].y;
  LineTo((5 * x0 + x1) / 6, (5 * y0 + y1) / 6);
  FOR k := 2 TO n - 1 DO
    Curve(x0, y0, x1, y1, p[k].x, p[k].y);
    x0 := x1; y0 := y1; x1 := p[k].x; y1 := p[k].y
  END;
  Curve(x0, y0, x1, y1, x1, y1);
  LineTo(x1, y1)
END Basis;

(* The point at t, from 0 to 1, on the cubic Bézier curve from a with
   control points b and c to d *)
PROCEDURE OnCurve*(VAR a, b, c, d: Point; t: REAL; VAR r: Point);
  VAR s, u, k0, k1, k2, k3: LONGREAL;
BEGIN
  (* in LONGREAL, rounded to REAL once: REAL arithmetic rounds each step
     on x86-64 but not in i386's x87, and the sampled points of a curve
     came out a digit apart *)
  u := t; s := 1 - u;
  k0 := s * s * s; k1 := 3 * s * s * u; k2 := 3 * s * u * u; k3 := u * u * u;
  r.x := SHORT(k0 * a.x + k1 * b.x + k2 * c.x + k3 * d.x);
  r.y := SHORT(k0 * a.y + k1 * b.y + k2 * c.y + k3 * d.y)
END OnCurve;

END PmGeom.
