\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -250pt; pmxx2 := 375pt; pmxx3 := 0;
def pmxtext(expr p, q, a, c) =
  pmxp := p shifted -(if (a = 0): xpart llcorner p else: xpart lrcorner p fi, ypart center p) shifted q;
  draw pmxp withcolor c;
  pmxx0 := min(pmxx0, xpart llcorner pmxp); pmxx1 := min(pmxx1, ypart llcorner pmxp);
  pmxx2 := max(pmxx2, xpart urcorner pmxp); pmxx3 := max(pmxx3, ypart urcorner pmxp);
enddef;
fill unitsquare xscaled 6.25pt yscaled 205.698pt shifted (0pt, -205.698pt) withcolor (0.3059,0.4745,0.6549);
fill unitsquare xscaled 6.25pt yscaled 137.132pt shifted (184.375pt, -137.132pt) withcolor (0.949,0.5569,0.1725);
fill unitsquare xscaled 6.25pt yscaled 95.993pt shifted (184.375pt, -250pt) withcolor (0.8824,0.3412,0.349);
fill unitsquare xscaled 6.25pt yscaled 95.993pt shifted (368.75pt, -95.993pt) withcolor (0.4627,0.7176,0.698);
fill unitsquare xscaled 6.25pt yscaled 82.279pt shifted (368.75pt, -195.147pt) withcolor (0.349,0.6314,0.3098);
fill unitsquare xscaled 6.25pt yscaled 27.427pt shifted (0pt, -250pt) withcolor (0.9294,0.7882,0.2863);
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A 15" & "}") scaled 0.875, (10pt, -99.787pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "B 10" & "}") scaled 0.875, (194.375pt, -65.504pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "C 7" & "}") scaled 0.875, (194.375pt, -198.941pt), 0, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "D 7" & "}") scaled 0.875, (365pt, -44.934pt), 2, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "E 6" & "}") scaled 0.875, (365pt, -150.945pt), 2, (0.2,0.2,0.2));
pmxtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "F 2" & "}") scaled 0.875, (10pt, -233.224pt), 0, (0.2,0.2,0.2));
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
