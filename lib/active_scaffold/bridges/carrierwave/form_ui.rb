module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_carrierwave(column, options)
        record = options[:object]
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include :object in html_options with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed
        options = active_scaffold_input_text_options(options.merge(column.options))

        carrierwave = record.send("#{column.name}")
        if !carrierwave.file.blank?
          required = options.delete(:required)
          remove_field_options = {
            :name => options[:name].gsub(/\[#{column.name}\]$/, "[remove_#{column.name}]"),
            :id => 'remove_' + options[:id],
            :value => false
          }

          cache_field_options = {
            :name => options[:name].gsub(/\[#{column.name}\]$/, "[#{column.name}_cache]"),
            :id => options[:id] + '_cache'
          }

          case ActiveScaffold.js_framework
          when :jquery
            js_remove_file_code = "jQuery(this).prev('input#remove_#{options[:id]}').val('true'); jQuery(this).parent().hide().next().show()#{".find('input').attr('required', 'required')" if required}; return false;"
            js_dont_remove_file_code = "jQuery(this).parents('div.carrierwave_controls').find('input#remove_#{options[:id]}').val('false'); return false;"
          when :prototype
            js_remove_file_code = "$(this).previous('input#remove_#{options[:id]}').value='true'; $(this).up().hide().next().show()#{".down().writeAttribute('required', 'required')" if required}; return false;"
            js_dont_remove_file_code = "$(this).up('div.carrierwave_controls').down('input#remove_#{options[:id]}').value='false'; return false;"
          end

          input = file_field(:record, column.name, options.merge(:onchange => js_dont_remove_file_code))
          content_tag(
            :div,
            content_tag(:div, (
                get_column_value(record, column) + ' | ' +
                  hidden_field(:record, "#{column.name}_cache", cache_field_options) +
                  hidden_field(:record, "remove_#{column.name}", remove_field_options) +
                  content_tag(:a, as_(:remove_file), :href => '#', :onclick => js_remove_file_code)
              ).html_safe
            ) + content_tag(:div, input, :style => 'display: none'),
            :class => 'carrierwave_controls'
          )
        else
          file_field(:record, column.name, options)
        end
      end
    end
  end
end
