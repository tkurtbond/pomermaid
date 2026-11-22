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
    "The output format: pic or mp.", SetTo));
  parser.AddOption(ArgParser.MakeStringOption("o", "output",
    "Write to FILE rather than standard output.", SetOutput));
  parser.AddOption(ArgParser.MakeOption("v", "version",
    "Show pomermaid's version.", ShowVersion));
  parser.AddOption(ArgParser.MakeOption("h", "help",
    "Show this help.", Help));
  parser.ParseArguments(1)
END Parse;

BEGIN
  to := "pic"; output := ""; input := "-"; done := FALSE; inputs := 0
END PmOptions.
