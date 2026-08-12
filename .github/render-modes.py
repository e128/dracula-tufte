#!/usr/bin/env python3
"""Render each fixture in each appearance mode, and prove the palette applied.

Light mode and high-contrast mode are media queries, so nothing in the fixture
set shows them: `samples/dark.html` follows the host and the other two palettes are
invisible until a reader's OS asks for them. That left both without coverage.

Headless Chrome cannot be told which media query to match. It reads
prefers-color-scheme from the host, so the same command paints dark on a
dark-appearance mac and light on a bare CI runner, which is no basis for a gate.
So each render rewrites EVERY mode condition in a scratch copy: the target one
becomes `@media all` and the rest become `@media not all`, which never matches.
Neutralising the others is the half that makes it host-independent, and leaving
it out is what failed CI on the first attempt, because the runner reports
prefers-color-scheme: light, so the untouched fixture painted light and the
"dark" case measured the light palette. The conditions are checked as strings in
the real fixture, so a deleted or misspelled query still fails.

What each mode asserts:

  1. the fixture contains every mode `@media` condition verbatim
  2. Chrome renders the rewritten copy without error
  3. the top-left pixel is the mode's `--surface`, within a tolerance

Check 3 is what makes this more than a screenshot. It reads the first pixel of
the first PNG scanline, which needs no image library: for the first pixel of row
0 every PNG filter predicts from a left and an above byte that are both zero, so
the filtered bytes are the raw bytes. `.github/palette-check.py` check 6 gates
the contrast inside each palette; this gates that the palette arrives at all.

Check 3 does not distinguish contrast mode from dark, because the high-contrast
block deliberately leaves `--surface` alone. It raises the accents and darkens
`--surface-alt`. Sampling a text pixel instead would mean fighting antialiasing
for no gain: check 1 already fails on a deleted or misspelled query, and check 6
already fails on a weakened value. What the contrast render adds is that the mode
paints without error, and an image a person can look at.

The PNGs are written for a human to look at. CI uploads them as artifacts.

Run: python3 .github/render-modes.py <outdir>

ponytail: no puppeteer, no playwright, no PIL. A `--screenshot` subprocess and
ten lines of zlib.
"""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

FIXTURES = ["samples/dark.html", "samples/dark-conn-map.html"]

# surface is the expected top-left pixel: `body { background: var(--surface) }`.
# dark is the default palette, so no condition of its own, and it is what shows when
# every mode condition is switched off.
CONTRAST = "@media (prefers-contrast: more)"
LIGHT = "@media (prefers-color-scheme: light)"
CONDITIONS = [CONTRAST, LIGHT]
MODES = {
    "dark": (None, "#2a2b3c"),
    "light": (LIGHT, "#fcfcf8"),
    "contrast": (CONTRAST, "#2a2b3c"),
}

# Chrome renders the oklch() surface through its own conversion, which lands a
# unit or two off the one in palette-check.py. 6 per channel is wide enough for
# that and far too narrow to accept a different palette: the closest pair of
# surfaces across the three modes differs by more than 190.
TOLERANCE = 6


def find_chrome():
    """Whatever this machine calls Chrome. $CHROME wins, then PATH, then the mac app."""
    if env := os.environ.get("CHROME"):
        return env
    for name in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser"):
        if found := shutil.which(name):
            return found
    mac = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    if pathlib.Path(mac).exists():
        return mac
    sys.exit("No Chrome found. Set $CHROME to the binary.")


def first_pixel(png):
    """(r, g, b) of the top-left pixel of an 8-bit RGB or RGBA PNG."""
    if png[:8] != b"\x89PNG\r\n\x1a\n":
        sys.exit("Chrome did not write a PNG.")
    pos, depth, color, idat = 8, None, None, b""
    while pos < len(png):
        length = int.from_bytes(png[pos:pos + 4], "big")
        kind = png[pos + 4:pos + 8]
        body = png[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            depth, color = body[8], body[9]
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
        pos += 12 + length
    if (depth, color) not in ((8, 2), (8, 6)):
        sys.exit(f"Unsupported PNG: bit depth {depth}, color type {color}.")
    raw = zlib.decompress(idat)
    # raw[0] is row 0's filter byte. For the first pixel of row 0 the left and
    # above bytes are both zero, so every filter type is the identity there.
    return tuple(raw[1:4])


def render(chrome, source, outfile):
    subprocess.run(
        [chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars",
         "--virtual-time-budget=8000", "--window-size=1400,1200",
         f"--screenshot={outfile}", source.as_uri()],
        check=True, capture_output=True,
    )
    if not outfile.exists():
        sys.exit(f"Chrome wrote no screenshot for {outfile.name}.")


def main():
    # outdir is optional and defaults to a temp dir, because the scratch HTML and the
    # PNGs are not tracked and must never land in the working tree. An earlier commit
    # here shipped ten stray files from an ad-hoc `render-modes.py modes2` run inside
    # the repo, half of them renders of deliberately broken states. CI passes
    # `mode-renders`, which .gitignore covers, so it can upload the artifact.
    if len(sys.argv) > 2:
        sys.exit("usage: render-modes.py [outdir]   (default: a temp dir)")
    outdir = pathlib.Path(sys.argv[1] if len(sys.argv) == 2 else tempfile.mkdtemp()).resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    chrome = find_chrome()
    fail = 0

    for name in FIXTURES:
        fixture = ROOT / name
        html = fixture.read_text()
        missing = [c for c in CONDITIONS if f"{c} {{" not in html]
        for c in missing:
            print(f"MISSING: {name} has no `{c} {{`, so that palette is unreachable")
            fail = 1
        if missing:
            continue
        for mode, (condition, want_hex) in MODES.items():
            # Switch every mode off, then switch the target one on. `@media not all`
            # never matches, so what the host prefers stops mattering.
            body = html
            for c in CONDITIONS:
                body = body.replace(c, "@media all" if c == condition else "@media not all", 1)
            source = outdir / f"{fixture.stem}-in-{mode}.html"
            source.write_text(body)
            png = outdir / f"{fixture.stem}-in-{mode}.png"
            render(chrome, source, png)
            got = first_pixel(png.read_bytes())
            want = tuple(int(want_hex[i:i + 2], 16) for i in (1, 3, 5))
            if max(abs(a - b) for a, b in zip(got, want)) > TOLERANCE:
                got_hex = "#%02x%02x%02x" % got
                print(f"DRIFT: {name} in {mode} mode painted {got_hex}, expected {want_hex}")
                fail = 1
            else:
                print(f"  {name} {mode}: surface {want_hex} → {png.name}")

    print("Mode render drift." if fail else f"Mode renders OK ({len(FIXTURES) * len(MODES)} images).")
    sys.exit(fail)


if __name__ == "__main__":
    main()
