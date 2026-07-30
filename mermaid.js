  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.esm.min.mjs';
    mermaid.initialize({
      startOnLoad: true, theme: 'base',
      securityLevel: window.mermaidSecurityLevel || 'strict',
      themeVariables: {
        darkMode: true,
        fontFamily: 'ui-monospace, "JetBrains Mono", "Fira Code", monospace',
        fontSize:   '1rem',
        background:          '#343746',
        mainBkg:             '#343746',
        primaryColor:        '#343746',
        primaryTextColor:    '#f8f8f2',
        primaryBorderColor:  '#a98ed6',
        lineColor:           '#979fc4',
        textColor:           '#f8f8f2',
        secondaryColor:      '#1e1f29',
        clusterBkg:          '#343746',
        clusterBorder:       '#707388',
        nodeBorder:          '#a98ed6',
        edgeLabelBackground: '#343746',
        pie1: '#99bdec', pie2: '#de8dc3', pie3: '#74caa6', pie4: '#bbc175',
      },
    });
    const overlay = document.getElementById('mermaid-zoom');
    if (!overlay) throw new Error('mermaid.js requires <div class="mermaid-overlay" id="mermaid-zoom"></div> as the first child of <body>');
    const dismiss = () => { overlay.classList.remove('active'); };
    overlay.addEventListener('transitionend', () => { if (!overlay.classList.contains('active')) overlay.innerHTML = ''; });
    document.querySelectorAll('pre.mermaid').forEach(pre => {
      new MutationObserver(() => {
        const svg = pre.querySelector('svg');
        if (svg) svg.addEventListener('click', () => {
          const zoomed = svg.cloneNode(true);
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
