# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

**Entries 2–6 are measured defects, not judgment calls.** They sit here because each
needs a decision about *which* fix, or because the fix is consumer markup this repo
cannot ship alone — not because the failure is in doubt. Every number in them was
measured in Chromium, sampling composited pixels rather than computed values.

Not a contract artifact. Consumers inline `tufte-dracula.css` and `mermaid.js`;
nothing reads this file.

---

## 1. Sticky table header is inert below 600px

**Where:** `tufte-dracula.css`, `th { position: sticky; top: 0 }` and the
`@media (max-width: 600px)` rule `table { display: block; overflow-x: auto }`

Making the table its own scroll container means `top: 0` resolves against a box that
never scrolls vertically, so the header does not stick on small screens. It looks
like it works because the rule is present.

**Change:** wrap tables in a scroll container and let the table stay a table:

```html
<div class="table-scroll"><table>…</table></div>
```

```css
@media (max-width: 600px) { .table-scroll { overflow-x: auto; } }
```

**Why it is deferred:** this is an HTML change in every consumer's renderer, not a
stylesheet change — it cannot ship from this repo alone. Either coordinate the wrapper
across consumers, or accept that mobile tables scroll without a pinned header.

**Bundle the keyboard fix into the same change.** `pre { overflow-x: auto }` and the
mobile `table { display: block; overflow-x: auto }` both create horizontal scroll
containers with no focusable owner, so a keyboard user cannot reach the overflowed
content (WCAG 2.1.1). The wrapper this entry already proposes is the place to put
`tabindex="0"`, and `pre` needs the same treatment. One coordinated markup change
covers the sticky header and both scrollers; doing them separately means asking
consumers to edit their renderer twice.

---

## 2. The contrast budget covers two backgrounds; the sheet has four

**Where:** `tufte-dracula.css`, `tr:hover td` and `aside`, against the token budget
recorded in `NOTES.md` ("Misc")

`NOTES.md` tunes `--rule-light`, `--muted` and `--red` against `--surface` and
`--code-bg`. Two more backgrounds exist and were never measured, both produced by
`color-mix`, so a computed-value reading reports the un-composited mix and is wrong.
Sampled from rendered pixels:

`tr:hover td` — `color-mix(in oklch, var(--rule-light) 50%, transparent)` composites to
`rgb(76,79,95)` over `--surface` and `rgb(82,85,103)` over a zebra row. Hovering a row
drops every accent below 4.5:1:

| token | on hover-odd | on hover-even |
| --- | --- | --- |
| `--red` | 2.84 | 2.58 |
| `--purple` | 2.91 | 2.64 |
| `--muted` | 3.12 | 2.83 |
| `--pink` | 3.35 | 3.04 |
| `--label` | 3.84 | 3.49 |
| `--link` | 4.45 | 4.04 |

`--on-surface` survives at 7.60 / 6.90, so plain cells are fine and every coloured or
linked cell fails 1.4.3 for as long as the pointer rests on it.

`aside` — `color-mix(in oklch, var(--rule-light) 30%, transparent)` composites to
`rgb(61,64,78)`. On it: `--muted` 3.95, `--red` 3.61, `--purple` 3.69, `--pink` 4.25.
`--label`, the aside's own colour, passes at 4.87. So a `cite`, `.sc-note`, `.count`,
`::marker` or status span inside a callout fails. `NOTES.md` ("Print") measured this
same composite on white, found `--label` at 3.58:1 and dropped the tint for print; the
screen case is the identical defect one step milder and was not carried back.

Third background, no `color-mix` involved: `--red` on `--code-bg` is **4.14** and
`--purple` **4.23**, so `.correction` in a zebra row, inside `pre`, or inside
`.filter-box` fails. `--muted` was checked there (4.53, passing by 0.03); the accents
were not.

**Change:** hover should darken rather than lighten — `color-mix` toward
`--surface-alt` keeps every accent above its current ratio instead of collapsing them —
or mark the hovered row with an inline-start accent and no fill at all. For `aside`,
either drop the tint on screen the way print does, or raise it to a lightness where
`--muted` clears 4.5.

**Why it is here rather than fixed:** the direction is a design call. A darker hover on
a dark theme is a weaker affordance than a lighter one, and the accent-bar alternative
changes what a hovered row looks like rather than adjusting it. Pick one, then extend
the `NOTES.md` budget to name all four backgrounds so the next token lands against the
worst of them, not the easiest.

---

## 3. `--rule-light` borders fail 1.4.11 wherever they sit on `--code-bg`

**Where:** `tufte-dracula.css`, `.filter-box`, `.mermaid-zoom`, `pre.mermaid:hover`

`--rule-light` is tuned to 3.05:1 against `--surface` — deliberate, and exactly the
1.4.11 floor. On `--code-bg` the same token measures **2.52**, and inside an `aside`
**2.20**. Three components draw their only boundary there:

- `.filter-box` — 1px `--rule-light` on its own `--code-bg` fill. The border is the
  only thing that marks the element as an input.
- `.mermaid-zoom` — sits on the `pre`, so its border is on `--code-bg`.
- `pre.mermaid:hover` — the 1px ring added so a diagram reads as clickable on touch.

The token is not wrong; its placement is. It has one measured ratio and two surfaces.

**Change:** borders drawn on `--code-bg` take `--muted` (4.53 there) instead, or a
second token exists for the darker fill. Alternatively `pre.mermaid` loses its
`--code-bg` background entirely — see entry 10 — which removes two of the three cases.

**Why it is here:** adding a token to a file every consumer inlines is not free, and
the one-token-two-surfaces problem may be better solved by removing a surface than by
adding a colour.

---

## 4. Semantic chips and status spans carry meaning in colour alone

**Where:** `tufte-dracula.css`, `.verdict-*`, `.badge-t*`, `.verified` / `.unverified`
/ `.correction`, and the `@media (forced-colors: active)` block

Emulating `forced-colors: active` (Windows High Contrast and equivalents), measured:

- `.verdict-pass` / `-partial` / `-failed` / `-neutral` all compute
  `rgb(255,255,255)` fill with `rgb(0,0,0)` text. Four states, one appearance.
- `.badge-t1` / `-t2` / `-t3` all compute white fill with `rgb(0,0,159)` text.
- `.verified` / `.unverified` / `.correction` all compute `rgb(0,0,0)`.
- Zebra rows go white; the striping disappears.

The forced-colors block currently handles `code` and nothing else. Every scorecard
verdict and every audit tier becomes unreadable as a state — the control still renders,
it just stops meaning anything.

The same encoding is thin without forced colors. `--green` is L 0.775, `--orange`
L 0.773, `--red` L 0.700: green/orange/red is the worst triple for deuteranopia, and
three near-identical lightnesses remove the greyscale fallback. WCAG 1.4.1.

**Change:** the print block at the end of the sheet already solves this —
`background: none` plus `inset 0 0 0 1px currentColor` with the hue moved to `color`.
Forced-colors needs the same idea with a **`border`, not a `box-shadow`**: forced-colors
suppresses shadows. That covers the chips. The status spans need a second channel that
survives both filters — a `::before` glyph, or three lightnesses far enough apart to
read in greyscale.

**Why it is here:** a glyph in `::before` is content, and this stylesheet is inlined
verbatim by consumers who cannot localise a string in it — the same constraint that made
the overlay's dismiss cue a `✕` rather than a word (`NOTES.md`, "Interaction states").
A geometric mark is fine; a letter or abbreviation is not. Decide the mark before
writing the rule.

---

## 5. `ul { list-style: none }` strips list semantics in Safari/VoiceOver

**Where:** `tufte-dracula.css`, `ul` and `.nav-list`

Known WebKit behaviour: a list with `list-style: none` stops being announced as a list,
so VoiceOver no longer says "list, N items" or gives item position. It applies globally
here, and again on `.nav-list` — which is the navigation structure of every index page.

Side effect worth knowing while this is open: `li::marker { color: var(--muted) }` is
inert for every `ul`, because there is no marker box to colour. It still works for `ol`.

**Change:** `role="list"` on the affected lists.

**Why it is deferred:** same shape as entry 1 — an attribute in every consumer's
renderer, not a stylesheet change. Either coordinate it, or state it in `README.md` as a
consumer requirement so a page that wants the nav list announced knows what to emit.

---

## 6. `table { width: 100% }` stretches tables past their content

**Where:** `tufte-dracula.css`, `table`

Measured at 1280px on the sample's three-column table: renders **1152px** against
**315px** of natural content width, a 3.7× stretch, with zebra stripes running the whole
way. Below 600px the sheet disagrees with itself — `display: block` lets the table shrink
to content, so the same stripes stop mid-row there.

`NOTES.md` ("Tables") is about the font stack and the ~27% width cost of the monospace
experiment; `width: 100%` itself has not been examined.

**Change:** `width: auto; max-width: 100%`.

**Why it is here and not just done:** this is the one entry that touches the width
question, and width decisions in this repo have a history of being right on paper and
wrong on screen (`NOTES.md`, "Width and measure" — three recorded failures). A table that
sizes to its data is correct for a 3-column table and may read as under-filled next to
full-width prose. Verify at 390 / 768 / 1280 / 1920 / 2560 on both a narrow and a wide
table before keeping it.

---

## 7. `em` reads dimmer than the copy it emphasizes

**Where:** `tufte-dracula.css`, `em { color: var(--label) }`

`--label` measures 6.75:1 against `--surface`; the body copy around it is 13.36:1. So
emphasised text renders at roughly half the contrast of the unemphasised text it is
meant to stand out from.

**Change:** `em` keeps `--on-surface` and lets the italic carry the emphasis. The
webfont's italic is a real italic, not a synthesised slant (`NOTES.md`, "Fonts"), so it
carries on its own.

**Why it is here:** `--label` on `em` is load-bearing for one thing — it is what keeps
`em` distinguishable from `cite`, which is monospace and upright for exactly that reason
(`NOTES.md`, "Links"). Dropping the colour is probably still right, since the two now
differ in family, but check a page that uses both before committing.

---

## 8. `--red` carries three meanings

**Where:** `tufte-dracula.css`, `.badge-t3`, `.verdict-failed`, `.correction`

All three compute byte-identical `oklch(0.7 0.142 21.457)`. `NOTES.md` ("Misc") states
the principle — "`--data-2` and `--data-3` are shifted off the `--pink` and `--green`
hues so one colour means one thing" — and enforces it for a 0.02° collision between
`--data-1` and `--link`. A 0° collision across three semantics is the same defect at
full strength.

Sharper version of the problem: Tier 1/2/3 are **ordinal**, not health states, so
green→orange→red tells the reader tier 3 is failing.

**Change:** tiers take three steps of a single hue (or the `--data-*` ramp, which exists
and is already gamut-checked); `--red` is reserved for failure. `.correction` and
`.verdict-failed` sharing it is fine — both mean "this was wrong".

**Why it is here:** the ramp is mirrored into `mermaid-palette.json` and gated by
`.github/palette-check.py`, so reusing `--data-*` for badges couples two systems that are
currently independent. Three steps of one new hue is cleaner and costs a token.

---

## 9. Eight components share one container treatment

**Where:** `tufte-dracula.css`, `details`, `.scorecard`, `.filter-box`, `.nav-list`,
`details.nav-group`, `.mermaid-zoom`

Counted in the rendered sample: eight elements compute 1px `solid --rule-light` with a
rounded corner. Interactive containers, a data panel, a form field and a button are all
the same box, so none of them is distinguishable at a glance.

The sheet already owns a stronger device: the 3px `border-inline-start` accent, used by
`pre` (purple), `aside` (orange) and `blockquote` (muted). It is the one thing in this
stylesheet that does not look like every other dark theme, and three rules use it.

**Change:** move the non-interactive panels onto the accent bar and leave the border to
things that are genuinely containers or controls. `.scorecard` is the obvious first
candidate — it is a statement of findings, not a control — and moving it also removes one
of the 1.4.11 cases in entry 3, since an accent bar needs no border.

**Why it is here:** this is a visual-identity call, not a defect, and it changes the look
of every generated page. It is also the highest-leverage aesthetic change available: the
boxes are what make the output read as templated.

---

## 10. `pre.mermaid` inherits code-block chrome

**Where:** `tufte-dracula.css`, `pre` and `pre.mermaid`

A diagram inherits `--code-bg` and the 3px purple accent bar from `pre`, so it is framed
as source code. On a connections map the slab is the dominant graphic on the page, mostly
empty around a small graph — the SVG renders at natural size by design (`NOTES.md`,
"Mermaid").

**Change:** `pre.mermaid { background: none; border-inline-start: none }`.

**Why it is here:** the `--code-bg` fill is not purely decorative — `NOTES.md`
("Mermaid") records that mermaid's own `background` themeVariable never reaches the
output and the `pre`'s background is what shows through, so removing it puts diagrams
directly on `--surface`. Check that node fills and edge strokes still separate from the
page at that lightness before keeping it. The hover ring and the injected zoom button
already carry the click affordance, so nothing is lost there.

---

## 11. `li` at 0.95em shrinks prose lists

**Where:** `tufte-dracula.css`, `li`

Measured 17.48px against 18.4px paragraphs at 1280. `NOTES.md` ("Type scale") files `li`
in the 0.95em "structural" tier with tables, `aside`, `nav` and `.scorecard`. That is
right for a nav list and wrong for a bulleted list inside an `<article>`, which is body
copy and reads as subordinate to the paragraphs around it for no semantic reason.

**Change:** scope 0.95em to the nav and table contexts, leave prose `li` at 1em.

**Why it is here:** the scale compounds, and `li` is a parent in several places —
`.nav-list li` and `li li` both depend on it, and `NOTES.md` warns to check the parent
before adding a step. Cheap change, needs the nested cases re-measured.
