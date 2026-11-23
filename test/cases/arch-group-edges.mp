\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -299pt; pmxx2 := 275pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (127.5pt, -75pt)
  .. controls (127.5pt, -75pt) and (137.5pt, -75pt) .. (137.5pt, -75pt)
  .. controls (137.5pt, -75pt) and (147.5pt, -75pt) .. (147.5pt, -75pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
fill (148.75pt, -75pt) -- (140.417pt, -79.167pt) -- (140.417pt, -70.833pt) -- cycle withcolor (0.2,0.2,0.2);
begingroup interim linecap := rounded; draw (75pt, -100pt)
  .. controls (75pt, -100pt) and (75pt, -143.5pt) .. (75pt, -143.5pt)
  .. controls (75pt, -143.5pt) and (75pt, -187pt) .. (75pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (127.5pt, -212pt)
  .. controls (127.5pt, -212pt) and (200pt, -212pt) .. (200pt, -212pt)
  .. controls (200pt, -212pt) and (200pt, -138.75pt) .. (200pt, -138.75pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
fill pmhbox(50pt, 50pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(60.938pt, 60.938pt, 28.125pt, 28.125pt, 1.25pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (60.938pt, -70.313pt) -- (89.063pt, -70.313pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (60.938pt, -79.688pt) -- (89.063pt, -79.688pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
fill pmhbox(77.344pt, 65pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (70.313pt, -65.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (70.313pt, -65.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (67.188pt, -65.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (67.188pt, -65.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (64.063pt, -65.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (64.063pt, -65.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill pmhbox(77.344pt, 74.375pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (70.313pt, -75pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (70.313pt, -75pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (67.188pt, -75pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (67.188pt, -75pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (64.063pt, -75pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (64.063pt, -75pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill pmhbox(77.344pt, 83.75pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (70.313pt, -84.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (70.313pt, -84.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (67.188pt, -84.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (67.188pt, -84.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (64.063pt, -84.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (64.063pt, -84.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A" & "}") scaled 1, (75pt, -106pt), 0, (0.2,0.2,0.2));
fill pmhbox(175pt, 50pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(185.938pt, 60.938pt, 28.125pt, 28.125pt, 1.25pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (185.938pt, -70.313pt) -- (214.063pt, -70.313pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (185.938pt, -79.688pt) -- (214.063pt, -79.688pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
fill pmhbox(202.344pt, 65pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (195.313pt, -65.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (195.313pt, -65.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (192.188pt, -65.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (192.188pt, -65.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (189.063pt, -65.625pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (189.063pt, -65.625pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill pmhbox(202.344pt, 74.375pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (195.313pt, -75pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (195.313pt, -75pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (192.188pt, -75pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (192.188pt, -75pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (189.063pt, -75pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (189.063pt, -75pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill pmhbox(202.344pt, 83.75pt, 7.813pt, 1.25pt, 0.625pt) withcolor (1,1,1);
fill fullcircle scaled 0.938pt shifted (195.313pt, -84.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (195.313pt, -84.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (192.188pt, -84.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (192.188pt, -84.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 0.938pt shifted (189.063pt, -84.375pt) withcolor (1,1,1);
draw fullcircle scaled 0.938pt shifted (189.063pt, -84.375pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B" & "}") scaled 1, (200pt, -106pt), 0, (0.2,0.2,0.2));
fill pmhbox(50pt, 187pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (62.5pt, -223.162pt)
  .. controls (62.5pt, -225.625pt) and (68.094pt, -227.625pt) .. (75pt, -227.625pt)
  .. controls (81.906pt, -227.625pt) and (87.5pt, -225.625pt) .. (87.5pt, -223.162pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (62.5pt, -215.722pt)
  .. controls (62.5pt, -218.184pt) and (68.094pt, -220.184pt) .. (75pt, -220.184pt)
  .. controls (81.906pt, -220.184pt) and (87.5pt, -218.184pt) .. (87.5pt, -215.722pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (62.5pt, -208.281pt)
  .. controls (62.5pt, -210.744pt) and (68.094pt, -212.744pt) .. (75pt, -212.744pt)
  .. controls (81.906pt, -212.744pt) and (87.5pt, -210.744pt) .. (87.5pt, -208.281pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (87.5pt, -200.838pt)
  .. controls (87.5pt, -203.302pt) and (81.904pt, -205.3pt) .. (75pt, -205.3pt)
  .. controls (68.096pt, -205.3pt) and (62.5pt, -203.302pt) .. (62.5pt, -200.838pt)
  .. controls (62.5pt, -198.373pt) and (68.096pt, -196.375pt) .. (75pt, -196.375pt)
  .. controls (81.904pt, -196.375pt) and (87.5pt, -198.373pt) .. (87.5pt, -200.838pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
draw (62.5pt, -223.162pt) -- (62.5pt, -200.838pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (87.5pt, -223.162pt) -- (87.5pt, -200.838pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "C" & "}") scaled 1, (75pt, -243pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (25pt, -25pt)
  .. controls (25pt, -25pt) and (125pt, -25pt) .. (125pt, -25pt)
  .. controls (125pt, -25pt) and (125pt, -274pt) .. (125pt, -274pt)
  .. controls (125pt, -274pt) and (25pt, -274pt) .. (25pt, -274pt)
  .. controls (25pt, -274pt) and (25pt, -25pt) .. (25pt, -25pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.25pt dashed dashpattern(on 5pt off 5pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Left" & "}") scaled 1, (37.95pt, -32.25pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (150pt, -25pt)
  .. controls (150pt, -25pt) and (250pt, -25pt) .. (250pt, -25pt)
  .. controls (250pt, -25pt) and (250pt, -137pt) .. (250pt, -137pt)
  .. controls (250pt, -137pt) and (150pt, -137pt) .. (150pt, -137pt)
  .. controls (150pt, -137pt) and (150pt, -25pt) .. (150pt, -25pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.25pt dashed dashpattern(on 5pt off 5pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Right" & "}") scaled 1, (165.35pt, -32.25pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
