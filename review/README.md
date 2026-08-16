# review/

Dated output from the `design-audit` skill (`.claude/skills/design-audit/SKILL.md`).

Each run writes a report, and a patch only when it has something to propose. Both are
stamped with the date the run started:

- `YYYY-MM-DD-design-audit.md`: the report. Findings against current CSS/color/
  typography/layout/accessibility/CDN-pin practice, checked against the decisions already
  recorded in `NOTES.md`. The header names the research window it covered and the previous
  report it read, so a run reports what changed rather than the same list again.
- `YYYY-MM-DD-design-audit.patch`: a draft diff for the non-controversial findings, against
  `HEAD`, touching source files only. No patch file is written when there is nothing to
  propose. Nothing here is applied automatically. Review it, then apply by hand.

Every patch carries a verification verdict in its report, from applying it in a throwaway
git worktree, regenerating there, and running `nu scripts/maintain.nu check`:

- `Verified`: the patch applies to `HEAD` and the contract holds after regeneration.
- `FAILED`: it does not. The report says which line failed.
- `Unverified`: `check` could not conclude locally, usually a missing Chromium for
  `render-modes.py`. An environment gap, not a verdict on the patch.

`declined.md` is the ledger of findings the maintainer read and said no to. `NOTES.md`
records the prohibitions this repo paid for in reverted commits; it does not record a
proposal that was simply turned down. Without this file the same rejected finding returns
every run. The skill only appends to it, only when a decline happens in conversation, and
never removes a row.

A finding that challenges a decision already settled in `NOTES.md` is called out
separately in the report and never enters the patch, in any run. It needs explicit
maintainer sign-off, which is a separate ask in a separate turn. Files in this folder are
tracked in git so the audit history itself is part of the repo's record, not just its
conclusions.
