\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -92.535pt; pmxx2 := 431.296pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (318.227pt, -46.268pt)
  .. controls (292.383pt, -46.268pt) and (292.383pt, -33.131pt) .. (266.538pt, -33.131pt) withcolor (1,1,0.4706) withpen pencircle scaled 6.394pt; endgroup;
begingroup interim linecap := rounded; draw (266.538pt, -33.131pt)
  .. controls (243.753pt, -33.131pt) and (243.753pt, -33.131pt) .. (220.968pt, -33.131pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 2.906pt; endgroup;
begingroup interim linecap := rounded; draw (220.968pt, -33.131pt)
  .. controls (195.858pt, -33.131pt) and (195.858pt, -33.131pt) .. (170.748pt, -33.131pt) withcolor (0.7608,0.5255,1) withpen pencircle scaled 1.744pt; endgroup;
begingroup interim linecap := rounded; draw (170.748pt, -33.131pt)
  .. controls (143.313pt, -33.131pt) and (143.313pt, -33.131pt) .. (115.878pt, -33.131pt) withcolor (1,0.5255,1) withpen pencircle scaled 1.744pt; endgroup;
begingroup interim linecap := rounded; draw (115.878pt, -33.131pt)
  .. controls (77.725pt, -33.131pt) and (77.725pt, -33.131pt) .. (39.572pt, -33.131pt) withcolor (1,0.5255,0.7647) withpen pencircle scaled 1.744pt; endgroup;
begingroup interim linecap := rounded; draw (318.227pt, -46.268pt)
  .. controls (344.072pt, -46.268pt) and (344.072pt, -46.268pt) .. (369.916pt, -46.268pt) withcolor (1,1,0.4706) withpen pencircle scaled 6.394pt; endgroup;
begingroup interim linecap := rounded; draw (369.916pt, -46.268pt)
  .. controls (392.701pt, -46.268pt) and (392.701pt, -33.131pt) .. (415.486pt, -33.131pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 2.906pt; endgroup;
begingroup interim linecap := rounded; draw (369.916pt, -46.268pt)
  .. controls (392.701pt, -46.268pt) and (392.701pt, -59.404pt) .. (415.486pt, -59.404pt) withcolor (0.8431,1,0.5255) withpen pencircle scaled 2.906pt; endgroup;
begingroup interim linecap := rounded; draw (318.227pt, -46.268pt)
  .. controls (292.383pt, -46.268pt) and (292.383pt, -81.724pt) .. (266.538pt, -81.724pt) withcolor (1,1,0.4706) withpen pencircle scaled 6.394pt; endgroup;
fill fullcircle scaled 48.508pt shifted (318.227pt, -46.268pt) withcolor (0,0,0.9255);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "The root" & "}") scaled 1, (318.227pt, -46.268pt), 0, (1,1,1));
fill pmhbox(256.541pt, 25.808pt, 19.995pt, 14.647pt, 2.906pt) withcolor (1,1,0.4706);
draw (256.541pt, -40.455pt) -- (276.536pt, -40.455pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A" & "}") scaled 1, (266.538pt, -33.131pt), 0, (0,0,0));
fill pmhbox(208.646pt, 25.808pt, 24.645pt, 14.647pt, 2.906pt) withcolor (0.8431,1,0.5255);
draw (208.646pt, -40.455pt) -- (233.291pt, -40.455pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A1" & "}") scaled 1, (220.968pt, -33.131pt), 0, (0,0,0));
fill pmhbox(156.101pt, 25.808pt, 29.295pt, 14.647pt, 2.906pt) withcolor (0.7608,0.5255,1);
draw (156.101pt, -40.455pt) -- (185.396pt, -40.455pt) withcolor (0.8627,1,0.7255) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A11" & "}") scaled 1, (170.748pt, -33.131pt), 0, (1,1,1));
fill pmhbox(98.906pt, 25.808pt, 33.945pt, 14.647pt, 2.906pt) withcolor (1,0.5255,1);
draw (98.906pt, -40.455pt) -- (132.851pt, -40.455pt) withcolor (0.7255,1,0.7255) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A111" & "}") scaled 1, (115.878pt, -33.131pt), 0, (0,0,0));
fill pmhbox(3.488pt, 3.488pt, 72.168pt, 59.287pt, 2.906pt) withcolor (1,0.5255,0.7647);
draw (3.488pt, -62.775pt) -- (75.656pt, -62.775pt) withcolor (0.7255,1,0.8627) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A1111 with a\\label long\\enough to wrap\\twice at this\\width" & "}") scaled 1, (39.572pt, -33.131pt), 0, (0,0,0));
fill pmhbox(359.918pt, 38.944pt, 19.995pt, 14.647pt, 2.906pt) withcolor (1,1,0.4706);
draw (359.918pt, -53.591pt) -- (379.913pt, -53.591pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B" & "}") scaled 1, (369.916pt, -46.268pt), 0, (0,0,0));
fill pmhbox(403.163pt, 25.808pt, 24.645pt, 14.647pt, 2.906pt) withcolor (0.8431,1,0.5255);
draw (403.163pt, -40.455pt) -- (427.808pt, -40.455pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B1" & "}") scaled 1, (415.486pt, -33.131pt), 0, (0,0,0));
fill pmhbox(403.163pt, 52.08pt, 24.645pt, 14.647pt, 2.906pt) withcolor (0.8431,1,0.5255);
draw (403.163pt, -66.728pt) -- (427.808pt, -66.728pt) withcolor (0.8157,0.7255,1) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "B2" & "}") scaled 1, (415.486pt, -59.404pt), 0, (0,0,0));
fill pmhbox(256.541pt, 74.4pt, 19.995pt, 14.647pt, 2.906pt) withcolor (1,1,0.4706);
draw (256.541pt, -89.048pt) -- (276.536pt, -89.048pt) withcolor (0.6706,0.6706,1) withpen pencircle scaled 1.744pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "C" & "}") scaled 1, (266.538pt, -81.724pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
