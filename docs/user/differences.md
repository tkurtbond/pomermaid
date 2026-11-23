# Where pomermaid differs from Mermaid

pomermaid does not try to copy Mermaid's drawings. It lays a diagram
out freely where that is clearer (pomermaid's decision 2). This page
lists where its drawings, and what it reads, differ from Mermaid's.
None of it was checked against a run of Mermaid itself. The
comparisons are with Mermaid's source and documentation.

## Text and sizes

- **Fonts.** Labels are set in the document's font: groff's `--font`
  (Times by default) for pic and SVG, and the body font for ConTeXt.
  Mermaid uses its theme's font, "trebuchet ms" by default. pomermaid
  scales Mermaid's sizes in pixels, such as padding, spacing, line
  widths and arrow heads, from its 16 pixel text to the size of the
  labels.
- **Wrapping.** A label wider than 200 pixels, Mermaid's wrapping
  width scaled to the text, is broken at spaces, as Mermaid breaks it.
  Its box is then as wide as its widest line. Mermaid's box is the
  full 200 pixels wide.
- **Markdown strings** (``"`**bold**`"``) keep their bold and italic,
  as in Mermaid. Their other markdown is drawn as written, as Mermaid
  draws it in a flowchart's labels.
- **Icons** (`fa:fa-car`) are drawn as their text. Mermaid draws Font
  Awesome's glyph where the page loads that font.
- **Width.** Mermaid scales a diagram to fit its container. With
  `-t pic` and `-t svg`, a diagram wider than `--width` is laid out
  again at a smaller text size, so that the text stays the size the
  boxes were measured for. With `-t mp`, the finished picture is
  scaled down, since MetaPost cannot ask pomermaid for another layout.

## Layout

The layout follows dagre's method, which Mermaid uses, with these
differences:

- **Edge ends.** An edge leaves and enters a node by the face that
  looks toward the next rank, not by whichever side is nearest. Where
  a node is shorter than its rank, the edge goes straight out to the
  edge of the rank's band before it turns aside, so that it misses
  taller neighbours. An end is cut where the edge's last piece meets
  the node's outline. Mermaid cuts it on the line toward the node's
  centre.
- **Self-loops** leave a node's side and come back lower down, round
  the gap before their label. Mermaid's circle a point away from the
  node.
- **Positions along a rank** in ConTeXt are not dagre's. Each rank is
  placed so that it keeps the alignment of pomermaid's estimate, with
  the nodes moved apart as far as their real sizes need. So a diagram
  in ConTeXt can differ a little from the same diagram in pic.

## Subgraphs

- **An empty subgraph** has no box. Mermaid draws an empty one.
- **`direction` inside a subgraph** is honoured, as in Mermaid, only
  for a subgraph that no edge crosses. Such a subgraph is laid out on
  its own and placed as one node; its rank spacing is 25 pixels more
  than its parent's, as Mermaid's is.
- **A collapsed subgraph** (`@{ view: collapsed }`) is drawn as
  Mermaid draws it, a box with its title, a dashed rule and three dots.
- **Subgraphs joined both ways,** directly or through a cycle, are not
  stacked one below the other. Their nodes are ranked by the edges
  alone, so their boxes may stand side by side or overlap in rank.

## Styles and colours

- **Themes.** Only Mermaid's `default` theme and `classic` look are
  drawn: `theme` and `look` are ignored. Since version 12.0.0, Mermaid
  draws flowcharts by default in its `redux-color` theme and `neo`
  look, so pomermaid's drawings look like Mermaid's with `theme:
  default` and `look: classic`. The `themeVariables` that colour a
  flowchart are used.
- **Colours.** pomermaid knows hex colours, `rgb()` and about 35 CSS
  names. Any other colour is ignored with a warning, and the default
  is used.
- **Dashed and dotted edges** are drawn in pic as a row of short
  lines along the curve. pic cannot dash a spline. They look as
  Mermaid's do.

## State diagrams

- **Layout.** A state diagram is laid out as a flowchart is: a
  composite state or region is a subgraph, and a transition to a
  composite state goes to its box.
- **Notes** are boxes beside their states, ranked as the layout
  places them, joined by a dashed line. Mermaid puts a note and its
  state in a group of their own (its `noteGroup`), side by side.
- **A state with descriptions** draws them as one block of lines
  below its name. Mermaid writes each description as a line of its
  own.
- **The end marker's dot** is drawn in the line colour. Mermaid fills
  it with the state border colour.
- **Ids** end at `;` and, inside a composite state, at `}`, so that
  `a --> b; b --> c` and `state X { a --> b }` read as they look.
  Mermaid takes those characters into an id.
- **Styles of the `neo` look** and `redux-color` theme, Mermaid's
  default for state diagrams since 12.0.0, are not drawn: see "Styles
  and colours".

## Class diagrams

- **Layout.** A class diagram is laid out as a flowchart is: a
  namespace is a subgraph and a note a node.
- **Sizes.** A class box's parts are spaced as Mermaid spaces them,
  but its lines are the document's line spacing, not Mermaid's 24
  pixels.
- **Note lines** are dashed, 2 pixels on and 2 off; Mermaid's are
  dotted.
- **The lollipop's circle** is drawn hollow, in the line colour.
- **Names** are a class's letters, digits and `_`, `-`, `.` and
  generics, or anything in backquotes; Mermaid takes some other
  characters into a name. Its quirks with keywords at the start of a
  name, such as a class `classA` read as `class A`, are not copied.
- **Comments.** `%%` starts a comment anywhere on a line. Mermaid
  takes one only at the start of a line.

## Entity relationship diagrams

- **Layout.** An entity relationship diagram is laid out as a
  flowchart is, with Mermaid's 140 pixels between entities in a rank
  and 80 between ranks.
- **Text sizes.** A relationship's role is drawn at the size of the
  other labels. Mermaid draws it at 14 pixels.
- **Keywords.** The words of a cardinality, `to` and `optionally to`
  are taken only as whole words: `A one to manyB` is an error, not a
  relationship to `B`. Mermaid takes them as prefixes.
- **Names** are letters, digits and `_`, `-`, `*` and `.`, or anything
  in quotation marks.
- **Relationships after an alias.** As in Mermaid's grammar, an
  entity with an alias, `p[Person]`, cannot begin a relationship on
  the same line; write `p[Person]` alone, then `p ||--o{ ...`.

## Requirement diagrams

- **Layout.** A requirement diagram is laid out as a flowchart is,
  with 50 pixels between boxes in a rank and between ranks.
- **Values.** A value not in quotation marks is the rest of its line,
  trimmed. Mermaid reads a word that cannot hold `:`, `,` or some
  other characters, and cannot be a keyword.
- **Names.** A relationship naming a requirement or element that is
  not defined is an error. Mermaid draws the edge to nothing.
- **Names defined twice.** The first definition is kept, even when
  one is a requirement and the other an element.
- **`title`** is an error, as Mermaid's grammar has none for this
  diagram.

## Sequence diagrams

- **Layout.** pomermaid spaces the participants and events as
  Mermaid does in outline, from the widths of the texts between each
  pair of participants, but more simply: all text is one size, the
  diagram's, where Mermaid sets messages, notes and labels in sizes of
  their own.
- **No wrapping.** `wrap:` and the `wrap` setting are ignored; a long
  text makes its column wider. Use `<br>` for new lines.
- **Keywords** are taken only as whole words: `loopback A->>B: hi`
  is a message from `loopback A`, where Mermaid's lexer reads `loop`
  and `back`.
- **`par_over`** is drawn as `par` is.
- **Activations** left open at the end are drawn to the foot of the
  diagram.
- **Participants' icons.** `boundary`, `control`, `entity`,
  `database`, `queue` and `collections` are drawn as simple outlines
  close to Mermaid's, not its exact shapes.
- **A message to itself** is drawn as three straight lines, where
  Mermaid draws a curve.
- **`create`** must be followed by a message to or from the
  participant created; otherwise it is an error.
- **A destroyed participant** has no box at the foot; a cross ends its
  line.
- **Boxes** are outlined in grey, whatever the theme.
- **Entities.** Numeric entities, `#9829;`, and the named ones
  pomermaid knows in every diagram, `#amp;`, `#lt;`, `#gt;`, `#quot;`,
  `#apos;` and `#nbsp;`, are decoded; other names, such as `#infin;`,
  are left as they are. A character the font lacks, such as Latin Modern's `♥`,
  is not drawn.

## User journeys

- **The title** is drawn above the sections, at 1.5 times the
  labels' size, where Mermaid draws it over the top of the first
  section.
- **The left margin.** The tasks start 150 pixels to the right of the
  widest actor's name, or 50 pixels in when there are no actors.
  Mermaid works it out from the names' lengths in characters.
- **Text in boxes** is wrapped to its box, and the sections' and the
  tasks' boxes grow to hold the longest, moving the activity line and
  the faces down. Mermaid wraps the text but keeps the boxes 50
  pixels high.
- **Scores far out of 1 to 5** put a face above the top of the
  drawing in Mermaid; pomermaid moves the drawing down to make room.
- **Colours.** The sections' fills are Mermaid's defaults, or the
  `fillType0` to `fillType7` theme variables; they are not worked out
  from `primaryColor` as Mermaid's themes do. The `journey`
  configuration's `actorColours` is not read; the theme variables
  `actor0` to `actor5` are.

## Timelines

- **The title** is drawn above the drawing, at 1.5 times the labels'
  size, its left at the first period's; Mermaid draws it at the top
  left, over what is there.
- **A section's text** is wrapped to its box; Mermaid wraps it at 150
  pixels, however wide the section. The sections are all as high as
  the highest.
- **A section named twice** is drawn once, with all the periods under
  that name; Mermaid draws it twice. A `:` in a section's name is an
  error.
- **Top down,** each section starts 20 pixels below what is above it,
  where Mermaid's sections can overlap the periods above them, and the
  axis and the dashed lines have their arrowheads, which Mermaid's
  top-down drawing loses.
- **Colours.** The defaults are Mermaid's default theme's; they are
  not worked out from `primaryColor` as Mermaid's themes do, and each
  theme variable changes only its own colour.

## Gantt charts

- **The width.** The chart is `--width` wide, 1200 pixels if it is
  not given, or `gantt.useWidth`'s (decision 15); Mermaid takes the
  width of the page it is drawn in.
- **Text** is placed by its middle, 0.3 of its size above Mermaid's
  baseline, and the grid's lines are at the ticks, without d3's half
  pixel offset.
- **Task text** is drawn as it is written; entities are not read.
- **What Mermaid's SVG clips** is left out: the today line when it is
  outside the chart, and, in compact mode, the part of a vertical
  marker below the chart.
- **See-through colours.** pic has no transparency, so the rows and
  the grid are drawn in the colour they give over what is behind them,
  and the grid is drawn over the rows, where Mermaid draws it under
  them. A colour's alpha in the theme variables is ignored, and so is
  `todayMarker`'s `opacity`.
- **Links** exist only in SVG.

## Pie charts

- **The title** is centred over the pie. Mermaid centres it at 225
  pixels, the pie's centre when the legend is not on the left; with
  the legend on the left, Mermaid's title is left of the pie
  (decision 17). A title wider than the drawing widens it, on both
  sides; Mermaid's is cut off.
- **Values** are shown, with `showData`, as they are written, without
  leading zeros and with the trailing zeros of a decimal dropped
  (`005.00` as `5`); Mermaid shows JavaScript's number, which can
  differ for very long numbers.
- **See-through colours.** pic has no transparency, so the slices are
  drawn in the colour `pieOpacity` gives them over white, their
  outlines too.
- **Colours** come from `pie1` ... `pie12` only; Mermaid's themes work
  them out from `primaryColor` and the others, which pomermaid does
  not.
- **Text sizes** are the labels', `--size`, and the title's 25/17 of
  that; Mermaid's `pieTitleTextSize`, `pieSectionTextSize` and
  `pieLegendTextSize` are ignored.
- **Escapes** in a label, `\n`, `\t` and the others, are drawn as a
  blank, as SVG draws white space.
- **Hovering** over a slice does nothing.

## Quadrant charts

- **Text the chart cannot hold,** a title wider than the chart, or a
  point's text, or an axis's, past its edge, widens or heightens the
  drawing, which is moved for it (decision 18); Mermaid's is cut off.
- **Points' colours.** Mermaid's default theme gives the points an
  invalid colour, so SVG draws them in the text's colour, `#333`, and
  without an outline; pomermaid draws them so too. A colour without
  `#`, in a style, is drawn in the text's colour too.
- **Markdown strings** are drawn as they are written, `**` and all,
  as Mermaid draws them.
- **Text heights.** A text set "hanging" in Mermaid's SVG, its top at
  its place, is set with its middle half its size below that.

## XY charts

- **Text the chart cannot hold,** a title or a label past the chart's
  edge, widens the drawing (decision 19); Mermaid's is cut off. The
  background covers the whole drawing.
- **Turned x labels** (`labelRotation`) are turned about their
  centres (decision 20); Mermaid turns them about their anchors.
- **Data labels.** Each bar plot shows its own values (decision 21);
  Mermaid shows the first bar plot's values over every bar plot. A
  value is shown as it was written, without leading zeros and with
  a decimal's trailing zeros dropped. The legend's markers have none.
- **Ticks** are written as plain numbers, never in exponent form.
- **Linear x axes.** A point whose key is not a number is skipped;
  keys are written with 15 significant digits.
- **Lines** stop at the first point with no value.
- **Line labels** are not clipped to the plot, and are drawn in the
  line's colour, as Mermaid draws them.
- **Markdown strings** are drawn as they are written, as Mermaid
  draws them.
- **Baselines.** Text Mermaid sets on its alphabetic baseline is set
  with its middle 0.35 of its size above that.

## Radar charts

- **Transparency.** pic has none, so the fills are opaque and blended
  as Mermaid's would look (decision 22): each graticule ring is its
  colour at `graticuleOpacity` over the ring outside it, white outside
  the largest; each curve is its colour at `curveOpacity` over white,
  so a curve hides the graticule and the curves beneath it. The
  outlines are drawn after all the fills, so each curve's outline
  shows. MetaPost's are drawn the same. An opacity of 0 is no fill.
- **Colours** for more than 12 curves start again at `cScale0`;
  Mermaid has no style for the 13th and later, and draws them black.
- **Text the chart cannot hold,** a long title or an axis label past
  the margins, widens the drawing (decision 19); Mermaid's is cut off.
- **Text heights** are set as for XY charts: hanging text with its
  middle half its size below its place, text on its baseline with its
  middle 0.35 of its size above it.

## Sankey diagrams

- **Transparency.** Mermaid draws its links at an opacity of 0.5,
  multiplied over the nodes and labels. pic has no transparency, so
  each link is its colour at 0.5 over white, a gradient drawn as 32
  slices across the link, each of the colour where it is (decision
  23); the links are drawn first, then the nodes, then the labels, so
  that no link hides a label. Where links cross, the later covers the
  earlier. MetaPost's are drawn the same.
- **Outlined labels** have no halo.
- **The title** is not drawn, as Mermaid does not draw it.
- **Characters.** Mermaid's lexer takes only ASCII, and fails on
  other characters; pomermaid takes any.
- **Blank lines** may hold blanks; Mermaid's are empty.
- **Zero.** A node whose values are all 0 has no height, and its
  links are a pixel wide; where all of a diagram's values are 0,
  Mermaid's layout divides by 0 and draws nothing in its place.
- **Colours** that are not CSS's, in `nodeColors`, are black, as
  Mermaid's SVG fill would be; in `linkColor`, no link is drawn.

## Git graphs

- **Made ids.** A commit without an id is given one: its number, `-`
  and 7 hexadecimal digits. Mermaid's digits are random; pomermaid's
  are a hash of the number, the branch and the message, the same on
  each run (decision 24).
- **Transparency.** Mermaid draws the commit labels' backgrounds at an
  opacity of 0.5; pomermaid draws each in its colour taken over white
  (decision 25), so that it hides the arrow under it.
- **Arrows' corners** are quarter circles drawn as Béziers, where
  Mermaid's are SVG arcs; pic draws them as lines through 8 points of
  each, with a round end drawn as a circle (decision 26).
- **Labels** are not passed through Mermaid's `sanitizeText`
  (decision 27).
- **A duplicate commit id** is a warning on standard error, with its
  line; Mermaid's is on the browser's console (decision 28).
- **Themes.** The colours are the default theme's, changed by the
  themeVariables; other themes are not drawn.
- **Text heights** are set as for XY charts: a text's middle is 0.35
  of its size above its baseline.

## Mindmaps

- **Layout.** Mermaid lays mindmaps out with cose-bilkent, a
  force-directed layout that starts at random; pomermaid lays them
  out as a two-sided tree, the same on each run (decision 29). The
  nodes' sizes, shapes and colours, and the edges' widths, are
  Mermaid's.
- **Icons and classes** are read, with a warning, and not drawn
  (decision 30).
- **Clouds and bangs** are polygons, each arc of their outlines taken
  at 16 points, where Mermaid's are SVG arcs (decision 31).
- **Themes.** The colours are the default theme's, changed by the
  themeVariables; other themes are not drawn.

## What is read but not drawn

- **Links.** `click` and `href` links and tooltips exist only in SVG,
  which pomermaid writes over the nodes. pic and MetaPost have none.
  A `click` that calls a function has no link; its tooltip is kept.
- **Icon and image shapes** (`@{ icon: ... }`, `@{ img: ... }`) are
  drawn as boxes with their labels.
- **Animation.** An edge's `animate`, `animation` and `step` are
  ignored.
- **Accessibility.** `accTitle` and `accDescr` are read and ignored.
- **State diagrams:** `hide empty description` and `scale` are read
  and ignored, and so are floating notes, `note "text" as id`, which
  Mermaid does not draw either.
- **Class diagrams:** `callback` and `click ... call`, which call
  functions, are read and ignored; their tooltips are kept.
- **Shapes Mermaid does not document,** such as `note` and the `bpmn-`
  shapes, are drawn as the nearest documented shape, with a warning.

## SVG

pomermaid does not write SVG itself (pomermaid's decision 10). groff
draws the pic picture as a PDF, and `mutool` or `pdftocairo` turns
that into SVG. So the SVG looks as the printed diagram does, but:

- its labels are `<text>` with each glyph placed, or outlines with
  `--svg-text=outline`, where Mermaid's are HTML in `foreignObject`;
- it has no CSS classes or ids for the nodes and edges, so a page's
  stylesheet cannot restyle them.

`mutool` places each glyph of a `<text>` with a list of x positions.
Browsers follow them. `rsvg-convert` (librsvg) does not: it sets the
text in its own font from the first position, so a label can run into
the next one on its line, most visibly in the cells of an entity's
attributes. Look at such SVG in a browser, or use
`--svg-text=outline`.
