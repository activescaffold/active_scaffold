# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      module Rendering
        def get_column_value(record, column)
          record = record.send(column.delegated_association.name) if column.delegated_association
          if record
            method, list_ui = get_column_method(record, column)
            value =
              if list_ui
                send(method, record, column, ui_options: column.list_ui_options || column.options)
              else
                send(method, record, column)
              end
          else
            value = nil
          end
          value
        rescue StandardError => e
          handle_exception_on_column(e, column, record)
        end

        def get_column_method(record, column)
          # check for an override helper
          ActiveScaffold::Registry.cache :column_methods, column.cache_key do
            if (method = column_override(column))
              # we only pass the record as the argument. we previously also passed the formatted_value,
              # but mike perham pointed out that prohibited the usage of overrides to improve on the
              # performance of our default formatting. see issue #138.
              method
            # second, check if the dev has specified a valid list_ui for this column
            elsif column.list_ui && (method = override_column_ui(column.list_ui))
              [method, true]
            elsif column.column && (method = override_column_ui(column.column_type)) # rubocop:disable Lint/DuplicateBranch
              method
            else
              :format_column_value
            end
          end
        end

        def column_sort_value(record, column)
          value = record.send(column.name)
          return if value.nil?

          case column.column.type
          when :time, :datetime, Time then value.to_i
          when :boolean then value ? 1 : 0
          when :binary then nil
          when :integer then value
          when :float, :decimal then (value % 1).zero? ? value.to_i : value
          else value.to_s
          end
        end

        def render_list_column(text, column, record)
          if column.link && !skip_action_link?(column.link, record)
            link = column.link
            authorized = link.action.nil?
            authorized, reason = column_link_authorized?(link, column, record) unless authorized
            link_text = text != false && text.blank? ? empty_field_text(column) : text
            render_action_link(link, record, link: link_text, authorized: authorized, not_authorized_reason: reason)
          elsif inplace_edit?(record, column)
            active_scaffold_inplace_edit(record, column, formatted_column: text)
          elsif column_wrap_tag
            content_tag column_wrap_tag, text
          else
            text
          end
        rescue StandardError => e
          handle_exception_on_column(e, column, record)
        end

        def column_wrap_tag
          return @_column_wrap_tag if defined? @_column_wrap_tag

          @_column_wrap_tag = (active_scaffold_config.list.wrap_tag if active_scaffold_config.actions.include?(:list))
        end

        def convert_value_to_label(column, value, options = nil)
          options ||= (column.form_ui_options || column.options)&.dig(:options)
          return value if options.blank?

          text, val = options.find { |t, v| (v.nil? ? t : v).to_s == value.to_s }
          text ? active_scaffold_translated_option(column, text, val).first : value
        end

        ##
        ## Overrides
        ##
        def active_scaffold_column_text(record, column, ui_options: column.options)
          # `to_s` is necessary to convert objects in serialized columns to string before truncation.
          clean_column_value(truncate(record.send(column.name).to_s, length: ui_options[:truncate] || 50))
        end

        def active_scaffold_column_fulltext(record, column, ui_options: column.options)
          clean_column_value(record.send(column.name))
        end

        def active_scaffold_column_marked(record, column, ui_options: column.options)
          options = {id: nil, object: record}
          content_tag(
            :span,
            check_box(:record, column.name, options),
            class: 'in_place_editor_field',
            data: {ie_id: record.to_param}
          )
        end

        def active_scaffold_column_checkbox(record, column, ui_options: column.options)
          options = {disabled: true, id: nil, object: record}
          options.delete(:disabled) if inplace_edit?(record, column)
          check_box(:record, column.name, options)
        end

        def active_scaffold_column_checkboxes(record, column, ui_options: column.options)
          return format_column_value(record, column) if column.association

          values = record.send(column.name)
          return if values.empty?

          content_tag :ul, safe_join(values.map { |v| content_tag(:li, convert_value_to_label(column, v)) })
        end
        alias active_scaffold_column_select_multiple active_scaffold_column_checkboxes
        alias active_scaffold_column_draggable active_scaffold_column_checkboxes

        def active_scaffold_column_select(record, column, ui_options: column.options)
          unless column.association
            if ui_options[:multiple]
              return active_scaffold_column_select_multiple(record, column,
                                                            ui_options: ui_options)
            end

            value = convert_value_to_label(column, record.send(column.name))
          end
          format_column_value(record, column, value)
        end
        alias active_scaffold_column_radio active_scaffold_column_select

        def active_scaffold_column_boolean(record, column, ui_options: column.options)
          value = record.send(column.name)
          if value.nil? && ui_options[:include_blank]
            value = ui_options[:include_blank]
            value.is_a?(Symbol) ? as_(value) : value
          else
            format_column_value(record, column, value)
          end
        end

        def active_scaffold_column_percentage(record, column, ui_options: column.options)
          options = ui_options[:slider] || {}
          options = options.merge(min: record.send(options[:min_method])) if options[:min_method]
          options = options.merge(max: record.send(options[:max_method])) if options[:max_method]
          value = record.send(options[:value_method]) if options[:value_method]
          as_slider options.merge(value: value || record.send(column.name))
        end

        def active_scaffold_column_month(record, column, ui_options: column.options)
          l record.send(column.name), format: :year_month
        end

        def active_scaffold_column_week(record, column, ui_options: column.options)
          l record.send(column.name), format: :week
        end

        def tel_to(text)
          text = text.to_s
          groups = text.scan(/(?:^\+)?\d+/)
          extension = groups.pop if text.match?(/\s*[^\d\s]+\s*\d+$/)
          link_to text, "tel:#{[groups.join('-'), extension].compact.join(',')}"
        end

        def active_scaffold_column_telephone(record, column, ui_options: column.options)
          phone = record.send column.name
          return if phone.blank?

          phone = number_to_phone(phone) unless ui_options[:format] == false
          tel_to phone
        end

        def column_override(column)
          override_helper column, 'column'
        end
        alias column_override? column_override

        # the naming convention for overriding column types with helpers
        def override_column_ui(list_ui)
          ActiveScaffold::Registry.cache :column_ui_overrides, list_ui do
            method = "active_scaffold_column_#{list_ui}"
            method if respond_to? method
          end
        end
        alias override_column_ui? override_column_ui
      end
    end
  end
end
