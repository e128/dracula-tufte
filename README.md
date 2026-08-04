# dracula-tufte

Arrr, gather 'round ye landlubbers — this here be the public contract for the **Tufte-Dracula** HTML conventions, hoist high as the single source of truth for the stylesheet, palette, Mermaid init, and sample fixtures.

This repo be the canonical home fer the eight artifacts that fer too long were scattered like spilled grog. Consumers pull this repo in through a pinned git submodule at `external/dracula-tufte/` — one place, one truth, no driftin'.

## Live Previews

Rendered in-browser via GitHub Pages (main branch, served straight — no build step):

- [sample.html](https://e128.github.io/dracula-tufte/sample.html) — component sample
- [sample-conn-map.html](https://e128.github.io/dracula-tufte/sample-conn-map.html) — connections-map layout

## The Eight Files

| File                  | What It Be |
|-----------------------|------------|
| `tufte-dracula.css`   | **The stylesheet payload.** The complete `<style>…</style>` block (template v1.15.0, oklch palette). Consumers inline this verbatim into every generated HTML file. Includes the wrapping `<style>` tags and 2-space leading indent — the exact byte sequence the renderer emits. |
| `mermaid.js`          | **The Mermaid init script.** The complete `<script type="module">…</script>` block — the `mermaid@11` CDN import, `theme: 'base'` + `darkMode` + hex `themeVariables` init, and the zoom overlay handler (injects a `<button class="mermaid-zoom">` per diagram; the overlay is a focus-managed `role="dialog"`). Despite the `.js` name it holds the wrapping `<script>` tags. Consumers inline this only when the rendered scroll contains a ` ```mermaid ` fence. Bump the CDN pin here. |
| `mermaid-palette.json` | **Mermaid's hex palette.** The Tufte-Dracula palette as hex, per `themeVariables` key plus `classDef` node roles. Mermaid cannot consume `oklch()` (khroma throws `Unsupported color format` and *no* diagram renders) or `var()`, so this be the one place hex lives. Each entry names the `:root` variable it projects in its `from` field, and CI recomputes every hex from that variable's `oklch()` — hex here that disagrees with the stylesheet fails the build. `mermaid.js` carries the same values inline because consumers inline it with no build step; CI fails if the two disagree. Generators that emit their own `classDef` lines read the `classdef` block, whose fills draw only from the `--data-1..4` ramp (the prose accents `--pink`/`--green`/`--orange` already mean something in body copy). |
| `tokens.css`          | **Palette reference. Generated.** The `:root { … }` block of `tufte-dracula.css`, sliced out verbatim by `build-sample.nu`. Not read by the renderer. Do not hand-edit — change `tufte-dracula.css` and regenerate. |
| `build-sample.nu`     | **The regenerator.** Runs `nu build-sample.nu` to rebuild `tokens.css`, `sample.html` and `sample-conn-map.html` from the canonical CSS + JS. Run after any stylesheet or Mermaid change. |
| `sample.html`         | **Living style fixture.** Generated default-body demo — headings, sidenotes, tables, scorecard, verdict chips, nav, badges, mermaid + zoom. Self-contained. Do not hand-edit — regenerate via `build-sample.nu`. |
| `sample-conn-map.html` | **Conn-map fixture.** Generated `<body class="conn-map">` two-section layout (Links, Graph — that DOM order is required) — the connections-map split `sample.html` can't show inline. Resize past 900px to see Links go left+sticky. |
| `README.md`           | **This here scroll.** |

## Consumers

Consumers pin to a tag (currently **`v1.15.0`**) via a git submodule at `external/dracula-tufte/`. To refresh a consumer: bump the submodule pointer, run `git submodule update --remote external/dracula-tufte`, then commit the new pointer.

**Inline verbatim, or slice the body.** `tufte-dracula.css` ships wrapped in its own `<style>` tags for consumers that inline it whole. A consumer whose generator supplies the wrapper itself takes the bare body with `sed '1d;$d'` — the wrapper be exactly one line at each end, and CI holds it there, so the slice can't rot. Same for `mermaid.js` and its `<script>` tags. Consumers needing the overlay CSS conditionally should note it ships in the stylesheet unconditionally (a dozen inert lines when no diagram be present); `mermaid.js` and the `<div class="mermaid-overlay" id="mermaid-zoom">` be the parts to omit, and the script throws a named error if the div be missing.

## What the Markup Must Supply

The stylesheet and script cannot fix markup they don't emit. A consumer's generator owes seven things, each modelled in `sample.html` / `sample-conn-map.html`:

- **`<main>` around the content**, so there be a primary landmark to jump to. `<article>` inside it keeps the sidenote counter and the conn-map layout selectors working.
- **A real `<label for>` on the filter input.** A placeholder be not a label — it announces as an unnamed field and vanishes on the first keystroke. The fixture uses `<label class="filter-label" for="nav-filter">` with `type="search"` and `autocomplete="off"`. A consumer that wires the filter's behaviour also owes a `role="status"` region for the result count, and `.filter-empty` for the no-matches line.
- **`accTitle:` and `accDescr:` inside every ` ```mermaid ` fence.** Mermaid renders the SVG as an unnamed `graphics-document` otherwise — a diagram carrying real structure with no text alternative. These be fence directives; no stylesheet change can supply them.
- **`scope="col"` on table headers**, and heading levels that nest (`h1` → `h2` → `h3`, no skips). For conn-map pages that means the Links section carries its own `<h2>`, since it now comes first in the DOM.
- **`role="list"` on every `<ul class="nav-list">`.** `.nav-list` sets `list-style: none`, and WebKit drops list semantics when it sees that — VoiceOver stops saying "list, N items" and stops giving item position, so a nav index becomes a run of loose links. Prose `<ul>` needs nothing: it keeps its markers, so it keeps its semantics.
- **`data-depth` on every row of a `<table class="tree">`**, counting from `0` at the root, and rows in document order so each child follows its parent. Depth be an author claim, not something the stylesheet can infer: the indent, the root tint and the `↳` come from that attribute alone. Levels `0`–`3` be styled; a deeper row renders flat rather than wrong. The table keeps its native semantics, so it still owes `scope="col"` like any other. It be **not** a `treegrid` — that role promises arrow-key navigation and `aria-expanded`, and neither ships here, so don't add the role.
- **`tabindex="0"` on anything that scrolls sideways**, with a `role="region"` and a label so the stop announces itself. `pre` be `overflow-x: auto`, and a table below 600px be its own scroll container, so a keyboard user cannot reach the overflowed content otherwise (WCAG 2.1.1). The fixture uses `<pre tabindex="0" role="region" aria-label="Code block">`; the label be a consumer string, so localise it.

**`.verified` / `.unverified` / `.correction` carry meaning by colour alone.** Pair each with a word or a mark — the fixture's `verified` / `unverified` / `correction` text be the cue, not the hue. Under forced-colors all three resolve to the same foreground, and a colour-blind reader never had the distinction.

**Click-to-zoom needs no markup.** `mermaid.js` injects a real `<button class="mermaid-zoom">` under each diagram, which be the keyboard and touch path; the overlay is a `role="dialog"` that takes focus, inerts the rest of the body, and returns focus on Escape. It be `inert` while closed, so a page with no diagram open carries no dialog in the accessibility tree. The only thing a consumer supplies is the `<div class="mermaid-overlay" id="mermaid-zoom">` as the first child of `<body>`.

Each button takes its accessible name from that diagram's `accTitle:` — `Zoom diagram: Decision flow sample` — so a page with several diagrams gives several distinguishable buttons. That be one more reason the `accTitle:` obligation above be not optional: without it, every button on the page announces the same. To localise the label word, set `window.mermaidZoomLabel` in a classic script tag before `mermaid.js`, the same way `window.mermaidSecurityLevel` be set.

## Releases

1. Edit the stylesheet or Mermaid script. Colors change in the `tufte-dracula.css` `:root` block and nowhere else; if the color is one Mermaid needs, recompute its hex in `mermaid-palette.json` and `mermaid.js` (`nu maintain.nu check` tells ye which).
2. Run `nu build-sample.nu` to regenerate `tokens.css` and both fixtures.
3. Bump the version with `nu maintain.nu bump <version>`, which stamps `tufte-dracula.css`, this README, and regenerates. Write the version as `vX.Y.Z` wherever it appears in prose — `bump` rewrites the `v`-prefixed form, so a bare `X.Y.Z` in a doc example goes stale without anyone noticing.
4. Commit to a branch — never straight to `main` — with a conventional message (`feat: ...` / `fix: ...`).
5. Open a PR and let the `contract` check pass on it: `gh pr create --fill && gh pr checks --watch`, then `gh pr merge --squash`. The merge be what the required check actually gates.
6. From an updated `main`, run `nu maintain.nu release <version>`. It verifies `HEAD` be `origin/main`, refuses a version the stylesheet be not stamped with, waits for every check on that exact SHA, and writes an annotated tag only if all conclude `success`. A red check, a missing check, or a `HEAD` that never landed through the PR all abort before tagging.
7. Each consumer repo runs `git submodule update --remote external/dracula-tufte` and commits the new pointer.

**A required status check can only be satisfied by a pull request.** The check runs *after* a push, so `git push origin main` can never have satisfied it — GitHub takes the push and records `Bypassed rule violations`. Splitting the commit and tag into two pushes does not help; only the PR does. Consumers pin to tags, so a tag on a commit nothing gated hands every one of them an unverified payload. If a push ever reports a bypass, say so and revert rather than tagging on top of it.

## Contract Enforcement

The CI workflow `.github/workflows/contract-check.yml` verifies all eight files exist on every push and PR, that the `<style>` wrapper be exactly the first and last line (so `sed '1d;$d'` stays a safe slice), that `mermaid.js` still uses `theme: 'base'`, that every `themeVariables` hex in `mermaid.js` matches `mermaid-palette.json`, and that `tokens.css` and both fixtures are freshly regenerated. Consumers run their own contract gates that scan for any hand-rolled `<style>` blocks bypassing the submodule — those gates fail CI.

**One palette, several projections.** The `:root` block of `tufte-dracula.css` is the only source of color truth. Everything else is derived and machine-checked: `tokens.css` and the fixtures are sliced or inlined verbatim, and `.github/palette-check.py` converts each `oklch()` through Oklab to sRGB and asserts the hex in `mermaid-palette.json`, the hex inline in `mermaid.js`, and the `/* was #xxxxxx */` provenance comments all still agree. Run the whole set locally with `nu maintain.nu check`.

If ye find a violation in a consumer, fix the consumer to read from `external/dracula-tufte/`. Don't add a copy.

## License

MIT — see [LICENSE](./LICENSE).
