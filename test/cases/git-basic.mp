\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -181.433pt; pmxx2 := 326.725pt; pmxx3 := 0;
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
draw (71.725pt, -30.063pt) -- (321.725pt, -30.063pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 0.625pt dashed dashpattern(on 1.25pt off 1.25pt);
fill pmhbox(19.4pt, 22.813pt, 30.45pt, 14.5pt, 2.5pt) withcolor (0,0,0.9255);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "main" & "}") scaled 1, (34.625pt, -30.063pt), 0, (1,1,1));
draw (71.725pt, -86.313pt) -- (321.725pt, -86.313pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 0.625pt dashed dashpattern(on 1.25pt off 1.25pt);
fill pmhbox(19.4pt, 79.063pt, 30.45pt, 14.5pt, 2.5pt) withcolor (0.8706,0.8706,0);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "feat" & "}") scaled 1, (34.625pt, -86.313pt), 0, (0,0,0));
draw (71.725pt, -142.563pt) -- (321.725pt, -142.563pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 0.625pt dashed dashpattern(on 1.25pt off 1.25pt);
fill pmhbox(5pt, 135.313pt, 44.85pt, 14.5pt, 2.5pt) withcolor (0.6157,0.9255,0);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "develop" & "}") scaled 1, (27.425pt, -142.563pt), 0, (0,0,0));
begingroup interim linecap := rounded; draw (77.975pt, -30.063pt)
  .. controls (77.975pt, -30.063pt) and (109.225pt, -30.063pt) .. (109.225pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (109.225pt, -30.063pt)
  .. controls (109.225pt, -30.063pt) and (109.225pt, -130.063pt) .. (109.225pt, -130.063pt)
  .. controls (109.225pt, -136.966pt) and (114.821pt, -142.563pt) .. (121.725pt, -142.563pt)
  .. controls (121.725pt, -142.563pt) and (140.475pt, -142.563pt) .. (140.475pt, -142.563pt) withcolor (0.6157,0.9255,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (140.475pt, -142.563pt)
  .. controls (140.475pt, -142.563pt) and (171.725pt, -142.563pt) .. (171.725pt, -142.563pt) withcolor (0.6157,0.9255,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (109.225pt, -30.063pt)
  .. controls (109.225pt, -30.063pt) and (202.975pt, -30.063pt) .. (202.975pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (171.725pt, -142.563pt)
  .. controls (171.725pt, -142.563pt) and (190.475pt, -142.563pt) .. (190.475pt, -142.563pt)
  .. controls (197.379pt, -142.563pt) and (202.975pt, -136.966pt) .. (202.975pt, -130.063pt)
  .. controls (202.975pt, -130.063pt) and (202.975pt, -30.063pt) .. (202.975pt, -30.063pt) withcolor (0.6157,0.9255,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (202.975pt, -30.063pt)
  .. controls (202.975pt, -30.063pt) and (202.975pt, -73.813pt) .. (202.975pt, -73.813pt)
  .. controls (202.975pt, -80.716pt) and (208.571pt, -86.313pt) .. (215.475pt, -86.313pt)
  .. controls (215.475pt, -86.313pt) and (234.225pt, -86.313pt) .. (234.225pt, -86.313pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (202.975pt, -30.063pt)
  .. controls (202.975pt, -30.063pt) and (265.475pt, -30.063pt) .. (265.475pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (140.475pt, -142.563pt)
  .. controls (140.475pt, -142.563pt) and (140.475pt, -81.313pt) .. (140.475pt, -81.313pt)
  .. controls (140.475pt, -77.861pt) and (143.273pt, -75.063pt) .. (146.725pt, -75.063pt)
  .. controls (146.725pt, -75.063pt) and (259.225pt, -75.063pt) .. (259.225pt, -75.063pt)
  .. controls (262.677pt, -75.063pt) and (265.475pt, -72.264pt) .. (265.475pt, -68.813pt)
  .. controls (265.475pt, -68.813pt) and (265.475pt, -30.063pt) .. (265.475pt, -30.063pt) withcolor (0.6157,0.9255,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (265.475pt, -30.063pt)
  .. controls (265.475pt, -30.063pt) and (296.725pt, -30.063pt) .. (296.725pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
fill fullcircle scaled 12.5pt shifted (77.975pt, -30.063pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (77.975pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (109.225pt, -30.063pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (109.225pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill pmhbox(134.225pt, 136.313pt, 12.5pt, 12.5pt, 0pt) withcolor (0.1922,0,0.5725);
draw pmhbox(134.225pt, 136.313pt, 12.5pt, 12.5pt, 0pt) withcolor (0.1922,0,0.5725) withpen pencircle scaled 0.625pt;
fill pmhbox(136.725pt, 138.813pt, 7.5pt, 7.5pt, 0pt) withcolor (0.9255,0.9255,1);
draw pmhbox(136.725pt, 138.813pt, 7.5pt, 7.5pt, 0pt) withcolor (0.9255,0.9255,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (171.725pt, -142.563pt) withcolor (0.6157,0.9255,0);
draw fullcircle scaled 12.5pt shifted (171.725pt, -142.563pt) withcolor (0.6157,0.9255,0) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (202.975pt, -30.063pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (202.975pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
draw (199.85pt, -26.938pt) -- (206.1pt, -33.188pt) withcolor (0.9255,0.9255,1) withpen pencircle scaled 1.875pt;
draw (199.85pt, -33.188pt) -- (206.1pt, -26.938pt) withcolor (0.9255,0.9255,1) withpen pencircle scaled 1.875pt;
fill fullcircle scaled 12.5pt shifted (234.225pt, -86.313pt) withcolor (0.8706,0.8706,0);
draw fullcircle scaled 12.5pt shifted (234.225pt, -86.313pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (265.475pt, -30.063pt) withcolor (0,0,0);
fill fullcircle scaled 3.438pt shifted (263.6pt, -31.313pt) withcolor (1,1,1);
fill fullcircle scaled 3.438pt shifted (267.35pt, -31.313pt) withcolor (1,1,1);
draw (267.35pt, -30.688pt) -- (265.475pt, -26.938pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
draw (263.6pt, -30.688pt) -- (265.475pt, -26.938pt) withcolor (1,1,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (296.725pt, -30.063pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (296.725pt, -30.063pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill (54.817pt, -57.036pt) -- (75.234pt, -36.618pt) -- (82.306pt, -43.689pt) -- (61.888pt, -64.107pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "0-e745ced" & "}") scaled 0.625, (68.561pt, -50.362pt), -45, (0,0,0.1294));
fill (103.214pt, -40.824pt) -- (107.103pt, -36.935pt) -- (114.174pt, -44.006pt) -- (110.285pt, -47.895pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "x" & "}") scaled 0.625, (108.694pt, -42.415pt), -45, (0,0,0.1294));
fill (98.662pt, -19.313pt) -- (98.662pt, -16.813pt) -- (103.662pt, -13.063pt) -- (114.787pt, -13.063pt) -- 
  (114.787pt, -23.063pt) -- (103.662pt, -23.063pt) -- cycle withcolor (0.9255,0.9255,1);
draw (98.662pt, -19.313pt) -- (98.662pt, -16.813pt) -- (103.662pt, -13.063pt) -- (114.787pt, -13.063pt) -- 
  (114.787pt, -23.063pt) -- (103.662pt, -23.063pt) -- cycle withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 1.875pt shifted (101.162pt, -18.063pt) withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "v1" & "}") scaled 0.625, (109.225pt, -17.875pt), 0, (0.0745,0.0745,0));
fill (132.171pt, -155.491pt) -- (138.27pt, -149.392pt) -- (145.341pt, -156.464pt) -- (139.242pt, -162.562pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "d1" & "}") scaled 0.625, (138.756pt, -155.977pt), -45, (0,0,0.1294));
fill (148.75pt, -169.362pt) -- (168.991pt, -149.121pt) -- (176.062pt, -156.192pt) -- (155.821pt, -176.433pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "3-adbfee0" & "}") scaled 0.625, (162.406pt, -162.777pt), -45, (0,0,0.1294));
fill (193.975pt, -19.313pt) -- (193.975pt, -16.813pt) -- (198.975pt, -13.063pt) -- (206.975pt, -13.063pt) -- 
  (206.975pt, -23.063pt) -- (198.975pt, -23.063pt) -- cycle withcolor (0.9255,0.9255,1);
draw (193.975pt, -19.313pt) -- (193.975pt, -16.813pt) -- (198.975pt, -13.063pt) -- (206.975pt, -13.063pt) -- 
  (206.975pt, -23.063pt) -- (198.975pt, -23.063pt) -- cycle withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 1.875pt shifted (196.475pt, -18.063pt) withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "m" & "}") scaled 0.625, (202.975pt, -17.875pt), 0, (0.0745,0.0745,0));
fill (210.975pt, -113.372pt) -- (231.481pt, -92.866pt) -- (238.552pt, -99.937pt) -- (218.046pt, -120.443pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "5-504eb8b" & "}") scaled 0.625, (224.764pt, -106.655pt), -45, (0,0,0.1294));
fill (238.037pt, -19.313pt) -- (238.037pt, -16.813pt) -- (243.037pt, -13.063pt) -- (287.912pt, -13.063pt) -- 
  (287.912pt, -23.063pt) -- (243.037pt, -23.063pt) -- cycle withcolor (0.9255,0.9255,1);
draw (238.037pt, -19.313pt) -- (238.037pt, -16.813pt) -- (243.037pt, -13.063pt) -- (287.912pt, -13.063pt) -- 
  (287.912pt, -23.063pt) -- (243.037pt, -23.063pt) -- cycle withcolor (0.7804,0.7804,0.9451) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 1.875pt shifted (240.537pt, -18.063pt) withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "cherry-pick:d1" & "}") scaled 0.625, (265.475pt, -17.875pt), 0, (0.0745,0.0745,0));
fill (273.567pt, -57.036pt) -- (293.984pt, -36.618pt) -- (301.056pt, -43.689pt) -- (280.638pt, -64.107pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "7-f3c9d3a" & "}") scaled 0.625, (287.311pt, -50.362pt), -45, (0,0,0.1294));
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Example Git diagram" & "}") scaled 1.125, (163.363pt, -11.75pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
