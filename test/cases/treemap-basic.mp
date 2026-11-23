\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -238.23pt; pmxx2 := 430.2pt; pmxx3 := 0;
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
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Budget" & "}") scaled 0.875, (215.1pt, -7.38pt), 0, (0.2,0.2,0.2));
fill pmhbox(3.6pt, 29.88pt, 322.2pt, 204.75pt, 0pt) withcolor (0.7137,0.7137,1);
draw pmhbox(3.6pt, 29.88pt, 322.2pt, 204.75pt, 0pt) withcolor (0.6902,0.6902,1) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Products}" & "}") scaled 0.75, 21.654pt), (17.127pt, -35.505pt), 0, (1,1,1));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it {\char36}162,500.5}" & "}") scaled 0.625, 19.8pt), (311.4pt, -35.505pt), 0, (1,1,1));
fill pmhbox(330.3pt, 29.88pt, 96.3pt, 192.15pt, 0pt) withcolor (1,1,0.6824);
draw pmhbox(330.3pt, 29.88pt, 96.3pt, 192.15pt, 0pt) withcolor (0.9882,0.9882,0.6) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Services}" & "}") scaled 0.75, 21.654pt), (343.827pt, -35.505pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it {\char36}47,000}" & "}") scaled 0.625, 13.95pt), (415.125pt, -35.505pt), 0, (0,0,0));
fill pmhbox(243pt, 45.63pt, 78.3pt, 184.5pt, 0pt) withcolor (0.7922,0.8863,0.7137);
draw pmhbox(243pt, 45.63pt, 78.3pt, 184.5pt, 0pt) withcolor (0.7137,0.8275,0.651) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Software}" & "}") scaled 0.75, 21.654pt), (256.527pt, -51.255pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it {\char36}42,500.5}" & "}") scaled 0.625, 17.55pt), (308.025pt, -51.255pt), 0, (0,0,0));
fill pmhbox(8.1pt, 45.63pt, 230.4pt, 184.5pt, 0pt) withcolor (0.6588,0.6588,1);
draw pmhbox(8.1pt, 45.63pt, 230.4pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Hardware" & "}") scaled 2.375, 68.571pt), (123.3pt, -137.88pt), 0, (1,1,1));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\char36}120,000" & "}") scaled 1.4375, 37.26pt), (123.3pt, -152.505pt), 0, (1,1,1));
fill pmhbox(247.5pt, 61.38pt, 69.3pt, 116.55pt, 0pt) withcolor (0.8078,0.9216,0.6588);
draw pmhbox(247.5pt, 61.38pt, 69.3pt, 116.55pt, 0pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Licences" & "}") scaled 2.25, 64.962pt), (282.15pt, -119.655pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\char36}30,500.5" & "}") scaled 1.375, 38.61pt), (282.15pt, -133.605pt), 0, (0,0,0));
fill pmhbox(247.5pt, 182.43pt, 69.3pt, 43.2pt, 0pt) withcolor (0.8549,0.8,0.6196);
draw pmhbox(247.5pt, 182.43pt, 69.3pt, 43.2pt, 0pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.8pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Support" & "}") scaled 2.375, 60.363pt), (282.15pt, -204.03pt), 0, (1,1,1));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\char36}12,000" & "}") scaled 1.4375, 32.085pt), (282.15pt, -218.655pt), 0, (1,1,1));
fill pmhbox(334.8pt, 45.63pt, 87.3pt, 145.8pt, 0pt) withcolor (1,1,0.6196);
draw pmhbox(334.8pt, 45.63pt, 87.3pt, 145.8pt, 0pt) withcolor (1,1,0.4706) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Consulting" & "}") scaled 2.3125, 82.751pt), (378.45pt, -118.53pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\char36}40,000" & "}") scaled 1.375, 30.69pt), (378.45pt, -132.705pt), 0, (0,0,0));
fill pmhbox(334.8pt, 195.93pt, 87.3pt, 21.6pt, 0pt) withcolor (1,1,0.6196);
draw pmhbox(334.8pt, 195.93pt, 87.3pt, 21.6pt, 0pt) withcolor (1,1,0.4706) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Training" & "}") scaled 1.5, 43.308pt), (378.45pt, -206.73pt), 0, (0,0,0));
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Other" & "}") scaled 0.5, 9.252pt), (378.45pt, -230.58pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
