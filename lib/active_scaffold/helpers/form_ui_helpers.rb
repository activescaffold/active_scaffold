# frozen_string_literal: true

require 'active_scaffold/helpers/form_ui_helpers/association_inputs'
require 'active_scaffold/helpers/form_ui_helpers/checkbox_inputs'
require 'active_scaffold/helpers/form_ui_helpers/radio_inputs'
require 'active_scaffold/helpers/form_ui_helpers/basic_inputs'

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormUiHelpers
      include AssociationInputs
      include CheckboxInputs
      include RadioInputs
      include BasicInputs

      def active_scaffold_file_with_content(column, options, content, remove_file_prefix, controls_class,
                                            ui_options: column.options)
        options = active_scaffold_input_text_options(options.merge(ui_options))
        options[:style] = 'display: none' if content
        field = file_field(:record, column.name, options)

        if content
          content = [content, ' | ']
          content << yield if block_given?
          object_name, method = options[:name].split(/\[(#{column.name})\]/)
          method.sub!(/#{column.name}/, "#{remove_file_prefix}\\0")
          content << hidden_field(object_name, method, value: 'false', class: 'remove_file')
          active_scaffold_file_with_remove_link(safe_join(content), options, controls_class) { field }
        else
          field
        end
      end

      def active_scaffold_file_with_remove_link(content, options, controls_class, link_key = nil)
        required = options.delete(:required)
        link_key ||= options[:multiple] ? :remove_files : :remove_file
        content_tag(:div, class: "#{controls_class} file-input-controls", data: {required: required}) do
          content_line = content_tag(:div) do
            safe_join [content, content_tag(:a, as_(link_key), href: '#', class: 'remove-file-btn')]
          end
          content_line << yield if block_given?
          content_line
        end
      end
    end
  end
end
