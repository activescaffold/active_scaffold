module ActiveScaffold
  module Helpers
    module FrameworkUiHelpers
      def as_element(key, content_or_options_with_block = nil, options = {}, &)
        if block_given? && content_or_options_with_block.is_a?(Hash)
          options = content_or_options_with_block
          content_or_options_with_block = nil
        end
        tag, attributes = as_tag_and_attributes(key, options)
        content_tag(tag, content_or_options_with_block, attributes, &)
      end

      def as_element_attributes(key, options = {})
        as_tag_and_attributes(key, options).last
      end

      def as_tag_and_attributes(key, options)
        tag, attributes, proc = ActiveScaffold.ui_elements[key]&.values_at(:tag, :attributes, :proc)
        tag, attributes = instance_exec(options, &proc) if proc
        [tag, attributes&.smart_merge(options) || options&.as_html_attrs]
      end
    end
  end
end
