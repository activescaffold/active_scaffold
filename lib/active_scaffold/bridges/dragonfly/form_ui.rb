# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      def active_scaffold_input_dragonfly(column, options, ui_options: column.options)
        record = options[:object]
        dragonfly = record.send(column.name.to_s)
        content = active_scaffold_column_dragonfly(record, column, ui_options: ui_options) if dragonfly.present?
        active_scaffold_file_with_content(column, options, content, 'remove_', 'dragonfly_controls', ui_options: ui_options)
      end
    end
  end
end
