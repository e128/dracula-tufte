# design-audit tools

Headless render probes for the `design-audit` skill. Standard library only: a small DevTools
Protocol client (`cdp.py`) and a CLI (`probe.py`). Written on 2026-11-20 while auditing `edade37`,
because the skill's render step assumed Playwright and this machine has none.

The tools read `samples/*.html` and write nothing into the repo. Pass `--out` to keep the JSON.

## Requirements

- Python 3.10 or newer.
- A Chromium browser. `$CHROME` wins, then the names on `PATH`, then the Mac application bundles
  (Google Chrome, Microsoft Edge, Brave). On this machine Google Chrome is absent, so Edge is the
  one to expect:

```
CHROME="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
  python3 probe.py sweep --fixtures samples/dark.html
```

- Network access to jsDelivr for the pinned payload (Mermaid, the two webfonts, the highlighter).
  `perf` blocks those URLs on purpose for its isolation runs, and reports the blocked result
  beside the unblocked one.

## Commands

All commands take `--fixtures` paths relative to the repo root, and `--port` if 9222 is busy.

```
python3 probe.py sweep      --fixtures samples/dark.html samples/dark-conn-map.html
python3 probe.py components --fixtures samples/dark-charts.html
python3 probe.py a11y       --fixtures samples/dark.html
python3 probe.py perf       --fixtures samples/light-charts.html
```

| Command | Measures |
| --- | --- |
| `sweep` | `scrollWidth` against `clientWidth` at every width and height, overflow outside documented scroll hatches, and every interactive target rectangle. Defaults: widths 320, 375, 768, 1024, 1280; heights 568, 768, 900. |
| `components` | Computed type and color, `dl.meter` and `td.dot` geometry, the same page under `dir="rtl"`, at 320px, and under `emulate_media(print)`. |
| `a11y` | Tab order and focus rings, target sizes with the 2.5.8 spacing exception, the filter box and its `role="status"`, the zoom dialog opened with a real click and closed with a real Escape key, forced-colors computed values, reduced motion, text-spacing overrides, and 200% text zoom. |
| `perf` | Author-sheet rule coverage, navigation timing, LCP, and CLS on a cold load with fonts blocked and with Mermaid blocked. |

## Traps this tool already handles

- **A synchronous layout read returns a stale `scrollWidth`.** Both text-zoom measurements wait
  200ms on a timer before reading. `requestAnimationFrame` is not dependable in a headless target
  that is not the active tab, so do not switch these back.
- **CLS observers accumulate across navigations.** `Page.addScriptToEvaluateOnNewDocument`
  persists, so `measure_cls` removes the previous registration first. Without that, three
  measurements in one run count every shift three times.
- **Real Escape, not a synthetic event.** Chromium closes a native `<dialog>` only for trusted key
  input, so the probe uses `Input.dispatchKeyEvent`. A script-dispatched `KeyboardEvent` proves
  nothing about 2.1.2 or dialog behavior.
- **A blocked CDN URL is checked by result.** The isolation runs report their CLS beside the
  unblocked value; a block that silently failed would otherwise read as a clean result.

## Output

Everything is JSON. `sweep` prints one line per fixture and viewport and writes the full records.
The other commands print the JSON. Quote the values in the report; do not restate them from memory.

## Mutation-check a script assertion

A payload change to `mermaid.js`, `filter.js` or `highlight.js` needs an assertion in
`.github/script-probe.py`, and the assertion is not trusted until it fails without the change:

```
cp highlight.js /tmp/highlight.js.bak
# remove the one line the assertion covers, then
nu scripts/build-sample.nu
CHROME=".../Microsoft Edge" python3 .github/script-probe.py   # expect BINDING: <name> failed
cp /tmp/highlight.js.bak highlight.js
nu scripts/build-sample.nu
CHROME=".../Microsoft Edge" python3 .github/script-probe.py   # expect Script binding OK
```

The probe reads the generated fixture, so regenerating between the mutation and the restore is
required. Do not edit `samples/*.html` to make the mutation.
