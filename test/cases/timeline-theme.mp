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
pmttitle := textext("{\bf " & "A themed timeline with a title much wider than the drawing would be" & "}") scaled 1.5;
pmttop := pmttop + pmtht(pmttitle) + (15*pmtpx);
pmtsech := 0; pmttaskh := 0; pmtstack := 0;
pmtt[0] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "2020" & "}");
pmth[0] := max(pmtht(pmtt[0]) + (28.8*pmtpx), (0*pmtpx));
pmttaskh := max(pmttaskh, pmth[0]);
pmtsum := 0;
pmtt[1] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "One" & "}");
pmth[1] := max(pmtht(pmtt[1]) + (28.8*pmtpx), (50*pmtpx));
pmtsum := pmtsum + pmth[1];
pmtt[2] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "Two" & "}");
pmth[2] := max(pmtht(pmtt[2]) + (28.8*pmtpx), (50*pmtpx));
pmtsum := pmtsum + pmth[2] + (10*pmtpx);
pmtstack := max(pmtstack, pmtsum);
pmtt[3] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "2021" & "}");
pmth[3] := max(pmtht(pmtt[3]) + (28.8*pmtpx), (0*pmtpx));
pmttaskh := max(pmttaskh, pmth[3]);
pmtsum := 0;
pmtt[4] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "A long event, long enough to be wrapped onto three lines in its box, or more" & "}");
pmth[4] := max(pmtht(pmtt[4]) + (28.8*pmtpx), (50*pmtpx));
pmtsum := pmtsum + pmth[4];
pmtstack := max(pmtstack, pmtsum);
pmtt[5] := textext("\framed[frame=off,offset=0pt,width=93.75pt,align=middle]{" & "2022" & "}");
pmth[5] := max(pmtht(pmtt[5]) + (28.8*pmtpx), (0*pmtpx));
pmttaskh := max(pmttaskh, pmth[5]);
pmtsum := 0;
pmtstack := max(pmtstack, pmtsum);
pmttaskh := pmttaskh + (20*pmtpx);
pmth[0] := pmttaskh;
pmth[3] := pmttaskh;
pmth[5] := pmttaskh;
pmtpy := pmttop;
pmtbottom := pmttop;
pmty[0] := pmtpy;
pmtla[0] := pmtpy + pmttaskh; pmtlb[0] := pmtpy + pmttaskh + (200*pmtpx) + pmtstack;
pmtbottom := max(pmtbottom, pmtlb[0]);
pmtey := pmtpy + (200*pmtpx);
pmty[1] := pmtey; pmtey := pmtey + pmth[1] + (10*pmtpx);
pmty[2] := pmtey; pmtey := pmtey + pmth[2] + (10*pmtpx);
pmty[3] := pmtpy;
pmtla[1] := pmtpy + pmttaskh; pmtlb[1] := pmtpy + pmttaskh + (200*pmtpx) + pmtstack;
pmtbottom := max(pmtbottom, pmtlb[1]);
pmtey := pmtpy + (200*pmtpx);
pmty[4] := pmtey; pmtey := pmtey + pmth[4] + (10*pmtpx);
pmty[5] := pmtpy;
pmtla[2] := pmtpy + pmttaskh; pmtlb[2] := pmtpy + pmttaskh + (200*pmtpx) + pmtstack;
pmtbottom := max(pmtbottom, pmtlb[2]);
pmtey := pmtpy + (200*pmtpx);
pmtay := pmtpy + pmttaskh + (50*pmtpx);
pmtaya := pmtay; pmtayb := pmtay;
pmtbottom := max(pmtbottom, pmtay + (8*pmtpx));
pmtarrow(pmtp((96.875pt), pmtla[0]), pmtp((96.875pt), pmtlb[0]), (12*pmtpx), (8*pmtpx), (2*pmtpx), true);
pmtarrow(pmtp((221.875pt), pmtla[1]), pmtp((221.875pt), pmtlb[1]), (12*pmtpx), (8*pmtpx), (2*pmtpx), true);
pmtarrow(pmtp((346.875pt), pmtla[2]), pmtp((346.875pt), pmtlb[2]), (12*pmtpx), (8*pmtpx), (2*pmtpx), true);
pmtnode((37.5pt), pmty[0], (118.75pt), pmth[0], pmtt[0], (1,0,0), (0,0,1), (0,0,0));
pmtnode((37.5pt), pmty[1], (118.75pt), pmth[1], pmtt[1], (1,0,0), (0,0,1), (0,0,0));
pmtnode((37.5pt), pmty[2], (118.75pt), pmth[2], pmtt[2], (1,0,0), (0,0,1), (0,0,0));
pmtnode((162.5pt), pmty[3], (118.75pt), pmth[3], pmtt[3], (0,1,0), (0.6706,0.6706,1), (0,0,0));
pmtnode((162.5pt), pmty[4], (118.75pt), pmth[4], pmtt[4], (0,1,0), (0.8039,0.8039,1), (0,0,0));
pmtnode((287.5pt), pmty[5], (118.75pt), pmth[5], pmtt[5], (0.8431,1,0.5255), (0.8157,0.7255,1), (0,0,0));
pmtarrow(pmtp((6.25pt), pmtaya), pmtp((437.5pt), pmtayb), (24*pmtpx), (16*pmtpx), (4*pmtpx), false);
draw pmttitle shifted (pmtp((37.5pt), (10*pmtpx)) - ulcorner pmttitle) withcolor (0.2,0.2,0.2);
pmtwidth := max((437.5pt), (37.5pt) + pmtwd(pmttitle));
pmtwidth := pmtwidth + (10*pmtpx); pmtbottom := pmtbottom + (10*pmtpx);
setbounds currentpicture to pmtp(0, 0) -- pmtp(pmtwidth, 0) -- pmtp(pmtwidth, pmtbottom) -- pmtp(0, pmtbottom) -- cycle;
if pmtwidth > 432pt: currentpicture := currentpicture scaled (432pt / pmtwidth); fi
\stopMPcode
