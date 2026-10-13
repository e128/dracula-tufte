  <script type="module">
    const blocks = document.querySelectorAll('pre > code[class*="language-"]:not(.hljs)');
    if (blocks.length) {
      const { default: hljs } = await import('https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.11.1/es/highlight.min.js');
      blocks.forEach(block => hljs.highlightElement(block));
    }
  </script>
