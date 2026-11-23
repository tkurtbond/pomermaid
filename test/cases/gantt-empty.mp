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
pmgtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Empty" & "}") scaled 1.6364, 216pt, 17.818pt, 1, (0.2,0.2,0.2));
setbounds currentpicture to pmgp(0, 0) -- pmgp(432pt, 0) -- pmgp(432pt, 90.909pt) -- pmgp(0, 90.909pt) -- cycle;
\stopMPcode
