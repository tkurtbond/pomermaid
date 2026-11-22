% pomermaid.mp: the geometry half of pomermaid's flowchart layout, in
% MetaPost (MetaFun, ConTeXt LMTX).
%
% Copyright 2026 T. Kurt Bond. BSD 3-Clause License; see LICENSE.
%
% pomermaid lays a flowchart out at the size of its estimate (--size),
% in a groff font, and writes the topology as calls of these macros:
% each node's rank, its place in the rank, its shape and label, and
% where the estimate put it along the rank; each edge's nodes and
% dummies. These macros then set each label with textext, in the
% document's font, size the nodes from them, as pomermaid does, place
% the ranks one after another and the nodes along each rank, route the
% edges as pomermaid does, and draw it all, as pomermaid's pic writer
% draws it.
%
% Along each rank the nodes go where the estimate put them, scaled from
% its size to the document's em, moved apart where they would be too
% close: the positions nearest those, in the least squares sense, that
% keep the nodes in order and far enough apart (pool adjacent
% violators). pomermaid's layout uses Brandes and Köpf's method.
%
% Subgraphs are clusters: pomermaid gives each its ranks and, in each
% of them, its left and right borders, nodes of no size that the
% positions keep apart from what is beside them. The macros make room
% above and below the ranks for the clusters' padding and titles, push
% the nodes right where a cluster's borders are not in line or its box
% is too narrow for its title, as pomermaid's layout does, and draw the
% boxes, those that hold others first, before the edges. An edge to a
% subgraph ends at its box.

% Lengths are in bp; the layout's y runs down, and is turned over when
% drawn. Spacing and padding are Mermaid's, in its pixels, 16 to the
% em.
%
% The calls:
%
%   pm_begin(dir, size, width, nodes, edges, ranks, clusters);
%   pm_colour(c, r, g, b);
%   pm_cluster(c, parent, firstrank, lastrank, "title");
%   pm_cstyle(c, fill, line, text, width, dash);
%   pm_node(v, kind, rank, order, x, shape, edge, "label");
%   pm_style(v, fill, line, text, width, dash);
%   pm_edge(j, from, to, fromcluster, tocluster, reversed, labelnode,
%     head, tail, visible, line, text, width, dash, "label")(chain);
%   pm_end;
%
% dir is 0 to 3, TB, BT, LR, RL. size is the estimate's size, and width
% the widest the drawing may be (0 for no limit), in bp. Colours are
% numbered from 0, -1 for none. kind is 0 for a node, 1 a dummy, 2 the
% dummy of an edge's label, 3 the dummy beside a node of its self-loop,
% 4 and 5 a cluster's left and right border in a rank (edge is then the
% cluster), 6 a node not drawn, that stands for a cluster. A cluster's
% parent is -1 for none, its ranks -1 if it holds no node; an edge's
% clusters are those it ends at the box of, -1 for none.
% Widths and dashes are at the estimate's size, and grow with the em.
% shape, head and tail are PmFlow's numbers.

numeric pm_dir, pm_size, pm_maxw, pm_nn, pm_ne, pm_nr, pm_em, pm_px;
numeric pm_kind[], pm_rank[], pm_order[], pm_tx[], pm_shape[], pm_ofedge[];
numeric pm_w[], pm_h[], pm_fw[], pm_fh[], pm_x[], pm_y[], pm_tw[], pm_th[];
numeric pm_fill[], pm_line[], pm_text[], pm_lw[], pm_dash[];
numeric pm_layer[][], pm_len[], pm_rankh[];
numeric pm_ef[], pm_et[], pm_erev[], pm_elab[], pm_ehead[], pm_etail[], pm_evis[];
numeric pm_eline[], pm_etext[], pm_ewd[], pm_edash[], pm_echain[][], pm_enc[];
numeric pm_elw[], pm_elh[], pm_elx[], pm_ely[];
numeric pm_nc, pm_cparent[], pm_cmin[], pm_cmax[], pm_cdepth[], pm_ctw[], pm_cth[];
numeric pm_ctop[], pm_cbot[], pm_cextra[], pm_cx[], pm_cy[], pm_cw[], pm_ch[];
numeric pm_ctx[], pm_cty[], pm_cleft[][], pm_cright[][], pm_ranky[];
numeric pm_efc[], pm_etc[];
string pm_ctitle[]; picture pm_cpic[];
pair pm_p[][]; numeric pm_np[];
color pm_c[];
string pm_lab[], pm_elabel[];
picture pm_pic[];

% the shapes and edge ends, as PmFlow's
pm_rect := 0; pm_round := 1; pm_stadium := 2; pm_subroutine := 3;
pm_cylinder := 4; pm_circle := 5; pm_asymmetric := 6; pm_diamond := 7;
pm_hexagon := 8; pm_leanright := 9; pm_leanleft := 10; pm_trapezoid := 11;
pm_invtrapezoid := 12; pm_doublecircle := 13;
pm_endnone := 0; pm_endarrow := 1; pm_endcircle := 2; pm_endcross := 3;

def pm_begin(expr d, s, mw, nn, ne, nr, nc) =
  pm_dir := d; pm_size := s; pm_maxw := mw; pm_nn := nn; pm_ne := ne; pm_nr := nr;
  pm_nc := nc;
  for r = 0 upto nr - 1: pm_len[r] := 0; endfor
enddef;

def pm_cluster(expr c, p, mn, mx, lab) =
  pm_cparent[c] := p; pm_cmin[c] := mn; pm_cmax[c] := mx; pm_ctitle[c] := lab;
enddef;

% a cluster's style is kept as that of node pm_nn + c
def pm_cstyle(expr c, f, l, t, w, d) =
  pm_style(pm_nn + c, f, l, t, w, d);
enddef;

def pm_colour(expr c, r, g, b) =
  pm_c[c] := (r, g, b);
enddef;

def pm_node(expr v, k, r, o, x, sh, e, lab) =
  pm_kind[v] := k; pm_rank[v] := r; pm_order[v] := o; pm_tx[v] := x;
  pm_shape[v] := sh; pm_ofedge[v] := e; pm_lab[v] := lab;
  if k = 6:
    pm_x[v] := 0; pm_y[v] := 0;
  else:
    pm_layer[r][o] := v;
    if o + 1 > pm_len[r]: pm_len[r] := o + 1; fi
    if k = 4: pm_cleft[e][r] := v; elseif k = 5: pm_cright[e][r] := v; fi
  fi
enddef;

def pm_style(expr v, f, l, t, w, d) =
  pm_fill[v] := f; pm_line[v] := l; pm_text[v] := t; pm_lw[v] := w; pm_dash[v] := d;
enddef;

def pm_edge(expr j, f, t, fc, tc, rv, ln, hd, tl, vis, l, tx, w, d, lab)(text chain) =
  pm_ef[j] := f; pm_et[j] := t; pm_efc[j] := fc; pm_etc[j] := tc;
  pm_erev[j] := rv; pm_elab[j] := ln;
  pm_ehead[j] := hd; pm_etail[j] := tl; pm_evis[j] := vis;
  pm_eline[j] := l; pm_etext[j] := tx; pm_ewd[j] := w; pm_edash[j] := d;
  pm_elabel[j] := lab; pm_enc[j] := 0;
  for c = chain: pm_echain[j][pm_enc[j]] := c; pm_enc[j] := pm_enc[j] + 1; endfor
enddef;

% a label set by ConTeXt: its lines centred, one below another
vardef pm_textext(expr s) =
  textext("\framed[frame=off,offset=0pt,align=middle]{" & s & "}")
enddef;

% Sizes

% node v's size from its label's, tw by th, as PmMetrics.ShapeSize
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
    elseif (if (pm_kind[v] = 2) or (pm_kind[v] = 3): pm_elabel[pm_ofedge[v]] else: "" fi) <> "":
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
  for c = 0 upto pm_nc - 1:
    pm_cpic[c] := pm_textext(pm_ctitle[c]);
    pm_ctw[c] := xpart urcorner pm_cpic[c] - xpart llcorner pm_cpic[c];
    pm_cth[c] := ypart urcorner pm_cpic[c] - ypart llcorner pm_cpic[c];
  endfor
enddef;

% each cluster's depth, 0 for one no other holds
def pm_depths =
  for c = 0 upto pm_nc - 1:
    begingroup save p; pm_cdepth[c] := 0; p := pm_cparent[c];
    forever:
      exitif p < 0;
      pm_cdepth[c] := pm_cdepth[c] + 1; p := pm_cparent[p];
    endfor
    endgroup;
  endfor
enddef;

% Positions

% the ranks, one below another, half rank spacing apart, with room
% above a cluster's first rank for its padding and, for TB, its title,
% and for those of the clusters it holds that start there too; below
% its last the same, with the title for BT. For LR and RL, a cluster is
% made at least as long as its title and padding. As PmLayout.PositionY.
def pm_positiony =
  begingroup save y, m, pad, maxd, pass, again, t, cp, above, below, topx, botx,
    subtop, subbot;
  numeric above[], below[], topx[], botx[], subtop[], subbot[]; boolean again;
  pad := 15pm_px;
  for r = 0 upto pm_nr - 1:
    m := 0;
    for i = 0 upto pm_len[r] - 1: m := max(m, pm_fh[pm_layer[r][i]]); endfor
    pm_rankh[r] := m;
  endfor
  maxd := 0;
  for c = 0 upto pm_nc - 1: maxd := max(maxd, pm_cdepth[c]); pm_cextra[c] := 0; endfor
  pass := 0;
  forever:
    for r = 0 upto pm_nr - 1: above[r] := 0; below[r] := 0; endfor
    for c = 0 upto pm_nc - 1: subtop[c] := 0; subbot[c] := 0; endfor
    for d = maxd downto 0:
      for c = 0 upto pm_nc - 1:
        if (pm_cdepth[c] = d) and (pm_cmin[c] >= 0):
          if pm_dir = 0: topx[c] := pm_cth[c] + 1.5pad; else: topx[c] := pad; fi
          if pm_dir = 1: botx[c] := pm_cth[c] + 1.5pad; else: botx[c] := pad; fi
          topx[c] := topx[c] + subtop[c]; botx[c] := botx[c] + subbot[c] + pm_cextra[c];
          above[pm_cmin[c]] := max(above[pm_cmin[c]], topx[c]);
          below[pm_cmax[c]] := max(below[pm_cmax[c]], botx[c]);
          cp := pm_cparent[c];
          if cp >= 0:
            if pm_cmin[c] = pm_cmin[cp]: subtop[cp] := max(subtop[cp], topx[c]); fi
            if pm_cmax[c] = pm_cmax[cp]: subbot[cp] := max(subbot[cp], botx[c]); fi
          fi
        fi
      endfor
    endfor
    y := 0;
    for r = 0 upto pm_nr - 1:
      y := y + above[r]; pm_ranky[r] := y; m := pm_rankh[r];
      for i = 0 upto pm_len[r] - 1: pm_y[pm_layer[r][i]] := y + m / 2; endfor
      y := y + m + below[r] + 25pm_px;
    endfor
    again := false;
    for c = 0 upto pm_nc - 1:
      if pm_cmin[c] >= 0:
        pm_ctop[c] := pm_ranky[pm_cmin[c]] - topx[c];
        pm_cbot[c] := pm_ranky[pm_cmax[c]] + pm_rankh[pm_cmax[c]] + botx[c];
        if pm_dir >= 2:
          t := pm_ctw[c] + 2pad - (pm_cbot[c] - pm_ctop[c]);
          if t > 0.01: pm_cextra[c] := pm_cextra[c] + t; again := true; fi
        fi
      fi
    endfor
    pass := pass + 1;
    exitif (not again) or (pass = 3);
  endfor
  endgroup
enddef;

% how far apart the centres of neighbours v and u, v on the left, must
% be: a cluster's padding inside its borders, and, for LR and RL, its
% title after its left border; else a node or border counts as node
% spacing, a dummy as edge spacing
vardef pm_sep(expr v, u) =
  save x; x := pm_fw[v] / 2 + pm_fw[u] / 2;
  if (pm_kind[v] = 4) or (pm_kind[u] = 5):
    if pm_kind[v] = 4:
      if pm_dir >= 2: x := x + pm_cth[pm_ofedge[v]] + 22.5pm_px; else: x := x + 15pm_px; fi
    fi
    if pm_kind[u] = 5: x := x + 15pm_px; fi
  else:
    x := x + (if (pm_kind[v] = 0) or (pm_kind[v] >= 4): 25 else: 10 fi) * pm_px
      + (if (pm_kind[u] = 0) or (pm_kind[u] >= 4): 25 else: 10 fi) * pm_px;
  fi
  x
enddef;

% along each rank, the positions nearest the estimate's, scaled, that
% keep each node far enough from the next
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

% after pm_positionx, the separations kept, and each cluster's borders
% in line, wide enough for its title for TB and BT, by moving nodes
% right, as PmLayout's Repair
def pm_repair =
  begingroup save it, changed, m, lx, rx, lo, hi, t, u, v; boolean changed;
  it := 0;
  forever:
    changed := false;
    for r = 0 upto pm_nr - 1:
      for i = 1 upto pm_len[r] - 1:
        u := pm_layer[r][i - 1]; v := pm_layer[r][i];
        m := pm_x[u] + pm_sep(u, v);
        if pm_x[v] < m - 0.001: pm_x[v] := m; changed := true; fi
      endfor
    endfor
    for c = 0 upto pm_nc - 1:
      if pm_cmin[c] >= 0:
        lx := pm_x[pm_cleft[c][pm_cmin[c]]]; rx := pm_x[pm_cright[c][pm_cmin[c]]];
        for r = pm_cmin[c] + 1 upto pm_cmax[c]:
          lx := max(lx, pm_x[pm_cleft[c][r]]); rx := max(rx, pm_x[pm_cright[c][r]]);
        endfor
        if pm_dir < 2: m := pm_ctw[c] + 30pm_px; else: m := 0; fi
        if rx < lx + m - 0.001:
          % wider for its title: what it holds moved to the middle
          lo := rx; hi := lx;
          for r = pm_cmin[c] upto pm_cmax[c]:
            for i = pm_order[pm_cleft[c][r]] + 1 upto pm_order[pm_cright[c][r]] - 1:
              v := pm_layer[r][i];
              lo := min(lo, pm_x[v] - pm_fw[v] / 2); hi := max(hi, pm_x[v] + pm_fw[v] / 2);
            endfor
          endfor
          t := lx + m / 2 - (lo + hi) / 2;
          if (hi < lo) or (t < 0): t := 0; fi
          for r = pm_cmin[c] upto pm_cmax[c]:
            for i = pm_order[pm_cleft[c][r]] + 1 upto pm_order[pm_cright[c][r]] - 1:
              v := pm_layer[r][i]; pm_x[v] := pm_x[v] + t;
            endfor
          endfor
          rx := lx + m;
        fi
        for r = pm_cmin[c] upto pm_cmax[c]:
          if pm_x[pm_cleft[c][r]] < lx - 0.001: pm_x[pm_cleft[c][r]] := lx; changed := true; fi
          if pm_x[pm_cright[c][r]] < rx - 0.001: pm_x[pm_cright[c][r]] := rx; changed := true; fi
        endfor
      fi
    endfor
    it := it + 1;
    exitif (not changed) or (it = 200);
  endfor
  endgroup
enddef;

% each cluster's box, from its borders in its first rank, and the
% centre of its title, as PmLayout.Boxes
def pm_boxes =
  for c = 0 upto pm_nc - 1:
    if pm_cmin[c] >= 0:
      begingroup save lx, rx;
      lx := pm_x[pm_cleft[c][pm_cmin[c]]]; rx := pm_x[pm_cright[c][pm_cmin[c]]];
      pm_cx[c] := (lx + rx) / 2; pm_cw[c] := rx - lx;
      pm_cy[c] := (pm_ctop[c] + pm_cbot[c]) / 2; pm_ch[c] := pm_cbot[c] - pm_ctop[c];
      if pm_dir = 0:
        pm_ctx[c] := pm_cx[c]; pm_cty[c] := pm_ctop[c] + 7.5pm_px + pm_cth[c] / 2;
      elseif pm_dir = 1:
        pm_ctx[c] := pm_cx[c]; pm_cty[c] := pm_cbot[c] - 7.5pm_px - pm_cth[c] / 2;
      else:
        pm_ctx[c] := lx + 7.5pm_px + pm_cth[c] / 2; pm_cty[c] := pm_cy[c];
      fi
      endgroup;
    fi
  endfor
enddef;

% Routes

% where the line from node v's centre towards q, in another rank,
% crosses the face of its box that faces that rank, as PmLayout.Face
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

% for an end at node v, at face point f, towards q: the edge of v's
% rank's band, as PmLayout.Bands, in pm_band; false if not needed
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

% the drawing turned from the frame to its direction, as PmLayout.Turn
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
  for c = 0 upto pm_nc - 1:
    if pm_cmin[c] >= 0:
      pm_xy := pm_turn((pm_cx[c], pm_cy[c])); pm_cx[c] := xpart pm_xy; pm_cy[c] := ypart pm_xy;
      pm_xy := pm_turn((pm_ctx[c], pm_cty[c])); pm_ctx[c] := xpart pm_xy; pm_cty[c] := ypart pm_xy;
      if pm_dir >= 2: pm_xy := (pm_cw[c], pm_ch[c]); pm_cw[c] := ypart pm_xy; pm_ch[c] := xpart pm_xy; fi
    fi
  endfor
enddef;
pair pm_xy;

% Outlines, y down

% the outline of node v, of shape sh, w by h, centred at c, as a closed
% path, y down: the polygon of PmFlowLayout.Outline, a circle, or its
% box
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

% whether node v's outline is not its box
vardef pm_clipped(expr v) =
  pm_shape[v] >= pm_circle
enddef;

% the first point, from a, where the line a--b meets the path o, as
% PmGeom.FirstHit; pm_hit is false if it does not. intersectiontimes
% finds a crossing, not the first: each one found is looked for again
% on the line before it.
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

% the end q of an edge at node v moved in to v's outline, along the
% edge's last piece from p if that meets it, else towards v's centre,
% as PmFlowLayout.Clip
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

% whether z is inside cluster c's box
vardef pm_inbox(expr c, z) =
  (abs(xpart z - pm_cx[c]) < pm_cw[c] / 2) and (abs(ypart z - pm_cy[c]) < pm_ch[c] / 2)
enddef;

% edge j's route cut where it leaves cluster c's box, at its start if
% start, else at its end, as PmFlowLayout.CutBox: the points inside are
% dropped, and the edge ends where the piece that leaves the box meets it
def pm_cutbox(expr j, c, start) =
  begingroup save n, i, a, b, m, q; pair a, b, m, q[];
  n := pm_np[j];
  for k = 0 upto n - 1:
    if start: q[k] := pm_p[j][k]; else: q[k] := pm_p[j][n - 1 - k]; fi
  endfor
  i := 0;
  forever:
    exitif i = n;
    exitunless pm_inbox(c, q[i]);
    i := i + 1;
  endfor
  if (i > 0) and (i < n):
    a := q[i - 1]; b := q[i];
    for k = 1 upto 40:
      m := 0.5[a, b];
      if pm_inbox(c, m): a := m; else: b := m; fi
    endfor
    q[i - 1] := b;
    for k = 0 upto n - i:
      if start: pm_p[j][k] := q[i - 1 + k]; else: pm_p[j][n - i - k] := q[i - 1 + k]; fi
    endfor
    pm_np[j] := n - i + 1;
  fi
  endgroup;
enddef;

def pm_clipall =
  for j = 0 upto pm_ne - 1:
    begingroup save n; n := pm_np[j];
    if pm_ef[j] = pm_et[j]:
      pm_p[j][0] := pm_clip(pm_ef[j], pm_p[j][0], pm_p[j][0]);
      pm_p[j][n - 1] := pm_clip(pm_et[j], pm_p[j][n - 1], pm_p[j][n - 1]);
    elseif n >= 2:
      if pm_efc[j] >= 0: pm_cutbox(j, pm_efc[j], true);
      else: pm_p[j][0] := pm_clip(pm_ef[j], pm_p[j][0], pm_p[j][1]); fi
      n := pm_np[j];
      if pm_etc[j] >= 0: pm_cutbox(j, pm_etc[j], false);
      else: pm_p[j][n - 1] := pm_clip(pm_et[j], pm_p[j][n - 1], pm_p[j][n - 2]); fi
    fi
    endgroup;
  endfor
enddef;

% Drawing, y up

% z, y down, as MetaPost's point, y up
def pm_up(expr z) = (xpart z, -ypart z) enddef;

% edge j's route as the Bézier curves of d3's curveBasis, y up, as
% PmGeom.Basis
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

% the colour c, or black for none
vardef pm_col(expr c) = if c >= 0: pm_c[c] else: black fi enddef;

% a filled arrowhead at the end of p, l long
def pm_head(expr p, l, c) =
  begingroup save u, e; pair u, e;
  e := point infinity of p; u := unitvector(direction infinity of p);
  fill (e -- (e - l * u + (l / 2) * (u rotated 90)) -- (e - l * u - (l / 2) * (u rotated 90)) -- cycle)
    withcolor c;
  endgroup
enddef;

% p without its last l
vardef pm_cut(expr p, l) =
  if arclength p > l: subpath (0, arctime (arclength p - l) of p) of p else: p fi
enddef;

% a circle or a cross at the end of p
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

% outline o filled and drawn in node v's style
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

% a w by h box centred at c, its corners rounded to radius r
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

% cluster c's box and title, in its style
def pm_drawcluster(expr c) =
  if pm_cmin[c] >= 0:
    pm_paint(unitsquare shifted (-1/2, -1/2) xscaled pm_cw[c] yscaled pm_ch[c]
      shifted pm_up((pm_cx[c], pm_cy[c])), pm_nn + c, true);
    draw pm_cpic[c] shifted (pm_up((pm_ctx[c], pm_cty[c])) - center pm_cpic[c])
      withcolor pm_col(pm_text[pm_nn + c]);
  fi
enddef;

% the clusters cluster p holds (-1: those no cluster holds), each before
% those it holds
def pm_drawclusters(expr p) =
  for c = 0 upto pm_nc - 1:
    if pm_cparent[c] = p: pm_drawcluster(c); pm_drawclusters(c); fi
  endfor
enddef;

def pm_end =
  begingroup save p; picture p;
  pm_em := xpart urcorner textext("\hbox to 1em{}") - xpart llcorner textext("\hbox to 1em{}");
  pm_px := pm_em / 16;
  pm_sizes;
  pm_depths;
  pm_positiony;
  pm_positionx;
  pm_repair;
  pm_boxes;
  pm_routes;
  pm_turnall;
  pm_clipall;
  p := image(
    pm_drawclusters(-1);
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
