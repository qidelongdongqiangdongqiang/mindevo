(() => {
  const hero = document.querySelector('.future-hero');
  const contact = document.querySelector('#contact');
  const contactBar = document.querySelector('.mobile-sticky');
  if (!hero || !contactBar || !('IntersectionObserver' in window)) return;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      const className = entry.target === hero ? 'camp-hero-visible' : 'camp-contact-visible';
      document.body.classList.toggle(className, entry.isIntersecting);
    });
  }, { threshold: 0.08 });

  observer.observe(hero);
  if (contact) observer.observe(contact);
})();
