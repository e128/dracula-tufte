# Passenger

Passenger theme format 1 files for [Zaneris/passenger](https://github.com/Zaneris/passenger), the
C#/.NET IDE built on Avalonia. Every colour is a `tufte-dracula.css` `:root` token or an sRGB mix
of two, the same projection Rider, VS Code and the rest of `themes/` use.

## Files

| File | Appearance |
| --- | --- |
| `dracula-tufte.json` | dark and light |
| `dracula-tufte-<season>.json` | that season's dark and light |

Each file holds both appearances in its `dark` and `light` members, and Passenger switches them
with the system. A season file is selected by hand and never follows the calendar, exactly as the
seasonal Rider, Zed and VS Code themes do. `passenger-themes.json` is the source index and lists
every theme file in this folder. It is generated from the `THEMES` rows in
`scripts/create-themes.nu`, not edited by hand.

## Install

1. Run `nu scripts/create-themes.nu`, or unpack `themes/passenger/` from the release's themes zip.
2. In Passenger, open Settings, Appearance, Theme sources, and add this folder by its full path.
3. Choose a theme from Settings, Appearance, Theme.

A source added from a folder is read only when you look at its themes or press Refresh. The
`.json.in` templates beside the outputs are the generator's input, are not listed in the index,
and are never installed.

## Slot map

The syntax colours are the map the Rider and VS Code themes already settled, not a new one:
keywords pink, strings green, escapes and numbers orange, types `purple.bright`, functions and
methods link, fields label, parameters orange, locals the plain text, and punctuation at
`on-surface`. Every brace colour is `on-surface`, so Passenger draws no rainbow here. See
[`../rider/README.md`](../rider/README.md) for the full reasoning and
[NOTES.md](../../NOTES.md#editor-themes) for the decisions behind it.

Shapes, fonts, the background picture and the default layout are left to Passenger's own theme.
This folder projects colour and seasons only.
