\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -380.915pt; pmxx2 := 429pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (51.563pt, -178.273pt)
  .. controls (51.563pt, -178.273pt) and (377.438pt, -178.273pt) .. (377.438pt, -178.273pt)
  .. controls (377.438pt, -178.273pt) and (377.438pt, -346.54pt) .. (377.438pt, -346.54pt)
  .. controls (377.438pt, -346.54pt) and (51.563pt, -346.54pt) .. (51.563pt, -346.54pt)
  .. controls (51.563pt, -346.54pt) and (51.563pt, -178.273pt) .. (51.563pt, -178.273pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt dashed dashpattern(on 2.406pt off 2.406pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf API Application}" & "}") scaled 1, (214.5pt, -181.023pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[CONTAINER]" & "}") scaled 0.875, (214.5pt, -189.341pt), 0, (0.2667,0.2667,0.2667));
fill pmhbox(51.563pt, 82.156pt, 74.25pt, 40.125pt, 4.125pt) withcolor (0.2627,0.5529,0.8353);
draw pmhbox(51.563pt, 82.156pt, 74.25pt, 40.125pt, 4.125pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Single Page Application}" & "}") scaled 0.875, (88.688pt, -91.919pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: javascript and angular]" & "}") scaled 0.6563, (88.688pt, -98.003pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides all the internet banking\\functionality to customers via\\their web browser." & "}") scaled 0.7175, (88.688pt, -108.303pt), 0, (1,1,1));
fill (160.188pt, -87.6pt) -- (160.267pt, -87.244pt) -- (160.505pt, -86.889pt) -- (160.901pt, -86.538pt) -- 
  (161.453pt, -86.191pt) -- (162.158pt, -85.85pt) -- (163.013pt, -85.517pt) -- (164.016pt, -85.192pt) -- 
  (165.161pt, -84.878pt) -- (166.444pt, -84.576pt) -- (167.859pt, -84.286pt) -- (169.4pt, -84.011pt) -- 
  (171.061pt, -83.751pt) -- (172.834pt, -83.507pt) -- (174.712pt, -83.281pt) -- (176.687pt, -83.074pt) -- 
  (178.75pt, -82.885pt) -- (180.893pt, -82.718pt) -- (183.105pt, -82.571pt) -- (185.379pt, -82.445pt) -- 
  (187.704pt, -82.342pt) -- (190.07pt, -82.261pt) -- (192.467pt, -82.203pt) -- (194.884pt, -82.168pt) -- 
  (197.313pt, -82.156pt) -- (199.741pt, -82.168pt) -- (202.158pt, -82.203pt) -- (204.555pt, -82.261pt) -- 
  (206.921pt, -82.342pt) -- (209.246pt, -82.445pt) -- (211.52pt, -82.571pt) -- (213.732pt, -82.718pt) -- 
  (215.875pt, -82.885pt) -- (217.938pt, -83.074pt) -- (219.913pt, -83.281pt) -- (221.791pt, -83.507pt) -- 
  (223.564pt, -83.751pt) -- (225.225pt, -84.011pt) -- (226.766pt, -84.286pt) -- (228.181pt, -84.576pt) -- 
  (229.464pt, -84.878pt) -- (230.609pt, -85.192pt) -- (231.612pt, -85.517pt) -- (232.467pt, -85.85pt) -- 
  (233.172pt, -86.191pt) -- (233.724pt, -86.538pt) -- (234.12pt, -86.889pt) -- (234.358pt, -87.244pt) -- 
  (234.438pt, -87.6pt) -- (234.438pt, -135.36pt) -- (234.358pt, -135.716pt) -- (234.12pt, -136.071pt) -- 
  (233.724pt, -136.422pt) -- (233.172pt, -136.769pt) -- (232.467pt, -137.11pt) -- (231.612pt, -137.443pt) -- 
  (230.609pt, -137.768pt) -- (229.464pt, -138.082pt) -- (228.181pt, -138.385pt) -- (226.766pt, -138.674pt) -- 
  (225.225pt, -138.95pt) -- (223.564pt, -139.209pt) -- (221.791pt, -139.453pt) -- (219.913pt, -139.679pt) -- 
  (217.938pt, -139.886pt) -- (215.875pt, -140.075pt) -- (213.732pt, -140.243pt) -- (211.52pt, -140.39pt) -- 
  (209.246pt, -140.515pt) -- (206.921pt, -140.618pt) -- (204.555pt, -140.699pt) -- (202.158pt, -140.757pt) -- 
  (199.741pt, -140.792pt) -- (197.313pt, -140.804pt) -- (194.884pt, -140.792pt) -- (192.467pt, -140.757pt) -- 
  (190.07pt, -140.699pt) -- (187.704pt, -140.618pt) -- (185.379pt, -140.515pt) -- (183.105pt, -140.39pt) -- 
  (180.893pt, -140.243pt) -- (178.75pt, -140.075pt) -- (176.687pt, -139.886pt) -- (174.712pt, -139.679pt) -- 
  (172.834pt, -139.453pt) -- (171.061pt, -139.209pt) -- (169.4pt, -138.95pt) -- (167.859pt, -138.674pt) -- 
  (166.444pt, -138.385pt) -- (165.161pt, -138.082pt) -- (164.016pt, -137.768pt) -- (163.013pt, -137.443pt) -- 
  (162.158pt, -137.11pt) -- (161.453pt, -136.769pt) -- (160.901pt, -136.422pt) -- (160.505pt, -136.071pt) -- 
  (160.267pt, -135.716pt) -- (160.188pt, -135.36pt) -- cycle withcolor (0.2627,0.5529,0.8353);
draw (160.188pt, -87.6pt) -- (160.267pt, -87.244pt) -- (160.505pt, -86.889pt) -- (160.901pt, -86.538pt) -- 
  (161.453pt, -86.191pt) -- (162.158pt, -85.85pt) -- (163.013pt, -85.517pt) -- (164.016pt, -85.192pt) -- 
  (165.161pt, -84.878pt) -- (166.444pt, -84.576pt) -- (167.859pt, -84.286pt) -- (169.4pt, -84.011pt) -- 
  (171.061pt, -83.751pt) -- (172.834pt, -83.507pt) -- (174.712pt, -83.281pt) -- (176.687pt, -83.074pt) -- 
  (178.75pt, -82.885pt) -- (180.893pt, -82.718pt) -- (183.105pt, -82.571pt) -- (185.379pt, -82.445pt) -- 
  (187.704pt, -82.342pt) -- (190.07pt, -82.261pt) -- (192.467pt, -82.203pt) -- (194.884pt, -82.168pt) -- 
  (197.313pt, -82.156pt) -- (199.741pt, -82.168pt) -- (202.158pt, -82.203pt) -- (204.555pt, -82.261pt) -- 
  (206.921pt, -82.342pt) -- (209.246pt, -82.445pt) -- (211.52pt, -82.571pt) -- (213.732pt, -82.718pt) -- 
  (215.875pt, -82.885pt) -- (217.938pt, -83.074pt) -- (219.913pt, -83.281pt) -- (221.791pt, -83.507pt) -- 
  (223.564pt, -83.751pt) -- (225.225pt, -84.011pt) -- (226.766pt, -84.286pt) -- (228.181pt, -84.576pt) -- 
  (229.464pt, -84.878pt) -- (230.609pt, -85.192pt) -- (231.612pt, -85.517pt) -- (232.467pt, -85.85pt) -- 
  (233.172pt, -86.191pt) -- (233.724pt, -86.538pt) -- (234.12pt, -86.889pt) -- (234.358pt, -87.244pt) -- 
  (234.438pt, -87.6pt) -- (234.438pt, -135.36pt) -- (234.358pt, -135.716pt) -- (234.12pt, -136.071pt) -- 
  (233.724pt, -136.422pt) -- (233.172pt, -136.769pt) -- (232.467pt, -137.11pt) -- (231.612pt, -137.443pt) -- 
  (230.609pt, -137.768pt) -- (229.464pt, -138.082pt) -- (228.181pt, -138.385pt) -- (226.766pt, -138.674pt) -- 
  (225.225pt, -138.95pt) -- (223.564pt, -139.209pt) -- (221.791pt, -139.453pt) -- (219.913pt, -139.679pt) -- 
  (217.938pt, -139.886pt) -- (215.875pt, -140.075pt) -- (213.732pt, -140.243pt) -- (211.52pt, -140.39pt) -- 
  (209.246pt, -140.515pt) -- (206.921pt, -140.618pt) -- (204.555pt, -140.699pt) -- (202.158pt, -140.757pt) -- 
  (199.741pt, -140.792pt) -- (197.313pt, -140.804pt) -- (194.884pt, -140.792pt) -- (192.467pt, -140.757pt) -- 
  (190.07pt, -140.699pt) -- (187.704pt, -140.618pt) -- (185.379pt, -140.515pt) -- (183.105pt, -140.39pt) -- 
  (180.893pt, -140.243pt) -- (178.75pt, -140.075pt) -- (176.687pt, -139.886pt) -- (174.712pt, -139.679pt) -- 
  (172.834pt, -139.453pt) -- (171.061pt, -139.209pt) -- (169.4pt, -138.95pt) -- (167.859pt, -138.674pt) -- 
  (166.444pt, -138.385pt) -- (165.161pt, -138.082pt) -- (164.016pt, -137.768pt) -- (163.013pt, -137.443pt) -- 
  (162.158pt, -137.11pt) -- (161.453pt, -136.769pt) -- (160.901pt, -136.422pt) -- (160.505pt, -136.071pt) -- 
  (160.267pt, -135.716pt) -- (160.188pt, -135.36pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.688pt;
begingroup interim linecap := rounded; draw (160.188pt, -87.6pt)
  .. controls (160.188pt, -90.606pt) and (176.809pt, -93.043pt) .. (197.313pt, -93.043pt)
  .. controls (217.816pt, -93.043pt) and (234.438pt, -90.606pt) .. (234.438pt, -87.6pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.688pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Database}" & "}") scaled 0.875, (197.313pt, -101.23pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Relational Database\\Schema]" & "}") scaled 0.6563, (197.313pt, -109.48pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores user registration\\information, hashed\\authentication credentials,\\access logs, etc." & "}") scaled 0.7175, (197.313pt, -124.313pt), 0, (1,1,1));
fill pmhbox(268.813pt, 82.156pt, 74.25pt, 40.125pt, 4.125pt) withcolor (0.6,0.6,0.6);
draw pmhbox(268.813pt, 82.156pt, 74.25pt, 40.125pt, 4.125pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Mainframe Banking System}" & "}") scaled 0.875, (305.938pt, -91.919pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (305.938pt, -98.003pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores all of the core banking\\information about customers,\\accounts, transactions, etc." & "}") scaled 0.7175, (305.938pt, -108.303pt), 0, (1,1,1));
fill pmhbox(68.75pt, 212.648pt, 74.25pt, 35.39pt, 4.125pt) withcolor (0.5216,0.7333,0.9412);
draw pmhbox(68.75pt, 212.648pt, 74.25pt, 35.39pt, 4.125pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Sign In Controller}" & "}") scaled 0.875, (105.875pt, -222.41pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: MVC Rest Controller]" & "}") scaled 0.6563, (105.875pt, -228.495pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Allows users to sign in to the\\internet banking system" & "}") scaled 0.7175, (105.875pt, -236.427pt), 0, (1,1,1));
fill pmhbox(177.375pt, 212.648pt, 74.25pt, 41.165pt, 4.125pt) withcolor (0.5216,0.7333,0.9412);
draw pmhbox(177.375pt, 212.648pt, 74.25pt, 41.165pt, 4.125pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Accounts Summary}\\{\bf Controller}" & "}") scaled 0.875, (214.5pt, -225.298pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: MVC Rest Controller]" & "}") scaled 0.6563, (214.5pt, -234.27pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides customers with a summary\\of their bank accounts" & "}") scaled 0.7175, (214.5pt, -242.202pt), 0, (1,1,1));
fill pmhbox(286pt, 212.648pt, 74.25pt, 40.125pt, 4.125pt) withcolor (0.5216,0.7333,0.9412);
draw pmhbox(286pt, 212.648pt, 74.25pt, 40.125pt, 4.125pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Security Component}" & "}") scaled 0.875, (323.125pt, -222.41pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: Spring Bean]" & "}") scaled 0.6563, (323.125pt, -228.495pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides functionality related to\\singing in, changing passwords,\\etc." & "}") scaled 0.7175, (323.125pt, -238.795pt), 0, (1,1,1));
fill (68.75pt, -293.631pt) -- (68.829pt, -293.275pt) -- (69.068pt, -292.92pt) -- (69.463pt, -292.569pt) -- 
  (70.015pt, -292.222pt) -- (70.72pt, -291.881pt) -- (71.576pt, -291.548pt) -- (72.579pt, -291.223pt) -- 
  (73.724pt, -290.909pt) -- (75.007pt, -290.607pt) -- (76.422pt, -290.317pt) -- (77.963pt, -290.042pt) -- 
  (79.624pt, -289.782pt) -- (81.397pt, -289.538pt) -- (83.275pt, -289.312pt) -- (85.25pt, -289.105pt) -- 
  (87.313pt, -288.917pt) -- (89.455pt, -288.749pt) -- (91.668pt, -288.602pt) -- (93.942pt, -288.476pt) -- 
  (96.266pt, -288.373pt) -- (98.632pt, -288.292pt) -- (101.029pt, -288.234pt) -- (103.447pt, -288.199pt) -- 
  (105.875pt, -288.187pt) -- (108.303pt, -288.199pt) -- (110.721pt, -288.234pt) -- (113.118pt, -288.292pt) -- 
  (115.484pt, -288.373pt) -- (117.808pt, -288.476pt) -- (120.082pt, -288.602pt) -- (122.295pt, -288.749pt) -- 
  (124.438pt, -288.917pt) -- (126.5pt, -289.105pt) -- (128.475pt, -289.312pt) -- (130.353pt, -289.538pt) -- 
  (132.126pt, -289.782pt) -- (133.787pt, -290.042pt) -- (135.328pt, -290.317pt) -- (136.743pt, -290.607pt) -- 
  (138.026pt, -290.909pt) -- (139.171pt, -291.223pt) -- (140.174pt, -291.548pt) -- (141.03pt, -291.881pt) -- 
  (141.735pt, -292.222pt) -- (142.287pt, -292.569pt) -- (142.682pt, -292.92pt) -- (142.921pt, -293.275pt) -- 
  (143pt, -293.631pt) -- (143pt, -317.087pt) -- (142.921pt, -317.443pt) -- (142.682pt, -317.797pt) -- 
  (142.287pt, -318.149pt) -- (141.735pt, -318.496pt) -- (141.03pt, -318.837pt) -- (140.174pt, -319.17pt) -- 
  (139.171pt, -319.495pt) -- (138.026pt, -319.809pt) -- (136.743pt, -320.111pt) -- (135.328pt, -320.401pt) -- 
  (133.787pt, -320.676pt) -- (132.126pt, -320.936pt) -- (130.353pt, -321.18pt) -- (128.475pt, -321.406pt) -- 
  (126.5pt, -321.613pt) -- (124.438pt, -321.801pt) -- (122.295pt, -321.969pt) -- (120.082pt, -322.116pt) -- 
  (117.808pt, -322.242pt) -- (115.484pt, -322.345pt) -- (113.118pt, -322.426pt) -- (110.721pt, -322.484pt) -- 
  (108.303pt, -322.519pt) -- (105.875pt, -322.531pt) -- (103.447pt, -322.519pt) -- (101.029pt, -322.484pt) -- 
  (98.632pt, -322.426pt) -- (96.266pt, -322.345pt) -- (93.942pt, -322.242pt) -- (91.668pt, -322.116pt) -- 
  (89.455pt, -321.969pt) -- (87.313pt, -321.801pt) -- (85.25pt, -321.613pt) -- (83.275pt, -321.406pt) -- 
  (81.397pt, -321.18pt) -- (79.624pt, -320.936pt) -- (77.963pt, -320.676pt) -- (76.422pt, -320.401pt) -- 
  (75.007pt, -320.111pt) -- (73.724pt, -319.809pt) -- (72.579pt, -319.495pt) -- (71.576pt, -319.17pt) -- 
  (70.72pt, -318.837pt) -- (70.015pt, -318.496pt) -- (69.463pt, -318.149pt) -- (69.068pt, -317.797pt) -- 
  (68.829pt, -317.443pt) -- (68.75pt, -317.087pt) -- cycle withcolor (0.5216,0.7333,0.9412);
draw (68.75pt, -293.631pt) -- (68.829pt, -293.275pt) -- (69.068pt, -292.92pt) -- (69.463pt, -292.569pt) -- 
  (70.015pt, -292.222pt) -- (70.72pt, -291.881pt) -- (71.576pt, -291.548pt) -- (72.579pt, -291.223pt) -- 
  (73.724pt, -290.909pt) -- (75.007pt, -290.607pt) -- (76.422pt, -290.317pt) -- (77.963pt, -290.042pt) -- 
  (79.624pt, -289.782pt) -- (81.397pt, -289.538pt) -- (83.275pt, -289.312pt) -- (85.25pt, -289.105pt) -- 
  (87.313pt, -288.917pt) -- (89.455pt, -288.749pt) -- (91.668pt, -288.602pt) -- (93.942pt, -288.476pt) -- 
  (96.266pt, -288.373pt) -- (98.632pt, -288.292pt) -- (101.029pt, -288.234pt) -- (103.447pt, -288.199pt) -- 
  (105.875pt, -288.187pt) -- (108.303pt, -288.199pt) -- (110.721pt, -288.234pt) -- (113.118pt, -288.292pt) -- 
  (115.484pt, -288.373pt) -- (117.808pt, -288.476pt) -- (120.082pt, -288.602pt) -- (122.295pt, -288.749pt) -- 
  (124.438pt, -288.917pt) -- (126.5pt, -289.105pt) -- (128.475pt, -289.312pt) -- (130.353pt, -289.538pt) -- 
  (132.126pt, -289.782pt) -- (133.787pt, -290.042pt) -- (135.328pt, -290.317pt) -- (136.743pt, -290.607pt) -- 
  (138.026pt, -290.909pt) -- (139.171pt, -291.223pt) -- (140.174pt, -291.548pt) -- (141.03pt, -291.881pt) -- 
  (141.735pt, -292.222pt) -- (142.287pt, -292.569pt) -- (142.682pt, -292.92pt) -- (142.921pt, -293.275pt) -- 
  (143pt, -293.631pt) -- (143pt, -317.087pt) -- (142.921pt, -317.443pt) -- (142.682pt, -317.797pt) -- 
  (142.287pt, -318.149pt) -- (141.735pt, -318.496pt) -- (141.03pt, -318.837pt) -- (140.174pt, -319.17pt) -- 
  (139.171pt, -319.495pt) -- (138.026pt, -319.809pt) -- (136.743pt, -320.111pt) -- (135.328pt, -320.401pt) -- 
  (133.787pt, -320.676pt) -- (132.126pt, -320.936pt) -- (130.353pt, -321.18pt) -- (128.475pt, -321.406pt) -- 
  (126.5pt, -321.613pt) -- (124.438pt, -321.801pt) -- (122.295pt, -321.969pt) -- (120.082pt, -322.116pt) -- 
  (117.808pt, -322.242pt) -- (115.484pt, -322.345pt) -- (113.118pt, -322.426pt) -- (110.721pt, -322.484pt) -- 
  (108.303pt, -322.519pt) -- (105.875pt, -322.531pt) -- (103.447pt, -322.519pt) -- (101.029pt, -322.484pt) -- 
  (98.632pt, -322.426pt) -- (96.266pt, -322.345pt) -- (93.942pt, -322.242pt) -- (91.668pt, -322.116pt) -- 
  (89.455pt, -321.969pt) -- (87.313pt, -321.801pt) -- (85.25pt, -321.613pt) -- (83.275pt, -321.406pt) -- 
  (81.397pt, -321.18pt) -- (79.624pt, -320.936pt) -- (77.963pt, -320.676pt) -- (76.422pt, -320.401pt) -- 
  (75.007pt, -320.111pt) -- (73.724pt, -319.809pt) -- (72.579pt, -319.495pt) -- (71.576pt, -319.17pt) -- 
  (70.72pt, -318.837pt) -- (70.015pt, -318.496pt) -- (69.463pt, -318.149pt) -- (69.068pt, -317.797pt) -- 
  (68.829pt, -317.443pt) -- (68.75pt, -317.087pt) -- cycle withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.688pt;
begingroup interim linecap := rounded; draw (68.75pt, -293.631pt)
  .. controls (68.75pt, -296.637pt) and (85.371pt, -299.074pt) .. (105.875pt, -299.074pt)
  .. controls (126.379pt, -299.074pt) and (143pt, -296.637pt) .. (143pt, -293.631pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.688pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Cache}" & "}") scaled 0.875, (105.875pt, -307.261pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: Redis]" & "}") scaled 0.6563, (105.875pt, -313.345pt), 0, (1,1,1));
fill pmhbox(177.375pt, 288.187pt, 74.25pt, 24.887pt, 4.125pt) withcolor (0.8,0.8,0.8);
draw pmhbox(177.375pt, 288.187pt, 74.25pt, 24.887pt, 4.125pt) withcolor (0.749,0.749,0.749) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Events}" & "}") scaled 0.875, (214.5pt, -297.95pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[component queu: Kafka]" & "}") scaled 0.6563, (214.5pt, -304.034pt), 0, (1,1,1));
fill pmhbox(286pt, 288.187pt, 74.25pt, 41.165pt, 4.125pt) withcolor (0.8,0.8,0.8);
draw pmhbox(286pt, 288.187pt, 74.25pt, 41.165pt, 4.125pt) withcolor (0.749,0.749,0.749) withpen pencircle scaled 0.688pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Mainframe Banking System}\\{\bf Facade}" & "}") scaled 0.875, (323.125pt, -300.837pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: Spring Bean]" & "}") scaled 0.6563, (323.125pt, -309.809pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A facade onto the mainframe\\banking system." & "}") scaled 0.7175, (323.125pt, -317.742pt), 0, (1,1,1));
draw (143pt, -230.747pt) -- (286pt, -232.306pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt;
fill (286.344pt, -232.309pt) -- (282.888pt, -233.991pt) -- (282.925pt, -230.553pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (218.811pt, -231.526pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (244.097pt, -253.812pt)
  .. controls (252.336pt, -265.271pt) and (268.813pt, -276.729pt) .. (293.528pt, -288.187pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt; endgroup;
fill (293.84pt, -288.332pt) -- (289.998pt, -288.445pt) -- (291.444pt, -285.327pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (273.123pt, -271pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (302.304pt, -212.648pt)
  .. controls (289.877pt, -187.924pt) and (265.024pt, -163.201pt) .. (227.745pt, -138.478pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt; endgroup;
fill (227.458pt, -138.288pt) -- (231.273pt, -138.756pt) -- (229.373pt, -141.62pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Read {\char38} write to" & "}") scaled 0.75, (278.43pt, -175.563pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [JDBC]}" & "}") scaled 0.75, (278.43pt, -181.407pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (321.412pt, -288.187pt)
  .. controls (319.111pt, -232.885pt) and (314.51pt, -177.583pt) .. (307.607pt, -122.281pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt; endgroup;
fill (307.564pt, -121.94pt) -- (309.696pt, -125.139pt) -- (306.285pt, -125.564pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (318.82pt, -205.234pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [XML/HTTPS]}" & "}") scaled 0.75, (327.091pt, -211.078pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (91.379pt, -122.281pt)
  .. controls (93.399pt, -152.404pt) and (97.44pt, -182.526pt) .. (103.501pt, -212.648pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt; endgroup;
fill (91.356pt, -121.938pt) -- (93.301pt, -125.253pt) -- (89.871pt, -125.483pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (101.751pt, -167.465pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [JSON/HTTPS]}" & "}") scaled 0.75, (111.362pt, -173.308pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (107.954pt, -122.281pt)
  .. controls (122.417pt, -152.404pt) and (151.344pt, -182.526pt) .. (194.734pt, -212.648pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.344pt; endgroup;
fill (195.017pt, -212.844pt) -- (191.213pt, -212.295pt) -- (193.173pt, -209.471pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (155.655pt, -167.465pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [JSON/HTTPS]}" & "}") scaled 0.75, (165.266pt, -173.308pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Component diagram for Internet Banking System - API Application" & "}") scaled 1, (209.907pt, -29.012pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
