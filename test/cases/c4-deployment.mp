\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -214.382pt; pmxx2 := 422.3pt; pmxx3 := 0;
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
draw pmhbox(38.438pt, 50.738pt, 80.975pt, 71.879pt, 0.641pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Customer's mobile device}" & "}") scaled 1, (78.925pt, -52.787pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Apple IOS or Android]" & "}") scaled 0.875, (78.925pt, -58.989pt), 0, (0.2667,0.2667,0.2667));
draw pmhbox(132.225pt, 50.738pt, 251.637pt, 138.019pt, 0.641pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Big Bank plc}" & "}") scaled 1, (258.044pt, -52.787pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Big Bank plc data center]" & "}") scaled 0.875, (258.044pt, -58.989pt), 0, (0.2667,0.2667,0.2667));
draw pmhbox(145.037pt, 65.856pt, 106.6pt, 96.28pt, 0.641pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf bigbank-api*** x8}" & "}") scaled 1, (198.338pt, -67.906pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Ubuntu 16.04 LTS]" & "}") scaled 0.875, (198.338pt, -74.108pt), 0, (0.2667,0.2667,0.2667));
draw pmhbox(157.85pt, 80.975pt, 80.975pt, 68.349pt, 0.641pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Apache Tomcat}" & "}") scaled 1, (198.338pt, -83.025pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Apache Tomcat 8.x]" & "}") scaled 0.875, (198.338pt, -89.226pt), 0, (0.2667,0.2667,0.2667));
draw pmhbox(264.45pt, 65.856pt, 106.6pt, 110.088pt, 0.641pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf bigbank-db01}" & "}") scaled 1, (317.75pt, -67.906pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Ubuntu 16.04 LTS]" & "}") scaled 0.875, (317.75pt, -74.108pt), 0, (0.2667,0.2667,0.2667));
draw pmhbox(277.262pt, 80.975pt, 80.975pt, 82.157pt, 0.641pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Oracle - Primary}" & "}") scaled 1, (317.75pt, -83.025pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Oracle 12c]" & "}") scaled 0.875, (317.75pt, -89.226pt), 0, (0.2667,0.2667,0.2667));
fill pmhbox(51.25pt, 76.363pt, 55.35pt, 33.442pt, 3.075pt) withcolor (0.2627,0.5529,0.8353);
draw pmhbox(51.25pt, 76.363pt, 55.35pt, 33.442pt, 3.075pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.512pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Mobile App}" & "}") scaled 0.875, (78.925pt, -83.64pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Xamarin]" & "}") scaled 0.6563, (78.925pt, -88.176pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides a limited subset of the\\Internet Banking functionality\\to customers via their mobile\\device." & "}") scaled 0.7175, (78.925pt, -97.619pt), 0, (1,1,1));
fill pmhbox(170.662pt, 106.6pt, 55.35pt, 29.911pt, 3.075pt) withcolor (0.2627,0.5529,0.8353);
draw pmhbox(170.662pt, 106.6pt, 55.35pt, 29.911pt, 3.075pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.512pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf API Application}" & "}") scaled 0.875, (198.338pt, -113.877pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Java and Spring MVC]" & "}") scaled 0.6563, (198.338pt, -118.413pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides Internet Banking\\functionality via a JSON/HTTPS\\API." & "}") scaled 0.7175, (198.338pt, -126.091pt), 0, (1,1,1));
fill (290.075pt, -110.658pt) -- (290.134pt, -110.392pt) -- (290.312pt, -110.128pt) -- (290.607pt, -109.866pt) -- 
  (291.018pt, -109.608pt) -- (291.544pt, -109.354pt) -- (292.182pt, -109.105pt) -- (292.929pt, -108.863pt) -- 
  (293.783pt, -108.629pt) -- (294.739pt, -108.403pt) -- (295.794pt, -108.188pt) -- (296.943pt, -107.982pt) -- 
  (298.181pt, -107.789pt) -- (299.503pt, -107.607pt) -- (300.902pt, -107.439pt) -- (302.375pt, -107.284pt) -- 
  (303.912pt, -107.144pt) -- (305.51pt, -107.018pt) -- (307.159pt, -106.909pt) -- (308.854pt, -106.815pt) -- 
  (310.587pt, -106.738pt) -- (312.351pt, -106.678pt) -- (314.138pt, -106.635pt) -- (315.94pt, -106.609pt) -- 
  (317.75pt, -106.6pt) -- (319.56pt, -106.609pt) -- (321.362pt, -106.635pt) -- (323.149pt, -106.678pt) -- 
  (324.913pt, -106.738pt) -- (326.646pt, -106.815pt) -- (328.341pt, -106.909pt) -- (329.99pt, -107.018pt) -- 
  (331.588pt, -107.144pt) -- (333.125pt, -107.284pt) -- (334.597pt, -107.439pt) -- (335.997pt, -107.607pt) -- 
  (337.319pt, -107.789pt) -- (338.557pt, -107.982pt) -- (339.706pt, -108.188pt) -- (340.761pt, -108.403pt) -- 
  (341.717pt, -108.629pt) -- (342.571pt, -108.863pt) -- (343.318pt, -109.105pt) -- (343.956pt, -109.354pt) -- 
  (344.482pt, -109.608pt) -- (344.893pt, -109.866pt) -- (345.188pt, -110.128pt) -- (345.366pt, -110.392pt) -- 
  (345.425pt, -110.658pt) -- (345.425pt, -146.261pt) -- (345.366pt, -146.527pt) -- (345.188pt, -146.791pt) -- 
  (344.893pt, -147.053pt) -- (344.482pt, -147.312pt) -- (343.956pt, -147.566pt) -- (343.318pt, -147.814pt) -- 
  (342.571pt, -148.056pt) -- (341.717pt, -148.29pt) -- (340.761pt, -148.516pt) -- (339.706pt, -148.732pt) -- 
  (338.557pt, -148.937pt) -- (337.319pt, -149.131pt) -- (335.997pt, -149.312pt) -- (334.597pt, -149.481pt) -- 
  (333.125pt, -149.635pt) -- (331.588pt, -149.776pt) -- (329.99pt, -149.901pt) -- (328.341pt, -150.01pt) -- 
  (326.646pt, -150.104pt) -- (324.913pt, -150.181pt) -- (323.149pt, -150.241pt) -- (321.362pt, -150.284pt) -- 
  (319.56pt, -150.31pt) -- (317.75pt, -150.319pt) -- (315.94pt, -150.31pt) -- (314.138pt, -150.284pt) -- 
  (312.351pt, -150.241pt) -- (310.587pt, -150.181pt) -- (308.854pt, -150.104pt) -- (307.159pt, -150.01pt) -- 
  (305.51pt, -149.901pt) -- (303.912pt, -149.776pt) -- (302.375pt, -149.635pt) -- (300.902pt, -149.481pt) -- 
  (299.503pt, -149.312pt) -- (298.181pt, -149.131pt) -- (296.943pt, -148.937pt) -- (295.794pt, -148.732pt) -- 
  (294.739pt, -148.516pt) -- (293.783pt, -148.29pt) -- (292.929pt, -148.056pt) -- (292.182pt, -147.814pt) -- 
  (291.544pt, -147.566pt) -- (291.018pt, -147.312pt) -- (290.607pt, -147.053pt) -- (290.312pt, -146.791pt) -- 
  (290.134pt, -146.527pt) -- (290.075pt, -146.261pt) -- cycle withcolor (0.7529,1,0.9333);
draw (290.075pt, -110.658pt) -- (290.134pt, -110.392pt) -- (290.312pt, -110.128pt) -- (290.607pt, -109.866pt) -- 
  (291.018pt, -109.608pt) -- (291.544pt, -109.354pt) -- (292.182pt, -109.105pt) -- (292.929pt, -108.863pt) -- 
  (293.783pt, -108.629pt) -- (294.739pt, -108.403pt) -- (295.794pt, -108.188pt) -- (296.943pt, -107.982pt) -- 
  (298.181pt, -107.789pt) -- (299.503pt, -107.607pt) -- (300.902pt, -107.439pt) -- (302.375pt, -107.284pt) -- 
  (303.912pt, -107.144pt) -- (305.51pt, -107.018pt) -- (307.159pt, -106.909pt) -- (308.854pt, -106.815pt) -- 
  (310.587pt, -106.738pt) -- (312.351pt, -106.678pt) -- (314.138pt, -106.635pt) -- (315.94pt, -106.609pt) -- 
  (317.75pt, -106.6pt) -- (319.56pt, -106.609pt) -- (321.362pt, -106.635pt) -- (323.149pt, -106.678pt) -- 
  (324.913pt, -106.738pt) -- (326.646pt, -106.815pt) -- (328.341pt, -106.909pt) -- (329.99pt, -107.018pt) -- 
  (331.588pt, -107.144pt) -- (333.125pt, -107.284pt) -- (334.597pt, -107.439pt) -- (335.997pt, -107.607pt) -- 
  (337.319pt, -107.789pt) -- (338.557pt, -107.982pt) -- (339.706pt, -108.188pt) -- (340.761pt, -108.403pt) -- 
  (341.717pt, -108.629pt) -- (342.571pt, -108.863pt) -- (343.318pt, -109.105pt) -- (343.956pt, -109.354pt) -- 
  (344.482pt, -109.608pt) -- (344.893pt, -109.866pt) -- (345.188pt, -110.128pt) -- (345.366pt, -110.392pt) -- 
  (345.425pt, -110.658pt) -- (345.425pt, -146.261pt) -- (345.366pt, -146.527pt) -- (345.188pt, -146.791pt) -- 
  (344.893pt, -147.053pt) -- (344.482pt, -147.312pt) -- (343.956pt, -147.566pt) -- (343.318pt, -147.814pt) -- 
  (342.571pt, -148.056pt) -- (341.717pt, -148.29pt) -- (340.761pt, -148.516pt) -- (339.706pt, -148.732pt) -- 
  (338.557pt, -148.937pt) -- (337.319pt, -149.131pt) -- (335.997pt, -149.312pt) -- (334.597pt, -149.481pt) -- 
  (333.125pt, -149.635pt) -- (331.588pt, -149.776pt) -- (329.99pt, -149.901pt) -- (328.341pt, -150.01pt) -- 
  (326.646pt, -150.104pt) -- (324.913pt, -150.181pt) -- (323.149pt, -150.241pt) -- (321.362pt, -150.284pt) -- 
  (319.56pt, -150.31pt) -- (317.75pt, -150.319pt) -- (315.94pt, -150.31pt) -- (314.138pt, -150.284pt) -- 
  (312.351pt, -150.241pt) -- (310.587pt, -150.181pt) -- (308.854pt, -150.104pt) -- (307.159pt, -150.01pt) -- 
  (305.51pt, -149.901pt) -- (303.912pt, -149.776pt) -- (302.375pt, -149.635pt) -- (300.902pt, -149.481pt) -- 
  (299.503pt, -149.312pt) -- (298.181pt, -149.131pt) -- (296.943pt, -148.937pt) -- (295.794pt, -148.732pt) -- 
  (294.739pt, -148.516pt) -- (293.783pt, -148.29pt) -- (292.929pt, -148.056pt) -- (292.182pt, -147.814pt) -- 
  (291.544pt, -147.566pt) -- (291.018pt, -147.312pt) -- (290.607pt, -147.053pt) -- (290.312pt, -146.791pt) -- 
  (290.134pt, -146.527pt) -- (290.075pt, -146.261pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.512pt;
begingroup interim linecap := rounded; draw (290.075pt, -110.658pt)
  .. controls (290.075pt, -112.899pt) and (302.465pt, -114.716pt) .. (317.75pt, -114.716pt)
  .. controls (333.034pt, -114.716pt) and (345.425pt, -112.899pt) .. (345.425pt, -110.658pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.512pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Database}" & "}") scaled 0.875, (317.75pt, -120.818pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Relational Database\\Schema]" & "}") scaled 0.6563, (317.75pt, -126.969pt), 0, (0,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores user registration\\information, hashed\\authentication credentials,\\access logs, etc." & "}") scaled 0.7175, (317.75pt, -138.026pt), 0, (0,0,0));
draw (106.6pt, -99.682pt) -- (170.662pt, -114.957pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt;
fill (170.912pt, -115.016pt) -- (168.122pt, -115.668pt) -- (168.716pt, -113.176pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Makes API calls to" & "}") scaled 0.75, (151.901pt, -99.632pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [json/HTTPS]}" & "}") scaled 0.75, (151.901pt, -103.988pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (226.012pt, -123.156pt)
  .. controls (236.69pt, -124.39pt) and (258.044pt, -125.625pt) .. (290.075pt, -126.859pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt; endgroup;
fill (290.331pt, -126.869pt) -- (287.721pt, -128.051pt) -- (287.82pt, -125.49pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Reads from and writes to" & "}") scaled 0.75, (274.603pt, -125.008pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [JDBC]}" & "}") scaled 0.75, (274.603pt, -129.364pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (290.075pt, -124.36pt)
  .. controls (259.496pt, -115.301pt) and (198.338pt, -106.242pt) .. (106.6pt, -97.183pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.256pt; endgroup;
fill (106.345pt, -97.158pt) -- (109.021pt, -96.134pt) -- (108.769pt, -98.684pt) -- cycle withcolor (0.2,0.2,0.2);
fill (290.321pt, -124.433pt) -- (287.5pt, -124.934pt) -- (288.228pt, -122.477pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Syncs" & "}") scaled 0.75, (202.289pt, -110.771pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Deployment Diagram for Internet Banking System - Live" & "}") scaled 1, (197.661pt, -21.627pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
