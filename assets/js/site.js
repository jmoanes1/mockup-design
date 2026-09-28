/* ==========================================================================
   Grip op China / Yu Shan Management - redesign mockup
   Progressive enhancement only: the pages work fully without this file.
   ========================================================================== */
(function () {
  "use strict";

  var body = document.body;
  var header = document.querySelector(".site-header");
  var toggle = document.querySelector(".nav-toggle");

  /* --- Sticky header state --------------------------------------------- */
  function onScroll() {
    if (header) header.classList.toggle("is-scrolled", window.scrollY > 8);
  }
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  /* --- Mobile navigation ------------------------------------------------ */
  function closeNav() {
    body.classList.remove("nav-open");
    if (toggle) toggle.setAttribute("aria-expanded", "false");
  }

  if (toggle) {
    toggle.addEventListener("click", function () {
      var open = body.classList.toggle("nav-open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
  }

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") closeNav();
  });

  document.addEventListener("click", function (event) {
    if (!body.classList.contains("nav-open")) return;
    if (event.target.closest(".nav") || event.target.closest(".nav-toggle")) return;
    closeNav();
  });

  window.addEventListener("resize", function () {
    if (window.innerWidth > 980) closeNav();
  });

  Array.prototype.forEach.call(document.querySelectorAll(".nav a"), function (link) {
    link.addEventListener("click", closeNav);
  });

  /* --- Reveal on scroll ------------------------------------------------- */
  var revealItems = document.querySelectorAll(".reveal");
  var revealed = 0;

  function revealAll() {
    Array.prototype.forEach.call(revealItems, function (el) {
      el.classList.add("is-visible");
    });
  }

  if (revealItems.length) {
    if (!("IntersectionObserver" in window)) {
      revealAll();
    } else {
      var observer = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) {
              entry.target.classList.add("is-visible");
              revealed++;
              observer.unobserve(entry.target);
            }
          });
        },
        { rootMargin: "0px 0px -6% 0px", threshold: 0.1 }
      );

      Array.prototype.forEach.call(revealItems, function (el) {
        observer.observe(el);
      });

      /* Safety net: never leave content hidden in environments where the
         observer does not run (print, screenshot tools, odd engines). */
      window.addEventListener("load", function () {
        window.setTimeout(function () {
          if (revealed === 0) revealAll();
        }, 1200);
      });
    }
  }

  /* --- Footer year ------------------------------------------------------ */
  Array.prototype.forEach.call(document.querySelectorAll("[data-year]"), function (el) {
    el.textContent = String(new Date().getFullYear());
  });

  /* --- Forms: this mockup has no backend -------------------------------- */
  Array.prototype.forEach.call(document.querySelectorAll("[data-mockup-form]"), function (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      var status = form.querySelector("[data-form-status]");
      if (status) status.hidden = false;
    });
  });
})();
