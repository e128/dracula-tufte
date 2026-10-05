# Design Audit, 2026-10-05

Range: `fa01958..5aa8e71`, five commits (`66ff8c0`, `506ea46`, `14f53dc`, `c0f12a9`, `5aa8e71`), v1.49.0 to v1.50.2. Previous report: `review/2026-09-30-design-audit.md`, which audited `fa01958`. `review/declined.md` has no rows, so no finding matches a decline.

The payload delta is three small releases: bar guides, evidence-table rules, `tfoot`, `.stat-strip`, caption `.label`, `.chart-takeaway`, `td.bar.lead`, a Mermaid pie config, and a `nav.toc` clear. This run found no violation of a settled decision and no defect. It found two new facts: Mermaid 12.1.0 shipped on 2026-10-02, and five Baseline dates in the 2026-09-30 report do not match the web-platform-dx data. No patch is proposed.

Method note: every browser probe loaded the real fixtures from `file://` with all non-file requests aborted, so no CDN code ran. Mermaid therefore never rendered, and `pre.mermaid` was hidden before measuring. Anything that depends on a rendered diagram is listed under Counts as unavailable.

## Step 2: Delta

| Added line | NOTES.md entry | Obeys AGENTS.md | Rendered by a fixture |
| --- | --- | --- | --- |
| `table.evidence-table` row rules, header rule, bold first column | Yes, CSS charts | Yes, no comment | `samples/dark-charts.html`, search `class="evidence-table"` |
| `tfoot td` rule and weight 600 | Yes, CSS charts | Yes | Same fixture, search `<tfoot>` |
| `.chart-takeaway`, `.more` | Yes, CSS charts | Yes | Same fixture, search `class="more"` |
| `:is(figcaption, caption) .label` | Yes, CSS charts | Yes | Same fixture, search `class="label"` |
| `.stat-strip` and its `dt`, `.v`, `.s` | Yes, CSS charts | Yes | Same fixture, search `class="stat-strip"` |
| `td.bar.lead` | Yes, CSS charts | Yes | Same fixture, search `bar lead` |
| `table.bar-chart` guide gradients | Yes, CSS charts | Yes | Same fixture |
| `.icon-list strong` | Yes, `no br in icon rows` | Yes | `samples/dark.html`, search `class="icon-list"` |
| `nav.toc` `clear: right; clear: inline-end` | Yes, Progressive disclosure | Yes, same pair as the sidenote float | Every fixture with a `nav.toc` |
| Mermaid `pie.textPosition`, three pie theme variables | Yes, CSS charts | Yes, no comment, no `oklch()` or `var()` in `mermaid.js` | Mermaid pie fence in `samples/dark-charts.html` |

Probe render of the new components (Chromium, `samples/dark-charts.html`, no before state captured because no defect was found):

| Check | 1280px | 320px | `dir="rtl"` | Print |
| --- | --- | --- | --- | --- |
| `.stat-strip` columns | 3, 1152px wide, no inner overflow | 1, 288px wide, no inner overflow | 3 | Not measured |
| `.chart-takeaway` rule | 2px left, 16px left padding | Same | 2px right, 16px right padding | Not measured |
| `td.bar` background position | `0% 50%` on all three layers | Same | `100% 50%` on all three layers | Not measured |
| `table.evidence-table` row rule | 1px | 1px | 1px | Not measured |
| `tfoot td` | weight 600, inset 1px top shadow | Same | Same | Not measured |
| Caption `.label` | block, all-small-caps, 15.7px | 13.7px | Same as 1280px | Not measured |
| `nav.toc` computed `clear` | `inline-end` | Not measured | Not measured | Not measured |

Forced colors (`forced_colors: active`): the inset shadows on `evidence-table` `thead th` and on `tfoot td` compute to `none`, and the sheet's `table, th, td { border: 1px solid currentColor }` rule restores a 1px border on both. The `.stat-strip` cell borders and the `.chart-takeaway` rule stay at 1px and 2px. The bar band and guides compute to `none`, which NOTES.md accepts because the printed value carries the data.

Print was not rendered for the new components. The print overrides for them were not read against the render, so no print claim is made.

Corrections to the 2026-09-30 report: its Topic 6 table said Mermaid 12.0.0 was the latest release. That was true on 2026-09-30. It is no longer true (see Topic 6). Its Baseline table also carries five wrong dates (see Modern CSS Baseline Review).

## Topic 1: Color and Contrast

No token changed in this window. The new `--bar-guide` is `color-mix(in oklab, var(--rule-light) 40%, transparent)`, a decorative guide behind text. The band tint under the printed value stays at the single alpha that palette-check 12 measures, and the guide adds no new text ground. Gate output: `nu scripts/maintain.nu check` printed `Contract OK` on `5aa8e71` with a clean tree.

`.claude/statusline.sh` now has palette check 13. It is a harness file, not payload, so no consumer is affected.

Reinforces: palette gate, OKLCH tokens. Repeat, unchanged since 2026-09-30: `nav.toc` stays the one named ground outside the gate.

### Searched

- `curl https://api.webstatus.dev/v1/features/color-mix`, 2026-10-05: Widely available, since 2025-11-09.
- `curl https://api.webstatus.dev/v1/features/relative-color`, 2026-10-05: Newly available, since 2024-09-16.

## Topic 2: Typography

The new caption `.label` uses `font-variant-caps: all-small-caps`. It computes to 15.7px at 1280px and 13.7px at 320px. `.stat-strip dt` computes to 14.7px and 12.8px. No type-scale decision changed. `text-wrap: pretty` status: web-platform-dx lists `text-wrap-pretty` as limited availability on 2026-10-05, so the 2026-09-30 line citing Baseline 2024 for `text-wrap-style` does not cover `pretty`. The sheet treats it as a progressive enhancement, which stays correct.

Repeat, unchanged since 2026-09-30: no type decision is challenged.

### Searched

- `curl https://api.webstatus.dev/v1/features/text-wrap-pretty`, 2026-10-05: limited availability.
- `curl https://api.webstatus.dev/v1/features/text-wrap-balance`, 2026-10-05: Newly available, since 2024-05-13.

## Topic 3: Layout and Spacing

`.stat-strip` uses `repeat(auto-fit, minmax(10rem, 1fr))` and collapses from 3 columns to 1 between 1280px and 320px with no overflow. Cell borders overlap by 1px through negative margins, as NOTES.md states. DOM order equals visual order. The `nav.toc` clear fix computes correctly.

The page-level sweep covered `samples/dark.html`, `samples/dark-conn-map.html` and `samples/dark-charts.html` at 5 widths and 3 heights, 45 combinations. `scrollWidth` equaled `clientWidth` in all 45. Mermaid diagrams were hidden for this sweep, so their scroll behavior was not measured in this run.

The wide measure was not examined or questioned. It is closed by AGENTS.md.

### Searched

- `curl https://api.webstatus.dev/v1/features/{container-queries,has,subgrid,cascade-layers,nesting,scope,grid-lanes,anchor-positioning}`, 2026-10-05.

## Topic 4: Accessibility

See the WCAG sweep and keyboard checks below. No ARIA authoring change applies to the delta: the new components are plain `table`, `dl` and `p` elements with no custom role.

### Searched

- W3C, [WCAG standards](https://www.w3.org/WAI/standards-guidelines/wcag/), 2026-10-05.
- W3C, [WCAG 3.0](https://www.w3.org/TR/wcag-3.0/), 2026-10-05.

## Topic 5: Interaction and Motion

No hover, press or transition rule changed. Every `:hover` rule (`rg -n ':hover'`) still sits inside the single `@media (hover: hover)` block. No motion change.

### Searched

- No query run: the delta contains no motion line, and the previous report's dating is unchanged.

## Topic 6: Pinned Dependencies

| Package | Pinned | Latest on 2026-10-05 | Modified | Provenance |
| --- | --- | --- | --- | --- |
| `mermaid` | 12.0.0 | **12.1.0** | 2026-10-02 | SLSA provenance on both 12.0.0 and 12.1.0 |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.0 | 2026-07-19 | Attestation present |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | 2026-07-19 | Attestation present |

**New: Mermaid 12.1.0.** The release notes ([GitHub release](https://github.com/mermaid-js/mermaid/releases/tag/mermaid%4012.1.0), read 2026-10-05) list a dependency security fix (chevrotain 13 drops a vulnerable `lodash-es@4.17.23` from the parser and main bundles), four rendering fixes (ELK feedback-loop edge routing, class diagram cardinality labels, XY chart legend clipping, duplicate-ID flowchart subgraphs), and a default-on `elk.orientFeedbackEdges` option that can change existing ELK diagrams. The fixtures use `look: 'classic'`, so the ELK change may not reach them, but only a render shows that. The bump touches generated files, so it is not in a patch. The supported path is `nu scripts/maintain.nu mermaid 12.1.0`, followed by `nu scripts/maintain.nu check`.

Provenance and SRI: `@font-face src: url()` and a remote ESM `import` have no `integrity` hook, so none is proposed. Self-hosting was weighed before and recorded in NOTES.md, so it is `[Repeat]`.

### Searched

- `npm view mermaid version time.modified`, 2026-10-05.
- `npm view mermaid dist.attestations` and for 12.0.0, 2026-10-05.
- `npm view @fontsource-variable/source-serif-4 version time.modified dist.attestations`, 2026-10-05.
- `npm view @fontsource-variable/jetbrains-mono version time.modified dist.attestations`, 2026-10-05.

## Topic 7: Performance and Stability

Lab or field Core Web Vitals data was not collected: no Lighthouse run, no public URL, no CrUX data, so field LCP, INP and CLS are unavailable. Current good thresholds (web.dev, [Core Web Vitals](https://web.dev/articles/vitals), read 2026-10-05): LCP 2.5 s or less, INP 200 ms or less, CLS 0.1 or less, at the 75th percentile, mobile and desktop separate.

The stylesheet is inline, so no separate stylesheet request blocks render. The fixtures load four font files and one Mermaid module from jsDelivr. Layout shift: the delta adds no image or embed. No ad slot exists.

CSS Coverage did not run. Candidates for unused CSS: none reported.

### Searched

- web.dev, [Core Web Vitals](https://web.dev/articles/vitals), 2026-10-05.

## Standards Status

| Area | Status on 2026-10-05 | Source |
| --- | --- | --- |
| WCAG Recommendation | WCAG 2.2, published 2023-10-05, updated 2024-12-12. No newer Recommendation listed. | [W3C WCAG](https://www.w3.org/WAI/standards-guidelines/wcag/) |
| WCAG 3.0 | Working Draft dated 2026-09-10. Draft only, not a conformance standard. | [W3C TR](https://www.w3.org/TR/wcag-3.0/) |
| ISO/IEC 40500 | Edition 2 (2025) as reported on 2026-09-30. The ISO page returned HTTP 403 on 2026-10-05, so this row was not rechecked. | [ISO](https://www.iso.org/standard/91029.html) |
| EN 301 549 | ETSI directory lists V4.1.1 (release 60) dated 2026-09-02. Official Journal status was not checked, so no harmonisation claim is made. | [ETSI deliver](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/) |
| Baseline definition | Dates taken from the web-platform-dx API (`api.webstatus.dev`), not from the web.dev page. | API, 2026-10-05 |

This audit maps technical criteria only. It makes no legal compliance claim.

### Searched

- Same sources as the table, fetched 2026-10-05.

## Modern CSS Baseline Review

Source: `https://api.webstatus.dev/v1/features/<id>`, fetched 2026-10-05. "Newly" means Newly available.

| Feature | Baseline status (low date, high date) | Current use | Fallback or reason not to adopt |
| --- | --- | --- | --- |
| Container queries | Widely, 2023-02-14, 2025-08-14 | `.scorecard` | Base layout remains the fallback |
| `:has()` | Widely, 2023-12-19, 2026-06-19 | Scope setup, captioned tables | Core content does not depend on it |
| Subgrid | Widely, 2023-09-15, 2026-03-15 | Not used | No nested shared tracks needed |
| Cascade layers | Widely, 2022-03-14, 2024-09-14 | `@layer tufte-dracula` | None needed |
| Native nesting | Widely, 2023-12-11, 2026-06-11 | Not used | No build step, flat rules |
| `@scope` | Newly, 2026-03-24 | Not used | Would need `@supports` |
| `color-mix()` | Widely, 2023-05-09, 2025-11-09 | Tokens, `nav.toc`, `--bar-guide` | None needed |
| `oklch()` | Not recovered: the API has no `oklch-function` id. `oklab` is Widely, 2023-05-09, 2025-11-09. | Every token | Not rechecked as its own feature |
| Relative color syntax | **Newly, 2024-09-16** | 8 uses of `oklch(from ...)` | **No `@supports` fallback and no stated floor in NOTES.md** (see New Ground) |
| `clamp()` | Not recovered: no API id found | Fluid type | Not rechecked |
| Logical properties | Widely, 2021-09-20, 2024-03-20 | Direction-aware sides | Sidenote and `nav.toc` physical `clear` precede `inline-end` |
| `aspect-ratio` | Widely, 2021-09-20, 2024-03-20 | Not used | No fixed-ratio media |
| Flexbox `gap` | Widely, 2021-04-26, 2023-10-26 | Component flex layouts | None needed |
| Dynamic viewport units | Widely, 2022-12-05, 2025-06-05 | Not used | No need |
| Scroll-driven animation | Limited | Not used | No need |
| View Transitions | Newly, 2025-10-14 (same-document) | Not used | NOTES.md records the decision |
| `@starting-style` | Newly, 2024-08-06 | Not used | No entry animation |
| CSS Grid Lanes | Limited | Not used | Explicit semantic order |
| `sibling-count()` | Newly, 2026-08-18. `sibling-index()` has no matching API id. | Not used | Not rechecked |
| Anchor positioning | **Limited** | Not used | No anchored popover |
| `@property` | Newly, 2024-07-09 | Not used | Unregistered tokens are simpler |

Corrections to 2026-09-30: subgrid Widely was 2026-03-15 (report said June 2026), cascade layers Widely was 2024-09-14 (report said March 2022, which is the Newly date), `@scope` Newly was 2026-03-24 (report said December 2025), anchor positioning is Limited (report said Newly, January 2026), and Grid Lanes remains Limited.

Mobile-first authoring: no change proposed.

## Responsive Usability Sweep

45 combinations: `dark.html`, `dark-conn-map.html`, `dark-charts.html` at widths 320, 375, 768, 1024, 1280 and heights 568, 768, 900. `scrollWidth` equaled `clientWidth` in every case. Method limit: Mermaid hidden, so diagram hatches are unmeasured. `.stat-strip` and `table.evidence-table` fit at 320px (288px wide). The loading, error and empty states: not applicable, the template implements none.

Targets in `samples/dark.html` at 1280px, from rendered rectangles: 54 targets, 25 under 44 x 44, 18 under 24 x 24.

- Under 24px: mostly inline links in running text (17 to 21px tall), which fall under the WCAG 2.5.8 inline exception. Two permalink anchors (`a.headerlink` 10 x 22, `a.anchor` 11 x 19) are not in a sentence. Whether the spacing exception covers them was not measured, so this is an open candidate, not a confirmed failure. They appear on heading hover and focus.
- Under 44px but 24 or more: seven block links, 28px tall. This is a usability gap against the 44px target. It is separate from WCAG 2.5.8.

## Accessibility Tool and Keyboard Checks

Axe, WAVE and Lighthouse were not available, so no automated accessibility result exists. Tab walk with Playwright in `samples/dark.html`, Mermaid hidden: dark, light and forced-colors dark, 59 focusable elements each, and every focused element showed an outline or box shadow (no element without an indicator). Shift+Tab, Enter, Space and Escape were not exercised, and the Mermaid zoom button and dialog were not reached, because Mermaid did not render. Manual screen reader testing did not run.

## WCAG Conformance Sweep

Status key: Pass, Not run, Not applicable. "Pass" here means the evidence below, not full conformance.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Not run | Delta has no image. Alt twins unchanged since 2026-09-30 |
| 1.3.1 Info and Relationships | A | Pass | New components use `table`, `thead`, `tfoot`, `caption`, `dl` |
| 1.3.2 Meaningful Sequence | A | Pass | `.stat-strip` DOM order equals visual order |
| 1.4.1 Use of Color | A | Pass | `td.bar.lead` uses weight 600, and values are printed text |
| 2.1.1 Keyboard | A | Not run | Tab walk reached 59 elements. Zoom button not reached |
| 2.1.2 No Keyboard Trap | A | Not run | Dialog not rendered |
| 2.4.2 Page Titled | A | Not run | Not rechecked |
| 2.4.3 Focus Order | A | Pass | Tab order followed DOM order in the walk |
| 2.4.4 Link Purpose | A | Not run | Not rechecked |
| 2.5.3 Label in Name | A | Not run | Zoom button not rendered |
| 3.1.1 Language of Page | A | Not run | Not rechecked this run |
| 3.2.1 On Focus | A | Pass | No context change during the Tab walk |
| 3.2.2 On Input | A | Not run | Filter not exercised |
| 4.1.2 Name, Role, Value | A | Not run | Custom widgets not exercised |
| 1.4.3 Contrast (Minimum) | AA | Pass | Palette gate inside `Contract OK` |
| 1.4.4 Resize Text | AA | Not run | No zoom run |
| 1.4.10 Reflow | AA | Pass | No page overflow at 320px in 3 fixtures, diagrams excluded |
| 1.4.11 Non-text Contrast | AA | Not run | Focus ring color not measured |
| 1.4.12 Text Spacing | AA | Not run | No override run |
| 1.4.13 Content on Hover or Focus | AA | Not run | Permalink reveal not tested |
| 2.4.6 Headings and Labels | AA | Not run | Not rechecked |
| 2.4.7 Focus Visible | AA | Pass | Indicator present in dark, light, forced colors |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Not run | Sticky `thead th` against focus was not tested |
| 3.2.3 Consistent Navigation | AA | Not applicable | No repeated navigation block |
| 3.2.4 Consistent Identification | AA | Not run | Not rechecked |
| 2.5.7 Dragging Movements | AA | Not applicable | No dragging feature |
| 2.5.8 Target Size (Minimum) | AA | Open | See responsive sweep: two permalink anchors unmeasured against the spacing exception |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step process |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication |
| 4.1.3 Status Messages | AA | Not run | Filter result count not exercised |

### Relevant AAA Criteria

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Not run | Not tested |
| 2.4.13 Focus Appearance | AAA | Not run | Indicator area not measured |
| 2.5.5 Target Size (Enhanced) | AAA | Not met | 25 of 54 targets under 44 x 44, see sweep |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication |

## Ungated-Rules Sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in the CSS or `mermaid.js` | Pass | CSS: line 2 only. `mermaid.js`: no match |
| Every `var(--x)` resolves | Pass | Set difference returned an empty list |
| Sides are logical | Pass | Two hits, both the sidenote and `nav.toc` physical `clear: right` before `clear: inline-end`, a documented fallback pair |
| Every `:hover` inside `@media (hover: hover)` | Pass | All hover lines fall in lines 418 to 428 |
| Decorative pseudo-element alt twin | Not run | Delta added no string-valued pseudo-element |
| Fixture instance per new selector | Pass | Every new selector has a fixture instance (Step 2 table) |
| Mermaid colors are hex | Pass | `rg 'oklch\|var\('` on `mermaid.js` returned nothing |
| Exact CDN pin | Pass | Five jsDelivr URLs, all pinned to exact versions |
| No line number into a generated file | Pass | Inside `Contract OK` |
| New composite grounds outside the gate | Pass | `--bar-guide` sits behind text and adds no text ground, and the delta adds no other composite ground |
| Em and en dash scan | Pass | `Contract OK` includes the dash gate |

## New Ground

**Relative color syntax has no stated browser floor.** `oklch(from var(--x) l c h / a)` appears 8 times in `tufte-dracula.css`. web-platform-dx lists relative color as Newly available since 2024-09-16, and the sheet has no `@supports` fallback for it. NOTES.md covers its contrast gating (check 10) but records no decision on the browsers that must render it. A browser without support drops the declaration. The remedy is a decision, not a mechanical fix: state the supported-browser floor in NOTES.md, or add fallbacks for the tinted fills. Left out of the patch for that reason.

## Challenges a Settled Decision

None.

## Out of Scope

Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo layout, and Odds and ends are outside the seven-topic map.

## Verification

No patch: nothing to propose. `nu scripts/maintain.nu check` printed `Contract OK` on `5aa8e71` with a clean tree. This run did not rerun the Mermaid-dependent probes.

## Counts

Findings: 3 (Mermaid 12.1.0, relative color floor, permalink target size candidate). Violations of a settled decision: 0. New: 3. Repeats: 1 (`nav.toc` ground). Challenges: 0. Corrections to the prior report: 2 (Mermaid latest, five Baseline dates). Evidence checks unavailable or incomplete: 7 (Mermaid-rendered sweep, zoom dialog keyboard, print render of new components, Lighthouse and field vitals, CSS Coverage, Axe or WAVE, full target-size spacing).

## Resolution

All three findings were resolved in v1.50.3 after the report was written. Mermaid moved to 12.1.0 through `nu scripts/maintain.nu mermaid 12.1.0`. NOTES.md now states the relative color support floor and forbids a hardcoded `@supports` twin. The permalink anchors pass the WCAG 2.5.8 spacing exception: the nearest other target sits 38px or more from each glyph centre at 1280px and 320px, so NOTES.md records that they stay glyph-sized. `Contract OK` held after the bump.
