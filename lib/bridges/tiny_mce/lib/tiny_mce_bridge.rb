module ActiveScaffold
  module Helpers
    module ViewHelpers
      def active_scaffold_includes_with_tiny_mce(*args)
        tiny_mce_js = javascript_tag(%|
var action_link_close = ActiveScaffold.ActionLink.Abstract.prototype.close;
ActiveScaffold.ActionLink.Abstract.prototype.close = function() {
  this.adapter.select('textarea.mceEditor').each(function(elem) {
    tinyMCE.execCommand('mceRemoveControl', false, elem.id);
  });
  action_link_close.apply(this);
};
        |) if using_tiny_mce?
        active_scaffold_includes_without_tiny_mce(*args) + (include_tiny_mce_if_needed || '') + (tiny_mce_js || '')
      end
      alias_method_chain :active_scaffold_includes, :tiny_mce
    end

    module FormColumnHelpers
      def active_scaffold_input_text_editor(column, options)
        options[:class] = "#{options[:class]} mceEditor #{column.options[:class]}".strip
        html = []
        html << text_area(:record, column.name, options.merge(:cols => column.options[:cols], :rows =>column.options[:rows]))
        html << javascript_tag("tinyMCE.execCommand('mceAddControl', false, '#{options[:id]}');") if request.xhr?
        html.join "\n"
      end

      def onsubmit
        'tinyMCE.triggerSave();this.select("textarea.mceEditor").each(function(elem) { tinyMCE.execCommand("mceRemoveControl", false, elem.id); });' if using_tiny_mce?
      end
    end

    module SearchColumnHelpers
      alias_method :active_scaffold_search_text_editor, :active_scaffold_search_text
    end
  end
end
