# frozen_string_literal: true

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

    def multi_parameter_attributes(attributes)
      params_hash(attributes).each_with_object({}) do |(k, v), result|
        next unless k.include? '('

        column_name = k.split('(').first
        result[column_name] ||= []
        result[column_name] << [k, v]
      end
    end

    def assign_locking_column(parent_record, attributes)
      return unless parent_record.persisted? && parent_record.locking_enabled? &&
                    attributes.include?(parent_record.class.locking_column)

      parent_record.write_attribute parent_record.class.locking_column, attributes[parent_record.class.locking_column]
    end

    # Takes attributes (as from params[:record]) and applies them to the parent_record. Also looks for
    # association attributes and attempts to instantiate them as associated objects.
    #
    # This is a secure way to apply params to a record, because it's based on a loop over the columns
    # set. The columns set will not yield unauthorized columns, and it will not yield unregistered columns.
    def update_record_from_params(parent_record, columns, attributes, avoid_changes = false, search_attributes: false)
      crud_type = parent_record.new_record? ? :create : :update
      return parent_record unless parent_record.authorized_for?(crud_type: crud_type)

      assign_locking_column(parent_record, attributes)
      update_columns_from_params(parent_record, columns, attributes, crud_type, avoid_changes: avoid_changes, search_attributes: search_attributes)
      parent_record
    end

    def update_columns_from_params(parent_record, columns, attributes, crud_type, avoid_changes: false, search_attributes: false)
      multi_parameter_attrs = multi_parameter_attributes(attributes)
      columns.each_column(for: parent_record, crud_type: crud_type, flatten: true) do |column|
        # Set any passthrough parameters that may be associated with this column (ie, file column "keep" and "temp" attributes)
        assign_column_params(parent_record, column, attributes)

        if multi_parameter_attrs.key? column.name.to_s
          parent_record.send(:assign_multiparameter_attributes, multi_parameter_attrs[column.name.to_s])
        elsif attributes.key? column.name
          next if search_attributes && params_hash?(attributes[column.name])

          update_column_from_params(parent_record, column, attributes[column.name], avoid_changes)
        end
      rescue StandardError => e
        message = "on the ActiveScaffold column = :#{column.name} for #{parent_record.inspect} " \
                  "(value from params #{attributes[column.name].inspect})"
        ActiveScaffold.log_exception(e, message)
        raise e.class, "#{e.message} -- #{message}", e.backtrace
      end
    end

    def assign_column_params(parent_record, column, attributes)
      column.params.select { |p| attributes.key? p }.each { |p| parent_record.send(:"#{p}=", attributes[p]) }
    end

    def update_column_from_params(parent_record, column, attribute, avoid_changes = false)
      value = column_value_from_param_value(parent_record, column, attribute, avoid_changes)
      if column.association
        update_column_association(parent_record, column, attribute, value, avoid_changes)
      else
        parent_record.send :"#{column.name}=", value
      end
      # needed? probably done on find_or_create_for_params, need more testing
      if column.association&.reverse_association&.belongs_to?
        Array(value).each { |v| v.send(:"#{column.association.reverse}=", parent_record) if v.new_record? }
      end
      value
    end

    def assign_column_association(parent_record, column, attribute, value)
      parent_record.association(column.name).target = value
      parent_record.send(:"#{column.association.foreign_key}=", value&.id) if column.association.belongs_to?
    end

    def update_column_association(parent_record, column, attribute, value, avoid_changes = false)
      if avoid_changes
        assign_column_association(parent_record, column, attribute, value)
      elsif column.association.collection? && column.association.through_singular?
        through = column.association.through_reflection.name
        through_record = parent_record.send(through)
        through_record ||= parent_record.send :"build_#{through}"
        through_record.send :"#{column.association.source_reflection.name}=", value
      else
        parent_record.send :"#{column.name}=", value
      end
    rescue ActiveRecord::RecordNotSaved
      parent_record.errors.add column.name, :invalid
      parent_record.association(column.name).target = value
    end

    def column_value_from_param_value(parent_record, column, value, avoid_changes = false)
      # convert the value, possibly by instantiating associated objects
      form_ui = column.form_ui || column.column&.type
      if form_ui && respond_to?(:"column_value_for_#{form_ui}_type", true)
        send(:"column_value_for_#{form_ui}_type", parent_record, column, value)
      elsif params_hash? value
        column_value_from_param_hash_value(parent_record, column, params_hash(value), avoid_changes)
      else
        column_value_from_param_simple_value(parent_record, column, value)
      end
    end

    def datetime_conversion_for_value(column)
      if column.column
        column.column_type == :date ? :to_date : :to_time
      else
        :to_time
      end
    end

    def column_value_for_datetime_type(parent_record, column, value)
      new_value = self.class.condition_value_for_datetime(column, value, datetime_conversion_for_value(column), ui_method: :form_ui)
      parent_record.errors.add column.name, :invalid if new_value.nil? && value.present?
      new_value
    end

    def column_value_for_month_type(parent_record, column, value)
      Date.parse("#{value}-01")
    end

    def association_value_from_param_simple_value(parent_record, column, value)
      if column.association.singular?
        column_singular_assocation_value_from_value(parent_record, column, value)
      else # column.association.collection?
        column_plural_assocation_value_from_value(parent_record, column, Array(value))
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
      elsif value.is_a?(Array)
        # for select_multiple or checkboxes in DB columns, needs to remove blank string used to clear the column
        value.compact_blank!
      else
        value
      end
    end

    def column_singular_assocation_value_from_value(parent_record, column, value)
      # value may be Array if using update_columns in field_search with multi-select
      return if value.blank? || value.is_a?(Array)

      if parent_record.association_cached?(column.name) && parent_record.send(column.name)&.id.to_s == value
        parent_record.send(column.name)
      else
        klass = column.association.klass(parent_record)
        # find_by needed when using update_columns in type foreign type key of polymorphic association,
        # and foreign key had value, it will try to find record with id of previous type
        klass&.find_by(klass.primary_key => value)
      end
    end

    def column_plural_assocation_value_from_value(parent_record, column, value)
      # it's an array of ids
      if value.present?
        ids = value.compact_blank
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
        value.compact_blank.filter_map do |id, attributes|
          manage_nested_record_from_params(parent_record, column, attributes, avoid_changes).tap do |record|
            track_new_record(record, id)
          end
        end
      else
        value
      end
    end

    def track_new_record(record, id)
      return unless record&.new_record?

      @new_records ||= Hash.new { |h, k| h[k] = {} }
      @new_records[record.class][id] = record
    end

    def subform_columns(column, klass)
      subform_cfg = active_scaffold_config_for(klass).subform
      columns = (column.form_ui_options || column.options)[:subform_columns]
      columns ? subform_cfg.build_action_columns(columns) : subform_cfg.columns
    end

    def manage_nested_record_from_params(parent_record, column, attributes, avoid_changes = false)
      return nil unless avoid_changes || build_record_from_params?(attributes, column, parent_record)

      record = find_or_create_for_params(attributes, column, parent_record, avoid_changes)
      if record
        record_columns = subform_columns(column, record.class)
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
    def find_or_create_for_params(params, parent_column, parent_record, avoid_changes = false)
      current = parent_record.send(parent_column.name)
      klass = parent_column.association.klass(parent_record)
      if params.key? klass.primary_key
        record_from_current_or_find(klass, params[klass.primary_key], current, avoid_changes)
      elsif klass.authorized_for?(crud_type: :create)
        association = parent_column.association
        record = klass.new
        if association.reverse_association&.belongs_to? && (association.collection? || current.nil?)
          record.send(:"#{parent_column.association.reverse}=", parent_record)
        end
        record
      end
    end

    # Attempts to find an instance of klass (which must be an ActiveRecord object) with id primary key
    # Returns record from current if it's included or find from DB
    def record_from_current_or_find(klass, id, current, avoid_changes = false)
      record = record_from_current(current, id)
      record ||= klass.new(klass.primary_key => id) if avoid_changes
      record ||= klass.find(id)
      record = copy_attributes(record) if avoid_changes && record.persisted?
      record
    end

    def record_from_current(current, id)
      if current.is_a?(ActiveRecord::Base) && current.id.to_s == id
        # modifying the current object of a singular association
        current
      elsif current.respond_to?(:any?)
        # modifying one of the current objects in a plural association
        current.detect { |o| o.id.to_s == id }
      end
    end

    # Determines whether the given attributes hash is "empty".
    # This isn't a literal emptiness - it's an attempt to discern whether the user intended it to be empty or not.
    def attributes_hash_is_empty?(hash, klass)
      hash.all? do |key, value|
        # datetimes will always have a value. so we ignore them when checking whether the hash is empty.
        # this could be a bad idea. but the current situation (excess record entry) seems worse.
        next true if mulitpart_ignored?(key, klass)

        # convert any possible multi-parameter attributes like 'created_at(5i)' to simply 'created_at'
        column_name = key.to_s.split('(', 2)[0]
        attribute_is_empty?(column_name, klass, value)
      end
    end

    def attribute_is_empty?(column_name, klass, value)
      if default_value?(column_name, klass, value)
        # defaults are pre-filled on the form. we can't use them to determine if the user intends a new row.
        # booleans always have value, so they are ignored if not changed from default
        true
      elsif params_hash? value
        attributes_hash_is_empty?(value, klass)
      elsif value.is_a?(Array)
        value.all?(&:blank?)
      else
        value.respond_to?(:empty?) ? value.empty? : false
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
      casted_value = ActiveScaffold::OrmChecks.cast(klass, column_name, value)
      default_value = ActiveScaffold::OrmChecks.default_value(klass, column_name)
      casted_value == default_value
    end
  end
end
