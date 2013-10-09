module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_paperclip(column, options)
        options = active_scaffold_input_text_options(options.merge(column.options))
        input = file_field(:record, column.name, options)
        paperclip = @record.send("#{column.name}")
        if paperclip.file?
          case ActiveScaffold.js_framework
          when :jquery
            js_remove_file_code = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show(); return false;";
          when :prototype
            js_remove_file_code = "$(this).previous().value='true'; $(this).up().hide().next().show(); return false;";
          end
          
          content = active_scaffold_column_paperclip(@record, column)
          content_tag(:div,
            content + " | " +
              hidden_field(:record, "delete_#{column.name}", :value => "false") +
              content_tag(:a, as_(:remove_file), {:href => '#', :onclick => js_remove_file_code}) 
          ) + content_tag(:div, input, :style => "display: none")
        else
          input
        end
      end
    end
  end
end
