\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -78.725pt; pmxx2 := 429.637pt; pmxx3 := 0;
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
fill pmhbox(0.419pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(0.419pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Source Port" & "}") scaled 0.75, (106.572pt, -12.981pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "0" & "}") scaled 0.625, (1.466pt, -3.978pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "15" & "}") scaled 0.625, (210.631pt, -3.978pt), 0, (0,0,0));
fill pmhbox(214.819pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(214.819pt, 6.281pt, 212.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Destination Port" & "}") scaled 0.75, (320.972pt, -12.981pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "16" & "}") scaled 0.625, (216.913pt, -3.978pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "31" & "}") scaled 0.625, (425.031pt, -3.978pt), 0, (0,0,0));
fill pmhbox(0.419pt, 25.963pt, 212.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(0.419pt, 25.963pt, 212.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Length" & "}") scaled 0.75, (106.572pt, -32.662pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "32" & "}") scaled 0.625, (2.513pt, -23.659pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "47" & "}") scaled 0.625, (210.631pt, -23.659pt), 0, (0,0,0));
fill pmhbox(214.819pt, 25.963pt, 212.306pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(214.819pt, 25.963pt, 212.306pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Checksum" & "}") scaled 0.75, (320.972pt, -32.662pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "48" & "}") scaled 0.625, (216.913pt, -23.659pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "63" & "}") scaled 0.625, (425.031pt, -23.659pt), 0, (0,0,0));
fill pmhbox(0.419pt, 45.644pt, 426.706pt, 13.4pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(0.419pt, 45.644pt, 426.706pt, 13.4pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.419pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Data (variable length)" & "}") scaled 0.75, (213.772pt, -52.344pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "64" & "}") scaled 0.625, (2.513pt, -43.341pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "95" & "}") scaled 0.625, (425.031pt, -43.341pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "UDP Packet" & "}") scaled 0.875, (214.819pt, -68.884pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
