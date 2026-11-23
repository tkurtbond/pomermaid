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
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "All" & "}") scaled 1));
pmqL := max(pmqL, pmqwd(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Zero" & "}") scaled 1));
pmqox := 0;
pmqw := 288.235pt + 12.941pt + pmqL;
pmqbx := 259.412pt;
pmqc := (132.353pt + pmqox, -132.353pt);
pmqs := fullcircle scaled 217.647pt shifted pmqc;
fill pmqs withcolor (1,0,0);
draw pmqs withcolor (0,0,1) withpen pencircle scaled 1.176pt;
pmqs := fullcircle scaled 108.824pt shifted pmqc;
fill pmqs withcolor (1,1,1);
draw pmqs withcolor (0,0,1) withpen pencircle scaled 1.176pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "100{\char37}" & "}") scaled 1, pmqc + (0pt, -78.618pt), 1, (0.2,0.2,0.2));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -130pt);
fill pmqs withcolor (1,0,0);
draw pmqs withcolor (1,0,0) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "All" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -124.647pt), 0, (0,0,0));
pmqs := unitsquare scaled 10.588pt shifted (pmqbx, -142.941pt);
fill pmqs withcolor (1,1,0.8706);
draw pmqs withcolor (1,1,0.8706) withpen pencircle scaled 0.588pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Zero" & "}") scaled 1, (pmqbx, 0) + (12.941pt, -137.588pt), 0, (0,0,0));
pmqa := 0;
currentpicture := currentpicture shifted (pmqa, 0);
setbounds currentpicture to (0, 0) -- (pmqw, 0) -- (pmqw, -264.706pt) -- (0, -264.706pt) -- cycle;
\stopMPcode
