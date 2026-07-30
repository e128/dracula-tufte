#!/usr/bin/env nu
# maintain.nu — regular upkeep: local contract check (mirrors CI without a
# push round-trip), template-version bump across all 5 sites, mermaid CDN pin
# bump. Run: `nu maintain.nu check|bump <version>|mermaid <version>`
#
# ponytail: wraps existing build-sample.nu + string replace, no new build
# system. bump/mermaid stop short of commit/tag/push — those touch shared
# history and stay manual.

const HERE = path self | path dirname

def main [] {
  print "usage: nu maintain.nu <check|bump <version>|mermaid <version>>"
}

# Mirrors .github/workflows/contract-check.yml locally: 8 files exist, the hex
# projections still match the oklch source, exactly one <style>/<script> block
# per fixture, generated files match current CSS/JS.
def "main check" [] {
  mut ok = true

  for f in [tufte-dracula.css mermaid.js mermaid-palette.json tokens.css sample.html sample-conn-map.html build-sample.nu README.md] {
    if not ($HERE | path join $f | path exists) {
      print $"MISSING: ($f)"
      $ok = false
    }
  }

  # Wrapper must stay one line at each end — consumers slice the bare body with
  # `sed '1d;$d'` and that is a promise, not an accident.
  let css_lines = (open --raw ($HERE | path join "tufte-dracula.css") | str trim --right | lines)
  if ($css_lines | first) != "  <style>" { print "tufte-dracula.css line 1 must be exactly '  <style>'"; $ok = false }
  if ($css_lines | last) != "  </style>" { print "tufte-dracula.css last line must be exactly '  </style>'"; $ok = false }

  let palette = (^python3 ($HERE | path join ".github/palette-check.py") | complete)
  print ($palette.stdout | str trim)
  if $palette.exit_code != 0 {
    # stderr carries the parse-guard message and any traceback; `complete` swallows
    # it, so an unprinted stderr means "failed for no stated reason".
    print ($palette.stderr | str trim)
    $ok = false
  }

  for f in [sample.html sample-conn-map.html] {
    let path = ($HERE | path join $f)
    let styles = (^grep -c "<style" $path | into int)
    let scripts = (^grep -c "<script" $path | into int)
    if $styles != 1 { print $"($f): expected 1 <style>, found ($styles)"; $ok = false }
    if $scripts != 1 { print $"($f): expected 1 <script>, found ($scripts)"; $ok = false }
  }

  # Regeneration must be a no-op. Compare bytes across the regen rather than ask
  # git: build-sample.nu git-adds what it writes, so `git diff` is always empty
  # (the gate never fires), and `git diff HEAD` would flag work-in-progress edits
  # that are legitimately uncommitted. CI, with a clean tree, uses `git diff HEAD`.
  let generated = [sample.html sample-conn-map.html tokens.css]
  let before = ($generated | each {|f| open --raw ($HERE | path join $f) })
  nu ($HERE | path join "build-sample.nu")
  let after = ($generated | each {|f| open --raw ($HERE | path join $f) })
  let stale = ($generated | enumerate
    | where {|e| ($before | get $e.index) != ($after | get $e.index) }
    | get item)
  if ($stale | is-not-empty) {
    print $"STALE: regen rewrote ($stale | str join ', ') — commit the result."
    $ok = false
  } else {
    print "Generated files fresh."
  }

  if $ok {
    print "Contract OK."
  } else {
    exit 1
  }
}

# Bump the template version in the two files that are hand-written: the
# tufte-dracula.css header comment and README's mentions. Then regenerate, which
# carries the new version into tokens.css and both fixtures.
def "main bump" [version: string] {
  let current = (open --raw ($HERE | path join "tufte-dracula.css")
    | lines | get 1 | parse --regex 'v(?<v>[\d.]+)' | get v.0)
  print $"Bumping v($current) -> v($version)"

  for f in [tufte-dracula.css README.md] {
    let path = ($HERE | path join $f)
    open --raw $path | str replace --all $"v($current)" $"v($version)" | save -f $path
  }

  nu ($HERE | path join "build-sample.nu")
  print $"Bumped. Review the diff, then:"
  print $"  git add -A && git commit -m 'feat: v($version) — <summary>'"
  print $"  git tag v($version) && git push origin main v($version)"
}

# Bump the mermaid CDN pin to an exact version, regenerate fixtures so the pin
# lands in sample.html/sample-conn-map.html too.
def "main mermaid" [version: string] {
  let path = ($HERE | path join "mermaid.js")
  open --raw $path | str replace --regex 'mermaid@[\d.]+' $"mermaid@($version)" | save -f $path
  nu ($HERE | path join "build-sample.nu")
  print $"mermaid.js pinned to ($version). Review + commit."
}
