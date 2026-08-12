# NOTES.md: why the stylesheet looks like this

Every generated HTML file carries `tufte-dracula.css`, `mermaid.js` and `filter.js` verbatim,
so those files carry no comments (see `CLAUDE.md`). This file holds the reasoning that used to
live in them. **Chromium measured every number below. Nobody reasoned one out.**

Two comments remain in the CSS. A machine reads both, and neither is prose:

- **Line 2, the version** (`/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`). `scripts/build-sample.nu`
  reads it from `lines | get 1` to stamp `tokens.css`, and `scripts/maintain.nu bump` rewrites it. A
  strip of that line broke regeneration with `index too large (empty content)`. The pipe swallowed
  that error, so the fixtures went stale while they still looked correct.
- **The `/* was #rrggbb */` notes on ten `:root` tokens.** Check 3 of `.github/palette-check.py`
  fails when a stated hex disagrees with its `oklch()`.

The prose-comment removal was verified as behavior-neutral. Computed styles for every element in
both fixtures at 390 / 900 / 1280 / 1920px are byte-identical to the commented version: 0
differences across 160 elements and 4 viewports. The CSS went 35192 to 13399 bytes, `mermaid.js`
4731 to 2079, `samples/dark.html` 45173 to 20728 (54%), and `samples/dark-conn-map.html` 41030 to 16585
(60%). That reduction lands in every page a consumer generates.

## Contents

| Section | Covers |
| --- | --- |
| [Fonts](#fonts) | Source Serif 4, the weight axis, fallback path, `--body-font` / `--mono-font` |
| [Type scale](#type-scale) | The one clamp, em steps, compounding traps |
| [Italics](#italics) | Which eight rules slant, and why h3 does not |
| [Width and measure](#width-and-measure) | `--page-width`, the long measure, three failed caps |
| [Paragraphs and section rhythm](#paragraphs-and-section-rhythm) | Section gaps, `.indented` |
| [Lists](#lists) | Markers, and the VoiceOver half of it |
| [Tables](#tables) | `table.tree`, widths, no zebra, `.num`, sticky `th` |
| [Links](#links) | Underline floor, the outbound arrow's alt text |
| [Color and the contrast budget](#color-and-the-contrast-budget) | Four surfaces, every ratio, the data ramp, forced colors |
| [Form follows role](#form-follows-role) | Filled vs outlined chips, bars vs boxes, hue budget |
| [Editor themes](#editor-themes) | Why the Rider slot map differs from the prose one |
| [Mermaid](#mermaid) | Init config, label measurement, diagram sizing, zoom, newer diagram types |
| [Connections-map layout](#connections-map-layout) | `body.conn-map`, markup order, no breakouts |
| [Interaction states](#interaction-states) | Press, hover, focus rings |
| [Keyboard and assistive technology](#keyboard-and-assistive-technology) | Zoom button, modal overlay, inert |
| [Direction, zoom and growth](#direction-zoom-and-growth) | RTL, text-only zoom, safe-area insets |
| [Cascade layer](#cascade-layer) | `@layer tufte-dracula`, the `!important` inversion, the indent that stayed |
| [Appearance modes](#appearance-modes) | `prefers-contrast: more`, `prefers-color-scheme: light`, `--mermaid-scheme`, the two mode gates |
| [Print](#print) | Token reassignment, page breaks, chip outlining |
| [Filter](#filter) | `filter.js` scope and its three load-bearing decisions |
| [Unclaimed elements](#unclaimed-elements) | `mark`, `kbd`, `figure`, `figcaption`, and the UA defaults they had |
| [Markdown coverage](#markdown-coverage) | Every construct a converter emits, and the eleven that were unstyled |
| [Raw HTML and other generators](#raw-html-and-other-generators) | Intrinsic-width media, unbreakable tokens, `tfoot`, permalinks |
| [Fixtures are coverage](#fixtures-are-coverage) | Which fixture details exist to catch a regression |
| [Repo layout](#repo-layout) | Why `scripts/` holds the Nushell and `.github/` keeps the Python |
| [Odds and ends](#odds-and-ends) | `hr`, `--ring` |

---

## Fonts

**The body face is Source Serif 4**, a variable serif pinned to an exact jsDelivr version the
way `mermaid.js` is. It ships roman and italic, about 50KB each, served `immutable`.

**Why a webfont at all: every system serif ships 400 and 700 and nothing between.** Nothing
could ask for the 450 that light-on-dark body copy wants. Georgia at `font-weight: 400` and at
`450` render *identically*. The variable axis runs 200 to 900, so 450 is real, and the `600` on
`.newthought`, `strong` and `dt` is a real 600 instead of a snap to bold.

**Why this face over the alternatives: its figures are tabular and lining by construction.** All
ten digits at 529/1000, so a table aligns in the body serif and needs no OpenType feature
support. Its x-height is 475/1000 against Georgia's 481, a 1.2% difference, so no em-relative
value needed a re-derivation.

| candidate | wght axis | x-height | figures |
| --- | --- | --- | --- |
| **Source Serif 4** | 200-900 | 475 | tabular + lining |
| Literata | 200-900 | 507 | proportional, lining (needs `tnum`) |
| Newsreader | 200-800 | 426 | tabular + lining |
| Lora | 400-700 | 500 | proportional + **old-style**, Georgia's exact defect |
| Petrona | 100-900 | 443 | proportional, lining |

None of the five ship `smcp`, so the browser still synthesizes the `.newthought` small caps. The
webfont bought the weight axis, not true small caps.

**The fallback path is a real downgrade, not an equivalence.** Offline the stack falls to
Georgia: no 450 (collapses to 400) and old-style proportional figures, so tables lose alignment.
The measured table per-digit spread is 0.00% online and 4.21% on the fallback. That is accepted,
because the text still renders and reads. The mermaid CDN is the opposite case: it renders no
diagram at all offline. `font-display: swap` keeps the text visible while the font loads.

Georgia stays first in the stack. It is the most widely installed sturdy screen serif (Windows
since Win98, all macOS, iOS), it has low stroke contrast, and it has a large x-height. Noto Serif
covers Android and ChromeOS; DejaVu Serif covers Linux. Charter and Palatino are absent on
purpose, because both exist only where Georgia already does, which puts them out of reach.

**Both stacks are tokens, because three rules needed the literal and one of those rules is not a
`body` descendant in the way it looks.**

- `.mermaid-zoom` sets `font: inherit`, which resolves against `pre.mermaid`, so the injected
  button computed `monospace` at 14.9px. It was the only control in the sheet in the code face
  while `.filter-box` sat in the body serif, and it undid half of the point of removing
  `pre.mermaid`'s fill and accent bar. `font-family: var(--body-font)` after the shorthand fixes
  the family and leaves the inherited weight and style alone.
- `pre` never set a `font-family`, so it inherited the UA's generic `monospace` while the inline
  `code` beside it computed the full stack. The fixtures hid this, because their `pre` wraps a
  `<code>` that supplies the family by inheritance. A consumer that emits a code block without
  the inner `<code>` got a different face for the block than for the inline spans on the page.

`mermaid.js` still writes the stack out twice as a literal, and that is not drift to fix. Both
copies are JavaScript strings in a config object; neither can read a custom property, and each
one is load-bearing for a different reason (see [Mermaid](#mermaid)). The `pre` change was
verified not to disturb them: the sequence `Note over` rect still measures 404px around 384px of
text, and `.mermaid-zoom` still computes the body serif.

**No `-webkit-font-smoothing: antialiased`.** That advice exists because macOS renders dark text
on light heavier than intended. This theme is the inverse, and grayscale-only antialiasing thins
strokes, which is the opposite of what light-on-dark needs.

## Type scale

The body `font-size` clamp is the **only size lever**. Every other step, headings included, is
em-relative to it, so a nudge to the clamp rescales the page proportionally.

The floor is `1rem`, which is 16px. That is the long-form minimum, and it is the iOS input-zoom
threshold that `.filter-box` inherits. The cap is `1.25rem`, which is 20px. Every bound is rem
and never px, so the page scales with a reader who raises the browser default. A previous
`clamp(1.0625rem, 1rem + 0.35vw, 1.375rem)` ran 17px to 22px and read oversized on a desktop.

**Do not lower the floor past `1rem`** without giving `.filter-box` its own 16px floor. iOS zooms
below 16px, and the input sits exactly on the threshold.

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

Nested ratios compound, so check the parent before you add a step. The repo has already paid for
three traps:

- **Headings are `em`, not `rem`.** Anchored to the root they diverged from body copy, which
  grows on a vw clamp. h3 rendered *smaller* than its own paragraphs at every width, 15.3 against
  17.4 at 390px and 17.6 against 22 at 1920px, and h2 fell to 1.16× body.
- **`.verdict` and `.badge` sit at 0.8em, not 0.75em.** They nest inside a 0.95em parent, so
  `0.75 × 0.95 × 16px` is 11.5px, under the 12px floor. 0.8 gives 12.3px. This is coupled to the
  body floor, so re-check these two when that floor moves.
- **`pre code` is `font-size: 1em`** to halt the compounding. `code` and `pre` each carry 0.9em,
  so a bare `<code>` inside `<pre>` would render at 0.81em, smaller than the block it fills.

An earlier scale used `max(Xem, 12pt)` floors. Those resolved to 16px on every viewport under
about 950px. They pinned nine elements to one size and made body copy the *smallest* text on a
phone. `pt` is absolute like `px`, so they also ignored the reader's own setting.

**`h1` and `h2` sit at weight 400.** At 22px to 35px they carry it. **`h3` is 500.** It is the
one heading at text size, 1.12em and 12% over body, so at 400 it rendered lighter than the
paragraph beneath it. Heavier than h2 is not an inversion, because h2 is 20% larger, italic and
`--purple`.

**`code` and `cite` sit at 0.9em.** SF Mono's x-height is 526/1000 against Source Serif 4's 475,
a ratio of 1.094, so the x-height-matched size is 0.914em. A previous 0.85em was tuned against
Palatino (x-height 471) and over-corrected by about 7%.

**`li` carries no `font-size` of its own.** At 0.95em in the structural tier, a bulleted list
inside an `<article>` rendered 17.48px against 18.4px paragraphs: body copy subordinate to the
body copy beside it. The two contexts that want 0.95em ask for it themselves, `.nav-list li`
directly and `nav` on the container. That last one was double-counting while `li` had its own
value, because `nav > ul > li` compounded to 0.9025em, the smallest text on any page with a
`<nav>`. Dropping the declaration also retired `li li { font-size: 1em }`, which existed only to
stop the same compounding one level down.

## Italics

Eight rules slant: `.byline`, `h2`, `th`, `summary`, `blockquote`,
`details.nav-group > summary`, `.filter-box::placeholder` and `.filter-empty`.

**`h3` is upright and `h2` is italic, deliberately.** They are adjacent levels, so while both
slanted the italic distinguished neither, and the hierarchy rested on size and color alone. An
upright h3 gives the pair a second axis, h2 italic `--purple` against h3 upright `--label`, and
it lands where italic is most expensive: at 1.12em a slanted stem on a dark surface loses more
definition than a 1.35em heading does.

**`summary` is 450, not 400.** It inherits the body font-size, so at 400 it was the only italic
text at *reading* size lighter than the copy around it. The italic stays, because it marks the
row as a label rather than prose. `details.nav-group > summary` inherits the weight.

**`th` is 450**, which matches body copy. A header row lighter than its own data reads as
subordinate to it. The declaration cannot simply go, because the UA default for `th` is bold.
Italic and `--pink` carry the distinction, and the weight must not work against it.

## Width and measure

**Page width is one number**, `--page-width: min(90vw, 160rem)` in `:root`. `body` and the
`body.conn-map` article both reference it, so the two layouts cannot drift.

- `90vw` is the proportional side margin, 5% each side. This is the dial.
- `160rem` is the ultrawide backstop, about 2560px at a default root. It engages past about
  2844px, where an uncapped line would run more than 390 characters. It is `rem`, so it scales
  with the reader's root size.
- `100% - 2 * var(--gutter)` on `body` is the floor, and it is what respects the safe-area insets
  folded into `--gutter`.

**Three attempts failed. They are recorded so that nobody retries them:**

1. `min(100% - 2 * var(--gutter), 70ch)` plus an `@media (min-width: 1200px)` override to `80vw`.
   The 70ch cap left **34.8% of a 1199px window empty**, with the body at 782px, and a cross of
   1200px snapped the content from 782px to 960px in one step.
2. A `100rem` cap. It left 16.7% of a 1920px window empty, and it cut 2560px to 1600px.
3. Gutter and backstop only, with no proportional term. That is full-bleed in practice: 32px
   margins at every size, and 2.5% unused at 2560px.

"Unused space" is **not** the metric to minimize. A page needs side margins that scale.

**The long measure is a standing decision, not an oversight.** Content flows nearly the full
window, about 178 characters per line at 1920px against the conventional 60 to 75. This
stylesheet serves dense reference pages with tables and diagrams, not book-length prose.

The repo re-litigated this once, and the answer did not change. `max-width: 32em` does hit about
74 characters at every width, but it strands body copy in a narrow left column with the
container empty. If anyone revisits it:

- The cap belongs in `em`, **not `ch`**. `ch` is the advance of `0`, and Georgia's `0` is 0.614em
  against a 0.433em average prose advance, a measured ch-to-average ratio of 1.416, so `70ch` ran
  99 characters and not 70.
- The cap must be scoped to section children. A bare `p` selector also hits `.byline`, a flex
  item in the conn-map header that collapses that layout when capped, and it hits the `<p>` that
  mermaid emits inside `foreignObject` labels.
- Smaller type makes the measure *worse*. The container width is `vw` and `%` driven, so smaller
  type fits more characters per line.

**Sidenotes stack below 1000px, not below 600px.** The float is `width: 28%`, so between the old
600px breakpoint and about 1280px the note was narrower than any measure worth reading: 150px at
601px, 194px at 768px and 227px at 900px, which is **19 to 25 characters per line** at 0.9em,
against 37 at 1280px. The body copy beside it kept the full container, so the page put a ribbon
of shredded text next to unbroken prose. Above 1000px the note is 252px and up.

**`hyphens: auto` is scoped to the two narrowest prose measures, not global.** `hyphens` computes
`manual` by default, so nothing in the sheet ever hyphenated, including the sidenote at 28% and
`.col-2` at half a column. Those are the two measures this section already records at 19 to 25
characters per line. Both fixtures carry `lang="en"`, which hyphenation requires. The rule does
**not** apply to body copy, because the long measure needs no help. It does not apply to
`.nav-list li a`, because a hyphenated link looks like a hyphen in the slug. It does not apply to
headings.

The collapse declarations live in their own `@media (max-width: 1000px)` block rather than
widening the 600px query. Everything in that block is genuinely phone-sized and was measured at
600px: the gutter, `pre` padding, `aside` and `blockquote` padding, `.edge-list`, `.col-2`,
`.scorecard`, the 44px touch minimums, and the diagram scroll container. Two breakpoints with
distinct reasons beat one breakpoint that is wrong for half its contents.

## Paragraphs and section rhythm

**`section` spacing is `2.5rem`, which matches `h2`'s top margin, because the smaller of the two
never painted.** It was `margin-bottom: 2rem` against `h2 { margin: 2.5rem 0 0.75rem }`.
Adjacent-sibling margins collapse to the larger value, and every section in both fixtures opens
with an `h2`, so the gap measured **40px between all eleven sections** at 1280px while the 2rem
declaration contributed nothing. Zeroing it on all of them moved the document height from 5096px
to 5080px. The defect was not the wasted declaration but what it hid: a section that opens with
anything else, a `<p>`, a table or a diagram, got 2rem where its neighbors got 2.5, so the rhythm
depended on markup the stylesheet does not control. Equal values collapse to 2.5rem either way,
measured at 40px at 320 / 390 / 600 / 768 / 1280 / 1920 / 2560px, across eleven gaps, with no
exceptions.

`section > :first-child { margin-top: 0 }` was tried and rejected. It flattens the gap under the
byline for the first section, and in `body.conn-map` the sections are flex items where margins do
not collapse at all, so a rule tuned for the collapsing case misaligns the two columns.

**`.indented` is the book setting. It is opt-in and it is two rules.** `margin-block: 0` on the
paragraphs, plus `text-indent: 1.5em` on every `p + p`. Nothing precedes the first paragraph, so
nothing indents it, which is why the indent hangs off the sibling combinator rather than off `p`.
1.5em resolves to 24.3px at 390px and 30px at 1920px, so it tracks the body clamp.

**It was three rules until v1.20.0.** The third was `.indented :is(ul, ol) { margin-block:
0.75rem }`. A bare `ul` had padding but no margin anywhere in the sheet, so it relied on the
paragraph above to supply the gap, and inside `.indented` no gap was left to rely on.
[Markdown coverage](#markdown-coverage) found the same hole outside `.indented`, where a
converter's list butted against the paragraph before it. The margin is global now, and the opt-in
rule retired as a duplicate. `dl` carries its own 1rem, `blockquote` and `aside` carry their own
1.5rem, and `pre` gained 0.75rem in the same release for the same reason.

It is a class rather than the default for two reasons. The two conventions cannot mix on one page
without reading as an accident, and the default is what every existing consumer's output assumes.

**A sidenote marker used to knock its own paragraph off the rhythm.** `.sidenote-number:after`
carried `vertical-align: super`, which grows the line box. Measured at 1280px, a one-line
paragraph that contained a marker was **30.5625px against a 29.44px `line-height`**, or 1.04
lines, so every paragraph with a note sat about 1px taller than its neighbors. It is now
`position: relative; top: -0.4em; line-height: 0`, which lifts the glyph without any part in the
line-box height. The same paragraph now measures 29.44px, exactly 1.000 lines, and the marker is
still raised. `.sidenote:before` shares the rule, and the numbers still align between the marker
and the note.

**`--space-*` covers block rhythm only. The component padding stays literal.** Six tokens
(`0.5 / 0.75 / 1 / 1.5 / 2.5 / 3rem`) replace 19 vertical-rhythm values: `body` padding, the
`h2`, `h3` and `p` margins, `section`, `hr`, `dl`, `nav`, `footer`, `figure`, `aside`,
`blockquote`, `details`, `.edge-list`, `.filter-label`, `.filter-box`, `.scorecard`,
`.mermaid-zoom`, and the mobile `body` padding. The values that are not on the scale (0.15, 0.2,
0.3, 0.35, 0.4, 0.6, 0.65, 0.85, 0.9, 1.25rem) are **left alone deliberately**. They are
component-internal padding tuned by measurement, not page rhythm, and a snap to the scale would
move rendered boxes to satisfy an abstraction. The list indent (`ul, ol padding-inline-start:
1.5rem`) stays literal for the same reason, because it pairs with `--tree-step` and not with the
vertical scale.

The refactor is a pure substitution, and it was verified as one. Computed margins and padding for
17 rhythm-bearing selectors, compared against the v1.16.0 fixture at 1280px, differ in exactly one
place: `section`'s 32px became 40px, which is the deliberate change above. Sixteen of the
seventeen are byte-identical.

## Lists

**A prose `ul` keeps its markers.** `ul { list-style: none; padding-inline-start: 0 }` was a
global reset, so a bulleted list inside an `<article>` rendered as a run of short paragraphs:
`list-style-type: none`, `padding-inline-start: 0px`, and a nested `ul` that indented by **0px**,
so the nesting was invisible too. It also made `li::marker { color: var(--muted) }` dead code for
every `ul`. `ul, ol { padding-inline-start: 1.5rem }` gives both list types one indent and lets
`ul` keep the UA's `disc`, `circle` and `square` progression, now muted. The reset bought
nothing, because `.nav-list` sets `list-style: none` and `padding-inline-start: 0` on its own
rule.

**This is also half of the VoiceOver list-semantics problem.** WebKit drops list semantics from a
list with `list-style: none`: no "list, N items", and no item position. With the markers restored,
prose lists keep their semantics natively, and only `.nav-list` needs `role="list"` in the markup,
which is now a documented consumer obligation. The real accessibility tree verified it (CDP
`Accessibility.getFullAXTree`): eight `list` nodes in `samples/dark.html`, four nav lists by explicit
role and the prose lists by having markers again.

## Tables

**No `font-family` on `table`.** Tables inherit the body serif, which is correct because Source
Serif 4's digits are tabular and lining by construction. Tables briefly carried the monospace
stack because Georgia cannot do this. Georgia has old-style *and* proportional figures, nine
distinct advances, with `1` at 430/1000 against `0` at 614/1000, and no `lnum` or `tnum` to
escape them, because its entire GSUB feature list is `aalt, locl`. That workaround cost about 27%
of table width, 807px against 634px natural at 1280px on six columns, and it put tables in a
different register from the prose. `font-variant-numeric: tabular-nums` on `td` is
belt-and-braces for the fallback path, where it works in any face that exposes `tnum`. It is
inert in Georgia, which exposes neither.

**`table.tree` is a table, deliberately not a `treegrid`.** The ask was hierarchy plus columnar
density. `role="treegrid"` is the answer that looks obvious and is wrong. The role is a keyboard
contract (roving `tabindex`, arrow keys, `aria-level`, `aria-expanded`, `aria-posinset`,
`aria-setsize`), so shipping it without the script promises interaction that does not exist, and
it *removes* the native row and column semantics a plain `<table>` announces. Depth is an author
attribute, `data-depth`, and everything else is presentation.

- **The indent is one `--tree-step` custom property, and only levels 0 to 3 exist.** `attr()`
  cannot feed a length into `calc()` with useful support, so the alternative to four explicit
  rules is a custom property per row in the markup, which pushes styling into the generator. Four
  rules is smaller, and a level-4 row degrades to flat rather than to wrong.
- **Depth de-emphasizes with `--label` at levels 2 and 3 rather than with smaller type.** Nested
  ratios compound, and the table already sits at 0.95em.
- **The `↳` needs the same alt-text treatment as the outbound arrow.** It is a `::before` on the
  first cell, so it lands in the accessibility name: a row announces as "↳ REQ-01". It takes the
  same `@supports (content: "x" / "y")` guard, `content: "\21B3\A0" / ""`. Any future decorative
  `::before` owes this.

**`width: auto; max-width: 100%`, not `width: 100%`.** A three-column table stretched to the full
page: 1152px rendered against 315px of content at 1280px. The change was checked against a
**wide** six-column table at 390 / 601 / 768 / 1024 / 1280px. A wide table is unchanged, because
its min-content width is the floor either way, 922px at 1024 and 1152px at 1280. Only a table
narrower than its container moves, which is the intent: the narrow table measures 316px at 1280px
and 338px at 1920px.

That comparison turned up a **pre-existing** sideways-scroll bug, identical under `width: 100%`.
Between 601px and about 1000px a wide table's min-content width exceeds the body and the
*document* scrolls, 731px against a 537px body at 601px and 746 against 691 at 768, because the
`overflow-x: auto` escape hatch only existed below 600px. **v1.14.0 fixed it by moving the hatch
to `@media (max-width: 1000px)` with `width: fit-content` alongside it.** The trigger is smaller
than a six-column table: at 200% text-only zoom and 601px, the fixture's own three-column
`table.tree` measured 588px against a 473px body and the document scrolled 51px. This file had
recorded sideways table scroll as a 400%-zoom problem. It starts at 200%.

`display: block` alone is not the fix. A block-level table takes `width: auto` and fills its
container, which reinstates the defect above: the narrow tree table measured 537px at 601px and
899px at 999px. `width: fit-content` resolves to content width for a table narrower than its
container and to container width for one wider, so both land correctly. The tree table measures
426 / 434 / 445px against bodies of 537 / 691 / 899px, and an injected eight-column table scrolls
inside itself at 601px (`scrollWidth` 617 against `clientWidth` 537) with the document at 601px.

The cost is the sticky header, which `display: block` makes inert up to 1000px rather than 600px.
It still pins above that, verified: `th` top holds at 0 after a 60px scroll at 1280px. That is
deliberate. A pinned header matters on a long table at desktop width, and a page that scrolls
sideways is a WCAG 1.4.10 failure at every width where it happens. The inert header and the
keyboard reach (WCAG 2.1.1) both have an opt-in answer as of v1.21.0, `.table-scroll`, which is
consumer markup. See [The backlog this closed](#the-backlog-this-closed).

**A sticky `th`** needs an opaque background, or the rows that scroll under it show through. The
rule is an inset shadow and not `border-bottom`, because under `border-collapse: collapse` the
table paints the collapsed border. That border scrolls away from the stuck header and leaves it
running straight into the first row.

**Zebra striping went in v1.17.0, and the row fill it freed now means one thing.**
`tbody tr:nth-child(even) td { background: var(--code-bg) }` was the sheet's only decorative
fill. It separated rows that the reader could already separate by padding, and it put the *code*
surface behind arbitrary prose cells. A Tufte table separates rows with space and one rule. There
are three consequences:

- **`table.tree tbody tr:nth-child(even) td { background: none }` went with it.** It existed only
  to switch striping back off inside the tree table, whose own depth-0 tint it was protecting.
  With nothing to override, it was pure weight. Parity is not depth: on a tree the stripe cut
  across the structure it was supposed to help read, which is why that override existed at all.
- **`table.tree [data-depth="0"] td` is now the only fill inside any table**, so `--code-bg` in a
  table means *root row* and nothing else. That reinforces what the indent, the `↳` and the bold
  weight already said.
- **`tbody tr:hover td` keeps its `tbody` qualifier.** The qualifier was there to win a
  specificity fight against the even-row rule, 0,1,2 against 0,1,3. That opponent is gone, so the
  qualifier is now redundant rather than load-bearing. It stays because it also scopes hover away
  from a `thead` row.

Ratios elsewhere in this file that were measured "inside a zebra row" are historical. The surface
is still real, in `pre`, inline `code`, `.filter-box` and the tree root row, but no ordinary
table row carries it.

**`.num` is an opt-in class, not a heuristic.** `th.num, td.num { text-align: end }`. CSS cannot
tell a number from a label: `:has()` cannot match text content, and "a column that looks numeric"
is a generator's claim. Source Serif 4's figures already shared one advance width, so alignment
was the missing half. `1234`, `567` and `9012` now line up on the last digit, where before they
hung off the left edge under an italic header. The class goes on the `th` too, or the header
floats off its own column, which is why `README.md` states both.

## Links

**Underline thickness has a 1px floor.** `0.05em` resolves to 0.8px at the base size, which
paints as a faint partial-coverage line, and the underline is the only thing that marks a link.

`overflow-wrap: break-word` lets a long URL or slug break instead of escaping its container. The
connections-map Links column is as narrow as 220px.

**The outbound arrow is decorative, and it reached the accessibility tree.** Measured through CDP
`Accessibility.getFullAXTree`, the link computed as `"outbound link\A0↗"`, so a screen reader
read out "north east arrow" after every external label. `content: "…" / ""` gives the
pseudo-element empty alternative text. That suppresses the arrow and the nbsp for assistive
technology and leaves the glyph visible.

It sits behind `@supports (content: "x" / "y")` because the alt-text syntax is a single value. A
browser that cannot parse it discards the **whole** declaration, and the marker disappears.
Firefox ESR 128 is in that group and is still deployed. Both paths were verified: with support
the accessible name is `"outbound link"`, and without support the marker stays visible and merely
keeps the old announcement.

`\A0` (nbsp) keeps the arrow from orphaning onto its own line. Print sets `content: ""` later in
source order, and it drops the underline too. On paper the destination is unreachable either way,
so both are noise.

`cite` is monospace and `font-style: normal`. The browser default is italic serif, which in this
theme is indistinguishable from `<em>`.

## Color and the contrast budget

The `:root` block is the only source of color truth. `tokens.css`, `mermaid-palette.json` and the
inline hex in `mermaid.js` are machine-checked projections of it.

**The budget covers four backgrounds.** For a long time it covered two. `--rule-light`, `--muted`
and `--red` were tuned against `--surface` and `--code-bg`, and two further surfaces existed
unmeasured. Both came from `color-mix`, which is why nobody noticed them. **A computed-value
reading reports the un-composited mix and is wrong.** Every number here was sampled from rendered
pixels through a 1×1 canvas.

The four surfaces that text can land on are `--surface`, `--code-bg` (`pre`, inline `code`,
`.filter-box`, the `table.tree` root row, and, until v1.17.0, zebra rows), the row-hover fill,
and, until v1.9.0, the `aside` tint. A new token must clear its ratio against **all** of them,
not against the easiest one.

Current ratios worth keeping to hand: `--muted` 4.53 on `--code-bg` and 5.47 on `--surface`,
`--red` 4.73 and 5.72, `--rule-light` 3.05 on `--surface` (exactly the 1.4.11 floor,
deliberately) and 2.52 on `--code-bg`, and `--label` 7.86 on `--surface`, 6.51 on `--code-bg` and
9.03 on `--surface-alt`.

**`--label` is `oklch(0.810 …)`, up from 0.767, because the two gray tiers were one gray with two
names.** At 0.767 against `--muted`'s 0.710 they shared hue and chroma and differed by only 0.057
in L, so ΔE_ok was 0.057, under 3 JND by the yardstick this file applies to `--data-2` and
`--data-3`. The difference from those two is that these **co-occur**. `.scorecard` puts
`--on-surface`, `--muted` and `--label` in one component, and `.byline` (muted) sits directly
above `h3` (label). 0.810 gives ΔE_ok **0.100**, about 5 JND, and it keeps `--label` a clear 0.167
in L below `--on-surface`, so the label tier still reads as secondary.

**The direction was forced, not chosen.** `--muted` cannot get quieter. It is already at 4.53 on
`--code-bg`, three hundredths above the 4.5 floor, so the only way to widen the gap was to move
`--label` toward body copy. That also fixes the print block, where the two tokens had been
*identical* in lightness, both 0.545, so the tiers were literally one color on paper. Print
`--label` is now 0.470, measured 6.93 on white and 6.36 on the `0.97` gray, against print
`--muted`'s 4.99 and 4.58. The story is the same in both modes: **label is the tier that moves
toward body text, and muted is the tier pinned at the contrast floor.**

`--label`'s `/* was */` note is now `#b7bfe4`, recomputed through the same Oklab path that
`.github/palette-check.py` uses, so check 3 still passes. It has no `mermaid-palette.json` entry,
so nothing else needed a re-projection.

**The row-hover fill darkens instead of lightening, and it is a flat token.** It was
`color-mix(in oklch, var(--rule-light) 50%, transparent)`, which composited to `rgb(76,79,95)`
over `--surface`. That lifted the row toward the accents on it and took every one below 4.5:1
(`--red` 2.84, `--purple` 2.91, `--muted` 3.12, `--pink` 3.35, `--label` 3.84, `--link` 4.45,
with only `--on-surface` surviving at 7.60), so a hovered row failed 1.4.3 for every colored or
linked cell in it. It is now `background: var(--surface-alt)`, which runs 5.87 (`--purple`) to
15.35 (`--on-surface`). Darker-on-dark is the weaker affordance and it is worth it, because the
fill is 1.15:1 against `--surface`, the same order as the striping it replaced. It uses
`--surface-alt` rather than another `color-mix` because that token exists, it needs no
compositing to reason about, and it is the only other flat surface in the sheet.

**`aside` has no fill at all, on screen or on paper.** The tint composited to `rgb(61,64,78)`,
where `--muted` measured 3.95, `--red` 3.61, `--purple` 3.69 and `--pink` 4.25, so a `cite`,
`.sc-note`, `.count`, `::marker` or status span inside a callout failed while `--label`, the
aside's own color, passed at 4.87. Print had already found this on white, where `--label`
measured 3.58:1, and dropped the tint there. The screen case was the same failure one step
milder, and nobody carried the fix back. Deleting the declaration retired the print override too.
The orange accent bar still marks the callout.

**`--red` is `oklch(0.735 …)`, up from 0.700.** At 0.700 it measured 4.14 on `--code-bg`, so
`.correction` failed inside `pre` and `.filter-box`. The budget had checked `--muted` on that
surface, at 4.53 and passing by 0.03, and had not checked the accents. 0.735 gives 4.73 / 5.72 /
6.57 on `--code-bg` / `--surface` / `--surface-alt`, and it lifts the `.verdict-failed` chip from
5.00 to 5.72. 0.725 is the first value that clears 4.5, at 4.56, and 0.735 was taken for
headroom. It moved `--red` closer to `--pink` in L, 0.735 against 0.742, for a ΔE_ok of 0.076 and
about 3.8 JND on a 32° hue separation, so a `--pink` `th` and a `--red` `.correction` in one
table stay distinct. `--red` has no `/* was */` note and no `mermaid-palette.json` entry, so the
change had no hex projection to keep in step.

**`--purple` on `--code-bg` is 4.23, and it was left alone.** Purple is `h2`, the `pre` accent bar
and `::selection`. The bar is non-text and clears 1.4.11 at that ratio, and nothing puts purple
*text* on the gray, because an `h2` never renders inside a `pre` or a table cell. The token is
mirrored into `mermaid-palette.json` twice and carries a `/* was */` note, so a move would cost a
hex recomputation in two files to fix a case that does not occur. Recorded rather than fixed.

**Borders drawn on `--code-bg` take `--rule`, not `--rule-light`.** At 2.52 on that surface, three
components whose only boundary sits there all failed 1.4.11: `.filter-box`, whose border is the
only thing marking it as an input, `.mermaid-zoom`, which sits on the `pre`, and
`pre.mermaid:hover`, the ring that makes a diagram read as clickable on touch. `--rule` is
`var(--muted)`, which is 4.53 there. No new token was needed, because the sheet has exactly two
rule weights and this is the heavier one. The side effect is wanted: a control now reads stronger
than a passive container like `details`, which keeps `--rule-light` on `--surface` at 3.05.

**`em` carries no color.** It was `--label` at 6.75:1 where the copy around it is 13.36:1, which
is emphasis at half the contrast of the text it emphasizes. The declaration was deleted rather
than reassigned, so `em` inherits. That is what makes it correct inside an `aside`, a
`blockquote` or a `.sidenote`: it matches its surroundings instead of overriding a color those
containers had already chosen. The italic carries the emphasis, from the variable font's real
italic face. `cite` stays distinguishable on family and upright stance, which is what that
distinction always rested on.

**The data ramp exists so that a diagram category cannot borrow a prose accent.** `--data-1` is
`oklch(0.790 0.077 255)`, moved off the link hue. It was `oklch(0.790 0.100 216.800)` against
`--link` at 216.782, a 0.02° collision with ΔE_ok 0.038, so the `ext` classDef fill and the pie's
first slice *were* the link color. 255 puts it 38.2° from `--link`, 45.9° from `--purple` and 85°
or more from every other ramp member, which is the comparison that matters, because those appear
together in one diagram. Chroma 0.077 is 71% of the maximum in-gamut chroma at that lightness and
hue, which matches the ratio the old value held, and `--surface` text on the new fill measures
7.39:1. A rendered pie and a `classDef` flowchart verified it: `#99bdec / #de8dc3 / #74caa6 /
#bbc175`, four visibly distinct categories.

**The ramp got a light and a print palette in v1.25.0, and that reverses what this file used to
accept.** Through v1.24.0 the four tokens were declared once in the base `:root` and in no mode
block, so a light page and a printed page drew diagram fills tuned for a dark ground. Measured
against the light `--code-bg`: `--data-1` 1.72:1, `--data-2` 2.15, `--data-3` 1.74, `--data-4`
1.69, and against light `--surface` 1.85 to 2.35. WCAG 1.4.11 asks 3:1 of a meaningful non-text
boundary, and a category fill is exactly that: the reader has to tell a slice from the card it sits
on. The old reasoning, recorded under *Appearance modes*, was that slices abut each other rather
than the background and each carries a label at 7.48 to 9.52:1, so the weak pair was derived rather
than rendered and no fixture had a pie chart. That is true and it was still the wrong call: it
argued the boundary does not matter instead of measuring that it passes.

The light and print blocks now carry their own four values, at the same hues and the same fraction
of maximum in-gamut chroma each dark member holds, with lightness solved down until the boundary
clears 3.2:1:

```
--data-1  oklch(0.624 0.146 255)      #4488dd   71% of max chroma
--data-2  oklch(0.643 0.156 340)      #c962ab   56%
--data-3  oklch(0.613 0.079 165)      #539378   61%
--data-4  oklch(0.619 0.078 112.5)    #868b53   57%
```

Measured flat, which is what the token is: 3.20:1 on light `--code-bg`, 3.50 on light `--surface`,
3.30 and 3.60 in print, and 5.03 against the `#161616` label Mermaid draws on a slice in light mode.
The hues do not move, so the separation reasoning above still holds unchanged. The floor is 3.2
rather than 3.0 so a rounding change cannot walk it under the gate.

**A pie slice does not render the token, and finding that out is what the rendered probe was for.**
Mermaid's own stylesheet sets `.pieCircle { opacity: 0.7; stroke: black; stroke-width: 2px }`, so
the fill a reader sees is 70 percent of the token over the card. Composited against the light
`--code-bg` of `#f0f1f9`, the four slices measure **2.20, 2.22, 2.17 and 2.15:1**, not 3.2. The
token work moved that pair up from roughly 1.5 to roughly 2.2 and it still does not clear 3:1. Dark
mode composites to 3.19 to 3.87:1 and does clear it. What actually separates a slice from the card
in both modes is Mermaid's 2px black stroke, which is a boundary the fill contrast never had to
carry.

So the gate is honest about its own scope: check 5 asserts the **token** clears the non-text floor,
which is what governs a `classDef` fill, a legend swatch and any consumer that paints with
`var(--data-2)` directly. It does not assert what a `pie` fence renders, because the opacity that
weakens it belongs to Mermaid and no CSS in this sheet sets it. Raising it with a seventh
`!important` was rejected here: it fixes the light boundary and simultaneously exposes a worse
pre-existing pair, recorded in `backlog.md`, where a dark-mode slice label is light text on a pale
fill at 2.86 to 3.47:1 composited. That is one change with two consequences and it needs its own
decision, not a line smuggled into a token bump.

**The floor is now a gate, in `.github/palette-check.py` check 5.** `DATA` joins `TEXT` and
`RULES`, checked against both grounds at the non-text floor in all four modes, because the whole
reason the old values survived is that a measurement in prose is not a gate. Reverting `--data-3`
to its dark value fails four contrast assertions and two hex assertions at once. `initLight.pie1..4`
in `mermaid-palette.json` and the light palette in `mermaid.js` carry the new hexes, and the pie
keys moved inside the two palette objects rather than sitting shared below them, which is what
lets check 1 resolve each set through its own block.

**What this does not fix: the `classdef` fills.** `mermaid-palette.json` has one `classdef` section,
projected from the dark ramp, and check 2 resolves it against the dark palette only. A generator
that emits its own `classDef name fill:…` lines therefore still paints dark-ground fills on a light
page. Giving `classdef` a light twin means a second section, a second membership check, and a
decision about how a generator picks between them at emit time with no CSS to read. That is a
larger change than the token work, so it is recorded in `backlog.md` rather than half-done here.

`--data-2` sits 9.4° off `--pink` and `--data-3` sits 9.6° off `--green`, both under the roughly
10° threshold where a hue shift becomes visible, at ΔE_ok 0.020 and 0.017, about one JND. They
are separated in name more than in appearance, and they are left that way deliberately. Nothing
in a diagram puts a category fill beside body copy, so the collision costs less than `--data-1`'s
did, and a move means a recomputation of two more hex projections.

**Forced colors suppresses shadows, so anything whose only boundary was a shadow needs a border.**
That is the general rule behind both fixes below, and it is the reason the print block's
`inset 0 0 0 1px currentColor` could not simply be reused.

- **Semantic chips outline themselves.** `code, .verdict, .badge { border: 1px solid
  currentColor }`. Under emulation, every `.verdict-*` fill resolves to `rgb(255,255,255)` with
  `rgb(0,0,0)` text, so all four verdicts become one appearance. The **state** survives either
  way, because the chip's text says `PASS`, `PARTIAL`, `FAILED` or `N/A`. The fill is redundant
  with the label, which is why a border suffices and why a generated glyph would be both
  unnecessary and impossible to translate. The border restores the boundary, not the meaning.
- **Tables carry a real border.** An earlier note here claimed that "the header rule and row
  rhythm survive". They do not. Measured: `table` `box-shadow: none`, `th` `box-shadow: none`
  (the inset header rule is a shadow too), `td` `border: 0px none`, and the `th` background
  resolving to `rgb(0,0,0)`, identical to the rows below it. A pixel scan down the right edge
  returned a single value: no outer rule, and a header indistinguishable from the data.
  `table, th, td { border: 1px solid currentColor }` fixes it, and the edge now returns five
  distinct values, including the forced foreground.

Fills inside a table still flatten. `--code-bg` resolves to `Canvas` and takes the `table.tree`
root tint with it. That is left alone, because the user's own rendering is the point of the mode.
What was restored is the grid, not the tint.

## Form follows role

Three families were drawn the same way and meant different things. *Form* separates them now, so
the shape carries the role and color is free to mean one thing.

**A filled chip is a state. An outlined chip is a label.** `.verdict-*` keeps its fill, because
pass, partial, failed and N/A are states of a claim and the hue does real work. `.badge` is
`color: var(--label)` with `box-shadow: inset 0 0 0 1px currentColor` and no fill. It was three
fills, `--green`, `--orange` and `--red`, for **Tier 1, 2 and 3**, which are ordinal levels and
not health states, so a green-to-red ramp told the reader that tier 3 was failing. It also put
`--red` on three meanings at once: `.badge-t3`, `.verdict-failed` and `.correction`.

`.badge-t1`, `-t2` and `-t3` **are not removed**. Consumers emit `class="badge badge-t3"` and
that markup keeps working. The variants simply carry no declarations, so there is nothing to keep
in step. The ring is `currentColor`, so it tracks the text and clears 1.4.11 at the `--label`
ratios above.

**What that trades away.** Tier is no longer scannable at a glance down a long index. The text
always carried the level, so nothing is *lost*, but the reader now reads the ranking instead of
seeing it. Three steps of one new hue was costed and rejected: three `:root` tokens **plus three
print overrides**, each clearing 4.5:1 on all four backgrounds, out of free hue gaps 20° to 27°
wide, inside which a three-step ramp reads as one color at 0.8em. If tier scanning matters, the
cheap version is weight or ring thickness on the existing hue.

**A border means interactive. An accent bar means passive block.** `.scorecard` was a 1px
`--rule-light` box, identical to `details`, `.nav-group`, `.nav-list`, `.filter-box` and
`.mermaid-zoom`. That is eight bordered instances in the fixture, so a data panel, a disclosure
widget, a form field and a button all read as one object. `.scorecard` now takes
`border-inline-start: var(--accent-bar) solid var(--rule-light)` with the `pre`, `aside` and
`blockquote` padding, and every remaining bordered box in the sheet is something you can click,
type in or open. It uses `--rule-light` rather than a new hue because the scorecard is structural
rather than semantic, and because that is the color the border already was.

**Three prose accents carry two or three roles each, and that is accepted, not overlooked.**

```
--pink    h1, th
--purple  h2, pre accent bar, ::selection
--orange  strong, aside accent bar, .unverified
```

The overlap a reader can actually see is `--orange`. `samples/dark.html` puts `strong` and
`.unverified` in adjacent paragraphs, so orange means *emphasis* on one line and *status* on the
next. It stays because form separates the other two pairs. `--pink` is a 1.75em heading against
an italic 0.95em table header, and `--purple` is a heading against a 3px bar and a selection
fill, so none of the three collide in one glance. A repaint of `.unverified` means a fifth
semantic hue plus its print override, clearing 4.5:1 on four backgrounds, out of the same 20° to
27° gaps that killed the tier ramp, for a weaker reason.

**What this means for the next accent.** The budget is spent. A new role takes an existing accent
*plus a different form* (weight, bar, ring, fill), the way `.verdict` and `.badge` are separated,
or it takes `--data-1` to `--data-4` if it lives in a diagram. A new hue is the last resort, and
a hue reused for a third prose role needs a line here that says why the two cannot appear
together.

## Editor themes

`themes/` shares the palette, but the *slot map*, which token paints which syntax class, is a
separate decision, and prose logic does not transfer to an editor. In prose the color is sparse:
a `--pink` h1 and an orange `strong` sit in a field of white body serif, and low chroma reads as
restraint. In an editor the color is the whole information channel and almost every glyph carries
one, so the same chroma reads as wash.

**`--label` is the document's caption tier, not a code tier.** It paints `figcaption`, sidenotes,
`dd` and `footer`, which are content deliberately behind the body. The first Rider scheme handed
it 18 slots, including braces, brackets, parentheses, comma, semicolon, dot, parameters and both
field kinds. That collapsed most of a C# buffer into one blue-gray band at C 0.053. Upstream
Dracula paints punctuation at `fg`, and so does this scheme now, at `--on-surface`, which takes
7.86 to 13.36 against `--surface`. Parameters moved to `--orange`. `--label` still carries
instance and static fields, which are legitimately secondary.

**Types cannot sit on plain `--purple`.** At L 0.698 and 5.10 on `--surface` it is the dimmest
accent in the palette, and in C# type names are the highest-frequency token there is. They use
`{{purple.bright}}` (#bfa4ed, 6.40), which is the existing `.bright` lift in `scripts/create-themes.nu`,
not a new placeholder and not a palette change.

**Three alternatives were rendered and rejected**, all variants of adopting Dracula's full slot
map: functions to `--green`, strings to `--data-4`, numbers to `--purple`. They separate more
channels, but `--data-4` (#bbc175) reads olive rather than yellow at this chroma, and moving
strings off green breaks the one cross-medium tie the theme has. The stylesheet paints inline
`code` green, so a string in the editor and a `<code>` span in the document are the same color.

**Do not fix this by raising chroma in `:root`.** Every ratio in [Color and the contrast
budget](#color-and-the-contrast-budget) was measured against those values, and every published
document inlines the tokens. A theme that reads dim is a slot-map problem first. Verify by
rendering the *generated* `.icls`, not the template, because the placeholders hide which hex
actually lands.

## Mermaid

### Init config

`theme: 'base'` plus explicit `themeVariables`, and **never `theme: 'dark'`**. The stock dark
theme ignores this palette entirely.

**Hex, never `oklch()`.** khroma throws "Unsupported color format" and aborts init, so no diagram
renders at all. The values mirror `mermaid-palette.json`, and CI enforces the match.

**`darkMode` belongs *inside* `themeVariables`.** `mermaidAPI` passes only
`config.themeVariables` to `base.getThemeVariables()`, so a root-level `darkMode` never reaches
the theme and every derived color computes light-mode. ER rows come out `lighten(mainBkg, 75)`,
near-white under light `textColor`.

**`fontFamily` and `fontSize` are the only non-color `themeVariables`**, and they are
deliberately not mirrored into `mermaid-palette.json`. That file catches hex drift, and a font
stack has no hex to drift. `fontSize: '1rem'` tracks the reader's root size, where mermaid's
default is a hard-coded 16px.

**`background` is inert.** It is set to `--code-bg` to match the `pre` a diagram used to render
in, but a sweep across 12 diagram types (flowchart, pie, ER, class, sequence, state, gantt,
journey, quadrant, gitGraph, mindmap, timeline) showed it never reaches the output. Every SVG
canvas is transparent, there is no full-size background rect, and the hex appears nowhere in
mermaid's injected CSS. It is correct by intent rather than load-bearing.

**The sequence note is themed as of v1.17.0. For four releases it rendered mermaid's stock
yellow.** `themeVariables` covered nodes, clusters, edges and pie slices but nothing in the
`note*` family, so a `Note over` came out fill `#fff5ad`, text `#333`, border `#f9f7e6`: the only
light surface on an otherwise dark page, at every width on both fixtures. `noteBkgColor`
`--code-bg`, `noteTextColor` `--on-surface` and `noteBorderColor` `--rule-light` put the note on
the same footing as a node, with the lighter rule weight around it so it reads as an annotation
rather than a second node.

**`actorTextColor` is not needed, and nothing paints the actor label twice.** A
`querySelectorAll('text,tspan')` sweep returns each actor name twice, once computing `#343746`
and once `#f8f8f2`, which reads like a dark layer hidden under a light one. It is not. Mermaid
emits one `<text class="actor actor-box">` that wraps one `<tspan>`, the sweep matches both, and
the parent `text` has no direct text child to paint. Setting `actorTextColor: '#f8f8f2'` moved
neither value, so it is not in `mermaid.js`. A themeVariable that changes nothing still has to be
kept in step by two CI gates. **Probe a `tspan`, not its parent `text`,** before you believe this
one again.

**The CDN pin is 11.16.1, and the bump from 11.16.0 was pixel-identical.** Both versions of both
fixtures rendered at 390 / 768 / 1280 / 1920 / 2560 and were diffed on every SVG box, text-node
width and node-label overflow: zero differences, zero console errors, and three zoom buttons in
both. It is a patch release (prototype-pollution hardening GHSA-c4c3-pg64-4m4v, a `compileCSS`
sibling-combinator fix, and architecture-diagram ordering), and it deprecates
`mermaidAPI.setConfig()`, which this template never called.

### Label measurement

**`fontFamily` is set at the top level of the config *as well as* in `themeVariables`, and both
copies are load-bearing.** The themeVariable reaches the CSS that mermaid injects, so it decides
what paints the labels. The root one is what `calculateTextDimensions` measures with, so it
decides how wide a label box computes to be. With only the themeVariable set, every box was sized
for mermaid's default `"trebuchet ms", verdana, arial` and painted in monospace, 1.31× wider than
its box: a sequence `Note over` rect came out 235px around 307px of text. The root `fontFamily`
took it to 327px, and it measures 404px today. **The measurement font is the render font, or the
arithmetic is wrong.**

`sequence.noteFontFamily` and `noteFontSize` are **not** the fix. `initialize` accepts them and
`getConfig()` reads them back, but through 11.16.1 they change nothing. A sweep of
`noteFontSize: 26` and `noteFontFamily: 'Courier New'` left the rect at exactly 235px in all
three cases, and a re-sweep on 11.16.1 left it unmoved at 404px.

### Diagram sizing

Label size follows SVG scale, so both ends of the viewport range are the same bug.

**Wide end: `pre.mermaid svg { width: 100% }`** stretched a viewBox'd SVG to its container and
multiplied the label size with it: 13.9px at 390px, 36.8px at 1280px, and **51.7px at 1920px**,
which is 1.35× the h1, set by nothing but how few nodes the graph had. `width: auto` pins labels
to the size mermaid asked for. `max-width: 100%` still shrinks a graph too wide to fit.
`text-align: center` keeps a small one centered, in **both** layouts. It once lived on
`body.conn-map` only, so an inline diagram narrower than its column hugged the left edge in the
default layout. `fontSize: '1rem'` alone does not fix it, because that still gives 47.1px at
1920px.

**Narrow end (v1.17.0): below 600px the diagram renders at natural size and scrolls.** At 390px
against 16.2px body copy, the sequence diagram's label box measured **8px** and the quadrant
chart's measured **13px**: diagram text at half the size of the prose it illustrates. At 600px
and below, `pre.mermaid` takes `overflow-x: auto` and the SVG drops its cap, which gives 18px
labels at 320px and 390px and puts the sequence SVG at 764px inside a 351px column, scrolling
inside itself.

**The natural width comes from a custom property, because CSS cannot otherwise recover it.** With
`useMaxWidth` at its default, mermaid writes `width="100%"` as an attribute and its real size as
an inline `max-width: 764px`. Two attempts failed first:

1. `width: auto` plus `max-width: none`. An SVG with a viewBox resolves `auto` to its container,
   so the diagram stayed 351px wide at 390px and the labels stayed 8px.
2. A copy of the inline `max-width` into the inline `width`. That broke the band *above* the
   breakpoint: at 768px the diagram became a fixed 764px inside a 691px column and overflowed
   under `overflow: visible`, which is a page-level sideways scroll, the one thing the width work
   exists to prevent.

So `mermaid.js` copies the inline `max-width` into `--natural-width`, which has no layout effect
of its own, and the rule at 600px and below reads `width: var(--natural-width, auto) !important;
max-width: none !important`. The fallback covers `body.conn-map`, whose fences set `useMaxWidth:
false` and therefore carry a real width attribute and no inline `max-width`. `!important` fights
mermaid's own inline styles, which is the same reason the pre-existing `body.conn-map pre.mermaid
svg` rule carries it. That selector repeats inside the media block because it is more specific
*and* `!important`, so source order alone would not win. Verified: identical diagram widths at
601 / 768 / 899 / 900 / 1280 / 1920 / 2560px, and no document-level sideways scroll on either
fixture at 320 / 390 / 600 / 601 / 768 / 899 / 900 / 1280 / 1920 / 2560px, or at 200% text zoom
at 390px.

**`pre.mermaid svg { overflow: visible }` exists because some diagram types write a viewBox that
does not contain their own content.** The outermost `<svg>` gets `overflow: hidden` from the UA
stylesheet, so anything outside the viewBox is clipped rather than merely untidy. `quadrantChart`
forced it: a fixed `0 0 500 500` from `chartWidth` and `chartHeight`, with point labels centered
on the point, so a long label overruns the canvas by 70.2 user units left and 99.8 right, and the
browser slices off both. `pre.mermaid` needs the declaration too, or the inherited `overflow-x:
auto` clips at the same place, and `.mermaid-overlay svg` needs it, or the zoom shows the
truncation it was opened to escape.

**The cost of the narrow-width scroll container is that those labels clip below 600px.**
`overflow-x: auto` forces computed `overflow-y` to `auto`, so `visible` stops applying there.
That is accepted: at that width the labels were present but 13px, and the zoom overlay shows the
whole diagram at 95vw either way. Above 600px nothing changed.

**A JS `refit()` that grew the viewBox to the measured `getBBox()` was tried and reverted.** Run
from the existing `MutationObserver`, it fires when mermaid inserts the SVG, before the
flowchart's `foreignObject` labels have laid out, so the bbox is enormous: viewBox `0 0 368 …`
became `0 0 25727 27839` at 1280px, and the inline `max-width` was dragged to 25727.2px, scaling
with the viewport because the unstyled labels did. To get it right you need a settled-layout
signal that the observer does not have. One CSS declaration needs no timing at all.

### Zoom

**The clone is stripped of mermaid's own sizing** so that the overlay's CSS governs every diagram
identically. `calculateSvgSizeAttrs` writes `width="100%"` plus inline `max-width:NNNpx` when
`useMaxWidth` is true, and `width` and `height` attributes when it is false, which is what the
connections maps set. An inline `max-width` outranks the stylesheet, so left in place the zoom
magnifies in one layout and does nothing in the other. `setupGraphViewbox` always emits a
viewBox, and that is what scales. The overlay sets `width` and `height`, not `max-*`, because
`max-width` alone leaves a small diagram at natural size, which is a zoom that does not zoom.
Verified at 95% × 95% in both layouts.

**The zoomed diagram's halo is tinted, because a pure-black shadow only looked right in one
palette.** It was `drop-shadow(0 0 24px oklch(0 0 0 / 0.5))`, written when dark was the only
palette. The scrim behind it is `oklch(from var(--surface-alt) l c h / 0.92)`, and light
`--surface-alt` is `oklch(0.940 0.006 106.545)`, so from v1.25.0's light mode a zoomed diagram sat
on a near-white plate wearing a black halo. A zero-offset 24px blur is a glow rather than an
elevation shadow, and an untinted one picks up none of the surface it falls on. The value is now
`oklch(from var(--surface-alt) 0.15 c h / 0.5)`: absolute lightness, chroma and hue inherited from
the scrim. Dark resolves to `oklch(0.15 0.019 280.395 / 0.5)`, which is the near-black it always
was with the palette's own blue in it. Light resolves to `oklch(0.15 0.006 106.545 / 0.5)`, a dark
warm neutral that belongs to the page. `oklch(from …)` adds no new dependency: `--purple-bright`,
`--highlight` and the scrim itself already use relative color syntax.

**The close mark honors the safe-area insets, because the overlay is the sheet's only fixed
layer.** `.mermaid-overlay::after` draws the ✕ at `top: 0.75rem` and `inset-inline-end: 1rem`, and
`position: fixed; inset: 0` puts it in the one place a notch, a rounded corner or a status bar can
land on top of a painted glyph. Both offsets are now `max()` against `env(safe-area-inset-*)`, the
same form `--gutter` already uses, and the inline-end offset lists both physical insets for the same
reason `--gutter` does: `env()` has no logical spelling. On a device that reports no insets the
`env()` terms resolve to `0px` and `max()` returns the original values, verified as computed `12px`
and `16px`. Not verified on hardware with a real notch. The ✕ stays a pseudo-element rather than a
button: the whole overlay dismisses on click and `Escape` closes it, so a control there would add a
second path to the same action and a focus stop inside a dialog whose only content is a diagram.

`securityLevel` defaults to `strict`, which sanitizes `click` directives away. A consumer with a
trusted source sets `window.mermaidSecurityLevel = 'loose'` in a preceding classic script tag.
The overlay throws loudly when `#mermaid-zoom` is missing, because without that check the zoom
dies on a bare `TypeError` that points nowhere near the missing element.

**The `pre` itself is a named, focusable region as of v1.17.0.** It takes `tabindex="0"`,
`role="region"` and an `aria-label` when the button is injected, because below 600px the `pre` is
a sideways scroll container and `README.md` already requires a reachable, named stop for those
(WCAG 2.1.1). The name is the fence's own `accTitle:`, which falls back to the translatable zoom
label. A diagram's title beats a button verb, and it is already an author obligation.

### Newer diagram types

The v1.13.0-era sweep covered 12 diagram types. Mermaid has since shipped `kanban`, `radar`,
`sankey`, `packet`, `block` and `treemap`, none of which had ever been rendered against this
palette. v1.23.0 closes that gap: `mermaid-cli@11.16.0` rendered all six with the exact
`themeVariables` this file carries, and every hex in the output was diffed against
`mermaid-palette.json`'s 17 values. Three came back clean once the dead paths were ruled out:
`kanban`'s stray `#efefef` sits in an unused `.disabled` rule inherited from the shared style
bundle, `treemap`'s stray `#efefef` default is a compile-time fallback that never reaches a rect
(each section and leaf gets a computed `hsl()` fill instead), and `radar`'s `graticuleColor`
default never painted anything the sweep's two-curve, three-axis fixture produced. `sankey` and
`block` come back tinted by d3's Tableau10 categorical scheme (`#4e79a7`, `#f28e2c`, `#cbc8b9`,
…) rather than any `themeVariable`. That is d3-scale-chromatic auto-coloring nodes with no
config surface in front of it, the same shape of decision as the pie-slice ramp but with no
override, and is left alone for the reason [Color and the contrast
budget](#color-and-the-contrast-budget) already gives: nothing puts a category fill beside body
copy, so the collision costs little.

**`packet` came back genuinely broken: white-on-white in spirit, `#efefef` blocks with `black`
text on a dark page.** `defaultPacketStyleOptions` in `src/diagrams/packet/styles.ts` hard-codes
`startByteColor`, `endByteColor`, `labelColor`, `titleColor` and `blockStrokeColor` to `"black"`
and `blockFillColor` to `"#efefef"`, and neither `mermaid.initialize({ packet: {…} })` nor a
`%%{init: {"packet": {…}}}%%` fence directive moves any of them, verified two ways on
`mermaid@11.16.1`: the CLI's `-c` config file and an inline directive both leave
`.packetBlock{fill:#efefef}` in the emitted `<style>` unchanged. This is the same shape of defect
`sequence.noteFontFamily` already is in [Label measurement](#label-measurement), where the config key
exists and is silently inert, except that here nothing themes it at all, ever, not even by accident,
so the fix cannot wait for a future mermaid release the way the sequence note's four-release wait
did. `tufte-dracula.css` now overrides mermaid's own injected rule directly:

```css
pre.mermaid :is(.packetByte, .packetLabel, .packetTitle) { fill: var(--on-surface) !important; }
pre.mermaid .packetBlock { fill: var(--code-bg) !important; stroke: var(--purple) !important; }
```

`!important` is required and is not a shortcut taken for convenience: mermaid's injected style
is scoped `#my-svg .packetBlock`, at (1,1,0), and a plain page-level `.packetBlock` rule at
(0,1,0) loses that specificity fight even though it comes later in the DOM. The pattern already
exists in this file for the same reason, because the `--natural-width` rule fights mermaid's own inline
`max-width` the same way, so this is not a new kind of override, just the second place mermaid's
CSS has to be out-muscled rather than configured. Verified by rendering to PNG and sampling
pixels, because the exported SVG's own embedded `<style>` text does not change even when an
external stylesheet visually overrides it on screen: the block fill measured `#efefef` before the
CSS and `#343746` after, at the same coordinate, and the anti-aliased edge around the label text
shifted from black-white blends (`#ababab`, `#222223`) to purple-white blends (`#8975ae`,
`#60537a`), confirming the text itself repainted and not just the box behind it. No hex needed
adding to `mermaid-palette.json`: every value reused is already a `var()` token from the CSS side
of the palette, not a new literal, so check 4 of `.github/palette-check.py` has nothing new to
drift. `samples/dark.html` carries a `packet-beta` fence for the same reason the sequence and quadrant
fences exist. The bug shipped invisibly because nothing had ever rendered the diagram type
before, and a fixture that never uses a component cannot catch a regression in it.

**`xyChart`'s bars and line render in mermaid's own default pastel palette (`#fff4dd`,
`#ffd8b1`, …), and there is no fix for it here.** `xyChart.plotColorPalette` has the identical
defect as `packet`: setting it through `initialize()` or a fence directive changes nothing,
verified the same two ways. Unlike `packet`, there is no CSS door in: the bars and the line are
plain `<rect>` and `<path>` elements with a literal `fill`/`stroke` attribute and **no class
attribute at all**, so there is no selector narrow enough to hang a `!important` override on
without also recoloring every unclassed shape another diagram type might emit. Take this when
mermaid ships a fix upstream, or when a consumer's real page needs an `xychart-beta` fence badly
enough to justify a per-diagram `<style>` scoped by a hand-added `id`, not by widening a
selector on the shared sheet.

## Connections-map layout

`body.conn-map` has exactly two sections in order: **(1) Links, (2) Graph**. For a topic map the
Links column holds the antecedents and descendants of the focus. For a year-slice map it holds
the drawn items, newest first. Above 900px Links sits left and sticky and the graph sits right.
Below 900px they stack.

**Markup order is the layout order. The stylesheet no longer reorders.** Until v1.8.0 the markup
was (1) Graph, (2) Links, and the CSS reversed it with `order: 1` and `order: 2`, so the visual
leading column was Links while the tab order and the screen-reader order started in the graph on
the right. Measured at 900px and 1280px: Links at x=45 and x=64, Graph at x=305 and x=386,
against the reverse DOM order. A sighted keyboard user tabbed away from where their eye had
started. Deleting the two `order` declarations and swapping the sections produces a
pixel-identical layout, verified at 899 / 900 / 1280px, with Links 220px to 282px sticky at the
leading edge and the sticky column holding at y=120 after a 1200px scroll, and now the reading
order and the visual order agree.

**That was a breaking change for consumers, and the break is silent.** A page emitted with the
old (Graph, Links) markup that inlines a v1.8.0 or later stylesheet renders with the graph in the
narrow sticky column and the link list filling the page. Nothing errors. Support for both orders
behind `:has(> .links)` was rejected, because that is two layout paths in a file every consumer
inlines verbatim.

**The article sets layout only, never width.** It previously carried `width: min(96vw, 1600px);
max-width: 96vw; left: 50%; transform: translateX(-50%)`, which broke out of the page container
to be *wider* than the default layout. A connections map and an ordinary page therefore never
shared a left edge, and the 1600px cap silently disagreed with the body's own cap. `pre.mermaid`
broke out a second time to `90vw`. Both breakouts were **deleted rather than ported**. The
container is `--page-width`, which is 90vw, so there is nothing left to escape to, and the SVG
renders at natural size, so extra container width no longer changes the diagram. Verified: body
width, article width and h1 left edge are identical across both fixtures at eight viewports.

**The full-width row is `article > *`, not an allow-list of three selectors.** It was
`> h1, > .byline, > .subtitle`, so *any* other direct child silently joined the two-column flex
row instead of spanning it. Measured at 1280px with a bare `<p>`, a third `<section>` and a
`<footer>` injected: the paragraph landed at `x=64 w=471` beside the Links column, and the three
sections split the row 282 / 168 / 112px. That is the same silent-visual-break class as the
section-order change, and a generator that grows a footer triggers it without touching the
stylesheet. `> *` at (0,1,2) loses to `> section:nth-of-type(1)` at (0,2,3), so the column rules
still win and the shipped layout is pixel-identical, with Links at `x=64 w=282` and the graph at
`x=386 w=830`, and the three extras each span the full 1152px. The change also retired
`.subtitle`, which had a rule here and no user anywhere in the repo. A class a consumer has to
guess at is worse than no class.

`overflow: visible` on `pre.mermaid` is unconditional as of v1.13.0, so the conn-map-only copy of
that rule is gone. The base `pre` rule's `overflow-x: auto` would otherwise clip a diagram's drop
shadow, which is the same reason the label-clipping fix needs it.

**The sticky column had no height ceiling until v1.25.0, so it stopped being sticky at real
content lengths.** `position: sticky` pins nothing when the element is taller than the viewport: it
scrolls with the page like any block. Measured at 1280×800 with 40 antecedent links, which is an
ordinary size for a topic map: the column computed 4132px against a 713px viewport, and after a
2000px scroll its top sat at −1880px. Nothing was clipped and every link stayed reachable, so the
failure was silent. The column simply scrolled away, and the two fixtures never showed it because
four links fit twice over.

The column now takes `max-height: calc(100vh - 2rem); overflow-y: auto; overscroll-behavior:
contain`. Re-measured at the same viewport with the same 40 links: `max-height` resolves to 681px,
the box pins at `top: 16px` after a 1200px scroll once the graph column gives the article range to
pin over, the column's own `scrollHeight` is 4132px, and the fortieth link is reachable inside it.
Where the article is *not* taller than the column, the whole map now fits one screen and sticky has
no work to do, which is the outcome that was wanted anyway.

**`tabindex="0"` was deliberately not added, and this is the one place the sideways-scroller rule
in `README.md` does not apply.** That rule exists for a `pre`, a wide table and a
`math[display="block"]`, whose overflowed content holds nothing focusable, so a keyboard user has
no way in. The Links column holds links. Focusing one scrolls it into view, so the column's content
is reachable by Tab alone, and a tab stop on the container would add a stop that announces a region
a reader is already inside. `overscroll-behavior: contain` matches `.table-scroll` and stops the
scroll chaining to the page at either end.

## Interaction states

**The press feedback on `.nav-list li a` was inert for two reasons, and measurement found both.**
It read `:active { transform: scale(0.96); transition: scale 0.12s ease-out }`. The transition
named the independent `scale` property while the rule set `transform`, so nothing animated. A
sample every 25ms through a real mousedown gave `transform: matrix(0.96, 0, 0, 0.96, 0, 0)` on
the first frame and an identical value on all six. The declaration also sat inside `:active`, so
it vanished with the state: `transform: none` 30ms after mouseup. Press and release both snapped.
It is now `scale: 0.96` in `:active` with the transition on the base rule: 0.987 to 0.976 to
0.968 to 0.962 to 0.96 on press, and 0.964 to 0.976 to 0.987 to 0.995 to 0.999 on release. **A
transition belongs on the resting rule, and `transform` and `scale` are different properties.**

**`.mermaid-zoom` was the one control outside that language.** It is the only real `<button>`
here, and it had neither thing every other interactive surface has. Its `:hover` color and fill
changed with no transition while `a` and `summary` ease at 0.15s, and it had no press state at
all. It now carries `transition: color 0.15s ease-out, background-color 0.15s ease-out, scale
0.12s ease-out` on the resting rule plus `scale: 0.96` in `:active`, measured 0.987 to 0.973 to
0.963 to 0.96.

**`[tabindex="0"]:focus-visible` is in the focus rule, because the one stop this sheet does not
own is the one consumers are told to add.** `README.md` requires `tabindex="0"` on anything that
scrolls sideways, and neither the `pre` nor a future table wrapper has a selector of its own.
Before the change, the focused `pre` fell back to Chromium's `1px auto rgb(0,95,204)` at `0px`
offset, against `2px solid --link` at `2px` offset everywhere else. That is not a contrast
failure, because the default ring paints a white line first at 14.24:1 against `--surface`, so
this is consistency alone. After the change the `pre` ring reads `rgb(143,201,217)` at 7.81:1,
and the attribute selector covers the wrapper before it exists.

**No `border-radius` in the `:focus-visible` rule.** It carried `border-radius: 3px`, which made
`.filter-box` corners tighten from 4px to 3px at the moment the ring appeared, and it applied
unevenly: `.nav-list li a` at (0,1,2) outranks `a:focus-visible` at (0,1,1), so nav links kept
2px while plain links took 3px in the same keyboard state. Chromium already rounds an outline to
the element's own radius plus offset, so the removal is what makes the ring follow each surface.
Verified by Tab: `a`, `summary` and `.filter-box` all render `solid 2px` at `2px` offset, and
inline links get square-cornered rings, which is the shape of an inline box.

**`.nav-list` radius is `calc(var(--radius-sm) + 0.3rem)`**, not `var(--radius)`. The outer radius
is the inner radius plus the padding: the child link is 2px inside 4.8px of padding, so 6.8px is
concentric where a flat 4px left the hovered row's corners pinched against the container's. The
`calc` tracks the padding, so a change to one follows in the other.

**`pre.mermaid:hover` gets a 1px `--rule-light` ring.** Before it, `cursor: zoom-in` was the
*only* signal that a diagram was clickable: `tabindex` null, `role` null, no hover rule, and no
focus style. A cursor does not exist on touch and nothing announces it, so on a phone the diagram
was an unmarked click target. The ring is instant and not transitioned, because hover is
high-frequency and does not want motion.

**The overlay's way out is a `✕` glyph on `.mermaid-overlay::after`**, in the top-trailing corner,
in `--label` on the backdrop. Click-anywhere and Escape both dismissed it before and still do,
but nothing advertised either one, and `cursor: zoom-out` is invisible on touch. It is a glyph
rather than a word because consumers inline this stylesheet verbatim and cannot translate a
string in it, and it uses `content: "✕" / ""` behind `@supports` for the same reason the outbound
arrow uses that pattern. Measured through CDP `Accessibility.getFullAXTree`, zero nodes name the
glyph, so nothing tells a screen reader about a control it cannot reach. It is a cue on an
already-clickable surface, not a new target.

The overlay is `transition: opacity 0.2s ease-out`. With the default `ease` the backdrop measured
0.026 to 0.497 to 0.80 to 0.94 to 0.999 at 40ms intervals: near-invisible for the first frame,
then a rush, so the click felt late. Every other transition in the sheet was already `ease-out`.

## Keyboard and assistive technology

**Zoom is a real `<button>` that `mermaid.js` injects, not a focusable `pre`.** Before it, the
only way to zoom was a click on the SVG. `tabindex` was null on both `pre` and `svg` with zero
focusable descendants, so Tab produced 12 stops in `samples/dark.html` and none of them was the diagram
(WCAG 2.1.1). Two cheaper fixes were rejected:

- `tabindex="0"` plus `role="button"` on `pre.mermaid` makes the button's content
  presentational, which hides the SVG's own `graphics-document` node and its name. The control
  would work and the diagram would stop existing.
- `tabindex="0"` with no role leaves a focusable generic, and `aria-label` cannot name
  `role=generic`, so it announces nothing and nothing hints that Enter zooms.

The injected button is a native control. It gets keyboard and pointer support for free, it has an
accessible name of its own, it leaves the SVG untouched, and it doubles as the touch affordance
that `cursor: zoom-in` could never be. Measured 138×42, in the tab order, with a focus ring from
the shared `:focus-visible` rule and `display: none` in print.

**The observer that creates it has to be idempotent.** Mermaid rewrites the `pre`'s children
after the first render, so a one-shot `if (pre.dataset.zoomable) return` guard let the second pass
delete the button and then blocked a recreation: `dataset.zoomable` set, zero buttons in the DOM.
It now re-adds the button whenever one is missing, and it marks the *SVG* rather than the `pre`
for the click listener, so appending the button, itself a `childList` mutation, is a no-op on the
next tick instead of a loop.

**The overlay is a modal and now says so.** It measured `role` null, `aria-modal` null, no name,
no `tabindex` and `overscroll-behavior: auto`, with focus never entering and never returning. It
now carries `role="dialog"`, `aria-modal="true"`, an `aria-label` and `tabindex="-1"`, it takes
focus on open, it sets `inert` on every other `body` child, and it restores focus to the button
that opened it. `overscroll-behavior: contain` keeps the page underneath from scrolling.

**It is `inert` while closed, and that is what keeps it out of the page.** `role="dialog"` fixed
the open state and broke the closed one. The overlay is only `opacity: 0; pointer-events: none`
and never hidden, so it stayed in the accessibility tree between zooms. Measured closed:
`display: flex`, `visibility: visible`, `hidden: false`, and `{role: "dialog", name: …, ignored:
false}` sitting **first in the tree**. Every generated page opened with a permanently open empty
modal, and `aria-modal="true"` is a page-wide instruction to disregard everything outside it.

`overlay.inert = true` at init, `false` in `zoom()`, and `true` again in `dismiss()`. One property
drops the node from the accessibility tree *and* blocks hit testing, and it does not interfere
with the opacity transition. Verified: zero `dialog` nodes while closed, with the first unignored
roles `main` and `article`. On open it is present, named and focused, with both siblings `inert`.
Escape restores `inert: true` and returns focus to `.mermaid-zoom`. `aria-hidden` was not used,
because it hides from assistive technology while it leaves the element focusable, which is the
defect it would paper over.

**The zoom button is named from the diagram, not from a constant.** `textContent` was a hard-coded
`'Zoom diagram'`, so a page with two diagrams exposed two identically named buttons, verified in
the AX tree by adding a pie chart to `samples/dark.html`. The distinguishing text already existed and
was being thrown away: mermaid writes each fence's `accTitle:` into the SVG's root `<title>`,
which is exactly the obligation `README.md` demands. `aria-label` is now `label + ': ' + title`
(`'Zoom diagram: Decision flow sample'`), with the visible text left short. The overlay takes the
same name on open, and the `pre` region takes the bare title.

`window.mermaidZoomLabel` overrides the label word, which follows the
`window.mermaidSecurityLevel` convention. Both strings were hard-coded English in a file
consumers inline verbatim, the same constraint that made the overlay's close cue a glyph. A glyph
could not carry this one, so the override is the way out.

**`accTitle` and `accDescr` are consumer obligations, and both fixtures model them.** The SVG had
a `graphics-document` role with no accessible name at all. These are fence directives, so no
stylesheet change can supply them.

**The sidenote margin-toggle is inert by design, and its two `display: none` rules must stay.**
`input.margin-toggle` is never focusable and the ⊕ label is hidden, so the Tufte collapse pattern
does nothing here. Measured at 1280px and 390px, `.sidenote` is `display: block` at every width.
The rules are not dead weight, because consumer generators emit that checkbox and label markup,
and a drop of the rules would show raw checkboxes on every published page. What *was* dead is
gone: `label.margin-toggle:focus-visible` could never match a `display: none` label. A revival of
the pattern needs a focusable control, not a hidden checkbox.

## Direction, zoom and growth

**Sidenotes float to the inline end, with the physical value first as the fallback:** `float:
right; float: inline-end; clear: right; clear: inline-end`. Under `dir="rtl"` the old
physical-only rule kept the note on the page's right with a 24px `margin-left`, while the `pre`
and `aside` accent bars, already logical, flipped correctly. After the change, `float` computes
`inline-end` in both directions, the note renders page-right in LTR and page-left in RTL, and the
24px gap moves from `margin-left` to `margin-right`. The duplicate physical declaration is
deliberate: a browser that cannot parse `inline-end` drops that line and keeps the LTR behavior it
had before. `margin` became `margin-block` and `margin-inline` for the same reason.

**`th` and `td` are `text-align: start`, not `left`.** With `left`, every cell stayed left-aligned
in RTL while the prose around it flipped. Verified by range-measuring the header text inside its
cell: LTR starts 10px from the cell's left edge, and RTL starts 10px from its right. (`.num` uses
`end` for the same reason.)

**`h1`, `h2` and `h3` carry `overflow-wrap: break-word`.** They were the only text in the sheet
without a break rule, since `a`, `code`, `cite` and `.sidenote` all had one, so a long title word
ran off the page under text-only zoom. At 320px with the root at 32px, `h1` measured `scrollWidth
301` inside `clientWidth 262`, and the connections-map title pushed the document to 367px. After
the change the conn-map fixture reflows clean at 200% text zoom and overflows by only 23px at
400%.

**`--gutter` folds the safe-area insets at every width, not only under 600px:** `max(2rem,
env(safe-area-inset-left, 0px), env(safe-area-inset-right, 0px))`. A landscape phone is 700px to
950px wide, which is above the mobile breakpoint, with lateral insets around 44px to 50px, larger
than the 32px gutter that used to apply there, so text ran under the notch. The `0px` fallbacks
inside `env()` are load-bearing: without them, a browser that does not support the variable makes
the whole custom property invalid at computed-value time, which takes `width: min(100% - 2 *
var(--gutter), …)` down with it. This is unverified on a real device, because Chromium does not
emulate the insets.

**A container query fixes the `.scorecard` overflow under text-only zoom, not a media query.**
`section:has(> .scorecard)` becomes an inline-size container, and `@container (max-width: 15em) {
.scorecard { grid-template-columns: minmax(0, 1fr) } }` stacks it. `em` inside a container query
resolves against the *container's* font size, so the query really asks "is the text large
relative to the space", which is exactly the failure condition and something a media query cannot
see. In a media query `em` resolves against the browser's initial font size, and a `max-width:
19em` media rule measured no change at a doubled root.

Two things about that rule are load-bearing:

- **The `:has()` scoping.** `container-type: inline-size` on every `section` also applied
  inline-size containment to the conn-map columns, which changed the sticky sidebar from 276px to
  220px at 200% zoom, because the content could no longer expand the flex basis. Scoped to the
  sections that actually hold a scorecard, the conn-map measures identically at all eight widths.
- **Its source position, after the `max-width: 600px` block.** Container queries add no
  specificity, so source order is what makes it win over the two-column rule there.

Two attempts on the same problem failed, and they are recorded so that nobody retries them.
`minmax(0, max-content)` tracks let the *track* shrink to zero without the `.verdict` chip
shrinking with it: `174px 0px` at 320px, with the chip spilling out of a zero-width column, which
is a different failure rather than a smaller one. `auto` tracks plus `overflow-wrap: break-word`
moved the number about 40px and fixed 601px only, because `break-word` does not reduce a box's
min-content contribution, while `anywhere` does.

The fix holds through 200% text zoom at every width from 320px to 2560px, and it was re-verified
after the scorecard's border-to-bar change at 320 / 390 / 480 / 601px with the root doubled: the
document sits at viewport width and the grid still collapses to one track. At **400%** text-only
zoom the page still scrolls sideways, from `.sc-note` and from the table at 601px and above. That
is past what WCAG 1.4.4 asks for, and nobody chases it.

## Cascade layer

**The whole sheet sits in one layer, `@layer tufte-dracula`, as of v1.24.0.** A consumer inlines
this payload and then writes CSS of their own. Before the layer, that override had to win on
specificity, and the sheet made that harder than it looks: the syntax-highlight groups are
`0,2,0`, most component rules are `0,1,1`, and a consumer writing `h1 { color: … }` at `0,0,1`
lost. The usual answers are to raise the consumer's selector or to reach for `!important`, and both
are worse than the problem. A layer settles it by origin instead of by weight. **Unlayered author
styles beat every layered author style for normal declarations, whatever the specificity.** So
`h1 { color: … }` in a consumer's own `<style>` now wins, and nothing in this sheet has to move.

Verified against `samples/dark.html`: a bare `h1 { color: rgb(0, 255, 0) }` added after the payload
paints the heading green, and no `--pink` pixel survives in the heading box.

**The `!important` declarations became harder to override, not easier, and that is the trade.** In
the important half of the cascade the layer order reverses: unlayered `!important` has the *lowest*
priority, so the six `!important` rules in this sheet now beat a consumer's unlayered `!important`.
Six is the whole list, and each one exists to beat something a consumer cannot reach either.
Five fight Mermaid's inline `style` attributes on a generated SVG, which nothing but `!important`
can reach. The sixth is `.filter-hidden { display: none !important }`, where a consumer overriding
it means a filtered row stays on the page. A consumer who genuinely needs to win declares their own
layer ahead of this one. Leaving those rules outside the layer was the alternative, and it was
rejected: three of the six sit inside a media query, so lifting them out means duplicating
`@media (max-width: 600px)` and `@media (prefers-reduced-motion: reduce)` outside the wrapper to
preserve six declarations that no consumer should be overriding.

**One layer, not the four that every 2026 article recommends.** `@layer reset, base, components,
utilities` is advice for a stylesheet a consumer composes from parts and can reorder. This is one
file, inlined verbatim, in a fixed order. Four names would buy internal conflict resolution the
sheet does not need: there was exactly one internal specificity conflict, and it is fixed below by
selector rather than by layer.

**The body was not re-indented.** The wrapper opens on line 3 and closes before `</style>`, and the
376 lines between it keep their four-space indent instead of moving to six. Re-indenting is the
correct-looking change and it rewrites every line in the file, which puts `git blame` on the whole
stylesheet at the layer commit. This repo's discipline depends on being able to trace a declaration
back to the change that made it look that way. NOTES.md is the primary record, but blame is the
index into it. `scripts/build-sample.nu` also slices `:root` with a hard-coded `^    ` de-indent for
`tokens.css`, so the indent that stayed is the indent that needs no second edit.

**`:where(ul, ol, menu):where(:not(.nav-list))` replaced the `:is()` form, and it fixed an inert
rule.** `:is()` and `:not()` both take the highest specificity of their arguments, so
`:is(ul, ol, menu):not(.nav-list)` measured `0,1,1`, because the class weight came from the `.nav-list`
inside the negation, which is not a class the rule ever matches. The very next line,
`li > :is(ul, ol, menu) { margin-block: 0 }`, measured `0,0,2` and therefore **never applied**: a
nested list took the outer `var(--space-3)` margin the whole time. `:where()` scores zero on both
sides, which drops the rule to `0,0,0` and lets the nested-list rule win. Visible in the light
fixture as *nested item* closing up under *Bullet two*.

The other twenty-four `:is()` groups stayed. The layer already gives consumers the override, so
converting them buys nothing outward, and two of them would break: the syntax-highlight groups at
`0,2,0` have to beat a highlight.js or Pygments theme stylesheet that a consumer may also load,
and `:is(h1, h2, h3, h4, h5, h6) :is(a.headerlink, a.anchor)` has to beat the plain `a` rule at
`0,0,1` or every permalink grows an underline. Lowering specificity is not free when something real
is on the other side of it.

## Appearance modes

**`@media (prefers-contrast: more)` reassigns eleven tokens and touches two rules.** The floor the
default palette holds is 4.23:1, which is `--purple` against `--code-bg` and recorded under *Color
and the contrast budget*. The high-contrast block raises every accent to **7:1 or better against
`--code-bg`**, the harder of the two backgrounds, which lands them at 8.49 to 9.41:1 against
`--surface`: `--label` 7.79 on code and 9.41 on surface, `--muted` 7.06, `--link` 7.12, `--orange`
7.09, `--red` 7.03, `--purple` 7.06, `--pink` 7.03, `--green` 7.03. `--on-surface` goes to
`oklch(1 0 0)` for 11.80 on code and 14.25 on surface. `--rule-light` goes to `oklch(0.700 …)`,
which is 4.40 on code where 1.4.11 asks for 3. `--surface-alt` *darkens* to `oklch(0.200 …)`,
because it is the row-hover and tinted-root fill and its job here is to be unmistakable: 1.27:1
against `--surface`, up from 1.18.

Three rules move as well. `a` takes `text-decoration-thickness: max(2px, 0.1em)` and
`text-decoration-color: currentColor`, so the underline stops sitting at `--muted` and reads at the
link's own ratio. `.nav-list li a` repeats that one declaration. The focus ring goes to
`outline-width: 3px`. Nothing else changes, because the palette carries the meaning in this sheet
and a reassignment reaches every element at once, which is the same reason the print block reassigns tokens
rather than elements.

**The `.nav-list` repeat is there because a media query adds no specificity.** The base rule
`.nav-list li a { text-decoration-color: transparent }` scores 0-1-2 and the block's `a` rule
scores 0-0-1, so through v1.24.0 every nav-list link stayed underline-free in the one mode whose
whole purpose is the strongest available cue. Forcing the condition on and reading the computed
value: `transparent` before, `oklch(0.83 0.064 216.782)` after, the same value the prose link
resolves to. The repeat ties the base rule at 0-1-2 and wins on source order, which is the cheapest
fix that does not raise specificity anywhere else in the sheet.

`mark` measures 6.17:1 rather than 7. `--highlight` is `--orange` at 0.35 alpha, and the alpha caps
what the composite can reach. Lowering the alpha to buy the last 0.83 would make the highlight
itself harder to see, which is the one thing the element exists to do.

**`@media (prefers-color-scheme: light)` is a full second screen palette, and it is not the print
palette.** Reusing print was the first attempt and it fails on screen for three reasons.
`--surface` and `--surface-alt` are both pure white there, which is correct on paper and kills
`tbody tr:hover td` and the overlay backdrop on a display. `--code-bg` at `oklch(0.970 …)` is a
paper compromise. And the accents are tuned against white, not against a light code fill.

The screen values, measured against `--surface` at `oklch(0.990 0.006 106.545)` and `--code-bg` at
`oklch(0.960 0.010 277.509)`: `--on-surface` `oklch(0.200 0 0)` at 16.10 on code and 17.61 on
surface, `--label` 6.13 and 6.70, `--muted` 4.74 and 5.18, `--link` 4.78 and 5.23, `--purple` 4.80
and 5.25, `--green` 4.76 and 5.21, `--red` 4.74 and 5.18, `--orange` 4.72 and 5.16, `--pink` 4.71
and 5.15. Every accent clears 4.5:1 on **both** backgrounds, which the default dark palette does
not, since its 4.23 floor is the thing this palette improves on. `--rule-light` is 3.53 on code for
1.4.11. `--surface-alt` at `oklch(0.940 …)` is 1.16:1 against `--surface` and *darker* than it, so
row hover reads the way it does in dark mode. `.verdict` keeps its filled form: near-white on the
light accents measures 5.16 to 5.21:1, so the print block's outlined variant is not needed here.
`::selection` is 5.25. `mark` is 10.83. `--purple-bright` inverts its rule to `calc(l - 0.06)`,
because brighter is *less* contrast on a light ground.

**Mermaid follows the media query, and it does it by reading a CSS token.** `mermaid.js` has to
pass hex, because khroma throws `Unsupported color format` on an `oklch()` string and never resolves
a `var()`. So it carries **two** hex palettes inline and picks one at init:

```js
const mermaidLight = getComputedStyle(document.documentElement)
  .getPropertyValue('--mermaid-scheme').trim() === 'light';
```

`:root` declares `--mermaid-scheme: dark` and the light block overrides it to `light`. That token is
the whole mechanism, and reading it instead of `matchMedia('(prefers-color-scheme: light)')` is the
load-bearing choice. **`matchMedia` reads the host; the token reads the cascade.** The forced-light
sample pages work only because of that: they force the palette by rewriting the `@media` condition in
their own copy of the stylesheet, which `matchMedia` cannot see and a computed custom property
resolves correctly. Anything driven off `matchMedia` would render a dark diagram on `light.html`,
which is precisely the bug that was reported.

The light projection, measured against the light `--code-bg` the diagram is drawn on: node and note
text at **16.10:1**, `nodeBorder` and `primaryBorderColor` 4.80, `lineColor` 4.74, `clusterBorder`
and `noteBorderColor` 3.53. **The `pie1..4` ramp was unchanged across both schemes through
v1.24.0, and that is reversed as of v1.25.0.** The paragraph here used to read: "`--data-1..4` are
pale by design, which reads as 1.69 to 2.15:1 against the light card and is weak separation from the
ground, but each slice carries `textColor` at 7.48 to 9.52:1 and slices abut each other rather than
the background. No fixture has a pie chart, so that pair is derived rather than rendered." The ramp
now has its own light and print values and clears 3.2:1 on the light card. See *Form follows role*
for the solved values, the gate, and what the reversal still leaves undone.

**This replaced a dark-island design, and the earlier approach is worth knowing about because it
looked fine.** The first cut accepted that mermaid could not be re-themed and leaned into it: light
mode handed `pre.mermaid, .mermaid-overlay` the dark palette back as inherited custom properties and
painted `pre.mermaid` a `--code-bg` card, so a diagram read as a deliberate dark plate on a light
page. Custom-property inheritance made it cheap: the zoom button, the packet `!important` fills, the
overlay scrim and the `::after` close mark all resolved to dark with no extra selectors.

It was wrong for three reasons that only showed up on the page:

1. **A dark slab beside a light sidebar reads as broken, not as a plate.** On the conn-map the graph
   *is* the content, and `pre.mermaid` is a block, so the card ran **1009px** wide around a **441px**
   diagram at 1500px, about 570px of dead dark space, next to a light column.
2. **Fixing that needed a rule that could not be generalised.** `width: fit-content` on the card
   shrank it correctly, but only on the conn-map. Rendered on the component sample it clipped
   `quadrantChart`'s deliberately overflowing point labels at the card edge and left the escaped tail
   as near-white text on a light page, and it collapsed `sequenceDiagram` and `packet-beta`, whose
   SVGs carry `width="100%"` with the real size as an inline `max-width`, so a `fit-content` parent
   makes that percentage resolve against a box the SVG is itself sizing.
3. **It needed its own gate.** The dark palette re-declared in that block was a third projection of
   `:root`, so `palette-check.py` grew a check comparing its nine `oklch()` literals against `:root`
   as declaration text.

All three are gone. The card, the `fit-content` rule, the inherited-dark block and that check are
deleted, because a light diagram needs none of them: `pre.mermaid` keeps `background: none`, the
packet `!important` fills resolve to the light tokens on their own, and the overlay scrim was already
derived from `--surface-alt`. **The net change is fewer rules than before the island existed.**

**Both palettes are gated, key by key.** `mermaid-palette.json` gained an `initLight` section whose
every entry names the same token in `from` as its `init` twin, and check 1 of `palette-check.py` now
resolves `init` through `:root` and `initLight` through the light block, refusing either at fewer than
19 keys and failing if the two sections cover different key sets. `contract-check.yml` and
`scripts/maintain.nu check` both pair `mermaid.js` against both sections, 38 rows in total. Check 4,
which asserts every hex in `mermaid.js` is a palette color, accepts either palette. **A drifted light
hex is invisible to anyone reading in dark mode**, which is exactly why it needs the gate rather than
an eye.

**Deleting `--mermaid-scheme` used to fail silently, so check 6 of `palette-check.py` gates it.**
`getPropertyValue` on a missing custom property returns an empty string, which is not `'light'`, so
mermaid renders dark on a light page and every other check stays green, which is the exact defect the token
was added to fix. The check asserts `:root` declares `dark`, the light block declares `light`,
`mermaid.js` reads that token by name, and `mermaid.js` does **not** read `matchMedia`. All four were
tampered with and all four reported. The last one is not pedantry: `matchMedia` looks correct on a
real machine and silently breaks only the forced-light pages, which is the hardest version of this
bug to see.

**A scheme flip without a reload leaves the diagram stale.** The token is read once, at init. The CSS
around it follows the media query live, so a reader who changes system appearance with the page open
gets a light page with a dark diagram until they reload. Re-theming live means re-initialising mermaid
and re-rendering every fence from source, which is a listener, a re-parse and a fresh `MutationObserver`
race for a case that costs one refresh. Take it if a consumer ships an in-page appearance toggle,
because then the flip is a click rather than a system setting.

**A toggle was asked for and refused, because there is nowhere to put it.** The fixtures carry
exactly one `<style>` and exactly two `<script>` blocks, and both counts are gated. The one
`<style>` is `tufte-dracula.css` verbatim. So fixture-only toggle CSS does not exist as an option:
a toggle has to go in the shared payload that every consumer inlines, and it costs either a second
theming convention with the light palette duplicated under it, or a fourth inlined script. Both are
paid by every consumer forever to serve a review convenience. Take it when a consumer asks for a
manual override as a feature, and treat it then as a public API decision covering the selector, the
persistence and the first-paint flash, not as a fixture fix.

**Two generated preview pages carry the light palette to the web instead.** Pages serves this repo
root from `main`, so `samples/light.html` and `samples/light-conn-map.html` are live on merge with no
workflow, no deploy step and no `docs/` directory. `scripts/build-sample.nu` writes each one right after its
fixture, using the rewrite `render-modes.py` already does: the light condition becomes `@media all`
and the contrast condition becomes `@media not all`.

Forcing light alone would very nearly do, because the light block is declared after the contrast
block and overrides every token it sets. It would leave the contrast block's two non-token rules
live, though (the 2px `currentColor` underline and the 3px focus ring) so a visitor who asks for
more contrast would get a preview nobody else gets. A preview exists to show one thing, so the
condition goes off.

**The generator raises when the rewrite no-ops.** If the stylesheet renames either condition,
`str replace` matches nothing, the preview equals the fixture, and Pages serves a dark page called
light while regeneration still compares clean. That is exactly the shape of quiet wrong this repo
gates against, so `scripts/build-sample.nu` errors on it, and `scripts/maintain.nu check` plus CI assert the same
property on the committed file, which is what a hand-edit would get past the generator.

**The banner is the only thing left warning anyone, and that is a real cost of the rename.** These
shipped as `preview-light.html` and `preview-conn-map-light.html`, where the filename carried the
warning: a `preview-` prefix beside `sample-` said which one was not the payload. The four pages were
then unified as `samples/dark.html`, `samples/dark-conn-map.html`, `samples/light.html` and
`samples/light-conn-map.html`, which reads far better as a set and costs that signal. `light.html`
now sits beside `dark.html` in one folder and looks like an equal peer, when its stylesheet has had
its `@media` conditions rewritten and `dark.html`'s has not.

Three things carry the warning instead. Each light page opens with a `markdown-alert-caution` block
that says it is not the payload and links back to its dark twin. CONTRACT.md §1 states it where a
consumer's agent reads, rather than only in README. And the two light pages are deliberately **not**
among the ten contract files, while the two dark ones are. Nothing outside this repo should pin a
page whose media queries were rewritten. **Do not remove that banner to tidy the page.** It is the
last thing standing between a consumer and a stylesheet locked to one appearance.

**No high-contrast preview page.** That block leaves `--surface` alone, so a forced page would look
almost exactly like the dark sample, and a preview that looks like the thing it is contrasted with
teaches nothing. CI renders it and attaches the image to the pull request, which is the right place
for a comparison a person makes once.

**Two gates cover the modes as well, and they cover different halves.** Neither is a screenshot
diff, because layout is identical across the modes and only color moves, so a diff would be noise.

`.github/palette-check.py` **check 6** re-derives the contrast floor for all four palettes on every
run: the default at 4.2, `prefers-contrast: more` at 7.0, light at 4.5, print at 4.5, with rule
tokens at 3.0 against `--surface`. Each mode block only restates what it changes, so the check
overlays the block's overrides on the default palette, which is how the cascade resolves it too.
Every ratio in this file and in *Print* was a hand measurement until v1.24.0, and **a measurement in
prose is not a gate**: one edited lightness value strands text at a ratio nobody re-derives. Text
tokens are checked against both `--surface` and `--code-bg`, because `--code-bg` is the harder
ground and is where the default palette's 4.23 floor lives. Rule tokens are checked against
`--surface` only: `--rule-light` is a hairline on the page background, and 1.4.11 asks 3:1 of that
boundary, not of a border drawn inside a code fill. Verified by tampering with one token in each of
the four modes, and each one reported the mode, the token, the ground and the ratio.

`.github/render-modes.py` covers the other half: that the palette **arrives**. check 6 reads values
and cannot see what a browser paints. **Headless Chrome cannot be told which media query to match**,
it reads `prefers-color-scheme` from the host, so the same command paints dark on a
dark-appearance mac and light on a bare runner, which is no basis for a gate. Confirmed locally:
`--force-dark-mode`, `--force-prefers-color-scheme=dark` and `--enable-features=WebContentsForceDark`
all left the result exactly as the OS had it. So each render rewrites **every** mode condition in a
scratch copy: the target one becomes `@media all` and the rest become `@media not all`, which never
matches. It asserts each condition exists verbatim in the real fixture, so a deleted or misspelled
query still fails, and then asserts the top-left pixel is that mode's `--surface`. Both failure
modes were forced and both reported.

**Neutralising the other conditions is the load-bearing half, and leaving it out failed CI on the
first attempt.** Rewriting only the target looked sufficient on a dark-appearance mac, where the
untouched fixture paints dark and the "dark" case passes. The ubuntu runner reports
`prefers-color-scheme: light`, so there the untouched fixture painted `#fcfcf8` and the dark and
contrast cases both measured the light palette. That is the same host-dependence the paragraph
above describes, arriving through the door it was supposed to close. The check now passes on a dark
host and on a light one, which is two real data points rather than one.

The pixel does **not** distinguish contrast mode from dark, because the high-contrast block leaves
`--surface` alone by design. It raises the accents and darkens `--surface-alt`. Sampling a text
pixel instead means fighting antialiasing for nothing: the condition check already fails on a
deleted query and check 6 already fails on a weakened value. What the contrast render adds is that
the mode paints without error, plus an image to look at.

That pixel read needs no image library. **For the first pixel of PNG row 0 every filter type
predicts from a left byte and an above byte that are both zero, so the filtered bytes are the raw
bytes**: `zlib.decompress`, skip the filter byte, take three. That is why the script has no
puppeteer, no playwright and no PIL, and why `scripts/maintain.nu check` can run the identical step locally.

The renders upload as a pull-request artifact and are **advisory on purpose**. They are not in
`REQUIRED_CHECKS`, because the assertions are the gate and the images are for a person to look at.

**High contrast and light mode do not compose.** `prefers-contrast: more` is declared *before* the
light block, so a reader who asks for both gets the light palette at its own 4.71:1 floor rather
than a high-contrast light palette. That is a deliberate ordering. The alternative is a fourth
palette in a `(prefers-color-scheme: light) and (prefers-contrast: more)` block, which is ten more
measured values for a combination this sheet has never been asked for. The failure mode of getting
the order wrong is much worse: dark high-contrast accents on a white surface, at ratios near 1:1.
Take the fourth palette when a reader asks. Do not reorder the two blocks.

## Print

**The print block overrides the palette tokens, not the elements.** It used to set `background`
and `color` on `body` alone, which left every accent at its dark-theme value on a white page.
Measured on white: `.newthought` **1.05:1**, `summary` 1.82, `.verified` 1.96, `strong` 2.09,
`h3`, `em`, `blockquote` and `footer` 2.11, `h1` 2.42, `.byline` and `cite` 2.60, and `h2` 2.79.
The dark fills survived too, so with background graphics on, near-black text sat on `--code-bg`
fills at **1.67:1**, and with them off, which is Chrome's default, the light text those fills had
backed was stranded on white: inline `code` 1.85:1 and `pre` 1.05:1.

A reassignment of the tokens fixes every element at once and both print paths, because the
accents become dark and the fills near-white. Accent lightness is chosen against the **`0.97`
gray** `--code-bg`, not against white, because that is the harder background: 4.56 to 4.64:1 on
the gray and 4.97 to 5.06:1 on white, with `--on-surface` at `oklch(0.2 0 0)` giving 18.1:1.
`--rule-light` sits at `oklch(0.620 …)`, which is 3:1 against white for 1.4.11 without becoming a
heavy line on paper. `--surface-alt` goes white as well. It is only the overlay backdrop, which
cannot be on screen and on paper at once, but a dark value would park a near-black rectangle in
the print stylesheet waiting for someone to reuse the token.

**Page breaks are controlled as of v1.17.0. Before that, only `h2` was.** Added: `orphans: 2;
widows: 2` on `p`, `break-after: avoid` on `h1`, `h2` and `h3`, which replaces the lone legacy
`page-break-after`, `break-inside: avoid` on `tr`, `blockquote`, `aside`, `details`, `.scorecard`,
`.verdict` and `img`, and `thead { display: table-header-group }` so a table that crosses a page
repeats its header. Verified against a 7-page Letter PDF of `samples/dark.html`: the tree table moves
whole to page 2 and reprints its header there, the scorecard and both callouts stay intact, and
no single line strands.

**`pre` joined that list in v1.20.0, and `math[display="block"]` in the commit after it.** This
paragraph claimed the opposite until v1.24.0, on the reasoning that a code block can be longer than
a page and that `break-inside: avoid` on something that cannot fit would be "either ignored or
overflows", making the guarantee a lie. The first half of that is right and the conclusion is
wrong, which is why the selector went in without anyone noticing the note contradicting it.

Measured on a Letter PDF built to force both cases. A 20-line fence pushed to a page boundary
**moves whole to the next page**, and the `h2` above it comes with it, because `break-after: avoid`
on the heading and `break-inside: avoid` on the fence resolve together. A 200-line fence, which
cannot fit under any placement, **splits across six pages with nothing lost**: the `--code-bg` fill
and the purple accent bar reprint on every fragment, and the text after it follows normally.

So the declaration is honored when the block fits and dropped when it cannot. That is the standard
resolution for an unforced break with no legal alternative, not an overflow and not a silent drop
of content, and it is the behavior you want here: a fence that fits stays whole, and a fence that
cannot fit still prints. The element most likely to need the rule is also the one that degrades
best without it.

**`.verdict` prints as an outlined label**, with `background: none` plus `box-shadow: inset 0 0 0
1px currentColor` and the semantic color moved to `color`. Its fill carried the meaning, and
`color: var(--surface)` would have become white-on-accent: fine with backgrounds on, invisible
with them off. The outline makes the chip identical either way, and each variant keeps its hue at
4.97:1 or better. `.badge` needs no print rule, because it is already an outlined `--label` chip
and `--label` is one of the tokens print reassigns.

The `aside` tint used to need a second exception here, because it composited to `#d9dae1` on
white, where `--label` measured 3.58:1. The tint is gone from the base rule as of v1.9.0, so
`aside { background: none }` has nothing left to override.

## Filter

`filter.js` is the third inlined payload, added in v1.16.0. The stylesheet has shipped
`.filter-box`, `.filter-label`, `.filter-hidden` and `.filter-empty` since the first release, and
consumers always had to write their own handler. The script makes the box work for the one
pattern the fixture documents: an `input.filter-box` followed by a table.

Three decisions are load-bearing:

- **The input wires the table it precedes, found by a forward walk.**
  `input.nextElementSibling` is the table in the normal case, and a forward walk to the first
  following `TABLE` covers a `role="status"` line, or anything else, between them. No `closest()`
  and no id-matching: the script never needs to know a consumer's ids, and the input-to-table
  pairing is the only relationship the markup states.
- **The script creates the empty line rather than requiring it.** A consumer that emits a table
  and a filter box but no `.filter-empty` would silently never show the no-matches state, so the
  script creates a hidden one after the table when none exists. It starts `hidden`, because the
  stylesheet's `.filter-empty` has no `display` declaration, so UA `display: none` is the only
  thing that keeps a freshly created line off the page.

  **It carries copy as of v1.25.0, and until then it did not.** The created element got a class and
  the `hidden` flag and no text, so the branch that exists to prevent a silent no-matches state was
  itself silent. Measured on a page with a filter box, a nav-list and no author-supplied
  `.filter-empty`, filtering to zero matches: every row hidden, `.filter-empty` unhidden,
  `textContent.length` 0, and 16px of blank padding where the line should be. The reader is left
  with an empty list and nothing that says why. It now reads `No entries match. Clear the filter to
  see all entries.`, an orientation and an exit, and the same shape as the fixture's own reference
  copy. It names no query on purpose: an interpolated string would put a bare template in a payload
  that consumers inline verbatim and cannot translate. Author-supplied copy is untouched, because
  the branch only runs when there is none.
- **No CDN, no build step, no comments.** The whole handler is `querySelectorAll` plus
  `classList.toggle`, and consumers inline it verbatim like the other two payloads.

### The one-table scope was reversed in v1.22.0

**Through v1.21.0 this section read: "The filter is one input, one table, one listener. It does not
filter a nav-list, a `details` group, or several tables from one box."** That decision is reversed,
and the reversal is deliberate rather than an oversight of it.

Two measurements forced it.

**The fixture's own filter box was inert, and had been since v1.16.0.** `samples/dark.html` carries
exactly one `input.filter-box`, and what follows it is a `.nav-list` and a `details.nav-group`.
There is no table in that section. The old script walked `nextElementSibling` for the first
`TABLE`, found none, and returned at `if (!table) return`. So the living style fixture, which
`README.md` calls the executable specification, shipped a filter box that never filtered anything
for six releases. No gate caught it: the contract check counts `<script>` blocks and compares
bytes, and neither question is "does the handler bind".

**The scope rule guaranteed that no consumer could ever inherit a fix.** The old text told a
consumer who wanted a different shape to write their own handler over the same classes, and one
did: 41 lines that filter `.nav-list li`, toggle `details.nav-group`, and keep a status count.
That is the decision working exactly as written, and the result is that the largest generator of
Tufte-Dracula pages references two of the three payload files and hand-maintains the third. A
shipped contract file with no reachable user is worse than no file.

**The new scope is the sibling span, not the parent.** From the input, walk forward over siblings
and stop at the next `input.filter-box`, or at the end. Within that span, filter `tbody tr` and
`.nav-list > li`. This keeps the two properties the original decision was protecting: no
`closest()` and no id-matching, so the script still never needs to know a consumer's ids, and the
input-to-content pairing is still the only relationship the markup states. What it drops is the
one-table limit, and with it "several tables from one box". A span that holds two tables now
drives both. A stop at the first structural break would be arbitrary, and stopping at the next
filter box is the rule a consumer can predict without reading the source.

`details.nav-group` open state is captured once at bind time and restored when the query clears,
because a group the script opened during a search must not read as a group the reader opened.

`.filter-box` is `font-size: 1em`, not the old `max(1em, 16pt)`. 16pt is 21.3px, not 16px, and
the iOS-zoom floor is 12pt.

## Nav link separators

`nav > a + a` takes a `border-inline-start` plus symmetric padding in v1.22.0. Before it, a `<nav>`
of sibling `<a>` children rendered as an undifferentiated run of link text, because the sheet
styled `nav` for margin, color and size but never separated its children.

**Neither fixture contained a `<nav>` element at all before v1.22.0**, though `README.md` listed
nav among the components `samples/dark.html` shows. The rule that fixed the run-together nav therefore
shipped unmodeled, and the nav that motivated it lived only in a consumer's output. `samples/dark.html`
now carries seven sibling links, which is enough to wrap at 390px.

**The wrapped-line separator is a known artefact and it is accepted.** The separator is a border on
the link, so a link that begins a wrapped line carries a separator with nothing to its left. No
pure-CSS rule can suppress a border at a line break: the wrap position is not addressable from a
selector, and flex wrapping moves the problem without solving it. The alternatives were a
pseudo-element glyph, which dangles identically, or dropping separators for whitespace alone, which
is the state the rule exists to fix. Seven links in the fixture make the artefact visible at a
phone width rather than hiding it behind a two-link nav.

## Version stamps are not version history

`scripts/maintain.nu bump` replaced every occurrence of the current version string across `README.md`. Six
of those occurrences were historical claims, not stamps: prose of the form "raw HTML is covered as
of v1.21.0" states when a feature landed. The blanket replace walked all six forward on every
release, so v1.22.0's working tree credited v1.22.0 with raw-HTML coverage, Pygments support, the
form-control font fix, the math scroll axis and the markdown-coverage baseline, all of which
shipped in v1.21.0 under commit `36b395d`.

The bump now rewrites three anchored stamps and nothing else: the stylesheet header comment, the
`(template vX.Y.Z, oklch palette)` cell, and the `currently **`vX.Y.Z`**` line. **Each pattern must
match or the bump fails.** A stamp that moves is a loud failure rather than a silent no-op, because
a no-op leaves the tree claiming the previous version while the release verb believes it stamped.

This matters more than a docs tidy. `CONTRACT.md` carries a per-version delta table, which is the
same shape of data, a version paired with a claim about that version, and the blanket replace
would have rewritten every row of it on the next release.

## Unclaimed elements

The sheet styles about forty elements. Four that a document generator can emit were never
claimed, so each rendered in whatever the UA decided. One of those was the same class of bug as
the mermaid sequence note: a light-mode default surviving inside a dark theme because nobody had
looked. Injected into `samples/dark.html` at 1280px and measured before the fix:

| element | rendered as | now |
| --- | --- | --- |
| `mark` | `background: rgb(255,255,0)`, `color: rgb(0,0,0)` | `--highlight` wash, inherited text |
| `caption` | centered (`-webkit-center`), 17.48px, `--on-surface` | start-aligned, 0.9em italic `--label` |
| `figcaption` | plain body copy, indistinguishable from a paragraph | annotation tier, 0.9em `--label` |
| `figure` | no margins at all, because the `*` reset ate the UA's | `var(--space-6)` block rhythm |

**Pure yellow on pure black was the worst of it.** This sheet bans both values everywhere else,
and a highlight is exactly what an annotation-heavy generator emits. `mark` now takes
`--highlight`, a wash rather than a chip: `oklch(from var(--orange) l c h / 0.35)`, which is the
same relative-color syntax `.mermaid-overlay` already uses.

The alpha was swept and pixel-sampled, because a computed style cannot report a composited value:

| alpha | composited fill | body text on it | fill vs `--surface` |
| --- | --- | --- | --- |
| 0.22 | `#504544` | 8.66:1 | 1.54:1 |
| 0.28 | `#5a4d48` | 7.61:1 | 1.76:1 |
| **0.35** | **`#68564d`** | **6.51:1** | **2.05:1** |
| 0.45 | `#7b6353` | 5.25:1 | 2.54:1 |

0.35 is the compromise. The wash reads at 2.05:1 against the page, nearly double the 1.15:1 the
row-hover fill is accepted at, and body copy on it still clears 4.5:1 with headroom. 0.45 reads
as a chip rather than a highlight and costs three points of text contrast.

**`mark` sets `color: var(--on-surface)` rather than inheriting, and that is a contrast fix, not
a preference.** The wash is the sheet's fifth surface and the narrowest. Pixel-sampled on
`#68554d`, `--on-surface` is 6.51 and **every other tier fails**: `--label` 3.83, `--link` 3.81,
`--green` 3.54, `--muted` 2.67. `mark` inherited its color, so a highlight inside an `aside`,
`figcaption`, `dd`, `footer`, `.sidenote` or `section.footnotes`, all `--label`, rendered at 3.83,
and nothing had measured it, because the fixture only ever put a `mark` in body copy. Pinning the
color costs nothing where the wash was already correct, and it fixes six containers where it was
not. **Do not paint the wash under anything but body copy**, which is why the `li:target`
highlight in [Markdown coverage](#markdown-coverage) was measured and dropped. Print inverts the
treatment to `background: none; box-shadow: inset 0 0 0 1px currentColor`, the same
outline-what-was-filled move as `.verdict`, so the mark survives a backgrounds-off print.

**`kbd` is a ringed chip, deliberately not `code`.** It takes the same `--code-bg` fill and mono
face, but `--on-surface` text instead of `--green`, and an `inset 0 0 0 1px var(--rule)` ring. A
shortcut is not a code fragment, and the ring is the only thing that separates them.
Pixel-sampled fill `#343746` with text at 11.06:1. The ring is `--rule` rather than `--rule-light`
because it sits on `--code-bg`, where the lighter weight measures 2.52, which is the rule the
contrast budget already sets. `kbd` joins `code, .verdict, .badge` in the forced-colors border
list, because an inset shadow is the only boundary it has.

**A `caption` sits above the table's frame, not inside it.** `caption` is a child of `table`, so
the table's `box-shadow: 0 -1px 0 var(--rule)` top rule painted *above* the caption and the
caption read as a stray first row. `table:has(caption) { box-shadow: 0 1px 0 var(--rule) }` drops
the top rule when a caption is present, so the caption becomes a label over the table and the
frame starts at the header rule. Verified on screen and in the Letter PDF.

`figcaption` stays start-aligned under a centered diagram, which is why the shared rule sets
`text-align: start` explicitly. `pre.mermaid` is centered, and a caption that inherited that would
float in the middle of a full-width column.

## Markdown coverage

The sheet was written for hand-authored markup and for `html-render.nu`. A consumer can also
point a markdown converter at it, and v1.20.0 is the first release measured against that path.
The probe was a fixture that held every CommonMark and GFM construct in the shape `cmark-gfm`,
`pandoc` and `markdown-it` actually emit, rendered at 390 / 768 / 1280 / 1920 with computed
values read per element. Twelve constructs came back unstyled or wrong.

**Seven were visibly broken.**

| construct | measured before | now |
| --- | --- | --- |
| `#### ` to `###### ` | h4 16.2px/700, h5 13.4px/700, h6 10.8px/700, **all margins 0** | body size, h4 weight 600 then h5 and h6 weight 500, `--label` then `--muted`, h6 italic |
| fenced code block | `pre` margin 0, so two fences merged into one slab | `margin-block: var(--space-3)` |
| any list | `ul` and `ol` margin 0 outside `.indented` | `margin-block: var(--space-3)`, nested lists pinned back to 0 |
| `> [!NOTE]` | `.markdown-alert` unclaimed: border 0, padding 0, `--on-surface` | shares the `aside` rule, hue on the title line |
| `- [ ] item` | `list-style: disc` beside a 13px UA checkbox, no gap | marker dropped, control at 1em with `accent-color` |
| `|:---:|` alignment | `align="center"` computed `start` at all four widths | `[align]` attribute selectors restore all three |
| `$$…$$` as MathML | a wide `math[display="block"]` overflowed the *page*: document scroll 1170 at a 390 viewport, 1359 at 1280 | own scroll axis, `pre`'s margin rhythm |

**`h5` and `h6` were smaller and heavier than body copy.** The `*` reset ate the UA margins and
the UA font-size ramp survived, so a sixth-level heading rendered at 10.8px bold, the exact
inverse of the rule [Type scale](#type-scale) sets, which forbids anything at text size from
going *lighter* than body copy. Both now sit at `1em`. Weight carries the tier, along with a
color drop from `--label` to `--muted`, and h6 adds italic. Depth past h4 is rare enough that a
fourth size step buys less than a fourth color step.

**Weight did not actually carry it until v1.25.0, and the paragraph above said it did.** h4 and
h5 both shipped `font-weight: 600` at `1em`, so the only thing between a fourth-level and a
fifth-level heading was one color step: `--label` at L 0.810 against `--muted` at L 0.71, and
0.470 against 0.530 in the light palette. Measured in the rendered fixture, "Fourth level" and
"Fifth level" read as the same tier at both root sizes. `h5, h6` now take `font-weight: 500`,
which restores the weight step the note claimed and stays above body copy's 450, so the rule that
forbids anything at text size from going lighter than body still holds. 450 was rejected: it ties
body copy and gives back the same problem one tier down.

**A presentational attribute loses to author CSS, which is why pipe-table alignment vanished.**
`cmark-gfm` emits `<td align="right">`. Presentational hints sit below author declarations in the
cascade, so `td { text-align: start }` silently won every time. `.num` had been the only way to
right-align a column, and it needs hand-written markup that no converter produces. The three
`[align]` rules are the fix. Inline `style="text-align:…"`, which is what `pandoc` emits instead,
already won on its own.

**GFM alerts take the `aside` rule rather than a second callout form.** [Form follows
role](#form-follows-role) says a new role takes an existing accent plus a different form, and an
alert *is* an aside, so it takes the same form, one 3px bar and no fill, and the two selectors
share one declaration block. The five types differ only in hue, and the hue lands on the bar and
on `.markdown-alert-title`, never on the body text, which stays `--label`. That keeps one colored
line per callout instead of a colored paragraph. `warning` keeps plain `aside` orange, so an
alert-free document and an alert-heavy one read the same. The octicon GitHub emits inside the
title is `fill: currentColor`, so it takes the hue for free. Only its size is set, to `1em`.

**Highlighted code reuses the Rider slot map instead of inventing one.** Keywords `--pink`,
strings `--green`, numbers and parameters `--orange`, comments `--muted` italic, functions
`--link`, types `--purple-bright`, fields and attributes `--label`, errors and deletions `--red`,
punctuation inherited. That is the table in
[`themes/rider/README.md`](themes/rider/README.md), unchanged, so a C# buffer in the editor and a
fenced C# block in a document color the same token the same way. One grouped selector per role
covers three emitters: `highlight.js` (`.hljs-*`), `pandoc` and skylighting (`.kw`, `.st`, `.co`,
…) and Prism (`.token.*`). The pandoc classes are one and two letters, so every rule is scoped
under `:is(pre, code)`, because an unscoped `.dt` or `.op` would repaint a consumer's own markup.

**Types needed the same lift the editor scheme needed, and for the same reason.** Plain
`--purple` is 4.23 on `--code-bg`, the one ratio [the contrast
budget](#color-and-the-contrast-budget) records as failing and left alone because "nothing puts
purple *text* on the gray". A syntax slot map does exactly that. `--purple-bright` is
`oklch(from var(--purple) calc(l + 0.07) c h)`, the same +0.07 L that `scripts/create-themes.nu` and
`.github/palette-check.py` already call `bright`, so the token needs no new hex and no new
`/* was */` note. `palette-check.py` matches only literal `oklch(L C h)` triples, so the count it
asserts stays at 17. Pixel-sampled: **5.47 on `--code-bg`**, 6.61 on `--surface`.

**In print the lift inverts, so print pins the token back.** Print is dark-on-light, where +0.07 L
*reduces* contrast: print `--purple-bright` measured 3.49 on the print `--code-bg` against plain
print `--purple`'s 4.64. The print block redeclares `--purple-bright` as the same value as
`--purple`. Every other highlight hue was sampled on both surfaces and clears 4.5. On screen:
`--pink` 4.87, `--orange` 5.64, `--green` 6.02, `--link` 6.47, `--muted` 4.53, `--label` 6.51 and
`--red` 4.73 on `--code-bg`. In print, all of them run 4.57 to 4.64 on the gray.

**Monospace was inheriting italic from three ancestors.** `blockquote`, `th` and `summary` all
slant, and nothing reset it, so a `code` span inside a quote, a header cell or a disclosure label
rendered italic mono, measured `font-style: italic` in all three. One rule resets `code`, `pre`,
`kbd` and `samp` inside them, and inside `h2` and `h6` for the same reason.

**`color-scheme: dark` is on `:root` now, and it is not cosmetic.** Without it a UA form control
renders light-mode inside a dark page: the GFM task-list checkbox came out a pale gray box, the
same class of bug as the mermaid sequence note. Print sets `color-scheme: light`.

**The task-list checkbox stays a native control and stays gray when checked.** GFM emits it with
`disabled`, and Chromium ignores `accent-color` on a disabled control, so the `--purple` accent
only lands when a generator emits the enabled form. A repaint means `appearance: none` plus a
tick drawn from a data-URI SVG, which would put a literal `#282a36` in the stylesheet with
nothing gating its drift against `--surface`, and pseudo-elements on inputs are unreliable in
Safari. A read-only checkbox that reads as read-only is the cheaper answer. `list-style` is
dropped with `li:has(input[type="checkbox"]:first-child)` rather than GFM's `.contains-task-list`,
so the rule holds for `markdown-it` output too, which does not always carry that class.

**Five smaller claims.** `del` and `s` drop to `--muted`, because a UA line-through at full body
color reads as emphasis. `samp` takes `--mono-font`, because it had fallen through to generic
`monospace`. `sub` and `sup` take `line-height: 0`, so a footnote reference does not open the
line it sits on. `abbr[title]` gets a `--muted` dotted rule and `cursor: help`. `img.emoji` loses
the `--ring` outline and is sized to `1.1em`, because the ring is for figures and an inline emoji
was getting a 1px box.

**Footnotes were the largest gap in spirit.** The sheet carries the whole Tufte sidenote
apparatus for hand-authored markup, and it had nothing for `section.footnotes`, which is what a
converter actually produces. That block now sits behind a `--rule-light` hairline at the caption
tier (0.9em, `--label`), with its paragraphs tightened and the backref underline dropped.

**A `li:target` highlight was built, measured, and removed.** A wash of the jumped-to footnote in
`--highlight` reads well and fails 1.4.3. The footnote block is `--label`, and pixel-sampled on
the composited wash (`#68564d`), `--label` measures **3.83**, the backref `--link` **3.81**, and
inline `code` green **3.54**. Only `--on-surface` clears, at 6.51. A recolor of the targeted note
to body copy would fix the prose and not the link inside it. A bar shifts the text sideways on
jump. An outline is the focus-ring form, which can be on screen at the same time. The browser
already scrolls the note into view, so nothing is broken without a marker. **The general rule this
produced: `--highlight` is a body-copy surface only.** See [the contrast
budget](#color-and-the-contrast-budget).

**Math is styled where it arrives as real HTML, and nowhere else.** The first pass claimed MathML
needed no styling. Rendering said otherwise: an unstyled `<math display="block">` overflows the
*page*, not itself. A 30-term equation measured `scrollWidth` 1151 inside a 351px column, and the
document scroll width went to 1170 against a 390 viewport and 1359 against 1280. That is the same
failure a wide table has, and it takes the same two rules. `overflow-x: auto` gives the equation
its own scroll axis, which Chromium honors on `display: block math`, measured and not assumed,
and `margin-block: var(--space-3)` puts it on `pre`'s rhythm rather than the UA's `1em`.
`.math.display`, the span `pandoc` emits without `--mathml` and the box KaTeX renders into, takes
`display: block` and the same pair. Measurement left everything else to the UA. A `1.05em` bump
was built and dropped, because the math font's x-height already matches Source Serif 4 to within
a pixel at every step of the body clamp, and the bump would have re-scaled math inside `h3` and
`td` as well. Color, italic variables and the centering of display math are all UA behavior and
all correct.

**TeX is not rendered, and that is where the CDN line sits.** `$E = mc^2$` reaches the page as
literal delimiters unless the consumer loads KaTeX or MathJax, which is a second hard-offline
dependency of Mermaid's kind, pinned and CDN-bound, for a construct that may never appear. The
sheet stays out of it and styles the containers instead, so a consumer who does add KaTeX gets
the block layout for free.

**Chroma was declined here on a namespace argument, and v1.21.0 overturned it.** The argument was
that Hugo's highlighter names its slots `.k`, `.s`, `.c`, `.n`, `.o`, `.m` and `.p`: one letter,
unnamespaced, in a stylesheet consumers inline into pages this repo never sees, where `.m` is a
margin utility in more than one framework. That reasoning held for Chroma, which is mostly moot
anyway, because Hugo defaults to `noClasses = true` and writes `style="color:#ff79c6"` inline on
every span, which beats any rule here. **It silently excluded Pygments too, and Pygments is not
moot:** it emits classes by default and it is the highlighter behind Sphinx, MkDocs, Quarto and
`nbconvert`. See [Raw HTML and other generators](#raw-html-and-other-generators) for what
replaced it. Chroma copies the Pygments class names, so Chroma is now covered by the same
selectors, for the consumers who turn `noClasses` off.

## Raw HTML and other generators

[Markdown coverage](#markdown-coverage) measured the CommonMark and GFM construct set. It did not
measure raw HTML, which every one of those converters passes through untouched, and it did not
measure the generators outside the GitHub path. A probe at 390px and 1280px, with computed values
read per element, found four defects that v1.21.0 fixes. The rest of that probe is in
`backlog.md`, because each remaining item is a trade rather than a bug.

**Intrinsic-width media pushed the document sideways. `img` was the only element claimed.**
Measured `document.scrollWidth - clientWidth` at 390px, all of them zero at 1280px:

| construct | before | after |
| --- | --- | --- |
| `<svg width="12in">` (graphviz, plantuml) | **782** | 0 |
| `<svg width="900">` (a pre-rendered diagram) | **530** | 0 |
| `<video>`, `<canvas>`, `<object>`, `<embed>` at 800px | **430** | 0 |
| `<iframe width="560">` (an embed pasted into markdown) | **190** | 0 |
| `<img width="800">`, the control | 0 | 0 |

That is the same failure the MathML block had, and it fails 1.4.10 the same way at every width
where it happens. The fix is one rule: `:is(svg, video, canvas, iframe, object, embed) {
max-width: 100% }`.

**The rule carries no `height: auto`, and that is deliberate.** `img` needs it because a raster
has an intrinsic aspect ratio to preserve. An SVG with a viewBox preserves its own ratio and
letterboxes, and the sideways scroll is what the rule exists to stop. Adding the declaration would
put a second sizing input on `pre.mermaid svg`, where three previous attempts were correct on
paper and wrong on screen. See [Diagram sizing](#diagram-sizing).

**`svg` is in that selector only because a fixture diff proved it inert against mermaid.** Both
fixtures were measured at 320 / 390 / 600 / 601 / 768 / 900 / 1280 / 1920 / 2560px, before and
after, on `document.scrollWidth`, every `pre.mermaid svg` box, every distinct label `font-size`,
and each `pre`'s width, `scrollWidth` and computed `overflow-x`. **All four probes are identical
at all 18 fixture-width pairs.** The SVG boxes stay `[368, 754, 500]` on `samples/dark.html`, including
the 601px step down to `[368, 505, 500]` and the 768px step to `[368, 659, 500]`, and `[416]` on
`samples/dark-conn-map.html`. The labels stay 12px and 16px. The only difference the diff reported was
mermaid's per-render element ids. `pre.mermaid svg` already carries `max-width` through its own
rules, and below 600px it carries `max-width: none !important`, so the new rule is outranked
exactly where a diagram needs to escape. Print and forced-colors were swept too: no scroll on
either fixture at 390px or 1280px, zero console errors.

**An unbreakable token in prose pushed the document sideways as well.** `overflow-wrap:
break-word` was on `a`, `code`, `cite` and `h1`-`h6`, and on nothing else, so a hash, a long path
or a base64 fragment outside a code span had no break opportunity. Measured with a 96-character
token at 390px:

| container | before | after |
| --- | --- | --- |
| `li`, `dd` | **467** | 0 |
| `p` | **443** | 0 |
| `blockquote` | **431** | 0 |
| `summary` | **425** | 0 |
| `td`, `th` | 0 | 0 |
| `pre` | 0 | 0 |

`td`, `th` and `pre` measured 0 before the fix because each already has its own scroll axis: the
`max-width: 1000px` escape hatch for a table, and `overflow-x: auto` for `pre`.

**The declaration went on `body`, not on a list of nine selectors.** One declaration inherits to
every prose container, including the ones a list would forget and the ones a later release adds.
It costs nothing in layout, because `break-word` does not reduce a box's min-content contribution:
that is `anywhere`, and [Direction, zoom and growth](#direction-zoom-and-growth) records the
measurement where that distinction mattered. The fixture diff above confirms it: no box in either
fixture moved.

**`position: sticky` on `th` was unscoped, so a `tfoot` row pinned to the top.** Measured on a
60-row table at 1280px after a 400px scroll: a `tfoot th` computed `position: sticky` with `top:
0`, in italic `--pink`, which is a totals row stuck to the header's place. The sticky group moved
to `thead th`, and the `th` typography stays on `th`, so a footer cell still reads as a header
cell. Verified after the same 400px scroll: `thead th` holds at top 0, and `tfoot th` computes
`static` at top 2046.

**The footnote tier matched one converter's class name out of two.** The rule matched
`.footnotes`, which is what `cmark-gfm` and `pandoc` emit. Python-Markdown emits `div.footnote`,
singular, with a leading `<hr>`, so its footnote block measured 18.4px body copy with no hairline,
and the `hr` took the full `--space-10` 40px margin where the tier rule should be. The selector is
now `:is(.footnotes, .footnote)`, and `:is(.footnotes, .footnote) > hr:first-child { display:
none }` drops the duplicate rule. Verified: both shapes now compute 16.56px, `--label`, a 1px
block-start border and a 40px top margin, which is the same tier from both converters.

**Permalink anchors reveal on hover, and the `:focus-visible` half is not optional.** Sphinx,
MkDocs and markdown-it-anchor emit `a.headerlink` or `a.anchor` inside the heading, and each one
measured a 20.6px underlined `--link` glyph, visible in every heading at all times. The rule sets
`opacity: 0` at 0.8em with no underline, and it lifts to `opacity: 1` on `:hover` of the heading
and on `:focus-visible` of the link itself. **Without the focus half the link stays in the tab
order while it is invisible**, which is a keyboard stop nobody can see. Verified on both class
names: 0 at rest, 1 on heading hover, and 1 after keyboard focus. The transition is `opacity 0.15s
ease-out`, which is the sheet's existing link timing, so it also honors the reduced-motion block.

### The backlog this closed

v1.21.0 also took the six entries that the probe left open, and `backlog.md` is empty as a
result. Four were taken and two were declined. The measurements each entry carried are here.

**A wide table gets an opt-in scroll wrapper, and the `table` escape hatch stays.**
[Tables](#tables) records that `display: block` below 1000px makes the sticky header inert, and
that a keyboard user cannot reach that scroll container at all (WCAG 2.1.1). A wrapper that
scrolls one axis does not fix either, because one axis on `auto` forces the other off `visible`,
so the wrapper becomes the scrollport and the header still leaves: probed at 390px on a 43-row
table, `th` top went to **-600 after a 600px page scroll, identical to no wrapper**. A wrapper
that scrolls *both* axes and caps its height does fix it. `.table-scroll { overflow: auto;
max-height: 70vh }` with `.table-scroll > table { display: table }`, measured at 1280px on a
40-row eight-column table: the page does not scroll, the wrapper scrolls in both axes, and `th`
holds at **0 relative to the wrapper** after 400px of inner scroll. `.table-scroll > table` at
(0,1,1) outranks the `max-width: 1000px` rule's bare `table` at (0,0,1), so a wrapped table stays
a real table at every width.

**The wrapper ships inert, and `overflow-x` stays on `table`.** The class matches nothing until a
consumer wraps, and moving the escape hatch off `table` in the same release would break every
consumer that had not wrapped yet: a wide table would overflow the page with no scroller at all.
Both paths therefore run at once. `tabindex="0"`, `role="region"` and a label are consumer
markup, like the other obligations in `README.md`. **`role="region"` must not go on the `<table>`
itself:** it overrides `role="table"` and takes the row and column semantics with it, the same
defect as `role="button"` on `pre.mermaid`. The `70vh` cap is still a guess against a fixture
rather than against real content, which is why the wrapper is opt-in rather than automatic.

**Form controls take `font: inherit` and a 1rem floor, and nothing else.** `.filter-box` was the
only control in the sheet that set a family, so every other one fell to the UA: measured **13.33px
Arial** inside an 18.4px serif page, which is also below the 16px threshold where iOS Safari
zooms the viewport on focus. `:is(button, input, select, textarea) { font: inherit; font-size:
max(1em, 1rem) }` fixes both. Measured after: `button`, `input`, `select`, `textarea` and
`.filter-box` all compute Source Serif 4 at 18.4px, and `.mermaid-zoom` keeps its 0.9em at
16.56px because its own rule outranks the group. The task-list checkbox is unmoved at 18.39px
square, for the same reason.

**Appearance is deliberately not styled.** A focus ring, a hover state, a disabled state and a
pressed state are a button design, and this is a document theme with exactly one control of its
own. The rule fixes the typography defect and leaves the widget to the UA, which
`color-scheme: dark` already tells to render dark.

**Pygments joins the syntax slot map, scoped under `:is(pre, code)`.** Measured before: `.k`,
`.s`, `.c1` and `.nf` all inherited `--on-surface`, so a Sphinx or MkDocs page rendered flat white
code inside a styled `pre`. The names now sit in the same seven grouped selectors as
`highlight.js`, pandoc and Prism, so no new color and no new rule appeared: only more selectors.
Verified in `samples/dark.html`: `.c1` muted, `.k` and `.o` pink, `.nf` link, `.kt` and `.nc`
purple-bright, `.mi` orange, `.s2` green, `.na` label, `.p` inherited.

**The one-letter risk is real and it is bounded by the scoping.** `:is(pre, code) .m` is far
narrower than a bare `.m`, which is a margin utility in more than one framework. The remaining
collision is inside the sheet, not outside it: `.ch` is pandoc's `Char` in the string group and
Pygments' `Comment.Hashbang`, so a Pygments hashbang renders green rather than muted. One line of
a shebang in the wrong tier is cheaper than a second selector set, and it is recorded here rather
than fixed.

**Two entries were declined, and the reasons are worth keeping.**

- **The non-GFM callout conventions stay unclaimed.** `.admonition` with `.admonition-title`
  (Python-Markdown, MkDocs, Sphinx, docutils), `.callout-*` (Quarto) and `.admonitionblock`
  (Asciidoctor) all measured bare: no bar, no title hue, body at `--on-surface` 18.4px.
  Asciidoctor is worse than bare, because it renders its callout as a `<table>` and therefore
  inherits the sheet's table frame, the sticky italic `--pink` `th` and the row hover. Against
  that: three more conventions is a fourth, fifth and sixth name for a role the sheet already
  paints twice, every selector is per-document weight in every consumer file, and nothing in the
  measured lode emits any of the three. Revisit when a consumer actually runs Sphinx or MkDocs.
- **Jupyter ANSI output stays monochrome.** `nbconvert` writes terminal color as `.ansi-red-fg`
  and siblings, plus `-bg` and `-intense-` variants. Sixteen ANSI names onto seven accents is a
  set of choices rather than a translation, the intense variants have nowhere sensible to land,
  and nothing in the measured lode is a notebook export. The `.dataframe` table pandas emits
  inherits the sheet's table rules and already looks correct.

**Two of the four smaller findings were taken, and the rule for the first one is now general: a
solid underline means a link, and a dotted underline means an annotation.** `ins` and `u` both
took the UA underline at body color, which is the one mark this theme uses for a link, so a
converter that emits CriticMarkup or track-changes produced text that read as clickable.
`:is(ins, u) { text-decoration: underline dotted; text-underline-offset: 0.2em }` is the same form
`abbr[title]` already uses. Measured at 1280px: a link is `solid` at `--muted` under `--link`
text, `ins` and `u` are `dotted` at `--on-surface` under body text, so the two differ on style
*and* color. No new hue was spent, and `del` and `s` keep their `--muted` line-through.

**`menu` is a list and now indents like one.** It takes `list-item` children, but the `ul, ol`
indent rule never matched it, so the `*` reset left its markers hanging outside the box. `menu`
joins all three list rules. Measured: `padding-inline-start` 24px, identical to `ul`, with the
first item's box at the same x.

**The other two stay recorded.** `address` keeps its UA italic, which is arguably right for a
postal block. `.tabbed-set` from `pymdownx.tabbed` shows every panel at once, and fixing it means
claiming a radio-driven widget rather than writing one rule: that is the size of the declined
callout work, not the size of these two.

**The nine zero-user class families stay, and `sidenote` is the reason the audit was read
twice.** Measured across the 370-file `product-intelligence` lode: `scorecard`, `edge-list`,
`col-2`, `badge`, `newthought`, `sidenote` and `marginnote` have **zero** documents,
`nav-list` / `filter-box` / `filter-label` / `filter-empty` and `body.conn-map` have **zero**, and
the `verdict` family has **one**. That zero measures two different things, and only one of them is
about the stylesheet. `lode-skeleton.sh` emits none of these classes, so a generator that never
offers a component guarantees that no document uses it. **`sidenote` and `marginnote` are the
Tufte signature and the reason the layout reserves a right margin at all**, so the zero there is a
generator gap. The fix belongs in the generator, which lives outside this repo, and `README.md`
now names the pattern in the opt-in list so it is reachable before anyone judges it. Nothing was
deleted. `conn-map` is the weakest case, because it is a whole second layout mode that nothing has
ever rendered in, but it is also the only worked example of the two-section sticky layout, and
reconstructing it costs more than the bytes do.

## Fixtures are coverage

A fixture demonstrates states. It does not simulate them. Several details in `samples/dark.html` and
`samples/dark-conn-map.html` look like filler and are regression checks. **Shortening any of these
retires the check it exists to be.**

- **The sequence diagram and quadrant chart** in `samples/dark.html`, alongside the flowchart. Both
  label-measurement bugs above shipped and survived because a flowchart is the one diagram type
  that shows neither. Its labels are `foreignObject` HTML that the browser measures rather than
  `calculateTextDimensions`, and its viewBox comes from the laid-out graph rather than from a
  fixed chart size. The sequence fence's `Note over` is deliberately wider than its actor box,
  and the quadrant fence carries two point labels long enough to overrun the canvas.
- **The conn-map focus node's long label.** The connections map is the one fixture that renders
  with `useMaxWidth: false`, so it is the only place where a mis-sized node box lands in a
  *constrained* column rather than on an open page. That is the failure mode the v1.13.0
  label-box fix was about, and five short labels never tested it. The label now wraps to four
  lines and the box grows to hold them: at 1280px, a rect of 260px around 200px of text, all five
  nodes `fits: true`, the SVG 416px inside an 830px graph column, and no document scroll at any of
  nine widths at either root size.
- **The filter's `role="status"` line and its `.filter-empty` line.**
  `README.md` has always asked a consumer who wires the filter for a result-count status region
  and a no-matches line, and neither existed anywhere in the repo. `.filter-empty` was a styled
  class with no instance, so nothing verified that it rendered, and a consumer had no reference
  copy for the one empty state in the system. Verified in the AX tree: one `status` node.

  **Both lines were hand-written to numbers the script contradicts, and the reason they were left
  visible expired in v1.22.0.** The bullet above used to end "the fixture's nav-list filter has no
  following table, so `filter.js` returns early and the pair stays inert and visible, the way the
  four `.verdict-*` chips do." Since the one-table scope was reversed the script *does* wire this
  filter, over four `.nav-list > li` rows: three in the list and one inside the `details.nav-group`.
  So the page shipped three claims that disagreed on load: a populated list, `3 entries`, and
  `No entries match “tier 4”. Clear the filter to see all 3.`, and one keystroke replaced the count
  with `4 entries`, which is a reference page correcting itself in front of the consumer reading it.
  The status line now reads `4 entries`, the group's `.count` reads `1` rather than `3`, the empty
  copy says `all 4`, and the empty line ships `hidden`. Verified through the real script: on load
  `hidden` with height 0 and `4 entries`; on `zzz` the line reveals with its copy and the status
  reads `0 entries`; on clear it hides again at `4 entries`. A `.verdict-*` chip can sit inert and
  visible because a chip states nothing about the rest of the page. An empty state does.
- **The highlighted code block carries real emitter classes.** `.hljs-keyword`, `.hljs-type`,
  `.hljs-params` and the rest, in the nesting `highlight.js` produces, not hand-written spans on
  invented names. It is the only check that the slot map in
  [Markdown coverage](#markdown-coverage) still matches
  [`themes/rider/README.md`](themes/rider/README.md), and the only place `--purple-bright`
  renders. All five GFM alert types are present for the same reason: four of the five hues appear
  nowhere else on a bar.
- **The Pygments block beside it carries the one- and two-letter names.** It is the only check on
  the half of the slot map that a bare `.k` or `.m` could break, and the only place `.p` proves it
  still inherits rather than picking up a color. It is a second code block on the same page on
  purpose: the `.hljs-*` set and the Pygments set can drift apart without either one failing
  alone.
- **The MathML block is the only element on the page with its own scroll axis besides `pre` and a
  wide table.** It is short enough to fit at 2560 and it still exists to prove that
  `math[display="block"]` is claimed at all. The overflow rule it checks was added because an
  unclaimed one pushed the whole document sideways. Deleting it retires the only test that a
  converter's math does not reintroduce a horizontal page scrollbar.
- **The `<em>` label says what `em` actually does.** It read `<em>emphasis (label)</em>` long
  after the `em` color rule was deleted, so the reference a consumer reads named a color the
  sheet no longer paints. It now reads `<em>emphasis (inherits its surroundings)</em>`.

## Repo layout

**The three Nushell scripts moved to `scripts/` in v1.24.0. The two Python helpers deliberately did
not.** The split is by who invokes a file, not by what language it is written in. Each Python helper
is a CI step of its own, and `python3 .github/palette-check.py` and `python3 .github/render-modes.py`
appear verbatim in `contract-check.yml`, so they live beside the workflow that runs them. The
Nushell scripts are the commands a person types, so they get a folder whose name says so.

`.nu` scripts are also invoked by CI, which makes the rule a judgment rather than a law. The tiebreak
is direction: a Python helper exists only to answer a check, and its only human caller is a Nushell
script forwarding to it, while `scripts/maintain.nu check` is the documented front door.

**Both kinds resolve every path from the repo root, never from `cwd`.** The Python side needed no
change at all: `pathlib.Path(__file__).resolve().parent.parent` was already the root from `.github/`,
and it is still the root from anywhere one level down. The Nushell side did, because `const HERE =
path self | path dirname` used to be the root and became `scripts/`. It is now two constants:

```nu
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname
```

`SCRIPTS` exists because `path self | path dirname | path dirname` is **not** a legal const chain in
Nushell, because the second step has to read a name that is already bound, and the one-liner fails to parse.
Verified after the move by running `nu ../scripts/maintain.nu check` from `themes/`, which prints
`Contract OK`.

The payload, the fixtures, `tokens.css` and the docs stay at the root. Pages serves the root, and
consumers pin paths into it, so moving any of those breaks a pinned consumer for no gain.

### Python stays, and the alternatives were measured rather than argued

Both helpers were put up for rewrite in v1.24.0 and both stayed. **Neither the color math nor the
contrast math is the obstacle. Both ports work, exactly.** Each candidate was run against all 17
`:root` tokens and compared to `palette-check.py --dump` as strings, because CI compares hex as
strings:

| candidate | result |
| --- | --- |
| awk | 17 tokens compared, 0 mismatch |
| Nushell | 17 tokens compared, 0 mismatch |

So the reasons are the other three.

**"Bash" is not an option; only awk is.** Bash has no floating-point arithmetic, and the Oklab
matrix needs `cos`, `sin` and `x^(1/2.4)`. A bash version is an awk program in a shell wrapper, which
takes the repo from `{nu, python, bash}` to `{nu, bash, awk}`, the same three languages, with the
math in the least readable of them.

**Nushell would genuinely drop one language, and it is a rewrite of the primary gate.** `math sin`
and `math cos` exist, and `format number | get lowerhex` formats the byte, so `palette-check` could
be `scripts/palette-check.nu` and `create-themes.nu` could stop shelling out to `python3` for
`--dump`. That is a real gain and it is two hundred lines of the most load-bearing check in the repo,
rewritten to save a dependency that is preinstalled everywhere it runs. Take it if the check needs a
substantial change for its own reasons, and do the rewrite then, not on its own.

**`render-modes.py` cannot move at all, and this is the hard blocker.** Reading one PNG pixel needs
zlib inflate. Nushell has no decompress command and neither does bash. The known workaround strips
the two-byte zlib header and prepends a hand-built gzip header:

```
{ printf '\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03'; dd if=z.bin bs=1 skip=2; } | gzip -dc
```

It inflates correctly and then **always fails its trailer**, because a zlib adler32 is not a gzip
crc32. `gzip` prints `invalid compressed data--crc error` and exits non-zero on a *healthy* PNG, so
the check would have to ignore its own exit status and could no longer tell a corrupt screenshot
from a good one. That is the exact class of quiet wrongness the gate exists to catch, so the
workaround costs more than the dependency.

## Odds and ends

**`hr` is a `border-block-start`, not a `box-shadow`, because the shadow painted nothing at all.**
It read `border: none; box-shadow: 0 1px 0 var(--rule-light)`. `border: none` collapses the
element to a measured `height: 0px`, and a `box-shadow` on a zero-area box has nothing to offset.
A pixel scan of a 40px band across the `hr` at 1280px returned bare `--surface` on every pixel.
The separator was invisible on screen at every width, in print, and in forced colors, for as long
as the rule existed. A real border paints, at 1px and 3.05:1, which is what `--rule-light` is
tuned for, it survives forced colors, and it needs no `height`.

The same defect does **not** affect `table`, whose `box-shadow: 0 1px 0 var(--rule), 0 -1px 0
var(--rule)` sits on a box with real height. Verified: both rules paint at `rgb(151,159,196)`.
Shadow-drawn rules are fine. Shadow-drawn rules on a zero-height box are not. Any future hairline
should ask which it is.

**`scrollbar-color` sits on `body`, not on every scrolling box, because the property inherits.**
`.table-scroll`, `pre`'s `overflow-x`, the narrow-viewport `pre.mermaid` scroll and the document's
own scrollbar all took the browser default light-mode thumb and track before this, the one UI
chrome this sheet never themed. `scrollbar-color: var(--rule) var(--surface-alt)` on `body` reaches
every one of them without a second declaration, because an unset `scrollbar-color` computes to
`auto` and inherits like any other property that defaults to it.

**`.table-scroll` gained `overscroll-behavior: contain`, matching the mermaid overlay and the
narrow-viewport `pre.mermaid` rule that already carry it.** Without it, scrolling a wide table to
its edge chains into the page behind it, which is the same scroll-chaining problem those two rules exist
to stop, just never checked against the newer wrapper.

**`--ring` is a token because the `img` hairline was the one color declared twice as a literal.**
It is `oklch(1 0 0 / 0.1)` on screen and `oklch(0 0 0 / 0.1)` in print, the only raw color values
left outside `:root`. As a token it flips in print beside the other thirteen overrides, and the
`img` rule disappears from that block entirely, so print carries one declaration fewer. It is
deliberately not a palette color, because white at 10% over an arbitrary image is a translucent
veil, not a hue, and `.github/palette-check.py` never sees it. The alpha-slash form does not match
its `oklch(L C h)` regex, so the parsed token count stays at 17 and the "expected 17" guard still
means what it says.

**The W3C CSS validator reports two errors on `samples/dark.html`, and both are the validator, not the
stylesheet.** It flags `container-type` as a property that "doesn't exist" and `@container` as an
"unrecognized at-rule". Both come from CSS Containment Module Level 3, which the Jigsaw
validator's `css3` profile predates. Container queries have shipped in every major engine since
February 2023, and the two declarations it names are the load-bearing fix for `.scorecard`
overflow under text-only zoom, recorded above under *Direction, zoom and growth*. Do not delete
them to make the validator quiet. That trades a real rendering bug for a green badge.

The nine warnings are noise of the same kind. Seven read "CSS variables are currently not
statically checked", which is a statement about the tool. One flags `font-size` inside a `clamp()`
as an unqualified dynamic value. One calls `pointer-events: auto` unofficial while admitting it is
"supported in multiple browsers"; it is the initial value of the property, and the overlay needs
it to re-enable hit testing after `pointer-events: none`.
