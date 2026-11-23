\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -85.25pt; pmxx2 := 203.125pt; pmxx3 := 0;
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
fill pmhbox(6.25pt, 6.25pt, 93.75pt, 72.75pt, 3.125pt) withcolor (1,0.2,0.2);
draw pmhbox(6.25pt, 6.25pt, 93.75pt, 72.75pt, 3.125pt) withcolor (1,0.2,0.2) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A section with a\\rather long title\\that wraps" & "}") scaled 1, (53.125pt, -24.25pt), 0, (0,1,0));
fill pmhbox(103.125pt, 6.25pt, 93.75pt, 66.75pt, 3.125pt) withcolor (0.8627,0.7255,1);
draw pmhbox(103.125pt, 6.25pt, 93.75pt, 66.75pt, 3.125pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B" & "}") scaled 1, (150pt, -12.25pt), 0, (1,1,1));
fill pmhbox(10.938pt, 42.25pt, 84.375pt, 30.5pt, 3.125pt) withcolor (1,1,0.9333);
draw pmhbox(10.938pt, 42.25pt, 84.375pt, 30.5pt, 3.125pt) withcolor (0,0,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "One" & "}") scaled 1, (25.238pt, -51.5pt), 0, (0.6,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "someone" & "}") scaled 1, (72.262pt, -63.5pt), 0, (0.6,0,0));
fill pmhbox(107.813pt, 42.25pt, 84.375pt, 24.5pt, 3.125pt) withcolor (1,1,0.9333);
draw pmhbox(107.813pt, 42.25pt, 84.375pt, 24.5pt, 3.125pt) withcolor (0,0,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Two" & "}") scaled 1, (122.113pt, -54.5pt), 0, (0.6,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
