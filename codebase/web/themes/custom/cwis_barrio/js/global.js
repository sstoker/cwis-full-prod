(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.cwisBarrio = {
    attach: function (context, settings) {
      // Nav menu dropdown: click to expand/collapse (works on desktop + mobile)
      once('cwis-barrio-mobile-dropdown', 'body', context).forEach(function () {
        var lastHandled = 0;

        function handleDropdownToggle(e) {
          var toggle = e.target.closest('a.dropdown-toggle, .dropdown-toggle');
          if (!toggle) return;

          var dropdown = toggle.closest('.dropdown');
          if (!dropdown) return;

          // Must be inside navbar or offcanvas (main menu area)
          var container = dropdown.closest('#CollapsingNavbar, .navbar-collapse, .offcanvas, nav.navbar');
          if (!container) return;

          var menuEl = toggle.nextElementSibling;
          if (!menuEl || !menuEl.classList.contains('dropdown-menu')) return;

          e.preventDefault();
          e.stopPropagation();

          // Prevent double-fire when both pointerdown and click fire
          var now = Date.now();
          if (now - lastHandled < 400) return;
          lastHandled = now;

          var isOpen = menuEl.classList.contains('show');

          // Close other open dropdowns (accordion-style on mobile)
          var openMenus = container.querySelectorAll('.dropdown-menu.show');
          for (var i = 0; i < openMenus.length; i++) {
            if (openMenus[i] !== menuEl) {
              openMenus[i].classList.remove('show');
              var openToggle = openMenus[i].previousElementSibling;
              if (openToggle) openToggle.setAttribute('aria-expanded', 'false');
            }
          }

          menuEl.classList.toggle('show');
          toggle.setAttribute('aria-expanded', !isOpen);
        }

        function closeDropdownsOutside(e) {
          if (e.target.closest('.dropdown-toggle') || e.target.closest('.dropdown-menu a')) return;
          var openMenus = document.querySelectorAll('.navbar .dropdown-menu.show, .navbar-collapse .dropdown-menu.show, .offcanvas .dropdown-menu.show');
          for (var i = 0; i < openMenus.length; i++) {
            openMenus[i].classList.remove('show');
            var t = openMenus[i].previousElementSibling;
            if (t) t.setAttribute('aria-expanded', 'false');
          }
        }

        document.addEventListener('touchstart', handleDropdownToggle, { capture: true, passive: false });
        document.addEventListener('pointerdown', handleDropdownToggle, true);
        document.addEventListener('click', handleDropdownToggle, true);
        document.addEventListener('click', closeDropdownsOutside, true);
      });
    }
  };

})(Drupal, once);
