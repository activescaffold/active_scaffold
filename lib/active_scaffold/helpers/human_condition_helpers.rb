# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with rendering of a human readable search statement
    module HumanConditionHelpers
      def active_scaffold_human_condition_for(column)
        return if (value = field_search_params[column.name.to_s]).nil?

        search_ui = column.search_ui
        search_ui ||= column.column_type if column.column
        if override_human_condition_column?(column)
          send(override_human_condition_column(column), value, {})
        elsif search_ui && override_human_condition?(search_ui)
          send(override_human_condition(search_ui), column, value)
        else
          logger.warn "undefined active_scaffold_human_condition method for search_ui #{search_ui} on column #{column.name}"
        end
      end

      def active_scaffold_human_filter_for(filter_option)
        filter_option.label
      end

      def active_scaffold_grouped_by_label
        text, = active_scaffold_config.field_search.group_options.find do |text, value|
          (value || text).to_s == field_search_params['active_scaffold_group']
        end
        active_scaffold_translated_option(active_scaffold_group_column, text).first if text
      end

      def format_human_condition(column, opt, from = nil, to = nil)
        attribute = column.label
        opt ||= :between if from && to
        opt ||= from ? '>=' : '<='
        from = to = nil if opt&.in? %w[null not_null]
        "#{attribute} #{as_(opt).downcase} #{from} #{to}"
      end

      def active_scaffold_human_condition_integer(column, value)
        from = format_number_value(controller.class.condition_value_for_numeric(column, value['from']), column.options) if value['from'].present?
        to = "- #{format_number_value(controller.class.condition_value_for_numeric(column, value['to']), column.options)}" if value['opt'] == 'BETWEEN'
        format_human_condition column, value['opt'].downcase, from, to
      end
      alias active_scaffold_human_condition_decimal active_scaffold_human_condition_integer
      alias active_scaffold_human_condition_float active_scaffold_human_condition_integer

      def active_scaffold_human_condition_range(column, value)
        opt = ActiveScaffold::Finder::STRING_COMPARATORS.key(value['opt']) || value['opt']
        to = "- #{value['to']}" if opt == 'BETWEEN'
        format_human_condition column, opt, "'#{value['from']}'", to
      end
      alias active_scaffold_human_condition_string active_scaffold_human_condition_range

      def active_scaffold_human_condition_datetime(column, value)
        case value['opt']
        when 'RANGE'
          range_type, range = value['range'].downcase.split('_')
          format = active_scaffold_human_condition_datetime_range_format(range_type, range)
          from, = controller.class.datetime_from_to(column, value)
          "#{column.label} = #{as_(value['range'].downcase).downcase} (#{I18n.l(from, format: format)})"
        when 'PAST', 'FUTURE', 'BETWEEN'
          from, to = controller.class.datetime_from_to(column, value)
          "#{column.label} #{as_('between').downcase} #{I18n.l(from)} - #{I18n.l(to)}"
        when 'null', 'not_null'
          "#{column.label} #{as_(value['opt'].downcase).downcase}"
        else
          from, = controller.class.datetime_from_to(column, value)
          "#{column.label} #{as_(value['opt'].downcase).downcase} #{I18n.l(from)}"
        end
      end
      alias active_scaffold_human_condition_time active_scaffold_human_condition_datetime
      alias active_scaffold_human_condition_date active_scaffold_human_condition_datetime
      alias active_scaffold_human_condition_timestamp active_scaffold_human_condition_datetime

      def active_scaffold_human_condition_datetime_range_format(range_type, range)
        case range
        when 'week'
          first_day_of_week = I18n.t 'active_scaffold.date_picker_options.firstDay'
          if first_day_of_week == 1
            '%W %Y'
          else
            '%U %Y'
          end
        when 'month'
          '%b %Y'
        when 'year'
          '%Y'
        else
          I18n.t 'date.formats.default'
        end
      end
      # def active_scaffold_human_condition_date(column, value)
      #   conversion = column.column_type == :date ? :to_date : :to_time
      #   from = controller.class.condition_value_for_datetime(column, value['from'], conversion)
      #   from = I18n.l from if from
      #   to = controller.class.condition_value_for_datetime(column, value['to'], conversion) if value['opt'] == 'BETWEEN' || (value['opt'].nil? && value['to'])
      #   to = "- #{I18n.l to}" if to
      #   format_human_condition column, value['opt'], from, to
      # end

      def active_scaffold_human_condition_boolean(column, value)
        attribute = column.label
        as_(:boolean, scope: :human_conditions, column: attribute, value: as_(value))
      end
      alias active_scaffold_human_condition_checkbox active_scaffold_human_condition_boolean

      def active_scaffold_human_condition_null(column, value)
        format_human_condition column, value.to_sym
      end

      def active_scaffold_human_condition_select(column, associated)
        attribute = column.label
        if associated.is_a?(Hash)
          return active_scaffold_human_condition_range(column, associated) unless associated['opt'] == '='

          associated = associated['from']
        end
        associated = [associated] unless associated.is_a? Array
        associated = associated.compact_blank
        if column.association
          method = column.options[:label_method] || :to_label
          associated = column.association.klass.where(id: associated.map(&:to_i)).map(&method)
        elsif column.options[:options]
          associated = associated.collect do |value|
            text, val = column.options[:options].find { |t, v| (v.nil? ? t : v).to_s == value.to_s }
            value = active_scaffold_translated_option(column, text, val).first if text
            value
          end
        end
        as_(:association, scope: :human_conditions, column: attribute, value: associated.join(', '))
      end
      alias active_scaffold_human_condition_multi_select active_scaffold_human_condition_select
      alias active_scaffold_human_condition_select_multiple active_scaffold_human_condition_select
      alias active_scaffold_human_condition_record_select active_scaffold_human_condition_select
      alias active_scaffold_human_condition_chosen active_scaffold_human_condition_select
      alias active_scaffold_human_condition_multi_chosen active_scaffold_human_condition_select

      # the naming convention for overriding form fields with helpers
      def override_human_condition_column(column)
        override_helper column, 'human_condition_column'
      end
      alias override_human_condition_column? override_human_condition_column

      def override_human_condition?(search_ui)
        respond_to?(override_human_condition(search_ui))
      end

      # the naming convention for overriding human condition search_ui types
      def override_human_condition(search_ui)
        "active_scaffold_human_condition_#{search_ui}"
      end
    end
  end
end
