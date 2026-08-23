# Dracula-Tufte (muted): VS Code theme

Three files: `package.json` (the extension manifest), `extension.vsixmanifest`
(the VSIX container manifest), and `themes/dracula-tufte-color-theme.json`
(workbench colors plus TextMate scopes).

## Generated, do not hand-edit

`scripts/create-themes.nu` writes all three from the `.in` template beside
each one, then packages `dist/dracula-tufte-vscode-<version>.vsix`, the same
way it packages the Rider plugin zip. Edit the template, never the rendered
file or the `.vsix`.

```sh
nu scripts/create-themes.nu
nu scripts/create-themes.nu --check
```

## Install

`dist/dracula-tufte-vscode-<version>.vsix` is tracked in this repo and rebuilt
on every regeneration, the same way `themes/rider/dist/dracula-tufte-rider-<version>.zip`
is.

```sh
code --install-extension themes/vscode/dist/dracula-tufte-vscode-<version>.vsix
```

Or, from the Extensions view: `...` menu -> **Install from VSIX...** -> pick
the file. Either way, reload when prompted, then `Ctrl/Cmd+K Ctrl/Cmd+T` and
pick **Dracula-Tufte (muted)**.

There is still no marketplace listing, so this is the only install path aside
from the unpacked folder below.

## Unpacked, for editing the theme itself

Extensions view -> `...` menu -> **Install from Location...** -> pick
`themes/vscode/` -> reload when prompted. This is the one install path that
reflects an edited `.in` template without a rebuild, so it is the faster loop
while working on the theme itself; the `.vsix` above is what to ship.

To try it without installing anything, run VS Code's Extension Development
Host instead:

```sh
code --extensionDevelopmentPath="$(pwd)/themes/vscode"
```

## Role mapping

Same accent-to-role assignment as the Rider scheme. See
[`../rider/README.md`](../rider/README.md) for the table. VS Code-only notes:

- **Types are `--purple` at L+0.07**, matching Rider exactly (`entity.name.type`,
  `entity.name.class`, `support.type`, `support.class`). Plain `--purple` stays on
  progress-bar and predefined-symbol roles, which VS Code's `tokenColors` schema
  has no scope for, so it only surfaces on `editorBracketHighlight.foreground5`
  and `markup.italic`.
- **Parameters are `--orange`**, not `--label`. The Rider table lists parameters
  under the orange row alongside numbers and constants; `variable.other.property`
  and `variable.other.member` (object fields) are what take `--label`.
- **Git decorations and diagnostics reuse Zed's already-shipped choices**
  (`../zed/dracula-tufte.json.in`) rather than inventing a second mapping: modified
  and renamed are `--data-1`, added and untracked are `--data-3`, conflicting is
  `--data-2`, errors and deletions are `--red`, warnings are `--orange`.
