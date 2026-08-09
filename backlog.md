# Backlog

Open decisions and deferred work for the Tufte-Dracula template. Each entry states
the problem, the concrete change, and what makes it a judgment call rather than a
bug — the bugs get fixed, these wait for a call.

Not a contract artifact. Consumers inline `tufte-dracula.css` and `mermaid.js`;
nothing reads this file.

A closed entry leaves this file rather than accumulating in it. Its measurements and
rejected alternatives go to [NOTES.md](NOTES.md), which is where a future agent looks;
the narrative goes in the commit.

---

## No open entries

v1.21.0 closed the last six. Four were taken and two were declined, and every
measurement moved to [The backlog this closed](NOTES.md#the-backlog-this-closed)
in NOTES.md:

| entry | outcome |
| --- | --- |
| Wide tables: inert sticky header, no keyboard reach | Taken. Opt-in `.table-scroll` wrapper, `overflow-x` stays on `table`. |
| Nine class families with no user in the largest consumer | Kept. The zero measures the generator, not the stylesheet. `sidenote` is now named in `README.md`. |
| Non-GFM callout conventions unclaimed | Declined. Three more names for a role the sheet paints twice, with no consumer. |
| Form controls at 13.33px Arial | Taken. `font: inherit` plus a 1rem floor. Appearance still belongs to the UA. |
| Pygments uncovered | Taken. Added to the seven grouped selectors, scoped under `:is(pre, code)`. |
| Jupyter ANSI output monochrome | Declined. Sixteen ANSI names onto seven accents is invention, with no consumer. |

Two declines carry a revisit condition rather than a verdict. Take the callout
conventions when a consumer actually runs Sphinx, MkDocs or Quarto. Take the ANSI map
when a notebook export appears in a lode.

Lower-severity findings from the same probe are recorded and not entered: `menu` loses
its marker padding to the `*` reset, `ins` and `u` are UA-underlined and so read as
links, `address` stays UA italic, and `.tabbed-set` shows every panel at once.
