(() => {
  document.querySelectorAll('[data-current]').forEach(a => {
    if (a.dataset.current === document.body.dataset.page) a.classList.add('active');
  });

  const btn = document.getElementById('mobileMenu');
  if (btn) btn.onclick = () => document.body.classList.toggle('nav-open');

  document.querySelectorAll('.sidebar a').forEach(a =>
    a.addEventListener('click', () => document.body.classList.remove('nav-open'))
  );

  const images = document.querySelectorAll('.figure img');
  if (images.length) {
    const box = document.createElement('div');
    box.className = 'lightbox';
    box.innerHTML = '<button aria-label="Close">×</button><img alt="Expanded screenshot">';
    document.body.appendChild(box);

    images.forEach(img => img.addEventListener('click', () => {
      box.querySelector('img').src = img.src;
      box.querySelector('img').alt = img.alt || 'Expanded screenshot';
      box.classList.add('open');
    }));

    box.addEventListener('click', e => {
      if (e.target === box || e.target.tagName === 'BUTTON') box.classList.remove('open');
    });
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape') box.classList.remove('open');
    });
  }
})();