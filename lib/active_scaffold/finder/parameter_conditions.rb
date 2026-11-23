# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module ParameterConditions
      protected

      # Builds conditions from query parameters whose names match configured columns.
      def conditions_from_params
        return [{}] if active_scaffold_config.conditions_from_params_columns == []

        @conditions_from_params ||= begin
          conditions = [{}]
          columns = parameter_filter_columns
          params.except(:controller, :action, :page, :sort, :sort_direction, :format, :id).each do |key, value|
            distinct = key.match?(/!$/)
            column = columns[key.to_s[0..(distinct ? -2 : -1)]]
            next unless column

            key = column.name.to_sym
            next if active_scaffold_constraints[key]
            next if nested? && nested.param_name == key

            value = condition_value_from_param(value, column, active_scaffold_config.model)
            if distinct
              conditions << distinct_condition(key, value)
            else
              conditions[0][key] = value
            end
          end
          conditions
        end
      end

      def parameter_filter_columns
        columns = active_scaffold_config._columns_hash
        allowed_columns = active_scaffold_config.conditions_from_params_columns
        columns = columns.slice(*allowed_columns.map(&:to_s)) if allowed_columns
        columns.except(*active_scaffold_config.conditions_from_params_excluded_columns.map(&:to_s))
      end

      def distinct_condition(key, value)
        attribute = active_scaffold_config.model.arel_table[key]
        case value
        when Array
          attribute.not_in(value)
        when Range
          attribute.not_between(value)
        else
          attribute.not_eq(value)
        end
      end

      def condition_value_from_param(value, column, model)
        range = range_from_param(value, column)
        value = range.captures if range
        not_string = %i[string text].exclude?(column.type)
        value =
          if value.is_a?(Array)
            value.map { |item| conditional_cast_for_column(item, column, not_string, model) }
          elsif value == '' && (not_string || column.null)
            ActiveScaffold::Core.column_type_cast(column.default, column, model)
          else
            ActiveScaffold::Core.column_type_cast(value, column, model)
          end
        range ? Range.new(*value) : value
      end

      def conditional_cast_for_column(value, column, not_string, model)
        return if value == '' && not_string

        ActiveScaffold::Core.column_type_cast(value, column, model)
      end

      def range_from_param(value, column)
        supporting_range = %i[date datetime timestamp timestamptz integer decimal float bigint]
        return unless supporting_range.include?(column.type) && value.is_a?(String) && value.scan('..').size == 1

        value.match(/\A(.*)\.\.(.*)\z/)
      end
    end
  end
end
