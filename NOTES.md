# NOTES.md — why the stylesheet looks like this

`tufte-dracula.css` and `mermaid.js` are inlined verbatim into every generated HTML file,
so they carry no comments (see `CLAUDE.md`). This file holds the reasoning that used to
live in them. Every number below was measured in Chromium, not reasoned about.

**Two comments remain in the CSS, and both are machine-read data rather than prose:**

- **Line 2, the version** (`/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`). `build-sample.nu` reads
  the version from `lines | get 1` to stamp `tokens.css`, and `maintain.nu bump` rewrites
  it. Stripping it broke regeneration with `index too large (empty content)`, and because
  that error was piped away the fixtures went stale while still looking correct.
- **The `/* was #rrggbb */` notes on ten `:root` tokens.** `.github/palette-check.py`
  check 3 parses them and fails if a stated hex disagrees with its `oklch()`.

Removing the comments was verified behaviour-neutral: computed styles for every element in
both fixtures, at 390/900/1280/1920px, are byte-identical to the commented version —
0 differences across 160 elements × 4 viewports. Sizes went 35192 → 13399 bytes for the CSS
and 4731 → 2079 for `mermaid.js`, taking `sample.html` from 45173 → 20728 bytes (54%) and
`sample-conn-map.html` from 41030 → 16585 (60%). That reduction lands in every page a
consumer generates.

---

## Fonts

**Body face is Source Serif 4**, a variable serif pinned to an exact jsDelivr version the
way `mermaid.js` is. Two faces (roman + italic), ~50KB each, served `immutable`.

Why a webfont at all: every system serif ships 400/700 and nothing between, so there was
no way to ask for the ~450 that light-on-dark body copy wants. Georgia at `font-weight:
400` and at `450` render *identically* — measured, the 450 does not exist. The variable
axis is 200–900, so 450 is real, and `600` on `.newthought` / `strong` / `dt` is a real
600 instead of snapping to bold.

Why this face over Literata, Newsreader, Lora, Petrona: its figures are **tabular and
lining by construction** (all ten digits at 529/1000), so tables align in the body serif
with no OpenType feature support required. x-height is 475/1000 against Georgia's 481 — a
1.2% difference, so no em-relative value needed re-deriving.

| candidate | wght axis | x-height | figures |
| --- | --- | --- | --- |
| **Source Serif 4** | 200–900 | 475 | tabular + lining |
| Literata | 200–900 | 507 | proportional, lining (needs `tnum`) |
| Newsreader | 200–800 | 426 | tabular + lining |
| Lora | 400–700 | 500 | proportional + **old-style** — Georgia's exact defect |
| Petrona | 100–900 | 443 | proportional, lining |

None of the five ship `smcp`, so `.newthought` small caps are still synthesised. The
webfont bought the weight axis, not true small caps.

**The fallback path is a genuine downgrade, not an equivalence.** Offline the stack falls
through to Georgia, which has no 450 (weight collapses to 400) and whose figures are
old-style and proportional, so tables lose alignment. Measured table per-digit spread:
0.00% online, 4.21% on the fallback. Accepted because text still renders and reads —
unlike the mermaid CDN, which renders no diagram at all offline. `font-display: swap` so
text is never invisible while loading.

Georgia stays first in the fallback stack: most widely installed sturdy screen serif
(Windows since Win98, all macOS, iOS), low stroke contrast, large x-height. Noto Serif
covers Android/ChromeOS, DejaVu Serif covers Linux. Charter and Palatino are absent on
purpose — both exist only where Georgia already does, so they were unreachable.

**No `-webkit-font-smoothing: antialiased`.** That advice exists because macOS renders
text heavier than intended *for dark text on light*. This theme is the inverse, and
grayscale-only antialiasing thins strokes — the opposite of what light-on-dark needs.

## Type scale

The body `font-size` clamp is the **only size lever**: every other step, headings
included, is em-relative to it, so nudging it rescales the whole page proportionally.

Floor `1rem` = 16px (the long-form minimum, and the iOS input-zoom threshold that
`.filter-box` inherits); cap `1.25rem` = 20px. Every bound is rem, never px, so a reader
who raises their browser default scales the page with it. A previous
`clamp(1.0625rem, 1rem + 0.35vw, 1.375rem)` ran 17→22px and read oversized on a desktop.

**Do not lower the floor past `1rem`** without giving `.filter-box` its own 16px floor —
iOS zooms below 16px, and the input sits exactly on the threshold.

Steps, all relative to body size:

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

Nested ratios compound — check the parent before adding a step.

**Headings are `em`, not `rem`.** Anchored to the root (a fixed 16px) they diverged from
body copy, which grows on a vw clamp: measured, h3 rendered *smaller* than the paragraphs
it introduced at every width (15.3 vs 17.4 at 390px, 17.6 vs 22 at 1920px), and h2 fell to
1.16× body. `em` resolves against body, so the ratios hold everywhere.

An earlier scale used `max(Xem, 12pt)` floors. Those resolved to 16px on every viewport
under ~950px, pinning nine elements to one size and making body copy the *smallest* text
on a phone. `pt` is absolute like `px`, so they also ignored the reader's own setting.

**`h1`/`h2` sit at weight 400** — 22–35px carries itself. **`h3` is 500**: it is the one
heading at text size (1.12em, only 12% over body), so at 400 it rendered lighter than the
paragraph beneath it. Being heavier than h2 is not an inversion — h2 is 20% larger, italic
and `--purple`. Raising weight as size drops is ordinary practice.

**`.verdict` / `.badge` at 0.8em, not 0.75em**: they nest inside a 0.95em parent, so the
ratios compound and `0.75 × 0.95 × 16px` = 11.5px, under the 12px floor. 0.8 gives 12.3px.
Coupled to the body floor — if that moves, re-check these.

**`code` / `cite` at 0.9em**: SF Mono's x-height is 526/1000 against Source Serif 4's 475,
a ratio of 1.094, so the x-height-matched size is 0.914em. A previous 0.85em was tuned
against Palatino (x-height 471) and over-corrected by ~7%.

`pre code` is `font-size: 1em` to halt em-compounding — `code` and `pre` each carry 0.9em,
so a bare `<code>` inside `<pre>` would render at 0.81em, smaller than the block it fills.

**`li` carries no `font-size` of its own.** It sat at 0.95em in the structural tier with
tables and nav, which made a bulleted list inside an `<article>` render at 17.48px against
18.4px paragraphs — body copy reading as subordinate to the body copy beside it. A prose
list is prose. The two contexts that do want 0.95em already ask for it themselves:
`.nav-list li` sets it directly, and `nav` sets it on the container. That last one was
double-counting while `li` had its own value — `nav > ul > li` compounded to 0.9025em, the
smallest text on any page that used a `<nav>`. Dropping the `li` declaration also retired
`li li { font-size: 1em }`, which existed only to stop the same compounding one level down;
with nothing to compound, the guard has nothing to guard.

## Italics

Eight italic rules: `.byline`, `h2`, `th`, `summary`, `blockquote`,
`details.nav-group > summary`, `.filter-box::placeholder`, `.filter-empty`.

**`h3` is upright, `h2` is italic — deliberately.** They are adjacent levels, so while both
were italic the slant distinguished neither and the hierarchy rested on size and colour
alone. Upright h3 gives the pair a second axis (h2 italic `--purple`, h3 upright
`--label`), and it lands where italic is most expensive: 1.12em is barely above text size,
where a slanted stem on a dark surface loses more definition than a 1.35em heading does.

**`summary` is 450, not 400.** It inherits the body font-size, so at 400 it was the only
italic text at *reading* size lighter than the copy around it. The italic stays — it marks
the row as a label rather than prose. `details.nav-group > summary` inherits the weight.

**`th` is 450**, matching body copy: a header row lighter than its own data reads as
subordinate to it. The declaration cannot simply be dropped — the UA default for `th` is
bold. Italic and `--pink` carry the distinction; weight must not work against it.

## Width and measure

**Page width is one number**, `--page-width: min(90vw, 160rem)` in `:root`, referenced by
`body` and by `body.conn-map`'s article alike, so the two layouts cannot drift.

- `90vw` — the proportional side margin, 5% each side. This is the dial for page width.
- `160rem` — ultrawide backstop, ~2560px at a default root. Engages past ~2844px where an
  uncapped line would run 390+ characters. `rem` so it scales with the reader's root size.
- `100% - 2 * var(--gutter)` on `body` is the floor, and what respects the safe-area
  insets the mobile rule folds into `--gutter`.

**Three failed attempts, recorded so they are not retried:**

1. `min(100% - 2 * var(--gutter), 70ch)` plus an `@media (min-width: 1200px)` override to
   `80vw`. The 70ch cap left **34.8% of a 1199px window empty** (body 782px), and crossing
   1200px snapped content from 782px to 960px in one step.
2. A `100rem` cap — left 16.7% of a 1920px window empty and cut 2560px down to 1600px.
3. Gutter + backstop only, no proportional term — made the page effectively full-bleed,
   32px margins at every size, 2.5% unused at 2560px.

"Unused space" is **not** the metric to minimise. A page needs side margins that scale.

**The long measure is a standing decision, not an oversight.** Content flows nearly the
full window, which runs ~178 characters per line at 1920px against the conventional 60–75.
This stylesheet serves dense reference pages with tables and diagrams, not book-length
prose, and width is what those pages need.

Re-litigated once; the answer did not change. Capping prose at `max-width: 32em` does hit
~74 characters at every width, but it strands body copy in a narrow left column with the
rest of the container empty. If it is ever revisited:

- The cap belongs in `em`, **not `ch`**. `ch` is the advance of `0`, and Georgia's `0` is
  0.614em against a 0.433em average prose advance (ch/avg = 1.416 measured), so a `ch` cap
  resolves ~1.42× wider than it reads — `70ch` ran 99 characters, not 70.
- It must be scoped to section children. A bare `p` selector also hits `.byline` (a flex
  item in the conn-map header, which collapses the two-column layout when capped) and the
  `<p>` mermaid emits inside `foreignObject` labels.
- Smaller type makes the measure *worse*, not better: container width is `vw`/`%`-driven,
  so shrinking type just fits more characters per line.

## Tables

**No `font-family` on `table`** — tables inherit the body serif, which is correct because
Source Serif 4's digits are tabular and lining by construction.

Tables briefly carried the monospace stack because Georgia could not do this: its figures
are old-style *and* proportional (9 distinct advances, `1` at 430/1000 against `0` at
614/1000) with no `lnum`/`tnum` to escape them — its entire GSUB feature list is `aalt,
locl`. That workaround cost ~27% table width (807px vs 634px natural at 1280px on a
6-column table) and put tables in a different register from the prose.

`font-variant-numeric: tabular-nums` on `td` is belt-and-braces, not the load-bearing fix.
It earns its place on the fallback path, where it works in any face exposing `tnum` — it is
inert in Georgia, which exposes neither `tnum` nor `lnum`.

**Sticky `th`** needs an opaque background or zebra rows show through. The rule is an inset
shadow, not `border-bottom`: under `border-collapse: collapse` the collapsed border is
painted by the table, so it scrolls away from the stuck header and leaves it running
straight into the first row. Note the sticky header is inert below 600px — see `backlog.md`.

## Links

**Underline thickness has a 1px floor.** `0.05em` resolves to 0.8px at the base size,
which paints as a faint partial-coverage line, and the underline is the only thing marking
a link, so it cannot be optional.

`overflow-wrap: break-word` lets a long URL or slug break instead of escaping its
container — the connections-map Links column is as narrow as 220px.

**The outbound arrow is decorative but reached the accessibility tree.** Measured via CDP
`Accessibility.getFullAXTree`, the link computed as `"outbound link\A0↗"`, so a screen
reader read out "north east arrow" after every external label. `content: "…" / ""` gives
the pseudo-element empty alternative text, suppressing both the arrow and the nbsp for
assistive tech while leaving the glyph visible.

It sits behind `@supports (content: "x" / "y")` because the alt-text syntax is a single
value — a browser that cannot parse it discards the **whole** declaration and the marker
disappears outright. Firefox ESR 128 is in that group and still deployed. Verified both
paths: supported gives accessible name `"outbound link"`; unsupported keeps the marker
visible and merely retains the old announcement. Nothing regresses either way.

`\A0` (nbsp) keeps the arrow from orphaning onto its own line. Print sets `content: ""` —
that rule is later in source order and wins.

`cite` is monospace and `font-style: normal`: the browser default is italic serif, which in
this theme is indistinguishable from `<em>`, losing the semantic distinction.

## Mermaid

`theme: 'base'` + explicit `themeVariables`, **never `theme: 'dark'`** — the stock dark
theme ignores this palette entirely.

**Hex, never `oklch()`.** khroma throws "Unsupported color format" on an `oklch()` string
and aborts init, so no diagram renders at all. Values mirror `mermaid-palette.json`, and
CI enforces the match.

**`darkMode` belongs *inside* `themeVariables`.** `mermaidAPI` passes only
`config.themeVariables` to `base.getThemeVariables()`, so a root-level `darkMode` never
reaches the theme and every derived colour is computed light-mode — ER rows come out
`lighten(mainBkg, 75)`, near-white under light `textColor`.

**`fontFamily` and `fontSize` are the only non-colour `themeVariables`**, deliberately not
mirrored into `mermaid-palette.json`: that file and `palette-check.py` exist to catch hex
drift against the oklch source, and a font stack has no hex to drift. `fontSize` is a CSS
length string, so `1rem` tracks the reader's root size; mermaid's default is a hard-coded
16px that ignores it.

**`background` is inert.** It is set to `--code-bg` to match the `pre` a diagram renders
in, but measured across 12 diagram types (flowchart, pie, ER, class, sequence, state,
gantt, journey, quadrant, gitGraph, mindmap, timeline) the value never reaches the output:
every SVG canvas is transparent, there is no full-size background rect, and the previous
`--surface` hex appeared nowhere in mermaid's injected CSS. The `pre`'s own background
shows through. The value is correct-by-intent rather than load-bearing.

**Diagram type size was uncontrolled.** `pre.mermaid svg { width: 100% }` stretched a
viewBox'd SVG to its container, multiplying mermaid's label size by the same factor:
measured 13.9px at 390px → 36.8px at 1280px → **51.7px at 1920px**, i.e. 1.35× the h1 and
the largest text on the page, set by nothing but how few nodes the graph had.
`width: auto` pins labels to the size mermaid asked for; `max-width: 100%` still shrinks a
graph too wide to fit, and `text-align: center` keeps a small one centred. `fontSize:
'1rem'` alone does not fix it — still 47.1px at 1920px.

**Click-to-zoom** strips mermaid's own sizing from the clone so the overlay's CSS governs
every diagram identically. `calculateSvgSizeAttrs` writes `width="100%"` plus an *inline*
`style="max-width:NNNpx"` when `flowchart.useMaxWidth` is true (the default), and
`width`/`height` attributes when false (what the connections maps set). An inline
`max-width` outranks the stylesheet, so left in place the zoom magnifies in one layout and
does nothing in the other. `setupGraphViewbox` always emits a viewBox, and that is what
scales. The overlay uses `width`/`height`, not `max-*`: `max-width` alone would leave a
small diagram at natural size — a zoom that does not zoom. Verified 95%×95% in both
layouts. `securityLevel` defaults to `strict`, which sanitises `click` directives away;
consumers with a trusted source can set `window.mermaidSecurityLevel = 'loose'` in a
preceding classic script tag.

The overlay throws loudly if `#mermaid-zoom` is missing — without it, click-to-zoom dies on
a bare `TypeError` pointing nowhere near the missing element.

## Connections-map layout

`body.conn-map` has exactly two sections in order: **(1) Links, (2) Graph**. For topic maps
the Links column is antecedents/descendants of the focus; for year-slice maps it is the drawn
items newest-first. Above 900px Links sits left and sticky, graph right; below it stacks.

**Markup order is the layout order — the stylesheet no longer reorders.** Until v1.8.0 the
markup was (1) Graph, (2) Links and the CSS reversed it with `order: 1` / `order: 2`, so the
visual leading column was Links while tab and screen-reader order started in the graph on
the right. Measured at 900 and 1280px: Links rendered at x=45 / x=64, Graph at x=305 / x=386,
against a DOM order that was the reverse. A sighted keyboard user tabbed away from where
their eye had started.

Deleting the two `order` declarations and swapping the sections in the markup produces a
pixel-identical layout — verified at 899 / 900 / 1280px, Links 220–282px sticky at the
leading edge, graph filling the rest, sticky column holding at y=120 after a 1200px scroll —
with reading order and visual order finally agreeing.

**This is a breaking change for consumers, and the break is silent.** The two files are
version-coupled: a page emitted with the old (Graph, Links) markup that inlines a v1.8.0+
stylesheet renders with the graph in the narrow sticky column and the link list filling the
page. Nothing errors; it just looks wrong. Consumers must swap their section order in the
same change that picks up the new CSS. The alternative — supporting both orders behind
`:has(> .links)` — was considered and rejected as two layout paths in a file that every
consumer inlines verbatim.

**The article sets layout only, never width.** It previously carried
`width: min(96vw, 1600px); max-width: 96vw; left: 50%; transform: translateX(-50%)`,
breaking out of the page container to be *wider* than the default layout — so a
connections map and an ordinary page never shared a left edge, and the 1600px cap silently
disagreed with the body's own cap. `pre.mermaid` broke out a second time to `90vw` via
`left: 50%; margin-left: -45vw`.

Both breakouts were **deleted rather than ported**: the container is `--page-width` (90vw)
itself, so there is nothing left to escape to, and the SVG renders at natural size, so
extra container width no longer changes the diagram at all. Verified body width, article
width and h1 left edge identical across both fixtures at eight viewports.

`overflow: visible` on `body.conn-map pre.mermaid` because the base `pre` rule sets
`overflow-x: auto`, which would otherwise clip a diagram's drop shadow.

## Direction and growth

**Sidenotes float to the inline end, with the physical value first as the fallback:**
`float: right; float: inline-end; clear: right; clear: inline-end`. Under `dir="rtl"` the
old physical-only rule kept the note on the page's right with a 24px `margin-left`, while
the `pre` and `aside` accent bars — already logical — correctly flipped. Measured after the
change: `float` computes `inline-end` in both directions, the note renders page-right in
LTR and page-left in RTL, and the 24px gap moves from `margin-left` to `margin-right`. The
duplicate physical declaration is deliberate: a browser that cannot parse `inline-end`
drops that line and keeps `right`, which is the LTR behaviour it had before. `margin` became
`margin-block: 0.2rem 1rem; margin-inline: 1.5rem 0` for the same reason.

**`th` / `td` are `text-align: start`, not `left`.** With `left` every cell stayed
left-aligned in RTL while the prose around it flipped. Verified by range-measuring the
header text inside its cell: LTR text starts 10px from the cell's left edge, RTL 10px from
its right.

**`h1`/`h2`/`h3` carry `overflow-wrap: break-word`.** They were the only text in the sheet
without a break rule (`a`, `code`, `cite`, `.sidenote` all had one), so a long title word
ran straight off the page under text-only zoom: at a 320px viewport with the root at 32px,
`h1` measured `scrollWidth 301` inside `clientWidth 262`, and the connections-map title
pushed the document to 367px. After the change the conn-map fixture reflows clean at 200%
text zoom (320px document on a 320px viewport) and still overflows only 23px at 400%.

**`--gutter` folds the safe-area insets at every width, not just under 600px:**
`max(2rem, env(safe-area-inset-left, 0px), env(safe-area-inset-right, 0px))`. A landscape
phone is 700–950px wide — above the mobile breakpoint — with lateral insets around 44–50px,
larger than the 32px gutter that used to apply there, so text ran under the notch. The
`0px` fallbacks inside `env()` are load-bearing: without them, a browser that does not
support the variable makes the whole custom property invalid at computed-value time, which
takes `width: min(100% - 2 * var(--gutter), …)` down with it. Unverified on a real device —
Chromium does not emulate the insets.

**The `.scorecard` grid still overflows under text-only zoom; `minmax(0, …)` was tried and
reverted.** At a 320–601px viewport with the root font size doubled, `max-content` tracks
plus the `.verdict` chip exceed the container and the document scrolls sideways (460px on a
320px viewport). Rewriting the tracks as `minmax(0, max-content)` lets the *track* shrink to
zero without letting the chip shrink with it: measured `174px 0px` at 320px, with the chip
spilling out of a zero-width column — a different failure, not a smaller one. `auto` tracks
and `overflow-wrap: break-word` on the children move the number by ~40px and fix 601px
only; `break-word` does not reduce a box's min-content contribution (`anywhere` does).
A media query cannot see this at all — `em` in a media query resolves against the browser's
initial font size, not the document root, so the query never fires when a reader zooms text
only. The fix is a container query, which needs a wrapper element the consumers emit. See
`backlog.md`.

## Interaction states

**The press feedback on `.nav-list li a` was inert for two reasons, both measured.** It
read `:active { transform: scale(0.96); transition: scale 0.12s ease-out }`. The
transition named the independent `scale` property while the rule set `transform`, so
nothing animated — sampled every 25ms through a real mousedown, `transform` was
`matrix(0.96, 0, 0, 0.96, 0, 0)` on the first frame and identical on all six. And the
declaration sat inside `:active`, so it vanished with the state: `transform: none` 30ms
after mouseup. Press and release both snapped.

It is now `scale: 0.96` in `:active` with the transition on the base rule alongside the
existing `text-decoration-color`. Measured 0.987 → 0.976 → 0.968 → 0.962 → 0.96 pressing
and 0.964 → 0.976 → 0.987 → 0.995 → 0.999 releasing. The lesson generalises: a transition
belongs on the resting rule, and `transform` and `scale` are different properties.

**No `border-radius` in the `:focus-visible` rule.** It carried `border-radius: 3px`,
which made `.filter-box` corners tighten 4px → 3px at the moment the ring appeared, and
applied unevenly — `.nav-list li a` (specificity 0,1,2) outranks `a:focus-visible`
(0,1,1), so nav links kept 2px while plain links took 3px in the same keyboard state.
Chromium already rounds an outline to the element's own radius plus offset, so removing it
is what makes the ring follow each surface. Verified by Tab: `a`, `summary` and
`.filter-box` all still render `solid 2px` at `2px` offset; inline links now get
square-cornered rings, which is the shape of an inline box.

**`.nav-list` radius is `calc(var(--radius-sm) + 0.3rem)`**, not `var(--radius)`. Outer
radius = inner radius + padding: the child link is `--radius-sm` (2px) inside 0.3rem
(4.8px) of padding, so 6.8px is concentric where a flat 4px left the hovered row's corners
pinched against the container's. The `calc` tracks the padding — change one and the other
follows.

**`pre.mermaid:hover` gets a 1px `--rule-light` ring.** Before it, `cursor: zoom-in` was
the *only* signal a diagram was clickable — measured `tabindex` null, `role` null, no
hover rule, no focus style. A cursor does not exist on touch and is never announced, so on
a phone the diagram was an unmarked click target. The ring is instant, not transitioned:
hover is high-frequency and does not want motion.

**The overlay's way out is a `✕` glyph on `.mermaid-overlay::after`**, top-trailing corner,
`--label` on the backdrop. Click-anywhere and Escape both dismissed it before and still do;
neither was advertised, and `cursor: zoom-out` is invisible on touch. A glyph rather than a
word because this stylesheet is inlined verbatim by consumers who cannot localise a string
in it, and `content: "✕" / ""` behind `@supports` for the same reason the outbound arrow
uses that pattern: measured through CDP `Accessibility.getFullAXTree`, zero nodes name the
glyph, so a screen reader is not told about a control it cannot reach. It is a cue on an
already-clickable surface, not a new target — the overlay dismisses on any click.

## Keyboard and assistive technology

**Zoom is a real `<button>` that `mermaid.js` injects, not a focusable `pre`.** Before it,
the only way to zoom was clicking the SVG: measured `tabindex` null on both `pre` and `svg`
with zero focusable descendants, so Tab produced 12 stops in `sample.html` and none was the
diagram (WCAG 2.1.1). Two cheaper fixes were rejected —

- `tabindex="0"` + `role="button"` on `pre.mermaid` makes the button's content
  presentational, which would hide the SVG's own `graphics-document` node and its name from
  assistive tech. The control would work and the diagram would stop existing.
- `tabindex="0"` with no role leaves a focusable generic. `aria-label` is not allowed to
  name `role=generic`, so it announces nothing and nothing hints that Enter zooms.

The injected button is a native control: keyboard and pointer for free, an accessible name
of its own, and the SVG untouched. It doubles as the touch affordance that `cursor: zoom-in`
could never be. Measured 138×42, in the tab order, focus ring from the shared
`:focus-visible` rule, `display: none` in print.

**The observer that creates it has to be idempotent.** Mermaid rewrites the `pre`'s children
after the first render, so a one-shot `if (pre.dataset.zoomable) return` guard let the second
pass delete the button and then blocked recreating it — measured: `dataset.zoomable` set,
zero buttons in the DOM. It now re-adds the button whenever one is missing and marks the
*SVG* rather than the `pre` for the click listener, so appending the button (itself a
`childList` mutation) is a no-op on the next tick instead of a loop.

**The overlay is a modal and now says so.** It measured `role` null, `aria-modal` null, no
name, no `tabindex`, `overscroll-behavior: auto`, with focus never entering and never
returning. It now carries `role="dialog"`, `aria-modal="true"`, `aria-label="Zoomed diagram"`,
`tabindex="-1"`, takes focus on open, sets `inert` on every other `body` child, and restores
focus to the button that opened it. Verified: Enter on the button gives focus inside the
overlay with both siblings `inert`, and Escape returns focus to `.mermaid-zoom` and clears
`inert`. `overscroll-behavior: contain` keeps the page underneath from scrolling.

**`accTitle` / `accDescr` in both fixture diagrams.** The SVG had a `graphics-document` role
with no accessible name at all — an unnamed graphic carrying the page's structure. These are
Mermaid directives inside the fence, so no stylesheet change can supply them; the fixtures
model them because whoever writes the fence has to.

**The sidenote margin-toggle is inert by design, and its two `display: none` rules must
stay.** `input.margin-toggle` is never focusable and the ⊕ label is hidden, so the Tufte
collapse pattern does nothing here — measured at 1280 and 390px, `.sidenote` is
`display: block` at every width, so sidenotes are always visible and there is nothing to
toggle. The rules are not dead weight though: consumer generators emit that checkbox and
label markup, and dropping the rules would show raw checkboxes on every published page. What
*was* dead is gone — `label.margin-toggle:focus-visible` could never match a `display: none`
label, and it no longer sits in the focus rule. If the pattern is ever revived it needs a
focusable control, not a hidden checkbox.

## The contrast budget covers four backgrounds

For a long time it covered two. `--rule-light`, `--muted` and `--red` were tuned against
`--surface` and `--code-bg`, and two further backgrounds existed unmeasured — both produced
by `color-mix`, which is why they went unnoticed: **a computed-value reading reports the
un-composited mix and is wrong.** Every number below was sampled from rendered pixels
through a 1×1 canvas, the same method the print `aside` finding needed.

The four surfaces text can land on are `--surface`, `--code-bg` (zebra rows, `pre`, inline
`code`, `.filter-box`), the row-hover fill, and — until v1.8.1 — the `aside` tint. A new
token has to clear its ratio against **all** of them, not the easiest one.

**The row-hover fill now darkens instead of lightening, and it is a flat token.** It was
`color-mix(in oklch, var(--rule-light) 50%, transparent)`, which composites to
`rgb(76,79,95)` over `--surface`. That lifted the row toward the accents sitting on it and
took every one of them below 4.5:1 — `--red` 2.84, `--purple` 2.91, `--muted` 3.12,
`--pink` 3.35, `--label` 3.84, `--link` 4.45, with only `--on-surface` surviving at 7.60.
Hovering a row made every coloured or linked cell in it fail 1.4.3 for as long as the
pointer rested there. It is now `background: var(--surface-alt)`: measured 5.87 (`--purple`)
to 15.35 (`--on-surface`), every accent clear. Darker-on-dark is the weaker affordance of
the two, and it is worth it — the fill is 1.15:1 against `--surface` and 1.39:1 against a
zebra row, both the same order as the zebra striping itself, which reads fine.

`--surface-alt` rather than another `color-mix`: the token already exists, it needs no
compositing to reason about, and it is the only other flat surface in the sheet.

**The hover rule is `tbody tr:hover td`, not `tr:hover td`.** At `tr:hover td` (0,1,2) it
lost to `tbody tr:nth-child(even) td` (0,1,3), so **hover never applied to a zebra row at
all** — half the rows in every table were inert and looked deliberate. Found while
verifying the fill change, not before it: the old fill's even-row ratios were computed from
the rule rather than from a real hover. Measured after the fix, all three sample rows go to
`oklch(0.243 0.019 280.395)` on hover and the striping is intact at rest.

**`aside` has no fill at all now, on screen as well as on paper.** The tint composited to
`rgb(61,64,78)`, on which `--muted` measured 3.95, `--red` 3.61, `--purple` 3.69 and
`--pink` 4.25 — so a `cite`, `.sc-note`, `.count`, `::marker` or status span inside a
callout failed while `--label`, the aside's own colour, passed at 4.87. The print block had
already found this exact defect on white (`--label` at 3.58:1) and dropped the tint there;
the screen case was the same failure one step milder and the fix was never carried back.
Deleting the declaration outright means the print override `aside { background: none }` is
redundant and is gone too — two declarations removed, one behaviour. The orange accent bar
still marks the callout, which was the print rationale and holds identically here.

**`--red` is `oklch(0.735 …)`, up from 0.700.** At 0.700 it measured 4.14:1 on `--code-bg`,
so `.correction` failed inside a zebra row, inside `pre`, and inside `.filter-box` — the
budget had checked `--muted` against that surface (4.53, passing by 0.03) and not the
accents. 0.735 gives **4.73 on `--code-bg`**, 5.72 on `--surface`, 6.57 on `--surface-alt`,
and lifts `--surface`-on-`--red` (the `.verdict-failed` and `.badge-t3` chips) from 5.00 to
5.72. 0.725 is the first value that clears 4.5 on the grey, at 4.56; 0.735 was taken for
headroom. Raising lightness moved `--red` closer to `--pink` in L (0.735 against 0.742) —
checked, ΔE_ok 0.076, about 3.8 JND on a 32° hue separation, so a `--pink` `th` and a
`--red` `.correction` in the same table stay distinct. `--red` is the one accent with no
`/* was */` note and no entry in `mermaid-palette.json`, so the change has no hex projection
to keep in step.

**`--purple` on `--code-bg` is 4.23 and was left alone.** Purple is `h2`, the `pre` accent
bar and `::selection`. The bar is non-text and clears 1.4.11 at that ratio; nothing puts
purple *text* on the grey, since an `h2` never renders inside a `pre` or a table cell. It is
mirrored into `mermaid-palette.json` twice and carries a `/* was #a98ed6 */` note, so moving
it costs a hex recomputation in two files to fix a case that does not occur. Recorded rather
than fixed.

**Borders drawn on `--code-bg` take `--rule`, not `--rule-light`.** `--rule-light` is tuned
to 3.05:1 against `--surface` — exactly the 1.4.11 floor, deliberately — and measures
**2.52** on `--code-bg`. Three components draw their only boundary there and all three
failed: `.filter-box` (border on its own `--code-bg` fill, and that border is the only thing
marking the element as an input), `.mermaid-zoom` (sits on the `pre`), and
`pre.mermaid:hover` (the ring that makes a diagram read as clickable on touch). `--rule` is
`var(--muted)`, which measures 4.53 on `--code-bg` and 5.47 on `--surface`. No new token: the
sheet already has exactly two rule weights and this is the heavier one. The side effect is
wanted — a control now reads stronger than a passive container like `details`, which keeps
`--rule-light` on `--surface` at 3.05.

**Semantic chips outline themselves in forced colors.** `@media (forced-colors: active)` now
carries `code, .verdict, .badge { border: 1px solid currentColor }`. Emulated, every
`.verdict-*` fill resolves to `rgb(255,255,255)` with `rgb(0,0,0)` text and every `.badge-t*`
to white with `rgb(0,0,159)`, so all four verdicts and all three tiers become one appearance
and the chip stops reading as a chip. The **state** survives regardless, because the chip's
own text says `PASS` / `PARTIAL` / `FAILED` / `N/A` and `Tier 1..3` — the fill is redundant
with the label, which is why a border is enough and a generated glyph would be both
unnecessary and unlocalisable. What the border restores is the boundary, not the meaning.
`box-shadow` cannot do this job: forced-colors suppresses shadows, which is why the print
block's `inset 0 0 0 1px currentColor` could not simply be reused.

Zebra striping still disappears in forced colors — `--code-bg` resolves to `Canvas`. Left
alone: the header rule and row rhythm survive, and reinstating stripes would mean per-row
borders in a mode where the user's own table rendering is the point.

**`em` carries no colour.** It was `--label`, 6.75:1 against `--surface` where the copy
around it is 13.36:1 — emphasis rendering at half the contrast of the text it emphasises.
The rule is deleted rather than reassigned, so `em` inherits, which is what makes it correct
inside an `aside`, a `blockquote` or a `.sidenote`: it now matches its surroundings instead
of overriding them with a colour those containers had already chosen. The italic carries the
emphasis, and it is a real italic from the variable font's italic face, not a synthesised
slant. `cite` stays distinguishable from `em` on family and upright stance, which is what
that distinction always rested on — the colour was never doing that work.

## Print

**The print block overrides the palette tokens, not the elements.** It used to set
`background`/`color` on `body` alone, which left every accent at its dark-theme value on a
white page. Measured on white: `.newthought` **1.05:1**, `summary` 1.82, `.verified` 1.96,
`strong` 2.09, `h3`/`em`/`blockquote`/`footer` 2.11, `h1` 2.42, `.byline`/`cite` 2.60,
`h2` 2.79. The dark fills survived too, so with background graphics on, near-black print
text sat on `--code-bg` zebra rows at **1.67:1**, and with them off (Chrome's default) the
light text that those fills had backed was stranded on white — inline `code` 1.85:1, `pre`
1.05:1.

Reassigning the tokens fixes every element at once and fixes both print paths, because the
accents become dark and the fills become near-white: whichever way the background-graphics
checkbox is set, the pair is legible. Accent lightness is chosen against the **`0.97` grey**
`--code-bg`, not white, because that is the harder of the two backgrounds — measured 4.56–4.64:1
on the grey and 4.97–5.06:1 on white, with `--on-surface` at `oklch(0.2 0 0)` giving 18.1:1.

One rule could not be handled by tokens alone:

- **`.verdict` / `.badge` print as outlined labels** — `background: none` plus
  `box-shadow: inset 0 0 0 1px currentColor` and the semantic colour moved to `color`.
  Their fill carried the meaning (pass / partial / failed), and `color: var(--surface)`
  would have become white-on-accent — fine with backgrounds on, invisible with them off.
  Outlining makes the chip identical either way, and each variant keeps its own hue at
  ≥4.97:1.

The `aside` tint used to need a second exception here: it composited to `#d9dae1` on white
and `--label` on that measured 3.58:1, the one pair the token pass left failing. The tint is
gone from the base rule as of v1.8.1 for the same reason it failed on screen, so
`aside { background: none }` no longer has anything to override. See "The contrast budget
covers four backgrounds".

`--rule-light` sits at `oklch(0.620 …)` in print: 3:1 against white for WCAG 1.4.11 without
becoming a heavy line on paper.

`--surface-alt` goes white as well. It is only the overlay backdrop, which cannot be on
screen and on paper at once, but leaving it dark would put a near-black rectangle in the
print stylesheet waiting for someone to reuse the token.

The overlay is `transition: opacity 0.2s ease-out`. With the default `ease` the backdrop
measured 0.026 → 0.497 → 0.80 → 0.94 → 0.999 at 40ms intervals — near-invisible for the
first frame, then a rush; the click felt late. Every other transition in the sheet was
already `ease-out`.

## Misc

`pre.mermaid { text-align: center }` applies to **both** layouts. It once lived on
`body.conn-map` only, so an inline diagram narrower than its column hugged the left edge in
the default layout while the same diagram sat centred in a connections map.

`.filter-box` is `font-size: 1em`, not the old `max(1em, 16pt)` — 16pt is 21.3px, not 16px;
the iOS-zoom floor is 12pt.

Print drops link chrome — no underline, no outbound marker: on paper the destination is
unreachable either way, so both are noise.

`--rule-light` is tuned to 3.05:1 against `--surface` for WCAG 1.4.11 (non-text contrast) and
is only ever drawn on that surface — see the contrast-budget section for why borders on
`--code-bg` take `--rule` instead. `--muted` sits at 4.53:1 against `--code-bg` and 5.47:1
against `--surface`; `--red` at 4.73:1 against `--code-bg` and 5.72:1 against `--surface`.
`--data-2` and `--data-3` are shifted off the `--pink` and `--green` hues so one colour means
one thing.

**`--data-1` is `oklch(0.790 0.077 255)`, moved off the link hue.** It was
`oklch(0.790 0.100 216.800)` against `--link` at 216.782 — a 0.02° collision, ΔE_ok 0.038, so
the `ext` classDef fill and the pie's first slice *were* the link colour. 255 puts it 38.2°
from `--link` and 45.9° from `--purple`, and ≥85° from every other member of the ramp, which
is the comparison that matters since those appear together in one diagram. Chroma is 0.077 =
71% of the maximum in-gamut chroma at that lightness and hue, matching the ratio the old
value held at its own hue; `--surface` text on the new fill measures 7.39:1. Verified by
rendering a pie and a `classDef` flowchart: slice fills come out
`#99bdec / #de8dc3 / #74caa6 / #bbc175`, four visibly distinct categories.

`--data-2` (9.4° off `--pink`) and `--data-3` (9.6° off `--green`) are still under the ~10°
threshold where a hue shift becomes visible — ΔE_ok 0.020 and 0.017, about one JND. They are
separated in name more than in appearance. Left alone deliberately: nothing in a diagram puts
a category fill beside body copy, so the collision costs less than `--data-1`'s did, and
moving them means recomputing two more hex projections.

**The `.scorecard` overflow under text-only zoom is fixed with a container query, not a media
query.** `section:has(> .scorecard)` becomes an inline-size container and
`@container (max-width: 15em) { .scorecard { grid-template-columns: minmax(0, 1fr) } }` stacks
it. `em` inside a container query resolves against the *container's* font size, so the query
is really "is the text large relative to the space" — which is exactly the failure condition,
and something a media query cannot see (`em` there resolves against the browser's initial font
size; a `max-width: 19em` media rule measured no change at a doubled root).

The `:has()` scoping matters: `container-type: inline-size` on every `section` also applied
inline-size containment to the conn-map columns, which changed the sticky sidebar from 276px
to 220px at 200% zoom because the content could no longer expand the flex basis. Scoped to
sections that actually hold a scorecard, the conn-map measures identically to before at all
eight widths.

The `@container` rule sits after the `max-width: 600px` block on purpose — container queries
add no specificity, so source order is what makes it win over the two-column rule there.

Fixed through 200% text zoom at every width from 320 to 2560px. At **400%** text-only zoom
the page still scrolls sideways (`.sc-note`, and the table at ≥601px); that is past what
WCAG 1.4.4 asks for and is not chased.
