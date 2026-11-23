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
fill pmhbox(3.6pt, 3.6pt, 423pt, 204.75pt, 0pt) withcolor (0.7137,0.7137,1);
draw pmhbox(3.6pt, 3.6pt, 423pt, 204.75pt, 0pt) withcolor (0.6902,0.6902,1) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Shares}" & "}") scaled 0.75, 16.47pt), (14.535pt, -9.225pt), 0, (1,1,1));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it 100.0{\char37}}" & "}") scaled 0.625, 11.7pt), (416.25pt, -9.225pt), 0, (1,1,1));
fill pmhbox(8.1pt, 19.35pt, 205.65pt, 184.5pt, 0pt) withcolor (0.6588,0.6588,1);
draw pmhbox(8.1pt, 19.35pt, 205.65pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Large" & "}") scaled 2.375, 43.947pt), (110.925pt, -111.6pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "50.0{\char37}" & "}") scaled 1.4375, 21.735pt), (110.925pt, -126.225pt), 0, (0,0,0));
fill pmhbox(216.45pt, 19.35pt, 153.45pt, 184.5pt, 0pt) withcolor (0.6588,0.6588,1);
draw pmhbox(216.45pt, 19.35pt, 153.45pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Medium" & "}") scaled 2.375, 52.155pt), (293.175pt, -111.6pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "37.5{\char37}" & "}") scaled 1.4375, 21.735pt), (293.175pt, -126.225pt), 0, (0,0,0));
fill pmhbox(372.6pt, 19.35pt, 49.5pt, 184.5pt, 0pt) withcolor (0.6588,0.6588,1);
draw pmhbox(372.6pt, 19.35pt, 49.5pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Small" & "}") scaled 2.375, 43.947pt), (397.35pt, -111.6pt), 0, (1,1,1));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "12.5{\char37}" & "}") scaled 1.4375, 21.735pt), (397.35pt, -126.225pt), 0, (1,1,1));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
