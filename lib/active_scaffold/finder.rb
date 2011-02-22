module ActiveScaffold
  module Finder
    def self.like_operator
      @@like_operator ||= ::ActiveRecord::Base.connection.adapter_name == "PostgreSQL" ? "ILIKE" : "LIKE"
    end

    module ClassMethods
      # Takes a collection of search terms (the tokens) and creates SQL that
      # searches all specified ActiveScaffold columns. A row will match if each
      # token is found in at least one of the columns.
      def create_conditions_for_columns(tokens, columns, text_search = :full)
        # if there aren't any columns, then just return a nil condition
        return unless columns.length > 0
        like_pattern = like_pattern(text_search)

        tokens = [tokens] if tokens.is_a? String

        where_clauses = []
        columns.each do |column|
          where_clauses << ((column.column.nil? || column.column.text?) ? "#{column.search_sql} #{ActiveScaffold::Finder.like_operator} ?" : "#{column.search_sql} = ?")
        end
        phrase = "(#{where_clauses.join(' OR ')})"

        sql = ([phrase] * tokens.length).join(' AND ')
        tokens = tokens.collect do |value|
          columns.collect {|column| (column.column.nil? || column.column.text?) ? like_pattern.sub('?', value) : column.column.type_cast(value)}
        end.flatten

        [sql, *tokens]
      end

      # Generates an SQL condition for the given ActiveScaffold column based on
      # that column's database type (or form_ui ... for virtual columns?).
      # TODO: this should reside on the column, not the controller
      def condition_for_column(column, value, text_search = :full)
        like_pattern = like_pattern(text_search)
        return unless column and column.search_sql and not value.blank?
        search_ui = column.search_ui || column.column.type
        begin
          if self.respond_to?("condition_for_#{column.name}_column")
            self.send("condition_for_#{column.name}_column", column, value, like_pattern)
          elsif self.respond_to?("condition_for_#{search_ui}_type")
            self.send("condition_for_#{search_ui}_type", column, value, like_pattern)
          else
            unless column.search_sql.instance_of? Proc
              case search_ui
                when :boolean, :checkbox
                  ["#{column.search_sql} = ?", column.column.type_cast(value)]
                when :integer, :decimal, :float
                  condition_for_numeric(column, value)
                when :string, :range
                  condition_for_range(column, value, like_pattern)
                when :date, :time, :datetime, :timestamp
                  condition_for_datetime(column, value)
                when :select, :multi_select, :country, :usa_state
                ["#{column.search_sql} in (?)", Array(value)]
                else
                  if column.column.nil? || column.column.text?
                    ["#{column.search_sql} #{ActiveScaffold::Finder.like_operator} ?", like_pattern.sub('?', value)]
                  else
                    ["#{column.search_sql} = ?", column.column.type_cast(value)]
                  end
              end
            else
              column.search_sql.call(value)
            end
          end
        rescue Exception => e
          logger.error Time.now.to_s + "#{e.inspect} -- on the ActiveScaffold column :#{column.name}, search_ui = #{search_ui} in #{@controller.class}"
          raise e
        end
      end

      def condition_for_numeric(column, value)
        if !value.is_a?(Hash)
          ["#{column.search_sql} = ?", condition_value_for_numeric(column, value)]
        elsif value[:from].blank? or not ActiveScaffold::Finder::NumericComparators.include?(value[:opt])
          nil
        elsif value[:opt] == 'BETWEEN'
          ["#{column.search_sql} BETWEEN ? AND ?", condition_value_for_numeric(column, value[:from]), condition_value_for_numeric(column, value[:to])]
         else
          ["#{column.search_sql} #{value[:opt]} ?", condition_value_for_numeric(column, value[:from])]
        end
      end

      def condition_for_range(column, value, like_pattern = nil)
        if !value.is_a?(Hash)
          if column.column.nil? || column.column.text?
            ["#{column.search_sql} #{ActiveScaffold::Finder.like_operator} ?", like_pattern.sub('?', value)]
          else
            ["#{column.search_sql} = ?", column.column.type_cast(value)]
          end
        elsif value[:from].blank?
          nil
        elsif ActiveScaffold::Finder::StringComparators.values.include?(value[:opt])
          ["#{column.search_sql} LIKE ?", value[:opt].sub('?', value[:from])]
        elsif value[:opt] == 'BETWEEN'
          ["#{column.search_sql} BETWEEN ? AND ?", value[:from], value[:to]]
        elsif ActiveScaffold::Finder::NumericComparators.include?(value[:opt])
          ["#{column.search_sql} #{value[:opt]} ?", value[:from]]
        else
          nil
        end
      end
      
      def condition_value_for_datetime(value, conversion = :to_time)
        if value.is_a? Hash
          Time.zone.local(*[:year, :month, :day, :hour, :minute, :second].collect {|part| value[field][part].to_i}) rescue nil
        elsif value.respond_to?(:strftime)
          value.send(conversion)
        else
          Time.zone.parse(value).in_time_zone.send(conversion) rescue nil
        end unless value.nil? || value.blank?
      end

      def condition_value_for_numeric(column, value)
        return value if value.nil?
        value = i18n_number_to_native_format(value) if [:i18n_number, :currency].include?(column.options[:format])
        case (column.search_ui || column.column.type)
        when :integer   then value.to_i rescue value ? 1 : 0
        when :float     then value.to_f
        when :decimal   then ActiveRecord::ConnectionAdapters::Column.value_to_decimal(value)
        else
          value
        end
      end

      def i18n_number_to_native_format(value)
        native = '.'
        delimiter = I18n.t('number.format.delimiter')
        separator = I18n.t('number.format.separator')
        return value if value.blank? || !value.is_a?(String)
        unless delimiter == native && !value.include?(separator) && value !~ /\.\d{3}$/
          value.gsub(/[^0-9\-#{I18n.t('number.format.separator')}]/, '').gsub(I18n.t('number.format.separator'), native)
        else
          value
        end
      end
            
      def condition_for_datetime(column, value, like_pattern = nil)
        conversion = column.column.type == :date ? :to_date : :to_time
        from_value = condition_value_for_datetime(value[:from], conversion)
        to_value = condition_value_for_datetime(value[:to], conversion)

        if from_value.nil? and to_value.nil?
          nil
        elsif !from_value
          ["#{column.search_sql} <= ?", to_value.to_s(:db)]
        elsif !to_value
          ["#{column.search_sql} >= ?", from_value.to_s(:db)]
        else
          ["#{column.search_sql} BETWEEN ? AND ?", from_value.to_s(:db), to_value.to_s(:db)]
        end
      end

      def condition_for_record_select_type(column, value, like_pattern = nil)
        if value.is_a?(Array)
          ["#{column.search_sql} IN (?)", value]
        else
          ["#{column.search_sql} = ?", value]
        end
      end
      
      def condition_for_null_type(column, value, like_pattern = nil)
        case value.to_sym
        when :null
          ["#{column.search_sql} is null"]
        when :not_null
          ["#{column.search_sql} is not null"]
        else
          nil
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

    NumericComparators = [
      '=',
      '>=',
      '<=',
      '>',
      '<',
      '!=',
      'BETWEEN'
    ]
    StringComparators = {
      :contains    => '%?%',
      :begins_with => '?%',
      :ends_with   => '%?'
    }
    NullComparators = [
      :null,
      :not_null
    ]
    
    

    def self.included(klass)
      klass.extend ClassMethods
    end

    protected

    attr_writer :active_scaffold_conditions
    def active_scaffold_conditions
      @active_scaffold_conditions ||= []
    end

    attr_writer :active_scaffold_includes
    def active_scaffold_includes
      @active_scaffold_includes ||= []
    end

    attr_writer :active_scaffold_habtm_joins
    def active_scaffold_habtm_joins
      @active_scaffold_habtm_joins ||= []
    end
    
    def all_conditions
      merge_conditions(
        active_scaffold_conditions,                   # from the search modules
        conditions_for_collection,                    # from the dev
        conditions_from_params,                       # from the parameters (e.g. /users/list?first_name=Fred)
        conditions_from_constraints,                  # from any constraints (embedded scaffolds)
        active_scaffold_session_storage[:conditions] # embedding conditions (weaker constraints)
      )
    end
    
    # returns a single record (the given id) but only if it's allowed for the specified action.
    # accomplishes this by checking model.#{action}_authorized?
    # TODO: this should reside on the model, not the controller
    def find_if_allowed(id, crud_type, klass = beginning_of_chain)
      record = klass.find(id)
      raise ActiveScaffold::RecordNotAllowed, "#{klass} with id = #{id}" unless record.authorized_for?(:crud_type => crud_type.to_sym)
      return record
    end

    # returns a Paginator::Page (not from ActiveRecord::Paginator) for the given parameters
    # options may include:
    # * :sorting - a Sorting DataStructure (basically an array of hashes of field => direction, e.g. [{:field1 => 'asc'}, {:field2 => 'desc'}]). please note that multi-column sorting has some limitations: if any column in a multi-field sort uses method-based sorting, it will be ignored. method sorting only works for single-column sorting.
    # * :per_page
    # * :page
    # TODO: this should reside on the model, not the controller
    def find_page(options = {})
      options.assert_valid_keys :sorting, :per_page, :page, :count_includes, :pagination

      search_conditions = all_conditions
      full_includes = (active_scaffold_includes.blank? ? nil : active_scaffold_includes)
      options[:per_page] ||= 999999999
      options[:page] ||= 1
      options[:count_includes] ||= full_includes unless search_conditions.nil?

      klass = beginning_of_chain
      
      # create a general-use options array that's compatible with Rails finders
      finder_options = { :order => options[:sorting].try(:clause),
                         :where => search_conditions,
                         :joins => joins_for_finder,
                         :includes => options[:count_includes]}
                         
      finder_options.merge! custom_finder_options

      # NOTE: we must use :include in the count query, because some conditions may reference other tables
      count_query = append_to_query(klass, finder_options.reject{|k, v| [:select, :order].include?(k)})
      count = count_query.count unless options[:pagination] == :infinite
  
      # Converts count to an integer if ActiveRecord returned an OrderedHash
      # that happens when finder_options contains a :group key
      count = count.length if count.is_a? ActiveSupport::OrderedHash
      finder_options.merge! :includes => full_includes

      # we build the paginator differently for method- and sql-based sorting
      if options[:sorting] and options[:sorting].sorts_by_method?
        pager = ::Paginator.new(count, options[:per_page]) do |offset, per_page|
          sorted_collection = sort_collection_by_column(append_to_query(klass, finder_options).all, *options[:sorting].first)
          sorted_collection = sorted_collection.slice(offset, per_page) if options[:pagination]
          sorted_collection
        end
      else
        pager = ::Paginator.new(count, options[:per_page]) do |offset, per_page|
          finder_options.merge!(:offset => offset, :limit => per_page) if options[:pagination]
          append_to_query(klass, finder_options).all
        end
      end
      pager.page(options[:page])
    end
    
    def append_to_query(query, options)
      options.assert_valid_keys :where, :select, :group, :order, :limit, :offset, :joins, :includes, :lock, :readonly, :from
      options.reject{|k, v| v.blank?}.inject(query) do |query, (k, v)|
        # default ordering of model has a higher priority than current queries ordering
        # fix this by removing existing ordering from arel
        # will not work if order part is first one which is iterated
        query = query.except(:order) if k.to_sym == :order && query.is_a?(ActiveRecord::Relation)
        query.send((k.to_sym), v) 
      end
    end

    def joins_for_finder
      case joins_for_collection
        when String
          [ joins_for_collection ]
        when Array
          joins_for_collection
        else
          []
      end + active_scaffold_habtm_joins
    end
    
    def merge_conditions(*conditions)
      segments = []
      conditions.each do |condition|
        unless condition.blank?
          sql = active_scaffold_config.model.send(:sanitize_sql, condition)
          segments << sql unless sql.blank?
        end
      end
      "(#{segments.join(') AND (')})" unless segments.empty?
    end

    # TODO: this should reside on the column, not the controller
    def sort_collection_by_column(collection, column, order)
      sorter = column.sort[:method]
      collection = collection.sort_by { |record|
        value = (sorter.is_a? Proc) ? record.instance_eval(&sorter) : record.instance_eval(sorter)
        value = '' if value.nil?
        value
      }
      collection.reverse! if order.downcase == 'desc'
      collection
    end
  end
end
