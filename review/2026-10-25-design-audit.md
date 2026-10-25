# Design Audit, 2026-10-25

Range: `3cc54b4..99be251`, **seventeen commits**: v1.58.0 through v1.59.4, including the v1.59.0
revert and reland pair. Previous report: `review/2026-10-20-design-audit.md`, which audited
`88f58d1..3cc54b4`. `review/declined.md` has no rows, so no finding matches a decline.

The window is large and the payload delta is concentrated in four changes: the five-step type scale
(v1.59.0), `scrollbar-gutter` (v1.58.2), the bar-chart width (v1.58.3), and the table edge shadow
(v1.59.2, extended to the base rule in v1.59.3). `highlight.js` also entered this skill's audit
scope in the same window, with no payload change of its own.

Method: headless Microsoft Edge (Chromium 153) on macOS, local `file://`, CDN reachable. Narrow
viewports were driven through sized iframes with `--allow-file-access-from-files`, because headless
Chromium clamps the minimum window width to about 492 CSS pixels. Print rules were exercised with the
repo's own media-rewrite technique (`@media print` rewritten to `@media all`), because Playwright is
not installed here and CDP media emulation was unavailable. All numbers are unthrottled lab data.
`nu scripts/maintain.nu check` printed `Contract OK` on `HEAD` and on the patched worktree.

## Step 2: Delta

| Change | NOTES.md documents it | Obeys AGENTS.md | Obeys a settled decision | A fixture renders it |
| --- | --- | --- | --- | --- |
| Five type steps, rem-based small sizes (v1.59.0) | Yes, Type scale, but see D3 and D4 | Pass, no comments added | Hierarchy regressed, D3 | Yes, every fixture |
| `html { scrollbar-gutter: stable both-edges }` (v1.58.2) | Yes, Odds and ends, but the claim is false, D2 | Pass | **Violation, D2** | Yes, document-wide |
| `table.bar-chart { display: table; inline-size: 100%; table-layout: fixed }` (v1.58.3) | Yes, Tables | Pass | Pass | `samples/dark-charts.html`, search `class="bar-chart"` |
| Four-layer table edge shadow on `table` and `.table-scroll` (v1.59.2, v1.59.3) | Yes, Tables | Pass | Pass on screen, **print gap D1** | Every table |
| Docs sync: thirteen files, forty-one requirements, highlight.js in scope (v1.59.4) | n/a | Pass | n/a | n/a |
| `highlight.js` copy button in audit scope | Yes, Markdown coverage | Pass | See D6 | Yes, `samples/dark.html` |

**D1 (Violation, in patch): print does not clear the table edge shadow on the base `table` rule.**
`NOTES.md`, Tables: "The layers sit on the base `table` rule, which is the scroll container for
every table, and on `.table-scroll`. Print turns them off with the rest of the container." The print
block resets `.table-scroll` only. A probe with print rules forced live measured `#t1` (a bare
`table`) still carrying all four background layers while `#ts` (`.table-scroll`) computed `none`.
Because print drops background graphics by default the shadow usually does not reach paper, but a
consumer who enables background printing gets the cue on one path and not the other. The patch adds
`table { background: none; }` beside the existing `.table-scroll` reset. After the patch both compute
`none`.

**D2 (Violation of a settled decision, no patch, needs sign-off): `scrollbar-gutter: stable
both-edges` narrows rendered prose.** `NOTES.md`, Odds and ends: "It changes no measure: `--page-width`
and `--gutter` keep their values, and it can only narrow the frame, never the prose inside it." A
head-to-head render of `samples/dark.html` with and without that one declaration:

| Viewport | Body width with gutter | Body width without | Left/right margins with | Left/right without |
| --- | --- | --- | --- | --- |
| 320 px | 261.0 | 276.2 | 29.5 / 29.5 | 14.4 / 29.5 |
| 1280 px | 1125.0 | 1152.0 | 77.5 / 77.5 | 56.5 / 77.5 |

The gutter buys a centred frame and pays 15.2 to 27 px of running prose. That is the trade the
declaration makes, and it contradicts the sentence above and the NON-NEGOTIABLE wide-measure rule in
`AGENTS.md`. **No patch accompanies this finding.** Removing the gutter reverses the v1.58.2 centring
decision and restores the asymmetric page; compensating in the width formula adds the second width
convention `AGENTS.md` forbids. Either direction is the maintainer's call. This is a violation, not
a challenge: the wide-measure decision still stands and the shipped declaration broke its stated
invariant.

**D3 (New ground, no patch): the five-step collapse inverts the heading hierarchy.** Rendered at a
1272 px window with the real stylesheet:

| Level | Computed size | Weight | Color |
| --- | --- | --- | --- |
| h1 | 32.03 px | 400 | `--pink` |
| h2 | 21.97 px | 400 | `--purple` |
| h3 | 18.31 px | 500 | `--label` |
| h4 | 18.31 px | 600 | `--label` |
| h5 | 18.31 px | 500 | `--label` |
| h6 | 18.31 px | 500, italic | `--label` |

h3 and h4 now share size and color, so h4 renders **heavier** than its parent level. h3 and h5 are
identical except for their margins. Before v1.59.0, h3's 1.12em size carried the distinction while
h4 stayed at body size; collapsing h3 to 1em removed it. NOTES.md records no decision for the new
relationship. There is no mechanical fix that does not reopen a settled decision: raising h3 to 600
makes h3 and h4 identical, lowering h4 to 500 makes h4 and h5 identical, restoring 1.12em adds a
sixth step, and moving h3 to `--on-surface` reverses the explicit "h3/h4 stay at `--label`" entry.
This needs a maintainer design decision.

**D4 (Doc drift, in patch): NOTES.md states a close-glyph size the stylesheet does not use.**
`NOTES.md`, Type scale, lists "the zoom overlay's close glyph" under `0.8125rem`. The glyph is
`.mermaid-overlay::after`, which renders at `1.75rem`; `blockquote.pull::before` renders at `2.5em`.
The paragraph above the block also claimed "five steps and no other size", which those two marks
contradict. The patch changes that to "five text steps" and states the two decorative marks outside
the scale. No measurement narration is added.

**D5 (Observation, no patch): the edge shadow sits under a classic vertical scrollbar.** In
`.table-scroll`, a classic vertical scrollbar occupies the right edge and paints over most of the
16 px `--rule` shadow. Measured in headless Edge: with a vertical scrollbar the right edge sampled
surface; with only a horizontal scrollbar the right shadow appeared at the same point. On
overlay-scrollbar platforms the shadow shows as designed. This is not a defect, because on those
platforms the scrollbar is itself the cue the shadow exists to replace on touch.

**D6 (Candidate, no patch): the copy confirmation has no live region.** `highlight.js` changes the
focused copy button's `aria-label` to "Copied" for 1.5 seconds. That is a visible and accessible
name change, but it is not a `role="status"` message and no live region is involved. Whether an
assistive technology announces it is unverified; this run had no screen reader. It is reported as a
candidate gap under 4.1.3, not as a confirmed violation, and it is left out of the patch because the
robust fix is a hidden status element, which is a new component rather than a one-attribute change.

**Previous report claims re-checked.** The previous report's D1 (`role="img"` and `aria-label` on
every `span.hm`) and D2 (the `.hm` and `.layer-end` grounds in NOTES.md) are both present in the
payload and the fixture. The previous Baseline table dated `color-mix()` at "Newly 2023-05-09,
Widely 2025-11-09"; MDN's badge currently reads "Widely available" with "available across browsers
since May 2023", while the web-features dataset behind that badge lists Widely 2025-11-09. The two
sources disagree on which milestone the May 2023 date belongs to. This report cites MDN's badge and
notes the web-features date rather than treating the earlier table as wrong.

## Topic 1: Color and Contrast

- **[Reinforces]** No new color token. The new table shadow is `color-mix(in oklab, var(--rule) 35%,
  transparent)`, a decorative edge over `--surface`; no text sits on it. The bar-chart band and
  `.hm` grounds were gated or documented in the previous window.
- **[Reinforces]** `oklch()` is Baseline Widely available, Newly 2023-05-09 and Widely 2025-11-09.
  `color-mix()` carries MDN's Widely badge (May 2023 by its banner) and web-features' Widely
  2025-11-09. Neither is a payload question.
- **Palette gate:** `python3 .github/palette-check.py` printed `Palette OK (17 tokens, 4 modes)`.
  The forced-colors block still borders `.hm` and every table.

### Searched

WebSearch: "MDN oklch() Baseline widely available date". WebFetch:
[MDN `color-mix()`](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix),
access 2026-10-25.

## Topic 2: Typography

- **[New ground]** The five-step collapse is documented, but its heading consequence is D3. The
  small steps are `rem`, the heading steps `em`, and `pre code` still halts compounding.
- **[Violation of the recorded text]** D4: NOTES.md assigns the zoom close glyph to the small step.
- **[Reinforces]** Current fluid-type guidance still prefers a user-negotiated clamp with `rem` or
  `em` bounds and only a small `vw` addition. The body clamp is `clamp(1rem, 0.95rem + 0.25vw,
  1.25rem)`, a 1.25 ratio, inside the 2 to 2.5 ratio guidance, so 1.4.4 has margin even though the
  middle term is viewport-relative.
- **[Reinforces]** `text-wrap: balance` remains on `h1` to `h3` only, matching the recorded reason.

### Searched

WebSearch: "web.dev fluid typography clamp CSS 2026 guidance". Sources: [Responsive and fluid
typography with Baseline CSS features](https://web.dev/articles/baseline-in-action-fluid-type),
[web.dev Typography](https://web.dev/learn/design/typography), access 2026-10-25.

## Topic 3: Layout and Spacing

- **[Violation, D2]** `scrollbar-gutter` narrows the prose measure at every tested width.
- **[Reinforces]** No second width convention, no breakpoint override, no prose cap was added.
  `.table-scroll` and the base table rule keep their full width.
- **[New ground]** `table.bar-chart` fills the measure with `inline-size: 100%` and a fixed layout.
  At 320, 375, 768 and 1280 px on `samples/dark-charts.html` it produced no page overflow and no
  table overflow. The only 320 px overflow was `table.evidence-table` inside its own scroll hatch
  (scrollWidth 287 against clientWidth 261), which is the documented table behaviour.
- **[Reinforces]** The edge shadow renders as recorded. Pixel probe at 320 px: at scroll start the
  left edge sampled `#282A36` (surface) and the right edge `#2C2E3B` to `#313341` (shadow); at
  scroll end the left edge sampled `#4C5064` to `#474A5D` and the right edge cleared. D5 records
  the classic-scrollbar overlap.

### Searched

WebSearch: "MDN scrollbar-gutter Baseline newly available date", "MDN container queries :has()
Baseline widely available dates 2026". WebFetch: [MDN
scrollbar-gutter](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/scrollbar-gutter).
Sources: scrollbar-gutter is Newly available 2024-12-11 (Safari 18.2), expected Widely about June
2027. Container size queries Widely 2025-08-14; `:has()` Widely 2026-06-19. Access 2026-10-25.

## Topic 4: Accessibility

- **[Candidate, D6]** The copy confirmation is not a live region.
- **[Reinforces]** Every `span.hm` in the generated fixture carries `role="img"` and an
  `aria-label` naming its state; the previous report's D1 is applied.
- **[Reinforces]** `.table-scroll` wrappers keep `tabindex="0"`, `role="region"` and a label, and
  `nu scripts/maintain.nu check` gates both the wrapper and the unwrapped `<table tabindex="0">`
  rule.
- **[Reinforces]** The heading hierarchy is a visual problem (D3), not a semantic one: the document
  outline still uses `h1` to `h6` in order.
- **APG:** no new hand-rolled grid or arrow-key behaviour was added. The heatmap continues to use a
  plain table, as recorded.

### Searched

WebSearch: "WCAG 3.0 Working Draft latest 2026 W3C". WebFetch: [W3C WCAG
2.2](https://www.w3.org/TR/WCAG22/), [W3C WCAG overview](https://www.w3.org/WAI/standards-guidelines/wcag/),
[AccessibleEU EN 301 549 news](https://accessible-eu-centre.ec.europa.eu/content-corner/news/new-version-en-301-549-standard-now-available-2026-09-07_en).
Access 2026-10-25.

## Topic 5: Interaction and Motion

- **[Reinforces]** No new `:hover` rule was added. All eleven hover rules sit inside the single
  `@media (hover: hover)` block at lines 506 to 518, and `maintain.nu check` gates that.
- **[Reinforces]** `@media (prefers-reduced-motion: reduce)` still zeroes transition and animation
  duration for all elements and pseudo-elements. The new table shadow has no transition.
- **[Reinforces]** Every transition remains `ease-out`, and press feedback still uses `scale` on the
  resting rule.

### Searched

WebSearch: "prefers-reduced-motion Baseline browser support MDN 2026". Sources: [MDN
prefers-reduced-motion](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion),
Widely available since January 2020 on MDN's banner; webstatus.dev lists 2020-01-15. Access
2026-10-25.

## Topic 6: Pinned Dependencies

| Package | Pinned | Registry current | Provenance |
| --- | --- | --- | --- |
| `mermaid` | 12.2.0 | 12.2.0 | attestation present |
| `@fontsource-variable/source-serif-4` | 5.3.1 | 5.3.1 | attestation present |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | attestation present |
| `@highlightjs/cdn-assets` | 11.12.0 | 11.12.0 | attestation present |

All four pins equal the current registry version, so no bump applies. `nu scripts/maintain.nu check`
reports "CDN pins are exact (6 URLs, 4 packages)". No `integrity` attribute can attach to an
`@font-face src: url()` or a bare-specifier remote ESM `import`, so the supply-chain question is the
npm attestation, which exists for all four. Self-hosting was weighed in NOTES.md and is not
re-argued here.

### Searched

Registry endpoint `https://registry.npmjs.org/<package>/latest` for the four packages, access
2026-10-25. `npm view` was attempted first and hung on this network, so the registry JSON was read
directly.

## Topic 7: Performance and Stability

- **Thresholds** (web.dev, [Web Vitals](https://web.dev/articles/vitals), accessed 2026-10-25): LCP
  at or below 2.5 s, INP at or below 200 ms, CLS at or below 0.1, at the 75th percentile, mobile
  and desktop separately.
- **Lab data:** not collected this run. **Field data:** unavailable. No public deployment was
  authorized and no CrUX data exists. **INP:** unavailable, and Total Blocking Time is not INP.
- **Render-blocking:** the stylesheet is inline. Fixtures load the two font families from jsDelivr
  with `font-display: swap` and Mermaid as an ES module; none of those blocks first paint of the
  inline CSS.
- **Layout shift:** the delta adds no image or embedded content. The heatmap squares are fixed, the
  bar-chart cells are text, and the edge shadow is a background. No new shift source.
- **CSS coverage:** not run. DevTools Coverage is unavailable in this headless setup, and a fixture
  cannot prove a consumer rule unused. Every selector added in the window has a fixture instance.

### Searched

WebFetch: [web.dev Web Vitals](https://web.dev/articles/vitals), access 2026-10-25.

## Standards status

Mapping only. This report claims no legal compliance.

| Area | Status as checked 2026-10-25 | Source |
| --- | --- | --- |
| WCAG Recommendation | WCAG 2.2, W3C Recommendation 2023-10-05, revised 2024-12-12. 86 active success criteria (4.1.1 removed). No newer Recommendation | [WCAG 2.2](https://www.w3.org/TR/WCAG22/) |
| WCAG 3.0 | Working Draft dated 2026-09-10. Content-model work continues; draft only, not a conformance standard | [WCAG 3.0](https://www.w3.org/TR/wcag-3.0/), [history](https://www.w3.org/standards/history/wcag-3.0/) |
| ISO/IEC 40500 | ISO/IEC 40500:2025, Edition 2.0, published 2025-09-24 as WCAG 2.2. ISO lifecycle stage 90.92 (to be revised) of 2026-02-05 | [W3C press release](https://www.w3.org/press-releases/2025/wcag22-iso-pas/), [IEC webstore](https://webstore.iec.ch/en/publication/109927) |
| EN 301 549 | V4.1.1 (2026-09), adopted 2026-08-24, DOA 2026-11-30. **Not cited in the Official Journal as of 2026-09-07**; V3.2.1 remains the legal reference until citation | [ETSI deliver](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/04.01.01_60/en_301549v040101p.pdf), [AccessibleEU](https://accessible-eu-centre.ec.europa.eu/content-corner/news/new-version-en-301-549-standard-now-available-2026-09-07_en) |
| Baseline definition | Baseline tiers and dates come from MDN and the web-features dataset. A Baseline tier is interoperability, not support on every device or with every assistive technology | [web.dev Baseline](https://web.dev/baseline) |

### Searched

WebSearch: "ISO/IEC 40500:2025 WCAG 2.2 published edition", "ETSI EN 301 549 V4.1.1 Official Journal
European Accessibility Act harmonised 2026", "WCAG 3.0 Working Draft latest 2026 W3C". Fetch:
W3C WCAG 2.2 (86 active criteria), W3C WCAG overview, AccessibleEU. All accessed 2026-10-25.

## Modern CSS Baseline review

| Feature | Baseline | Newly | Widely | Use in this stylesheet | Fallback or reason |
| --- | --- | --- | --- | --- | --- |
| Container queries | Widely | 2023-02-14 | 2025-08-14 | Used where NOTES.md records it | Settled |
| `:has()` | Widely | 2023-12-19 | 2026-06-19 | Used | Settled |
| Subgrid | Widely | 2023-09-15 | 2026-06-15 | Not used | No aligned sub-rows needed |
| `@layer` | Widely | 2022-03-14 | 2024-09-14 | Used | Settled |
| CSS nesting | Widely | 2023-12-11 | 2026-02-11 | Not used | Flat rules read better in an inlined file |
| `@scope` | Newly | 2026-03-24 | n/a | Not used | Needs an `@supports` fallback |
| `oklch()` | Widely | 2023-05-09 | 2025-11-09 | Used | Settled |
| `color-mix()` | Widely | 2023-05-09 | 2023-05 (MDN badge) / 2025-11-09 (web-features) | Used | Settled |
| `clamp()` | Widely | 2020-07-28 | 2023-01-28 | Used | Settled |
| Logical properties | Widely | 2021-09-20 | 2024-03-20 | Used, no physical sides | Settled |
| `aspect-ratio` | Widely | 2021-09-20 | 2024-03-20 | Used by `.hero` | Settled |
| Flexbox `gap` | Widely | 2021-04-26 | 2023-10-26 | Used | Settled |
| `scrollbar-gutter` | Newly | 2024-12-11 | expected 2027-06 | Used on `html` | No fallback; an older browser simply keeps the asymmetric frame |
| `dvh`/`svh`/`lvh` | Widely | 2017-10-17 | 2020-04-17 | Not used | No full-height layout |
| Scroll-driven animation | Not Baseline | n/a | n/a | Not used | No scroll effect wanted |
| View Transitions | Newly | 2025-10-14 | n/a | Not used | No navigation effect |
| `@starting-style` | Newly | 2024-08-06 | n/a | Not used | No entry animation |
| CSS Grid Lanes | Not Baseline | n/a | n/a | Not used | No masonry need |
| `sibling-index()`/`sibling-count()` | Newly | 2026-08-18 | n/a | Not used | No index needed |
| Anchor positioning | Not Baseline | n/a | n/a | Not used | No popover |
| `@property` | Newly | 2024-07-09 | n/a | Not used | No animated token |
| `content: "x" / "alt"` | Newly | 2024-07-09 | n/a | Used | Plain `content` declared first |
| Sticky positioning | Widely | 2019-09-19 | 2022-03-19 | Used | Static fallback is acceptable |
| `writing-mode` | Widely | 2017-03-27 | 2019-09-27 | Used | Headers stay legible if ignored |

Mobile-first authoring: the delta adds no media query and no breakpoint override. `table.bar-chart`
uses `inline-size: 100%` and a fixed layout, `scrollbar-gutter` is a frame declaration, and the
type scale uses `em`/`rem`. No conflict with a settled layout decision.

### Searched

Sources above plus [MDN `:has()`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/:has)
and [web.dev Baseline](https://web.dev/baseline), access 2026-10-25.

## Responsive usability sweep

`samples/dark.html` and `samples/dark-conn-map.html` at 320, 375, 768, 1024 and 1280 wide by 568,
768 and 900 tall (30 renders). Source: Edge, sized iframes, lab.

| Fixture | Width | Page `scrollWidth` / `clientWidth` |
| --- | --- | --- |
| `dark.html` | 320 | 290 / 305 |
| `dark.html` | 375 | 345 / 360 |
| `dark.html` | 768 | 738 / 753 |
| `dark.html` | 1024 | 994 / 1009 |
| `dark.html` | 1280 | 1250 / 1265 |
| `dark-conn-map.html` | all five | same as `dark.html` at each width |

Height changed no result in any of the 30 renders. No page-level horizontal overflow occurred.

Intentional overflow, measured at 320 px on `dark.html`: `pre` blocks (4, the widest 499 against
258), `table.tree` (304 against 261), three `.table-scroll` wrappers (502, 552 and 400 against 246),
and five `pre.mermaid` diagrams (426 to 1036 against 261). These are the documented hatches. They do
not make a long measure or a table an argument for narrowing prose.

**Interactive targets under 44 by 44 CSS px** (usability gap, separate from WCAG 2.5.8): 31 at 320,
32 at 375 and 768, 33 at 1024 and 1280 in `dark.html`; none in `dark-conn-map.html`. The 1280 set
is 28 anchors, two `summary` elements, two disabled task-list checkboxes (18.3 px) and one MathML
block. The anchors are inline links, heading permalinks and the outbound-link sentence. The delta
adds no new target; the copy button is 44 by 44 and is gated by `script-probe.py`.

Stacking: `.layer` still wraps name over cards in DOM order. Loading, error and empty states: this
template has none beyond the filter's no-match line, which is unchanged and driven by the script
probe. Visual hierarchy: D3 is the one regression; all other levels keep their order and weights.

## Accessibility tool and keyboard checks

**Not run:** interactive Tab, Shift+Tab, Enter, Space and Escape passes in each appearance mode; a
forced-colors render; and an automated accessibility tool. This session had a headless browser and
no interactive or assistive session, and Playwright is not installed. Nothing below is a pass for
keyboard or screen-reader behaviour.

What was checked instead:

- `nu scripts/maintain.nu check` passed, including the wrapper `tabindex` and `role` gates.
- `.github/script-probe.py` ran through the contract check and reported 44 binding assertions.
- The text-spacing override probe (`line-height: 1.5`, `letter-spacing: 0.12em`,
  `word-spacing: 0.16em`, paragraph spacing `2em`) produced no horizontal overflow at 320 or 1280
  (290 / 305 and 1250 / 1265), so 1.4.12 holds for `samples/dark.html`.
- Focus rules exist for every focusable pattern in the sheet: `a`, `summary`, `.filter-box`,
  `.mermaid-zoom`, `[tabindex="0"]` and `.copy-code`, each with a 2 px `--link` outline, raised to
  3 px under `prefers-contrast: more`.

## WCAG conformance sweep

Standard: WCAG 2.2, Recommendation 2023-10-05, revised 2024-12-12, 86 active criteria. "Delta" means
evidence from this run. "Prior" means last verified in the 2026-10-20 report and untouched by this
window. A "Prior" row is not re-verified here.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | Every `span.hm` has `role="img"` and a state label; Mermaid names are in `samples/dark-charts.html` |
| 1.3.1 Info and Relationships | A | Pass | Matrix and heatmap use `thead`, `th scope="row"` and band cells; wrappers keep table semantics |
| 1.3.2 Meaningful Sequence | A | Pass | `.layer` reads in DOM order; no delta reorder |
| 1.4.1 Use of Color | A | Pass | Heatmap states differ by shape; bars carry their numbers; the edge shadow is decorative |
| 2.1.1 Keyboard | A | Pass, not hand-tested | Table and wrapper stops are gated; no new control in the delta |
| 2.1.2 No Keyboard Trap | A | Prior | Zoom dialog unchanged; Escape path untouched |
| 2.4.2 Page Titled | A | Pass | Eight distinct `<title>` values checked in `samples/` |
| 2.4.3 Focus Order | A | Pass by DOM order, not hand-tested | No positive `tabindex`; wrappers follow their tables |
| 2.4.4 Link Purpose (In Context) | A | Pass | No bare "click here"; outbound arrow has empty alt text |
| 2.5.3 Label in Name | A | Pass | Zoom button keeps visible text as its label prefix; copy button is icon-only with a name |
| 3.1.1 Language of Page | A | Pass | `lang="en"` on every fixture |
| 3.2.1 On Focus | A | Pass | No focus handler changes context |
| 3.2.2 On Input | A | Pass | `filter.js` only hides rows and updates a status count |
| 4.1.2 Name, Role, Value | A | Pass | Wrapper `role="region"` and label are gated; copy and zoom buttons are native `<button>` |
| 1.4.3 Contrast (Minimum) | AA | Pass | `Palette OK (17 tokens, 4 modes)`; table shadow is non-text |
| 1.4.4 Resize Text | AA | Pass | Body clamp 1rem to 1.25rem, ratio 1.25; rem/em steps scale with the reader default |
| 1.4.10 Reflow | AA | Pass | No page overflow at 320 to 1280; wide tables and code scroll inside hatches |
| 1.4.11 Non-text Contrast | AA | Pass | Palette gate plus the prior `.hm` and `.layer-end` measurements; the delta adds no boundary |
| 1.4.12 Text Spacing | AA | Pass | Override probe at 320 and 1280 produced no horizontal overflow |
| 1.4.13 Content on Hover or Focus | AA | Prior | Header permalinks appear on hover and focus and persist while focused; no new hover content |
| 2.4.6 Headings and Labels | AA | Pass | New sections keep noun-phrase headings; D3 is visual only |
| 2.4.7 Focus Visible | AA | Pass by CSS, not hand-tested | Focus rules listed under keyboard checks |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Prior | `.table-scroll` keeps `scroll-padding-top: 3em` for the sticky header |
| 3.2.3 Consistent Navigation | AA | Prior | No repeated site navigation changed |
| 3.2.4 Consistent Identification | AA | Prior | No component identification changed |
| 2.5.7 Dragging Movements | AA | Not applicable | No dragging feature |
| 2.5.8 Target Size (Minimum) | AA | Pass | Copy and zoom buttons are 44 by 44 (gated). Header permalinks are about 7 by 17 with the spacing exception. Inline links use the inline exception. Disabled task-list checkboxes are the inactive-control exception. MathML is a scroll region |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step entry |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication |
| 4.1.3 Status Messages | AA | Pass for the filter; candidate gap D6 | `filter.js` writes the result count into `role="status"`. The copy confirmation changes a focused button's name and has no live region |

**Relevant AAA, tracked separately**

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Prior | Same evidence as 2.4.11 |
| 2.4.13 Focus Appearance | AAA | Not run | No focus rendering this run |
| 2.5.5 Target Size (Enhanced) | AAA | Not met | 31 to 33 targets in `dark.html` are under 44 px, all pre-existing prose links and summaries |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication |

Out of scope, stated once: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4, 3.1.2, and 3.3.1
to 3.3.6.

## Ungated-rules sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in any inlined payload file | Pass | `rg` returns line 2 only in the CSS and nothing in `mermaid.js`, `filter.js` or `highlight.js` |
| Every `var(--x)` resolves | Pass | The four unresolved names (`--bar`, `--icon-color`, `--natural-width`, `--timeline-date`) are consumer-supplied and documented in NOTES.md |
| Sides are logical, never physical | Pass | No `border-left`, `border-right`, `padding-left`, `padding-right`, `margin-left` or `margin-right` |
| Every `:hover` rule sits inside `@media (hover: hover)` | Pass | The block spans lines 506 to 518 and holds all eleven hover rules; also gated |
| Decorative pseudo-element content has an alt-text twin | Pass | Outbound arrow, tree branch, pull quote, layer arrow, overlay close mark and deep disclosure arrows all carry a `/ ""` twin |
| Selector represented in a fixture | Pass | `table.bar-chart`, the table shadow, `scrollbar-gutter` and `.table-scroll` all render in the fixtures |
| Mermaid colors are hex, never `oklch()` and never `var()` | Pass | `rg` finds neither in `mermaid.js` |
| Exact CDN pin, never a range | Pass | Six URLs, four packages, all exact; also gated |
| Never cite a line number into a generated file | Pass | `CONTRACT pointers resolve (48 search strings, 41 requirements)` |
| New composite grounds outside palette-check coverage have a NOTES.md entry | Pass | The window adds no text ground. The table shadow is a decorative edge, not a ground. The bar band and the `.hm` ground remain gated or documented |

No gate was added. The one mechanical gap the window exposed, the missing print reset for `table`,
is a one-line CSS fix and not worth a bespoke gate: a grep for that exact declaration would pin the
current formatting rather than the behaviour.

## Challenges a settled decision

None. D2 is a violation of the wide-measure decision, not a challenge to it; its only fixes reopen
the v1.58.2 centring decision, so it is reported above with no patch and requires maintainer
sign-off before any change.

## Out of Scope

NOTES.md sections Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo
layout, and Odds and ends beyond the `scrollbar-gutter` entry were not audited, by design.

## Verification

`Verified: patch applies to HEAD and Contract OK after regeneration.` The patch
(`review/2026-10-25-design-audit.patch`) changes `NOTES.md` and `tufte-dracula.css` only. It was
authored in a detached worktree at `HEAD`, fixtures were regenerated there with
`scripts/build-sample.nu`, and `nu scripts/maintain.nu check` printed `Contract OK`. The worktree is
removed. Added patch lines contain no `/*`, `*/` or comment marker, and no em-dash or en-dash. The
print probe was re-run against the patched stylesheet: `#t1` and `#ts` both compute
`background-image: none`, against `#t1` carrying the four layers before the patch.
