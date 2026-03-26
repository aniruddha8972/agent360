/**
 * AGENT360.IN — UI Helpers
 * Navbar, toast, scroll reveal, hamburger
 */

// ── TOAST ────────────────────────────────────
function showToast(msg, duration = 4000) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), duration);
}

// ── NAVBAR SCROLL SHADOW ──────────────────────
window.addEventListener('scroll', () => {
  const nav = document.getElementById('nav');
  if (nav) {
    nav.style.boxShadow = window.scrollY > 40
      ? '0 4px 30px rgba(60,30,10,.1)'
      : '';
  }
}, { passive: true });

// ── HAMBURGER ────────────────────────────────
document.getElementById('ham')?.addEventListener('click', () => {
  document.getElementById('navLinks')?.classList.toggle('open');
});

// Close nav on link click (mobile)
document.querySelectorAll('.nav-links a').forEach(a => {
  a.addEventListener('click', () => {
    document.getElementById('navLinks')?.classList.remove('open');
  });
});

// ── SCROLL REVEAL ────────────────────────────
const revealObs = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('in');
      // Stagger children if grid parent
      const children = e.target.querySelectorAll('.reveal');
      children.forEach((child, i) => {
        setTimeout(() => child.classList.add('in'), i * 80);
      });
    }
  });
}, { threshold: 0.08 });

document.querySelectorAll('.reveal').forEach(el => revealObs.observe(el));

// ── PROGRESS BAR ANIMATION ───────────────────
// Animate progress fills when they enter view
const progressObs = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      const fill = e.target.querySelector('.progress-fill');
      if (fill) {
        const target = fill.style.width;
        fill.style.width = '0%';
        setTimeout(() => { fill.style.width = target; }, 200);
      }
    }
  });
}, { threshold: 0.3 });

document.querySelectorAll('.progress-wrap').forEach(el => progressObs.observe(el));
