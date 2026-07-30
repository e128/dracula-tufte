# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

Not a contract artifact. Consumers inline `tufte-dracula.css` and `mermaid.js`;
nothing reads this file.

---

## 1. Font refinement — ongoing

The stack is `Georgia, "Noto Serif", "DejaVu Serif", serif`, chosen for platform reach.
Three weight fixes shipped together in v1.6.0 — a relative `clamp()` with a 17px floor,
removal of `-webkit-font-smoothing: antialiased`, and the move off Palatino. This item
stays open because that was the coarse pass; what follows is the finer work, none of it
done, plus the one consequence the stack choice deliberately accepted.

### Georgia's old-style figures wobble in data tables

**Where:** `tufte-dracula.css`, `td { font-variant-numeric: tabular-nums }`

Georgia's default figures are old-style: they carry ascenders and descenders, vary in
height, and are proportionally spaced. In a column of numbers that reads as uneven and
the digits do not align vertically.

`font-variant-numeric: tabular-nums` cannot fix it. Feature tags found in the font
binaries on macOS:

| font | `onum` | `lnum` | `tnum` | `pnum` |
| --- | --- | --- | --- | --- |
| `Georgia.ttf` | — | — | — | — |
| `Charter.ttc` | — | — | — | — |
| `Palatino.ttc` | — | — | — | — |

With no `lnum` or `tnum` exposed, Georgia cannot be asked for lining or tabular figures,
so the declaration on `td` is inert. It is kept as documentation of intent, not because
it does anything.

Method caveat: that table is a byte-level search for the four-character feature tags in
the font files, not a parsed GSUB table (no `fontTools` on the machine that ran it).
Strong evidence, not proof — reconfirm before acting on it.

**Candidate fix:** give tables the monospace stack already used by `code` and `cite`,
which has lining, fixed-width figures by construction:

```css
table { font-family: ui-monospace, 'JetBrains Mono', 'Fira Code', monospace; }
```

**Why it is a decision:** it makes every table read as data rather than prose. For a
technical reference that is arguably an improvement and it is consistent with `cite` and
`code` already being monospace — but it is a visible change to every table in every
consumer, and monospace runs wider, so column-heavy tables will need more horizontal
room. A narrower variant would target only numeric cells, which needs markup this
stylesheet does not have.

### Values tuned for Palatino that Georgia inherited unchanged

Each of these was set against Palatino's proportions and has not been re-derived. Georgia
has a larger x-height, wider advances and different descenders, so all four are now
guesses rather than measurements:

| Where | Value | Why it may be wrong for Georgia |
| --- | --- | --- |
| `code`, `cite` | `font-size: 0.85em` | Compensates for the monospace x-height exceeding the serif's. Georgia's x-height is larger, so the gap narrowed and this may over-correct — code could read small against the body |
| `body` | `clamp(1.0625rem, …, 1.375rem)` | Georgia looks bigger than Palatino at the same `font-size`. The 17px floor was chosen for Palatino and may now be one step too large |
| `h1` | `letter-spacing: -0.02em` | Negative tracking tuned to Palatino's tighter fit; Georgia is wider and may want less, or none |
| `a` | `text-underline-offset: 0.15em` | Clearance was set against Palatino's descenders |

Also unmeasured: the `70ch` measure cap below 1200px is now sized by Georgia's `0`
advance rather than Palatino's, so the effective characters-per-line changed. Worth
re-measuring rather than assuming the band still holds.

### The long-term answer: a variable webfont

Every weight problem in this theme traces back to one root cause — system serifs ship
400/700 and nothing between, so there is no way to ask for the 450–500 that light-on-dark
body copy actually wants. A self-hosted variable serif (Source Serif 4, Literata,
Newsreader) would resolve it outright: a continuous weight axis, true small caps for
`.newthought` instead of synthesised ones, both lining and old-style figures so tables
and prose can each have the right ones, and identical rendering on every platform
instead of three different faces.

**Why it is not done:** it breaks the property that makes this repo work — consumers
inline two files verbatim with no build step, and the output is local knowledge-base HTML
that must render offline. A webfont needs either a CDN URL (fails offline, and the
diagrams already have this problem via the mermaid CDN) or base64 in the stylesheet
(bloats every generated file by hundreds of KB). Revisit if the no-build constraint ever
relaxes, or if a subset small enough to inline proves acceptable.

### Rejected alternatives for the font stack

- **Charter first** — sturdier than Georgia at the same size, but macOS-only, so it
  left Linux, Android and ChromeOS on the generic `serif`. Dropped from the stack
  entirely rather than kept as a fallback: it only exists where Georgia also does.
- **`ui-serif` first** — resolves to New York on macOS, which is excellent for aging
  eyes, but only Safari supports the keyword. Chrome and Firefox on the same machine
  would fall through to a different face. Unpredictable cross-browser rendering is
  worse than a slightly lighter font.
- **Self-hosted webfont** — identical everywhere, but breaks the no-build,
  self-contained property, and consumers render local knowledge-base files where a
  CDN font fails offline.

## 2. Six of the nine italic rules

**Where:** `tufte-dracula.css` — `h2`, `h3`, `th`, `summary`, `blockquote`, `.byline`,
`details.nav-group > summary`, `.filter-box::placeholder`, `.filter-empty`

Georgia Italic at weight 400 is the lightest face in the theme, and it currently carries
two heading levels plus every table header.

**Change:** drop `font-style: italic` from `h3` and `th`, keeping it on `h2` and
`blockquote`. Both already have colour (`--label`, `--pink`) and size doing the work
of distinguishing them.

**Why it is a decision:** italic headings and table headers are a deliberate Tufte
convention, not an accident. This trades that convention for stroke weight.

## 3. Mermaid `fontFamily` and `fontSize` are unset

**Where:** `mermaid.js`, `themeVariables`

Neither key is set, so every diagram renders in mermaid's default
`"trebuchet ms", verdana, arial, sans-serif` at a hard-coded 16px. The 16px ignores
the reader's browser font-size preference — the same defect as the `max(Xem, 12pt)`
floors that were removed from the stylesheet.

**Change:** add to `themeVariables`:

```js
fontFamily: 'ui-monospace, "JetBrains Mono", "Fira Code", monospace',
fontSize:   '1rem',
```

`fontSize` accepts a CSS length string, so `1rem` tracks the root size.

**Why it is a decision:** diagrams currently read as a distinct register from the
prose, which is arguably correct for technical figures. Tying them to the theme is a
taste call. Note `mermaid-palette.json` covers colours only — these two keys would be
the first non-colour `themeVariables` entries, so decide whether the palette gate
should track them.

## 4. Outbound-link arrow has no alternative text

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

## 5. Sticky table header is inert below 600px

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

## 6. Mermaid `background` does not match the container it renders in

**Where:** `mermaid.js` / `mermaid-palette.json`, `background: '#282a36'` (`--surface`)

Diagrams render inside a `pre`, which is `--code-bg` (`#343746`), not `--surface`.
This is the same mismatch already fixed on `edgeLabelBackground`.

**Change:** point `background` at `--code-bg` (`#343746`) in both `mermaid.js` and
`mermaid-palette.json`, then run `nu maintain.nu check`.

**Why it is a decision:** mermaid's theme-base derives other colours from
`background`, and the knock-on effects were not traced. Needs a visual check across
several diagram types (flowchart, pie, ER, class) before committing, since ER and pie
in particular compute row and slice colours from it.

---

## Verification debt

Everything applied in the v1.6.0 working tree was reasoned from source and computed
values — **no diagram or page was actually rendered**. Two changes in particular are
worth confirming in a browser before tagging:

- **Click-to-zoom parity** (`mermaid.js`). Derived from `calculateSvgSizeAttrs` in the
  pinned mermaid 11.16.0 build, which writes an inline `style="max-width:NNNpx"` when
  `flowchart.useMaxWidth` is true and `width`/`height` attributes when false. Click a
  diagram in `sample.html` *and* in `sample-conn-map.html` and confirm both fill ~95%
  of the viewport.
- **`.newthought` at `font-weight: 600`**, which resolves to real bold (700) — every
  family in the stack ships 400/700 only. Confirm the section opener does not read as
  shouting; drop the `font-weight` if it does.
- **The Georgia-first font stack itself.** Body copy no longer renders in Palatino: a
  shift in the theme's voice, not just stroke weight. Georgia also has a notably larger
  x-height, so it looks bigger than Palatino at the same `font-size`, and it is wider, so
  a line holds fewer characters. It is the third of three compounding weight changes
  (with the size floor and the removal of `-webkit-font-smoothing: antialiased`), so this
  is the point to check whether the text has overshot from too thin to too heavy — and
  whether the `clamp()` floor wants trimming back toward `1rem` now that the face itself
  reads larger.
