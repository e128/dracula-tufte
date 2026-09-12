# NOTES.md: the decisions behind the stylesheet

Every generated HTML file carries `tufte-dracula.css`, `mermaid.js` and `filter.js` verbatim. Those
files therefore carry no comments. See `AGENTS.md`. This file holds what those comments would say.

**This file states decisions and prohibitions. It does not carry the measurements behind them.**
Chromium measured every number. Those measurements live in git history and in the gates.
`.github/palette-check.py` and `.github/render-modes.py` enforce the color and mode claims. A number
that matters is therefore a check rather than a paragraph. When a decision here disagrees with a
gate, the gate is right.

**Do not re-litigate an entry here without a new measurement.** Several changes in this repo were
correct on paper, shipped, and then went back out. Every "do not" below is one of those.

Two comments remain in the CSS. A machine reads both.

- **Line 2, the version** (`/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`).
  `scripts/build-sample.nu` reads it to stamp `tokens.css`. `scripts/maintain.nu bump` rewrites it.
  Strip that line and regeneration dies. The failure is silent through a pipe, and it leaves stale
  fixtures that look correct.
- **The `/* was #rrggbb */` notes on ten `:root` tokens.** Check 3 of `.github/palette-check.py`
  fails when a stated hex disagrees with its `oklch()`.

## Contents

| Section | Covers |
| --- | --- |
| [Fonts](#fonts) | Source Serif 4, the weight axis, the fallback path |
| [Type scale](#type-scale) | The one clamp, em steps, compounding traps |
| [Italics](#italics) | Which eight rules slant, and why h3 does not |
| [Width and measure](#width-and-measure) | `--page-width`, the long measure, the caps that failed |
| [Paragraphs and section rhythm](#paragraphs-and-section-rhythm) | Section gaps, `.indented`, `--space-*` |
| [Lists](#lists) | Markers, list semantics, `dl.timeline` |
| [Tables](#tables) | `table.tree`, widths, no zebra, `.num`, sticky `th`, `.table-scroll` |
| [Links](#links) | Underline floor, the outbound arrow's alt text |
| [Color and the contrast budget](#color-and-the-contrast-budget) | Grounds, floors, the data ramp, gamut, forced colors |
| [Form follows role](#form-follows-role) | Filled and outlined chips, bars and boxes, the hue budget |
| [Borrowed components](#borrowed-components) | `.kicker`, `.tag-dot`, `.live-dot`, `.icon-list`, `.step-chain`/`.step-hop`, `blockquote.pull` |
| [CSS charts](#css-charts) | `table.bar-chart`, the alpha under the number, why the CSS pie went out, print and forced colors |
| [Progressive disclosure](#progressive-disclosure) | `nav.toc`, `details.deep`, the narrow and print column overrides |
| [Editor themes](#editor-themes) | Why the Rider slot map differs from the prose one |
| [Mermaid](#mermaid) | Init config, label measurement, sizing, zoom, diagram types |
| [Connections-map layout](#connections-map-layout) | `body.conn-map`, markup order, no breakouts |
| [Interaction states](#interaction-states) | Press, hover, focus rings |
| [Keyboard and assistive technology](#keyboard-and-assistive-technology) | Zoom button, modal overlay, `inert`, scroll regions |
| [Direction, zoom and growth](#direction-zoom-and-growth) | RTL, text-only zoom, safe-area insets |
| [Cascade layer](#cascade-layer) | `@layer tufte-dracula`, the `!important` inversion |
| [Appearance modes](#appearance-modes) | High contrast, light, `--mermaid-scheme`, the mode gates |
| [Print](#print) | Token reassignment, page breaks, chip outlining |
| [Filter](#filter) | `filter.js` scope and its load-bearing decisions |
| [Unclaimed elements](#unclaimed-elements) | `mark`, `kbd`, `caption`, `figure`, `figcaption` |
| [Markdown coverage](#markdown-coverage) | What a converter emits, and how the sheet claims it |
| [Raw HTML and other generators](#raw-html-and-other-generators) | Intrinsic-width media, unbreakable tokens, permalinks |
| [Fixtures are coverage](#fixtures-are-coverage) | Which fixture details catch a regression, why a pointer is a search string, and the one check that runs the payload |
| [Repo layout](#repo-layout) | Why `scripts/` holds the Nushell, `.github/` keeps the Python, and `AGENTS.md` holds the rules |
| [Odds and ends](#odds-and-ends) | `hr`, scrollbars, `--ring`, the validator |

---

## Fonts

**The body face is Source Serif 4.** Variable, pinned to an exact jsDelivr version, roman and italic.

**The webfont exists for the weight axis.** Every system serif ships only 400 and 700. Nothing else
renders the 450 that light-on-dark body copy wants, or the real 600 on `.newthought`, `strong` and `dt`.

**It also won on tabular, lining figures.** A table aligns with no OpenType feature support.
Literata, Newsreader, Lora and Petrona were rejected: Lora carries Georgia's old-style proportional
figures, and none of the five ship `smcp`, so `.newthought` small caps stay synthesized either way.

**The fallback path is a real downgrade, not an equivalence, and the repo accepts it.** Offline the
stack falls to Georgia (no 450, proportional figures, tables lose alignment), then Noto Serif
(Android/ChromeOS), then DejaVu Serif (Linux). Charter and Palatino are deliberately absent: both
exist only where Georgia already does. `font-display: swap` keeps text visible during load.

**The code face is also a webfont, `'JetBrains Mono'` first**, loaded from
`@fontsource-variable/jetbrains-mono`, pinned like the body face, matching the Rider theme's editor
font. Offline it falls to `ui-monospace`. `mermaid.js` repeats the same order in both of its literals,
because the measurement font must stay the render font (see [Mermaid](#mermaid)).

**`blockquote.pull`'s glyph takes `var(--body-font)`, not a hardcoded Georgia**, which exists on
neither Android nor Linux.

**Both font stacks are tokens because three rules need the literal.** `.mermaid-zoom`'s
`font: inherit` would otherwise resolve to `pre.mermaid`'s code face, so it re-sets
`font-family: var(--body-font)` after the shorthand. `pre` sets its own family too, so a code block
with no inner `<code>` still matches its neighbors. `mermaid.js` writes the mono stack out twice as a
JS literal, because neither copy can read a custom property, and each is load-bearing for a
different reason. **That duplication is not drift to fix.**

**No `-webkit-font-smoothing: antialiased`.** That advice is for dark text on light. This theme is
the inverse, and grayscale-only antialiasing thins strokes.

## Type scale

The body `font-size` clamp is the **only size lever**. Every other step is em-relative to it,
headings included. Floor `1rem` (also the iOS input-zoom threshold `.filter-box` inherits), cap
`1.25rem`, every bound `rem` never `px`, so the page scales with a raised browser default.

**Do not lower the floor past `1rem`** without a separate 16px floor on `.filter-box`.

```
1.75em  h1  ┐ headings in em so they track the body clamp, not the fixed root
1.35em  h2  │
1.12em  h3  ┘
1em     body copy, prose li, .filter-box
0.95em  structural: table, aside, nav, .scorecard, .nav-list li
0.9em   annotation: .byline, .sidenote, cite, code, pre, footer
0.8em   chips: .badge, .verdict
0.75em  the outbound arrow
```

**`text-wrap: balance` sits on `h1`, `h2`, `h3` only.** They're short blocks where a stray last-line
word is the defect; `h4`-`h6` render at body size with no wider measure to justify it.

Nested ratios compound. Check the parent before adding a step. Three paid-for traps:

- **Headings are `em`, not `rem`.** Anchored to the root they'd diverge from body copy, which grows
  on a vw clamp, and h3 would render smaller than its own paragraphs.
- **`.verdict`/`.badge` sit at 0.8em, not 0.75em.** They nest inside a 0.95em parent, and 0.75em
  lands under the 12px floor. Re-check both if the body floor moves.
- **`pre code` is `font-size: 1em`** to halt the compounding; `code`/`pre` each carry 0.9em.

**Do not write a `pt` or `px` floor.** An earlier `max(Xem, 12pt)` scale pinned nine elements to one
size, made body copy the smallest text on a phone, and ignored the reader's own setting.

**`h1`/`h2` sit at weight 400. `h3` is 500**, the one heading at text size, since 400 would render
lighter than the paragraph beneath it. **Nothing at text size may go lighter than body copy**: h3-h6,
`summary`, `th`.

**That rule now covers color too: `h5`/`h6` sit at `--label`, not `--muted`.** At body size, weight
is the only other axis marking them as headings; on `--muted` a heading was the dimmest thing in its
own section, the same inversion this file refuses for `dl.timeline > dd`. `--muted` is pinned at the
contrast floor; `--label` moves toward body text, so that's where a heading belongs. **h3/h4 stay at
`--label`, not `--on-surface`**: both are already larger or heavier, so size and weight do the work
color alone has to do at h5.

**`code`/`cite` sit at 0.9em**, x-height-matched against the mono stack.

**`li` carries no `font-size` of its own.** At 0.95em a bulleted list read subordinate to body copy,
and `nav > ul > li` compounded to the smallest text on the page. `.nav-list li` and `nav` ask for
0.95em themselves instead.

## Italics

Eight rules slant: `.byline`, `h2`, `th`, `summary`, `blockquote`, `details.nav-group > summary`,
`.filter-box::placeholder`, `.filter-empty`.

**`h3` is upright and `h2` is italic, deliberately.** Adjacent levels sharing an italic would
distinguish neither, resting the hierarchy on size and color alone; upright h3 gives the pair a
second axis, and italic costs the most legibility at text size on a dark surface anyway.

**`summary` and `th` are both 450, italic near reading size.** At 400 each read lighter than the
copy around it. `th` can't drop its declaration (UA default is bold), so italic plus `--pink` carry
the distinction instead.

## Width and measure

**Page width is one number**, `--page-width: min(90vw, 160rem)` in `:root`, shared by `body` and
`body.conn-map`'s article so the two layouts cannot drift. `90vw` is the proportional dial, `160rem`
(scales with root size) is the ultrawide backstop, `100% - 2 * var(--gutter)` on `body` is the floor
respecting the safe-area insets folded into `--gutter`.

**Do not add a second width convention, a breakpoint override, or a full-bleed breakout.** Three
failed attempts, recorded so nobody retries them: (1) a `70ch` cap plus `min-width: 1200px` override
to `80vw`, stranding copy in a narrow column and snapping width in one step; (2) a `100rem` cap, same
failure one size up; (3) a gutter-and-backstop with no proportional term, full-bleed with fixed
margins at every size. **"Unused space" is not the metric to minimize.**

### NON-NEGOTIABLE: the wide measure stays

**The long measure is closed, not a standing decision.** `AGENTS.md` carries the rule in full.
Content flows nearly the full window, well past the conventional 60-75 characters, and **nothing may
narrow the rendered width of running prose**: no `max-width`, `width`, `inline-size`, `columns`,
narrower `--page-width`, grid track, wrapper, or consumer opt-in.

**A measurement is not an argument here, and that's the whole point.** A fourth attempt (below)
produced good numbers and was rejected on sight anyway. Do not reopen this with fresh numbers, a
`better-*` review finding, a typography rule of thumb, or a WCAG citation. If a review flags the long
measure, record that it was flagged and move on.

This stylesheet serves dense reference pages with tables and diagrams, not book-length prose. Three
facts for anyone who reads on anyway: the cap belongs in `em`, **not `ch`** (a serif's average
advance is far under `0`'s width, so a `ch` cap runs longer than its number claims); it must be
scoped to section children, not a bare `p` (which also hits `.byline` and mermaid's `foreignObject`
paragraphs); and **smaller type makes the measure worse**, because the container is `vw`/`%` driven.

**Attempt 4 capped prose only and is the one worth knowing.** `--measure: 40em` on `p` (with
`dl.timeline > dd` matched), leaving `table`, `pre`, `pre.mermaid`, `.edge-list`, `.recent-groups` at
full width. It measured exactly as intended (about 70 characters per line flat from 1280 to 3440px,
against 103-144 before, no overflow anywhere) and **was rendered, compared side by side, and
rejected on sight regardless.** A capped column beside a wide container still reads as stranded copy.

Two things it did establish: a sidenote floats `width: 28%` *inside* its paragraph, so any future
cap on `p` needs a paired `p:has(:is(.sidenote, .marginnote))` rule at `cap / 0.72` to hold both; and
a `max-width` can only narrow, so it can't reintroduce a sideways scroll.

**Sidenotes stack below 1000px, not 600px**: the 28% float is narrower than any measure worth
reading between 600 and about 1280px.

**`hyphens: auto` is scoped to the two narrowest prose measures**, the sidenote (28%) and `.col-2`
(half a column). Not body copy, not `.nav-list li a` (a hyphen there reads as part of the slug), not
headings. Both fixtures carry `lang="en"`, which hyphenation requires.

**The 1000px and 600px breakpoints stay separate on purpose**: the 600px block is genuinely
phone-sized, and one breakpoint wrong for half its contents beats two with distinct reasons.

## Paragraphs and section rhythm

**`section` spacing matches `h2`'s top margin**, collapsing to one value; unequal values hid a
defect (a section opening with anything but `h2` got the smaller gap) rather than caused one.

**`section > :first-child { margin-top: 0 }` was tried and rejected**: it flattens the gap under the
byline, and in `body.conn-map` the sections are flex items where margins don't collapse at all, so a
rule tuned for the collapsing case misaligns the two columns.

**`.indented` (book setting) is opt-in, not the default**, because the two conventions can't mix on
one page without reading as an accident, and it's not what existing consumer output assumes. It's
two rules: `margin-block: 0` on paragraphs, `text-indent: 1.5em` on every `p + p` (hung off the
sibling combinator since nothing precedes the first paragraph).

**A sidenote marker must not use `vertical-align: super`**, which grows the line box and throws off
every paragraph with a note. `position: relative; top: -0.4em; line-height: 0` lifts the glyph with
no line-box impact instead.

**`.sidenote`/`.marginnote` reset what a surrounding `.newthought` inherits into them** (small caps,
weight 600, tracking, 1.2em size), so a note pins the annotation register regardless of where its
anchor lands. **Do not replace the reset with a markup rule.** A rendering invariant is the
stylesheet's job.

**`--space-*` covers block rhythm only; component padding stays literal**, tuned by measurement
rather than snapped to a scale that would move rendered boxes to satisfy an abstraction. The list
indent stays literal too, pairing with `--tree-step` rather than the vertical scale.

**`text-wrap: pretty` sits on `p`, `.sidenote`/`.marginnote`, `figcaption`/`caption`** to avoid a
stranded last-line word, for blocks too long for `balance`. Firefox falls back to normal wrapping
with no breakage.

## Lists

**A prose `ul` keeps its markers.** A global `list-style: none` reset made bulleted lists read as a
run of short paragraphs and made `li::marker` dead code. `ul`/`ol` share one indent; `ul` keeps the
muted UA marker progression.

**That's also half of a list-semantics problem: WebKit drops list semantics from `list-style: none`.**
`.nav-list`/`.icon-list` reset it on the `<ul>` itself, so both need `role="list"` in markup, a
`CONTRACT.md` consumer obligation.

### `.recent-groups`

**A landing index of several category lists is `auto-fit`, not a fixed column count.**
`repeat(auto-fit, minmax(min(36rem, 100%), 1fr))` sizes to whatever count a generator emits, unlike
`.edge-list`'s fixed two columns (always an antecedent/descendant pair). This is also why it needs no
breakpoint override where `.edge-list` does: below two 36rem tracks, `auto-fit` collapses to one
column on its own.

**A bare `minmax(36rem, 1fr)` only fixed the column count, not the surviving column's own width**:
it still floored at 576px, overflowing the document below that, a real WCAG 1.4.10 failure.
`minmax(min(36rem, 100%), 1fr)` is the standard guard against exactly this `auto-fit` trap.

Item count and the "view all" link are a generator concern, not a stylesheet one. An uncategorized
`.recent-group` is styled identically to a named one, one class not two.

**A `.recent-group .nav-list li` is one line, title leading with `.count` trailing on the same
row, never below it.** `a { display: block }` made the date wrap to its own line beneath the title,
outranking it visually. Now `display: flex`: the anchor (`flex: 1 1 auto`, `min-width: 0`, ellipsis
truncation) keeps the title from wrapping and pushing the date off the row; `.count` (`flex: none`,
`--muted`, `0.82em`) never shrinks to make room. **Do not revert to `display: block`, and do not let
the title wrap.**

**`.recent-group` and its `.nav-list` stretch to fill the grid row** (`flex-direction: column` plus
`.nav-list { flex: 1 }`), so a card with fewer items doesn't leave its "view all" link at a different
baseline than its neighbors.

### `dl.timeline`

**A timeline entry is content, not annotation.** `dl.timeline > dd`/`dt` both take `--on-surface`
(not the plain-`dd` caption tier), since the date is the axis a reader scans. An `h3` date line is
the wrong shape too: label-tier weight 500 reads fainter than the event title, and dates never align
into a column.

**`--timeline-date` exists because era groups are separate lists**, and `max-content` sizes each
track against only its own rows, so a multi-list timeline needs `var(--timeline-date, max-content)`
to pin one width in `ch` across lists CSS otherwise cannot see (no shared-parent `subgrid` applies).

**Measure the widest label at weight 500 (what `dt` renders at) and round up.** `tabular-nums` pins
digits to `1ch`; a spelled-out century often beats a numeric range. **A short `--timeline-date` has
no CSS backstop**: `minmax(var(--timeline-date), max-content)` does not fix a bled label, since the
`1fr` sibling consumes free space first. The `CONTRACT.md` measurement instruction is the only
defense.

**`text-align: end` plus `tabular-nums` does not align mixed date formats** (real labels end in `CE`
or `s`, not always a digit); `tabular-nums` stays only to make the `ch` measurement predictable.
**`text-align: start` was rejected**, opening a wide gap between a short date and its rule.

**No `.approx` class exists for a `c.` prefix**: no generator emits a span for it, and a class with
no emitter is a guess about markup this repo doesn't control.

**A floated `.sidenote` can't escape a `dl.timeline` entry** (the float resolves against the `dd`).
**Cite a timeline entry with a `sup` link into a numbered source list instead**: better at density
too, since a margin column loses sync with its anchors down a long page.

**`white-space: nowrap` on the date releases below 600px**, where the collapsed layout has no track
left to protect and nowrap would be the one thing pushing the page wider than the viewport.

**A deep link's arrival cue is an `outline`, not the `--highlight` wash** (which takes link text
under 4.5:1). It costs no layout shift, reads distinct from the link-blue focus ring by hue, and
survives `prefers-reduced-motion` where a flash wouldn't. `dt:target` takes the orange text color
instead (an outline can't reach a `dt`, and a background wash can't either since a grid gap takes no
background). `:target` also carries `scroll-margin-block-start`, so a deep link doesn't land with its
era heading scrolled off above. **Smooth scrolling was rejected**: on a long page it becomes a long
animated scroll, and the outline already answers "where did I land".

**`.footnote-ref` is `nowrap`**, scoped there rather than to `sup` since a converter may put anything
in a bare `sup`. **The citation marker's hit area grows with `padding-block` alone**, never
`padding-inline`, which would drag the underline out past the digit.

Print: `break-inside: avoid` on the entry, never the list (a whole timeline forced onto one page is
worse). `break-after: avoid` on `dt` is not needed (the grid row travels as a unit, measured).

**The collapse to one column happens at 760px, not 600px**: the date track doesn't shrink out of the
way below that, leaving a narrow prose ribbon beside a wide empty date column, the same failure
recorded for the measure cap. **A container query was rejected**: `container-type: inline-size` on
`<article>` would apply layout containment to every consumer's whole document for one component's
breakpoint.

**A `strong` inside an `<a>` repaints the link** (`strong { color: var(--orange) }` wins on the inner
element), so take `strong` out of any anchor a consumer wraps a link title in.

**Nothing in `dl.timeline` encodes elapsed time, by design.** A proportional axis buries most content
in a pile and most of the page in whitespace; era grouping already does the coarse chunking, and
anyone wanting a real axis wants a chart, which this stylesheet does not grow into.

## Tables

**No `font-family` on `table`.** Tables inherit the body serif (tabular, lining digits by
construction). **Do not put tables in the mono stack**: costs about a quarter of table width and
puts tables in a different register from the prose.

**`table.tree` is a table, deliberately not a `treegrid`.** That role promises roving `tabindex`,
arrow keys, `aria-level`/`expanded`/`posinset`/`setsize`, a keyboard contract this repo ships no
script for, and it would strip the native row/column semantics a plain `<table>` announces. Depth is
an author attribute (`data-depth`); everything else is presentation.

- **The indent is one `--tree-step` custom property, levels 0-3 only.** `attr()` can't feed a length
  into `calc()` with useful support; a per-row custom property pushes styling into the generator. A
  level-4 row degrades to flat, not wrong.
- **Depth de-emphasizes with `--label` at levels 2-3, not smaller type** (nested ratios compound, and
  the table already sits at 0.95em).
- **The `↳` needs the same alt-text treatment as the outbound arrow** (`content: "\21B3\A0" / ""`
  behind `@supports`), or the glyph lands in the row's accessible name. **Any future decorative
  `::before` owes this.**

**`width: auto; max-width: 100%`, not `width: 100%`**, or a narrow table stretches to the full page.

**The sideways-scroll escape hatch is `@media (max-width: 1000px)`**, pairing `display: block` with
`width: fit-content` (block alone reinstates document-level scroll via `width: auto`; `fit-content`
resolves correctly for both narrow and wide tables). The trigger is smaller than it looks: it starts
at 200% text-only zoom, not 400%.

**The hatch's cost is the sticky header, inert below 1000px, deliberately**: a page that scrolls
sideways is a WCAG 1.4.10 failure at every width it happens, and that outranks a pinned header at
desktop width. The opt-in answer to both is `.table-scroll`. **Chromium does not strip table
semantics on `display: block`**, measured rather than assumed; role counts are identical above and
below the breakpoint.

**A sticky `th` needs an opaque background** (an inset shadow, not `border-bottom`, since
`border-collapse: collapse` would scroll the border away from the stuck header).

**No zebra striping**: it separated rows a reader could already separate by padding, and put the
code surface behind arbitrary prose cells. Two consequences: `table.tree [data-depth="0"] td` is the
only in-table fill (meaning *root row*, nothing else), and `tbody tr:hover td` keeps its `tbody`
qualifier to stay clear of `thead`.

**`.num` is an opt-in class, not a heuristic**: CSS can't tell a number from a label, and `:has()`
can't match text content. Goes on the `th` too, or the header floats off its own column.

**An unwrapped table takes `tabindex="0"` and a `<caption>`, never `role="region"`.** The escape
hatch makes it a scroll container, and an unreachable one is a 2.1.1 failure Chrome papers over (with
a non-conforming ring) but Firefox and Safari do not. `role="region"` on the `<table>` overrides
`role="table"` and takes row/column semantics with it, the same defect as `role="button"` on
`pre.mermaid`. **This rule is gated in `scripts/maintain.nu check`** (prose alone didn't hold it):
the check deletes the `.table-scroll`-wrapped case first, then asserts `tabindex="0"` on every
remaining `<table>` and no `role="region"` on any.

**`.table-scroll` is the opt-in wrapper for a wide table**: `overflow: auto` with a `70vh` cap plus
`.table-scroll > table { display: table }`, scrolling both axes and keeping the header pinned. A
wrapper scrolling only one axis does **not** work (forces the other off `visible`, so the wrapper
becomes the scrollport and the header still leaves). `tabindex="0"`, `role="region"` and a label go
on the wrapper. The wrapper stays opt-in and `overflow-x` stays on `table` too, so both paths run at
once rather than breaking un-wrapped consumers.

**`.table-scroll` carries `scroll-padding-top: 3em`, matched to the sticky `th`'s height**, or a
focused cell in an early row lands under the pinned header (WCAG 2.4.11), confirmed by a headless
repro: without it a focused link's rect sat inside the header's bounds, with it the native scroll
cleared the header by about 46px. The fixture's wide table carries one link for exactly this reason.

## Links

**Underline thickness has a 1px floor.** A sub-pixel underline paints as a faint partial-coverage
line, and the underline is the only thing that marks a link. `overflow-wrap: break-word` lets a long
URL or slug break rather than escape its container (the conn-map Links column runs as narrow as
220px).

**The outbound arrow is decorative and once reached the accessibility tree** (a screen reader read
"north east arrow" after every external label). `content: "…" / ""` gives the pseudo-element empty
alternative text, behind `@supports (content: "x" / "y")` since the alt-text syntax is a single
value a browser that can't parse it discards **whole** (Firefox ESR still ships in that state).
`\A0` keeps the arrow from an orphan line. Print drops both arrow and underline (the destination is
unreachable on paper).

`cite` is monospace and `font-style: normal`: the browser default (italic serif) is indistinguishable
from `<em>` in this theme.

## Color and the contrast budget

**The `:root` block is the only source of color truth.** `tokens.css`, `mermaid-palette.json`, and
the inline hex in `mermaid.js` are machine-checked projections of it. **Measure a composited color
from rendered pixels, never a computed value**: a computed-value reading reports the un-composited
mix, which is wrong (two surfaces went unmeasured this way for a long time).

**Text can land on three grounds** (`--surface`, `--code-bg`, `--surface-alt`) **and a new token must
clear its floor against all three.** `--surface-alt` (row-hover fill) is the harder one to check in
light mode.

**An accent can also be the ground.** `.verdict-*`, `.step-node`, `::selection` all invert and paint
`--surface` text on an accent fill; check 9 gates all three (print is exempt for `.verdict-*` alone,
since its print block swaps to an outline). **Two tokens in relative color syntax** (`--purple-bright`,
`--highlight`) **sat outside every check** until check 10 resolved and gated both; this mattered most
for `--purple-bright`, the one token putting purple text on `--code-bg` (accepted at 4.21:1, the
`.hljs-type` pair).

**`prefers-contrast: more` states `--purple-bright` explicitly, as `oklch(0.885 0.060 300.909)`**,
because the base relative-color rule (`calc(l + 0.07)` off `--purple`) would land past the sRGB
ceiling once high contrast already raised `--purple`. **Do not replace it with the relative form
again**, and do not park it on the gamut boundary.

**Floors by mode: default 4.2:1, `prefers-contrast: more` 7:1, light 4.5:1, print 4.5:1.** Rule
tokens sit at 3:1 against `--surface`; the data ramp at 3.2:1.

### Tier decisions

**`--label` moves toward body text; `--muted` is pinned at the contrast floor.** They used to share a
hue/chroma and read as one tier despite co-occurring (`.scorecard`, `.byline` above `h3`); `--muted`
couldn't get quieter, so `--label` moved.

**The row-hover fill, `--surface-alt`, is a flat token that darkens, not a lightening `color-mix`.**
A `color-mix` composited to a lighter row that took every accent below 4.5:1. **Do not reach for
another `color-mix`**: `--surface-alt` already exists and needs no compositing to reason about.

**`aside` has no fill at all**, screen or paper: a tint took a `cite`/`.sc-note`/`.count`/`::marker`/
status span below floor. The orange accent bar marks the callout instead.

**`--purple` on `--code-bg` sits under the text floor, and the repo left it alone**: purple is `h2`,
the `pre` bar, `::selection`, and nothing puts purple *text* there (an `h2` never renders inside a
`pre` or cell). Recorded rather than fixed, since the token mirrors into `mermaid-palette.json` twice.

**Borders on `--code-bg` take `--rule`, not `--rule-light`** (the lighter weight fails 1.4.11 there:
`.filter-box`, `.mermaid-zoom`, `pre.mermaid:hover`). The side effect is wanted: a control now reads
stronger than a passive container like `details`.

**`em` carries no color, it inherits**: correct inside `aside`/`blockquote`/`.sidenote`, matching
surroundings rather than overriding a color they already chose.

**`--highlight` is a body-copy surface only.** `mark` pins `color: var(--on-surface)` since every
other tier fails on the wash. **Do not paint the wash under anything but body copy** (a `li:target`
highlight was built, measured, and removed on this basis).

### The data ramp

**`--data-1` to `--data-4` exist so a diagram category can't borrow a prose accent.** `--data-1`
moved off the link hue, a near-exact collision; hue separation between members is what matters, since
they co-occur in one diagram. The ramp carries its own light and print values (a single base `:root`
declaration once drew dark-ground fills on a light page). Each member holds a stated fraction of
maximum in-gamut chroma at its lightness and hue; check 8 pins those fractions.

**A pie slice renders the token as of v1.40.0.** Check 5 always asserted the token cleared the
non-text floor (governing a `classDef` fill, a legend swatch, any direct `var(--data-2)` use) but
said nothing about what a `pie` fence itself rendered at Mermaid's default 0.7 `pieOpacity`.
`pieOpacity: '1'` closes that gap; check 11 measures the label that lands on it. See
[Diagram types](#mermaid).

**`--data-2` sits close to `--pink`, `--data-3` close to `--green`, left alone**: nothing in a
diagram puts a category fill beside body copy, and a move means two more hex projections to
recompute.

**`classdef`/`classdefLight` fills both exist as of v1.40.0**, check 2 gating both sets plus the
letter each paints on its own fill (`--surface` on the pale dark ramp, `--on-surface` on the
mid-tone light ramp: reusing `--surface` in light would land at 3.45-3.53:1, out of bounds).
**`CONTRACT.md` § 2 bans a `classDef name fill:#hex` line on any page that follows the reader's
appearance**, permitting it only on a page locked to one palette: a fence has no CSS to read, so one
literal hex can't follow appearance and no palette work changes that.

### Gamut and vividness

**A declared chroma sRGB can't hold is silently clipped, and every contrast check stays green**
(three high-contrast tokens shipped that way for two releases, since `oklch_to_linear` clips before
measuring). Check 7 bisects the sRGB boundary and gates every parsed token in every mode. **The trap
is directional**: the chroma ceiling shrinks as lightness climbs, so raising `L` for "more contrast"
washes a color out faster than the numbers predict. **Do not park a token exactly on the gamut
boundary**: it tips out on any later lightness nudge; each token holds a stated fraction of ceiling
instead.

**High contrast compresses the accent set (the ceiling collapses at high lightness), and no token
edit fixes that.** Text mitigates it (`verified`/`unverified`/`correction` spelled out), not color.
**Do not try to widen these by a hue move**: chroma compressed, not hue separation.

**`--red` is the loudest accent in every mode on purpose**, check 8 pins it there: its chroma is what
separates `.correction` from `h1` pink and `.unverified` orange. **`--link` and four other accents
(`--orange`, `--purple`, `--pink`, `--green`) deliberately let their fraction float** rather than
holding one pinned fraction like `--red` and the data ramp: a pin means new chromas across three
mode blocks each, re-measuring every ratio and both Mermaid projections, worth it for a status color
but not for "`h2` calmer on paper". **A table of five that's true beats a table of ten that's
aspirational.**

### P3 gamut for six vivid accents

**`--red`, `--orange`, `--purple`, `--pink`, `--green` and the `--data-*` ramp hold a wider,
Display-P3-reaching chroma in dark and light mode only**: high contrast and print keep original
sRGB values (high contrast is already gamut-compressed by design; a screen's P3 gamut has no
correspondence to reproducible ink). `palette-check.py`'s `P3_WIDENED`/`P3_MODES` scope the relaxed
ceiling to exactly these tokens in exactly these two modes; everywhere else the sRGB gate is
unchanged.

**`--red` and the data ramp keep their exact existing fraction**, now measured against the wider
ceiling: no re-litigation of loudness, only a wider ruler. **`--orange`/`--purple`/`--pink`/`--green`
get no pinned fraction**: their fraction of the sRGB ceiling swung wildly between modes purely by
accident of where one hardcoded chroma landed, so porting one as a "target" would state a precision
that was never designed. The rule instead: **+25% chroma, independently in dark and light**, capped
wherever it would break an existing check-5 floor (only `--purple` dark against `--code-bg` needed
the cap, to +9.3% instead of +25%, holding 4.21:1).

**High contrast now restates the data ramp explicitly** (it never had to before check 8 caught an
unstated inherited P3 chroma drifting its vividness fraction out of band), the same treatment the
other five accents already get.

**Every hex-only consumer (Mermaid, the three editor themes) is still sRGB and now needs gamut
mapping, not a straight conversion.** Before this, no token's chroma ever exceeded the sRGB ceiling,
so `oklch_to_hex`'s per-channel clip was dead code. `oklch_to_hex` now reduces chroma to the sRGB
ceiling before converting (holding `L` and hue), matching what a browser's own CSS Color 4 gamut
mapping does. `mermaid-palette.json` and `mermaid.js`'s `primaryBorderColor`/`nodeBorder`/`pie1..4`
literals were recomputed to match; every other Mermaid hex was already in-gamut.

**Percent of maximum chroma is the wrong yardstick across lightness: it works only across hue.**
**Do not carry the fraction rule to the near-neutral grays** (`--label` etc).

**An APCA reading inverts the WCAG 2 story (dark mode runs below light mode on identical roles), and
no token moved because of it**: that's the known WCAG 2 overstatement of light-on-dark, not a
defect here, and a flat Lc threshold misapplies APCA, whose threshold falls with size and weight.

### What is gated, and what is open

`.github/palette-check.py` runs twelve checks: (1) hex projections in both Mermaid palettes; (2) the
`classdef` fills in both sets plus their painted letter; (3) `/* was */` provenance comments; (4)
stray hex in `mermaid.js`; (5) the contrast floor in all four modes against three grounds, plus rules
and the data ramp; (6) `--mermaid-scheme` both directions, no `prefers-color-scheme` in `mermaid.js`,
and the `(max-width: 600px)` breakpoint pinned in both files; (7) sRGB gamut for every parsed token
in every mode; (8) the vividness bands; (9) the inverted accent-as-ground pairs; (10) the two
relative-color tokens per mode, plus `mark`'s alpha composite; (11) the pie slice label against all
four fills in both palettes, plus `pieOpacity` pinned to `1`; (12) `--on-surface` over the
`table.bar-chart` band at its alpha, against both grounds in every mode, plus print and forced-colors
pins.

**Check 9 also gates its own reason for existing**: `.step-node`'s role list deliberately omits
`--data-*`, and the check says so out loud rather than leaving an untested prohibition. **A new token
joins check 5's roles, then decide whether it also belongs in check 8's table**: a light-palette
token move needs a matching Mermaid-side move, and the gate is what says so.

**Two `CONTRACT.md` § 2 requirements reach the sheet where no palette check can see them.**
`--icon-color` on `.step-node` (inline `style` attribute) is gated in `scripts/maintain.nu check`
instead, scanning every fixture for a banned `--data-*` value. A `quadrantChart` point label (inside
a `pre.mermaid` fence, diagram source) stays prose: the fixture's own two overlong labels are the
only instance in the repo and exist to exercise `overflow: visible` (see Diagram sizing), so a length
gate would have to exempt its only subject and assert nothing. **Some obligations stay prose**: writing a gate that skips its only subject reports green about a question it never asked.

**Three things stay open, none a measurement**: `--orange` carries eight roles (`strong`, the `mark`
wash, syntax numerals/constants, the `aside`/alert bar, `.markdown-alert-title`, `.unverified`,
`.verdict-partial`, `:target`): every alternative trades one hue collision for another, and a move
would break the "orange arrival cue reads distinct from the link-blue focus ring" reasoning
elsewhere. Five accents let their chroma fraction float (above). The high-contrast set is
gamut-compressed and text mitigates it (above).

### Forced colors

**Forced colors suppresses shadows.** Anything whose only boundary was a shadow needs a border
instead; the print block's inset-shadow trick can't be reused (an inset shadow is still a shadow).

- **Semantic chips outline themselves**: `code, kbd, .verdict, .badge { border: 1px solid
  currentColor }`. State survives in the chip's own text (`PASS`/`PARTIAL`/etc); the border restores
  the boundary, not the meaning.
- **A code BLOCK is not a chip.** `pre > code` is `display: inline`, so the chip border fragmented
  across every code-block line into three broken boxes. `pre code { border: none }` undoes it; `pre`
  keeps its own accent bar, which forced colors already preserves.
- **Tables carry a real border** (`table, th, td { border: 1px solid currentColor }`), or the outer
  rule, header shading and inset header rule all vanish, leaving no frame and no header distinction.

Fills inside a table still flatten, left alone deliberately: the mode restores the grid, not the tint.

**This block had no coverage at all until v1.41.1.** `render-modes.py`'s pixel assertion (checking
`--surface` painted) can't transfer here, since forced colors means the sheet's colors stop deciding
anything. So it's gated on **structure** instead, in `.github/script-probe.py`: the condition is
rewritten to `@media all` in a scratch copy, and eight assertions read computed styles an edit here
actually breaks (chip outlined, table/cell outlined, block `code` not outlined, `pre` keeps its bar,
the grain is off). **A mode whose correctness is not a color needs a structural gate, not a pixel
one.**

## Form follows role

Three families were drawn the same way and meant different things; **form now separates them so the
shape carries the role and color is free to mean one thing.**

**A filled chip is a state; an outlined chip is a label.** `.verdict-*` keeps its fill (pass/partial/
failed/N/A are states of a claim). `.badge` is `--label` text with a `currentColor` ring, no fill: it had been three tier fills, which told the reader tier 3 was "failing" on a green-to-red ramp when
tiers are ordinal, not health states. `.badge-t1/-t2/-t3` are not removed, just carry no
declarations. **What that trades away**: tier is no longer scannable at a glance, but the text always
carried the level. **Three steps of one new hue was costed and rejected** (three more `:root` tokens
plus three print overrides, and the free hue gaps are too narrow to read as three colors at chip
size).

**A border means interactive; an accent bar means passive block.** `.scorecard` was bordered
identically to `details`/`.nav-group`/`.nav-list`/`.filter-box`/`.mermaid-zoom`, so a data panel and
a button read as one kind of object. `.scorecard` now takes `border-inline-start`. **Every remaining
bordered box in the sheet is something you can click, type in, or open.**

**Three prose accents carry two or three roles each, accepted:** `--pink` (h1, th), `--purple` (h2,
`pre` bar, `::selection`), `--orange` (`strong`, aside bar, `.unverified`). Only `--orange`'s overlap
is visible to a reader; the other two pairs are separated by form (a heading vs. an italic small
header; a heading vs. a 3px bar and a selection fill).

**The hue budget is spent.** A new role takes an existing accent **plus a different form** (weight,
bar, ring, fill), or a diagram role takes `--data-1..4`. A new hue is the last resort, and reusing one
for a third prose role needs a line here explaining why the two won't appear together.

## Borrowed components

Six components plus one page-wide texture were adapted from factory.strongdm.ai's product pages:
structure only, no color, every component reusing an existing token under the hue-budget rule above.

**`.kicker`** (eyebrow pill) reuses `--link` and the `oklch(from … / alpha)` pattern `--highlight`
established: no new token for a tint. A document-status use picks the color already scoped to that
state rather than adding a seventh accent. **Tint sits at 8% alpha, not 12%**: 12% pushed `--link`
text on a `--link`-tinted background under the 4.5:1 floor in light mode (4.47:1); 8% clears it with
margin.

**`.tag-dot`** (`::before` circle) paints `currentColor`, carrying no color of its own, so it can't
reopen the rejected tier-ramp above. **Belongs on an empty element, never one that also holds the
label**: `currentColor` recolors sibling text too, and the first fixture draft measured 3.45-3.53:1
painting a label directly.

**`.live-dot`** (the sheet's first `@keyframes`) reuses `--green`, the existing "healthy" role.
`prefers-reduced-motion`'s global animation-duration zero already freezes the pulse for free. No
print override needed (paged media runs no CSS animation regardless).

**`.icon-list`/`.icon-chip`** takes color from an inline `--icon-color` per `<li>` (the
`--timeline-date` convention), keeping the component color-free by default. **The glyph itself is
fixed `--on-surface`, never `--icon-color`**: a same-hue glyph on its own tint measured as low as
3.35:1 dark and failed outright in light mode for all four demo hues, where `--on-surface` measures
8.06:1+. **The `.icon-chip` glyph is `aria-hidden="true"`**, since it always sits beside a visible
label (unhidden, a screen reader announces the initial and then the title right after it, twice).
`.step-node` is the opposite case (no adjacent label) and keeps its letter as real text.

**A step chain names its steps in the prose that introduces it, and every `.step-arrow` is
`aria-hidden="true"`.** A node is a circle with room for one character, so the words can't go inside
it: the fixture originally shipped bare letters (`S`, `I`, `O`, `V`) decoding to nothing for any
reader. **Do not answer this with a visually-hidden label class**: the sheet has none, and adding
one turns a problem one sentence of prose already solves into a payload API.

**`.step-chain`/`.step-hop`/`.step-node`/`.step-arrow`** is a linear process strip for a flow too
trivial for Mermaid (three or four stages, no branching): not a Mermaid replacement; any graph with
a branch or loop still belongs in `pre.mermaid`. Same `--icon-color` convention as `.icon-list`,
**with one exception: `.step-node`'s `--icon-color` takes a prose accent, never a `--data-*` slot**: the node fills at full strength under real text (`--surface`), and the ramp is only checked at the
3:1 non-text floor (measured 3.45-3.60:1 there). `.tag-dot`/`.icon-chip` may still carry `--data-*`
since neither puts text on the fill. **Only a full-strength fill under real text is the problem**: check the distinction before adding a fifth component to this convention; check 9 gates the
permitted set, `CONTRACT.md` § 2 states the consumer obligation. **Every node but the first is
wrapped with its leading arrow in one `.step-hop`**, so a flex-wrap can't strand an arrow on one line
and its node on the next with no visible connector.

**`blockquote.pull`** adds a large faint opening quote over the existing accent bar, opt-in since the
default `blockquote` is used densely for citations. Decorative, so it takes the same alt-text
convention as the outbound arrow.

**`body::before` paints a fixed, full-viewport film grain** (an inline SVG `feTurbulence` filter,
low opacity, `mix-blend-mode: overlay`), carrying no hue of its own so it crosses dark/light/print
cleanly. `pointer-events: none` and `z-index: -1` (still paints above `body`'s own background, per
CSS stacking order). **Switched off in print and `forced-colors: active`**: ink has no blend-mode
equivalent, and a reader in that mode shouldn't see pure texture.

**Four more factory.strongdm.ai patterns were measured against this repo's own decisions and left
out, not missed**: a `.cta-button` hover sheen/lift (this repo already decided hover wants no motion,
see Interaction states); a `.glass-card` `backdrop-filter` blur (already rejected for the sticky
`th` case, and moot here with no busy background to soften); a `.section { min-height: 100vh }`
one-idea-per-screen layout (opposite of the settled dense-reference-page decision); an
absolute-positioned JS nav dropdown (`details.nav-group` already does this with no script).

**`.kicker`, `.icon-chip`, `.step-node` join the forced-colors border list** (all three carry their
whole shape through fill alone). **`.tag-dot`/`.live-dot` take `background: CanvasText` there, not a
border**: both are round and empty, so a border would ring nothing; a render showed any author
background (even `currentColor` on an empty `::before`) resolves to Canvas under forced colors, so
the dot doesn't flatten, it vanishes without this. `.verified`/`.unverified`/`.correction` need no
override: they color a glyph forced colors keeps drawing, so they only lose a hue, not their content.

**A sticky element does not take `backdrop-filter` blur**: the sticky-`th` decision above (opaque
background required) already rules it out; blur over an opaque layer is a no-op.

## CSS charts

One component draws a chart from ordinary markup, `table.bar-chart`: CSS only, no script, no CDN, no
build step. A pie is a Mermaid `pie showData` fence instead (the existing hard-offline CDN exception).
A second CSS pie was tried for one release and removed; see below.

**Values are text in the markup, always**: what makes shipping a pie chart defensible despite
Tufte's objection that readers compare angles and areas badly: the template themes one anyway because
a part-to-whole share of a few categories is real, provided the chart is always a second reading of a
number the page already states (`CONTRACT.md` § 2 obligation). A ranking, a magnitude comparison, or
five-plus categories is `table.bar-chart`.

**The bar chart is a table with a class, and the band paints inside the cell holding the number**
(an empty cell was rejected: it would make the graphic the only carrier of the value).

- **The band is a 0.3-alpha wash of `--data-1`, never full strength** (full strength under text is
  the `.step-node` trap; text on it measures about 3.5:1). Check 12 measures the actual composite
  rather than restating the alpha; the first floor failure appears at 0.5.
- **Every band is one hue; a per-row `--bar-color` was tried and reverted.** At 0.3 alpha the four
  washes land within Lc 2 of each other (1.00-1.13:1 band-against-band) while the legend dot at full
  strength reads 7.39:1: no alpha fix exists (even 0.4, check 12's cap, still leaves Lc 3). **Do not
  reintroduce a per-bar color property**: it can't deliver the category key it implies, and as an
  inline hook it also invites a prose accent onto a neutral number. The row label carries the
  category.
- **The bar cell takes `inline-size`, not `min-inline-size`**: Chromium's auto table layout doesn't
  size a cell from `min-width` (measured: an 8rem minimum still produced a 130px column).
- **Background longhands, never the shorthand**: `tbody tr:hover td` sets the shorthand at lower
  specificity than `table.bar-chart td.bar`'s two classes, so a shorthand there would delete the
  row-hover fill on exactly the rows with a bar.
- **Direction costs one override**: `[dir="rtl"]` flips the gradient's `background-position`, since
  neither a gradient nor `background-position` takes a logical direction keyword.

**The pie is a Mermaid `pie showData` fence; the CSS pie (v1.42.0) was removed in v1.43.0**, one
release later, after rendering both side by side: the Mermaid pie drew in-slice percentages, a
legend, a title; the CSS `conic-gradient` had none of that (nothing inside it was text, forcing a
`role="img"` plus an `aria-label` plus a caption legend: three restatements of the numbers to draw a
shape still unreadable). Mermaid draws the label in the slice and themes every slice from
`--data-*`, at the cost of a CDN request. **The offline case is `table.bar-chart`, not a second CSS
pie**: keeping one alive to cover Mermaid's offline failure cost a component, a § 2 requirement, a
print pin, a forced-colors rule, and a check, for the one chart shape Tufte objects to, in the one
form that can't carry its own numbers.

**Four slices stays the ceiling**: the ramp has four members, and a fifth has no color left that
clears the floor. **A pie needs a boundary between slices**: the ramp holds one lightness by design,
so adjacent slices had no luminance step at all (measured 1.00-1.14:1 across palettes and even under
simulated color-blindness). Mermaid's `pieStrokeColor` (`--surface`, so slices separate by a gap not
a line) and `pieOuterStrokeColor` (`--muted`, matching every other hairline) answer this, themed as of
v1.41.0. **Do not drop either stroke to Mermaid's `black` default.**

**The bar band paints through a background image, so print and forced-colors both need a pin,
verified by rendering rather than reasoning.** Print drops background graphics by default (verified
via `print_background=False`), so `table.bar-chart td.bar` takes `print-color-adjust: exact` (check
12 holds it). **`.tag-dot::before` needed the same pin**: a legend's dots vanished on paper without
it, costing the legend's whole key, found by reading a printed PDF. `forced-colors: active` computes
`background-image: none` on its own (verified), so the bar table needs no rule; the CSS pie did, and
it's gone with the component. **Never answer a forced-colors case with `forced-color-adjust: none`**: it overrides the reader's own accessibility setting for a graphic whose numbers the page already
states.

**Nothing here draws a line chart.** A Mermaid `xychart-beta` fence can't be themed (see
[Diagram types](#mermaid)), and a pure-CSS line chart needs hand-authored SVG paths a generator can't
be asked to emit correctly. The gap is deliberate.

`samples/dark-charts.html` carries two bar tables (share of whole vs. share of the largest value, the
convention that makes an unlabelled axis honest) plus a Mermaid pie of the same numbers.

## Progressive disclosure

Two components (template v1.21.0): `nav.toc` (on-this-page index), `details.deep` (collapsed detail
tier).

**`nav.toc` marks links with a dotted `border-block-end`, not an underline.** The underline-only-mark
rule (Links) holds for prose; a standalone index is a list of links and nothing else, so the dotted
rule is its marker (`prefers-contrast: more`'s underline bump can't reach it, outranked by
`nav.toc a`).

**The index runs two columns above 600px, one below**: at 320px two columns left each entry about
68px and wrapped titles to five lines (matches `.col-2`'s breakpoint). **The print override targets
`nav.toc ol`, not `nav.toc`** (`columns` on the wrapper does nothing to the list inside it).

**Both components use logical properties only** (`border-left`/`padding-left` shipped in v1.45.0 and
kept the index rule and list indent on the left in RTL while prose flipped).

**Neither component names a font of its own.** The first version set `font-family: var(--sans)`, a
token `:root` never declares, resolving to the inherited serif either way. The sheet ships two faces
(body serif, code mono); a third is a decision this section doesn't make. **Do not reintroduce the
token without declaring it.**

**The summary triangles are decorative and once reached the accessibility tree** (`<details>` already
exposes its own open state, so the marker only added a spoken "black right-pointing small triangle").
Same `content: "…" / ""` alt-text convention as the outbound arrow.

**`nav.toc` paints a composited ground no gate reaches** (`color-mix(in oklab, var(--surface-alt) 60%,
transparent)` lands between two measured grounds). `--muted`/`--purple-bright` clear their floor
against both, so this is an honest, documented gap, not a check that cannot see the mix.

**Hover on both components sits inside `@media (hover: hover)`** (v1.45.0 shipped both outside it: see Interaction states for the tap-sticks-forever cost). **Both components carry a fixture instance**
now (they shipped with none for two releases, so no mode render or forced-colors sweep ever drew
them).

**Every `var()` here resolves to a declared token or carries a fallback.** Seven references resolve
outside `:root`, all deliberate: `--tree-step`/`--bar-tint` are declared on the component that reads
them; `--bar`/`--icon-color`/`--natural-width`/`--timeline-date` are consumer-supplied with their own
fallback in the `var()`. `--sans` had neither, which is what made it dead. **A new consumer-supplied
token states its fallback in the reference.**

## Editor themes

`themes/` shares the palette; the **slot map** (which token paints which syntax class) is a separate
decision. **Prose logic does not transfer to an editor**: in prose, sparse low-chroma color reads as
restraint; in an editor, where almost every glyph carries color, the same chroma reads as wash.

**`--label` is the document's caption tier, not a code tier.** Punctuation, parameters and both field
kinds on it would collapse a buffer into one blue-gray band. Punctuation sits at `--on-surface`
(matching upstream Dracula); parameters at `--orange`; `--label` keeps only legitimately secondary
instance/static fields.

**Types cannot sit on plain `--purple`** (the dimmest accent) despite being C#'s highest-frequency
token: they use the existing `.bright` lift, not a new placeholder or palette change.

**Three alternatives (closer to Dracula's own slot map: functions to `--green`, strings to
`--data-4`, numbers to `--purple`) were rendered and rejected**: `--data-4` reads olive not yellow at
this chroma, and moving strings off green breaks the one cross-medium tie the theme has (inline
`code` is also green).

**Do not answer "the theme looks washed out" with a chroma raise in `:root`.** Every contrast-budget
ratio was measured against those values, on every published page. A dim-reading theme is a slot-map
problem first. Verify against the **generated** `.icls`, not the template: placeholders hide which
hex actually lands.

### Light and dark parity

**Rider, Zed, Ghostty, iTerm2 and VS Code ship a light variant**, projected from the same
`prefers-color-scheme: light` override the page itself uses. opencode and tmux stay dark only:
neither format has an appearance-switch mechanism to project a second palette into. `.github/palette-check.py --dump`
returns `{dark: {...}, light: {...}}` rather than one flat map, and `scripts/create-themes.nu`'s
`render`/`resolve` pick a palette per placeholder: bare `{{token}}` resolves against a template's
default scheme, `{{light:token}}` (or `dark:`) overrides that one placeholder regardless of default.

**Two shapes cover every format, chosen by whether the format's own schema holds more than one
appearance per file.** A format that does not (Rider's `theme.json`/`.icls`, VS Code's
`color-theme.json`, Ghostty's theme file, iTerm2's `.itermcolors`) gets a second, separately
generated `-light` file: same template rendered a second time with `--scheme light`, so every bare
placeholder in it resolves to light with no per-placeholder prefix. A format whose schema already
holds several appearances in one document (Zed's `themes` array) keeps one file: the dark theme
object renders unchanged and the light one, alongside it in the same template, prefixes every
placeholder with `light:`. Do not invent a third shape for a future target before checking which of
these two its schema actually is.

**Rider ships two complete themes, not one that follows the system setting**: IntelliJ Platform
themes are one appearance per `theme.json`, so `plugin.xml` registers a second `themeProvider` for
the light one, and the light `.icls` inherits IntelliJ's built-in `Default` scheme
(`parent_scheme="Default"`) where the dark one inherits `Darcula`. The light `theme.json`'s four
`Checkbox.*` icon keys drop the `.Dark` suffix the dark theme's copies carry, per JetBrains' icon
palette convention (a bare key is the light-icon asset, `.Dark` overrides it for the dark one).
**Neither of those two differences has been run against an actual Rider install**, only checked
against JetBrains' own theme documentation, because nothing in this repo's toolchain can render an
IntelliJ theme the way Playwright renders the CSS payload. Flag it if either turns out wrong once
installed, rather than trusting the doc citation as verification.

**iTerm2 has no single-file dual mode**: a profile's "Use different colors for light and dark mode"
checkbox takes two separately imported presets, so `dracula-tufte-light.itermcolors` is a second
plist built by the same `render-itermcolors` function with `scheme: "light"`, not a field inside the
existing file.

## Mermaid

### Init config

Use `theme: 'base'` plus explicit `themeVariables`. **Never `theme: 'dark'`**, which ignores this
palette entirely. **Pass hex, never `oklch()`**: khroma throws and aborts init on an oklch string,
so no diagram renders at all. Values mirror `mermaid-palette.json`, CI-enforced.

**`look: 'classic'` is explicit, as of Mermaid v12.0.0.** Mermaid 12 changed its default look from
`classic` to `neo` and its default layout from `dagre` to a bundled ELK. `theme: 'base'` stays
explicit so colors don't move; `look` is pinned rather than left to follow the new default. Rendered
side by side, `neo` adds a `filter: drop-shadow(...)` and a brighter stroke halo on every node, ink
carrying no data, declined for the same reason the CSS pie lost its `conic-gradient`. **Layout is
left unset**: every diagram now lays out with ELK by default, an upstream default this template
accepts rather than pinning `layout: 'dagre'` to hold the old geometry (see [Large maps](#connections-map-layout)
for what changed on the one fixture that already used ELK deliberately). **Mermaid v12 also raises
its runtime floor to ES2024, Safari 17.4+, Node 22.12+**: this template ships no polyfill and states
no browser matrix of its own, so that's now the floor for any page pulling Mermaid.

**The `@mermaid-js/layout-elk` CDN import is gone**: Mermaid v12 bundles ELK into core, so the
second CDN pin and the dynamic `import()` that only ran for a `layout: elk` fence are dead weight.
Verified by rendering `samples/dark-conn-map.html`'s three-subgraph flowchart and its explicit-ELK
diagram with the import removed: both render with no layout-loader error.

**`darkMode` belongs inside `themeVariables`**, not root-level: `mermaidAPI` only passes
`config.themeVariables` to `base.getThemeVariables()`, so a root-level `darkMode` never reaches the
theme and every derived color computes light-mode.

**`fontFamily`, `fontSize`, `pieOpacity` are the only non-color `themeVariables`**, none mirrored
into `mermaid-palette.json` (nothing there to catch). `fontSize: '1rem'` tracks the reader's root
size (Mermaid defaults to a hardcoded 16px); `pieOpacity: '1'` is pinned by check 11 instead, since it
changes a measured contrast pair. **`background` is inert** (swept across twelve diagram types,
never reaches output): correct by intent, not load-bearing.

**Theme the `note*` family explicitly**, or `Note over` renders at Mermaid's stock yellow, the only
light surface on a dark page. **`actorTextColor` is not needed and is deliberately absent**: a
`text,tspan` sweep that looks like a hidden dark layer is really one `<text>` wrapping one `<tspan>`
with no direct text child to paint. **Probe a `tspan`, not its parent `text`**, before adding this
back; a no-op themeVariable still costs two CI gates to keep in step.

**Pin the CDN to an exact version, never a range.**

### Label measurement

**`fontFamily` is set at both the config top level and in `themeVariables`, and both copies are
load-bearing.** The themeVariable reaches the injected CSS that paints labels; the root one is what
`calculateTextDimensions` measures with, deciding label box width. **The measurement font is the
render font, or the arithmetic is wrong.** `sequence.noteFontFamily`/`noteFontSize` are accepted by
`initialize()` and read back by `getConfig()` but change nothing through 11.16.1: not the fix.

### Diagram sizing

Label size follows SVG scale, so both viewport extremes are the same bug.

**Wide end: `pre.mermaid svg` takes `width: auto`, not `width: 100%`**: stretching a viewBox SVG to
its container multiplies label size with it (a sparse graph renders labels larger than `h1`).
`max-width: 100%` still shrinks an oversized graph; `text-align: center` (in both layouts) keeps a
small one centered.

**Narrow end: below 600px the diagram renders at natural size and scrolls**, or diagram text would
render at half the size of the prose beside it. **`--natural-width` recovers the natural size CSS
otherwise can't**: with `useMaxWidth` default, mermaid writes `width="100%"` plus a real-size inline
`max-width`; `mermaid.js` copies that into the custom property. Two earlier attempts failed: plain
`width: auto` + `max-width: none` (an SVG with a viewBox resolves `auto` to its container, so labels
stayed small); copying inline `max-width` into inline `width` (broke the band *above* the breakpoint
with a page-level sideways scroll). The `!important` fights mermaid's own inline styles; the selector
repeats inside the media block since it needs both higher specificity **and** `!important`.

**`pre.mermaid svg { overflow: visible }` exists because some diagram types write a viewBox that
excludes their own content** (`quadrantChart`'s fixed viewBox with edge-centered point labels forced
this). Needed on `pre.mermaid` (or inherited `overflow-x: auto` clips the same content) and on
`.mermaid-overlay svg` (or zoom shows the same truncation it's meant to escape).

**The cost: a label outside its own viewBox is unreachable below about 690px (not 600px), and no
`overflow` value anywhere recovers it.** `overflow-x: auto` unconditionally was tried and reverted: strictly worse: SVG ink outside the root `<svg>`'s box is not scrollable overflow for any CSS
ancestor, so a scroller recovers nothing and instead *clips* content `overflow: visible` had at least
been painting into the page gutter. The zoom overlay doesn't rescue it either: it's proportional to
the SVG's own width, so the escape scales with the zoom (measured 69-105px lost at a 640px viewport): only shrinking the SVG helps, which would shrink every zoomed diagram, the one thing the overlay
exists not to do. **This is a consumer constraint, stated in `CONTRACT.md` § 2**, not a stylesheet
defect: the fixture's two overlong point labels exist to exercise this; realistic labels lose nothing
above 601px. Same defect class as `packet`/`xyChart` (a Mermaid viewBox bug): take it when Mermaid
fixes it.

**A JS `refit()` growing the viewBox to `getBBox()` was tried and reverted**: fired from a
`MutationObserver` before flowchart `foreignObject` labels lay out, producing an enormous bbox. **One
CSS declaration needs no timing at all.**

### Zoom

**The clone is stripped of mermaid's own sizing**, so the overlay's CSS governs every diagram
identically (an inline `max-width` left in place would zoom in one layout and do nothing in the
other; the overlay sets `width`/`height`, not `max-*`).

**The zoomed diagram's halo is tinted from the scrim**, `oklch(from var(--surface-alt) 0.15 c h /
0.5)`: a pure-black shadow only looked right in one palette.

**The close mark honors safe-area insets** via `max()` against `env(safe-area-inset-*)` (not
verified on hardware with a real notch). **The ✕ is a pseudo-element, not a button**: the whole
overlay dismisses on click and Escape already closes it, so a button would add a second path to one
action and a needless focus stop.

`securityLevel` defaults to `strict`, sanitizing `click` directives away; a consumer sets
`window.mermaidSecurityLevel = 'loose'` to opt in. The overlay throws loudly when `#mermaid-zoom` is
missing, rather than a bare `TypeError` pointing nowhere.

**Clicking a diagram opened nothing, on any fixture, until this was found.** A `data-*` "already
wired" guard is not safe against `cloneNode`: Mermaid clones the `<svg>` at least once during its own
render pipeline, the clone carries the marker attribute over, but a JS listener added with
`addEventListener` does not survive a clone, so the handler stays bound to the discarded original.
**The fix is a `WeakSet` keyed on the element itself**, not an attribute a clone can copy: a clone is
a different object and correctly misses the set; the same object on a later pass correctly doesn't
get a second listener. Confirmed with a real driven click, not a synthetic `dispatchEvent` (which
proves nothing about which element a listener is bound to).

**A node's own link must win over click-to-zoom.** The svg-wide zoom listener now checks
`e.target.closest('a')` and defers to the node's own navigation when the click lands on one: verified with a real click on a `click`-directive node (navigates, overlay never opens) against one
with no directive (opens as before).

### Diagram types

**`packet` is not themeable through config, so CSS overrides it.** `defaultPacketStyleOptions`
hard-codes black text on `#efefef`; neither `initialize()` nor a fence directive moves it.
`tufte-dracula.css` overrides mermaid's id-scoped injected rule with `!important` (required, not
convenient: id-scoping beats a page-level class rule regardless of source order). **Verify a
mermaid override by rendered pixels, never by reading the exported SVG's own `<style>`**, which
doesn't change even when an override is visually in effect.

**`xyChart` cannot be fixed here.** Same inert-config defect as `packet`, but no CSS door: bars and
line are plain `<rect>`/`<path>` with a literal fill/stroke and **no class attribute at all**. Take
it when Mermaid ships a fix, or use a per-diagram `<style>` scoped by a hand-added `id`. **Never
widen a selector on the shared sheet for it.**

**`sankey` and `block` render in d3's Tableau10 categorical scheme**, no config surface in front of
it. Left alone: nothing puts a category fill beside body copy.

**`mindmap` was tried for the connections map and rejected.** Mermaid's own section coloring resolved
to literal black under `theme: 'base'` with this palette's dark `primaryColor` (an `hsl(_, _, 0%)`
Mermaid computes by hue-rotating off `primaryColor`), fixable the way `packet`/ELK clusters are. What
actually killed it: `mindmap` accepts no `accTitle`/`accDescr` at any indentation and rejects the
whole diagram (not just the directive) the moment either appears, a real accessibility regression
against every other diagram type here; and it has no equivalent to a legend, since a connection is
always a plain parent-child line with no per-edge line style. **Do not re-add `mindmap` on the
strength of a theming fix alone**: neither gap above is a CSS problem.

**`usecase` (v12.0.0+, keyword `usecase-beta`) needs no new `themeVariables`, and none were added.**
Actors and ellipses already resolve through `primaryColor`/`primaryBorderColor`/`primaryTextColor`/
`lineColor`, verified by rendering against both palettes. A `systemBoundary` doesn't read those: Mermaid numbers boundaries from its own categorical palette, and `usecaseBoundaryBkg`/`Border` are
only a fallback for a theme with no such palette (setting them changed nothing, confirmed by
rendering with and without). What carries the boundary correctly instead: a `systemBoundary` renders
with a `cluster` class like a flowchart subgraph, so the existing `pre.mermaid .cluster rect`/
`.cluster-label` override (written for ELK, see [Large maps](#connections-map-layout)) covers it for
free. `samples/dark.html` carries a `usecase-beta` fence with one `systemBoundary` as fixture
coverage.

**`C4Context`/`Container`/`Component`/`Dynamic`/`Deployment` are not themeable here, and no fixture
exists for any of them.** A probe render found `Person()`/`System()` painted with Mermaid's hardcoded
C4 defaults (`#08427B`, `#1168BD`) regardless of theme, since the C4 renderer sets fill/stroke as a
literal shape attribute: same defect class as `xyChart`. A relationship label rendered at `#444444`,
failing contrast on this dark ground outright. A CSS door does exist (the `!important` route
`packet`/ELK clusters use), but C4's several shape tiers (`person`, `external_person`, `system`,
`external_system`, `system_db`, `system_queue`, `container`/`component` tiers) are too much surface to
theme with no fixture to prove it against (see [Fixtures are coverage](#fixtures-are-coverage)). A
consumer adding a C4 diagram on this dark palette should verify contrast themselves.

**Diagram text on the page ground (not a node fill) was invisible in print**: Mermaid bakes hex into
the SVG at init, and print is a media query with no re-render, so a dark-page-themed diagram kept
painting `textColor` at `#f8f8f2` while `@media print` turned `--surface` white (measured: pie
title/legend, `quadrantChart` axis labels, every `sequenceDiagram` message label at about 1.0:1). An
earlier fix (v1.40.1) recolored four measured classes onto `--on-surface`, covering only the five
diagram types the fixtures carried; v1.41.0 replaced it with giving the diagram back its own palette
instead, which covers every diagram type with no per-class enumeration.

**The diagram is a dark object on a white page, so `@media print` treats it as one**: `pre.mermaid`
re-declares the five tokens its own rules resolve through (`--surface`, `--on-surface`, `--code-bg`,
`--purple`, `--muted`) and takes `background: var(--surface)` from the frozen value. Custom
properties inherit, so every `var()` inside the diagram resolves correctly with no class enumeration.

- **Freeze every token any `pre.mermaid` rule reads, or the half you miss goes dark on dark**: a
  first attempt froze only the background, so `packet`'s own overrides still resolved `--on-surface`
  to the paper palette, printing dark text on the new dark ground.
- **`print-color-adjust: exact` is load-bearing**, verified by rendering a PDF with backgrounds
  suppressed (the default): without it, backgrounds drop and light text lands on white paper again.
  Pinned by `palette-check.py` alongside `-webkit-` and all five frozen literals.
- **A light-themed diagram needs none of it**: a trailing
  `@media print and (prefers-color-scheme: light)` block `unset`s all five (falling back to the
  inherited paper palette), sitting after `@media print` on purpose since source order, not
  specificity, is what lets it win.

**`pie` paints text directly onto a `--data-*` fill and took two coupled fixes**, both found by
rendering rather than reading tokens. `pieOpacity` is now `1` (Mermaid's 0.7 default composited every
slice toward the card, undoing the ramp's own contrast work). `pieSectionTextColor` is per palette
and inverts (`--surface` in the pale dark ramp, `--on-surface` in the mid-tone light ramp: one value
can't serve both). Both are real `themeVariables` in mermaid 11.17.2; no `!important` was needed.
**Both pie strokes are themed too** (`pieStrokeColor: --surface` so slices separate by a gap not a
line; `pieOuterStrokeColor: --muted` matching every other hairline): Mermaid defaults both to
literal `black`, not a palette color in any mode. **Do not drop either stroke back to Mermaid's
default.**

`samples/dark.html` carries a `pie showData` fence as of v1.40.0; its absence is why the above went
unmeasured for four releases (see [Fixtures are coverage](#fixtures-are-coverage)).

**Nine more diagram types theme correctly with no code change, verified by rendering each against
both palettes and reading `getComputedStyle` on every colored element, not by reading the exported
SVG's own attributes.** That last part matters: a Mermaid element can carry a literal
`fill="#191970"` attribute and still paint the themed color, because an SVG presentation attribute
sits at the bottom of the cascade and any ordinary CSS rule beats it with no `!important` needed.
Reading the attribute string alone would have misreported every one of these as broken.
`classDiagram`, `stateDiagram-v2`, `erDiagram`, `requirementDiagram`, `kanban` and `radar-beta`
resolve every color through `primaryColor`/`primaryBorderColor`/`primaryTextColor`/`lineColor`, the
same four this template already themes for `flowchart` and `sequenceDiagram`. `gitGraph` and
`treemap-beta` looked suspect at first pass (their commit and section colors are not literal hex
matching `mermaid-palette.json`) until a second render with `primaryColor` swapped to a probe red
moved those same colors in step: both derive their palette from `primaryColor` by hue rotation,
so they track this template's purple correctly, they just do not equal one of the pinned hexes.
None of these six carries a fixture yet.

**Mermaid's own `timeline` keyword is a twelfth working type, unrelated to this template's
`dl.timeline` component.** Same keyword, two different things: one is a Mermaid diagram, the other
is HTML this stylesheet themes directly. Confirmed themed the same way as the six above. No
fixture demonstrates it, and the name collision is worth flagging to a generator that greps this
file for "timeline" and finds the wrong hit.

**`gantt` and `architecture-beta` needed one new `themeVariable` each, both confirmed by the same
swap test.** `gantt`'s axis ticks rendered at Mermaid's literal `lightgrey` regardless of theme;
`gridColor` (the token this template already uses for `clusterBorder`/`noteBorderColor`) fixed it.
`architecture-beta`'s connecting lines and group boundary rendered at Mermaid's literal mid-grey;
`archEdgeColor` (the same token as `lineColor`) and `archGroupBorderColor` (the same token as
`clusterBorder`) fixed both. All three are real `themeVariables`, mirrored into
`mermaid-palette.json` like every other hex here. **`gantt`'s `today` marker stays Mermaid's
literal red on purpose:** it is a "you are here" signal, not a category, the same reasoning that
keeps the pie and cluster strokes off any accent this template already assigns a meaning
(see the settled decision on `--data-1..4` above). Setting it would cost a new gamut-clipped
hex for a signal that already reads correctly. `architecture-beta`'s arrowheads were checked and
found not to exist on this diagram's edges at all (no `<marker>` in the render), so
`archEdgeArrowColor` was left out: a `themeVariable` with nothing to paint is a dead declaration,
the same objection that removed a dead `font-family` rule in v1.46.0. Neither diagram carries a
fixture yet.

**`journey`'s task and section fills theme correctly through `fillType0..7`; its actor band and
mood face do not, and are left alone.** The swap test is what told them apart: task and section
color moved with `primaryColor`, the actor band (a fixed seagreen) and the per-task face (a fixed
cornsilk circle with grey eyes and mouth) did not move at all. Both are Mermaid's own literal
colors with no `themeVariable` in front of them, the same defect class as `sankey`/`block`. Left
alone for the same reason `today` was left alone above: a mood face reads as a fixed emotional
scale, not a brand category, and repainting it purple would cost the one piece of information it
carries. No fixture demonstrates `journey`.

**`zenuml` does not render at all, and stays out.** Mermaid ships it as a second package
(`@mermaid-js/mermaid-zenuml`) registered through `mermaid.registerExternalDiagrams`, not inside
the core bundle this template imports. Adding it means a second CDN import and a load-order
dependency against `mermaid.initialize()`, exactly the complexity v1.47.0 removed when ELK moved
into core. Declined on the same cost basis, with no fixture and no demonstrated consumer need.

## Connections-map layout

`body.conn-map` has exactly two sections in order: **(1) Links, (2) Graph.** Above 900px Links sits
left and sticky with the graph right; below 900px they stack.

**Markup order is the layout order; the stylesheet does not reorder.** CSS `order` once reversed
them, so the visual leading column was Links while tab/screen-reader order started in the graph.
**That was a silent breaking change for consumers**: a page emitted with the old order renders with
the graph in the narrow sticky column and nothing errors. Supporting both orders behind
`:has(> .links)` was rejected: two layout paths in a file every consumer inlines verbatim.

**The article sets layout only, never width**: it once broke out of the page container to be wider
than the default layout, so a connections map and an ordinary page never shared a left edge.
`pre.mermaid` broke out a second time. **Both breakouts were deleted, not ported.** The container is
`--page-width`; the SVG renders at natural size; there's nothing to escape to.

**The full-width row is `article > *`, not an allow-list**: an allow-list would let a new direct
child (e.g. a generator-added footer) silently join the two-column flex row instead of spanning it.

**The sticky column has a height ceiling** (`max-height: calc(100vh - 2rem); overflow-y: auto;
overscroll-behavior: contain`): `position: sticky` pins nothing once the element is taller than the
viewport; it silently scrolls with the page instead. **`tabindex="0"` is deliberately not on that
column**: the sideways-scroller rule exists for a `pre`/table/`math` whose overflow holds nothing
focusable; the Links column holds links, and focusing one already scrolls it into view.

### Large maps

The default `flowchart BT` fan-out does not scale past a small map: a 50-node production map measured
`viewBox="0 0 7435 798"`, one rank holding 27 of 50 nodes, a horizontal-scroll wall. **Past roughly
15-20 nodes on one rank, restructure rather than widen:**

**1. Cluster into open subgraphs for visual grouping. Never collapse one a reader must click into.**
`subgraphId@{ view: collapsed }` (Mermaid 11.17) deletes every node inside a cluster from the render,
along with each node's own `click` anchors: disqualified outright for a template that exists to
link out to every item it names. An open subgraph still gives visual structure; it just doesn't
reduce node count (point 4 does that).

**2. Switch a large map to the ELK layout engine.** As of v12.0.0 ELK ships inside core rather than
the separate `@mermaid-js/layout-elk` module this template used to conditionally load: a
`config: { layout: elk }` fence still opts in exactly as before, with nothing left to load
conditionally or race against `mermaid.initialize()` (verified by rendering the explicit-ELK diagram
with no second import present). **ELK is also the default layout for every diagram naming no
`layout` at all**, as of the same release; this template accepts that default (see
[Init config](#mermaid)).

**ELK trades width for height on an unbalanced fan-out: it does not just shrink the diagram.**
Eighteen leaf nodes into one focus node measured `3063 x 174` under dagre vs. `2671 x 324` under ELK:
about 13% narrower, roughly twice as tall. A map already short and wide will read taller under ELK,
not merely narrower.

**ELK clusters ignore `clusterBkg`/`clusterBorder` outright**: isolated against dagre with an
identical subgraph and `theme: 'base'`, ELK hardcodes Mermaid's stock `#ffffde` fill, `#aaaa33`
stroke, `#333` label text regardless of `themeVariables`. Same defect class as `packet`/`xyChart`, so
`tufte-dracula.css` overrides it the same way: `pre.mermaid .cluster rect` and
`pre.mermaid .cluster-label :is(p, span)` with `!important` (Mermaid's injected rule is id-scoped).
Verified by rendered pixels in both dark and forced-light, not by reading the exported SVG's own
`<style>`.

**3. Encode relationship type as line style, once, in a legend, not as a text label on every edge.**
The production map carried 39 edges each labelled `technological`/`conceptual` in its own
`foreignObject`, adding to the width dagre solves for. A `classDef` on two edge classes (solid vs.
`stroke-dasharray`) plus one small unconnected legend subgraph states the distinction once.

**4. Past that node count, split into multiple maps rather than hide any node.** Every node stays
present and clickable on whichever map holds it. The production map's 31 technological vs. 8
conceptual edges read better as two focused maps by relationship type (or by era) than as one map
carrying both past the point either reads clearly. A generator decision, not something the template
enforces, but the recommended default past the threshold above.

## Interaction states

**A transition belongs on the resting rule, and `transform`/`scale` are different properties.** The
`.nav-list li a` press feedback was inert for both reasons: the transition named `scale` while the
rule set `transform`, and it sat inside `:active` where it vanished with the state. Now `scale: 0.96`
in `:active`, transition on the base rule. `.mermaid-zoom` (the sheet's only real `<button>`) takes
the same treatment.

**`[tabindex="0"]:focus-visible` is in the focus rule**: the one stop this sheet doesn't own is the
one consumers are told to add (a focused `pre`/`math`/`.table-scroll` would otherwise fall back to
Chromium's default ring). **No `border-radius` in `:focus-visible`**: it tightened `.filter-box`
corners unevenly at the moment the ring appeared (Chromium already rounds an outline to the
element's own radius). **`.nav-list` radius is `calc(var(--radius-sm) + 0.3rem)`**, not
`var(--radius)`, keeping the outer/inner radii concentric as either changes.

**Every hover rule sits inside `@media (hover: hover)`.** Eight rules didn't, and an unguarded hover
rule doesn't fail to apply on touch: it applies at the wrong time and sticks: the browser sets
`:hover` on tap and leaves it set until the next tap elsewhere (measured with real touch emulation).
**The block's position, immediately before `::selection`, is load-bearing**: a media query adds no
specificity, so placed after `prefers-contrast: more` instead, `.nav-list li a:hover` would tie and
win on source order, stripping that mode's underline from hovered nav links.

**`pre.mermaid:hover` gets an instant, untransitioned 1px ring, for a pointer only**: hover is
high-frequency and doesn't want motion. **Do not describe it as the touch affordance**: a hover rule
fires after the tap, so it can never advertise anything in advance on touch. The injected
`.mermaid-zoom` button is the real touch affordance.

**The View Transitions API was considered for the mermaid overlay and passed over**: cross-document
support isn't Baseline yet, and the existing `opacity` transition already covers the need.

**The overlay's way out is a `✕` glyph on `.mermaid-overlay::after`**: click-anywhere and Escape
already dismiss it, so this is a cue on an already-clickable surface, not a new target. `cursor:
zoom-out` alone is invisible on touch. Glyph rather than a word (untranslatable in a file consumers
inline verbatim), same `content: "✕" / ""` alt-text convention as the outbound arrow.

**Every transition in the sheet is `ease-out`**: the default `ease` leaves the first frame
near-invisible then rushes, reading as late.

## Keyboard and assistive technology

**Zoom is a real `<button>` `mermaid.js` injects, not a focusable `pre`.** Two cheaper fixes were
rejected: `tabindex="0"` + `role="button"` on `pre.mermaid` makes the SVG's content presentational,
hiding its `graphics-document` name; `tabindex="0"` with no role leaves a focusable generic, and
`aria-label` can't name `role=generic`. A native button gets keyboard/pointer support and an
accessible name for free, leaves the SVG untouched, and doubles as the touch affordance `cursor:
zoom-in` could never be.

**The observer that creates the button has to be idempotent**: Mermaid rewrites the `pre`'s children
after first render, so a one-shot guard let the second pass delete the button and then blocked
recreation. It now re-adds the button whenever one is missing, and marks the **SVG** (not the `pre`)
for the click listener.

**The overlay is a native `<dialog>`, opened with `showModal()`**, replacing an earlier hand-rolled
`<div>` (`role="dialog"`, `aria-modal`, manual focus, manual `inert` toggling, a guarded document-level
Escape listener). `showModal()` provides all of it natively: implicit role/`aria-modal`, the rest of
the page excluded from focus/a11y tree with no sibling touched, focus moves in automatically, Escape
closes via the browser's own `cancel` event. `aria-label` still needs setting by hand (a `<dialog>`
has no accessible name of its own).

**Close runs through one `hide()`**, called from both a `click` listener on the overlay and a
`cancel` listener that calls `preventDefault()` first, so the same cleanup runs either way (drop the
`active` class, call `overlay.close()`, empty its `innerHTML`). `close()` runs synchronously rather
than deferred to `transitionend`, since a transition that never completes would otherwise leave the
dialog open forever with no cleanup. **The trade: the overlay fades in but does not fade out**: `showModal()`'s top-layer removal is synchronous, and a removed property can't transition. Not
pursued via `@starting-style`/`transition-behavior: allow-discrete`, since a dismissal a reader asked
for isn't a state worth watching happen. **Focus returns to the opening button for free** via
`close()`'s native restore.

**The zoom button is named from the diagram (`accTitle` → SVG `<title>`), not a hardcoded constant**: a page with several diagrams would otherwise get several identically named buttons. `aria-label` is
`label + ': ' + title`; the overlay takes the same name on open.

**The `pre` region is named for what the container IS, not for the diagram inside it**
(`window.mermaidRegionLabel || 'Scrollable diagram'`): it used to take the bare title, which the SVG
already exposes as its own `graphics-document` name, so a screen reader read the diagram title, the
word "region", and the diagram title again. **The trade: several regions on one page now share a
name** where each was once unique: weighed deliberately, since the duplication cost was paid on
every entry into every diagram, while the shared-name cost only hits a reader browsing a region list
below 600px, one step before a uniquely named diagram. **Do not "fix" this by putting the title back
in the label.**

**`pre.mermaid` is a labelled region only at widths where it can actually scroll**, answering two
defects at once: `mermaid.js` used to set the tab stop unconditionally, so above 600px (measured
`scrollWidth == clientWidth` on every fixture diagram) every diagram was a tab stop with nothing to
scroll, carrying the duplicate-name `aria-label` above too. Two cheaper alternatives (a second
invented English string; a focusable generic) were declined for the reasons already stated above.
`mermaid.js` matches `window.matchMedia('(max-width: 600px)')` and syncs `tabindex`/`role`/
`aria-label` on `change`: verified by driving a real resize (region absent at 1440px, present at
400px, absent again returning), and swept at 1440/1000/700/601/600/400px confirming no diagram above
the breakpoint both scrolls and lacks a region. **`matchMedia` is now permitted in `mermaid.js`,
`prefers-color-scheme` is not**: the real prohibition was always reading the host's appearance
instead of the cascade. **The breakpoint is pinned in both files** (stylesheet and `mermaid.js`
separately); a move on one side alone is invisible in a render of the other.

`window.mermaidZoomLabel`/`mermaidRegionLabel` override the two label words, following the
`mermaidSecurityLevel` convention (all three are hardcoded English in a file consumers inline
verbatim). **`accTitle`/`accDescr` are consumer obligations**: fence directives no stylesheet change
can supply; without them the SVG is a `graphics-document` with no accessible name.

**The sidenote margin-toggle checkbox is inert by design, and its `display: none` rules must stay**: `.sidenote` is `display: block` at every width, so the Tufte collapse pattern does nothing here, but
consumer generators still emit that markup and dropping the rules would show raw checkboxes on every
page.

**`math[display="block"]` takes `tabindex="0"`, `role="region"`, and a label**: it's a scroll
container like `pre` (own `overflow-x: auto`), and `role="region"` costs nothing here since Chrome
exposes no native `math` role either way.

## Direction, zoom and growth

**Sidenotes float to the inline end, with the physical value first as fallback**: `float: right;
float: inline-end; clear: right; clear: inline-end`: a browser that can't parse `inline-end` drops
that line and keeps LTR behavior. `margin` is `margin-block`/`margin-inline` for the same reason.

**`th`/`td` are `text-align: start`, not `left`** (`.num` uses `end`), or cells stay left-aligned in
RTL while the surrounding prose flips. **`h1`/`h2`/`h3` carry `overflow-wrap: break-word`**: the
only text in the sheet without a break rule, so a long title word ran off the page under text-only
zoom.

**`--gutter` folds safe-area insets at every width, not only under 600px**: a landscape phone is
wider than the mobile breakpoint yet still has lateral insets larger than the desktop gutter, so text
ran under the notch without this. **The `0px` `env()` fallbacks are load-bearing**: without them, a
browser with no support makes the whole custom property invalid at computed-value time, taking the
`width: min(...)` calc down with it. Not verified on real hardware (Chromium doesn't emulate insets).

**A container query fixes `.scorecard` overflow under text-only zoom; a media query cannot**: `em`
inside a container query resolves against the container's own font size (correctly asking "is text
large relative to space"), where a media query's `em` resolves against the browser's initial size and
sees nothing at a doubled root. Two things about it are load-bearing: the `:has()` scoping (plain
`container-type: inline-size` on every `section` would also shrink the conn-map sticky sidebar at
zoom), and its position after the `max-width: 600px` block (container queries add no specificity, so
source order decides).

Two earlier attempts failed: `minmax(0, max-content)` tracks let a track shrink to zero without the
`.verdict` chip shrinking with it (chip spilled out); `auto` tracks plus `overflow-wrap: break-word`
fixed only one width, since **`break-word` does not reduce a box's min-content contribution, and
`anywhere` does.**

**At 400% text-only zoom the page still scrolls sideways**: past what WCAG 1.4.4 asks for, and
nobody chases it further.

## Cascade layer

**The whole sheet sits in one layer, `@layer tufte-dracula`.** Before it, a consumer override had to
win on specificity against syntax-highlight groups at `0,2,0`. **Unlayered author styles beat every
layered author style for normal declarations, whatever the specificity**: a consumer's plain
`h1 { color: … }` now wins with nothing here needing to move.

**The `!important` declarations became harder to override, not easier: that's the trade.** In the
important half of the cascade the layer order reverses, so every `!important` here beats a consumer's
unlayered `!important`. A consumer who genuinely needs to win declares their own layer ahead of this
one. Lifting those rules outside the layer was rejected (two sit inside a media query, meaning
duplicated `@media` blocks).

They fall in three groups: **six fight Mermaid**, which nothing else can reach (four fight its
id-scoped injected stylesheet: `packet`, `cluster` fill/label; two fight its inline `style`
attributes: conn-map and narrow-viewport svg sizing); **`.filter-hidden { display: none !important }`**
(a consumer override there means a filtered row stays on the page); **the `prefers-reduced-motion`
reset** (has to beat every transition/animation the sheet declares).

**One layer, not four** (`@layer reset, base, components, utilities`): that convention is for a
stylesheet a consumer composes from parts and can reorder; this is one file, inlined verbatim, in a
fixed order.

**Do not re-indent the sheet body.** The wrapper opens on line 3 and closes before `</style>`; a
re-indent rewrites every line, putting `git blame` on the whole stylesheet at one commit, breaking the
trace from a declaration to the change that made it look that way. `scripts/build-sample.nu` also
slices `:root` with a hard-coded `^    ` de-indent.

**`:is()`/`:not()` both take the highest specificity of their arguments**: `:is(ul, ol, menu):not(.nav-list)` scored a class weight from a class it never matches, silently
outranking the nested-list rule below it. The `:where()` form scores zero on both sides. **Check the
specificity of a negation before trusting source order.** The other `:is()` groups stay (the layer
already gives consumers an override, and two would break if lowered: syntax-highlight groups must
beat a loaded highlighter theme, the permalink group must beat the plain `a` rule).

## Appearance modes

**`@media (prefers-contrast: more)` reassigns tokens, not elements**: raises every accent to the
mode's 7:1 floor against `--code-bg` (the harder ground); `--surface-alt` *darkens* there (its job as
row-hover/tinted-root fill is to be unmistakable). `a` takes a thicker `currentColor` underline, and
the focus ring widens. **`.nav-list li a` repeats the underline declaration**: a media query adds no
specificity, so without the repeat the base `.nav-list li a` rule outranked the mode's `a` rule,
leaving every nav link underline-free in the one mode built for the strongest cue. `mark` does not
reach the mode's floor (the `--highlight` alpha wash caps what the composite can reach, and lowering
alpha would defeat the highlight's purpose).

**`@media (prefers-color-scheme: light)` is a full second screen palette, not the print palette**: reusing print fails on screen for three reasons: `--surface`/`--surface-alt` are both pure white
there (killing row hover and the overlay backdrop), `--code-bg` is a paper compromise, and the
accents are tuned against white rather than a light code fill. In light mode `--surface-alt` is
*darker* than `--surface` (row hover reads like dark mode); `.verdict` keeps its filled form (no
print-style outline needed); `--purple-bright` inverts to `calc(l - 0.06)` (brighter is less contrast
on a light ground).

**Mermaid follows the media query by reading a CSS token, never `matchMedia`.** `:root` declares
`--mermaid-scheme: dark`, the light block overrides it. **`matchMedia` reads the host; the token
reads the cascade**: the forced-light preview pages only work because they rewrite the `@media`
condition, which `matchMedia` can't see but a computed custom property resolves correctly. A deleted
token used to fail silently (`getPropertyValue` on a missing property returns `''`, not `'light'`);
check 6 now asserts all four: `:root` declares `dark`, the light block declares `light`, `mermaid.js`
reads the token by name, and `mermaid.js` does **not** read `matchMedia`.

**The dark-island design (light mode handing `pre.mermaid` the dark palette back as inherited custom
properties) was tried and removed**: it looked fine but was wrong three ways: a dark slab beside a
light sidebar reads as broken; the card-width fix needed a `width: fit-content` that clipped
`quadrantChart` and collapsed self-sizing SVGs; the re-declared palette was a third `:root` projection
needing its own gate. **The net change after deleting it is fewer rules than before it existed.**

**A scheme flip with no reload leaves the diagram stale**: the token is read once, at init; a live
re-theme means a re-init, a re-render from source, and a fresh `MutationObserver` race. **An in-page
toggle was asked for and refused**: the fixtures carry exactly one `<style>` and two `<script>`
blocks, both gated, so a toggle would need a second theming convention or a fourth inlined script.
Take it only as a deliberate public-API decision if a consumer asks for a manual override as a
feature.

**Two generated preview pages carry the light palette to the web instead**, rewriting the light
condition to `@media all` and the contrast condition to `@media not all` (forcing light alone isn't
enough: it would leave the contrast block's non-token rules live). **The generator raises when the
rewrite no-ops**, or Pages would serve a dark page called light while regeneration still compares
clean. **Do not remove the light-preview banner to tidy it**: the filename no longer carries the
warning, so the `markdown-alert-caution` block, the `CONTRACT.md` § 1 statement, and the pages'
deliberate exclusion from the contract-files list are what's left to carry it. **Nothing outside this
repo should pin a page whose media queries were rewritten.**

**There is no high-contrast preview page**: that mode leaves `--surface` alone, so a forced page
would look almost like the dark sample and teach nothing; CI renders it and attaches the image to the
PR instead.

**Two gates cover the modes, covering different halves, neither a screenshot diff** (layout is
identical across modes, only color moves). `.github/palette-check.py` check 5 re-derives the contrast
floor for all four palettes on every run, overlaying each mode block's overrides on the default
palette the way the cascade actually resolves it. `.github/render-modes.py` covers that the palette
**arrives**: **headless Chrome cannot be told which media query to match** (`--force-dark-mode` etc.
all leave the OS's own result unchanged), so each render rewrites **every** mode condition in a
scratch copy, the target becoming `@media all` and the rest `@media not all`. **Neutralizing the
other conditions is the load-bearing half**: its absence failed CI on the first attempt (a
dark-appearance mac measured its own light-runner result as correct). The pixel read needs no image
library: for the first pixel of PNG row 0, every filter type predicts from an all-zero left/above
byte, so the filtered byte is the raw byte. Renders are **advisory on purpose**, not in
`REQUIRED_CHECKS`: the assertions are the gate, the images are for a person to look at.

**`light-dark()` was considered for the mode swap and passed over**: each mode redeclares roughly
fifteen tokens in one `:root` block; `light-dark()` sets one declaration at a time from two values,
meaning fifteen inline calls instead of one block to keep in step.

**High contrast and light mode do not compose, and the ordering is deliberate**:
`prefers-contrast: more` is declared *before* the light block, so a reader asking for both gets the
light palette at its own floor rather than a fourth, never-built high-contrast-light palette. **The
failure mode of a wrong order is much worse: dark high-contrast accents on a white surface. Do not
reorder the two blocks.**

## Print

**The print block overrides palette tokens, not elements**: `background`/`color` on `body` alone
would leave every accent at its dark value on white, breaking both print paths (near-black text on
dark fills with backgrounds on; light text stranded on white with them off, Chrome's default).

**Accent lightness is chosen against the print `--code-bg` gray, not white** (the harder ground).
`--surface-alt` goes pure white too (only the overlay backdrop, never simultaneously on screen and
paper).

**`.table-scroll` releases its cap on paper** (`max-height: none; overflow: visible`): a scrollport
is a screen affordance; on paper it's a guillotine with no mark that content is missing. The existing
`tr { break-inside: avoid }` and `thead { display: table-header-group }` carry the released table
across pages. The fixture's wrapped table is twenty-four rows, not three, to actually exercise this.

**Page breaks**: `p` takes `orphans: 2; widows: 2`; headings take `break-after: avoid`;
`break-inside: avoid` covers `tr`, `blockquote`, `aside`, `details`, `.scorecard`, `.verdict`, `img`,
`.markdown-alert`, `pre`, `dl.timeline > dd`, `math[display="block"]`; `thead` takes
`display: table-header-group`.

**`pre` belongs in that `break-inside: avoid` list**: the worry that it would be "ignored or
overflow" on a block longer than a page was wrong: a fence that fits moves whole to the next page
with its heading; one that can't fit splits with nothing lost, reprinting its fill and accent bar on
every fragment. **That's the standard resolution, and it's the behavior you want.**

**`.verdict` prints as an outlined label**, moving its semantic color to `color` (its fill carried
the meaning, invisible with backgrounds off). `.badge` needs no print rule: already an outlined
`--label` chip, and print reassigns `--label` for it automatically.

## Filter

`filter.js` is the third inlined payload. Three load-bearing decisions:

- **The scope is the sibling span, not the parent.** From the input, walk forward over siblings,
  stopping at the next `input.filter-box` or the end; within that span filter `tbody tr` and
  `.nav-list > li`. **No `closest()`, no id-matching**: the script never needs a consumer's ids, and
  a stop at the next filter box is predictable with no read of the source.
- **The script creates the empty line rather than requiring it**, starting `hidden` (`.filter-empty`
  has no `display` of its own). **It names no query on purpose**: an interpolated string would put
  untranslatable template text in a payload consumers inline verbatim.
- **No CDN, no build step, no comments.** The whole handler is `querySelectorAll` plus
  `classList.toggle`.

**The one-table scope was reversed from an earlier one-input-one-table-one-listener rule, and the
reversal is deliberate**: the fixture's own filter box was inert for six releases under the old rule,
and the largest generator of these pages hand-maintained its own 41-line replacement rather than
inherit a fix scoped too narrow to reach its markup. **A shipped contract file with no reachable user
is worse than no file.**

The script captures `details.nav-group` open state (and `summary .count`) once at bind time and
restores both when the query clears: a group the script opened during a search must not read as one
the reader opened, and **the authored count, not a recomputed `rows.length`, is what's restored**
(the number a generator wrote is a claim about the group, not necessarily a row count; restoring the
authored text avoids the page stating two different, disagreeing numbers).

**The `[role="status"]` line takes a register**: `.filter-box ~ [role="status"]` styles it at body
weight on `--on-surface`, matching every other filter-chrome piece. **The selector stays a sibling
combinator on purpose**: `filter.js` finds the element via `input.parentElement.querySelector`,
wider than any CSS selector could be without claiming every `[role="status"]` on a consumer's page;
the narrower CSS rule styles only the shape `CONTRACT.md` § 6 documents.

`.filter-box` is `font-size: 1em`. **Do not write a `pt` floor here**: 16pt is not 16px, and the
iOS-zoom threshold is 12pt.

## Nav link separators

`nav > a + a` takes a `border-inline-start` plus symmetric padding: without it, sibling `<a>`
children in a `<nav>` render as an undifferentiated run of link text.

**The wrapped-line separator is a known artefact, accepted.** A link beginning a wrapped line carries
a separator with nothing to its left. **No pure-CSS rule can suppress a border at a line break** (the
wrap position isn't addressable from a selector, and flex wrapping just moves the problem). The
alternatives (a dangling pseudo-element glyph, or no separators at all) were both worse. The fixture
carries enough links to wrap at a phone width so the artefact stays visible.

## Version stamps are not version history

**`scripts/maintain.nu bump` rewrites three anchored stamps and nothing else**: the stylesheet header
comment, the `(template vX.Y.Z, oklch palette)` cell, the `is **vX.Y.Z**` line. A blanket
find-and-replace across `README.md` once walked historical claims forward too, crediting the wrong
release on every bump for prose like "raw HTML is covered as of vX.Y.Z". **Each pattern must match,
or the bump fails**: a loud failure beats a silent no-op that leaves the tree claiming the previous
version while the release process believes it stamped. `CONTRACT.md`'s per-version delta table is the
same shape of risk; a blanket replace would rewrite every row of it.

## Unclaimed elements

**An element the sheet doesn't claim renders in whatever the UA decided**, usually a light-mode
default that survives a dark theme (`mark` came out pure yellow on pure black, `caption` centered
itself, `figcaption` read as an ordinary paragraph, `figure` had no margins at all since the `*`
reset ate the UA's).

**`mark` is a wash, not a chip**: `--highlight` is `--orange` at a tuned alpha, and body copy on it
still clears the text floor with headroom (a higher alpha would read as a chip and cost contrast).
`mark` pins `color: var(--on-surface)` rather than inheriting, since it renders inside `--label`
containers where every other tier fails on the wash. Print inverts it to an outline, the same move as
`.verdict`.

**`kbd` is a ringed chip, deliberately not `code`**: same fill and mono face, but `--on-surface`
text (not `--green`) and a `--rule` ring (not `--rule-light`, since it sits on `--code-bg`). A second
shadow layer (`0 1px 0 var(--rule)` outside the ring, borrowed from factory.strongdm.ai's keycap)
reads as a raised edge. Joins the forced-colors border list (an inset shadow is its only boundary).

**A `caption` sits above the table's frame, not inside it**: `table:has(caption)` drops the top rule,
or the table's own top rule paints above the caption and it reads as a stray first row.
**`figcaption` sets `text-align: start` explicitly**: `pre.mermaid` is centered, and an inheriting
caption would float mid-column.

## Markdown coverage

The sheet was written for hand-authored markup; a consumer can also point a markdown converter at it.
Every construct a converter emits lands in a theme register with **no classes of its own**. **Do not
invent classes for markdown constructs.**

**`h4`-`h6` all sit at `1em`**; weight (600/500/500) and color (`--label` then `--muted`, h6 also
italic) carry the tier, since the `*` reset ate UA margins while the UA font-size ramp survived
(a sixth-level heading would otherwise render smaller and heavier than body copy, the exact inverse
of the type scale). **Weight 450 was rejected for h5/h6**: it ties body copy and pushes the same
problem one tier down.

**A presentational attribute loses to author CSS**: `td { text-align: start }` silently beat
`<td align="right">`, so three `[align]` rules fix pipe-table alignment (inline
`style="text-align:…"`, which pandoc emits, already won on its own).

**GFM alerts take the `aside` rule rather than a second callout form**: an alert *is* an aside. The
hue lands on the bar and `.markdown-alert-title`, never body text; `warning` keeps plain `aside`
orange so alert-free and alert-heavy documents read the same. GitHub's octicon is `fill: currentColor`
and takes the hue for free.

**Highlighted code reuses the Rider slot map rather than invents one**: keywords `--pink`, strings
`--green`, numbers/parameters `--orange`, comments `--muted` italic, functions `--link`, types
`--purple-bright`, fields/attributes `--label`, errors/deletions `--red`, punctuation inherits. One
grouped selector per role covers `highlight.js`, pandoc/skylighting, Prism, Pygments, **all scoped
under `:is(pre, code)`** since the pandoc/Pygments classes are one and two letters that would
otherwise repaint a consumer's own markup. **One known, accepted collision**: `.ch` is pandoc's
`Char` in the string group and Pygments' `Comment.Hashbang`, so a shebang renders in the string tier: cheaper than a second selector set.

**Types take `--purple-bright`, and print inverts the lift back to plain `--purple`**: plain
`--purple` is the one ratio the contrast budget records as a failure on `--code-bg` ("nothing puts
purple text on the gray"), but a syntax slot map does exactly that; `--purple-bright` is the same
`oklch(from var(--purple) calc(l + 0.07) c h)` lift `scripts/create-themes.nu` already calls
`bright`, needing no new hex. Print redeclares plain `--purple` since more lightness is less contrast
on light ground.

**Monospace was inheriting italic from `blockquote`/`th`/`summary`**: one rule resets `code`, `pre`,
`kbd`, `samp` inside those three (and `h2`/`h6` for the same reason).

**`color-scheme: dark` on `:root` is not cosmetic**: without it a UA form control renders light-mode
inside a dark page. Print sets `color-scheme: light`.

**The task-list checkbox stays native and gray when checked**: GFM emits it `disabled`, and Chromium
ignores `accent-color` on a disabled control; a repaint would mean a literal hex data-URI SVG with
nothing to gate its drift and unreliable pseudo-elements in Safari. **A read-only checkbox that reads
as read-only is the cheaper answer.** `list-style` drops through
`li:has(input[type="checkbox"]:first-child)` rather than GFM's own class, so it holds for
`markdown-it` output too.

**Five smaller claims**: `del`/`s` drop to `--muted` (full body color would read as emphasis); `samp`
takes `--mono-font`; `sub`/`sup` take `line-height: 0` (a footnote ref shouldn't open its line);
`abbr[title]` gets a dotted rule and `cursor: help`; `img.emoji` loses the `--ring` outline (that's
for figures) and takes `1.1em`.

**Footnotes land in `:is(.footnotes, .footnote)` behind a hairline at the caption tier**, matching
`cmark-gfm`, pandoc, and Python-Markdown's shapes, dropping the duplicate leading `<hr>`. The Tufte
`.sidenote` apparatus is separate and still needs hand-authored markup.

**`.footnote-backref` needs an `aria-label`**: the one accessible-name requirement this repo asks of
converter output, not just hand-authored markup, since `cmark-gfm`/pandoc emit it as a bare `&#8617;`
glyph a screen reader can't name. This is the opposite fix from the outbound-arrow (which was
silenced because it's decorative): a backref is a real functional control, so it gets a name rather
than losing one. `CONTRACT.md` § 2 states it as a generator obligation, numbered per footnote.

**The sheet styles math where it arrives as real HTML; it renders none.** An unstyled
`<math display="block">` overflows the page (same failure as a wide table, same two-rule fix: its own
scroll axis plus `pre`'s margin rhythm). `.math.display` covers both the pandoc `--mathml` span and a
KaTeX box. **A font-size bump was built and dropped**: the math font's x-height already matches the
body serif, and a bump would re-scale math inside `h3`/`td` too.

**TeX is not rendered**: KaTeX/MathJax would be a second hard-offline dependency (Mermaid's kind)
for a construct that may never appear; the sheet styles the containers so a consumer adding KaTeX
gets block layout free.

**Chroma was declined on a namespace argument that turned out to silently exclude Pygments.** Hugo
defaults `noClasses = true` (inline color, mostly moot), but Pygments emits classes by default and is
the highlighter behind Sphinx, MkDocs, Quarto, `nbconvert`. Chroma copies Pygments' class names, so
the same selectors already cover consumers who turn `noClasses` off.

## Raw HTML and other generators

Every converter passes raw HTML through untouched.

**Intrinsic-width media pushes the document sideways, and `img` was the only element claimed.**
`:is(svg, video, canvas, iframe, object, embed) { max-width: 100% }` fixes the same 1.4.10 failure
the MathML block had. **No `height: auto` on that rule, deliberately**: an SVG with a viewBox
preserves its own ratio, and adding it would put a second sizing input on `pre.mermaid svg`, where
three earlier attempts were correct on paper and wrong on screen. **`svg` is in that selector only
because a fixture diff proved it inert against mermaid**: `pre.mermaid svg` already carries its own
`max-width` at higher specificity in every band that matters.

**`body` takes `overflow-wrap: break-word`, not a list of nine selectors**: one declaration inherits
to every prose container, including ones a hand list would forget, at no layout cost (`break-word`
doesn't reduce min-content contribution).

**`position: sticky` is scoped to `thead th`**: unscoped, a `tfoot` header cell would pin to the top
too (a totals row stuck in the header's place).

**Permalink anchors reveal on hover, and the `:focus-visible` half is not optional.** Sphinx, MkDocs
and markdown-it-anchor emit them visible by default; `opacity: 0` hides them, lifting on `:hover` of
the heading **and** `:focus-visible` of the link: without the focus half, the link stays in tab
order while invisible, a keyboard stop nobody can see.

**Form controls take `font: inherit` and a `1rem` floor, nothing else**: `.filter-box` was the only
control that set a family; every other one fell to a small sans-serif below the iOS Safari zoom
threshold. **Appearance is deliberately not styled**: a focus ring, hover, disabled and pressed state
is a button design this document theme (one control) doesn't need. `color-scheme: dark` already
themes the UA widgets dark.

**Three conventions stay unclaimed, reasons worth keeping**: non-GFM callouts (`.admonition`,
`.callout-*`, `.admonitionblock`) render bare: Asciidoctor's is worse, rendering as a `<table>` that
inherits the sheet's sticky header; against three more names for a role the sheet already paints
twice, revisit only when a consumer actually runs Sphinx/MkDocs. Jupyter ANSI output: sixteen names
onto seven accents is a set of choices, not a translation, and the intense variants have nowhere
sensible to land (the `.dataframe` table pandas emits already inherits table rules). `address` and
`.tabbed-set`: `address` keeps UA italic (arguably right for a postal block); `.tabbed-set` shows
every panel at once, and a fix means a claim on a radio-driven widget rather than one rule.

**A solid underline means a link; a dotted underline means an annotation.** `ins`/`u` took the UA
underline at body color (the one mark this theme uses for a link), so track-changes markup read as
clickable. Both now use the dotted form `abbr[title]` already uses.

**`menu` joins all three list rules** (takes `list-item` children): without the indent rule the `*`
reset left its markers hanging outside the box.

**The zero-user class families stay**: `scorecard`, `edge-list`, `col-2`, `badge`, `newthought`,
`sidenote`, `marginnote`, the filter family, `body.conn-map` have no documents in the measured lode,
which measures the generator as much as the stylesheet: a generator that never offers a component
guarantees no document uses it. **`sidenote`/`marginnote` are the Tufte signature and the reason the
layout reserves a right margin at all**; the zero there is a generator gap, not a design failure.

**`.verdict`/`.scorecard` had the same generator gap, undocumented rather than merely unused**: a
real proof-test page rendered every verdict as bare text, since `CONTRACT.md` had never listed the
markup for a generator to discover. Fixed by adding it (`CONTRACT.md` § 2, v1.31.0 row of § 3).

**`.verdict` was missing `display: inline-block`, and `min-width` had been silently dead outside
`.scorecard`'s grid the whole time**: a grid item's computed `display` blockifies regardless of the
rule's own declaration, so `min-width: 5.2ch` only ever held inside `.scorecard`; `min-width` doesn't
apply to a non-replaced inline box at all, per spec, so the same class on a bare `<span>` elsewhere
had no floor under it. No fixture ever put `.verdict` outside `.scorecard`, so nothing caught it; a
short word like `N/A` happened to clear the floor on its own padding, producing an inconsistent
badge rather than a visibly broken one.

## Fixtures are coverage

**A fixture demonstrates states. It does not simulate them.** Several details that look like filler
are regression checks. **A cut to any of these retires the check it exists to be.**

**A fixture is also the copy consumers paste, so its own strings have to be right.** Two weren't:
`.filter-empty` must not state a count (the fixture once said "Clear the filter to see all 4", wrong
for any other list length, and `filter.js` only writes its own copy when the element is absent: so
whatever's in the fixture is what ships and gets copied); `.verdict` text is written in sentence case
(the class already carries `text-transform: uppercase`, so `PASS`/`SEE BELOW` baked presentation into
copy).

**A new page means five hardcoded fixture lists, not one**: the page list in
`scripts/build-sample.nu`; the presence, style-and-script-count, and light-preview lists in
`scripts/maintain.nu`; the staleness list there plus `FIXTURES` in `.github/render-modes.py`. **Miss
the `render-modes.py` one and the new page renders in no appearance mode while `check` still prints
`Contract OK`**: that list drives the image count rather than deriving from the directory (four
fixtures times three modes is twelve images, the tell).

Specific fixture details and what they catch: `samples/dark-timeline.html`'s length is the point (four
era groups exercise `--timeline-date`'s multi-list case; citation density is where floated sidenotes
fail; the enlarged marker hit area and `:target` outline were measured against it). The sequence
diagram and quadrant chart sit beside the flowchart because a flowchart shows neither
label-measurement bug (its labels are browser-measured `foreignObject` HTML). The `pie` fence is the
only one putting text on a `--data-*` fill (its absence hid two real contrast defects for four
releases) and the only one depending on a non-color `themeVariable`. `samples/dark-charts.html`
carries both bar tables (no other coverage exists for `table.bar-chart`, and its background-image
band is exactly what print/forced-colors take away) plus a Mermaid pie of the same numbers, so the
CSS-chart-vs-pie guidance is checkable by eye. The conn-map focus node's long label is the only place
a mis-sized node box lands in a *constrained* column. The filter's `role="status"` and
`.filter-empty` lines are the only reference copy for both: **nothing hand-written into a fixture
may restate a runtime value the reader controls** (a count can be checked against the page; a quoted
query cannot). The wide `.table-scroll` table is the only instance of that wrapper (eight columns,
twenty-four rows, deliberately past both the sideways-scroll and `70vh` thresholds). The highlighted
code block carries real `highlight.js` emitter classes (the only check the Rider slot map still
matches, and the only place `--purple-bright` renders); the Pygments block beside it is the only
check on the one/two-letter half of the slot map. The MathML block proves `math[display="block"]` is
claimed at all.

### Never cite a line number into a generated file

`CONTRACT.md` § 2 once pointed a consumer's generator at fixture line numbers, and **all 22 were
wrong, already wrong at v1.38.1**: a fixture regenerates on every payload edit, so a line number
rots on a change unrelated to the requirement it names, and nothing could see it happen. Renumbering
was rejected (resets the same clock, needs a machine-readable token to gate at all, which is the
whole cost of the real fix). **Each pointer is now a search string** instead:
``(in `samples/dark.html`, search `class="tag-dot"`)``, parsed and verified by
`nu scripts/maintain.nu check`, which refuses to pass on fewer than 20 pointers so a bulk delete can't
make the gate vacuous.

**§ 2 also made two countable claims about itself that had gone false**: that every requirement
points at a fixture or says it has none (five bullets did neither), and its own bullet count stated
in prose (read "Sixteen" against 21 bullets before v1.39.0, with `README.md` carrying its own stale
copy). Both are now derived from the bullets rather than trusted. **A prose claim about a countable
property is a gate waiting to be written.**

**Both the pointer gate and the fixture table-tab-stop scan were local-only for a while, which
doesn't hold a merge.** Both are now one function, `contract-markup-ok`, called from `check` and from
a `main contract-markup` CI subcommand.

**The fixture breaks exactly one § 2 requirement on purpose, and that had to be said out loud**: `samples/dark.html` carries two deliberately overlong `quadrantChart` point labels that § 2 otherwise
bans, since `CONTRACT.md` tells a generator the fixture wins any disagreement. The exception is now
named in both the intro and the bullet.

### The one check that runs the payload

`.github/script-probe.py` loads `samples/dark.html` in headless Chrome, drives both inlined scripts,
and asserts what a reader would see (eighteen assertions over `filter.js` scope/counts/group-state,
`mermaid.js` rendering/zoom-binding/conditional-region, plus eight over the forced-colors block).
Everything else in CI counts blocks, compares bytes, or measures colors: **none of that asks "does
this handler attach to anything."** Two real defects proved the gap: the fixture shipped an inert
`input.filter-box` for five releases, and a diagram click opened nothing for several more (see
[Zoom](#mermaid)).

**It needs no new dependency**: reuses `render-modes.py`'s same headless Chrome binary with
`--dump-dom` instead of `--screenshot`, a driver script appended to a scratch copy writing results
into the DOM for a one-regex readback (this sat in `backlog.md` for releases on a stated Node/jsdom
cost that was never actually required). **The mermaid half is network-dependent and says so out
loud**: the pinned CDN is probed for reachability first and reported as a `SKIP`, never folded into
a pass. **It refuses to pass on fewer than 13 binding assertions and 8 forced-colors ones**, and both
halves were mutation-tested (moving `filter.js`'s scope walk up one level, and making the mermaid
region unconditional, each turned the gate red on the exact assertion naming them).

## Repo layout

**The Nushell scripts live in `scripts/`, Python helpers stay in `.github/`: split by who invokes a
file, not by language.** Each Python helper is a CI step appearing verbatim in `contract-check.yml`
and lives beside it; the Nushell scripts are commands a person types.

**Both kinds resolve every path from the repo root, never `cwd`.** Nushell needs two constants,
since `path self | path dirname | path dirname` is not a legal const chain:

```nu
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname
```

**`AGENTS.md` is the instruction file; `CLAUDE.md` is a pointer to it, split by audience not
content.** The rules used to live in `CLAUDE.md`, which made a filename a dependency (another
harness reading `AGENTS.md` would have found nothing). `AGENTS.md` holds every rule and names no
harness; `CLAUDE.md` records only what Claude Code adds on top (the skills in `.claude/skills/`) and
states `AGENTS.md` wins on conflict. **A skill may only wrap a flow `AGENTS.md` already states in
full**: that's what keeps a harness without skills at full capability, losing an entry point, never
a rule. **Do not let a rule come to rest only inside a skill**, and don't put repo policy in
`.claude/settings.json` (status line config only). Both files sit in the presence gate
(`scripts/maintain.nu` and `contract-check.yml`): a deleted instruction file is the one deletion that
leaves every check green while removing the reason the checks exist.

**Python stays in the two `.github/` helpers, measured rather than argued.** Bash is not a real
alternative (no floating-point arithmetic; the Oklab matrix needs `cos`/`sin`/fractional powers, so a
bash version would really be an awk program in a shell wrapper, trading Python for a less readable
language). Nushell would genuinely drop a language for `palette-check.py` (the math ports exactly),
but it's two hundred lines of the most load-bearing check in the repo, rewritten only to save an
already-preinstalled dependency: **take it if the check needs a substantial change for its own
reasons, not on its own.** `render-modes.py` cannot move at all: reading one PNG pixel needs zlib
inflate, which neither Nushell nor bash has, and the gzip-header inflate workaround always fails its
trailer (a zlib adler32 isn't a gzip crc32), forcing the check to ignore its own exit status: exactly
the quiet wrongness the gate exists to catch.

## Odds and ends

**A shadow-drawn rule on a zero-height box paints nothing.** `hr` read `border: none; box-shadow: …`,
and `border: none` collapses the element to zero height, making the separator invisible at every
width, in print, and in forced colors. Now a `border-block-start`. **Shadow-drawn rules are fine.
Shadow-drawn rules on a zero-height box are not.**

**A pipe-separated `nav` is a flex row, and the rule goes on the link, not between the links**: `nav:has(> a)` takes `display: flex; flex-wrap: wrap`, `nav > a + a` carries the border. As plain
inline anchors, a long destination name broke *inside* the link across lines, splitting labels with
no separator between the halves; a flex item wraps as a unit and carries its leading rule with it.
**The `:has(> a)` scoping is deliberate**: a bare `nav { display: flex }` would also catch a
consumer's `nav > ul`, silently turning it into a shrinking flex item.

**`scrollbar-color` sits on `body`, not on every scrolling box**, since the property inherits: one
declaration reaches `.table-scroll`, `pre`, the narrow-viewport mermaid scroll, and the document
scrollbar. **`overscroll-behavior: contain` goes on every scroll container the sheet owns**
(`.table-scroll`, the mermaid overlay, narrow-viewport `pre.mermaid`, the conn-map sticky column), or
a scroll to an edge chains into the page behind it.

**`--ring` is a token because the `img` hairline was the one color declared twice as a literal**: as a token it flips in print with the other overrides. Deliberately not a palette color (white at
10% over an arbitrary image is a translucent veil, not a hue), so its alpha-slash form doesn't match
`palette-check.py`'s token regex, leaving the parsed token count unaffected.

**The W3C CSS validator reports two errors, and both are the validator**: it flags `container-type`
and `@container` (a module its `css3` profile predates), which are the load-bearing `.scorecard`
zoom fix. **Do not delete them to make the validator quiet**: that trades a real rendering bug for a
green badge.
