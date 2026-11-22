MODULE PmOptions;
(* PmOptions: pomermaid's command line.

     pomermaid [OPTIONS] [FILE]

   reads one diagram from FILE, or standard input when there is none or
   it is "-", and writes it in the format -t names to standard output or
   to -o's file. ArgParser reads the options; a mistake in them ends
   pomermaid with ArgParser's status, 2. *)

IMPORT ArgParser, PmIO;

CONST
  Version* = "0.1";

TYPE
  String* = ArgParser.String;

VAR
  to*: String;     (* -t: the output format *)
  output*: String; (* -o: the output file, "" for standard output *)
  input*: String;  (* the input file, "-" for standard input *)
  font*: String;   (* --font: the groff font labels are set in *)
  size*: REAL;     (* --size: their size, in points *)
  fontPath*: String; (* --font-path: where groff's fonts are, "" for PmMetrics' default *)
  width*: REAL;    (* --width: the widest a diagram may be, in points; 0 for no limit *)
  mpInput*: BOOLEAN; (* --mp-macros=input: the MetaPost writer inputs pomermaid.mp *)
  done*: BOOLEAN;  (* --help or --version was given: nothing more to do *)
  inputs: INTEGER;
  parser: ArgParser.Parser;

PROCEDURE Help(): BOOLEAN;
BEGIN
  parser.Usage;
  done := TRUE;
  RETURN FALSE
END Help;

PROCEDURE ShowVersion(): BOOLEAN;
BEGIN
  PmIO.WriteString("pomermaid "); PmIO.WriteString(Version); PmIO.WriteLn;
  PmIO.WriteString("Mermaid diagrams in pic and MetaPost, in Oberon-2, built with poc."); PmIO.WriteLn;
  done := TRUE;
  RETURN FALSE
END ShowVersion;

PROCEDURE SetTo(VAR arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
  COPY(arg, to);
  RETURN TRUE
END SetTo;

PROCEDURE SetOutput(VAR arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
  COPY(arg, output);
  RETURN TRUE
END SetOutput;

PROCEDURE SetFont(VAR arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
  COPY(arg, font);
  RETURN TRUE
END SetFont;

PROCEDURE SetFontPath(VAR arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
  COPY(arg, fontPath);
  RETURN TRUE
END SetFontPath;

(* A decimal number at arg[i], such as 10 or 10.5: FALSE if there is
   none. i is left after it. *)
PROCEDURE Number(VAR arg: ARRAY OF CHAR; VAR i: INTEGER; VAR x: REAL): BOOLEAN;
  VAR frac: REAL; digits: BOOLEAN;
BEGIN
  x := 0; i := 0; digits := FALSE;
  WHILE (i < LEN(arg)) & (arg[i] >= "0") & (arg[i] <= "9") DO
    x := x * 10 + (ORD(arg[i]) - ORD("0")); INC(i); digits := TRUE
  END;
  IF (i < LEN(arg)) & (arg[i] = ".") THEN
    INC(i); frac := 1;
    WHILE (i < LEN(arg)) & (arg[i] >= "0") & (arg[i] <= "9") DO
      frac := frac / 10; x := x + frac * (ORD(arg[i]) - ORD("0")); INC(i); digits := TRUE
    END
  END;
  RETURN digits
END Number;

(* --size: a decimal number of points, more than 0 and at most 1000 *)
PROCEDURE SetSize(VAR arg: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER; x: REAL;
BEGIN
  IF ~Number(arg, i, x) OR (i < LEN(arg)) & (arg[i] # 0X) OR (x <= 0) OR (x > 1000) THEN
    PmIO.Fail("", "--size takes a number of points, such as 10 or 10.5", PmIO.OptionError)
  END;
  size := x;
  RETURN TRUE
END SetSize;

(* --width: a decimal number with a unit, i (inches, the default), c
   (centimetres) or p (points); 0 for no limit *)
PROCEDURE SetWidth(VAR arg: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER; x: REAL; ok: BOOLEAN;
BEGIN
  ok := Number(arg, i, x);
  IF ok & (i < LEN(arg)) & (arg[i] # 0X) THEN
    CASE arg[i] OF
      "i": x := x * 72
    | "c": x := x * 72 / 2.54
    | "p":
    ELSE ok := FALSE
    END;
    INC(i);
    ok := ok & ((i >= LEN(arg)) OR (arg[i] = 0X))
  ELSE x := x * 72
  END;
  IF ~ok OR (x > 72000) THEN
    PmIO.Fail("", "--width takes a length, such as 6i, 15c or 432p, or 0 for no limit", PmIO.OptionError)
  END;
  width := x;
  RETURN TRUE
END SetWidth;

(* --mp-macros: inline, the macros copied into each MetaPost block, or
   input, "input pomermaid ;" *)
PROCEDURE SetMpMacros(VAR arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF arg = "inline" THEN mpInput := FALSE
  ELSIF arg = "input" THEN mpInput := TRUE
  ELSE PmIO.Fail("", "--mp-macros takes inline or input", PmIO.OptionError)
  END;
  RETURN TRUE
END SetMpMacros;

PROCEDURE AddInput(startIdx: INTEGER; VAR arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
  INC(inputs);
  IF inputs > 1 THEN
    PmIO.Fail("", "one diagram at a time: give one FILE, or none for standard input", PmIO.OptionError)
  END;
  COPY(arg, input);
  RETURN TRUE
END AddInput;

(* Parses the command line into the variables above. --help and
   --version set done. *)
PROCEDURE Parse*;
BEGIN
  parser := ArgParser.NewParser("pomermaid [OPTIONS] [FILE]", AddInput);
  parser.AddOption(ArgParser.MakeStringOption("t", "to",
    "The output format: pic, mp, dump (the diagram read) or layout (its layout), the last two for tests.", SetTo));
  parser.AddOption(ArgParser.MakeStringOption("o", "output",
    "Write to this file rather than standard output.", SetOutput));
  parser.AddOption(ArgParser.MakeStringOption(0X, "font",
    "Set labels in this groff font (TR by default).", SetFont));
  parser.AddOption(ArgParser.MakeStringOption(0X, "size",
    "Set labels at this size, in points (10 by default).", SetSize));
  parser.AddOption(ArgParser.MakeStringOption(0X, "width",
    "Make a diagram no wider than this, in inches, or with a unit, c or p (6i by default; 0 for no limit).", SetWidth));
  parser.AddOption(ArgParser.MakeStringOption(0X, "font-path",
    "Look for groff's fonts in these directories, separated by colons.", SetFontPath));
  parser.AddOption(ArgParser.MakeStringOption(0X, "mp-macros",
    "For mp: copy pomermaid.mp's macros into the drawing (inline, the default) or input it (input).", SetMpMacros));
  parser.AddOption(ArgParser.MakeOption("v", "version",
    "Show pomermaid's version.", ShowVersion));
  parser.AddOption(ArgParser.MakeOption("h", "help",
    "Show this help.", Help));
  parser.ParseArguments(1)
END Parse;

BEGIN
  to := "pic"; output := ""; input := "-"; done := FALSE; inputs := 0;
  font := "TR"; size := 10; fontPath := ""; width := 6 * 72;
  mpInput := FALSE
END PmOptions.
