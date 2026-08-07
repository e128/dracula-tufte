# Dracula-Tufte (muted) — JetBrains Rider theme

Two artefacts, one palette:

- `dracula-tufte.icls` — editor colour scheme (syntax, gutter, diff, console ANSI).
- `dracula-tufte.theme.json` — IDE chrome (tool windows, tabs, menus, popups, icons).

Every hex here is the sRGB rendering of a `tufte-dracula.css` `:root` `oklch()`
token. The ANSI slots match `themes/ghostty/dracula-tufte` one-for-one, so the
Rider console and the terminal agree.

## These files are generated

`create-themes.nu` writes all four, plus the installable plugin, from the `.in`
template beside each one. Edit the template, never the output.

```sh
nu create-themes.nu           # write the themes, then package the plugin
nu create-themes.nu --check   # fail if any output drifts from its template
nu create-themes.nu --no-jar  # themes only
```

## Install

**Whole theme** — UI plus colour scheme:

```sh
nu create-themes.nu
```

Settings → Plugins → gear → Install Plugin from Disk… → pick
`themes/rider/dist/dracula-tufte-rider-<version>.zip` → restart. Rider loads a
UI theme only from a plugin, which is why there is an artefact to build at all;
`zip` is the whole build.

### Why a zip and not a bare jar

The plugin is a zip wrapping a jar:

```
dracula-tufte-rider-<version>.zip
  Dracula-Tufte/lib/dracula-tufte-rider-<version>.jar
```

Through v1.18.0 it was a bare jar, and that shape has a trap in it. A bare jar
copied by hand into `<config>/plugins/` loads perfectly — Rider 2026.2 reports
`Loaded custom plugins: … Dracula-Tufte (muted) …` and the theme appears. But
**Install Plugin from Disk… refuses it**, which is how everyone actually
installs. Bare-jar plugins are the legacy form; `Name/lib/*.jar` is what every
other plugin in that directory is, and what every marketplace theme ships.

If you have an old `dracula-tufte-rider-*.jar` in your plugins directory, delete
it before installing the zip. Two copies of the same plugin ID is its own
problem.

The plugin is tracked, and `nu maintain.nu release` attaches it to the GitHub
release for the tag, so it can also be downloaded without cloning. Tracking a
zip only works because the build is reproducible: every staged entry is stamped
`1980-01-01` — twice, since the inner jar is itself created new — `-X` drops
per-machine uid/gid and xattrs, and entries are named in a fixed order instead of
swept up by `-r`. `META-INF/MANIFEST.MF` deliberately carries no JVM, OS or
platform-build stamps for the same reason. Rebuilding unchanged inputs is
byte-identical, so a diff means a real change and `--check` can compare it.

The scheme enters the jar renamed to `dracula-tufte.xml`. A theme's
`editorScheme` path is resolved through `SchemeManager`, which registers only
`*.xml` out of a plugin: bundle it as `.icls` and Rider shows the UI theme,
falls back to Darcula for the editor, and logs `refers to unknown color scheme`.
The file keeps its `.icls` name on disk because that is what Import Scheme…
expects.

**Colour scheme only**, no packaging step: Settings → Editor → Color Scheme →
gear → Import Scheme… → pick `dracula-tufte.icls`. Unnecessary once the plugin
is installed, since the theme carries the scheme with it.

## Role mapping

The CSS assigns each accent a job in prose. The scheme keeps those jobs.

| Token | Hex | Prose role | Editor role |
| --- | --- | --- | --- |
| `--pink` | `#e48bb7` | `h1`, `th` | keywords, operators, caret, active tab underline |
| `--purple` | `#a98ed6` | `h2`, `pre` accent bar | types, classes, progress bar |
| `--green` | `#7fc99a` | inline `code` | strings, XML attribute values |
| `--orange` | `#e0a878` | `strong` | numbers, constants, TODO, search match |
| `--link` | `#8fc9d9` | `a` | functions and methods, focus ring, links |
| `--label` | `#b7bfe4` | `h3`, sidenotes | parameters, fields, punctuation |
| `--muted` | `#979fc4` | `cite` | comments (italic), inlay hints |
| `--rule-light` | `#707388` | hairlines | line numbers, unused symbols |
| `--red` | `#f68281` | — | errors, deleted lines |
| `--data-1..4` | `#99bdec` `#de8dc3` `#74caa6` `#bbc175` | diagram categories | VCS status, diff, log refs |

The `--data-*` ramp stays on categorical things (diff, VCS, file colours) for the
same reason it exists in the CSS: prose accents already mean something, and a
category must not borrow them.

Greys and tinted backgrounds are not tokens. They are sRGB mixes over
`--surface`, written in the templates as `{{mix:surface:red:20}}` and resolved
by `create-themes.nu`: the neutral ramp mixes toward `--rule-light` so it keeps
the palette's violet cast, and every diff, file-colour and search background is
its accent at a fixed 10 / 20 / 28 / 35 percent.

## Deviations from the CSS

- **Line height 1.2, not 1.6.** Body prose inherits `line-height: 1.6`; an editor
  at 1.6 wastes half the viewport. Change `LINE_SPACING` in the `.icls` if you
  disagree.
- **Mono font, not serif.** `--mono-font` names `JetBrains Mono` first; the
  scheme pins that. The serif is a prose face and has no editor role.
- **Bright ANSI slots** (`#ff9896`, `#96e0b0`, `#afd4ff`, `#a5e0f0`, `#fcfcf6`)
  have no token of their own. They are the matching hue and chroma at L + 0.07,
  same derivation as the Ghostty theme.
