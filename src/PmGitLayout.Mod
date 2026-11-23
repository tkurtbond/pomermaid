MODULE PmGitLayout;
(* PmGitLayout: a git graph, PmGit's, laid out as Mermaid 12.3.0's
   gitGraphRenderer.ts lays it out, in its pixels, taken at the
   drawing's size, 16 pixels to the size. Lengths are in points, y
   down; a text's (x, y) is its middle, before it is turned.

   The branches are placed in their order (PmGit's sorted), each 50
   pixels after the last, 40 more with rotateCommitLabel, and, for TB
   and BT, half its name's width more. The commits are placed in the
   order made, each 50 pixels after the last (from 30 for TB and BT),
   reversed for BT; with parallelCommits, 40 after its closest parent.
   A commit is on its branch's line.

   The drawing is a list of items, in Mermaid's order:

   - with showBranches, each branch's dashed line, its label's
     rounded box in its colour, and its name, 16 pixels;
   - the arrows, from each commit's parents to it, 8 pixels wide with
     round caps, with quarter circles at their bends, each a Bézier;
     an arrow that would cross a commit between its ends goes round,
     along a free lane;
   - the commits' bullets: a circle in the branch's colour; a merge's
     with a smaller circle inside; a reverse's with a cross; a
     highlight's two squares; a cherry-pick's black circle with a
     white mark;
   - each commit's label, its id on a box blended over white, and its
     tags, each a label with a hole;
   - the title, 18 pixels, over the middle of the rest.

   The bounds are every item's, without the lines' widths, a turned
   text's its turned box's, widened by diagramPadding on each side;
   everything is moved for them to start at (0, 0). Each place and
   size is rounded once, as it is made, to a 1/8192 point (Snap). *)

IMPORT MathL, M := PmMetrics, F := PmFlow, G := PmGeom, S := PmStyle, H := PmGit;

CONST
  MermaidSize* = 16;
  BranchSize = 16;
  TitleSize = 18;
  Offset = 10;          (* LAYOUT_OFFSET *)
  Step = 40;            (* COMMIT_STEP *)
  PX = 4; PY = 2;
  DefaultPos = 30;
  Mid = 0.35D0;         (* a text's middle above its baseline, in sizes *)
  Kappa = 0.5522847498D0;
  MaxPath = 32;
  Black = 0; White = 0FFFFFFH;
  (* items *)
  Circle* = 0; Rect* = 1; Poly* = 2; Line* = 3; Curve* = 4; Text* = 5;

TYPE
  (* A circle: centre (x, y), radius r;
     a rectangle: (x, y) its top left corner, w by h, its corners
     rounded to r;
     a polygon: p[0 .. n-1];
     a line: from p[0] to p[1], dashed dash on and off, if dash > 0;
     a curve: Béziers, p[0], then 3 points each, its control points
     and its end, n points in all, with round caps;
     a text: lab, size points, its middle (x, y), w by h, turned
     angle degrees, clockwise, in colour line.
     Each is filled with fill and outlined with line width wide; -1 is
     neither *)
  Item* = POINTER TO ItemDesc;
  ItemDesc* = RECORD
    kind-: INTEGER;
    x-, y-, w-, h-, r-: REAL;
    p-: G.Points; n-: INTEGER;
    fill-, line-: LONGINT;
    width-, dash-: REAL;
    lab-: F.Label;
    size-, angle-: REAL;
    next-: Item
  END;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: H.Diagram;
    font-: M.Font;
    size-, vs-, px-: REAL;      (* the drawing's size, line spacing, a pixel *)
    width-, height-: REAL;
    items-: Item                (* in drawing order *)
  END;

  Reals = POINTER TO ARRAY OF LONGREAL;

VAR
  l: Layout;
  last: Item;
  d: H.Diagram;
  t: S.GitTheme;
  px: LONGREAL;
  minX, minY, maxX, maxY: LONGREAL;
  bpos: Reals;                  (* by branch index *)
  cx, cy, cpos, cpwo: Reals;    (* by place in d.bySeq *)
  maxPos: LONGREAL;
  lanes: Reals; nLanes: LONGINT;
  (* the path being made, in pixels *)
  qx, qy: ARRAY MaxPath OF LONGREAL; nq: INTEGER;

PROCEDURE Max(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a > b THEN RETURN a END;
  RETURN b
END Max;

PROCEDURE Min(a, b: LONGREAL): LONGREAL;
BEGIN
  IF a < b THEN RETURN a END;
  RETURN b
END Min;

(* x rounded to a 1/8192 point *)
PROCEDURE Snap(x: LONGREAL): REAL;
BEGIN
  IF ABS(x) < 2048 THEN RETURN SHORT(ENTIER(x * 8192 + 0.5D0) / 8192.0D0) END;
  RETURN SHORT(x)
END Snap;

(* x pixels in points *)
PROCEDURE P(x: LONGREAL): REAL;
BEGIN
  RETURN Snap(x * px)
END P;

(* Items *)

PROCEDURE Add(it: Item);
BEGIN
  it.next := NIL;
  IF last = NIL THEN l.items := it ELSE last.next := it END;
  last := it
END Add;

PROCEDURE NewItem(kind: INTEGER; fill, line: LONGINT; width: LONGREAL): Item;
  VAR it: Item;
BEGIN
  NEW(it); it.kind := kind; it.p := NIL; it.n := 0;
  it.fill := fill; it.line := line;
  IF line < 0 THEN it.width := 0 ELSE it.width := P(width) END;
  it.dash := 0; it.lab := NIL; it.size := 0; it.angle := 0;
  it.x := 0; it.y := 0; it.w := 0; it.h := 0; it.r := 0;
  Add(it);
  RETURN it
END NewItem;

PROCEDURE AddCircle(x, y, r: LONGREAL; fill, line: LONGINT; width: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(Circle, fill, line, width);
  it.x := P(x); it.y := P(y); it.r := P(r)
END AddCircle;

PROCEDURE AddRect(x, y, w, h, r: LONGREAL; fill, line: LONGINT; width: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(Rect, fill, line, width);
  it.x := P(x); it.y := P(y); it.w := P(w); it.h := P(h); it.r := P(r)
END AddRect;

PROCEDURE AddLine(x0, y0, x1, y1: LONGREAL; line: LONGINT; width, dash: LONGREAL);
  VAR it: Item;
BEGIN
  it := NewItem(Line, -1, line, width);
  it.p := G.NewPoints(2); it.n := 2;
  G.Set(it.p[0], P(x0), P(y0)); G.Set(it.p[1], P(x1), P(y1));
  it.dash := P(dash)
END AddLine;

PROCEDURE AddPoly(VAR x, y: ARRAY OF LONGREAL; n: INTEGER; fill, line: LONGINT;
  width: LONGREAL);
  VAR it: Item; k: INTEGER;
BEGIN
  it := NewItem(Poly, fill, line, width);
  it.p := G.NewPoints(n); it.n := n;
  FOR k := 0 TO n - 1 DO G.Set(it.p[k], P(x[k]), P(y[k])) END
END AddPoly;

(* lab's width and height, in pixels, at size pixels *)
PROCEDURE Measure(lab: F.Label; size: LONGREAL; VAR w, h: LONGREAL);
  VAR rw, rh: REAL;
BEGIN
  M.LabelSize(l.font, lab, SHORT(size * px), SHORT(size * px * 1.2D0), rw, rh);
  w := rw / px; h := rh / px
END Measure;

(* lab, size pixels, w by h, its middle (x, y), turned angle degrees *)
PROCEDURE AddText(lab: F.Label; x, y, size, angle: LONGREAL; colour: LONGINT);
  VAR it: Item;
BEGIN
  IF lab.n = 0 THEN RETURN END;
  it := NewItem(Text, -1, colour, 0);
  it.lab := lab; it.size := SHORT(size * px); it.angle := SHORT(angle);
  M.LabelSize(l.font, lab, it.size, it.size * 1.2, it.w, it.h);
  it.x := P(x); it.y := P(y)
END AddText;

(* (x, y) turned a degrees, clockwise, about (ox, oy) *)
PROCEDURE Turn(VAR x, y: LONGREAL; ox, oy, a: LONGREAL);
  VAR c, s, u, v: LONGREAL;
BEGIN
  c := MathL.cos(a * MathL.pi / 180); s := MathL.sin(a * MathL.pi / 180);
  u := x - ox; v := y - oy;
  x := ox + u * c - v * s; y := oy + u * s + v * c
END Turn;

(* Paths *)

PROCEDURE MoveTo(x, y: LONGREAL);
BEGIN
  qx[0] := x; qy[0] := y; nq := 1
END MoveTo;

PROCEDURE Put(x, y: LONGREAL);
BEGIN
  qx[nq] := x; qy[nq] := y; INC(nq)
END Put;

PROCEDURE LineTo(x, y: LONGREAL);
BEGIN
  Put(qx[nq - 1], qy[nq - 1]); Put(x, y); Put(x, y)
END LineTo;

(* The quarter circle to (x, y), clockwise if sweep, as SVG's arc with
   sweep-flag sweep *)
PROCEDURE ArcTo(sweep: BOOLEAN; x, y: LONGREAL);
  VAR ax, ay, ox, oy: LONGREAL;
BEGIN
  ax := qx[nq - 1]; ay := qy[nq - 1];
  (* the centre: (ax, y) turns clockwise when (y - ay) (x - ax) > 0 *)
  IF ((y - ay) * (x - ax) > 0) = sweep THEN ox := ax; oy := y ELSE ox := x; oy := ay END;
  Put(ax + Kappa * (x - ox), ay + Kappa * (y - oy));
  Put(x + Kappa * (ax - ox), y + Kappa * (ay - oy));
  Put(x, y)
END ArcTo;

PROCEDURE AddPath(colour: LONGINT);
  VAR it: Item; k: INTEGER;
BEGIN
  it := NewItem(Curve, -1, colour, 8);
  it.p := G.NewPoints(nq); it.n := nq;
  FOR k := 0 TO nq - 1 DO G.Set(it.p[k], P(qx[k]), P(qy[k])) END
END AddPath;

(* Places *)

(* c's place in d.bySeq *)
PROCEDURE Place(c: H.Commit): LONGINT;
  VAR k: LONGINT;
BEGIN
  k := 0;
  WHILE d.bySeq[k] # c DO INC(k) END;
  RETURN k
END Place;

PROCEDURE ParentPlace(c: H.Commit; j: INTEGER): LONGINT;
BEGIN
  RETURN Place(H.Find(d, c.parents[j]))
END ParentPlace;

PROCEDURE Colour(b: H.Branch): INTEGER;
BEGIN
  RETURN b.index MOD 8
END Colour;

PROCEDURE Branches;
  VAR k: INTEGER; pos, w, h: LONGREAL; b: H.Branch;
BEGIN
  NEW(bpos, d.nBranches + 1); pos := 0;
  FOR k := 0 TO d.nBranches - 1 DO
    b := d.sorted[k];
    Measure(F.PlainLabel(b.name), BranchSize, w, h);
    bpos[b.index] := pos;
    pos := pos + 50;
    IF d.rotateCommitLabel THEN pos := pos + 40 END;
    IF d.dir # H.LR THEN pos := pos + w / 2 END
  END
END Branches;

(* The y of the parent of c with the least y, Mermaid's closest for
   BT, the later of equals *)
PROCEDURE LeastParentY(c: H.Commit): LONGREAL;
  VAR j: INTEGER; y, v: LONGREAL;
BEGIN
  y := MAX(LONGREAL);
  FOR j := 0 TO c.nParents - 1 DO
    v := cy[ParentPlace(c, j)];
    IF v <= y THEN y := v END
  END;
  RETURN y
END LeastParentY;

(* setParallelBTPos *)
PROCEDURE ParallelBT;
  VAR k, n: LONGINT; c: H.Commit; cur, most: LONGREAL;
BEGIN
  n := d.nCommits; cur := DefaultPos; most := DefaultPos;
  FOR k := 0 TO n - 1 DO
    c := d.bySeq[k];
    IF c.nParents > 0 THEN cur := LeastParentY(c) + Step; most := Max(cur, most) END;
    cx[k] := bpos[c.branch.index]; cy[k] := cur + Offset
  END;
  FOR k := 0 TO n - 1 DO
    IF d.bySeq[k].nParents = 0 THEN cy[k] := most + DefaultPos END
  END;
  FOR k := 0 TO n - 1 DO
    c := d.bySeq[k];
    IF c.nParents > 0 THEN cur := LeastParentY(c) - Step; cy[k] := cur - Offset END
  END
END ParallelBT;

(* calculatePosition, for parallelCommits *)
PROCEDURE ParallelPos(k: LONGINT): LONGREAL;
  VAR c: H.Commit; j: INTEGER; best, v: LONGREAL; q: LONGINT;
BEGIN
  c := d.bySeq[k];
  IF d.dir = H.BT THEN RETURN cy[k] - Step END;
  IF c.nParents = 0 THEN
    IF d.dir = H.TB THEN RETURN DefaultPos END;
    RETURN 0
  END;
  best := -MAX(LONGREAL);
  FOR j := 0 TO c.nParents - 1 DO
    q := ParentPlace(c, j);
    IF d.dir = H.TB THEN v := cy[q] ELSE v := cx[q] END;
    IF v >= best THEN best := v END
  END;
  RETURN best + Step
END ParallelPos;

(* The places of the commits, in the order drawn *)
PROCEDURE Commits;
  VAR i, k, n: LONGINT; pos, pwo: LONGREAL; c: H.Commit; btp: BOOLEAN;
BEGIN
  n := d.nCommits;
  NEW(cx, n + 1); NEW(cy, n + 1); NEW(cpos, n + 1); NEW(cpwo, n + 1);
  btp := (d.dir = H.BT) & d.parallelCommits;
  IF btp THEN ParallelBT END;
  IF d.dir = H.LR THEN pos := 0 ELSE pos := DefaultPos END;
  maxPos := 0;
  FOR i := 0 TO n - 1 DO
    IF d.dir = H.BT THEN k := n - 1 - i ELSE k := i END;
    c := d.bySeq[k];
    IF d.parallelCommits THEN pos := ParallelPos(k) END;
    IF btp THEN pwo := pos ELSE pwo := pos + Offset END;
    IF d.dir = H.LR THEN cx[k] := pwo; cy[k] := bpos[c.branch.index] - 2
    ELSE cx[k] := bpos[c.branch.index]; cy[k] := pwo
    END;
    cpos[k] := pos; cpwo[k] := pwo;
    IF btp THEN pos := pos + Step ELSE pos := pos + Step + Offset END;
    maxPos := Max(maxPos, pos)
  END
END Commits;

(* Drawing *)

PROCEDURE Spine(b: H.Branch): LONGREAL;
BEGIN
  IF d.dir = H.LR THEN RETURN bpos[b.index] - 2 END;
  RETURN bpos[b.index]
END Spine;

PROCEDURE PushLane(y: LONGREAL);
  VAR b: Reals; k: LONGINT;
BEGIN
  IF nLanes = LEN(lanes^) THEN
    NEW(b, 2 * nLanes);
    FOR k := 0 TO nLanes - 1 DO b[k] := lanes[k] END;
    lanes := b
  END;
  lanes[nLanes] := y; INC(nLanes)
END PushLane;

PROCEDURE DrawBranches;
  VAR k: INTEGER; b: H.Branch; lab: F.Label; w, h, y, r, tp: LONGREAL; i: INTEGER;
    it: Item;
BEGIN
  IF d.rotateCommitLabel THEN r := 30 ELSE r := 0 END;
  FOR k := 0 TO d.nBranches - 1 DO
    b := d.sorted[k]; i := Colour(b); y := Spine(b);
    IF d.dir = H.LR THEN AddLine(0, y, maxPos, y, t.line, 1, 2)
    ELSIF d.dir = H.TB THEN AddLine(y, DefaultPos, y, maxPos, t.line, 1, 2)
    ELSE AddLine(y, maxPos, y, DefaultPos, t.line, 1, 2)
    END;
    PushLane(y);
    lab := F.PlainLabel(b.name);
    Measure(lab, BranchSize, w, h);
    IF d.dir = H.LR THEN
      AddRect(-w - 23 - r, y - h / 2 - 2, w + 18, h + 4, 4, t.git[i], -1, 0);
      AddText(lab, -w / 2 - 14 - r, y, BranchSize, 0, t.label[i])
    ELSE
      IF d.dir = H.TB THEN tp := 0 ELSE tp := maxPos END;
      AddRect(bpos[b.index] - w / 2 - 10, tp, w + 18, h + 4, 4, t.git[i], -1, 0);
      AddText(lab, bpos[b.index] - 5, tp + 16 - Mid * BranchSize, BranchSize, 0, t.label[i])
    END
  END
END DrawBranches;

PROCEDURE FindLane(y1, y2: LONGREAL; depth: INTEGER): LONGREAL;
  VAR cand: LONGREAL; k: LONGINT; ok: BOOLEAN;
BEGIN
  cand := y1 + ABS(y1 - y2) / 2;
  IF depth > 5 THEN RETURN cand END;
  ok := TRUE; k := 0;
  WHILE ok & (k < nLanes) DO ok := ABS(lanes[k] - cand) >= 10; INC(k) END;
  IF ok THEN PushLane(cand); RETURN cand END;
  RETURN FindLane(y1, y2 - ABS(y1 - y2) / 5, depth + 1)
END FindLane;

(* Whether the arrow from a to b goes round a commit between them *)
PROCEDURE Reroute(a, b: H.Commit; x1, y1, x2, y2: LONGREAL): BOOLEAN;
  VAR on: H.Branch; c: H.Commit; further: BOOLEAN;
BEGIN
  IF d.dir = H.LR THEN further := y1 < y2 ELSE further := x1 < x2 END;
  IF further THEN on := b.branch ELSE on := a.branch END;
  c := d.commits;
  WHILE c # NIL DO
    IF (c.seq > a.seq) & (c.seq < b.seq) & (c.branch = on) THEN RETURN TRUE END;
    c := c.next
  END;
  RETURN FALSE
END Reroute;

PROCEDURE Arrow(a, b: H.Commit);
  VAR ka, kb: LONGINT; x1, y1, x2, y2, lx, ly, r: LONGREAL; ci: INTEGER; merge: BOOLEAN;
BEGIN
  ka := Place(a); kb := Place(b);
  x1 := cx[ka]; y1 := cy[ka]; x2 := cx[kb]; y2 := cy[kb];
  ci := Colour(b.branch);
  merge := (b.type = H.Merge) & ~((b.parents[0] # NIL) & (a.id^ = b.parents[0]^));
  IF merge THEN ci := Colour(a.branch) END;
  MoveTo(x1, y1);
  IF Reroute(a, b, x1, y1, x2, y2) THEN
    r := 10;
    ly := FindLane(Min(y1, y2), Max(y1, y2), 0);
    lx := FindLane(Min(x1, x2), Max(x1, x2), 0);
    IF d.dir = H.TB THEN
      IF x1 < x2 THEN
        LineTo(lx - r, y1); ArcTo(TRUE, lx, y1 + r); LineTo(lx, y2 - r); ArcTo(FALSE, lx + r, y2)
      ELSE
        ci := Colour(a.branch);
        LineTo(lx + r, y1); ArcTo(FALSE, lx, y1 + r); LineTo(lx, y2 - r); ArcTo(TRUE, lx - r, y2)
      END
    ELSIF d.dir = H.BT THEN
      IF x1 < x2 THEN
        LineTo(lx - r, y1); ArcTo(FALSE, lx, y1 - r); LineTo(lx, y2 + r); ArcTo(TRUE, lx + r, y2)
      ELSE
        ci := Colour(a.branch);
        LineTo(lx + r, y1); ArcTo(TRUE, lx, y1 - r); LineTo(lx, y2 + r); ArcTo(FALSE, lx - r, y2)
      END
    ELSE
      IF y1 < y2 THEN
        LineTo(x1, ly - r); ArcTo(FALSE, x1 + r, ly); LineTo(x2 - r, ly); ArcTo(TRUE, x2, ly + r)
      ELSE
        ci := Colour(a.branch);
        LineTo(x1, ly + r); ArcTo(TRUE, x1 + r, ly); LineTo(x2 - r, ly); ArcTo(FALSE, x2, ly - r)
      END
    END
  ELSE
    r := 20;
    IF d.dir = H.TB THEN
      IF x1 < x2 THEN
        IF merge THEN LineTo(x1, y2 - r); ArcTo(FALSE, x1 + r, y2)
        ELSE LineTo(x2 - r, y1); ArcTo(TRUE, x2, y1 + r)
        END
      ELSIF x1 > x2 THEN
        IF merge THEN LineTo(x1, y2 - r); ArcTo(TRUE, x1 - r, y2)
        ELSE LineTo(x2 + r, y1); ArcTo(FALSE, x2, y1 + r)
        END
      END
    ELSIF d.dir = H.BT THEN
      IF x1 < x2 THEN
        IF merge THEN LineTo(x1, y2 + r); ArcTo(TRUE, x1 + r, y2)
        ELSE LineTo(x2 - r, y1); ArcTo(FALSE, x2, y1 - r)
        END
      ELSIF x1 > x2 THEN
        IF merge THEN LineTo(x1, y2 + r); ArcTo(FALSE, x1 - r, y2)
        ELSE LineTo(x2 + r, y1); ArcTo(TRUE, x2, y1 - r)
        END
      END
    ELSE
      IF y1 < y2 THEN
        IF merge THEN LineTo(x2 - r, y1); ArcTo(TRUE, x2, y1 + r)
        ELSE LineTo(x1, y2 - r); ArcTo(FALSE, x1 + r, y2)
        END
      ELSIF y1 > y2 THEN
        IF merge THEN LineTo(x2 - r, y1); ArcTo(FALSE, x2, y1 - r)
        ELSE LineTo(x1, y2 + r); ArcTo(TRUE, x1 + r, y2)
        END
      END
    END
  END;
  LineTo(x2, y2);
  AddPath(t.git[ci MOD 8])
END Arrow;

PROCEDURE DrawArrows;
  VAR b: H.Commit; j: INTEGER;
BEGIN
  b := d.commits;
  WHILE b # NIL DO
    FOR j := 0 TO b.nParents - 1 DO Arrow(H.Find(d, b.parents[j]), b) END;
    b := b.next
  END
END DrawArrows;

PROCEDURE Bullet(k: LONGINT);
  VAR c: H.Commit; x, y: LONGREAL; i, type: INTEGER;
BEGIN
  c := d.bySeq[k]; x := cx[k]; y := cy[k]; i := Colour(c.branch);
  IF c.customType >= 0 THEN type := c.customType ELSE type := c.type END;
  IF type = H.Highlight THEN
    AddRect(x - 10, y - 10, 20, 20, 0, t.inv[i], t.inv[i], 1);
    AddRect(x - 6, y - 6, 12, 12, 0, t.primary, t.primary, 1)
  ELSIF type = H.CherryPick THEN
    AddCircle(x, y, 10, Black, -1, 0);
    AddCircle(x - 3, y + 2, 2.75D0, White, -1, 0);
    AddCircle(x + 3, y + 2, 2.75D0, White, -1, 0);
    AddLine(x + 3, y + 1, x, y - 5, White, 1, 0);
    AddLine(x - 3, y + 1, x, y - 5, White, 1, 0)
  ELSE
    AddCircle(x, y, 10, t.git[i], t.git[i], 1);
    IF type = H.Merge THEN AddCircle(x, y, 6, t.primary, t.primary, 1)
    ELSIF type = H.Reverse THEN
      AddLine(x - 5, y - 5, x + 5, y + 5, t.primary, 3, 0);
      AddLine(x - 5, y + 5, x + 5, y - 5, t.primary, 3, 0)
    END
  END
END Bullet;

PROCEDURE CommitLabel(k: LONGINT);
  VAR c: H.Commit; lab: F.Label; x, y, w, h, bx, by, tx, ty, rx, ry, a: LONGREAL;
    px4, py4: ARRAY 4 OF LONGREAL; j: INTEGER;
BEGIN
  c := d.bySeq[k];
  IF (c.type = H.CherryPick) OR (c.type = H.Merge) & ~c.customId OR ~d.showCommitLabel THEN
    RETURN
  END;
  x := cx[k]; y := cy[k];
  lab := F.PlainLabel(c.id);
  Measure(lab, t.commitSize, w, h);
  IF d.dir = H.LR THEN
    bx := cpwo[k] - w / 2 - PY; by := y + 13.5D0;
    tx := cpwo[k]; ty := y + 25
  ELSE
    bx := x - (w + 4 * PX + 5); by := y - 12;
    tx := x - (w + 4 * PX) + w / 2; ty := y + h - 12
  END;
  ty := ty - Mid * t.commitSize;
  px4[0] := bx; py4[0] := by; px4[1] := bx + w + 2 * PY; py4[1] := by;
  px4[2] := px4[1]; py4[2] := by + h + 2 * PY; px4[3] := bx; py4[3] := py4[2];
  a := 0;
  IF d.rotateCommitLabel THEN
    a := -45;
    IF d.dir = H.LR THEN
      rx := -7.5D0 - ((w + 10) / 25) * 9.5D0; ry := 10 + (w / 25) * 8.5D0;
      FOR j := 0 TO 3 DO
        Turn(px4[j], py4[j], cpos[k], y, a); px4[j] := px4[j] + rx; py4[j] := py4[j] + ry
      END;
      Turn(tx, ty, cpos[k], y, a); tx := tx + rx; ty := ty + ry
    ELSE
      FOR j := 0 TO 3 DO Turn(px4[j], py4[j], x, y, a) END;
      Turn(tx, ty, x, y, a)
    END
  END;
  IF t.commitFill >= 0 THEN
    IF a = 0 THEN AddRect(bx, by, w + 2 * PY, h + 2 * PY, 0, t.commitFill, -1, 0)
    ELSE AddPoly(px4, py4, 4, t.commitFill, -1, 0)
    END
  END;
  AddText(lab, tx, ty, t.commitSize, a, t.commitText)
END CommitLabel;

PROCEDURE Tags(k: LONGINT);
  VAR c: H.Commit; tg: H.Tag; labs: POINTER TO ARRAY OF F.Label;
    ws: Reals; n, j, m: INTEGER; x, y, pos, pwo, w, h, maxW, maxH, h2, yo, ly, tx, ty: LONGREAL;
    qx6, qy6: ARRAY 6 OF LONGREAL; hx, hy: LONGREAL;
BEGIN
  c := d.bySeq[k];
  IF c.nTags = 0 THEN RETURN END;
  n := c.nTags; NEW(labs, n); NEW(ws, n);
  (* the tags reversed *)
  tg := c.tags; j := n;
  WHILE tg # NIL DO DEC(j); labs[j] := F.PlainLabel(tg.text); tg := tg.next END;
  maxW := 0; maxH := 0;
  FOR j := 0 TO n - 1 DO
    Measure(labs[j], t.tagSize, w, h); ws[j] := w;
    maxW := Max(maxW, w); maxH := Max(maxH, h)
  END;
  x := cx[k]; y := cy[k]; pos := cpos[k]; pwo := cpwo[k]; h2 := maxH / 2;
  FOR j := 0 TO n - 1 DO
    yo := 20 * j;
    IF d.dir = H.LR THEN
      ly := y - 19.2D0 - yo;
      qx6[0] := pos - maxW / 2 - PX / 2; qy6[0] := ly + PY;
      qx6[1] := qx6[0]; qy6[1] := ly - PY;
      qx6[2] := pwo - maxW / 2 - PX; qy6[2] := ly - h2 - PY;
      qx6[3] := pwo + maxW / 2 + PX; qy6[3] := qy6[2];
      qx6[4] := qx6[3]; qy6[4] := ly + h2 + PY;
      qx6[5] := qx6[2]; qy6[5] := qy6[4];
      hx := pos - maxW / 2 + PX / 2; hy := ly;
      tx := pwo; ty := y - 16 - yo - Mid * t.tagSize
    ELSE
      yo := pos + yo;
      qx6[0] := x; qy6[0] := yo + 2;
      qx6[1] := x; qy6[1] := yo - 2;
      qx6[2] := x + Offset; qy6[2] := yo - h2 - 2;
      qx6[3] := x + Offset + maxW + 4; qy6[3] := qy6[2];
      qx6[4] := qx6[3]; qy6[4] := yo + h2 + 2;
      qx6[5] := qx6[2]; qy6[5] := qy6[4];
      hx := x + PX / 2; hy := yo;
      FOR m := 0 TO 5 DO
        Turn(qx6[m], qy6[m], x, pos, 45); qx6[m] := qx6[m] + 12; qy6[m] := qy6[m] + 12
      END;
      Turn(hx, hy, x, pos, 45); hx := hx + 12; hy := hy + 12;
      tx := x + 5 + ws[j] / 2; ty := yo + 3 - Mid * t.tagSize;
      Turn(tx, ty, x, pos, 45); tx := tx + 14; ty := ty + 14
    END;
    AddPoly(qx6, qy6, 6, t.tagFill, t.tagLine, 1);
    AddCircle(hx, hy, 1.5D0, t.text, -1, 0);
    IF d.dir = H.LR THEN AddText(labs[j], tx, ty, t.tagSize, 0, t.tagText)
    ELSE AddText(labs[j], tx, ty, t.tagSize, 45, t.tagText)
    END
  END
END Tags;

PROCEDURE DrawCommits;
  VAR i, k, n: LONGINT;
BEGIN
  n := d.nCommits;
  FOR i := 0 TO n - 1 DO
    IF d.dir = H.BT THEN k := n - 1 - i ELSE k := i END;
    Bullet(k)
  END;
  FOR i := 0 TO n - 1 DO
    IF d.dir = H.BT THEN k := n - 1 - i ELSE k := i END;
    CommitLabel(k); Tags(k)
  END
END DrawCommits;

(* Bounds *)

PROCEDURE Bound(x0, y0, x1, y1: LONGREAL);
BEGIN
  IF x0 < minX THEN minX := x0 END;
  IF y0 < minY THEN minY := y0 END;
  IF x1 > maxX THEN maxX := x1 END;
  IF y1 > maxY THEN maxY := y1 END
END Bound;

PROCEDURE BoundItem(it: Item);
  VAR k: INTEGER; c, s, u, v: LONGREAL;
BEGIN
  IF it.kind = Circle THEN Bound(it.x - it.r, it.y - it.r, it.x + it.r, it.y + it.r)
  ELSIF it.kind = Rect THEN Bound(it.x, it.y, it.x + it.w, it.y + it.h)
  ELSIF it.kind = Text THEN
    c := MathL.cos(it.angle * MathL.pi / 180); s := MathL.sin(it.angle * MathL.pi / 180);
    FOR k := 0 TO 3 DO
      IF k MOD 2 = 0 THEN u := -it.w / 2 ELSE u := it.w / 2 END;
      IF k < 2 THEN v := -it.h / 2 ELSE v := it.h / 2 END;
      Bound(it.x + u * c - v * s, it.y + u * s + v * c, it.x + u * c - v * s, it.y + u * s + v * c)
    END
  ELSE
    FOR k := 0 TO it.n - 1 DO Bound(it.p[k].x, it.p[k].y, it.p[k].x, it.p[k].y) END
  END
END BoundItem;

PROCEDURE BoundAll;
  VAR it: Item;
BEGIN
  it := l.items;
  IF it # NIL THEN
    minX := MAX(REAL); minY := MAX(REAL); maxX := -MAX(REAL); maxY := -MAX(REAL)
  ELSE minX := 0; minY := 0; maxX := 0; maxY := 0
  END;
  WHILE it # NIL DO BoundItem(it); it := it.next END
END BoundAll;

PROCEDURE Move(it: Item; dx, dy: LONGREAL);
  VAR k: INTEGER;
BEGIN
  FOR k := 0 TO it.n - 1 DO G.Set(it.p[k], Snap(it.p[k].x + dx), Snap(it.p[k].y + dy)) END;
  it.x := Snap(it.x + dx); it.y := Snap(it.y + dy)
END Move;

(* Lays d out, its text set in font, the drawing at size points, into lay *)
PROCEDURE Make*(dg: H.Diagram; font: M.Font; size: REAL; VAR lay: Layout);
  VAR it: Item; pad, ddx, ddy: LONGREAL;
BEGIN
  d := dg;
  NEW(l); lay := l; l.d := d; l.font := font; l.size := size; l.vs := size * 1.2;
  px := size / MermaidSize; l.px := SHORT(px); l.items := NIL; last := NIL;
  S.Reset(d.g, l.px);
  S.GitColours(t);
  NEW(lanes, 8); nLanes := 0;
  Branches;
  Commits;
  IF d.showBranches THEN DrawBranches END;
  DrawArrows;
  DrawCommits;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    BoundAll;
    AddText(d.g.title, (minX + maxX) / 2 / px, -d.titleTopMargin - Mid * TitleSize, TitleSize, 0,
      t.text)
  END;
  BoundAll;
  pad := d.diagramPadding * px;
  ddx := pad - minX; ddy := pad - minY;
  l.width := Snap(maxX - minX + 2 * pad); l.height := Snap(maxY - minY + 2 * pad);
  it := l.items;
  WHILE it # NIL DO Move(it, ddx, ddy); it := it.next END;
  d := NIL; bpos := NIL; cx := NIL; cy := NIL; cpos := NIL; cpwo := NIL; lanes := NIL
END Make;

(* Make, at a smaller size, up to 5 times, while the drawing is wider
   than maxW points, if maxW > 0 *)
PROCEDURE Fit*(d: H.Diagram; font: M.Font; size, maxW: REAL; VAR lay: Layout);
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

END PmGitLayout.
