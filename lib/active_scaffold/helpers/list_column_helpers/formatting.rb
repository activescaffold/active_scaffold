# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      module Formatting
        # There are two basic ways to clean a column's value: h() and sanitize(). The latter is useful
        # when the column contains *valid* html data, and you want to just disable any scripting. People
        # can always use field overrides to clean data one way or the other, but having this override
        # lets people decide which way it should happen by default.
        #
        # Why is it not a configuration option? Because it seems like a somewhat rare request. But it
        # could eventually be an option in config.list (and config.show, I guess).
        def clean_column_value(value)
          h(value)
        end

        def read_value_from_record(record, column, join_text = ' - ')
          if grouped_search? && column == search_group_column
            value =
              if search_group_function
                record[column.name]
              elsif search_group_column.group_by
                safe_join column.group_by.map.with_index { |_, index| record["#{column.name}_#{index}"] }, join_text
              end
          end
          value || record.send(column.name)
        end

        FORM_UI_WITH_OPTIONS = %i[select radio].freeze
        def format_column_value(record, column, value = nil)
          value ||= read_value_from_record(record, column) unless record.nil?
          if _as_grouped_search_column?(column)
            format_grouped_search_column(value, column.options)
          elsif column.association.nil?
            _as_format_non_association_value(value, column)
          else
            if column.association.collection?
              associated_size = _as_prepare_collection_association(record, column,
                                                                   value)
            end
            format_association_value(value, column, associated_size)
          end
        end

        def _as_grouped_search_column?(column)
          grouped_search? && column == search_group_column && (search_group_function || search_group_column.group_by)
        end

        def _as_format_non_association_value(value, column)
          if value.is_a? Numeric
            format_number_value(value, column.options)
          else
            format_value(value, column.options, column)
          end
        end

        def _as_prepare_collection_association(record, column, value)
          # Get count before caching the association.
          associated_size = column_association_size(record, column, value) if column.associated_number?
          if column.association.respond_to_target? && !value.loaded?
            cache_association(record.association(column.name), column, associated_size)
          end
          associated_size
        end
        private :_as_grouped_search_column?, :_as_format_non_association_value, :_as_prepare_collection_association

        def column_association_size(record, column, value)
          cached_counts = @counts&.dig(column.name)
          if cached_counts
            key = column.association.primary_key if count_on_association_class?(column)
            cached_counts[record.send(key || :id)] || 0
          else
            value.size
          end
        end

        def format_number_value(value, options = {})
          return clean_column_value(value) unless value

          i18n_options = options[:i18n_options] || {}
          formatted_value =
            case options[:format]
            when :size then number_to_human_size(value, i18n_options)
            when :percentage then number_to_percentage(value, i18n_options)
            when :currency then number_to_currency(value, i18n_options)
            when :i18n_number then _as_format_i18n_number(value, i18n_options)
            else value
            end
          clean_column_value(formatted_value)
        end

        def _as_format_i18n_number(value, options)
          formatter = value.is_a?(Integer) ? :number_with_delimiter : :number_with_precision
          send(formatter, value, options)
        end
        private :_as_format_i18n_number

        def format_grouped_search_column(value, options = {})
          case search_group_function
          when 'year_month'
            year, month = value.to_s.scan(/(\d*)(\d{2})/)[0]
            I18n.l(Date.new(year.to_i, month.to_i, 1), format: options[:group_format] || search_group_function.to_sym)
          when 'year_quarter'
            year, quarter = value.to_s.scan(/(\d*)(\d)/)[0]
            I18n.t(options[:group_format] || search_group_function, scope: 'date.formats', year: year, quarter: quarter)
          when 'quarter'
            I18n.t(options[:group_format] || search_group_function, scope: 'date.formats', num: value)
          when 'month'
            I18n.l(Date.new(Time.zone.today.year, value, 1),
                   format: options[:group_format] || search_group_function.to_sym)
          when 'year'
            value.to_i
          else
            value
          end
        end

        def association_join_text(column = nil)
          column_value = column&.association_join_text
          return column_value if column_value
          return @_association_join_text if defined? @_association_join_text

          @_association_join_text =
            if active_scaffold_config.actions.include?(:list)
              active_scaffold_config.list.association_join_text
            else
              ActiveScaffold::Config::List.association_join_text
            end
        end

        def format_collection_association_value(value, column, label_method, size)
          associated_limit = column.associated_limit
          if associated_limit.nil?
            safe_join(value.collect(&label_method), association_join_text(column))
          elsif associated_limit.zero?
            size if column.associated_number?
          else
            firsts = value.loaded? ? value[0, associated_limit] : value.limit(associated_limit)
            firsts = firsts.map(&label_method)
            firsts << '…' if value.size > associated_limit
            text = safe_join firsts, association_join_text(column)
            text << " (#{size})" if column.associated_number? && value.size > associated_limit
            text
          end
        end

        def format_singular_association_value(value, column, label_method)
          if column.association.polymorphic?
            "#{value.class.model_name.human}: #{value.send(label_method)}"
          else
            value.send(label_method)
          end
        end

        def format_association_value(value, column, size)
          method = (column.list_ui_options || column.options)[:label_method] || :to_label
          value =
            if column.association.collection?
              format_collection_association_value(value, column, method, size)
            elsif value
              format_singular_association_value(value, column, method)
            end
          format_value value, nil, column
        end

        def format_value(column_value, options = {}, column = nil)
          options ||= column&.options
          value =
            if column_empty?(column_value)
              empty_field_text(column)
            elsif column_value.is_a?(Time) || column_value.is_a?(Date)
              l(column_value, format: options&.dig(:format) || :default)
            elsif !!column_value == column_value # rubocop:disable Style/DoubleNegation -- fast check for boolean
              as_(column_value.to_s.to_sym)
            else
              column_value.to_s
            end
          clean_column_value(value)
        end

        def cache_association(association, column, size)
          associated_limit = column.associated_limit
          # We are not using eager loading. Cache the first records to avoid querying the whole association later.
          if associated_limit.nil?
            logger.warn "ActiveScaffold: Enable eager loading for #{column.name} association to reduce SQL queries"
          elsif associated_limit.positive?
            # load at least one record more, is needed to display '...'
            selected_columns = column.select_associated_columns || "#{association.klass.quoted_table_name}.*"
            association.target = association.reader.limit(associated_limit + 1).select(selected_columns).to_a
          elsif @cache_associations
            # set array with at least one element if size > 0, so blank? or present? works, saving [nil] may cause
            # exceptions
            association.target =
              if size.to_i.zero?
                []
              else
                ActiveScaffold::Registry.cache(:cached_empty_association, association.klass) { [association.klass.new] }
              end
          end
        end
      end
    end
  end
end
