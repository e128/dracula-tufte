  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@12.3.0/dist/mermaid.esm.min.mjs';
    const mermaidScheme = getComputedStyle(document.documentElement).getPropertyValue('--mermaid-scheme').trim();
    const mermaidLight = mermaidScheme === 'light' || mermaidScheme.startsWith('light-');
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
    const mermaidThanksgiving = {
      background:           '#3b2a1e',
      mainBkg:              '#3b2a1e',
      primaryColor:         '#3b2a1e',
      primaryTextColor:     '#f9f6eb',
      primaryBorderColor:   '#c287bc',
      lineColor:            '#c0ae95',
      textColor:            '#f9f6eb',
      secondaryColor:       '#1b1008',
      clusterBkg:           '#3b2a1e',
      clusterBorder:        '#867162',
      nodeBorder:           '#c287bc',
      edgeLabelBackground:  '#3b2a1e',
      noteBkgColor:         '#3b2a1e',
      noteTextColor:        '#f9f6eb',
      noteBorderColor:      '#867162',
      archEdgeColor:        '#c0ae95',
      archGroupBorderColor: '#867162',
      xyChart: {
        backgroundColor:      '#291b0f',
        titleColor:           '#d9c4a8',
        dataLabelColor:       '#f9f6eb',
        legendTextColor:      '#f9f6eb',
        xAxisLabelColor:      '#f9f6eb',
        yAxisLabelColor:      '#f9f6eb',
        xAxisTitleColor:      '#f9f6eb',
        yAxisTitleColor:      '#f9f6eb',
        xAxisTickColor:       '#c0ae95',
        yAxisTickColor:       '#c0ae95',
        xAxisLineColor:       '#c0ae95',
        yAxisLineColor:       '#c0ae95',
        plotColorPalette:     '#97bef0',
      },
    };
    const mermaidThanksgivingLight = {
      background:           '#f5e9d9',
      mainBkg:              '#f5e9d9',
      primaryColor:         '#f5e9d9',
      primaryTextColor:     '#19120e',
      primaryBorderColor:   '#843780',
      lineColor:            '#795d46',
      textColor:            '#19120e',
      secondaryColor:       '#f5dfc3',
      clusterBkg:           '#f5e9d9',
      clusterBorder:        '#937f6e',
      nodeBorder:           '#843780',
      edgeLabelBackground:  '#f5e9d9',
      noteBkgColor:         '#f5e9d9',
      noteTextColor:        '#19120e',
      noteBorderColor:      '#937f6e',
      archEdgeColor:        '#795d46',
      archGroupBorderColor: '#937f6e',
      xyChart: {
        backgroundColor:      '#feedd8',
        titleColor:           '#6e4f37',
        dataLabelColor:       '#19120e',
        legendTextColor:      '#19120e',
        xAxisLabelColor:      '#19120e',
        yAxisLabelColor:      '#19120e',
        xAxisTitleColor:      '#19120e',
        yAxisTitleColor:      '#19120e',
        xAxisTickColor:       '#795d46',
        yAxisTickColor:       '#795d46',
        xAxisLineColor:       '#795d46',
        yAxisLineColor:       '#795d46',
        plotColorPalette:     '#3c88e3',
      },
    };
    const mermaidChartreuse = {
      background:           '#454a04',
      mainBkg:              '#454a04',
      primaryColor:         '#454a04',
      primaryTextColor:     '#f7f8ed',
      primaryBorderColor:   '#b5df76',
      lineColor:            '#cbcfa6',
      textColor:            '#f7f8ed',
      secondaryColor:       '#3f4405',
      clusterBkg:           '#454a04',
      clusterBorder:        '#b0b591',
      nodeBorder:           '#b5df76',
      edgeLabelBackground:  '#454a04',
      noteBkgColor:         '#454a04',
      noteTextColor:        '#f7f8ed',
      noteBorderColor:      '#b0b591',
      archEdgeColor:        '#cbcfa6',
      archGroupBorderColor: '#b0b591',
      backgroundColor:      '#4d5208',
      titleColor:           '#dee3b5',
      dataLabelColor:       '#f7f8ed',
      legendTextColor:      '#f7f8ed',
      xAxisLabelColor:      '#f7f8ed',
      yAxisLabelColor:      '#f7f8ed',
      xAxisTitleColor:      '#f7f8ed',
      yAxisTitleColor:      '#f7f8ed',
      xAxisTickColor:       '#cbcfa6',
      yAxisTickColor:       '#cbcfa6',
      xAxisLineColor:       '#cbcfa6',
      yAxisLineColor:       '#cbcfa6',
      xyChart: {
        backgroundColor:      '#4d5208',
        titleColor:           '#dee3b5',
        dataLabelColor:       '#f7f8ed',
        legendTextColor:      '#f7f8ed',
        xAxisLabelColor:      '#f7f8ed',
        yAxisLabelColor:      '#f7f8ed',
        xAxisTitleColor:      '#f7f8ed',
        yAxisTitleColor:      '#f7f8ed',
        xAxisTickColor:       '#cbcfa6',
        yAxisTickColor:       '#cbcfa6',
        xAxisLineColor:       '#cbcfa6',
        yAxisLineColor:       '#cbcfa6',
        plotColorPalette:     '#97bef0',
      },
    };
    const mermaidChartreuseLight = {
      background:           '#d6ef51',
      mainBkg:              '#d6ef51',
      primaryColor:         '#d6ef51',
      primaryTextColor:     '#13150e',
      primaryBorderColor:   '#4c5527',
      lineColor:            '#4a5223',
      textColor:            '#13150e',
      secondaryColor:       '#c2db21',
      clusterBkg:           '#d6ef51',
      clusterBorder:        '#707b43',
      nodeBorder:           '#4c5527',
      edgeLabelBackground:  '#d6ef51',
      noteBkgColor:         '#d6ef51',
      noteTextColor:        '#13150e',
      noteBorderColor:      '#707b43',
      archEdgeColor:        '#4a5223',
      archGroupBorderColor: '#707b43',
      backgroundColor:      '#cce630',
      titleColor:           '#3f4718',
      dataLabelColor:       '#13150e',
      legendTextColor:      '#13150e',
      xAxisLabelColor:      '#13150e',
      yAxisLabelColor:      '#13150e',
      xAxisTitleColor:      '#13150e',
      yAxisTitleColor:      '#13150e',
      xAxisTickColor:       '#4a5223',
      yAxisTickColor:       '#4a5223',
      xAxisLineColor:       '#4a5223',
      yAxisLineColor:       '#4a5223',
      xyChart: {
        backgroundColor:      '#cce630',
        titleColor:           '#3f4718',
        dataLabelColor:       '#13150e',
        legendTextColor:      '#13150e',
        xAxisLabelColor:      '#13150e',
        yAxisLabelColor:      '#13150e',
        xAxisTitleColor:      '#13150e',
        yAxisTitleColor:      '#13150e',
        xAxisTickColor:       '#4a5223',
        yAxisTickColor:       '#4a5223',
        xAxisLineColor:       '#4a5223',
        yAxisLineColor:       '#4a5223',
        plotColorPalette:     '#1a6dca',
      },
    };
    const mermaidStPatrick = {
      background:           '#0c4128',
      mainBkg:              '#0c4128',
      primaryColor:         '#0c4128',
      primaryTextColor:     '#f4f9f0',
      primaryBorderColor:   '#61da92',
      lineColor:            '#9eba9e',
      textColor:            '#f4f9f0',
      secondaryColor:       '#012514',
      clusterBkg:           '#0c4128',
      clusterBorder:        '#708d79',
      nodeBorder:           '#61da92',
      edgeLabelBackground:  '#0c4128',
      noteBkgColor:         '#0c4128',
      noteTextColor:        '#f4f9f0',
      noteBorderColor:      '#708d79',
      archEdgeColor:        '#9eba9e',
      archGroupBorderColor: '#708d79',
      backgroundColor:      '#02331d',
      titleColor:           '#b5d5b5',
      dataLabelColor:       '#f4f9f0',
      legendTextColor:      '#f4f9f0',
      xAxisLabelColor:      '#f4f9f0',
      yAxisLabelColor:      '#f4f9f0',
      xAxisTitleColor:      '#f4f9f0',
      yAxisTitleColor:      '#f4f9f0',
      xAxisTickColor:       '#9eba9e',
      yAxisTickColor:       '#9eba9e',
      xAxisLineColor:       '#9eba9e',
      yAxisLineColor:       '#9eba9e',
      xyChart: {
        backgroundColor:      '#02331d',
        titleColor:           '#b5d5b5',
        dataLabelColor:       '#f4f9f0',
        legendTextColor:      '#f4f9f0',
        xAxisLabelColor:      '#f4f9f0',
        yAxisLabelColor:      '#f4f9f0',
        xAxisTitleColor:      '#f4f9f0',
        yAxisTitleColor:      '#f4f9f0',
        xAxisTickColor:       '#9eba9e',
        yAxisTickColor:       '#9eba9e',
        xAxisLineColor:       '#9eba9e',
        yAxisLineColor:       '#9eba9e',
        plotColorPalette:     '#97bef0',
      },
    };
    const mermaidStPatrickLight = {
      background:           '#d4f1d8',
      mainBkg:              '#d4f1d8',
      primaryColor:         '#d4f1d8',
      primaryTextColor:     '#0c1610',
      primaryBorderColor:   '#266741',
      lineColor:            '#476a53',
      textColor:            '#0c1610',
      secondaryColor:       '#c8ecce',
      clusterBkg:           '#d4f1d8',
      clusterBorder:        '#6b8975',
      nodeBorder:           '#266741',
      edgeLabelBackground:  '#d4f1d8',
      noteBkgColor:         '#d4f1d8',
      noteTextColor:        '#0c1610',
      noteBorderColor:      '#6b8975',
      archEdgeColor:        '#476a53',
      archGroupBorderColor: '#6b8975',
      backgroundColor:      '#d6f7dc',
      titleColor:           '#365c44',
      dataLabelColor:       '#0c1610',
      legendTextColor:      '#0c1610',
      xAxisLabelColor:      '#0c1610',
      yAxisLabelColor:      '#0c1610',
      xAxisTitleColor:      '#0c1610',
      yAxisTitleColor:      '#0c1610',
      xAxisTickColor:       '#476a53',
      yAxisTickColor:       '#476a53',
      xAxisLineColor:       '#476a53',
      yAxisLineColor:       '#476a53',
      xyChart: {
        backgroundColor:      '#d6f7dc',
        titleColor:           '#365c44',
        dataLabelColor:       '#0c1610',
        legendTextColor:      '#0c1610',
        xAxisLabelColor:      '#0c1610',
        yAxisLabelColor:      '#0c1610',
        xAxisTitleColor:      '#0c1610',
        yAxisTitleColor:      '#0c1610',
        xAxisTickColor:       '#476a53',
        yAxisTickColor:       '#476a53',
        xAxisLineColor:       '#476a53',
        yAxisLineColor:       '#476a53',
        plotColorPalette:     '#3886e3',
      },
    };
    const mermaidIndependenceDay = {
      background:           '#1b2948',
      mainBkg:              '#1b2948',
      primaryColor:         '#1b2948',
      primaryTextColor:     '#f2f7fd',
      primaryBorderColor:   '#82a3ec',
      lineColor:            '#9eb4ca',
      textColor:            '#f2f7fd',
      secondaryColor:       '#071129',
      clusterBkg:           '#1b2948',
      clusterBorder:        '#6e829b',
      nodeBorder:           '#82a3ec',
      edgeLabelBackground:  '#1b2948',
      noteBkgColor:         '#1b2948',
      noteTextColor:        '#f2f7fd',
      noteBorderColor:      '#6e829b',
      archEdgeColor:        '#9eb4ca',
      archGroupBorderColor: '#6e829b',
      backgroundColor:      '#101d38',
      titleColor:           '#b8cde4',
      dataLabelColor:       '#f2f7fd',
      legendTextColor:      '#f2f7fd',
      xAxisLabelColor:      '#f2f7fd',
      yAxisLabelColor:      '#f2f7fd',
      xAxisTitleColor:      '#f2f7fd',
      yAxisTitleColor:      '#f2f7fd',
      xAxisTickColor:       '#9eb4ca',
      yAxisTickColor:       '#9eb4ca',
      xAxisLineColor:       '#9eb4ca',
      yAxisLineColor:       '#9eb4ca',
      xyChart: {
        backgroundColor:      '#101d38',
        titleColor:           '#b8cde4',
        dataLabelColor:       '#f2f7fd',
        legendTextColor:      '#f2f7fd',
        xAxisLabelColor:      '#f2f7fd',
        yAxisLabelColor:      '#f2f7fd',
        xAxisTitleColor:      '#f2f7fd',
        yAxisTitleColor:      '#f2f7fd',
        xAxisTickColor:       '#9eb4ca',
        yAxisTickColor:       '#9eb4ca',
        xAxisLineColor:       '#9eb4ca',
        yAxisLineColor:       '#9eb4ca',
        plotColorPalette:     '#97bef0',
      },
    };
    const mermaidIndependenceDayLight = {
      background:           '#e1effd',
      mainBkg:              '#e1effd',
      primaryColor:         '#e1effd',
      primaryTextColor:     '#0f141d',
      primaryBorderColor:   '#224ac0',
      lineColor:            '#52617a',
      textColor:            '#0f141d',
      secondaryColor:       '#d8e8fa',
      clusterBkg:           '#e1effd',
      clusterBorder:        '#728199',
      nodeBorder:           '#224ac0',
      edgeLabelBackground:  '#e1effd',
      noteBkgColor:         '#e1effd',
      noteTextColor:        '#0f141d',
      noteBorderColor:      '#728199',
      archEdgeColor:        '#52617a',
      archGroupBorderColor: '#728199',
      backgroundColor:      '#e8f3ff',
      titleColor:           '#42536e',
      dataLabelColor:       '#0f141d',
      legendTextColor:      '#0f141d',
      xAxisLabelColor:      '#0f141d',
      yAxisLabelColor:      '#0f141d',
      xAxisTitleColor:      '#0f141d',
      yAxisTitleColor:      '#0f141d',
      xAxisTickColor:       '#52617a',
      yAxisTickColor:       '#52617a',
      xAxisLineColor:       '#52617a',
      yAxisLineColor:       '#52617a',
      xyChart: {
        backgroundColor:      '#e8f3ff',
        titleColor:           '#42536e',
        dataLabelColor:       '#0f141d',
        legendTextColor:      '#0f141d',
        xAxisLabelColor:      '#0f141d',
        yAxisLabelColor:      '#0f141d',
        xAxisTitleColor:      '#0f141d',
        yAxisTitleColor:      '#0f141d',
        xAxisTickColor:       '#52617a',
        yAxisTickColor:       '#52617a',
        xAxisLineColor:       '#52617a',
        yAxisLineColor:       '#52617a',
        plotColorPalette:     '#3886e3',
      },
    };
    const mermaidPoland = {
      background:           '#491d1d',
      mainBkg:              '#491d1d',
      primaryColor:         '#491d1d',
      primaryTextColor:     '#f8f7f2',
      primaryBorderColor:   '#d87ca9',
      lineColor:            '#c0b29c',
      textColor:            '#f8f7f2',
      secondaryColor:       '#27080a',
      clusterBkg:           '#491d1d',
      clusterBorder:        '#9c7571',
      nodeBorder:           '#d87ca9',
      edgeLabelBackground:  '#491d1d',
      noteBkgColor:         '#491d1d',
      noteTextColor:        '#f8f7f2',
      noteBorderColor:      '#9c7571',
      archEdgeColor:        '#c0b29c',
      archGroupBorderColor: '#9c7571',
      xyChart: {
        backgroundColor:    '#371111',
        titleColor:         '#daccb5',
        dataLabelColor:     '#f8f7f2',
        legendTextColor:    '#f8f7f2',
        xAxisLabelColor:    '#f8f7f2',
        yAxisLabelColor:    '#f8f7f2',
        xAxisTitleColor:    '#f8f7f2',
        yAxisTitleColor:    '#f8f7f2',
        xAxisTickColor:     '#c0b29c',
        yAxisTickColor:     '#c0b29c',
        xAxisLineColor:     '#c0b29c',
        yAxisLineColor:     '#c0b29c',
        plotColorPalette:   '#e2b349',
      },
    };
    const mermaidPolandLight = {
      background:           '#f8e4e2',
      mainBkg:              '#f8e4e2',
      primaryColor:         '#f8e4e2',
      primaryTextColor:     '#221010',
      primaryBorderColor:   '#8e3565',
      lineColor:            '#84504c',
      textColor:            '#221010',
      secondaryColor:       '#f5dcda',
      clusterBkg:           '#f8e4e2',
      clusterBorder:        '#9f7470',
      nodeBorder:           '#8e3565',
      edgeLabelBackground:  '#f8e4e2',
      noteBkgColor:         '#f8e4e2',
      noteTextColor:        '#221010',
      noteBorderColor:      '#9f7470',
      archEdgeColor:        '#84504c',
      archGroupBorderColor: '#9f7470',
      xyChart: {
        backgroundColor:    '#fceae8',
        titleColor:         '#893130',
        dataLabelColor:     '#221010',
        legendTextColor:    '#221010',
        xAxisLabelColor:    '#221010',
        yAxisLabelColor:    '#221010',
        xAxisTitleColor:    '#221010',
        yAxisTitleColor:    '#221010',
        xAxisTickColor:     '#84504c',
        yAxisTickColor:     '#84504c',
        xAxisLineColor:     '#84504c',
        yAxisLineColor:     '#84504c',
        plotColorPalette:   '#9f7e32',
      },
    };
    const mermaidVars = new Map([['light', mermaidLightVars], ['christmas', mermaidChristmas], ['light-christmas', mermaidChristmasLight], ['thanksgiving', mermaidThanksgiving], ['light-thanksgiving', mermaidThanksgivingLight], ['chartreuse', mermaidChartreuse], ['light-chartreuse', mermaidChartreuseLight], ['st-patrick', mermaidStPatrick], ['light-st-patrick', mermaidStPatrickLight], ['independence-day', mermaidIndependenceDay], ['light-independence-day', mermaidIndependenceDayLight], ['poland', mermaidPoland], ['light-poland', mermaidPolandLight]]);
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
