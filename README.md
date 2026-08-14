# dracula-tufte

**This repo is the single source of truth for the Tufte-Dracula HTML conventions.** It holds the
stylesheet, the palette, the Mermaid init script, and the sample fixtures. Consumers pull it in
through a pinned git submodule at `external/dracula-tufte/`. One place, one truth, no drift.

**A consumer's generator reads [CONTRACT.md](CONTRACT.md), not this file.** That one is the
imperative checklist: what to inline, what markup to emit, what changed in each release. This one
holds the narrative and the measurements behind it.

The typography adapts [tufte-css](https://edwardtufte.github.io/tufte-css/), the book style of
Edward Tufte. The palette comes from [Dracula](https://draculatheme.com/). This repo is not a
fork of either. It rewrites the ideas as one inline stylesheet with no build step.

## Live Previews

GitHub Pages renders these from main, no build step:

- [samples/dark.html](https://e128.github.io/dracula-tufte/samples/dark.html): component sample
- [samples/dark-conn-map.html](https://e128.github.io/dracula-tufte/samples/dark-conn-map.html): connections-map layout

Both follow your system appearance, so a dark-mode reader never sees the light palette. These two
force it, and are generated from the fixtures above by the same run:

- [samples/light.html](https://e128.github.io/dracula-tufte/samples/light.html): component sample, forced light
- [samples/light-conn-map.html](https://e128.github.io/dracula-tufte/samples/light-conn-map.html): connections-map layout, forced light

**Do not inline CSS from a preview.** The stylesheet inside those two has had its `@media`
conditions rewritten, so it is not the payload. Each one says so in a banner and links back to its
fixture. High-contrast mode has no preview page: it changes the accents, not `--surface`, so a
forced page would look nearly identical to the dark sample. CI renders it and attaches the image to
each pull request instead.

## The Ten Files

| File | What it is |
| --- | --- |
| `tufte-dracula.css` | The stylesheet payload (template v1.26.0, oklch palette). The complete `<style>…</style>` block, including the wrapping tags and the 2-space leading indent. Consumers inline it verbatim into every generated file. |
| `mermaid.js` | The Mermaid init script. The complete `<script type="module">…</script>` block: the `mermaid@11` CDN import, the init call (`theme: 'base'`, `darkMode`, hex `themeVariables`), and the zoom overlay handler. The handler injects one `<button class="mermaid-zoom">` per diagram. The overlay is a focus-managed `role="dialog"`. Inline only when the page has a mermaid fence. Bump the CDN pin here. |
| `filter.js` | The filter-box script. Wires each `input.filter-box` to the sibling span that follows it, stopping at the next filter box. Inside that span it toggles `.filter-hidden` on non-matching `tbody tr` rows and `.nav-list > li` items, hides a `details.nav-group` whose items all fail, and opens one that still matches. Reveals a `.filter-empty` line when nothing matches, and writes default copy into one it had to create. No CDN, no build step, no comments. Inline only when the page has a filter box. |
| `mermaid-palette.json` | Mermaid's hex palette, per `themeVariables` key, in two sections (`init` for dark and `initLight` for light) plus `classDef` node roles. Mermaid cannot read `oklch()` or `var()`: khroma throws `Unsupported color format` and no diagram renders. Each entry names its `:root` source in `from`. CI recomputes every hex, and `mermaid.js` carries the same values inline, with CI failing when the two disagree. |
| `tokens.css` | Palette reference. Generated. The `:root` block sliced out by `scripts/build-sample.nu`. Do not edit by hand. |
| `scripts/build-sample.nu` | The regenerator. `nu scripts/build-sample.nu` rebuilds `tokens.css` and both fixtures. Run it after any stylesheet or Mermaid change. |
| `samples/dark.html` | Living style fixture. Headings, sidenotes, tables, scorecard, verdict chips, nav, badges, Mermaid with zoom, and the markdown-converter set: highlighted code, a task list, all five GFM alerts, an aligned pipe table, MathML, footnotes. Generated. Do not edit by hand. |
| `samples/dark-conn-map.html` | Conn-map fixture. A `<body class="conn-map">` two-section layout: Links, then Graph. That DOM order is required. Past 900px, Links moves left and sticks. |
| `samples/dark-timeline.html` | Timeline fixture, and the only one built from real content. Twenty entries across four era groups on one pinned `--timeline-date` axis, with 54 `sup` citation markers into 15 sources and an `id` on every `dt`. The length is the point: a three-row demo shows the component but not the multi-group axis or the citation density. Generated. Do not edit by hand. |
| `CONTRACT.md` | The consumer checklist. What to inline, the markup a generator owes, what changed in each release, how to spot a stale artifact, and what each pin mode costs. Imperative and short, because a consumer's agent reads it on every bump. It carries no reasoning: `NOTES.md` holds that. |
| `README.md` | This file. |

**Where the rest lives.** The payload, the fixtures and the docs sit at the repo root, because Pages
serves the root and consumers pin paths into it. Everything else is split by who runs it:

| path | what | who runs it |
| --- | --- | --- |
| `scripts/*.nu` | `build-sample.nu`, `maintain.nu`, `create-themes.nu` | you, by hand, and CI |
| `.github/*.py` | `palette-check.py`, `render-modes.py` | CI steps, and the Nushell scripts above |
| `.github/workflows/` | `contract-check.yml`, the one workflow | GitHub |

The Python helpers stay in `.github/` because a CI step invokes each of them directly. The Nushell
scripts are the commands a person types, so they get a folder with a name that says so. Both resolve
every path from the repo root rather than from `cwd`, so `nu scripts/maintain.nu check` works from
anywhere in the tree.

## Consumers

The current release is **`v1.26.0`**. Consumers reach it through a git submodule. To refresh: bump
the pointer, run `git submodule update --remote external/dracula-tufte`, then commit the pointer.

**Three pin modes are in use, and they are not equal.** A tag is the only pin that makes a
generated artifact reproducible, because a tag is written only after CI passes on that exact
commit. Tracking `main` is fresh and still CI-gated, but two generations from one source can
differ. A live read of a working tree is not reproducible at all: an uncommitted edit reaches a
generated artifact with nothing recording it, which is how a page comes to carry a stylesheet
version that no release ever contained. [CONTRACT.md](CONTRACT.md) states the trade for each mode.

**Keep the markdown source.** A generator that deletes its source after converting cannot
regenerate, so it can never adopt an improvement from a later release. Repairing generated HTML in
place is a much harder problem than running the generator again.

**Inline the file verbatim, or slice the body out.** `tufte-dracula.css` ships inside its own
`<style>` tags. A consumer whose generator supplies the wrapper takes the bare body with
`sed '1d;$d'`. The wrapper is exactly one line at each end, and CI holds it there. `mermaid.js`
and `filter.js` work the same way with their `<script>` tags.

**Your own CSS now wins without a specificity fight.** The whole sheet sits in
`@layer tufte-dracula` as of v1.24.0. Unlayered author styles beat layered ones for normal
declarations, so a plain `h1 { color: … }` in your own `<style>` overrides the template no matter
how weak the selector looks. Load your CSS in any order. The six `!important` declarations in the
sheet go the other way, because layered `!important` beats unlayered `!important`, so if you have to win
against one of those, put your rules in a layer declared ahead of `tufte-dracula`. All six exist to
beat Mermaid's inline styles or to keep a filtered row hidden.

**Three appearance modes ship, and you supply nothing for any of them.** Dark is the default.
`prefers-contrast: more` raises every accent to 7:1 against the code fill. `prefers-color-scheme:
light` swaps in a full light palette where every accent clears 4.5:1 on both backgrounds. **Mermaid
diagrams follow the light palette too.** `mermaid.js` has to pass hex, because Mermaid's color engine
throws on `oklch()`, so it carries both palettes inline and picks one at init by reading the
`--mermaid-scheme` token off `:root`. That is the cascade, not `matchMedia`, which is what makes a
forced-light page render a light diagram. The token is read once at load, so a reader who changes
system appearance with the page open sees a stale diagram until they reload.

**The overlay CSS ships unconditionally.** A page with no diagram pays about a dozen inert lines.
Omit `mermaid.js` and the `<div class="mermaid-overlay" id="mermaid-zoom">` instead. The script
throws a named error when the div is missing.

## What the Markup Must Supply

The stylesheet and the script cannot fix markup they do not emit. A consumer's generator owes
seven things, and both fixtures model each one.

- **`<main>` around the content.** A primary landmark to jump to. Keep `<article>` inside it. The
  sidenote counter and the conn-map selectors depend on it.
- **A real `<label for>` on the filter input.** A placeholder is not a label: the field announces
  as unnamed, and the placeholder disappears on the first keystroke. The fixture uses
  `<label class="filter-label" for="nav-filter">` with `type="search"` and `autocomplete="off"`.
  `filter.js` supplies the behavior, over the `tbody tr` rows and `.nav-list > li` items that
  follow the input. A consumer that emits its own `.filter-empty` also owes a `role="status"`
  region for the result count.
- **`accTitle:` and `accDescr:` inside every mermaid fence.** Without them the SVG is an unnamed
  `graphics-document`: real structure with no text alternative. These are fence directives. No
  stylesheet change can supply them.
- **`scope="col"` on table headers**, and heading levels that nest: `h1`, then `h2`, then `h3`,
  no skips. On a conn-map page the Links section carries its own `<h2>`.
- **`role="list"` on every `<ul class="nav-list">`.** `.nav-list` sets `list-style: none`, and
  WebKit drops list semantics when it sees that. VoiceOver then stops saying "list, N items" and
  stops giving item position. A prose `<ul>` needs nothing, because it keeps its markers and
  therefore its semantics.
- **`data-depth` on every row of a `<table class="tree">`.** Count from `0` at the root, rows in
  document order. Depth is an author claim: the indent, the root tint and the `↳` come from that
  attribute alone. Levels `0` to `3` are styled; deeper renders flat. It still owes
  `scope="col"`. It is **not** a `treegrid`: that role promises arrow-key navigation and
  `aria-expanded`, and this repo ships neither.
- **`tabindex="0"` on anything that scrolls sideways**, with `role="region"` and a label, so the
  tab stop announces itself. `pre` uses `overflow-x: auto`. A table below 1000px is its own
  scroll container. Since v1.21.0 a `<math display="block">` is one too. Without the attributes a
  keyboard user cannot reach the overflowed content (WCAG 2.1.1). The fixture uses
  `<pre tabindex="0" role="region" aria-label="Code block">`. The label is a consumer string, so
  translate it.

**Four opt-in patterns, plus one group that needs no class. `samples/dark.html` models all but the
table wrapper.** Nothing here is required. The stylesheet does nothing until the markup asks.

- **`.table-scroll` around a wide table** keeps its header pinned. A table below 1000px already
  scrolls sideways on its own, but `display: block` makes the sticky header inert there, and
  neither scroll container is reachable by keyboard. The wrapper fixes both, and it needs the
  same three attributes any sideways scroller does:

  ```html
  <div class="table-scroll" tabindex="0" role="region" aria-label="Results by quarter">
    <table>…</table>
  </div>
  ```

  It scrolls both axes and caps its height at `70vh`, which is what keeps the header pinned. Put
  `role="region"` on the wrapper and **never on the `<table>`**: that role overrides
  `role="table"` and takes the row and column semantics with it. The unwrapped path still works,
  so nothing breaks if you never adopt this.
- **`.sidenote` and `.marginnote`** put a note in the right margin, the pattern the layout
  reserves that margin for. `.sidenote` takes a numbered marker from `.sidenote-number`;
  `.marginnote` takes none. Below 1000px both stack into the flow, because at 28% of a narrow
  page the note measures 19 to 25 characters per line. Use these for an aside that comments on
  one sentence, and `<aside>` for one that comments on a section.
- **`.num` on a `th` and on every `td` in the same column** right-aligns that column. Source
  Serif 4 is tabular and lining by construction, so the digits already share a width. Alignment
  is the missing half; `font-variant-numeric` is not needed. Put the class on the header too, or
  the header floats away from its own column.
- **`dl.timeline` on a `dl`** sets a dated list as a two-column spine: the `dt` right-aligned on
  tabular figures in its own track, the `dd` beside it behind a hairline. Both sit at body tier,
  because a dated event is content rather than annotation, which is the one thing an `h3` date line
  cannot express. Below 600px it collapses to one column and drops the rule. A page with more than
  one of these lists, era groups being the usual reason, must set `--timeline-date` on an ancestor
  in `ch`, or each list sizes its own date track and the axis steps left as the reader scrolls.
  Cite an entry with a `sup` link into a numbered source list: a floated `.sidenote` cannot escape
  a grid item. An `id` on the `dt` makes the entry deep-linkable, and the destination then takes an
  orange arrival outline, distinct from the link-blue focus ring.
- **`.indented` on a container** switches its paragraphs from spaced to indented. Every `p` takes
  `margin-block: 0`; every `p` after the first takes `text-indent: 1.5em`. Book setting rather
  than web setting. The default stays spaced.

**`mark`, `kbd`, `caption`, `figure` and `figcaption` need no class.** They carry theme styles
where they were bare UA defaults. `mark` took pure yellow with pure black text, and it now pins
its own text color, because the wash carries body copy and nothing dimmer. `caption` centered
itself. `figcaption` read as an ordinary paragraph. A `caption` also drops the table's top
hairline, so it reads as a label over the table instead of a first row.

**The sheet covers a markdown converter's output as of v1.21.0, and that output needs no classes
of its own.** Point `cmark-gfm`, `pandoc` or `markdown-it` at the sheet, and every construct
lands in a theme register: `h4` to `h6`, fenced blocks, lists, tables, definition lists,
footnotes, task lists, GFM alerts, `del`, `samp`, `abbr`, `sub`, `sup`, `img.emoji`. Five are
worth knowing about:

- **GFM alerts** (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) take the
  `aside` form: one accent bar, no fill. The hue lands on the bar and on `.markdown-alert-title`
  only. A converter that emits the GitHub class names gets this for free. A converter that emits
  its own wrapper gets nothing, so keep the `markdown-alert` and `markdown-alert-<type>` pair.
- **Pipe-table alignment** works through the `align` attribute `cmark-gfm` emits and the inline
  `text-align` `pandoc` emits. `.num` still exists for hand-authored markup. A converter needs
  neither.
- **The sheet styles syntax highlighting. It does not generate it.** It paints `highlight.js`
  (`.hljs-*`), pandoc and skylighting (`.kw`, `.st`, `.co`, …), Prism (`.token.*`) and, as of
  v1.21.0, Pygments (`.k`, `.s`, `.nf`, `.kt`, …) with the same slot map the editor themes use.
  That covers Sphinx, MkDocs, Quarto, `nbconvert`, and Hugo's Chroma, which copies the Pygments
  class names. Run the highlighter yourself; the sheet colors what it emits. Types take a
  `--purple-bright` token, `--purple` recomputed at `L + 0.07`, because plain purple on
  `--code-bg` measures 4.23 and misses 1.4.3. Print pins the token back, because the lift runs
  the wrong way on paper. Every Pygments rule is scoped under `:is(pre, code)`, because the
  names are one and two letters. One collision is known and accepted: `.ch` is `Char` to pandoc
  and `Comment.Hashbang` to Pygments, so a shebang renders in the string tier.
- **Footnotes** land in `section.footnotes` behind a hairline at the caption tier. The Tufte
  `.sidenote` apparatus is separate and still needs hand-authored markup.
- **The sheet styles math where it arrives as HTML, and renders none of it.** A converter that
  emits **MathML** (`pandoc --mathml`) needs no script and no CDN, because browsers lay MathML
  out natively. The sheet gives a `<math display="block">` its own sideways scroll axis and
  `pre`'s margin rhythm, so a wide equation cannot push the page sideways. A converter that
  leaves **TeX** as text hands you literal delimiters. You then need KaTeX or MathJax: a pinned
  CDN and a hard-offline failure of Mermaid's kind, so it stays a consumer decision. The
  container styling is already here, so KaTeX drops in and inherits the block layout.

**Raw HTML is covered as of v1.21.0, plus three shapes the GitHub path does not emit.** Every
converter passes raw HTML through untouched, and until v1.21.0 `img` was the only element with a
width cap. Four changes, none of which need a class:

- **`svg`, `video`, `canvas`, `iframe`, `object` and `embed` take `max-width: 100%`.** A
  graphviz or plantuml SVG, a pre-rendered diagram, or an embed pasted into markdown pushed the
  whole document sideways at a phone width. A mermaid diagram is unaffected, because its own
  rules outrank this one where it needs to escape.
- **`body` takes `overflow-wrap: break-word`.** A hash, a long path or a base64 fragment outside
  a code span had no break opportunity and ran off the page.
- **A `tfoot` header cell no longer pins to the top.** `position: sticky` now scopes to
  `thead th`, so a totals row scrolls with its table. The `th` typography is unchanged.
- **Python-Markdown footnotes get the caption tier.** The rule matches `div.footnote` as well as
  the `section.footnotes` that `cmark-gfm` and `pandoc` emit, and it drops the leading `<hr>`
  that would otherwise double the hairline.

**Form controls inherit the page font.** `button`, `input`, `select` and `textarea` do not
inherit it natively, so before v1.21.0 every control except the filter box rendered at 13.33px
Arial inside an 18.4px serif page, below the 16px threshold where iOS Safari zooms on focus.
They now take `font: inherit` with a `1rem` floor. Their **appearance** is still the UA's: no
border, no fill, no focus ring of the theme's own. This is a document theme, and
`color-scheme: dark` already tells the UA to draw its widgets dark. Style a button yourself in
your own sheet if you need one.

**A permalink anchor reveals on hover.** Sphinx, MkDocs and markdown-it-anchor emit
`a.headerlink` or `a.anchor` inside the heading. Those sit at `opacity: 0` until you hover the
heading, and they return on keyboard focus, so the link stays reachable by Tab. A converter that
emits neither class is unaffected.

**The sheet declares the dark UA furniture instead of inheriting it.** `:root` carries
`color-scheme: dark`; print flips it to `light`. Scrollbars, form controls and the UA focus ring
therefore match the page. One consequence is unavoidable. GFM emits task-list checkboxes as
`disabled`, and Chromium ignores `accent-color` on a disabled control, so a ticked box paints UA
gray rather than `--purple`. Drawing it ourselves needs an ungated literal hex plus a
pseudo-element on an `input`, which WebKit does not honor. The box stays native, sized to `1em`
and spaced off its label.

**Below 600px a diagram is its own sideways scroll container.** `pre.mermaid` takes
`overflow-x: auto` there, and the SVG renders at natural size instead of scaling to a phone's
width, where the labels measured half the size of body copy. `mermaid.js` sets `tabindex="0"`,
`role="region"` and an `aria-label` on each `pre.mermaid` when it injects the zoom button. The
label comes from the fence's own `accTitle:`, and it falls back to the zoom label. One more
reason `accTitle:` is not optional.

**`.verified`, `.unverified` and `.correction` carry meaning by color alone.** Pair each one
with a word or a mark. The fixture's text is the cue, not the hue. Under forced-colors all three
resolve to the same foreground, and a color-blind reader never had the distinction.

**Click-to-zoom needs no markup.** `mermaid.js` injects a real `<button class="mermaid-zoom">`
under each diagram: the keyboard path and the touch path. The overlay is a `role="dialog"`. It
takes focus, marks the rest of the body `inert`, and returns focus on Escape. While closed it is
`inert`, so a page with no open diagram carries no dialog in the accessibility tree. The consumer
supplies one thing: the `<div class="mermaid-overlay" id="mermaid-zoom">` as the first child of
`<body>`.

Each button takes its name from that diagram's `accTitle:`, in the form
`Zoom diagram: Decision flow sample`, so a page with several diagrams gives several
distinguishable buttons. Without it, every button announces the same name. To translate the label
word, set `window.mermaidZoomLabel` in a classic script tag before `mermaid.js`, the same way
you set `window.mermaidSecurityLevel`.

## Editor Themes

Beyond the ten files, `themes/` projects the same `:root` palette into three editors. These
files are **not** part of the consumer contract, because no submodule reads them. The repo
generates and gates them from a `.in` template beside each output:

| Theme | Files | Install |
| --- | --- | --- |
| **Rider** | `dracula-tufte.theme.json` (IDE chrome) + `dracula-tufte.icls` (editor scheme) | Settings → Plugins → gear → Install Plugin from Disk… → `themes/rider/dist/dracula-tufte-rider-<version>.zip` |
| **Zed** | `dracula-tufte.json` | Drop into `~/.config/zed/themes/` |
| **Ghostty** | `dracula-tufte` | Drop into `~/.config/ghostty/themes/`, then `theme = dracula-tufte` |

```sh
nu scripts/create-themes.nu           # write every theme, then package the Rider plugin
nu scripts/create-themes.nu --check   # fail if any output drifts from its template
```

**Rider loads a UI theme only from a plugin, which is why there is an artifact to build at all.**
It ships as a zip that wraps a jar (`Dracula-Tufte/lib/*.jar`), because Install Plugin from
Disk… refuses a bare jar, even though the same jar loads when you copy it into
`<config>/plugins/` by hand. That trap shipped through v1.18.0. Delete any old
`dracula-tufte-rider-*.jar` from your plugins directory before you install the zip: two copies of
one plugin ID is its own problem. `nu scripts/maintain.nu release` attaches the plugin and a themes zip
to the GitHub release, so neither needs a clone.

**Prose weighting does not transfer to an editor.** The accents keep their jobs: pink is
headings and keywords, purple is `h2` and types, green is inline `code` and strings, cyan is
links and functions. The *quiet* tiers do not carry over. In prose the color is sparse, and
`--label` reads as restraint on a sidenote. An editor colors nearly every glyph, so the same
token across punctuation, parameters and fields collapses a buffer into one blue-gray band.
Punctuation sits at `--on-surface`, parameters at `--orange`, and types at `--purple` lifted
`L + 0.07`. See [Editor themes](NOTES.md#editor-themes) for the ratios and the three fuller slot
maps that were rendered and rejected, and [`themes/rider/README.md`](themes/rider/README.md) for
the whole mapping. **Do not answer "the theme looks washed out" by raising chroma in `:root`.**
Every ratio in the contrast budget is measured against those values, and those values go into
every published page.

## Releases

1. Edit the stylesheet or the Mermaid script. Colors change in the `tufte-dracula.css` `:root`
   block and nowhere else. When Mermaid needs that color, recompute its hex in
   `mermaid-palette.json` and `mermaid.js`. `nu scripts/maintain.nu check` tells you which ones.
2. Run `nu scripts/build-sample.nu` to regenerate `tokens.css` and both fixtures.
3. Bump the version with `nu scripts/maintain.nu bump <version>`. It stamps `tufte-dracula.css` and this
   README, and it regenerates the fixtures. Write the version as `vX.Y.Z` wherever it appears in
   prose. `bump` rewrites only the `v`-prefixed form, so a bare `X.Y.Z` in a doc example goes
   stale without anyone noticing.
4. Commit to a branch, never straight to `main`, with a conventional message (`feat: ...` or
   `fix: ...`).
5. Open a pull request and let the `contract` check pass on it:
   `gh pr create --fill && gh pr checks --watch`, then `gh pr merge --squash`. The merge is what
   the required check gates.
6. From an updated `main`, run `nu scripts/maintain.nu release <version>`. It verifies that `HEAD` is
   `origin/main`. It refuses a version the stylesheet does not carry. It waits for the required
   checks on that exact SHA, which `REQUIRED_CHECKS` at the top of the verb lists, currently just
   `contract`. It writes an annotated tag only when every one concludes `success`. A red required
   check, a missing one, or a `HEAD` that never landed through the pull request each abort the
   run before the tag. Every other check run on the commit prints as `(advisory)` and gates
   nothing: GitHub attaches its own `pages-build-deployment` runs to the same SHA, and a Pages
   deploy that stalls on GitHub's side says nothing about the payload.
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
verifies that all ten files exist. It verifies the `<style>` wrapper is exactly the first line
and the last line, which keeps `sed '1d;$d'` a safe slice. It verifies `mermaid.js` still uses
`theme: 'base'`. It verifies every `themeVariables` hex in `mermaid.js` matches
`mermaid-palette.json`. It verifies the release gate still refuses a missing or red required
check (`nu scripts/maintain.nu selftest`). It verifies that `tokens.css`, both fixtures, every file under
`themes/` and the Rider plugin zip are freshly regenerated (`nu scripts/create-themes.nu --check`). The
zip freezes every entry timestamp to `1980-01-01`, so a rebuild of unchanged inputs is
byte-identical and any diff means a real change. Consumers run their own contract gates, which
scan for hand-rolled `<style>` blocks that bypass the submodule. Those gates fail CI.

**One palette, several projections.** The `:root` block of `tufte-dracula.css` is the only source
of color truth. Everything else is derived and machine-checked. `tokens.css` and the fixtures are
sliced or inlined verbatim. `.github/palette-check.py` converts each `oklch()` through Oklab to
sRGB, then asserts that the hex in `mermaid-palette.json`, the hex inline in `mermaid.js`, the
dark palette re-declared on `pre.mermaid` for light mode, and the `/* was #xxxxxx */` provenance
comments all still agree. It also re-derives the contrast floor for all four palettes (the
default at 4.2:1, `prefers-contrast: more` at 7:1, light at 4.5:1, print at 4.5:1) because those
ratios were hand measurements in `NOTES.md` and prose is not a gate.

**Every appearance mode is rendered, not just parsed.** `.github/render-modes.py` opens each
fixture in each mode and asserts the page paints that mode's `--surface`. Headless Chrome cannot
be told which media query to match, because it reads `prefers-color-scheme` from the host, so the script
rewrites the mode's `@media` condition in a scratch copy and checks the real fixture separately
for the condition's presence. The images upload as a pull-request artifact for review, and they
are advisory: the assertions are the gate. Run the whole set locally with
`nu scripts/maintain.nu check`. It mirrors the CI workflow step for step, including the `themeVariables`
pairing gate that used to run only in CI, so a local pass and a CI pass now mean the same thing.

If you find a violation in a consumer, fix the consumer to read from `external/dracula-tufte/`.
Do not add a copy.

## License

MIT, see [LICENSE](./LICENSE).
