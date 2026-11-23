\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -199.375pt; pmxx2 := 265.625pt; pmxx3 := 0;
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
fill pmhbox(6.25pt, 6.25pt, 125pt, 186.875pt, 3.125pt) withcolor (0.9098,1,0.7255);
draw pmhbox(6.25pt, 6.25pt, 125pt, 186.875pt, 3.125pt) withcolor (0.9098,1,0.7255) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Todo" & "}") scaled 1, (68.75pt, -12.25pt), 0, (0,0,0));
fill pmhbox(134.375pt, 6.25pt, 125pt, 46.375pt, 3.125pt) withcolor (0.8627,0.7255,1);
draw pmhbox(134.375pt, 6.25pt, 125pt, 46.375pt, 3.125pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Done" & "}") scaled 1, (196.875pt, -12.25pt), 0, (1,1,1));
fill pmhbox(10.938pt, 21.875pt, 115.625pt, 42.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 21.875pt, 115.625pt, 42.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
draw (12.188pt, -23.125pt) -- (12.188pt, -63.125pt) withcolor (1,0.6471,0) withpen pencircle scaled 2.5pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Update Database\\Function" & "}") scaled 1, (53.738pt, -37.125pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "MC-2037" & "}") scaled 1, (35.188pt, -55.125pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "knsv" & "}") scaled 1, (110.713pt, -55.125pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 67.5pt, 115.625pt, 30.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 67.5pt, 115.625pt, 30.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
draw (12.188pt, -68.75pt) -- (12.188pt, -96.75pt) withcolor (0,0,1) withpen pencircle scaled 2.5pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Low one" & "}") scaled 1, (33.688pt, -76.75pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "42" & "}") scaled 1, (22.188pt, -88.75pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 101.125pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 101.125pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Medium one" & "}") scaled 1, (40.887pt, -113.375pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 128.75pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 128.75pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Odd one" & "}") scaled 1, (33.688pt, -141pt), 0, (0.2,0.2,0.2));
fill pmhbox(10.938pt, 156.375pt, 115.625pt, 30.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(10.938pt, 156.375pt, 115.625pt, 30.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
draw (12.188pt, -157.625pt) -- (12.188pt, -185.625pt) withcolor (0.6784,0.8471,0.902) withpen pencircle scaled 2.5pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "From the metadata" & "}") scaled 1, (56.537pt, -165.625pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "knsv" & "}") scaled 1, (110.713pt, -177.625pt), 0, (0.2,0.2,0.2));
fill pmhbox(139.063pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (1,1,1);
draw pmhbox(139.063pt, 21.875pt, 115.625pt, 24.5pt, 3.125pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A {\bf bold} and {\it italic} card" & "}") scaled 1, (194.363pt, -34.125pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
