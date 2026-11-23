MODULE PmGitDump;
(* PmGitDump: a git graph's model, PmGit's, written as text, one line
   for the title, each configuration value, the diagram's options, each
   branch in its order and each commit in Mermaid's order, for the
   tests (-t dump); and its layout, PmGitLayout's (-t layout) *)

IMPORT PmIO, Y := PmYaml, H := PmGit, X := PmXy, D := PmDump, HL := PmGitLayout, P := PmPic;

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

PROCEDURE Type(name: ARRAY OF CHAR; t: INTEGER);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF t = H.Normal THEN PmIO.WriteString("normal")
  ELSIF t = H.Reverse THEN PmIO.WriteString("reverse")
  ELSIF t = H.Highlight THEN PmIO.WriteString("highlight")
  ELSIF t = H.Merge THEN PmIO.WriteString("merge")
  ELSE PmIO.WriteString("cherry-pick")
  END
END Type;

(* Writes d's model *)
PROCEDURE Write*(d: H.Diagram);
  VAR q: Y.Pair; b: H.Branch; c: H.Commit; t: H.Tag; k: INTEGER;
BEGIN
  IF d.g.title # NIL THEN PmIO.WriteString("title"); D.Label("text", d.g.title); PmIO.WriteLn END;
  q := d.g.config;
  WHILE q # NIL DO
    PmIO.WriteString("config "); PmIO.WriteString(q.name^); PmIO.WriteChar("=");
    D.Quoted(q.value); PmIO.WriteLn;
    q := q.next
  END;
  PmIO.WriteString("gitGraph dir=");
  IF d.dir = H.LR THEN PmIO.WriteString("LR")
  ELSIF d.dir = H.TB THEN PmIO.WriteString("TB")
  ELSE PmIO.WriteString("BT")
  END;
  Num("titleTopMargin", d.titleTopMargin); Num("diagramPadding", d.diagramPadding);
  Bool("showCommitLabel", d.showCommitLabel); Bool("showBranches", d.showBranches);
  Bool("rotateCommitLabel", d.rotateCommitLabel); Bool("parallelCommits", d.parallelCommits);
  PmIO.WriteString(" mainBranchName="); D.Quoted(d.mainBranchName);
  PmIO.WriteLn;
  FOR k := 0 TO d.nBranches - 1 DO
    b := d.sorted[k];
    PmIO.WriteString("branch "); PmIO.WriteInt(b.index); PmIO.WriteChar(" "); D.Quoted(b.name);
    Num("order", b.order); PmIO.WriteLn
  END;
  c := d.commits;
  WHILE c # NIL DO
    PmIO.WriteString("commit "); D.Quoted(c.id);
    Num("seq", c.seq); Type("type", c.type);
    IF c.customType >= 0 THEN Type("customType", c.customType) END;
    IF c.customId THEN PmIO.WriteString(" customId") END;
    PmIO.WriteString(" branch="); D.Quoted(c.branch.name);
    PmIO.WriteString(" msg="); D.Quoted(c.msg);
    FOR k := 0 TO c.nParents - 1 DO PmIO.WriteString(" parent="); D.Quoted(c.parents[k]) END;
    t := c.tags;
    WHILE t # NIL DO PmIO.WriteString(" tag="); D.Quoted(t.text); t := t.next END;
    PmIO.WriteLn;
    c := c.next
  END
END Write;

PROCEDURE Real(name: ARRAY OF CHAR; x: REAL);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("="); PmIO.WriteReal(x, 2)
END Real;

PROCEDURE Pt(name: ARRAY OF CHAR; x, y: REAL);
BEGIN
  PmIO.WriteChar(" ");
  IF name # "" THEN PmIO.WriteString(name); PmIO.WriteChar("=") END;
  PmIO.WriteChar("(");
  PmIO.WriteReal(x, 2); PmIO.WriteChar(","); PmIO.WriteReal(y, 2); PmIO.WriteChar(")")
END Pt;

PROCEDURE Colour(name: ARRAY OF CHAR; c: LONGINT);
BEGIN
  PmIO.WriteChar(" "); PmIO.WriteString(name); PmIO.WriteChar("=");
  IF c < 0 THEN PmIO.WriteString("none") ELSE PmIO.WriteChar("#"); P.Hex(c, 6) END
END Colour;

(* Writes the layout l (-t layout): its size and each item, in drawing
   order, in points, rounded to 2 decimals *)
PROCEDURE WriteLayout*(l: HL.Layout);
  VAR it: HL.Item; k: INTEGER;
BEGIN
  PmIO.WriteString("layout"); Real("width", l.width); Real("height", l.height); PmIO.WriteLn;
  it := l.items;
  WHILE it # NIL DO
    IF it.kind = HL.Circle THEN
      PmIO.WriteString("circle"); Pt("at", it.x, it.y); Real("r", it.r)
    ELSIF it.kind = HL.Rect THEN
      PmIO.WriteString("rect"); Pt("at", it.x, it.y); Real("w", it.w); Real("h", it.h);
      IF it.r # 0 THEN Real("r", it.r) END
    ELSIF it.kind = HL.Text THEN
      PmIO.WriteString("text"); Pt("at", it.x, it.y); Real("size", it.size); Real("w", it.w);
      IF it.angle # 0 THEN Real("angle", it.angle) END
    ELSE
      IF it.kind = HL.Poly THEN PmIO.WriteString("poly")
      ELSIF it.kind = HL.Line THEN PmIO.WriteString("line")
      ELSE PmIO.WriteString("curve")
      END;
      FOR k := 0 TO it.n - 1 DO Pt("", it.p[k].x, it.p[k].y) END;
      IF it.dash # 0 THEN Real("dash", it.dash) END
    END;
    IF it.kind # HL.Text THEN Colour("fill", it.fill) END;
    Colour("line", it.line);
    IF it.width # 0 THEN Real("width", it.width) END;
    IF it.kind = HL.Text THEN D.Label("text", it.lab) END;
    PmIO.WriteLn;
    it := it.next
  END
END WriteLayout;

END PmGitDump.
