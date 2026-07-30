# CLAUDE.md — Tufte-Dracula template

Instructions for any agent working in this repo. These override default behaviour.

## Read [NOTES.md](NOTES.md) first

**Before changing `tufte-dracula.css` or `mermaid.js`, read [NOTES.md](NOTES.md).** It is
the reasoning that used to live in those files as comments: every measured number, every
rejected alternative, and every decision that has already been re-litigated.

This is not optional background. Several changes in this repo's history were correct on
paper, shipped, and had to be reverted — the measure cap, two page-width attempts, a
monospace table stack. NOTES.md records what was tried, what it measured, and why it was
undone, specifically so the same ground is not covered twice.

If you are about to "fix" something that looks obviously wrong — a 178-character measure,
a heading heavier than its parent, an inert `themeVariable`, a table that could be
narrower — **it is probably in NOTES.md already, with the measurement that settled it.**
Check there before touching the CSS, and if you still disagree, say so explicitly rather
than silently reversing a documented decision.

When you make a new decision worth keeping, add it to NOTES.md rather than to the
stylesheet.

## NEVER write comments in files that get inlined into HTML

`tufte-dracula.css` and `mermaid.js` are **copied verbatim into every generated HTML
file**. A comment written here is not written once — it is duplicated into every page a
consumer renders, forever.

**Rules:**

- **Do not add comments to `tufte-dracula.css` or `mermaid.js`.** Not block comments, not
  end-of-line comments, not "just one line to explain this magic number".
- The same applies to any future file that is inlined rather than linked: if a consumer
  copies it into output, it carries no comments.
- `mermaid-palette.json` has `_comment` keys already; do not add more.
- **Two exceptions exist, and neither is prose — both are machine-read. Do not remove:**
  - **Line 2 of `tufte-dracula.css`** must be a comment containing the template version,
    in the form `/* Dracula-Tufte (muted) vMAJOR.MINOR.PATCH */`. `build-sample.nu` parses it out of
    `lines | get 1` to stamp `tokens.css`, and `maintain.nu bump` rewrites it. Remove it
    and regeneration dies with `index too large (empty content)` — which fails *silently*
    if you pipe the output, leaving stale fixtures that look fine.
  - **The `/* was #rrggbb */` notes on ten `:root` tokens.** `.github/palette-check.py`
    check 3 parses them and fails if a stated hex disagrees with its `oklch()`. Deleting
    them silently disables that gate. Match the exact format if a token is added.
- Nushell scripts (`build-sample.nu`, `maintain.nu`), `README.md`, `backlog.md` and this
  file are **not** inlined. Comment those normally.

**Where the reasoning goes instead**, in order of preference:

1. **[NOTES.md](NOTES.md)** — the durable home for why a declaration looks the way it
   does: measurements, rejected alternatives, and settled decisions. This is the file a
   future agent reads instead of the comments.
2. **The commit message** for the narrative of a single change.
3. **`backlog.md`** for open decisions and deferred work.
4. **`README.md`** for anything a consumer needs to know.

Never delete a load-bearing explanation outright — move it to NOTES.md.

## Regeneration and the contract

- `sample.html`, `sample-conn-map.html` and `tokens.css` are **generated**. Never hand-edit
  them. Change `tufte-dracula.css` / `mermaid.js` / `build-sample.nu`, then regenerate.
- Run `nu maintain.nu check` after every change. It mirrors CI: file presence, the palette
  hex-vs-oklch gate, exactly one `<style>` and one `<script>` per fixture, and a staleness
  check that regeneration is a no-op. It must print `Contract OK`.
- The first line of `tufte-dracula.css` must be exactly `  <style>` and the last exactly
  `  </style>`. Consumers slice the body out with `sed '1d;$d'`; this is a contract.
- `tufte-dracula.css` carries its own `<style>` wrapper and `mermaid.js` its own
  `<script>` wrapper. Do not add a second one.

## Constraints that shape every decision

- **No build step.** Consumers inline two files verbatim. Anything requiring compilation,
  bundling, or a preprocessor is out.
- **Output renders locally, often offline.** A CDN dependency must degrade gracefully —
  the webfont falls back to a system serif and text still renders. Mermaid is the existing
  exception and it fails hard offline.
- **Mermaid colours must be hex, never `oklch()`.** Its colour engine (khroma) throws
  "Unsupported color format" on an `oklch()` string and aborts init, so no diagram
  renders. `mermaid-palette.json` and `.github/palette-check.py` keep the hex honest
  against the oklch source.
- CDN dependencies are pinned to an exact version, never a range.

## Verify by rendering, not by reasoning

This stylesheet has a history of changes that were correct on paper and wrong on screen.
Do not report a visual or typographic change as done until it has been rendered.

- Playwright + Chromium is available. Measure computed values, not intended ones.
- Check 390 / 768 / 1280 / 1920 at minimum; width and type-scale changes need 2560 too.
- Both fixtures. `body.conn-map` has its own layout and has broken independently before.
- For accessibility claims, read the real accessibility tree
  (CDP `Accessibility.getFullAXTree`), not the markup.

## Style decisions that are already settled

Do not "fix" these; they are deliberate and were re-litigated at least once. Each has its
measurement and its failed alternatives written up in [NOTES.md](NOTES.md):

- **The long measure.** Prose runs well past 60–75 characters per line. Capping it strands
  copy in a narrow column with an empty container. Width is traded for measure knowingly.
- **Page width is one number**, `--page-width` in `:root`, shared by both layouts. Do not
  introduce a second width convention, a breakpoint override, or a full-bleed breakout.
- **Headings are `em`**, so they track the body clamp rather than the fixed root.
- **`h1`/`h2` sit at weight 400** — they are large enough to carry it. Anything at text
  size must not be lighter than body copy.
