\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -66.15pt; pmxx2 := 428.985pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (196.093pt, -33.075pt)
  .. controls (178.21pt, -33.075pt) and (178.21pt, -18.007pt) .. (160.328pt, -18.007pt) withcolor (1,1,0.4706) withpen pencircle scaled 3.369pt; endgroup;
begingroup interim linecap := rounded; draw (160.328pt, -18.007pt)
  .. controls (136.771pt, -18.007pt) and (136.771pt, -7.534pt) .. (113.214pt, -7.534pt) withcolor (1,1,0.4706) withpen pencircle scaled 1.531pt; endgroup;
begingroup interim linecap := rounded; draw (160.328pt, -18.007pt)
  .. controls (135.313pt, -18.007pt) and (135.313pt, -25.541pt) .. (110.299pt, -25.541pt) withcolor (1,1,0.4706) withpen pencircle scaled 1.531pt; endgroup;
begingroup interim linecap := rounded; draw (110.299pt, -25.541pt)
  .. controls (74.676pt, -25.541pt) and (74.676pt, -25.541pt) .. (39.053pt, -25.541pt) withcolor (1,1,0.4706) withpen pencircle scaled 0.919pt; endgroup;
begingroup interim linecap := rounded; draw (196.093pt, -33.075pt)
  .. controls (214.563pt, -33.075pt) and (214.563pt, -33.075pt) .. (233.034pt, -33.075pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 3.369pt; endgroup;
begingroup interim linecap := rounded; draw (233.034pt, -33.075pt)
  .. controls (259.53pt, -33.075pt) and (259.53pt, -10.474pt) .. (286.027pt, -10.474pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 1.531pt; endgroup;
begingroup interim linecap := rounded; draw (233.034pt, -33.075pt)
  .. controls (262.397pt, -33.075pt) and (262.397pt, -43.549pt) .. (291.76pt, -43.549pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 1.531pt; endgroup;
begingroup interim linecap := rounded; draw (291.76pt, -43.549pt)
  .. controls (318.771pt, -43.549pt) and (318.771pt, -43.549pt) .. (345.782pt, -43.549pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 0.919pt; endgroup;
begingroup interim linecap := rounded; draw (345.782pt, -43.549pt)
  .. controls (371.691pt, -43.549pt) and (371.691pt, -28.481pt) .. (397.6pt, -28.481pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 0.919pt; endgroup;
begingroup interim linecap := rounded; draw (345.782pt, -43.549pt)
  .. controls (371.103pt, -43.549pt) and (371.103pt, -43.549pt) .. (396.424pt, -43.549pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 0.919pt; endgroup;
begingroup interim linecap := rounded; draw (345.782pt, -43.549pt)
  .. controls (369.927pt, -43.549pt) and (369.927pt, -58.616pt) .. (394.072pt, -58.616pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 0.919pt; endgroup;
begingroup interim linecap := rounded; draw (196.093pt, -33.075pt)
  .. controls (179.386pt, -33.075pt) and (179.386pt, -51.082pt) .. (162.68pt, -51.082pt) withcolor (0.7608,0.5255,1) withpen pencircle scaled 3.369pt; endgroup;
begingroup interim linecap := rounded; draw (162.68pt, -51.082pt)
  .. controls (139.993pt, -51.082pt) and (139.993pt, -43.549pt) .. (117.306pt, -43.549pt) withcolor (0.7608,0.5255,1) withpen pencircle scaled 1.531pt; endgroup;
begingroup interim linecap := rounded; draw (162.68pt, -51.082pt)
  .. controls (142.958pt, -51.082pt) and (142.958pt, -58.616pt) .. (123.235pt, -58.616pt) withcolor (0.7608,0.5255,1) withpen pencircle scaled 1.531pt; endgroup;
fill fullcircle scaled 23.607pt shifted (196.093pt, -33.075pt) withcolor (0,0,0.9255);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "mindmap" & "}") scaled 1, (196.093pt, -33.075pt), 0, (1,1,1));
fill pmhbox(145.555pt, 13.536pt, 29.547pt, 8.943pt, 1.531pt) withcolor (1,1,0.4706);
draw (145.555pt, -22.479pt) -- (175.102pt, -22.479pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Origins" & "}") scaled 1, (160.328pt, -18.007pt), 0, (0,0,0));
fill pmhbox(93.125pt, 3.063pt, 40.18pt, 8.943pt, 1.531pt) withcolor (1,1,0.4706);
draw (93.125pt, -12.005pt) -- (133.305pt, -12.005pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Long history" & "}") scaled 1, (113.214pt, -7.534pt), 0, (0,0,0));
fill pmhbox(87.294pt, 21.07pt, 46.011pt, 8.943pt, 1.531pt) withcolor (1,1,0.4706);
draw (87.294pt, -30.012pt) -- (133.305pt, -30.012pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Popularisation" & "}") scaled 1, (110.299pt, -25.541pt), 0, (0,0,0));
fill pmhbox(3.063pt, 18.13pt, 71.981pt, 14.823pt, 1.531pt) withcolor (1,1,0.4706);
draw (3.063pt, -32.952pt) -- (75.044pt, -32.952pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "British popular psychology\\author Tony Buzan" & "}") scaled 1, (39.053pt, -25.541pt), 0, (0,0,0));
fill pmhbox(217.084pt, 28.604pt, 31.899pt, 8.943pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (217.084pt, -37.546pt) -- (248.983pt, -37.546pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Research" & "}") scaled 1, (233.034pt, -33.075pt), 0, (0,0,0));
fill pmhbox(261.233pt, 3.063pt, 49.588pt, 14.823pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (261.233pt, -17.885pt) -- (310.821pt, -17.885pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "On effectiveness\\and features" & "}") scaled 1, (286.027pt, -10.474pt), 0, (0,0,0));
fill pmhbox(261.233pt, 39.077pt, 61.054pt, 8.943pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (261.233pt, -48.02pt) -- (322.287pt, -48.02pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "On Automatic creation" & "}") scaled 1, (291.76pt, -43.549pt), 0, (0,0,0));
fill pmhbox(334.537pt, 39.077pt, 22.491pt, 8.943pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (334.537pt, -48.02pt) -- (357.028pt, -48.02pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 1, (345.782pt, -43.549pt), 0, (0,0,0));
fill pmhbox(369.278pt, 24.01pt, 56.644pt, 8.943pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (369.278pt, -32.952pt) -- (425.922pt, -32.952pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Creative techniques" & "}") scaled 1, (397.6pt, -28.481pt), 0, (0,0,0));
fill pmhbox(369.278pt, 39.077pt, 54.292pt, 8.943pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (369.278pt, -48.02pt) -- (423.57pt, -48.02pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Strategic planning" & "}") scaled 1, (396.424pt, -43.549pt), 0, (0,0,0));
fill pmhbox(369.278pt, 54.145pt, 49.588pt, 8.943pt, 1.531pt) withcolor (0.8431,1,0.5255);
draw (369.278pt, -63.087pt) -- (418.866pt, -63.087pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Argument mapping" & "}") scaled 1, (394.072pt, -58.616pt), 0, (0,0,0));
fill pmhbox(150.259pt, 46.611pt, 24.843pt, 8.943pt, 1.531pt) withcolor (0.7608,0.5255,1);
draw (150.259pt, -55.554pt) -- (175.102pt, -55.554pt) withcolor (0.8627,1,0.7255) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Tools" & "}") scaled 1, (162.68pt, -51.082pt), 0, (1,1,1));
fill pmhbox(96.604pt, 39.077pt, 41.405pt, 8.943pt, 1.531pt) withcolor (0.7608,0.5255,1);
draw (96.604pt, -48.02pt) -- (138.009pt, -48.02pt) withcolor (0.8627,1,0.7255) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Pen and paper" & "}") scaled 1, (117.306pt, -43.549pt), 0, (1,1,1));
fill pmhbox(108.462pt, 54.145pt, 29.547pt, 8.943pt, 1.531pt) withcolor (0.7608,0.5255,1);
draw (108.462pt, -63.087pt) -- (138.009pt, -63.087pt) withcolor (0.8627,1,0.7255) withpen pencircle scaled 0.919pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Mermaid" & "}") scaled 1, (123.235pt, -58.616pt), 0, (1,1,1));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
