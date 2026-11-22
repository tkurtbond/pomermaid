MODULE PmIOTest;
(* Tests of PmIO's number writers. *)

IMPORT PmIO;

PROCEDURE R(x: REAL; d: INTEGER);
BEGIN
  PmIO.WriteReal(x, d); PmIO.WriteLn
END R;

BEGIN
  PmIO.WriteInt(0); PmIO.WriteLn;
  PmIO.WriteInt(-1234); PmIO.WriteLn;
  PmIO.WriteInt(30000); PmIO.WriteLn;
  R(0.0, 2); R(1.5, 2); R(-1.5, 2); R(2.0, 2);
  R(0.004, 2); R(-0.004, 2); R(12.345, 1); R(3.14159, 4);
  R(1.999, 2); R(100.1, 0); R(1234.5, 2);
  PmIO.CloseOutput
END PmIOTest.
