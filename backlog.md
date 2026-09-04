# Backlog

This file holds the open decisions and the deferred work for the Tufte-Dracula template.
Each entry states the problem, the concrete change, and what makes it a judgment call
rather than a bug. The bugs get fixed. These wait for a call.

This file is not a contract artifact. Consumers inline `tufte-dracula.css` and
`mermaid.js`, and nothing reads this file.

A closed entry leaves this file. It does not collect here. Its measurements and its
rejected alternatives go to [NOTES.md](NOTES.md), which is the file a future agent reads.
The narrative goes in the commit.

---

## No gate asks whether an inlined script binds

**The problem.** `samples/dark.html` shipped an inert `input.filter-box` from v1.16.0 to v1.21.0.
The handler walked forward for a `TABLE` that the fixture never had, and returned. Six
releases passed. The contract check counts `<script>` blocks and compares bytes, and neither
question is "does this handler attach to anything". The same blind spot covers `mermaid.js`:
CI proves its hex matches the palette and never proves it initialises.

**The change.** A CI-only step that loads each fixture in a DOM, runs the two inlined
scripts, and asserts observable behaviour. A working check already exists and is what
verified the v1.22.0 filter widening: six assertions over the real `samples/dark.html`, covering
in-scope filtering, out-of-scope items staying put, group reveal, the empty line, the status
count, and open-state restore.

**Why it is a judgment call.** It needs Node and jsdom. Those are CI-only and no consumer
would inline them, so **No build step** survives in letter. It still grows the release
promise: a tag would then assert that the scripts behave, not only that the payload is
well-formed, and `REQUIRED_CHECKS` would gain a name that can hold a release. The declines
in this file have all been about refusing to make the sheet claim more than it can hold, and
this is the same shape of decision pointed at CI.

**Take it when** a third payload script appears, or when a second binding defect ships.
One defect found by hand is not yet a pattern.

---

## Closed in v1.21.0

v1.21.0 closed six entries. It took four and declined two. Every measurement
moved to [The backlog this closed](NOTES.md#the-backlog-this-closed) in NOTES.md.

| entry | outcome |
| --- | --- |
| Wide tables: inert sticky header, no keyboard reach | Taken. An opt-in `.table-scroll` wrapper. `overflow-x` stays on `table`. |
| Nine class families with no user in the largest consumer | Kept. The zero measures the generator, not the stylesheet. `README.md` now names `sidenote`. |
| Non-GFM callout conventions unclaimed | Declined. Three more names for a role the sheet already paints twice, with no consumer. |
| Form controls at 13.33px Arial | Taken. `font: inherit` plus a 1rem floor. The UA still owns the appearance. |
| Pygments uncovered | Taken. Added to the seven grouped selectors, scoped under `:is(pre, code)`. |
| Jupyter ANSI output monochrome | Declined. Sixteen ANSI names onto seven accents is invention, with no consumer. |

Both declines carry a condition to revisit, not a verdict. Take the callout conventions
when a consumer runs Sphinx, MkDocs or Quarto. Take the ANSI map when a notebook export
appears in a lode.

The same probe found four smaller defects. v1.21.0 took two of them. `menu` now indents
like the other list types. `ins` and `u` now take a dotted underline, so they no longer
read as links.

Two stay recorded, and they are not entries. `address` keeps its UA italic, which is
arguably correct for a postal block. `.tabbed-set` shows every panel at once, and a fix
means the sheet claims a radio-driven widget.

## Open after v1.25.0

**A light twin for the `classdef` fills.** v1.25.0 gave `--data-1..4` light and print values and
moved `initLight.pie1..4` onto them, so a pie chart now clears 3.2:1 against the light card. The
`classdef` section in `mermaid-palette.json` did not move: it holds one set, projected from the dark
ramp, and `.github/palette-check.py` check 2 resolves it against the dark palette only. A generator
that writes its own `classDef name fill:...` lines still paints dark-ground fills on a light page,
at the 1.69 to 2.15:1 the token work just fixed everywhere else.

Take it when a consumer emits `classDef` lines on a page that can render light. The cost is not the
hex: it is that a fence has no CSS to read, so the generator has to decide which set to emit, and
that decision needs a rule this repo does not have yet. `NOTES.md` under *Form follows role* records
the measurement and the reasoning.

**Pie slice opacity and the dark-mode slice label.** Two coupled defects, both found by rendering a
`pie` fence rather than by reading tokens, and both older than v1.25.0.

Mermaid sets `.pieCircle { opacity: 0.7 }`, so a slice composites to 2.15 to 2.22:1 against the
light card even after the v1.25.0 ramp cleared 3.2:1 flat. Separately, a dark-mode slice label is
`textColor` at `#f8f8f2`, drawn on a pale fill, measuring 1.81:1 flat and 2.86 to 3.47:1
composited. The fills are pale in dark mode and dark in light mode, which is the inverse of what
Mermaid's single `textColor` assumes, so one value cannot serve both.

Forcing `opacity: 1` fixes the first and makes the second worse, so they move together or not at
all. The shape of a real fix is `pieSectionTextColor` per palette, dark text in the dark scheme
where fills are pale and light text in the light scheme where fills are not, plus a decision about
whether a seventh `!important` against Mermaid's stylesheet is worth the boundary. No fixture has a
pie chart, which is why this went unmeasured for so long; take this together with adding one.

**The mermaid `pre` region announces its diagram's name twice.** `mermaid.js` sets
`role="region"` plus an `aria-label` from the SVG's own `<title>`, and the SVG then exposes that
same string as its `graphics-document` name. A screen reader therefore reads the diagram title, the
word "region", and the diagram title again on entry. Verified from the accessibility attributes on
`samples/dark.html`: `pre` label and `svg > title` are byte-identical by construction.

A fix is either a second, distinct string for the region (which `mermaid.js` cannot invent, and
which consumers cannot translate in a file they inline verbatim) or dropping the region role and
leaving a focusable generic, which the *Keyboard and assistive technology* section already rejects
for the button case. Take it if someone reports the duplication from a real screen reader, since
neither option is clearly better than the noise.

**`pre.mermaid` is a focusable region at widths where it cannot scroll.** The tab stop exists for
the narrow-viewport `overflow-x: auto` case, and `mermaid.js` sets it unconditionally, so above
600px each diagram is a tab stop with nothing to scroll and no action. Measured: all four fixture
diagrams report `scrollWidth == clientWidth` at 1440px. The *Connections-map layout* section
rejects exactly this shape for the sticky Links column.

Making it conditional needs either a resize listener or a `matchMedia`, and check 6 of
`palette-check.py` fails on any `matchMedia` in `mermaid.js` for good reasons of its own. A
resize-stale *missing* tab stop is a 2.1.1 failure, where a resize-stale redundant one costs a
keystroke, so the unconditional version is the safe default and this stays open rather than fixed.

**Two `CONTRACT.md` § 2 requirements cannot be gated, at all.** Both arrived with the v1.39.0 work.
`--icon-color` on a `.step-node` reaches the sheet through an inline `style` attribute, and a
`quadrantChart` point label lives inside a `pre.mermaid` fence as diagram source. No CSS rule and no
palette check can see either one, so both are prose obligations of the kind this repo distrusts.
Check 9 gates the permitted `.step-node` token set inside the stylesheet, which catches an editor
here but never a consumer.

A fixture-level scan in `scripts/maintain.nu` would catch the repo's own regressions, and that is
worth doing if either requirement is ever violated in `samples/`. It would not help a consumer,
which is the case that matters, so the honest answer may be that some obligations stay prose.

**Every `samples/dark.html` line reference in `CONTRACT.md` § 2 is wrong.** All 22 of them, and
they were already wrong at v1.38.1, so this predates the work that found it. The cited range is
637 to 927 against a 1007-line fixture, and spot checks land on unrelated markup every time: the
reference for `<main>` points into `mermaid.js`'s tail, the one for `role="list"` on `.icon-list`
points at a wide-table row, the one for the rollup `.verdict` points at the task list.

This matters more than an ordinary stale link, because § 2 tells a consumer's generator that
"most link the line in `samples/dark.html` that models it, so you have a working example instead
of only a sentence". A wrong pointer is worse than no pointer: it sends a reader to markup that
does not demonstrate the requirement and looks authoritative doing it.

Two ways to fix it, and the choice is the real work. Renumber all 22 and add a gate that fails
when a cited line stops containing an expected token, which keeps the format but needs a
machine-readable token per requirement. Or stop citing line numbers into a generated file
altogether and cite a stable anchor instead, which is more honest about what a generated fixture
can promise, and costs a rewrite of every reference plus whatever a reader loses in precision.

Do not renumber without also adding the gate. Line numbers into a generated file rot on the next
regeneration, which is exactly how all 22 got here with every check green.
