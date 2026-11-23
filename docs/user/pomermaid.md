# pomermaid

pomermaid reads a [Mermaid](https://mermaid.js.org/) diagram and draws
it in one of three forms:

- in **pic**, for groff's ms and mom documents;
- in **MetaPost**, for ConTeXt;
- as **SVG**, for HTML, made by groff from the pic drawing.

It needs no browser and no JavaScript. The labels are set in the
document's own fonts: groff's font files measure them for pic and SVG,
and ConTeXt measures them itself for MetaPost.

It reads flowcharts (`flowchart` and `graph`) and state diagrams
(`stateDiagram-v2` and `stateDiagram`). Mermaid's other diagram types
are planned, one after another.

## What it needs

To build it:

- the Peaseblossom Oberon Compiler, `poc`;
- the poc libraries ArgParser and pounicode, installed under both size
  models;
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
- the MetaPost macros, as `$(PREFIX)/share/pomermaid/pomermaid.mp`;
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
| `--mp-macros inline\|input` | For `mp`: copy the macros into each drawing (`inline`, the default) or write `input pomermaid ;` (`input`). |
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
does not draw. Mermaid's other diagram types are not read yet.

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
where ConTeXt finds it, such as beside the document.

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
