# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

Not a contract artifact. Consumers inline `tufte-dracula.css` and `mermaid.js`;
nothing reads this file.

---

## 1. Outbound-link arrow has no alternative text

**Where:** `tufte-dracula.css`, `a[href^="http"]::after`

Screen readers announce "north east arrow" after every external link label.

**Change:**

```css
a[href^="http"]::after { content: "\A0↗" / ""; … }
```

The `/ ""` alt-text syntax makes the marker decorative to assistive technology.

**Why it is a decision:** browsers that do not support alt text in `content` — Firefox
ESR 128 among them — drop the *entire* declaration and lose the marker. Accessibility
win against silently losing the affordance on an old ESR still in enterprise use.

## 2. Sticky table header is inert below 600px

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

## 3. Mermaid `background` does not match the container it renders in

**Where:** `mermaid.js` / `mermaid-palette.json`, `background: '#282a36'` (`--surface`)

Diagrams render inside a `pre`, which is `--code-bg` (`#343746`), not `--surface`.
This is the same mismatch already fixed on `edgeLabelBackground`.

**Change:** point `background` at `--code-bg` (`#343746`) in both `mermaid.js` and
`mermaid-palette.json`, then run `nu maintain.nu check`.

**Why it is a decision:** mermaid's theme-base derives other colours from
`background`, and the knock-on effects were not traced. Needs a visual check across
several diagram types (flowchart, pie, ER, class) before committing, since ER and pie
in particular compute row and slice colours from it.
