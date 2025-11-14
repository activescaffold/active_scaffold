# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      def active_scaffold_input_active_storage_has_one(column, options, ui_options: column.options)
        record = options[:object]
        active_storage = record.send(column.name.to_s)
        content = active_scaffold_column_active_storage_has_one(record, column, ui_options: ui_options) if active_storage.attached?
        active_scaffold_file_with_remove_link(column, options, content, 'delete_', 'active_storage_controls', ui_options: ui_options)
      end

      def active_scaffold_input_active_storage_has_many(column, options, ui_options: column.options)
        record = options[:object]
        options[:multiple] = 'multiple'
        options[:name] += '[]'
        active_storage = record.send(column.name.to_s)
        content = active_scaffold_column_active_storage_has_many(record, column, ui_options: ui_options) if active_storage.attached?
        active_scaffold_file_with_remove_link(column, options, content, 'delete_', 'active_storage_controls', ui_options: ui_options)
      end
    end
  end
end
