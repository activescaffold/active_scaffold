# frozen_string_literal: true

module ActiveScaffold
  module Assets
    autoload :CssDepsGenerator, 'active_scaffold/assets/css_deps_generator'
    autoload :JqueryUiManifest, 'active_scaffold/assets/jquery_ui_manifest'
    autoload :JqueryUiThemeGenerator, 'active_scaffold/assets/jquery_ui_theme_generator'

    CORE_STYLESHEETS = ['active_scaffold/core'].freeze
    CORE_JAVASCRIPTS = ['jquery.ba-throttle-debounce', 'jquery.visible.min', 'active_scaffold/jquery.editinplace', 'active_scaffold/active_scaffold'].freeze

    class << self
      # Returns array of stylesheet paths based on load mode
      def active_scaffold_stylesheets(load = :all)
        case load
        when :all
          CORE_STYLESHEETS + active_scaffold_stylesheets(:deps)
        when :deps
          jquery_ui_stylesheets + ActiveScaffold.stylesheets + bridge_stylesheets
        when :core
          CORE_STYLESHEETS
        when :plugins
          ActiveScaffold.stylesheets
        when :bridges
          bridge_stylesheets
        when :jquery_ui
          jquery_ui_stylesheets
        else
          raise ArgumentError, "Unknown load mode: #{load.inspect}"
        end
      end

      # Returns array of javascript paths based on load mode
      def active_scaffold_javascripts(load = :all)
        case load
        when :all
          jquery_ui_javascripts + CORE_JAVASCRIPTS + ActiveScaffold.javascripts + bridge_javascripts
        when :deps
          jquery_ui_javascripts + ActiveScaffold.javascripts + bridge_javascripts
        when :core
          CORE_JAVASCRIPTS
        when :plugins
          ActiveScaffold.javascripts
        when :bridges
          bridge_javascripts
        when :jquery_ui
          jquery_ui_javascripts
        else
          raise ArgumentError, "Unknown load mode: #{load.inspect}"
        end
      end

      def active_scaffold_js_code(load = :all)
        code =
          case load
          when :all
            [jquery_ui_js_code, active_scaffold_js_config]
          when :deps, :jquery_ui
            [jquery_ui_js_code]
          when :core
            [active_scaffold_js_config]
          when :plugins, :bridges
            []
          else
            raise ArgumentError, "Unknown load mode: #{load.inspect}"
          end
        code.join("\n")
      end

      private

      def jquery_ui_stylesheets
        return [] unless ActiveScaffold.jquery_ui_included?

        sheets = []
        if Object.const_defined?(:Jquery) && Jquery.const_defined?(:Ui)
          sheets << 'active_scaffold/jquery-ui/theme' if defined?(Propshaft)
          sheets << 'jquery-ui/datepicker'
        end
        sheets << 'jquery-ui-theme' if ActiveScaffold.jquery_ui_included?
        sheets
      end

      def bridge_stylesheets
        ActiveScaffold::Bridges.all_stylesheets
      end

      def jquery_ui_javascripts
        return [] unless ActiveScaffold.jquery_ui_included?

        # For Propshaft, we need all jQuery UI dependencies
        ActiveScaffold::Assets::JqueryUiManifest.all_dependencies +
          ['jquery-ui-timepicker-addon', 'active_scaffold/date_picker_bridge', 'active_scaffold/draggable_lists']
      end

      def jquery_ui_js_code
        ActiveScaffold::Bridges[:date_picker].localization
      end

      def active_scaffold_js_config
        "ActiveScaffold.config = #{ActiveScaffold.js_config.to_json};"
      end

      def bridge_javascripts
        ActiveScaffold::Bridges.all_javascripts
      end
    end
  end
end
