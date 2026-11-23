\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -211.95pt; pmxx2 := 430.2pt; pmxx3 := 0;
def pmxtext(expr p, q, d, c) =
  pmxp := p shifted -center p rotated -d shifted q;
  draw pmxp withcolor c;
  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);
  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);
enddef;
vardef pmxfit(expr p, w) =
  if xpart urcorner p - xpart llcorner p > w:
    p scaled (w / (xpart urcorner p - xpart llcorner p)) else: p fi
enddef;
vardef pmhbox(expr x, y, w, h, r) =
  if r > 0: (x + r, -y) -- (x + w - r, -y) {right} .. {down} (x + w, -y - r)
    -- (x + w, -y - h + r) {down} .. {left} (x + w - r, -y - h)
    -- (x + r, -y - h) {left} .. {up} (x, -y - h + r)
    -- (x, -y - r) {up} .. {right} cycle
  else: (x, -y) -- (x + w, -y) -- (x + w, -y - h) -- (x, -y - h) -- cycle fi
enddef;
begingroup interim linecap := butt;
fill pmhbox(3.6pt, 3.6pt, 423pt, 204.75pt, 0pt) withcolor (0.9216,0.9608,1);
draw pmhbox(3.6pt, 3.6pt, 423pt, 204.75pt, 0pt) withcolor (0.6,0.6784,0.7608) withpen pencircle scaled 0.45pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Section A}" & "}") scaled 0.75, 23.922pt), (18.261pt, -9.225pt), 0, (1,1,1));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it 13}" & "}") scaled 0.625, 4.5pt), (419.85pt, -9.225pt), 0, (1,1,1));
fill pmhbox(8.1pt, 19.35pt, 317.25pt, 184.5pt, 0pt) withcolor (0.9451,0.9137,0.702);
draw pmhbox(8.1pt, 19.35pt, 317.25pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "One" & "}") scaled 2.375, 27.531pt), (166.725pt, -111.6pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "10" & "}") scaled 1.4375, 10.35pt), (166.725pt, -126.225pt), 0, (0,0,0));
fill pmhbox(329.85pt, 19.35pt, 92.25pt, 184.5pt, 0pt) withcolor (0.8039,0.8314,1);
draw pmhbox(329.85pt, 19.35pt, 92.25pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Two" & "}") scaled 2.375, 27.531pt), (375.975pt, -111.6pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "3" & "}") scaled 1.4375, 5.175pt), (375.975pt, -126.225pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
