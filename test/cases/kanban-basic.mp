\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -169.375pt; pmxx2 := 265.625pt; pmxx3 := 0;
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
fill pmhbox(6.25pt, 6.25pt, 125pt, 156.875pt, 3.125pt) withcolor (0.9098,1,0.7255);
draw pmhbox(6.25pt, 6.25pt, 125pt, 156.875pt, 3.125pt) withcolor (0.9098,1,0.7255) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Todo" & "}") scaled 1, (68.75pt, -12.25pt), 0, (0,0,0));
fill pmhbox(134.375pt, 6.25pt, 125pt, 46.375pt, 3.125pt) withcolor (0.8627,0.7255,1);
draw pmhbox(134.375pt, 6.25pt, 125pt, 46.375pt, 3.125pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "In progress" & "}") scaled 1, (196.875pt, -12.25pt), 0, (1,1,1));
fill pmhbox(10.938pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create JISON" & "}") scaled 1, (49.938pt, -34.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 49.5pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 49.5pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Update DB function" & "}") scaled 1, (60.637pt, -61.75pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 77.125pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 77.125pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create parsing tests" & "}") scaled 1, (63.738pt, -89.375pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 104.75pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 104.75pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "define getData" & "}") scaled 1, (50.488pt, -117pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 132.375pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 132.375pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create renderer" & "}") scaled 1, (52.887pt, -144.625pt), 0, (0.2,0.2,0.2));
fill pmhbox(139.063pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(139.063pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Design grammar" & "}") scaled 1, (178.613pt, -34.125pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
