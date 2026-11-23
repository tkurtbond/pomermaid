\startMPcode
numeric pmtpx, pmttop, pmtsech, pmttaskh, pmtstack, pmtsum, pmtpy, pmtey, pmtay,
  pmtaya, pmtayb, pmtspacing, pmtbottom, pmtwidth, pmth[], pmty[], pmtla[], pmtlb[];
picture pmtt[], pmttitle; pair pmtu;
pmtpx := 0.625pt;
vardef pmtp(expr a, b) = (a, -b) enddef;
vardef pmtwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;
vardef pmtht(expr p) = (ypart urcorner p - ypart llcorner p) enddef;
def pmtarrow(expr a, b, len, wide, w, dsh) =
  pmtu := unitvector(b - a);
  draw a -- (b - len * pmtu) if dsh: dashed dashpattern(on (5*pmtpx) off (5*pmtpx)) fi
    withcolor (0,0,0) withpen pencircle scaled w;
  fill (b - len * pmtu + (wide / 2) * (pmtu rotated 90)) -- b
    -- (b - len * pmtu - (wide / 2) * (pmtu rotated 90)) -- cycle withcolor (0,0,0);
enddef;
def pmtnode(expr xa, ya, w, h, p, f, c, tc) =
  fill pmtp(xa, ya + h) -- pmtp(xa, ya + (5*pmtpx)) {up} .. {right} pmtp(xa + (5*pmtpx), ya)
    -- pmtp(xa + w - (5*pmtpx), ya) {right} .. {down} pmtp(xa + w, ya + (5*pmtpx))
    -- pmtp(xa + w, ya + h) -- cycle withcolor f;
  draw pmtp(xa, ya + h) -- pmtp(xa + w, ya + h) withcolor c withpen pencircle scaled (3*pmtpx);
  draw p shifted (pmtp(xa + w / 2, ya + h / 2) - center p) withcolor tc;
enddef;
pmttop := (10*pmtpx);
pmttitle := textext("{\bf " & "Sections with no periods" & "}") scaled 1.5;
pmttop := pmttop + pmtht(pmttitle) + (15*pmtpx);
pmtsech := 0; pmttaskh := 0; pmtstack := 0;
pmtt[0] := textext("\framed[frame=off,offset=0pt,width=362.5pt,align=middle]{" & "Before" & "}");
pmth[0] := max(pmtht(pmtt[0]) + (13.8*pmtpx), (0*pmtpx));
pmtsech := max(pmtsech, pmth[0]);
pmtt[1] := textext("\framed[frame=off,offset=0pt,width=362.5pt,align=middle]{" & "During" & "}");
pmth[1] := max(pmtht(pmtt[1]) + (13.8*pmtpx), (0*pmtpx));
pmtsech := max(pmtsech, pmth[1]);
pmtt[2] := textext("\framed[frame=off,offset=0pt,width=125pt,align=middle]{" & "Then" & "}");
pmth[2] := max(pmtht(pmtt[2]) + (13.8*pmtpx), (0*pmtpx));
pmttaskh := max(pmttaskh, pmth[2]);
pmtsum := 0;
pmtt[3] := textext("\framed[frame=off,offset=0pt,width=187.5pt,align=middle]{" & "something" & "}");
pmth[3] := max(pmtht(pmtt[3]) + (13.8*pmtpx), (0*pmtpx));
pmtsum := pmtsum + pmth[3];
pmtstack := max(pmtstack, pmtsum);
pmtt[4] := textext("\framed[frame=off,offset=0pt,width=362.5pt,align=middle]{" & "After" & "}");
pmth[4] := max(pmtht(pmtt[4]) + (13.8*pmtpx), (0*pmtpx));
pmtsech := max(pmtsech, pmth[4]);
pmth[0] := pmtsech;
pmth[1] := pmtsech;
pmth[2] := pmttaskh;
pmth[4] := pmtsech;
pmtspacing := max(pmttaskh, pmtstack) + (30*pmtpx);
pmtpy := pmttop + (32*pmtpx);
pmtbottom := pmttop;
pmty[0] := pmtpy; pmtpy := pmtpy + pmtsech + (20*pmtpx);
pmtbottom := max(pmtbottom, pmtpy - (20*pmtpx));
pmty[1] := pmtpy; pmtpy := pmtpy + pmtsech + (20*pmtpx);
pmtbottom := max(pmtbottom, pmtpy - (20*pmtpx));
pmty[2] := pmtpy;
pmtbottom := max(pmtbottom, pmtpy + pmttaskh);
pmtey := pmtpy;
pmty[3] := pmtey; pmtla[0] := pmtey + pmth[3] / 2; pmtlb[0] := pmtla[0];
pmtey := pmtey + pmth[3]; pmtbottom := max(pmtbottom, pmtey); pmtey := pmtey + (10*pmtpx);
pmtpy := pmtpy + pmtspacing;
pmtpy := pmtpy - (10*pmtpx);
pmty[4] := pmtpy; pmtpy := pmtpy + pmtsech + (20*pmtpx);
pmtbottom := max(pmtbottom, pmtpy - (20*pmtpx));
pmtaya := pmttop; pmtayb := max(pmtbottom, pmttop + (32*pmtpx)) + (28*pmtpx);
pmtbottom := pmtayb;
pmtarrow(pmtp((150pt), pmtaya), pmtp((150pt), pmtayb), (24*pmtpx), (16*pmtpx), (4*pmtpx), false);
pmtarrow(pmtp((150pt), pmtla[0]), pmtp((181.25pt), pmtlb[0]), (12*pmtpx), (8*pmtpx), (2*pmtpx), true);
pmtnode((6.25pt), pmty[0], (368.75pt), pmth[0], pmtt[0], (0.5255,0.5255,1), (1,1,0.7255), (1,1,1));
pmtnode((6.25pt), pmty[1], (368.75pt), pmth[1], pmtt[1], (1,1,0.4706), (0.6706,0.6706,1), (0,0,0));
pmtnode((6.25pt), pmty[2], (131.25pt), pmth[2], pmtt[2], (1,1,0.4706), (0.6706,0.6706,1), (0,0,0));
pmtnode((181.25pt), pmty[3], (193.75pt), pmth[3], pmtt[3], (1,1,0.5647), (0.8039,0.8039,1), (0,0,0));
pmtnode((6.25pt), pmty[4], (368.75pt), pmth[4], pmtt[4], (0.8431,1,0.5255), (0.8157,0.7255,1), (0,0,0));
draw pmttitle shifted (pmtp((6.25pt), (10*pmtpx)) - ulcorner pmttitle) withcolor (0.2,0.2,0.2);
pmtwidth := max((375pt), (6.25pt) + pmtwd(pmttitle));
pmtwidth := pmtwidth + (10*pmtpx); pmtbottom := pmtbottom + (10*pmtpx);
setbounds currentpicture to pmtp(0, 0) -- pmtp(pmtwidth, 0) -- pmtp(pmtwidth, pmtbottom) -- pmtp(0, pmtbottom) -- cycle;
if pmtwidth > 432pt: currentpicture := currentpicture scaled (432pt / pmtwidth); fi
\stopMPcode
