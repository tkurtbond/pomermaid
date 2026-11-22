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

(* --size: a decimal number of points, more than 0 and at most 1000 *)
PROCEDURE SetSize(VAR arg: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER; x, frac: REAL; digits: BOOLEAN;
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
  IF ~digits OR (i < LEN(arg)) & (arg[i] # 0X) OR (x <= 0) OR (x > 1000) THEN
    PmIO.Fail("", "--size takes a number of points, such as 10 or 10.5", PmIO.OptionError)
  END;
  size := x;
  RETURN TRUE
END SetSize;

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
    "The output format: pic, mp, or dump (the diagram read, for tests).", SetTo));
  parser.AddOption(ArgParser.MakeStringOption("o", "output",
    "Write to this file rather than standard output.", SetOutput));
  parser.AddOption(ArgParser.MakeStringOption(0X, "font",
    "Set labels in this groff font (TR by default).", SetFont));
  parser.AddOption(ArgParser.MakeStringOption(0X, "size",
    "Set labels at this size, in points (10 by default).", SetSize));
  parser.AddOption(ArgParser.MakeStringOption(0X, "font-path",
    "Look for groff's fonts in these directories, separated by colons.", SetFontPath));
  parser.AddOption(ArgParser.MakeOption("v", "version",
    "Show pomermaid's version.", ShowVersion));
  parser.AddOption(ArgParser.MakeOption("h", "help",
    "Show this help.", Help));
  parser.ParseArguments(1)
END Parse;

BEGIN
  to := "pic"; output := ""; input := "-"; done := FALSE; inputs := 0;
  font := "TR"; size := 10; fontPath := ""
END PmOptions.
