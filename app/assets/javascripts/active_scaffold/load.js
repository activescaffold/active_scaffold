// ActiveScaffold main entry point
(function() {
  const config = window.ActiveScaffold?.config || {};
  config.deferInitialSetup = true;
  const scriptLoads = new Map();
  const readyHeld = typeof window.jQuery?.holdReady === 'function';
  if (readyHeld) window.jQuery.holdReady(true);

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

    // Load plugins and bridges in order. Some of them depend on scripts loaded
    // before them and register callbacks while they are being evaluated.
    await loadScripts(config.plugins);
    await loadScripts(config.bridges);

    // ALL DEPENDENCIES ARE LOADED NOW
    // Initialize everything
    await initializeActiveScaffold();
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

  const loadScripts = async (paths = []) => {
    for (const path of paths || []) {
      await loadScript(path);
    }
  };

  const loadScript = (path) => {
    if (scriptLoads.has(path)) return scriptLoads.get(path);

    const promise = new Promise((resolve, reject) => {
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

    scriptLoads.set(path, promise);
    return promise;
  };

  const initializeJQueryUI = function() {
    if (config.jqueryUiIncluded && window.jQuery) {
      applyDatepickerLocalization();
    }
  };

  const applyDatepickerLocalization = () => {
    const localization = config.datepickerLocalization;
    if (!localization) return;
    const { locale, datepickerRegional, timepickerRegional } = localization;

    if (jQuery.datepicker && datepickerRegional) {
      Object.assign(jQuery.datepicker.regional, datepickerRegional);
      if (jQuery.datepicker.regional[locale]) {
        jQuery.datepicker.setDefaults(jQuery.datepicker.regional[locale]);
      }
    }

    if (jQuery.timepicker && timepickerRegional) {
      Object.assign(jQuery.timepicker.regional, timepickerRegional);
      if (jQuery.timepicker.regional[locale]) {
        jQuery.timepicker.setDefaults(jQuery.timepicker.regional[locale]);
      }
    }
  };

  // Initialize only after plugins and bridges are available. This is especially
  // important when this file is loaded as a regular script after DOM ready.
  const initializeActiveScaffold = () => new Promise((resolve) => {
    if (!window.jQuery || !window.ActiveScaffold) {
      resolve();
      return;
    }

    jQuery(function() {
      config.deferInitialSetup = false;
      if ((typeof(Turbolinks) == 'undefined' || !Turbolinks.supported) && typeof(Turbo) == 'undefined') {
        ActiveScaffold.setup_history_state();
      }
      ActiveScaffold.setup(document);
      jQuery(document).trigger('active-scaffold:loaded');
      resolve();
    });

    if (readyHeld) window.jQuery.holdReady(false);
  });

  // Start loading when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadDependencies);
  } else {
    loadDependencies();
  }
})();
