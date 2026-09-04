# CLAUDE.md: Claude Code entry points

**Read [AGENTS.md](AGENTS.md). It carries every rule for working in this repo, and it is
harness-neutral.** This file adds nothing to it. It only records what Claude Code ships on top:
which skills exist, and what they wrap.

**AGENTS.md wins on any conflict.** Nothing here may add, relax or override a rule stated there.
If a skill's instructions and AGENTS.md disagree, AGENTS.md is right and the skill is a bug.

## Skills in this repo

Both live in `.claude/skills/` and are available to Claude Code only. Each one packages a flow that
AGENTS.md already documents as plain shell, so a harness without skills loses an entry point and no
capability.

| Skill | Wraps | Invoked by |
| --- | --- | --- |
| [`release`](.claude/skills/release/SKILL.md) | The full release flow in AGENTS.md, *A tag claims that the contract held*, plus publishing the Rider plugin zip, the VS Code vsix and the themes zip | "make a release", "cut a release", "tag a release", or a named version |
| [`design-audit`](.claude/skills/design-audit/SKILL.md) | A research-and-report pass over current CSS, color, typography, layout, accessibility and CDN-pin practice against the settled decisions in NOTES.md, plus a WCAG Level A/AA sweep. Writes a dated report and an unapplied patch to `review/`. Never edits the payload | "design audit", "check WCAG compliance", `/design-audit` |

**Neither skill is required to do the work.** `release` is the order in which to call
`scripts/maintain.nu`, and every one of those commands is in AGENTS.md. `design-audit` produces a
report a person reads, and `review/` holds the prior ones as precedent whatever wrote them.

## What Claude Code specifically must not do here

- **Do not treat a `better-*` review, or any other bundled design skill, as authority over a
  settled decision.** AGENTS.md, *Style decisions that are already settled*, is the authority, and
  its NON-NEGOTIABLE measure rule is closed to re-argument from any skill's findings.
- **Do not add a skill that edits `tufte-dracula.css` or `mermaid.js` without a render.** AGENTS.md,
  *Verify a rendered claim by rendering it*, applies to skill-driven edits exactly as it does to
  direct ones.
- **`.claude/settings.json` configures the status line and nothing about the payload.** Do not put
  repo policy there. Policy goes in AGENTS.md, where every harness can read it.
