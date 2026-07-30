  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.esm.min.mjs';
    // Defaults to 'strict' (sanitizes `click <node> "<url>"` directives away).
    // Consumers with a trusted diagram source can opt into 'loose' (renders
    // click directives as navigable links) by setting
    // `window.mermaidSecurityLevel = 'loose'` in a preceding classic script
    // tag (runs before this module script).
    // theme:'base' + explicit themeVariables, never theme:'dark' — the stock dark
    // theme ignores this palette entirely. Hex, never oklch(): khroma throws
    // "Unsupported color format" on an oklch() string and aborts init, so no
    // diagram renders. Values mirror mermaid-palette.json (CI enforces).
    // darkMode belongs *inside* themeVariables: mermaidAPI passes only
    // config.themeVariables to base.getThemeVariables(), so a root-level darkMode
    // never reaches the theme and every derived color is computed light-mode
    // (ER rows come out lighten(mainBkg, 75) — near-white under light textColor).
    mermaid.initialize({
      startOnLoad: true, theme: 'base',
      securityLevel: window.mermaidSecurityLevel || 'strict',
      themeVariables: {
        darkMode: true,
        // The only two non-color themeVariables. Deliberately NOT mirrored into
        // mermaid-palette.json: that file and palette-check.py exist to catch hex
        // drift against the oklch source, and a font stack has no hex to drift.
        // fontSize is a CSS length string, so 1rem tracks the reader's own root
        // font-size; mermaid's default is a hard-coded 16px that ignores it, the
        // same defect as the max(Xem, 12pt) floors removed from the stylesheet.
        // Pair this with `width: auto` on the conn-map svg — while the SVG was
        // stretched to its container, whatever is set here was multiplied by up
        // to 3.23x on the way to the screen.
        fontFamily: 'ui-monospace, "JetBrains Mono", "Fira Code", monospace',
        fontSize:   '1rem',
        background:          '#282a36',  /* --surface */
        mainBkg:             '#343746',  /* --code-bg */
        primaryColor:        '#343746',  /* --code-bg */
        primaryTextColor:    '#f8f8f2',  /* --on-surface */
        primaryBorderColor:  '#a98ed6',  /* --purple */
        lineColor:           '#979fc4',  /* --muted */
        textColor:           '#f8f8f2',  /* --on-surface */
        secondaryColor:      '#1e1f29',  /* --surface-alt */
        clusterBkg:          '#343746',  /* --code-bg */
        clusterBorder:       '#707388',  /* --rule-light */
        nodeBorder:          '#a98ed6',  /* --purple */
        edgeLabelBackground: '#343746',  /* --code-bg, matching the pre it renders in */
        pie1: '#67cbe4', pie2: '#de8dc3', pie3: '#74caa6', pie4: '#bbc175',  /* --data-1..4 */
      },
    });
    // Fail loudly: without the overlay div, click-to-zoom silently dies on a bare
    // TypeError that points nowhere near the missing element.
    const overlay = document.getElementById('mermaid-zoom');
    if (!overlay) throw new Error('mermaid.js requires <div class="mermaid-overlay" id="mermaid-zoom"></div> as the first child of <body>');
    const dismiss = () => { overlay.classList.remove('active'); };
    overlay.addEventListener('transitionend', () => { if (!overlay.classList.contains('active')) overlay.innerHTML = ''; });
    document.querySelectorAll('pre.mermaid').forEach(pre => {
      new MutationObserver(() => {
        const svg = pre.querySelector('svg');
        if (svg) svg.addEventListener('click', () => {
          const zoomed = svg.cloneNode(true);
          // Strip mermaid's own sizing so the overlay's CSS governs it, identically
          // for every diagram. calculateSvgSizeAttrs writes width="100%" plus an
          // INLINE style="max-width:NNNpx" when flowchart.useMaxWidth is true (the
          // default), and width/height attributes when it is false (what the
          // connections maps set). An inline max-width outranks the stylesheet, so
          // left in place the zoom magnifies in one layout and does nothing in the
          // other. setupGraphViewbox always emits a viewBox, and that is what scales.
          zoomed.removeAttribute('width');
          zoomed.removeAttribute('height');
          zoomed.style.maxWidth = zoomed.style.width = zoomed.style.height = '';
          overlay.replaceChildren(zoomed);
          overlay.classList.add('active');
        });
      }).observe(pre, { childList: true });
    });
    overlay.addEventListener('click', dismiss);
    document.addEventListener('keydown', e => { if (e.key === 'Escape') dismiss(); });
  </script>