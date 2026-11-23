\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -38.75pt; pmxx2 := 321.25pt; pmxx3 := 0;
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
fill pmhbox(160.625pt, 9.375pt, 156.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(160.625pt, 9.375pt, 156.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "DATA" & "}") scaled 0.75, (239.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "7" & "}") scaled 0.625, (162.188pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "0" & "}") scaled 0.625, (315.938pt, -5.938pt), 0, (0,0,0));
fill pmhbox(80.625pt, 9.375pt, 76.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(80.625pt, 9.375pt, 76.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "TYPE" & "}") scaled 0.75, (119.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "11" & "}") scaled 0.625, (83.75pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "8" & "}") scaled 0.625, (155.938pt, -5.938pt), 0, (0,0,0));
fill pmhbox(60.625pt, 9.375pt, 16.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(60.625pt, 9.375pt, 16.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "EN" & "}") scaled 0.75, (69.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "12" & "}") scaled 0.625, (69.063pt, -5.938pt), 0, (0,0,0));
fill pmhbox(0.625pt, 9.375pt, 56.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(0.625pt, 9.375pt, 56.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "RESERVED" & "}") scaled 0.75, (29.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "15" & "}") scaled 0.625, (3.75pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "13" & "}") scaled 0.625, (54.375pt, -5.938pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
