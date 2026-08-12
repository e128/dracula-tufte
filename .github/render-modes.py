#!/usr/bin/env python3
"""Render each fixture in each appearance mode, and prove the palette applied.

Light mode and high-contrast mode are media queries, so nothing in the fixture
set shows them: `sample.html` renders dark and the other two palettes are
invisible until a reader's OS asks for them. That left both without coverage.

Headless Chrome cannot be told which media query to match. It reads
prefers-color-scheme from the host, so the same command paints dark on a
dark-appearance mac and light on a bare CI runner, which is no basis for a gate.
This script rewrites the mode's `@media` condition to `@media all` in a scratch
copy instead, which is deterministic everywhere. The condition itself is checked
as a string in the real fixture, so a deleted or misspelled query still fails.

What each mode asserts:

  1. the fixture contains the mode's `@media` condition verbatim
  2. Chrome renders the rewritten copy without error
  3. the top-left pixel is the mode's `--surface`, within a tolerance

Check 3 is what makes this more than a screenshot. It reads the first pixel of
the first PNG scanline, which needs no image library: for the first pixel of row
0 every PNG filter predicts from a left and an above byte that are both zero, so
the filtered bytes are the raw bytes. `.github/palette-check.py` check 6 gates
the contrast inside each palette; this gates that the palette arrives at all.

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
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

FIXTURES = ["sample.html", "sample-conn-map.html"]

# surface is the expected top-left pixel: `body { background: var(--surface) }`.
# dark rewrites nothing, so its condition is None.
MODES = {
    "dark": (None, "#2a2b3c"),
    "light": ("@media (prefers-color-scheme: light)", "#fcfcf8"),
    "contrast": ("@media (prefers-contrast: more)", "#2a2b3c"),
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
    if len(sys.argv) != 2:
        sys.exit("usage: render-modes.py <outdir>")
    outdir = pathlib.Path(sys.argv[1]).resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    chrome = find_chrome()
    fail = 0

    for name in FIXTURES:
        fixture = ROOT / name
        html = fixture.read_text()
        for mode, (condition, want_hex) in MODES.items():
            if condition is None:
                source = fixture
            else:
                if f"{condition} {{" not in html:
                    print(f"MISSING: {name} has no `{condition} {{` — the {mode} palette is unreachable")
                    fail = 1
                    continue
                source = outdir / f"{fixture.stem}-{mode}.html"
                source.write_text(html.replace(condition, "@media all", 1))
            png = outdir / f"{fixture.stem}-{mode}.png"
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
