\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -224.1pt; pmxx2 := 427.5pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (45pt, -67.5pt)
  .. controls (45pt, -67.5pt) and (45pt, -106.65pt) .. (45pt, -106.65pt)
  .. controls (45pt, -106.65pt) and (45pt, -145.8pt) .. (45pt, -145.8pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (360pt, -45pt)
  .. controls (360pt, -45pt) and (326.25pt, -45pt) .. (326.25pt, -45pt)
  .. controls (326.25pt, -45pt) and (292.5pt, -45pt) .. (292.5pt, -45pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
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
fill pmhbox(22.5pt, 145.8pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(32.344pt, 155.644pt, 25.313pt, 25.313pt, 1.125pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (32.344pt, -164.081pt) -- (57.656pt, -164.081pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (32.344pt, -172.519pt) -- (57.656pt, -172.519pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
fill pmhbox(47.109pt, 159.3pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (40.781pt, -159.863pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (40.781pt, -159.863pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (37.969pt, -159.863pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (37.969pt, -159.863pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (35.156pt, -159.863pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (35.156pt, -159.863pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(47.109pt, 167.738pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (40.781pt, -168.3pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (40.781pt, -168.3pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (37.969pt, -168.3pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (37.969pt, -168.3pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (35.156pt, -168.3pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (35.156pt, -168.3pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill pmhbox(47.109pt, 176.175pt, 7.031pt, 1.125pt, 0.563pt) withcolor (1,1,1);
fill fullcircle scaled 0.844pt shifted (40.781pt, -176.738pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (40.781pt, -176.738pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (37.969pt, -176.738pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (37.969pt, -176.738pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
fill fullcircle scaled 0.844pt shifted (35.156pt, -176.738pt) withcolor (1,1,1);
draw fullcircle scaled 0.844pt shifted (35.156pt, -176.738pt) withcolor (1,1,1) withpen pencircle scaled 0.563pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B" & "}") scaled 1, (45pt, -196.2pt), 0, (0.2,0.2,0.2));
fill pmhbox(135pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (171.563pt, -49.219pt)
  .. controls (171.563pt, -50.771pt) and (170.302pt, -52.031pt) .. (168.75pt, -52.031pt)
  .. controls (168.75pt, -52.031pt) and (146.25pt, -52.031pt) .. (146.25pt, -52.031pt)
  .. controls (144.698pt, -52.031pt) and (143.438pt, -50.771pt) .. (143.438pt, -49.219pt)
  .. controls (143.438pt, -48.167pt) and (144.017pt, -47.244pt) .. (144.877pt, -46.766pt)
  .. controls (144.855pt, -46.648pt) and (144.844pt, -46.53pt) .. (144.844pt, -46.406pt)
  .. controls (144.844pt, -44.944pt) and (146.239pt, -43.74pt) .. (148.022pt, -43.611pt)
  .. controls (148.95pt, -41.074pt) and (151.588pt, -39.246pt) .. (154.688pt, -39.246pt)
  .. controls (155.171pt, -39.246pt) and (155.638pt, -39.291pt) .. (156.094pt, -39.375pt)
  .. controls (157.269pt, -38.492pt) and (158.732pt, -37.969pt) .. (160.313pt, -37.969pt)
  .. controls (163.744pt, -37.969pt) and (166.607pt, -40.432pt) .. (167.22pt, -43.689pt)
  .. controls (168.424pt, -44.004pt) and (169.313pt, -45.101pt) .. (169.313pt, -46.406pt)
  .. controls (169.313pt, -46.423pt) and (169.313pt, -46.446pt) .. (169.307pt, -46.463pt)
  .. controls (170.595pt, -46.721pt) and (171.563pt, -47.858pt) .. (171.563pt, -49.219pt)
  .. controls (171.563pt, -49.219pt) and (171.563pt, -49.219pt) .. (171.563pt, -49.219pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Alone" & "}") scaled 1, (157.5pt, -72.9pt), 0, (0.2,0.2,0.2));
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
fill pmhbox(247.5pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(258.75pt, 30.938pt, 22.5pt, 28.125pt, 0.563pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (261pt, -33.283pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (279pt, -33.283pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (261pt, -56.717pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw fullcircle scaled 0.9pt shifted (279pt, -56.717pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
begingroup interim linecap := rounded; draw (277.875pt, -41.484pt)
  .. controls (277.875pt, -46.014pt) and (274.349pt, -49.686pt) .. (270pt, -49.686pt)
  .. controls (265.651pt, -49.686pt) and (262.125pt, -46.014pt) .. (262.125pt, -41.484pt)
  .. controls (262.125pt, -36.955pt) and (265.651pt, -33.283pt) .. (270pt, -33.283pt)
  .. controls (274.349pt, -33.283pt) and (277.875pt, -36.955pt) .. (277.875pt, -41.484pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
fill fullcircle scaled 4.59pt shifted (270pt, -41.484pt) withcolor (1,1,1);
fill (268.599pt, -46.417pt) -- (265.882pt, -53.854pt) -- (265.813pt, -53.993pt) -- (265.718pt, -54.109pt) -- 
  (265.603pt, -54.199pt) -- (265.472pt, -54.264pt) -- (265.33pt, -54.299pt) -- (265.183pt, -54.304pt) -- 
  (265.036pt, -54.276pt) -- (264.892pt, -54.214pt) -- (262.541pt, -52.853pt) -- (262.416pt, -52.76pt) -- 
  (262.318pt, -52.646pt) -- (262.248pt, -52.517pt) -- (262.208pt, -52.377pt) -- (262.198pt, -52.232pt) -- 
  (262.219pt, -52.087pt) -- (262.271pt, -51.947pt) -- (262.356pt, -51.818pt) -- (267.424pt, -45.743pt) -- 
  (267.627pt, -45.572pt) -- (267.853pt, -45.498pt) -- (268.083pt, -45.507pt) -- (268.296pt, -45.589pt) -- 
  (268.474pt, -45.732pt) -- (268.597pt, -45.925pt) -- (268.645pt, -46.158pt) -- (268.599pt, -46.417pt) -- 
  (268.599pt, -46.417pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "E" & "}") scaled 1, (270pt, -72.9pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
