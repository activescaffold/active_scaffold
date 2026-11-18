# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module ClassMethods
      module SubqueryConditions
        def subquery_condition(column, sql, options, values)
          relation, subquery = build_search_subquery(sql, options, values)
          conditions = subquery_conditions(column, options, subquery)
          add_polymorphic_subquery_condition(column, relation, conditions)
          conditions
        end

        def build_search_subquery(sql, options, values)
          relation, *columns = options[:subquery]
          conditions = [columns.map { |search_sql| sql % {search_sql: search_sql} }.join(' OR ')]
          conditions += values * columns.size if values.present?
          subquery = relation.where(conditions)
          subquery = subquery.select(relation.primary_key) if subquery.select_values.blank?
          [relation, subquery]
        end

        def subquery_conditions(column, options, subquery)
          conditions = [["#{options[:field] || column.field} IN (?)",
                         options[:conditions]&.first].compact.join(' AND ')]
          conditions << subquery
          conditions.concat options[:conditions][1..] if options[:conditions]
          conditions
        end

        def add_polymorphic_subquery_condition(column, relation, conditions)
          return unless column.association&.polymorphic?

          conditions[0] << " AND #{column.quoted_foreign_type} = ?"
          conditions << relation.base_class.sti_name
        end
      end
    end
  end
end
