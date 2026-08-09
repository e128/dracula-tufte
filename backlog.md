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

## No open entries

v1.21.0 closed the last six entries. It took four and declined two. Every measurement
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
