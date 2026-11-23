MODULE PmSvgTest;
(* Tests of PmSvg.Crop: the band cut from the top of an SVG's page, as
   mutool and pdftocairo write the root element; and the nodes' links
   and tooltips it writes before the last </svg>. *)

IMPORT PmIO, PmSvg, Lx := PmLex, F := PmFlow, FL := PmFlowLayout, M := PmMetrics;

VAR layout: FL.Layout;

PROCEDURE C(s: ARRAY OF CHAR; top: REAL);
  VAR t: PmIO.Text; len, i: LONGINT;
BEGIN
  len := 0; WHILE s[len] # 0X DO INC(len) END;
  NEW(t, len + 1);
  FOR i := 0 TO len - 1 DO t[i] := s[i] END;
  IF ~PmSvg.Crop(t, len, top, layout) THEN PmIO.WriteString("(not cropped)") END;
  PmIO.WriteLn
END C;

(* Sets layout to the drawing of the flowchart s, in the test font TS *)
PROCEDURE Lay(s: ARRAY OF CHAR);
  VAR t: PmIO.Text; len, i: LONGINT; g: F.Graph; f: M.Font;
BEGIN
  len := 0; WHILE s[len] # 0X DO INC(len) END;
  NEW(t, len + 1);
  FOR i := 0 TO len - 1 DO IF s[i] = "|" THEN t[i] := 0AX ELSE t[i] := s[i] END END;
  t[len] := 0X;
  F.Read(Lx.Open(t, len, "test"), g);
  M.SetPath("../../../test/fonts");
  IF ~M.Load("TS", f) THEN PmIO.WriteString("no font TS"); PmIO.WriteLn END;
  FL.Fit(g, f, 16, 0, layout)
END Lay;

BEGIN
  layout := NIL;
  (* mutool draw *)
  C('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="398.79" height="535.06" viewBox="0 0 398.79 535.06"><g/></svg>', 12);
  (* pdftocairo, after an XML declaration *)
  C('<?xml version="1.0"?><svg xmlns="x" width="398.79pt" height="535.06pt" viewBox="0 0 398.79 535.06"><defs/></svg>', 12);
  (* viewBox before height, commas, an attribute ending in height *)
  C('<svg data-height="7" viewBox="0,0,100,60" height="60px">x</svg>', 12.5);
  (* none: no viewBox; a height no taller than the band; no root *)
  C('<svg width="10" height="20">', 12);
  C('<svg height="10" viewBox="0 0 10 10">', 12);
  C('<svgx height="20" viewBox="0 0 10 20">', 12);
  (* links: a URL with & and a target and tooltip; one Mermaid makes
     about:blank; a callback's tooltip alone; a relative URL; a node
     with none. xlink:href too where xlink is declared. *)
  Lay('flowchart LR|A --> B --> C --> D --> E|click A "https://x.org/?a=1&b=2" "Go <there>" _blank|click B href " JavaScript:alert(1)"|click C call f() "Tip"|click D "a/b:c.html" _self');
  C('<svg xmlns:xlink="http://www.w3.org/1999/xlink" height="100" viewBox="0 0 100 100"><g/></svg>', 12);
  Lay('flowchart LR|A --> B|click B "data:text/html,x"|click A "data-page.html"');
  C('<svg height="100" viewBox="0 0 100 100"><g/> </svg> ', 12);
  PmIO.CloseOutput
END PmSvgTest.
