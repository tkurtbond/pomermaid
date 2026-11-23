MODULE PmSeq;
(* PmSeq: Mermaid's sequence diagrams (`sequenceDiagram`), read into a
   model of their own: the participants, in the order they are first
   named, the boxes around them, and the events, in order, that the
   layout, PmSeqLayout, turns into a drawing from the top down.

   The reader follows Mermaid's grammar, packages/mermaid/src/diagrams/
   sequence/parser/sequenceDiagram.jison, and what sequenceDb.ts makes
   of it:

   - statements end at a line end or ";"; "%%" and "#" start a
     comment, but "#name;" and "#123;" are Mermaid's entities, as in
     the text of messages; keywords are read in any case;
   - "participant name", "actor name", with "as text" for the text
     drawn and "@{ ... }" for its type (participant, actor, boundary,
     control, entity, database, collections or queue) and alias;
     "create participant ..." and "destroy name";
   - "box colour title" ... "end" around participants;
   - messages, "a->>b: text", with the arrows of Mermaid 11, "+" or "-"
     after the arrow (activate b, deactivate a), and "()" before or
     after it (a central connection);
   - "activate name", "deactivate name";
   - "note left of a: text", "note right of a: text", "note over a:
     text", "note over a,b: text";
   - "loop", "opt", "alt" with "else", "par" and "par_over" with "and",
     "critical" with "option", "break" and "rect colour", each to its
     "end";
   - "autonumber", "autonumber start", "autonumber start step",
     "autonumber off";
   - "title text", "title: text"; accTitle, accDescr, "links", "link",
     "properties" and "details" are read and skipped.

   Mermaid's "wrap:" and "nowrap:" before a text are read and ignored:
   pomermaid does not wrap a sequence diagram's text. A keyword must
   end at a word's end here, where Mermaid's lexer would take
   "loopback" as "loop" and "back". *)

IMPORT L := PmLex, F := PmFlow, Y := PmYaml, S := PmStyle, C := PmClass;

CONST
  (* participants' types *)
  Participant* = 0; Person* = 1; (* "actor" *) Boundary* = 2; Control* = 3; Entity* = 4;
  Database* = 5; Collections* = 6; Queue* = 7;
  NoType = -1;          (* a participant named, not defined *)

  (* events *)
  Msg* = 0; Note* = 1; BlockStart* = 2; Section* = 3; BlockEnd* = 4;
  Activate* = 5; Deactivate* = 6;

  (* a message's ends *)
  NoHead* = 0; Filled* = 1; Open* = 2; Cross* = 3; SolidTop* = 4;
  SolidBottom* = 5; StickTop* = 6; StickBottom* = 7;

  (* a message's central connections *)
  CentralTo* = 1; CentralFrom* = 2;

  (* notes' placements *)
  LeftOf* = 0; RightOf* = 1; Over* = 2;

  (* blocks *)
  Loop* = 0; Opt* = 1; Alt* = 2; Par* = 3; ParOver* = 4; Critical* = 5;
  Break* = 6; Rect* = 7;

  NoColour* = -1;
  MaxDepth = 64;        (* blocks inside blocks *)

TYPE
  Str = L.Str;

  Box* = POINTER TO BoxDesc;
  BoxDesc* = RECORD
    title*: F.Label;    (* or NIL *)
    fill*: LONGINT;     (* 0RRGGBBH, or NoColour for none *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Box
  END;

  Event* = POINTER TO EventDesc;

  Actor* = POINTER TO ActorDesc;
  ActorDesc* = RECORD
    id*: Str;
    label*: F.Label;    (* the text drawn: "as"'s, or the id *)
    type*: INTEGER;     (* Participant ... *)
    box*: Box;          (* or NIL *)
    index*: INTEGER;    (* from 0, in order of first mention *)
    created*, destroyed*: Event; (* the messages that create and destroy
                           it, or NIL *)
    next*: Actor
  END;

  EventDesc* = RECORD
    kind*: INTEGER;     (* Msg ... *)
    from*, to*: Actor;  (* a message's; a note's (to = from for one);
                           an activation's (from) *)
    text*: F.Label;     (* a message's, a note's, a block's or a
                           section's; NIL for none *)
    dotted*: BOOLEAN;   (* a message's line *)
    head*, tail*: INTEGER; (* a message's ends, at to and at from:
                           NoHead ...; "top" is the upper side when
                           from is left of to, the lower otherwise *)
    activate*: BOOLEAN; (* "+" after the arrow *)
    central*: SET;      (* {CentralTo, CentralFrom} *)
    placement*: INTEGER; (* a note's *)
    block*: INTEGER;    (* a block's kind, Loop ..., at its start, its
                           sections and its end *)
    fill*: LONGINT;     (* a rect's, 0RRGGBBH, or NoColour *)
    number*: Str;       (* a message's number, or NIL *)
    index*: INTEGER;    (* from 0, in order *)
    next*: Event
  END;

  Diagram* = POINTER TO DiagramDesc;
  DiagramDesc* = RECORD
    g*: F.Graph;        (* the title and the configuration *)
    actors*: Actor; nActors*: INTEGER;
    boxes*: Box; nBoxes*: INTEGER;
    events*: Event; nEvents*: INTEGER;
    mirror*: BOOLEAN;   (* the participants drawn again at the bottom *)
    lastActor: Actor; lastBox: Box; lastEvent: Event
  END;

VAR
  sc: L.Scanner;
  d: Diagram;
  box: Box;              (* the box being read, or NIL *)
  lastCreated: Actor;    (* created, not yet sent its message *)
  lastDestroyed: Str;    (* destroyed, not yet sent or sending its message *)
  depth: INTEGER;
  open: ARRAY MaxDepth OF INTEGER; (* the blocks being read *)
  (* autonumber, in hundredths *)
  numbering: BOOLEAN;
  number, step: LONGINT;

(* Text *)

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN RETURN CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* Whether the text at the position is w, which is in lower case, in
   any case *)
PROCEDURE LookingAtI(w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF Lower(sc.Peek(i)) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END LookingAtI;

(* Whether the text at the position is the keyword w, in any case, not
   followed by a word character *)
PROCEDURE Kw(w: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN LookingAtI(w) & ~L.IsWordChar(sc.Peek(L.Length(w)))
END Kw;

(* Whether the text at p is an entity, "#name;" or "#123;" *)
PROCEDURE IsEntity(p: LONGINT): BOOLEAN;
  VAR k: LONGINT;
BEGIN
  k := p + 1;
  WHILE (k < LEN(sc.t^)) & L.IsWordChar(sc.t[k]) DO INC(k) END;
  RETURN (k > p + 1) & (k < LEN(sc.t^)) & (sc.t[k] = ";")
END IsEntity;

(* Whether the text at the position starts a comment *)
PROCEDURE AtComment(): BOOLEAN;
BEGIN
  RETURN sc.LookingAt("%%") OR (sc.Ch() = "#") & ~IsEntity(sc.pos)
END AtComment;

(* Skips blanks, line ends, ";", and comments and directives *)
PROCEDURE SkipSpace;
  VAR e: LONGINT;
BEGIN
  LOOP
    sc.SkipBlanks;
    IF (sc.Ch() = 0AX) OR (sc.Ch() = ";") THEN INC(sc.pos)
    ELSIF sc.LookingAt("%%") THEN
      e := sc.DirectiveEnd();
      IF e >= 0 THEN sc.pos := e ELSE sc.SkipLine END
    ELSIF sc.Ch() = "#" THEN sc.SkipLine
    ELSE EXIT
    END
  END
END SkipSpace;

(* Whether the statement ends here, after blanks *)
PROCEDURE AtEnd(): BOOLEAN;
BEGIN
  sc.SkipBlanks;
  RETURN sc.AtEnd() OR (sc.Ch() = 0AX) OR (sc.Ch() = ";") OR AtComment()
END AtEnd;

PROCEDURE ExpectEnd;
BEGIN
  IF ~AtEnd() THEN sc.Error("unexpected text") END
END ExpectEnd;

(* The rest of the statement, from the position, as a label: without
   blanks at its ends and without Mermaid's "wrap:" or "nowrap:"; NIL
   if it is empty *)
PROCEDURE RestOfLine(): F.Label;
  VAR start, end: LONGINT; ch: CHAR;
BEGIN
  sc.SkipBlanks;
  IF sc.Ch() = ":" THEN
    IF LookingAtI(":wrap:") OR LookingAtI(":nowrap:") THEN INC(sc.pos) END
  END;
  IF LookingAtI("wrap:") THEN INC(sc.pos, 5)
  ELSIF LookingAtI("nowrap:") THEN INC(sc.pos, 7)
  END;
  sc.SkipBlanks;
  start := sc.pos;
  LOOP
    IF sc.AtEnd() THEN EXIT END;
    ch := sc.Ch();
    IF (ch = 0AX) OR (ch = ";") THEN EXIT
    ELSIF ch = "#" THEN
      IF ~IsEntity(sc.pos) THEN EXIT END;
      WHILE sc.Ch() # ";" DO INC(sc.pos) END;
      INC(sc.pos)
    ELSE INC(sc.pos)
    END
  END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  IF end = start THEN RETURN NIL END;
  RETURN F.MakeLabel(sc.t^, start, end, FALSE)
END RestOfLine;

(* A message's or a note's text: ":" and the rest of the statement *)
PROCEDURE Text(): F.Label;
BEGIN
  sc.SkipBlanks;
  IF sc.Ch() # ":" THEN sc.Error('expected ":" and the text') END;
  INC(sc.pos);
  RETURN RestOfLine()
END Text;

(* The colour named by s, as 0RRGGBBH, or NoColour; "rgba(...)" and
   "hsla(...)" are blended with white by their alpha *)
PROCEDURE Colour(s: Str): LONGINT;
  VAR rgb, c, a100: LONGINT; none: BOOLEAN; i, n, k: LONGINT; x, f: REAL; t: Str;
BEGIN
  t := L.Sub(s^, 0, L.Length(s^));
  i := 0;
  WHILE t[i] # 0X DO
    t[i] := Lower(t[i]);
    IF L.IsBlank(t[i]) & (t[i + 1] = "(") THEN
      k := i; WHILE t[k] # 0X DO t[k] := t[k + 1]; INC(k) END
    ELSE INC(i)
    END
  END;
  IF ~S.ParseColour(t^, rgb, none) OR none THEN RETURN NoColour END;
  (* the alpha, the fourth number *)
  IF (t[0] = "r") & (t[3] = "a") THEN
    i := 0; n := 0;
    WHILE (t[i] # 0X) & (n < 3) DO IF t[i] = "," THEN INC(n) END; INC(i) END;
    IF n = 3 THEN
      WHILE L.IsBlank(t[i]) DO INC(i) END;
      x := 0;
      WHILE L.IsDigit(t[i]) DO x := x * 10 + (ORD(t[i]) - ORD("0")); INC(i) END;
      IF t[i] = "." THEN
        INC(i); f := 0.1;
        WHILE L.IsDigit(t[i]) DO x := x + f * (ORD(t[i]) - ORD("0")); f := f / 10; INC(i) END
      END;
      IF t[i] = "%" THEN x := x / 100 END;
      IF x > 1 THEN x := 1 END;
      a100 := ENTIER(x * 100 + 0.5);
      c := 0;
      FOR k := 0 TO 2 DO
        n := rgb DIV 10000H; rgb := rgb MOD 10000H * 100H;
        c := c * 100H + 255 - (255 - n) * a100 DIV 100
      END;
      rgb := c
    END
  END;
  RETURN rgb
END Colour;

(* Participants *)

PROCEDURE Find(id: Str): Actor;
  VAR a: Actor;
BEGIN
  a := d.actors;
  WHILE (a # NIL) & ~L.Equal(a.id, id) DO a := a.next END;
  RETURN a
END Find;

(* The participant id, defined with text desc (NIL for none) and type
   type, or NoType when it is only named, at p, as sequenceDb.ts's
   addActor has it *)
PROCEDURE Define(id: Str; desc: F.Label; type: INTEGER; p: LONGINT): Actor;
  VAR a: Actor; msg: ARRAY 512 OF CHAR;

  PROCEDURE Cat(s: ARRAY OF CHAR);
    VAR i, k: LONGINT;
  BEGIN
    i := 0; WHILE msg[i] # 0X DO INC(i) END;
    k := 0;
    WHILE (k < LEN(s)) & (s[k] # 0X) & (i < LEN(msg) - 1) DO msg[i] := s[k]; INC(i); INC(k) END;
    msg[i] := 0X
  END Cat;

  PROCEDURE BoxName(b: Box);
  BEGIN
    IF (b.title # NIL) & (b.title.lines # NIL) THEN Cat(b.title.lines.text^) END
  END BoxName;

BEGIN
  a := Find(id);
  IF a # NIL THEN
    IF (box # NIL) & (a.box # NIL) & (box # a.box) THEN
      msg := "a participant can be in one box only: "; Cat(id^); Cat(" can't be in '");
      BoxName(a.box); Cat("' and in '"); BoxName(box); Cat("' at the same time");
      sc.ErrorAt(p, msg)
    END;
    IF a.box = NIL THEN a.box := box END;
    IF desc = NIL THEN
      IF type # NoType THEN a.type := type END;
      RETURN a
    END
  ELSE
    NEW(a); a.id := id; a.box := box; a.index := d.nActors; INC(d.nActors);
    a.created := NIL; a.destroyed := NIL; a.next := NIL;
    a.type := Participant;
    IF d.actors = NIL THEN d.actors := a ELSE d.lastActor.next := a END;
    d.lastActor := a
  END;
  IF desc = NIL THEN desc := F.PlainLabel(id) END;
  a.label := desc;
  IF type # NoType THEN a.type := type END;
  RETURN a
END Define;

(* A participant named in a message, a note or an activation: as
   Mermaid's lexer reads it there, up to "+", "<", ">", ":", ",", ";",
   a line end or an arrow, with "-" in it where no arrow starts *)
PROCEDURE Name(): Str;
  VAR start, end, k: LONGINT; ch: CHAR; later: BOOLEAN;

  PROCEDURE Stop(c: CHAR): BOOLEAN;
  BEGIN
    RETURN (c = 0X) OR (c = "+") OR (c = "<") OR (c = ">") OR (c = ":") OR (c = 0AX)
      OR (c = ",") OR (c = ";") OR (c = "-")
  END Stop;

BEGIN
  sc.SkipBlanks;
  start := sc.pos; later := FALSE;
  LOOP
    IF sc.AtEnd() THEN EXIT END;
    ch := sc.Ch();
    IF ch = "-" THEN
      ch := Lower(sc.Peek(1));
      IF (ch = "x") OR (ch = ")") OR (ch = "|") OR (ch = "\") OR (ch = "/") OR (ch = "-") THEN EXIT END;
      k := sc.pos; WHILE (k < LEN(sc.t^)) & (sc.t[k] = "-") DO INC(k) END;
      IF (k >= LEN(sc.t^)) OR Stop(sc.t[k]) THEN EXIT END;
      sc.pos := k; later := TRUE
    ELSIF Stop(ch) THEN EXIT
    ELSIF ~later & ((ch = "/") OR (ch = "\") OR (ch = "(") OR (ch = ")")) THEN EXIT
    ELSIF later & (sc.LookingAt("/|-") OR sc.LookingAt("\|-") OR sc.LookingAt("//-")
      OR sc.LookingAt("\\-") OR sc.LookingAt("()")) THEN EXIT
    ELSE INC(sc.pos)
    END
  END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  IF end = start THEN sc.Error("expected a participant") END;
  RETURN L.Sub(sc.t^, start, end - start)
END Name;

(* A participant named, which is defined if it is new *)
PROCEDURE Named(): Actor;
  VAR p: LONGINT; id: Str;
BEGIN
  sc.SkipBlanks; p := sc.pos;
  id := Name();
  RETURN Define(id, NIL, NoType, p)
END Named;

(* A participant's name after participant, actor, create, destroy,
   activate and deactivate, as Mermaid's lexer reads it there: a word
   before "as" or "@{", or else the rest of the statement, which cannot
   have "<", ">", ":", "," or "@" in it. alias and config say which
   follows. *)
PROCEDURE IdName(VAR alias, config: BOOLEAN): Str;
  VAR start, k, end: LONGINT; ch: CHAR; id: Str;

  PROCEDURE NameChar(c: CHAR): BOOLEAN;
  BEGIN
    RETURN (c # 0X) & (c # "<") & (c # ">") & (c # ":") & (c # 0AX) & (c # ",")
      & (c # ";") & (c # "@")
  END NameChar;

BEGIN
  alias := FALSE; config := FALSE;
  sc.SkipBlanks; start := sc.pos;
  k := start;
  WHILE (k < LEN(sc.t^)) & NameChar(sc.t[k]) & ~L.IsBlank(sc.t[k]) DO INC(k) END;
  IF k > start THEN
    end := k;
    WHILE (k < LEN(sc.t^)) & L.IsBlank(sc.t[k]) DO INC(k) END;
    IF (k + 1 < LEN(sc.t^)) & (sc.t[k] = "@") & (sc.t[k + 1] = "{") THEN
      sc.pos := k; config := TRUE;
      RETURN L.Sub(sc.t^, start, end - start)
    ELSIF (k > end) & (k + 2 < LEN(sc.t^)) & (Lower(sc.t[k]) = "a") & (Lower(sc.t[k + 1]) = "s")
      & L.IsBlank(sc.t[k + 2]) THEN
      sc.pos := k + 2; alias := TRUE;
      RETURN L.Sub(sc.t^, start, end - start)
    END
  END;
  (* the rest of the statement *)
  LOOP
    IF sc.AtEnd() THEN EXIT END;
    ch := sc.Ch();
    IF (ch = 0AX) OR (ch = ";") OR AtComment() THEN EXIT END;
    IF ~NameChar(ch) THEN
      sc.Error('the name of a participant cannot have "<", ">", ":", "," or "@" in it')
    END;
    INC(sc.pos)
  END;
  end := sc.pos;
  WHILE (end > start) & L.IsBlank(sc.t[end - 1]) DO DEC(end) END;
  IF end = start THEN sc.Error("expected a participant") END;
  id := L.Sub(sc.t^, start, end - start);
  RETURN id
END IdName;

(* The type named s, or NoType *)
PROCEDURE TypeNamed(s: Str): INTEGER;
BEGIN
  IF L.Is(s, "participant") THEN RETURN Participant
  ELSIF L.Is(s, "actor") THEN RETURN Person
  ELSIF L.Is(s, "boundary") THEN RETURN Boundary
  ELSIF L.Is(s, "control") THEN RETURN Control
  ELSIF L.Is(s, "entity") THEN RETURN Entity
  ELSIF L.Is(s, "database") THEN RETURN Database
  ELSIF L.Is(s, "collections") THEN RETURN Collections
  ELSIF L.Is(s, "queue") THEN RETURN Queue
  END;
  RETURN NoType
END TypeNamed;

(* "participant ..." or "actor ...", the keyword read, of type type;
   create says it was after "create" *)
PROCEDURE ParticipantStmt(type: INTEGER; create: BOOLEAN);
  VAR p: LONGINT; id: Str; alias, config: BOOLEAN; desc: F.Label;
    list, q: Y.Pair; a: Actor; t: INTEGER;
BEGIN
  sc.SkipBlanks; p := sc.pos;
  id := IdName(alias, config);
  desc := NIL;
  IF config THEN
    list := F.MetaData();
    q := Y.Find(list, "type");
    IF q # NIL THEN
      t := TypeNamed(q.value);
      IF t = NoType THEN sc.ErrorAt(q.pos, "not a participant's type") END;
      type := t
    END;
    sc.SkipBlanks;
    IF LookingAtI("as") & L.IsBlank(sc.Peek(2)) THEN INC(sc.pos, 2); alias := TRUE END;
    IF ~alias THEN
      q := Y.Find(list, "alias");
      IF (q # NIL) & (q.value[0] # 0X) THEN desc := F.PlainLabel(q.value) END
    END
  END;
  IF alias THEN
    desc := RestOfLine();
    IF desc = NIL THEN desc := F.PlainLabel(id) END
  END;
  ExpectEnd;
  IF create THEN
    IF Find(id) # NIL THEN
      sc.ErrorAt(p, 'a participant cannot be created once it exists, even if it was destroyed; give another its text with "as"')
    END;
    IF lastCreated # NIL THEN
      sc.ErrorAt(p, "the participant created before has no message creating it")
    END
  END;
  a := Define(id, desc, type, p);
  IF create THEN lastCreated := a END
END ParticipantStmt;

PROCEDURE DestroyStmt;
  VAR alias, config: BOOLEAN; id: Str;
BEGIN
  id := IdName(alias, config);
  IF alias OR config THEN sc.Error("unexpected text") END;
  ExpectEnd;
  lastDestroyed := id
END DestroyStmt;

(* Events *)

PROCEDURE NewEvent(kind: INTEGER): Event;
  VAR e: Event;
BEGIN
  NEW(e); e.kind := kind; e.from := NIL; e.to := NIL; e.text := NIL;
  e.dotted := FALSE; e.head := NoHead; e.tail := NoHead; e.activate := FALSE;
  e.central := {}; e.placement := Over; e.block := Loop; e.fill := NoColour;
  e.number := NIL; e.index := d.nEvents; INC(d.nEvents); e.next := NIL;
  IF d.events = NIL THEN d.events := e ELSE d.lastEvent.next := e END;
  d.lastEvent := e;
  RETURN e
END NewEvent;

(* The number n, in hundredths, as JavaScript writes it *)
PROCEDURE NumberText(n: LONGINT): Str;
  VAR s: ARRAY 32 OF CHAR; i, k, ip, fp: LONGINT; neg: BOOLEAN; ch: CHAR;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  ip := n DIV 100; fp := n MOD 100;
  i := 0;
  REPEAT s[i] := CHR(ORD("0") + ip MOD 10); ip := ip DIV 10; INC(i) UNTIL ip = 0;
  IF neg THEN s[i] := "-"; INC(i) END;
  FOR k := 0 TO i DIV 2 - 1 DO ch := s[k]; s[k] := s[i - 1 - k]; s[i - 1 - k] := ch END;
  IF fp # 0 THEN
    s[i] := "."; INC(i);
    s[i] := CHR(ORD("0") + fp DIV 10); INC(i);
    IF fp MOD 10 # 0 THEN s[i] := CHR(ORD("0") + fp MOD 10); INC(i) END
  END;
  s[i] := 0X;
  RETURN L.New(s)
END NumberText;

PROCEDURE Activation(kind: INTEGER; a: Actor; p: LONGINT);
  VAR e: Event; n: INTEGER;
BEGIN
  IF kind = Deactivate THEN
    (* the activations still open *)
    n := 0; e := d.events;
    WHILE e # NIL DO
      IF e.from = a THEN
        IF e.kind = Activate THEN INC(n) ELSIF e.kind = Deactivate THEN DEC(n) END
      END;
      e := e.next
    END;
    IF n < 1 THEN sc.ErrorAt(p, "the participant is not active") END
  END;
  e := NewEvent(kind); e.from := a
END Activation;

(* An arrow at the position: its ends and line; FALSE if there is none *)
PROCEDURE Arrow(VAR head, tail: INTEGER; VAR dotted: BOOLEAN): BOOLEAN;

  PROCEDURE A(w: ARRAY OF CHAR; h, t: INTEGER; dot: BOOLEAN): BOOLEAN;
  BEGIN
    IF LookingAtI(w) THEN
      INC(sc.pos, L.Length(w)); head := h; tail := t; dotted := dot;
      RETURN TRUE
    END;
    RETURN FALSE
  END A;

BEGIN
  RETURN A("->>", Filled, NoHead, FALSE) OR A("<<->>", Filled, Filled, FALSE)
    OR A("-->>", Filled, NoHead, TRUE) OR A("<<-->>", Filled, Filled, TRUE)
    OR A("->", NoHead, NoHead, FALSE) OR A("-->", NoHead, NoHead, TRUE)
    OR A("-x", Cross, NoHead, FALSE) OR A("--x", Cross, NoHead, TRUE)
    OR A("-)", Open, NoHead, FALSE) OR A("--)", Open, NoHead, TRUE)
    OR A("--|\", SolidTop, NoHead, TRUE) OR A("--|/", SolidBottom, NoHead, TRUE)
    OR A("--\\", StickTop, NoHead, TRUE) OR A("--//", StickBottom, NoHead, TRUE)
    OR A("/|--", NoHead, SolidTop, TRUE) OR A("\|--", NoHead, SolidBottom, TRUE)
    OR A("//--", NoHead, StickTop, TRUE) OR A("\\--", NoHead, StickBottom, TRUE)
    OR A("-|\", SolidTop, NoHead, FALSE) OR A("-|/", SolidBottom, NoHead, FALSE)
    OR A("-\\", StickTop, NoHead, FALSE) OR A("-//", StickBottom, NoHead, FALSE)
    OR A("/|-", NoHead, SolidTop, FALSE) OR A("\|-", NoHead, SolidBottom, FALSE)
    OR A("//-", NoHead, StickTop, FALSE) OR A("\\-", NoHead, StickBottom, FALSE)
END Arrow;

(* A message, "a->>b: text", at the position *)
PROCEDURE Message;
  VAR p, pTo: LONGINT; from, to: Actor; e: Event; head, tail: INTEGER; dotted: BOOLEAN;
    central: SET; plus, minus: BOOLEAN; text: F.Label;
BEGIN
  sc.SkipBlanks; p := sc.pos;
  from := Named();
  central := {};
  sc.SkipBlanks;
  IF sc.LookingAt("()") THEN INC(sc.pos, 2); INCL(central, CentralFrom) END;
  IF ~Arrow(head, tail, dotted) THEN sc.Error("expected an arrow") END;
  plus := FALSE; minus := FALSE;
  IF sc.LookingAt("()") THEN INC(sc.pos, 2); INCL(central, CentralTo)
  ELSIF sc.Ch() = "+" THEN INC(sc.pos); plus := TRUE
  ELSIF sc.Ch() = "-" THEN INC(sc.pos); minus := TRUE
  END;
  sc.SkipBlanks; pTo := sc.pos;
  to := Named();
  text := Text();
  e := NewEvent(Msg);
  e.from := from; e.to := to; e.text := text; e.head := head; e.tail := tail;
  e.dotted := dotted; e.central := central; e.activate := plus;
  IF lastCreated # NIL THEN
    IF to # lastCreated THEN
      sc.ErrorAt(pTo, "the participant created before has no message creating it")
    END;
    to.created := e; lastCreated := NIL
  END;
  IF lastDestroyed # NIL THEN
    IF L.Equal(to.id, lastDestroyed) THEN to.destroyed := e
    ELSIF L.Equal(from.id, lastDestroyed) THEN from.destroyed := e
    ELSE sc.ErrorAt(p, "the participant destroyed before has no message destroying it")
    END;
    lastDestroyed := NIL
  END;
  IF numbering THEN e.number := NumberText(number) END;
  INC(number, step);
  IF plus THEN Activation(Activate, to, pTo) END;
  IF minus THEN Activation(Deactivate, from, p) END
END Message;

(* A number, "12" or "1.5", in hundredths *)
PROCEDURE Num(): LONGINT;
  VAR n, f: LONGINT;
BEGIN
  n := 0;
  WHILE L.IsDigit(sc.Ch()) DO n := n * 10 + ORD(sc.Ch()) - ORD("0"); INC(sc.pos) END;
  n := n * 100;
  IF sc.Ch() = "." THEN
    INC(sc.pos); f := 10;
    IF ~L.IsDigit(sc.Ch()) THEN sc.Error("expected a number") END;
    WHILE L.IsDigit(sc.Ch()) DO
      IF f = 0 THEN sc.Error("a number here has two decimals at most") END;
      n := n + f * (ORD(sc.Ch()) - ORD("0")); f := f DIV 10; INC(sc.pos)
    END
  END;
  RETURN n
END Num;

PROCEDURE Autonumber;
BEGIN
  sc.SkipBlanks;
  IF Kw("off") THEN INC(sc.pos, 3); numbering := FALSE
  ELSE
    numbering := TRUE;
    IF L.IsDigit(sc.Ch()) OR (sc.Ch() = ".") THEN
      number := Num(); step := 100;
      sc.SkipBlanks;
      IF L.IsDigit(sc.Ch()) OR (sc.Ch() = ".") THEN step := Num() END
    END
  END;
  ExpectEnd
END Autonumber;

PROCEDURE NoteStmt;
  VAR e: Event; a, b: Actor; placement: INTEGER;
BEGIN
  sc.SkipBlanks;
  IF Kw("left") THEN placement := LeftOf; INC(sc.pos, 4)
  ELSIF Kw("right") THEN placement := RightOf; INC(sc.pos, 5)
  ELSIF Kw("over") THEN placement := Over; INC(sc.pos, 4)
  ELSE sc.Error('expected "left of", "right of" or "over"')
  END;
  IF placement # Over THEN
    sc.SkipBlanks;
    IF ~Kw("of") THEN sc.Error('expected "of"') END;
    INC(sc.pos, 2)
  END;
  a := Named(); b := a;
  sc.SkipBlanks;
  IF (placement = Over) & (sc.Ch() = ",") THEN INC(sc.pos); b := Named() END;
  e := NewEvent(Note);
  e.placement := placement; e.from := a; e.to := b;
  e.text := Text()
END NoteStmt;

(* "links", "link", "properties" or "details", w, which is ignored *)
PROCEDURE Ignored(w: ARRAY OF CHAR): BOOLEAN;
  VAR k: LONGINT; ch: CHAR; a: Actor; t: F.Label;
BEGIN
  IF ~Kw(w) THEN RETURN FALSE END;
  k := L.Length(w);
  IF ~L.IsBlank(sc.Peek(k)) THEN RETURN FALSE END;
  WHILE L.IsBlank(sc.Peek(k)) DO INC(k) END;
  ch := sc.Peek(k);
  IF (ch = 0X) OR (ch = "/") OR (ch = "\") OR (ch = "+") OR (ch = "(") OR (ch = ")")
    OR (ch = "<") OR (ch = ">") OR (ch = ":") OR (ch = 0AX) OR (ch = ",") OR (ch = ";")
    OR (ch = "-") THEN RETURN FALSE
  END;
  INC(sc.pos, L.Length(w));
  a := Named(); t := Text();
  RETURN TRUE
END Ignored;

PROCEDURE BlockStmt(kind: INTEGER);
  VAR e: Event; lab: F.Label; s: Str; l: F.Line;
BEGIN
  IF depth = MaxDepth THEN sc.Error("blocks are too deeply nested") END;
  lab := RestOfLine();
  e := NewEvent(BlockStart); e.block := kind;
  IF kind = Rect THEN
    IF lab = NIL THEN sc.Error("expected a colour") END;
    s := NIL; l := lab.lines;
    WHILE l # NIL DO
      IF s = NIL THEN s := l.text ELSE s := C.CatS(s, l.text) END;
      l := l.next
    END;
    e.fill := Colour(s)
  ELSE e.text := lab
  END;
  open[depth] := kind; INC(depth)
END BlockStmt;

PROCEDURE SectionStmt(w: ARRAY OF CHAR; k1, k2: INTEGER);
  VAR e: Event; p: LONGINT;
BEGIN
  p := sc.pos;
  IF (depth = 0) OR (open[depth - 1] # k1) & (open[depth - 1] # k2) THEN
    IF k1 = Alt THEN sc.ErrorAt(p, '"else" is only for an alt block')
    ELSIF k1 = Par THEN sc.ErrorAt(p, '"and" is only for a par block')
    ELSE sc.ErrorAt(p, '"option" is only for a critical block')
    END
  END;
  INC(sc.pos, L.Length(w));
  e := NewEvent(Section); e.block := open[depth - 1];
  e.text := RestOfLine()
END SectionStmt;

(* Whether s is w, which is in lower case, in any case *)
PROCEDURE IsWordI(s: Str; w: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(w)) & (w[i] # 0X) DO
    IF Lower(s[i]) # w[i] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN s[i] = 0X
END IsWordI;

PROCEDURE BoxStmt;
  VAR lab, title: F.Label; l: F.Line; s, w: Str; i, start: LONGINT; fill: LONGINT; b: Box;
BEGIN
  IF box # NIL THEN sc.Error("a box cannot be in a box") END;
  lab := RestOfLine();
  fill := NoColour; title := lab;
  IF lab # NIL THEN
    s := lab.lines.text;
    (* the colour: "rgb(...)", "rgba(...)", "hsl(...)", "hsla(...)" or a word *)
    i := 0;
    IF ((Lower(s[0]) = "r") & (Lower(s[1]) = "g") & (Lower(s[2]) = "b")
      OR (Lower(s[0]) = "h") & (Lower(s[1]) = "s") & (Lower(s[2]) = "l")) THEN
      i := 3; IF Lower(s[i]) = "a" THEN INC(i) END;
      WHILE L.IsBlank(s[i]) DO INC(i) END;
      IF s[i] = "(" THEN
        WHILE (s[i] # 0X) & (s[i] # ")") DO INC(i) END;
        IF s[i] = ")" THEN INC(i) END
      ELSE i := 0
      END
    END;
    IF i = 0 THEN WHILE L.IsWordChar(s[i]) DO INC(i) END END;
    IF i > 0 THEN
      w := L.Sub(s^, 0, i);
      fill := Colour(w);
      IF (fill # NoColour) OR IsWordI(w, "transparent") THEN
        start := i; WHILE L.IsBlank(s[start]) DO INC(start) END;
        IF (s[start] = 0X) & (lab.lines.next = NIL) THEN title := NIL
        ELSE
          l := lab.lines;
          l.text := L.Sub(s^, start, L.Length(s^) - start);
          IF l.style # NIL THEN l.style := NIL END;
          title := lab
        END
      END
    END
  END;
  NEW(b); b.title := title; b.fill := fill; b.index := d.nBoxes; INC(d.nBoxes); b.next := NIL;
  IF d.boxes = NIL THEN d.boxes := b ELSE d.lastBox.next := b END;
  d.lastBox := b;
  box := b;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN sc.Error('a box has no "end"') END;
    IF Kw("end") THEN INC(sc.pos, 3); ExpectEnd; EXIT
    ELSIF Kw("participant") THEN INC(sc.pos, 11); ParticipantStmt(Participant, FALSE)
    ELSIF Kw("actor") THEN INC(sc.pos, 5); ParticipantStmt(Person, FALSE)
    ELSIF Kw("destroy") THEN INC(sc.pos, 7); DestroyStmt
    ELSE sc.Error("only participants can be in a box")
    END
  END;
  box := NIL
END BoxStmt;

PROCEDURE Title;
  VAR lab: F.Label;
BEGIN
  IF sc.Ch() = ":" THEN INC(sc.pos) END;
  lab := RestOfLine();
  IF lab # NIL THEN d.g.title := lab END
END Title;

PROCEDURE Statement;
  VAR p: LONGINT; alias, config: BOOLEAN; id: Str; kind: INTEGER; e: Event;
BEGIN
  p := sc.pos;
  IF Kw("participant") THEN INC(sc.pos, 11); ParticipantStmt(Participant, FALSE)
  ELSIF Kw("actor") THEN INC(sc.pos, 5); ParticipantStmt(Person, FALSE)
  ELSIF Kw("create") THEN
    INC(sc.pos, 6); sc.SkipBlanks;
    IF Kw("participant") THEN INC(sc.pos, 11); ParticipantStmt(Participant, TRUE)
    ELSIF Kw("actor") THEN INC(sc.pos, 5); ParticipantStmt(Person, TRUE)
    ELSE sc.Error('expected "participant" or "actor"')
    END
  ELSIF Kw("destroy") THEN INC(sc.pos, 7); DestroyStmt
  ELSIF Kw("box") THEN INC(sc.pos, 3); BoxStmt
  ELSIF Kw("activate") OR Kw("deactivate") THEN
    IF Kw("activate") THEN INC(sc.pos, 8); kind := Activate
    ELSE INC(sc.pos, 10); kind := Deactivate
    END;
    sc.SkipBlanks; p := sc.pos;
    id := IdName(alias, config);
    IF alias OR config THEN sc.Error("unexpected text") END;
    ExpectEnd;
    Activation(kind, Define(id, NIL, NoType, p), p)
  ELSIF Kw("autonumber") THEN INC(sc.pos, 10); Autonumber
  ELSIF Kw("note") THEN INC(sc.pos, 4); NoteStmt; ExpectEnd
  ELSIF Kw("loop") THEN INC(sc.pos, 4); BlockStmt(Loop)
  ELSIF Kw("opt") THEN INC(sc.pos, 3); BlockStmt(Opt)
  ELSIF Kw("alt") THEN INC(sc.pos, 3); BlockStmt(Alt)
  ELSIF Kw("par_over") THEN INC(sc.pos, 8); BlockStmt(ParOver)
  ELSIF Kw("par") THEN INC(sc.pos, 3); BlockStmt(Par)
  ELSIF Kw("critical") THEN INC(sc.pos, 8); BlockStmt(Critical)
  ELSIF Kw("break") THEN INC(sc.pos, 5); BlockStmt(Break)
  ELSIF Kw("rect") THEN INC(sc.pos, 4); BlockStmt(Rect)
  ELSIF Kw("else") THEN SectionStmt("else", Alt, Alt)
  ELSIF Kw("and") THEN SectionStmt("and", Par, ParOver)
  ELSIF Kw("option") THEN SectionStmt("option", Critical, Critical)
  ELSIF Kw("end") THEN
    IF depth = 0 THEN sc.Error('an "end" with no block to end') END;
    INC(sc.pos, 3); DEC(depth);
    e := NewEvent(BlockEnd); e.block := open[depth];
    ExpectEnd
  ELSIF LookingAtI("title") & ((sc.Peek(5) = ":") OR L.IsBlank(sc.Peek(5))) THEN
    INC(sc.pos, 5); Title
  ELSIF Kw("acctitle") OR Kw("accdescr") THEN F.Accessibility
  ELSIF Ignored("links") OR Ignored("link") OR Ignored("properties") OR Ignored("details") THEN
    ExpectEnd
  ELSE Message; ExpectEnd
  END
END Statement;

(* Whether the scanner's text, after front matter and comments, starts
   with "sequenceDiagram" *)
PROCEDURE IsSeq*(s: L.Scanner): BOOLEAN;
  VAR save: LONGINT; r: BOOLEAN;
BEGIN
  save := s.pos;
  F.SkipFrontMatter(s);
  sc := s;
  r := Kw("sequencediagram");
  s.pos := save;
  RETURN r
END IsSeq;

(* Reads the sequence diagram in s's text into diagram *)
PROCEDURE Read*(s: L.Scanner; VAR diagram: Diagram);
  VAR q: Y.Pair;
BEGIN
  NEW(d); diagram := d;
  F.Begin(s, F.Seq, d.g); sc := s;
  d.actors := NIL; d.nActors := 0; d.boxes := NIL; d.nBoxes := 0;
  d.events := NIL; d.nEvents := 0; d.lastActor := NIL; d.lastBox := NIL; d.lastEvent := NIL;
  box := NIL; lastCreated := NIL; lastDestroyed := NIL; depth := 0;
  numbering := FALSE; number := 100; step := 100;
  q := Y.Find(d.g.config, "config.sequence.showSequenceNumbers");
  IF (q # NIL) & L.Is(q.value, "true") THEN numbering := TRUE END;
  q := Y.Find(d.g.config, "config.sequence.mirrorActors");
  d.mirror := (q = NIL) OR ~L.Is(q.value, "false");
  IF ~Kw("sequencediagram") THEN sc.Error("expected sequenceDiagram") END;
  INC(sc.pos, 15);
  ExpectEnd;
  LOOP
    SkipSpace;
    IF sc.AtEnd() THEN EXIT END;
    Statement
  END;
  IF depth > 0 THEN sc.Error('a block has no "end"') END;
  IF lastCreated # NIL THEN sc.Error("the participant created has no message creating it") END;
  IF lastDestroyed # NIL THEN sc.Error("the participant destroyed has no message destroying it") END
END Read;

END PmSeq.
