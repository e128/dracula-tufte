# Design audit: 2026-08-16

First run of this skill. No previous `review/*-design-audit.md` exists and
`review/declined.md` does not exist, so this run has no anchor window, no
repeats, and no declines to check. It covers current practice as of
2026-08-16 against every decision recorded in `NOTES.md` on that date.

Out of scope for this skill (per the topic map): Editor themes, Filter,
Unclaimed elements, Markdown coverage, Raw HTML and other generators,
Fixtures are coverage, Repo layout, Odds and ends. Their absence here is a
scope decision, not an oversight.

Zero findings challenge a settled decision this run. Every finding below is
either `[Reinforces]` (current practice still agrees with the recorded
decision) or `[New ground]` (NOTES.md has no decision on the point at all).

## Color and contrast

NOTES.md sections read: Color and the contrast budget, Appearance modes,
Print, Mermaid.

### Searched
- OKLCH color-scheme Baseline 2025 caniuse widely available
- APCA WCAG 3 W3C draft status 2025 2026 contrast algorithm
- forced-colors media query Baseline status 2025
- light-dark() CSS function Baseline 2025 support
- CSS Color 4 gamut mapping display-p3 oklch browser support 2025 2026 wide gamut screens

### Findings

**[Reinforces]** `oklch()` is Baseline Widely available (all engines since
May 2023, MDN `oklch()`). The sheet's exclusive use of `oklch()` for every
`:root` token, hex kept only as provenance comments and in `mermaid.js`,
matches current practice.

**[Reinforces]** `color-scheme` is Baseline Widely available (since January
2022, MDN `color-scheme`). `tufte-dracula.css:15,383,415` already set it
correctly per mode.

**[Reinforces]** `forced-colors: active` is Baseline Widely available (since
September 2022, MDN `forced-colors`). NOTES.md's forced-colors section and
`tufte-dracula.css:406-409` match current guidance. The repo does not use
the still-stabilizing system color keywords (`AccentColor`), so that
caveat does not touch it.

**[Reinforces]** APCA vs WCAG 2. NOTES.md already states the divergence and
keeps WCAG 2 ratios as the enforced bar. Current research strengthens this:
APCA was pulled from the WCAG 3 working draft and the most recent published
draft (August 2025) carries no contrast method at all (Adrian Roselli,
"WCAG3 Contrast as of April 2026," adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html;
W3C wcag3 issue #29). WCAG 3 is not projected to reach Recommendation before
2027 to 2028. The recorded decision to log the divergence rather than chase
it is confirmed, not merely unchallenged.

**[New ground]** `light-dark()` is Baseline Newly available since May 2024,
projected to reach Widely available 2026-11-13 (web-platform-dx feature
explorer, MDN `light-dark()`). NOTES.md has no passage on it: every mode
swap here is a full re-declared `:root` block under three separate media
queries. This repo swaps roughly fifteen tokens per mode as one unit;
`light-dark()` is a per-declaration ternary, so it would mean writing the
function fifteen times inline instead of one override block, more verbose
for this repo's shape. Not proposing a change. Worth one line in NOTES.md
recording that this was considered and passed over, if the maintainer
agrees with the reasoning above.

**[New ground]** Display P3 / wide-gamut color. NOTES.md's gamut section
scopes entirely to the sRGB boundary, and check 7 (`.github/palette-check.py`)
gates every parsed token to it. Current practice (Chrome for Developers' HD
color guide, colorui.io's Display P3 guide) treats `color(display-p3 ...)`
and P3-reaching `oklch()` chroma as safe to declare today, since
unsupported displays gamut-map automatically and P3 screens are now common.
NOTES.md never states whether the accent ceiling should stay at sRGB or
move to P3. This is an open question, not a defect. Moving it would touch
checks 7 and 8, the same cost NOTES.md already flags as expensive for
chroma changes. Flagging for the maintainer to decide whether "we stay at
sRGB" belongs in NOTES.md as a stated decision, or this goes to
`backlog.md`.

### Patch-worthy

Nothing to propose.

## Typography

NOTES.md sections read: Fonts, Type scale, Italics, Paragraphs and section
rhythm.

### Searched
- CSS text-wrap balance pretty Baseline browser support 2025
- CSS hyphens auto hyphenate-limit-chars Baseline support 2025 2026
- variable fonts woff2 Baseline status MDN font-variation-settings 2024 2025
- font-size-adjust font-optical-sizing Baseline 2025 fluid type scale clamp best practice update
- OddBird "Responsive and fluid typography with Baseline CSS features" clamp vw rem zoom problem

### Findings

**[Reinforces]** The variable webfont strategy (one Source Serif 4 woff2,
roman and italic, `font-weight: 200 900`) uses `@font-face` range syntax
rather than the not-yet-Baseline `font-variation-settings` descriptor form.
`font-variation-settings` (the property) is Baseline Widely available since
September 2018; 2025 compatibility data puts WOFF2 and variable-font
support above 93 to 97 percent (font-converters.com 2025 guide; MDN
`font-variation-settings`). No change indicated.

**[Reinforces]** `text-wrap: balance` scoped to `h1`/`h2` only
(`tufte-dracula.css:64,66`). `balance` reached Baseline Newly available May
2024 (MDN `text-wrap`) and current guidance still restricts it to short
blocks, matching the existing scope exactly.

**[New ground]** `text-wrap: pretty` is already in production use
(`tufte-dracula.css:71,82,209`, on `p`, `.sidenote`/`.marginnote`, and
`figcaption`/`caption`) but NOTES.md's Paragraphs and section rhythm
section never mentions `text-wrap` at all. As of early 2026, `pretty` is
Chrome/Edge 117+ and Safari 26+ but not shipped in Firefox (WebKit blog,
"Better typography with text-wrap: pretty"), so it is not full Baseline.
Firefox falls back to normal wrapping with no breakage, so current usage is
safe progressive enhancement, but it is an implemented decision with no
recorded rationale. A short NOTES.md entry would close the gap; not
proposed here since it is documentation, not a stylesheet change.

**[Reinforces]** `hyphens: auto` stays narrowly scoped to the
sidenote/marginnote and `.col-2`, with no use of the finer-grained
`hyphenate-limit-chars`, which remains Limited availability because Firefox
support is incomplete as of 2025 to 2026 (MDN `hyphenate-limit-chars`;
caniuse). The hand-scoped-by-selector approach is still the correct call.

**[Reinforces]** The body clamp (`clamp(1rem, 0.95rem + 0.25vw, 1.25rem)`,
floor 1rem, cap 1.25rem) matches the pattern a January 2026 source
independently converges on: combine a `vw` term with an `em`/`rem` term so
browser zoom still moves the rem component, and keep the max-to-min ratio
at or below 2.5x for WCAG SC 1.4.4 (OddBird, "Responsive and fluid
typography with Baseline CSS features," oddbird.net/2026/01/08, also on
web.dev). This repo's ratio is 1.25, well inside that bound. A decision
NOTES.md made earlier is now independently corroborated by a fresh source,
not just still-tolerated.

### Patch-worthy

Nothing to propose. The one gap found (`text-wrap: pretty` undocumented) is
a NOTES.md documentation gap, not a CSS change.

## Layout and spacing

NOTES.md sections read: Width and measure, Lists, Tables, Connections-map
layout, Cascade layer.

### Searched
- CSS container queries Baseline status 2025 caniuse widely available
- :has() selector CSS Baseline status 2025 support
- CSS @layer cascade layers Baseline widely available support 2025
- sticky table header scrollable table accessibility technique 2025 2026
- CSS fit-content min-content max-content Baseline support width intrinsic sizing 2025

### Findings

**[Reinforces]** Container queries reached Baseline Widely available on
2025-08-14 (web-platform-dx feature explorer; web.dev Baseline digest,
August 2025). The repo already uses `container-type: inline-size` on
`section:has(> .scorecard)` plus an `@container (max-width: 15em)` query
(`tufte-dracula.css:245,361`), recorded in NOTES.md (lines 1002 to 1017) as
the fix for `.scorecard` overflow under text-only zoom, since a container
query resolves `em` against the container's font size. That decision now
sits on a formally Widely available feature. No change needed.

**[Reinforces]** NOTES.md's separate rejection of a container query for
`dl.timeline` (a container-type on `<article>` would apply layout
containment to every consumer's whole document to fix one component) is a
blast-radius argument, not a support gap. The Baseline milestone above does
not touch it.

**[Reinforces]** `:has()` reached Baseline Newly available December 2023
and by 2025 is the most-used, most-loved CSS feature in the State of CSS
2025 survey. The sheet already uses it three times (`table:has(caption)`,
`li:has(input[type="checkbox"]:first-child)`,
`section:has(> .scorecard)`). NOTES.md's rejection of
`:has(> .links)` for the conn-map, on the grounds of two layout paths in a
file every consumer inlines verbatim, is a maintenance-cost argument that
current practice does not override.

**[Reinforces]** `@layer` reached Baseline Widely available on
2024-09-14. NOTES.md's "one layer, not four" decision is architectural for
a single inlined file, not a support question.

**[Reinforces]** Current 2025 to 2026 sticky-table-header guidance
(Stanford accessibility guide; Accessibility Developer Guide) converges on
exactly this repo's implementation: one semantic `<table>`, an
`overflow: auto` wrapper, `position: sticky` on `th`, `tabindex="0"` for
keyboard reach (needed because Chrome does not make scroll regions
focusable by default), a visible focus style, and warnings against
duplicate-header-table or CSS-Grid-table reimplementations. NOTES.md's
Tables section already reflects all of this. No new pattern to adopt.

**[New ground]** Intrinsic sizing keywords (`fit-content`, `max-content`)
are used as plain keywords at several lines. These reached broad support
years ago and no source suggests any change in guidance. NOTES.md has no
dedicated section on intrinsic sizing (the reasoning lives inline in
Tables and Lists), consistent with there being no open question. Nothing
to add.

No search turned up anything bearing on `--page-width`, the long-measure
decision, or the breakpoint split. Those stay hard-settled per `CLAUDE.md`
and nothing here rises to strong new evidence.

### Patch-worthy

Nothing to propose.

## Accessibility

NOTES.md sections read: Keyboard and assistive technology, Direction, zoom
and growth, Links.

### Searched
- focus-visible Baseline status caniuse 2025
- inert attribute Baseline status caniuse date
- WCAG 3 Silver draft status 2026 W3C
- dialog element native focus trap support 2025 MDN Baseline
- WCAG 2.2 new success criteria 2.4.11 Focus Not Obscured 2.5.8 Target Size Minimum

### Findings

**[New ground]** `:focus-visible` has no `:focus` fallback anywhere in the
sheet (`tufte-dracula.css:89-90,378-379`), and NOTES.md never states a
decision about this specifically. `:focus-visible` is Baseline Widely
available, interoperable across engines since March 2022 (MDN
`:focus-visible`). Current no-fallback usage is safe as written; nothing to
change.

**[Reinforces]** `inert` on the overlay's siblings, chosen over
`aria-hidden` because `aria-hidden` hides from assistive technology while
leaving the element focusable, is still the right call. `inert` reached
Baseline Newly available April 2023 and Widely available around October
2025 (MDN, web.dev Baseline data). The decision to depend on it
unconditionally holds.

**[New ground]** Native `<dialog>` now does automatically what
`mermaid.js`'s zoom overlay hand-rolls: `showModal()` traps focus, adds
`::backdrop`, and wires Escape, without the custom keydown guard or manual
`inert`-toggling siblings NOTES.md describes. NOTES.md never considered
`<dialog>` for this control; this is untouched ground, not a rejected
alternative. `<dialog>`'s modal focus-trap behavior is broadly shipped
(Chrome 37+, Safari 15.4+, Firefox 98+). Swapping the hand-rolled overlay
for native `<dialog>` would touch the `accTitle`/named-button logic and the
idempotent-observer contract `mermaid.js` already depends on, so this is a
design question for the maintainer, not a drop-in patch.

**[New ground]** WCAG 2.2 added 2.4.11 Focus Not Obscured (Minimum) and
2.5.8 Target Size (Minimum), both AA, neither mentioned in NOTES.md. WCAG
2.2 became a Recommendation on 2023-10-05. Checked against current CSS:
`.mermaid-zoom` carries `min-height: 40px`, clearing the 24 by 24 pixel
2.5.8 floor already. 2.4.11 raises a genuinely open question:
`thead th { position: sticky; top: 0 }` pins a header over
`.table-scroll`'s own scrollport, and nothing keys `scroll-padding-top` to
that sticky offset, so a keyboard user tabbing a link inside a tall wrapped
table could land a focus ring fully under the pinned header. This was not
confirmed in a real browser during this run, so it is reported as an open
question rather than a patch candidate.

**[Reinforces]** The physical-then-logical fallback pattern for sidenotes
(`float: inline-end` with a physical value first) is still correct.
Nothing in current Baseline data changes the stated concern about an older
engine dropping the unparsed line and keeping LTR.

**[New ground, informational]** WCAG 3 ("Silver") remains a Working Draft.
The March 2026 draft still projects Candidate Recommendation no earlier
than Q4 2027 and possible Recommendation as late as 2029. WCAG 2.2 AA
stays the only applicable benchmark; nothing here needs to anticipate the
Bronze/Silver/Gold model yet.

### Patch-worthy

Nothing to propose. The sticky-header `scroll-padding-top` question needs a
real browser check against a tall wrapped table before it becomes a
snippet, and the `<dialog>` swap is architectural, flagged above as needing
maintainer sign-off before it touches `mermaid.js`.

## Interaction and motion

NOTES.md sections read: Interaction states, Form follows role.

### Searched
- prefers-reduced-motion Baseline status caniuse 2026
- :focus-visible Baseline status MDN 2026
- View Transitions API Baseline 2025 2026 cross-document support
- CSS transition scale property Baseline individual transform properties 2026
- web.dev prefers-reduced-motion best practice transition-duration 0.01ms vs disable animation

### Findings

**[Reinforces]** The global reduced-motion collapse
(`tufte-dracula.css:410-411`, `transition-duration`/`animation-duration` to
0.01ms rather than 0) matches the still-dominant pattern: 0ms can be
treated as falsy in some engines and can drop `transitionend`/
`animationend` events that script logic relies on. `prefers-reduced-motion`
itself is Baseline Widely available since 2020. Some accessibility writers
argue for a more selective, opt-in approach that keeps small fades and
disables only large slides or parallax; this repo's transitions are
already small (color, background-color, opacity, scale, all under 200ms,
no slide or parallax motion), so the blanket collapse loses no nuance
here. No change needed.

**[Reinforces]** NOTES.md's decision to use the `scale` property rather
than `transform: scale()` for press feedback, so the transition lives on
the resting rule, is still correct. Individual transform properties
(`translate`, `rotate`, `scale`) are Baseline Widely available since
2022-08-05, and current guidance still recommends them over `transform:
scale()` specifically because they compose independently and can be
overridden without re-specifying the whole transform chain, matching
NOTES.md's own stated reasoning.

**[Reinforces]** `[tabindex="0"]:focus-visible` as the sole custom-focus
selector matches current practice: `:focus-visible` is Baseline Widely
available, and guidance still holds that authors should not remove default
focus indication and should prefer `:focus-visible` over `:focus` for
mouse-triggered elements.

**[New ground]** Neither NOTES.md nor either CSS/JS file mentions the View
Transitions API (confirmed via search, no hits). Same-document view
transitions reached Baseline Newly available on 2025-10-14 (Firefox 144
shipped `document.startViewTransition`). Cross-document transitions remain
Chrome/Edge- and Safari-18.2+-only as of mid-2026; Firefox has not shipped
that half, so the full API is not yet Baseline. The mermaid overlay
open/close is the one place this could theoretically apply, but the API is
triggered by JS this repo does not currently call anywhere, and "Newly
available" (not "Widely available") means non-supporting browsers need a
plain fallback, which the overlay already has via its existing transition.
A genuine gap in NOTES.md's interaction-state decisions, but adopting a new
browser API is a scope decision, not a mechanical fix.

**[Reinforces]** The `ease-out` mandate for every transition is a
design-taste rule, not a spec-tracked feature, so no Baseline claim
applies. It matches general interaction-design guidance for press and
hover feedback found across current 2025 to 2026 sources, and nothing
contradicts it.

### Patch-worthy

Nothing to propose. The View Transitions API question needs a maintainer
decision before it touches NOTES.md or the stylesheet.

## Pinned dependencies

NOTES.md sections read: Fonts, Mermaid.

### Searched
- @fontsource-variable/source-serif-4 npm latest version
- mermaid npm latest version 2026
- npm view @fontsource-variable/source-serif-4 version (registry check)
- npm view mermaid version (registry check)

### Findings

**@fontsource-variable/source-serif-4**: pinned at 5.3.0
(`tufte-dracula.css:7,12`). The npm registry confirms 5.3.0 is also the
latest published version, released 17 days before this audit. Nothing to
upgrade.

**mermaid**: pinned at 11.16.1 (`mermaid.js:2`). The npm registry confirms
11.16.1 is also the latest published version, released 11 days before this
audit. No interim release exists to check for a rendering or security fix.
A future bump belongs behind `nu scripts/maintain.nu mermaid <version>` per
`CLAUDE.md`, since that command also touches the generated
`mermaid-palette.json` and fixtures; not applicable this run since no
newer version exists.

Both pins pass this audit as current. The font pin is chosen for
weight-axis and tabular-figure behavior unrelated to version currency, and
the mermaid pin is gated by the khroma hex-only constraint, which does not
change between patch releases.

### Patch-worthy

Nothing to propose.

## Verification

No patch file was written: every topic returned "nothing to propose."
Step 5 (apply in a throwaway worktree, regenerate, run
`nu scripts/maintain.nu check`) is skipped per the skill's own rule, since
it applies only when Step 4 wrote a patch.

**Verdict: no patch: nothing to propose.**

## Summary

- Findings total: 20 (across 6 topics)
- New ground: 9 (light-dark(), P3 gamut ceiling, text-wrap: pretty
  undocumented, focus-visible no-fallback, native `<dialog>` for the zoom
  overlay, WCAG 2.2 2.4.11/2.5.8, WCAG 3 status informational, View
  Transitions API, intrinsic sizing keywords)
- Reinforces a settled decision: 11
- Repeats: 0 (first run, nothing to repeat)
- Challenges a settled decision: 0
- Patch: none written
