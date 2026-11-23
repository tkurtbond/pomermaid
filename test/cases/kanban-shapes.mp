\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -197pt; pmxx2 := 290.563pt; pmxx3 := 0;
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
fill pmhbox(6.25pt, 6.25pt, 125pt, 184.5pt, 3.125pt) withcolor (0.9098,1,0.7255);
draw pmhbox(6.25pt, 6.25pt, 125pt, 184.5pt, 3.125pt) withcolor (0.9098,1,0.7255) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Rounded" & "}") scaled 1, (68.75pt, -12.25pt), 0, (0,0,0));
fill pmhbox(134.375pt, 6.25pt, 125pt, 86pt, 3.125pt) withcolor (0.8627,0.7255,1);
draw pmhbox(134.375pt, 6.25pt, 125pt, 86pt, 3.125pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Second" & "}") scaled 1, (196.875pt, -12.25pt), 0, (1,1,1));
fill pmhbox(10.938pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Circle" & "}") scaled 1, (32.438pt, -34.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 49.5pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 49.5pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Cloud" & "}") scaled 1, (30.037pt, -61.75pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 77.125pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 77.125pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Bang" & "}") scaled 1, (27.637pt, -89.375pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 104.75pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 104.75pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Hexagon" & "}") scaled 1, (34.838pt, -117pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 132.375pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 132.375pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Quoted [text]" & "}") scaled 1, (46.287pt, -144.625pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 160pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 160pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A {\it markdown} string" & "}") scaled 1, (56.537pt, -172.25pt), 0, (0.2,0.2,0.2));
fill pmhbox(139.063pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(139.063pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "plain text card" & "}") scaled 1, (179.012pt, -34.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(139.063pt, 49.5pt, 115.625pt, 36.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(139.063pt, 49.5pt, 115.625pt, 36.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "style n2\\stroke:{\char35}AA00FF,fill:{\char35}E1BEE7" & "}") scaled 1, (214.813pt, -67.75pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
