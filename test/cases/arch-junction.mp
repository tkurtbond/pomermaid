\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -386pt; pmxx2 := 350pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (75pt, -187pt)
  .. controls (75pt, -187pt) and (125pt, -187pt) .. (125pt, -187pt)
  .. controls (125pt, -187pt) and (175pt, -187pt) .. (175pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (175pt, -75pt)
  .. controls (175pt, -75pt) and (175pt, -131pt) .. (175pt, -131pt)
  .. controls (175pt, -131pt) and (175pt, -187pt) .. (175pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (175pt, -299pt)
  .. controls (175pt, -299pt) and (175pt, -243pt) .. (175pt, -243pt)
  .. controls (175pt, -243pt) and (175pt, -187pt) .. (175pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (175pt, -187pt)
  .. controls (175pt, -187pt) and (237.5pt, -187pt) .. (237.5pt, -187pt)
  .. controls (237.5pt, -187pt) and (300pt, -187pt) .. (300pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (300pt, -75pt)
  .. controls (300pt, -75pt) and (300pt, -131pt) .. (300pt, -131pt)
  .. controls (300pt, -131pt) and (300pt, -187pt) .. (300pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
begingroup interim linecap := rounded; draw (300pt, -299pt)
  .. controls (300pt, -299pt) and (300pt, -243pt) .. (300pt, -243pt)
  .. controls (300pt, -243pt) and (300pt, -187pt) .. (300pt, -187pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
fill pmhbox(25pt, 162pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(37.5pt, 171.375pt, 25pt, 31.25pt, 0.625pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (40pt, -173.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (60pt, -173.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (40pt, -200.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (60pt, -200.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (58.75pt, -183.094pt)
  .. controls (58.75pt, -188.126pt) and (54.833pt, -192.206pt) .. (50pt, -192.206pt)
  .. controls (45.167pt, -192.206pt) and (41.25pt, -188.126pt) .. (41.25pt, -183.094pt)
  .. controls (41.25pt, -178.061pt) and (45.167pt, -173.981pt) .. (50pt, -173.981pt)
  .. controls (54.833pt, -173.981pt) and (58.75pt, -178.061pt) .. (58.75pt, -183.094pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
fill fullcircle scaled 5.1pt shifted (50pt, -183.094pt) withcolor (1,1,1);
fill (48.444pt, -188.575pt) -- (45.425pt, -196.838pt) -- (45.348pt, -196.992pt) -- (45.243pt, -197.121pt) -- 
  (45.114pt, -197.222pt) -- (44.969pt, -197.293pt) -- (44.812pt, -197.332pt) -- (44.648pt, -197.338pt) -- 
  (44.484pt, -197.307pt) -- (44.325pt, -197.238pt) -- (41.713pt, -195.725pt) -- (41.573pt, -195.622pt) -- 
  (41.464pt, -195.496pt) -- (41.387pt, -195.352pt) -- (41.342pt, -195.197pt) -- (41.331pt, -195.036pt) -- 
  (41.354pt, -194.874pt) -- (41.412pt, -194.719pt) -- (41.506pt, -194.575pt) -- (47.137pt, -187.825pt) -- 
  (47.364pt, -187.636pt) -- (47.615pt, -187.553pt) -- (47.87pt, -187.563pt) -- (48.107pt, -187.654pt) -- 
  (48.305pt, -187.813pt) -- (48.441pt, -188.028pt) -- (48.495pt, -188.286pt) -- (48.444pt, -188.575pt) -- 
  (48.444pt, -188.575pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Disk" & "}") scaled 1, (50pt, -218pt), 0, (0.2,0.2,0.2));
fill pmhbox(150pt, 25pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(162.5pt, 34.375pt, 25pt, 31.25pt, 0.625pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (165pt, -36.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (185pt, -36.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (165pt, -63.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (185pt, -63.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (183.75pt, -46.094pt)
  .. controls (183.75pt, -51.126pt) and (179.833pt, -55.206pt) .. (175pt, -55.206pt)
  .. controls (170.167pt, -55.206pt) and (166.25pt, -51.126pt) .. (166.25pt, -46.094pt)
  .. controls (166.25pt, -41.061pt) and (170.167pt, -36.981pt) .. (175pt, -36.981pt)
  .. controls (179.833pt, -36.981pt) and (183.75pt, -41.061pt) .. (183.75pt, -46.094pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
fill fullcircle scaled 5.1pt shifted (175pt, -46.094pt) withcolor (1,1,1);
fill (173.444pt, -51.575pt) -- (170.425pt, -59.838pt) -- (170.348pt, -59.992pt) -- (170.243pt, -60.121pt) -- 
  (170.114pt, -60.222pt) -- (169.969pt, -60.293pt) -- (169.812pt, -60.332pt) -- (169.648pt, -60.338pt) -- 
  (169.484pt, -60.307pt) -- (169.325pt, -60.238pt) -- (166.713pt, -58.725pt) -- (166.573pt, -58.622pt) -- 
  (166.464pt, -58.496pt) -- (166.387pt, -58.352pt) -- (166.342pt, -58.197pt) -- (166.331pt, -58.036pt) -- 
  (166.354pt, -57.874pt) -- (166.412pt, -57.719pt) -- (166.506pt, -57.575pt) -- (172.137pt, -50.825pt) -- 
  (172.364pt, -50.636pt) -- (172.615pt, -50.553pt) -- (172.87pt, -50.563pt) -- (173.107pt, -50.654pt) -- 
  (173.305pt, -50.813pt) -- (173.441pt, -51.028pt) -- (173.495pt, -51.286pt) -- (173.444pt, -51.575pt) -- 
  (173.444pt, -51.575pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Disk" & "}") scaled 1, (175pt, -81pt), 0, (0.2,0.2,0.2));
fill pmhbox(150pt, 299pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(162.5pt, 308.375pt, 25pt, 31.25pt, 0.625pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (165pt, -310.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (185pt, -310.981pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (165pt, -337.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw fullcircle scaled 1pt shifted (185pt, -337.019pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (183.75pt, -320.094pt)
  .. controls (183.75pt, -325.126pt) and (179.833pt, -329.206pt) .. (175pt, -329.206pt)
  .. controls (170.167pt, -329.206pt) and (166.25pt, -325.126pt) .. (166.25pt, -320.094pt)
  .. controls (166.25pt, -315.061pt) and (170.167pt, -310.981pt) .. (175pt, -310.981pt)
  .. controls (179.833pt, -310.981pt) and (183.75pt, -315.061pt) .. (183.75pt, -320.094pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
fill fullcircle scaled 5.1pt shifted (175pt, -320.094pt) withcolor (1,1,1);
fill (173.444pt, -325.575pt) -- (170.425pt, -333.838pt) -- (170.348pt, -333.992pt) -- (170.243pt, -334.121pt) -- 
  (170.114pt, -334.222pt) -- (169.969pt, -334.293pt) -- (169.812pt, -334.332pt) -- (169.648pt, -334.338pt) -- 
  (169.484pt, -334.307pt) -- (169.325pt, -334.238pt) -- (166.713pt, -332.725pt) -- (166.573pt, -332.622pt) -- 
  (166.464pt, -332.496pt) -- (166.387pt, -332.352pt) -- (166.342pt, -332.197pt) -- (166.331pt, -332.036pt) -- 
  (166.354pt, -331.874pt) -- (166.412pt, -331.719pt) -- (166.506pt, -331.575pt) -- (172.137pt, -324.825pt) -- 
  (172.364pt, -324.636pt) -- (172.615pt, -324.553pt) -- (172.87pt, -324.563pt) -- (173.107pt, -324.654pt) -- 
  (173.305pt, -324.813pt) -- (173.441pt, -325.028pt) -- (173.495pt, -325.286pt) -- (173.444pt, -325.575pt) -- 
  (173.444pt, -325.575pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Disk" & "}") scaled 1, (175pt, -355pt), 0, (0.2,0.2,0.2));
fill pmhbox(275pt, 25pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw fullcircle scaled 28.125pt shifted (300pt, -50pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (300pt, -35.938pt) -- (300pt, -64.063pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (285.938pt, -50pt) -- (314.063pt, -50pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (287.344pt, -43.813pt) -- (312.656pt, -43.813pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (287.344pt, -56.188pt) -- (312.656pt, -56.188pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (299.994pt, -35.944pt)
  .. controls (290.444pt, -42.881pt) and (290.444pt, -57.119pt) .. (299.994pt, -64.056pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (300.006pt, -35.944pt)
  .. controls (309.556pt, -42.881pt) and (309.556pt, -57.119pt) .. (300.006pt, -64.056pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Gateway" & "}") scaled 1, (300pt, -81pt), 0, (0.2,0.2,0.2));
fill pmhbox(275pt, 299pt, 50pt, 50pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw fullcircle scaled 28.125pt shifted (300pt, -324pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (300pt, -309.938pt) -- (300pt, -338.063pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (285.938pt, -324pt) -- (314.063pt, -324pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (287.344pt, -317.813pt) -- (312.656pt, -317.813pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
draw (287.344pt, -330.188pt) -- (312.656pt, -330.188pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt;
begingroup interim linecap := rounded; draw (299.994pt, -309.944pt)
  .. controls (290.444pt, -316.881pt) and (290.444pt, -331.119pt) .. (299.994pt, -338.056pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
begingroup interim linecap := rounded; draw (300.006pt, -309.944pt)
  .. controls (309.556pt, -316.881pt) and (309.556pt, -331.119pt) .. (300.006pt, -338.056pt) withcolor (1,1,1) withpen pencircle scaled 1.25pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Gateway" & "}") scaled 1, (300pt, -355pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
