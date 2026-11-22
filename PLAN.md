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
- cycles, including an edge from a node to itself.

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

### Phase 2: the flowchart reader

**Change:** `PmLex` and `PmFlow`: the features of "What the user's
diagrams use"; the graph model; the default class and Mermaid's
default colours (nodes #ececff with #9370db, clusters #ffffde with
#aaaa33). `-t dump` writes the model as text, for the tests.

**Check:** unit tests of the reader; the three diagrams of the user's
files read and dumped; errors reported with line and column for bad
input.

**Done:** no.

### Phase 3: text metrics

**Change:** `PmMetrics`: read groff's `DESC` and font files; the width
of a UTF-8 string in a font at a size, with groff's glyph names for
non-ASCII characters (`groff_char(7)`); label lines split at `<br>`;
node sizes by shape, with Mermaid's padding. `--font` and `--size`
(defaults: `TR`, 10 points).

**Check:** widths compared with groff's own, by `\w'...'` in a groff
run, for ASCII and accented text.

**Done:** no.

### Phase 4: layout

**Change:** `PmLayout`, both halves: cycle removal, ranking, dummy
nodes, crossing reduction; coordinates, edge routes, all four
directions; self-loops; the B-spline to Bézier conversion. Subgraphs
are laid out as plain nodes here (Phase 7 adds clusters). `-t dump`
adds the ranks and orders, each node's box and each edge's points.

**Check:** unit tests on small graphs (a chain, a diamond, a cycle, a
long edge, a self-loop) with known ranks, orders and coordinates; no
two nodes overlap and no edge crosses a node in the user's diagrams.

**Done:** no.

### Phase 5: the pic writer

**Change:** `PmPic`: nodes in their shapes, edges as splines with
their heads and labels, `classDef` colours and widths, label colour;
`.defcolor` lines and `.PS`/`.PE`; `--width` to scale.

**Check:** case tests (`test/cases/*.mmd` against `*.pic`); `make
render` wraps each in a small ms document and makes PDFs with `groff
-k -p -Tpdf`; the user's diagrams look at least as good as the
hand-drawn version.

**Done:** no.

### Phase 6: the MetaPost writer

**Change:** `pomermaid.mp`, the geometry half of the layout in
MetaPost; `PmMp`, the topology as MetaPost data and the macros, in a
`\startMPcode` block; `--mp-macros=inline|input`.

**Check:** case tests against `*.mp`; `make render` wraps each in a
small ConTeXt document and runs ConTeXt LMTX; the labels fit their
boxes in the document's font, with a large and a small body font; no
overlaps in the user's diagrams.

**Done:** no.

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
