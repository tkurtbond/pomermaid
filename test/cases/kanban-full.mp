\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -89.169pt; pmxx2 := 427.969pt; pmxx3 := 0;
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
fill pmhbox(3.438pt, 3.438pt, 68.75pt, 47.3pt, 1.719pt) withcolor (0.9098,1,0.7255);
draw pmhbox(3.438pt, 3.438pt, 68.75pt, 47.3pt, 1.719pt) withcolor (0.9098,1,0.7255) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Todo" & "}") scaled 1, (37.813pt, -6.738pt), 0, (0,0,0));
fill pmhbox(73.906pt, 3.438pt, 68.75pt, 58.506pt, 1.719pt) withcolor (0.8627,0.7255,1);
draw pmhbox(73.906pt, 3.438pt, 68.75pt, 58.506pt, 1.719pt) withcolor (0.8627,0.7255,1) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "In progress" & "}") scaled 1, (108.281pt, -6.738pt), 0, (1,1,1));
fill pmhbox(144.375pt, 3.438pt, 68.75pt, 28.806pt, 1.719pt) withcolor (1,0.7255,1);
draw pmhbox(144.375pt, 3.438pt, 68.75pt, 28.806pt, 1.719pt) withcolor (1,0.7255,1) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Ready for deploy" & "}") scaled 1, (178.75pt, -6.738pt), 0, (0,0,0));
fill pmhbox(214.844pt, 3.438pt, 68.75pt, 47.3pt, 1.719pt) withcolor (1,0.7255,0.8627);
draw pmhbox(214.844pt, 3.438pt, 68.75pt, 47.3pt, 1.719pt) withcolor (1,0.7255,0.8627) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Ready for test" & "}") scaled 1, (249.219pt, -6.738pt), 0, (0,0,0));
fill pmhbox(285.313pt, 3.438pt, 68.75pt, 82.294pt, 1.719pt) withcolor (1,0.7255,0.7255);
draw pmhbox(285.313pt, 3.438pt, 68.75pt, 82.294pt, 1.719pt) withcolor (1,0.7255,0.7255) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Done" & "}") scaled 1, (319.688pt, -6.738pt), 0, (0,0,0));
fill pmhbox(355.781pt, 3.438pt, 68.75pt, 32.106pt, 1.719pt) withcolor (1,0.8627,0.7255);
draw pmhbox(355.781pt, 3.438pt, 68.75pt, 32.106pt, 1.719pt) withcolor (1,0.8627,0.7255) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Can't reproduce" & "}") scaled 1, (390.156pt, -6.738pt), 0, (0,0,0));
fill pmhbox(6.016pt, 12.031pt, 63.594pt, 13.475pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(6.016pt, 12.031pt, 63.594pt, 13.475pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create Documentation" & "}") scaled 1, (36.156pt, -18.769pt), 0, (0.2,0.2,0.2));
fill pmhbox(6.016pt, 27.225pt, 63.594pt, 20.075pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(6.016pt, 27.225pt, 63.594pt, 20.075pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create Blog about the\\new diagram" & "}") scaled 1, (36.211pt, -37.262pt), 0, (0.2,0.2,0.2));
fill pmhbox(76.484pt, 12.031pt, 63.594pt, 46.475pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(76.484pt, 12.031pt, 63.594pt, 46.475pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create renderer so that\\it works in all cases. We\\also add some extra text\\here for testing\\purposes. And some more\\just for the extra flare." & "}") scaled 1, (109.897pt, -35.269pt), 0, (0.2,0.2,0.2));
fill pmhbox(146.953pt, 12.031pt, 63.594pt, 16.775pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(146.953pt, 12.031pt, 63.594pt, 16.775pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Design grammar" & "}") scaled 1, (168.706pt, -17.119pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "knsv" & "}") scaled 1, (201.829pt, -23.719pt), 0, (0.2,0.2,0.2));
fill pmhbox(217.422pt, 12.031pt, 63.594pt, 16.775pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(217.422pt, 12.031pt, 63.594pt, 16.775pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
draw (218.109pt, -12.719pt) -- (218.109pt, -28.119pt) withcolor (1,0.6471,0) withpen pencircle scaled 1.375pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create parsing tests" & "}") scaled 1, (246.462pt, -17.119pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "MC-2038" & "}") scaled 1, (230.759pt, -23.719pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "K.Sveidqvist" & "}") scaled 1, (261.298pt, -23.719pt), 0, (0.2,0.2,0.2));
fill pmhbox(217.422pt, 30.525pt, 63.594pt, 16.775pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(217.422pt, 30.525pt, 63.594pt, 16.775pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
draw (218.109pt, -31.213pt) -- (218.109pt, -46.613pt) withcolor (0.6784,0.8471,0.902) withpen pencircle scaled 1.375pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "last item" & "}") scaled 1, (232.107pt, -35.613pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "knsv" & "}") scaled 1, (272.298pt, -42.213pt), 0, (0.2,0.2,0.2));
fill pmhbox(287.891pt, 12.031pt, 63.594pt, 13.475pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(287.891pt, 12.031pt, 63.594pt, 13.475pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "define getData" & "}") scaled 1, (309.643pt, -18.769pt), 0, (0.2,0.2,0.2));
fill pmhbox(287.891pt, 27.225pt, 63.594pt, 36.575pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(287.891pt, 27.225pt, 63.594pt, 36.575pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
draw (288.578pt, -27.912pt) -- (288.578pt, -63.113pt) withcolor (1,0,0) withpen pencircle scaled 1.375pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Title of diagram is more\\than 100 chars when user\\duplicates diagram with\\100 char" & "}") scaled 1, (320.946pt, -42.213pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "MC-2036" & "}") scaled 1, (301.228pt, -58.713pt), 0, (0.2,0.2,0.2));
fill pmhbox(287.891pt, 65.519pt, 63.594pt, 16.775pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(287.891pt, 65.519pt, 63.594pt, 16.775pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
draw (288.578pt, -66.206pt) -- (288.578pt, -81.606pt) withcolor (1,0.6471,0) withpen pencircle scaled 1.375pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Update DB function" & "}") scaled 1, (315.226pt, -70.606pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "MC-2037" & "}") scaled 1, (301.228pt, -77.206pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "knsv" & "}") scaled 1, (342.767pt, -77.206pt), 0, (0.2,0.2,0.2));
fill pmhbox(358.359pt, 12.031pt, 63.594pt, 20.075pt, 1.719pt) withcolor (1,1,1);
draw pmhbox(358.359pt, 12.031pt, 63.594pt, 20.075pt, 1.719pt) withcolor (0.5765,0.4392,0.8588) withpen pencircle scaled 0.344pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Weird flickering in\\Firefox" & "}") scaled 1, (386.079pt, -22.069pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
