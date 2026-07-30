# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

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

---

## 2. The zoom overlay has no visible way out

**Where:** `tufte-dracula.css`, `.mermaid-overlay`; `mermaid.js`, the `dismiss` handler

Click anywhere and Escape both close it, and both work. Neither is advertised: the only cue
is `cursor: zoom-out`, which touch users never see. `pre.mermaid:hover` now marks the
diagram as interactive on the way in, but nothing marks the way out.

**Change:** a dismiss affordance on the overlay — a `::after` hint, or a real close button
added in `mermaid.js`.

**Why it is deferred:** a `::after` puts user-facing English into a stylesheet that every
consumer inlines verbatim, with no way to localise or suppress it; a close button is markup
plus a hit area plus a focus order, which is a `better-accessibility` decision about the
whole overlay (it is not keyboard-reachable to begin with — `pre.mermaid` has no
`tabindex`). Both are bigger than the polish fix that prompted this entry.

---

## 3. `.scorecard` scrolls sideways under text-only zoom

**Where:** `tufte-dracula.css`, `.scorecard { grid-template-columns: max-content max-content 1fr }`
and its `max-content 1fr` form under 600px

At a 320–601px viewport with the reader's root font size doubled (Firefox's text-only zoom,
or a 32px browser default), the `max-content` label track plus the nowrap `.verdict` chip
exceed the container: measured document `scrollWidth` 460 against a 320px viewport, chip
edge 140px off-screen. Default text size is clean at every width from 320 to 2560px.

**Change:** stack the grid to one column when the text is large relative to the container —
a container query on a wrapper:

```html
<div class="scorecard-wrap"><div class="scorecard">…</div></div>
```

```css
.scorecard-wrap { container-type: inline-size; }
@container (max-width: 22em) { .scorecard { grid-template-columns: minmax(0, 1fr); } }
```

**Why it is deferred:** it needs the wrapper element, so like entry 1 it is an HTML change
in every consumer's renderer, not a stylesheet change. A media query cannot substitute —
`em` in a media query resolves against the browser's initial font size, not the document
root, so it never fires on text-only zoom (measured: a `max-width: 19em` rule changed
nothing at a doubled root). Track-level fixes were tried and rejected; `NOTES.md` records
what each one measured.
