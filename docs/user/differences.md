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

- **Themes.** Only Mermaid's default theme is drawn: `theme` is
  ignored. The `themeVariables` that colour a flowchart are used.
- **Colours.** pomermaid knows hex colours, `rgb()` and about 35 CSS
  names. Any other colour is ignored with a warning, and the default
  is used.
- **Dashed and dotted edges** are drawn in pic as a row of short
  lines along the curve. pic cannot dash a spline. They look as
  Mermaid's do.

## What is read but not drawn

- **Links.** `click` and `href` links and tooltips exist only in SVG,
  which pomermaid writes over the nodes. pic and MetaPost have none.
  A `click` that calls a function has no link; its tooltip is kept.
- **Icon and image shapes** (`@{ icon: ... }`, `@{ img: ... }`) are
  drawn as boxes with their labels.
- **Animation.** An edge's `animate`, `animation` and `step` are
  ignored.
- **Accessibility.** `accTitle` and `accDescr` are read and ignored.
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
