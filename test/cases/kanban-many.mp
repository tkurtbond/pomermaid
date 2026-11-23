\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -15.896pt; pmxx2 := 417.656pt; pmxx3 := 0;
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
fill pmhbox(1.688pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.9098,1,0.7255);
draw pmhbox(1.688pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.9098,1,0.7255) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 1" & "}") scaled 1, (18.563pt, -3.307pt), 0, (0,0,0));
fill pmhbox(36.281pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.8627,0.7255,1);
draw pmhbox(36.281pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 2" & "}") scaled 1, (53.156pt, -3.307pt), 0, (1,1,1));
fill pmhbox(70.875pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.7255,1);
draw pmhbox(70.875pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.7255,1) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 3" & "}") scaled 1, (87.75pt, -3.307pt), 0, (0,0,0));
fill pmhbox(105.469pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.7255,0.8627);
draw pmhbox(105.469pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.7255,0.8627) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 4" & "}") scaled 1, (122.344pt, -3.307pt), 0, (0,0,0));
fill pmhbox(140.063pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.7255,0.7255);
draw pmhbox(140.063pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.7255,0.7255) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 5" & "}") scaled 1, (156.938pt, -3.307pt), 0, (0,0,0));
fill pmhbox(174.656pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.8627,0.7255);
draw pmhbox(174.656pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (1,0.8627,0.7255) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 6" & "}") scaled 1, (191.531pt, -3.307pt), 0, (0,0,0));
fill pmhbox(209.25pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.8627,1,0.7255);
draw pmhbox(209.25pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.8627,1,0.7255) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 7" & "}") scaled 1, (226.125pt, -3.307pt), 0, (0,0,0));
fill pmhbox(243.844pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.7255,1,0.8627);
draw pmhbox(243.844pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.7255,1,0.8627) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 8" & "}") scaled 1, (260.719pt, -3.307pt), 0, (0,0,0));
fill pmhbox(278.438pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.7255,1,1);
draw pmhbox(278.438pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.7255,1,1) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 9" & "}") scaled 1, (295.313pt, -3.307pt), 0, (0,0,0));
fill pmhbox(313.031pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.7255,0.8627,1);
draw pmhbox(313.031pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.7255,0.8627,1) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 10" & "}") scaled 1, (329.906pt, -3.307pt), 0, (0,0,0));
fill pmhbox(347.625pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.9098,1,0.7255);
draw pmhbox(347.625pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.9098,1,0.7255) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 11" & "}") scaled 1, (364.5pt, -3.307pt), 0, (0,0,0));
fill pmhbox(382.219pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.8627,0.7255,1);
draw pmhbox(382.219pt, 1.688pt, 33.75pt, 12.521pt, 0.844pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Section 12" & "}") scaled 1, (399.094pt, -3.307pt), 0, (1,1,1));
fill pmhbox(2.953pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(2.953pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 1" & "}") scaled 1, (8.475pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(37.547pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(37.547pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 2" & "}") scaled 1, (43.068pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(72.141pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(72.141pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 3" & "}") scaled 1, (77.662pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(106.734pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(106.734pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 4" & "}") scaled 1, (112.256pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(141.328pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(141.328pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 5" & "}") scaled 1, (146.85pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(175.922pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(175.922pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 6" & "}") scaled 1, (181.443pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(210.516pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(210.516pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 7" & "}") scaled 1, (216.037pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(245.109pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(245.109pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 8" & "}") scaled 1, (250.631pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(279.703pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(279.703pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 9" & "}") scaled 1, (285.225pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(314.297pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(314.297pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 10" & "}") scaled 1, (320.493pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(348.891pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(348.891pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 11" & "}") scaled 1, (355.087pt, -9.214pt), 0, (0.2,0.2,0.2));
fill pmhbox(383.484pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (1,1,1);
draw pmhbox(383.484pt, 5.906pt, 31.219pt, 6.615pt, 0.844pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.169pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Item 12" & "}") scaled 1, (389.681pt, -9.214pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
