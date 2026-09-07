# Design audit: 2026-09-07

Research window: since 2026-08-23, the date of the previous audit
(`review/2026-08-23-design-audit.md`). That audit read the tree at v1.36.0, commit `5e857e0`. This
run reads the tree at v1.44.0, commit `7e67221`. `review/declined.md` still does not exist, so no
finding is filtered by a prior decline.

Out of scope for this skill, per the topic map: Editor themes, Filter, Unclaimed elements,
Markdown coverage, Raw HTML and other generators, Fixtures are coverage, Repo layout, Odds and
ends. Their absence here is a scope decision, not an oversight.

Fourteen commits landed in the window: v1.37.x (JetBrains Mono as a webfont and one mono stack,
the sidenote `newthought` reset, the conn-map sidebar overflow fix, mermaid pins 11.17.1 then
11.17.2), v1.38.x (citation and `newthought` contract rules), v1.39.0 (touch hover guards, heading
tier, nav wrap, two palette gates), v1.40.x (pie contrast, conditional diagram region, printed
diagram palette), v1.41.0 (print palette freeze, both pie strokes themed, region named for itself),
v1.41.1 (forced-colors code-block fix plus the mode's first structural coverage), v1.42.0
(`table.bar-chart`, the print pin its legend needed), v1.43.0 (the CSS pie removed, a Mermaid
`pie` fence takes the slot), and v1.44.0 (`.step-hop` wrap fix, `.tag-dot` and `.live-dot` under
forced colors). Every one of these is already documented in NOTES.md, and this run read the
sections that document them. The findings below are confirmations, not new proposals.

## Extra subject: a rendered consumer page

At the maintainer's request this run also audited one rendered consumer page: a saved MHTML copy
of `https://e128.info/research/proof-tests/tier-2-survive-plausible/nocebo-proof-test`
("Research · Nocebo Effects Cause Real Symptoms: Proof-Test", generated 2026-09-07 by the
`lode` pipeline, `output-template-version v1.4.0`). This section is outside the six-topic map and
the patch rules; the page's fixes belong to the generator that emitted it, not to this repo.

What the page carries:

- The inlined stylesheet is a **Blink-serialized copy of a current-era sheet**, not a stale pin.
  It has the v1.42 features (`table.bar-chart`, the `.tag-dot` print pin, the `pre.mermaid` print
  palette freeze), the v1.44 forced-colors entries (`.step-hop` era: `code, kbd, .verdict, .badge,
  .kicker, .icon-chip, .step-node { border: 1px solid currentColor }`, and
  `.tag-dot::before, .live-dot { background: CanvasText }`), and a normalized rule-for-rule
  comparison against `tufte-dracula.css` at HEAD finds no template drift in it. The differences
  are Blink's own serialization on save (`0px` for `0`, longhand expansion of `flex` and `font`
  shorthands, `currentColor` dropped from the border shorthand as the initial value, the physical
  `float: right` fallback lost where `inline-end` won, and `-webkit-print-color-adjust` dropped).
  Nobody should read that MHTML copy as evidence about the payload; it is a computed snapshot.
- The page's markup follows the repo's own unwrapped-table convention: both tables take
  `tabindex="0"` plus a `<caption>` and no `role="region"`, exactly as NOTES.md, Tables, requires.
  The sidenote margin-toggle checkboxes are hidden with the two `display: none` rules NOTES.md,
  Keyboard and assistive technology, declares load-bearing. `lang="en"`, a distinct `<title>`,
  and marked footnote refs are all present.

Findings on the page itself (all generator-owned, none actionable here):

1. **`<strong>` inside `<a>` on every citation.** NOTES.md, Lists, states: "A `strong` inside an
   `<a>` repaints the link. `strong { color: var(--orange) }` wins on the inner element... Check
   this in any consumer that wraps a link title in `strong`." The page does this in all 13 numbered
   source entries and in roughly a dozen sidenote citations, so every citation link renders orange
   body-accent instead of link cyan. This is the exact case that paragraph asks consumers to be
   checked for, found in the wild. The fix belongs to the `lode` generator: take the `strong` out
   of the anchor.
2. **Markdown lists left unconverted inside `<p>`.** The Synthesis "What does not survive as
   stated" paragraph carries three literal " - " items inline, and the Strongest Defense paragraph
   carries "1. 2. 3." inline. List structure is flattened into run-on paragraph text, a WCAG 1.3.1
   information loss as well as a rendering defect. Same owner: the generator's markdown pipeline.
3. **A duplicated paragraph.** The Synthesis details block states the independence note twice,
   once bold and once italic, verbatim in substance. Content bug, cosmetic.
4. **The overlay `<dialog>` is emitted with no diagram and no script.** The page carries
   `<dialog class="mermaid-overlay" id="mermaid-zoom">` but no Mermaid fence and no inlined
   `mermaid.js`. Harmless (the dialog stays empty and closed), but a generator that always emits
   the dialog could instead emit it only when a fence is present.
5. **Generator-owned additions reference a token the sheet does not define.** `nav.toc .toc-label`
   and `details.deep > summary` set `font-family: var(--sans)`, and `:root` declares no `--sans`.
   They fall back to the inherited serif, which is how the page renders now; the generator should
   either define the token or drop the declaration. The generator's own `nav.toc` and
   `details.deep` components sit outside this sheet and are noted only for completeness.

## Color and contrast

NOTES.md sections read: Color and the contrast budget, Appearance modes, Print, Mermaid, CSS
charts.

### Searched

- forced-colors CSS update APCAN WCAG contrast 2026 AccentColor spec change
- (Topic 6 searches, npm registry reads, covered the palette-adjacent Mermaid delta)

### Findings

**[Repeat, unchanged since 2026-08-23]** Forced colors: the only spec movement is still the CSS
Color 4 `AccentColor` change, now formalized in the Candidate Recommendation Draft dated
2026-04-13 (`AccentColor` takes its value from `accent-color` except in forced colors mode, merged
via csswg-drafts PR #12733 in September 2025). This sheet uses only `border: 1px solid
currentColor` overrides and the two system-color dots (`background: CanvasText`), both of which
the change leaves alone. No action. Sources: W3C CSS Color 4 CRD, 2026-04-13;
github.com/w3c/csswg-drafts PR 12733.

**[Reinforces]** APCA stays on the WCAG 3 track and out of the CSS specs. The SAPC-APCA repository
confirms APCA is intended for WCAG 3, and CSS Color 6 (Editor's Draft, 2026-01-11) ships
`contrast-color()` supporting only `wcag2()`, explicitly noting that algorithm's known problems on
dark backgrounds and that future revisions may add more algorithms. The repo's decision to log the
APCA divergence and keep WCAG 2 as the enforced bar stands. Sources: github.com/Myndex/SAPC-APCA;
W3C CSS Color 6 ED, 2026-01-11.

**[New ground, not applicable]** `contrast-color()` itself is now a shipped CSS function and
reached Baseline Newly available in April 2026 (web.dev Baseline 2026). The sheet has no use for
it: every pair is gated statically by `palette-check.py`, and a runtime-resolving color function
would put a pair outside every gate this repo owns. Recorded so a future reader does not mistake
absence for an oversight.

No commit in the window moved a `:root` token, a mode block, a print override, or a Mermaid hex
outside what NOTES.md already documents (the v1.40.0 through v1.41.0 ramp, pie and print work is
all recorded in the sections this run read).

### Patch-worthy

Nothing to propose.

## Typography

NOTES.md sections read: Fonts, Type scale, Italics, Paragraphs and section rhythm.

### Searched

- text-wrap pretty Firefox shipped 2026 hyphens support
- hyphenate-limit-chars browser support caniuse 2026 baseline

### Findings

**[Repeat, unchanged since 2026-08-16]** `text-wrap: pretty` still has no Firefox support. The
web-platform-dx tracking issue (`web-features` 3458, last updated 2026-02) still lists `pretty` as
a limited-availability subfeature of the Baseline `text-wrap` shorthand. The repo's stated
fallback still holds: the property costs nothing where a browser does not read it.

**[Repeat, unchanged since 2026-08-16, one new dating detail]** `hyphenate-limit-chars` stays
Limited availability: Chrome 109+, Firefox 137+ (shipped 2025-04), and Safari is the sole blocker,
blocking Baseline since 2025-04 with no support through Safari 26.x including Technology Preview.
The repo correctly avoids it; the new detail is that the blocker set has narrowed to Safari alone,
which does not change the decision.

**[Reinforces]** `hyphens` reached Baseline Widely available on 2026-03-18 (web-features
explorer; Chrome 88+, Firefox 43+, Safari 17+). The sheet's narrow scoping of `hyphens: auto` to
the sidenote and `.col-2` measures, with `lang="en"` required, now stands on a Widely available
primitive. Sources: web-platform-dx web-features explorer, Hyphenation; MDN `hyphens`.

The v1.38.1 sidenote `newthought` reset and the JetBrains Mono unification (v1.38.0) are both
already documented in the sections this run read; no drift found.

### Patch-worthy

Nothing to propose.

## Layout and spacing

NOTES.md sections read: Width and measure, Tables, Lists, Connections-map layout, Cascade layer.

### Searched

- "Baseline" digest July 2026 OR August 2026 web.dev newly available
- Baseline newly available CSS features September 2026 web-platform-dx

### Findings

**[Reinforces]** `:has()` is now listed as Widely available in the June 2026 Baseline digest
(published 2026-07-17). The sheet's `:has()` selectors (`table:has(caption)`, the scorecard
container-query scoping, `nav:has(> a)`, `li:has(input[type="checkbox"]:first-child)`) sit on a
fully available primitive. Source: web.dev June 2026 Baseline digest.

**[Repeat, unchanged since 2026-08-23]** `subgrid` Widely available in March 2026, and still
inapplicable to `dl.timeline`'s separate-`<dl>` structure. Same conclusion as the last audit.

**[New ground, not applicable]** Container **style** queries reached Baseline Newly available in
May 2026 (web.dev May 2026 digest). This is a different mechanism from the inline-size container
query the sheet already uses on `section` for the scorecard, and it does not touch the
`dl.timeline` rejection, which is about layout containment cost, not about what queries can
inspect. No action.

**[Repeat, unchanged since 2026-08-16]** No upstream fix for ELK's hardcoded cluster colors; the
pinned `@mermaid-js/layout-elk` is unchanged at 0.2.3 (published 2026-08-19), so nothing new could
have landed. NOTES.md's CSS override stays necessary.

The v1.39.0 touch-hover guards, nav wrap, and the conn-map sidebar overflow fix (v1.37.1) are
already documented. No new layout pattern arrived in the window.

### Patch-worthy

Nothing to propose.

## Accessibility

NOTES.md sections read: Keyboard and assistive technology, Direction, zoom and growth, Links.

### Searched

- WCAG 2.2 W3C Recommendation current version 2026 update
- View Transitions API same-document Baseline 2026 Firefox Safari status (recorded under
  Interaction and motion, where it also answers this topic's ARIA-pattern question for the
  overlay)

### Findings

WCAG version confirmed this run, unchanged from the last audit: **WCAG 2.2, W3C Recommendation,
2023-10-05, republished 2024-12-12** with editorial errata through 2025-10-28; an Editor's Draft
dated 2026-07-29 shows ongoing errata work and no new Recommendation. WCAG 3.0 remains a Working
Draft. WCAG 2.2 AA stays the applicable benchmark. Sources: w3.org/TR/WCAG22/ (2024-12-12);
w3.org/WAI/WCAG22/errata/.

The window's accessibility work (the conditional diagram region naming, the forced-colors
structural gate, the v1.44.0 step-chain naming requirement) is all already documented in
NOTES.md, Keyboard and assistive technology and Borrowed components. No new gap was found.

### WCAG conformance sweep

Checked against the tree at v1.44.0, commit `7e67221`. Spot-verified this run: the
`[tabindex="0"]:focus-visible` rule (`tufte-dracula.css`, search `a:focus-visible, summary`), the
`prefers-reduced-motion` blanket, `role="list"` on reset lists in the fixtures, `role="status"`
wiring in `filter.js`, and `tabindex="0"` on unwrapped fixture tables.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | `accTitle`/`accDescr` project to `title`/`desc`; decorative pseudo-elements carry `content: "…" / ""` behind `@supports` (outbound arrow, tree turn, `blockquote.pull`, overlay close mark). |
| 1.3.1 Info and Relationships | A | Pass | Semantic tables, `role="list"` on reset `<ul>`s, `table.tree` kept a plain table by documented decision. |
| 1.3.2 Meaningful Sequence | A | Pass | DOM order is visual order; `body.conn-map` reorder documented, markup order is layout order. |
| 1.4.1 Use of Color | A | Pass | `.verdict` and `.badge` carry text; `.tag-dot` sits beside a label; forced colors keeps state text. |
| 2.1.1 Keyboard | A | Pass | Zoom is a real `<button>`; `.table-scroll`, `pre`, `math[display="block"]` tab stops; conditional region logic verified by the payload probe. |
| 2.1.2 No Keyboard Trap | A | Pass | Native `<dialog>` via `showModal()`; `cancel` and backdrop click both run `hide()`. |
| 2.4.2 Page Titled | A | Pass | Distinct `<title>` per fixture. |
| 2.4.3 Focus Order | A | Pass | Tab order follows visual order in both layouts. |
| 2.4.4 Link Purpose | A | Pass | No bare "click here"; nav-list links carry `title` for clipped text. |
| 2.5.3 Label in Name | A | Pass | Zoom button's visible text is a prefix of its title-derived `aria-label`. |
| 3.1.1 Language of Page | A | Pass | `lang="en"` on every fixture; `lang="la"` marking practiced since commit `5e857e0`. |
| 3.2.1 On Focus | A | Pass | No context change on focus anywhere in the sheet. |
| 3.2.2 On Input | A | Pass | Filter box never navigates or submits on input. |
| 4.1.2 Name, Role, Value | A | Pass | `.table-scroll` region, `<dialog>`, zoom button all carry name plus role. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference | Covered by Color and contrast's palette gate (check 5 of `palette-check.py`). |
| 1.4.4 Resize Text | AA | Pass | Body clamp; the stated 400% sideways-scroll exception still holds as written (NOTES.md, Direction, zoom and growth). |
| 1.4.10 Reflow | AA | Pass | No two-dimensional scroll at 320px outside the opt-in hatches; `.recent-groups` carries the `min(36rem, 100%)` guard. |
| 1.4.11 Non-text Contrast | AA | Pass | Forced-colors border list covers the chip components; focus ring 2px, 3px in high contrast; bar-chart wash gated by check 12. |
| 1.4.12 Text Spacing | AA | Pass | Token-driven grid and flex layout survives spacing overrides. |
| 1.4.13 Content on Hover or Focus | AA | Pass | No hover-revealed content anywhere. |
| 2.4.6 Headings and Labels | AA | Pass | Headings and the filter label describe their purpose. |
| 2.4.7 Focus Visible | AA | Pass | `:focus-visible` covers every interactive element plus the consumer `[tabindex="0"]` stop; no `:focus` fallback, still safe (Baseline 2022-03). |
| 2.4.11 Focus Not Obscured | AA | Pass | `scroll-padding-top: 3em` on `.table-scroll`, unchanged. |
| 2.5.8 Target Size (Minimum) | AA | Pass | `.mermaid-zoom` 40px, `.nav-list li a` 40 or 44px; the newer components carry no pointer target. |
| 4.1.3 Status Messages | AA | Pass | `filter.js` writes the count into the consumer's `role="status"` element. |

### Patch-worthy

Nothing to propose.

## Interaction and motion

NOTES.md sections read: Interaction states, Form follows role, Borrowed components.

### Searched

- View Transitions API same-document Baseline 2026 Firefox Safari status

### Findings

**[Reinforces, one dating correction]** Same-document View Transitions reached Baseline Newly
available on 2025-10-14 with Firefox 144; cross-document transitions still have no Firefox support
and remain outside Baseline. NOTES.md, Interaction states, records the pass-over with the sentence
"Cross-document support is not Baseline yet", which remains true for what it names, and the
overlay never needed cross-document anyway. The second leg of the decision, that closing the
overlay is a dismissal rather than a state to watch, is taste and unchanged. Same-document
transitions could now technically animate the overlay's missing exit fade, but the recorded
reason not to pursue it was never support. No action, and not a challenge. Source:
web.dev, "Same-document view transitions have become Baseline Newly available", 2025-10-16.

**[Reinforces]** `@starting-style` and `transition-behavior: allow-discrete` stay Baseline Newly
available since 2024-08, unchanged from the last audit's dating. Same conclusion.

**[Reinforces]** The v1.44.0 `.step-hop` fix and the `.tag-dot`/`.live-dot` forced-colors
backgrounds are documented in Borrowed components and verified by the structural gate NOTES.md
describes. The `@keyframes live-pulse` remains covered by the blanket `prefers-reduced-motion`
reset (`tufte-dracula.css`, search `@media (prefers-reduced-motion: reduce)`).

No new hover, press or transition pattern arrived in the window.

### Patch-worthy

Nothing to propose.

## Pinned dependencies

NOTES.md sections read: Fonts, Mermaid.

### Searched

- `npm view @fontsource-variable/source-serif-4 version time.modified`
- `npm view mermaid version time.modified`
- `npm view @mermaid-js/layout-elk version time.modified`
- `gh api repos/mermaid-js/mermaid/releases` (tag list)

### Findings

**@fontsource-variable/source-serif-4**: pinned at 5.3.0 (`tufte-dracula.css`, search
`@fontsource-variable/source-serif-4`). Registry latest: 5.3.0, published 2026-07-19. Pin is
current. (`@fontsource-variable/jetbrains-mono`, added v1.38.0, is also pinned at 5.3.0 and
current.)

**mermaid**: pinned at 11.17.2 (`mermaid.js`, search `mermaid@`). Registry latest: 11.17.2,
published 2026-08-25. Pin is current; the window's own v1.37.2 and v1.37.3 commits did the bumps
from 11.17.0 through 11.17.1 to 11.17.2. Nothing between the shipped pin and today.

**@mermaid-js/layout-elk**: pinned at 0.2.3 (`mermaid.js`, search `layout-elk@`). Registry
latest: 0.2.3, published 2026-08-19. Pin is current.

No bump applies. A future Mermaid bump belongs to `nu scripts/maintain.nu mermaid <version>`,
named here per this skill's rule, never run. The layout-elk tooling gap the last audit named (no
dedicated `maintain.nu` verb) is unchanged and stays a `backlog.md` question, not a design
finding.

### Patch-worthy

Nothing to propose. No dependency bump belongs in this skill's patch regardless of findings.

## Challenges a settled decision

None this run. The nearest candidate was the View Transitions pass-over, whose stated support
blocker ("cross-document not Baseline") remains true for what it names and whose second reason is
explicitly a taste trade; recorded as a Reinforces finding above instead.

## Verification

No patch: nothing to propose. Step 5 is skipped per the skill's own rule, so there is no
worktree run and no dash or added-lines scan over a patch. The report file itself was scanned for
em-dashes and en-dashes and found clean.

## Summary

- Findings total: 18 body findings (6 on the extra subject page, 12 across the six topics), plus
  the 25-row WCAG sweep
- Reinforces a settled decision: 10
- Repeat, unchanged: 5 (`text-wrap: pretty` no Firefox, `hyphenate-limit-chars` limited
  availability, `subgrid` inapplicable, ELK cluster theming, forced-colors `AccentColor` movement)
- New ground: 3 (the MHTML page findings; `contrast-color()` not applicable; container style
  queries not applicable)
- Challenges a settled decision: 0
- Patch: none