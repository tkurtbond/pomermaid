\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -112pt; pmxx2 := 100pt; pmxx3 := 0;
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
fill pmhbox(25pt, 25pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(35.938pt, 35.938pt, 28.125pt, 28.125pt, 1.25pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (35.938pt, -45.313pt) -- (64.063pt, -45.313pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (35.938pt, -54.688pt) -- (64.063pt, -54.688pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
fill pmhbox(52.344pt, 40pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (45.313pt, -40.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (45.313pt, -40.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (42.188pt, -40.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (42.188pt, -40.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (39.063pt, -40.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (39.063pt, -40.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill pmhbox(52.344pt, 49.375pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (45.313pt, -50pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (45.313pt, -50pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (42.188pt, -50pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (42.188pt, -50pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (39.063pt, -50pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (39.063pt, -50pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill pmhbox(52.344pt, 58.75pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (45.313pt, -59.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (45.313pt, -59.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (42.188pt, -59.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (42.188pt, -59.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (39.063pt, -59.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (39.063pt, -59.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A" & "}") scaled 1, (50pt, -81pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
