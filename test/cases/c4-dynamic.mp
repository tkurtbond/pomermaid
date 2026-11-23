\startMPcode
numeric pmxx[]; picture pmxp;
pmxx0 := 0; pmxx1 := -409.469pt; pmxx2 := 431.05pt; pmxx3 := 0;
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
begingroup interim linecap := rounded; draw (69.375pt, -239.858pt)
  .. controls (69.375pt, -239.858pt) and (361.675pt, -239.858pt) .. (361.675pt, -239.858pt)
  .. controls (361.675pt, -239.858pt) and (361.675pt, -363.219pt) .. (361.675pt, -363.219pt)
  .. controls (361.675pt, -363.219pt) and (69.375pt, -363.219pt) .. (69.375pt, -363.219pt)
  .. controls (69.375pt, -363.219pt) and (69.375pt, -239.858pt) .. (69.375pt, -239.858pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.463pt dashed dashpattern(on 3.238pt off 3.238pt); endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf API Application}" & "}") scaled 1, (215.525pt, -243.558pt), 0, (0.2667,0.2667,0.2667));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[CONTAINER]" & "}") scaled 0.875, (215.525pt, -254.75pt), 0, (0.2667,0.2667,0.2667));
fill (69.375pt, -117.862pt) -- (69.482pt, -117.383pt) -- (69.802pt, -116.906pt) -- (70.335pt, -116.433pt) -- 
  (71.077pt, -115.966pt) -- (72.026pt, -115.507pt) -- (73.177pt, -115.059pt) -- (74.526pt, -114.622pt) -- 
  (76.067pt, -114.2pt) -- (77.793pt, -113.792pt) -- (79.697pt, -113.403pt) -- (81.771pt, -113.032pt) -- 
  (84.005pt, -112.683pt) -- (86.391pt, -112.355pt) -- (88.917pt, -112.051pt) -- (91.574pt, -111.772pt) -- 
  (94.35pt, -111.519pt) -- (97.233pt, -111.293pt) -- (100.21pt, -111.095pt) -- (103.269pt, -110.926pt) -- 
  (106.397pt, -110.787pt) -- (109.58pt, -110.678pt) -- (112.805pt, -110.6pt) -- (116.058pt, -110.553pt) -- 
  (119.325pt, -110.537pt) -- (122.592pt, -110.553pt) -- (125.845pt, -110.6pt) -- (129.07pt, -110.678pt) -- 
  (132.253pt, -110.787pt) -- (135.381pt, -110.926pt) -- (138.44pt, -111.095pt) -- (141.417pt, -111.293pt) -- 
  (144.3pt, -111.519pt) -- (147.076pt, -111.772pt) -- (149.733pt, -112.051pt) -- (152.259pt, -112.355pt) -- 
  (154.645pt, -112.683pt) -- (156.879pt, -113.032pt) -- (158.953pt, -113.403pt) -- (160.857pt, -113.792pt) -- 
  (162.583pt, -114.2pt) -- (164.124pt, -114.622pt) -- (165.473pt, -115.059pt) -- (166.624pt, -115.507pt) -- 
  (167.573pt, -115.966pt) -- (168.315pt, -116.433pt) -- (168.848pt, -116.906pt) -- (169.168pt, -117.383pt) -- 
  (169.275pt, -117.862pt) -- (169.275pt, -182.121pt) -- (169.168pt, -182.6pt) -- (168.848pt, -183.077pt) -- 
  (168.315pt, -183.55pt) -- (167.573pt, -184.017pt) -- (166.624pt, -184.475pt) -- (165.473pt, -184.924pt) -- 
  (164.124pt, -185.361pt) -- (162.583pt, -185.783pt) -- (160.857pt, -186.19pt) -- (158.953pt, -186.58pt) -- 
  (156.879pt, -186.95pt) -- (154.645pt, -187.3pt) -- (152.259pt, -187.628pt) -- (149.733pt, -187.932pt) -- 
  (147.076pt, -188.211pt) -- (144.3pt, -188.464pt) -- (141.417pt, -188.69pt) -- (138.44pt, -188.888pt) -- 
  (135.381pt, -189.057pt) -- (132.253pt, -189.196pt) -- (129.07pt, -189.305pt) -- (125.845pt, -189.383pt) -- 
  (122.592pt, -189.43pt) -- (119.325pt, -189.445pt) -- (116.058pt, -189.43pt) -- (112.805pt, -189.383pt) -- 
  (109.58pt, -189.305pt) -- (106.397pt, -189.196pt) -- (103.269pt, -189.057pt) -- (100.21pt, -188.888pt) -- 
  (97.233pt, -188.69pt) -- (94.35pt, -188.464pt) -- (91.574pt, -188.211pt) -- (88.917pt, -187.932pt) -- 
  (86.391pt, -187.628pt) -- (84.005pt, -187.3pt) -- (81.771pt, -186.95pt) -- (79.697pt, -186.58pt) -- 
  (77.793pt, -186.19pt) -- (76.067pt, -185.783pt) -- (74.526pt, -185.361pt) -- (73.177pt, -184.924pt) -- 
  (72.026pt, -184.475pt) -- (71.077pt, -184.017pt) -- (70.335pt, -183.55pt) -- (69.802pt, -183.077pt) -- 
  (69.482pt, -182.6pt) -- (69.375pt, -182.121pt) -- cycle withcolor (0.2627,0.5529,0.8353);
draw (69.375pt, -117.862pt) -- (69.482pt, -117.383pt) -- (69.802pt, -116.906pt) -- (70.335pt, -116.433pt) -- 
  (71.077pt, -115.966pt) -- (72.026pt, -115.507pt) -- (73.177pt, -115.059pt) -- (74.526pt, -114.622pt) -- 
  (76.067pt, -114.2pt) -- (77.793pt, -113.792pt) -- (79.697pt, -113.403pt) -- (81.771pt, -113.032pt) -- 
  (84.005pt, -112.683pt) -- (86.391pt, -112.355pt) -- (88.917pt, -112.051pt) -- (91.574pt, -111.772pt) -- 
  (94.35pt, -111.519pt) -- (97.233pt, -111.293pt) -- (100.21pt, -111.095pt) -- (103.269pt, -110.926pt) -- 
  (106.397pt, -110.787pt) -- (109.58pt, -110.678pt) -- (112.805pt, -110.6pt) -- (116.058pt, -110.553pt) -- 
  (119.325pt, -110.537pt) -- (122.592pt, -110.553pt) -- (125.845pt, -110.6pt) -- (129.07pt, -110.678pt) -- 
  (132.253pt, -110.787pt) -- (135.381pt, -110.926pt) -- (138.44pt, -111.095pt) -- (141.417pt, -111.293pt) -- 
  (144.3pt, -111.519pt) -- (147.076pt, -111.772pt) -- (149.733pt, -112.051pt) -- (152.259pt, -112.355pt) -- 
  (154.645pt, -112.683pt) -- (156.879pt, -113.032pt) -- (158.953pt, -113.403pt) -- (160.857pt, -113.792pt) -- 
  (162.583pt, -114.2pt) -- (164.124pt, -114.622pt) -- (165.473pt, -115.059pt) -- (166.624pt, -115.507pt) -- 
  (167.573pt, -115.966pt) -- (168.315pt, -116.433pt) -- (168.848pt, -116.906pt) -- (169.168pt, -117.383pt) -- 
  (169.275pt, -117.862pt) -- (169.275pt, -182.121pt) -- (169.168pt, -182.6pt) -- (168.848pt, -183.077pt) -- 
  (168.315pt, -183.55pt) -- (167.573pt, -184.017pt) -- (166.624pt, -184.475pt) -- (165.473pt, -184.924pt) -- 
  (164.124pt, -185.361pt) -- (162.583pt, -185.783pt) -- (160.857pt, -186.19pt) -- (158.953pt, -186.58pt) -- 
  (156.879pt, -186.95pt) -- (154.645pt, -187.3pt) -- (152.259pt, -187.628pt) -- (149.733pt, -187.932pt) -- 
  (147.076pt, -188.211pt) -- (144.3pt, -188.464pt) -- (141.417pt, -188.69pt) -- (138.44pt, -188.888pt) -- 
  (135.381pt, -189.057pt) -- (132.253pt, -189.196pt) -- (129.07pt, -189.305pt) -- (125.845pt, -189.383pt) -- 
  (122.592pt, -189.43pt) -- (119.325pt, -189.445pt) -- (116.058pt, -189.43pt) -- (112.805pt, -189.383pt) -- 
  (109.58pt, -189.305pt) -- (106.397pt, -189.196pt) -- (103.269pt, -189.057pt) -- (100.21pt, -188.888pt) -- 
  (97.233pt, -188.69pt) -- (94.35pt, -188.464pt) -- (91.574pt, -188.211pt) -- (88.917pt, -187.932pt) -- 
  (86.391pt, -187.628pt) -- (84.005pt, -187.3pt) -- (81.771pt, -186.95pt) -- (79.697pt, -186.58pt) -- 
  (77.793pt, -186.19pt) -- (76.067pt, -185.783pt) -- (74.526pt, -185.361pt) -- (73.177pt, -184.924pt) -- 
  (72.026pt, -184.475pt) -- (71.077pt, -184.017pt) -- (70.335pt, -183.55pt) -- (69.802pt, -183.077pt) -- 
  (69.482pt, -182.6pt) -- (69.375pt, -182.121pt) -- cycle withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.925pt;
begingroup interim linecap := rounded; draw (69.375pt, -117.862pt)
  .. controls (69.375pt, -121.906pt) and (91.738pt, -125.186pt) .. (119.325pt, -125.186pt)
  .. controls (146.912pt, -125.186pt) and (169.275pt, -121.906pt) .. (169.275pt, -117.862pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.925pt; endgroup;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Database}" & "}") scaled 0.875, (119.325pt, -136.2pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: Relational Database\\Schema]" & "}") scaled 0.6563, (119.325pt, -147.3pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Stores user registration\\information, hashed\\authentication credentials,\\access logs, etc." & "}") scaled 0.7175, (119.325pt, -167.258pt), 0, (1,1,1));
fill pmhbox(215.525pt, 110.537pt, 99.9pt, 53.987pt, 5.55pt) withcolor (0.2627,0.5529,0.8353);
draw pmhbox(215.525pt, 110.537pt, 99.9pt, 53.987pt, 5.55pt) withcolor (0.2353,0.498,0.7529) withpen pencircle scaled 0.925pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Single-Page Application}" & "}") scaled 0.875, (265.475pt, -123.672pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Container: JavaScript and Angular]" & "}") scaled 0.6563, (265.475pt, -131.859pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides all of the Internet\\banking functionality to\\customers via their web browser." & "}") scaled 0.7175, (265.475pt, -145.717pt), 0, (1,1,1));
fill pmhbox(92.5pt, 286.108pt, 99.9pt, 53.987pt, 5.55pt) withcolor (0.5216,0.7333,0.9412);
draw pmhbox(92.5pt, 286.108pt, 99.9pt, 53.987pt, 5.55pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.925pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Security Component}" & "}") scaled 0.875, (142.45pt, -299.243pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: Spring Bean]" & "}") scaled 0.6563, (142.45pt, -307.429pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Provides functionality Related\\to signing in, changing passwords,\\etc." & "}") scaled 0.7175, (142.45pt, -321.287pt), 0, (1,1,1));
fill pmhbox(238.65pt, 286.108pt, 99.9pt, 53.443pt, 5.55pt) withcolor (0.5216,0.7333,0.9412);
draw pmhbox(238.65pt, 286.108pt, 99.9pt, 53.443pt, 5.55pt) withcolor (0.4706,0.6588,0.8471) withpen pencircle scaled 0.925pt;
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\bf Sign In Controller}" & "}") scaled 0.875, (288.6pt, -299.243pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "[Component: Spring MVC Rest\\Controller]" & "}") scaled 0.6563, (288.6pt, -310.343pt), 0, (1,1,1));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Allows users to sign in to the\\Internet Banking System." & "}") scaled 0.7175, (288.6pt, -323.929pt), 0, (1,1,1));
draw (269.036pt, -164.524pt) -- (285.075pt, -286.108pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.463pt;
fill (285.135pt, -286.566pt) -- (282.238pt, -282.283pt) -- (286.823pt, -281.679pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "1: Submits credentials to" & "}") scaled 0.75, (308.469pt, -206.816pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [JSON/HTTPS]}" & "}") scaled 0.75, (308.469pt, -214.678pt), 0, (1,0,0));
begingroup interim linecap := rounded; draw (238.65pt, -312.922pt)
  .. controls (230.942pt, -312.951pt) and (215.525pt, -312.979pt) .. (192.4pt, -313.008pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.463pt; endgroup;
fill (191.938pt, -313.009pt) -- (196.56pt, -310.69pt) -- (196.565pt, -315.315pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "2: Calls isAuthenticated() on" & "}") scaled 0.75, (233.24pt, -340.715pt), 0, (1,0,0));
begingroup interim linecap := rounded; draw (138.623pt, -286.108pt)
  .. controls (136.339pt, -253.872pt) and (131.771pt, -221.635pt) .. (124.919pt, -189.399pt) withcolor (0.2667,0.2667,0.2667) withpen pencircle scaled 0.463pt; endgroup;
fill (124.822pt, -188.947pt) -- (128.046pt, -192.99pt) -- (123.522pt, -193.952pt) -- cycle withcolor (0.2,0.2,0.2);
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "3: select * from users where username = ?" & "}") scaled 0.75, (183.961pt, -219.253pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "{\it [JDBC]}" & "}") scaled 0.75, (183.961pt, -227.116pt), 0, (1,0,0));
pmxtext(textext("\framed[frame=off,offset=0pt,align=middle]{" & "Dynamic diagram for Internet Banking System - API Application" & "}") scaled 1, (205.794pt, -39.035pt), 0, (0.2,0.2,0.2));
endgroup;
setbounds currentpicture to (pmxx0, pmxx1) -- (pmxx2, pmxx1) -- (pmxx2, pmxx3) -- (pmxx0, pmxx3) -- cycle;
\stopMPcode
