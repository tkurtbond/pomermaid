\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -378.77pt; pmxx2 := 428.75pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (98pt, -98pt)
  .. controls (98pt, -98pt) and (134.75pt, -98pt) .. (134.75pt, -98pt)
  .. controls (134.75pt, -98pt) and (171.5pt, -98pt) .. (171.5pt, -98pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.838pt; endgroup;
begingroup interim linecap := rounded; draw (196pt, -122.5pt)
  .. controls (196pt, -122.5pt) and (196pt, -171.255pt) .. (196pt, -171.255pt)
  .. controls (196pt, -171.255pt) and (196pt, -220.01pt) .. (196pt, -220.01pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.838pt; endgroup;
begingroup interim linecap := rounded; draw (220.5pt, -244.51pt)
  .. controls (220.5pt, -244.51pt) and (275.625pt, -244.51pt) .. (275.625pt, -244.51pt)
  .. controls (275.625pt, -244.51pt) and (330.75pt, -244.51pt) .. (330.75pt, -244.51pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.838pt; endgroup;
fill pmhbox(49pt, 73.5pt, 49pt, 49pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw fullcircle scaled 27.563pt shifted (73.5pt, -98pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (73.5pt, -84.219pt) -- (73.5pt, -111.781pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (59.719pt, -98pt) -- (87.281pt, -98pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (61.097pt, -91.936pt) -- (85.903pt, -91.936pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (61.097pt, -104.064pt) -- (85.903pt, -104.064pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
begingroup interim linecap := rounded; draw (73.494pt, -84.225pt)
  .. controls (64.135pt, -91.024pt) and (64.135pt, -104.976pt) .. (73.494pt, -111.775pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
begingroup interim linecap := rounded; draw (73.506pt, -84.225pt)
  .. controls (82.865pt, -91.024pt) and (82.865pt, -104.976pt) .. (73.506pt, -111.775pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Gateway" & "}") scaled 1, (73.5pt, -128.38pt), 0, (0.2,0.2,0.2));
fill pmhbox(171.5pt, 73.5pt, 49pt, 49pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(182.219pt, 84.219pt, 27.563pt, 27.563pt, 1.225pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (182.219pt, -93.406pt) -- (209.781pt, -93.406pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (182.219pt, -102.594pt) -- (209.781pt, -102.594pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
fill pmhbox(198.297pt, 88.2pt, 7.656pt, 1.225pt, 0.613pt) withcolor (1,1,1);
fill fullcircle scaled 0.919pt shifted (191.406pt, -88.813pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (191.406pt, -88.813pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill fullcircle scaled 0.919pt shifted (188.344pt, -88.813pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (188.344pt, -88.813pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill fullcircle scaled 0.919pt shifted (185.281pt, -88.813pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (185.281pt, -88.813pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill pmhbox(198.297pt, 97.387pt, 7.656pt, 1.225pt, 0.613pt) withcolor (1,1,1);
fill fullcircle scaled 0.919pt shifted (191.406pt, -98pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (191.406pt, -98pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill fullcircle scaled 0.919pt shifted (188.344pt, -98pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (188.344pt, -98pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill fullcircle scaled 0.919pt shifted (185.281pt, -98pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (185.281pt, -98pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill pmhbox(198.297pt, 106.575pt, 7.656pt, 1.225pt, 0.613pt) withcolor (1,1,1);
fill fullcircle scaled 0.919pt shifted (191.406pt, -107.188pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (191.406pt, -107.188pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill fullcircle scaled 0.919pt shifted (188.344pt, -107.188pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (188.344pt, -107.188pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
fill fullcircle scaled 0.919pt shifted (185.281pt, -107.188pt) withcolor (1,1,1);
draw fullcircle scaled 0.919pt shifted (185.281pt, -107.188pt) withcolor (1,1,1) withpen pencircle scaled 0.613pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "App" & "}") scaled 1, (196pt, -128.38pt), 0, (0.2,0.2,0.2));
fill pmhbox(171.5pt, 220.01pt, 49pt, 49pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (183.75pt, -255.449pt)
  .. controls (183.75pt, -257.863pt) and (189.232pt, -259.823pt) .. (196pt, -259.823pt)
  .. controls (202.768pt, -259.823pt) and (208.25pt, -257.863pt) .. (208.25pt, -255.449pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
begingroup interim linecap := rounded; draw (183.75pt, -248.157pt)
  .. controls (183.75pt, -250.571pt) and (189.232pt, -252.531pt) .. (196pt, -252.531pt)
  .. controls (202.768pt, -252.531pt) and (208.25pt, -250.571pt) .. (208.25pt, -248.157pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
begingroup interim linecap := rounded; draw (183.75pt, -240.866pt)
  .. controls (183.75pt, -243.279pt) and (189.232pt, -245.239pt) .. (196pt, -245.239pt)
  .. controls (202.768pt, -245.239pt) and (208.25pt, -243.279pt) .. (208.25pt, -240.866pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
begingroup interim linecap := rounded; draw (208.25pt, -233.571pt)
  .. controls (208.25pt, -235.986pt) and (202.766pt, -237.944pt) .. (196pt, -237.944pt)
  .. controls (189.234pt, -237.944pt) and (183.75pt, -235.986pt) .. (183.75pt, -233.571pt)
  .. controls (183.75pt, -231.156pt) and (189.234pt, -229.198pt) .. (196pt, -229.198pt)
  .. controls (202.766pt, -229.198pt) and (208.25pt, -231.156pt) .. (208.25pt, -233.571pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
draw (183.75pt, -255.449pt) -- (183.75pt, -233.571pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw (208.25pt, -255.449pt) -- (208.25pt, -233.571pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Store" & "}") scaled 1, (196pt, -274.89pt), 0, (0.2,0.2,0.2));
fill pmhbox(330.75pt, 220.01pt, 49pt, 49pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(343pt, 229.198pt, 24.5pt, 30.625pt, 0.613pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw fullcircle scaled 0.98pt shifted (345.45pt, -231.752pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw fullcircle scaled 0.98pt shifted (365.05pt, -231.752pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw fullcircle scaled 0.98pt shifted (345.45pt, -257.268pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
draw fullcircle scaled 0.98pt shifted (365.05pt, -257.268pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt;
begingroup interim linecap := rounded; draw (363.825pt, -240.682pt)
  .. controls (363.825pt, -245.614pt) and (359.986pt, -249.612pt) .. (355.25pt, -249.612pt)
  .. controls (350.514pt, -249.612pt) and (346.675pt, -245.614pt) .. (346.675pt, -240.682pt)
  .. controls (346.675pt, -235.75pt) and (350.514pt, -231.752pt) .. (355.25pt, -231.752pt)
  .. controls (359.986pt, -231.752pt) and (363.825pt, -235.75pt) .. (363.825pt, -240.682pt) withcolor (1,1,1) withpen pencircle scaled 1.225pt; endgroup;
fill fullcircle scaled 4.998pt shifted (355.25pt, -240.682pt) withcolor (1,1,1);
fill (353.725pt, -246.053pt) -- (350.766pt, -254.151pt) -- (350.691pt, -254.302pt) -- (350.588pt, -254.428pt) -- 
  (350.462pt, -254.527pt) -- (350.319pt, -254.597pt) -- (350.165pt, -254.636pt) -- (350.005pt, -254.641pt) -- 
  (349.844pt, -254.611pt) -- (349.688pt, -254.543pt) -- (347.128pt, -253.061pt) -- (346.991pt, -252.96pt) -- 
  (346.885pt, -252.836pt) -- (346.809pt, -252.695pt) -- (346.765pt, -252.543pt) -- (346.754pt, -252.385pt) -- 
  (346.777pt, -252.227pt) -- (346.834pt, -252.074pt) -- (346.926pt, -251.933pt) -- (352.445pt, -245.318pt) -- 
  (352.666pt, -245.133pt) -- (352.913pt, -245.052pt) -- (353.163pt, -245.062pt) -- (353.395pt, -245.151pt) -- 
  (353.589pt, -245.307pt) -- (353.722pt, -245.517pt) -- (353.775pt, -245.771pt) -- (353.725pt, -246.053pt) -- 
  (353.725pt, -246.053pt) -- cycle withcolor (1,1,1);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Backup" & "}") scaled 1, (355.25pt, -274.89pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (24.5pt, -24.5pt)
  .. controls (24.5pt, -24.5pt) and (294pt, -24.5pt) .. (294pt, -24.5pt)
  .. controls (294pt, -24.5pt) and (294pt, -354.27pt) .. (294pt, -354.27pt)
  .. controls (294pt, -354.27pt) and (24.5pt, -354.27pt) .. (24.5pt, -354.27pt)
  .. controls (24.5pt, -354.27pt) and (24.5pt, -24.5pt) .. (24.5pt, -24.5pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.225pt dashed dashpattern(on 4.9pt off 4.9pt); endgroup;
fill pmhbox(25.113pt, 25.113pt, 18.375pt, 18.375pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (40.042pt, -36.023pt)
  .. controls (40.042pt, -36.657pt) and (39.528pt, -37.171pt) .. (38.894pt, -37.171pt)
  .. controls (38.894pt, -37.171pt) and (29.706pt, -37.171pt) .. (29.706pt, -37.171pt)
  .. controls (29.072pt, -37.171pt) and (28.558pt, -36.657pt) .. (28.558pt, -36.023pt)
  .. controls (28.558pt, -35.593pt) and (28.794pt, -35.216pt) .. (29.146pt, -35.021pt)
  .. controls (29.137pt, -34.973pt) and (29.132pt, -34.925pt) .. (29.132pt, -34.874pt)
  .. controls (29.132pt, -34.277pt) and (29.702pt, -33.786pt) .. (30.43pt, -33.733pt)
  .. controls (30.809pt, -32.697pt) and (31.886pt, -31.95pt) .. (33.152pt, -31.95pt)
  .. controls (33.349pt, -31.95pt) and (33.54pt, -31.969pt) .. (33.726pt, -32.003pt)
  .. controls (34.206pt, -31.642pt) and (34.803pt, -31.429pt) .. (35.448pt, -31.429pt)
  .. controls (36.849pt, -31.429pt) and (38.019pt, -32.435pt) .. (38.269pt, -33.765pt)
  .. controls (38.76pt, -33.893pt) and (39.123pt, -34.341pt) .. (39.123pt, -34.874pt)
  .. controls (39.123pt, -34.881pt) and (39.123pt, -34.89pt) .. (39.121pt, -34.897pt)
  .. controls (39.647pt, -35.003pt) and (40.042pt, -35.467pt) .. (40.042pt, -36.023pt)
  .. controls (40.042pt, -36.023pt) and (40.042pt, -36.023pt) .. (40.042pt, -36.023pt) withcolor (1,1,1) withpen pencircle scaled 0.459pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Outer group" & "}") scaled 1, (70.903pt, -34.667pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (122.5pt, -49pt)
  .. controls (122.5pt, -49pt) and (269.5pt, -49pt) .. (269.5pt, -49pt)
  .. controls (269.5pt, -49pt) and (269.5pt, -329.77pt) .. (269.5pt, -329.77pt)
  .. controls (269.5pt, -329.77pt) and (122.5pt, -329.77pt) .. (122.5pt, -329.77pt)
  .. controls (122.5pt, -329.77pt) and (122.5pt, -49pt) .. (122.5pt, -49pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.225pt dashed dashpattern(on 4.9pt off 4.9pt); endgroup;
fill pmhbox(123.113pt, 49.613pt, 18.375pt, 18.375pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(127.132pt, 53.632pt, 10.336pt, 10.336pt, 0.459pt) withcolor (1,1,1) withpen pencircle scaled 0.459pt;
draw (127.132pt, -57.077pt) -- (137.468pt, -57.077pt) withcolor (1,1,1) withpen pencircle scaled 0.459pt;
draw (127.132pt, -60.523pt) -- (137.468pt, -60.523pt) withcolor (1,1,1) withpen pencircle scaled 0.459pt;
fill pmhbox(133.161pt, 55.125pt, 2.871pt, 0.459pt, 0.23pt) withcolor (1,1,1);
fill fullcircle scaled 0.344pt shifted (130.577pt, -55.355pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (130.577pt, -55.355pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill fullcircle scaled 0.344pt shifted (129.429pt, -55.355pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (129.429pt, -55.355pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill fullcircle scaled 0.344pt shifted (128.281pt, -55.355pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (128.281pt, -55.355pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill pmhbox(133.161pt, 58.57pt, 2.871pt, 0.459pt, 0.23pt) withcolor (1,1,1);
fill fullcircle scaled 0.344pt shifted (130.577pt, -58.8pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (130.577pt, -58.8pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill fullcircle scaled 0.344pt shifted (129.429pt, -58.8pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (129.429pt, -58.8pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill fullcircle scaled 0.344pt shifted (128.281pt, -58.8pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (128.281pt, -58.8pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill pmhbox(133.161pt, 62.016pt, 2.871pt, 0.459pt, 0.23pt) withcolor (1,1,1);
fill fullcircle scaled 0.344pt shifted (130.577pt, -62.245pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (130.577pt, -62.245pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill fullcircle scaled 0.344pt shifted (129.429pt, -62.245pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (129.429pt, -62.245pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
fill fullcircle scaled 0.344pt shifted (128.281pt, -62.245pt) withcolor (1,1,1);
draw fullcircle scaled 0.344pt shifted (128.281pt, -62.245pt) withcolor (1,1,1) withpen pencircle scaled 0.23pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Inner" & "}") scaled 1, (155.918pt, -59.167pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (147pt, -195.51pt)
  .. controls (147pt, -195.51pt) and (245pt, -195.51pt) .. (245pt, -195.51pt)
  .. controls (245pt, -195.51pt) and (245pt, -305.27pt) .. (245pt, -305.27pt)
  .. controls (245pt, -305.27pt) and (147pt, -305.27pt) .. (147pt, -305.27pt)
  .. controls (147pt, -305.27pt) and (147pt, -195.51pt) .. (147pt, -195.51pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.225pt dashed dashpattern(on 4.9pt off 4.9pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Deepest" & "}") scaled 1, (166.747pt, -202.615pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (306.25pt, -195.51pt)
  .. controls (306.25pt, -195.51pt) and (404.25pt, -195.51pt) .. (404.25pt, -195.51pt)
  .. controls (404.25pt, -195.51pt) and (404.25pt, -305.27pt) .. (404.25pt, -305.27pt)
  .. controls (404.25pt, -305.27pt) and (306.25pt, -305.27pt) .. (306.25pt, -305.27pt)
  .. controls (306.25pt, -305.27pt) and (306.25pt, -195.51pt) .. (306.25pt, -195.51pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 1.225pt dashed dashpattern(on 4.9pt off 4.9pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Other side" & "}") scaled 1, (331.926pt, -202.615pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
