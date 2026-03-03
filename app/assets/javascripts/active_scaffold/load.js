// ActiveScaffold main entry point
(function() {
  const config = window.ActiveScaffold?.config || {};

  // Load dependencies based on configuration
  const loadDependencies = async () => {
    // Always load these
    await loadScript(RAILS_ASSET_URL('/jquery.ba-throttle-debounce.js'));
    await loadScript(RAILS_ASSET_URL('/jquery.visible.min.js'));

    // Check if jQuery UI should be loaded
    if (config.jqueryUiIncluded) {
      await loadJQueryUI();
    }

    // Load core ActiveScaffold
    await loadScript(RAILS_ASSET_URL('/active_scaffold/active_scaffold.js'));
    await loadScript(RAILS_ASSET_URL('/active_scaffold/jquery.editinplace.js'));

    // Load plugins
    if (config.plugins) {
      for (const plugin of config.plugins) {
        await loadScript(plugin);
      }
    }

    // Load bridges
    if (config.bridges) {
      for (const bridge of config.bridges) {
        await loadScript(bridge);
      }
    }

    // ALL DEPENDENCIES ARE LOADED NOW
    // Initialize everything
    initializeActiveScaffold();
  };

  const loadJQueryUI = async () => {
    // Check if jQuery UI is already loaded via importmap or script tag
    if (typeof window.jQuery?.ui === 'undefined') {
      // If using jquery-ui-rails gem with Sprockets/Propshaft
      // We need to load individual components
      if (config.jqueryUi) {
        for (const file of config.jqueryUi) {
          await loadScript(file);
        }
      } else return;
    }

    // Load jQuery UI addons
    await loadScript(RAILS_ASSET_URL('/jquery-ui-timepicker-addon.js'));
    await loadScript(RAILS_ASSET_URL('/active_scaffold/date_picker_bridge.js'));
    await loadScript(RAILS_ASSET_URL('/active_scaffold/draggable_lists.js'));

    // Initialize jQuery UI components
    initializeJQueryUI();
  };

  const loadScript = (path) => {
    return new Promise((resolve, reject) => {
      // Check if already loaded
      if (document.querySelector(`script[src*="${path}"]`)) {
        resolve();
        return;
      }

      const script = document.createElement('script');
      script.src = path;
      script.async = false;
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  };

  const initializeJQueryUI = function() {
    if (config.jqueryUiIncluded && window.jQuery) {
      // Check if datepicker exists
      if (jQuery.datepicker) {
        // Execute the datepicker localization
        // This will be replaced by actual generated code
        eval(config.datepickerLocalization);
      }
    }
  };

  // NEW: Initialize everything after all scripts are loaded
  const initializeActiveScaffold = () => {
    // Run any post-load initialization
    if (window.jQuery) {
      jQuery(document).trigger('active-scaffold:loaded');
    }
  };

  // Start loading when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadDependencies);
  } else {
    loadDependencies();
  }
})();