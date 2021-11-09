module ActiveScaffold
  # Provides support for param hashes assumed to be model attributes.
  # Support is primarily needed for creating/editing associated records using a nested hash structure.
  #
  # Paradigm Params Hash (should write unit tests on this):
  #   params[:record] = {
  #     # a simple record attribute
  #     'name' => 'John',
  #     # a plural association hash
  #     'roles' => {
  #       # hack to be able to clear roles
  #       '0' => ''
  #       # associate with an existing role
  #       '5' => {'id' => 5}
  #       # associate with an existing role and edit it
  #       '6' => {'id' => 6, 'name' => 'designer'}
  #       # create and associate a new role
  #       '124521' => {'name' => 'marketer'}
  #     }
  #     # a singular association hash
  #     'location' => {'id' => 12, 'city' => 'New York'}
  #   }
  #
  # Simpler association structures are also supported, like:
  #   params[:record] = {
  #     # a simple record attribute
  #     'name' => 'John',
  #     # a plural association ... all ids refer to existing records
  #     'roles' => ['5', '6'],
  #     # a singular association ... all ids refer to existing records
  #     'location' => '12'
  # }
  module AttributeParams
    protected

    # workaround for updating counters twice bug on rails4 (https://github.com/rails/rails/pull/14849)
    # rails 5 needs this hack for belongs_to, when selecting record, not creating new one (value is Hash)
    # TODO: remove when rails5 support is removed
    def belongs_to_counter_cache_hack?(association, value)
      !params_hash?(value) && association.belongs_to? && association.counter_cache_hack?
    end

    def multi_parameter_attributes(attributes)
      params_hash(attributes).each_with_object({}) do |(k, v), result|
        next unless k.include? '('
        column_name = k.split('(').first
        result[column_name] ||= []
        result[column_name] << [k, v]
      end
    end

    # Takes attributes (as from params[:record]) and applies them to the parent_record. Also looks for
    # association attributes and attempts to instantiate them as associated objects.
    #
    # This is a secure way to apply params to a record, because it's based on a loop over the columns
    # set. The columns set will not yield unauthorized columns, and it will not yield unregistered columns.
    def update_record_from_params(parent_record, columns, attributes, avoid_changes = false)
      crud_type = parent_record.new_record? ? :create : :update
      return parent_record unless parent_record.authorized_for?(:crud_type => crud_type)

      multi_parameter_attrs = multi_parameter_attributes(attributes)

      columns.each_column(for: parent_record, crud_type: crud_type, flatten: true) do |column|
        # Set any passthrough parameters that may be associated with this column (ie, file column "keep" and "temp" attributes)
        column.params.select { |p| attributes.key? p }.each { |p| parent_record.send("#{p}=", attributes[p]) }

        if multi_parameter_attrs.key? column.name.to_s
          parent_record.send(:assign_multiparameter_attributes, multi_parameter_attrs[column.name.to_s])
        elsif attributes.key? column.name
          update_column_from_params(parent_record, column, attributes[column.name], avoid_changes)
        end
      rescue StandardError => e
        message = "on the ActiveScaffold column = :#{column.name} for #{parent_record.inspect} "\
                  "(value from params #{attributes[column.name].inspect})"
        Rails.logger.error "#{e.class.name}: #{e.message} -- #{message}"
        raise
      end

      parent_record
    end

    def update_column_from_params(parent_record, column, attribute, avoid_changes = false)
      value = column_value_from_param_value(parent_record, column, attribute, avoid_changes)
      if column.association
        if avoid_changes
          parent_record.association(column.name).target = value
          parent_record.send("#{column.association.foreign_key}=", value&.id) if column.association.belongs_to?
        else
          update_column_association(parent_record, column, attribute, value)
        end
      else
        parent_record.send "#{column.name}=", value
      end
      # needed? probably done on find_or_create_for_params, need more testing
      if column.association&.reverse_association&.belongs_to?
        Array(value).each { |v| v.send("#{column.association.reverse}=", parent_record) if v.new_record? }
      end
      value
    end

    def update_column_association(parent_record, column, attribute, value)
      if belongs_to_counter_cache_hack?(column.association, attribute)
        parent_record.send "#{column.association.foreign_key}=", value&.id
        parent_record.association(column.name).target = value
      elsif column.association.collection? && column.association.through_singular?
        through = column.association.through_reflection.name
        through_record = parent_record.send(through)
        through_record ||= parent_record.send "build_#{through}"
        through_record.send "#{column.association.source_reflection.name}=", value
      else
        parent_record.send "#{column.name}=", value
      end
    rescue ActiveRecord::RecordNotSaved
      parent_record.errors.add column.name, :invalid
      parent_record.association(column.name).target = value
    end

    def column_value_from_param_value(parent_record, column, value, avoid_changes = false)
      # convert the value, possibly by instantiating associated objects
      form_ui = column.form_ui || column.column&.type
      if form_ui && respond_to?("column_value_for_#{form_ui}_type", true)
        send("column_value_for_#{form_ui}_type", parent_record, column, value)
      elsif params_hash? value
        column_value_from_param_hash_value(parent_record, column, params_hash(value), avoid_changes)
      else
        column_value_from_param_simple_value(parent_record, column, value)
      end
    end

    def datetime_conversion_for_value(column)
      if column.column
        column.column.type == :date ? :to_date : :to_time
      else
        :to_time
      end
    end

    def column_value_for_datetime_type(parent_record, column, value)
      new_value = self.class.condition_value_for_datetime(column, value, datetime_conversion_for_value(column))
      if new_value.nil? && value.present?
        parent_record.errors.add column.name, :invalid
      end
      new_value
    end

    def column_value_for_month_type(parent_record, column, value)
      Date.parse("#{value}-01")
    end

    def association_value_from_param_simple_value(parent_record, column, value)
      if column.association.singular?
        column.association.klass(parent_record)&.find(value) if value.present?
      else # column.association.collection?
        column_plural_assocation_value_from_value(column, Array(value))
      end
    end

    def column_value_from_param_simple_value(parent_record, column, value)
      if column.association
        association_value_from_param_simple_value(parent_record, column, value)
      elsif column.convert_to_native?
        column.number_to_native(value)
      elsif value.is_a?(String) && value.empty? && !column.virtual?
        # convert empty strings into nil. this works better with 'null => true' columns (and validations),
        # for 'null => false' columns is just converted to default value from column
        column.default_for_empty_value
      else
        value
      end
    end

    def column_plural_assocation_value_from_value(column, value)
      # it's an array of ids
      if value.present?
        ids = value.select(&:present?)
        ids.empty? ? [] : column.association.klass.find(ids)
      else
        []
      end
    end

    def column_value_from_param_hash_value(parent_record, column, value, avoid_changes = false)
      if column.association&.singular?
        manage_nested_record_from_params(parent_record, column, value, avoid_changes)
      elsif column.association&.collection?
        # HACK: to be able to delete all associated records, hash will include "0" => ""
        values = value.values.reject(&:blank?)
        values.collect { |val| manage_nested_record_from_params(parent_record, column, val, avoid_changes) }.compact
      else
        value
      end
    end

    def manage_nested_record_from_params(parent_record, column, attributes, avoid_changes = false)
      return nil unless build_record_from_params?(attributes, column, parent_record)
      record = find_or_create_for_params(attributes, column, parent_record)
      if record
        record_columns = active_scaffold_config_for(record.class).subform.columns
        prev_constraints = record_columns.constraint_columns
        record_columns.constraint_columns = [column.association.reverse].compact
        update_record_from_params(record, record_columns, attributes, avoid_changes)
        record_columns.constraint_columns = prev_constraints
        record.unsaved = true
      end
      record
    end

    def build_record_from_params?(params, column, record)
      current = record.send(column.name)
      return true if column.association.collection? && !column.show_blank_record?(current)
      klass = column.association.klass(record)
      klass && !attributes_hash_is_empty?(params, klass)
    end

    # Attempts to create or find an instance of the klass of the association in parent_column from the
    # request parameters given. If params[primary_key] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, parent_column, parent_record)
      current = parent_record.send(parent_column.name)
      klass = parent_column.association.klass(parent_record)
      if params.key? klass.primary_key
        record_from_current_or_find(klass, params[klass.primary_key], current)
      elsif klass.authorized_for?(:crud_type => :create)
        association = parent_column.association
        record = klass.new
        if association.reverse_association&.belongs_to? && (association.collection? || current.nil?)
          record.send("#{parent_column.association.reverse}=", parent_record)
        end
        record
      end
    end

    # Attempts to find an instance of klass (which must be an ActiveRecord object) with id primary key
    # Returns record from current if it's included or find from DB
    def record_from_current_or_find(klass, id, current)
      if current.is_a?(ActiveRecord::Base) && current.id.to_s == id
        # modifying the current object of a singular association
        current
      elsif current.respond_to?(:any?) && current.any? { |o| o.id.to_s == id }
        # modifying one of the current objects in a plural association
        current.detect { |o| o.id.to_s == id }
      else # attaching an existing but not-current object
        klass.find(id)
      end
    end

    # Determines whether the given attributes hash is "empty".
    # This isn't a literal emptiness - it's an attempt to discern whether the user intended it to be empty or not.
    def attributes_hash_is_empty?(hash, klass)
      hash.all? do |key, value|
        # convert any possible multi-parameter attributes like 'created_at(5i)' to simply 'created_at'
        column_name = key.to_s.split('(', 2)[0]

        # datetimes will always have a value. so we ignore them when checking whether the hash is empty.
        # this could be a bad idea. but the current situation (excess record entry) seems worse.
        next true if mulitpart_ignored?(key, klass)

        # defaults are pre-filled on the form. we can't use them to determine if the user intends a new row.
        # booleans always have value, so they are ignored if not changed from default
        next true if default_value?(column_name, klass, value)

        if params_hash? value
          attributes_hash_is_empty?(value, klass)
        elsif value.is_a?(Array)
          value.all?(&:blank?)
        else
          value.respond_to?(:empty?) ? value.empty? : false
        end
      end
    end

    # old style date form management... ignore them
    MULTIPART_IGNORE_TYPES = [:datetime, :date, :time, Time, Date].freeze

    def mulitpart_ignored?(param_name, klass)
      column_name, multipart = param_name.to_s.split('(', 2)
      return false unless multipart
      column_type = ActiveScaffold::OrmChecks.column_type(klass, column_name)
      MULTIPART_IGNORE_TYPES.include?(column_type) if column_type
    end

    def default_value?(column_name, klass, value)
      column = ActiveScaffold::OrmChecks.columns_hash(klass)[column_name]
      default_value = column_default_value(column_name, klass)
      casted_value = ActiveScaffold::Core.column_type_cast(value, column)
      casted_value == default_value
    end

    def column_default_value(column_name, klass)
      column = ActiveScaffold::OrmChecks.columns_hash(klass)[column_name]
      return unless column
      if ActiveScaffold::OrmChecks.mongoid? klass
        column.default_val
      elsif ActiveScaffold::OrmChecks.active_record? klass
        column_type = ActiveScaffold::OrmChecks.column_type(klass, column_name)
        cast_type = ActiveRecord::Type.lookup column_type
        cast_type ? cast_type.deserialize(column.default) : column.default
      end
    end
  end
end
