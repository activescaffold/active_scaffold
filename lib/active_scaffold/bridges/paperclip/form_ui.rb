module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_paperclip(column, options)
        record = options[:object]
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include :object in html_options with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed
        options = active_scaffold_input_text_options(options.merge(column.options))
        paperclip = record.send("#{column.name}")

        required = options.delete(:required) if paperclip.file?
        input = file_field(:record, column.name, options)
        if paperclip.file?
          case ActiveScaffold.js_framework
          when :jquery
            js_remove_file_code = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show()#{".find('input').attr('required', 'required')" if required}; return false;"
          when :prototype
            js_remove_file_code = "$(this).previous().value='true'; $(this).up().hide().next().show()#{".down().writeAttribute('required', 'required')" if required}; return false;"
          end

          object_name, method = options[:name].split(/\[(#{column.name})\]/)
          method.sub!(/#{column.name}/, 'delete_\0')

          content = active_scaffold_column_paperclip(record, column)
          content_tag(
            :div,
            content + ' | ' +
              hidden_field(object_name, method, :value => 'false') +
              content_tag(:a, as_(:remove_file), :href => '#', :onclick => js_remove_file_code)
          ) + content_tag(:div, input, :style => 'display: none')
        else
          input
        end
      end
    end
  end
end
