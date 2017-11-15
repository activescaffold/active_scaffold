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

    # workaround to update counters when polymorphic has_many changes on persisted record
    # TODO: remove when rails4 support is removed or counter cache for polymorphic has_many association works on rails4
    def hack_for_has_many_counter_cache(parent_record, column, value)
      association = parent_record.association(column.name)
      counter_attr = association.send(:cached_counter_attribute_name)
      difference = value.select(&:persisted?).size - parent_record.send(counter_attr)

      if parent_record.new_record?
        if Rails.version >= '4.2.0'
          parent_record.send "#{column.name}=", value
          parent_record.send "#{counter_attr}_will_change!"
        else # < 4.2
          parent_record.send "#{counter_attr}=", difference
          parent_record.send "#{column.name}=", value
        end
      else
        # don't decrement counter for deleted records, on destroy they will update counter
        difference += (parent_record.send(column.name) - value).size
        association.send :update_counter, difference unless difference.zero?
      end

      # update counters on old parents if belongs_to is changed
      value.select(&:persisted?).each do |record|
        key = record.send(column.association.foreign_key)
        parent_record.class.decrement_counter counter_attr, key if key && key != parent_record.id
      end
      parent_record.send "#{column.name}=", value if parent_record.persisted?
    end

    # rails 4 needs this hack for polymorphic has_many
    # TODO: remove when hack_for_has_many_counter_cache is not needed
    def hack_for_has_many_counter_cache?(parent_record, column)
      column.association.counter_cache_hack? && parent_record.association(column.name).send(:has_cached_counter?)
    end

    # workaround for updating counters twice bug on rails4 (https://github.com/rails/rails/pull/14849)
    # rails 4 needs this hack for non-polymorphic belongs_to, when selecting record, not creating new one (value is Hash)
    # rails 5 needs this hack for belongs_to, when selecting record, not creating new one (value is Hash)
    # TODO: remove when pull request is merged and no version with bug is supported
    def counter_cache_hack?(association, value)
      !params_hash?(value) && association.belongs_to? && association.counter_cache_hack?
    end

    # Takes attributes (as from params[:record]) and applies them to the parent_record. Also looks for
    # association attributes and attempts to instantiate them as associated objects.
    #
    # This is a secure way to apply params to a record, because it's based on a loop over the columns
    # set. The columns set will not yield unauthorized columns, and it will not yield unregistered columns.
    def update_record_from_params(parent_record, columns, attributes, avoid_changes = false)
      crud_type = parent_record.new_record? ? :create : :update
      return parent_record unless parent_record.authorized_for?(:crud_type => crud_type)

      multi_parameter_attributes = {}
      attributes.each do |k, v|
        next unless k.include? '('
        column_name = k.split('(').first
        multi_parameter_attributes[column_name] ||= []
        multi_parameter_attributes[column_name] << [k, v]
      end

      columns.each :for => parent_record, :crud_type => crud_type, :flatten => true do |column|
        begin
          # Set any passthrough parameters that may be associated with this column (ie, file column "keep" and "temp" attributes)
          unless column.params.empty?
            column.params.each { |p| parent_record.send("#{p}=", attributes[p]) if attributes.key? p }
          end

          if multi_parameter_attributes.key? column.name.to_s
            parent_record.send(:assign_multiparameter_attributes, multi_parameter_attributes[column.name.to_s])
          elsif attributes.key? column.name
            value = update_column_from_params(parent_record, column, attributes[column.name], avoid_changes)
          end
        rescue => e
          Rails.logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} for #{parent_record.inspect}#{" with value #{value}" if value}"
          raise
        end
      end

      parent_record
    end

    def update_column_from_params(parent_record, column, attribute, avoid_changes = false)
      value = column_value_from_param_value(parent_record, column, attribute, avoid_changes)
      if avoid_changes && column.association
        parent_record.association(column.name).target = value
        parent_record.send("#{column.association.foreign_key}=", value.try(:id)) if column.association.belongs_to?
      elsif column.association && counter_cache_hack?(column.association, attribute)
        parent_record.send "#{column.association.foreign_key}=", value.try(:id)
        parent_record.association(column.name).target = value
      elsif column.association.try(:collection?) && column.association.through? && !column.association.through_reflection.collection?
        through = column.association.through_reflection.name
        through_record = parent_record.send(through)
        through_record ||= parent_record.send "build_#{through}"
        through_record.send "#{column.association.source_reflection.name}=", value
      else
        begin
          if column.association && hack_for_has_many_counter_cache?(parent_record, column)
            hack_for_has_many_counter_cache(parent_record, column, value)
          else
            parent_record.send "#{column.name}=", value
          end
        rescue ActiveRecord::RecordNotSaved
          parent_record.errors.add column.name, :invalid
          parent_record.association(column.name).target = value if column.association
        end
      end
      if column.association.try(:reverse_association).try(:belongs_to?)
        Array(value).each { |v| v.send("#{column.association.reverse}=", parent_record) if v.new_record? }
      end
      value
    end

    def column_value_from_param_value(parent_record, column, value, avoid_changes = false)
      # convert the value, possibly by instantiating associated objects
      form_ui = column.form_ui || column.column.try(:type)
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

    def column_value_from_param_simple_value(parent_record, column, value)
      if column.association.try :singular?
        if value.present?
          if column.association.polymorphic?
            class_name = parent_record.send(column.association.foreign_type)
            class_name.constantize.find(value) if class_name.present?
          else
            # it's a single id
            column.association.klass.find(value)
          end
        end
      elsif column.association.try :collection?
        column_plural_assocation_value_from_value(column, Array(value))
      elsif column.number? && column.options[:format] && column.form_ui != :number
        column.number_to_native(value)
      else
        # convert empty strings into nil. this works better with 'null => true' columns (and validations),
        # for 'null => false' columns is just converted to default value from column
        if value.is_a?(String) && value.empty? && !column.column.nil?
          value = column.column.null ? nil : column.column.default
        end
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
      if column.association.try :singular?
        manage_nested_record_from_params(parent_record, column, value, avoid_changes)
      elsif column.association.try :collection?
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
        record_columns = active_scaffold_config_for(column.association.klass).subform.columns
        record_columns.constraint_columns = [column.association.reverse].compact
        update_record_from_params(record, record_columns, attributes, avoid_changes)
        record.unsaved = true
      end
      record
    end

    def build_record_from_params?(params, column, record)
      current = record.send(column.name)
      klass = column.association.klass
      (column.association.collection? && !column.show_blank_record?(current)) || !attributes_hash_is_empty?(params, klass)
    end

    # Attempts to create or find an instance of the klass of the association in parent_column from the
    # request parameters given. If params[primary_key] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, parent_column, parent_record)
      current = parent_record.send(parent_column.name)
      klass = parent_column.association.klass
      if params.key? klass.primary_key
        record_from_current_or_find(klass, params[klass.primary_key], current)
      elsif klass.authorized_for?(:crud_type => :create)
        parent_column.association.klass.new
      end
    end

    # Attempts to find an instance of klass (which must be an ActiveRecord object) with id primary key
    # Returns record from current if it's included or find from DB
    def record_from_current_or_find(klass, id, current)
      if current && current.is_a?(ActiveRecord::Base) && current.id.to_s == id
        # modifying the current object of a singular association
        current
      elsif current && current.respond_to?(:any?) && current.any? { |o| o.id.to_s == id }
        # modifying one of the current objects in a plural association
        current.detect { |o| o.id.to_s == id }
      else # attaching an existing but not-current object
        klass.find(id)
      end
    end

    def save_record_to_association(record, association, value)
      if association.try(:collection?)
        record.send(association.name) << value
      elsif association
        record.send("#{association.name}=", value)
      end
    end

    # Determines whether the given attributes hash is "empty".
    # This isn't a literal emptiness - it's an attempt to discern whether the user intended it to be empty or not.
    def attributes_hash_is_empty?(hash, klass)
      # old style date form management... ignore them too
      part_ignore_column_types = [:datetime, :date, :time, Time, Date]

      hash.all? do |key, value|
        # convert any possible multi-parameter attributes like 'created_at(5i)' to simply 'created_at'
        parts = key.to_s.split('(')
        column_name = parts.first
        column = ActiveScaffold::OrmChecks.columns_hash(klass)[column_name]
        column_type = ActiveScaffold::OrmChecks.column_type(klass, column_name) if column

        # datetimes will always have a value. so we ignore them when checking whether the hash is empty.
        # this could be a bad idea. but the current situation (excess record entry) seems worse.
        next true if column && parts.length > 1 && part_ignore_column_types.include?(column_type)

        # defaults are pre-filled on the form. we can't use them to determine if the user intends a new row.
        # booleans always have value, so they are ignored if not changed from default
        default_value = column_default_value(column_name, klass, column)
        casted_value = column ? ActiveScaffold::Core.column_type_cast(value, column) : value
        next true if casted_value == default_value

        if params_hash? value
          attributes_hash_is_empty?(value, klass)
        elsif value.is_a?(Array)
          value.all?(&:blank?)
        else
          value.respond_to?(:empty?) ? value.empty? : false
        end
      end
    end

    def column_default_value(column_name, klass, column)
      return unless column
      if ActiveScaffold::OrmChecks.mongoid? klass
        column.default_val
      elsif ActiveScaffold::OrmChecks.active_record? klass
        if Rails.version < '4.2'
          column.default
        elsif Rails.version < '5.0'
          column.type_cast_from_database(column.default)
        else
          column_type = ActiveScaffold::OrmChecks.column_type(klass, column_name)
          cast_type = ActiveModel::Type.lookup column_type
          cast_type ? cast_type.deserialize(column.default) : column.default
        end
      end
    end
  end
end
