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

## 1. Wide tables: the page-scroll half is fixed, the keyboard half is not

**Where:** `tufte-dracula.css`, `th { position: sticky; top: 0 }`, and the
`@media (max-width: 1000px)` rule `table { display: block; overflow-x: auto; width: fit-content }`

Three problems, one shape. All measured on a six-column table, Chromium.

**a. ~~A wide table scrolls the document sideways between 601px and ~1000px.~~ Fixed in
v1.14.0** by moving the `overflow-x: auto` escape hatch to `max-width: 1000px` and giving it
`width: fit-content` so a narrow table still shrinks to its content. The trigger turned out to
be broader than a six-column table: the fixture's own three-column `table.tree` did it at 200%
text zoom and 601px, 588px against a 473px body, 51px of document scroll. Measurements in
[NOTES.md](NOTES.md) under "Tables".

**b. The sticky header is inert wherever the escape hatch applies — now up to 1000px, was
600px.** `display: block` makes the table its own scroll container, so `top: 0` resolves
against a box that never scrolls vertically. It looks like it works because the rule is
present. Widening the band widened this, deliberately: a page that scrolls sideways fails
1.4.10 at every width it happens, and a pinned header earns its keep on a long table read at
desktop width, which is above 1000px. Verified still pinning there (`th` top holds at 0 after a
60px scroll at 1280px).

**c. Neither scroll container is reachable by keyboard.** A scrollable `pre` and a
scrollable table with no focusable owner strand their overflowed content (WCAG 2.1.1). The
`pre` half of this shipped in v1.9.0 — `tabindex="0"` plus `role="region"` and a label, now
a documented consumer obligation. The table half is still open, and (a)'s fix widened the band
where it bites. Two things keep it open: the table's own `tabindex` is the wrong place for it
if a wrapper is coming, and it is not free — `tabindex="0"` on `table` adds a tab stop at
*every* width, including the ones where nothing scrolls, which is 2,093 extra stops across the
largest consumer. **`role="region"` must not go on the `<table>` itself**: it would override
`role="table"` and take the row and column semantics with it, the same defect as putting
`role="button"` on `pre.mermaid`. It belongs on a wrapper or nowhere.

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

**Half of the cheap alternative has now been taken.** Extending the `overflow-x: auto` rule
above 600px was the cheap fix for (a), and v1.14.0 took it — at 1000px rather than at every
width, so the pinned header survives where it matters instead of being given up for good. What
remains of the cheap path is (c) by `tabindex="0"` on the table itself, and the tab-stop cost
above is the reason it has not been taken with it.

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

**Updated 2026-08-04.** (a) is closed in v1.14.0 without the wrapper — the condition above
turned out to be reachable without anyone changing how they read, since 200% text zoom hits it
at 601px on a three-column table. The wrapper is still the only thing that fixes (b) and (c)
together, and it is still consumer markup this repo cannot ship alone, so what is left of this
entry stays deferred on the same terms.

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
