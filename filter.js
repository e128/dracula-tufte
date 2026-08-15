  <script type="module">
    document.querySelectorAll('input.filter-box').forEach(input => {
      const scope = [];
      let el = input.nextElementSibling;
      while (el) {
        if (el.matches('input.filter-box') || el.querySelector('input.filter-box')) break;
        scope.push(el);
        el = el.nextElementSibling;
      }
      if (!scope.length) return;
      const rows = [];
      const groups = [];
      scope.forEach(node => {
        rows.push(...node.querySelectorAll('tbody tr, .nav-list > li'));
        if (node.matches('details.nav-group')) groups.push(node);
        groups.push(...node.querySelectorAll('details.nav-group'));
      });
      if (!rows.length) return;
      const wasOpen = groups.map(group => group.open);
      const counts = groups.map(group => group.querySelector('summary .count'));
      const wasCount = counts.map(count => count && count.textContent);
      const status = input.parentElement.querySelector('[role="status"]');
      let empty = input.parentElement.querySelector('.filter-empty');
      if (!empty) {
        empty = document.createElement('p');
        empty.className = 'filter-empty';
        empty.textContent = 'No entries match. Clear the filter to see all entries.';
        empty.hidden = true;
        scope[scope.length - 1].after(empty);
      }
      input.addEventListener('input', () => {
        const q = input.value.trim().toLowerCase();
        let visible = 0;
        rows.forEach(row => {
          const hit = !q || row.textContent.toLowerCase().includes(q);
          row.classList.toggle('filter-hidden', !hit);
          if (hit) visible += 1;
        });
        groups.forEach((group, i) => {
          const shown = group.querySelectorAll('.nav-list > li:not(.filter-hidden)').length;
          group.classList.toggle('filter-hidden', Boolean(q) && shown === 0);
          group.open = q ? shown > 0 : wasOpen[i];
          if (counts[i]) counts[i].textContent = q ? shown : wasCount[i];
        });
        empty.hidden = visible !== 0;
        if (status) status.textContent = `${visible} ${visible === 1 ? 'entry' : 'entries'}`;
      });
    });
  </script>
