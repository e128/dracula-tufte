# dracula-tufte

Arrr, gather 'round ye landlubbers — this here be the public contract for the **Tufte-Dracula** HTML conventions, hoist high as the single source of truth for the stylesheet, palette, Mermaid init, and sample fixtures.

This repo be the canonical home fer the seven artifacts that fer too long were scattered like spilled grog. Consumers pull this repo in through a pinned git submodule at `external/dracula-tufte/` — one place, one truth, no driftin'.

## Live Previews

Rendered in-browser via GitHub Pages (main branch, served straight — no build step):

- [sample.html](https://e128.github.io/dracula-tufte/sample.html) — component sample
- [sample-conn-map.html](https://e128.github.io/dracula-tufte/sample-conn-map.html) — connections-map layout

## The Seven Files

| File                  | What It Be |
|-----------------------|------------|
| `tufte-dracula.css`   | **The stylesheet payload.** The complete `<style>…</style>` block (template v1.5.3, oklch palette). Consumers inline this verbatim into every generated HTML file. Includes the wrapping `<style>` tags and 2-space leading indent — the exact byte sequence the renderer emits. |
| `mermaid.js`          | **The Mermaid init script.** The complete `<script type="module">…</script>` block — the `mermaid@11` CDN import, `theme: 'dark'` init, and click-to-zoom overlay handler. Despite the `.js` name it holds the wrapping `<script>` tags. Consumers inline this only when the rendered scroll contains a ` ```mermaid ` fence. Bump the CDN pin here. |
| `tokens.css`          | **Palette reference.** A `:root { … }` custom-property extract (oklch values). Documentation only — **not read by the renderer**. The same declarations live inside `tufte-dracula.css`. |
| `build-sample.nu`     | **The sample regenerator.** Runs `nu build-sample.nu` to rebuild both `sample.html` and `sample-conn-map.html` from the canonical CSS + JS. Run after any stylesheet or Mermaid change. |
| `sample.html`         | **Living style fixture.** Generated default-body demo — headings, sidenotes, tables, scorecard, verdict chips, nav, badges, mermaid + zoom. Self-contained. Do not hand-edit — regenerate via `build-sample.nu`. |
| `sample-conn-map.html` | **Conn-map fixture.** Generated `<body class="conn-map">` two-section layout (Graph, Links) — the connections-map split `sample.html` can't show inline. Resize past 900px to see Links float left+sticky. |
| `README.md`           | **This here scroll.** |

## Consumers

Consumers pin to a tag (currently **`v1.5.3`**) via a git submodule at `external/dracula-tufte/`. To refresh a consumer: bump the submodule pointer, run `git submodule update --remote external/dracula-tufte`, then commit the new pointer.

## Releases

1. Edit the stylesheet or Mermaid script.
2. Run `nu build-sample.nu` to regenerate both fixtures.
3. Bump the version line in `tufte-dracula.css` (the template version).
4. Commit with a conventional message (`feat: ...` / `fix: ...`).
5. Tag with the next semver: `git tag v1.5.3 && git push origin v1.5.3`.
6. Each consumer repo runs `git submodule update --remote external/dracula-tufte` and commits the new pointer.

## Contract Enforcement

The CI workflow `.github/workflows/contract-check.yml` verifies all seven files exist on every push and PR. Consumers run their own contract gates that scan for any hand-rolled `<style>` blocks bypassing the submodule — those gates fail CI.

If ye find a violation in a consumer, fix the consumer to read from `external/dracula-tufte/`. Don't add a copy.

## License

MIT — see [LICENSE](./LICENSE).
