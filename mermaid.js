  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.17.2/dist/mermaid.esm.min.mjs';
    const elkPres = [...document.querySelectorAll('pre.mermaid')].filter(pre => /layout:\s*elk/.test(pre.textContent));
    if (elkPres.length) {
      import('https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0.2.3/dist/mermaid-layout-elk.esm.min.mjs')
        .then(elkLayouts => {
          mermaid.registerLayoutLoaders(elkLayouts.default);
          return mermaid.run({ nodes: elkPres });
        })
        .catch(() => {});
    }
    const mermaidLight = getComputedStyle(document.documentElement).getPropertyValue('--mermaid-scheme').trim() === 'light';
    const mermaidFont = 'ui-monospace, "JetBrains Mono", "Fira Code", monospace';
    const mermaidDark = {
      background:          '#343746',
      mainBkg:             '#343746',
      primaryColor:        '#343746',
      primaryTextColor:    '#f8f8f2',
      primaryBorderColor:  '#aa8cdb',
      lineColor:           '#979fc4',
      textColor:           '#f8f8f2',
      secondaryColor:      '#1e1f29',
      clusterBkg:          '#343746',
      clusterBorder:       '#707388',
      nodeBorder:          '#aa8cdb',
      edgeLabelBackground: '#343746',
      noteBkgColor:        '#343746',
      noteTextColor:       '#f8f8f2',
      noteBorderColor:     '#707388',
      pie1: '#96bef0', pie2: '#ec80cb', pie3: '#4bd1a0', pie4: '#bcc267',
    };
    const mermaidLightVars = {
      background:          '#f0f1f9',
      mainBkg:             '#f0f1f9',
      primaryColor:        '#f0f1f9',
      primaryTextColor:    '#161616',
      primaryBorderColor:  '#7b58ae',
      lineColor:           '#626a8c',
      textColor:           '#161616',
      secondaryColor:      '#efefea',
      clusterBkg:          '#f0f1f9',
      clusterBorder:       '#7b7f94',
      nodeBorder:          '#7b58ae',
      edgeLabelBackground: '#f0f1f9',
      noteBkgColor:        '#f0f1f9',
      noteTextColor:       '#161616',
      noteBorderColor:     '#7b7f94',
      pie1: '#3c88e4', pie2: '#cf5cae', pie3: '#349874', pie4: '#878c48',
    };
    mermaid.initialize({
      startOnLoad: true, theme: 'base',
      securityLevel: window.mermaidSecurityLevel || 'strict',
      fontFamily: mermaidFont,
      themeVariables: {
        darkMode: !mermaidLight,
        fontFamily: mermaidFont,
        fontSize:   '1rem',
        ...(mermaidLight ? mermaidLightVars : mermaidDark),
      },
    });
    const overlay = document.getElementById('mermaid-zoom');
    if (!overlay) throw new Error('mermaid.js requires <dialog class="mermaid-overlay" id="mermaid-zoom"></dialog> as the first child of <body>');
    const zoomLabel = window.mermaidZoomLabel || 'Zoom diagram';
    const titleOf = svg => svg.querySelector('title')?.textContent?.trim();
    const named = (svg, label) => {
      const title = titleOf(svg);
      return title ? label + ': ' + title : label;
    };
    const hide = () => {
      overlay.classList.remove('active');
      overlay.close();
      overlay.innerHTML = '';
    };
    const zoom = svg => {
      const zoomed = svg.cloneNode(true);
      zoomed.removeAttribute('width');
      zoomed.removeAttribute('height');
      zoomed.style.maxWidth = zoomed.style.width = zoomed.style.height = '';
      overlay.setAttribute('aria-label', named(svg, zoomLabel));
      overlay.replaceChildren(zoomed);
      overlay.showModal();
      requestAnimationFrame(() => overlay.classList.add('active'));
    };
    const zoomBound = new WeakSet();
    document.querySelectorAll('pre.mermaid').forEach(pre => {
      new MutationObserver(() => {
        const svg = pre.querySelector('svg');
        if (!svg) return;
        if (!zoomBound.has(svg)) {
          zoomBound.add(svg);
          svg.addEventListener('click', e => { if (!e.target.closest('a')) zoom(svg); });
        }
        if (svg.style.maxWidth) svg.style.setProperty('--natural-width', svg.style.maxWidth);
        pre.tabIndex = 0;
        pre.setAttribute('role', 'region');
        pre.setAttribute('aria-label', titleOf(svg) || zoomLabel);
        if (!pre.querySelector('.mermaid-zoom')) {
          const button = document.createElement('button');
          button.type = 'button';
          button.className = 'mermaid-zoom';
          button.textContent = zoomLabel;
          button.setAttribute('aria-label', named(svg, zoomLabel));
          button.addEventListener('click', () => zoom(svg));
          pre.append(button);
        }
      }).observe(pre, { childList: true });
    });
    overlay.addEventListener('click', hide);
    overlay.addEventListener('cancel', e => { e.preventDefault(); hide(); });
  </script>
