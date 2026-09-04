# AGENTS.md: Tufte-Dracula template

Instructions for any agent that works in this repo, whichever harness runs it. These instructions
override default behavior.

**This file is the whole contract for agent behavior here. It names no harness and depends on
none.** Everything it asks for is a shell command, a file path, or a decision rule. A harness may
wrap a flow below behind a command, a skill or a slash command of its own, and a sibling file may
document that wrapper (`CLAUDE.md` does, for Claude Code). Such a file adds an entry point. **It
never adds, relaxes or overrides a rule stated here.** If one appears to, this file wins.

## Read [NOTES.md](NOTES.md) first

**Before you change `tufte-dracula.css` or `mermaid.js`, read [NOTES.md](NOTES.md).** It holds
the reasoning that used to live in those files as comments. It records every current decision,
every rejected alternative, and every prohibition this repo already paid for.

**NOTES.md states decisions, not measurements.** Every number behind an entry was measured in
Chromium, and those measurements live in git history and in the gates. `.github/palette-check.py`
and `.github/render-modes.py` enforce the color and mode claims, so a number that matters is a
check rather than a paragraph. **Do not add measurement narration back to NOTES.md**, and do not
write a version history into it: `CONTRACT.md` § 3 owns per-release deltas and `git blame` owns
the rest.

This is not optional background. Several changes in this repo's history were correct on paper,
shipped, and then went back out: the measure cap, two page-width attempts, and a monospace
table stack. Every "do not" in NOTES.md is one of those. The file exists so that nobody covers
the same ground twice.

You may want to fix something that looks wrong: a long measure, a heading heavier than its
parent, an inert `themeVariable`, or a table that could be narrower. **NOTES.md probably records
it already.** Check NOTES.md before you touch the CSS. If you still disagree, re-measure and say
so directly. Do not reverse a documented decision in silence.

When you make a new decision worth keeping, add it to NOTES.md as a decision plus its
prohibition. Do not add it to the stylesheet, and do not append it as a story about what changed.

## Writing rules

**No em-dash and no en-dash anywhere in this repo.** Not in prose, not in a heading, not in a
table cell, not in a code comment, not in a runtime `print` string, not in fixture copy, and not
in a commit message or a PR body. The two characters are U+2014 EM DASH and U+2013 EN DASH, and
the count is zero. This paragraph names them by codepoint rather than printing them, because the
gate below scans every tracked file and would otherwise fail on the rule that states it.

Use whatever the sentence actually needs instead:

- A period, when the two halves are two sentences. This is right most of the time.
- A comma or a conjunction, when the second half qualifies the first.
- A colon, when the second half names or expands the first.
- Parentheses, when a pair of dashes was fencing an aside.
- A plain hyphen `-`, for compound words, numeric ranges (`200-900`, `h1`-`h6`), and aligned
  key-to-description lines where a colon would break the column.

`nu scripts/maintain.nu check` and the `contract` workflow both fail on any occurrence, and
`nu scripts/maintain.nu bump` refuses to stamp a version while one is present, so this is gated
rather than trusted. The commit-subject convention is `feat: vX.Y.Z - <summary>` with a hyphen.
Commits already in history keep the old em-dash form; nothing rewrites them.

The rule exists because 186 em-dashes across 22 files read as one voice tic rather than as
punctuation, and because a gate is the only thing that keeps a prose rule alive in a repo where
most edits are made by an agent.

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
  - **The `/* was #rrggbb */` notes on six `:root` tokens.** Check 3 of
    `.github/palette-check.py` parses them, and the check fails when a stated hex disagrees with
    its `oklch()`. If you delete a note, you disable that gate in silence. Match the exact
    format when you add a token. Four tokens (`--orange`, `--purple`, `--pink`, `--green`) lost
    this note when their chroma widened past sRGB into Display P3: a P3 chroma has no exact sRGB
    hex to state. See NOTES.md, Color and the contrast budget.
- The Nushell scripts (`scripts/build-sample.nu`, `scripts/maintain.nu`), `README.md`, `backlog.md`
  and the agent instruction files are **not** inlined. Comment those files as normal.

**Put the reasoning in one of these places instead**, in order of preference:

1. **[NOTES.md](NOTES.md)**, the durable home for the reason a declaration looks the way it
   does. It holds measurements, rejected alternatives, and settled decisions. A future agent
   reads this file instead of the comments.
2. **The commit message**, for the story of a single change.
3. **`backlog.md`**, for open decisions and deferred work.
4. **`README.md`**, for anything a consumer needs to know.

Never delete a load-bearing explanation. Move it to NOTES.md.

## Regeneration and the contract

- `scripts/build-sample.nu` generates `samples/dark.html`, `samples/dark-conn-map.html` and `tokens.css`. Never edit
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

The flow, start to finish. Run it as written, whatever else your harness offers on top of it:

```
git switch -c fix/whatever                  # never work on main
nu scripts/maintain.nu bump 1.11.0          # stamps the CSS + README
git add -A && git commit -m 'fix: v1.11.0 - <summary>'
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

**A release also publishes three assets**, and a tag without them is an incomplete release: the
Rider plugin zip, the VS Code vsix, and the themes zip. `scripts/create-themes.nu` builds them.
Check an existing release with `gh release view v<version>` before assuming it shipped whole.

**Only the required checks gate the tag. The rest are advisory.** GitHub attaches a check run
for every workflow that a commit fires, including the workflows GitHub generates itself.
`pages-build-deployment` alone contributes `build`, `deploy` and `report-build-status`. None of
them say anything about the payload. A gate on *every* check once held a tag for a full timeout
because a Pages deploy stalled on GitHub's side, and then refused the tag outright, because a
non-success conclusion stays attached to that SHA. `REQUIRED_CHECKS` near the top of
`scripts/maintain.nu` is the list. Keep it in step with the required checks configured on `main`,
and add to that list rather than widen the gate back to every check.

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
  "Unsupported color format" on an `oklch()` string and aborts init, so no diagram renders. It never
  resolves a `var()` either, so `mermaid.js` carries **two** hex palettes and picks one at init by
  reading the `--mermaid-scheme` token off `:root`. Read the token, never `matchMedia`: the
  forced-light sample pages rewrite an `@media` condition, which the cascade sees and `matchMedia`
  does not. `mermaid-palette.json` holds both sets as `init` and `initLight`, and
  `.github/palette-check.py` keeps both honest against the oklch source.
- Pin every CDN dependency to an exact version, never to a range.

## Verify a rendered claim by rendering it

**A layout or contrast claim about this stylesheet is not verified until a browser has drawn it.**
The repo already drives headless Chromium in `.github/render-modes.py`, and Playwright is the
convention for anything more interactive. Three plausible fixes were once reported as correct from
arithmetic alone and all three were wrong: SVG ink painted outside a root `<svg>` is not scrollable
overflow for any CSS ancestor, so no `overflow` value recovers it; the zoom overlay does not rescue
an escaping viewBox at narrow widths, because it scales the overrun with the diagram; and alpha
compositing must be computed in gamma-encoded sRGB, not linear, or a contrast ratio reads several
tenths too bright.

**When a claim rests on a mitigation, test the mitigation too, not just the defect.**

## Style decisions that are already settled

Do not "fix" these decisions. Each one is deliberate, and this repo re-litigated each one at
least once. [NOTES.md](NOTES.md) holds the failed alternatives for each.

- **Page width is one number.** `--page-width` in `:root` serves both layouts. Do not add a
  second width convention, a breakpoint override, or a full-bleed breakout.
- **Headings use `em`**, so they track the body clamp instead of the fixed root.
- **`h1` and `h2` sit at weight 400.** They are large enough to carry it. Nothing at text size
  may be lighter than body copy.
- **`h3` through `h6` sit at `--label`.** Not `--muted`, which would render a heading dimmer
  than the paragraph it introduces.

### NON-NEGOTIABLE: the wide measure stays. Never cap it

**Prose runs nearly the full window, well past 60 to 75 characters per line. That is the design.
Do not narrow it. Not in any form, not by any mechanism, not behind any measurement.**

This is the single most re-litigated decision in the repo. Four attempts have now shipped or been
rendered, and all four went back out:

1. A `70ch` cap plus a `min-width: 1200px` override to `80vw`.
2. A `100rem` cap.
3. A gutter and a backstop with no proportional term.
4. **A prose-only cap** (`--measure: 40em` on `p`, with `dl.timeline > dd` matched, while tables,
   `pre`, `pre.mermaid`, `.edge-list` and `.recent-groups` kept the full width). This is the
   clever one, because it looks like it dodges what killed the first three. It does not.

**Attempt 4 is the important entry, because its numbers were good.** It held body copy at about 70
characters per line, flat from 1280px to 3440px, against 103 to 144 before it, with no overflow at
any width in any appearance mode. It was rendered, reviewed against the previous behavior, and
rejected anyway. **A capped column beside a wide container reads as stranded copy, and no
per-line-length metric captures that.**

**Therefore: a measurement is not an argument for narrowing the measure, and neither is an
automated design review, a WCAG guideline, a typography rule of thumb or an external style guide.**
The maintainer's judgment on this is the decision and it is closed. If a review flags the long
measure, the correct response is to record that it was flagged and move on. Do not propose a cap,
do not implement one behind a token, a class, a media query, a container query or a consumer
opt-in, and do not raise it again with fresh numbers.

Anything that reduces the rendered width of running prose is in scope for this rule: `max-width`,
`width`, `inline-size`, `columns`, a narrower `--page-width`, a grid track, or a wrapper element.
[NOTES.md](NOTES.md), Width and measure, holds the detail.
