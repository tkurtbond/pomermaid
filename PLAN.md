# pomermaid: plan

pomermaid reads a Mermaid diagram and draws it in pic, for groff, or in
MetaPost, for ConTeXt; for HTML it makes SVG from the pic drawing,
through groff and a PDF. It is written in Oberon-2 and built
with poc. See AGENTS.md for the conventions.

Each phase lists the work in it (**Change**), how it is checked
(**Check**) and its state (**Done**). A phase ends with a commit, made
when the user asks.

## Why

The user's documents carry Mermaid diagrams in fenced `mermaid` code
blocks. Today a pandoc filter draws them by running a headless
Chromium, which is large, slow and missing on the small and less common
systems podoc is meant for; podoc ignores the blocks (podoc decision
4). Groff and ConTeXt each have a drawing language of their own, pic
and MetaPost, and HTML has SVG. A program that turns Mermaid into
those languages draws the diagrams with the document's own fonts,
needs no browser, and can be run by podoc (decision 5).

## What the user's diagrams use

As of 2026-11-22 there are three flowcharts in two files (AGENTS.md's
reference material). Together they use:

- `flowchart TD` and `graph TD`;
- the node shapes `id[text]`, `id["text"]` and `id{text}` (a diamond);
- the edges `-->` and `<-->`, and edge labels in the `-->|text|` form;
- chains of nodes and edges on one line;
- `subgraph ID ["Title"]` ... `end`;
- `classDef name fill:#f9f,stroke:#333,stroke-width:2px;` and
  `class A,B name;`;
- `%%` comments;
- `<br>` and `<br/>` in labels, and non-ASCII text (`Máximo`);
- cycles, and parallel edges: three labelled edges from one node to
  the same other node (aftermath's `ActKind` to `Interpreter`).

The first target is these features, drawn well, in all three writers
(Phases 1 to 11). The rest of Mermaid's flowchart syntax and then every
other diagram type follow (decision 1).

## Design

The program is a pipeline of modules, each tested alone:

1. **Readers** (`PmLex`, then one per diagram type: `PmFlow`, ...):
   read the Mermaid text into that type's model. For a flowchart: nodes
   (id, label lines, shape, class, style), edges (ends, label, kind:
   arrow heads at either end, line style), subgraphs (a tree of node
   sets, with titles), class definitions, and the direction. The first
   line (`flowchart`, `sequenceDiagram`, `pie`, ...) picks the reader.
   Errors give the line and column, as Mermaid's do.
2. **`PmMetrics`**: the width and height of each label, in points, for
   a font and size, from groff's font files
   (`/usr/share/groff/current/font/devpdf`, or `--font-dir`), read at
   run time. Used by the pic writer, and so by SVG (decision 10). The
   MetaPost writer does not measure (decision 3).
3. **`PmLayout`**: a layered layout after dagre's method (Gansner et
   al. 1993), split in two halves.
   - **Topology**, which does not depend on sizes: break cycles by
     reversing a set of edges; assign ranks (longest path, then network
     simplex); put dummy nodes on edges that span more than one rank
     and on edge labels; order each rank to reduce crossings
     (barycenters, sweeping down and up, with transposition of
     neighbours); keep subgraphs together (clusters).
   - **Geometry**, from the sizes: coordinates across ranks (Brandes
     and Köpf 2001) and along them; edge routes through the dummy
     nodes, clipped at node outlines; the turn for `LR`, `BT` and `RL`.
   Where a clearer drawing is possible than dagre's, take it
   (decision 2): matching Mermaid's drawings is not a goal.
4. **Writers**: `PmPic` and `PmMp`; and `PmSvg`, which runs groff on
   `PmPic`'s output and turns the PDF into SVG (decision 10).
5. **`pomermaid`**: the command line (ArgParser). One diagram per run
   (decision 4).

Coordinates are `REAL`s, in points. All output is deterministic, so the
case tests compare it byte for byte.

### Curves

Edges are curves, as Mermaid draws them (decision 8). Mermaid's
default is d3's `curveBasis`, a uniform cubic B-spline through the
route's points as control points, passing through the first and last.
pic's `spline` is that same kind of curve, so pic gets the route's
points as they are. For MetaPost the B-spline is turned into
cubic Bézier segments (each segment's control points from three
neighbouring route points), which MetaPost draws directly. Arrow heads are
placed along the curve's end tangent.

### pic

What the hand-drawn version (`docs/examples/gbh-handdrawn.ms`) found
works in groff 1.23:

- `.defcolor name rgb #rrggbb` for each colour, before `.PS`;
- `box wid W ht H at (x,y) shaded "fill" outlined "line"`;
- pic gives a box's text its outline colour, so each label is wrapped
  in `\m[text]...\m[]`;
- `thickness`, `dashed`, `dotted`, `arrow`, `arrow <->`;
- labels of several lines as several quoted strings;
- `groff -k`, with a coding line, for UTF-8 labels.

Diamonds and other polygons are drawn with `line` from point to point;
rounded boxes with `box rad`; circles with `circle`. The output is the
`.defcolor` lines and a `.PS` ... `.PE` block (decision 4). A diagram
is written at its natural size and scaled with `.PS width` when it is
wider than `--width`.

### MetaPost

The output is a `\startMPcode` ... `\stopMPcode` block of MetaFun
(decision 4). Labels are `textext("...")`, set by ConTeXt in the
document's fonts, and the final positions are computed in MetaPost
after `textext` has measured them (decision 3):

- pomermaid does the topology half of the layout and writes it as
  data: each node's rank, its place in the rank, its shape and label;
  each edge's route as a list of nodes and dummies; the clusters.
- A MetaPost macro set, `pomermaid.mp`, written once as part of this
  project, does the geometry half: it measures each label
  (`bbox textext(...)`), sizes the nodes, assigns coordinates, routes
  and draws the edges as Bézier curves, and draws the nodes and
  clusters.
- Each block is self-contained: pomermaid copies the macros it needs
  into the block (`--mp-macros=inline`, the default), or writes
  `input pomermaid ;` for a document that installs `pomermaid.mp`
  once (`--mp-macros=input`).

The coordinate step in MetaPost is simpler than Brandes and Köpf if it
must be, as long as it gives a clear drawing (decision 2): MetaPost's
numbers are limited (scaled, or double with LMTX's `numbersystem`),
and its loops are slow for large graphs. The same split serves the
other diagram types: pomermaid decides the structure, MetaPost the
sizes and positions.

### SVG

SVG is made from the pic drawing, not written directly (decision 10),
so the HTML diagrams look as the printed ones do and their text is
measured by groff itself:

1. `PmPic` writes the picture; pomermaid knows its size.
2. pomermaid wraps it in a groff document whose page is the picture's
   size, with no margins (`-P-p`, `.pl`, `.po`, `.ll`), so no cropping
   tool is needed.
3. It runs `groff -k -p -Tpdf` on it, as podoc runs its PDF engines
   (`Platform.System`, a temporary directory under `TMPDIR`).
4. It turns the one-page PDF into SVG with `mutool draw -F svg -O
   text=text` (MuPDF), which keeps the labels as `<text>` with each
   glyph's position: small, and the text can be selected and searched.
   `--svg-text=outline` draws the glyphs as outlines instead, about ten
   times larger, but the same in every browser whatever fonts it has.
   `pdftocairo -svg` (poppler), which always draws outlines, is the
   fallback where `mutool` is missing (`--svg-engine`).
5. It writes the SVG to standard output or `-o FILE`, and removes the
   temporary files.

Tried by hand on 2026-11-22 with the hand-drawn pic diagrams: `mutool`
with `text=text` gave a 10 KB SVG that `rsvg-convert` drew as the PDF
looked; with outlines, 96 KB. `pdftocairo`'s output was right, but it
failed an assertion as it exited on a PDF cropped by `pdfcrop`; the
uncropped PDF was fine. The SVG names the PDF's fonts
(`Nimbus Roman`); a browser without them uses another font at the same
glyph positions, which can look uneven: hence `--svg-text=outline`.
Links (`click`, `href`) are not expected to survive the PDF; to be
checked in Phase 8.

ConTeXt and MetaPost could make SVG the same way
(`\startMPpage[offset=2pt]` makes a page the drawing's size; tried on
2026-11-22, a 2 KB SVG), but a ConTeXt run takes about a second, and
groff is quick, so SVG goes through pic.

## Phases

### Phase 1: the skeleton [done]

**Change:** a `GNUmakefile` after podoc's: build under `-O2` and `-OC`
in `build/O2` and `build/OC`, `make test` running unit tests and case
tests, `make install`, `make uninstall`. A `pomermaid` that reads a
file or standard input and writes standard output, with `--help`,
`--version`, `-t pic|mp` (or `--to`), and `-o FILE`.
`tools/runcases` (POSIX `sh`). `LICENSE` (BSD 3-Clause, decision 7)
is in place.

**Check:** `make` and `make test` under both models; `pomermaid
--help`.

**Done:** 2026-11-22. `PmIO` (after podoc's `PdIO`, with `WriteInt` and
`WriteReal`), `PmOptions`, `pomermaid`, the GNUmakefile and
`tools/runcases` (cases `<name>.mmd`, outputs `dump`, `pic`, `mp`,
`svg-ms`, or `out` for no `-t`). The program reads its input and stops
with "no diagram reader yet" (64).

### Phase 2: the flowchart reader [done]

**Change:** `PmLex` and `PmFlow`: the features of "What the user's
diagrams use"; the graph model; the default class and Mermaid's
default colours (nodes #ececff with #9370db, clusters #ffffde with
#aaaa33). `-t dump` writes the model as text, for the tests.

**Check:** unit tests of the reader; the three diagrams of the user's
files read and dumped; errors reported with line and column for bad
input.

**Done:** 2026-11-22. `PmLex`, `PmFlow` and `PmDump`. The reader
takes more than the user's diagrams use: every bracket shape, every
edge form (normal, thick, dotted, invisible; arrow, circle and cross
ends at either end; longer links; text as `|...|` or `-- ... -->`),
`&` groups, chains, nested subgraphs with `direction`, `style`,
`linkStyle`, `:::class`, entities, markdown strings and front matter;
drawing the shapes and ends the user's diagrams do not use waits for
Phase 10. The colours of the default class are the writers'
(Phase 5). The tests are case tests of `-t dump` rather than unit
tests.

### Phase 3: text metrics [done]

**Change:** `PmMetrics`: read groff's `DESC` and font files; the width
of a UTF-8 string in a font at a size, with groff's glyph names for
non-ASCII characters (`groff_char(7)`); label lines split at `<br>`;
node sizes by shape, with Mermaid's padding. `--font` and `--size`
(defaults: `TR`, 10 points).

**Check:** widths compared with groff's own, by `\w'...'` in a groff
run, for ASCII and accented text.

**Done:** `PmMetrics` reads `DESC` (`res`, `unitwidth`, `sizescale`)
and a font's `spacewidth`, `ligatures`, `kernpairs` and `charset`,
in `devpdf/`, then `devps/`, of each directory of its path:
`--font-path`, or else `GROFF_FONT_PATH`, the `site-font` and
`current/font` of the groff in `PATH`, then `/usr/local`, `/usr/pkg`
and `/usr`. A glyph's code point comes from groff 1.25's `-- XXXX`
column, a one-character name, `uXXXX`, or a table of groff's names
written from `groff_char(7)` (groff's own `glyphuni` table is GPL and
was not copied). Words are set as groff sets them (`merge_glyph_node`):
a character makes a ligature with the glyph before it or is kerned
against it, so "ffi" in Times is f, the f–f kern and fi; nothing is
kerned against a space (fonts have `. u0020` pairs that groff
ignores); an unknown character counts half an em. `LabelSize` and
`ShapeSize` (Mermaid's shapes and padding) size the nodes. `--font`
(TR), `--size` (10) and `--font-path` are read and the font loaded
for `-t pic` and `-t mp`; a missing font ends pomermaid with 97.
`PmMetricsTest` checks a made-up font, `test/fonts`;
`tools/checkwidths` and `make check-groff` compare widths with groff.

### Phase 4: layout [done]

**Change:** `PmLayout`, both halves: cycle removal, ranking, dummy
nodes, crossing reduction; coordinates, edge routes, all four
directions; self-loops; the B-spline to Bézier conversion. Subgraphs
are laid out as plain nodes here (Phase 7 adds clusters). `-t dump`
adds the ranks and orders, each node's box and each edge's points.

**Check:** unit tests on small graphs (a chain, a diamond, a cycle, a
long edge, a self-loop) with known ranks, orders and coordinates; no
two nodes overlap and no edge crosses a node in the user's diagrams.

**Done:** `PmGeom` (points, the intersections, curveBasis to Bézier
curves), `PmLayout` (dagre's steps: a DFS feedback arc set, network
simplex per component on a grid of half ranks, dummy chains with the
label dummy at the middle, barycentre sweeps keeping the order with
fewest crossings, Brandes and Köpf's four alignments balanced, routes,
the turn for BT, LR and RL) and `PmFlowLayout` (a flowchart's nodes
sized by `PmMetrics`, Mermaid's spacing scaled to the text, edge ends
clipped to the shapes' outlines). The layout is written by a new
`-t layout`, not by `-t dump` as planned, so the reader's tests stay
as they are. Where it is clearer (decision 2) the layout differs from
dagre's: a self-loop leaves the node's side and comes back lower down,
round the gap before its label, instead of circling a point away from
the node; an edge leaves and enters by the face of the box toward the
next rank, not by a side; where its node is shorter than its rank, it
goes straight out to the edge of the rank's band (a doubled point)
before it turns aside, so that it misses taller neighbours; and an
end is clipped to a shape along the edge's last piece, not toward the
centre, so it stays in the node's box.

### Phase 5: the pic writer [done]

**Change:** `PmPic`: nodes in their shapes, edges as splines with
their heads and labels, `classDef` colours and widths, label colour;
`.defcolor` lines and `.PS`/`.PE`; `--width` to scale.

**Check:** case tests (`test/cases/*.mmd` against `*.pic`); `make
render` wraps each in a small ms document and makes PDFs with `groff
-k -p -Tpdf`; the user's diagrams look at least as good as the
hand-drawn version.

**Done:** `PmPic` writes, in a `.PS`/`.PE` block, every shape
(polygons as closed `line`s, rounded and stadium boxes with `rad`, the
subroutine's inner lines, the cylinder as ellipses and lines, single
and double circles), edges as splines with `->`, `<-` or `<->`, circle
and cross markers, edge labels on Mermaid's grey, and the colours,
widths and dashes of `classDef`, `class`, `:::`, `style` and
`linkStyle` (CSS hex, `rgb()`, about 35 names; others are ignored with
a warning). Mermaid's default theme, its pixel sizes scaled to the
text. It differs from the plan in these ways:
- Colours are `.defcolor`ed as `pm-rrggbb`, named by their value, so
  that one diagram's never clash with another's.
- The text's `.ps` and `.vs` are set for the block and restored after
  it, the old values saved in `pm*ps` and `pm*vs`; `maxpswid` and
  `maxpsht` are raised so pic never scales the diagram itself.
- `--width` (6 inches by default; `0` for no limit) does not scale the
  picture: a diagram that is too wide is laid out again at a smaller
  text size, to a tenth of a point, so the text stays the size the
  boxes were measured for.
- A label wider than Mermaid's 200 pixels is wrapped at spaces, as
  Mermaid wraps it, but its box is as wide as its widest line, where
  Mermaid's is 200 pixels.
- pic cannot dash a spline, and groff dashes each piece of a line on
  its own, so a dashed or dotted edge is sampled along its curve and
  each dash written as a line of its own, its heads as short lines.
`make render` (`tools/render`) draws each case with a layout in
groff's Times, one to a page, in `build/render/cases.pdf`.

### Phase 6: the MetaPost writer [done]

**Change:** `pomermaid.mp`, the geometry half of the layout in
MetaPost; `PmMp`, the topology as MetaPost data and the macros, in a
`\startMPcode` block; `--mp-macros=inline|input`.

**Check:** case tests against `*.mp`; `make render` wraps each in a
small ConTeXt document and runs ConTeXt LMTX; the labels fit their
boxes in the document's font, with a large and a small body font; no
overlaps in the user's diagrams.

**Done:** `mp/pomermaid.mp` holds the macros; `tools/mp2mod` makes
`PmMpMacros` from it, which `--mp-macros=inline` (the default) copies
into each block, and `make install` installs it in
`$(PREFIX)/share/pomermaid` for `--mp-macros=input`. `PmMp` writes the
layout's topology: each node, dummies too, with its rank, its order,
where the estimate put it along the rank, its shape, label and style;
each edge with its chain of dummies, heads, line and label. The style
code that `PmPic` had is now `PmStyle`, shared by both writers. In
MetaPost, the macros measure the em and each label (`textext` of a
`\framed`), size the nodes as `PmMetrics.ShapeSize` does, place the
ranks as `PmLayout` does, route the edges (self-loops, faces, rank
bands, reversed edges), turn the drawing to its direction, clip the
ends to the outlines, and draw as `PmPic` does. It differs from the
plan in these ways:
- The coordinates along each rank are not Brandes and Köpf's: each
  rank is placed by isotonic regression (pool adjacent violators)
  towards the estimate's positions, scaled by the ratio of the
  document's em to the estimate's size, keeping nodes the spacing
  apart. This keeps the estimate's alignment, and is quick in
  MetaPost.
- `--width` scales the finished picture down, where `-t pic` lays the
  diagram out again at a smaller size: MetaPost cannot ask pomermaid
  for another layout.
- Line widths, dashes, markers and spacing are the estimate's pixel
  sizes scaled with the document's em, so they grow with the body
  font.
- Labels are wrapped by pomermaid, in the estimate's font; MetaPost
  sets each line as it is. The characters TeX treats specially, and
  `"`, are written as `{\charN}`.
- `make render` draws each case with ConTeXt too, at a 12 point and an
  8 point body font, in `build/render/cases-context.pdf`.

### Phase 7: subgraphs

**Change:** clusters in `PmLayout` and `pomermaid.mp`: the nodes of a
subgraph kept together, in rank and in order; nested subgraphs; edges
to and from a subgraph's id; the cluster box and title in all writers;
`direction` inside a subgraph.

**Check:** the Galactic-Bounty-Hunters diagrams, whose subgraphs are
the floors of a building; case tests; PDFs from pic and MetaPost.

**Done:** no.

### Phase 8: SVG through groff

**Change:** `PmSvg`, as "SVG" above: the groff page of the picture's
size, the groff and `mutool` runs, `pdftocairo` as the fallback;
`-t svg`, and `-t svg-ms` to write only the groff document;
`--svg-text=text|outline`, `--svg-engine=mutool|pdftocairo`;
exit statuses for a missing program and a failed run, as podoc's
(47, 43). The case tests check the groff document pomermaid writes,
which needs no groff; the SVG itself depends on the versions of groff
and MuPDF, so it is checked by rendering, not byte for byte.

**Check:** case tests of the groff documents; where groff and `mutool`
or `pdftocairo` are installed, each SVG is valid XML (`xmllint`),
`rsvg-convert` draws it the same as the PDF, and the page has no
margin to crop; links checked.

**Done:** no.

### Phase 9: documentation and installation

**Change:** `docs/user/pomermaid.md`: usage; what is supported; how to
use the output from ms, mom, ConTeXt and HTML, and from pandoc and
podoc builds. `docs/user/differences.md`: where pomermaid draws
differently from Mermaid. A man page if the user wants one.

**Check:** `make install` into a scratch prefix; the examples in the
documentation run.

**Done:** no.

### Phase 10: the rest of the flowchart syntax

**Change:** the other shapes (`(round)`, `([stadium])`,
`[[subroutine]]`, `[(cylinder)]`, `((circle))`, `>flag]`,
`{{hexagon}}`, `[/slant/]`, `[\slant\]`, trapezoids,
`(((double circle)))`, and the `@{ shape: ... }` form with its named
shapes), the other edges (`---`, `-.->`, `==>`, `--o`, `--x`, `~~~`,
longer arrows for longer edges, `-- text -->` labels, `&`), `style`,
`linkStyle`, `:::class`, `%%{init: ...}%%` as far as it sets
direction, curves and colours; markdown strings in labels as far as
each writer can set them; `click` and `href`, kept as links in SVG if
Phase 8 finds a way, and ignored elsewhere.

**Check:** case tests for each; Mermaid's own flowchart examples read
without errors and drawn.

**Done:** no.

### Phase 11: the BSDs

**Change:** whatever the BSDs need.

**Check:** `gmake` and `gmake test` on FreeBSD, NetBSD and OpenBSD,
as for podoc (the VMs on atla), with clean copies of the checkout and
the libraries, removed afterwards.

**Done:** no.

### Phases 12 and later: the other diagram types

All of Mermaid's diagram types are in scope (decision 1). Each is a
phase of its own: a reader, a model, a layout, and the three writers,
with case tests and rendered checks, and its section of the user
documentation. The order below puts first the types that reuse the
most of what is already built; the user may reorder it.

| Phase | Type | First line | Layout and notes |
|---|---|---|---|
| 12 | State | `stateDiagram-v2` | layered, as flowcharts; composite states as clusters; start and end markers, forks, choices, notes, concurrency |
| 13 | Class | `classDiagram` | layered; nodes of three compartments; relation ends (inheritance, composition, aggregation), cardinalities, generics, namespaces |
| 14 | Entity relationship | `erDiagram` | layered; attribute tables; crow's-foot ends |
| 15 | Requirement | `requirementDiagram` | layered; requirement and element boxes |
| 16 | Sequence | `sequenceDiagram` | no graph layout: participants in columns, messages in rows; activations, notes, loops, alt and par boxes, autonumber, actors |
| 17 | User journey | `journey` | sections and tasks along a line, scores as faces |
| 18 | Timeline | `timeline` | periods along a line, events below |
| 19 | Gantt | `gantt` | a time axis; dates and durations with poDateTime; sections, milestones, dependencies (`after`), excludes, `dateFormat`, `axisFormat` |
| 20 | Pie | `pie` | sectors and legend |
| 21 | Quadrant | `quadrantChart` | axes, quadrants, points |
| 22 | XY chart | `xychart-beta` | axes, bars and lines |
| 23 | Radar | `radar-beta` | polar axes, polygons |
| 24 | Sankey | `sankey-beta` | columns of nodes, flows as bands (Sankey's own layout) |
| 25 | Git graph | `gitGraph` | branches as lanes, commits along them, merges, tags |
| 26 | Mindmap | `mindmap` | a tree from indentation; radial or two-sided tree layout; node shapes |
| 27 | Treemap | `treemap-beta` | squarified treemap |
| 28 | Block | `block-beta` | the author's grid of columns and spans; no automatic layout |
| 29 | Packet | `packet-beta` | rows of bit fields |
| 30 | Kanban | `kanban` | columns of cards |
| 31 | Architecture | `architecture-beta` | groups, services and edges with sides (`L`, `R`, `T`, `B`); Mermaid uses a force layout (fcose); a layout of our own |
| 32 | C4 | `C4Context` and the others | boxes in boundaries, relations; Mermaid places them in rows |
| 33 | ZenUML | `zenuml` | a plugin, not core Mermaid; sequence diagrams in a code-like syntax, read into Phase 16's model |

Mermaid adds types and changes the `-beta` ones from release to
release. Before each phase, check the type's current syntax in
Mermaid's documentation and record the Mermaid version it follows.

## Open questions

These are the user's to decide. Each decision is recorded, dated,
under "Decisions".

None at present.

## Decisions

2026-11-22, the user's answers to the plan's first questions:

1. **Diagram types:** all of Mermaid's, flowcharts first
   (Phases 12 and later for the rest).
2. **How close to Mermaid:** lay out freely where that is clearer;
   matching Mermaid's drawings is not a goal.
3. **Text sizes for ConTeXt:** the final positioning is done in
   MetaPost, after ConTeXt has measured the labels with `textext`.
4. **Output form:** a `.PS`/`.PE` block for pic and a `\startMPcode`
   block for MetaPost. One diagram per run.
5. **podoc** runs pomermaid as a program, on each `mermaid` block; it
   does not import pomermaid's modules. (A podoc decision and phase,
   later.)
6. **SVG** is in scope (Phase 8).
7. **License:** BSD 3-Clause, as podoc's.
8. **Edges** are curves, as Mermaid's.
9. **Module prefix:** `Pm`.

2026-11-22, later:

10. **SVG is made through groff,** from the pic drawing: groff makes a
    PDF the picture's size, and `mutool` (or `pdftocairo`) turns it
    into SVG. No SVG writer of pomermaid's own, for now. This settles
    the question of how SVG labels are measured (Q10): groff measures
    them.

## Later

- A whole-document mode (`-s`) for looking at one diagram alone, if
  the `make render` wrappers turn out not to be enough.
- podoc running pomermaid on `mermaid` blocks (decision 5; to be
  planned in podoc).
- An SVG writer of pomermaid's own (`<svg>` with `rect`, `path`,
  `text`, Bézier edges and `marker` heads), for systems without groff
  or MuPDF, or for links in SVG, if the user wants it.
- Mermaid's themes (`theme: dark`, `forest`, `neutral`, `base` and
  `themeVariables`) mapped to colours.

## State

2026-11-22: the repository was created with this plan, AGENTS.md,
LICENSE (BSD 3-Clause, copied from podoc's) and
`docs/examples/gbh-handdrawn.ms` (the hand-drawn pic version of the
Galactic-Bounty-Hunters diagrams, rendered with `groff -k -ms -p -Tpdf`
on 2026-11-22). The user decided the first nine questions, then SVG
through groff (Decisions 1 to 10).
No code yet; nothing committed.

2026-11-22, Phase 1: `make` and `make test` pass under `-O2` and `-OC`:
`PmIOTest` and 4 case tests (`--help`, `--version`, an unknown `-t`
(22), two input files (6)).

2026-11-22, Phase 2: `make test` passes under `-O2` and `-OC`:
`PmIOTest` and 21 case tests. The three diagrams of the user's files
(copied as `test/cases/gbh-overview.mmd`, `gbh-map.mmd` and
`aftermath.mmd`), and `shapes`, `edges`, `subgraphs`, `styles` and
`frontmatter`, are dumped; their expected `.dump` files are
pomermaid's own output, checked by hand against Mermaid's grammar
(`flow.jison`) and `flowDb.ts` (no Mermaid was run). Nine error cases
give status 64 and `NAME:LINE:COL` messages.

2026-11-22, Phase 3: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest` (25 checks against the made-up font
`test/fonts/devpdf/TT`) and 23 case tests (new: `--size 10pt`, 6, and
a missing font, 97). `make check-groff` passes: 11 lines (ASCII,
Latin-1 accents, ligatures, kerns, typographic quotes and dashes,
runs of spaces) give groff's `\w` width, to the unit, in TR 10, TI 9,
HB 12 and CR 10.5, with groff 1.25.0 and with the system's 1.23.0
(old charset lines); also in HR 7, TB 11 and HI 8 with 1.25.0.

2026-11-22, Phase 4: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest`, `PmLayoutTest` (104 checks: a chain, a
diamond, a cycle, a long edge, labels, a self-loop, the four
directions, components, a crossing, random dense graphs of 12 to 30
nodes in each direction, and the user's three diagrams with `shapes`
and `edges` in each direction: no node overlaps a node or a label,
and no edge's curve, sampled 21 times per Bézier piece, passes
through another node) and 29 case tests (new: six `-t layout` cases,
among them `loops`, with the made-up font `test/fonts/devpdf/TS`).
The `-O2` and `-OC` layouts are the same. Nothing was drawn yet; the
layouts were not compared with Mermaid's.

2026-11-22, Phase 5: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest`, `PmLayoutTest` and 36 case tests (new:
`-t pic` for `shapes`, `edges`, `loops`, `styles`, `gbh-map` and
`colours`, which warns of two colours it does not know; `--width 6x`,
6; the `.layout` files and `options.out` regenerated for wrapping and
`--width`). `make render` draws the seven layout cases with groff
1.25.0 and `-wall` without a warning; each page was looked at: the
shapes, markers, dotted and thick edges, self-loops, styles and the
user's three diagrams are drawn as intended, and the overview has
the hand-drawn version's layout, with Mermaid's curves. Not compared
with Mermaid's own drawings.

2026-11-22, Phase 6: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest`, `PmLayoutTest` and 45 case tests (new:
`-t mp` for `shapes`, `edges`, `loops`, `styles`, `colours`, `gbh-map`
and `aftermath`, with `--mp-macros=input` from `<name>.mp.args`, which
`tools/runcases` now reads; `mpInline`, with the macros inline and
special characters; `--mp-macros=both`, 6; `options.out`
regenerated). The `-O2` and `-OC` outputs are the same. `make render`
runs ConTeXt LMTX on all nine cases at 12 and 8 points without an
error; each page was looked at: the labels fit their boxes at both
sizes, nothing overlaps, and the shapes, heads, markers, dashes,
self-loops and styles are drawn as with `-t pic`. Two diagrams in one
document, with the macros inline, also work.
