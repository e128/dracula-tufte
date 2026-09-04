#!/usr/bin/env python3
"""Prove the two inlined scripts still bind to the fixture, by driving them.

`samples/dark.html` shipped an inert `input.filter-box` from v1.16.0 to v1.21.0. The
handler walked forward looking for a `TABLE` the fixture never had, and returned. Six
releases passed. Nothing noticed, because the contract check counts `<script>` blocks
and compares bytes, and neither question is "does this handler attach to anything".
`mermaid.js` had the same blind spot from the other side: CI proved its hex matched the
palette, and never proved a click on a diagram opened the zoom. It did not, on any
fixture, for several releases (NOTES.md, Zoom, records that one).

So this loads the real fixture, drives the real inlined scripts, and asserts observable
behaviour. It is the only check in the repo that runs the payload rather than reading it.

  filter.js   a live query hides the rows that do not match and keeps every element
              outside the input's own sibling span untouched, the group count follows
              the query, the no-matches line appears and goes away again, the
              `[role="status"]` count tracks, and clearing the query restores the
              authored count and the authored open state
  mermaid.js  every `pre.mermaid` renders an `<svg>` and gains its own zoom button, a
              click on the live diagram opens the `<dialog>`, and the pre carries no
              `role="region"` at a width where it cannot scroll

Run: python3 .github/script-probe.py

ponytail: no node, no jsdom, no playwright. The same headless Chrome
`.github/render-modes.py` already shells out to, with `--dump-dom` instead of
`--screenshot`, and a driver script appended to a scratch copy of the fixture. The
driver writes its results into the DOM, so reading them back is one regex.

The mermaid half needs the pinned CDN, which is the one thing here that can be
unavailable rather than broken. Reachability is probed first and reported as a SKIP,
never folded into a pass: a gate that goes quiet when the network does is worse than no
gate, so the skip is loud and the exit code stays honest about what ran.
"""
import importlib.util
import pathlib
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

# render-modes.py already knows how to find Chrome on this machine, and a second copy of
# that search is a second thing to keep in step. The hyphen in the filename is why this
# is a loader rather than an import.
_spec = importlib.util.spec_from_file_location(
    "render_modes", pathlib.Path(__file__).resolve().parent / "render-modes.py"
)
_rm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_rm)
find_chrome = _rm.find_chrome

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURE = ROOT / "samples/dark.html"

# The width the driver runs at. Above the (max-width: 600px) block, so `pre.mermaid` is
# `overflow: visible` and mermaid.js must NOT have made it a region: that is the
# assertion, not an incidental setting.
WINDOW = "1400,1200"

DRIVER = """
  <script type="module">
    const out = [];
    const t = (name, cond) => out.push(name + '=' + (cond ? 'PASS' : 'FAIL'));
    const publish = () => {
      const el = document.createElement('pre');
      el.id = 'script-probe';
      el.textContent = out.join('\\n');
      document.body.append(el);
    };

    // filter.js: synchronous, no network, and the half that shipped the defect.
    const input = document.querySelector('input.filter-box');
    const status = input && input.parentElement.querySelector('[role="status"]');
    const empty = input && input.parentElement.querySelector('.filter-empty');
    const group = document.querySelector('details.nav-group');
    const count = group && group.querySelector('summary .count');
    const authored = count && count.textContent;
    const wasOpen = group && group.open;
    const type = q => {
      input.value = q;
      input.dispatchEvent(new Event('input', { bubbles: true }));
    };
    const hidden = () => document.querySelectorAll('.filter-hidden').length;

    t('filter-wired', Boolean(input && status && empty && group && count));
    if (input) {
      type('grouped');
      t('filter-hides-nonmatching', hidden() === 3);
      t('filter-keeps-group-open', group.open === true);
      t('filter-status-tracks', status.textContent === '1 entry');
      t('filter-empty-stays-hidden', empty.hidden === true);

      type('no such entry anywhere');
      // Four rows plus the group itself, and nothing else on the page: an element
      // outside the input's sibling span must never be touched.
      t('filter-scope-holds', hidden() === 5);
      t('filter-empty-shows', empty.hidden === false);
      t('filter-count-follows', count.textContent === '0');
      t('filter-status-zero', status.textContent === '0 entries');

      type('');
      t('filter-restores-rows', hidden() === 0);
      t('filter-restores-count', count.textContent === authored);
      t('filter-restores-open', group.open === wasOpen);
      t('filter-restores-status', status.textContent === '4 entries');
    }

    if (!window.__probeMermaid) {
      out.push('mermaid=SKIP');
      publish();
    } else {
      const deadline = Date.now() + 20000;
      const poll = () => {
        const pres = [...document.querySelectorAll('pre.mermaid')];
        const ready = pres.length > 0 && pres.every(
          p => p.querySelector('svg') && p.querySelector('.mermaid-zoom')
        );
        if (!ready && Date.now() < deadline) {
          setTimeout(poll, 250);
          return;
        }
        t('mermaid-rendered', ready);
        t('mermaid-no-region-when-wide', pres.every(p => !p.hasAttribute('role')));
        t('mermaid-no-tabstop-when-wide', pres.every(p => !p.hasAttribute('tabindex')));
        const svg = pres[0] && pres[0].querySelector('svg');
        const overlay = document.getElementById('mermaid-zoom');
        if (svg && overlay) {
          svg.dispatchEvent(new MouseEvent('click', { bubbles: true }));
          // A listener bound to a discarded clone leaves the live element with none,
          // so dispatching on the live svg is exactly the case that used to fail.
          t('mermaid-click-zooms', overlay.hasAttribute('open'));
          t('mermaid-overlay-named', Boolean(overlay.getAttribute('aria-label')));
          overlay.close();
        } else {
          t('mermaid-click-zooms', false);
        }
        publish();
      };
      poll();
    }
  </script>
"""

CDN = re.search(r"from '(https://[^']+)'", (ROOT / "mermaid.js").read_text()).group(1)


def cdn_reachable():
    try:
        with urllib.request.urlopen(CDN, timeout=10) as r:
            return r.status == 200
    except (urllib.error.URLError, OSError):
        return False


def main():
    mermaid = cdn_reachable()
    if not mermaid:
        print(f"SKIP: {CDN} is unreachable, so the mermaid.js half cannot run.")

    html = FIXTURE.read_text()
    if "</body>" not in html:
        sys.exit(f"{FIXTURE.name} has no </body> to append the driver to.")
    flag = f"  <script>window.__probeMermaid = {'true' if mermaid else 'false'};</script>\n"
    body = html.replace("</body>", flag + DRIVER + "\n</body>", 1)

    with tempfile.TemporaryDirectory() as tmp:
        source = pathlib.Path(tmp) / "probe.html"
        source.write_text(body)
        dump = subprocess.run(
            [find_chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars",
             "--virtual-time-budget=25000", f"--window-size={WINDOW}",
             "--dump-dom", source.as_uri()],
            check=True, capture_output=True, text=True,
        ).stdout

    found = re.search(r'<pre id="script-probe">(.*?)</pre>', dump, re.S)
    if not found:
        sys.exit(
            "The probe never published a result. Either an inlined script threw before "
            "the driver ran, or the driver itself did not reach `publish()`."
        )
    results = [line.strip() for line in found.group(1).splitlines() if line.strip()]
    if len(results) < 13:
        sys.exit(f"Only {len(results)} assertions reported, refusing to pass vacuously.")

    fail = 0
    for line in results:
        name, _, verdict = line.partition("=")
        if verdict == "FAIL":
            print(f"BINDING: {name} failed. The inlined script did not behave as the "
                  f"contract says it does.")
            fail = 1
        else:
            print(f"  {name}: {verdict}")

    print("Script binding broken." if fail else f"Script binding OK ({len(results)} assertions).")
    sys.exit(fail)


if __name__ == "__main__":
    main()
