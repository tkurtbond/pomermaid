MODULE pomermaid;
(* pomermaid: Mermaid diagrams drawn in pic, for groff, and MetaPost,
   for ConTeXt. The command line is PmOptions'. See PLAN.md. *)

IMPORT PmIO, O := PmOptions, L := PmLex, PmFlow, PmDump, M := PmMetrics;

VAR
  text: PmIO.Text;
  len: LONGINT;
  sc: L.Scanner;
  g: PmFlow.Graph;
  font: M.Font;

BEGIN
  O.Parse;
  IF ~O.done THEN
    IF (O.to # "pic") & (O.to # "mp") & (O.to # "dump") THEN
      PmIO.Fail("", "unknown output format; use pic or mp", PmIO.UnknownWriter)
    END;
    PmIO.ReadFile(O.input, text, len);
    sc := L.Open(text, len, O.input);
    IF ~PmFlow.IsFlowchart(sc) THEN
      sc.Error("not a diagram pomermaid knows; it reads flowchart and graph")
    END;
    PmFlow.Read(sc, g);
    IF O.to # "dump" THEN
      IF O.fontPath # "" THEN M.SetPath(O.fontPath) END;
      IF ~M.Load(O.font, font) THEN
        PmIO.Fail("", "no such groff font in devpdf or devps; see --font and --font-path", PmIO.FontNotFound)
      END
    END;
    PmIO.OpenOutput(O.output);
    IF O.to = "dump" THEN PmDump.Write(g)
    ELSE PmIO.Fail("", "no writer for this format yet", PmIO.UnknownWriter)
    END
  END;
  PmIO.CloseOutput
END pomermaid.
