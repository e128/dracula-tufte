# Dracula-Tufte (muted): CotEditor theme

Two `.cottheme` files, one per appearance. CotEditor pairs two themes whose names differ
only by a trailing ` (Dark)` or ` (Light)`, so the pair switches with the window appearance
once both are installed and Appearance is set to Match System. The space before the
parenthesis is part of the name.

## Generated, do not hand-edit

`scripts/create-themes.nu` writes both files from the `.in` template beside each one. Edit
the template.

```sh
nu scripts/create-themes.nu
nu scripts/create-themes.nu --check
```

## Install

Copy both files to `~/Library/Application Support/CotEditor/Themes/`, or import them from
Settings, Appearance, gear, Import. For the Mac App Store build, use the container path:
`~/Library/Containers/com.coteditor.CotEditor/Data/Library/Application Support/CotEditor/Themes/`.

## Role mapping

Same accent-to-role assignment as the Rider scheme. See
[`../rider/README.md`](../rider/README.md) for the table. CotEditor-only decisions:

- **`characters` is `--green`**, the same colour as `strings`. The palette has no yellow,
  and a character literal is a string literal in this slot map.
- **`values` and `numbers` are both `--orange`**, matching `DEFAULT_NUMBER` and
  `DEFAULT_CONSTANT` in the Rider scheme.
- **`selection` is `--link` at 20%**, the same value the VS Code theme uses. A solid
  `--code-bg.bright` reads as almost no selection at all in light mode, where it sits one
  step from `--surface`.
- **`highlight` is `--orange`**, matching the find-match colour in the VS Code theme.
- **`lineHighlight` and `invisibles`** are `--surface` mixed toward `--rule-light` at 12%
  and 60%, the same two mixes the VS Code theme uses.

`cursor` is deliberately absent. CotEditor's current theme model reads `insertionPoint`;
`cursor` appears in some third-party themes but no built-in one.
