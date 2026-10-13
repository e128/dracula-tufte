  <script type="module">
    const icons = {
      copy: '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V6a2 2 0 0 1 2-2h9"/>',
      done: '<path d="M5 12.5l4.5 4.5L19 7.5"/>'
    };
    const paint = (button, name) => {
      button.innerHTML = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name]}</svg>`;
    };
    if (navigator.clipboard) {
      document.querySelectorAll('pre:not(.mermaid)').forEach(pre => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'copy-code';
        button.setAttribute('aria-label', 'Copy code');
        paint(button, 'copy');
        button.addEventListener('click', async () => {
          try {
            await navigator.clipboard.writeText(pre.textContent);
          } catch { return; }
          paint(button, 'done');
          button.setAttribute('aria-label', 'Copied');
          setTimeout(() => { paint(button, 'copy'); button.setAttribute('aria-label', 'Copy code'); }, 1500);
        });
        pre.prepend(button);
      });
    }
    const blocks = document.querySelectorAll('pre > code[class*="language-"]:not(.hljs)');
    if (blocks.length) {
      const { default: hljs } = await import('https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.11.1/es/highlight.min.js');
      blocks.forEach(block => hljs.highlightElement(block));
    }
  </script>
