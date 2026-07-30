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
Identical with `width: 100%` and `width: auto`, so this predates the v1.8.1 width change
and is not caused by it. 601px is a real viewport: small tablets and landscape phones.

**b. The sticky header is inert below 600px.** `display: block` makes the table its own
scroll container, so `top: 0` resolves against a box that never scrolls vertically. It
looks like it works because the rule is present.

**c. Neither scroll container is reachable by keyboard.** A scrollable `pre` and a
scrollable table with no focusable owner strand their overflowed content (WCAG 2.1.1). The
`pre` half of this shipped in v1.8.1 — `tabindex="0"` plus `role="region"` and a label, now
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
