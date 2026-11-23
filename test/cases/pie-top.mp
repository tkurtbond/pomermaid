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
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Dogs" & "}") scaled 1));
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Cats" & "}") scaled 1));
pmqox := 0;
pmqw := 288.235pt;
pmqbx := 119.412pt - pmqL / 2;
pmqc := (132.353pt + pmqox, -171.176pt);
draw fullcircle scaled 218.824pt shifted pmqc withcolor (0,0,0) withpen pencircle scaled 1.176pt;
pmqs := (pmqarc(108.824pt, 0, 295.032) -- reverse pmqarc(43.529pt, 0, 295.032) -- cycle) shifted pmqc;
fill pmqs withcolor (0.949,0.949,1);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 1.176pt;
pmqs := (pmqarc(108.824pt, 295.032, 360) -- reverse pmqarc(43.529pt, 295.032, 360) -- cycle) shifted pmqc;
fill pmqs withcolor (1,1,0.9098);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 1.176pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "82{\char37}" & "}") scaled 1, pmqc + (43.834pt, -65.848pt), 1, (0.2,0.2,0.2));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "18{\char37}" & "}") scaled 1, pmqc + (-43.834pt, 71.848pt), 1, (0.2,0.2,0.2));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -34.118pt);
fill pmqs withcolor (0.9255,0.9255,1);
draw pmqs withcolor (0.9255,0.9255,1) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Dogs" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -28.765pt), 0, (0,0,0));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -47.059pt);
fill pmqs withcolor (1,1,0.8706);
draw pmqs withcolor (1,1,0.8706) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Cats" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -41.706pt), 0, (0,0,0));
pmqa := 0;
currentpicture := currentpicture shifted (pmqa, 0);
setbounds currentpicture to (0, 0) -- (pmqw, 0) -- (pmqw, -290.588pt) -- (0, -290.588pt) -- cycle;
\stopMPcode
