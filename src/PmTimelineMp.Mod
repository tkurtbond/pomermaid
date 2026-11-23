MODULE PmTimelineMp;
(* PmTimelineMp: a timeline written in MetaPost, for ConTeXt: a
   \startMPcode block that lays the timeline out and draws it as
   PmTimelineLayout and PmTimelinePic do, with ConTeXt's text.

   The code is written for this timeline, not as calls of macros. The
   nodes' left edges and widths do not depend on their text, and are
   taken from PmTimelineLayout's layout; what does, the nodes' heights,
   their tops and the dashed lines' and the axis's ends, is measured
   and worked out in MetaPost, from textext's pictures, in Mermaid's
   pixels (pmtpx). A node's text is set by \framed to the width
   PmTimelineLayout wraps it to. Text is written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, S := PmStyle, T := PmTimeline, TL := PmTimelineLayout,
  TP := PmTimelinePic, PmMp;

VAR
  t: S.TimelineTheme;
  px: REAL;
  l: TL.Layout;
  d: T.Diagram;
  k: INTEGER;        (* the next node *)
  nl: INTEGER;       (* the next dashed line *)

PROCEDURE W(s: ARRAY OF CHAR);
BEGIN
  PmIO.WriteString(s)
END W;

PROCEDURE Ln;
BEGIN
  PmIO.WriteLn
END Ln;

PROCEDURE I(n: LONGINT);
BEGIN
  PmIO.WriteInt(n)
END I;

PROCEDURE R(x: REAL);
BEGIN
  PmIO.WriteReal(x, 3)
END R;

(* x pixels, as a MetaPost expression *)
PROCEDURE Px(x: REAL);
BEGIN
  W("("); R(x); W("*pmtpx)")
END Px;

(* x points, as a MetaPost expression *)
PROCEDURE Pt(x: REAL);
BEGIN
  W("("); R(x); W("pt)")
END Pt;

(* x pixels, as a TeX dimension *)
PROCEDURE Dim(x: REAL);
BEGIN
  PmIO.WriteReal(x * px, 2); W("pt")
END Dim;

(* The colour rgb, 0RRGGBBH, as a MetaPost colour *)
PROCEDURE Col(rgb: LONGINT);
BEGIN
  IF rgb < 0 THEN rgb := 0 END;
  W("("); PmIO.WriteReal(rgb DIV 10000H / 255, 4); W(",");
  PmIO.WriteReal(rgb DIV 100H MOD 100H / 255, 4); W(",");
  PmIO.WriteReal(rgb MOD 100H / 255, 4); W(")")
END Col;

(* Node k's text, lab, set to w pixels, and its height, at least min
   pixels *)
PROCEDURE Text(lab: F.Label; w, extra, min: REAL);
BEGIN
  W('pmtt['); I(k); W('] := textext("\framed[frame=off,offset=0pt,width='); Dim(w);
  W(',align=middle]{" & '); PmMp.Label(lab); W(' & "}");'); Ln;
  W("pmth["); I(k); W("] := max(pmtht(pmtt["); I(k); W("]) + "); Px(extra); W(", "); Px(min);
  W(");"); Ln
END Text;

(* The texts and heights of the nodes; pmtsech, pmttaskh and pmtstack,
   the sections', the periods' and the highest stack of events' *)
PROCEDURE Texts(pw, ew, pad: REAL);
  VAR s: T.Section; p: T.Period; i, j, m, first: INTEGER; extra, min, w: REAL;

  PROCEDURE Period(p: T.Period);
    VAR i: INTEGER;
  BEGIN
    Text(p.text, pw, extra, 0);
    W("pmttaskh := max(pmttaskh, pmth["); I(k); W("]);"); Ln;
    INC(k);
    W("pmtsum := 0;"); Ln;
    FOR i := 0 TO p.nEvents - 1 DO
      Text(p.events[i], ew, extra, min);
      W("pmtsum := pmtsum + pmth["); I(k); W("]");
      IF i > 0 THEN
        W(" + ");
        IF d.td THEN Px(TL.TdEventSpace) ELSE Px(TL.LrEventGap) END
      END;
      W(";"); Ln;
      INC(k)
    END;
    W("pmtstack := max(pmtstack, pmtsum);"); Ln
  END Period;

BEGIN
  extra := TL.TextExtra + pad;
  IF d.td THEN min := 0 ELSE min := TL.LrMinEvent END;
  W("pmtsech := 0; pmttaskh := 0; pmtstack := 0;"); Ln;
  k := 0;
  IF d.sections # NIL THEN
    s := d.sections;
    WHILE s # NIL DO
      first := k;
      IF d.td THEN w := TL.TdSectionW
      ELSE m := s.count; IF m < 1 THEN m := 1 END;
        w := TL.LrStep * m - TL.LrStep + TL.LrNodeW
      END;
      Text(s.text, w, extra, 0);
      W("pmtsech := max(pmtsech, pmth["); I(k); W("]);"); Ln;
      INC(k);
      FOR j := 0 TO s.count - 1 DO Period(s.periods[j]) END;
      s := s.next
    END
  ELSE
    p := d.periods;
    WHILE p # NIL DO Period(p); p := p.next END
  END;
  IF ~d.td THEN
    IF d.sections # NIL THEN W("pmtsech := pmtsech + "); Px(TL.LrGrow); W(";"); Ln END;
    IF k > d.nSections THEN W("pmttaskh := pmttaskh + "); Px(TL.LrGrow); W(";"); Ln END
  END;
  (* the sections and periods are as high as the highest *)
  FOR i := 0 TO l.n - 1 DO
    IF l.kind[i] = TL.SectionNode THEN W("pmth["); I(i); W("] := pmtsech;"); Ln
    ELSIF l.kind[i] = TL.PeriodNode THEN W("pmth["); I(i); W("] := pmttaskh;"); Ln
    END
  END
END Texts;

(* The nodes' tops, the dashed lines' ends and the axis's or activity
   line's, left to right *)
PROCEDURE PlaceLr;
  VAR i: INTEGER;
BEGIN
  W("pmtpy := pmttop");
  IF d.sections # NIL THEN W(" + pmtsech + "); Px(TL.LrGap) END;
  W(";"); Ln;
  W("pmtbottom := pmttop;"); Ln;
  k := 0; nl := 0;
  WHILE k < l.n DO
    IF l.kind[k] = TL.SectionNode THEN
      W("pmty["); I(k); W("] := pmttop;"); Ln; INC(k)
    ELSE (* a period, then its events *)
      W("pmty["); I(k); W("] := pmtpy;"); Ln;
      W("pmtla["); I(nl); W("] := pmtpy + pmttaskh; pmtlb["); I(nl);
      W("] := pmtpy + pmttaskh + "); Px(TL.LrEventTop); W(" + pmtstack;"); Ln;
      W("pmtbottom := max(pmtbottom, pmtlb["); I(nl); W("]);"); Ln;
      INC(nl); INC(k);
      W("pmtey := pmtpy + "); Px(TL.LrEventTop); W(";"); Ln;
      WHILE (k < l.n) & (l.kind[k] = TL.EventNode) DO
        W("pmty["); I(k); W("] := pmtey; pmtey := pmtey + pmth["); I(k); W("] + ");
        Px(TL.LrEventGap); W(";"); Ln;
        INC(k)
      END
    END
  END;
  W("pmtay := pmtpy + pmttaskh + "); Px(TL.LrGap); W(";"); Ln;
  W("pmtaya := pmtay; pmtayb := pmtay;"); Ln;
  W("pmtbottom := max(pmtbottom, pmtay + "); Px(2 * TL.AxisW); W(");"); Ln;
  i := 0
END PlaceLr;

(* The same, top down *)
PROCEDURE PlaceTd;
  VAR inSection: BOOLEAN;
BEGIN
  W("pmtspacing := max(pmttaskh, pmtstack) + "); Px(TL.TdPeriodGap); W(";"); Ln;
  W("pmtpy := pmttop + "); Px(TL.TdAxisTop); W(";"); Ln;
  W("pmtbottom := pmttop;"); Ln;
  k := 0; nl := 0; inSection := FALSE;
  WHILE k < l.n DO
    IF l.kind[k] = TL.SectionNode THEN
      IF inSection THEN
        W("pmtpy := pmtpy - "); Px(TL.TdPeriodGap - TL.TdSectionGap); W(";"); Ln
      END;
      W("pmty["); I(k); W("] := pmtpy; pmtpy := pmtpy + pmtsech + "); Px(TL.TdSectionGap);
      W(";"); Ln;
      W("pmtbottom := max(pmtbottom, pmtpy - "); Px(TL.TdSectionGap); W(");"); Ln;
      INC(k); inSection := FALSE
    ELSE
      W("pmty["); I(k); W("] := pmtpy;"); Ln;
      W("pmtbottom := max(pmtbottom, pmtpy + pmttaskh);"); Ln;
      INC(k); inSection := TRUE;
      W("pmtey := pmtpy;"); Ln;
      WHILE (k < l.n) & (l.kind[k] = TL.EventNode) DO
        W("pmty["); I(k); W("] := pmtey; pmtla["); I(nl); W("] := pmtey + pmth["); I(k);
        W("] / 2; pmtlb["); I(nl); W("] := pmtla["); I(nl); W("];"); Ln;
        W("pmtey := pmtey + pmth["); I(k); W("]; pmtbottom := max(pmtbottom, pmtey);");
        W(" pmtey := pmtey + "); Px(TL.TdEventSpace); W(";"); Ln;
        INC(k); INC(nl)
      END;
      W("pmtpy := pmtpy + pmtspacing;"); Ln
    END
  END;
  W("pmtaya := pmttop; pmtayb := max(pmtbottom, pmttop + "); Px(TL.TdAxisTop); W(") + ");
  Px(TL.TdAxisBottom); W(";"); Ln;
  W("pmtbottom := pmtayb;"); Ln
END PlaceTd;

(* An arrow from (xa, ya) to (xb, yb), in points, the ys MetaPost
   expressions *)
PROCEDURE Arrow(xa: REAL; ya: ARRAY OF CHAR; xb: REAL; yb: ARRAY OF CHAR;
  len, wide, width: REAL; dashed: BOOLEAN);
BEGIN
  W("pmtarrow(pmtp("); Pt(xa); W(", "); W(ya); W("), pmtp("); Pt(xb); W(", "); W(yb);
  W("), "); Px(len); W(", "); Px(wide); W(", "); Px(width); W(", ");
  IF dashed THEN W("true") ELSE W("false") END; W(");"); Ln
END Arrow;

PROCEDURE Ref(VAR s: ARRAY OF CHAR; name: ARRAY OF CHAR; n: INTEGER);
  VAR i, j: INTEGER; digits: ARRAY 8 OF CHAR;
BEGIN
  COPY(name, s); i := 0; WHILE s[i] # 0X DO INC(i) END;
  s[i] := "["; INC(i);
  j := 0;
  REPEAT digits[j] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(j) UNTIL n = 0;
  WHILE j > 0 DO DEC(j); s[i] := digits[j]; INC(i) END;
  s[i] := "]"; s[i + 1] := 0X
END Ref;

(* Writes the timeline laid out in lay as a \startMPcode block, its
   labels at lay's size; wider than maxW points (0 for no limit), it is
   scaled down to maxW *)
PROCEDURE Write*(lay: TL.Layout; maxW: REAL);
  VAR i, c: INTEGER; pad, right: REAL; f, lb, iv: LONGINT; a, b: ARRAY 24 OF CHAR;
BEGIN
  l := lay; d := l.d; px := l.px;
  S.Reset(d.g, px); S.TimelineColours(t);
  W("\startMPcode"); Ln;
  W("numeric pmtpx, pmttop, pmtsech, pmttaskh, pmtstack, pmtsum, pmtpy, pmtey, pmtay,"); Ln;
  W("  pmtaya, pmtayb, pmtspacing, pmtbottom, pmtwidth, pmth[], pmty[], pmtla[], pmtlb[];"); Ln;
  W("picture pmtt[], pmttitle; pair pmtu;"); Ln;
  W("pmtpx := "); R(px); W("pt;"); Ln;
  W("vardef pmtp(expr a, b) = (a, -b) enddef;"); Ln;
  W("vardef pmtwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;"); Ln;
  W("vardef pmtht(expr p) = (ypart urcorner p - ypart llcorner p) enddef;"); Ln;
  (* an arrow from a to its tip at b, its head len long and wide wide,
     its line w wide, dashed or not, in black *)
  W("def pmtarrow(expr a, b, len, wide, w, dsh) ="); Ln;
  W("  pmtu := unitvector(b - a);"); Ln;
  W("  draw a -- (b - len * pmtu) if dsh: dashed dashpattern(on "); Px(TL.Dash);
  W(" off "); Px(TL.Dash); W(") fi"); Ln;
  W("    withcolor "); Col(t.line); W(" withpen pencircle scaled w;"); Ln;
  W("  fill (b - len * pmtu + (wide / 2) * (pmtu rotated 90)) -- b"); Ln;
  W("    -- (b - len * pmtu - (wide / 2) * (pmtu rotated 90)) -- cycle withcolor ");
  Col(t.line); W(";"); Ln;
  W("enddef;"); Ln;
  (* a node at (xa, ya), w by h, filled with f, its bottom line in c, p
     centred in it in colour tc *)
  W("def pmtnode(expr xa, ya, w, h, p, f, c, tc) ="); Ln;
  W("  fill pmtp(xa, ya + h) -- pmtp(xa, ya + "); Px(TL.Radius); W(") {up} .. {right} pmtp(xa + ");
  Px(TL.Radius); W(", ya)"); Ln;
  W("    -- pmtp(xa + w - "); Px(TL.Radius); W(", ya) {right} .. {down} pmtp(xa + w, ya + ");
  Px(TL.Radius); W(")"); Ln;
  W("    -- pmtp(xa + w, ya + h) -- cycle withcolor f;"); Ln;
  W("  draw pmtp(xa, ya + h) -- pmtp(xa + w, ya + h) withcolor c withpen pencircle scaled ");
  Px(TL.BottomW); W(";"); Ln;
  W("  draw p shifted (pmtp(xa + w / 2, ya + h / 2) - center p) withcolor tc;"); Ln;
  W("enddef;"); Ln;
  (* the title, and the top *)
  W("pmttop := "); Px(TL.Margin); W(";"); Ln;
  IF l.title # NIL THEN
    W('pmttitle := textext("{\bf " & '); PmMp.Label(d.g.title); W(' & "}") scaled ');
    R(TL.TitleScale); W(";"); Ln;
    W("pmttop := pmttop + pmtht(pmttitle) + "); Px(TL.TitleGap); W(";"); Ln
  END;
  (* the nodes' text and heights, and their places *)
  IF d.td THEN pad := TL.TdPad; Texts(TL.TdPeriodW, TL.TdEventW, pad)
  ELSE pad := TL.LrPad; Texts(TL.LrNodeW, TL.LrNodeW, pad)
  END;
  IF d.td THEN PlaceTd ELSE PlaceLr END;
  (* the drawing *)
  IF d.td THEN Arrow(l.ax1, "pmtaya", l.ax2, "pmtayb", 24, 16, TL.AxisW, FALSE) END;
  FOR i := 0 TO l.nLines - 1 DO
    Ref(a, "pmtla", i); Ref(b, "pmtlb", i);
    Arrow(l.x1[i], a, l.x2[i], b, 12, 8, TL.DashW, TRUE)
  END;
  FOR i := 0 TO l.n - 1 DO
    c := l.colour[i] MOD 12;
    f := t.scale[c]; lb := t.label[c]; iv := t.inv[c];
    IF l.kind[i] = TL.EventNode THEN
      f := TP.Brighter(f); lb := TP.Brighter(lb); iv := TP.Brighter(iv)
    END;
    W("pmtnode("); Pt(l.x[i]); W(", pmty["); I(i); W("], "); Pt(l.w[i]); W(", pmth["); I(i);
    W("], pmtt["); I(i); W("], "); Col(f); W(", "); Col(iv); W(", "); Col(lb); W(");"); Ln
  END;
  IF ~d.td THEN Arrow(l.ax1, "pmtaya", l.ax2, "pmtayb", 24, 16, TL.AxisW, FALSE) END;
  right := l.width - TL.Margin * px;
  IF l.title # NIL THEN
    right := l.ax2;
    FOR i := 0 TO l.n - 1 DO
      IF l.x[i] + l.w[i] > right THEN right := l.x[i] + l.w[i] END
    END;
    W("draw pmttitle shifted (pmtp("); Pt(l.titleX); W(", "); Px(TL.Margin);
    W(") - ulcorner pmttitle) withcolor "); Col(t.title); W(";"); Ln;
    W("pmtwidth := max("); Pt(right); W(", "); Pt(l.titleX); W(" + pmtwd(pmttitle));"); Ln
  ELSE W("pmtwidth := "); Pt(right); W(";"); Ln
  END;
  W("pmtwidth := pmtwidth + "); Px(TL.Margin); W("; pmtbottom := pmtbottom + "); Px(TL.Margin);
  W(";"); Ln;
  W("setbounds currentpicture to pmtp(0, 0) -- pmtp(pmtwidth, 0) -- pmtp(pmtwidth, pmtbottom)");
  W(" -- pmtp(0, pmtbottom) -- cycle;"); Ln;
  IF maxW > 0 THEN
    W("if pmtwidth > "); R(maxW); W("pt: currentpicture := currentpicture scaled (");
    R(maxW); W("pt / pmtwidth); fi"); Ln
  END;
  W("\stopMPcode"); Ln
END Write;

END PmTimelineMp.
