  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
    // securityLevel:'loose' lets `click <node> "<url>"` directives render as
    // navigable links (strict — the default — sanitizes them away).
    mermaid.initialize({ startOnLoad: true, theme: 'dark', securityLevel: 'loose' });
    const overlay = document.getElementById('mermaid-zoom');
    const dismiss = () => { overlay.classList.remove('active'); overlay.innerHTML = ''; };
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