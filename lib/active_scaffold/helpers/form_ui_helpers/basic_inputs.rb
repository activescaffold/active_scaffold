# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      module BasicInputs
        def active_scaffold_translated_option(column, text, value = nil)
          value = text if value.nil?
          if text.is_a?(Symbol)
            klass = column.active_record_class
            text = I18n.t "#{klass.i18n_scope}.attributes.#{klass.model_name.i18n_key}.#{column.name}.#{text}",
                          default: klass.human_attribute_name(text)
          end
          [text, value]
        end

        def active_scaffold_enum_options(column, record = nil, ui_options: column.options)
          ui_options[:options]
        end

        def active_scaffold_translated_enum_options(column, record, ui_options: column.options)
          enum_options_method = override_helper_per_model(:active_scaffold_enum_options, record.class)
          # e.g. setting form_ui = :select, set the options in column.options, and set search_ui = :select,
          # {null_comparators: false}
          ui_options = column.options if ui_options[:options].nil?
          options = send(enum_options_method, column, record, ui_options: ui_options)&.collect do |text, value|
            active_scaffold_translated_option(column, text, value)
          end
          options || []
        end

        def active_scaffold_input_enum(column, html_options, options = {}, ui_options: column.options)
          record = html_options.delete(:object)
          options[:selected] = record.send(column.name)
          options[:object] = record
          options_for_select = active_scaffold_translated_enum_options(column, record, ui_options: ui_options)
          html_options.merge!(ui_options[:html_options] || {})
          options.merge!(ui_options)
          active_scaffold_select_name_with_multiple html_options
          active_scaffold_translate_select_options(options)
          html = select(:record, column.name, options_for_select, options, html_options)
          html << active_scaffold_refresh_link(column, html_options, record, ui_options) if ui_options[:refresh_link]
          html
        end

        def active_scaffold_input_select(column, html_options, ui_options: column.options)
          record = html_options[:object]
          html =
            if column.association&.singular?
              active_scaffold_input_singular_association(column, html_options, ui_options: ui_options)
            elsif column.association&.collection?
              active_scaffold_input_plural_association(column, html_options, ui_options: ui_options)
            else
              active_scaffold_input_enum(column, html_options, ui_options: ui_options)
            end
          if ui_options[:add_new]
            html = content_tag(:div, html, class: 'select-field') <<
                   active_scaffold_add_new(column, record, html_options, ui_options: ui_options)
          end
          html
        end

        def active_scaffold_input_select_multiple(column, options, ui_options: column.options)
          active_scaffold_input_select(column, options.merge(multiple: true), ui_options: ui_options)
        end

        def active_scaffold_input_checkbox(column, options, ui_options: column.options)
          check_box(:record, column.name, options.merge(ui_options))
        end

        def active_scaffold_input_password(column, options, ui_options: column.options)
          active_scaffold_text_input :password_field, column, options.reverse_merge(autocomplete: 'new-password'),
                                     ui_options: ui_options
        end

        def active_scaffold_input_textarea(column, options, ui_options: column.options)
          text_area(:record, column.name,
                    options.merge(cols: ui_options[:cols], rows: ui_options[:rows], size: ui_options[:size]))
        end

        def active_scaffold_input_virtual(column, options)
          active_scaffold_text_input :text_field, column, options
        end

        # Some fields from HTML5 (primarily for using in-browser validation)
        # Sadly, many of them lacks browser support

        # A text box, that accepts only valid email address (in-browser validation)
        def active_scaffold_input_email(column, options, ui_options: column.options)
          active_scaffold_text_input :email_field, column, options, ui_options: ui_options
        end

        # A text box, that accepts only valid URI (in-browser validation)
        def active_scaffold_input_url(column, options, ui_options: column.options)
          active_scaffold_text_input :url_field, column, options, ui_options: ui_options
        end

        # A text box, that accepts only valid phone-number (in-browser validation)
        def active_scaffold_input_telephone(column, options, ui_options: column.options)
          active_scaffold_text_input :telephone_field, column, options, :format, ui_options: ui_options
        end

        # A spinbox control for number values (in-browser validation)
        def active_scaffold_input_number(column, options, ui_options: column.options)
          active_scaffold_number_input :number_field, column, options, :format, ui_options: ui_options
        end

        # A slider control for number values (in-browser validation)
        def active_scaffold_input_range(column, options, ui_options: column.options)
          active_scaffold_number_input :range_field, column, options, :format, ui_options: ui_options
        end

        # A slider control for number values (in-browser validation)
        def active_scaffold_number_input(method, column, options, remove_options = nil, ui_options: column.options)
          options = numerical_constraints_for_column(column, options)
          active_scaffold_text_input method, column, options, remove_options, ui_options: ui_options
        end

        def active_scaffold_text_input(method, column, options, remove_options = nil, ui_options: column.options)
          options = active_scaffold_input_text_options(options)
          options = options.merge(ui_options)
          options = options.except(*remove_options) if remove_options.present?
          send method, :record, column.name, options
        end

        # A color picker
        def active_scaffold_input_color(column, options, ui_options: column.options)
          html = []
          options = active_scaffold_input_text_options(options)
          if column.null?
            no_color = options[:object].send(column.name).nil?
            method = no_color ? :hidden_field : :color_field
            checkbox = check_box_tag('disable', '1', no_color, id: nil, name: nil, class: 'no-color')
            html << content_tag(:label, checkbox << " #{as_ ui_options[:no_color] || :no_color}")
          else
            method = :color_field
          end
          html << send(method, :record, column.name, options.merge(ui_options).except(:format, :no_color))
          safe_join html
        end

        #
        # Column.type-based inputs
        #

        def active_scaffold_input_boolean(column, html_options, ui_options: column.options)
          record = html_options.delete(:object)
          html_options.merge!(ui_options[:html_options] || {})

          options = {selected: record.send(column.name), object: record}
          options[:include_blank] = :_select_ if column.null?
          options.merge!(ui_options)
          active_scaffold_translate_select_options(options)

          options_for_select = [[as_(:true), true], [as_(:false), false]] # rubocop:disable Lint/BooleanSymbol
          select(:record, column.name, options_for_select, options, html_options)
        end

        def active_scaffold_input_date(column, options, ui_options: column.options)
          active_scaffold_text_input :date_field, column, options, ui_options: ui_options
        end

        def active_scaffold_input_time(column, options, ui_options: column.options)
          active_scaffold_text_input :time_field, column, options, ui_options: ui_options
        end

        def active_scaffold_input_datetime(column, options, ui_options: column.options)
          active_scaffold_text_input :datetime_local_field, column, options, ui_options: ui_options
        end

        def active_scaffold_input_month(column, options, ui_options: column.options)
          active_scaffold_text_input :month_field, column, options, ui_options: ui_options
        end

        def active_scaffold_input_week(column, options, ui_options: column.options)
          active_scaffold_text_input :week_field, column, options, ui_options: ui_options
        end
      end
    end
  end
end
