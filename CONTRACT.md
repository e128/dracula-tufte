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
child of `<body>`. It throws a named error when the dialog is absent.

**Take the CSS from `tufte-dracula.css`, never from a page.** `samples/light.html`,
`samples/light-conn-map.html` and `samples/light-timeline.html` exist so a reader can see the light
palette on a dark-mode machine. They carry a stylesheet whose `@media` conditions were rewritten to
force that, so a copy taken from one of them is locked to light and can never follow a reader's
system appearance. Each says so in a banner. `samples/dark.html`, `samples/dark-conn-map.html` and
`samples/dark-timeline.html` do carry the payload verbatim, but the file is still the source.

## 2. Emit this markup

Nine requirements. No stylesheet change can supply any of them.

- [ ] `<main>` around the content, with `<article>` inside it.
- [ ] A real `<label for>` on every `input.filter-box`. A placeholder is not a label.
- [ ] `accTitle:` and `accDescr:` inside every ` ```mermaid ` fence.
- [ ] `scope="col"` on table headers, and heading levels that nest with no skips.
- [ ] `role="list"` on every `<ul class="nav-list">`.
- [ ] `data-depth` on every row of a `<table class="tree">`, counting from `0`, in document order.
- [ ] `tabindex="0"` plus `role="region"` plus a label on anything that scrolls sideways: `pre`, a
      `<math display="block">`, and any `.table-scroll` wrapper. **Never put `role="region"` on the
      `<table>` itself.** It overrides `role="table"` and takes the row and column semantics with
      it. An unwrapped table takes `tabindex="0"` alone, named by its own `<caption>`, because the
      stylesheet hands it a sideways-scroll axis of its own below 1000px.
- [ ] `--timeline-date` on an ancestor when a page carries **more than one** `dl.timeline`, set in
      `ch` against the widest date label in the whole document. Each list otherwise sizes its own
      date track and the axis steps left down the page. Measure the label: `tabular-nums` pins
      digits to exactly `1ch` while letters stay proportional, so a spelled-out
      `c. 6th century CE` is wider than a numeric `c. 1182-1201`. **Measure at weight 500**, the
      weight `dt` renders at, and **round up to the next whole `ch`.** `ch` resolves against the
      element the variable is set on, which is weight 400, and 400 is about 1.7% narrower per
      character, so a value measured at 400 is short by a quarter character at 16ch. Too small a
      value has no CSS backstop: the label overflows into the column gap and touches the rule.
      One list needs nothing.
- [ ] Citations inside a `dl.timeline` entry as `sup` links into a numbered source list, never a
      `.sidenote`. A float cannot escape a grid item, so the note lands inside the entry column
      instead of the page margin. Give each `dt` an `id` to make an entry deep-linkable; the
      arrival outline is automatic once it has one.

Markdown constructs need **no classes of their own**. Do not invent any. A converter's output
lands in a theme register already.

## 3. What changed, by release

Check this table when you move the pin. A row here means your generator needs an edit, because
regeneration re-inlines fresh CSS around whatever markup you already emitted.

| since | your generator must now |
| --- | --- |
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
