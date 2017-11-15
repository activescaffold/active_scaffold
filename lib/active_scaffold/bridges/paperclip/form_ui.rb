module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_paperclip(column, options)
        record = options[:object]
        paperclip = record.send(column.name.to_s)
        content = active_scaffold_column_paperclip(record, column) if paperclip.file?
        active_scaffold_file_with_remove_link(column, options, content, 'delete_', 'paperclip_controls')
      end
    end
  end
end
