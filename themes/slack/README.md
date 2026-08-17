# Dracula-Tufte (muted): Slack sidebar theme

Slack has no theme file. Custom Colors takes one string: eight `#rrggbb` values,
comma-separated, no spaces, in a fixed order. This file exists because that string
has to be copied by hand, so it needs a written source of truth instead of a
regenerated one.

## The string

```
#1e1f29,#282a36,#f081ba,#f8f8f2,#343746,#f8f8f2,#6dcd93,#ff7a7b
```

## Install

Slack desktop or web: profile picture, **Preferences**, **Themes**, **Custom Theme**,
paste the string above, **Save**.

## Not generated

Every other file under `themes/` is a `.in` template that `scripts/create-themes.nu`
renders and `nu scripts/maintain.nu check` gates against drift. This one is not: the
output is a single line with no file format, so a template and a CI check would cost
more than they save. Hex values below are copied from `.github/palette-check.py --dump`,
the same source the gated themes render from. Re-run that dump and re-copy the eight
values by hand if the `:root` palette changes.

## Role mapping

| Slot | Hex | Token | Prose role |
| --- | --- | --- | --- |
| Column BG | `#1e1f29` | `--surface-alt` | secondary surface (`--code-bg`'s neighbor) |
| Menu BG | `#282a36` | `--surface` | page background |
| Active Item | `#f081ba` | `--pink` | `h1`, active-tab underline |
| Active Item Text | `#f8f8f2` | `--on-surface` | body copy |
| Hover Item | `#343746` | `--code-bg` | inline code / raised surface |
| Text Color | `#f8f8f2` | `--on-surface` | body copy |
| Active Presence | `#6dcd93` | `--green` | inline `code`, success/verified |
| Mention Badge | `#ff7a7b` | `--red` | errors, deleted lines |

Active Item takes `--pink` because the stylesheet already spends that color on the
active-tab underline in the editor themes ([`../rider/README.md`](../rider/README.md)
§ Role mapping), the closest existing role to "this one is selected." Active Presence
and Mention Badge borrow `--green` and `--red` for their universal meaning
(online, alert) rather than for a prose role: neither slot has a stylesheet
counterpart.
