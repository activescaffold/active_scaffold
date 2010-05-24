module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_paperclip(column, options)
        input = file_field(:record, column.name, options)
        paperclip = @record.send("#{column.name}")
        if paperclip.file?
          content = active_scaffold_column_paperclip(column, @record)
          content_tag(:div,
            content + " | " +
            link_to_function(as_(:remove_file), "$(this).next().value='true'; $(this).up().hide().next().show()") +
            hidden_field(:record, "delete_#{column.name}", :value => "false")
          ) + content_tag(:div, input, :style => "display: none")
        else
          input
        end
      end
    end
  end
end