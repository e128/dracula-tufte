# Design audit: 2026-09-08

Research window: `7e67221..edb9cb6`, six commits, since the previous audit
(`review/2026-09-07-design-audit.md`) read the tree at v1.44.0 on 2026-09-07. This run reads the
tree at v1.45.1. `review/declined.md` holds no rows, so no finding is filtered by a prior decline.

**This run changed the skill that produced it.** The commit-range window above, the delta audit
that found everything actionable here, the mandatory probe render, and the ungated-rules sweep were
all added to `.claude/skills/design-audit/SKILL.md` after this run's findings showed the gaps. The
report is written against the new steps.

Out of scope for this skill, per the topic map: Editor themes, Filter, Unclaimed elements, Markdown
coverage, Raw HTML and other generators, Fixtures are coverage, Repo layout, Odds and ends. Their
absence here is a scope decision, not an oversight.

**The window is one day long, so the field moved almost not at all. The tree did.** Six commits
landed: v1.45.0 (`a5e3d90`) added two components to `tufte-dracula.css`, `nav.toc` and
`details.deep`, described in its subject as "on-this-page TOC and deep-section collapse styles
(template 1.21.0)"; the three commits after it regenerated the samples, `tokens.css` and the editor
themes that v1.45.0 tagged stale, ending at v1.45.1. **The entire value of this run is in that
twenty-three-line CSS addition.** It arrived with no NOTES.md entry, no fixture instance, and eight
defects, four of which contradict a decision NOTES.md already records as measured and settled.

Every finding below about those two components was verified by rendering them in headless Chromium
through Playwright, not by reading the cascade. Three of the eight were things arithmetic got right
and one was a thing arithmetic got wrong: the first version of this run's own narrow-width fix was
inert, because a media query adds no specificity and the override sat above the rule it meant to
beat. The render caught it. That is the same trap NOTES.md, Direction, zoom and growth, records for
the `.scorecard` container query.

## Color and contrast

NOTES.md sections read: Color and the contrast budget, Appearance modes, Print, Mermaid, CSS charts.

### Searched

- `color-mix() CSS Baseline widely available date web-features`
- (Topic 6's registry reads covered the palette-adjacent Mermaid delta; no palette hex moved in the
  window)

### Findings

**[New ground] `nav.toc` paints a composited ground that no gate in this repo can reach.** The rule
is `background: color-mix(in oklab, var(--surface-alt) 60%, transparent)`, which resolves against
`--surface`. NOTES.md, Color and the contrast budget, states: "Text can land on three grounds, and a
new token must clear its floor against all three. The grounds are `--surface`, `--code-bg` and
`--surface-alt`." This mix is a fourth ground, and `palette-check.py` parses tokens, not composited
mixes, so nothing measures it. Two tokens land on it: `--muted` (the `.toc-label`, at 0.72rem) and
`--purple-bright` (the hover and focus color). The mix's lightness sits between `--surface` and
`--surface-alt` in every mode, and both text tokens are already gated against both of those grounds
above their floor, so the pair is **bounded** rather than **measured**. AGENTS.md covers this case
directly: "A gate that cannot reach its subject does not get written. Say so in `NOTES.md` and leave
the obligation in prose." The patch says so in NOTES.md. It does not add a check.

**[Reinforces]** `color-mix()` itself is fine to use here: Baseline Newly available since Firefox
113 in May 2023, Widely available 2025-11-09 per the web-features dataset. It is the only use of
`color-mix()` in the sheet; every other translucent value uses the relative
`oklch(from var(--x) l c h / alpha)` form. The mixed form is not wrong, only unlike its neighbors,
and rewriting it would change a rendered ground for no gain. Left alone.
Source: [web-features explorer, `color-mix()`](https://web-platform-dx.github.io/web-features-explorer/features/color-mix/).

**[Repeat, unchanged since 2026-08-23]** Forced colors: no new spec movement beyond the CSS Color 4
`AccentColor` change already recorded. **But the forced-colors block does not cover the two new
components**, and that is a Topic 4 finding rather than a Topic 1 one. See the sweep, 1.4.11.

**[Repeat, unchanged since 2026-09-07]** APCA stays on the WCAG 3 track and out of the CSS specs.
No source dated inside this window.

No `:root` token, mode block, print override or Mermaid hex moved in the window.

### Patch-worthy

The NOTES.md paragraph recording the ungated composited ground. No check, per AGENTS.md.

## Typography

NOTES.md sections read: Fonts, Type scale, Italics, Paragraphs and section rhythm.

### Searched

- (No new query this run. The window is one day and the previous audit's `text-wrap: pretty`,
  `hyphenate-limit-chars` and `hyphens` datings are all inside their own citation windows. Repeats
  are listed without re-citation, per this skill's rule.)

### Findings

**[Violation of a settled decision] Both new components set `font-family: var(--sans)`, and `:root`
declares no `--sans`.** `nav.toc .toc-label` and `details.deep > summary` each carry the
declaration. Rendered in Chromium, the computed `font-family` on both is
`"Source Serif 4", Georgia, "Noto Serif", "DejaVu Serif", serif`: the inherited body stack. The
declaration is dead in every mode and always was. NOTES.md, Fonts, records exactly two faces, a
variable body serif and a variable code mono, each with a documented fallback path, and it records
why four other serifs lost. A third face is a decision that section does not make, and a dead token
reference is not the way to make it. **The previous audit found this same pair of declarations in a
rendered consumer page on 2026-09-07 and called them generator-owned** (that report, Extra subject,
finding 5). They were not. They were already in the template a day earlier, in v1.45.0. The patch
drops both declarations, which changes nothing rendered and makes the rules say what they do.

**[New ground] Six other `var()` references resolve outside `:root`, and all six are correct.**
`--tree-step` and `--bar-tint` are declared on the component that reads them, so a line-start
regex misses them while the cascade does not. `--bar`, `--icon-color`, `--natural-width` and
`--timeline-date` are consumer-supplied and each carries its own fallback inside the `var()`.
`--sans` had neither a declaration nor a fallback, which is exactly what separated a dead
reference from an optional one. The patch records that distinction in NOTES.md so the next
mechanical check of this rule does not report six false positives.

**[Repeat, unchanged since 2026-08-16]** `text-wrap: pretty` still has no Firefox support.
**[Repeat, unchanged since 2026-08-16]** `hyphenate-limit-chars` stays Limited availability, Safari
the sole blocker.

Neither new component sets a `text-wrap` or `hyphens` value, and neither needs one: the TOC entries
are short and the summary is one line.

### Patch-worthy

Drop `font-family: var(--sans)` from both rules. NOTES.md records the prohibition.

## Layout and spacing

NOTES.md sections read: Width and measure, Tables, Lists, Connections-map layout, Cascade layer.

### Searched

- `web.dev Baseline newly available August 2026 September 2026 CSS features digest`

### Findings

**[Violation] `nav.toc ol { columns: 2 }` has no narrow-width override, and at 320px it is
unusable.** Rendered at a 320px viewport, each TOC link box measures **68.1px wide and 102.6px
tall**: every entry wraps to five lines, roughly one word each. The sheet already solves this exact
problem one breakpoint up: `@media (max-width: 600px) { .col-2 > ol, .col-2 > ul { columns: 1 } }`.
`nav.toc ol` was simply left out of it. This is not a 1.4.10 Reflow failure, `scrollWidth` equals
`clientWidth` at 320px in both directions, so it does not appear in the WCAG sweep; it is a plain
layout defect. Patched to one column under 600px, the same link box renders 204.8px by 40.6px.

**A note on where that override goes, because the first attempt was wrong.** Adding
`nav.toc ol { columns: 1 }` inside the existing `@media (max-width: 600px)` block at the top of the
sheet did nothing: that block sits above the progressive-disclosure rules, a media query adds no
specificity, and the base `nav.toc ol { columns: 2 }` therefore won on source order. The render
showed `columnCount: 2` at 320px with the fix supposedly applied. The override has to sit **after**
the base rule, so the patch gives it its own block beside the print one. NOTES.md, Direction, zoom
and growth, already records this trap for `@container (max-width: 15em)`: "Its source position,
after the `max-width: 600px` block. Container queries add no specificity, so source order is what
makes it win."

**[Violation] The print override targets the wrong element and is inert.** v1.45.0 shipped
`@media print { nav.toc { columns: 1 } }`. The `columns` declaration lives on `nav.toc ol`, not on
`nav.toc`, and `columns` on a wrapper says nothing about the list inside it. Rendered under
`emulate_media(media="print")`: `nav.toc` computes `column-count: 1` and `nav.toc ol` still computes
`2`. The printed index stays two columns. Patched to `nav.toc ol`, print now computes `1`.

**[Violation of a settled decision] The two new rules are the only physical-side declarations in the
whole sheet.** `nav.toc { border-left: 3px }` and `nav.toc ol { padding-left: 1.3rem }`. A grep for
`border-left|border-right|padding-left|padding-right|margin-left|margin-right` across
`tufte-dracula.css` returns exactly those two lines and nothing else; every other side in 566 lines
is logical. NOTES.md, Direction, zoom and growth, is explicit about why: "`th` and `td` are
`text-align: start`, not `left`. With `left`, every cell stays left-aligned in RTL while the prose
around it flips." Rendered with `dir="rtl"`, `nav.toc` computes `border-left-width: 3px` and
`border-right-width: 0px`: the accent rule and the list indent stay on the left while the prose
flips. Patched to `border-inline-start` and `padding-inline-start`, RTL computes `0px` left and
`3px` right. `border-bottom` on `nav.toc a` went to `border-block-end` in the same pass, for
consistency rather than for a rendered defect.

**[Reinforces]** `:has()` Widely available, June 2026 Baseline digest. `subgrid` Widely available
March 2026 and still inapplicable to `dl.timeline`. Both unchanged and uncited again, per the repeat
rule. No August or September 2026 Baseline digest has published yet, so no Baseline line was crossed
inside this window by anything.

### Patch-worthy

The narrow-width override (placed after the base rule), the print selector fix, and the two logical
properties.

## Accessibility

NOTES.md sections read: Keyboard and assistive technology, Direction, zoom and growth, Links.

### Searched

- `WCAG 2.5.8 target size minimum inline exception link list spacing 24 CSS pixels`

### Findings

WCAG version confirmed, unchanged: **WCAG 2.2, W3C Recommendation, 2023-10-05, republished
2024-12-12.** WCAG 3.0 remains a Working Draft. WCAG 2.2 AA is the benchmark.

**[Violation] The `details.deep` summary triangles reach the accessibility tree.** The rules are
`details.deep > summary::before { content: "\25B8\00A0" }` and the `[open]` variant with `\25BE`.
The sheet has an established convention for exactly this, recorded in NOTES.md, Links: "The outbound
arrow is decorative, and it reached the accessibility tree. A screen reader then read out 'north
east arrow' after every external label. `content: "…" / ""` gives the pseudo-element empty
alternative text." Three pseudo-elements already sit inside `@supports (content: "x" / "y")` for
this reason (the outbound arrow, the `table.tree` turn, `blockquote.pull`). The two new triangles do
not, so a screen reader prefixes every deep-section summary with "black right-pointing small
triangle", and `<details>` already announces its own open state, so the marker adds nothing.
WCAG 1.1.1. Patched: the alt-text form goes in an `@supports` block placed **after** the base
declarations, because it ties them on specificity and would otherwise lose on source order. The base
declarations stay outside the guard for the reason NOTES.md gives: a browser that cannot parse the
alt-text syntax discards the whole declaration and the marker disappears.

**[New ground] `nav.toc a { text-decoration: none }` removes the underline from a link, and NOTES.md
says the underline is the only thing that marks one.** The full passage, NOTES.md, Links: "Underline
thickness has a 1px floor. A sub-pixel underline paints as a faint partial-coverage line, and the
underline is the only thing that marks a link." The new rule substitutes
`border-bottom: 1px dotted var(--rule-light)`, which is a real non-color cue, so this is not a
1.4.1 failure and not a reversal of the 1px floor. It is an undocumented second convention: prose
links are marked by an underline, index links by a dotted border. **One consequence is worth
knowing.** `prefers-contrast: more` raises the underline with
`a { text-decoration-thickness: max(2px, 0.1em); text-decoration-color: currentColor }`, and
`nav.toc a` outranks that rule (0,1,2 against 0,0,1), so the mode cannot reach these links at all.
The dotted border carries the mode instead, through `--rule-light`, which the mode does raise. The
patch records the convention and that consequence in NOTES.md rather than changing the rendering,
because the design intent here is the maintainer's to state.

**[Violation] Neither new component has a fixture instance, so no gate in the repo has ever drawn
either one.** `rg 'toc|class=\"deep\"' samples/*.html scripts/build-sample.nu` finds the CSS text
inlined in eight fixtures and no markup anywhere. That means `render-modes.py` never drew them in
dark, light or high contrast; the forced-colors structural sweep never saw them; `script-probe.py`
never touched them. NOTES.md states the principle itself, under Print: "**A styled class with no
instance is an untested class.** That is why the fixture's wrapped table is twenty-four rows rather
than three." The patch adds a six-entry `nav.toc` and one `details.deep` to the living fixture. This
is the finding that makes the other seven catchable next time by a gate instead of by an audit.

### WCAG conformance sweep

Checked against the tree at v1.45.1, commit `edb9cb6`. New this run: every row below was
re-evaluated against the two v1.45.0 components as well as against the rest of the sheet, since
neither had ever been swept. Rows whose status is unchanged from 2026-09-07 and whose subject the
new components do not touch carry their prior evidence.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | **Violation** | `details.deep > summary::before` and the `[open]` variant carry decorative triangles with no `content: "…" / ""` alt text, against the sheet's own convention for three other pseudo-elements. Patched. |
| 1.3.1 Info and Relationships | A | Pass | `nav.toc` is a real `nav` with an `ol`; `details.deep` is native disclosure. Semantic tables and `role="list"` unchanged. |
| 1.3.2 Meaningful Sequence | A | Pass | The multicol TOC reads column by column, which is its DOM order. `body.conn-map` reorder unchanged. |
| 1.4.1 Use of Color | A | Pass | `nav.toc a` trades the underline for a dotted `border-block-end`, so a non-color cue survives; `.verdict`, `.badge`, `.tag-dot` unchanged. |
| 2.1.1 Keyboard | A | Pass | `summary` and `a` are native stops; no `tabindex` added. |
| 2.1.2 No Keyboard Trap | A | Pass | Native `<dialog>`, unchanged. `details.deep` traps nothing. |
| 2.4.2 Page Titled | A | Pass | Distinct `<title>` per fixture. |
| 2.4.3 Focus Order | A | Pass | Rendered tab order through the TOC follows the visual column order at 1280px and the single column at 320px. |
| 2.4.4 Link Purpose | A | Pass | TOC entries name their sections. |
| 2.5.3 Label in Name | A | Pass | No new `aria-label` in the window. |
| 3.1.1 Language of Page | A | Pass | `lang="en"` on every fixture. |
| 3.2.1 On Focus | A | Pass | `nav.toc a:focus-visible` and `details.deep > summary:focus-visible` change color only. |
| 3.2.2 On Input | A | Pass | Filter box unchanged. |
| 4.1.2 Name, Role, Value | A | Pass | Both new components are native elements with native roles; nothing custom added. |
| 1.4.3 Contrast (Minimum) | AA | **Cross-reference, with a gap** | Covered by Topic 1's palette gate for the three declared grounds. `nav.toc`'s `color-mix` ground is a fourth that no check reaches; bounded by two gated grounds, not measured. Recorded in NOTES.md by the patch. |
| 1.4.4 Resize Text | AA | Pass | The stated 400% sideways-scroll exception still holds as written. |
| 1.4.10 Reflow | AA | Pass | Rendered at 320px: `scrollWidth` 320 equals `clientWidth` 320 with the TOC present, before and after the patch. The two-column index at 320px is a usability defect, not a reflow failure. |
| 1.4.11 Non-text Contrast | AA | **Violation** | The `@media (forced-colors: active)` block lists `code, kbd, .verdict, .badge, .kicker, .icon-chip, .step-node` and the two dots. It does not mention `nav.toc`. Under forced colors the `color-mix` background is replaced by `Canvas` and the index loses its ground, leaving only the `border-inline-start`, which does survive as `CanvasText`. The box therefore still reads as a box. **Not patched:** the rule that would fix it is a judgment about how the index should look in that mode, and no fixture instance existed to render it against until this patch adds one. Re-sweep next run with the instance in place. |
| 1.4.12 Text Spacing | AA | Pass | `nav.toc li` uses `margin`, not a fixed height; the summary is a block with padding. |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content. `details.deep` opens on activation, not on hover. |
| 2.4.6 Headings and Labels | AA | Pass | `.toc-label` names the index; summaries name their sections. |
| 2.4.7 Focus Visible | AA | Pass | `a:focus-visible, summary:focus-visible` covers both new components with the 2px ring, 3px in high contrast. The new color-only `:focus-visible` rules add to that ring rather than replace it. |
| 2.4.11 Focus Not Obscured | AA | Pass | `scroll-padding-top: 3em` on `.table-scroll`, unchanged. The TOC is not sticky. |
| 2.5.8 Target Size (Minimum) | AA | Pass, by the spacing exception | Rendered at 1280px, each TOC link box is 288.6 by 20px on a 28.3px vertical pitch, so a 24px circle centered on one target does not intersect the next. A standalone index is **not** covered by the inline exception, which applies to a target "in a sentence or block of text", so the spacing exception is what carries this. `details.deep > summary` renders 28px tall and passes on size outright. At 320px the single-column links render 40.6px tall. |
| 4.1.3 Status Messages | AA | Pass | `filter.js` unchanged. |

Out of scope, per this skill's fixed list: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4,
2.5.7, 3.1.2, 3.2.3, 3.2.4, 3.2.6, 3.3.x.

### Patch-worthy

The `@supports` alt-text block for both triangles, the fixture instances, and the NOTES.md entries.
The forced-colors gap is reported and left for the maintainer, with the reason stated in its row.

## Interaction and motion

NOTES.md sections read: Interaction states, Form follows role, Borrowed components.

### Searched

- `::details-content pseudo-element Baseline status interpolate-size details animation 2026`

### Findings

**[Violation of a settled decision] Both new `:hover` rules sit outside
`@media (hover: hover)`.** The rules were `nav.toc a:hover, nav.toc a:focus-visible` and
`details.deep > summary:hover, details.deep > summary:focus-visible`, each pairing the two states in
one selector, which is what put the hover half outside the guard. NOTES.md, Interaction states, is
as direct as this repo gets: "**Every hover rule sits inside `@media (hover: hover)`.** Eight of them
did not, and a hover style with no such guard does not fail to apply on touch, it applies at the
wrong time: the browser sets `:hover` on tap and leaves it set until the reader taps something else.
Measured with real touch emulation, a tapped `.nav-list` link kept its `--code-bg` fill
indefinitely. Every affordance in the sheet was affected at once, which is why this is one block
rather than eight guards." v1.45.0 made it nine and ten. The patch splits each selector, moves the
`:hover` halves into the single existing block immediately after `summary:hover`, and leaves the
`:focus-visible` halves where they are. Both moved selectors outrank their base rules on specificity
((0,2,2) against (0,1,2)), so the move is safe against source order, and neither collides with the
`prefers-contrast: more` block that NOTES.md warns the position guards against.

**[New ground, not proposed] `::details-content` is now Baseline Newly available (September 2025)
and would let `details.deep` animate open and closed with no script.** The pattern needs
`transition-behavior: allow-discrete` on `content-visibility` (Baseline since 2024-08, already
recorded here) and `interpolate-size: allow-keywords` for the `height: auto` leg, which is
Chromium-only, so Firefox and Safari would snap while Chrome slid. That asymmetry plus the sheet's
recorded motion restraint is enough reason not to propose it, and the `prefers-reduced-motion`
blanket would have to cover it if anyone ever did. Recorded so absence reads as a decision.
Sources: [MDN `::details-content`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/::details-content);
[Chrome for Developers, "More options for styling `<details>`"](https://developer.chrome.com/blog/styling-details).

**[Reinforces]** `@starting-style` and `transition-behavior: allow-discrete` unchanged since
2024-08. Same-document View Transitions unchanged since the previous run's dating. Neither new
component transitions anything, and `user-select: none` on the summary is a press-affordance choice
with no motion in it.

### Patch-worthy

Both `:hover` halves into `@media (hover: hover)`.

## Pinned dependencies

NOTES.md sections read: Fonts, Mermaid.

### Searched

- `npm view @fontsource-variable/source-serif-4 version time.modified`
- `npm view @fontsource-variable/jetbrains-mono version time.modified`
- `npm view mermaid version time.modified`
- `npm view @mermaid-js/layout-elk version time.modified`

### Findings

All four pins current, none moved in the window.

| Dependency | Pinned | Registry latest | Published |
| --- | --- | --- | --- |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.0 | 2026-07-19 |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | 2026-07-19 |
| `mermaid` | 11.17.2 | 11.17.2 | 2026-08-25 |
| `@mermaid-js/layout-elk` | 0.2.3 | 0.2.3 | 2026-08-19 |

No bump applies. A future Mermaid bump belongs to `nu scripts/maintain.nu mermaid <version>`, named
here per this skill's rule and never run.

### Patch-worthy

Nothing. No dependency bump belongs in this skill's patch regardless of findings.

## Ungated-rules sweep

This section is new. It runs the fixed table of AGENTS.md and NOTES.md rules that no check
enforces, added to the skill after this run found its first three violations by hand. Status per
row: **Violation** on the comment prohibition (three sites) and on four rows already reported above
under their topics (physical sides, unguarded hovers, decorative pseudo-element alt text, styled
class with no instance). **Pass** on the Mermaid hex-only rule, the exact-pin rule, and the
generated-file line-number rule. **Pass with a documented gap** on the composited-ground row, per
Topic 1.

**Deleting a comment out of the payload is in this patch three times, and two of them are four
releases old or older.** AGENTS.md: "Do not add comments to `tufte-dracula.css` or `mermaid.js`. No block
comments, no end-of-line comments, and no single line that explains a magic number... Two exceptions
exist. A machine reads both": line 2's version stamp and the `/* was #rrggbb */` notes.

- v1.45.0 added `/* Progressive disclosure (template v1.21.0): on-this-page TOC + deep sections */`.
- **v1.41.0 (`4eaff8b`) added a five-line block comment inside `@media print`**, above the
  `pre.mermaid` token freeze. It has shipped inlined in every generated page for four releases, and
  three design audits read past it. Its content is already in NOTES.md, Mermaid, in fuller form
  ("Mermaid bakes its hex into the SVG at init, and print is a media query with no re-render..."
  through the five-token list and the "freeze every token any `pre.mermaid` rule reads" prohibition),
  so deleting it loses no load-bearing explanation, which is the one condition AGENTS.md puts on
  removing one.

**`mermaid.js` carries eleven comment lines, and its correct count is zero.** Both AGENTS.md
exceptions are CSS-only: one names "Line 2 of `tufte-dracula.css`", the other the `:root` hex
notes. `mermaid.js` gets no exception, and it is inlined verbatim into every generated page
exactly as the stylesheet is. Two blocks: six lines above `const scrolls = window.matchMedia(...)`
on the labelled-region tab stop, and five inside `syncRegions` on why the region takes a
container name rather than the diagram title. **NOTES.md, Keyboard and assistive technology,
already holds both in fuller form** (lines beginning "The `pre` region is named for what the
container is" and "`pre.mermaid` is a labelled region only at the widths where it can scroll",
including the "Do not 'fix' this by putting the title back in the label" prohibition the comments
omit), so deleting them loses nothing. In the patch. `Script binding OK (26 assertions)` after the
deletion, so the payload still runs.

**This finding came out of the new ungated-rules sweep on its first run, which is the argument for
the sweep.** Four design audits read the stylesheet closely and none of them looked at `mermaid.js`
for comments, because no step told them to and no gate does.

After the patch, `rg '/\*' tufte-dracula.css` returns the version stamp and the `was #` notes and
nothing else, and `rg -e '/\*' -e '^\s*//' mermaid.js` returns nothing. **`nu scripts/maintain.nu
check` prints `Contract OK` with all three comment sites present**, on `HEAD` today, which is why
four audits missed them: nothing gates this rule. Mechanizing it is two `rg` calls in
`maintain.nu`, and it is the strongest candidate for a gate this repo does not have. Not in this
patch, because a new gate belongs in the same change as a decision to enforce it.

## Challenges a settled decision

None. Every finding above either agrees with a NOTES.md decision and reports v1.45.0 as having
broken it, or lands on ground NOTES.md never covered. Nothing here asks the maintainer to reopen
anything, and the long measure was not touched, examined or measured this run.

## Verification

`Verified: patch applies to HEAD and Contract OK after regeneration.`

The sequence: a detached worktree at `HEAD`, `git apply`, `scripts/build-sample.nu`, then
`scripts/maintain.nu check`, which printed `Mode renders OK (12 images)`,
`Script binding OK (26 assertions)`, `Generated files fresh.`, `Themes fresh.`,
`No em-dash or en-dash.` and `Contract OK.` Both worktrees were removed.

Both scans this skill requires beyond `check` returned nothing:

- `rg -c -e '\u{2014}' -e '\u{2013}' review/2026-09-08-design-audit.*`: no hits.
- `rg -n '^\+' review/2026-09-08-design-audit.patch | rg -e '/\*' -e '\*/' -e '//'`: no hits. The
  patch adds one `#` comment, to `scripts/build-sample.nu`, which AGENTS.md permits: "The Nushell
  scripts... are not inlined. Comment those files as normal."

Beyond `check`, every rendered claim in this report was measured in headless Chromium at 1280px,
at 320px, with `dir="rtl"`, and under print emulation, against a probe page carrying the real
stylesheet and real `nav.toc` and `details.deep` markup, before and after the patch. The
before-and-after numbers are in the findings.

## Applied

The maintainer accepted the patch on 2026-09-08. It landed on `fix/v1.46.0-progressive-disclosure`
as **v1.46.0**, with three additions found while applying it:

1. **`CONTRACT.md` had no `v1.45.0` or `v1.45.1` row and never named either component.** § 3's own
   header says a row there means a generator needs an edit, so a consumer moving the pin read the
   table, found nothing, and had no way to learn that two components existed. Three rows added,
   newest first, and the v1.45.0 row says to pin v1.46.0 instead.
2. **A new § 2 requirement for `nav.toc`.** It is a landmark and needs a name, so the requirement
   is `aria-labelledby` pointing at its own `p.toc-label`. § 2 is twenty-five requirements, and
   README.md's count moved with it, which `maintain.nu check` gates: the first `check` after the
   edit failed with "README.md does not say `The twenty-five markup requirements`, so the two counts
   disagree". That gate did its job.
3. **The fixture markup this report proposed named the landmark twice.** It carried
   `aria-label="On this page"` beside a visible `p.toc-label` reading the same string, which is the
   duplication NOTES.md records for the `pre.mermaid` region, reached from the other direction.
   Fixed to `aria-labelledby` before the commit, which is also what made requirement 2 worth
   writing down.

Adding a § 2 requirement is the v1.44.0 shape, which is why this is a minor rather than v1.45.2.
The measurements above were re-taken against the **real regenerated `samples/dark.html`**, not the
synthetic probe: two columns at 1280px and one at 320px, 28.3px link pitch, 28px summary, no
horizontal scroll at either width, `border-right` in RTL, one column under print emulation, the
landmark name resolving once through `aria-labelledby`, and the summary computing the body serif.

## Summary

- Findings total: 17 across the six topics, plus the 25-row WCAG sweep and the new
  10-row ungated-rules sweep
- Violations of a settled NOTES.md decision, patched: 4 (the dead `--sans`, the two physical
  properties, the unguarded hovers, the missing pseudo-element alt text)
- Violations of the AGENTS.md comment prohibition, patched: 3 sites (v1.45.0 in the CSS,
  v1.41.0 in the CSS print block, and eleven lines in `mermaid.js` predating both)
- Other violations, patched: 3 (no narrow-width column override, the inert print override, no
  fixture instance)
- Violations reported and not patched: 1 (forced colors does not cover `nav.toc`; the fix is a
  design judgment, and the fixture instance this patch adds is what makes it renderable next run)
- New ground: 4 (the ungated `color-mix` ground, the index-link marking convention,
  `::details-content`, the six correct out-of-`:root` `var()` references)
- Reinforces: 4
- Repeat, unchanged: 4
- Challenges a settled decision: 0
- Patch: `review/2026-09-08-design-audit.patch`, 4 source files (`tufte-dracula.css`,
  `mermaid.js`, `NOTES.md`, `scripts/build-sample.nu`), 89 insertions and 25 deletions, verified
