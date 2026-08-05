  <script type="module">
    document.querySelectorAll('input.filter-box').forEach(input => {
      let el = input.nextElementSibling;
      while (el && el.tagName !== 'TABLE') el = el.nextElementSibling;
      const table = el;
      if (!table) return;
      const rows = table.querySelectorAll('tbody tr');
      const status = input.parentElement.querySelector('[role="status"]');
      let empty = input.parentElement.querySelector('.filter-empty');
      if (!empty) {
        empty = document.createElement('p');
        empty.className = 'filter-empty';
        empty.hidden = true;
        table.after(empty);
      }
      input.addEventListener('input', () => {
        const q = input.value.trim().toLowerCase();
        let visible = 0;
        rows.forEach(row => {
          const hit = !q || row.textContent.toLowerCase().includes(q);
          row.classList.toggle('filter-hidden', !hit);
          if (hit) visible += 1;
        });
        empty.hidden = visible !== 0;
        if (status) status.textContent = `${visible} ${visible === 1 ? 'entry' : 'entries'}`;
      });
    });
  </script>
