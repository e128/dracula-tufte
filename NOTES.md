# NOTES.md — why the stylesheet looks like this

`tufte-dracula.css` and `mermaid.js` are inlined verbatim into every generated HTML file,
so they carry no comments (see `CLAUDE.md`). This file holds the reasoning that used to
live in them. Every number below was measured in Chromium, not reasoned about.

**Two comments remain in the CSS, and both are machine-read data rather than prose:**

- **Line 2, the version** (`/* Dracula-Tufte (muted) v1.6.1 */`). `build-sample.nu` reads
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
1em     body copy, .filter-box
0.95em  structural: li, table, aside, nav, .scorecard, .nav-list li
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
Same guard as `li li`.

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

`body.conn-map` has exactly two sections in order: (1) Graph, (2) Links. For topic maps the
Links column is antecedents/descendants of the focus; for year-slice maps it is the drawn
items newest-first. Above 900px Links floats left and sticky, graph right; below it stacks.

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

## Misc

`pre.mermaid { text-align: center }` applies to **both** layouts. It once lived on
`body.conn-map` only, so an inline diagram narrower than its column hugged the left edge in
the default layout while the same diagram sat centred in a connections map.

`.filter-box` is `font-size: 1em`, not the old `max(1em, 16pt)` — 16pt is 21.3px, not 16px;
the iOS-zoom floor is 12pt.

Print drops link chrome — no underline, no outbound marker: on paper the destination is
unreachable either way, so both are noise.

`--rule-light` is tuned to 3.05:1 against `--surface` for WCAG 1.4.11 (non-text contrast);
`--muted` to 4.55:1 against `--code-bg` and 5.50:1 against `--surface`; `--red` to 5.00:1
against `--surface`. `--data-2` and `--data-3` are shifted off the `--pink` and `--green`
hues so one colour means one thing.
