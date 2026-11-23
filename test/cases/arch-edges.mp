\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -277.92pt; pmxx2 := 432pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (126pt, -116.64pt)
  .. controls (126pt, -116.64pt) and (126pt, -85.32pt) .. (126pt, -85.32pt)
  .. controls (126pt, -85.32pt) and (126pt, -54pt) .. (126pt, -54pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.35pt; endgroup;
fill (126pt, -53.1pt) -- (129pt, -59.1pt) -- (123pt, -59.1pt) -- cycle withcolor (0.2,0.2,0.2);
begingroup interim linecap := rounded; draw (126pt, -152.64pt)
  .. controls (126pt, -152.64pt) and (126pt, -183.96pt) .. (126pt, -183.96pt)
  .. controls (126pt, -183.96pt) and (126pt, -215.28pt) .. (126pt, -215.28pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.35pt; endgroup;
fill (126pt, -151.74pt) -- (129pt, -157.74pt) -- (123pt, -157.74pt) -- cycle withcolor (0.2,0.2,0.2);
fill (123pt, -210.18pt) -- (129pt, -210.18pt) -- (126pt, -216.18pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "down" & "}") scaled 1, (130.32pt, -183.96pt), -90, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (144pt, -134.64pt)
  .. controls (144pt, -134.64pt) and (171pt, -134.64pt) .. (171pt, -134.64pt)
  .. controls (171pt, -134.64pt) and (198pt, -134.64pt) .. (198pt, -134.64pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.35pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "a rather long\\edge title" & "}") scaled 1, (171pt, -143.28pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (54pt, -134.64pt)
  .. controls (54pt, -134.64pt) and (81pt, -134.64pt) .. (81pt, -134.64pt)
  .. controls (81pt, -134.64pt) and (108pt, -134.64pt) .. (108pt, -134.64pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.35pt; endgroup;
fill (53.1pt, -134.64pt) -- (59.1pt, -131.64pt) -- (59.1pt, -137.64pt) -- cycle withcolor (0.2,0.2,0.2);
begingroup interim linecap := rounded; draw (144pt, -36pt)
  .. controls (144pt, -36pt) and (306pt, -36pt) .. (306pt, -36pt)
  .. controls (306pt, -36pt) and (306pt, -152.64pt) .. (306pt, -152.64pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.35pt; endgroup;
fill (306pt, -151.74pt) -- (309pt, -157.74pt) -- (303pt, -157.74pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "bend" & "}") scaled 1, (217.058pt, -86.378pt), -45, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (108pt, -233.28pt)
  .. controls (108pt, -233.28pt) and (396pt, -233.28pt) .. (396pt, -233.28pt)
  .. controls (396pt, -233.28pt) and (396pt, -116.64pt) .. (396pt, -116.64pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.35pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "turn" & "}") scaled 1, (259.942pt, -182.902pt), -45, (0.2,0.2,0.2));
fill pmhbox(108pt, 116.64pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(115.875pt, 124.515pt, 20.25pt, 20.25pt, 0.9pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw (115.875pt, -131.265pt) -- (136.125pt, -131.265pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw (115.875pt, -138.015pt) -- (136.125pt, -138.015pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
fill pmhbox(127.688pt, 127.44pt, 5.625pt, 0.9pt, 0.45pt) withcolor (1,1,1);
fill fullcircle scaled 0.675pt shifted (122.625pt, -127.89pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (122.625pt, -127.89pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill fullcircle scaled 0.675pt shifted (120.375pt, -127.89pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (120.375pt, -127.89pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill fullcircle scaled 0.675pt shifted (118.125pt, -127.89pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (118.125pt, -127.89pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill pmhbox(127.688pt, 134.19pt, 5.625pt, 0.9pt, 0.45pt) withcolor (1,1,1);
fill fullcircle scaled 0.675pt shifted (122.625pt, -134.64pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (122.625pt, -134.64pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill fullcircle scaled 0.675pt shifted (120.375pt, -134.64pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (120.375pt, -134.64pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill fullcircle scaled 0.675pt shifted (118.125pt, -134.64pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (118.125pt, -134.64pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill pmhbox(127.688pt, 140.94pt, 5.625pt, 0.9pt, 0.45pt) withcolor (1,1,1);
fill fullcircle scaled 0.675pt shifted (122.625pt, -141.39pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (122.625pt, -141.39pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill fullcircle scaled 0.675pt shifted (120.375pt, -141.39pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (120.375pt, -141.39pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
fill fullcircle scaled 0.675pt shifted (118.125pt, -141.39pt) withcolor (1,1,1);
draw fullcircle scaled 0.675pt shifted (118.125pt, -141.39pt) withcolor (1,1,1) withpen pencircle scaled 0.45pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Hub" & "}") scaled 1, (126pt, -156.96pt), 0, (0.2,0.2,0.2));
fill pmhbox(108pt, 18pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (137.25pt, -39.375pt)
  .. controls (137.25pt, -40.617pt) and (136.242pt, -41.625pt) .. (135pt, -41.625pt)
  .. controls (135pt, -41.625pt) and (117pt, -41.625pt) .. (117pt, -41.625pt)
  .. controls (115.758pt, -41.625pt) and (114.75pt, -40.617pt) .. (114.75pt, -39.375pt)
  .. controls (114.75pt, -38.533pt) and (115.214pt, -37.796pt) .. (115.902pt, -37.413pt)
  .. controls (115.884pt, -37.318pt) and (115.875pt, -37.224pt) .. (115.875pt, -37.125pt)
  .. controls (115.875pt, -35.955pt) and (116.991pt, -34.992pt) .. (118.417pt, -34.889pt)
  .. controls (119.16pt, -32.859pt) and (121.271pt, -31.396pt) .. (123.75pt, -31.396pt)
  .. controls (124.137pt, -31.396pt) and (124.51pt, -31.432pt) .. (124.875pt, -31.5pt)
  .. controls (125.816pt, -30.793pt) and (126.985pt, -30.375pt) .. (128.25pt, -30.375pt)
  .. controls (130.995pt, -30.375pt) and (133.286pt, -32.346pt) .. (133.776pt, -34.952pt)
  .. controls (134.739pt, -35.203pt) and (135.45pt, -36.081pt) .. (135.45pt, -37.125pt)
  .. controls (135.45pt, -37.139pt) and (135.45pt, -37.156pt) .. (135.446pt, -37.17pt)
  .. controls (136.476pt, -37.377pt) and (137.25pt, -38.286pt) .. (137.25pt, -39.375pt)
  .. controls (137.25pt, -39.375pt) and (137.25pt, -39.375pt) .. (137.25pt, -39.375pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "North" & "}") scaled 1, (126pt, -58.32pt), 0, (0.2,0.2,0.2));
fill pmhbox(108pt, 215.28pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (137.25pt, -236.655pt)
  .. controls (137.25pt, -237.897pt) and (136.242pt, -238.905pt) .. (135pt, -238.905pt)
  .. controls (135pt, -238.905pt) and (117pt, -238.905pt) .. (117pt, -238.905pt)
  .. controls (115.758pt, -238.905pt) and (114.75pt, -237.897pt) .. (114.75pt, -236.655pt)
  .. controls (114.75pt, -235.813pt) and (115.214pt, -235.075pt) .. (115.902pt, -234.693pt)
  .. controls (115.884pt, -234.599pt) and (115.875pt, -234.504pt) .. (115.875pt, -234.405pt)
  .. controls (115.875pt, -233.235pt) and (116.991pt, -232.272pt) .. (118.417pt, -232.168pt)
  .. controls (119.16pt, -230.139pt) and (121.271pt, -228.677pt) .. (123.75pt, -228.677pt)
  .. controls (124.137pt, -228.677pt) and (124.51pt, -228.713pt) .. (124.875pt, -228.78pt)
  .. controls (125.816pt, -228.073pt) and (126.985pt, -227.655pt) .. (128.25pt, -227.655pt)
  .. controls (130.995pt, -227.655pt) and (133.286pt, -229.626pt) .. (133.776pt, -232.231pt)
  .. controls (134.739pt, -232.484pt) and (135.45pt, -233.361pt) .. (135.45pt, -234.405pt)
  .. controls (135.45pt, -234.418pt) and (135.45pt, -234.437pt) .. (135.446pt, -234.45pt)
  .. controls (136.476pt, -234.657pt) and (137.25pt, -235.566pt) .. (137.25pt, -236.655pt)
  .. controls (137.25pt, -236.655pt) and (137.25pt, -236.655pt) .. (137.25pt, -236.655pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "South" & "}") scaled 1, (126pt, -255.6pt), 0, (0.2,0.2,0.2));
fill pmhbox(198pt, 116.64pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (227.25pt, -138.015pt)
  .. controls (227.25pt, -139.257pt) and (226.242pt, -140.265pt) .. (225pt, -140.265pt)
  .. controls (225pt, -140.265pt) and (207pt, -140.265pt) .. (207pt, -140.265pt)
  .. controls (205.758pt, -140.265pt) and (204.75pt, -139.257pt) .. (204.75pt, -138.015pt)
  .. controls (204.75pt, -137.173pt) and (205.214pt, -136.436pt) .. (205.902pt, -136.053pt)
  .. controls (205.884pt, -135.958pt) and (205.875pt, -135.864pt) .. (205.875pt, -135.765pt)
  .. controls (205.875pt, -134.595pt) and (206.991pt, -133.632pt) .. (208.417pt, -133.528pt)
  .. controls (209.16pt, -131.499pt) and (211.271pt, -130.036pt) .. (213.75pt, -130.036pt)
  .. controls (214.137pt, -130.036pt) and (214.51pt, -130.073pt) .. (214.875pt, -130.14pt)
  .. controls (215.816pt, -129.433pt) and (216.985pt, -129.015pt) .. (218.25pt, -129.015pt)
  .. controls (220.995pt, -129.015pt) and (223.286pt, -130.986pt) .. (223.776pt, -133.592pt)
  .. controls (224.739pt, -133.844pt) and (225.45pt, -134.721pt) .. (225.45pt, -135.765pt)
  .. controls (225.45pt, -135.778pt) and (225.45pt, -135.797pt) .. (225.445pt, -135.81pt)
  .. controls (226.476pt, -136.017pt) and (227.25pt, -136.926pt) .. (227.25pt, -138.015pt)
  .. controls (227.25pt, -138.015pt) and (227.25pt, -138.015pt) .. (227.25pt, -138.015pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "East" & "}") scaled 1, (216pt, -156.96pt), 0, (0.2,0.2,0.2));
fill pmhbox(18pt, 116.64pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (47.25pt, -138.015pt)
  .. controls (47.25pt, -139.257pt) and (46.242pt, -140.265pt) .. (45pt, -140.265pt)
  .. controls (45pt, -140.265pt) and (27pt, -140.265pt) .. (27pt, -140.265pt)
  .. controls (25.758pt, -140.265pt) and (24.75pt, -139.257pt) .. (24.75pt, -138.015pt)
  .. controls (24.75pt, -137.173pt) and (25.214pt, -136.436pt) .. (25.902pt, -136.053pt)
  .. controls (25.884pt, -135.958pt) and (25.875pt, -135.864pt) .. (25.875pt, -135.765pt)
  .. controls (25.875pt, -134.595pt) and (26.991pt, -133.632pt) .. (28.417pt, -133.528pt)
  .. controls (29.16pt, -131.499pt) and (31.271pt, -130.036pt) .. (33.75pt, -130.036pt)
  .. controls (34.137pt, -130.036pt) and (34.51pt, -130.073pt) .. (34.875pt, -130.14pt)
  .. controls (35.816pt, -129.433pt) and (36.985pt, -129.015pt) .. (38.25pt, -129.015pt)
  .. controls (40.995pt, -129.015pt) and (43.286pt, -130.986pt) .. (43.776pt, -133.592pt)
  .. controls (44.739pt, -133.844pt) and (45.45pt, -134.721pt) .. (45.45pt, -135.765pt)
  .. controls (45.45pt, -135.778pt) and (45.45pt, -135.797pt) .. (45.446pt, -135.81pt)
  .. controls (46.476pt, -136.017pt) and (47.25pt, -136.926pt) .. (47.25pt, -138.015pt)
  .. controls (47.25pt, -138.015pt) and (47.25pt, -138.015pt) .. (47.25pt, -138.015pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "West" & "}") scaled 1, (36pt, -156.96pt), 0, (0.2,0.2,0.2));
fill pmhbox(288pt, 116.64pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(297pt, 123.39pt, 18pt, 22.5pt, 0.45pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (298.8pt, -125.266pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (313.2pt, -125.266pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (298.8pt, -144.014pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (313.2pt, -144.014pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
begingroup interim linecap := rounded; draw (312.3pt, -131.828pt)
  .. controls (312.3pt, -135.451pt) and (309.479pt, -138.389pt) .. (306pt, -138.389pt)
  .. controls (302.521pt, -138.389pt) and (299.7pt, -135.451pt) .. (299.7pt, -131.828pt)
  .. controls (299.7pt, -128.204pt) and (302.521pt, -125.266pt) .. (306pt, -125.266pt)
  .. controls (309.479pt, -125.266pt) and (312.3pt, -128.204pt) .. (312.3pt, -131.828pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt; endgroup;
fill fullcircle scaled 3.672pt shifted (306pt, -131.828pt) withcolor (1,1,1);
fill (304.88pt, -135.774pt) -- (302.706pt, -141.723pt) -- (302.651pt, -141.834pt) -- (302.575pt, -141.927pt) -- 
  (302.482pt, -142pt) -- (302.377pt, -142.051pt) -- (302.264pt, -142.079pt) -- (302.147pt, -142.083pt) -- 
  (302.028pt, -142.061pt) -- (301.914pt, -142.011pt) -- (300.033pt, -140.922pt) -- (299.932pt, -140.848pt) -- 
  (299.854pt, -140.757pt) -- (299.799pt, -140.654pt) -- (299.766pt, -140.542pt) -- (299.758pt, -140.426pt) -- 
  (299.775pt, -140.309pt) -- (299.817pt, -140.198pt) -- (299.885pt, -140.094pt) -- (303.939pt, -135.234pt) -- 
  (304.102pt, -135.098pt) -- (304.283pt, -135.038pt) -- (304.466pt, -135.045pt) -- (304.637pt, -135.111pt) -- 
  (304.779pt, -135.225pt) -- (304.877pt, -135.38pt) -- (304.916pt, -135.566pt) -- (304.88pt, -135.774pt) -- 
  (304.88pt, -135.774pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "NE" & "}") scaled 1, (306pt, -156.96pt), 0, (0.2,0.2,0.2));
fill pmhbox(378pt, 116.64pt, 36pt, 36pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(387pt, 123.39pt, 18pt, 22.5pt, 0.45pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (388.8pt, -125.266pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (403.2pt, -125.266pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (388.8pt, -144.014pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
draw fullcircle scaled 0.72pt shifted (403.2pt, -144.014pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt;
begingroup interim linecap := rounded; draw (402.3pt, -131.828pt)
  .. controls (402.3pt, -135.451pt) and (399.479pt, -138.389pt) .. (396pt, -138.389pt)
  .. controls (392.521pt, -138.389pt) and (389.7pt, -135.451pt) .. (389.7pt, -131.828pt)
  .. controls (389.7pt, -128.204pt) and (392.521pt, -125.266pt) .. (396pt, -125.266pt)
  .. controls (399.479pt, -125.266pt) and (402.3pt, -128.204pt) .. (402.3pt, -131.828pt) withcolor (1,1,1) withpen pencircle scaled 0.9pt; endgroup;
fill fullcircle scaled 3.672pt shifted (396pt, -131.828pt) withcolor (1,1,1);
fill (394.88pt, -135.774pt) -- (392.706pt, -141.723pt) -- (392.651pt, -141.834pt) -- (392.575pt, -141.927pt) -- 
  (392.482pt, -142pt) -- (392.377pt, -142.051pt) -- (392.264pt, -142.079pt) -- (392.147pt, -142.083pt) -- 
  (392.028pt, -142.061pt) -- (391.914pt, -142.011pt) -- (390.033pt, -140.922pt) -- (389.932pt, -140.848pt) -- 
  (389.854pt, -140.757pt) -- (389.799pt, -140.654pt) -- (389.766pt, -140.542pt) -- (389.758pt, -140.426pt) -- 
  (389.775pt, -140.309pt) -- (389.817pt, -140.198pt) -- (389.885pt, -140.094pt) -- (393.939pt, -135.234pt) -- 
  (394.102pt, -135.098pt) -- (394.283pt, -135.038pt) -- (394.466pt, -135.045pt) -- (394.637pt, -135.111pt) -- 
  (394.779pt, -135.225pt) -- (394.877pt, -135.38pt) -- (394.916pt, -135.566pt) -- (394.88pt, -135.774pt) -- 
  (394.88pt, -135.774pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "SW" & "}") scaled 1, (396pt, -156.96pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
