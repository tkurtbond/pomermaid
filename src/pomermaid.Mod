MODULE pomermaid;
(* pomermaid: Mermaid diagrams drawn in pic, for groff, and MetaPost,
   for ConTeXt, and SVG made from the pic through groff. The command line is PmOptions'. See PLAN.md. *)

IMPORT PmIO, O := PmOptions, L := PmLex, PmFlow, PmState, PmClass, PmEr, PmReq, PmSeq, PmSeqDump, SL := PmSeqLayout, PmSeqPic, PmSeqMp, PmJourney, PmJourneyDump, JL := PmJourneyLayout, PmJourneyPic, PmJourneyMp, PmTimeline, PmTimelineDump, TL := PmTimelineLayout, PmTimelinePic, PmTimelineMp, PmGantt, PmGanttDump, GL := PmGanttLayout, PmGanttPic, PmGanttMp, PmPie, PmPieDump, PL := PmPieLayout, PmPiePic, PmPieMp, PmQuadrant, PmQuadrantDump, QL := PmQuadrantLayout, PmQuadrantPic, PmQuadrantMp, PmXy, PmXyDump, XL := PmXyLayout, PmXyPic, PmXyMp, PmRadar, PmRadarDump, RL := PmRadarLayout, PmRadarPic, PmRadarMp, PmSankey, PmSankeyDump, KL := PmSankeyLayout, PmSankeyPic, PmSankeyMp, PmGit, PmGitDump, HL := PmGitLayout, PmMindmap, PmMindmapDump, ML := PmMindmapLayout, PmTreemap, PmTreemapDump, TML := PmTreemapLayout, PmBlock, PmBlockDump, BL := PmBlockLayout, PmPacket, PmPacketDump, PKL := PmPacketLayout, PmKanban, PmKanbanDump, KBL := PmKanbanLayout, PmArch, PmArchDump, AL := PmArchLayout, PmC4, PmC4Dump, C4L := PmC4Layout, PmDrawDump, PmDrawPic, PmDrawMp, PmDump, M := PmMetrics, FL := PmFlowLayout, PmPic, PmMp, PmSvg;

VAR
  text: PmIO.Text;
  len: LONGINT;
  sc: L.Scanner;
  g: PmFlow.Graph;
  seq: PmSeq.Diagram;
  jour: PmJourney.Diagram;
  tim: PmTimeline.Diagram;
  gan: PmGantt.Diagram;
  pie: PmPie.Diagram;
  quad: PmQuadrant.Diagram;
  xy: PmXy.Diagram;
  radar: PmRadar.Diagram;
  sankey: PmSankey.Diagram;
  git: PmGit.Diagram;
  mm: PmMindmap.Diagram;
  tm: PmTreemap.Diagram;
  blk: PmBlock.Diagram;
  pkt: PmPacket.Diagram;
  kan: PmKanban.Diagram;
  arch: PmArch.Diagram;
  c4: PmC4.Diagram;
  c4lay: C4L.Layout;
  font: M.Font;
  lay: FL.Layout;
  slay: SL.Layout;
  jlay: JL.Layout;
  tlay: TL.Layout;
  glay: GL.Layout;
  play: PL.Layout;
  qlay: QL.Layout;
  xlay: XL.Layout;
  rlay: RL.Layout;
  klay: KL.Layout;
  hlay: HL.Layout;
  mlay: ML.Layout;
  tmlay: TML.Layout;
  blay: BL.Layout;
  pklay: PKL.Layout;
  kblay: KBL.Layout;
  alay: AL.Layout;

BEGIN
  O.Parse;
  IF ~O.done THEN
    IF (O.to # "pic") & (O.to # "mp") & (O.to # "svg") & (O.to # "svg-ms")
      & (O.to # "dump") & (O.to # "layout") THEN
      PmIO.Fail("", "unknown output format; use pic, mp or svg", PmIO.UnknownWriter)
    END;
    PmIO.ReadFile(O.input, text, len);
    sc := L.Open(text, len, O.input);
    IF PmState.IsState(sc) THEN PmState.Read(sc, g)
    ELSIF PmClass.IsClass(sc) THEN PmClass.Read(sc, g)
    ELSIF PmEr.IsEr(sc) THEN PmEr.Read(sc, g)
    ELSIF PmReq.IsReq(sc) THEN PmReq.Read(sc, g)
    ELSIF PmSeq.IsSeq(sc) THEN PmSeq.Read(sc, seq)
    ELSIF PmJourney.IsJourney(sc) THEN PmJourney.Read(sc, jour)
    ELSIF PmTimeline.IsTimeline(sc) THEN PmTimeline.Read(sc, tim)
    ELSIF PmGantt.IsGantt(sc) THEN PmGantt.Read(sc, gan)
    ELSIF PmPie.IsPie(sc) THEN PmPie.Read(sc, pie)
    ELSIF PmQuadrant.IsQuadrant(sc) THEN PmQuadrant.Read(sc, quad)
    ELSIF PmXy.IsXy(sc) THEN PmXy.Read(sc, xy)
    ELSIF PmRadar.IsRadar(sc) THEN PmRadar.Read(sc, radar)
    ELSIF PmSankey.IsSankey(sc) THEN PmSankey.Read(sc, sankey)
    ELSIF PmGit.IsGit(sc) THEN PmGit.Read(sc, git)
    ELSIF PmMindmap.IsMindmap(sc) THEN PmMindmap.Read(sc, mm)
    ELSIF PmTreemap.IsTreemap(sc) THEN PmTreemap.Read(sc, tm)
    ELSIF PmBlock.IsBlock(sc) THEN PmBlock.Read(sc, blk)
    ELSIF PmPacket.IsPacket(sc) THEN PmPacket.Read(sc, pkt)
    ELSIF PmKanban.IsKanban(sc) THEN PmKanban.Read(sc, kan)
    ELSIF PmArch.IsArch(sc) THEN PmArch.Read(sc, arch)
    ELSIF PmC4.IsC4(sc) THEN PmC4.Read(sc, c4)
    ELSIF PmFlow.IsFlowchart(sc) THEN PmFlow.Read(sc, g)
    ELSE sc.Error("not a diagram pomermaid knows; it reads flowchart, graph, stateDiagram, classDiagram, erDiagram, requirementDiagram, sequenceDiagram, journey, timeline, gantt, pie, quadrantChart, xychart, radar-beta, sankey-beta, gitGraph, mindmap, treemap, block, packet, kanban, architecture-beta, C4Context, C4Container, C4Component, C4Dynamic and C4Deployment")
    END;
    IF O.to # "dump" THEN
      IF O.fontPath # "" THEN M.SetPath(O.fontPath) END;
      IF ~M.Load(O.font, font) THEN
        PmIO.Fail("", "no such groff font in devpdf or devps; see --font and --font-path", PmIO.FontNotFound)
      END;
      M.LoadStyles(font)
    END;
    IF (c4 # NIL) & (O.to = "svg") THEN
      C4L.Fit(c4, font, O.size, O.width, c4lay);
      PmSvg.WriteDrawing(c4lay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF c4 # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmC4Dump.Write(c4)
      ELSIF O.to = "layout" THEN C4L.Fit(c4, font, O.size, O.width, c4lay); PmDrawDump.WriteLayout(c4lay)
      ELSIF O.to = "pic" THEN C4L.Fit(c4, font, O.size, O.width, c4lay); PmDrawPic.Write(c4lay, O.font)
      ELSIF O.to = "svg-ms" THEN C4L.Fit(c4, font, O.size, O.width, c4lay); PmSvg.WriteDrawingDocument(c4lay, O.font)
      ELSIF O.to = "mp" THEN C4L.Fit(c4, font, O.size, O.width, c4lay); PmDrawMp.Write(c4lay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (arch # NIL) & (O.to = "svg") THEN
      AL.Fit(arch, font, O.size, O.width, alay);
      PmSvg.WriteDrawing(alay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF arch # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmArchDump.Write(arch)
      ELSIF O.to = "layout" THEN AL.Fit(arch, font, O.size, O.width, alay); PmDrawDump.WriteLayout(alay)
      ELSIF O.to = "pic" THEN AL.Fit(arch, font, O.size, O.width, alay); PmDrawPic.Write(alay, O.font)
      ELSIF O.to = "svg-ms" THEN AL.Fit(arch, font, O.size, O.width, alay); PmSvg.WriteDrawingDocument(alay, O.font)
      ELSIF O.to = "mp" THEN AL.Fit(arch, font, O.size, O.width, alay); PmDrawMp.Write(alay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (kan # NIL) & (O.to = "svg") THEN
      KBL.Fit(kan, font, O.size, O.width, kblay);
      PmSvg.WriteDrawing(kblay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF kan # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmKanbanDump.Write(kan)
      ELSIF O.to = "layout" THEN KBL.Fit(kan, font, O.size, O.width, kblay); PmDrawDump.WriteLayout(kblay)
      ELSIF O.to = "pic" THEN KBL.Fit(kan, font, O.size, O.width, kblay); PmDrawPic.Write(kblay, O.font)
      ELSIF O.to = "svg-ms" THEN KBL.Fit(kan, font, O.size, O.width, kblay); PmSvg.WriteDrawingDocument(kblay, O.font)
      ELSIF O.to = "mp" THEN KBL.Fit(kan, font, O.size, O.width, kblay); PmDrawMp.Write(kblay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (pkt # NIL) & (O.to = "svg") THEN
      PKL.Fit(pkt, font, O.size, O.width, pklay);
      PmSvg.WriteDrawing(pklay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF pkt # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmPacketDump.Write(pkt)
      ELSIF O.to = "layout" THEN PKL.Fit(pkt, font, O.size, O.width, pklay); PmDrawDump.WriteLayout(pklay)
      ELSIF O.to = "pic" THEN PKL.Fit(pkt, font, O.size, O.width, pklay); PmDrawPic.Write(pklay, O.font)
      ELSIF O.to = "svg-ms" THEN PKL.Fit(pkt, font, O.size, O.width, pklay); PmSvg.WriteDrawingDocument(pklay, O.font)
      ELSIF O.to = "mp" THEN PKL.Fit(pkt, font, O.size, O.width, pklay); PmDrawMp.Write(pklay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (blk # NIL) & (O.to = "svg") THEN
      BL.Fit(blk, font, O.size, O.width, blay);
      PmSvg.WriteDrawing(blay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF blk # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmBlockDump.Write(blk)
      ELSIF O.to = "layout" THEN BL.Fit(blk, font, O.size, O.width, blay); PmDrawDump.WriteLayout(blay)
      ELSIF O.to = "pic" THEN BL.Fit(blk, font, O.size, O.width, blay); PmDrawPic.Write(blay, O.font)
      ELSIF O.to = "svg-ms" THEN BL.Fit(blk, font, O.size, O.width, blay); PmSvg.WriteDrawingDocument(blay, O.font)
      ELSIF O.to = "mp" THEN BL.Fit(blk, font, O.size, O.width, blay); PmDrawMp.Write(blay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (tm # NIL) & (O.to = "svg") THEN
      TML.Fit(tm, font, O.size, O.width, tmlay);
      PmSvg.WriteDrawing(tmlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF tm # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmTreemapDump.Write(tm)
      ELSIF O.to = "layout" THEN TML.Fit(tm, font, O.size, O.width, tmlay); PmDrawDump.WriteLayout(tmlay)
      ELSIF O.to = "pic" THEN TML.Fit(tm, font, O.size, O.width, tmlay); PmDrawPic.Write(tmlay, O.font)
      ELSIF O.to = "svg-ms" THEN TML.Fit(tm, font, O.size, O.width, tmlay); PmSvg.WriteDrawingDocument(tmlay, O.font)
      ELSIF O.to = "mp" THEN TML.Fit(tm, font, O.size, O.width, tmlay); PmDrawMp.Write(tmlay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (mm # NIL) & (O.to = "svg") THEN
      ML.Fit(mm, font, O.size, O.width, mlay);
      PmSvg.WriteDrawing(mlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF mm # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmMindmapDump.Write(mm)
      ELSIF O.to = "layout" THEN ML.Fit(mm, font, O.size, O.width, mlay); PmDrawDump.WriteLayout(mlay)
      ELSIF O.to = "pic" THEN ML.Fit(mm, font, O.size, O.width, mlay); PmDrawPic.Write(mlay, O.font)
      ELSIF O.to = "svg-ms" THEN ML.Fit(mm, font, O.size, O.width, mlay); PmSvg.WriteDrawingDocument(mlay, O.font)
      ELSIF O.to = "mp" THEN ML.Fit(mm, font, O.size, O.width, mlay); PmDrawMp.Write(mlay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (git # NIL) & (O.to = "svg") THEN
      HL.Fit(git, font, O.size, O.width, hlay);
      PmSvg.WriteDrawing(hlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF git # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmGitDump.Write(git)
      ELSIF O.to = "layout" THEN HL.Fit(git, font, O.size, O.width, hlay); PmDrawDump.WriteLayout(hlay)
      ELSIF O.to = "pic" THEN HL.Fit(git, font, O.size, O.width, hlay); PmDrawPic.Write(hlay, O.font)
      ELSIF O.to = "svg-ms" THEN HL.Fit(git, font, O.size, O.width, hlay); PmSvg.WriteDrawingDocument(hlay, O.font)
      ELSIF O.to = "mp" THEN HL.Fit(git, font, O.size, O.width, hlay); PmDrawMp.Write(hlay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (sankey # NIL) & (O.to = "svg") THEN
      KL.Fit(sankey, font, O.size, O.width, klay);
      PmSvg.WriteSankey(klay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF sankey # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmSankeyDump.Write(sankey)
      ELSIF O.to = "layout" THEN KL.Fit(sankey, font, O.size, O.width, klay); PmSankeyDump.WriteLayout(klay)
      ELSIF O.to = "pic" THEN KL.Fit(sankey, font, O.size, O.width, klay); PmSankeyPic.Write(klay, O.font)
      ELSIF O.to = "svg-ms" THEN KL.Fit(sankey, font, O.size, O.width, klay); PmSvg.WriteSankeyDocument(klay, O.font)
      ELSIF O.to = "mp" THEN KL.Fit(sankey, font, O.size, O.width, klay); PmSankeyMp.Write(klay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (radar # NIL) & (O.to = "svg") THEN
      RL.Fit(radar, font, O.size, O.width, rlay);
      PmSvg.WriteRadar(rlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF radar # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmRadarDump.Write(radar)
      ELSIF O.to = "layout" THEN RL.Fit(radar, font, O.size, O.width, rlay); PmRadarDump.WriteLayout(rlay)
      ELSIF O.to = "pic" THEN RL.Fit(radar, font, O.size, O.width, rlay); PmRadarPic.Write(rlay, O.font)
      ELSIF O.to = "svg-ms" THEN RL.Fit(radar, font, O.size, O.width, rlay); PmSvg.WriteRadarDocument(rlay, O.font)
      ELSIF O.to = "mp" THEN RL.Fit(radar, font, O.size, O.width, rlay); PmRadarMp.Write(rlay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (xy # NIL) & (O.to = "svg") THEN
      XL.Fit(xy, font, O.size, O.width, xlay);
      PmSvg.WriteXy(xlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF xy # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmXyDump.Write(xy)
      ELSIF O.to = "layout" THEN XL.Fit(xy, font, O.size, O.width, xlay); PmXyDump.WriteLayout(xlay)
      ELSIF O.to = "pic" THEN XL.Fit(xy, font, O.size, O.width, xlay); PmXyPic.Write(xlay, O.font)
      ELSIF O.to = "svg-ms" THEN XL.Fit(xy, font, O.size, O.width, xlay); PmSvg.WriteXyDocument(xlay, O.font)
      ELSIF O.to = "mp" THEN XL.Fit(xy, font, O.size, O.width, xlay); PmXyMp.Write(xlay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (quad # NIL) & (O.to = "svg") THEN
      QL.Fit(quad, font, O.size, O.width, qlay);
      PmSvg.WriteQuadrant(qlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF quad # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmQuadrantDump.Write(quad)
      ELSIF O.to = "layout" THEN QL.Fit(quad, font, O.size, O.width, qlay); PmQuadrantDump.WriteLayout(qlay)
      ELSIF O.to = "pic" THEN QL.Fit(quad, font, O.size, O.width, qlay); PmQuadrantPic.Write(qlay, O.font)
      ELSIF O.to = "svg-ms" THEN QL.Fit(quad, font, O.size, O.width, qlay); PmSvg.WriteQuadrantDocument(qlay, O.font)
      ELSIF O.to = "mp" THEN QL.Fit(quad, font, O.size, O.width, qlay); PmQuadrantMp.Write(qlay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (pie # NIL) & (O.to = "svg") THEN
      PL.Fit(pie, font, O.size, O.width, play);
      PmSvg.WritePie(play, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF pie # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmPieDump.Write(pie)
      ELSIF O.to = "layout" THEN PL.Fit(pie, font, O.size, O.width, play); PmPieDump.WriteLayout(play)
      ELSIF O.to = "pic" THEN PL.Fit(pie, font, O.size, O.width, play); PmPiePic.Write(play, O.font)
      ELSIF O.to = "svg-ms" THEN PL.Fit(pie, font, O.size, O.width, play); PmSvg.WritePieDocument(play, O.font)
      ELSIF O.to = "mp" THEN PL.Fit(pie, font, O.size, O.width, play); PmPieMp.Write(play)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (gan # NIL) & (O.to = "svg") THEN
      GL.Make(gan, font, O.size, O.width, glay);
      PmSvg.WriteGantt(glay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF gan # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmGanttDump.Write(gan)
      ELSIF O.to = "layout" THEN GL.Make(gan, font, O.size, O.width, glay); PmGanttDump.WriteLayout(glay)
      ELSIF O.to = "pic" THEN GL.Make(gan, font, O.size, O.width, glay); PmGanttPic.Write(glay, O.font)
      ELSIF O.to = "svg-ms" THEN GL.Make(gan, font, O.size, O.width, glay); PmSvg.WriteGanttDocument(glay, O.font)
      ELSIF O.to = "mp" THEN GL.Make(gan, font, O.size, O.width, glay); PmGanttMp.Write(glay)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (tim # NIL) & (O.to = "svg") THEN
      TL.Fit(tim, font, O.size, O.width, tlay);
      PmSvg.WriteTimeline(tlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF tim # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmTimelineDump.Write(tim)
      ELSIF O.to = "layout" THEN TL.Fit(tim, font, O.size, O.width, tlay); PmTimelineDump.WriteLayout(tlay)
      ELSIF O.to = "pic" THEN TL.Fit(tim, font, O.size, O.width, tlay); PmTimelinePic.Write(tlay, O.font)
      ELSIF O.to = "svg-ms" THEN TL.Fit(tim, font, O.size, O.width, tlay); PmSvg.WriteTimelineDocument(tlay, O.font)
      ELSIF O.to = "mp" THEN TL.Make(tim, font, O.size, tlay); PmTimelineMp.Write(tlay, O.width)
      END
    ELSIF (jour # NIL) & (O.to = "svg") THEN
      JL.Fit(jour, font, O.size, O.width, jlay);
      PmSvg.WriteJourney(jlay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF jour # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmJourneyDump.Write(jour)
      ELSIF O.to = "layout" THEN JL.Fit(jour, font, O.size, O.width, jlay); PmJourneyDump.WriteLayout(jlay)
      ELSIF O.to = "pic" THEN JL.Fit(jour, font, O.size, O.width, jlay); PmJourneyPic.Write(jlay, O.font)
      ELSIF O.to = "svg-ms" THEN JL.Fit(jour, font, O.size, O.width, jlay); PmSvg.WriteJourneyDocument(jlay, O.font)
      ELSIF O.to = "mp" THEN PmJourneyMp.Write(jour, O.size, O.width)
      ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
      END
    ELSIF (seq # NIL) & (O.to = "svg") THEN
      SL.Fit(seq, font, O.size, O.width, slay);
      PmSvg.WriteSeq(slay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSIF seq # NIL THEN
      PmIO.OpenOutput(O.output);
      IF O.to = "dump" THEN PmSeqDump.Write(seq)
      ELSIF O.to = "layout" THEN SL.Fit(seq, font, O.size, O.width, slay); PmSeqDump.WriteLayout(slay)
      ELSIF O.to = "pic" THEN SL.Fit(seq, font, O.size, O.width, slay); PmSeqPic.Write(slay, O.font)
      ELSIF O.to = "svg-ms" THEN SL.Fit(seq, font, O.size, O.width, slay); PmSvg.WriteSeqDocument(slay, O.font)
      ELSIF O.to = "mp" THEN PmSeqMp.Write(seq, O.size, O.width, O.mpInput)
      END
    ELSIF O.to = "svg" THEN
      (* PmSvg opens the output once the SVG is made *)
      FL.Fit(g, font, O.size, O.width, lay);
      PmSvg.Write(lay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSE PmIO.OpenOutput(O.output)
    END;
    IF (seq # NIL) OR (jour # NIL) OR (tim # NIL) OR (gan # NIL) OR (pie # NIL) OR (quad # NIL) OR (xy # NIL) OR (radar # NIL) OR (sankey # NIL) OR (git # NIL) OR (mm # NIL) OR (tm # NIL) OR (blk # NIL) OR (pkt # NIL) OR (kan # NIL) OR (arch # NIL) OR (c4 # NIL) OR (O.to = "svg") THEN
    ELSIF O.to = "svg-ms" THEN FL.Fit(g, font, O.size, O.width, lay); PmSvg.WriteDocument(lay, O.font)
    ELSIF O.to = "dump" THEN PmDump.Write(g)
    ELSIF O.to = "layout" THEN FL.Fit(g, font, O.size, O.width, lay); PmDump.WriteLayout(lay)
    ELSIF O.to = "pic" THEN FL.Fit(g, font, O.size, O.width, lay); PmPic.Write(lay, O.font)
    ELSIF O.to = "mp" THEN FL.Make(g, font, O.size, lay); PmMp.Write(lay, O.width, O.mpInput)
    ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
    END
  END;
  PmIO.CloseOutput
END pomermaid.
