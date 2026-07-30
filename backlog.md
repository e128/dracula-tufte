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
