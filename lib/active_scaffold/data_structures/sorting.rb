module ActiveScaffold::DataStructures
  # encapsulates the column sorting configuration for the List view
  class Sorting
    include Enumerable

    attr_accessor :constraint_columns
    attr_accessor :sorting_by_primary_key # enabled by default for postgres

    def initialize(columns)
      @columns = columns
      @clauses = []
      @constraint_columns = []
    end

    def set_default_sorting(model)
      # fallback to setting primary key ordering
      setup_primary_key_order_clause(model)
      model_scope = model.send(:build_default_scope)
      order_clause = model_scope.order_values.join(',') if model_scope
      return unless order_clause
      # If an ORDER BY clause is found set default sorting according to it
      set_sorting_from_order_clause(order_clause, model.table_name)
      @default_sorting = true
    end

    def set_nested_sorting(table_name, order_clause)
      clear
      set_sorting_from_order_clause(order_clause, table_name)
    end

    # add a clause to the sorting, assuming the column is sortable
    def add(column_name, direction = nil)
      direction ||= 'ASC'
      direction = direction.to_s.upcase
      column = get_column(column_name)
      raise ArgumentError, "Could not find column #{column_name}" if column.nil?
      raise ArgumentError, 'Sorting direction unknown' unless [:ASC, :DESC].include? direction.to_sym
      @clauses << [column, direction.untaint] if column.sortable?
      raise ArgumentError, "Can't mix :method- and :sql-based sorting" if mixed_sorting?
    end

    # an alias for +add+. must accept its arguments in a slightly different form, though.
    def <<(arg)
      add(*arg)
    end

    # clears the sorting before setting to the given column/direction
    # set(column, direction)
    # set({column => direction, column => direction})
    # set({column => direction}, {column => direction})
    # set([column, direction], [column, direction])
    def set(*args)
      clear
      if args.first.is_a?(Enumerable)
        args.each do |h|
          h.is_a?(Hash) ? h.each { |c, d| add(c, d) } : add(*h)
        end
      else
        add(*args)
      end
    end

    # clears the sorting
    def clear
      @default_sorting = false
      @clauses = []
    end

    # checks whether the given column (a Column object or a column name) is in the sorting
    def sorts_on?(column)
      !get_clause(column).nil?
    end

    def direction_of(column)
      clause = get_clause(column)
      return if clause.nil?
      clause[1]
    end

    SORTING_STAGES = Hash[%w(reset ASC DESC reset).each_cons(2).to_a].freeze
    DEFAULT_SORTING_STAGES = Hash[%w(ASC DESC ASC).each_cons(2).to_a].freeze
    def next_sorting_of(column, sorted_by_default)
      stages = sorted_by_default ? DEFAULT_SORTING_STAGES : SORTING_STAGES
      stages[direction_of(column)] || 'ASC'
    end

    # checks whether any column is configured to sort by method (using a proc)
    def sorts_by_method?
      @clauses.any? { |sorting| sorting[0].sort.is_a?(Hash) && sorting[0].sort.key?(:method) }
    end

    def sorts_by_sql?
      @clauses.any? { |sorting| sorting[0].sort.is_a?(Hash) && sorting[0].sort.key?(:sql) }
    end

    # iterate over the clauses
    def each
      @clauses.each { |clause| yield clause }
    end

    # provides quick access to the first (and sometimes only) clause
    def first
      @clauses.first
    end

    # builds an order-by clause
    def clause
      return nil if sorts_by_method? || default_sorting?

      # unless the sorting is by method, create the sql string
      order = []
      each do |sort_column, sort_direction|
        next if constraint_columns.include? sort_column.name
        sql = sort_column.sort[:sql]
        next if sql.nil? || sql.empty?

        order << Array(sql).map { |column| "#{column} #{sort_direction}" }.join(', ')
      end

      order << @primary_key_order_clause if @sorting_by_primary_key
      order unless order.empty?
    end

    protected

    # retrieves the sorting clause for the given column
    def get_clause(column)
      column = get_column(column)
      @clauses.find { |clause| clause[0] == column }
    end

    # possibly converts the given argument into a column object from @columns (if it's not already)
    def get_column(name_or_column)
      # it's a column
      return name_or_column if name_or_column.is_a? ActiveScaffold::DataStructures::Column
      # it's a name
      name_or_column = name_or_column.to_s.split('.').last if name_or_column.to_s.include? '.'
      @columns[name_or_column]
    end

    def mixed_sorting?
      sorts_by_method? && sorts_by_sql?
    end

    def default_sorting?
      @default_sorting
    end

    def set_sorting_from_order_clause(order_clause, model_table_name = nil)
      clear
      order_clause.to_s.split(',').each do |criterion|
        unless criterion.blank?
          order_parts = extract_order_parts(criterion)
          add(order_parts[:column_name], order_parts[:direction]) unless different_table?(model_table_name, order_parts[:table_name]) || get_column(order_parts[:column_name]).nil?
        end
      end
    end

    def extract_order_parts(criterion_parts)
      column_name_part, direction_part = criterion_parts.strip.split(' ')
      column_name_parts = column_name_part.split('.')
      order = {:direction => extract_direction(direction_part),
               :column_name => remove_quotes(column_name_parts.last)}
      order[:table_name] = remove_quotes(column_name_parts[-2]) if column_name_parts.length >= 2
      order
    end

    def different_table?(model_table_name, order_table_name)
      !order_table_name.nil? && model_table_name != order_table_name
    end

    def remove_quotes(sql_name)
      if sql_name.starts_with?('"') || sql_name.starts_with?('`')
        sql_name[1, (sql_name.length - 2)]
      else
        sql_name
      end
    end

    def extract_direction(direction_part)
      if direction_part.to_s.upcase == 'DESC'
        'DESC'
      else
        'ASC'
      end
    end

    def postgres?(model)
      model.connection.try(:adapter_name) == 'PostgreSQL'
    end

    def setup_primary_key_order_clause(model)
      return unless model.column_names.include?(model.primary_key)
      set([model.primary_key, 'ASC'])
      @primary_key_order_clause = clause
      @sorting_by_primary_key = postgres?(model) # mandatory for postgres, so enabled by default
    end
  end
end
