\startMPcode
numeric pmqL, pmqox, pmqw, pmqa, pmqbx; pair pmqc; path pmqs; picture pmqt;
vardef pmqwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;
vardef pmqarc(expr r, b, c) = save n; n := max(2, ceiling(abs(c - b) / 5));
  (r * sind(b), r * cosd(b)) for i = 1 upto n:
    .. (r * sind(b + (c - b) * i / n), r * cosd(b + (c - b) * i / n)) endfor
enddef;
def pmqtext(expr p, q, a, c) =
  draw p shifted (q - (if a = 0: xpart llcorner p else: xpart center p fi, ypart center p)) withcolor c;
enddef;
pmqL := 0;
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A" & "}") scaled 1));
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "B" & "}") scaled 1));
pmqox := 0;
pmqw := 224.824pt + 10.094pt + pmqL;
pmqbx := 202.341pt;
pmqc := (103.235pt + pmqox, -103.235pt);
draw fullcircle scaled 170.682pt shifted pmqc withcolor (0,0,0) withpen pencircle scaled 0.918pt;
pmqs := (pmqarc(84.882pt, 0, 180) -- (0, 0) -- cycle) shifted pmqc;
fill pmqs withcolor (0.949,0.949,1);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 0.918pt;
pmqs := (pmqarc(84.882pt, 180, 360) -- (0, 0) -- cycle) shifted pmqc;
fill pmqs withcolor (1,1,0.9098);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 0.918pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "50{\char37}" & "}") scaled 1, pmqc + (63.662pt, 2.34pt), 1, (0.2,0.2,0.2));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "50{\char37}" & "}") scaled 1, pmqc + (-63.662pt, 2.34pt), 1, (0.2,0.2,0.2));
pmqs := unitsquare scaled 8.259pt shifted (pmqbx, -101.4pt);
fill pmqs withcolor (0.9255,0.9255,1);
draw pmqs withcolor (0.9255,0.9255,1) withpen pencircle scaled 0.459pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A" & "}") scaled 1, (pmqbx, 0) + (10.094pt, -97.225pt), 0, (0,0,0));
pmqs := unitsquare scaled 8.259pt shifted (pmqbx, -111.494pt);
fill pmqs withcolor (1,1,0.8706);
draw pmqs withcolor (1,1,0.8706) withpen pencircle scaled 0.459pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "B" & "}") scaled 1, (pmqbx, 0) + (10.094pt, -107.319pt), 0, (0,0,0));
pmqa := 0;
pmqt := textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A title much wider than the pie and its legend together, so that it widens the drawing" & "}") scaled 1.4706;
pmqtext(pmqt, (xpart pmqc, -8.029pt), 1, (0,0,0));
pmqa := max(0, pmqwd(pmqt) / 2 - xpart pmqc);
pmqw := max(pmqw + pmqa, xpart pmqc + pmqa + pmqwd(pmqt) / 2);
currentpicture := currentpicture shifted (pmqa, 0);
setbounds currentpicture to (0, 0) -- (pmqw, 0) -- (pmqw, -206.471pt) -- (0, -206.471pt) -- cycle;
\stopMPcode
