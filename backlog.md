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
