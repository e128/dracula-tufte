# Design Audit, 2026-11-20

Range: `a1df369..edade37`, **fifteen commits**: v1.60.0 through v1.68.2. Previous report:
`review/2026-10-31-design-audit.md`, which audited `99be251..a1df369`. `review/declined.md` has no
rows, so no finding matches a decline.

`HEAD` is `edade37` and equals `origin/main`; the tree was clean at the start. This run was asked to
focus on the `samples/` fixtures.

The window is large for two months: two chart components (`dl.meter`, `td.dot`), a font swap to the
`opsz` files, six Mermaid palettes, two seasonal CSS palettes, a date-range head snippet, and four
new forced-season preview pages. Every payload change answers a `NOTES.md` entry except one (D1).

Method: headless Microsoft Edge 157.0.4341.60 on macOS, driven over CDP with
`Emulation.setDeviceMetricsOverride`, `setEmulatedMedia`, forced-colors and reduced-motion feature
overrides, a cold cache, and device scale 1. `file://` loads, jsDelivr reachable. Layout, print, RTL,
focus, keyboard and performance readings are unthrottled lab data except where CPU throttling is
named. Field data is unavailable (no public deployment and no CrUX input for this run).

`CHROME="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" nu scripts/maintain.nu
check` printed `Contract OK`. The gates in that run reported `Palette OK (17 tokens, 8 modes)`,
`CONTRACT pointers resolve (51 search strings, 43 requirements)`, `Mode renders OK (28 images)`,
`Script binding OK (96 assertions)`, and `Season probe OK (247 assertions)`.

The probe harness used for every measurement below is now saved in
[`.claude/skills/design-audit/tools/`](../.claude/skills/design-audit/tools/README.md).

## Step 2: Delta

Every payload line added in the window, against the four questions.

| Change | NOTES.md documents it | Obeys AGENTS.md | Obeys a settled decision | A fixture renders it |
| --- | --- | --- | --- | --- |
| `opsz` webfont files replace `wght` (v1.62.0) | Yes, Fonts | Pass, no comment | Pass | Four faces in every fixture; both axes measured below |
| `dl.meter` (v1.60.0) | Yes, CSS charts | Pass | Pass | `samples/dark-charts.html`, search `class="meter"` |
| `td.dot` (v1.60.0) | Yes, CSS charts | Pass | Pass | `samples/dark-charts.html`, search `class="dot"` |
| Two seasonal palettes, six Mermaid maps, head snippet (v1.63.0 to v1.68.0) | Yes, Appearance modes and Seasonal palettes | Pass, hex only in `mermaid.js` | Pass | Four dark fixtures carry the snippet; four previews force the attribute |
| Mermaid 12.2.0 to 12.3.0 (v1.66.0) | Yes, Mermaid | Pass, exact pin | Pass | Every `pre.mermaid` fence |
| Filter input attributes (v1.68.2) | **No NOTES.md entry (D1)** | Pass | Pass | `samples/dark.html`, search `autocapitalize="off"` |
| `AGENTS.md` fixture count (v1.63.0 onward) | n/a | **Stale: "eight fixtures" (D2)** | n/a | Twelve files in `samples/` |

**D1 (Doc gap, in patch): the v1.68.2 filter attributes are recorded only in the commit message.**
The fixture's filter box now carries `autocomplete="off"`, `autocapitalize="off"`,
`spellcheck="false"` and `enterkeyhint="search"`. `NOTES.md`, Filter, does not mention them, and
`CONTRACT.md` § 2's filter-box bullet states only the label and placeholder obligations. The
fixture is authoritative for markup when the two disagree, so a consumer that follows CONTRACT.md
emits none of the four. The patch adds one sentence to CONTRACT § 2, with a search-string pointer,
and a paragraph to NOTES Filter stating the decision and its prohibition. No payload line changes.

**D2 (Doc drift, no patch): `AGENTS.md` still says `scripts/build-sample.nu` generates "all eight
fixtures".** `samples/` holds twelve: four dark fixtures, four light previews, and the four
forced-season previews added by v1.63.0 through v1.67.0. The other fixture claims in the contract
hold: `maintain.nu check` gates presence and the three-or-four `<script>` count per fixture. This
skill does not edit `AGENTS.md`; the correct sentence is "all twelve fixtures", with the four
seasonal previews named as previews rather than payload pages.

**D3 (New ground, no patch): layout shift on the diagram-heavy fixtures is caused by the webfont
swap.** Measured with a buffered `layout-shift` observer on a cold cache, after fonts settle:

| Fixture | CLS | Fonts blocked | Mermaid blocked |
| --- | --- | --- | --- |
| `samples/dark.html` | 0.0127 | 0.0000 | 0.0000 |
| `samples/dark-charts.html` | 0.1454 | 0.0000 | 0.1454 |
| `samples/light-charts.html` | 0.2055 | 0.0000 | 0.2055 |

The good threshold is 0.1, so two of the three fixtures are poor and the third is marginal. Blocking
the two font families returns zero in every run; blocking Mermaid changes nothing. The shift is one
entry whose sources are text nodes at the top of the document, and it happens at the font swap, not
at diagram insertion.

The mechanism is the `font-display: swap` pair plus `pre.mermaid`'s unreserved height. Until Mermaid
renders, that element holds raw fence text, which re-wraps when the mono face arrives; after it
renders, the SVG's height is font-dependent too. The `opsz` files are 122 KB roman and 130 KB
italic against 51 KB and 52 KB for the `wght` pair, so the swap lands later than it used to; NOTES
accepted the extra bytes for optical sizing but did not price this. **The one direct fix is closed:**
`size-adjust` on the mono face would shrink the raw-text re-wrap, but NOTES, Fonts, says **"No
face-specific `size-adjust` on JetBrains Mono"**, so that is a settled decision to challenge in a
separate turn, not to patch here. The alternatives are `font-display: optional` (a visible design
trade: the webfont may not appear on a first, slow load) and a reserved block size on `pre.mermaid`
(a guess per diagram). All three are design decisions, so none is in the patch.

**D4 (Repeat, unchanged since 2026-10-31): `h5` is dimmer than the body copy it introduces.** The
previous report's F1 still holds. Measured at 1280px in the Thanksgiving dark palette that today's
snippet selects: `h5` computes `oklch(0.83 0.045 75)` at weight 450; the paragraph under it computes
`oklch(0.972 0.014 90)` at weight 450. `h6` escapes on italic, `h5` does not. The same contradiction
between two NOTES passages is present; no mechanical fix exists.

**D5 (Repeat, still a candidate): the copy confirmation has no live region.** `highlight.js` changes
its own `aria-label` between `Copy code` and `Copied` on a focused button and restores it after 1.5
seconds. Whether a screen reader announces that name change is unverified. It remains a candidate
under 4.1.3, not a confirmed violation, exactly as the previous report recorded.

**Previous report claims re-checked.** F2 (the Georgia fallback collapsing 550 and 650) is now
documented in NOTES, Fonts: "no 550 or 650 either, so both steps map to 700 and `h3` and `h4`
render alike". D1 (print table background) still computes `rgba(0, 0, 0, 0)`. D3 (heading weight
ladder) still measures 650, 550, 450, 450 italic. The `scrollbar-gutter` passage (D2) still
describes current behavior and is not re-argued.

## Fixtures: what the twelve pages prove

The `samples/` focus is in this section rather than a separate topic.

- **Structure.** Every fixture has one `<style>`, one `<html lang="en">`, a distinct `<title>`, and
  either three `<script>` blocks (previews) or four (the four dark fixtures, adding the seasonal
  head snippet). `maintain.nu check` gates all of it. The twelve titles are distinct, and the eight
  previews say "forced" and name the forced mode.
- **The snippet is one text.** All four dark fixtures carry a byte-identical classic `<script>`, and
  `CONTRACT.md` § 1 carries the same block; `.github/season-probe.py` extracts and compares all
  five. The eight previews carry none, and each forces `data-season` in markup on `<html>` instead.
- **The date works.** Loaded on 2026-11-20, every dark fixture set `data-season="thanksgiving"` and
  `--mermaid-scheme` read `thanksgiving` before the first module script ran.
- **The previews do not follow the host.** `christmas-dark.html` and `thanksgiving-light.html` paint
  their forced palette with the OS dark, light, and high-contrast settings all switched; the
  season-probe's 247 assertions cover the boundary days in three time zones.
- **Headings.** No fixture skips a level (checked h1 through h6 in all twelve). There is exactly one
  `h1` per fixture.
- **Images.** The two `<img>` elements in each main fixture carry `alt`; the emoji image's `alt` is
  the emoji character and the banner image's `alt` describes the drawing.

## Topic 1: Color and contrast

**Reinforces the settled palette decisions.** `.github/palette-check.py` reports `Palette OK (17
tokens, 8 modes)` with the two new seasons included, each at its family's floor: 4.2 for the dark
family, 4.5 for light, 7.0 under `prefers-contrast: more`, and 3.0 for rule and data tokens. The
new components add no token: the meter fill and the dot both paint `--data-1` at full strength, the
meter track is `--rule`, and `.meter .s` is `--muted` at the annotation step. Rendered values at
1280px in the Thanksgiving dark preview: `.meter .v` `oklch(0.972 0.014 90)` on the surface,
`.meter .s` `oklch(0.76 0.04 75)`, dot fill `oklch(0.79 0.083 255)`. The one composite the gate
cannot reach is `--bar-guide`, `color-mix(in oklab, var(--rule-light) 40%, transparent)`; NOTES,
CSS charts, already classifies guides as a second reading whose numbers the cells state, so it is
decorative and not a 1.4.11 object.

**The season palette yields to contrast and print by media condition.** Verified in the cascade:
under `prefers-contrast: more` the season blocks do not match, and the dark palette paints (the
light block is source-earlier and loses the season tokens it does not restate). Under print media
the season blocks are `screen`-only, so the print tokens win. Rendered print surface for the meter
fill is the print `--data-1`, `oklch(0.624 0.146 255)`.

### Searched

- "oklch Display P3 gamut CSS color 4 browser support 2026 contrast", 2026-11-20.
- "prefers-contrast media query browser support Baseline 2026", 2026-11-20.
- Source: CSS Color Module Level 4, W3C Candidate Recommendation Draft, 18 November 2026,
  https://www.w3.org/TR/css-color-4/ (accessed 2026-11-20).
- Source: MDN, `prefers-contrast`, https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-contrast
  (accessed 2026-11-20): Baseline Widely available since 2022, and web-features dates it 2024-11-30.

## Topic 2: Typography

**Reinforces optical sizing, and verifies the risk it carried.** The `opsz` files were measured in
the browser for both axes: at a fixed 64px, `wght` 200 through 900 moves the advance from 721.0 to
761.7 px, and `opsz` 8 through 60 moves it from 893.1 to 730.3 px. So the swap did not cost the
weight ladder; `font-optical-sizing: auto` is the default and is doing the work. The default
rendering at 64px matched `wght 450` and `opsz 60`, as expected.

**`h5` remains the one typographic contradiction (D4).** See the delta.

**`text-wrap: balance` is now Widely available, and the sheet's use is unchanged and documented.**
The sheet sets it on `h1`, `h2`, `h3` only; NOTES, Type scale, gives the reason for excluding
`h4` to `h6`. Widely available is the tier the sheet already assumed.

### Searched

- "CSS font-optical-sizing Source Serif 4 variable font opsz axis best practice", 2026-11-20.
- "text-wrap balance pretty Baseline widely available date 2026", 2026-11-20.
- Source: MDN, `font-optical-sizing`,
  https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/font-optical-sizing
  (accessed 2026-11-20). Default is `auto`; do not pin `opsz` in `font-variation-settings`.
- Source: web.dev Baseline 2026, https://web.dev/baseline/2026 (accessed 2026-11-20), and MDN,
  `text-wrap`, https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-wrap
  (accessed 2026-11-20). `text-wrap: balance` is Widely available from 2026-11-13; `pretty` remains
  blocked by Firefox and is not Baseline.

## Topic 3: Layout and spacing

**No page-level horizontal overflow at any tested size, and the settled width is untouched.** The
sweep is in its own section below. The only over-wide boxes are inside a table's own
`overflow-x: auto`, which NOTES, Tables, documents as the sideways-scroll container at every width.
`--page-width` still resolves to `min(90vw, 160rem)` and no second convention was added.

**The new components obey the same direction rule.** `dl.meter::after` computes
`background-position: 0% 50%` in LTR and `100% 50%` under `dir="rtl"`; `td.dot` computes
`3.84px 50%` and `calc(100% - 3.84px) 50%` respectively, with the dot's `at` position mirrored from
65% to 35% at the same value. The RTL sweep found no physical-side declaration in the sheet.

### Searched

- "Baseline 2026 CSS features newly available color-mix oklch container queries status", 2026-11-20.
- "CSS Grid Lanes masonry sibling-index sibling-count @property anchor positioning Baseline 2026",
  2026-11-20.
- Source: modern.css Baseline tracker, https://modern-css.com/whats-new/baseline/ (accessed
  2026-11-20); web.dev Baseline 2026, https://web.dev/baseline/2026 (accessed 2026-11-20).

## Topic 4: Accessibility

The conformance sweep is separate below. The topic-level findings:

- **Reinforces the zoom-dialog decision.** Opened with a real click, the native `<dialog>` reports
  `open: true` and `:modal: true`, takes focus, and carries
  `aria-label="Zoom diagram: Decision flow sample"`. A trusted Escape key closes it (`open: false`,
  `innerHTML` length 0) and focus returns to the button. No keyboard trap.
- **Reinforces the filter decision.** The label's `for` matches the input id, `role="status"` is on
  the count, and typing `zzz` changes the count from `4 entries` to `0 entries`.
- **Reinforces the target-size decision.** At 1280px, 83 targets are present, 33 are under 44 by 44,
  and 15 are under 24 by 24. The undersized non-inline candidates are two footnote markers and one
  inline link; no two 24px circles around non-exempt targets intersect. The three `input` elements
  are two 18.3px checkboxes (user-agent controls, the margin-toggle pair NOTES documents as inert)
  and the 1125 by 52.1px search box.

### Searched

- "WCAG 2.2 focus appearance AAA 2.4.13 target size 24px exception guidance 2026", 2026-11-20.
- Source: WAI, Understanding SC 2.5.8, https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum
  (updated 2026-11-02, accessed 2026-11-20).
- Source: WAI, Understanding SC 2.4.13,
  https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance (updated 2026-10-04, accessed
  2026-11-20).

## Topic 5: Interaction and motion

**Reinforces the reduced-motion reset, with a note on current guidance.** The sheet keeps the global
`transition-duration: 0.01ms !important` and `animation-duration: 0.01ms !important` reset, and
NOTES records both the reason (`.live-dot`'s two-beat pulse freezes for free) and the `!important`
obligation in the cascade-layer entry. Current Chrome guidance discourages a blanket duration reset
because it can turn motion jarring, and prefers opting in under `no-preference`. The sheet has no
spatial motion: its transitions are color, text-decoration, opacity and a press `scale`, and the one
animation is two beats over four seconds, below the 2.2.2 five-second bar. Measured under
`prefers-reduced-motion: reduce`, both the root and `.mermaid-zoom` compute `1e-05s`. This is a
documented decision with a functional reason, not drift, so it is not re-litigated here.

**All ten `:hover` rules still sit inside `@media (hover: hover)`** (lines 529 to 541), which the
style lint gate confirms. No hover-revealed content exists, so 1.4.13 is not applicable.

### Searched

- "prefers-reduced-motion best practice 2026 animation duration !important", 2026-11-20.
- Source: Chrome Modern Web Guidance, Motion,
  https://developer.chrome.com/docs/modern-web-guidance/guides/ui-behaviors/motion (accessed
  2026-11-20).
- Source: MDN, `prefers-reduced-motion`,
  https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion
  (accessed 2026-11-20).

## Topic 6: Pinned dependencies

Read from the files, then checked against npm.

| Pin | Current release | Assessment |
| --- | --- | --- |
| `mermaid@12.3.0` | 12.3.0 | Current. Season support is already shipped. Do not bump in this patch; `nu scripts/maintain.nu mermaid <version>` is the supported path and it touches generated files. |
| `@fontsource-variable/source-serif-4@5.3.1` | 5.3.1 | Current. The `opsz` file pair is the one the sheet uses. |
| `@fontsource-variable/jetbrains-mono@5.3.0` | 5.3.0 | Current. |
| `@highlightjs/cdn-assets@11.12.0` | 11.12.0 | Current. |

**Provenance.** All four npm packages publish an SLSA provenance attestation
(`npm view <pkg> dist.attestations` returns `predicateType: https://slsa.dev/provenance/v1`), so the
supply-chain question resolves at the package, not at the CDN edge. SRI is not available for either
construct: `@font-face src: url()` has no integrity hook in any browser, and a bare-specifier ESM
`import` of a remote URL has none either. The exact-version pins are the remaining control, and
`maintain.nu check` gates them. Self-hosting was already weighed in NOTES and declined; it is not
re-proposed.

### Searched

- "mermaid 12.3.0 release notes changes 2026", 2026-11-20.
- Source: mermaid-js release notes, https://github.com/mermaid-js/mermaid/releases/tag/mermaid%4012.3.0
  (released 2026-11-03, accessed 2026-11-20).
- `npm view mermaid version time.modified`, `npm view @fontsource-variable/source-serif-4 version`,
  `npm view @fontsource-variable/jetbrains-mono version`, `npm view @highlightjs/cdn-assets version`,
  and `npm view <pkg> dist.attestations`, run 2026-11-20.

## Topic 7: Performance and stability

Thresholds checked against web.dev on 2026-11-20: LCP at or below 2.5 seconds, INP at or below
200 milliseconds, CLS at or below 0.1, all at the 75th percentile.

**Field data is unavailable.** This repo has no public deployment with CrUX coverage and no
instrumentation, so INP is reported as unavailable rather than inferred from Total Blocking Time.
Everything below is lab data.

**Coverage: no unused-rule candidate.** `CSS.startRuleUsageTracking` on a cold load reports 299 of
299 author rules used on `samples/dark.html`, 259 of 259 on `samples/dark-charts.html`, and 263 of
263 on `samples/light-charts.html`. These are fixture results, not proof that every consumer uses
every rule; no rule is proposed for removal on this evidence.

**Render-blocking resources.** The stylesheet is inline and is not a separate request. The fixtures
load the four font files, Mermaid's ESM entry and its chunks, and the highlighter from
`cdn.jsdelivr.net` only. `samples/dark.html` makes 58 resource requests totalling 1.19 MB;
`samples/dark-charts.html` and `samples/light-charts.html` make 70 totalling 1.35 MB. No ad slot
exists, so ad layout shift is not applicable. Images carry `alt` and the fixtures' images are
inline SVG data URLs with intrinsic dimensions.

**LCP and CLS are the measured metrics.** LCP on an unthrottled local load is 212 ms on
`samples/dark.html` and 36 ms on each chart fixture: far below the 2.5 second threshold, and not
representative of a consumer on a slow network. CLS is the one failing metric, and it is a font-swap
finding (D3): 0.0127, 0.1454 and 0.2055 against the 0.1 threshold. The isolation runs and the
mechanism are in the delta. **INP is unavailable:** there is no field data, and a lab run cannot
measure it. No interaction beyond the filter and the zoom dialog was instrumented.

### Searched

- "Core Web Vitals thresholds 2026 LCP INP CLS web.dev good", 2026-11-20.
- "font-display swap cumulative layout shift fallback metrics size-adjust 2026 web.dev",
  2026-11-20.
- Source: web.dev, Web Vitals, https://web.dev/articles/vitals (accessed 2026-11-20).
- Source: web.dev, Optimize CLS, https://web.dev/articles/optimize-cls (updated 2025-02-07,
  accessed 2026-11-20).
- Source: web.dev, CSS `size-adjust` for `@font-face`, https://web.dev/articles/css-size-adjust
  (accessed 2026-11-20).

## Standards status

| Area | Status on 2026-11-20 | Difference for this template |
| --- | --- | --- |
| WCAG Recommendation | WCAG 2.2, W3C Recommendation 2023-10-05, errata republication 2024-12-12, 86 active success criteria. https://www.w3.org/TR/WCAG22/ (accessed 2026-11-20). | None. The sweep below uses 2.2 A and AA plus the relevant AAA. |
| WCAG 3.0 | Working Draft 2026-09-10. The editor's draft is dated 2026-11-20 and is not a conformance standard. https://www.w3.org/TR/wcag-3.0/ (accessed 2026-11-20). | None. Draft only, no criteria applied. |
| ISO/IEC 40500 | ISO/IEC 40500:2025 is reported as the current ISO publication of WCAG 2.2. The ISO catalog URL in AGENTS.md returned HTTP 403 to this run, so this edition is taken from the alignment sources below and is **not** a direct catalog read. | Same criteria as WCAG 2.2 AA. |
| EN 301 549 | V4.1.1 adopted 2026-08-24, published 2026-09-02, aligning clauses 9 to 11 with WCAG 2.2 AA. Not cited in the EU Official Journal as of the sources checked; V3.2.1 (2021-03) remains the legally binding harmonised version. ETSI lists 2026-11-30 as an OJ target. EUR-Lex was not fetched directly in this run. | No technical difference for web content beyond the WCAG 2.2 delta already in the sweep. |
| Baseline definition | Baseline tiers by feature, per web-platform-dx; see the review below. | Report only. |

**Limits.** The W3C Recommendation page was fetched directly and shows this version as dated
2024-12-12, with errata. The ISO catalog rejected the request (403), and EUR-Lex was not fetched, so
the ISO edition and the Official Journal status above rest on the AccessibleEU note and the
practitioner summaries listed under `### Searched`, not on a primary read. They are reported as a
limit of this run, not as a pass.

This is a technical criteria mapping. It does not claim conformance with the European Accessibility
Act, Section 508, or any other law, and it does not infer harmonisation from publication or delivery.

### Searched

- "WCAG latest recommendation version 2026 W3C WCAG 2.2 2.3 status", 2026-11-20.
- "WCAG 3.0 working draft November 2026 latest publication", 2026-11-20.
- "EN 301 549 version 2026 Official Journal harmonised ISO/IEC 40500 edition", 2026-11-20.
- Sources: W3C WCAG 2.2, https://www.w3.org/TR/WCAG22/; W3C WCAG 3.0, https://www.w3.org/TR/wcag-3.0/;
  W3C publication history, https://www.w3.org/standards/history/wcag-3.0/; AccessibleEU on EN 301 549
  V4.1.1, https://accessible-eu-centre.ec.europa.eu/content-corner/news/european-accessibility-standard-en-301-549-has-been-updated-2026-09-07_en;
  all accessed 2026-11-20.

## Modern CSS Baseline review

| Feature | Baseline tier and date | Current use here | Fallback or reason not to adopt |
| --- | --- | --- | --- |
| Container queries | Newly available 2023-02-14; Widely available 2025-08-14 | `@container (max-width: 38em)` on `.scorecard` | None needed. |
| `:has()` | Widely available (2024-04) | Not used | Not needed; no selector here requires ancestor matching. |
| Subgrid | Widely available (2024-04) | Not used | The meter's sibling alignment is guaranteed by two grid tracks, and NOTES rejected a container that would have used shared tracks. |
| Cascade layers | Widely available (2023-12) | The whole sheet sits in `@layer tufte-dracula` | The layer is the consumer-override contract. |
| Native nesting | Widely available (2024-08) | Not used | No build step; flat selectors stay greppable. |
| `@scope` | Newly available 2026 | Not used | The sheet is one component system with class prefixes, not a composition surface. |
| `oklch()`, `color-mix()` | Widely available 2025-11-09 | Both used; `color-mix` for the bar guide | Relative color syntax has no fallback and is accepted in NOTES. |
| `clamp()` | Widely available | Body scale | None needed. |
| Logical properties | Widely available | Used throughout | The sidenote float is the one documented physical fallback. |
| `aspect-ratio` | Widely available (2021) | Used on the hero image box | None needed. |
| Flexbox `gap` | Widely available | Used | None needed. |
| Dynamic viewport units | Widely available | Not used | The page has no full-height viewport surface. |
| Scroll-driven animations | Newly available 2026-10 | Not used | Newly available; no current need, and would need `@supports`. |
| View Transitions | Newly available 2025-10; cross-document Limited | Considered for the zoom overlay and declined in NOTES | A dismissal should not animate; documented. |
| `@starting-style` | Newly available 2024-08 | Not used | Would be the only way to fade the overlay out, and NOTES declined that transition. |
| CSS Grid Lanes | Not Baseline (Safari only) | Not used | No masonry layout in the template. |
| `sibling-index()`, `sibling-count()` | Newly available 2026-08 | Not used | The dot and sparkline positions are inline `--bar`/`--h` values set by the generator, not sibling order. |
| Anchor positioning | Not Baseline (no Firefox) | Not used | Nothing is anchored to another element. |
| `@property` | Newly available (2024) | Not used | No registered custom property needs a typed value. |

**Mobile-first authoring.** The sheet is written from the resting desktop measure down: the 1000px,
900px, 760px and 600px blocks are subtractive. Reversing that authoring order would rewrite the one
settled width decision without changing a single rendered pixel, so it is recorded as current
practice and not adopted.

### Searched

- "Baseline 2026 CSS features newly available color-mix oklch container queries status", 2026-11-20.
- "CSS view transitions @starting-style scroll-driven animations Baseline status November 2026",
  2026-11-20.
- "CSS Grid Lanes masonry sibling-index sibling-count @property anchor positioning Baseline 2026",
  2026-11-20.
- Sources: web.dev Baseline 2026, https://web.dev/baseline/2026; modern.css Baseline tracker,
  https://modern-css.com/whats-new/baseline/; web-features explorer,
  https://web-platform-dx.github.io/web-features-explorer/; MDN Grid lanes,
  https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Grid_layout/Grid_lanes; all accessed
  2026-11-20.

## Responsive usability sweep

`samples/dark.html` and `samples/dark-conn-map.html` at all fifteen width and height combinations
(320, 375, 768, 1024, 1280 wide; 568, 768, 900 tall). `samples/dark-charts.html` at all fifteen.
`samples/dark-timeline.html`, `samples/light-charts.html`, and the four season previews at
320x568, 320x900, 1280x568 and 1280x900. `scrollWidth` is the document element's.

| Fixture set | Range of `scrollWidth` | Range of `clientWidth` | Page-level horizontal scroll |
| --- | --- | --- | --- |
| `dark.html`, `dark-conn-map.html`, 15 sizes each | 290 to 1250 | 305 to 1265 | None |
| `dark-charts.html`, 15 sizes | 290 to 1250 | 305 to 1265 | None |
| `dark-timeline.html` and previews, 4 sizes | 290 to 1250 | 305 to 1265 | None |

`scrollWidth` is below `clientWidth` at every size because the viewport reserves a classic
scrollbar. Overflow outside a hatch was found in exactly one shape: at 320px a `<caption>` and its
table extend past the table's own `clientWidth` (for example 311.6 against 305) while the table is
its own `overflow-x: auto` container, so the caption is reachable by scrolling the table and the
page itself does not move. That is the documented table hatch, not a page overflow.

Flex and grid stacking was checked against DOM order at 320px and 1280px: the connections-map
`article` still reorders only its two sections by design (NOTES, Connections-map layout), and the
meter grid places `dt`, `dd.v`, the spanning `dd.s`, then the band, which reads in DOM order.

**Targets below 44 by 44.** At 1280px on `dark.html`, 33 of 83. The great majority are inline links
inside prose, which the usability target (not 2.5.8) allows to be smaller; the two 44px controls
NOTES names, the copy button and the zoom button, both clear it. The permalinks stay glyph-sized on
the documented spacing exception.

**States.** The fixtures implement one dynamic state, the filter with zero matches, and it is
reachable and reversible: typing `zzz` yields `0 entries`, clearing it restores the four authored
entries. There is no loading state and no error state, and none was invented.

**Hierarchy and typography** were rendered at every width in the table. No heading level is skipped,
no fixture has more than one `h1`, and the settled scale is unchanged at 320px (h1 28px) and 1280px
(h1 32.07px).

## Accessibility tool and keyboard checks

Manual keyboard work was done in a real headless session, not inferred from the DOM.

| Check | Result |
| --- | --- |
| Tab order, `samples/dark.html` | 82 stops at 1280px, then the document body. Tab order follows DOM order; the filter, the details summaries and the copy buttons are all reachable. |
| Focus visibility | Every one of the 82 stops has a visible ring: `outline: 2px solid` in the link color at rest, `3px` under `prefers-contrast: more`, and Chromium's own `rgba(26, 235, 255, 0.8)` under forced colors. |
| Shift+Tab | The reverse walk returns the same sequence; no focus disappears into a hidden element. |
| Enter and Space | The copy button, the filter box and the details summaries take their native keys; the zoom button opens on Enter and returns to itself on close. |
| Escape | On `dark-conn-map.html`, a trusted Escape closes the modal dialog (`open: false`) and focus returns to `BUTTON.mermaid-zoom`. |
| Focus not obscured | Scrolling each focusable element into the middle of the viewport (93 at 320px, 88 at 1280px) and hit-testing its center found no author-created overlay. The one non-match at 320px is an inline link whose center falls on its parent paragraph's whitespace, not on an obscuring element. |

Automated results are not available for this repo beyond its own gates, and none would replace the
palette gate, the keyboard walk, or the rendered contrast checks.

## WCAG conformance sweep

WCAG 2.2 Recommendation, errata version 2024-12-12, accessed 2026-11-20. Criterion text and
techniques were checked against the WAI Understanding documents on that date.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | Both `<img>` elements carry `alt`; Mermaid fences carry `accTitle`/`accDescr` and the zoom button is named from the SVG title; every glyph pseudo-element has an `@supports` alt-text twin (`.github/script-probe.py` asserts the twins). |
| 1.3.1 Info and Relationships | A | Pass | Table headers use `scope`; heading order has no skips in any of the twelve fixtures; `dl.meter` uses one `dt` and two `dd`s; `role="list"` restores list semantics where `list-style: none` drops it. |
| 1.3.2 Meaningful Sequence | A | Pass | DOM order matches reading order. `body.conn-map` reorders two article sections by flex order, as documented; each section is self-contained and the visual order is the source order of the flex items. |
| 1.4.1 Use of Color | A | Pass | `.verdict` carries its word, `.hm` cells carry `role="img"` and an `aria-label`, links keep an underline as well as a color, and the meter states its percent as text beside the band. |
| 1.4.3 Contrast (Minimum) | AA | Pass | Palette gate, 8 modes, all text tokens at their family floor (4.2 dark, 4.5 light, 7.0 contrast, 4.5 print). The untested ground is the same one NOTES names: `mark`'s alpha wash. |
| 1.4.4 Resize Text | AA | Pass at 200% | Root at 32px on a 1280px viewport gives `scrollWidth` 1250 against `clientWidth` 1265, no page-level scroll. At 320px plus 200% text the page does scroll sideways (459 against 305); NOTES states the 400% case as knowingly not chased, and this combined case is past what 1.4.4 alone asks. |
| 1.4.10 Reflow | AA | Pass | 320 CSS pixels, no page-level two-dimensional scroll in any fixture or appearance mode. Tables, `pre`, `math` and diagrams are the documented opt-in hatches and scroll inside themselves. |
| 1.4.11 Non-text Contrast | AA | Pass | Focus rings paint `--link` (gated above 3:1), the meter track is `--rule` (gated at 3:1 against surface), the dot is `--data-1` (gated at 3:1), and the table and cell borders survive forced colors as `CanvasText`. |
| 1.4.12 Text Spacing | AA | Pass | Injecting line-height 1.5, letter-spacing 0.12em, word-spacing 0.16em and paragraph margin 2em leaves `scrollWidth` at 1250 against `clientWidth` 1265. |
| 1.4.13 Content on Hover or Focus | AA | Not applicable | No content is revealed by hover or focus; `.chart-takeaway .more` is always displayed and the mermaid hover is a ring. |
| 2.1.1 Keyboard | A | Pass | Every control is a native button, link, summary or input. Table, code, math and diagram scroll regions carry `tabindex="0"`; the narrow diagram region is added by script at the width where it can scroll. |
| 2.1.2 No Keyboard Trap | A | Pass | The modal dialog closes on Escape and restores focus to its opener; the filter and details have native exits. |
| 2.4.2 Page Titled | A | Pass | Twelve distinct `<title>` values, one per fixture. |
| 2.4.3 Focus Order | A | Pass | 82 Tab stops in DOM order; no stop moves backward visually. |
| 2.4.4 Link Purpose (In Context) | A | Pass | No bare "click here". Permalinks are named "Permalink to this heading"; the outbound arrow has an empty alt-text twin so it adds no text to the name. |
| 2.4.6 Headings and Labels | AA | Pass | Heading text describes its section; the filter input has a visible `<label for>` reading "Filter entries". |
| 2.4.7 Focus Visible | AA | Pass | Visible ring on all 82 stops in the default mode, and on the first stop in light, contrast and forced-colors sessions. |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Pass | No sticky header or author overlay covers a focused control. The index rail and table headers are sticky inside their own scrollers and never over the focus ring. |
| 2.5.3 Label in Name | A | Pass | The zoom button's visible text "Zoom diagram" is a prefix of its `aria-label` "Zoom diagram: <diagram title>". The copy button's visible form is an icon and its label changes as a whole. |
| 2.5.7 Dragging Movements | AA | Not applicable | No drag interaction exists; the only pointer gesture is a click. |
| 2.5.8 Target Size (Minimum) | AA | Pass | No 24px circle around a non-exempt undersized target intersects another. Permalinks use the spacing exception, documented in NOTES. The 18.3px checkboxes are user-agent controls. |
| 3.1.1 Language of Page | A | Pass | `lang="en"` on `<html>` in all twelve fixtures. |
| 3.2.1 On Focus | A | Pass | Focus never opens a dialog, navigates, or changes the filter state. |
| 3.2.2 On Input | A | Pass | The filter box only hides and shows entries; it never submits or navigates. |
| 3.2.3 Consistent Navigation | AA | Not applicable | The fixtures are single documents with no repeated site-wide navigation block. The `nav.toc` on each page is page-local. |
| 3.2.4 Consistent Identification | AA | Pass | The copy, zoom and permalink controls carry the same names on every fixture. |
| 3.2.6 Consistent Help | A | Not applicable | No help mechanism is repeated across pages. |
| 3.3.7 Redundant Entry | A | Not applicable | No multi-step process. |
| 3.3.8 Accessible Authentication (Minimum) | AA | Not applicable | No authentication. |
| 4.1.2 Name, Role, Value | A | Pass | Native `<dialog>` with `aria-label`, native `<button>`s, `role="region"` with a label on every scroll hatch, and `role="status"` on the filter count. |
| 4.1.3 Status Messages | AA | Pass, one candidate | The filter count is a `role="status"` live region and updates `4 entries` to `0 entries`. The copy confirmation changes a focused button's name only; whether it is announced is unverified (D5). |

Out of scope for this template, stated once: 1.2.x (no audio or video), 2.2.x (no timers or
sessions; the four-second pulse is below the five-second bar), 2.3.x (no flashing content), 2.4.1
and 2.4.5 (single documents with no repeated site navigation), 2.5.1, 2.5.2 and 2.5.4 (no custom
pointer gestures or motion actuation), and 3.1.2 (single-language prose; no mixed-language fixture).

### Relevant AAA criteria, tracked separately

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | Pass | No part of a focused control is hidden by author content, in the scroll and sticky states tested. |
| 2.4.13 Focus Appearance | AAA | Pass | The ring is a 2px (3px in contrast mode) outline with 2px offset; its color is `--link`, gated above 4.2:1 against every ground, so it clears the 3:1 focus-pixel requirement and the 2px perimeter. |
| 2.5.5 Target Size (Enhanced) | AAA | Fails as a usability target | 33 of 83 targets are under 44 by 44 at 1280px; the permalinks and inline links are deliberate, and the responsive sweep reports them as a usability gap, not an AA failure. |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Not applicable | No authentication. |

## Ungated-rules sweep

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in an inlined payload file | Pass | `tufte-dracula.css` has exactly one comment, line 2's version stamp; the `was #` notes are the documented exception. `mermaid.js`, `filter.js` and `highlight.js` have none. |
| Every `var(--x)` resolves or has a fallback | Pass | 43 declared custom properties; every `var()` reference resolves to a declaration or carries a fallback. |
| Sides are logical, never physical | Pass | No `border-left`, `padding-left`, `margin-left` or physical `left:`/`right:` declaration in the sheet; the RTL render flips the meter and dot as intended. |
| Every `:hover` rule sits inside `@media (hover: hover)` | Pass | All ten hover rules are lines 530 to 540, inside the block that opens at 529 and closes at 541. |
| Decorative pseudo-element content has an alt-text twin | Pass | Every string-valued `::before`/`::after` has an `@supports (content: "x" / "y")` twin with `content: "..." / ""`; the layer-stack arrow declares both in one rule. |
| A selector with no fixture instance has a documented reason or stays a candidate | Pass | All 240 class selectors in the sheet appear in at least one fixture; there is no unexercised class to excuse. |
| Mermaid colors are hex, never `oklch()` or `var()` | Pass | `mermaid.js` holds no `oklch` and no `var(` in a color position; six hex maps. |
| Exact CDN pin, never a range | Pass | Six URLs, four packages, no `^`, `~` or `latest`. |
| Never cite a line number into a generated file | Pass | `maintain.nu check` resolves 51 search-string pointers and 43 requirements; no new pointer in this run's output names a line. |
| A new composite ground has a NOTES entry or a gate | Pass | `--bar-guide` is documented under CSS charts; the meter and dot composites are covered by checks 5 and 12. |

No new gate is proposed. The one rule a short gate could mechanize, the fixture count in
`AGENTS.md`, cannot be patched here because this skill does not edit `AGENTS.md`, and a gate that
would fail on `HEAD` cannot ship without its fix.

## Skill currency review

The user asked for a check that the `design-audit` skill carries current standards and research.
The skill was read whole. **Its instructions are not edited by this run**; the items below are a
proposal for a separate maintainer-authorized change. The parts that are still right are stated too.
The one addition under the skill directory is the probe harness the user explicitly asked this run
to save: `tools/cdp.py`, `tools/probe.py` and `tools/README.md`. Those are tooling, not a rule, and
`SKILL.md` is untouched.

Confirmed current: WCAG 2.2 as the Recommendation with a 2024-12-12 errata date; 86 active success
criteria; WCAG 3.0 as a Working Draft and not a standard; the six new 2.2 criteria named in the
sweep; the fixed A and AA row list; the seven research topics; the commit-range anchoring; the
repeat and decline machinery.

**Factually wrong in the skill as written.** Step 3 says "Playwright is installed locally". It is
not: `python3 -c "import playwright"` raises `ModuleNotFoundError` on this machine. The tools
directory added by this run is the working replacement, and the skill should point at it instead of
naming a dependency that is absent.

**Standards and research to add or re-date.**

1. **EN 301 549 V4.1.1** (adopted 2026-08-24, published 2026-09-02) is not in the skill. Clauses 9
   to 11 now align with WCAG 2.2 AA. Add it to the Accessibility Checks source list, with the
   Official Journal caveat the skill already states.
2. **ISO/IEC 40500:2025** is the current edition and matches WCAG 2.2 AA. The skill names the ISO
   catalog but not this edition.
3. **WCAG 3.0** moved to a 2026-09-10 Working Draft, with an editor's draft dated 2026-11-20. The
   skill already says "recheck every run"; record the current draft date in that run's report.
4. **Baseline additions the fixed feature table lacks.** Container *style* queries (Newly available
   2026-05), `contrast-color()`, `@scope` (Newly available 2026), `shape()`, `field-sizing`, `:open`,
   `light-dark()` (Widely available 2026-11-13), `reading-flow`, `text-wrap: pretty` (still blocked
   by Firefox; not Baseline). `text-wrap: balance` is now Widely available 2026-11-13 and should
   carry that date in the table. Grid Lanes is still not Baseline, in Safari only.
5. **Scroll-driven animations** crossed Baseline Newly available in 2026-10. They are already in the
   table; add the date so the "newly available needs `@supports`" rule bites.
6. **`prefers-reduced-motion` guidance changed.** Chrome's 2026 guidance now discourages the global
   `animation-duration: 0.01ms !important` reset and prefers `no-preference` opt-in. Topic 5 should
   say so, so a run does not report the sheet's documented reset as drift.
7. **Topic 6 should name provenance.** Every CDN package used here publishes an SLSA attestation;
   the skill currently asks only about freshness and says SRI is unavailable. Add
   `npm view <pkg> dist.attestations` to the check.
8. **Topic 7 should name the font-swap CLS check.** The isolation technique is cheap: run CLS on a
   cold load, then again with the font URLs blocked. A zero-with-fonts-blocked result attributes
   the shift to the swap. This run's D3 is the first finding that needed it.

**Process gaps in the skill, not standards gaps.**

- Step 7's worktree path under `/tmp` fails on this Mac: `/tmp` is a symlink to `/private/tmp`, and
  `maintain.nu`'s pointer resolver calls `path relative-to $ROOT`, which raises `prefix not found`
  when the root is `/tmp/...` and the expanded target is `/private/tmp/...`. Use a path with no
  symlink anywhere in it, such as a sibling directory of the repo. The verification in this run used
  `../dracula-tufte-verify` for that reason.
- The step that says "add an assertion" to `.github/script-probe.py` for payload changes is right,
  but the same paragraph should say that `season-probe.py` already gates the snippet and the six
  palettes, so a later run does not add a duplicate.

## Challenges a settled decision

None. D3's most direct remedy, `size-adjust` on the mono face, would reopen a decision NOTES closes
in prose, and the other remedies are design trade-offs rather than a spec change. No challenge is
raised, so nothing here needs maintainer sign-off before a later run can touch the stylesheet.

## Step 7: verification

The patch touches `CONTRACT.md` and `NOTES.md` only: one documentation sentence and one NOTES
paragraph, both stating markup the fixture already carries. No payload line changes, so no rendered
component changes and the probe geometry above is unchanged.

Verified in a detached worktree at `HEAD`, with the patch applied and the repository's own gates run:

```
CHROME=".../Microsoft Edge" nu scripts/build-sample.nu     # exit 0
CHROME=".../Microsoft Edge" nu scripts/maintain.nu check   # Contract OK
```

The gate re-rendered 28 mode images, ran 96 script assertions and 247 season assertions, and
re-resolved 52 CONTRACT search strings, up from 51 on `HEAD`, which proves the new
`autocapitalize="off"` pointer was parsed and found. Both files were scanned for em and en dashes
(none) and every added patch line was read for a comment in an inlined payload file (none; the
patch touches no payload file).

**Verdict: Verified: patch applies to HEAD and Contract OK after regeneration.**

## Out of scope

The NOTES.md sections outside the fixed topic map were not swept: Filter is used only where the
delta touches it, and Unclaimed elements, Markdown coverage, Raw HTML and other generators, Repo
layout, and Odds and ends were not read for findings. `themes/` was regenerated by the gates and
`create-themes.nu --check` passed, but no theme file was reviewed for color parity in this run.

## Post-audit application

After this report was written, the maintainer asked for all five findings to be applied. This
section records what changed; the findings above are the audit record and are not rewritten.

| Finding | Applied change | Evidence |
| --- | --- | --- |
| D1 | `CONTRACT.md` § 2 states the four filter attributes; `NOTES.md`, Filter, records the decision. | This report's patch, applied to the working tree. |
| D2 | `AGENTS.md` now says twelve fixtures and names the three groups. | `samples/` holds twelve files. |
| D3 | All four `@font-face` rules are `font-display: optional`. | CLS re-measured 0.0000 on all three fixtures with the font requests live; a warm load still uses both faces. NOTES, Fonts, records the trade. |
| D4 | `h5` is weight 500. | Rendered ladder 650, 550, 500, 450 italic; `h5` now sits above body 450. NOTES, Type scale, updated. |
| D5 | `highlight.js` appends one visually hidden `role="status"` region, announces `Copied`, and clears it with the button label. | `.github/script-probe.py` carries four new assertions (100 total). Removing the announcement line fails `copy-status-announces`; restoring it passes. |

`CHROME=".../Microsoft Edge" nu scripts/maintain.nu check` printed `Contract OK` after the change
set, with `Script binding OK (100 assertions)`. The version stamp still reads v1.68.2; no bump or
release was part of this application.
