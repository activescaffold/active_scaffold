module ActiveScaffold
  module Finder
    def self.create_conditions_for_columns(tokens, columns)
      where_clauses = []
      columns.each do |column|
        where_clauses << "LOWER(#{column.search_sql}) LIKE ?"
      end
      phrase = "(#{where_clauses.join(' OR ')})"

      sql = ([phrase] * tokens.length).join(' AND ')
      tokens = tokens.collect{ |value| ["#{value.downcase}%"] * columns.length }.flatten

      [sql, *tokens]
    end

    attr_writer :active_scaffold_conditions
    def active_scaffold_conditions
      @active_scaffold_conditions ||= []
    end

    attr_writer :active_scaffold_includes
    def active_scaffold_includes
      @active_scaffold_includes ||= []
    end

    protected

    # returns a single record (the given id) but only if it's allowed for the specified action.
    # accomplishes this by checking model.#{action}_authorized?
    def find_if_allowed(id, mod)
      security_method = "#{mod}_authorized?"
      current_user = self.send(active_scaffold_config.current_user_method) rescue nil
      record = active_scaffold_config.model.find(id)
      raise ActiveScaffold::RecordNotAllowed if current_user and record.respond_to? security_method and !record.send(security_method, current_user)
      record
    end

    # returns a Paginator::Page (not from ActiveRecord::Paginator) for the given parameters
    # options may include:
    # * :sorting - a Sorting DataStructure (basically an array of hashes of field => direction, e.g. [{:field1 => 'asc'}, {:field2 => 'desc'}]). please note that multi-column sorting has some limitations: if any column in a multi-field sort uses method-based sorting, it will be ignored. method sorting only works for single-column sorting.
    # * :per_page
    # * :page
    def find_page(options = {})
      options.assert_valid_keys :sorting, :per_page, :page
      options[:per_page] ||= 999999999
      options[:page] ||= 1

      klass = active_scaffold_config.model

      # create a general-use options array that's compatible with Rails finders
      finder_options = { :order => build_order_clause(options[:sorting]),
                         :conditions => merge_conditions(active_scaffold_conditions, conditions_for_collection, conditions_from_params),
                         :include => active_scaffold_includes.empty? ? nil : active_scaffold_includes}

      count = klass.count(finder_options.reject{|k,v| k == :order})

      # we build the paginator differently for method- and sql-based sorting
      if options[:sorting] and options[:sorting].sorts_by_method?
        pager = ::Paginator.new(count, options[:per_page]) do |offset, per_page|
          sorted_collection = sort_collection_by_column(klass.find(:all, finder_options), *options[:sorting].first)
          sorted_collection.slice(offset, per_page)
        end
      else
        pager = ::Paginator.new(count, options[:per_page]) do |offset, per_page|
          klass.find(:all, finder_options.merge(:offset => offset, :limit => per_page))
        end
      end

      pager.page(options[:page])
    end

    # accepts arguments like the :conditions clauses that can get passed to an ActiveRecord find, and merges them together into one :conditions-worthy clause.
    def merge_conditions(*conditions)
      sql, values = [], []
      conditions.compact.each do |condition|
        next if condition.empty? # .compact removes nils but it doesn't remove empty arrays.
        condition = condition.clone
        # "name = 'Joe'" gets parsed to sql => "name = 'Joe'", values => []
        # ["name = '?'", 'Joe'] gets parsed to sql => "name = '?'", values => ['Joe']
        sql << ((condition.is_a? String) ? condition : condition.shift)
        values += (condition.is_a? String) ? [] : condition
      end
      # if there are no values, then simply return the joined sql. otherwise, stick the joined sql onto the beginning of the values array and return that.
      conditions = values.empty? ? sql.join(" AND ") : values.unshift(sql.join(" AND "))
      conditions = nil if conditions.empty?
      conditions
    end

    # accepts a DataStructure::Sorting object and builds an order-by clause
    def build_order_clause(sorting)
      return nil if sorting.nil? or sorting.sorts_by_method?

      # unless the sorting is by method, create the sql string
      order = []
      sorting.each do |clause|
        sort_column, sort_direction = clause
        sql = sort_column.sort[:sql]
        next if sql.nil? or sql.empty?

        order << "#{sql} #{sort_direction}"
      end

      order = order.join(', ')
      order = nil if order.empty?

      order
    end

    def sort_collection_by_column(collection, column, order)
      sorter = column.sort[:method]
      collection = collection.sort_by { |record|
        value = (sorter.is_a? Proc) ? record.instance_eval(&sorter) : record.instance_eval(sorter)
        value = column.column.type_cast('') if value.nil? and column.column
        value
      }
      collection.reverse! if order.downcase == 'desc'
      collection
    end
  end
end