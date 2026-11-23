\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -314.964pt; pmxx2 := 131.149pt; pmxx3 := 0;
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
draw (38.499pt, -23.75pt) -- (38.499pt, -305pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 0.625pt dashed dashpattern(on 1.25pt off 1.25pt);
fill pmhbox(22.649pt, 5pt, 30.45pt, 14.5pt, 2.5pt) withcolor (0,0,0.9255);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "main" & "}") scaled 1, (35.374pt, -11.5pt), 0, (1,1,1));
draw (104.349pt, -23.75pt) -- (104.349pt, -305pt) withcolor (0.2,0.2,0.2) withpen pencircle scaled 0.625pt dashed dashpattern(on 1.25pt off 1.25pt);
fill pmhbox(81.299pt, 5pt, 44.85pt, 14.5pt, 2.5pt) withcolor (0.8706,0.8706,0);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "develop" & "}") scaled 1, (101.224pt, -11.5pt), 0, (0,0,0));
begingroup interim linecap := rounded; draw (38.499pt, -30pt)
  .. controls (38.499pt, -30pt) and (38.499pt, -61.25pt) .. (38.499pt, -61.25pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (38.499pt, -61.25pt)
  .. controls (38.499pt, -61.25pt) and (91.849pt, -61.25pt) .. (91.849pt, -61.25pt)
  .. controls (98.753pt, -61.25pt) and (104.349pt, -66.846pt) .. (104.349pt, -73.75pt)
  .. controls (104.349pt, -73.75pt) and (104.349pt, -92.5pt) .. (104.349pt, -92.5pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (104.349pt, -92.5pt)
  .. controls (104.349pt, -92.5pt) and (104.349pt, -123.75pt) .. (104.349pt, -123.75pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (38.499pt, -61.25pt)
  .. controls (38.499pt, -61.25pt) and (38.499pt, -155pt) .. (38.499pt, -155pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (38.499pt, -155pt)
  .. controls (38.499pt, -155pt) and (38.499pt, -186.25pt) .. (38.499pt, -186.25pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (38.499pt, -186.25pt)
  .. controls (38.499pt, -186.25pt) and (38.499pt, -217.5pt) .. (38.499pt, -217.5pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (104.349pt, -123.75pt)
  .. controls (104.349pt, -123.75pt) and (104.349pt, -205pt) .. (104.349pt, -205pt)
  .. controls (104.349pt, -211.904pt) and (98.753pt, -217.5pt) .. (91.849pt, -217.5pt)
  .. controls (91.849pt, -217.5pt) and (38.499pt, -217.5pt) .. (38.499pt, -217.5pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (38.499pt, -217.5pt)
  .. controls (38.499pt, -217.5pt) and (38.499pt, -248.75pt) .. (38.499pt, -248.75pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
begingroup interim linecap := rounded; draw (38.499pt, -248.75pt)
  .. controls (38.499pt, -248.75pt) and (38.499pt, -280pt) .. (38.499pt, -280pt) withcolor (0,0,0.9255) withpen pencircle scaled 5pt; endgroup;
fill fullcircle scaled 12.5pt shifted (38.499pt, -30pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -30pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (38.499pt, -61.25pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -61.25pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (104.349pt, -92.5pt) withcolor (0.8706,0.8706,0);
draw fullcircle scaled 12.5pt shifted (104.349pt, -92.5pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (104.349pt, -123.75pt) withcolor (0.8706,0.8706,0);
draw fullcircle scaled 12.5pt shifted (104.349pt, -123.75pt) withcolor (0.8706,0.8706,0) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (38.499pt, -155pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -155pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (38.499pt, -186.25pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -186.25pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (38.499pt, -217.5pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -217.5pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 7.5pt shifted (38.499pt, -217.5pt) withcolor (0.9255,0.9255,1);
draw fullcircle scaled 7.5pt shifted (38.499pt, -217.5pt) withcolor (0.9255,0.9255,1) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (38.499pt, -248.75pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -248.75pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill fullcircle scaled 12.5pt shifted (38.499pt, -280pt) withcolor (0,0,0.9255);
draw fullcircle scaled 12.5pt shifted (38.499pt, -280pt) withcolor (0,0,0.9255) withpen pencircle scaled 0.625pt;
fill (5.265pt, -52.627pt) -- (25.683pt, -32.21pt) -- (32.754pt, -39.281pt) -- (12.336pt, -59.698pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "0-e745ced" & "}") scaled 0.625, (20.556pt, -44.849pt), -45, (0,0,0.1294));
fill (5.177pt, -83.966pt) -- (25.683pt, -63.46pt) -- (32.754pt, -70.531pt) -- (12.248pt, -91.037pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "1-85a1cf8" & "}") scaled 0.625, (20.512pt, -76.143pt), -45, (0,0,0.1294));
fill (70.762pt, -115.481pt) -- (91.533pt, -94.71pt) -- (98.604pt, -101.781pt) -- (77.833pt, -122.552pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2-0076937" & "}") scaled 0.625, (86.229pt, -107.526pt), -45, (0,0,0.1294));
fill (71.292pt, -146.201pt) -- (91.533pt, -125.96pt) -- (98.604pt, -133.031pt) -- (78.363pt, -153.272pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "3-adbfee0" & "}") scaled 0.625, (86.495pt, -138.511pt), -45, (0,0,0.1294));
fill (5.088pt, -177.804pt) -- (25.683pt, -157.21pt) -- (32.754pt, -164.281pt) -- (12.159pt, -184.875pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "4-30b5d19" & "}") scaled 0.625, (20.468pt, -169.938pt), -45, (0,0,0.1294));
fill (5.177pt, -208.966pt) -- (25.683pt, -188.46pt) -- (32.754pt, -195.531pt) -- (12.248pt, -216.037pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "5-cf11d24" & "}") scaled 0.625, (20.512pt, -201.143pt), -45, (0,0,0.1294));
fill (5.265pt, -271.377pt) -- (25.683pt, -250.96pt) -- (32.754pt, -258.031pt) -- (12.336pt, -278.448pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "7-f3c9d3a" & "}") scaled 0.625, (20.556pt, -263.599pt), -45, (0,0,0.1294));
fill (5pt, -302.893pt) -- (25.683pt, -282.21pt) -- (32.754pt, -289.281pt) -- (12.071pt, -309.964pt) -- 
  cycle withcolor (1,1,0.9373);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "8-9225d45" & "}") scaled 0.625, (20.424pt, -294.982pt), -45, (0,0,0.1294));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
