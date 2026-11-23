# AGENTS.md

Notes for agents (and people) working in this repository.

## What this is

pomermaid is a command line program, written in Oberon-2 and built
with the Peaseblossom Oberon Compiler (`poc`), that turns Mermaid
diagrams into drawing languages that typesetters understand:

- **pic**, for groff (`ms`, `mom`), run through `groff -p`;
- **MetaPost**, in ConTeXt's MetaFun form (`\startMPcode` ...
  `\stopMPcode`), which ConTeXt LMTX runs itself; the labels are set
  and measured by ConTeXt, and the final positions computed in
  MetaPost (`pomermaid.mp`);
- **SVG**, for HTML, made from the pic drawing by groff (a PDF the
  drawing's size) and MuPDF's `mutool`.

All of Mermaid's diagram types are in scope, flowcharts first. One
diagram per run; podoc will run pomermaid as a program.

The Mermaid tools (`mmdc`, the pandoc filters) lay diagrams out and
draw them in a headless web browser. pomermaid needs no browser, no
Node.js and no network: it parses the Mermaid source, lays the diagram
out itself, and writes the drawing. Like podoc
(`~/Repos/Oberon/podoc`), it should build wherever poc does, on Linux
and the BSDs. Diagrams drawn this way use the document's own fonts.

The plan, phase by phase, is `PLAN.md`; each phase's state is recorded
there. Its "Open questions" are the user's to decide. Do not settle
one silently: ask, then record the decision, dated, under
"Decisions".

## Status

As of 2026-11-22: Phases 1 (the skeleton), 2 (the flowchart
reader, `PmLex`, `PmFlow`, `PmDump`), 3 (text metrics from groff's
font files, `PmMetrics`), 4 (layout: `PmGeom`, `PmLayout`,
`PmFlowLayout`, written by `-t layout`), 5 (the pic writer,
`PmPic`, `-t pic`; `make render`), 6 (the MetaPost writer,
`PmMp`, `-t mp`, with the macros `mp/pomermaid.mp`, made into
`PmMpMacros` by `tools/mp2mod`; styles shared in `PmStyle`), 7
(subgraphs: clusters in `PmLayout` and `pomermaid.mp`, boxes in both
writers), 8 (SVG through groff and mutool or pdftocairo: `PmSvg`,
`PmRun`, `-t svg` and `-t svg-ms`) and 9 (the user documentation,
`docs/user/pomermaid.md`, `docs/user/differences.md` and the man page
`docs/user/pomermaid.1`, and the
pandoc filter `docs/examples/pomermaid.lua`) and 10 (the rest of
Mermaid's flowchart syntax: `@{ ... }` metadata, the named shapes in
`PmShapes`, curves in `PmCurves`, `themeVariables` and the title,
bold and italic in `PmEmphasis`, links in the SVG, collapsed
subgraphs, and isolated subgraphs laid out alone with their own
`direction`) and 11 (the BSDs: FreeBSD, NetBSD and OpenBSD, on
x86-64, i386 and arm64) and 12 (state diagrams, `PmState`, read
into `PmFlow`'s model and drawn by the same layout and writers) and
13 (class diagrams, `PmClass`: class boxes, relations with UML
markers and cardinalities, notes and namespaces) and 14 (entity
relationship diagrams, `PmEr`: entities with attribute tables,
crow's-foot ends, subgraphs) and 15 (requirement diagrams, `PmReq`:
requirement and element boxes, contains and arrow ends) and 16
(sequence diagrams: `PmSeq`, `PmSeqLayout`, `PmSeqPic`, and
`PmSeqMp` with its own macros, `mp/pomermaid-seq.mp`) and 17 (user
journeys: `PmJourney`, `PmJourneyLayout`, `PmJourneyPic`, and
`PmJourneyMp`, which writes the MetaPost directly, without macros) and
18 (timelines: `PmTimeline`, `PmTimelineLayout`, `PmTimelinePic` and
`PmTimelineMp`, left to right and top down) and 19 (Gantt charts:
`PmGantt`, with its dates in `PmGanttTime` and its axis in
`PmGanttScale`, `PmGanttLayout`, `PmGanttPic` and `PmGanttMp`) and
20 (pie charts: `PmPie`, `PmPieLayout`, `PmPiePic` and `PmPieMp`) and
21 (quadrant charts: `PmQuadrant`, `PmQuadrantLayout`,
`PmQuadrantPic`, with `PmPic.Rotated` for turned text, and
`PmQuadrantMp`) and 22 (XY charts: `PmXy`, `PmXyLayout`,
`PmXyPic`, with `PmPic.Along`, and `PmXyMp`) and 23 (radar charts:
`PmRadar`, `PmRadarLayout`, `PmRadarPic` and `PmRadarMp`) and 24
(sankey diagrams: `PmSankey`, `PmSankeyLayout`, d3-sankey's layout,
`PmSankeyPic` and `PmSankeyMp`) and 25 (git graphs: `PmGit`,
`PmGitLayout`, Mermaid's renderer, drawn by the shared `PmDraw`,
`PmDrawPic`, `PmDrawMp` and `PmDrawDump`) and 26 (mindmaps:
`PmMindmap`, `PmMindmapLayout`, a two-sided tree, and
`PmMindmapDump`) and 27 (treemaps: `PmTreemap`, `PmTreemapLayout`,
d3's squarified treemap, `PmTreemapDump`, and `PmFormat`, d3-format's
number formats) and 28 (block diagrams: `PmBlock`, `PmBlockLayout`,
Mermaid's layout and shapes, and `PmBlockDump`) and 29 (packet
diagrams: `PmPacket`, `PmPacketLayout` and `PmPacketDump`) and 30
(kanban boards: `PmKanban`, `PmKanbanLayout` and `PmKanbanDump`) are
done. See
PLAN.md's State.

## Reference material

| What | Where |
|---|---|
| Mermaid's syntax | <https://mermaid.js.org/syntax/flowchart.html> and its siblings; Mermaid's grammars are jison files in `packages/mermaid/src/diagrams/*/parser/` of its repository |
| dagre, the layered layout Mermaid uses for flowcharts | <https://github.com/dagrejs/dagre>; its steps follow Gansner et al., "A Technique for Drawing Directed Graphs" (1993), and Brandes and Köpf, "Fast and Simple Horizontal Coordinate Assignment" (2001) |
| pic | groff's `pic(1)`, and Kernighan's "PIC — A Graphics Language for Typesetting" (CSTR 116); GNU extensions: `shaded`, `outlined`, `thickness`, `\m[...]` colour |
| MetaPost and MetaFun | Hobby's MetaPost manual (`mpman`), Hagen's MetaFun manual (`metafun-p.pdf` in the ConTeXt distribution); `textext` for labels in the document's fonts |
| groff font metrics, for text widths | `/usr/share/groff/current/font/devpdf/` (`DESC`: `unitwidth`; each font file: `charset` lines of name, width, ...); `groff_font(5)` |
| Diagrams in the user's documents | `~/Repos/RPG/Galactic-Bounty-Hunters/galactic_bounty_hunters_one_shot.md` (two flowcharts: subgraphs, `classDef`, `<-->`, `<br>`), `~/Repos/RPG/Tools/aftermath-generator/aftermath_generator_spec.md` (a flowchart with edge labels, a `{}` diamond and cycles) |
| A hand-drawn pic version of the Galactic-Bounty-Hunters diagrams | `docs/examples/gbh-handdrawn.ms`, made on 2026-11-22; `groff -k -ms -p -Tpdf` renders it; the target look for Phase 5 |
| podoc, the sister project: conventions, build, tests | `~/Repos/Oberon/podoc` (its `AGENTS.md`, `GNUmakefile`, `tools/runcases`) |

The user's projects are read only: never change them. Read the
specific files you need; do not list private directories wholesale.

## The compiler

- **Use the installed `poc`**, `/usr/bin/poc`. Its libraries are in
  `/usr/lib/poc`, and libraries installed by the user in
  `~/.local/lib/poc/<triple>/{O2,OC}`. Check what the compiler
  accepts by running it, not by reading its source.
- **`~/Repos/Oberon/Peaseblossom` is reference only.** Read its
  `doc/users-guide.md`, `doc/developer/language-extensions.md` and
  `AGENTS.md` for conventions, but never modify, build or commit
  anything there. A poc bug found here is reported to the user; do not
  work around it silently.
- **Size models:** under `-O2`, the default, `INTEGER` and `LONGINT`
  are 16 and 32 bits; under `-OC` they are 32 and 64. Every module
  must compile and pass its tests under both.
- **Functions cannot return records or arrays** in poc; they come back
  through a `VAR` parameter.
- **No C** unless the user agrees to it.
- **Module names** must not collide with poc's runtime modules or
  other libraries: Oberon has one global module namespace.
  pomermaid's modules are prefixed `Pm`.

## Libraries

| Library | Use |
|---|---|
| ArgParser | the command line |
| pounicode (`Utf8`, ...) | labels are UTF-8; widths are per code point |
| Ropes | output, if it helps (podoc uses it for all output) |
| poDateTime (`Calendar`, `Instants`, `TimeZones`) | Gantt dates and local time (Phase 19) |

They are installed under both models in `~/.local/lib/poc`; a missing
one is installed from its checkout under `~/Repos/Oberon`, as podoc's
AGENTS.md describes.

## Building and testing

- `make` builds `pomermaid` under `-O2` and `-OC` in `build/O2` and
  `build/OC`.
- `make test` runs the unit tests (`test/<Name>Test.Mod`, printing
  `ok   - ` and `FAIL - ` lines, compared with `<Name>Test.expected`)
  and the case tests (`test/cases/<name>.mmd`, with optional
  `<name>.args`, and `<name>.<ext>.args` for one format, against the expected `<name>.dump`, `<name>.layout`,
  `<name>.pic`, `<name>.mp` and, for SVG, the groff document
  `<name>.svg.ms` beside it), under both models. It
  must not need groff, ConTeXt or Mermaid's tools: the tests' fonts
  are made up, `test/fonts/devpdf/TT` and `TS`.
- `make check-groff` (where groff is installed) compares the widths
  `PmMetrics` gives with groff's `\w`, through `tools/checkwidths`.
- `make render` (where groff is installed) draws each case that has a
  layout with `-t pic` in groff's Times, one to a page, in
  `build/render/cases.pdf` (`tools/render`), for looking at; where
  ConTeXt is installed, with `-t mp` too, at 12 and 8 points, in
  `build/render/cases-context.pdf`. Run it under a `systemd-run`
  memory cap.
- `mp/pomermaid.mp` is the only source of the MetaPost macros: edit
  it, and `make` regenerates `src/PmMpMacros.Mod` (kept in the
  repository). Test the macros in ConTeXt LMTX; a declared MetaPost
  variable must not end in a digit, `and` and `or` do not short-cut,
  and a statement that begins with `begingroup` needs its `;`.

## Exit statuses

Errors the user can cause end pomermaid through `PmIO.Fail`, with
podoc's status for the same kind of error: 1 input or output, 6 option
error, 22 unknown output format, 43 a program (groff, mutool) failed,
47 a program not found, 64 the diagram cannot be read, 97 no such
font. ArgParser ends
with 2 on a bad option.

## Conventions

- **Claim only what has been verified.** Say in PLAN.md's State what
  was run and what passed, with the date. A diagram is checked by
  looking at the PDF, not only by its source.
- **Commit only when asked.**
- **Temporary files** go under `/usr/local/sw/tmp`, in a directory per
  session, never `/tmp` (a RAM disk on this machine). Delete it when
  done.
- **Portable:** Linux and the BSDs. GNU make is the build tool; shell
  scripts are POSIX `sh`.
- **Mermaid's syntax, not its pixels:** accept what Mermaid accepts,
  and draw a clear diagram; lay out freely where that is clearer than
  Mermaid's drawing (PLAN.md, decision 2).
- **Scope:** add a feature when the user's diagrams need it or the
  plan schedules it. Everything else goes to PLAN.md's "Later".
- **Style:** as the other Oberon projects under `~/Repos/Oberon`: one
  module per file, `src/<Module>.Mod`, exported procedures commented.
