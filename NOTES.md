# NOTES.md: the decisions behind the stylesheet

Every generated HTML file carries `tufte-dracula.css`, `mermaid.js` and `filter.js` verbatim. Those
files therefore carry no comments. See `CLAUDE.md`. This file holds what those comments would say.

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
| [Fixtures are coverage](#fixtures-are-coverage) | Which fixture details catch a regression |
| [Repo layout](#repo-layout) | Why `scripts/` holds the Nushell and `.github/` keeps the Python |
| [Odds and ends](#odds-and-ends) | `hr`, scrollbars, `--ring`, the validator |

---

## Fonts

**The body face is Source Serif 4.** It is a variable serif, pinned to an exact jsDelivr version,
in roman and italic.

**The webfont exists for the weight axis.** Every system serif ships 400 and 700 and nothing
between. Nothing else can render the 450 that light-on-dark body copy wants. Nothing else can
render the real 600 on `.newthought`, `strong` and `dt`.

**This face won because its figures are tabular and lining by construction.** A table therefore
aligns in the body serif with no OpenType feature support. Literata, Newsreader, Lora and Petrona
lost. Lora carries Georgia's exact defect, which is old-style proportional figures. None of the
five ship `smcp`, so `.newthought` small caps stay synthesized.

**The fallback path is a real downgrade, not an equivalence.** Offline the stack falls to Georgia.
Georgia has no 450, and it has old-style proportional figures, so tables lose alignment. The repo
accepts that, because the text still renders. `font-display: swap` keeps text visible during the
load.

Georgia stays first in the fallback stack. Noto Serif follows it for Android and ChromeOS. DejaVu
Serif follows for Linux. Charter and Palatino are deliberately absent, because both exist only
where Georgia already does.

**The code face ships as a webfont too.** `--mono-font` names `'JetBrains Mono'` first, and both
styles of it load from `@fontsource-variable/jetbrains-mono` on jsDelivr, pinned like the body
face. The stack used to lead with `ui-monospace`, so the named face rendered only where someone had
installed it and code blocks differed per machine. The order now matches the Rider theme, which
already pins JetBrains Mono as its editor font. Offline the stack falls to `ui-monospace`, so the
degradation path is unchanged. `mermaid.js` repeats this order in both of its literals, because
the measurement font must stay the render font.

**The `blockquote.pull` glyph takes `var(--body-font)`.** It once hardcoded Georgia, which exists
on neither Android nor Linux, so the mark already fell through to another face there. The loaded
body serif renders it identically on every platform.

**Both stacks are tokens, because three rules need the literal.** `.mermaid-zoom` sets
`font: inherit`, which resolves against `pre.mermaid`. That would put the only button in the sheet
in the code face, so the rule sets `font-family: var(--body-font)` after the shorthand. `pre` sets
the family too. Without it, a code block emitted with no inner `<code>` gets a different face than
the inline spans beside it.

`mermaid.js` writes the mono stack out twice as a JavaScript literal. **That is not drift to fix.**
Neither copy can read a custom property. Each copy is load-bearing for a different reason. See
[Mermaid](#mermaid).

**No `-webkit-font-smoothing: antialiased`.** That advice exists for dark text on light. This theme
is the inverse, and grayscale-only antialiasing thins strokes.

## Type scale

The body `font-size` clamp is the **only size lever**. Every other step is em-relative to it,
headings included.

The floor is `1rem`. That is the long-form minimum. It is also the iOS input-zoom threshold that
`.filter-box` inherits. The cap is `1.25rem`. Every bound is `rem` and never `px`, so the page
scales with a reader who raises the browser default.

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

**`text-wrap: balance` sits on `h1`, `h2` and `h3`, not `h4` through `h6`.** All three are short
blocks where a stray last-line word is the defect `balance` fixes, the same reasoning
`text-wrap: pretty` states for paragraph-length blocks elsewhere. `h4` through `h6` render at body
text size, without the wider measure a headline runs against, so they stay off the list.

Nested ratios compound. Check the parent before you add a step. The repo already paid for three
traps.

- **Headings are `em`, not `rem`.** Anchored to the root, they diverge from body copy, which grows
  on a vw clamp. h3 then renders smaller than its own paragraphs.
- **`.verdict` and `.badge` sit at 0.8em, not 0.75em.** They nest inside a 0.95em parent, and
  0.75em lands under the 12px floor. This couples to the body floor. Re-check both when that floor
  moves.
- **`pre code` is `font-size: 1em`** to halt the compounding. `code` and `pre` each carry 0.9em.

**Do not write a `pt` or `px` floor.** An earlier scale used `max(Xem, 12pt)`. It pinned nine
elements to one size. It made body copy the smallest text on a phone. It also ignored the reader's
own setting.

**`h1` and `h2` sit at weight 400. `h3` is 500.** h3 is the one heading at text size. At 400 it
renders lighter than the paragraph beneath it. Heavier than h2 is not an inversion, because h2 is
larger, italic and `--purple`.

**Nothing at text size may go lighter than body copy.** That rule governs h3, h4, h5, h6, `summary`
and `th`.

**`code` and `cite` sit at 0.9em**, which is the x-height-matched size against the mono stack.

**`li` carries no `font-size` of its own.** At 0.95em a bulleted list rendered subordinate to the
body copy beside it. `nav > ul > li` also compounded to the smallest text on the page. The two
contexts that want 0.95em ask for it themselves. `.nav-list li` asks directly, and `nav` asks on
the container.

## Italics

Eight rules slant: `.byline`, `h2`, `th`, `summary`, `blockquote`,
`details.nav-group > summary`, `.filter-box::placeholder` and `.filter-empty`.

**`h3` is upright and `h2` is italic, deliberately.** They are adjacent levels. A shared italic
distinguishes neither, and the hierarchy then rests on size and color alone. An upright h3 gives
the pair a second axis. It also lands where italic costs most: at text size a slanted stem on a
dark surface loses definition.

**`summary` is 450 and `th` is 450.** Both are italic at or near reading size. At 400 each one read
lighter than the copy around it. `th` cannot simply drop the declaration, because the UA default is
bold. Italic and `--pink` carry the distinction instead.

## Width and measure

**Page width is one number**, `--page-width: min(90vw, 160rem)` in `:root`. `body` and the
`body.conn-map` article both reference it, so the two layouts cannot drift. `90vw` is the
proportional side margin, and it is the dial. `160rem` is the ultrawide backstop. It is `rem`, so
it scales with the reader's root size. `100% - 2 * var(--gutter)` on `body` is the floor. That term
is what respects the safe-area insets folded into `--gutter`.

**Do not add a second width convention, a breakpoint override, or a full-bleed breakout.** Three
attempts failed. The repo records them so that nobody retries them.

1. A `70ch` cap plus a `min-width: 1200px` override to `80vw`. It stranded the copy in a narrow
   column inside an empty container. It also snapped the width in one step at the breakpoint.
2. A `100rem` cap. Same failure, one size up.
3. A gutter and a backstop with no proportional term. That is full-bleed with fixed margins at
   every size.

**"Unused space" is not the metric to minimize.** A page needs side margins that scale.

**The long measure is a standing decision.** Content flows nearly the full window, well past the
conventional 60 to 75 characters. This stylesheet serves dense reference pages with tables and
diagrams. It does not serve book-length prose. Anyone who revisits this owes three facts.

- The cap belongs in `em`, **not `ch`**. `ch` is the advance of `0`. In a serif that is far wider
  than the average prose advance, so a `ch` cap runs much longer than its number claims.
- The cap must be scoped to section children. A bare `p` selector also hits `.byline`, which is a
  flex item in the conn-map header. It also hits the `<p>` mermaid emits inside `foreignObject`
  labels.
- **Smaller type makes the measure worse**, because the container is `vw` and `%` driven.

**Sidenotes stack below 1000px, not below 600px.** The float is `width: 28%`. Between 600px and
about 1280px the note is narrower than any measure worth reading. The body copy beside it keeps the
full container.

**`hyphens: auto` is scoped to the two narrowest prose measures.** Those are the sidenote at 28%
and `.col-2` at half a column. It does **not** apply to body copy, which needs no help at the long
measure. It does not apply to `.nav-list li a`, where a hyphen reads as part of the slug. It does
not apply to headings. Both fixtures carry `lang="en"`, which hyphenation requires.

**The 1000px block and the 600px block are separate on purpose.** Everything in the 600px block is
genuinely phone-sized. Two breakpoints with distinct reasons beat one breakpoint that is wrong for
half its contents.

## Paragraphs and section rhythm

**`section` spacing matches `h2`'s top margin**, so the two collapse to one value. Unequal values
hid a defect rather than caused one. A section that opened with anything other than an `h2` got the
smaller gap. The rhythm then depended on markup the stylesheet does not control.

**`section > :first-child { margin-top: 0 }` was tried and rejected.** It flattens the gap under
the byline. In `body.conn-map` the sections are flex items, where margins do not collapse at all. A
rule tuned for the collapsing case therefore misaligns the two columns.

**`.indented` is the book setting. It is opt-in, and it is two rules.** The paragraphs take
`margin-block: 0`. Every `p + p` takes `text-indent: 1.5em`. The indent hangs off the sibling
combinator, because nothing precedes the first paragraph.

It is a class rather than the default for two reasons. The two conventions cannot mix on one page
without a reader taking it for an accident. The default is also what every existing consumer's
output assumes.

**A sidenote marker must not use `vertical-align: super`.** That grows the line box, which puts
every paragraph with a note off the page rhythm. `.sidenote-number:after` and `.sidenote:before`
use `position: relative; top: -0.4em; line-height: 0` instead. That lifts the glyph with no part in
line-box height.

**`.sidenote` and `.marginnote` reset what a surrounding `.newthought` inherits into them.** Small
caps, weight 600, tracking and the `1.2em` size all inherit, and the natural place for a note is
inside the sentence it corroborates, so a generator that opens a paragraph with `.newthought` and
keeps its note markup there produced a margin note in semibold small caps beside every other note
in its normal register. The reset pins the annotation register: a note renders the same wherever
its anchor lands. **Do not replace the reset with a markup rule instead.** A rendering invariant is
the stylesheet's job; a consumer that ignores the contract must still get a correct note.

**`--space-*` covers block rhythm only. Component padding stays literal.** Six tokens replace the
vertical-rhythm values. The off-scale values stay as they are, deliberately. They are
component-internal padding tuned by measurement. A snap to the scale would move rendered boxes to
satisfy an abstraction. The list indent stays literal for the same reason, because it pairs with
`--tree-step` rather than with the vertical scale.

**`text-wrap: pretty` sits on `p`, `.sidenote`/`.marginnote`, and `figcaption`/`caption`.** It
avoids a lone short word stranded on the last line, the same defect `balance` fixes on headings,
but for blocks too long for `balance`'s cost. Chrome and Safari ship it; Firefox falls back to
normal wrapping with no breakage, so the rule costs nothing where it is not read.

## Lists

**A prose `ul` keeps its markers.** A global `list-style: none` reset rendered bulleted lists as a
run of short paragraphs with invisible nesting. It also made `li::marker` dead code. `ul` and `ol`
share one indent, and `ul` keeps the UA marker progression, muted.

**That is also half of the list-semantics problem.** WebKit drops list semantics from a list with
`list-style: none`. A prose list with markers therefore keeps its semantics natively. `.nav-list`
and `.icon-list` both reset `list-style: none` on the `<ul>` itself, so both need `role="list"` in
the markup, which is a consumer obligation in `CONTRACT.md`.

### `.recent-groups`

**A landing index with several "recently updated, by category" lists is `auto-fit`, not a fixed
column count.** `.edge-list` is always two columns, because an antecedent list and a descendant
list are always a pair. A category index has no such fixed arity. A generator may emit two
categories or eight, and a fixed `1fr 1fr` would either strand empty columns or overflow them.
`repeat(auto-fit, minmax(min(36rem, 100%), 1fr))` sizes itself to whatever count the client emits,
with no per-category selector and no count read from markup.

**That is also why `.recent-groups` carries no breakpoint override, where `.edge-list` needs
one.** At any width narrow enough to matter, two 36rem tracks no longer fit side by side, and
`auto-fit` collapses to one column on its own. A fixed-column grid cannot do that, which is why
`.edge-list` and `dl.timeline` each carry an explicit breakpoint. Adding one here would duplicate
what the track-sizing function already does, against a number nobody measured for this component.

**The bare `minmax(36rem, 1fr)` only fixed the column count, not the surviving column's own
width.** `auto-fit` drops to one column below two tracks' width, but that one column still floors
at 36rem (576px), which overflows the document below that width: a real WCAG 1.4.10 failure on any
phone, confirmed by rendered layout. **`minmax(min(36rem, 100%), 1fr)` is the fix**, the standard
guard against this exact `auto-fit` trap. It changes nothing above 576px and costs no new
breakpoint.

**Item count per category and the "view all" link are a generator concern, not a stylesheet
one.** The CSS lays out whatever `.recent-group` sections arrive. It does not cap a list's length
and does not style the overflow link beyond the plain `a` rules every link already carries.

**A `.recent-group` for uncategorized items is styled identically to a named category.** It is
one class, not two. A muted or demoted "Other" bucket would need a second class family for a
distinction only the heading text needs to carry.

**A `.recent-group .nav-list li` is one line: title leading, its trailing `<span class="count">`
on the same row, never below it.** `a { display: block }` made the anchor claim the full row, so
the date sat on a line of its own beneath the title, at the same size and color as the link
itself. The date outranked the title it was annotating. `.recent-group .nav-list li` is now
`display: flex`. The anchor takes `flex: 1 1 auto` with `min-width: 0` plus `overflow: hidden;
text-overflow: ellipsis; white-space: nowrap`, so a long title truncates instead of wrapping to a
second line and pushing the date off the row. `.count` takes `flex: none` at `--muted` and
`0.82em`, so it reads as metadata, matching every other annotation register in the sheet, and it
never shrinks to make room for the title. Do not revert the anchor to `display: block` inside a
`.recent-group`, and do not let the title wrap: a second line is what this rule exists to prevent.

**`.recent-group` and its `.nav-list` stretch to fill the grid row.** `.recent-groups` already
sizes its tracks with `auto-fit`; without `.recent-group { display: flex; flex-direction: column }`
plus `.recent-group .nav-list { flex: 1 }`, a category with fewer recent items renders a shorter
card, and the "view all" links across a row land on different baselines. The list, not the card,
absorbs the slack, so item rows keep their own height.

### `dl.timeline`

**A timeline entry is content, not annotation.** `dl.timeline > dd` and `> dt` both take
`--on-surface`, where a plain `dd` is the caption tier. The date is the axis a reader scans, so it
may not be the dimmest thing on the page.

**An `h3` date line is the wrong shape.** `h3` is the label tier at weight 500. The date therefore
reads fainter than the event title beneath it, and the dates never align into a column.

**`--timeline-date` exists because era groups are separate lists.** `max-content` sizes each track
against only its own rows. A multi-list timeline then gets an axis that walks left down the page.
`grid-template-columns: var(--timeline-date, max-content) 1fr` lets a wrapper pin one width in
`ch`. The default stays `max-content`, so a single-list timeline needs no number.

**CSS cannot size every list to the document.** No selector reaches a sibling list's content.
`subgrid` does not apply either, because the lists are not tracks of a shared parent grid.

**Measure the widest label. It is rarely the one that looks longest.** `tabular-nums` pins every
digit to exactly `1ch`, and letters stay proportional. A spelled-out century therefore beats a
numeric range. **Measure at weight 500**, which is what `dt` renders at, and **round up**. `ch`
resolves against the element the variable sits on, which is weight 400 and systematically narrower.

**A short `--timeline-date` has no CSS backstop.** `white-space: nowrap` means the label bleeds
rather than wraps. `minmax(var(--timeline-date), max-content)` was measured and does **not** fix
it. The `1fr` sibling consumes the free space before the growth limit is reached. The measurement
instruction in `CONTRACT.md` is the only defense there is.

**`text-align: end` plus `tabular-nums` is not what aligns mixed date formats.** It right-aligns on
the last character. That forms a numeral column only while every label ends in a digit, and real
labels end in `CE` or `s`. `tabular-nums` stays, because it makes the `ch` measurement predictable.
**Do not go looking for the missing column.** **`text-align: start` was rejected**, because it
opens a wide gap between a short date and the rule it labels.

**There is no `.approx` class for the `c.` prefix.** A muted prefix would read well. No generator
emits a span for it, and a class with no emitter is a guess about markup this repo does not
control.

**A floated `.sidenote` cannot escape a `dl.timeline` entry.** The float resolves against the `dd`
rather than the page, so the note lands inside the entry column. **Cite a timeline entry with a
`sup` link into a numbered source list.** That is also the better answer at density. A margin column
loses sync with its anchors down a long page.

**`white-space: nowrap` on the date is released below 600px.** It exists to stop a range from a
break at its own hyphen inside a narrow track. The collapsed layout has no track to protect. There
nowrap becomes the one declaration in the component that can push the page wider than the viewport.

**A deep link needs an arrival cue, and it is an `outline`.** It is not the `--highlight` wash. A
source list item is mostly link text, and the wash takes link text under 4.5:1. The outline costs
nothing in contrast. It shifts no layout, which matters inside the `.col-2` multicol source list.
It reads as distinct from the link-blue focus ring by hue. It is static, so it survives
`prefers-reduced-motion`, where a flash would leave that reader with no cue at all.

**`dt:target` takes the orange text color, because the outline cannot reach the date.** An outline
on both halves reads as two results rather than one. A background wash cannot work either, because
a grid gap takes no background.

**`:target` also carries `scroll-margin-block-start`.** Without it, a `dt` deep link lands against
the viewport edge with its era heading scrolled off above. The rule sits on `:target` rather than
on the headings, so it covers whatever a document links to. **Smooth scrolling was rejected.** On a
long page the jump becomes a long animated scroll, and the outline already answers "where did I
land".

**`.footnote-ref` is `nowrap`.** A multi-source citation group is one unbreakable unit, and the
commas inside it are ordinary break opportunities. The rule is scoped to `.footnote-ref` rather
than to `sup`, because a converter may put arbitrary content in a bare `sup`.

**The citation marker's hit area grows with `padding-block` alone.** Vertical padding on a
non-replaced inline element extends the hit region and leaves the line box alone. **Do not add
`padding-inline`.** Inline padding does affect inline layout, and it drags the underline out past
the digit.

**Print gets `break-inside: avoid` on the entry, never on the list.** A whole timeline forced onto
one page is the worse failure.

**`break-after: avoid` on the `dt` is not needed.** The grid row travels as a unit across page
boundaries, which was measured. The property would therefore be a declaration nobody can observe.

**The collapse to one column happens at 760px, not 600px.** The two-column layout holds far past
the point where it should. The date track does not shrink out of the way, so the prose column
becomes a narrow ribbon beside a wide empty date column. That is the same failure this repo already
recorded for the measure cap. **A container query was rejected.** `container-type: inline-size` on
`<article>` applies layout containment to every consumer's whole document to fix one component's
breakpoint.

**A `strong` inside an `<a>` repaints the link.** `strong { color: var(--orange) }` wins on the
inner element. A source title wrapped in `strong` therefore renders orange while the citation
markers render link-cyan. That is one page with two link colors. Take the `strong` out of the
anchor. Check this in any consumer that wraps a link title in `strong`.

**Nothing in `dl.timeline` encodes elapsed time, and that is the design.** A proportional axis puts
most of the page in whitespace and most of the content in an unreadable pile. The era grouping
already does the coarse chunking. Anyone who wants a real axis wants a chart, and a chart is not a
thing a no-build stylesheet should grow.

## Tables

**No `font-family` on `table`.** Tables inherit the body serif, which is correct, because Source
Serif 4's digits are tabular and lining. **Do not put tables in the mono stack.** The repo tried
that. It costs about a quarter of the table width, and it puts tables in a different register from
the prose. `font-variant-numeric: tabular-nums` on `td` is belt-and-braces for the fallback path.

**`table.tree` is a table, deliberately not a `treegrid`.** That role is a keyboard contract. It
promises roving `tabindex`, arrow keys, `aria-level`, `aria-expanded`, `aria-posinset` and
`aria-setsize`. A ship without the script therefore promises interaction that does not exist. The
role also removes the native row and column semantics a plain `<table>` announces. Depth is an
author attribute, `data-depth`, and everything else is presentation.

- **The indent is one `--tree-step` custom property, and only levels 0 to 3 exist.** `attr()`
  cannot feed a length into `calc()` with useful support. The alternative is a custom property per
  row, which pushes styling into the generator. A level-4 row degrades to flat rather than to
  wrong.
- **Depth de-emphasizes with `--label` at levels 2 and 3, not with smaller type.** Nested ratios
  compound, and the table already sits at 0.95em.
- **The `↳` needs the same alt-text treatment as the outbound arrow**, which is
  `content: "\21B3\A0" / ""` behind `@supports`. Without it the glyph lands in the row's accessible
  name. **Any future decorative `::before` owes this.**

**`width: auto; max-width: 100%`, not `width: 100%`.** Otherwise a narrow table stretches to the
full page. A wide table is unchanged either way, because its min-content width is the floor.

**The sideways-scroll escape hatch is `@media (max-width: 1000px)`.** It pairs `display: block`
with `width: fit-content`. `display: block` alone is not the fix. A block-level table takes
`width: auto` and fills its container, which reinstates the document-level sideways scroll.
`fit-content` resolves to content width for a narrow table and to container width for a wide one,
so both land correctly. The trigger is smaller than it looks. It starts at 200% text-only zoom, not
at 400%.

**The cost of the hatch is the sticky header, which `display: block` makes inert up to 1000px. That
is deliberate.** A pinned header matters on a long table at desktop width. A page that scrolls
sideways is a WCAG 1.4.10 failure at every width where it happens. The opt-in answer to both is
`.table-scroll`.

**Chromium does not strip table semantics on `display: block`.** The repo measured that rather than
assumed it. The role counts are identical above and below the breakpoint. The hatch costs the
sticky header and the keyboard reach. It does not cost the role.

**A sticky `th` needs an opaque background.** Otherwise the rows that scroll under it show through.
The header rule is an inset shadow rather than a `border-bottom`. Under `border-collapse: collapse`
the table paints the collapsed border, and that border scrolls away from the stuck header.

**No zebra striping.** It separated rows a reader could already separate by padding. It also put
the code surface behind arbitrary prose cells. A Tufte table separates rows with space and one
rule. Two consequences follow.

- **`table.tree [data-depth="0"] td` is the only fill inside any table.** `--code-bg` in a table
  therefore means *root row* and nothing else.
- **`tbody tr:hover td` keeps its `tbody` qualifier**, which now only scopes hover away from a
  `thead` row.

**`.num` is an opt-in class, not a heuristic.** CSS cannot tell a number from a label. `:has()`
cannot match text content, and "a column that looks numeric" is a generator's claim. The class goes
on the `th` too. Without it the header floats off its own column.

**An unwrapped table takes `tabindex="0"` and a `<caption>`, never `role="region"`.** The escape
hatch gives a table its own sideways-scroll axis. A scroll container no keyboard can reach is a
2.1.1 failure. Chrome papers over that by a scroll container it makes focusable on its own, with a
non-conforming default ring. Firefox and Safari do not.

**`role="region"` on the `<table>` is the wrong fix.** It overrides `role="table"` and takes the row
and column semantics with it. That is the same defect as `role="button"` on `pre.mermaid`.
`tabindex` alone changes no role, and `<caption>` is the element that already exists to name it.

**That rule is gated in `scripts/maintain.nu check`, because prose did not hold it.** The rule was
written into `CONTRACT.md` § 2, `table.tree` was fixed to match, and two fixture tables stayed
unreachable through the release that stated the requirement. The check deletes the
`.table-scroll` wrapper case from the body first and then asserts `tabindex="0"` on every `<table>`
that is left, plus no `role="region"` on any of them. **Delete the wrapper before the scan rather
than write an exemption into the predicate.** A wrapped table is not a scroll container, so it has
nothing to be reachable for, and a predicate that reasons about ancestry from a flat regex is the
kind of check that passes for the wrong reason.

**`.table-scroll` is the opt-in wrapper for a wide table.** It takes `overflow: auto` with a `70vh`
cap, alongside `.table-scroll > table { display: table }`. It scrolls both axes and keeps the
header pinned. A wrapper that scrolls one axis does **not** work. One axis on `auto` forces the
other off `visible`, so the wrapper becomes the scrollport and the header still leaves.
`tabindex="0"`, `role="region"` and a label go on the wrapper.

**The wrapper stays opt-in, and `overflow-x` stays on `table`.** A move of the hatch off `table`
would break every consumer that had not wrapped yet, so both paths run at once.

**`.table-scroll` carries `scroll-padding-top: 3em`, matched against the sticky `th`'s own
height.** A focusable cell in an early row lands under the pinned header otherwise, which is a
WCAG 2.4.11 failure. A headless-Chrome repro confirmed both halves: with no `scroll-padding-top`,
a focused link's rect sat fully inside the sticky header's bounding box; with it set, the
browser's native focus-triggered scroll went far enough that the link cleared the header by
roughly 46px. The fixture's wide table carries one link (row 2's trend cell) for exactly this
reason, so a future regression here fails the same way it was caught.

## Links

**Underline thickness has a 1px floor.** A sub-pixel underline paints as a faint partial-coverage
line, and the underline is the only thing that marks a link.

`overflow-wrap: break-word` lets a long URL or slug break rather than escape its container. The
connections-map Links column is as narrow as 220px.

**The outbound arrow is decorative, and it reached the accessibility tree.** A screen reader then
read out "north east arrow" after every external label. `content: "…" / ""` gives the
pseudo-element empty alternative text.

That declaration sits behind `@supports (content: "x" / "y")`, because the alt-text syntax is a
single value. A browser that cannot parse it discards the **whole** declaration, and the marker
disappears. Firefox ESR is in that group, and it is still deployed. `\A0` keeps the arrow from an
orphan line of its own. Print drops both the arrow and the underline, because on paper the
destination is unreachable.

`cite` is monospace and `font-style: normal`. The browser default is italic serif, which in this
theme is indistinguishable from `<em>`.

## Color and the contrast budget

**The `:root` block is the only source of color truth.** `tokens.css`, `mermaid-palette.json` and
the inline hex in `mermaid.js` are machine-checked projections of it.

**Measure a composited color from rendered pixels, never from a computed value.** A computed-value
reading reports the un-composited mix, and it is wrong. Two surfaces went unmeasured for a long
time that way.

**Text can land on three grounds, and a new token must clear its floor against all three.** The
grounds are `--surface`, `--code-bg` and `--surface-alt`. `--code-bg` covers `pre`, inline `code`,
`.filter-box` and the `table.tree` root row. `--surface-alt` is the row-hover fill. **Do not check
only the easiest ground.** `--surface-alt` is the harder one in light mode.

The floors, by mode: default 4.2:1, `prefers-contrast: more` 7:1, light 4.5:1, print 4.5:1. Rule
tokens sit at 3:1 against `--surface`, and the data ramp sits at 3.2:1.

### Tier decisions

**`--label` is the tier that moves toward body text. `--muted` is the tier pinned at the contrast
floor.** The two shared a hue and a chroma, and they differed too little in lightness to read as
two tiers. They also co-occur. `.scorecard` puts `--on-surface`, `--muted` and `--label` in one
component, and `.byline` sits directly above `h3`. `--muted` cannot get quieter, so `--label`
moved. The same holds in print, where the two had identical lightness.

**The row-hover fill is `var(--surface-alt)`. It is a flat token, and it darkens rather than
lightens.** It was a `color-mix` that composited to a lighter row, which took every accent on that
row below 4.5:1. Darker-on-dark is the weaker affordance, and it is worth it. **Do not reach for
another `color-mix`.** `--surface-alt` already exists, it needs no compositing to reason about, and
it is the only other flat surface in the sheet.

**`aside` has no fill at all, on screen or on paper.** The tint took a `cite`, `.sc-note`,
`.count`, `::marker` or status span inside a callout below the floor. The orange accent bar marks
the callout instead.

**`--purple` on `--code-bg` sits under the text floor, and the repo left it alone.** Purple is
`h2`, the `pre` accent bar and `::selection`. The bar is non-text and clears 1.4.11. Nothing puts
purple *text* on the gray, because an `h2` never renders inside a `pre` or a table cell. The repo
recorded this rather than fixed it, because the token is mirrored into `mermaid-palette.json`
twice.

**Borders drawn on `--code-bg` take `--rule`, not `--rule-light`.** The lighter weight fails 1.4.11
there, which took out `.filter-box`, `.mermaid-zoom` and `pre.mermaid:hover`. The side effect is
wanted. A control now reads stronger than a passive container like `details`.

**`em` carries no color.** It inherits. That is what makes it correct inside an `aside`, a
`blockquote` or a `.sidenote`. It matches its surroundings rather than overrides a color those
containers already chose. The italic carries the emphasis.

**`--highlight` is a body-copy surface only.** `mark` pins `color: var(--on-surface)` rather than
inherits, because every other tier fails on the wash. **Do not paint the wash under anything but
body copy.** A `li:target` highlight was built on that basis, measured, and removed.

### The data ramp

**`--data-1` to `--data-4` exist so that a diagram category cannot borrow a prose accent.**
`--data-1` moved off the link hue, where it was a near-exact collision. Hue separation between ramp
members is what matters, because they appear together in one diagram.

**The ramp carries its own light and print values.** One declaration in the base `:root` drew
dark-ground fills on a light page. The old reasoning was that slices abut each other rather than
the ground. That argued the boundary does not matter, rather than measured that it passes.

Each ramp member holds a stated fraction of maximum in-gamut chroma at its lightness and hue. Check
8 pins those fractions.

**A pie slice does not render the token.** Mermaid's own stylesheet applies `opacity: 0.7` and a 2px
black stroke. The stroke is therefore what separates a slice from the card, not the fill contrast.
The gate is honest about that. Check 5 asserts that the **token** clears the non-text floor. That
floor governs a `classDef` fill, a legend swatch and any consumer that paints with `var(--data-2)`
directly. Check 5 does not assert what a `pie` fence renders.

**`--data-2` sits close to `--pink`, and `--data-3` sits close to `--green`.** The repo left both
that way. Nothing in a diagram puts a category fill beside body copy, and a move means two more hex
projections to recompute.

**The `classdef` fills have no light twin.** A generator that emits its own `classDef name fill:…`
still paints dark-ground fills on a light page. A fix needs a second section and a second
membership check. It also needs a rule for how a generator picks at emit time with no CSS to read.
It therefore sits in `backlog.md` rather than half-done here.

### Gamut and vividness

**A declared chroma that sRGB cannot hold is silently clipped, and every contrast check stays
green.** Three high-contrast tokens shipped that way for two releases. `oklch_to_linear` clips
before it measures, so the checks were accurate about what ships and blind to the gap against the
source. Check 7 bisects the sRGB boundary and gates every parsed token in every mode.

**The trap is directional.** The chroma ceiling *shrinks* as lightness climbs. An editor who reads
a large chroma value therefore sees room to spare and raises `L` for more contrast. The color then
washes out faster than the numbers predict.

**Do not park a token exactly on the gamut boundary.** It tips back out on any later lightness
nudge. Each token holds a stated fraction of the ceiling instead.

**High contrast compresses the accent set, and no token edit can fix that.** The chroma ceiling
collapses at high lightness. A mode that pushes every accent up for a 7:1 floor therefore converges
them. Text mitigates it, not color. The status spans carry the words `verified`, `unverified` and
`correction`. That is the same reasoning that lets the `.verdict-*` chips survive forced colors.
**Do not try to widen these by a hue move.** The hue separations are already wide. Chroma is what
compressed, and the gamut is what compressed it.

**`--red` is the loudest accent in every mode on purpose**, and check 8 pins it there. The reflex is
to bring it down into the family, and that reflex is wrong. Red's chroma is what separates
`.correction` from `h1` pink and from `.unverified` orange. An alarm color that reads like the
heading beside it is worse than one louder than its peers.

**One absolute chroma across modes means different vividness in each**, because the ceiling moves
with lightness. `--red` therefore writes a different chroma per mode to hold one fraction.

**`--link` and the four other accents deliberately let their fraction float.** `--orange`,
`--purple`, `--pink` and `--green` do not hold one absolute chroma across all four modes anymore
(see "P3 gamut for six vivid accents" below); `--link` still does, and none of the five are pinned
to an invariant fraction the way `--red` and the data ramp are. A pin means new chromas in three
mode blocks each. It then means a re-measure of every ratio, every `/* was */` hex and both Mermaid
projections. `--red` was worth it, because a status color that changes intensity between screen and
paper is a semantic problem. `h2` calmer on paper is not. **A table of five that is true beats a
table of ten that is aspirational.**

### P3 gamut for six vivid accents

**`--red`, `--orange`, `--purple`, `--pink`, `--green` and the `--data-*` ramp hold a wider,
Display-P3-reaching chroma in dark and light mode.** High contrast and print keep these same six
tokens at their original sRGB values. High contrast is already gamut-compressed by design (the
paragraph above this one), and a screen's P3 gamut has no correspondence to reproducible ink, so
neither mode had anything to gain from the wider ceiling. `.github/palette-check.py` gates this
with `P3_WIDENED` and `P3_MODES`: only these nine tokens, only in `default` and
`prefers-color-scheme: light`, get checked against a Display P3 ceiling instead of the sRGB one.
Everywhere else, including these same tokens in high contrast and print, the sRGB gate is unchanged,
so a real sRGB clip in an untouched mode still fails loudly rather than passing under a relaxation
that was never meant to reach it.

**`--red` and the data ramp keep the exact fraction they already held, now measured against the
wider ceiling.** Same design, wider ruler: no re-litigation of how loud `--red` should read relative
to its neighbors, because the fraction that answers that question did not change, only the ceiling
it is a fraction of.

**`--orange`, `--purple`, `--pink` and `--green` do not get a pinned fraction.** Their current
fraction of the sRGB ceiling swings wildly between dark and light, by measurement: orange 55.5%
dark vs. 74.3% light, purple 56.5% vs. 37.6%, pink 63.3% vs. 52.6%, green 52.6% vs. 79.1%, purely
from where one hard-coded chroma happened to land against two different per-mode ceilings. Porting
one of those numbers as a "target fraction" would state a precision that was never designed, only
landed on by accident. The rule instead: **+25% chroma, independently in dark and light**, capped
at whatever value keeps every existing check 5 contrast floor passing. Only one pair needed the
cap: `--purple` dark against `--code-bg` was already the closest accent/ground pair to its floor in
the sheet (4.227:1 against a 4.2 floor, recorded above as "the repo left it alone"), and a flat +25%
would have dropped it to 4.180:1, crossing the line. Capping purple's dark bump at +9.3% instead of
+25% (chroma 0.107 to 0.117, not 0.134) holds it at 4.21:1. Every other token, mode and ground
clears its floor with margin at the full +25%. This still leaves `--orange`, `--purple`, `--pink`
and `--green` floating rather than pinned: dark and light now each hold their own bumped value, and
high contrast and print hold the original one, which is one more split than these four had before,
not a step toward the invariant-fraction model `--red` and the ramp use.

**High contrast has to state the data ramp explicitly now, and it never had to before.** Its
`:root` block redeclares `--red`, `--orange`, `--purple`, `--pink` and `--green` but had never
redeclared `--data-1..4`, since inheriting the base block's values was always correct there. Once
the base block's data ramp held a P3-reaching chroma, an unstated high-contrast override silently
inherited it too, and check 8 caught the drift: the ramp's vividness fraction, measured against
the sRGB ceiling as high contrast requires, moved outside its band. High contrast now restates the
ramp at its original sRGB values explicitly, for the same reason the other five accents already do.

**Every hex-only consumer, Mermaid and the three editor themes alike, is still sRGB, and now
needs gamut mapping rather than a straight conversion.** `mermaid.js`, `mermaid-palette.json` and
`scripts/create-themes.nu` (Zed, Rider, Ghostty, via `.github/palette-check.py --dump`) all read a
`#rrggbb` projection of these tokens, never the `oklch()` itself. Before this change, no token's
`C` ever exceeded the sRGB ceiling, so `oklch_to_hex`'s per-channel clip never actually engaged: it
was dead code, exercised only by the reverted three-token bug check 7 was built to catch. Once
`--purple` and the data ramp legitimately exceed sRGB in dark and light, per-channel clipping would
have hue- and lightness-shifted them, the same drift check 7's own history describes. `oklch_to_hex`
now reduces chroma to the sRGB ceiling before converting, holding `L` and `h`, which is what a
browser's own CSS Color 4 gamut mapping does and matches the function's stated purpose. The
practical result: Zed, Rider, Ghostty and every Mermaid diagram render the nearest in-gamut sRGB
approximation of the new vivid colors, not the full P3 vividness (hex cannot carry that) and not a
distorted guess either. `mermaid-palette.json`'s stated hex and `mermaid.js`'s inline literals for
`primaryBorderColor`/`nodeBorder` (from `--purple`) and `pie1..4` (from the data ramp) were
recomputed and updated to match; every other Mermaid hex was already within sRGB and unaffected.

**Percent of maximum chroma is the wrong yardstick across lightness. It works only across hue.** A
near-neutral like `--label` holds one absolute chroma in every mode. A match on the fraction would
make the light value a violently violet gray. The ramp applies the fraction rule at one lightness
across four hues, which is where it belongs. **Do not carry it to the grays.**

**An APCA reading inverts the WCAG 2 story, and no token moved because of it.** Dark mode runs below
light mode on identical roles. That is the known WCAG 2 overstatement of light text on a dark
ground, not a defect in these tokens. A flat Lc threshold as the bar misapplies the metric, because
APCA's threshold falls with size and weight. The repo records this so that a later reader who runs
APCA finds the answer rather than re-derives the panic.

### What is gated, and what is open

`.github/palette-check.py` runs eight checks.

1. Hex projections in both Mermaid palettes.
2. The `classdef` fills.
3. The `/* was */` provenance comments.
4. Stray hex in `mermaid.js`.
5. The contrast floor in all four modes, for text against three grounds, and for rules and the data
   ramp against their own.
6. `--mermaid-scheme` in both directions.
7. The sRGB gamut for every parsed token in every mode.
8. The vividness bands.

**A new token joins the roles in check 5.** Decide then whether it also belongs in check 8's table.
A token in the light palette cannot move without a matching move on the Mermaid side, and the gate
is what says so.

Three things stay open, and none of them is a measurement. `--orange` carries eight roles. Five
accents let their chroma fraction float. The high-contrast set is gamut-compressed, and text
mitigates it. Two more items live in `backlog.md`. The `classdef` fills have no light twin, and a
dark-mode pie slice label composites thin under Mermaid's own opacity.

**`--orange` carries eight roles:** `strong`, the `mark` wash through `--highlight`, syntax
numerals and constants, the `aside` and alert accent bar, `.markdown-alert-title`, `.unverified`,
`.verdict-partial` and `:target`. The repo recorded that rather than moved it. Every alternative
trades one collision for another. `--pink` is `h1`. `--purple` is `h2` and `::selection`. `--link`
is the focus ring. `--green` and `--red` are status. A move off orange also breaks the recorded
reason the arrival cue is orange. That cue reads as distinct from the link-blue focus ring. The
outline is a shape as well as a hue, so the state stays unambiguous.

### Forced colors

**Forced colors suppresses shadows.** Anything whose only boundary was a shadow therefore needs a
border. That is the general rule. The print block's `inset 0 0 0 1px currentColor` cannot be
reused, because an inset shadow is a shadow.

- **Semantic chips outline themselves.** `code, kbd, .verdict, .badge { border: 1px solid
  currentColor }`. Every `.verdict-*` fill resolves to one appearance under emulation. The **state**
  survives, because the chip's text says `PASS`, `PARTIAL`, `FAILED` or `N/A`. The border restores
  the boundary, not the meaning.
- **Tables carry a real border.** `table, th, td { border: 1px solid currentColor }`. Without it the
  outer rule, the inset header rule and the header background all vanish. A pixel scan down the
  edge then returns one value: no frame, and a header indistinguishable from the data.

Fills inside a table still flatten, and the repo left that alone. The user's own rendering is the
point of the mode. The grid is what is restored, not the tint.

## Form follows role

Three families were drawn the same way and meant different things. **Form separates them now, so
the shape carries the role and color is free to mean one thing.**

**A filled chip is a state. An outlined chip is a label.** `.verdict-*` keeps its fill, because
pass, partial, failed and N/A are states of a claim. `.badge` is `--label` text with a
`currentColor` ring and no fill. It had been three fills for Tier 1, 2 and 3. Those are ordinal
levels rather than health states, so a green-to-red ramp told the reader that tier 3 was failing.

`.badge-t1`, `-t2` and `-t3` **are not removed.** Consumers emit them, and that markup keeps
working. The variants simply carry no declarations.

**What that trades away:** tier is no longer scannable at a glance. The text always carried the
level, so nothing is lost. The reader now reads the ranking rather than sees it. **Three steps of
one new hue was costed and rejected.** It needs three `:root` tokens plus three print overrides,
each one clear of the floor on every ground. The free hue gaps are also too narrow for a three-step
ramp to read as three colors at chip size. If tier scanning matters, the cheap version is weight or
ring thickness on the existing hue.

**A border means interactive. An accent bar means passive block.** `.scorecard` was a bordered box
identical to `details`, `.nav-group`, `.nav-list`, `.filter-box` and `.mermaid-zoom`. A data panel,
a disclosure widget, a form field and a button therefore all read as one object. `.scorecard` now
takes `border-inline-start: var(--accent-bar) solid var(--rule-light)`. **Every remaining bordered
box in the sheet is something you can click, type in or open.**

**Three prose accents carry two or three roles each, and the repo accepts that:**

```
--pink    h1, th
--purple  h2, pre accent bar, ::selection
--orange  strong, aside accent bar, .unverified
```

The only overlap a reader can see is `--orange`. It stays, because form separates the other two
pairs. `--pink` is a large heading against an italic small table header. `--purple` is a heading
against a 3px bar and a selection fill.

**The hue budget is spent.** A new role takes an existing accent **plus a different form**, which
means weight, bar, ring or fill. `.verdict` and `.badge` show that separation. A role that lives in
a diagram takes `--data-1` to `--data-4` instead. A new hue is the last resort. A hue reused for a
third prose role needs a line here that says why the two cannot appear together.

## Borrowed components

Six components plus one page-wide texture were adapted from factory.strongdm.ai's product pages:
structure only, no color. Every component reuses an existing token under this section's hue-budget
rule. None introduces a new color role.

**`.kicker`** is an eyebrow label: a small tracked pill above a heading. It reuses `--link` and the
`oklch(from … / alpha)` pattern `--highlight` already established, so no new token exists just for
a tint. Do not give it a hue of its own. A document-status use should pick the color already scoped
to that state (`--green` verified, `--orange` unverified) rather than add a seventh accent. **The
tint sits at 8% alpha, not 12%.** Measured: `--link` text against a 12%-alpha `--link` background
landed at 4.47:1 in light mode, under the 4.5:1 text floor, because the tint moves the background
toward the text's own hue and lightness. 8% clears it (4.71:1 light, 6.6:1 dark) with margin instead
of sitting on the line.

**`.tag-dot`** is a `::before` circle, a categorical marker for a table cell or a nav-list entry. It
paints `currentColor`, so it carries no color of its own and cannot reopen the `.badge-t1/-t2/-t3`
tier ramp this repo already rejected above. A tier stays text, per that decision. A tag-dot is for a
value that already has a color elsewhere, a `--data-*` role in a diagram legend, for instance, never
a rank. **The class belongs on an empty element, never one that also holds the label.** `currentColor`
recolors whatever text sits inside the same element, and `--data-*` was scoped for diagram marks
(3:1, non-text), not body text (4.5:1). The first draft of the sample fixture set `color` on a span
that wrapped the label too and measured 3.45-3.53:1 in light mode, a real failure a reader would have
copied. `<span class="tag-dot" style="color: var(--data-1)"></span>Rust` keeps the color scoped to
the dot; the label stays plain text.

**`.live-dot`** is the sheet's first `@keyframes`. It reuses `--green`, the existing "healthy" role
(`.verified`, `.verdict-pass`, `.markdown-alert-tip`), so a live indicator does not invent an eighth
hue for the same meaning. `prefers-reduced-motion` at the top of the file already zeroes every
animation-duration, so the pulse freezes there for free. No print override exists: print has no live
state to show, and paged media does not run CSS animation regardless.

**`.icon-list` / `.icon-chip`** is a definition-style row: a tinted square carrying an initial, a
left accent bar in the same hue, then a title and a mono subtitle. It takes its color from an
`--icon-color` custom property set inline per `<li>`, the convention `--timeline-date` already uses
on `dl.timeline`. That keeps the component color-free by default and lets an author reuse `--orange`,
`--purple`, `--green` or a `--data-*` slot rather than a new token. **The glyph itself is fixed
`--on-surface`, never `--icon-color`.** A same-hue glyph on its own 15%-alpha tint measured as low as
3.35:1 (dark, `--purple`) and failed outright in light mode for all four demo hues (3.85-4.01:1),
because foreground and background differ only in alpha, not hue. `--on-surface` on the same tinted
backgrounds measures 8.06:1 and up in both modes. `--icon-color` still carries the whole component's
identity through the border and the tint; it is just never the letter.

**The `.icon-chip` glyph is `aria-hidden="true"`, because it always sits beside a visible label.**
Unhidden, a screen reader announces the initial and then the `<strong>` title right after it, the
same information twice on every row. `.step-node` is the opposite case and keeps its letter as real
text: a step chain carries no adjacent label for it to duplicate.

**`.step-chain` / `.step-hop` / `.step-node` / `.step-arrow`** is a linear process strip: circular
nodes joined by an arrow glyph. It exists for a flow too trivial to justify a Mermaid diagram, three
or four stages, no branching. It is not a Mermaid replacement. A graph with a branch or a loop still
belongs in `pre.mermaid`. Same `--icon-color` convention as `.icon-list`. **Every node but the first
is wrapped with its leading arrow in one `.step-hop`.** `.step-chain` still wraps at `flex-wrap: wrap`
for a narrow measure, but an arrow and a bare `.step-node` are separate flex items, so a wrap could
land between them: the arrow stays on the line above, and the node that follows starts a new line
with no visible connector. `.step-hop` makes the pair one flex item, so a wrap carries the arrow down
with the node it points to instead of stranding it.

**`blockquote.pull`** adds a large faint opening quote mark, positioned over the existing accent bar.
It is opt-in, because the sheet's default `blockquote` is used densely for citations and should not
carry the extra glyph everywhere. The glyph is decorative, so it takes the sheet's existing
accessible-alt convention: `blockquote.pull::before { content: "\201C" / ""; }` joins the
`@supports (content: "x" / "y")` block already used for the outbound-link arrow and the tree-table
turn.

**`body::before` paints a fixed, full-viewport film grain.** factory.strongdm.ai layers an inline
SVG `feTurbulence` filter over its dark background at low opacity with `mix-blend-mode: overlay`.
The technique carries no hue of its own, so it crosses over cleanly: dark ground, light ground and
print all inherit whatever `--surface` already is, and the grain reads as paper stock rather than
as a glow. It needs no consumer markup, unlike the six components above, because the pseudo-element
lives entirely in the stylesheet. `pointer-events: none` keeps it out of the hit-test order, and
`z-index: -1` is deliberate: a negative index still paints above `body`'s own background (the
stacking-context step it belongs to comes right after that background, per the CSS stacking order),
which is what makes it a backdrop rather than an opaque cover. **It is switched off in print and in
`forced-colors: active`.** Ink has no equivalent of `mix-blend-mode`, and a texture with no
informational content is exactly what a forced-colors reader should not have to see.

**Four more of factory.strongdm.ai's patterns were measured against this repo's own decisions and
left out, not missed.**

- **A `.cta-button` diagonal hover sheen plus a `translateY` lift.** That is new hover motion. This
  repo already decided the opposite for its one real button: `pre.mermaid:hover`'s ring is
  deliberately instant and untransitioned, because hover is high-frequency and "does not want
  motion" (Interaction states). A sheen on `.mermaid-zoom` or `.filter-box` would reopen that
  question for no stated reason.
- **A `.glass-card` translucent panel with `backdrop-filter: blur`.** Already rejected once here,
  for the sticky `th` case. It is also moot on this page: there is no busy background behind any
  card for a blur to soften, so the effect would be a no-op tax on paint cost.
- **A `.section { min-height: 100vh }` one-idea-per-screen layout.** It is the opposite of the
  settled long-measure, dense-reference-page decision (Width and measure). A page here is meant to
  hold a long table beside a diagram, not one thought per viewport.
- **An absolute-positioned, JS-driven nav dropdown.** `details.nav-group` already does this job with
  a native disclosure widget and no script. The dropdown is strictly worse for a no-build sheet.

**`.kicker`, `.icon-chip` and `.step-node` join the forced-colors border list.** All three carry
their whole shape through a background fill alone, which forced colors suppresses the same way it
suppresses a shadow. Without a border, the fill disappears: `.kicker` and `.icon-chip` read as bare
text with no chip shape left, and `.step-node` loses its circle outright, leaving only the letter
floating with no node and no per-step color. `.tag-dot` and `.live-dot` are not added there. Both sit
beside text that already carries the same information, so a flattened dot loses no meaning, matching
how `.verified` / `.unverified` / `.correction` already rely on color alone with no forced-colors
override.

**A sticky element does not take `backdrop-filter` blur.** factory.strongdm.ai's frosted sticky
panels were a seventh candidate here, and this repo already has a decision that rules them out: "A
sticky `th` needs an opaque background. Otherwise the rows that scroll under it show through"
(Tables). Blur only reads as frosted glass over a translucent layer, and an opaque `background` makes
`backdrop-filter` a no-op sitting on top of it. Reversing the opacity to get the frosted look would
reopen the exact defect that rule exists to prevent. Left out rather than diluted into an unrelated
shadow that would not deliver what was asked.

## Editor themes

`themes/` shares the palette. The **slot map**, which is the question of which token paints which
syntax class, is a separate decision. **Prose logic does not transfer to an editor.** In prose the
color is sparse, and low chroma reads as restraint. In an editor almost every glyph carries a
color, so the same chroma reads as wash.

**`--label` is the document's caption tier, not a code tier.** Punctuation, parameters and both
field kinds on that token collapse a buffer into one blue-gray band. Punctuation sits at
`--on-surface`, which matches upstream Dracula. Parameters sit at `--orange`. `--label` keeps
instance and static fields, which are legitimately secondary.

**Types cannot sit on plain `--purple`**, the dimmest accent in the palette. Type names are the
highest-frequency token in C#. They use the existing `.bright` lift. That is not a new placeholder
and not a palette change.

**The repo rendered three alternatives and rejected all three.** Each one adopts more of Dracula's
slot map: functions to `--green`, strings to `--data-4`, numbers to `--purple`. `--data-4` reads
olive rather than yellow at this chroma. A move of strings off green also breaks the one
cross-medium tie the theme has. The stylesheet paints inline `code` green, so a string in the
editor and a `<code>` span in a document are the same color.

**Do not answer "the theme looks washed out" by a chroma raise in `:root`.** Every ratio in the
contrast budget was measured against those values, and those values go into every published page. A
theme that reads dim is a slot-map problem first. Verify by a render of the **generated** `.icls`,
not the template. The placeholders hide which hex actually lands.

## Mermaid

### Init config

Use `theme: 'base'` plus explicit `themeVariables`. **Never use `theme: 'dark'`**, which ignores
this palette entirely.

**Pass hex, never `oklch()`.** khroma throws "Unsupported color format" and aborts init, so no
diagram renders at all. The values mirror `mermaid-palette.json`, and CI enforces the match.

**`darkMode` belongs inside `themeVariables`.** `mermaidAPI` passes only `config.themeVariables` to
`base.getThemeVariables()`. A root-level `darkMode` therefore never reaches the theme, and every
derived color computes light-mode.

**`fontFamily` and `fontSize` are the only non-color `themeVariables`.** They are deliberately not
mirrored into `mermaid-palette.json`, which catches hex drift and has no hex here to catch.
`fontSize: '1rem'` tracks the reader's root size. Mermaid's default is a hard-coded 16px.

**`background` is inert.** A sweep across twelve diagram types showed that it never reaches the
output. It is correct by intent rather than load-bearing.

**Theme the `note*` family explicitly.** Coverage of nodes, clusters, edges and pie slices leaves a
`Note over` at mermaid's stock yellow, which is the only light surface on a dark page.
`noteBorderColor` takes the lighter rule weight, so a note reads as an annotation rather than as a
second node.

**`actorTextColor` is not needed, and it is deliberately absent.** A `text,tspan` sweep returns each
actor name twice, which looks like a hidden dark layer. It is not. Mermaid emits one `<text>` that
wraps one `<tspan>`, and the parent has no direct text child to paint. **Probe a `tspan`, not its
parent `text`,** before you believe this one again. A themeVariable that changes nothing still
costs two CI gates to keep in step.

**Pin the CDN to an exact version, never to a range.**

### Label measurement

**`fontFamily` is set at the top level of the config as well as in `themeVariables`. Both copies are
load-bearing.** The themeVariable reaches the CSS mermaid injects, and it decides what paints the
labels. The root one is what `calculateTextDimensions` measures with, and it decides how wide a
label box computes to be. **The measurement font is the render font, or the arithmetic is wrong.**

**`sequence.noteFontFamily` and `noteFontSize` are not the fix.** `initialize` accepts them, and
`getConfig()` reads them back. Through 11.16.1 they change nothing.

### Diagram sizing

Label size follows SVG scale, so both ends of the viewport range are the same bug.

**Wide end: `pre.mermaid svg` takes `width: auto`, not `width: 100%`.** A stretch of an SVG with a viewBox
to its container multiplies the label size with it. A sparse graph then renders labels larger than
`h1`. `max-width: 100%` still shrinks a graph too wide to fit. `text-align: center` keeps a small
one centered, **in both layouts**. It once lived on `body.conn-map` only, so an inline diagram
narrower than its column hugged the left edge in the default layout. `fontSize: '1rem'` alone does
not fix this.

**Narrow end: below 600px the diagram renders at natural size and scrolls.** Scaled to a phone's
width, diagram text renders at half the size of the prose it illustrates.

**The natural width comes from `--natural-width`, because CSS cannot otherwise recover it.** With
`useMaxWidth` at its default, mermaid writes `width="100%"` as an attribute and its real size as an
inline `max-width`. `mermaid.js` copies that value into the custom property. Two attempts failed
first.

1. `width: auto` plus `max-width: none`. An SVG with a viewBox resolves `auto` to its container. The
   diagram therefore stayed at container width, and the labels stayed small.
2. A copy of the inline `max-width` into the inline `width`. That broke the band *above* the
   breakpoint. A fixed width overflowed its column into a page-level sideways scroll, which is the
   one thing this work exists to prevent.

The `--natural-width` fallback covers `body.conn-map`. Its fences set `useMaxWidth: false`, so they
carry a real width attribute and no inline `max-width`. The `!important` fights mermaid's own
inline styles. The selector repeats inside the media block, because it is more specific **and**
`!important`. Source order alone would not win.

**`pre.mermaid svg { overflow: visible }` exists because some diagram types write a viewBox that
does not contain their own content.** The outermost `<svg>` gets `overflow: hidden` from the UA
stylesheet, so anything outside the viewBox is clipped. `quadrantChart` forced the rule with a fixed
viewBox and point labels centered on the point. `pre.mermaid` needs the declaration too, or the
inherited `overflow-x: auto` clips at the same place. `.mermaid-overlay svg` needs it too, or the
zoom shows the truncation it was opened to escape.

**The cost is that those labels clip below 600px**, where `overflow-x: auto` forces computed
`overflow-y` to `auto`. The repo accepts that. The zoom overlay shows the whole diagram either way.

**A JS `refit()` that grows the viewBox to the measured `getBBox()` was tried and reverted.** Run
from the `MutationObserver`, it fires before the flowchart's `foreignObject` labels lay out. The
bbox is therefore enormous, and it drags the inline `max-width` with it. A correct version needs a
settled-layout signal the observer does not have. **One CSS declaration needs no timing at all.**

### Zoom

**The clone is stripped of mermaid's own sizing**, so the overlay's CSS governs every diagram
identically. An inline `max-width` outranks the stylesheet. Left in place, the zoom magnifies in one
layout and does nothing in the other. The overlay sets `width` and `height`, not `max-*`, because
`max-width` alone leaves a small diagram at natural size. That is a zoom that does not zoom.

**The zoomed diagram's halo is tinted from the scrim**, at
`oklch(from var(--surface-alt) 0.15 c h / 0.5)`. A pure-black shadow only looked right in one
palette. A zero-offset blur is a glow rather than an elevation shadow, and an untinted one picks up
none of the surface it falls on.

**The close mark honors the safe-area insets, because the overlay is the sheet's only fixed layer.**
Both offsets are `max()` against `env(safe-area-inset-*)`. The inline-end offset lists both physical
insets, because `env()` has no logical spelling. Nobody verified this on hardware with a real notch.

**The ✕ stays a pseudo-element, not a button.** The whole overlay dismisses on click, and Escape
closes it. A control there adds a second path to one action. It also adds a focus stop inside a
dialog whose only content is a diagram.

`securityLevel` defaults to `strict`, which sanitizes `click` directives away. A consumer with a
trusted source sets `window.mermaidSecurityLevel = 'loose'` in a preceding classic script tag. The
overlay throws loudly when `#mermaid-zoom` is missing. Without that check the zoom dies on a bare
`TypeError` that points nowhere near the missing element.

**Clicking a diagram never opened the overlay, on any fixture, until this was found.** A `data-*`
attribute is not a safe "already wired up" guard, because it is a real DOM attribute and
`cloneNode` copies it. Mermaid's own render pipeline clones the `<svg>` at least once after the
initial insert, part of its own layout process, unrelated to anything this repo does. The clone
carries the `data-zoomable="true"` marker over, so the guard reads "already done" and skips
re-attaching, but a JS listener added with `addEventListener` does not survive a clone: the click
handler stays bound to the discarded original, and the live element nobody can click has none.
Confirmed with a real, driven click (Playwright, not a synthetic `dispatchEvent`, which fires
listeners but proves nothing about which element they are bound to): a click straight at the
diagram's own "Zoom diagram" button worked, because that button is recreated fresh on every render
pass and always closes over the current `svg`, and a click on the diagram itself did nothing, on
every fixture, small or large, ELK or not. **The fix is a `WeakSet` keyed on the element itself,
not an attribute copied onto whatever clones it.** A clone is a different object and is not in the
set, so it correctly gets its own listener; the same object seen again on a later render pass
correctly does not get a second one.

**A node's own link must win over the diagram's click-to-zoom, and nothing enforced that either.**
The svg-wide listener that opens the overlay sees every click inside the diagram, including one
that lands on a node's own `<a xlink:href>`. A connections map's nodes are exactly that kind of
link. The listener now checks `e.target.closest('a')` and does nothing when the click is inside
one, letting the node's own navigation proceed instead of racing it. Verified with a real click on
a node carrying a `click` directive: the page navigates and the overlay never opens, against the
same real click landing on a node with no directive, which still opens the overlay as before.

### Diagram types

**`packet` is not themeable through config, so CSS overrides it.**
`defaultPacketStyleOptions` hard-codes black text on `#efefef`. Neither `initialize()` nor a fence
directive moves any of it. `tufte-dracula.css` overrides mermaid's injected rule directly with
`!important`. That is required rather than convenient. Mermaid's rule is id-scoped, so it beats a
page-level class rule on specificity whatever the source order.

**Verify a mermaid override by a sample of rendered pixels, not by a read of the exported SVG.** The
SVG's own embedded `<style>` does not change, even when an external stylesheet visually overrides it.

**`xyChart` cannot be fixed here.** `plotColorPalette` has the same inert-config defect as `packet`.
Unlike `packet`, there is no CSS door in. The bars and the line are plain `<rect>` and `<path>`
elements with a literal `fill` or `stroke` and **no class attribute at all**. Take this when mermaid
ships a fix. Otherwise use a per-diagram `<style>` scoped by a hand-added `id`. **Never widen a
selector on the shared sheet for it.**

**`sankey` and `block` render in d3's Tableau10 categorical scheme** rather than in any
`themeVariable`. There is no config surface in front of it. The repo leaves them alone for the
reason the contrast budget gives: nothing puts a category fill beside body copy.

## Connections-map layout

`body.conn-map` has exactly two sections in order: **(1) Links, (2) Graph**. Above 900px Links sits
left and sticky, and the graph sits right. Below 900px they stack.

**Markup order is the layout order. The stylesheet does not reorder.** CSS `order` reversed them,
so the visual leading column was Links while tab order and screen-reader order started in the graph
on the right.

**That was a breaking change for consumers, and the break is silent.** A page emitted with the old
order renders with the graph in the narrow sticky column, and nothing errors. Support for both
orders behind `:has(> .links)` was rejected. That is two layout paths in a file every consumer
inlines verbatim.

**The article sets layout only, never width.** It once broke out of the page container to be *wider*
than the default layout. A connections map and an ordinary page therefore never shared a left edge.
`pre.mermaid` broke out a second time. **The repo deleted both breakouts rather than ported them.**
The container is `--page-width`, and the SVG renders at natural size. There is nothing to escape to,
and extra width would buy nothing.

**The full-width row is `article > *`, not an allow-list.** With an allow-list, any other direct
child silently joined the two-column flex row rather than spanned it. A generator triggers that by a
new footer. The column rules still win on specificity, so the shipped layout is unchanged.

**The sticky column has a height ceiling.** `position: sticky` pins nothing when the element is
taller than the viewport. It scrolls with the page like any block, silently, with nothing clipped.
The column takes `max-height: calc(100vh - 2rem); overflow-y: auto; overscroll-behavior: contain`.

**`tabindex="0"` is deliberately not on that column.** This is the one place the sideways-scroller
rule does not apply. That rule exists for a `pre`, a table and a `math[display="block"]`, whose
overflowed content holds nothing focusable. The Links column holds links. Focus on one scrolls it
into view, so a tab stop on the container would announce a region the reader is already inside.

### Large maps

The two-node sample above proves the container. It says nothing about a map with dozens of nodes,
and the default `flowchart BT` fan-out does not scale to one: a 50-node production map measured
`viewBox="0 0 7435 798"`, five ranks, one of them holding 27 of the 50 nodes because dagre lays a
flat rank out left to right with nothing to break it up. That is a horizontal-scroll wall, not a
diagram. **Past roughly 15 to 20 nodes on one rank, restructure rather than widen:**

**1. Cluster nodes into open subgraphs for visual grouping. Never collapse one that a reader must
click into.** `subgraphId@{ view: collapsed }` (Mermaid 11.17) does not shrink a cluster, it
deletes it: every node inside is dropped from the render, and with it every one of that node's own
`click id href "url"` anchors. A connections map exists to link out to every item it names, so
collapse is disqualified outright for this template, not a tradeoff to weigh. Verified against the
same reason the zoom overlay depends on `click`: a `click` directive rendered under an open
subgraph produces a real `<a xlink:href>` per node, identical to a node outside any subgraph, and
Mermaid's own PR description for the feature confirms internal edges and nodes are dropped rather
than hidden. Grouping into an open (uncollapsed) subgraph still gives a reader visual structure,
an era or a topic reads as one region, but it does not reduce the node count on the page. Point 4
is what does.

**2. Switch a large map to the ELK layout engine, loaded only when a page asks for it.**
`mermaid.js` imports `@mermaid-js/layout-elk` from the CDN and calls
`mermaid.registerLayoutLoaders()`, but only when a `pre.mermaid` fence on the page contains
`layout: elk`. An unconditional import would add a second mandatory CDN dependency to every page
with a Mermaid diagram, including the ones with five nodes that never needed it. A consumer opts
in per diagram with a `config: { layout: elk }` frontmatter block in the fence.

**The ELK import must never block `mermaid.initialize()`, and a top-level `await` on it does
exactly that.** A first attempt awaited the dynamic import before calling `initialize`, so nothing
on the page rendered, not even diagrams that never asked for ELK, until that import settled. Under
`--virtual-time-budget`, the flag `.github/render-modes.py` already uses to screenshot every
fixture, the import never settles at all: virtual time does not let a pending `fetch` resolve, so
the `await` hangs forever and the page stays unrendered for the full budget. The fix is
fire-and-forget: `mermaid.initialize` and `startOnLoad` run immediately as before, and the ELK
import, once it resolves, calls `mermaid.registerLayoutLoaders()` then `mermaid.run({ nodes:
elkPres })` to re-render only the diagrams that requested `layout: elk`. Every other diagram on
the page is never blocked on it. If the import never resolves, an ELK diagram shows Mermaid's own
inline error state indefinitely: the same offline failure this repo already accepts for Mermaid
itself, now scoped to the one diagram that opted into the extra dependency instead of the whole
page.

**ELK trades width for height on an unbalanced fan-out, it does not just shrink the diagram.**
Eighteen leaf nodes into one focus node, the shape of the production map's worst rank, measured
`3063 x 174` under dagre and `2671 x 324` under ELK: about 13% narrower and roughly twice as tall.
ELK spreads a flat rank across more than one row instead of extending it sideways. That is the
fix for the sprawl, and it is a real layout change, not a free win: a map that is already short
and wide will read taller under ELK, not merely narrower.

**ELK clusters ignore `clusterBkg` and `clusterBorder` outright.** Isolated against dagre with the
identical subgraph and the identical `theme: 'base'` config: dagre paints the cluster from the
theme, ELK hardcodes Mermaid's stock `#ffffde` fill and `#aaaa33` stroke, and the label text
hardcodes to `#333`, regardless of `themeVariables`. This is the same defect class as `packet` and
`xyChart` above, a diagram surface Mermaid does not theme, so `tufte-dracula.css` overrides it the
same way: `pre.mermaid .cluster rect` and `pre.mermaid .cluster-label :is(p, span)` carry
`!important`, because Mermaid's injected rule is ID-scoped and beats a page-level class rule on
specificity otherwise. Verified by rendered pixels in Chromium in both the dark and forced-light
palettes, not by reading the exported SVG's own `<style>` block, which does not change even when
this override is in effect.

**3. Encode relationship type as line style, once, in a legend, not as a text label on every
edge.** The production map carried 39 edges, each labelled `technological` or `conceptual` in its
own `foreignObject`, the same two strings repeated forty times, each one adding to the width dagre
solves for. A `classDef` on two edge classes, solid against `stroke-dasharray`, plus one small
unconnected subgraph holding two short labelled edges as a key, states the distinction once
instead of on every edge.

**4. Past that node count, split into multiple maps rather than hide any node.** This is the actual
answer to a map too large for one page, now that point 1 rules out collapsing: every node stays
present and clickable, on whichever of the several maps holds it. The production map's edges split
31 technological against 8 conceptual, and a map that lopsided reads better as two focused maps by
relationship type than as one map carrying both past the point where either reads clearly. An era
split works the same way. This is a decision for whatever generates the map's content, not
something the template enforces, but it is the recommended default past the threshold above.

## Interaction states

**A transition belongs on the resting rule, and `transform` and `scale` are different properties.**
The press feedback on `.nav-list li a` was inert for both reasons at once. The transition named
`scale` while the rule set `transform`. The declaration also sat inside `:active`, so it vanished
with the state. It is now `scale: 0.96` in `:active`, with the transition on the base rule.

**`.mermaid-zoom` follows the same language.** It takes `transition: color, background-color, scale`
on the resting rule and `scale: 0.96` in `:active`. It is the only real `<button>` in the sheet, and
it had neither a transition nor a press state.

**`[tabindex="0"]:focus-visible` is in the focus rule.** The one stop this sheet does not own is the
one consumers are told to add. Without that selector, a focused `pre`, `math` or `.table-scroll`
falls back to Chromium's default ring. That is a consistency failure rather than a contrast one. The
attribute selector covers a wrapper before it exists.

**No `border-radius` in the `:focus-visible` rule.** It made `.filter-box` corners tighten at the
moment the ring appeared. It also applied unevenly, because `.nav-list li a` outranks
`a:focus-visible`. Chromium already rounds an outline to the element's own radius plus offset. The
removal is therefore what makes the ring follow each surface.

**`.nav-list` radius is `calc(var(--radius-sm) + 0.3rem)`**, not `var(--radius)`. The outer radius
is the inner radius plus the padding. The `calc` keeps them concentric when either one changes.

**`pre.mermaid:hover` gets a 1px ring.** Before it, `cursor: zoom-in` was the only signal that a
diagram was clickable, and a cursor does not exist on touch. The ring is instant and not
transitioned. Hover is high-frequency, and it does not want motion.

**The View Transitions API was considered for the mermaid overlay open/close, and passed over.**
Cross-document support is not Baseline yet, and the overlay's existing `opacity` transition already
covers the same need. A new browser API earns its place by doing something the current transition
cannot, not by replacing it with an equivalent.

**The overlay's way out is a `✕` glyph on `.mermaid-overlay::after`.** Click-anywhere and Escape
both dismissed it before and still do. Nothing advertised either one, and `cursor: zoom-out` is
invisible on touch. It is a glyph rather than a word, because consumers inline this stylesheet
verbatim and cannot translate a string in it. It uses `content: "✕" / ""` behind `@supports`, for
the same reason the outbound arrow does. It is a cue on an already-clickable surface, not a new
target.

**Every transition in the sheet is `ease-out`.** The default `ease` leaves the first frame
near-invisible and then rushes. The interaction then feels late.

## Keyboard and assistive technology

**Zoom is a real `<button>` that `mermaid.js` injects. It is not a focusable `pre`.** Before it, the
only way to zoom was a click on the SVG, and no tab stop reached the diagram (WCAG 2.1.1). The repo
rejected two cheaper fixes.

- `tabindex="0"` plus `role="button"` on `pre.mermaid` makes the button's content presentational.
  That hides the SVG's own `graphics-document` node and its name. The control would work, and the
  diagram would stop existing.
- `tabindex="0"` with no role leaves a focusable generic, and `aria-label` cannot name
  `role=generic`.

The injected button is a native control. It gets keyboard and pointer support for free. It has an
accessible name of its own. It leaves the SVG untouched. It is also the touch affordance that
`cursor: zoom-in` could never be.

**The observer that creates it has to be idempotent.** Mermaid rewrites the `pre`'s children after
the first render. A one-shot guard therefore let the second pass delete the button and then blocked
a recreation. The observer now re-adds the button whenever one is missing. It also marks the **SVG**
rather than the `pre` for the click listener. The button append is therefore a no-op on the next
tick rather than a loop.

**The overlay is a native `<dialog>`, opened with `showModal()`.** An earlier version was a `<div>`
that hand-rolled every part of modality: `role="dialog"`, `aria-modal="true"`, a `tabindex="-1"` plus
a manual `.focus()` call, an `inert` toggle across every other `body` child on open and close, and a
guarded `document`-level Escape listener that had to check `.active` before it ran, because an
unguarded one reached into a consumer's page on every Escape press and cleared `inert` off whatever
the consumer's own dialog had set. `showModal()` does all of it natively: the dialog carries an
implicit `role="dialog"` and an implicit `aria-modal="true"` while shown, the rest of the page is
excluded from focus and the accessibility tree without this file touching a single sibling, focus
moves to the dialog automatically (there is nothing focusable in a cloned diagram to move to
instead), and Escape closes it through a `cancel` event the browser fires on its own. `aria-label`
still needs setting by hand, same as before, since a `<dialog>` has no accessible name of its own.

**Close still runs through one function, `hide()`, called from a `click` listener on the overlay
and from a `cancel` listener that first calls `preventDefault()`.** The `preventDefault()` stops the
browser's own auto-close so `hide()` can run the same cleanup either way: drop the `active` class,
call `overlay.close()`, empty `overlay.innerHTML`. `close()` is called synchronously in `hide()`
rather than deferred to the fade's `transitionend`, because a `transitionend` that never fires (a
missing frame, a stalled compositor, anything that stops the opacity transition from completing)
would otherwise leave the dialog open forever with no cleanup and no focus restored, which is worse
than the fragility this replaced. **The trade is that the overlay's entrance still fades in but its
exit does not.** `showModal()` puts the dialog in the top layer and removing it with `close()` takes
it back out synchronously, and a property that no longer applies cannot transition. An exit fade is
possible with `@starting-style` and `transition-behavior: allow-discrete`, and was not pursued here,
because closing this dialog is a dismissal a user asked for, not a state a user is meant to watch
happen.

**Focus returns to the button that opened it for free.** `close()` restores focus to whatever had it
when `showModal()` was called, which is the trigger button for any focus-driven activation. The
manual `opener` variable and its `.focus()` call are gone with the code that made them necessary.

**The zoom button is named from the diagram, not from a constant.** A hard-coded label gives a page
with several diagrams several identically named buttons. Mermaid writes each fence's `accTitle:`
into the SVG's root `<title>`. `aria-label` is therefore `label + ': ' + title`, and the visible
text stays short. The overlay takes the same name on open, and the `pre` region takes the bare
title.

`window.mermaidZoomLabel` overrides the label word. It follows the `window.mermaidSecurityLevel`
convention. Both strings were hard-coded English in a file consumers inline verbatim. That is the
same constraint that made the overlay's close cue a glyph.

**`accTitle` and `accDescr` are consumer obligations.** They are fence directives, so no stylesheet
change can supply them. Without them the SVG is a `graphics-document` with no accessible name.

**The sidenote margin-toggle is inert by design, and its two `display: none` rules must stay.**
`.sidenote` is `display: block` at every width, so the Tufte collapse pattern does nothing here. The
rules are not dead weight. Consumer generators emit that checkbox and label markup, and a drop of
the rules would show raw checkboxes on every published page. A revival of the pattern needs a
focusable control, not a hidden checkbox.

**`math[display="block"]` takes `tabindex="0"`, `role="region"` and a label.** It carries its own
`overflow-x: auto`, so it is a scroll container like `pre`. `role="region"` costs nothing here,
unlike on a `<table>`. Chrome exposes no native `math` role for this element either way, so there is
no role to protect.

## Direction, zoom and growth

**Sidenotes float to the inline end, with the physical value first as the fallback:** `float:
right; float: inline-end; clear: right; clear: inline-end`. **The duplicate physical declaration is
deliberate.** A browser that cannot parse `inline-end` drops that line and keeps the LTR behavior it
had. `margin` became `margin-block` and `margin-inline` for the same reason.

**`th` and `td` are `text-align: start`, not `left`.** With `left`, every cell stays left-aligned in
RTL while the prose around it flips. `.num` uses `end` for the same reason.

**`h1`, `h2` and `h3` carry `overflow-wrap: break-word`.** They were the only text in the sheet with
no break rule, so a long title word ran off the page under text-only zoom.

**`--gutter` folds the safe-area insets at every width, not only under 600px.** A landscape phone is
wider than the mobile breakpoint, and it still has lateral insets larger than the desktop gutter.
Text therefore ran under the notch. **The `0px` fallbacks inside `env()` are load-bearing.** Without
them, a browser with no support for the variable makes the whole custom property invalid at
computed-value time. That takes `width: min(100% - 2 * var(--gutter), …)` down with it. Nobody
verified this on a real device, because Chromium does not emulate the insets.

**A container query fixes the `.scorecard` overflow under text-only zoom. A media query cannot.**
`em` inside a container query resolves against the **container's** font size. The query therefore
asks "is the text large relative to the space", which is the failure condition. In a media query
`em` resolves against the browser's initial font size, and it sees nothing at a doubled root.

Two things about that rule are load-bearing.

- **The `:has()` scoping.** `container-type: inline-size` on every `section` also applies
  inline-size containment to the conn-map columns, which shrinks the sticky sidebar at zoom.
- **Its source position, after the `max-width: 600px` block.** Container queries add no specificity,
  so source order is what makes it win.

Two attempts on the same problem failed. `minmax(0, max-content)` tracks let the track shrink to
zero without the `.verdict` chip shrinking with it, so the chip spilled out of a zero-width column.
`auto` tracks plus `overflow-wrap: break-word` fixed one width only. **`break-word` does not reduce
a box's min-content contribution, and `anywhere` does.**

**At 400% text-only zoom the page still scrolls sideways.** That is past what WCAG 1.4.4 asks for,
and nobody chases it.

## Cascade layer

**The whole sheet sits in one layer, `@layer tufte-dracula`.** Before it, a consumer's override had
to win on specificity against syntax-highlight groups at `0,2,0` and component rules at `0,1,1`.
**Unlayered author styles beat every layered author style for normal declarations**, whatever the
specificity. A consumer's plain `h1 { color: … }` therefore wins now, and nothing in this sheet has
to move.

**The `!important` declarations became harder to override, not easier. That is the trade.** In the
important half of the cascade the layer order reverses. The six `!important` rules in this sheet
therefore beat a consumer's unlayered `!important`. Five of them fight Mermaid's inline `style`
attributes, which nothing else can reach. The sixth is `.filter-hidden { display: none !important }`,
where a consumer override means a filtered row stays on the page. **A consumer who genuinely needs
to win declares an own layer ahead of this one.** A lift of those rules outside the layer was
rejected. Three sit inside a media query, so it means a duplicate of two `@media` blocks outside the
wrapper.

**One layer, not four.** `@layer reset, base, components, utilities` is advice for a stylesheet a
consumer composes from parts and can reorder. This is one file, inlined verbatim, in a fixed order.

**Do not re-indent the sheet body.** The wrapper opens on line 3 and closes before `</style>`. The
lines between keep their four-space indent. A re-indent is the correct-looking change, and it
rewrites every line, which puts `git blame` on the whole stylesheet at one commit. This repo's
discipline depends on a trace from a declaration back to the change that made it look that way.
`scripts/build-sample.nu` also slices `:root` with a hard-coded `^    ` de-indent.

**`:is()` and `:not()` both take the highest specificity of their arguments.**
`:is(ul, ol, menu):not(.nav-list)` therefore scored a class weight from a class it never matches. It
then silently outranked the nested-list rule below it. The `:where()` form scores zero on both
sides. **Check the specificity of a negation before you trust source order.**

**The other `:is()` groups stay.** The layer already gives consumers the override. Two would also
break if lowered. The syntax-highlight groups have to beat a highlighter theme a consumer may also
load. The permalink group has to beat the plain `a` rule. **Lower specificity is not free when
something real sits on the other side of it.**

## Appearance modes

**`@media (prefers-contrast: more)` reassigns tokens, not elements.** It raises every accent to the
mode's 7:1 floor against `--code-bg`, which is the harder ground. `--surface-alt` *darkens* there.
It is the row-hover and tinted-root fill, and its job in that mode is to be unmistakable.

Three rules move as well. `a` takes a thicker underline at `currentColor`. `.nav-list li a` repeats
that one declaration. The focus ring widens.

**The `.nav-list` repeat exists because a media query adds no specificity.** The base
`.nav-list li a` rule outranked the block's `a` rule. Every nav link therefore stayed underline-free
in the one mode whose whole purpose is the strongest available cue.

`mark` does not reach the mode's floor. `--highlight` is an alpha wash, and the alpha caps what the
composite can reach. A lower alpha would make the highlight harder to see, which is the one thing
the element exists to do.

**`@media (prefers-color-scheme: light)` is a full second screen palette. It is not the print
palette.** Reuse of print fails on screen for three reasons. `--surface` and `--surface-alt` are
both pure white there, which kills row hover and the overlay backdrop. `--code-bg` is a paper
compromise. The accents are also tuned against white rather than against a light code fill.

In light mode `--surface-alt` is *darker* than `--surface`, so row hover reads the way it does in
dark mode. `.verdict` keeps its filled form, so the print block's outlined variant is not needed.
**`--purple-bright` inverts its rule to `calc(l - 0.06)`, because brighter is less contrast on a
light ground.**

**Mermaid follows the media query by a read of a CSS token, never `matchMedia`.** `:root` declares
`--mermaid-scheme: dark`, and the light block overrides it. **`matchMedia` reads the host. The token
reads the cascade.** The forced-light sample pages work only because of that. They rewrite the
`@media` condition in their own copy of the stylesheet. `matchMedia` cannot see that, and a computed
custom property resolves it correctly.

**A delete of `--mermaid-scheme` used to fail silently.** `getPropertyValue` on a missing property
returns an empty string, which is not `'light'`. Check 6 asserts four things. `:root` declares
`dark`. The light block declares `light`. `mermaid.js` reads that token by name. `mermaid.js` does
**not** read `matchMedia`.

**The dark-island design was tried and removed.** Light mode handed `pre.mermaid` the dark palette
back as inherited custom properties, and it painted the diagram a dark card. It looked fine, and it
was wrong for three reasons. A dark slab beside a light sidebar reads as broken rather than as a
plate. A fix for the card width needed a `width: fit-content` rule that clipped `quadrantChart` and
collapsed the SVGs that size themselves. The re-declared palette was also a third projection of
`:root`, which needed its own gate. **The net change after the delete is fewer rules than before it
existed.**

**A scheme flip with no reload leaves the diagram stale.** The token is read once, at init. A live
re-theme means a re-init of mermaid, a re-render of every fence from source, and a fresh
`MutationObserver` race. That is a lot for a case one refresh costs. Take it if a consumer ships an
in-page appearance toggle.

**An in-page toggle was asked for and refused, because there is nowhere to put it.** The fixtures
carry exactly one `<style>` and two `<script>` blocks, and both counts are gated. Fixture-only
toggle CSS therefore does not exist as an option. A toggle goes in the shared payload every consumer
inlines. It costs either a second theming convention with the light palette duplicated under it, or
a fourth inlined script. Take it when a consumer asks for a manual override as a feature. Treat it
then as a public API decision. It covers the selector, the persistence and the first-paint flash.

**Two generated preview pages carry the light palette to the web instead.** Pages serves the repo
root from `main`, so the light fixtures go live on merge with no workflow and no `docs/` directory.
The rewrite makes the light condition `@media all` and the contrast condition `@media not all`.
**A force of light alone is not enough.** It leaves the contrast block's two non-token rules live,
so a visitor who asks for more contrast gets a preview nobody else gets.

**The generator raises when the rewrite no-ops.** If the stylesheet renames either condition, the
replace matches nothing and the preview equals the fixture. Pages then serves a dark page called
light, while regeneration still compares clean.

**Do not remove the banner on a light preview page to tidy it.** These pages once carried the
warning in their filenames, and a rename cost that signal. Three things carry it instead. Each light
page opens with a `markdown-alert-caution` block. `CONTRACT.md` § 1 states it. The light pages are
also deliberately **not** among the contract files, while the dark ones are. **Nothing outside this
repo should pin a page whose media queries were rewritten.**

**There is no high-contrast preview page.** That block leaves `--surface` alone, so a forced page
would look almost exactly like the dark sample. A preview that looks like the thing it contrasts
with teaches nothing. CI renders it and attaches the image to the pull request.

**Two gates cover the modes, and they cover different halves.** Neither one is a screenshot diff.
Layout is identical across the modes, and only color moves.

`.github/palette-check.py` check 5 re-derives the contrast floor for all four palettes on every run.
Each mode block only restates what it changes. The check therefore overlays the block's overrides on
the default palette, which is how the cascade resolves it too. **A measurement in prose is not a
gate.**

`.github/render-modes.py` covers the other half, which is that the palette **arrives**. **Headless
Chrome cannot be told which media query to match.** It reads `prefers-color-scheme` from the host.
`--force-dark-mode`, `--force-prefers-color-scheme` and `--enable-features=WebContentsForceDark` all
leave the result exactly as the OS had it. Each render therefore rewrites **every** mode condition
in a scratch copy. The target becomes `@media all`, and the rest become `@media not all`.

**The neutralization of the other conditions is the load-bearing half.** Its absence failed CI on
the first attempt. A rewrite of the target alone looked sufficient on a dark-appearance mac, and it
measured the light palette on a light runner.

The pixel read does not distinguish contrast mode from dark. The high-contrast block leaves
`--surface` alone by design. A sample of a text pixel instead means a fight with antialiasing for
nothing. **The read needs no image library.** For the first pixel of PNG row 0, every filter type
predicts from a left byte and an above byte that are both zero. The filtered bytes are therefore the
raw bytes.

The renders are **advisory on purpose**. They are not in `REQUIRED_CHECKS`. The assertions are the
gate, and the images are for a person to look at.

**`light-dark()` was considered for the mode swap and passed over.** Each mode redeclares roughly
fifteen tokens as one `:root` block under one media condition. `light-dark()` sets one declaration
at a time from two values, so the same swap would mean fifteen inline calls instead of one block,
which is more to read and more to keep in step, not less.

**High contrast and light mode do not compose. The ordering is deliberate.**
`prefers-contrast: more` is declared *before* the light block. A reader who asks for both therefore
gets the light palette at its own floor, rather than a high-contrast light palette. The alternative
is a fourth palette in a combined query. That is ten more measured values for a combination this
sheet has never been asked for. **The failure mode of a wrong order is much worse: dark
high-contrast accents on a white surface. Do not reorder the two blocks.** Take the fourth palette
when a reader asks for it.

## Print

**The print block overrides the palette tokens, not the elements.** `background` and `color` on
`body` alone leave every accent at its dark value on a white page. That also breaks both print paths
at once. With background graphics on, near-black text sits on dark fills. With them off, which is
Chrome's default, the light text those fills backed is stranded on white.

**Accent lightness is chosen against the print `--code-bg` gray, not against white.** The gray is
the harder ground. `--surface-alt` goes white as well. It is only the overlay backdrop, which cannot
be on screen and on paper at once. A dark value would park a near-black rectangle in the print
stylesheet, waiting for someone to reuse the token.

**`.table-scroll` releases its cap on paper.** A scrollport is a screen affordance. On paper it is a
guillotine that drops the overflow with no mark to say it is missing. Print sets
`max-height: none; overflow: visible`. The existing `tr { break-inside: avoid }` and
`thead { display: table-header-group }` carry the released table across pages. **A styled class with
no instance is an untested class.** That is why the fixture's wrapped table is twenty-four rows
rather than three.

**Page breaks are controlled.** `p` takes `orphans: 2; widows: 2`. The headings take
`break-after: avoid`. `break-inside: avoid` covers `tr`, `blockquote`, `aside`, `details`,
`.scorecard`, `.verdict`, `img`, `.markdown-alert`, `pre`, `dl.timeline > dd` and
`math[display="block"]`. `thead` takes `display: table-header-group`.

**`pre` belongs in that list, and the argument against it was wrong.** The worry was that
`break-inside: avoid` on a block longer than a page would be "either ignored or overflows". A fence
that fits moves whole to the next page, and it brings its heading with it. A fence that cannot fit
splits across pages with nothing lost, and it reprints its fill and accent bar on every fragment.
**The declaration is honored when the block fits, and dropped when it cannot.** That is the standard
resolution, and it is the behavior you want.

**`.verdict` prints as an outlined label**, with the semantic color moved to `color`. Its fill
carried the meaning, and white-on-accent is fine with backgrounds on and invisible with them off.
`.badge` needs no print rule. It is already an outlined `--label` chip, and print reassigns
`--label`.

## Filter

`filter.js` is the third inlined payload. Three decisions are load-bearing.

- **The scope is the sibling span, not the parent.** From the input, walk forward over siblings and
  stop at the next `input.filter-box`, or at the end. Within that span, filter `tbody tr` and
  `.nav-list > li`. **No `closest()` and no id-matching.** The script therefore never needs to know a
  consumer's ids, and the input-to-content pairing is the only relationship the markup states. A
  stop at the next filter box is a rule a consumer can predict with no read of the source. A stop at
  the first structural break would be arbitrary.
- **The script creates the empty line rather than requires it.** The created line carries its own
  copy. It starts `hidden`, because `.filter-empty` has no `display` declaration of its own. **It
  names no query on purpose.** An interpolated string would put a bare template in a payload
  consumers inline verbatim and cannot translate. Author-supplied copy stays untouched, because the
  branch only runs when there is none.
- **No CDN, no build step, no comments.** The whole handler is `querySelectorAll` plus
  `classList.toggle`.

**The one-table scope was reversed, and the reversal is deliberate.** The rule used to be one input,
one table, one listener. Two things forced the change. The fixture's own filter box was inert for
six releases. What follows it is a `.nav-list` and a `details.nav-group` with no table, and no gate
asks "does the handler bind". The scope rule also guaranteed that no consumer could inherit a
fix. The largest generator of these pages hand-maintained its own 41-line replacement. **A shipped
contract file with no reachable user is worse than no file.**

The script captures `details.nav-group` open state once at bind time, and it restores that state
when the query clears. A group the script opened during a search must not read as a group the reader
opened.

**`summary .count` is captured and restored on the same terms as the open state, and for the same
reason.** The count was left alone while the query hid items under it, so a group read `5` over two
visible rows while the `[role="status"]` line beside it read the truth. That is one page stating a
number twice and disagreeing with itself, and the stale figure is the larger of the two. The
authored text is restored rather than recomputed on clear, because the number a generator wrote is
a claim about the group and not necessarily a row count. **Do not derive the cleared value from
`rows.length`.**

**The `[role="status"]` line takes a register: `.filter-box ~ [role="status"]`.** Every other piece
of filter chrome had one, so the count rendered at body weight on `--on-surface` and read as content
sitting above the list. **The selector stays a sibling combinator on purpose.** `filter.js` finds
the element with `input.parentElement.querySelector`, which is wider than any selector can be
without claiming every `[role="status"]` on a consumer's page. The narrower rule styles the shape
`CONTRACT.md` § 6 actually documents and leaves a status line elsewhere in the document alone.

`.filter-box` is `font-size: 1em`. **Do not write a `pt` floor here.** 16pt is not 16px, and the
iOS-zoom threshold is 12pt.

## Nav link separators

`nav > a + a` takes a `border-inline-start` plus symmetric padding. Without it, a `<nav>` of sibling
`<a>` children renders as an undifferentiated run of link text.

**The wrapped-line separator is a known artefact, and the repo accepts it.** The separator is a
border on the link. A link that begins a wrapped line therefore carries a separator with nothing to
its left. **No pure-CSS rule can suppress a border at a line break.** The wrap position is not
addressable from a selector, and flex wrapping moves the problem rather than solves it. The
alternatives were a pseudo-element glyph, which dangles identically, or no separators at all, which
is the state the rule exists to fix. The fixture carries enough links to wrap at a phone width, so
the artefact stays visible rather than hidden behind a two-link nav.

## Version stamps are not version history

**`scripts/maintain.nu bump` rewrites three anchored stamps and nothing else.** Those are the
stylesheet header comment, the `(template vX.Y.Z, oklch palette)` cell, and the `is **vX.Y.Z**`
line. A blanket replace across `README.md` also walked historical claims forward. Prose of the form
"raw HTML is covered as of vX.Y.Z" then credited the wrong release on every bump.

**Each pattern must match, or the bump fails.** A stamp that moves is a loud failure rather than a
silent no-op. A no-op leaves the tree with a claim of the previous version, while the release verb
believes it stamped.

This matters more than a docs tidy. `CONTRACT.md` carries a per-version delta table, which is the
same shape of data. A blanket replace would rewrite every row of it.

## Unclaimed elements

**An element the sheet does not claim renders in whatever the UA decided.** In a dark theme that
usually means a light-mode default that survives. `mark` came out pure yellow on pure black.
`caption` centered itself. `figcaption` read as an ordinary paragraph. `figure` had no margins at
all, because the `*` reset ate the UA's.

**`mark` is a wash, not a chip.** `--highlight` is `--orange` at a tuned alpha. The wash reads
clearly against the page, and body copy on it still clears the text floor with headroom. A higher
alpha reads as a chip, and it costs text contrast. `mark` pins `color: var(--on-surface)`
rather than inherits, because it renders inside `--label` containers where every other tier fails on
the wash. Print inverts it to an outline, which is the same move as `.verdict`.

**`kbd` is a ringed chip, deliberately not `code`.** It takes the same fill and mono face, with
`--on-surface` text rather than `--green`, and a `--rule` ring. A shortcut is not a code fragment,
and the ring is the only thing that separates them. The ring is `--rule` rather than `--rule-light`,
because it sits on `--code-bg`. `kbd` joins the forced-colors border list, because an inset shadow
is the only boundary it has.

**A second shadow layer, `0 1px 0 var(--rule)` outside the ring, gives the bottom edge one more
weight.** Borrowed from factory.strongdm.ai's keycap, this is what reads as a raised edge rather
than a flat chip. It reuses `--rule`, the same token the ring already uses on `--code-bg`, so no new
token exists for it. The existing forced-colors border already replaces both shadow layers at once,
the same way it already replaced the ring alone.

**A `caption` sits above the table's frame, not inside it.** `caption` is a child of `table`, so the
table's top rule paints above it, and the caption reads as a stray first row. `table:has(caption)`
drops the top rule. The caption then becomes a label over the table.

**`figcaption` sets `text-align: start` explicitly.** `pre.mermaid` is centered, and a caption that
inherited that would float in the middle of a full-width column.

## Markdown coverage

The sheet was written for hand-authored markup. A consumer can also point a markdown converter at
it. Every construct a converter emits lands in a theme register with **no classes of its own**. **Do
not invent classes for markdown constructs.**

**`h4` to `h6` all sit at `1em`.** Weight and color carry the tier. h4 is 600, h5 and h6 are 500. The
colors run `--label` then `--muted`, and h6 adds italic. The `*` reset ate the UA margins while the
UA font-size ramp survived. A sixth-level heading therefore rendered smaller and heavier than body
copy, which is the exact inverse of the type-scale rule. **Weight 450 was rejected for h5 and h6.**
It ties body copy, and it gives the same problem one tier down. Depth past h4 is rare enough that a
fourth size step buys less than a fourth color step.

**A presentational attribute loses to author CSS.** That is why pipe-table alignment vanished.
`td { text-align: start }` silently beat `<td align="right">` every time. Three `[align]` rules are
the fix. Inline `style="text-align:…"`, which pandoc emits, already won on its own.

**GFM alerts take the `aside` rule rather than a second callout form.** An alert *is* an aside, so it
takes the same form: one bar and no fill. The two selectors share one declaration block. The hue
lands on the bar and on `.markdown-alert-title`, never on the body text. `warning` keeps plain
`aside` orange, so an alert-free document and an alert-heavy one read the same. The octicon GitHub
emits is `fill: currentColor`, so it takes the hue for free.

**Highlighted code reuses the Rider slot map rather than invents one.** Keywords take `--pink`.
Strings take `--green`. Numbers and parameters take `--orange`. Comments take `--muted` italic.
Functions take `--link`. Types take `--purple-bright`. Fields and attributes take `--label`. Errors
and deletions take `--red`. Punctuation inherits. One grouped selector per role covers
`highlight.js`, pandoc and skylighting, Prism and Pygments.

**Every rule is scoped under `:is(pre, code)`.** The pandoc and Pygments classes are one and two
letters. An unscoped `.dt`, `.op` or `.m` would repaint a consumer's own markup.

**One collision inside that map is known and accepted.** `.ch` is pandoc's `Char` in the string
group and Pygments' `Comment.Hashbang`, so a shebang renders in the string tier. One line in the
wrong tier is cheaper than a second selector set.

**Types take `--purple-bright`, and in print the lift inverts.** Plain `--purple` is the one ratio
the contrast budget records as a failure on `--code-bg`. The repo left it alone, because "nothing
puts purple text on the gray". A syntax slot map does exactly that. `--purple-bright` is
`oklch(from var(--purple) calc(l + 0.07) c h)`, which is the same lift `scripts/create-themes.nu`
already calls `bright`. It therefore needs no new hex and no new `/* was */` note. **Print
redeclares it as plain `--purple`**, because on a light ground more lightness is less contrast.

**Monospace was inheriting italic from `blockquote`, `th` and `summary`.** One rule resets `code`,
`pre`, `kbd` and `samp` inside those three. It covers `h2` and `h6` for the same reason.

**`color-scheme: dark` on `:root` is not cosmetic.** Without it a UA form control renders light-mode
inside a dark page. Print sets `color-scheme: light`.

**The task-list checkbox stays a native control, and it stays gray when checked.** GFM emits it
`disabled`, and Chromium ignores `accent-color` on a disabled control. A repaint means
`appearance: none` plus a tick from a data-URI SVG. That puts a literal hex in the stylesheet with
nothing to gate its drift against `--surface`, and pseudo-elements on inputs are unreliable in
Safari. **A read-only checkbox that reads as read-only is the cheaper answer.** `list-style` drops
through `li:has(input[type="checkbox"]:first-child)` rather than GFM's `.contains-task-list`, so the
rule holds for `markdown-it` output too.

**Five smaller claims.** `del` and `s` drop to `--muted`, because a line-through at full body color
reads as emphasis. `samp` takes `--mono-font`. `sub` and `sup` take `line-height: 0`, so a footnote
reference does not open the line it sits on. `abbr[title]` gets a dotted rule and `cursor: help`.
`img.emoji` loses the `--ring` outline and takes `1.1em`, because the ring is for figures.

**Footnotes land in `:is(.footnotes, .footnote)` behind a hairline at the caption tier.** That
matches both the `cmark-gfm` and pandoc shape and Python-Markdown's singular class, and it drops the
duplicate leading `<hr>`. The Tufte `.sidenote` apparatus is separate, and it still needs
hand-authored markup.

**`.footnote-backref` needs an `aria-label`, and this is the one accessible-name requirement this
repo asks of converter output rather than only of hand-authored markup.** `cmark-gfm` and pandoc
both emit the backref as a bare `&#8617;` glyph with no name of its own. A screen reader announces
the Unicode character or nothing useful, never "back to reference 1", and no CSS rule can attach an
accessible name to content the stylesheet did not write. This differs from the outbound-link arrow,
which was silenced (`content: "…" / ""`) because it is decorative and had wrongly reached the
accessibility tree; a `.footnote-backref` is a real, functional control, so the fix runs the other
way: give it a name rather than take one away. `CONTRACT.md` § 2 states it as a generator
obligation, numbered per footnote, because two unlabeled backrefs on one page announce identically
either way.

**The sheet styles math where it arrives as real HTML. It renders none.** An unstyled
`<math display="block">` overflows the **page**, not itself. That is the same failure a wide table
has, and it takes the same two rules: its own scroll axis, and `pre`'s margin rhythm.
`.math.display` takes `display: block` and the same pair. That class covers the span pandoc emits
without `--mathml` and the box KaTeX renders into. **A font-size bump was built and dropped.** The
math font's x-height already matches the body serif, and the bump would re-scale math inside `h3`
and `td` as well. Color, italic variables and the centering of display math are all UA behavior, and
all correct.

**TeX is not rendered, and that is where the CDN line sits.** KaTeX or MathJax is a second
hard-offline dependency of Mermaid's kind, for a construct that may never appear. The sheet styles
the containers, so a consumer who adds KaTeX gets the block layout free.

**Chroma was declined on a namespace argument, and that argument silently excluded Pygments.** Hugo
defaults to `noClasses = true`, and it writes inline color on every span, so Chroma is mostly moot.
Pygments is not. It emits classes by default, and it is the highlighter behind Sphinx, MkDocs,
Quarto and `nbconvert`. Chroma copies the Pygments class names, so the same selectors cover it for
consumers who turn `noClasses` off.

## Raw HTML and other generators

Every converter passes raw HTML through untouched.

**Intrinsic-width media pushes the document sideways, and `img` was the only element claimed.**
`:is(svg, video, canvas, iframe, object, embed) { max-width: 100% }` is the fix. That is the same
1.4.10 failure the MathML block had.

**That rule carries no `height: auto`, and that is deliberate.** `img` needs it, because a raster has
an intrinsic aspect ratio to preserve. An SVG with a viewBox preserves its own ratio, and the
sideways scroll is what the rule exists to stop. The declaration would also put a second sizing
input on `pre.mermaid svg`, where three previous attempts were correct on paper and wrong on screen.

**`svg` is in that selector only because a fixture diff proved it inert against mermaid.**
`pre.mermaid svg` already carries `max-width` through its own rules. Below 600px it carries
`max-width: none !important`. The new rule is therefore outranked exactly where a diagram needs to
escape.

**`body` takes `overflow-wrap: break-word`, not a list of nine selectors.** A hash, a long path or a
base64 fragment outside a code span had no break opportunity. One declaration inherits to every
prose container. That includes the ones a list would forget and the ones a later release adds. It
costs nothing in layout, because `break-word` does not reduce a box's min-content contribution.

**`position: sticky` is scoped to `thead th`.** Unscoped, a `tfoot` header cell pinned to the top,
which is a totals row stuck in the header's place. The `th` typography stays on `th`, so a footer
cell still reads as a header cell.

**Permalink anchors reveal on hover, and the `:focus-visible` half is not optional.** Sphinx, MkDocs
and markdown-it-anchor emit `a.headerlink` or `a.anchor` inside the heading, visible at all times by
default. The rule sets `opacity: 0`. It lifts on `:hover` of the heading and on `:focus-visible` of
the link. **Without the focus half the link stays in the tab order while it is invisible.** That is a
keyboard stop nobody can see.

**Form controls take `font: inherit` and a `1rem` floor, and nothing else.** `.filter-box` was the
only control that set a family. Every other one fell to a small sans-serif inside a serif page,
below the threshold where iOS Safari zooms on focus. **Appearance is deliberately not styled.** A
focus ring, a hover state, a disabled state and a pressed state are a button design. This is a
document theme with exactly one control of its own. `color-scheme: dark` already tells the UA to
render its widgets dark.

**Three conventions stay unclaimed, and the reasons are worth keeping.**

- **Non-GFM callouts.** `.admonition` (Python-Markdown, MkDocs, Sphinx, docutils), `.callout-*`
  (Quarto) and `.admonitionblock` (Asciidoctor) all render bare. Asciidoctor is worse than bare. It
  renders its callout as a `<table>`, so it inherits the sheet's table frame and sticky header.
  Against that: three more conventions is a fourth, fifth and sixth name for a role the sheet
  already paints twice. Every selector is also weight in every consumer file. Revisit this when a
  consumer actually runs Sphinx or MkDocs.
- **Jupyter ANSI output.** Sixteen ANSI names onto seven accents is a set of choices rather than a
  translation. The intense variants also have nowhere sensible to land. The `.dataframe` table
  pandas emits already inherits the sheet's table rules.
- **`address` and `.tabbed-set`.** `address` keeps its UA italic, which is arguably right for a
  postal block. `.tabbed-set` shows every panel at once. A fix means a claim on a radio-driven
  widget rather than one rule.

**A solid underline means a link. A dotted underline means an annotation.** `ins` and `u` took the UA
underline at body color, which is the one mark this theme uses for a link. Track-changes markup
therefore read as clickable. Both now use the dotted form `abbr[title]` already uses. `del` and `s`
keep their `--muted` line-through.

**`menu` joins all three list rules.** It takes `list-item` children. Without the indent rule the `*`
reset left its markers hanging outside the box.

**The zero-user class families stay.** `scorecard`, `edge-list`, `col-2`, `badge`, `newthought`,
`sidenote`, `marginnote`, the filter family and `body.conn-map` have no documents in the measured
lode. That zero measures the generator as much as the stylesheet. A generator that never offers a
component guarantees that no document uses it. **`sidenote` and `marginnote` are the Tufte signature,
and they are the reason the layout reserves a right margin at all.** The zero there is a generator
gap. `conn-map` is the weakest case, and it is also the only worked example of the two-section
sticky layout.

**`.verdict` and `.scorecard` had the same generator gap, undocumented rather than merely unused.**
A real proof-test page (a graded scorecard against 27 lens-methods, the exact content this component
exists for) rendered every verdict as bare text: a plain `<table>` cell, a heading suffix, a bold
summary word, none of them carrying `.verdict` or a pass/partial/failed/neutral class. `CONTRACT.md`
had never listed the markup, so the generator had no way to discover it existed. `dl.timeline` got a
`§ 2` checklist entry when it shipped. `.verdict` and `.scorecard` did not. Fixed by adding one now:
see `CONTRACT.md` § 2 and the v1.31.0 row of § 3.

**`.verdict` was missing `display: inline-block`, and `min-width` had been silently dead outside
`.scorecard`'s grid the whole time.** A grid item's computed `display` blockifies regardless of what
the rule itself declares, so `min-width: 5.2ch` held inside `.scorecard`, where every measurement to
date happened. `min-width` does not apply to a non-replaced inline box at all, per spec, so the same
class on a bare `<span>` in a `<table>` cell, a heading, or prose sized to its own text with no floor
under it. Nothing in this repo's fixtures ever put `.verdict` outside `.scorecard`, so nothing here
caught it. A short word like `N/A` still happened to clear the floor on its own padding, which is why
the defect produced no visibly broken badge, only an inconsistent one next to a wider verdict.

## Fixtures are coverage

**A fixture demonstrates states. It does not simulate them.** Several details look like filler and
are regression checks. **A cut to any of these retires the check it exists to be.**

**A new page means five hardcoded fixture lists, not one.** The five are:

1. The page list in `scripts/build-sample.nu`.
2. The presence list in `scripts/maintain.nu`.
3. The style-and-script count list in `scripts/maintain.nu`.
4. The light-preview list in `scripts/maintain.nu`.
5. The staleness list in `scripts/maintain.nu`, plus `FIXTURES` in `.github/render-modes.py`.

**Miss the `render-modes.py` one and the new page renders in no
appearance mode, while the check still prints `Contract OK`.** That list drives the image count
rather than derives from the directory. The count is the tell. Three fixtures times three modes is
nine images.

- **`samples/dark-timeline.html` is the one fixture built from real content, and the length is the
  point.** Four era groups are four separate lists, which is the case `max-content` cannot serve and
  `--timeline-date` exists for. The citation density is where the floated sidenote form fails. It is
  also what the `:target` outline and the enlarged marker hit area were measured against. Every `dt`
  carries an id, so the arrival cue is walkable rather than merely declared.
- **The sequence diagram and quadrant chart** sit beside the flowchart, because a flowchart is the
  one diagram type that shows neither label-measurement bug. Its labels are `foreignObject` HTML the
  browser measures, and its viewBox comes from the laid-out graph. The sequence fence's `Note over`
  is deliberately wider than its actor box. The quadrant fence carries point labels long enough to
  overrun the canvas.
- **The conn-map focus node's long label.** The connections map is the one fixture that renders with
  `useMaxWidth: false`. It is therefore the only place a mis-sized node box lands in a *constrained*
  column rather than on an open page.
- **The filter's `role="status"` line and its `.filter-empty` line.** The repo asked consumers for
  both and had neither anywhere. Nothing verified that the empty state rendered, and a consumer had
  no reference copy. **Nothing hand-written into a fixture may restate a runtime value the reader
  controls.** The empty line once quoted a query the reader never typed, so the page stated two
  different things about one keystroke. A count can be checked against the page. A quoted query
  cannot.
- **The wide table in `.table-scroll` is wide and tall on purpose. It is the only instance of that
  wrapper in the repo.** A short wrapped table renders identically to an unwrapped one, and it
  proves nothing. Eight columns push it past the body, so the wrapper takes the sideways scroll
  rather than the document. Twenty-four rows push it past the `70vh` cap, so the pinned header has
  something to hold against. `role="region"` sits on the wrapper, so the table keeps its own
  semantics.
- **The highlighted code block carries real emitter classes**, in the nesting `highlight.js`
  produces. They are not hand-written spans on invented names. It is the only check that the slot map
  still matches [`themes/rider/README.md`](themes/rider/README.md), and the only place
  `--purple-bright` renders. All five GFM alert types are present for the same reason.
- **The Pygments block beside it carries the one- and two-letter names.** It is the only check on the
  half of the slot map a bare `.k` or `.m` could break. It is also the only place `.p` proves that it
  still inherits. Two code blocks on one page is on purpose. The two sets can drift apart without
  either one failing alone.
- **The MathML block** exists to prove that `math[display="block"]` is claimed at all. A delete
  retires the only test that a converter's math does not reintroduce a horizontal page scrollbar.
- **The `<em>` label says what `em` actually does.** It named a color the sheet no longer paints,
  long after the rule was deleted.

## Repo layout

**The Nushell scripts live in `scripts/`, and the Python helpers stay in `.github/`. The split is by
who invokes a file, not by language.** Each Python helper is a CI step of its own, and it appears
verbatim in `contract-check.yml`. It therefore lives beside the workflow that runs it. The Nushell
scripts are the commands a person types.

**Both kinds resolve every path from the repo root, never from `cwd`.** The Nushell side needs two
constants, because `path self | path dirname | path dirname` is **not** a legal const chain in
Nushell:

```nu
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname
```

The payload, the fixtures, `tokens.css` and the docs stay at the root. Pages serves the root, and
consumers pin paths into it.

**Python stays, and the repo measured the alternatives rather than argued them.** Both helpers were
put up for rewrite, and both stayed.

- **"Bash" is not an option. Only awk is.** Bash has no floating-point arithmetic, and the Oklab
  matrix needs `cos`, `sin` and a fractional power. A bash version is an awk program in a shell
  wrapper. That takes the repo from `{nu, python, bash}` to `{nu, bash, awk}`, which is the same
  three languages with the math in the least readable of them.
- **Nushell would genuinely drop one language, and it is a rewrite of the primary gate.** The math
  ports exactly. That is a real gain. It is also two hundred lines of the most load-bearing check
  in the repo, rewritten to save a dependency preinstalled everywhere it runs. **Take it if the check
  needs a substantial change for its own reasons. Do not take it on its own.**
- **`render-modes.py` cannot move at all, and this is the hard blocker.** A read of one PNG pixel
  needs zlib inflate, which neither Nushell nor bash has. The gzip-header workaround inflates
  correctly, and then it **always fails its trailer**, because a zlib adler32 is not a gzip crc32.
  The check would therefore have to ignore its own exit status. It could then no longer tell a
  corrupt screenshot from a good one. That is the exact class of quiet wrongness the gate exists to
  catch.

## Odds and ends

**A shadow-drawn rule on a zero-height box paints nothing.** `hr` read `border: none; box-shadow:
…`, and `border: none` collapses the element to zero height. The separator was therefore invisible at
every width, in print and in forced colors, for as long as the rule existed. It is a
`border-block-start` now. The same defect does **not** affect `table`, whose box has real height.
**Shadow-drawn rules are fine. Shadow-drawn rules on a zero-height box are not.**

**`scrollbar-color` sits on `body`, not on every scrolling box, because the property inherits.** One
declaration reaches `.table-scroll`, `pre`, the narrow-viewport `pre.mermaid` scroll and the
document's own scrollbar.

**`overscroll-behavior: contain` goes on every scroll container the sheet owns.** Those are
`.table-scroll`, the mermaid overlay, the narrow-viewport `pre.mermaid` rule and the conn-map sticky
column. Without it, a scroll to an edge chains into the page behind it.

**`--ring` is a token, because the `img` hairline was the one color declared twice as a literal.** As
a token it flips in print beside the other overrides, and the `img` rule disappears from that block
entirely. It is deliberately not a palette color. White at 10% over an arbitrary image is a
translucent veil rather than a hue. Its alpha-slash form does not match `palette-check.py`'s
`oklch(L C h)` regex, so the parsed token count is unaffected.

**The W3C CSS validator reports two errors, and both are the validator.** It flags `container-type`
and `@container`, which come from a module its `css3` profile predates. Those two declarations are
the load-bearing fix for `.scorecard` overflow under text-only zoom. **Do not delete them to make
the validator quiet.** That trades a real rendering bug for a green badge. The warnings are noise of
the same kind, mostly "CSS variables are currently not statically checked".
