module ActiveScaffold
  module TinyMceBridge
    def self.included(base)
      base.class_eval do
        include FormColumnHelpers
        include SearchColumnHelpers
        include ViewHelpers
      end
    end

    module ViewHelpers
      def self.included(base)
        base.alias_method_chain :active_scaffold_includes, :tiny_mce
      end

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
    end

    module FormColumnHelpers
      def self.included(base)
        base.alias_method_chain :onsubmit, :tiny_mce
      end

      def active_scaffold_input_text_editor(column, options)
        options[:class] = "#{options[:class]} mceEditor #{column.options[:class]}".strip
        html = []
        html << send(override_input(:textarea), column, options)
        html << javascript_tag("tinyMCE.execCommand('mceAddControl', false, '#{options[:id]}');") if request.xhr? || params[:iframe]
        html.join "\n"
      end

      def onsubmit_with_tiny_mce
        submit_js = 'tinyMCE.triggerSave();this.select("textarea.mceEditor").each(function(elem) { tinyMCE.execCommand("mceRemoveControl", false, elem.id); });' if using_tiny_mce?
        [onsubmit_without_tiny_mce, submit_js].compact.join ';'
      end
    end

    module SearchColumnHelpers
      def self.included(base)
        base.class_eval { alias_method :active_scaffold_search_text_editor, :active_scaffold_search_text }
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::TinyMceBridge }
