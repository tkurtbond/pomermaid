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
begingroup interim linecap := rounded; draw (180pt, -45pt)
  .. controls (180pt, -45pt) and (213.75pt, -45pt) .. (213.75pt, -45pt)
  .. controls (213.75pt, -45pt) and (247.5pt, -45pt) .. (247.5pt, -45pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (292.5pt, -45pt)
  .. controls (292.5pt, -45pt) and (326.25pt, -45pt) .. (326.25pt, -45pt)
  .. controls (326.25pt, -45pt) and (360pt, -45pt) .. (360pt, -45pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (382.5pt, -67.5pt)
  .. controls (382.5pt, -67.5pt) and (382.5pt, -106.65pt) .. (382.5pt, -106.65pt)
  .. controls (382.5pt, -106.65pt) and (382.5pt, -145.8pt) .. (382.5pt, -145.8pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (360pt, -168.3pt)
  .. controls (360pt, -168.3pt) and (326.25pt, -168.3pt) .. (326.25pt, -168.3pt)
  .. controls (326.25pt, -168.3pt) and (292.5pt, -168.3pt) .. (292.5pt, -168.3pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (247.5pt, -168.3pt)
  .. controls (247.5pt, -168.3pt) and (213.75pt, -168.3pt) .. (213.75pt, -168.3pt)
  .. controls (213.75pt, -168.3pt) and (180pt, -168.3pt) .. (180pt, -168.3pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (135pt, -168.3pt)
  .. controls (135pt, -168.3pt) and (101.25pt, -168.3pt) .. (101.25pt, -168.3pt)
  .. controls (101.25pt, -168.3pt) and (67.5pt, -168.3pt) .. (67.5pt, -168.3pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (45pt, -190.8pt)
  .. controls (45pt, -190.8pt) and (45pt, -229.95pt) .. (45pt, -229.95pt)
  .. controls (45pt, -229.95pt) and (45pt, -269.1pt) .. (45pt, -269.1pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (67.5pt, -291.6pt)
  .. controls (67.5pt, -291.6pt) and (101.25pt, -291.6pt) .. (101.25pt, -291.6pt)
  .. controls (101.25pt, -291.6pt) and (135pt, -291.6pt) .. (135pt, -291.6pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
begingroup interim linecap := rounded; draw (180pt, -291.6pt)
  .. controls (180pt, -291.6pt) and (213.75pt, -291.6pt) .. (213.75pt, -291.6pt)
  .. controls (213.75pt, -291.6pt) and (247.5pt, -291.6pt) .. (247.5pt, -291.6pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.688pt; endgroup;
fill pmhbox(22.5pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (33.75pt, -55.046pt)
  .. controls (33.75pt, -57.262pt) and (38.784pt, -59.063pt) .. (45pt, -59.063pt)
  .. controls (51.216pt, -59.063pt) and (56.25pt, -57.262pt) .. (56.25pt, -55.046pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
begingroup interim linecap := rounded; draw (33.75pt, -48.35pt)
  .. controls (33.75pt, -50.566pt) and (38.784pt, -52.366pt) .. (45pt, -52.366pt)
  .. controls (51.216pt, -52.366pt) and (56.25pt, -50.566pt) .. (56.25pt, -48.35pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
begingroup interim linecap := rounded; draw (33.75pt, -41.653pt)
  .. controls (33.75pt, -43.869pt) and (38.784pt, -45.669pt) .. (45pt, -45.669pt)
  .. controls (51.216pt, -45.669pt) and (56.25pt, -43.869pt) .. (56.25pt, -41.653pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
begingroup interim linecap := rounded; draw (56.25pt, -34.954pt)
  .. controls (56.25pt, -37.172pt) and (51.213pt, -38.97pt) .. (45pt, -38.97pt)
  .. controls (38.787pt, -38.97pt) and (33.75pt, -37.172pt) .. (33.75pt, -34.954pt)
  .. controls (33.75pt, -32.736pt) and (38.787pt, -30.938pt) .. (45pt, -30.938pt)
  .. controls (51.213pt, -30.938pt) and (56.25pt, -32.736pt) .. (56.25pt, -34.954pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
draw (33.75pt, -55.046pt) -- (33.75pt, -34.954pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (56.25pt, -55.046pt) -- (56.25pt, -34.954pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "database" & "}") scaled 1, (45pt, -72.9pt), 0, (0.2,0.2,0.2));
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
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "server" & "}") scaled 1, (157.5pt, -72.9pt), 0, (0.2,0.2,0.2));
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
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "disk" & "}") scaled 1, (270pt, -72.9pt), 0, (0.2,0.2,0.2));
fill pmhbox(360pt, 22.5pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw fullcircle scaled 25.313pt shifted (382.5pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (382.5pt, -32.344pt) -- (382.5pt, -57.656pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (369.844pt, -45pt) -- (395.156pt, -45pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (371.109pt, -39.431pt) -- (393.891pt, -39.431pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
draw (371.109pt, -50.569pt) -- (393.891pt, -50.569pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt;
begingroup interim linecap := rounded; draw (382.494pt, -32.349pt)
  .. controls (373.899pt, -38.593pt) and (373.899pt, -51.407pt) .. (382.494pt, -57.651pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
begingroup interim linecap := rounded; draw (382.506pt, -32.349pt)
  .. controls (391.101pt, -38.593pt) and (391.101pt, -51.407pt) .. (382.506pt, -57.651pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "internet" & "}") scaled 1, (382.5pt, -72.9pt), 0, (0.2,0.2,0.2));
fill pmhbox(360pt, 145.8pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (396.563pt, -172.519pt)
  .. controls (396.563pt, -174.071pt) and (395.302pt, -175.331pt) .. (393.75pt, -175.331pt)
  .. controls (393.75pt, -175.331pt) and (371.25pt, -175.331pt) .. (371.25pt, -175.331pt)
  .. controls (369.698pt, -175.331pt) and (368.438pt, -174.071pt) .. (368.438pt, -172.519pt)
  .. controls (368.438pt, -171.467pt) and (369.017pt, -170.544pt) .. (369.877pt, -170.066pt)
  .. controls (369.855pt, -169.948pt) and (369.844pt, -169.83pt) .. (369.844pt, -169.706pt)
  .. controls (369.844pt, -168.244pt) and (371.239pt, -167.04pt) .. (373.022pt, -166.911pt)
  .. controls (373.95pt, -164.374pt) and (376.588pt, -162.546pt) .. (379.688pt, -162.546pt)
  .. controls (380.171pt, -162.546pt) and (380.638pt, -162.591pt) .. (381.094pt, -162.675pt)
  .. controls (382.269pt, -161.792pt) and (383.732pt, -161.269pt) .. (385.313pt, -161.269pt)
  .. controls (388.744pt, -161.269pt) and (391.607pt, -163.733pt) .. (392.22pt, -166.989pt)
  .. controls (393.424pt, -167.304pt) and (394.313pt, -168.401pt) .. (394.313pt, -169.706pt)
  .. controls (394.313pt, -169.723pt) and (394.313pt, -169.746pt) .. (394.307pt, -169.762pt)
  .. controls (395.595pt, -170.021pt) and (396.563pt, -171.157pt) .. (396.563pt, -172.519pt)
  .. controls (396.563pt, -172.519pt) and (396.563pt, -172.519pt) .. (396.563pt, -172.519pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "cloud" & "}") scaled 1, (382.5pt, -196.2pt), 0, (0.2,0.2,0.2));
fill pmhbox(247.5pt, 145.8pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "blank" & "}") scaled 1, (270pt, -196.2pt), 0, (0.2,0.2,0.2));
fill pmhbox(135pt, 145.8pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "?" & "}") scaled 4.2344, (157.5pt, -169.425pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "unknown" & "}") scaled 1, (157.5pt, -196.2pt), 0, (0.2,0.2,0.2));
fill pmhbox(22.5pt, 145.8pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (59.063pt, -172.519pt)
  .. controls (59.063pt, -174.071pt) and (57.802pt, -175.331pt) .. (56.25pt, -175.331pt)
  .. controls (56.25pt, -175.331pt) and (33.75pt, -175.331pt) .. (33.75pt, -175.331pt)
  .. controls (32.198pt, -175.331pt) and (30.938pt, -174.071pt) .. (30.938pt, -172.519pt)
  .. controls (30.938pt, -171.467pt) and (31.517pt, -170.544pt) .. (32.377pt, -170.066pt)
  .. controls (32.355pt, -169.948pt) and (32.344pt, -169.83pt) .. (32.344pt, -169.706pt)
  .. controls (32.344pt, -168.244pt) and (33.739pt, -167.04pt) .. (35.522pt, -166.911pt)
  .. controls (36.45pt, -164.374pt) and (39.088pt, -162.546pt) .. (42.188pt, -162.546pt)
  .. controls (42.671pt, -162.546pt) and (43.138pt, -162.591pt) .. (43.594pt, -162.675pt)
  .. controls (44.769pt, -161.792pt) and (46.232pt, -161.269pt) .. (47.813pt, -161.269pt)
  .. controls (51.244pt, -161.269pt) and (54.107pt, -163.733pt) .. (54.72pt, -166.989pt)
  .. controls (55.924pt, -167.304pt) and (56.813pt, -168.401pt) .. (56.813pt, -169.706pt)
  .. controls (56.813pt, -169.723pt) and (56.813pt, -169.746pt) .. (56.807pt, -169.762pt)
  .. controls (58.095pt, -170.021pt) and (59.063pt, -171.157pt) .. (59.063pt, -172.519pt)
  .. controls (59.063pt, -172.519pt) and (59.063pt, -172.519pt) .. (59.063pt, -172.519pt) withcolor (1,1,1) withpen pencircle scaled 1.125pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "prefixed" & "}") scaled 1, (45pt, -196.2pt), 0, (0.2,0.2,0.2));
fill pmhbox(22.5pt, 269.1pt, 45pt, 45pt, 0pt) withcolor (0.0314,0.4941,0.749);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Text in\\place of an\\icon,\\rather" & "}") scaled 1, (45pt, -291.6pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "iconText" & "}") scaled 1, (45pt, -319.5pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (135pt, -314.1pt)
  .. controls (135pt, -314.1pt) and (135pt, -271.912pt) .. (135pt, -271.912pt)
  .. controls (135pt, -270.037pt) and (135.938pt, -269.1pt) .. (137.813pt, -269.1pt)
  .. controls (137.813pt, -269.1pt) and (177.188pt, -269.1pt) .. (177.188pt, -269.1pt)
  .. controls (179.063pt, -269.1pt) and (180pt, -270.037pt) .. (180pt, -271.912pt)
  .. controls (180pt, -271.912pt) and (180pt, -314.1pt) .. (180pt, -314.1pt)
  .. controls (180pt, -314.1pt) and (135pt, -314.1pt) .. (135pt, -314.1pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.125pt dashed dashpattern(on 4.5pt off 4.5pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "none" & "}") scaled 1, (157.5pt, -319.5pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (247.5pt, -314.1pt)
  .. controls (247.5pt, -314.1pt) and (247.5pt, -271.912pt) .. (247.5pt, -271.912pt)
  .. controls (247.5pt, -270.037pt) and (248.438pt, -269.1pt) .. (250.313pt, -269.1pt)
  .. controls (250.313pt, -269.1pt) and (289.688pt, -269.1pt) .. (289.688pt, -269.1pt)
  .. controls (291.563pt, -269.1pt) and (292.5pt, -270.037pt) .. (292.5pt, -271.912pt)
  .. controls (292.5pt, -271.912pt) and (292.5pt, -314.1pt) .. (292.5pt, -314.1pt)
  .. controls (292.5pt, -314.1pt) and (247.5pt, -314.1pt) .. (247.5pt, -314.1pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.125pt dashed dashpattern(on 4.5pt off 4.5pt); endgroup;
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
