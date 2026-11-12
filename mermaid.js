  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@12.2.0/dist/mermaid.esm.min.mjs';
    const mermaidScheme = getComputedStyle(document.documentElement).getPropertyValue('--mermaid-scheme').trim();
    const mermaidLight = mermaidScheme === 'light' || mermaidScheme === 'light-christmas';
    const mermaidFont = '"JetBrains Mono", ui-monospace, "Fira Code", monospace';
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
      archEdgeColor:       '#979fc4',
      archGroupBorderColor: '#707388',
      xyChart: {
        backgroundColor: '#282a36',
        titleColor: '#b7bfe4',
        dataLabelColor: '#f8f8f2',
        legendTextColor: '#f8f8f2',
        xAxisLabelColor: '#f8f8f2',
        yAxisLabelColor: '#f8f8f2',
        xAxisTitleColor: '#f8f8f2',
        yAxisTitleColor: '#f8f8f2',
        xAxisTickColor: '#979fc4',
        yAxisTickColor: '#979fc4',
        xAxisLineColor: '#979fc4',
        yAxisLineColor: '#979fc4',
        plotColorPalette: '#96bef0',
      },
    };
    const mermaidLightVars = {
      background:          '#f0f1f9',
      mainBkg:             '#f0f1f9',
      primaryColor:        '#f0f1f9',
      primaryTextColor:    '#161616',
      primaryBorderColor:  '#804cc2',
      lineColor:           '#626a8c',
      textColor:           '#161616',
      secondaryColor:      '#efefea',
      clusterBkg:          '#f0f1f9',
      clusterBorder:       '#7b7f94',
      nodeBorder:          '#804cc2',
      edgeLabelBackground: '#f0f1f9',
      noteBkgColor:        '#f0f1f9',
      noteTextColor:       '#161616',
      noteBorderColor:     '#7b7f94',
      archEdgeColor:       '#626a8c',
      archGroupBorderColor: '#7b7f94',
      xyChart: {
        backgroundColor: '#fcfcf8',
        titleColor: '#525879',
        dataLabelColor: '#161616',
        legendTextColor: '#161616',
        xAxisLabelColor: '#161616',
        yAxisLabelColor: '#161616',
        xAxisTitleColor: '#161616',
        yAxisTitleColor: '#161616',
        xAxisTickColor: '#626a8c',
        yAxisTickColor: '#626a8c',
        xAxisLineColor: '#626a8c',
        yAxisLineColor: '#626a8c',
        plotColorPalette: '#3c88e4',
      },
    };
    const mermaidChristmas = {
      background:          '#243a2c',
      mainBkg:             '#243a2c',
      primaryColor:        '#243a2c',
      primaryTextColor:    '#faf8ef',
      primaryBorderColor:  '#4ab769',
      lineColor:           '#9ebaa2',
      textColor:           '#faf8ef',
      secondaryColor:      '#0d1e13',
      clusterBkg:          '#243a2c',
      clusterBorder:       '#5d7e68',
      nodeBorder:          '#4ab769',
      edgeLabelBackground: '#243a2c',
      noteBkgColor:        '#243a2c',
      noteTextColor:       '#faf8ef',
      noteBorderColor:     '#5d7e68',
      archEdgeColor:       '#9ebaa2',
      archGroupBorderColor: '#5d7e68',
      xyChart: {
        backgroundColor: '#182c1f',
        titleColor: '#b3d0b8',
        dataLabelColor: '#faf8ef',
        legendTextColor: '#faf8ef',
        xAxisLabelColor: '#faf8ef',
        yAxisLabelColor: '#faf8ef',
        xAxisTitleColor: '#faf8ef',
        yAxisTitleColor: '#faf8ef',
        xAxisTickColor: '#9ebaa2',
        yAxisTickColor: '#9ebaa2',
        xAxisLineColor: '#9ebaa2',
        yAxisLineColor: '#9ebaa2',
        plotColorPalette: '#97bef0',
      },
    };
    const mermaidChristmasLight = {
      background:          '#edf5ee',
      mainBkg:             '#edf5ee',
      primaryColor:        '#edf5ee',
      primaryTextColor:    '#101511',
      primaryBorderColor:  '#26753e',
      lineColor:           '#4f6c54',
      textColor:           '#101511',
      secondaryColor:      '#f0ebd8',
      clusterBkg:          '#edf5ee',
      clusterBorder:       '#738a77',
      nodeBorder:          '#26753e',
      edgeLabelBackground: '#edf5ee',
      noteBkgColor:        '#edf5ee',
      noteTextColor:       '#101511',
      noteBorderColor:     '#738a77',
      archEdgeColor:       '#4f6c54',
      archGroupBorderColor: '#738a77',
      xyChart: {
        backgroundColor: '#fdf9ea',
        titleColor: '#405f46',
        dataLabelColor: '#101511',
        legendTextColor: '#101511',
        xAxisLabelColor: '#101511',
        yAxisLabelColor: '#101511',
        xAxisTitleColor: '#101511',
        yAxisTitleColor: '#101511',
        xAxisTickColor: '#4f6c54',
        yAxisTickColor: '#4f6c54',
        xAxisLineColor: '#4f6c54',
        yAxisLineColor: '#4f6c54',
        plotColorPalette: '#3c88e4',
      },
    };
    const mermaidVars = new Map([['light', mermaidLightVars], ['christmas', mermaidChristmas], ['light-christmas', mermaidChristmasLight]]);
    mermaid.initialize({
      startOnLoad: true, theme: 'base', look: 'classic',
      securityLevel: window.mermaidSecurityLevel || 'strict',
      fontFamily: mermaidFont,
      themeVariables: {
        darkMode: !mermaidLight,
        fontFamily: mermaidFont,
        fontSize:   '1rem',
        ...(mermaidVars.get(mermaidScheme) ?? mermaidDark),
      },
    });
    const sourceMeta = new WeakMap();
    const accField = (text, key) => {
      const match = text.match(new RegExp('^\\s*' + key + ':\\s*(.+?)\\s*$', 'im'));
      return match ? match[1].replace(/^["']|["']$/g, '') : '';
    };
    document.querySelectorAll('pre.mermaid').forEach(pre => {
      sourceMeta.set(pre, { title: accField(pre.textContent, 'accTitle'), descr: accField(pre.textContent, 'accDescr') });
    });
    const overlay = document.getElementById('mermaid-zoom');
    if (!overlay) throw new Error('mermaid.js requires <dialog class="mermaid-overlay" id="mermaid-zoom"></dialog> as the first child of <body>');
    const zoomLabel = window.mermaidZoomLabel || 'Zoom diagram';
    const regionLabel = window.mermaidRegionLabel || 'Scrollable diagram';
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
    const scrolls = window.matchMedia('(max-width: 600px)');
    const syncRegions = () => {
      document.querySelectorAll('pre.mermaid').forEach(pre => {
        const svg = pre.querySelector('svg');
        if (!svg) return;
        if (scrolls.matches) {
          pre.tabIndex = 0;
          pre.setAttribute('role', 'region');
          pre.setAttribute('aria-label', regionLabel);
        } else {
          pre.removeAttribute('tabindex');
          pre.removeAttribute('role');
          pre.removeAttribute('aria-label');
        }
      });
    };
    scrolls.addEventListener('change', syncRegions);
    const zoomBound = new WeakSet();
    document.querySelectorAll('pre.mermaid').forEach(pre => {
      new MutationObserver(() => {
        const svg = pre.querySelector('svg');
        if (!svg) return;
        if (!svg.querySelector('title')) {
          const meta = sourceMeta.get(pre);
          if (meta && meta.title) {
            if (meta.descr) {
              const desc = document.createElementNS('http://www.w3.org/2000/svg', 'desc');
              desc.textContent = meta.descr;
              svg.prepend(desc);
            }
            const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
            title.textContent = meta.title;
            svg.prepend(title);
          }
        }
        if (!zoomBound.has(svg)) {
          zoomBound.add(svg);
          svg.addEventListener('click', e => { if (!e.target.closest('a')) zoom(svg); });
        }
        if (svg.style.maxWidth) svg.style.setProperty('--natural-width', svg.style.maxWidth);
        syncRegions();
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
