MODULE PmGanttLayout;
(* PmGanttLayout: a Gantt chart, PmGantt's, laid out as Mermaid's
   ganttRenderer.js lays it out, in its pixels, taken at the labels'
   size, the task text's 11 pixels (gantt.fontSize) to the size.
   Lengths are in points, y down; a text's y is its middle, 0.3 of its
   size above Mermaid's baseline.

   The chart is W pixels wide: gantt.useWidth, else --width, else 1200
   (decision 15); and as high as two topPaddings and a row for each
   task, barHeight and barGap high, but vertical markers. In compact
   mode each section's tasks are packed into as few rows as hold them
   without overlap, first come first placed, in sections taken in
   JavaScript's Object.keys order. The time scale runs from the first
   start to the last end, over W less leftPadding and rightPadding,
   rounded to whole pixels.

   Drawn, in order: the excluded days, as ranges of whole days, unless
   the tasks span more than five years; the grid, lines at the ticks
   (tickInterval's, if it has one Mermaid takes, else d3's automatic
   ones) from gridLineStartPadding down to 50 pixels above the bottom,
   their labels, by axisFormat, below, and above too with topAxis; the
   background rows, one per row, in their section's colour; the tasks,
   by their start, vertical markers last: bars, milestones (squares
   turned 45 degrees and scaled by 0.8) and vertical markers, each
   with its text inside its bar or, if wider than the bar, outside it,
   right or left as there is room; the section names, at the left,
   each in the middle of its rows; the title; and the today line,
   unless todayMarker is off.

   Everything is as Mermaid has it but that what Mermaid's SVG clips,
   outside the chart, is left out: the today line, when it is outside,
   and in compact mode, where there are fewer rows than tasks, the
   part of a vertical marker below the chart, and its text, when all
   of it is below. *)

IMPORT L := PmLex, F := PmFlow, M := PmMetrics, Y := PmYaml, G := PmGantt,
  T := PmGanttTime, S := PmGanttScale;

CONST
  MermaidSize* = 11;     (* gantt.fontSize's default, at the labels' size *)
  Drop* = 0.3;           (* a text's middle, above its baseline, of its size *)
  (* where a task's text is *)
  Inside* = 0; OutsideRight* = 1; OutsideLeft* = 2; VertText* = 3;
  (* in Mermaid's pixels *)
  DefaultW = 1200;
  Radius* = 3;           (* the bars' corners *)
  TickSize* = 10;        (* the tick labels *)
  TickPad = 3;           (* between the axis and its labels *)
  AxisFromBottom = 50;   (* the bottom axis, above the bottom *)
  TitleSize* = 18;
  VertSize* = 15;        (* a vertical marker's text *)
  VertTextBelow = 60;    (* its baseline, below the last row *)
  VertW = 0.08;          (* a vertical marker's width, of barHeight *)
  TextGap = 5;           (* between a bar and its text outside it *)
  SectionX* = 10;        (* the section names' left *)
  MaxTicks = 10000;      (* Mermaid's MAX_TICK_COUNT *)
  MaxYears = 5;          (* excluded days are drawn up to this span *)

TYPE
  Str = L.Str;
  Reals* = POINTER TO ARRAY OF REAL;
  Ints* = POINTER TO ARRAY OF INTEGER;
  Labels* = POINTER TO ARRAY OF F.Label;
  Strs* = POINTER TO ARRAY OF Str;
  Tasks* = POINTER TO ARRAY OF G.Task;

  Layout* = POINTER TO LayoutDesc;
  LayoutDesc* = RECORD
    d-: G.Diagram;
    font-: M.Font;
    size-, px-: REAL;        (* the labels' size, a pixel *)
    width-, height-: REAL;
    nss-: INTEGER;           (* numberSectionStyles: the colours *)
    (* the background rows, from x 0, rowW wide, each at rowY, rowH
       high, in its section's colour *)
    nRows-: INTEGER;
    rowY-: Reals; rowColour-: Ints;
    rowW-, rowH-: REAL;
    (* the excluded days: each range from exX, exW wide; all from exY,
       exH high *)
    nEx-: INTEGER;
    exX-, exW-: Reals;
    exY-, exH-: REAL;
    (* the ticks: each one's x and label; the lines from gridY1 down to
       gridY2; the labels' middles at labelY, and with topAxis at
       topLabelY, tickSize high *)
    nTicks-: INTEGER;
    tickX-: Reals; tickLabel-: Strs;
    gridY1-, gridY2-, labelY-: REAL;
    topAxis-: BOOLEAN;
    topY1-, topY2-, topLabelY-: REAL;
    tickSize-: REAL;
    (* the tasks, in the order they are drawn: each one's box, of its
       bar, or its milestone before it is turned, or its vertical
       marker; its colour number; its text, the text's place, its x
       (its left, middle or right, by its place) and middle, and its
       size; and the bars' corners' radius *)
    nTasks-: INTEGER;
    task-: Tasks;
    bx-, by-, bw-, bh-: Reals;
    colour-: Ints;
    text-: Labels;
    place-: Ints;
    tx-, ty-, tsize-: Reals;
    (* where else the text goes if it is wider or narrower than the
       estimate, for a writer that measures it (PmGanttMp): its x
       inside the bar, right of it and left of it; the widths over
       which it goes outside (xRoom) and then left (xRight), for its x;
       and the same for its place (pRoom, pRight), Mermaid's class,
       which differ for a milestone *)
    inX-, rightX-, leftX-, xRoom-, xRight-, pRoom-, pRight-: Reals;
    radius-: REAL;
    (* the section names, each its lines centred at secY, its left at
       secX, sectionFontSize high, a line apart; colour -1 for none *)
    nSections-: INTEGER;
    secText-: Labels; secY-: Reals; secColour-: Ints;
    secX-, secSize-: REAL;
    (* the title, its middle at (titleX, titleY), or NIL *)
    title-: F.Label;
    titleSize-, titleX-, titleY-: REAL;
    (* the today line, from (todayX, todayY1) to (todayX, todayY2), if
       today; todayMarker's style, or "" *)
    today-: BOOLEAN;
    todayX-, todayY1-, todayY2-: REAL;
    todayStyle-: Str
  END;

VAR
  d: G.Diagram;
  barHeight, barGap, topPadding, leftPadding, rightPadding, gridStart,
  fontSize, sectionFontSize, titleTop: LONGREAL;

(* Configuration *)

(* The number in s, as JavaScript's Number() reads a decimal; FALSE if
   s is not one *)
PROCEDURE Number(s: Str; VAR x: LONGREAL): BOOLEAN;
  VAR i: LONGINT; f: LONGREAL; neg, digits: BOOLEAN;
BEGIN
  i := 0; x := 0; neg := FALSE; digits := FALSE;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF (s[i] = "-") OR (s[i] = "+") THEN neg := s[i] = "-"; INC(i) END;
  WHILE L.IsDigit(s[i]) DO x := x * 10 + (ORD(s[i]) - ORD("0")); INC(i); digits := TRUE END;
  IF s[i] = "." THEN
    INC(i); f := 0.1D0;
    WHILE L.IsDigit(s[i]) DO x := x + f * (ORD(s[i]) - ORD("0")); f := f / 10; INC(i); digits := TRUE END
  END;
  WHILE L.IsBlank(s[i]) DO INC(i) END;
  IF neg THEN x := -x END;
  RETURN digits & (s[i] = 0X)
END Number;

(* config.gantt.name, a number, or default *)
PROCEDURE Conf(name: ARRAY OF CHAR; default: LONGREAL): LONGREAL;
  VAR q: Y.Pair; x: LONGREAL;
BEGIN
  q := Y.Find(d.g.config, name);
  IF (q # NIL) & Number(q.value, x) THEN RETURN x END;
  RETURN default
END Conf;

(* config.gantt.name's text, or NIL *)
PROCEDURE ConfStr(name: ARRAY OF CHAR): Str;
  VAR q: Y.Pair;
BEGIN
  q := Y.Find(d.g.config, name);
  IF q # NIL THEN RETURN q.value END;
  RETURN NIL
END ConfStr;

(* Sections *)

(* Whether s is an array index, which Object.keys puts first, by
   value: "0", or digits not starting with "0", below 2^32 - 1 *)
PROCEDURE IsIndex(s: Str; VAR v: HUGEINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  v := 0; i := 0;
  IF ~L.IsDigit(s[0]) OR (s[0] = "0") & (s[1] # 0X) THEN RETURN FALSE END;
  WHILE L.IsDigit(s[i]) DO
    v := v * 10 + (ORD(s[i]) - ORD("0")); INC(i);
    IF v >= 4294967295 THEN RETURN FALSE END
  END;
  RETURN s[i] = 0X
END IsIndex;

(* keys[0 .. n-1], distinct, in insertion order, put in Object.keys
   order: the array indexes by value, then the others as they were *)
PROCEDURE KeysOrder(keys: Strs; n: INTEGER);
  VAR r: Strs; v, w: HUGEINT; i, j, k: INTEGER; s: Str;
BEGIN
  NEW(r, n + 1); k := 0;
  FOR i := 0 TO n - 1 DO
    IF IsIndex(keys[i], v) THEN
      j := k;
      WHILE (j > 0) & IsIndex(r[j - 1], w) & (w > v) DO r[j] := r[j - 1]; DEC(j) END;
      r[j] := keys[i]; INC(k)
    END
  END;
  FOR i := 0 TO n - 1 DO
    IF ~IsIndex(keys[i], v) THEN r[k] := keys[i]; INC(k) END
  END;
  FOR i := 0 TO n - 1 DO s := r[i]; keys[i] := s END
END KeysOrder;

(* Where s is in keys[0 .. n-1], or -1 *)
PROCEDURE Find(keys: Strs; n: INTEGER; s: Str): INTEGER;
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO n - 1 DO
    IF L.Equal(keys[i], s) THEN RETURN i END
  END;
  RETURN -1
END Find;

(* Text *)

(* A label of one line, s, each byte in style *)
PROCEDURE OneLine(s: Str; style: SHORTINT): F.Label;
  VAR lab: F.Label; k, len: LONGINT;
BEGIN
  NEW(lab); lab.n := 1; lab.markdown := FALSE;
  NEW(lab.lines); lab.lines.text := s; lab.lines.underline := FALSE; lab.lines.next := NIL;
  lab.lines.style := NIL;
  IF style # F.Roman THEN
    len := L.Length(s^);
    NEW(lab.lines.style, len + 1);
    FOR k := 0 TO len - 1 DO lab.lines.style[k] := style END;
    lab.lines.style[len] := F.Roman
  END;
  RETURN lab
END OneLine;

(* The ticks *)

(* The interval tickInterval names, if it is one Mermaid takes, a
   whole number, without a leading 0, then millisecond, second,
   minute, hour, day, week or month, and it gives at most MaxTicks
   over [d0, d1] by dayjs's durations *)
PROCEDURE Custom(s: Str; d0, d1: HUGEINT; VAR iv: S.Interval): BOOLEAN;
  CONST Big = 1000000000000000;   (* beyond any field's value *)
  VAR i, j: LONGINT; n: HUGEINT; kind: INTEGER; unit, est: LONGREAL; u: ARRAY 16 OF CHAR;
BEGIN
  IF (s = NIL) OR (s[0] < "1") OR (s[0] > "9") THEN RETURN FALSE END;
  i := 0; n := 0;
  WHILE L.IsDigit(s[i]) DO
    IF n < Big THEN n := n * 10 + (ORD(s[i]) - ORD("0")) END;
    INC(i)
  END;
  IF n > Big THEN n := Big END;
  j := 0;
  WHILE (s[i] # 0X) & (j < LEN(u) - 1) DO u[j] := s[i]; INC(i); INC(j) END;
  u[j] := 0X;
  IF s[i] # 0X THEN RETURN FALSE END;
  IF u = "millisecond" THEN kind := S.Millisecond; unit := 1
  ELSIF u = "second" THEN kind := S.Second; unit := 1000
  ELSIF u = "minute" THEN kind := S.Minute; unit := 60000
  ELSIF u = "hour" THEN kind := S.Hour; unit := 3600000
  ELSIF u = "day" THEN kind := S.Day; unit := T.Day
  ELSIF u = "week" THEN kind := S.Week; unit := 7 * T.Day
  ELSIF u = "month" THEN kind := S.Month; unit := 365 * T.Day / 12
  ELSE RETURN FALSE
  END;
  IF d0 > d1 THEN RETURN FALSE END;
  est := (d1 - d0) / (n * unit);
  IF est > MaxTicks THEN RETURN FALSE END;
  S.Every(kind, n, d.weekday, iv);
  RETURN TRUE
END Custom;

(* The ticks over [d0, d1], on scale s, at left, with their labels *)
PROCEDURE Ticks(l: Layout; VAR s: S.Scale; d0, d1: HUGEINT; left, px: REAL);
  VAR iv: S.Interval; tick: Str; fmt: Str; times: S.Times; n, i: LONGINT;
BEGIN
  IF d.axisFormat # NIL THEN fmt := d.axisFormat
  ELSIF L.Is(d.dateFormat, "D") THEN fmt := L.New("%d")
  ELSE
    fmt := ConfStr("config.gantt.axisFormat");
    IF fmt = NIL THEN fmt := L.New("%Y-%m-%d") END
  END;
  tick := d.tickInterval;
  IF (tick = NIL) OR (tick[0] = 0X) THEN tick := ConfStr("config.gantt.tickInterval") END;
  IF ~Custom(tick, d0, d1, iv) THEN S.Auto(d0, d1, iv) END;
  times := S.Range(iv, d0, d1 + 1, 2 * MaxTicks, n);
  l.nTicks := SHORT(n);
  NEW(l.tickX, n + 1); NEW(l.tickLabel, n + 1);
  FOR i := 0 TO n - 1 DO
    l.tickX[i] := SHORT(left + S.X(s, times[i]) * px);
    S.Format(times[i], fmt^, l.tickLabel[i])
  END
END Ticks;

(* The excluded days *)

(* The ranges of excluded days from d0 to d1, on scale s *)
PROCEDURE Excludes(l: Layout; VAR s: S.Scale; d0, d1: HUGEINT; left, px: REAL);
  VAR t, limit, start, end, a, b: HUGEINT; n, k: LONGINT; open: BOOLEAN; pass: INTEGER;

  (* the end of t's day *)
  PROCEDURE EndOfDay(t: HUGEINT): HUGEINT;
    VAR r: HUGEINT;
  BEGIN
    IF ~T.Add(T.StartOfDay(t), 1, "d", r) THEN r := T.StartOfDay(t) + T.Day END;
    RETURN r - 1
  END EndOfDay;

  PROCEDURE Range;
  BEGIN
    IF pass = 1 THEN
      a := T.StartOfDay(start); b := EndOfDay(end);
      l.exX[k] := SHORT(left + S.X(s, a) * px);
      l.exW[k] := SHORT((S.X(s, b) - S.X(s, a)) * px)
    END;
    INC(k)
  END Range;

BEGIN
  l.nEx := 0;
  IF (d.excludes = NIL) & (d.includes = NIL) THEN RETURN END;
  IF T.Add(d0, MaxYears * 12 + 12, "M", limit) & (d1 >= limit) THEN RETURN END;
  n := 0;
  FOR pass := 0 TO 1 DO
    IF pass = 1 THEN NEW(l.exX, n + 1); NEW(l.exW, n + 1) END;
    k := 0; t := d0; open := FALSE;
    WHILE t <= d1 DO
      IF G.IsExcluded(d, t) THEN
        IF ~open THEN start := t; open := TRUE END;
        end := t
      ELSIF open THEN Range; open := FALSE
      END;
      IF ~T.Add(t, 1, "d", t) THEN t := d1 + 1 END
    END;
    n := k
  END;
  l.nEx := SHORT(n)
END Excludes;

(* Lays out d with its labels at size points, the chart width points
   wide, or 1200 pixels if width is 0 *)
PROCEDURE Make*(diagram: G.Diagram; font: M.Font; size, width: REAL; VAR lay: Layout);
  VAR
    l: Layout; px: REAL; w, h, gap, x, sx, ex, tw, y: LONGREAL;
    t: G.Task; all, sorted: Tasks; ord: POINTER TO ARRAY OF LONGINT;
    nAll, nNon, nCat, nKeys, i, j, k, m, rows: INTEGER;
    cats, keys: Strs; heights: POINTER TO ARRAY OF LONGINT;
    group: Tasks; timeline: POINTER TO ARRAY OF HUGEINT;
    d0, d1, now: HUGEINT; s: S.Scale; seen: BOOLEAN; q: Str; style: SHORTINT;
    useWidth, nss, offset, maxJ: LONGREAL; place: INTEGER; prev: LONGINT;
BEGIN
  d := diagram;
  NEW(l); l.d := d; l.font := font; l.size := size;
  barHeight := Conf("config.gantt.barHeight", 20);
  barGap := Conf("config.gantt.barGap", 4);
  topPadding := Conf("config.gantt.topPadding", 50);
  leftPadding := Conf("config.gantt.leftPadding", 75);
  rightPadding := Conf("config.gantt.rightPadding", 75);
  gridStart := Conf("config.gantt.gridLineStartPadding", 35);
  fontSize := Conf("config.gantt.fontSize", 11);
  sectionFontSize := Conf("config.gantt.sectionFontSize", 11);
  titleTop := Conf("config.gantt.titleTopMargin", 25);
  nss := Conf("config.gantt.numberSectionStyles", 4);
  IF nss < 1 THEN nss := 1 END;
  l.nss := SHORT(ENTIER(nss));
  px := size / MermaidSize; l.px := px;
  gap := barHeight + barGap;
  useWidth := Conf("config.gantt.useWidth", -1);
  IF useWidth >= 0 THEN w := useWidth
  ELSIF width > 0 THEN w := width / px
  ELSE w := DefaultW
  END;
  (* the tasks, in order, and those not vertical markers *)
  nAll := SHORT(d.nTasks);
  NEW(all, nAll + 1); NEW(sorted, nAll + 1); NEW(ord, nAll + 1);
  t := d.tasks; i := 0; nNon := 0;
  WHILE t # NIL DO
    all[i] := t; ord[i] := t.order; INC(i);
    IF ~t.vert THEN INC(nNon) END;
    t := t.next
  END;
  (* the categories: the sections of the tasks, in order *)
  NEW(cats, nAll + 1); nCat := 0;
  FOR i := 0 TO nAll - 1 DO
    IF ~all[i].vert & (Find(cats, nCat, all[i].section) < 0) THEN
      cats[nCat] := all[i].section; INC(nCat)
    END
  END;
  NEW(keys, nCat + 1); NEW(heights, nCat + 1);
  FOR i := 0 TO nCat - 1 DO keys[i] := cats[i] END;
  nKeys := nCat;
  KeysOrder(keys, nKeys);
  (* the rows *)
  IF d.compact THEN
    NEW(group, nAll + 1); NEW(timeline, nAll + 1);
    offset := 0; rows := 0;
    FOR k := 0 TO nKeys - 1 DO
      (* the section's tasks, by start, then order *)
      m := 0;
      FOR i := 0 TO nAll - 1 DO
        t := all[i];
        IF ~t.vert & L.Equal(t.section, keys[k]) THEN
          j := m;
          WHILE (j > 0) & ((group[j - 1].start > t.start)
            OR (group[j - 1].start = t.start) & (group[j - 1].order > t.order)) DO
            group[j] := group[j - 1]; DEC(j)
          END;
          group[j] := t; INC(m)
        END
      END;
      FOR j := 0 TO m - 1 DO timeline[j] := MIN(HUGEINT) END;
      maxJ := 0;
      FOR i := 0 TO m - 1 DO
        t := group[i]; j := 0;
        WHILE (j < m) & ~(t.start >= timeline[j]) DO INC(j) END;
        IF j < m THEN
          timeline[j] := t.end; ord[t.index] := j + ENTIER(offset);
          IF j > maxJ THEN maxJ := j END
        END
      END;
      heights[k] := ENTIER(maxJ) + 1;
      offset := offset + maxJ + 1; rows := rows + SHORT(ENTIER(maxJ)) + 1
    END
  ELSE
    rows := nNon;
    FOR k := 0 TO nKeys - 1 DO
      heights[k] := 0;
      FOR i := 0 TO nAll - 1 DO
        IF ~all[i].vert & L.Equal(all[i].section, keys[k]) THEN INC(heights[k]) END
      END
    END
  END;
  h := 2 * topPadding + rows * gap;
  l.width := SHORT(w * px); l.height := SHORT(h * px);
  (* the scale *)
  IF nAll > 0 THEN
    d0 := all[0].start; d1 := all[0].end;
    FOR i := 1 TO nAll - 1 DO
      IF all[i].start < d0 THEN d0 := all[i].start END;
      IF all[i].end > d1 THEN d1 := all[i].end END
    END
  ELSE d0 := 0; d1 := 0
  END;
  S.Init(s, d0, d1, w - leftPadding - rightPadding);
  (* the excluded days *)
  l.exY := SHORT(gridStart * px); l.exH := SHORT((h - topPadding - gridStart) * px);
  IF nAll > 0 THEN Excludes(l, s, d0, d1, SHORT(leftPadding * px), px) ELSE l.nEx := 0 END;
  (* the grid *)
  l.tickSize := TickSize * px;
  l.gridY1 := SHORT((topPadding + gridStart - AxisFromBottom) * px);
  l.gridY2 := SHORT((h - AxisFromBottom) * px);
  l.labelY := SHORT((h - AxisFromBottom + TickPad + TickSize - Drop * TickSize) * px);
  q := ConfStr("config.gantt.topAxis");
  l.topAxis := d.topAxis OR (q # NIL) & L.Is(q, "true");
  l.topY1 := SHORT(topPadding * px); l.topY2 := SHORT((h - gridStart) * px);
  l.topLabelY := SHORT((topPadding - TickPad - Drop * TickSize) * px);
  IF nAll > 0 THEN Ticks(l, s, d0, d1, SHORT(leftPadding * px), px)
  ELSE l.nTicks := 0
  END;
  (* the tasks, by start, vertical markers last *)
  m := 0;
  FOR i := 0 TO nAll - 1 DO
    t := all[i]; j := m;
    WHILE (j > 0) & (sorted[j - 1].start > t.start) DO sorted[j] := sorted[j - 1]; DEC(j) END;
    sorted[j] := t; INC(m)
  END;
  m := 0;
  FOR i := 0 TO nAll - 1 DO
    IF ~sorted[i].vert THEN all[m] := sorted[i]; INC(m) END
  END;
  FOR i := 0 TO nAll - 1 DO
    IF sorted[i].vert THEN all[m] := sorted[i]; INC(m) END
  END;
  l.nTasks := nAll; l.task := all;
  (* the background rows, one for each row's first task *)
  NEW(l.rowY, nNon + 1); NEW(l.rowColour, nNon + 1); l.nRows := 0;
  l.rowW := SHORT((w - rightPadding / 2) * px); l.rowH := SHORT(gap * px);
  FOR i := 0 TO nNon - 1 DO
    seen := FALSE;
    FOR j := 0 TO i - 1 DO
      IF ord[all[j].index] = ord[all[i].index] THEN seen := TRUE END
    END;
    IF ~seen THEN
      l.rowY[l.nRows] := SHORT((ord[all[i].index] * gap + topPadding - 2) * px);
      k := Find(cats, nCat, all[i].section);
      IF k < 0 THEN k := 0 END;
      l.rowColour[l.nRows] := SHORT(k MOD l.nss);
      INC(l.nRows)
    END
  END;
  (* the bars and their text *)
  NEW(l.bx, nAll + 1); NEW(l.by, nAll + 1); NEW(l.bw, nAll + 1); NEW(l.bh, nAll + 1);
  NEW(l.colour, nAll + 1); NEW(l.text, nAll + 1); NEW(l.place, nAll + 1);
  NEW(l.tx, nAll + 1); NEW(l.ty, nAll + 1); NEW(l.tsize, nAll + 1);
  NEW(l.inX, nAll + 1); NEW(l.rightX, nAll + 1); NEW(l.leftX, nAll + 1);
  NEW(l.xRoom, nAll + 1); NEW(l.xRight, nAll + 1); NEW(l.pRoom, nAll + 1);
  NEW(l.pRight, nAll + 1);
  l.radius := Radius * px;
  FOR i := 0 TO nAll - 1 DO
    t := all[i];
    k := Find(cats, nCat, t.section);
    IF k < 0 THEN k := 0 END;
    l.colour[i] := SHORT(k MOD l.nss);
    sx := S.X(s, t.start); ex := S.X(s, t.end);
    IF t.hasRenderEnd THEN ex := S.X(s, t.renderEnd) END;
    y := ord[t.index] * gap + topPadding;
    IF t.vert THEN
      l.bx[i] := SHORT((sx + leftPadding) * px); l.by[i] := SHORT(gridStart * px);
      l.bw[i] := SHORT(VertW * barHeight * px);
      l.bh[i] := SHORT((nNon * gap + 2 * barHeight) * px)
    ELSIF t.milestone THEN
      l.bx[i] := SHORT((sx + leftPadding + 0.5 * (S.X(s, t.end) - sx) - 0.5 * barHeight) * px);
      l.by[i] := SHORT(y * px); l.bw[i] := SHORT(barHeight * px); l.bh[i] := l.bw[i]
    ELSE
      l.bx[i] := SHORT((sx + leftPadding) * px); l.by[i] := SHORT(y * px);
      l.bw[i] := SHORT((ex - sx) * px); l.bh[i] := SHORT(barHeight * px)
    END;
    (* the text: milestones' in italic, links' in bold *)
    style := F.Roman;
    IF t.milestone THEN style := F.Italic END;
    IF t.clickable THEN style := style + F.Bold END;
    l.text[i] := OneLine(t.text, style);
    tw := M.Width(font, t.text^, 0, L.Length(t.text^), SHORT(fontSize * px)) / px;
    IF t.milestone THEN
      sx := sx + 0.5 * (S.X(s, t.end) - sx) - 0.5 * barHeight; ex := sx + barHeight
    END;
    (* the x, as Mermaid's x *)
    l.inX[i] := SHORT(((ex - sx) / 2 + sx + leftPadding) * px);
    l.rightX[i] := SHORT((ex + leftPadding + TextGap) * px);
    l.leftX[i] := SHORT((sx + leftPadding - TextGap) * px);
    l.xRoom[i] := SHORT((ex - sx) * px); l.xRight[i] := SHORT((w - ex - 1.5 * leftPadding) * px);
    IF t.vert THEN x := S.X(s, t.start) + leftPadding
    ELSIF tw > ex - sx THEN
      IF ex + tw + 1.5 * leftPadding > w THEN x := sx + leftPadding - TextGap
      ELSE x := ex + leftPadding + TextGap
      END
    ELSE x := (ex - sx) / 2 + sx + leftPadding
    END;
    (* the place, as Mermaid's class, from the end, not the end drawn *)
    sx := S.X(s, t.start); ex := S.X(s, t.end);
    IF t.milestone THEN ex := sx + barHeight END;
    l.pRoom[i] := SHORT((ex - sx) * px); l.pRight[i] := SHORT((w - ex - 1.5 * leftPadding) * px);
    IF t.vert THEN place := VertText
    ELSIF tw > ex - sx THEN
      IF ex + tw + 1.5 * leftPadding > w THEN place := OutsideLeft
      ELSE place := OutsideRight
      END
    ELSE place := Inside
    END;
    l.place[i] := place; l.tx[i] := SHORT(x * px);
    IF t.vert THEN
      l.tsize[i] := VertSize * px;
      l.ty[i] := SHORT((gridStart + nNon * gap + VertTextBelow - Drop * VertSize) * px)
    ELSE
      l.tsize[i] := SHORT(fontSize * px);
      l.ty[i] := SHORT((y + barHeight / 2 + (fontSize / 2 - 2) - Drop * fontSize) * px)
    END
  END;
  (* a vertical marker clipped to the chart, as Mermaid's SVG clips
     it, in compact mode; its text left out if all below it *)
  FOR i := 0 TO nAll - 1 DO
    IF all[i].vert THEN
      IF l.by[i] + l.bh[i] > l.height THEN l.bh[i] := l.height - l.by[i] END;
      IF l.bh[i] < 0 THEN l.bh[i] := 0 END;
      IF l.ty[i] - l.tsize[i] / 2 >= l.height THEN l.text[i] := NIL END
    END
  END;
  (* the section names *)
  l.nSections := nKeys; l.secX := SectionX * px; l.secSize := SHORT(sectionFontSize * px);
  NEW(l.secText, nKeys + 1); NEW(l.secY, nKeys + 1); NEW(l.secColour, nKeys + 1);
  prev := 0;
  FOR k := 0 TO nKeys - 1 DO
    l.secText[k] := F.PlainLabel(keys[k]);
    IF k > 0 THEN prev := prev + heights[k - 1] END;
    l.secY[k] := SHORT((heights[k] * gap / 2 + prev * gap + topPadding) * px);
    j := Find(cats, nCat, keys[k]);
    IF j >= 0 THEN l.secColour[k] := SHORT(j MOD l.nss) ELSE l.secColour[k] := -1 END
  END;
  (* the title *)
  l.title := NIL; l.titleSize := TitleSize * px;
  IF (d.g.title # NIL) & (d.g.title.n > 0) THEN
    l.title := d.g.title;
    l.titleX := SHORT(w / 2 * px); l.titleY := SHORT((titleTop - Drop * TitleSize) * px)
  END;
  (* today *)
  l.today := FALSE; l.todayStyle := d.todayMarker;
  IF (nAll > 0) & ~L.Is(d.todayMarker, "off") THEN
    now := T.Now();
    x := S.X(s, now) + leftPadding;
    IF (x >= 0) & (x <= w) THEN
      l.today := TRUE; l.todayX := SHORT(x * px);
      l.todayY1 := SHORT(titleTop * px); l.todayY2 := SHORT((h - titleTop) * px)
    END
  END;
  lay := l
END Make;

END PmGanttLayout.
