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

---

## 3. Intrinsic-width media pushes the page sideways

**Where:** `tufte-dracula.css`, the `img` rule. It is the only element with
`max-width: 100%`.

The v1.20.0 audit measured the CommonMark and GFM construct set. It did not measure raw HTML,
which every one of those converters passes through untouched. Nothing else that carries an
intrinsic width is claimed, so each one overflows the document at a phone width. Measured on
the sheet at 390px and 1280px, `document.scrollWidth - clientWidth`:

| construct | @390 | @1280 |
| --- | --- | --- |
| `<svg width="12in">` (graphviz, plantuml) | **782** | 0 |
| `<svg width="900">` (a pre-rendered diagram) | **530** | 0 |
| `<video>`, `<canvas>`, `<object>`, `<embed>` at 800px | **430** | 0 |
| `<iframe width="560">` (an embed pasted into markdown) | **190** | 0 |
| `<img width="800">`, the control | 0 | 0 |

This is the same failure the MathML block had before v1.20.0, and it fails 1.4.10 the same
way at every width where it happens.

**The concrete change:** `:is(svg, video, canvas, iframe, object, embed) { max-width: 100% }`,
with `height: auto` where the element carries a height attribute.

**Why it is a call rather than a one-line fix.** `svg` is the collision. `pre.mermaid svg`
and `body.conn-map pre.mermaid svg` already set width and max-width with `!important`, and
below 600px the sheet deliberately lets a diagram render at natural size inside its own scroll
container. A bare `svg` rule loses to those declarations, which is the wanted outcome, but
[Mermaid](NOTES.md#diagram-sizing) records three sizing attempts that were correct on paper
and wrong on screen. Nothing ships here until both fixtures render at 390 / 768 / 1280 / 1920
with the rule in place. The cheaper split is to claim `video`, `canvas`, `iframe`, `object`
and `embed` now, and to take `svg` as its own change with its own measurement.

---

## 4. An unbreakable token in prose pushes the page sideways

**Where:** `tufte-dracula.css`. `overflow-wrap: break-word` is on `a`, `code`, `cite` and
`h1`–`h6`, and on nothing else.

A hash, a long path, a base64 fragment or a bare URL outside a code span has no break
opportunity, so the line runs past the column. Measured with a 96-character token at 390px,
`document.scrollWidth - clientWidth`:

| container | overflow |
| --- | --- |
| `li`, `dd` | **467** |
| `p` | **443** |
| `blockquote` | **431** |
| `summary` | **425** |
| `td`, `th` | 0 |
| `pre` | 0 |

`td` and `th` measure 0 because the `max-width: 1000px` escape hatch already gives a table its
own scroll axis, and `pre` has one of its own. The prose containers have neither.

**The concrete change:** add `p, li, dd, dt, blockquote, summary, figcaption, td, th` to the
`overflow-wrap: break-word` set, or set it once on `body` and let it inherit.

**Why it is a judgment call.** `overflow-wrap` on `body` is one declaration instead of nine,
and it also catches every container the list forgets. Against that, it breaks a word in the
middle wherever a line runs out, which is a typographic choice this sheet has not made
anywhere else, and [Width and measure](NOTES.md#width-and-measure) is the section that would
have to own it. `hyphens: auto` is already on `.sidenote` and `.col-2`, so the sheet does
break words in two places and could reasonably do it in prose.

---

## 5. Only the GFM alert shape is claimed. Every other generator's callout is bare

**Where:** `tufte-dracula.css`, the `aside, .markdown-alert` rule and the five
`.markdown-alert-*` variants.

v1.20.0 claimed the GitHub class names. Three other callout conventions reach the sheet from
converters a consumer is at least as likely to run, and all three measured unstyled at 1280px:
no accent bar, `--on-surface` body text at 18.4px, no title color.

| convention | emitter | measured |
| --- | --- | --- |
| `.admonition` + `.admonition-title` | Python-Markdown, MkDocs, Sphinx, docutils | no bar, no title hue |
| `.callout-note` + `.callout-header` | Quarto | no bar, no title hue |
| `.admonitionblock` | Asciidoctor | worse than bare, see below |

**Asciidoctor is the one that renders wrong rather than plain.** It emits its callout as a
`<table>` with an `.icon` cell and a `.content` cell, so the sheet's own table rules claim it:
the top and bottom hairline frame, the sticky italic `--pink` `th` treatment, and the row
hover fill. A callout drawn with table furniture.

**The concrete change:** add the selectors to the existing `aside, .markdown-alert`
declaration block, and map each convention's type suffix onto the five hues already defined.
[Form follows role](NOTES.md#form-follows-role) settled the form when GFM alerts landed, so
this adds selectors and no new treatment. Asciidoctor also needs the table rules turned off
inside `.admonitionblock`.

**Why it is a judgment call.** Each convention is a fourth, fifth and sixth name for a role
the sheet already paints twice, and every selector is per-document weight in every consumer
file. Nothing in the measured lode emits any of the three today. Against that, the whole point
of the v1.20.0 audit was that a consumer can point any converter at this sheet, and Sphinx and
MkDocs are the two most common ones outside the GitHub path.

---

## 6. Form controls fall to the UA font at 13.33px

**Where:** `tufte-dracula.css`, the `.filter-box` rule. It is the only control in the sheet
that sets `font-family: inherit`.

A `button`, `input`, `select` or `textarea` does not inherit the page font. Measured at
1280px, every one of them renders at **13.33px Arial** inside a serif page at 18.4px. That is
also below the 16px floor where iOS Safari zooms the viewport on focus. `progress`, `meter`,
`output`, `fieldset`, `legend` and `dialog` are unclaimed as well. `color-scheme: dark` saves
the colors, not the type.

**The concrete change:** `:is(button, input, select, textarea) { font: inherit }`, with a
`font-size` floor of `1rem` so the iOS zoom does not fire.

**Why it is a judgment call.** The sheet is a document theme, and a document has no form. The
one control it does style is the filter box, which the conn-map layout owns. Claiming the rest
invites the next question, which is what a focus ring, a disabled state and a hover state
should look like on a button this theme never intended to have. The honest middle is to fix
the font inheritance only, and to leave the appearance to the UA.

---

## 7. Pygments is uncovered, and the Chroma decision hid that

**Where:** `tufte-dracula.css`, the seven `:is(pre, code) :is(…)` syntax rules.

They cover `highlight.js` (`.hljs-*`), pandoc and skylighting (`.kw`, `.st`, `.co`) and Prism
(`.token.*`). Pygments names its slots `.k`, `.s`, `.c1`, `.nf`, `.mi`. Measured at 1280px,
all four inherit `--on-surface`: flat white code inside a styled `pre`.

[Markdown coverage](NOTES.md#markdown-coverage) declined Chroma on the grounds that
single-letter class names are unnamespaced in a sheet consumers inline into their own pages.
That call also excluded Pygments in silence, and the two are not equivalent:

- Hugo defaults to `noClasses = true` and writes its colors inline, so a Chroma map would
  reach almost nobody. That is most of why the decision was cheap.
- Pygments emits classes by default, and it is the highlighter behind Sphinx, MkDocs, Quarto
  and Jupyter.

**The concrete change:** add the Pygments slot names to the existing seven grouped selectors,
scoped under `:is(pre, code)` exactly the way pandoc's two-letter names already are. No new
colors and no new rules, only more selectors on the same seven declaration blocks.

**Why it is a judgment call.** The scoping is the whole argument. `:is(pre, code) .m` is far
narrower than a bare `.m`, and a consumer with a `.m` utility class inside a `<pre>` is
unlikely rather than impossible. If that risk is acceptable for `.k`, it is also acceptable
for Chroma, and this entry should either take both or record why Pygments alone is worth it.
Scoping to Pygments' own `.highlight` wrapper avoids the question entirely, at the cost of
missing any emitter that omits the wrapper.

---

## 8. Four smaller gaps, all measured

**Where:** `tufte-dracula.css`, one rule each.

- **Python-Markdown footnotes miss the caption tier.** The `.footnotes` rule matches the
  `section.footnotes` that cmark-gfm and pandoc emit. Python-Markdown emits `div.footnote`,
  singular, with a leading `<hr>`. Measured: 18.4px body copy with no hairline, and the `hr`
  taking the full `--space-10` 40px margin where the tier rule should be. Adding
  `.footnote` to the selector is one word, and suppressing the leading `hr` is one more rule.
- **`tfoot th` pins to the top of the scroll container.** `th { position: sticky; top: 0 }` is
  unscoped, so a totals row measured `position: sticky`, `top: 0`, italic `--pink`. Scope the
  rule to `thead th`. That is a correctness fix with no trade, and it only waits here because
  nothing in the repo emits a `tfoot` today.
- **Permalink anchors are always visible at heading size.** Sphinx, MkDocs and
  markdown-it-anchor emit `a.headerlink` or `a.anchor` inside the heading. Measured a 20.6px
  underlined `--link` glyph in every heading. GitHub reveals its own on hover. A
  `opacity: 0` until `:hover` and `:focus-visible` is the usual treatment, and the
  `:focus-visible` half is not optional.
- **Jupyter output is monochrome.** `.output_area` is bare and the ANSI classes
  (`.ansi-red-fg` and siblings) are unclaimed, so terminal output inside a notebook export
  loses every color. The `.dataframe` table inherits the sheet's table rules and looks
  correct. This is the largest of the four in scope and the least likely to appear.

**Why these are a judgment call.** Each is small enough to fix in one line, and none of them
has a consumer in the measured lode. They are grouped so the call is taken once rather than
four times. `tfoot` is the one that is a plain bug: take it with whatever ships next.

**Recorded 2026-08-09.** Entries 3 to 8 come from one probe run against the sheet, at 390px
and 1280px, with computed values read per element. The lower-severity findings from that run
are not recorded here: `menu` loses its marker padding to the `*` reset, `ins` and `u` are
UA-underlined and so read as links, `address` stays UA italic, and `.tabbed-set` shows every
panel at once.
