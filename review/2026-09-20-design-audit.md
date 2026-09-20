# Design audit, 2026-09-20

Range: since `05d16c5` (v1.48.0), five commits, one of them payload. Previous report:
`review/2026-09-11-design-audit.md`, which audited `794b9c4..05d16c5`. `review/declined.md` is
present and holds no rows, so no finding here is a declined one.

Five commits, one payload commit (`f5a8344`, "feat/mermaid diagram coverage"), one gate commit
(`0c8f643`), one skill-scope commit and two Pages retriggers. The window is small in CSS and large
in fixtures: `tufte-dracula.css` and `tokens.css` changed line 2 only, the version stamp, so no
selector reached this run for the first time. Everything Step 2 found sits in the 12 new Mermaid
fences, the three `themeVariables` they came with, and the prose that documents them.

## Step 2: the delta

`git diff 05d16c5..HEAD` over the payload and its surroundings:

| File | Change |
| --- | --- |
| `mermaid.js` | `+6`: `gridColor`, `archEdgeColor`, `archGroupBorderColor`, each in both palettes |
| `mermaid-palette.json` | `+6`: the same three keys per palette, with their `from` tokens |
| `tufte-dracula.css` | line 2 only, `v1.47.0` to `v1.48.0` |
| `tokens.css`, `themes/**` | version stamps and rebuilt zip and vsix only; no `themes/**/*.in` changed, so no slot-map probe was owed |
| `scripts/build-sample.nu` | `+32`: 12 new fences under "More diagram types" |
| `.github/render-modes.py` | `+21`: `strip_scripts()`, so mode screenshots no longer carry the inlined scripts |
| `NOTES.md`, `CONTRACT.md`, `README.md` | the prose for the above |
| `samples/*` | regenerated |

### Does the delta obey the questions this step asks

**Does it obey a decision NOTES.md already records.** No payload line does, in two places. Both are
`[Violation of a settled decision]` and both went in the patch.

**Does anything render it.** Yes. All 12 types carry a fixture, and `maintain.nu check` fails when
one stops matching. This is the first window in three runs where that question answers clean.

**Does NOTES.md document it.** Yes for all three `themeVariables`, and the patch corrects what it
says about one of them.

### Findings

1. **`[Violation of a settled decision]` `gridColor` is a dead `themeVariable`, and both
   `NOTES.md` and `CONTRACT.md` describe it as load-bearing.** The swap test settles it: writing a
   probe red into `gridColor` in both palettes left the gantt render byte for byte identical
   (md5 `ae55bd6ce30e1c68ed5f7a24e126b1ae` in dark, `4707fb9d70d9391ddd0ad730e97bc52a` in light,
   before and after). The gantt axis already paints from this stylesheet with no `themeVariable` in
   front of it: in the fixture `.grid .tick line` computes to `oklch(0.977 0.008 106.545)` in dark
   and `oklch(0.2 0 0)` in light, and `.grid .tick text` to `rgb(248, 248, 242)` in dark and
   `rgb(22, 22, 22)` in light. NOTES.md's own sentence is the rule it breaks: "a `themeVariable`
   with nothing to paint is a dead declaration, the same objection that removed a dead
   `font-family` rule in v1.46.0". Patch: removed from `mermaid.js` and `mermaid-palette.json`. The
   pairing floor still clears: 24 keys per palette, 48 across both, CI's floor is 38 and the local
   gate's is 20, and every remaining key still pairs against `mermaid.js`.

2. **`[Violation of a settled decision]` the `kanban` fence's `accTitle` and `accDescr` render as
   two junk columns.** Written inside the fence body, `kanban` reads both lines as column names.
   The rendered labels in `samples/dark-charts.html` before the patch were
   `["accTitle: Kanban board sample", "accTitle: Kanban board sample", "accDescr: Two tasks in a
   Todo column and one task in a Done column.", ... same pair again ..., "Todo", "Todo", "Done",
   "Done", ...]`, so the diagram a reader sees opens with two columns that are not columns, each
   repeated once by Mermaid's own label duplication. CONTRACT.md § 2 requires `accTitle:` and
   `accDescr:` inside every fence, and this is what that requirement buys on this one type. Patch:
   the front-matter form, which `kanban` parses without drawing anything, plus a sentence above the
   fence that carries the same information as text. After: `["Todo", "Todo", "Done", "Done",
   "Write docs", ... "Ship it"]`.

3. **`[Violation of a settled decision]` the `timeline` fence's `accTitle` and `accDescr` are
   inert.** Mermaid's timeline renderer drops both. No `<title>`, no visible text, nothing in the
   accessibility tree. Same patch: front matter plus a prose sentence carrying the three years and
   their versions.

4. **`[Violation of a settled decision]` the `gantt` axis prints every date twice.** Before:
   13 tick labels for 7 distinct days, `["2026-01-01", "2026-01-01", "2026-01-02", "2026-01-02",
   ...]`, at default tick spacing. After `tickInterval 1day` in the fence: 7 labels, 7 distinct, 0
   duplicates, in both palettes. This is a chart option and not a `themeVariable`, which is why the
   fix is on the fence and not in `mermaid.js`.

5. **`[New ground]` `kanban` and `timeline` never produce the SVG `<title>` the zoom button is
   named from.** Whatever form `accTitle`/`accDescr` take, the two types do not surface them, so a
   zoom button over either diagram reads the bare `Zoom diagram` and a page with several of them is
   back to the repeated-name problem *Keyboard and assistive technology* exists to avoid. Measured
   on the patched fixture: every other fence reads `Zoom diagram: <its own title>`, `kanban` and
   `timeline` read `Zoom diagram`. Nothing in this repo can fix it, since the built Mermaid bundle
   is inlined and the behaviour is inside Mermaid's own renderers. Patch: recorded in NOTES.md, in
   Mermaid and in *Keyboard and assistive technology*, with the trade named.

6. **`[New ground]` `journey` renders empty on roughly one load in five, and no gate here can see
   it.** Five loads of the same fixture under CDP: four rendered `nodes=76 textLen=5429`, one
   rendered `processed=true svg=true nodes=1 textLen=0 zoom=true`, with no console error. The
   readiness predicate every harness in this repo uses, an `svg` with a `.mermaid-zoom` inside the
   `pre`, is satisfied by exactly that empty state, so `script-probe.py` passes it. Recorded, not
   patched: the defect is inside Mermaid's journey renderer, a fixture-level retry would hide it,
   and a consumer page hits the same coin flip.

7. **`[New ground]` `.github/render-modes.py` now strips the inlined `<script>` from its scratch
   copies.** Correct, and worth the note it got: the twelve new fences made the mode screenshots
   spend their budget on script execution that `script-probe.py` already asserts separately.
   Informational, no finding.

8. **`[Reinforces]` `archEdgeColor` and `archGroupBorderColor` do paint, and the swap test moved
   both.** In the dark fixture the architecture edge computes to `rgb(151, 159, 196)` (`#979fc4`)
   and in the light fixture to `rgb(98, 106, 140)` (`#626a8c`), each the value its palette declares.
   These two survive the patch; only `gridColor` went.

9. **Re-checked, the previous report's own claim, and this run's first reading of it was wrong.**
   `review/2026-09-11-design-audit.md` records `nu scripts/maintain.nu check` printing
   `Script binding OK (26 assertions)`. With `CHROME` pointing at Brave, today the same command
   prints `Script binding broken.` with `BINDING: mermaid-rendered failed.`, on unmodified HEAD as
   well as on the patched tree, and every other assertion in the same run passes. This run first
   attributed that to a race between `--virtual-time-budget=25000` and the pinned CDN fetch, since
   `mermaid.js` imports `https://cdn.jsdelivr.net/npm/mermaid@12.0.0/dist/mermaid.esm.min.mjs`.
   That attribution does not survive a second browser: with `CHROME` pointing at
   Microsoft Edge 153.0.4234.48, Chromium 153 as Brave is, the same command prints
   `Script binding OK (26 assertions)` and `Contract OK.` on both HEAD and the patched tree, no file
   changed. The budget is not the problem and neither is the CDN; Brave is. The previous report's
   claim still holds and needs no correction in this direction, and the `contract` workflow has been
   green on `38eedef` and on every commit back through `f5a8344`, where Mermaid 12 landed.

## Topic 1: Color and contrast

Nothing in this window touches the sheet's colour system. `tufte-dracula.css` changed line 2 only.
The three new hexes are Mermaid-only and all three are `themeVariable`s mirroring existing tokens,
which the palette gate checks and which this run re-derived: `archEdgeColor` from `--muted`,
`archGroupBorderColor` from `--rule-light`. The one that claimed `--rule-light` and painted nothing
is finding 1, and it left rather than being re-tokened.

`[Reinforces]` the settled split on literal colours. NOTES.md keeps `gantt`'s `today` marker,
`journey`'s actor band and its mood face at Mermaid's own literals, and this run confirmed the
reasoning holds: repainting a mood face would cost information, and the marker is a "you are here"
signal. `[New ground]` one correction: the `today` decision is untested by any fixture, because the
sample's axis sits months away from the current date and the marker lands at x=47252 in a
1228-wide viewBox, outside the visible area. That is now in NOTES.md next to the decision, so the
next run does not have to rediscover it.

`[Reinforces]` the contrast budget itself. The palette gate covers the three declared grounds and
the `nav.toc` `color-mix` ground remains the one bounded, documented gap, unchanged.

### Searched

- "OKLCH gamut mapping CSS color Level 5 Baseline 2026 contrast APCA adoption"
- Sources: CSS Color Module Level 5, W3C Working Draft 19 March 2026,
  <https://www.w3.org/TR/2026/WD-css-color-5-20260319/>; MDN `oklch()`,
  <https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/color_value/oklch>; "OKLCH,
  APCA, and why one luminance number may not be enough", <https://jonplummer.com/2026/03/28/oklch-apca-and-wide-gamut-luminance/>.

`oklch()` is Baseline widely available since May 2023, so the sheet's use of it is not a risk and
has not been for three years. APCA is still not a standard: WCAG 2.2 is the contractual floor
everywhere that matters, and the recommended shape is WCAG 2.2 as the gate with APCA as a
forward-compatible second check. Nothing here changes the repo's position, which is WCAG 2.2 plus a
per-token contrast floor.

## Topic 2: Typography

No type, scale, italic, hyphenation or paragraph-rhythm change in this window.

`[New ground]` one thing worth recording for a later pass: `text-wrap: pretty` still has limited
availability, because Firefox has not shipped it. The umbrella `text-wrap` property is Baseline
2024, which is what makes the per-value situation easy to misread in tooling. This sheet already
uses `text-wrap: pretty` on `.sidenote`/`.marginnote` and `hyphens: auto` beside it, which degrades
correctly, so there is nothing to change. The finding is the shape of the rule, not the value.

### Searched

- "CSS text-wrap pretty balance browser support Baseline 2026"
- Sources: MDN `text-wrap`, <https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-wrap>;
  Chrome for Developers, "CSS text-wrap: pretty", <https://developer.chrome.com/blog/css-text-wrap-pretty>;
  web-platform-dx/web-features issue 3458, <https://github.com/web-platform-dx/web-features/issues/3458>.

`text-wrap: balance` reached Baseline on 2024-05-13 (Chrome 114, Firefox 121, Safari 17.5).
`text-wrap: pretty` did not: Chrome 117 and Safari 26 only, Firefox still treats the value as
invalid, and the WebDX issue tracking the misleading Baseline banner was still open in February
2026.

## Topic 3: Layout and spacing

No layout change in this window. `tufte-dracula.css` changed line 2 only, so the measure rule, the
breakpoints and the one container query are all where the previous run left them.

`[Reinforces]` the container query and the intrinsic-sizing choices. Both `@container` and `:has()`
reached Baseline in 2023, with Firefox shipping container queries on 2023-02-14, so the sheet's
`.scorecard` container query is well inside support. The known limits are the ones NOTES.md already
respects: `container-type: size` disables auto-height, style queries are still Chromium-only, and
nested components want named containers.

`[New ground]` the 320px reflow measurement, re-run against the patched fixtures because the new
fences changed the page: `documentElement.scrollWidth` is 320 against a `clientWidth` of 320 on
both `samples/dark-charts.html` and `samples/dark.html`, so no two-dimensional scroll. The 49 and
81 elements wider than the viewport are all inside an opt-in hatch, the sideways-scrolling `pre`
and `.table-scroll`.

### Searched

- "container queries :has() Baseline status 2026 intrinsic sizing practice"
- Sources: MDN, "CSS container queries",
  <https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Containment/Container_queries>;
  Chrome for Developers, "@container and :has(): two powerful new responsive APIs",
  <https://developer.chrome.com/blog/has-with-cq-m105>; caniuse figures as cited at
  <https://vivianvoss.net/blog/the-width-you-never-had-to-measure>.

## Topic 4: Accessibility

The conformance sweep below is the substance of this topic this run. Two things it turned up are
worth stating here rather than only in the table.

`[New ground]` the new fences are where the accessibility work in this window actually landed, and
one of them was actively harmful: `kanban`'s inline `accTitle`/`accDescr` drew two junk columns,
which is a 1.1.1 problem and a 1.3.1 problem at once, since the page's own markup says those lines
are metadata and the render says they are content. Front matter fixes both.

`[New ground]` `kanban` and `timeline` cannot be named in the way *Keyboard and assistive
technology* relies on, which bounds a mechanism NOTES.md states flatly. The mechanism is unchanged
and still right for the other eleven types; what changed is that the exception is now written down.

`[Repeat, unchanged since 2026-09-11]` 1.4.11 at `nav.toc` under `forced-colors: active`. No
forced-colors rule changed in this window and the gap is where the previous report left it.

### Searched

- "WCAG 2.2 Recommendation latest version 2026 WCAG 3.0 status"
- "WCAG 2.5.8 target size minimum 24px exception inline links 2.4.11 focus not obscured sticky headers"
- Sources: WCAG 2.2, W3C Recommendation 5 October 2023 as republished 12 December 2024,
  <https://www.w3.org/TR/WCAG22/Overview.html>; WCAG 3.0 Working Draft, <https://www.w3.org/TR/wcag-3.0/>;
  WAI, "Understanding Success Criterion 2.5.8",
  <https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html>.

WCAG 2.2 is still the current Recommendation, so this sweep uses its numbering and no version
change is recorded. WCAG 3.0 remains a Working Draft with a tier model instead of A/AA/AAA; its
criteria are not binding and none were checked as if they were.

## WCAG Level A and AA conformance sweep

Twenty-five rows, the fixed table, re-evaluated against what Step 2 found new. Rows marked
"unchanged" carry the previous report's evidence and were re-checked only where the delta touched
them.

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | Pass, with the gap named | Every fence carries `accTitle`/`accDescr`. Re-checked on the delta: the `kanban` and `timeline` fences now carry them as front matter, because inline they became visible columns in one and nothing at all in the other. Both sections also carry the same information as prose, so a reader who cannot see the diagram gets it as text. The named gap: neither type yields an SVG `<title>`, so their zoom buttons take the bare label. See *Mermaid* in NOTES.md. |
| 1.3.1 Info and Relationships | A | Pass | Unchanged. Re-checked on the delta: `kanban`'s junk columns were the one new violation and front matter removes them, restoring the columns the markup declares. |
| 1.3.2 Meaningful Sequence | A | Pass | Unchanged. |
| 1.4.1 Use of Color | A | Pass | Unchanged. |
| 2.1.1 Keyboard | A | Pass | Unchanged. `mermaid.js` changed only by the three removed `themeVariable` lines this patch takes out. |
| 2.1.2 No Keyboard Trap | A | Pass | Unchanged. |
| 2.4.2 Page Titled | A | Pass | Unchanged. |
| 2.4.3 Focus Order | A | Pass | Unchanged. |
| 2.4.4 Link Purpose | A | Pass | Unchanged. |
| 2.5.3 Label in Name | A | Pass | Unchanged; the visible text remains a prefix of the `aria-label`. The bare `Zoom diagram` case in 1.1.1 is a uniqueness loss and not a label-in-name one. |
| 3.1.1 Language of Page | A | Pass | Unchanged. |
| 3.2.1 On Focus | A | Pass | Unchanged. |
| 3.2.2 On Input | A | Pass | Unchanged. |
| 4.1.2 Name, Role, Value | A | Pass | Unchanged. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference, with a gap | Unchanged: covered by Topic 1's palette gate for the three declared grounds; `nav.toc`'s `color-mix` ground stays the documented, bounded gap. The three new hexes are Mermaid-only and the palette gate checks them. |
| 1.4.4 Resize Text | AA | Pass | Unchanged; NOTES.md's stated 400% exception still describes current behaviour. |
| 1.4.10 Reflow | AA | Pass | Re-measured on the patched fixtures, because the new fences changed the page: `scrollWidth` 320 against `clientWidth` 320 on both `samples/dark-charts.html` and `samples/dark.html`. No two-dimensional scroll outside the opt-in hatches. |
| 1.4.11 Non-text Contrast | AA | Violation, unchanged, not re-patched | Carried forward from 2026-09-11 as the open, reported gap: the `@media (forced-colors: active)` block still does not mention `nav.toc`. No forced-colors rule changed in this window. |
| 1.4.12 Text Spacing | AA | Pass | Unchanged. |
| 1.4.13 Content on Hover or Focus | AA | Pass | Unchanged. |
| 2.4.6 Headings and Labels | AA | Pass | Unchanged; the two new prose sentences added by the patch describe their sections. |
| 2.4.7 Focus Visible | AA | Pass | Unchanged. |
| 2.4.11 Focus Not Obscured | AA | Pass | Unchanged: the sticky `thead th` does not obscure focused content, and the new fences add no sticky element. |
| 2.5.8 Target Size (Minimum) | AA | Pass, by the size exception | Re-measured on the patched fixture at 320px: the zoom button is 121x40 CSS pixels, above the 24x24 floor in both dimensions. |
| 4.1.3 Status Messages | AA | Pass | Unchanged; `filter.js` did not change in this window. |

## Out of scope

Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Fixtures are
coverage, Repo layout and Odds and ends are outside this skill's six-topic map, so nothing in them
was read this run. That is a decision, not an oversight.

The delta's one prose change outside the map is CONTRACT.md's v1.48.0 row, which the patch
corrects because it carries a claim about the payload this run disproved.

## Topic 5: Interaction and motion

No transition, press state or hover rule changed in this window. `tufte-dracula.css` changed line 2
only, and the ten `:hover` rules all still sit inside the single `@media (hover: hover)` block that
opens on line 389.

`[Reinforces]` the reduced-motion position. This sheet animates nothing beyond the zoom overlay's
fade in, and it does not use scroll-driven animations, so the 2026 trap that matters, that
`animation-timeline` survives a blanket `animation: none`, does not apply here. Worth naming for a
future pass: if any scroll-linked animation ever arrives, the reset has to null `animation-timeline`
as well, and `::view-transition-*` durations want `0.01ms` rather than `0ms` so `animationend`
still fires.

### Searched

- "prefers-reduced-motion 2026 best practice scroll-driven animations Baseline"
- Sources: MDN `prefers-reduced-motion`,
  <https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion>;
  "Baseline-First CSS for Scroll Animations",
  <https://www.css-scroll-driven.com/core-animation-fundamentals-browser-mechanics/browser-support-progressive-enhancement/baseline-first-css-for-scroll-animations/>.

`prefers-reduced-motion` has been Baseline widely available since January 2020. `animation-timeline:
view()` is much newer, from Chrome 115, Firefox 136 and Safari 18, which is the practical reason
the sheet's avoidance of scroll-driven animation is still the cheap choice.

## Topic 6: Pinned dependencies

`mermaid@12.0.0` is still the registry's `latest` dist-tag, so the pin is current and no bump is
proposed. The two font pins are unchanged.

Per this skill's rule, if a bump is ever wanted the supported path is
`nu scripts/maintain.nu mermaid <version>` and nothing else. Not run this time, because there is
nothing to take.

### Searched

- "Mermaid 12 latest release version 2026 changelog"
- Sources: npm registry metadata for `mermaid`, <https://registry.npmjs.org/mermaid>; GitHub
  releases, <https://github.com/mermaid-js/mermaid/releases>.

| Dependency | Pinned | Registry latest | Note |
| --- | --- | --- | --- |
| `mermaid` | 12.0.0 | 12.0.0 | Current. Published around 2026-09-10. |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.0 | Current. |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0 | Current. |

## Ungated-rules sweep

Ten rows, each one a rule that no check in this repo enforces. Run against the patched tree, and
against the patch itself for the two rows that can be decided from the diff.

| Rule | Source | Status | Evidence |
| --- | --- | --- | --- |
| No comment in `tufte-dracula.css` or `mermaid.js` | AGENTS.md | Pass | `rg -n '/\*' tufte-dracula.css \| rg -v 'was #'` returns line 2 only; `rg -n -e '/\*' -e '^\s*//' mermaid.js` returns nothing. The patch adds zero lines to either file, so it cannot regress this; the added-line scan over the patch found no comment in either. |
| Every `var(--x)` resolves to a declared token or carries a fallback | NOTES.md, Progressive disclosure | Pass | `tufte-dracula.css` did not change this window beyond the version stamp. The full set carries forward from 2026-09-08: six references outside `:root`, all deliberate (`--tree-step` and `--bar-tint` declared on their component; `--bar`, `--icon-color`, `--natural-width` and `--timeline-date` consumer-supplied with an in-line fallback). |
| Sides are logical, never physical | NOTES.md, Direction, zoom and growth | Pass, with two named exemptions | No new hit in this window, since the sheet changed line 2 only. Two pre-existing physical values remain, both deliberate: `float: right; float: inline-end;` on `.sidenote`/`.marginnote` (a fallback pair, the logical value last so it wins) and `background-position: left center` on `table.bar-chart td.bar`, which carries its own `[dir="rtl"]` override on the next line. The 2026-09-11 report recorded this row as "no hit"; a broader pattern than that run used finds these two, and they are exemptions rather than violations. |
| Every `:hover` rule sits inside `@media (hover: hover)` | NOTES.md, Interaction states | Pass | All ten `:hover` selector lines are between 389 and 399, inside the one block that opens on line 389. |
| Decorative pseudo-element `content` carries an alt-text twin behind `@supports` | NOTES.md, Links | Pass | Three `@supports (content: "x" / "y")` blocks, one per decorative pseudo-element pair, unchanged. |
| No styled class without a fixture instance | NOTES.md, Print | Pass | No class selector was added to `tufte-dracula.css` this window, so the rule cannot be broken by it. The question does bite on the delta from the other side, and the answer is clean: all 12 new fence types carry a fixture. |
| Mermaid colors are hex, never `oklch()` and never `var()` | AGENTS.md | Pass | `rg 'oklch\|var\('` over `mermaid.js` returns nothing. The patch removes three hex lines and adds none. |
| Exact CDN pin, never a range | AGENTS.md | Pass | `mermaid@12.0.0`, `@fontsource-variable/source-serif-4@5.3.0`, `@fontsource-variable/jetbrains-mono@5.3.0`; no `^`, `~` or `latest` anywhere in either inlined file. |
| Never cite a line number into a generated file | AGENTS.md | Pass | No line-number-shaped reference into `samples/` or `tokens.css` in this window's `NOTES.md`, `CONTRACT.md` or `README.md`. The patch's own prose cites search strings (`A kanban board`) rather than lines. |
| A new composited or `color-mix()` ground has a NOTES.md paragraph | AGENTS.md | Pass | The one existing `color-mix()` ground, `nav.toc`'s background, is still documented. The three new Mermaid hexes are `themeVariable`s and not composited grounds, and the patch removes rather than adds one. |

## Challenges a settled decision

None. Nothing this run found disagrees with a NOTES.md decision, and nothing proposes reopening
one. The one settled mechanism that turned out to have an exception, the zoom button's name, is
narrower than its wording implied rather than wrong, so it is recorded in NOTES.md as a trade and
not raised against it.

## Verification

Verdict: **Verified** for the patch's own claims, on a gate that first looked like it could not
conclude. The gate turned out to be a browser on this machine, not the check. See below.

The patch was applied to a clean worktree at `38eedef` with `git apply`, which reported all five
files applying cleanly, and `nu scripts/build-sample.nu` then regenerated the fixtures there. The
five source files and the two regenerated chart fixtures are byte-identical to the tree the
renders were measured in (md5 compared file by file), so the numbers below belong to the patch as
written and not to a hand-edit.

`nu scripts/maintain.nu check` in that worktree prints `Contract OK.` with `Mode renders OK (12
images).`, `Script binding OK (26 assertions).`, `Generated files fresh.`, `Themes fresh.`, `No
em-dash or en-dash.` and the palette check passing.

That took a second browser to see. With `CHROME` pointed at the only Chrome-shaped app this machine
had been using, Brave 153.1.95.102, the same unmodified check prints `Script binding broken.` and
`BINDING: mermaid-rendered failed.`, on the branch and on HEAD alike. Swapping `CHROME` to
Microsoft Edge 153.0.4234.48, also Chromium 153, passes all 26 assertions with no change to any
file. The failure is Brave's `--virtual-time-budget` handing back a page whose Mermaid chunks have
not arrived yet, not a defect in `script-probe.py` and not this patch's; the `contract` workflow was
green on `38eedef` and on every commit back through `f5a8344`, which is where Mermaid 12 landed.

This report earlier recorded the gate as unable to conclude, and a follow-up was planned to replace
its virtual clock with a CDP driver. That work is not needed: under a real Chrome the existing
`--dump-dom` probe drives every one of the six fences and asserts them. The record is corrected
here rather than left standing, because a gate that "cannot conclude on this machine" and a gate
that "needs the other browser" are different facts, and only the second one is true.

Everything the patch claims was instead re-rendered in real time under CDP, before and after:

| What | Before | After |
| --- | --- | --- |
| `kanban` rendered labels | 4 junk labels, `accTitle:` and `accDescr:` twice each, ahead of the columns | `["Todo", "Todo", "Done", "Done", "Write docs", "Write docs", "Fix bug", "Fix bug", "Ship it", "Ship it"]` |
| `gantt` axis labels | 13 labels, 7 distinct, 6 duplicates | 7 labels, 7 distinct, 0 duplicates, both palettes |
| `gridColor` painted | setting it to `#ff0000` in both palettes changed nothing (md5 `ae55bd6ce30e1c68ed5f7a24e126b1ae` dark, `4707fb9d70d9391ddd0ad730e97bc52a` light) | key absent from both files |
| `archEdgeColor` painted | `#979fc4` dark, `#626a8c` light | unchanged, still `rgb(151, 159, 196)` and `rgb(98, 106, 140)` |
| palette pairing | 26 keys per palette | 24 per palette, 48 total, no unpaired key, both floors clear |
| 320px reflow | `scrollWidth` 320 vs `clientWidth` 320 | unchanged |
| zoom button | 121x40 CSS px | unchanged |

Two scans ran: zero em-dash or en-dash characters in either this report or the patch, and zero
added lines in the patch carrying a comment into `tufte-dracula.css` or `mermaid.js` (the patch
adds no line to either file at all).

## Counts

One patch, five files, 56 added lines and 21 removed. Seven findings: four violations (one dead
`themeVariable`, two broken fences, one broken axis), two new-ground items recorded rather than
patched, and one correction to the previous report's own claim. Twenty-five WCAG rows classified,
ten ungated rules swept, no challenges. Verdict `Verified`: `nu scripts/maintain.nu check` prints
`Contract OK.` on the patched tree under Chromium 153. The `mermaid-rendered` failure this run first
hit is a Brave artifact, recorded under Verification.
