const menuButton = document.querySelector('[data-menu-button]');
const navLinks = document.querySelector('[data-nav-links]');
const siteHeader = document.querySelector('.site-header');
const backToTop = document.querySelector('[data-back-to-top]');

if (menuButton && navLinks) {
  menuButton.addEventListener('click', () => {
    navLinks.classList.toggle('open');
    menuButton.setAttribute('aria-expanded', navLinks.classList.contains('open') ? 'true' : 'false');
  });

  navLinks.addEventListener('click', (event) => {
    if (event.target.closest('a')) {
      navLinks.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
    }
  });
}

if (siteHeader) {
  let compact = false;

  const updateHeader = () => {
    const y = window.scrollY;

    if (!compact && y > 80) {
      compact = true;
      siteHeader.classList.add('is-compact');
    } else if (compact && y < 20) {
      compact = false;
      siteHeader.classList.remove('is-compact');
    }
  };

  updateHeader();
  window.addEventListener('scroll', updateHeader, { passive: true });
}

if (backToTop) {
  const updateBackToTop = () => {
    backToTop.classList.toggle('is-visible', window.scrollY > 900);
  };

  backToTop.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  updateBackToTop();
  window.addEventListener('scroll', updateBackToTop, { passive: true });
}
