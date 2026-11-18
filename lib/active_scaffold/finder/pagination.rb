# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module Pagination
      protected

      def add_order_expressions_to_select(query, sorting)
        return query unless query.respond_to?(:distinct_value) && query.distinct_value &&
                            active_scaffold_config.model.connection.needs_order_expressions_in_select?

        order_expressions = order_select_expressions(sorting)
        return query if order_expressions.empty?

        select_columns = query.select_values
        select_columns = ["#{active_scaffold_config.model.quoted_table_name}.*"] if select_columns.empty?
        query.reselect(*(select_columns + order_expressions).uniq)
      end

      def order_select_expressions(sorting)
        Array(sorting&.clause).flat_map { |order| order.is_a?(Hash) ? order.keys : [] }
      end

      def count_items(query, find_options = {}, count_includes = nil)
        count_includes ||= find_options[:includes] if find_options[:conditions].present?
        options = find_options.except(:select, :reorder, :order)
        # Keep includes in the count query because conditions may reference joined tables.
        options[:includes] = count_includes

        count = append_to_query(query, options).count

        # Converts count to an integer if ActiveRecord returned an OrderedHash
        # that happens when find_options contains a :group key
        count = count.length if count.is_a?(Hash)
        count
      end

      # returns a Paginator::Page (not from ActiveRecord::Paginator) for the given parameters
      # See finder_options for valid options
      def find_page(options = {})
        options.assert_valid_keys :sorting, :per_page, :page, :count_includes, :pagination, :select
        options[:per_page] ||= 999_999_999
        options[:page] ||= 1

        find_options, query = find_page_query(options)
        count_query = query

        count_after_first_page = count_after_loading_first_page?(options)
        if options[:pagination] && options[:pagination] != :infinite && !count_after_first_page
          count = count_items(query, find_options, options[:count_includes])
        end

        query = append_to_query(query, find_options)
        query = add_order_expressions_to_select(query, options[:sorting])
        if count_after_first_page
          first_page_items, count = delayed_page_count(query, count_query, find_options,
                                                       options)
        end
        # we build the paginator differently for method- and sql-based sorting
        pager = build_finder_pager(query, count, first_page_items, options)
        pager.page(options[:page])
      end

      def find_page_query(options)
        find_options = finder_options(options)
        query = filtered_query
        # where(nil) is needed because we need a relation.
        query = query.where(nil) if active_scaffold_config.active_record?
        [find_options, query]
      end

      def delayed_page_count(query, count_query, find_options, options)
        first_page_items = load_page_for_delayed_count(query, options[:per_page])
        count = first_page_items.size
        count = count_items(count_query, find_options, options[:count_includes]) if count == options[:per_page]
        [first_page_items, count]
      end

      def build_finder_pager(query, count, first_page_items, options)
        if options[:sorting]&.sorts_by_method?
          ::Paginator.new(count, options[:per_page]) do |offset, per_page|
            calculate_last_modified(query)
            sorted_collection = sort_collection_by_column(query.to_a, *options[:sorting].first)
            sorted_collection = sorted_collection.slice(offset, per_page) || [] if options[:pagination]
            sorted_collection
          end
        else
          ::Paginator.new(count, options[:per_page]) do |offset, per_page|
            if first_page_items && offset.zero?
              first_page_items
            else
              page_query = options[:pagination] ? append_to_query(query, offset: offset, limit: per_page) : query
              calculate_last_modified(page_query)
              page_query
            end
          end
        end
      end

      def count_after_loading_first_page?(options)
        active_scaffold_config.active_record? &&
          finite_pagination?(options) &&
          first_page?(options) &&
          !options[:sorting]&.sorts_by_method?
      end

      def finite_pagination?(options)
        options[:pagination] && options[:pagination] != :infinite
      end

      def first_page?(options)
        options[:page].to_i == 1
      end

      private :first_page?, :finite_pagination?

      def load_page_for_delayed_count(query, per_page)
        page_query = append_to_query(query, offset: 0, limit: per_page)
        calculate_last_modified(page_query)
        page_query.to_a
      end

      def calculate_last_modified(query)
        return unless conditional_get_support? && ActiveScaffold::OrmChecks.columns_hash(query.klass)['updated_at']

        @last_modified = query.maximum(:updated_at)
      end
    end
  end
end
