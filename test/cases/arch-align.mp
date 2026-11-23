\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -347.4pt; pmxx2 := 427.5pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (67.5pt, -45pt)
  .. controls (67.5pt, -45pt) and (101.25pt, -45pt) .. (101.25pt, -45pt)
  .. controls (101.25pt, -45pt) and (135pt, -45pt) .. (135pt, -45pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
fill pmhbox(22.5pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(32.344pt, 32.344pt, 25.313pt, 25.313pt, 1.125pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (32.344pt, -40.781pt) -- (57.656pt, -40.781pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (32.344pt, -49.219pt) -- (57.656pt, -49.219pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
fill pmhbox(47.109pt, 36pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (40.781pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (40.781pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (37.969pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (37.969pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (35.156pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (35.156pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(47.109pt, 44.438pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (40.781pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (40.781pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (37.969pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (37.969pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (35.156pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (35.156pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(47.109pt, 52.875pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (40.781pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (40.781pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (37.969pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (37.969pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (35.156pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (35.156pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A" & "}") scaled 1, (45pt, -72.9pt), 0, (0.2,0.2,0.2));
fill pmhbox(135pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(144.844pt, 32.344pt, 25.313pt, 25.313pt, 1.125pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (144.844pt, -40.781pt) -- (170.156pt, -40.781pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (144.844pt, -49.219pt) -- (170.156pt, -49.219pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
fill pmhbox(159.609pt, 36pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (153.281pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (153.281pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (150.469pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (150.469pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (147.656pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (147.656pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(159.609pt, 44.438pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (153.281pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (153.281pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (150.469pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (150.469pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (147.656pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (147.656pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(159.609pt, 52.875pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (153.281pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (153.281pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (150.469pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (150.469pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (147.656pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (147.656pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B" & "}") scaled 1, (157.5pt, -72.9pt), 0, (0.2,0.2,0.2));
fill pmhbox(247.5pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(257.344pt, 32.344pt, 25.313pt, 25.313pt, 1.125pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (257.344pt, -40.781pt) -- (282.656pt, -40.781pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (257.344pt, -49.219pt) -- (282.656pt, -49.219pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
fill pmhbox(272.109pt, 36pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (265.781pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (265.781pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (262.969pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (262.969pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (260.156pt, -36.563pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (260.156pt, -36.563pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(272.109pt, 44.438pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (265.781pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (265.781pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (262.969pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (262.969pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (260.156pt, -45pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (260.156pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(272.109pt, 52.875pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (265.781pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (265.781pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (262.969pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (262.969pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (260.156pt, -53.438pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (260.156pt, -53.438pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "C" & "}") scaled 1, (270pt, -72.9pt), 0, (0.2,0.2,0.2));
fill pmhbox(360pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(371.25pt, 30.938pt, 22.5pt, 28.125pt, 0.563pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (373.5pt, -33.283pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (391.5pt, -33.283pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (373.5pt, -56.717pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (391.5pt, -56.717pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
begingroup interim linecap := rounded; draw (390.375pt, -41.484pt)
  .. controls (390.375pt, -46.014pt) and (386.849pt, -49.686pt) .. (382.5pt, -49.686pt)
  .. controls (378.151pt, -49.686pt) and (374.625pt, -46.014pt) .. (374.625pt, -41.484pt)
  .. controls (374.625pt, -36.955pt) and (378.151pt, -33.283pt) .. (382.5pt, -33.283pt)
  .. controls (386.849pt, -33.283pt) and (390.375pt, -36.955pt) .. (390.375pt, -41.484pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
fill fullcircle scaled 4.59pt shifted (382.5pt, -41.484pt) withcolor (1,1,1);
fill (381.099pt, -46.417pt) -- (378.382pt, -53.854pt) -- (378.313pt, -53.993pt) -- (378.218pt, -54.109pt) -- 
  (378.103pt, -54.199pt) -- (377.972pt, -54.264pt) -- (377.83pt, -54.299pt) -- (377.683pt, -54.304pt) -- 
  (377.536pt, -54.276pt) -- (377.392pt, -54.214pt) -- (375.041pt, -52.853pt) -- (374.916pt, -52.76pt) -- 
  (374.818pt, -52.646pt) -- (374.748pt, -52.517pt) -- (374.708pt, -52.377pt) -- (374.698pt, -52.232pt) -- 
  (374.719pt, -52.087pt) -- (374.771pt, -51.947pt) -- (374.856pt, -51.818pt) -- (379.924pt, -45.743pt) -- 
  (380.127pt, -45.572pt) -- (380.353pt, -45.498pt) -- (380.583pt, -45.507pt) -- (380.796pt, -45.589pt) -- 
  (380.974pt, -45.732pt) -- (381.097pt, -45.925pt) -- (381.145pt, -46.158pt) -- (381.099pt, -46.417pt) -- 
  (381.099pt, -46.417pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "D" & "}") scaled 1, (382.5pt, -72.9pt), 0, (0.2,0.2,0.2));
fill pmhbox(360pt, 145.8pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(371.25pt, 154.238pt, 22.5pt, 28.125pt, 0.563pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (373.5pt, -156.583pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (391.5pt, -156.583pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (373.5pt, -180.017pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (391.5pt, -180.017pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
begingroup interim linecap := rounded; draw (390.375pt, -164.784pt)
  .. controls (390.375pt, -169.314pt) and (386.849pt, -172.986pt) .. (382.5pt, -172.986pt)
  .. controls (378.151pt, -172.986pt) and (374.625pt, -169.314pt) .. (374.625pt, -164.784pt)
  .. controls (374.625pt, -160.255pt) and (378.151pt, -156.583pt) .. (382.5pt, -156.583pt)
  .. controls (386.849pt, -156.583pt) and (390.375pt, -160.255pt) .. (390.375pt, -164.784pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
fill fullcircle scaled 4.59pt shifted (382.5pt, -164.784pt) withcolor (1,1,1);
fill (381.099pt, -169.718pt) -- (378.382pt, -177.154pt) -- (378.313pt, -177.293pt) -- (378.218pt, -177.409pt) -- 
  (378.103pt, -177.5pt) -- (377.972pt, -177.564pt) -- (377.83pt, -177.599pt) -- (377.683pt, -177.604pt) -- 
  (377.536pt, -177.576pt) -- (377.392pt, -177.514pt) -- (375.041pt, -176.152pt) -- (374.916pt, -176.06pt) -- 
  (374.818pt, -175.947pt) -- (374.748pt, -175.817pt) -- (374.708pt, -175.677pt) -- (374.698pt, -175.532pt) -- 
  (374.719pt, -175.387pt) -- (374.771pt, -175.247pt) -- (374.856pt, -175.118pt) -- (379.924pt, -169.042pt) -- 
  (380.127pt, -168.872pt) -- (380.353pt, -168.798pt) -- (380.583pt, -168.807pt) -- (380.796pt, -168.889pt) -- 
  (380.974pt, -169.032pt) -- (381.097pt, -169.225pt) -- (381.145pt, -169.458pt) -- (381.099pt, -169.718pt) -- 
  (381.099pt, -169.718pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "E" & "}") scaled 1, (382.5pt, -196.2pt), 0, (0.2,0.2,0.2));
fill pmhbox(360pt, 269.1pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (396.563pt, -295.819pt)
  .. controls (396.563pt, -297.371pt) and (395.302pt, -298.631pt) .. (393.75pt, -298.631pt)
  .. controls (393.75pt, -298.631pt) and (371.25pt, -298.631pt) .. (371.25pt, -298.631pt)
  .. controls (369.698pt, -298.631pt) and (368.438pt, -297.371pt) .. (368.438pt, -295.819pt)
  .. controls (368.438pt, -294.767pt) and (369.017pt, -293.844pt) .. (369.877pt, -293.366pt)
  .. controls (369.855pt, -293.248pt) and (369.844pt, -293.13pt) .. (369.844pt, -293.006pt)
  .. controls (369.844pt, -291.544pt) and (371.239pt, -290.34pt) .. (373.022pt, -290.211pt)
  .. controls (373.95pt, -287.674pt) and (376.588pt, -285.846pt) .. (379.688pt, -285.846pt)
  .. controls (380.171pt, -285.846pt) and (380.638pt, -285.891pt) .. (381.094pt, -285.975pt)
  .. controls (382.269pt, -285.092pt) and (383.732pt, -284.569pt) .. (385.313pt, -284.569pt)
  .. controls (388.744pt, -284.569pt) and (391.607pt, -287.032pt) .. (392.22pt, -290.289pt)
  .. controls (393.424pt, -290.604pt) and (394.313pt, -291.701pt) .. (394.313pt, -293.006pt)
  .. controls (394.313pt, -293.023pt) and (394.313pt, -293.046pt) .. (394.307pt, -293.063pt)
  .. controls (395.595pt, -293.321pt) and (396.563pt, -294.458pt) .. (396.563pt, -295.819pt)
  .. controls (396.563pt, -295.819pt) and (396.563pt, -295.819pt) .. (396.563pt, -295.819pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "F" & "}") scaled 1, (382.5pt, -319.5pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
