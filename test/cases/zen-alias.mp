\startMPcode
numeric pms_maxw, pms_n, pms_ne, pms_nb, pms_mirror, pms_em, pms_px;
numeric pms_atype[], pms_abox[], pms_acre[], pms_ades[];
numeric pms_x[], pms_w[], pms_top[], pms_tw[], pms_th[], pms_ly[];
numeric pms_lifea[], pms_lifeb[], pms_foot[], pms_footer[], pms_bw[];
numeric pms_bfill[], pms_btw[], pms_bth[];
numeric pms_bxa[], pms_bya[], pms_bxb[], pms_byb[], pms_btx[], pms_bty[];
numeric pms_ek[], pms_efrom[], pms_eto[], pms_edot[], pms_ehead[], pms_etail[];
numeric pms_eact[], pms_ecto[], pms_ecfrom[], pms_eplace[], pms_eblock[], pms_efill[];
numeric pms_ga[], pms_gb[], pms_gc[], pms_gd[], pms_ge[], pms_gtx[], pms_gty[];
numeric pms_gtw[], pms_gth[], pms_gself[];
numeric pms_gap[][], pms_stack[], pms_lev[];
numeric pms_fr[], pms_fpar[], pms_fhas[], pms_flo[], pms_fhi[], pms_fns[];
numeric pms_fxa[], pms_fya[], pms_fxb[], pms_fyb[], pms_flw[], pms_flh[];
numeric pms_ftw[], pms_ftx[], pms_fty[], pms_sy[][], pms_stw[][], pms_sty[][];
numeric pms_rxa[], pms_rya[], pms_rxb[], pms_ryb[], pms_rbelow[];
numeric pms_nf, pms_nbar, pms_open, pms_y, pms_liney, pms_lastline, pms_h, pms_bandh;
string pms_alab[], pms_btitle[], pms_enum[], pms_etext[], pms_kname[];
picture pms_apic[], pms_bpic[], pms_epic[], pms_flpic[], pms_ftpic[], pms_spic[][];
color pms_c[];
string pms_title; pms_title := "";
numeric pms_cafill, pms_caline, pms_catext, pms_clife, pms_csig, pms_csigtext;
numeric pms_clfill, pms_clline, pms_cltext, pms_clooptext, pms_cnfill, pms_cnline;
numeric pms_cntext, pms_cbfill, pms_cbline, pms_cnum, pms_cnumtext, pms_ctitle;
numeric pms_cboxline;
pms_kname[0] := "loop"; pms_kname[1] := "opt"; pms_kname[2] := "alt";
pms_kname[3] := "par"; pms_kname[4] := "par"; pms_kname[5] := "critical";
pms_kname[6] := "break"; pms_kname[7] := "";
pms_kname[8] := "try"; pms_kname[9] := "section"; pms_kname[10] := "ref";
def pms_begin(expr mw, n, ne, nb, m) =
  pms_maxw := mw; pms_n := n; pms_ne := ne; pms_nb := nb; pms_mirror := m;
  pms_title := "";
enddef;
def pms_colour(expr c, r, g, b) = pms_c[c] := (r, g, b); enddef;
def pms_theme(expr af, al, at, li, sg, st, lf, ll, lt, ot, nf, nl, nt, bf, bl, nu, ut, ti, bx) =
  pms_cafill := af; pms_caline := al; pms_catext := at; pms_clife := li;
  pms_csig := sg; pms_csigtext := st; pms_clfill := lf; pms_clline := ll;
  pms_cltext := lt; pms_clooptext := ot; pms_cnfill := nf; pms_cnline := nl;
  pms_cntext := nt; pms_cbfill := bf; pms_cbline := bl; pms_cnum := nu;
  pms_cnumtext := ut; pms_ctitle := ti; pms_cboxline := bx;
enddef;
def pms_box(expr k, f, s) = pms_bfill[k] := f; pms_btitle[k] := s; enddef;
def pms_actor(expr i, t, bx, cr, ds, s) =
  pms_atype[i] := t; pms_abox[i] := bx; pms_acre[i] := cr; pms_ades[i] := ds;
  pms_alab[i] := s;
enddef;
def pms_event(expr q, k, f, t, s) =
  pms_ek[q] := k; pms_efrom[q] := f; pms_eto[q] := t; pms_etext[q] := s;
  pms_edot[q] := 0; pms_ehead[q] := 0; pms_etail[q] := 0; pms_eact[q] := 0;
  pms_ecto[q] := 0; pms_ecfrom[q] := 0; pms_eplace[q] := 0; pms_eblock[q] := 0;
  pms_efill[q] := -1; pms_enum[q] := "";
enddef;
def pms_msg(expr q, f, t, dt, hd, tl, ac, ct, cf, nm, s) =
  pms_event(q, 0, f, t, s);
  pms_edot[q] := dt; pms_ehead[q] := hd; pms_etail[q] := tl; pms_eact[q] := ac;
  pms_ecto[q] := ct; pms_ecfrom[q] := cf; pms_enum[q] := nm;
enddef;
def pms_note(expr q, f, t, pl, s) = pms_event(q, 1, f, t, s); pms_eplace[q] := pl; enddef;
def pms_start(expr q, k, f, s) =
  pms_event(q, 2, -1, -1, s); pms_eblock[q] := k; pms_efill[q] := f;
enddef;
def pms_else(expr q, s) = pms_event(q, 3, -1, -1, s); enddef;
def pms_stop(expr q) = pms_event(q, 4, -1, -1, ""); enddef;
def pms_activate(expr q, a) = pms_event(q, 5, a, a, ""); enddef;
def pms_deactivate(expr q, a) = pms_event(q, 6, a, a, ""); enddef;
vardef pms_text(expr s) =
  textext("\framed[frame=off,offset=0pt,align=middle]{" & s & "}")
enddef;
vardef pms_picw(expr p) = xpart urcorner p - xpart llcorner p enddef;
vardef pms_pich(expr p) = ypart urcorner p - ypart llcorner p enddef;
def pms_measure(suffix p, w, h)(expr s) =
  if s = "": p := nullpicture; w := 0; h := 0;
  else: p := pms_text(s); w := pms_picw(p); h := pms_pich(p); fi
enddef;
vardef pms_up(expr a, b) = (a, -b) enddef;
def pms_need(expr a, b, v) =
  if a < b:
    if v > pms_gap[a][b]: pms_gap[a][b] := v; fi
  elseif b < a:
    if v > pms_gap[b][a]: pms_gap[b][a] := v; fi
  fi
enddef;
def pms_columns =
  for i = 0 upto pms_n - 1: for j = 0 upto pms_n - 1: pms_gap[i][j] := 0; endfor endfor
  for i = 0 upto pms_n - 1:
    pms_bw[i] := pms_w[i];
    if pms_abox[i] >= 0:
      if pms_btitle[pms_abox[i]] <> "":
        pms_alone := 1;
        for j = 0 upto pms_n - 1:
          if (j <> i) and (pms_abox[j] = pms_abox[i]): pms_alone := 0; fi
        endfor
        if pms_alone = 1: pms_bw[i] := max(pms_bw[i], pms_btw[pms_abox[i]]); fi
      fi
    fi
  endfor
  for i = 0 upto pms_n - 2:
    pms_v := (pms_bw[i] + pms_bw[i + 1]) / 2 + 50pms_px;
    if pms_abox[i] <> pms_abox[i + 1]: pms_v := pms_v + 20pms_px; fi
    pms_need(i, i + 1, pms_v);
  endfor
  for q = 0 upto pms_ne - 1:
    pms_i := pms_efrom[q]; pms_j := pms_eto[q]; pms_v := pms_gtw[q];
    if pms_ek[q] = 0:
      if pms_i <> pms_j: pms_need(pms_i, pms_j, pms_v + 30pms_px);
      elseif pms_i < pms_n - 1: pms_need(pms_i, pms_i + 1, max(pms_v, 30pms_px) + 25pms_px);
      fi
    elseif pms_ek[q] = 1:
      pms_v := pms_v + 20pms_px;
      if pms_eplace[q] = 1:
        if pms_i < pms_n - 1: pms_need(pms_i, pms_i + 1, pms_v + 20pms_px); fi
      elseif pms_eplace[q] = 0:
        if pms_i > 0: pms_need(pms_i - 1, pms_i, pms_v + 20pms_px); fi
      elseif pms_i = pms_j:
        if pms_i < pms_n - 1: pms_need(pms_i, pms_i + 1, pms_v / 2 + 10pms_px); fi
        if pms_i > 0: pms_need(pms_i - 1, pms_i, pms_v / 2 + 10pms_px); fi
      else: pms_need(pms_i, pms_j, pms_v - 50pms_px);
      fi
    fi
  endfor
  if pms_n > 0: pms_x[0] := 0; fi
  for j = 1 upto pms_n - 1:
    pms_v := pms_x[0] + pms_gap[0][j];
    for i = 1 upto j - 1: pms_v := max(pms_v, pms_x[i] + pms_gap[i][j]); endfor
    pms_x[j] := pms_v;
  endfor
enddef;
vardef pms_redge(expr i, k) =
  if k = 0: pms_x[i] else: pms_x[i] + 5pms_px + (k - 1) * 5pms_px fi
enddef;
vardef pms_ledge(expr i, k) =
  if k = 0: pms_x[i] else: pms_x[i] - 5pms_px + (k - 1) * 5pms_px fi
enddef;
def pms_startbar(expr i, yy) =
  pms_rxa[pms_nbar] := pms_x[i] - 5pms_px + pms_lev[i] * 5pms_px;
  pms_rxb[pms_nbar] := pms_rxa[pms_nbar] + 10pms_px;
  pms_rya[pms_nbar] := yy; pms_ryb[pms_nbar] := yy;
  pms_rbelow[pms_nbar] := pms_stack[i]; pms_stack[i] := pms_nbar;
  pms_lev[i] := pms_lev[i] + 1; pms_nbar := pms_nbar + 1;
enddef;
def pms_endbar(expr i, yy) =
  if pms_stack[i] >= 0:
    pms_ryb[pms_stack[i]] := max(yy, pms_rya[pms_stack[i]]);
    pms_stack[i] := pms_rbelow[pms_stack[i]]; pms_lev[i] := pms_lev[i] - 1;
  fi
enddef;
def pms_holds(expr lo, hi) =
  if pms_open >= 0:
    if pms_fhas[pms_open] = 0:
      pms_flo[pms_open] := lo; pms_fhi[pms_open] := hi; pms_fhas[pms_open] := 1;
    else:
      pms_flo[pms_open] := min(pms_flo[pms_open], lo);
      pms_fhi[pms_open] := max(pms_fhi[pms_open], hi);
    fi
  fi
enddef;
def pms_lmsg(expr q) =
  pms_i := pms_efrom[q]; pms_j := pms_eto[q];
  pms_y := pms_y + 20pms_px;
  pms_liney := pms_y + pms_gth[q];
  if pms_gth[q] > 0: pms_liney := pms_liney + 6pms_px; fi
  pms_gty[q] := pms_liney - 6pms_px - pms_gth[q] / 2;
  if pms_i = pms_j:
    pms_gself[q] := 1;
    pms_ga[q] := pms_redge(pms_i, pms_lev[pms_i]); pms_gb[q] := pms_liney;
    pms_gc[q] := pms_ga[q] + 30pms_px; pms_gd[q] := pms_liney + 20pms_px;
    pms_k := pms_lev[pms_i] + pms_eact[q];
    pms_ge[q] := pms_redge(pms_i, pms_k);
    pms_gtx[q] := pms_ga[q] + 5pms_px + pms_gtw[q] / 2;
    pms_holds(min(pms_ga[q], pms_gtx[q] - pms_gtw[q] / 2),
      max(pms_gc[q], pms_gtx[q] + pms_gtw[q] / 2));
    pms_y := pms_gd[q];
  else:
    if pms_acre[pms_j] = q: pms_liney := max(pms_liney, pms_y + pms_h / 2); fi
    pms_gb[q] := pms_liney; pms_gd[q] := pms_liney;
    pms_k := pms_lev[pms_j] + pms_eact[q];
    if pms_x[pms_i] < pms_x[pms_j]:
      pms_ga[q] := pms_redge(pms_i, pms_lev[pms_i]); pms_gc[q] := pms_ledge(pms_j, pms_k);
      if pms_acre[pms_j] = q: pms_gc[q] := pms_x[pms_j] - pms_w[pms_j] / 2; fi
    else:
      pms_ga[q] := pms_ledge(pms_i, pms_lev[pms_i]); pms_gc[q] := pms_redge(pms_j, pms_k);
      if pms_acre[pms_j] = q: pms_gc[q] := pms_x[pms_j] + pms_w[pms_j] / 2; fi
    fi
    pms_ge[q] := pms_gc[q];
    pms_gtx[q] := (pms_ga[q] + pms_gc[q]) / 2;
    pms_holds(min(pms_ga[q], pms_gc[q], pms_gtx[q] - pms_gtw[q] / 2),
      max(pms_ga[q], pms_gc[q], pms_gtx[q] + pms_gtw[q] / 2));
    pms_y := pms_liney;
    if pms_acre[pms_j] = q:
      pms_top[pms_j] := pms_liney - pms_h / 2; pms_y := pms_liney + pms_h / 2;
    fi
  fi
  if pms_ades[pms_j] = q: pms_lifeb[pms_j] := pms_liney; fi
  if pms_ades[pms_i] = q: pms_lifeb[pms_i] := pms_liney; fi
  pms_lastline := pms_liney;
enddef;
def pms_lnote(expr q) =
  pms_i := pms_efrom[q]; pms_j := pms_eto[q];
  pms_v := pms_gtw[q] + 20pms_px; pms_hh := pms_gth[q] + 20pms_px;
  pms_y := pms_y + 10pms_px;
  if pms_eplace[q] = 1:
    pms_ga[q] := pms_redge(pms_i, pms_lev[pms_i]) + 10pms_px; pms_gc[q] := pms_ga[q] + pms_v;
  elseif pms_eplace[q] = 0:
    pms_gc[q] := pms_ledge(pms_i, pms_lev[pms_i]) - 10pms_px; pms_ga[q] := pms_gc[q] - pms_v;
  elseif pms_i = pms_j:
    pms_ga[q] := pms_x[pms_i] - pms_v / 2; pms_gc[q] := pms_ga[q] + pms_v;
  else:
    pms_ga[q] := min(pms_x[pms_i], pms_x[pms_j]) - 25pms_px;
    pms_gc[q] := max(pms_x[pms_i], pms_x[pms_j]) + 25pms_px;
    if pms_gc[q] - pms_ga[q] < pms_v:
      pms_ga[q] := (pms_ga[q] + pms_gc[q] - pms_v) / 2; pms_gc[q] := pms_ga[q] + pms_v;
    fi
  fi
  pms_gb[q] := pms_y; pms_gd[q] := pms_y + pms_hh;
  pms_gtx[q] := (pms_ga[q] + pms_gc[q]) / 2; pms_gty[q] := pms_y + pms_hh / 2;
  pms_ge[q] := pms_gc[q];
  pms_holds(pms_ga[q], pms_gc[q]);
  pms_y := pms_gd[q]; pms_lastline := pms_y;
enddef;
def pms_lstart(expr q) =
  pms_y := pms_y + 10pms_px;
  pms_fr[pms_nf] := q; pms_nf := pms_nf + 1;
  pms_fya[q] := pms_y; pms_fns[q] := 0; pms_fhas[q] := 0; pms_fpar[q] := pms_open;
  pms_hh := 0; pms_flw[q] := 0; pms_flh[q] := 0; pms_ftw[q] := 0;
  if pms_eblock[q] <> 7:
    pms_flpic[q] := pms_text("{\bf " & pms_kname[pms_eblock[q]] & "}");
    pms_flw[q] := max(50pms_px, pms_picw(pms_flpic[q]) + 20pms_px);
    pms_flh[q] := max(20pms_px, pms_pich(pms_flpic[q]) + 4pms_px);
    pms_hh := pms_flh[q];
    if pms_etext[q] <> "":
      pms_ftpic[q] := pms_text("[" & pms_etext[q] & "]");
      pms_ftw[q] := pms_picw(pms_ftpic[q]); pms_hh := max(pms_hh, pms_pich(pms_ftpic[q]));
    fi
  fi
  pms_fty[q] := pms_y + pms_hh / 2;
  pms_y := pms_y + pms_hh; pms_open := q; pms_lastline := pms_y;
enddef;
def pms_lelse(expr q) =
  if pms_open >= 0:
    pms_f := pms_open; pms_k := pms_fns[pms_f];
    pms_y := pms_y + 10pms_px;
    pms_sy[pms_f][pms_k] := pms_y; pms_stw[pms_f][pms_k] := 0; pms_hh := 0;
    if pms_etext[q] <> "":
      pms_spic[pms_f][pms_k] := pms_text("[" & pms_etext[q] & "]");
      pms_stw[pms_f][pms_k] := pms_picw(pms_spic[pms_f][pms_k]);
      pms_hh := pms_pich(pms_spic[pms_f][pms_k]);
    fi
    pms_sty[pms_f][pms_k] := pms_y + 3pms_px + pms_hh / 2;
    if pms_hh > 0: pms_y := pms_y + 3pms_px + pms_hh; fi
    pms_fns[pms_f] := pms_k + 1; pms_lastline := pms_y;
  fi
enddef;
def pms_lstop =
  if pms_open >= 0:
    pms_f := pms_open;
    pms_y := pms_y + 10pms_px; pms_fyb[pms_f] := pms_y;
    if pms_fhas[pms_f] = 0:
      pms_flo[pms_f] := if pms_n > 0: pms_x[0] else: 0 fi; pms_fhi[pms_f] := pms_flo[pms_f];
    fi
    pms_fxa[pms_f] := pms_flo[pms_f] - 10pms_px; pms_fxb[pms_f] := pms_fhi[pms_f] + 10pms_px;
    pms_v := pms_ftw[pms_f] + 2 * pms_flw[pms_f] + 20pms_px;
    for k = 0 upto pms_fns[pms_f] - 1: pms_v := max(pms_v, pms_stw[pms_f][k] + 20pms_px); endfor
    if pms_fxb[pms_f] - pms_fxa[pms_f] < pms_v:
      pms_hh := (pms_fxa[pms_f] + pms_fxb[pms_f]) / 2;
      pms_fxa[pms_f] := pms_hh - pms_v / 2; pms_fxb[pms_f] := pms_hh + pms_v / 2;
    fi
    pms_ftx[pms_f] := (pms_fxa[pms_f] + pms_fxb[pms_f]) / 2;
    pms_open := pms_fpar[pms_f];
    pms_holds(pms_fxa[pms_f], pms_fxb[pms_f]);
    pms_lastline := pms_y;
  fi
enddef;
vardef pms_icon(expr t) = (t >= 1) and (t <= 4) enddef;
def pms_layout =
  pms_em := pms_picw(textext("\hbox to 1em{}")); pms_px := pms_em / 16;
  pms_h := 65pms_px;
  for i = 0 upto pms_n - 1:
    pms_stack[i] := -1; pms_lev[i] := 0;
    pms_measure(pms_apic[i], pms_tw[i], pms_th[i])(pms_alab[i]);
    pms_w[i] := max(150pms_px, pms_tw[i] + 20pms_px);
    if pms_icon(pms_atype[i]): pms_hh := 55pms_px + pms_th[i];
    else: pms_hh := pms_th[i] + 20pms_px; fi
    pms_h := max(pms_h, pms_hh);
  endfor
  for k = 0 upto pms_nb - 1: pms_measure(pms_bpic[k], pms_btw[k], pms_bth[k])(pms_btitle[k]); endfor
  for q = 0 upto pms_ne - 1:
    pms_ga[q] := 0; pms_gb[q] := 0; pms_gc[q] := 0; pms_gd[q] := 0; pms_ge[q] := 0;
    pms_gtx[q] := 0; pms_gty[q] := 0; pms_gself[q] := 0;
    if pms_ek[q] <= 1: pms_measure(pms_epic[q], pms_gtw[q], pms_gth[q])(pms_etext[q]);
    else: pms_gtw[q] := 0; pms_gth[q] := 0; fi
  endfor
  pms_columns;
  pms_bandh := 0;
  for k = 0 upto pms_nb - 1:
    if pms_btitle[k] <> "": pms_bandh := max(pms_bandh, pms_bth[k] + 5pms_px); fi
  endfor
  pms_v := if pms_nb > 0: 10pms_px + pms_bandh else: 0 fi;
  for i = 0 upto pms_n - 1: pms_top[i] := pms_v; endfor
  pms_y := pms_v + pms_h; pms_lastline := pms_y;
  pms_open := -1; pms_nf := 0; pms_nbar := 0;
  for q = 0 upto pms_ne - 1:
    if pms_ek[q] = 0: pms_lmsg(q);
    elseif pms_ek[q] = 1: pms_lnote(q);
    elseif pms_ek[q] = 2: pms_lstart(q);
    elseif pms_ek[q] = 3: pms_lelse(q);
    elseif pms_ek[q] = 4: pms_lstop;
    elseif pms_ek[q] = 5: pms_startbar(pms_efrom[q], pms_lastline);
    else: pms_endbar(pms_efrom[q], pms_lastline);
    fi
  endfor
  forever: exitif pms_open < 0; pms_lstop; endfor
  for i = 0 upto pms_n - 1:
    forever: exitif pms_stack[i] < 0; pms_endbar(i, pms_y); endfor
  endfor
  pms_y := pms_y + 20pms_px;
  pms_bottom := pms_y;
  for i = 0 upto pms_n - 1:
    if pms_icon(pms_atype[i]):
      pms_ly[i] := pms_top[i] + 45pms_px + pms_th[i] / 2; pms_lifea[i] := pms_ly[i] + pms_th[i] / 2;
    else:
      pms_ly[i] := pms_top[i] + pms_h / 2; pms_lifea[i] := pms_top[i] + pms_h;
    fi
    pms_footer[i] := if (pms_ades[i] < 0) and (pms_mirror = 1): 1 else: 0 fi;
    if pms_ades[i] < 0: pms_lifeb[i] := pms_y; fi
    pms_foot[i] := pms_y;
    if pms_footer[i] = 1: pms_bottom := pms_y + pms_h; fi
  endfor
  for k = 0 upto pms_nb - 1:
    pms_bxa[k] := 0; pms_bxb[k] := 0; pms_v := 0;
    for i = 0 upto pms_n - 1:
      if pms_abox[i] = k:
        if pms_v = 0:
          pms_bxa[k] := pms_x[i] - pms_w[i] / 2; pms_bxb[k] := pms_x[i] + pms_w[i] / 2; pms_v := 1;
        else:
          pms_bxa[k] := min(pms_bxa[k], pms_x[i] - pms_w[i] / 2);
          pms_bxb[k] := max(pms_bxb[k], pms_x[i] + pms_w[i] / 2);
        fi
      fi
    endfor
    pms_bxa[k] := pms_bxa[k] - 10pms_px; pms_bxb[k] := pms_bxb[k] + 10pms_px;
    if pms_btitle[k] <> "":
      if pms_bxb[k] - pms_bxa[k] < pms_btw[k] + 20pms_px:
        pms_v := (pms_bxa[k] + pms_bxb[k]) / 2;
        pms_bxa[k] := pms_v - pms_btw[k] / 2 - 10pms_px; pms_bxb[k] := pms_v + pms_btw[k] / 2 + 10pms_px;
      fi
    fi
    pms_bya[k] := 0; pms_byb[k] := pms_bottom + 10pms_px;
    pms_btx[k] := (pms_bxa[k] + pms_bxb[k]) / 2; pms_bty[k] := (10pms_px + pms_bandh) / 2;
  endfor
enddef;
vardef pms_col(expr c) = if c >= 0: pms_c[c] else: black fi enddef;
def pms_paint(expr p, f, l, w, d) =
  if (f >= 0) and (cycle p): fill p withcolor pms_c[f]; fi
  if l >= 0:
    if d > 0:
      draw p withpen pencircle scaled (w * pms_px) withcolor pms_c[l]
        dashed dashpattern(on (d * pms_px) off (d * pms_px));
    else:
      draw p withpen pencircle scaled (w * pms_px) withcolor pms_c[l];
    fi
  fi
enddef;
vardef pms_rect(expr xa, ya, xb, yb) =
  pms_up(xa, ya) -- pms_up(xb, ya) -- pms_up(xb, yb) -- pms_up(xa, yb) -- cycle
enddef;
vardef pms_line(expr xa, ya, xb, yb) = pms_up(xa, ya) -- pms_up(xb, yb) enddef;
vardef pms_circle(expr cx, cy, r) = fullcircle scaled (2r) shifted pms_up(cx, cy) enddef;
vardef pms_rrect(expr xa, ya, xb, yb, r) =
  save k; k := r * 0.5523;
  (pms_up(xa + r, yb) -- pms_up(xb - r, yb) .. controls pms_up(xb - r + k, yb) and pms_up(xb, yb - r + k)
   .. pms_up(xb, yb - r) -- pms_up(xb, ya + r) .. controls pms_up(xb, ya + r - k) and pms_up(xb - r + k, ya)
   .. pms_up(xb - r, ya) -- pms_up(xa + r, ya) .. controls pms_up(xa + r - k, ya) and pms_up(xa, ya + r - k)
   .. pms_up(xa, ya + r) -- pms_up(xa, yb - r) .. controls pms_up(xa, yb - r + k) and pms_up(xa + r - k, yb)
   .. cycle)
enddef;
def pms_put(expr p, cx, cy, c) =
  draw p shifted (pms_up(cx, cy) - (llcorner p + urcorner p) / 2) withcolor pms_col(c);
enddef;
def pms_fig(expr p) = pms_paint(p, pms_cafill, pms_caline, 1.5, 0); enddef;
def pms_participant(expr i, yy) =
  begingroup save cx, ww, hh, xa, xb, r, cy, rx, ry, t, pa, pb; path pa, pb;
  cx := pms_x[i]; ww := pms_w[i]; hh := pms_h; xa := cx - ww / 2; xb := cx + ww / 2;
  t := pms_atype[i];
  if t = 1:
    r := 7pms_px; cy := yy + r;
    pms_fig(pms_circle(cx, cy, r));
    pms_fig(pms_line(cx, cy + r, cx, yy + 28pms_px));
    pms_fig(pms_line(cx - 12pms_px, yy + 19pms_px, cx + 12pms_px, yy + 19pms_px));
    pms_fig(pms_line(cx, yy + 28pms_px, cx - 10pms_px, yy + 40pms_px));
    pms_fig(pms_line(cx, yy + 28pms_px, cx + 10pms_px, yy + 40pms_px));
  elseif t = 2:
    r := 14pms_px; cy := yy + 20pms_px;
    pms_fig(pms_line(cx - 22pms_px, cy - r, cx - 22pms_px, cy + r));
    pms_fig(pms_line(cx - 22pms_px, cy, cx + 4pms_px - r, cy));
    pms_fig(pms_circle(cx + 4pms_px, cy, r));
  elseif t = 3:
    r := 14pms_px; cy := yy + 23pms_px;
    pms_fig(pms_circle(cx, cy, r));
    pms_fig(pms_line(cx + 2pms_px, cy - r, cx + 8pms_px, cy - r - 5pms_px));
    pms_fig(pms_line(cx + 2pms_px, cy - r, cx + 8pms_px, cy - r + 5pms_px));
  elseif t = 4:
    r := 14pms_px; cy := yy + r + 4pms_px;
    pms_fig(pms_circle(cx, cy, r));
    pms_fig(pms_line(cx - r, cy + r + 4pms_px, cx + r, cy + r + 4pms_px));
  elseif t = 5:
    ry := min(8pms_px, hh / 6);
    pa := fullcircle xscaled ww yscaled (2ry) shifted pms_up(cx, yy + ry);
    pb := fullcircle xscaled ww yscaled (2ry) shifted pms_up(cx, yy + hh - ry);
    pms_paint(subpath (0, 4) of pa -- subpath (4, 8) of pb -- cycle, pms_cafill, pms_caline, 1, 0);
    pms_paint(subpath (4, 8) of pa, -1, pms_caline, 1, 0);
  elseif t = 7:
    rx := min(8pms_px, ww / 8);
    pa := fullcircle xscaled (2rx) yscaled hh shifted pms_up(xb - rx, yy + hh / 2);
    pb := fullcircle xscaled (2rx) yscaled hh shifted pms_up(xa + rx, yy + hh / 2);
    pms_paint((subpath (6, 8) of pa & subpath (0, 2) of pa) -- subpath (2, 6) of pb -- cycle,
      pms_cafill, pms_caline, 1, 0);
    pms_paint(subpath (2, 6) of pa, -1, pms_caline, 1, 0);
  elseif t = 6:
    pms_paint(pms_rect(xa + 6pms_px, yy, xb, yy + hh - 6pms_px), pms_cafill, pms_caline, 1, 0);
    pms_paint(pms_rect(xa, yy + 6pms_px, xb - 6pms_px, yy + hh), pms_cafill, pms_caline, 1, 0);
  else:
    pms_paint(pms_rrect(xa, yy, xb, yy + hh, 3pms_px), pms_cafill, pms_caline, 1, 0);
  fi
  pms_put(pms_apic[i], cx, yy + pms_ly[i] - pms_top[i], pms_catext);
  endgroup
enddef;
vardef pms_hp(expr al, sd) =
  pms_up(pms_hx - pms_hux * al * pms_px + pms_huy * sd * pms_px,
    pms_hy - pms_huy * al * pms_px - pms_hux * sd * pms_px)
enddef;
def pms_head(expr k, hx, hy, ux, uy) =
  pms_hx := hx; pms_hy := hy; pms_hux := ux; pms_huy := uy;
  if k = 1:
    pms_paint(pms_hp(0, 0) -- pms_hp(10, 5) -- pms_hp(10, -5) -- cycle, pms_csig, -1, 0, 0);
  elseif k = 2:
    pms_paint(pms_hp(0, 0) -- pms_hp(10, 6) -- pms_hp(5, 0) -- pms_hp(10, -6) -- cycle,
      pms_csig, -1, 0, 0);
  elseif k = 4:
    pms_paint(pms_hp(0, 0) -- pms_hp(10, 8) -- pms_hp(10, 0) -- cycle, pms_csig, -1, 0, 0);
  elseif k = 5:
    pms_paint(pms_hp(0, 0) -- pms_hp(10, -8) -- pms_hp(10, 0) -- cycle, pms_csig, -1, 0, 0);
  elseif k = 6:
    pms_paint(pms_hp(0, 0) -- pms_hp(7, 7), -1, pms_csig, 1.5, 0);
  elseif k = 7:
    pms_paint(pms_hp(0, 0) -- pms_hp(7, -7), -1, pms_csig, 1.5, 0);
  elseif k = 3:
    pms_paint(pms_hp(8, 4) -- pms_hp(0, -4), -1, pms_csig, 1.5, 0);
    pms_paint(pms_hp(8, -4) -- pms_hp(0, 4), -1, pms_csig, 1.5, 0);
  fi
enddef;
vardef pms_sign(expr v) = if v < 0: -1 elseif v > 0: 1 else: 0 fi enddef;
def pms_drawmsg(expr q) =
  begingroup save d, ux, uy, ex, ey, p; picture p;
  d := 3 * pms_edot[q];
  if pms_gself[q] = 1:
    pms_paint(pms_up(pms_ga[q], pms_gb[q]) -- pms_up(pms_gc[q], pms_gb[q])
      -- pms_up(pms_gc[q], pms_gd[q]) -- pms_up(pms_ge[q], pms_gd[q]), -1, pms_csig, 1.5, d);
    ex := pms_ge[q]; ey := pms_gd[q];
    pms_head(pms_ehead[q], ex, ey, -1, 0); pms_head(pms_etail[q], pms_ga[q], pms_gb[q], -1, 0);
  else:
    pms_paint(pms_line(pms_ga[q], pms_gb[q], pms_gc[q], pms_gd[q]), -1, pms_csig, 1.5, d);
    ex := pms_gc[q]; ey := pms_gd[q];
    ux := pms_sign(pms_gc[q] - pms_ga[q]); uy := 0;
    if ux = 0: uy := pms_sign(pms_gd[q] - pms_gb[q]); fi
    pms_head(pms_ehead[q], ex, ey, ux, uy); pms_head(pms_etail[q], pms_ga[q], pms_gb[q], -ux, -uy);
  fi
  if pms_ecto[q] = 1: pms_paint(pms_circle(ex, ey, 5pms_px), pms_csig, -1, 0, 0); fi
  if pms_ecfrom[q] = 1: pms_paint(pms_circle(pms_ga[q], pms_gb[q], 5pms_px), pms_csig, -1, 0, 0); fi
  if pms_etext[q] <> "": pms_put(pms_epic[q], pms_gtx[q], pms_gty[q], pms_csigtext); fi
  if pms_enum[q] <> "":
    pms_paint(pms_circle(pms_ga[q], pms_gb[q], 9pms_px), pms_cnum, -1, 0, 0);
    p := textext(pms_enum[q]) scaled (12/16);
    pms_put(p, pms_ga[q], pms_gb[q], pms_cnumtext);
  fi
  endgroup
enddef;
def pms_drawnote(expr q) =
  pms_paint(pms_rect(pms_ga[q], pms_gb[q], pms_gc[q], pms_gd[q]), pms_cnfill, pms_cnline, 1, 0);
  pms_put(pms_epic[q], pms_gtx[q], pms_gty[q], pms_cntext);
enddef;
def pms_drawframe(expr f) =
  pms_paint(pms_rect(pms_fxa[f], pms_fya[f], pms_fxb[f], pms_fyb[f]), -1, pms_clline, 2, 2);
  pms_paint(pms_up(pms_fxa[f], pms_fya[f]) -- pms_up(pms_fxa[f] + pms_flw[f], pms_fya[f])
    -- pms_up(pms_fxa[f] + pms_flw[f], pms_fya[f] + pms_flh[f] - 7pms_px)
    -- pms_up(pms_fxa[f] + pms_flw[f] - 8.4pms_px, pms_fya[f] + pms_flh[f])
    -- pms_up(pms_fxa[f], pms_fya[f] + pms_flh[f]) -- cycle, pms_clfill, pms_clline, 1, 0);
  pms_put(pms_flpic[f], pms_fxa[f] + pms_flw[f] / 2, pms_fya[f] + pms_flh[f] / 2, pms_cltext);
  if pms_ftw[f] > 0: pms_put(pms_ftpic[f], pms_ftx[f], pms_fty[f], pms_clooptext); fi
  for k = 0 upto pms_fns[f] - 1:
    pms_paint(pms_line(pms_fxa[f], pms_sy[f][k], pms_fxb[f], pms_sy[f][k]), -1, pms_clline, 2, 2);
    if pms_stw[f][k] > 0:
      pms_put(pms_spic[f][k], pms_ftx[f], pms_sty[f][k], pms_clooptext);
    fi
  endfor
enddef;
def pms_drawing =
  image(
    for k = 0 upto pms_nb - 1:
      pms_paint(pms_rect(pms_bxa[k], pms_bya[k], pms_bxb[k], pms_byb[k]), pms_bfill[k], pms_cboxline, 1, 0);
      if pms_btitle[k] <> "": pms_put(pms_bpic[k], pms_btx[k], pms_bty[k], pms_catext); fi
    endfor
    for k = 0 upto pms_nf - 1:
      if pms_eblock[pms_fr[k]] = 7:
        pms_paint(pms_rect(pms_fxa[pms_fr[k]], pms_fya[pms_fr[k]], pms_fxb[pms_fr[k]], pms_fyb[pms_fr[k]]),
          pms_efill[pms_fr[k]], -1, 0, 0);
      fi
    endfor
    for i = 0 upto pms_n - 1:
      pms_paint(pms_line(pms_x[i], pms_lifea[i], pms_x[i], pms_lifeb[i]), -1, pms_clife, 0.5, 0);
    endfor
    for k = 0 upto pms_nbar - 1:
      pms_paint(pms_rect(pms_rxa[k], pms_rya[k], pms_rxb[k], pms_ryb[k]), pms_cbfill, pms_cbline, 1, 0);
    endfor
    for k = 0 upto pms_nf - 1:
      if pms_eblock[pms_fr[k]] <> 7: pms_drawframe(pms_fr[k]); fi
    endfor
    for q = 0 upto pms_ne - 1:
      if pms_ek[q] = 0: pms_drawmsg(q); elseif pms_ek[q] = 1: pms_drawnote(q); fi
    endfor
    for i = 0 upto pms_n - 1:
      pms_participant(i, pms_top[i]);
      if pms_footer[i] = 1: pms_participant(i, pms_foot[i]); fi
      if pms_ades[i] >= 0:
        pms_paint(pms_line(pms_x[i] - 9pms_px, pms_lifeb[i] - 9pms_px, pms_x[i] + 9pms_px,
          pms_lifeb[i] + 9pms_px), -1, pms_caline, 2, 0);
        pms_paint(pms_line(pms_x[i] - 9pms_px, pms_lifeb[i] + 9pms_px, pms_x[i] + 9pms_px,
          pms_lifeb[i] - 9pms_px), -1, pms_caline, 2, 0);
      fi
    endfor
  )
enddef;
def pms_drawtitle(suffix p) =
  begingroup save t; picture t;
  t := pms_text(pms_title) scaled (18/16);
  t := t shifted ((xpart llcorner p + xpart urcorner p) / 2
    - (xpart llcorner t + xpart urcorner t) / 2, ypart urcorner p + 25pms_px);
  p := image(draw p; draw t withcolor pms_col(pms_ctitle));
  endgroup
enddef;
def pms_end =
  begingroup save p; picture p;
  pms_layout;
  p := pms_drawing;
  if pms_title <> "": pms_drawtitle(p); fi
  if (pms_maxw > 0) and (pms_picw(p) > pms_maxw): p := p scaled (pms_maxw / pms_picw(p)); fi
  draw p;
  endgroup
enddef;
pms_begin(432, 2, 2, 0, 0);
pms_colour(0, 0.9255, 0.9255, 1);
pms_colour(1, 0.5765, 0.4392, 0.8588);
pms_colour(2, 0, 0, 0);
pms_colour(3, 0.2, 0.2, 0.2);
pms_colour(4, 1, 0.9608, 0.6784);
pms_colour(5, 0.6667, 0.6667, 0.2);
pms_colour(6, 0.9569, 0.9569, 0.9569);
pms_colour(7, 0.4, 0.4, 0.4);
pms_colour(8, 1, 1, 1);
pms_colour(9, 0.502, 0.502, 0.502);
pms_theme(0, 1, 2, 1, 3, 3, 0, 1, 2, 2, 4, 5, 2, 6, 7, 3, 8, 3, 9);
pms_actor(0, 0, -1, -1, -1, "Alice");
pms_actor(1, 0, -1, -1, -1, "John");
pms_msg(0, 0, 1, 0, 2, 0, 0, 0, 0, "", "Hello John,how are you?");
pms_msg(1, 1, 0, 0, 2, 0, 0, 0, 0, "", "Great!");
pms_title := "Aliases";
pms_end;
\stopMPcode
