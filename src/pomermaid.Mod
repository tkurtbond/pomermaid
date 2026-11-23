MODULE pomermaid;
(* pomermaid: Mermaid diagrams drawn in pic, for groff, and MetaPost,
   for ConTeXt, and SVG made from the pic through groff. The command line is PmOptions'. See PLAN.md. *)

IMPORT PmIO, O := PmOptions, L := PmLex, PmFlow, PmState, PmClass, PmEr, PmDump, M := PmMetrics, FL := PmFlowLayout, PmPic, PmMp, PmSvg;

VAR
  text: PmIO.Text;
  len: LONGINT;
  sc: L.Scanner;
  g: PmFlow.Graph;
  font: M.Font;
  lay: FL.Layout;

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
    ELSIF PmFlow.IsFlowchart(sc) THEN PmFlow.Read(sc, g)
    ELSE sc.Error("not a diagram pomermaid knows; it reads flowchart, graph, stateDiagram, classDiagram and erDiagram")
    END;
    IF O.to # "dump" THEN
      IF O.fontPath # "" THEN M.SetPath(O.fontPath) END;
      IF ~M.Load(O.font, font) THEN
        PmIO.Fail("", "no such groff font in devpdf or devps; see --font and --font-path", PmIO.FontNotFound)
      END;
      M.LoadStyles(font)
    END;
    IF O.to = "svg" THEN
      (* PmSvg opens the output once the SVG is made *)
      FL.Fit(g, font, O.size, O.width, lay);
      PmSvg.Write(lay, O.font, O.fontPath, O.output, O.svgOutline, O.svgEngine)
    ELSE PmIO.OpenOutput(O.output)
    END;
    IF O.to = "svg" THEN
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
