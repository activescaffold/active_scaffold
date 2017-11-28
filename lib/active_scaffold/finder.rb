module ActiveScaffold
  module Finder
    def self.like_operator
      @@like_operator ||= ::ActiveRecord::Base.connection.adapter_name == 'PostgreSQL' ? 'ILIKE' : 'LIKE'
    end

    module ClassMethods
      # Takes a collection of search terms (the tokens) and creates SQL that
      # searches all specified ActiveScaffold columns. A row will match if each
      # token is found in at least one of the columns.
      def create_conditions_for_columns(tokens, columns, text_search = :full)
        # if there aren't any columns, then just return a nil condition
        return unless columns.any?
        like_pattern = like_pattern(text_search)

        tokens = [tokens] if tokens.is_a? String

        where_clauses = []
        columns.each do |column|
          Array(column.search_sql).each do |search_sql|
            where_clauses << "#{search_sql} #{column.text? ? ActiveScaffold::Finder.like_operator : '='} ?"
          end
        end
        phrase = where_clauses.join(' OR ')

        tokens.collect do |value|
          columns.each_with_object([phrase]) do |column, condition|
            Array(column.search_sql).size.times do
              condition.push(column.text? ? like_pattern.sub('?', value) : ActiveScaffold::Core.column_type_cast(value, column.column))
            end
          end
        end
      end

      # Generates an SQL condition for the given ActiveScaffold column based on
      # that column's database type (or form_ui ... for virtual columns?).
      # TODO: this should reside on the column, not the controller
      def condition_for_column(column, value, text_search = :full)
        like_pattern = like_pattern(text_search)
        value = value.with_indifferent_access if value.is_a? Hash
        if self.respond_to?("condition_for_#{column.name}_column")
          return send("condition_for_#{column.name}_column", column, value, like_pattern)
        end
        return unless column && column.search_sql && !value.blank?
        search_ui = column.search_ui || column.column.try(:type)
        begin
          sql, *values =
            if search_ui && self.respond_to?("condition_for_#{search_ui}_type")
              send("condition_for_#{search_ui}_type", column, value, like_pattern)
            else
              if column.search_sql.instance_of? Proc
                column.search_sql.call(value)
              else
                condition_for_search_ui(column, value, like_pattern, search_ui)
              end
            end
          return nil unless sql

          conditions = [column.search_sql.collect { |search_sql| sql % {:search_sql => search_sql} }.join(' OR ')]
          conditions += values * column.search_sql.size if values.present?
          conditions
        rescue StandardError => e
          logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column :#{column.name}, search_ui = #{search_ui} in #{name}"
          raise e
        end
      end

      def condition_for_search_ui(column, value, like_pattern, search_ui)
        case search_ui
        when :boolean, :checkbox
          ['%{search_sql} = ?', column.column ? ActiveScaffold::Core.column_type_cast(value, column.column) : value]
        when :integer, :decimal, :float
          condition_for_numeric(column, value)
        when :string, :range
          condition_for_range(column, value, like_pattern)
        when :date, :time, :datetime, :timestamp
          condition_for_datetime(column, value)
        when :select, :multi_select, :country, :usa_state, :chosen, :multi_chosen
          ['%{search_sql} in (?)', Array(value)]
        else
          if column.text?
            ["%{search_sql} #{ActiveScaffold::Finder.like_operator} ?", like_pattern.sub('?', value)]
          else
            ['%{search_sql} = ?', ActiveScaffold::Core.column_type_cast(value, column.column)]
          end
        end
      end

      def condition_for_numeric(column, value)
        if !value.is_a?(Hash)
          ['%{search_sql} = ?', condition_value_for_numeric(column, value)]
        elsif ActiveScaffold::Finder::NULL_COMPARATORS.include?(value[:opt])
          condition_for_null_type(column, value[:opt])
        elsif value[:from].blank? || !ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(value[:opt])
          nil
        elsif value[:opt] == 'BETWEEN'
          ['(%{search_sql} BETWEEN ? AND ?)', condition_value_for_numeric(column, value[:from]), condition_value_for_numeric(column, value[:to])]
        else
          ["%{search_sql} #{value[:opt]} ?", condition_value_for_numeric(column, value[:from])]
        end
      end

      def condition_for_range(column, value, like_pattern = nil)
        if !value.is_a?(Hash)
          if column.text?
            ["%{search_sql} #{ActiveScaffold::Finder.like_operator} ?", like_pattern.sub('?', value)]
          else
            ['%{search_sql} = ?', ActiveScaffold::Core.column_type_cast(value, column.column)]
          end
        elsif ActiveScaffold::Finder::NULL_COMPARATORS.include?(value[:opt])
          condition_for_null_type(column, value[:opt], like_pattern)
        elsif value[:from].blank?
          nil
        elsif ActiveScaffold::Finder::STRING_COMPARATORS.values.include?(value[:opt])
          ["%{search_sql} #{ActiveScaffold::Finder.like_operator} ?", value[:opt].sub('?', value[:from])]
        elsif value[:opt] == 'BETWEEN'
          ['(%{search_sql} BETWEEN ? AND ?)', value[:from], value[:to]]
        elsif ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(value[:opt])
          ["%{search_sql} #{value[:opt]} ?", value[:from]]
        end
      end

      def translate_days_and_months(value, format)
        keys = {
          '%A' => 'date.day_names',
          '%a' => 'date.abbr_day_names',
          '%B' => 'date.month_names',
          '%b' => 'date.abbr_month_names'
        }
        keys.each do |f, k|
          if format.include? f
            table = Hash[I18n.t(k).compact.zip(I18n.t(k, :locale => :en).compact)]
            value.gsub!(Regexp.union(table.keys)) { |s| table[s] }
          end
        end
        value
      end

      def condition_value_for_datetime(column, value, conversion = :to_time)
        if value.is_a? Hash
          time = Time.zone.local(*[:year, :month, :day, :hour, :minute, :second].collect { |part| value[part].to_i }) rescue nil
          time.send(conversion) if time
        elsif value.respond_to?(:strftime)
          if conversion == :to_time
            # Explicitly get the current zone, because TimeWithZone#to_time in rails 3.2.3 returns UTC.
            # https://github.com/rails/rails/pull/2453
            value.to_time.in_time_zone
          else
            value.send(conversion)
          end
        elsif conversion == :to_date
          Date.strptime(value, I18n.t("date.formats.#{column.options[:format] || :default}")) rescue nil
        else
          parts = Date._parse(value)
          format = I18n.translate "time.formats.#{column.options[:format] || :picker}", :default => '' if ActiveScaffold.js_framework == :jquery
          if format.blank?
            time_parts = [[:hour, '%H'], [:min, '%M'], [:sec, '%S']].collect { |part, format_part| format_part if parts[part].present? }.compact
            format = "#{I18n.t('date.formats.default')} #{time_parts.join(':')} #{'%z' if parts[:offset].present?}"
          else
            if parts[:hour]
              [[:min, '%M'], [:sec, '%S']].each { |part, f| format.gsub!(":#{f}", '') unless parts[part].present? }
            else
              value += ' 00:00:00'
            end
            format += ' %z' if parts[:offset].present? && format !~ /%z/i
          end
          if !parts[:year] && !parts[:month] && !parts[:mday]
            value = "#{Date.today.strftime(format.gsub(/%[HI].*/, ''))} #{value}"
          end
          value = translate_days_and_months(value, format) if I18n.locale != :en
          time = DateTime.strptime(value, format) rescue nil
          if time
            time = Time.zone.local_to_utc(time).in_time_zone unless parts[:offset]
            time = time.send(conversion) unless conversion == :to_time
          end
          time
        end unless value.nil? || value.blank?
      end

      def condition_value_for_numeric(column, value)
        return value if value.nil?
        value = column.number_to_native(value) if column.options[:format] && column.search_ui != :number
        case (column.search_ui || column.column.type)
        when :integer   then value.to_i rescue value ? 1 : 0
        when :float     then value.to_f
        when :decimal
          if Rails.version >= '4.2.0'
            ActiveRecord::Type::Decimal.new.type_cast_from_user(value)
          else
            ActiveRecord::ConnectionAdapters::Column.value_to_decimal(value)
          end
        else
          value
        end
      end

      def datetime_conversion_for_condition(column)
        if column.column
          column.column.type == :date ? :to_date : :to_time
        else
          :to_time
        end
      end

      def condition_for_datetime(column, value, like_pattern = nil)
        conversion = datetime_conversion_for_condition(column)
        from_value = condition_value_for_datetime(column, value[:from], conversion)
        to_value = condition_value_for_datetime(column, value[:to], conversion)

        if from_value.nil? && to_value.nil?
          nil
        elsif !from_value
          ['%{search_sql} <= ?', to_value.to_s(:db)]
        elsif !to_value
          ['%{search_sql} >= ?', from_value.to_s(:db)]
        else
          ['%{search_sql} BETWEEN ? AND ?', from_value.to_s(:db), to_value.to_s(:db)]
        end
      end

      def condition_for_record_select_type(column, value, like_pattern = nil)
        if value.is_a?(Array)
          ['%{search_sql} IN (?)', value]
        else
          ['%{search_sql} = ?', value]
        end
      end

      def condition_for_null_type(column, value, like_pattern = nil)
        case value.to_s
        when 'null'
          ['%{search_sql} is null', []]
        when 'not_null'
          ['%{search_sql} is not null', []]
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

    NUMERIC_COMPARATORS = [
      '=',
      '>=',
      '<=',
      '>',
      '<',
      '!=',
      'BETWEEN'
    ]
    STRING_COMPARATORS = {
      :contains    => '%?%',
      :begins_with => '?%',
      :ends_with   => '%?'
    }
    NULL_COMPARATORS = %w(null not_null)

    def self.included(klass)
      klass.extend ClassMethods
    end

    protected

    attr_writer :active_scaffold_conditions
    def active_scaffold_conditions
      @active_scaffold_conditions ||= []
    end

    attr_writer :active_scaffold_preload
    def active_scaffold_preload
      @active_scaffold_preload ||= []
    end

    def active_scaffold_includes=(value)
      ActiveSupport::Deprecation.warn "active_scaffold_includes doesn't exist anymore, use active_scaffold_preload, active_scaffold_outer_joins or active_scaffold_references"
      self.active_scaffold_preload = value
    end

    def active_scaffold_includes
      ActiveSupport::Deprecation.warn "active_scaffold_includes doesn't exist anymore, use active_scaffold_preload, active_scaffold_outer_joins or active_scaffold_references"
      active_scaffold_preload
    end

    attr_writer :active_scaffold_habtm_joins
    def active_scaffold_habtm_joins
      @active_scaffold_habtm_joins ||= []
    end

    attr_writer :active_scaffold_outer_joins
    def active_scaffold_outer_joins
      @active_scaffold_outer_joins ||= []
    end

    attr_writer :active_scaffold_references
    def active_scaffold_references
      @active_scaffold_references ||= []
    end

    # Override this method on your controller to define conditions to be used when querying a recordset (e.g. for List). The return of this method should be any format compatible with the :conditions clause of ActiveRecord::Base's find.
    def conditions_for_collection
    end

    # Override this method on your controller to define joins to be used when querying a recordset (e.g. for List).  The return of this method should be any format compatible with the :joins clause of ActiveRecord::Base's find.
    def joins_for_collection
    end

    # Override this method on your controller to provide custom finder options to the find() call. The return of this method should be a hash.
    def custom_finder_options
      {}
    end

    def all_conditions
      [
        id_condition,                                 # for list with id (e.g. /users/:id/index)
        active_scaffold_conditions,                   # from the search modules
        conditions_for_collection,                    # from the dev
        conditions_from_params,                       # from the parameters (e.g. /users/list?first_name=Fred)
        conditions_from_constraints,                  # from any constraints (embedded scaffolds)
        active_scaffold_session_storage['conditions'] # embedding conditions (weaker constraints)
      ].reject(&:blank?)
    end

    def id_condition
      {active_scaffold_config.model.primary_key => params[:id]} if params[:id]
    end

    # returns a single record (the given id) but only if it's allowed for the specified security options.
    # security options can be a hash for authorized_for? method or a value to check as a :crud_type
    # accomplishes this by checking model.#{action}_authorized?
    def find_if_allowed(id, security_options, klass = beginning_of_chain)
      record = klass.find(id)
      security_options = {:crud_type => security_options.to_sym} unless security_options.is_a? Hash
      raise ActiveScaffold::RecordNotAllowed, "#{klass} with id = #{id}" unless record.authorized_for? security_options
      record
    end
    # valid options may include:
    # * :sorting - a Sorting DataStructure (basically an array of hashes of field => direction, e.g. [{:field1 => 'asc'}, {:field2 => 'desc'}]). please note that multi-column sorting has some limitations: if any column in a multi-field sort uses method-based sorting, it will be ignored. method sorting only works for single-column sorting.
    # * :per_page
    # * :page
    def finder_options(options = {})
      search_conditions = all_conditions
      full_includes = (active_scaffold_references.blank? ? nil : active_scaffold_references)

      # create a general-use options array that's compatible with Rails finders
      finder_options = {
        :reorder => options[:sorting].try(:clause),
        :conditions => search_conditions,
        :joins => joins_for_finder,
        :outer_joins => active_scaffold_outer_joins,
        :preload => active_scaffold_preload,
        :includes => full_includes,
        :select => options[:select]
      }
      if Rails::VERSION::MAJOR >= 4
        finder_options.merge!(:references => active_scaffold_references)
      end

      finder_options.merge! custom_finder_options
      finder_options
    end

    def count_items(query, find_options = {}, count_includes = nil)
      count_includes ||= find_options[:includes] unless find_options[:conditions].blank?
      options = find_options.reject { |k, _| [:select, :reorder].include? k }
      # NOTE: we must use includes in the count query, because some conditions may reference other tables
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

      find_options = finder_options(options)
      query = beginning_of_chain.where(nil) # where(nil) is needed because we need a relation

      # NOTE: we must use :include in the count query, because some conditions may reference other tables
      if options[:pagination] && options[:pagination] != :infinite
        count = count_items(query, find_options, options[:count_includes])
      end

      query = append_to_query(query, find_options)
      # we build the paginator differently for method- and sql-based sorting
      if options[:sorting] && options[:sorting].sorts_by_method?
        pager = ::Paginator.new(count, options[:per_page]) do |offset, per_page|
          calculate_last_modified(query)
          sorted_collection = sort_collection_by_column(query.to_a, *options[:sorting].first)
          sorted_collection = sorted_collection.slice(offset, per_page) if options[:pagination]
          sorted_collection
        end
      else
        pager = ::Paginator.new(count, options[:per_page]) do |offset, per_page|
          query = append_to_query(query, :offset => offset, :limit => per_page) if options[:pagination]
          calculate_last_modified(query)
          query
        end
      end
      pager.page(options[:page])
    end

    def calculate_last_modified(query)
      return unless conditional_get_support? && query.klass.columns_hash['updated_at']
      @last_modified = query.maximum(:updated_at)
    end

    def calculate_query
      conditions = all_conditions
      includes = active_scaffold_config.list.count_includes
      includes ||= active_scaffold_references unless conditions.blank?
      outer_joins = active_scaffold_outer_joins
      outer_joins += includes if includes
      primary_key = active_scaffold_config.model.primary_key
      subquery = append_to_query(beginning_of_chain, :conditions => conditions, :joins => joins_for_finder, :outer_joins => outer_joins, :select => active_scaffold_config.columns[primary_key].field)
      subquery = subquery.unscope(:order) if Rails::VERSION::MAJOR >= 4
      active_scaffold_config.model.where(primary_key => subquery)
    end

    def append_to_query(relation, options)
      options.assert_valid_keys :where, :select, :having, :group, :reorder, :limit, :offset, :joins, :outer_joins, :includes, :lock, :readonly, :from, :conditions, :preload, (:references if Rails::VERSION::MAJOR >= 4)
      relation = options.reject { |_, v| v.blank? }.inject(relation) do |rel, (k, v)|
        k == :conditions ? apply_conditions(rel, *v) : rel.send(k, v)
      end
      if options[:outer_joins].present?
        if Rails::VERSION::MAJOR >= 4
          relation.distinct_value = true
        else
          relation = relation.uniq
        end
      end
      relation
    end

    def joins_for_finder
      case joins_for_collection
        when String
          [joins_for_collection]
        when Array
          joins_for_collection
        else
          []
      end + active_scaffold_habtm_joins
    end

    def apply_conditions(relation, *conditions)
      conditions.reject(&:blank?).inject(relation) do |rel, condition|
        if condition.is_a?(Array) && !condition.first.is_a?(String) # multiple conditions
          apply_conditions(rel, *condition)
        else
          rel.where(condition)
        end
      end
    end

    # TODO: this should reside on the column, not the controller
    def sort_collection_by_column(collection, column, order)
      sorter = column.sort[:method]
      collection = collection.sort_by do |record|
        value = (sorter.is_a? Proc) ? record.instance_eval(&sorter) : record.instance_eval(sorter.to_s)
        value = '' if value.nil?
        value
      end
      collection.reverse! if order.downcase == 'desc'
      collection
    end
  end
end
