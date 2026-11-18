# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module ClassMethods
      module Conditions
        def condition_for_column(column, value, text_search, session)
          like_pattern = like_pattern(text_search)
          value = value.with_indifferent_access if value.is_a? Hash
          column_method = "condition_for_#{column.name}_column"
          if respond_to?(column_method)
            args = [column, value, like_pattern]
            args << session if method(column_method).arity == 4
            return send(:"condition_for_#{column.name}_column", *args)
          end
          return unless column.searchable? && value.present?

          search_ui = column.search_ui || column.column_type
          begin
            sql, *values = dispatch_condition_for_column(column, value, like_pattern, search_ui)
            return nil unless sql
            return sql if sql.is_a? ::ActiveRecord::Relation

            build_condition_for_column(column, sql, values)
          rescue StandardError => e
            message = "on the ActiveScaffold column :#{column.name}, search_ui = #{search_ui} in #{name}"
            ActiveScaffold.log_exception(e, message)
            raise e, "#{e.message} -- #{message}", e.backtrace
          end
        end

        def dispatch_condition_for_column(column, value, like_pattern, search_ui)
          if search_ui && respond_to?(:"condition_for_#{search_ui}_type")
            send(:"condition_for_#{search_ui}_type", column, value, like_pattern)
          elsif column.search_sql.instance_of? Proc
            column.search_sql.call(value)
          else
            condition_for_search_ui(column, value, like_pattern, search_ui)
          end
        end

        def build_condition_for_column(column, sql, values)
          where_values = []
          sql_conditions = []
          column.search_sql.each do |search_sql|
            if search_sql.is_a?(Hash)
              subquery_sql, *subquery_values = subquery_condition(column, sql, search_sql, values)
              sql_conditions << subquery_sql
              where_values.concat subquery_values
            else
              sql_conditions << (sql % {search_sql: search_sql})
              where_values.concat values
            end
          end
          [sql_conditions.join(' OR '), *where_values]
        end

        def condition_for_search_ui(column, value, like_pattern, search_ui)
          case search_ui
          when :boolean, :checkbox
            condition_for_boolean(column, value)
          when :integer, :decimal, :float
            condition_for_numeric(column, value)
          when :string, :range
            return condition_for_single_value(column, value, like_pattern) unless value.is_a?(Hash)

            condition_for_range(column, value, like_pattern)
          when :date, :time, :datetime, :timestamp, :timestamptz
            condition_for_datetime(column, value)
          when :select, :select_multiple, :draggable, :multi_select, :country, :usa_state,
               :chosen, :multi_chosen, :choices, :multi_choices
            return condition_for_array(column, value) unless value.is_a?(Hash)

            condition_for_range(column, value, like_pattern)
          else
            condition_for_single_value(column, value, like_pattern)
          end
        end

        def condition_for_boolean(column, value)
          return condition_for_null_type(column, value) if value == 'null'

          cast_value = column.column ? ActiveScaffold::Core.column_type_cast(value, column.column, column.model) : value
          ['%<search_sql>s = ?', cast_value]
        end

        def condition_for_numeric(column, value)
          if !value.is_a?(Hash)
            ['%<search_sql>s = ?', condition_value_for_numeric(column, value)]
          elsif ActiveScaffold::Finder::NULL_COMPARATORS.include?(value[:opt])
            condition_for_null_type(column, value[:opt])
          elsif value[:from].blank? || ActiveScaffold::Finder::NUMERIC_COMPARATORS.exclude?(value[:opt])
            nil
          elsif value[:opt] == 'BETWEEN'
            ['(%<search_sql>s BETWEEN ? AND ?)', condition_value_for_numeric(column, value[:from]),
             condition_value_for_numeric(column, value[:to])]
          else
            ["%<search_sql>s #{value[:opt]} ?", condition_value_for_numeric(column, value[:from])]
          end
        end

        def condition_value_for_numeric(column, value)
          return value if value.nil?

          value = column.number_to_native(value) if column.options[:format] && column.search_ui != :number
          case column.search_ui || column.column_type
          when :integer   then ::ActiveRecord::Type::Integer.new.cast(value)
          when :float     then value.to_f
          when :decimal   then ::ActiveRecord::Type::Decimal.new.cast(value)
          else
            value
          end
        end

        def condition_for_single_value(column, value, like_pattern = nil)
          if column.text?
            value = column.active_record_class.sanitize_sql_like(value) if column.active_record?
            ["%<search_sql>s #{ActiveScaffold::Finder.like_operator(column)} ?", like_pattern.sub('?', value)]
          else
            ['%<search_sql>s = ?', ActiveScaffold::Core.column_type_cast(value, column.column, column.model)]
          end
        end

        def condition_for_array(column, value)
          values = Array(value).compact_blank
          ['%<search_sql>s in (?)', values] if values.present?
        end

        def condition_for_record_select_type(column, value, like_pattern = nil)
          if value.is_a?(Array)
            value = value.compact_blank
            ['%<search_sql>s IN (?)', value] if value.present?
          else
            ['%<search_sql>s = ?', value]
          end
        end

        def condition_for_null_type(column, value, like_pattern = nil)
          case value.to_s
          when 'null'
            ['%<search_sql>s is null', []]
          when 'not_null'
            ['%<search_sql>s is not null', []]
          end
        end

        def condition_for_range(column, value, like_pattern = nil)
          if ActiveScaffold::Finder::NULL_COMPARATORS.include?(value[:opt])
            condition_for_null_type(column, value[:opt], like_pattern)
          elsif value[:from].is_a?(Array) # opt can be only =
            condition_for_array(column, value[:from])
          elsif value[:from].blank?
            nil
          elsif ActiveScaffold::Finder::STRING_COMPARATORS.value?(value[:opt])
            condition_for_string_comparator(column, value)
          elsif value[:opt] == 'BETWEEN'
            ['(%<search_sql>s BETWEEN ? AND ?)', value[:from], value[:to]]
          elsif ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(value[:opt])
            ["%<search_sql>s #{value[:opt]} ?", value[:from]]
          elsif ActiveScaffold::Finder.logical_comparators&.include?(value[:opt])
            [logical_search_condition(column, value[:from], logical_search_parser(value[:opt]))]
          end
        end

        def condition_for_string_comparator(column, value)
          text = column.active_record? ? column.active_record_class.sanitize_sql_like(value[:from]) : value[:from]
          [
            "%<search_sql>s #{'NOT ' if value[:opt].start_with?('not_')}" \
            "#{ActiveScaffold::Finder.like_operator(column)} ?",
            value[:opt].sub('not_', '').sub('?', text)
          ]
        end

        def logical_search_parser(opt)
          operator =
            case opt
            when 'all_tokens' then 'AND'
            when 'any_token'  then 'OR'
            end
          parser = ActiveScaffold::Bridges::LogicalQueryParser::KeywordQueryParser.new(operator) if operator
          parser || ::LogicalQueryParser
        end

        def logical_search_condition(column, search, parser)
          model = column.active_record_class
          subquery = alias_query_for_same_table_exists(model.all) if column.logical_search.any?(Hash)
          query = parser.search(search, subquery || model, column.logical_search)
          if subquery
            model.where(same_table_exists_subquery(query))
          else
            query
          end
        end

        def alias_query_for_same_table_exists(query)
          query.instance_variable_set(:@table, query.table.dup)
          query.table.instance_variable_set(:@table_alias, "_#{query.table_name}_exists")
          query
        end

        def same_table_exists_subquery(query)
          alias_query_for_same_table_exists(query) unless query.table.table_alias
          subquery = query.where(query.arel_table[query.primary_key].eq(query.table[query.primary_key]))
          subquery.select(1).arel.exists
        end
      end
    end
  end
end
