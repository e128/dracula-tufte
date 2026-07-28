  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.esm.min.mjs';
    // Defaults to 'strict' (sanitizes `click <node> "<url>"` directives away).
    // Consumers with a trusted diagram source can opt into 'loose' (renders
    // click directives as navigable links) by setting
    // `window.mermaidSecurityLevel = 'loose'` in a preceding classic script
    // tag (runs before this module script).
    mermaid.initialize({ startOnLoad: true, theme: 'dark', securityLevel: window.mermaidSecurityLevel || 'strict' });
    const overlay = document.getElementById('mermaid-zoom');
    const dismiss = () => { overlay.classList.remove('active'); };
    overlay.addEventListener('transitionend', () => { if (!overlay.classList.contains('active')) overlay.innerHTML = ''; });
    document.querySelectorAll('pre.mermaid').forEach(pre => {
      new MutationObserver(() => {
        const svg = pre.querySelector('svg');
        if (svg) svg.addEventListener('click', () => {
          overlay.innerHTML = ''; overlay.appendChild(svg.cloneNode(true));
          overlay.classList.add('active');
        });
      }).observe(pre, { childList: true });
    });
    overlay.addEventListener('click', dismiss);
    document.addEventListener('keydown', e => { if (e.key === 'Escape') dismiss(); });
  </script>