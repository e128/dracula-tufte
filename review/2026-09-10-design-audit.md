# Design audit: 2026-09-10 (scoped: Mermaid v11.17.2 → v12.0.0)

Scoped run, not a periodic sweep. The user asked to plan and implement a Mermaid v12.0.0 upgrade
with several decisions already made, and to verify five existing or requested diagram types (pie,
C4, class, flowchart, sequence) plus bring in the new `usecase` diagram type. Topics 1-5 of the
normal six-topic research pass, and the full WCAG conformance sweep, are out of scope for this run
by the user's own instruction. Topic 6 (pinned dependencies) is in scope because the whole run is a
pin bump. Step 2's delta audit still ran, against the previous report's commit.

**Commit range:** `edb9cb6..794b9c4` (the tag/commit the 2026-09-08 report's header names as its
own read, through `HEAD`), one commit: `794b9c4` "feat: v1.46.0 - repair the v1.45.0
progressive-disclosure components". That commit touches `mermaid.js` only to delete two comments
left over from an earlier fix, and touches no other Mermaid-relevant source file. **The Step 2 delta
against Mermaid is empty.** Nothing in the range violates a settled Mermaid decision, so every
finding below comes from this run's own upgrade work, not from Step 2.

`review/declined.md` holds no rows, so nothing here is filtered by a prior decline.

## What this run did, in order

1. **Bumped the CDN pin.** `mermaid@11.17.2` → `mermaid@12.0.0` in `mermaid.js`.
2. **Added `look: 'neo'` explicitly**, next to the already-explicit `theme: 'base'`, because Mermaid
   12 changed its own default look from `classic` to `neo` and a page-visible default like that
   should be a stated fact in the payload rather than an inherited one.
3. **Left `layout` unset**, accepting Mermaid 12's new default layout engine (ELK, replacing dagre)
   for every diagram on every fixture, per the user's explicit instruction.
4. **Removed the `@mermaid-js/layout-elk` dynamic import and its second CDN pin.** Mermaid 12 bundles
   ELK into the core package. Verified by rendering the existing `layout: elk` fence in
   `samples/dark-conn-map.html` with the import removed: it still renders, with no layout-loader
   error.
5. **Added a `usecase-beta` fence to `samples/dark.html`**, the new UML use-case diagram type from
   Mermaid 12.0.0, per the user's request to bring it in.
6. **Verified pie, C4, class, flowchart and sequence diagrams** against the v12 bump, by rendering
   each one, not by reading the changelog.
7. **Updated `NOTES.md`, Mermaid section**, with the decisions above, following the file's existing
   pattern for `packet`/`xyChart`/ELK clusters.

No change was made to `mermaid-palette.json`: nothing this run found needed a new theme key (see
the `usecase` finding below).

## Rendering method, and one methodology bug found and fixed mid-run

Every finding below was rendered in headless Chromium through Playwright, using the real
`tufte-dracula.css` body and, once the bug below was found, the real `mermaid.js` verbatim with only
the CDN version (and, for a control run, `look`) substituted, per AGENTS.md, *Verify a rendered claim
by rendering it*.

**The first pass reimplemented `mermaid.js`'s init logic by hand instead of using the real file, and
ran the browser at its default (light) `prefers-color-scheme`, while hand-passing the dark
`themeVariables` set regardless.** That produced a false regression: every subgraph cluster and the
new `usecase` system boundary appeared to render in Mermaid's own pale default fill instead of this
template's palette, on **every** Mermaid version tested, including the currently-shipping
`mermaid@11.17.2`. Reading `tufte-dracula.css` line 60 explained it: `--mermaid-scheme: dark` is a
`:root` token this repo's own real `mermaid.js` reads to choose which JS variable set to pass, and
it is scoped to the CSS cascade, not to the browser's actual color-scheme preference. My hand-rolled
harness never read that token, so the CSS class rules (light, because the harness browser was light)
and the hand-picked JS variables (hardcoded dark) disagreed with each other, on a component neither
version of Mermaid had touched. Rebuilding the harness around the real `mermaid.js` file and forcing
`color_scheme='dark'` in the Playwright context made the false result disappear identically on
`mermaid@11.17.2` and `mermaid@12.0.0`: no regression, on either version. This is exactly the class
of mistake `AGENTS.md` and this repo's own memory of past sessions warn about, arithmetic and a
plausible-looking harness both said "broken," and a correct render said otherwise. Every finding
below used the corrected harness.

## Findings

### `look: 'neo'` and the ELK default: reinforces the user's decision, no regression found

Rendering `samples/dark-conn-map.html`'s three-subgraph flowchart (two open subgraphs plus a legend
subgraph) under `mermaid@12.0.0` with `look: 'neo'` and no `layout` override, against the same
fixture under `mermaid@11.17.2`: every cluster still resolves through `pre.mermaid .cluster rect`
and `pre.mermaid .cluster-label :is(p, span)` (`tufte-dracula.css:368-369`), which is the `!important`
CSS override this template already carries because ELK ignores `clusterBkg`/`clusterBorder` as
`themeVariables` (NOTES.md, Large maps). That override does not care which Mermaid version drew the
cluster rect, only that the rect carries a `cluster` class, so it kept working across the bump
without changes. Diagram bounding-box dimensions shifted between versions (expected: ELK's internal
implementation moved from a plugin to the bundled core), but nothing overflowed, nothing errored, and
the palette held in both dark and light.

### The `layout-elk` import: confirmed dead weight, removed

`samples/dark-conn-map.html` carries a second diagram with an explicit `config: { layout: elk }`
front-matter block. Rendered with the dynamic `@mermaid-js/layout-elk` import removed entirely from
`mermaid.js`, at `mermaid@12.0.0`: the diagram still renders under ELK, with no
`registerLayoutLoaders` call and no layout-loader error. This matches Mermaid 12's own changelog
claim that ELK is now bundled into the core package rather than shipped as a separate optional
module. The import, its `elkPres` filter, and the second CDN pin (`@mermaid-js/layout-elk@0.2.3`)
are removed from `mermaid.js` in the patch.

### `usecase` (new in v12): renders correctly with zero new `themeVariables`

Actor glyphs, use-case ellipses, edge lines, and `include`/`extend` relationship labels all resolve
through the `themeVariables` this template already sets (`primaryColor`, `primaryBorderColor`,
`primaryTextColor`, `lineColor`, `edgeLabelBackground`), verified by reading computed `fill`/`stroke`
on the rendered SVG in both palettes.

A `systemBoundary` was the one part that did not, at first: it rendered with a pale, unthemed fill
regardless of the corrected harness. Setting the two theme keys the Mermaid v12 docs name for this
purpose, `usecaseBoundaryBkg` and `usecaseBoundaryBorder`, changed nothing, rendered with and without
them side by side. Reading Mermaid's own documentation for the feature explained why: a system
boundary is *numbered* from Mermaid's categorical palette the same way a flowchart subgraph or a
composite state is, and those two keys are only the fallback for a theme that carries no categorical
palette to number with, which `base` is not. What actually paints it correctly is the DOM: a
`systemBoundary` renders with a `cluster` class on its wrapping group, identical to a flowchart
subgraph, so this template's existing `pre.mermaid .cluster rect` / `pre.mermaid .cluster-label`
override (written for ELK's ignored `clusterBkg`, see Large maps) already covers it, verified by
rendering the boundary fill and its title text color and finding both correctly on-palette with no
`usecase`-specific override present at all.

**No `mermaid-palette.json` change and no new `mermaid.js` theme key.** This is a `[Reinforces a
settled decision]`-shaped finding: the same "don't add a themeVariable that changes nothing" rule
`actorTextColor` already established for sequence diagrams generalizes to `usecase`'s eight new
theme keys, six of which change nothing (verified by render) and two of which are made moot by CSS
this template wrote for an unrelated reason years before `usecase` existed.

A `usecase-beta` fence with one `systemBoundary`, one `include` relationship, and the actor and two
use cases from this finding's own render, ships in `samples/dark.html` as of this patch, so the claim
above is fixture coverage, not an untested one.

### C4 diagrams: `[Violation-adjacent gap, documented rather than fixed]`

`C4Context`, `C4Container`, `C4Component`, `C4Dynamic` and `C4Deployment` are not themed by this
template, and this template carries no fixture for any of them, before or after this patch. A probe
render (`Person()`, `System()`, one `Rel()`) found:

- `Person()` renders with a literal `fill="#08427B"` / `stroke="#073B6F"` attribute directly on its
  `<rect>`, not through any `themeVariable`. Same for `System()`, at `#1168BD` / `#3C7FC0`.
- The `Rel()` relationship label renders at `#444444`, a dark gray that fails contrast outright
  against this template's dark ground.

This is the same defect class NOTES.md already names for `xyChart`: Mermaid sets these as literal
attributes on each shape rather than reading `theme: 'base'` or any `themeVariable`. Unlike
`xyChart`, a CSS door does exist here (an `!important` rule the way `packet` and the ELK cluster
override both already use this template), but C4's several shape tiers (`person`,
`external_person`, `system`, `external_system`, `system_db`, `system_queue`, and the
`container`/`component` tiers again) are a lot of speculative surface to theme with no fixture to
prove any of it against, which is exactly the "no styled class without a fixture instance" rule
this repo already holds itself to (NOTES.md, Print, *Fixtures are coverage*). **This finding stops
at documentation rather than a fix**: `NOTES.md`, Diagram types, now states plainly that C4 is
unthemed here and that its relationship-label contrast specifically is known to fail, so a consumer
who reaches for a C4 diagram on this template's dark palette knows to check before shipping it,
rather than discovering it cold. Adding a real fixture and a real fix is a separate, larger piece of
work than "verify support," and this run does not do it speculatively.

### Class, pie, flowchart, sequence: `[Reinforces a settled decision]`, no changes needed

All four rendered correctly at `mermaid@12.0.0` with `look: 'neo'`, in both palettes, with no console
or page errors and no Mermaid-injected error state:

- **Pie**: slice fills, `pieSectionTextColor`, `pieOpacity`, and both strokes all still resolve as
  NOTES.md's existing pie section describes. No v12 changelog item touches pie.
- **Sequence**: actor boxes, the `Note over` bridge, and message labels all still resolve through
  existing `themeVariables`. The changelog's "sequence diagram actors aligned vertically under neo
  look" bug fix is a Mermaid-side improvement this template inherits for free; nothing here needed
  to change to take it.
- **Flowchart**: the existing `flowchart TD`/`flowchart BT` fixtures render correctly under the new
  ELK default (see above). `flowchart.wrappingWidth`'s v12 change (no longer applied to stadium,
  circle, diamond, display or delay node shapes) does not apply: no fixture in this repo uses those
  shapes or sets `wrappingWidth`.
- **Class**: renders correctly with the existing `primaryColor`/`primaryBorderColor` theming and no
  class-diagram-specific override, the same story as `usecase`'s ellipses. No fixture carries a
  `classDiagram` fence before or after this patch; the user's request was to verify support, not to
  add coverage, and nothing this run found makes class diagrams a `[Violation]` or a gap worth
  documenting the way C4 is; it simply works.

### Topic 6: pinned dependencies

| Dependency | Pinned before | Pinned after | Registry latest | Action |
| --- | --- | --- | --- | --- |
| `mermaid` | 11.17.2 | 12.0.0 | 12.0.0 (published 2026-09-10, the day of this run) | Bumped in the patch, per the user's explicit request. This is the one case where the general Topic 6 rule ("do not put a Mermaid bump in the patch, name `nu scripts/maintain.nu mermaid <version>` instead") does not apply: the user asked for a real, structural upgrade (`look`, the ELK import removal, `usecase` support), not a routine pin-only bump, so the version line is one hunk of the same `mermaid.js` diff as everything else, exactly the ordinary "edit the source, then regenerate" flow AGENTS.md already describes, not the `maintain.nu mermaid` shortcut. |
| `@mermaid-js/layout-elk` | 0.2.3 | removed entirely | n/a | Removed; see the finding above. |
| `@fontsource-variable/jetbrains-mono` | 5.3.0 | unchanged | not re-checked this run (out of scope: not Mermaid) | none |
| `@fontsource-variable/source-serif-4` | 5.3.0 | unchanged | not re-checked this run (out of scope: not Mermaid) | none |

## Ungated-rules sweep (Mermaid-relevant rows only, this run's scope)

| Rule | Status | Evidence |
| --- | --- | --- |
| No comment in `mermaid.js` | Pass | `rg -n -e '/\*' -e '^\s*//' mermaid.js` returns nothing, in the patched file |
| Mermaid colors are hex, never `oklch()`/`var()` | Pass | `rg -n 'oklch\|var\(' mermaid.js` returns nothing |
| Exact CDN pin, never a range | Pass | `mermaid@12.0.0` only; no `^`, `~`, or `latest` |
| No em-dash/en-dash in the changed files | Pass | A scan for U+2014 and U+2013 returns nothing across `NOTES.md`, `mermaid.js`, `scripts/build-sample.nu` (sanity-checked against a planted em-dash first, to confirm the scan itself works) |
| No styled class without a fixture instance | Pass | The `usecase-beta` fence added to `samples/dark.html` gives the finding above a real instance. C4 is deliberately left with **no** fixture and **no** override, per the finding's own reasoning, so this rule is satisfied by omission rather than by coverage there |

Every other row of the full ungated-rules table (logical sides, `:hover` scoping, decorative
`content`, etc.) is out of scope for this run: nothing this run touched can violate them, since the
only source files this run edited are `mermaid.js`, `NOTES.md`, and `scripts/build-sample.nu`, and
none of those rules apply to any of the three.

## Out of scope, by the user's own instruction for this run

Topics 1-5 (color, typography, layout, accessibility, interaction) and the full WCAG conformance
sweep. The C4 relationship-label contrast finding above surfaced incidentally from Topic-6-adjacent
render verification, not from a WCAG sweep, and is reported because it is real and render-confirmed,
not because Topic 4 ran.

## Verification

```
$ git worktree add --detach /tmp/design-audit-mermaid12 HEAD
$ # edited mermaid.js, NOTES.md, scripts/build-sample.nu in the worktree
$ nu /tmp/design-audit-mermaid12/scripts/build-sample.nu
$ nu /tmp/design-audit-mermaid12/scripts/maintain.nu check
Contract OK.
```

`Verified: patch applies to HEAD and Contract OK after regeneration.` `check` includes
`.github/script-probe.py`, which drives the real regenerated `samples/dark.html` (carrying the new
`usecase-beta` fence) through headless Chrome and asserts every `pre.mermaid` gets an `<svg>` and a
working zoom button; that passed too (`Script binding OK, 26 assertions`), against `mermaid@12.0.0`
live from the CDN.

A scan for U+2014 and U+2013 returns nothing for this report and its patch. A scan of the patch's
added lines for `/*`, `*/`, and `//` returns one hit, the `https://` in the bumped CDN import line,
which is the documented URL-protocol over-match rather than a real comment: no comment lines were
added to `mermaid.js`.

## Counts

10 findings. 0 violations of a settled decision (the Step 2 delta was empty). 8 new (look/ELK
default, layout-elk removal, usecase support, usecase boundary CSS reuse, C4 gap documentation, and
the class/pie/sequence/flowchart reconfirmations, several bundled per finding above). 0 repeats
(first Mermaid-scoped run). 0 challenges a settled decision. 1 methodology bug found and fixed
mid-run (the light/dark harness mismatch), reported above rather than silently corrected, per this
skill's own render-first rule.
