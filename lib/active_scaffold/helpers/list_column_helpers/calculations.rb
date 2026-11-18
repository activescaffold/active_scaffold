# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      module Calculations
        def column_calculation(column, id_condition: true)
          if column.calculate.instance_of? Proc
            column.calculate.call(@records)
          elsif column.calculate.in? %i[count sum average minimum maximum]
            calculate_query(id_condition: id_condition).calculate(column.calculate, column.grouped_select)
          end
        end

        def render_column_calculation(column, id_condition: true)
          calculation = column_calculation(column, id_condition: id_condition)
          override_formatter = "render_#{column.name}_#{column.calculate.is_a?(Proc) ? :calculate : column.calculate}"
          calculation = send(override_formatter, calculation) if respond_to? override_formatter
          format_column_calculation(column, calculation)
        end

        def format_column_calculation(column, calculation)
          label = "#{as_(column.calculate)}: " unless column.calculate.is_a? Proc
          "#{label}#{format_column_value(nil, column, calculation)}"
        end
      end
    end
  end
end
