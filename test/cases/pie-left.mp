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
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Rats" & "}") scaled 1));
pmqox := 12.941pt + pmqL;
pmqw := 288.235pt + 12.941pt + pmqL;
pmqbx := 10.588pt;
pmqc := (132.353pt + pmqox, -132.353pt);
draw fullcircle scaled 218.824pt shifted pmqc withcolor (0,0,0) withpen pencircle scaled 1.176pt;
pmqs := (pmqarc(108.824pt, 0, 285.926) -- (0, 0) -- cycle) shifted pmqc;
fill pmqs withcolor (0.949,0.949,1);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 1.176pt;
pmqs := (pmqarc(108.824pt, 285.926, 348.889) -- (0, 0) -- cycle) shifted pmqc;
fill pmqs withcolor (1,1,0.9098);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 1.176pt;
pmqs := (pmqarc(108.824pt, 348.889, 360) -- (0, 0) -- cycle) shifted pmqc;
fill pmqs withcolor (0.7961,1,0.3882);
draw pmqs withcolor (0.302,0.302,0.302) withpen pencircle scaled 1.176pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "79{\char37}" & "}") scaled 1, pmqc + (49.161pt, -62.151pt), 1, (0.2,0.2,0.2));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "17{\char37}" & "}") scaled 1, pmqc + (-55.237pt, 63.086pt), 1, (0.2,0.2,0.2));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "3{\char37}" & "}") scaled 1, pmqc + (-7.901pt, 84.234pt), 1, (0.2,0.2,0.2));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -123.529pt);
fill pmqs withcolor (0.9255,0.9255,1);
draw pmqs withcolor (0.9255,0.9255,1) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Dogs" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -118.176pt), 0, (0,0,0));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -136.471pt);
fill pmqs withcolor (1,1,0.8706);
draw pmqs withcolor (1,1,0.8706) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Cats" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -131.118pt), 0, (0,0,0));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -149.412pt);
fill pmqs withcolor (0.7098,1,0.1255);
draw pmqs withcolor (0.7098,1,0.1255) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Rats" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -144.059pt), 0, (0,0,0));
pmqa := 0;
pmqt := textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Left" & "}") scaled 1.4706;
pmqtext(pmqt, (xpart pmqc, -10.294pt), 1, (0,0,0));
pmqa := max(0, pmqwd(pmqt) / 2 - xpart pmqc);
pmqw := max(pmqw + pmqa, xpart pmqc + pmqa + pmqwd(pmqt) / 2);
currentpicture := currentpicture shifted (pmqa, 0);
setbounds currentpicture to (0, 0) -- (pmqw, 0) -- (pmqw, -264.706pt) -- (0, -264.706pt) -- cycle;
\stopMPcode
