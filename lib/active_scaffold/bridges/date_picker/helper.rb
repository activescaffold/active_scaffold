# frozen_string_literal: true

module ActiveScaffold::Bridges
  class DatePicker
    module Helper
      UNSUPPORTED_FORMAT_OPTIONS = /%[cUWwxXZ]/
      DATE_FORMAT_CONVERSION = {
        /%a/ => 'D',
        /%A/ => 'DD',
        /%b/ => 'M',
        /%B/ => 'MM',
        /%d/ => 'dd',
        /%e|%-d/ => 'd',
        /%j/ => 'oo',
        /%m/ => 'mm',
        /%-m|%-m/ => 'm',
        /%y/ => 'y',
        /%Y/ => 'yy',
        /%H/ => 'HH', # options ampm => false
        /%I/ => 'hh', # options ampm => true
        /%M/ => 'mm',
        /%p/ => 'tt',
        /%S/ => 'ss',
        /%z/ => 'z',
        UNSUPPORTED_FORMAT_OPTIONS => ''
      }.freeze

      def self.date_options_for_locales
        I18n.available_locales.filter_map do |locale|
          locale_date_options = date_options(locale)
          "$.datepicker.regional['#{locale}'] = #{locale_date_options.to_json};" if locale_date_options
        end.join
      end

      def self.date_options(locale)
        date_picker_options = {
          closeText:       as_(:close),
          prevText:        as_(:previous),
          nextText:        as_(:next),
          currentText:     as_(:today),
          monthNames:      I18n.translate!('date.month_names', locale: locale)[1..],
          monthNamesShort: I18n.translate!('date.abbr_month_names', locale: locale)[1..],
          dayNames:        I18n.translate!('date.day_names', locale: locale),
          dayNamesShort:   I18n.translate!('date.abbr_day_names', locale: locale),
          dayNamesMin:     I18n.translate!('date.abbr_day_names', locale: locale),
          changeYear:      true,
          changeMonth:     true
        }

        as_date_picker_options = I18n.translate! :date_picker_options, scope: :active_scaffold, locale: locale, default: ''
        date_picker_options.merge!(as_date_picker_options) if as_date_picker_options.is_a? Hash
        Rails.logger.warn "ActiveScaffold: Missing date picker localization for your locale: #{locale}" if as_date_picker_options.blank?

        js_format = to_datepicker_format(I18n.translate!('date.formats.default', locale: locale, default: ''))
        date_picker_options[:dateFormat] = js_format if js_format.present?
        date_picker_options
      rescue StandardError
        raise if locale == I18n.locale
      end

      def self.datetime_options_for_locales
        I18n.available_locales.filter_map do |locale|
          locale_datetime_options = datetime_options(locale)
          "$.timepicker.regional['#{locale}'] = #{locale_datetime_options.to_json};" if locale_datetime_options
        end.join
      end

      def self.datetime_options(locale)
        rails_time_format = I18n.translate! 'time.formats.picker', locale: locale, default: '%a, %d %b %Y %H:%M:%S'
        datetime_picker_options = {
          ampm: false,
          hourText: I18n.translate!('datetime.prompts.hour', locale: locale),
          minuteText: I18n.translate!('datetime.prompts.minute', locale: locale),
          secondText: I18n.translate!('datetime.prompts.second', locale: locale),
          millisecText: I18n.translate!('datetime.prompts.millisec', locale: locale),
          microsecText: I18n.translate!('datetime.prompts.microsec', locale: locale)
        }

        as_datetime_picker_options = I18n.translate! :datetime_picker_options, scope: :active_scaffold, locale: locale, default: ''
        datetime_picker_options.merge!(as_datetime_picker_options) if as_datetime_picker_options.is_a? Hash
        Rails.logger.warn "ActiveScaffold: Missing datetime picker localization for your locale: #{locale}" if as_datetime_picker_options.blank?

        datetime_picker_options.merge! format_to_datetime_picker(rails_time_format)
        datetime_picker_options
      rescue StandardError
        raise if locale == I18n.locale
      end

      def self.to_datepicker_format(rails_format)
        return nil if rails_format.nil?

        if rails_format.match?(UNSUPPORTED_FORMAT_OPTIONS)
          options = UNSUPPORTED_FORMAT_OPTIONS.to_s.scan(/\[(.*)\]/).dig(0, 0)&.each_char&.map { |c| "%#{c}" }
          Rails.logger.warn(
            "AS DatePicker::Helper: rails date format #{rails_format} includes options " \
            "which can't be converted to jquery datepicker format. " \
            "Options #{options.join(', ')} are not supported by datepicker and will be removed"
          )
        end
        js_format = rails_format.dup
        js_format.gsub!(/( |^)([^% ]\S*)/, " '\\2'")
        DATE_FORMAT_CONVERSION.each do |key, value|
          js_format.gsub!(key, value)
        end
        js_format
      end

      def self.format_to_datetime_picker(rails_time_format)
        date_format, time_format = split_datetime_format(to_datepicker_format(rails_time_format))
        datetime_picker_options = {}
        datetime_picker_options[:dateFormat] = date_format unless date_format.nil?
        unless time_format.nil?
          datetime_picker_options[:timeFormat] = time_format
          datetime_picker_options[:ampm] = true if rails_time_format.include?('%I')
        end
        datetime_picker_options
      end

      def self.split_datetime_format(datetime_format)
        date_format = datetime_format
        time_format = nil
        time_start_indicators = %w[HH hh mm tt ss]
        unless datetime_format.nil?
          start_indicator = time_start_indicators.detect { |indicator| datetime_format.include?(indicator) }
          unless start_indicator.nil?
            pos_time_format = datetime_format.index(start_indicator)
            date_format = datetime_format.to(pos_time_format - 1).strip
            time_format = datetime_format.from(pos_time_format).strip
          end
        end
        [date_format, time_format]
      end

      module DatepickerColumnHelpers
        def to_datepicker_format(rails_format) # rubocop:disable Rails/Delegate
          ActiveScaffold::Bridges::DatePicker::Helper.to_datepicker_format(rails_format)
        end

        def datepicker_format_options(column, format)
          return {} if format == :default

          if column.form_ui == :date_picker
            js_format = to_datepicker_format(I18n.translate!("date.formats.#{format}"))
            js_format.nil? ? {} : {dateFormat: js_format}
          else
            rails_time_format = I18n.translate!("time.formats.#{format}")
            ActiveScaffold::Bridges::DatePicker::Helper.format_to_datetime_picker(rails_time_format)
          end
        end

        def datepicker_format(options, ui_name)
          options.delete(:format) || (ui_name == :date_picker ? :default : :picker)
        end
      end

      module SearchColumnHelpers
        def active_scaffold_search_date_picker_field(column, options, current_search, name, ui_options: column.options)
          value =
            if current_search.is_a? Hash
              conversion = column.search_ui == :date_picker ? :to_date : :to_time
              controller.class.condition_value_for_datetime(column, current_search[name], conversion, ui_method: :search_ui, ui_options: ui_options)
            else
              current_search
            end
          options = ui_options.merge(options).except!(:include_blank, :discard_time, :discard_date, :value)
          options = active_scaffold_input_text_options(options)
          format = datepicker_format(options, column.search_ui)
          options[:class] << " #{column.search_ui}"
          options[:style] = 'display: none' if options[:show] == false # hide only if asked to hide
          options[:data] = datepicker_format_options(column, format).reverse_merge!(options[:data] || {})
          value = l(value, format: format) if value
          options = options.merge(id: "#{options[:id]}_#{name}", name: "#{options[:name]}[#{name}]", object: nil)
          text_field_tag("#{options[:name]}[#{name}]", value, options)
        end
      end

      module FormColumnHelpers
        def active_scaffold_input_date_picker(column, options, ui_options: column.options)
          record = options[:object]
          options = active_scaffold_input_text_options(options.merge(ui_options))
          options[:class] << " #{column.form_ui}"

          format = datepicker_format(options, column.form_ui)
          conversion = column.form_ui == :date_picker ? :to_date : :to_time
          value = controller.class.condition_value_for_datetime(column, record.send(column.name), conversion, ui_method: :form_ui, ui_options: ui_options)
          options[:data] = datepicker_format_options(column, format).reverse_merge!(options[:data] || {})
          options[:value] = (value ? l(value, format: format) : nil)
          text_field(:record, column.name, options)
        end
      end
    end
  end
end
