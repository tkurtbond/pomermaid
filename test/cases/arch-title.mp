\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -117.75pt; pmxx2 := 220.675pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (68.75pt, -46.875pt)
  .. controls (68.75pt, -46.875pt) and (106.25pt, -46.875pt) .. (106.25pt, -46.875pt)
  .. controls (106.25pt, -46.875pt) and (143.75pt, -46.875pt) .. (143.75pt, -46.875pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 1.875pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "quoted edge" & "}") scaled 1, (106.25pt, -52.875pt), 0, (0.2,0.2,0.2));
fill pmhbox(25pt, 25pt, 43.75pt, 43.75pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(34.57pt, 34.57pt, 24.609pt, 24.609pt, 1.094pt) withcolor (1,1,1) withpen pencircle scaled 1.094pt;
draw (34.57pt, -42.773pt) -- (59.18pt, -42.773pt) withcolor (1,1,1) withpen pencircle scaled 1.094pt;
draw (34.57pt, -50.977pt) -- (59.18pt, -50.977pt) withcolor (1,1,1) withpen pencircle scaled 1.094pt;
fill pmhbox(48.926pt, 38.125pt, 6.836pt, 1.094pt, 0.547pt) withcolor (1,1,1);
fill fullcircle scaled 0.82pt shifted (42.773pt, -38.672pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (42.773pt, -38.672pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill fullcircle scaled 0.82pt shifted (40.039pt, -38.672pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (40.039pt, -38.672pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill fullcircle scaled 0.82pt shifted (37.305pt, -38.672pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (37.305pt, -38.672pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill pmhbox(48.926pt, 46.328pt, 6.836pt, 1.094pt, 0.547pt) withcolor (1,1,1);
fill fullcircle scaled 0.82pt shifted (42.773pt, -46.875pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (42.773pt, -46.875pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill fullcircle scaled 0.82pt shifted (40.039pt, -46.875pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (40.039pt, -46.875pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill fullcircle scaled 0.82pt shifted (37.305pt, -46.875pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (37.305pt, -46.875pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill pmhbox(48.926pt, 54.531pt, 6.836pt, 1.094pt, 0.547pt) withcolor (1,1,1);
fill fullcircle scaled 0.82pt shifted (42.773pt, -55.078pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (42.773pt, -55.078pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill fullcircle scaled 0.82pt shifted (40.039pt, -55.078pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (40.039pt, -55.078pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
fill fullcircle scaled 0.82pt shifted (37.305pt, -55.078pt) withcolor (1,1,1);
draw fullcircle scaled 0.82pt shifted (37.305pt, -55.078pt) withcolor (1,1,1) withpen pencircle scaled 0.547pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Quoted\\{\char34}title{\char34}" & "}") scaled 1, (46.875pt, -80.75pt), 0, (0.2,0.2,0.2));
fill pmhbox(143.75pt, 25pt, 43.75pt, 43.75pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (179.297pt, -50.977pt)
  .. controls (179.297pt, -52.486pt) and (178.072pt, -53.711pt) .. (176.563pt, -53.711pt)
  .. controls (176.563pt, -53.711pt) and (154.688pt, -53.711pt) .. (154.688pt, -53.711pt)
  .. controls (153.178pt, -53.711pt) and (151.953pt, -52.486pt) .. (151.953pt, -50.977pt)
  .. controls (151.953pt, -49.954pt) and (152.516pt, -49.057pt) .. (153.353pt, -48.592pt)
  .. controls (153.331pt, -48.477pt) and (153.32pt, -48.363pt) .. (153.32pt, -48.242pt)
  .. controls (153.32pt, -46.82pt) and (154.677pt, -45.65pt) .. (156.41pt, -45.524pt)
  .. controls (157.313pt, -43.058pt) and (159.877pt, -41.281pt) .. (162.891pt, -41.281pt)
  .. controls (163.361pt, -41.281pt) and (163.815pt, -41.324pt) .. (164.258pt, -41.406pt)
  .. controls (165.401pt, -40.548pt) and (166.823pt, -40.039pt) .. (168.359pt, -40.039pt)
  .. controls (171.695pt, -40.039pt) and (174.479pt, -42.434pt) .. (175.075pt, -45.601pt)
  .. controls (176.245pt, -45.907pt) and (177.109pt, -46.973pt) .. (177.109pt, -48.242pt)
  .. controls (177.109pt, -48.259pt) and (177.109pt, -48.281pt) .. (177.104pt, -48.297pt)
  .. controls (178.356pt, -48.548pt) and (179.297pt, -49.653pt) .. (179.297pt, -50.977pt)
  .. controls (179.297pt, -50.977pt) and (179.297pt, -50.977pt) .. (179.297pt, -50.977pt) withcolor (1,1,1) withpen pencircle scaled 1.094pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "single quoted" & "}") scaled 1, (165.625pt, -74.75pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
