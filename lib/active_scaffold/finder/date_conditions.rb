# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module ClassMethods
      module DateConditions
        def tables_for_translating_days_and_months(format)
          keys = {
            '%A' => 'date.day_names',
            '%a' => 'date.abbr_day_names',
            '%B' => 'date.month_names',
            '%b' => 'date.abbr_month_names'
          }
          key_index = keys.keys.index_with { |key| format.index(key) }
          keys.select! { |k, _| key_index[k] }
          keys.sort_by { |k, _| key_index[k] }.map do |_, k|
            I18n.t(k).compact.zip(I18n.t(k, locale: :en).compact).to_h
          end
        end

        def translate_days_and_months(value, format)
          translated = +''
          value = value.dup # ensure the string can be changed
          tables_for_translating_days_and_months(format).each do |table|
            regexp = Regexp.union(table.keys)
            index = value.index(regexp)
            next unless index

            translated << value.slice!(0...index)
            value.sub!(regexp) do |str|
              translated << table[str]
              ''
            end
          end
          translated << value
        end

        def format_for_datetime(column, value, ui_name, ui_options)
          parts = Date._parse(value)
          time_parts = [[:hour, '%H'], [:min, '%M'], [:sec, '%S']].filter_map do |part, format_part|
            format_part if parts[part].present?
          end
          format = "%Y-%m-%d #{time_parts.join(':')} #{'%z' if parts[:offset].present?}"

          format.gsub!(/.*(?=%H)/, '') if !parts[:year] && !parts[:month] && !parts[:mday]
          [format, parts[:offset]]
        end

        def local_time_from_hash(value, conversion = :to_time)
          time = Time.zone.local(*%i[year month day hour minute second].collect { |part| value[part].to_i })
          time.send(conversion)
        rescue StandardError => e
          message = "Error creating time from #{value.inspect}:"
          Rails.logger.warn "#{message}\n#{e.message}\n#{e.backtrace.join("\n")}"
          nil
        end

        def format_for_date(column, value, ui_name, ui_options)
          if ui_options[:format]
            format = I18n.t("date.formats.#{ui_options[:format]}")
            format.gsub!(/%-d|%-m|%_m/) { |s| s.gsub(/[-_]/, '') } # strptime fails with %-d, %-m, %_m
            en_value = I18n.locale == :en ? value : translate_days_and_months(value, format)
          end
          [en_value || value, format]
        end

        def parse_date_with_format(value, format)
          Date.strptime(value, *format)
        rescue StandardError => e
          message = "Error parsing date from #{value}"
          message << ", with format #{format}" if format
          Rails.logger.warn "#{message}:\n#{e.message}\n#{e.backtrace.join("\n")}"
          nil
        end

        def parse_time_with_format(value, format, offset)
          format.gsub!(/%-d|%-m|%_m/) { |s| s.gsub(/[-_]/, '') } # strptime fails with %-d, %-m, %_m
          en_value = I18n.locale == :en ? value : translate_days_and_months(value, format)
          time = Time.strptime(en_value, format)
          offset ? time : Time.zone.local_to_utc(time).in_time_zone
        rescue StandardError => e
          message = "Error parsing time from #{en_value}"
          message << " (#{value})" if en_value != value
          message << ", with format #{format}" if format
          Rails.logger.warn "#{message}:\n#{e.message}\n#{e.backtrace.join("\n")}"
          nil
        end

        def condition_value_for_datetime(column, value, conversion = :to_time, ui_method: :search_ui, ui_options: nil)
          return if value.blank?

          ui_options ||= column.send(:"#{ui_method}_options") || column.options
          if value.is_a? Hash
            local_time_from_hash(value, conversion)
          elsif value.respond_to?(:strftime)
            value.send(conversion)
          elsif conversion == :to_date
            parse_date_with_format(*format_for_date(column, value, column.send(ui_method), ui_options))
          elsif value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/) # iso8601 format
            Time.zone.parse(value)
          else # datetime
            time = parse_time_with_format(value,
                                          *format_for_datetime(column, value, column.send(ui_method), ui_options))
            conversion == :to_time ? time : time.send(conversion)
          end
        end

        def datetime_conversion_for_condition(column)
          if column.column
            column.column_type == :date ? :to_date : :to_time
          else
            :to_time
          end
        end

        def condition_for_datetime(column, value, like_pattern = nil)
          operator =
            if ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(value['opt']) && value['opt'] != 'BETWEEN'
              value['opt']
            end
          from_value, to_value = datetime_from_to(column, value)

          if column.search_sql.is_a? Proc
            column.search_sql.call(from_value, to_value, operator)
          elsif ActiveScaffold::Finder::NULL_COMPARATORS.include?(value['opt'])
            condition_for_null_type(column, value['opt'], like_pattern)
          elsif operator.nil?
            ['%<search_sql>s BETWEEN ? AND ?', from_value, to_value] unless from_value.nil? || to_value.nil?
          else
            ["%<search_sql>s #{value['opt']} ?", from_value] unless from_value.nil?
          end
        end

        def datetime_from_to(column, value)
          conversion = datetime_conversion_for_condition(column)
          case value['opt']
          when 'RANGE'
            datetime_from_to_for_range(column, value).map(&conversion)
          when 'PAST', 'FUTURE'
            datetime_from_to_for_trend(column, value).map { |date| date&.public_send(conversion) }
          else
            %w[from to].collect { |field| condition_value_for_datetime(column, value[field], conversion) }
          end
        end

        def datetime_now
          Time.zone.now
        end

        # Override to allow additional normalized duration units offered by the trend dropdown.
        def valid_datetime_trend_unit?(unit)
          DATE_UNITS.include?(unit.upcase) || TIME_UNITS.include?(unit.upcase)
        end

        def datetime_from_to_for_trend(column, value)
          unit = value['unit'].to_s.downcase.pluralize
          return [nil, nil] unless valid_datetime_trend_unit?(unit)

          trend_number = [value['number'].to_i, 1].max
          duration = trend_number.public_send(unit)
          now = datetime_now
          case value['opt']
          when 'PAST'
            if datetime_column_date?(column)
              [now.beginning_of_day.ago(duration), now.end_of_day]
            else
              [now.ago(duration), now]
            end
          when 'FUTURE'
            if datetime_column_date?(column)
              [now.beginning_of_day, now.end_of_day.in(duration)]
            else
              [now, now.in(duration)]
            end
          end
        end

        def datetime_from_to_for_range(column, value)
          case value['range']
          when 'TODAY'
            [datetime_now.beginning_of_day, datetime_now.end_of_day]
          when 'YESTERDAY'
            [datetime_now.ago(1.day).beginning_of_day, datetime_now.ago(1.day).end_of_day]
          when 'TOMORROW'
            [datetime_now.in(1.day).beginning_of_day, datetime_now.in(1.day).end_of_day]
          else
            datetime_from_to_for_named_range(value['range'])
          end
        end

        def datetime_from_to_for_named_range(named_range)
          range_type, range = named_range.downcase.split('_')
          raise ArgumentError unless %w[week month year].include?(range)
          return [nil, nil] unless %w[this prev next].include?(range_type)

          now = datetime_now
          now = now.ago(1.send(range.to_sym)) if range_type == 'prev'
          now = now.in(1.send(range.to_sym)) if range_type == 'next'
          [now.send(:"beginning_of_#{range}"), now.send(:"end_of_#{range}")]
        end

        def datetime_column_date?(column)
          column.column&.type == :date
        end
      end
    end
  end
end
