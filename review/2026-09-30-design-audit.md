# Design Audit, 2026-09-30

Range: `f9aaa65..fa01958`, four commits. Previous report: `review/2026-09-22-design-audit.md`, which names `f9aaa65` as its start and end. `review/declined.md` has no findings. No finding matches a declined proposal.

This window has one CSS payload release and a new fixture set. It also changes the palette probe, generated samples, and documentation. The audit reviewed payload lines, rendered fixtures, current standards, and browser support. It found no confirmed defect that warrants a patch. The required connections-map component render, full keyboard sweep, CSS Coverage run, and complete WCAG target-size exception check remain unavailable. No patch is proposed.

## Step 2: Delta

The four commits are `fd1a544`, `60f7b64`, `ff2a9dc`, and `fa01958`. The payload delta changes pseudo-element alternative-text rules, adds a caption byline tier, changes `.edge-list` geometry, and adds instances for math and an emoji image. `NOTES.md` records the new component and typography decisions. `scripts/build-sample.nu` adds matching instances. Generated files were not edited by hand.

The alt-text twins for the tree arrow and pull quote now follow their base rules. This corrects the source-order defect from the prior audit. The outbound arrow and summary triangle remain covered by the same convention. The script probe now checks all four cases. The new probe assertions passed in the prior audit run on the unpatched and patched fixture states.

The new `.edge-list` divider and caption byline rules have real instances in `samples/dark.html`. The connection-map-specific `.edge-list` reset has no fixture instance in `samples/dark-conn-map.html`. `NOTES.md` explains that this reset protects consumer markup in the narrow Links rail. The missing instance is therefore a known and documented coverage limit, not an undocumented payload class.

The previous audit measured the changed component in a browser. At 1280px, `.edge-list` rendered as two 576px columns with a 1px divider and 16px inline-start padding on the second column. At 320px, it rendered as one 288px column without divider or extra padding. In RTL, the divider and padding moved to the right. The caption byline computed to `display: block`, at 16.56px on the wide render and 14.4px on the narrow render. Print kept the byline block. This audit did not capture a before-render for comparison.

The audit could measure `.edge-list` inside the connection-map Links rail only after another render at 1280px, 320px, RTL, and print. The command permission classifier denied a local probe because the page loads CDN-hosted code. The probe would load and run the fixture scripts. I did not retry it through another route. The audit did not verify this component-specific mitigation. The current CSS resets its columns, gap, gutter, and divider in the wide connection-map rail rule and in the narrow and print rules. No code change follows from an unrendered claim.

## Topic 1: Color and Contrast

No color token or appearance-mode rule changed in this window. The palette gate passed in the prior run: 17 tokens across four modes. `nav.toc` remains the only named contrast ground outside the palette gate. `NOTES.md` documents that limitation. The prior report corrected the former `nav.toc` forced-colors violation after rendering showed its boundary and link markers remained visible. No contrary result appeared in this window.

Current practice still supports the use of OKLCH and `color-mix()` where the sheet uses them. The palette gate remains the measurable contrast check for declared grounds. No APCA or color change is proposed. The wide prose measure remains closed to re-argument. This audit does not use line length or accessibility guidance to challenge that decision.

### Searched

- `OKLCH color-mix CSS Baseline 2026 status`
- `prefers-contrast forced-colors color contrast Baseline status`
- W3C WCAG 2.2, [Recommendation](https://www.w3.org/TR/WCAG22/), checked 2026-09-30.
- MDN, [forced-colors](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/forced-colors), checked 2026-09-30.
- MDN, [prefers-contrast](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-contrast), checked 2026-09-30.
- web.dev, [Baseline](https://web.dev/baseline/), checked 2026-09-30.

## Topic 2: Typography

The caption byline is a documented second annotation tier. Its `font-size: 1em` prevents the existing `.byline` size from compounding inside a caption. The prior browser render confirmed block display at wide and narrow viewports and in print. No type-scale or font decision changed.

`text-wrap: pretty` remains a progressive enhancement. MDN labels `text-wrap-style` Baseline 2024, Newly available. The value does not have the same support history as the `text-wrap` shorthand. Browsers that do not implement `pretty` keep normal line wrapping. No fallback rule is required for this non-critical typography enhancement. Current practice does not challenge the existing choice.

### Searched

- `CSS text-wrap pretty Baseline browser support 2026`
- MDN, [text-wrap-style](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-wrap-style), checked 2026-09-30.
- web.dev, [New to the web platform in September 2025](https://web.dev/blog/web-platform-09-2025), checked 2026-09-30.
- `CSS variable fonts typography text-wrap hyphenation 2026`

## Topic 3: Layout and Spacing

The divider gives the `.edge-list` tracks a visual boundary without a box or accent bar. Its logical border and padding mirror in RTL. The prior render measured the standalone fixture at 1280px and 320px and checked RTL and print. The new connection-map reset has no fixture instance. `NOTES.md` states why the rule remains. The extra rail probe did not run in this audit, so no new claim is made about its rendered output.

The page-level responsive sweep covered both dark fixtures at widths 320, 375, 768, 1024, and 1280px and heights 568, 768, and 900px. Chromium reported equal `scrollWidth` and `clientWidth` for all 30 viewport combinations. At 320px, code blocks, tables, and diagrams scrolled inside their documented hatches. The 2026-09-22 audit also reported no page-level overflow across the same matrix. The current component changes do not alter page width or breakpoints.

### Searched

- `container queries :has subgrid CSS Baseline status 2026`
- `CSS Grid Lanes anchor positioning sibling-index Baseline 2026`
- MDN, [container queries](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40container), checked 2026-09-30.
- MDN, [subgrid](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Grid_layout/Subgrid), checked 2026-09-30.
- web.dev, [Baseline](https://web.dev/baseline/), checked 2026-09-30.

## Topic 4: Accessibility

The decorative alternative-text defect identified in the 2026-09-22 audit is fixed in this payload. The new probe checks the four pseudo-element pairs, including the two that previously lost by source order. The prior audit ran the probe after the fix and reported all assertions passing.

The new math and emoji fixture instances address coverage, not new style behavior. Both math scroll containers carry the consumer-supplied focus and accessible-name attributes documented in `NOTES.md`. The connection-map `edge-list` change adds navigation links but the narrow rail markup is not represented in its fixture. The target-size review for that exact instance is incomplete, so this audit does not mark it as verified.

The previous audit measured the two heading permalinks at 1280px and 320px. Their rendered sizes were 11.9 by 28px and 8.8 by 23px on the wide viewport, then 10.3 by 24px and 7.7 by 20px on the narrow viewport. The previous report judged them against the WCAG 2.2 spacing exception. This run did not repeat the complete pairwise circle-spacing test for every undersized target. It carries the prior finding forward without extending that conclusion to the new connection-map links.

No new WCAG criterion or accessibility pattern makes a settled decision obsolete. WCAG 3.0 remains draft work. The full criterion-by-criterion status appears below. This is technical standards mapping, not a claim of legal compliance.

### Searched

- `WCAG 2.2 latest Recommendation WCAG 3.0 status September 2026`
- `WCAG 2.5.8 target size minimum spacing exception 2.5.5 enhanced`
- W3C, [WCAG 2.2](https://www.w3.org/TR/WCAG22/), checked 2026-09-30.
- W3C, [WCAG 3 September 2026 update](https://www.w3.org/WAI/news/2026-09-10/wcag3/), checked 2026-09-30.
- W3C, [Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), checked 2026-09-30.
- W3C, [Target Size Enhanced](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced), checked 2026-09-30.

## Topic 5: Interaction and Motion

The reduced-motion, hover, and focus rules did not change. All hover selectors remain inside `@media (hover: hover)`. The reduced-motion query still reduces transition duration and animation duration. MDN marks `prefers-reduced-motion`, `prefers-contrast`, and `forced-colors` Baseline Widely available. The previous report records reduced motion as Widely available since January 2020. No new interaction finding.

### Searched

- `prefers-reduced-motion 2026 CSS best practice scroll-driven animations Baseline`
- MDN, [prefers-reduced-motion](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion), checked 2026-09-30.
- MDN, [prefers-contrast](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-contrast), checked 2026-09-30.
- MDN, [forced-colors](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/forced-colors), checked 2026-09-30.

## Topic 6: Pinned Dependencies

The exact CDN pins remain `mermaid@12.0.0`, `@fontsource-variable/source-serif-4@5.3.0`, and `@fontsource-variable/jetbrains-mono@5.3.0`. The prior audit checked npm release metadata and provenance for all three and found no later release to take. Current registry fetches still report 12.0.0 and 5.3.0 as latest. No version change appears in the current diff. Do not add integrity attributes to remote ESM imports or `@font-face` URLs. Those constructs do not provide an SRI hook. The prior audit found npm provenance attestations for all three packages.

Mermaid 12.0.0 is a breaking release and changes default layout and appearance. The repository has already accepted those defaults and rendered its fixtures in all appearance modes. No additional bump is proposed. If a later bump is wanted, use `nu scripts/maintain.nu mermaid <version>`.

### Searched

- `Mermaid 12.0.0 release notes ELK default layout`
- `npm view <pkg> version time.modified dist.attestations` for each pin, checked in the prior audit.
- Registry metadata for [Mermaid](https://registry.npmjs.org/mermaid), fetched 2026-09-30.
- Registry metadata for [Source Serif 4](https://registry.npmjs.org/@fontsource-variable/source-serif-4), fetched 2026-09-30.
- Registry metadata for [JetBrains Mono](https://registry.npmjs.org/@fontsource-variable/jetbrains-mono), fetched 2026-09-30.
- Mermaid, [GitHub releases](https://github.com/mermaid-js/mermaid/releases), checked 2026-09-30.

| Package | Pinned | Latest checked | Provenance |
| --- | --- | --- | --- |
| `mermaid` | 12.0.0 | 12.0.0 | Present in prior npm metadata check |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.0 | Present in prior npm metadata check |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | Present in prior npm metadata check |

## Topic 7: Performance and Stability

No Lighthouse binary, Axe package, or WAVE tool was available locally. No Lighthouse lab run occurred. No public deployment request was made. Field LCP, INP, and CLS data are unavailable. Do not treat these measures as passing. The current web.dev good thresholds remain LCP at or below 2.5 seconds, INP at or below 200ms, and CLS at or below 0.1 at the 75th percentile. The 75th-percentile field thresholds do not convert this static fixture review into field data.

The fixtures load four pinned font files and the pinned Mermaid module. The stylesheet is inline, so it is not a separate render-blocking stylesheet request. The fixture includes a decorative noise data URI and Mermaid diagram content. Images and embedded content have reserved dimensions or CSS constraints where present. There is no ad slot. No image or timing audit ran, so no layout-shift score is claimed.

DevTools CSS Coverage was not available through the local tools used in this run. No selector is reported as unused. Fixture coverage would identify candidates only, not prove a consumer does not use a rule.

### Searched

- `Core Web Vitals thresholds LCP INP CLS good 75th percentile 2026`
- web.dev, [Core Web Vitals thresholds](https://web.dev/articles/defining-core-web-vitals-thresholds), checked 2026-09-30.
- Lighthouse local availability: `command -v lighthouse` returned no path.
- Accessibility tool availability: `command -v axe` returned no path. Python package lookup found no Axe Playwright package.

## Standards Status

WCAG 2.2 remains the latest W3C Recommendation found. The Recommendation page is dated 2024-12-12. The W3C page lists errata but the search did not identify a newer Recommendation. The 2026-09-10 WCAG 3 publication is a Working Draft update, not a conformance standard. The current draft and its criteria are not used as pass or fail criteria.

ISO lists ISO/IEC 40500:2025, Edition 2, as the published edition. ISO/IEC DIS 40500 Edition 3 remains under development. ETSI lists EN 301 549 V4.1.1 with a September 2026 cover date and records delivery to the European Commission on 2026-09-08. This audit did not verify an Official Journal citation for V4.1.1. Publication and delivery do not establish harmonisation. The ETSI draft comparison says clauses 9, 10, and 11 were updated toward WCAG 2.2, but this audit did not verify a complete V4.1.1 clause mapping.

This section maps technical criteria only. It does not claim legal compliance.

### Searched

- `W3C WCAG standards page latest Recommendation and revision date`
- `WCAG 3.0 working draft September 2026 status W3C`
- `ISO/IEC 40500:2025 current edition catalog`
- `ETSI EN 301 549 V4.1.1 2026 Official Journal harmonised standard EU`
- W3C, [WCAG 2.2](https://www.w3.org/TR/WCAG22/), checked 2026-09-30.
- W3C, [WCAG standards](https://www.w3.org/WAI/standards-guidelines/wcag/), checked 2026-09-30.
- W3C, [WCAG 3.0 introduction](https://www.w3.org/WAI/standards-guidelines/wcag/wcag3-intro/), checked 2026-09-30.
- ISO, [ISO/IEC 40500:2025](https://www.iso.org/standard/91029.html), checked 2026-09-30.
- ISO, [ISO/IEC DIS 40500 Edition 3](https://www.iso.org/standard/94018.html), checked 2026-09-30.
- ETSI, [EN 301 549 work item](https://portal.etsi.org/webapp/WorkProgram/Report_WorkItem.asp?WKI_ID=64282), checked 2026-09-30.
- ETSI, [EN 301 549 V4.1.1](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/04.01.00_30/en_301549v040100va.pdf), checked 2026-09-30.
- European Union, [Official Journal access](https://eur-lex.europa.eu/oj/direct-access.html), checked 2026-09-30. No V4.1.1 citation was confirmed.

## Modern CSS Baseline Review

Baseline status checked 2026-09-30. A feature family can contain properties with different dates and support. `Not Baseline` means no Baseline milestone was confirmed. Newly available features get fallbacks where this sheet uses them. This table does not recommend adding unused features.

| Feature | Baseline status and date | Current use | Fallback or reason not to adopt |
| --- | --- | --- | --- |
| Container queries | Widely available, August 2025 | `.scorecard` zoom adaptation | Existing media and base layout remain fallback |
| `:has()` | Widely available, June 2026 | Scope setup and captioned tables | Core content does not depend on it |
| Subgrid | Widely available, June 2026 | Not used | Current grid tracks do not need shared nested tracks |
| Cascade layers | Widely available, March 2022 | `@layer tufte-dracula` | No fallback needed for the current supported CSS audience |
| Native CSS nesting | Widely available, June 2026 | Not used | No build step. Current flat rules need no nesting transform |
| `@scope` | Newly available, December 2025 | Not used | Older consumers need `@supports`. Current rules need no new scope |
| `oklch()` and `color-mix()` | Widely available, November 2025 | Tokens and `nav.toc` mix | Current browsers support OKLCH. No new composited ground is proposed |
| `clamp()` | Widely available, exact date not recovered | Fluid type and page sizing | Current browsers support it. No alternate fluid-sizing fallback exists |
| Logical properties | Mixed support by property | Direction-aware spacing, borders, and alignment | Sidenote float has a physical fallback before `inline-end` |
| `aspect-ratio` | Widely available since 2021 | Not used | No fixture media needs a fixed ratio |
| Flexbox `gap` | Widely available since 2021 | Used in component flex layouts | No older-browser fallback. Current audience support is sufficient |
| Dynamic viewport units | Widely available, June 2025 | Not used | Existing viewport-height uses do not need dynamic browser chrome sizing |
| Scroll-driven animation | Not Baseline | Not used | No animation need warrants support risk or motion fallback |
| View Transitions | Same-document: Newly available, October 2025. Cross-document: Baseline not confirmed | Not used | Existing Mermaid fade is sufficient. NOTES.md records this decision |
| `@starting-style` | Newly available, August 2024 | Not used | No entry animation is needed. A fallback adds no value |
| CSS Grid Lanes | Not Baseline | Not used | Current grids have explicit semantic order and do not need masonry placement |
| `sibling-index()` | Newly available, August 2026. `sibling-count()` differs | Not used | No calculated sibling styling need. Add a fallback if adopted |
| CSS Anchor Positioning | Newly available, January 2026 | Not used | No anchored popover need. Older consumers need a fallback |
| `@property` | Newly available, July 2024 | Not used | No typed custom property need. Unregistered tokens are simpler |

Mobile-first authoring remains a practice, not a requirement to reverse established layout decisions. The stylesheet uses component and viewport conditions where each addresses a measured layout need. This audit does not propose breakpoint changes.

### Searched

- `Baseline 2026 CSS feature status newly available CSS anchor positioning sibling-index Grid Lanes :has native nesting date`
- `Baseline newly available CSS aspect-ratio flexbox gap logical properties clamp dynamic viewport units View Transitions starting-style property scope 2026`
- web.dev, [Baseline](https://web.dev/baseline/), checked 2026-09-30.
- web.dev, [Baseline 2026](https://web.dev/baseline/2026), checked 2026-09-30.
- web.dev, [June 2026 Baseline digest](https://web.dev/blog/baseline-digest-jun-2026), checked 2026-09-30.
- web.dev, [August 2026 platform update](https://web.dev/blog/web-platform-08-2026), checked 2026-09-30.
- web.dev, [December 2025 platform update](https://web.dev/blog/web-platform-12-2025), checked 2026-09-30.
- web.dev, [Same-document View Transitions](https://web.dev/blog/same-document-view-transitions-are-now-baseline-newly-available), checked 2026-09-30.
- MDN, [Grid Lanes](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Grid_layout/Grid_lanes), checked 2026-09-30.
- MDN, [CSS nesting](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Nesting), checked 2026-09-30.

## Responsive Usability Sweep

Chromium 152.0.7977.77 rendered `samples/dark.html` and `samples/dark-conn-map.html`. All three heights at each width produced the same page-level widths listed below. Each row therefore represents three measurements, one per required height: 568px, 768px, and 900px.

| Fixture | Viewport width | `scrollWidth` | `clientWidth` | Result |
| --- | ---: | ---: | ---: | --- |
| `samples/dark.html` | 320 | 320 | 320 | No page overflow |
| `samples/dark.html` | 375 | 375 | 375 | No page overflow |
| `samples/dark.html` | 768 | 768 | 768 | No page overflow |
| `samples/dark.html` | 1024 | 1024 | 1024 | No page overflow |
| `samples/dark.html` | 1280 | 1280 | 1280 | No page overflow |
| `samples/dark-conn-map.html` | 320 | 320 | 320 | No page overflow |
| `samples/dark-conn-map.html` | 375 | 375 | 375 | No page overflow |
| `samples/dark-conn-map.html` | 768 | 768 | 768 | No page overflow |
| `samples/dark-conn-map.html` | 1024 | 1024 | 1024 | No page overflow |
| `samples/dark-conn-map.html` | 1280 | 1280 | 1280 | No page overflow |

At 320px, code blocks, tables, and Mermaid content use their documented horizontal scroll hatches. The connection-map layout preserves markup order. Below 900px, Links precedes Graph in the stacked layout. The filter empty-result message is the only implemented empty state. The script probe covers the filter and status message.

The 44 by 44px usability target is not the WCAG 2.2 AA minimum. The prior render found targets below 44px, including heading permalink links and text links with 20px to 28px line boxes. Mermaid zoom buttons measured about 121 by 40px. These remain usability gaps against the requested 44px target. The full target inventory and spacing exceptions were not re-measured in this run. Do not read this result as a WCAG 2.5.8 failure.

## Accessibility Tool and Keyboard Checks

The prior audit ran the fixture script probe and reported 30 assertions passing, including the filter, Mermaid interactions, and all four decorative alternative-text twins. The previous audit also checked the changed component's focus behavior at representative viewport sizes. No Axe or WAVE executable was available. No external accessibility service received fixture content.

A complete manual Tab, Shift+Tab, Enter, Space, and Escape pass in dark, light, high-contrast, and forced-colors modes did not run in this audit. The previous report's focus evidence carries forward only for unchanged controls. No new passing claim is made for the added Links-rail markup.

## WCAG Conformance Sweep

WCAG 2.2 remains the current Recommendation found. This table covers each relevant criterion in the audit skill's fixed set. A status marked `Carried forward` relies on the prior audit evidence and means the current delta did not touch that behavior. `Incomplete` means this audit did not gather enough evidence to pass or fail the criterion.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass for delta | The tree-arrow and pull-quote alternative-text twins now follow their base rules. Prior script probe checked all four pairs. `kanban` and `timeline` naming limits remain documented. |
| 1.3.1 Info and Relationships | A | Carried forward | Semantic tables, lists, headings, and definition lists were unchanged. New math markup uses documented region semantics. |
| 1.3.2 Meaningful Sequence | A | Carried forward | Connection-map flex layout keeps DOM order. Responsive sweep shows stacking without a page-level reorder. |
| 1.4.1 Use of Color | A | Carried forward | Verdicts and status states retain text labels, not color alone. |
| 2.1.1 Keyboard | A | Incomplete for new rail | Existing table, math, and Mermaid scroll regions have keyboard affordances. New connection-map rail links were not rendered for a keyboard check. |
| 2.1.2 No Keyboard Trap | A | Carried forward | Mermaid uses native dialog behavior and a close path. No dialog behavior changed. |
| 2.4.2 Page Titled | A | Carried forward | Both generated fixtures have distinct titles. No title markup changed. |
| 2.4.3 Focus Order | A | Carried forward | DOM order remains meaningful. Full manual keyboard traversal did not run. |
| 2.4.4 Link Purpose (In Context) | A | Carried forward | New edge-list links have descriptive labels in fixture markup. No bare action label was added. |
| 2.5.3 Label in Name | A | Carried forward | Mermaid zoom button text remains included in its accessible name. |
| 3.1.1 Language of Page | A | Carried forward | Fixture roots retain `lang="en"`. |
| 3.2.1 On Focus | A | Carried forward | No focus-triggered context change was added. |
| 3.2.2 On Input | A | Carried forward | Filter behavior is unchanged and remains covered by the probe. |
| 4.1.2 Name, Role, Value | A | Carried forward | Native zoom button and dialog semantics remain unchanged. New math region names are in fixture markup. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference with documented gap | Palette gate covers declared grounds. `nav.toc` composited background remains documented as outside the gate. |
| 1.4.4 Resize Text | AA | Carried forward | Prior audit found current behavior consistent with the documented 400% exception. No size rule changed. |
| 1.4.10 Reflow | AA | Pass for tested matrix | Page-level `scrollWidth` equals `clientWidth` at every required viewport. This matrix does not equal a browser zoom test. |
| 1.4.11 Non-text Contrast | AA | Carried forward | Prior forced-colors render showed `nav.toc` border and link markers as system colors. No relevant rule changed. |
| 1.4.12 Text Spacing | AA | Carried forward | No text-spacing rule changed. The prior audit reported this row passing. |
| 1.4.13 Content on Hover or Focus | AA | Carried forward | No new hover-revealed content. Permalink behavior remains from prior rendered evidence. |
| 2.4.6 Headings and Labels | AA | Carried forward | New content has descriptive headings and caption text. |
| 2.4.7 Focus Visible | AA | Incomplete for new rail | Existing focus rules cover anchors and `tabindex="0"`. A full manual sweep across appearance modes did not run. |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Carried forward | No sticky header or overlay behavior changed. Prior table scrolling mitigation remains in place. |
| 3.2.3 Consistent Navigation | AA | Carried forward | Repeated fixture navigation retains the same relative order. |
| 3.2.4 Consistent Identification | AA | Carried forward | No repeated component changed its function or label pattern. |
| 2.5.7 Dragging Movements | AA | Not applicable | The template adds no author-provided dragging operation. Native scrolling is not a drag-only content control. |
| 2.5.8 Target Size (Minimum) | AA | Incomplete | Prior audit assessed the heading permalinks. This run did not recheck all 24px circle-spacing exceptions or the new Links-rail targets. |
| 3.2.6 Consistent Help | A | Not applicable | The template provides no repeated help mechanism. |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step form or repeated-entry process exists. |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication flow exists. |
| 4.1.3 Status Messages | AA | Carried forward | Filter result count remains a `role="status"` message and passed the prior script probe. |

### Relevant AAA Criteria

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Incomplete | No full traversal checked that part of every focused control remains visible. |
| 2.4.13 Focus Appearance | AAA | Incomplete | Focus ring width and contrast were not measured for every control and appearance mode. |
| 2.5.5 Target Size (Enhanced) | AAA | Usability gap | Prior renders show multiple targets below 44 by 44px. This is separate from AA 2.5.8 and requires target-specific exception review. |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication flow exists. |

Criteria outside the fixed table are not applicable. The audit skill lists audio/video, timers, flashing, bypass blocks, alternate navigation paths, custom gestures, motion controls, language switching, and form error prevention. WCAG 3.0 draft criteria are not conformance criteria.

## Ungated-Rules Sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comments in inlined CSS or Mermaid JavaScript, except machine-read CSS comments | Pass | Payload diff adds no comments to either inlined file. |
| Every `var(--x)` resolves or has a fallback | Pass, prior count corrected | `NOTES.md` lists six references outside `:root`. No new variable reference was added. |
| Direction-aware sides use logical properties | Pass | New divider and padding use inline logical properties. Prior RTL render moved them to the right. |
| Every hover selector sits inside `@media (hover: hover)` | Pass | No hover rule changed. |
| Decorative pseudo-element content has an alt-text twin after the base rule | Pass | Source order is corrected. The probe now asserts all four twins. |
| Uninstantiated styled classes have a documented reason | Pass with documented fixture limit | The connection-map `.edge-list` reset is described in `NOTES.md` as defensive consumer styling. |
| Mermaid colors use hex, not OKLCH or variables | Pass | Mermaid palette code did not change. |
| CDN dependencies use exact pins | Pass | The three pins remain exact versions. |
| Generated-file references use search strings, not line numbers | Pass | No new generated-file line reference was added. |
| Composited grounds outside the palette gate are documented | Pass | `nav.toc` remains the only documented ground outside the gate. |

## Challenges a Settled Decision

None. No current source or rendered result warrants reopening a decision in `NOTES.md`. The wide measure remains closed and is not proposed for change.

## Out of Scope

Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo layout, and Odds and ends are outside the seven-topic map. Fixture coverage was read only for the delta and documented component exception.

## Verification

No patch was written, so the patch worktree verification step did not apply. `nu scripts/maintain.nu check`, the palette gate, script probe, and mode renders passed in the prior audit run before this audit began. This audit did not rerun those checks. The component-specific live fixture probe was denied and remains unverified. No CSS Coverage, Lighthouse, Axe, WAVE, or complete manual keyboard run concluded.

No patch: nothing to propose.

## Counts

Findings: 0 confirmed actionable findings. Violations of settled decisions: 0. New findings: 0. Repeats: 4 topic decisions remain unchanged. Challenges: 0. Evidence checks unavailable or incomplete: 5, connection-map render, full keyboard pass, complete target-size spacing review, CSS Coverage, and performance lab tools.
