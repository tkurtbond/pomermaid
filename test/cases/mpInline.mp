\startMPcode
numeric pm_dir, pm_size, pm_maxw, pm_nn, pm_ne, pm_nr, pm_em, pm_px;
numeric pm_kind[], pm_rank[], pm_order[], pm_tx[], pm_shape[], pm_ofedge[];
numeric pm_w[], pm_h[], pm_fw[], pm_fh[], pm_x[], pm_y[], pm_tw[], pm_th[];
numeric pm_fill[], pm_line[], pm_text[], pm_lw[], pm_dash[];
numeric pm_layer[][], pm_len[], pm_rankh[];
numeric pm_ef[], pm_et[], pm_erev[], pm_elab[], pm_ehead[], pm_etail[], pm_evis[];
numeric pm_eline[], pm_etext[], pm_ewd[], pm_edash[], pm_echain[][], pm_enc[];
numeric pm_elw[], pm_elh[], pm_elx[], pm_ely[];
pair pm_p[][]; numeric pm_np[];
color pm_c[];
string pm_lab[], pm_elabel[];
picture pm_pic[];
pm_rect := 0; pm_round := 1; pm_stadium := 2; pm_subroutine := 3;
pm_cylinder := 4; pm_circle := 5; pm_asymmetric := 6; pm_diamond := 7;
pm_hexagon := 8; pm_leanright := 9; pm_leanleft := 10; pm_trapezoid := 11;
pm_invtrapezoid := 12; pm_doublecircle := 13;
pm_endnone := 0; pm_endarrow := 1; pm_endcircle := 2; pm_endcross := 3;
def pm_begin(expr d, s, mw, nn, ne, nr) =
  pm_dir := d; pm_size := s; pm_maxw := mw; pm_nn := nn; pm_ne := ne; pm_nr := nr;
  for r = 0 upto nr - 1: pm_len[r] := 0; endfor
enddef;
def pm_colour(expr c, r, g, b) =
  pm_c[c] := (r, g, b);
enddef;
def pm_node(expr v, k, r, o, x, sh, e, lab) =
  pm_kind[v] := k; pm_rank[v] := r; pm_order[v] := o; pm_tx[v] := x;
  pm_shape[v] := sh; pm_ofedge[v] := e; pm_lab[v] := lab;
  pm_layer[r][o] := v;
  if o + 1 > pm_len[r]: pm_len[r] := o + 1; fi
enddef;
def pm_style(expr v, f, l, t, w, d) =
  pm_fill[v] := f; pm_line[v] := l; pm_text[v] := t; pm_lw[v] := w; pm_dash[v] := d;
enddef;
def pm_edge(expr j, f, t, rv, ln, hd, tl, vis, l, tc, w, d, lab)(text chain) =
  pm_ef[j] := f; pm_et[j] := t; pm_erev[j] := rv; pm_elab[j] := ln;
  pm_ehead[j] := hd; pm_etail[j] := tl; pm_evis[j] := vis;
  pm_eline[j] := l; pm_etext[j] := tc; pm_ewd[j] := w; pm_edash[j] := d;
  pm_elabel[j] := lab; pm_enc[j] := 0;
  for c = chain: pm_echain[j][pm_enc[j]] := c; pm_enc[j] := pm_enc[j] + 1; endfor
enddef;
vardef pm_textext(expr s) =
  textext("\framed[frame=off,offset=0pt,align=middle]{" & s & "}")
enddef;
def pm_shapesize(expr v) =
  begingroup save p, r, ry, tw, th, sh, w, h;
  tw := pm_tw[v]; th := pm_th[v]; sh := pm_shape[v];
  p := pm_em * 15 / 16;
  w := tw + 2p; h := th + 2p;
  if sh = pm_stadium: w := tw + h / 2 + 2p;
  elseif sh = pm_subroutine: w := w + pm_em;
  elseif sh = pm_cylinder: ry := w / 2 / (2.5 + w / 50); h := h + 2ry;
  elseif (sh = pm_circle) or (sh = pm_doublecircle):
    r := max(tw, th) / 2 + p;
    if sh = pm_doublecircle: r := r + pm_em * 5 / 16; fi
    w := 2r; h := w;
  elseif (sh = pm_asymmetric) or (sh = pm_hexagon): w := w + h / 2;
  elseif sh = pm_diamond: w := w + h; h := w;
  elseif (sh >= pm_leanright) and (sh <= pm_invtrapezoid): w := w + 2h / 3;
  fi
  pm_w[v] := w; pm_h[v] := h;
  endgroup
enddef;
def pm_sizes =
  for v = 0 upto pm_nn - 1:
    pm_tw[v] := 0; pm_th[v] := 0;
    if pm_kind[v] = 0:
      pm_pic[v] := pm_textext(pm_lab[v]);
      pm_tw[v] := xpart urcorner pm_pic[v] - xpart llcorner pm_pic[v];
      pm_th[v] := ypart urcorner pm_pic[v] - ypart llcorner pm_pic[v];
      pm_shapesize(v);
    elseif (pm_kind[v] > 1) and (pm_elabel[pm_ofedge[v]] <> ""):
      pm_pic[v] := pm_textext(pm_elabel[pm_ofedge[v]]);
      pm_tw[v] := xpart urcorner pm_pic[v] - xpart llcorner pm_pic[v];
      pm_th[v] := ypart urcorner pm_pic[v] - ypart llcorner pm_pic[v];
      pm_w[v] := pm_tw[v] + pm_em / 2; pm_h[v] := pm_th[v];
    else:
      pm_w[v] := 0; pm_h[v] := 0;
    fi
    if pm_dir >= 2: pm_fw[v] := pm_h[v]; pm_fh[v] := pm_w[v];
    else: pm_fw[v] := pm_w[v]; pm_fh[v] := pm_h[v]; fi
  endfor
enddef;
def pm_positiony =
  begingroup save y, m;
  y := 0;
  for r = 0 upto pm_nr - 1:
    m := 0;
    for i = 0 upto pm_len[r] - 1: m := max(m, pm_fh[pm_layer[r][i]]); endfor
    pm_rankh[r] := m;
    for i = 0 upto pm_len[r] - 1: pm_y[pm_layer[r][i]] := y + m / 2; endfor
    y := y + m + 25pm_px;
  endfor
  endgroup
enddef;
vardef pm_sep(expr v, u) =
  pm_fw[v] / 2 + pm_fw[u] / 2
    + (if pm_kind[v] = 0: 25 else: 10 fi) * pm_px
    + (if pm_kind[u] = 0: 25 else: 10 fi) * pm_px
enddef;
def pm_positionx =
  begingroup save c, t, bs, bsum, bn, nb, k, n, v;
  numeric c[], t[], bs[], bsum[], bn[];
  k := pm_em / pm_size;
  for r = 0 upto pm_nr - 1:
    n := pm_len[r];
    if n > 0:
      c[0] := 0;
      for i = 1 upto n - 1:
        c[i] := c[i - 1] + pm_sep(pm_layer[r][i - 1], pm_layer[r][i]);
      endfor
      nb := 0;
      for i = 0 upto n - 1:
        bs[nb] := i; bsum[nb] := pm_tx[pm_layer[r][i]] * k - c[i]; bn[nb] := 1;
        nb := nb + 1;
        forever:
          exitif nb < 2;
          exitunless bsum[nb - 2] / bn[nb - 2] > bsum[nb - 1] / bn[nb - 1];
          bsum[nb - 2] := bsum[nb - 2] + bsum[nb - 1];
          bn[nb - 2] := bn[nb - 2] + bn[nb - 1];
          nb := nb - 1;
        endfor
      endfor
      bs[nb] := n;
      for b = 0 upto nb - 1:
        for i = bs[b] upto bs[b + 1] - 1:
          pm_x[pm_layer[r][i]] := bsum[b] / bn[b] + c[i];
        endfor
      endfor
    fi
  endfor
  endgroup
enddef;
vardef pm_face(expr v, q) =
  save dy, hw, hh, x, cx, cy;
  cx := pm_x[v]; cy := pm_y[v];
  dy := ypart q - cy; hw := pm_fw[v] / 2; hh := pm_fh[v] / 2;
  if dy = 0:
    if xpart q > cx: (cx + hw, cy) else: (cx - hw, cy) fi
  else:
    if dy < 0: hh := -hh; fi
    x := cx + (xpart q - cx) * hh / dy;
    if x > cx + hw: x := cx + hw; elseif x < cx - hw: x := cx - hw; fi
    (x, cy + hh)
  fi
enddef;
vardef pm_needband(expr v, f, q) =
  save hh, y;
  hh := pm_rankh[pm_rank[v]] / 2;
  if ypart q > pm_y[v]: y := pm_y[v] + hh; else: y := pm_y[v] - hh; fi
  pm_band := (xpart f, y);
  (pm_fh[v] < 2hh - 1) and (abs(ypart q - pm_y[v]) > hh) and (abs(y - ypart f) > 0.5)
enddef;
pair pm_band;
def pm_routes =
  for j = 0 upto pm_ne - 1:
    if pm_ef[j] = pm_et[j]:
      begingroup save n, d, x, y, dx, dy;
      n := pm_ef[j]; d := pm_echain[j][0];
      x := pm_x[n] + pm_fw[n] / 2; y := pm_y[n];
      dx := pm_x[d] - pm_fw[d] / 2 - x; dy := pm_fh[n] / 2;
      pm_p[j][0] := (x, y - dy / 2);
      pm_p[j][1] := (x + dx, y - dy);
      pm_p[j][2] := (x + dx, y + dy);
      pm_p[j][3] := (x, y + dy / 2);
      pm_np[j] := 4;
      endgroup;
    else:
      begingroup save u, v, m, q, f, a, b, ba, bb, nc; pair q[], f[], ba, bb;
      boolean a, b;
      if pm_erev[j] = 1: u := pm_et[j]; v := pm_ef[j]; else: u := pm_ef[j]; v := pm_et[j]; fi
      nc := pm_enc[j];
      for i = 0 upto nc - 1: q[i + 1] := (pm_x[pm_echain[j][i]], pm_y[pm_echain[j][i]]); endfor
      if nc > 0:
        q[0] := pm_face(u, q[1]); q[nc + 1] := pm_face(v, q[nc]);
      else:
        q[0] := pm_face(u, (pm_x[v], pm_y[v])); q[1] := pm_face(v, (pm_x[u], pm_y[u]));
      fi
      m := nc + 2;
      a := pm_needband(u, q[0], q[1]); ba := pm_band;
      b := pm_needband(v, q[m - 1], q[m - 2]); bb := pm_band;
      pm_np[j] := 0;
      def pm_add(expr z) = pm_p[j][pm_np[j]] := z; pm_np[j] := pm_np[j] + 1; enddef;
      pm_add(q[0]);
      if a: pm_add(ba); pm_add(ba); fi
      for i = 1 upto m - 2: pm_add(q[i]); endfor
      if b: pm_add(bb); pm_add(bb); fi
      pm_add(q[m - 1]);
      if pm_erev[j] = 1:
        for i = 0 upto pm_np[j] div 2 - 1:
          f0 := pm_p[j][i]; pm_p[j][i] := pm_p[j][pm_np[j] - 1 - i];
          pm_p[j][pm_np[j] - 1 - i] := f0;
        endfor
      fi
      endgroup;
    fi
    if pm_elab[j] >= 0:
      pm_elx[j] := pm_x[pm_elab[j]]; pm_ely[j] := pm_y[pm_elab[j]];
      pm_elw[j] := pm_w[pm_elab[j]]; pm_elh[j] := pm_h[pm_elab[j]];
    fi
  endfor
enddef;
vardef pm_turn(expr z) =
  save x, y, t; x := xpart z; y := ypart z;
  if (pm_dir = 1) or (pm_dir = 3): y := -y; fi
  if pm_dir >= 2: t := x; x := y; y := t; fi
  (x, y)
enddef;
def pm_turnall =
  for v = 0 upto pm_nn - 1:
    pm_xy := pm_turn((pm_x[v], pm_y[v])); pm_x[v] := xpart pm_xy; pm_y[v] := ypart pm_xy;
  endfor
  for j = 0 upto pm_ne - 1:
    for i = 0 upto pm_np[j] - 1: pm_p[j][i] := pm_turn(pm_p[j][i]); endfor
    if pm_elab[j] >= 0:
      pm_xy := pm_turn((pm_elx[j], pm_ely[j])); pm_elx[j] := xpart pm_xy; pm_ely[j] := ypart pm_xy;
    fi
  endfor
enddef;
pair pm_xy;
vardef pm_outline(expr v) =
  save xl, top, bot, m, cx, cy, w, h, sh;
  cx := pm_x[v]; cy := pm_y[v]; w := pm_w[v]; h := pm_h[v]; sh := pm_shape[v];
  xl := cx - w / 2; top := cy - h / 2; bot := cy + h / 2;
  if sh = pm_diamond: (cx, top) -- (xl + w, cy) -- (cx, bot) -- (xl, cy) -- cycle
  elseif sh = pm_hexagon: m := h / 4;
    (xl + m, top) -- (xl + w - m, top) -- (xl + w, cy) -- (xl + w - m, bot)
      -- (xl + m, bot) -- (xl, cy) -- cycle
  elseif sh = pm_leanright:
    (xl, bot) -- (xl + w - h / 2, bot) -- (xl + w, top) -- (xl + h / 2, top) -- cycle
  elseif sh = pm_leanleft:
    (xl + h / 2, bot) -- (xl + w, bot) -- (xl + w - h / 2, top) -- (xl, top) -- cycle
  elseif sh = pm_trapezoid:
    (xl, bot) -- (xl + w, bot) -- (xl + w - h / 2, top) -- (xl + h / 2, top) -- cycle
  elseif sh = pm_invtrapezoid:
    (xl, top) -- (xl + w, top) -- (xl + w - h / 2, bot) -- (xl + h / 2, bot) -- cycle
  elseif sh = pm_asymmetric:
    (xl, top) -- (xl + w, top) -- (xl + w, bot) -- (xl, bot) -- (xl + h / 2, cy) -- cycle
  elseif (sh = pm_circle) or (sh = pm_doublecircle): fullcircle scaled w shifted (cx, cy)
  else: (xl, top) -- (xl + w, top) -- (xl + w, bot) -- (xl, bot) -- cycle
  fi
enddef;
vardef pm_clipped(expr v) =
  pm_shape[v] >= pm_circle
enddef;
vardef pm_firsthit(expr a, b, o) =
  save t, r, e; pair r, e;
  pm_hit := false; r := a;
  t := xpart ((a -- b) intersectiontimes o);
  if t >= 0:
    pm_hit := true; r := point t of (a -- b);
    forever:
      exitif abs(r - a) < 0.01;
      e := r - 0.01 * unitvector(r - a);
      t := xpart ((a -- e) intersectiontimes o);
      exitif t < 0;
      r := point t of (a -- e);
    endfor
  fi
  r
enddef;
boolean pm_hit;
vardef pm_clip(expr v, q, p) =
  save o, d, c, r, h; path o; pair d, c, r, h;
  r := q;
  if pm_clipped(v):
    o := pm_outline(v); c := (pm_x[v], pm_y[v]);
    pm_hit := false;
    if abs(q - p) > 0:
      d := unitvector(q - p) * (pm_w[v] + pm_h[v]);
      h := pm_firsthit(p, q + d, o);
      if pm_hit: r := h; fi
    fi
    if (not pm_hit) and (abs(c - q) > 0):
      h := pm_firsthit(q, c, o);
      if pm_hit: r := h; fi
    fi
  fi
  r
enddef;
def pm_clipall =
  for j = 0 upto pm_ne - 1:
    begingroup save n; n := pm_np[j];
    if pm_ef[j] = pm_et[j]:
      pm_p[j][0] := pm_clip(pm_ef[j], pm_p[j][0], pm_p[j][0]);
      pm_p[j][n - 1] := pm_clip(pm_et[j], pm_p[j][n - 1], pm_p[j][n - 1]);
    elseif n >= 2:
      pm_p[j][0] := pm_clip(pm_ef[j], pm_p[j][0], pm_p[j][1]);
      pm_p[j][n - 1] := pm_clip(pm_et[j], pm_p[j][n - 1], pm_p[j][n - 2]);
    fi
    endgroup;
  endfor
enddef;
def pm_up(expr z) = (xpart z, -ypart z) enddef;
vardef pm_basis(expr j) =
  save n, z, p, a, b, s; pair z[], a, b, s; path p;
  n := pm_np[j];
  for i = 0 upto n - 1: z[i] := pm_up(pm_p[j][i]); endfor
  if n = 2: p := z0 -- z1;
  else:
    s := (5z0 + z1) / 6;
    p := z0 .. controls ((2z0 + s) / 3) and ((z0 + 2s) / 3) .. s;
    a := z0; b := z1;
    for k = 2 upto n - 1:
      p := p .. controls ((2a + b) / 3) and ((a + 2b) / 3) .. ((a + 4b + z[k]) / 6);
      a := b; b := z[k];
    endfor
    p := p .. controls ((2a + b) / 3) and ((a + 2b) / 3) .. ((a + 5b) / 6);
    s := point infinity of p;
    p := p .. controls ((2s + b) / 3) and ((s + 2b) / 3) .. b;
  fi
  p
enddef;
vardef pm_col(expr c) = if c >= 0: pm_c[c] else: black fi enddef;
def pm_head(expr p, l, c) =
  begingroup save u, e; pair u, e;
  e := point infinity of p; u := unitvector(direction infinity of p);
  fill (e -- (e - l * u + (l / 2) * (u rotated 90)) -- (e - l * u - (l / 2) * (u rotated 90)) -- cycle)
    withcolor c;
  endgroup
enddef;
vardef pm_cut(expr p, l) =
  if arclength p > l: subpath (0, arctime (arclength p - l) of p) of p else: p fi
enddef;
def pm_marker(expr kind, p, w, c) =
  begingroup save u, e, r; pair u, e;
  e := point infinity of p; u := unitvector(direction infinity of p);
  r := 5.5pm_px; e := e - r * u;
  if kind = pm_endcircle:
    fill fullcircle scaled 2r shifted e withcolor c;
  elseif kind = pm_endcross:
    r := 0.7r;
    draw (e + (-r, -r)) -- (e + (r, r)) withpen pencircle scaled w withcolor c;
    draw (e + (-r, r)) -- (e + (r, -r)) withpen pencircle scaled w withcolor c;
  fi
  endgroup
enddef;
def pm_drawedge(expr j) =
  if (pm_evis[j] = 1) and (pm_eline[j] >= 0) and (pm_np[j] >= 2):
    begingroup save p, q, l, w, c, d; path p, q; color c;
    p := pm_basis(j); l := 8pm_px; w := pm_ewd[j] * pm_em / pm_size;
    d := pm_edash[j] * pm_em / pm_size; c := pm_c[pm_eline[j]];
    q := p;
    if pm_ehead[j] = pm_endarrow: q := pm_cut(q, l); fi
    if pm_etail[j] = pm_endarrow: q := reverse pm_cut(reverse q, l); fi
    if d > 0:
      draw q withpen pencircle scaled w withcolor c dashed dashpattern(on d off d);
    else:
      draw q withpen pencircle scaled w withcolor c;
    fi
    if pm_ehead[j] = pm_endarrow: pm_head(p, l, c); fi
    if pm_etail[j] = pm_endarrow: pm_head(reverse p, l, c); fi
    pm_marker(pm_ehead[j], p, w, c);
    pm_marker(pm_etail[j], reverse p, w, c);
    endgroup;
  fi
enddef;
def pm_drawlabel(expr j) =
  if (pm_elab[j] >= 0) and (pm_elabel[j] <> ""):
    begingroup save z; pair z;
    z := pm_up((pm_elx[j], pm_ely[j]));
    fill unitsquare shifted (-1/2, -1/2) xscaled pm_elw[j] yscaled pm_elh[j] shifted z
      withcolor pm_labelback;
    draw pm_pic[pm_elab[j]] shifted (z - center pm_pic[pm_elab[j]])
      withcolor pm_col(pm_etext[j]);
    endgroup;
  fi
enddef;
color pm_labelback; pm_labelback := (232, 232, 232) / 255;
def pm_paint(expr o, v, filled) =
  begingroup save w, d; w := pm_lw[v] * pm_em / pm_size; d := pm_dash[v] * pm_em / pm_size;
  if filled and (pm_fill[v] >= 0) and cycle o: fill o withcolor pm_c[pm_fill[v]]; fi
  if pm_line[v] >= 0:
    if d > 0:
      draw o withpen pencircle scaled w withcolor pm_c[pm_line[v]] dashed dashpattern(on d off d);
    else:
      draw o withpen pencircle scaled w withcolor pm_c[pm_line[v]];
    fi
  fi
  endgroup
enddef;
vardef pm_rbox(expr c, w, h, r) =
  save a, b; a := w / 2; b := h / 2;
  ((-a + r, -b) -- (a - r, -b) .. controls (a - r + r * 0.5523, -b) and (a, -b + r - r * 0.5523)
   .. (a, -b + r) -- (a, b - r) .. controls (a, b - r + r * 0.5523) and (a - r + r * 0.5523, b)
   .. (a - r, b) -- (-a + r, b) .. controls (-a + r - r * 0.5523, b) and (-a, b - r + r * 0.5523)
   .. (-a, b - r) -- (-a, -b + r) .. controls (-a, -b + r - r * 0.5523) and (-a + r - r * 0.5523, -b)
   .. cycle) shifted c
enddef;
def pm_drawnode(expr v) =
  begingroup save c, w, h, sh, ry, r, d, o, z; pair c, z; path o;
  c := pm_up((pm_x[v], pm_y[v])); w := pm_w[v]; h := pm_h[v]; sh := pm_shape[v];
  z := c;
  if sh = pm_rect: pm_paint(unitsquare shifted (-1/2, -1/2) xscaled w yscaled h shifted c, v, true);
  elseif sh = pm_round: pm_paint(pm_rbox(c, w, h, 5pm_px), v, true);
  elseif sh = pm_stadium: pm_paint(pm_rbox(c, w, h, h / 2), v, true);
  elseif sh = pm_subroutine:
    pm_paint(unitsquare shifted (-1/2, -1/2) xscaled w yscaled h shifted c, v, true);
    d := pm_em / 2;
    pm_paint((c + (-w / 2 + d, -h / 2)) -- (c + (-w / 2 + d, h / 2)), v, false);
    pm_paint((c + (w / 2 - d, -h / 2)) -- (c + (w / 2 - d, h / 2)), v, false);
  elseif sh = pm_cylinder:
    ry := w / 2 / (2.5 + w / 50);
    o := (c + (-w / 2, h / 2 - ry)) -- (c + (-w / 2, -h / 2 + ry))
      -- (subpath (4, 8) of fullcircle xscaled w yscaled 2ry shifted (c + (0, -h / 2 + ry)))
      -- (c + (w / 2, -h / 2 + ry)) -- (c + (w / 2, h / 2 - ry))
      -- (subpath (0, 4) of fullcircle xscaled w yscaled 2ry shifted (c + (0, h / 2 - ry)))
      -- cycle;
    pm_paint(o, v, true);
    pm_paint(fullcircle xscaled w yscaled 2ry shifted (c + (0, h / 2 - ry)), v, false);
    z := c - (0, ry);
  elseif (sh = pm_circle) or (sh = pm_doublecircle):
    pm_paint(fullcircle scaled w shifted c, v, true);
    if sh = pm_doublecircle: pm_paint(fullcircle scaled (w - 2pm_em * 5 / 16) shifted c, v, true); fi
  else:
    pm_paint(pm_outline(v) yscaled -1, v, true);
  fi
  if pm_lab[v] <> "":
    draw pm_pic[v] shifted (z - center pm_pic[v]) withcolor pm_col(pm_text[v]);
  fi
  endgroup
enddef;
def pm_end =
  begingroup save p; picture p;
  pm_em := xpart urcorner textext("\hbox to 1em{}") - xpart llcorner textext("\hbox to 1em{}");
  pm_px := pm_em / 16;
  pm_sizes;
  pm_positiony;
  pm_positionx;
  pm_routes;
  pm_turnall;
  pm_clipall;
  p := image(
    for j = 0 upto pm_ne - 1: pm_drawedge(j); endfor
    for j = 0 upto pm_ne - 1: pm_drawlabel(j); endfor
    for v = 0 upto pm_nn - 1: if pm_kind[v] = 0: pm_drawnode(v); fi endfor
  );
  if (pm_maxw > 0) and (xpart urcorner p - xpart llcorner p > pm_maxw):
    p := p scaled (pm_maxw / (xpart urcorner p - xpart llcorner p));
  fi
  draw p;
  endgroup
enddef;
pm_begin(2, 10, 432, 3, 1, 3);
pm_colour(0, 0.9255, 0.9255, 1);
pm_colour(1, 0.5765, 0.4392, 0.8588);
pm_colour(2, 0.2, 0.2, 0.2);
pm_node(0, 0, 0, 0, 18.975, 0, -1, "a {\char38} b {\char123}c{\char125}");
pm_style(0, 0, 1, 2, 0.625, 0);
pm_node(1, 0, 2, 0, 18.975, 5, -1, "done");
pm_style(1, 0, 1, 2, 0.625, 0);
pm_node(2, 2, 1, 0, 18.975, 0, 0, "");
pm_edge(0, 0, 1, 0, 2, 1, 0, 1, 2, 2, 1.25, 0, "50{\char37}")(2);
pm_end;
\stopMPcode
