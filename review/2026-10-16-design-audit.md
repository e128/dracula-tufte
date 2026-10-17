# Design Audit, 2026-10-16

Range: `03c78db..88f58d1`, **one commit** (v1.56.0 to v1.57.0), plus one uncommitted working-tree
edit to `scripts/opencode-ollama.nu` (a developer launch script, not payload). Previous report:
`review/2026-10-14-design-audit.md`, which audited `5aa8e71..03c78db` plus the v1.57.0 work while it
was still uncommitted. `review/declined.md` has no rows, so no finding matches a decline.

This is a two-day window and the one commit is the work the previous report already reviewed as a
draft. The whole payload delta is: the sparkline (`span.spark`), small multiples (`div.multiples`),
the `xychart` theme, the pie theme removed, the film grain removed, `strong` loses its hue, the
light-mode chroma band, the focus-color cues removed, and two CDN pins bumped (Mermaid 12.2.0,
source-serif-4 5.3.1). **Both violations the previous report found in v1.56.0 are fixed in this
commit and shipped.** No new violation of a settled decision was found. No challenge is raised.

Method: headless Microsoft Edge 155.0.4283.60 (no Google Chrome is installed on this machine this
run), local `file://`, CDN reachable so Mermaid and the fonts render. Narrow viewports were driven
through sized iframes because old headless clamps the minimum window width to about 492 CSS pixels.
Lab results are unthrottled and labelled as lab data. A standards and npm pass gathered the sources
listed under each `### Searched` heading; items that could not be retrieved are marked unavailable.

## Step 2: Delta

The commit is the v1.57.0 work the previous report audited as a draft. Every added payload line was
read and answers the four Step 2 questions.

| Added line | NOTES.md entry | Obeys AGENTS.md | Rendered by a fixture |
| --- | --- | --- | --- |
| `.spark`, `.spark > i`, `.spark.fit` | Yes, Tufte's chart rules | Yes, no comment, logical sides | `samples/dark-charts.html`, search `class="spark"` |
| `.multiples`, `--multiples-label`, `> table + table` | Yes, Tufte's chart rules | Yes | `samples/dark-charts.html`, search `class="multiples"` |
| `xyChart` object, both Mermaid sets | Yes, Diagram types | Yes, hex only, no comment | `samples/dark-charts.html`, search `xychart` |
| Pie theme variables and `pie` init keys removed | Yes, CSS charts, "The pie was removed in v1.57.0" | Yes | `samples/dark-charts.html` |
| `body::before` grain removed | Yes, Tufte's chart rules, "The film grain was removed in v1.57.0" | Yes | Every fixture |
| `strong { font-weight: 600 }` (no `--orange`) | Yes, Paragraphs and section rhythm | Yes | `samples/dark.html`, search `<strong` |
| Light-mode chroma band (`--orange` 0.085, `--purple` 0.178, `--green` 0.105, `--link` 0.056) | Yes, Color and the contrast budget | Yes, `palette-check.py` check 5 and the band check pass | All fixtures |
| `nav.toc a:focus-visible`, `details.deep > summary:focus-visible` removed | Yes, Color and the contrast budget, "Focus is one cue everywhere, the `--link` outline" | Yes | `samples/dark.html` |
| Mermaid 12.2.0 pin, source-serif-4 5.3.1 pin | Not a decision, a pin | Yes, exact version | `mermaid.js`, `tufte-dracula.css` |

**Resolution of the previous report's two violations.** Both are fixed in HEAD, verified by render:

- **`.copy-code:hover` now sits inside `@media (hover: hover)`.** The block starts at
  `tufte-dracula.css` line 448 (search `@media (hover: hover)`), and `.copy-code:hover` is line 459,
  inside it. `nu scripts/maintain.nu check` now prints "Every :hover rule sits inside @media (hover:
  hover)", backed by the new `hover-guard` gate the last patch added.
- **`.copy-code` now uses logical margins** (`margin-block`/`margin-inline`). Probe render of the
  button inside a real `pre` against the real stylesheet body, inline-end distance from the `pre`
  edge to the button: **LTR 16px, RTL 16px** (was RTL 24px before the fix).

No other source line was added since the previous report. Nothing in this delta contradicts a
NOTES.md passage.

**Re-check of the previous report's own claims.** Its Step 2 tables and its two violations are
correct against this delta. Its Mermaid "latest 12.2.0" figure is now the pinned version. Its CSS
coverage note (the Chrome rule-usage tracker reported every rule used) stands; this run did not
re-run it, see Topic 7.

## Topic 1: Color and Contrast

`palette-check.py` passes: 17 tokens, 4 modes. The light-mode band this commit adds holds `--orange`,
`--purple`, `--pink`, `--green` and `--link` to 55 to 65 percent of their ceiling, and `check 5`
still passes every floor. Reinforces: OKLCH tokens, hex-only Mermaid. The new `xyChart` backgrounds
(`#282a36` dark, `#fcfcf8` light) and axis colors are projections of the same tokens and are read by
the existing key-by-key gate. **Repeat, unchanged since 2026-09-30:** `nav.toc` is still the one
named ground outside the gate.

### Searched

- `api.webstatus.dev/v1/features/{oklab,color-mix,relative-color}`, 2026-10-16. `oklab` and
  `color-mix` Widely available since 2025-11-09; relative color syntax Newly available since
  2024-09-16.

## Topic 2: Typography

No type decision changed. `strong` now carries weight 600 with no hue, which matches the "emphasis by
weight" form and removes the orange that read as a caution beside `.unverified`. `text-wrap: pretty`
stays limited availability and is used only where a fallback is harmless. **Repeat, unchanged since
2026-09-30.**

### Searched

- webstatus `text-wrap-balance` (Newly, 2024-05-13), `text-wrap-pretty` (limited), 2026-10-16.

## Topic 3: Layout and Spacing

The sweep below measured 45 combinations with no page overflow. `.multiples` stacks in DOM order and
its later panels take `margin-inline-start`, which is logical and survives RTL. The `.recent-group`
container query added last window is scoped to one component and does not repeat the `article`
containment mistake NOTES.md records. The wide measure was not examined. AGENTS.md closes it.

### Searched

- webstatus `container-queries` (Widely 2025-08-14), `has` (Widely 2026-06-19), `subgrid` (Widely
  2026-03-15), `cascade-layers` (Widely 2024-09-14), `nesting` (Widely 2026-06-11), `scope` (Newly
  2026-03-24), `masonry` (limited), 2026-10-16.

## Topic 4: Accessibility

See the WCAG sweep and the keyboard checks. **Maintainer instruction, 2026-10-14: screen-reader
support is out of scope for this repo.** This report still measures it where a criterion asks, and
does not propose a screen-reader-only fix. The one such gap is under 1.1.1. Contrast, keyboard and
focus findings are unaffected.

### Searched

- W3C WCAG standards page and TR index, 2026-10-16 (see Standards status).

## Topic 5: Interaction and Motion

The `live-dot` pulse is finite and `prefers-reduced-motion` forces a single 0.01ms iteration, as
NOTES.md records. The focus-color cue on `nav.toc a` and `details.deep > summary` is gone, which
matches "Focus is one cue everywhere, the `--link` outline; hover may add a color, but focus adds
none." Every `:hover` rule sits inside the guarded block, gated. **Repeat, unchanged since
2026-10-14:** no hover or press decision is challenged.

### Searched

- No new query. `@starting-style` (Newly 2024-08-06) and View Transitions (Newly 2025-10-14) are not
  used and nothing requires them.

## Topic 6: Pinned Dependencies

Read from the files, not from memory: Mermaid `12.2.0` in `mermaid.js`, `@highlightjs/cdn-assets`
`11.12.0`, `@fontsource-variable/source-serif-4` `5.3.1` and `@fontsource-variable/jetbrains-mono`
`5.3.0` in `tufte-dracula.css`, and `highlight.min.js` in the generator.

| Package | Pinned | Latest on npm | Latest modified | Verdict |
| --- | --- | --- | --- | --- |
| `mermaid` | 12.2.0 | 12.2.0 | 2026-10-13 | Current. Bumped in this commit, ahead of the previous report's wait-until 2026-10-27 note; a maintainer decision, not a NOTES.md decision, so no finding |
| `@highlightjs/cdn-assets` | 11.12.0 | 11.12.0 | 2026-08-12 | Current. Bumped in this commit; the previous report had it as eligible |
| `@fontsource-variable/source-serif-4` | 5.3.1 | 5.3.1 | 2026-10-11 | Current |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | 2026-07-19 | Current |

All four are the latest release. No bump is proposed, and a Mermaid bump is never in the patch in any
case (`nu scripts/maintain.nu mermaid <version>` is the supported path and it touches generated
files).

**Provenance.** `@font-face src: url()` and a bare-specifier `import` of a remote URL have no
`integrity` hook, so no SRI attribute can attach to any of these URLs. The npm packages do carry
SLSA v1 provenance attestations (`npm view <pkg> dist.attestations`), checked for the pinned versions
this run. NOTES.md already weighed self-hosting, so it is `[Repeat]` and not proposed.

### Searched

- `npm view <pkg> version time.modified dist.attestations` for the four packages, 2026-10-16.

## Topic 7: Performance and Stability

Core Web Vitals thresholds, `web.dev/articles/vitals` and
`web.dev/articles/defining-core-web-vitals-thresholds` (accessed 2026-10-16): LCP at or below 2.5 s,
INP at or below 200 ms, CLS at or below 0.1, each at the 75th percentile and split by mobile and
desktop. Unchanged this run. LCP and INP became Baseline Newly available on 2025-12-12 (Safari 26.2);
CLS is still Chromium-only to measure.

**Field data: unavailable.** No public deployment was queried, no CrUX data exists for these
fixtures, and `web-vitals` is not added to the template. **INP: unavailable. Total Blocking Time is
not INP.**

**Lab data was not recollected this run.** The previous report's lab result stands as the last
measurement: `samples/dark-charts.html` recorded CLS 0.2215 in lab, caused by the web-font swap, not
Mermaid, with `font-display: swap` and no metric-adjusted fallback recorded in NOTES.md, Fonts.
**Repeat, unchanged since 2026-10-14, design judgment, no patch:** a metric-matched fallback needs
per-platform metrics the stylesheet cannot read.

Render-blocking: the stylesheet is inline, so there is no stylesheet request. The fixtures request
two variable-font files, the Mermaid module and its chunks, and `highlight.js` from jsDelivr; the
module scripts are deferred by `type="module"`. Images in `samples/dark.html` carry `alt` and the
larger one an `aspect-ratio` (`21 / 9`), so its box is reserved. No ad slot exists, so ad shift is not
applicable.

**CSS coverage: not reported.** The previous run found the Chrome rule-usage tracker reported every
rule as used, which cannot be right for a sheet with print, forced-colors and RTL branches. A result
that cannot fail is not evidence. No coverage candidate is listed this run either.

### Searched

- `web.dev/articles/vitals`, `web.dev/articles/defining-core-web-vitals-thresholds`, 2026-10-16.

## Standards Status

Accessed 2026-10-16. This report maps technical criteria only and does not claim legal compliance.

| Area | Finding | Source |
| --- | --- | --- |
| WCAG Recommendation | **WCAG 2.2 is the newest version.** Published 2023-10-05, updated 2024-12-12. The W3C page was updated 2026-09-17. WCAG 2.1 also had an update on 2025-05-06. No WCAG 2.3 and no newer Recommendation exists | `w3.org/WAI/standards-guidelines/wcag/`, `w3.org/TR/` |
| WCAG 3.0 | Working Draft dated **2026-09-10**, Recommendation track, "may be updated, replaced, or obsoleted". No newer draft than the previous audit. Draft information only | `w3.org/TR/wcag-3.0/` |
| ISO/IEC 40500 | W3C states WCAG 2.2 is approved as **ISO/IEC 40500:2025**, identical to the October 2023 WCAG 2.2. W3C expects the December 2024 revision as ISO/IEC 40500:2026 "by late 2026", so it is **not yet published**. The iso.org catalog was not read; the approval date comes from the W3C page | W3C WCAG page |
| EN 301 549 | W3C states **the 2026 version of EN 301 549 uses WCAG 2.2**. **Harmonisation and Official Journal citation: not confirmed, no OJ record retrieved.** Do not infer harmonisation from publication | `w3.org/WAI/standards-guidelines/wcag/`, `etsi.org/technical-groups/hf/` |
| Baseline | Newly available means supported in every core browser. Widely available means 30 months after that date. Core set: Chrome and Edge, Firefox, Safari. LCP and INP became Newly available 2025-12-12 (Safari 26.2) | `web.dev/baseline` |

### Searched

- The five sources above, 2026-10-16.

## Modern CSS Baseline Review

Source for every row: `api.webstatus.dev/v1/features/<id>`, 2026-10-16, unless marked. Newly
available features need an `@supports` fallback unless current consumer needs make it unnecessary.

| Feature | Baseline | Newly available | Widely available | Use in this stylesheet | Fallback or reason |
| --- | --- | --- | --- | --- | --- |
| Container queries | Widely | 2023-02-14 | 2025-08-14 | `.scorecard`, `.recent-group` | None needed |
| `:has()` | Widely | 2023-12-19 | 2026-06-19 | `.edge-list:has(> div:only-child)` | None needed |
| Subgrid | Widely | 2023-09-15 | 2026-03-15 | Not used | No need |
| Cascade layers | Widely | 2022-03-14 | 2024-09-14 | Whole sheet in one layer | None needed |
| Native nesting | Widely | 2023-12-11 | 2026-06-11 | Not used | No need |
| `@scope` | Newly | 2026-03-24 | n/a | Not used | Would need `@supports`. No need |
| OKLCH, `color-mix()` | Widely | 2023-05-09 | 2025-11-09 | Tokens and mixes | None needed |
| Relative color syntax | Newly | 2024-09-16 | n/a | Eight declarations, NOTES.md records no fallback by decision | Accepted, the decision is stated |
| `clamp()` | Widely | (id not resolved this run) | n/a | Body size, rail width | None needed |
| Logical properties | Widely | 2021-09-20 | 2024-03-20 | Throughout, no remaining exception | None needed |
| `aspect-ratio` | Widely | 2021-09-20 | 2024-03-20 | `.hero > img` | None needed |
| Flexbox `gap` | Widely | 2021-04-26 | 2023-10-26 | Used | None needed |
| `dvh`, `svh`, `lvh` | Widely | 2022-12-05 | 2025-06-05 | `100dvh` on the rail | None needed |
| Scroll-driven animations | Limited | n/a | n/a | Not used | Not Baseline |
| View Transitions | Newly | 2025-10-14 | n/a | Not used | No need |
| `@starting-style` | Newly | 2024-08-06 | n/a | Not used | No need |
| CSS Grid Lanes | Limited | n/a | n/a | Not used | Not Baseline |
| `sibling-index()`, `sibling-count()` | Newly | 2026-08-18 | n/a | Not used | No need |
| Anchor positioning | Limited | n/a | n/a | Not used | Not Baseline |
| `@property` | Not rechecked | n/a | n/a | Not used | webstatus returned 404 for `at-property`, `property`. Previous audit recorded Newly 2024-07-09. Not Baseline-critical here |
| `text-wrap: balance` | Newly | 2024-05-13 | n/a | `h1` | Fallback is harmless wrapping |
| `text-wrap: pretty` | Limited | n/a | n/a | Paragraphs where a fallback is harmless | Not Baseline |

Mobile-first authoring: evaluated as current practice and not adopted as a reversal of settled layout
decisions. The single-width decision stays.

## Responsive Usability Sweep

`samples/dark.html`, `samples/dark-conn-map.html` and `samples/dark-charts.html`, each at 320, 375,
768, 1024 and 1280 CSS pixels wide and 568, 768 and 900 tall: **45 combinations,
`scrollWidth` equal to `clientWidth` in all 45, no page-level overflow.** Mermaid rendered in each
(5, 2 and 17 SVGs). An RTL pass of the charts fixture at 320, 768 and 1280 also showed zero
overflow, so the new `.multiples` and `.spark` logical rules hold in a right-to-left page. Nothing in
the sweep narrows prose or changes `--page-width`.

Interactive targets, measured from rendered rectangles:

| Fixture | Viewport | Targets | Under 44 px | Under 24 px | Notes |
| --- | --- | --- | --- | --- | --- |
| `dark.html` | 1280 | 70 | 41 | 12 | All under 24 are inline links (20px) or revealed heading anchors |
| `dark.html` | 320 | 70 | 39 | 15 | Same, inline links |
| `dark-charts.html` | 1280 | 23 | 23 | 8 | Under 24 are inline links at 20px |
| `dark-conn-map.html` | 1280 | 8 | 2 | 0 | Mermaid zoom button |

**44 x 44 usability gap, reported separately from WCAG:** the Mermaid zoom button (about 134x42),
the copy button (36x36, NOTES.md already records "below the 44px usability target"), and 20 to 29px
high nav and inline links. **WCAG 2.5.8 (24x24): Pass.** The only sub-24 targets are inline links
within a sentence of non-target text, covered by the inline exception, and disabled task-list
checkboxes, covered by the inactive exception.

Heading order has no skip in any fixture, each has one `h1`, and every `<title>` is distinct. No
loading, error or empty state exists in the fixtures except the filter's empty line, which
`script-probe.py` asserts.

## Accessibility Tool and Keyboard Checks

No automated accessibility tool was run (no Axe or WAVE package is installed). Programmatic checks
via headless Edge 155, `samples/dark.html`, `light.html`, `dark-charts.html`, `light-charts.html`,
`dark-conn-map.html`, `dark-timeline.html`:

| Check | Result |
| --- | --- |
| Focus indicator | Every focusable element has a computed outline or box shadow: dark 79, light 80, charts 31 and 32, conn-map 8, timeline 75. No element lacked one in dark or light |
| `lang` and title | `lang="en"` and a distinct `<title>` in every fixture |
| Heading order | One `h1`, no skip in any fixture |
| Images | Every `img` has `alt`; the tile image carries `aspect-ratio: 21 / 9` |
| Mermaid SVG titles | `dark-charts.html` and `light-charts.html`: 6 of 17 SVGs have no `<title>` (Mermaid does not emit one for those diagram types). `dark.html` and `dark-conn-map.html`: 0 missing. Accepted gap, screen-reader support out of scope |
| Filter status | `dark.html` has one `[role="status"]`; `role="status"` implies `aria-live="polite"`, so no explicit attribute is required |

**Mode coverage limit:** `prefers-contrast: more` and `forced-colors: active` could not be emulated
this run (no Playwright or CDP driver is installed and no Google Chrome is present). Their focus and
contrast rules were read in `tufte-dracula.css`, not rendered. This is a tooling gap, stated rather
than reported as a pass. The interactive keyboard walkthrough (Tab, Shift+Tab, Enter, Space, Escape)
was also not driven this run for the same reason; the previous report's walkthrough stands as the
last interactive check.

## WCAG Conformance Sweep

WCAG 2.2 (Recommendation, revised 2024-12-12), checked 2026-10-16. No newer criteria exist.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Accepted gap, partly | Both images carry `alt`. Six of the Mermaid SVGs in `dark-charts.html` carry no `<title>` even though every fence has an `accTitle`; Mermaid does not emit one for those types. Maintainer said screen-reader support is out of scope |
| 1.3.1 Info and Relationships | A | Pass | Tables carry captions and header cells. No heading skips |
| 1.3.2 Meaningful Sequence | A | Pass | The connections-map reorder and the grid stack follow DOM order |
| 1.4.1 Use of Color | A | Pass | Verdict badges spell the status. The sparkline end column is neutral and every value is text in the cell |
| 2.1.1 Keyboard | A | Pass | 79 and 31 tab stops; zoom dialog operable (previous walkthrough) |
| 2.1.2 No Keyboard Trap | A | Pass | Escape leaves the dialog and focus returns (previous walkthrough) |
| 2.4.2 Page Titled | A | Pass | Six distinct titles |
| 2.4.3 Focus Order | A | Pass | Tab order follows DOM order |
| 2.4.4 Link Purpose | A | Pass | No bare "click here". Outbound arrow has an alt twin |
| 2.5.3 Label in Name | A | Pass | The zoom button's visible text is a prefix of its name |
| 3.1.1 Language of Page | A | Pass | `lang="en"` in every fixture |
| 3.2.1 On Focus | A | Pass | No focus change triggers a context change |
| 3.2.2 On Input | A | Pass | The filter updates a count only |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step process |
| 4.1.2 Name, Role, Value | A | Pass | Zoom button and dialog are named. Task-list checkboxes are native and disabled |
| 1.4.3 Contrast (Minimum) | AA | Pass | `palette-check.py`, 17 tokens in 4 modes. Ground not reached by the gate: `nav.toc`, named above |
| 1.4.4 Resize Text | AA | Pass | 320 px reflow passes with no overflow, the layout a 400 percent zoom produces |
| 1.4.10 Reflow | AA | Pass | 45 combinations, `scrollWidth` equals `clientWidth` |
| 1.4.11 Non-text Contrast | AA | Pass | Focus rings use `--link`, the borders use `--rule`. Both are in the palette gate |
| 1.4.12 Text Spacing | AA | Pass | Previous override test stands; no layout change this window |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content |
| 2.4.6 Headings and Labels | AA | Pass | Descriptive headings, labelled filter |
| 2.4.7 Focus Visible | AA | Pass | Every stop has an outline or shadow in dark and light |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Pass | Previous walkthrough found no focused control fully hidden |
| 2.5.7 Dragging Movements | AA | Not applicable | No dragging feature |
| 2.5.8 Target Size (Minimum) | AA | Pass | Under-24 targets are inline links or disabled checkboxes |
| 3.2.3 Consistent Navigation | AA | Pass | Repeated `nav` keeps its order |
| 3.2.4 Consistent Identification | AA | Pass | Zoom and copy buttons are identified the same way everywhere |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication |
| 4.1.3 Status Messages | AA | Pass | The filter's `role="status"` exists in `dark.html` and `script-probe.py` asserts it |

Relevant AAA, tracked separately:

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Not measured | The run tested for fully hidden controls only, not for any hidden part |
| 2.4.13 Focus Appearance | AAA | Not measured | Indicator area and contrast change were not computed |
| 2.5.5 Target Size (Enhanced) | AAA | Not met | The 44 px gaps listed under the responsive sweep |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication |

Out of scope, stated once: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4, 3.1.2 and 3.3.1
through 3.3.6.

## Ungated-Rules Sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in the inlined files | Pass | `tufte-dracula.css` shows line 2 only, outside the `was #` notes. `mermaid.js` has none |
| Every `var(--x)` resolves | Pass | No undeclared reference without a fallback. The fallbacked component tokens (`--bar`, `--h`, `--icon-color`, `--natural-width`, `--timeline-date`) are deliberate |
| Sides are logical | Pass | The longhand grep is empty; the `.copy-code` shorthand is now `margin-block`/`margin-inline` |
| Every `:hover` is inside `@media (hover: hover)` | Pass, gated | Lines 449 to 459 sit inside the block at 448. `hover-guard` now in `check` and in the workflow |
| Decorative pseudo content has an alt twin | Pass | Every string-valued `content` has a `/ ""` twin or is empty |
| Selector with no fixture instance | Candidates only | 61 of 220 class selectors appear in no fixture markup: highlighter and Pygments token classes (consumer input, NOTES.md Markdown coverage), `copy-code` and `filter-hidden` (injected at runtime by `highlight.js` and `filter.js`). `jsdelivr`, `woff2` are URL fragments matched by the class pattern, not selectors. None is proposed for removal |
| Mermaid colors are hex | Pass | No `oklch` or `var(` in `mermaid.js` |
| Exact CDN pin | Pass, gated | Six URLs, four packages, each exact. `cdn-pins` now in the workflow |
| No line number into a generated file | Pass | `check` resolves 45 search-string pointers |
| New composite grounds covered | Pass | The sparkline end column is `--on-surface` on `--surface`; the `xyChart` backgrounds are gate projections. `check 5` covers them |

## Challenges a Settled Decision

None.

## Out-of-Scope Sections

Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo layout, and Odds
and ends were not audited, as the skill defines. The chart and Spark/Multiples entries were read only
to answer Step 2's documentation questions.

## Patch and Verification

**No patch: nothing to propose.** Every candidate was either a repeat, a Pass, or a documented
decision, and the two violations the previous report carried were fixed by the v1.57.0 commit. Step 7
is skipped because Step 6 wrote no patch.

`nu scripts/maintain.nu check` (Edge supplied through `$CHROME`) runs in the maintainer's tree
without changes and concludes cleanly: Palette OK (17 tokens, 4 modes), CONTRACT pointers resolve
(45 search strings, 37 requirements), Markdown anchors resolve (70 links, 24 files), Mode renders OK
(12 images), Script binding OK (40 assertions), generated files fresh, themes fresh, no em-dash or
en-dash, every hover rule guarded, CDN pins exact, then **`Contract OK`**, exit 0. No generated file
was modified by this audit.

## Follow-up: fixes applied after this report

The maintainer asked for three of the recorded findings to be fixed, and for the `scripts/` Nushell
files to be optimized. Those changes are on branch `fix/audit-2026-10-16`. This section records
them; it is not part of the audit window.

| Finding | Change | Verification |
| --- | --- | --- |
| `nav.toc` composite ground outside the palette gate | New check 14 in `.github/palette-check.py` reads the mix fraction and token out of the rule and re-derives the composite in every mode | Passes all four modes (light `--muted` at 4.83:1 is the tightest against its 4.5 floor). The model reproduces the rendered pixel (`#22232e` in dark, measured on a canvas). Mutated to point the ground at `--rule-light`: the check fails, then the file reverts |
| 1.1.1 SVG-title gap | `mermaid.js` reads `accTitle`/`accDescr` off each fence before render and injects an SVG `<title>`/`<desc>` only when Mermaid left none, so `xychart`, `kanban` and `timeline` gain the name the other types already emit | All 14 charts-fixture diagrams and all 5 `dark.html` diagrams now carry a `<title>`; zoom buttons read the diagram name. New probe assertion `fidelity-diagrams-named` failed before the shim and passes after |
| 44 by 44 target gap | `.copy-code` is `2.75rem` square and `.mermaid-zoom` carries `min-height: 44px` | Rendered: copy button 44 by 44 in LTR and RTL; zoom button 134 by 44. New probe assertions `copy-buttons-meet-44` and `zoom-buttons-meet-44` fail at the old sizes and pass at the new. The heading permalinks stay glyph-sized on the recorded spacing exception |
| `scripts/` optimization | `claude-ollama.nu` drops the hand-rolled arg parser and redundant locals (mirrors `opencode-ollama.nu`); `maintain.nu`'s `dash-files` runs one `rg` over all tracked files instead of one per file; `markdown-links-ok` reads each markdown file once; `build-sample.nu`'s `preview` drives one rewrite list for both the check and the replacement | Regenerating with the HEAD generator and with the refactored generator is byte-identical; `dash-files` returns `[]` clean and detects a tracked em-dash file; `Contract OK` |

`nu scripts/maintain.nu check` (Edge via `$CHROME`) prints `Contract OK`, exit 0, with 43 probe
assertions. NOTES.md records the new check 14, the Mermaid shim, and the two target sizes, each with
its prohibition.

## Counts

Findings: 6. Violations of a settled decision: 0 (the previous report's two are fixed and shipped,
reported as resolved, not as new findings). New ground: 0. Challenges: 0. Repeats: 5 (the `nav.toc`
ground outside the gate; the 44 px usability gap; the font-swap CLS judgment; self-hosting declined;
the 1.1.1 screen-reader gap). Other: 1 (the Mermaid pin was taken ahead of the audit's own two-week
wait; a maintainer decision, not a repo decision). Evidence checks unavailable: 3 (interactive
keyboard walkthrough; `prefers-contrast: more` and `forced-colors: active` render; field LCP, INP and
CLS; and the `@property` Baseline id, which webstatus did not return).
