# AGENTS.md: Tufte-Dracula template

Instructions for any agent that works in this repo, whichever harness runs it. These instructions
override default behavior.

**This file is the whole contract for agent behavior here, and the only instruction file in the
repo.** Everything it asks for is a shell command, a file path, or a decision rule. A harness may
wrap a flow below behind a command, a skill or a slash command of its own. Such a wrapper adds an
entry point. **It never adds, relaxes or overrides a rule stated here.** If one appears to, this
file wins. The wrappers that exist, and the rules that bind them, are listed under
[Harness entry points](#harness-entry-points) near the end. Nothing outside this file is required
reading, and **a second instruction file beside this one is a regression**: see that section.

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
Commits in history keep the old em-dash form. No rewrite changes them.

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
  and `AGENTS.md` are **not** inlined. Comment those files as normal.

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
- **Never cite a line number into a generated file.** Any document that points at
  `samples/`, `tokens.css` or any other generated artifact points at a **string to search for**,
  never at a line. A fixture is rewritten on every payload edit, so a line number rots on a change
  that has nothing to do with what it names. `CONTRACT.md` § 2 carried 22 such references and every
  one of them was wrong, undetected, for twelve releases. The form is
  ``(in `samples/dark.html`, search `class="tag-dot"`)`` and `nu scripts/maintain.nu check` parses
  and resolves every one of them.
- **A gate that cannot reach its subject does not get written.** Say so in `NOTES.md` and leave the
  obligation in prose. A check that skips the only instance it could test reports green about a
  question it never asked, which is worse than the honest gap. This is why the `quadrantChart`
  label length is prose and the `.step-node` accent is gated.

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
convention for anything more interactive. Three plausible fixes once seemed correct from arithmetic
alone. All three were wrong. SVG ink outside a root `<svg>` does not create scrollable overflow for
any CSS ancestor. No `overflow` value recovers it. The zoom overlay does not fix an escaping
viewBox at narrow widths. It scales the overrun with the diagram. Alpha compositing must use
gamma-encoded sRGB, not linear. Otherwise, a contrast ratio reads several tenths too bright.

**When a claim rests on a mitigation, test the mitigation too, not just the defect.**

**A behavioural claim about `mermaid.js` or `filter.js` is not verified until the script has run.**
`.github/script-probe.py` drives both of them in the real fixture through the same headless Chrome.
Add an assertion there when you change either file, and mutate the change to confirm the assertion
fails without it. Every other check in this repo reads the payload. This is the only check that runs it. The probe exists because the fixture shipped an inert `input.filter-box` for six releases and a diagram nobody could click for several more. Other checks missed both defects.

**Re-price a decline before you repeat it.** Three entries sat in `backlog.md` for releases on
costs that were simply wrong: a jsdom dependency the repo did not need, a resize listener a media
query replaces, and an `!important` that two real `themeVariables` made unnecessary. A recorded
decline is a cost estimate with a date on it, not a verdict.

## Design Audit Evidence

Every design audit includes performance, responsive usability, accessibility, and standards currency.
For each check, report measured results, limits, and missing inputs. Never report an unrun check as a pass. Recheck current W3C, ISO/IEC, ETSI, and Baseline sources on each run. Add
newly ratified applicable criteria to that audit's report, even if this file and the skill have not
changed. Update either instruction file only through a separate maintainer-authorized change.

### Performance and Stability

- Check the current Core Web Vitals thresholds at web.dev on every audit. The good targets currently are LCP at or below 2.5 seconds, INP at or below 200 milliseconds, and CLS at or below 0.1. Cite the source and access date. For field data, report the 75th percentile and separate mobile from desktop.
- If lab data is collected, label it as lab data and report it separately from field data. Report INP only when valid field data exists.
- Use PageSpeed Insights only for a public deployment and after the user authorizes the external
  request. The `web-vitals` library may measure field data only when the deployed consumer provides
  consent and instrumentation. Do not add it to this static template. If no public URL or CrUX data
  exists, report field data as unavailable.
- The stylesheet is inline. Do not report a separate stylesheet request as render-blocking. Check
  the resources that the fixture actually loads.
- Check images and embedded content for reserved dimensions or aspect ratios that prevent layout
  shifts. Mark ad checks not applicable when no ad slot exists.
- Use browser Coverage to find CSS that fixtures did not exercise. Treat each result as a candidate,
  not proof that the CSS is unused. Do not remove CSS based only on fixtures or a PurgeCSS report.
  Fixtures do not cover every consumer.

### Responsive Usability

- Render representative fixtures at every combination of these viewport widths and heights:
  320, 375, 768, 1024, and 1280 CSS pixels wide, with heights of 568, 768, and 900 CSS pixels.
- Measure page-level horizontal overflow with `scrollWidth` and `clientWidth`. Identify intentional
  overflow inside documented scroll hatches. Check flex and grid stacking against DOM order. Do not
  use a matrix result to narrow prose, change `--page-width`, or add a breakpoint override.
- Measure interactive targets at the rendered size. Report targets below 44 x 44 CSS pixels as a
  usability gap. Keep this result separate from WCAG 2.2 AA, whose 2.5.8 minimum is 24 x 24 CSS
  pixels.
- Test each implemented loading, error, and empty state. Confirm that critical actions remain
  reachable. If a state does not exist, report it as not applicable and do not invent one.
- Check visual hierarchy and typography at each viewport. Preserve the settled type scale and
  heading decisions in NOTES.md.

### Accessibility Checks

At each audit, check current records from the [W3C WCAG standards page](https://www.w3.org/WAI/standards-guidelines/wcag/),
[W3C TR index](https://www.w3.org/TR/), [ISO catalog](https://www.iso.org/search.html?q=ISO%2FIEC%2040500),
[ETSI Human Factors group](https://www.etsi.org/technical-groups/hf/), and [EU Official Journal](https://eur-lex.europa.eu/oj/direct-access.html).
Check WCAG 3.0 draft status at [W3C TR](https://www.w3.org/TR/wcag-3.0/). Cite each source and access date.
Do not treat a draft as a conformance standard or a published EN version as harmonised unless its
Official Journal status confirms that claim. Compare their applicable web-content criteria with the
WCAG sweep and report any difference. Report standards mapping only. Do not claim legal compliance.

When W3C ratifies a new version or changes criteria, add the relevant current Level A and AA
criteria to that audit's report table. Track relevant AAA criteria separately. Include Focus Not
Obscured, Dragging Movements, Target Size (Minimum), Consistent Help, Redundant Entry, and
Accessible Authentication checks where they apply. Track Focus Appearance as AAA, not AA. Mark
criteria for absent features not applicable with a reason. Record version, status, and date checked.
Update this file and the skill only through a separate maintainer-authorized change.

Track WCAG 3.0 changes as draft information only until W3C publishes a Recommendation. Record the
latest draft date and relevant changes. Do not treat proposed outcomes as conformance criteria or
state a predicted Recommendation date as fact.

Do not send non-public content to an external service without user authorization.

Test keyboard navigation by hand. Check Tab, Shift+Tab, Enter, Space, and Escape where relevant.
Confirm visible focus for each interactive element in each appearance mode. Automated results, when available, supplement the current WCAG sweep. They do not replace the palette gate, manual keyboard checks, or rendered contrast checks.

### Modern CSS Evaluation Targets

At each audit, check current MDN or web.dev Baseline status and dates for every feature below.
Report status as of the audit date. Prefer Baseline Widely available features when the audience
includes older browsers. Newly available features need an `@supports` fallback unless current
consumer needs make the fallback unnecessary. In that case, state why. Baseline indicates
interoperability across its core browsers. It does not guarantee support on every device or with
every assistive technology. Do not claim a feature is safe to ship without checking its status and
support needs.

Evaluate these features against actual use and the current stylesheet. Do not add them only to
follow a trend:

- Container queries (`@container`), `:has()`, subgrid, cascade layers (`@layer`), native CSS
  nesting, and `@scope`.
- OKLCH, `color-mix()`, `clamp()`, logical properties, `aspect-ratio`, and Flexbox `gap`.
- Dynamic viewport units (`dvh`, `svh`, `lvh`), scroll-driven animations, View Transitions,
  and `@starting-style`.
- CSS Grid Lanes, `sibling-index()`, `sibling-count()`, CSS Anchor Positioning, and registered
  custom properties (`@property`).

Evaluate mobile-first authoring as current practice, not as a requirement to reverse settled layout
decisions. Record Baseline tier, Newly available date, current use, fallback behavior, and reason
not to adopt each feature.

## Harness entry points

**Every rule in this file reaches every harness through this one file, and nothing in this section
adds a rule.** A harness that ships wrappers, config or skills gets them listed here, so that an
agent which opens `.claude/` can tell an entry point from a rule. **These names exist for
orientation only. Delete `.claude/` and this repo still works exactly as written above.**

### Claude Code

Claude Code reads `AGENTS.md` directly from v2.1.277 on, with no `CLAUDE.md` beside it. Two skills
live in `.claude/skills/`, and they are available to Claude Code only. Each one packages a flow that
this file states in full as plain shell, so a harness without skills loses an entry point and no
capability.

| Skill | Wraps | Invoked by |
| --- | --- | --- |
| [`release`](.claude/skills/release/SKILL.md) | Release flow and three published assets | "release", "cut", "tag", or version |
| [`design-audit`](.claude/skills/design-audit/SKILL.md) | Audits payload changes against NOTES.md and current practice. Checks current standards, Core Web Vitals, responsive usability, WCAG, manual accessibility, and prose rules. Renders changed components and writes a dated report with unapplied patch to `review/`. Never edits the payload | "design audit", "check WCAG compliance", `/design-audit` |

**Neither skill is required to do the work.** `release` is the order in which to call
`scripts/maintain.nu`, and every one of those commands appears above. `design-audit` produces a
report a person reads, and `review/` holds the prior ones as precedent whatever wrote them.

### Rules that bind a harness, its skills and its config

- **A skill, or any bundled design skill, is not authority over a settled decision.** *Style
  decisions that are already settled* is the authority, and its NON-NEGOTIABLE measure rule is
  closed to re-argument from any skill's findings, including a `better-*` review.
- **A skill may only wrap a flow this file states in full, and may not restate it as its own.** Do
  not let a rule come to rest only inside a skill: a harness without skills must lose an entry
  point, never a rule. If a skill's instructions and this file disagree, this file is right and the
  skill is a bug.
- **No skill edits `tufte-dracula.css` or `mermaid.js` without a render.** *Verify a rendered claim
  by rendering it* applies to skill-driven edits exactly as it does to direct ones.
- **`.claude/settings.json` configures the status line and nothing about the payload.** Do not put
  repo policy there. Policy goes in this file, where every harness can read it.
- **A second instruction file beside this one is a regression.** Claude Code's default
  `claude-md-or-agents-md` setting loads a `CLAUDE.md` and then **skips `AGENTS.md` altogether**, so
  a pointer file does not accompany this contract, it replaces it. Do not add one, do not leave a
  stale one, and do not symlink one.

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
