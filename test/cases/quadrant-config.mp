\startMPcode
numeric pmqx[]; picture pmqp;
pmqx0 := 0; pmqx1 := -225pt; pmqx2 := 250pt; pmqx3 := 0;
def pmqtext(expr p, q, a, c) =
  pmqp := p shifted (q - (if (a = 0): xpart llcorner p else: xpart center p fi, if (a = 2): ypart llcorner p else: ypart center p fi));
  draw pmqp withcolor c;
  pmqx0 := min(pmqx0, xpart llcorner pmqp); pmqx1 := min(pmqx1, ypart llcorner pmqp);
  pmqx2 := max(pmqx2, xpart urcorner pmqp); pmqx3 := max(pmqx3, ypart urcorner pmqp);
enddef;
fill unitsquare xscaled 113.75pt yscaled 87.5pt shifted (116.875pt, -118.125pt) withcolor (0.8784,0.9412,0.8784);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Plan" & "}") scaled 1, (173.75pt, -38.75pt), 1, (1,0,0));
fill unitsquare xscaled 113.75pt yscaled 87.5pt shifted (3.125pt, -118.125pt) withcolor (0.9451,0.9451,1);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Do" & "}") scaled 1, (60pt, -38.75pt), 1, (0.0549,0.0549,0));
fill unitsquare xscaled 113.75pt yscaled 87.5pt shifted (3.125pt, -205.625pt) withcolor (0.9647,0.9647,1);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Drop" & "}") scaled 1, (60pt, -126.25pt), 1, (0.0353,0.0353,0));
fill unitsquare xscaled 113.75pt yscaled 87.5pt shifted (116.875pt, -205.625pt) withcolor (0.9843,0.9843,1);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Delegate" & "}") scaled 1, (173.75pt, -126.25pt), 1, (0.0157,0.0157,0));
draw (2.5pt, -30.625pt) -- (231.25pt, -30.625pt) withcolor (0.251,0.251,0.251) withpen pencircle scaled 1.25pt;
draw (230.625pt, -31.25pt) -- (230.625pt, -205pt) withcolor (0.251,0.251,0.251) withpen pencircle scaled 1.25pt;
draw (2.5pt, -205.625pt) -- (231.25pt, -205.625pt) withcolor (0.251,0.251,0.251) withpen pencircle scaled 1.25pt;
draw (3.125pt, -31.25pt) -- (3.125pt, -205pt) withcolor (0.251,0.251,0.251) withpen pencircle scaled 1.25pt;
draw (116.875pt, -31.25pt) -- (116.875pt, -205pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
draw (3.75pt, -118.125pt) -- (230pt, -118.125pt) withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 10pt shifted (162.375pt, -153.125pt) withcolor (0.1882,0.3765,0.7529);
draw fullcircle scaled 10pt shifted (162.375pt, -153.125pt) withcolor (0.1882,0.3765,0.7529) withpen pencircle scaled 1.25pt;
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Docs" & "}") scaled 0.75, (162.375pt, -160pt), 1, (0.0745,0.0745,0));
fill fullcircle scaled 10pt shifted (48.625pt, -65.625pt) withcolor (0.1882,0.3765,0.7529);
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Tests" & "}") scaled 0.75, (48.625pt, -72.5pt), 1, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Low effort" & "}") scaled 1, (60pt, -216.875pt), 1, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "High effort" & "}") scaled 1, (173.75pt, -216.875pt), 1, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Low value" & "}") scaled 1 rotated 90, (241.875pt, -161.875pt), 3, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "High value" & "}") scaled 1 rotated 90, (241.875pt, -74.375pt), 3, (0.0745,0.0745,0));
pmqtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Effort and value" & "}") scaled 1.5, (125pt, -13.75pt), 1, (0.1255,0.1255,0.502));
setbounds currentpicture to (pmqx0, pmqx1) -- (pmqx2, pmqx1) -- (pmqx2, pmqx3) -- (pmqx0, pmqx3) -- cycle;
\stopMPcode
