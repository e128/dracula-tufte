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

## No gate asks whether an inlined script binds

**The problem.** `sample.html` shipped an inert `input.filter-box` from v1.16.0 to v1.21.0.
The handler walked forward for a `TABLE` that the fixture never had, and returned. Six
releases passed. The contract check counts `<script>` blocks and compares bytes, and neither
question is "does this handler attach to anything". The same blind spot covers `mermaid.js`:
CI proves its hex matches the palette and never proves it initialises.

**The change.** A CI-only step that loads each fixture in a DOM, runs the two inlined
scripts, and asserts observable behaviour. A working check already exists and is what
verified the v1.22.0 filter widening: six assertions over the real `sample.html`, covering
in-scope filtering, out-of-scope items staying put, group reveal, the empty line, the status
count, and open-state restore.

**Why it is a judgment call.** It needs Node and jsdom. Those are CI-only and no consumer
would inline them, so **No build step** survives in letter. It still grows the release
promise: a tag would then assert that the scripts behave, not only that the payload is
well-formed, and `REQUIRED_CHECKS` would gain a name that can hold a release. The declines
in this file have all been about refusing to make the sheet claim more than it can hold, and
this is the same shape of decision pointed at CI.

**Take it when** a third payload script appears, or when a second binding defect ships.
One defect found by hand is not yet a pattern.

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
