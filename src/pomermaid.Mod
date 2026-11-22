MODULE pomermaid;
(* pomermaid: Mermaid diagrams drawn in pic, for groff, and MetaPost,
   for ConTeXt. The command line is PmOptions'. See PLAN.md. *)

IMPORT PmIO, O := PmOptions;

VAR
  text: PmIO.Text;
  len: LONGINT;

BEGIN
  O.Parse;
  IF ~O.done THEN
    IF (O.to # "pic") & (O.to # "mp") THEN
      PmIO.Fail("", "unknown output format; use pic or mp", PmIO.UnknownWriter)
    END;
    PmIO.ReadFile(O.input, text, len);
    PmIO.OpenOutput(O.output);
    PmIO.Fail("", "no diagram reader yet", PmIO.ParseError)
  END;
  PmIO.CloseOutput
END pomermaid.
