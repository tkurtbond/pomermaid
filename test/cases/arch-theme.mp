\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -96.5pt; pmxx2 := 162.5pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (62.5pt, -43.75pt)
  .. controls (62.5pt, -43.75pt) and (81.25pt, -43.75pt) .. (81.25pt, -43.75pt)
  .. controls (81.25pt, -43.75pt) and (100pt, -43.75pt) .. (100pt, -43.75pt) withcolor (0.6667,0.2,0) withpen pencircle scaled 1.875pt; endgroup;
fill (101.25pt, -43.75pt) -- (95pt, -46.875pt) -- (95pt, -40.625pt) -- cycle withcolor (0,0,1);
fill pmhbox(25pt, 25pt, 37.5pt, 37.5pt, 0pt) withcolor (0.0314,0.4941,0.749);
draw pmhbox(33.203pt, 33.203pt, 21.094pt, 21.094pt, 0.938pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt;
draw (33.203pt, -40.234pt) -- (54.297pt, -40.234pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt;
draw (33.203pt, -47.266pt) -- (54.297pt, -47.266pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt;
fill pmhbox(45.508pt, 36.25pt, 5.859pt, 0.938pt, 0.469pt) withcolor (1,1,1);
fill fullcircle scaled 0.703pt shifted (40.234pt, -36.719pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (40.234pt, -36.719pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill fullcircle scaled 0.703pt shifted (37.891pt, -36.719pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (37.891pt, -36.719pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill fullcircle scaled 0.703pt shifted (35.547pt, -36.719pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (35.547pt, -36.719pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill pmhbox(45.508pt, 43.281pt, 5.859pt, 0.938pt, 0.469pt) withcolor (1,1,1);
fill fullcircle scaled 0.703pt shifted (40.234pt, -43.75pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (40.234pt, -43.75pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill fullcircle scaled 0.703pt shifted (37.891pt, -43.75pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (37.891pt, -43.75pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill fullcircle scaled 0.703pt shifted (35.547pt, -43.75pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (35.547pt, -43.75pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill pmhbox(45.508pt, 50.313pt, 5.859pt, 0.938pt, 0.469pt) withcolor (1,1,1);
fill fullcircle scaled 0.703pt shifted (40.234pt, -50.781pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (40.234pt, -50.781pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill fullcircle scaled 0.703pt shifted (37.891pt, -50.781pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (37.891pt, -50.781pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
fill fullcircle scaled 0.703pt shifted (35.547pt, -50.781pt) withcolor (1,1,1);
draw fullcircle scaled 0.703pt shifted (35.547pt, -50.781pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Small A" & "}") scaled 0.75, (43.75pt, -67pt), 0, (0.2,0.2,0.2));
fill pmhbox(100pt, 25pt, 37.5pt, 37.5pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (109.375pt, -52.122pt)
  .. controls (109.375pt, -53.969pt) and (113.57pt, -55.469pt) .. (118.75pt, -55.469pt)
  .. controls (123.93pt, -55.469pt) and (128.125pt, -53.969pt) .. (128.125pt, -52.122pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt; endgroup;
begingroup interim linecap := rounded; draw (109.375pt, -46.541pt)
  .. controls (109.375pt, -48.388pt) and (113.57pt, -49.888pt) .. (118.75pt, -49.888pt)
  .. controls (123.93pt, -49.888pt) and (128.125pt, -48.388pt) .. (128.125pt, -46.541pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt; endgroup;
begingroup interim linecap := rounded; draw (109.375pt, -40.961pt)
  .. controls (109.375pt, -42.808pt) and (113.57pt, -44.308pt) .. (118.75pt, -44.308pt)
  .. controls (123.93pt, -44.308pt) and (128.125pt, -42.808pt) .. (128.125pt, -40.961pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt; endgroup;
begingroup interim linecap := rounded; draw (128.125pt, -35.378pt)
  .. controls (128.125pt, -37.227pt) and (123.928pt, -38.725pt) .. (118.75pt, -38.725pt)
  .. controls (113.572pt, -38.725pt) and (109.375pt, -37.227pt) .. (109.375pt, -35.378pt)
  .. controls (109.375pt, -33.53pt) and (113.572pt, -32.031pt) .. (118.75pt, -32.031pt)
  .. controls (123.928pt, -32.031pt) and (128.125pt, -33.53pt) .. (128.125pt, -35.378pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt; endgroup;
draw (109.375pt, -52.122pt) -- (109.375pt, -35.378pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt;
draw (128.125pt, -52.122pt) -- (128.125pt, -35.378pt) withcolor (1,1,1) withpen pencircle scaled 0.938pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Small B" & "}") scaled 0.75, (118.75pt, -67pt), 0, (0.2,0.2,0.2));
begingroup interim linecap := rounded; draw (12.5pt, -12.5pt)
  .. controls (12.5pt, -12.5pt) and (150pt, -12.5pt) .. (150pt, -12.5pt)
  .. controls (150pt, -12.5pt) and (150pt, -84pt) .. (150pt, -84pt)
  .. controls (150pt, -84pt) and (12.5pt, -84pt) .. (12.5pt, -84pt)
  .. controls (12.5pt, -84pt) and (12.5pt, -12.5pt) .. (12.5pt, -12.5pt) withcolor (0,0.6667,0) withpen pencircle scaled 1.25pt dashed dashpattern(on 5pt off 5pt); endgroup;
fill pmhbox(13.125pt, 13.125pt, 18.75pt, 18.75pt, 0pt) withcolor (0.0314,0.4941,0.749);
begingroup interim linecap := rounded; draw (28.359pt, -24.258pt)
  .. controls (28.359pt, -24.905pt) and (27.834pt, -25.43pt) .. (27.188pt, -25.43pt)
  .. controls (27.188pt, -25.43pt) and (17.813pt, -25.43pt) .. (17.813pt, -25.43pt)
  .. controls (17.166pt, -25.43pt) and (16.641pt, -24.905pt) .. (16.641pt, -24.258pt)
  .. controls (16.641pt, -23.82pt) and (16.882pt, -23.435pt) .. (17.241pt, -23.236pt)
  .. controls (17.231pt, -23.187pt) and (17.227pt, -23.137pt) .. (17.227pt, -23.086pt)
  .. controls (17.227pt, -22.477pt) and (17.808pt, -21.975pt) .. (18.551pt, -21.921pt)
  .. controls (18.938pt, -20.864pt) and (20.037pt, -20.102pt) .. (21.328pt, -20.102pt)
  .. controls (21.53pt, -20.102pt) and (21.724pt, -20.121pt) .. (21.914pt, -20.156pt)
  .. controls (22.404pt, -19.788pt) and (23.013pt, -19.57pt) .. (23.672pt, -19.57pt)
  .. controls (25.102pt, -19.57pt) and (26.295pt, -20.597pt) .. (26.55pt, -21.954pt)
  .. controls (27.052pt, -22.085pt) and (27.422pt, -22.542pt) .. (27.422pt, -23.086pt)
  .. controls (27.422pt, -23.093pt) and (27.422pt, -23.102pt) .. (27.42pt, -23.109pt)
  .. controls (27.956pt, -23.217pt) and (28.359pt, -23.691pt) .. (28.359pt, -24.258pt)
  .. controls (28.359pt, -24.258pt) and (28.359pt, -24.258pt) .. (28.359pt, -24.258pt) withcolor (1,1,1) withpen pencircle scaled 0.469pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Themed" & "}") scaled 0.75, (45.188pt, -21.375pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
