#!/usr/bin/env python3
"""Fail if any hex projection of the palette drifts from the oklch source.

tufte-dracula.css :root is the single source of truth. Two projections carry the
same colors as hex, because Mermaid's color engine (khroma) throws "Unsupported
color format" on oklch() and renders no diagram at all:

  mermaid-palette.json  — the declared hex palette, keyed by themeVariables name
  mermaid.js            — the same values inline (consumers inline it, no build)

contract-check.yml already pins mermaid.js to mermaid-palette.json. This closes
the remaining edge: mermaid-palette.json back to the CSS it claims to project.
It is what makes the "from" fields load-bearing rather than decorative.

Paths resolve from this script's location, so cwd does not matter (maintain.nu
calls it by absolute path). Exit 1 on any drift.

ponytail: stdlib-only Oklab -> sRGB, no colour-science dependency for 17 values.
"""
import json
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def oklch_to_hex(L, C, h):
    """oklch() -> #rrggbb, gamut-clipped, matching how a browser renders it."""
    a = C * math.cos(math.radians(h))
    b = C * math.sin(math.radians(h))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    linear = (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )

    def encode(x):
        x = min(1.0, max(0.0, x))
        return 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055

    return "#%02x%02x%02x" % tuple(round(encode(v) * 255) for v in linear)


stylesheet = (ROOT / "tufte-dracula.css").read_text()

# Only the :root block defines the palette. Scanning the whole stylesheet would let a
# --x: oklch(...) declared inside a component rule join the palette set and quietly
# widen the membership checks below, so a stale hex could start passing. Non-greedy up
# to a closing brace on its own line, and the first match is the real :root — the
# @media one is a single inline line that never reaches this shape.
root = re.search(r":root \{(.*?)\n\s*\}", stylesheet, re.S)
if not root:
    sys.exit("Could not find the :root block in tufte-dracula.css.")
css = root.group(1)

triples = {
    name: (float(L), float(C), float(h))
    for name, L, C, h in re.findall(
        r"--([\w-]+):\s*oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)", css
    )
}
palette = {name: oklch_to_hex(*lch) for name, lch in triples.items()}
if len(palette) < 17:
    sys.exit(f"Only parsed {len(palette)} oklch tokens from :root — expected 17.")

# --dump is the generator side of the same parse: create-themes.nu needs the palette
# as data, and re-deriving oklch -> sRGB in Nushell (no trig builtins) would mean a
# second implementation of the matrix above, free to drift from the one CI checks.
# `bright` is the L + 0.07 rule the Ghostty ANSI slots already document; it lives
# here because it needs oklch, not because it is palette policy. The ceiling is
# 0.99, not 1.0: --on-surface sits at L 0.977, so an unclamped bump lands on
# #fffff9, a white with nothing above it. 0.99 keeps ANSI 15 at #fcfcf6.
if "--dump" in sys.argv:
    json.dump(
        {
            name: {"hex": hexval, "bright": oklch_to_hex(min(0.99, triples[name][0] + 0.07), *triples[name][1:])}
            for name, hexval in palette.items()
        },
        sys.stdout,
    )
    sys.exit(0)

pal = json.loads((ROOT / "mermaid-palette.json").read_text())
fail = 0

# 1. Every init hex is exactly the conversion of the variable it names.
for key, entry in pal["init"].items():
    if key == "_comment":
        continue
    want = palette.get(entry["from"].lstrip("-"))
    if want is None:
        print(f"DRIFT: init.{key} names {entry['from']}, which is not in :root")
        fail = 1
    elif entry["hex"] != want:
        print(f"DRIFT: init.{key} is {entry['hex']}, {entry['from']} computes to {want}")
        fail = 1

# 2. Each classdef fill is exactly the variable its `from` field names — that is
#    what makes `from` load-bearing here too. stroke/color are shared across every
#    role rather than named, so those get a membership check.
for role, entry in pal["classdef"].items():
    if role == "_comment":
        continue
    want = palette.get(entry["from"].lstrip("-"))
    if entry["fill"] != want:
        print(f"DRIFT: classdef.{role} fill is {entry['fill']}, {entry['from']} computes to {want}")
        fail = 1
    for found in (entry["stroke"], entry["color"]):
        if found not in palette.values():
            print(f"DRIFT: classdef.{role} hex {found} is not a tufte-dracula.css palette color")
            fail = 1

# 3. The `/* was #xxxxxx */` provenance comments are read by whoever hand-edits
#    the stylesheet, so they have to stay true too. `.get`, not `[name]`: a token
#    this file cannot parse (alpha slash syntax, say) must report as drift rather
#    than crash with a KeyError that says nothing about which check failed.
for name, stated in re.findall(
    r"--([\w-]+):\s*oklch\([^)]*\);\s*/\* was (#[0-9a-f]{6})", css
):
    if palette.get(name) != stated:
        print(f"DRIFT: --{name} comment says {stated}, its oklch computes to {palette.get(name)}")
        fail = 1

# 4. contract-check.yml maps every palette key onto mermaid.js; this is the
#    reverse — a hex inline in mermaid.js that is no longer a palette color at all
#    (a hand-added themeVariable, a stale value under a renamed key).
for found in sorted(set(re.findall(r"#[0-9a-f]{6}", (ROOT / "mermaid.js").read_text()))):
    if found not in palette.values():
        print(f"DRIFT: mermaid.js hex {found} is not a tufte-dracula.css palette color")
        fail = 1

# 5. The light theme re-declares the dark palette on `pre.mermaid, .mermaid-overlay`,
#    because mermaid.js bakes the dark hex in and cannot be re-themed by a media
#    query. That block is a third projection of :root and can drift from it exactly
#    like mermaid-palette.json could, so every value in it must be the literal
#    :root value of the same token. Not a hex comparison: two different oklch()
#    triples can round to the same hex, and what has to hold here is that the
#    declaration was copied rather than re-derived.
diagram = re.search(r"pre\.mermaid, \.mermaid-overlay \{(.*?)\n\s*\}", stylesheet, re.S)
if not diagram:
    sys.exit("Could not find the `pre.mermaid, .mermaid-overlay` palette block.")
root_literal = dict(re.findall(r"--([\w-]+):\s*(oklch\([^)]*\))", css))
overrides = re.findall(r"--([\w-]+):\s*(oklch\([^)]*\))", diagram.group(1))
if len(overrides) < 9:
    sys.exit(f"Only parsed {len(overrides)} oklch overrides from the diagram block — expected 9.")
for name, stated in overrides:
    want = root_literal.get(name)
    if stated != want:
        print(f"DRIFT: diagram block --{name} is {stated}, :root declares {want}")
        fail = 1

print("Palette drift." if fail else f"Palette OK ({len(palette)} tokens).")
sys.exit(fail)
