\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -39.363pt; pmxx2 := 429.637pt; pmxx3 := 0;
def pmxtext(expr p, q, d, c) =
  pmxp := p shifted -center p rotated -d shifted q;
  draw pmxp withcolor c;
  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);
  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);
enddef;
vardef pmhbox(expr x, y, w, h, r) =
  if r > 0: (x + r, -y) -- (x + w - r, -y) {right} .. {down} (x + w, -y - r)
    -- (x + w, -y - h + r) {down} .. {left} (x + w - r, -y - h)
    -- (x + r, -y - h) {left} .. {up} (x, -y - h + r)
    -- (x, -y - r) {up} .. {right} cycle
  else: (x, -y) -- (x + w, -y) -- (x + w, -y - h) -- (x, -y - h) -- cycle fi
enddef;
begingroup interim linecap := butt;
fill pmhbox(0.419pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (1,1,0.9333);
draw pmhbox(0.419pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (0.6,0.2,0.2) withpen pencircle scaled 0.838pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Source Port" & "}") scaled 0.875, (106.572pt, -12.981pt), 0, (0,0.4,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "0" & "}") scaled 0.5, (1.256pt, -4.271pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "15" & "}") scaled 0.5, (211.05pt, -4.271pt), 0, (0,0,1));
fill pmhbox(214.819pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (1,1,0.9333);
draw pmhbox(214.819pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (0.6,0.2,0.2) withpen pencircle scaled 0.838pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Destination Port" & "}") scaled 0.875, (320.972pt, -12.981pt), 0, (0,0.4,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "16" & "}") scaled 0.5, (216.494pt, -4.271pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "31" & "}") scaled 0.5, (425.45pt, -4.271pt), 0, (0,0,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Coloured" & "}") scaled 1.125, (214.819pt, -29.522pt), 0, (0.502,0,0.502));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
