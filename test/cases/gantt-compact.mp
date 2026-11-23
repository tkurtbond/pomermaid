\startMPcode
picture pmgt; numeric pmgw, pmga; color pmgc;
vardef pmgp(expr a, b) = (a, -b) enddef;
vardef pmgwd(expr p) = (xpart urcorner p - xpart llcorner p) enddef;
vardef pmgbox(expr x, y, w, h, r) =
  if r > 0: (x + r, -y) -- (x + w - r, -y) {right} .. {down} (x + w, -y - r)
    -- (x + w, -y - h + r) {down} .. {left} (x + w - r, -y - h)
    -- (x + r, -y - h) {left} .. {up} (x, -y - h + r)
    -- (x, -y - r) {up} .. {right} cycle
  else: (x, -y) -- (x + w, -y) -- (x + w, -y - h) -- (x, -y - h) -- cycle fi
enddef;
def pmgtext(expr p, x, y, a, c) =
  draw p shifted (pmgp(x, y) - (if a = 0: xpart llcorner p elseif a = 2: xpart urcorner p
    else: xpart center p fi, ypart center p)) withcolor c;
enddef;
fill pmgbox(0pt, 109.091pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(0pt, 87.273pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(0pt, 130.909pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(0pt, 43.636pt, 397.909pt, 21.818pt, 0pt) withcolor (1,0.9922,0.8);
fill pmgbox(0pt, 65.455pt, 397.909pt, 21.818pt, 0pt) withcolor (1,0.9922,0.8);
draw pmgp(92.727pt, 31.818pt) -- pmgp(92.727pt, 154.545pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 7" & "}") scaled 0.9091, 92.727pt, 163.636pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(92.727pt, 45.455pt) -- pmgp(92.727pt, 168.182pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 7" & "}") scaled 0.9091, 92.727pt, 40pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(141.818pt, 31.818pt) -- pmgp(141.818pt, 154.545pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 9" & "}") scaled 0.9091, 141.818pt, 163.636pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(141.818pt, 45.455pt) -- pmgp(141.818pt, 168.182pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 9" & "}") scaled 0.9091, 141.818pt, 40pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(190.909pt, 31.818pt) -- pmgp(190.909pt, 154.545pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 11" & "}") scaled 0.9091, 190.909pt, 163.636pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(190.909pt, 45.455pt) -- pmgp(190.909pt, 168.182pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 11" & "}") scaled 0.9091, 190.909pt, 40pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(240.909pt, 31.818pt) -- pmgp(240.909pt, 154.545pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 13" & "}") scaled 0.9091, 240.909pt, 163.636pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(240.909pt, 45.455pt) -- pmgp(240.909pt, 168.182pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 13" & "}") scaled 0.9091, 240.909pt, 40pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(290pt, 31.818pt) -- pmgp(290pt, 154.545pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 15" & "}") scaled 0.9091, 290pt, 163.636pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(290pt, 45.455pt) -- pmgp(290pt, 168.182pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 15" & "}") scaled 0.9091, 290pt, 40pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(339.091pt, 31.818pt) -- pmgp(339.091pt, 154.545pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 17" & "}") scaled 0.9091, 339.091pt, 163.636pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(339.091pt, 45.455pt) -- pmgp(339.091pt, 168.182pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Nov 17" & "}") scaled 0.9091, 339.091pt, 40pt, 1, (0.3608,0.3608,0.3608));
fill pmgbox(68.182pt, 110.909pt, 98.182pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(68.182pt, 110.909pt, 98.182pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(92.727pt, 89.091pt, 148.182pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(92.727pt, 89.091pt, 148.182pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(117.273pt, 132.727pt, 99.091pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(117.273pt, 132.727pt, 99.091pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(141.818pt, 45.455pt, 49.091pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(141.818pt, 45.455pt, 49.091pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(141.818pt, 67.273pt, 221.818pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(141.818pt, 67.273pt, 221.818pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(190.909pt, 110.909pt, 74.545pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(190.909pt, 110.909pt, 74.545pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(231.818pt, 89.091pt, 18.182pt, 18.182pt, 2.727pt) shifted -pmgp(240.909pt, 98.182pt) rotated 45 scaled 0.8 shifted pmgp(240.909pt, 98.182pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(231.818pt, 89.091pt, 18.182pt, 18.182pt, 2.727pt) shifted -pmgp(240.909pt, 98.182pt) rotated 45 scaled 0.8 shifted pmgp(240.909pt, 98.182pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(339.091pt, 45.455pt, 24.545pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(339.091pt, 45.455pt, 24.545pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(290pt, 31.818pt, 1.455pt, 168.182pt, 0.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(290pt, 31.818pt, 1.455pt, 168.182pt, 0.727pt) withcolor (0,0,0.502) withpen pencircle scaled 1.818pt;
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "One" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 98.182pt: if pmgw > 231.545pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 98.182pt: if pmgw > 231.545pt: 63.636pt else: 170.909pt fi else: 117.273pt fi, 120.182pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Four" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 148.182pt: if pmgw > 157pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 148.182pt: if pmgw > 157pt: 88.182pt else: 245.455pt fi else: 166.818pt fi, 98.364pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Two" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 99.091pt: if pmgw > 181.545pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 99.091pt: if pmgw > 181.545pt: 112.727pt else: 220.909pt fi else: 166.818pt fi, 142pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Five" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 49.091pt: if pmgw > 207pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 49.091pt: if pmgw > 207pt: 137.273pt else: 195.455pt fi else: 166.364pt fi, 54.727pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Six" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 221.818pt: if pmgw > 34.273pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 221.818pt: if pmgw > 34.273pt: 137.273pt else: 368.182pt fi else: 252.727pt fi, 76.545pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Three" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 74.545pt: if pmgw > 132.455pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 74.545pt: if pmgw > 132.455pt: 186.364pt else: 270pt fi else: 228.182pt fi, 120.182pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it Done}" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 18.182pt: if pmgw > 138.818pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 18.182pt: if pmgw > 147.909pt: 227.273pt else: 254.545pt fi else: 240.909pt fi, 98.364pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Seven" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 24.545pt: if pmgw > 34.273pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 24.545pt: if pmgw > 34.273pt: 334.545pt else: 368.182pt fi else: 351.364pt fi, 54.727pt, pmga, pmgc);
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "2" & "}") scaled 1, 9.091pt, 67.273pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "10" & "}") scaled 1, 9.091pt, 100pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "b" & "}") scaled 1, 9.091pt, 132.727pt, 0, (0.2,0.2,0.2));
draw pmgp(282.727pt, 22.727pt) -- pmgp(282.727pt, 177.273pt) withcolor (1,0,0) withpen pencircle scaled 1.818pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Compact" & "}") scaled 1.6364, 216pt, 17.818pt, 1, (0.2,0.2,0.2));
setbounds currentpicture to pmgp(0, 0) -- pmgp(432pt, 0) -- pmgp(432pt, 200pt) -- pmgp(0, 200pt) -- cycle;
\stopMPcode
