# Design audit: 2026-09-11

Commit range: `794b9c4..05d16c5` (the SHA the 2026-09-10 report names as its own read, through
`HEAD`, tag `v1.47.0`), one commit: `05d16c5` "feat: v1.47.0 - Mermaid v12, light/dark editor
themes, a trimmed NOTES.md (#69)". `review/declined.md` holds no rows, so no finding is filtered
by a prior decline.

**Baseline for repeats differs by topic.** The 2026-09-10 report was explicitly scoped to Mermaid
only and skipped Topics 1-5 and the WCAG sweep. The last full run of those is
`review/2026-09-08-design-audit.md`. So: Topic 6 and the ungated-rules sweep compare against
2026-09-10; Topics 1-5 and the WCAG sweep compare against 2026-09-08; the Step 2 delta below
compares against the tree at `794b9c4`, whichever report that was.

This run also carries the first live test of two additions this session made to
`.claude/skills/design-audit/SKILL.md` itself: Topic 1 now owns the Editor themes NOTES.md
section and gets a non-Chromium probe method for slot-map findings, and Topic 6 now checks
provenance/SRI feasibility alongside version freshness. Both surfaced real findings this run; see
Topic 1 and Topic 6 below.

Out of scope for this skill, per the topic map: Filter, Unclaimed elements, Markdown coverage, Raw
HTML and other generators, Fixtures are coverage, Repo layout, Odds and ends. Their absence here
is a scope decision, not an oversight.

## Step 2: delta audit

One commit landed: v1.47.0. It bumped `mermaid.js` to `mermaid@12.0.0`, added `look: 'classic'`
explicitly, removed the now-bundled `@mermaid-js/layout-elk` CDN import and its dynamic loader,
and added a `usecase-beta` fixture. It also added light-mode variants for five editor and
terminal themes (Rider, Zed, Ghostty, iTerm2, VS Code) through a reworked
`scripts/create-themes.nu`. `NOTES.md` itself was trimmed by a net 844 lines in the same commit.
`tufte-dracula.css` changed by exactly one line: the version-stamp comment on line 2, the
AGENTS.md-permitted exception.

Running the four questions against every changed line in `mermaid.js`, `scripts/create-themes.nu`
and the new `themes/**/*.in` templates:

1. **Does NOTES.md document it?** Yes, in full, for both changes. The Mermaid section's Init
   config and Diagram types subsections state the `look: 'classic'` pin, the ELK-bundling
   rationale and the `usecase` theming story in the same prose style as the existing
   `packet`/`xyChart`/ELK-cluster entries. The Editor themes section gained a new "Light and dark
   parity" subsection covering the two-shapes-per-format rule, the `light:`/`dark:` placeholder
   prefix, and the Rider `themeProvider`/`parent_scheme` mechanics. `CONTRACT.md` § 3 also gained
   a v1.47.0 row.
2. **Does it obey AGENTS.md?** Yes. No comment was added to `mermaid.js` (comments in
   `scripts/create-themes.nu` are permitted, it is not inlined) and every jsDelivr URL in the diff
   stays an exact pin.
3. **Does it obey a decision NOTES.md already records?** Yes, no violation found. See the
   ungated-rules sweep below for the mechanical rows.
4. **Does anything render it?** Yes for both. The `usecase-beta` fence shipped in
   `samples/dark.html` alongside the CSS/JS change, so `render-modes.py` and `script-probe.py`
   draw it on every `check`. The light editor/terminal themes are not rendered by Chromium (they
   are not HTML), so the render-probe question here is "does anything regenerate and verify them":
   `scripts/create-themes.nu --check` does, and I ran it, clean.

**No violation found in this delta.** This is a clean release: fully documented, fully rendered,
fully regenerated, nothing landed that Step 4's mechanical sweep or a direct read caught.

### Re-checking the previous report's own non-repeat claims

**Correction to `review/2026-09-10-design-audit.md`.** That report's finding "`look: 'neo'` and
the ELK default: reinforces the user's decision, no regression found" describes work done during
that session, where `look: 'neo'` was added deliberately (see that report's "What this run did,
in order", item 2). **The code that actually shipped in v1.47.0 uses `look: 'classic'`, not
`'neo'`.** `mermaid.js` line 46 reads `theme: 'base', look: 'classic'`, and the current NOTES.md,
Mermaid, Init config states the reasoning explicitly: "Rendered side by side, `neo` adds a
`filter: drop-shadow(...)` and a brighter stroke halo on every node, ink carrying no data,
declined for the same reason the CSS pie lost its `conic-gradient`." The PR body for #69 confirms
this was a deliberate reversal, not a slip: "`look: 'classic'` is pinned explicitly so the new
upstream default (`neo`, a drop shadow on every node) never ships." Whoever finished this work
between the 2026-09-10 session and the merged PR changed course, and the 2026-09-10 report's text
was never updated to say so. Nothing here is a defect in the shipped code: `'classic'` is exactly
what's live, and NOTES.md documents it correctly. The defect is only that a reader of the
2026-09-10 report in isolation would believe `'neo'` shipped. This note exists so the next reader
of that report knows its `look` claim is superseded.

No other claim in the 2026-09-10 report names a file, selector or value that this run's delta
touches differently.

## Color and contrast

NOTES.md sections read: Color and the contrast budget, Appearance modes, Print, Mermaid, Editor
themes.

### Searched

- `CSS Baseline newly available September 2026 web-features monthly digest` (no August or
  September 2026 digest has published yet, same as the 2026-09-08 finding; every Topic 1 Baseline
  claim from that report carries forward uncited)

### Findings

**[New ground] The light editor/terminal theme rollout, verified by probe, not by reading the
template.** Per this session's new Topic 1 scope, I ran `scripts/create-themes.nu --check`
(clean) and `.github/palette-check.py --dump` (returns `{dark: {...}, light: {...}}` as NOTES.md
says it should), then read resolved hex directly out of the generated files rather than trusting
the `.in` templates. Rider's dark `.icls` resolves `on-surface` to `#f8f8f2`, `pink` to `#f081ba`,
`purple` to `#aa8cdb`; the light `.icls` resolves the same three slots to `#161616`, `#ad447d`,
`#7b58ae`. All six match `palette-check.py --dump`'s dark/light values exactly. `plugin.xml`
registers two `themeProvider` entries; the dark `.icls` carries `parent_scheme="Darcula"` and the
light one `parent_scheme="Default"`, exactly as NOTES.md's Light and dark parity subsection
states. The light `dracula-tufte.theme.json`'s `Checkbox.*` keys drop the `.Dark` suffix the dark
copy carries (`Checkbox.Background.Default` vs `Checkbox.Background.Default.Dark`), per
JetBrains' own convention. Zed's one file carries both `"appearance": "dark"` and
`"appearance": "light"` objects, as its schema allows and the two-shapes rule predicts. iTerm2 now
ships two `.itermcolors` files. Every claim in NOTES.md's new subsection checks out against the
generated output. **[Reinforces]** rather than new: the decision was already fully settled and
documented before this run; this is confirmation the implementation matches the documentation,
which is worth reporting for the same reason a passing WCAG row is.

**[New ground, informational, not proposed]** `contrast-color()` reached Baseline Newly available
in the April 2026 digest (source below): a CSS function that picks a WCAG-passing foreground for
a given background with no author-side ramp math. This template already hand-measures every pair
through `palette-check.py`'s gates rather than computing at paint time, and nothing in this delta
touches a contrast pair, so there is no concrete case to apply it to this run. Recorded so its
absence from the patch reads as "no use case yet," not "the audit didn't know."
Source: [web.dev, April 2026 Baseline monthly digest](https://web.dev/blog/baseline-digest-apr-2026).

**[Repeat, unchanged since 2026-09-08]** Forced colors: no new spec movement. The `nav.toc` gap in
the forced-colors block (WCAG 1.4.11) is unchanged; see the WCAG sweep.

**[Repeat, unchanged since 2026-09-07]** APCA stays on the WCAG 3 track and out of the CSS specs.

No `:root` token, mode block, print override or Mermaid hex moved in this window.

### Patch-worthy

Nothing. The editor-themes finding confirms an already-documented decision; the
`contrast-color()` note has no concrete application yet.

## Typography

NOTES.md sections read: Fonts, Type scale, Italics, Paragraphs and section rhythm.

### Searched

- No new query. `tufte-dracula.css` did not change in this window (one version-stamp line only),
  and the 2026-09-08 report's `text-wrap: pretty` and `hyphenate-limit-chars` datings are inside
  their own citation windows.

### Findings

**[Repeat, unchanged since 2026-08-16]** `text-wrap: pretty` still has no Firefox support.
**[Repeat, unchanged since 2026-08-16]** `hyphenate-limit-chars` stays Limited availability,
Safari the sole blocker.

Nothing in this window touches a font, a type-scale token or a paragraph rule.

### Patch-worthy

Nothing.

## Layout and spacing

NOTES.md sections read: Width and measure, Tables, Lists, Connections-map layout, Cascade layer.

### Searched

- No new query. Same reasoning as Typography: no CSS moved, and the 2026-09-08 report's `:has()`
  and `subgrid` datings carry forward uncited.

### Findings

**[Repeat, unchanged since 2026-09-08]** `:has()` Widely available since the June 2026 Baseline
digest. `subgrid` Widely available since March 2026, still inapplicable to `dl.timeline`. The wide
measure was not touched, examined or measured this run.

### Patch-worthy

Nothing.

## Accessibility

NOTES.md sections read: Keyboard and assistive technology, Direction, zoom and growth, Links.

### Searched

- No new query. WCAG version and the 2.5.8 target-size reading both carry forward from
  2026-09-08 unchanged.

### Findings

WCAG version confirmed unchanged: **WCAG 2.2, W3C Recommendation, 2023-10-05, republished
2024-12-12.** WCAG 3.0 remains a Working Draft. See the sweep below for the full table.

**[New ground, informational]** The `usecase-beta` fixture carries `accTitle`/`accDescr` (WCAG
1.1.1), matching the sheet's existing convention for every other diagram type. No new finding
beyond what the sweep records.

### Patch-worthy

Nothing.

### WCAG conformance sweep

Checked against the tree at v1.47.0, commit `05d16c5`. Nothing in `tufte-dracula.css` changed
this window beyond the version stamp, so every row below carries its 2026-09-08 evidence forward
except where the new `usecase-beta` fixture or the light editor themes are named directly. Editor
themes are not part of the generated HTML this sweep covers (they render nowhere in a browser
page), so they touch no row here.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass | Unchanged, plus the new `usecase-beta` fence carries `accTitle`/`accDescr`, matching every other diagram type's convention. |
| 1.3.1 Info and Relationships | A | Pass | Unchanged. |
| 1.3.2 Meaningful Sequence | A | Pass | Unchanged. |
| 1.4.1 Use of Color | A | Pass | Unchanged. |
| 2.1.1 Keyboard | A | Pass | Unchanged; `mermaid.js`'s zoom-button and click-handling code did not change in this bump beyond the CDN version, `look`, and the ELK-loader removal. |
| 2.1.2 No Keyboard Trap | A | Pass | Unchanged. |
| 2.4.2 Page Titled | A | Pass | Unchanged. |
| 2.4.3 Focus Order | A | Pass | Unchanged. |
| 2.4.4 Link Purpose | A | Pass | Unchanged. |
| 2.5.3 Label in Name | A | Pass | Unchanged. |
| 3.1.1 Language of Page | A | Pass | Unchanged. |
| 3.2.1 On Focus | A | Pass | Unchanged. |
| 3.2.2 On Input | A | Pass | Unchanged. |
| 4.1.2 Name, Role, Value | A | Pass | Unchanged. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference, with a gap | Unchanged: covered by Topic 1's palette gate for the three declared grounds; `nav.toc`'s `color-mix` ground stays a documented, bounded gap (NOTES.md, Color and the contrast budget). |
| 1.4.4 Resize Text | AA | Pass | Unchanged. |
| 1.4.10 Reflow | AA | Pass | Unchanged. |
| 1.4.11 Non-text Contrast | AA | Violation, unchanged, not re-patched | The `@media (forced-colors: active)` block still does not mention `nav.toc`; carried forward from 2026-09-08 as an open, reported gap. |
| 1.4.12 Text Spacing | AA | Pass | Unchanged. |
| 1.4.13 Content on Hover or Focus | AA | Pass | Unchanged. |
| 2.4.6 Headings and Labels | AA | Pass | Unchanged. |
| 2.4.7 Focus Visible | AA | Pass | Unchanged. |
| 2.4.11 Focus Not Obscured | AA | Pass | Unchanged. |
| 2.5.8 Target Size (Minimum) | AA | Pass, by the spacing exception | Unchanged. |
| 4.1.3 Status Messages | AA | Pass | Unchanged; `filter.js` did not change in this window. |

Out of scope, per this skill's fixed list: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4,
2.5.7, 3.1.2, 3.2.3, 3.2.4, 3.2.6, 3.3.x.

## Interaction and motion

NOTES.md sections read: Interaction states, Form follows role.

### Searched

- No new query. Nothing in `mermaid.js`'s hover, focus or transition behavior changed in this
  bump; the 2026-09-08 `::details-content` and `@starting-style` findings carry forward uncited.

### Findings

**[Repeat, unchanged since 2026-09-08]** `::details-content` stays Baseline Newly available
(September 2025) and unproposed, for the same cross-engine `interpolate-size` asymmetry reason
already recorded.

### Patch-worthy

Nothing.

## Pinned dependencies

NOTES.md sections read: Fonts, Mermaid.

### Searched

- `npm view mermaid version time.modified dist.attestations`
- `npm view @fontsource-variable/source-serif-4 version time.modified dist.attestations`
- `npm view @fontsource-variable/jetbrains-mono version time.modified dist.attestations`
- `Subresource Integrity import() dynamic ES module attribute support 2026`
- `@font-face src url() integrity attribute SRI support browser`
- `import maps integrity metadata Baseline caniuse Firefox support status 2026`

### Findings

| Dependency | Pinned | Registry latest | Published |
| --- | --- | --- | --- |
| `mermaid` | 12.0.0 | 12.0.0 | 2026-09-10 |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.0 | 2026-07-19 |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | 2026-07-19 |

All three current, all bumped or confirmed by the v1.47.0 release itself. No further bump applies.

**[New ground] Provenance, first run this check exists.** All three packages carry an npm
provenance attestation at the exact pinned version: `npm view <pkg> dist.attestations` returns a
SLSA v1 provenance record for `mermaid@12.0.0`, `@fontsource-variable/source-serif-4@5.3.0` and
`@fontsource-variable/jetbrains-mono@5.3.0`. jsDelivr serves the npm-published tarball unmodified
at each versioned path, so the actual supply-chain question, whether the published artifact is
attested back to its build, is answered yes for everything currently pinned.

**[New ground, informational, not proposed] `integrity=` cannot attach to either loading
mechanism this repo uses, but a real alternative now exists for one of them.**
`@font-face { src: url() }` has no `integrity`/SRI hook in any browser and none is proposed by any
spec: SRI's `integrity` attribute is defined only for `link` and `script` elements, and MDN's own
`@font-face`/`src` documentation names no such mechanism.
Source: [MDN, `@font-face` src descriptor](https://developer.mozilla.org/en-US/docs/Web/CSS/@font-face/src);
[uni-hamburg.de, "Dangers and Prevalence of Unprotected Web Fonts"](https://svs.informatik.uni-hamburg.de/publications/2019/mueller-dangers-and-prevalence-webfonts.pdf).
For `mermaid.js`'s direct-URL ESM `import`, the picture changed since this repo last looked: a
bare `import()`/`import` of a literal URL still has no integrity hook, but **import maps now
carry an `integrity` key that covers both static and dynamic imports resolved through them**,
shipped in Chrome, Firefox 138 and Safari 18.4, per Baseline. Firefox's stable channel is far past
138 as of this run, so this reads as Baseline Widely available territory, though I could not pull
the exact caniuse widget percentage from search results alone; treat the Baseline claim as
"newly available across all three engines," not independently confirmed "widely available" by
date. **Not proposed in this patch.** Using it would mean rewriting `mermaid.js`'s import from a
literal URL to a bare specifier (`import mermaid from 'mermaid'`) plus adding a
`<script type="importmap">` block naming the URL and its SRI hash, which every consumer's
generator would then need to emit alongside `mermaid.js` itself. That is a change to the consumer
contract (`CONTRACT.md` § 3), not a one-file edit, and it is the maintainer's call whether the
security gain is worth a new markup requirement on every consumer. Recorded so the option is
visible next time a Mermaid CDN concern comes up, rather than re-researched from zero.
Sources: [Shopify Engineering, "Shipping support for module script integrity in Chrome & Safari"](https://shopify.engineering/shipping-support-for-module-script-integrity-in-chrome-safari);
[MDN, `<script type="importmap">`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/script/type/importmap).

**[New ground, informational, not proposed] Self-hosting.** Nothing in NOTES.md or
`review/declined.md` records a prior self-hosting proposal for the fonts or the Mermaid bundle,
so this is not a repeat. Given the provenance finding above, the case for it is weak: AGENTS.md's
offline-degradation constraint is already satisfied by the system-serif fallback, and vendoring
binary font files or a bundled JS library would be a real change to this repo's "no build step,
two files inlined verbatim" model, not a one-line swap. Not proposed.

### Patch-worthy

Nothing. `nu scripts/maintain.nu mermaid <version>` is the supported path for any future Mermaid
pin bump, named here per this skill's rule and not run.

## Ungated-rules sweep

| Rule | Source | Status | Evidence |
| --- | --- | --- | --- |
| No comment in `tufte-dracula.css` or `mermaid.js` | AGENTS.md | Pass | `rg -n '/\*' tufte-dracula.css \| rg -v 'was #'` returns line 2 only; `rg -n -e '/\*' -e '^\s*//' mermaid.js` returns nothing. |
| Every `var(--x)` resolves to a declared token or carries a fallback | NOTES.md, Progressive disclosure | Pass | `tufte-dracula.css` did not change this window beyond the version stamp; the full set carries forward from 2026-09-08 unchanged (six references outside `:root`, all deliberate: `--tree-step`/`--bar-tint` declared on their component, `--bar`/`--icon-color`/`--natural-width`/`--timeline-date` consumer-supplied with an in-line fallback). |
| Sides are logical, never physical | NOTES.md, Direction, zoom and growth | Pass | No hit for any physical-side property. |
| Every `:hover` rule sits inside `@media (hover: hover)` | NOTES.md, Interaction states | Pass | All 9 `:hover` selector lines fall inside the one `@media (hover: hover)` block (lines 389-400). |
| Decorative pseudo-element `content` carries an alt-text twin behind `@supports` | NOTES.md, Links | Pass | Three `@supports (content: "x" / "y")` blocks exist, one per decorative pseudo-element pair, unchanged. |
| No styled class without a fixture instance | NOTES.md, Print | Pass | No class selector was added to `tufte-dracula.css` this window. The `usecase-beta` fence added to `samples/dark.html` gives the new Mermaid diagram type a real fixture instance. |
| Mermaid colors are hex, never `oklch()` and never `var()` | AGENTS.md | Pass | `rg -n 'oklch\|var\(' mermaid.js` returns nothing. |
| Exact CDN pin, never a range | AGENTS.md | Pass | `mermaid@12.0.0`, `@fontsource-variable/source-serif-4@5.3.0`, `@fontsource-variable/jetbrains-mono@5.3.0`; no `^`, `~` or `latest`. |
| Never cite a line number into a generated file | AGENTS.md | Pass | No line-number-shaped reference into `samples/` or `tokens.css` in this window's `NOTES.md`, `CONTRACT.md` or `README.md` changes. |
| A new composited or `color-mix()` ground has a NOTES.md paragraph | AGENTS.md | Pass | The one existing `color-mix()` ground (`nav.toc`'s background) is still documented in NOTES.md, Color and the contrast budget, after the trim. No new one was added this window. |

## Challenges a settled decision

None. Nothing this run disagrees with a NOTES.md decision, and nothing proposes reopening one.

## Verification

No patch: nothing to propose. Every finding this run is either a confirmed, already-settled
decision, a correction to the previous report's own text, or new-ground information with no
concrete change to make yet. Step 7 is skipped per the skill's own rule: "Skip this step only when
Step 6 wrote no patch."

I did run `nu scripts/maintain.nu check` against the real tree to confirm the current state (it
printed `Mode renders OK (12 images)`, `Script binding OK (26 assertions)`, `Generated files
fresh.`, `Themes fresh.`, `No em-dash or en-dash.`, `Contract OK.`), and `git status --short`
before and after shows the tree unchanged except this session's already-present edit to
`.claude/skills/design-audit/SKILL.md`. `nu scripts/create-themes.nu --check` also printed
`Themes fresh.` No file this skill is forbidden from touching was edited.

## Summary

- Findings total: 10 across the six topics, plus the 25-row WCAG sweep and the 10-row
  ungated-rules sweep
- Violations of a settled decision: 0
- Corrections to a previous report: 1 (the 2026-09-10 report's `look: 'neo'` claim, superseded by
  the shipped `look: 'classic'`)
- New ground: 6 (editor-themes probe confirmation, `contrast-color()`, npm provenance
  attestations, the `@font-face`/SRI dead end, import-map integrity as a real but unproposed
  option, self-hosting as a real but unproposed option)
- Reinforces: 1 (folded into the editor-themes finding above)
- Repeats, unchanged: 4 (forced colors, APCA, `text-wrap: pretty`, `hyphenate-limit-chars`,
  `:has()`/`subgrid`, `::details-content`, bundled across topics as stated)
- Challenges a settled decision: 0
- Patch: none
- This run's two new skill additions (editor-themes probe scope, SRI/provenance check) both
  surfaced real, reportable findings on their first live run: the editor-themes probe confirmed
  every claim in NOTES.md's new Light and dark parity subsection against generated output, and
  the SRI check surfaced a genuinely new, real option (import-map integrity) that did not exist
  the last time anyone looked at this repo's CDN posture.
