MODULE PmEmphasis;
(* PmEmphasis: bold and italic in a markdown string.

   Mermaid gives a markdown string's text to marked and keeps its
   strong and em (handle-markdown-text.ts); everything else is written
   as it was. This is CommonMark's emphasis, as marked follows it:
   runs of "*" or "_" are delimiters, left- and right-flanking as the
   characters around them say, "_" not inside a word; a closer is
   matched with the nearest opener of its character before it, by the
   rule of three; two characters from each make strong, one makes em.
   A backslash before ASCII punctuation makes it a plain character.

   Parse gives the text without the delimiters that were matched and
   without escaping backslashes, and each byte's style: Bold, Italic,
   or both. ASCII punctuation counts as punctuation; other characters,
   UTF-8's bytes among them, count as letters. *)

CONST
  Roman* = 0; Bold* = 1; Italic* = 2; (* styles; Bold + Italic is both *)

  Plain = 0; Delim = 1; Gone = 2;  (* what a byte of the input is *)

TYPE
  Text* = POINTER TO ARRAY OF CHAR;
  Styles* = POINTER TO ARRAY OF SHORTINT;

  Run = RECORD
    start, len: LONGINT;  (* the run's bytes in the input *)
    left, right: LONGINT; (* how many are left at its left and right
                             ends: those not used yet are start + left
                             .. start + len - right - 1 *)
    ch: CHAR;
    open, close, active: BOOLEAN;
    orig: LONGINT         (* its length before any was used *)
  END;

VAR
  runs: POINTER TO ARRAY OF Run;
  kind: POINTER TO ARRAY OF SHORTINT;
  add: POINTER TO ARRAY OF SHORTINT; (* each byte's style bits, ORed *)

PROCEDURE Space(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c = " ") OR (c = 9X) OR (c = 0AX) OR (c = 0DX) OR (c = 0CX)
END Space;

PROCEDURE Punct(c: CHAR): BOOLEAN;
BEGIN
  RETURN (c >= "!") & (c <= "/") OR (c >= ":") & (c <= "@") OR
    (c >= "[") & (c <= "`") OR (c >= "{") & (c <= "~")
END Punct;

(* Parses s[0 .. len-1]: the text without the matched delimiters and
   the escaping backslashes in t[0 .. n-1], each byte's style in
   st[0 .. n-1]; t is 0X-terminated. styled is FALSE if every byte is
   Roman. *)
PROCEDURE Parse*(VAR s: ARRAY OF CHAR; len: LONGINT; VAR t: Text; VAR st: Styles;
  VAR n: LONGINT; VAR styled: BOOLEAN);
  VAR i, j, k, nr, use, a, b: LONGINT; before, after: CHAR;
    lf, rf, found: BOOLEAN; bits: SHORTINT;
BEGIN
  NEW(kind, len + 1); NEW(add, len + 1); NEW(runs, len + 1);
  FOR i := 0 TO len DO kind[i] := Plain; add[i] := 0 END;
  (* escapes and runs *)
  nr := 0; i := 0;
  WHILE i < len DO
    IF (s[i] = "\") & (i + 1 < len) & Punct(s[i + 1]) THEN
      kind[i] := Gone; INC(i, 2)
    ELSIF (s[i] = "*") OR (s[i] = "_") THEN
      j := i; WHILE (j < len) & (s[j] = s[i]) DO kind[j] := Delim; INC(j) END;
      IF i = 0 THEN before := " " ELSE before := s[i - 1] END;
      IF j = len THEN after := " " ELSE after := s[j] END;
      (* an escaped character before is punctuation all the same *)
      lf := ~Space(after) & (~Punct(after) OR Space(before) OR Punct(before));
      rf := ~Space(before) & (~Punct(before) OR Space(after) OR Punct(after));
      runs[nr].start := i; runs[nr].len := j - i; runs[nr].orig := j - i;
      runs[nr].left := 0; runs[nr].right := 0; runs[nr].ch := s[i];
      IF s[i] = "*" THEN runs[nr].open := lf; runs[nr].close := rf
      ELSE
        runs[nr].open := lf & (~rf OR Punct(before));
        runs[nr].close := rf & (~lf OR Punct(after))
      END;
      runs[nr].active := TRUE;
      INC(nr); i := j
    ELSE INC(i)
    END
  END;
  (* each closer, from the left, with the nearest opener before it *)
  FOR k := 0 TO nr - 1 DO
    IF runs[k].close THEN
      LOOP
        IF runs[k].len - runs[k].left - runs[k].right <= 0 THEN EXIT END;
        found := FALSE; j := k - 1;
        WHILE (j >= 0) & ~found DO
          IF runs[j].active & runs[j].open & (runs[j].ch = runs[k].ch) &
             (runs[j].len - runs[j].left - runs[j].right > 0) &
             ~((runs[j].open & runs[j].close OR runs[k].open & runs[k].close) &
               ((runs[j].orig + runs[k].orig) MOD 3 = 0) &
               ~((runs[j].orig MOD 3 = 0) & (runs[k].orig MOD 3 = 0))) THEN
            found := TRUE
          ELSE DEC(j)
          END
        END;
        IF ~found THEN EXIT END;
        IF (runs[j].len - runs[j].left - runs[j].right >= 2) &
           (runs[k].len - runs[k].left - runs[k].right >= 2) THEN
          use := 2; bits := Bold
        ELSE use := 1; bits := Italic
        END;
        (* the opener's last unused, the closer's first unused *)
        a := runs[j].start + runs[j].len - runs[j].right - use;
        b := runs[k].start + runs[k].left;
        FOR i := a TO a + use - 1 DO kind[i] := Gone END;
        FOR i := b TO b + use - 1 DO kind[i] := Gone END;
        FOR i := a + use TO b - 1 DO
          IF add[i] DIV bits MOD 2 = 0 THEN add[i] := add[i] + bits END
        END;
        INC(runs[j].right, use); INC(runs[k].left, use);
        (* the runs between are plain text now *)
        FOR i := j + 1 TO k - 1 DO runs[i].active := FALSE END
      END
    END;
    IF ~runs[k].open THEN runs[k].active := FALSE END
  END;
  (* the text that is left *)
  NEW(t, len + 1); NEW(st, len + 1); n := 0; styled := FALSE;
  FOR i := 0 TO len - 1 DO
    IF kind[i] # Gone THEN
      t[n] := s[i]; st[n] := add[i];
      IF add[i] # Roman THEN styled := TRUE END;
      INC(n)
    END
  END;
  t[n] := 0X; st[n] := Roman;
  kind := NIL; add := NIL; runs := NIL
END Parse;

END PmEmphasis.
