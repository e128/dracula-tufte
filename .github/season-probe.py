#!/usr/bin/env python3
"""Prove the seasonal head snippet picks the right palette for the right dates.

Consumers opt in by pasting a classic inline script before the stylesheet. It sets
`data-season` on `<html>` from the visitor's local calendar, with one row per season:
St Patrick from March 1 through March 17, Chartreuse from May 1 through May 16, Independence Day
from June 28 through July 4, Thanksgiving from November 1 through the fourth Thursday of November,
and Christmas from the fourth Friday of November through December 28, all inclusive, at page load.
Poland overrides 3 May, 15 August, 11 November and 6 December, and those override rows come first
so they carve their days out of Chartreuse, Thanksgiving or Christmas. Rows are checked in order and
the first match wins, so in a year where November 1 is a Friday the fourth Friday falls before the
fourth Thursday and Thanksgiving keeps those days.
Nothing else in the repo runs that script. `maintain.nu check` counts `<script>` blocks, `palette-check.py` measures
colors, and `script-probe.py` drives the three payload scripts. None of them asks
whether the snippet picks the right days, so an off-by-one on a boundary, a UTC getter
or a malformed edit would ship green.

This extracts the snippet from the generated fixtures, so it tests the bytes a page
carries, and then drives it in real headless Chrome:

  presence    every dark fixture carries exactly one classic `<script>` that sets the
              season, before the first `<style>` and the first module script, with no
              comment, and the four copies and the one in CONTRACT.md section 1 are the
              same text
  calendar    a mocked `Date` puts each boundary in front of the real snippet: Nov 10 off,
              Nov 11 on, Dec 26 on, Dec 27 off, the January days whose day number sits
              inside the window, and a leap year. The page never reads the real clock.
  timezone    the same cases run under UTC, UTC+14 and UTC-11. A snippet that reads the
              UTC getters instead of the local ones passes in one zone and fails in the
              others. The run asserts that Chrome honored the zone, and fails otherwise.
  ordering    the real fixture, with its module scripts replaced by one recorder, reads
              `data-season` and `--mermaid-scheme` when a module first evaluates, which is
              when `mermaid.js` reads the token. In a window both name that season, out of
              one neither does.
  previews    every `<season>-*.html` paints its season palette whatever the system
              scheme and contrast, and `light.html` stays
              plain light under the same settings. The settings reach Chrome through
              `--blink-settings`, and the run reads them back through `matchMedia`, so a
              Chrome that ignores them is reported as a SKIP instead of a pass.

A missing, moved or malformed snippet fails by name. The same generated fixtures
must exist, so run `nu scripts/build-sample.nu` first.

Run: python3 .github/season-probe.py

ponytail: no node, no playwright. The same headless Chrome `render-modes.py` finds,
with `--dump-dom`, a driver page that publishes its results into the DOM, and `TZ` in
the subprocess environment for the zones.
"""
import html as htmllib
import importlib.util
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile

_spec = importlib.util.spec_from_file_location(
    "render_modes", pathlib.Path(__file__).resolve().parent / "render-modes.py"
)
_rm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_rm)
find_chrome = _rm.find_chrome

ROOT = pathlib.Path(__file__).resolve().parent.parent
DARK = ["samples/dark.html", "samples/dark-conn-map.html",
        "samples/dark-timeline.html", "samples/dark-charts.html"]
MAIN = "samples/dark.html"
SEASONS = ["chartreuse", "christmas", "independence-day", "poland", "st-patrick", "thanksgiving"]
PREVIEWS = {(season, mode): f"samples/{season}-{mode}.html"
            for season in SEASONS for mode in ("dark", "light")}
PLAIN_LIGHT = "samples/light.html"
CONTRACT = ROOT / "CONTRACT.md"

SEASON_ATTR = "document.documentElement.setAttribute('data-season'"
ZONES = {"UTC": 0, "Pacific/Kiritimati": -840, "Pacific/Pago_Pago": 660}

# (label, year, month, day, hour, minute, second, season expected or None). Months are
# the calendar's own, 1 to 12. The expectations are literals on purpose: deriving them
# from the rule would restate the snippet's own logic and could not disagree with it.
CASES = [
    ("Feb 28 end of day", 2026, 2, 28, 23, 59, 59, None),
    ("Mar 1 start of day", 2026, 3, 1, 0, 0, 0, "st-patrick"),
    ("Mar 1 noon", 2026, 3, 1, 12, 0, 0, "st-patrick"),
    ("Mar 8", 2026, 3, 8, 12, 0, 0, "st-patrick"),
    ("Mar 17 end of day", 2026, 3, 17, 23, 59, 59, "st-patrick"),
    ("Mar 18 start of day", 2026, 3, 18, 0, 0, 0, None),
    ("2024 Mar 1", 2024, 3, 1, 12, 0, 0, "st-patrick"),
    ("2027 Mar 17 end of day", 2027, 3, 17, 23, 59, 59, "st-patrick"),
    ("Apr 30 end of day", 2026, 4, 30, 23, 59, 59, None),
    ("May 2, before the override", 2026, 5, 2, 23, 59, 59, "chartreuse"),
    ("May 3, Poland Constitution Day", 2026, 5, 3, 0, 0, 0, "poland"),
    ("May 3 noon, carving Chartreuse", 2026, 5, 3, 12, 0, 0, "poland"),
    ("May 4, base range resumes", 2026, 5, 4, 0, 0, 0, "chartreuse"),
    ("May 1 start of day", 2026, 5, 1, 0, 0, 0, "chartreuse"),
    ("May 1 noon", 2026, 5, 1, 12, 0, 0, "chartreuse"),
    ("May 8", 2026, 5, 8, 12, 0, 0, "chartreuse"),
    ("May 16 end of day", 2026, 5, 16, 23, 59, 59, "chartreuse"),
    ("May 17 start of day", 2026, 5, 17, 0, 0, 0, None),
    ("2024 May 1", 2024, 5, 1, 12, 0, 0, "chartreuse"),
    ("2027 May 16 end of day", 2027, 5, 16, 23, 59, 59, "chartreuse"),
    ("Jun 27 end of day", 2026, 6, 27, 23, 59, 59, None),
    ("Aug 14, before the override", 2026, 8, 14, 23, 59, 59, None),
    ("Aug 15, Poland Armed Forces Day", 2026, 8, 15, 12, 0, 0, "poland"),
    ("Aug 16, after the override", 2026, 8, 16, 0, 0, 0, None),
    ("Jun 28 start of day", 2026, 6, 28, 0, 0, 0, "independence-day"),
    ("Jun 28 noon", 2026, 6, 28, 12, 0, 0, "independence-day"),
    ("Jul 1", 2026, 7, 1, 12, 0, 0, "independence-day"),
    ("Jul 4 end of day", 2026, 7, 4, 23, 59, 59, "independence-day"),
    ("Jul 5 start of day", 2026, 7, 5, 0, 0, 0, None),
    ("2024 Jun 28", 2024, 6, 28, 12, 0, 0, "independence-day"),
    ("2027 Jul 4 end of day", 2027, 7, 4, 23, 59, 59, "independence-day"),
    ("Oct 1", 2026, 10, 1, 0, 0, 0, None),
    ("Oct 11, a day number inside both windows", 2026, 10, 11, 12, 0, 0, None),
    ("Oct 31 end of day", 2026, 10, 31, 23, 59, 59, None),
    ("Nov 1 start of day", 2026, 11, 1, 0, 0, 0, "thanksgiving"),
    ("Nov 10, before the override", 2026, 11, 10, 23, 59, 59, "thanksgiving"),
    ("Nov 11, Poland Independence Day", 2026, 11, 11, 0, 0, 0, "poland"),
    ("Nov 11 noon, carving Thanksgiving", 2026, 11, 11, 12, 0, 0, "poland"),
    ("Nov 12, base range resumes", 2026, 11, 12, 0, 0, 0, "thanksgiving"),
    ("Nov 1 noon", 2026, 11, 1, 12, 0, 0, "thanksgiving"),
    ("Nov 15", 2026, 11, 15, 12, 0, 0, "thanksgiving"),
    ("Nov 26 end of day, fourth Thursday", 2026, 11, 26, 23, 59, 59, "thanksgiving"),
    ("Nov 27 start of day, fourth Friday", 2026, 11, 27, 0, 0, 0, "christmas"),
    ("Nov 28", 2026, 11, 28, 12, 0, 0, "christmas"),
    ("Nov 29 noon", 2026, 11, 29, 12, 0, 0, "christmas"),
    ("Nov 30", 2026, 11, 30, 12, 0, 0, "christmas"),
    ("Dec 1", 2026, 12, 1, 0, 0, 0, "christmas"),
    ("Dec 5, before the override", 2026, 12, 5, 23, 59, 59, "christmas"),
    ("Dec 6, Poland St Nicholas Day", 2026, 12, 6, 0, 0, 0, "poland"),
    ("Dec 6 noon, carving Christmas", 2026, 12, 6, 12, 0, 0, "poland"),
    ("Dec 7, base range resumes", 2026, 12, 7, 0, 0, 0, "christmas"),
    ("Dec 25", 2026, 12, 25, 12, 0, 0, "christmas"),
    ("Dec 28 end of day", 2026, 12, 28, 23, 59, 59, "christmas"),
    ("Dec 29 start of day", 2026, 12, 29, 0, 0, 0, None),
    ("Dec 31", 2026, 12, 31, 12, 0, 0, None),
    ("Jan 1", 2027, 1, 1, 0, 0, 0, None),
    ("Jan 11, a day number inside the old windows", 2027, 1, 11, 12, 0, 0, None),
    ("Jan 26, a day number inside the old windows", 2027, 1, 26, 12, 0, 0, None),
    ("Jun 15", 2026, 6, 15, 12, 0, 0, None),
    ("Leap year Feb 29", 2024, 2, 29, 12, 0, 0, None),
    ("2024 Nov 22, fourth Friday before the fourth Thursday", 2024, 11, 22, 12, 0, 0, "thanksgiving"),
    ("2024 Nov 28 end of day, fourth Thursday", 2024, 11, 28, 23, 59, 59, "thanksgiving"),
    ("2024 Nov 29 start of day", 2024, 11, 29, 0, 0, 0, "christmas"),
    ("2024 Dec 28", 2024, 12, 28, 12, 0, 0, "christmas"),
    ("2024 Dec 29", 2024, 12, 29, 12, 0, 0, None),
    ("Next year Nov 1", 2027, 11, 1, 0, 0, 0, "thanksgiving"),
    ("Next year Nov 25 end of day, fourth Thursday", 2027, 11, 25, 23, 59, 59, "thanksgiving"),
    ("Next year Nov 26 start of day, fourth Friday", 2027, 11, 26, 0, 0, 0, "christmas"),
    ("Next year Nov 29", 2027, 11, 29, 0, 0, 0, "christmas"),
    ("2028 Nov 23 end of day, fourth Thursday of five", 2028, 11, 23, 23, 59, 59, "thanksgiving"),
    ("2028 Nov 24 start of day, fourth Friday", 2028, 11, 24, 0, 0, 0, "christmas"),
    ("2028 Nov 30, fifth Thursday", 2028, 11, 30, 12, 0, 0, "christmas"),
]

# `Date` is replaced inside the page the snippet runs in, so the snippet sees the case's
# local time through `new Date()` and through `Date.now()` alike. The clock is built from
# local components, which makes the case host-independent and the zone the only variable.
MOCK = """(function () {
  var Real = Date, at = new Real(%d, %d, %d, %d, %d, %d);
  function Fake() {
    if (arguments.length === 0) return new Real(at.getTime());
    return new (Function.prototype.bind.apply(Real, [null].concat([].slice.call(arguments))))();
  }
  Fake.prototype = Real.prototype;
  Fake.now = function () { return at.getTime(); };
  Fake.UTC = Real.UTC;
  Fake.parse = Real.parse;
  window.Date = Fake;
  window.__errors = [];
  window.addEventListener('error', function (e) { window.__errors.push(String(e.message)); });
})();"""

REPORT = """parent.postMessage({
  id: %d,
  season: document.documentElement.getAttribute('data-season'),
  zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  offset: new Date(2026, 6, 1).getTimezoneOffset(),
  clock: [new Date().getFullYear(), new Date().getMonth() + 1, new Date().getDate()],
  errors: window.__errors
}, '*');"""

MATRIX_DRIVER = """
<!doctype html><meta charset="utf-8"><body>
<script type="module">
  const docs = %s;
  const got = [];
  const done = () => {
    const el = document.createElement('pre');
    el.id = 'season-probe';
    el.textContent = JSON.stringify(got);
    document.body.append(el);
  };
  addEventListener('message', (e) => {
    got.push(e.data);
    if (got.length === docs.length) done();
  });
  docs.forEach((srcdoc) => {
    const frame = document.createElement('iframe');
    frame.srcdoc = srcdoc;
    document.body.append(frame);
  });
  setTimeout(() => { if (got.length < docs.length) done(); }, 15000);
</script>
"""

RECORDER = """
  <script type="module">
    const root = document.documentElement;
    const style = getComputedStyle(root);
    const el = document.createElement('pre');
    el.id = 'season-probe';
    el.textContent = JSON.stringify({
      season: root.getAttribute('data-season'),
      scheme: style.getPropertyValue('--mermaid-scheme').trim(),
      surface: style.getPropertyValue('--surface').trim(),
      background: getComputedStyle(document.body).backgroundColor,
      light: matchMedia('(prefers-color-scheme: light)').matches,
      more: matchMedia('(prefers-contrast: more)').matches
    });
    document.body.append(el);
  </script>
"""

# Blink's own numbering, read back through matchMedia on every run.
HOSTS = {
    "dark system, more contrast": "preferredColorScheme=0,preferredContrast=0",
    "light system, more contrast": "preferredColorScheme=1,preferredContrast=0",
}

results = []
skips = []


def check(name, cond, detail=""):
    results.append((name, bool(cond), detail))


def chrome_dump(page, zone=None, blink=None):
    """Render `page` in headless Chrome and return the JSON the driver published."""
    env = dict(os.environ)
    if zone:
        env["TZ"] = zone
    args = [find_chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars",
            "--virtual-time-budget=20000", "--window-size=1400,1200"]
    if blink:
        args.append(f"--blink-settings={blink}")
    with tempfile.TemporaryDirectory() as tmp:
        source = pathlib.Path(tmp) / "season.html"
        source.write_text(page)
        dump = subprocess.run(args + ["--dump-dom", source.as_uri()],
                              check=True, capture_output=True, text=True, env=env).stdout
    found = re.search(r'<pre id="season-probe">(.*?)</pre>', dump, re.S)
    if not found:
        sys.exit("SEASON: the driver never published a result, so a script threw before it "
                 "reached its append.")
    return json.loads(htmllib.unescape(found.group(1)))


def js_string(text):
    """A JSON string that survives inside an inline script: `</script` cannot end it."""
    return json.dumps(text).replace("</", "<\\/")


def read(rel):
    path = ROOT / rel
    if not path.exists():
        sys.exit(f"SEASON: {rel} does not exist. Run `nu scripts/build-sample.nu` first.")
    return path.read_text()


def snippet_of(html, name):
    """The one classic `<script>` that sets the season, as its whole block, or a failure."""
    blocks = [m for m in re.finditer(r"<script>(.*?)</script>", html, re.S) if "data-season" in m.group(1)]
    if not blocks:
        check(f"present-{name}", False, "no classic `<script>` that sets data-season: the snippet is absent or malformed")
        return None
    check(f"single-{name}", len(blocks) == 1, f"{len(blocks)} season scripts")
    block = blocks[0]
    first_style = html.find("<style")
    first_module = html.find('<script type="module"')
    check(f"before-style-and-modules-{name}",
          block.start() < first_style and block.start() < first_module,
          "the snippet must precede the stylesheet and every module script")
    check(f"sets-season-{name}", SEASON_ATTR in block.group(1), f"no `{SEASON_ATTR}`")
    check(f"comment-free-{name}", not re.search(r"//|/\*|<!--", block.group(1)), "a comment inside the snippet")
    return block.group(0)


def squash(block):
    """The block's lines with their indentation removed, so a fence and a `<head>` compare."""
    return "\n".join(line.strip() for line in block.strip().splitlines())


def contract_snippet():
    text = CONTRACT.read_text()
    for fence in re.finditer(r"```html\n(.*?)```", text, re.S):
        if "data-season" in fence.group(1):
            return fence.group(1)
    return None


def main():
    # presence
    blocks = {}
    for rel in DARK:
        block = snippet_of(read(rel), pathlib.Path(rel).stem)
        if block:
            blocks[rel] = block
    if MAIN not in blocks:
        report(fail_early=True)
    canonical = squash(blocks[MAIN])
    for rel, block in blocks.items():
        check(f"same-text-{pathlib.Path(rel).stem}", squash(block) == canonical,
              "this fixture's snippet differs from samples/dark.html")
    copy = contract_snippet()
    check("contract-copy-present", copy is not None, "CONTRACT.md section 1 has no ```html block with the snippet")
    if copy is not None:
        check("contract-copy-matches", squash(copy) == canonical,
              "the CONTRACT.md copy differs from the snippet in samples/dark.html")

    # calendar, in three zones
    docs = []
    for i, (_, y, m, d, h, mi, s, _) in enumerate(CASES):
        docs.append("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
                    f"<script>{MOCK % (y, m - 1, d, h, mi, s)}</script>\n{blocks[MAIN]}\n</head>"
                    f"<body><script>{REPORT % i}</script></body></html>")
    driver = MATRIX_DRIVER % json.dumps(docs).replace("</", "<\\/")
    for zone, offset in ZONES.items():
        got = {r["id"]: r for r in chrome_dump(driver, zone=zone)}
        if len(got) != len(CASES):
            check(f"calendar-complete-{zone}", False, f"{len(got)} of {len(CASES)} pages reported")
            continue
        if any(r["zone"] != zone or r["offset"] != offset for r in got.values()):
            sys.exit(f"SEASON: Chrome ignored TZ={zone}, so the local-calendar cases cannot run. "
                     f"Got {sorted({r['zone'] for r in got.values()})}.")
        for i, (label, y, m, d, *_, want) in enumerate(CASES):
            r = got[i]
            check(f"clock-mocked-{zone}-{i}", r["clock"] == [y, m, d], f"{label}: the mock reported {r['clock']}")
            check(f"calendar-{zone}-{label}", not r["errors"] and r["season"] == want,
                  f"{label} in {zone}: expected {want or 'no season'}, got "
                  f"{r['season']!r} {r['errors'] or ''}")

    # ordering, in the real fixture
    page = read(MAIN)
    for tag, when, want in (("st-patrick", (2026, 3, 8), "st-patrick"),
                            ("chartreuse", (2026, 5, 8), "chartreuse"),
                            ("independence-day", (2026, 7, 1), "independence-day"),
                            ("thanksgiving", (2026, 11, 15), "thanksgiving"),
                            ("christmas", (2026, 12, 1), "christmas"),
                            ("out-of-window", (2027, 1, 15), None)):
        mock = f"  <script>{MOCK % (when[0], when[1] - 1, when[2], 12, 0, 0)}</script>\n"
        timed = page.replace("<head>", "<head>\n" + mock, 1)
        timed = re.sub(r'<script type="module">.*?</script>', "", timed, flags=re.S)
        r = chrome_dump(timed.replace("</head>", RECORDER + "</head>", 1))
        check(f"ordering-{tag}-season", r["season"] == want, f"data-season was {r['season']!r}")
        token_ok = (want in r["scheme"]) if want else not any(s in r["scheme"] for s in SEASONS)
        check(f"ordering-{tag}-token", token_ok,
              f"--mermaid-scheme read {r['scheme']!r} when a module first evaluated")

    # previews
    seen = {}
    for kind, rel in (*PREVIEWS.items(), ("plain", None)):
        season, mode = kind if isinstance(kind, tuple) else (None, None)
        rel = rel if rel is not None else PLAIN_LIGHT
        label = "plain" if season is None else f"{season}-{mode}"
        html = read(rel)
        has_snippet = SEASON_ATTR in html
        check(f"preview-{label}-has-no-snippet", not has_snippet, f"{rel} still carries the date-driven snippet")
        check(f"preview-{label}-season-attr",
              (f'<html lang="en" data-season="{season}">' in html) == (season is not None),
              f"{rel}: <html> carries data-season only on the season previews")
        bare = re.sub(r"<script\b[^>]*>.*?</script>", "", html, flags=re.S)
        for host, blink in HOSTS.items():
            r = chrome_dump(bare.replace("</head>", RECORDER + "</head>", 1), blink=blink)
            if r["more"] is not True or r["light"] is not host.startswith("light"):
                skips.append(f"SKIP: Chrome did not apply `{blink}` ({host}); the {rel} check did not run for it.")
                continue
            seen.setdefault(kind, {})[host] = r
        runs = list(seen.get(kind, {}).values())
        if len(runs) < 2:
            continue
        check(f"preview-{label}-ignores-system",
              all((r["scheme"], r["surface"], r["background"]) == (runs[0]["scheme"], runs[0]["surface"],
                                                                   runs[0]["background"]) for r in runs),
              f"{rel} painted differently under the two system settings: {[r['scheme'] for r in runs]}")
        scheme = runs[0]["scheme"]
        if season is None:
            check("preview-plain-is-not-seasonal", scheme == "light" and runs[0]["season"] is None,
                  f"{rel}: scheme {scheme!r}, season {runs[0]['season']!r}")
        else:
            wants_light = mode == "light"
            check(f"preview-{label}-is-season",
                  runs[0]["season"] == season and season in scheme and ("light" in scheme) == wants_light,
                  f"{rel}: scheme {scheme!r}, season {runs[0]['season']!r}")
    backgrounds = {k: next(iter(v.values()))["background"] for k, v in seen.items() if len(v) == 2}
    if len(backgrounds) == len(PREVIEWS) + 1:
        check("preview-grounds-differ", len(set(backgrounds.values())) == len(backgrounds),
              f"the previews do not paint distinct grounds: {backgrounds}")

    report()


def report(fail_early=False):
    fail = 0
    for line in skips:
        print(line)
    for name, ok, detail in results:
        if ok:
            print(f"  {name}: PASS")
        else:
            print(f"SEASON: {name} failed. {detail}")
            fail = 1
    if fail_early:
        print("SEASON: samples/dark.html has no usable snippet, so nothing could be driven.")
        sys.exit(1)
    if len(results) < 100:
        print(f"SEASON: only {len(results)} assertions reported, refusing to pass vacuously.")
        sys.exit(1)
    print("Season probe broken." if fail else f"Season probe OK ({len(results)} assertions).")
    sys.exit(fail)


if __name__ == "__main__":
    main()
