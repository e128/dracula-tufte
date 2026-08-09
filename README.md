# dracula-tufte

Arrr, gather 'round ye landlubbers — this here be the public contract for the **Tufte-Dracula** HTML conventions, hoist high as the single source of truth for the stylesheet, palette, Mermaid init, and sample fixtures.

This repo be the canonical home fer the nine artifacts that fer too long were scattered like spilled grog. Consumers pull this repo in through a pinned git submodule at `external/dracula-tufte/` — one place, one truth, no driftin'.

## Live Previews

Rendered in-browser via GitHub Pages (main branch, served straight — no build step):

- [sample.html](https://e128.github.io/dracula-tufte/sample.html) — component sample
- [sample-conn-map.html](https://e128.github.io/dracula-tufte/sample-conn-map.html) — connections-map layout

## The Nine Files

| File                  | What It Be |
|-----------------------|------------|
| `tufte-dracula.css`   | **The stylesheet payload.** The complete `<style>…</style>` block (template v1.20.0, oklch palette). Consumers inline this verbatim into every generated HTML file. Includes the wrapping `<style>` tags and 2-space leading indent — the exact byte sequence the renderer emits. |
| `mermaid.js`          | **The Mermaid init script.** The complete `<script type="module">…</script>` block — the `mermaid@11` CDN import, `theme: 'base'` + `darkMode` + hex `themeVariables` init, and the zoom overlay handler (injects a `<button class="mermaid-zoom">` per diagram; the overlay is a focus-managed `role="dialog"`). Despite the `.js` name it holds the wrapping `<script>` tags. Consumers inline this only when the rendered scroll contains a ` ```mermaid ` fence. Bump the CDN pin here. |
| `filter.js`          | **The filter-box script.** The complete `<script type="module">…</script>` block — wires each `input.filter-box` to the table it precedes, toggling `.filter-hidden` on non-matching `tbody tr` rows and revealing a `.filter-empty` line when nothing matches. No CDN, no build step, no comments (inlined verbatim). Consumers inline this only when a rendered scroll contains a filter box. |
| `mermaid-palette.json` | **Mermaid's hex palette.** The Tufte-Dracula palette as hex, per `themeVariables` key plus `classDef` node roles. Mermaid cannot consume `oklch()` (khroma throws `Unsupported color format` and *no* diagram renders) or `var()`, so this be the one place hex lives. Each entry names the `:root` variable it projects in its `from` field, and CI recomputes every hex from that variable's `oklch()` — hex here that disagrees with the stylesheet fails the build. `mermaid.js` carries the same values inline because consumers inline it with no build step; CI fails if the two disagree. Generators that emit their own `classDef` lines read the `classdef` block, whose fills draw only from the `--data-1..4` ramp (the prose accents `--pink`/`--green`/`--orange` already mean something in body copy). |
| `tokens.css`          | **Palette reference. Generated.** The `:root { … }` block of `tufte-dracula.css`, sliced out verbatim by `build-sample.nu`. Not read by the renderer. Do not hand-edit — change `tufte-dracula.css` and regenerate. |
| `build-sample.nu`     | **The regenerator.** Runs `nu build-sample.nu` to rebuild `tokens.css`, `sample.html` and `sample-conn-map.html` from the canonical CSS + JS. Run after any stylesheet or Mermaid change. |
| `sample.html`         | **Living style fixture.** Generated default-body demo — headings, sidenotes, tables, scorecard, verdict chips, nav, badges, mermaid + zoom. Self-contained. Do not hand-edit — regenerate via `build-sample.nu`. |
| `sample-conn-map.html` | **Conn-map fixture.** Generated `<body class="conn-map">` two-section layout (Links, Graph — that DOM order is required) — the connections-map split `sample.html` can't show inline. Resize past 900px to see Links go left+sticky. |
| `README.md`           | **This here scroll.** |

## Consumers

Consumers pin to a tag (currently **`v1.20.0`**) via a git submodule at `external/dracula-tufte/`. To refresh a consumer: bump the submodule pointer, run `git submodule update --remote external/dracula-tufte`, then commit the new pointer.

**Inline verbatim, or slice the body.** `tufte-dracula.css` ships wrapped in its own `<style>` tags for consumers that inline it whole. A consumer whose generator supplies the wrapper itself takes the bare body with `sed '1d;$d'` — the wrapper be exactly one line at each end, and CI holds it there, so the slice can't rot. Same for `mermaid.js` and `filter.js` and their `<script>` tags. Consumers needing the overlay CSS conditionally should note it ships in the stylesheet unconditionally (a dozen inert lines when no diagram be present); `mermaid.js` and the `<div class="mermaid-overlay" id="mermaid-zoom">` be the parts to omit, and the script throws a named error if the div be missing.

## What the Markup Must Supply

The stylesheet and script cannot fix markup they don't emit. A consumer's generator owes seven things, each modelled in `sample.html` / `sample-conn-map.html`:

- **`<main>` around the content**, so there be a primary landmark to jump to. `<article>` inside it keeps the sidenote counter and the conn-map layout selectors working.
- **A real `<label for>` on the filter input.** A placeholder be not a label — it announces as an unnamed field and vanishes on the first keystroke. The fixture uses `<label class="filter-label" for="nav-filter">` with `type="search"` and `autocomplete="off"`. **`filter.js` wires the behaviour**: it toggles `.filter-hidden` on the `tbody tr` rows of the table the input precedes and reveals a `.filter-empty` line when nothing matches, creating the element if the markup omits it. A consumer that emits its own `.filter-empty` also owes a `role="status"` region for the result count.
- **`accTitle:` and `accDescr:` inside every ` ```mermaid ` fence.** Mermaid renders the SVG as an unnamed `graphics-document` otherwise — a diagram carrying real structure with no text alternative. These be fence directives; no stylesheet change can supply them.
- **`scope="col"` on table headers**, and heading levels that nest (`h1` → `h2` → `h3`, no skips). For conn-map pages that means the Links section carries its own `<h2>`, since it now comes first in the DOM.
- **`role="list"` on every `<ul class="nav-list">`.** `.nav-list` sets `list-style: none`, and WebKit drops list semantics when it sees that — VoiceOver stops saying "list, N items" and stops giving item position, so a nav index becomes a run of loose links. Prose `<ul>` needs nothing: it keeps its markers, so it keeps its semantics.
- **`data-depth` on every row of a `<table class="tree">`**, counting from `0` at the root, and rows in document order so each child follows its parent. Depth be an author claim, not something the stylesheet can infer: the indent, the root tint and the `↳` come from that attribute alone. Levels `0`–`3` be styled; a deeper row renders flat rather than wrong. The table keeps its native semantics, so it still owes `scope="col"` like any other. It be **not** a `treegrid` — that role promises arrow-key navigation and `aria-expanded`, and neither ships here, so don't add the role.
- **`tabindex="0"` on anything that scrolls sideways**, with a `role="region"` and a label so the stop announces itself. `pre` be `overflow-x: auto`, and a table below 600px be its own scroll container, so a keyboard user cannot reach the overflowed content otherwise (WCAG 2.1.1). The fixture uses `<pre tabindex="0" role="region" aria-label="Code block">`; the label be a consumer string, so localise it.

**Two opt-in classes, both modelled in `sample.html`.** Neither be required; the stylesheet does nothing until the markup asks.

- **`.num` on a `th` and every `td` in the same column** right-aligns that column so figures line up under one another. Source Serif 4 be tabular and lining by construction, so the digits already share a width — the alignment be the missing half, and no `font-variant-numeric` be needed. Put it on the header too, or the header floats away from its own column.
- **`mark`, `kbd`, `caption`, `figure` and `figcaption` need no class**, but they be styled now where they were bare UA defaults before: `mark` took pure yellow with pure black text and now pins its own text colour, because the wash carries body copy and nothing dimmer, `caption` centred itself, `figcaption` read as an ordinary paragraph. A generator that emits highlights, shortcuts, table captions or figures gets the theme's own registers. A `caption` also drops the table's top hairline, so it reads as a label over the table rather than a first row.
- **`.indented` on a container** (a `<section>`, an `<article>`) switches its paragraphs from spaced to indented: `margin-block: 0` on every `p`, `text-indent: 1.5em` on every `p` after the first. Book setting rather than web setting. Default remains spaced paragraphs with no indent.

**A markdown converter's output be covered as of v1.20.0, and needs no classes of its own.** Point `cmark-gfm`, `pandoc` or `markdown-it` at the sheet and every construct lands in a theme register: `h4`–`h6`, fenced blocks, lists, tables, definition lists, footnotes, task lists, GFM alerts, `del`, `samp`, `abbr`, `sub` / `sup`. Four of those be worth knowing about:

- **GFM alerts** (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) take the `aside` form — one accent bar, no fill — with the hue on the bar and on `.markdown-alert-title` only. A converter that emits the GitHub class names gets this for free; one that emits its own wrapper gets nothing, so keep the `markdown-alert` / `markdown-alert-<type>` pair.
- **Pipe-table alignment** works through the `align` attribute `cmark-gfm` emits and the inline `text-align` `pandoc` emits. `.num` be still there for hand-authored markup and still right-aligns; a converter needs neither.
- **Syntax highlighting** be styled, not generated — the sheet paints `highlight.js` (`.hljs-*`), `pandoc`/skylighting (`.kw`, `.st`, `.co`, …) and Prism (`.token.*`) classes with the same slot map the editor themes use. Run the highlighter yourself; the sheet colours whatever it emits. Chroma's single-letter classes be not covered.
- **Footnotes** land in `section.footnotes` behind a hairline at the caption tier. The Tufte `.sidenote` apparatus be separate and still needs hand-authored markup.

**Below 600px a diagram be its own sideways scroll container.** `pre.mermaid` takes `overflow-x: auto` there and the SVG renders at natural size instead of being scaled down to a phone's width, where labels measured half the size of body copy. `mermaid.js` sets `tabindex="0"`, `role="region"` and an `aria-label` on each `pre.mermaid` when it injects the zoom button, so the stop be reachable and named the same way the fixture's `<pre>` code block be — the label comes from the fence's own `accTitle:`, falling back to the zoom label. That be one more reason `accTitle:` be not optional.

**`.verified` / `.unverified` / `.correction` carry meaning by colour alone.** Pair each with a word or a mark — the fixture's `verified` / `unverified` / `correction` text be the cue, not the hue. Under forced-colors all three resolve to the same foreground, and a colour-blind reader never had the distinction.

**Click-to-zoom needs no markup.** `mermaid.js` injects a real `<button class="mermaid-zoom">` under each diagram, which be the keyboard and touch path; the overlay is a `role="dialog"` that takes focus, inerts the rest of the body, and returns focus on Escape. It be `inert` while closed, so a page with no diagram open carries no dialog in the accessibility tree. The only thing a consumer supplies is the `<div class="mermaid-overlay" id="mermaid-zoom">` as the first child of `<body>`.

Each button takes its accessible name from that diagram's `accTitle:` — `Zoom diagram: Decision flow sample` — so a page with several diagrams gives several distinguishable buttons. That be one more reason the `accTitle:` obligation above be not optional: without it, every button on the page announces the same. To localise the label word, set `window.mermaidZoomLabel` in a classic script tag before `mermaid.js`, the same way `window.mermaidSecurityLevel` be set.

## Editor Themes

Beyond the nine, `themes/` projects the same `:root` palette into three editors. These be **not** part of the consumer contract — no submodule reads them — but they be generated and gated the same way, from a `.in` template beside each output:

| Theme | Files | Install |
|-------|-------|---------|
| **Rider** | `dracula-tufte.theme.json` (IDE chrome) + `dracula-tufte.icls` (editor scheme) | Settings → Plugins → gear → Install Plugin from Disk… → `themes/rider/dist/dracula-tufte-rider-<version>.zip` |
| **Zed** | `dracula-tufte.json` | Drop into `~/.config/zed/themes/` |
| **Ghostty** | `dracula-tufte` | Drop into `~/.config/ghostty/themes/`, then `theme = dracula-tufte` |

```sh
nu create-themes.nu           # write every theme, then package the Rider plugin
nu create-themes.nu --check   # fail if any output drifts from its template
```

Rider loads a UI theme only from a plugin, which be why there be an artifact to build at all. It ships as a zip wrapping a jar (`Dracula-Tufte/lib/*.jar`), because a **bare jar be refused by Install Plugin from Disk…** even though it loads fine when copied into `<config>/plugins/` by hand — the trap that shipped through v1.18.0. Delete any old `dracula-tufte-rider-*.jar` from yer plugins directory before installing the zip; two copies of one plugin ID be its own problem. `nu maintain.nu release` attaches the plugin and a themes zip to the GitHub release, so neither needs a clone.

**Prose weighting does not transfer to an editor.** The accents keep their jobs — pink be headings and keywords, purple be `h2` and types, green be inline `code` and strings, cyan be links and functions — but the *quiet* tiers do not carry over. In prose, colour be sparse and `--label` reads as restraint on a sidenote; an editor colours nearly every glyph, so the same token across punctuation, parameters and fields collapses a buffer into one blue-grey band. Punctuation therefore sits at `--on-surface`, parameters at `--orange`, and types at `--purple` lifted `L + 0.07`. See [Editor themes](NOTES.md#editor-themes) for the ratios and the three fuller slot maps that were rendered and rejected, and [`themes/rider/README.md`](themes/rider/README.md) for the whole mapping. **Do not answer "the theme looks washed out" by raising chroma in `:root`** — every ratio in the contrast budget be measured against those values, and they be inlined into every published page.

## Releases

1. Edit the stylesheet or Mermaid script. Colors change in the `tufte-dracula.css` `:root` block and nowhere else; if the color is one Mermaid needs, recompute its hex in `mermaid-palette.json` and `mermaid.js` (`nu maintain.nu check` tells ye which).
2. Run `nu build-sample.nu` to regenerate `tokens.css` and both fixtures.
3. Bump the version with `nu maintain.nu bump <version>`, which stamps `tufte-dracula.css`, this README, and regenerates. Write the version as `vX.Y.Z` wherever it appears in prose — `bump` rewrites the `v`-prefixed form, so a bare `X.Y.Z` in a doc example goes stale without anyone noticing.
4. Commit to a branch — never straight to `main` — with a conventional message (`feat: ...` / `fix: ...`).
5. Open a PR and let the `contract` check pass on it: `gh pr create --fill && gh pr checks --watch`, then `gh pr merge --squash`. The merge be what the required check actually gates.
6. From an updated `main`, run `nu maintain.nu release <version>`. It verifies `HEAD` be `origin/main`, refuses a version the stylesheet be not stamped with, waits for the required checks on that exact SHA — `REQUIRED_CHECKS` at the top of the verb, currently just `contract` — and writes an annotated tag only if every one concludes `success`. A red required check, a missing one, or a `HEAD` that never landed through the PR all abort before tagging. Every other check run on the commit be printed as `(advisory)` and gates nothing: GitHub attaches its own `pages-build-deployment` runs to the same SHA, and a Pages deploy that stalls on GitHub's side says naught about the payload.
7. Each consumer repo runs `git submodule update --remote external/dracula-tufte` and commits the new pointer.

**A required status check can only be satisfied by a pull request.** The check runs *after* a push, so `git push origin main` can never have satisfied it — GitHub takes the push and records `Bypassed rule violations`. Splitting the commit and tag into two pushes does not help; only the PR does. Consumers pin to tags, so a tag on a commit nothing gated hands every one of them an unverified payload. If a push ever reports a bypass, say so and revert rather than tagging on top of it.

## Contract Enforcement

The CI workflow `.github/workflows/contract-check.yml` verifies all nine files exist on every push and PR, that the `<style>` wrapper be exactly the first and last line (so `sed '1d;$d'` stays a safe slice), that `mermaid.js` still uses `theme: 'base'`, that every `themeVariables` hex in `mermaid.js` matches `mermaid-palette.json`, that the release gate still refuses a missing or red required check (`nu maintain.nu selftest`), and that `tokens.css`, both fixtures, every file under `themes/` and the Rider plugin zip are freshly regenerated (`nu create-themes.nu --check` — the zip freezes every entry timestamp to `1980-01-01` so a rebuild of unchanged inputs be byte-identical and a diff means a real change). Consumers run their own contract gates that scan for any hand-rolled `<style>` blocks bypassing the submodule — those gates fail CI.

**One palette, several projections.** The `:root` block of `tufte-dracula.css` is the only source of color truth. Everything else is derived and machine-checked: `tokens.css` and the fixtures are sliced or inlined verbatim, and `.github/palette-check.py` converts each `oklch()` through Oklab to sRGB and asserts the hex in `mermaid-palette.json`, the hex inline in `mermaid.js`, and the `/* was #xxxxxx */` provenance comments all still agree. Run the whole set locally with `nu maintain.nu check` — it mirrors the CI workflow step for step, including the `themeVariables` pairing gate that used to run only in CI, so a local pass and a CI pass now mean the same thing.

If ye find a violation in a consumer, fix the consumer to read from `external/dracula-tufte/`. Don't add a copy.

## License

MIT — see [LICENSE](./LICENSE).
