module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      def active_scaffold_input_file_column(column, options)
        if @record.send(column.name) 
          # we already have a value?  display the form for deletion.
          if ActiveScaffold.js_framework == :jquery
            js_remove_file_code = "$(this).prev().val('true'); $(this).parent().hide().next().show(); return false;";
          else
            js_remove_file_code = "$(this).previous().value='true'; p=$(this).up(); p.hide(); p.next().show(); return false;";
          end
          content_tag(
            :div, 
            content_tag(
              :div, 
              get_column_value(@record, column) + " " +
              hidden_field(:record, "delete_#{column.name}", :value => "false") +
              " | " +
                content_tag(:a, as_(:remove_file), {:href => '#', :onclick => js_remove_file_code}),
              {}
            ) +
            content_tag(
              :div,
              file_column_field("record", column.name, options),
              :style => "display: none"
            ),
            {}
          )
        else
          # no, just display the file_column_field
          file_column_field("record", column.name, options)
        end
      end      
    end
  end
end