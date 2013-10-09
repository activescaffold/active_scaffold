module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      def active_scaffold_input_file_column(column, options)
       if @record.send(column.name) 
          # we already have a value? display the form for deletion.
          case ActiveScaffold.js_framework
          when :jquery
            remove_file_js = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show(); return false;";
          when :prototype
            remove_file_js = "$(this).previous().value='true'; p=$(this).up(); p.hide(); p.next().show(); return false;";
          end            
          
          hidden_options = options.dup
          hidden_options[:id] += '_delete'
          hidden_options[:name].sub!("[#{column.name}]", "[delete_#{column.name}]")
          hidden_options[:value] = 'false'          
          custom_hidden_field_tag = hidden_field(:record, column.name, hidden_options)

          content_tag(:div) do
            content_tag(:div) do
              content = get_column_value(@record, column) + " #{custom_hidden_field_tag} | ".html_safe
              content += content_tag(:a, as_(:remove_file), {:href => '#', :onclick => remove_file_js})
              content += content_tag(:div, file_column_field("record", column.name, options), :style => "display: none")
            end           
          end
       else
          file_column_field("record", column.name, options)          
       end        
      end
      
    end
  end
end
