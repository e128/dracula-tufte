# Design audit: 2026-08-23

Research window: since 2026-08-16, the date of the previous audit
(`review/2026-08-16-design-audit.md`). That audit read the tree at v1.30.0. This run reads the
tree at v1.36.0, commit `5e857e0`. `review/declined.md` does not exist yet, so no finding is
filtered by a prior decline.

Out of scope for this skill, per the topic map: Editor themes, Filter, Unclaimed elements,
Markdown coverage, Raw HTML and other generators, Fixtures are coverage, Repo layout, Odds and
ends. Their absence here is a scope decision, not an oversight.

Six commits landed in the window: v1.31.0 (ELK layout support, a real click-to-zoom fix, a
verdict-badge markup contract), v1.32.0 (`.recent-groups` track width), v1.33.0 (six borrowed
presentational components: `.kicker`, `.tag-dot`, `.live-dot`, `.icon-list`/`.icon-chip`,
`.step-chain`/`.step-hop`/`.step-node`/`.step-arrow`, `blockquote.pull`), v1.34.0 (film-grain
texture, raised `kbd` edge), v1.34.1 (clipped nav-list link titles, `h3` balance, muted sidenote
marker), v1.35.0 (iTerm2, opencode themes), v1.36.0 (VS Code, tmux themes, plus two accessibility
fixes: `.step-node` joins the forced-colors border list, and `.footnote-backref` gets a numbered
`aria-label` convention), and the latest, `5e857e0` (orphaned source citation in the timeline
fixture, a `lang="la"` tag on a Latin blockquote clause). Most of this run's findings are those
fixes confirmed against NOTES.md, not new proposals.

## Color and contrast

NOTES.md sections read: Color and the contrast budget, Appearance modes, Print, Mermaid.

### Searched

- CSS Color 5 gamut mapping oklch Baseline status 2026
- APCA WCAG 3 contrast 2026 status update
- forced-colors CSS spec update 2026 AccentColor

### Findings

**[Reinforces]** `oklch()` stays Baseline Widely available (Chrome 111+, Safari 15.4+, Firefox
113+, roughly 93 to 95% global coverage as of 2026). No change to the sheet's exclusive `:root`
use of `oklch()`, with hex kept only as provenance and Mermaid projections. Sources: 66colorful.com,
"OKLCH Color in CSS: The Complete Guide for 2026" (2026); devtoolnow.com color-formats guide (2026).

**[Reinforces]** APCA versus WCAG 2, restated with a second source beyond the one the last audit
already cited. accessibility.chat, "The APCA Mirage" (2026), and yatil.net, "WCAG 3 is not ready
yet," both confirm APCA left the WCAG 3 drafts in 2023, the contrast algorithm stays "yet to be
determined," and a WCAG 3 Recommendation now projects to 2028 through 2030. The repo's decision to
log the APCA divergence and keep WCAG 2 as the enforced bar stands, further corroborated.

**[Reinforces]** Forced colors: the only spec movement found is a CSS Color 4 pull request linking
`AccentColor` to author `accent-color` outside forced-colors mode, plus
`forced-color-adjust: preserve-parent-color` moving through Candidate Recommendation Draft. Neither
touches this sheet, which uses only `border: 1px solid currentColor` overrides and no system-color
keyword. No action.

**[Resolved since last pass]** `.step-node` joined the forced-colors border list in v1.36.0
(`tufte-dracula.css`: `code, kbd, .verdict, .badge, .kicker, .icon-chip, .step-node { border: 1px
solid currentColor; }`). This closes the gap the two prior components (`.kicker`, `.icon-chip`,
added v1.33.0) already had documented in NOTES.md; `.step-node` catches up to the same rule.

**[Reinforces]** Display P3 gamut mapping: the 2026 State of CSS survey lists gamut mapping as a
live industry pain point (out-of-gamut results from `color-mix()` or relative-color math with no
mapping). This sheet does not hit that, because `oklch_to_hex`'s clip-to-sRGB-ceiling approach
(documented under "P3 gamut for six vivid accents") already holds `L`/`h` and reduces `C`, which is
the CSS Color 4 gamut-mapping algorithm's own approach, applied by hand for the hex-only consumers.

No commit in this window touches `:root` tokens, an appearance-mode block, the print block, or a
Mermaid palette hex beyond the `.step-node` fix above.

### Patch-worthy

Nothing to propose.

## Typography

NOTES.md sections read: Fonts, Type scale, Italics, Paragraphs and section rhythm.

### Searched

- hyphenate-limit-chars CSS Baseline support 2026
- text-wrap pretty Firefox support Baseline 2026
- variable font woff2 font-size-adjust letter-spacing best practice 2026

### Findings

**[Repeat, unchanged since 2026-08-16]** `hyphenate-limit-chars` stays Limited availability, not
Baseline. The repo correctly avoids it. Confirmed against MDN and caniuse, same status as last
audit.

**[Repeat, unchanged since 2026-08-16]** `text-wrap: pretty` still has no Firefox shipped support
as of 2026 (a Mozilla Connect request stays open). The repo's stated fallback, that the property
costs nothing where a browser does not read it, still holds. `text-wrap: balance` remains Baseline
since 2024, unchanged.

**[New ground]** NOTES.md's Type scale section documented no scope or rationale for
`text-wrap: balance`, even though it now sits on three selectors: `h1` (`tufte-dracula.css:69`),
`h2` (`:74`), and `h3` (`:75`, added in v1.34.1, commit `a09ee66`, "h3 balance"). This was a
documentation gap, the same shape `text-wrap: pretty` had before v1.29.0 closed it. **Patched this
run:** see below.

Two v1.34.1 fixes were checked against NOTES.md and found already reflected: the clipped
nav-list link title fix (`text-overflow: ellipsis` plus a `title` attribute, documented at
NOTES.md's Lists section) and the muted sidenote marker fix (`color: var(--muted)` on the marker
pseudo-elements, consistent with every other de-emphasized annotation in the sheet, not itself
surprising enough to need its own NOTES.md line).

### Patch-worthy

Added to NOTES.md, Type scale section, a new paragraph stating `text-wrap: balance`'s scope
(`h1` through `h3`, not `h4` through `h6`) and the short-block rationale already established for
`text-wrap: pretty`. In the patch below.

## Layout and spacing

NOTES.md sections read: Width and measure, Tables, Lists, Connections-map layout, Cascade layer.

### Searched

- CSS subgrid Baseline support 2026
- Mermaid ELK layout engine release notes 2026 cluster theming fix
- mermaid-js layout-elk npm version history changelog cluster themeVariables
- CSS auto-fit minmax overflow fix 2026 grid track sizing best practice
- CSS Baseline newly available features August 2026 web.dev digest

### Findings

**[New ground, not applicable]** `subgrid` reached Baseline Widely available on 2026-03-15. Does
not apply to `dl.timeline`'s stated blocker: separate `<dl>` lists have no common grid ancestor,
which is a DOM-structure fact, not a support gap. No action.

**[Reinforces]** `.recent-groups`'s `repeat(auto-fit, minmax(min(36rem, 100%), 1fr))` still matches
the current documented best fix for the auto-fit and minmax overflow trap. Confirms the prior
audit's "Resolved since last pass" entry; nothing new.

**[Reinforces]** The sheet's three `:has()` selectors are unchanged and still sit on the
most-used modern CSS selector per the 2025 State of CSS survey the prior audit cited.

**[Reinforces]** `.table-scroll`'s `scroll-padding-top: 3em` against the sticky `thead th` is
confirmed present and unchanged, matching the prior audit's WCAG 2.4.11 fix.

**[Repeat, unchanged since 2026-08-16]** No upstream Mermaid fix exists yet for ELK's hardcoded
cluster fill, stroke and label color (`#ffffde`, `#aaaa33`, `#333`, ignoring `themeVariables`).
Checked the `@mermaid-js/layout-elk` changelog through its current pinned 0.2.3: only an unrelated
crash fix and two unrelated config options landed. NOTES.md's CSS override
(`pre.mermaid .cluster rect`, `.cluster-label`, both `!important`) stays necessary.

No layout implication found from v1.31.0 through v1.36.0 beyond the already-covered items above;
the new borrowed components from v1.33.0/v1.34.0 live in Borrowed components, outside this topic's
NOTES.md map.

### Patch-worthy

Nothing to propose.

## Accessibility

NOTES.md sections read: Keyboard and assistive technology, Direction, zoom and growth, Links.

### Searched

- WCAG 2.2 Recommendation current version 2026 W3C
- WCAG 3.0 Silver Working Draft status 2026 Candidate Recommendation
- WCAG 2.2 errata update 2026 success criteria changes

### Findings

WCAG version confirmed this run: 2.2 (Recommendation, 2023-10-05, editorial update 2024-12-12;
ISO/IEC 40500:2025). No substantive criteria changed via errata, only wording and capitalization,
last dated 2025-10-28. WCAG 3.0 stays a Working Draft (latest March 2026); Candidate Recommendation
is not expected before Q4 2027, full Recommendation 2028 or later. WCAG 2.2 AA stays the only
applicable benchmark, same conclusion as the prior audit with a later projection.

**[Resolved since last pass]** `.step-node`'s forced-colors border (v1.36.0), covered under Color
and contrast above; also closes what would otherwise be a fresh 1.4.11 gap in this topic's sweep.

**[Resolved since last pass]** `.footnote-backref` accessible name. v1.36.0 added `CONTRACT.md`
guidance for a numbered `aria-label` (for example, "Back to reference 1"), and the fixture models
it. A converter-emitted glyph with no name of its own is now a documented consumer obligation, the
same pattern `accTitle`/`accDescr` already set.

**[New ground, informational]** 3.1.2 Language of Parts was previously out of scope, flagged only
if a fixture mixed languages without marking the shift. Commit `5e857e0` does the marking: a
`lang="la"` span around a Latin clause inside an English blockquote. Recorded as evidence of active
practice, not a gap.

**[New ground]** v1.31.0's click-to-zoom fix replaced a `data-*` attribute guard, which a cloned SVG
carries over without its listener, with a `WeakSet` keyed on the element itself. This underlies the
2.1.1 and 2.5.3 passes below; recorded so a future run does not treat it as newly discovered.

**[Repeat, unchanged since 2026-08-16]** `:focus-visible` still carries no `:focus` fallback
(`tufte-dracula.css:97-98`). Still safe, Baseline Widely available since March 2022.

### WCAG conformance sweep

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | Mermaid `accTitle`/`accDescr` project to `title`/`desc`; `.icon-chip` is `aria-hidden="true"` beside a visible label; outbound arrow and tree-turn glyph use empty alt via `content:"…" / ""`. |
| 1.3.1 Info and Relationships | A | Pass | Semantic `table`, heading hierarchy, `dl`/`dl.timeline`, `role="list"` on reset `<ul>`s. |
| 1.3.2 Meaningful Sequence | A | Pass | DOM order is visual order; `body.conn-map` reorder documented, no focusable content out of order. |
| 1.4.1 Use of Color | A | Pass | `.verdict`/`.tag-dot` pair color with text or shape; `.tag-dot` sits beside a text label per NOTES.md's own rule. |
| 2.1.1 Keyboard | A | Pass | Zoom button, `.table-scroll`/`pre`/`math` tabindex hatch; click-to-zoom reliably reachable since the v1.31.0 fix. |
| 2.1.2 No Keyboard Trap | A | Pass | Native `<dialog>` via `showModal()`; `cancel` and backdrop click both exit. |
| 2.4.2 Page Titled | A | Pass | Distinct `<title>` per fixture. |
| 2.4.3 Focus Order | A | Pass | Tab order matches visual order in every layout mode. |
| 2.4.4 Link Purpose | A | Pass | No bare "click here"; nav-list links carry a `title` attribute for clipped text (v1.34.1). |
| 2.5.3 Label in Name | A | Pass | Zoom button's visible text is a prefix of its `aria-label`. |
| 3.1.1 Language of Page | A | Pass | `lang="en"` on every fixture. |
| 3.2.1 On Focus | A | Pass | No context change on focus. |
| 3.2.2 On Input | A | Pass | Filter box never navigates or submits on input. |
| 4.1.2 Name, Role, Value | A | Pass | `.table-scroll` region, `<dialog>`, and zoom button all carry name plus role. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference | Covered by Color and contrast's palette gate. |
| 1.4.4 Resize Text | AA | Pass | Body clamp ratio 1.25; the stated 400% sideways-scroll exception still holds, unchanged. |
| 1.4.10 Reflow | AA | Pass | No two-dimensional scroll at 320px outside the opt-in hatches. |
| 1.4.11 Non-text Contrast | AA | Pass | Forced-colors border list now covers `.kicker`, `.icon-chip`, `.step-node`; focus ring 2px/3px. |
| 1.4.12 Text Spacing | AA | Pass | Token-driven grid or flex layout survives spacing overrides. |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content anywhere, including the six v1.33.0 components. |
| 2.4.6 Headings and Labels | AA | Pass | Headings and the filter label describe their section or purpose. |
| 2.4.7 Focus Visible | AA | Pass | Every interactive element has `:focus-visible`; no `:focus` fallback, still safe per the repeat above. |
| 2.4.11 Focus Not Obscured | AA | Pass | `scroll-padding-top: 3em` on `.table-scroll`. |
| 2.5.8 Target Size (Minimum) | AA | Pass, N/A for new components | Existing targets unchanged (`.mermaid-zoom` 40px, `.nav-list li a` 40 or 44px). The v1.33.0 components (`.kicker`, `.icon-chip`, `.tag-dot`, `.live-dot`, `.step-node`) carry no click handler or `href`, so the criterion does not apply to them. |
| 4.1.3 Status Messages | AA | Pass | `filter.js`'s result count via a `role="status"` element. |

### Patch-worthy

Nothing to propose.

## Interaction and motion

NOTES.md sections read: Interaction states, Form follows role.

### Searched

- View Transitions API cross-document Baseline support 2026
- @starting-style transition-behavior allow-discrete Baseline status 2026

### Findings

**[Reinforces]** View Transitions cross-document support stays outside Baseline. Firefox has not
shipped it as of 2026; Chrome has, since Chrome 126. Confirms the decision to pass over View
Transitions for the mermaid overlay: nothing to revisit.

**[Reinforces, new dating detail]** `@starting-style` and `transition-behavior: allow-discrete`
reached Baseline Newly available in August 2024 (Firefox 129 was the last engine). NOTES.md does
not state this date, but the fact does not change the decision: the overlay's non-fading exit is
already documented as a deliberate trade, "closing this dialog is a dismissal a user asked for, not
a state a user is meant to watch happen," not a support gap the browser has since closed. No
action.

**[Reinforces]** `.live-dot`'s `@keyframes live-pulse` is covered by the sheet's blanket
`prefers-reduced-motion: reduce` rule, which zeroes `animation-duration` and
`animation-iteration-count` on every element. Matches the Borrowed components section's claim that
the pulse freezes there for free.

**[Reinforces]** Current `:active`, `:hover` and transition rules still follow the documented
conventions: transition on the resting rule, `scale` rather than `transform`, an untransitioned
instant hover ring. No drift found from v1.31.0 through v1.36.0; the new borrowed components
introduce no new hover or press motion.

### Patch-worthy

Nothing to propose.

## Pinned dependencies

NOTES.md sections read: Fonts, Mermaid.

### Searched

- `npm view @fontsource-variable/source-serif-4 version time.modified`
- `npm view mermaid version time.modified`
- `npm view @mermaid-js/layout-elk version time.modified`
- `npm view mermaid time --json`, `npm view @mermaid-js/layout-elk time --json`, `npm view @fontsource-variable/source-serif-4 time --json`
- `gh api repos/mermaid-js/mermaid/releases`

### Findings

**@fontsource-variable/source-serif-4**: pinned at 5.3.0 (`tufte-dracula.css:7,12`). Registry
latest: 5.3.0, published 2026-07-19. Pin is current.

**mermaid**: pinned at 11.17.0 (`mermaid.js:2`), already bumped from 11.16.1 since the last audit.
Registry latest: 11.17.0, published 2026-08-19. Pin is current. The 11.16.1 to 11.17.0 delta,
already shipped, added new shapes and diagram features, an ELK config option, and patch fixes (a
dagre warning-log flood, a `RangeError` crash on certain edges, block-diagram label overlap,
tree-view icon sanitization).

**@mermaid-js/layout-elk**: pinned at 0.2.3 (`mermaid.js:5`). Registry latest: 0.2.3, published
2026-08-19. Pin is current.

All three pins are already at their latest published registry version, so no bump applies
regardless of the fix search. A future Mermaid bump belongs to
`nu scripts/maintain.nu mermaid <version>`, named here per this skill's rule, never run. A future
layout-elk bump has no dedicated `maintain.nu` verb: `nu scripts/maintain.nu mermaid` rewrites only
the `mermaid@[\d.]+` pattern in `mermaid.js`, not the layout-elk CDN URL, so that pin would need a
plain manual edit followed by `nu scripts/build-sample.nu` to regenerate fixtures. That gap in the
maintenance tooling, not a design or CSS finding, belongs in `backlog.md` if the maintainer wants
it tracked; this report only names it.

### Patch-worthy

Nothing to propose. No dependency bump belongs in this skill's patch regardless of findings.

## Challenges a settled decision

None this run.

## Verification

```
D=2026-08-23
git worktree add --detach /tmp/design-audit-verify HEAD
git -C /tmp/design-audit-verify apply "$PWD/review/$D-design-audit.patch"
nu /tmp/design-audit-verify/scripts/build-sample.nu
nu /tmp/design-audit-verify/scripts/maintain.nu check
git worktree remove --force /tmp/design-audit-verify
```

`build-sample.nu` regenerated all fixtures and `tokens.css` inside the worktree, then
`maintain.nu check` printed `Palette OK`, `Mode renders OK`, `Generated files fresh`, `Themes
fresh`, `No em-dash or en-dash`, and `Contract OK`. The added-lines scan
(`rg -n '^\+' review/2026-08-23-design-audit.patch | rg -e '/\*' -e '\*/' -e '//'`) found nothing,
and the dash scan over both artifacts found nothing.

**Verdict: Verified: patch applies to HEAD and Contract OK after regeneration.**

## Summary

- Findings total: 19 body findings across 6 topics, plus the 25-row WCAG sweep
- Reinforces a settled decision: 10
- Resolved since last pass: 3 (`.step-node` forced-colors border, `.footnote-backref` accessible
  name, both v1.36.0)
- Repeat, unchanged since 2026-08-16: 3 (`hyphenate-limit-chars` limited availability,
  `text-wrap: pretty` no Firefox support, ELK cluster theming has no upstream fix)
- New ground: 3 (`text-wrap: balance` documentation gap, now patched; 3.1.2 language marking now
  practiced; the v1.31.0 click-to-zoom `WeakSet` fix as underlying context)
- Challenges a settled decision: 0
- Patch: one hunk, NOTES.md only, documenting `text-wrap: balance`'s existing scope
