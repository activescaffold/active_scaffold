module ActiveScaffold
  module JqueryUiManifest
    # Full list of jQuery UI dependencies based on jquery-ui-rails structure
    CORE_FILES = [
      ('jquery-ui/core' unless Jquery::Ui::Rails::VERSION >= '8.0.0'),
      'jquery-ui/version',
      'jquery-ui/keycode',
      'jquery-ui/scroll-parent',
      'jquery-ui/unique-id',
      'jquery-ui/widget',
      'jquery-ui/widgets/mouse',
      'jquery-ui/plugin',
      ('jquery-ui/safe-active-element' unless Jquery::Ui::Rails::VERSION >= '8.0.0'),
      ('jquery-ui/safe-blur' unless Jquery::Ui::Rails::VERSION >= '8.0.0'),
      'jquery-ui/data',
      'jquery-ui/disable-selection',
      'jquery-ui/focusable',
      ('jquery-ui/form' unless Jquery::Ui::Rails::VERSION >= '8.0.0'),
      ('jquery-ui/ie' unless Jquery::Ui::Rails::VERSION >= '8.0.0'),
      'jquery-ui/labels',
      "jquery-ui/jquery-#{Jquery::Ui::Rails::VERSION >= '7.0.0' ? 'patch' : '1-7'}",
      ('jquery-ui/escape-selector' unless Jquery::Ui::Rails::VERSION >= '7.0.0'),
      'jquery-ui/tabbable'
    ].compact.freeze

    WIDGET_FILES = {
      sortable: [
        'jquery-ui/widgets/sortable'
      ],
      draggable: [
        'jquery-ui/widgets/draggable'
      ],
      droppable: [
        'jquery-ui/widgets/droppable'
      ],
      datepicker: [
        'jquery-ui/widgets/datepicker'
      ],
      # dialog: [
      #   'jquery-ui/position',
      #   'jquery-ui/form-reset-mixin',
      #   'jquery-ui/widgets/controlgroup',
      #   'jquery-ui/widgets/checkboxradio',
      #   'jquery-ui/widgets/button',
      #   'jquery-ui/widgets/resizable',
      #   'jquery-ui/widgets/dialog'
      # ]
    }.freeze

    EFFECT_FILES = {
      core: [
        ('jquery-ui/jquery-var-for-color' if Jquery::Ui::Rails::VERSION >= '7.0.0'),
        ('jquery-ui/vendor/jquery-color/jquery.color' if Jquery::Ui::Rails::VERSION >= '7.0.0'),
        'jquery-ui/effect'
      ].compact,
      highlight: ['jquery-ui/effects/effect-highlight']
    }.freeze

    def self.all_dependencies
      (CORE_FILES +
        WIDGET_FILES.values.flatten +
        EFFECT_FILES.values.flatten).uniq
    end

    def self.widget_dependencies(widgets)
      deps = CORE_FILES.dup
      Array(widgets).each do |widget|
        deps += WIDGET_FILES[widget.to_sym] if WIDGET_FILES[widget.to_sym]
      end
      deps
    end
  end
end