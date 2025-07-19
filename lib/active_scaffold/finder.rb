module ActiveScaffold
  module Finder
    def self.like_operator
      @@like_operator ||= ::ActiveRecord::Base.connection.adapter_name.in?(%w[PostgreSQL PostGIS]) ? 'ILIKE' : 'LIKE'
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
          columns.each_with_object({}) do |column, column_tokens|
            column_tokens[column.name] =
              if column.text?
                like_pattern.sub('?', column.active_record? ? column.active_record_class.sanitize_sql_like(value) : value)
              else
                ActiveScaffold::Core.column_type_cast(value, column.column)
              end
          end
        end
      end

      module ActiveRecord
        def create_conditions_for_columns(tokens, columns)
          where_clauses = []
          columns.each do |column|
            column.search_sql.each do |search_sql|
              where_clauses << "#{search_sql} #{column.text? ? ActiveScaffold::Finder.like_operator : '='} ?"
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
      # TODO: this should reside on the column, not the controller
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
          sql, *values =
            if search_ui && respond_to?(:"condition_for_#{search_ui}_type")
              send(:"condition_for_#{search_ui}_type", column, value, like_pattern)
            elsif column.search_sql.instance_of? Proc
              column.search_sql.call(value)
            else
              condition_for_search_ui(column, value, like_pattern, search_ui)
            end
          return nil unless sql
          return sql if sql.is_a? ::ActiveRecord::Relation

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
        rescue StandardError => e
          Rails.logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column :#{column.name}, search_ui = #{search_ui} in #{name}"
          raise e
        end
      end

      def subquery_condition(column, sql, options, values)
        relation, *columns = options[:subquery]
        conditions = [columns.map { |search_sql| sql % {search_sql: search_sql} }.join(' OR ')]
        conditions += values * columns.size if values.present?
        subquery = relation.where(conditions)
        subquery = subquery.select(relation.primary_key) if subquery.select_values.blank?

        conditions = [["#{options[:field] || column.field} IN (?)", options[:conditions]&.first].compact.join(' AND ')]
        conditions << subquery
        conditions.concat options[:conditions][1..] if options[:conditions]
        if column.association&.polymorphic?
          conditions[0] << " AND #{column.quoted_foreign_type} = ?"
          conditions << relation.base_class.sti_name
        end
        conditions
      end

      def condition_for_search_ui(column, value, like_pattern, search_ui)
        case search_ui
        when :boolean, :checkbox
          if value == 'null'
            condition_for_null_type(column, value)
          else
            ['%<search_sql>s = ?', column.column ? ActiveScaffold::Core.column_type_cast(value, column.column) : value]
          end
        when :integer, :decimal, :float
          condition_for_numeric(column, value)
        when :string, :range
          if value.is_a?(Hash)
            condition_for_range(column, value, like_pattern)
          else
            condition_for_single_value(column, value, like_pattern)
          end
        when :date, :time, :datetime, :timestamp
          condition_for_datetime(column, value)
        when :select, :select_multiple, :draggable, :multi_select, :country, :usa_state, :chosen, :multi_chosen
          if value.is_a?(Hash)
            condition_for_range(column, value, like_pattern)
          else
            values = Array(value).compact_blank
            ['%<search_sql>s in (?)', values] if values.present?
          end
        else
          condition_for_single_value(column, value, like_pattern)
        end
      end

      def condition_for_numeric(column, value)
        if !value.is_a?(Hash)
          ['%<search_sql>s = ?', condition_value_for_numeric(column, value)]
        elsif ActiveScaffold::Finder::NULL_COMPARATORS.include?(value[:opt])
          condition_for_null_type(column, value[:opt])
        elsif value[:from].blank? || ActiveScaffold::Finder::NUMERIC_COMPARATORS.exclude?(value[:opt])
          nil
        elsif value[:opt] == 'BETWEEN'
          ['(%<search_sql>s BETWEEN ? AND ?)', condition_value_for_numeric(column, value[:from]), condition_value_for_numeric(column, value[:to])]
        else
          ["%<search_sql>s #{value[:opt]} ?", condition_value_for_numeric(column, value[:from])]
        end
      end

      def condition_for_single_value(column, value, like_pattern = nil)
        if column.text?
          value = column.active_record_class.sanitize_sql_like(value) if column.active_record?
          ["%<search_sql>s #{ActiveScaffold::Finder.like_operator} ?", like_pattern.sub('?', value)]
        else
          ['%<search_sql>s = ?', ActiveScaffold::Core.column_type_cast(value, column.column)]
        end
      end

      def condition_for_range(column, value, like_pattern = nil)
        if ActiveScaffold::Finder::NULL_COMPARATORS.include?(value[:opt])
          condition_for_null_type(column, value[:opt], like_pattern)
        elsif value[:from].is_a?(Array) # opt can be only =
          from = Array(value[:from]).compact_blank
          ['%<search_sql>s in (?)', from] if from.present?
        elsif value[:from].blank?
          nil
        elsif ActiveScaffold::Finder::STRING_COMPARATORS.value?(value[:opt])
          text = column.active_record? ? column.active_record_class.sanitize_sql_like(value[:from]) : value[:from]
          [
            "%<search_sql>s #{'NOT ' if value[:opt].start_with?('not_')}#{ActiveScaffold::Finder.like_operator} ?",
            value[:opt].sub('not_', '').sub('?', text)
          ]
        elsif value[:opt] == 'BETWEEN'
          ['(%<search_sql>s BETWEEN ? AND ?)', value[:from], value[:to]]
        elsif ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(value[:opt])
          ["%<search_sql>s #{value[:opt]} ?", value[:from]]
        elsif ActiveScaffold::Finder::LOGICAL_COMPARATORS.include?(value[:opt])
          operator =
            case value[:opt]
            when 'all_tokens' then 'AND'
            when 'any_token'  then 'OR'
            end
          parser = ActiveScaffold::Bridges::LogicalQueryParser::TokensGrammar::Parser.new(operator)
          [logical_search_condition(column, value[:from], parser)]
        end
      end

      def logical_search_condition(column, search, parser = nil)
        model = column.active_record_class
        if column.logical_search.any? { |item| item.is_a?(Hash) }
          subquery_model = column.active_record_class.dup.tap { |m| m.table_name = "_#{m.table_name}_exists" }
        end
        query = ::LogicalQueryParser.search(search, subquery_model || model, columns: column.logical_search, parser: parser)
        if subquery_model
          subquery = query.from("#{model.table_name} #{subquery_model.table_name}").
            where(model.arel_table[model.primary_key].eq(subquery_model.arel_table[model.primary_key]))
          column.active_record_class.where(subquery.select(1).arel.exists)
        else
          query
        end
      end

      def tables_for_translating_days_and_months(format)
        keys = {
          '%A' => 'date.day_names',
          '%a' => 'date.abbr_day_names',
          '%B' => 'date.month_names',
          '%b' => 'date.abbr_month_names'
        }
        key_index = keys.keys.index_with { |key| format.index(key) }
        keys.select! { |k, _| key_index[k] }
        keys.sort_by { |k, _| key_index[k] }.map do |_, k|
          I18n.t(k).compact.zip(I18n.t(k, locale: :en).compact).to_h
        end
      end

      def translate_days_and_months(value, format)
        translated = ''
        tables_for_translating_days_and_months(format).each do |table|
          regexp = Regexp.union(table.keys)
          index = value.index(regexp)
          next unless index

          translated << value.slice!(0...index)
          value.sub!(regexp) do |str|
            translated << table[str]
            ''
          end
        end
        translated << value
      end

      def format_for_datetime(column, value, ui_name, ui_options)
        parts = Date._parse(value)
        time_parts = [[:hour, '%H'], [:min, '%M'], [:sec, '%S']].filter_map do |part, format_part|
          format_part if parts[part].present?
        end
        format = "%Y-%m-%d #{time_parts.join(':')} #{'%z' if parts[:offset].present?}"

        format.gsub!(/.*(?=%H)/, '') if !parts[:year] && !parts[:month] && !parts[:mday]
        [format, parts[:offset]]
      end

      def local_time_from_hash(value, conversion = :to_time)
        time = Time.zone.local(*%i[year month day hour minute second].collect { |part| value[part].to_i })
        time.send(conversion)
      rescue StandardError => e
        message = "Error creating time from #{value.inspect}:"
        Rails.logger.warn "#{message}\n#{e.message}\n#{e.backtrace.join("\n")}"
        nil
      end

      def format_for_date(column, value, ui_name, ui_options)
        if ui_options[:format]
          format = I18n.t("date.formats.#{ui_options[:format]}")
          format.gsub!(/%-d|%-m|%_m/) { |s| s.gsub(/[-_]/, '') } # strptime fails with %-d, %-m, %_m
          en_value = I18n.locale == :en ? value : translate_days_and_months(value, format)
        end
        [en_value || value, format]
      end

      def parse_date_with_format(value, format)
        Date.strptime(value, *format)
      rescue StandardError => e
        message = "Error parsing date from #{value}"
        message << ", with format #{format}" if format
        Rails.logger.warn "#{message}:\n#{e.message}\n#{e.backtrace.join("\n")}"
        nil
      end

      def parse_time_with_format(value, format, offset)
        format.gsub!(/%-d|%-m|%_m/) { |s| s.gsub(/[-_]/, '') } # strptime fails with %-d, %-m, %_m
        en_value = I18n.locale == :en ? value : translate_days_and_months(value, format)
        time = Time.strptime(en_value, format)
        offset ? time : Time.zone.local_to_utc(time).in_time_zone
      rescue StandardError => e
        message = "Error parsing time from #{en_value}"
        message << " (#{value})" if en_value != value
        message << ", with format #{format}" if format
        Rails.logger.warn "#{message}:\n#{e.message}\n#{e.backtrace.join("\n")}"
        nil
      end

      def condition_value_for_datetime(column, value, conversion = :to_time, ui_method: :search_ui, ui_options: nil)
        return if value.nil? || value.blank?

        ui_options ||= column.send(:"#{ui_method}_options") || column.options
        if value.is_a? Hash
          local_time_from_hash(value, conversion)
        elsif value.respond_to?(:strftime)
          if conversion == :to_time
            # Explicitly get the current zone, because TimeWithZone#to_time in rails 3.2.3 returns UTC.
            # https://github.com/rails/rails/pull/2453
            value.to_time.in_time_zone
          else
            value.send(conversion)
          end
        elsif conversion == :to_date
          parse_date_with_format(*format_for_date(column, value, column.send(ui_method), ui_options))
        elsif value.include?('T')
          Time.zone.parse(value)
        else # datetime
          time = parse_time_with_format(value, *format_for_datetime(column, value, column.send(ui_method), ui_options))
          conversion == :to_time ? time : time.send(conversion)
        end
      end

      def condition_value_for_numeric(column, value)
        return value if value.nil?

        value = column.number_to_native(value) if column.options[:format] && column.search_ui != :number
        case column.search_ui || column.column_type
        when :integer
          if value.is_a?(TrueClass) || value.is_a?(FalseClass)
            value ? 1 : 0
          else
            value.to_i
          end
        when :float     then value.to_f
        when :decimal   then ::ActiveRecord::Type::Decimal.new.cast(value)
        else
          value
        end
      end

      def datetime_conversion_for_condition(column)
        if column.column
          column.column_type == :date ? :to_date : :to_time
        else
          :to_time
        end
      end

      def condition_for_datetime(column, value, like_pattern = nil)
        operator = ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(value['opt']) && value['opt'] != 'BETWEEN' ? value['opt'] : nil
        from_value, to_value = datetime_from_to(column, value)

        if column.search_sql.is_a? Proc
          column.search_sql.call(from_value, to_value, operator)
        elsif ActiveScaffold::Finder::NULL_COMPARATORS.include?(value['opt'])
          condition_for_null_type(column, value['opt'], like_pattern)
        elsif operator.nil?
          ['%<search_sql>s BETWEEN ? AND ?', from_value, to_value] unless from_value.nil? || to_value.nil?
        else
          ["%<search_sql>s #{value['opt']} ?", from_value] unless from_value.nil?
        end
      end

      def datetime_from_to(column, value)
        conversion = datetime_conversion_for_condition(column)
        case value['opt']
        when 'RANGE'
          values = datetime_from_to_for_range(column, value)
          # Avoid calling to_time, not needed and broken on rails >= 4, because return local time instead of UTC
          values.collect!(&conversion) if conversion != :to_time
          values
        when 'PAST', 'FUTURE'
          values = datetime_from_to_for_trend(column, value)
          # Avoid calling to_time, not needed and broken on rails >= 4, because return local time instead of UTC
          values.collect!(&conversion) if conversion != :to_time
          values
        else
          %w[from to].collect { |field| condition_value_for_datetime(column, value[field], conversion) }
        end
      end

      def datetime_now
        Time.zone.now
      end

      def datetime_from_to_for_trend(column, value)
        case value['opt']
        when 'PAST'
          trend_number = [value['number'].to_i, 1].max
          now = datetime_now
          if datetime_column_date?(column)
            from = now.beginning_of_day.ago(trend_number.send(value['unit'].downcase.singularize.to_sym))
            to = now.end_of_day
          else
            from = now.ago(trend_number.send(value['unit'].downcase.singularize.to_sym))
            to = now
          end
          [from, to]
        when 'FUTURE'
          trend_number = [value['number'].to_i, 1].max
          now = datetime_now
          if datetime_column_date?(column)
            from = now.beginning_of_day
            to = now.end_of_day.in(trend_number.send(value['unit'].downcase.singularize.to_sym))
          else
            from = now
            to = now.in(trend_number.send(value['unit'].downcase.singularize.to_sym))
          end
          [from, to]
        end
      end

      def datetime_from_to_for_range(column, value)
        case value['range']
        when 'TODAY'
          [datetime_now.beginning_of_day, datetime_now.end_of_day]
        when 'YESTERDAY'
          [datetime_now.ago(1.day).beginning_of_day, datetime_now.ago(1.day).end_of_day]
        when 'TOMORROW'
          [datetime_now.in(1.day).beginning_of_day, datetime_now.in(1.day).end_of_day]
        else
          range_type, range = value['range'].downcase.split('_')
          raise ArgumentError unless %w[week month year].include?(range)

          case range_type
          when 'this'
            [datetime_now.send(:"beginning_of_#{range}"), datetime_now.send(:"end_of_#{range}")]
          when 'prev'
            [datetime_now.ago(1.send(range.to_sym)).send(:"beginning_of_#{range}"), datetime_now.ago(1.send(range.to_sym)).send(:"end_of_#{range}")]
          when 'next'
            [datetime_now.in(1.send(range.to_sym)).send(:"beginning_of_#{range}"), datetime_now.in(1.send(range.to_sym)).send(:"end_of_#{range}")]
          else
            [nil, nil]
          end
        end
      end

      def datetime_column_date?(column)
        column.column&.type == :date
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
    LOGICAL_COMPARATORS = [].freeze
    NULL_COMPARATORS = %w[null not_null].freeze
    DATE_COMPARATORS = %w[PAST FUTURE RANGE].freeze
    DATE_UNITS = %w[DAYS WEEKS MONTHS YEARS].freeze
    TIME_UNITS = %w[SECONDS MINUTES HOURS].freeze
    DATE_RANGES = %w[TODAY YESTERDAY TOMORROW THIS_WEEK PREV_WEEK NEXT_WEEK THIS_MONTH PREV_MONTH NEXT_MONTH THIS_YEAR PREV_YEAR NEXT_YEAR].freeze

    def self.included(klass)
      klass.extend ClassMethods
    end

    protected

    attr_writer :active_scaffold_conditions, :active_scaffold_preload, :active_scaffold_joins,
                :active_scaffold_outer_joins, :active_scaffold_references, :active_scaffold_relations

    def active_scaffold_conditions
      @active_scaffold_conditions ||= []
    end

    def active_scaffold_relations
      @active_scaffold_relations ||= []
    end

    def active_scaffold_preload
      @active_scaffold_preload ||= []
    end

    def active_scaffold_joins
      @active_scaffold_joins ||= []
    end

    def active_scaffold_outer_joins
      @active_scaffold_outer_joins ||= []
    end

    def active_scaffold_references
      @active_scaffold_references ||= []
    end

    # Override this method on your controller to define conditions to be used when querying a recordset (e.g. for List).
    # The return of this method should be any format compatible with the :conditions clause of ActiveRecord::Base's find.
    def conditions_for_collection; end

    # Override this method on your controller to define joins to be used when querying a recordset (e.g. for List).
    # The return of this method should be any format compatible with the :joins clause of ActiveRecord::Base's find.
    def joins_for_collection; end

    # Override this method on your controller to provide custom finder options to the find() call. The return of this method should be a hash.
    def custom_finder_options
      {}
    end

    def active_scaffold_embedded_conditions
      params_hash active_scaffold_embedded_params[:conditions]
    end

    def all_conditions(id_condition: true)
      [
        (self.id_condition if id_condition),          # for list with id (e.g. /users/:id/index)
        active_scaffold_conditions,                   # from the search modules
        conditions_for_collection,                    # from the dev
        conditions_from_params,                       # from the parameters (e.g. /users/list?first_name=Fred)
        conditions_from_constraints,                  # from any constraints (embedded scaffolds)
        active_scaffold_embedded_conditions           # embedding conditions (weaker constraints)
      ].compact_blank
    end

    def id_condition
      {active_scaffold_config.primary_key => params[:id]} if params[:id]
    end

    # returns a single record (the given id) but only if it's allowed for the specified security options.
    # security options can be a hash for authorized_for? method or a value to check as a :crud_type
    # accomplishes this by checking model.#{action}_authorized?
    def find_if_allowed(id, security_options, klass = filtered_query)
      record = klass.find(id)
      security_options = {crud_type: security_options.to_sym} unless security_options.is_a? Hash
      raise ActiveScaffold::RecordNotAllowed, "#{klass} with id = #{id}" unless record.authorized_for? security_options

      record
    end

    # valid options may include:
    # * :sorting - a Sorting DataStructure (basically an array of hashes of field => direction,
    #     e.g. [{field1: 'asc'}, {field2: 'desc'}]).
    #     please note that multi-column sorting has some limitations: if any column in a multi-field
    #     sort uses method-based sorting, it will be ignored. method sorting only works for single-column sorting.
    # * :per_page
    # * :page
    def finder_options(options = {})
      search_conditions = all_conditions

      sorting = options[:sorting]&.clause
      sorting = sorting.map { |part| Arel.sql(part) } if sorting && active_scaffold_config.active_record?
      # create a general-use options array that's compatible with Rails finders
      finder_options = {
        reorder: sorting,
        conditions: search_conditions
      }
      if active_scaffold_config.mongoid?
        finder_options[:includes] = [active_scaffold_references, active_scaffold_preload].compact.flatten.uniq.presence
      else
        finder_options.merge!(
          joins:      joins_for_finder,
          left_joins: active_scaffold_outer_joins,
          preload:    active_scaffold_preload,
          includes:   active_scaffold_references.presence,
          references: active_scaffold_references.presence,
          relations:  active_scaffold_relations.presence,
          select:     options[:select]
        )
      end

      finder_options.merge! custom_finder_options
      finder_options
    end

    def count_items(query, find_options = {}, count_includes = nil)
      count_includes ||= find_options[:includes] if find_options[:conditions].present?
      options = find_options.except(:select, :reorder, :order)
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
      query = filtered_query
      query = query.where(nil) if active_scaffold_config.active_record? # where(nil) is needed because we need a relation

      # NOTE: we must use :include in the count query, because some conditions may reference other tables
      if options[:pagination] && options[:pagination] != :infinite
        count = count_items(query, find_options, options[:count_includes])
      end

      query = append_to_query(query, find_options)
      # we build the paginator differently for method- and sql-based sorting
      pager = if options[:sorting]&.sorts_by_method?
                ::Paginator.new(count, options[:per_page]) do |offset, per_page|
                  calculate_last_modified(query)
                  sorted_collection = sort_collection_by_column(query.to_a, *options[:sorting].first)
                  sorted_collection = sorted_collection.slice(offset, per_page) if options[:pagination]
                  sorted_collection
                end
              else
                ::Paginator.new(count, options[:per_page]) do |offset, per_page|
                  query = append_to_query(query, offset: offset, limit: per_page) if options[:pagination]
                  calculate_last_modified(query)
                  query
                end
              end
      pager.page(options[:page])
    end

    def calculate_last_modified(query)
      return unless conditional_get_support? && ActiveScaffold::OrmChecks.columns_hash(query.klass)['updated_at']

      @last_modified = query.maximum(:updated_at)
    end

    def calculate_subquery(id_condition: true)
      conditions = all_conditions(id_condition: id_condition)
      includes = active_scaffold_config.list.count_includes
      includes ||= active_scaffold_references if conditions.present?
      left_joins = active_scaffold_outer_joins
      left_joins += includes if includes
      primary_key = active_scaffold_config.primary_key
      subquery = append_to_query(filtered_query, conditions: conditions, joins: joins_for_finder, left_joins: left_joins, select: active_scaffold_config.columns[primary_key].field)
      subquery.unscope(:order)
    end

    def calculate_query(id_condition: true)
      active_scaffold_config.model.where(active_scaffold_config.primary_key => calculate_subquery(id_condition: id_condition))
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
      relation.distinct_value = true if options[:left_outer_joins].present? || options[:left_joins].present?
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

    # TODO: this should reside on the column, not the controller
    def sort_collection_by_column(collection, column, order)
      sorter = column.sort[:method]
      collection = collection.sort_by do |record|
        value = sorter.is_a?(Proc) ? record.instance_eval(&sorter) : record.instance_eval(sorter.to_s)
        value = '' if value.nil?
        value
      end
      collection.reverse! if order.casecmp('DESC').zero?
      collection
    end
  end
end
