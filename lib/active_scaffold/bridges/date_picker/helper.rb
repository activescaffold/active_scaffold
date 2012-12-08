module ActiveScaffold::Bridges
  class DatePicker
    module Helper
      DATE_FORMAT_CONVERSION = {
        /%a/ => 'D',
        /%A/ => 'DD',
        /%b/ => 'M',
        /%B/ => 'MM',
        /%d/ => 'dd',
        /%e/ => 'd',
        /%j/ => 'oo',
        /%m/ => 'mm',
        /%y/ => 'y',
        /%Y/ => 'yy',
        /%H/ => 'HH', # options ampm => false
        /%I/ => 'hh', # options ampm => true
        /%M/ => 'mm',
        /%p/ => 'tt',
        /%S/ => 'ss',
        /%[cUWwxXZz]/ => ''
      }
      
      def self.date_options_for_locales
        I18n.available_locales.collect do |locale|
          locale_date_options = date_options(locale)
          if locale_date_options
            "$.datepicker.regional['#{locale}'] = #{locale_date_options.to_json};"
          else
            nil
          end
        end.compact.join('')
      end
      
      def self.date_options(locale)
        begin
          date_picker_options = { :closeText => as_(:close),
            :prevText => as_(:previous),
            :nextText => as_(:next),
            :currentText => as_(:today),
            :monthNames => I18n.translate!('date.month_names', :locale => locale)[1..-1],
            :monthNamesShort => I18n.translate!('date.abbr_month_names', :locale => locale)[1..-1],
            :dayNames => I18n.translate!('date.day_names', :locale => locale),
            :dayNamesShort => I18n.translate!('date.abbr_day_names', :locale => locale),
            :dayNamesMin => I18n.translate!('date.abbr_day_names', :locale => locale),
            :changeYear => true,
            :changeMonth => true,
          }

          as_date_picker_options = I18n.translate! :date_picker_options, :scope => :active_scaffold, :locale => locale, :default => ''
          date_picker_options.merge!(as_date_picker_options) if as_date_picker_options.is_a? Hash
          Rails.logger.warn "ActiveScaffold: Missing date picker localization for your locale: #{locale}" if as_date_picker_options.blank?

          js_format = self.to_datepicker_format(I18n.translate!('date.formats.default', :locale => locale, :default => ''))
          date_picker_options[:dateFormat] = js_format unless js_format.blank?
          date_picker_options
        rescue
          raise if locale == I18n.locale
        end
      end

      def self.datetime_options_for_locales
        I18n.available_locales.collect do |locale|
          locale_datetime_options = datetime_options(locale)
          if locale_datetime_options
            "$.timepicker.regional['#{locale}'] = #{locale_datetime_options.to_json};"
          else
            nil
          end
        end.compact.join('')
      end
      
      def self.datetime_options(locale)
        begin
          rails_time_format = I18n.translate! 'time.formats.picker', :locale => locale
          datetime_picker_options = {:ampm => false,
            :hourText => I18n.translate!('datetime.prompts.hour', :locale => locale),
            :minuteText => I18n.translate!('datetime.prompts.minute', :locale => locale),
            :secondText => I18n.translate!('datetime.prompts.second', :locale => locale)
          }

          as_datetime_picker_options = I18n.translate! :datetime_picker_options, :scope => :active_scaffold, :locale => locale, :default => ''
          datetime_picker_options.merge!(as_datetime_picker_options) if as_datetime_picker_options.is_a? Hash
          Rails.logger.warn "ActiveScaffold: Missing datetime picker localization for your locale: #{locale}" if as_datetime_picker_options.blank?

          date_format, time_format = self.split_datetime_format(self.to_datepicker_format(rails_time_format))
          datetime_picker_options[:dateFormat] = date_format unless date_format.nil?
          unless time_format.nil?
            datetime_picker_options[:timeFormat] = time_format
            datetime_picker_options[:ampm] = true if rails_time_format.include?('%I')
          end
          datetime_picker_options
        rescue
          raise if locale == I18n.locale
        end
      end
      
      def self.to_datepicker_format(rails_format)
        return nil if rails_format.nil?
        if rails_format =~ /%[cUWwxXZz]/
          Rails.logger.warn("AS DatePicker::Helper: rails date format #{rails_format} includes options which can't be converted to jquery datepicker format. Options %c, %U, %W, %w, %x %X, %z, %Z are not supported by datepicker and will be removed")
          nil
        end
        js_format = rails_format.dup
        js_format.gsub! /([ ]|^)([^% ]\S*)/, " '\\2'"
        DATE_FORMAT_CONVERSION.each do |key, value|
          js_format.gsub!(key, value)
        end
        js_format
      end
      
      def self.split_datetime_format(datetime_format)
        date_format = datetime_format
        time_format = nil
        time_start_indicators = %w{HH hh mm tt ss}
        unless datetime_format.nil?
          start_indicator = time_start_indicators.detect {|indicator| datetime_format.include?(indicator)}
          unless start_indicator.nil?
            pos_time_format = datetime_format.index(start_indicator)
            date_format = datetime_format.to(pos_time_format - 1).strip
            time_format = datetime_format.from(pos_time_format).strip
          end
        end
        return date_format, time_format
      end
      
      module DatepickerColumnHelpers
        def datepicker_split_datetime_format(datetime_format)
          ActiveScaffold::Bridges::DatePicker::Helper.split_datetime_format(datetime_format)
        end
        
        def to_datepicker_format(rails_format)
          ActiveScaffold::Bridges::DatePicker::Helper.to_datepicker_format(rails_format)
        end
        
        def datepicker_format_options(column, format, options)
          if column.form_ui == :date_picker
            js_format = to_datepicker_format(I18n.translate!("date.formats.#{format}"))
            options['date:dateFormat'] = js_format unless js_format.nil?
          else
            rails_time_format = I18n.translate!("time.formats.#{format}")
            date_format, time_format = datepicker_split_datetime_format(self.to_datepicker_format(rails_time_format))
            options['date:dateFormat'] = date_format unless date_format.nil?
            unless time_format.nil?
              options['time:timeFormat'] = time_format
              options['time:ampm'] = true if rails_time_format.include?('%I')
            end
          end unless format == :default
        end
      end
      
      module SearchColumnHelpers
        def active_scaffold_search_date_bridge_calendar_control(column, options, current_search, name)
          if current_search.is_a? Hash
            value = controller.class.condition_value_for_datetime(current_search[name], column.search_ui == :date_picker ? :to_date : :to_time)
          else
            value = current_search
          end
          options = column.options.merge(options).except!(:include_blank, :discard_time, :discard_date, :value)
          options = active_scaffold_input_text_options(options.merge(column.options))
          options[:class] << " #{column.search_ui.to_s}"
          options[:style] = (options[:show].nil? || options[:show]) ? nil : "display: none"
          format = options.delete(:format) || (column.search_ui == :date_picker ? :default : :picker)
          datepicker_format_options(column, format, options)
          text_field_tag("#{options[:name]}[#{name}]", value ? l(value, :format => format) : nil, options.merge(:id => "#{options[:id]}_#{name}", :name => "#{options[:name]}[#{name}]"))
        end
      end
      
      module FormColumnHelpers
        def active_scaffold_input_date_picker(column, options)
          options = active_scaffold_input_text_options(options.merge(column.options))
          options[:class] << " #{column.form_ui.to_s}"
          value = controller.class.condition_value_for_datetime(@record.send(column.name), column.form_ui == :date_picker ? :to_date : :to_time)
          format = options.delete(:format) || (column.form_ui == :date_picker ? :default : :picker)
          datepicker_format_options(column, format, options)
          options[:value] = (value ? l(value, :format => format) : nil)
          text_field(:record, column.name, options)
        end
      end
    end
  end
end
