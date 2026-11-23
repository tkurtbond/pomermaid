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
fill pmgbox(135.455pt, 31.818pt, 26.364pt, 384.545pt, 0pt) withcolor (0.9333,0.9333,0.9333);
fill pmgbox(229.091pt, 31.818pt, 27.273pt, 384.545pt, 0pt) withcolor (0.9333,0.9333,0.9333);
fill pmgbox(323.636pt, 31.818pt, 26.364pt, 384.545pt, 0pt) withcolor (0.9333,0.9333,0.9333);
fill pmgbox(0pt, 43.636pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(135.455pt, 43.636pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(229.091pt, 43.636pt, 27.273pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(323.636pt, 43.636pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(0pt, 130.909pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 130.909pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 130.909pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 130.909pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 152.727pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 152.727pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 152.727pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 152.727pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 283.636pt, 397.909pt, 21.818pt, 0pt) withcolor (1,0.9922,0.8);
fill pmgbox(135.455pt, 283.636pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(229.091pt, 283.636pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(323.636pt, 283.636pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(0pt, 65.455pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(135.455pt, 65.455pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(229.091pt, 65.455pt, 27.273pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(323.636pt, 65.455pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(0pt, 174.545pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 174.545pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 174.545pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 174.545pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 305.455pt, 397.909pt, 21.818pt, 0pt) withcolor (1,0.9922,0.8);
fill pmgbox(135.455pt, 305.455pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(229.091pt, 305.455pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(323.636pt, 305.455pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(0pt, 327.273pt, 397.909pt, 21.818pt, 0pt) withcolor (1,0.9922,0.8);
fill pmgbox(135.455pt, 327.273pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(229.091pt, 327.273pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(323.636pt, 327.273pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9373,0.7451);
fill pmgbox(0pt, 87.273pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(135.455pt, 87.273pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(229.091pt, 87.273pt, 27.273pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(323.636pt, 87.273pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(0pt, 196.364pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 196.364pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 196.364pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 196.364pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 349.091pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 349.091pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 349.091pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 349.091pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 370.909pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 370.909pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 370.909pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 370.909pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 392.727pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 392.727pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 392.727pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 392.727pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 109.091pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(135.455pt, 109.091pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(229.091pt, 109.091pt, 27.273pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(323.636pt, 109.091pt, 26.364pt, 21.818pt, 0pt) withcolor (0.8824,0.8824,0.9412);
fill pmgbox(0pt, 218.182pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 218.182pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 218.182pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 218.182pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 240pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 240pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 240pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 240pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(0pt, 261.818pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(135.455pt, 261.818pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(229.091pt, 261.818pt, 27.273pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
fill pmgbox(323.636pt, 261.818pt, 26.364pt, 21.818pt, 0pt) withcolor (0.9451,0.9451,0.9451);
draw pmgp(81.818pt, 31.818pt) -- pmgp(81.818pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-07" & "}") scaled 0.9091, 81.818pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(108.182pt, 31.818pt) -- pmgp(108.182pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-09" & "}") scaled 0.9091, 108.182pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(135.455pt, 31.818pt) -- pmgp(135.455pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-11" & "}") scaled 0.9091, 135.455pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(161.818pt, 31.818pt) -- pmgp(161.818pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-13" & "}") scaled 0.9091, 161.818pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(189.091pt, 31.818pt) -- pmgp(189.091pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-15" & "}") scaled 0.9091, 189.091pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(216.364pt, 31.818pt) -- pmgp(216.364pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-17" & "}") scaled 0.9091, 216.364pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(242.727pt, 31.818pt) -- pmgp(242.727pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-19" & "}") scaled 0.9091, 242.727pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(270pt, 31.818pt) -- pmgp(270pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-21" & "}") scaled 0.9091, 270pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(296.364pt, 31.818pt) -- pmgp(296.364pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-23" & "}") scaled 0.9091, 296.364pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(323.636pt, 31.818pt) -- pmgp(323.636pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-25" & "}") scaled 0.9091, 323.636pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(350pt, 31.818pt) -- pmgp(350pt, 416.364pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-27" & "}") scaled 0.9091, 350pt, 425.455pt, 1, (0.3608,0.3608,0.3608));
fill pmgbox(68.182pt, 45.455pt, 27.273pt, 18.182pt, 2.727pt) withcolor (0.8275,0.8275,0.8275);
draw pmgbox(68.182pt, 45.455pt, 27.273pt, 18.182pt, 2.727pt) withcolor (0.502,0.502,0.502) withpen pencircle scaled 1.818pt;
fill pmgbox(68.182pt, 132.727pt, 13.636pt, 18.182pt, 2.727pt) withcolor (0.8275,0.8275,0.8275);
draw pmgbox(68.182pt, 132.727pt, 13.636pt, 18.182pt, 2.727pt) withcolor (1,0.5333,0.5333) withpen pencircle scaled 1.818pt;
fill pmgbox(95.455pt, 154.545pt, 26.364pt, 18.182pt, 2.727pt) withcolor (0.8275,0.8275,0.8275);
draw pmgbox(95.455pt, 154.545pt, 26.364pt, 18.182pt, 2.727pt) withcolor (1,0.5333,0.5333) withpen pencircle scaled 1.818pt;
fill pmgbox(95.455pt, 285.455pt, 40pt, 18.182pt, 2.727pt) withcolor (0.749,0.7804,1);
draw pmgbox(95.455pt, 285.455pt, 40pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(108.182pt, 67.273pt, 67.273pt, 18.182pt, 2.727pt) withcolor (0.749,0.7804,1);
draw pmgbox(108.182pt, 67.273pt, 67.273pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(121.818pt, 176.364pt, 67.273pt, 18.182pt, 2.727pt) withcolor (0.749,0.7804,1);
draw pmgbox(121.818pt, 176.364pt, 67.273pt, 18.182pt, 2.727pt) withcolor (1,0.5333,0.5333) withpen pencircle scaled 1.818pt;
fill pmgbox(161.818pt, 307.273pt, 11.818pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(161.818pt, 307.273pt, 11.818pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(161.818pt, 329.091pt, 27.273pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(161.818pt, 329.091pt, 27.273pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(175.455pt, 89.091pt, 94.545pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(175.455pt, 89.091pt, 94.545pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(189.091pt, 198.182pt, 94.545pt, 18.182pt, 2.727pt) withcolor (1,0,0);
draw pmgbox(189.091pt, 198.182pt, 94.545pt, 18.182pt, 2.727pt) withcolor (1,0.5333,0.5333) withpen pencircle scaled 1.818pt;
fill pmgbox(189.091pt, 350.909pt, 40pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(189.091pt, 350.909pt, 40pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(256.364pt, 372.727pt, 10.909pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(256.364pt, 372.727pt, 10.909pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(267.273pt, 394.545pt, 27.273pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(267.273pt, 394.545pt, 27.273pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(270pt, 110.909pt, 93.636pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(270pt, 110.909pt, 93.636pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(283.636pt, 220pt, 26.364pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(283.636pt, 220pt, 26.364pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(310pt, 241.818pt, 13.636pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(310pt, 241.818pt, 13.636pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(314.545pt, 263.636pt, 18.182pt, 18.182pt, 2.727pt) shifted -pmgp(323.636pt, 272.727pt) rotated 45 scaled 0.8 shifted pmgp(323.636pt, 272.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(314.545pt, 263.636pt, 18.182pt, 18.182pt, 2.727pt) shifted -pmgp(323.636pt, 272.727pt) rotated 45 scaled 0.8 shifted pmgp(323.636pt, 272.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Completed task}" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 27.273pt: if pmgw > 302.455pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (0,0.1922,0.3882); fi
pmgtext(pmgt, if pmgw > 27.273pt: if pmgw > 302.455pt: 63.636pt else: 100pt fi else: 81.818pt fi, 54.727pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Completed task in the critical line" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 13.636pt: if pmgw > 316.091pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (0,0,0); fi
pmgtext(pmgt, if pmgw > 13.636pt: if pmgw > 316.091pt: 63.636pt else: 86.364pt fi else: 75pt fi, 142pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Implement parser and jison" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 26.364pt: if pmgw > 276.091pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (0,0,0); fi
pmgtext(pmgt, if pmgw > 26.364pt: if pmgw > 276.091pt: 90.909pt else: 126.364pt fi else: 108.636pt fi, 163.818pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Describe gantt syntax" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 66.364pt: if pmgw > 236.091pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (0,0,0); fi
pmgtext(pmgt, if pmgw > 40pt: if pmgw > 262.455pt: 90.909pt else: 140pt fi else: 115.455pt fi, 294.727pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Active task}" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 67.273pt: if pmgw > 222.455pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0.1922,0.3882);
  else: pmga := 1; pmgc := (0,0.1922,0.3882); fi
pmgtext(pmgt, if pmgw > 67.273pt: if pmgw > 222.455pt: 103.636pt else: 180pt fi else: 141.818pt fi, 76.545pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create tests for parser" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 67.273pt: if pmgw > 208.818pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (0,0,0); fi
pmgtext(pmgt, if pmgw > 67.273pt: if pmgw > 208.818pt: 117.273pt else: 193.636pt fi else: 155.455pt fi, 185.636pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Add gantt diagram to demo page" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 11.818pt: if pmgw > 224.273pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 11.818pt: if pmgw > 224.273pt: 157.273pt else: 178.182pt fi else: 167.727pt fi, 316.545pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Add another diagram to demo page" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 27.273pt: if pmgw > 208.818pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 27.273pt: if pmgw > 208.818pt: 157.273pt else: 193.636pt fi else: 175.455pt fi, 338.364pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Future task" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 94.545pt: if pmgw > 127.909pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 94.545pt: if pmgw > 127.909pt: 170.909pt else: 274.545pt fi else: 222.727pt fi, 98.364pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Future task in critical line" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 94.545pt: if pmgw > 114.273pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 94.545pt: if pmgw > 114.273pt: 184.545pt else: 288.182pt fi else: 236.364pt fi, 207.455pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Describe gantt syntax" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 67.273pt: if pmgw > 141.545pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 40pt: if pmgw > 168.818pt: 184.545pt else: 233.636pt fi else: 209.091pt fi, 360.182pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Add gantt diagram to demo page" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 10.909pt: if pmgw > 130.636pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 10.909pt: if pmgw > 130.636pt: 251.818pt else: 271.818pt fi else: 261.818pt fi, 382pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Add another diagram to demo page" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 27.273pt: if pmgw > 103.364pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 27.273pt: if pmgw > 103.364pt: 262.727pt else: 299.091pt fi else: 280.909pt fi, 403.818pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Future task2" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 93.636pt: if pmgw > 34.273pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 93.636pt: if pmgw > 34.273pt: 265.455pt else: 368.182pt fi else: 316.818pt fi, 120.182pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Create tests for renderer" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 26.364pt: if pmgw > 87.909pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 26.364pt: if pmgw > 87.909pt: 279.091pt else: 314.545pt fi else: 296.818pt fi, 229.273pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Add to mermaid" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 40pt: if pmgw > 47.909pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 13.636pt: if pmgw > 74.273pt: 305.455pt else: 328.182pt fi else: 316.818pt fi, 251.091pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it Functionality added}" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 18.182pt: if pmgw > 56.091pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 18.182pt: if pmgw > 65.182pt: 310pt else: 337.273pt fi else: 323.636pt fi, 272.909pt, pmga, pmgc);
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "A section" & "}") scaled 1, 9.091pt, 89.091pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Critical tasks" & "}") scaled 1, 9.091pt, 209.091pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Documentation" & "}") scaled 1, 9.091pt, 318.182pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Last section" & "}") scaled 1, 9.091pt, 383.636pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Adding GANTT diagram functionality to mermaid" & "}") scaled 1.6364, 216pt, 17.818pt, 1, (0.2,0.2,0.2));
setbounds currentpicture to pmgp(0, 0) -- pmgp(432pt, 0) -- pmgp(432pt, 461.818pt) -- pmgp(0, 461.818pt) -- cycle;
\stopMPcode
