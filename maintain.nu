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

# Mirrors .github/workflows/contract-check.yml locally: 7 files exist, exactly
# one <style>/<script> block per fixture, fixtures match current CSS/JS.
def "main check" [] {
  mut ok = true

  for f in [tufte-dracula.css mermaid.js tokens.css sample.html sample-conn-map.html build-sample.nu README.md] {
    if not ($HERE | path join $f | path exists) {
      print $"MISSING: ($f)"
      $ok = false
    }
  }

  for f in [sample.html sample-conn-map.html] {
    let path = ($HERE | path join $f)
    let styles = (^grep -c "<style" $path | into int)
    let scripts = (^grep -c "<script" $path | into int)
    if $styles != 1 { print $"($f): expected 1 <style>, found ($styles)"; $ok = false }
    if $scripts != 1 { print $"($f): expected 1 <script>, found ($scripts)"; $ok = false }
  }

  nu ($HERE | path join "build-sample.nu")
  let diff = (^git diff --stat -- sample.html sample-conn-map.html | complete)
  if ($diff.stdout | str trim | is-not-empty) {
    print "STALE: fixtures changed after regen — commit the result."
    print $diff.stdout
    $ok = false
  } else {
    print "Fixtures fresh."
  }

  if $ok {
    print "Contract OK."
  } else {
    exit 1
  }
}

# Bump the template version everywhere it's written: tufte-dracula.css header
# comment, tokens.css header comment, README's mentions. Regenerates fixtures
# so the new comment lands in sample.html/sample-conn-map.html too.
def "main bump" [version: string] {
  let current = (open --raw ($HERE | path join "tufte-dracula.css")
    | lines | get 1 | parse --regex 'v(?<v>[\d.]+)' | get v.0)
  print $"Bumping v($current) -> v($version)"

  for f in [tufte-dracula.css tokens.css README.md] {
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
