\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -37.5pt; pmxx2 := 201.25pt; pmxx3 := 0;
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
fill pmhbox(100.625pt, 2.5pt, 98.75pt, 15pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(100.625pt, 2.5pt, 98.75pt, 15pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "low" & "}") scaled 0.75, (150pt, -10pt), 0, (0,0,0));
fill pmhbox(0.625pt, 2.5pt, 98.75pt, 15pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(0.625pt, 2.5pt, 98.75pt, 15pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "spans rows" & "}") scaled 0.75, (50pt, -10pt), 0, (0,0,0));
fill pmhbox(150.625pt, 20pt, 48.75pt, 15pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(150.625pt, 20pt, 48.75pt, 15pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "spans rows" & "}") scaled 0.75, (175pt, -27.5pt), 0, (0,0,0));
fill pmhbox(100.625pt, 20pt, 48.75pt, 15pt, 0pt) withcolor (0.9373,0.9373,0.9373);
draw pmhbox(100.625pt, 20pt, 48.75pt, 15pt, 0pt) withcolor (0,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "end" & "}") scaled 0.75, (125pt, -27.5pt), 0, (0,0,0));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
