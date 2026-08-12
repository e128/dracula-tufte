#!/usr/bin/env nu
# create-themes.nu — regenerate everything under themes/ from tufte-dracula.css,
# then package the Rider theme as an installable plugin jar.
# Run: `nu scripts/create-themes.nu` | `… --check` | `… --no-jar`
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
# Templates write bare hex, never `#rrggbb` — the `#` belongs to the format, so
# Ghostty and the Rider theme.json write `#{{green}}` and the .icls writes
# `{{green}}`. One placeholder vocabulary, no per-file escaping rule.
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
# chain in Nushell — the second step has to read a name that is already bound.
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname

# Pairs are (template, output). Output is always the template minus `.in`, but
# spelling both keeps the list greppable from either direction.
const THEMES = [
  "themes/ghostty/dracula-tufte"
  "themes/rider/dracula-tufte.icls"
  "themes/rider/dracula-tufte.theme.json"
  "themes/rider/META-INF/plugin.xml"
  "themes/zed/dracula-tufte.json"
]

def main [
  --check       # render in memory and fail on drift instead of writing
  --no-jar      # skip packaging, just write the theme files
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

  let plugin = (plugin-path $version)
  if not $no_jar {
    if $check {
      # Build a throwaway and compare bytes. Only meaningful because package
      # freezes every entry timestamp — see there.
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
          $drift = ($drift | append $"($old | path relative-to $ROOT) — built for a version no longer stamped")
        }
      }
    } else {
      package $plugin $version
      print $"  → ($plugin | path relative-to $ROOT)"
      print "Install: Rider → Settings → Plugins → gear → Install Plugin from Disk…"
    }
  }

  if $check {
    if ($drift | is-empty) {
      print "Themes fresh."
    } else {
      $drift | each {|f| print $"STALE: ($f) — run `nu scripts/create-themes.nu`" }
      exit 1
    }
  }
}

def plugin-path [version: string]: nothing -> path {
  $ROOT | path join "themes" "rider" "dist" $"dracula-tufte-rider-($version).zip"
}

# Line 2 of the stylesheet is machine-read in three places already (build-sample.nu,
# maintain.nu bump, and here). Fail loudly rather than stamping a plugin "v" — a
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
      error make {msg: $"bad placeholder {{($key)}} — want mix:base:accent:percent"}
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

# Rider loads a UI theme only from a plugin, so the installable artefact is built
# here — and it is a zip wrapping a jar, not a bare jar. That distinction is the
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
# Naming only the files gives a zip with no directory entries — legal, and
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
#     applied twice — once before the inner jar is built, and again to the jar
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
# theme. It stays .icls on disk — that is what Import Scheme… expects.
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
