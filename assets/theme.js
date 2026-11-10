// Zain Hashmi — theme interactions
(function () {
  'use strict';

  function ready(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  ready(function () {
    document.documentElement.classList.remove('no-js');

    // Sticky header shadow
    var header = document.querySelector('.site-header');
    function onScroll() {
      if (!header) return;
      header.classList.toggle('is-scrolled', window.scrollY > 8);
    }
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();

    // Mobile menu
    var toggle = document.querySelector('.menu-toggle');
    var menu = document.querySelector('.header-menu');
    if (toggle && menu) {
      toggle.addEventListener('click', function () {
        var open = menu.classList.toggle('is-open');
        toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      });
      document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && menu.classList.contains('is-open')) {
          menu.classList.remove('is-open');
          toggle.setAttribute('aria-expanded', 'false');
          toggle.focus();
        }
      });
    }

    // Reveal on scroll
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting) {
            en.target.classList.add('is-visible');
            io.unobserve(en.target);
          }
        });
      }, { threshold: 0.12 });
      document.querySelectorAll('.reveal').forEach(function (el) { io.observe(el); });
    } else {
      document.querySelectorAll('.reveal').forEach(function (el) { el.classList.add('is-visible'); });
    }

    // Toast
    var toast = document.getElementById('Toast');
    var toastTimer = null;
    function showToast(msg) {
      if (!toast) return;
      toast.textContent = msg;
      toast.classList.add('is-visible');
      clearTimeout(toastTimer);
      toastTimer = setTimeout(function () { toast.classList.remove('is-visible'); }, 2600);
    }

    // Cart count refresh
    function refreshCartCount() {
      fetch('/cart.js', { headers: { Accept: 'application/json' } })
        .then(function (r) { return r.json(); })
        .then(function (cart) {
          document.querySelectorAll('[data-cart-count]').forEach(function (el) {
            el.textContent = cart.item_count;
          });
        })
        .catch(function () {});
    }

    // AJAX add to cart with graceful fallback to normal submit
    document.querySelectorAll('form[action="/cart/add"]').forEach(function (form) {
      form.addEventListener('submit', function (e) {
        if (!window.fetch || !FormData) return; // fall back to native POST
        e.preventDefault();
        var btn = form.querySelector('[type="submit"]');
        if (btn) { btn.disabled = true; }
        fetch('/cart/add.js', { method: 'POST', body: new FormData(form), headers: { Accept: 'application/json' } })
          .then(function (r) {
            if (!r.ok) throw new Error('add failed');
            return r.json();
          })
          .then(function () {
            refreshCartCount();
            showToast('Added to your bag');
          })
          .catch(function () { form.submit(); })
          .finally(function () { if (btn) btn.disabled = false; });
      });
    });

    // Product gallery thumbs
    var main = document.querySelector('[data-gallery-main] img');
    document.querySelectorAll('[data-gallery-thumb]').forEach(function (thumb) {
      thumb.addEventListener('click', function () {
        if (!main) return;
        var src = thumb.getAttribute('data-src');
        if (src) main.src = src;
        document.querySelectorAll('[data-gallery-thumb]').forEach(function (t) { t.classList.remove('is-active'); });
        thumb.classList.add('is-active');
      });
    });

    refreshCartCount();
  });
})();