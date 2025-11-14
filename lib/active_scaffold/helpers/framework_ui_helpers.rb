# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FrameworkUiHelpers
      def as_element(key, content = nil, proc_options: {}, **options, &)
        tag, attributes = as_tag_and_attributes(key, options, proc_options)
        content_tag(tag, content, attributes, &)
      end

      def as_element_attributes(key, proc_options: {}, **options)
        as_tag_and_attributes(key, options, proc_options).last
      end

      def as_tag_and_attributes(key, options, proc_options = {})
        tag, attributes, proc = ActiveScaffold.ui_elements[key]&.values_at(:tag, :attributes, :proc)
        tag, attributes = instance_exec(proc_options, &proc) if proc
        [tag, attributes&.smart_merge(options) || options&.as_html_attrs]
      end
    end
  end
end
