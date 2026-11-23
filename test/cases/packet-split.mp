\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -104.688pt; pmxx2 := 430.802pt; pmxx3 := 0;
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
fill pmhbox(1.583pt, 6.281pt, 145.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(1.583pt, 6.281pt, 145.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "test" & "}") scaled 0.75, (74.236pt, -12.981pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "0" & "}") scaled 0.625, (2.63pt, -3.978pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "10" & "}") scaled 0.625, (144.795pt, -3.978pt), 0, (0,0,0));
fill pmhbox(148.983pt, 6.281pt, 279.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(148.983pt, 6.281pt, 279.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "multiple" & "}") scaled 0.75, (288.636pt, -12.981pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "11" & "}") scaled 0.625, (151.077pt, -3.978pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "31" & "}") scaled 0.625, (426.195pt, -3.978pt), 0, (0,0,0));
fill pmhbox(1.583pt, 25.963pt, 426.706pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(1.583pt, 25.963pt, 426.706pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "multiple" & "}") scaled 0.75, (214.936pt, -32.662pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "32" & "}") scaled 0.625, (3.677pt, -23.659pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "63" & "}") scaled 0.625, (426.195pt, -23.659pt), 0, (0,0,0));
fill pmhbox(1.583pt, 45.644pt, 359.706pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(1.583pt, 45.644pt, 359.706pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "multiple" & "}") scaled 0.75, (181.436pt, -52.344pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "64" & "}") scaled 0.625, (3.677pt, -43.341pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "90" & "}") scaled 0.625, (359.195pt, -43.341pt), 0, (0,0,0));
fill pmhbox(363.383pt, 45.644pt, 64.906pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(363.383pt, 45.644pt, 64.906pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "exact" & "}") scaled 0.75, (395.836pt, -52.344pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "91" & "}") scaled 0.625, (365.477pt, -43.341pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "95" & "}") scaled 0.625, (426.195pt, -43.341pt), 0, (0,0,0));
fill pmhbox(1.583pt, 65.325pt, 426.706pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(1.583pt, 65.325pt, 426.706pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "exact" & "}") scaled 0.75, (214.936pt, -72.025pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "96" & "}") scaled 0.625, (3.677pt, -63.022pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "127" & "}") scaled 0.625, (425.148pt, -63.022pt), 0, (0,0,0));
fill pmhbox(1.583pt, 85.006pt, 11.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(1.583pt, 85.006pt, 11.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "single" & "}") scaled 0.75, (7.236pt, -91.706pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "128" & "}") scaled 0.625, (7.236pt, -82.703pt), 0, (0,0,0));
fill pmhbox(14.983pt, 85.006pt, 11.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(14.983pt, 85.006pt, 11.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "after" & "}") scaled 0.75, (20.636pt, -91.706pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "129" & "}") scaled 0.625, (20.636pt, -82.703pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
