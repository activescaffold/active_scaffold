# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module AssetsHelpers
      def active_scaffold_javascript_tag
        js_tags = ActiveScaffold::Bridges.all_javascript_tags.map { |method| send(method) }
        js_tags << active_scaffold_javascript_config
        unless defined?(Importmap)
          # Without importmap, active_scaffold/load must be added to the layout too
          js_tags << javascript_include_tag('active_scaffold/load')
        end
        safe_join js_tags
      end

      private

      def active_scaffold_javascript_config
        config = ActiveScaffold.js_config.merge(
          jqueryUiIncluded: ActiveScaffold.jquery_ui_included?,
          bridges: ActiveScaffold::Bridges.all_javascripts.map { |asset| asset_path(asset, extname: '.js') },
          plugins: ActiveScaffold.javascripts.map { |asset| asset_path(asset, extname: '.js') }
        )
        if ActiveScaffold.jquery_ui_included?
          config[:datepickerLocalization] = ActiveScaffold::Assets.active_scaffold_js_code(:jquery_ui)
        end

        if Object.const_defined?(:Jquery) && Jquery.const_defined?(:Ui)
          config[:jqueryUi] = ActiveScaffold::Assets::JqueryUiManifest.all_dependencies.map { |asset| asset_path(asset, extname: '.js') }
        end

        javascript_tag <<~JS
          window.ActiveScaffold = window.ActiveScaffold || {};
          window.ActiveScaffold.config = #{config.to_json};
        JS
      end
    end
  end
end
