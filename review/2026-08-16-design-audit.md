# Design audit: 2026-08-16

Re-run of the same calendar day. The first pass completed at 10:17 local; this
run overwrites it, which the skill defines as one audit per day. The material
change between the two is the work that landed after the first pass read the
tree: commit `b92f25f` (v1.29.0, 10:17) and commit `0905485` (v1.30.0, 12:19).
The first pass captured the tree before v1.29.0, so its six "new ground"
recommendations are now the story of this run.

Out of scope for this skill (per the topic map): Editor themes, Filter, Unclaimed
elements, Markdown coverage, Raw HTML and other generators, Fixtures are
coverage, Repo layout, Odds and ends. Their absence here is a scope decision, not
an oversight.

Zero findings challenge a settled decision this run. Every finding is
`[Reinforces]` (current practice agrees with a recorded decision),
`[Resolved since last pass]` (a first-pass recommendation is now implemented and
documented), `[Repeat, unchanged since 2026-08-16]` (in the first pass, nothing
new behind it), or `[New ground]` (NOTES.md has no decision on the point).

## Color and contrast

NOTES.md sections read: Color and the contrast budget, Appearance modes, Print,
Mermaid.

### Searched
- oklch function Baseline status widely available 2025 (carried from first pass)
- APCA WCAG 3 contrast algorithm status April 2026 editor's draft
- Display P3 gamut mapping oklch browser support 2026
- light-dark() CSS color function Baseline 2026 support
- forced-colors system color keywords AccentColor stability

### Findings

**[Reinforces]** `oklch()` is Baseline Widely available across all engines
(since May 2023). The sheet's exclusive use of `oklch()` for every `:root`
token, with hex kept only as `/* was */` provenance and in `mermaid.js`,
matches current practice.

**[Reinforces]** `color-scheme` and `forced-colors: active` are both Baseline
Widely available. The four mode blocks and the forced-colors border overrides
(`tufte-dracula.css:417-420`) match current guidance. The repo does not use the
still-stabilizing system keywords such as `AccentColor`, so that caveat does
not touch it.

**[Reinforces]** APCA versus WCAG 2. The decision to log the divergence and keep
WCAG 2 ratios as the enforced bar is now corroborated by a fresh source. The
Adrian Roselli note "WCAG3 Contrast as of April 2026"
(adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html, updated
2026-04-13) restates that the W3C contrast ratio test still carries the editor
note "yet to be determined," and that WCAG 3 is "years away," the soonest 2030.
The recorded decision is confirmed, not merely unchallenged.

**[Resolved since last pass]** P3 gamut for the six vivid accents. The first pass
flagged the accent gamut ceiling as an open question whether it should stay at
sRGB or move to P3. v1.29.0 implemented "P3 gamut for six vivid accents":
`--red`, `--orange`, `--purple`, `--pink`, `--green` and the `--data-*` ramp now
hold a Display-P3-reaching chroma in dark and light mode, with high contrast and
print holding the original sRGB values by design. `.github/palette-check.py`
gated it with `P3_WIDENED` and `P3_MODES` (`default` and `prefers-color-scheme:
light` only), and `oklch_to_hex` now reduces chroma to the sRGB ceiling before
converting for the hex-only consumers. NOTES.md records the decision. No further
action.

**[Resolved since last pass]** `light-dark()` considered and passed over. The
first pass recommended a NOTES.md line recording that `light-dark()` was
considered for the mode swap and rejected as more verbose for this repo's
fifteen-token-per-block shape. v1.29.0 added that exact entry. No further
action.

### Patch-worthy

Nothing to propose.

## Typography

NOTES.md sections read: Fonts, Type scale, Italics, Paragraphs and section
rhythm.

### Searched
- CSS text-wrap balance vs pretty Baseline 2026 Firefox support
- variable font woff2 range syntax font-variation-settings 2026
- OddBird fluid typography clamp vw rem 2026
- hyphens auto hyphenate-limit-chars availability 2026

### Findings

**[Reinforces]** The variable webfont strategy (one Source Serif 4 woff2 pair,
`font-weight: 200 900`, range syntax in `@font-face`) matches current practice.
`font-variation-settings` as a property is Baseline Widely available since
September 2018, and the range-syntax `@font-face` form predates it.

**[Reinforces]** `text-wrap: balance` scoped to `h1`/`h2` only
(`tufte-dracula.css:64,66`) matches the "short blocks only" guidance.

**[Resolved since last pass]** `text-wrap: pretty` is now documented. The first
pass found it in use (on `p`, `.sidenote`/`.marginnote`, `figcaption`/`caption`)
with no NOTES.md entry. v1.29.0 added the entry under Paragraphs and section
rhythm, stating the fallback is normal wrapping where the property is not read.
No further action.

**[Reinforces]** `hyphens: auto` stays scoped to the two narrowest prose
measures, with no use of `hyphenate-limit-chars`, which remains Limited
availability in Firefox.

**[Reinforces]** The body clamp floor 1rem, cap 1.25rem, ratio 1.25, sits
inside WCAG SC 1.4.4 bounds, as the January 2026 OddBird source corroborated in
the first pass.

### Patch-worthy

Nothing to propose.

## Layout and spacing

NOTES.md sections read: Width and measure, Lists, Tables, Connections-map
layout, Cascade layer.

### Searched
- CSS container queries Baseline 2026 status (carried from first pass)
- :has() selector usage 2026
- sticky table header scrollport keyboard focus 2026
- CSS fit-content intrinsic sizing 2026
- single-line flex row with trailing metadata truncation pattern

### Findings

**[Reinforces]** Container queries are Baseline Widely available (2025-08-14).
`section:has(> .scorecard)` plus `@container (max-width: 15em)`
(`tufte-dracula.css:245`) sits on a formally Widely available feature. The
separate rejection of a container query for `dl.timeline` is a blast-radius
argument, not a support gap, and the milestone does not touch it.

**[Reinforces]** `:has()` remains the most-used CSS feature in the 2025 State of
CSS survey. Its three uses here are unchanged.

**[Reinforces]** `@layer` is Baseline Widely available (2024-09-14). The
"one layer, not four" decision is architectural for a single inlined file.

**[Reinforces]** Current sticky-table-header guidance converges on exactly this
repo's implementation: one semantic `<table>`, an `overflow: auto` wrapper,
`position: sticky` on `th`, a keyboard-reach `tabindex`, a visible focus style.
NOTES.md already reflects all of this.

**[Resolved since last pass]** `.table-scroll` sticky-header focus. The first
pass raised WCAG 2.4.11 as an open question and recommended a real browser
check. v1.29.0 set `scroll-padding-top: 3em` on `.table-scroll`
(`tufte-dracula.css:160`), reproduced and fixed it against a headless-Chrome
measurement, and added one focusable cell to the wide-table fixture so a future
regression fails the staleness gate. NOTES.md records it under Tables. No
further action.

**[Implemented since last pass]** `.recent-group` single-line rows. v1.30.0 made
`.recent-group .nav-list li` a flex row so the trailing date sits on the same
line as the title, with the title truncating via `text-overflow: ellipsis`
rather than wrapping to push the date off the row
(`tufte-dracula.css:289-294`). NOTES.md records it under Lists. It is a settled
decision, not new ground. No new evidence is needed.

**[New ground, minor]** `:target { scroll-margin-block-start: var(--space-6) }`
at `tufte-dracula.css:91` offsets an anchored link so a jump target is not
stranded. NOTES.md has no entry for it. It is a small, correct affordance with
no defect and no settled decision to update. No action required; noted so the
line is not read as missing documentation next pass.

### Patch-worthy

Nothing to propose.

## Accessibility

NOTES.md sections read: Keyboard and assistive technology, Direction, zoom and
growth, Links.

### Searched
- :focus-visible Baseline status 2026 (carried from first pass)
- inert attribute Baseline widely available 2026
- native dialog showModal Escape focus trap 2026
- WCAG 2.2 2.4.11 Focus Not Obscured 2.5.8 Target Size Minimum
- WCAG 3 Silver draft status 2026

### Findings

**[Repeat, unchanged since 2026-08-16]** `:focus-visible` carries no `:focus`
fallback (`tufte-dracula.css:89-90`). Baseline Widely available since March
2022, so the no-fallback usage is safe. First pass flagged it; nothing new.

**[Reinforces]** `inert` on the overlay's siblings over `aria-hidden` is still
the right call. `inert` is Baseline Widely available (around October 2025).

**[Resolved since last pass]** Native `<dialog>` for the zoom overlay. The first
pass flagged this as an architectural question needing maintainer sign-off.
v1.29.0 adopted it: `mermaid.js` now opens a native `<dialog>` with
`showModal()`/`close()`, and the hand-rolled `role`/`aria-modal`/`inert`
toggle and the guarded document-level Escape listener are gone (the `cancel`
event now drives `hide()`, `mermaid.js:52-99`). The trade, that the exit does
not fade because `close()` is synchronous, is documented in NOTES.md under
Keyboard and assistive technology. No further action.

**[Resolved since last pass]** WCAG 2.2 2.4.11 and 2.5.8 for the zoom overlay.
The first pass reported `.mermaid-zoom` clearing the 2.5.8 floor at `40px`
(`tufte-dracula.css:318`), and raised 2.4.11 as an open question. Both are now
closed: 2.4.11 is fixed by the `scroll-padding-top` above, and 2.5.8 passes for
`.mermaid-zoom` (`40px`), `.nav-list li a` (`40px`, `44px` in high contrast),
and the recent-group "view all" link by the WCAG 2.5.8 inline-target exception
for text links. No further action.

**[New ground, informational]** WCAG 3 ("Silver") remains a Working Draft. The
April 2026 material projects Candidate no earlier than Q4 2027. WCAG 2.2 AA
stays the only applicable benchmark.

### WCAG conformance sweep

WCAG version confirmed this run: 2.2 (Recommendation, 2023-10-05). No newer
Recommendation exists; WCAG 3 is a Working Draft and its criteria are not checked
as binding.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | No `<img>` in any fixture. Mermaid svgs carry `accTitle:`/`accDescr:`, projected to `title`/`desc`. The outbound arrow carries empty alternative text via `content: "…" / ""` (`tufte-dracula.css:95-97`). |
| 1.3.1 Info and Relationships | A | Pass | Semantic `table`, heading hierarchy, `dl`/`dl.timeline`, `role="list"` on `nav-list` (`samples/light.html:833,855-858`). |
| 1.3.2 Meaningful Sequence | A | Pass | DOM order is visual order. `body.conn-map` flex reorder is covered in NOTES.md; no out-of-order focusable content. |
| 1.4.1 Use of Color | A | Pass | `.verdict`/`.verified`/`.unverified`/`.correction pair color with text and a `border`/`background` cue; not color alone. `forced-colors` borders at `tufte-dracula.css:417-420`. |
| 2.1.1 Keyboard | A | Pass | `.mermaid-zoom` button, `.table-scroll`/`pre`/`math` sideways scroll, and `[tabindex="0"]` hatch are all keyboard reachable. |
| 2.1.2 No Keyboard Trap | A | Pass | Native `<dialog>`: `showModal()` traps, `cancel` and backdrop click both exit (`mermaid.js:98-99`). |
| 2.4.2 Page Titled | A | Pass | Each fixture carries a distinct `<title>` (`samples/light.html:6`). |
| 2.4.3 Focus Order | A | Pass | Tab order follows visual order in every layout mode. |
| 2.4.4 Link Purpose | A | Pass | No bare "click here". The outbound arrow's empty alt is documented; "view all N" links name their target. |
| 2.5.3 Label in Name | A | Pass | `.mermaid-zoom` visible text "Zoom diagram" is a prefix of its `aria-label` "Zoom diagram: <title>". |
| 3.1.1 Language of Page | A | Pass | `<html lang="en">` in every fixture. |
| 3.2.1 On Focus | A | Pass | Focusing an element never changes context. |
| 3.2.2 On Input | A | Pass | The filter box never navigates or submits on input. |
| 4.1.2 Name, Role, Value | A | Pass | The `.table-scroll` region, the `<dialog>`, and the zoom button all carry name plus role. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference | Covered by Topic 1's palette gate; not re-measured here. |
| 1.4.4 Resize Text | AA | Pass | Body clamp ratio 1.25, inside the 2.5x bound. The 400% sideways-scroll exception for the scroll hatches is stated in NOTES.md and still holds. |
| 1.4.10 Reflow | AA | Pass | No two-dimensional scroll at 320 css pixels outside the opt-in `.table-scroll`/`pre`/`math` hatches. |
| 1.4.11 Non-text Contrast | AA | Pass | `:focus-visible` ring is `2px`/`3px` `--link` (`tufte-dracula.css:89-90,389-390`); `.verdict`, `.badge`, `code`, `kbd` carry a `currentColor` border (including in `forced-colors`). |
| 1.4.12 Text Spacing | AA | Pass | Layout is token-driven and grid/flex based; user line-height/letter-spacing overrides do not collapse it. |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content in the sheet. |
| 2.4.6 Headings and Labels | AA | Pass | Headings and the `.filter-label` describe their section. |
| 2.4.7 Focus Visible | AA | Pass | Every interactive element carries an `:focus-visible` outline, widened to `3px` in high contrast. |
| 2.4.11 Focus Not Obscured | AA | Pass | `scroll-padding-top: 3em` on `.table-scroll` keeps a focused cell clear of the sticky `th`; one focusable fixture cell keeps it gated. |
| 2.5.8 Target Size (Minimum) | AA | Pass | `.mermaid-zoom` `40px`, `.nav-list li a` `40px` (high contrast `44px`); the recent-group "view all" link meets the inline-target exception. |
| 4.1.3 Status Messages | AA | Pass | `filter.js` exposes its result count through a `role="status"` element (`samples/light.html:832`), a live region by default. |

### Patch-worthy

Nothing to propose.

## Interaction and motion

NOTES.md sections read: Interaction states, Form follows role.

### Searched
- prefers-reduced-motion 0.01ms vs 0 web.dev 2026
- View Transitions API Baseline 2026 cross-document support
- CSS scale individual transform property 2026
- dialog exit transition @starting-style transition-behavior

### Findings

**[Reinforces]** The global reduced-motion collapse to `0.01ms` rather than `0`
(`tufte-dracula.css:421-423`) matches the still-dominant pattern. `0ms` can be
treated as falsy and can drop `transitionend`. This repo's transitions are all
small, so the blanket collapse loses no nuance.

**[Reinforces]** The `scale` property on the resting rule for press feedback
(`.mermaid-zoom:active`, `.nav-list li a:active` at `0.96`) is correct.
Individual transform properties are Baseline Widely available since 2022-08-05.

**[Reinforces]** `ease-out` on every transition matches current interaction-design
guidance.

**[Resolved since last pass]** The View Transitions API. The first pass flagged
it as a gap in NOTES.md's interaction-state decisions. v1.29.0 added the entry:
considered for the overlay open/close, passed over because the existing `opacity`
transition already covers the need and cross-document support is not Baseline.

**[Resolved since last pass]** The overlay's exit does not fade. v1.29.0
documented the deliberate trade in NOTES.md: `close()` is synchronous, so a
property that no longer applies cannot transition. An exit fade via
`@starting-style` plus `transition-behavior: allow-discrete` was not pursued
because closing is a dismissal the user asked for. No further action.

### Patch-worthy

Nothing to propose.

## Pinned dependencies

NOTES.md sections read: Fonts, Mermaid.

### Searched
- `npm view @fontsource-variable/source-serif-4 version` (registry check)
- `npm view mermaid version` (registry check)

### Findings

**@fontsource-variable/source-serif-4**: pinned at 5.3.0
(`tufte-dracula.css:7,12`), which the npm registry confirms is the latest
published version, last modified 2026-07-19. Nothing to upgrade.

**mermaid**: pinned at 11.16.1 (`mermaid.js:2`), which the npm registry confirms
is the latest published version, last modified 2026-08-04. No interim release
exists. A future bump belongs behind `nu scripts/maintain.nu mermaid
<version>` per `CLAUDE.md`, since that command also touches the generated
`mermaid-palette.json` and fixtures.

Both pins pass this audit as current.

### Patch-worthy

Nothing to propose. No Mermaid bump is proposed, per the skill's rule that a
Mermaid change goes through the supported `maintain.nu mermaid` path.

## Challenges a settled decision

None this run.

## Verification

No patch file was written: every topic returned "nothing to propose." Step 5
(apply in a throwaway worktree, regenerate, run `nu scripts/maintain.nu check`)
is skipped per the skill's own rule, since Step 4 wrote no patch.

The contract was confirmed clean independently of any patch:
`nu scripts/maintain.nu check` printed `Contract OK` against the v1.30.0 tree at
the time of writing.

**Verdict: no patch: nothing to propose.**

## Summary

- Findings total: 27 body findings across 6 topics, plus the 25-row WCAG sweep
- Reinforces a settled decision: 15
- Resolved since last pass: 8 (P3 gamut, `light-dark()` doc, `text-wrap: pretty`
  doc, native `<dialog>`, WCAG 2.4.11/2.5.8 overlay, View Transitions doc, plus
  the related exit-fade and recent-group entries under them)
- Implemented since last pass: 1 (`.recent-group` single-line rows, now a
  settled decision)
- Repeat, unchanged since 2026-08-16: 1 (`:focus-visible` no fallback)
- New ground: 2 (`:target` scroll-margin, WCAG 3 status informational)
- Challenges a settled decision: 0
- Patch: none written
