\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -387.497pt; pmxx2 := 430.929pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (66.563pt, -236.987pt)
  .. controls (66.563pt, -236.987pt) and (247.579pt, -236.987pt) .. (247.579pt, -236.987pt)
  .. controls (247.579pt, -236.987pt) and (247.579pt, -343.122pt) .. (247.579pt, -343.122pt)
  .. controls (247.579pt, -343.122pt) and (66.563pt, -343.122pt) .. (66.563pt, -343.122pt)
  .. controls (66.563pt, -343.122pt) and (66.563pt, -236.987pt) .. (66.563pt, -236.987pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.444pt dashed dashpattern(on 3.106pt off 3.106pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf A group}" & "}") scaled 1, (157.071pt, -240.537pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[system]" & "}") scaled 0.875, (157.071pt, -251.276pt), 0, (0.2667,0.2667,0.2667));
fill pmhbox(66.563pt, 149.047pt, 157.579pt, 39.572pt, 17.807pt) withcolor (0.0314,0.2588,0.4824);
draw pmhbox(66.563pt, 149.047pt, 157.579pt, 39.572pt, 17.807pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.887pt;
fill fullcircle scaled 49.7pt shifted (145.352pt, -130.906pt) withcolor (0.0314,0.2588,0.4824);
draw fullcircle scaled 49.7pt shifted (145.352pt, -130.906pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.887pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf A person with a rather long name}" & "}") scaled 0.875, (145.352pt, -161.649pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6562, (145.352pt, -169.504pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A description long enough to need wrapping if it were wrapped." & "}") scaled 0.7175, (145.352pt, -176.687pt), 0, (1,1,1));
fill pmhbox(268.516pt, 106.056pt, 95.85pt, 39.572pt, 5.325pt) withcolor (0.6,0.6,0.6);
draw pmhbox(268.516pt, 106.056pt, 95.85pt, 39.572pt, 5.325pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.887pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf B}" & "}") scaled 0.875, (316.442pt, -118.659pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6562, (316.442pt, -126.513pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Short." & "}") scaled 0.7175, (316.442pt, -133.697pt), 0, (1,1,1));
fill pmhbox(88.75pt, 281.362pt, 136.642pt, 39.572pt, 5.325pt) withcolor (0.0667,0.4078,0.7412);
draw pmhbox(88.75pt, 281.362pt, 136.642pt, 39.572pt, 5.325pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.887pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf C}" & "}") scaled 0.875, (157.071pt, -293.965pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6562, (157.071pt, -301.819pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Another fairly long description that is not wrapped." & "}") scaled 0.7175, (157.071pt, -309.003pt), 0, (1,1,1));
draw (165.991pt, -144.744pt) -- (268.516pt, -131.863pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.444pt;
fill (268.957pt, -131.808pt) -- (264.83pt, -134.563pt) -- (264.277pt, -130.16pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A relationship label that is long" & "}") scaled 0.75, (256.818pt, -138.304pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [and its technology]}" & "}") scaled 0.75, (256.818pt, -145.848pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (155.563pt, -281.362pt)
  .. controls (154.386pt, -250.448pt) and (152.03pt, -219.533pt) .. (148.497pt, -188.619pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.444pt; endgroup;
fill (148.447pt, -188.178pt) -- (151.155pt, -192.335pt) -- (146.746pt, -192.839pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "back" & "}") scaled 0.75, (157.142pt, -234.99pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "No wrapping" & "}") scaled 1, (123.058pt, -37.453pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
