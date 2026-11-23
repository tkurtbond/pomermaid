\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -16.25pt; pmxx2 := 16.25pt; pmxx3 := 0;
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
fill pmhbox(3.125pt, 3.125pt, 10pt, 10pt, 0pt) withcolor (1,1,0.9373);
draw pmhbox(3.125pt, 3.125pt, 10pt, 10pt, 0pt) withcolor (0.9333,0.9333,0.8392) withpen pencircle scaled 0.625pt;
fill pmhbox(8.125pt, 8.125pt, 0pt, 0pt, 0pt) withcolor (1,1,0.9373);
draw pmhbox(8.125pt, 8.125pt, 0pt, 0pt, 0pt) withcolor (0.9333,0.9333,0.8392) withpen pencircle scaled 0.625pt;
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
