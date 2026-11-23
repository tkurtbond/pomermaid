\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -243.65pt; pmxx2 := 335.1pt; pmxx3 := 0;
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
fill pmhbox(19.825pt, 3.125pt, 70.4pt, 55.6pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(19.825pt, 3.125pt, 70.4pt, 55.6pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "square" & "}") scaled 1, (55.025pt, -30.925pt), 0, (0.2,0.2,0.2));
fill pmhbox(95.225pt, 3.125pt, 70.4pt, 55.6pt, 3.125pt) withcolor (0.9255,0.9255,1);
draw pmhbox(95.225pt, 3.125pt, 70.4pt, 55.6pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "round" & "}") scaled 1, (130.425pt, -30.925pt), 0, (0.2,0.2,0.2));
fill pmhbox(184.04pt, 22.425pt, 43.571pt, 17pt, 8.5pt) withcolor (0.9255,0.9255,1);
draw pmhbox(184.04pt, 22.425pt, 43.571pt, 17pt, 8.5pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "stadium" & "}") scaled 1, (205.825pt, -30.925pt), 0, (0.2,0.2,0.2));
fill pmhbox(246.025pt, 3.125pt, 70.4pt, 55.6pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(246.025pt, 3.125pt, 70.4pt, 55.6pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
draw (251.025pt, -3.125pt) -- (251.025pt, -58.725pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
draw (311.425pt, -3.125pt) -- (311.425pt, -58.725pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "subroutine" & "}") scaled 1, (281.225pt, -30.925pt), 0, (0.2,0.2,0.2));
fill (19.825pt, -71.131pt) -- (19.825pt, -111.919pt) -- (20.501pt, -113.364pt) -- (22.504pt, -114.753pt) -- 
  (25.757pt, -116.033pt) -- (30.135pt, -117.156pt) -- (35.469pt, -118.077pt) -- (41.554pt, -118.761pt) -- 
  (48.158pt, -119.183pt) -- (55.025pt, -119.325pt) -- (61.892pt, -119.183pt) -- (68.495pt, -118.761pt) -- 
  (74.581pt, -118.077pt) -- (79.915pt, -117.156pt) -- (84.293pt, -116.033pt) -- (87.546pt, -114.753pt) -- 
  (89.549pt, -113.364pt) -- (90.225pt, -111.919pt) -- (90.225pt, -71.131pt) -- (89.549pt, -69.686pt) -- 
  (87.546pt, -68.297pt) -- (84.293pt, -67.016pt) -- (79.915pt, -65.894pt) -- (74.581pt, -64.973pt) -- 
  (68.495pt, -64.289pt) -- (61.892pt, -63.867pt) -- (55.025pt, -63.725pt) -- (48.158pt, -63.867pt) -- 
  (41.554pt, -64.289pt) -- (35.469pt, -64.973pt) -- (30.135pt, -65.894pt) -- (25.757pt, -67.016pt) -- 
  (22.504pt, -68.297pt) -- (20.501pt, -69.686pt) -- (19.825pt, -71.131pt) -- cycle withcolor (0.9255,0.9255,1);
draw (19.825pt, -71.131pt) -- (19.825pt, -111.919pt) -- (20.501pt, -113.364pt) -- (22.504pt, -114.753pt) -- 
  (25.757pt, -116.033pt) -- (30.135pt, -117.156pt) -- (35.469pt, -118.077pt) -- (41.554pt, -118.761pt) -- 
  (48.158pt, -119.183pt) -- (55.025pt, -119.325pt) -- (61.892pt, -119.183pt) -- (68.495pt, -118.761pt) -- 
  (74.581pt, -118.077pt) -- (79.915pt, -117.156pt) -- (84.293pt, -116.033pt) -- (87.546pt, -114.753pt) -- 
  (89.549pt, -113.364pt) -- (90.225pt, -111.919pt) -- (90.225pt, -71.131pt) -- (89.549pt, -69.686pt) -- 
  (87.546pt, -68.297pt) -- (84.293pt, -67.016pt) -- (79.915pt, -65.894pt) -- (74.581pt, -64.973pt) -- 
  (68.495pt, -64.289pt) -- (61.892pt, -63.867pt) -- (55.025pt, -63.725pt) -- (48.158pt, -63.867pt) -- 
  (41.554pt, -64.289pt) -- (35.469pt, -64.973pt) -- (30.135pt, -65.894pt) -- (25.757pt, -67.016pt) -- 
  (22.504pt, -68.297pt) -- (20.501pt, -69.686pt) -- (19.825pt, -71.131pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
begingroup interim linecap := rounded; draw (19.825pt, -71.131pt)
  .. controls (19.825pt, -75.221pt) and (35.584pt, -78.537pt) .. (55.025pt, -78.537pt)
  .. controls (74.465pt, -78.537pt) and (90.225pt, -75.221pt) .. (90.225pt, -71.131pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "cylinder" & "}") scaled 1, (55.025pt, -94.858pt), 0, (0.2,0.2,0.2));
fill fullcircle scaled 36.2pt shifted (130.425pt, -91.525pt) withcolor (0.9255,0.9255,1);
draw fullcircle scaled 36.2pt shifted (130.425pt, -91.525pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "circle" & "}") scaled 1, (130.425pt, -91.525pt), 0, (0.2,0.2,0.2));
fill fullcircle scaled 86.65pt shifted (205.825pt, -91.525pt) withcolor (0.9255,0.9255,1);
draw fullcircle scaled 86.65pt shifted (205.825pt, -91.525pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 80.4pt shifted (205.825pt, -91.525pt) withcolor (0.9255,0.9255,1);
draw fullcircle scaled 80.4pt shifted (205.825pt, -91.525pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "double" & "}") scaled 1, (205.825pt, -91.525pt), 0, (0.2,0.2,0.2));
fill (246.025pt, -63.725pt) -- (259.925pt, -91.525pt) -- (246.025pt, -119.325pt) -- (316.425pt, -119.325pt) -- 
  (316.425pt, -63.725pt) -- cycle withcolor (0.9255,0.9255,1);
draw (246.025pt, -63.725pt) -- (259.925pt, -91.525pt) -- (246.025pt, -119.325pt) -- (316.425pt, -119.325pt) -- 
  (316.425pt, -63.725pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "flag" & "}") scaled 1, (288.175pt, -91.525pt), 0, (0.2,0.2,0.2));
fill (55.337pt, -179.925pt) -- (83.137pt, -152.125pt) -- (55.337pt, -124.325pt) -- (27.537pt, -152.125pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (55.337pt, -179.925pt) -- (83.137pt, -152.125pt) -- (55.337pt, -124.325pt) -- (27.537pt, -152.125pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "diamond" & "}") scaled 1, (55.025pt, -152.125pt), 0, (0.2,0.2,0.2));
fill (109.125pt, -179.925pt) -- (151.725pt, -179.925pt) -- (165.625pt, -152.125pt) -- (151.725pt, -124.325pt) -- 
  (109.125pt, -124.325pt) -- (95.225pt, -152.125pt) -- cycle withcolor (0.9255,0.9255,1);
draw (109.125pt, -179.925pt) -- (151.725pt, -179.925pt) -- (165.625pt, -152.125pt) -- (151.725pt, -124.325pt) -- 
  (109.125pt, -124.325pt) -- (95.225pt, -152.125pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "hexagon" & "}") scaled 1, (130.425pt, -152.125pt), 0, (0.2,0.2,0.2));
fill (152.675pt, -179.925pt) -- (231.175pt, -179.925pt) -- (258.975pt, -124.325pt) -- (180.475pt, -124.325pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (152.675pt, -179.925pt) -- (231.175pt, -179.925pt) -- (258.975pt, -124.325pt) -- (180.475pt, -124.325pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "lean right" & "}") scaled 1, (205.825pt, -152.125pt), 0, (0.2,0.2,0.2));
fill (258.275pt, -179.925pt) -- (331.975pt, -179.925pt) -- (304.175pt, -124.325pt) -- (230.475pt, -124.325pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (258.275pt, -179.925pt) -- (331.975pt, -179.925pt) -- (304.175pt, -124.325pt) -- (230.475pt, -124.325pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "lean left" & "}") scaled 1, (281.225pt, -152.125pt), 0, (0.2,0.2,0.2));
fill (3.125pt, -240.525pt) -- (106.925pt, -240.525pt) -- (79.125pt, -184.925pt) -- (30.925pt, -184.925pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (3.125pt, -240.525pt) -- (106.925pt, -240.525pt) -- (79.125pt, -184.925pt) -- (30.925pt, -184.925pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "trapezoid" & "}") scaled 1, (55.025pt, -212.725pt), 0, (0.2,0.2,0.2));
fill (106.225pt, -240.525pt) -- (154.625pt, -240.525pt) -- (182.425pt, -184.925pt) -- (78.425pt, -184.925pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (106.225pt, -240.525pt) -- (154.625pt, -240.525pt) -- (182.425pt, -184.925pt) -- (78.425pt, -184.925pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "inverted" & "}") scaled 1, (130.425pt, -212.725pt), 0, (0.2,0.2,0.2));
fill pmhbox(170.625pt, 184.925pt, 70.4pt, 55.6pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(170.625pt, 184.925pt, 70.4pt, 55.6pt, 0pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "na" & "}") scaled 1, (205.825pt, -212.725pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
