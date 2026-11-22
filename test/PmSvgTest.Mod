MODULE PmSvgTest;
(* Tests of PmSvg.Crop: the band cut from the top of an SVG's page, as
   mutool and pdftocairo write the root element. *)

IMPORT PmIO, PmSvg;

PROCEDURE C(s: ARRAY OF CHAR; top: REAL);
  VAR t: PmIO.Text; len, i: LONGINT;
BEGIN
  len := 0; WHILE s[len] # 0X DO INC(len) END;
  NEW(t, len + 1);
  FOR i := 0 TO len - 1 DO t[i] := s[i] END;
  IF ~PmSvg.Crop(t, len, top) THEN PmIO.WriteString("(not cropped)") END;
  PmIO.WriteLn
END C;

BEGIN
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
  PmIO.CloseOutput
END PmSvgTest.
