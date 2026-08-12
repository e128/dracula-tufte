# CLAUDE.md — Tufte-Dracula template

Instructions for any agent that works in this repo. These instructions override default
behavior.

## Read [NOTES.md](NOTES.md) first

**Before you change `tufte-dracula.css` or `mermaid.js`, read [NOTES.md](NOTES.md).** It holds
the reasoning that used to live in those files as comments. It records every measured number,
every rejected alternative, and every decision that this repo already re-litigated.

This is not optional background. Several changes in this repo's history were correct on paper,
shipped, and then went back out: the measure cap, two page-width attempts, and a monospace
table stack. NOTES.md records what the repo tried, what it measured, and why it reverted. The
file exists so that nobody covers the same ground twice.

You may want to fix something that looks wrong: a 178-character measure, a heading heavier than
its parent, an inert `themeVariable`, or a table that could be narrower. **NOTES.md probably
records it already, with the measurement that settled it.** Check NOTES.md before you touch the
CSS. If you still disagree, say so directly. Do not reverse a documented decision in silence.

When you make a new decision worth keeping, add it to NOTES.md. Do not add it to the
stylesheet.

## NEVER write comments in files that get inlined into HTML

Every generated HTML file carries a verbatim copy of `tufte-dracula.css` and `mermaid.js`. A
comment here is not written once. Every page a consumer renders carries a copy of it, forever.

**Rules:**

- **Do not add comments to `tufte-dracula.css` or `mermaid.js`.** No block comments, no
  end-of-line comments, and no single line that explains a magic number.
- The same rule covers any future file that a consumer inlines instead of links. If a consumer
  copies the file into output, the file carries no comments.
- `mermaid-palette.json` already has `_comment` keys. Do not add more.
- **Two exceptions exist. A machine reads both. Do not remove them:**
  - **Line 2 of `tufte-dracula.css`** must be a comment that holds the template version, in the
    form `/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`. `scripts/build-sample.nu` parses it out of
    `lines | get 1` to stamp `tokens.css`, and `scripts/maintain.nu bump` rewrites it. If you remove it,
    regeneration dies with `index too large (empty content)`. That failure is *silent* when you
    pipe the output, and it leaves stale fixtures that look correct.
  - **The `/* was #rrggbb */` notes on ten `:root` tokens.** Check 3 of
    `.github/palette-check.py` parses them, and the check fails when a stated hex disagrees with
    its `oklch()`. If you delete a note, you disable that gate in silence. Match the exact
    format when you add a token.
- The Nushell scripts (`scripts/build-sample.nu`, `scripts/maintain.nu`), `README.md`, `backlog.md` and this
  file are **not** inlined. Comment those files as normal.

**Put the reasoning in one of these places instead**, in order of preference:

1. **[NOTES.md](NOTES.md)** — the durable home for the reason a declaration looks the way it
   does. It holds measurements, rejected alternatives, and settled decisions. A future agent
   reads this file instead of the comments.
2. **The commit message**, for the story of a single change.
3. **`backlog.md`**, for open decisions and deferred work.
4. **`README.md`**, for anything a consumer needs to know.

Never delete a load-bearing explanation. Move it to NOTES.md.

## Regeneration and the contract

- `scripts/build-sample.nu` generates `sample.html`, `sample-conn-map.html` and `tokens.css`. Never edit
  them by hand. Change `tufte-dracula.css`, `mermaid.js` or `scripts/build-sample.nu`, then regenerate.
- Run `nu scripts/maintain.nu check` after every change. It mirrors CI: file presence, the palette
  hex-against-oklch gate, exactly one `<style>` and one `<script>` per fixture, and a staleness
  check that proves regeneration changes nothing. It must print `Contract OK`.
- The first line of `tufte-dracula.css` must be exactly `  <style>`. The last line must be
  exactly `  </style>`. Consumers slice the body out with `sed '1d;$d'`. This is a contract.
- `tufte-dracula.css` carries its own `<style>` wrapper, and `mermaid.js` carries its own
  `<script>` wrapper. Do not add a second wrapper.

## A tag claims that the contract held. Verify the claim, never assume it

Consumers pin to a tag through a git submodule. A tag on a commit that CI never checked hands
every consumer a payload that nothing verified. The fixtures and `tokens.css` are generated, so
a stale or broken one looks completely normal.

**Only a pull request can satisfy a required status check.** `main` requires the `contract`
check (`strict: true`, `enforce_admins: false`, no review requirement). The check runs *after* a
push, so a direct `git push origin main` can never satisfy it. GitHub accepts the push and
records `Bypassed rule violations`. Two separate pushes, one for the commit and one for the tag,
do not fix this. Only a merged pull request does. **Never commit straight to `main`.**

The flow, start to finish. The `release` skill
([`.claude/skills/release/SKILL.md`](.claude/skills/release/SKILL.md)) packages it, and "make a
release" invokes that skill.

```
git switch -c fix/whatever                  # never work on main
nu scripts/maintain.nu bump 1.11.0          # stamps the CSS + README
git add -A && git commit -m 'fix: v1.11.0 — <summary>'
git push -u origin fix/whatever
gh pr create --fill && gh pr checks --watch # `contract` must pass here
gh pr merge --squash                        # the merge is what the check gates
git switch main && git pull
nu scripts/maintain.nu release 1.11.0       # verifies, then tags
```

`nu scripts/maintain.nu release <version>` does **not** push a branch. It refuses a dirty tree. It
refuses a version that the stylesheet does not carry. It refuses a tag that already exists. It
refuses a `HEAD` that is not already `origin/main`, and that last refusal is what proves the
commit arrived through the gate instead of around it. It then polls the check runs for that
exact SHA, and it writes the tag only when every check named in `REQUIRED_CHECKS` concludes
`success`. A missing required check counts as a failure, because a commit that CI never saw is
the thing this gate exists to refuse. The tag is **annotated**, so `git tag -v` has an object to
read.

**Only the required checks gate the tag. The rest are advisory.** GitHub attaches a check run
for every workflow that a commit fires, including the workflows GitHub generates itself.
`pages-build-deployment` alone contributes `build`, `deploy` and `report-build-status`. None of
them say anything about the payload. A gate on *every* check once held a tag for a full timeout
because a Pages deploy stalled on GitHub's side, and then refused the tag outright, because a
non-success conclusion stays attached to that SHA. `REQUIRED_CHECKS` at the top of `release` is
the list. Keep it in step with the required checks configured on `main`, and add to that list
rather than widen the gate back to every check.

**Rules that have no exception:**

- **Never run `git push origin main v1.x.0`.** One command pushes the commit and the tag
  together, so the tag claims that the contract held before anything checked it.
- **Never tag a commit that is not `origin/main`,** and never tag a commit where a required
  check is absent. Absent is not passing.
- **Never use `--no-verify`, and never force-push a tag that you already pushed.** A moved tag
  changes what every pinned consumer resolves to, and it does so in silence.
- **If a push reports `Bypassed rule violations`, stop and say so in that same message.** The
  report means that something overrode the protection instead of satisfying it. Do not bury it,
  and do not continue to the tag. Offer to revert.

A release faces outward and is hard to reverse. Confirm before you tag or push, unless the
request was explicitly to release.

## Constraints that shape every decision

- **No build step.** Consumers inline two files verbatim. Anything that needs compilation,
  bundling, or a preprocessor is out of scope.
- **Output renders locally, and often offline.** A CDN dependency must degrade well: the webfont
  falls back to a system serif and the text still renders. Mermaid is the existing exception,
  and it fails hard offline.
- **Mermaid colors must be hex, never `oklch()`.** Its color engine (khroma) throws
  "Unsupported color format" on an `oklch()` string and aborts init, so no diagram renders.
  `mermaid-palette.json` and `.github/palette-check.py` keep the hex honest against the oklch
  source.
- Pin every CDN dependency to an exact version, never to a range.

## Style decisions that are already settled

Do not "fix" these decisions. Each one is deliberate, and this repo re-litigated each one at
least once. [NOTES.md](NOTES.md) holds the measurement and the failed alternatives for each.

- **The long measure.** Prose runs well past 60 to 75 characters per line. A cap strands the
  copy in a narrow column inside an empty container. The repo trades width for measure
  knowingly.
- **Page width is one number.** `--page-width` in `:root` serves both layouts. Do not add a
  second width convention, a breakpoint override, or a full-bleed breakout.
- **Headings use `em`**, so they track the body clamp instead of the fixed root.
- **`h1` and `h2` sit at weight 400.** They are large enough to carry it. Nothing at text size
  may be lighter than body copy.
