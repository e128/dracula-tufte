#!/usr/bin/env python3
"""Fail if any hex projection of the palette drifts from the oklch source.

tufte-dracula.css :root is the single source of truth. Two projections carry the
same colors as hex, because Mermaid's color engine (khroma) throws "Unsupported
color format" on oklch() and renders no diagram at all:

  mermaid-palette.json  - the declared hex palette, keyed by themeVariables name
  mermaid.js            - the same values inline (consumers inline it, no build)

contract-check.yml already pins mermaid.js to mermaid-palette.json. This closes
the remaining edge: mermaid-palette.json back to the CSS it claims to project.
It is what makes the "from" fields load-bearing rather than decorative.

Paths resolve from this script's location, so cwd does not matter (scripts/maintain.nu
calls it by absolute path). Exit 1 on any drift.

ponytail: stdlib-only Oklab -> sRGB, no colour-science dependency for 17 values.
"""
import json
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def oklch_to_linear_raw(L, C, h):
    """oklch() -> linear sRGB, unclamped, so a channel outside 0..1 stays visible."""
    a = C * math.cos(math.radians(h))
    b = C * math.sin(math.radians(h))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def oklch_to_linear(L, C, h):
    """oklch() -> clamped linear sRGB. Clamping here is the gamut clip a browser does."""
    return tuple(min(1.0, max(0.0, v)) for v in oklch_to_linear_raw(L, C, h))


def max_chroma(L, h, eps=1e-4):
    """The largest chroma at this lightness and hue that still lands inside sRGB.

    Bisection, because there is no closed form: the sRGB boundary in Oklab is the
    surface where one of the three channels hits 0 or 1, and which channel that is
    depends on the hue. 40 halvings of 0..0.5 resolve it far finer than the three
    decimals a token is written to.
    """
    lo, hi = 0.0, 0.5
    for _ in range(40):
        mid = (lo + hi) / 2
        if all(-eps <= v <= 1 + eps for v in oklch_to_linear_raw(L, mid, h)):
            lo = mid
        else:
            hi = mid
    return lo


def oklch_to_linear_raw_p3(L, C, h):
    """oklch() -> linear Display P3, unclamped. Same Oklab step as sRGB, different matrix.

    The matrix is an OKLab-to-XYZ matrix composed with an XYZ-to-linear-Display-P3
    matrix (both from color.js, the reference implementation CSS Color 4 cites).
    Composing the same OKLab-to-XYZ matrix with an XYZ-to-linear-sRGB matrix instead
    reproduces the sRGB matrix above to 9 significant figures, which is what confirms
    this composition method rather than trusting it.
    """
    a = C * math.cos(math.radians(h))
    b = C * math.sin(math.radians(h))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        3.1277689714 * l - 2.2571357626 * m + 0.1293667912 * s,
        -1.0910090184 * l + 2.4133317103 * m - 0.3223226919 * s,
        -0.0260108019 * l - 0.5080413317 * m + 1.5340521336 * s,
    )


def max_chroma_p3(L, h, eps=1e-4):
    """The largest chroma at this lightness and hue that still lands inside Display P3.

    Same bisection as max_chroma, against the wider P3 boundary. Only P3_WIDENED
    tokens in P3_MODES are ever checked against this instead of max_chroma.
    """
    lo, hi = 0.0, 0.5
    for _ in range(40):
        mid = (lo + hi) / 2
        if all(-eps <= v <= 1 + eps for v in oklch_to_linear_raw_p3(L, mid, h)):
            lo = mid
        else:
            hi = mid
    return lo


def oklch_to_hex(L, C, h):
    """oklch() -> #rrggbb, gamut-mapped, matching how a browser renders it.

    Chroma is reduced to the sRGB ceiling before conversion, rather than clipped
    per-channel afterward, because that is what a browser's own CSS Color 4 gamut
    mapping does: hold L and h, pull C in to the boundary. A P3-reaching token (see
    P3_WIDENED) has no exact sRGB hex, but every hex-only consumer (Mermaid, the
    editor themes `--dump` feeds) is sRGB regardless, so this is the nearest
    same-hue-and-lightness color they can actually show, not a hue-shifted guess.
    Every token that already fits in sRGB is untouched: this only ever pulls
    chroma in, never out.
    """

    def encode(x):
        return 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055

    C = min(C, max_chroma(L, h))
    return "#%02x%02x%02x" % tuple(round(encode(v) * 255) for v in oklch_to_linear(L, C, h))


def contrast(one, two):
    """WCAG 2.x contrast ratio between two oklch triples, on the clipped values."""

    def relative_luminance(lch):
        r, g, b = oklch_to_linear(*lch)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b

    a, b = relative_luminance(one), relative_luminance(two)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)


stylesheet = (ROOT / "tufte-dracula.css").read_text()

# Only the :root block defines the palette. Scanning the whole stylesheet would let a
# --x: oklch(...) declared inside a component rule join the palette set and quietly
# widen the membership checks below, so a stale hex could start passing. Non-greedy up
# to a closing brace on its own line, and the first match is the real :root, and the
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
    sys.exit(f"Only parsed {len(palette)} oklch tokens from :root, expected 17.")

# --dump is the generator side of the same parse: scripts/create-themes.nu needs the palette
# as data, and re-deriving oklch -> sRGB in Nushell would mean a second implementation
# of the matrix above, free to drift from the one CI checks. This comment used to say
# Nushell had no trig builtins. It does, since `math sin` and `math cos` both work, checked
# on 0.114.1, so the reason is one implementation, not a missing primitive.
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

# The light palette is the base :root overlaid with the light block's overrides, which
# is how the cascade resolves it. mermaid.js carries both hex sets because khroma cannot
# read a var() or an oklch(), and picks one at init from the --mermaid-scheme token.
light_block = re.search(
    r"@media \(prefers-color-scheme: light\) \{\s*:root \{(.*?)\n\s*\}", stylesheet, re.S
)
if not light_block:
    sys.exit("Could not find the light :root block in tufte-dracula.css.")
light_triples = dict(triples)
light_triples.update({
    name: (float(L), float(C), float(h))
    for name, L, C, h in re.findall(
        r"--([\w-]+):\s*oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)", light_block.group(1)
    )
})
light_palette = {name: oklch_to_hex(*lch) for name, lch in light_triples.items()}

# 1. Every init hex is exactly the conversion of the variable it names, in both
#    palettes. initLight names the same tokens and resolves them through the light
#    block, so a light-only token edit cannot slip past by looking right in dark.
for section, source in (("init", palette), ("initLight", light_palette)):
    if section not in pal:
        print(f"DRIFT: mermaid-palette.json has no {section} section")
        fail = 1
        continue
    keys = [k for k in pal[section] if k != "_comment"]
    if len(keys) < 19:
        sys.exit(f"{section} has only {len(keys)} keys, refusing to pass vacuously.")
    for key in keys:
        entry = pal[section][key]
        want = source.get(entry["from"].lstrip("-"))
        if want is None:
            print(f"DRIFT: {section}.{key} names {entry['from']}, which is not in :root")
            fail = 1
        elif entry["hex"] != want:
            print(f"DRIFT: {section}.{key} is {entry['hex']}, {entry['from']} computes to {want}")
            fail = 1
    if set(keys) != set(k for k in pal["init"] if k != "_comment"):
        print(f"DRIFT: {section} and init cover different themeVariables keys")
        fail = 1

# 2. Each classdef fill is exactly the variable its `from` field names, and that is
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
#    reverse: a hex inline in mermaid.js that is no longer a palette color at all
#    (a hand-added themeVariable, a stale value under a renamed key).
known = set(palette.values()) | set(light_palette.values())
for found in sorted(set(re.findall(r"#[0-9a-f]{6}", (ROOT / "mermaid.js").read_text()))):
    if found not in known:
        print(f"DRIFT: mermaid.js hex {found} is not a tufte-dracula.css palette color")
        fail = 1

# 5. Every mode has to hold its own contrast floor. The stylesheet ships four
#    palettes now (the default, `prefers-contrast: more`, `prefers-color-scheme:
#    light` and print) and the ratios behind each one were measured by hand and
#    written into NOTES.md. A measurement in prose is not a gate: a later edit to
#    one lightness value strands text at a ratio nobody re-derives. This check
#    re-derives all of them on every run.
#
#    A mode block only restates what it changes, so each palette is the default
#    overlaid with that block's overrides, which is also how the cascade resolves
#    it. Text tokens are checked against all THREE backgrounds a reader meets:
#    --code-bg carries the default palette's floor, and --surface-alt is the
#    row-hover fill, which NOTES.md names as one of the grounds a token has to
#    clear and which this check did not look at for two releases. It is the
#    hardest of the three in light mode, where --muted, --orange and --pink all
#    measured 4.44 to 4.47 on it while passing on the other two, so a `strong` or
#    an outbound arrow inside a hovered row was under 4.5 with nothing saying so.
#    Rule tokens are checked against --surface only: --rule-light is a hairline on
#    the page background, and 1.4.11 asks 3:1 of a non-text boundary, not of a
#    border drawn inside a code fill.
#
#    DATA stays on --surface and --code-bg. A diagram is not drawn inside a table
#    row, so the hover fill is not a ground a category fill ever lands on.
#
#    DATA is the diagram-category ramp, and it is a non-text boundary like a rule
#    rather than text: a pie slice or a classDef fill has to be tellable from the
#    card it sits on. It is checked against BOTH grounds because a diagram is drawn
#    on --code-bg while a bare SVG lands on --surface. Through v1.24.0 this ramp had
#    no light or print override and measured 1.69 to 2.15:1 there, which NOTES.md
#    recorded and accepted. v1.25.0 gave it both, so the floor is now gated.
TEXT = ["on-surface", "label", "muted", "link", "orange", "red", "purple", "pink", "green"]
RULES = ["rule-light"]
DATA = ["data-1", "data-2", "data-3", "data-4"]
MODES = {
    # name: (media condition, text floor, non-text boundary floor)
    #
    # 4.2 for the default, not 4.5: --purple sits at 4.23 against --code-bg. That
    # is the documented floor under "Color and the contrast budget", kept because
    # --purple-bright carries the one role that puts purple text on that fill.
    # The floor is pinned here so it cannot slip further without saying so.
    "default": (None, 4.2, 3.0),
    "prefers-contrast: more": ("@media (prefers-contrast: more)", 7.0, 3.0),
    "prefers-color-scheme: light": ("@media (prefers-color-scheme: light)", 4.5, 3.0),
    "print": ("@media print", 4.5, 3.0),
}
resolved = {}
for mode, (condition, text_floor, rule_floor) in MODES.items():
    triples_for_mode = dict(triples)
    if condition is not None:
        block = re.search(
            re.escape(condition) + r" \{\s*:root \{(.*?)\n\s*\}", stylesheet, re.S
        )
        if not block:
            print(f"DRIFT: no `{condition}` block with a :root of its own")
            fail = 1
            continue
        overrides = {
            name: (float(L), float(C), float(h))
            for name, L, C, h in re.findall(
                r"--([\w-]+):\s*oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)", block.group(1)
            )
        }
        if not overrides:
            print(f"DRIFT: the `{condition}` block redefines no oklch token")
            fail = 1
            continue
        triples_for_mode.update(overrides)
    resolved[mode] = triples_for_mode
    # --on-surface goes to `oklch(1 0 0)` in high contrast, which the triple regex
    # reads fine, and print writes `oklch(0.200 0 0)`. Both parse. A token that
    # stops parsing drops back to its default value rather than vanishing, so a
    # weakened override cannot pass by becoming unreadable.
    for role, floor in ((TEXT, text_floor), (RULES, rule_floor), (DATA, rule_floor)):
        for name in role:
            fg = triples_for_mode[name]
            if role is RULES:
                grounds = ["surface"]
            elif role is DATA:
                grounds = ["surface", "code-bg"]
            else:
                grounds = ["surface", "code-bg", "surface-alt"]
            for ground in grounds:
                got = contrast(fg, triples_for_mode[ground])
                if got + 0.005 < floor:
                    print(
                        f"CONTRAST: {mode} --{name} is {got:.2f}:1 on --{ground}, "
                        f"below the {floor} floor for this mode"
                    )
                    fail = 1

# 6. --mermaid-scheme is the whole mechanism that lets a diagram follow the palette,
#    and deleting it fails silently: mermaid.js reads an empty string, decides "not
#    light", and renders a dark diagram on a light page while every other check stays
#    green. That is the exact defect this token was added to fix, so it is gated
#    rather than trusted. The token is not an oklch() value, so nothing else here sees
#    it, and the JS side is checked by name because a renamed token is the same bug.
mermaid_js = (ROOT / "mermaid.js").read_text()
for where, want, block_text in (
    (":root", "dark", css),
    ("the light :root block", "light", light_block.group(1)),
):
    if not re.search(r"--mermaid-scheme:\s*" + want + r"\s*;", block_text):
        print(f"DRIFT: {where} does not declare --mermaid-scheme: {want}")
        fail = 1
if "--mermaid-scheme" not in mermaid_js:
    print("DRIFT: mermaid.js never reads --mermaid-scheme, so a diagram cannot follow the palette")
    fail = 1
if "matchMedia" in mermaid_js:
    print("DRIFT: mermaid.js reads matchMedia, which reports the host, not the cascade, "
          "so the forced-light sample pages would render a dark diagram")
    fail = 1

# 7. Every declared chroma has to be reachable in sRGB, in every mode. A value above
#    the ceiling is not an error the browser reports: it clips per channel and paints
#    something else, so the stylesheet documents a color it never renders and every
#    check above still passes, because they all measure the clipped result. The
#    high-contrast block shipped three of these. --red was `oklch(0.895 0.142 21.457)`
#    where the ceiling at that lightness and hue is 0.055, so the declared chroma was
#    259% of what sRGB can hold, and Chrome painted `oklch(0.842 0.087 20.795)`: 0.053
#    of lightness and 0.055 of chroma gone, ΔE_ok 0.077 from the stated value. --pink
#    also drifted 4.9 degrees of hue, which is the part that makes this more than
#    bookkeeping.
#
#    The trap this closes is directional. An editor reading C 0.142 sees chroma to
#    spare and raises L for more contrast, but the ceiling *shrinks* as L climbs
#    (0.159 at L 0.74 against 0.052 at L 0.90 on that hue), so the color washes out
#    faster than the numbers in front of them predict. Checked in all four modes, on
#    every token the triple regex parses, not just the ones with a contrast floor.
#
#    The 0.0005 slack is one unit in the third decimal a token is written to. Sitting
#    exactly on the boundary passes, and it is still a bad place to sit: a later
#    lightness nudge tips it out. Aim for the fraction of maximum chroma the dark
#    token holds, which is the method the --data-* ramp already documents.
#
#    Six vivid accents (--red, --orange, --purple, --pink, --green, --data-1..4) hold
#    a P3-reaching chroma in dark and light mode, gated by P3_WIDENED and P3_MODES.
#    High-contrast and print keep these same tokens at their original sRGB values, so
#    they still gate against the sRGB ceiling: a real sRGB clip in either untouched
#    mode still fails loudly rather than passing under a relaxation meant for two
#    modes it never applies to.
P3_WIDENED = {"red", "orange", "purple", "pink", "green", "data-1", "data-2", "data-3", "data-4"}
P3_MODES = {"default", "prefers-color-scheme: light"}
for mode, triples_for_mode in resolved.items():
    for name, (L, C, h) in sorted(triples_for_mode.items()):
        wide = name in P3_WIDENED and mode in P3_MODES
        ceiling = max_chroma_p3(L, h) if wide else max_chroma(L, h)
        if C > ceiling + 0.0005:
            gamut = "P3" if wide else "sRGB"
            print(
                f"GAMUT: {mode} --{name} declares chroma {C:.3f} at L {L:.3f} hue {h:g}, "
                f"where {gamut} holds {ceiling:.3f} ({C / ceiling * 100:.0f}% of the ceiling). "
                f"The browser clips it to {oklch_to_hex(L, C, h)} instead."
            )
            fail = 1

# 8. Vividness is policy for some tokens, so it is pinned here rather than left in
#    prose. Chroma alone does not say how colorful a token looks: the sRGB ceiling
#    moves with lightness, so one absolute chroma reads as two different intensities
#    at two lightnesses. --red carried `0.142` in three modes and landed at 87% of the
#    ceiling in dark, 65% in light and 63% in print, which is one number producing
#    three different reds. It now holds 87% in all four, which keeps it the loudest
#    accent on purpose, and the light and print values that came out of that were also
#    strictly better on every measured pair. The --data-* ramp already held its
#    fractions exactly across modes; NOTES.md stated them and nothing enforced it.
#
#    The band is the fraction of maximum in-gamut chroma, checked in every mode. It is
#    wide enough for the third decimal a token is written to and narrow enough that a
#    lightness edit made without recomputing chroma trips it, which is the whole point:
#    L and C have to move together or the token changes character.
#
#    --link, --orange, --purple, --pink and --green are still deliberately absent from
#    this table. --orange, --purple, --pink and --green each hold one absolute chroma in
#    dark and a second one in light (see NOTES.md), so their fraction still floats
#    independently per mode rather than being pinned to an invariant. Pinning those
#    means rewriting the whole palette and re-measuring every ratio in this file,
#    which is a much larger change than the drift it would prevent. A table of five
#    tokens that is true beats a table of ten that is aspirational.
#
#    The five tokens below are pinned, and in dark and light mode the ceiling they are
#    measured against is now the P3 one (P3_WIDENED / P3_MODES, same as check 7). The
#    band numbers are unchanged; only the ruler is wider, in the two modes that widened.
VIVIDNESS = {
    "red": (0.85, 0.89),
    "data-1": (0.69, 0.73),
    "data-2": (0.54, 0.58),
    "data-3": (0.59, 0.63),
    "data-4": (0.55, 0.59),
}
for mode, triples_for_mode in resolved.items():
    for name, (low, high) in VIVIDNESS.items():
        L, C, h = triples_for_mode[name]
        ceiling = max_chroma_p3(L, h) if mode in P3_MODES else max_chroma(L, h)
        got = C / ceiling
        if not low <= got <= high:
            print(
                f"VIVIDNESS: {mode} --{name} is {got * 100:.1f}% of the sRGB ceiling at "
                f"L {L:.3f} hue {h:g}, outside the {low * 100:.0f} to {high * 100:.0f}% band. "
                f"Chroma {(low + high) / 2 * ceiling:.3f} would sit mid-band."
            )
            fail = 1

# 9. An accent used as a BACKGROUND is a pair no check above ever looks at. Check 5
#    only ever puts a token in the foreground, on --surface, --code-bg or
#    --surface-alt. Three components invert that: `.verdict-*`, `.step-node` and
#    `::selection` all paint --surface TEXT on an accent fill. Nothing gated any of
#    them, and the gap is not theoretical. `.step-node` takes its fill from an
#    --icon-color custom property that NOTES.md invited an author to set from the
#    --data-* ramp, and --surface on that ramp measures 3.45 to 3.53:1 in light mode
#    and 3.60:1 in print. Those are the same numbers NOTES.md already records as "a
#    real failure a reader would have copied" from the first draft of the .tag-dot
#    fixture, one component over, caught by hand that time.
#
#    So the ramp is now out of bounds for .step-node, stated in CONTRACT.md, and the
#    permitted set is pinned below. A .tag-dot or an .icon-chip may still carry a
#    --data-* color: the dot paints currentColor on an empty element, and the chip's
#    glyph is --on-surface on a 15%-alpha tint, which measures 8.06:1 and up. Only a
#    full-strength fill under real text is the problem.
#
#    Print is skipped for `.verdict-*` alone, because the print block replaces the
#    fill with `background: none` plus a currentColor ring and recolors the text, so
#    the pair this check describes does not exist on paper. `.step-node` has no print
#    override, so it is checked there like everywhere else.
INVERTED = {
    ".verdict-*": ("surface", ["green", "orange", "red", "muted"], {"print"}),
    ".step-node": ("surface", ["orange", "link", "purple", "green"], set()),
    "::selection": ("surface", ["purple"], set()),
}
for mode, triples_for_mode in resolved.items():
    floor = MODES[mode][1]
    for component, (text, grounds, skip) in INVERTED.items():
        if mode in skip:
            continue
        for ground in grounds:
            got = contrast(triples_for_mode[text], triples_for_mode[ground])
            if got + 0.005 < floor:
                print(
                    f"CONTRAST: {mode} {component} puts --{text} text on a --{ground} "
                    f"fill at {got:.2f}:1, below the {floor} floor for this mode"
                )
                fail = 1

#    The prohibition above needs a reason that stays true, not a comment. If a later
#    edit to the ramp made --surface legible on all four members in every mode, the
#    exclusion would be dead weight and this check says so out loud rather than
#    leaving a rule nobody can retire.
ramp_ok = True
for mode, triples_for_mode in resolved.items():
    for name in DATA:
        if contrast(triples_for_mode["surface"], triples_for_mode[name]) + 0.005 < MODES[mode][1]:
            ramp_ok = False
if ramp_ok:
    print(
        "STALE: --surface now clears the text floor on every --data-* member in every "
        "mode, so the .step-node exclusion in CONTRACT.md has no reason left. Either "
        "widen INVERTED['.step-node'] to include the ramp, or delete this check."
    )
    fail = 1

# 10. Two tokens are written with relative color syntax, and the triple regex above
#     cannot see either one. `--purple-bright: oklch(from var(--purple) calc(l + 0.07)
#     c h)` and `--highlight: oklch(from var(--orange) l c h / 0.35)` therefore sat
#     outside checks 5 and 7 entirely. That matters most for --purple-bright, because
#     it is the ONE token that puts purple text on --code-bg: NOTES.md records
#     --purple itself at 4.21:1 there, the tightest accent-on-ground pair in the
#     sheet, and accepts it precisely because no purple text renders on that fill.
#     --purple-bright is the counterexample to that reasoning, it renders on every
#     highlighted code block as .hljs-type, and nothing measured it. It currently
#     clears its floor with margin, so this closes a blind spot rather than a failure,
#     but a later nudge to --purple's lightness moves it silently either way.
#
#     Only two forms exist, so this resolves those two rather than implementing
#     relative color in general. A third form fails loudly below instead of being
#     silently skipped, which is the failure mode this check exists to remove.
RELATIVE = re.compile(
    r"--([\w-]+):\s*oklch\(from var\(--([\w-]+)\) "
    r"(?:calc\(l ([+-]) ([\d.]+)\)|l) c h(?: / ([\d.]+))?\)"
)


def relative_decls(text):
    out = {}
    for name, base, sign, delta, alpha in RELATIVE.findall(text):
        shift = 0.0 if not delta else (float(delta) if sign == "+" else -float(delta))
        out[name] = (base, shift, float(alpha) if alpha else 1.0)
    return out


def encode(x):
    return 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055


def decode(x):
    return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4


def over(fg, bg, alpha):
    """Alpha-composite two oklch triples, in the gamma-encoded space a browser uses.

    Compositing the linear values instead reads several tenths of a ratio too bright,
    which is enough to turn a failing pair into a passing one. Reproducing NOTES.md's
    own recorded .kicker numbers (6.60:1 dark, 4.71:1 light) is what confirms this is
    the right space rather than an assumption about it.
    """
    f, b = oklch_to_linear(*fg), oklch_to_linear(*bg)
    return tuple(decode(encode(x) * alpha + encode(y) * (1 - alpha)) for x, y in zip(f, b))


def relative_luminance_lin(lin):
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def contrast_lin(one, two):
    a, b = relative_luminance_lin(one), relative_luminance_lin(two)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)


base_relative = relative_decls(css)
declared_relative = set(base_relative)
for mode, (condition, text_floor, rule_floor) in MODES.items():
    triples_for_mode = resolved.get(mode)
    if triples_for_mode is None:
        continue
    block = css
    if condition is not None:
        found = re.search(
            re.escape(condition) + r" \{\s*:root \{(.*?)\n\s*\}", stylesheet, re.S
        )
        block = found.group(1) if found else ""
    rel = dict(base_relative)
    rel.update(relative_decls(block))
    declared_relative |= set(rel)
    for name, (base, shift, alpha) in rel.items():
        # A mode may override the relative form with a literal, which print does for
        # --purple-bright and which prefers-contrast: more now has to do as well. Check
        # 7 already owns the gamut for a literal, because the triple regex sees it; the
        # contrast floor is checked here either way, since --purple-bright is in no
        # role list above and would otherwise be measured in two modes out of four.
        literal = name in triples_for_mode
        L, C, h = triples_for_mode[name] if literal else triples_for_mode[base]
        resolved_lch = (L, C, h) if literal else (L + shift, C, h)
        origin = f"--{name}" if literal else f"--{name} (from --{base})"
        if alpha == 1.0:
            for ground in ("surface", "code-bg", "surface-alt"):
                got = contrast(resolved_lch, triples_for_mode[ground])
                if got + 0.005 < text_floor:
                    print(
                        f"CONTRAST: {mode} {origin} is {got:.2f}:1 on "
                        f"--{ground}, below the {text_floor} floor for this mode"
                    )
                    fail = 1
            if not literal:
                ceiling = (
                    max_chroma_p3(resolved_lch[0], resolved_lch[2])
                    if base in P3_WIDENED and mode in P3_MODES
                    else max_chroma(resolved_lch[0], resolved_lch[2])
                )
                if C > ceiling + 0.0005:
                    print(
                        f"GAMUT: {mode} {origin} declares chroma {C:.3f} at "
                        f"L {resolved_lch[0]:.3f}, where the ceiling holds {ceiling:.3f}"
                    )
                    fail = 1
        else:
            # An alpha wash is a background, and --on-surface is what `mark` pins on
            # top of it. The floor is 4.5 in every mode, including prefers-contrast:
            # more, because the alpha caps what the composite can reach and NOTES.md
            # already records that trade: a lower alpha would make the highlight
            # harder to see, which is the one thing the element exists to do.
            for ground in ("surface", "code-bg"):
                composite = over(resolved_lch, triples_for_mode[ground], alpha)
                got = contrast_lin(oklch_to_linear(*triples_for_mode["on-surface"]), composite)
                if got + 0.005 < 4.5:
                    print(
                        f"CONTRAST: {mode} --on-surface on --{name} ({alpha:g} alpha of "
                        f"--{base}) over --{ground} is {got:.2f}:1, below 4.5"
                    )
                    fail = 1

#     A token that stops matching RELATIVE stops being checked, and a check that
#     silently covers nothing is worse than no check. Both names are pinned.
for name in ("purple-bright", "highlight"):
    if name not in declared_relative and name not in triples:
        print(
            f"DRIFT: --{name} is neither an oklch() triple nor a relative color this "
            f"file can parse, so nothing measures it in any mode"
        )
        fail = 1

print("Palette drift." if fail else f"Palette OK ({len(palette)} tokens, 4 modes).")
sys.exit(fail)
