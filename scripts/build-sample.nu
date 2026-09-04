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
      "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>"
      $"  <title>($p.2)</title>"
      "  <meta name=\"generated-by\" content=\"scripts/build-sample.nu\"/>"
      $css
      $mermaid
      $filter
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
  # Each condition is checked on its own, not "did anything change". A first cut
  # compared the whole string before and after and passed when only the contrast
  # condition still matched, which is the case that matters least. Renaming the
  # light condition alone would have shipped a dark page called light.
  for c in ["@media (prefers-color-scheme: light)" "@media (prefers-contrast: more)" "@media print and (prefers-color-scheme: light)"] {
    if not ($html | str contains $c) {
      error make {msg: $"preview: ($fixture) has no `($c)`: the stylesheet renamed it, so the preview would ship the default palette under a light name"}
    }
  }
  # The print-and-light block becomes an unconditional `@media print`, because a page
  # locked to light renders a light-themed diagram, which needs neither the frozen dark
  # palette nor the ground that goes with it. Leaving the condition intact would also
  # leave a live `prefers-color-scheme` in a page that claims to have none, which the
  # contract check reads as a rewrite that did not happen. This replacement runs first
  # only for readability: the longer string is not a substring of the shorter one.
  let forced = ($html
    | str replace "@media print and (prefers-color-scheme: light)" "@media print"
    | str replace "@media (prefers-color-scheme: light)" "@media all"
    | str replace "@media (prefers-contrast: more)" "@media not all")
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
    "      <p>Past roughly 15 to 20 nodes on one rank the small map's flat fan-out sprawls (see NOTES.md, Large maps). This map groups antecedents and descendants into open subgraphs, switches to the ELK layout engine, and states each relationship style once in a legend instead of on every edge. Every node stays clickable: the subgraphs are never collapsed, because <code>view: collapsed</code> drops a cluster's nodes, and their links, from the render entirely. A consumer wanting real per-node links adds a <code>click</code> directive per node and sets <code>window.mermaidSecurityLevel = 'loose'</code> (see NOTES.md, Zoom); this fixture leaves the default <code>strict</code>, so it stays a two-<code>&lt;script&gt;</code> fixture.</p>"
    "      <pre class=\"mermaid\">---\nconfig:\n  layout: elk\n  flowchart:\n    useMaxWidth: false\n  elk:\n    nodePlacementStrategy: NETWORK_SIMPLEX\n---\nflowchart TD\n  accTitle: Large connections map for the focus topic\n  accDescr: A focus topic with two eras of antecedents and descendants grouped into open subgraphs, every node individually clickable, and a legend explaining that a solid line is a technological connection and a dashed line is a conceptual one.\n  subgraph legend[\"Legend\"]\n    direction LR\n    key1((\" \")) -->|technological| key2((\" \"))\n    key3((\" \")) -.->|conceptual| key4((\" \"))\n  end\n  focus[Focus Topic]\n  subgraph pre2010[\"Antecedents, pre-2010\"]\n    a1[Antecedent A]\n    a2[Antecedent B]\n    a3[Antecedent C]\n    a4[Antecedent D]\n    a5[Antecedent E]\n    a6[Antecedent F]\n  end\n  subgraph post2010[\"Descendants, post-2010\"]\n    d1[Descendant W]\n    d2[Descendant X]\n    d3[Descendant Y]\n    d4[Descendant Z]\n  end\n  a1 --> focus\n  a2 --> focus\n  a3 --> focus\n  a4 -.-> focus\n  a5 -.-> focus\n  a6 --> focus\n  focus --> d1\n  focus --> d2\n  focus -.-> d3\n  focus --> d4</pre>"
    "    </section>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}

# Charts get their own page, not a section in the component sample, because the two
# forms are only worth anything side by side: both tables and the pie carry the SAME
# four numbers, so a reader can see that the 21 and the 15 are ranked at a glance as
# bars and are a coin toss as slices. That comparison is the guidance CONTRACT.md
# section 2 states in one line, and a page is where it can be looked at.
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
    "    <p class=\"byline\">table.bar-chart and .pie-chart: CSS over ordinary markup, no script and no CDN</p>"
    ""
    "    <nav>"
    "      <a href=\"#bars\">Bar chart</a>"
    "      <a href=\"#pie\">Pie chart</a>"
    "      <a href=\"#which\">Which one</a>"
    "    </nav>"
    ""
    "    <section>"
    "      <h2 id=\"bars\">Bar chart</h2>"
    "      <p>A bar chart here is a real table with a class on it. The bar is a background band inside the cell that already holds the number, sized by a <code>--bar</code> percentage the generator sets, so the value is text in the markup and the bar is a second reading of it. Nothing is added to the accessibility tree and nothing is lost when the band does not paint.</p>"
    "      <table class=\"bar-chart\" tabindex=\"0\">"
    "        <caption>Payload bytes by file, as a share of the whole. Every bar starts at the same edge, so length is the comparison.</caption>"
    "        <thead><tr><th scope=\"col\">File</th><th scope=\"col\">Share</th></tr></thead>"
    "        <tbody>"
    "          <tr><td><code>tufte-dracula.css</code></td><td class=\"bar\" style=\"--bar: 52%\">52%</td></tr>"
    "          <tr><td><code>mermaid.js</code></td><td class=\"bar\" style=\"--bar: 21%\">21%</td></tr>"
    "          <tr><td><code>filter.js</code></td><td class=\"bar\" style=\"--bar: 15%\">15%</td></tr>"
    "          <tr><td><code>mermaid-palette.json</code></td><td class=\"bar\" style=\"--bar: 12%\">12%</td></tr>"
    "        </tbody>"
    "      </table>"
    "      <p>Every band is one hue, and the row label carries the category. Coloring each band from the <code>--data-*</code> ramp to key it to the pie legend below was tried and measured out: at the 0.3 alpha that keeps the number on top of the band legible, the four ramp members land within Lc 2 of each other, so a band cannot carry a category at all (see NOTES.md, <em>CSS charts</em>). The table below is the other axis convention: each bar is a share of the largest value rather than of a total, which is what makes an unlabelled axis honest.</p>"
    "      <table class=\"bar-chart\" tabindex=\"0\">"
    "        <caption>A synthetic single series, each bar a share of the largest value rather than of a total</caption>"
    "        <thead><tr><th scope=\"col\">Category</th><th scope=\"col\">Count</th></tr></thead>"
    "        <tbody>"
    "          <tr><td>First category</td><td class=\"bar\" style=\"--bar: 100%\">480</td></tr>"
    "          <tr><td>Second category</td><td class=\"bar\" style=\"--bar: 65%\">312</td></tr>"
    "          <tr><td>Third category</td><td class=\"bar\" style=\"--bar: 28%\">134</td></tr>"
    "          <tr><td>Fourth category</td><td class=\"bar\" style=\"--bar: 4%\">19</td></tr>"
    "        </tbody>"
    "      </table>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"pie\">Pie chart</h2>"
    "      <p>The pie is one <code>conic-gradient</code> over four shares. Each <code>--p1</code> to <code>--p4</code> is that slice's own percentage, never a running total: the rule adds them up, so a generator that emits cumulative values draws the wrong chart. Every slice is separated by a 1.5deg gap of the page ground, because the four ramp members sit at one lightness: without the gap two touching slices differ in hue alone, at 1.00 to 1.02:1 in the light and print palettes and as little as 1.00:1 under simulated color blindness, so the 15% and the 12% wedge read as one. Nothing inside the element is text, so it takes <code>role=\"img\"</code> and an <code>aria-label</code> that states every slice and its value, and the legend repeats them for a sighted reader.</p>"
    "      <figure>"
    "        <div class=\"pie-chart\" role=\"img\" style=\"--p1: 52; --p2: 21; --p3: 15; --p4: 12\" aria-label=\"Payload bytes by file: tufte-dracula.css 52 percent, mermaid.js 21 percent, filter.js 15 percent, mermaid-palette.json 12 percent\"></div>"
    "        <figcaption>The same four numbers as the first table above. Legend: <span class=\"tag-dot\" style=\"color: var(--data-1)\"></span>tufte-dracula.css 52%, <span class=\"tag-dot\" style=\"color: var(--data-2)\"></span>mermaid.js 21%, <span class=\"tag-dot\" style=\"color: var(--data-3)\"></span>filter.js 15%, <span class=\"tag-dot\" style=\"color: var(--data-4)\"></span>mermaid-palette.json 12%.</figcaption>"
    "      </figure>"
    "      <p>Four slices is the ceiling, because the ramp has four members and each one is contrast-checked against the card it sits on. A fifth category has no color left that clears the floor, and a page that reaches for one is telling you it wanted a bar chart. A Mermaid <code>pie showData</code> fence is the other way to draw this, themed per palette in <code>mermaid.js</code>; it prints its percentages inside the slices and costs a CDN request (see the component sample page).</p>"
    "    </section>"
    ""
    "    <section>"
    "      <h2 id=\"which\">Which one</h2>"
    "      <p><strong>Reach for the bar chart first, and for a plain table before either.</strong> Tufte's objection to the pie is that it asks a reader to compare angles and areas, which readers do badly: the 21 and the 15 slice above are a coin toss without the legend, while the same two bars are ranked at a glance. This template supports the pie anyway, because a part-to-whole share of a few categories is a real thing to draw and a consumer who wants one should get a themed one rather than invent it. The support comes with the rule that makes it defensible: <strong>every value is in the markup as text</strong>, so no reader depends on measuring a wedge.</p>"
    "      <ul>"
    "        <li>Ranking or comparing magnitudes: bar chart.</li>"
    "        <li>One part-to-whole split, four categories or fewer, values stated in text: pie chart.</li>"
    "        <li>Five or more categories, two series, or a value a reader will want to read exactly: a table. The bar chart is a table, so this is the same answer twice.</li>"
    "        <li>A trend over time: neither. Nothing here draws a line chart, and a Mermaid <code>xychart-beta</code> fence is not themeable (see NOTES.md, Diagram types).</li>"
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
    # a two-link nav.
    "    <nav>"
    "      <a href=\"#\">Requirements Register</a>"
    "      <a href=\"#\">Decision Log</a>"
    "      <a href=\"#\">Dependency Tracker</a>"
    "      <a href=\"#\">Spike Results</a>"
    "      <a href=\"#\">Findings</a>"
    "      <a href=\"#\">Reuse Candidates</a>"
    "      <a href=\"#\">Project Summary</a>"
    "    </nav>"
    ""
    "    <section>"
    "      <h2>Headings &amp; text</h2>"
    "      <h3>Third-level heading</h3>"
    "      <h4>Fourth level: body size, label tier</h4>"
    "      <h5>Fifth level: body size, muted tier</h5>"
    "      <h6>Sixth level: muted and italic</h6>"
    "      <p><span class=\"newthought\">A new thought</span> opens in small-caps. Body copy is Source Serif 4 at weight 450, with <strong>strong (orange)</strong>, <em>emphasis (inherits its surroundings)</em>, an <a href=\"#\">internal hyperlink</a>, an <a href=\"https://example.com\">outbound link</a> carrying its marker, a source citation <cite>src/theme/tokens.css:14</cite>, and inline <code>code()</code>.</p>"
    "      <p>Status spans: <span class=\"verified\">verified</span>, <span class=\"unverified\">unverified</span>, <span class=\"correction\">correction</span>.</p>"
    "      <p>Annotation elements: <mark>a marked passage</mark> takes a translucent orange wash, and a shortcut renders as <kbd>Ctrl</kbd> <kbd>K</kbd>, a ringed chip distinct from inline <code>code()</code>.</p>"
    "      <p>Markdown inline output: <del>struck through</del> drops to the muted tier, <samp>program output</samp> takes the mono face without the code chip, an <abbr title=\"HyperText Markup Language\">HTML</abbr> abbreviation carries a dotted rule, and H<sub>2</sub>O sits beside 10<sup>3</sup> without opening the line.</p>"
    "      <p>A sidenote lives here.<label for=\"sn-1\" class=\"margin-toggle sidenote-number\"></label><input type=\"checkbox\" id=\"sn-1\" class=\"margin-toggle\"/><span class=\"sidenote\">This is a Tufte sidenote. It floats to the right margin and auto-numbers.</span> And a margin note follows.<label for=\"mn-1\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-1\" class=\"margin-toggle\"/><span class=\"marginnote\">A margin note carries no number.</span></p>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Code block</h2>"
    "      <pre tabindex=\"0\" role=\"region\" aria-label=\"Code block\"><code>def greet [name: string] {\n    print $\"hello ($name)\"\n}</code></pre>"
    "      <p>A highlighted block takes the same slot map the editor themes use: keywords pink, strings green, numbers orange, comments muted, functions link, types purple, fields label.</p>"
    "      <pre tabindex=\"0\" role=\"region\" aria-label=\"Highlighted code block\"><code class=\"language-csharp hljs\"><span class=\"hljs-comment\">// highlighter classes, not hand-written spans</span>\n<span class=\"hljs-keyword\">public</span> <span class=\"hljs-type\">Result</span> <span class=\"hljs-title hljs-function\">Parse</span>(<span class=\"hljs-type\">string</span> <span class=\"hljs-params\">source</span>) {\n    <span class=\"hljs-keyword\">var</span> <span class=\"hljs-variable\">count</span> = <span class=\"hljs-number\">42</span>;\n    <span class=\"hljs-keyword\">return</span> <span class=\"hljs-keyword\">new</span> <span class=\"hljs-type\">Result</span>(<span class=\"hljs-string\">\"ok\"</span>, <span class=\"hljs-variable\">count</span>);\n}</code></pre>"
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
    "      <p>A tag-dot marks a categorical value that already has a color elsewhere, never a rank. The class carries only the dot, never the label, because it paints <code>currentColor</code> and would otherwise recolor the text beside it: <span class=\"tag-dot\" style=\"color: var(--data-1)\"></span>Rust, <span class=\"tag-dot\" style=\"color: var(--data-3)\"></span>Go, <span class=\"tag-dot\" style=\"color: var(--data-2)\"></span>Python. A live-dot is the sheet's first animation, frozen for free under reduced motion: <span class=\"live-dot\"></span> streaming.</p>"
    "      <ul class=\"icon-list\" role=\"list\">"
    "        <li style=\"--icon-color: var(--orange)\"><span class=\"icon-chip\" aria-hidden=\"true\">I</span><div><strong>Implement</strong><br/><code>implement the functionality</code></div></li>"
    "        <li style=\"--icon-color: var(--link)\"><span class=\"icon-chip\" aria-hidden=\"true\">I</span><div><strong>Identify</strong><br/><code>identify the bottleneck</code></div></li>"
    "        <li style=\"--icon-color: var(--green)\"><span class=\"icon-chip\" aria-hidden=\"true\">V</span><div><strong>Validate</strong><br/><code>verify behavioral correctness</code></div></li>"
    "      </ul>"
    "      <p>A step chain is for a flow too trivial to justify a Mermaid diagram. A graph with a branch or a loop still belongs in <code>pre.mermaid</code>. Its <code>--icon-color</code> takes a prose accent, never a <code>--data-*</code> slot: the node fills at full strength and the letter is <code>--surface</code> on top of it, so a ramp scoped to the 3:1 diagram floor lands that pair at 3.5:1 in light mode. A <code>.tag-dot</code> or an <code>.icon-chip</code> may still carry a <code>--data-*</code> color, because neither puts text on the fill.</p>"
    "      <div class=\"step-chain\">"
    "        <span class=\"step-node\" style=\"--icon-color: var(--orange)\">S</span>"
    "        <span class=\"step-hop\"><span class=\"step-arrow\">&rarr;</span><span class=\"step-node\" style=\"--icon-color: var(--link)\">I</span></span>"
    "        <span class=\"step-hop\"><span class=\"step-arrow\">&rarr;</span><span class=\"step-node\" style=\"--icon-color: var(--purple)\">O</span></span>"
    "        <span class=\"step-hop\"><span class=\"step-arrow\">&rarr;</span><span class=\"step-node\" style=\"--icon-color: var(--green)\">V</span></span>"
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
    "        <span class=\"sc-label\">P4 Coherence</span><span class=\"verdict verdict-neutral\">N/A</span><span class=\"sc-note\">not assessed</span>"
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
    "      </table>"
    "    </section>"
    ""
    "    <section>"
    "      <h2>Navigation index components</h2>"
    "      <label class=\"filter-label\" for=\"nav-filter\">Filter entries</label>"
    "      <input id=\"nav-filter\" type=\"search\" class=\"filter-box\" autocomplete=\"off\" placeholder=\"Type to filter&hellip;\"/>"
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
    "        <div class=\"recent-group\"><h3>Category A</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item One\">Item One</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"view all 12: Category A\">view all 12 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "        <div class=\"recent-group\"><h3>Category B</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item Two\">Item Two</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"view all 533: Category B\">view all 533 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "        <div class=\"recent-group\"><h3>Category C</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item Three\">Item Three</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"view all 36: Category C\">view all 36 <span aria-hidden=\"true\">&rarr;</span></a></div>"
    "        <div class=\"recent-group\"><h3>Other</h3><ul class=\"nav-list\" role=\"list\"><li><a href=\"#\" title=\"Item Four\">Item Four</a> <span class=\"count\">2026-08-15</span></li></ul><a href=\"#\" aria-label=\"view all 1689: Other\">view all 1689 <span aria-hidden=\"true\">&rarr;</span></a></div>"
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
    "      <figcaption>A figure caption sits in the annotation register and stays start-aligned under a centred diagram.</figcaption>"
    "      </figure>"
    "      <pre class=\"mermaid\">sequenceDiagram\n  accTitle: Sequence diagram sample\n  accDescr: The caller sends a request, the service stores it, and a note records that a label box must fit its own monospace text.\n  participant C as Caller\n  participant S as Service (long name)\n  C->>S: Request with a fairly long label\n  S->>S: Store it\n  Note over S: This note is wider than the actor box.<br/>Its rect must contain the rendered text.\n  S->>C: Result</pre>"
    "      <pre class=\"mermaid\">quadrantChart\n  accTitle: Quadrant chart sample\n  accDescr: Four labelled points near the chart edges, where long labels would otherwise be clipped by the fixed chart viewBox.\n  x-axis Narrow --> Wide\n  y-axis Shallow --> Deep\n  quadrant-1 Best of both\n  quadrant-2 Deep but narrow\n  quadrant-3 Neither yet\n  quadrant-4 Wide but shallow\n  A label long enough to reach past the edge: [0.9, 0.9]\n  Another deliberately overlong point label: [0.1, 0.1]</pre>"
    "      <pre class=\"mermaid\">packet-beta\n  accTitle: Packet diagram sample\n  accDescr: A UDP header split into four labelled byte ranges, styled through tufte-dracula.css because mermaid's own packet themeVariables are a documented no-op.\n  title UDP Header\n  0-15: \"Source Port\"\n  16-31: \"Destination Port\"\n  32-47: \"Length\"\n  48-63: \"Checksum\"</pre>"
    "      <p>The pie chart is the only diagram type that paints text directly onto a <code>--data-*</code> fill, so it carries its own <code>pieSectionTextColor</code> per palette and pins <code>pieOpacity</code> to <code>1</code>. Mermaid's stock 0.7 composited every slice toward the card, and its single <code>textColor</code> is the wrong end of the ramp in one palette or the other (see NOTES.md, Diagram types).</p>"
    "      <pre class=\"mermaid\">pie showData\n  accTitle: Pie chart sample\n  accDescr: Four payload files as a share of the template's bytes, drawn from the data ramp, with each slice's percentage painted inside the slice.\n  title Payload bytes by file\n  \"tufte-dracula.css\" : 52\n  \"mermaid.js\" : 21\n  \"filter.js\" : 15\n  \"mermaid-palette.json\" : 12</pre>"
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
