---
name: design-audit
description: Periodic design review for the Dracula-Tufte template. Audits payload changes, researches current CSS and design practice against settled NOTES.md decisions, and writes a dated report and unapplied patch. Rechecks current W3C, ISO/IEC, ETSI, and Baseline status on every run. Includes Core Web Vitals, responsive usability, current WCAG Level A/AA and relevant AAA criteria, manual accessibility checks, and prose-rule sweeps. Renders new or changed components. Use for design audits, CSS pattern reviews, WCAG checks, and refresh reviews.
---

# Design audit: settled decisions vs current practice

This is a research-and-report skill, not an implementation skill. It never edits
`tufte-dracula.css`, `mermaid.js`, or any generated file in the working tree. It never runs
`scripts/maintain.nu bump` or opens a PR. It produces two files under `review/` for the
maintainer to read and decide on. Manual invocation only: nothing schedules this.

**Why this exists:** the maintainer is not strong in CSS and layout, and wants a periodic
check that this repo's hand-tuned decisions haven't fallen behind current practice, backed
by real sources rather than a model's unstated priors.

**Two kinds of finding come out of a run, and the second one turned out to matter more.**
The field moving past a settled decision is rare and slow. The payload drifting away from a
decision NOTES.md already records is common and fast, because most edits here are made by an
agent that did not read NOTES.md first. Step 2 and Step 4 exist for the second kind, and on
the 2026-09-08 run they produced every actionable finding while the six research topics
produced none.

## Step 1: load the decision set and the last audit

Three reads, in this order, before anything else.

1. **`AGENTS.md`, whole.** Short, and every constraint the patch must obey lives there.
2. **`NOTES.md`, the `## Contents` table only.** That table names every section and what
   each one covers. Read it whole so nothing in the file is invisible to this run. Read
   individual sections in Step 3, scoped by the topic map, not up front. If a finding
   turns out to touch a section outside its topic's map, read that section before writing
   the finding up. Never write a finding against a section this run has not read.
3. **The newest `review/*-design-audit.md`, if one exists,** plus `review/declined.md`.
   `ls review/*-design-audit.md | sort | tail -1` gives the file. **Read its header for the
   commit SHA it audited, not just its date.** Step 2 needs the SHA.

Do not rely on partial recall from a prior turn in this conversation. Re-read the files
fresh, since they may have changed since any memory of them was formed.

### What the previous audit is for

A periodic skill that starts blind every time reports the same list every time, and the
maintainer stops reading it by the third run. The previous report changes this run in four
ways:

- **It anchors the window on a commit, not on a date.** See Step 2.
- **It classifies repeats.** A finding already in the last report, with nothing new behind
  it, is marked `Repeat, unchanged since YYYY-MM-DD` in one line. Do not re-argue it, do
  not re-cite it, and do not put it in the patch again.
- **It respects declines.** `review/declined.md` is the ledger of findings the maintainer
  looked at and said no to. NOTES.md records prohibitions this repo paid for in reverted
  commits. It does not record "the audit proposed X and the maintainer declined". Without
  the ledger, the same rejected proposal returns every quarter.
- **Its own claims are re-checkable, and one of them was wrong.** See Step 2, last part.

`review/declined.md` is a single markdown table: `| Date | Topic | Finding | Reason |`. **The
file exists and may hold no rows.** An empty ledger is a real state and it means no finding
has been declined yet, not that the ledger is missing. **This skill only ever appends to it,
and only when the maintainer declines a finding in conversation.** A run never writes to it
on its own, and never removes a row.

A finding that appears in the ledger is out of scope unless a cited source dates from
after the decline. If one does, it is a challenge under Step 5, not an ordinary finding,
and the report must quote the ledger row alongside the NOTES.md passage.

## Step 2: audit the delta before researching anything

**Do this before Step 3.** The research topics ask what the field did. This step asks what
this repo did, and it is where the findings are.

### The window is a commit range

```bash
PREV=<the SHA named in the previous report's header>
git log --oneline "$PREV..HEAD"
git diff --stat "$PREV..HEAD"
git diff "$PREV..HEAD" -- tufte-dracula.css mermaid.js filter.js NOTES.md scripts/ .github/ 'themes/**/*.in'
```

If the previous report names no SHA, fall back to the tag for the version it says it read
(`git rev-list -n1 v1.44.0`), and say in the header which fallback was used. If no previous
report exists at all, the range is the last ten commits that touched the payload.

**The header states the range and the commit count, not only a date:** "since `7e67221`
(v1.44.0), six commits". A one-day window with six commits is a large delta. A two-month
window with no payload commit is nothing, and the run should say so in one line and spend
its effort on Step 4 instead.

### Every added payload line gets four questions

Read the diff, not a summary of it. For each added or changed line in `tufte-dracula.css`,
`mermaid.js`, `filter.js`, or a `themes/**/*.in` slot-map template:

1. **Does NOTES.md document it?** AGENTS.md: "When you make a new decision worth keeping,
   add it to NOTES.md as a decision plus its prohibition." A new component with no NOTES.md
   entry is a finding on its own, and the patch adds the entry.
2. **Does it obey AGENTS.md?** The comment prohibition first, since nothing gates it.
3. **Does it obey a decision NOTES.md already records?** This is the high-yield question.
   Run the Step 4 sweep against the new lines specifically, not only against the sheet as a
   whole.
4. **Does anything render it?** A selector with no fixture instance is drawn by no gate in
   this repo. NOTES.md, Print, states the principle: "A styled class with no instance is an
   untested class."

Classify these the same way Step 3 classifies research findings, with one addition:
**`[Violation of a settled decision]`** for a payload line that contradicts a NOTES.md
passage. That is not a challenge and it never goes under the challenge heading: the decision
still stands and the code broke it, which is the opposite direction. It goes in the patch
like any other bug, and the report quotes the NOTES.md passage it broke.

### Re-check the previous report's own non-repeat claims

Any claim in the previous report that named a file, a selector, or an owner is checkable.
Check the ones this run's delta touches. On 2026-09-07 the report attributed two
`font-family: var(--sans)` declarations to a consumer's generator. The declarations already
appeared in `tufte-dracula.css`, shipped in v1.45.0 a day earlier. Under the repeat rule alone,
a wrong verdict stays wrong forever because the next run is told not to re-argue it. Correct it
in the new report and say which report it corrects.

## Step 3: run one topic at a time

Seven topics. The first five mirror the `better-*` skills the maintainer already runs by
hand (`better-colors`, `better-typography`, `better-layout`, `better-accessibility`,
`better-ui`), so this audit is the layer on top: "what changed in the field since the last
pass", not a repeat of what those skills already check per-session. The sixth covers pinned
CDN dependencies. The seventh covers performance and stability.

Each topic owns a fixed set of NOTES.md sections. The map is fixed so that coverage is
stable run to run, and so the maintainer can tell which sections an audit never looked at.

| # | Topic | Covers | NOTES.md sections |
| --- | --- | --- | --- |
| 1 | Color and contrast | Color tokens, modes, editor themes | Color and the contrast budget, Appearance modes, Print, Mermaid, Editor themes |
| 2 | Typography | Variable fonts, type scale, `text-wrap`, hyphenation | Fonts, Type scale, Italics, Paragraphs and section rhythm |
| 3 | Layout and spacing | Container queries, `:has()`, intrinsic sizing, breakpoints | Width and measure, Tables, Lists, Connections-map layout, Cascade layer |
| 4 | Accessibility | WCAG updates, ARIA patterns, focus handling, keyboard reach | Keyboard and assistive technology, Direction, zoom and growth, Links |
| 5 | Interaction and motion | `prefers-reduced-motion`, transitions, press/hover states | Interaction states, Form follows role |
| 6 | Pinned dependencies | Whether the pinned CDN versions have shipped fixes worth taking | Fonts, Mermaid |
| 7 | Performance and stability | Core Web Vitals, render-blocking resources, layout shift, CSS coverage | Fonts, Mermaid, Fixtures are coverage |

Sections outside the map (Filter, Unclaimed elements, Markdown coverage, Raw HTML and
other generators, Repo layout, Odds and ends) are out of scope for this skill. Say so in one
line in the report so their absence reads as a decision rather than an oversight.

For each topic:

1. **Search first.** Use WebSearch for the specific, current state of practice, not a
   general query. Prefer MDN, web.dev, WCAG/WAI-ARIA specs, caniuse, and browser vendor
   blogs over aggregator content. Two to four sources per topic is enough. Record title
   and URL for every source cited in the report, and list every query run under
   `### Searched` for that topic even when it returned nothing. The next run reads that
   list to avoid re-treading ground. **Scale this to the window.** When Step 2 found a
   short range and the previous report's datings are all inside their own citation
   windows, one query per topic is enough and the repeats carry forward uncited.
2. **Date every browser-support claim.** "Supported now" is not evidence. For any claim
   that a feature is usable, cite its **Baseline status and the date it reached Baseline**
   (web-platform-dx Baseline, or caniuse). A settled decision only becomes challengeable
   because something crossed a line on a date, and the report must name the date so the
   claim stays checkable a year later.
3. **Compare against the actual stylesheet**, not against the audit's memory of it. Read
   the relevant part of `tufte-dracula.css` and the mapped `NOTES.md` sections.
4. **Classify each candidate finding:**
   - **New ground.** NOTES.md has no decision here at all. No conflict, propose freely.
   - **Reinforces a settled decision.** Current practice still agrees with what NOTES.md
     already chose. Say so. A confirmed decision is worth reporting because it shows the repo
     has not drifted.
   - **Repeat.** Already in the previous report, nothing new behind it. One line.
   - **Declined.** In `review/declined.md`, no post-decline source. Drop it silently.
   - **Violation of a settled decision.** The payload contradicts NOTES.md. See Step 2.
   - **Challenges a settled decision.** Current practice now disagrees with a NOTES.md
     entry (a rejected alternative that browser support or a spec change now makes
     viable, for instance). This is the case that needs care, see Step 5.

### Render the component, do not reason about the cascade

AGENTS.md: "A layout or contrast claim about this stylesheet is not verified until a browser
has drawn it." That applies to this skill's findings and to this skill's fixes.

**Any finding or fix touching a component that Step 2 found new or changed gets a probe
render.** Playwright is installed locally and `.github/render-modes.py` shows how the repo
finds Chrome. Build a throwaway page in the scratchpad that carries the **real** stylesheet
body (`tufte-dracula.css` with its first and last lines stripped, which are the `<style>`
wrapper) plus real markup for the component, then measure it:

- **1280px**, for the resting geometry.
- **320px**, for reflow and for target size at the narrow breakpoint.
- **`dir="rtl"`**, for physical-side regressions. Read `borderLeftWidth` against
  `borderRightWidth`, not the declaration.
- **`emulate_media(media="print")`**, for print overrides. Read the computed value on the
  element the declaration actually targets **and** on the element the author probably meant.

Measure the same page again after the patch and put both numbers in the report. A claim with
a before-and-after pair is checkable a year later. "Fixed" is not.

**A slot-map finding gets a probe of its own kind, not a Chromium render.** Editor themes,
Light and dark parity: "Verify against the generated `.icls`, not the template: placeholders
hide which hex actually lands." Run `scripts/create-themes.nu` and `.github/palette-check.py
--dump` in the scratchpad, and quote the resolved hex per slot, before and after any patch
touching a `themes/**/*.in` file.

**A fix is not verified until the probe shows it.** On 2026-09-08 the first version of a
narrow-width column override was inert: the override sat in a media block above the rule it
meant to beat, a media query adds no specificity, and the base rule won on source order. The
arithmetic was right and the rendering was wrong. NOTES.md records the same trap twice
already, for the `.scorecard` container query and for the `@media (hover: hover)` position.

### Fixed responsive usability sweep

Run this sweep on every audit. Test `samples/dark.html` and
`samples/dark-conn-map.html` at every combination of these CSS viewport widths and heights:

- Widths: 320, 375, 768, 1024, and 1280 pixels.
- Heights: 568, 768, and 900 pixels.

Record fixture, viewport, `document.documentElement.scrollWidth`,
`document.documentElement.clientWidth`, and any intentional overflow. Check page-level
horizontal scrolling at every size. Inspect flex and grid stacking against DOM order. Separate
page overflow from scrolling inside documented table, code, math, and diagram hatches. Do not
treat a long measure or known hatch as permission to narrow prose, change `--page-width`, or
add a breakpoint override.

Measure each interactive target from its rendered rectangle. Report targets smaller than
44 x 44 CSS pixels as a usability gap. Keep this result separate from WCAG 2.2 AA: criterion
2.5.8 has a 24 x 24 CSS pixel minimum, subject to its size or spacing exception. The 44 x 44
check does not change that conformance result.

Check visual hierarchy, heading order, and typography at each viewport. Test every loading,
error, and empty state that the fixtures implement, and confirm that critical actions remain
reachable in each state. If the template has no such state, report that fact. Do not invent
states or controls. Add the viewport results and separate 44 x 44 findings under
`## Responsive usability sweep` in the report.

### Topic 4 in particular: the WCAG conformance sweep

The rest of this skill asks "has current practice moved past a settled decision." Topic 4
also asks a narrower, harder question every run: **does this repo currently fail a
WCAG success criterion, right now, regardless of what NOTES.md decided.** A violation is not
a style opinion. It goes in the patch like any other bug, unless the fix contradicts a settled decision. In
that case, make it a Step 5 challenge instead of an ordinary finding.

**First, find the current standards.** Check the W3C WCAG standards page and W3C TR index for
the latest WCAG **Recommendation** and its revision date. Check the latest WCAG 3.0 status
separately. Also check the current ISO/IEC 40500 edition and ETSI EN 301 549 version and
Official Journal status. Cite sources and the date checked. Do not infer a legal requirement or
claim legal compliance from a standards listing.

WCAG 2.2 became a Recommendation on October 5, 2023. W3C published a revision on December 12,
2024. Use current W3C records to confirm these dates and whether a newer Recommendation now
exists. If W3C has ratified a newer version, audit its applicable Level A and AA criteria, note
which criteria changed, and update the fixed table below in the report. Do not treat the table
below as a ceiling on the current Recommendation. Track relevant AAA criteria in a separate
enhanced review, not as AA failures.

Track WCAG 3.0 as draft work only. Record the latest Working Draft date and material changes
since the prior audit. Do not report proposed outcomes as conformance criteria. As checked on
2026-09-30, W3C listed a 2026-09-10 Working Draft. The 2026-03 requirements note is not the
WCAG 3.0 Working Draft. Recheck W3C's publication history on every audit. Do not state a
predicted Recommendation date as fact.

**Second, run the relevant A and AA criteria in the fixed table below**, plus any current criteria
that W3C added or changed. The table keeps coverage stable from run to run and shows what has not
been checked. It covers criteria relevant to this static, no-build CSS and vanilla-JS template.
If the current Recommendation adds or changes a relevant criterion, add it to this run's table and
report it, even before this skill's table changes.
This template has one filter input, no audio or video, no authentication flow, and no multi-step
form process. Mark criteria that require absent content as `Not applicable` with a brief reason.
Do not omit a criterion from the table just because it is not applicable.

**Re-evaluate every row against whatever Step 2 found new**, not only against the parts of
the sheet a previous run already swept. A component that has never been swept has never
passed.

| Criterion | Level | Check against |
| --- | --- | --- |
| 1.1.1 Non-text Content | A | `alt` text on `img`, `accTitle`/`accDescr` on mermaid fences, SVG `title`, decorative pseudo-element `content: "…" / ""` |
| 1.3.1 Info and Relationships | A | Semantic table roles, heading hierarchy, `dl`/`dl.timeline`, list semantics |
| 1.3.2 Meaningful Sequence | A | DOM order vs visual order, especially `body.conn-map`'s flex reorder and any multicol block |
| 1.4.1 Use of Color | A | `.verdict`, `.verified`/`.unverified`/`.correction`: color never the only cue |
| 2.1.1 Keyboard | A | Mermaid zoom button, `.table-scroll`, `pre`/`math` sideways-scroll hatch |
| 2.1.2 No Keyboard Trap | A | The zoom dialog has a keyboard method to move focus away from it. Check Escape behavior separately as a dialog interaction |
| 2.4.2 Page Titled | A | `<title>` present and distinct per fixture |
| 2.4.3 Focus Order | A | Tab order preserves meaning and operability. It need not match visual order exactly |
| 2.4.4 Link Purpose (In Context) | A | No bare "click here". The outbound-link arrow has alt text |
| 2.5.3 Label in Name | A | Visible button text is a prefix of its `aria-label` (the zoom button) |
| 3.1.1 Language of Page | A | `lang="en"` (or a real value) on `<html>` in every fixture |
| 3.2.1 On Focus | A | Focusing an element never triggers a context change |
| 3.2.2 On Input | A | The filter box never navigates or submits on input |
| 4.1.2 Name, Role, Value | A | Custom widgets (`.table-scroll` region, mermaid dialog, zoom button) |
| 1.4.3 Contrast (Minimum) | AA | Topic 1's palette gate covers this. Cross-reference it and name any ground the gate cannot reach |
| 1.4.4 Resize Text | AA | 200% zoom and reflow. Check current behavior against NOTES.md's 400% exception |
| 1.4.10 Reflow | AA | No two-dimensional scroll at 320 CSS px / 400% zoom outside opt-in hatches. Measure `scrollWidth` against `clientWidth`, do not eyeball it |
| 1.4.11 Non-text Contrast | AA | Focus rings, borders, and `.verdict`/`.badge` outlines against their grounds. Check forced-colors rules against actual components |
| 1.4.12 Text Spacing | AA | Layout survives user style overrides for line-height/letter-spacing/margins |
| 1.4.13 Content on Hover or Focus | AA | Any hover-revealed content: dismissable, hoverable, persistent |
| 2.4.6 Headings and Labels | AA | Headings and the filter label describe their section/purpose |
| 2.4.7 Focus Visible | AA | Every interactive element has a visible focus indicator in every mode |
| 2.4.11 Focus Not Obscured (Minimum) | AA | Sticky headers, overlays, and other author-created content do not fully hide focused controls |
| 3.2.3 Consistent Navigation | AA | When repeated navigation exists, it keeps the same relative order |
| 3.2.4 Consistent Identification | AA | Components with the same function are identified consistently |
| 2.5.7 Dragging Movements | AA | A dragging feature has a single-pointer alternative when the criterion applies |
| 2.5.8 Target Size (Minimum) | AA | 24 x 24 CSS pixels or a WCAG 2.2 exception. Measure from a render and check the spacing exception |
| 3.2.6 Consistent Help | A | Repeated help mechanisms keep the same relative order |
| 3.3.7 Redundant Entry | A | Previously entered information is available in the same process |
| 3.3.8 Accessible Authentication (Minimum) | AA | Authentication avoids cognitive function tests unless an exception applies |
| 4.1.3 Status Messages | AA | `filter.js`'s `role="status"` result count: `aria-live` wired correctly |

For SC 2.5.8, check every exception. The inline exception covers a target in a sentence or a
target limited by the line height of surrounding non-target text. The spacing exception passes
only when a 24px circle centered on each undersized target touches neither another target nor the
circle around another undersized target. Also check the equivalent-control, user-agent-control,
and essential-presentation exceptions.

**Relevant AAA criteria, tracked separately:**

| Criterion | Level | Check against |
| --- | --- | --- |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | No part of the focused control is hidden by author-created content |
| 2.4.13 Focus Appearance | AAA | Focus indicator area and contrast meet the criterion's enhanced requirements |
| 2.5.5 Target Size (Enhanced) | AAA | Interactive targets meet 44 x 44 CSS pixels, subject to the criterion's exceptions. Also report the requested 44 x 44 usability target in the responsive sweep |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | Authentication avoids cognitive function tests, subject to exceptions. Mark not applicable when no authentication exists |

**Out of scope, stated once:** 1.2.x (no audio/video), 2.2.x (no timers or sessions), 2.3.x
(no flashing content), 2.4.1 Bypass Blocks and 2.4.5 Multiple Ways (single-document
template, no repeated site-wide navigation block to bypass), 2.5.1/2.5.2/2.5.4 (no custom
pointer gestures or motion-actuated controls), and 3.1.2 Language of Parts (single-language
prose by convention. Flag mixed-language fixtures without language markup). Criteria about
error prevention, suggestions, and correction in 3.3.1 through 3.3.6 are not applicable
because the filter has no form submission or required fields.

**Classify every row, do not skip one silently:**

- **Pass.** State the evidence briefly. A passing sweep is worth reporting. This follows the
  reasoning for a `[Reinforces]` finding elsewhere in this skill.
- **Accepted gap.** NOTES.md already states, in prose, that this repo knowingly does not
  meet it (the 400% sideways-scroll line under Width and measure is exactly this shape).
  Quote the passage. Confirm it describes current behavior. If behavior has changed, state
  whether the gap closed or remains open.
- **Violation.** Fails the criterion and NOTES.md never said so. This is the case Topic 4
  exists to catch. State the failure concretely (a selector, a missing attribute, a
  reproducible interaction), and put a mechanical fix in the patch if one exists, exactly
  like any other Topic 4 finding. If the only fix available would reverse a NOTES.md
  decision, this becomes a Step 5 challenge instead, same rule as everywhere else in this
  skill. If the only fix available is a design judgment rather than a mechanical one, say
  so in the row and leave it out of the patch, with the reason stated.
- **Not applicable.** For a criterion in the sweep table, state the absent feature and reason in
  its row. Keep the explicit out-of-scope summary for criteria outside the fixed table.

Report this sweep under its own `## WCAG conformance sweep` heading in the audit report,
as a table with one row per relevant criterion in the current Recommendation. Include criteria
from the table above and any current changes. Use (Criterion, Level, Status, Evidence) columns.
Report relevant AAA criteria in a separate table. Topic 4's ordinary findings still cover
everything this sweep does not, including ARIA authoring-practice shifts and WCAG 3 draft
movement.

### Manual accessibility checks

Do not send local or private fixture content to an external service. If automated contrast results are available, treat them as a supplement to Topic 1's palette gate and the rendered contrast checks, not as a replacement.

Test keyboard navigation by hand in each appearance mode. Use Tab and Shift+Tab to visit
each interactive element. Use Enter, Space, and Escape where the control supports them.
Confirm every element has a visible focus indicator, and confirm that keyboard use keeps
critical actions reachable. Report these results under `## Accessibility and keyboard checks`.
Automated checks, when used, do not prove full WCAG conformance.

### Topic 6 in particular

`AGENTS.md` mandates an exact pin, never a range, for every CDN dependency. Read the pinned
versions out of the files rather than from memory:

```bash
rg -o '[a-z0-9@/-]+@[0-9.]+' tufte-dracula.css mermaid.js | sort -u
```

For each, report the current release (`npm view <pkg> version time.modified`), whether
anything between the two is a rendering or security fix, and whether the upgrade is worth
taking. **Do not put a Mermaid bump in the patch:** `nu scripts/maintain.nu mermaid <version>`
is the supported path and it touches generated files. Name the command in the report and stop
that part there.

**Also check provenance, not only freshness.** Every jsDelivr URL in the two files above
loads through a mechanism with no `integrity` attribute available to it: `@font-face src:
url()` has no SRI hook in any browser, and a bare-specifier ESM `import` of a remote URL has
no `integrity` hook either, current npm-package or import-map metadata aside. State this
plainly rather than proposing an `integrity=` attribute that cannot attach to either
construct. What is checkable:
- The URL pins an exact version (already covered by the exact-pin row in Step 4's table,
  cross-reference rather than re-run).
- jsDelivr serves the npm-published tarball unmodified at a versioned path, so the actual
  supply-chain question is whether the **npm package itself** has a provenance attestation
  (`npm view <pkg> dist.attestations` or the npm registry's provenance badge), not whether
  the CDN edge is trusted.
- Whether self-hosting the four font files or Mermaid bundle is worth the tradeoff NOTES.md
  already weighed. Read that passage before proposing self-hosting again. If NOTES.md already
  declined it, mark it `[Repeat]` or match `review/declined.md`. Do not call it new ground.

### Topic 7 in particular: performance and stability

Search current web.dev guidance for Core Web Vitals. List the queries and sources under Topic 7's
`### Searched` heading. Verify current thresholds from web.dev on each audit. The current good
targets are LCP at or below 2.5 seconds, INP at or below 200 milliseconds, and CLS at or below
0.1. Cite the source and access date rather than assuming these values remain current.

Lab measurements are optional. If collected, label results as lab data and record the tool,
browser and version, fixture, viewport, device emulation, throttling, and results. Report field
data separately by mobile and desktop at the 75th percentile. The `web-vitals` library may measure
field data when a deployed consumer has consent and instrumentation. Do not add the library to this
static template. Total Blocking Time is not INP. Report INP as unavailable unless valid field data
exists. If a public deployment and user authorization are both available, PageSpeed Insights may
supply lab results and CrUX field data. Report those data types separately. If no public URL or
CrUX data exists, record field data as unavailable. Never send a local or private page to
PageSpeed Insights.

Check the resources that each fixture loads for render-blocking behavior. This repository inlines
its stylesheet, so do not describe it as a separate stylesheet network request. Check images and
embedded content for reserved width and height or an aspect ratio. The fixtures have no ad slot.
Report ad layout shift as not applicable unless a future fixture adds one.

Use browser DevTools Coverage on both fixtures, including implemented interaction and
appearance states. Report CSS that the tested page did not exercise as a candidate only.
A coverage result cannot show that no consumer uses a CSS rule. Compare candidates with
consumer-facing rules in NOTES.md and all known inputs before proposing removal. Do not use
PurgeCSS output or fixture coverage alone to remove CSS. Do not add a dependency for this
audit. Put available metrics, render-blocking resources, layout-shift sources, and CSS
coverage candidates under `## Topic 7: Performance and stability` in the report.

## Standards and feature currency

Check this section on every audit. Use the audit date as the status date. Do not reuse a prior
report's status without checking the source again. A standard's status can change after a report.

| Area | Current source to check | Report |
| --- | --- | --- |
| WCAG Recommendation | W3C WCAG page, W3C TR index, current Recommendation | Version, status, dates, changed criteria |
| WCAG 3.0 | Current W3C TR draft and publication history | Latest draft type and date, changes relevant to this template, and explicit draft status |
| ISO/IEC 40500 | Official ISO catalog | Current edition, publication status, and applicable criteria that differ from WCAG |
| EN 301 549 | ETSI publication and work-item records, EU Official Journal | Version, date, delivery, OJ citation, criteria that differ from WCAG |
| Baseline definition | web.dev Baseline or MDN Baseline glossary | Definition checked, status date, and date each evaluated feature became Newly available |

Report this as `## Standards status`. Add `### Searched` with every query, source title, URL, and
access date. State that the audit maps technical criteria only. Do not claim that a template
complies with the EU Accessibility Act, Section 508, or any other law. Do not infer harmonisation
from publication or delivery alone. WCAG 2.2 became a W3C Recommendation on October 5, 2023, and
has 86 active success criteria. Verify the current version and count in W3C sources each run
instead of treating either fact as permanent.

### Modern CSS Baseline review

Check every feature below against current MDN or web.dev data. Record one row per feature under
`## Modern CSS Baseline review`, with its Baseline tier, Newly available date if applicable,
current use in this stylesheet, and fallback or reason not to adopt it. Use `Not Baseline` when
no Baseline status exists. Newly available features need an `@supports` fallback unless current
consumer needs make the fallback unnecessary. In that case, state why. `@supports` tests syntax
support. It does not prove full interoperability or accessibility. Widely available is a safer
default, not a guarantee for all users. Do not propose a feature only because it crossed a
Baseline threshold.

| Feature target | CSS or platform feature |
| --- | --- |
| Container queries | `@container` |
| Relational selector | `:has()` |
| Subgrid | `grid-template-rows: subgrid` |
| Cascade layers | `@layer` |
| Native CSS nesting | CSS nesting |
| Scoped styles | `@scope` |
| Perceptual colors | `oklch()` and `color-mix()` |
| Fluid sizing | `clamp()` |
| Logical properties | `margin-inline`, `padding-block`, and related properties |
| Aspect ratio | `aspect-ratio` |
| Flexbox gap | `gap` in Flexbox |
| Dynamic viewport units | `dvh`, `svh`, and `lvh` |
| Scroll-driven animation | `animation-timeline: scroll()` and related timeline properties |
| View Transitions | View Transitions API |
| Entry animation | `@starting-style` |
| CSS Grid Lanes | Native masonry layout |
| Sibling index functions | `sibling-index()` and `sibling-count()` |
| Anchor positioning | CSS Anchor Positioning |
| Registered custom properties | `@property` |

Also evaluate mobile-first authoring as a current practice. Do not treat it as a requirement to
reverse the repository's settled layout decisions. Record current sources, queries, status dates,
and browser Baseline dates under `### Searched` for the relevant topics. Recheck these targets on
every audit, including targets not currently used by the stylesheet.

### Step 3 report format

The report has one section for each of the seven topics, followed by `## Standards status`,
`## Modern CSS Baseline review`, `## Responsive usability sweep`, `## Accessibility tool and
keyboard checks`, and `## WCAG conformance sweep`. Add a separate AAA table under
`## WCAG conformance sweep`. Include every relevant A and AA criterion from the current
Recommendation. Mark absent features not applicable with a reason. Add `### Searched` under
each research topic and include every query and source used for the standards and feature review.

## Step 4: the ungated-rules sweep

**Why this exists.** AGENTS.md: "a gate is the only thing that keeps a prose rule alive in a
repo where most edits are made by an agent." Several rules in AGENTS.md and NOTES.md have no
gate behind them, so `nu scripts/maintain.nu check` prints `Contract OK` while the payload
breaks them. A five-line block comment inside `@media print` shipped in v1.41.0 and reached
every consumer page for four releases while three design audits read past it. This table is
fixed so that cannot happen a fourth time.

Run every row. The commands are starting points, not the whole check: read the hits.

| Rule | Source | Check | 
| --- | --- | --- |
| No comment in `tufte-dracula.css` or `mermaid.js`. **Both exceptions are CSS-only** (line 2's version stamp, the `/* was #rrggbb */` notes), so `mermaid.js` must have zero comments | AGENTS.md | `rg -n '/\*' tufte-dracula.css \| rg -v 'was #'` returns line 2 only. Then `rg -n -e '/\*' -e '^\s*//' mermaid.js` returns nothing |
| Every `var(--x)` resolves to a declared token or has a fallback | NOTES.md, Progressive disclosure | Set difference. Match `--x:` anywhere because component tokens count. Exclude references with fallback commas. Six references outside `:root` resolve on `HEAD`, and all six are deliberate |
| Sides are logical, never physical | NOTES.md, Direction, zoom and growth | `rg -n 'border-left\|border-right\|padding-left\|padding-right\|margin-left\|margin-right' tufte-dracula.css` returns nothing, except a deliberate physical fallback stated in NOTES.md (the sidenote `float`) |
| Every `:hover` rule sits inside `@media (hover: hover)` | NOTES.md, Interaction states | Every line number from `rg -n ':hover' tufte-dracula.css` falls inside that block's range. A selector pairing `:hover` with `:focus-visible` in one rule is the usual way this breaks |
| Decorative pseudo-element content has an alt-text twin | NOTES.md, Links | Check each string-valued `::before` and `::after`. The twin must follow its base declaration |
| A selector not represented in a fixture has a documented reason or remains a candidate, not presumed unused | NOTES.md, Print, and Fixtures are coverage | Compare class selectors against `scripts/build-sample.nu` and NOTES.md exceptions. Do not remove selectors only because fixtures did not exercise them |
| Mermaid colors are hex, never `oklch()` and never `var()` | AGENTS.md | `rg -n 'oklch\|var(' mermaid.js` returns nothing in a color position |
| Exact CDN pin, never a range | AGENTS.md | No `^`, `~` or `latest` in a jsDelivr URL |
| Never cite a line number into a generated file | AGENTS.md | `maintain.nu check` gates search-string pointers. Confirm each new document pointer uses this form |
| New composite grounds outside palette-check coverage have a NOTES.md entry | AGENTS.md | Add a gate or document grounds not covered by `--surface`, `--code-bg`, or `--surface-alt` |

Status per row is `Pass`, `Violation` or `Not reachable this run` (say why). Report it under
its own `## Ungated-rules sweep` heading.

### A finding a gate could catch should become a gate

The first two rows of that table are mechanically decidable in a few lines of Nushell, and
they caught two real defects on the 2026-09-08 run. **This skill may put a `maintain.nu`
gate in the patch**, and should when a row is cheap to mechanize: `scripts/` is a source
file, the patch already touches source files, and Step 7 regenerates and runs `check` in a
worktree so a broken gate fails there rather than in the maintainer's tree.

Two limits on that:

- **A gate that cannot reach its subject does not get written.** AGENTS.md is explicit, and
  it is why the `quadrantChart` label rule is prose. Prefer an honest NOTES.md paragraph over
  a check that reports green about a question it never asked.
- **A gate that would fail on `HEAD` goes in the patch together with the fix it demands**, or
  it does not go in at all. A patch that adds a red check is a patch nobody can apply.

## Step 5: settled decisions can be challenged, but only loudly

NOTES.md exists because several past changes were correct on paper, shipped, and had to be
reverted. This skill is allowed to propose reopening a settled decision, but never
quietly. Every such finding in the report must:

- Quote the exact NOTES.md passage being challenged, with its section heading.
- State what changed since that passage was written (a spec landing, a browser reaching
  Baseline, a measurement technique becoming available) with a cited source and a date.
- Sit under a `## Challenges a settled decision` heading, separate from ordinary findings.
- Carry the line: `Requires maintainer sign-off before this touches NOTES.md or the
  stylesheet.`

**A challenged finding never enters the patch.** Not in this run and not in any run. Step 8
ends the invocation, so sign-off cannot happen inside a run that raised the challenge, and
a patch drafted "in case" is a patch nobody agreed to. If the maintainer signs off later,
that is a separate ask in a separate turn, and they ask for the change directly through the
normal contract flow.

**Do not confuse a challenge with a violation.** A challenge says the decision may be wrong
now. A violation says the code broke a decision that still stands. A violation goes in the patch. A challenge never does.

Findings that do not challenge a settled decision go into the draft patch.

## Step 6: write the two artifacts

Get today's date once (`date +%F`) and reuse it for both filenames. Do not call `date` separately for each file. A run that crosses midnight could produce mismatched pairs. A
second run on the same day overwrites the first: that is intended, one audit per day is
the unit.

- `review/YYYY-MM-DD-design-audit.md`: the report. A header naming **the commit range and
  commit count** from Step 2 and the previous report it read, the Step 2 delta findings, one
  section per topic, findings classified per Step 3, `### Searched` per topic, sources cited
  inline with dates, the `## Standards status` report, the `## Modern CSS Baseline review`, the
  responsive usability sweep, the accessibility tool and keyboard checks, the current WCAG
  conformance sweep with a separate relevant AAA table, the performance and stability topic,
  the ungated-rules sweep, the challenged-decisions section (if any) clearly separated per
  Step 5, one line naming the out-of-scope NOTES.md sections, and the Step 7 verification result.
- `review/YYYY-MM-DD-design-audit.patch`: a unified diff against `HEAD` covering only the
  non-challenging findings the maintainer would plausibly want. A draft to review, not
  something to apply automatically. **If there are no such findings, do not write an empty
  patch file.** Say "no patch: nothing to propose" in the report instead.

The report and patch never edit `AGENTS.md` or this skill. Report audit-process gaps separately.

The patch must obey every constraint in AGENTS.md: no comments added to
`tufte-dracula.css` or `mermaid.js`, no em-dash or en-dash anywhere, hex-only in
`mermaid.js`, the `<style>` and `<script>` wrapper contract intact. Step 7 proves that
mechanically rather than trusting it.

**The patch touches source files only.** It never changes `samples/*.html` or `tokens.css`.
The generator creates those files. Step 7 regenerates them in a throwaway worktree to test the
patch. If the maintainer accepts it, they regenerate through the normal contract flow.

`NOTES.md` and `scripts/` are source files and the patch may touch both. Step 2 findings about undocumented components require a NOTES.md entry. Step 4 findings that a short script can check require a gate.

**The easiest way to author the patch is a second worktree.** Edit there, regenerate there,
run `check` there, then `git diff HEAD -- <source files only>` out of it. That keeps the real
tree clean, which is this skill's hardest rule, and it means the diff you emit is the diff
you already tested. Remove both worktrees when done.

Create `review/` if it does not exist. Do not touch any other file in the working tree.

## Step 7: verify the patch mechanically, or say it is unverified

AGENTS.md: "a gate is the only thing that keeps a prose rule alive in a repo where most
edits are made by an agent." A patch this skill only *claims* obeys the contract is worth
less than no patch, because the maintainer pays to discover otherwise.

Skip this step only when Step 6 wrote no patch.

```bash
D=$(date +%F)
git worktree add --detach /tmp/design-audit-verify HEAD
git -C /tmp/design-audit-verify apply "$PWD/review/$D-design-audit.patch"
nu /tmp/design-audit-verify/scripts/build-sample.nu     # regenerate INSIDE the worktree
nu /tmp/design-audit-verify/scripts/maintain.nu check   # must print "Contract OK"
git worktree remove --force /tmp/design-audit-verify
```

Four things about that sequence, each of which has one way to get wrong:

- **The worktree is at `HEAD`, so the patch must apply to `HEAD`.** Generate the diff
  against `HEAD`, not against a dirty working tree.
- **`build-sample.nu` runs before `check`, not after.** `check` regenerates internally and
  fails on `STALE` if the fixtures do not match the sources. A patch that changes the CSS
  and no fixtures always trips that. Regenerating first is what makes the staleness gate
  say something real: it now proves the patch survives regeneration.
- **Everything happens in the worktree.** The real tree keeps its generated files
  untouched, which is the rule Step 6 states.
- **`git worktree remove` runs even when `check` fails.** Do not leave the worktree behind.

Then run the two scans `check` cannot do for you.

The first covers this skill's own output files, which the dash gate misses because it
reads `git ls-files` and these are not tracked yet:

```bash
rg -c -e '\u{2014}' -e '\u{2013}' review/$D-design-audit.*   # must find nothing
```

The second covers the rule with no gate behind it. **`maintain.nu check` does not detect a
comment added to `tufte-dracula.css` or `mermaid.js`.** A patch that adds one passes
`Contract OK` and ships a comment into every page every consumer ever renders, which is the
single hardest prohibition in AGENTS.md. Read every added line of the patch yourself:

```bash
rg -n '^\+' review/$D-design-audit.patch | rg -e '/\*' -e '\*/' -e '//'   # must find nothing
```

That regex over-matches (a `//` inside a URL trips it, and a `#` comment added to a Nushell
script is permitted), so read the hits rather than trusting the count. Zero hits passes. Any
hit needs an eye on it.

Third, **re-run the probe render from Step 3 against the patched stylesheet** and record the
after numbers beside the before ones. `Contract OK` says the contract holds. It says nothing
about whether the fix took effect.

Record the outcome in the report as one of exactly three verdicts:

- `Verified: patch applies to HEAD and Contract OK after regeneration.`
- `FAILED: <the shortest decisive line of output>.` Fix the patch and re-verify, or drop
  the offending finding to the report body and say why.
- `Unverified: <reason>.` Use this only for a missing local dependency, `check` runs
  `render-modes.py`, which needs a local Chromium. A missing browser is an environment
  gap, not a bad patch, and calling it a failure is a false report. Never write
  `Verified` for a run where `check` did not conclude.

## Step 8: Report Back, Then Stop

End by telling the maintainer where the files landed, the verification verdict, and one
line of counts: findings total, how many are violations of a settled decision, how many are
new, how many are repeats, how many challenge a settled decision, and how many evidence
checks were unavailable. Stop there.

Applying the patch, updating NOTES.md, appending to `review/declined.md`, bumping a CDN
pin, or cutting a release are separate asks with their own flow (see the `release` skill
and AGENTS.md's regeneration section). This skill does not chain into any of them.

## Rules with no exception

- **Never edit `tufte-dracula.css`, `mermaid.js`, `filter.js`, `samples/*.html` or
  `tokens.css` in the working tree.** The only place this skill applies a change is a
  throwaway worktree it removes in the same step.
- **A challenged decision never enters the patch.** See Step 5. A violated decision always
  does.
- **Never write `Verified` for a `check` that did not conclude.** Unverified is a real
  verdict and it is the honest one.
- **Never write to `review/declined.md` unprompted, and never remove a row from it.** It
  is the record of what the maintainer already decided.
- **Never claim a browser feature is usable without a Baseline date.**
- **Never claim a layout, contrast or target-size fix works without a render that shows
  it.** Arithmetic has been wrong here four times on record.
