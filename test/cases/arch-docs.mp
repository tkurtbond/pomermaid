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
begingroup interim linecap := rounded; draw (175pt, -75pt)
  .. controls (175pt, -75pt) and (137.5pt, -75pt) .. (137.5pt, -75pt)
  .. controls (137.5pt, -75pt) and (100pt, -75pt) .. (100pt, -75pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (75pt, -187pt)
  .. controls (75pt, -187pt) and (75pt, -143.5pt) .. (75pt, -143.5pt)
  .. controls (75pt, -143.5pt) and (75pt, -100pt) .. (75pt, -100pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (200pt, -187pt)
  .. controls (200pt, -187pt) and (200pt, -143.5pt) .. (200pt, -143.5pt)
  .. controls (200pt, -143.5pt) and (200pt, -100pt) .. (200pt, -100pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
fill pmhbox(175pt, 50pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (187.5pt, -86.162pt)
  .. controls (187.5pt, -88.625pt) and (193.094pt, -90.625pt) .. (200pt, -90.625pt)
  .. controls (206.906pt, -90.625pt) and (212.5pt, -88.625pt) .. (212.5pt, -86.162pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (187.5pt, -78.722pt)
  .. controls (187.5pt, -81.184pt) and (193.094pt, -83.184pt) .. (200pt, -83.184pt)
  .. controls (206.906pt, -83.184pt) and (212.5pt, -81.184pt) .. (212.5pt, -78.722pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (187.5pt, -71.281pt)
  .. controls (187.5pt, -73.744pt) and (193.094pt, -75.744pt) .. (200pt, -75.744pt)
  .. controls (206.906pt, -75.744pt) and (212.5pt, -73.744pt) .. (212.5pt, -71.281pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (212.5pt, -63.838pt)
  .. controls (212.5pt, -66.302pt) and (206.904pt, -68.3pt) .. (200pt, -68.3pt)
  .. controls (193.096pt, -68.3pt) and (187.5pt, -66.302pt) .. (187.5pt, -63.838pt)
  .. controls (187.5pt, -61.373pt) and (193.096pt, -59.375pt) .. (200pt, -59.375pt)
  .. controls (206.904pt, -59.375pt) and (212.5pt, -61.373pt) .. (212.5pt, -63.838pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
draw (187.5pt, -86.162pt) -- (187.5pt, -63.838pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (212.5pt, -86.162pt) -- (212.5pt, -63.838pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Database" & "}") scaled 1, (200pt, -106pt), 0, (0.2,0.2,0.2));
fill pmhbox(50pt, 187pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(62.5pt, 196.375pt, 25pt, 31.25pt, 0.625pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (65pt, -198.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (85pt, -198.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (65pt, -225.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (85pt, -225.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (83.75pt, -208.094pt)
  .. controls (83.75pt, -213.126pt) and (79.833pt, -217.206pt) .. (75pt, -217.206pt)
  .. controls (70.167pt, -217.206pt) and (66.25pt, -213.126pt) .. (66.25pt, -208.094pt)
  .. controls (66.25pt, -203.061pt) and (70.167pt, -198.981pt) .. (75pt, -198.981pt)
  .. controls (79.833pt, -198.981pt) and (83.75pt, -203.061pt) .. (83.75pt, -208.094pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
fill fullcircle scaled 5.1pt shifted (75pt, -208.094pt) withcolor (1,1,1);
fill (73.444pt, -213.575pt) -- (70.425pt, -221.838pt) -- (70.348pt, -221.992pt) -- (70.243pt, -222.121pt) -- 
  (70.114pt, -222.222pt) -- (69.969pt, -222.293pt) -- (69.812pt, -222.332pt) -- (69.648pt, -222.338pt) -- 
  (69.484pt, -222.307pt) -- (69.325pt, -222.238pt) -- (66.713pt, -220.725pt) -- (66.573pt, -220.622pt) -- 
  (66.464pt, -220.496pt) -- (66.387pt, -220.352pt) -- (66.342pt, -220.197pt) -- (66.331pt, -220.036pt) -- 
  (66.354pt, -219.874pt) -- (66.412pt, -219.719pt) -- (66.506pt, -219.575pt) -- (72.137pt, -212.825pt) -- 
  (72.364pt, -212.636pt) -- (72.615pt, -212.553pt) -- (72.87pt, -212.563pt) -- (73.107pt, -212.654pt) -- 
  (73.305pt, -212.813pt) -- (73.441pt, -213.028pt) -- (73.495pt, -213.286pt) -- (73.444pt, -213.575pt) -- 
  (73.444pt, -213.575pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Storage" & "}") scaled 1, (75pt, -243pt), 0, (0.2,0.2,0.2));
fill pmhbox(175pt, 187pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(187.5pt, 196.375pt, 25pt, 31.25pt, 0.625pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (190pt, -198.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (210pt, -198.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (190pt, -225.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (210pt, -225.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (208.75pt, -208.094pt)
  .. controls (208.75pt, -213.126pt) and (204.833pt, -217.206pt) .. (200pt, -217.206pt)
  .. controls (195.167pt, -217.206pt) and (191.25pt, -213.126pt) .. (191.25pt, -208.094pt)
  .. controls (191.25pt, -203.061pt) and (195.167pt, -198.981pt) .. (200pt, -198.981pt)
  .. controls (204.833pt, -198.981pt) and (208.75pt, -203.061pt) .. (208.75pt, -208.094pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
fill fullcircle scaled 5.1pt shifted (200pt, -208.094pt) withcolor (1,1,1);
fill (198.444pt, -213.575pt) -- (195.425pt, -221.838pt) -- (195.348pt, -221.992pt) -- (195.243pt, -222.121pt) -- 
  (195.114pt, -222.222pt) -- (194.969pt, -222.293pt) -- (194.812pt, -222.332pt) -- (194.648pt, -222.338pt) -- 
  (194.484pt, -222.307pt) -- (194.325pt, -222.238pt) -- (191.713pt, -220.725pt) -- (191.573pt, -220.622pt) -- 
  (191.464pt, -220.496pt) -- (191.387pt, -220.352pt) -- (191.342pt, -220.197pt) -- (191.331pt, -220.036pt) -- 
  (191.354pt, -219.874pt) -- (191.412pt, -219.719pt) -- (191.506pt, -219.575pt) -- (197.137pt, -212.825pt) -- 
  (197.364pt, -212.636pt) -- (197.615pt, -212.553pt) -- (197.87pt, -212.563pt) -- (198.107pt, -212.654pt) -- 
  (198.305pt, -212.813pt) -- (198.441pt, -213.028pt) -- (198.495pt, -213.286pt) -- (198.444pt, -213.575pt) -- 
  (198.444pt, -213.575pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Storage" & "}") scaled 1, (200pt, -243pt), 0, (0.2,0.2,0.2));
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
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Server" & "}") scaled 1, (75pt, -106pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (25pt, -25pt)
  .. controls (25pt, -25pt) and (250pt, -25pt) .. (250pt, -25pt)
  .. controls (250pt, -25pt) and (250pt, -274pt) .. (250pt, -274pt)
  .. controls (250pt, -274pt) and (25pt, -274pt) .. (25pt, -274pt)
  .. controls (25pt, -274pt) and (25pt, -25pt) .. (25pt, -25pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.25pt dashed dashpattern(on 5pt off 5pt); endgroup;
fill pmhbox(25.625pt, 25.625pt, 18.75pt, 18.75pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (40.859pt, -36.758pt)
  .. controls (40.859pt, -37.405pt) and (40.334pt, -37.93pt) .. (39.688pt, -37.93pt)
  .. controls (39.688pt, -37.93pt) and (30.313pt, -37.93pt) .. (30.313pt, -37.93pt)
  .. controls (29.666pt, -37.93pt) and (29.141pt, -37.405pt) .. (29.141pt, -36.758pt)
  .. controls (29.141pt, -36.32pt) and (29.382pt, -35.935pt) .. (29.741pt, -35.736pt)
  .. controls (29.731pt, -35.687pt) and (29.727pt, -35.637pt) .. (29.727pt, -35.586pt)
  .. controls (29.727pt, -34.977pt) and (30.308pt, -34.475pt) .. (31.051pt, -34.421pt)
  .. controls (31.438pt, -33.364pt) and (32.537pt, -32.602pt) .. (33.828pt, -32.602pt)
  .. controls (34.03pt, -32.602pt) and (34.224pt, -32.621pt) .. (34.414pt, -32.656pt)
  .. controls (34.904pt, -32.288pt) and (35.513pt, -32.07pt) .. (36.172pt, -32.07pt)
  .. controls (37.602pt, -32.07pt) and (38.795pt, -33.097pt) .. (39.05pt, -34.454pt)
  .. controls (39.552pt, -34.585pt) and (39.922pt, -35.042pt) .. (39.922pt, -35.586pt)
  .. controls (39.922pt, -35.593pt) and (39.922pt, -35.602pt) .. (39.92pt, -35.609pt)
  .. controls (40.456pt, -35.717pt) and (40.859pt, -36.191pt) .. (40.859pt, -36.758pt)
  .. controls (40.859pt, -36.758pt) and (40.859pt, -36.758pt) .. (40.859pt, -36.758pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "API" & "}") scaled 1, (56pt, -35.375pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
