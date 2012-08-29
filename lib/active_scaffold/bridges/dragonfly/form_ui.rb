module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_dragonfly(column, options)
        options = active_scaffold_input_text_options(options)
        input = file_field(:record, column.name, options)
        dragonfly = @record.send("#{column.name}")
        if dragonfly.present?
          if ActiveScaffold.js_framework == :jquery
            js_remove_file_code = "$(this).prev().val('true'); $(this).parent().hide().next().show(); return false;";
          else
            js_remove_file_code = "$(this).previous().value='true'; $(this).up().hide().next().show(); return false;";
          end
          
          content = active_scaffold_column_dragonfly(@record, column)
          content_tag(:div,
            content + " | " +
              hidden_field(:record, "remove_#{column.name}", :value => "false") +
              content_tag(:a, as_(:remove_file), {:href => '#', :onclick => js_remove_file_code}) 
          ) + content_tag(:div, input, :style => "display: none")
        else
          input
        end
      end
    end
  end
end