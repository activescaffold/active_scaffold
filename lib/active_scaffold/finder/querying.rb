# frozen_string_literal: true

module ActiveScaffold
  module Finder
    module Querying
      protected

      # Returns a single record only when it is allowed for the specified security options.
      def find_if_allowed(id, security_options, klass = filtered_query)
        record = klass.find(id)
        security_options = {crud_type: security_options.to_sym} unless security_options.is_a? Hash
        unless record.authorized_for? security_options
          raise ActiveScaffold::RecordNotAllowed,
                "#{klass} with id = #{id}"
        end

        record
      end

      def calculate_subquery(id_condition: true)
        conditions = all_conditions(id_condition: id_condition)
        includes = active_scaffold_config.list.count_includes
        includes ||= active_scaffold_references if conditions.present?
        left_joins = active_scaffold_outer_joins
        left_joins += includes if includes
        primary_key = active_scaffold_config.primary_key
        selected_field = active_scaffold_config.columns[primary_key].field
        subquery = append_to_query(
          filtered_query,
          conditions: conditions, joins: joins_for_finder, left_joins: left_joins, select: selected_field
        )
        subquery.unscope(:order)
      end

      def calculate_query(id_condition: true)
        subquery = calculate_subquery(id_condition: id_condition)
        active_scaffold_config.model.where(active_scaffold_config.primary_key => subquery)
      end

      def append_to_query(relation, options)
        options.assert_valid_keys :where, :select, :having, :group, :reorder, :order, :limit, :offset,
                                  :joins, :left_joins, :left_outer_joins, :includes, :lock, :readonly,
                                  :from, :conditions, :preload, :references, :relations
        relation = options.compact_blank.inject(relation) do |rel, (k, v)|
          if k == :conditions
            apply_conditions(rel, *v)
          elsif k == :relations
            v.reduce(rel, :merge)
          else
            rel.send(k, v)
          end
        end
        distinct_query?(options) ? relation.distinct : relation
      end

      def distinct_query?(options)
        joins = [options[:left_outer_joins], options[:left_joins]].flatten.compact
        model = active_scaffold_config.model

        joins.any? do |join|
          next true unless join.is_a?(Symbol)

          model.reflect_on_association(join)&.macro != :belongs_to
        end
      end

      def joins_for_finder
        case joins_for_collection
        when String
          [joins_for_collection]
        when Array
          joins_for_collection
        else
          []
        end + active_scaffold_joins
      end

      def apply_conditions(relation, *conditions)
        conditions.compact_blank.inject(relation) do |rel, condition|
          if condition.is_a?(Array) && !condition.first.is_a?(String) # multiple conditions
            apply_conditions(rel, *condition)
          else
            rel.where(condition)
          end
        end
      end

      def sort_collection_by_column(collection, column, order)
        sorter = column.sort[:method]
        collection = collection.sort_by do |record|
          value = sorter.is_a?(Proc) ? record.instance_exec(record, &sorter) : record.send(sorter)
          value = '' if value.nil?
          value
        end
        collection.reverse! if order.casecmp('DESC').zero?
        collection
      end
    end
  end
end
