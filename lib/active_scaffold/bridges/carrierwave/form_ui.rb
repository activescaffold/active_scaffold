# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      def active_scaffold_input_carrierwave(column, options, ui_options: column.options)
        record = options[:object]
        carrierwave = record.send(column.name.to_s)
        content = get_column_value(record, column) if carrierwave.file.present?
        active_scaffold_file_with_content(column, options, content, 'remove_', 'carrierwave_controls', ui_options: ui_options) do
          cache_field_options = {
            name: options[:name].gsub(/\[#{column.name}\]$/, "[#{column.name}_cache]"),
            id: "#{options[:id]}_cache"
          }
          hidden_field(:record, "#{column.name}_cache", cache_field_options)
        end
      end
    end
  end
end
