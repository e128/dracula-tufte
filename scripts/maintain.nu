#!/usr/bin/env nu
# maintain.nu — regular upkeep: local contract check (mirrors CI without a
# push round-trip), release-gate selftest, template-version bump across all 5
# sites, CI-gated release tagging, mermaid CDN pin bump.
# Run: `nu maintain.nu check|selftest|bump <version>|release <version>|mermaid <version>`
#
# ponytail: wraps existing build-sample.nu + string replace, no new build
# system. bump/mermaid stop short of commit — that stays manual. `release` does
# push and tag, because the ordering between them is the whole point: a tag
# pushed beside its commit claims the contract held before anything checked it.

# path self is this file, so its dirname is scripts/ and ROOT is the repo above it.
# Everything resolves from ROOT, never from cwd, so this runs from anywhere in the tree.
# SCRIPTS exists because `path self | path dirname | path dirname` is not a legal const
# chain in Nushell — the second step has to read a name that is already bound.
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname

def main [] {
  print "usage: nu scripts/maintain.nu <check|selftest|bump <version>|release <version>|mermaid <version>>"
}

# Mirrors .github/workflows/contract-check.yml locally, step for step: ten files
# exist, the wrapper is one line at each end, mermaid.js agrees with
# mermaid-palette.json key by key, the hex projections still match the oklch
# source, all four palettes hold their contrast floor, exactly one <style> and two
# <script> per fixture, each appearance mode paints its own surface, generated
# files match the current CSS/JS.
#
# "Step for step" is the whole point of the verb: a local pass that CI would fail
# is worse than no local check, because it is trusted. Add a step here whenever
# contract-check.yml gains one.
def "main check" [] {
  mut ok = true

  for f in [tufte-dracula.css mermaid.js filter.js mermaid-palette.json tokens.css sample.html sample-conn-map.html scripts/build-sample.nu README.md CONTRACT.md] {
    if not ($ROOT | path join $f | path exists) {
      print $"MISSING: ($f)"
      $ok = false
    }
  }

  # Wrapper must stay one line at each end — consumers slice the bare body with
  # `sed '1d;$d'` and that is a promise, not an accident.
  let css_lines = (open --raw ($ROOT | path join "tufte-dracula.css") | str trim --right | lines)
  if ($css_lines | first) != "  <style>" { print "tufte-dracula.css line 1 must be exactly '  <style>'"; $ok = false }
  if ($css_lines | last) != "  </style>" { print "tufte-dracula.css last line must be exactly '  </style>'"; $ok = false }

  let palette = (^python3 ($ROOT | path join ".github/palette-check.py") | complete)
  print ($palette.stdout | str trim)
  if $palette.exit_code != 0 {
    # stderr carries the parse-guard message and any traceback; `complete` swallows
    # it, so an unprinted stderr means "failed for no stated reason".
    print ($palette.stderr | str trim)
    $ok = false
  }

  # mermaid.js is inlined verbatim, so it carries its own hex and can drift from
  # the palette that documents it. palette-check.py only asks whether a hex is *a*
  # palette colour; it cannot see that a key points at the wrong one. That pairing
  # gate lived only in CI, which meant a themeVariable set to some other palette
  # colour passed here and failed on the push.
  let init = (open ($ROOT | path join "mermaid-palette.json") | get init
    | transpose key entry | where key != "_comment")
  if ($init | length) < 16 {
    print $"mermaid-palette.json .init has only ($init | length) keys — refusing to pass vacuously"
    $ok = false
  }
  let js = (open --raw ($ROOT | path join "mermaid.js"))
  for e in $init {
    if not ($js =~ $"($e.key):\\s*'($e.entry.hex)'") {
      print $"DRIFT: mermaid.js ($e.key) is not '($e.entry.hex)' \(mermaid-palette.json)"
      $ok = false
    }
  }
  if not ($js =~ "theme: 'base'") { print "mermaid.js must use theme:'base', not 'dark'"; $ok = false }

  # Count occurrences, not matching lines. `grep -c` reports lines, so a second
  # block opened on a line that already has one reads as 1 and passes.
  for f in [sample.html sample-conn-map.html preview-light.html preview-conn-map-light.html] {
    let body = (open --raw ($ROOT | path join $f))
    let styles = (($body | split row "<style" | length) - 1)
    let scripts = (($body | split row "<script" | length) - 1)
    if $styles != 1 { print $"($f): expected 1 <style>, found ($styles)"; $ok = false }
    if $scripts != 2 { print $"($f): expected 2 <script> blocks, found ($scripts)"; $ok = false }
  }

  # The previews are the fixtures with the light condition forced on and the
  # contrast condition forced off. If the stylesheet renames either one,
  # `str replace` no-ops and the preview ships the default palette while still
  # regenerating cleanly, so Pages would serve a dark page called light. The
  # generator raises on that, and this asserts the same property on the committed
  # file, which is what a hand-edit would get past the generator.
  for f in [preview-light.html preview-conn-map-light.html] {
    let body = (open --raw ($ROOT | path join $f))
    if not ($body =~ '@media all \{') { print $"($f): no forced `@media all {` — the light palette is not on"; $ok = false }
    if not ($body =~ '@media not all \{') { print $"($f): no `@media not all {` — the contrast block is still live"; $ok = false }
    if ($body | str replace --all --regex '(?s)<p>This page forces.*?</p>' '') =~ 'prefers-color-scheme' {
      print $"($f): a prefers-color-scheme condition survived the rewrite"
      $ok = false
    }
  }

  # Light and high-contrast mode are media queries, so no fixture shows them and
  # nothing else here proves they reach the page. Writes into a temp dir rather
  # than the repo: the PNGs are review output in CI, not tracked files, and a
  # stray mode-renders/ would show up as untracked noise on every local check.
  let renders = (mktemp -d)
  let modes = (^python3 ($ROOT | path join ".github/render-modes.py") $renders | complete)
  print ($modes.stdout | str trim)
  if $modes.exit_code != 0 {
    print ($modes.stderr | str trim)
    $ok = false
  }
  rm -rf $renders

  # Regeneration must be a no-op. Compare bytes across the regen rather than ask
  # git: build-sample.nu git-adds what it writes, so `git diff` is always empty
  # (the gate never fires), and `git diff HEAD` would flag work-in-progress edits
  # that are legitimately uncommitted. CI, with a clean tree, uses `git diff HEAD`.
  let generated = [sample.html sample-conn-map.html preview-light.html preview-conn-map-light.html tokens.css]
  let before = ($generated | each {|f| open --raw ($ROOT | path join $f) })
  nu ($SCRIPTS | path join "build-sample.nu")
  let after = ($generated | each {|f| open --raw ($ROOT | path join $f) })
  let stale = ($generated | enumerate
    | where {|e| ($before | get $e.index) != ($after | get $e.index) }
    | get item)
  if ($stale | is-not-empty) {
    print $"STALE: regen rewrote ($stale | str join ', ') — commit the result."
    $ok = false
  } else {
    print "Generated files fresh."
  }

  # themes/ is generated too, from the same :root palette. A stale theme is worse
  # than a stale fixture: `release` attaches the Rider jar to the tag, so drift
  # here ships to whoever installs it. The jar is tracked and covered by this
  # gate — create-themes.nu freezes the zip's entry timestamps precisely so its
  # bytes can be compared rather than assumed.
  let themes = (^nu ($SCRIPTS | path join "create-themes.nu") --check | complete)
  print ($themes.stdout | str trim)
  if $themes.exit_code != 0 { $ok = false }

  if $ok {
    print "Contract OK."
  } else {
    exit 1
  }
}

# Bump the template version in the two files that are hand-written: the
# tufte-dracula.css header comment and README's two current-version stamps. Then
# regenerate, which carries the new version into tokens.css and both fixtures.
#
# Each stamp is rewritten through its own anchored pattern. A blanket
# `str replace --all v<current> v<new>` was the original implementation, and it
# corrupted documentation history on every release: prose that says a feature
# landed "as of v1.21.0" is a historical claim, not a stamp, and the blanket
# replace walked all of those forward one version at a time. v1.22.0 shipped with
# five such claims reattributed to a release that had not happened. CONTRACT.md's
# per-version delta table is the same shape of data and would rot the same way.
#
# STAMPS is therefore the whole contract: a stamp is a place that names the
# CURRENT version, and nothing else in these files may be touched. Every pattern
# must match, or the bump fails — a silent no-op leaves the tree claiming the old
# version while the release process believes it was stamped.
const STAMPS = [
  [file pattern template]; # pattern is a regex; template takes {v}
  [tufte-dracula.css '/\* Dracula-Tufte \(muted\) v[\d.]+ \*/' '/* Dracula-Tufte (muted) v{v} */']
  [README.md '\(template v[\d.]+, oklch palette\)' '(template v{v}, oklch palette)']
  [README.md 'is \*\*`v[\d.]+`\*\*' 'is **`v{v}`**']
]

def "main bump" [version: string] {
  let current = (open --raw ($ROOT | path join "tufte-dracula.css")
    | lines | get 1 | parse --regex 'v(?<v>[\d.]+)' | get v.0)
  print $"Bumping v($current) -> v($version)"

  for stamp in $STAMPS {
    let path = ($ROOT | path join $stamp.file)
    let before = (open --raw $path)
    let after = ($before | str replace --all --regex $stamp.pattern ($stamp.template | str replace "{v}" $version))
    if $after == $before {
      error make { msg: $"bump found no match for ($stamp.pattern) in ($stamp.file) — stamp moved or already current, and a silent no-op would ship the wrong version" }
    }
    $after | save -f $path
    print $"  stamped ($stamp.file)"
  }

  nu ($SCRIPTS | path join "build-sample.nu")
  # The plugin zip's filename carries the version and META-INF/plugin.xml reads it
  # off the stylesheet header, which is what just changed — so this writes a new
  # artefact and leaves the old one behind. Deleting it is the point: a stale
  # dracula-tufte-rider-<old>.zip in the tree is installable, and nothing
  # regenerates or checks it.
  #
  # Globs .jar as well, to sweep up the bare-jar artefact this repo shipped
  # through v1.18.0. That shape loads when copied into plugins/ by hand but
  # Install Plugin from Disk refuses it, so leaving one behind hands someone the
  # exact file that already failed.
  let old = (glob ($ROOT | path join "themes" "rider" "dist" "dracula-tufte-rider-*.{jar,zip}"))
  if ($old | is-not-empty) { rm --force ...$old }
  nu ($SCRIPTS | path join "create-themes.nu")
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
#
# Only REQUIRED_CHECKS decide. GitHub attaches a check run to a commit for every
# workflow that fires, including ones it generates itself — pages-build-deployment
# contributes build/deploy/report-build-status. Those say nothing about the payload,
# and gating on "every check green" meant a stalled Pages deploy could block, or
# permanently refuse, a tag whose contract CI had already verified in 14 seconds.
# Keep this list in step with the required checks on `main`.
const REQUIRED_CHECKS = [contract]

# Split out of the poll loop so `main selftest` can drive it with the check shapes
# GitHub actually produces, including the two that got this wrong. Waiting on the
# live API to exercise a gate is how the Pages bug survived in the first place.
#
# Per name, not by row count: a re-run, or two workflows sharing a job name, can
# put more than one run under one name, and counting rows against REQUIRED_CHECKS
# would then never match and would time out on a green commit.
def check-ready [checks: list] {
  $REQUIRED_CHECKS | all {|n|
    let runs = ($checks | where name == $n)
    ($runs | is-not-empty) and ($runs | all {|c| $c.status == "completed" })
  }
}

def check-failures [checks: list] {
  $checks | where {|c| $c.name in $REQUIRED_CHECKS and $c.conclusion != "success" }
}

def check-missing [checks: list] {
  $REQUIRED_CHECKS | where {|n| not ($checks | any {|c| $c.name == $n }) }
}

def "main release" [version: string] {
  let tag = $"v($version)"
  # Every git call is pinned to $ROOT and gh to the slug read from its origin.
  # Bare `git` and gh's {owner}/{repo} both resolve against the cwd, so running
  # this script by absolute path from inside another repo would read that repo's
  # HEAD and push a tag there, while validating this one's version stamp.
  let sha = (^git -C $ROOT rev-parse HEAD | str trim)
  let slug = (^git -C $ROOT remote get-url origin | str trim
    | parse --regex '[:/](?<owner>[^/:]+)/(?<repo>[^/]+?)(:?\.git)?$'
    | get 0 | $"($in.owner)/($in.repo)")

  if (^git -C $ROOT status --porcelain | str trim) != "" {
    print "Working tree is dirty — commit or stash before releasing."
    exit 1
  }
  # The commit must already be what origin/main points at. That is what proves
  # it arrived through the PR gate rather than around it, and it stops a tag
  # ever naming a commit no one else can fetch.
  ^git -C $ROOT fetch --quiet origin main
  let remote = (^git -C $ROOT rev-parse origin/main | str trim)
  if $sha != $remote {
    print $"HEAD ($sha | str substring 0..7) is not origin/main ($remote | str substring 0..7)."
    print "  Land the change through a pull request first, then pull and re-run."
    exit 1
  }
  # The tag has to name what the stylesheet says it is, or consumers pin a
  # version that disagrees with the payload they inline.
  let stamped = (open --raw ($ROOT | path join "tufte-dracula.css")
    | lines | get 1 | parse --regex 'v(?<v>[\d.]+)' | get v.0)
  if $stamped != $version {
    print $"tufte-dracula.css is stamped v($stamped), not v($version)."
    print $"  Run `nu maintain.nu bump ($version)` and commit first."
    exit 1
  }
  if (^git -C $ROOT tag --list $tag | str trim) != "" {
    print $"($tag) already exists locally. Delete it or pick the next version."
    exit 1
  }
  # Checked before the poll, not after the tag: this verb builds the Rider jar
  # from the theme files on disk and attaches it to the release. Stale files
  # here would ship a jar that disagrees with the tag, and regenerating after
  # the clean-tree check would dirty the tree behind our own gate.
  let themes = (^nu ($SCRIPTS | path join "create-themes.nu") --check | complete)
  if $themes.exit_code != 0 {
    print ($themes.stdout | str trim)
    print "  Run `nu create-themes.nu` and commit the result first."
    exit 1
  }

  print $"Waiting for ($REQUIRED_CHECKS | str join ', ') on ($sha) in ($slug)…"
  mut checks = []
  mut waited = 0
  loop {
    let raw = (^gh api $"repos/($slug)/commits/($sha)/check-runs"
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

    # Absent is not passing. A required check that never appeared means a commit CI
    # never saw, which is exactly the thing this verb exists to refuse to tag — so
    # wait for every name in REQUIRED_CHECKS to be present *and* completed.
    if (check-ready $checks) { break }
    if $waited >= 600 {
      let missing = (check-missing $checks)
      if ($missing | is-not-empty) {
        print $"No ($missing | str join ', ') check run ever appeared for ($sha) after 600s. Not tagging."
      } else {
        print $"($REQUIRED_CHECKS | str join ', ') still running after 600s. Not tagging."
      }
      exit 1
    }
    sleep 10sec
    $waited = $waited + 10
  }

  for c in $checks {
    let note = if $c.name in $REQUIRED_CHECKS { "" } else { " (advisory)" }
    print $"  ($c.name): ($c.conclusion)($note)"
  }
  let failed = (check-failures $checks)
  if ($failed | is-not-empty) {
    print $"NOT TAGGING — ($failed | length) required check\(s\) did not pass on ($sha)."
    exit 1
  }

  # Annotated, never lightweight: a lightweight tag is just a second name for a
  # commit, with no tagger, no date and nothing `git tag -v` can even look at.
  let subject = (^git -C $ROOT log -1 --pretty=%s | str trim)
  ^git -C $ROOT tag -a $tag -m $"($tag) — ($subject)"
  # A failed push used to still print "Tagged … verified green", leaving a tag that
  # exists only on this machine while the message says consumers can pin it.
  let pushed = (^git -C $ROOT push origin $tag | complete)
  if $pushed.exit_code != 0 {
    print $"($tag) was created locally but the push failed:"
    print ($pushed.stderr | str trim)
    print $"  Nothing is released yet. Fix the remote, then: git push origin ($tag)"
    exit 1
  }
  print $"Tagged ($tag) on ($sha), verified green."
  publish-plugin $tag $slug $version
}

# The Rider theme is the one artefact a consumer cannot take from the source
# tree. Rider loads a UI theme only from a plugin, so `create-themes.nu` packages
# one, and attaching it to the release is what makes a tag something a person can
# install rather than something they have to build.
#
# The other editor themes go up as one themes zip alongside it. They are plain
# files in the tree, so GitHub's own source zip already carries them — but only
# for someone willing to download the whole template and find themes/. An asset
# named for the job is what a person on a second machine actually wants, and
# v1.17.0 shipped with neither: the tag landed on a commit before themes/ existed
# and no release was ever cut, so there was nothing to download at all.
#
# Runs after the tag is pushed, on purpose: the tag is the gated claim, and a
# failed upload must not be able to un-say it. If this half fails the tag stands
# and the retry is one command.
def publish-plugin [tag: string, slug: string, version: string] {
  nu ($SCRIPTS | path join "create-themes.nu")
  let plugin = ($ROOT | path join "themes" "rider" "dist" $"dracula-tufte-rider-($version).zip")
  if not ($plugin | path exists) {
    print $"create-themes.nu produced no ($plugin | path basename). ($tag) is tagged with no plugin attached."
    exit 1
  }
  let themes = (theme-bundle $version)

  let rel = (^gh release create $tag --repo $slug --title $tag --generate-notes $plugin $themes | complete)
  if $rel.exit_code != 0 {
    print $"($tag) is tagged and pushed, but publishing the release failed:"
    print ($rel.stderr | str trim)
    print $"  The tag stands. Retry with:"
    print $"  gh release create ($tag) --repo ($slug) --title ($tag) --generate-notes ($plugin) ($themes)"
    exit 1
  }
  print $"Released ($tag) with ($plugin | path basename) and ($themes | path basename) attached."
}

# Zip the editor themes for the release. The exclusions are the whole content
# decision:
#   - dist/* — the jar is its own asset, and a jar nested inside a zip is a thing
#     people install by mistake.
#   - *.in — the generation templates. They carry `{{token}}` placeholders, so a
#     consumer who installs one gets a theme with literal braces for colours.
#   - .DS_Store — gitignored, so git never sees it, but zip walks the real disk.
# Written to dist/, which .gitignore covers for *.zip, so this leaves no
# untracked artefact behind to go stale.
def theme-bundle [version: string]: nothing -> path {
  let out = ($ROOT | path join "themes" "rider" "dist" $"dracula-tufte-themes-($version).zip")
  rm --force $out
  cd $ROOT
  let z = (^zip -q -r -X $out themes -x 'themes/rider/dist/*' '*.in' '*.DS_Store' | complete)
  if $z.exit_code != 0 or (not ($out | path exists)) {
    print $"zip failed building ($out | path basename): ($z.stderr | str trim)"
    exit 1
  }
  $out
}

# Drive the release gate with the check shapes GitHub really produces. No network,
# no repo state — it exists because the gate cannot otherwise be exercised without
# waiting on a live commit, and the two cases marked below are bugs that shipped.
def "main selftest" [] {
  let cases = [
    # [label, checks, ready, missing, failures]
    ["required green, advisory still running" [[name status conclusion]; [contract completed success] [build completed success] [deploy in_progress pending]] true [] 0]
    ["required green, advisory failed"        [[name status conclusion]; [contract completed success] [deploy completed failure]] true [] 0]
    ["required failed"                        [[name status conclusion]; [contract completed failure] [deploy completed success]] true [] 1]
    ["no checks at all"                       [] false [contract] 0]
    ["required absent, others present"        [[name status conclusion]; [deploy completed success]] false [contract] 0]
    ["required still running"                 [[name status conclusion]; [contract in_progress pending]] false [] 1]
    ["required re-run, both green"            [[name status conclusion]; [contract completed success] [contract completed success]] true [] 0]
    ["required re-run, one still going"       [[name status conclusion]; [contract completed success] [contract in_progress pending]] false [] 1]
    ["required re-run, one failed"            [[name status conclusion]; [contract completed success] [contract completed failure]] true [] 1]
  ]
  mut ok = true
  for c in $cases {
    let checks = ($c.1 | default [])
    let got = {ready: (check-ready $checks), missing: (check-missing $checks), failures: (check-failures $checks | length)}
    let want = {ready: $c.2, missing: $c.3, failures: $c.4}
    if $got != $want {
      print $"FAIL ($c.0): got ($got | to nuon), want ($want | to nuon)"
      $ok = false
    }
  }
  if $ok {
    print $"Release gate OK \(($cases | length) cases)."
  } else {
    exit 1
  }
}

# Bump the mermaid CDN pin to an exact version, regenerate fixtures so the pin
# lands in sample.html/sample-conn-map.html too.
def "main mermaid" [version: string] {
  let path = ($ROOT | path join "mermaid.js")
  open --raw $path | str replace --regex 'mermaid@[\d.]+' $"mermaid@($version)" | save -f $path
  nu ($SCRIPTS | path join "build-sample.nu")
  print $"mermaid.js pinned to ($version). Review + commit."
}
