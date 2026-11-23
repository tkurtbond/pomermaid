\startMPcode
numeric pmqx[]; picture pmqp;
pmqx0 := 0; pmqx1 := -312.5pt; pmqx2 := 312.5pt; pmqx3 := 0;
def pmqtext(expr p, q, a, c) =
  pmqp := p shifted (q - (if (a = 0): xpart llcorner p else: xpart center p fi, if (a = 2): ypart llcorner p else: ypart center p fi));
  draw pmqp withcolor c;
  pmqx0 := min(pmqx0, xpart llcorner pmqp); pmqx1 := min(pmqx1, ypart llcorner pmqp);
  pmqx2 := max(pmqx2, xpart urcorner pmqp); pmqx3 := max(pmqx3, ypart urcorner pmqp);
enddef;
fill unitsquare xscaled 153.125pt yscaled 153.125pt shifted (156.25pt, -156.25pt) withcolor (0.9255,0.9255,1);
fill unitsquare xscaled 153.125pt yscaled 153.125pt shifted (3.125pt, -156.25pt) withcolor (0.9451,0.9451,1);
fill unitsquare xscaled 153.125pt yscaled 153.125pt shifted (3.125pt, -309.375pt) withcolor (0.9647,0.9647,1);
fill unitsquare xscaled 153.125pt yscaled 153.125pt shifted (156.25pt, -309.375pt) withcolor (0.9843,0.9843,1);
draw (2.5pt, -3.125pt) -- (310pt, -3.125pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (309.375pt, -3.75pt) -- (309.375pt, -308.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (2.5pt, -309.375pt) -- (310pt, -309.375pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (3.125pt, -3.75pt) -- (3.125pt, -308.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (156.25pt, -3.75pt) -- (156.25pt, -308.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
draw (3.75pt, -156.25pt) -- (308.75pt, -156.25pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
setbounds currentpicture to (pmqx0, pmqx1) -- (pmqx2, pmqx1) -- (pmqx2, pmqx3) -- (pmqx0, pmqx3) -- cycle;
\stopMPcode
