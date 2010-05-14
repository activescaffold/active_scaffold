module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      def active_scaffold_input_datepicker(column, options)
        method = "date#{'time' if column.column.type == :datetime}_select"
        options[:include_blank] = true if column.column and column.column.null and [:date, :datetime, :time].include?(column.column.type)
        html_options = options.update(column.options).delete(:html_options) || {}
        options = active_scaffold_input_date_options(column, options)
        args = [:record, column.name, options, html_options]
        self.send(method, *args) + date_picker(*args)
      end
    end
  end
end
