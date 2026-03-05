# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormUiHelpers
      def active_scaffold_input_file_column(column, options, ui_options: column.options)
        record = options[:object]
        if record.send(column.name)
          # we already have a value? display the form for deletion.
          remove_file_js = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show(); return false;"

          hidden_options = options.merge(id: "#{options[:id]}_delete", name: options[:name].sub("[#{column.name}]", "[delete_#{column.name}]"), value: 'false')
          custom_hidden_field_tag = hidden_field(:record, column.name, hidden_options)

          content_tag(:div) do
            content_tag(:div) do
              safe_join [get_column_value(record, column), custom_hidden_field_tag, '|',
                         content_tag(:a, as_(:remove_file), href: '#', onclick: remove_file_js),
                         content_tag(:div, 'test', style: 'display: none')], ' '
            end
          end
        else
          file_column_field('record', column.name, options)
        end
      end
    end
  end
end
