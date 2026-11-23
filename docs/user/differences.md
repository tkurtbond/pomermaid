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
