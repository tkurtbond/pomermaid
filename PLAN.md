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

The other eleven curves Mermaid takes (2026-11-22, Phase 10.3) are
d3's, followed line by line: `linear`, `step`, `stepBefore`,
`stepAfter`, `cardinal` (tension 0), `catmullRom` (alpha 0.5),
`natural`, `monotoneX`, `monotoneY`, `bumpX` and `bumpY`. Each is
built as cubic Bézier pieces, in `PmCurves` for pic and in
`pm_curved` in `mp/pomermaid.mp` for MetaPost. pic has no Bézier
curve, so the pieces are sampled into a `line` (straight curves, the
steps and `linear`, give their corners alone). An unknown curve is
drawn as basis, with a warning. Where a curve's last control point is
its end (`catmullRom`), MetaPost's end direction is zero, so the
arrow head takes its direction from just before the end
(`pm_enddir`).

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

Diamonds and other polygons are outlined with `line` from point to
point; rounded boxes with `box rad`; circles with `circle`. pic does
not fill a `line`, and its `polygon` is new in groff 1.24, so a
polygon is filled by troff's `\D'P ...'` in a string placed `ljust`
at its first point, `\v'-0.22m'` taking back the offset pic gives a
string (2026-11-22, Phase 10.2; checked with groff 1.25.0 and
1.23.0). The output is the
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
   size and a small margin for the lines' widths (`-P-p`, `.pl`, `.po`,
   `.ll`). pic draws a picture one line space (`.vs`) below where it
   starts, and groff cannot move above the top of a page, so the page
   is one line space taller; pomermaid cuts that band from the SVG's
   root element (its `height` and `viewBox`), so no cropping tool is
   needed.
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
Links (`click`, `href`) do not survive: checked in Phase 8, a link
made by groff's `.pdfhref` is in the PDF, but neither `mutool draw`
(1.28.2) nor `pdftocairo` writes it into the SVG. pomermaid must write
them into the SVG itself (Phase 10).

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

### Phase 7: subgraphs [done]

**Change:** clusters in `PmLayout` and `pomermaid.mp`: the nodes of a
subgraph kept together, in rank and in order; nested subgraphs; edges
to and from a subgraph's id; the cluster box and title in all writers;
`direction` inside a subgraph.

**Check:** the Galactic-Bounty-Hunters diagrams, whose subgraphs are
the floors of a building; case tests; PDFs from pic and MetaPost.

**Done:** `PmLayout` has clusters, as dagre has them: each subgraph is a
cluster; its nodes are kept on consecutive ranks below its title
(`Stack`, which lowers a cluster below another it has an edge from),
and together in each rank between two border nodes, so that ordering
never puts another node between them. The ranks' heights make room for
each cluster's title and padding, nested clusters adding theirs; along
the ranks, `Repair` keeps the borders apart and the box at least as
wide as its title. `PmFlowLayout` makes a node with a subgraph's id,
where the subgraph holds nodes, stand for it, as Mermaid does: the
node is hidden, an edge to it is laid out to the subgraph's first node,
and its route is cut where it meets the subgraph's box. `PmPic` and
`pomermaid.mp` draw each box, parents first, with its title at the
top (at the left in LR and RL), styled by `classDef` and `class` on the
subgraph's id. It differs from the plan in these ways:
- `direction` inside a subgraph is read but not laid out yet: Mermaid
  honours it only for a subgraph no edge crosses, laying that subgraph
  out on its own. It moves to Phase 10.
- A subgraph that holds no node has no box (Mermaid draws an empty
  one).
- Clusters that edges join both ways, directly or through a cycle, are
  not stacked: their nodes are ranked by the edges alone, and the
  boxes may stand side by side or overlap in rank. Stacking them would
  have no end.
- An edge may cross a cluster's title, as in Mermaid.

### Phase 8: SVG through groff [done]

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

**Done:** 2026-11-22. `PmRun` (running programs and the temporary
directory, after podoc's `PdRun`) and `PmSvg`: `-t svg-ms` writes the
groff document, `-t svg` runs `groff -p -Tpdf` and `mutool draw -F svg
-O text=text` (`text=path` for `--svg-text=outline`) or `pdftocairo
-svg` in a temporary directory under `TMPDIR`, removed afterwards,
even when a run fails. `--svg-engine=mutool|pdftocairo`; by default
mutool if it is found, else pdftocairo. `--font-path` is passed to
groff as `-F`. A missing program ends pomermaid with 47, a failed run
with 43. Differences from the plan: the page is one line space taller
than the drawing, a band `PmSvg.Crop` cuts from the SVG's root element
(see "SVG"); the margin is 2 points, or more where a line is wider
than 2 points (`PmPic.Widest`); links do not survive the converters,
so Phase 10 writes them into the SVG. `tools/render` (`make render`)
also writes each case as SVG and checks it with `xmllint`.

### Phase 9: documentation and installation [done]

**Change:** `docs/user/pomermaid.md`: usage; what is supported; how to
use the output from ms, mom, ConTeXt and HTML, and from pandoc and
podoc builds. `docs/user/differences.md`: where pomermaid draws
differently from Mermaid. A man page if the user wants one.

**Check:** `make install` into a scratch prefix; the examples in the
documentation run.

**Done:** 2026-11-22. `docs/user/pomermaid.md` (what it needs,
building, the options, the exit statuses, what it reads and what it
does not yet, and its use from ms, mom, ConTeXt, HTML, pandoc and
podoc, and how it finds fonts), `docs/user/differences.md`, and
`docs/examples/pomermaid.lua`, a pandoc Lua filter that makes each
`mermaid` block pic for ms, MetaPost for ConTeXt and SVG for HTML.
`make install` installs the two documents and the filter in
`$(DOCDIR)`. Found and fixed while checking the examples: the pic
block restored the document's size with `.ps \n[pm*ps]z`, which
groff reads as a thousand times the size; with two diagrams and no
paragraph macro between them, the second was set at 10,000 points.
It is now `u`. Also found: a pic file read with `.so` needs groff's
`-s` (soelim) as well as `-p`, and podoc runs ConTeXt in a temporary
directory, so a diagram `\input` there needs an absolute path; both
are in the documentation. The user then asked for a man page in mdoc
(decision 11): `docs/user/pomermaid.1`, installed in
`$(MANDIR)/man1`, `$(PREFIX)/share/man` by default.

### Phase 10: the rest of the flowchart syntax [done]

**Change:** the other shapes (`(round)`, `([stadium])`,
`[[subroutine]]`, `[(cylinder)]`, `((circle))`, `>flag]`,
`{{hexagon}}`, `[/slant/]`, `[\slant\]`, trapezoids,
`(((double circle)))`, and the `@{ shape: ... }` form with its named
shapes), the other edges (`---`, `-.->`, `==>`, `--o`, `--x`, `~~~`,
longer arrows for longer edges, `-- text -->` labels, `&`), `style`,
`direction` inside a subgraph (moved from Phase 7),
`linkStyle`, `:::class`, `%%{init: ...}%%` as far as it sets
direction, curves and colours; markdown strings in labels as far as
each writer can set them; `click` and `href`, as links in SVG, which
pomermaid writes into the SVG as `<a>` elements over the nodes, since
the PDF's links do not survive the converters (Phase 8), and ignored
elsewhere.

**Check:** case tests for each; Mermaid's own flowchart examples read
without errors and drawn.

Mermaid 12.3.0 is followed: `packages/mermaid/src/docs/syntax/
flowchart.md`, `flow.jison`, `flowDb.ts`, and `rendering-util/
rendering-elements/shapes.ts` with its `shapes/`, at the tag
`mermaid@12.3.0`. The bracket shapes, the edges, `style`, `linkStyle`
and `:::class` were done in Phases 2 to 5. What is left, in steps:

- **10.1, the reader:** the `@{ ... }` metadata of a node (`shape`,
  `label`; `icon`, `img`, `form`, `pos`, `w`, `h` and `constraint`
  kept), of an edge with an id (`curve`; `animate`, `animation` and
  `step` read and ignored) and of a subgraph (`view`); every shape name
  and alias of `shapes.ts`, an unknown one an error as in Mermaid; edge
  ids (`e1@-->`); `class` on edges and subgraphs; `linkStyle ...
  interpolate`; `click` and `href` with their tooltips and targets;
  front matter's `title` and `config`, and `%%{init: ...}%%`. [done]
- **10.2, the named shapes:** the 39 shapes that have no bracket form,
  drawn in pic and MetaPost from one table (`PmShapes`), close to
  Mermaid's drawings. [done]
- **10.3, configuration:** `flowchart.curve` and the edges' `curve`;
  the `themeVariables` that name pomermaid's colours; a title above the
  diagram. Named themes stay in "Later". [done]
- **10.4, markdown strings:** bold and italic in pic (groff's bold and
  italic fonts, measured) and in MetaPost (ConTeXt's), and their
  wrapping. [done]
- **10.5, links:** `click` and `href` as `<a>` elements over the nodes
  in the SVG. [done]
- **10.6, subgraphs:** `@{ view: collapsed }`, and `direction` in a
  subgraph that no edge crosses. [done]
- **10.7:** Mermaid's own flowchart examples; the documentation.
  [done]

**Done:** yes.

### Phase 11: the BSDs [done]

**Change:** whatever the BSDs need.

**Check:** `gmake` and `gmake test` on FreeBSD, NetBSD and OpenBSD,
as for podoc (the VMs on atla), with clean copies of the checkout and
the libraries, removed afterwards.

**Done:** yes.

### Phase 12: state diagrams [done]

**Change:** `stateDiagram-v2` (and `stateDiagram`), read by a new
module, `PmState`, into the flowchart model (`PmFlow.Graph`), so that
the layout and the three writers are shared.

**Check:** case tests for each construct; Mermaid's own state
examples read without errors and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/stateDiagram.md`,
`diagrams/state/parser/stateDiagram.jison`, `stateDb.ts`,
`dataFetcher.ts` and the state shapes of `rendering-elements/shapes/`.
In steps:

- **12.1, the model:** `PmFlow`'s builders exported for other readers
  (`Begin`, `NewEdge`, `NewCluster`, `AddCluster`, `Finish`); a graph
  kind (flowchart or state) and a cluster kind (plain, composite,
  region) with its alternating fill; the shapes `choice`, `state` and
  `state-desc` (a state with descriptions, its title above a line) in
  `PmShapes` and `pomermaid.mp`.
- **12.2, the reader:** states, `state "desc" as id`, descriptions,
  transitions and their labels, `[*]` as a start or end in each
  composite, `<<fork>>`, `<<join>>`, `<<choice>>`, composite states,
  `--` regions, notes (one line and `end note`), `direction`,
  `classDef`, `class`, `:::`, `style`, `click`, comments, and the
  statements Mermaid accepts and pomermaid ignores (`hide empty
  description`, `scale`, `accTitle`, `accDescr`).
- **12.3, drawing:** composite states as clusters with a title band,
  regions dashed, notes in the note colours, start and end markers,
  in pic and MetaPost.
- **12.4:** Mermaid's own examples; the documentation.

### Phase 13: class diagrams [done]

**Change:** `classDiagram` (and `classDiagram-v2`), read by a new
module, `PmClass`, into the flowchart model, with the layout and the
three writers shared.

**Check:** case tests for each construct; Mermaid's own class
examples read without errors and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/classDiagram.md`,
`diagrams/class/parser/classDiagram.jison`, `classDb.ts`,
`classTypes.ts`, `shapeUtil.ts`, the shape `classBox.ts`, and the
markers of `rendering-elements/markers.js` and `edgeMarker.ts`. In
steps:

- **13.1, the model:** a graph kind `Class`; the shape `class` (a box
  of title, members and methods, with an annotation above the title,
  two dividers) and `interface` (a lollipop's label with no box);
  class members as label lines with their classifier (`*` italic,
  `$` underlined); the edge ends extension, composition, aggregation,
  dependency and lollipop; cardinality labels at an edge's two ends.
- **13.2, the reader:** classes, `class X["label"]`, `class X {
  members }`, `X : member`, generics (`~T~`), annotations (`<<ann>>
  X` and in the body), relations with both ends, the solid and
  dotted lines, labels and cardinalities, lollipop interfaces,
  `namespace` (nested and dotted), `note` and `note for`,
  `direction`, `classDef`, `cssClass`, `:::`, `style`, `click`,
  `link`, `callback`, comments and `accTitle`/`accDescr`.
- **13.3, drawing:** class boxes, the relation markers drawn as
  Mermaid draws them, the cardinalities beside the ends, notes,
  namespaces as clusters, in pic and MetaPost.
- **13.4:** Mermaid's own examples; the documentation.

### Phase 14: entity relationship diagrams [done]

**Change:** `erDiagram`, read by a new module, `PmEr`, into the
flowchart model, with the layout and the three writers shared.

**Check:** case tests for each construct; Mermaid's own ER examples
read without errors and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/entityRelationshipDiagram.md`,
`diagrams/er/parser/erDiagram.jison`, `erDb.ts`, `erTypes.ts`,
`erRenderer-unified.ts`, the shape `erBox.ts` and the ER markers of
`rendering-elements/markers.js`. In steps:

- **14.1, the model:** a graph kind `Er`; the shape `erbox` (the
  entity's name above a table of attributes: type, name, keys and
  comment, rows in alternating colours); the ends only one, zero or
  one, one or more and zero or more (crow's feet).
- **14.2, the reader:** entities, aliases (`name[alias]`), attribute
  blocks with keys and comments, relations in symbols and in words,
  identifying and non-identifying lines, roles, `direction`,
  `subgraph`, `classDef`, `class`, `:::`, `style`, comments and
  `accTitle`/`accDescr`.
- **14.3, drawing:** the entity boxes and the crow's-foot markers,
  in pic and MetaPost.
- **14.4:** Mermaid's own examples; the documentation.

### Phase 15: requirement diagrams [done]

**Change:** `requirementDiagram`, read by a new module, `PmReq`, into
the flowchart model, with the layout and the three writers shared.

**Check:** case tests for each construct; Mermaid's own requirement
examples read without errors and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/requirementDiagram.md`,
`diagrams/requirement/parser/requirementDiagram.jison`,
`requirementDb.ts`, `requirementRenderer.ts`, the shape
`requirementBox.ts` and the requirement markers of
`rendering-elements/markers.js`. In steps:

- **15.1, the model:** a graph kind `Req`; the shape `reqbox` (the
  type in guillemets, the name in bold, then a divider and the
  requirement's or element's fields, flush left); the ends contains
  (a circle with a cross) and the open arrow.
- **15.2, the reader:** the six requirement types and `element`, their
  fields, the seven relationships in both directions, `direction`,
  `classDef`, `class`, `:::`, `style`, comments and
  `accTitle`/`accDescr`.
- **15.3, drawing:** the boxes and the markers, in pic and MetaPost.
- **15.4:** Mermaid's own examples; the documentation.

### Phase 16: sequence diagrams [done]

**Change:** `sequenceDiagram`, read by a new module, `PmSeq`, into a
model of its own (participants in columns, events in rows), laid out
by a new module, `PmSeqLayout`, as Mermaid lays it out, and drawn in
pic, SVG and MetaPost.

**Check:** case tests for each construct; Mermaid's own sequence
examples read without errors and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/sequenceDiagram.md`,
`diagrams/sequence/parser/sequenceDiagram.jison`, `sequenceDb.ts`,
`sequenceRenderer.ts`, `svgDraw.js`, `styles.js` and the default
theme. In steps:

- **16.1, the model and the reader:** participants and actors (and
  the `@{ "type": ... }` kinds), aliases, `box`, `create` and
  `destroy`, every message arrow with `+` and `-` activations and
  central connections, `activate` and `deactivate`, notes, `loop`,
  `alt`/`else`, `opt`, `par`/`and`, `par_over`, `critical`/`option`,
  `break`, `rect`, `autonumber`, `title`, `accTitle`/`accDescr`,
  comments, front matter and directives; the dump.
- **16.2, the layout:** Mermaid's widths, margins and vertical walk,
  in points, with podoc's text widths; the layout dump.
- **16.3, pic and SVG:** participants, lifelines, messages and their
  heads, activations, notes, blocks, boxes, sequence numbers.
- **16.4, MetaPost:** the same drawing, its sizes from ConTeXt's
  text (decision 3).
- **16.5:** Mermaid's own examples; the documentation.

### Phase 17: user journeys [done]

**Change:** `journey`, read by a new module, `PmJourney`, into a model
of its own (the title, the sections, the tasks with their scores and
people, the actors), laid out by `PmJourneyLayout` on Mermaid's fixed
geometry, and drawn in pic, SVG and MetaPost.

**Check:** case tests for each construct and error; Mermaid's own
journey example read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/userJourney.md`,
`diagrams/user-journey/parser/journey.jison`, `journeyDb.js`,
`journeyRenderer.ts`, `svgDraw.js`, `styles.js` and the default
theme. In steps:

- **17.1, the model and the reader:** `title`, `section`, tasks
  (`name: score: person, person`), `accTitle`/`accDescr`, comments,
  front matter and directives, keywords in any case; the actors, the
  people of all tasks, each once, sorted; the dump.
- **17.2, the layout:** Mermaid's pixels at the labels' size: the
  legend (a circle and the name of each actor, wrapped at 360
  pixels), the left margin from its widest name, sections and tasks
  150 by 50 pixels 50 apart, the task lines, the faces by score, the
  activity line with its arrow; task and section text wrapped to their
  boxes, with PmMetrics' text widths, the sections' and the tasks'
  boxes as high as the highest, and what is below moved down by as
  much; the layout dump.
- **17.3, pic and SVG:** the drawing; the colours of the default
  theme (fillType0 ... 6 for sections, the actors' colours, faceColor,
  textColor), changed by themeVariables.
- **17.4, MetaPost:** the same drawing written directly, its text
  widths from ConTeXt's (decision 3): the legend's names set the left
  margin, task and section text is wrapped by `\framed`.
- **17.5:** Mermaid's example; the documentation.

### Phase 18: timelines [done]

**Change:** `timeline`, read by a new module, `PmTimeline`, into a
model of its own (the title, the direction, the sections, the periods
with their events), laid out by `PmTimelineLayout` on Mermaid's fixed
geometry, left to right (`timeline`, `timeline LR`) or top down
(`timeline TD`), and drawn in pic, SVG and MetaPost.

**Check:** case tests for each construct and error, in both
directions; Mermaid's own timeline examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/timeline.md`,
`diagrams/timeline/parser/timeline.jison`, `timelineDb.js`,
`timelineRenderer.ts`, `timelineRendererVertical.ts`, `svgDraw.js`,
`styles.js` and the default theme. In steps:

- **18.1, the model and the reader:** `timeline`, `LR` and `TD`,
  `title`, `section`, periods and their events (`period : event :
  event`, and `: event` on the lines after), `accTitle`/`accDescr`,
  comments, front matter and directives, keywords in any case; the
  sections as Mermaid draws them, each name once with every period
  under it; the dump.
- **18.2, the layout:** Mermaid's pixels at the labels' size. Left to
  right: sections over their periods, periods 190 pixels wide and 200
  apart, events stacked below them, a dashed line down from each
  period, the activity line with its arrow. Top down: sections across
  the width, periods left of a vertical axis, their events right of
  it on dashed lines. Text wrapped to the nodes, the nodes of a kind
  as high as the highest; the layout dump.
- **18.3, pic and SVG:** the nodes (rounded at the top, a line along
  the bottom) in the default theme's `cScale0` ... `cScale11`, with
  `cScaleLabel` and `cScaleInv`, events brighter; each period its own
  colour without sections, unless `disableMulticolor`; the colours
  changed by themeVariables.
- **18.4, MetaPost:** the same drawing written directly, its text
  sizes from ConTeXt's (decision 3).
- **18.5:** Mermaid's examples; the documentation.

### Phase 19: Gantt charts [done]

**Change:** `gantt`, read by a new module, `PmGantt`, into a model of
its own (the title, the sections, the tasks with their start and end
times and tags, the excluded and included days, the axis's settings),
its dates read and computed with poDateTime; laid out by
`PmGanttLayout` on Mermaid's geometry and a time scale, and drawn in
pic, SVG and MetaPost.

**Check:** case tests for each construct and error, run with `TZ` and
`SOURCE_DATE_EPOCH` set (decisions 14 and 16); Mermaid's own Gantt
examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/gantt.md`,
`diagrams/gantt/parser/gantt.jison`, `ganttDb.js`,
`ganttRenderer.js`, `styles.js` and the default theme; and what they
call, dayjs 1.11 (`customParseFormat`, `advancedFormat`,
`isoWeek`, `add`) and d3 (`scaleTime`, `timeTicks`, the time
intervals, `tickStep`, `timeFormat`). In steps:

- **19.1, the model and the reader:** `gantt`, `title`, `section`,
  tasks (`name : tags, id, start, end`), `dateFormat`, `axisFormat`,
  `tickInterval`, `todayMarker`, `excludes`, `includes`, `weekday`,
  `weekend`, `inclusiveEndDates`, `topAxis`, `click`, `accTitle` and
  `accDescr`, comments, front matter (`displayMode`) and directives;
  dates parsed as dayjs's strict `customParseFormat` parses them, or
  as JavaScript's `Date` parses ISO forms, in local time; durations,
  `after` and `until`; excluded days moving a task's end; today from
  `SOURCE_DATE_EPOCH` or the clock; the dump, with each task's times.
- **19.2, the time scale:** the scale from the first start to the last
  end over the chart's width, rounded as d3's `rangeRound`; the ticks,
  d3's automatic intervals or `tickInterval`'s, in local time; their
  labels by `axisFormat`, d3's `strftime` with its English locale.
- **19.3, the layout:** Mermaid's pixels at the labels' size, the task
  text's 11 pixels to the size: the rows (one per task, or packed in
  compact mode), the background rows by section, the excluded days,
  the grid, the bars, milestones and vertical markers, the task text
  inside or outside its bar, the section names, the title, the today
  line; the chart --width wide (decision 15); the layout dump.
- **19.4, pic and SVG:** the drawing in the default theme's Gantt
  colours (`taskBkgColor`, `critBkgColor`, `sectionBkgColor` and the
  others), changed by themeVariables.
- **19.5, MetaPost:** the same drawing written directly, the task
  text's place (inside or outside its bar) decided in MetaPost from
  ConTeXt's text widths (decision 3).
- **19.6:** Mermaid's examples; the documentation.

### Phase 20: pie charts [done]

**Change:** `pie`, read by a new module, `PmPie`, into a model of its
own (the title, `showData`, the sections with their values, the
configuration), laid out by `PmPieLayout` on Mermaid's geometry, and
drawn in pic, SVG and MetaPost.

**Check:** case tests for each construct and error, and for each
legend position; Mermaid's own pie examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/pie.md`,
`parser/src/language/pie/pie.langium` and `common.langium`,
`diagrams/pie/pieDb.ts`, `pieRenderer.ts`, `pieStyles.ts` and the
default theme. In steps:

- **20.1, the model and the reader:** `pie`, `showData`, `title`,
  `accTitle` and `accDescr`, the sections (`"label" : value`, the
  label in double or single quotation marks with its escapes, the
  value an integer or a decimal), comments, front matter and
  directives; keywords in Mermaid's case; a negative value an error,
  a label given again ignored; `pie.textPosition`, `pie.donutHole`,
  `pie.legendPosition` and `pie.highlightSlice`; the dump.
- **20.2, the layout:** Mermaid's pixels at the labels' size, the
  legend's 17 pixels to the size: the circle, 185 pixels in radius;
  the slices, clockwise from the top, those under 1% left out, each
  with its percentage; the title; the legend, right, left, top,
  bottom or centre, its widths measured; the layout dump.
- **20.3, pic and SVG:** the outer circle, the slices in `pie1` ...
  `pie12`, 0.7 opaque (blended over white, as pic has no
  transparency), the highlighted slice larger and opaque, the
  percentages, the title and the legend; the colours, widths, sizes
  and opacity changed by themeVariables.
- **20.4, MetaPost:** the same drawing written directly, the legend's
  place and the drawing's width worked out in MetaPost from ConTeXt's
  text widths (decision 3).
- **20.5:** Mermaid's examples; the documentation.

### Phase 21: quadrant charts [done]

**Change:** `quadrantChart`, read by a new module, `PmQuadrant`, into
a model of its own (the title, the axes' and the quadrants' texts,
the points with their styles, the classes, the configuration), laid
out by `PmQuadrantLayout` on Mermaid's geometry, and drawn in pic,
SVG and MetaPost.

**Check:** case tests for each construct and error, with and without
points, the axes in each place; Mermaid's own quadrant examples read
and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/quadrantChart.md`,
`diagrams/quadrant-chart/parser/quadrant.jison`, `quadrantDb.ts`,
`quadrantBuilder.ts`, `quadrantRenderer.ts`, `utils.ts` and the
default theme. In steps:

- **21.1, the model and the reader:** `quadrantChart`, `title`,
  `accTitle` and `accDescr`, `x-axis` and `y-axis` (one text, or two
  joined by `-->`, a missing second text adding " ⟶ " to the first),
  `quadrant-1` to `quadrant-4`, `classDef`, the points (`text:
  [x, y]`, with `:::class` and styles: `radius`, `color`,
  `stroke-color`, `stroke-width`, checked as Mermaid checks them),
  quoted and markdown texts, `;` and line ends, comments, front
  matter and directives; keywords in any case; `config.quadrantChart`;
  the dump.
- **21.2, the layout:** Mermaid's pixels at the labels' size, the
  quadrants' 16 pixels to the size: the chart 500 pixels square, the
  space for the title and the axes, the quadrants and their texts,
  the borders, the points, drawn in reverse order, and their texts,
  the axes' texts, the y axis's turned; the drawing widened for text
  that does not fit; the layout dump.
- **21.3, pic and SVG:** the quadrants, the borders, the points, the
  texts, the y axis's along a line; the colours changed by
  themeVariables.
- **21.4, MetaPost:** the same drawing written directly, the text with
  ConTeXt's widths.
- **21.5:** Mermaid's examples; the documentation.

### Phase 22: XY charts [done]

**Change:** `xychart-beta` (and `xychart`), read by a new module,
`PmXy`, into a model of its own (the orientation, the title, the
axes, the bar and line plots, the configuration), laid out by
`PmXyLayout` on Mermaid's geometry, and drawn in pic, SVG and
MetaPost.

**Check:** case tests for each construct and error: band and linear
x axes, a given and a computed y range, bars and lines together,
vertical and horizontal, the legend, data labels, rotated labels,
the configuration and themeVariables; Mermaid's own XY chart
examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/xyChart.md`,
`diagrams/xychart/parser/xychart.jison`, `xychartDb.ts`,
`chartBuilder/` (the orchestrator, the axes, the title, the legend,
the plots), `xychartRenderer.ts`, the configuration's schema and the
default theme. In steps:

- **22.1, the model and the reader:** `xychart-beta` and `xychart`
  with `vertical` or `horizontal`, `title`, `accTitle` and
  `accDescr`, `x-axis` (a title, categories, or a range), `y-axis` (a
  title, a range), `bar` and `line` (an optional title, the values,
  a line's points' texts), quoted and markdown texts, unquoted texts
  joined as Mermaid's lexer joins them, `;` and line ends, comments,
  front matter and directives; the axes' defaults from the data, as
  `xychartDb.ts` sets them; `config.xyChart`; the dump.
- **22.2, the layout:** Mermaid's pixels at the labels' size (16
  pixels to the size), the chart 700 by 500: the space for the title,
  the axes and the legend, as the orchestrator gives it, vertical and
  horizontal; band and linear scales, d3's ticks; the bars, the
  lines, the legend, the data labels; the drawing widened for text
  that does not fit; the layout dump.
- **22.3, pic and SVG:** the background, the bars, the lines, the
  texts, the axes, the turned texts; the colours changed by
  themeVariables.
- **22.4, MetaPost:** the same drawing written directly, the text with
  ConTeXt's widths.
- **22.5:** Mermaid's examples; the documentation.

### Phase 23: radar charts [done]

**Change:** `radar-beta`, read by a new module, `PmRadar`, into a
model of its own (the axes, the curves, the options, the title),
laid out by `PmRadarLayout` on Mermaid's geometry, and drawn in pic,
SVG and MetaPost.

**Check:** case tests for each construct and error: axes with and
without labels, curves with plain and named entries, the options
(`showLegend`, `ticks`, `max`, `min`, `graticule`), circle and
polygon graticules, the configuration and themeVariables; Mermaid's
own radar examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/radar.md`,
`diagrams/radar/` (`radar.langium`, `db.ts`, `renderer.ts`,
`styles.ts`), the configuration's schema and the default theme. In
steps:

- **23.1, the model and the reader:** `radar-beta`, `title`,
  `accTitle` and `accDescr`, `axis` (names, labels, several lines),
  `curve` (names, labels, entries plain or by axis), the options,
  comments, front matter and directives; Mermaid's errors;
  `config.radar`; the dump.
- **23.2, the layout:** Mermaid's pixels, the chart 600 by 600 in
  margins of 50: the graticule, the axes and their labels, the
  curves (closed Catmull-Rom curves or polygons), the legend, the
  title; the drawing widened for text that does not fit; the layout
  dump.
- **23.3, pic and SVG:** the fills over white (decision 22), the
  outlines, the texts; the colours changed by themeVariables.
- **23.4, MetaPost:** the same drawing, the curves as Béziers.
- **23.5:** Mermaid's examples; the documentation.

### Phase 24: sankey diagrams [done]

**Change:** `sankey-beta` and `sankey`, read by a new module,
`PmSankey`, into a model of its own (the nodes, in order, and the
links, each a source, a target and a value), laid out by
`PmSankeyLayout` as d3-sankey 0.12.3 lays it out for Mermaid, and
drawn in pic, SVG and MetaPost.

**Check:** case tests for the CSV (quoted fields, `""`, blanks, blank
lines, comments), each node alignment, the configuration (`width`,
`height`, `nodeWidth`, `nodePadding`, `showValues`, `prefix`,
`suffix`, `labelStyle`, `nodeColors`, `linkColor`), and the errors
(a missing field, a value that is not a number, a circular link);
Mermaid's own sankey examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/sankey.md`,
`diagrams/sankey/` (`parser/sankey.jison`, `sankeyDB.ts`,
`sankeyRenderer.ts`, `sankeyUtils.ts`, `styles.js`), the
configuration's schema, and d3-sankey 0.12.3's `sankey.js`,
`align.js` and `sankeyLinkHorizontal.js`. In steps:

- **24.1, the model and the reader:** the first line, the records,
  nodes in order of first appearance; comments, front matter and
  directives; `config.sankey`; the errors; the dump.
- **24.2, the layout:** d3-sankey's: the nodes' depths and heights,
  their layers by the alignment, their breadths, relaxed 6 times,
  collisions resolved, the links' breadths; Mermaid's labels, legacy
  and outlined; the colours (Tableau10 by node, `nodeColors`) and the
  links' (gradient, source, target or a colour); the layout dump.
- **24.3, pic and SVG:** the links as bands, sliced for a gradient,
  blended over white, then the nodes, then the labels (decision 23).
- **24.4, MetaPost:** the same drawing.
- **24.5:** Mermaid's examples; the documentation.

### Phase 25: git graphs [done]

**Change:** `gitGraph`, read by a new module, `PmGit`, into a model
of its own (the commits, in Mermaid's order, each with its id,
message, type, tags, parents and branch; the branches, each with its
name, order and tip), laid out by `PmGitLayout` as Mermaid's
`gitGraphRenderer.ts` draws it, and drawn in pic, SVG and MetaPost.

**Check:** case tests for each direction (LR, TB, BT),
`parallelCommits`, `rotateCommitLabel`, `showBranches` and
`showCommitLabel`, merges, cherry-picks (with `parent:`), tags,
commit types, rerouted arrows, a duplicate id, the theme's variables,
and the errors; Mermaid's own git graph examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/gitgraph.md`, the Langium
grammar (`packages/parser/src/language/gitGraph/`),
`diagrams/git/gitGraphAst.ts`, `gitGraphParser.ts`,
`gitGraphRenderer.ts` and `styles.js`, and the default theme's git
colours. In steps:

- **25.1, the model and the reader:** the statements, their
  arguments and strings; the db's rules and errors; `config.gitGraph`;
  the dump.
- **25.2, the layout:** the branches' places by order, the commits'
  (in sequence, or parallel), the branch lines and labels, the arrows
  (straight, curved, or rerouted through a free lane), the bullets of
  each type, the commit labels and tags, turned for TB and BT and by
  `rotateCommitLabel`, the title; the layout dump.
- **25.3, pic and SVG; 25.4, MetaPost:** the same drawing, in the
  layout's order.
- **25.5:** Mermaid's examples; the documentation.

### Phase 26: mindmaps [done]

**Change:** `mindmap`, read by a new module, `PmMindmap`, into a tree
of nodes (each with its id, label, shape, indentation level, depth,
section, icon and class), laid out by `PmMindmapLayout` as a
two-sided tree (decision 29) in a `PmDraw.Drawing`, and drawn in pic,
SVG and MetaPost by `PmDrawPic`, `PmSvg` and `PmDrawMp`.

**Check:** case tests for each shape, the branch and depth colours,
`padding` and `maxNodeWidth`, wrapped labels, deep trees, comments,
tabs, quoted labels, icons and classes, and the errors; Mermaid's own
mindmap examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/mindmap.md`, the Jison
grammar (`diagrams/mindmap/parser/mindmap.jison`), `mindmapDb.ts`,
`mindmapRenderer.ts`, `styles.ts`, the shapes it draws
(`rendering-util/rendering-elements/shapes/`: `defaultMindmapNode`,
`cloud`, `bang`, `hexagon`, `roundedRect`, `squareRect`, `circle`)
and the default theme's `cScale` colours. In steps:

- **26.1, the model and the reader:** indentation, the shapes'
  brackets, `::icon()` and `:::` classes, comments, the db's rules
  (one root; a node's parent is the nearest less indented node) and
  errors; `config.mindmap`; the dump.
- **26.2, the layout:** each node's size, by shape, with its label
  wrapped at `maxNodeWidth`; the root's children to its left and
  right, by turns, each subtree in its band; the edges as curves,
  narrowing with depth; the colours by section or by depth; the
  layout dump.
- **26.3, pic and SVG; 26.4, MetaPost:** the same drawing, through
  `PmDraw`; `PmSvg`'s git-only procedures became `WriteDrawing` and
  `WriteDrawingDocument`, for any `PmDraw.Drawing`.
- **26.5:** Mermaid's examples; the documentation.

### Phase 27: treemaps [done]

**Change:** `treemap-beta` and `treemap`, read by a new module,
`PmTreemap`, into a tree of sections and leaves (each with its name,
value, indentation level and class styles), laid out by
`PmTreemapLayout` as Mermaid lays it out, with d3-hierarchy's
squarified treemap, and drawn through `PmDraw` by `PmDrawPic`,
`PmSvg` and `PmDrawMp`. Values are formatted by a new module,
`PmFormat`, d3-format 3.1.0's `format`.

**Check:** case tests for nesting, a title, `valueFormat`, classes,
`showValues`, `padding`, comments and the accessibility lines, a
lone leaf, an empty treemap and the errors; `PmFormatTest` for the
number formats; the layout checked against an independent
re-implementation of d3's squarify; Mermaid's own treemap examples
read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/treemap.md`, the Langium
grammar (`packages/parser/src/language/treemap/treemap.langium`) and
its value converter, `diagrams/treemap/` (`parser.ts`, `db.ts`,
`utils.ts`, `renderer.ts`, `styles.ts`), d3-hierarchy 3.1.2's
`treemap`, `squarify`, `dice` and `slice`, d3-format 3.1.0, and
`handDrawnShapeStyles.ts`'s `styles2String` for the classes. In
steps:

- **27.1, the model and the reader:** the grammar's tokens, in its
  order; rows by indentation; classes; the configuration; the dump.
- **27.2, the number formats:** `PmFormat`, d3-format's specifiers,
  and Mermaid's `$` forms of `valueFormat`.
- **27.3, the layout:** d3's sums, sorting, paddings, squarify and
  rounding; the colours, blended where Mermaid's are translucent; the
  labels sized and shortened as Mermaid's renderer does.
- **27.4, pic, SVG and MetaPost:** the same drawing; `PmDraw`'s
  fitted texts (`AddFittedText`), which `PmDrawMp` sets no wider than
  pomermaid measured them (decision 43).
- **27.5:** Mermaid's examples; the documentation.

### Phase 28: block diagrams [done]

**Change:** `block-beta` and `block`, read by a new module,
`PmBlock`, into a tree of blocks (each with its shape, label, width
in columns, block-arrow directions, classes and style), composite
blocks with their columns, spaces, and the links between blocks;
`PmBlockDump` writes the model for `-t dump`. `PmBlockLayout` sizes
and places the blocks as Mermaid does (`setBlockSizes` and
`layoutBlocks`: the widest child sets the column width, spans add
the padding between them, rows take their tallest block), draws each
shape from Mermaid's formulas, and cuts each link at the outlines of
its two blocks; `PmDrawPic`, `PmSvg` and `PmDrawMp` draw it.
`PmStyle` gives the blocks' and links' colours (`BlockStyle`,
`BlockEdgeStyle`).

**Check:** case tests for columns, spans, composite blocks, every
shape, block arrows, spaces, links with their markers and labels,
classes and styles, the warnings and the errors; Mermaid's own block
examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/block.md` and
`diagrams/block/` (`parser/block.jison`, `blockDB.ts`, `layout.ts`,
`renderHelpers.ts`, `blockRenderer.ts`), the shapes it draws with
(`rendering-util/rendering-elements/shapes/`) and `blockArrow.ts`.
In steps:

- **28.1, the model and the reader:** the jison lexer's tokens, with
  its word boundaries; composite blocks, columns, widths, spaces,
  links, classes and styles; the dump.
- **28.2, the layout:** sizes, positions and the filled-columns rule;
  the shapes and the block arrows.
- **28.3, pic, SVG and MetaPost:** the drawing, links cut at the
  outlines, their markers and labels.
- **28.4:** Mermaid's examples; the documentation.

### Phase 29: packet diagrams [done]

**Change:** `packet-beta` and `packet`, read by a new module,
`PmPacket`, into rows of fields' parts (a field longer than a row's
rest is split at the row's end), with the title and the `packet`
configuration; `PmPacketDump` writes the model for `-t dump`.
`PmPacketLayout` draws it as Mermaid's renderer does, in a
`PmDraw.Drawing`: a box for each part, its label in the middle and
its first and last bit numbers over it, and the title below the rows.
`PmStyle.PacketColours` gives `themeVariables`' `packet` colours and
sizes.

**Check:** case tests for `+n` fields, split fields, single bits,
`bitOrder: descending`, `showBits: false`, the configuration, the
theme variables, the syntax (comments, directives, `accTitle`,
`accDescr`, escapes) and Mermaid's errors; Mermaid's own packet
examples read and drawn.

Mermaid 12.3.0 is followed: `docs/syntax/packet.md`,
`diagrams/packet/` (`parser.ts`, `db.ts`, `renderer.ts`, `styles.ts`)
and the Langium grammar, `packages/parser/src/language/packet/`.

### Phase 30: kanban boards [done]

**Change:** `kanban`, read by a new module, `PmKanban`, with
mindmap's lexer: sections (the least indented nodes) and their items,
`@{ ... }` metadata (`label`, `shape`, `ticket`, `assigned`,
`priority`), icons and classes; `PmKanbanDump` writes the model for
`-t dump`. `PmKanbanLayout` draws it as Mermaid's renderer does, in a
`PmDraw.Drawing`: a coloured column for each section, its label along
its top, and its items below it, with their priority lines, tickets
and assignees. `PmStyle.KanbanColours` gives the colours, with
`PmStyle.Lighten`, khroma's `lighten`.

**Check:** case tests for sections and items, metadata, shapes,
markdown labels, many sections, `sectionWidth` and theme variables,
an empty board and Mermaid's errors; Mermaid's examples read and
drawn.

Mermaid 12.3.0 is followed: `docs/syntax/kanban.md`,
`diagrams/kanban/` (`parser/kanban.jison`, `kanbanDb.ts`,
`kanbanRenderer.ts`, `styles.ts`) and the kanban item shape,
`rendering-util/rendering-elements/shapes/kanbanItem.ts`.

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

2026-11-22, at the end of Phase 9:

11. **A man page:** yes, `pomermaid.1`, in mdoc, installed by `make
    install` beside the markdown documentation.

2026-11-22, in Phase 10.6:

12. **Subgraphs as Mermaid lays them out.** A subgraph that no edge
    crosses (an edge to the subgraph's own id does not count) is
    laid out alone, in its own `direction`, or, without one, LR in a
    TB parent and TB otherwise, as Mermaid's extractor does; its rank
    spacing is 25 pixels more than its parent's. Each such subgraph,
    and the root, is one layout scope, inner first; in MetaPost each
    is a `pm_begin ... pm_endsub(k)` block whose picture is placed as
    a node of its parent (`pm_begin` now comes before the nodes'
    sizes). A collapsed subgraph (`@{ view: collapsed }`), the
    outermost only, is one node sized as Mermaid's `collapsedGroup`;
    what it holds is hidden, edges to it are redirected, and those
    that would join it to itself are dropped. `class` applies to
    subgraphs and edges, as Mermaid 12.3.0 applies it (`flowDb.ts`).

2026-11-22, before Phase 12, the user's answer:

13. **The classic look for every type.** Since v12.0.0 Mermaid draws
    flowcharts and state, class, ER, requirement and sequence diagrams
    by default in the `redux-color` theme and the `neo` look
    (`docs/config/theming.md`, "Per-diagram defaults"); the `default`
    theme and `classic` look are what a diagram gets when it asks for
    them. pomermaid draws the `default` theme and `classic` look for
    every type, as its flowcharts already do: consistent between types
    and good in print. The new look is in "Later".

2026-11-23, before Phase 19, the user's answers:

14. **Today, as Mermaid, but reproducible.** A Gantt chart's today
    line, an `after` or `until` that names no known task, and a date
    format without a year or a day use today's date, as Mermaid does;
    today is taken from `SOURCE_DATE_EPOCH` (seconds since 1970, the
    reproducible-builds convention) when it is set, else from the
    clock.
15. **A Gantt chart fills --width.** Mermaid's chart is as wide as its
    container, 1200 pixels without one; pomermaid's is --width wide (6
    inches by default), or 1200 of Mermaid's pixels at the labels'
    size with --width 0. `gantt.useWidth` in the configuration, in
    pixels, overrides both.
16. **Local time, as Mermaid.** Dates are read and computed in the
    local time zone, through poDateTime's `TimeZones.Local` (the C
    library's, so `TZ` is honoured), with its daylight-saving rules.
    The case tests set `TZ`.

2026-11-23, in Phase 20, under decision 2:

17. **A pie chart's title is centred over the pie.** Mermaid centres
    it at 225 pixels, the pie's centre unless the legend is on the
    left, which moves the pie right and leaves the title over the
    legend. pomermaid centres it over the pie wherever the legend is,
    and a title wider than the drawing widens it on both sides,
    where Mermaid's is cut off.

2026-11-23, in Phase 21, under decision 2:

18. **A quadrant chart's texts widen the drawing.** Mermaid draws
    the chart in a fixed box and lets a title, a point's text or an
    axis's text that does not fit run past its edge, where it is cut
    off. pomermaid takes the union of the chart, its texts and its
    points as the drawing's bounds, and moves the drawing to start at
    (0, 0).

2026-11-23, in Phase 22, under decision 2:

19. **An XY chart's texts widen the drawing,** as a quadrant chart's
    do (decision 18): a title, a legend or a label that runs past
    Mermaid's fixed box widens the drawing instead of being cut off.
20. **Turned x axis labels are turned about their centres.** With
    `labelRotation`, Mermaid reserves the turned labels' height below
    the axis and turns each label about the middle of its top, moved
    by half its turned width. pomermaid reserves the same height and
    draws each label turned about its centre, under its tick, in the
    middle of that height, which pic and MetaPost draw alike.
21. **Each bar shows its own value.** With `showDataLabel`, Mermaid
    labels the bars of every bar plot with the first plot's values.
    pomermaid labels each bar with its own.

2026-11-23, in Phase 23, under decision 2:

22. **A radar chart's transparent fills are blended.** pic has no
    transparency, so, as for pie charts' and Gantt charts' opacity,
    each fill Mermaid draws with an opacity is drawn in its colour
    taken over the colour beneath it: the graticule's rings, from the
    outermost in, each over the one before, starting from white, and
    each curve in its colour over white, in order. Each curve's
    outline is drawn after all the fills, so that no curve hides
    another's. MetaPost draws the same, so that the outputs agree.
    A radar chart's texts widen the drawing, as decision 19 says.

2026-11-23, in Phase 24, under decision 2:

23. **A sankey diagram's links are opaque bands under the labels.**
    Mermaid strokes each link with its gradient, or a colour, at an
    opacity of 0.5, blended by multiplying, over the nodes and
    labels. pic has neither, so, as decision 22 says, each link is
    its colour taken over white, its gradient drawn as slices across
    it, each of its colour where it is; and the links are drawn
    first, then the nodes, then the labels, so that no link hides a
    label. Where links cross, the later covers the earlier. The
    outlined labels' halo is not drawn. MetaPost draws the same. A
    sankey diagram's texts widen the drawing, as Mermaid's do: its
    bounds are its items'.

2026-11-23, in Phase 25, under decision 2:

24. **A git graph's made commit ids are a hash.** Mermaid gives a
    commit without an id its sequence number, "-" and 7 random
    hexadecimal digits, different on each run. pomermaid's 7 digits
    are a hash of the number, the branch and the message, so that the
    output is the same each time and can be tested.
25. **A git graph's commit label backgrounds are blended.** Mermaid
    draws them at an opacity of 0.5; pic has no transparency, so, as
    decision 22 says, each is its colour taken over white. It hides
    what is beneath it, an arrow's line, for one.
26. **A git graph's arrows are Béziers.** Mermaid's arrows turn their
    corners with SVG arcs; pomermaid's are quarter circles, each a
    Bézier (with Mermaid's centres and radii), which MetaPost draws as
    it is and pic takes at 8 points. pic's lines have no round caps,
    so each arrow has a filled circle at each end, as wide as it.
27. **A git graph's labels are a line each.** Branch names, commit
    ids and tags are each set on one line, as Mermaid sets them, and
    are not passed through Mermaid's `sanitizeText`, which removes
    HTML: pic and MetaPost have none to remove.
28. **A duplicate commit id is a warning.** Mermaid writes it to the
    browser's console and replaces the earlier commit; pomermaid
    does the same, writing the warning, with the line, to standard
    error.

2026-11-23, in Phase 26, under decision 2:

29. **A mindmap is laid out as a two-sided tree.** Mermaid lays it out
    with cose-bilkent, a force-directed layout whose result depends on
    its random start and many iterations. pomermaid places the root's
    children to its left and right by turns, as Mermaid's results
    mostly look, and each subtree in a band of its own height, so that
    nothing overlaps and the output is the same each time. Node sizes,
    shapes, colours and edge widths are Mermaid's.
30. **A mindmap's icons and classes are read but not drawn.** Icons
    are Font Awesome or Material Design glyphs and classes are the
    page's CSS; pomermaid has neither. Each is read, kept in the
    model (and the dump), and warned about, with its line, on
    standard error.
31. **A cloud's and a bang's arcs are polygons.** Mermaid draws these
    outlines with SVG arcs; pomermaid samples each arc at 16 points
    and draws the outline as a filled polygon, in pic, SVG and
    MetaPost alike.
32. **MetaPost centres the lines of a label.** `PmDrawMp`'s labels of
    more than one line, a wrapped mindmap node's, are set
    `align=middle`, as Mermaid centres them; a git graph's labels, of
    one line, are unchanged in the drawing.

2026-11-23, in Phase 27, under decision 2:

33. **A treemap's translucent colours are blended.** Mermaid draws a
    section's fill at an opacity of 0.6 and its outline at 0.4, and a
    leaf's fill at 0.3; as decision 22 says, each is its colour taken
    over the colour beneath it, the parent section's as drawn, or
    white.
34. **A treemap section's label that does not fit is left out.**
    Mermaid draws it and clips it to the header; pic cannot clip, so
    it is drawn only when it fits, 6 pixels in from each side. A
    leaf's label is fitted as Mermaid fits it, and its last check, that
    the label fits at all, is made for every treemap.
35. **A treemap's classes draw `fill`, `stroke`, `stroke-width` and
    `color`.** Mermaid passes the others to the page's CSS; pomermaid
    warns of each, with its line.
36. **Numbers that JavaScript writes by their shortest form are
    written to 15 significant digits** by `PmFormat`, and a width
    above 1000 is not accepted.
37. **A treemap value that is not a finite number is an error.**
    Mermaid's grammar takes digits, `_`, `.` and `,`; JavaScript's
    `Number` makes `NaN` of most with `_` or `,`, and Mermaid draws
    nothing sensible for them. A number too large is `Infinity`.
    pomermaid stops with a parse error for each.
38. **An invalid format after `$` in `valueFormat` is an error.**
    Mermaid logs it in the browser's console and shows the number
    unformatted.
39. **`nodeWidth` and `nodeHeight` set the treemap's size.** Mermaid's
    documentation says 100 each, but its code uses them as the whole
    treemap's size, 960 by 500 by default, and so does pomermaid. A
    value that is not positive is ignored.
40. **Long treemap labels are shortened by characters,** code points,
    where Mermaid's browser counts UTF-16 units.
41. **A treemap box of no width or height is not drawn;** a value of
    0, or a `NaN` in Mermaid's arithmetic, gives such a box.
42. **The peer colours, `cScalePeer0` to `cScalePeer11`, are fixed
    defaults,** the default theme's, each changed by its
    themeVariable; Mermaid would darken a changed `cScale` colour for
    its peer, which pomermaid does not, as with the timelines'
    colours.
43. **In ConTeXt, a treemap's labels are set no wider than pomermaid
    measured them.** MetaPost's labels are set in the document's font
    and size, relative to the body font; a treemap's boxes are fixed
    and do not grow around them, so each label is shrunk, if it must
    be, to the width pomermaid measured, and stays in its box.
44. **Block diagrams: what Mermaid accepts but cannot draw is an
    error** (2026-11-23): a chain of links (`a --> b --> c`), a link
    in a composite block's header, `style` for a block that does not
    exist, a width of 0 and `columns 0`. A `class` for an unknown id
    is ignored, as in Mermaid.
45. **Blocks Mermaid keeps but does not draw are warned of**
    (2026-11-23): a block defined a second time, the blocks of a
    composite block defined a second time, a block named by `class`
    before it is defined, and a block whose id is `root`. Links to
    them are left out. Generated ids (`id-1`, ...) are numbered in
    order, so the output does not change from run to run.
46. **Block class names are split at blanks** (2026-11-23); a
    `class` id with blanks before it, which Mermaid looks up with the
    blanks, is ignored with a warning. `classDef` and `style` are read
    as the flowcharts' are (`PmFlow.Props`); in `style`, `;` ends a
    declaration as `,` does, as in the CSS Mermaid puts it in.
47. **Block labels are measured with pomermaid's metrics and not
    wrapped** (2026-11-23).
48. **Block outlines are approximated** (2026-11-23): links are cut
    where they leave the drawn outline of each block; a stadium is a
    box with round ends; a cylinder is a polygon, its arcs taken at 16
    points; outlines are never dashed; the arrowheads, circles and
    crosses at the ends of links are drawn about as Mermaid's markers
    are.
49. **Packet theme variables are drawn** (2026-11-23):
    `themeVariables`' `packet` colours and sizes are applied, though
    Mermaid's documentation says they do not work in Mermaid.
50. **A packet diagram keeps Mermaid's view box** (2026-11-23): its
    drawing is as wide and high as Mermaid's SVG, an unseen box, so
    the bit numbers and the space below the rows are as Mermaid's.
51. **Packet numbers above 999999999 are an error** (2026-11-23),
    where Mermaid's would lose precision or take a long time.
52. **`bitsPerRow` must be a whole number from 1 to 100000**
    (2026-11-23); another is ignored with a warning, and 32 is used.
    More than 10000 rows are left out with a warning, as Mermaid
    leaves them out.
53. **Kanban sections past the tenth reuse the first ten's colours**
    (2026-11-23): section k takes cScale((k-1) mod 10 + 2), where
    Mermaid's eleventh and later sections have no colour class.
54. **Kanban tickets are not links** (2026-11-23): `ticketBaseUrl`
    is read, but no output makes a ticket a link; a board with both
    gets a warning.

## Later

- A whole-document mode (`-s`) for looking at one diagram alone, if
  the `make render` wrappers turn out not to be enough.
- podoc running pomermaid on `mermaid` blocks (decision 5; to be
  planned in podoc).
- An SVG writer of pomermaid's own (`<svg>` with `rect`, `path`,
  `text`, Bézier edges and `marker` heads), for systems without groff
  or MuPDF, if the user wants it.
- Mermaid's named themes (`theme: dark`, `forest`, `neutral`, `base`)
  mapped to colours.
- Mermaid 12's `redux-color` theme and `neo` look, its default since
  v12.0.0 for flowcharts and state, class, ER, requirement and
  sequence diagrams (decision 13), drawn when a diagram asks for them.

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

2026-11-22, Phase 7: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest`, `PmLayoutTest` (new: `subgraphs` and
`subgraph-edges` in each direction: no overlaps or crossings, every
node inside each cluster that holds it and no other node overlapping
the box, each box inside its parent's, and no more ranks than four
per node) and 55 case tests (new: `-t layout`, `-t pic` and `-t mp`
for `subgraphs`, `subgraph-edges` (LR, with edges to and from
subgraphs and clusters on a cycle), `subgraph-edges-tb` and
`subgraphs-bt`; the `gbh-map` layout, pic and mp regenerated, now with
its three floors as boxes; every `.mp` regenerated for `pm_begin`'s
and `pm_edge`'s new arguments). The `-O2` and `-OC` outputs are the
same. `tools/render` drew `subgraphs`, `subgraphs-bt`,
`subgraph-edges`, `subgraph-edges-tb` and `gbh-map` with groff 1.25.0
and with ConTeXt LMTX; each page was looked at: the boxes hold their
nodes, nested boxes nest, titles sit inside their boxes, edges to a
subgraph end at its box, and the ConTeXt drawings match groff's. Not
compared with Mermaid's own drawings.

2026-11-22, Phase 8: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest`, `PmLayoutTest`, `PmSvgTest` (new: `Crop`
on mutool's and pdftocairo's root elements, attributes in either
order, and three it must refuse) and 59 case tests (new: `-t svg-ms`
for `gbh-map` and `styles`, bad `--svg-text` and `--svg-engine`, 6;
`badformat` now uses `-t png`). With groff 1.25.0, mutool 1.28.2 and
pdftocairo: every drawn case made SVG with both engines under `-O2`
(the `-O2` and `-OC` SVGs of `gbh-map` are the same), each valid XML
(`xmllint`) and drawn by `rsvg-convert`; measured at 4x, the ink of
each mutool SVG of `make render` is 1.5 to 2 points from every edge of
the page (`styles`, with 2.5 point lines, had 0.75 point before the
margin grew for wide lines); `gbh-map`, `shapes`, `edges`
and `styles`, drawn by `rsvg-convert` at 4x, line up with groff's PDF
drawn by `pdftoppm` (no offset; the pixels that differ are the edges
of glyphs and lines, antialiased differently); `gbh-map` with mutool
and with pdftocairo was looked at. A missing groff, mutool or
pdftocairo gave 47, a failing groff or mutool 43, and no temporary
directory was left behind. Links: see Phase 10.

2026-11-22, Phase 9: `make test` passes under `-O2` and `-OC`:
`PmIOTest`, `PmMetricsTest`, `PmLayoutTest`, `PmSvgTest` and 59 case
tests (the `.pic` files and `version.out` regenerated for the `.ps`
fix and the new version text). `make render` drew every case with
groff 1.25.0 (`-wall`, no warning), ConTeXt LMTX and mutool. The
documentation's examples were run: a diagram in ms (`groff -ms -p`,
and with `.so` and `-s`), in mom (`pdfmom -p`, and `-s -p` with
`.so`), in ConTeXt (inline, `\input`, `\startlinealignment[middle]`,
`\startplacefigure`, and `--mp-macros=input` with the installed
`pomermaid.mp` beside the document), and as SVG in an HTML page
(drawn by headless Chromium); the Lua filter with pandoc 3.14, to ms
(`groff -k -ms -p`, and `--pdf-engine=pdfroff --pdf-engine-opt=-p`
with the system's groff 1.23.0), to ConTeXt (`--pdf-engine=context`)
and to HTML, with two diagrams, `width` and `size` attributes,
non-ASCII text and a code block of another class left as it was;
podoc with raw `ms` and `context` blocks (`--pdf-engine=pdfroff` with
`-s` and `-p`; ConTeXt with an absolute path). Each PDF and the page
were looked at. `make install` and `make uninstall` with a scratch
`PREFIX`, and with `DESTDIR`, install and remove the program, the
macros and the documentation. `pomermaid.1` passes `mandoc -Tlint`
and formats without a warning with `groff -mdoc -wall` (1.25.0 and
1.23.0).

2026-11-22, Phase 10.2: the 39 named shapes are drawn by `PmShapes`
(pic) and by `pm_shapedraw` in `mp/pomermaid.mp` (MetaPost), with
the same sizes, parts and outlines; edges are cut at the outlines.
Polygons in pic are now filled (see "pic"); before, diamonds and the
other polygons were drawn unfilled. `make -B test` passes under `-O2`
and `-OC`: 69 case tests, with the new `named-shapes` (`.dump`,
`.layout`, `.pic`, `.mp`) and `loops.pic`, `shapes.pic`,
`metadata.pic` and `mpInline.mp` regenerated (the fills; `doc` and
`hourglass` sized as named shapes; the new macros). `named-shapes`
was looked at as SVG (groff 1.25.0, mutool), as a PDF from groff
1.23.0 (`-wall`, no warning) and from ConTeXt LMTX.

2026-11-22, Phase 10.3: the curves (see "Curves"), from
`flowchart.curve` in the front matter or `%%{init}%%`, an edge's
`@{ curve }` and `linkStyle ... interpolate`; the `themeVariables` of
Mermaid's default theme that the flowchart uses (`mainBkg`,
`nodeBorder`, `textColor`, `nodeTextColor`, `titleColor`, `lineColor`,
`edgeLabelBackground`, `clusterBkg`, `clusterBorder`, and those they
are made from: `border1`, `border2`, `secondBkg`,
`labelBackground`), in pic and MetaPost; and the title, 18 pixels to
the labels' 16, centred, its baseline 25 pixels above the drawing, as
Mermaid's `titleTopMargin`. The layout keeps room for the title
(`PmLayout.Reserve`), so the SVG's page holds it and a title wider
than the drawing widens it. `make -B test` passes under `-O2` and
`-OC`: 73 case tests, with the new `curves` and `theme` (`.pic`,
`.mp`), and `metadata.pic` (its title and curves) and `mpInline.mp`
(the macros) regenerated. Looked at: all twelve curves as SVG (groff
1.25.0, mutool; drawn with rsvg-convert) and in ConTeXt LMTX with their
arrow heads; the theme and the title in both, with a title wider than
its drawing. mutool's own SVG renderer ignores the per-glyph `x` lists
mutool writes, so SVGs are checked with rsvg-convert.

2026-11-22, Phase 10.4: bold and italic in markdown strings
(`PmEmphasis`), as Mermaid keeps marked's `strong` and `em`
(`handle-markdown-text.ts`, mermaid 12.3.0) and writes everything else
as it was: CommonMark's delimiter runs of `*` and `_`, left- and
right-flanking, `_` not inside a word, the rule of three, nesting
(`***x***` is bold italic) and backslash escapes. A label line keeps
each byte's style. `PmMetrics.LoadStyles` finds the bold, italic and
bold italic of the labels' font by groff's names (a name ending in R,
B, I or BI; any other has none and stays regular), and the widths,
and so the wrapping, are measured in each run's font. pic writes each
styled run as `\f[XB]run\f[]`, so every run starts from, and the label
ends in, the font before it, as pic does not restore fonts; MetaPost
writes `{\bf ...}`, `{\it ...}` and `{\bi ...}`. The dump shows a
styled line's styles after `=`, a digit a byte. `make -B test` passes
under `-O2` and `-OC`: 77 case tests, with the new `markdown`
(`.dump`, `.layout`, `.pic`, `.mp`) in the made-up fonts `XR`, `XB`,
`XI` and `XBI` (different widths, so the measuring shows), and
`shapes` (`.dump`, `.layout`, `.pic`, `.mp`) regenerated, as its
`**markdown**` is now bold. Looked at: the case's labels as SVG
(groff 1.25.0, mutool, drawn with rsvg-convert) and in ConTeXt LMTX
with TeX Gyre Termes.

2026-11-22, Phase 10.5: a node's `click` link and tooltip in the SVG.
After groff's drawing, before the last `</svg>`, PmSvg writes a
`<g class="pm-links">` holding, for each node with a link, an `<a>`
with `href` (and `xlink:href` where the root element declares xlink,
as mutool and pdftocairo do) and the `target` if one was given, as
Mermaid writes it only then; for a tooltip alone, a `<g>`. Each holds
the tooltip as a `<title>` and a rectangle over the node's bounds,
filled white with opacity 0, so it takes the pointer. URLs are made
`about:blank` as Mermaid's `sanitizeUrl` makes them: a URL with a
scheme that starts, after any non-word characters, with `javascript`,
`data` or `vbscript`. Callbacks have no link; their tooltips are kept.
`make -B test` passes under `-O2` and `-OC`: `PmSvgTest` has two new
drawings, with `&`, `<`, a target, a tooltip alone, `JavaScript:` and
`data:` (made `about:blank`), `data-page.html` and `a/b:c.html`
(kept), with and without xlink. Looked at: the rectangles, made
visible, lie on the nodes (rect, hexagon, circle, cylinder) in SVG from
mutool and from pdftocairo (rsvg-convert); both SVGs pass xmllint.

2026-11-22, Phases 10.1, 10.6 and 10.7: 10.1, the reader, was done
with 10.2 to 10.5 (`@{ ... }` metadata, edge ids, `class` on edges and
subgraphs, `linkStyle ... interpolate`, `click` and `href`, front
matter and `%%{init}%%`, with the cases `metadata`, `interpolate`
and `badMeta*`). 10.6: isolated subgraphs laid out alone with their
own `direction`, and collapsed subgraphs (decision 12); the collapsed
group's rule is dashed in MetaPost as in pic and Mermaid; `class` now
styles subgraphs and edges (`PmStyle.ClusterStyle`, `EdgeStyle`), as
it was read but not applied. 10.7: Mermaid 12.3.0's 116 flowchart
examples (`flowchart.md`) all run with exit 0 and no warning under
`-t pic`, and were drawn with `tools/render` in groff (116 pages) and
ConTeXt LMTX (no TeX error) and looked at; the subgraph directions
(TB, RL, BT and the inherited LR) and the collapsed example match
Mermaid's documentation. The documentation (`pomermaid.md`,
`differences.md`, `pomermaid.1`, which passes `mandoc -Tlint`) is
brought up to date. `make test` passes under `-O2` and `-OC`: 86 case
tests, with the new `collapsed`, `isolated` and `classes`, the `.mp`
cases regenerated (the sub-picture blocks) and the subgraph cases'
layouts (the isolated subgraphs); `PmLayoutTest` lays out `collapsed`
and `isolated` with no fault. Looked at: `collapsed`, `isolated`,
`subgraphs` and `metadata` in groff and ConTeXt.

2026-11-22, Phase 11: `gmake` and `gmake test` (both models; the unit
tests and 86 case tests) pass on FreeBSD 15.1 (alerik, x86-64;
rackhir, arm64), NetBSD 11.0 (artos, x86-64; yishana, i386) and
OpenBSD 7.9 (jherek, x86-64; cymoril, i386), from clean copies of the
working tree, removed afterwards, with the ArgParser installed on each
for poc 0.15.0. The first run found two faults.
`metadata.pic` measured with the system's groff fonts, and the BSDs
have other fonts or none (exit 97): it now has `metadata.pic.args`
with the tests' fonts. And on i386 a sampled curve point in
`curves.pic` came out a digit apart, because x87 arithmetic keeps more
precision than REAL's: `PmGeom.OnCurve` now evaluates in LONGREAL and
rounds to REAL once, and `PmIO.WriteReal` (with the new `PmIO.Round`,
also used for pic's polygon fills) makes its product exactly in
LONGREAL, so a REAL just under a tie rounds down everywhere. That
moved 75 numbers in 12 expected files by one in the last digit (each
checked to be exactly that), the rounding now of the REAL's exact
value. pomermaid now also looks for fonts in `/usr/share/groff_font`,
NetBSD's own groff's. On artos, with only NetBSD's groff 1.19.2,
pomermaid found and read its `devps` fonts with no `--font-path`, and
`groff -p -ms -Tps -wall` drew `theme`, `classes` and nine other cases
(fills, colours, dashes, collapsed and nested isolated subgraphs)
without a warning; looked at with Ghostscript. groff 1.24.1 (yishana,
pkgsrc) did the same. Linux's `make test` passes under both models.

2026-11-22, Phase 12: state diagrams. `PmState` reads
`stateDiagram-v2` and `stateDiagram` into `PmFlow`'s model, with
`PmFlow`'s builders exported (`Begin`, `NewEdge`, `NewCluster`,
`AddCluster`, `Finish`, `MarkdownLabel`, `SkipFrontMatter`); the graph
and cluster kinds, the alternating fill of composite states and
regions, and the shapes `choice`, `state` and `state-desc` in
`PmShapes`, `PmStyle`, both writers and `pomermaid.mp`. The reader
follows Mermaid 12.3.0's `stateDiagram.jison`, `stateDb.ts` and
`dataFetcher.ts`: `[*]` as each composite's and region's start and
end, `--` regions (renamed as Mermaid renames them), notes with
Mermaid's ids, descriptions, forks, joins and choices, and `class`,
`style` and `click` applied at the end. `make test` passes under
`-O2` and `-OC`: 106 case tests, with the new `state-basic`,
`state-composite`, `state-nested` and `state-classes` (dump, layout,
pic, mp; classes dump and pic) and six error cases. All 21 examples
of Mermaid's `docs/syntax/stateDiagram.md` read with no error or
warning; looked at in SVG: the regions example, the classes example,
the notes example, and the four state cases in `make render`.
Decision 13 (the classic look for every type) is recorded in
`differences.md`. On the i386 BSDs, a dash boundary on a vertex of a
dotted note edge was taken at the start of the next piece instead of
at the end of the last, which wrote a point twice; `PmPic.Dashes` now
drops a point within 0.01 of the one before it, which took duplicate
points out of `classes.pic`, `edges.pic` and `state-nested.pic`. With
that, `gmake` and `gmake test` (106 case tests under both models)
pass on FreeBSD 15.1 (alerik, rackhir), NetBSD 11.0 (artos, yishana)
and OpenBSD 7.9 (jherek, cymoril), from clean copies, 2026-11-22.

2026-11-22, Phase 13: class diagrams. `PmClass` reads `classDiagram`
and `classDiagram-v2` into `PmFlow`'s model, following Mermaid
12.3.0's `classDiagram.jison`, `classDb.ts`, `classTypes.ts` and
`shapeUtil.ts`: classes made on first use, labels, members in braces
or one at a time, generics, annotations, classifiers (`$` underlined,
`*` italic) and return types, relations with every end and both line
types, labels and cardinalities, lollipop interfaces, notes,
namespaces (nested, dotted, labelled, and
`hierarchicalNamespaces: false`), `classDef`, `:::`, `cssClass`,
`style`, `click`, `link` and `callback`. The model has the shapes
`class` and `interface`, the ends extension, composition,
aggregation, dependency and lollipop, an edge's two cardinalities and
an underlined line. `PmFlowLayout.ClassSize` sizes a class box as
`classBox.ts` does and `Cardinality` places the cardinalities as
`edgeMarker.ts`; `PmPic` and `pomermaid.mp` draw the boxes, the
markers of `markers.js` (each edge shortened as Mermaid shortens it)
and the cardinalities. `pomermaid.mp`'s `pm_sub` and `pm_collapsed`
are now 60 and 61, which changed those numbers in ten expected `.mp`
files and nothing else. `make test` passes under `-O2` and `-OC`:
123 case tests, with the new `class-basic` (dump, layout, pic, mp),
`class-namespaces` and `class-members` (dump, pic, mp),
`class-relations` (dump, pic) and five error cases. All 33 examples
of Mermaid's `docs/syntax/classDiagram.md` read with no error or
warning and were looked at in SVG; `class-basic` and
`class-namespaces` were looked at in ConTeXt's MetaPost output, and
`make render` ran ConTeXt on every case without an error. `gmake`
and `gmake test` (123 case tests under both models) pass on FreeBSD
15.1 (alerik, rackhir), NetBSD 11.0 (artos, yishana) and OpenBSD 7.9
(jherek, cymoril), from clean copies, 2026-11-22.

2026-11-22, Phase 14: entity relationship diagrams. `PmEr` reads
`erDiagram` into `PmFlow`'s model (graph kind `Er`), following
Mermaid 12.3.0's `erDiagram.jison` and `erDb.ts`: entities, quoted
names, aliases, attribute blocks (types with generics and `[]`,
backquoted names, `PK`, `FK` and `UK` keys, comments), relationships
in symbols and in words (`to` and `optionally to`), identifying and
non-identifying lines, roles, `direction`, `subgraph` (nested, with
titles and their own direction), `classDef`, `class`, `:::` and
`style` on entities and subgraphs, comments and `accTitle`/`accDescr`.
The model has the shape `erbox`, each node's attributes and the ends
only one, zero or one, one or more and zero or more.
`PmFlowLayout.ErSize` sizes an entity as `erBox.ts` does (columns of
the widest cell, spread to the name's width), with Mermaid's ER
spacing of 140 and 80 pixels; `PmStyle` has the `rowOdd` and `rowEven`
theme variables; `PmPic` and `pomermaid.mp` draw the tables and the
bars, circles and crow's feet of `markers.js`. The new macros changed
ten expected `.mp` files in their copies of the macros only, and the
list of diagram types changed `notFlow.errors`. `make test` passes
under `-O2` and `-OC`: 139 case tests, with the new `er-basic` and
`er-attributes` (dump, layout, pic, mp), `er-subgraph` (dump, layout,
mp), `er-words` (dump, pic) and three error cases. All 50 examples of
Mermaid's `docs/syntax/entityRelationshipDiagram.md` read with no
error or warning and make SVG; the largest were looked at in Chrome.
`rsvg-convert` runs an entity's cells together, since it ignores
mutool's per-glyph positions; this is noted in `differences.md`. The
four ER cases were looked at in pic and in ConTeXt's MetaPost output,
and `make render` ran ConTeXt on every case without an error.
`gmake` and `gmake test` (139 case tests under both models) pass on
FreeBSD 15.1 (alerik, rackhir), NetBSD 11.0 (artos, yishana) and
OpenBSD 7.9 (jherek, cymoril), from clean copies, 2026-11-22.

2026-11-22, Phase 15: requirement diagrams. `PmReq` reads
`requirementDiagram` into `PmFlow`'s model (graph kind `Req`),
following Mermaid 12.3.0's `requirementDiagram.jison` and
`requirementDb.ts`: the six requirement types and `element`, their
fields (`id`, `text`, `risk`, `verifymethod`, `type`, `docref`), the
seven relationships in both directions, `direction`, `classDef`,
`class`, `:::`, `style`, comments and `accTitle`/`accDescr`. The model
has the shape `reqbox` and the ends contains and arrow;
`PmFlowLayout` sizes the boxes as `requirementBox.ts` does, and
`PmPic` and `pomermaid.mp` draw them and the markers. The new macros
changed ten expected `.mp` files in their copies of the macros only,
and the list of diagram types changed `notFlow.errors`. `make test`
passes under `-O2` and `-OC`: 154 case tests, with the new
`req-basic` and `req-styles` (dump, layout, pic, mp), `req-elements`
(dump, pic, mp) and four error cases (`reqBadRisk`, `reqNoEnd`,
`reqTitle`, `reqUndefined`). All 18 examples of Mermaid's
`docs/syntax/requirementDiagram.md` read with no error or warning,
and `make render` ran ConTeXt on every case without an error.
`gmake` and `gmake test` pass on FreeBSD 15.1 (alerik, rackhir),
NetBSD 11.0 (artos, yishana) and OpenBSD 7.9 (jherek, cymoril), from
clean copies: 154 case tests under both models (on the x86-64 hosts
155, with a `req-elements.layout` since dropped, as i386 rounds one
of its numbers differently), 2026-11-22.

2026-11-22, Phase 16: sequence diagrams. `PmSeq` reads
`sequenceDiagram` into a model of its own (participants, boxes and
events), following Mermaid 12.3.0's `sequenceDiagram.jison` and
`sequenceDb.ts`: participants and actors with the eight
`@{ "type": ... }` kinds and aliases, `box`, `create` and `destroy`,
every message arrow with `+`/`-` and central connections,
`activate`/`deactivate`, notes, the eight blocks with their sections,
`autonumber`, `title`, comments, front matter and directives;
`PmSeqDump` dumps it. `PmSeqLayout` lays it out from the top down, in
a simplified form of `sequenceRenderer.ts` (one text size);
`PmSeqPic` draws it in pic, and SVG comes from that through groff.
For MetaPost, `PmSeqMp` writes the diagram, not its layout, as calls
of the macros in `mp/pomermaid-seq.mp` (copied in as
`PmSeqMacros`, generated by `tools/mp2mod`, or `input`), which lay it
out again with ConTeXt's text sizes and draw it (decision 3);
`make install` installs it beside `pomermaid.mp`. `make test` passes
under `-O2` and `-OC`: 181 case tests, with `seq-arrows` and
`seq-blocks` (dump, layout, pic, mp), `seq-basic` (dump, mp),
`seq-boxes` (dump, pic, mp, svg-ms), `seq-theme` (pic, mp) and eleven error cases
(`seqBadElse`, `seqBadEnd`, `seqBadType`, `seqBoxMessage`,
`seqCreate`, `seqCreateTwice`, `seqDestroy`, `seqInactive`,
`seqNoEnd`, `seqNoText`, `seqTwoBoxes`); the list of diagram types
changed `notFlow`. All 38 examples of Mermaid's
`docs/syntax/sequenceDiagram.md` give no error or warning in dump,
layout, pic, mp and svg, and ConTeXt drew all 38 from `-t mp` without
an error; `make render` ran ConTeXt on every case without an error.
`gmake` and `gmake test` pass on FreeBSD 15.1 (alerik, rackhir),
NetBSD 11.0 (artos, yishana) and OpenBSD 7.9 (jherek, cymoril), from
clean copies: on the x86-64 hosts with 184 case tests, before
`seq-basic.layout`, `seq-basic.pic` and `seq-boxes.layout` were
dropped, as i386 (yishana, cymoril) rounds a few of their numbers
differently in the last digit; after that, 181 case tests under both
models on yishana and cymoril, 2026-11-22.

2026-11-22, Phase 17: user journeys. `PmJourney` reads `journey`
into a model of its own, following Mermaid 12.3.0's `journey.jison`,
`journeyDb.js` and `journeyRenderer.ts`: `title`, `section`, tasks
with scores (JavaScript's `Number`) and people, `accTitle`/`accDescr`,
`%%` and `#` comments, front matter and directives; the actors are
the people, each once, sorted by bytes. `PmJourneyLayout` lays it out
on Mermaid's pixels at the labels' size, with the differences in
`docs/user/differences.md` (the title above the sections, the left
margin from the widest name, boxes that grow for wrapped text, room
for faces far out of 1 to 5); `PmJourneyPic` draws it in pic, and SVG
comes from that through groff; `PmJourneyMp` writes the MetaPost
directly, with no macros, measuring the text with `textext` and
`\framed` (decision 3). The colours are Mermaid's defaults, changed
by `fillType0`..`7`, `actor0`..`5` and `faceColor`
(`PmStyle.JourneyColours`). `make test` passes under `-O2` and `-OC`:
202 case tests, with `journey-basic` (Mermaid's example; dump,
layout, pic, mp, svg-ms), `journey-sections`, `journey-noactors` and
`journey-theme` (dump, layout, pic, mp), and four error cases
(`journeyBadScore`, `journeyColonOnly`, `journeyNoScore`,
`journeySectionColon`); the list of diagram types changed `notFlow`.
The four cases were drawn through groff (SVG, looked at) and through
ConTeXt from `-t mp` (looked at), and `make render` ran on every case
without an error. `gmake` and `gmake test` pass, 202 case tests under
both models, on FreeBSD 15.1 (alerik, rackhir), NetBSD 11.0 (artos,
yishana) and OpenBSD 7.9 (jherek, cymoril), from clean copies,
2026-11-22.

2026-11-23, Phase 18: timelines. `PmTimeline` reads `timeline`
(`LR`, `TD`) into a model of its own, following Mermaid 12.3.0's
`timeline.jison`, `timelineDb.js`, `timelineRenderer.ts` and
`timelineRendererVertical.ts`: `title`, `section`, periods with their
events (`period : event : event`, and `: event` on the lines after),
`accTitle`/`accDescr`, comments, front matter and directives; each
section once, by name, with every period under it, and periods before
the first section warned of and not drawn, as in Mermaid.
`PmTimelineLayout` lays it out on Mermaid's pixels at the labels'
size, left to right or top down, with the differences in
`docs/user/differences.md` (the title, section text wrapped, the top
down spacing and arrowheads); `PmTimelinePic` draws it in pic, and
SVG comes from that through groff; `PmTimelineMp` writes the MetaPost
directly, its heights from ConTeXt's text (decision 3). The colours
are the default theme's `cScale0`..`11`, `cScaleLabel` and
`cScaleInv`, events brighter, changed by themeVariables
(`PmStyle.TimelineColours`), and `disableMulticolor`. `make test`
passes under `-O2` and `-OC`: 234 case tests, with `timeline-basic`
(dump, layout, pic, mp, svg-ms), `timeline-sections`, `timeline-td`,
`timeline-theme`, `timeline-empty` and `timeline-early` (dump,
layout, pic, mp), `timeline-nomulti` (dump, pic, mp; its layout
dropped, as i386 rounds a line's end in the last digit), and four
error cases (`timelineNoPeriod`, `timelineSectionColon`,
`timelineEmptyEvent`, `timelineNoBlank`); the list of diagram types
changed `notFlow`. The cases were drawn through groff (SVG, looked
at) and through ConTeXt from `-t mp` (looked at), and `make render`
ran on every case without an error. Mermaid's 28 timeline examples
(`docs/syntax/timeline.md`) were read and written as dump, layout,
pic, mp and SVG without an error; seven were looked at in SVG and two
through ConTeXt (named themes are drawn in the default colours, as
for every diagram). `gmake` and `gmake test` pass, 234 case tests
under both models, on FreeBSD 15.1 (alerik, rackhir), NetBSD 11.0
(artos, yishana) and OpenBSD 7.9 (jherek, cymoril), from clean
copies, 2026-11-23.

Phase 19, Gantt charts, is done, 2026-11-23, on Mermaid 12.3.0.
`PmGantt` reads `gantt` (tasks with their tags, ids, dates, durations,
`after` and `until`; `dateFormat`, `axisFormat`, `tickInterval`,
`todayMarker`, `excludes`, `includes`, `weekday`, `weekend`,
`inclusiveEndDates`, `topAxis`, `click`, `displayMode`) and computes
the tasks' times as ganttDb.js does, with `PmGanttTime` (dayjs's
parsing, formatting and `add`; JavaScript's `Date`; local time) and
today from `SOURCE_DATE_EPOCH` (decisions 14 and 16).
`PmGanttScale` is d3's time scale, ticks and `strftime`.
`PmGanttLayout` lays the chart out on Mermaid's pixels, --width wide
(decision 15), packed in compact mode; `PmGanttPic` draws it in pic,
and SVG comes from that through groff; `PmGanttMp` writes the
MetaPost directly, with each task's text placed inside or beside its
bar in MetaPost from ConTeXt's width (decision 3). The differences are
in `docs/user/differences.md`. `make test` passes under `-O2` and
`-OC`: the unit tests `PmGanttTimeTest` and `PmGanttScaleTest` and 266
case tests, with `gantt-basic` (dump, layout, pic, mp, svg-ms),
`gantt-compact`, `gantt-tags` and `gantt-empty` (dump, layout, pic,
mp), `gantt-excludes` (dump, layout, pic), `gantt-settings` and
eleven error and warning cases; all run with `TZ=America/New_York`
and `SOURCE_DATE_EPOCH=1700000000`. The cases were drawn through
groff and through ConTeXt and looked at, and `make render` ran on
every case without an error. Mermaid's 22 Gantt examples
(`docs/syntax/gantt.md`) were read and written as dump, layout, pic,
mp and SVG without an error (two warn, as Mermaid does, of a `%%`
inside a task's data); three were looked at in SVG and two through
ConTeXt. The Gantt drawing cases use the test fonts (`.args`), as the
others do, so they need no groff. poDateTime was installed on the BSD
hosts, and `gmake` and `gmake test` pass, 266 case tests under both
models, on FreeBSD 15.1 (alerik, rackhir), NetBSD 11.0 (artos,
yishana) and OpenBSD 7.9 (jherek, cymoril), from clean copies,
2026-11-23.

Phase 20, pie charts, is done, 2026-11-23, on Mermaid 12.3.0. `PmPie`
reads `pie` (`showData`, `title`, `accTitle`/`accDescr`, the sections
with their quoted labels, escapes and values as `pie.langium` reads
them, a negative value an error, a label given again ignored) and
`pie`'s `textPosition`, `donutHole`, `legendPosition` and
`highlightSlice`. `PmPieLayout` lays it out on `pieRenderer.ts`'s
pixels at the labels' size: the slices clockwise from the top, those
under 1% left out, each with its rounded percentage, and the legend
right, left, top, bottom or centre; the title centred over the pie
(decision 17). `PmPiePic` draws it in pic, the slices' opacity taken
over white, and SVG comes from that through groff; `PmPieMp` writes
the MetaPost directly, the legend's place and the drawing's width
worked out from ConTeXt's text widths (decision 3). The colours,
widths and opacity are the default theme's, changed by themeVariables
(`PmStyle.PieColours`). The front matter's YAML reader lost the key
after a nested mapping, a block scalar or a sequence (`config:` with
`pie:` and then `themeVariables:`, as in Mermaid's own example); that
is fixed, with the case `yaml-dedent`. `make test` passes under `-O2`
and `-OC`: 330 case tests, with `pie-basic`, `pie-config`,
`pie-showdata`, `pie-left`, `pie-top`, `pie-center`, `pie-widetitle`,
`pie-allzero`, `pie-small`, `pie-many` and `pie-whole` (dump, layout,
pic, mp, svg-ms), `pie-dup` (dump) and seven error cases; `notFlow`
now uses `zenuml`. The cases were drawn through groff and through
ConTeXt and looked at, and `make render` ran on every case without
an error. Mermaid's two pie examples (`docs/syntax/pie.md`) were read
and written as pic, mp and SVG without an error, and looked at.
`make test` passes, 330 of 330 under both models, on FreeBSD (alerik,
rackhir), NetBSD (artos, yishana) and OpenBSD (jherek, cymoril).

Phase 21, quadrant charts, is done, 2026-11-23, on Mermaid 12.3.0.
`PmQuadrant` reads `quadrantChart` (the title, `accTitle`/`accDescr`,
`x-axis` and `y-axis` with one text or two, `quadrant-1` to
`quadrant-4`, `classDef`, the points with `:::class` and their
styles, checked as Mermaid checks them, and `config.quadrantChart`).
`PmQuadrantLayout` lays it out on `quadrantBuilder.ts`'s pixels at
the labels' size, the axes' texts at the bottom or top and the left
or right as Mermaid places them, the y axis's rotated; the drawing
grows for texts that do not fit (decision 18). `PmQuadrantPic` draws
it in pic (rotated text with `PmPic.Rotated`), SVG coming from that
through groff; `PmQuadrantMp` writes the MetaPost. The colours are
the default theme's, changed by themeVariables
(`PmStyle.QuadrantColours`). `make test` passes under `-O2` and
`-OC`: 362 case tests, with `quadrant-basic` (dump, pic, mp,
svg-ms; its layout dropped, as i386 rounds a point's y in the last
digit), `quadrant-styles`, `quadrant-config`, `quadrant-empty` (dump,
layout, pic, mp, svg-ms),
`quadrant-syntax` (dump, layout, pic), `quadrant-wide` (layout, pic,
mp) and seven error cases. The cases and Mermaid's three quadrant
examples (`docs/syntax/quadrantChart.md`) were drawn through groff,
through ConTeXt and as SVG, and looked at; ConTeXt's font has no ❤.
`make test` passes on FreeBSD (alerik, rackhir), NetBSD (artos,
yishana) and OpenBSD (jherek, cymoril) under both models: 362 of 362
on yishana and cymoril (i386), and 363 of 363 on the others, which
ran before `quadrant-basic`'s layout was dropped.

Phase 22, XY charts, is done, 2026-11-23, on Mermaid 12.3.0. `PmXy`
reads `xychart-beta` and `xychart` (`vertical` or `horizontal`, the
title, `accTitle`/`accDescr`, `x-axis` with a title and categories
or a range, `y-axis` with a title and a range, `bar` and `line` with
optional titles, quoted, markdown and unquoted texts joined as
Mermaid's lexer joins them, and `config.xyChart`), setting the axes'
defaults from the data as `xychartDb.ts` does. `PmXyLayout` lays it
out on the orchestrator's pixels at the labels' size: the title, the
axes (band and linear, d3's ticks), the legend, the bars, the lines
and the data labels, vertical and horizontal; the drawing grows for
text that does not fit (decision 19). Its arithmetic is LONGREAL, each
item's places and sizes rounded once to a 1/8192 point: rounded to the
nearest REAL, the y axis's ticks at 10000 and 10500 came out a digit
apart on i386. `PmXyPic` draws it in pic (turned texts with the new
`PmPic.Along`), SVG coming from that through groff (`PmSvg`'s
`WriteXyDocument`); `PmXyMp` writes the MetaPost. The colours are the
default theme's, changed by the `xyChart` themeVariables and
`plotColorPalette` (`PmStyle.XyColours`). `make test` passes under
`-O2` and `-OC`: 392 case tests, with `xy-basic`, `xy-horizontal`,
`xy-labels`, `xy-outside`, `xy-points` and `xy-theme` (dump, layout,
pic, mp; svg-ms for three) and three error cases (`xy-data`,
`xy-noplot`, `xy-statement`). The cases and Mermaid's eight XY chart
examples (`docs/syntax/xyChart.md`) were drawn through groff, through
ConTeXt and as SVG, and looked at. `make test` passes, 392 of 392
under both models, on FreeBSD (alerik, rackhir), NetBSD (artos,
yishana) and OpenBSD (jherek, cymoril).

Phase 23, radar charts, is done, 2026-11-23, on Mermaid 12.3.0.
`PmRadar` reads `radar-beta` (and `radar-beta:`): `title`,
`accTitle`/`accDescr`, `axis` with names and labels, `curve` with
plain values or values by axis, the options `showLegend`, `ticks`
(at most 32, with Mermaid's warning), `max`, `min` and `graticule`,
and `config.radar`, with Mermaid's lexer's names and numbers and its
errors for curves by axis. `PmRadarLayout` lays it out on the
renderer's pixels at the labels' size: the graticule's rings
(circles or polygons), the axes and their labels, the curves (closed
Catmull-Rom Béziers with `curveTension`, or polygons), the legend and
the title; the drawing grows for text that does not fit (decision
19). Its arithmetic is LONGREAL, each item's places rounded once to a
1/8192 point, as `PmXyLayout`'s. The fills are blended over white
(decision 22); an opacity of 0 is no fill, as Mermaid's third radar
example needs. `PmRadarPic` draws it in pic, each curve taken at 16
points a Bézier, SVG coming from that through groff (`PmSvg`'s
`WriteRadarDocument`); `PmRadarMp` writes the MetaPost, the curves
as MetaPost's Béziers. The colours are `cScale0` to `cScale11` and
the `radar` themeVariables (`PmStyle.RadarColours`), which Mermaid
merges over the theme's, so 0 is kept. `make test` passes under `-O2`
and `-OC`: 423 case tests, with `radar-basic`, `radar-polygon` and
`radar-config` (Mermaid's three examples, `docs/syntax/radar.md`),
`radar-byaxis`, `radar-legend`, `radar-theme` and `radar-ticks`
(dump, layout, and pic and mp for most, svg-ms for two) and four
error cases (`radar-noaxes`, `radar-missing`, `radar-badnumber`,
`radar-keyword`). The cases and Mermaid's examples were drawn as SVG
through groff, and Mermaid's examples through ConTeXt, and looked at.
`make test` passes, 423 of 423 under both models, on FreeBSD
(alerik, rackhir), NetBSD (artos, yishana) and OpenBSD (jherek,
cymoril).

Phase 24, sankey diagrams, is done, 2026-11-23, on Mermaid 12.3.0
and d3-sankey 0.12.3. `PmSankey` reads `sankey-beta` and `sankey`:
CSV records of a source, a target and a value (quoted fields with
commas, line ends and `""`, blanks around fields, blank lines, `%%`
comments), values as `parseFloat` reads them, nodes in order of first
appearance, and `config.sankey` (`width`, `height`, `nodeWidth`,
`nodePadding`, `nodeAlignment`, `showValues`, `prefix`, `suffix`,
`labelStyle`, `nodeColors`, `linkColor`); a value that is not a
number or is negative, a missing field or quotation mark, and links
that make a cycle are errors. `PmSankeyLayout` is d3-sankey's layout,
ported: depths and heights, layers by the alignment, the breadths
relaxed 6 times with collisions resolved, the links' breadths, in
d3's orders (stable sorts); then Mermaid's labels, legacy and
outlined, and colours (Tableau10 by node, `nodeColors`; links by
gradient, source, target or a colour). Its arithmetic is LONGREAL,
each item's places rounded once to a 1/8192 point. The links are
blended over white, a gradient drawn as 32 slices, and drawn under the
nodes and labels (decision 23). `PmSankeyPic` draws it in pic, SVG
coming from that through groff (`PmSvg`'s `WriteSankeyDocument`);
`PmSankeyMp` writes the MetaPost. `PmStyle`'s colour table grew from
256 to 4096 colours, for the gradients' slices: Mermaid's energy
example needs about 2,000. `make test` passes under `-O2` and `-OC`:
520 case tests, with Mermaid's eight sankey examples
(`docs/syntax/sankey.md`: `sankey-energy`, `sankey-basic`,
`sankey-blank-lines`, `sankey-commas`, `sankey-quotes`,
`sankey-outlined`, `sankey-node-size`, `sankey-node-colors`), each
alignment (`sankey-align-*`), `sankey-prefix`, `sankey-target`,
`sankey-fixed`, `sankey-fixed-bad`, `sankey-outlined-small`,
`sankey-csv` and `sankey-zero` (dump and layout; pic, mp and svg-ms
but for the energy example's and `sankey-zero`'s, which are large or
have pic only), and seven error cases (`sankey-cycle`, `sankey-empty`,
`sankey-keyword`, `sankey-nan`, `sankey-negative`, `sankey-quote`,
`sankey-twofields`). The cases were drawn as SVG through groff and
through ConTeXt, and looked at; d3-sankey itself was not run, so the
layout is checked against its source, not its output. On 2026-11-23,
`make test` passes, 520 of 520 under both models, on FreeBSD (alerik,
rackhir), NetBSD (artos, yishana) and OpenBSD (jherek, cymoril).

Phase 25, git graphs, is done, 2026-11-23, on Mermaid 12.3.0.
`PmGit` reads `gitGraph` (with `LR:`, `TB:` or `BT:`): `commit`
(`id:`, `msg:`, `tag:`, `type:`), `branch` (`order:`), `merge`,
`checkout` and `switch`, `cherry-pick` (`id:`, `tag:`, `parent:`),
`title`, `accTitle` and `accDescr`, and `config.gitGraph`
(`showBranches`, `showCommitLabel`, `rotateCommitLabel`,
`parallelCommits`, `mainBranchName`, `mainBranchOrder`,
`titleTopMargin`, `diagramPadding`), with Mermaid's db's rules and
errors; a branch without an order sorts as Mermaid's,
`parseFloat("0." + i)`. Made ids are a hash (decision 24), and a
duplicate id is a warning (decision 28). `PmGitLayout` is Mermaid's
renderer, ported: the branches' places, the commits' (in sequence or
parallel, `setParallelBTPos`), the branch lines and labels, the
arrows, rerouted through a free lane where a commit is in the way,
the bullets (normal, reverse, highlight, merge, cherry-pick), the
commit labels and tags, turned for TB and BT and by
`rotateCommitLabel`, and the title. Its arithmetic is LONGREAL. The
colours are the default theme's, each changed by its themeVariable
(`PmStyle.GitColours`); the commit labels' backgrounds are blended
over white (decision 25), and the arrows' corners are Béziers
(decision 26). `PmGitPic` draws it in pic, SVG coming from that
through groff (`PmSvg`'s `WriteGitDocument`); an unstroked rounded box
is given a hairline outline in its fill colour, as `box rad` with
`thickness 0` comes out of mutool with corners of the default SVG
stroke width, scaled. `PmGitMp` writes the MetaPost. `make test`
passes under `-O2` and `-OC`: 549 case tests, with `git-basic` and
`git-tb` (dump, layout, pic, mp and svg-ms), `git-bt`,
`git-parallel`, `git-unrotated`, `git-hidden`, `git-colours`,
`git-cherry-parent` and `git-duplicate` (dump and layout; most from
Mermaid's `docs/syntax/gitgraph.md`), and five error cases
(`git-bad-branch`, `git-bad-checkout`, `git-bad-cherry`,
`git-bad-merge`, `git-bad-type`). All 35 of Mermaid's git graph
examples were read and laid out; `git-basic` was drawn as SVG,
through groff to PDF and through ConTeXt, and the directions,
`parallelCommits`, `rotateCommitLabel: false` and the colours as SVG,
and looked at. Mermaid itself was not run, so the layout is checked
against its source, not its output. On 2026-11-23, `make test`
passes, 549 of 549 under both models, on FreeBSD (alerik, rackhir),
NetBSD (artos, yishana) and OpenBSD (jherek, cymoril).

On 2026-11-23, after Phase 25, the git graph's drawing items (circles,
boxes, polygons, lines, Bézier paths and text) moved to a shared
module, `PmDraw`, which later diagrams extend (`PmGitLayout`'s layout
is a `PmDraw.Drawing`); `PmGitPic` and `PmGitMp` became `PmDrawPic`
and `PmDrawMp`, and the layout dump `PmDrawDump`. The output is
unchanged: `make test` passes, 549 of 549 under both models, on
Fedora and on the six BSD hosts.

2026-11-23, Phase 26: mindmaps. `PmMindmap` reads `mindmap`
(`PmMindmapDump` writes its model for `-t dump`), `PmMindmapLayout`
lays it out as a two-sided tree in a `PmDraw.Drawing`, and
`PmDrawPic`, `PmSvg` (`WriteDrawing`, now for any drawing) and
`PmDrawMp` draw it. `make test` passes under `-O2` and `-OC`: 569 case
tests, with `mindmap-basic`, `mindmap-shapes` and `mindmap-depth`
(dump, layout, pic, mp and svg-ms), `mindmap-comments` (dump), and
four error cases (`mindmap-two-roots`, `mindmap-icon-first`,
`mindmap-text-after`, `mindmap-unterminated`). All 15 of Mermaid's
mindmap examples (`docs/syntax/mindmap.md`) were read and laid out;
the three drawn cases were drawn as SVG, through groff to PDF and
through ConTeXt, and looked at. Mermaid itself was not run.
On 2026-11-23, `make test` passes, 569 of 569 under both models, on
FreeBSD (alerik, rackhir), NetBSD (artos, yishana) and OpenBSD
(jherek, cymoril).

2026-11-23, Phase 27: treemaps. `PmTreemap` reads `treemap-beta` and
`treemap` (`PmTreemapDump` writes its model for `-t dump`),
`PmTreemapLayout` lays it out with d3's squarified treemap in a
`PmDraw.Drawing`, `PmFormat` formats the values as d3-format does, and
`PmDrawPic`, `PmSvg` and `PmDrawMp` draw it; `PmDraw.AddFittedText`
keeps a treemap's labels in their boxes in ConTeXt (decision 43).
`make test` passes under `-O2` and `-OC`: 596 case tests, with
`treemap-basic`, `treemap-plain`, `treemap-classes` and
`treemap-formats` (dump, layout, pic, mp and svg-ms), `treemap-leaf`
and `treemap-empty` (dump and layout) and three error cases
(`treemap-bad-value`, `treemap-blank-class`, `treemap-huge`), and
`PmFormatTest`. The layout of `treemap-basic` was checked against an
independent re-implementation of d3's squarify: every box matched. All
16 of Mermaid's treemap examples (`docs/syntax/treemap.md`) were read
and drawn as SVG and looked at; the cases were drawn through groff and
ConTeXt (at 12 and 8 points) and looked at. Mermaid itself was not
run.
On 2026-11-23, `make test` passes, 596 of 596 under both models, on
FreeBSD (alerik, rackhir), NetBSD (artos, yishana) and OpenBSD
(jherek, cymoril).

2026-11-23, Phase 28: block diagrams. `PmBlock` reads `block-beta`
and `block` (`PmBlockDump` writes its model for `-t dump`),
`PmBlockLayout` lays it out as Mermaid does in a `PmDraw.Drawing`,
and `PmDrawPic`, `PmSvg` and `PmDrawMp` draw it. `make test` passes
under `-O2` and `-OC`: 656 case tests, with `block-basic`,
`block-columns`, `block-composite`, `block-shapes`, `block-arrows`,
`block-space`, `block-edges`, `block-styles` and
`block-style-semicolon` (dump, layout, pic, mp and svg-ms), two
warning cases (`block-redefined`, `block-class-blank`) and five error
cases (`block-chain`, `block-header-link`, `block-style-unknown`,
`block-width-zero`, `block-columns-zero`). All 60 of Mermaid's block
examples (`docs/syntax/block.md`) were read and drawn as SVG and
looked at; the cases were drawn through groff and ConTeXt and looked
at. Mermaid itself was not run. pic now writes a no-break space as
`\ `, as groff has no `u00A0`.
On 2026-11-23, `make test` passes, 656 of 656 under both models, on
FreeBSD (alerik, rackhir), NetBSD (artos, yishana) and OpenBSD
(jherek, cymoril).

2026-11-23, Phase 29: packet diagrams. `PmPacket` reads
`packet-beta` and `packet` (`PmPacketDump` writes its model for `-t
dump`), and `PmPacketLayout` draws it as Mermaid does in a
`PmDraw.Drawing`. `make test` passes under `-O2` and `-OC`: 704 case
tests, with `packet-tcp`, `packet-udp`, `packet-descending`,
`packet-split`, `packet-nobits`, `packet-theme`, `packet-syntax` and
`packet-empty-title` (dump, layout, pic, mp and svg-ms) and eight
error cases (`packet-gap`, `packet-backwards`, `packet-zero`,
`packet-twofields`, `packet-fraction`, `packet-noquotes`,
`packet-leading-zero`, `packet-large`). Mermaid's four packet
examples (`docs/syntax/packet.md`) were read and drawn as SVG and
looked at, and the dumps of its spec's split fields match its
snapshots. Mermaid itself was not run.

On 2026-11-23, `make test` passes, 704 of 704 under both models, on
FreeBSD (alerik, rackhir), NetBSD (artos, yishana) and OpenBSD
(jherek, cymoril).

2026-11-23, Phase 30: kanban boards. `PmKanban` reads `kanban`
(`PmKanbanDump` writes its model for `-t dump`), and
`PmKanbanLayout` draws it as Mermaid does in a `PmDraw.Drawing`.
`make test` passes under `-O2` and `-OC`: 745 case tests, with
`kanban-basic`, `kanban-full` (Mermaid's documentation example, with
the ticketBaseUrl warning), `kanban-meta`, `kanban-shapes`,
`kanban-many` (12 sections), `kanban-theme` and `kanban-empty` (dump,
layout, pic, mp and svg-ms) and six error cases (`kanban-err-caret`,
`kanban-err-icon`, `kanban-err-label`, `kanban-err-nosection`,
`kanban-err-shape`, `kanban-err-word`). The boards were drawn as SVG
and looked at. Mermaid itself was not run.
On 2026-11-23, `make test` passes, 745 of 745 under both models,
on FreeBSD (alerik, rackhir), NetBSD (artos, yishana) and OpenBSD
(jherek, cymoril).
