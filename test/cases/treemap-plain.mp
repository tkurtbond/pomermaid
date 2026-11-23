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
fill pmhbox(3.6pt, 3.6pt, 297.45pt, 204.75pt, 0pt) withcolor (0.7137,0.7137,1);
draw pmhbox(3.6pt, 3.6pt, 297.45pt, 204.75pt, 0pt) withcolor (0.6902,0.6902,1) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Fruit}" & "}") scaled 0.75, 13.878pt), (13.239pt, -9.225pt), 0, (1,1,1));
fill pmhbox(302.85pt, 3.6pt, 123.75pt, 204.75pt, 0pt) withcolor (1,1,0.6824);
draw pmhbox(302.85pt, 3.6pt, 123.75pt, 204.75pt, 0pt) withcolor (0.9882,0.9882,0.6) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Vegetables}" & "}") scaled 0.75, 26.838pt), (318.969pt, -9.225pt), 0, (0,0,0));
fill pmhbox(8.1pt, 118.8pt, 216pt, 85.05pt, 0pt) withcolor (0.7922,0.8863,0.7137);
draw pmhbox(8.1pt, 118.8pt, 216pt, 85.05pt, 0pt) withcolor (0.7137,0.8275,0.651) withpen pencircle scaled 0.9pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Citrus}" & "}") scaled 0.75, 16.47pt), (19.035pt, -124.425pt), 0, (0,0,0));
fill pmhbox(8.1pt, 19.35pt, 216pt, 97.65pt, 0pt) withcolor (0.6588,0.6588,1);
draw pmhbox(8.1pt, 19.35pt, 216pt, 97.65pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Apples" & "}") scaled 2.375, 52.155pt), (116.1pt, -68.175pt), 0, (1,1,1));
fill pmhbox(12.6pt, 134.55pt, 117.45pt, 64.8pt, 0pt) withcolor (0.8078,0.9216,0.6588);
draw pmhbox(12.6pt, 134.55pt, 117.45pt, 64.8pt, 0pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Oranges" & "}") scaled 2.375, 60.363pt), (71.325pt, -166.95pt), 0, (0,0,0));
fill pmhbox(131.85pt, 134.55pt, 57.6pt, 64.8pt, 0pt) withcolor (0.8078,0.9216,0.6588);
draw pmhbox(131.85pt, 134.55pt, 57.6pt, 64.8pt, 0pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Lemons" & "}") scaled 2.375, 52.155pt), (160.65pt, -166.95pt), 0, (0,0,0));
fill pmhbox(191.25pt, 134.55pt, 28.35pt, 64.8pt, 0pt) withcolor (0.8078,0.9216,0.6588);
draw pmhbox(191.25pt, 134.55pt, 28.35pt, 64.8pt, 0pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Limes" & "}") scaled 1.3125, 24.287pt), (205.425pt, -166.95pt), 0, (0,0,0));
fill pmhbox(225.9pt, 19.35pt, 70.65pt, 184.5pt, 0pt) withcolor (0.6588,0.6588,1);
draw pmhbox(225.9pt, 19.35pt, 70.65pt, 184.5pt, 0pt) withcolor (0.5255,0.5255,1) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Pears" & "}") scaled 2.375, 43.947pt), (261.225pt, -111.6pt), 0, (0,0,0));
fill pmhbox(307.35pt, 19.35pt, 114.75pt, 131.4pt, 0pt) withcolor (1,1,0.6196);
draw pmhbox(307.35pt, 19.35pt, 114.75pt, 131.4pt, 0pt) withcolor (1,1,0.4706) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Carrots" & "}") scaled 2.375, 60.363pt), (364.725pt, -85.05pt), 0, (0,0,0));
fill pmhbox(307.35pt, 152.55pt, 114.75pt, 51.3pt, 0pt) withcolor (1,1,0.6196);
draw pmhbox(307.35pt, 152.55pt, 114.75pt, 51.3pt, 0pt) withcolor (1,1,0.4706) withpen pencircle scaled 1.35pt;
pmxtext(pmxfit(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Leeks" & "}") scaled 2.375, 43.947pt), (364.725pt, -178.2pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
