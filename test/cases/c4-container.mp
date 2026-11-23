\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -322.903pt; pmxx2 := 430.1pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (41.25pt, -147.647pt)
  .. controls (41.25pt, -147.647pt) and (388.85pt, -147.647pt) .. (388.85pt, -147.647pt)
  .. controls (388.85pt, -147.647pt) and (388.85pt, -295.403pt) .. (388.85pt, -295.403pt)
  .. controls (388.85pt, -295.403pt) and (41.25pt, -295.403pt) .. (41.25pt, -295.403pt)
  .. controls (41.25pt, -295.403pt) and (41.25pt, -147.647pt) .. (41.25pt, -147.647pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt dashed dashpattern(on 1.925pt off 1.925pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Internet Banking}" & "}") scaled 1, (215.05pt, -149.847pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[CONTAINER]" & "}") scaled 0.875, (215.05pt, -156.502pt), 0, (0.2667,0.2667,0.2667));
fill pmhbox(41.25pt, 65.725pt, 59.4pt, 28.312pt, 3.3pt) withcolor (0.6,0.6,0.6);
draw pmhbox(41.25pt, 65.725pt, 59.4pt, 28.312pt, 3.3pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.55pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf E-Mail System}" & "}") scaled 0.875, (70.95pt, -73.535pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (70.95pt, -78.402pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "The internal Microsoft Exchange\\system" & "}") scaled 0.7175, (70.95pt, -84.748pt), 0, (1,1,1));
fill pmhbox(128.15pt, 89.36pt, 59.4pt, 28.312pt, 10.514pt) withcolor (0.0314,0.2588,0.4824);
draw pmhbox(128.15pt, 89.36pt, 59.4pt, 28.312pt, 10.514pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.55pt;
fill fullcircle scaled 27.324pt shifted (157.85pt, -79.387pt) withcolor (0.0314,0.2588,0.4824);
draw fullcircle scaled 27.324pt shifted (157.85pt, -79.387pt) withcolor (0.0275,0.2314,0.4353) withpen pencircle scaled 0.55pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Customer}" & "}") scaled 0.875, (157.85pt, -97.17pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Person]" & "}") scaled 0.6563, (157.85pt, -102.038pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "A customer of the bank, with\\personal bank accounts" & "}") scaled 0.7175, (157.85pt, -108.384pt), 0, (1,1,1));
fill pmhbox(55pt, 175.147pt, 59.4pt, 32.1pt, 3.3pt) withcolor (0.2627,0.5529,0.8353);
draw pmhbox(55pt, 175.147pt, 59.4pt, 32.1pt, 3.3pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.55pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Single-Page App}" & "}") scaled 0.875, (84.7pt, -182.957pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: JavaScript, Angular]" & "}") scaled 0.6563, (84.7pt, -187.825pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides all the Internet banking\\functionality to customers via\\their web browser" & "}") scaled 0.7175, (84.7pt, -196.065pt), 0, (1,1,1));
fill pmhbox(141.9pt, 175.147pt, 59.4pt, 32.1pt, 3.3pt) withcolor (0.702,0.702,0.702);
draw pmhbox(141.9pt, 175.147pt, 59.4pt, 32.1pt, 3.3pt) withcolor (0.651,0.651,0.651) withpen pencircle scaled 0.55pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Mobile App}" & "}") scaled 0.875, (171.6pt, -182.957pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: C{\char35}, Xamarin]" & "}") scaled 0.6563, (171.6pt, -187.825pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides a limited subset of the\\Internet banking functionality to\\customers via their mobile device" & "}") scaled 0.7175, (171.6pt, -196.065pt), 0, (1,1,1));
fill pmhbox(228.8pt, 175.147pt, 59.4pt, 28.312pt, 3.3pt) withcolor (0.2627,0.5529,0.8353);
draw pmhbox(228.8pt, 175.147pt, 59.4pt, 28.312pt, 3.3pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.55pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Web Application}" & "}") scaled 0.875, (258.5pt, -182.957pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Java, Spring MVC]" & "}") scaled 0.6563, (258.5pt, -187.825pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Delivers the static content and\\the Internet banking SPA" & "}") scaled 0.7175, (258.5pt, -194.17pt), 0, (1,1,1));
fill (315.7pt, -179.502pt) -- (315.764pt, -179.217pt) -- (315.954pt, -178.933pt) -- (316.271pt, -178.652pt) -- 
  (316.712pt, -178.375pt) -- (317.276pt, -178.102pt) -- (317.961pt, -177.835pt) -- (318.763pt, -177.576pt) -- 
  (319.679pt, -177.324pt) -- (320.705pt, -177.083pt) -- (321.837pt, -176.851pt) -- (323.07pt, -176.631pt) -- 
  (324.399pt, -176.423pt) -- (325.817pt, -176.228pt) -- (327.32pt, -176.047pt) -- (328.9pt, -175.881pt) -- 
  (330.55pt, -175.73pt) -- (332.264pt, -175.596pt) -- (334.034pt, -175.479pt) -- (335.853pt, -175.378pt) -- 
  (337.713pt, -175.295pt) -- (339.606pt, -175.231pt) -- (341.523pt, -175.184pt) -- (343.458pt, -175.156pt) -- 
  (345.4pt, -175.147pt) -- (347.343pt, -175.156pt) -- (349.277pt, -175.184pt) -- (351.194pt, -175.231pt) -- 
  (353.087pt, -175.295pt) -- (354.947pt, -175.378pt) -- (356.766pt, -175.479pt) -- (358.536pt, -175.596pt) -- 
  (360.25pt, -175.73pt) -- (361.9pt, -175.881pt) -- (363.48pt, -176.047pt) -- (364.983pt, -176.228pt) -- 
  (366.401pt, -176.423pt) -- (367.73pt, -176.631pt) -- (368.963pt, -176.851pt) -- (370.095pt, -177.083pt) -- 
  (371.121pt, -177.324pt) -- (372.037pt, -177.576pt) -- (372.839pt, -177.835pt) -- (373.524pt, -178.102pt) -- 
  (374.088pt, -178.375pt) -- (374.529pt, -178.652pt) -- (374.846pt, -178.933pt) -- (375.036pt, -179.217pt) -- 
  (375.1pt, -179.502pt) -- (375.1pt, -210.457pt) -- (375.036pt, -210.742pt) -- (374.846pt, -211.025pt) -- 
  (374.529pt, -211.307pt) -- (374.088pt, -211.584pt) -- (373.524pt, -211.857pt) -- (372.839pt, -212.123pt) -- 
  (372.037pt, -212.383pt) -- (371.121pt, -212.634pt) -- (370.095pt, -212.876pt) -- (368.963pt, -213.108pt) -- 
  (367.73pt, -213.328pt) -- (366.401pt, -213.536pt) -- (364.983pt, -213.731pt) -- (363.48pt, -213.912pt) -- 
  (361.9pt, -214.078pt) -- (360.25pt, -214.228pt) -- (358.536pt, -214.363pt) -- (356.766pt, -214.48pt) -- 
  (354.947pt, -214.581pt) -- (353.087pt, -214.663pt) -- (351.194pt, -214.728pt) -- (349.277pt, -214.775pt) -- 
  (347.343pt, -214.802pt) -- (345.4pt, -214.812pt) -- (343.458pt, -214.802pt) -- (341.523pt, -214.775pt) -- 
  (339.606pt, -214.728pt) -- (337.713pt, -214.663pt) -- (335.853pt, -214.581pt) -- (334.034pt, -214.48pt) -- 
  (332.264pt, -214.363pt) -- (330.55pt, -214.228pt) -- (328.9pt, -214.078pt) -- (327.32pt, -213.912pt) -- 
  (325.817pt, -213.731pt) -- (324.399pt, -213.536pt) -- (323.07pt, -213.328pt) -- (321.837pt, -213.108pt) -- 
  (320.705pt, -212.876pt) -- (319.679pt, -212.634pt) -- (318.763pt, -212.383pt) -- (317.961pt, -212.123pt) -- 
  (317.276pt, -211.857pt) -- (316.712pt, -211.584pt) -- (316.271pt, -211.307pt) -- (315.954pt, -211.025pt) -- 
  (315.764pt, -210.742pt) -- (315.7pt, -210.457pt) -- cycle withcolor (0.2627,0.5529,0.8353);
draw (315.7pt, -179.502pt) -- (315.764pt, -179.217pt) -- (315.954pt, -178.933pt) -- (316.271pt, -178.652pt) -- 
  (316.712pt, -178.375pt) -- (317.276pt, -178.102pt) -- (317.961pt, -177.835pt) -- (318.763pt, -177.576pt) -- 
  (319.679pt, -177.324pt) -- (320.705pt, -177.083pt) -- (321.837pt, -176.851pt) -- (323.07pt, -176.631pt) -- 
  (324.399pt, -176.423pt) -- (325.817pt, -176.228pt) -- (327.32pt, -176.047pt) -- (328.9pt, -175.881pt) -- 
  (330.55pt, -175.73pt) -- (332.264pt, -175.596pt) -- (334.034pt, -175.479pt) -- (335.853pt, -175.378pt) -- 
  (337.713pt, -175.295pt) -- (339.606pt, -175.231pt) -- (341.523pt, -175.184pt) -- (343.458pt, -175.156pt) -- 
  (345.4pt, -175.147pt) -- (347.343pt, -175.156pt) -- (349.277pt, -175.184pt) -- (351.194pt, -175.231pt) -- 
  (353.087pt, -175.295pt) -- (354.947pt, -175.378pt) -- (356.766pt, -175.479pt) -- (358.536pt, -175.596pt) -- 
  (360.25pt, -175.73pt) -- (361.9pt, -175.881pt) -- (363.48pt, -176.047pt) -- (364.983pt, -176.228pt) -- 
  (366.401pt, -176.423pt) -- (367.73pt, -176.631pt) -- (368.963pt, -176.851pt) -- (370.095pt, -177.083pt) -- 
  (371.121pt, -177.324pt) -- (372.037pt, -177.576pt) -- (372.839pt, -177.835pt) -- (373.524pt, -178.102pt) -- 
  (374.088pt, -178.375pt) -- (374.529pt, -178.652pt) -- (374.846pt, -178.933pt) -- (375.036pt, -179.217pt) -- 
  (375.1pt, -179.502pt) -- (375.1pt, -210.457pt) -- (375.036pt, -210.742pt) -- (374.846pt, -211.025pt) -- 
  (374.529pt, -211.307pt) -- (374.088pt, -211.584pt) -- (373.524pt, -211.857pt) -- (372.839pt, -212.123pt) -- 
  (372.037pt, -212.383pt) -- (371.121pt, -212.634pt) -- (370.095pt, -212.876pt) -- (368.963pt, -213.108pt) -- 
  (367.73pt, -213.328pt) -- (366.401pt, -213.536pt) -- (364.983pt, -213.731pt) -- (363.48pt, -213.912pt) -- 
  (361.9pt, -214.078pt) -- (360.25pt, -214.228pt) -- (358.536pt, -214.363pt) -- (356.766pt, -214.48pt) -- 
  (354.947pt, -214.581pt) -- (353.087pt, -214.663pt) -- (351.194pt, -214.728pt) -- (349.277pt, -214.775pt) -- 
  (347.343pt, -214.802pt) -- (345.4pt, -214.812pt) -- (343.458pt, -214.802pt) -- (341.523pt, -214.775pt) -- 
  (339.606pt, -214.728pt) -- (337.713pt, -214.663pt) -- (335.853pt, -214.581pt) -- (334.034pt, -214.48pt) -- 
  (332.264pt, -214.363pt) -- (330.55pt, -214.228pt) -- (328.9pt, -214.078pt) -- (327.32pt, -213.912pt) -- 
  (325.817pt, -213.731pt) -- (324.399pt, -213.536pt) -- (323.07pt, -213.328pt) -- (321.837pt, -213.108pt) -- 
  (320.705pt, -212.876pt) -- (319.679pt, -212.634pt) -- (318.763pt, -212.383pt) -- (317.961pt, -212.123pt) -- 
  (317.276pt, -211.857pt) -- (316.712pt, -211.584pt) -- (316.271pt, -211.307pt) -- (315.954pt, -211.025pt) -- 
  (315.764pt, -210.742pt) -- (315.7pt, -210.457pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.55pt;
begingroup interim linecap := rounded; draw (315.7pt, -179.502pt)
  .. controls (315.7pt, -181.907pt) and (328.997pt, -183.857pt) .. (345.4pt, -183.857pt)
  .. controls (361.803pt, -183.857pt) and (375.1pt, -181.907pt) .. (375.1pt, -179.502pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.55pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Database}" & "}") scaled 0.875, (345.4pt, -190.406pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: SQL Database]" & "}") scaled 0.6563, (345.4pt, -195.273pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores user registration\\information, hashed auth\\credentials, access logs, etc." & "}") scaled 0.7175, (345.4pt, -203.514pt), 0, (1,1,1));
fill (55pt, -246.667pt) -- (55.064pt, -246.382pt) -- (55.254pt, -246.098pt) -- (55.571pt, -245.817pt) -- 
  (56.012pt, -245.54pt) -- (56.576pt, -245.267pt) -- (57.261pt, -245pt) -- (58.063pt, -244.74pt) -- 
  (58.979pt, -244.489pt) -- (60.005pt, -244.247pt) -- (61.137pt, -244.016pt) -- (62.37pt, -243.795pt) -- 
  (63.699pt, -243.587pt) -- (65.117pt, -243.392pt) -- (66.62pt, -243.212pt) -- (68.2pt, -243.046pt) -- 
  (69.85pt, -242.895pt) -- (71.564pt, -242.761pt) -- (73.334pt, -242.643pt) -- (75.153pt, -242.543pt) -- 
  (77.013pt, -242.46pt) -- (78.906pt, -242.396pt) -- (80.823pt, -242.349pt) -- (82.758pt, -242.321pt) -- 
  (84.7pt, -242.312pt) -- (86.642pt, -242.321pt) -- (88.577pt, -242.349pt) -- (90.494pt, -242.396pt) -- 
  (92.387pt, -242.46pt) -- (94.247pt, -242.543pt) -- (96.066pt, -242.643pt) -- (97.836pt, -242.761pt) -- 
  (99.55pt, -242.895pt) -- (101.2pt, -243.046pt) -- (102.78pt, -243.212pt) -- (104.283pt, -243.392pt) -- 
  (105.701pt, -243.587pt) -- (107.03pt, -243.795pt) -- (108.263pt, -244.016pt) -- (109.395pt, -244.247pt) -- 
  (110.421pt, -244.489pt) -- (111.337pt, -244.74pt) -- (112.139pt, -245pt) -- (112.824pt, -245.267pt) -- 
  (113.388pt, -245.54pt) -- (113.829pt, -245.817pt) -- (114.146pt, -246.098pt) -- (114.336pt, -246.382pt) -- 
  (114.4pt, -246.667pt) -- (114.4pt, -277.298pt) -- (114.336pt, -277.583pt) -- (114.146pt, -277.867pt) -- 
  (113.829pt, -278.148pt) -- (113.388pt, -278.425pt) -- (112.824pt, -278.698pt) -- (112.139pt, -278.965pt) -- 
  (111.337pt, -279.224pt) -- (110.421pt, -279.476pt) -- (109.395pt, -279.718pt) -- (108.263pt, -279.949pt) -- 
  (107.03pt, -280.17pt) -- (105.701pt, -280.378pt) -- (104.283pt, -280.572pt) -- (102.78pt, -280.753pt) -- 
  (101.2pt, -280.919pt) -- (99.55pt, -281.07pt) -- (97.836pt, -281.204pt) -- (96.066pt, -281.322pt) -- 
  (94.247pt, -281.422pt) -- (92.387pt, -281.505pt) -- (90.494pt, -281.569pt) -- (88.577pt, -281.616pt) -- 
  (86.642pt, -281.644pt) -- (84.7pt, -281.653pt) -- (82.758pt, -281.644pt) -- (80.823pt, -281.616pt) -- 
  (78.906pt, -281.569pt) -- (77.013pt, -281.505pt) -- (75.153pt, -281.422pt) -- (73.334pt, -281.322pt) -- 
  (71.564pt, -281.204pt) -- (69.85pt, -281.07pt) -- (68.2pt, -280.919pt) -- (66.62pt, -280.753pt) -- 
  (65.117pt, -280.572pt) -- (63.699pt, -280.378pt) -- (62.37pt, -280.17pt) -- (61.137pt, -279.949pt) -- 
  (60.005pt, -279.718pt) -- (58.979pt, -279.476pt) -- (58.063pt, -279.224pt) -- (57.261pt, -278.965pt) -- 
  (56.576pt, -278.698pt) -- (56.012pt, -278.425pt) -- (55.571pt, -278.148pt) -- (55.254pt, -277.867pt) -- 
  (55.064pt, -277.583pt) -- (55pt, -277.298pt) -- cycle withcolor (0.702,0.702,0.702);
draw (55pt, -246.667pt) -- (55.064pt, -246.382pt) -- (55.254pt, -246.098pt) -- (55.571pt, -245.817pt) -- 
  (56.012pt, -245.54pt) -- (56.576pt, -245.267pt) -- (57.261pt, -245pt) -- (58.063pt, -244.74pt) -- 
  (58.979pt, -244.489pt) -- (60.005pt, -244.247pt) -- (61.137pt, -244.016pt) -- (62.37pt, -243.795pt) -- 
  (63.699pt, -243.587pt) -- (65.117pt, -243.392pt) -- (66.62pt, -243.212pt) -- (68.2pt, -243.046pt) -- 
  (69.85pt, -242.895pt) -- (71.564pt, -242.761pt) -- (73.334pt, -242.643pt) -- (75.153pt, -242.543pt) -- 
  (77.013pt, -242.46pt) -- (78.906pt, -242.396pt) -- (80.823pt, -242.349pt) -- (82.758pt, -242.321pt) -- 
  (84.7pt, -242.312pt) -- (86.642pt, -242.321pt) -- (88.577pt, -242.349pt) -- (90.494pt, -242.396pt) -- 
  (92.387pt, -242.46pt) -- (94.247pt, -242.543pt) -- (96.066pt, -242.643pt) -- (97.836pt, -242.761pt) -- 
  (99.55pt, -242.895pt) -- (101.2pt, -243.046pt) -- (102.78pt, -243.212pt) -- (104.283pt, -243.392pt) -- 
  (105.701pt, -243.587pt) -- (107.03pt, -243.795pt) -- (108.263pt, -244.016pt) -- (109.395pt, -244.247pt) -- 
  (110.421pt, -244.489pt) -- (111.337pt, -244.74pt) -- (112.139pt, -245pt) -- (112.824pt, -245.267pt) -- 
  (113.388pt, -245.54pt) -- (113.829pt, -245.817pt) -- (114.146pt, -246.098pt) -- (114.336pt, -246.382pt) -- 
  (114.4pt, -246.667pt) -- (114.4pt, -277.298pt) -- (114.336pt, -277.583pt) -- (114.146pt, -277.867pt) -- 
  (113.829pt, -278.148pt) -- (113.388pt, -278.425pt) -- (112.824pt, -278.698pt) -- (112.139pt, -278.965pt) -- 
  (111.337pt, -279.224pt) -- (110.421pt, -279.476pt) -- (109.395pt, -279.718pt) -- (108.263pt, -279.949pt) -- 
  (107.03pt, -280.17pt) -- (105.701pt, -280.378pt) -- (104.283pt, -280.572pt) -- (102.78pt, -280.753pt) -- 
  (101.2pt, -280.919pt) -- (99.55pt, -281.07pt) -- (97.836pt, -281.204pt) -- (96.066pt, -281.322pt) -- 
  (94.247pt, -281.422pt) -- (92.387pt, -281.505pt) -- (90.494pt, -281.569pt) -- (88.577pt, -281.616pt) -- 
  (86.642pt, -281.644pt) -- (84.7pt, -281.653pt) -- (82.758pt, -281.644pt) -- (80.823pt, -281.616pt) -- 
  (78.906pt, -281.569pt) -- (77.013pt, -281.505pt) -- (75.153pt, -281.422pt) -- (73.334pt, -281.322pt) -- 
  (71.564pt, -281.204pt) -- (69.85pt, -281.07pt) -- (68.2pt, -280.919pt) -- (66.62pt, -280.753pt) -- 
  (65.117pt, -280.572pt) -- (63.699pt, -280.378pt) -- (62.37pt, -280.17pt) -- (61.137pt, -279.949pt) -- 
  (60.005pt, -279.718pt) -- (58.979pt, -279.476pt) -- (58.063pt, -279.224pt) -- (57.261pt, -278.965pt) -- 
  (56.576pt, -278.698pt) -- (56.012pt, -278.425pt) -- (55.571pt, -278.148pt) -- (55.254pt, -277.867pt) -- 
  (55.064pt, -277.583pt) -- (55pt, -277.298pt) -- cycle withcolor (0.651,0.651,0.651) withpen pencircle scaled 0.55pt;
begingroup interim linecap := rounded; draw (55pt, -246.667pt)
  .. controls (55pt, -249.072pt) and (68.297pt, -251.021pt) .. (84.7pt, -251.021pt)
  .. controls (101.103pt, -251.021pt) and (114.4pt, -249.072pt) .. (114.4pt, -246.667pt) withcolor (0.651,0.651,0.651) withpen pencircle scaled 0.55pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf API Application}" & "}") scaled 0.875, (84.7pt, -257.571pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Java, Docker\\Container]" & "}") scaled 0.6563, (84.7pt, -264.171pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides Internet banking\\functionality via API" & "}") scaled 0.7175, (84.7pt, -272.249pt), 0, (1,1,1));
fill (144.109pt, -258.585pt) -- (143.964pt, -258.568pt) -- (143.821pt, -258.516pt) -- (143.678pt, -258.429pt) -- 
  (143.537pt, -258.308pt) -- (143.399pt, -258.153pt) -- (143.264pt, -257.966pt) -- (143.132pt, -257.746pt) -- 
  (143.005pt, -257.495pt) -- (142.882pt, -257.214pt) -- (142.764pt, -256.904pt) -- (142.652pt, -256.566pt) -- 
  (142.547pt, -256.202pt) -- (142.448pt, -255.813pt) -- (142.356pt, -255.402pt) -- (142.272pt, -254.969pt) -- 
  (142.196pt, -254.517pt) -- (142.128pt, -254.047pt) -- (142.068pt, -253.562pt) -- (142.017pt, -253.064pt) -- 
  (141.975pt, -252.554pt) -- (141.943pt, -252.036pt) -- (141.919pt, -251.51pt) -- (141.905pt, -250.981pt) -- 
  (141.9pt, -250.448pt) -- (141.905pt, -249.916pt) -- (141.919pt, -249.386pt) -- (141.943pt, -248.861pt) -- 
  (141.975pt, -248.343pt) -- (142.017pt, -247.833pt) -- (142.068pt, -247.335pt) -- (142.128pt, -246.85pt) -- 
  (142.196pt, -246.38pt) -- (142.272pt, -245.928pt) -- (142.356pt, -245.495pt) -- (142.448pt, -245.084pt) -- 
  (142.547pt, -244.695pt) -- (142.652pt, -244.331pt) -- (142.764pt, -243.993pt) -- (142.882pt, -243.683pt) -- 
  (143.005pt, -243.402pt) -- (143.132pt, -243.151pt) -- (143.264pt, -242.931pt) -- (143.399pt, -242.744pt) -- 
  (143.537pt, -242.589pt) -- (143.678pt, -242.468pt) -- (143.821pt, -242.381pt) -- (143.964pt, -242.329pt) -- 
  (144.109pt, -242.312pt) -- (205.718pt, -242.312pt) -- (205.862pt, -242.329pt) -- (206.006pt, -242.381pt) -- 
  (206.149pt, -242.468pt) -- (206.29pt, -242.589pt) -- (206.428pt, -242.744pt) -- (206.563pt, -242.931pt) -- 
  (206.695pt, -243.151pt) -- (206.822pt, -243.402pt) -- (206.945pt, -243.683pt) -- (207.063pt, -243.993pt) -- 
  (207.174pt, -244.331pt) -- (207.28pt, -244.695pt) -- (207.379pt, -245.084pt) -- (207.47pt, -245.495pt) -- 
  (207.555pt, -245.928pt) -- (207.631pt, -246.38pt) -- (207.699pt, -246.85pt) -- (207.759pt, -247.335pt) -- 
  (207.81pt, -247.833pt) -- (207.852pt, -248.343pt) -- (207.884pt, -248.861pt) -- (207.908pt, -249.386pt) -- 
  (207.922pt, -249.916pt) -- (207.927pt, -250.448pt) -- (207.922pt, -250.981pt) -- (207.908pt, -251.51pt) -- 
  (207.884pt, -252.036pt) -- (207.852pt, -252.554pt) -- (207.81pt, -253.064pt) -- (207.759pt, -253.562pt) -- 
  (207.699pt, -254.047pt) -- (207.631pt, -254.517pt) -- (207.555pt, -254.969pt) -- (207.47pt, -255.402pt) -- 
  (207.379pt, -255.813pt) -- (207.28pt, -256.202pt) -- (207.174pt, -256.566pt) -- (207.063pt, -256.904pt) -- 
  (206.945pt, -257.214pt) -- (206.822pt, -257.495pt) -- (206.695pt, -257.746pt) -- (206.563pt, -257.966pt) -- 
  (206.428pt, -258.153pt) -- (206.29pt, -258.308pt) -- (206.149pt, -258.429pt) -- (206.006pt, -258.516pt) -- 
  (205.862pt, -258.568pt) -- (205.718pt, -258.585pt) -- cycle withcolor (0.2627,0.5529,0.8353);
draw (144.109pt, -258.585pt) -- (143.964pt, -258.568pt) -- (143.821pt, -258.516pt) -- (143.678pt, -258.429pt) -- 
  (143.537pt, -258.308pt) -- (143.399pt, -258.153pt) -- (143.264pt, -257.966pt) -- (143.132pt, -257.746pt) -- 
  (143.005pt, -257.495pt) -- (142.882pt, -257.214pt) -- (142.764pt, -256.904pt) -- (142.652pt, -256.566pt) -- 
  (142.547pt, -256.202pt) -- (142.448pt, -255.813pt) -- (142.356pt, -255.402pt) -- (142.272pt, -254.969pt) -- 
  (142.196pt, -254.517pt) -- (142.128pt, -254.047pt) -- (142.068pt, -253.562pt) -- (142.017pt, -253.064pt) -- 
  (141.975pt, -252.554pt) -- (141.943pt, -252.036pt) -- (141.919pt, -251.51pt) -- (141.905pt, -250.981pt) -- 
  (141.9pt, -250.448pt) -- (141.905pt, -249.916pt) -- (141.919pt, -249.386pt) -- (141.943pt, -248.861pt) -- 
  (141.975pt, -248.343pt) -- (142.017pt, -247.833pt) -- (142.068pt, -247.335pt) -- (142.128pt, -246.85pt) -- 
  (142.196pt, -246.38pt) -- (142.272pt, -245.928pt) -- (142.356pt, -245.495pt) -- (142.448pt, -245.084pt) -- 
  (142.547pt, -244.695pt) -- (142.652pt, -244.331pt) -- (142.764pt, -243.993pt) -- (142.882pt, -243.683pt) -- 
  (143.005pt, -243.402pt) -- (143.132pt, -243.151pt) -- (143.264pt, -242.931pt) -- (143.399pt, -242.744pt) -- 
  (143.537pt, -242.589pt) -- (143.678pt, -242.468pt) -- (143.821pt, -242.381pt) -- (143.964pt, -242.329pt) -- 
  (144.109pt, -242.312pt) -- (205.718pt, -242.312pt) -- (205.862pt, -242.329pt) -- (206.006pt, -242.381pt) -- 
  (206.149pt, -242.468pt) -- (206.29pt, -242.589pt) -- (206.428pt, -242.744pt) -- (206.563pt, -242.931pt) -- 
  (206.695pt, -243.151pt) -- (206.822pt, -243.402pt) -- (206.945pt, -243.683pt) -- (207.063pt, -243.993pt) -- 
  (207.174pt, -244.331pt) -- (207.28pt, -244.695pt) -- (207.379pt, -245.084pt) -- (207.47pt, -245.495pt) -- 
  (207.555pt, -245.928pt) -- (207.631pt, -246.38pt) -- (207.699pt, -246.85pt) -- (207.759pt, -247.335pt) -- 
  (207.81pt, -247.833pt) -- (207.852pt, -248.343pt) -- (207.884pt, -248.861pt) -- (207.908pt, -249.386pt) -- 
  (207.922pt, -249.916pt) -- (207.927pt, -250.448pt) -- (207.922pt, -250.981pt) -- (207.908pt, -251.51pt) -- 
  (207.884pt, -252.036pt) -- (207.852pt, -252.554pt) -- (207.81pt, -253.064pt) -- (207.759pt, -253.562pt) -- 
  (207.699pt, -254.047pt) -- (207.631pt, -254.517pt) -- (207.555pt, -254.969pt) -- (207.47pt, -255.402pt) -- 
  (207.379pt, -255.813pt) -- (207.28pt, -256.202pt) -- (207.174pt, -256.566pt) -- (207.063pt, -256.904pt) -- 
  (206.945pt, -257.214pt) -- (206.822pt, -257.495pt) -- (206.695pt, -257.746pt) -- (206.563pt, -257.966pt) -- 
  (206.428pt, -258.153pt) -- (206.29pt, -258.308pt) -- (206.149pt, -258.429pt) -- (206.006pt, -258.516pt) -- 
  (205.862pt, -258.568pt) -- (205.718pt, -258.585pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.55pt;
begingroup interim linecap := rounded; draw (205.718pt, -242.312pt)
  .. controls (204.498pt, -242.312pt) and (203.509pt, -245.955pt) .. (203.509pt, -250.448pt)
  .. controls (203.509pt, -254.942pt) and (204.498pt, -258.585pt) .. (205.718pt, -258.585pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.55pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Queue}" & "}") scaled 0.875, (172.704pt, -245.997pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: RabbitMQ]" & "}") scaled 0.6563, (172.704pt, -250.864pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Hands work on" & "}") scaled 0.7175, (172.704pt, -255.316pt), 0, (1,1,1));
fill pmhbox(215.05pt, 65.725pt, 59.4pt, 32.1pt, 3.3pt) withcolor (0.6,0.6,0.6);
draw pmhbox(215.05pt, 65.725pt, 59.4pt, 32.1pt, 3.3pt) withcolor (0.5412,0.5412,0.5412) withpen pencircle scaled 0.55pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Mainframe Banking System}" & "}") scaled 0.875, (244.75pt, -73.535pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Software System]" & "}") scaled 0.6563, (244.75pt, -78.402pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores all of the core banking\\information about customers,\\accounts, transactions, etc." & "}") scaled 0.7175, (244.75pt, -86.643pt), 0, (1,1,1));
draw (182.789pt, -115.883pt) -- (243.902pt, -175.147pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt;
fill (244.1pt, -175.339pt) -- (241.168pt, -174.411pt) -- (243.083pt, -172.437pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (241.544pt, -162.015pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [HTTPS]}" & "}") scaled 0.75, (244.448pt, -166.69pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (138.755pt, -117.672pt)
  .. controls (131.712pt, -136.83pt) and (117.627pt, -155.989pt) .. (96.5pt, -175.147pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (96.296pt, -175.332pt) -- (97.41pt, -172.466pt) -- (99.257pt, -174.503pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (121.076pt, -146.41pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [HTTPS]}" & "}") scaled 0.75, (123.98pt, -151.085pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (161.439pt, -117.672pt)
  .. controls (162.763pt, -136.83pt) and (165.411pt, -155.989pt) .. (169.382pt, -175.147pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (169.438pt, -175.416pt) -- (167.533pt, -173.003pt) -- (170.226pt, -172.444pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (168.859pt, -146.41pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (228.8pt, -189.627pt)
  .. controls (209.733pt, -190.042pt) and (171.6pt, -190.458pt) .. (114.4pt, -190.873pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (114.125pt, -190.875pt) -- (116.865pt, -189.48pt) -- (116.885pt, -192.23pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Delivers" & "}") scaled 0.75, (178.217pt, -190.25pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (84.7pt, -207.247pt)
  .. controls (84.7pt, -218.935pt) and (84.7pt, -230.624pt) .. (84.7pt, -242.312pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (84.7pt, -242.587pt) -- (83.325pt, -239.837pt) -- (86.075pt, -239.837pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (88.149pt, -224.78pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [async, JSON/HTTPS]}" & "}") scaled 0.75, (100.705pt, -229.454pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (315.7pt, -202.613pt)
  .. controls (282.15pt, -219.858pt) and (215.05pt, -237.104pt) .. (114.4pt, -254.349pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (315.945pt, -202.487pt) -- (314.127pt, -204.967pt) -- (312.87pt, -202.521pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Reads from and writes to" & "}") scaled 0.75, (232.821pt, -228.481pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [sync, JDBC]}" & "}") scaled 0.75, (232.821pt, -233.156pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (100.65pt, -83.92pt)
  .. controls (107.318pt, -85.733pt) and (120.653pt, -87.547pt) .. (140.656pt, -89.36pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (140.93pt, -89.385pt) -- (138.067pt, -90.506pt) -- (138.315pt, -87.767pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Sends e-mails to" & "}") scaled 0.75, (132.549pt, -86.64pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (83.215pt, -242.317pt)
  .. controls (81.349pt, -192.89pt) and (77.617pt, -143.464pt) .. (72.019pt, -94.037pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (71.988pt, -93.764pt) -- (73.664pt, -96.341pt) -- (70.931pt, -96.651pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Sends e-mails using" & "}") scaled 0.75, (91.889pt, -168.177pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [sync, SMTP]}" & "}") scaled 0.75, (91.889pt, -172.852pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (102.17pt, -243.145pt)
  .. controls (123.558pt, -194.705pt) and (166.333pt, -146.265pt) .. (230.495pt, -97.825pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (230.715pt, -97.66pt) -- (229.348pt, -100.414pt) -- (227.691pt, -98.219pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Uses" & "}") scaled 0.75, (169.781pt, -170.485pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [sync/async, XML/HTTPS]}" & "}") scaled 0.75, (184.928pt, -175.16pt), 0, (0.2667,0.2667,0.2667));
begingroup interim linecap := rounded; draw (114.4pt, -258.185pt)
  .. controls (119.037pt, -257.013pt) and (128.31pt, -255.841pt) .. (142.22pt, -254.669pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.275pt; endgroup;
fill (142.495pt, -254.646pt) -- (139.87pt, -256.247pt) -- (139.639pt, -253.507pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Puts" & "}") scaled 0.75, (131.759pt, -256.427pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Container diagram for Internet Banking System" & "}") scaled 1, (192.786pt, -23.21pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
