MODULE PmMetricsTest;
(* Tests of PmMetrics, with the made-up font test/fonts/devpdf/TT *)

IMPORT Out, M := PmMetrics, F := PmFlow, L := PmLex;

VAR f: M.Font; failures: INTEGER;

PROCEDURE Check(name: ARRAY OF CHAR; got, want: LONGINT);
BEGIN
  IF got = want THEN Out.String("ok   - ") ELSE Out.String("FAIL - "); INC(failures) END;
  Out.String(name);
  IF got # want THEN Out.String(": got "); Out.Int(got, 0); Out.String(", want "); Out.Int(want, 0) END;
  Out.Ln
END Check;

PROCEDURE U(s: ARRAY OF CHAR; size: REAL): LONGINT;
BEGIN
  RETURN M.Units(f, s, 0, L.Length(s), size)
END U;

PROCEDURE B(b: BOOLEAN): LONGINT;
BEGIN
  IF b THEN RETURN 1 END;
  RETURN 0
END B;

PROCEDURE W(s: ARRAY OF CHAR; size: REAL): REAL;
BEGIN
  RETURN M.Width(f, s, 0, L.Length(s), size)
END W;

PROCEDURE R(x: REAL): LONGINT;
BEGIN
  RETURN ENTIER(x * 100 + 0.5)
END R;

PROCEDURE Shapes;
  VAR w, h: REAL;
BEGIN
  M.ShapeSize(F.Rect, 50, 12, 16, w, h);
  Check("rect, Mermaid's padding: width", R(w), 8000); Check("rect: height", R(h), 4200);
  M.ShapeSize(F.Diamond, 50, 12, 16, w, h);
  Check("diamond: width", R(w), 12200); Check("diamond: height", R(h), 12200);
  M.ShapeSize(F.Circle, 50, 12, 16, w, h);
  Check("circle: diameter", R(w), 8000)
END Shapes;

BEGIN
  failures := 0;
  M.SetPath("/nonexistent:../../../test/fonts");
  Check("load TT", B(M.Load("TT", f)), 1);
  Check("no font XX", B(M.Load("XX", f)), 0);
  IF M.Load("TT", f) THEN
    Check("A at 10", U("A", 10), 7000);
    Check("A at 1", U("A", 1), 700);
    Check("A at 10.5", U("A", 10.5), 7350);
    Check("space", U(" ", 10), 2500);
    Check("kern AV", U("AV", 10), 7000 + 7000 - 1000);
    Check("kern VAV", U("VAV", 10), 3 * 7000 - 800 - 1000);
    Check("ligature fi", U("fi", 10), 5500);
    Check("no ligature ff", U("ff", 10), 6000 - 200);
    Check("f, kern f f, then fi", U("ffi", 10), 3000 - 200 + 5500);
    Check("fl: no glyph, so f and l", U("fl", 10), 5500);
    Check("hyphen and hy", U("-", 10), 3300);
    Check("e acute by name, kerned", U("éx", 10), 4500 + 5000 - 100);
    Check("u0107", U("ć", 10), 4600);
    Check("Euro from --", U("€", 10), 7000);
    Check("unknown: half an em", U("Z", 10), 5000);
    Check("no kern across a space", U("A V", 10), 7000 + 2500 + 7000);
    Check("no kern before a space", U("A ", 10), 7000 + 2500);
    Check("points", R(W("AA", 10)), 1400)
  END;
  Shapes;
  IF failures > 0 THEN Out.Int(failures, 0); Out.String(" failed"); Out.Ln END
END PmMetricsTest.
