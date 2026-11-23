MODULE PmArchLayout;
(* PmArchLayout: an architecture diagram, PmArch's, laid out in
   Mermaid's pixels, taken at the drawing's size, 16 pixels to the
   size, and drawn as Mermaid 12.3.0's architecture renderer draws it.
   Lengths are in pixels, y down.

   Mermaid places the services and junctions with fcose, a force
   directed layout, from the grids its database makes; pomermaid places
   them on those grids (decision 55):

   - each grid is PmArch's, y up; "align row" puts its members on the
     first's row, one column apart, rightwards, and "align column" in
     the first's column, one row apart, downwards;
   - the grids are set side by side, left to right, their tops level;
   - a node whose cell is taken moves right to the next free one;
   - columns are iconSize and max(120, 40 k + 20) apart, k the most
     group boundaries an edge between two nodes in them would cross;
     rows the same, and the upper row's tallest title.

   A service is an icon, iconSize square: database, server, disk,
   internet, cloud or blank (a "mermaid-architecture:" prefix is
   dropped), any other a "?" (Mermaid's unknown icon); a service with a
   text in its icon's place is a blank icon with the text, white,
   wrapped and at most as many lines as fit; one with neither is a
   dashed outline. Its title, wrapped at 1.5 iconSize, is centred below
   it. A junction draws nothing.

   An edge runs from its first end's side to its second's, by one bend
   if its sides are one across and one up or down and its ends not in
   line; its arrows are triangles; "{group}" starts or ends it outside
   the group. Its title is along it, turned for an edge up or down, and
   by 45 degrees for an edge that bends.

   A group is a dashed box around its members, their titles and the
   groups in it, padding (40) out; its icon, 30 square, and title at
   its top left. A group with nothing in it is not drawn.

   The colours are PmStyle.ArchColours'. *)

IMPORT MathL, M := PmMetrics, F := PmFlow, S := PmStyle, A := PmArch, D := PmDraw,
  FL := PmFlowLayout, L := PmLex;

CONST
  Blue = 087EBFH; White = 0FFFFFFH;
  GroupIcon = 30;
  MaxPts = 512;

TYPE
  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD (D.DrawingDesc)
    d-: A.Diagram
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;
  Ints = POINTER TO ARRAY OF LONGINT;

VAR
  l: Layout;
  d: A.Diagram;
  th: S.ArchTheme;
  size, icon: LONGREAL;      (* the text's, the icons' *)
  cx, cy: Reals;             (* each node's middle, by index *)
  col, row: Ints;            (* each node's cell *)
  gx0, gy0, gx1, gy1: Reals; (* each group's box, by index *)
  (* the path being read, flattened, for a filled shape *)
  px, py: ARRAY MaxPts OF LONGREAL; np: INTEGER;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a ELSE RETURN b END
END Max;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a ELSE RETURN b END
END Min;

(* lab wrapped at maxW pixels, and its size, w by h; an empty label's is 0 *)
PROCEDURE Wrapped(lab: F.Label; maxW: LONGREAL; VAR w, h: LONGREAL): F.Label;
BEGIN
  lab := FL.Wrap(l.font, lab, SHORT(size * l.px), SHORT(maxW * l.px));
  IF lab.n = 0 THEN w := 0; h := 0 ELSE D.Measure(l, lab, size, w, h) END;
  RETURN lab
END Wrapped;

(* lab's first n lines *)
PROCEDURE Lines(lab: F.Label; n: INTEGER): F.Label;
  VAR r: F.Label; ln, c, last: F.Line;
BEGIN
  IF lab.n <= n THEN RETURN lab END;
  NEW(r); r^ := lab^; r.n := n; r.lines := NIL; last := NIL; ln := lab.lines;
  WHILE n > 0 DO
    NEW(c); c^ := ln^; c.next := NIL;
    IF last = NIL THEN r.lines := c ELSE last.next := c END;
    last := c; ln := ln.next; DEC(n)
  END;
  RETURN r
END Lines;

(* Paths *)

PROCEDURE Pt(x, y: LONGREAL);
BEGIN
  IF np < MaxPts THEN px[np] := x; py[np] := y; INC(np) END
END Pt;

PROCEDURE Curve(x0, y0, x1, y1, x2, y2, x3, y3: LONGREAL);
  VAR k: INTEGER; t, u: LONGREAL;
BEGIN
  D.CurveTo(x1, y1, x2, y2, x3, y3);
  FOR k := 1 TO 8 DO
    t := k / 8; u := 1 - t;
    Pt(u*u*u*x0 + 3*u*u*t*x1 + 3*u*t*t*x2 + t*t*t*x3, u*u*u*y0 + 3*u*u*t*y1 + 3*u*t*t*y2 + t*t*t*y3)
  END
END Curve;

(* The SVG path s, its commands m, c, s, q, l, h and v, absolute and
   relative, and z, in a box 80 square, made iconSize k / 80 and moved
   to (ox, oy); started, for D.AddPath, and flattened, in px and py *)
PROCEDURE Path(s: ARRAY OF CHAR; ox, oy, k: LONGREAL);
  VAR i: INTEGER; cmd: CHAR; x, y, sx, sy, cx2, cy2, a1, a2, a3, a4, a5, a6: LONGREAL;
    rel, started: BOOLEAN;

  PROCEDURE Sep;
  BEGIN
    WHILE (s[i] = " ") OR (s[i] = ",") DO INC(i) END
  END Sep;

  PROCEDURE IsNum(): BOOLEAN;
  BEGIN
    Sep;
    RETURN (s[i] = "-") OR (s[i] = ".") OR (s[i] >= "0") & (s[i] <= "9")
  END IsNum;

  PROCEDURE Num(): LONGREAL;
    VAR v, f: LONGREAL; neg, dot: BOOLEAN;
  BEGIN
    Sep; v := 0; neg := FALSE; dot := FALSE; f := 1;
    IF s[i] = "-" THEN neg := TRUE; INC(i) END;
    WHILE (s[i] >= "0") & (s[i] <= "9") OR (s[i] = ".") & ~dot DO
      IF s[i] = "." THEN dot := TRUE
      ELSIF dot THEN f := f / 10; v := v + f * (ORD(s[i]) - ORD("0"))
      ELSE v := v * 10 + (ORD(s[i]) - ORD("0"))
      END;
      INC(i)
    END;
    IF neg THEN v := -v END;
    RETURN v
  END Num;

  PROCEDURE X(v: LONGREAL): LONGREAL;
  BEGIN RETURN ox + v * k
  END X;

  PROCEDURE Y(v: LONGREAL): LONGREAL;
  BEGIN RETURN oy + v * k
  END Y;

  PROCEDURE To(nx, ny: LONGREAL);
  BEGIN
    D.LineTo(X(nx), Y(ny)); Pt(X(nx), Y(ny)); x := nx; y := ny
  END To;

  PROCEDURE C(x1, y1, x2, y2, x3, y3: LONGREAL);
  BEGIN
    Curve(X(x), Y(y), X(x1), Y(y1), X(x2), Y(y2), X(x3), Y(y3));
    cx2 := x2; cy2 := y2; x := x3; y := y3
  END C;

BEGIN
  i := 0; x := 0; y := 0; sx := 0; sy := 0; cx2 := 0; cy2 := 0; np := 0; started := FALSE;
  cmd := 0X;
  LOOP
    Sep;
    IF (s[i] # 0X) & ~IsNum() THEN cmd := s[i]; INC(i)
    ELSIF s[i] = 0X THEN EXIT
    END;
    rel := (cmd >= "a") & (cmd <= "z");
    IF (cmd = "m") OR (cmd = "M") THEN
      a1 := Num(); a2 := Num();
      IF rel THEN a1 := a1 + x; a2 := a2 + y END;
      x := a1; y := a2; sx := x; sy := y; cx2 := x; cy2 := y;
      D.MoveTo(X(x), Y(y)); Pt(X(x), Y(y));
      IF rel THEN cmd := "l" ELSE cmd := "L" END
    ELSIF (cmd = "l") OR (cmd = "L") THEN
      a1 := Num(); a2 := Num();
      IF rel THEN To(x + a1, y + a2) ELSE To(a1, a2) END;
      cx2 := x; cy2 := y
    ELSIF (cmd = "h") OR (cmd = "H") THEN
      a1 := Num(); IF rel THEN To(x + a1, y) ELSE To(a1, y) END; cx2 := x; cy2 := y
    ELSIF (cmd = "v") OR (cmd = "V") THEN
      a1 := Num(); IF rel THEN To(x, y + a1) ELSE To(x, a1) END; cx2 := x; cy2 := y
    ELSIF (cmd = "c") OR (cmd = "C") THEN
      a1 := Num(); a2 := Num(); a3 := Num(); a4 := Num(); a5 := Num(); a6 := Num();
      IF rel THEN C(x + a1, y + a2, x + a3, y + a4, x + a5, y + a6) ELSE C(a1, a2, a3, a4, a5, a6) END
    ELSIF (cmd = "s") OR (cmd = "S") THEN
      a3 := Num(); a4 := Num(); a5 := Num(); a6 := Num();
      a1 := 2 * x - cx2; a2 := 2 * y - cy2;
      IF rel THEN C(a1, a2, x + a3, y + a4, x + a5, y + a6) ELSE C(a1, a2, a3, a4, a5, a6) END
    ELSIF (cmd = "q") OR (cmd = "Q") THEN
      a1 := Num(); a2 := Num(); a5 := Num(); a6 := Num();
      IF rel THEN a1 := a1 + x; a2 := a2 + y; a5 := a5 + x; a6 := a6 + y END;
      C(x + 2 / 3 * (a1 - x), y + 2 / 3 * (a2 - y), a5 + 2 / 3 * (a1 - a5), a6 + 2 / 3 * (a2 - a6), a5, a6);
      cx2 := x; cy2 := y
    ELSIF (cmd = "z") OR (cmd = "Z") THEN
      To(sx, sy); cx2 := x; cy2 := y; cmd := 0X
    ELSE EXIT
    END
  END
END Path;

(* The path s stroked white, as an icon's *)
PROCEDURE Stroke(s: ARRAY OF CHAR; ox, oy, k: LONGREAL);
BEGIN
  Path(s, ox, oy, k); D.AddPath(l, White, 2 * k)
END Stroke;

(* The path s filled white *)
PROCEDURE Fill(s: ARRAY OF CHAR; ox, oy, k: LONGREAL);
BEGIN
  Path(s, ox, oy, k); D.AddPoly(l, px, py, np, White, -1, 0)
END Fill;

PROCEDURE Ellipse(x, y, rx, ry, width: LONGREAL);
  VAR kx, ky: LONGREAL;
BEGIN
  kx := rx * D.Kappa; ky := ry * D.Kappa;
  D.MoveTo(x + rx, y);
  D.CurveTo(x + rx, y + ky, x + kx, y + ry, x, y + ry);
  D.CurveTo(x - kx, y + ry, x - rx, y + ky, x - rx, y);
  D.CurveTo(x - rx, y - ky, x - kx, y - ry, x, y - ry);
  D.CurveTo(x + kx, y - ry, x + rx, y - ky, x + rx, y);
  D.AddPath(l, White, width)
END Ellipse;

(* The icon called name, iconSize k / 80 square, its top left (x, y);
   FALSE if pomermaid does not know it *)
PROCEDURE Icon(name: L.Str; x, y, k: LONGREAL): BOOLEAN;
  VAR n: ARRAY 64 OF CHAR; i, j: INTEGER; yy, rr: LONGREAL; q: F.Label; qm: ARRAY 2 OF CHAR;

  PROCEDURE PX(v: LONGREAL): LONGREAL; BEGIN RETURN x + v * k END PX;
  PROCEDURE PY(v: LONGREAL): LONGREAL; BEGIN RETURN y + v * k END PY;

BEGIN
  n := "mermaid-architecture:"; j := 0;
  WHILE (n[j] # 0X) & (name[j] = n[j]) DO INC(j) END;
  IF n[j] # 0X THEN j := 0 END;
  i := 0;
  WHILE (name[j] # 0X) & (i < LEN(n) - 1) DO n[i] := name[j]; INC(i); INC(j) END;
  n[i] := 0X;
  D.AddRect(l, x, y, 80 * k, 80 * k, 0, Blue, -1, 0);
  IF n = "database" THEN
    yy := 57.86D0;
    FOR i := 0 TO 2 DO
      Stroke("m20,0c0,3.94,8.95,7.14,20,7.14s20-3.2,20-7.14", x, y + yy * k, k);
      yy := yy - 11.905D0
    END;
    Ellipse(PX(40), PY(22.14D0), 20 * k, 7.14D0 * k, 2 * k);
    D.AddLine(l, PX(20), PY(57.86D0), PX(20), PY(22.14D0), White, 2 * k, 0);
    D.AddLine(l, PX(60), PY(57.86D0), PX(60), PY(22.14D0), White, 2 * k, 0)
  ELSIF n = "server" THEN
    D.AddRect(l, PX(17.5D0), PY(17.5D0), 45 * k, 45 * k, 2 * k, -1, White, 2 * k);
    D.AddLine(l, PX(17.5D0), PY(32.5D0), PX(62.5D0), PY(32.5D0), White, 2 * k, 0);
    D.AddLine(l, PX(17.5D0), PY(47.5D0), PX(62.5D0), PY(47.5D0), White, 2 * k, 0);
    yy := 25;
    FOR i := 0 TO 2 DO
      D.AddRect(l, PX(43.75D0), PY(yy - 1), 12.5D0 * k, 2 * k, k, White, -1, 0);
      D.AddCircle(l, PX(32.5D0), PY(yy), 0.75D0 * k, White, White, k);
      D.AddCircle(l, PX(27.5D0), PY(yy), 0.75D0 * k, White, White, k);
      D.AddCircle(l, PX(22.5D0), PY(yy), 0.75D0 * k, White, White, k);
      yy := yy + 15
    END
  ELSIF n = "disk" THEN
    D.AddRect(l, PX(20), PY(15), 40 * k, 50 * k, k, -1, White, 2 * k);
    rr := 0.8D0 * k;
    D.AddCircle(l, PX(24), PY(19.17D0), rr, -1, White, 2 * k);
    D.AddCircle(l, PX(56), PY(19.17D0), rr, -1, White, 2 * k);
    D.AddCircle(l, PX(24), PY(60.83D0), rr, -1, White, 2 * k);
    D.AddCircle(l, PX(56), PY(60.83D0), rr, -1, White, 2 * k);
    Ellipse(PX(40), PY(33.75D0), 14 * k, 14.58D0 * k, 2 * k);
    D.AddCircle(l, PX(40), PY(33.75D0), 4.08D0 * k, White, -1, 0);
    Fill("m37.51,42.52l-4.83,13.22c-.26.71-1.1,1.02-1.76.64l-4.18-2.42c-.66-.38-.81-1.26-.33-1.84l9.01-10.8c.88-1.05,2.56-.08,2.09,1.2Z",
      x, y, k)
  ELSIF n = "internet" THEN
    D.AddCircle(l, PX(40), PY(40), 22.5D0 * k, -1, White, 2 * k);
    D.AddLine(l, PX(40), PY(17.5D0), PX(40), PY(62.5D0), White, 2 * k, 0);
    D.AddLine(l, PX(17.5D0), PY(40), PX(62.5D0), PY(40), White, 2 * k, 0);
    D.AddLine(l, PX(19.75D0), PY(30.1D0), PX(60.25D0), PY(30.1D0), White, 2 * k, 0);
    D.AddLine(l, PX(19.75D0), PY(49.9D0), PX(60.25D0), PY(49.9D0), White, 2 * k, 0);
    Stroke("m39.99,17.51c-15.28,11.1-15.28,33.88,0,44.98", x, y, k);
    Stroke("m40.01,17.51c15.28,11.1,15.28,33.88,0,44.98", x, y, k)
  ELSIF n = "cloud" THEN
    Stroke("m65,47.5c0,2.76-2.24,5-5,5H20c-2.76,0-5-2.24-5-5,0-1.87,1.03-3.51,2.56-4.36-.04-.21-.06-.42-.06-.64,0-2.6,2.48-4.74,5.65-4.97,1.65-4.51,6.34-7.76,11.85-7.76.86,0,1.69.08,2.5.23,2.09-1.57,4.69-2.5,7.5-2.5,6.1,0,11.19,4.38,12.28,10.17,2.14.56,3.72,2.51,3.72,4.83,0,.03,0,.07-.01.1,2.29.46,4.01,2.48,4.01,4.9Z",
      x, y, k)
  ELSIF n = "blank" THEN
  ELSE
    qm := "?"; q := F.TextLabel(qm, 0, 1);
    D.AddText(l, q, PX(40), PY(42), 67.75D0 * k, 0, White);
    RETURN FALSE
  END;
  RETURN TRUE
END Icon;

(* Places *)

(* The groups a and b are in, from the outermost: how many boundaries
   a line from one to the other crosses *)
PROCEDURE Crossed(a, b: A.Group): LONGINT;
  VAR n: LONGINT; p, q: A.Group;
BEGIN
  n := 0; p := a; q := b;
  WHILE (p # NIL) & (q # NIL) & (p.depth > q.depth) DO p := p.parent; INC(n) END;
  WHILE (p # NIL) & (q # NIL) & (q.depth > p.depth) DO q := q.parent; INC(n) END;
  IF p = NIL THEN WHILE q # NIL DO q := q.parent; INC(n) END
  ELSIF q = NIL THEN WHILE p # NIL DO p := p.parent; INC(n) END
  ELSE
    WHILE p # q DO p := p.parent; q := q.parent; INC(n, 2) END
  END;
  RETURN n
END Crossed;

(* Each node's cell *)
PROCEDURE Cells;
  VAR n, m: A.Node; a: A.Align; k, j, mp, base, i: LONGINT;
    map, minX, maxX, maxY, off: Ints;
BEGIN
  NEW(col, d.nNodes + 1); NEW(row, d.nNodes + 1); NEW(map, d.nNodes + 1);
  n := d.nodes;
  WHILE n # NIL DO col[n.index] := n.gx; row[n.index] := n.gy; map[n.index] := n.map; n := n.next END;
  a := d.aligns;
  WHILE a # NIL DO
    m := a.members[0];
    FOR k := 1 TO a.n - 1 DO
      j := a.members[k].index; map[j] := map[m.index];
      IF a.column THEN col[j] := col[m.index]; row[j] := row[m.index] - k
      ELSE col[j] := col[m.index] + k; row[j] := row[m.index]
      END
    END;
    a := a.next
  END;
  (* a node whose cell in its map is taken moves right *)
  FOR i := 1 TO d.nNodes - 1 DO
    j := 0;
    WHILE j < i DO
      IF (map[j] = map[i]) & (col[j] = col[i]) & (row[j] = row[i]) THEN INC(col[i]); j := 0 ELSE INC(j) END
    END
  END;
  NEW(minX, d.nMaps + 1); NEW(maxX, d.nMaps + 1); NEW(maxY, d.nMaps + 1); NEW(off, d.nMaps + 1);
  FOR mp := 0 TO d.nMaps - 1 DO minX[mp] := MAX(LONGINT); maxX[mp] := MIN(LONGINT); maxY[mp] := MIN(LONGINT) END;
  FOR i := 0 TO d.nNodes - 1 DO
    mp := map[i];
    IF col[i] < minX[mp] THEN minX[mp] := col[i] END;
    IF col[i] > maxX[mp] THEN maxX[mp] := col[i] END;
    IF row[i] > maxY[mp] THEN maxY[mp] := row[i] END
  END;
  base := 0;
  FOR mp := 0 TO d.nMaps - 1 DO
    IF minX[mp] <= maxX[mp] THEN off[mp] := base - minX[mp]; base := base + maxX[mp] - minX[mp] + 1 END
  END;
  FOR i := 0 TO d.nNodes - 1 DO
    col[i] := col[i] + off[map[i]]; row[i] := maxY[map[i]] - row[i]
  END;
END Cells;

(* node i's title, wrapped, and its size *)
PROCEDURE Title(n: A.Node; VAR w, h: LONGREAL): F.Label;
BEGIN
  IF n.title = NIL THEN w := 0; h := 0; RETURN NIL END;
  RETURN Wrapped(n.title, icon * 1.5D0, w, h)
END Title;

(* The gap after an icon between two columns or rows whose nodes are
   a and b *)
PROCEDURE Gap(k: LONGINT): LONGREAL;
BEGIN
  RETURN icon + Max(3 * d.padding, d.padding * k + 20)
END Gap;

(* Each node's middle *)
PROCEDURE Places;
  VAR i, j, c, nCols, nRows, k: LONGINT; colX, rowY, tall: Reals; w, h: LONGREAL;
    lab: F.Label;
BEGIN
  nCols := 0; nRows := 0;
  FOR i := 0 TO d.nNodes - 1 DO
    IF col[i] + 1 > nCols THEN nCols := col[i] + 1 END;
    IF row[i] + 1 > nRows THEN nRows := row[i] + 1 END
  END;
  NEW(colX, nCols + 1); NEW(rowY, nRows + 1); NEW(tall, nRows + 1);
  FOR c := 0 TO nRows - 1 DO tall[c] := 0 END;
  FOR i := 0 TO d.nNodes - 1 DO
    lab := Title(d.byIndex[i], w, h);
    IF h > tall[row[i]] THEN tall[row[i]] := h END
  END;
  colX[0] := 0;
  FOR c := 1 TO nCols - 1 DO
    k := 0;
    FOR i := 0 TO d.nNodes - 1 DO
      IF col[i] = c - 1 THEN
        FOR j := 0 TO d.nNodes - 1 DO
          IF col[j] = c THEN IF Crossed(d.byIndex[i].parent, d.byIndex[j].parent) > k THEN k := Crossed(d.byIndex[i].parent, d.byIndex[j].parent) END END
        END
      END
    END;
    colX[c] := colX[c - 1] + Gap(k)
  END;
  rowY[0] := 0;
  FOR c := 1 TO nRows - 1 DO
    k := 0;
    FOR i := 0 TO d.nNodes - 1 DO
      IF row[i] = c - 1 THEN
        FOR j := 0 TO d.nNodes - 1 DO
          IF row[j] = c THEN IF Crossed(d.byIndex[i].parent, d.byIndex[j].parent) > k THEN k := Crossed(d.byIndex[i].parent, d.byIndex[j].parent) END END
        END
      END
    END;
    rowY[c] := rowY[c - 1] + Gap(k) + tall[c - 1]
  END;
  NEW(cx, d.nNodes + 1); NEW(cy, d.nNodes + 1);
  FOR i := 0 TO d.nNodes - 1 DO
    cx[i] := colX[col[i]] + icon / 2; cy[i] := rowY[row[i]] + icon / 2
  END
END Places;

(* Each group's box: its members', their titles' and its groups' *)
PROCEDURE Boxes;
  VAR gr, h: A.Group; n: A.Node; depth, i: LONGINT; w, th, x0, y0, x1, y1: LONGREAL; lab: F.Label;
BEGIN
  NEW(gx0, d.nGroups + 1); NEW(gy0, d.nGroups + 1); NEW(gx1, d.nGroups + 1); NEW(gy1, d.nGroups + 1);
  depth := 0; gr := d.groups;
  WHILE gr # NIL DO IF gr.depth > depth THEN depth := gr.depth END; gr := gr.next END;
  WHILE depth >= 0 DO
    gr := d.groups;
    WHILE gr # NIL DO
      IF (gr.depth = depth) & ~gr.empty THEN
        x0 := MAX(LONGREAL); y0 := MAX(LONGREAL); x1 := -MAX(LONGREAL); y1 := -MAX(LONGREAL);
        n := d.nodes;
        WHILE n # NIL DO
          IF n.parent = gr THEN
            i := n.index; lab := Title(n, w, th);
            x0 := Min(x0, Min(cx[i] - icon / 2, cx[i] - w / 2));
            x1 := Max(x1, Max(cx[i] + icon / 2, cx[i] + w / 2));
            y0 := Min(y0, cy[i] - icon / 2); y1 := Max(y1, cy[i] + icon / 2 + th)
          END;
          n := n.next
        END;
        h := d.groups;
        WHILE h # NIL DO
          IF (h.parent = gr) & ~h.empty THEN
            x0 := Min(x0, gx0[h.index]); y0 := Min(y0, gy0[h.index]);
            x1 := Max(x1, gx1[h.index]); y1 := Max(y1, gy1[h.index])
          END;
          h := h.next
        END;
        gx0[gr.index] := x0 - d.padding; gy0[gr.index] := y0 - d.padding;
        gx1[gr.index] := x1 + d.padding; gy1[gr.index] := y1 + d.padding
      END;
      gr := gr.next
    END;
    DEC(depth)
  END
END Boxes;

(* Drawing *)

(* Where an edge's end at n, side dir, starts, outside its group if group *)
PROCEDURE End(n: A.Node; dir: CHAR; group: BOOLEAN; VAR x, y: LONGREAL);
  VAR h: LONGREAL;
BEGIN
  x := cx[n.index]; y := cy[n.index];
  IF n.junction THEN h := 0 ELSE h := icon / 2 END;
  IF group THEN
    h := h + d.padding + 4;
    IF dir = "B" THEN h := h + 18 END
  END;
  CASE dir OF
    "L": x := x - h
  | "R": x := x + h
  | "T": y := y - h
  | "B": y := y + h
  END
END End;

(* An arrow into side dir at (x, y) *)
PROCEDURE Arrow(x, y: LONGREAL; dir: CHAR);
  VAR s: LONGREAL; ax, ay: ARRAY 3 OF LONGREAL; k: INTEGER;
BEGIN
  s := icon / 6;
  CASE dir OF
    "L": ax[0] := s; ay[0] := s / 2; ax[1] := 0; ay[1] := s; ax[2] := 0; ay[2] := 0;
      x := x - s + 2; y := y - s / 2
  | "R": ax[0] := 0; ay[0] := s / 2; ax[1] := s; ay[1] := 0; ax[2] := s; ay[2] := s;
      x := x - 2; y := y - s / 2
  | "T": ax[0] := 0; ay[0] := 0; ax[1] := s; ay[1] := 0; ax[2] := s / 2; ay[2] := s;
      x := x - s / 2; y := y - s + 2
  | "B": ax[0] := s / 2; ay[0] := 0; ax[1] := s; ay[1] := s; ax[2] := 0; ay[2] := s;
      x := x - s / 2; y := y - 2
  END;
  FOR k := 0 TO 2 DO ax[k] := ax[k] + x; ay[k] := ay[k] + y END;
  D.AddPoly(l, ax, ay, 3, th.arrow, -1, 0)
END Arrow;

PROCEDURE IsX(dir: CHAR): BOOLEAN;
BEGIN
  RETURN (dir = "L") OR (dir = "R")
END IsX;

PROCEDURE DrawEdge(e: A.Edge);
  VAR sx, sy, tx, ty, mx, my, w, h, fx, fy, W: LONGREAL; lab: F.Label; a, b: CHAR;
BEGIN
  End(e.lhs, e.lhsDir, e.lhsGroup, sx, sy);
  End(e.rhs, e.rhsDir, e.rhsGroup, tx, ty);
  mx := (sx + tx) / 2; my := (sy + ty) / 2;
  D.MoveTo(sx, sy);
  IF (IsX(e.lhsDir) # IsX(e.rhsDir)) & (sx # tx) & (sy # ty) THEN
    IF IsX(e.lhsDir) THEN D.LineTo(tx, sy) ELSE D.LineTo(sx, ty) END
  ELSE D.LineTo(mx, my)
  END;
  D.LineTo(tx, ty);
  D.AddPath(l, th.edge, 3);
  IF e.lhsInto THEN Arrow(sx, sy, e.lhsDir) END;
  IF e.rhsInto THEN Arrow(tx, ty, e.rhsDir) END;
  IF e.title # NIL THEN
    IF IsX(e.lhsDir) & IsX(e.rhsDir) THEN
      lab := Wrapped(e.title, ABS(tx - sx), w, h);
      D.AddText(l, lab, mx, my + h / 2, size, 0, th.text)
    ELSIF ~IsX(e.lhsDir) & ~IsX(e.rhsDir) THEN
      lab := Wrapped(e.title, ABS(ty - sy) / 1.5D0, w, h);
      D.AddText(l, lab, mx + h / 2, my, size, -90, th.text)
    ELSE
      lab := Wrapped(e.title, ABS(tx - sx) / 2, w, h);
      a := e.lhsDir; b := e.rhsDir;
      IF (a = "L") & (b = "T") OR (a = "T") & (b = "L") THEN fx := 1; fy := 1
      ELSIF (a = "B") & (b = "L") OR (a = "L") & (b = "B") THEN fx := 1; fy := -1
      ELSIF (a = "B") & (b = "R") OR (a = "R") & (b = "B") THEN fx := -1; fy := -1
      ELSE fx := -1; fy := 1
      END;
      W := (w + h) * MathL.cos(MathL.pi / 4);
      D.AddText(l, lab, mx + fx * W / 2, my + fy * W / 2, size, -fx * fy * 45, th.text)
    END
  END
END DrawEdge;

PROCEDURE DrawService(n: A.Node);
  VAR x0, y0, k, w, h: LONGREAL; lab: F.Label; i: LONGINT; known: BOOLEAN;
BEGIN
  i := n.index; x0 := cx[i] - icon / 2; y0 := cy[i] - icon / 2; k := icon / 80;
  IF n.iconLabel # NIL THEN
    D.AddRect(l, x0, y0, icon, icon, 0, Blue, -1, 0);
    lab := Wrapped(n.iconLabel, icon - 2, w, h);
    lab := Lines(lab, SHORT(ENTIER((icon - 2) / size)));
    D.AddText(l, lab, cx[i], cy[i], size, 0, White)
  ELSIF n.icon # NIL THEN known := Icon(n.icon, x0, y0, k)
  ELSE
    Path("M0,80 V5 Q0,0 5,0 H75 Q80,0 80,5 V80 Z", x0, y0, k);
    D.AddPath(l, th.groupLine, 2); D.Dash(l, 8)
  END;
  lab := Title(n, w, h);
  IF lab # NIL THEN D.AddText(l, lab, cx[i], y0 + icon + h / 2, size, 0, th.text) END
END DrawService;

PROCEDURE DrawGroup(gr: A.Group);
  VAR x0, y0, x1, y1, tx, ty, w, h: LONGREAL; lab: F.Label; known: BOOLEAN;
BEGIN
  x0 := gx0[gr.index]; y0 := gy0[gr.index]; x1 := gx1[gr.index]; y1 := gy1[gr.index];
  D.MoveTo(x0, y0); D.LineTo(x1, y0); D.LineTo(x1, y1); D.LineTo(x0, y1); D.LineTo(x0, y0);
  D.AddPath(l, th.groupLine, 2); D.Dash(l, 8);
  tx := x0 + 4; ty := y0 + 2;
  IF gr.icon # NIL THEN
    known := Icon(gr.icon, x0 + 1, y0 + 1, GroupIcon / 80);
    tx := tx + GroupIcon; ty := ty + 5
  END;
  IF gr.title # NIL THEN
    lab := Wrapped(gr.title, x1 - x0, w, h);
    D.AddText(l, lab, tx + w / 2, ty + h / 2, size, 0, th.text)
  END
END DrawGroup;

(* d laid out at size points, in lay *)
PROCEDURE Make*(dg: A.Diagram; font: M.Font; sz: REAL; VAR lay: Layout);
  VAR gr: A.Group; n: A.Node; e: A.Edge;
BEGIN
  NEW(l); lay := l; d := dg; l.d := d; D.Init(l, d.g, font, sz);
  S.Reset(d.g, l.px); S.ArchColours(th);
  size := d.fontSize; icon := d.iconSize;
  Cells; Places; Boxes;
  e := d.edges; WHILE e # NIL DO DrawEdge(e); e := e.next END;
  n := d.nodes; WHILE n # NIL DO IF ~n.junction THEN DrawService(n) END; n := n.next END;
  gr := d.groups; WHILE gr # NIL DO IF ~gr.empty THEN DrawGroup(gr) END; gr := gr.next END;
  D.Finish(l, d.padding);
  l := NIL; d := NIL; cx := NIL; cy := NIL; col := NIL; row := NIL;
  gx0 := NIL; gy0 := NIL; gx1 := NIL; gy1 := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: A.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmArchLayout.
