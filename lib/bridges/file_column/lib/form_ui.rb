module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      def active_scaffold_input_file_column(column, options)
        if @record.send(column.name) 
          # we already have a value?  display the form for deletion.

          # generate hidden field tag
          hidden_options = options.dup
          hidden_options[:id] += '_delete'
          hidden_options[:name].sub!("[#{column.name}]", "[delete_#{column.name}]")
          hidden_options[:value] = 'false'
          custom_hidden_field_tag = hidden_field(:record, column.name, hidden_options)

          content_tag(
            :div, 
            content_tag(
              :div, 
              get_column_value(@record, column) + " " +
              custom_hidden_field_tag +
              " | " +
              link_to_function(as_(:remove_file), "$(this).previous().value='true'; p=$(this).up(); p.hide(); p.next().show();"),
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
