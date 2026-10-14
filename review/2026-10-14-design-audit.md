# Design Audit, 2026-10-14

Range: `5aa8e71..03c78db`, ten commits (v1.50.3 to v1.56.0), plus the uncommitted v1.57.0 work in the working tree, audited as it stands. Previous report: `review/2026-10-05-design-audit.md`, which audited `5aa8e71`. `review/declined.md` has no rows, so no finding matches a decline.

The committed delta is small in CSS (32 added lines: copy button, `.hero`, index shell and rail, `recent-group` container query, `:has()` edge-list rule, live-dot, `dvh`) and large in NOTES.md and scripts. The working tree adds the sparkline, small multiples, `xychart` theme, light-mode accent band, `strong` weight, pie removal and a focus-cue change. **Two violations of a settled decision, both in the v1.56.0 copy button, and both in the patch.** One new gate comes with them. No challenge to a settled decision is raised.

Method: browser probes loaded the real fixtures from `file://` in Chrome 152.0.7977.77 with the CDN reachable, so Mermaid, highlight.js and the fonts rendered. Lab results are unthrottled, desktop-emulated and labelled as lab data. A subagent gathered the standards, Baseline and npm facts and returned source URLs; items it could not retrieve are marked unavailable below.

## Step 2: Delta

| Added line | NOTES.md entry | Obeys AGENTS.md | Rendered by a fixture |
| --- | --- | --- | --- |
| `.copy-code` (v1.56.0) | Yes, Raw HTML and other generators, "Every `pre` except `pre.mermaid` gets a copy button" | Yes, no comment | Runtime only: `highlight.js` injects it, so no static fixture string exists. The probe asserts it |
| `.copy-code:hover` | Covered by Interaction states, which this line breaks | Yes | Same |
| `.copy-code` `margin: -0.5rem -0.5rem 0 0.5rem` | Direction, zoom and growth requires logical sides | Yes | Same |
| `.hero`, `.hero > img`, `.hero > figcaption` | Yes, Image tiles | Yes | `samples/dark.html`, search `class="hero"` |
| `nav a[aria-current="page"]` | Yes, Nav link separators | Yes | `samples/dark.html` |
| `.index-shell`, `.index-rail` | Yes, The index shell | Yes | `samples/dark.html` |
| `.recent-group { container-type: inline-size }`, `@container (max-width: 40rem)` | Yes, Progressive disclosure | Yes. The containment is scoped to one component, not `article` | Same fixture |
| `.edge-list:has(> div:only-child)` | Yes | Yes | `samples/dark-conn-map.html` |
| `live-pulse` finite animation | Yes | Yes | `samples/dark.html` |
| Working tree: `.spark`, `.spark.fit`, `.multiples` | Yes, Tufte's chart rules | Yes, no comment | `samples/dark-charts.html`, search `class="spark"` and `class="multiples"` |
| Working tree: `xyChart` theme variables | Yes, Diagram types | Yes, hex only, no comment | `samples/dark-charts.html`, search `xychart` |

**Violation 1, `.copy-code:hover` sits outside `@media (hover: hover)`.** NOTES.md, Interaction states: "Every hover rule sits inside `@media (hover: hover)`. Eight rules didn't, and an unguarded hover rule doesn't fail to apply on touch: it applies at the wrong time and sticks." The rule was the only unguarded `:hover` in the sheet. Probe: with the patch, `matchMedia('(hover: hover)')` is false on a touch-emulated context, so the rule no longer applies there.

**Violation 2, the copy button uses physical margins.** NOTES.md, Direction, zoom and growth, requires logical sides. The four-value `margin` shorthand evaded the `margin-left` grep in Step 4. Probe, distance from the `pre`'s inline-end edge to the button, `samples/dark.html`:

| Direction | Before | After |
| --- | --- | --- |
| `dir="ltr"` | 16px | 16px |
| `dir="rtl"` | 24px | 16px |

The same two lines are still present in the working tree, so the patch applies there too.

**Re-check of the previous report's claims.** The 2026-10-05 report's Method note says no CDN code ran and Mermaid never rendered. That is true of that run and is not repeated here. Its Mermaid "latest" claim was 12.1.0 as of 2026-10-02. That is no longer current (see Topic 6). No file or selector attribution in it was wrong against this delta.

## Topic 1: Color and Contrast

`palette-check.py` passes (17 tokens, 4 modes). The working tree adds a light-mode band that holds `--orange`, `--purple`, `--pink`, `--green` and `--link` to 55-65 percent of their ceiling, and an `xyChart` palette in both Mermaid sets. Reinforces: OKLCH tokens, hex-only Mermaid. Repeat, unchanged since 2026-09-30: `nav.toc` is still the one named ground outside the gate.

### Searched

- `curl https://api.webstatus.dev/v1/features/{oklab,color-mix,relative-color,light-dark}`, 2026-10-14. OKLCH and `color-mix()` Widely available since 2025-11-09. `relative-color` and `light-dark()` Newly available since 2024-09-16 and 2024-05-13.

## Topic 2: Typography

No type decision changed. The working tree changes only `strong` (weight 600, no color). `text-wrap: pretty` stays limited availability, and the stylesheet uses it only where a fallback is harmless. Repeat, unchanged since 2026-09-30.

### Searched

- webstatus `text-wrap-balance` (Newly, 2024-05-13), `text-wrap-pretty` (limited), `text-wrap` shorthand (Newly, 2024-10-17), 2026-10-14.

## Topic 3: Layout and Spacing

The sweep below measured 45 combinations with no page overflow. The new `.multiples` grid stacks in DOM order. `container-type: inline-size` on `.recent-group` is scoped and does not repeat the `article` mistake NOTES.md records. The wide measure was not examined. AGENTS.md closes it.

### Searched

- webstatus container-queries (Widely 2025-08-14), `:has()` (Widely 2026-06-19), subgrid (Widely 2026-03-15), cascade-layers (Widely 2024-09-14), nesting (Widely 2026-06-11), `@scope` (Newly 2026-03-24), grid-lanes (limited), 2026-10-14.

## Topic 4: Accessibility

See the WCAG sweep and the keyboard checks. **Maintainer instruction, 2026-10-14: screen-reader support is out of scope for this repo.** This report still measures it where a criterion asks, and does not propose a fix for a screen-reader-only gap. The one such gap is below under 1.1.1. Contrast, keyboard and focus findings are unaffected.

### Searched

- W3C WCAG standards page and TR index, 2026-10-14 (see Standards status).

## Topic 5: Interaction and Motion

The `live-dot` pulse is finite (two beats) and `prefers-reduced-motion` forces animation to a single 0.01ms iteration, as NOTES.md records. **Violation 1 above is the finding for this topic.** In the working tree, the focus color change on `nav.toc a` and `details.deep > summary` is gone, so focus is one cue (the `--link` outline) in every component. Repeat, unchanged since 2026-09-30: no hover or press decision is challenged.

### Searched

- No new query. `@starting-style` (Newly 2024-08-06) and View Transitions (Newly 2025-10-14) are not used and nothing requires them.

## Topic 6: Pinned Dependencies

| Package | Pinned | Latest on npm | Latest modified | Two-week rule | Verdict |
| --- | --- | --- | --- | --- | --- |
| `mermaid` | 12.1.0 | 12.2.0 | 2026-10-13 | Fails by 13 days | Wait. Recheck after 2026-10-27. Path: `nu scripts/maintain.nu mermaid <version>`. Not in the patch |
| `@highlightjs/cdn-assets` | 11.11.1 | 11.12.0 (11.11.2 on 2026-08-11) | 2026-08-12 | Passes | Eligible. Release notes were not retrieved, so no judgment on whether a fix applies. Manual edit of the `highlight.js` URL |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.1 | 2026-10-11 | Fails by 11 days | Stay |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | 2026-07-19 | Current | None |

12.1.0 already includes the chevrotain 13 change that dropped a vulnerable `lodash-es`. 12.2.0 lists circle node sizing, ELK label placement, mindmap fixes, scoped swimlane cluster IDs and edge clipping, and nothing labelled breaking.

**Provenance.** `@font-face src: url()` and a bare-specifier `import` of a remote URL have no `integrity` hook, so no SRI attribute can attach to any of these four URLs. The checkable question is whether the npm packages carry attestations. The latest version of each of the four has an SLSA v1 provenance attestation. Attestations were not checked on the pinned versions. NOTES.md already weighed self-hosting, so it is `[Repeat]` and not proposed.

### Searched

- `npm view <pkg> version time.modified` and `dist.attestations` for the four packages, 2026-10-14. Mermaid release notes at `github.com/mermaid-js/mermaid/releases`.

## Topic 7: Performance and Stability

Core Web Vitals thresholds, `web.dev/articles/vitals` (accessed 2026-10-14, page last updated 2024-10-31): LCP at or below 2.5 s, INP at or below 200 ms, CLS at or below 0.1, each at the 75th percentile and split by mobile and desktop.

**Field data: unavailable.** No public deployment was queried, no CrUX data exists for these fixtures, and `web-vitals` is not added to the template. **INP: unavailable.**

**Lab data**, Chrome 152.0.7977.77, local `file://`, no throttling, no device emulation beyond a 1280x800 desktop viewport, cold cache, CDN reachable:

| Fixture | CLS | LCP |
| --- | --- | --- |
| `samples/dark.html` | 0.0146 | 68 ms |
| `samples/dark-charts.html` | 0.2215, one shift at about 108 ms | 56 ms |

**The charts-fixture CLS is above the 0.1 target in lab, and the cause is the web-font swap, not Mermaid.** With `**/*.woff2` aborted, both fixtures record zero shifts. The shift lands before any Mermaid chunk loads, and the fallback serif has different metrics from Source Serif 4. NOTES.md, Fonts, records `font-display: swap` and no metric-adjusted fallback. **New ground, no patch:** a metric-matched local fallback face (`size-adjust` and the ascent and descent overrides) needs per-platform fallback metrics that the stylesheet cannot read, so this is a design judgment, and CLS in a consumer's page depends on that page's font cache. Lab, not field.

Render-blocking: the stylesheet is inline, so no stylesheet request blocks render. The fixtures request two variable-font files, the Mermaid module and its chunks, and `highlight.js` from jsDelivr. The module scripts are deferred by the `type="module"` attribute. Images: `samples/dark.html` carries two images, 20x20 and 1150x493. The larger one has a width attribute or an `aspect-ratio`, so its box is reserved. No ad slot exists, so ad shift is not applicable.

**CSS coverage: not reported.** The Chrome rule-usage tracker returned every rule as used (462 of 462 and 334 of 334), which cannot be right for a sheet with print, forced-colors and RTL branches the run did not enter. A result that cannot fail is not evidence, so no coverage candidate is listed.

### Searched

- `web.dev/articles/vitals`, 2026-10-14.

## Standards Status

Accessed 2026-10-14. This report maps technical criteria only and does not claim legal compliance.

| Area | Finding | Source |
| --- | --- | --- |
| WCAG Recommendation | WCAG 2.2 is the newest version. Published 2023-10-05, updated 2024-12-12. No WCAG 2.3 or newer criteria exist. Total criteria count not on the page, so not asserted | `w3.org/WAI/standards-guidelines/wcag/`, `w3.org/TR/` |
| WCAG 3.0 | Working Draft dated 2026-09-10, Recommendation track, "may be updated, replaced, or obsoleted". Draft information only. The Appendix C change log was past the fetch limit, so changes since the last audit are unavailable | `w3.org/TR/wcag-3.0/` |
| ISO/IEC 40500 | W3C states WCAG 2.2 is approved as ISO/IEC 40500:2025. `iso.org` returned 403, so the catalog was not read. Approval date 2025-10-21 is from a secondary source only | W3C WCAG page |
| EN 301 549 | ETSI HF page lists V4.1.1 (2026-09) as Published. **Harmonisation and Official Journal citation: not confirmed, no OJ record retrieved.** Vendor commentary says V3.2.1 is the cited version, unconfirmed here | `etsi.org/technical-groups/hf/` |
| Baseline | Newly available means supported in every core browser. Widely available means 30 months after that date. Core set: Chrome and Edge, Firefox, Safari | `web.dev/baseline` |

### Searched

- The five sources above, 2026-10-14. MDN's Baseline glossary was not fetched.

## Modern CSS Baseline Review

Source for every row: `api.webstatus.dev/v1/features/<id>`, 2026-10-14. Newly available features need an `@supports` fallback unless current consumer needs make it unnecessary.

| Feature | Baseline | Newly available | Widely available | Use in this stylesheet | Fallback or reason |
| --- | --- | --- | --- | --- | --- |
| Container queries | Widely | 2023-02-14 | 2025-08-14 | `.scorecard`, `.recent-group` | None needed |
| `:has()` | Widely | 2023-12-19 | 2026-06-19 | `.edge-list:has(> div:only-child)` | None needed |
| Subgrid | Widely | 2023-09-15 | 2026-03-15 | Not used | No need |
| Cascade layers | Widely | 2022-03-14 | 2024-09-14 | Whole sheet in one layer | None needed |
| Native nesting | Widely | 2023-12-11 | 2026-06-11 | Not used | No need |
| `@scope` | Newly | 2026-03-24 | n/a | Not used | Would need `@supports`. No need |
| OKLCH, `color-mix()` | Widely | 2023-05-09 | 2025-11-09 | Tokens and mixes | None needed |
| `clamp()` | Widely | 2020-07-28 | 2023-01-28 | Body size, rail width | None needed |
| Logical properties | Widely | 2021-09-20 | 2024-03-20 | Throughout, one exception fixed by the patch | None needed |
| `aspect-ratio` | Widely | 2021-09-20 | 2024-03-20 | `.hero > img` | None needed |
| Flexbox `gap` | Widely | 2021-04-26 | 2023-10-26 | Used | None needed |
| `dvh`, `svh`, `lvh` | Widely | 2022-12-05 | 2025-06-05 | `100dvh` on the rail | None needed |
| Scroll-driven animations | Limited | n/a | n/a | Not used | Not Baseline |
| View Transitions | Newly | 2025-10-14 | n/a | Not used | No need |
| `@starting-style` | Newly | 2024-08-06 | n/a | Not used | No need |
| CSS Grid Lanes | Limited | n/a | n/a | Not used | Not Baseline |
| `sibling-index()`, `sibling-count()` | Newly | 2026-08-18 | n/a | Not used | No need |
| Anchor positioning | Limited | n/a | n/a | Not used | Not Baseline |
| `@property` | Newly | 2024-07-09 | n/a | Not used | No need |

Mobile-first authoring: evaluated as current practice and not adopted as a reversal of settled layout decisions. The single-width decision stays.

## Responsive Usability Sweep

`samples/dark.html`, `samples/dark-conn-map.html` and `samples/dark-charts.html`, each at 320, 375, 768, 1024 and 1280 CSS pixels wide and 568, 768 and 900 tall: **45 combinations, `scrollWidth` equal to `clientWidth` in all 45, no page-level overflow.** Intentional scrolling stays inside the documented hatches (tables, code, and the 700px Mermaid diagrams under 600px). Nothing in the sweep narrows prose or changes `--page-width`.

Interactive targets at 768 tall, measured from rendered rectangles:

| Fixture | Targets | Under 44 px | Under 24 px | Notes |
| --- | --- | --- | --- | --- |
| `dark.html` at 1280 | 81 | 42 | 14 | 2 non-inline under 24: two disabled 18px checkboxes |
| `dark-conn-map.html` | 8 | 2 | 0 | Mermaid zoom button 134x42 |
| `dark-charts.html` | 31 | 23 | 8 | Zoom buttons 134x42, one summary 28px tall |

**44 x 44 usability gap, reported separately from WCAG:** the Mermaid zoom button is 121x40 at 320 and 134x42 at 1280, the copy button is 36x36 (NOTES.md already records "below the 44px usability target"), and 24 to 29px high nav and inline links. **WCAG 2.5.8 (24x24):** every target passes, because the only undersized ones are disabled checkboxes, which the inactive exception covers.

Heading order has no skip in any fixture, each has one `h1`, and every `<title>` is distinct. No loading, error or empty state exists in the fixtures except the filter's empty line, which `script-probe.py` asserts.

## Accessibility Tool and Keyboard Checks

No automated accessibility tool was run (no Axe or WAVE package is installed). Manual keyboard checks, Chrome, Tab through `samples/dark.html` and `samples/dark-charts.html` in dark, light, `prefers-contrast: more` and forced colors:

| Check | Result |
| --- | --- |
| Tab stops, `dark.html` | 79 in every mode, each with a computed outline or a box shadow, none invisible |
| Tab stops, `dark-charts.html` | 31 in every mode, same result |
| Mermaid zoom button | Enter opens the dialog, Escape closes it, Space opens it again, and focus returns to the zoom button |
| Sticky header and rail | Over 113 to 119 focus stops per fixture, none was fully obscured |
| Text spacing override (line-height 1.5, letter-spacing 0.12em, word-spacing 0.16em, paragraph spacing 2em) | No overflow, no clipped text in all four fixtures |

Automated results, had they run, would supplement and not replace these checks.

## WCAG Conformance Sweep

WCAG 2.2 (Recommendation, revised 2024-12-12), checked 2026-10-14. Newer criteria: none.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Accepted gap, partly | Both images carry `alt`. **Six of the Mermaid SVGs in `dark-charts.html` carry no `<title>`** even though every fence has an `accTitle`: Mermaid does not emit one for those types. NOTES.md, Diagram types, records this for `timeline` and the like. Maintainer said screen-reader support is out of scope |
| 1.3.1 Info and Relationships | A | Pass | Tables carry captions and header cells. No heading skips |
| 1.3.2 Meaningful Sequence | A | Pass | The connections-map reorder and the grid stack follow DOM order |
| 1.4.1 Use of Color | A | Pass | Verdict badges spell the status. NOTES.md records the `verified`, `unverified` and `correction` text |
| 2.1.1 Keyboard | A | Pass | 79 and 31 tab stops, zoom dialog operable |
| 2.1.2 No Keyboard Trap | A | Pass | Escape leaves the dialog and focus returns |
| 2.4.2 Page Titled | A | Pass | Four distinct titles |
| 2.4.3 Focus Order | A | Pass | Tab order follows DOM order |
| 2.4.4 Link Purpose | A | Pass | No bare "click here". Outbound arrow has an alt twin |
| 2.5.3 Label in Name | A | Pass | The zoom button's visible text is a prefix of its name |
| 3.1.1 Language of Page | A | Pass | `lang="en"` in all four fixtures |
| 3.2.1 On Focus | A | Pass | No focus change triggers a context change |
| 3.2.2 On Input | A | Pass | The filter updates a count only |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step process |
| 4.1.2 Name, Role, Value | A | Pass | Zoom button and dialog are named. Task-list checkboxes are native and disabled |
| 1.4.3 Contrast (Minimum) | AA | Pass | `palette-check.py`, 17 tokens in 4 modes. Ground not reached by the gate: `nav.toc`, named in the previous report |
| 1.4.4 Resize Text | AA | Pass | 320 px reflow passes with no overflow, which is the layout a 400 percent zoom produces |
| 1.4.10 Reflow | AA | Pass | 45 combinations, `scrollWidth` equals `clientWidth` |
| 1.4.11 Non-text Contrast | AA | Pass | Focus rings use `--link`, the borders use `--rule`. Both are in the palette gate |
| 1.4.12 Text Spacing | AA | Pass | Override test above |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content |
| 2.4.6 Headings and Labels | AA | Pass | Descriptive headings, labelled filter |
| 2.4.7 Focus Visible | AA | Pass | Every stop has an outline or shadow in four modes |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Pass | No focused control was fully hidden |
| 2.5.7 Dragging Movements | AA | Not applicable | No dragging feature |
| 2.5.8 Target Size (Minimum) | AA | Pass | Only disabled checkboxes are under 24 px |
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

Out of scope, stated once: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4, 3.1.2 and 3.3.1 through 3.3.6.

## Ungated-Rules Sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in the inlined files | Pass | `tufte-dracula.css` shows line 2 only, outside the `was #` notes. `mermaid.js`, `filter.js` and `highlight.js` have none |
| Every `var(--x)` resolves | Pass | 41 declared tokens, no undeclared reference without a fallback |
| Sides are logical | **Violation, fixed by the patch** | The longhand grep is empty, but the `.copy-code` four-value `margin` shorthand was physical |
| Every `:hover` is inside `@media (hover: hover)` | **Violation, fixed by the patch** | `.copy-code:hover`. The patch also adds a gate |
| Decorative pseudo content has an alt twin | Pass | Every string-valued `content` has a `/ ""` twin or is empty |
| Selector with no fixture instance | Candidates only | 96 of 217 class selectors appear in no static fixture: highlighter token classes (consumer input) and `.copy-code` (injected at runtime). None is proposed for removal |
| Mermaid colors are hex | Pass | No `oklch` or `var(` in `mermaid.js` |
| Exact CDN pin | Pass | Four URLs, each with an exact version |
| No line number into a generated file | Pass | `check` resolves 45 search-string pointers |
| New composite grounds covered | Pass | The sparkline end column is `--on-surface` on `--surface`, which check 5 covers |

## Challenges a Settled Decision

None.

## Out-of-Scope Sections

Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo layout, and Odds and ends were not audited, as the skill defines. The copy-button entry in Raw HTML and other generators was read only to confirm Step 2's documentation question.

## Patch and Verification

`review/2026-10-14-design-audit.patch` touches three source files: `tufte-dracula.css` (move `.copy-code:hover` into the guarded block, make its margin logical), `scripts/maintain.nu` (a `:hover` gate) and `NOTES.md` (one sentence recording the gate). It does not touch `samples/` or `tokens.css`.

**Verified: patch applies to HEAD and Contract OK after regeneration.** Details: a worktree at `03c78db` under the scratchpad directory (a `/tmp` path breaks `maintain.nu`'s `path relative-to` on macOS, because `/tmp` resolves to `/private/tmp`), patch applied, `build-sample.nu` run, `check` printed `Contract OK`. With the stylesheet reverted to HEAD, the new gate printed `HOVER: tufte-dracula.css line 146 is outside @media (hover: hover)` and `check` failed, so the gate reaches its subject. The dash scan of both review files found nothing, and the added-line scan for comments found nothing. The probe render after the patch gives 16px in both directions (see Step 2).

## Counts

Findings: 10. Violations of a settled decision: 2. New ground: 1 (font-swap CLS). Challenges: 0. Repeats: 4. Other: 3 (the 1.1.1 accepted gap, the 44 px usability gap, the dependency bump timing). Evidence checks unavailable: 6 (field CLS, LCP and INP; the ISO catalog page; the EN 301 549 Official Journal record; the WCAG 3.0 change log; the highlight.js release notes; a reliable CSS coverage result).
