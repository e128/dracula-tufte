#!/usr/bin/env nu
# maintain.nu — regular upkeep: local contract check (mirrors CI without a
# push round-trip), template-version bump across all 5 sites, CI-gated release
# tagging, mermaid CDN pin bump.
# Run: `nu maintain.nu check|bump <version>|release <version>|mermaid <version>`
#
# ponytail: wraps existing build-sample.nu + string replace, no new build
# system. bump/mermaid stop short of commit — that stays manual. `release` does
# push and tag, because the ordering between them is the whole point: a tag
# pushed beside its commit claims the contract held before anything checked it.

const HERE = path self | path dirname

def main [] {
  print "usage: nu maintain.nu <check|bump <version>|release <version>|mermaid <version>>"
}

# Mirrors .github/workflows/contract-check.yml locally: 8 files exist, the hex
# projections still match the oklch source, exactly one <style>/<script> block
# per fixture, generated files match current CSS/JS.
def "main check" [] {
  mut ok = true

  for f in [tufte-dracula.css mermaid.js filter.js mermaid-palette.json tokens.css sample.html sample-conn-map.html build-sample.nu README.md] {
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
    if $scripts != 2 { print $"($f): expected 2 <script> blocks, found ($scripts)"; $ok = false }
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
  print $"  nu maintain.nu release ($version)"
}

# Tag a release only after CI has gone green on the exact commit being tagged.
#
# This verb does NOT push. `main` requires the `contract` status check, and a
# required check can only be satisfied by a pull request — the check runs after
# a push, so a direct push to main can never have satisfied it and is recorded
# as `Bypassed rule violations`. The work lands through a PR; this runs once it
# has, confirms the check really is green on what merged, and tags that.
#
# ponytail: polls the check-runs API rather than adding a release workflow.
# The gate belongs where a human or an agent tags, not in another YAML file.
def "main release" [version: string] {
  let tag = $"v($version)"
  let sha = (^git rev-parse HEAD | str trim)

  if (^git status --porcelain | str trim) != "" {
    print "Working tree is dirty — commit or stash before releasing."
    exit 1
  }
  # The commit must already be what origin/main points at. That is what proves
  # it arrived through the PR gate rather than around it, and it stops a tag
  # ever naming a commit no one else can fetch.
  ^git fetch --quiet origin main
  let remote = (^git rev-parse origin/main | str trim)
  if $sha != $remote {
    print $"HEAD ($sha | str substring 0..7) is not origin/main ($remote | str substring 0..7)."
    print "  Land the change through a pull request first, then pull and re-run."
    exit 1
  }
  # The tag has to name what the stylesheet says it is, or consumers pin a
  # version that disagrees with the payload they inline.
  let stamped = (open --raw ($HERE | path join "tufte-dracula.css")
    | lines | get 1 | parse --regex 'v(?<v>[\d.]+)' | get v.0)
  if $stamped != $version {
    print $"tufte-dracula.css is stamped v($stamped), not v($version)."
    print $"  Run `nu maintain.nu bump ($version)` and commit first."
    exit 1
  }
  if (^git tag --list $tag | str trim) != "" {
    print $"($tag) already exists locally. Delete it or pick the next version."
    exit 1
  }

  print $"Waiting for checks on ($sha)…"
  mut checks = []
  mut waited = 0
  loop {
    let raw = (^gh api $"repos/{owner}/{repo}/commits/($sha)/check-runs"
      --jq '.check_runs[] | [.name, .status, (.conclusion // "pending")] | @tsv' | complete)
    if $raw.exit_code != 0 {
      print $"gh api failed: ($raw.stderr | str trim)"
      exit 1
    }
    $checks = ($raw.stdout | str trim | lines | where {|l| $l != "" }
      | each {|l|
          let f = ($l | split row "\t")
          {name: $f.0, status: $f.1, conclusion: $f.2}
        })

    # No check at all is a failure, not a pass. A commit that CI never saw is
    # exactly the thing this verb exists to refuse to tag.
    if ($checks | is-not-empty) and ($checks | all {|c| $c.status == "completed" }) { break }
    if $waited >= 600 {
      if ($checks | is-empty) {
        print $"No check run ever appeared for ($sha) after 600s. Not tagging."
      } else {
        print $"Checks still running after 600s. Not tagging."
      }
      exit 1
    }
    sleep 10sec
    $waited = $waited + 10
  }

  for c in $checks { print $"  ($c.name): ($c.conclusion)" }
  let failed = ($checks | where conclusion != "success")
  if ($failed | is-not-empty) {
    print $"NOT TAGGING — ($failed | length) check\(s\) did not pass on ($sha)."
    exit 1
  }

  # Annotated, never lightweight: a lightweight tag is just a second name for a
  # commit, with no tagger, no date and nothing `git tag -v` can even look at.
  let subject = (^git log -1 --pretty=%s | str trim)
  ^git tag -a $tag -m $"($tag) — ($subject)"
  ^git push origin $tag
  print $"Tagged ($tag) on ($sha), verified green."
}

# Bump the mermaid CDN pin to an exact version, regenerate fixtures so the pin
# lands in sample.html/sample-conn-map.html too.
def "main mermaid" [version: string] {
  let path = ($HERE | path join "mermaid.js")
  open --raw $path | str replace --regex 'mermaid@[\d.]+' $"mermaid@($version)" | save -f $path
  nu ($HERE | path join "build-sample.nu")
  print $"mermaid.js pinned to ($version). Review + commit."
}
