# Declined findings

Findings from a `design-audit` run that the maintainer read and said no to. The audit skill
reads this file in Step 1 and drops a matching finding silently, so a rejected proposal
does not return every quarter.

`NOTES.md` is not this file. NOTES.md records the prohibitions this repo paid for in
reverted commits, each one a thing that shipped and went back out. This file records a
proposal that never shipped because the maintainer turned it down.

**Rules for this file:**

- Only the maintainer's decline in conversation puts a row here. A run never adds one on
  its own initiative.
- A run only appends. Nothing removes a row.
- A declined finding comes back into scope only when a cited source dates from **after** the
  decline. It returns as a challenge, not as an ordinary finding, and the report must quote
  the row below alongside the NOTES.md passage.
- **An empty table is a real state.** It means nothing has been declined yet.

**Two things do not belong here.** The wide measure is one: AGENTS.md, *NON-NEGOTIABLE: the
wide measure stays*, closes it to re-argument from any skill's findings, which is stronger
than a ledger row. A defect the maintainer chose not to fix yet is the other: that is
`backlog.md`.

| Date | Topic | Finding | Reason |
| --- | --- | --- | --- |
