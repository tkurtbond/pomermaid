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
pmtsech := 0; pmttaskh := 0; pmtstack := 0;
pmtt[0] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "Later" & "}");
pmth[0] := max(pmtht(pmtt[0]) + (28.8*pmtpx), (0*pmtpx));
pmtsech := max(pmtsech, pmth[0]);
pmtt[1] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "Late" & "}");
pmth[1] := max(pmtht(pmtt[1]) + (28.8*pmtpx), (0*pmtpx));
pmttaskh := max(pmttaskh, pmth[1]);
pmtsum := 0;
pmtt[2] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "drawn" & "}");
pmth[2] := max(pmtht(pmtt[2]) + (28.8*pmtpx), (50*pmtpx));
pmtsum := pmtsum + pmth[2];
pmtstack := max(pmtstack, pmtsum);
pmtsech := pmtsech + (20*pmtpx);
pmttaskh := pmttaskh + (20*pmtpx);
pmth[0] := pmtsech;
pmth[1] := pmttaskh;
pmtpy := pmttop + pmtsech + (50*pmtpx);
pmtbottom := pmttop;
pmty[0] := pmttop;
pmty[1] := pmtpy;
pmtla[0] := pmtpy + pmttaskh; pmtlb[0] := pmtpy + pmttaskh + (200*pmtpx) + pmtstack;
pmtbottom := max(pmtbottom, pmtlb[0]);
pmtey := pmtpy + (200*pmtpx);
pmty[2] := pmtey; pmtey := pmtey + pmth[2] + (10*pmtpx);
pmtay := pmtpy + pmttaskh + (50*pmtpx);
pmtaya := pmtay; pmtayb := pmtay;
pmtbottom := max(pmtbottom, pmtay + (8*pmtpx));
pmtarrow(pmtp((96.875pt), pmtla[0]), pmtp((96.875pt), pmtlb[0]), (12*pmtpx), (8*pmtpx), (2*pmtpx), true);
pmtnode((37.5pt), pmty[0], (118.75pt), pmth[0], pmtt[0], (0.5255,0.5255,1), (1,1,0.7255), (1,1,1));
pmtnode((37.5pt), pmty[1], (118.75pt), pmth[1], pmtt[1], (0.5255,0.5255,1), (1,1,0.7255), (1,1,1));
pmtnode((37.5pt), pmty[2], (118.75pt), pmth[2], pmtt[2], (0.6314,0.6314,1), (1,1,0.8706), (1,1,1));
pmtarrow(pmtp((6.25pt), pmtaya), pmtp((187.5pt), pmtayb), (24*pmtpx), (16*pmtpx), (4*pmtpx), false);
pmtwidth := (187.5pt);
pmtwidth := pmtwidth + (10*pmtpx); pmtbottom := pmtbottom + (10*pmtpx);
setbounds currentpicture to pmtp(0, 0) -- pmtp(pmtwidth, 0) -- pmtp(pmtwidth, pmtbottom) -- pmtp(0, pmtbottom) -- cycle;
if pmtwidth > 432pt: currentpicture := currentpicture scaled (432pt / pmtwidth); fi
\stopMPcode
