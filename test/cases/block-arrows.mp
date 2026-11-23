\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -139.25pt; pmxx2 := 219.25pt; pmxx3 := 0;
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
fill (9.325pt, -22.625pt) -- (9.325pt, -22.625pt) -- (38.325pt, -22.625pt) -- (38.325pt, -25.125pt) -- 
  (49.325pt, -14.125pt) -- (38.325pt, -3.125pt) -- (38.325pt, -5.625pt) -- (9.325pt, -5.625pt) -- 
  (9.325pt, -5.625pt) -- cycle withcolor (0.9255,0.9255,1);
draw (9.325pt, -22.625pt) -- (9.325pt, -22.625pt) -- (38.325pt, -22.625pt) -- (38.325pt, -25.125pt) -- 
  (49.325pt, -14.125pt) -- (38.325pt, -3.125pt) -- (38.325pt, -5.625pt) -- (9.325pt, -5.625pt) -- 
  (9.325pt, -5.625pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "right" & "}") scaled 1, (23.825pt, -14.125pt), 0, (0.2,0.2,0.2));
fill (68.125pt, -25.125pt) -- (68.125pt, -22.625pt) -- (92.325pt, -22.625pt) -- (92.325pt, -5.625pt) -- 
  (68.125pt, -5.625pt) -- (68.125pt, -3.125pt) -- (57.125pt, -14.125pt) -- cycle withcolor (0.9255,0.9255,1);
draw (68.125pt, -25.125pt) -- (68.125pt, -22.625pt) -- (92.325pt, -22.625pt) -- (92.325pt, -5.625pt) -- 
  (68.125pt, -5.625pt) -- (68.125pt, -3.125pt) -- (57.125pt, -14.125pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "left" & "}") scaled 1, (80.225pt, -14.125pt), 0, (0.2,0.2,0.2));
fill (129.325pt, -22.625pt) -- (129.325pt, -5.625pt) -- (118.325pt, -5.625pt) -- (136.625pt, -3.125pt) -- 
  (154.925pt, -5.625pt) -- (143.925pt, -5.625pt) -- (143.925pt, -22.625pt) -- cycle withcolor (0.9255,0.9255,1);
draw (129.325pt, -22.625pt) -- (129.325pt, -5.625pt) -- (118.325pt, -5.625pt) -- (136.625pt, -3.125pt) -- 
  (154.925pt, -5.625pt) -- (143.925pt, -5.625pt) -- (143.925pt, -22.625pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "up" & "}") scaled 1, (136.625pt, -14.125pt), 0, (0.2,0.2,0.2));
fill (193.025pt, -25.125pt) -- (169.925pt, -22.625pt) -- (180.925pt, -22.625pt) -- (180.925pt, -5.625pt) -- 
  (205.125pt, -5.625pt) -- (205.125pt, -22.625pt) -- (216.125pt, -22.625pt) -- cycle withcolor (0.9255,0.9255,1);
draw (193.025pt, -25.125pt) -- (169.925pt, -22.625pt) -- (180.925pt, -22.625pt) -- (180.925pt, -5.625pt) -- 
  (205.125pt, -5.625pt) -- (205.125pt, -22.625pt) -- (216.125pt, -22.625pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "down" & "}") scaled 1, (193.025pt, -14.125pt), 0, (0.2,0.2,0.2));
fill (18.925pt, -62.125pt) -- (18.925pt, -59.625pt) -- (28.725pt, -59.625pt) -- (28.725pt, -62.125pt) -- 
  (39.725pt, -51.125pt) -- (28.725pt, -40.125pt) -- (28.725pt, -42.625pt) -- (18.925pt, -42.625pt) -- 
  (18.925pt, -40.125pt) -- (7.925pt, -51.125pt) -- cycle withcolor (0.9255,0.9255,1);
draw (18.925pt, -62.125pt) -- (18.925pt, -59.625pt) -- (28.725pt, -59.625pt) -- (28.725pt, -62.125pt) -- 
  (39.725pt, -51.125pt) -- (28.725pt, -40.125pt) -- (28.725pt, -42.625pt) -- (18.925pt, -42.625pt) -- 
  (18.925pt, -40.125pt) -- (7.925pt, -51.125pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "x" & "}") scaled 1, (23.825pt, -51.125pt), 0, (0.2,0.2,0.2));
fill (80.225pt, -62.125pt) -- (64.325pt, -59.625pt) -- (75.325pt, -59.625pt) -- (75.325pt, -42.625pt) -- 
  (64.325pt, -42.625pt) -- (80.225pt, -40.125pt) -- (96.125pt, -42.625pt) -- (85.125pt, -42.625pt) -- 
  (85.125pt, -59.625pt) -- (96.125pt, -59.625pt) -- cycle withcolor (0.9255,0.9255,1);
draw (80.225pt, -62.125pt) -- (64.325pt, -59.625pt) -- (75.325pt, -59.625pt) -- (75.325pt, -42.625pt) -- 
  (64.325pt, -42.625pt) -- (80.225pt, -40.125pt) -- (96.125pt, -42.625pt) -- (85.125pt, -42.625pt) -- 
  (85.125pt, -59.625pt) -- (96.125pt, -59.625pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "y" & "}") scaled 1, (80.225pt, -51.125pt), 0, (0.2,0.2,0.2));
fill (118.325pt, -62.125pt) -- (154.925pt, -62.125pt) -- (118.325pt, -40.125pt) -- cycle withcolor (0.9255,0.9255,1);
draw (118.325pt, -62.125pt) -- (154.925pt, -62.125pt) -- (118.325pt, -40.125pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "rd" & "}") scaled 1, (136.625pt, -51.125pt), 0, (0.2,0.2,0.2));
fill (211.325pt, -62.125pt) -- (174.725pt, -51.125pt) -- (211.325pt, -40.125pt) -- cycle withcolor (0.9255,0.9255,1);
draw (211.325pt, -62.125pt) -- (174.725pt, -51.125pt) -- (211.325pt, -40.125pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "lu" & "}") scaled 1, (193.025pt, -51.125pt), 0, (0.2,0.2,0.2));
fill (14.125pt, -99.125pt) -- (33.525pt, -99.125pt) -- (44.525pt, -88.125pt) -- (33.525pt, -77.125pt) -- 
  (14.125pt, -77.125pt) -- (3.125pt, -88.125pt) -- cycle withcolor (0.9255,0.9255,1);
draw (14.125pt, -99.125pt) -- (33.525pt, -99.125pt) -- (44.525pt, -88.125pt) -- (33.525pt, -77.125pt) -- 
  (14.125pt, -77.125pt) -- (3.125pt, -88.125pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "rlu" & "}") scaled 1, (23.825pt, -88.125pt), 0, (0.2,0.2,0.2));
fill (59.525pt, -99.125pt) -- (70.525pt, -77.125pt) -- (89.925pt, -77.125pt) -- (100.925pt, -99.125pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (59.525pt, -99.125pt) -- (70.525pt, -77.125pt) -- (89.925pt, -77.125pt) -- (100.925pt, -99.125pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "rld" & "}") scaled 1, (80.225pt, -88.125pt), 0, (0.2,0.2,0.2));
fill (115.925pt, -99.125pt) -- (126.925pt, -99.125pt) -- (136.625pt, -104.125pt) -- (146.325pt, -99.125pt) -- 
  (157.325pt, -99.125pt) -- (157.325pt, -91.792pt) -- (162.325pt, -88.125pt) -- (157.325pt, -84.458pt) -- 
  (157.325pt, -77.125pt) -- (146.325pt, -77.125pt) -- (136.625pt, -72.125pt) -- (126.925pt, -77.125pt) -- 
  (115.925pt, -77.125pt) -- (115.925pt, -84.458pt) -- (110.925pt, -88.125pt) -- (115.925pt, -91.792pt) -- 
  cycle withcolor (0.9255,0.9255,1);
draw (115.925pt, -99.125pt) -- (126.925pt, -99.125pt) -- (136.625pt, -104.125pt) -- (146.325pt, -99.125pt) -- 
  (157.325pt, -99.125pt) -- (157.325pt, -91.792pt) -- (162.325pt, -88.125pt) -- (157.325pt, -84.458pt) -- 
  (157.325pt, -77.125pt) -- (146.325pt, -77.125pt) -- (136.625pt, -72.125pt) -- (126.925pt, -77.125pt) -- 
  (115.925pt, -77.125pt) -- (115.925pt, -84.458pt) -- (110.925pt, -88.125pt) -- (115.925pt, -91.792pt) -- 
  cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "all" & "}") scaled 1, (136.625pt, -88.125pt), 0, (0.2,0.2,0.2));
fill (180.925pt, -96.625pt) -- (180.925pt, -96.625pt) -- (205.125pt, -96.625pt) -- (205.125pt, -99.125pt) -- 
  (216.125pt, -88.125pt) -- (205.125pt, -77.125pt) -- (205.125pt, -79.625pt) -- (180.925pt, -79.625pt) -- 
  (180.925pt, -79.625pt) -- cycle withcolor (0.9255,0.9255,1);
draw (180.925pt, -96.625pt) -- (180.925pt, -96.625pt) -- (205.125pt, -96.625pt) -- (205.125pt, -99.125pt) -- 
  (216.125pt, -88.125pt) -- (205.125pt, -77.125pt) -- (205.125pt, -79.625pt) -- (180.925pt, -79.625pt) -- 
  (180.925pt, -79.625pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "wide" & "}") scaled 1, (193.025pt, -88.125pt), 0, (0.2,0.2,0.2));
fill (9.125pt, -133.625pt) -- (9.125pt, -133.625pt) -- (94.925pt, -133.625pt) -- (94.925pt, -136.125pt) -- 
  (105.925pt, -125.125pt) -- (94.925pt, -114.125pt) -- (94.925pt, -116.625pt) -- (9.125pt, -116.625pt) -- 
  (9.125pt, -116.625pt) -- cycle withcolor (0.9255,0.9255,1);
draw (9.125pt, -133.625pt) -- (9.125pt, -133.625pt) -- (94.925pt, -133.625pt) -- (94.925pt, -136.125pt) -- 
  (105.925pt, -125.125pt) -- (94.925pt, -114.125pt) -- (94.925pt, -116.625pt) -- (9.125pt, -116.625pt) -- 
  (9.125pt, -116.625pt) -- cycle withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "spans two" & "}") scaled 1, (52.025pt, -125.125pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
