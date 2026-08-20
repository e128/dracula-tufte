# CONTRACT.md: what a consumer's generator must emit

This file is for the agent or the script that generates HTML in a **consumer** repository. It
states what to inline, what markup to emit, and what changed in each release. It carries no
reasoning. [NOTES.md](NOTES.md) holds the decisions and the prohibitions behind these rules, and
[README.md](README.md) orients a person arriving for the first time.

**`samples/dark.html` is the executable specification.** It models every requirement below, and CI
fails when it drifts from the stylesheet. When this file and the fixture disagree, the fixture is
right. Read the fixture before you invent markup.

## 1. Inline the payload

Three files. Each one carries its own wrapper tag.

| file | when | wrapper |
| --- | --- | --- |
| `tufte-dracula.css` | always | `<style>` |
| `mermaid.js` | only when the document holds a ` ```mermaid ` fence | `<script type="module">` |
| `filter.js` | only when the document holds an `input.filter-box` | `<script type="module">` |

Two supported modes. Pick one and hold it:

- **Verbatim.** Copy the whole file. The wrapper comes with it. Do not add a second wrapper.
- **Sliced.** Take the body with `sed '1d;$d'` and supply your own wrapper. The wrapper is exactly
  one line at each end, and CI holds it there, so the slice cannot rot.

`mermaid.js` needs `<dialog class="mermaid-overlay" id="mermaid-zoom"></dialog>` as the first
child of `<body>`. It throws a named error when the dialog is absent. **Emit the dialog only on a
page that also inlines `mermaid.js`.** A page with no ` ```mermaid ` fence needs neither; a dialog
with no script to open it is dead markup.

**Take the CSS from `tufte-dracula.css`, never from a page.** `samples/light.html`,
`samples/light-conn-map.html` and `samples/light-timeline.html` exist so a reader can see the light
palette on a dark-mode machine. They carry a stylesheet whose `@media` conditions were rewritten to
force that, so a copy taken from one of them is locked to light and can never follow a reader's
system appearance. Each says so in a banner. `samples/dark.html`, `samples/dark-conn-map.html` and
`samples/dark-timeline.html` do carry the payload verbatim, but the file is still the source.

## 2. Emit this markup

Twelve requirements. No stylesheet change can supply any of them. Most link the line in
`samples/dark.html` that models it, so you have a working example instead of only a sentence. The
newest has no fixture yet; it says so.

- [ ] `<main>` around the content, with `<article>` inside it
      (`samples/dark.html:637-638`).
- [ ] A real `<label for>` on every `input.filter-box`. A placeholder is not a label
      (`samples/dark.html:849-850`).
- [ ] `accTitle:` and `accDescr:` inside every ` ```mermaid ` fence
      (`samples/dark.html:890-891`).
- [ ] `scope="col"` on table headers, and heading levels that nest with no skips
      (`samples/dark.html:687`).
- [ ] `role="list"` on every `<ul class="nav-list">` (`samples/dark.html:852`).
- [ ] `data-depth` on every row of a `<table class="tree">`, counting from `0`, in document order
      (`samples/dark.html:700-704`).
- [ ] `tabindex="0"` plus `role="region"` plus a label on anything that scrolls sideways: `pre`
      (`samples/dark.html:667`), a `<math display="block">` (`samples/dark.html:811`), and any
      `.table-scroll` wrapper (`samples/dark.html:717`). **Never put `role="region"` on the
      `<table>` itself.** It overrides `role="table"` and takes the row and column semantics with
      it. An unwrapped table takes `tabindex="0"` alone, named by its own `<caption>`
      (`samples/dark.html:685-686`), because the stylesheet hands it a sideways-scroll axis of its
      own below 1000px.
- [ ] `--timeline-date` on an ancestor when a page carries **more than one** `dl.timeline`, set in
      `ch` against the widest date label in the whole document (`samples/dark.html:784`). Each
      list otherwise sizes its own date track and the axis steps left down the page. Measure the
      label: `tabular-nums` pins digits to exactly `1ch` while letters stay proportional, so a
      spelled-out `c. 6th century CE` is wider than a numeric `c. 1182-1201`. **Measure at weight
      500**, the weight `dt` renders at, and **round up to the next whole `ch`.** `ch` resolves
      against the element the variable is set on, which is weight 400, and 400 is about 1.7%
      narrower per character, so a value measured at 400 is short by a quarter character at 16ch.
      Too small a value has no CSS backstop: the label overflows into the column gap and touches
      the rule. One list needs nothing.
- [ ] Citations inside a `dl.timeline` entry as `sup` links into a numbered source list, never a
      `.sidenote` (`samples/dark.html:779`). A float cannot escape a grid item, so the note lands
      inside the entry column instead of the page margin. Give each `dt` an `id` to make an entry
      deep-linkable (`samples/dark.html:776`); the arrival outline is automatic once it has one.
- [ ] A second citation of a source already cited earlier in the document does not open a second
      `.sidenote` carrying the same title, authors and URL again. Link back into a numbered
      Sources list instead, the same `sup`-into-source-list pattern the requirement above already
      asks for inside `dl.timeline`, generalized to prose. No fixture demonstrates this yet.
      `.sidenote` floats into a fixed 28%-wide margin column, the narrowest real estate on the
      page; three near-identical citations for one fact, stacked in that column because a
      generator re-emitted the same source three times in one paragraph, spend it three times over
      for a single piece of corroboration.
- [ ] `.verdict` plus one of `.verdict-pass`, `.verdict-partial`, `.verdict-failed` or
      `.verdict-neutral` on a `<span>` around a verdict token, wherever a page grades a claim: a
      `<table>` cell, a heading, prose, or a bulleted claim summary (a "What You Need to Know"
      list naming a verdict per item is exactly this). Bare text carries no pass, partial, failed
      or N/A distinction; the classes carry all of it. `.scorecard` (a compact `.sc-label` /
      `.verdict` / `.sc-note` three-column grid, `samples/dark.html:827-832`) suits a short
      two-to-six-item summary. A longer graded list wants a real `<table>` instead, `scope="col"`
      headers per the requirement above, with the same `.verdict` classes inside each Verdict cell
      (`samples/dark.html:835-843`). **A row that rolls up sub-rows instead of carrying its own
      verdict** (a "Five principles" parent row whose sub-rows are what's graded) **still gets a
      `.verdict verdict-neutral` badge**, with a token like `SEE BELOW`, not bare punctuation
      (`samples/dark.html:838`). An ungraded row that skips the badge reads as a rendering gap next
      to every other row's colored pill, not as a deliberate design choice. **`<strong>` is not
      `.verdict`, and reaching for it is the failure this bullet most needs to name:** `strong`
      already carries `color: var(--orange)` for unrelated reasons (see NOTES.md, Form follows
      role), so `<strong>PASS</strong>` and `<strong>FAILED</strong>` render in the identical
      color, and a page that bolds every verdict this way looks styled without carrying any of the
      pass/partial/failed/N/A distinction the classes exist for. A table that grades a dozen rows
      and applies the badge to zero of them is the same missing markup as the rollup case above,
      just at the scale that makes it costliest to regenerate afterward.

- [ ] `.tag-dot` on an element that holds **no label text**, never one that wraps the dot and the
      label together (`samples/dark.html:790`). The class paints its dot with `currentColor`, so a
      `color` set to recolor the dot recolors any text inside the same element too, and a
      categorical accent (`--data-1` through `--data-4`) is contrast-checked for a 3:1 graphic, not
      4.5:1 body text. `<span class="tag-dot" style="color: var(--data-1)"></span>Rust` keeps the
      color on the dot; the label sits outside the span as plain text.
- [ ] Every `.step-node` after the first, together with the `.step-arrow` in front of it, wrapped in
      one `.step-hop` (`samples/dark.html:797-801`). `.step-chain` wraps at a narrow measure, and an
      arrow and its node are two separate flex items unless paired: a wrap can then land between
      them, stranding the arrow on the line above with no node after it and leaving the wrapped node
      with no connector in front of it. `.step-hop` makes the pair one flex item, so a wrap carries
      the arrow down with the node it points to.

Markdown constructs need **no classes of their own**. Do not invent any. A converter's output
lands in a theme register already.

## 3. What changed, by release

Check this table when you move the pin. A row here means your generator needs an edit, because
regeneration re-inlines fresh CSS around whatever markup you already emitted.

| since | your generator must now |
| --- | --- |
| v1.34.0 | nothing. Two self-contained stylesheet additions over markup you already emit: a fixed, full-viewport film-grain texture behind every page (`body::before`, off in print and in `forced-colors: active`), and a second shadow layer on `kbd` for a raised bottom edge. Neither needs new markup or a new class |
| v1.33.0 | nothing, unless you opt in to one of six new presentational classes: `.kicker`, `.tag-dot`, `.live-dot`, `.icon-list` / `.icon-chip`, `.step-chain` / `.step-hop` / `.step-node` / `.step-arrow`, and `blockquote.pull`. All are self-contained CSS over markup you write yourself, no existing fixture requirement changes. Two carry a real markup requirement if you use them, both new in § 2: keep `.tag-dot` off any element that also holds the label text, and wrap every arrow-plus-node pair after the first in `.step-hop` |
| v1.31.0 | opt in to `.verdict` plus `.verdict-pass` / `.verdict-partial` / `.verdict-failed` / `.verdict-neutral` on any page that grades a claim. The classes existed before this row did; nothing in this file told a generator they were there, so a real graded page (a 27-row scorecard, a verdict per row) rendered every verdict as plain text. `.verdict` also gained `display: inline-block`, so its fixed `min-width` now holds wherever you place it, a `<table>` cell, a heading, or prose, not only inside `.scorecard`'s grid, where a grid item's blockified `display` had been carrying it until now |
| v1.30.0 | nothing. `.recent-group .nav-list li` now lays its `<span class="count">` out beside the link instead of on its own line below it, and equalizes card height within a `.recent-groups` row. Both are self-contained stylesheet changes over markup you already emit |
| v1.27.0 | **drop `role="region"` from any bare `<table>` you put it on**, and emit `tabindex="0"` plus a `<caption>` there instead. § 2 used to fold a table into the same sentence as `pre` and `math`, so it asked for a role that overrides `role="table"` and takes the row and column semantics with it. The tab stop is still required, because the stylesheet gives a table its own sideways-scroll axis below 1000px, and the `<caption>` is what names it. A table inside `.table-scroll` needs no edit: the role belongs on the wrapper and always did |
| v1.27.0 | nothing, and a filtered `details.nav-group` now counts what it shows. `filter.js` used to leave `summary .count` at its authored number while the query hid items underneath it, so a group could read `5` over two visible rows, and the `[role="status"]` line beside it reported the real figure. Two counts on one screen disagreed and the wrong one was the larger. The script restores your number when the query clears, so an authored count is still yours |
| v1.27.0 | nothing, and the filter's live count now sits in the annotation register. The sheet claimed `.filter-label`, `.filter-empty` and `.count` but never `[role="status"]`, so the count § 6 asks you to emit rendered at body weight on `--on-surface` and read as content above the list. `.filter-box ~ [role="status"]` puts it at `--label` and `0.95em` beside its own label. Override it in your own layer if you had styled it yourself |
| v1.27.0 | nothing, and a wrapped table now prints in full. `.table-scroll` held its `70vh` cap and `overflow: auto` on paper, so a table taller than one screen lost the overflow with nothing marking the loss. The print block releases both. `samples/dark.html` carries the first `.table-scroll` instance in the repo, twenty-four rows by eight columns, which is the size it takes to make both scroll axes and the pinned header real rather than declared |
| v1.26.0 | nothing, unless you emit dated events. `dl.timeline` is opt-in: a `dl` with no class keeps the glossary register it always had. Emit the class and the two requirements in § 2 apply, `--timeline-date` and `sup` citations. Everything else is self-contained: the timeline collapses to one column below 760px rather than 600px, a `:target` entry outlines and its date turns orange, a multi-source `sup` no longer breaks across a line end, and a citation marker's hit area is taller |
| v1.26.0 | nothing for the palette, but expect a visible shift in three places if you diff screenshots. Light and print `--red` are more saturated, the light row-hover fill is one step lighter, and the three high-contrast accents that were declaring a chroma sRGB cannot hold now declare the color they actually paint. All are `:root` values; no markup reads them |
| v1.25.0 | nothing. The stylesheet changes are self-contained: `--data-1..4` gained light and print values, `h5` and `h6` dropped to weight 500, and the conn-map Links column is height-bounded. `filter.js` now writes `No entries match. Clear the filter to see all entries.` into a `.filter-empty` it creates, and still leaves your own copy untouched when you emit one |
| v1.24.0 | drop any specificity hack or `!important` you added to override the template. The sheet is in `@layer tufte-dracula` and your unlayered CSS wins on its own |
| v1.24.0 | nothing for light or high-contrast mode; both are media queries over the same markup |
| v1.22.0 | emit `<nav>` with sibling `<a>` children to get link separators; nothing to change if you already do |
| v1.22.0 | supply `tabindex="0"`, `role="region"` and a label on any `<math display="block">` |
| v1.22.0 | keep the `markdown-alert` and `markdown-alert-<type>` class pair on GFM alerts |
| v1.21.0 | wrap a wide table in `.table-scroll` to get a working sticky header, if you want one |
| v1.20.0 | emit `align` attributes or inline `text-align` for pipe-table alignment |

## 4. Regenerate on a byte compare, not a version string

A version comment is not a staleness signal. A generated file can carry a current comment over
stale bytes, and a file generated before the comment existed carries no version at all. Both
classes are invisible to a version check and both are caught by one byte compare.

Store the inline `<style>` block of each generated file. On regeneration, compare it against the
current `tufte-dracula.css` body. Regenerate the files that differ.

This is the recommended trigger. It scales to thousands of files and it needs no metadata beyond
what the artifact already carries.

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

A group's `summary .count` follows the filter as of v1.27.0. It reads the matched count while a
query is live and returns to the number you authored when the query clears. Emit the span if you
want the behavior; a group without one filters exactly as before.

It does not read your ids and it does not use `closest()`. The input-to-content pairing is the
only relationship your markup states, so state it by putting the content after the input.

A `[role="status"]` element inside the input's parent receives the visible count. A
`.filter-empty` element receives the no-matches line, and the script creates a hidden one after
the span when your markup omits it. The created one carries its own copy as of v1.25.0, so a page
that omits the element still shows a real no-matches line rather than a blank gap.
