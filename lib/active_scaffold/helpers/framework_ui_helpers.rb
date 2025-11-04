module ActiveScaffold
  module Helpers
    module FrameworkUiHelpers
      def as_ui_tag(key, content_or_options_with_block = nil, options = {}, &block)
        options = content_or_options_with_block if block_given? && content_or_options_with_block.is_a?(Hash)
        tag, attributes = as_ui_for(key, options)
        content_tag tag, content_or_options_with_block, attributes, &block
      end

      def as_ui_attributes(key, options = {})
        as_ui_for(key, options).last
      end

      def as_ui_for(key, options)
        tag, attributes, proc = ActiveScaffold.ui_tags[key]&.values_at(:tag, :attributes, :proc)
        tag, attributes = instance_exec(options, &proc) if proc
        [tag, attributes&.smart_merge(options) || options&.as_html_attrs]
      end
    end
  end
end
