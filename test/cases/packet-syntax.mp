\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -58.75pt; pmxx2 := 321.25pt; pmxx3 := 0;
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
fill pmhbox(0.625pt, 9.375pt, 76.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(0.625pt, 9.375pt, 76.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "a {\char34}quoted{\char34} label" & "}") scaled 0.75, (39.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "0" & "}") scaled 0.625, (2.188pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "3" & "}") scaled 0.625, (75.938pt, -5.938pt), 0, (0,0,0));
fill pmhbox(80.625pt, 9.375pt, 76.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(80.625pt, 9.375pt, 76.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "single 'quotes' and {\char92}" & "}") scaled 0.75, (119.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "4" & "}") scaled 0.625, (82.188pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "7" & "}") scaled 0.625, (155.938pt, -5.938pt), 0, (0,0,0));
fill pmhbox(160.625pt, 9.375pt, 16.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(160.625pt, 9.375pt, 16.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "a b c" & "}") scaled 0.75, (169.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "8" & "}") scaled 0.625, (169.063pt, -5.938pt), 0, (0,0,0));
fill pmhbox(180.625pt, 9.375pt, 136.875pt, 20pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(180.625pt, 9.375pt, 136.875pt, 20pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "spans lines" & "}") scaled 0.75, (249.063pt, -19.375pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "9" & "}") scaled 0.625, (182.188pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "15" & "}") scaled 0.625, (314.375pt, -5.938pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "The title" & "}") scaled 0.875, (160.625pt, -44.063pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
