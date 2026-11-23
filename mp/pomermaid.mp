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
pm_datastore := 14; pm_folder := 15; pm_bucket := 16; pm_console := 17; pm_browser := 18;
pm_person := 19; pm_bang := 20; pm_cloud := 21; pm_textshape := 22; pm_notchrect := 23;
pm_linrect := 24; pm_smcircle := 25; pm_frcircle := 26; pm_fork := 27; pm_hourglass := 28;
pm_brace := 29; pm_bracer := 30; pm_braces := 31; pm_bolt := 32; pm_doc := 33; pm_delay := 34;
pm_hcylinder := 35; pm_lincylinder := 36; pm_curvtrap := 37; pm_divrect := 38;
pm_triangle := 39; pm_winpane := 40; pm_fcircle := 41; pm_notchpent := 42;
pm_fliptriangle := 43; pm_slrect := 44; pm_docs := 45; pm_strect := 46; pm_bowrect := 47;
pm_crosscircle := 48; pm_tagdoc := 49; pm_tagrect := 50; pm_flag := 51; pm_lindoc := 52;
pm_choice := 53; pm_statebox := 54; pm_statedesc := 55;
% an isolated subgraph, laid out by itself (pm_sub), and a collapsed one
pm_sub := 56; pm_collapsed := 57;
pm_endnone := 0; pm_endarrow := 1; pm_endcircle := 2; pm_endcross := 3;

% the pixels between ranks are 2pm_ranksep, Mermaid's ranksep, for the
% layout begun; one of an isolated subgraph sets it after pm_begin
numeric pm_ranksep, pm_subof[]; picture pm_subpic[];

def pm_begin(expr d, s, mw, nn, ne, nr, nc) =
  pm_dir := d; pm_size := s; pm_maxw := mw; pm_nn := nn; pm_ne := ne; pm_nr := nr;
  pm_nc := nc; pm_ranksep := 25;
  for r = 0 upto nr - 1: pm_len[r] := 0; endfor
  for j = 0 upto ne - 1: pm_ecurve[j] := 0; endfor
enddef;

% node v is the drawing of isolated subgraph k, made by an earlier
% layout ended by pm_endsub(k)
def pm_subnode(expr v, k) = pm_subof[v] := k; enddef;

def pm_cluster(expr c, p, mn, mx, lab) =
  pm_cparent[c] := p; pm_cmin[c] := mn; pm_cmax[c] := mx; pm_ctitle[c] := lab;
enddef;

% a cluster's style is kept as that of node pm_nn + c; a composite
% state's body is filled with colour pm_cin[c], or -1 for none
numeric pm_cin[];
def pm_cstyle(expr c, f, l, t, w, d) =
  pm_style(pm_nn + c, f, l, t, w, d); pm_cin[c] := -1;
enddef;
def pm_cinner(expr c, i) = pm_cin[c] := i; enddef;

% the lines of node v's label, for a state with descriptions
numeric pm_nl[];
def pm_lines(expr v, n) = pm_nl[v] := n; enddef;

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
  elseif sh = pm_collapsed: w := max(tw + 16pm_px, 80pm_px); h := th + 44pm_px;
  elseif sh >= pm_datastore: pm_xsize;
  fi
  pm_w[v] := w; pm_h[v] := h;
  endgroup
enddef;

vardef pm_clamp(expr a, lo, hi) = max(lo, min(a, hi)) enddef;

% the size of a node of one of PmShapes's shapes, as PmShapes.Size,
% from pm_shapesize's tw, th, sh, p, w and h
def pm_xsize =
  begingroup save q, r, t, u; u := pm_px;
  if sh = pm_datastore: w := tw + 4p;
  elseif sh = pm_folder: q := 12u; w := max(tw + 2q, 90u); h := th + 2q + pm_clamp(0.16w, 8u, 14u);
  elseif sh = pm_bucket: q := 12u; w := max(tw + 2q, 80u); h := th + 2q + pm_clamp(0.08w, 5u, 12u);
  elseif sh = pm_console: q := 12u; w := max(tw + 2q, 90u); h := th + 2q + 20u;
  elseif sh = pm_browser: q := 12u; w := max(tw + 2q, 90u); h := th + 2q + 18u;
  elseif sh = pm_person:
    q := 20u; w := max(tw + 2q, 100u); r := pm_clamp(0.23w, 16u, 56u) / 2; h := 1.6r + th + 2q;
  elseif (sh = pm_bang) or (sh = pm_cloud): w := (tw + p) * 1.77; h := (th + p) * 1.77;
  elseif sh = pm_textshape: w := tw + p; h := th + p;
  elseif sh = pm_notchrect: w := tw + p + 12u; h := th + p;
  elseif (sh = pm_linrect) or (sh = pm_lindoc): w := w + 16u;
  elseif (sh = pm_smcircle) or (sh = pm_frcircle) or (sh = pm_fcircle): w := 14u; h := w;
  elseif sh = pm_fork: if pm_dir >= 2: w := 10u; h := 70u; else: w := 70u; h := 10u; fi
  elseif sh = pm_hourglass: w := 30u; h := w;
  elseif (sh >= pm_brace) and (sh <= pm_braces):
    h := th + p; r := max(5u, 0.1h);
    if sh = pm_braces: w := tw + p + 4r; else: w := tw + p + 2r; fi
  elseif sh = pm_bolt: w := 35u; h := 70u;
  elseif (sh = pm_doc) or (sh = pm_tagdoc): h := h + h / 8;
  elseif sh = pm_delay: w := w + h / 2;
  elseif sh = pm_hcylinder: w := w + 3 * (h / 2 / (2.5 + h / 50));
  elseif sh = pm_lincylinder: h := h + w / (2.5 + w / 50);
  elseif sh = pm_curvtrap: w := w + h;
  elseif sh = pm_divrect: h := 1.2h;
  elseif (sh = pm_triangle) or (sh = pm_fliptriangle):
    t := th + p; w := tw + p + 1.155t; h := max(0.866w, 2t);
  elseif sh = pm_winpane: w := w + 5u; h := h + 5u;
  elseif sh = pm_slrect: h := 1.5h;
  elseif sh = pm_docs: w := w + 10u; h := h + h / 8 + 10u;
  elseif sh = pm_strect: w := w + 10u; h := h + 10u;
  elseif sh = pm_bowrect: w := w + 2 * (h / 2 / (2.5 + h / 50));
  elseif sh = pm_crosscircle: w := 60u; h := w;
  elseif sh = pm_flag: h := h + h / 4;
  elseif sh = pm_choice: w := 28u; h := w;
  elseif (sh = pm_statebox) or (sh = pm_statedesc): w := tw + 16u; h := th + 16u;
  fi
  endgroup
enddef;

def pm_sizes =
  for v = 0 upto pm_nn - 1:
    pm_tw[v] := 0; pm_th[v] := 0;
    if (pm_kind[v] = 0) and (pm_shape[v] = pm_sub):
      pm_pic[v] := pm_subpic[pm_subof[v]];
      pm_w[v] := xpart urcorner pm_pic[v] - xpart llcorner pm_pic[v];
      pm_h[v] := ypart urcorner pm_pic[v] - ypart llcorner pm_pic[v];
    elseif pm_kind[v] = 0:
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
      y := y + m + below[r] + pm_ranksep * pm_px;
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

% PmShapes's shapes, drawn as PmShapes.Draw: pm_shapedraw(v) makes
% node v's parts pm_sp[0 .. pm_sn-1], of kinds pm_sk[] (0 the body, 1 a
% line, 2 a solid, 3 a fill), its outline pm_so, whether its label is
% drawn, pm_slab, and its centre (pm_slx, pm_sly); y down. Arcs and
% waves are polygons of as many points as PmShapes's.
path pm_cur, pm_so, pm_sp[]; numeric pm_sk[], pm_sn, pm_ck, pm_cn, pm_ox, pm_oy;
numeric pm_slx, pm_sly; boolean pm_slab; pm_slab := true;

def pm_B(expr k) = pm_ck := k; pm_cn := 0; enddef;

% the point (a, b) from the node's centre added to the part
def pm_P(expr a, b) =
  if pm_cn = 0: pm_cur := (pm_ox + a, pm_oy + b);
  else: pm_cur := pm_cur -- (pm_ox + a, pm_oy + b);
  fi
  pm_cn := pm_cn + 1;
enddef;

def pm_E =
  pm_sp[pm_sn] := if pm_ck = 1: pm_cur else: pm_cur -- cycle fi;
  pm_sk[pm_sn] := pm_ck; pm_sn := pm_sn + 1;
enddef;
def pm_O = pm_so := pm_cur -- cycle; enddef;
def pm_EO = pm_O; pm_E; enddef;

% an arc of the ellipse centred at (cx, cy), radii rx and ry, from
% angle a to angle b in degrees, 0 to the right and 90 down
def pm_arc(expr cx, cy, rx, ry, a, b) =
  begingroup save n_, t_; n_ := floor(abs(b - a) / 90 * 12) + 1;
  for k = 0 upto n_:
    t_ := a + (b - a) * k / n_; pm_P(cx + rx * cosd t_, cy + ry * sind t_);
  endfor
  endgroup
enddef;

def pm_box(expr xa, ya, xb, yb) = pm_P(xa, ya); pm_P(xb, ya); pm_P(xb, yb); pm_P(xa, yb); enddef;

def pm_rarcs(expr xa, ya, xb, yb, r) =
  pm_arc(xb - r, ya + r, r, r, 270, 360); pm_arc(xb - r, yb - r, r, r, 0, 90);
  pm_arc(xa + r, yb - r, r, r, 90, 180); pm_arc(xa + r, ya + r, r, r, 180, 270);
enddef;

% the y of a wave of amplitude a about mid, of n cycles across a w wide
% node, at xx
vardef pm_wavey(expr xx, w, mid, a, n) = mid + a * sind(360 * n * ((xx + w / 2) / w)) enddef;

% that wave from xa to xb, shifted by (dx, dy)
def pm_wave(expr dx, dy, xa, xb, w, mid, a, n) =
  for k = 0 upto 32:
    pm_P(dx + xa + (xb - xa) * k / 32, dy + pm_wavey(xa + (xb - xa) * k / 32, w, mid, a, n));
  endfor
enddef;

% a document w by h centred at (cx, cy), its bottom a wave
def pm_document(expr cx, cy, w, h) =
  pm_P(cx - w / 2, cy - h / 2); pm_P(cx + w / 2, cy - h / 2);
  pm_wave(cx, cy, w / 2, -w / 2, w, h / 2 - h / 9, h / 9, 0.8);
enddef;

% a curly brace, open to the right, its point at xa, from ya to yb
def pm_bracepath(expr xa, ya, yb, r) =
  pm_B(1);
  pm_arc(xa + 2r, ya + r, r, r, 270, 180); pm_arc(xa, -r, r, r, 0, 90);
  pm_arc(xa, r, r, r, 270, 360); pm_arc(xa + 2r, yb - r, r, r, 180, 90);
enddef;

def pm_shapedraw(expr v) =
  begingroup save sh, w, h, th, p, u, xl, yt, xr, ybo, q, r, rx, ry, t, a, b, hz, ybd, o;
  sh := pm_shape[v]; w := pm_w[v]; h := pm_h[v]; th := pm_th[v];
  p := pm_em * 15 / 16; u := pm_px;
  pm_ox := pm_x[v]; pm_oy := pm_y[v];
  xl := -w / 2; yt := -h / 2; xr := w / 2; ybo := h / 2;
  pm_sn := 0; pm_slab := true; pm_slx := pm_ox; pm_sly := pm_oy;
  if sh = pm_datastore:
    pm_B(3); pm_box(xl, yt, xr, ybo); pm_EO;
    pm_B(1); pm_P(xl, yt); pm_P(xr, yt); pm_E;
    pm_B(1); pm_P(xl, ybo); pm_P(xr, ybo); pm_E;
  elseif sh = pm_folder:
    t := pm_clamp(0.16w, 8u, 14u); a := max(0.38w, 28u);
    pm_B(0); pm_P(xl, yt); pm_P(xl + a, yt); pm_P(xl + a + t, yt + t); pm_P(xr, yt + t);
    pm_P(xr, ybo); pm_P(xl, ybo); pm_EO;
    pm_sly := pm_oy + t / 2;
  elseif sh = pm_bucket:
    ry := pm_clamp(0.08w, 5u, 12u);
    pm_B(0); pm_arc(0, yt + ry, w / 2, ry, 180, 360); pm_P(0.36w, ybo); pm_P(-0.36w, ybo); pm_EO;
    pm_B(1); pm_arc(0, yt + ry, w / 2, ry, 0, 180); pm_E;
    pm_sly := pm_oy + ry / 2;
  elseif sh = pm_console:
    pm_B(0); pm_rarcs(xl, yt, xr, ybo, 12u); pm_EO;
    pm_B(1); pm_P(xl + 12u, yt + 8u); pm_P(xl + 17u, yt + 12u); pm_P(xl + 12u, yt + 16u); pm_E;
    pm_B(1); pm_P(xl + 19u, yt + 16u); pm_P(xl + 26u, yt + 16u); pm_E;
    pm_sly := pm_oy + 10u;
  elseif sh = pm_browser:
    pm_B(0); pm_rarcs(xl, yt, xr, ybo, 12u); pm_EO;
    pm_B(1); pm_P(xl, yt + 18u); pm_P(xr, yt + 18u); pm_E;
    for k = 0 upto 2:
      pm_B(2); pm_arc(xl + (12 + 8 * k) * u, yt + 9u, 2.5u, 2.5u, 0, 360); pm_E;
    endfor
    pm_B(1); pm_box(xl + 38u, yt + 4u, xr - 12u, yt + 14u); pm_P(xl + 38u, yt + 4u); pm_E;
    pm_sly := pm_oy + 9u;
  elseif sh = pm_person:
    r := pm_clamp(0.23w, 16u, 56u) / 2; ybd := yt + 1.6r; q := min(0.2w, w / 2 - 0.8r);
    pm_B(0); pm_arc(xr - q, ybd + q, q, q, 270, 360); pm_P(xr, ybo); pm_P(xl, ybo);
    pm_arc(xl + q, ybd + q, q, q, 180, 270); pm_arc(0, yt + r, r, r, 143.1301, 396.8699);
    pm_EO;
    pm_sly := pm_oy + 0.8r;
  elseif sh = pm_bang:
    pm_B(0);
    for k = 0 upto 31:
      t := k * 360 / 32 - 90; a := if odd k: 0.82 else: 1 fi;
      pm_P(a * w / 2 * cosd t, a * h / 2 * sind t);
    endfor
    pm_EO;
  elseif sh = pm_cloud:
    pm_B(0); b := 0.1 * min(w, h);
    for k = 0 upto 9:
      t := k * 36 - 90; a := t + 36;
      xl := 0.4w * cosd t; yt := 0.4h * sind t; xr := 0.4w * cosd a; ybo := 0.4h * sind a;
      rx := ybo - yt; ry := xl - xr; q := rx ++ ry; o := min(0.35q, b);
      rx := rx / q * o; ry := ry / q * o;
      for m = 0 upto 7:
        t := sind(22.5 * m);
        pm_P(xl + (xr - xl) * m / 8 + rx * t, yt + (ybo - yt) * m / 8 + ry * t);
      endfor
    endfor
    pm_EO;
  elseif sh = pm_textshape: pm_B(0); pm_box(xl, yt, xr, ybo); pm_O;
  elseif sh = pm_notchrect:
    pm_B(0); pm_P(xl + 12u, yt); pm_P(xr, yt); pm_P(xr, ybo); pm_P(xl, ybo); pm_P(xl, yt + 12u);
    pm_EO;
  elseif sh = pm_linrect:
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_EO;
    pm_B(1); pm_P(xl + 8u, yt); pm_P(xl + 8u, ybo); pm_E;
    pm_slx := pm_ox + 4u;
  elseif (sh = pm_smcircle) or (sh = pm_fcircle):
    pm_B(2); pm_arc(0, 0, w / 2, w / 2, 0, 360); pm_EO; pm_slab := false;
  elseif sh = pm_frcircle:
    pm_B(0); pm_arc(0, 0, w / 2, w / 2, 0, 360); pm_EO;
    pm_B(2); pm_arc(0, 0, 2.5u, 2.5u, 0, 360); pm_E; pm_slab := false;
  elseif sh = pm_fork: pm_B(2); pm_box(xl, yt, xr, ybo); pm_EO; pm_slab := false;
  elseif sh = pm_hourglass:
    pm_B(0); pm_P(xl, yt); pm_P(xr, yt); pm_P(xl, ybo); pm_P(xr, ybo); pm_EO; pm_slab := false;
  elseif (sh >= pm_brace) and (sh <= pm_braces):
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_O;
    r := max(5u, 0.1h);
    if sh <> pm_bracer: pm_bracepath(xl, yt, ybo, r); pm_E; fi
    if sh <> pm_brace:
      pm_bracepath(xl, yt, ybo, r);
      pm_cur := pm_cur reflectedabout((pm_ox, 0), (pm_ox, 1)); pm_E;
    fi
    if sh = pm_brace: pm_slx := pm_ox + r; elseif sh = pm_bracer: pm_slx := pm_ox - r; fi
  elseif sh = pm_bolt:
    a := w / 35; b := h / 70;
    pm_B(0); pm_P(17.5a, -35b); pm_P(-17.5a, 3.5b); pm_P(3.5a, 3.5b);
    pm_P(-17.5a, 35b); pm_P(17.5a, -3.5b); pm_P(-3.5a, -3.5b); pm_EO;
    pm_slab := false;
  elseif (sh = pm_doc) or (sh = pm_tagdoc):
    pm_B(0); pm_document(0, 0, w, h); pm_EO;
    hz := h * 8 / 9; a := h / 9;
    if sh = pm_tagdoc:
      t := 0.2hz;
      pm_B(1); pm_P(xr - t, pm_wavey(xr - t, w, ybo - a, a, 0.8));
      pm_P(xr, pm_wavey(xr, w, ybo - a, a, 0.8) - t); pm_E;
    fi
    pm_sly := pm_oy - a / 2;
  elseif sh = pm_delay:
    pm_B(0); pm_P(xl, yt); pm_arc(xr - h / 2, 0, h / 2, h / 2, 270, 450); pm_P(xl, ybo); pm_EO;
    pm_slx := pm_ox - h / 4;
  elseif sh = pm_hcylinder:
    rx := h / 2 / (2.5 + h / 50);
    pm_B(0); pm_arc(xr - rx, 0, rx, h / 2, 270, 450); pm_arc(xl + rx, 0, rx, h / 2, 90, 270);
    pm_EO;
    pm_B(1); pm_arc(xr - rx, 0, rx, h / 2, 90, 270); pm_E;
    pm_slx := pm_ox - rx;
  elseif sh = pm_lincylinder:
    ry := w / 2 / (2.5 + w / 50);
    pm_B(0); pm_arc(0, yt + ry, w / 2, ry, 180, 360); pm_arc(0, ybo - ry, w / 2, ry, 0, 180);
    pm_EO;
    pm_B(1); pm_arc(0, yt + ry, w / 2, ry, 0, 180); pm_E;
    pm_B(1); pm_arc(0, yt + ry + 0.1h, w / 2, ry, 0, 180); pm_E;
    pm_sly := pm_oy + ry;
  elseif sh = pm_curvtrap:
    pm_B(0); pm_P(xl, 0); pm_P(xl + h / 2, yt); pm_arc(xr - h / 2, 0, h / 2, h / 2, 270, 450);
    pm_P(xl + h / 2, ybo); pm_EO;
  elseif sh = pm_divrect:
    hz := h / 1.2;
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_EO;
    pm_B(1); pm_P(xl, yt + 0.2hz); pm_P(xr, yt + 0.2hz); pm_E;
    pm_sly := pm_oy + 0.1hz;
  elseif sh = pm_triangle:
    pm_B(0); pm_P(0, yt); pm_P(xr, ybo); pm_P(xl, ybo); pm_EO;
    pm_sly := pm_oy + ybo - (th + p) / 2;
  elseif sh = pm_fliptriangle:
    pm_B(0); pm_P(xl, yt); pm_P(xr, yt); pm_P(0, ybo); pm_EO;
    pm_sly := pm_oy + yt + (th + p) / 2;
  elseif sh = pm_winpane:
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_EO;
    pm_B(1); pm_P(xl + 5u, yt); pm_P(xl + 5u, ybo); pm_E;
    pm_B(1); pm_P(xl, yt + 5u); pm_P(xr, yt + 5u); pm_E;
    pm_slx := pm_ox + 2.5u; pm_sly := pm_oy + 2.5u;
  elseif sh = pm_notchpent:
    pm_B(0); pm_P(-0.4w, yt); pm_P(0.4w, yt); pm_P(xr, -0.3h); pm_P(xr, ybo); pm_P(xl, ybo);
    pm_P(xl, -0.3h); pm_EO;
  elseif sh = pm_slrect:
    hz := h / 1.5;
    pm_B(0); pm_P(xl, yt + hz / 2); pm_P(xr, yt); pm_P(xr, ybo); pm_P(xl, ybo); pm_EO;
    pm_sly := pm_oy + hz / 4;
  elseif sh = pm_docs:
    o := 5u;
    for k = 1 step -1 until -1:
      pm_B(0); pm_document(k * o, -k * o, w - 2o, h - 2o); pm_E;
    endfor
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_O;
    pm_slx := pm_ox - o; pm_sly := pm_oy + o - (h - 2o) / 18;
  elseif sh = pm_strect:
    o := 5u;
    for k = 1 step -1 until -1:
      pm_B(0); pm_box(xl + o + k * o, yt + o - k * o, xr - o + k * o, ybo - o - k * o); pm_E;
    endfor
    pm_B(0);
    pm_P(xl + 2o, yt); pm_P(xr, yt); pm_P(xr, ybo - 2o); pm_P(xr - o, ybo - 2o);
    pm_P(xr - o, ybo - o); pm_P(xr - 2o, ybo - o); pm_P(xr - 2o, ybo); pm_P(xl, ybo);
    pm_P(xl, yt + 2o); pm_P(xl + o, yt + 2o); pm_P(xl + o, yt + o); pm_P(xl + 2o, yt + o);
    pm_O;
    pm_slx := pm_ox - o; pm_sly := pm_oy + o;
  elseif sh = pm_bowrect:
    rx := h / 2 / (2.5 + h / 50);
    pm_B(0); pm_arc(xr, 0, rx, h / 2, 270, 90); pm_arc(xl + rx, 0, rx, h / 2, 90, 270); pm_EO;
  elseif sh = pm_crosscircle:
    r := w / 2; a := r * 0.7071;
    pm_B(0); pm_arc(0, 0, r, r, 0, 360); pm_EO;
    pm_B(1); pm_P(-a, -a); pm_P(a, a); pm_E;
    pm_B(1); pm_P(-a, a); pm_P(a, -a); pm_E;
    pm_slab := false;
  elseif sh = pm_tagrect:
    t := 0.2h;
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_EO;
    pm_B(1); pm_P(xr - t, ybo); pm_P(xr, ybo - t); pm_E;
  elseif sh = pm_flag:
    a := h / 10;
    pm_B(0); pm_wave(0, 0, xl, xr, w, yt + a, a, 1); pm_wave(0, 0, xr, xl, w, ybo - a, a, 1);
    pm_EO;
  elseif sh = pm_lindoc:
    a := h / 9;
    pm_B(0); pm_document(0, 0, w, h); pm_EO;
    pm_B(1); pm_P(xl + 8u, yt); pm_P(xl + 8u, pm_wavey(xl + 8u, w, ybo - a, a, 0.8)); pm_E;
    pm_slx := pm_ox + 4u; pm_sly := pm_oy - a / 2;
  elseif sh = pm_choice:
    pm_B(0); pm_P(0, yt); pm_P(xr, 0); pm_P(0, ybo); pm_P(xl, 0); pm_EO; pm_slab := false;
  elseif sh = pm_statebox: pm_B(0); pm_rarcs(xl, yt, xr, ybo, 5u); pm_EO;
  elseif sh = pm_statedesc:
    % the title is the label's first line, the descriptions the rest
    pm_B(0); pm_box(xl, yt, xr, ybo); pm_EO;
    t := -th / 2 + th / pm_nl[v];
    pm_B(1); pm_P(xl, t); pm_P(xr, t); pm_E;
  else: pm_B(0); pm_box(xl, yt, xr, ybo); pm_EO;
  fi
  endgroup
enddef;

% part o of node v, of kind k, in its style
def pm_drawpart(expr o, k, v) =
  if k = 0: pm_paint(o, v, true);
  elseif k = 1: pm_paint(o, v, false);
  elseif k = 2:
    begingroup save c, w; w := pm_lw[v] * pm_em / pm_size;
    c := if pm_line[v] >= 0: pm_line[v] else: pm_fill[v] fi;
    if c >= 0:
      fill o withcolor pm_c[c]; draw o withpen pencircle scaled w withcolor pm_c[c];
    fi
    endgroup;
  elseif pm_fill[v] >= 0: fill o withcolor pm_c[pm_fill[v]];
  fi
enddef;

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
  elseif sh >= pm_sub: (xl, top) -- (xl + w, top) -- (xl + w, bot) -- (xl, bot) -- cycle
  elseif sh >= pm_datastore: pm_shapedraw(v); pm_so
  else: (xl, top) -- (xl + w, top) -- (xl + w, bot) -- (xl, bot) -- cycle
  fi
enddef;

% whether node v's outline is not its box
vardef pm_clipped(expr v) =
  (pm_shape[v] >= pm_circle) and (pm_shape[v] < pm_sub)
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
% The direction at the end of p, as a unit vector; where the last
% control point is the end (catmullRom's), from just before it
vardef pm_enddir(expr p) =
  save d; pair d; d := direction infinity of p;
  if abs(d) < 1/1000: d := point infinity of p - point (length p - 1/64) of p; fi
  if abs(d) < 1/1000000: (1, 0) else: unitvector(d) fi
enddef;
def pm_head(expr p, l, c) =
  begingroup save u, e; pair u, e;
  e := point infinity of p; u := pm_enddir(p);
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
  e := point infinity of p; u := pm_enddir(p);
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

% An edge's curve, other than basis, d3's as PmCurves draws it:
% 1 linear, 2 step, 3 stepBefore, 4 stepAfter, 5 cardinal, 6 catmullRom,
% 7 natural, 8 monotoneX, 9 monotoneY, 10 bumpX, 11 bumpY. The curve is
% built as Bézier pieces in pm_b[0 .. pm_nb-1], the start and then two
% control points and an end for each.
numeric pm_ecurve[], pm_nb; pair pm_b[];
def pm_curve(expr j, c) = pm_ecurve[j] := c; enddef;
def pm_badd(expr z) = pm_b[pm_nb] := z; pm_nb := pm_nb + 1; enddef;
def pm_bto(expr a, b, z) = pm_badd(a); pm_badd(b); pm_badd(z); enddef;
def pm_bline(expr z) =
  begingroup save s; pair s; s := pm_b[pm_nb - 1];
    if z <> s: pm_bto((2s + z) / 3, (s + 2z) / 3, z); fi
  endgroup
enddef;
% monotoneX's slopes, on the points q[] (x and y swapped for monotoneY)
vardef pm_sign(expr v) = if v < 0: -1 elseif v > 0: 1 else: 0 fi enddef;
vardef pm_steffen(suffix q)(expr i) =
  save h, k, d, e, s, t, u; numeric h, k, d, e, s, t, u;
  h := xpart q[i] - xpart q[i - 1]; k := xpart q[i + 1] - xpart q[i];
  d := ypart q[i] - ypart q[i - 1]; e := ypart q[i + 1] - ypart q[i];
  if (h = 0) and (k = 0): 0
  elseif h = 0: if d = 0: 0 else: (pm_sign(d) + pm_sign(e / k)) * abs(e / k) fi
  elseif k = 0: if e = 0: 0 else: (pm_sign(d / h) + pm_sign(e)) * abs(d / h) fi
  elseif h + k = 0: 0
  else:
    s := d / h; t := e / k; u := (s * k + t * h) / (h + k);
    (pm_sign(s) + pm_sign(t)) * min(abs(s), abs(t), 0.5abs(u))
  fi
enddef;
vardef pm_curved(expr j) =
  save n, c, z, q, a, b, r, s, t, l, m, p, sw, x, u, v;
  pair z[], q[], a[], b[], u, v; numeric n, c, r, s, t[], l[], m, x; path p;
  boolean sw;
  n := pm_np[j]; c := pm_ecurve[j];
  for i = 0 upto n - 1: z[i] := pm_up(pm_p[j][i]); endfor
  pm_nb := 0; pm_badd(z0);
  if (c = 1) or ((n = 2) and (c < 10)):
    for k = 1 upto n - 1: pm_bline(z[k]); endfor
  elseif c <= 4:
    s := if c = 2: 0.5 elseif c = 3: 0 else: 1 fi;
    for k = 1 upto n - 1:
      if s = 0: pm_bline((xpart z[k - 1], ypart z[k]));
      elseif s = 1: pm_bline((xpart z[k], ypart z[k - 1]));
      else:
        x := (1 - s) * xpart z[k - 1] + s * xpart z[k];
        pm_bline((x, ypart z[k - 1])); pm_bline((x, ypart z[k]));
      fi
      pm_bline(z[k]);
    endfor
  elseif c <= 6:
    z[-1] := z0; z[n] := z[n - 1];
    for k = 0 upto n - 2:
      if c = 5:
        pm_bto(z[k] + (z[k + 1] - z[k - 1]) / 6, z[k + 1] - (z[k + 2] - z[k]) / 6, z[k + 1]);
      else:
        l0 := abs(z[k] - z[k - 1]); l1 := abs(z[k + 1] - z[k]);
        l2 := abs(z[k + 2] - z[k + 1]);
        u := z[k]; v := z[k + 1];
        if sqrt(l0) > 1/1000000:
          m := 2l0 + 3sqrt(l0) * sqrt(l1) + l1;
          u := (z[k] * m - z[k - 1] * l1 + z[k + 1] * l0) / (3sqrt(l0) * (sqrt(l0) + sqrt(l1)));
        fi
        if sqrt(l2) > 1/1000000:
          m := 2l2 + 3sqrt(l2) * sqrt(l1) + l1;
          v := (z[k + 1] * m + z[k] * l2 - z[k + 2] * l1) / (3sqrt(l2) * (sqrt(l2) + sqrt(l1)));
        fi
        pm_bto(u, v, z[k + 1]);
      fi
    endfor
  elseif c = 7:
    % d3's controlPoints, x and y together, as pairs
    m := n - 1;
    q0 := (0, 2); a0 := z0 + 2z1;
    for i = 1 upto m - 2: q[i] := (1, 4); a[i] := 4z[i] + 2z[i + 1]; endfor
    q[m - 1] := (2, 7); a[m - 1] := 8z[m - 1] + z[m];
    for i = 1 upto m - 1:
      r := xpart q[i] / ypart q[i - 1];
      q[i] := (xpart q[i], ypart q[i] - r); a[i] := a[i] - r * a[i - 1];
    endfor
    a[m - 1] := a[m - 1] / ypart q[m - 1];
    for i = m - 2 downto 0: a[i] := (a[i] - a[i + 1]) / ypart q[i]; endfor
    b[m - 1] := (z[m] + a[m - 1]) / 2;
    for i = 0 upto m - 2: b[i] := 2z[i + 1] - a[i + 1]; endfor
    for i = 0 upto m - 1: pm_bto(a[i], b[i], z[i + 1]); endfor
  elseif c <= 9:
    sw := (c = 9);
    for i = 0 upto n - 1: q[i] := if sw: (ypart z[i], xpart z[i]) else: z[i] fi; endfor
    for i = 1 upto n - 2: t[i] := pm_steffen(q)(i); endfor
    x := xpart q1 - xpart q0;
    t0 := if x = 0: t1 else: (3(ypart q1 - ypart q0) / x - t1) / 2 fi;
    x := xpart q[n - 1] - xpart q[n - 2];
    t[n - 1] := if x = 0: t[n - 2]
      else: (3(ypart q[n - 1] - ypart q[n - 2]) / x - t[n - 2]) / 2 fi;
    for i = 0 upto n - 2:
      x := (xpart q[i + 1] - xpart q[i]) / 3;
      u := q[i] + (x, x * t[i]); v := q[i + 1] - (x, x * t[i + 1]);
      if sw: u := (ypart u, xpart u); v := (ypart v, xpart v); fi
      pm_bto(u, v, z[i + 1]);
    endfor
  else:
    for k = 1 upto n - 1:
      if c = 10:
        x := (xpart z[k - 1] + xpart z[k]) / 2;
        pm_bto((x, ypart z[k - 1]), (x, ypart z[k]), z[k]);
      else:
        x := (ypart z[k - 1] + ypart z[k]) / 2;
        pm_bto((xpart z[k - 1], x), (xpart z[k], x), z[k]);
      fi
    endfor
  fi
  if pm_nb < 4: pm_bto(z0, z0, z0); fi
  p := pm_b0 .. controls pm_b1 and pm_b2 .. pm_b3;
  for k = 6 step 3 until pm_nb - 1:
    p := p .. controls pm_b[k - 2] and pm_b[k - 1] .. pm_b[k];
  endfor
  p
enddef;
vardef pm_path(expr j) =
  if not known pm_ecurve[j]: pm_basis(j)
  elseif (pm_ecurve[j] < 1) or (pm_ecurve[j] > 11): pm_basis(j)
  else: pm_curved(j) fi
enddef;
def pm_drawedge(expr j) =
  if (pm_evis[j] = 1) and (pm_eline[j] >= 0) and (pm_np[j] >= 2):
    begingroup save p, q, l, w, c, d; path p, q; color c;
    p := pm_path(j); l := 8pm_px; w := pm_ewd[j] * pm_em / pm_size;
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
    if pm_labelbox:
      fill unitsquare shifted (-1/2, -1/2) xscaled pm_elw[j] yscaled pm_elh[j] shifted z
        withcolor pm_labelback;
    fi
    draw pm_pic[pm_elab[j]] shifted (z - center pm_pic[pm_elab[j]])
      withcolor pm_col(pm_etext[j]);
    endgroup;
  fi
enddef;
color pm_labelback; pm_labelback := (232, 232, 232) / 255;
boolean pm_labelbox; pm_labelbox := true;
% the diagram's title, and its colour's number, -1 for none
string pm_title; pm_title := ""; numeric pm_titlec; pm_titlec := -1;

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
  elseif sh = pm_sub:
    draw pm_pic[v] shifted (c - center pm_pic[v]);
  elseif sh = pm_collapsed:
    % Mermaid's collapsedGroup: its title, a dashed line, three dots
    pm_paint(pm_rbox(c, w, h, 8pm_px), v, true);
    z := c + (0, 14pm_px);
    d := h / 2 - 16pm_px - pm_th[v];
    if pm_line[v] >= 0:
      draw (c + (-w / 2 + 8pm_px, d)) -- (c + (w / 2 - 8pm_px, d))
        withpen pencircle scaled (pm_lw[v] * pm_em / pm_size)
        withcolor pm_c[pm_line[v]] dashed dashpattern(on 3pm_px off 3pm_px);
    fi
    for k = -1 upto 1:
      fill fullcircle scaled 5pm_px shifted (c + (10 * k * pm_px, d - 10pm_px))
        withcolor pm_col(pm_line[v]);
    endfor
  elseif sh >= pm_datastore:
    pm_shapedraw(v);
    for k = 0 upto pm_sn - 1: pm_drawpart(pm_sp[k] yscaled -1, pm_sk[k], v); endfor
    z := pm_up((pm_slx, pm_sly));
  else:
    pm_paint(pm_outline(v) yscaled -1, v, true);
  fi
  if (pm_lab[v] <> "") and ((sh < pm_datastore) or (sh = pm_collapsed) or pm_slab):
    draw pm_pic[v] shifted (z - center pm_pic[v]) withcolor pm_col(pm_text[v]);
  fi
  endgroup
enddef;

% cluster c's box and title, in its style
% cluster c's box and title, in its style; a composite state's title
% on a band at its top, its body below
def pm_drawcluster(expr c) =
  if pm_cmin[c] >= 0:
    if (pm_cin[c] >= 0) and (abs(pm_ctx[c] - pm_cx[c]) < 0.5) and (pm_cty[c] < pm_cy[c]):
      begingroup save th, top, d, bot;
      pm_paint(pm_rbox(pm_up((pm_cx[c], pm_cy[c])), pm_cw[c], pm_ch[c], 5pm_px), pm_nn + c, true);
      th := ypart urcorner pm_cpic[c] - ypart llcorner pm_cpic[c];
      top := pm_cy[c] - pm_ch[c] / 2; bot := pm_cy[c] + pm_ch[c] / 2;
      d := pm_cty[c] + th / 2 + (pm_cty[c] - top - th / 2);
      fill unitsquare shifted (-1/2, -1/2) xscaled pm_cw[c] yscaled (bot - d)
        shifted pm_up((pm_cx[c], (d + bot) / 2)) withcolor pm_c[pm_cin[c]];
      pm_paint(unitsquare shifted (-1/2, -1/2) xscaled pm_cw[c] yscaled (bot - d)
        shifted pm_up((pm_cx[c], (d + bot) / 2)), pm_nn + c, false);
      endgroup;
    else:
      pm_paint(unitsquare shifted (-1/2, -1/2) xscaled pm_cw[c] yscaled pm_ch[c]
        shifted pm_up((pm_cx[c], pm_cy[c])), pm_nn + c, true);
    fi
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

% the title, 18 pixels to the labels' 16, centred above p, its
% baseline Mermaid's titleTopMargin, 25 pixels, above p's top
def pm_drawtitle(suffix p) =
  begingroup save t; picture t;
  t := textext(pm_title) scaled (18/16);
  t := t shifted ((xpart llcorner p + xpart urcorner p) / 2
    - (xpart llcorner t + xpart urcorner t) / 2, ypart urcorner p + 25pm_px);
  p := image(draw p; draw t withcolor pm_col(pm_titlec));
  endgroup
enddef;

% the layout begun, drawn: as pm_end, but kept as isolated subgraph
% k's drawing, not drawn, not scaled, with no title
def pm_endsub(expr k) =
  begingroup save p; picture p;
  pm_layout;
  pm_subpic[k] := pm_drawing;
  endgroup
enddef;

def pm_layout =
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
enddef;

def pm_drawing =
  image(
    pm_drawclusters(-1);
    for j = 0 upto pm_ne - 1: pm_drawedge(j); endfor
    for j = 0 upto pm_ne - 1: pm_drawlabel(j); endfor
    for v = 0 upto pm_nn - 1: if pm_kind[v] = 0: pm_drawnode(v); fi endfor
  )
enddef;

def pm_end =
  begingroup save p; picture p;
  pm_layout;
  p := pm_drawing;
  if pm_title <> "": pm_drawtitle(p); fi
  if (pm_maxw > 0) and (xpart urcorner p - xpart llcorner p > pm_maxw):
    p := p scaled (pm_maxw / (xpart urcorner p - xpart llcorner p));
  fi
  draw p;
  endgroup
enddef;
