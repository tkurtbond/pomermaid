\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -188.5pt; pmxx2 := 304.6pt; pmxx3 := 0;
def pmxtext(expr p, q, a, c) =
  pmxp := p shifted -(if (a = 0): xpart llcorner p elseif (a = 1): xpart center p else: xpart lrcorner p fi, ypart center p) shifted q;
  draw pmxp withcolor c;
  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);
  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);
enddef;
begingroup interim linecap := butt; interim linejoin := mitered;
fill (135.85pt, -32.25pt) -- (195.291pt, -75.436pt) -- (172.587pt, -145.314pt) -- (99.113pt, -145.314pt) -- (76.409pt, -75.436pt) -- cycle withcolor (0.8,0.902,0.8);
draw (135.85pt, -32.25pt) -- (195.291pt, -75.436pt) -- (172.587pt, -145.314pt) -- (99.113pt, -145.314pt) -- (76.409pt, -75.436pt) -- cycle withcolor (0.6,0.8,0.6) withpen pencircle scaled 0.625pt;
fill (135.85pt, -44.75pt) -- (183.403pt, -79.299pt) -- (165.239pt, -135.201pt) -- (106.461pt, -135.201pt) -- (88.297pt, -79.299pt) -- cycle withcolor (0.702,0.851,0.702);
draw (135.85pt, -44.75pt) -- (183.403pt, -79.299pt) -- (165.239pt, -135.201pt) -- (106.461pt, -135.201pt) -- (88.297pt, -79.299pt) -- cycle withcolor (0.6,0.8,0.6) withpen pencircle scaled 0.625pt;
fill (135.85pt, -57.25pt) -- (171.515pt, -83.162pt) -- (157.892pt, -125.088pt) -- (113.808pt, -125.088pt) -- (100.185pt, -83.162pt) -- cycle withcolor (0.651,0.8275,0.651);
draw (135.85pt, -57.25pt) -- (171.515pt, -83.162pt) -- (157.892pt, -125.088pt) -- (113.808pt, -125.088pt) -- (100.185pt, -83.162pt) -- cycle withcolor (0.6,0.8,0.6) withpen pencircle scaled 0.625pt;
fill (135.85pt, -69.75pt) -- (159.626pt, -87.025pt) -- (150.545pt, -114.975pt) -- (121.155pt, -114.975pt) -- (112.074pt, -87.025pt) -- cycle withcolor (0.6275,0.8157,0.6275);
draw (135.85pt, -69.75pt) -- (159.626pt, -87.025pt) -- (150.545pt, -114.975pt) -- (121.155pt, -114.975pt) -- (112.074pt, -87.025pt) -- cycle withcolor (0.6,0.8,0.6) withpen pencircle scaled 0.625pt;
fill (135.85pt, -82.25pt) -- (147.738pt, -90.887pt) -- (143.197pt, -104.863pt) -- (128.503pt, -104.863pt) -- (123.962pt, -90.887pt) -- cycle withcolor (0.6157,0.8078,0.6157);
draw (135.85pt, -82.25pt) -- (147.738pt, -90.887pt) -- (143.197pt, -104.863pt) -- (128.503pt, -104.863pt) -- (123.962pt, -90.887pt) -- cycle withcolor (0.6,0.8,0.6) withpen pencircle scaled 0.625pt;
draw (135.85pt, -94.75pt) -- (135.85pt, -32.25pt) withcolor (0.6667,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "North" & "}") scaled 1, (135.85pt, -13.75pt), 1, (0.2,0.2,0.2));
draw (135.85pt, -94.75pt) -- (195.291pt, -75.436pt) withcolor (0.6667,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "East side" & "}") scaled 1, (209.557pt, -67.301pt), 0, (0.2,0.2,0.2));
draw (135.85pt, -94.75pt) -- (172.587pt, -145.314pt) withcolor (0.6667,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "South" & "}") scaled 1, (181.403pt, -162.449pt), 0, (0.2,0.2,0.2));
draw (135.85pt, -94.75pt) -- (99.113pt, -145.314pt) withcolor (0.6667,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "The West" & "}") scaled 1, (90.297pt, -162.449pt), 2, (0.2,0.2,0.2));
draw (135.85pt, -94.75pt) -- (76.409pt, -75.436pt) withcolor (0.6667,0,0) withpen pencircle scaled 0.625pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "up" & "}") scaled 1, (62.143pt, -67.301pt), 2, (0.2,0.2,0.2));
fill (135.85pt, -32.25pt) -- (183.403pt, -79.299pt) -- (157.892pt, -125.088pt) -- (121.155pt, -114.975pt) -- (123.962pt, -90.887pt) -- cycle withcolor (0.8,0.851,0.902);
draw (135.85pt, -32.25pt) -- (183.403pt, -79.299pt) -- (157.892pt, -125.088pt) -- (121.155pt, -114.975pt) -- (123.962pt, -90.887pt) -- cycle withcolor (0.2,0.4,0.6) withpen pencircle scaled 1.875pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A wide title that the margins of this chart cannot hold at all" & "}") scaled 1, (135.85pt, -6pt), 1, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
