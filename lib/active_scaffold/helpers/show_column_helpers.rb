module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ShowColumnHelpers
      def show_column_value(record, column)
        # check for an override helper
        if show_column_override? column
          # we only pass the record as the argument. we previously also passed the formatted_value,
          # but mike perham pointed out that prohibited the usage of overrides to improve on the
          # performance of our default formatting. see issue #138.
          send(show_column_override(column), record)
        # second, check if the dev has specified a valid list_ui for this column
        elsif column.list_ui and override_show_column_ui?(column.list_ui)
          send(override_show_column_ui(column.list_ui), column, record)
        else
          if column.column and override_show_column_ui?(column.column.type)
            send(override_show_column_ui(column.column.type), column, record)
          else
            get_column_value(record, column)
          end
        end
      end

      def active_scaffold_show_text(column, record)
        simple_format(clean_column_value(record.send(column.name)))
      end

      def show_column_override_name(column, old = false)
        "#{clean_class_name(column.active_record_class.name) + '_' unless old}#{clean_column_name(column.name)}_show_column"
      end

      def show_column_override(column)
        method = show_column_override_name(column)
        return method if respond_to?(method)
        old_method = show_column_override_name(column, true)
        if respond_to?(old_method)
          ActiveSupport::Deprecation.warn("You are using an old naming schema for overrides, you should name the helper #{method} instead of #{old_method}")
          old_method
        end
      end
      alias_method :show_column_override?, :show_column_override

      def override_show_column_ui?(list_ui)
        respond_to?(override_show_column_ui(list_ui))
      end

      # the naming convention for overriding show types with helpers
      def override_show_column_ui(list_ui)
        "active_scaffold_show_#{list_ui}"
      end
    end
  end
end
