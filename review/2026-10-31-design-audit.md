# Design Audit, 2026-10-31

Range: `99be251..a1df369`, **two commits**: v1.59.5 and v1.59.6. Previous report:
`review/2026-10-25-design-audit.md`, which audited `3cc54b4..99be251`. `review/declined.md` has no
rows, so no finding matches a decline.

`HEAD` is `a1df369` on `fix/timeline-entry-grouping`, one commit ahead of `origin/main` (`ebe3469`).
The v1.59.6 commit is not merged yet. This run audits the branch head as it stands.

The window is small and every payload change answers a finding from the previous report: the heading
weight ladder (D3), the print table reset (D1), the NOTES type-scale drift (D4), and the
`scrollbar-gutter` passage (D2). `NOTES.md` also corrects a stale timeline breakpoint (600 px to
760 px) that the stylesheet already used.

Method: headless Microsoft Edge 156.0.4314.50 on macOS, driven over CDP with
`Emulation.setDeviceMetricsOverride` (so 320 px is a real viewport, not an iframe), `file://` loads,
CDN reachable, and device-scale 1. Layout, print, RTL, focus, keyboard and performance readings are
unthrottled lab data. CSS coverage was attempted and is reported as unavailable; see Topic 7.
`nu scripts/maintain.nu check` printed `Contract OK` on `HEAD`.

## Step 2: Delta

| Change | NOTES.md documents it | Obeys AGENTS.md | Obeys a settled decision | A fixture renders it |
| --- | --- | --- | --- | --- |
| `h3` 650, `h4` 550, `h5`/`h6` 450 (v1.59.5) | Yes, Type scale, but see F1 | Pass, no comment added | Conflicts with the adjacent `--label` rationale, F1 | `samples/dark.html` has h1 through h6 |
| `dl.timeline > dd + dt { margin-top: var(--space-4) }` plus the 760 px reset (v1.59.6) | Yes, Lists | Pass | Pass | `samples/dark-timeline.html`, search `class="timeline"` |
| `table { background: none }` in print (v1.59.6) | Yes, Tables | Pass | Pass, closes previous D1 | Every fixture table |
| NOTES timeline breakpoint 600 to 760 (v1.59.6) | Now matches the stylesheet | Pass | Pass | n/a |
| Version stamps and release assets to v1.59.6 | n/a | Pass | n/a | n/a |

**F1 (Violation of a settled decision, no patch): the new `h5` weight removes the axis the
`--label` decision depends on.** `NOTES.md`, Type scale, still says:

> **That rule now covers color too: `h5`/`h6` sit at `--label`, not `--muted`.** At body size, weight
> is the only other axis marking them as headings; on `--muted` a heading was the dimmest thing in its
> own section, the same inversion this file refuses for `dl.timeline > dd`.

The same section now sets `h5` and `h6` to 450. Body copy is also 450, and `--label` is dimmer than
body text: rendered `h5` computes `oklch(0.81 0.054 275.492)` at weight 450 while the paragraph under
it computes `oklch(0.977 0.008 106.545)` at weight 450 (`samples/dark.html`, 1280 px). So `h5` is now
marked only by `--label` and its margin, and it is the dimmest text in its own section: exactly the
shape the paragraph says the repo refuses. `h6` escapes by italic; `h5` does not.

This is not a WCAG failure and it is not the old inversion: the order is 650, 550, 450, 450 italic,
so no child outweighs its parent. It is a contradiction between two entries written two days apart.
There is no mechanical fix the audit can choose. Raising `h5` to 500 restores the weight axis and
keeps every level distinct; rewriting the paragraph accepts a heading dimmer than its body copy. Both
are design decisions, so neither is in the patch.

**F2 (Doc gap, in patch): the fallback face collapses the new heading ladder.** `NOTES.md`, Fonts,
records that Georgia has no 450. It does not record that Georgia also has no 550 or 650, so both
steps map to 700 and `h3` and `h4` render identically offline. Measured with Canvas font matching:
Georgia at 550 and 650 both measure 169.89 px for the same string as Georgia 700, while 400, 450 and
500 all measure 145.68 px. The patch adds this to the existing fallback paragraph; it states a
consequence, not a new size convention.

**Previous findings, closed in this window.** D1 is fixed: print now computes `background: none` on
both a bare `table` and `.table-scroll`. D3 is fixed on screen: `h3` 650 above `h4` 550 above `h5`
450, with `h6` 450 italic. D4 is fixed: NOTES says "five text steps" and names the two decorative
glyphs outside the scale. D2 is now documented rather than contradicted: NOTES states that the
gutter narrows prose by one track per edge and that the cost is accepted. The declaration still
narrows running prose by 15.2 to 27 px against no gutter, as the previous report measured; there is
nothing left to report on it, and it is not re-argued here.

**Previous report claims re-checked.** D5 (the table shadow under a classic scrollbar) was not
touched by this window. D6 (the copy confirmation has no live region) is unchanged: the copy button
still changes its own `aria-label`, and the only `role="status"` on the page belongs to the filter.
It remains a candidate under 4.1.3, not a confirmed violation.

## Topic 1: Color and Contrast

No color token changed in this window. The palette gate ran inside `maintain.nu check` and passed.
F1 is a hierarchy consequence that uses two already-gated colors, not a contrast failure: `--label`
and `--on-surface` both clear their floors.

Tier behavior still matches NOTES: `--label` is the moving tier, `--muted` is pinned at the floor,
and `h3`/`h4` stay on `--label`. The one new interaction is F1: at the same weight, `--label` becomes
the only remaining color cue for `h5`.

### Searched

No new query. The window carries no color change, and the standards recheck lives under Standards
status.

## Topic 2: Typography

The ladder is a clear improvement over the previous audit's D3: the rendered weights descend
650, 550, 450, 450 italic, and `h6` is italic. At the same body step, no parent is lighter than its
child. `text-wrap: balance` remains on `h1` to `h3`, and `text-wrap: pretty` remains on `p`,
sidenotes and captions.

**F1** is the residual: `h5` at 450 equals body copy at 450, so the weight axis that the `--label`
paragraph relies on is gone for that one level. **F2** records the offline collapse of 550 and 650
onto Georgia's 700.

Baseline status: `text-wrap: balance` is Newly available since 2024-05-13; `text-wrap: pretty` is
not Baseline (web-features 3.44.0). Both are cosmetic progressive enhancements: an unsupported
browser wraps normally. Hyphenation is Widely available since 2023-09-18.

### Searched

- web-features 3.44.0 dataset, keys `text-wrap-balance`, `text-wrap-pretty`, `hyphens`,
  `font-display`, `font-variation-settings` (accessed 2026-10-31).
- No web query: the window changes weights only, and the Baseline data above is authoritative for
  the two wrapping features.

## Topic 3: Layout and Spacing

The timeline change works as written, and the render proves it rather than the arithmetic alone.

| Fixture | Viewport | Entry gap before v1.59.6 | Entry gap after | Date and body baseline |
| --- | --- | --- | --- | --- |
| `dark-timeline.html` | 1280 | 12.0 px | 28.0 px | equal top and baseline in every row |
| `dark-timeline.html` | 320 | 18.4 px | 18.4 px | stacked, unchanged |

At 1280 the `dd + dt` margin is 16 px, the grid row gap is 12 px, and the margin moves the whole
row, so the date and body still share a baseline. At 320 the reset to `margin-top: 0` leaves the
existing `dd` bottom margin and 2.4 px row gap: no double separation. RTL at 1280 computed
`border-right: 1px`, `padding-right: 16px`, `border-left: 0`, `padding-left: 0`, with the date column
on the right, so the rule adds no physical-side regression. Print carries the 16 px margin, which is
harmless and not a new container.

Page width, measure and breakpoints are untouched. `--page-width` remains the one width number.

### Searched

- web-features 3.44.0 dataset, keys `container-queries`, `has`, `subgrid`, `cascade-layers`,
  `nesting`, `scope` (accessed 2026-10-31).
- No web query: the delta is spacing inside an existing grid, and the feature review is covered
  under Modern CSS Baseline review.

## Topic 4: Accessibility

The timeline is a `dl` with `dt` and `dd`, so the new spacing changes no semantics. Headings keep
their order and level in the DOM. The WCAG sweep below is the detailed record.

One manual result worth stating here: the zoom dialog is a native `<dialog>` and `showModal()` gives
it the dialog role. A trusted Escape key closes it (`open: false`) and returns focus to the
`.mermaid-zoom` button that opened it. No custom key handler is involved.

### Searched

- W3C WAI WCAG standards page, https://www.w3.org/WAI/standards-guidelines/wcag/ (accessed
  2026-10-31).
- W3C TR, WCAG 3.0 Working Draft, https://www.w3.org/TR/wcag-3.0/ (accessed 2026-10-31).
- ETSI EN 301 549 directory, https://www.etsi.org/deliver/etsi_en/301500_301599/301549/ (accessed
  2026-10-31).
- Search: "EN 301 549 latest version 2026 Official Journal harmonised accessibility".
- Search: "ISO/IEC 40500 current edition 2026 WCAG 2.2".

## Topic 5: Interaction and Motion

No interaction rule changed. The hover block still owns every `:hover` rule (lines inside
`@media (hover: hover)`), `prefers-reduced-motion` still gates the transitions, and the timeline
margin is static, so reduced motion has nothing to suppress. Focus rings render at 2 px in dark and
light and 3 px in `prefers-contrast: more`.

### Searched

No new query. The window adds no state, transition or pointer behavior.

## Topic 6: Pinned Dependencies

| Package | Pinned | Current | Provenance |
| --- | --- | --- | --- |
| `mermaid` | 12.2.0 | 12.2.0 | npm attestation, SLSA v1 |
| `@highlightjs/cdn-assets` | 11.12.0 | 11.12.0 | npm attestation, SLSA v1 |
| `@fontsource-variable/source-serif-4` | 5.3.1 | 5.3.1 | npm attestation, SLSA v1 |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | npm attestation, SLSA v1 |

Every pin is current, so there is nothing to take. All four are exact versions with no range.

**Provenance is not checkable at the URL.** `@font-face src: url()` has no SRI hook, and a bare
specifier ESM import of a remote URL has no `integrity` hook. Adding `integrity=` to either would be
inert, so the audit does not propose it. What is checkable is the npm package's own attestation, and
all four carry one. Self-hosting remains a decision NOTES already weighed; this run does not reopen
it.

A Mermaid bump would go through `nu scripts/maintain.nu mermaid <version>`, not through this patch.
None is needed.

### Searched

- `npm view <pkg> version time.modified dist.attestations` for the four packages above (accessed
  2026-10-31).
- No web query.

## Topic 7: Performance and Stability

Lab data, Edge 156, `samples/dark.html`, 1280 x 900, cache disabled, no throttling, local `file://`:

| Metric | Value |
| --- | --- |
| LCP | 68 ms |
| CLS | 0.0126, one shift at 101 ms |
| DOMContentLoaded | 122 ms |
| Load | 126 ms |
| HTML transfer | 100,274 bytes |

These are cache-disabled but unthrottled local numbers; they say the page is light, not what a
network reader sees. The one layout shift is the webfont swap at 101 ms. Field data is unavailable:
there is no public deployment or CrUX record for this template, so INP is unavailable and no field
LCP or CLS is reported.

Render-blocking: none in the CWV sense. The stylesheet is inline, so there is no stylesheet request.
The four font files use `font-display: swap`. Mermaid and highlight.js load as module scripts, which
are deferred. Mermaid pulls 54 script resources on this fixture; that cost is already documented and
is not new.

Images: the emoji `<img>` is an inline data URI at text size, and the hero image is an inline data
URI whose box is reserved by the `.hero` aspect ratio. Neither has `width`/`height` attributes, and
neither produced a shift. Ad slots do not exist, so ad layout shift is not applicable.

CSS coverage: **not reachable this run.** CDP's `CSS.startRuleUsageTracking` reports one coarse
range for an inline `<style>` block and marks it used. A control page with a never-matching selector
and an unmatched print rule returned a single `used: true` range, so the API cannot answer which
rules a fixture did not exercise. No unused-CSS claim is made from it. This is a tool gap, not a
clean result.

### Searched

- web.dev, Core Web Vitals, https://web.dev/articles/vitals (page last updated 2024-10-31,
  accessed 2026-10-31).
- web.dev, Baseline, https://web.dev/baseline (accessed 2026-10-31).
- web-features 3.44.0 dataset (accessed 2026-10-31).

## Standards status

| Area | Status on 2026-10-31 | Notes |
| --- | --- | --- |
| WCAG Recommendation | WCAG 2.2, Recommendation 2023-10-05, revised 2024-12-12 | No newer Recommendation. 86 active success criteria after 4.1.1 removal and nine 2.2 additions |
| WCAG 3.0 | W3C Working Draft, 2026-09-10 | Draft only. Requirements note is not the draft. No Recommendation date is predicted |
| ISO/IEC 40500 | ISO/IEC 40500:2025, Edition 2, published 2025-09-24 | Corresponds to WCAG 2.2. Stage 90.92, revision under development. 2026-dated national adoptions are not a new ISO edition |
| EN 301 549 | V4.1.1, published 2026-09 | Adds WCAG 2.2 AA and six 2.2 criteria, drops 4.1.1. Not yet cited in the Official Journal; V3.2.1 remains the cited standard until citation is confirmed |
| Baseline | WebDX Community Group definition | Newly available means interoperable in all core browsers; Widely available means 30 months later |

This section maps technical criteria only. It does not claim compliance with the European
Accessibility Act, Section 508, or any other law, and it does not infer harmonisation from
publication.

### Searched

- https://www.w3.org/WAI/standards-guidelines/wcag/ (accessed 2026-10-31).
- https://www.w3.org/TR/wcag-3.0/ (accessed 2026-10-31).
- https://www.etsi.org/deliver/etsi_en/301500_301599/301549/ (accessed 2026-10-31).
- https://web.dev/baseline (accessed 2026-10-31).
- Search: "EN 301 549 latest version 2026 Official Journal harmonised accessibility" (results from
  AccessibleEU, 2026-09-07, and the National Disability Authority).
- Search: "ISO/IEC 40500 current edition 2026 WCAG 2.2" (ISO catalog result).

## Modern CSS Baseline review

Baseline data from web-features 3.44.0, accessed 2026-10-31. "Newly" is the date the feature became
interoperable in every core browser; "Widely" is 30 months later.

| Feature | Baseline | Newly | Current use | Fallback or reason |
| --- | --- | --- | --- | --- |
| Container queries (`@container`) | Widely | 2023-02-14 | Yes, 2 uses | Not needed |
| `:has()` | Widely | 2023-12-19 | Yes, 5 uses | Not needed |
| Subgrid | Widely | 2023-09-15 | No | No layout need; the one grid already works without it |
| Cascade layers (`@layer`) | Widely | 2022-03-14 | Yes, 1 use | Not needed |
| Native nesting | Widely | 2023-12-11 | No | The sheet is flat by convention; not adopted |
| `@scope` | Newly | 2026-03-24 | No | Would need an `@supports` fallback for no gain |
| `oklch()` | Widely | 2023-05-09 | Yes, 84 uses | Not needed |
| `color-mix()` | Widely | 2023-05-09 | Yes, 6 uses | Not needed |
| `clamp()` | Widely | 2020-07-28 | Yes, 3 uses | Not needed |
| Logical properties | Widely | 2021-09-20 | Yes, 20 uses | Not needed |
| `aspect-ratio` | Widely | 2021-09-20 | Yes, 1 use | Not needed |
| Flexbox `gap` | Widely | 2021-04-26 | Yes | Not needed |
| `dvh`/`svh`/`lvh` | Widely | 2022-12-05 | `dvh` only, 2 uses | The existing `vh` fallback pattern is unchanged |
| Scroll-driven animations | Not Baseline | n/a | No | Not adopted |
| View Transitions | Newly | 2025-10-14 | No | Not adopted |
| `@starting-style` | Newly | 2024-08-06 | No | Not adopted |
| CSS Grid Lanes | Not Baseline | n/a | No | Not adopted |
| `sibling-index()`/`sibling-count()` | Newly | 2026-08-18 | No | Not adopted |
| Anchor positioning | Not Baseline | n/a | No | Not adopted |
| Registered custom properties (`@property`) | Newly | 2024-07-09 | No | The sheet's tokens need no registration |

Mobile-first authoring remains current practice, but this sheet is desktop-first by an explicit
width decision. Reversing it would re-open the settled layout, and nothing in the field data
suggests that is warranted.

### Searched

- web-features 3.44.0 dataset (accessed 2026-10-31), keys listed in the table.
- No additional web query: the dataset is the source behind MDN's Baseline badges, and every
  feature was checked against it in one pass.

## Responsive usability sweep

`samples/dark.html` and `samples/dark-conn-map.html` at 320, 375, 768, 1024 and 1280 wide by 568,
768 and 900 tall, 30 renders, real viewports through CDP.

| Fixture | Width | Page `scrollWidth` / `clientWidth` |
| --- | --- | --- |
| `dark.html` | 320 | 290 / 305 |
| `dark.html` | 375 | 345 / 360 |
| `dark.html` | 768 | 738 / 753 |
| `dark.html` | 1024 | 994 / 1009 |
| `dark.html` | 1280 | 1250 / 1265 |
| `dark-conn-map.html` | all five | same as `dark.html` at each width |

Height changed no result in any render. No page-level horizontal overflow occurred. The 15 px
difference between `scrollWidth` and `clientWidth` is the reserved gutter, not overflow. Known
hatches (`pre`, `pre.mermaid`, `.table-scroll`, `table.tree`, display math) still scroll inside
their own boxes and were excluded from the page-level count.

Targets under 44 by 44 CSS px, measured at 1280: 33 in `dark.html`, none in `dark-conn-map.html`.
The set is unchanged from the previous audit: 28 anchors, two `summary` elements, two disabled
task-list checkboxes at 18.3 px, one MathML scroll region, and the heading permalinks at about 8 by
17. This is the same usability gap the previous run recorded; this window adds no target. Under
WCAG 2.5.8 the 24 by 24 minimum is met by the spacing, inline-link and inactive-control exceptions,
recorded in the table below.

Stacking: `body.conn-map` still wraps name over cards in DOM order. Loading, error and empty states:
the template implements only the filter's no-match line. Typing a non-matching term produced
`0 entries` in the existing `role="status"` line with no layout overflow. Visual hierarchy: F1 is
the one new residual, and it is a heading-versus-body contrast of emphasis, not a reflow defect.

## Accessibility tool and keyboard checks

Manual keyboard checks in Edge, `samples/dark.html`:

| Check | Result |
| --- | --- |
| Tab through the first 26 focusable elements | Every one showed a visible outline; order follows DOM order |
| Focus ring, dark | 2 px solid `oklch(0.802 0.064 216.782)` |
| Focus ring, light | 2 px solid `oklch(0.52 0.056 216.782)` |
| Focus ring, `prefers-contrast: more` | 3 px solid `oklch(0.83 0.064 216.782)` |
| Space on a `summary` | Toggles `details`, focus stays on the summary |
| Escape in the mermaid dialog | Closes the native dialog, focus returns to `.mermaid-zoom` |
| Filter input | Updates `role="status"` to `0 entries`; no navigation or submit |
| Text-spacing override at 320 px (line-height 1.5, letter-spacing 0.12em, word-spacing 0.16em, 2em paragraph margins) | `scrollWidth` 290 against `clientWidth` 305; no overflow |

No automated accessibility tool was run. Automated results would supplement, not replace, the
palette gate and these manual checks. No screen reader was available, so the copy-confirmation
announcement remains unverified (F3, below).

## WCAG conformance sweep

WCAG 2.2, the current Recommendation, with 86 active success criteria. Each row is checked against
the current payload, including the changed timeline and heading rules.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | Hero and emoji `img` carry `alt`; mermaid `title`/`desc` are set from `accTitle`/`accDescr`; decorative pseudo content has a `/ ""` twin |
| 1.3.1 Info and Relationships | A | Pass | Heading levels descend h1 to h6 in the fixture; timeline is `dl` with `dt`/`dd`; tables keep native roles |
| 1.3.2 Meaningful Sequence | A | Pass | DOM order is logical; `body.conn-map` reorder is unchanged and documented |
| 1.4.1 Use of Color | A | Pass | Verdicts and status chips carry text, not hue alone |
| 2.1.1 Keyboard | A | Pass | All controls reachable; scroll regions and the dialog are keyboard operable |
| 2.1.2 No Keyboard Trap | A | Pass | Escape closes the dialog and returns focus to the opener |
| 2.4.2 Page Titled | A | Pass | `<title>` present and distinct per fixture |
| 2.4.3 Focus Order | A | Pass | Tab order follows DOM order through navigation, content, code buttons and the filter |
| 2.4.4 Link Purpose (In Context) | A | Pass | No bare "click here"; outbound arrow is decorative with an accessible twin |
| 2.5.3 Label in Name | A | Pass | Zoom button's visible "Zoom diagram" is a prefix of its aria-label |
| 3.1.1 Language of Page | A | Pass | `lang="en"` on `<html>` |
| 3.2.1 On Focus | A | Pass | Focus never changes context |
| 3.2.2 On Input | A | Pass | The filter only updates the status line |
| 4.1.2 Name, Role, Value | A | Pass | Zoom button and dialog are natively named; scroll regions carry `role="region"` and a label at narrow widths |
| 1.4.3 Contrast (Minimum) | AA | Pass | Palette gate inside `maintain.nu check`; `--label` and `--on-surface` both clear their floors |
| 1.4.4 Resize Text | AA | Pass | The clamp uses `rem` bounds and the 320 px render reflows without overlap |
| 1.4.10 Reflow | AA | Pass | 290/305 at 320 px; no page overflow at any of the 30 renders |
| 1.4.11 Non-text Contrast | AA | Pass | Focus rings and control borders are gated by palette checks 9 and 10; rendered rings are visible in all three modes |
| 1.4.12 Text Spacing | AA | Pass | Override probe at 320 px produced no horizontal overflow |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content exists |
| 2.4.6 Headings and Labels | AA | Pass | Headings and the filter label describe their content |
| 2.4.7 Focus Visible | AA | Pass | Visible outline on every focused element, all three modes |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Pass | No sticky header; the modal dialog contains focus rather than covering it |
| 3.2.3 Consistent Navigation | AA | Pass | Single-document template; the toc and nav order is stable |
| 3.2.4 Consistent Identification | AA | Pass | Repeated controls (copy buttons, zoom buttons) keep one name pattern |
| 2.5.7 Dragging Movements | AA | Pass | No dragging feature |
| 2.5.8 Target Size (Minimum) | AA | Pass | Copy and zoom buttons are 44 by 44. Permalinks use the spacing exception, inline links the inline exception, disabled checkboxes the inactive-control exception |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism is repeated across the template |
| 3.3.7 Redundant Entry | A | Not applicable | The only input is a filter; no multi-step process |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication |
| 4.1.3 Status Messages | AA | Pass, one candidate | The filter count is a `role="status"` message. The copy confirmation changes a focused button's name only; whether it is announced is unverified (F3) |

Relevant AAA criteria, tracked separately:

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Pass | No author content overlaps a focused control |
| 2.4.13 Focus Appearance | AAA | Partial | A 2 px ring is visible, but the criterion's enhanced area and contrast calculation was not measured this run |
| 2.5.5 Target Size (Enhanced) | AAA | Not met | 33 targets under 44 by 44 at 1280, all pre-existing prose links, permalinks, summaries and checkboxes |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication |

Out of scope, stated once: 1.2.x (no audio or video), 2.2.x (no timers), 2.3.x (no flashing),
2.4.1 and 2.4.5 (single document, no repeated site navigation), 2.5.1, 2.5.2 and 2.5.4 (no custom
pointer gestures or motion controls), and 3.1.2 Language of Parts (single-language prose).

## Ungated-rules sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in an inlined payload file | Pass | CSS comment search returns line 2 only; `mermaid.js`, `filter.js` and `highlight.js` return none |
| Every `var(--x)` resolves or has a fallback | Pass | 348 references against 42 declared tokens; no unresolved reference without a fallback |
| Sides are logical, never physical | Pass | No `border-left`, `padding-left` or `margin-left` in the sheet; RTL computed the border and padding on the right |
| Every `:hover` sits inside `@media (hover: hover)` | Pass | All hover rules at lines 508 to 518 sit inside the block opened at line 507 |
| Decorative pseudo content has an alt-text twin | Pass | Outbound arrow, tree branch, pull quote, layer arrow, close mark and details arrows all carry a `/ ""` twin. The sidenote counter is content, not decoration |
| A selector not in a fixture has a documented reason | Pass for the new rule | `dl.timeline > dd + dt` renders in `samples/dark-timeline.html` |
| Mermaid colors are hex, never `oklch()` or `var()` | Pass | Search returns nothing in a color position |
| Exact CDN pin, never a range | Pass | Four packages, six URLs, all exact |
| Never cite a line number into a generated file | Pass | No line-number pointer appears in this report or the changed docs |
| New composite grounds have a NOTES entry | Not applicable | This window adds no color or ground |

## Challenges a settled decision

None. The window's changes were a response to the previous report, and the one contradiction found
(F1) is internal to the current NOTES, not a case where current practice moved past a settled
decision. No cited source dates from after a decline, because the decline ledger has no rows.

## Out of Scope

The NOTES sections outside the topic map (Filter, Unclaimed elements, Markdown coverage, Raw HTML
and other generators, Repo layout, Odds and ends) were not audited by this run. Their absence is a
scope decision, not a pass.

## Verification

Patch: `review/2026-10-31-design-audit.patch`, NOTES.md only (F2).

- Applied to a detached worktree at `HEAD` (`a1df369`).
- `nu scripts/build-sample.nu` regenerated with no fixture change.
- `nu scripts/maintain.nu check` printed `Contract OK`.
- Em-dash and en-dash scan over both output files found nothing.
- Added-line comment scan found no comment in an inlined payload file (the patch touches NOTES.md,
  which is not inlined).
- Probe re-run on the patched worktree: the fallback measurement is unchanged, because the patch
  states it rather than changing it.

Verdict: `Verified: patch applies to HEAD and Contract OK after regeneration.`

No patch accompanies F1, because both remedies are design decisions. The patch does not touch any
payload file.
