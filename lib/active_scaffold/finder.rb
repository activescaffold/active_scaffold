# frozen_string_literal: true

require 'active_scaffold/finder/subquery_conditions'
require 'active_scaffold/finder/conditions'
require 'active_scaffold/finder/date_conditions'
require 'active_scaffold/finder/collection'
require 'active_scaffold/finder/pagination'
require 'active_scaffold/finder/querying'

module ActiveScaffold
  module Finder
    def self.like_operator(column = nil)
      return column.like_operator if column&.like_operator

      connection = column&.active_record_class&.connection || ::ActiveRecord::Base.connection
      connection.adapter_name.in?(%w[PostgreSQL PostGIS]) ? 'ILIKE' : 'LIKE'
    end

    def self.logical_comparators
      ActiveScaffold::Finder::LOGICAL_COMPARATORS if ActiveScaffold::Finder.const_defined? :LOGICAL_COMPARATORS
    end

    module ClassMethods
      def self.extended(klass)
        return unless klass.active_scaffold_config

        if klass.active_scaffold_config.active_record?
          klass.extend ActiveRecord
        elsif klass.active_scaffold_config.mongoid?
          klass.extend Mongoid
        end
      end

      # Takes a collection of search terms (the tokens) and creates SQL that
      # searches all specified ActiveScaffold columns. A row will match if each
      # token is found in at least one of the columns.
      def conditions_for_columns(tokens, columns, text_search = :full)
        # if there aren't any columns, then just return a nil condition
        return unless columns.any?

        tokens = [tokens] if tokens.is_a? String
        tokens = type_casted_tokens(tokens, columns, like_pattern(text_search))
        create_conditions_for_columns(tokens, columns)
      end

      def type_casted_tokens(tokens, columns, like_pattern)
        tokens.map do |value|
          columns.to_h do |column|
            casted_value =
              if column.text?
                value = column.active_record_class.sanitize_sql_like(value) if column.active_record?
                like_pattern.sub('?', value)
              else
                ActiveScaffold::Core.column_type_cast(value, column.column, column.model)
              end
            [column.name, casted_value]
          end
        end
      end

      module ActiveRecord
        def create_conditions_for_columns(tokens, columns)
          where_clauses = []
          columns.each do |column|
            column.search_sql.each do |search_sql|
              where_clauses << "#{search_sql} #{column.text? ? ActiveScaffold::Finder.like_operator(column) : '='} ?"
            end
          end
          phrase = where_clauses.join(' OR ')

          tokens.map do |columns_token|
            columns.each_with_object([phrase]) do |column, condition|
              condition.concat([columns_token[column.name]] * column.search_sql.size)
            end
          end
        end

        def like_pattern(text_search)
          case text_search
          when :full then '%?%'
          when :start then '?%'
          when :end then '%?'
          else '?'
          end
        end
      end

      module Mongoid
        def create_conditions_for_columns(tokens, columns)
          conditions = tokens.map do |columns_token|
            token_conditions = columns.map do |column|
              value = columns_token[column.name]
              value = /#{value}/ if column.text?
              column.search_sql.map do |search_sql|
                # call .to_s so String is returned from CowProxy::String in threadsafe mode
                # in other case, or method from Mongoid would fail
                {search_sql.to_s => value}
              end
            end.flatten
            active_scaffold_config.model.or(token_conditions).selector
          end
          [active_scaffold_config.model.and(conditions).selector]
        end

        def like_pattern(text_search)
          case text_search
          when :full then '?'
          when :start then '^?'
          when :end then '?$'
          else '^?$'
          end
        end
      end

      # Generates an SQL condition for the given ActiveScaffold column based on
      # that column's database type (or form_ui ... for virtual columns?).
      include SubqueryConditions
      include Conditions
      include DateConditions
    end

    NUMERIC_COMPARATORS = [
      '=',
      '>=',
      '<=',
      '>',
      '<',
      '!=',
      'BETWEEN'
    ].freeze
    STRING_COMPARATORS = {
      contains:          '%?%',
      begins_with:       '?%',
      ends_with:         '%?',
      doesnt_contain:    'not_%?%',
      doesnt_begin_with: 'not_?%',
      doesnt_end_with:   'not_%?'
    }.freeze
    NULL_COMPARATORS = %w[null not_null].freeze
    DATE_COMPARATORS = %w[PAST FUTURE RANGE].freeze
    DATE_UNITS = %w[DAYS WEEKS MONTHS YEARS].freeze
    TIME_UNITS = %w[SECONDS MINUTES HOURS].freeze
    DATE_RANGES = %w[TODAY YESTERDAY TOMORROW THIS_WEEK PREV_WEEK NEXT_WEEK THIS_MONTH PREV_MONTH NEXT_MONTH THIS_YEAR
                     PREV_YEAR NEXT_YEAR].freeze

    def self.included(klass)
      klass.extend ClassMethods
    end

    protected

    attr_writer :active_scaffold_conditions, :active_scaffold_preload, :active_scaffold_joins,
                :active_scaffold_outer_joins, :active_scaffold_references, :active_scaffold_relations

    include Collection
    include Pagination
    include Querying
  end
end
