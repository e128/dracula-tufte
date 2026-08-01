# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

Not a contract artifact. Consumers inline `tufte-dracula.css` and `mermaid.js`;
nothing reads this file.

A closed entry leaves this file rather than accumulating in it. Its measurements and
rejected alternatives go to [NOTES.md](NOTES.md), which is where a future agent looks;
the narrative goes in the commit.

---

## 1. Wide tables need one decision that covers three failures

**Where:** `tufte-dracula.css`, `table`, `th { position: sticky; top: 0 }`, and the
`@media (max-width: 600px)` rule `table { display: block; overflow-x: auto }`

Three problems, one shape. All measured on a six-column table, Chromium.

**a. A wide table scrolls the document sideways between 601px and ~1000px.** Its
min-content width exceeds the body — 731px against a 537px body at 601px, 746 against 691
at 768 — and the `overflow-x: auto` escape hatch only exists below 600px. WCAG 1.4.10.
Identical with `width: 100%` and `width: auto`, so this predates the v1.9.0 width change
and is not caused by it. 601px is a real viewport: small tablets and landscape phones.

**b. The sticky header is inert below 600px.** `display: block` makes the table its own
scroll container, so `top: 0` resolves against a box that never scrolls vertically. It
looks like it works because the rule is present.

**c. Neither scroll container is reachable by keyboard.** A scrollable `pre` and a
scrollable table with no focusable owner strand their overflowed content (WCAG 2.1.1). The
`pre` half of this shipped in v1.9.0 — `tabindex="0"` plus `role="region"` and a label, now
a documented consumer obligation. The table half is still open because the table's own
`tabindex` is the wrong place for it if a wrapper is coming.

**The wrapper this entry used to propose does not fix (b).** Measured: a
`div` with `overflow-x: auto` around the table computes `overflow-y: auto` as well — one
axis auto forces the other off `visible` — so the wrapper becomes the scrollport and the
header still scrolls away. Probed at 390px on a 43-row table, `th` top went to **-600 after
a 600px page scroll, identical to no wrapper at all**, against a control at 1280px where it
pins at 0. Recorded so the obvious fix is not tried a third time.

**What does work, measured:** a wrapper that scrolls *both* axes and caps its height.
`.table-scroll { overflow: auto; max-height: 70vh }` with `.table-scroll > table
{ display: table }` pins the header — `th` top holds at **0 relative to the wrapper** after
scrolling 400px inside it — and, applied at every width rather than only below 600px, it
also fixes (a). Add `tabindex="0"` and it fixes (c).

```html
<div class="table-scroll" tabindex="0" role="region" aria-label="…"><table>…</table></div>
```

```css
.table-scroll { overflow: auto; max-height: 70vh; }
.table-scroll > table { display: table; }
```

**Why it is deferred, and what the call actually is:**

- It is consumer markup in every renderer, like the other obligations in `README.md` — it
  cannot ship from this repo alone.
- It trades a page-level scroll for a **nested scroll region on every table**, with a
  viewport-relative height cap. That is a real UX cost on a phone, and `70vh` is a guess
  that wants testing against real content, not a fixture.
- Shipping the CSS without the markup is safe (the class matches nothing), but moving
  `overflow-x: auto` off `table` at the same time would silently break any consumer that
  has not wrapped yet — wide tables would overflow the page with no scroller. Either keep
  both paths for a release, or coordinate the bump.

The cheap alternative is to accept (b), fix (a) by extending the existing `overflow-x: auto`
rule above 600px, and fix (c) with `tabindex="0"` on the table itself. That is CSS plus one
attribute, no wrapper, no nested scroll region — and it gives up the pinned header for good.

**How much this actually affects, measured 2026-08-01** against the 370-file
`product-intelligence` lode, the largest consumer. Tables are the dominant component by a
wide margin: **2,093 of them, a mean of 5.7 per document**, against zero uses of
`sidenote`, `marginnote`, `newthought`, `scorecard`, `edge-list` or `col-2`. Column-count
histogram, by table: 2 cols 530, 3 cols 909, 4 cols 425, 5 cols 143, 6 cols 53, 7 cols 23,
8 cols 5, and one each at 9, 10 and 13.

So **227 tables carry five or more columns, spread across 118 documents — 32% of the
corpus.** Eleven of those are also longer than 20 rows, where the inert sticky header
starts to matter on its own rather than as a nicety; the worst is a 10-column, 23-row
table. That is the scope of (a) and (c). It is not a fixture-only problem.

**Deferred 2026-08-01, deliberately.** The trade is understood and the cost is real: a
nested scroll region on every wide table, with a `70vh` cap nobody has tested against real
content on a phone. Nothing regresses by waiting, and the 118 documents keep behaviour they
already have. Revisit when someone actually reads the lode below 1000px, which is the
condition that makes (a) bite.

---

## 2. Nine class families have no user in the largest consumer

**Where:** `tufte-dracula.css` — `.scorecard`, `.edge-list`, `.col-2`, `.badge`,
`.newthought`, `.sidenote`, `.marginnote`, `.verdict*`, and the whole `body.conn-map`
layout with `.nav-list` / `.filter-box` / `.filter-label` / `.filter-empty`.

Measured 2026-08-01 across the 370-file `product-intelligence` lode, by class attribute:

| Class family | Documents using it |
|---|---|
| `scorecard`, `edge-list`, `col-2`, `badge`, `newthought`, `sidenote`, `marginnote` | **0** |
| `nav-list`, `filter-box`, `filter-label`, `filter-empty`, `body.conn-map` | **0** |
| `verdict`, `verdict-pass` and siblings | **1** |
| `verified` / `unverified` / `correction` | heavy, keep |

Every lode file inlines the stylesheet whole, so this is per-document weight in 370 files,
not one shared asset.

**Read the zero honestly, because it measures two different things.** `lode-skeleton.sh`
emits none of these classes, so a generator that never offers a component guarantees no
document uses it — that is a consumer gap, not a dead pattern. `sidenote` and `marginnote`
are the clearest case: they are the Tufte signature, the reason the layout reserves a right
margin at all, and a lode file has plenty of asides that want to be one. The same argument
does **not** rescue `conn-map`: that is a whole second layout mode with its own fixture, and
nothing has ever rendered in it.

**The concrete change, if this is ever taken:** split the list rather than deleting it
whole. Retire what has no plausible consumer, and *wire* what does — teach
`lode-skeleton.sh --docs` about `sidenote` so the pattern gets reachable before it gets
judged. Deleting `sidenote` because the generator never offered it would be measuring the
generator and blaming the stylesheet.

**Why it is a judgment call.** The bytes cost nothing to maintain, and `maintain.nu check`
does not care. Against that, every unused rule is surface a future agent has to read past in
a 262-line file, and `sample.html` demos components no document contains, so the fixture
oversells what the theme is actually used for. Removing `conn-map` also destroys the only
worked example of the two-section sticky layout, which is expensive to reconstruct.

**Deferred 2026-08-01:** audit recorded, nothing removed.
