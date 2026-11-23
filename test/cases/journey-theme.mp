\startMPcode
numeric pmjpx, pmjtop, pmjleft, pmjright, pmjbottom, pmjwidth, pmjx, pmjy, pmjfy,
  pmjsech, pmjtaskh, pmjtasky, pmjextra;
picture pmjname[], pmjtitle, pmjsec[], pmjtask[];
pmjpx := 0.625pt;
vardef pmjp(expr a, b) = (a, -b) enddef;
vardef pmjwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;
vardef pmjht(expr p) = (ypart urcorner p - ypart llcorner p) enddef;
vardef pmjbox(expr xa, ya, w, h, r) =
  pmjp(xa + r, ya) -- pmjp(xa + w - r, ya) {right} .. {down} pmjp(xa + w, ya + r)
  -- pmjp(xa + w, ya + h - r) {down} .. {left} pmjp(xa + w - r, ya + h)
  -- pmjp(xa + r, ya + h) {left} .. {up} pmjp(xa, ya + h - r)
  -- pmjp(xa, ya + r) {up} .. {right} cycle
enddef;
def pmjboxed(expr xa, ya, w, h, p, f, c, tc) =
  fill pmjbox(xa, ya, w, h, (3*pmjpx)) withcolor f;
  draw pmjbox(xa, ya, w, h, (3*pmjpx)) withcolor c withpen pencircle scaled pmjpx;
  draw p shifted (pmjp(xa + w / 2, ya + h / 2) - center p) withcolor tc;
enddef;
pmjtop := (10*pmjpx);
pmjtitle := textext("{\bf " & "A themed journey with a much longer title than its tasks need" & "}") scaled 1.5;
pmjtop := pmjtop + pmjht(pmjtitle) + (15*pmjpx);
pmjright := 0; pmjy := pmjtop + (10*pmjpx);
pmjname[0] := textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A person with a name long enough to wrap in the legend because it is wider than three hundred and sixty pixels" & "}");
if pmjwd(pmjname[0]) > (360*pmjpx): pmjname[0] := textext("\framed[frame=off,offset=0pt,width=225pt,align=flushleft]{" & "A person with a name long enough to wrap in the legend because it is wider than three hundred and sixty pixels" & "}"); fi
fill fullcircle scaled (14*pmjpx) shifted pmjp(20pmjpx, pmjy) withcolor (1,0,0);
draw fullcircle scaled (14*pmjpx) shifted pmjp(20pmjpx, pmjy) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
draw pmjname[0] shifted (pmjp((50*pmjpx), pmjy - (6*pmjpx)) - ulcorner pmjname[0]) withcolor (0.2,0.2,0.2);
pmjright := max(pmjright, pmjwd(pmjname[0]));
pmjy := pmjy + max((20*pmjpx), pmjht(pmjname[0]) + (8*pmjpx));
pmjname[1] := textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Alice" & "}");
if pmjwd(pmjname[1]) > (360*pmjpx): pmjname[1] := textext("\framed[frame=off,offset=0pt,width=225pt,align=flushleft]{" & "Alice" & "}"); fi
fill fullcircle scaled (14*pmjpx) shifted pmjp(20pmjpx, pmjy) withcolor (0,0,1);
draw fullcircle scaled (14*pmjpx) shifted pmjp(20pmjpx, pmjy) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
draw pmjname[1] shifted (pmjp((50*pmjpx), pmjy - (6*pmjpx)) - ulcorner pmjname[1]) withcolor (0.2,0.2,0.2);
pmjright := max(pmjright, pmjwd(pmjname[1]));
pmjy := pmjy + max((20*pmjpx), pmjht(pmjname[1]) + (8*pmjpx));
pmjname[2] := textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Bob" & "}");
if pmjwd(pmjname[2]) > (360*pmjpx): pmjname[2] := textext("\framed[frame=off,offset=0pt,width=225pt,align=flushleft]{" & "Bob" & "}"); fi
fill fullcircle scaled (14*pmjpx) shifted pmjp(20pmjpx, pmjy) withcolor (0,1,1);
draw fullcircle scaled (14*pmjpx) shifted pmjp(20pmjpx, pmjy) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
draw pmjname[2] shifted (pmjp((50*pmjpx), pmjy - (6*pmjpx)) - ulcorner pmjname[2]) withcolor (0.2,0.2,0.2);
pmjright := max(pmjright, pmjwd(pmjname[2]));
pmjy := pmjy + max((20*pmjpx), pmjht(pmjname[2]) + (8*pmjpx));
pmjbottom := max(pmjy, pmjtop + (400*pmjpx));
pmjleft := (200*pmjpx) + pmjright;
pmjsech := (50*pmjpx); pmjtaskh := (50*pmjpx);
pmjsec[0] := textext("\framed[frame=off,offset=0pt,width=87.5pt,align=middle]{" & "First" & "}");
pmjsech := max(pmjsech, pmjht(pmjsec[0]) + (10*pmjpx));
pmjsec[1] := textext("\framed[frame=off,offset=0pt,width=87.5pt,align=middle]{" & "Second" & "}");
pmjsech := max(pmjsech, pmjht(pmjsec[1]) + (10*pmjpx));
pmjtask[0] := textext("\framed[frame=off,offset=0pt,width=87.5pt,align=middle]{" & "Start" & "}");
pmjtaskh := max(pmjtaskh, pmjht(pmjtask[0]) + (10*pmjpx));
pmjtask[1] := textext("\framed[frame=off,offset=0pt,width=87.5pt,align=middle]{" & "Finish" & "}");
pmjtaskh := max(pmjtaskh, pmjht(pmjtask[1]) + (10*pmjpx));
pmjtasky := pmjtop + pmjsech + (10*pmjpx);
pmjextra := pmjsech + pmjtaskh - (100*pmjpx);
pmjbottom := max(pmjbottom, pmjtop + pmjextra + (400*pmjpx));
pmjboxed(pmjleft + (0*pmjpx), pmjtop, (150*pmjpx), pmjsech, pmjsec[0], (1,0.8,0.8), (0.4,0.4,0.4), (0.2,0.2,0.2));
pmjboxed(pmjleft + (200*pmjpx), pmjtop, (150*pmjpx), pmjsech, pmjsec[1], (0.8,1,0.8), (0.4,0.4,0.4), (0.2,0.2,0.2));
pmjx := pmjleft + (0*pmjpx);
draw pmjp(pmjx + (75*pmjpx), pmjtasky) -- pmjp(pmjx + (75*pmjpx), pmjtop + pmjextra + (400*pmjpx)) dashed dashpattern(on (4*pmjpx) off (4*pmjpx)) withcolor (0.2,0.2,0.2) withpen pencircle scaled pmjpx;
pmjx := pmjx + (75*pmjpx); pmjfy := pmjtop + pmjextra + (280*pmjpx);
fill fullcircle scaled (30*pmjpx) shifted pmjp(pmjx, pmjfy) withcolor (1,1,0);
draw fullcircle scaled (30*pmjpx) shifted pmjp(pmjx, pmjfy) withcolor (0.6,0.6,0.6) withpen pencircle scaled (2*pmjpx);
fill fullcircle scaled (5*pmjpx) shifted pmjp(pmjx - 5pmjpx, pmjfy - 5pmjpx) withcolor (0.4,0.4,0.4);
fill fullcircle scaled (5*pmjpx) shifted pmjp(pmjx + 5pmjpx, pmjfy - 5pmjpx) withcolor (0.4,0.4,0.4);
draw halfcircle rotated 180 scaled (14*pmjpx) shifted pmjp(pmjx, pmjfy + (2*pmjpx)) withcolor (0.4,0.4,0.4) withpen pencircle scaled (1.5*pmjpx);
pmjx := pmjx - (75*pmjpx);
pmjboxed(pmjx, pmjtasky, (150*pmjpx), pmjtaskh, pmjtask[0], (1,0.8,0.8), (0.4,0.4,0.4), (0.2,0.2,0.2));
pmjy := pmjx + (14*pmjpx);
fill fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,0,1);
draw fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
pmjy := pmjx + (24*pmjpx);
fill fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,1,1);
draw fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
pmjbottom := max(pmjbottom, pmjfy + (15*pmjpx), pmjtasky + pmjtaskh);
pmjx := pmjleft + (200*pmjpx);
draw pmjp(pmjx + (75*pmjpx), pmjtasky) -- pmjp(pmjx + (75*pmjpx), pmjtop + pmjextra + (400*pmjpx)) dashed dashpattern(on (4*pmjpx) off (4*pmjpx)) withcolor (0.2,0.2,0.2) withpen pencircle scaled pmjpx;
pmjx := pmjx + (75*pmjpx); pmjfy := pmjtop + pmjextra + (340*pmjpx);
fill fullcircle scaled (30*pmjpx) shifted pmjp(pmjx, pmjfy) withcolor (1,1,0);
draw fullcircle scaled (30*pmjpx) shifted pmjp(pmjx, pmjfy) withcolor (0.6,0.6,0.6) withpen pencircle scaled (2*pmjpx);
fill fullcircle scaled (5*pmjpx) shifted pmjp(pmjx - 5pmjpx, pmjfy - 5pmjpx) withcolor (0.4,0.4,0.4);
fill fullcircle scaled (5*pmjpx) shifted pmjp(pmjx + 5pmjpx, pmjfy - 5pmjpx) withcolor (0.4,0.4,0.4);
draw halfcircle scaled (14*pmjpx) shifted pmjp(pmjx, pmjfy + (7*pmjpx)) withcolor (0.4,0.4,0.4) withpen pencircle scaled (1.5*pmjpx);
pmjx := pmjx - (75*pmjpx);
pmjboxed(pmjx, pmjtasky, (150*pmjpx), pmjtaskh, pmjtask[1], (0.8,1,0.8), (0.4,0.4,0.4), (0.2,0.2,0.2));
pmjy := pmjx + (14*pmjpx);
fill fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,1,1);
draw fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
pmjy := pmjx + (24*pmjpx);
fill fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (1,0,0);
draw fullcircle scaled (14*pmjpx) shifted pmjp(pmjy, pmjtasky) withcolor (0,0,0) withpen pencircle scaled (1*pmjpx);
pmjbottom := max(pmjbottom, pmjfy + (15*pmjpx), pmjtasky + pmjtaskh);
pmjx := pmjleft + (400*pmjpx); pmjy := pmjtop + pmjextra + (150*pmjpx);
draw pmjp(pmjleft, pmjy) -- pmjp(pmjx - (24*pmjpx), pmjy) withcolor (0.2,0.2,0.2) withpen pencircle scaled (4*pmjpx);
fill pmjp(pmjx - (24*pmjpx), pmjy - (8*pmjpx)) -- pmjp(pmjx, pmjy) -- pmjp(pmjx - (24*pmjpx), pmjy + (8*pmjpx)) -- cycle withcolor (0.2,0.2,0.2);
pmjwidth := pmjx;
pmjwidth := max(pmjwidth, pmjleft + (350*pmjpx));
draw pmjtitle shifted (pmjp(pmjleft, (10*pmjpx)) - ulcorner pmjtitle) withcolor (0.2,0.2,0.2);
pmjwidth := max(pmjwidth, pmjleft + pmjwd(pmjtitle));
pmjwidth := pmjwidth + (10*pmjpx); pmjbottom := pmjbottom + (10*pmjpx);
setbounds currentpicture to pmjp(0, 0) -- pmjp(pmjwidth, 0) -- pmjp(pmjwidth, pmjbottom) -- pmjp(0, pmjbottom) -- cycle;
if pmjwidth > 432pt: currentpicture := currentpicture scaled (432pt / pmjwidth); fi
\stopMPcode
