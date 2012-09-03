module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ShowColumnHelpers
      def show_column_value(record, column)
        # check for an override helper
        if (method = show_column_override(column))
          # we only pass the record as the argument. we previously also passed the formatted_value,
          # but mike perham pointed out that prohibited the usage of overrides to improve on the
          # performance of our default formatting. see issue #138.
          send(method, record, column)
        # second, check if the dev has specified a valid list_ui for this column
        elsif column.list_ui and (method = override_show_column_ui(column.list_ui))
          send(method, record, column)
        else
          if column.column and (method = override_show_column_ui(column.column.type))
            send(method, record, column)
          else
            get_column_value(record, column)
          end
        end
      end

      def active_scaffold_show_text(record, column)
        simple_format(clean_column_value(record.send(column.name)))
      end

      def show_column_override(column)
        override_helper column, 'show_column'
      end

      # the naming convention for overriding show types with helpers
      def override_show_column_ui(list_ui)
        method = "active_scaffold_show_#{list_ui}"
        method if respond_to? method
      end
    end
  end
end
