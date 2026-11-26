# CONTRACT.md: what a consumer's generator must emit

This file is for the agent or the script that generates HTML in a **consumer** repository. It
states what to inline, what markup to emit, and what changed in each release. It carries no
reasoning. [NOTES.md](NOTES.md) holds the decisions and the prohibitions behind these rules, and
[README.md](README.md) orients a person arriving for the first time.

**The fixtures are the executable specification.** CI fails when they drift from the stylesheet, so
when this file and a fixture disagree about markup, the fixture is right. Read it before you invent
any.

Two limits on that, and both are stated where they apply rather than left for you to discover.
**Most requirements below are modelled in `samples/dark.html`, six only in
`samples/dark-timeline.html`, seven only in `samples/dark-charts.html`, and four that no fixture
demonstrates**, which each of those four says in its own bullet.
**One requirement the fixture deliberately breaks:** its `quadrantChart` carries
two overlong point labels on purpose, as the stress case for a stylesheet rule that has to survive
them. That bullet is the one place to follow this file and not the fixture, and it says so.

## 1. Inline the payload

Four files. Each one carries its own wrapper tag.

| file | when | wrapper |
| --- | --- | --- |
| `tufte-dracula.css` | always | `<style>` |
| `mermaid.js` | only when the document holds a ` ```mermaid ` fence | `<script type="module">` |
| `filter.js` | only when the document holds an `input.filter-box` | `<script type="module">` |
| `highlight.js` | only when the document holds a `pre > code` whose class starts `language-` | `<script type="module">` |

Two supported modes. Pick one and hold it:

- **Verbatim.** Copy the whole file. The wrapper comes with it. Do not add a second wrapper.
- **Sliced.** Take the body with `sed '1d;$d'` and supply your own wrapper. The wrapper is exactly
  one line at each end, and CI holds it there, so the slice cannot rot.

`mermaid.js` needs `<dialog class="mermaid-overlay" id="mermaid-zoom"></dialog>` as the first
child of `<body>`. It throws a named error when the dialog is absent. **Emit the dialog only on a
page that also inlines `mermaid.js`.** A page with no ` ```mermaid ` fence needs neither; a dialog
with no script to open it is dead markup.

**Take the CSS from `tufte-dracula.css`, never from a page.** `samples/light.html`,
`samples/light-conn-map.html`, `samples/light-timeline.html` and `samples/light-charts.html` exist
so a reader can see the light palette on a dark-mode machine. They carry a stylesheet whose
`@media` conditions were rewritten to force that, so a copy taken from one of them is locked to
light and can never follow a reader's system appearance. Each says so in a banner.
`samples/christmas-dark.html`, `samples/christmas-light.html`, `samples/thanksgiving-dark.html`,
`samples/thanksgiving-light.html`, `samples/chartreuse-dark.html`,
`samples/chartreuse-light.html`, `samples/st-patrick-dark.html`,
`samples/st-patrick-light.html`, `samples/independence-day-dark.html`,
`samples/independence-day-light.html`, `samples/poland-dark.html`,
`samples/poland-light.html`, `samples/bois-jacques-dark.html`,
`samples/bois-jacques-light.html`, `samples/aurora-dark.html`,
`samples/aurora-light.html`, `samples/birthday-dark.html`,
`samples/birthday-light.html`, `samples/oktoberfest-dark.html`,
`samples/oktoberfest-light.html`, `samples/halloween-dark.html` and
`samples/halloween-light.html` are the same kind of page for the
[seasonal theme](#seasonal-theme-optional): each pair forces one season for any date and any system
setting, so a copy taken from one of them is locked to that season. None is the payload.
`samples/dark.html`, `samples/dark-conn-map.html`, `samples/dark-timeline.html` and
`samples/dark-charts.html` do carry the payload verbatim, but the file is still the source.

**Do not inline a second `<style>` block that re-declares `:root` inside
`@media (prefers-color-scheme: light)`.** A generator that adds its own "force dark" block after
the payload's `<style>` wins the cascade on equal specificity, so the page never shows the light
palette regardless of the reader's OS setting, and `prefers-color-scheme` still reports correctly
in devtools while the rendered page stays dark. To force one scheme only, rewrite the payload's own
`@media` conditions before inlining it (the way `samples/light.html` does), never append an
overriding block. To respond to the reader's system setting, inline the payload once and add
nothing after it.

### Seasonal Theme (Optional)

`tufte-dracula.css` carries eleven seasonal palettes that stay off until `<html>` carries
`data-season`. The attribute value names the season: `"st-patrick"`, `"chartreuse"`,
`"independence-day"`, `"thanksgiving"`, `"christmas"`, `"poland"`, `"bois-jacques"`,
`"aurora"`, `"birthday"`, `"oktoberfest"` or `"halloween"`. The
stylesheet never sets that attribute. **A page turns a theme on by date only
after its generator adds the head snippet below.** Inlining a newer stylesheet into a page that has
no snippet changes nothing, so no consumer gets a season until it adds the snippet.

Emit the snippet as a classic inline `<script>`, before the `<style>` block and before every
`<script type="module">`:

```html
  <script>
    (function () {
      var now = new Date(), year = now.getFullYear(), month = now.getMonth(), day = now.getDate(), r;
      function nthWeekday(y, m, w, n) {
        var d = new Date(y, m, 1);
        return new Date(y, m, 1 + ((w - d.getDay() + 7) % 7) + (n - 1) * 7).getDate();
      }
      var ranges = [
        [4, 3, 4, 3, 'poland'],
        [7, 15, 7, 15, 'poland'],
        [10, 11, 10, 11, 'poland'],
        [11, 6, 11, 6, 'poland'],
        [0, 1, 0, 13, 'bois-jacques'],
        [0, 14, 1, 28, 'aurora'],
        [2, 1, 2, 17, 'st-patrick'],
        [4, 1, 4, 16, 'chartreuse'],
        [5, 28, 6, 4, 'independence-day'],
        [7, 25, 7, 27, 'birthday'],
        [8, 20, 9, 5, 'oktoberfest'],
        [9, 24, 9, 31, 'halloween'],
        [10, 1, 10, nthWeekday(year, 10, 4, 4), 'thanksgiving'],
        [10, nthWeekday(year, 10, 5, 4), 11, 28, 'christmas'],
        [11, 29, 11, 31, 'bois-jacques'],
      ];
      for (var i = 0; i < ranges.length; i++) {
        r = ranges[i];
        if ((month > r[0] || (month === r[0] && day >= r[1])) && (month < r[2] || (month === r[2] && day <= r[3]))) {
          document.documentElement.setAttribute('data-season', r[4]);
          break;
        }
      }
    })();
  </script>
```

- **Bois Jacques runs from December 29 through January 13, Aurora from January 14 through
  February 28, St Patrick from March 1 through March 17, Chartreuse from May 1 through May 16,
  Independence Day from June 28 through July 4, Birthday from August 25 through 27, Oktoberfest
  from September 20 through October 5, Halloween from October 24 through 31, Thanksgiving from
  November 1 through the fourth Thursday of November, and Christmas from the fourth Friday of
  November through December 28, all inclusive.** Poland ships four single
  days: May 3, August 15, November 11 and December 6.
  May 3, November 11 and December 6 fall inside Chartreuse, Thanksgiving and Christmas, and
  Poland's rows come first so they win those days. August 15 falls outside every base range, so
  it stands on its own. The remaining rows are the base calendar. Bois Jacques crosses the year
  boundary, so it is two rows of the same season: December 29 through 31 and January 1 through 13.
  The snippet compares months linearly, and January is an ordinary month in the visitor's current
  year. The fourth Thursday is Thanksgiving Day. `nthWeekday` resolves both Thursdays and Fridays
  in the visitor's own year, so the Thanksgiving and Christmas windows track the calendar.
  That also covers the years where November 1 is a Friday and the fourth Friday falls before the
  fourth Thursday: rows are checked in order and the first match wins, so Thanksgiving keeps those
  days and Christmas starts the day after its end. March 18 through April 30, May 17 through
  June 27, July 5 through August 24, August 28 through September 19, and October 6 through
  October 23 belong to no season. The
  snippet reads the visitor's local calendar once, at page load. A page left open past midnight
  keeps its theme until the next load. To change a window, edit that row in `ranges`. `getMonth()`
  counts from zero, so `0` is January, `4` is May, `7` is August, `8` is September, `9` is
  October, `10` is November and `11` is December, and
  `getDay()` counts from Sunday, so `4` is Thursday and `5` is Friday. A date in no row leaves the
  attribute off.
- **Keep the snippet classic and first.** `mermaid.js` reads `--mermaid-scheme` once, when its
  module evaluates. A classic inline script runs as the parser reaches it, so the attribute is on
  `<html>` before any module runs. A `type="module"`, `defer` or `async` snippet, or one placed
  after the payload scripts, can lose that race and draw diagrams in the standard palette on a
  seasonal page.
- **The theme yields to the reader.** It applies on the `screen` media type and only when the
  reader states no contrast preference, so high contrast and print keep their own palettes.
- **Omit the snippet to opt out.** To force a season on every date, write
  `data-season="st-patrick"`, `data-season="chartreuse"`, `data-season="independence-day"`,
  `data-season="thanksgiving"`, `data-season="christmas"`, `data-season="poland"`,
  `data-season="bois-jacques"`, `data-season="aurora"`, `data-season="birthday"`,
  `data-season="oktoberfest"` or `data-season="halloween"` on `<html>` and omit the snippet, which
  is how the season preview pages work. A page under a `script-src` policy needs a nonce or a hash
  for the snippet. A blocked snippet leaves the standard palette, with no error visible to the
  reader.
- **The fixtures carry the snippet.** All four dark fixtures include it (in `samples/dark.html`,
  search `document.documentElement.setAttribute('data-season'`), so each one turns seasonal inside
  a window and holds four `<script>` blocks instead of three. The four light previews carry no
  snippet and never show a season.

CI does not copy this block by eye. `.github/season-probe.py` extracts it from every fixture,
compares it with the one above, and runs it in a browser against a mocked clock.

### Adding a New Date-Range Palette

A season beyond the eleven shipped follows the same shape, and the mode names are a convention the
drift gate depends on: the attribute value is the season name, `--mermaid-scheme` takes `<season>` and
`light-<season>`, and `.github/palette-check.py` keys its `SEASONS` row by the season name. The
steps, in order:

1. Write two `:root[data-season="name"]` blocks in `tufte-dracula.css`, one under
   `@media screen and (prefers-contrast: no-preference)` and one under
   `@media screen and (prefers-color-scheme: light) and (prefers-contrast: no-preference)`.
   Each restates every token a block of that family changes, and each declares its own
   `--mermaid-scheme`. The dark block's colors must clear the dark floors and the light block's
   the light floors; `palette-check.py` re-derives both.
2. Add the `SEASONS` row in `.github/palette-check.py`: the token set, both floors, whether the
   ramp reaches P3, and whether the light variant joins the accent band. Everything else in that
   file derives from the row.
3. Add `init<Name>` and `init<Name>Light` sections to `mermaid-palette.json`, keyed by
   `themeVariables` name with a `from` field, and the two hex maps plus one `Map` insert in
   `mermaid.js`. `mermaidLight` tests `startsWith('light-')`, so a light season needs no edit
   there. `<Name>` capitalizes each hyphen-separated word of the season name (`christmas` becomes
   `Christmas`, `new-year` becomes `NewYear`).
4. No edit is needed to `.github/palette-check.py`'s expectations: both sections derive from the
   row. Run `palette-check.py` and fix whatever it measures.
5. Add the season's rows to `scripts/build-sample.nu`. A base range goes in `SEASON_RANGES`; a
   single day goes in `SEASON_OVERRIDES`, which is emitted before the base rows so it wins
   wherever it overlaps a base range. Either list emits the `<season>-dark.html` and
   `<season>-light.html` pair, sets the attribute in markup, rewrites the season conditions to
   `@media screen`, and derives the display name. Register both pages in `SEASON_PREVIEWS` in
   `scripts/maintain.nu` and add their date cases to `.github/season-probe.py`.
6. Every template-bearing theme target ships the season. Add `THEMES` rows with
   `scheme: "<season>"` for Rider (`.icls` and `theme.json`), VS Code, Ghostty, CotEditor,
   opencode and tmux, add the iTerm2 pair row, and add the season's theme object to Zed's one
   template with every placeholder prefixed `{{<season>:...}}`. Register the Rider
   `themeProvider`, the VS Code label and the `.vsix` entry list, and the Rider jar staging list.
   A target whose template carries no appearance name (CotEditor, opencode) reuses its dark
   template for the seasonal row. Rider also gets a second row per season for each of its two
   files, rendered with `scheme: "light-<season>"` from a `-light` template, and the matching
   `themeProvider` and jar entries. The render already resolves any `--dump` key as a prefix or as
   `scheme`.
7. Add the new season's windows and expectations to `CASES` in `.github/season-probe.py`. The probe
   drives the whole snippet, so its expectations stay literal and it catches a range that is off by
   one day.
8. Record the palette decision in `NOTES.md` under a season heading, as the Christmas entries
   do, and update `CONTRACT.md` § 1 with the head snippet a consumer pastes.

The date-window snippet itself is consumer code: a page pastes it with its own rows. Nothing in
the stylesheet or the payload scripts ever reads a date.

## 2. Emit this markup

Forty-three requirements. No stylesheet change can supply any of them. Most name a string to search
for in a fixture, so you have a working example instead of only a sentence. The few with no fixture
yet say so.

**The pointers are search strings, not line numbers, and that is deliberate.** Every fixture in
`samples/` is generated by `scripts/build-sample.nu`, so a line number goes stale on the next
regeneration with nothing to notice: all 22 of the line references this section used to carry were
wrong by v1.38.1, and every check stayed green. A search string survives regeneration, and
`nu scripts/maintain.nu check` fails when one of them stops matching the file it names.

- [ ] `<main>` around the content, with `<article>` inside it
      (in `samples/dark.html`, search `<article>`).
- [ ] A real `<label for>` on every `input.filter-box`. A placeholder is not a label
      (in `samples/dark.html`, search `class="filter-label"`). If you emit a `placeholder` at all,
      make it an **example** of what the box accepts, never an instruction: it restates the label it
      sits under, and it disappears on the first keystroke, so an instruction there teaches nothing
      and costs a line of chrome (in `samples/dark.html`, search `placeholder="Failed audit"`). The
      box also carries `autocomplete="off"`, `autocapitalize="off"`, `spellcheck="false"` and
      `enterkeyhint="search"` (in `samples/dark.html`, search `autocapitalize="off"`): a phone
      keyboard then offers a search key, does not capitalize the query, and does not spell-check a
      term that already matches an entry.
- [ ] `accTitle:` and `accDescr:` inside every ` ```mermaid ` fence
      (in `samples/dark.html`, search `accTitle: Decision flow sample`).
- [ ] `scope="col"` on table headers, and heading levels that nest with no skips
      (in `samples/dark.html`, search `scope="col"`).
- [ ] `role="list"` on every `<ul class="nav-list">` (in `samples/dark.html`, search
      `class="nav-list" role="list"`) and every `<ul class="icon-list">` (in `samples/dark.html`,
      search `class="icon-list" role="list"`). Both reset `list-style: none` on the
      `<ul>` itself, which drops native list semantics in WebKit.
- [ ] `data-depth` on every row of a `<table class="tree">`, counting from `0`, in document order
      (in `samples/dark.html`, search `<table class="tree" tabindex="0">`).
- [ ] `tabindex="0"` plus `role="region"` plus a label on anything that scrolls sideways: `pre`
      (in `samples/dark.html`, search `aria-label="Code block"`)
      and a `<math display="block">` (in `samples/dark.html`, search
      `<math display="block" tabindex="0" role="region"`), a pandoc `span.math.display` (in
      `samples/dark.html`, search `<span class="math display" tabindex="0" role="region"`), and any `.table-scroll` wrapper (in
      `samples/dark.html`, search `class="table-scroll"`). **Never put `role="region"` on the
      `<table>` itself.** It overrides `role="table"` and takes the row and column semantics with
      it. An unwrapped table takes `tabindex="0"` alone, named by its own `<caption>`
      (in `samples/dark.html`, search `<caption>Table caption: annotation register`), because the
      stylesheet hands it a sideways-scroll axis of its own below 1000px.
- [ ] A code block you want highlighted in the browser is `<pre><code class="language-NAME">` with
      the source as escaped text, and nothing else (in `samples/dark.html`, search
      `class="language-python"`). The `language-` class on a `code` inside a `pre` is the
      opt-in: `highlight.js` skips a `code` with no such class, never guesses a language, and
      skips a block that already carries `hljs` spans from a server-side highlighter (in
      `samples/dark.html`, search `class="language-csharp hljs"`). The block still takes the
      `tabindex`, `role` and label from the scroll requirement above. Name a language the pinned
      `highlight.js` common bundle ships. The script loads from a CDN, so an offline reader sees the
      same block as plain, readable code. Use no class of your own, and inline `highlight.js` only on
      a page that holds one. Put `translate="no"` on every `<pre>` and `<code>` you emit
      (in `samples/dark.html`, search `translate="no"`): Chrome's page translation otherwise
      rewrites identifiers inside the sample, so the code a reader sees stops matching the
      source.
- [ ] `--timeline-date` on an ancestor when a page carries **more than one** `dl.timeline`, set in
      `ch` against the widest date label in the whole document (in `samples/dark-timeline.html`,
      search `--timeline-date: 16ch`). Each
      list otherwise sizes its own date track and the axis steps left down the page. Measure the
      label: `tabular-nums` pins digits to exactly `1ch` while letters stay proportional, so a
      spelled-out `c. 6th century CE` is wider than a numeric `c. 1182-1201`. **Measure at weight
      500**, the weight `dt` renders at, and **round up to the next whole `ch`.** `ch` resolves
      against the element the variable is set on, which is weight 400, and 400 is about 1.7%
      narrower per character, so a value measured at 400 is short by a quarter character at 16ch.
      Too small a value has no CSS backstop: the label overflows into the column gap and touches
      the rule. One list needs nothing.
- [ ] Citations inside a `dl.timeline` entry as `sup` links into a numbered source list, never a
      `.sidenote` (in `samples/dark-timeline.html`, search `class="footnote-ref"`). A float cannot
      escape a grid item, so the note lands inside the entry column instead of the page margin.
      Give each `dt` an `id` to make an entry deep-linkable (in `samples/dark-timeline.html`,
      search `<dt id="`); the arrival outline is automatic once it has one.
- [ ] A timeline that covers more than one era or phase splits into one `<section>` per group,
      each opened by an `<h2>` that carries an `id`, and carries a page-level `<nav>` of
      `<a href="#that-id">` links to every group and to the `Sources` heading near the top
      (in `samples/dark-timeline.html`, search `href="#pre-angkor"`). A twenty-entry timeline
      behind no index is a wall: the reader cannot reach the century they want, and a screen
      reader hears one unbroken definition list. This is not `nav.toc`, which indexes a whole
      document by its headings, and a single-era timeline needs neither.
- [ ] The timeline's `Sources` is a numbered `<ol>` under a `<h2 id="sources">`, one
      `<li id="src-N">` per source, and every `src-N` is reached by at least one `sup` in the
      entries (in `samples/dark-timeline.html`, search `id="src-1"`). The `sup` links a reader
      clicks point into this list, so an id the list does not carry is a dead link, and a source
      no entry cites is a row the reader cannot connect to anything.
- [ ] A date shown to the reader is human text inside a `<time>`, with the machine value in its
      `datetime`: a bare year for a year label (in `samples/dark-timeline.html`, search
      `<time datetime="1860">`), a full ISO date such as `2026-10-09` when the source gives one,
      and a full timestamp with hours, minutes and seconds when it does. A `c.`-qualified or
      ranged label such as `c. 802` or `928-944` stays plain text, because `<time>` carries one
      machine instant and a range is not one. Never print the machine value at the reader: a raw
      ISO string such as `2026-10-09T23:01:18Z` belongs in `datetime` alone, and the visible text
      stays a date a person reads.
- [ ] A second citation of a source already cited earlier in the document does not open a second
      `.sidenote` carrying the same title, authors and URL again. Link back into a numbered
      Sources list instead, the same `sup`-into-source-list pattern the requirement above already
      asks for inside `dl.timeline`, generalized to prose. No fixture demonstrates this yet.
      `.sidenote` floats into a fixed 28%-wide margin column, the narrowest real estate on the
      page; three near-identical citations for one fact, stacked in that column because a
      generator re-emitted the same source three times in one paragraph, spend it three times over
      for a single piece of corroboration.
- [ ] A page that cites sources from running prose cites them as `sup` links into one numbered
      `Sources` section at the foot of the page, not as a stack of `.sidenote` down the margin.
      The section is `<h2 id="sources">` over a `<div class="col-2">` that holds the numbered
      `<ol>`, two columns above `600px` and one below, with one `<li id="src-N">` per source and
      every one reached by at least one `sup` (in `tufte-dracula.css`, search `columns: 2`). A
      `.sidenote` floats 28% wide at its own anchor, so ten sources cited through prose become ten
      disconnected notes down one edge, each in sync with its paragraph and none with the rest. A
      numbered list puts every source in one place, keeps the number on screen the number in the
      list, and gives a reader one block to scan. **Do not reuse `.footnotes` for it**: that class
      is the converter's footnote block, hairline and annotation register included. `.sidenote` and
      `.marginnote` stay for an aside the sentence needs beside it.
      No fixture demonstrates this yet.
- [ ] `.verdict` plus one of `.verdict-pass`, `.verdict-partial`, `.verdict-failed` or
      `.verdict-neutral` on a `<span>` around a verdict token, wherever a page grades a claim: a
      `<table>` cell, a heading, prose, or a bulleted claim summary (a "What You Need to Know"
      list naming a verdict per item is exactly this). Bare text carries no pass, partial, failed
      or N/A distinction; the classes carry all of it. `.scorecard` (a compact `.sc-label` /
      `.verdict` / `.sc-note` three-column grid; in `samples/dark.html`, search
      `class="sc-label"`) suits a short two-to-six-item summary. A longer graded list wants a real
      `<table>` instead, `scope="col"` headers per the requirement above, with the same `.verdict`
      classes inside each Verdict cell (in `samples/dark.html`, search
      `<caption>Proof-test scorecard, table form`). **A row that rolls up sub-rows instead of
      carrying its own verdict** (a "Five principles" parent row whose sub-rows are what's graded)
      **still gets a `.verdict verdict-neutral` badge**, with a token like `See below`, not bare
      punctuation (in `samples/dark.html`, search
      `<span class="verdict verdict-neutral">See below</span>`). An ungraded row that skips the
      badge reads as a rendering gap next
      to every other row's colored pill, not as a deliberate design choice. **`<strong>` is not
      `.verdict`, and reaching for it is the failure this bullet most needs to name:** `strong`
      carries weight only (see NOTES.md, Form follows role), so `<strong>PASS</strong>` and
      `<strong>FAILED</strong>` render in the identical plain color, and a page that bolds every verdict this way looks styled without carrying any of the
      pass/partial/failed/N/A distinction the classes exist for. A table that grades a dozen rows
      and applies the badge to zero of them is the same missing markup as the rollup case above,
      just at the scale that makes it costliest to regenerate afterward.

- [ ] `.tag-dot` on an element that holds **no label text**, never one that wraps the dot and the
      label together (in `samples/dark.html`, search `class="tag-dot"`). The class paints its dot with `currentColor`, so a
      `color` set to recolor the dot recolors any text inside the same element too, and a
      categorical accent (`--data-1` through `--data-4`) is contrast-checked for a 3:1 graphic, not
      4.5:1 body text. `<span class="tag-dot" style="color: var(--data-1)"></span>Rust` keeps the
      color on the dot; the label sits outside the span as plain text.
- [ ] `aria-hidden="true"` on every `.icon-chip` span (in `samples/dark.html`, search `class="icon-chip"`). The glyph always sits
      beside a visible `<strong>` label that already states what it identifies, so an unhidden glyph
      is a screen reader announcing the same information twice per row. `.step-node` is the opposite
      case and stays real text: it carries no adjacent label of its own.
- [ ] `--icon-color` on a `.step-node` set from a **prose accent** (`--orange`, `--link`,
      `--purple`, `--green`, `--pink`, `--red`), never from the `--data-1` through `--data-4` ramp.
      The node fills at full strength and its letter is `--surface` painted on that fill, so the
      fill is a text ground, and the ramp is contrast-checked for a 3:1 graphic: `--surface` on it
      measures 3.45 to 3.53:1 in light mode and 3.60:1 in print, under the 4.5:1 text floor. This is
      the same trap as the `.tag-dot` case above, one component over. `.tag-dot` and `.icon-chip`
      **may** still take a `--data-*` color, because neither puts text on the fill. No CSS rule can
      enforce this, because the color arrives in an inline `style` attribute (in `samples/dark.html`,
      search `class="step-node" style="--icon-color: var(--orange)"`).
- [ ] **No `classDef name fill:#hex` line inside a ` ```mermaid ` fence on a page that can switch
      palette, whether by the reader's appearance or by the date.** A fence is diagram source, so
      it has no CSS to read and no `var()` it can resolve: one literal hex cannot serve both
      palettes, and the set in `mermaid-palette.json` under `classdef` is the **dark**
      projection. Emitted onto a page a reader opens in light mode, those fills land at 1.69 to
      2.15:1 against the light card, which is the failure the `--data-*` light values exist to
      prevent everywhere else. Let the nodes take the themed default instead, which `mermaid.js`
      already picks per scheme. Only a page **locked** to one palette (the way
      `samples/light.html` is) may carry the hex, and then it takes the matching set: `classdef`
      when locked to dark, `classdefLight` when locked to light.
      The one `classDef` a fixture emits sets `stroke-dasharray` and nothing else, which carries
      no color and serves both palettes (in `samples/dark-charts.html`, search
      `stroke-dasharray:6 4`). No fixture shows the hex case.
- [ ] Point labels on a `quadrantChart` kept short enough to sit inside the chart. Mermaid writes
      that diagram a fixed viewBox that does not contain its own point labels, so an overlong label
      paints outside it, and below roughly 700px the overflow lands past the viewport edge where
      nothing can reach it: not a scroll container, because SVG ink outside the root `<svg>` is not
      scrollable overflow for any ancestor, and not the zoom overlay, because the overlay scales the
      svg and scales the overrun with it. A chart with realistic labels loses nothing at any width
      from 601px up. `samples/dark.html` carries two deliberately overlong labels as a stress case
      for `pre.mermaid svg { overflow: visible }`, so do not copy their length (in
      `samples/dark.html`, search `quadrantChart`). **This is the one requirement the fixture
      deliberately breaks, so follow this bullet and not the fixture.**
- [ ] `--bar` on every `td.bar` inside a `table.bar-chart`, as a percentage, with the value itself
      as text in that same cell (in `samples/dark-charts.html`, search
      `class="bar" style="--bar: 21%`). The band is a background image, so `forced-colors: active`
      drops it and so does a reader who prints with background graphics off: a cell whose only
      content is the band then states nothing at all, while a cell that also carries the number
      loses only the second reading of it. Say in the `<caption>` what the percentage is a share
      of, because the component draws no axis and a bare band implies one. State the measure, the
      denominator, the cohort and the date range there when they change how a reader reads the
      numbers, and put the source in a `<span class="byline">`. This stays prose: no check can tell
      a caption that states them from one that does not. **The band has no color
      property, and that is deliberate:** it is a 0.3 alpha wash of `--data-1` in every row, which
      is the alpha the number sitting on top of it needs (check 12 of `palette-check.py` measures
      that pair in all four modes). A per-row hue was measured out, because four washes at that
      alpha land within Lc 2 of each other and cannot carry a category. Put the category in the row
      label.
- [ ] A `dl.meter` for a value against a known limit: the label in `<dt>`, the percent as text in
      `dd.v`, an optional gloss in `dd.s`, and `--bar` on the `dl` stating the same number the text
      states (in `samples/dark-charts.html`, search `class="meter"`). The band is a background
      image, so forced colors and a background-off print drop it and the text carries the value
      alone. A meter states a percent; a bare number with no limit belongs in `.stat-strip` or a
      plain table instead. The band carries one hue and no state: spell "full" or "paused" beside
      the value, and compose an existing `.verdict` chip where a page wants a state pill, rather
      than recoloring any band (per-row chart color is refused). Say in the surrounding prose what
      the percent is a share of, because the track carries no scale of its own, and compare each
      fill only against its own track when several meters with different limits share a page.
- [ ] A `span.spark` holds only empty `<i style="--h: NN%">` columns, oldest first, and carries
      a `data-values` attribute listing every value, comma separated, which the fixture probe checks
      each column against (in `samples/dark-charts.html`, search `class="spark"`). In a table, put the first and latest
      values in `td.num` cells either side of it (First, Trend, Latest). It also fits a sentence or a
      `.marginnote`. Order rows by the latest value unless they have a natural order. Add `fit` only
      outside a shared-scale table: it stretches the columns from the series' lowest to its highest
      value and dashes the baseline. The probe checks the stretch and refuses `fit` inside a
      `table.bar-chart`. Scale every column to zero and every row of
      one table to one maximum, and say the maximum in the `<caption>`. A series stretched from its
      minimum draws noise as a cliff. The columns carry no text, so the numbers must sit beside them.
- [ ] A `td.dot` inside a `table.bar-chart` holds no text, states `--bar` as the value's position on
      the table's shared scale, and is followed by a `td.num` carrying the value (in
      `samples/dark-charts.html`, search `class="dot"`). The dot paints at full strength `--data-1`,
      the sparkline's allowance, because no text sits under it. The position is the same share of a
      named scale that `--bar` states on a bar cell, so the `<caption>` names the denominator the
      same way. The probe reads the pair and refuses text in the dot cell.
- [ ] A Mermaid `xychart` fence holds one `line` series, no legend and no second series, beside a table
      that states every value (in `samples/dark-charts.html`, search `xychart`). Use the keyword
      `xychart`. The palette themes one color, so a second series would draw outside it. Set `height: 360` in the
      fence's `config: xyChart:` frontmatter, or the y-axis labels crowd at 5-unit ticks.
- [ ] A `div.multiples` holding two or more `table.bar-chart` panels on one shared scale (in
      `samples/dark-charts.html`, search `class="multiples"`). State the shared scale once in the
      prose above the grid. The first panel carries the row labels. Give every later
      panel the same rows in the same order, with its own caption, bars and source, a `Share`-style
      header, and no label cells: the sheet indents it by the label column so the bars line up.
- [ ] A Mermaid `radar-beta` or `treemap-beta` fence beside a table that states every value in it
      (in `samples/dark-charts.html`, search `radar-beta`). Both chart types ask a reader to compare
      angles or areas, so the graphic is only a second reading of numbers the page already states.
- [ ] Every `.step-node` after the first, together with the `.step-arrow` in front of it, wrapped in
      one `.step-hop` (in `samples/dark.html`, search `class="step-hop"`). `.step-chain` wraps at a narrow measure, and an
      arrow and its node are two separate flex items unless paired: a wrap can then land between
      them, stranding the arrow on the line above with no node after it and leaving the wrapped node
      with no connector in front of it. `.step-hop` makes the pair one flex item, so a wrap carries
      the arrow down with the node it points to.
- [ ] The steps of a `.step-chain` named in the sentence that introduces it, and `aria-hidden="true"`
      on every `.step-arrow` (in `samples/dark.html`, search `class="step-arrow" aria-hidden="true"`).
      A `.step-node` is a circle with room for one character, so its letter stays real text and
      carries no adjacent label, per the `.icon-chip` bullet above. That makes this the one
      requirement here that asks you for copy rather than for markup: an unexpanded `S`, `I`, `O`,
      `V` decodes to nothing for any reader, and no CSS rule can supply words the stylesheet did not
      write. The arrow is the other half. Left unhidden, a screen reader reads the glyph between
      every pair of steps, which is the duplication the `.icon-chip` bullet exists to prevent.
- [ ] `title` carrying the full text on every `<a>` inside `.recent-group .nav-list li`
      (in `samples/dark.html`, search `title="Item One"`). The stylesheet clips that link to one line with
      `text-overflow: ellipsis`, so a title longer than the row has no way back to sighted mouse
      users once clipped. `title` gives the browser's native tooltip a value to show. The DOM text
      stays intact either way, so a screen reader already reads the full title regardless.
- [ ] `aria-label` on every `.footnote-backref`, naming which reference it returns to
      (in `samples/dark.html`, search `aria-label="Back to reference 1"`). Its only content is `&#8617;`, a bare glyph with no accessible
      name a reader can act on. Number it: `Back to reference 1`, `Back to reference 2`, and so on,
      so two backrefs on one page do not announce identically. This holds whether you hand-author
      the footnote block or pass a document through a Markdown converter. No stylesheet rule can
      supply an accessible name onto content it did not write, so the class arrives from the
      converter and the label is still yours to add.

- [ ] Same-page citation targets emitted as relative fragments (`#src-1`), never absolute
      self-URLs. The stylesheet paints an outbound-link arrow after every `a[href^="http"]`, so a
      footnote ref written as `href="https://your.site/page#src-1"` renders `1 ↗` while the click
      only scrolls within the page. The arrow is a promise the link does not keep. Absolute URLs to
      other hosts keep the arrow; that is what it is for (in `samples/dark-timeline.html`, search
      `href="#src-1"`).
- [ ] A bracket-style inline citation (`[2, 3]`) is a link into the numbered source list, not bare
      text. The page's other citations are `sup` links into Sources; a bare `[2, 3]` asks the
      reader to count an ordered list by hand to learn what corroborates the claim. Emit the same
      `sup`-into-source-list pattern the timeline requirement above already asks for, one `sup` per
      source number. No fixture demonstrates this yet.
- [ ] `viewport-fit=cover` in the page's own `<meta name="viewport">`, beside
      `width=device-width, initial-scale=1` (in `samples/dark.html`, search `viewport-fit=cover`).
      Every `env(safe-area-inset-*)` reads `0` without it, so the `--gutter` insets, the overlay close
      mark and the top inset they fold in are all inert on the one class of device that has them, and
      text runs under a notch or a rounded corner in landscape. No stylesheet rule can set this: the
      meta element belongs to the page, not to the sheet.
- [ ] `.newthought` covers the opening few words of a section's first paragraph, never the whole
      sentence, and never splits a proper name at the span boundary. The class sets small caps at
      `1.2em` and weight 600, which is display treatment: a four-line paragraph inside it reads as
      shouting, and `of St.</span> John the Baptist` breaks a name in half. The stylesheet resets
      variant, weight, letter-spacing and size on a note nested inside the span, so the note renders
      normally, but the treatment itself is for opening words, not paragraphs. Keep the span short
      (in `samples/dark.html`, search `class="newthought"`).
- [ ] A `nav.toc` names itself with `aria-labelledby` pointing at its own visible
      `p.toc-label`, never with an `aria-label` repeating that same string. The index is a landmark,
      so it needs a name to be findable in a landmark list, and the label is already on the page:
      two copies of it make a screen reader read "On this page" twice on entry. This is the same
      duplication the `pre.mermaid` region avoids, reached from the other direction. Give
      the label an `id` and point at it. Entries are `<a>` inside `<li>` inside a single `<ol>`, so
      the two-column rule and its narrow and print overrides have a list to act on (in
      `samples/dark.html`, search `class="toc" aria-labelledby`).
- [ ] An index page whose section list runs past the viewport puts its section map in a
      `class="index-rail"` inside a `class="index-shell"`, and the rail holds its place while the
      entries beside it scroll. The rail is a `<nav>` named with `aria-labelledby` pointing at its
      own visible label, the naming rule `nav.toc` already follows, so it arrives in a landmark
      list with something to say. **The filter box and the entries it filters stay siblings in the
      second column, never inside the rail**: `filter.js` scopes a filter to the siblings that
      follow its input, so a box moved into the rail finds nothing to filter and goes inert with
      no error to read. Above `900px` the shell is two columns; below it the rail stacks over the
      entries and the shell is the single column this sheet has always rendered (in
      `samples/dark.html`, search `class="index-rail"`).
- [ ] If a `nav` lists sibling pages and one of them is the page the reader is on, mark that link
      `aria-current="page"`. The sheet gives it the body foreground at weight 600 and replaces the
      `nav > a + a` hairline on its start edge with a `3px` accent bar, so the marker still reads
      under forced colors, where the border and the colour both collapse to one system colour and
      only the weight is left (in `samples/dark.html`, search `aria-current="page"`).
- [ ] An image tile is `class="hero"` on a `<figure>`, with the image as its first child and the
      headline, supporting line and call to action inside the `<figcaption>` below it, never
      painted over the image. Text over a consumer's own image is beyond every check here, while a
      caption on `--surface-alt` is measured in all four modes. The image carries an
      `aspect-ratio`, so its box is reserved before the file arrives and nothing below it moves.
      The image itself is the one part of the tile the sheet cannot write: supply a real `alt` (in
      `samples/dark.html`, search `class="hero"`).

- [ ] A `.layer-stack` is an `<ol>` carrying `role="list"`, one `li.layer` per layer in the order a
      request crosses them, each holding a `div.layer-name` and a `div.layer-cards`, and the last
      layer takes `layer-end` only when it ends the path (in `samples/dark.html`, search
      `class="layer-stack"`). An optional card carries `class="layer-card optional"` and the word
      "Optional" in its own text: a dashed border alone disappears under forced colors. The
      stylesheet draws the arrow between layers, so emit none of your own.
- [ ] A coverage grid is `<table class="matrix">` inside a `.table-scroll` wrapper, with a label
      cell as `<th scope="row">` in the first column and `<span class="tag-dot"></span>N` where N
      counts what the row shares with the column (in `samples/dark.html`, search `class="matrix"`).
      A cell with nothing documented is `<td class="none">&middot;</td>`, never an empty cell,
      because a blank reads as missing data rather than as zero. Never shade a cell by its count:
      a shade reads as a score, and the values are never summed across a row.
- [ ] A `.heatmap` is the wide grid: `<table class="heatmap">` inside a `.table-scroll` wrapper, a
      first `<thead>` row of `th.band` cells spanning the columns they group, rotated column names
      in `th.col > span`, and one `span.hm` per cell (in `samples/dark.html`, search
      `class="heatmap"`). Give every square `role="img"` and an `aria-label` naming its state, one
      of `Full`, `Partial`, `Striped`, `Outlined` or `None` (in `samples/dark.html`, search
      `aria-label="Striped"`). A blank square conveys data, so the state needs a text equivalent.
      Never carry a state by hue alone, never sum a row's squares, and never add arrow-key movement
      without the full APG grid contract.

**Rules that outlive their release row.** § 3 keeps only the last ten releases, and each rule below
used to be carried by an older row. They bind every page whatever your pin.

**Converter output.** Keep the `markdown-alert` and `markdown-alert-<type>` class pair on GFM alerts.
Emit `align` attributes or inline `text-align` for pipe-table alignment. Wrap a wide table in
`.table-scroll` to get a working sticky header. Emit a `<nav>` with sibling `<a>` children to get link
separators. A bare `<table>` takes `tabindex="0"` and a `<caption>`, never `role="region"`.

**Icon lists.** Never break an `.icon-list` title from its detail with `<br>`. Put the `<strong>` and
the `<code>` side by side, and `.icon-list strong` breaks the line. Mark a file path with `<code>`,
not `<cite>`, which names the title of a standalone work.

**Mermaid fences.** A `kanban` and Mermaid's own `timeline` keyword take `accTitle` and `accDescr` in a
`---` front-matter block above the diagram keyword, both keys at column 0. Written inline, a `kanban`
draws them as two junk columns and a `timeline` never surfaces them. A `gantt` takes
`tickInterval 1day`, because its default spacing draws every date twice. `zenuml` does not render.
Layout is the bundled ELK engine, so a diagram can reflow when you move from an older pin, and a
direct import of `@mermaid-js/layout-elk` is dead weight to delete. Never pin below v1.48.1 when you
draw a `gantt`, a `kanban` or a `timeline`, because earlier releases carry defects for all three.

**Removed or replaced.** A `<div class="pie-chart">` is an empty box. Draw a `table.bar-chart`. The
template no longer themes a Mermaid `pie` fence. Drop any specificity hack or
`!important` you added to override the template: the sheet sits in `@layer tufte-dracula`, and your
unlayered CSS wins on its own.

Markdown constructs otherwise need **no classes of their own**. Do not invent any beyond what this
section already asks for. A converter's output lands in a theme register already.

## 3. What changed, by release

Check this table when you move the pin. A row here means your generator needs an edit, because
regeneration re-inlines fresh CSS around whatever markup you already emitted.

**Each row states what you must do and what is still open. The reasoning behind a change lives in
`NOTES.md`, which is where the rejected alternatives are recorded, so a row here stays short.**

**This table keeps the last ten releases, including the ones whose answer is `nothing`.** When you add a
row for a new release, delete the oldest. Every rule a deleted row introduced lives in § 1, § 2, § 5 or
§ 6, and the "Rules that outlive their release row" paragraph at the end of § 2 holds the ones that
fit no requirement. If your pin is older than the oldest row, read those sections in full instead of
looking for a row. `nu scripts/maintain.nu check` and the `contract` workflow compare this table
with `git tag`, so a skipped row fails the build. Add the row in the release commit itself.

| since | your generator must now |
| --- | --- |
| v1.75.0 | repaste the head snippet to gain four seasonal windows. **Aurora, Birthday, Oktoberfest and Halloween ship behind `data-season`.** Aurora runs January 14 through February 28, Birthday from August 25 through 27, Oktoberfest from September 20 through October 5, and Halloween from October 24 through 31. A page that keeps the older snippet keeps its existing calendar until it copies the block in § 1 again. The palettes apply on screen only, and a reader who asks for more contrast, and any printed page, keeps the existing palette. Every template-bearing theme target gains a variant per season, and Rider gains a dark and a light one, selected by hand. None of them is part of the payload. |
| v1.74.0 | nothing breaks. **The heading permalink is always visible and uses a chain-link icon instead of a pilcrow.** Emit `a.headerlink` with the inline SVG shown in the component fixture (in `samples/dark.html`, search `class="headerlink"`): `aria-hidden="true"` and `focusable="false"` on the icon, `aria-label` on the anchor, and `stroke="currentColor"`. A page that keeps the old pilcrow still renders it, because the stylesheet no longer hides the link. Heading label colors are unchanged. Regenerate pages whose inline stylesheet predates this payload. |
| v1.73.0 | repaste the head snippet to gain the Bois Jacques window. **A Bois Jacques palette ships behind `data-season="bois-jacques"`.** December 29 through January 13 select it, as two rows of one season because the window crosses the year boundary. Christmas still ends December 28, and January 14 through February 28 belong to no season. The palette applies on screen only, and a reader who asks for more contrast, and any printed page, keeps the existing palette. Every template-bearing theme target gains a Bois Jacques variant, and Rider gains a dark and a light one, selected by hand. None of them is part of the payload. |
| v1.72.1 | nothing breaks. **The contract history is corrected and the fixtures now demonstrate `translate="no"`.** The release table is rebuilt to the last ten tags, with the missing rows for `v1.71.0`, `v1.68.1`, `v1.67.0`, `v1.66.0` and `v1.65.0`. § 2 now requires `translate="no"` on every `<pre>` and `<code>`, and every fixture carries it. `check` and the `contract` workflow compare the table with `git tag`, so a skipped row fails the build. The payload changes only in its version stamp; regenerate pages whose inline stylesheet predates this payload. |
| v1.72.0 | nothing is required. **A Poland palette ships behind `data-season`, and the calendar gains override rows.** May 3, August 15, November 11 and December 6 select `poland`; May 3, November 11 and December 6 sit inside the Chartreuse, Thanksgiving and Christmas ranges, and August 15 stands alone. The override rows come first, so they win the days they share with a base range. A page that pasted the v1.70 snippet keeps its old calendar until it copies the block in § 1 again. The palette applies on screen only, and a reader who asks for more contrast, and any printed page, keeps the existing palette. Every template-bearing theme target gains a Poland variant, and Rider gains a dark and a light one, selected by hand. None of them is part of the payload. |
| v1.71.0 | nothing. **Every Rider season ships a light variant.** Rider was the one target that carried a dark and a light theme plus one dark theme per season, so each season now lands as a pair rendered from its `light-<season>` palette, with the matching `themeProvider` and jar entries. § 1 step 6 records the extra row. None of it is part of the payload. |
| v1.70.0 | nothing is required. **Three seasonal palettes ship behind `data-season` values, and nothing you already emit changes.** St Patrick runs from March 1 through March 17, Chartreuse from May 1 through May 16, and Independence Day from June 28 through July 4. A page without the head snippet in § 1 never turns them on; to follow the calendar, paste the updated snippet before the `<style>` block. The palette applies on screen only, and a reader who asks for more contrast, and any printed page, keeps the existing palette. Every template-bearing theme target gains one dark-family variant per season, selected by hand. None of them is part of the payload. |
| v1.69.0 | nothing breaks, and the § 2 text catches up with the fixtures. **The filter box now documents all four keyboard attributes**, three of which the v1.68.2 fixture already carried; `autocomplete="off"` was present earlier. The payload changes arrive on a re-inline: `font-display: optional` in all four `@font-face` rules, `h5` at weight 500, and a visually hidden `role="status"` region in `highlight.js` that announces `Copied`. |
| v1.68.2 | add `translate="no"` to the `<pre>` and `<code>` elements your generator emits, and add `autocapitalize="off"`, `spellcheck="false"` and `enterkeyhint="search"` to every `input.filter-box`; `autocomplete="off"` was already required. **Chrome page translation rewrites identifiers inside a code sample, and a phone keyboard capitalizes and spell-checks a search query.** § 2 states both rules and the fixtures demonstrate them. The stylesheet is unchanged apart from its version comment. |
| v1.68.1 | nothing. **Consumer documentation only.** README scales the seasonal theme prose and names one stable filename pattern per target. The stylesheet differs only in its version stamp; no markup, token or script changes. |

## 4. Regenerate on a byte compare, not a version string

A version comment is not a staleness signal. A generated file can carry a current comment over
stale bytes, and a file generated before the comment existed carries no version at all. Both
classes are invisible to a version check and both are caught by one byte compare.

Store the inline `<style>` block of each generated file. On regeneration, compare it against the
current `tufte-dracula.css` body. Regenerate the files that differ.

This is a requirement, not a recommendation. It scales to thousands of files and it needs no
metadata beyond what the artifact already carries.

**Don't keep a second version field that duplicates the one you inlined.** A generated page that
stamps its own `<meta name="template-version">` or similar, separate from the CSS it actually
shipped, can drift the same way a version-string staleness check can: the stamp is written once
and the payload moves on without it. Line 2 of `tufte-dracula.css` is
`/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`, the version of the bytes you are inlining right
now. Read it from there at generation time if you need to display or log a version, so the number
you show a reader can never disagree with the stylesheet you gave them.

## 5. Pin the payload

Three modes are in use. They are not equal.

- **Submodule at a release tag. Recommended.** A tag is the only pin that makes a generated
  artifact reproducible, and a tag is written only after CI has passed on that exact commit.
- **Submodule tracking `main`.** Fresh, and gated by CI, but two generations from the same source
  can differ.
- **A live read of a working tree.** Not reproducible. An uncommitted edit reaches a generated
  artifact with nothing recording it. Take this mode only when every source file survives
  regeneration.

**Keep the source.** A generator that deletes its own source after converting cannot regenerate,
so it can never adopt an improvement. Repairing generated HTML in place is a much harder problem
than running the generator again.

## 6. Scope of `filter.js`

The script wires each `input.filter-box` to the siblings that follow it, stopping at the next
filter box. Within that span it filters `tbody tr` rows and `.nav-list > li` items, and it hides
or opens a `details.nav-group` by whether anything inside it still matches.

A group's `summary .count` follows the filter. It reads the matched count while a
query is live and returns to the number you authored when the query clears. Emit the span if you
want the behavior; a group without one filters exactly as before.

It does not read your ids and it does not use `closest()`. The input-to-content pairing is the
only relationship your markup states, so state it by putting the content after the input.

A `[role="status"]` element inside the input's parent receives the visible count. A
`.filter-empty` element receives the no-matches line, and the script creates a hidden one after
the span when your markup omits it. The created one carries its own copy, so a page
that omits the element still shows a real no-matches line rather than a blank gap.
