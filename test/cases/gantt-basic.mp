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
fill pmgbox(0pt, 43.636pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
fill pmgbox(0pt, 87.273pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(0pt, 109.091pt, 397.909pt, 21.818pt, 0pt) withcolor (1,1,1);
fill pmgbox(0pt, 65.455pt, 397.909pt, 21.818pt, 0pt) withcolor (0.9412,0.9412,1);
draw pmgp(91.818pt, 31.818pt) -- pmgp(91.818pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-05" & "}") scaled 0.9091, 91.818pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(133.636pt, 31.818pt) -- pmgp(133.636pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-12" & "}") scaled 0.9091, 133.636pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(174.545pt, 31.818pt) -- pmgp(174.545pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-19" & "}") scaled 0.9091, 174.545pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(216.364pt, 31.818pt) -- pmgp(216.364pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-01-26" & "}") scaled 0.9091, 216.364pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(257.273pt, 31.818pt) -- pmgp(257.273pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-02-02" & "}") scaled 0.9091, 257.273pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(299.091pt, 31.818pt) -- pmgp(299.091pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-02-09" & "}") scaled 0.9091, 299.091pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
draw pmgp(340pt, 31.818pt) -- pmgp(340pt, 132.727pt) withcolor (0.8627,0.8627,0.8627) withpen pencircle scaled 0.909pt;
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2014-02-16" & "}") scaled 0.9091, 340pt, 141.818pt, 1, (0.3608,0.3608,0.3608));
fill pmgbox(68.182pt, 45.455pt, 177.273pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(68.182pt, 45.455pt, 177.273pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(133.636pt, 89.091pt, 70.909pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(133.636pt, 89.091pt, 70.909pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(204.545pt, 110.909pt, 141.818pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(204.545pt, 110.909pt, 141.818pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
fill pmgbox(245.455pt, 67.273pt, 118.182pt, 18.182pt, 2.727pt) withcolor (0.5412,0.5647,0.8667);
draw pmgbox(245.455pt, 67.273pt, 118.182pt, 18.182pt, 2.727pt) withcolor (0.3255,0.3098,0.7373) withpen pencircle scaled 1.818pt;
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "A task" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 177.273pt: if pmgw > 152.455pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 177.273pt: if pmgw > 152.455pt: 63.636pt else: 250pt fi else: 156.818pt fi, 54.727pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Task in Another" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 70.909pt: if pmgw > 193.364pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 70.909pt: if pmgw > 193.364pt: 129.091pt else: 209.091pt fi else: 169.091pt fi, 98.364pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "another task" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 141.818pt: if pmgw > 51.545pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 141.818pt: if pmgw > 51.545pt: 200pt else: 350.909pt fi else: 275.455pt fi, 120.182pt, pmga, pmgc);
pmgt := textext("\framed[frame=off,offset=0pt,align=middle]{" & "Another task" & "}") scaled 1; pmgw := pmgwd(pmgt);
if pmgw > 118.182pt: if pmgw > 34.273pt: pmga := 2; else: pmga := 0; fi pmgc := (0,0,0);
  else: pmga := 1; pmgc := (1,1,1); fi
pmgtext(pmgt, if pmgw > 118.182pt: if pmgw > 34.273pt: 240.909pt else: 368.182pt fi else: 304.545pt fi, 76.545pt, pmga, pmgc);
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Section" & "}") scaled 1, 9.091pt, 67.273pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=flushleft]{" & "Another" & "}") scaled 1, 9.091pt, 110.909pt, 0, (0.2,0.2,0.2));
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A Gantt Diagram" & "}") scaled 1.6364, 216pt, 17.818pt, 1, (0.2,0.2,0.2));
setbounds currentpicture to pmgp(0, 0) -- pmgp(432pt, 0) -- pmgp(432pt, 178.182pt) -- pmgp(0, 178.182pt) -- cycle;
\stopMPcode
