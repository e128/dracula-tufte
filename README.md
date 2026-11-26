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

GitHub Pages renders these four from `main`. There is no build step.

- [samples/dark.html](https://e128.github.io/dracula-tufte/samples/dark.html): component sample
- [samples/dark-conn-map.html](https://e128.github.io/dracula-tufte/samples/dark-conn-map.html): connections-map layout
- [samples/dark-timeline.html](https://e128.github.io/dracula-tufte/samples/dark-timeline.html): timeline layout, real content
- [samples/dark-charts.html](https://e128.github.io/dracula-tufte/samples/dark-charts.html): the bar chart, meter, dot plot, sparkline, small multiples and line chart

Those four follow your system appearance. A dark-mode reader therefore never sees the light
palette. Four more pages force it:
[light.html](https://e128.github.io/dracula-tufte/samples/light.html),
[light-conn-map.html](https://e128.github.io/dracula-tufte/samples/light-conn-map.html) and
[light-timeline.html](https://e128.github.io/dracula-tufte/samples/light-timeline.html) and
[light-charts.html](https://e128.github.io/dracula-tufte/samples/light-charts.html).

**Do not inline CSS from a light preview.** Its stylesheet carries rewritten `@media` conditions,
so it is locked to light and it is not the payload. Each light page says so in a banner. High
contrast has no preview page. CI renders it and attaches the image to each pull request. See
[Appearance modes](NOTES.md#appearance-modes).

### Seasonal previews

The four fixtures above carry the optional seasonal head snippet and follow the calendar at page
load, in the visitor's local year. Read in date order, the seasons take effect:

1. **January 14 through February 28**: Aurora. A violet polar night in the dark palette and a pale
   aurora green in the light one, anchored on `#0f0528`, `#c7fde4` and an ice-blue link.
2. **March 1 through March 17**: St Patrick. Deep shamrock green in the dark palette and pale
   mint in the light one, anchored on `#02331d`, `#d6f7dc` and the gold `#e4b24d`.
3. **May 1 through May 16**: Chartreuse. Green chartreuse in the dark palette, yellow chartreuse
   in the light one, anchored on `#9BA434` and `#CDE62E`.
4. **June 28 through July 4**: Independence Day. Navy and red in the dark palette, pale blue in
   the light one, anchored on `#101d38`, `#e8f3ff` and the flag red.
5. **August 25 through 27**: Birthday. Candle gold, coral and mint on a deep wine ground in the
   dark palette, and a pale blue ground in the light one.
6. **September 20 through October 5**: Oktoberfest. Bavarian blue, wheat gold and hop green on a
   deep pretzel brown ground in the dark palette, and a wheat ground in the light one.
7. **October 24 through 31**: Halloween. Pumpkin, bone and witch violet in the dark palette, with
   a pale lilac ground in the light one.
8. **November 1 through the fourth Thursday of November**: Thanksgiving. That Thursday is
   Thanksgiving Day.
9. **The fourth Friday of November through December 28**: Christmas.
10. **December 29 through January 13**: Bois Jacques. Frozen ground and snow at the Bois Jacques
    forest in the Ardennes winter, anchored on `#11161d`, `#dfe7ef` and a lantern amber.

Poland is an override rather than a range. Its single days win even inside another season's range:
May 3, August 15, November 11 and December 6. Red and white dominate, with the eagle's gold in the
accents. Every other day shows the plain palette. The windows are inclusive and both November
boundaries are resolved in the visitor's local year. March 18 through April 30, May 17 through
June 27, July 5 through August 24, August 28 through September 19, and October 6 through October 23
belong to no season.

Each season also has a pair of preview pages that force it for any date and any system setting:

| Season | `data-season` | Active window | Forced preview |
| --- | --- | --- | --- |
| St Patrick | `st-patrick` | March 1 through March 17 | [dark](https://e128.github.io/dracula-tufte/samples/st-patrick-dark.html), [light](https://e128.github.io/dracula-tufte/samples/st-patrick-light.html) |
| Chartreuse | `chartreuse` | May 1 through May 16 | [dark](https://e128.github.io/dracula-tufte/samples/chartreuse-dark.html), [light](https://e128.github.io/dracula-tufte/samples/chartreuse-light.html) |
| Independence Day | `independence-day` | June 28 through July 4 | [dark](https://e128.github.io/dracula-tufte/samples/independence-day-dark.html), [light](https://e128.github.io/dracula-tufte/samples/independence-day-light.html) |
| Thanksgiving | `thanksgiving` | November 1 through the fourth Thursday of November | [dark](https://e128.github.io/dracula-tufte/samples/thanksgiving-dark.html), [light](https://e128.github.io/dracula-tufte/samples/thanksgiving-light.html) |
| Christmas | `christmas` | the fourth Friday of November through December 28 | [dark](https://e128.github.io/dracula-tufte/samples/christmas-dark.html), [light](https://e128.github.io/dracula-tufte/samples/christmas-light.html) |
| Poland | `poland` | May 3, August 15, November 11 and December 6 (overrides the ranges above) | [dark](https://e128.github.io/dracula-tufte/samples/poland-dark.html), [light](https://e128.github.io/dracula-tufte/samples/poland-light.html) |
| Bois Jacques | `bois-jacques` | December 29 through January 13 | [dark](https://e128.github.io/dracula-tufte/samples/bois-jacques-dark.html), [light](https://e128.github.io/dracula-tufte/samples/bois-jacques-light.html) |
| Aurora | `aurora` | January 14 through February 28 | [dark](https://e128.github.io/dracula-tufte/samples/aurora-dark.html), [light](https://e128.github.io/dracula-tufte/samples/aurora-light.html) |
| Birthday | `birthday` | August 25 through 27 | [dark](https://e128.github.io/dracula-tufte/samples/birthday-dark.html), [light](https://e128.github.io/dracula-tufte/samples/birthday-light.html) |
| Oktoberfest | `oktoberfest` | September 20 through October 5 | [dark](https://e128.github.io/dracula-tufte/samples/oktoberfest-dark.html), [light](https://e128.github.io/dracula-tufte/samples/oktoberfest-light.html) |
| Halloween | `halloween` | October 24 through 31 | [dark](https://e128.github.io/dracula-tufte/samples/halloween-dark.html), [light](https://e128.github.io/dracula-tufte/samples/halloween-light.html) |

A preview page is not the payload, and each says so in a banner.

## The twelve files

| File | What it is |
| --- | --- |
| `tufte-dracula.css` | The stylesheet payload (template v1.75.0, oklch palette). The complete `<style>…</style>` block, with its wrapper tags and its leading indent. Consumers inline it verbatim into every generated file. |
| `mermaid.js` | The Mermaid init script, with its `<script type="module">` wrapper. It holds the pinned CDN import, the init call, and the zoom overlay. Inline it only when the page has a mermaid fence. Bump the CDN pin here. |
| `highlight.js` | The code highlighter, with its `<script type="module">` wrapper. It loads a pinned `highlight.js` from a CDN and highlights each `pre > code.language-NAME` block. Inline it only when the page has one. |
| `filter.js` | The filter-box script, with its wrapper. It wires each `input.filter-box` to the siblings that follow it. Inline it only when the page has a filter box. [CONTRACT.md § 6](CONTRACT.md#6-scope-of-filterjs) states the scope. |
| `mermaid-palette.json` | Mermaid's hex palette for each `themeVariables` key, in dark, light and one variant per season, plus the `classDef` node roles. Mermaid cannot read `oklch()` or `var()`. Each entry names its `:root` source, and CI recomputes every hex. |
| `tokens.css` | Palette reference. Generated from the `:root` block. Do not edit it by hand. |
| `scripts/build-sample.nu` | The regenerator. It rebuilds `tokens.css`, the fixtures and the season previews. Run it after any payload change. |
| `samples/dark.html` | Living style fixture, and the executable specification. Generated. Do not edit it by hand. |
| `samples/dark-conn-map.html` | Conn-map fixture. It uses `<body class="conn-map">` with the sections in Links-then-Graph order. Generated. |
| `samples/dark-timeline.html` | Timeline fixture, and the only one built from real content. Generated. |
| `samples/dark-charts.html` | Chart fixture: `table.bar-chart`, the meter, the dot plot, a column sparkline, small multiples, a Mermaid `xychart` line, a delta column, a stored-and-derived flowchart, the guidance on which chart to draw, and twelve more Mermaid fence types verified against this palette. Generated. |
| `CONTRACT.md` | The consumer checklist. It stays imperative and short, because a consumer's agent reads it on every bump. |

The light previews and the season previews are deliberately **not** contract files.
The rest of the repo splits by who runs a file. A person types the `scripts/*.nu` commands. CI runs the `.github/*.py` helpers.
Both kinds resolve every path from the repo root. See [Repo layout](NOTES.md#repo-layout).

## Consumers

The current release is **`v1.75.0`**. Consumers reach it through a git submodule. To refresh it,
run `git submodule update --remote external/dracula-tufte` and then commit the pointer.

**Read [CONTRACT.md](CONTRACT.md) before you wire a generator.** It states five things:

1. What to inline (§ 1).
2. The forty-three markup requirements a generator owes (§ 2), each pointing at a string to search
   for in a fixture rather than at a line number.
3. What changed in the last ten releases (§ 3).
4. How to detect a stale artifact (§ 4).
5. What each pin mode costs (§ 5).

Most of § 2 is modelled in `samples/dark.html`, six requirements only in
`samples/dark-timeline.html`, seven only in `samples/dark-charts.html`, and four that no fixture
demonstrates yet, which each of those four says. CI fails
when a fixture drifts from the stylesheet, so **when CONTRACT.md and a fixture disagree about
markup, the fixture is right.** The single exception is flagged in § 2 itself: the fixture's
`quadrantChart` breaks its own requirement on purpose, as a stress case.

Six things are worth knowing before you get there:

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
- **The seasonal themes need one snippet from you.** The stylesheet carries a palette per season
  and never turns one on. A page shows a season only after your generator adds the classic head
  snippet that [CONTRACT.md § 1](CONTRACT.md#seasonal-theme-optional) gives.
  [Seasonal previews](#seasonal-previews) lists the seasons and their date windows. Updating the
  pinned submodule alone changes nothing for a page without the snippet. Leave the snippet out to
  opt out.
- **Keep the markdown source.** A generator that deletes its source after conversion cannot
  regenerate, so it can never adopt a later release. A repair of generated HTML in place is a much
  harder problem than a second run of the generator.
- **Mark code as untranslatable.** Add `translate="no"` to the `<code>` and `<pre>` elements your
  generator emits. Chrome's page translation rewrites the identifiers inside a code sample, so a
  reader who translates the page sees code that no longer matches the source.

## Editor themes

`themes/` projects the same `:root` palette into eight editors and terminals, plus Slack. The
editor and terminal files are **not** part of the consumer contract, because no submodule reads
them. The repo generates and gates them from a `.in` template beside each output, except iTerm2's
plist, which `scripts/create-themes.nu` builds straight from the palette because a plist color is
three float components, not a hex string. The Slack entry has no file format to generate: it is a
hand-copied color string, documented in [`themes/slack/README.md`](themes/slack/README.md).

**Every target ships the appearances its format can hold.** Rider, Zed, Ghostty, iTerm2, VS Code
and CotEditor ship dark and light, projected from `:root` and its `prefers-color-scheme: light`
override. opencode and tmux ship dark only: their theme formats have no appearance switch. Slack
holds a single hand-copied string.

**Every target in the table except Slack also ships one variant per season**, projected from that
season's dark block, so it stays dark-family even in light mode. Rider adds a light variant of
each season beside the dark one, so its plugin carries every appearance. A season variant is
selected by hand, not by the calendar. [Seasonal previews](#seasonal-previews) lists the seasons. In the
table, `<season>` is the season's `data-season` value, except that Rider and Ghostty spell
Christmas `xmas` in filenames. A new season adds one file per target (two for Rider, dark and
light), or one more theme object in Zed's single file, plus the steps in CONTRACT.md's
[Adding a New Date-Range Palette](CONTRACT.md#adding-a-new-date-range-palette).

| Theme | Files | Modes | Season variants | Install |
| --- | --- | --- | --- | --- |
| **Rider** | `dracula-tufte.theme.json`/`.icls` (dark), `dracula-tufte-light.theme.json`/`.icls` (light) | dark + light | `dracula-tufte-<season>.theme.json`/`.icls` and `dracula-tufte-<season>-light.theme.json`/`.icls` | Settings, Plugins, gear, Install Plugin from Disk, `themes/rider/dist/dracula-tufte-rider-<version>.zip`, pick a theme from the theme list |
| **Zed** | `dracula-tufte.json` (one file, all themes) | dark + light | `Dracula-Tufte (muted) <Season>` object in the same file | Copy to `~/.config/zed/themes/` |
| **Ghostty** | `dracula-tufte`, `dracula-tufte-light` | dark + light | `dracula-tufte-<season>` | Copy to `~/.config/ghostty/themes/`, then set `theme = dark:dracula-tufte,light:dracula-tufte-light`; pick a seasonal theme by hand |
| **CotEditor** | `Dracula-Tufte (Dark).cottheme`, `Dracula-Tufte (Light).cottheme` | dark + light | `Dracula-Tufte <Season> (Dark).cottheme` | Settings, Appearance, gear, Import the themes you want; the plain pair switches with the window appearance |
| **iTerm2** | `dracula-tufte.itermcolors`, `dracula-tufte-light.itermcolors` | dark + light | `dracula-tufte-<season>.itermcolors` | Preferences, Profiles, Colors, Color Presets, import the presets you want; check "Use different colors for light and dark mode" and assign each preset to its appearance |
| **opencode** | `dracula-tufte.json` | dark only | `dracula-tufte-<season>.json` | Copy to `~/.config/opencode/themes/`, then set `"theme"` in `opencode.json` to the file base name |
| **VS Code** | `package.json` plus `themes/dracula-tufte-color-theme.json` (dark), `themes/dracula-tufte-light-color-theme.json` (light) | dark + light | `themes/dracula-tufte-<season>-color-theme.json` | Extensions view, `...` menu, Install from Location, pick `themes/vscode/`, then select a theme |
| **tmux** | `dracula-tufte.conf` | dark only | `dracula-tufte-<season>.conf` | `source-file` the variant you want from `~/.tmux.conf` |
| **Slack** | `themes/slack/README.md` (color string, no file to install) | dark only | none: one hand-copied string | Preferences, Themes, Custom Theme, paste string |

```sh
nu scripts/create-themes.nu           # write every theme, then package the Rider plugin
nu scripts/create-themes.nu --check   # fail if any output drifts from its template
```

**Rider loads a UI theme only from a plugin.** That is why there is an artifact to build. It ships
as a zip that wraps a jar, because Install Plugin from Disk refuses a bare jar. Delete any old
`dracula-tufte-rider-*.jar` from your plugins directory before you install the zip.
`nu scripts/maintain.nu release` attaches the Rider plugin zip, the VS Code vsix and the themes zip
to the GitHub release.

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
exception. It is the only instruction file in this repo and the one any agent reads, whichever
harness runs it, Claude Code included. Its *Harness entry points* section lists the two Claude Code
skills, `release` and `design-audit`, each of which packages a flow stated in full there.

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
- That every link from one markdown file in this repo into another still lands on a heading that
  exists.
- That no em-dash and no en-dash appears in any tracked file.

**One check runs the payload instead of reading it.** `.github/script-probe.py` loads
`samples/dark.html` in headless Chrome, drives `filter.js`, `mermaid.js` and `highlight.js`, and asserts what a
reader would see. Everything else counts blocks, compares bytes or measures colors, and none of
that asks whether a handler attaches to anything: the fixture shipped an inert `input.filter-box`
for six releases with every other check green. It also renders the page with `forced-colors`
switched on and asserts that block's structure, which is the only coverage that mode has, because
its correctness is not a color.

**A second check does the same for the seasonal snippet.** `.github/season-probe.py` extracts the
head snippet from the generated fixtures and compares it with the copy in CONTRACT.md. It then runs
the snippet in headless Chrome against a mocked clock across every window's boundary dates and three
time zones, and checks that the season previews hold under any system setting.

**One palette feeds several projections.** The `:root` block is the only source of color truth.
`.github/palette-check.py` runs fourteen checks over it:

1. Hex projections in all twelve Mermaid palettes.
2. The `classdef` fills, dark and light, and the letter each set paints on its own fill.
3. The `/* was */` provenance comments.
4. Stray hex in `mermaid.js`.
5. Contrast floors in all eighteen modes.
6. `--mermaid-scheme` in both directions, and the scroll breakpoint pinned across two files.
7. The sRGB gamut ceiling.
8. The vividness bands.
9. The inverted pairs, where an accent is the ground and `--surface` is the text.
10. The two relative-color tokens.
11. Retired with the pie.
12. The number that sits on a `table.bar-chart` band, and the two pins that keep a CSS chart
    visible in print and out of the way in forced colors.
13. The ten truecolor projections in `.claude/statusline.sh`.
14. The `nav.toc` composite ground, in every mode.

**A measurement in prose is not a gate.** That is why those checks exist, and why
[NOTES.md](NOTES.md) carries the decisions rather than the numbers.

**CI renders every appearance mode instead of only parsing it.** `.github/render-modes.py` opens
each fixture in each mode. It then asserts that the page paints that mode's `--surface`. The images
upload as a pull-request artifact and stay advisory. The assertions are the gate.

If you find a violation in a consumer, fix that consumer to read from `external/dracula-tufte/`. Do
not add a copy.

## License

MIT, see [LICENSE](./LICENSE).
