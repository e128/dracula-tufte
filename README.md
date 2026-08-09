# dracula-tufte

This repository holds the public contract for the **Tufte-Dracula** HTML conventions. It is the
single source of truth for the stylesheet, the palette, the Mermaid init script, and the sample
fixtures.

This repository is the canonical home for nine artifacts that were scattered across several
repos before. Consumers pull this repository in through a pinned git submodule at
`external/dracula-tufte/`. One place, one truth, no drift.

## Live Previews

GitHub Pages renders these in the browser, from the main branch, served directly with no build
step:

- [sample.html](https://e128.github.io/dracula-tufte/sample.html) — component sample
- [sample-conn-map.html](https://e128.github.io/dracula-tufte/sample-conn-map.html) — connections-map layout

## The Nine Files

| File                  | What it is |
|-----------------------|------------|
| `tufte-dracula.css`   | **The stylesheet payload.** The complete `<style>…</style>` block (template v1.21.0, oklch palette). Consumers inline this file verbatim into every generated HTML file. It includes the wrapping `<style>` tags and the 2-space leading indent. That is the exact byte sequence the renderer emits. |
| `mermaid.js`          | **The Mermaid init script.** The complete `<script type="module">…</script>` block. It holds the `mermaid@11` CDN import, the init call with `theme: 'base'`, `darkMode` and hex `themeVariables`, and the zoom overlay handler. The handler injects one `<button class="mermaid-zoom">` per diagram, and the overlay is a focus-managed `role="dialog"`. The name ends in `.js`, but the file holds the wrapping `<script>` tags. Consumers inline this file only when the rendered document contains a ` ```mermaid ` fence. Bump the CDN pin here. |
| `filter.js`          | **The filter-box script.** The complete `<script type="module">…</script>` block. It wires each `input.filter-box` to the table that the input precedes. It toggles `.filter-hidden` on non-matching `tbody tr` rows, and it reveals a `.filter-empty` line when nothing matches. No CDN, no build step, and no comments, because consumers inline it verbatim. Consumers inline this file only when the rendered document contains a filter box. |
| `mermaid-palette.json` | **Mermaid's hex palette.** The Tufte-Dracula palette as hex, per `themeVariables` key, plus `classDef` node roles. Mermaid cannot consume `oklch()` or `var()`: khroma throws `Unsupported color format` and *no* diagram renders. This file is therefore the one place that holds hex. Each entry names the `:root` variable it projects in its `from` field, and CI recomputes every hex from that variable's `oklch()`. A hex here that disagrees with the stylesheet fails the build. `mermaid.js` carries the same values inline, because consumers inline it with no build step, and CI fails when the two disagree. A generator that emits its own `classDef` lines reads the `classdef` block. Those fills draw only from the `--data-1` to `--data-4` ramp, because the prose accents `--pink`, `--green` and `--orange` already carry meaning in body copy. |
| `tokens.css`          | **Palette reference. Generated.** The `:root { … }` block of `tufte-dracula.css`, which `build-sample.nu` slices out verbatim. The renderer does not read it. Do not edit it by hand. Change `tufte-dracula.css` and regenerate. |
| `build-sample.nu`     | **The regenerator.** `nu build-sample.nu` rebuilds `tokens.css`, `sample.html` and `sample-conn-map.html` from the canonical CSS and JS. Run it after any stylesheet or Mermaid change. |
| `sample.html`         | **Living style fixture.** A generated default-body demo. It shows headings, sidenotes, tables, the scorecard, verdict chips, nav, badges, Mermaid with zoom, and the markdown-converter set: highlighted code, a task list, all five GFM alerts, an aligned pipe table, MathML and footnotes. It is self-contained. Do not edit it by hand. Regenerate it with `build-sample.nu`. |
| `sample-conn-map.html` | **Conn-map fixture.** A generated `<body class="conn-map">` two-section layout: Links, then Graph. That DOM order is required. It shows the connections-map split that `sample.html` cannot show inline. Resize past 900px to see Links move left and become sticky. |
| `README.md`           | **This file.** |

## Consumers

Consumers pin to a tag, currently **`v1.21.0`**, through a git submodule at
`external/dracula-tufte/`. To refresh a consumer: bump the submodule pointer, run
`git submodule update --remote external/dracula-tufte`, then commit the new pointer.

**Inline the file verbatim, or slice the body out.** `tufte-dracula.css` ships inside its own
`<style>` tags for a consumer that inlines it whole. A consumer whose generator supplies the
wrapper takes the bare body with `sed '1d;$d'`. The wrapper is exactly one line at each end, and
CI holds it there, so the slice cannot rot. `mermaid.js` and `filter.js` work the same way with
their `<script>` tags. A consumer cannot take the overlay CSS conditionally: the stylesheet
ships it unconditionally, which costs about a dozen inert lines when the page has no diagram.
Omit `mermaid.js` and the `<div class="mermaid-overlay" id="mermaid-zoom">` instead. The script
throws a named error when the div is missing.

## What the Markup Must Supply

The stylesheet and the script cannot fix markup that they do not emit. A consumer's generator
owes seven things, and `sample.html` and `sample-conn-map.html` model each one:

- **`<main>` around the content**, so the page has a primary landmark to jump to. Keep
  `<article>` inside it. The sidenote counter and the conn-map layout selectors depend on it.
- **A real `<label for>` on the filter input.** A placeholder is not a label: the field announces
  as unnamed, and the placeholder text disappears on the first keystroke. The fixture uses
  `<label class="filter-label" for="nav-filter">` with `type="search"` and `autocomplete="off"`.
  **`filter.js` supplies the behavior.** It toggles `.filter-hidden` on the `tbody tr` rows of
  the table that the input precedes. It reveals a `.filter-empty` line when nothing matches, and
  it creates that element when the markup omits it. A consumer that emits its own
  `.filter-empty` also owes a `role="status"` region for the result count.
- **`accTitle:` and `accDescr:` inside every ` ```mermaid ` fence.** Without them Mermaid renders
  the SVG as an unnamed `graphics-document`: a diagram that carries real structure with no text
  alternative. These are fence directives. No stylesheet change can supply them.
- **`scope="col"` on table headers**, and heading levels that nest: `h1`, then `h2`, then `h3`,
  with no skips. On a conn-map page the Links section carries its own `<h2>`, because Links now
  comes first in the DOM.
- **`role="list"` on every `<ul class="nav-list">`.** `.nav-list` sets `list-style: none`, and
  WebKit drops list semantics when it sees that. VoiceOver then stops saying "list, N items" and
  stops giving item position, so a nav index becomes a run of loose links. A prose `<ul>` needs
  nothing, because it keeps its markers and therefore keeps its semantics.
- **`data-depth` on every row of a `<table class="tree">`.** Count from `0` at the root. Put the
  rows in document order, so each child follows its parent. Depth is an author claim, and the
  stylesheet cannot infer it: the indent, the root tint and the `↳` come from that attribute
  alone. Levels `0` to `3` are styled, and a deeper row renders flat rather than wrong. The
  table keeps its native semantics, so it still owes `scope="col"` like any other table. It is
  **not** a `treegrid`. That role promises arrow-key navigation and `aria-expanded`, and this
  repo ships neither, so do not add the role.
- **`tabindex="0"` on anything that scrolls sideways**, with a `role="region"` and a label, so
  the tab stop announces itself. `pre` uses `overflow-x: auto`. A table below 1000px is its own
  scroll container. Since v1.21.0 a `<math display="block">` is one too. Without the attributes a
  keyboard user cannot reach the overflowed content (WCAG 2.1.1). The fixture uses
  `<pre tabindex="0" role="region" aria-label="Code block">`. The label is a consumer string, so
  translate it. A converter that emits math owes the same three attributes on any equation wide
  enough to clip, and no stylesheet can add them.

**Four opt-in patterns, plus one group that needs no class. `sample.html` models all but the
table wrapper.** Nothing here is required, and the stylesheet does nothing until the markup asks.

- **`.table-scroll` around a wide table** gives it a scroll container that keeps its header
  pinned. A table below 1000px already scrolls sideways on its own, but `display: block` makes
  the sticky header inert there, and neither scroll container is reachable by keyboard. The
  wrapper fixes both, and it needs the same three attributes any sideways scroller does:

  ```html
  <div class="table-scroll" tabindex="0" role="region" aria-label="Results by quarter">
    <table>…</table>
  </div>
  ```

  It scrolls both axes and caps its height at `70vh`, which is what keeps the header pinned. Put
  `role="region"` on the wrapper and **never on the `<table>`**, because that role overrides
  `role="table"` and takes the row and column semantics with it. The unwrapped path still works,
  so nothing breaks if you never adopt this.
- **`.sidenote` and `.marginnote`** put a note in the right margin instead of in the flow, which
  is the pattern the whole layout reserves that margin for. A `.sidenote` takes a numbered marker
  from `.sidenote-number`; a `.marginnote` takes none. Below 1000px both stack into the flow,
  because at 28% of a narrow page the note measures 19 to 25 characters per line. Use these for
  an aside that comments on one sentence, and use `<aside>` for one that comments on a section.

- **`.num` on a `th` and on every `td` in the same column** right-aligns that column, so the
  figures line up under one another. Source Serif 4 is tabular and lining by construction, so
  the digits already share a width. The alignment is the missing half, and `font-variant-numeric`
  is not needed. Put the class on the header too, or the header floats away from its own column.
- **`mark`, `kbd`, `caption`, `figure` and `figcaption` need no class**, but they now carry theme
  styles where they were bare UA defaults before. `mark` took pure yellow with pure black text,
  and it now pins its own text color, because the wash carries body copy and nothing dimmer.
  `caption` centered itself. `figcaption` read as an ordinary paragraph. A generator that emits
  highlights, shortcuts, table captions or figures now gets the theme's own registers. A
  `caption` also drops the table's top hairline, so it reads as a label over the table instead of
  a first row.
- **`.indented` on a container**, a `<section>` or an `<article>`, switches its paragraphs from
  spaced to indented. Every `p` takes `margin-block: 0`, and every `p` after the first takes
  `text-indent: 1.5em`. That is book setting rather than web setting. The default stays spaced
  paragraphs with no indent.

**The sheet covers a markdown converter's output as of v1.21.0, and that output needs no classes
of its own.** Point `cmark-gfm`, `pandoc` or `markdown-it` at the sheet, and every construct
lands in a theme register: `h4` to `h6`, fenced blocks, lists, tables, definition lists,
footnotes, task lists, GFM alerts, `del`, `samp`, `abbr`, `sub`, `sup`, and `img.emoji`, which
loses the figure ring and sizes to the line. Five of those are worth knowing about:

- **GFM alerts** (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) take the
  `aside` form: one accent bar, no fill. The hue lands on the bar and on `.markdown-alert-title`
  only. A converter that emits the GitHub class names gets this for free. A converter that emits
  its own wrapper gets nothing, so keep the `markdown-alert` and `markdown-alert-<type>` pair.
- **Pipe-table alignment** works through the `align` attribute that `cmark-gfm` emits and through
  the inline `text-align` that `pandoc` emits. `.num` still exists for hand-authored markup and
  still right-aligns, and a converter needs neither.
- **The sheet styles syntax highlighting. It does not generate it.** It paints `highlight.js`
  (`.hljs-*`), `pandoc` and skylighting (`.kw`, `.st`, `.co`, …), Prism (`.token.*`) and, as of
  v1.21.0, Pygments (`.k`, `.s`, `.nf`, `.kt`, …) with the same slot map the editor themes use.
  That last one covers Sphinx, MkDocs, Quarto and `nbconvert`, and it covers Hugo's Chroma too,
  which copies the Pygments class names. Run the highlighter yourself, and the sheet colors
  whatever the highlighter emits. Types take a `--purple-bright` token, which is `--purple`
  recomputed at `L + 0.07`, because plain purple on `--code-bg` measures 4.23 and misses 1.4.3.
  Print pins the token back, because the lift runs the wrong way on paper. Every Pygments rule is
  scoped under `:is(pre, code)`, because the names are one and two letters. One collision is
  known and accepted: `.ch` is `Char` to pandoc and `Comment.Hashbang` to Pygments, so a shebang
  renders in the string tier.
- **Footnotes** land in `section.footnotes` behind a hairline at the caption tier. The Tufte
  `.sidenote` apparatus is separate and still needs hand-authored markup.
- **The sheet styles math where it arrives as HTML, and renders none of it.** A converter that
  emits **MathML** (`pandoc --mathml`) needs no script and no CDN, because browsers lay MathML
  out natively. The sheet gives a `<math display="block">` its own sideways scroll axis and
  `pre`'s margin rhythm, so a wide equation cannot push the page sideways. A converter that
  leaves **TeX** as text hands you literal delimiters, whether the TeX is `$E = mc^2$` or a
  `<span class="math display">` that holds it. You then need KaTeX or MathJax, which means a
  pinned CDN and a hard-offline failure of Mermaid's kind, so it stays a consumer decision. The
  container styling is already here, so KaTeX drops in and inherits the block layout.

**Raw HTML is covered as of v1.21.0, and so are three shapes the GitHub path does not emit.**
Every converter passes raw HTML through untouched, and until v1.21.0 `img` was the only element
in the sheet with a width cap. Four changes, none of which need a class:

- **`svg`, `video`, `canvas`, `iframe`, `object` and `embed` take `max-width: 100%`.** A
  graphviz or plantuml SVG, a pre-rendered diagram, or an embed pasted into markdown pushed the
  whole document sideways at a phone width. A mermaid diagram is unaffected, because its own
  rules outrank this one where it needs to escape.
- **`body` takes `overflow-wrap: break-word`.** A hash, a long path or a base64 fragment outside
  a code span had no break opportunity and ran off the page.
- **A `tfoot` header cell no longer pins to the top.** `position: sticky` now scopes to
  `thead th`, so a totals row scrolls with its table. The `th` typography is unchanged, so a
  footer cell still reads as a header cell.
- **Python-Markdown footnotes get the caption tier.** The rule matches `div.footnote` as well as
  the `section.footnotes` that `cmark-gfm` and `pandoc` emit, and it drops the leading `<hr>`
  that Python-Markdown puts above the block, which would otherwise double the hairline.

**Form controls inherit the page font.** `button`, `input`, `select` and `textarea` do not
inherit it natively, so before v1.21.0 every control except the filter box rendered at 13.33px
Arial inside an 18.4px serif page, which is also below the 16px threshold where iOS Safari zooms
on focus. They now take `font: inherit` with a `1rem` floor. Their **appearance** is still the
UA's: no border, no fill, no focus ring of the theme's own. This is a document theme, and
`color-scheme: dark` already tells the UA to draw its widgets dark. If you need a styled button,
style it in your own sheet.

**A permalink anchor reveals on hover.** Sphinx, MkDocs and markdown-it-anchor emit
`a.headerlink` or `a.anchor` inside the heading. Those sit at `opacity: 0` until you hover the
heading, and they return at `opacity: 1` on keyboard focus, so the link is still reachable by
Tab. A converter that emits neither class name is unaffected.

**The sheet declares the dark UA furniture instead of inheriting it.** `:root` carries
`color-scheme: dark`, and the print block flips it to `light`. Scrollbars, form controls and the
UA focus ring therefore match the page, instead of dropping a light-mode widget onto a dark one.
One consequence is unavoidable. GFM emits task-list checkboxes as `disabled`, and Chromium
ignores `accent-color` on a disabled control, so a ticked box paints UA gray rather than
`--purple`. To draw it ourselves we would need an ungated literal hex in the sheet plus a
pseudo-element on an `input`, which WebKit does not honor. The box therefore stays native, and
either way it is sized to `1em` and spaced off its label.

**Below 600px a diagram is its own sideways scroll container.** `pre.mermaid` takes
`overflow-x: auto` there, and the SVG renders at natural size instead of scaling down to a
phone's width, where the labels measured half the size of body copy. `mermaid.js` sets
`tabindex="0"`, `role="region"` and an `aria-label` on each `pre.mermaid` when it injects the
zoom button. The tab stop is therefore reachable, and it is named the same way the fixture's
`<pre>` code block is named. The label comes from the fence's own `accTitle:`, and it falls back
to the zoom label. That is one more reason `accTitle:` is not optional.

**`.verified`, `.unverified` and `.correction` carry meaning by color alone.** Pair each one
with a word or a mark. The fixture's `verified`, `unverified` and `correction` text is the cue,
not the hue. Under forced-colors all three resolve to the same foreground, and a color-blind
reader never had the distinction.

**Click-to-zoom needs no markup.** `mermaid.js` injects a real `<button class="mermaid-zoom">`
under each diagram, which is the keyboard path and the touch path. The overlay is a
`role="dialog"`. It takes focus, it marks the rest of the body `inert`, and it returns focus on
Escape. The overlay itself is `inert` while closed, so a page with no open diagram carries no
dialog in the accessibility tree. The consumer supplies one thing: the
`<div class="mermaid-overlay" id="mermaid-zoom">` as the first child of `<body>`.

Each button takes its accessible name from that diagram's `accTitle:`, in the form
`Zoom diagram: Decision flow sample`, so a page with several diagrams gives several
distinguishable buttons. That is one more reason the `accTitle:` obligation above is not
optional. Without it, every button on the page announces the same name. To translate the label
word, set `window.mermaidZoomLabel` in a classic script tag before `mermaid.js`, the same way
you set `window.mermaidSecurityLevel`.

## Editor Themes

Beyond the nine files, `themes/` projects the same `:root` palette into three editors. These
files are **not** part of the consumer contract, because no submodule reads them. The repo
generates and gates them the same way, from a `.in` template beside each output:

| Theme | Files | Install |
|-------|-------|---------|
| **Rider** | `dracula-tufte.theme.json` (IDE chrome) + `dracula-tufte.icls` (editor scheme) | Settings → Plugins → gear → Install Plugin from Disk… → `themes/rider/dist/dracula-tufte-rider-<version>.zip` |
| **Zed** | `dracula-tufte.json` | Drop into `~/.config/zed/themes/` |
| **Ghostty** | `dracula-tufte` | Drop into `~/.config/ghostty/themes/`, then `theme = dracula-tufte` |

```sh
nu create-themes.nu           # write every theme, then package the Rider plugin
nu create-themes.nu --check   # fail if any output drifts from its template
```

Rider loads a UI theme only from a plugin, which is why there is an artifact to build at all. It
ships as a zip that wraps a jar (`Dracula-Tufte/lib/*.jar`), because **Install Plugin from Disk…
refuses a bare jar**, even though the same jar loads when you copy it into `<config>/plugins/` by
hand. That trap shipped through v1.18.0. Delete any old `dracula-tufte-rider-*.jar` from your
plugins directory before you install the zip, because two copies of one plugin ID is its own
problem. `nu maintain.nu release` attaches the plugin and a themes zip to the GitHub release, so
neither one needs a clone.

**Prose weighting does not transfer to an editor.** The accents keep their jobs: pink is
headings and keywords, purple is `h2` and types, green is inline `code` and strings, and cyan is
links and functions. The *quiet* tiers do not carry over. In prose the color is sparse, and
`--label` reads as restraint on a sidenote. An editor colors nearly every glyph, so the same
token across punctuation, parameters and fields collapses a buffer into one blue-gray band.
Punctuation therefore sits at `--on-surface`, parameters at `--orange`, and types at `--purple`
lifted `L + 0.07`. See [Editor themes](NOTES.md#editor-themes) for the ratios and for the three
fuller slot maps that were rendered and rejected, and see
[`themes/rider/README.md`](themes/rider/README.md) for the whole mapping. **Do not answer "the
theme looks washed out" by raising chroma in `:root`.** Every ratio in the contrast budget is
measured against those values, and those values go into every published page.

## Releases

1. Edit the stylesheet or the Mermaid script. Colors change in the `tufte-dracula.css` `:root`
   block and nowhere else. When Mermaid needs that color, recompute its hex in
   `mermaid-palette.json` and `mermaid.js`. `nu maintain.nu check` tells you which ones.
2. Run `nu build-sample.nu` to regenerate `tokens.css` and both fixtures.
3. Bump the version with `nu maintain.nu bump <version>`. It stamps `tufte-dracula.css` and this
   README, and it regenerates the fixtures. Write the version as `vX.Y.Z` wherever it appears in
   prose. `bump` rewrites only the `v`-prefixed form, so a bare `X.Y.Z` in a doc example goes
   stale without anyone noticing.
4. Commit to a branch, never straight to `main`, with a conventional message (`feat: ...` or
   `fix: ...`).
5. Open a pull request and let the `contract` check pass on it:
   `gh pr create --fill && gh pr checks --watch`, then `gh pr merge --squash`. The merge is what
   the required check gates.
6. From an updated `main`, run `nu maintain.nu release <version>`. It verifies that `HEAD` is
   `origin/main`. It refuses a version that the stylesheet does not carry. It waits for the
   required checks on that exact SHA, which `REQUIRED_CHECKS` at the top of the verb lists,
   currently just `contract`. It writes an annotated tag only when every one of them concludes
   `success`. A red required check, a missing one, or a `HEAD` that never landed through the
   pull request each abort the run before the tag. Every other check run on the commit prints as
   `(advisory)` and gates nothing: GitHub attaches its own `pages-build-deployment` runs to the
   same SHA, and a Pages deploy that stalls on GitHub's side says nothing about the payload.
7. Run `git submodule update --remote external/dracula-tufte` in each consumer repo, then commit
   the new pointer.

**Only a pull request can satisfy a required status check.** The check runs *after* a push, so
`git push origin main` can never satisfy it. GitHub takes the push and records `Bypassed rule
violations`. Two pushes, one for the commit and one for the tag, do not help. Only the pull
request does. Consumers pin to tags, so a tag on a commit that nothing gated hands every one of
them an unverified payload. When a push reports a bypass, say so and revert. Do not tag on top
of it.

## Contract Enforcement

The CI workflow `.github/workflows/contract-check.yml` runs on every push and pull request. It
verifies that all nine files exist. It verifies that the `<style>` wrapper is exactly the first
line and the last line, which keeps `sed '1d;$d'` a safe slice. It verifies that `mermaid.js`
still uses `theme: 'base'`. It verifies that every `themeVariables` hex in `mermaid.js` matches
`mermaid-palette.json`. It verifies that the release gate still refuses a missing or red required
check (`nu maintain.nu selftest`). It verifies that `tokens.css`, both fixtures, every file under
`themes/` and the Rider plugin zip are freshly regenerated (`nu create-themes.nu --check`). The
zip freezes every entry timestamp to `1980-01-01`, so a rebuild of unchanged inputs is
byte-identical and any diff means a real change. Consumers run their own contract gates, which
scan for hand-rolled `<style>` blocks that bypass the submodule. Those gates fail CI.

**One palette, several projections.** The `:root` block of `tufte-dracula.css` is the only source
of color truth. Everything else is derived and machine-checked. `tokens.css` and the fixtures are
sliced or inlined verbatim. `.github/palette-check.py` converts each `oklch()` through Oklab to
sRGB, then asserts that the hex in `mermaid-palette.json`, the hex inline in `mermaid.js`, and
the `/* was #xxxxxx */` provenance comments all still agree. Run the whole set locally with
`nu maintain.nu check`. It mirrors the CI workflow step for step, including the `themeVariables`
pairing gate that used to run only in CI, so a local pass and a CI pass now mean the same thing.

If you find a violation in a consumer, fix the consumer to read from `external/dracula-tufte/`.
Do not add a copy.

## License

MIT — see [LICENSE](./LICENSE).
