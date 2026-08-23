---
name: release
description: Cut a tagged, verified release of the Dracula-Tufte template: bump the version, land it through a PR so the required check gates it, tag the merged commit, and publish the Rider plugin zip, the VS Code vsix, and the themes zip. Use when the user says "make a release", "create a new release", "cut a release", "ship a release", "release this", "tag a release", or names a version to release. Also use when asked to check or repair a release that shipped without its assets.
---

# Release the template

`scripts/maintain.nu` does the work. This skill is the order to call it in, and the two
places where the order is the whole point.

Read [CLAUDE.md](../../../CLAUDE.md) "A tag is a claim the contract held" before
deviating. Everything below is that section made runnable.

## Pick the version

Read the current one, then decide the next:

```
sed -n '2p' tufte-dracula.css     # /* Dracula-Tufte (muted) vX.Y.Z */
git log --oneline "v$(...)"..HEAD # what has landed untagged
```

- `feat:` commits since the last tag, or any new consumer-visible file → **minor**
- `fix:` / `chore:` only → **patch**
- Breaking the `<style>` wrapper contract or the `:root` token names → **major**

Say which you picked and why in one line. Ask only if the untagged commits are a
genuine mix that could read either way.

## Run it

```bash
git switch -c release/vX.Y.Z-<slug>  # never work on main
nu scripts/maintain.nu bump X.Y.Z    # stamps CSS + README, rebuilds fixtures + themes + plugin + vsix
nu scripts/maintain.nu check         # must print "Contract OK"
git add -A && git commit -F -        # message from the diff, see below
git push -u origin release/vX.Y.Z-<slug>
gh pr create --fill
gh pr checks --watch                 # `contract` must pass HERE, not after
gh pr merge --squash
git switch main && git pull --ff-only
nu scripts/maintain.nu release X.Y.Z # verifies green on the merged SHA, then tags + publishes
```

`bump` refuses outright when any tracked file carries an em-dash or an en-dash, which
CLAUDE.md bans. It checks before it stamps anything, so nothing has to be unwound. The
same scan runs in `nu scripts/maintain.nu check` and in the `contract` workflow.

`bump` deletes the old plugin zip and the old vsix and writes new ones. Each
filename carries the version, and each manifest (`META-INF/plugin.xml`,
`extension.vsixmanifest`) reads it off the stylesheet header. Expect
`themes/rider/dist/dracula-tufte-rider-<old>.zip` and
`themes/vscode/dist/dracula-tufte-vscode-<old>.vsix` to disappear from
`git status` as deletes. That is correct.

## Verify before reporting done

A release that shipped with no assets looks identical to one that worked, which
is exactly how v1.17.0 got tagged onto a commit that predated `themes/` with no
release cut at all.

```bash
gh release view vX.Y.Z --json tagName,assets --jq '.tagName, (.assets[] | "\(.name)  \(.size)B")'
git cat-file -t vX.Y.Z                                   # must be `tag`, not `commit`
git ls-tree -r --name-only vX.Y.Z | rg '^themes'         # the tag must contain what it claims
shasum -a 256 themes/rider/dist/dracula-tufte-rider-X.Y.Z.zip
unzip -l themes/rider/dist/dracula-tufte-rider-X.Y.Z.zip # Dracula-Tufte/lib/*.jar
shasum -a 256 themes/vscode/dist/dracula-tufte-vscode-X.Y.Z.vsix
unzip -l themes/vscode/dist/dracula-tufte-vscode-X.Y.Z.vsix # extension/package.json, extension/themes/*.json
```

Three assets must be present: `dracula-tufte-rider-X.Y.Z.zip`,
`dracula-tufte-vscode-X.Y.Z.vsix`, and `dracula-tufte-themes-X.Y.Z.zip`. Report
the plugin zip's and the vsix's sha256 so a second machine can compare after
downloading.

The plugin zip must contain `Dracula-Tufte/lib/dracula-tufte-rider-X.Y.Z.jar` and
nothing flatter. A bare jar loads when copied into `plugins/` by hand and is
**refused by Install Plugin from Disk…**, which is how it actually gets
installed, so a flat artefact passes every check here and fails the only user
who matters.

The vsix must contain `extension.vsixmanifest`, `[Content_Types].xml`, and an
`extension/` directory holding `package.json`, `readme.md`, and
`themes/dracula-tufte-color-theme.json`. Confirm it installs with
`code --install-extension themes/vscode/dist/dracula-tufte-vscode-X.Y.Z.vsix`.

## Commit message

Write it from the diff, normal prose, not caveman. What changed and why it
changed. The repo's history is the design record for anything not in NOTES.md.
Subject line: `feat: vX.Y.Z - <summary>` (or `fix:` / `chore:`).

**No email address anywhere in the message.** Not the maintainer's, not a
co-author trailer's. Name-only `Co-Authored-By: Claude` or omit it.

## Rules with no exception

- **Never `git push origin main`,** and never `git push origin main vX.Y.Z`. One
  command pushing commit and tag together means the tag claims the contract held
  before anything checked it.
- **If a push prints `Bypassed rule violations`, stop and say so in that same
  message.** Protection was overridden, not satisfied. Do not carry on to the
  tag. Offer to revert.
- **Never `--no-verify`. Never force-move a pushed tag.** Consumers pin through a
  submodule; a moved tag silently changes what they resolve to.
- **Annotated tags only.** `scripts/maintain.nu release` does this; do not hand-tag.
- Do not hand-edit `samples/dark.html`, `samples/dark-conn-map.html` or `tokens.css`. Ever.
  They are generated, and `check` fails if regeneration is not a no-op.

## Tooling-only changes

A change that touches no consumer payload (this skill file, a CI workflow, a
`scripts/maintain.nu` refactor) still lands through a PR, but takes **no version bump**
and **no tag**. Commit it as `chore:` and stop. An untagged commit on `main` is
fine; a tag that consumers pin to for nothing is not.

## When a release already shipped wrong

Do not move the tag. Cut the next version with the fix. Say plainly what the bad
tag is missing so anyone pinned to it knows to move.
