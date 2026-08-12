# CONTRACT.md: what a consumer's generator must emit

This file is for the agent or the script that generates HTML in a **consumer** repository. It
states what to inline, what markup to emit, and what changed in each release. It carries no
reasoning. [NOTES.md](NOTES.md) holds the reasoning, and [README.md](README.md) holds the
narrative.

**`sample.html` is the executable specification.** It models every requirement below, and CI
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

`mermaid.js` needs `<div class="mermaid-overlay" id="mermaid-zoom"></div>` as the first child of
`<body>`. It throws a named error when the div is absent.

## 2. Emit this markup

Seven requirements. No stylesheet change can supply any of them.

- [ ] `<main>` around the content, with `<article>` inside it.
- [ ] A real `<label for>` on every `input.filter-box`. A placeholder is not a label.
- [ ] `accTitle:` and `accDescr:` inside every ` ```mermaid ` fence.
- [ ] `scope="col"` on table headers, and heading levels that nest with no skips.
- [ ] `role="list"` on every `<ul class="nav-list">`.
- [ ] `data-depth` on every row of a `<table class="tree">`, counting from `0`, in document order.
- [ ] `tabindex="0"` plus `role="region"` plus a label on anything that scrolls sideways: `pre`,
      a table below 1000px, a `<math display="block">`, and any `.table-scroll` wrapper.

Markdown constructs need **no classes of their own**. Do not invent any. A converter's output
lands in a theme register already.

## 3. What changed, by release

Check this table when you move the pin. A row here means your generator needs an edit, because
regeneration re-inlines fresh CSS around whatever markup you already emitted.

| since | your generator must now |
| --- | --- |
| v1.24.0 | drop any specificity hack or `!important` you added to override the template — the sheet is in `@layer tufte-dracula` and your unlayered CSS wins on its own |
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

It does not read your ids and it does not use `closest()`. The input-to-content pairing is the
only relationship your markup states, so state it by putting the content after the input.

A `[role="status"]` element inside the input's parent receives the visible count. A
`.filter-empty` element receives the no-matches line, and the script creates a hidden one after
the span when your markup omits it.
