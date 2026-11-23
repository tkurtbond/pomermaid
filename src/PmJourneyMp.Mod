MODULE PmJourneyMp;
(* PmJourneyMp: a user journey written in MetaPost, for ConTeXt: a
   \startMPcode block that lays the journey out and draws it as
   PmJourneyLayout and PmJourneyPic do, with ConTeXt's text.

   The code is written for this journey, not as calls of macros: what
   depends on the text, the legend's width, the title's height and the
   boxes' heights, is measured in MetaPost, from textext's pictures;
   the rest is written as numbers, in Mermaid's pixels (pmjpx). A
   task's or a section's text is set by \framed to its box's width, less
   10 pixels; an actor's name is, if it is wider than 360 pixels. Text
   is written as PmMp writes it. *)

IMPORT PmIO, F := PmFlow, S := PmStyle, J := PmJourney, JL := PmJourneyLayout, PmMp;

VAR
  t: S.JourneyTheme;
  px: REAL;

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
  W("("); R(x); W("*pmjpx)")
END Px;

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

(* textext of lab set by \framed, align align, width w pixels, or its
   own width for w = 0 *)
PROCEDURE Framed(lab: F.Label; w: REAL; align: ARRAY OF CHAR);
BEGIN
  W('textext("\framed[frame=off,offset=0pt,');
  IF w > 0 THEN W("width="); Dim(w); W(",") END;
  W("align="); W(align); W(']{" & '); PmMp.Label(lab); W(' & "}")')
END Framed;

(* A circle about (x, y), x and y MetaPost expressions, radius r
   pixels, filled with fill and drawn with line, width pixels wide *)
PROCEDURE Circle(x, y: ARRAY OF CHAR; r: REAL; fill, line: LONGINT; width: REAL);
BEGIN
  IF fill >= 0 THEN
    W("fill fullcircle scaled "); Px(2 * r); W(" shifted pmjp("); W(x); W(", "); W(y);
    W(") withcolor "); Col(fill); W(";"); Ln
  END;
  IF line >= 0 THEN
    W("draw fullcircle scaled "); Px(2 * r); W(" shifted pmjp("); W(x); W(", "); W(y);
    W(") withcolor "); Col(line); W(" withpen pencircle scaled "); Px(width); W(";"); Ln
  END
END Circle;

(* The fill of the boxes of a task or section in s *)
PROCEDURE Fill(s: J.Section): LONGINT;
BEGIN
  IF s = NIL THEN RETURN t.fill[0] ELSE RETURN t.fill[s.index MOD 7] END
END Fill;

(* Writes d's user journey as a \startMPcode block, its labels at size
   points; wider than maxW points (0 for no limit), it is scaled down
   to maxW *)
PROCEDURE Write*(d: J.Diagram; size, maxW: REAL);
  VAR
    k, i: INTEGER; s: J.Section; tk: J.Task; minFace, y, w: REAL;
BEGIN
  px := size / JL.MermaidSize;
  S.Reset(d.g, px); S.JourneyColours(t);
  W("\startMPcode"); Ln;
  W("numeric pmjpx, pmjtop, pmjleft, pmjright, pmjbottom, pmjwidth, pmjx, pmjy, pmjfy,"); Ln;
  W("  pmjsech, pmjtaskh, pmjtasky, pmjextra;"); Ln;
  W("picture pmjname[], pmjtitle, pmjsec[], pmjtask[];"); Ln;
  W("pmjpx := "); R(px); W("pt;"); Ln;
  W("vardef pmjp(expr a, b) = (a, -b) enddef;"); Ln;
  W("vardef pmjwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;"); Ln;
  W("vardef pmjht(expr p) = (ypart urcorner p - ypart llcorner p) enddef;"); Ln;
  W("vardef pmjbox(expr xa, ya, w, h, r) ="); Ln;
  W("  pmjp(xa + r, ya) -- pmjp(xa + w - r, ya) {right} .. {down} pmjp(xa + w, ya + r)"); Ln;
  W("  -- pmjp(xa + w, ya + h - r) {down} .. {left} pmjp(xa + w - r, ya + h)"); Ln;
  W("  -- pmjp(xa + r, ya + h) {left} .. {up} pmjp(xa, ya + h - r)"); Ln;
  W("  -- pmjp(xa, ya + r) {up} .. {right} cycle"); Ln;
  W("enddef;"); Ln;
  (* a box at (xa, ya), w by h, filled with f and drawn with c, p
     centred in it in colour tc *)
  W("def pmjboxed(expr xa, ya, w, h, p, f, c, tc) ="); Ln;
  W("  fill pmjbox(xa, ya, w, h, "); Px(3); W(") withcolor f;"); Ln;
  W("  draw pmjbox(xa, ya, w, h, "); Px(3); W(") withcolor c withpen pencircle scaled pmjpx;"); Ln;
  W("  draw p shifted (pmjp(xa + w / 2, ya + h / 2) - center p) withcolor tc;"); Ln;
  W("enddef;"); Ln;
  (* the title, and the top *)
  W("pmjtop := "); Px(JL.Margin); W(";"); Ln;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    W('pmjtitle := textext("{\bf " & '); PmMp.Label(d.g.title); W(' & "}") scaled ');
    R(JL.TitleScale); W(";"); Ln;
    W("pmjtop := pmjtop + pmjht(pmjtitle) + "); Px(JL.TitleGap); W(";"); Ln
  END;
  minFace := 0; tk := d.tasks;
  WHILE tk # NIL DO
    y := JL.FaceTop + (5 - tk.score) * JL.FaceStep - JL.FaceR - JL.Margin;
    IF y < minFace THEN minFace := y END;
    tk := tk.next
  END;
  IF minFace < 0 THEN W("pmjtop := max(pmjtop, "); Px(JL.Margin - minFace); W(");"); Ln END;
  (* the legend *)
  W("pmjright := 0; pmjy := pmjtop + "); Px(JL.LegendTop); W(";"); Ln;
  FOR k := 0 TO d.nActors - 1 DO
    W("pmjname["); I(k); W("] := "); Framed(F.PlainLabel(d.actors[k]), 0, "flushleft"); W(";"); Ln;
    W("if pmjwd(pmjname["); I(k); W("]) > "); Px(JL.LegendW); W(": pmjname["); I(k);
    W("] := "); Framed(F.PlainLabel(d.actors[k]), JL.LegendW, "flushleft"); W("; fi"); Ln;
    Circle("20pmjpx", "pmjy", JL.LegendR, t.actor[k MOD 6], 0, 1);
    W("draw pmjname["); I(k); W("] shifted (pmjp("); Px(JL.LegendTextX); W(", pmjy - "); Px(6);
    W(") - ulcorner pmjname["); I(k); W("]) withcolor "); Col(t.text); W(";"); Ln;
    W("pmjright := max(pmjright, pmjwd(pmjname["); I(k); W("]));"); Ln;
    W("pmjy := pmjy + max("); Px(JL.LegendStep); W(", pmjht(pmjname["); I(k); W("]) + ");
    Px(8); W(");"); Ln
  END;
  W("pmjbottom := max(pmjy, pmjtop + "); Px(JL.LineEnd); W(");"); Ln;
  IF d.nActors > 0 THEN
    W("pmjleft := "); Px(JL.LegendTextX + JL.LeftGap); W(" + pmjright;"); Ln
  ELSE W("pmjleft := "); Px(JL.NoActorsLeft); W(";"); Ln
  END;
  (* the sections' and the tasks' text, and their boxes' heights *)
  W("pmjsech := "); Px(JL.TaskH); W("; pmjtaskh := "); Px(JL.TaskH); W(";"); Ln;
  s := d.sections;
  WHILE s # NIL DO
    w := JL.TaskW * s.count + (JL.TaskStep - JL.TaskW) * (s.count - 1);
    W("pmjsec["); I(s.index); W("] := "); Framed(s.text, w - 2 * JL.TextPad, "middle"); W(";"); Ln;
    W("pmjsech := max(pmjsech, pmjht(pmjsec["); I(s.index); W("]) + "); Px(2 * JL.TextPad);
    W(");"); Ln;
    s := s.next
  END;
  tk := d.tasks;
  WHILE tk # NIL DO
    W("pmjtask["); I(tk.index); W("] := "); Framed(tk.text, JL.TaskW - 2 * JL.TextPad, "middle");
    W(";"); Ln;
    W("pmjtaskh := max(pmjtaskh, pmjht(pmjtask["); I(tk.index); W("]) + "); Px(2 * JL.TextPad);
    W(");"); Ln;
    tk := tk.next
  END;
  W("pmjtasky := pmjtop + pmjsech + "); Px(JL.TaskTop - JL.TaskH); W(";"); Ln;
  W("pmjextra := pmjsech + pmjtaskh - "); Px(2 * JL.TaskH); W(";"); Ln;
  W("pmjbottom := max(pmjbottom, pmjtop + pmjextra + "); Px(JL.LineEnd); W(");"); Ln;
  s := d.sections;
  WHILE s # NIL DO
    w := JL.TaskW * s.count + (JL.TaskStep - JL.TaskW) * (s.count - 1);
    W("pmjboxed(pmjleft + "); Px(s.first * JL.TaskStep); W(", pmjtop, "); Px(w);
    W(", pmjsech, pmjsec["); I(s.index); W("], "); Col(Fill(s)); W(", ");
    Col(t.boxLine); W(", "); Col(t.boxText); W(");"); Ln;
    s := s.next
  END;
  (* the tasks *)
  tk := d.tasks;
  WHILE tk # NIL DO
    k := tk.index;
    W("pmjx := pmjleft + "); Px(k * JL.TaskStep); W(";"); Ln;
    W("draw pmjp(pmjx + "); Px(JL.TaskW / 2); W(", pmjtasky");
    W(") -- pmjp(pmjx + "); Px(JL.TaskW / 2); W(", pmjtop + pmjextra + "); Px(JL.LineEnd);
    W(") dashed dashpattern(on "); Px(4); W(" off "); Px(4); W(") withcolor "); Col(t.line);
    W(" withpen pencircle scaled pmjpx;"); Ln;
    W("pmjx := pmjx + "); Px(JL.TaskW / 2); W("; pmjfy := pmjtop + pmjextra + ");
    Px(JL.FaceTop + (5 - tk.score) * JL.FaceStep); W(";"); Ln;
    Circle("pmjx", "pmjfy", JL.FaceR, t.face, t.faceLine, 2);
    Circle("pmjx - 5pmjpx", "pmjfy - 5pmjpx", 2.5, t.mouth, -1, 0);
    Circle("pmjx + 5pmjpx", "pmjfy - 5pmjpx", 2.5, t.mouth, -1, 0);
    IF tk.score > 3 THEN
      W("draw halfcircle rotated 180 scaled "); Px(14); W(" shifted pmjp(pmjx, pmjfy + "); Px(2)
    ELSIF tk.score < 3 THEN
      W("draw halfcircle scaled "); Px(14); W(" shifted pmjp(pmjx, pmjfy + "); Px(7)
    ELSE
      W("draw pmjp(pmjx - "); Px(5); W(", pmjfy + "); Px(7); W(") -- pmjp(pmjx + "); Px(5);
      W(", pmjfy + "); Px(7)
    END;
    W(") withcolor "); Col(t.mouth); W(" withpen pencircle scaled "); Px(1.5); W(";"); Ln;
    W("pmjx := pmjx - "); Px(JL.TaskW / 2); W(";"); Ln;
    W("pmjboxed(pmjx, pmjtasky, "); Px(JL.TaskW); W(", pmjtaskh, pmjtask["); I(k);
    W("], "); Col(Fill(tk.section));
    W(", "); Col(t.boxLine); W(", "); Col(t.boxText); W(");"); Ln;
    FOR i := 0 TO tk.nPeople - 1 DO
      W("pmjy := pmjx + "); Px(14 + 10 * i); W(";"); Ln;
      Circle("pmjy", "pmjtasky", JL.LegendR, t.actor[tk.people[i] MOD 6], 0, 1)
    END;
    W("pmjbottom := max(pmjbottom, pmjfy + "); Px(JL.FaceR); W(", pmjtasky + pmjtaskh);"); Ln;
    tk := tk.next
  END;
  (* the activity line *)
  w := d.nTasks * JL.TaskStep; IF w < JL.MinArrow THEN w := JL.MinArrow END;
  W("pmjx := pmjleft + "); Px(w); W("; pmjy := pmjtop + pmjextra + "); Px(JL.ActivityY); W(";"); Ln;
  W("draw pmjp(pmjleft, pmjy) -- pmjp(pmjx - "); Px(6 * JL.ActivityW); W(", pmjy) withcolor ");
  Col(t.line); W(" withpen pencircle scaled "); Px(JL.ActivityW); W(";"); Ln;
  W("fill pmjp(pmjx - "); Px(6 * JL.ActivityW); W(", pmjy - "); Px(2 * JL.ActivityW);
  W(") -- pmjp(pmjx, pmjy) -- pmjp(pmjx - "); Px(6 * JL.ActivityW); W(", pmjy + ");
  Px(2 * JL.ActivityW); W(") -- cycle withcolor "); Col(t.line); W(";"); Ln;
  W("pmjwidth := pmjx;"); Ln;
  IF d.nTasks > 0 THEN
    W("pmjwidth := max(pmjwidth, pmjleft + "); Px((d.nTasks - 1) * JL.TaskStep + JL.TaskW);
    W(");"); Ln
  END;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    W("draw pmjtitle shifted (pmjp(pmjleft, "); Px(JL.Margin); W(") - ulcorner pmjtitle) withcolor ");
    Col(t.title); W(";"); Ln;
    W("pmjwidth := max(pmjwidth, pmjleft + pmjwd(pmjtitle));"); Ln
  END;
  W("pmjwidth := pmjwidth + "); Px(JL.Margin); W("; pmjbottom := pmjbottom + "); Px(JL.Margin);
  W(";"); Ln;
  W("setbounds currentpicture to pmjp(0, 0) -- pmjp(pmjwidth, 0) -- pmjp(pmjwidth, pmjbottom)");
  W(" -- pmjp(0, pmjbottom) -- cycle;"); Ln;
  IF maxW > 0 THEN
    W("if pmjwidth > "); R(maxW); W("pt: currentpicture := currentpicture scaled (");
    R(maxW); W("pt / pmjwidth); fi"); Ln
  END;
  W("\stopMPcode"); Ln
END Write;

END PmJourneyMp.
