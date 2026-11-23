# pomermaid

pomermaid reads a [Mermaid](https://mermaid.js.org/) diagram and draws
it in one of three forms:

- in **pic**, for groff's ms and mom documents;
- in **MetaPost**, for ConTeXt;
- as **SVG**, for HTML, made by groff from the pic drawing.

It needs no browser and no JavaScript. The labels are set in the
document's own fonts: groff's font files measure them for pic and SVG,
and ConTeXt measures them itself for MetaPost.

It reads flowcharts (`flowchart` and `graph`), state diagrams
(`stateDiagram-v2` and `stateDiagram`), class diagrams
(`classDiagram` and `classDiagram-v2`), entity relationship
diagrams (`erDiagram`), requirement diagrams
(`requirementDiagram`), sequence diagrams (`sequenceDiagram`),
user journeys (`journey`), timelines (`timeline`), Gantt
charts (`gantt`), pie charts (`pie`), quadrant charts
(`quadrantChart`), XY charts (`xychart`), radar charts
(`radar-beta`), sankey diagrams (`sankey-beta`), git graphs
(`gitGraph`) and mindmaps (`mindmap`).
Mermaid's other diagram types are planned, one
after another.

## What it needs

To build it:

- the Peaseblossom Oberon Compiler, `poc`;
- the poc libraries ArgParser, pounicode and poDateTime, installed
  under both size models;
- GNU make (`gmake` on the BSDs).

It builds and passes its tests on Linux, FreeBSD, NetBSD and OpenBSD,
on x86-64, i386 and arm64.

To run it:

- **For every format:** groff's font files (`devpdf` or `devps`), for
  measuring the labels. pomermaid finds them where groff is installed,
  or in `--font-path`.
- **To use pic:** groff with pic (`groff -p`), and the ms or mom
  macros.
- **To use MetaPost:** ConTeXt LMTX.
- **For SVG:** groff with `-Tpdf`, and one of these converters:
  - `mutool`, from MuPDF;
  - `pdftocairo`, from poppler.

NetBSD's own groff, 1.19.2, draws the pic, and pomermaid finds its
fonts, but it has no `-Tpdf`, so SVG needs pkgsrc's groff. FreeBSD
and OpenBSD have no groff of their own: install it from ports or
packages.

## Building and installing

    make
    make test
    make install

`make` builds pomermaid twice, once under each size model, in
`build/O2` and `build/OC`. `make test` runs the unit tests and the case
tests under both. They need no groff, ConTeXt, MuPDF or Mermaid.

`make install` installs these files:

- the `-OC` build, as `$(PREFIX)/bin/pomermaid`;
- the MetaPost macros, as `$(PREFIX)/share/pomermaid/pomermaid.mp`,
  and those for sequence diagrams, `pomermaid-seq.mp`;
- the manual page, as `$(PREFIX)/share/man/man1/pomermaid.1`;
- this documentation and the example filter, in
  `$(PREFIX)/share/doc/pomermaid`.

`PREFIX` is `~/.local` by default. `MODEL=O2` installs the other build,
and `DESTDIR` sets a staging directory for a package. `make uninstall`
removes what was installed.

`make render` draws every test case so that you can look at them:

- with groff, in `build/render/cases.pdf`;
- with ConTeXt, if it is installed, in `build/render/cases-context.pdf`;
- as SVG, if `mutool` or `pdftocairo` is installed, in
  `build/render/svg/`.

## Usage

    pomermaid [OPTIONS] [FILE]

pomermaid reads one diagram from FILE, or from standard input when no
FILE is given, and writes it to standard output, or to `-o FILE`. It
draws one diagram per run.

| Option | Meaning |
|---|---|
| `-t FORMAT`, `--to FORMAT` | `pic`, `mp`, `svg` or `svg-ms` (see below). `dump` and `layout` write the diagram as read and as laid out, for the tests. |
| `-o FILE`, `--output FILE` | Write to FILE. |
| `--font FONT` | The groff font for the labels: `TR` (the default), `HR`, `PR` and so on. |
| `--size N` | The labels' size in points: 10 by default; `10.5` is allowed. |
| `--width LEN` | The widest the diagram may be: 6 inches by default. A unit, `i`, `c` or `p`, may follow the number; `0` means no limit. |
| `--font-path DIRS` | Look for groff's fonts in these directories, separated by colons. These are directories that hold `devpdf` or `devps`. |
| `--mp-macros inline\|input` | For `mp`: copy the macros into each drawing (`inline`, the default) or write `input pomermaid ;` (`input pomermaid-seq ;` for a sequence diagram) (`input`). |
| `--svg-text text\|outline` | For `svg`: keep the labels as text (the default), or draw their glyphs as outlines. |
| `--svg-engine mutool\|pdftocairo` | For `svg`: the converter from PDF to SVG. The default is `mutool` if it is found, else `pdftocairo`. |
| `-v`, `--version` | Show the version. |
| `-h`, `--help` | Show the options. |

The output formats:

- `pic` writes the diagram's colours as `.defcolor` requests, then a
  `.PS` ... `.PE` block. The block sets the labels' size and spacing,
  then restores the document's.
- `mp` writes a `\startMPcode` ... `\stopMPcode` block.
- `svg` writes an SVG document.
- `svg-ms` writes the groff document that the SVG is made from, for
  looking into a problem with the SVG.

Errors in a diagram give its file, line and column. Every error ends
pomermaid with the status pandoc and podoc use for that kind of error:

| Status | Error |
|---|---|
| 1 | a file that cannot be read or written |
| 2 | an unknown option |
| 6 | a bad option value, or more than one FILE |
| 22 | an unknown output format |
| 43 | groff, `mutool` or `pdftocairo` failed |
| 47 | groff, `mutool` or `pdftocairo` was not found |
| 64 | a diagram pomermaid cannot read |
| 97 | the font was not found |

Warnings, such as a colour pomermaid does not know, go to standard
error, and pomermaid goes on.

## What it reads

pomermaid reads Mermaid's flowcharts, as Mermaid 12.3.0 reads them:

- **The first line:** `flowchart` or `graph`, with a direction: `TD`,
  `TB`, `BT`, `LR` or `RL`.
- **Front matter:** a block between `---` lines, before the first line,
  with a `title`, drawn above the diagram, and a `config`. Of the
  configuration, pomermaid uses `flowchart.curve` and the
  `themeVariables` of Mermaid's default theme that colour a flowchart:
  `mainBkg`, `nodeBorder`, `textColor`, `nodeTextColor`, `titleColor`,
  `lineColor`, `edgeLabelBackground`, `clusterBkg`, `clusterBorder`,
  and those they are made from, `border1`, `border2`, `secondBkg` and
  `labelBackground`. `%%{init: ...}%%` directives set the same.
- **Nodes:** an id alone, or an id with a label in one of the bracket
  shapes:
  - `[box]` and `(round)`;
  - `([stadium])` and `[[subroutine]]`;
  - `[(cylinder)]`, `((circle))` and `(((double circle)))`;
  - `>flag]`, `{diamond}` and `{{hexagon}}`;
  - `[/slant/]`, `[\slant\]`, `[/trapezoid\]` and `[\trapezoid/]`.

  A label may be quoted, `["text"]`. It may hold `<br>` and `<br/>`
  for new lines, entities such as `#amp;`, `#35;` and `&amp;`, and any
  UTF-8 text. A label wider than Mermaid's 200 pixels is wrapped at
  spaces.
- **Node metadata:** `A@{ shape: doc, label: "Text" }`, with every
  shape name and alias Mermaid knows, such as `doc`, `lean-r`,
  `cyl`, `fork`, `hourglass`, `bolt` and `brace`. An unknown name is
  an error, as in Mermaid. A few names Mermaid takes but does not
  document, such as `note` and the `bpmn-` shapes, are drawn as the
  nearest documented shape, with a warning.
- **Markdown strings:** ``"`**bold** and _italic_`"``, in bold and
  italic, measured in those fonts and wrapped as Mermaid wraps them.
  The rest of a markdown string is drawn as it is written.
- **Edges:**
  - the lines `-->`, `---`, `-.->`, `-.-`, `==>`, `===` and `~~~`
    (invisible);
  - an arrow, `o` (a circle) or `x` (a cross) at either end, as `<-->`,
    `--o` or `x--x`;
  - longer links, `--->` and `-...->`, for edges that span more ranks;
  - labels as `-->|text|` or `-- text -->`;
  - ids, `A e1@--> B`, and an edge's metadata, `e1@{ curve: linear }`.
- **Curves:** Mermaid's twelve, `basis` (the default), `linear`,
  `step`, `stepBefore`, `stepAfter`, `cardinal`, `catmullRom`,
  `natural`, `monotoneX`, `monotoneY`, `bumpX` and `bumpY`: for every
  edge, from `flowchart.curve`; for one, from its metadata; or from
  `linkStyle ... interpolate`.
- **Chains and groups:** chains such as `A --> B --> C`, and groups
  joined with `&`, as `A & B --> C`.
- **Subgraphs:** `subgraph id [Title]` ... `end`, nested to any depth.
  An edge to or from a subgraph's id goes to or from its box.
  - A subgraph that no edge crosses (an edge to its id does not cross
    it) is laid out on its own, as Mermaid lays it out: in its own
    `direction`, or, without one, left to right in a top-to-bottom
    diagram and top to bottom in any other. In a subgraph that an
    edge crosses, `direction` is ignored, as in Mermaid.
  - `S@{ view: collapsed }` draws the subgraph as one small box with
    its title and three dots. What it holds is not drawn, and edges to
    any of it go to the box.
- **Styles:**
  - `classDef`, `class`, `:::class`, `style` and `linkStyle`;
  - `class` on a subgraph's id, and on an edge's id;
  - the properties `fill`, `stroke`, `stroke-width`,
    `stroke-dasharray` and `color`;
  - colours as `#rgb`, `#rrggbb`, `rgb()`, or one of about 35 CSS
    names;
  - `classDef default` restyles every node.
- **Links:** `click A "url" "tooltip"`, `click A href ...` and
  `_blank` and the other targets. They are drawn only in SVG, as links
  over the nodes; see "SVG".
- **Comments:** `%%` comments.

Read and ignored: `accTitle` and `accDescr`; a node's `icon`, `img`,
`form`, `pos`, `w`, `h` and `constraint` (an `icon` or `image` node is
drawn as a box with its label); an edge's `animate`, `animation` and
`step`; a `click` that calls a function, except for its tooltip in
SVG.

### State diagrams

pomermaid reads Mermaid's state diagrams, as Mermaid 12.3.0 reads
them, and lays them out and draws them as it does flowcharts:

- **The first line:** `stateDiagram-v2` or `stateDiagram`. A diagram
  is drawn top to bottom unless a `direction TB`, `BT`, `LR` or `RL`
  says otherwise. Front matter and directives are read as for a
  flowchart.
- **States:** an id, `state "A name" as id`, and descriptions,
  `id : text`. The first description is the state's name; with more,
  the state is drawn with its name above a line and its descriptions
  below.
- **Transitions:** `a --> b`, with a label, `a --> b : text`. `[*]`
  is the start, before `-->` or alone, or the end, after it; the
  diagram and each composite state have their own.
- **Forks, joins and choices:** `state f <<fork>>`, `<<join>>` and
  `<<choice>>`, or `[[fork]]` and so on.
- **Composite states:** `state id { ... }`, nested to any depth, drawn
  as a box with the state's name in a band at its top, filled in
  alternating colours as they nest. A composite state is laid out top
  to bottom unless a `direction` statement in it says otherwise. `--`
  divides one into concurrent regions, drawn as dashed boxes, each
  with its own `direction`.
- **Notes:** `note left of id : text`, `note right of id : text`, or
  the note's lines up to `end note`, in a box in the note colours,
  joined to its state by a dashed line.
- **Styles:** `classDef`, `class`, `:::class` in a transition, and
  `style`, at the top level; `class` and `style` apply to states
  anywhere, as in Mermaid. `click id "url" "tooltip"` and `click id
  href "url"` make links in SVG.
- **Text:** labels are markdown, as Mermaid reads them: a line end in
  a note breaks the line, and bold and italic are kept.
- **Comments:** `%%` and `#` comments; keywords are read in any case.

Read and ignored: `hide empty description`, `scale`, `accTitle`,
`accDescr`, and floating notes, `note "text" as id`, which Mermaid
does not draw.

### Class diagrams

pomermaid reads Mermaid's class diagrams, as Mermaid 12.3.0 reads
them, and lays them out as it does flowcharts:

- **The first line:** `classDiagram` or `classDiagram-v2`. A diagram
  is drawn top to bottom unless a `direction TB`, `BT`, `LR` or `RL`
  says otherwise. Front matter and directives are read as for a
  flowchart.
- **Classes:** `class Name`, with a label, `class Name["A label"]`,
  members in braces, `class Name { ... }`, or one at a time,
  `Name : +int age`. A class is made, too, by its first use in a
  relation or a note. Names may be in backquotes, and generics are
  written with tildes, `Square~Shape~`, drawn `Square<Shape>`.
- **Members:** a member with parentheses is a method, drawn below the
  attributes. `$` at the end underlines a static member, `*` sets an
  abstract one in italics, and a method's return type, after the
  closing parenthesis, is drawn after a colon.
- **Annotations:** `<<interface>> Name`, or `<<interface>>` inside the
  braces, drawn above the class's name in guillemets.
- **Relations:** `A <|-- B`, with `<|`, `*`, `o`, `<` and `()` (a
  lollipop interface) at either end, or both, and `--` or `..` for a
  solid or dotted line; cardinalities in quotation marks, `A "1" --> "*"
  B`, and a label, `A --> B : text`.
- **Notes:** `note "text"`, alone, or `note for Name "text"`, joined
  to its class by a dotted line; `<br>` breaks a line.
- **Namespaces:** `namespace Name { ... }`, with a label,
  `namespace Name["A label"]`, nested, or written with dots,
  `namespace A.B`, drawn as boxes; with
  `config.class.hierarchicalNamespaces: false`, only the namespaces
  written are drawn.
- **Styles:** `classDef`, `class Name:::class`, `cssClass "A,B" class`,
  and `style`. `click Name href "url" "tooltip"` and `link Name "url"`
  make links in SVG.
- **Comments:** `%%` comments.

Read and ignored: `accTitle`, `accDescr`, and `callback` and `click
... call`, which call functions; a tooltip is kept.

### Entity relationship diagrams

pomermaid reads Mermaid's entity relationship diagrams, as Mermaid
12.3.0 reads them, and lays them out as it does flowcharts:

- **The first line:** `erDiagram`. A diagram is drawn top to bottom
  unless a `direction TB`, `BT`, `LR` or `RL` says otherwise. Front
  matter and directives are read as for a flowchart.
- **Entities:** a name, `CUSTOMER`, or one in quotation marks,
  `"Line item"`, with an alias drawn in its place, `p[Person]` or
  `a["Customer Account"]`. An entity is made, too, by its first use
  in a relationship.
- **Attributes:** in braces after the entity, one to a line: a type,
  a name, keys (`PK`, `FK` and `UK`, separated by commas) and a
  comment in quotation marks, the last two optional, drawn as the rows
  of a table. Generics are written with tildes, `List~int~`, drawn
  `List<int>`, and a name may be in backquotes.
- **Relationships:** `A ||--o{ B : places`, with `|o` or `o|` (zero or
  one), `||` (exactly one), `}o` or `o{` (zero or more) and `}|` or
  `|{` (one or more) at the ends, drawn as crow's feet, bars and
  circles; `--` for a solid (identifying) line and `..`, `.-` or `-.`
  for a dashed one. The ends may be words instead: `one or zero`,
  `zero or one`, `only one`, `one`, `1`, `zero or more`, `zero or
  many`, `many`, `many(0)`, `0+`, `one or more`, `one or many`,
  `many(1)`, `1+`, joined by `to` (solid) or `optionally to` (dashed),
  as in `A only one to zero or more B : has`. The role, after the
  colon, is required; `""` draws none.
- **Subgraphs:** `subgraph id [title]` ... `end`, listing entities,
  nested, with their own `direction`.
- **Styles:** `classDef`, `class A,B name`, `A:::name` and `style`, on
  entities and on subgraphs. An entity's rows are white and pale
  lavender, Mermaid's `rowOdd` and `rowEven` theme variables; an
  entity filled in another colour has every other row in that colour.
- **Comments:** `%%` comments.

Read and ignored: `accTitle` and `accDescr`.

### Requirement diagrams

pomermaid reads Mermaid's requirement diagrams, as Mermaid 12.3.0
reads them, and lays them out as it does flowcharts:

- **The first line:** `requirementDiagram`. A diagram is drawn top to
  bottom unless a `direction TB`, `BT`, `LR` or `RL` says otherwise.
  Front matter and directives are read as for a flowchart.
- **Requirements:** `requirement`, `functionalRequirement`,
  `interfaceRequirement`, `performanceRequirement`,
  `physicalRequirement` or `designConstraint`, a name, which may be in
  quotation marks, and `{`, then one field to a line: `id:`, `text:`,
  `risk:` (`low`, `medium` or `high`) and `verifymethod:` (`analysis`,
  `demonstration`, `inspection` or `test`), any of them left out, and
  `}`.
- **Elements:** `element`, a name and `{`, then `type:` and `docref:`,
  and `}`.
- **Relationships:** `a - satisfies -> b` or `b <- satisfies - a`,
  with `contains`, `copies`, `derives`, `satisfies`, `verifies`,
  `refines` or `traces`. `contains` is drawn as a solid line with a
  circled cross at the container; the others as dashed arrows.
- **Styles:** `classDef`, `class a,b name`, `a:::name`, also after a
  definition's name, and `style`.
- **Comments:** `%%` comments, and `#` comments on lines of their own.

Each box shows its kind, `<<Requirement>>`, its name in bold, and
its fields below a line, one to a line; values are read as markdown.

Read and ignored: `accTitle` and `accDescr`.
### Sequence diagrams

pomermaid reads Mermaid's sequence diagrams, as Mermaid 12.3.0 reads
them, and lays them out in its own simpler way, from the top down:

- **The first line:** `sequenceDiagram`. Front matter and directives
  are read as for a flowchart; `mirrorActors: false` in the
  `sequence` configuration leaves out the participants at the foot.
- **Statements** end at a line's end or `;`. Keywords are read in any
  case.
- **Participants:** `participant name` and `actor name`, with
  `as text` for the text drawn, and `@{ "type": "...", "alias": "..." }`
  for one of Mermaid's types: `participant`, `actor`, `boundary`,
  `control`, `entity`, `database`, `collections` or `queue`. A name
  first seen in a message is a participant. `create participant ...`
  (or `actor`) starts a participant at the next message, which must
  involve it; `destroy name` ends it at the next message.
- **Boxes:** `box colour title` ... `end`, around participants. The
  colour may be left out, or be `transparent`.
- **Messages:** `a->>b: text`, with each of Mermaid's arrows: `->`,
  `-->`, `->>`, `-->>`, `<<->>`, `<<-->>`, `-x`, `--x`, `-)`, `--)`,
  and the half arrows of Mermaid 11. `+` or `-` after the arrow
  activates the target or deactivates the source; `()` before or after
  the arrow draws a central connection.
- **Activations:** `activate name` and `deactivate name`, and the
  `+` and `-` of messages, nested.
- **Notes:** `note left of a: text`, `note right of a: text`,
  `note over a: text` and `note over a,b: text`.
- **Blocks:** `loop`, `opt`, `alt` with `else`, `par` and `par_over`
  with `and`, `critical` with `option`, `break`, and `rect colour`,
  each to its `end`, nested.
- **Numbers:** `autonumber`, `autonumber start`,
  `autonumber start step` and `autonumber off`.
- **Text:** `<br>` for new lines, and entities such as `#35;` and
  `#amp;`, as in flowcharts. `wrap:` and `nowrap:` are read and
  ignored.
- **The title:** `title text` or `title: text`.
- **Comments:** `%%` comments and `#` comments.

Read and ignored: `accTitle`, `accDescr`, `links`, `link`,
`properties` and `details`.

### User journeys

pomermaid reads Mermaid's user journeys, as Mermaid 12.3.0 reads them,
and draws them as Mermaid does: the actors' legend at the left, the
sections above their tasks, the activity line, and below it each
task's face, higher for a higher score, on a dashed line from the
task.

- **The first line:** `journey`. Front matter and directives are read
  as for a flowchart.
- **Statements** end at a line's end or `;`. Keywords are read in any
  case.
- **The title:** `title text`. It is drawn in bold, above the
  sections.
- **Sections:** `section name`. The tasks after it are in it, until
  the next. Tasks before the first section are in none; a section
  named again after another is drawn again.
- **Tasks:** `name: score: person, person`. The score is a number,
  read as JavaScript reads one, so `: :` is 0; 5 is the best and 1
  the worst. The people may be left out, with their `:`; each person
  is an actor, shown in the legend once, in the order of their names'
  bytes.
- **Text:** a task's or a section's text is wrapped to its box, and
  the boxes grow to hold the longest; an actor's name is wrapped at
  360 pixels. Entities such as `#35;` are read as in flowcharts.
- **Colours:** Mermaid's: each section, and its tasks, in the fill for
  its number, and the actors in turn in six colours. The theme
  variables `fillType0` to `fillType7`, `actor0` to `actor5` and
  `faceColor` change them.
- **Comments:** `%%` comments and `#` comments.

Read and ignored: `accTitle` and `accDescr`.

### Timelines

pomermaid reads Mermaid's timelines, as Mermaid 12.3.0 reads them, and
draws them as Mermaid does. Left to right, the default: the sections
in a row, each over its periods; the periods in a row, 200 pixels
apart; the activity line, an arrow, below them; and each period's
events stacked below it, on a dashed line down from it. Top down: each
section across the drawing, followed by its periods, left of a
vertical axis, with each period's events right of the axis, on dashed
lines from it.

- **The first line:** `timeline`, `timeline LR` or `timeline TD` (top
  down). Front matter and directives are read as for a flowchart.
  Keywords are read in any case.
- **The title:** `title text`, the rest of the line. It is drawn in
  bold, above the drawing.
- **Sections:** `section name`. The periods after it are in it, until
  the next. A section's name has no `:`. With sections, periods before
  the first are not drawn, as in Mermaid; pomermaid warns of them.
- **Periods:** a line of text, up to a `:`, a `#` comment or the end
  of the line.
- **Events:** `: event`, after a period, on its line or on the lines
  after it; each `: ` starts another event. A `:` not followed by a
  blank is part of the event.
- **Text** is wrapped to its box, and the boxes of a kind grow to
  hold the highest. Entities such as `#35;` are read as in flowcharts;
  `;` is text.
- **Colours:** Mermaid's: each section and what is in it, or, without
  sections, each period and its events, in the colour for its number,
  0 to 11; events a little brighter. With the `timeline` configuration
  `disableMulticolor: true`, periods without sections are all in the
  first colour. The theme variables `cScale0` to `cScale11` (fills),
  `cScaleLabel0` to `cScaleLabel11` (text) and `cScaleInv0` to
  `cScaleInv11` (the line along a box's bottom) change them.
- **Comments:** `%%` comments and `#` comments.

Read and ignored: `accTitle` and `accDescr`.

### Gantt charts

pomermaid reads Mermaid's Gantt charts, as Mermaid 12.3.0 reads them,
and draws them as Mermaid does: a row for each task, a bar from its
start to its end on a time axis, the rows' backgrounds in bands by
section, each section's name at the left, the grid and the axis's
labels below (or above too, with `topAxis`), and the title at the top.
The chart is `--width` wide, 1200 pixels if it is not given;
`gantt.useWidth` in the configuration sets it instead.

- **The first line:** `gantt`. Front matter and directives are read as
  for a flowchart; `displayMode: compact` packs the tasks of a section
  into as few rows as do not overlap. Keywords are read in any case.
- **The title:** `title text`. **Sections:** `section name`.
- **Tasks:** `name : data`, the data up to a `#`, `;` or the end of
  the line: first any of the tags `active`, `done`, `crit`,
  `milestone` and `vert`, then the end; the start and the end; or an
  id, the start and the end. A task with only its end starts where the
  task before it ends.
  - A start is a date, read with `dateFormat`, or `after id ...`, the
    latest end of those tasks.
  - An end is a date, a duration (`3d`, `1.5w`, `2M`, `30m`, `10ms`;
    `y`, `M`, `w`, `d`, `h`, `m`, `s` and `ms`), or `until id ...`,
    the earliest start of those tasks.
  - A milestone is drawn as a diamond at its start, a `vert` task as a
    vertical line across the chart, labelled below it.
- **Dates:** `dateFormat`, dayjs's tokens (`YYYY-MM-DD`, the default;
  `x` and `X` for Unix times; `MMM`, `Do`, `HH:mm` and the others),
  read strictly, in local time; a start that does not fit is read as
  JavaScript's `Date` reads it, and one it cannot read is an error.
  An end that is neither a date nor a duration is a zero duration,
  with a warning. `inclusiveEndDates` makes a date given as an end
  include its day.
- **Excluded days:** `excludes`, dates, weekday names, `weekends`;
  `includes`, dates that are not excluded; `weekend friday` or
  `weekend saturday`. A task's end moves past the excluded days it
  covers, and they are shaded in the chart.
- **The axis:** `axisFormat`, d3's `strftime` formats (`%Y-%m-%d`, the
  default); `tickInterval`, a number and `millisecond`, `second`,
  `minute`, `hour`, `day`, `week` or `month` (else the ticks are
  d3's); `weekday monday` ... `weekday sunday`, the weeks' first day
  for `week`; `topAxis`.
- **Today:** a red line at today's date, if it is in the chart; today
  is from `SOURCE_DATE_EPOCH`, else the clock. `todayMarker off`
  leaves it out; `todayMarker` with a style (`stroke-width:5px,
  stroke:#0f0`) changes it.
- **Links:** `click id href "link"` links the task, in SVG; `click id
  call name()` is read and has no link. A task named by a `click` has
  its text in `taskTextClickableColor`.
- **Configuration:** `gantt`'s `barHeight`, `barGap`, `topPadding`,
  `leftPadding`, `rightPadding`, `gridLineStartPadding`, `fontSize`,
  `sectionFontSize`, `titleTopMargin`, `numberSectionStyles`,
  `axisFormat`, `tickInterval`, `topAxis` and `useWidth`, in Mermaid's
  pixels, scaled as the other diagrams' are.
- **Colours:** the default theme's, each changed by its theme
  variable: `sectionBkgColor`, `altSectionBkgColor`,
  `sectionBkgColor2`, `excludeBkgColor`, `gridColor`,
  `todayLineColor`, `vertLineColor`, `taskBkgColor`,
  `taskBorderColor`, `activeTaskBkgColor`, `activeTaskBorderColor`,
  `doneTaskBkgColor`, `doneTaskBorderColor`, `critBkgColor`,
  `critBorderColor`, `taskTextColor`, `taskTextLightColor`,
  `taskTextOutsideColor`, `taskTextDarkColor` and
  `taskTextClickableColor`.
- **Task text** is drawn in its bar, or beside it, right or left,
  where it does not fit, as Mermaid places it. In MetaPost, the place
  is chosen from ConTeXt's width of the text.
- **Comments:** `%%` comments, and `#` ends a task's data.

Read and ignored: `accTitle` and `accDescr`.

### Pie charts

pomermaid reads Mermaid's pie charts, as Mermaid 12.3.0 reads them,
and draws them as Mermaid does: a circle 185 pixels in radius, each
section a slice, clockwise from the top, in the order given, with its
percentage of the whole in it; the legend, a coloured square and the
section's label for each; and the title above the pie.

- **The first line:** `pie`, then `showData`, which puts each value in
  the legend after its label, in brackets. Front matter and directives
  are read as for a flowchart.
- **The title:** `title text`, on the first line or a line of its own.
- **Sections:** `"label" : value`, the label in double or single
  quotation marks, the value a whole number or a decimal (`42`,
  `42.5`; not `-1`, `.5`, `1e3` or `05`), one to a line. A negative
  value is an error. A label given again is ignored, as Mermaid
  ignores it. In a label, `\` escapes the next character; `\n`,
  `\t` and the other control characters' escapes are drawn as a blank.
- **Slices:** a section of less than 1% of the sum is in the legend
  but has no slice, and the others fill the circle. Each slice's
  percentage, of the sum of all the sections, is rounded to a whole
  number.
- **Configuration:** `pie`'s `textPosition` (where the percentages
  are, from 0 at the centre to 1 at the edge; 0.75 by default),
  `donutHole` (a hole in the middle, that part of the radius, up to
  0.9), `legendPosition` (`right`, the default, `left`, `top`,
  `bottom` or `center`) and `highlightSlice` (the label of a slice
  drawn larger and opaque).
- **Colours:** the default theme's, each changed by its theme
  variable: `pie1` to `pie12` (the sections', in turn),
  `pieStrokeColor`, `pieOuterStrokeColor`, `pieTitleTextColor`,
  `pieSectionTextColor` and `pieLegendTextColor`; `pieStrokeWidth`
  and `pieOuterStrokeWidth`, in pixels; `pieOpacity`, the slices'
  (0.7).
- **In MetaPost,** the legend's place, and the drawing's width, are
  worked out from ConTeXt's widths of its text and of the title.
- **Comments:** `%%` comments.

Read and ignored: `accTitle` and `accDescr`.

### Quadrant charts

pomermaid reads Mermaid's quadrant charts (`quadrantChart`), as
Mermaid 12.3.0 reads them, and draws them as Mermaid does: a square
of four quadrants, 500 pixels across, each with its text; the points,
each a circle with its text below it; the axes' texts; and the title
above.

- **Keywords** are read in any case. A statement ends at the end of
  the line or at `;`.
- **The title:** `title text`; the rest of the line, `;` and `%%`
  too, is the title.
- **Axes:** `x-axis left --> right`, or `x-axis left`, or
  `x-axis left -->`, which draws `left ⟶`; `y-axis bottom --> top`
  likewise, its texts turned to read upward. The arrow is two or more
  `-` and a `>`. An axis with both texts has them in the middle of its
  halves; with one, the text starts at the quadrants' corner. The x
  axis is at the top, or at the bottom when there are points.
- **Quadrants:** `quadrant-1 text` to `quadrant-4 text`: 1 is the top
  right, 2 the top left, 3 the bottom left, 4 the bottom right. Their
  texts are in the middle of the quadrants, or at their top when there
  are points.
- **Points:** `text: [x, y]`, x and y from 0 to 1 (`1`, or `0` or
  `0.` and digits), across the quadrants from the bottom left; or
  `text:::class: [x, y]`; then styles, if any: `radius: 10`,
  `color: #ff3300`, `stroke-color: #10f0f0` and `stroke-width: 5px`,
  separated by commas. A colour without `#` is drawn in the default.
  A point's own styles override its class's.
- **Classes:** `classDef name styles`, the same styles; a later
  `classDef` of a name replaces an earlier one.
- **Texts** are words, digits, blanks and punctuation, but not
  `:`, `;`, `( ) [ ] < > { } | @ ~ ^`, an arrow or a keyword, and do
  not start with `-`. A text may start with a string in quotation
  marks, `"..."`, or a markdown string, `` "`...`" ``, drawn as it is
  written.
- **Configuration:** `quadrantChart`'s `chartWidth`, `chartHeight`,
  `titlePadding`, `titleFontSize`, `quadrantPadding`,
  `quadrantTextTopPadding`, `quadrantLabelFontSize`,
  `xAxisLabelPadding`, `yAxisLabelPadding`, `xAxisLabelFontSize`,
  `yAxisLabelFontSize`, `pointTextPadding`, `pointLabelFontSize`,
  `pointRadius`, `quadrantInternalBorderStrokeWidth`,
  `quadrantExternalBorderStrokeWidth`, all in pixels, the quadrants'
  text 16 of them to `--size`; `xAxisPosition` (`top` or `bottom`) and
  `yAxisPosition` (`left` or `right`).
- **Colours:** the default theme's, each changed by its theme
  variable: `quadrant1Fill` to `quadrant4Fill`, `quadrant1TextFill` to
  `quadrant4TextFill`, `quadrantPointFill` (the points' fill and
  outline), `quadrantPointTextFill`, `quadrantXAxisTextFill`,
  `quadrantYAxisTextFill`, `quadrantTitleFill`,
  `quadrantInternalBorderStrokeFill` and
  `quadrantExternalBorderStrokeFill`.
- **Text the chart cannot hold,** a long title or a point's text at
  its edge, widens the drawing (decision 18).
- **Comments:** `%%` comments.

Read and ignored: `accTitle` and `accDescr`.

### XY charts

pomermaid reads Mermaid's XY charts (`xychart`, or `xychart-beta`),
as Mermaid 12.3.0 reads them, and draws them as Mermaid does: a
chart 700 by 500 pixels, the title above, the axes with their ticks,
labels and titles, the bars and lines in the plot, and a legend of
the plots that have titles, unless `showLegend` is false.

- **The first line:** `xychart`, or `xychart-beta`, then `vertical`
  or `horizontal`; a horizontal chart has its x axis on the left and
  its bars across.
- **Keywords** are read in any case. A statement ends at the end of
  the line or at `;`.
- **The title:** `title text`.
- **The x axis:** `x-axis text`, its title; `x-axis [a, b, ...]`,
  categories; or `x-axis n --> m`, a range; with a title before the
  categories or the range, or not. Without categories or a range,
  the axis counts the data's points, 1, 2 and on.
- **The y axis:** `y-axis text`, `y-axis n --> m`, or both. Without
  a range, the axis spans the data, as Mermaid's does.
- **Plots:** `bar [n, ...]` and `line [n, ...]`, with a title before
  the data or not, drawn in the order written. In a line's data, a
  number may have a string after it, `[5 "start", 7, ...]`, the
  point's label.
- **Texts** are strings in quotation marks, `"..."`; markdown strings,
  `` "`...`" ``, drawn as they are written; or words of letters,
  digits and `+ = * # _ . & -`, joined without the blanks between
  them, as Mermaid's lexer joins them.
- **Configuration:** `xyChart`'s `width`, `height`, `titleFontSize`,
  `titlePadding`, `showTitle`, `showLegend`, `legendFontSize`,
  `legendPadding`, `showDataLabel`, `showDataLabelOutsideBar`,
  `plotReservedSpacePercent` and `chartOrientation`; and `xAxis`'s and
  `yAxis`'s `showLabel`, `labelFontSize`, `labelPadding`,
  `showTitle`, `titleFontSize`, `titlePadding`, `showTick`,
  `tickLength`, `tickWidth`, `showAxisLine`, `axisLineWidth` and
  `labelRotation` (degrees, clockwise). Sizes are in pixels, 16 of
  them to `--size`.
- **Colours:** the default theme's, each changed by its theme
  variable: `xyChart.backgroundColor`, `titleColor`,
  `dataLabelColor`, `legendTextColor`, `xAxisTitleColor`,
  `xAxisLabelColor`, `xAxisTickColor`, `xAxisLineColor`, the same
  four for `yAxis`, and `plotColorPalette`, colours separated by
  commas, one for each plot in turn.
- **Text the chart cannot hold** widens the drawing (decision 19).
- **Comments:** `%%` comments.

Read and ignored: `accTitle` and `accDescr`.

### Radar charts

pomermaid reads Mermaid's radar charts (`radar-beta`), as Mermaid
12.3.0 reads them, and draws them as Mermaid does: a chart 600 by 600
pixels in margins of 50, its axes from the centre, the first at 12
o'clock and the others clockwise, its graticule's rings, a closed
curve for each set of values, a legend at the top right, and the
title above.

- **The first line:** `radar-beta`, or `radar-beta:`. Keywords are
  read in this case only. Statements end at the end of the line, or
  follow each other on one.
- **The title:** `title text`, the rest of the line.
- **Axes:** `axis a, b["Label"], c`, each a name and, in brackets, a
  string, its label; without one, the name is its label. Several
  `axis` statements add to the axes before.
- **Curves:** `curve a["Label"]{1, 2, 3}`, a value for each axis in
  order; or `curve b{x: 1, y: 2, z: 3}`, each value with its axis's
  name, `:` if wanted, in any order. Line ends may come inside the
  braces. A curve without a value for each axis is not drawn, but is
  in the legend, as in Mermaid.
- **Options,** separated by commas or on lines of their own:
  `showLegend true|false`, `ticks n` (the rings, at most 32),
  `max n`, `min n` (values are clipped to them; `max` is the greatest
  value if not given) and `graticule circle|polygon` (circles, else
  polygons with a corner on each axis, and straight curves).
- **Names** are letters, digits, `_` and `-`; one that is a keyword,
  or starts with `true`, `false`, `circle`, `polygon` or `title`, is
  not read, as Mermaid's lexer does not read it. **Numbers** have no
  sign and no leading 0.
- **Configuration:** `radar`'s `width`, `height`, `marginTop`,
  `marginRight`, `marginBottom`, `marginLeft`, `axisScaleFactor`,
  `axisLabelFactor` and `curveTension`. Sizes are in pixels, 16 of
  them to `--size`.
- **Colours:** the default theme's `cScale0` to `cScale11`, one for
  each curve in turn; and the theme variables `radar.axisColor`,
  `axisStrokeWidth`, `axisLabelFontSize`, `curveOpacity`,
  `curveStrokeWidth`, `graticuleColor`, `graticuleStrokeWidth`,
  `graticuleOpacity` and `legendFontSize`.
- **Text the chart cannot hold** widens the drawing (decision 19).
- **Comments:** `%%` comments.

Read and ignored: `accTitle` and `accDescr`.

### Sankey diagrams

pomermaid reads Mermaid's sankey diagrams (`sankey-beta` and
`sankey`), as Mermaid 12.3.0 reads them, and lays them out as
d3-sankey 0.12.3 does for Mermaid: columns of nodes, each as tall as
the greater of the values that come into it and go out of it, and
between them the links, bands as wide as their values. Each node is
labelled with its name and, unless `showValues` is false, its value.

- **The first line:** `sankey-beta` or `sankey`, then a line end.
- **Records,** one to a line, are CSV's: a source, a target and a
  value, separated by commas. A field in double quotation marks may
  hold commas and line ends, and `""` is a quotation mark in it.
  Blanks around a field are not its own. The same name is the same
  node; nodes are taken in the order they first appear.
- **Values** are numbers, read as JavaScript's `parseFloat` reads
  them: `12`, `.5`, `1e3`, and what follows the number is ignored. A
  value that is not a number, or is negative, is an error, and so
  are links that make a cycle.
- **Blank lines** and `%%` comments are skipped.
- **Configuration:** `sankey`'s `width` and `height` (600 by 400
  pixels), `nodeWidth` (10), `nodePadding` (12, and 15 more when the
  values are shown), `nodeAlignment` (`justify`, `left`, `right` or
  `center`: where a node without links on one side goes), `showValues`
  (true), `prefix` and `suffix` (around each value), `labelStyle`
  (`legacy`, each label beside its node, inside the drawing; or
  `outlined`, each label to the left of its node in the columns before
  the largest node's and to the right from it on), `nodeColors` (a
  colour for each node, by name) and `linkColor` (`gradient`, from the
  source's colour to the target's; `source`; `target`; or a colour).
  Sizes are in pixels, 16 of them to `--size`.
- **Colours:** each node's from `nodeColors`, else Tableau10's, in
  turn, as d3 gives them.
- **Text the diagram cannot hold** widens the drawing, as Mermaid's
  does.

### Git graphs

pomermaid reads Mermaid's git graphs (`gitGraph`), as Mermaid 12.3.0
reads them, and draws them as Mermaid does: each branch a lane, with
its name; the commits along the lanes, in the order they were made;
an arrow from each commit to the next on its branch, and from each
branch's start and each merge's or cherry-pick's other parent; the
commits' ids beside them, and their tags.

- **The first line:** `gitGraph`, `gitGraph:`, or `gitGraph` and a
  direction, `LR:` (left to right, the default), `TB:` (top to
  bottom) or `BT:` (bottom to top).
- **`commit`,** then any of `id: "x"`, `msg: "x"` (or just `"x"`),
  `tag: "x"` and `type: NORMAL`, `REVERSE` or `HIGHLIGHT`. A commit
  with no id is given one: its number, `-` and 7 hexadecimal digits.
  An id used before is a warning, and the new commit replaces the
  old, as in Mermaid.
- **`branch name`,** then `order: N`: makes the branch at the current
  commit and checks it out. Branches are placed by order, then in the
  order made.
- **`checkout name`** or **`switch name`.**
- **`merge name`,** then any of `id:`, `tag:` and `type:`: a merge
  commit on the current branch.
- **`cherry-pick id: "x"`,** then any of `tag:` and `parent: "x"`
  (which of a merge commit's parents to pick from).
- **Names** are letters, digits, `_`, `-`, `.` and `/`, or a string
  in quotation marks.
- **`title`,** and `%%` comments; `accTitle` and `accDescr` are read
  and ignored.
- **Mermaid's errors:** a branch checked out before it is made, or
  made twice; a branch merged into itself, or a merge with nothing to
  merge; a cherry-pick of a commit that does not exist or is on the
  current branch.
- **Configuration:** `gitGraph`'s `showBranches` (true),
  `showCommitLabel` (true), `rotateCommitLabel` (true: the ids are
  turned 45 degrees), `parallelCommits` (false: each commit a step
  further along; true: each a step past its parents),
  `mainBranchName` (`main`), `mainBranchOrder` (0), `titleTopMargin`
  (25) and `diagramPadding` (8).
- **Colours:** the default theme's, each changed by its
  themeVariable: `git0` to `git7` (the branches, in turn),
  `gitInv0` to `gitInv7`, `gitBranchLabel0` to `gitBranchLabel7`,
  `commitLabelColor`, `commitLabelBackground`, `commitLabelFontSize`,
  `tagLabelColor`, `tagLabelBackground`, `tagLabelBorder`,
  `tagLabelFontSize`, `primaryColor`, `commitLineColor` (else
  `lineColor`) and `textColor`.

### Mindmaps

pomermaid reads Mermaid's mindmaps (`mindmap`), as Mermaid 12.3.0
reads them, and draws them with Mermaid's shapes, colours and edges,
but laid out as a two-sided tree: the root in the middle, its
children to its left and right by turns, and each child's subtree
spreading away from the root. Mermaid's own layout is force-directed
and differs from run to run (see differences.md).

- **The first line:** `mindmap`.
- **Nodes:** one to a line; a node's parent is the nearest line
  above it that is less indented. There is one root, the first node.
  Indentation is spaces or tabs.
- **Shapes:** `id` or text alone (the default, a box with a line
  along its bottom), `id[text]` (a rectangle), `id(text)` (rounded),
  `id((text))` (a circle), `id)text(` (a cloud), `id))text((` (a
  bang) and `id{{text}}` (a hexagon). A label in quotation marks, or
  in `` "` `` and `` `" ``, may hold brackets.
- **`::icon(...)`** and **`:::class`,** on the line after a node:
  read and kept, with a warning; neither is drawn.
- **`%%` comments;** a `%%` inside a node's text is part of it, as in
  Mermaid.
- **Mermaid's errors:** a second root; an icon or class before any
  node; text after a node on its line; a label without its end.
- **Configuration:** `mindmap`'s `padding` (10) and `maxNodeWidth`
  (200: a longer label is wrapped), and `colorBy`: `branch` (the
  default: each child of the root and its subtree a colour) or
  `depth` (each level a colour).
- **Colours:** the default theme's, each changed by its
  themeVariable: `git0` and `gitBranchLabel0` (the root), and
  `cScale0` to `cScale11` (fills and edges), `cScaleLabel0` to
  `cScaleLabel11` (text) and `cScaleInv0` to `cScaleInv11` (a default
  node's bottom line). An edge is as wide as Mermaid's: narrower at
  each level.

Mermaid's other diagram types are not read yet.

## Using the output

### groff ms

Put the pic output where the diagram goes, and run groff with `-p`.
If it is read with `.so`, add `-s` (soelim), so that pic sees it:

    pomermaid -t pic diagram.mmd > diagram.pic

    .LP
    Text before the diagram.
    .so diagram.pic
    .LP
    Text after it.

    groff -s -ms -p -Tpdf doc.ms > doc.pdf

The block is centred, as pic centres a drawing. Labels are in `--font`
at `--size`, measured from groff's font files, so they fit their boxes
in that font. A diagram wider than `--width` is laid out again at a
smaller size, not scaled, so that the text stays sharp and fits.

Labels outside ASCII are written as groff's `\[uXXXX]` escapes, so
`-k` is not needed for them.

### groff mom

mom's documents read pic as ms's do. Give `pdfmom` the `-p` option, and
`-s` for `.so`:

    .PRINTSTYLE TYPESET
    .START
    .PP
    Text before the diagram.
    .so diagram.pic
    .PP
    Text after it.

    pdfmom -s -p doc.mom > doc.pdf

### ConTeXt

Put the `\startMPcode` block where the diagram goes:

    pomermaid -t mp diagram.mmd > diagram.tex

    \starttext
    Text before the diagram.

    \input diagram

    Text after it.
    \stoptext

pomermaid lays the diagram out, but ConTeXt measures the labels in the
document's own font and size, and MetaPost places the nodes to fit
them. So `--font` and `--size` do not set how the labels look in
ConTeXt; they set only the estimate the layout starts from. A diagram
wider than `--width` is scaled down.

Each block holds the macros it needs, about 30 KB. With several
diagrams in one document, `--mp-macros=input` writes `input pomermaid ;`
instead. The installed `share/pomermaid/pomermaid.mp` must then be
where ConTeXt finds it, such as beside the document. A sequence
diagram's block writes `input pomermaid-seq ;` instead, for
`share/pomermaid/pomermaid-seq.mp`, its own macros: they lay the
diagram out again with ConTeXt's sizes, as `--size` and `--font` only
estimate them.

To centre a diagram, wrap it in `\startlinealignment[middle]` ...
`\stoplinealignment`, or place it as a figure:

    \startplacefigure[location={here,none}]
      \input diagram
    \stopplacefigure

### HTML

`-t svg` writes an SVG document. Use it as an image:

    pomermaid -t svg -o diagram.svg diagram.mmd

    <img src="diagram.svg" alt="...">

You can also put it in the page itself. It begins with `<svg`, with no
XML declaration when `mutool` made it.

The SVG's size is the diagram's, in points, with a margin of 2 points
or the widest line's width, whichever is larger.

- **`--svg-text=text`** (the default) keeps each label as `<text>`
  with each glyph's position. This is small, and the text can be
  selected and searched. The SVG names groff's fonts, such as
  `Nimbus Roman`. A browser without them sets the glyphs in another
  font, at groff's positions.
- **`--svg-text=outline`** draws the glyphs as outlines. The result
  looks the same everywhere, but is about ten times as large.
  `pdftocairo` always draws outlines.

Outlined SVGs give their glyphs ids: `font_1_N` from `mutool`, and
`glyph-0-N` from `pdftocairo`. These ids are the same in every
diagram, so two outlined SVGs in one page would clash. Use `<img>` for
those. SVGs with text have no ids and can be put in a page together.

### pandoc

`docs/examples/pomermaid.lua` is a pandoc Lua filter. It runs
pomermaid on each fenced `mermaid` code block:

| pandoc output | The block becomes |
|---|---|
| ms | pic |
| ConTeXt | MetaPost |
| HTML | inline SVG |

Code blocks of other formats, and of other classes, are left as they
are. The block's `width` and `size` attributes become `--width` and
`--size`:

````
```{.mermaid width=4i size=9}
flowchart LR
    A --> B
```
````

To make PDFs and HTML:

    pandoc --lua-filter pomermaid.lua -s -t ms doc.md -o doc.ms
    groff -ms -p -Tpdf doc.ms > doc.pdf

    pandoc --lua-filter pomermaid.lua -t ms \
      --pdf-engine=pdfroff --pdf-engine-opt=-p doc.md -o doc.pdf

    pandoc --lua-filter pomermaid.lua -t context doc.md -o doc.pdf

    pandoc --lua-filter pomermaid.lua -s -t html doc.md -o doc.html

### podoc

podoc does not run pomermaid yet; it is planned (pomermaid's decision
5). Until it does, make each diagram's file with pomermaid, and bring
it into the document with a raw block:

    ```{=ms}
    .so diagram.pic
    ```

    ```{=context}
    \startlinealignment[middle]
    \input /home/me/doc/diagram
    \stoplinealignment
    ```

For ms, pass groff's `-s` and `-p`:

    podoc -t ms --pdf-engine=pdfroff --pdf-engine-opt=-s \
      --pdf-engine-opt=-p doc.md -o doc.pdf

For ConTeXt, the path must be absolute. podoc runs ConTeXt in a
temporary directory, where a relative path is not found.

## Fonts

pomermaid measures the labels with groff's font description files for
`-t pic` and `-t svg`. These are the files that groff itself sets the
text with, so the measurements match groff's to the unit. It looks for
`devpdf/FONT`, then `devps/FONT`, in these directories, in this order:

1. `--font-path`, if it is given;
2. otherwise `GROFF_FONT_PATH`, if it is set;
3. otherwise the `site-font` and `current/font` directories of the
   groff found in `PATH`;
4. then the same under `/usr/local`, `/usr/pkg` and `/usr`;
5. then `/usr/share/groff_font`, where NetBSD's own groff keeps them,
   and `/usr/lib/font`.

For `-t svg`, `--font-path` is also passed to groff, as `-F`.

## See also

- `docs/user/differences.md`, where pomermaid draws differently from
  Mermaid.
- `PLAN.md`, the plan and the state of each phase.
