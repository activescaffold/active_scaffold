# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ShowColumnHelpers
      def show_column_value(record, column, **tab_options)
        value_record = column.delegated_association ? record.send(column.delegated_association.name) : record
        return get_column_value(record, column) unless value_record

        # check for an override helper
        if (method = show_column_override(column))
          # we only pass the record as the argument. we previously also passed the formatted_value,
          # but mike perham pointed out that prohibited the usage of overrides to improve on the
          # performance of our default formatting. see issue #138.
          send(method, value_record, column)
        # second, check if the dev has specified a valid list_ui for this column
        elsif column.show_ui && (method = override_show_column_ui(column.show_ui))
          send(method, value_record, column, ui_options: tab_options.merge(column.show_ui_options || column.options))
        elsif column.column && (method = override_show_column_ui(column.column_type)) # rubocop:disable Lint/DuplicateBranch
          send(method, value_record, column)
        else
          get_column_value(value_record, column)
        end
      end

      def active_scaffold_show_text(record, column, ui_options: column.options)
        simple_format(clean_column_value(record.send(column.name)), ui_options[:html_options], ui_options)
      end

      def active_scaffold_show_horizontal(record, column, ui_options: column.options)
        raise ':horizontal show_ui must be used on association column' unless column.association

        vars = {column: column, parent_record: record, show_partial: :horizontal}
        render partial: 'show_association', locals: vars.merge(ui_options.slice(:tabbed_by, :tab_value, :tab_id))
      end

      def active_scaffold_show_vertical(record, column, ui_options: column.options)
        raise ':vertical show_ui must be used on association column' unless column.association

        render partial: 'show_association', locals: {column: column, parent_record: record, show_partial: :vertical}
      end

      def show_columns_for(record, parent_column = nil, hash = {})
        hash[record.class] ||= begin
          columns = active_scaffold_config_for(record.class).show.columns
          columns.constraint_columns = [parent_column.association.reverse] if parent_column
          columns
        end
      end

      def show_label(column)
        column.label
      end

      def show_column_override(column)
        override_helper column, 'show_column'
      end

      # the naming convention for overriding show types with helpers
      def override_show_column_ui(show_ui)
        method = "active_scaffold_show_#{show_ui}"
        method if respond_to? method
      end

      def display_link_in_show?(link, position)
        position == :header
      end
    end
  end
end
