class ActiveScaffold::Bridges::TinyMce
  module Helpers
    def self.included(base)
      base.class_eval do
        include FormColumnHelpers
        include SearchColumnHelpers
      end
    end

    module FormColumnHelpers
      # The two column options that can be set specifically for the text_editor input
      # is :tinymce, which overrides single values in the tinymce config.
      # E.g. column[:foo].options[:tinymce] = {theme: 'other'} will change the theme
      # but not the plugins, toolbars etc.
      # The other one is :tinymce_config, which selects the config to use from tinymce.yml.
      # See the tinymce-rails gem documentation for usage.
      def active_scaffold_input_text_editor(column, options, ui_options: column.options)
        options[:class] = "#{options[:class]} mceEditor #{ui_options[:class]}".strip

        settings = tinymce_configuration(ui_options[:tinymce_config] || :default).options
                                                                                 .reject { |k, _v| k == 'selector' }
                                                                                 .merge(ui_options[:tinymce] || {})
        options['data-tinymce'] = settings.to_json if ActiveScaffold.js_framework != :prototype

        html = []
        html << send(override_input(:textarea), column, options, ui_options: ui_options)
        if ActiveScaffold.js_framework == :prototype && (request.xhr? || params[:iframe])
          html << javascript_tag("tinyMCE.settings = #{settings.to_json}; tinyMCE.execCommand('mceAddEditor', false, '#{options[:id]}');")
        end
        safe_join html
      end

      # The implementation is very tinymce specific, so it makes sense allowing :form_ui
      # to be :tinymce as well
      alias active_scaffold_input_tinymce active_scaffold_input_text_editor
    end

    module SearchColumnHelpers
      def self.included(base)
        base.class_eval { alias_method :active_scaffold_search_text_editor, :active_scaffold_search_text }
      end
    end
  end
end
