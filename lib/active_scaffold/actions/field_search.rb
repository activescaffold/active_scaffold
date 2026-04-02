# frozen_string_literal: true

module ActiveScaffold::Actions
  module FieldSearch
    def self.included(base)
      conf = base.active_scaffold_config
      if conf.model.primary_key.nil? && conf.field_search.columns.any? { |col| conf.columns[col]&.association }
        raise "#{base.active_scaffold_config.model.name} has no primary key, field_search with association columns won't work"
      end

      base.class_eval do
        helper_method :field_search_params, :grouped_search?, :search_group_column, :search_group_function
        include ActiveScaffold::Actions::CommonSearch
        include InstanceMethods
      end
    end

    module InstanceMethods
      # FieldSearch uses params[:search] and not @record because search conditions do not always pass the Model's validations.
      # This facilitates for example, textual searches against associations via .search_sql
      def show_search
        @record = empty_model
        super
      end

      protected

      def search_partial
        super || :field_search
      end

      def store_search_params_into_session
        init_field_search_params(active_scaffold_config.field_search.default_params) unless active_scaffold_config.field_search.default_params.nil?
        super
      end

      def init_field_search_params(default_params)
        return unless (params[:search].is_a?(String) || search_params.nil?) && params[:search].blank?

        params[:search] = default_params.is_a?(Proc) ? instance_eval(&default_params) : default_params
      end

      def grouped_search?
        field_search_params.present? && field_search_params['active_scaffold_group'].present?
      end

      def setup_search_group
        @_search_group_name, @_search_group_function = field_search_params['active_scaffold_group'].to_s.split('#')
      end

      def search_group_function
        setup_search_group unless defined? @_search_group_function
        @_search_group_function
      end

      def search_group_name
        setup_search_group unless defined? @_search_group_name
        @_search_group_name
      end

      def search_group_column
        active_scaffold_config.columns[search_group_name] if search_group_name
      end

      def custom_finder_options
        if grouped_search?
          grouped_search_finder_options
        else
          super
        end
      end

      def grouped_search_finder_options
        select_query = grouped_search_select
        group_by = calculation_for_group_by(search_group_column&.group_by || [search_group_name], search_group_function)

        if search_group_function
          select_query += [group_by.as(search_group_name)]
          group_by = group_by.to_sql
          order = grouped_sorting(group_by)
        else
          if search_group_column&.group_by
            sql_with_names = search_group_column.group_by.map.with_index { |part, i| [part, "#{search_group_name}_#{i}"] }
            select_query += quoted_select_columns(sql_with_names)
          else
            select_query += group_by
          end
          order = grouped_sorting
        end

        {group: group_by, select: select_query, reorder: order}
      end

      def grouped_search_select
        grouped_columns_calculations.map do |name, part|
          (part.respond_to?(:as) ? part : Arel::Nodes::SqlLiteral.new(part)).as(name.to_s)
        end
      end

      def grouped_sorting(group_sql = nil)
        return unless search_group_column && active_scaffold_config.list.user.sorting

        sorting = active_scaffold_config.list.user.sorting.clause(grouped_columns_sorting(group_sql))
        active_scaffold_config.active_record? ? sorting&.map(&Arel.method(:sql)) : sorting
      end

      def grouped_columns_sorting(group_sql)
        group_sql ||= search_group_column.sort[:sql] if search_group_column.sortable?
        grouped_columns_calculations.merge(search_group_column.name => group_sql)
      end

      def grouped_columns_calculations
        @grouped_columns_calculations ||= list_columns[1..].each_with_object({}) do |c, h|
          h[c.name] = calculation_for_group_search(c)
        end
      end

      def calculation_for_group_search(column)
        sql_function column.calculate.to_s, column.grouped_select
      end

      def calculation_for_group_by(group_sql, group_function)
        return quoted_select_columns(group_sql) unless group_function

        group_sql = Arel.sql(group_sql.join(', '))
        case group_function
        when 'year', 'month', 'quarter'
          extract_sql_fn(group_function, group_sql)
        when 'year_month'
          sql_operator(sql_operator(extract_sql_fn('year', group_sql), '*', 100), '+', extract_sql_fn('month', group_sql))
        when 'year_quarter'
          sql_operator(sql_operator(extract_sql_fn('year', group_sql), '*', 10), '+', extract_sql_fn('quarter', group_sql))
        else
          raise ArgumentError, "#{group_function} unsupported, override calculation_for_group_by in #{self.class.name}"
        end
      end

      def extract_sql_fn(part, column)
        sql_function('extract', sql_operator(Arel.sql(part), 'FROM', column))
      end

      def sql_function(function, *args)
        args.map! { |arg| quoted_arel_value(arg) }
        Arel::Nodes::NamedFunction.new(function, args)
      end

      def sql_operator(arg1, operator, arg2)
        Arel::Nodes::InfixOperation.new(operator, quoted_arel_value(arg1), quoted_arel_value(arg2))
      end

      def quoted_arel_value(value)
        value.is_a?(Arel::Predications) ? value : Arel::Nodes::Quoted.new(value)
      end

      def list_columns
        @list_columns ||=
          if grouped_search?
            columns = grouped_columns || super.select(&:calculation?)
            columns.unshift(search_group_column || search_group_name)
          else
            super
          end
      end

      def grouped_columns
        return if active_scaffold_config.field_search.grouped_columns.blank?

        active_scaffold_config.field_search.grouped_columns.filter_map do |col|
          active_scaffold_config.columns[col]
        end
      end

      def field_search_params
        search_params.is_a?(Hash) ? search_params : {}
      end

      def field_search_respond_to_html
        render(action: 'field_search')
      end

      def field_search_respond_to_js
        render(partial: 'field_search')
      end

      def do_search
        if field_search_params.present?
          do_field_search
        else
          super
        end
      end

      def do_field_search
        text_search = active_scaffold_config.field_search.text_search
        columns = active_scaffold_config.field_search.columns

        search_conditions = search_params.filter_map do |key, value|
          next unless columns.include? key

          column = active_scaffold_config.columns[key]
          search_condition = self.class.condition_for_column(column, value, text_search, session)
          [column, search_condition] unless search_condition.nil?
        end

        process_search_conditions(search_conditions)
        active_scaffold_config.list.user.page = nil
      end

      def process_search_conditions(search_conditions)
        filtered_columns = []
        filtered_columns_for_joins = []
        search_conditions.each do |column, search_condition|
          if search_condition.is_a? ActiveRecord::Relation
            active_scaffold_relations << search_condition
            filtered_columns << column
          else
            active_scaffold_conditions << search_condition
            filtered_columns << column
            filtered_columns_for_joins << column
          end
        end

        setup_joins_for_filtered_columns(filtered_columns_for_joins)
        setup_human_conditions(filtered_columns)
      end

      def setup_human_conditions(filtered_columns)
        return unless filtered_columns.present? || grouped_search?

        @filtered = active_scaffold_config.field_search.human_conditions ? filtered_columns : true
      end

      def field_search_ignore?
        active_scaffold_config.list.always_show_search && active_scaffold_config.list.search_partial == 'field_search'
      end

      private

      def setup_joins_for_filtered_columns(filtered_columns)
        if grouped_search? || active_scaffold_config.list.user.count_includes.present?
          active_scaffold_outer_joins.concat filtered_columns.map(&:search_joins).flatten.uniq.compact
          active_scaffold_joins << search_group_column.search_joins if grouped_column_needs_joins?(filtered_columns)
        else
          set_outer_joins_for_search filtered_columns
        end
      end

      def grouped_column_needs_joins?(filtered_columns)
        grouped_search? && search_group_column&.search_joins.present? && filtered_columns.exclude?(search_group_column)
      end

      def field_search_formats
        (default_formats + active_scaffold_config.formats + active_scaffold_config.field_search.formats).uniq
      end
    end
  end
end
