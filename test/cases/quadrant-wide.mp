\startMPcode
numeric pmqx[]; picture pmqp;
pmqx0 := 0; pmqx1 := -320.75pt; pmqx2 := 398.138pt; pmqx3 := 0;
def pmqtext(expr p, q, a, c) =
  pmqp := p shifted (q - (if (a = 0): xpart llcorner p else: xpart center p fi, if (a = 2): ypart llcorner p else: ypart center p fi));
  draw pmqp withcolor c;
  pmqx0 := min(pmqx0, xpart llcorner pmqp); pmqx1 := min(pmqx1, ypart llcorner pmqp);
  pmqx2 := max(pmqx2, xpart urcorner pmqp); pmqx3 := max(pmqx3, ypart urcorner pmqp);
enddef;
fill unitsquare xscaled 145pt yscaled 140.625pt shifted (202.813pt, -168.75pt) withcolor (0.9255,0.9255,1);
fill unitsquare xscaled 145pt yscaled 140.625pt shifted (57.813pt, -168.75pt) withcolor (0.9451,0.9451,1);
fill unitsquare xscaled 145pt yscaled 140.625pt shifted (57.813pt, -309.375pt) withcolor (0.9647,0.9647,1);
fill unitsquare xscaled 145pt yscaled 140.625pt shifted (202.813pt, -309.375pt) withcolor (0.9843,0.9843,1);
draw (57.188pt, -28.125pt) -- (348.438pt, -28.125pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (347.813pt, -28.75pt) -- (347.813pt, -308.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (57.188pt, -309.375pt) -- (348.438pt, -309.375pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (57.813pt, -28.75pt) -- (57.813pt, -308.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 1.25pt;
draw (202.813pt, -28.75pt) -- (202.813pt, -308.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
draw (58.438pt, -168.75pt) -- (347.188pt, -168.75pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 6.25pt shifted (347.813pt, -28.125pt) withcolor (0.2,0.2,0.2);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Another long text at the right" & "}") scaled 0.75, (347.813pt, -35pt), 1, (0.0745,0.0745,0));
fill fullcircle scaled 6.25pt shifted (57.813pt, -309.375pt) withcolor (0.2,0.2,0.2);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Edge point with a long text" & "}") scaled 0.75, (57.813pt, -316.25pt), 1, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Bottom only" & "}") scaled 1 rotated 90, (46.563pt, -309.375pt), 2, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A very long title, much wider than the chart itself, that goes on and on" & "}") scaled 1.25, (194.688pt, -12.5pt), 1, (0.0745,0.0745,0));
setbounds currentpicture to (pmqx0, pmqx1) -- (pmqx2, pmqx1) -- (pmqx2, pmqx3) -- (pmqx0, pmqx3) -- cycle;
\stopMPcode
