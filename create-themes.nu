#!/usr/bin/env nu
# create-themes.nu — regenerate everything under themes/ from tufte-dracula.css,
# then package the Rider theme as an installable plugin jar.
# Run: `nu create-themes.nu` | `nu create-themes.nu --check` | `nu create-themes.nu --no-jar`
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

const HERE = path self | path dirname

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
  let palette = (^python3 ($HERE | path join ".github/palette-check.py") --dump | from json)
  let version = (version-of-css)

  mut drift = []
  for rel in $THEMES {
    let out = ($HERE | path join $rel)
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

  let jar = (jar-path $version)
  if not $no_jar {
    if $check {
      # Build a throwaway and compare bytes. Only meaningful because package
      # freezes every entry timestamp — see there.
      let probe = ($jar | path dirname | path join ".probe.jar")
      package $probe
      if (not ($jar | path exists)) or (open --raw $jar) != (open --raw $probe) {
        $drift = ($drift | append ($jar | path relative-to $HERE))
      }
      rm --force $probe
      # A jar for a version we no longer build is installable and unmaintained.
      # `bump` deletes them; this is what notices when something else did not.
      for old in (glob ($jar | path dirname | path join "*.jar")) {
        if $old != $jar { $drift = ($drift | append $"($old | path relative-to $HERE) — built for a version no longer stamped") }
      }
    } else {
      package $jar
      print $"  → ($jar | path relative-to $HERE)"
      print "Install: Rider → Settings → Plugins → gear → Install Plugin from Disk…"
    }
  }

  if $check {
    if ($drift | is-empty) {
      print "Themes fresh."
    } else {
      $drift | each {|f| print $"STALE: ($f) — run `nu create-themes.nu`" }
      exit 1
    }
  }
}

def jar-path [version: string]: nothing -> path {
  $HERE | path join "themes" "rider" "dist" $"dracula-tufte-rider-($version).jar"
}

# Line 2 of the stylesheet is machine-read in three places already (build-sample.nu,
# maintain.nu bump, and here). Fail loudly rather than stamping a plugin "v" — a
# jar with a blank version installs fine and then never updates.
def version-of-css []: nothing -> string {
  let line = (open --raw ($HERE | path join "tufte-dracula.css") | lines | get 1)
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

# Rider loads a UI theme only from a plugin, so the installable artefact is a jar
# — which is a zip, which is the entire build.
#
# The jar is tracked, so it has to be byte-reproducible from the same inputs, or
# every run shows up as a diff and no staleness gate can say anything. Three
# things make it so, and all three are load-bearing:
#
#   - `touch -t 198001010000` on every staged entry. A zip records each file's
#     mtime in its header, so an unfrozen build of identical content is a
#     different file. 1980-01-01 is the earliest a zip can store.
#   - `-X` drops the uid/gid and extended attributes, which differ per machine.
#   - Entries are named in a fixed order rather than swept up with `-r`. Recursion
#     walks in readdir order, which is not a promise; naming them also stops a new
#     META-INF/*.in template riding along into a shipped jar, which the first
#     build did.
#
# `META-INF/` is named as an entry in its own right, ahead of the file inside it.
# Naming only the files writes a jar with no directory entry at all, which is a
# legal zip and which java.util.zip reads back fine — but it is not the shape of
# any jar known to load here. The one jar that has demonstrably loaded in Rider
# carried the directory entry; the frozen build dropped it and was never installed
# anywhere to find out. Matching the artefact that works costs one argument.
#
# Staged rather than zipped in place because the scheme has to enter the jar as
# dracula-tufte.xml: a theme's `editorScheme` resolves through SchemeManager,
# which registers only *.xml out of a plugin, so a bundled .icls loads as nothing
# and Rider logs "refers to unknown color scheme" while still showing the UI
# theme. It stays .icls on disk — that is what Import Scheme… expects.
def package [out: path] {
  let dir = ($HERE | path join "themes" "rider")
  let stage = ($dir | path join "dist" "stage")

  rm --recursive --force $stage
  mkdir ($stage | path join "META-INF")
  cp ($dir | path join "META-INF" "plugin.xml") ($stage | path join "META-INF" "plugin.xml")
  cp ($dir | path join "dracula-tufte.theme.json") ($stage | path join "dracula-tufte.theme.json")
  cp ($dir | path join "dracula-tufte.icls") ($stage | path join "dracula-tufte.xml")
  # Files before directories: writing a file bumps its parent's mtime.
  ^touch -t 198001010000 ($stage | path join "META-INF" "plugin.xml")
  ^touch -t 198001010000 ($stage | path join "dracula-tufte.theme.json")
  ^touch -t 198001010000 ($stage | path join "dracula-tufte.xml")
  ^touch -t 198001010000 ($stage | path join "META-INF")
  rm --force $out

  cd $stage
  let z = (^zip -q -X $out "META-INF/" META-INF/plugin.xml dracula-tufte.theme.json dracula-tufte.xml | complete)
  cd $HERE
  rm --recursive --force $stage
  if $z.exit_code != 0 {
    error make {msg: $"zip failed: ($z.stderr)"}
  }
}
