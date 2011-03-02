module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_carrierwave(column, options)
        options = active_scaffold_input_text_options(options)
        carrierwave = @record.send("#{column.name}")
        if carrierwave.file.present? && !carrierwave.file.empty?

          remove_field_options = {
            :name => options[:name].gsub(/\[#{column.name}\]$/, "[remove_#{column.name}]"),
            :id => 'remove_' + options[:id],
            :value => false
          }

          cache_field_options = {
            :name => options[:name].gsub(/\[#{column.name}\]$/, "[#{column.name}_cache]"),
            :id => options[:id] + '_cache'
          }

          if ActiveScaffold.js_framework == :jquery
            js_remove_file_code = "$(this).prev('input#remove_#{options[:id]}').val('true'); $(this).parent().hide().next().show(); return false;";
            js_dont_remove_file_code = "$(this).parents('div.carrierwave_controls').find('input#remove_#{options[:id]}').val('false'); return false;";
          else
            js_remove_file_code = "$(this).previous('input#remove_#{options[:id]}').value='true'; $(this).up().hide().next().show(); return false;";
            js_dont_remove_file_code = "$(this).up('div.carrierwave_controls').down('input#remove_#{options[:id]}').value='false'; return false;";
          end

          input = file_field(:record, column.name, options.merge(:onchange => js_dont_remove_file_code))
          content_tag( :div,
            content_tag(:div, (
                get_column_value(@record, column) + " | " +
                  hidden_field(:record, "#{column.name}_cache", cache_field_options) +
                  hidden_field(:record, "remove_#{column.name}", remove_field_options) +
                  content_tag(:a, as_(:remove_file), {:href => '#', :onclick => js_remove_file_code})
              ).html_safe
            ) + content_tag(:div, input, :style => "display: none"),
            :class => 'carrierwave_controls'
          )
        else
          file_field(:record, column.name, options)
        end
      end
    end
  end
end