\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -200.012pt; pmxx2 := 427.828pt; pmxx3 := 0;
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
fill pmhbox(43.125pt, 76.172pt, 62.1pt, 20.815pt, 9.367pt) withcolor (0.0314,0.2588,0.4824);
draw pmhbox(43.125pt, 76.172pt, 62.1pt, 20.815pt, 9.367pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.575pt;
fill fullcircle scaled 28.566pt shifted (74.175pt, -65.745pt) withcolor (0.0314,0.2588,0.4824);
draw fullcircle scaled 28.566pt shifted (74.175pt, -65.745pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.575pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Plain person}" & "}") scaled 0.875, (74.175pt, -84.337pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6563, (74.175pt, -89.426pt), 0, (1,1,1));
fill pmhbox(133.975pt, 76.172pt, 62.1pt, 20.815pt, 9.367pt) withcolor (0.0314,0.2588,0.4824);
draw pmhbox(133.975pt, 76.172pt, 62.1pt, 20.815pt, 9.367pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.575pt;
fill fullcircle scaled 28.566pt shifted (165.025pt, -65.745pt) withcolor (0.0314,0.2588,0.4824);
draw fullcircle scaled 28.566pt shifted (165.025pt, -65.745pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.575pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Person as a box}" & "}") scaled 0.875, (165.025pt, -84.337pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6563, (165.025pt, -89.426pt), 0, (1,1,1));
fill (224.825pt, -56.015pt) -- (224.891pt, -55.718pt) -- (225.091pt, -55.421pt) -- (225.422pt, -55.127pt) -- 
  (225.883pt, -54.837pt) -- (226.473pt, -54.552pt) -- (227.188pt, -54.273pt) -- (228.027pt, -54.002pt) -- 
  (228.985pt, -53.739pt) -- (230.058pt, -53.486pt) -- (231.241pt, -53.244pt) -- (232.53pt, -53.013pt) -- 
  (233.919pt, -52.796pt) -- (235.402pt, -52.592pt) -- (236.973pt, -52.403pt) -- (238.625pt, -52.23pt) -- 
  (240.35pt, -52.073pt) -- (242.142pt, -51.932pt) -- (243.993pt, -51.809pt) -- (245.894pt, -51.704pt) -- 
  (247.839pt, -51.618pt) -- (249.817pt, -51.55pt) -- (251.822pt, -51.501pt) -- (253.844pt, -51.472pt) -- 
  (255.875pt, -51.463pt) -- (257.906pt, -51.472pt) -- (259.928pt, -51.501pt) -- (261.932pt, -51.55pt) -- 
  (263.911pt, -51.618pt) -- (265.856pt, -51.704pt) -- (267.757pt, -51.809pt) -- (269.608pt, -51.932pt) -- 
  (271.4pt, -52.073pt) -- (273.125pt, -52.23pt) -- (274.777pt, -52.403pt) -- (276.348pt, -52.592pt) -- 
  (277.831pt, -52.796pt) -- (279.22pt, -53.013pt) -- (280.509pt, -53.244pt) -- (281.692pt, -53.486pt) -- 
  (282.765pt, -53.739pt) -- (283.723pt, -54.002pt) -- (284.561pt, -54.273pt) -- (285.277pt, -54.552pt) -- 
  (285.867pt, -54.837pt) -- (286.328pt, -55.127pt) -- (286.659pt, -55.421pt) -- (286.859pt, -55.718pt) -- 
  (286.925pt, -56.015pt) -- (286.925pt, -80.456pt) -- (286.859pt, -80.754pt) -- (286.659pt, -81.05pt) -- 
  (286.328pt, -81.344pt) -- (285.867pt, -81.635pt) -- (285.277pt, -81.92pt) -- (284.561pt, -82.198pt) -- 
  (283.723pt, -82.47pt) -- (282.765pt, -82.733pt) -- (281.692pt, -82.986pt) -- (280.509pt, -83.228pt) -- 
  (279.22pt, -83.458pt) -- (277.831pt, -83.676pt) -- (276.348pt, -83.879pt) -- (274.777pt, -84.068pt) -- 
  (273.125pt, -84.242pt) -- (271.4pt, -84.399pt) -- (269.608pt, -84.539pt) -- (267.757pt, -84.662pt) -- 
  (265.856pt, -84.767pt) -- (263.911pt, -84.854pt) -- (261.932pt, -84.922pt) -- (259.928pt, -84.97pt) -- 
  (257.906pt, -84.999pt) -- (255.875pt, -85.009pt) -- (253.844pt, -84.999pt) -- (251.822pt, -84.97pt) -- 
  (249.817pt, -84.922pt) -- (247.839pt, -84.854pt) -- (245.894pt, -84.767pt) -- (243.993pt, -84.662pt) -- 
  (242.142pt, -84.539pt) -- (240.35pt, -84.399pt) -- (238.625pt, -84.242pt) -- (236.973pt, -84.068pt) -- 
  (235.402pt, -83.879pt) -- (233.919pt, -83.676pt) -- (232.53pt, -83.458pt) -- (231.241pt, -83.228pt) -- 
  (230.058pt, -82.986pt) -- (228.985pt, -82.733pt) -- (228.027pt, -82.47pt) -- (227.188pt, -82.198pt) -- 
  (226.473pt, -81.92pt) -- (225.883pt, -81.635pt) -- (225.422pt, -81.344pt) -- (225.091pt, -81.05pt) -- 
  (224.891pt, -80.754pt) -- (224.825pt, -80.456pt) -- cycle withcolor (0.0667,0.4078,0.7412);
draw (224.825pt, -56.015pt) -- (224.891pt, -55.718pt) -- (225.091pt, -55.421pt) -- (225.422pt, -55.127pt) -- 
  (225.883pt, -54.837pt) -- (226.473pt, -54.552pt) -- (227.188pt, -54.273pt) -- (228.027pt, -54.002pt) -- 
  (228.985pt, -53.739pt) -- (230.058pt, -53.486pt) -- (231.241pt, -53.244pt) -- (232.53pt, -53.013pt) -- 
  (233.919pt, -52.796pt) -- (235.402pt, -52.592pt) -- (236.973pt, -52.403pt) -- (238.625pt, -52.23pt) -- 
  (240.35pt, -52.073pt) -- (242.142pt, -51.932pt) -- (243.993pt, -51.809pt) -- (245.894pt, -51.704pt) -- 
  (247.839pt, -51.618pt) -- (249.817pt, -51.55pt) -- (251.822pt, -51.501pt) -- (253.844pt, -51.472pt) -- 
  (255.875pt, -51.463pt) -- (257.906pt, -51.472pt) -- (259.928pt, -51.501pt) -- (261.932pt, -51.55pt) -- 
  (263.911pt, -51.618pt) -- (265.856pt, -51.704pt) -- (267.757pt, -51.809pt) -- (269.608pt, -51.932pt) -- 
  (271.4pt, -52.073pt) -- (273.125pt, -52.23pt) -- (274.777pt, -52.403pt) -- (276.348pt, -52.592pt) -- 
  (277.831pt, -52.796pt) -- (279.22pt, -53.013pt) -- (280.509pt, -53.244pt) -- (281.692pt, -53.486pt) -- 
  (282.765pt, -53.739pt) -- (283.723pt, -54.002pt) -- (284.561pt, -54.273pt) -- (285.277pt, -54.552pt) -- 
  (285.867pt, -54.837pt) -- (286.328pt, -55.127pt) -- (286.659pt, -55.421pt) -- (286.859pt, -55.718pt) -- 
  (286.925pt, -56.015pt) -- (286.925pt, -80.456pt) -- (286.859pt, -80.754pt) -- (286.659pt, -81.05pt) -- 
  (286.328pt, -81.344pt) -- (285.867pt, -81.635pt) -- (285.277pt, -81.92pt) -- (284.561pt, -82.198pt) -- 
  (283.723pt, -82.47pt) -- (282.765pt, -82.733pt) -- (281.692pt, -82.986pt) -- (280.509pt, -83.228pt) -- 
  (279.22pt, -83.458pt) -- (277.831pt, -83.676pt) -- (276.348pt, -83.879pt) -- (274.777pt, -84.068pt) -- 
  (273.125pt, -84.242pt) -- (271.4pt, -84.399pt) -- (269.608pt, -84.539pt) -- (267.757pt, -84.662pt) -- 
  (265.856pt, -84.767pt) -- (263.911pt, -84.854pt) -- (261.932pt, -84.922pt) -- (259.928pt, -84.97pt) -- 
  (257.906pt, -84.999pt) -- (255.875pt, -85.009pt) -- (253.844pt, -84.999pt) -- (251.822pt, -84.97pt) -- 
  (249.817pt, -84.922pt) -- (247.839pt, -84.854pt) -- (245.894pt, -84.767pt) -- (243.993pt, -84.662pt) -- 
  (242.142pt, -84.539pt) -- (240.35pt, -84.399pt) -- (238.625pt, -84.242pt) -- (236.973pt, -84.068pt) -- 
  (235.402pt, -83.879pt) -- (233.919pt, -83.676pt) -- (232.53pt, -83.458pt) -- (231.241pt, -83.228pt) -- 
  (230.058pt, -82.986pt) -- (228.985pt, -82.733pt) -- (228.027pt, -82.47pt) -- (227.188pt, -82.198pt) -- 
  (226.473pt, -81.92pt) -- (225.883pt, -81.635pt) -- (225.422pt, -81.344pt) -- (225.091pt, -81.05pt) -- 
  (224.891pt, -80.754pt) -- (224.825pt, -80.456pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
begingroup interim linecap := rounded; draw (224.825pt, -56.015pt)
  .. controls (224.825pt, -58.53pt) and (238.727pt, -60.568pt) .. (255.875pt, -60.568pt)
  .. controls (273.023pt, -60.568pt) and (286.925pt, -58.53pt) .. (286.925pt, -56.015pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf System as a cylinder}" & "}") scaled 0.875, (255.875pt, -67.415pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (255.875pt, -72.504pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "by its sprite" & "}") scaled 0.7175, (255.875pt, -77.158pt), 0, (1,1,1));
fill (317.984pt, -68.476pt) -- (317.833pt, -68.457pt) -- (317.683pt, -68.403pt) -- (317.534pt, -68.312pt) -- 
  (317.387pt, -68.186pt) -- (317.242pt, -68.024pt) -- (317.101pt, -67.828pt) -- (316.963pt, -67.598pt) -- 
  (316.83pt, -67.336pt) -- (316.701pt, -67.042pt) -- (316.578pt, -66.718pt) -- (316.462pt, -66.365pt) -- 
  (316.351pt, -65.984pt) -- (316.248pt, -65.578pt) -- (316.152pt, -65.147pt) -- (316.064pt, -64.695pt) -- 
  (315.984pt, -64.222pt) -- (315.913pt, -63.731pt) -- (315.851pt, -63.224pt) -- (315.798pt, -62.703pt) -- 
  (315.754pt, -62.171pt) -- (315.719pt, -61.629pt) -- (315.695pt, -61.079pt) -- (315.68pt, -60.525pt) -- 
  (315.675pt, -59.969pt) -- (315.68pt, -59.413pt) -- (315.695pt, -58.859pt) -- (315.719pt, -58.309pt) -- 
  (315.754pt, -57.767pt) -- (315.798pt, -57.235pt) -- (315.851pt, -56.714pt) -- (315.913pt, -56.207pt) -- 
  (315.984pt, -55.716pt) -- (316.064pt, -55.243pt) -- (316.152pt, -54.791pt) -- (316.248pt, -54.36pt) -- 
  (316.351pt, -53.954pt) -- (316.462pt, -53.573pt) -- (316.578pt, -53.22pt) -- (316.701pt, -52.896pt) -- 
  (316.83pt, -52.602pt) -- (316.963pt, -52.34pt) -- (317.101pt, -52.11pt) -- (317.242pt, -51.914pt) -- 
  (317.387pt, -51.752pt) -- (317.534pt, -51.626pt) -- (317.683pt, -51.535pt) -- (317.833pt, -51.481pt) -- 
  (317.984pt, -51.463pt) -- (382.394pt, -51.463pt) -- (382.545pt, -51.481pt) -- (382.695pt, -51.535pt) -- 
  (382.844pt, -51.626pt) -- (382.991pt, -51.752pt) -- (383.136pt, -51.914pt) -- (383.277pt, -52.11pt) -- 
  (383.415pt, -52.34pt) -- (383.548pt, -52.602pt) -- (383.677pt, -52.896pt) -- (383.8pt, -53.22pt) -- 
  (383.916pt, -53.573pt) -- (384.027pt, -53.954pt) -- (384.13pt, -54.36pt) -- (384.226pt, -54.791pt) -- 
  (384.314pt, -55.243pt) -- (384.394pt, -55.716pt) -- (384.465pt, -56.207pt) -- (384.527pt, -56.714pt) -- 
  (384.58pt, -57.235pt) -- (384.624pt, -57.767pt) -- (384.659pt, -58.309pt) -- (384.683pt, -58.859pt) -- 
  (384.698pt, -59.413pt) -- (384.703pt, -59.969pt) -- (384.698pt, -60.525pt) -- (384.683pt, -61.079pt) -- 
  (384.659pt, -61.629pt) -- (384.624pt, -62.171pt) -- (384.58pt, -62.703pt) -- (384.527pt, -63.224pt) -- 
  (384.465pt, -63.731pt) -- (384.394pt, -64.222pt) -- (384.314pt, -64.695pt) -- (384.226pt, -65.147pt) -- 
  (384.13pt, -65.578pt) -- (384.027pt, -65.984pt) -- (383.916pt, -66.365pt) -- (383.8pt, -66.718pt) -- 
  (383.677pt, -67.042pt) -- (383.548pt, -67.336pt) -- (383.415pt, -67.598pt) -- (383.277pt, -67.828pt) -- 
  (383.136pt, -68.024pt) -- (382.991pt, -68.186pt) -- (382.844pt, -68.312pt) -- (382.695pt, -68.403pt) -- 
  (382.545pt, -68.457pt) -- (382.394pt, -68.476pt) -- cycle withcolor (0.0667,0.4078,0.7412);
draw (317.984pt, -68.476pt) -- (317.833pt, -68.457pt) -- (317.683pt, -68.403pt) -- (317.534pt, -68.312pt) -- 
  (317.387pt, -68.186pt) -- (317.242pt, -68.024pt) -- (317.101pt, -67.828pt) -- (316.963pt, -67.598pt) -- 
  (316.83pt, -67.336pt) -- (316.701pt, -67.042pt) -- (316.578pt, -66.718pt) -- (316.462pt, -66.365pt) -- 
  (316.351pt, -65.984pt) -- (316.248pt, -65.578pt) -- (316.152pt, -65.147pt) -- (316.064pt, -64.695pt) -- 
  (315.984pt, -64.222pt) -- (315.913pt, -63.731pt) -- (315.851pt, -63.224pt) -- (315.798pt, -62.703pt) -- 
  (315.754pt, -62.171pt) -- (315.719pt, -61.629pt) -- (315.695pt, -61.079pt) -- (315.68pt, -60.525pt) -- 
  (315.675pt, -59.969pt) -- (315.68pt, -59.413pt) -- (315.695pt, -58.859pt) -- (315.719pt, -58.309pt) -- 
  (315.754pt, -57.767pt) -- (315.798pt, -57.235pt) -- (315.851pt, -56.714pt) -- (315.913pt, -56.207pt) -- 
  (315.984pt, -55.716pt) -- (316.064pt, -55.243pt) -- (316.152pt, -54.791pt) -- (316.248pt, -54.36pt) -- 
  (316.351pt, -53.954pt) -- (316.462pt, -53.573pt) -- (316.578pt, -53.22pt) -- (316.701pt, -52.896pt) -- 
  (316.83pt, -52.602pt) -- (316.963pt, -52.34pt) -- (317.101pt, -52.11pt) -- (317.242pt, -51.914pt) -- 
  (317.387pt, -51.752pt) -- (317.534pt, -51.626pt) -- (317.683pt, -51.535pt) -- (317.833pt, -51.481pt) -- 
  (317.984pt, -51.463pt) -- (382.394pt, -51.463pt) -- (382.545pt, -51.481pt) -- (382.695pt, -51.535pt) -- 
  (382.844pt, -51.626pt) -- (382.991pt, -51.752pt) -- (383.136pt, -51.914pt) -- (383.277pt, -52.11pt) -- 
  (383.415pt, -52.34pt) -- (383.548pt, -52.602pt) -- (383.677pt, -52.896pt) -- (383.8pt, -53.22pt) -- 
  (383.916pt, -53.573pt) -- (384.027pt, -53.954pt) -- (384.13pt, -54.36pt) -- (384.226pt, -54.791pt) -- 
  (384.314pt, -55.243pt) -- (384.394pt, -55.716pt) -- (384.465pt, -56.207pt) -- (384.527pt, -56.714pt) -- 
  (384.58pt, -57.235pt) -- (384.624pt, -57.767pt) -- (384.659pt, -58.309pt) -- (384.683pt, -58.859pt) -- 
  (384.698pt, -59.413pt) -- (384.703pt, -59.969pt) -- (384.698pt, -60.525pt) -- (384.683pt, -61.079pt) -- 
  (384.659pt, -61.629pt) -- (384.624pt, -62.171pt) -- (384.58pt, -62.703pt) -- (384.527pt, -63.224pt) -- 
  (384.465pt, -63.731pt) -- (384.394pt, -64.222pt) -- (384.314pt, -64.695pt) -- (384.226pt, -65.147pt) -- 
  (384.13pt, -65.578pt) -- (384.027pt, -65.984pt) -- (383.916pt, -66.365pt) -- (383.8pt, -66.718pt) -- 
  (383.677pt, -67.042pt) -- (383.548pt, -67.336pt) -- (383.415pt, -67.598pt) -- (383.277pt, -67.828pt) -- 
  (383.136pt, -68.024pt) -- (382.991pt, -68.186pt) -- (382.844pt, -68.312pt) -- (382.695pt, -68.403pt) -- 
  (382.545pt, -68.457pt) -- (382.394pt, -68.476pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
begingroup interim linecap := rounded; draw (382.394pt, -51.463pt)
  .. controls (381.118pt, -51.463pt) and (380.084pt, -55.271pt) .. (380.084pt, -59.969pt)
  .. controls (380.084pt, -64.667pt) and (381.118pt, -68.476pt) .. (382.394pt, -68.476pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf System as a queue}" & "}") scaled 0.875, (347.88pt, -55.315pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (347.88pt, -60.404pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "by its tags" & "}") scaled 0.7175, (347.88pt, -65.058pt), 0, (1,1,1));
fill pmhbox(43.125pt, 150.447pt, 62.1pt, 20.815pt, 9.367pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(43.125pt, 150.447pt, 62.1pt, 20.815pt, 9.367pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
fill fullcircle scaled 28.566pt shifted (74.175pt, -140.02pt) withcolor (0.0667,0.4078,0.7412);
draw fullcircle scaled 28.566pt shifted (74.175pt, -140.02pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf System as a person}" & "}") scaled 0.875, (74.175pt, -158.612pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (74.175pt, -163.7pt), 0, (1,1,1));
fill pmhbox(133.975pt, 125.737pt, 62.1pt, 15.065pt, 0pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(133.975pt, 125.737pt, 62.1pt, 15.065pt, 0pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
draw (136.275pt, -125.737pt) -- (136.275pt, -140.802pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
draw (193.775pt, -125.737pt) -- (193.775pt, -140.802pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Db as a component}" & "}") scaled 0.875, (165.025pt, -131.027pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (165.025pt, -136.116pt), 0, (1,1,1));
fill pmhbox(224.825pt, 125.737pt, 62.1pt, 20.815pt, 3.45pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(224.825pt, 125.737pt, 62.1pt, 20.815pt, 3.45pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.575pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Queue as a box}" & "}") scaled 0.875, (255.875pt, -133.902pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (255.875pt, -138.991pt), 0, (1,1,1));
fill pmhbox(315.675pt, 125.737pt, 62.1pt, 20.815pt, 3.45pt) withcolor (0.5216,0.7333,0.9412);
draw pmhbox(315.675pt, 125.737pt, 62.1pt, 20.815pt, 3.45pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.575pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Component, default}" & "}") scaled 0.875, (346.725pt, -133.902pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: Go]" & "}") scaled 0.6563, (346.725pt, -138.991pt), 0, (1,1,1));
draw (85.939pt, -73.837pt) -- (224.825pt, -69.259pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.287pt;
fill (225.112pt, -69.25pt) -- (222.286pt, -70.781pt) -- (222.192pt, -67.908pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "first" & "}") scaled 0.75, (159.522pt, -71.548pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (177.143pt, -73.292pt)
  .. controls (200.251pt, -69.737pt) and (246.467pt, -66.182pt) .. (315.791pt, -62.626pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.287pt; endgroup;
fill (316.078pt, -62.612pt) -- (313.28pt, -64.194pt) -- (313.133pt, -61.323pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "second" & "}") scaled 0.75, (251.435pt, -67.959pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (86.976pt, -146.353pt)
  .. controls (94.81pt, -143.727pt) and (110.476pt, -141.101pt) .. (133.975pt, -138.475pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.287pt; endgroup;
fill (134.261pt, -138.443pt) -- (131.563pt, -140.191pt) -- (131.244pt, -137.333pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "third" & "}") scaled 0.75, (114.616pt, -142.414pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (286.925pt, -136.145pt)
  .. controls (291.717pt, -136.145pt) and (301.3pt, -136.145pt) .. (315.675pt, -136.145pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.287pt; endgroup;
fill (315.963pt, -136.145pt) -- (313.088pt, -137.582pt) -- (313.088pt, -134.707pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "fourth" & "}") scaled 0.75, (306.268pt, -136.145pt), 0, (0.2667,0.2667,0.2667));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
