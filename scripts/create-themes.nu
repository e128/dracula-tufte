#!/usr/bin/env nu
# create-themes.nu regenerates everything under themes/ from tufte-dracula.css,
# then packages the Rider theme as an installable plugin jar and the VS Code
# theme as an installable .vsix.
# Run: `nu scripts/create-themes.nu` | `… --check` | `… --no-jar` | `… --no-vsix`
#
# Each theme is a `.in` template beside its output. The template is the real
# file with every colour replaced by a placeholder, so a diff between the two
# reads as "which colours moved", not "what changed". Placeholders:
#
#   {{green}}                  a :root oklch token, as bare rrggbb
#   {{green.bright}}           the same hue and chroma at L + 0.07 (capped 0.99)
#   {{mix:surface:red:20}}     20% red over surface, mixed in sRGB
#   {{version}}                the template version parsed out of the CSS
#
# Templates write bare hex, never `#rrggbb`, because the `#` belongs to the format, so
# Ghostty and the Rider theme.json write `#{{green}}` and the .icls writes
# `{{green}}`. One placeholder vocabulary, no per-file escaping rule.
#
# iTerm2's .itermcolors is the one output with no `.in` template. A plist color is
# three float components, not a hex string, so there is nothing for `{{}}` substitution
# to land on. `render-itermcolors` below builds it straight from $palette, the same way
# `package` builds the Rider zip from code, and it is gated the same way too: rendered
# in memory and compared to the file on disk.
#
# ponytail: template + substitution, not a themed-file generator. The colours
# are the only thing that tracks the stylesheet; 20 KB of XML that never moves
# has no business being emitted from a script. oklch -> sRGB comes from
# `.github/palette-check.py --dump` rather than a Nushell reimplementation:
# Nushell has no trig builtins, and a second copy of the Oklab matrix would be
# free to drift from the one CI checks.

# path self is this file, so its dirname is scripts/ and ROOT is the repo above it.
# Everything resolves from ROOT, never from cwd, so this runs from anywhere in the tree.
# SCRIPTS exists because `path self | path dirname | path dirname` is not a legal const
# chain in Nushell, because the second step has to read a name that is already bound.
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname

# Pairs are (template, output). Output is always the template minus `.in`, but
# spelling both keeps the list greppable from either direction.
const THEMES = [
  "themes/ghostty/dracula-tufte"
  "themes/opencode/dracula-tufte.json"
  "themes/rider/dracula-tufte.icls"
  "themes/rider/dracula-tufte.theme.json"
  "themes/rider/META-INF/plugin.xml"
  "themes/tmux/dracula-tufte.conf"
  "themes/vscode/extension.vsixmanifest"
  "themes/vscode/package.json"
  "themes/vscode/themes/dracula-tufte-color-theme.json"
  "themes/zed/dracula-tufte.json"
]

# iTerm2's ANSI slots, in the same hue-to-slot assignment the Ghostty template already
# settled on. Kept as one table so a future terminal target reuses it by name instead
# of re-deriving which token is "yellow".
const ANSI_SLOTS = [
  {idx: 0,  key: "surface-alt"}
  {idx: 1,  key: "red"}
  {idx: 2,  key: "green"}
  {idx: 3,  key: "data-4"}
  {idx: 4,  key: "data-1"}
  {idx: 5,  key: "purple"}
  {idx: 6,  key: "link"}
  {idx: 7,  key: "label"}
  {idx: 8,  key: "rule-light"}
  {idx: 9,  key: "red.bright"}
  {idx: 10, key: "green.bright"}
  {idx: 11, key: "orange"}
  {idx: 12, key: "data-1.bright"}
  {idx: 13, key: "pink"}
  {idx: 14, key: "link.bright"}
  {idx: 15, key: "on-surface.bright"}
]

const ITERM_OUT = "themes/iterm2/dracula-tufte.itermcolors"

def main [
  --check       # render in memory and fail on drift instead of writing
  --no-jar      # skip Rider packaging, just write the theme files
  --no-vsix     # skip VS Code packaging, just write the theme files
] {
  let palette = (^python3 ($ROOT | path join ".github/palette-check.py") --dump | from json)
  let version = (version-of-css)

  mut drift = []
  for rel in $THEMES {
    let out = ($ROOT | path join $rel)
    let rendered = (render (open --raw $"($out).in") $palette $version)
    if $check {
      if (not ($out | path exists)) or (open --raw $out) != $rendered {
        $drift = ($drift | append $rel)
      }
    } else {
      $rendered | save --force --raw $out
      print $"  → ($rel)"
    }
  }

  let iterm_path = ($ROOT | path join $ITERM_OUT)
  let iterm_rendered = (render-itermcolors $palette $version)
  if $check {
    if (not ($iterm_path | path exists)) or (open --raw $iterm_path) != $iterm_rendered {
      $drift = ($drift | append $ITERM_OUT)
    }
  } else {
    $iterm_rendered | save --force --raw $iterm_path
    print $"  → ($ITERM_OUT)"
  }

  let plugin = (plugin-path $version)
  if not $no_jar {
    if $check {
      # Build a throwaway and compare bytes. Only meaningful because package
      # freezes every entry timestamp. See there.
      let probe = ($plugin | path dirname | path join ".probe.zip")
      package $probe $version
      if (not ($plugin | path exists)) or (open --raw $plugin) != (open --raw $probe) {
        $drift = ($drift | append ($plugin | path relative-to $ROOT))
      }
      rm --force $probe
      # A plugin for a version we no longer build is installable and unmaintained.
      # `bump` deletes them; this is what notices when something else did not.
      # Globs .jar too: the bare-jar artefact this replaced must not linger, since
      # it is the shape Install Plugin from Disk refuses.
      for old in (glob ($plugin | path dirname | path join "*.{jar,zip}")) {
        if $old != $plugin and ($old | path basename | str starts-with "dracula-tufte-rider-") {
          $drift = ($drift | append $"($old | path relative-to $ROOT) , built for a version no longer stamped")
        }
      }
    } else {
      package $plugin $version
      print $"  → ($plugin | path relative-to $ROOT)"
      print "Install: Rider → Settings → Plugins → gear → Install Plugin from Disk…"
    }
  }

  let vsix = (vscode-plugin-path $version)
  if not $no_vsix {
    if $check {
      # Same reproducible-bytes probe the Rider jar uses above, for the same reason:
      # the vsix is tracked, and a drift here ships a stale one to whoever installs it.
      let probe = ($vsix | path dirname | path join ".probe.vsix")
      package-vscode $probe $version
      if (not ($vsix | path exists)) or (open --raw $vsix) != (open --raw $probe) {
        $drift = ($drift | append ($vsix | path relative-to $ROOT))
      }
      rm --force $probe
      for old in (glob ($vsix | path dirname | path join "dracula-tufte-vscode-*.vsix")) {
        if $old != $vsix {
          $drift = ($drift | append $"($old | path relative-to $ROOT) , built for a version no longer stamped")
        }
      }
    } else {
      package-vscode $vsix $version
      print $"  → ($vsix | path relative-to $ROOT)"
      print $"Install: code --install-extension ($vsix | path relative-to $ROOT)"
    }
  }

  if $check {
    if ($drift | is-empty) {
      print "Themes fresh."
    } else {
      $drift | each {|f| print $"STALE: ($f). Run `nu scripts/create-themes.nu`" }
      exit 1
    }
  }
}

def plugin-path [version: string]: nothing -> path {
  $ROOT | path join "themes" "rider" "dist" $"dracula-tufte-rider-($version).zip"
}

def vscode-plugin-path [version: string]: nothing -> path {
  $ROOT | path join "themes" "vscode" "dist" $"dracula-tufte-vscode-($version).vsix"
}

# Line 2 of the stylesheet is machine-read in three places already (build-sample.nu,
# maintain.nu bump, and here). Fail loudly rather than stamping a plugin "v", because a
# jar with a blank version installs fine and then never updates.
def version-of-css []: nothing -> string {
  let line = (open --raw ($ROOT | path join "tufte-dracula.css") | lines | get 1)
  let m = ($line | parse --regex 'v(?<v>\d+\.\d+\.\d+)')
  if ($m | is-empty) {
    error make {msg: $"tufte-dracula.css line 2 carries no version: ($line)"}
  }
  $m | first | get v
}

def render [text: string, palette: record, version: string]: nothing -> string {
  mut out = $text
  for key in ($text | parse --regex '\{\{(?<k>[^}]+)\}\}' | get k | uniq) {
    $out = ($out | str replace --all $"{{($key)}}" (resolve $key $palette $version))
  }
  $out
}

def resolve [key: string, palette: record, version: string]: nothing -> string {
  if $key == "version" { return $version }

  if ($key | str starts-with "mix:") {
    let p = ($key | split row ":")
    if ($p | length) != 4 {
      error make {msg: $"bad placeholder {{($key)}}: want mix:base:accent:percent"}
    }
    return (mix (token $palette $p.1) (token $palette $p.2) ($p.3 | into float))
  }

  if ($key | str ends-with ".bright") {
    let name = ($key | str replace ".bright" "")
    return (field $palette $name "bright")
  }

  token $palette $key
}

def token [palette: record, name: string]: nothing -> string {
  field $palette $name "hex"
}

def field [palette: record, name: string, which: string]: nothing -> string {
  if $name not-in ($palette | columns) {
    error make {msg: $"--($name) is not an oklch token in tufte-dracula.css :root"}
  }
  $palette | get $name | get $which | str substring 1..
}

def mix [base: string, accent: string, percent: float]: nothing -> string {
  let t = ($percent / 100)
  [0 1 2] | each {|i|
    let a = (channel $base $i)
    let b = (channel $accent $i)
    ($a + (($b - $a) * $t)) | math round | into int | byte-hex
  } | str join
}

def channel [hex: string, i: int]: nothing -> int {
  $hex | str substring ($i * 2)..<($i * 2 + 2) | into int --radix 16
}

def byte-hex []: int -> string {
  $in | format number | get lowerhex | str replace "0x" ""
      | fill --alignment right --character "0" --width 2
}

def iterm-component [hex: string, i: int]: nothing -> string {
  ((channel $hex $i) | into float) / 255 | into string
}

def iterm-real-dict [hex: string, alpha: float]: nothing -> string {
  [
    "  <dict>"
    "    <key>Color Space</key>"
    "    <string>sRGB</string>"
    "    <key>Red Component</key>"
    $"    <real>(iterm-component $hex 0)</real>"
    "    <key>Green Component</key>"
    $"    <real>(iterm-component $hex 1)</real>"
    "    <key>Blue Component</key>"
    $"    <real>(iterm-component $hex 2)</real>"
    "    <key>Alpha Component</key>"
    $"    <real>($alpha)</real>"
    "  </dict>"
  ] | str join "\n"
}

def iterm-key [name: string, hex: string, alpha: float]: nothing -> string {
  [$"  <key>($name)</key>" (iterm-real-dict $hex $alpha)] | str join "\n"
}

# Same slot map the Ghostty template renders, projected into iTerm2's
# float-component plist instead of a `theme = ` key file.
def render-itermcolors [palette: record, version: string]: nothing -> string {
  mut entries = []
  for slot in $ANSI_SLOTS {
    $entries = ($entries | append (iterm-key $"Ansi ($slot.idx) Color" (resolve $slot.key $palette $version) 1.0))
  }
  $entries = ($entries | append (iterm-key "Background Color" (resolve "surface" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Foreground Color" (resolve "on-surface" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Bold Color" (resolve "on-surface" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Cursor Color" (resolve "pink" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Cursor Text Color" (resolve "surface" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Cursor Guide Color" (resolve "code-bg.bright" $palette $version) 0.25))
  $entries = ($entries | append (iterm-key "Selection Color" (resolve "code-bg.bright" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Selected Text Color" (resolve "on-surface" $palette $version) 1.0))
  $entries = ($entries | append (iterm-key "Link Color" (resolve "link" $palette $version) 1.0))

  [
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    '<plist version="1.0">'
    '<dict>'
    ($entries | str join "\n")
    '</dict>'
    '</plist>'
    ''
  ] | str join "\n"
}

# Rider loads a UI theme only from a plugin, so the installable artefact is built
# here, and it is a zip wrapping a jar, not a bare jar. That distinction is the
# whole reason this function is shaped the way it is.
#
# A bare jar dropped straight into `<config>/plugins/` loads fine. Verified: Rider
# 2026.2 logs `Loaded custom plugins: … Dracula-Tufte (muted) …` and the theme
# appears. What a bare jar does NOT survive is Settings → Plugins → gear → Install
# Plugin from Disk…, which refused it on a second machine while the same file
# copied by hand into the same plugins directory worked. Bare-jar plugins are the
# legacy form; every other plugin in that directory is `Name/lib/*.jar`, and so is
# every marketplace theme (checked against Catppuccin Theme 3.6.1). So:
#
#   dracula-tufte-rider-<version>.zip
#     Dracula-Tufte/
#     Dracula-Tufte/lib/
#     Dracula-Tufte/lib/dracula-tufte-rider-<version>.jar
#         META-INF/
#         META-INF/MANIFEST.MF
#         META-INF/plugin.xml
#         dracula-tufte.theme.json
#         dracula-tufte.xml
#
# Directory entries are written in their own right, ahead of what is inside them.
# Naming only the files gives a zip with no directory entries, which is legal, and
# java.util.zip reads it back without complaint, but not the shape of anything
# known to load, and the one jar that had demonstrably loaded here carried them.
#
# MANIFEST.MF holds no build stamps on purpose. A real Gradle-built manifest
# records the JVM, the OS and the platform build, all of which move between
# machines and would break reproducibility below for nothing: the IDE reads the
# plugin descriptor, not the manifest.
#
# The artefact is tracked, so it has to be byte-reproducible from the same inputs,
# or every run shows up as a diff and no staleness gate can say anything. Three
# things make it so, and all three are load-bearing:
#
#   - `touch -t 198001010000` on every staged entry. A zip records each file's
#     mtime in its header, so an unfrozen build of identical content is a
#     different file. 1980-01-01 is the earliest a zip can store. It has to be
#     applied twice: once before the inner jar is built, and again to the jar
#     itself, which is created new and therefore carries a live mtime.
#   - `-X` drops the uid/gid and extended attributes, which differ per machine.
#   - Entries are named in a fixed order rather than swept up with `-r`. Recursion
#     walks in readdir order, which is not a promise; naming them also stops a new
#     META-INF/*.in template riding along into a shipped jar, which the first
#     build did.
#
# Staged rather than zipped in place because the scheme has to enter the jar as
# dracula-tufte.xml: a theme's `editorScheme` resolves through SchemeManager,
# which registers only *.xml out of a plugin, so a bundled .icls loads as nothing
# and Rider logs "refers to unknown color scheme" while still showing the UI
# theme. It stays .icls on disk, which is what Import Scheme… expects.
def package [out: path, version: string] {
  let dir = ($ROOT | path join "themes" "rider")
  let dist = ($dir | path join "dist")
  let stage = ($dist | path join "stage")
  let jar_name = $"dracula-tufte-rider-($version).jar"

  # Inner jar first, out of its own staging tree.
  let jstage = ($stage | path join "jar")
  rm --recursive --force $stage
  mkdir ($jstage | path join "META-INF")
  cp ($dir | path join "META-INF" "plugin.xml") ($jstage | path join "META-INF" "plugin.xml")
  cp ($dir | path join "dracula-tufte.theme.json") ($jstage | path join "dracula-tufte.theme.json")
  cp ($dir | path join "dracula-tufte.icls") ($jstage | path join "dracula-tufte.xml")
  [ "Manifest-Version: 1.0"
    "Implementation-Title: Dracula-Tufte (muted)"
    $"Implementation-Version: ($version)"
    ""
  ] | str join "\n" | save --force --raw ($jstage | path join "META-INF" "MANIFEST.MF")

  # Files before directories: writing a file bumps its parent's mtime.
  for f in ["META-INF/MANIFEST.MF" "META-INF/plugin.xml" "dracula-tufte.theme.json" "dracula-tufte.xml" "META-INF"] {
    ^touch -t 198001010000 ($jstage | path join $f)
  }

  let jar = ($stage | path join "lib" $jar_name)
  mkdir ($stage | path join "lib")
  cd $jstage
  let jz = (^zip -q -X $jar "META-INF/" META-INF/MANIFEST.MF META-INF/plugin.xml dracula-tufte.theme.json dracula-tufte.xml | complete)
  cd $ROOT
  if $jz.exit_code != 0 {
    rm --recursive --force $stage
    error make {msg: $"zip failed building ($jar_name): ($jz.stderr)"}
  }

  # The outer zip wants Dracula-Tufte/lib/<jar>, so the plugin directory has to be
  # a real path on disk for `zip` to name. `lib` is renamed under it rather than
  # built there in the first place so the jar staging tree can be thrown away.
  let plugin_dir = ($stage | path join "Dracula-Tufte")
  rm --recursive --force $jstage
  mkdir $plugin_dir
  mv ($stage | path join "lib") $plugin_dir
  ^touch -t 198001010000 ($plugin_dir | path join "lib" $jar_name)
  ^touch -t 198001010000 ($plugin_dir | path join "lib")
  ^touch -t 198001010000 $plugin_dir
  rm --force $out

  cd $stage
  let z = (^zip -q -X $out "Dracula-Tufte/" "Dracula-Tufte/lib/" $"Dracula-Tufte/lib/($jar_name)" | complete)
  cd $ROOT
  rm --recursive --force $stage
  if $z.exit_code != 0 {
    error make {msg: $"zip failed: ($z.stderr)"}
  }
}

# VS Code's unpacked-folder install path (Extensions view → … → Install from
# Location…) already works with nothing but the source tree, unlike Rider,
# which cannot load a theme without a plugin at all. A .vsix is still worth
# building: it is the form every other install path expects (the `code
# --install-extension` CLI, drag-and-drop onto the Extensions view, the
# marketplace's own upload format), and it is the one this repo's README no
# longer has to explain away with "there is no .vsix, use Install from
# Location instead."
#
# `@vscode/vsce` is the tool that normally builds this file, and it was tried
# first. Two things ruled it out. Its default file-list step shells out to
# `npm`/`yarn` for dependency detection, and that call failed silently on this
# tree, packaging a .vsix with only the two container manifests and none of
# the actual extension, no error, exit code 0. `--no-dependencies --no-yarn`
# routes around it, but reaching for npm at all, even just to be told there
# are no dependencies, is a second toolchain this repo does not otherwise
# need: `nu`, `python3` and `zip` cover every other artefact here, Rider's jar
# included, and CLAUDE.md's "no build step" already governs the payload this
# repo ships, not only the two inlined files. A .vsix is, underneath, exactly
# what the Rider zip already is: a specific directory shape zipped with `-X`.
# Hand-building it needs the same tool this repo already runs, and nothing
# else.
#
#   dracula-tufte-vscode-<version>.vsix
#     [Content_Types].xml
#     extension.vsixmanifest
#     extension/
#       package.json
#       readme.md
#       themes/
#         dracula-tufte-color-theme.json
#
# That shape, and the manifest and content-types text below, are not a guess
# at the format: they are what `@vscode/vsce package --no-dependencies
# --no-yarn` actually produced from this same package.json and README once
# dependency detection was routed around, trimmed of the empty placeholder
# `<Property>` rows vsce emits for fields this extension does not use, then
# verified installable with `code --install-extension` and selectable via
# Ctrl/Cmd+K Ctrl/Cmd+T. `extension/readme.md` is lowercase because that is
# the name vsce gave it and the manifest's own `Path` has to agree.
#
# `[Content_Types].xml` carries no `{{version}}` and nothing else that ever
# changes, so it is written here rather than as a same-named `.in` template on
# disk: git and most shells treat the literal `[` and `]` in a bare filename
# as glob metacharacters, and a file with nothing to substitute gains nothing
# from the template mechanism the other themes need. `render-itermcolors`
# above is the same call: build it from code when there is no `{{}}` to fill.
#
# Byte-reproducible for the same reason the Rider jar is, and by the same
# three measures: every staged entry gets `touch -t 198001010000` (files
# before the directories that hold them, since writing a file bumps its
# parent's mtime), `-X` drops uid/gid and extended attributes, and the zip is
# built from a fixed entry list rather than `-r`, so `--check` can compare
# bytes instead of trusting that a rebuild came out the same.
def package-vscode [out: path, version: string] {
  let dir = ($ROOT | path join "themes" "vscode")
  let dist = ($dir | path join "dist")
  let stage = ($dist | path join "stage")
  let extension = ($stage | path join "extension")

  rm --recursive --force $stage
  mkdir ($extension | path join "themes")
  cp ($dir | path join "package.json") ($extension | path join "package.json")
  cp ($dir | path join "README.md") ($extension | path join "readme.md")
  cp ($dir | path join "themes" "dracula-tufte-color-theme.json") ($extension | path join "themes" "dracula-tufte-color-theme.json")
  cp ($dir | path join "extension.vsixmanifest") ($stage | path join "extension.vsixmanifest")
  content-types | save --force --raw ($stage | path join "[Content_Types].xml")

  for f in [
    "extension/themes/dracula-tufte-color-theme.json" "extension/themes"
    "extension/package.json" "extension/readme.md" "extension"
    "extension.vsixmanifest" "[Content_Types].xml"
  ] {
    ^touch -t 198001010000 ($stage | path join $f)
  }

  rm --force $out
  cd $stage
  let z = (^zip -q -X $out "[Content_Types].xml" "extension.vsixmanifest"
    "extension/" "extension/package.json" "extension/readme.md"
    "extension/themes/" "extension/themes/dracula-tufte-color-theme.json" | complete)
  cd $ROOT
  rm --recursive --force $stage
  if $z.exit_code != 0 {
    error make {msg: $"zip failed: ($z.stderr)"}
  }
}

def content-types []: nothing -> string {
  let types = ('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    + '<Default Extension=".json" ContentType="application/json"/>'
    + '<Default Extension=".md" ContentType="text/markdown"/>'
    + '<Default Extension=".vsixmanifest" ContentType="text/xml"/></Types>')
  ['<?xml version="1.0" encoding="utf-8"?>' $types ''] | str join "\n"
}
