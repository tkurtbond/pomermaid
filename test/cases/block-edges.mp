\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -82.25pt; pmxx2 := 90.65pt; pmxx3 := 0;
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
fill pmhbox(3.125pt, 3.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(3.125pt, 3.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "a" & "}") scaled 1, (15.525pt, -14.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(62.725pt, 3.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(62.725pt, 3.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "b" & "}") scaled 1, (75.125pt, -14.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(32.925pt, 30.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(32.925pt, 30.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "c" & "}") scaled 1, (45.325pt, -41.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(3.125pt, 57.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(3.125pt, 57.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "d" & "}") scaled 1, (15.525pt, -68.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(62.725pt, 57.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(62.725pt, 57.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "e" & "}") scaled 1, (75.125pt, -68.125pt), 0, (0.2,0.2,0.2));
fill (62.725pt, -14.125pt) -- (57.725pt, -16.625pt) -- (57.725pt, -11.625pt) -- cycle withcolor (0.2,0.2,0.2);
draw (27.925pt, -14.125pt) -- (60.225pt, -14.125pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
fill (33.184pt, -30.125pt) -- (27.8pt, -28.62pt) -- (31.157pt, -24.915pt) -- cycle withcolor (0.2,0.2,0.2);
draw (27.666pt, -25.125pt) -- (31.332pt, -28.446pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
fill pmhbox(18.425pt, 21.625pt, 24pt, 12pt, 0pt) withcolor (0.9098,0.9098,0.9098);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "label" & "}") scaled 1, (30.425pt, -27.625pt), 0, (0.2,0.2,0.2));
fill (57.466pt, -30.125pt) -- (59.492pt, -24.915pt) -- (62.85pt, -28.62pt) -- cycle withcolor (0.2,0.2,0.2);
draw (62.984pt, -25.125pt) -- (59.318pt, -28.446pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 2.188pt;
fill (27.666pt, -57.125pt) -- (29.693pt, -51.915pt) -- (33.05pt, -55.62pt) -- cycle withcolor (0.2,0.2,0.2);
draw (33.184pt, -52.125pt) -- (29.518pt, -55.446pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt dashed dashpattern(on 1.875pt off 1.875pt);
draw (56.881pt, -65.719pt) -- (61.694pt, -70.531pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
draw (56.881pt, -70.531pt) -- (61.694pt, -65.719pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
draw (27.925pt, -68.125pt) -- (59.287pt, -68.125pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
fill fullcircle scaled 6.875pt shifted (30.213pt, -27.433pt) withcolor (0.2,0.2,0.2);
draw (62.984pt, -57.125pt) -- (30.213pt, -27.433pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
draw (15.525pt, -25.125pt) -- (15.525pt, -57.125pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
fill (75.125pt, -57.125pt) -- (72.625pt, -52.125pt) -- (77.625pt, -52.125pt) -- cycle withcolor (0.2,0.2,0.2);
fill (75.125pt, -25.125pt) -- (77.625pt, -30.125pt) -- (72.625pt, -30.125pt) -- cycle withcolor (0.2,0.2,0.2);
draw (75.125pt, -27.625pt) -- (75.125pt, -54.625pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
