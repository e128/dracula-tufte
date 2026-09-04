# dracula-tufte

**This repo is the single source of truth for the Tufte-Dracula HTML conventions.** It holds the
stylesheet, the palette, the Mermaid init script, and the sample fixtures. Consumers pull it in
through a pinned git submodule at `external/dracula-tufte/`. One repo holds the payload, so no
copy can drift from it.

The typography adapts [tufte-css](https://edwardtufte.github.io/tufte-css/), the book style of
Edward Tufte. The palette comes from [Dracula](https://draculatheme.com/). This repo is not a fork
of either one. It rewrites the ideas as one inline stylesheet with no build step.

**Three files answer three different questions:**

| file | question | audience |
| --- | --- | --- |
| [CONTRACT.md](CONTRACT.md) | What must my generator emit? | a consumer's generator, or the agent that writes it |
| [NOTES.md](NOTES.md) | Why is this declaration the way it is, and what must I not change? | anyone who edits the payload |
| README.md | What is this, and how do I install it? | a person who arrives for the first time |

**This file repeats neither one.** It orients the reader and it links out.

## Live previews

GitHub Pages renders these three from `main`. There is no build step.

- [samples/dark.html](https://e128.github.io/dracula-tufte/samples/dark.html): component sample
- [samples/dark-conn-map.html](https://e128.github.io/dracula-tufte/samples/dark-conn-map.html): connections-map layout
- [samples/dark-timeline.html](https://e128.github.io/dracula-tufte/samples/dark-timeline.html): timeline layout, real content

Those three follow your system appearance. A dark-mode reader therefore never sees the light
palette. Three more pages force it:
[light.html](https://e128.github.io/dracula-tufte/samples/light.html),
[light-conn-map.html](https://e128.github.io/dracula-tufte/samples/light-conn-map.html) and
[light-timeline.html](https://e128.github.io/dracula-tufte/samples/light-timeline.html).

**Do not inline CSS from a light preview.** Its stylesheet carries rewritten `@media` conditions,
so it is locked to light and it is not the payload. Each light page says so in a banner. High
contrast has no preview page. CI renders it and attaches the image to each pull request. See
[Appearance modes](NOTES.md#appearance-modes).

## The ten files

| File | What it is |
| --- | --- |
| `tufte-dracula.css` | The stylesheet payload (template v1.41.0, oklch palette). The complete `<style>…</style>` block, with its wrapper tags and its leading indent. Consumers inline it verbatim into every generated file. |
| `mermaid.js` | The Mermaid init script, with its `<script type="module">` wrapper. It holds the pinned CDN import, the init call, and the zoom overlay. Inline it only when the page has a mermaid fence. Bump the CDN pin here. |
| `filter.js` | The filter-box script, with its wrapper. It wires each `input.filter-box` to the siblings that follow it. Inline it only when the page has a filter box. [CONTRACT.md § 6](CONTRACT.md#6-scope-of-filterjs) states the scope. |
| `mermaid-palette.json` | Mermaid's hex palette for each `themeVariables` key, in dark and light, plus the `classDef` node roles. Mermaid cannot read `oklch()` or `var()`. Each entry names its `:root` source, and CI recomputes every hex. |
| `tokens.css` | Palette reference. Generated from the `:root` block. Do not edit it by hand. |
| `scripts/build-sample.nu` | The regenerator. It rebuilds `tokens.css` and all six fixtures. Run it after any payload change. |
| `samples/dark.html` | Living style fixture, and the executable specification. Generated. Do not edit it by hand. |
| `samples/dark-conn-map.html` | Conn-map fixture. It uses `<body class="conn-map">` with the sections in Links-then-Graph order. Generated. |
| `samples/dark-timeline.html` | Timeline fixture, and the only one built from real content. Generated. |
| `CONTRACT.md` | The consumer checklist. It stays imperative and short, because a consumer's agent reads it on every bump. |

The three light previews are deliberately **not** contract files. The rest of the repo splits by
who runs a file. A person types the `scripts/*.nu` commands. CI runs the `.github/*.py` helpers.
Both kinds resolve every path from the repo root. See [Repo layout](NOTES.md#repo-layout).

## Consumers

The current release is **`v1.41.0`**. Consumers reach it through a git submodule. To refresh it,
run `git submodule update --remote external/dracula-tufte` and then commit the pointer.

**Read [CONTRACT.md](CONTRACT.md) before you wire a generator.** It states five things:

1. What to inline (§ 1).
2. The twenty-two markup requirements a generator owes (§ 2), each pointing at a string to search
   for in a fixture rather than at a line number.
3. What changed in each release (§ 3).
4. How to detect a stale artifact (§ 4).
5. What each pin mode costs (§ 5).

Most of § 2 is modelled in `samples/dark.html`, three requirements only in
`samples/dark-timeline.html`, and three in no fixture yet, which each of those three says. CI fails
when a fixture drifts from the stylesheet, so **when CONTRACT.md and a fixture disagree about
markup, the fixture is right.** The single exception is flagged in § 2 itself: the fixture's
`quadrantChart` breaks its own requirement on purpose, as a stress case.

Four things are worth knowing before you get there:

- **Inline each file verbatim, or slice the body out.** Each payload ships inside its own wrapper
  tag. A generator that supplies its own wrapper takes the bare body with `sed '1d;$d'`. The
  wrapper is exactly one line at each end, and CI holds it there.
- **Your own CSS wins with no specificity fight.** The sheet sits in `@layer tufte-dracula`.
  Unlayered author styles beat layered ones, so a plain `h1 { color: … }` overrides the template.
  Load your CSS in any order. The `!important` declarations go the other way. To beat one of
  those, declare your own layer ahead of `tufte-dracula`. See
  [Cascade layer](NOTES.md#cascade-layer).
- **Three appearance modes ship, and you supply nothing for any of them.** Dark is the default.
  `prefers-contrast: more` raises every accent. `prefers-color-scheme: light` swaps in a full light
  palette. Mermaid diagrams follow the light palette, because `mermaid.js` reads a CSS token at
  init. A reader who changes system appearance with the page open sees a stale diagram until the
  next reload. See [Appearance modes](NOTES.md#appearance-modes).
- **Keep the markdown source.** A generator that deletes its source after conversion cannot
  regenerate, so it can never adopt a later release. A repair of generated HTML in place is a much
  harder problem than a second run of the generator.

## Editor themes

`themes/` projects the same `:root` palette into seven editors and terminals, plus Slack. The
editor and terminal files are **not** part of the consumer contract, because no submodule reads
them. The repo generates and gates them from a `.in` template beside each output, except iTerm2's
plist, which `scripts/create-themes.nu` builds straight from the palette because a plist color is
three float components, not a hex string. The Slack entry has no file format to generate: it is a
hand-copied color string, documented in [`themes/slack/README.md`](themes/slack/README.md).

| Theme | Files | Install |
| --- | --- | --- |
| **Rider** | `dracula-tufte.theme.json` (IDE chrome) and `dracula-tufte.icls` (editor scheme) | Settings, Plugins, gear, Install Plugin from Disk, `themes/rider/dist/dracula-tufte-rider-<version>.zip` |
| **Zed** | `dracula-tufte.json` | Copy to `~/.config/zed/themes/` |
| **Ghostty** | `dracula-tufte` | Copy to `~/.config/ghostty/themes/`, then set `theme = dracula-tufte` |
| **iTerm2** | `dracula-tufte.itermcolors` | Preferences, Profiles, Colors, Color Presets, Import, then select it |
| **opencode** | `dracula-tufte.json` | Copy to `~/.config/opencode/themes/`, then set `"theme": "dracula-tufte"` in `opencode.json` |
| **VS Code** | `package.json` plus `themes/dracula-tufte-color-theme.json` | Extensions view, `...` menu, Install from Location, pick `themes/vscode/`, then select the theme |
| **tmux** | `dracula-tufte.conf` | `source-file` it from `~/.tmux.conf` |
| **Slack** | `themes/slack/README.md` (color string, no file to install) | Preferences, Themes, Custom Theme, paste string |

```sh
nu scripts/create-themes.nu           # write every theme, then package the Rider plugin
nu scripts/create-themes.nu --check   # fail if any output drifts from its template
```

**Rider loads a UI theme only from a plugin.** That is why there is an artifact to build. It ships
as a zip that wraps a jar, because Install Plugin from Disk refuses a bare jar. Delete any old
`dracula-tufte-rider-*.jar` from your plugins directory before you install the zip.
`nu scripts/maintain.nu release` attaches the plugin and a themes zip to the GitHub release.

**The editor slot map is deliberately not the prose slot map.** **Do not answer "the theme looks
washed out" by a chroma raise in `:root`.** [Editor themes](NOTES.md#editor-themes) holds the
reasoning. [`themes/rider/README.md`](themes/rider/README.md) holds the whole mapping.

## Releases

1. Edit the payload. Colors change in the `tufte-dracula.css` `:root` block and nowhere else. When
   Mermaid needs that color, recompute its hex in `mermaid-palette.json` and `mermaid.js`.
2. Run `nu scripts/build-sample.nu` to regenerate `tokens.css` and the fixtures.
3. Run `nu scripts/maintain.nu bump <version>` to stamp the stylesheet and this README. Write the
   version as `vX.Y.Z` in prose. A bare `X.Y.Z` goes stale with nobody to notice.
4. Commit to a branch, never straight to `main`, with a conventional message.
5. Run `gh pr create --fill && gh pr checks --watch`, then `gh pr merge --squash`. **The merge is
   what the required check gates.**
6. From an updated `main`, run `nu scripts/maintain.nu release <version>`. It refuses a `HEAD` that
   is not `origin/main`. It refuses a version the stylesheet does not carry. It waits for the
   checks named in `REQUIRED_CHECKS` on that exact SHA. It writes an annotated tag only when every
   one of those concludes `success`. Every other check run prints as `(advisory)`.
7. Run `git submodule update --remote external/dracula-tufte` in each consumer repo.

**Only a pull request can satisfy a required status check.** The check runs after a push, so
`git push origin main` can never satisfy it. GitHub takes the push and records `Bypassed rule
violations`. Consumers pin to tags, so a tag on an ungated commit hands every one of them an
unverified payload. **When a push reports a bypass, say so and revert. Do not tag on top of it.**

[`AGENTS.md`](AGENTS.md) states this flow as plain shell, and states the rules that have no
exception. It is the instruction file for any agent working in this repo, whichever harness runs
it. [`CLAUDE.md`](CLAUDE.md) adds only Claude Code entry points on top, including a `release` skill
that packages the same flow.

## Contract enforcement

`.github/workflows/contract-check.yml` runs on every push and pull request.
`nu scripts/maintain.nu check` mirrors it step for step, so a local pass and a CI pass mean the
same thing. Together they verify:

- File presence, and the one-line `<style>` and `<script>` wrappers.
- `theme: 'base'` in `mermaid.js`.
- Both Mermaid hex palettes against `mermaid-palette.json`.
- The release gate's own refusals, through `nu scripts/maintain.nu selftest`.
- That every generated file and every theme is freshly regenerated.
- That every fixture pointer in [CONTRACT.md § 2](CONTRACT.md#2-emit-this-markup) still matches the
  file it names.
- That no em-dash and no en-dash appears in any tracked file.

**One check runs the payload instead of reading it.** `.github/script-probe.py` loads
`samples/dark.html` in headless Chrome, drives `filter.js` and `mermaid.js`, and asserts what a
reader would see. Everything else counts blocks, compares bytes or measures colors, and none of
that asks whether a handler attaches to anything: the fixture shipped an inert `input.filter-box`
for six releases with every other check green.

**One palette feeds several projections.** The `:root` block is the only source of color truth.
`.github/palette-check.py` runs eleven checks over it:

1. Hex projections in both Mermaid palettes.
2. The `classdef` fills, dark and light, and the letter each set paints on its own fill.
3. The `/* was */` provenance comments.
4. Stray hex in `mermaid.js`.
5. Contrast floors in all four modes.
6. `--mermaid-scheme` in both directions, and the scroll breakpoint pinned across two files.
7. The sRGB gamut ceiling.
8. The vividness bands.
9. The inverted pairs, where an accent is the ground and `--surface` is the text.
10. The two relative-color tokens.
11. The pie slice label against every slice fill, and `pieOpacity`.

**A measurement in prose is not a gate.** That is why those checks exist, and why
[NOTES.md](NOTES.md) carries the decisions rather than the numbers.

**CI renders every appearance mode instead of only parsing it.** `.github/render-modes.py` opens
each fixture in each mode. It then asserts that the page paints that mode's `--surface`. The images
upload as a pull-request artifact and stay advisory. The assertions are the gate.

If you find a violation in a consumer, fix that consumer to read from `external/dracula-tufte/`. Do
not add a copy.

## License

MIT, see [LICENSE](./LICENSE).
