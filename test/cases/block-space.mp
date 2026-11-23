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
fill pmhbox(62.725pt, 30.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(62.725pt, 30.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "c" & "}") scaled 1, (75.125pt, -41.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(3.125pt, 57.125pt, 24.8pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(3.125pt, 57.125pt, 24.8pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "d" & "}") scaled 1, (15.525pt, -68.125pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
