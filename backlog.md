# Backlog

This file holds the open decisions and the deferred work for the Tufte-Dracula template.
Each entry states the problem, the concrete change, and what makes it a judgment call
rather than a bug. The bugs get fixed. These wait for a call.

This file is not a contract artifact. Consumers inline `tufte-dracula.css` and
`mermaid.js`, and nothing reads this file.

A closed entry leaves this file. It does not collect here. Its measurements and its
rejected alternatives go to [NOTES.md](NOTES.md), which is the file a future agent reads.
The narrative goes in the commit.

---

## Nothing is open

v1.40.0 closed every entry that was here. Six went in and six came out, and the
measurements moved to NOTES.md as the rule above says.

| entry | outcome | where the reasoning went |
| --- | --- | --- |
| No gate asks whether an inlined script binds | Taken. `.github/script-probe.py`, eighteen driven assertions | [The one check that runs the payload](NOTES.md#the-one-check-that-runs-the-payload) |
| A light twin for the `classdef` fills | Taken. `classdefLight`, plus the emit-time rule that was the real blocker | [The data ramp](NOTES.md#the-data-ramp) |
| Pie slice opacity and the dark-mode slice label | Taken. `pieOpacity: '1'` and `pieSectionTextColor` per palette, with a `pie` fence to measure it | [Diagram types](NOTES.md#diagram-types) |
| The mermaid `pre` region announces its name twice | Taken. The region now exists only where the `pre` can scroll | [Keyboard and assistive technology](NOTES.md#keyboard-and-assistive-technology) |
| `pre.mermaid` is a focusable region where it cannot scroll | Taken by the same change | [Keyboard and assistive technology](NOTES.md#keyboard-and-assistive-technology) |
| Two § 2 requirements cannot be gated | Split. `.step-node` is gated in the fixtures; the `quadrantChart` label stays prose | [What is gated, and what is open](NOTES.md#what-is-gated-and-what-is-open) |
| Every `samples/dark.html` line reference in § 2 is wrong | Taken. Search strings instead of line numbers, with a gate | [Never cite a line number into a generated file](NOTES.md#never-cite-a-line-number-into-a-generated-file) |

**Three of the six had been declined on a cost that turned out to be wrong**, which is
the pattern worth carrying forward rather than the entries themselves.

- The script probe was declined on needing Node and jsdom. It needs neither: the repo
  already shells out to headless Chrome for the mode renders, and `--dump-dom` answers
  the question `--screenshot` could not.
- The conditional region was declined on needing a resize listener or a `matchMedia` the
  palette check banned. A media-query listener is not resize-stale, and the ban was
  aimed at `prefers-color-scheme` rather than at the function.
- The pie fix was declined partly on needing a seventh `!important` against Mermaid's own
  stylesheet. Both values are real `themeVariables`, confirmed against the pinned chunk.

**A decline is a cost estimate with a date on it.** Re-price one before repeating it.

---

## Closed in v1.21.0

v1.21.0 closed six entries. It took four and declined two. Every measurement
moved to [The backlog this closed](NOTES.md#the-backlog-this-closed) in NOTES.md.

| entry | outcome |
| --- | --- |
| Wide tables: inert sticky header, no keyboard reach | Taken. An opt-in `.table-scroll` wrapper. `overflow-x` stays on `table`. |
| Nine class families with no user in the largest consumer | Kept. The zero measures the generator, not the stylesheet. `README.md` now names `sidenote`. |
| Non-GFM callout conventions unclaimed | Declined. Three more names for a role the sheet already paints twice, with no consumer. |
| Form controls at 13.33px Arial | Taken. `font: inherit` plus a 1rem floor. The UA still owns the appearance. |
| Pygments uncovered | Taken. Added to the seven grouped selectors, scoped under `:is(pre, code)`. |
| Jupyter ANSI output monochrome | Declined. Sixteen ANSI names onto seven accents is invention, with no consumer. |

Both declines carry a condition to revisit, not a verdict. Take the callout conventions
when a consumer runs Sphinx, MkDocs or Quarto. Take the ANSI map when a notebook export
appears in a lode.

The same probe found four smaller defects. v1.21.0 took two of them. `menu` now indents
like the other list types. `ins` and `u` now take a dotted underline, so they no longer
read as links.

Two stay recorded, and they are not entries. `address` keeps its UA italic, which is
arguably correct for a postal block. `.tabbed-set` shows every panel at once, and a fix
means the sheet claims a radio-driven widget.
