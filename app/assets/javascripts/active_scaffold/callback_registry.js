(function(global) {
  var ActiveScaffold = global.ActiveScaffold = global.ActiveScaffold || {};
  var warned = {};

  ActiveScaffold.datepickerCallbacks = ActiveScaffold.datepickerCallbacks || {};
  ActiveScaffold.tinymceCallbacks = ActiveScaffold.tinymceCallbacks || {};

  function warnOnce(key, message) {
    if (warned[key]) return;

    warned[key] = true;
    if (global.console && typeof global.console.warn === 'function') {
      global.console.warn(message);
    }
  }

  function evaluateLegacy(value, description, wrap) {
    try {
      var evaluated = global.eval(wrap ? '(' + value + ')' : value);
      warnOnce(description + ':' + value,
        'DEPRECATION WARNING: JavaScript in ' + description + ' is deprecated and will be removed in ActiveScaffold 4.5. ' +
        'Register callbacks by name and use JSON-compatible values instead.');
      return {success: true, value: evaluated};
    } catch (error) {
      return {success: false};
    }
  }

  ActiveScaffold.resolveCallback = function(registryName, value, description) {
    if (typeof value === 'function' || typeof value !== 'string') return value;

    var registry = ActiveScaffold[registryName] || {};
    if (Object.prototype.hasOwnProperty.call(registry, value)) {
      if (typeof registry[value] === 'function') return registry[value];

      throw new TypeError('ActiveScaffold.' + registryName + '.' + value + ' must be a function');
    }

    var legacy = evaluateLegacy(value, description, true);
    if (legacy.success) return legacy.value;

    throw new Error(description + ' references unknown callback ' + value +
      '. Register it in ActiveScaffold.' + registryName + '.');
  };

  var datepickerCallbackOptions = {
    afterInject: true,
    beforeShow: true,
    beforeShowDay: true,
    calculateWeek: true,
    onChangeMonthYear: true,
    onClose: true,
    onSelect: true,
    onUpdateDatepicker: true
  };

  ActiveScaffold.resolveDatepickerSetting = function(option, value) {
    if (typeof value !== 'string') return value;

    if (datepickerCallbackOptions[option]) {
      return ActiveScaffold.resolveCallback('datepickerCallbacks', value, 'datepicker option ' + option);
    }

    var legacy = evaluateLegacy(value, 'datepicker option ' + option, false);
    return legacy.success ? legacy.value : value;
  };
})(window);
