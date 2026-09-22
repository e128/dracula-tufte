# Design audit, 2026-09-22

Range: since `f9aaa65`, zero commits. `HEAD` is `f9aaa65`, the commit the previous report read.
Previous report: `review/2026-09-21-design-audit.md`. It names no end SHA in its header, so this run
took `f9aaa65` from its Step 2 table, which ends there. `review/declined.md` holds no rows, so no
finding here is a declined one.

**No payload commit landed, so this run spent its effort on Step 4 and on re-checking old claims.**
That is where both real findings came from. Each one corrects a verdict that four or more previous
reports carried forward without a render.

## Step 2: the Delta

No commit in the window. Nothing to put the four questions to.

### Corrections to Previous Reports

**Correction 1: the pseudo-element alt-text row was wrong in every report that marked it Pass**
(2026-09-08, 09-10, 09-11, 09-20 and 09-21 at least). Two of the four `content: "…" / ""` twins
never took effect. Details under the ungated-rules sweep. The later reports checked only whether a
twin existed. None checked where it sat.

**Correction 2: the 1.4.11 row for `nav.toc` was not a violation.** The 2026-09-08 report marked it
a violation, left it unpatched, and asked for a re-sweep "next run with the instance in place". The
fixture instance landed in that same patch. Four runs later, no run had drawn it under forced colors.
This run did, in `samples/dark.html` with `forced_colors="active"`:

| Element | Computed under forced colors |
| --- | --- |
| `nav.toc` border-inline-start | `3px solid rgb(0, 0, 0)` (CanvasText) |
| `nav.toc` background | `rgba(255, 255, 255, 0.6)` (Canvas at the author alpha) |
| `nav.toc a` border-block-end | `1px dotted rgb(0, 0, 159)` (LinkText) |
| `nav.toc a` color | `rgb(0, 0, 159)` (LinkText) |

The box keeps its boundary and every link keeps its marker. The 2026-09-08 row said the same thing
in prose ("the `border-inline-start` ... does survive as `CanvasText`. The box therefore still reads
as a box") and then called it a violation anyway. The row is now **Pass**.

## Topic 1: Color and Contrast

`[Repeat, unchanged since 2026-09-20]` for every finding. No token or mode block moved.

### Searched

Nothing new. The window is empty and every prior dating is still inside its citation window.

## Topic 2: Typography

`[Repeat, unchanged since 2026-09-20]` for the `text-wrap: pretty` note (Chrome and Safari only).

### Searched

Nothing new, for the same reason.

## Topic 3: Layout and Spacing

`[Repeat, unchanged since 2026-09-20]`. Re-measured anyway on the probe page: `scrollWidth` equals
`clientWidth` at 1280px (1280) and at 320px (320), before and after the patch.

### Searched

- `web.dev Baseline digest August 2026 CSS newly available`: the newest digest found was
  [May 2026](https://web.dev/blog/baseline-digest-may-2026). Nothing in it touches a layout
  decision here. The running list is [Baseline 2026](https://web.dev/baseline/2026).

## Topic 4: Accessibility

WCAG 2.2 (Recommendation, 2023-10-05) is still current. WAI published a new WCAG 3 Working Draft on
2026-09-10, and it is still a Working Draft
([W3C WAI news, 2026-09-10](https://www.w3.org/WAI/news/2026-09-10/wcag3/)). No version change to
the sweep table. This also confirms the draft date that the 2026-09-21 report quoted.

**[New ground] `.math.display` is a scroll container that no fixture draws and NOTES.md never
mentions.** The rule is `.math.display { display: block; overflow-x: auto; ... }` (the pandoc
MathJax span). NOTES.md, Keyboard and assistive technology, gives `math[display="block"]` a
`tabindex="0"`, a role and a label because it scrolls. The pandoc span gets none of that, and CSS
cannot supply a tab stop. Chrome 132 and Firefox focus a scroller with no focusable child on their
own. Safari still does not, so the feature is not Baseline
([Chrome for Developers](https://developer.chrome.com/blog/keyboard-focusable-scrollers),
[Interop issue #762](https://github.com/web-platform-tests/interop/issues/762),
[Adrian Roselli, updated January 2026](http://adrianroselli.com/2022/06/keyboard-only-scrolling-areas.html)).
In Safari, an overflowing display equation is out of keyboard reach (2.1.1). **Not in the patch.**
The fix is a consumer markup obligation or a `mermaid.js`-style runtime shim, and which one is a
design decision. A fixture instance must come first, per the class-instance row below.

**[New ground, informational] Permalinks measured for the first time.** `a.headerlink` and
`a.anchor` have no fixture instance, so this run drew them on a probe page with the real stylesheet:

| Width | `h2 a.headerlink` (¶) | `h3 a.anchor` (#) |
| --- | --- | --- |
| 1280px | 11.9 by 28px | 8.8 by 23px |
| 320px | 10.3 by 24px | 7.7 by 20px |

Both sit under 24px wide. They pass 2.5.8 by the spacing exception: one target per heading line, so
a 24px circle on each one meets no other target. Tab reached the ¶ link first, and it rendered at
`opacity: 1` with a solid outline, so the `:focus-visible` half that NOTES.md, Raw HTML and other
generators, calls "not optional" works.

### Searched

- `WCAG 3.0 working draft September 2026 status W3C`
- `keyboard focusable scroll containers Baseline Safari Chrome 130 Firefox`

## WCAG Conformance Sweep

| Criterion | Level | Status | Evidence |
| --- | --- | --- | --- |
| 1.1.1 Non-text Content | A | **Violation, patched** | Chromium exposes the decorative `“` inside `blockquote.pull` as text and names the first cell of each child tree row `"↳ F1"`. The alt-text twins exist but lose on source order (see sweep). After the patch, both are gone from the ARIA snapshot of `samples/dark.html`. The `kanban`/`timeline` `<title>` gap stays as NOTES.md records it. |
| 1.3.1 Info and Relationships | A | Pass | Unchanged. |
| 1.3.2 Meaningful Sequence | A | Pass | Unchanged. |
| 1.4.1 Use of Color | A | Pass | Unchanged. |
| 2.1.1 Keyboard | A | Pass, with a gap named | Fixture scrollers all carry `tabindex`. The untested `.math.display` is unreachable in Safari (Topic 4). |
| 2.1.2 No Keyboard Trap | A | Pass | Unchanged. |
| 2.4.2 Page Titled | A | Pass | Unchanged. |
| 2.4.3 Focus Order | A | Pass | Unchanged. |
| 2.4.4 Link Purpose | A | Pass | Unchanged. |
| 2.5.3 Label in Name | A | Pass | Unchanged. |
| 3.1.1 Language of Page | A | Pass | Unchanged. |
| 3.2.1 On Focus | A | Pass | Unchanged. |
| 3.2.2 On Input | A | Pass | Unchanged. |
| 4.1.2 Name, Role, Value | A | Pass | Unchanged. A tree cell's name carried the arrow glyph (1.1.1). The patch fixes that too. |
| 1.4.3 Contrast (Minimum) | AA | Cross-reference, with a gap | Unchanged. The `nav.toc` `color-mix` ground stays the documented gap. |
| 1.4.4 Resize Text | AA | Pass | Unchanged. |
| 1.4.10 Reflow | AA | Pass | Probe page: `scrollWidth` 320 equals `clientWidth` 320 at 320px. |
| 1.4.11 Non-text Contrast | AA | **Pass (corrected)** | Rendered under forced colors: the `nav.toc` border is CanvasText, the link markers are LinkText. See Correction 2. |
| 1.4.12 Text Spacing | AA | Pass | Unchanged. |
| 1.4.13 Content on Hover or Focus | AA | Pass | The permalink appears on heading hover, covers no content, and stays while the pointer is on the heading. |
| 2.4.6 Headings and Labels | AA | Pass | Unchanged. |
| 2.4.7 Focus Visible | AA | Pass | Permalink: `opacity: 1` and a solid outline on keyboard focus (probe). |
| 2.4.11 Focus Not Obscured | AA | Pass | Unchanged. |
| 2.5.8 Target Size (Minimum) | AA | Pass, by the spacing exception | TOC as before. Permalinks measured above. |
| 4.1.3 Status Messages | AA | Pass | `filter.js` unchanged. The 13 filter assertions pass. |

Out of scope, per the skill's fixed list: 1.2.x, 2.2.x, 2.3.x, 2.4.1, 2.4.5, 2.5.1, 2.5.2, 2.5.4,
2.5.7, 3.1.2, 3.2.3, 3.2.4, 3.2.6, 3.3.x.

## Topic 5: Interaction and Motion

`[Repeat, unchanged since 2026-09-20]`. All ten `:hover` lines (390-399) sit inside the
`@media (hover: hover)` block that opens at 389.

## Topic 6: Pinned Dependencies

| Package | Pinned | Latest (npm) | Provenance |
| --- | --- | --- | --- |
| `mermaid` | 12.0.0 | 12.0.0, published 2026-09-10 | npm attestation present |
| `@fontsource-variable/source-serif-4` | 5.3.0 | 5.3.0, modified 2026-07-19 | npm attestation present |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | 5.3.0, modified 2026-07-19 | npm attestation present |

No bump to take. Neither `@font-face src: url()` nor a remote ESM `import` can carry `integrity`, so
the npm attestation is the checkable provenance, and all three packages have one.

**Re-check of the 2026-09-21 claim that Mermaid 12 makes ELK the default layout: confirmed.** The
release bundles ELK as the default and adds new default looks
([mermaid releases](https://github.com/mermaid-js/mermaid/releases),
[mermaid-cli PR #1182](https://github.com/mermaid-js/mermaid-cli/pull/1182)). The fixture renders
green under 12.0.0 (`Mode renders OK (12 images)`), so nothing changes here.

### Searched

- `mermaid 12.0.0 release notes ELK default layout`
- `npm view <pkg> version time.modified dist.attestations` for all three pins

## Ungated-rules Sweep

| Rule | Source | Status | Evidence |
| --- | --- | --- | --- |
| No comment in `tufte-dracula.css` or `mermaid.js` | AGENTS.md | Pass | Line 2 only. `mermaid.js` returns nothing. |
| Every `var(--x)` resolves or carries a fallback | NOTES.md, Progressive disclosure | Pass, with a NOTES.md count error | A set difference finds no undeclared reference without a fallback. Six resolve outside `:root`: `--tree-step` and `--bar-tint` on their components, and `--bar`, `--icon-color`, `--natural-width` and `--timeline-date` through fallbacks. NOTES.md says "Seven" and then lists those six. The patch corrects the count. |
| Sides are logical | NOTES.md, Direction, zoom and growth | Pass | The grep returns nothing. RTL probe: the pull-quote mark's `right` is 3.2px, which mirrors `left` in LTR. |
| `:hover` inside `@media (hover: hover)` | NOTES.md, Interaction states | Pass | Lines 390-399, in the block at 389. |
| Decorative `content` has an alt-text twin **after** its base | NOTES.md, Links | **Violation, patched** | The `@supports` block at lines 114-118 holds three twins. Two of them sit above their base rules: the tree arrow (base at line 195) and `blockquote.pull::before` (base at 221). Selectors are identical and `@supports` adds no specificity, so the base wins. Computed `content` at 1280px, 320px, RTL and print: tree `"↳ "`, pull `"“"`, with no `/ ""`. This has been true since v1.10.0 (`937c95a`) and v1.33.0 (`dbf9c05`). The outbound arrow's twin stays where it is: the print block's `content: ""` at line 526 has to beat it, and moving it later would print the arrow. |
| No styled class without a fixture instance | NOTES.md, Print | **Violation, not patched** | Earlier reports read this row as "no class added this window". Swept against the whole sheet, most misses are highlighter role classes. NOTES.md, Fixtures are coverage, covers those on purpose with one representative per role group. Four real components have no instance: `a.headerlink`/`a.anchor`, `.math.display`, `img.emoji`. Not patched, because which generator's markup the living fixture should demonstrate is a fixture-design choice. `.cluster`/`.packet*` are Mermaid runtime classes, and the fixture fences produce them. |
| Mermaid colors are hex | AGENTS.md | Pass | `rg 'oklch\|var\(' mermaid.js` returns nothing. |
| Exact CDN pin | AGENTS.md | Pass | See Topic 6. |
| No line number into a generated file | AGENTS.md | Pass | No new pointer. The patch adds none. |
| Composited ground is gated or documented | AGENTS.md | Pass | One `color-mix()`, `nav.toc`, documented. |

### The Gate This Run Adds

The alt-text row can be checked mechanically, so the patch gates it. `.github/script-probe.py` gains
four assertions in its no-network half. Each one reads `getComputedStyle(el, pseudo).content` and
requires the value to end in `/ ""`: outbound arrow, tree arrow, pull quote and summary triangle.
The binding floor rises from 13 to 17. **Mutation check:** run against the unpatched fixture,
`alt-tree-arrow` and `alt-pull-quote` fail and `alt-outbound-arrow` and `alt-summary-triangle`
pass. After the fix, all four pass. The gate goes in together with the fix it demands, so `HEAD`
plus the patch stays green.

## Challenges a Settled Decision

None.

## Out of Scope

Filter, Unclaimed elements, Markdown coverage, Raw HTML and other generators, Fixtures are coverage,
Repo layout and Odds and ends sit outside the six-topic map. Fixtures are coverage and Raw HTML and
other generators were read only as far as the class-instance and permalink findings needed.

## The Patch

`review/2026-09-22-design-audit.patch`, against `HEAD` (`f9aaa65`), three source files:

- `tufte-dracula.css`: moves the tree-arrow and pull-quote twins out of the early `@supports` block
  and into their own `@supports` blocks directly after each base rule. No comment added.
- `.github/script-probe.py`: the four alt-text assertions and the new floor.
- `NOTES.md`: "Seven references" becomes "Six references". Links gains one decision: the twin sits
  after its base rule, never above it, and `script-probe.py` asserts every twin.

Before and after, computed `content` on the probe page (same at 1280px, 320px, RTL and print):

| Pseudo-element | Before | After |
| --- | --- | --- |
| tree arrow | `"↳ "` | `"↳ " / ""` |
| pull quote | `"“"` | `"“" / ""` |
| outbound arrow | `" ↗" / ""` (print `""`) | unchanged |
| summary triangle | `"▸ " / ""` | unchanged |

ARIA snapshot of `samples/dark.html` after regeneration: the tree cell and the pull quote no longer
carry the glyphs.

## Verification

Verified: patch applies to HEAD and Contract OK after regeneration. `Script binding OK (30
assertions)` (26 before, plus the 4 new ones), `Mode renders OK (12 images)`, `Palette OK`. Run in
a fresh detached worktree at `f9aaa65`, with `build-sample.nu` before `check`. The worktree was
removed afterwards.

The patch adds no line with `/*` or `*/` to `tufte-dracula.css`. The one new `//` comment is in the
JavaScript driver string inside `.github/script-probe.py`, which no consumer inlines. This report and
the patch contain no em-dash or en-dash.

## Counts

Findings: 5. Violations of a settled decision: 1 (alt-text twin order, patched with a gate). Other
violations: 1 (class-instance row on a whole-sheet reading, not patched). New: 2 (`.math.display`
keyboard reach in Safari, permalink measurements). Corrections of previous reports: 2 (alt-text row,
`nav.toc` 1.4.11). NOTES.md count fix: 1. Repeats: Topics 1, 2, 3 and 5 unchanged. Challenges: 0.
