# Dracula-Tufte (muted): Zed theme

One file, schema `v0.2.0`: 148 style keys, 43 syntax slots, 7 player colours.

## Generated, do not hand-edit

`scripts/create-themes.nu` writes `dracula-tufte.json` from `dracula-tufte.json.in`.
Edit the template.

```sh
nu scripts/create-themes.nu
nu scripts/create-themes.nu --check
```

## Install

```sh
cp themes/zed/dracula-tufte.json ~/.config/zed/themes/
```

Zed picks it up without a restart. `cmd-k cmd-t`, then **Dracula-Tufte (muted)**.

## Role mapping

Same accent-to-role assignment as the Rider scheme. See
[`../rider/README.md`](../rider/README.md) for the table. Zed-only decisions:

- **`title` is `--pink` at weight 400**, matching `h1` in the stylesheet rather
  than the bold a Markdown heading usually gets. `emphasis` is `--purple`
  italic (`h2`) and `emphasis.strong` is `--orange` at 600 (`strong`), so a
  Markdown buffer reads in the same colours as the rendered page.
- **`text.literal` is `--green`**, the inline-`code` colour, for the same reason.
- **Terminal ANSI matches `../ghostty/dracula-tufte` slot for slot.** The `dim_*`
  slots have no Ghostty counterpart; they are the accent at 65% over
  `--surface`.
- **Player 1 is `--pink`**, so the primary cursor is the same colour Rider uses.
  Players 2-7 are `--link` and the `--data-*` ramp: collaborator cursors are a
  category, and the ramp is what categories draw from.
