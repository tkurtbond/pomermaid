\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -274.25pt; pmxx2 := 277.25pt; pmxx3 := 0;
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
fill pmhbox(3.125pt, 3.125pt, 271pt, 86pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(3.125pt, 3.125pt, 271pt, 86pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Top" & "}") scaled 1, (138.625pt, -46.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(3.125pt, 94.125pt, 87pt, 86pt, 0pt) withcolor (1,1,0.9373);
draw pmhbox(3.125pt, 94.125pt, 87pt, 86pt, 0pt) withcolor (0.9333,0.9333,0.8392) withpen pencircle scaled 0.625pt;
fill pmhbox(8.125pt, 99.125pt, 77pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(8.125pt, 99.125pt, 77pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "l1" & "}") scaled 1, (46.625pt, -110.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(8.125pt, 126.125pt, 77pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(8.125pt, 126.125pt, 77pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "l2" & "}") scaled 1, (46.625pt, -137.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(8.125pt, 153.125pt, 77pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(8.125pt, 153.125pt, 77pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "l3" & "}") scaled 1, (46.625pt, -164.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(95.125pt, 121.125pt, 179pt, 32pt, 0pt) withcolor (1,1,0.9373);
draw pmhbox(95.125pt, 121.125pt, 179pt, 32pt, 0pt) withcolor (0.9333,0.9333,0.8392) withpen pencircle scaled 0.625pt;
fill pmhbox(100.125pt, 126.125pt, 82pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(100.125pt, 126.125pt, 82pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A wider label" & "}") scaled 1, (141.125pt, -137.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(187.125pt, 126.125pt, 82pt, 22pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(187.125pt, 126.125pt, 82pt, 22pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "m2" & "}") scaled 1, (228.125pt, -137.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(3.125pt, 185.125pt, 271pt, 86pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(3.125pt, 185.125pt, 271pt, 86pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "bottom" & "}") scaled 1, (138.625pt, -228.125pt), 0, (0.2,0.2,0.2));
fill (90.098pt, -94.125pt) -- (91.894pt, -88.831pt) -- (95.41pt, -92.386pt) -- cycle withcolor (0.2,0.2,0.2);
draw (95.152pt, -89.125pt) -- (91.875pt, -92.367pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
fill (95.125pt, -137.125pt) -- (90.125pt, -139.625pt) -- (90.125pt, -134.625pt) -- cycle withcolor (0.2,0.2,0.2);
draw (90.125pt, -137.125pt) -- (92.625pt, -137.125pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.25pt;
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
