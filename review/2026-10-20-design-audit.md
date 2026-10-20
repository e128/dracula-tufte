# Design Audit, 2026-10-20

Range: `88f58d1..3cc54b4` (`HEAD` of branch `feat/layer-stack-and-matrix`), **five commits**: v1.57.1, v1.57.2, v1.57.3 on `main`, plus two unversioned feature commits on the branch (`.layer-stack` and `table.matrix`; `table.heatmap`). Previous report: `review/2026-10-16-design-audit.md`, which audited `03c78db..88f58d1`. `review/declined.md` has no rows, so no finding matches a decline.

The three `main` commits are small (diagram accessible names, 44px targets, a `nav.toc` cap, an agent-config script cleanup). The three new components are the bulk of the payload delta, and no earlier audit has seen them.

Method: headless Google Chrome (the macOS app), local `file://`, CDN reachable. Narrow viewports were driven through sized iframes with `--allow-file-access-from-files`, because headless Chrome clamps the minimum window width. All numbers are unthrottled lab data. Playwright is not installed here, so `.github/render-modes.py` was not run on its own. `nu scripts/maintain.nu check` printed `Contract OK` on `HEAD` and on the patched worktree.

## Step 2: Delta

| Change | NOTES.md documents it | Obeys AGENTS.md | Obeys a settled decision | A fixture renders it |
| --- | --- | --- | --- | --- |
| `mermaid.js` reads `accTitle` and `accDescr` into SVG `<title>` and `<desc>` (v1.57.1) | Yes (v1.57.1) | No comments added, hex-only unaffected | Pass | Yes, `samples/dark-charts.html` |
| `.mermaid-zoom` `min-height: 44px`, overlay close `2.75rem` (v1.57.1) | Yes | Pass | Pass | Yes |
| `nav.toc { max-inline-size: 38rem }` (v1.57.3) | Yes, `NOTES.md` § Progressive disclosure | Pass | See note below | Yes |
| `.layer-stack`, `.layer*`, `.layer-card`, `.layer-end` | Yes, § Borrowed components | Pass | Pass | `samples/dark.html`, search `class="layer-stack"` |
| `table.matrix` | Yes | Pass | Pass | `samples/dark.html`, search `class="matrix"` |
| `table.heatmap`, `span.hm` | Yes | Pass | Pass | `samples/dark.html`, search `class="heatmap"` |
| `scripts/maintain.nu` dash and link scans read each file once | n/a (script) | Pass | n/a | n/a |

**Note on `nav.toc` at `38rem`.** The closed measure rule covers "anything that reduces the rendered width of running prose". `nav.toc` is a navigation block, `NOTES.md` states the cap in the same entry that explains the float clearing, and the rule's four failed attempts all targeted `p` or the page column. I read it as outside the rule and report it here so the maintainer can confirm that reading. This is not a finding and not a challenge.

**Finding D1 (new, in patch): `span.hm` conveys data with no text alternative.** A square is a blank `<span>`. Its state (full, part, striped, outlined) is the data, and WCAG 1.1.1 and 1.3.1 ask for a text equivalent. The patch adds `role="img"` and an `aria-label` per square in the fixture and states the convention in NOTES.md. The maintainer has said screen readers are not a concern here, so this finding is the cheapest of the set to drop. It is one attribute pair, and a consumer who copies the fixture inherits it.

**Finding D2 (Step 4 row, in patch): two grounds sit outside the palette gate and had no NOTES.md entry.** `.hm` paints `--purple` over `--code-bg`. `.layer-end` inverts `--on-surface` over `--surface`. `.github/palette-check.py` gates neither. I computed the first pair from the oklch tokens (sRGB, gamut-clipped, not rendered): dark 4.21, light 5.00, contrast 7.24, print 4.64, all above the 3:1 non-text floor. The patch records those grounds in NOTES.md. A gate was not written: a gate that checks a pair I computed by hand in a script I did not render against would report more than it knows.

**Observation (not a finding):** `tbody tr:hover td` tints cells but not the sticky `th` in `table.matrix` and `table.heatmap`, so a hovered row shows an untinted first column. It is cosmetic and hover-only.

**Previous report claims re-checked.** The 2026-10-16 report said both v1.56.0 violations were fixed and shipped. The delta does not touch either. Nothing to correct.

## Topic 1: Color and Contrast

- **[Reinforces]** `oklch()` and `color-mix()` are Baseline Widely available (2023-05-09 Newly, 2025-11-09 Widely). The tokens and `mermaid-palette.json` split stay as NOTES.md states.
- **[New ground]** The three new components add no token. They reuse `--purple`, `--code-bg`, `--on-surface`, `--surface`, `--rule`, `--rule-light`. See D2 for the one gap.
- Forced colors: `.hm` gets a `1px solid CanvasText` border, so a stripped fill still leaves a visible square. Fill height and stripes survive because backgrounds are images. I did not render forced-colors mode (see Accessibility checks).

### Searched
`web-features` 3.43.0 dataset (npm, modified 2026-10-19), access 2026-10-20.

## Topic 2: Typography

- **[New ground]** Rotated column headers in `table.heatmap` use `writing-mode: vertical-rl` plus `rotate(180deg)` on an inner `span`. `writing-mode` is Widely available (2017-03-27 Newly, 2019-09-27 Widely). `text-orientation` is Widely available (2020-09-16, 2023-03-16). The inner `span` is `inline-block`, so the header takes real height and adds no layout width, which is the property the earlier "transform ink" lesson (AGENTS.md) requires.
- **[Reinforces]** Body type scale unchanged. The new components add no `font-size` outside `0.9em` captions.

### Searched
Same dataset as Topic 1.

## Topic 3: Layout and Spacing

- **[New ground]** `.layer` uses `flex-wrap` with `flex: 1 1 10rem` and `3 1 18rem`, so the name column stacks over the cards with no breakpoint. At 320px every `.layer`, `.layer-cards` and `.layer-card` stayed inside its parent (rect check, 3 layers). Flexbox `gap` is Widely available (2021-04-26, 2023-10-26).
- **[New ground]** Sticky first column: `position: sticky` is Widely available (2019-09-19, 2022-03-19). Sticky on a `th` cell and `inset-inline-start` with sticky have no separate Baseline entry, so per-element behavior is not independently dated. The sticky behavior was **not exercised**: the 1000px renders of `table.matrix` and `table.heatmap` did not overflow, so no horizontal scroll moved a column under the pinned one.
- **[Reinforces]** No physical sides added. `rg` for `*-left`/`*-right` returns nothing.
- **Page-level overflow:** none (see Responsive Usability Sweep).

### Searched
Same dataset.

## Topic 4: Accessibility

- **[Violation, patched]** D1 above.
- **[Reinforces]** `.table-scroll` wrappers on the matrix and heatmap carry `tabindex="0"`, `role="region"` and an `aria-label`, and `nu scripts/maintain.nu contract-markup` gates that.
- **[New ground]** 2.4.11 Focus Not Obscured: the only focusable element in either table is the wrapper, so a sticky column cannot hide a focused cell. W3C's Understanding page names `scroll-padding` as the technique for a sticky element over focusable content ([Understanding SC 2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)). That would matter the day a grid gets focusable cells.
- **[New ground, declined as scope]** Arrow-key movement in `table.heatmap`. The APG grid pattern ([APG grid](https://www.w3.org/WAI/ARIA/apg/patterns/grid/)) requires `role="grid"`, one tab stop, Home/End and author-managed focus. A plain `table` with hand-rolled arrows is a non-standard hybrid. NOTES.md now states this.
- **[Reinforces]** The `content: "x" / ""` alt-text syntax used by `.layer::before` is Baseline Newly available since 2024-07-09. The stylesheet writes a fallback declaration first, which is the `@supports`-equivalent shape.

### Searched
APG Grid pattern, access 2026-10-20. WCAG 2.2 Understanding 1.3.1, 1.4.10, 2.4.11, access 2026-10-20.

## Topic 5: Interaction and Motion

- **[Reinforces]** No new `:hover` outside `@media (hover: hover)` (lines 491 to 503 hold all of them). No new transition or animation.

### Searched
None; the delta adds no interaction.

## Topic 6: Pinned Dependencies

| Package | Pinned | Current | npm `time.modified` | Provenance |
| --- | --- | --- | --- | --- |
| `mermaid` | 12.2.0 | 12.2.0 | 2026-10-13 | SLSA provenance v1 present |
| `@fontsource-variable/source-serif-4` | 5.3.1 | 5.3.1 | 2026-10-11 | present |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | 2026-07-19 | present |

Pinned equals current for all three, so no Mermaid bump command applies. `time.modified` is registry metadata and can move without a release. I did not read changelogs or advisories. Provenance: `@font-face src: url()` and a remote ESM `import` both have no `integrity` hook, so the checkable supply-chain question is the npm attestation, which exists for all three. **[Repeat]** Self-hosting was weighed in NOTES.md and is not re-argued.

### Searched
`npm view <pkg> version time.modified dist.attestations` for the three packages, 2026-10-20.

## Topic 7: Performance and Stability

- **Thresholds** (web.dev, [Web Vitals](https://web.dev/articles/vitals), accessed 2026-10-20): LCP at or below 2.5 s, INP at or below 200 ms, CLS at or below 0.1, at the 75th percentile, mobile and desktop separately.
- **Lab data:** not collected this run (no Lighthouse or trace run). **Field data:** unavailable, no public deployment authorized and no CrUX data. **INP:** unavailable.
- **Render-blocking:** the stylesheet is inline. The fixtures load fonts from jsDelivr (`font-display: swap`) and Mermaid as an ES module; neither blocks first paint of the inline CSS.
- **Layout shift:** no `img` or embedded content in the three new components. Heatmap squares are fixed `1.6rem` boxes and header height is set by text, so no shift source was added.
- **CSS coverage:** not run (DevTools Coverage is not available in this headless setup). Every new selector has a fixture instance, so no uncovered candidate was produced by the delta.

### Searched
web.dev Web Vitals, 2026-10-20.

## Standards Status

Mapping only. This report claims no legal compliance.

| Area | Status as checked 2026-10-20 | Source |
| --- | --- | --- |
| WCAG Recommendation | WCAG 2.2, W3C Recommendation, published 2023-10-05, revised 2024-12-12, 86 active success criteria (4.1.1 removed). A/AA/AAA split not confirmed this run | [WCAG overview](https://www.w3.org/WAI/standards-guidelines/wcag/), [WCAG 2.2](https://www.w3.org/TR/WCAG22/) |
| WCAG 3.0 | Draft only. Latest Working Draft 2026-09-10, none newer. Content of that draft not read this run | [WCAG 3.0](https://www.w3.org/TR/wcag-3.0/), [history](https://www.w3.org/standards/history/wcag-3.0/) |
| ISO/IEC 40500 | 40500:2025 reported as WCAG 2.2, W3C news 2025-10-21 (secondary). ISO catalog returned HTTP 403, so the catalog record is **unavailable** | [W3C news](https://www.w3.org/WAI/news/2025-10-21/wcag22-iso) |
| ETSI EN 301 549 | V4.1.1 (WCAG 2.2 based), ETSI deliver directory lists 04.01.01_60 dated 2026-09-02 | [ETSI deliver](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/) |
| EU Official Journal | **Unverified at the primary source** (EUR-Lex not retrieved). Secondary sources report V4.1.1 published but not cited under the European Accessibility Act. Do not state it as harmonised | secondary only |
| Baseline definition | Dates below come from the `web-features` 3.43.0 dataset behind MDN and web.dev badges. Individual MDN pages were not fetched | npm `web-features` |

### Searched
WebSearch: "EN 301 549 harmonised standard Official Journal implementing decision European Accessibility Act harmonisation"; "ISO/IEC 40500 edition WCAG 2.2 ISO/IEC 40500:2025". Fetches: W3C WCAG overview, WCAG 2.2, WCAG 3.0 and its history, ETSI deliver directory. All accessed 2026-10-20.

## Modern CSS Baseline Review

| Feature | Baseline | Newly | Widely | Use in this stylesheet | Fallback or reason |
| --- | --- | --- | --- | --- | --- |
| Container queries | Widely | 2023-02-14 | 2025-08-14 | Used where NOTES.md records it | Settled |
| `:has()` | Widely | 2023-12-19 | 2026-06-19 | Not used by the new components | No need |
| Subgrid | Widely | 2023-09-15 | 2026-03-15 | Not used | Layer grid does not need aligned sub-rows |
| `@layer` | Widely | 2022-03-14 | 2024-09-14 | Used (`tufte-dracula`) | Settled |
| CSS nesting | Widely | 2023-12-11 | 2026-06-11 | Not used | Flat rules read easier in the generated copy |
| `@scope` | Newly | 2026-03-24 | n/a | Not used | Needs a fallback if ever adopted |
| `oklch()` / `color-mix()` | Widely | 2023-05-09 | 2025-11-09 | Used | Settled |
| `clamp()` | Widely | 2020-07-28 | 2023-01-28 | Used (type scale) | Settled |
| Logical properties | Widely | 2021-09-20 | 2024-03-20 | Used, no physical sides | Settled |
| `aspect-ratio` | Widely | 2021-09-20 | 2024-03-20 | Not used by new components | No image |
| Flexbox `gap` | Widely | 2021-04-26 | 2023-10-26 | Used by `.layer` | None needed |
| `dvh`/`svh`/`lvh` | Widely (viewport-units entry) | 2017-10-17 | 2020-04-17 | Not used | No full-height layout. Sub-keys not separated out |
| Scroll-driven animations | Not Baseline | n/a | n/a | Not used | No scroll effect wanted |
| View Transitions (same-document) | Newly | 2025-10-14 | n/a | Not used | No navigation effect |
| `@starting-style` | Newly | 2024-08-06 | n/a | Not used | No entry animation |
| CSS Grid Lanes | Not Baseline | n/a | n/a | Not used | No masonry need |
| `sibling-index()`/`sibling-count()` | Newly | 2026-08-18 | n/a | Not used | Layer order needs no index |
| Anchor positioning | Not Baseline (feature level) | n/a | n/a | Not used | No popover |
| `@property` | Newly | 2024-07-09 | n/a | Not used | No animated token |
| `content: "x" / "alt"` | Newly | 2024-07-09 | n/a | Used (arrows, quotes) | Plain `content` declared first |
| Sticky positioning | Widely | 2019-09-19 | 2022-03-19 | Used (`thead`, first column) | Static fallback is acceptable |
| `writing-mode` | Widely | 2017-03-27 | 2019-09-27 | Used (heatmap headers) | Headers stay legible if ignored |

Mobile-first authoring: the new components use no media query at all (`flex-wrap`, `auto-fit`, `min()`), which matches the rule against breakpoint overrides. No conflict with a settled decision.

### Searched
`web-features` dataset, 2026-10-20.

## Responsive Usability Sweep

`samples/dark.html` and `samples/dark-conn-map.html` at 320, 375, 768, 1024 and 1280 wide by 568, 768 and 900 tall (30 renders). Source: Chrome, iframes, lab.

| Fixture | Widths | Page overflow (`scrollWidth` vs `clientWidth`) |
| --- | --- | --- |
| `dark.html` | all five | none (305/305 at 320, 360/360 at 375, 753/753, 1009/1009, 1265/1265) |
| `dark-conn-map.html` | all five | none |

Height changed no result. Intentional overflow lives inside `.table-scroll`, `pre`, `math` and diagram hatches (the matrix scrolled 561px inside a 320px wrapper in an earlier probe).

**Interactive targets under 44 x 44 CSS px** (usability gap, separate from WCAG 2.5.8): in `dark.html`, 31 at 320, 33 at 375 and above, out of 88 and 83. At 1280 they are 15 inline links (inside text), 11 non-inline anchors, 1 heading permalink, 1 anchor, 2 `summary` elements, 2 disabled task-list checkboxes and 1 math scroll region. The two checkboxes are under 24 px and are disabled controls emitted by Markdown. `dark-conn-map.html` has none. **The new components add no target below 44 px**: their only focusable element is the full-width scroll wrapper. The 11 non-inline anchors and 2 `summary` elements are pre-existing and not touched by this delta.

Stacking: `.layer` stacks name over cards by wrapping, in DOM order, with no reorder. Loading, error and empty states: the template has none, and the filter box's empty state is unchanged. Not applicable for the delta.

## Accessibility Tool and Keyboard Checks

**Not run:** interactive Tab, Shift+Tab, Enter, Space and Escape passes in each appearance mode, forced-colors rendering of the new components, and an automated accessibility tool. This session had a headless browser and no interactive session. Gate coverage: `contract-markup` confirms the wrapper `tabindex` and `role`. Nothing here is a pass for keyboard behavior. The only new focus stops are the three wrappers, which reuse the existing `.table-scroll` pattern.

## WCAG Conformance Sweep

Standard: WCAG 2.2 (checked 2026-10-20, see Standards Status). "Delta" means evidence from this run. "Prior" means last verified in the 2026-10-16 report and the delta does not touch it. A "Prior" row is not re-verified.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Violation, patched | `span.hm` blank squares (D1). Mermaid names from v1.57.1 are in `samples/dark-charts.html` |
| 1.3.1 Info and Relationships | A | Pass for markup, Violation for `span.hm` | Tables use `th scope="row"`, `thead`, `rowspan`/`colspan` bands. D1 for squares |
| 1.3.2 Meaningful Sequence | A | Pass | Delta: `.layer` reads in DOM order, an `ol` |
| 1.4.1 Use of Color | A | Pass | Delta: `.hm` states differ by fill height, stripes and outline. Optional card says "Optional" in text |
| 2.1.1 Keyboard | A | Pass, not hand-tested | Wrappers carry `tabindex="0"` (gated). No interactive control added |
| 2.1.2 No Keyboard Trap | A | Prior | Zoom dialog untouched |
| 2.4.2 Page Titled | A | Prior | Untouched |
| 2.4.3 Focus Order | A | Pass | Three wrappers in source order |
| 2.4.4 Link Purpose | A | Prior | Untouched |
| 2.5.3 Label in Name | A | Prior | Zoom button untouched |
| 3.1.1 Language of Page | A | Prior | Untouched |
| 3.2.1 On Focus, 3.2.2 On Input | A | Prior | No script added |
| 4.1.2 Name, Role, Value | A | Pass for wrappers | `role="region"` plus label (gated) |
| 1.4.3 Contrast (Minimum) | AA | Pass | Palette gate, `Palette OK (17 tokens, 4 modes)` |
| 1.4.4 Resize Text | AA | Prior | Untouched |
| 1.4.10 Reflow | AA | Pass | Delta: no page overflow at 320 to 1280. Tables are the criterion's data-table exception and scroll inside a wrapper |
| 1.4.11 Non-text Contrast | AA | Pass (computed) | `.hm` `--purple` over `--code-bg`: dark 4.21, light 5.00, contrast 7.24, print 4.64. Computed from tokens, not rendered, and not gated |
| 1.4.12 Text Spacing | AA | Not run | No override test this run |
| 1.4.13 Content on Hover or Focus | AA | Not applicable to the delta | No hover-revealed content added |
| 2.4.6 Headings and Labels | AA | Pass | New section heading "Layer stack and coverage matrix" is a noun phrase |
| 2.4.7 Focus Visible | AA | Not run | Needs a hand pass |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Pass | Only focusable element in each table is the wrapper |
| 3.2.3, 3.2.4 | AA | Prior | No repeated navigation or identification change |
| 2.5.7 Dragging Movements | AA | Not applicable | No dragging feature |
| 2.5.8 Target Size (Minimum) | AA | Pass for the delta | New components add no target. Disabled checkboxes are an inactive-control exception |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step entry |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication |
| 4.1.3 Status Messages | AA | Prior | `filter.js` untouched |

**Relevant AAA, tracked separately**

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Pass for the delta | Same reason as 2.4.11 |
| 2.4.13 Focus Appearance | AAA | Not run | No focus rendering this run |
| 2.5.5 Target Size (Enhanced) | AAA | Not met | 31 to 33 targets in `dark.html` are under 44 px, none from the delta |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication |

Out of scope, stated once: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4, 3.1.2, 3.3.1 to 3.3.6.

## Ungated-Rules Sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in `tufte-dracula.css` or `mermaid.js` | Pass | Only line 2 (and the `/* was #rrggbb */` notes) in the CSS. Zero in `mermaid.js` |
| Every `var(--x)` resolves | Pass | Set difference empty over all declared tokens |
| Sides are logical | Pass | No physical `*-left`/`*-right` |
| `:hover` inside `@media (hover: hover)` | Pass | All hovers on lines 492 to 502, block spans 491 to 503 |
| Decorative `content` has an alt twin | Pass | Every string `::before`/`::after` has a `/ ""` twin, including the new `.layer` arrow |
| Selector represented in a fixture | Pass | `.layer*`, `table.matrix`, `table.heatmap`, `.hm` all in `samples/dark.html` |
| Mermaid colors are hex | Pass | No `oklch` or `var(` in `mermaid.js` |
| Exact CDN pin | Pass | Five URLs, all exact |
| No line number into a generated file | Pass | `contract pointers resolve (45 search strings, 37 requirements)` |
| New composite grounds have a NOTES.md entry | Violation, patched | D2 |

## Challenges a Settled Decision

None.

## Out of Scope

NOTES.md sections Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo layout, and Odds and ends were not audited, by design.

## Verification

`Verified: patch applies to HEAD and Contract OK after regeneration.` The patch (`review/2026-10-20-design-audit.patch`) changes `NOTES.md` and `scripts/build-sample.nu` only. It was applied in a detached worktree under the scratchpad, fixtures were regenerated there, and `nu scripts/maintain.nu check` printed `Contract OK`. The worktree is removed. Added patch lines contain no `/*`, `*/` or comment marker in a CSS or JS payload file. A before and after render of the patched markup was not taken: the patch adds attributes with no visual effect, so a render would show no difference.
