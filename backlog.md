# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

Not a contract artifact. Consumers inline `tufte-dracula.css` and `mermaid.js`;
nothing reads this file.

Five entries left here in v1.8.1: the row-hover contrast failure, the `aside` tint,
`--red` on `--code-bg`, `--rule-light` borders on `--code-bg`, the forced-colors chip
outline, the `em` colour and the `li` size. Their measurements moved to
[NOTES.md](NOTES.md) — "The contrast budget covers four backgrounds" and the type-scale
section — rather than staying here as closed items. Entry 3 below is the remaining half
of the contrast work.

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

## 2. `ul { list-style: none }` strips list semantics in Safari/VoiceOver

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

## 3. `table { width: 100% }` stretches tables past their content

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

## 4. `--red` carries three meanings

**Where:** `tufte-dracula.css`, `.badge-t3`, `.verdict-failed`, `.correction`

All three compute byte-identical `oklch(0.735 0.142 21.457)`. `NOTES.md` ("Misc") states
the principle — "`--data-2` and `--data-3` are shifted off the `--pink` and `--green`
hues so one colour means one thing" — and enforces it for a 0.02° collision between
`--data-1` and `--link`. A 0° collision across three semantics is the same defect at
full strength. Unaffected by the v1.8.1 lightness change, which moved all three together.

Sharper version of the problem: Tier 1/2/3 are **ordinal**, not health states, so
green→orange→red tells the reader tier 3 is failing.

**Change:** tiers take three steps of a single hue (or the `--data-*` ramp, which exists
and is already gamut-checked); `--red` is reserved for failure. `.correction` and
`.verdict-failed` sharing it is fine — both mean "this was wrong".

**Why it is here:** the ramp is mirrored into `mermaid-palette.json` and gated by
`.github/palette-check.py`, so reusing `--data-*` for badges couples two systems that are
currently independent. Three steps of one new hue is cleaner and costs a token. Any new
token has to clear 4.5:1 on all four backgrounds now named in `NOTES.md`, not just
`--surface`.

---

## 5. Seven components share one container treatment

**Where:** `tufte-dracula.css`, `details`, `.scorecard`, `.filter-box`, `.nav-list`,
`details.nav-group`, `.mermaid-zoom`

Counted in the rendered sample: seven elements compute a 1px solid border with a rounded
corner. Interactive containers, a data panel, a form field and a button are all the same
box, so none of them is distinguishable at a glance.

v1.8.1 split the *colour* two ways for contrast reasons — controls on `--code-bg` take
`--rule`, passive containers on `--surface` keep `--rule-light` — which incidentally gives
controls a heavier line than containers. That is a contrast fix that happens to help here;
it is not the identity change this entry is about.

The sheet already owns a stronger device: the 3px `border-inline-start` accent, used by
`pre` (purple), `aside` (orange) and `blockquote` (muted). It is the one thing in this
stylesheet that does not look like every other dark theme, and three rules use it.

**Change:** move the non-interactive panels onto the accent bar and leave the border to
things that are genuinely containers or controls. `.scorecard` is the obvious first
candidate — it is a statement of findings, not a control.

**Why it is here:** this is a visual-identity call, not a defect, and it changes the look
of every generated page. It is also the highest-leverage aesthetic change available: the
boxes are what make the output read as templated.

---

## 6. `pre.mermaid` inherits code-block chrome

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
page at that lightness before keeping it, and re-check the `:hover` ring: it is `--rule`
now, tuned for `--code-bg`, and would be sitting on `--surface` instead (5.47:1 there, so
it holds — but it stops being the value the contrast note explains).
