class ActiveScaffold::Bridges::TinyMce
  module Helpers
    def self.included(base)
      base.class_eval do
        include FormColumnHelpers
        include SearchColumnHelpers
      end
    end

    module FormColumnHelpers
      def self.included(base)
        base.alias_method_chain :onsubmit, :tiny_mce
      end

      # The two column options that can be set specifically for the text_editor input
      # is :tinymce, which overrides single values in the tinymce config.
      # E.g. column[:foo].options[:tinymce] = {theme: 'other'} will change the theme
      # but not the plugins, toolbars etc.
      # The other one is :tinymce_config, which selects the config to use from tinymce.yml.
      # See the tinymce-rails gem documentation for usage.
      def active_scaffold_input_text_editor(column, options)
        options[:class] = "#{options[:class]} mceEditor #{column.options[:class]}".strip

        settings = tinymce_configuration(column.options[:tinymce_config] || :default).options.
          reject{|k,v| k =='selector'}.
          merge(column.options[:tinymce] || {})
        settings = settings.to_json
        settings = "tinyMCE.settings = #{settings};"

        html = []
        html << send(override_input(:textarea), column, options)
        html << javascript_tag(settings + "tinyMCE.execCommand('mceAddEditor', false, '#{options[:id]}');") if request.xhr? || params[:iframe]
        html.join "\n"
      end

      def onsubmit_with_tiny_mce
        case ActiveScaffold.js_framework
        when :jquery
          submit_js = 'tinyMCE.triggerSave();jQuery(\'textarea.mceEditor\').each(function(index, elem) { tinyMCE.execCommand(\'mceRemoveEditor\', false, jQuery(elem).attr(\'id\')); });'
        when :prototype
          submit_js = 'tinyMCE.triggerSave();this.select(\'textarea.mceEditor\').each(function(elem) { tinyMCE.execCommand(\'mceRemoveEditor\', false, elem.id); });'
        end
        [onsubmit_without_tiny_mce, submit_js].compact.join ';'
      end

      # The implementation is very tinymce specific, so it makes sense allowing :form_ui
      # to be :tinymce as well
      alias_method :active_scaffold_input_tinymce, :active_scaffold_input_text_editor
    end

    module SearchColumnHelpers
      def self.included(base)
        base.class_eval { alias_method :active_scaffold_search_text_editor, :active_scaffold_search_text }
      end
    end
  end
end
