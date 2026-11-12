(function(global) {
  var ActiveScaffold = global.ActiveScaffold = global.ActiveScaffold || {};

  ActiveScaffold.datepickerCallbacks = ActiveScaffold.datepickerCallbacks || {};
  ActiveScaffold.tinymceCallbacks = ActiveScaffold.tinymceCallbacks || {};

  ActiveScaffold.resolveCallback = function(registryName, value, description) {
    if (typeof value === 'function' || typeof value !== 'string') return value;

    var registry = ActiveScaffold[registryName] || {};
    if (Object.prototype.hasOwnProperty.call(registry, value)) {
      if (typeof registry[value] === 'function') return registry[value];

      throw new TypeError('ActiveScaffold.' + registryName + '.' + value + ' must be a function');
    }

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

    return value;
  };
})(window);
