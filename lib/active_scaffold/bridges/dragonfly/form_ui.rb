module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_dragonfly(column, options)
        record = options[:object]
        dragonfly = record.send(column.name.to_s)
        content = active_scaffold_column_dragonfly(record, column) if dragonfly.present?
        active_scaffold_file_with_remove_link(column, options, content, 'remove_', 'dragonfly_controls')
      end
    end
  end
end
