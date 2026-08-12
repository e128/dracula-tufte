#!/usr/bin/env nu
# build-sample.nu — regenerate the samples/ pages, a living demo of every
# component in tufte-dracula.css + mermaid.js. Re-inlines the two source files
# verbatim (same bytes the renderer emits), so a CSS or mermaid edit shows up
# here on the next run. Run: `nu scripts/build-sample.nu` (writes + git-adds).
#
# ponytail: static demo body, no markdown pipeline. This is a style fixture, not
# a lode scroll — html-render.nu owns real content. Add a component here whenever
# tufte-dracula.css gains one.

# path self is this file, so its dirname is scripts/ and ROOT is the repo above it.
# Everything resolves from ROOT, never from cwd, so this runs from anywhere in the tree.
# SCRIPTS exists because `path self | path dirname | path dirname` is not a legal const
# chain in Nushell — the second step has to read a name that is already bound.
const SCRIPTS = path self | path dirname
const ROOT = $SCRIPTS | path dirname

def main [] {
  let css = (open --raw ($ROOT | path join "tufte-dracula.css") | str trim --right)
  let mermaid = (open --raw ($ROOT | path join "mermaid.js") | str trim --right)
  let filter = (open --raw ($ROOT | path join "filter.js") | str trim --right)

  tokens $css

  # (filename, <body> tag, title, body-content, light-preview filename) — one page
  # per layout mode, each with a forced-light twin for Pages.
  [
    ["dark.html" "<body>" "Tufte-Dracula — component sample" (body) "light.html"]
    ["dark-conn-map.html" "<body class=\"conn-map\">" "Tufte-Dracula — connections-map layout" (conn-map-body) "light-conn-map.html"]
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
# `@media not all` so it never does. Forcing light alone would be almost enough —
# the light block is declared after the contrast block and overrides every token
# it sets — but it would leave the contrast block's two non-token rules live, so a
# visitor who asks for more contrast would see a preview nobody else sees.
# Deterministic beats almost.
#
# light.html is NOT the payload: the stylesheet inside it has had its media
# conditions rewritten, so it is not the file a consumer inlines. It sits beside
# dark.html under one folder and reads like an equal peer, which is exactly why
# the banner is not optional — the filename no longer carries the warning.
def preview [html: string, fixture: string, title: string, name: string] {
  # Each condition is checked on its own, not "did anything change". A first cut
  # compared the whole string before and after and passed when only the contrast
  # condition still matched — which is the case that matters least. Renaming the
  # light condition alone would have shipped a dark page called light.
  for c in ["@media (prefers-color-scheme: light)" "@media (prefers-contrast: more)"] {
    if not ($html | str contains $c) {
      error make {msg: $"preview: ($fixture) has no `($c)` — the stylesheet renamed it, so the preview would ship the default palette under a light name"}
    }
  }
  let forced = ($html
    | str replace "@media (prefers-color-scheme: light)" "@media all"
    | str replace "@media (prefers-contrast: more)" "@media not all")
  let banner = ([
    "  <div class=\"markdown-alert markdown-alert-caution\">"
    "    <p class=\"markdown-alert-title\">Preview only &mdash; not the payload</p>"
    $"    <p>This page forces <code>prefers-color-scheme: light</code>, so the light palette shows on any system. Its copy of the stylesheet has had the <code>@media</code> conditions rewritten to do that, which makes it <strong>locked to light</strong> and <strong>not the payload</strong>. Inline <code>tufte-dracula.css</code> from the repo root, never a page. <a href=\"($fixture)\">($fixture)</a> is the same fixture with the stylesheet verbatim.</p>"
    "  </div>"
  ] | str join "\n")
  let out = ($ROOT | path join "samples" $name)
  ($forced
    | str replace $"<title>($title)</title>" $"<title>($title) — forced light preview</title>"
    | str replace --regex '(?m)^(<body[^>]*>)$' $"$1\n($banner)") | save -f $out
  ^git -C $ROOT add $out
  print $"  → ($out)"
}

# tokens.css is a projection of tufte-dracula.css, not a second source: the :root
# block sliced out verbatim (only the shared indent is stripped). Verbatim means
# no transform step, so nothing to drift — the AA-tuning comments, the
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
    " * GENERATED by scripts/build-sample.nu — the :root block of tufte-dracula.css, verbatim."
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
# this stylesheet — see NOTES.md.
def conn-map-body [] {
  [
    "  <div class=\"mermaid-overlay\" id=\"mermaid-zoom\"></div>"
    "  <main>"
    "  <article>"
    "    <h1>Connections-Map Layout Sample</h1>"
    "    <p class=\"byline\">body.conn-map &mdash; Links column left, graph right (wide screens)</p>"
    "    <section>"
    "      <h2>Links</h2>"
    "      <h3>Antecedents</h3>"
    "      <ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">Antecedent A</a></li><li><a href=\"#\">Antecedent B</a></li></ul>"
    "      <h3>Descendants</h3>"
    "      <ul class=\"nav-list\" role=\"list\"><li><a href=\"#\">Descendant X</a></li><li><a href=\"#\">Descendant Y</a></li></ul>"
    "    </section>"
    "    <section>"
    "      <h2>Graph</h2>"
    "      <pre class=\"mermaid\">%%{init: {'flowchart': {'useMaxWidth': false}}}%%\nflowchart BT\n  accTitle: Connections map for the focus topic\n  accDescr: Antecedents A and B feed the focus topic, which leads to descendants X and Y. The focus label is deliberately long, so its box must not clip its own text or push the graph past the column.\n  focus[Focus Topic with a deliberately long label that must fit its own box]\n  a1[Antecedent A] --> focus\n  a2[Antecedent B] --> focus\n  focus --> d1[Descendant X]\n  focus --> d2[Descendant Y]</pre>"
    "    </section>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}

def body [] {
  [
    # Mermaid click-to-zoom overlay target (id referenced by mermaid.js).
    "  <div class=\"mermaid-overlay\" id=\"mermaid-zoom\"></div>"
    "  <main>"
    "  <article>"
    "    <h1>Tufte-Dracula Component Sample</h1>"
    "    <p class=\"byline\">Living style fixture &mdash; every rule in tufte-dracula.css + mermaid.js</p>"
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
    "      <h4>Fourth level &mdash; body size, label tier</h4>"
    "      <h5>Fifth level &mdash; body size, muted tier</h5>"
    "      <h6>Sixth level &mdash; muted and italic</h6>"
    "      <p><span class=\"newthought\">A new thought</span> opens in small-caps. Body copy is Source Serif 4 at weight 450, with <strong>strong (orange)</strong>, <em>emphasis (inherits its surroundings)</em>, an <a href=\"#\">internal hyperlink</a>, an <a href=\"https://example.com\">outbound link</a> carrying its marker, a source citation <cite>src/theme/tokens.css:14</cite>, and inline <code>code()</code>.</p>"
    "      <p>Status spans: <span class=\"verified\">verified</span>, <span class=\"unverified\">unverified</span>, <span class=\"correction\">correction</span>.</p>"
    "      <p>Annotation elements: <mark>a marked passage</mark> takes a translucent orange wash, and a shortcut renders as <kbd>Ctrl</kbd> <kbd>K</kbd> &mdash; a ringed chip, distinct from inline <code>code()</code>.</p>"
    "      <p>Markdown inline output: <del>struck through</del> drops to the muted tier, <samp>program output</samp> takes the mono face without the code chip, an <abbr title=\"HyperText Markup Language\">HTML</abbr> abbreviation carries a dotted rule, and H<sub>2</sub>O sits beside 10<sup>3</sup> without opening the line.</p>"
    "      <p>A sidenote lives here.<label for=\"sn-1\" class=\"margin-toggle sidenote-number\"></label><input type=\"checkbox\" id=\"sn-1\" class=\"margin-toggle\"/><span class=\"sidenote\">This is a Tufte sidenote &mdash; it floats to the right margin and auto-numbers.</span> And a margin note follows.<label for=\"mn-1\" class=\"margin-toggle\">&#8853;</label><input type=\"checkbox\" id=\"mn-1\" class=\"margin-toggle\"/><span class=\"marginnote\">A margin note carries no number.</span></p>"
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
    "      <table>"
    "        <caption>Table caption: annotation register, start-aligned like every other block.</caption>"
    "        <thead><tr><th scope=\"col\">Column</th><th scope=\"col\" class=\"num\">Value</th><th scope=\"col\">Note</th></tr></thead>"
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
    "      <table class=\"tree\">"
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
    "    <section>"
    "      <h2>Blockquote, aside, details</h2>"
    "      <blockquote><p>Stat crux dum volvitur orbis &mdash; the Cross stands while the world turns.</p></blockquote>"
    "      <aside>An aside: orange accent-bar, no fill. For asides and callouts. A <mark>marked passage inside the label tier</mark> keeps body-copy text, since the wash carries nothing dimmer.</aside>"
    "      <details><summary>Collapsible summary</summary><p>Hidden content revealed on click.</p></details>"
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
    "    <section>"
    "      <h2>Markdown callouts, math &amp; footnotes</h2>"
    "      <p>GitHub alert blocks share the <code>aside</code> form &mdash; one accent bar, no fill &mdash; and carry the hue on the title line only.<sup class=\"footnote-ref\"><a href=\"#fn-1\" id=\"fnref-1\">1</a></sup></p>"
    "      <div class=\"markdown-alert markdown-alert-note\"><p class=\"markdown-alert-title\">Note</p><p>Link-blue bar. Neutral information.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-tip\"><p class=\"markdown-alert-title\">Tip</p><p>Green bar. Optional advice.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-important\"><p class=\"markdown-alert-title\">Important</p><p>Purple bar. Do not skip this.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-warning\"><p class=\"markdown-alert-title\">Warning</p><p>Orange bar, the same hue the plain aside takes.</p></div>"
    "      <div class=\"markdown-alert markdown-alert-caution\"><p class=\"markdown-alert-title\">Caution</p><p>Red bar. Risk of loss or breakage.</p></div>"
    "      <table>"
    "        <thead><tr><th align=\"left\">Alignment</th><th align=\"center\">from the</th><th align=\"right\">pipe table</th></tr></thead>"
    "        <tbody><tr><td align=\"left\">start</td><td align=\"center\">center</td><td align=\"right\">3.14159</td></tr></tbody>"
    "      </table>"
    "      <p>Math converted to MathML needs no script and no CDN: <math><mi>E</mi><mo>=</mo><mi>m</mi><msup><mi>c</mi><mn>2</mn></msup></math> sets inline without opening the line box, and a display block scrolls on its own axis rather than widening the page.</p>"
    "      <math display=\"block\"><mrow><munderover><mo>&sum;</mo><mrow><mi>n</mi><mo>=</mo><mn>1</mn></mrow><mi>&infin;</mi></munderover><mfrac><mn>1</mn><msup><mi>n</mi><mn>2</mn></msup></mfrac><mo>=</mo><mfrac><msup><mi>&pi;</mi><mn>2</mn></msup><mn>6</mn></mfrac></mrow></math>"
    "      <section class=\"footnotes\" data-footnotes>"
    "        <ol><li id=\"fn-1\"><p>The footnote block sits behind a hairline at the caption tier, tightened to the annotation register. <a href=\"#fnref-1\" class=\"footnote-backref\">&#8617;</a></p></li></ol>"
    "      </section>"
    "    </section>"
    ""
    "    <section class=\"indented\">"
    "      <h2>Indented paragraphs (opt-in)</h2>"
    "      <p>A container carrying <code>class=\"indented\"</code> sets its paragraphs the way a book does: no gap between them, and every paragraph after the first opens with a 1.5em indent. The first paragraph is never indented, because nothing precedes it to break from.</p>"
    "      <p>This paragraph is the second, so it indents. The break is carried by the indent rather than by white space, which is the convention the rest of the page deliberately does not use &mdash; the default remains spaced paragraphs with no indent, and this class is the only way to get the other one.</p>"
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
    "    </section>"
    ""
    "    <section>"
    "      <h2>Navigation index components</h2>"
    "      <label class=\"filter-label\" for=\"nav-filter\">Filter entries</label>"
    "      <input id=\"nav-filter\" type=\"search\" class=\"filter-box\" autocomplete=\"off\" placeholder=\"Type to filter&hellip;\"/>"
    "      <p role=\"status\">3 entries</p>"
    "      <ul class=\"nav-list\" role=\"list\">"
    "        <li><a href=\"#\">A tappable nav-list link</a></li>"
    "        <li><a href=\"#\">Another entry <span class=\"badge badge-t1\">Tier 1</span></a></li>"
    "        <li><a href=\"#\">Failed audit <span class=\"badge badge-t3\">Tier 3</span></a></li>"
    "      </ul>"
    "      <p class=\"filter-empty\">No entries match &ldquo;tier 4&rdquo;. Clear the filter to see all 3.</p>"
    "      <details class=\"nav-group\" open><summary>Subfolder group <span class=\"count\">3</span></summary>"
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
    "    </section>"
    ""
    "    <hr/>"
    "    <footer>Footer text &mdash; muted, small. Generated by scripts/build-sample.nu.</footer>"
    "  </article>"
    "  </main>"
  ] | str join "\n"
}
