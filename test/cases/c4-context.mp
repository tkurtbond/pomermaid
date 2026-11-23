\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -677.899pt; pmxx2 := 429.675pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (47.813pt, -63.113pt)
  .. controls (47.813pt, -63.113pt) and (381.863pt, -63.113pt) .. (381.863pt, -63.113pt)
  .. controls (381.863pt, -63.113pt) and (381.863pt, -646.024pt) .. (381.863pt, -646.024pt)
  .. controls (381.863pt, -646.024pt) and (47.813pt, -646.024pt) .. (47.813pt, -646.024pt)
  .. controls (47.813pt, -646.024pt) and (47.813pt, -63.113pt) .. (47.813pt, -63.113pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.319pt dashed dashpattern(on 2.231pt off 2.231pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf BankBoundary0}" & "}") scaled 1, (214.838pt, -65.662pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[ENTERPRISE]" & "}") scaled 0.875, (214.838pt, -73.376pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (63.75pt, -259.025pt)
  .. controls (63.75pt, -259.025pt) and (365.925pt, -259.025pt) .. (365.925pt, -259.025pt)
  .. controls (365.925pt, -259.025pt) and (365.925pt, -630.086pt) .. (365.925pt, -630.086pt)
  .. controls (365.925pt, -630.086pt) and (63.75pt, -630.086pt) .. (63.75pt, -630.086pt)
  .. controls (63.75pt, -630.086pt) and (63.75pt, -259.025pt) .. (63.75pt, -259.025pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.319pt dashed dashpattern(on 2.231pt off 2.231pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf BankBoundary}" & "}") scaled 1, (214.838pt, -261.575pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[ENTERPRISE]" & "}") scaled 0.875, (214.838pt, -269.288pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (79.688pt, -376.973pt)
  .. controls (79.688pt, -376.973pt) and (281.137pt, -376.973pt) .. (281.137pt, -376.973pt)
  .. controls (281.137pt, -376.973pt) and (281.137pt, -457.602pt) .. (281.137pt, -457.602pt)
  .. controls (281.137pt, -457.602pt) and (79.688pt, -457.602pt) .. (79.688pt, -457.602pt)
  .. controls (79.688pt, -457.602pt) and (79.688pt, -376.973pt) .. (79.688pt, -376.973pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.319pt dashed dashpattern(on 2.231pt off 2.231pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf BankBoundary2}" & "}") scaled 1, (180.412pt, -379.523pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[SYSTEM]" & "}") scaled 0.875, (180.412pt, -387.237pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (79.688pt, -492.346pt)
  .. controls (79.688pt, -492.346pt) and (189.223pt, -492.346pt) .. (189.223pt, -492.346pt)
  .. controls (189.223pt, -492.346pt) and (189.223pt, -614.149pt) .. (189.223pt, -614.149pt)
  .. controls (189.223pt, -614.149pt) and (79.688pt, -614.149pt) .. (79.688pt, -614.149pt)
  .. controls (79.688pt, -614.149pt) and (79.688pt, -492.346pt) .. (79.688pt, -492.346pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.319pt dashed dashpattern(on 2.231pt off 2.231pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf BankBoundary3}" & "}") scaled 1, (134.455pt, -494.896pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[boundary]" & "}") scaled 0.875, (134.455pt, -502.609pt), 0, (0.2667,0.2667,0.2667));
fill pmhbox(63.75pt, 122.383pt, 68.85pt, 32.816pt, 12.186pt) withcolor (0.502,0.502,0.502);
draw pmhbox(63.75pt, 122.383pt, 68.85pt, 32.816pt, 12.186pt) withcolor (1,0,0) withpen pencircle scaled 0.637pt;
fill fullcircle scaled 31.671pt shifted (98.175pt, -110.823pt) withcolor (0.502,0.502,0.502);
draw fullcircle scaled 31.671pt shifted (98.175pt, -110.823pt) withcolor (1,0,0) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking Customer A}" & "}") scaled 0.875, (98.175pt, -131.435pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6563, (98.175pt, -137.077pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A customer of the bank, with\\personal bank accounts." & "}") scaled 0.7175, (98.175pt, -144.433pt), 0, (1,0,0));
fill pmhbox(164.475pt, 122.383pt, 68.85pt, 23.078pt, 10.385pt) withcolor (0.0314,0.2588,0.4824);
draw pmhbox(164.475pt, 122.383pt, 68.85pt, 23.078pt, 10.385pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.637pt;
fill fullcircle scaled 31.671pt shifted (198.9pt, -110.823pt) withcolor (0.0314,0.2588,0.4824);
draw fullcircle scaled 31.671pt shifted (198.9pt, -110.823pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking Customer B}" & "}") scaled 0.875, (198.9pt, -131.435pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6563, (198.9pt, -137.077pt), 0, (1,1,1));
fill pmhbox(265.2pt, 122.383pt, 68.85pt, 28.425pt, 12.186pt) withcolor (0.4078,0.4078,0.4078);
draw pmhbox(265.2pt, 122.383pt, 68.85pt, 28.425pt, 12.186pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt;
fill fullcircle scaled 31.671pt shifted (299.625pt, -110.823pt) withcolor (0.4078,0.4078,0.4078);
draw fullcircle scaled 31.671pt shifted (299.625pt, -110.823pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking Customer C}" & "}") scaled 0.875, (299.625pt, -131.435pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6563, (299.625pt, -137.077pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "desc" & "}") scaled 0.7175, (299.625pt, -142.237pt), 0, (1,1,1));
fill pmhbox(63.75pt, 187.074pt, 68.85pt, 37.207pt, 3.825pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(63.75pt, 187.074pt, 68.85pt, 37.207pt, 3.825pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Internet Banking System}" & "}") scaled 0.875, (98.175pt, -196.126pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (98.175pt, -201.768pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Allows customers to view\\information about their bank\\accounts, and make payments." & "}") scaled 0.7175, (98.175pt, -211.319pt), 0, (1,1,1));
fill (79.688pt, -295.947pt) -- (79.761pt, -295.617pt) -- (79.982pt, -295.288pt) -- (80.349pt, -294.963pt) -- 
  (80.86pt, -294.641pt) -- (81.514pt, -294.325pt) -- (82.308pt, -294.016pt) -- (83.238pt, -293.715pt) -- 
  (84.3pt, -293.423pt) -- (85.489pt, -293.143pt) -- (86.801pt, -292.875pt) -- (88.23pt, -292.619pt) -- 
  (89.77pt, -292.378pt) -- (91.415pt, -292.152pt) -- (93.156pt, -291.943pt) -- (94.987pt, -291.75pt) -- 
  (96.9pt, -291.576pt) -- (98.887pt, -291.42pt) -- (100.939pt, -291.284pt) -- (103.047pt, -291.167pt) -- 
  (105.203pt, -291.072pt) -- (107.396pt, -290.997pt) -- (109.619pt, -290.943pt) -- (111.861pt, -290.911pt) -- 
  (114.113pt, -290.9pt) -- (116.364pt, -290.911pt) -- (118.606pt, -290.943pt) -- (120.828pt, -290.997pt) -- 
  (123.022pt, -291.072pt) -- (125.178pt, -291.167pt) -- (127.286pt, -291.284pt) -- (129.338pt, -291.42pt) -- 
  (131.325pt, -291.576pt) -- (133.238pt, -291.75pt) -- (135.069pt, -291.943pt) -- (136.81pt, -292.152pt) -- 
  (138.455pt, -292.378pt) -- (139.995pt, -292.619pt) -- (141.424pt, -292.875pt) -- (142.736pt, -293.143pt) -- 
  (143.925pt, -293.423pt) -- (144.987pt, -293.715pt) -- (145.917pt, -294.016pt) -- (146.711pt, -294.325pt) -- 
  (147.365pt, -294.641pt) -- (147.876pt, -294.963pt) -- (148.243pt, -295.288pt) -- (148.464pt, -295.617pt) -- 
  (148.537pt, -295.947pt) -- (148.537pt, -337.182pt) -- (148.464pt, -337.512pt) -- (148.243pt, -337.841pt) -- 
  (147.876pt, -338.167pt) -- (147.365pt, -338.488pt) -- (146.711pt, -338.805pt) -- (145.917pt, -339.114pt) -- 
  (144.987pt, -339.415pt) -- (143.925pt, -339.706pt) -- (142.736pt, -339.986pt) -- (141.424pt, -340.255pt) -- 
  (139.995pt, -340.51pt) -- (138.455pt, -340.751pt) -- (136.81pt, -340.977pt) -- (135.069pt, -341.187pt) -- 
  (133.238pt, -341.379pt) -- (131.325pt, -341.553pt) -- (129.338pt, -341.709pt) -- (127.286pt, -341.845pt) -- 
  (125.178pt, -341.962pt) -- (123.022pt, -342.058pt) -- (120.828pt, -342.133pt) -- (118.606pt, -342.187pt) -- 
  (116.364pt, -342.219pt) -- (114.113pt, -342.23pt) -- (111.861pt, -342.219pt) -- (109.619pt, -342.187pt) -- 
  (107.396pt, -342.133pt) -- (105.203pt, -342.058pt) -- (103.047pt, -341.962pt) -- (100.939pt, -341.845pt) -- 
  (98.887pt, -341.709pt) -- (96.9pt, -341.553pt) -- (94.987pt, -341.379pt) -- (93.156pt, -341.187pt) -- 
  (91.415pt, -340.977pt) -- (89.77pt, -340.751pt) -- (88.23pt, -340.51pt) -- (86.801pt, -340.255pt) -- 
  (85.489pt, -339.986pt) -- (84.3pt, -339.706pt) -- (83.238pt, -339.415pt) -- (82.308pt, -339.114pt) -- 
  (81.514pt, -338.805pt) -- (80.86pt, -338.488pt) -- (80.349pt, -338.167pt) -- (79.982pt, -337.841pt) -- 
  (79.761pt, -337.512pt) -- (79.688pt, -337.182pt) -- cycle withcolor (0.6,0.6,0.6);
draw (79.688pt, -295.947pt) -- (79.761pt, -295.617pt) -- (79.982pt, -295.288pt) -- (80.349pt, -294.963pt) -- 
  (80.86pt, -294.641pt) -- (81.514pt, -294.325pt) -- (82.308pt, -294.016pt) -- (83.238pt, -293.715pt) -- 
  (84.3pt, -293.423pt) -- (85.489pt, -293.143pt) -- (86.801pt, -292.875pt) -- (88.23pt, -292.619pt) -- 
  (89.77pt, -292.378pt) -- (91.415pt, -292.152pt) -- (93.156pt, -291.943pt) -- (94.987pt, -291.75pt) -- 
  (96.9pt, -291.576pt) -- (98.887pt, -291.42pt) -- (100.939pt, -291.284pt) -- (103.047pt, -291.167pt) -- 
  (105.203pt, -291.072pt) -- (107.396pt, -290.997pt) -- (109.619pt, -290.943pt) -- (111.861pt, -290.911pt) -- 
  (114.113pt, -290.9pt) -- (116.364pt, -290.911pt) -- (118.606pt, -290.943pt) -- (120.828pt, -290.997pt) -- 
  (123.022pt, -291.072pt) -- (125.178pt, -291.167pt) -- (127.286pt, -291.284pt) -- (129.338pt, -291.42pt) -- 
  (131.325pt, -291.576pt) -- (133.238pt, -291.75pt) -- (135.069pt, -291.943pt) -- (136.81pt, -292.152pt) -- 
  (138.455pt, -292.378pt) -- (139.995pt, -292.619pt) -- (141.424pt, -292.875pt) -- (142.736pt, -293.143pt) -- 
  (143.925pt, -293.423pt) -- (144.987pt, -293.715pt) -- (145.917pt, -294.016pt) -- (146.711pt, -294.325pt) -- 
  (147.365pt, -294.641pt) -- (147.876pt, -294.963pt) -- (148.243pt, -295.288pt) -- (148.464pt, -295.617pt) -- 
  (148.537pt, -295.947pt) -- (148.537pt, -337.182pt) -- (148.464pt, -337.512pt) -- (148.243pt, -337.841pt) -- 
  (147.876pt, -338.167pt) -- (147.365pt, -338.488pt) -- (146.711pt, -338.805pt) -- (145.917pt, -339.114pt) -- 
  (144.987pt, -339.415pt) -- (143.925pt, -339.706pt) -- (142.736pt, -339.986pt) -- (141.424pt, -340.255pt) -- 
  (139.995pt, -340.51pt) -- (138.455pt, -340.751pt) -- (136.81pt, -340.977pt) -- (135.069pt, -341.187pt) -- 
  (133.238pt, -341.379pt) -- (131.325pt, -341.553pt) -- (129.338pt, -341.709pt) -- (127.286pt, -341.845pt) -- 
  (125.178pt, -341.962pt) -- (123.022pt, -342.058pt) -- (120.828pt, -342.133pt) -- (118.606pt, -342.187pt) -- 
  (116.364pt, -342.219pt) -- (114.113pt, -342.23pt) -- (111.861pt, -342.219pt) -- (109.619pt, -342.187pt) -- 
  (107.396pt, -342.133pt) -- (105.203pt, -342.058pt) -- (103.047pt, -341.962pt) -- (100.939pt, -341.845pt) -- 
  (98.887pt, -341.709pt) -- (96.9pt, -341.553pt) -- (94.987pt, -341.379pt) -- (93.156pt, -341.187pt) -- 
  (91.415pt, -340.977pt) -- (89.77pt, -340.751pt) -- (88.23pt, -340.51pt) -- (86.801pt, -340.255pt) -- 
  (85.489pt, -339.986pt) -- (84.3pt, -339.706pt) -- (83.238pt, -339.415pt) -- (82.308pt, -339.114pt) -- 
  (81.514pt, -338.805pt) -- (80.86pt, -338.488pt) -- (80.349pt, -338.167pt) -- (79.982pt, -337.841pt) -- 
  (79.761pt, -337.512pt) -- (79.688pt, -337.182pt) -- cycle withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt;
begingroup interim linecap := rounded; draw (79.688pt, -295.947pt)
  .. controls (79.688pt, -298.735pt) and (95.1pt, -300.995pt) .. (114.113pt, -300.995pt)
  .. controls (133.125pt, -300.995pt) and (148.537pt, -298.735pt) .. (148.537pt, -295.947pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Mainframe Banking}\\{\bf System}" & "}") scaled 0.875, (114.113pt, -311.264pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (114.113pt, -319.583pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores all of the core banking\\information about customers,\\accounts, transactions, etc." & "}") scaled 0.7175, (114.113pt, -329.134pt), 0, (1,1,1));
fill pmhbox(95.625pt, 408.848pt, 68.85pt, 23.078pt, 3.825pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(95.625pt, 408.848pt, 68.85pt, 23.078pt, 3.825pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking System A}" & "}") scaled 0.875, (130.05pt, -417.901pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (130.05pt, -423.543pt), 0, (1,1,1));
fill pmhbox(196.35pt, 408.848pt, 68.85pt, 32.816pt, 3.825pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(196.35pt, 408.848pt, 68.85pt, 32.816pt, 3.825pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking System B}" & "}") scaled 0.875, (230.775pt, -417.901pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (230.775pt, -423.543pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A system of the bank, with\\personal bank accounts. next line." & "}") scaled 0.7175, (230.775pt, -430.898pt), 0, (1,1,1));
fill pmhbox(180.412pt, 290.9pt, 68.85pt, 32.816pt, 3.825pt) withcolor (0.6,0.6,0.6);
draw pmhbox(180.412pt, 290.9pt, 68.85pt, 32.816pt, 3.825pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf E-mail system}" & "}") scaled 0.875, (214.838pt, -299.952pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (214.838pt, -305.594pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "The internal Microsoft Exchange\\e-mail system." & "}") scaled 0.7175, (214.838pt, -312.949pt), 0, (1,1,1));
fill (281.137pt, -295.947pt) -- (281.211pt, -295.617pt) -- (281.432pt, -295.288pt) -- (281.799pt, -294.963pt) -- 
  (282.311pt, -294.641pt) -- (282.964pt, -294.325pt) -- (283.758pt, -294.016pt) -- (284.688pt, -293.715pt) -- 
  (285.75pt, -293.423pt) -- (286.939pt, -293.143pt) -- (288.251pt, -292.875pt) -- (289.68pt, -292.619pt) -- 
  (291.22pt, -292.378pt) -- (292.865pt, -292.152pt) -- (294.606pt, -291.943pt) -- (296.437pt, -291.75pt) -- 
  (298.35pt, -291.576pt) -- (300.337pt, -291.42pt) -- (302.389pt, -291.284pt) -- (304.497pt, -291.167pt) -- 
  (306.653pt, -291.072pt) -- (308.847pt, -290.997pt) -- (311.069pt, -290.943pt) -- (313.311pt, -290.911pt) -- 
  (315.563pt, -290.9pt) -- (317.814pt, -290.911pt) -- (320.056pt, -290.943pt) -- (322.278pt, -290.997pt) -- 
  (324.472pt, -291.072pt) -- (326.628pt, -291.167pt) -- (328.736pt, -291.284pt) -- (330.788pt, -291.42pt) -- 
  (332.775pt, -291.576pt) -- (334.688pt, -291.75pt) -- (336.519pt, -291.943pt) -- (338.26pt, -292.152pt) -- 
  (339.905pt, -292.378pt) -- (341.445pt, -292.619pt) -- (342.874pt, -292.875pt) -- (344.186pt, -293.143pt) -- 
  (345.375pt, -293.423pt) -- (346.437pt, -293.715pt) -- (347.367pt, -294.016pt) -- (348.161pt, -294.325pt) -- 
  (348.814pt, -294.641pt) -- (349.326pt, -294.963pt) -- (349.693pt, -295.288pt) -- (349.914pt, -295.617pt) -- 
  (349.988pt, -295.947pt) -- (349.988pt, -332.791pt) -- (349.914pt, -333.121pt) -- (349.693pt, -333.45pt) -- 
  (349.326pt, -333.776pt) -- (348.814pt, -334.097pt) -- (348.161pt, -334.413pt) -- (347.367pt, -334.723pt) -- 
  (346.437pt, -335.023pt) -- (345.375pt, -335.315pt) -- (344.186pt, -335.595pt) -- (342.874pt, -335.864pt) -- 
  (341.445pt, -336.119pt) -- (339.905pt, -336.36pt) -- (338.26pt, -336.586pt) -- (336.519pt, -336.796pt) -- 
  (334.688pt, -336.988pt) -- (332.775pt, -337.162pt) -- (330.788pt, -337.318pt) -- (328.736pt, -337.454pt) -- 
  (326.628pt, -337.571pt) -- (324.472pt, -337.667pt) -- (322.278pt, -337.742pt) -- (320.056pt, -337.795pt) -- 
  (317.814pt, -337.828pt) -- (315.563pt, -337.839pt) -- (313.311pt, -337.828pt) -- (311.069pt, -337.795pt) -- 
  (308.847pt, -337.742pt) -- (306.653pt, -337.667pt) -- (304.497pt, -337.571pt) -- (302.389pt, -337.454pt) -- 
  (300.337pt, -337.318pt) -- (298.35pt, -337.162pt) -- (296.437pt, -336.988pt) -- (294.606pt, -336.796pt) -- 
  (292.865pt, -336.586pt) -- (291.22pt, -336.36pt) -- (289.68pt, -336.119pt) -- (288.251pt, -335.864pt) -- 
  (286.939pt, -335.595pt) -- (285.75pt, -335.315pt) -- (284.688pt, -335.023pt) -- (283.758pt, -334.723pt) -- 
  (282.964pt, -334.413pt) -- (282.311pt, -334.097pt) -- (281.799pt, -333.776pt) -- (281.432pt, -333.45pt) -- 
  (281.211pt, -333.121pt) -- (281.137pt, -332.791pt) -- cycle withcolor (0.0667,0.4078,0.7412);
draw (281.137pt, -295.947pt) -- (281.211pt, -295.617pt) -- (281.432pt, -295.288pt) -- (281.799pt, -294.963pt) -- 
  (282.311pt, -294.641pt) -- (282.964pt, -294.325pt) -- (283.758pt, -294.016pt) -- (284.688pt, -293.715pt) -- 
  (285.75pt, -293.423pt) -- (286.939pt, -293.143pt) -- (288.251pt, -292.875pt) -- (289.68pt, -292.619pt) -- 
  (291.22pt, -292.378pt) -- (292.865pt, -292.152pt) -- (294.606pt, -291.943pt) -- (296.437pt, -291.75pt) -- 
  (298.35pt, -291.576pt) -- (300.337pt, -291.42pt) -- (302.389pt, -291.284pt) -- (304.497pt, -291.167pt) -- 
  (306.653pt, -291.072pt) -- (308.847pt, -290.997pt) -- (311.069pt, -290.943pt) -- (313.311pt, -290.911pt) -- 
  (315.563pt, -290.9pt) -- (317.814pt, -290.911pt) -- (320.056pt, -290.943pt) -- (322.278pt, -290.997pt) -- 
  (324.472pt, -291.072pt) -- (326.628pt, -291.167pt) -- (328.736pt, -291.284pt) -- (330.788pt, -291.42pt) -- 
  (332.775pt, -291.576pt) -- (334.688pt, -291.75pt) -- (336.519pt, -291.943pt) -- (338.26pt, -292.152pt) -- 
  (339.905pt, -292.378pt) -- (341.445pt, -292.619pt) -- (342.874pt, -292.875pt) -- (344.186pt, -293.143pt) -- 
  (345.375pt, -293.423pt) -- (346.437pt, -293.715pt) -- (347.367pt, -294.016pt) -- (348.161pt, -294.325pt) -- 
  (348.814pt, -294.641pt) -- (349.326pt, -294.963pt) -- (349.693pt, -295.288pt) -- (349.914pt, -295.617pt) -- 
  (349.988pt, -295.947pt) -- (349.988pt, -332.791pt) -- (349.914pt, -333.121pt) -- (349.693pt, -333.45pt) -- 
  (349.326pt, -333.776pt) -- (348.814pt, -334.097pt) -- (348.161pt, -334.413pt) -- (347.367pt, -334.723pt) -- 
  (346.437pt, -335.023pt) -- (345.375pt, -335.315pt) -- (344.186pt, -335.595pt) -- (342.874pt, -335.864pt) -- 
  (341.445pt, -336.119pt) -- (339.905pt, -336.36pt) -- (338.26pt, -336.586pt) -- (336.519pt, -336.796pt) -- 
  (334.688pt, -336.988pt) -- (332.775pt, -337.162pt) -- (330.788pt, -337.318pt) -- (328.736pt, -337.454pt) -- 
  (326.628pt, -337.571pt) -- (324.472pt, -337.667pt) -- (322.278pt, -337.742pt) -- (320.056pt, -337.795pt) -- 
  (317.814pt, -337.828pt) -- (315.563pt, -337.839pt) -- (313.311pt, -337.828pt) -- (311.069pt, -337.795pt) -- 
  (308.847pt, -337.742pt) -- (306.653pt, -337.667pt) -- (304.497pt, -337.571pt) -- (302.389pt, -337.454pt) -- 
  (300.337pt, -337.318pt) -- (298.35pt, -337.162pt) -- (296.437pt, -336.988pt) -- (294.606pt, -336.796pt) -- 
  (292.865pt, -336.586pt) -- (291.22pt, -336.36pt) -- (289.68pt, -336.119pt) -- (288.251pt, -335.864pt) -- 
  (286.939pt, -335.595pt) -- (285.75pt, -335.315pt) -- (284.688pt, -335.023pt) -- (283.758pt, -334.723pt) -- 
  (282.964pt, -334.413pt) -- (282.311pt, -334.097pt) -- (281.799pt, -333.776pt) -- (281.432pt, -333.45pt) -- 
  (281.211pt, -333.121pt) -- (281.137pt, -332.791pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt;
begingroup interim linecap := rounded; draw (281.137pt, -295.947pt)
  .. controls (281.137pt, -298.735pt) and (296.55pt, -300.995pt) .. (315.563pt, -300.995pt)
  .. controls (334.575pt, -300.995pt) and (349.988pt, -298.735pt) .. (349.988pt, -295.947pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking System D}\\{\bf Database}" & "}") scaled 0.875, (315.563pt, -311.264pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (315.563pt, -319.583pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A system of the bank, with\\personal bank accounts." & "}") scaled 0.7175, (315.563pt, -326.938pt), 0, (1,1,1));
fill (98.185pt, -543.083pt) -- (98.018pt, -543.063pt) -- (97.851pt, -543.002pt) -- (97.686pt, -542.902pt) -- 
  (97.523pt, -542.762pt) -- (97.362pt, -542.582pt) -- (97.206pt, -542.365pt) -- (97.053pt, -542.11pt) -- 
  (96.905pt, -541.819pt) -- (96.763pt, -541.494pt) -- (96.627pt, -541.134pt) -- (96.497pt, -540.743pt) -- 
  (96.375pt, -540.321pt) -- (96.26pt, -539.87pt) -- (96.154pt, -539.393pt) -- (96.057pt, -538.891pt) -- 
  (95.968pt, -538.367pt) -- (95.889pt, -537.823pt) -- (95.82pt, -537.261pt) -- (95.761pt, -536.683pt) -- 
  (95.712pt, -536.093pt) -- (95.674pt, -535.492pt) -- (95.647pt, -534.883pt) -- (95.63pt, -534.269pt) -- 
  (95.625pt, -533.652pt) -- (95.63pt, -533.035pt) -- (95.647pt, -532.421pt) -- (95.674pt, -531.812pt) -- 
  (95.712pt, -531.211pt) -- (95.761pt, -530.62pt) -- (95.82pt, -530.043pt) -- (95.889pt, -529.48pt) -- 
  (95.968pt, -528.936pt) -- (96.057pt, -528.412pt) -- (96.154pt, -527.91pt) -- (96.26pt, -527.433pt) -- 
  (96.375pt, -526.983pt) -- (96.497pt, -526.561pt) -- (96.627pt, -526.17pt) -- (96.763pt, -525.81pt) -- 
  (96.905pt, -525.484pt) -- (97.053pt, -525.193pt) -- (97.206pt, -524.938pt) -- (97.362pt, -524.721pt) -- 
  (97.523pt, -524.542pt) -- (97.686pt, -524.402pt) -- (97.851pt, -524.301pt) -- (98.018pt, -524.241pt) -- 
  (98.185pt, -524.221pt) -- (169.596pt, -524.221pt) -- (169.763pt, -524.241pt) -- (169.93pt, -524.301pt) -- 
  (170.095pt, -524.402pt) -- (170.258pt, -524.542pt) -- (170.419pt, -524.721pt) -- (170.576pt, -524.938pt) -- 
  (170.728pt, -525.193pt) -- (170.876pt, -525.484pt) -- (171.018pt, -525.81pt) -- (171.154pt, -526.17pt) -- 
  (171.284pt, -526.561pt) -- (171.406pt, -526.983pt) -- (171.521pt, -527.433pt) -- (171.627pt, -527.91pt) -- 
  (171.725pt, -528.412pt) -- (171.813pt, -528.936pt) -- (171.892pt, -529.48pt) -- (171.961pt, -530.043pt) -- 
  (172.02pt, -530.62pt) -- (172.069pt, -531.211pt) -- (172.107pt, -531.812pt) -- (172.134pt, -532.421pt) -- 
  (172.151pt, -533.035pt) -- (172.156pt, -533.652pt) -- (172.151pt, -534.269pt) -- (172.134pt, -534.883pt) -- 
  (172.107pt, -535.492pt) -- (172.069pt, -536.093pt) -- (172.02pt, -536.683pt) -- (171.961pt, -537.261pt) -- 
  (171.892pt, -537.823pt) -- (171.813pt, -538.367pt) -- (171.725pt, -538.891pt) -- (171.627pt, -539.393pt) -- 
  (171.521pt, -539.87pt) -- (171.406pt, -540.321pt) -- (171.284pt, -540.743pt) -- (171.154pt, -541.134pt) -- 
  (171.018pt, -541.494pt) -- (170.876pt, -541.819pt) -- (170.728pt, -542.11pt) -- (170.576pt, -542.365pt) -- 
  (170.419pt, -542.582pt) -- (170.258pt, -542.762pt) -- (170.095pt, -542.902pt) -- (169.93pt, -543.002pt) -- 
  (169.763pt, -543.063pt) -- (169.596pt, -543.083pt) -- cycle withcolor (0.0667,0.4078,0.7412);
draw (98.185pt, -543.083pt) -- (98.018pt, -543.063pt) -- (97.851pt, -543.002pt) -- (97.686pt, -542.902pt) -- 
  (97.523pt, -542.762pt) -- (97.362pt, -542.582pt) -- (97.206pt, -542.365pt) -- (97.053pt, -542.11pt) -- 
  (96.905pt, -541.819pt) -- (96.763pt, -541.494pt) -- (96.627pt, -541.134pt) -- (96.497pt, -540.743pt) -- 
  (96.375pt, -540.321pt) -- (96.26pt, -539.87pt) -- (96.154pt, -539.393pt) -- (96.057pt, -538.891pt) -- 
  (95.968pt, -538.367pt) -- (95.889pt, -537.823pt) -- (95.82pt, -537.261pt) -- (95.761pt, -536.683pt) -- 
  (95.712pt, -536.093pt) -- (95.674pt, -535.492pt) -- (95.647pt, -534.883pt) -- (95.63pt, -534.269pt) -- 
  (95.625pt, -533.652pt) -- (95.63pt, -533.035pt) -- (95.647pt, -532.421pt) -- (95.674pt, -531.812pt) -- 
  (95.712pt, -531.211pt) -- (95.761pt, -530.62pt) -- (95.82pt, -530.043pt) -- (95.889pt, -529.48pt) -- 
  (95.968pt, -528.936pt) -- (96.057pt, -528.412pt) -- (96.154pt, -527.91pt) -- (96.26pt, -527.433pt) -- 
  (96.375pt, -526.983pt) -- (96.497pt, -526.561pt) -- (96.627pt, -526.17pt) -- (96.763pt, -525.81pt) -- 
  (96.905pt, -525.484pt) -- (97.053pt, -525.193pt) -- (97.206pt, -524.938pt) -- (97.362pt, -524.721pt) -- 
  (97.523pt, -524.542pt) -- (97.686pt, -524.402pt) -- (97.851pt, -524.301pt) -- (98.018pt, -524.241pt) -- 
  (98.185pt, -524.221pt) -- (169.596pt, -524.221pt) -- (169.763pt, -524.241pt) -- (169.93pt, -524.301pt) -- 
  (170.095pt, -524.402pt) -- (170.258pt, -524.542pt) -- (170.419pt, -524.721pt) -- (170.576pt, -524.938pt) -- 
  (170.728pt, -525.193pt) -- (170.876pt, -525.484pt) -- (171.018pt, -525.81pt) -- (171.154pt, -526.17pt) -- 
  (171.284pt, -526.561pt) -- (171.406pt, -526.983pt) -- (171.521pt, -527.433pt) -- (171.627pt, -527.91pt) -- 
  (171.725pt, -528.412pt) -- (171.813pt, -528.936pt) -- (171.892pt, -529.48pt) -- (171.961pt, -530.043pt) -- 
  (172.02pt, -530.62pt) -- (172.069pt, -531.211pt) -- (172.107pt, -531.812pt) -- (172.134pt, -532.421pt) -- 
  (172.151pt, -533.035pt) -- (172.156pt, -533.652pt) -- (172.151pt, -534.269pt) -- (172.134pt, -534.883pt) -- 
  (172.107pt, -535.492pt) -- (172.069pt, -536.093pt) -- (172.02pt, -536.683pt) -- (171.961pt, -537.261pt) -- 
  (171.892pt, -537.823pt) -- (171.813pt, -538.367pt) -- (171.725pt, -538.891pt) -- (171.627pt, -539.393pt) -- 
  (171.521pt, -539.87pt) -- (171.406pt, -540.321pt) -- (171.284pt, -540.743pt) -- (171.154pt, -541.134pt) -- 
  (171.018pt, -541.494pt) -- (170.876pt, -541.819pt) -- (170.728pt, -542.11pt) -- (170.576pt, -542.365pt) -- 
  (170.419pt, -542.582pt) -- (170.258pt, -542.762pt) -- (170.095pt, -542.902pt) -- (169.93pt, -543.002pt) -- 
  (169.763pt, -543.063pt) -- (169.596pt, -543.083pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt;
begingroup interim linecap := rounded; draw (169.596pt, -524.221pt)
  .. controls (168.182pt, -524.221pt) and (167.035pt, -528.443pt) .. (167.035pt, -533.652pt)
  .. controls (167.035pt, -538.86pt) and (168.182pt, -543.083pt) .. (169.596pt, -543.083pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.637pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking System F Queue}" & "}") scaled 0.875, (131.33pt, -528.492pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (131.33pt, -534.134pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A system of the bank." & "}") scaled 0.7175, (131.33pt, -539.294pt), 0, (1,1,1));
fill (98.562pt, -598.211pt) -- (98.37pt, -598.187pt) -- (98.178pt, -598.112pt) -- (97.989pt, -597.988pt) -- 
  (97.802pt, -597.815pt) -- (97.618pt, -597.594pt) -- (97.438pt, -597.326pt) -- (97.263pt, -597.012pt) -- 
  (97.093pt, -596.654pt) -- (96.93pt, -596.252pt) -- (96.774pt, -595.809pt) -- (96.625pt, -595.326pt) -- 
  (96.485pt, -594.806pt) -- (96.354pt, -594.251pt) -- (96.232pt, -593.663pt) -- (96.12pt, -593.044pt) -- 
  (96.018pt, -592.398pt) -- (95.928pt, -591.727pt) -- (95.849pt, -591.034pt) -- (95.781pt, -590.322pt) -- 
  (95.725pt, -589.594pt) -- (95.681pt, -588.853pt) -- (95.65pt, -588.102pt) -- (95.631pt, -587.345pt) -- 
  (95.625pt, -586.585pt) -- (95.631pt, -585.824pt) -- (95.65pt, -585.067pt) -- (95.681pt, -584.316pt) -- 
  (95.725pt, -583.575pt) -- (95.781pt, -582.847pt) -- (95.849pt, -582.135pt) -- (95.928pt, -581.442pt) -- 
  (96.018pt, -580.771pt) -- (96.12pt, -580.125pt) -- (96.232pt, -579.507pt) -- (96.354pt, -578.919pt) -- 
  (96.485pt, -578.363pt) -- (96.625pt, -577.843pt) -- (96.774pt, -577.361pt) -- (96.93pt, -576.917pt) -- 
  (97.093pt, -576.516pt) -- (97.263pt, -576.157pt) -- (97.438pt, -575.843pt) -- (97.618pt, -575.575pt) -- 
  (97.802pt, -575.354pt) -- (97.989pt, -575.181pt) -- (98.178pt, -575.057pt) -- (98.37pt, -574.983pt) -- 
  (98.562pt, -574.958pt) -- (170.349pt, -574.958pt) -- (170.541pt, -574.983pt) -- (170.732pt, -575.057pt) -- 
  (170.921pt, -575.181pt) -- (171.109pt, -575.354pt) -- (171.292pt, -575.575pt) -- (171.472pt, -575.843pt) -- 
  (171.647pt, -576.157pt) -- (171.817pt, -576.516pt) -- (171.98pt, -576.917pt) -- (172.136pt, -577.361pt) -- 
  (172.285pt, -577.843pt) -- (172.425pt, -578.363pt) -- (172.557pt, -578.919pt) -- (172.678pt, -579.507pt) -- 
  (172.79pt, -580.125pt) -- (172.892pt, -580.771pt) -- (172.982pt, -581.442pt) -- (173.062pt, -582.135pt) -- 
  (173.129pt, -582.847pt) -- (173.185pt, -583.575pt) -- (173.229pt, -584.316pt) -- (173.26pt, -585.067pt) -- 
  (173.279pt, -585.824pt) -- (173.285pt, -586.585pt) -- (173.279pt, -587.345pt) -- (173.26pt, -588.102pt) -- 
  (173.229pt, -588.853pt) -- (173.185pt, -589.594pt) -- (173.129pt, -590.322pt) -- (173.062pt, -591.034pt) -- 
  (172.982pt, -591.727pt) -- (172.892pt, -592.398pt) -- (172.79pt, -593.044pt) -- (172.678pt, -593.663pt) -- 
  (172.557pt, -594.251pt) -- (172.425pt, -594.806pt) -- (172.285pt, -595.326pt) -- (172.136pt, -595.809pt) -- 
  (171.98pt, -596.252pt) -- (171.817pt, -596.654pt) -- (171.647pt, -597.012pt) -- (171.472pt, -597.326pt) -- 
  (171.292pt, -597.594pt) -- (171.109pt, -597.815pt) -- (170.921pt, -597.988pt) -- (170.732pt, -598.112pt) -- 
  (170.541pt, -598.187pt) -- (170.349pt, -598.211pt) -- cycle withcolor (0.6,0.6,0.6);
draw (98.562pt, -598.211pt) -- (98.37pt, -598.187pt) -- (98.178pt, -598.112pt) -- (97.989pt, -597.988pt) -- 
  (97.802pt, -597.815pt) -- (97.618pt, -597.594pt) -- (97.438pt, -597.326pt) -- (97.263pt, -597.012pt) -- 
  (97.093pt, -596.654pt) -- (96.93pt, -596.252pt) -- (96.774pt, -595.809pt) -- (96.625pt, -595.326pt) -- 
  (96.485pt, -594.806pt) -- (96.354pt, -594.251pt) -- (96.232pt, -593.663pt) -- (96.12pt, -593.044pt) -- 
  (96.018pt, -592.398pt) -- (95.928pt, -591.727pt) -- (95.849pt, -591.034pt) -- (95.781pt, -590.322pt) -- 
  (95.725pt, -589.594pt) -- (95.681pt, -588.853pt) -- (95.65pt, -588.102pt) -- (95.631pt, -587.345pt) -- 
  (95.625pt, -586.585pt) -- (95.631pt, -585.824pt) -- (95.65pt, -585.067pt) -- (95.681pt, -584.316pt) -- 
  (95.725pt, -583.575pt) -- (95.781pt, -582.847pt) -- (95.849pt, -582.135pt) -- (95.928pt, -581.442pt) -- 
  (96.018pt, -580.771pt) -- (96.12pt, -580.125pt) -- (96.232pt, -579.507pt) -- (96.354pt, -578.919pt) -- 
  (96.485pt, -578.363pt) -- (96.625pt, -577.843pt) -- (96.774pt, -577.361pt) -- (96.93pt, -576.917pt) -- 
  (97.093pt, -576.516pt) -- (97.263pt, -576.157pt) -- (97.438pt, -575.843pt) -- (97.618pt, -575.575pt) -- 
  (97.802pt, -575.354pt) -- (97.989pt, -575.181pt) -- (98.178pt, -575.057pt) -- (98.37pt, -574.983pt) -- 
  (98.562pt, -574.958pt) -- (170.349pt, -574.958pt) -- (170.541pt, -574.983pt) -- (170.732pt, -575.057pt) -- 
  (170.921pt, -575.181pt) -- (171.109pt, -575.354pt) -- (171.292pt, -575.575pt) -- (171.472pt, -575.843pt) -- 
  (171.647pt, -576.157pt) -- (171.817pt, -576.516pt) -- (171.98pt, -576.917pt) -- (172.136pt, -577.361pt) -- 
  (172.285pt, -577.843pt) -- (172.425pt, -578.363pt) -- (172.557pt, -578.919pt) -- (172.678pt, -579.507pt) -- 
  (172.79pt, -580.125pt) -- (172.892pt, -580.771pt) -- (172.982pt, -581.442pt) -- (173.062pt, -582.135pt) -- 
  (173.129pt, -582.847pt) -- (173.185pt, -583.575pt) -- (173.229pt, -584.316pt) -- (173.26pt, -585.067pt) -- 
  (173.279pt, -585.824pt) -- (173.285pt, -586.585pt) -- (173.279pt, -587.345pt) -- (173.26pt, -588.102pt) -- 
  (173.229pt, -588.853pt) -- (173.185pt, -589.594pt) -- (173.129pt, -590.322pt) -- (173.062pt, -591.034pt) -- 
  (172.982pt, -591.727pt) -- (172.892pt, -592.398pt) -- (172.79pt, -593.044pt) -- (172.678pt, -593.663pt) -- 
  (172.557pt, -594.251pt) -- (172.425pt, -594.806pt) -- (172.285pt, -595.326pt) -- (172.136pt, -595.809pt) -- 
  (171.98pt, -596.252pt) -- (171.817pt, -596.654pt) -- (171.647pt, -597.012pt) -- (171.472pt, -597.326pt) -- 
  (171.292pt, -597.594pt) -- (171.109pt, -597.815pt) -- (170.921pt, -597.988pt) -- (170.732pt, -598.112pt) -- 
  (170.541pt, -598.187pt) -- (170.349pt, -598.211pt) -- cycle withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt;
begingroup interim linecap := rounded; draw (170.349pt, -574.958pt)
  .. controls (168.727pt, -574.958pt) and (167.412pt, -580.163pt) .. (167.412pt, -586.585pt)
  .. controls (167.412pt, -593.006pt) and (168.727pt, -598.211pt) .. (170.349pt, -598.211pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.637pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Banking System G Queue}" & "}") scaled 0.875, (131.518pt, -579.229pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (131.518pt, -584.871pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A system of the bank, with\\personal bank accounts." & "}") scaled 0.7175, (131.518pt, -592.227pt), 0, (1,1,1));
draw (98.175pt, -155.199pt) -- (98.175pt, -187.074pt) withcolor (0,0,1) withpen pencircle scaled 0.319pt;
fill (98.175pt, -187.393pt) -- (96.581pt, -184.205pt) -- (99.769pt, -184.205pt) -- cycle withcolor (0.2,0.2,0.2);
fill (98.175pt, -154.88pt) -- (99.769pt, -158.068pt) -- (96.581pt, -158.068pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (103.766pt, -171.136pt), 0, (0,0,1));
begingroup interim linecap := rounded; draw (100.849pt, -224.281pt)
  .. controls (102.445pt, -246.497pt) and (105.636pt, -268.713pt) .. (110.424pt, -290.929pt) withcolor (0,0,1) withpen pencircle scaled 0.319pt; endgroup;
fill (110.491pt, -291.24pt) -- (108.261pt, -288.46pt) -- (111.377pt, -287.789pt) -- cycle withcolor (0.2,0.2,0.2);
fill (100.826pt, -223.963pt) -- (102.644pt, -227.028pt) -- (99.465pt, -227.256pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (109.633pt, -254.417pt), 0, (0,0,1));
begingroup interim linecap := rounded; draw (119.53pt, -224.281pt)
  .. controls (132.276pt, -246.487pt) and (157.766pt, -268.693pt) .. (196.003pt, -290.9pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.319pt; endgroup;
fill (196.278pt, -291.06pt) -- (192.721pt, -290.837pt) -- (194.322pt, -288.081pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Sends e-mails" & "}") scaled 0.75, (169.241pt, -257.59pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [SMTP]}" & "}") scaled 0.75, (169.241pt, -263.009pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (204.332pt, -290.9pt)
  .. controls (189.852pt, -245.666pt) and (160.891pt, -200.432pt) .. (117.45pt, -155.199pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.319pt; endgroup;
fill (117.229pt, -154.969pt) -- (120.587pt, -156.164pt) -- (118.288pt, -158.372pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Sends e-mails to" & "}") scaled 0.75, (174.68pt, -223.049pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "System Context diagram for Internet Banking System" & "}") scaled 1, (194.999pt, -26.902pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
