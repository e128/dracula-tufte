#!/usr/bin/env nu
# build-sample.nu regenerates the samples/ pages, a living demo of every
# component in tufte-dracula.css + mermaid.js. Re-inlines the two source files
# verbatim (same bytes the renderer emits), so a CSS or mermaid edit shows up
# here on the next run. Run: `nu scripts/build-sample.nu` (writes + git-adds).
#
# ponytail: static demo body, no markdown pipeline. This is a style fixture, not
# a lode scroll. html-render.nu owns real content. Add a component here whenever
# tufte-dracula.css gains one.

# path self is this file, so its dirname is scripts/ and ROOT is the repo above it.
# Everything resolves from ROOT, never from cwd, so this runs from anywhere in the tree.
# SCRIPTS exists because `path self | path dirname | path dirname` is not a legal const
# chain in Nushell, because the second step has to read a name that is already bound.
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname

def main [] {
  let css = (open --raw ($ROOT | path join "tufte-dracula.css") | str trim --right)
  let mermaid = (open --raw ($ROOT | path join "mermaid.js") | str trim --right)
  let filter = (open --raw ($ROOT | path join "filter.js") | str trim --right)
  let highlight = (open --raw ($ROOT | path join "highlight.js") | str trim --right)

  tokens $css

  # (filename, <body> tag, title, body-content, light-preview filename), one page
  # per layout mode, each with a forced-light twin for Pages.
  [
    ["dark.html" "<body>" "Tufte-Dracula component sample" (body) "light.html"]
    ["dark-conn-map.html" "<body class=\"conn-map\">" "Tufte-Dracula connections-map layout" (conn-map-body) "light-conn-map.html"]
    ["dark-timeline.html" "<body>" "Tufte-Dracula timeline layout" (timeline-body) "light-timeline.html"]
    ["dark-charts.html" "<body>" "Tufte-Dracula chart components" (charts-body) "light-charts.html"]
  ] | each {|p|
    let html = ([
      "<!DOCTYPE html>"
      "<html lang=\"en\">"
      "<head>"
      "  <meta charset=\"utf-8\"/>"
      "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\"/>"
      $"  <title>($p.2)</title>"
      "  <meta name=\"generated-by\" content=\"scripts/build-sample.nu\"/>"
      $css
      $mermaid
      $filter
      $highlight
      "</head>"
      $p.1
      $p.3
      "</body>"
      "</html>"
    ] | str join "\n")
    let out = ($ROOT | path join "samples" $p.0)
    $html | save -f $out
    ^git -C $ROOT add $out
    print $"  → ($out)"
    preview $html $p.0 $p.2 $p.4
  }
  null
}

# The light palette is a media query, so no fixture shows it: a visitor on a
# dark-appearance OS sees dark and has to change a system setting to see anything
# else. Pages serves this repo root from main, so one extra HTML file per fixture
# is a live light-mode preview with no workflow, no deploy step and no docs/ dir.
#
# The rewrite is the one render-modes.py uses: the light condition becomes
# `@media all` so it always matches, and the high-contrast condition becomes
# `@media not all` so it never does. Forcing light alone would be almost enough,
# the light block is declared after the contrast block and overrides every token
# it sets, but it would leave the contrast block's two non-token rules live, so a
# visitor who asks for more contrast would see a preview nobody else sees.
# Deterministic beats almost.
#
# light.html is NOT the payload: the stylesheet inside it has had its media
# conditions rewritten, so it is not the file a consumer inlines. It sits beside
# dark.html under one folder and reads like an equal peer, which is exactly why
# the banner is not optional, because the filename no longer carries the warning.
def preview [html: string, fixture: string, title: string, name: string] {
  # One list drives both the presence check and the rewrite, so the two cannot drift.
  # Each condition is checked on its own, not "did anything change". A first cut
  # compared the whole string before and after and passed when only the contrast
  # condition still matched, which is the case that matters least. Renaming the
  # light condition alone would have shipped a dark page called light.
  #
  # The print-and-light block becomes an unconditional `@media print`, because a page
  # locked to light renders a light-themed diagram, which needs neither the frozen dark
  # palette nor the ground that goes with it. Leaving the condition intact would also
  # leave a live `prefers-color-scheme` in a page that claims to have none, which the
  # contract check reads as a rewrite that did not happen. Its entry sits first only for
  # readability: the longer string is not a substring of the shorter one.
  let rewrites = [
    {cond: "@media print and (prefers-color-scheme: light)", to: "@media print"}
    {cond: "@media (prefers-color-scheme: light)", to: "@media all"}
    {cond: "@media (prefers-contrast: more)", to: "@media not all"}
  ]
  for r in $rewrites {
    if not ($html | str contains $r.cond) {
      error make {msg: $"preview: ($fixture) has no `($r.cond)`: the stylesheet renamed it, so the preview would ship the default palette under a light name"}
    }
  }
  let forced = ($rewrites | reduce --fold $html {|r, acc| $acc | str replace $r.cond $r.to })
  let banner = ([
    "  <div class=\"markdown-alert markdown-alert-caution\">"
    "    <p class=\"markdown-alert-title\">Preview only, not the payload</p>"
    $"    <p>This page forces <code>prefers-color-scheme: light</code>, so the light palette shows on any system. Its copy of the stylesheet has had the <code>@media</code> conditions rewritten to do that, which makes it <strong>locked to light</strong> and <strong>not the payload</strong>. Inline <code>tufte-dracula.css</code> from the repo root, never a page. <a href=\"($fixture)\">($fixture)</a> is the same fixture with the stylesheet verbatim.</p>"
    "  </div>"
  ] | str join "\n")
  let out = ($ROOT | path join "samples" $name)
  ($forced
    | str replace $"<title>($title)</title>" $"<title>($title): forced light preview</title>"
    | str replace --regex '(?m)^(<body[^>]*>)$' $"$1\n($banner)") | save -f $out
  ^git -C $ROOT add $out
  print $"  → ($out)"
}

# tokens.css is a projection of tufte-dracula.css, not a second source: the :root
# block sliced out verbatim (only the shared indent is stripped). Verbatim means
# no transform step, so nothing to drift. The AA-tuning comments, the
# `--rule: var(--muted)` alias and the layout tokens all come along as written.
# The staleness gate in contract-check.yml covers this file for free.
def tokens [css: string] {
  let version = ($css | lines | get 1 | parse --regex 'v(?<v>[\d.]+)' | get v.0)
  let root = ($css | lines
    | skip while {|l| ($l | str trim) != ":root {" }
    | take while {|l| ($l | str trim) != "}" }
    | each {|l| $l | str replace --regex '^    ' "" })
  let out = ($ROOT | path join "tokens.css")
  ([
    $"/* Tufte-Dracula palette tokens \(template v($version)\)."
    " * GENERATED by scripts/build-sample.nu from the :root block of tufte-dracula.css, verbatim."
    " * Reference only; the renderer inlines the full tufte-dracula.css, which already"
    " * carries these declarations. Do not hand-edit: change tufte-dracula.css and run"
    " * `nu scripts/build-sample.nu`. */"
    ...$root
    "}"
    ""
  ] | str join "\n") | save -f $out
  ^git -C $ROOT add $out
  print $"  → ($out)"
}

# Connections-map layout: body.conn-map, two sections in order (Links, Graph).
# Wide screens put Links left+sticky, graph right; below 900px it stacks with a
# full-bleed graph. flowchart BT + useMaxWidth:false is what the real maps emit.
#
# Links comes FIRST in the DOM as of v1.8.0 so tab and screen-reader order match
# the visual order. The stylesheet no longer reorders; markup order is the layout
# order. A page emitted with the old (Graph, Links) markup renders reversed under
# this stylesheet. See NOTES.md.
#
# One long, hyphenated link label ships in each list below on purpose: the Links
# column is a narrow sticky rail (clamp(220px, 22vw, 300px)), and a real slug
# like "depollier-bayonet-crown" is exactly what overflows a column that isn't
# forced to one grid track. If this regresses, the rail grows a horizontal
# scrollbar alongside its intended vertical one.
#
# The Graph section holds two diagrams: the small map is the container-CSS
# fixture (long label, useMaxWidth:false). The large map exercises the "Large
# maps" NOTES.md section instead: open (never collapsed) subgraphs, the ELK
# layout engine, a legend in place of per-edge text labels, and a `click`
# directive on every node, because a connections map must link out to every
# item it names. Both ship in the one fixture so a CSS or mermaid.js edit
# shows up against both patterns on the next regenerate.
def conn-map-body [] {
  [
    "  <dialog class=\"mermaid-overlay\" id=\"mermaid-zoom\"></dialog>"
    "  <main>"
    "  <article>"
    "    <h1>Connections-Map Layout Sample</h1>"
    "    <p class=\"byline\">body.conn-map, Links column left, graph right (wide screens)</p>"
    "    <section>"
    "      <h2>Links</h2>"
    "      <h3>Antecedents</h3>"
    "      <ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">Antecedent A</a></li><li><a href=\"#\">Antecedent B</a></li><li><a href=\"#\">depollier-bayonet-crown-antecedent</a></li></ul>"
    "      <h3>Descendants</h3>"
    "      <ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">Descendant X</a></li><li><a href=\"#\">Descendant Y</a></li><li><a href=\"#\">perpetual-calendar-watch-descendant</a></li></ul>"
    "    </section>"
    "    <section>"
    "      <h2>Graph</h2>"
    "      <h3>Small map</h3>"
    "      <pre class=\"mermaid\">%%{init: {'flowchart': {'useMaxWidth': false}}}%%\nflowchart BT\n  accTitle: Connections map for the focus topic\n  accDescr: Antecedents A and B feed the focus topic, which leads to descendants X and Y. The focus label is deliberately long, so its box must not clip its own text or push the graph past the column.\n  focus[Focus Topic with a deliberately long label that must fit its own box]\n  a1[Antecedent A] --> focus\n  a2[Antecedent B] --> focus\n  focus --> d1[Descendant X]\n  focus --> d2[Descendant Y]</pre>"
    "      <h3>Large map</h3>"
    "      <p>Past roughly 15 to 20 nodes on one rank the small map's flat fan-out sprawls (see NOTES.md, Large maps). This map groups antecedents and descendants into open subgraphs, switches to the ELK layout engine, and states each relationship style once in a legend instead of on every edge. Every node stays clickable: the subgraphs are never collapsed, because <code>view: collapsed</code> drops a cluster's nodes, and their links, from the render entirely. A consumer wanting real per-node links adds a <code>click</code> directive per node and sets <code>window.mermaidSecurityLevel = 'loose'</code> (see NOTES.md, Zoom); this fixture leaves the default <code>strict</code>, so it stays a three-<code>&lt;script&gt;</code> fixture.</p>"
    "      <pre class=\"mermaid\">---\nconfig:\n  layout: elk\n  flowchart:\n    useMaxWidth: false\n  elk:\n    nodePlacementStrategy: NETWORK_SIMPLEX\n---\nflowchart TD\n  accTitle: Large connections map for the focus topic\n  accDescr: A focus topic with two eras of antecedents and descendants grouped into open subgraphs, every node individually clickable, and a legend explaining that a solid line is a technological connection and a dashed line is a conceptual one.\n  subgraph legend[\"Legend\"]\n    direction LR\n    key1((\" \")) -->|technological| key2((\" \"))\n    key3((\" \")) -.->|conceptual| key4((\" \"))\n  end\n  focus[Focus Topic]\n  subgraph pre2010[\"Antecedents, pre-2010\"]\n    a1[Antecedent A]\n    a2[Antecedent B]\n    a3[Antecedent C]\n    a4[Antecedent D]\n    a5[Antecedent E]\n    a6[Antecedent F]\n  end\n  subgraph post2010[\"Descendants, post-2010\"]\n    d1[Descendant W]\n    d2[Descendant X]\n    d3[Descendant Y]\n    d4[Descendant Z]\n  end\n  a1 --> focus\n  a2 --> focus\n  a3 --> focus\n  a4 -.-> focus\n  a5 -.-> focus\n  a6 --> focus\n  focus --> d1\n  focus --> d2\n  focus -.-> d3\n  focus --> d4</pre>"    "    </section>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}

# Charts get their own page, not a section in the component sample, because the forms are only
# worth anything side by side: a bar table, a sparkline and a line chart state the same kind of
# number three ways, and a page is where the guidance CONTRACT.md section 2 gives can be looked at.
#
# Two bar tables ship on purpose, and the difference is the axis rather than the color:
# the first is a share of the whole, the second a share of the largest value in the
# column. Both bands are one hue. A per-row hue was tried and measured out: at the 0.3
# alpha the number on top of the band requires, the four ramp members land within Lc 2
# of each other, so a band cannot carry a category (see NOTES.md, CSS charts). The
# number stays `--on-surface` over the wash, which check 12 of palette-check.py
# measures in all four modes.
def charts-body [] {
  [
    "  <dialog class=\"mermaid-overlay\" id=\"mermaid-zoom\"></dialog>"
    "  <main>"
    "  <article>"
    "    <h1>Chart Components</h1>"
    "    <p class=\"byline\">table.bar-chart, a column sparkline and small multiples in CSS over ordinary markup, and a Mermaid line chart, all using illustrative fixture data</p>"
    ""
    "    <nav class=\"toc\" aria-labelledby=\"toc-label\">"
    "      <p class=\"toc-label\" id=\"toc-label\">On this page</p>"
    "      <ol>"
    "        <li><a href=\"#bars\">Bar charts</a></li>"
    "        <li><a href=\"#spark\">Sparklines</a></li>"
    "        <li><a href=\"#multiples\">Small multiples</a></li>"
    "        <li><a href=\"#line\">Line chart</a></li>"
    "        <li><a href=\"#derived\">Stored and derived</a></li>"
    "        <li><a href=\"#more\">More diagram types</a></li>"
    "        <li><a href=\"#summary\">Reading summary</a></li>"
    "        <li><a href=\"#which\">Which one</a></li>"
    "      </ol>"
    "    </nav>"
    ""
    "    <section>"
    "      <h2 id=\"bars\">Bar chart</h2>"
    "      <p>A bar chart here is a real table with a class on it. The bar is a background band inside the cell that already holds the number, sized by a <code>--bar</code> percentage the generator sets, so the value is text in the markup and the bar is a second reading of it. Nothing is added to the accessibility tree and nothing is lost when the band does not paint.</p>"
    "      <dl class=\"stat-strip\">"
    "        <div><dt>Files</dt><dd class=\"v\">4</dd><dd class=\"s\">in the payload</dd></div>"
    "        <div><dt>Largest share</dt><dd class=\"v\">52%</dd><dd class=\"s\">the stylesheet</dd></div>"
    "        <div><dt>Smallest share</dt><dd class=\"v\">12%</dd><dd class=\"s\">the palette file</dd></div>"
    "      </dl>"
    "      <table class=\"bar-chart\" tabindex=\"0\">"
    "        <caption><span class=\"label\">Payload share by file</span>Illustrative shares across four files. Each value is a share of their combined total. Guides mark 25 percentage points.<span class=\"byline\">Source: fixture data, not measured file sizes.</span></caption>"
    "        <thead><tr><th scope=\"col\">File</th><th scope=\"col\">Share</th></tr></thead>"
    "        <tbody>"
    "          <tr><td><code>tufte-dracula.css</code></td><td class=\"bar lead\" style=\"--bar: 52%\">52%</td></tr>"
    "          <tr><td><code>mermaid.js</code></td><td class=\"bar\" style=\"--bar: 21%\">21%</td></tr>"
    "          <tr><td><code>filter.js</code></td><td class=\"bar\" style=\"--bar: 15%\">15%</td></tr>"
    "          <tr><td><code>mermaid-palette.json</code></td><td class=\"bar\" style=\"--bar: 12%\">12%</td></tr>"
    "        </tbody>"
    "        <tfoot><tr><td>Total</td><td>100%</td></tr></tfoot>"
    "      </table>"
    "      <p class=\"chart-takeaway\"><strong>Read:</strong> the stylesheet has the largest share in this example.<span class=\"more\">Compare bar length for rank, and keep the percentage for exact values.</span></p>"
    "      <p>Every band uses one hue, and the row label carries the category. Per-row colors from the <code>--data-*</code> ramp were tried and measured out: at the 0.3 alpha that keeps each number legible, the four ramp members land within Lc 2 of each other, so color cannot identify a category (see NOTES.md, <em>CSS charts</em>). The next table uses a different scale: each bar is a share of the largest value, not a share of the total.</p>"
    "      <table class=\"bar-chart\" tabindex=\"0\">"
    "        <caption>Illustrative counts. Bar length is a share of the largest value, 480, not a share of the total. Guides mark 25 percentage points.<span class=\"byline\">Source: fixture data.</span></caption>"
    "        <thead><tr><th scope=\"col\">Category</th><th scope=\"col\">Count</th><th scope=\"col\" class=\"num\">Versus prior run</th></tr></thead>"
    "        <tbody>"
    "          <tr><td>First category</td><td class=\"bar\" style=\"--bar: 100%\">480</td><td class=\"num\">×1.6</td></tr>"
    "          <tr><td>Second category</td><td class=\"bar\" style=\"--bar: 65%\">312</td><td class=\"num\">×1.2</td></tr>"
    "          <tr><td>Third category</td><td class=\"bar\" style=\"--bar: 28%\">134</td><td class=\"num\">×0.9</td></tr>"
    "          <tr><td>Fourth category</td><td class=\"bar\" style=\"--bar: 4%\">19</td><td class=\"num\">×3.0</td></tr>"
    "        </tbody>"
    "      </table>"
    "      <p class=\"chart-takeaway\"><strong>Read:</strong> the second chart compares counts to a named maximum. The printed count remains the exact value, and the right-aligned multiple states the change against the prior run in text, so no reader has to compare two bars to get it.</p>"
    "      <h3 id=\"summary\">Reading summary</h3>"
    "      <table class=\"evidence-table\" tabindex=\"0\">"
    "        <caption>How to read the two bar tables<span class=\"byline\">Source: illustrative fixture values.</span></caption>"
    "        <thead><tr><th scope=\"col\">Finding</th><th scope=\"col\">Evidence</th><th scope=\"col\">Action</th></tr></thead>"
    "        <tbody>"
    "          <tr><td>First table shows shares of a whole</td><td>Four values total 100%</td><td>Compare each file's contribution.</td></tr>"
    "          <tr><td>Second table uses the largest value as its baseline</td><td>480 is 100%; 19 is 4%</td><td>Compare bar lengths, then read exact counts.</td></tr>"
    "        </tbody>"
    "      </table>"
    "      <details class=\"deep\"><summary>Method</summary><p>The first table divides each value by the four-file total. The second divides each count by 480. Guide lines mark 25 percentage point intervals. Fixture values are illustrative, not measured repository sizes.</p></details>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"spark\">Sparklines</h2>"
    "      <p>A sparkline is a word-sized graphic that sits in a table cell or a sentence and shows the shape of a series next to the numbers that state it. Here it is a row of <code>i</code> columns inside <code>span.spark</code>, each sized by a <code>--h</code> percentage the generator sets. Every column stands on one zero baseline, so a falling series looks like a fall and never like a stretched range, and the final column is drawn in <code>--on-surface</code> so the latest value is the one mark a reader finds first. The first and latest values are text in the cells that flank the sparkline, and the whole series is a <code>data-values</code> attribute, so the shape is a second reading and the numbers stay the source. Order rows by the latest value unless the rows have a natural order of their own.</p>"
    "      <table class=\"bar-chart\" tabindex=\"0\">"
    "        <caption><span class=\"label\">Payload share across six releases</span>Each column is a file's share of the combined total in one release, oldest on the left. Full height is 60 percent for every row, so the rows compare with each other.<span class=\"byline\">Source: fixture data.</span></caption>"
    "        <thead><tr><th scope=\"col\">File</th><th scope=\"col\" class=\"num\">First</th><th scope=\"col\">Trend</th><th scope=\"col\" class=\"num\">Latest</th></tr></thead>"
    "        <tbody>"
    "          <tr><td><code>tufte-dracula.css</code></td><td class=\"num\">30%</td><td><span class=\"spark\" data-values=\"30%, 34%, 38%, 44%, 49%, 52%\"><i style=\"--h: 50%\"></i><i style=\"--h: 57%\"></i><i style=\"--h: 63%\"></i><i style=\"--h: 73%\"></i><i style=\"--h: 82%\"></i><i style=\"--h: 87%\"></i></span></td><td class=\"num\">52%</td></tr>"
    "          <tr><td><code>mermaid.js</code></td><td class=\"num\">40%</td><td><span class=\"spark\" data-values=\"40%, 36%, 32%, 27%, 24%, 21%\"><i style=\"--h: 67%\"></i><i style=\"--h: 60%\"></i><i style=\"--h: 53%\"></i><i style=\"--h: 45%\"></i><i style=\"--h: 40%\"></i><i style=\"--h: 35%\"></i></span></td><td class=\"num\">21%</td></tr>"
    "          <tr><td><code>filter.js</code></td><td class=\"num\">20%</td><td><span class=\"spark\" data-values=\"20%, 19%, 18%, 17%, 16%, 15%\"><i style=\"--h: 33%\"></i><i style=\"--h: 32%\"></i><i style=\"--h: 30%\"></i><i style=\"--h: 28%\"></i><i style=\"--h: 27%\"></i><i style=\"--h: 25%\"></i></span></td><td class=\"num\">15%</td></tr>"
    "          <tr><td><code>mermaid-palette.json</code></td><td class=\"num\">10%</td><td><span class=\"spark\" data-values=\"10%, 11%, 12%, 12%, 11%, 12%\"><i style=\"--h: 17%\"></i><i style=\"--h: 18%\"></i><i style=\"--h: 20%\"></i><i style=\"--h: 20%\"></i><i style=\"--h: 18%\"></i><i style=\"--h: 20%\"></i></span></td><td class=\"num\">12%</td></tr>"
    "        </tbody>"
    "      </table>"
    "      <p class=\"chart-takeaway\"><strong>Read:</strong> the stylesheet's share climbs every release while the Mermaid script's falls.<span class=\"more\">Compare the shapes for direction and the first and latest values for size.</span></p>"
    "      <p>A sparkline also reads inside a sentence. The stylesheet's share rose from 30% to 52% <span class=\"spark\" data-values=\"30%, 34%, 38%, 44%, 49%, 52%\"><i style=\"--h: 50%\"></i><i style=\"--h: 57%\"></i><i style=\"--h: 63%\"></i><i style=\"--h: 73%\"></i><i style=\"--h: 82%\"></i><i style=\"--h: 87%\"></i></span> across the six releases.<label for=\"mn-spark\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-spark\" class=\"margin-toggle\"/><span class=\"marginnote\">The Mermaid script fell from 40% to 21% <span class=\"spark fit\" data-values=\"40%, 36%, 32%, 27%, 24%, 21%\"><i style=\"--h: 100%\"></i><i style=\"--h: 81%\"></i><i style=\"--h: 62%\"></i><i style=\"--h: 38%\"></i><i style=\"--h: 24%\"></i><i style=\"--h: 10%\"></i></span> stretched to its own range, with a dashed baseline.</span> The same graphic fits a margin note, which is where Tufte set small figures beside the text they support. Add <code>fit</code> when the shape matters more than the size: the columns stretch from the series' lowest to its highest value, and the dashed baseline tells a reader that the bottom is not zero.</p>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"multiples\">Small multiples</h2>"
    "      <p>Small multiples repeat one chart design across a series of cases, so a reader learns the encoding once and spends the rest of the page comparing. <code>div.multiples</code> lays ordinary <code>table.bar-chart</code> children in a grid that wraps by available width. Every panel must share one scale, and the shared scale belongs in the paragraph above the grid. The first panel carries the row labels once, and each later panel keeps only its caption, its bars and its source. Every panel lists the same rows in the same order, and a later panel is indented by the label column so its bars line up with the first.</p>"
    "      <div class=\"multiples\">"
    "        <table class=\"bar-chart\" tabindex=\"0\">"
    "          <caption><span class=\"label\">Release 1</span>Share of the combined total. Guides mark 25 percentage points.</caption>"
    "          <thead><tr><th scope=\"col\">File</th><th scope=\"col\">Share</th></tr></thead>"
    "          <tbody>"
    "            <tr><td>Stylesheet</td><td class=\"bar\" style=\"--bar: 30%\">30%</td></tr>"
    "            <tr><td>Mermaid</td><td class=\"bar\" style=\"--bar: 40%\">40%</td></tr>"
    "            <tr><td>Filter</td><td class=\"bar\" style=\"--bar: 20%\">20%</td></tr>"
    "            <tr><td>Palette</td><td class=\"bar\" style=\"--bar: 10%\">10%</td></tr>"
    "          </tbody>"
    "        </table>"
    "        <table class=\"bar-chart\" tabindex=\"0\">"
    "          <caption><span class=\"label\">Release 3</span>Share of the combined total. Guides mark 25 percentage points.</caption>"
    "          <thead><tr><th scope=\"col\">Share</th></tr></thead>"
    "          <tbody>"
    "            <tr><td class=\"bar\" style=\"--bar: 38%\">38%</td></tr>"
    "            <tr><td class=\"bar\" style=\"--bar: 32%\">32%</td></tr>"
    "            <tr><td class=\"bar\" style=\"--bar: 18%\">18%</td></tr>"
    "            <tr><td class=\"bar\" style=\"--bar: 12%\">12%</td></tr>"
    "          </tbody>"
    "        </table>"
    "        <table class=\"bar-chart\" tabindex=\"0\">"
    "          <caption><span class=\"label\">Release 6</span>Share of the combined total. Guides mark 25 percentage points.</caption>"
    "          <thead><tr><th scope=\"col\">Share</th></tr></thead>"
    "          <tbody>"
    "            <tr><td class=\"bar\" style=\"--bar: 52%\">52%</td></tr>"
    "            <tr><td class=\"bar\" style=\"--bar: 21%\">21%</td></tr>"
    "            <tr><td class=\"bar\" style=\"--bar: 15%\">15%</td></tr>"
    "            <tr><td class=\"bar\" style=\"--bar: 12%\">12%</td></tr>"
    "          </tbody>"
    "        </table>"
    "      </div>"
    "      <p class=\"chart-takeaway\"><strong>Read:</strong> every panel is a share of its own release total on the same 0 to 100 percent scale.<span class=\"more\">Read across the panels for change and down one panel for rank.</span></p>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"line\">Line chart</h2>"
    "      <p>A time series is a line chart: one hue, no legend, no gridlines, and the axes drawn in the muted rule color so the data is the heaviest ink on the page. It is a Mermaid <code>xychart</code> fence with a single <code>line</code> series, themed per palette in <code>mermaid.js</code>. A line may start above zero because it shows shape, but this one stands on zero so it shares the scale of the sparklines above. Draw one only beside a table that states every value, the same rule as the radar chart below.</p>"
    "      <pre class=\"mermaid\">---\naccTitle: Stylesheet share by release\naccDescr: The stylesheet share of the combined payload rises from 30 percent in release 1 to 52 percent in release 6.\nconfig:\n  xyChart:\n    height: 360\n---\nxychart\n  title \"Stylesheet share of the combined payload\"\n  x-axis [r1, r2, r3, r4, r5, r6]\n  y-axis \"Share (%)\" 0 --> 60\n  line [30, 34, 38, 44, 49, 52]</pre>"
    "      <table tabindex=\"0\">"
    "        <caption><span class=\"label\">Values behind the line</span>Share of the combined payload by release.<span class=\"byline\">Source: fixture data.</span></caption>"
    "        <thead><tr><th scope=\"col\">Release</th><th scope=\"col\" class=\"num\">Share</th></tr></thead>"
    "        <tbody>"
    "          <tr><td>Release 1</td><td class=\"num\">30%</td></tr><tr><td>Release 2</td><td class=\"num\">34%</td></tr><tr><td>Release 3</td><td class=\"num\">38%</td></tr><tr><td>Release 4</td><td class=\"num\">44%</td></tr><tr><td>Release 5</td><td class=\"num\">49%</td></tr><tr><td>Release 6</td><td class=\"num\">52%</td></tr>"
    "        </tbody>"
    "      </table>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"derived\">Stored and derived</h2>"
    "      <p>A dashed outline marks a node a system derives instead of stores, the way a dashed edge already marks a conceptual connection. State the convention once, in a legend node or in the sentence above the fence, and never as a label on each node. The dash is a <code>stroke-dasharray</code> in a <code>classDef</code> and carries no color, so one line serves both palettes.</p>"
    "      <pre class=\"mermaid\">flowchart LR\n  accTitle: Stored and derived nodes\n  accDescr: A changeset is stored in the metadata store, while its root tree is derived by the server and drawn with a dashed outline. A legend node states that a dashed outline means derived.\n  cs[Changeset] --> next[Parent changeset]\n  cs -.-> root[Root tree]:::derived\n  root --> tree[Tree src]:::derived\n  cs --> blob[File contents]\n  key[Dashed: derived]:::derived\n  classDef derived stroke-dasharray:6 4</pre>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"more\">More diagram types</h2>"
    "      <p>Twelve more Mermaid fences, each rendered against this palette and verified by <code>getComputedStyle</code> rather than by reading the exported SVG's own attributes, which can carry a stale literal hex even after CSS has already repainted it (see NOTES.md, Diagram types).</p>"
    "      <h3>Class diagram</h3>"
    "      <pre class=\"mermaid\">classDiagram\n  accTitle: Class diagram sample\n  accDescr: An Animal base class with a name and a sound, and a Dog subclass that inherits from it.\n  class Animal {\n    +String name\n    +makeSound()\n  }\n  class Dog\n  Animal <|-- Dog</pre>"
    "      <h3>State diagram</h3>"
    "      <pre class=\"mermaid\">stateDiagram-v2\n  accTitle: State diagram sample\n  accDescr: A job that starts idle, moves to running when started, and returns to idle when stopped.\n  [*] --> Idle\n  Idle --> Running: start\n  Running --> Idle: stop</pre>"
    "      <h3>Entity relationship diagram</h3>"
    "      <pre class=\"mermaid\">erDiagram\n  accTitle: Entity relationship diagram sample\n  accDescr: A customer who places zero or more orders.\n  CUSTOMER ||--o{ ORDER : places</pre>"
    "      <h3>Requirement diagram</h3>"
    "      <pre class=\"mermaid\">requirementDiagram\n  accTitle: Requirement diagram sample\n  accDescr: A high-risk requirement satisfied by a simulation element.\n  requirement req1 {\n    id: 1\n    text: the system shall log every request\n    risk: high\n    verifymethod: test\n  }\n  element sim {\n    type: simulation\n  }\n  sim - satisfies -> req1</pre>"
    "      <h3>Kanban board</h3>"
    "      <p>A kanban board: two tasks in a <code>Todo</code> column and one task in a <code>Done</code> column.</p>"
    "      <pre class=\"mermaid\">---\naccTitle: Kanban board sample\naccDescr: Two tasks in a Todo column and one task in a Done column.\n---\nkanban\n  Todo\n    task1[Write docs]\n    task2[Fix bug]\n  Done\n    task3[Ship it]</pre>"
    "      <h3>Radar chart</h3>"
    "      <pre class=\"mermaid\">radar-beta\n  accTitle: Radar chart sample\n  accDescr: One series scored across three axes.\n  axis a[\"Speed\"], b[\"Cost\"], c[\"Quality\"]\n  curve x[\"Current\"]{3,4,2}</pre>"
    "      <p>A radar chart asks a reader to compare areas and angles, which readers judge poorly, and the area changes with the order of the axes. Draw one only beside a table that states every value on every axis.</p>"
    "      <h3>Git graph</h3>"
    "      <pre class=\"mermaid\">gitGraph\n  accTitle: Git graph sample\n  accDescr: A develop branch committed once and merged back into main.\n  commit\n  branch develop\n  commit\n  checkout main\n  merge develop</pre>"
    "      <h3>Treemap</h3>"
    "      <pre class=\"mermaid\">treemap-beta\n  accTitle: Treemap sample\n  accDescr: Two categories under one root, each sized by its own value.\n  \"Root\"\n    \"A\": 10\n    \"B\": 20</pre>"
    "      <p>A treemap compares rectangle areas, which readers judge poorly. Draw one only beside a table of the same values, and prefer a bar chart for a ranking.</p>"
    "      <h3>Timeline</h3>"
    "      <p>Mermaid's own <code>timeline</code> keyword: unrelated to this template's <code>dl.timeline</code> component (see NOTES.md, Diagram types). Three release years, each naming the versions that shipped that year: 2024 shipped v1.20.0 and v1.30.0, 2025 shipped v1.40.0 and v1.47.0, and 2026 shipped v1.48.0.</p>"
    "      <pre class=\"mermaid\">---\naccTitle: Timeline diagram sample\naccDescr: Three release years plotted on Mermaid's own timeline diagram, each naming the versions that shipped that year.\n---\ntimeline\n  title Release history\n  2024 : v1.20.0 : v1.30.0\n  2025 : v1.40.0 : v1.47.0\n  2026 : v1.48.0</pre>"
    "      <h3>Gantt chart</h3>"
    "      <pre class=\"mermaid\">gantt\n  tickInterval 1day\n  accTitle: Gantt chart sample\n  accDescr: Two sequential tasks against a dated axis.\n  title Two-task schedule\n  dateFormat YYYY-MM-DD\n  section Phase\n  Task A :a1, 2026-01-01, 3d\n  Task B :after a1, 3d</pre>"
    "      <h3>Architecture diagram</h3>"
    "      <pre class=\"mermaid\">architecture-beta\n  accTitle: Architecture diagram sample\n  accDescr: A database and a server grouped inside one API boundary.\n  group api(cloud)[API]\n  service db(database)[Database] in api\n  service server(server)[Server] in api\n  db:L -- R:server</pre>"
    "      <h3>User journey</h3>"
    "      <p>Task and section fills theme from this palette. The actor band and the per-task mood face keep Mermaid's own fixed colors on purpose, because a mood face reads as a fixed emotional scale rather than a brand category (see NOTES.md, Diagram types).</p>"
    "      <pre class=\"mermaid\">journey\n  accTitle: User journey sample\n  accDescr: One day rated across two sections, Work and Home.\n  title My day\n  section Work\n    Code: 5: Me\n    Review: 3: Me\n  section Home\n    Relax: 4: Me</pre>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"which\">Which one</h2>"
    "      <p><strong>Reach for the bar chart first, and for a plain table before either.</strong> A bar ranks at a glance where an angle or an area is a coin toss by eye, and <strong>every value is in the markup as text</strong> whichever form you draw.</p>"
    "      <ul>"
    "        <li>Ranking or comparing magnitudes: bar chart.</li>"
    "        <li>A part-to-whole split: a bar chart whose bars are each share of the total, as in the first table above.</li>"
    "        <li>Five or more categories, two series, or a value a reader will want to read exactly: a table. The bar chart is a table, so this is the same answer twice.</li>"
    "        <li>A trend inside a table row or a sentence: a column sparkline, with the first and latest values as text beside it.</li>"
    "        <li>The same chart across several cases: small multiples on one shared scale.</li>"
    "        <li>A full time series: a Mermaid <code>xychart</code> fence with one <code>line</code> series, beside a table of its values.</li>"
    "      </ul>"
    "    </section>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}

def body [] {
  [
    # Mermaid click-to-zoom overlay target (id referenced by mermaid.js).
    "  <dialog class=\"mermaid-overlay\" id=\"mermaid-zoom\"></dialog>"
    "  <main>"
    "  <article>"
    "    <span class=\"kicker\">Living fixture</span>"
    "    <h1>Tufte-Dracula Component Sample</h1>"
    "    <p class=\"byline\">Living style fixture: every rule in tufte-dracula.css, mermaid.js and filter.js</p>"
    ""
    # Enough sibling links to wrap at 390px, because the v1.22.0 `nav > a + a`
    # separator is a border on the link, so a link that starts a wrapped line
    # carries a separator with nothing before it. That artefact is accepted and
    # recorded in NOTES.md; the fixture has to show it rather than hide it behind
    # a two-link nav. The second link is the current page, which takes the accent
    # bar in place of the hairline on the same edge.
    "    <nav>"
    "      <a href=\"#\">Requirements Register</a>"
    "      <a href=\"#\" aria-current=\"page\">Decision Log</a>"
    "      <a href=\"#\">Dependency Tracker</a>"
    "      <a href=\"#\">Spike Results</a>"
    "      <a href=\"#\">Findings</a>"
    "      <a href=\"#\">Reuse Candidates</a>"
    "      <a href=\"#\">Project Summary</a>"
    "    </nav>"
    ""
    # A floated note stack immediately before the index. Three margin notes in one
    # paragraph clear each other, so the stack is taller than its one-line paragraph
    # and extends into nav.toc. A float shortens the line boxes of a block, never its
    # box, so without `clear` on nav.toc its full-width ground paints under the notes.
    # NOTES.md, Progressive disclosure; script-probe.py asserts this geometry.
    "    <p>A note stack here spans the block that follows it.<label for=\"mn-2\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-2\" class=\"margin-toggle\"/><span class=\"marginnote\">The first margin note in the stack. It floats to the inline end, and the notes below it clear it.</span><label for=\"mn-3\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-3\" class=\"margin-toggle\"/><span class=\"marginnote\">A second margin note, clearing the first, so the pair stacks down the margin column.</span><label for=\"mn-4\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-4\" class=\"margin-toggle\"/><span class=\"marginnote\">A third note makes the stack taller than its one-line paragraph, which is the case the index has to clear.</span></p>"
    ""

    # nav.toc and details.deep shipped styled with no instance in v1.45.0, so no
    # mode render and no forced-colors sweep ever drew either one. See NOTES.md,
    # Progressive disclosure.
    "    <nav class=\"toc\" aria-labelledby=\"toc-label\">"
    "      <p class=\"toc-label\" id=\"toc-label\">On this page</p>"
    "      <ol>"
    "        <li><a href=\"#\">Headings and text</a></li>"
    "        <li><a href=\"#\">Lists and definition lists</a></li>"
    "        <li><a href=\"#\">Tables and the scroll region</a></li>"
    "        <li><a href=\"#\">Diagrams and the zoom overlay</a></li>"
    "        <li><a href=\"#\">Borrowed components</a></li>"
    "        <li><a href=\"#\">Appearance modes</a></li>"
    "      </ol>"
    "    </nav>"
    ""
    "    <section>"
    "      <h2 id=\"headings\">Headings &amp; text <a class=\"headerlink\" href=\"#headings\" aria-label=\"Permalink to this heading\">&#182;</a></h2>"
    "      <h3 id=\"third-level\">Third-level heading <a class=\"anchor\" href=\"#third-level\" aria-label=\"Permalink to this heading\">#</a></h3>"
    "      <h4>Fourth level: body size, label tier</h4>"
    "      <h5>Fifth level: body size, muted tier</h5>"
    "      <h6>Sixth level: muted and italic</h6>"
    "      <p><span class=\"newthought\">A new thought</span> opens in small-caps. Body copy is Source Serif 4 at weight 450, with <strong>strong (weight 600)</strong>, <em>emphasis (inherits its surroundings)</em>, an <a href=\"#\">internal hyperlink</a>, an <a href=\"https://example.com\">outbound link</a> carrying its marker, a source citation <code>src/theme/tokens.css:14</code>, and inline <code>code()</code>.</p>"
    "      <p>Status spans: <span class=\"verified\">verified</span>, <span class=\"unverified\">unverified</span>, <span class=\"correction\">correction</span>.</p>"
    "      <p>Annotation elements: <mark>a marked passage</mark> takes a translucent orange wash, and a shortcut renders as <kbd>Ctrl</kbd> <kbd>K</kbd>, a ringed chip distinct from inline <code>code()</code>.</p>"
    "      <p>Markdown inline output: <del>struck through</del> drops to the muted tier, <samp>program output</samp> takes the mono face without the code chip, an <abbr title=\"HyperText Markup Language\">HTML</abbr> abbreviation carries a dotted rule, and H<sub>2</sub>O sits beside 10<sup>3</sup> without opening the line. An emoji image <img class=\"emoji\" alt=\"&#128578;\" title=\":slightly_smiling_face:\" src=\"data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 16 16%22%3E%3Ccircle cx=%228%22 cy=%228%22 r=%227%22 fill=%22%23e6c84f%22/%3E%3Ccircle cx=%225.5%22 cy=%226.5%22 r=%221%22/%3E%3Ccircle cx=%2210.5%22 cy=%226.5%22 r=%221%22/%3E%3Cpath d=%22M5 10q3 2.5 6 0%22 fill=%22none%22 stroke=%22%23000%22/%3E%3C/svg%3E\"> sets at text size with no frame.</p>"
    "      <details class=\"deep\"><summary>Why weight 450 and not 400</summary><p>The webfont exists for the weight axis. A system serif ships 400 and 700 and nothing between, so nothing else renders the 450 that light-on-dark body copy wants.</p></details>"
    "      <p>A sidenote lives here.<label for=\"sn-1\" class=\"margin-toggle sidenote-number\"></label><input type=\"checkbox\" id=\"sn-1\" class=\"margin-toggle\"/><span class=\"sidenote\">This is a Tufte sidenote. It floats to the right margin and auto-numbers.</span> And a margin note follows.<label for=\"mn-1\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-1\" class=\"margin-toggle\"/><span class=\"marginnote\">A margin note carries no number.</span></p>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Code block</h2>"
    "      <pre tabindex=\"0\" role=\"region\" aria-label=\"Code block\"><code>def greet [name: string] {\n    print $\"hello ($name)\"\n}</code></pre>"
    "      <p>A highlighted block takes the same slot map the editor themes use: keywords pink, strings green, numbers orange, comments muted, functions link, types purple, fields label.</p>"
    "      <pre tabindex=\"0\" role=\"region\" aria-label=\"Highlighted code block\"><code class=\"language-csharp hljs\"><span class=\"hljs-comment\">// highlighter classes, not hand-written spans</span>\n<span class=\"hljs-keyword\">public</span> <span class=\"hljs-type\">Result</span> <span class=\"hljs-title hljs-function\">Parse</span>(<span class=\"hljs-type\">string</span> <span class=\"hljs-params\">source</span>) {\n    <span class=\"hljs-keyword\">var</span> <span class=\"hljs-variable\">count</span> = <span class=\"hljs-number\">42</span>;\n    <span class=\"hljs-keyword\">return</span> <span class=\"hljs-keyword\">new</span> <span class=\"hljs-type\">Result</span>(<span class=\"hljs-string\">\"ok\"</span>, <span class=\"hljs-variable\">count</span>);\n}</code></pre>"
    "      <p>An unhighlighted block that names its language is highlighted in the browser by <code>highlight.js</code>. Emit <code>pre &gt; code.language-python</code> and nothing else: the script skips a block that already carries <code>hljs</code> spans, and a block with no <code>language-</code> class stays plain.</p>"
    "      <pre tabindex=\"0\" role=\"region\" aria-label=\"Runtime-highlighted code block\"><code class=\"language-python\"># highlighted in the browser, not by the generator\ndef parse(source: str) -&gt; Result:\n    count = 42\n    return Result(\"ok\", total=count)</code></pre>"
    "      <p>Pygments names the same slots one and two letters, so Sphinx, MkDocs, Quarto and a notebook export land in the same registers.</p>"
    "      <div class=\"highlight\"><pre tabindex=\"0\" role=\"region\" aria-label=\"Pygments code block\"><span class=\"c1\"># pygments classes, not hand-written spans</span>\n<span class=\"k\">def</span> <span class=\"nf\">parse</span><span class=\"p\">(</span><span class=\"n\">source</span><span class=\"p\">:</span> <span class=\"kt\">str</span><span class=\"p\">)</span> <span class=\"o\">-&gt;</span> <span class=\"nc\">Result</span><span class=\"p\">:</span>\n    <span class=\"n\">count</span> <span class=\"o\">=</span> <span class=\"mi\">42</span>\n    <span class=\"k\">return</span> <span class=\"nc\">Result</span><span class=\"p\">(</span><span class=\"s2\">&quot;ok&quot;</span><span class=\"p\">,</span> <span class=\"na\">total</span><span class=\"o\">=</span><span class=\"n\">count</span><span class=\"p\">)</span></pre></div>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Table</h2>"
    "      <table tabindex=\"0\">"
    "        <caption>Table caption: annotation register, start-aligned like every other block. An unwrapped table carries <code>tabindex</code>, because the escape hatch below 1000px hands it a sideways-scroll axis no keyboard could otherwise reach.</caption>"
    "        <thead><tr><th scope=\"col\">Column</th><th scope=\"col\" class=\"num\">Value</th><th scope=\"col\">Note</th></tr></thead>"
    "        <!-- mock: the figures exist to demonstrate tabular-nums alignment, not to state data -->"
    "        <tbody>"
    "          <tr><td>alpha</td><td class=\"num\">1234</td><td>no stripe, no fill</td></tr>"
    "          <tr><td>beta</td><td class=\"num\">567</td><td>figures align on the class, not the cell</td></tr>"
    "          <tr><td>gamma</td><td class=\"num\">9012</td><td>hover me</td></tr>"
    "        </tbody>"
    "      </table>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Tree table</h2>"
    "      <p>Depth comes from <code>data-depth</code> on the row, not from nesting. No <code>role</code>, no script.</p>"
    "      <table class=\"tree\" tabindex=\"0\">"
    "        <caption>Requirement tree: an unwrapped table, so it takes the sideways-scroll escape hatch below 1000px and carries <code>tabindex</code> to be reachable there.</caption>"
    "        <thead><tr><th scope=\"col\">Id</th><th scope=\"col\">Title</th><th scope=\"col\">State</th></tr></thead>"
    "        <tbody>"
    "          <tr data-depth=\"0\"><td>Epic 1</td><td>root row, tinted and bold</td><td>New</td></tr>"
    "          <tr data-depth=\"1\"><td>F1</td><td>child row, one indent step</td><td>Active</td></tr>"
    "          <tr data-depth=\"2\"><td>REQ-01</td><td>grandchild, muted</td><td>MVP</td></tr>"
    "          <tr data-depth=\"2\"><td>REQ-02</td><td>sibling, untinted like every leaf</td><td>MVP</td></tr>"
    "          <tr data-depth=\"1\"><td>F2</td><td>second child</td><td>New</td></tr>"
    "          <tr data-depth=\"0\"><td>Epic 2</td><td>second root</td><td>New</td></tr>"
    "        </tbody>"
    "      </table>"
    "    </section>"
    ""
    # The only `.table-scroll` instance in the repo, and it has to be BOTH wide and
    # tall or it verifies nothing. Eight columns push it past the body so the
    # wrapper scrolls sideways instead of the document; twenty-four rows push it
    # past the 70vh cap so the sticky `th` has something to pin against. A short
    # wrapped table renders identically to an unwrapped one and proves neither.
    # `role="region"` sits on the DIV, never on the table: on the table it
    # overrides `role="table"` and takes the row and column semantics with it.
    "    <section>"
    "      <h2>Wide table in a scroll wrapper</h2>"
    "      <p>A wide table wrapped in <code>.table-scroll</code> scrolls on both axes inside the wrapper, so the document never scrolls sideways, and the header stays pinned because the wrapper is the scrollport. The wrapper carries <code>tabindex=\"0\"</code>, <code>role=\"region\"</code> and a label. The table keeps its own row and column semantics, because the role sits on the wrapper and never on the table.</p>"
    "      <div class=\"table-scroll\" tabindex=\"0\" role=\"region\" aria-label=\"Quarterly totals by region\">"
    "        <table>"
    "          <caption>Twenty-four rows across eight columns: past the 70vh cap and past the body width at once.</caption>"
    "          <thead><tr><th scope=\"col\">Id</th><th scope=\"col\">Region</th><th scope=\"col\" class=\"num\">Q1</th><th scope=\"col\" class=\"num\">Q2</th><th scope=\"col\" class=\"num\">Q3</th><th scope=\"col\" class=\"num\">Q4</th><th scope=\"col\">Trend</th><th scope=\"col\">Note</th></tr></thead>"
    "          <!-- mock: the figures exist to give the wrapper something to scroll, not to state data -->"
    "          <tbody>"
    ...(1..24 | each {|i|
      let region = ([Northwest Southeast Midlands Coastal Interior "Upper Bay"] | get (($i - 1) mod 6))
      let trend = ([rising flat falling] | get (($i - 1) mod 3))
      # Row 2 carries the only focusable cell in any .table-scroll table, so a
      # keyboard user tabbing into it is what proves the sticky thead's
      # scroll-padding-top actually clears the focus ring, not just the math.
      let trend_cell = if $i == 2 { $"<a href=\"#\">($trend)</a>" } else { $trend }
      $"            <tr><td>R-($i)</td><td>($region)</td><td class=\"num\">($i * 137)</td><td class=\"num\">($i * 211)</td><td class=\"num\">($i * 89)</td><td class=\"num\">($i * 313)</td><td>($trend_cell)</td><td>Row ($i) of twenty-four, long enough that eight columns outrun the body</td></tr>"
    })
    "          </tbody>"
    "        </table>"
    "      </div>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Blockquote, aside, details</h2>"
    "      <blockquote><p><span lang=\"la\">Stat crux dum volvitur orbis.</span> The Cross stands while the world turns.</p></blockquote>"
    "      <blockquote class=\"pull\"><p>A <code>blockquote.pull</code> carries a large faint opening quote mark over the same accent bar. Opt-in, because the plain blockquote above is used too densely for citations to carry the glyph everywhere.</p></blockquote>"
    "      <aside>An aside: orange accent-bar, no fill. For asides and callouts. A <mark>marked passage inside the label tier</mark> keeps body-copy text, since the wash carries nothing dimmer.</aside>"
    "      <details><summary>Collapsible summary</summary><p>Hidden content revealed on click.</p></details>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Icon rows and a step chain</h2>"
    "      <p>A tag-dot marks a categorical value that already has a color elsewhere, never a rank. The class carries only the dot, never the label, because it paints <code>currentColor</code> and would otherwise recolor the text beside it: <span class=\"tag-dot\" style=\"color: var(--data-1)\"></span>Rust, <span class=\"tag-dot\" style=\"color: var(--data-3)\"></span>Go, <span class=\"tag-dot\" style=\"color: var(--data-2)\"></span>Python. A live-dot is the sheet's first animation, two beats and then still, because a loop that never ends owes the reader a way to stop it: <span class=\"live-dot\"></span> streaming.</p>"
    "      <ul class=\"icon-list\" role=\"list\">"
    "        <li style=\"--icon-color: var(--orange)\"><span class=\"icon-chip\" aria-hidden=\"true\">I</span><div><strong>Implement</strong><code>implement the functionality</code></div></li>"
    "        <li style=\"--icon-color: var(--link)\"><span class=\"icon-chip\" aria-hidden=\"true\">I</span><div><strong>Identify</strong><code>identify the bottleneck</code></div></li>"
    "        <li style=\"--icon-color: var(--green)\"><span class=\"icon-chip\" aria-hidden=\"true\">V</span><div><strong>Validate</strong><code>verify behavioral correctness</code></div></li>"
    "      </ul>"
    "      <p>A step chain is for a flow too trivial to justify a Mermaid diagram. A graph with a branch or a loop still belongs in <code>pre.mermaid</code>. Its <code>--icon-color</code> takes a prose accent, never a <code>--data-*</code> slot: the node fills at full strength and the letter is <code>--surface</code> on top of it, so a ramp scoped to the 3:1 diagram floor lands that pair at 3.5:1 in light mode. A <code>.tag-dot</code> or an <code>.icon-chip</code> may still carry a <code>--data-*</code> color, because neither puts text on the fill. The chain below runs Specify, Implement, Optimize, Verify, one letter to a node. A node is a circle with room for one character, so the words belong in the sentence that introduces the chain, the way this one does. Each <code>.step-arrow</code> is <code>aria-hidden</code>, because a screen reader otherwise reads the glyph between every pair of steps.</p>"
    "      <div class=\"step-chain\">"
    "        <span class=\"step-node\" style=\"--icon-color: var(--orange)\">S</span>"
    "        <span class=\"step-hop\"><span class=\"step-arrow\" aria-hidden=\"true\">&rarr;</span><span class=\"step-node\" style=\"--icon-color: var(--link)\">I</span></span>"
    "        <span class=\"step-hop\"><span class=\"step-arrow\" aria-hidden=\"true\">&rarr;</span><span class=\"step-node\" style=\"--icon-color: var(--purple)\">O</span></span>"
    "        <span class=\"step-hop\"><span class=\"step-arrow\" aria-hidden=\"true\">&rarr;</span><span class=\"step-node\" style=\"--icon-color: var(--green)\">V</span></span>"
    "      </div>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Layer stack and coverage matrix</h2>"
    "      <p>A layer stack draws a path that a request crosses in order. Each <code>li.layer</code> holds a name, a caption, and one or more <code>.layer-card</code> children. A dashed <code>.optional</code> card says so in its text, because a dashed border alone fails in forced-colors mode. The CSS draws the arrow between layers, and <code>.layer-end</code> inverts the last one.</p>"
    "      <ol class=\"layer-stack\" role=\"list\">"
    "        <li class=\"layer\"><div class=\"layer-name\"><strong>On the network</strong><span>the company web security service</span></div><div class=\"layer-cards\"><div class=\"layer-card\"><strong>Network check</strong><span>Stops requests (in the path)</span></div></div></li>"
    "        <li class=\"layer\"><div class=\"layer-name\"><strong>In the app</strong><span>the software that sends the request</span></div><div class=\"layer-cards\"><div class=\"layer-card\"><strong>Platform hook</strong><span>Stops requests (in the path)</span></div><div class=\"layer-card optional\"><strong>Check the app calls</strong><span>Optional. Gives an answer; the app decides</span></div></div></li>"
    "        <li class=\"layer layer-end\"><div class=\"layer-name\"><strong>The AI model</strong><span>reads the request and answers</span></div></li>"
    "      </ol>"
    "      <p>A coverage matrix is a <code>table.matrix</code> in a <code>.table-scroll</code> wrapper. Each cell holds a dot and a count, or a muted <code>&middot;</code> when none is documented. The first column stays pinned while the rest scrolls. The count is never summed across a row.</p>"
    "      <div class=\"table-scroll\" tabindex=\"0\" role=\"region\" aria-label=\"Checks that reach each kind of AI\">"
    "        <table class=\"matrix\">"
    "          <thead><tr><th>Kind of AI</th><th>Admission gate</th><th>Browser extension</th><th>Endpoint agent</th><th>AI gateway</th><th>Response after detection</th></tr></thead>"
    "          <tbody>"
    "            <tr><th scope=\"row\">Cloud AI services</th><td><span class=\"tag-dot\"></span>6</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td></tr>"
    "            <tr><th scope=\"row\">Self-hosted models</th><td><span class=\"tag-dot\"></span>6</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td><td><span class=\"tag-dot\"></span>13</td><td class=\"none\">&middot;</td></tr>"
    "            <tr><th scope=\"row\">Coding assistants</th><td class=\"none\">&middot;</td><td><span class=\"tag-dot\"></span>3</td><td><span class=\"tag-dot\"></span>6</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td></tr>"
    "            <tr><th scope=\"row\">Agents on platforms</th><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td><td class=\"none\">&middot;</td><td><span class=\"tag-dot\"></span>2</td></tr>"
    "          </tbody>"
    "        </table>"
    "      </div>"
    ""
    "      <p>A heatmap is a <code>table.heatmap</code> in a <code>.table-scroll</code> wrapper. A <code>span.hm</code> is one square. <code>full</code> fills it, <code>part</code> fills the lower part, <code>hatch</code> stripes it, and <code>ring</code> outlines it, so no state rests on color alone. Column headers read bottom to top, and a band row above them names each group. A score cell draws a bar under its number. A row never sums its squares.</p>"
    "      <div class=\"table-scroll\" tabindex=\"0\" role=\"region\" aria-label=\"Coverage heatmap by kind of AI\">"
    "        <table class=\"heatmap\">"
    "          <thead>"
    "            <tr><th rowspan=\"2\">Kind of AI</th><th rowspan=\"2\">Score</th><th class=\"band\" colspan=\"3\">On the device</th><th class=\"band\" colspan=\"2\">Existing tool</th><th class=\"band\" colspan=\"3\">Off the device</th></tr>"
    "            <tr><th class=\"col\"><span>EDR sensor</span></th><th class=\"col\"><span>IDE plugin</span></th><th class=\"col\"><span>Browser extension</span></th><th class=\"col\"><span>Existing EDR data</span></th><th class=\"col\"><span>Telemetry export</span></th><th class=\"col\"><span>Network or DNS</span></th><th class=\"col\"><span>Platform APIs</span></th><th class=\"col\"><span>Audit logs</span></th></tr>"
    "          </thead>"
    "          <tbody>"
    "            <tr><th colspan=\"10\">Top group</th></tr>"
    "            <tr><th scope=\"row\">Agents on platforms</th><td class=\"score\" style=\"--bar: 75.0%\">75.0</td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm hatch\"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm full\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm full\"></span></td></tr>"
    "            <tr><th scope=\"row\">Remote MCP servers</th><td class=\"score\" style=\"--bar: 71.7%\">71.7</td><td><span class=\"hm part\"></span></td><td><span class=\"hm hatch\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm full\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm part\"></span></td></tr>"
    "            <tr><th colspan=\"10\">Next</th></tr>"
    "            <tr><th scope=\"row\">Cloud AI services</th><td class=\"score\" style=\"--bar: 68.3%\">68.3</td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm full\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm part\"></span></td></tr>"
    "            <tr><th scope=\"row\">Self-hosted models</th><td class=\"score\" style=\"--bar: 66.7%\">66.7</td><td><span class=\"hm ring\"></span></td><td><span class=\"hm part\"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm full\"></span></td><td><span class=\"hm full\"></span></td><td><span class=\"hm full\"></span></td><td><span class=\"hm \"></span></td><td><span class=\"hm \"></span></td></tr>"
    "          </tbody>"
    "        </table>"
    "      </div>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Lists &amp; definitions</h2>"
    "      <ul><li>Bullet one, muted marker</li><li>Bullet two<ul><li>nested item</li></ul></li></ul>"
    "      <ol><li>Ordered one</li><li>Ordered two</li></ol>"
    "      <dl><dt>Term</dt><dd>Definition of the term.</dd><dt>Another</dt><dd>Its definition.</dd></dl>"
    "      <p>A task list drops its marker and keeps the checkbox. Markdown emits the control disabled, so it stays read-only.</p>"
    "      <ul class=\"contains-task-list\">"
    "        <li class=\"task-list-item\"><input type=\"checkbox\" disabled> open item</li>"
    "        <li class=\"task-list-item\"><input type=\"checkbox\" checked disabled> done item</li>"
    "      </ul>"
    "    </section>"
    ""
    # Timeline entries deliberately mix a `c.` prefix, a range and a bare year,
    # because right-aligned tabular figures are the only reason those three line
    # up. A fixture with three bare years would pass while the alignment was
    # broken. The third entry states the sidenote-in-a-grid-item trap in copy, so
    # a consumer reading the fixture hits it before their generator does.
    "    <section>"
    "      <h2>Timeline</h2>"
    "      <p>A <code>dl</code> carrying <code>class=\"timeline\"</code> becomes a two-column date spine: dates right-aligned on tabular figures, entries against a hairline. The date column is <code>max-content</code>, so the longest label sets the width for every row. Below 600px it collapses to one column and drops the rule.</p>"
    # `:target` cannot be captured by a static fixture or by mode-renders, since
    # it needs a URL fragment. The ids and the two links below are the only way a
    # human can walk that state, so they are load-bearing, not decoration.
    "      <p>Deep links carry an arrival cue: jump to <a href=\"#e-802\">the 802 entry</a> or to <a href=\"#fn-1\">footnote 1</a> and the destination takes an orange outline, distinct from the link-blue focus ring, and lands clear of the viewport edge.</p>"
    "      <dl class=\"timeline\">"
    "        <dt id=\"e-802\">c. 802</dt>"
    "        <dd><strong>An approximate year.</strong> Entry text sits at the primary tier, not the caption tier a plain <code>dd</code> takes, because a timeline entry is the content rather than an annotation.<sup class=\"footnote-ref\"><a href=\"#fn-1\">1</a></sup></dd>"
    "        <dt id=\"e-928\">928-944</dt>"
    "        <dd><strong>A range.</strong> The widest label in the column, so it sets the date width. Its digits still align with the rows above and below.</dd>"
    "        <dt id=\"e-1431\"><time datetime=\"1431\">1431</time></dt>"
    "        <dd><strong>A single year.</strong> Cite with a <code>sup</code> link into the sources list, never a floated <code>.sidenote</code>: a float cannot escape a grid item, so the note would land inside this column instead of the page margin.</dd>"
    "      </dl>"
    # Two lists under one axis is the case max-content cannot serve, because each
    # list sizes its own track and the spine then steps left down the page. Both
    # groups below carry `--timeline-date`, and the shorter labels in the second
    # one are the proof: it holds the wide column instead of shrinking to fit.
    "      <p>Era groups are separate lists, so <code>max-content</code> would give each one its own date width and step the spine left down the page. Setting <code>--timeline-date</code> on an ancestor pins one axis across all of them.</p>"
    "      <div style=\"--timeline-date: 11ch\">"
    "        <h3>First era</h3>"
    "        <dl class=\"timeline\">"
    "          <dt>c. 1182-1201</dt><dd>The widest label in the document. It fits the pinned width exactly.</dd>"
    "        </dl>"
    "        <h3>Second era</h3>"
    "        <dl class=\"timeline\">"
    "          <dt>1431</dt><dd>Short labels, same axis. Without the pin this rule would sit further left than the one above it.</dd>"
    "          <dt>1992</dt><dd>Second row, to show the spine is continuous within a group.</dd>"
    "        </dl>"
    "      </div>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Markdown callouts, math &amp; footnotes</h2>"
    "      <p>GitHub alert blocks share the <code>aside</code> form (one accent bar, no fill) and carry the hue on the title line only.<sup class=\"footnote-ref\"><a href=\"#fn-1\" id=\"fnref-1\">1</a></sup></p>"
    "      <div class=\"markdown-alert markdown-alert-note\"><p class=\"markdown-alert-title\">Note</p><p>Link-blue bar. Neutral information.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-tip\"><p class=\"markdown-alert-title\">Tip</p><p>Green bar. Optional advice.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-important\"><p class=\"markdown-alert-title\">Important</p><p>Purple bar. Do not skip this.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-warning\"><p class=\"markdown-alert-title\">Warning</p><p>Orange bar, the same hue the plain aside takes.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-caution\"><p class=\"markdown-alert-title\">Caution</p><p>Red bar. Risk of loss or breakage.</p></div>"
    "      <table tabindex=\"0\">"
    "        <caption>Pipe-table alignment: a converter emits no caption, so this one is the fixture's own, and it is what names the tab stop the escape hatch requires.</caption>"
    "        <thead><tr><th align=\"left\">Alignment</th><th align=\"center\">from the</th><th align=\"right\">pipe table</th></tr></thead>"
    "        <tbody><tr><td align=\"left\">start</td><td align=\"center\">center</td><td align=\"right\">3.14159</td></tr></tbody>"
    "      </table>"
    "      <p>Math converted to MathML needs no script and no CDN: <math><mi>E</mi><mo>=</mo><mi>m</mi><msup><mi>c</mi><mn>2</mn></msup></math> sets inline without opening the line box, and a display block scrolls on its own axis rather than widening the page.</p>"
    "      <math display=\"block\" tabindex=\"0\" role=\"region\" aria-label=\"Display equation: the sum from n equals 1 to infinity of 1 over n squared equals pi squared over 6\"><mrow><munderover><mo>&sum;</mo><mrow><mi>n</mi><mo>=</mo><mn>1</mn></mrow><mi>&infin;</mi></munderover><mfrac><mn>1</mn><msup><mi>n</mi><mn>2</mn></msup></mfrac><mo>=</mo><mfrac><msup><mi>&pi;</mi><mn>2</mn></msup><mn>6</mn></mfrac></mrow></math>"
    "      <p>Pandoc&#8217;s MathJax output is a <code>span.math.display</code> instead. It scrolls the same way, and CSS cannot give it a tab stop, so it takes the same three attributes.</p>"
    "      <span class=\"math display\" tabindex=\"0\" role=\"region\" aria-label=\"Display equation: the sum from n equals 1 to infinity of 1 over n squared equals pi squared over 6\">\\[\\sum_{n=1}^{\\infty} \\frac{1}{n^2} = \\frac{\\pi^2}{6}\\]</span>"
    "      <section class=\"footnotes\" data-footnotes>"
    "        <ol><li id=\"fn-1\"><p>The footnote block sits behind a hairline at the caption tier, tightened to the annotation register. <a href=\"#fnref-1\" class=\"footnote-backref\" aria-label=\"Back to reference 1\">&#8617;</a></p></li></ol>"
    "      </section>"
    "    </section>"
    ""
    "    <section class=\"indented\">"
    "      <h2>Indented paragraphs (opt-in)</h2>"
    "      <p>A container carrying <code>class=\"indented\"</code> sets its paragraphs the way a book does: no gap between them, and every paragraph after the first opens with a 1.5em indent. The first paragraph is never indented, because nothing precedes it to break from.</p>"
    "      <p>This paragraph is the second, so it indents. The break is carried by the indent rather than by white space, which is the convention the rest of the page deliberately does not use. The default remains spaced paragraphs with no indent, and this class is the only way to get the other one.</p>"
    "      <p>Lists keep their own margin here, as they do everywhere else, so they do not butt against the paragraph above even though the paragraphs themselves carry none.</p>"
    "      <ul><li>A list inside the indented container</li><li>Second item</li></ul>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Proof-test scorecard</h2>"
    "      <div class=\"scorecard\">"
    "        <span class=\"sc-label\">P1 Observability</span><span class=\"verdict verdict-pass\">Pass</span><span class=\"sc-note\">directly measured</span>"
    "        <span class=\"sc-label\">P2 Mechanism</span><span class=\"verdict verdict-partial\">Partial</span><span class=\"sc-note\">surrogate endpoint</span>"
    "        <span class=\"sc-label\">P3 Prediction</span><span class=\"verdict verdict-failed\">Failed</span><span class=\"sc-note\">model output, not measurement</span>"
    "        <span class=\"sc-label\">P4 Coherence of the profile the method inherits</span><span class=\"verdict verdict-neutral\">N/A</span><span class=\"sc-note\">not assessed</span>"
    "        <span class=\"sc-full\">Full verdict spans all three columns for a summary line.</span>"
    "      </div>"
    "      <p>A longer graded list takes a real <code>table</code> instead of <code>.scorecard</code>. A row that rolls up sub-rows rather than carrying its own verdict, method 1 below, still gets a <code>.verdict verdict-neutral</code> badge reading <code>See below</code>, never bare punctuation: a badge next to every other row's badge is what makes the rollup read as deliberate instead of as a rendering gap.</p>"
    "      <table tabindex=\"0\">"
    "        <caption>Proof-test scorecard, table form</caption>"
    "        <thead><tr><th scope=\"col\">#</th><th scope=\"col\">Method</th><th scope=\"col\">Verdict</th><th scope=\"col\">Bearing</th></tr></thead>"
    "        <tbody>"
    "          <tr><td>1</td><td>Five principles</td><td><span class=\"verdict verdict-neutral\">See below</span></td><td>see P1-P2</td></tr>"
    "          <tr><td></td><td>&middot; P1 Observability</td><td><span class=\"verdict verdict-pass\">Pass</span></td><td>directly measured</td></tr>"
    "          <tr><td></td><td>&middot; P2 Mechanism</td><td><span class=\"verdict verdict-partial\">Partial</span></td><td>surrogate endpoint</td></tr>"
    "          <tr><td>2</td><td>Charge gate</td><td><span class=\"verdict verdict-neutral\">N/A</span></td><td>not assessed</td></tr>"
    "        </tbody>"
    "        <tfoot><tr><td></td><td>Summary</td><td>1 Pass, 1 Partial</td><td>1 not assessed</td></tr></tfoot>"
    "      </table>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Navigation index components</h2>"
    "      <label class=\"filter-label\" for=\"nav-filter\">Filter entries</label>"
    "      <input id=\"nav-filter\" type=\"search\" class=\"filter-box\" autocomplete=\"off\" placeholder=\"Failed audit\"/>"
    "      <p role=\"status\">4 entries</p>"
    "      <ul class=\"nav-list\" role=\"list\">"
    "        <li><a href=\"#\">A tappable nav-list link</a></li>"
    "        <li><a href=\"#\">Another entry <span class=\"badge badge-t1\">Tier 1</span></a></li>"
    "        <li><a href=\"#\">Failed audit <span class=\"badge badge-t3\">Tier 3</span></a></li>"
    "      </ul>"
    "      <p class=\"filter-empty\" hidden>No entries match. Clear the filter to see all entries.</p>"
    "      <details class=\"nav-group\" open><summary>Subfolder group <span class=\"count\">1</span></summary>"
    "        <ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">grouped item <span class=\"badge badge-t2\">Tier 2</span></a></li></ul>"
    "      </details>"
    "    </section>"
    ""

    # The shell holds the rail and the entries as two columns above 900px and one
    # below it. The filter box deliberately stays out of the rail: filter.js scopes
    # a filter to the siblings that follow its input, so a box moved into the rail
    # would find no rows and go inert. See NOTES.md, The index shell.
    "    <section>"
    "      <h2>The index shell</h2>"
    "      <div class=\"index-shell\">"
    "        <nav class=\"index-rail\" aria-labelledby=\"rail-label\">"
    "          <p id=\"rail-label\">Sections</p>"
    "          <ul class=\"nav-list\" role=\"list\">"
    "            <li><a href=\"#\">Antecedents</a></li>"
    "            <li><a href=\"#\">Decision log</a></li>"
    "            <li><a href=\"#\">Dependency tracker</a></li>"
    "            <li><a href=\"#\">Findings</a></li>"
    "          </ul>"
    "        </nav>"
    "        <div>"
    "          <ul class=\"nav-list\" role=\"list\">"
    "            <li><a href=\"#\">A long entry list scrolls past the rail <span class=\"badge badge-t1\">Tier 1</span></a></li>"
    "            <li><a href=\"#\">Antecedent records for the charge gate</a></li>"
    "            <li><a href=\"#\">Antecedent records for the release gate</a></li>"
    "            <li><a href=\"#\">Decision log, first quarter <span class=\"count\">12</span></a></li>"
    "            <li><a href=\"#\">Decision log, second quarter <span class=\"count\">9</span></a></li>"
    "            <li><a href=\"#\">Dependency tracker, open items</a></li>"
    "            <li><a href=\"#\">Findings from the load test</a></li>"
    "            <li><a href=\"#\">Findings from the recovery drill</a></li>"
    "            <li><a href=\"#\">Failed audit <span class=\"badge badge-t3\">Tier 3</span></a></li>"
    "            <li><a href=\"#\">Reuse candidates for the index rail</a></li>"
    "            <li><a href=\"#\">Spike results, storage tier</a></li>"
    "            <li><a href=\"#\">Spike results, message bus</a></li>"
    "          </ul>"
    "        </div>"
    "      </div>"
    "    </section>"
    ""

    # A card, not an overlay: the caption sits on --surface-alt, which every text
    # token already clears, so the tile needs no scrim and no new colour.
    "    <section>"
    "      <h2>Image hero tile</h2>"
    "      <figure class=\"hero\">"
    "        <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 840 360'%3E%3Crect width='840' height='360' fill='%233a3d52'/%3E%3Cpath d='M0 300 L240 160 L430 260 L640 120 L840 280 L840 360 L0 360 Z' fill='%238a8fb0'/%3E%3Ccircle cx='690' cy='96' r='46' fill='%23bd93f9'/%3E%3C/svg%3E\" alt=\"A wide banner illustration: layered purple hills under a single bright disc.\" />"
    "        <figcaption>"
    "          <span class=\"label\">Template component</span>"
    "          <h3>An image tile with a headline and one call to action</h3>"
    "          <p>The image reserves its box through <code>aspect-ratio</code>, so nothing below it moves when the file arrives.</p>"
    "          <a href=\"#headings\">See the headings and text section</a>"
    "        </figcaption>"
    "      </figure>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Connections edge-list</h2>"
    "      <div class=\"edge-list\">"
    "        <div><h3>Antecedents</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">prior node one</a></li><li><a href=\"#\">prior node two</a></li></ul></div>"
    "        <div><h3>Descendants</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">later node one</a></li></ul></div>"
    "      </div>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Recently updated, by category</h2>"
    "      <div class=\"recent-groups\">"
    "        <div class=\"recent-group\"><h3>Category A</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item One\">Item One</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"View all 12: Category A\">View all 12 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "        <div class=\"recent-group\"><h3>Category B</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item Two\">Item Two</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"View all 533: Category B\">View all 533 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "        <div class=\"recent-group\"><h3>Category C</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item Three\">Item Three</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"View all 36: Category C\">View all 36 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "        <div class=\"recent-group\"><h3>Other</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item Four\">Item Four</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"View all 1689: Other\">View all 1689 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "      </div>"
    "    </section>"
    ""
    "    <section class=\"col-2\">"
    "      <h2>Two-column citation list</h2>"
    "      <ol><li>First source, flows into balanced columns on wide screens.</li><li>Second source.</li><li>Third source.</li><li>Fourth source.</li></ol>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Mermaid diagram (click to zoom)</h2>"
    "      <figure>"
    "      <pre class=\"mermaid\">flowchart TD\n  accTitle: Decision flow sample\n  accDescr: Start leads to a decision; yes does the thing, no skips it, and both reach done.\n  A[Start] --> B{Decision}\n  B -->|yes| C[Do the thing]\n  B -->|no| D[Skip it]\n  C --> E[Done]\n  D --> E</pre>"
    "      <figcaption><span class=\"label\">Caption tiers</span>A figure caption sits in the annotation register and stays start-aligned under a centred diagram.<span class=\"byline\">Source: the flowchart above, rendered at the template's pinned Mermaid version.</span></figcaption>"
    "      </figure>"
    "      <pre class=\"mermaid\">sequenceDiagram\n  accTitle: Sequence diagram sample\n  accDescr: The caller sends a request, the service stores it, and a note records that a label box must fit its own monospace text.\n  participant C as Caller\n  participant S as Service (long name)\n  C->>S: Request with a fairly long label\n  S->>S: Store it\n  Note over S: This note is wider than the actor box.<br/>Its rect must contain the rendered text.\n  S->>C: Result</pre>"
    "      <pre class=\"mermaid\">quadrantChart\n  accTitle: Quadrant chart sample\n  accDescr: Four labelled points near the chart edges, where long labels would otherwise be clipped by the fixed chart viewBox.\n  x-axis Narrow --> Wide\n  y-axis Shallow --> Deep\n  quadrant-1 Best of both\n  quadrant-2 Deep but narrow\n  quadrant-3 Neither yet\n  quadrant-4 Wide but shallow\n  A label long enough to reach past the edge: [0.9, 0.9]\n  Another deliberately overlong point label: [0.1, 0.1]</pre>"
    "      <pre class=\"mermaid\">packet-beta\n  accTitle: Packet diagram sample\n  accDescr: A UDP header split into four labelled byte ranges, styled through tufte-dracula.css because mermaid's own packet themeVariables are a documented no-op.\n  title UDP Header\n  0-15: \"Source Port\"\n  16-31: \"Destination Port\"\n  32-47: \"Length\"\n  48-63: \"Checksum\"</pre>"
    "      <pre class=\"mermaid\">usecase-beta\n  accTitle: Use case diagram sample\n  accDescr: A reader actor reaching a system boundary that groups a use case and the diagram zoom it includes.\n  direction LR\n  actor Reader\n  systemBoundary Site\n    Read(\"Read page\")\n    Zoom(\"Zoom diagram\")\n  end\n  Reader --> Read\n  Read ..> : include Zoom</pre>"
    "    </section>"
    ""
    "    <hr/>"
    "    <footer>Footer text, muted and small. Generated by scripts/build-sample.nu.</footer>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}

# Timeline layout: real content rather than three synthetic rows, because the
# component's two hard parts only appear at length. Four era groups are four
# separate `dl.timeline` lists, which is the case `max-content` cannot serve and
# `--timeline-date` exists for; and 54 citation markers against 15 sources is the
# density that made the sidenote form fail. Every `dt` carries an id, so the
# `:target` outline is walkable here.
#
# Entries run chronologically by START date, which is why Bayon `c. 1182-1201`
# precedes Ta Prohm `1186` here and follows Preah Khan `1191` in the source
# scroll. Do not restore the source order: once the dates form a scannable
# column, a row out of sequence reads as a bug in the component.
#
# Source content: e128.info research scroll `lode/research/timelines/khmer-civilization.md`.
def timeline-body [] {
  [
    "  <dialog class=\"mermaid-overlay\" id=\"mermaid-zoom\"></dialog>"
    "  <main>"
    "  <article style=\"--timeline-date: 16ch\">"
    "    <h1>Khmer Civilization Timeline</h1>"
    "    <p class=\"byline\">Real-content layout sample: dl.timeline across four era groups on one pinned axis</p>"
    ""
    "    <nav>"
    "      <a href=\"#pre-angkor\">Pre-Angkor</a>"
    "      <a href=\"#angkor\">Angkor period</a>"
    "      <a href=\"#post-angkor\">Post-Angkor</a>"
    "      <a href=\"#survey\">Rediscovery and survey</a>"
    "      <a href=\"#sources\">Sources</a>"
    "    </nav>"
    ""
    "    <section>"
    "      <h2 id=\"pre-angkor\">Pre-Angkor</h2>"
    "      <p class=\"byline\">Funan and Chenla, before the Angkor period</p>"
    "      <dl class=\"timeline\">"
    "        <dt id=\"e-funan\">c. 1st century CE</dt>"
    "        <dd><strong>Funan polity emerges in the Mekong Delta.</strong> First Hinduized kingdom of Southeast Asia. Maritime entrepots like Oc Eo traded with India, China, and Rome. Chinese annals record it from the 3rd century. <em>Contested:</em> Vickery argues Funan was a group of coastal polities, not a unified empire.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-9\">9</a>, <a href=\"#src-10\">10</a></sup></dd>"
    "        <dt id=\"e-chenla\">c. 6th century CE</dt>"
    "        <dd><strong>Chenla emerges and succeeds Funan.</strong> Centered on the middle Mekong and Tonle Sap. Sambor Prei Kuk (Isanapura) was its 7th-century capital and the prototype for Angkor. <em>Contested:</em> The transition was likely gradual, not a conquest.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-9\">9</a>, <a href=\"#src-10\">10</a></sup></dd>"
    "      </dl>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"angkor\">Angkor period</h2>"
    "      <p class=\"byline\">802 to 1431, capital on the Angkor plain</p>"
    "      <dl class=\"timeline\">"
    "        <dt id=\"e-802\">c. 802</dt>"
    "        <dd><strong>Jayavarman II declares himself universal king on Mount Kulen, founds Mahendraparvata.</strong> Traditional founding of the Khmer Empire and start of the Angkor period. Lidar rediscovered Mahendraparvata in 2012. <em>Contested:</em> Coe's lecture conflates the 802 founding with Yasovarman's later Yasodharapura.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-5\">5</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-7\">7</a></sup></dd>"
    "        <dt id=\"e-889\">c. 889</dt>"
    "        <dd><strong>Royal capital moves south to Angkor; Yasovarman I founds Yasodharapura.</strong> The capital relocates from the Kulen hills to the Angkor plain. <em>Contested:</em> The founding date and founder are contested across sources.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-7\">7</a></sup></dd>"
    "        <dt id=\"e-koh-ker\">928-944</dt>"
    "        <dd><strong>Koh Ker interregnum: Jayavarman IV rules from a new capital.</strong> A 17-year interval when power left Angkor. Prasat Thom pyramid built in 942. The reservoir embankment failed within a decade, possibly driving the court back.<sup class=\"footnote-ref\"><a href=\"#src-4\">4</a></sup></dd>"
    "        <dt id=\"e-1000\">c. 1000</dt>"
    "        <dd><strong>Angkor becomes one of the largest cities in the world.</strong> Estimates run from ~500,000 (Ancient Code) to ~900,000 (Evans) people in a low-density sprawl of ~1,000 sq km.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-7\">7</a></sup></dd>"
    "        <dt id=\"e-angkor-wat\">1113-1150</dt>"
    "        <dd><strong>Suryavarman II reigns; Angkor Wat is built.</strong> The largest religious structure on Earth, dedicated to Vishnu.<sup class=\"footnote-ref\"><a href=\"#src-1\">1</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-7\">7</a>, <a href=\"#src-11\">11</a></sup></dd>"
    "        <dt id=\"e-cham-sack\"><time datetime=\"1177\">1177</time></dt>"
    "        <dd><strong>Chams sack Angkor.</strong> The hereditary enemies conquered the city before Jayavarman VII took the throne. The battles appear in Bayon reliefs.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-12\">12</a></sup></dd>"
    "        <dt id=\"e-jayavarman-vii\"><time datetime=\"1181\">1181</time></dt>"
    "        <dd><strong>Jayavarman VII is crowned king.</strong> First Khmer king devoted to Mahayana Buddhism. Proclaimed the &ldquo;Living Buddha.&rdquo; Ousted the Chams and launched a massive building program.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-12\">12</a></sup></dd>"
    "        <dt id=\"e-bayon\">c. 1182-1201</dt>"
    "        <dd><strong>Bayon built as the state temple of the new capital Angkor Thom.</strong> The Bayon has 54 towers and ~200 smiling faces (Lokesvara or Jayavarman VII). Its reliefs show daily life and the Cham wars.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-12\">12</a></sup></dd>"
    "        <dt id=\"e-ta-prohm\"><time datetime=\"1186\">1186</time></dt>"
    "        <dd><strong>Ta Prohm is founded.</strong> Mahayana monastery (Rajavihara) dedicated to Jayavarman VII's mother. Its stele records ~12,500 attached people. Now the &ldquo;Tomb Raider&rdquo; temple left in its jungle state. <em>Contested:</em> A carved roundel on one lintel is popularly read as a stegosaurus, a claim used to argue dinosaurs and humans coexisted; mainstream analysis identifies it as a rhinoceros or a decorative leaf motif.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-8\">8</a>, <a href=\"#src-12\">12</a></sup></dd>"
    "        <dt id=\"e-preah-khan\"><time datetime=\"1191\">1191</time></dt>"
    "        <dd><strong>Preah Khan is dedicated.</strong> Temple honoring Jayavarman VII's father. BBC reports it held 60 tons of gold, worth about &pound;2bn today.<sup class=\"footnote-ref\"><a href=\"#src-7\">7</a>, <a href=\"#src-12\">12</a></sup></dd>"
    "        <dt id=\"e-zhou-daguan\">c. 1296</dt>"
    "        <dd><strong>Zhou Daguan visits Angkor.</strong> The Chinese Yuan-dynasty diplomat writes &ldquo;Customs of Cambodia,&rdquo; the main eyewitness account of late-13th-century Angkor.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-5\">5</a></sup></dd>"
    "        <dt id=\"e-decline\">c. 1300-1431</dt>"
    "        <dd><strong>Gradual decline begins a century before the fall.</strong> Land use in central Angkor declined ~100 years before the traditional 1431 abandonment (Penny's moat cores). Water infrastructure failed; tree rings record extreme dry and wet swings. <em>Contested:</em> The &ldquo;collapse&rdquo; narrative against the century-in-the-making view.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-3\">3</a>, <a href=\"#src-7\">7</a></sup></dd>"
    "      </dl>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"post-angkor\">Post-Angkor</h2>"
    "      <p class=\"byline\">The court leaves, the temple does not empty</p>"
    "      <dl class=\"timeline\">"
    "        <dt id=\"e-1431\"><time datetime=\"1431\">1431</time></dt>"
    "        <dd><strong>Ayutthaya (Thai) sack of Angkor; court moves to Phnom Penh.</strong> Traditional date of the fall and start of the post-Angkor era. <em>Contested:</em> Carter's excavations show Angkor Wat was never abandoned. The landscape was reoccupied by the late 14th or early 15th century and used into the 17th-18th.<sup class=\"footnote-ref\"><a href=\"#src-1\">1</a>, <a href=\"#src-2\">2</a>, <a href=\"#src-3\">3</a>, <a href=\"#src-5\">5</a></sup></dd>"
    "        <dt id=\"e-japanese-inscriptions\">c. 1600s</dt>"
    "        <dd><strong>Japanese Buddhist inscriptions appear at Angkor Wat.</strong> Fourteen 17th-century inscriptions show Japanese Buddhists traveled to and settled alongside the Khmer. The temple remained in continuous use.<sup class=\"footnote-ref\"><a href=\"#src-1\">1</a></sup></dd>"
    "      </dl>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"survey\">Rediscovery and survey</h2>"
    "      <p class=\"byline\">Events in the study of Angkor, not in its history</p>"
    "      <dl class=\"timeline\">"
    "        <dt id=\"e-mouhot\"><time datetime=\"1860\">1860</time></dt>"
    "        <dd><strong>Henri Mouhot &ldquo;discovers&rdquo; Angkor.</strong> His posthumous journal (1863-64) introduced Angkor to the West. <em>Contested:</em> Angkor was never lost, local monks kept it. Mouhot arrived in 1858, and pre-Mouhot accounts already described the site.<sup class=\"footnote-ref\"><a href=\"#src-5\">5</a>, <a href=\"#src-7\">7</a>, <a href=\"#src-15\">15</a></sup></dd>"
    "        <dt id=\"e-unesco\"><time datetime=\"1992\">1992</time></dt>"
    "        <dd><strong>Angkor inscribed as a UNESCO World Heritage Site.</strong> Also placed on the Danger List, removed in 2004. The Angkor Archaeological Park now draws ~2 million visitors a year.<sup class=\"footnote-ref\"><a href=\"#src-6\">6</a>, <a href=\"#src-7\">7</a></sup></dd>"
    "        <dt id=\"e-lidar-1\"><time datetime=\"2012\">2012</time></dt>"
    "        <dd><strong>First lidar survey of Greater Angkor.</strong> The KALC airborne laser survey revealed the full urban grid, waterworks, and the lost city of Mahendraparvata. Results published in PNAS 2013.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-7\">7</a>, <a href=\"#src-13\">13</a></sup></dd>"
    "        <dt id=\"e-lidar-2\"><time datetime=\"2015\">2015</time></dt>"
    "        <dd><strong>Second lidar survey covers ~2,000 sq km.</strong> Five times larger than the first. Redefined the Angkor Wat landscape (Antiquity 2015), revealing occupation mounds and a residential population of up to ~4,500 inside the moated enclosure.<sup class=\"footnote-ref\"><a href=\"#src-2\">2</a>, <a href=\"#src-6\">6</a>, <a href=\"#src-14\">14</a></sup></dd>"
    "      </dl>"
    "    </section>"
    ""
    "    <section class=\"col-2\">"
    "      <h2 id=\"sources\">Sources</h2>"
    "      <ol>"
    "        <li id=\"src-1\"><a href=\"https://e128.info/content/history/ancient/anthropologists-at-angkor-wat-reveal-new-clues-about-the-ancient-temple-thought/anthropologists-at-angkor-wat-reveal-new-clues-about-the-ancient-temple-thought.md\">Anthropologists at Angkor Wat reveal new clues about the ancient temple thought abandoned (Ancient Code)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-2\"><a href=\"https://e128.info/content/history/geography/how-early-megacities-emerged-from-the-jungles-of-cambodia-atlas-obscura/how-early-megacities-emerged-from-the-jungles-of-cambodia-atlas-obscura.md\">How Early Megacities Emerged From the Jungles of Cambodia (Atlas Obscura)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-3\"><a href=\"https://e128.info/content/history/geography/the-fall-of-angkor-was-more-than-a-century-in-the-making/the-fall-of-angkor-was-more-than-a-century-in-the-making.md\">The Fall of Angkor Was More Than a Century in The Making</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-4\"><a href=\"https://e128.info/content/history/geography/how-bad-karma-and-bad-engineering-doomed-an-ancient-cambodian-capital/how-bad-karma-and-bad-engineering-doomed-an-ancient-cambodian-capital.md\">How Bad Karma and Bad Engineering Doomed an Ancient Cambodian Capital</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-5\"><a href=\"https://e128.info/content/history/ancient/parallel-civilizations-ancient-angkor-and-the-anci/parallel-civilizations-ancient-angkor-and-the-anci.md\">Parallel Civilizations: Ancient Angkor and the Ancient Maya (Michael Coe lecture, UC Berkeley)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-6\"><a href=\"https://e128.info/content/history/ancient/angkor-an-ancient-mega-city-hidden-deep-withing-the-jungle-ancient-code/angkor-an-ancient-mega-city-hidden-deep-withing-the-jungle-ancient-code.md\">Angkor: An Ancient Mega City Hidden Deep Withing the Jungle (Ancient Code)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-7\"><a href=\"https://e128.info/content/history/blinds-gossip/bbc-news-beyond-angkor-how-lasers-revealed-a-lost-city/bbc-news-beyond-angkor-how-lasers-revealed-a-lost-city.md\">BBC News - Beyond Angkor: How lasers revealed a lost city</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-8\"><a href=\"https://e128.info/content/history/geography/the-mystery-of-the-dinosaur-of-angkor-ilbonito-blog-2007/the-mystery-of-the-dinosaur-of-angkor-ilbonito-blog-2007.md\">The mystery of the dinosaur of Angkor (ilbonito blog 2007)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-9\"><a href=\"https://www.britannica.com/place/Funan\">Funan | Cambodia, Map, &amp; Facts (Britannica)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-10\"><a href=\"http://michaelvickery.org/vickery2003funan-rev.pdf\">Funan Reviewed: Deconstructing the Ancients (Michael Vickery)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-11\"><a href=\"https://www.britannica.com/topic/Angkor-Wat\">Angkor Wat | Description, Location, History, Restoration (Britannica)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-12\"><a href=\"https://penelope.uchicago.edu/Thayer/E/Gazetteer/Places/Asia/Cambodia/Siem_Reap/Siem_Reap/Angkor_Wat/_Texts/DICANG/Chronology*.html\">Wondrous Angkor - Kings of Angkor chronology (LacusCurtius, University of Chicago)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-13\"><a href=\"https://doi.org/10.1073/pnas.1306539110\">Uncovering archaeological landscapes at Angkor using lidar (Evans et al., PNAS 2013)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-14\"><a href=\"https://www.cambridge.org/core/journals/antiquity/article/landscape-of-angkor-wat-redefined/F3F0731A514E338A76DA8A906458A890\">The landscape of Angkor Wat redefined (Evans &amp; Fletcher, Antiquity 2015)</a>, scraped 2026-08-13</li>"
    "        <li id=\"src-15\"><a href=\"https://hdl.handle.net/2292/72578\">Discovering Angkor: Henri Mouhot and the European Rediscovery of Angkor Wat (Rui Patel Kerr, Univ. of Auckland)</a>, scraped 2026-08-13</li>"
    "      </ol>"
    "    </section>"
    ""
    "    <footer>Timeline layout sample. Generated by scripts/build-sample.nu.</footer>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}
