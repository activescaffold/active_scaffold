# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      def active_scaffold_input_paperclip(column, options, ui_options: column.options)
        record = options[:object]
        paperclip = record.send(column.name.to_s)
<<<<<<< version4-3
        # TDH: 2024-10-29 so that a non-persisted record can show the file upload field we need to check if the record is persisted
        # if we attempt to show the column when the record is not persisted, it will attempt to find the file with a blank id. 
        # this causes an error and the form will not render properly. This is the only change to the original code.
        content = active_scaffold_column_paperclip(record, column, ui_options: ui_options) if paperclip.file? && record.persisted?
        active_scaffold_file_with_remove_link(column, options, content, 'delete_', 'paperclip_controls', ui_options: ui_options)
=======
        content = active_scaffold_column_paperclip(record, column, ui_options: ui_options) if paperclip.file?
        active_scaffold_file_with_content(column, options, content, 'delete_', 'paperclip_controls', ui_options: ui_options)
>>>>>>> master
      end
    end
  end
end
