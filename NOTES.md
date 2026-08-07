# NOTES.md — why the stylesheet looks like this

`tufte-dracula.css`, `mermaid.js` and `filter.js` are inlined verbatim into every generated
HTML file, so they carry no comments (see `CLAUDE.md`). This file holds the reasoning that
used to live in them. **Every number below was measured in Chromium, not reasoned about.**

Two comments remain in the CSS, both machine-read data rather than prose:

- **Line 2, the version** (`/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`). `build-sample.nu`
  reads it from `lines | get 1` to stamp `tokens.css`; `maintain.nu bump` rewrites it.
  Stripping it broke regeneration with `index too large (empty content)`, and because that
  error was piped away the fixtures went stale while still looking correct.
- **The `/* was #rrggbb */` notes on ten `:root` tokens.** `.github/palette-check.py` check 3
  fails if a stated hex disagrees with its `oklch()`.

Removing the prose comments was verified behaviour-neutral: computed styles for every element
in both fixtures at 390/900/1280/1920px are byte-identical to the commented version, 0
differences across 160 elements × 4 viewports. CSS 35192 → 13399 bytes, `mermaid.js` 4731 →
2079, `sample.html` 45173 → 20728 (54%), `sample-conn-map.html` 41030 → 16585 (60%). That
reduction lands in every page a consumer generates.

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
| [Colour and the contrast budget](#colour-and-the-contrast-budget) | Four surfaces, every ratio, the data ramp, forced colors |
| [Form follows role](#form-follows-role) | Filled vs outlined chips, bars vs boxes, hue budget |
| [Editor themes](#editor-themes) | Why the Rider slot map differs from the prose one |
| [Mermaid](#mermaid) | Init config, label measurement, diagram sizing, zoom |
| [Connections-map layout](#connections-map-layout) | `body.conn-map`, markup order, no breakouts |
| [Interaction states](#interaction-states) | Press, hover, focus rings |
| [Keyboard and assistive technology](#keyboard-and-assistive-technology) | Zoom button, modal overlay, inert |
| [Direction, zoom and growth](#direction-zoom-and-growth) | RTL, text-only zoom, safe-area insets |
| [Print](#print) | Token reassignment, page breaks, chip outlining |
| [Filter](#filter) | `filter.js` scope and its three load-bearing decisions |
| [Unclaimed elements](#unclaimed-elements) | `mark`, `kbd`, `figure`, `figcaption`, and the UA defaults they had |
| [Fixtures are coverage](#fixtures-are-coverage) | Which fixture details exist to catch a regression |
| [Odds and ends](#odds-and-ends) | `hr`, `--ring` |

---

## Fonts

**Body face is Source Serif 4**, a variable serif pinned to an exact jsDelivr version the way
`mermaid.js` is. Two faces (roman + italic), ~50KB each, served `immutable`.

Why a webfont at all: every system serif ships 400/700 and nothing between, so there was no
way to ask for the ~450 that light-on-dark body copy wants. Georgia at `font-weight: 400` and
at `450` render *identically* — measured, the 450 does not exist. The variable axis is
200–900, so 450 is real, and `600` on `.newthought` / `strong` / `dt` is a real 600 instead of
snapping to bold.

Why this face over the alternatives: its figures are **tabular and lining by construction**
(all ten digits at 529/1000), so tables align in the body serif with no OpenType feature
support required. x-height 475/1000 against Georgia's 481, a 1.2% difference, so no
em-relative value needed re-deriving.

| candidate | wght axis | x-height | figures |
| --- | --- | --- | --- |
| **Source Serif 4** | 200–900 | 475 | tabular + lining |
| Literata | 200–900 | 507 | proportional, lining (needs `tnum`) |
| Newsreader | 200–800 | 426 | tabular + lining |
| Lora | 400–700 | 500 | proportional + **old-style** — Georgia's exact defect |
| Petrona | 100–900 | 443 | proportional, lining |

None of the five ship `smcp`, so `.newthought` small caps are still synthesised. The webfont
bought the weight axis, not true small caps.

**The fallback path is a genuine downgrade, not an equivalence.** Offline the stack falls to
Georgia: no 450 (collapses to 400), old-style proportional figures, so tables lose alignment.
Measured table per-digit spread 0.00% online, 4.21% on the fallback. Accepted because text
still renders and reads — unlike the mermaid CDN, which renders no diagram at all offline.
`font-display: swap` so text is never invisible while loading.

Georgia stays first in the fallback stack: most widely installed sturdy screen serif (Windows
since Win98, all macOS, iOS), low stroke contrast, large x-height. Noto Serif covers
Android/ChromeOS, DejaVu Serif covers Linux. Charter and Palatino are absent on purpose — both
exist only where Georgia already does, so they were unreachable.

**Both stacks are tokens, because three rules needed the literal and one of them is not a
`body` descendant in the way it looks.**

- `.mermaid-zoom` sets `font: inherit`, which resolves against `pre.mermaid`, so the injected
  button computed `monospace` at 14.9px — the only control in the sheet in the code face while
  `.filter-box` sat in the body serif, undoing half of what removing `pre.mermaid`'s fill and
  accent bar was for. `font-family: var(--body-font)` after the shorthand fixes the family
  without disturbing inherited weight and style.
- `pre` never set a `font-family` at all, so it inherited the UA's generic `monospace` while the
  inline `code` beside it computed the full stack. The fixtures hid it because their `pre` wraps
  a `<code>` that supplies the family by inheritance; a consumer emitting a code block without
  the inner `<code>` got a different face for the block than for the inline spans on the page.

`mermaid.js` still writes the stack out twice as a literal, and that is not drift to fix: they
are JavaScript strings in a config object, cannot read a custom property, and both copies are
load-bearing for different reasons (see [Mermaid](#mermaid)). Verified the `pre` change does not
disturb them — the sequence `Note over` rect still measures 404px around 384px of text, and
`.mermaid-zoom` still computes the body serif.

**No `-webkit-font-smoothing: antialiased`.** That advice exists because macOS renders dark
text on light heavier than intended. This theme is the inverse, and grayscale-only
antialiasing thins strokes — the opposite of what light-on-dark needs.

## Type scale

The body `font-size` clamp is the **only size lever**: every other step, headings included, is
em-relative to it, so nudging it rescales the page proportionally.

Floor `1rem` = 16px (the long-form minimum, and the iOS input-zoom threshold `.filter-box`
inherits); cap `1.25rem` = 20px. Every bound is rem, never px, so a reader who raises their
browser default scales the page with it. A previous `clamp(1.0625rem, 1rem + 0.35vw,
1.375rem)` ran 17→22px and read oversized on a desktop.

**Do not lower the floor past `1rem`** without giving `.filter-box` its own 16px floor — iOS
zooms below 16px and the input sits exactly on the threshold.

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

Nested ratios compound — check the parent before adding a step. Three traps already paid for:

- **Headings are `em`, not `rem`.** Anchored to the root they diverged from body copy, which
  grows on a vw clamp: h3 rendered *smaller* than its own paragraphs at every width (15.3 vs
  17.4 at 390px, 17.6 vs 22 at 1920px) and h2 fell to 1.16× body.
- **`.verdict` / `.badge` at 0.8em, not 0.75em**: they nest inside a 0.95em parent, so
  `0.75 × 0.95 × 16px` = 11.5px, under the 12px floor. 0.8 gives 12.3px. Coupled to the body
  floor — if that moves, re-check these.
- **`pre code` is `font-size: 1em`** to halt compounding: `code` and `pre` each carry 0.9em, so
  a bare `<code>` inside `<pre>` would render at 0.81em, smaller than the block it fills.

An earlier scale used `max(Xem, 12pt)` floors. Those resolved to 16px on every viewport under
~950px, pinning nine elements to one size and making body copy the *smallest* text on a phone.
`pt` is absolute like `px`, so they also ignored the reader's own setting.

**`h1`/`h2` sit at weight 400** — 22–35px carries itself. **`h3` is 500**: it is the one
heading at text size (1.12em, 12% over body), so at 400 it rendered lighter than the paragraph
beneath it. Heavier than h2 is not an inversion — h2 is 20% larger, italic and `--purple`.

**`code` / `cite` at 0.9em**: SF Mono's x-height is 526/1000 against Source Serif 4's 475, a
ratio of 1.094, so the x-height-matched size is 0.914em. A previous 0.85em was tuned against
Palatino (x-height 471) and over-corrected by ~7%.

**`li` carries no `font-size` of its own.** At 0.95em in the structural tier, a bulleted list
inside an `<article>` rendered 17.48px against 18.4px paragraphs — body copy subordinate to
the body copy beside it. The two contexts that want 0.95em ask for it themselves: `.nav-list
li` directly, `nav` on the container. That last one was double-counting while `li` had its own
value — `nav > ul > li` compounded to 0.9025em, the smallest text on any page with a `<nav>`.
Dropping the declaration also retired `li li { font-size: 1em }`, which existed only to stop
the same compounding one level down.

## Italics

Eight italic rules: `.byline`, `h2`, `th`, `summary`, `blockquote`,
`details.nav-group > summary`, `.filter-box::placeholder`, `.filter-empty`.

**`h3` is upright, `h2` is italic — deliberately.** They are adjacent levels, so while both
were italic the slant distinguished neither and the hierarchy rested on size and colour alone.
Upright h3 gives the pair a second axis (h2 italic `--purple`, h3 upright `--label`), and it
lands where italic is most expensive: at 1.12em a slanted stem on a dark surface loses more
definition than a 1.35em heading does.

**`summary` is 450, not 400.** It inherits the body font-size, so at 400 it was the only
italic text at *reading* size lighter than the copy around it. The italic stays — it marks the
row as a label rather than prose. `details.nav-group > summary` inherits the weight.

**`th` is 450**, matching body copy: a header row lighter than its own data reads as
subordinate to it. The declaration cannot simply be dropped — the UA default for `th` is bold.
Italic and `--pink` carry the distinction; weight must not work against it.

## Width and measure

**Page width is one number**, `--page-width: min(90vw, 160rem)` in `:root`, referenced by
`body` and by `body.conn-map`'s article alike, so the two layouts cannot drift.

- `90vw` — the proportional side margin, 5% each side. This is the dial.
- `160rem` — ultrawide backstop, ~2560px at a default root. Engages past ~2844px, where an
  uncapped line would run 390+ characters. `rem` so it scales with the reader's root size.
- `100% - 2 * var(--gutter)` on `body` is the floor, and what respects the safe-area insets
  folded into `--gutter`.

**Three failed attempts, recorded so they are not retried:**

1. `min(100% - 2 * var(--gutter), 70ch)` plus an `@media (min-width: 1200px)` override to
   `80vw`. The 70ch cap left **34.8% of a 1199px window empty** (body 782px), and crossing
   1200px snapped content from 782px to 960px in one step.
2. A `100rem` cap — 16.7% of a 1920px window empty, and 2560px cut to 1600px.
3. Gutter + backstop only, no proportional term — effectively full-bleed, 32px margins at
   every size, 2.5% unused at 2560px.

"Unused space" is **not** the metric to minimise. A page needs side margins that scale.

**The long measure is a standing decision, not an oversight.** Content flows nearly the full
window, ~178 characters per line at 1920px against the conventional 60–75. This stylesheet
serves dense reference pages with tables and diagrams, not book-length prose.

Re-litigated once; the answer did not change. `max-width: 32em` does hit ~74 characters at
every width, but it strands body copy in a narrow left column with the container empty. If it
is ever revisited:

- The cap belongs in `em`, **not `ch`**. `ch` is the advance of `0`, and Georgia's `0` is
  0.614em against a 0.433em average prose advance (ch/avg = 1.416 measured), so `70ch` ran 99
  characters, not 70.
- It must be scoped to section children. A bare `p` selector also hits `.byline` (a flex item
  in the conn-map header, which collapses that layout when capped) and the `<p>` mermaid emits
  inside `foreignObject` labels.
- Smaller type makes the measure *worse*: container width is `vw`/`%`-driven, so shrinking
  type fits more characters per line.

**Sidenotes stack below 1000px, not below 600px.** The float is `width: 28%`, so between the
old 600px breakpoint and ~1280px the note was narrower than any measure worth reading: 150px
at 601px, 194px at 768px, 227px at 900px — **19 to 25 characters per line** at 0.9em, against
37 at 1280px. The body copy beside it kept the full container, so the page put a ribbon of
shredded text next to unbroken prose. Above 1000px the note is 252px and up.

**`hyphens: auto` is scoped to the two narrowest prose measures, not global.** `hyphens`
computes `manual` by default, so nothing in the sheet ever hyphenated — including the sidenote
at 28% and `.col-2` at half a column, which are the measures this section already records at 19
to 25 characters per line. Both fixtures carry `lang="en"`, which hyphenation requires. It is
**not** applied to body copy (the long measure needs no help), to `.nav-list li a` (a
hyphenated link looks like a hyphen in the slug), or to headings.

The collapse declarations live in their own `@media (max-width: 1000px)` block rather than
widening the 600px query: everything in that block — gutter, `pre` padding, `aside` /
`blockquote` padding, `.edge-list`, `.col-2`, `.scorecard`, the 44px touch minimums, the
diagram scroll container — is genuinely phone-sized and was measured at 600px. Two
breakpoints with distinct reasons beat one breakpoint wrong for half its contents.

## Paragraphs and section rhythm

**`section` spacing is `2.5rem`, matching `h2`'s top margin, because the smaller of the two
never painted.** It was `margin-bottom: 2rem` against `h2 { margin: 2.5rem 0 0.75rem }`.
Adjacent-sibling margins collapse to the larger, and every section in both fixtures opens with
an `h2`, so the gap measured **40px between all eleven sections** at 1280px while the 2rem
declaration contributed nothing — zeroing it on all of them moved document height 5096 →
5080px. The defect was not the wasted declaration but what it hid: a section opening with
anything else (a `<p>`, a table, a diagram) got 2rem where its neighbours got 2.5, so rhythm
depended on markup the stylesheet does not control. Equal values collapse to 2.5rem either
way — measured 40px at 320 / 390 / 600 / 768 / 1280 / 1920 / 2560px, eleven gaps, no
exceptions.

`section > :first-child { margin-top: 0 }` was tried and rejected: it flattens the gap under
the byline for the first section, and in `body.conn-map` the sections are flex items where
margins do not collapse at all, so a rule tuned for the collapsing case misaligns the two
columns.

**`.indented` is the book setting, opt-in, three rules.** `margin-block: 0` on paragraphs plus
`text-indent: 1.5em` on every `p + p`. The first paragraph is never indented because nothing
precedes it to break from, which is why the indent hangs off the sibling combinator rather
than off `p`. 1.5em resolves to 24.3px at 390px and 30px at 1920px, tracking the body clamp.

The third rule is `.indented :is(ul, ol) { margin-block: 0.75rem }`. A bare `ul` here has
padding but no margin — it relied on the paragraph above supplying the gap, and with
`margin-block: 0` there is no gap left. `dl` carries its own 1rem and `blockquote` / `aside` /
`pre` their own 1.5rem, so the rule names only the two elements that were relying on a
neighbour.

A class rather than the default: the two conventions cannot be mixed on one page without
reading as an accident, and the default is what every existing consumer's output assumes.

**A sidenote marker used to knock its own paragraph off the rhythm.** `.sidenote-number:after`
carried `vertical-align: super`, which grows the line box: measured at 1280px, a one-line
paragraph containing a marker was **30.5625px against a 29.44px `line-height`**, 1.04 lines, so
every paragraph with a note sat ~1px taller than its neighbours. It is now `position: relative;
top: -0.4em; line-height: 0`, which lifts the glyph without participating in line-box height —
the same paragraph measures 29.44px, exactly 1.000 lines, with the marker still raised.
`.sidenote:before` shares the rule and the numbers still align between marker and note.

**`--space-*` covers block rhythm only, and the component padding stays literal.** Six tokens
(`0.5 / 0.75 / 1 / 1.5 / 2.5 / 3rem`) replace 19 vertical-rhythm values: `body` padding,
`h2` / `h3` / `p` margins, `section`, `hr`, `dl`, `nav`, `footer`, `figure`, `aside`,
`blockquote`, `details`, `.edge-list`, `.filter-label`, `.filter-box`, `.scorecard`,
`.mermaid-zoom`, and the mobile `body` padding. Values that are not on the scale (0.15, 0.2,
0.3, 0.35, 0.4, 0.6, 0.65, 0.85, 0.9, 1.25rem) are **left alone deliberately**: they are
component-internal padding tuned by measurement, not page rhythm, and snapping them to a scale
would move rendered boxes to satisfy an abstraction. The list indent (`ul, ol
padding-inline-start: 1.5rem`) stays literal for the same reason — it pairs with
`--tree-step`, not with the vertical scale.

The refactor is a pure substitution and was verified as one: computed margins and padding for
17 rhythm-bearing selectors, compared against the v1.16.0 fixture at 1280px, differ in exactly
one place — `section`'s 32px → 40px, which is the deliberate change above. Sixteen of seventeen
are byte-identical.

## Lists

**Prose `ul` keeps its markers.** `ul { list-style: none; padding-inline-start: 0 }` was a
global reset, so a bulleted list inside an `<article>` rendered as a run of short paragraphs —
`list-style-type: none`, `padding-inline-start: 0px`, and a nested `ul` indenting by **0px**,
so nesting was invisible too. It also made `li::marker { color: var(--muted) }` dead code for
every `ul`. `ul, ol { padding-inline-start: 1.5rem }` gives both list types one indent and
lets `ul` keep the UA's `disc` / `circle` / `square` progression, now muted. The reset bought
nothing: `.nav-list` sets `list-style: none` and `padding-inline-start: 0` on its own rule.

**This is also half of the VoiceOver list-semantics problem.** WebKit drops list semantics from
a list with `list-style: none` — no "list, N items", no item position. With markers restored,
prose lists keep their semantics natively and only `.nav-list` needs `role="list"` in the
markup, now a documented consumer obligation. Verified through the real accessibility tree
(CDP `Accessibility.getFullAXTree`): eight `list` nodes in `sample.html`, four nav lists by
explicit role and the prose lists by having markers again.

## Tables

**No `font-family` on `table`** — tables inherit the body serif, which is correct because
Source Serif 4's digits are tabular and lining by construction. Tables briefly carried the
monospace stack because Georgia could not do this: old-style *and* proportional figures (9
distinct advances, `1` at 430/1000 against `0` at 614/1000) with no `lnum`/`tnum` to escape
them — its entire GSUB feature list is `aalt, locl`. That workaround cost ~27% table width
(807px vs 634px natural at 1280px, 6 columns) and put tables in a different register from the
prose. `font-variant-numeric: tabular-nums` on `td` is belt-and-braces for the fallback path,
where it works in any face exposing `tnum`; it is inert in Georgia, which exposes neither.

**`table.tree` is a table, deliberately not a `treegrid`.** The ask was hierarchy plus
columnar density. `role="treegrid"` is the obvious-looking answer and the wrong one: the role
is a keyboard contract (roving `tabindex`, arrow keys, `aria-level` / `aria-expanded` /
`aria-posinset` / `aria-setsize`), so shipping it without the script promises interaction that
does not exist and *removes* the native row/column semantics a plain `<table>` announces.
Depth is an author attribute, `data-depth`; everything else is presentation.

- **Indent is one `--tree-step` custom property, and only levels 0–3 exist.** `attr()` cannot
  feed a length into `calc()` with useful support, so the alternative to four explicit rules is
  a custom property per row in the markup, which pushes styling into the generator. Four rules
  is smaller and a level-4 row degrades to flat rather than to wrong.
- **Depth de-emphasises with `--label` at levels 2 and 3 rather than shrinking type** — nested
  ratios compound and the table is already at 0.95em.
- **The `↳` needs the same alt-text treatment as the outbound arrow.** It is a `::before` on
  the first cell, so it lands in the accessibility name: a row announced as "↳ REQ-01". Same
  `@supports (content: "x" / "y")` guard, `content: "\21B3\A0" / ""`. Any future decorative
  `::before` owes this.

**`width: auto; max-width: 100%`, not `width: 100%`.** A three-column table stretched to the
full page: 1152px rendered against 315px of content at 1280px. Checked against a **wide**
(six-column) table at 390 / 601 / 768 / 1024 / 1280px — a wide table is unchanged, its
min-content width is the floor either way (922px at 1024, 1152px at 1280). Only tables narrower
than their container move, which is the intent: the narrow table measures 316px at 1280px and
338px at 1920px.

That comparison turned up a **pre-existing** sideways-scroll bug, identical under `width: 100%`:
between 601px and ~1000px a wide table's min-content width exceeds the body and the *document*
scrolls (731px against a 537px body at 601px, 746 against 691 at 768), because the `overflow-x:
auto` escape hatch only existed below 600px. **Fixed in v1.14.0 by moving the hatch to `@media
(max-width: 1000px)` with `width: fit-content` alongside it.** The trigger is smaller than a
six-column table: at 200% text-only zoom and 601px the fixture's own three-column `table.tree`
measured 588px against a 473px body and the document scrolled 51px. This file had recorded
sideways table scroll as a 400%-zoom problem; it starts at 200%.

`display: block` alone is not the fix — a block-level table takes `width: auto` and fills its
container, reinstating the defect above (narrow tree table 537px at 601px, 899px at 999px).
`width: fit-content` resolves to content width for a table narrower than its container and to
container width for one wider, so both land correctly: tree table 426 / 434 / 445px against
bodies of 537 / 691 / 899px, and an injected eight-column table scrolling inside itself at 601px
(`scrollWidth` 617 against `clientWidth` 537) with the document at 601px.

The cost is the sticky header, which `display: block` makes inert up to 1000px rather than 600px
— verified still pinning above it (`th` top holds at 0 after a 60px scroll at 1280px).
Deliberate: a pinned header matters on a long table at desktop width, and a page that scrolls
sideways is a WCAG 1.4.10 failure at every width it happens. Keyboard reach for that scroll
container (WCAG 2.1.1) is still open — see `backlog.md`.

**Sticky `th`** needs an opaque background or the rows scrolling under it show through. The
rule is an inset shadow, not `border-bottom`: under `border-collapse: collapse` the collapsed
border is painted by the table, so it scrolls away from the stuck header and leaves it running
straight into the first row.

**Zebra striping is gone as of v1.17.0, and the row fill it freed now means one thing.**
`tbody tr:nth-child(even) td { background: var(--code-bg) }` was the sheet's only decorative
fill: it separated rows the reader could already separate by padding, and it put the *code*
surface behind arbitrary prose cells. A Tufte table separates rows with space and one rule.
Three consequences:

- **`table.tree tbody tr:nth-child(even) td { background: none }` went with it.** It existed
  only to switch striping back off inside the tree table, whose own depth-0 tint it was
  protecting. With nothing to override it was pure weight. (Parity is not depth: on a tree the
  stripe cut across the structure it was supposed to help read, which is why that override
  existed at all.)
- **`table.tree [data-depth="0"] td` is now the only fill inside any table**, so `--code-bg`
  in a table means *root row* and nothing else — reinforcing what the indent, the `↳` and the
  bold weight already said.
- **`tbody tr:hover td` keeps its `tbody` qualifier.** It was there to win a specificity fight
  against the even-row rule (0,1,2 against 0,1,3); that opponent is gone, so the qualifier is
  now redundant rather than load-bearing. Left in place because it also scopes hover away from
  a `thead` row.

Ratios elsewhere in this file measured "inside a zebra row" are historical. The surface is
still real — `pre`, inline `code`, `.filter-box`, the tree root row — but no ordinary table
row carries it.

**`.num` is an opt-in class, not a heuristic.** `th.num, td.num { text-align: end }`.
CSS cannot tell a number from a label: `:has()` cannot match text content, and "a column that
looks numeric" is a generator's claim. Source Serif 4's figures already shared one advance
width, so alignment was the missing half — `1234` / `567` / `9012` now line up on the last
digit where before they hung off the left edge under an italic header. The class goes on the
`th` too or the header floats off its own column, which is why `README.md` states both.

## Links

**Underline thickness has a 1px floor.** `0.05em` resolves to 0.8px at the base size, which
paints as a faint partial-coverage line, and the underline is the only thing marking a link.

`overflow-wrap: break-word` lets a long URL or slug break instead of escaping its container —
the connections-map Links column is as narrow as 220px.

**The outbound arrow is decorative but reached the accessibility tree.** Measured via CDP
`Accessibility.getFullAXTree`, the link computed as `"outbound link\A0↗"`, so a screen reader
read out "north east arrow" after every external label. `content: "…" / ""` gives the
pseudo-element empty alternative text, suppressing arrow and nbsp for assistive tech while
leaving the glyph visible.

It sits behind `@supports (content: "x" / "y")` because the alt-text syntax is a single value —
a browser that cannot parse it discards the **whole** declaration and the marker disappears.
Firefox ESR 128 is in that group and still deployed. Verified both paths: supported gives
accessible name `"outbound link"`; unsupported keeps the marker visible and merely retains the
old announcement.

`\A0` (nbsp) keeps the arrow from orphaning onto its own line. Print sets `content: ""`, later
in source order, and drops the underline too: on paper the destination is unreachable either
way, so both are noise.

`cite` is monospace and `font-style: normal`: the browser default is italic serif, which in
this theme is indistinguishable from `<em>`.

## Colour and the contrast budget

The `:root` block is the only source of colour truth; `tokens.css`, `mermaid-palette.json` and
the inline hex in `mermaid.js` are machine-checked projections of it.

**The budget covers four backgrounds.** For a long time it covered two: `--rule-light`,
`--muted` and `--red` were tuned against `--surface` and `--code-bg`, and two further surfaces
existed unmeasured — both produced by `color-mix`, which is why they went unnoticed. **A
computed-value reading reports the un-composited mix and is wrong;** every number here was
sampled from rendered pixels through a 1×1 canvas.

The four surfaces text can land on are `--surface`, `--code-bg` (`pre`, inline `code`,
`.filter-box`, the `table.tree` root row — and, until v1.17.0, zebra rows), the row-hover
fill, and — until v1.9.0 — the `aside` tint. A new token must clear its ratio against **all**
of them, not the easiest one.

Current ratios worth keeping to hand: `--muted` 4.53 on `--code-bg` / 5.47 on `--surface`;
`--red` 4.73 / 5.72; `--rule-light` 3.05 on `--surface` (exactly the 1.4.11 floor,
deliberately) and 2.52 on `--code-bg`; `--label` 7.86 on `--surface`, 6.51 on `--code-bg`,
9.03 on `--surface-alt`.

**`--label` is `oklch(0.810 …)`, up from 0.767, because the two grey tiers were one grey with
two names.** At 0.767 against `--muted`'s 0.710 they shared hue and chroma and differed only
0.057 in L, so ΔE_ok was 0.057 — under 3 JND by the yardstick this file applies to
`--data-2`/`--data-3`. The difference from those two is that these **co-occur**: `.scorecard`
puts `--on-surface`, `--muted` and `--label` in one component, and `.byline` (muted) sits
directly above `h3` (label). 0.810 gives ΔE_ok **0.100**, about 5 JND, and keeps `--label` a
clear 0.167 in L below `--on-surface` so the label tier still reads as secondary.

**The direction was forced, not chosen.** `--muted` cannot get quieter: it is already at 4.53 on
`--code-bg`, three hundredths above the 4.5 floor, so the only way to widen the gap was to move
`--label` toward body copy. That also fixes the print block, where the two tokens had been
*identical* in lightness (both 0.545, so the tiers were literally one colour on paper); print
`--label` is now 0.470, measured 6.93 on white and 6.36 on the `0.97` grey against print
`--muted`'s 4.99 / 4.58. Same story in both modes: **label is the tier that moves toward body
text, muted is the tier pinned at the contrast floor.**

`--label`'s `/* was */` note is now `#b7bfe4`, recomputed through the same Oklab path
`.github/palette-check.py` uses, so check 3 still passes. It has no `mermaid-palette.json`
entry, so nothing else needed re-projecting.

**The row-hover fill darkens instead of lightening, and it is a flat token.** It was
`color-mix(in oklch, var(--rule-light) 50%, transparent)`, compositing to `rgb(76,79,95)` over
`--surface` — which lifted the row toward the accents on it and took every one below 4.5:1
(`--red` 2.84, `--purple` 2.91, `--muted` 3.12, `--pink` 3.35, `--label` 3.84, `--link` 4.45,
only `--on-surface` surviving at 7.60), so hovering a row failed 1.4.3 for every coloured or
linked cell in it. Now `background: var(--surface-alt)`: 5.87 (`--purple`) to 15.35
(`--on-surface`). Darker-on-dark is the weaker affordance and worth it — the fill is 1.15:1
against `--surface`, the same order as the striping it replaced. `--surface-alt` rather than
another `color-mix`: it exists, needs no compositing to reason about, and is the only other flat
surface in the sheet.

**`aside` has no fill at all, on screen or on paper.** The tint composited to `rgb(61,64,78)`,
where `--muted` measured 3.95, `--red` 3.61, `--purple` 3.69 and `--pink` 4.25 — so a `cite`,
`.sc-note`, `.count`, `::marker` or status span inside a callout failed while `--label`, the
aside's own colour, passed at 4.87. Print had already found this on white (`--label` 3.58:1) and
dropped the tint there; the screen case was the same failure one step milder and the fix was
never carried back. Deleting the declaration retired the print override too. The orange accent
bar still marks the callout.

**`--red` is `oklch(0.735 …)`, up from 0.700.** At 0.700 it measured 4.14 on `--code-bg`, so
`.correction` failed inside `pre` and `.filter-box` — the budget had checked `--muted` on that
surface (4.53, passing by 0.03) and not the accents. 0.735 gives 4.73 / 5.72 / 6.57 on
`--code-bg` / `--surface` / `--surface-alt` and lifts the `.verdict-failed` chip from 5.00 to
5.72; 0.725 is the first value that clears 4.5, at 4.56, and 0.735 was taken for headroom. It
moved `--red` closer to `--pink` in L (0.735 against 0.742) — ΔE_ok 0.076, ~3.8 JND on a 32° hue
separation, so a `--pink` `th` and a `--red` `.correction` in one table stay distinct. `--red`
has no `/* was */` note and no `mermaid-palette.json` entry, so the change had no hex projection
to keep in step.

**`--purple` on `--code-bg` is 4.23 and was left alone.** Purple is `h2`, the `pre` accent bar
and `::selection`. The bar is non-text and clears 1.4.11 at that ratio; nothing puts purple
*text* on the grey, since an `h2` never renders inside a `pre` or a table cell. It is mirrored
into `mermaid-palette.json` twice and carries a `/* was */` note, so moving it costs a hex
recomputation in two files to fix a case that does not occur. Recorded rather than fixed.

**Borders drawn on `--code-bg` take `--rule`, not `--rule-light`.** At 2.52 on that surface,
three components whose only boundary sits there all failed 1.4.11: `.filter-box` (whose border
is the only thing marking it as an input), `.mermaid-zoom` (sits on the `pre`), and
`pre.mermaid:hover` (the ring that makes a diagram read as clickable on touch). `--rule` is
`var(--muted)` at 4.53 there. No new token: the sheet has exactly two rule weights and this is
the heavier one. The side effect is wanted — a control now reads stronger than a passive
container like `details`, which keeps `--rule-light` on `--surface` at 3.05.

**`em` carries no colour.** It was `--label`, 6.75:1 where the copy around it is 13.36:1 —
emphasis at half the contrast of the text it emphasises. Deleted rather than reassigned, so
`em` inherits, which is what makes it correct inside an `aside`, a `blockquote` or a
`.sidenote`: it matches its surroundings instead of overriding a colour those containers had
already chosen. The italic carries the emphasis, from the variable font's real italic face.
`cite` stays distinguishable on family and upright stance, which is what that distinction
always rested on.

**The data ramp exists so a diagram category cannot borrow a prose accent.** `--data-1` is
`oklch(0.790 0.077 255)`, moved off the link hue: it was `oklch(0.790 0.100 216.800)` against
`--link` at 216.782, a 0.02° collision (ΔE_ok 0.038), so the `ext` classDef fill and the pie's
first slice *were* the link colour. 255 puts it 38.2° from `--link`, 45.9° from `--purple` and
≥85° from every other ramp member, which is the comparison that matters since those appear
together in one diagram. Chroma 0.077 is 71% of maximum in-gamut chroma at that lightness and
hue, matching the ratio the old value held; `--surface` text on the new fill measures 7.39:1.
Verified by rendering a pie and a `classDef` flowchart: `#99bdec / #de8dc3 / #74caa6 /
#bbc175`, four visibly distinct categories.

`--data-2` (9.4° off `--pink`) and `--data-3` (9.6° off `--green`) sit under the ~10° threshold
where a hue shift becomes visible — ΔE_ok 0.020 and 0.017, about one JND. Separated in name
more than in appearance, and left that way deliberately: nothing in a diagram puts a category
fill beside body copy, so the collision costs less than `--data-1`'s did, and moving them
means recomputing two more hex projections.

**Forced colors: shadows are suppressed, so anything whose only boundary was a shadow needs a
border.** That is the general rule behind both fixes below, and the reason the print block's
`inset 0 0 0 1px currentColor` could not simply be reused.

- **Semantic chips outline themselves.** `code, .verdict, .badge { border: 1px solid
  currentColor }`. Emulated, every `.verdict-*` fill resolves to `rgb(255,255,255)` with
  `rgb(0,0,0)` text, so all four verdicts become one appearance. The **state** survives
  regardless, because the chip's text says `PASS` / `PARTIAL` / `FAILED` / `N/A` — the fill is
  redundant with the label, which is why a border suffices and a generated glyph would be both
  unnecessary and unlocalisable. What the border restores is the boundary, not the meaning.
- **Tables carry a real border.** An earlier note here claimed "the header rule and row rhythm
  survive"; they do not. Measured: `table` `box-shadow: none`, `th` `box-shadow: none` (the
  inset header rule is a shadow too), `td` `border: 0px none`, `th` background resolving to
  `rgb(0,0,0)` identical to the rows below it. A pixel scan down the right edge returned a
  single value: no outer rule, header indistinguishable from data. `table, th, td { border:
  1px solid currentColor }` — verified, the edge now returns five distinct values including the
  forced foreground.

Fills inside a table still flatten (`--code-bg` resolves to `Canvas`, taking the `table.tree`
root tint with it) and that is left alone: the user's own rendering is the point of the mode.
What was restored is the grid, not the tint.

## Form follows role

Three families were drawn the same way and meant different things. They are separated by
*form*, so the shape carries the role and colour is free to mean one thing.

**A filled chip is a state. An outlined chip is a label.** `.verdict-*` keeps its fill — pass
/ partial / failed / N/A are states of a claim and the hue does real work. `.badge` is
`color: var(--label)` with `box-shadow: inset 0 0 0 1px currentColor` and no fill. It was
three fills (`--green`, `--orange`, `--red`) for **Tier 1 / 2 / 3**, which are ordinal levels,
not health states, so a green-to-red ramp told the reader tier 3 was failing. It also put
`--red` on three meanings at once (`.badge-t3`, `.verdict-failed`, `.correction`).

`.badge-t1` / `-t2` / `-t3` **are not removed** — consumers emit `class="badge badge-t3"` and
that markup keeps working; the variants simply carry no declarations, so there is nothing to
keep in step. The ring is `currentColor`, so it tracks the text and clears 1.4.11 at the
`--label` ratios above.

**What that trades away.** Tier is no longer scannable at a glance down a long index — the text
always carried the level, so nothing is *lost*, but ranking is read rather than seen. Three steps
of one new hue was costed and rejected: three `:root` tokens **plus three print overrides**, each
clearing 4.5:1 on all four backgrounds, out of free hue gaps 20–27° wide, inside which a
three-step ramp reads as one colour at 0.8em. If tier scanning matters, the cheap version is
weight or ring thickness on the existing hue.

**A border means interactive; an accent bar means passive block.** `.scorecard` was a 1px
`--rule-light` box, identical to `details`, `.nav-group`, `.nav-list`, `.filter-box` and
`.mermaid-zoom` — eight bordered instances in the fixture, so a data panel, a disclosure
widget, a form field and a button all read as one object. `.scorecard` now takes
`border-inline-start: var(--accent-bar) solid var(--rule-light)` with the `pre` / `aside` /
`blockquote` padding, and every remaining bordered box in the sheet is something you can
click, type in or open. `--rule-light` rather than a new hue because the scorecard is
structural rather than semantic, and because it is the colour the border already was.

**Three prose accents carry two or three roles each, and that is accepted, not overlooked.**

```
--pink    h1, th
--purple  h2, pre accent bar, ::selection
--orange  strong, aside accent bar, .unverified
```

The overlap a reader can actually see is `--orange`: `sample.html` puts `strong` and
`.unverified` in adjacent paragraphs, so orange means *emphasis* on one line and *status* on
the next. It stays because form separates the other two pairs — `--pink` is a 1.75em heading
against an italic 0.95em table header, `--purple` a heading against a 3px bar and a selection
fill — and none of the three collide in one glance. Repainting `.unverified` means a fifth
semantic hue plus its print override, clearing 4.5:1 on four backgrounds, out of the same
20–27° gaps that killed the tier ramp, for a weaker reason.

**What this means for the next accent.** The budget is spent. A new role takes an existing
accent *plus a different form* (weight, bar, ring, fill), the way `.verdict` and `.badge` are
separated, or it takes `--data-1..4` if it lives in a diagram. Adding a hue is the last
resort, and a hue reused for a third prose role needs a line here saying why the two cannot
appear together.

## Editor themes

The palette is shared with `themes/`, but the *slot map* — which token paints which syntax
class — is a separate decision, and prose logic does not transfer to an editor. In prose,
colour is sparse: a `--pink` h1 and an orange `strong` sit in a field of white body serif, and
low chroma reads as restraint. In an editor, colour is the whole information channel and
almost every glyph carries one, so the same chroma reads as wash.

**`--label` is the doc's caption tier, not a code tier.** It paints `figcaption`, sidenotes,
`dd`, `footer` — content deliberately behind the body. The first Rider scheme handed it 18
slots, including braces, brackets, parentheses, comma, semicolon, dot, parameters and both
field kinds. That collapsed most of a C# buffer into one blue-grey band at C 0.053. Upstream
Dracula paints punctuation at `fg`; so does this scheme now (`--on-surface`, 7.86 → 13.36
against `--surface`). Parameters moved to `--orange`. `--label` still carries instance and
static fields, which are legitimately secondary.

**Types cannot sit on plain `--purple`.** At L 0.698 / 5.10 on `--surface` it is the dimmest
accent in the palette, and in C# type names are the highest-frequency token there is. They use
`{{purple.bright}}` (#bfa4ed, 6.40) — the existing `.bright` lift in `create-themes.nu`, not a
new placeholder and not a palette change.

**Three alternatives were rendered and rejected**, all variants of adopting Dracula's full slot
map: functions to `--green`, strings to `--data-4`, numbers to `--purple`. They separate more
channels, but `--data-4` (#bbc175) reads olive rather than yellow at this chroma, and moving
strings off green breaks the one cross-medium tie the theme has — the stylesheet paints inline
`code` green, so a string in the editor and a `<code>` span in the doc are the same colour.

**Do not fix this by raising chroma in `:root`.** Every ratio in [Colour and the contrast
budget](#colour-and-the-contrast-budget) was measured against those values, and the tokens are
inlined into every published document. A theme that reads dim is a slot-map problem first.
Verify by rendering the *generated* `.icls`, not the template — the placeholders hide which
hex actually lands.

## Mermaid

### Init config

`theme: 'base'` + explicit `themeVariables`, **never `theme: 'dark'`** — the stock dark theme
ignores this palette entirely.

**Hex, never `oklch()`.** khroma throws "Unsupported color format" and aborts init, so no
diagram renders at all. Values mirror `mermaid-palette.json`; CI enforces the match.

**`darkMode` belongs *inside* `themeVariables`.** `mermaidAPI` passes only
`config.themeVariables` to `base.getThemeVariables()`, so a root-level `darkMode` never
reaches the theme and every derived colour is computed light-mode — ER rows come out
`lighten(mainBkg, 75)`, near-white under light `textColor`.

**`fontFamily` and `fontSize` are the only non-colour `themeVariables`**, deliberately not
mirrored into `mermaid-palette.json`: that file catches hex drift and a font stack has no hex
to drift. `fontSize: '1rem'` tracks the reader's root size where mermaid's default is a
hard-coded 16px.

**`background` is inert.** Set to `--code-bg` to match the `pre` a diagram used to render in,
but measured across 12 diagram types (flowchart, pie, ER, class, sequence, state, gantt,
journey, quadrant, gitGraph, mindmap, timeline) it never reaches the output: every SVG canvas
is transparent, there is no full-size background rect, and the hex appears nowhere in
mermaid's injected CSS. Correct-by-intent rather than load-bearing.

**The sequence note is themed as of v1.17.0; for four releases it rendered mermaid's stock
yellow.** `themeVariables` covered nodes, clusters, edges and pie slices but nothing in the
`note*` family, so a `Note over` came out fill `#fff5ad`, text `#333`, border `#f9f7e6` — the
only light surface on an otherwise dark page, at every width on both fixtures. `noteBkgColor`
`--code-bg`, `noteTextColor` `--on-surface`, `noteBorderColor` `--rule-light` puts the note on
the same footing as a node, with the lighter rule weight around it so it reads as an
annotation rather than a second node.

**`actorTextColor` is not needed, and the actor label is not painted twice.** A
`querySelectorAll('text,tspan')` sweep returns each actor name twice, once computing `#343746`
and once `#f8f8f2`, which reads like a dark layer hidden under a light one. It is not: mermaid
emits one `<text class="actor actor-box">` wrapping one `<tspan>`, the sweep matches both, and
the parent `text` has no direct text child to paint. Setting `actorTextColor: '#f8f8f2'` moved
neither value, so it is not in `mermaid.js` — a themeVariable that changes nothing still has to
be kept in step by two CI gates. **Probe a `tspan`, not its parent `text`,** before believing
this one again.

**The CDN pin is 11.16.1; the bump from 11.16.0 was pixel-identical.** Both versions of both
fixtures rendered at 390/768/1280/1920/2560 and diffed on every SVG box, text-node width and
node-label overflow: zero differences, zero console errors, three zoom buttons in both. It is a
patch release (prototype-pollution hardening GHSA-c4c3-pg64-4m4v, a `compileCSS`
sibling-combinator fix, architecture-diagram ordering) and it deprecates
`mermaidAPI.setConfig()`, which this template never called.

### Label measurement

**`fontFamily` is set at the top level of the config *as well as* in `themeVariables`, and both
copies are load-bearing.** The themeVariable reaches the CSS mermaid injects, so it decides
what labels are *painted* in; the root one is what `calculateTextDimensions` measures with, so
it decides how wide a label box is *computed* to be. With only the themeVariable set, every box
was sized for mermaid's default `"trebuchet ms", verdana, arial` and painted in monospace, 1.31×
wider than its box: a sequence `Note over` rect came out 235px around 307px of text. The root
`fontFamily` took it to 327px; it measures 404px today. **The measurement font is the render
font or the arithmetic is wrong.**

`sequence.noteFontFamily` / `noteFontSize` are **not** the fix: accepted by `initialize` and
read back from `getConfig()`, but through 11.16.1 they change nothing. Swept `noteFontSize: 26`
and `noteFontFamily: 'Courier New'` — the rect measured exactly 235px in all three, and
re-swept on 11.16.1 it was unmoved at 404px.

### Diagram sizing

Label size follows SVG scale, so both ends of the viewport range are the same bug.

**Wide end: `pre.mermaid svg { width: 100% }`** stretched a viewBox'd SVG to its container and
multiplied label size with it — 13.9px at 390px → 36.8px at 1280px → **51.7px at 1920px**,
1.35× the h1, set by nothing but how few nodes the graph had. `width: auto` pins labels to the
size mermaid asked for; `max-width: 100%` still shrinks a graph too wide to fit; `text-align:
center` keeps a small one centred (in **both** layouts — it once lived on `body.conn-map` only,
so an inline diagram narrower than its column hugged the left edge in the default one).
`fontSize: '1rem'` alone does not fix it: still 47.1px at 1920px.

**Narrow end (v1.17.0): below 600px the diagram renders at natural size and scrolls.** At 390px
against 16.2px body copy the sequence diagram's label box measured **8px** and the quadrant
chart's **13px** — diagram text at half the size of the prose it illustrates. At ≤600px
`pre.mermaid` takes `overflow-x: auto` and the SVG drops its cap: 18px labels at 320 and 390px,
the sequence SVG 764px inside a 351px column, scrolling inside itself.

**The natural width comes from a custom property, because CSS cannot otherwise recover it.**
With `useMaxWidth` at its default, mermaid writes `width="100%"` as an attribute and its real
size as an inline `max-width: 764px`. Two attempts failed first:

1. `width: auto` + `max-width: none` — an SVG with a viewBox resolves `auto` to its container,
   so the diagram stayed 351px wide at 390px, labels still 8px.
2. Copying the inline `max-width` into the inline `width` — broke the band *above* the
   breakpoint: at 768px the diagram became a fixed 764px inside a 691px column and overflowed
   under `overflow: visible`, a page-level sideways scroll, the one thing the width work exists
   to prevent.

So `mermaid.js` copies the inline `max-width` into `--natural-width` (no layout effect of its
own) and the ≤600px rule reads `width: var(--natural-width, auto) !important; max-width: none
!important`. The fallback covers `body.conn-map`, whose fences set `useMaxWidth: false` and so
carry a real width attribute and no inline `max-width`. `!important` fights mermaid's own inline
styles, the same reason the pre-existing `body.conn-map pre.mermaid svg` rule carries it, and
that selector is repeated inside the media block because it is more specific *and* `!important`
— source order alone would not win. Verified: identical diagram widths at 601 / 768 / 899 / 900
/ 1280 / 1920 / 2560px, and no document-level sideways scroll on either fixture at 320 / 390 /
600 / 601 / 768 / 899 / 900 / 1280 / 1920 / 2560px, or at 200% text zoom at 390px.

**`pre.mermaid svg { overflow: visible }` exists because some diagram types write a viewBox that
does not contain their own content.** The outermost `<svg>` gets `overflow: hidden` from the UA
stylesheet, so anything outside the viewBox is clipped rather than merely untidy.
`quadrantChart` forced it: a fixed `0 0 500 500` from `chartWidth`/`chartHeight` with point
labels centred on the point, so a long label overruns the canvas by 70.2 user units left and
99.8 right, both sliced off. `pre.mermaid` needs it too or the inherited `overflow-x: auto`
clips at the same place, and `.mermaid-overlay svg` needs it or the zoom shows the truncation it
was opened to escape.

**The cost of the narrow-width scroll container is that those labels clip below 600px:**
`overflow-x: auto` forces computed `overflow-y` to `auto`, so `visible` stops applying there.
Accepted — at that width the labels were present but 13px, and the zoom overlay shows the whole
diagram at 95vw either way. Above 600px nothing changed.

**A JS `refit()` that grew the viewBox to the measured `getBBox()` was tried and reverted.** Run
from the existing `MutationObserver`, it fires when mermaid inserts the SVG, before the
flowchart's `foreignObject` labels have laid out, so the bbox is enormous: viewBox `0 0 368 …` →
`0 0 25727 27839` at 1280px, inline `max-width` dragged to 25727.2px, scaling with the viewport
because the unstyled labels did. Getting it right needs a settled-layout signal the observer
does not have; one CSS declaration needs no timing at all.

### Zoom

**The clone is stripped of mermaid's own sizing** so the overlay's CSS governs every diagram
identically. `calculateSvgSizeAttrs` writes `width="100%"` plus inline `max-width:NNNpx` when
`useMaxWidth` is true and `width`/`height` attributes when false (what the connections maps
set), and an inline `max-width` outranks the stylesheet — left in place, the zoom magnifies in
one layout and does nothing in the other. `setupGraphViewbox` always emits a viewBox, and that
is what scales. The overlay sets `width`/`height`, not `max-*`: `max-width` alone leaves a small
diagram at natural size, a zoom that does not zoom. Verified 95%×95% in both layouts.

`securityLevel` defaults to `strict`, which sanitises `click` directives away; a consumer with a
trusted source sets `window.mermaidSecurityLevel = 'loose'` in a preceding classic script tag.
The overlay throws loudly if `#mermaid-zoom` is missing — without it, zoom dies on a bare
`TypeError` pointing nowhere near the missing element.

**The `pre` itself is a named, focusable region as of v1.17.0**: `tabindex="0"`, `role="region"`
and an `aria-label`, set when the button is injected, because below 600px the `pre` is a
sideways scroll container and `README.md` already requires a reachable, named stop for those
(WCAG 2.1.1). The name is the fence's own `accTitle:`, falling back to the localisable zoom
label — a diagram's title beats a button verb, and it is already an author obligation.

## Connections-map layout

`body.conn-map` has exactly two sections in order: **(1) Links, (2) Graph**. For topic maps the
Links column is antecedents/descendants of the focus; for year-slice maps it is the drawn items
newest-first. Above 900px Links sits left and sticky, graph right; below it stacks.

**Markup order is the layout order — the stylesheet no longer reorders.** Until v1.8.0 the
markup was (1) Graph, (2) Links and the CSS reversed it with `order: 1` / `order: 2`, so the
visual leading column was Links while tab and screen-reader order started in the graph on the
right. Measured at 900 and 1280px: Links at x=45 / x=64, Graph at x=305 / x=386, against the
reverse DOM order — a sighted keyboard user tabbed away from where their eye had started.
Deleting the two `order` declarations and swapping the sections produces a pixel-identical
layout (verified at 899 / 900 / 1280px, Links 220–282px sticky at the leading edge, sticky
column holding at y=120 after a 1200px scroll) with reading order and visual order agreeing.

**That was a breaking change for consumers, and the break is silent.** A page emitted with the
old (Graph, Links) markup that inlines a v1.8.0+ stylesheet renders with the graph in the
narrow sticky column and the link list filling the page. Nothing errors. Supporting both orders
behind `:has(> .links)` was rejected: two layout paths in a file every consumer inlines
verbatim.

**The article sets layout only, never width.** It previously carried `width: min(96vw, 1600px);
max-width: 96vw; left: 50%; transform: translateX(-50%)`, breaking out of the page container to
be *wider* than the default layout — so a connections map and an ordinary page never shared a
left edge, and the 1600px cap silently disagreed with the body's own cap. `pre.mermaid` broke
out a second time to `90vw`. Both breakouts were **deleted rather than ported**: the container
is `--page-width` (90vw) itself, so there is nothing left to escape to, and the SVG renders at
natural size, so extra container width no longer changes the diagram. Verified body width,
article width and h1 left edge identical across both fixtures at eight viewports.

**The full-width row is `article > *`, not an allow-list of three selectors.** It was
`> h1, > .byline, > .subtitle`, so *any* other direct child silently joined the two-column flex
row instead of spanning it: measured at 1280px with a bare `<p>`, a third `<section>` and a
`<footer>` injected, the paragraph landed at `x=64 w=471` beside the Links column and the three
sections split the row `282 / 168 / 112px`. Same silent-visual-break class as the section-order
change, and a generator that grows a footer triggers it without touching the stylesheet. `> *` at
(0,1,2) loses to `> section:nth-of-type(1)` at (0,2,3), so the column rules still win and the
shipped layout is pixel-identical (Links `x=64 w=282`, graph `x=386 w=830`) with the three extras
each spanning the full 1152px. It also retired `.subtitle`, which had a rule here and no user
anywhere in the repo — a class a consumer has to guess at is worse than no class.

`overflow: visible` on `pre.mermaid` is unconditional as of v1.13.0, so the conn-map-only copy
of that rule is gone: the base `pre` rule's `overflow-x: auto` would otherwise clip a diagram's
drop shadow, which is the same reason the label-clipping fix needs it.

## Interaction states

**The press feedback on `.nav-list li a` was inert for two reasons, both measured.** It read
`:active { transform: scale(0.96); transition: scale 0.12s ease-out }`. The transition named the
independent `scale` property while the rule set `transform`, so nothing animated — sampled every
25ms through a real mousedown, `transform` was `matrix(0.96, 0, 0, 0.96, 0, 0)` on the first
frame and identical on all six. And the declaration sat inside `:active`, so it vanished with
the state: `transform: none` 30ms after mouseup. Press and release both snapped. Now `scale:
0.96` in `:active` with the transition on the base rule: 0.987 → 0.976 → 0.968 → 0.962 → 0.96
pressing, 0.964 → 0.976 → 0.987 → 0.995 → 0.999 releasing. **A transition belongs on the resting
rule, and `transform` and `scale` are different properties.**

**`.mermaid-zoom` was the one control outside that language.** The only real `<button>` here, and
it had neither thing every other interactive surface has: `:hover` colour and fill changing with
no transition while `a` and `summary` ease at 0.15s, and no press state at all. It now carries
`transition: color 0.15s ease-out, background-color 0.15s ease-out, scale 0.12s ease-out` on the
resting rule plus `scale: 0.96` in `:active` — measured 0.987 → 0.973 → 0.963 → 0.96.

**`[tabindex="0"]:focus-visible` is in the focus rule, because the one stop this sheet does not
own is the one consumers are told to add.** `README.md` requires `tabindex="0"` on anything
that scrolls sideways, and neither the `pre` nor a future table wrapper has a selector of its
own. Before: the focused `pre` fell back to Chromium's `1px auto rgb(0,95,204)` at `0px` offset
against `2px solid --link` at `2px` offset everywhere else. Not a contrast failure — the
default ring paints a white line first, 14.24:1 against `--surface` — so this is consistency
alone. After: the `pre` ring reads `rgb(143,201,217)` at 7.81:1, and the attribute selector
covers the wrapper before it exists.

**No `border-radius` in the `:focus-visible` rule.** It carried `border-radius: 3px`, which
made `.filter-box` corners tighten 4px → 3px at the moment the ring appeared, and applied
unevenly — `.nav-list li a` (0,1,2) outranks `a:focus-visible` (0,1,1), so nav links kept 2px
while plain links took 3px in the same keyboard state. Chromium already rounds an outline to
the element's own radius plus offset, so removing it is what makes the ring follow each
surface. Verified by Tab: `a`, `summary` and `.filter-box` all render `solid 2px` at `2px`
offset; inline links get square-cornered rings, which is the shape of an inline box.

**`.nav-list` radius is `calc(var(--radius-sm) + 0.3rem)`**, not `var(--radius)`. Outer radius
= inner radius + padding: the child link is 2px inside 4.8px of padding, so 6.8px is concentric
where a flat 4px left the hovered row's corners pinched against the container's. The `calc`
tracks the padding — change one and the other follows.

**`pre.mermaid:hover` gets a 1px `--rule-light` ring.** Before it, `cursor: zoom-in` was the
*only* signal a diagram was clickable — `tabindex` null, `role` null, no hover rule, no focus
style. A cursor does not exist on touch and is never announced, so on a phone the diagram was
an unmarked click target. The ring is instant, not transitioned: hover is high-frequency and
does not want motion.

**The overlay's way out is a `✕` glyph on `.mermaid-overlay::after`**, top-trailing corner,
`--label` on the backdrop. Click-anywhere and Escape both dismissed it before and still do;
neither was advertised, and `cursor: zoom-out` is invisible on touch. A glyph rather than a word
because this stylesheet is inlined verbatim by consumers who cannot localise a string in it, and
`content: "✕" / ""` behind `@supports` for the same reason the outbound arrow uses that pattern
— measured through CDP `Accessibility.getFullAXTree`, zero nodes name the glyph, so a screen
reader is not told about a control it cannot reach. It is a cue on an already-clickable surface,
not a new target.

The overlay is `transition: opacity 0.2s ease-out`. With the default `ease` the backdrop
measured 0.026 → 0.497 → 0.80 → 0.94 → 0.999 at 40ms intervals — near-invisible for the first
frame, then a rush; the click felt late. Every other transition in the sheet was already
`ease-out`.

## Keyboard and assistive technology

**Zoom is a real `<button>` that `mermaid.js` injects, not a focusable `pre`.** Before it, the
only way to zoom was clicking the SVG: `tabindex` null on both `pre` and `svg` with zero
focusable descendants, so Tab produced 12 stops in `sample.html` and none was the diagram
(WCAG 2.1.1). Two cheaper fixes were rejected —

- `tabindex="0"` + `role="button"` on `pre.mermaid` makes the button's content presentational,
  hiding the SVG's own `graphics-document` node and its name. The control would work and the
  diagram would stop existing.
- `tabindex="0"` with no role leaves a focusable generic, and `aria-label` cannot name
  `role=generic`, so it announces nothing and nothing hints that Enter zooms.

The injected button is a native control: keyboard and pointer for free, an accessible name of
its own, the SVG untouched, and it doubles as the touch affordance `cursor: zoom-in` could never
be. Measured 138×42, in the tab order, focus ring from the shared `:focus-visible` rule,
`display: none` in print.

**The observer that creates it has to be idempotent.** Mermaid rewrites the `pre`'s children
after the first render, so a one-shot `if (pre.dataset.zoomable) return` guard let the second
pass delete the button and then blocked recreating it — `dataset.zoomable` set, zero buttons in
the DOM. It now re-adds the button whenever one is missing and marks the *SVG* rather than the
`pre` for the click listener, so appending the button (itself a `childList` mutation) is a no-op
on the next tick instead of a loop.

**The overlay is a modal and now says so.** It measured `role` null, `aria-modal` null, no name,
no `tabindex`, `overscroll-behavior: auto`, with focus never entering and never returning. It now
carries `role="dialog"`, `aria-modal="true"`, an `aria-label`, `tabindex="-1"`, takes focus on
open, sets `inert` on every other `body` child, and restores focus to the button that opened it.
`overscroll-behavior: contain` keeps the page underneath from scrolling.

**It is `inert` while closed, and that is what keeps it out of the page.** `role="dialog"` fixed
the open state and broke the closed one: the overlay is only `opacity: 0; pointer-events: none`,
never hidden, so it stayed in the accessibility tree between zooms — measured closed, `display:
flex`, `visibility: visible`, `hidden: false`, and `{role: "dialog", name: …, ignored: false}`
sitting **first in the tree**. Every generated page opened with a permanently-open empty modal,
and `aria-modal="true"` is a page-wide instruction to disregard everything outside it.

`overlay.inert = true` at init, `false` in `zoom()`, `true` again in `dismiss()`. One property
drops the node from the accessibility tree *and* blocks hit testing, and it does not interfere
with the opacity transition. Verified: zero `dialog` nodes while closed, first unignored roles
`main` / `article`; on open, present, named and focused with both siblings `inert`; Escape
restores `inert: true` and returns focus to `.mermaid-zoom`. `aria-hidden` was not used — it
hides from assistive tech while leaving the element focusable, the defect it would paper over.

**The zoom button is named from the diagram, not from a constant.** `textContent` was a
hard-coded `'Zoom diagram'`, so a page with two diagrams exposed two identically-named buttons —
verified in the AX tree by adding a pie chart to `sample.html`. The distinguishing text already
existed and was being thrown away: mermaid writes each fence's `accTitle:` into the SVG's root
`<title>`, which is exactly the obligation `README.md` demands. `aria-label` is now
`label + ': ' + title` (`'Zoom diagram: Decision flow sample'`) with the visible text left short;
the overlay takes the same name on open and the `pre` region takes the bare title.

`window.mermaidZoomLabel` overrides the label word, following the `window.mermaidSecurityLevel`
convention. Both strings were hard-coded English in a file consumers inline verbatim — the same
constraint that made the overlay's close cue a glyph. A glyph could not carry this one, so the
override is the way out.

**`accTitle` / `accDescr` are consumer obligations, modelled in both fixtures.** The SVG had a
`graphics-document` role with no accessible name at all. These are fence directives, so no
stylesheet change can supply them.

**The sidenote margin-toggle is inert by design, and its two `display: none` rules must stay.**
`input.margin-toggle` is never focusable and the ⊕ label is hidden, so the Tufte collapse
pattern does nothing here — measured at 1280 and 390px, `.sidenote` is `display: block` at every
width. The rules are not dead weight: consumer generators emit that checkbox and label markup,
and dropping the rules would show raw checkboxes on every published page. What *was* dead is
gone — `label.margin-toggle:focus-visible` could never match a `display: none` label. If the
pattern is ever revived it needs a focusable control, not a hidden checkbox.

## Direction, zoom and growth

**Sidenotes float to the inline end, with the physical value first as the fallback:** `float:
right; float: inline-end; clear: right; clear: inline-end`. Under `dir="rtl"` the old
physical-only rule kept the note on the page's right with a 24px `margin-left` while the `pre`
and `aside` accent bars — already logical — correctly flipped. After: `float` computes
`inline-end` in both directions, the note renders page-right in LTR and page-left in RTL, and
the 24px gap moves from `margin-left` to `margin-right`. The duplicate physical declaration is
deliberate — a browser that cannot parse `inline-end` drops that line and keeps the LTR
behaviour it had before. `margin` became `margin-block` / `margin-inline` for the same reason.

**`th` / `td` are `text-align: start`, not `left`.** With `left` every cell stayed
left-aligned in RTL while the prose around it flipped. Verified by range-measuring the header
text inside its cell: LTR starts 10px from the cell's left edge, RTL 10px from its right.
(`.num` uses `end` for the same reason.)

**`h1`/`h2`/`h3` carry `overflow-wrap: break-word`.** They were the only text in the sheet
without a break rule (`a`, `code`, `cite`, `.sidenote` all had one), so a long title word ran
off the page under text-only zoom: at 320px with the root at 32px, `h1` measured `scrollWidth
301` inside `clientWidth 262` and the connections-map title pushed the document to 367px. After,
the conn-map fixture reflows clean at 200% text zoom and overflows only 23px at 400%.

**`--gutter` folds the safe-area insets at every width, not just under 600px:** `max(2rem,
env(safe-area-inset-left, 0px), env(safe-area-inset-right, 0px))`. A landscape phone is 700–950px
wide — above the mobile breakpoint — with lateral insets around 44–50px, larger than the 32px
gutter that used to apply there, so text ran under the notch. The `0px` fallbacks inside `env()`
are load-bearing: without them a browser that does not support the variable makes the whole
custom property invalid at computed-value time, taking `width: min(100% - 2 * var(--gutter), …)`
down with it. Unverified on a real device — Chromium does not emulate the insets.

**The `.scorecard` overflow under text-only zoom is fixed with a container query, not a media
query.** `section:has(> .scorecard)` becomes an inline-size container and `@container
(max-width: 15em) { .scorecard { grid-template-columns: minmax(0, 1fr) } }` stacks it. `em`
inside a container query resolves against the *container's* font size, so the query is really
"is the text large relative to the space" — exactly the failure condition, and something a media
query cannot see (`em` there resolves against the browser's initial font size; a `max-width:
19em` media rule measured no change at a doubled root).

Two things about that rule are load-bearing:

- **The `:has()` scoping.** `container-type: inline-size` on every `section` also applied
  inline-size containment to the conn-map columns, changing the sticky sidebar from 276px to
  220px at 200% zoom because the content could no longer expand the flex basis. Scoped to
  sections that actually hold a scorecard, the conn-map measures identically at all eight widths.
- **Its source position, after the `max-width: 600px` block.** Container queries add no
  specificity, so source order is what makes it win over the two-column rule there.

Failed attempts on the same problem, so they are not retried: `minmax(0, max-content)` tracks
let the *track* shrink to zero without the `.verdict` chip shrinking with it — `174px 0px` at
320px with the chip spilling out of a zero-width column, a different failure rather than a
smaller one. `auto` tracks plus `overflow-wrap: break-word` moved the number ~40px and fixed
601px only; `break-word` does not reduce a box's min-content contribution (`anywhere` does).

Fixed through 200% text zoom at every width from 320 to 2560px, and re-verified after the
scorecard's border-to-bar change at 320 / 390 / 480 / 601px with the root doubled — document at
viewport width, grid still collapsing to one track. At **400%** text-only zoom the page still
scrolls sideways (`.sc-note`, and the table at ≥601px); that is past what WCAG 1.4.4 asks for and
is not chased.

## Print

**The print block overrides the palette tokens, not the elements.** It used to set
`background`/`color` on `body` alone, leaving every accent at its dark-theme value on a white
page. Measured on white: `.newthought` **1.05:1**, `summary` 1.82, `.verified` 1.96, `strong`
2.09, `h3`/`em`/`blockquote`/`footer` 2.11, `h1` 2.42, `.byline`/`cite` 2.60, `h2` 2.79. The
dark fills survived too, so with background graphics on, near-black text sat on `--code-bg`
fills at **1.67:1**, and with them off (Chrome's default) the light text those fills had backed
was stranded on white — inline `code` 1.85:1, `pre` 1.05:1.

Reassigning the tokens fixes every element at once and both print paths, because the accents
become dark and the fills near-white. Accent lightness is chosen against the **`0.97` grey**
`--code-bg`, not white, because that is the harder background — 4.56–4.64:1 on the grey and
4.97–5.06:1 on white, with `--on-surface` at `oklch(0.2 0 0)` giving 18.1:1. `--rule-light`
sits at `oklch(0.620 …)`: 3:1 against white for 1.4.11 without becoming a heavy line on paper.
`--surface-alt` goes white as well — it is only the overlay backdrop, which cannot be on screen
and on paper at once, but leaving it dark would park a near-black rectangle in the print
stylesheet waiting for someone to reuse the token.

**Page breaks are controlled as of v1.17.0; before, only `h2` was.** Added: `orphans: 2;
widows: 2` on `p`, `break-after: avoid` on `h1`/`h2`/`h3` (replacing the lone legacy
`page-break-after`), `break-inside: avoid` on `tr`, `blockquote`, `aside`, `details`,
`.scorecard`, `.verdict` and `img`, and `thead { display: table-header-group }` so a table
crossing a page repeats its header. Verified against a 7-page Letter PDF of `sample.html`: the
tree table moves whole to page 2 and reprints its header there, the scorecard and both callouts
stay intact, no single line strands.

`pre` is deliberately **not** in that list. A code block can be longer than a page, and
`break-inside: avoid` on something that cannot fit is either ignored or overflows, so the
guarantee would be a lie for exactly the element most likely to need it.

**`.verdict` prints as an outlined label** — `background: none` plus `box-shadow: inset 0 0 0
1px currentColor`, with the semantic colour moved to `color`. Its fill carried the meaning, and
`color: var(--surface)` would have become white-on-accent: fine with backgrounds on, invisible
with them off. Outlining makes the chip identical either way, each variant keeping its hue at
≥4.97:1. `.badge` needs no print rule — it is already an outlined `--label` chip and `--label`
is one of the tokens print reassigns.

The `aside` tint used to need a second exception here (it composited to `#d9dae1` on white,
where `--label` measured 3.58:1). The tint is gone from the base rule as of v1.9.0, so
`aside { background: none }` has nothing left to override.

## Filter

`filter.js` is the third inlined payload, added in v1.16.0. The stylesheet has shipped
`.filter-box` / `.filter-label` / `.filter-hidden` / `.filter-empty` since the first release and
consumers always had to write their own handler. The script makes the box work for the one
pattern the fixture documents: an `input.filter-box` followed by a table.

Three decisions are load-bearing:

- **The input wires the table it precedes, found by walking forward.** `input.nextElementSibling`
  is the table in the normal case; walking forward to the first following `TABLE` covers a
  `role="status"` line (or anything else) between them. No `closest()` and no id-matching: the
  script never needs to know a consumer's ids, and the input-to-table pairing is the only
  relationship the markup states.
- **The empty line is created, not required.** A consumer that emits a table and a filter box
  but no `.filter-empty` would silently never show the no-matches state, so the script creates a
  hidden one after the table when none exists. It starts `hidden` because the stylesheet's
  `.filter-empty` has no `display` declaration, so UA `display: none` is the only thing keeping
  a freshly created line off the page.
- **No CDN, no build step, no comments.** The whole handler is `querySelectorAll` +
  `classList.toggle`, and it is inlined verbatim like the other two payloads.

The filter is one input, one table, one listener. It does not filter a nav-list, a `details`
group, or multiple tables from one box — the stylesheet styles a box, not a taxonomy, and a
consumer wanting a different shape writes a handler over the same classes.

`.filter-box` is `font-size: 1em`, not the old `max(1em, 16pt)` — 16pt is 21.3px, not 16px; the
iOS-zoom floor is 12pt.

## Unclaimed elements

The sheet styles about forty elements. Four that a document generator can emit were never
claimed, so each rendered in whatever the UA decided, and one of those was the same class of
bug as the mermaid sequence note: a light-mode default surviving inside a dark theme because
nobody had looked. Injected into `sample.html` at 1280px and measured before the fix:

| element | rendered as | now |
| --- | --- | --- |
| `mark` | `background: rgb(255,255,0)`, `color: rgb(0,0,0)` | `--highlight` wash, inherited text |
| `caption` | centred (`-webkit-center`), 17.48px, `--on-surface` | start-aligned, 0.9em italic `--label` |
| `figcaption` | plain body copy, indistinguishable from a paragraph | annotation tier, 0.9em `--label` |
| `figure` | no margins at all, the `*` reset having eaten the UA's | `var(--space-6)` block rhythm |

**Pure yellow on pure black was the worst of it.** Both values are banned everywhere else in
this sheet, and a highlight is exactly what an annotation-heavy generator emits. `mark` now
takes `--highlight`, a wash rather than a chip: `oklch(from var(--orange) l c h / 0.35)`, which
is the same relative-colour syntax `.mermaid-overlay` already uses.

The alpha was swept and pixel-sampled, because a composited value cannot be read from computed
styles:

| alpha | composited fill | body text on it | fill vs `--surface` |
| --- | --- | --- | --- |
| 0.22 | `#504544` | 8.66:1 | 1.54:1 |
| 0.28 | `#5a4d48` | 7.61:1 | 1.76:1 |
| **0.35** | **`#68564d`** | **6.51:1** | **2.05:1** |
| 0.45 | `#7b6353` | 5.25:1 | 2.54:1 |

0.35 is the compromise: the wash reads at 2.05:1 against the page, nearly double the 1.15:1 the
row-hover fill is accepted at, while body copy on it still clears 4.5:1 with headroom. 0.45
reads as a chip rather than a highlight and costs three points of text contrast. Print inverts
the treatment to `background: none; box-shadow: inset 0 0 0 1px currentColor`, the same
outline-what-was-filled move as `.verdict`, so the mark survives a backgrounds-off print.

**`kbd` is a ringed chip, deliberately not `code`.** Same `--code-bg` fill and mono face, but
`--on-surface` text instead of `--green` and an `inset 0 0 0 1px var(--rule)` ring: a shortcut
is not a code fragment, and the ring is the only thing separating them. Pixel-sampled fill
`#343746` with text at 11.06:1. The ring is `--rule` rather than `--rule-light` because it sits
on `--code-bg`, where the lighter weight measures 2.52 — the rule the contrast budget already
sets. `kbd` joins `code, .verdict, .badge` in the forced-colors border list, since an inset
shadow is the only boundary it has.

**A `caption` sits above the table's frame, not inside it.** `caption` is a child of `table`, so
the table's `box-shadow: 0 -1px 0 var(--rule)` top rule painted *above* the caption and the
caption read as a stray first row. `table:has(caption) { box-shadow: 0 1px 0 var(--rule) }` drops
the top rule when a caption is present, so the caption becomes a label over the table and the
frame starts at the header rule. Verified on screen and in the Letter PDF.

`figcaption` stays start-aligned under a centred diagram, which is why the shared rule sets
`text-align: start` explicitly: `pre.mermaid` is centred, and a caption inheriting that would
float in the middle of a full-width column.

## Fixtures are coverage

A fixture demonstrates states; it does not simulate them. Several details in `sample.html` and
`sample-conn-map.html` look like filler and are regression checks. **Shortening any of these
retires the check it exists to be.**

- **The sequence diagram and quadrant chart** in `sample.html`, alongside the flowchart. Both
  label-measurement bugs above shipped and survived because a flowchart is the one diagram type
  that shows neither: its labels are `foreignObject` HTML measured by the browser rather than by
  `calculateTextDimensions`, and its viewBox is computed from the laid-out graph rather than
  from a fixed chart size. The sequence fence's `Note over` is deliberately wider than its actor
  box; the quadrant fence carries two point labels long enough to overrun the canvas.
- **The conn-map focus node's long label.** The connections map is the one fixture rendering
  with `useMaxWidth: false`, so it is the only place a mis-sized node box lands in a
  *constrained* column rather than on an open page — the failure mode the v1.13.0 label-box fix
  was about, which five short labels never tested. The label now wraps to four lines and the box
  grows to hold them: at 1280px, rect 260px around 200px of text, all five nodes `fits: true`,
  the SVG 416px inside an 830px graph column, no document scroll at any of nine widths at either
  root size.
- **The filter's `role="status"` line and its `.filter-empty` line, both visible at once.**
  `README.md` has always asked a consumer who wires the filter for a result-count status region
  and a no-matches line, and neither existed anywhere in the repo — `.filter-empty` was a styled
  class with no instance, so nothing verified it rendered and a consumer had no reference copy
  for the one empty state in the system. The fixture's nav-list filter has no following table,
  so `filter.js` returns early and the pair stays inert and visible, the way the four
  `.verdict-*` chips do. Verified in the AX tree: one `status` node.
- **The `<em>` label says what `em` actually does.** It read `<em>emphasis (label)</em>` long
  after the `em` colour rule was deleted, so the reference a consumer reads named a colour the
  sheet no longer paints. Now `<em>emphasis (inherits its surroundings)</em>`.

## Odds and ends

**`hr` is a `border-block-start`, not a `box-shadow`, because the shadow painted nothing at
all.** It read `border: none; box-shadow: 0 1px 0 var(--rule-light)`. `border: none` collapses
the element to `height: 0px` (measured), and a `box-shadow` on a zero-area box has nothing to
offset — pixel-scanned a 40px band across the `hr` at 1280px and every pixel was bare
`--surface`. The separator was invisible on screen at every width, in print, and in forced
colors, for as long as the rule existed. A real border paints (1px at 3.05:1, which is what
`--rule-light` is tuned for), survives forced colors, and needs no `height`.

The same defect does **not** affect `table`, whose `box-shadow: 0 1px 0 var(--rule), 0 -1px 0
var(--rule)` sits on a box with real height — verified, both rules paint at `rgb(151,159,196)`.
Shadow-drawn rules are fine; shadow-drawn rules on a zero-height box are not. Any future
hairline should ask which it is.

**`--ring` is a token because the `img` hairline was the one colour declared twice as a
literal.** `oklch(1 0 0 / 0.1)` on screen and `oklch(0 0 0 / 0.1)` in print, the only raw
colour values left outside `:root`. As a token, print flips it beside the other thirteen
overrides and the `img` rule disappears from that block entirely, so print carries one
declaration fewer. Deliberately not a palette colour: white-at-10% over an arbitrary image is a
translucent veil, not a hue, and `.github/palette-check.py` never sees it — the alpha-slash form
does not match its `oklch(L C h)` regex, so the parsed token count stays at 17 and the
"expected 17" guard still means what it says.
