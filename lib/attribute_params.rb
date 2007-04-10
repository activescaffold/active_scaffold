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
  module AttributeParams
    # Takes attributes (as from params[:record]) and applies them to the parent_record. Also looks for
    # association attributes and attempts to instantiate them as associated objects.
    #
    # This is a secure way to apply params to a record, because it's based on a loop over the columns
    # set. The columns set will not yield unauthorized columns, and it will not yield unregistered columns.
    # This very effectively replaces the params[:record] filtering I set up before.
    def update_record_from_params(parent_record, columns, attributes)
      action = parent_record.new_record? ? :create : :update
      return parent_record unless parent_record.authorized_for?(:action => action)

      multi_parameter_attributes = {}
      attributes.each do |k, v|
        next unless k.include? '('
        column_name = k.split('(').first.to_sym
        multi_parameter_attributes[column_name] ||= []
        multi_parameter_attributes[column_name] << [k, v]
      end

      columns.each :for => parent_record, :flatten => true do |column|
        if multi_parameter_attributes.has_key? column.name
          parent_record.send(:assign_multiparameter_attributes, multi_parameter_attributes[column.name])
        elsif attributes.has_key? column.name
          value = attributes[column.name]

          # convert the value, possibly by instantiating associated objects
          value = if column.ui_type == :select
            ids = if column.singular_association?
              value[:id]
            else
              value.values.collect {|hash| hash[:id]}
            end
            (ids and not ids.empty?) ? column.association.klass.find(ids) : nil

          elsif column.singular_association?
            hash = value
            record = find_or_create_for_params(hash, column.association.klass, parent_record.send("#{column.name}"))
            if record
              record_columns = active_scaffold_config_for(column.association.klass).subform.columns
              update_record_from_params(record, record_columns, hash)
            end
            record

          elsif column.plural_association?
            collection = value.collect do |key_value_pair|
              hash = key_value_pair[1]
              record = find_or_create_for_params(hash, column.association.klass, parent_record.send("#{column.name}"))
              if record
                record_columns = active_scaffold_config_for(column.association.klass).subform.columns
                update_record_from_params(record, record_columns, hash)
              end
              record
            end
            collection.compact

          else
            # convert empty strings into nil. this works better with 'null => true' columns (and validations),
            # and 'null => false' columns should just convert back to an empty string.
            value = nil if value.is_a? String and value.empty?
            value
          end

          parent_record.send("#{column.name}=", value) unless column.through_association?
        # because the plural association list of checkboxes doesn't submit anything when no checkboxes are checked,
        # we need to clear the associated set when the attribute is missing from the parameters.
        elsif column.ui_type == :select and column.plural_association? and not column.through_association?
          parent_record.send("#{column.name}=", [])
        end
      end
      parent_record
    end

    # Attempts to create or find an instance of klass (which must be an ActiveRecord object) from the
    # request parameters given. If params[:id] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, klass, current)
      return nil if attributes_hash_is_empty?(params, klass)

      if params.has_key? :id
        # modifying the current object of a singular association
        if current and current.is_a? ActiveRecord::Base and current.id = params[:id]
          return current
        # modifying one of the current objects in a plural association
        elsif current and current.any? {|o| o.id.to_s == params[:id]}
          return current.detect {|o| o.id.to_s == params[:id]}
        # attaching an existing but not-current object
        else
          return klass.find(params[:id])
        end
      else
        return klass.new if klass.authorized_for?(:action => :create)
      end
    end

    # Determines whether the given attributes hash is "empty".
    # This isn't a literal emptiness - it's an attempt to discern whether the user intended it to be empty or not.
    def attributes_hash_is_empty?(hash, klass)
      hash.all? do |key,value|
        column = klass.columns_hash[key.to_s]

        # booleans and datetimes will always have a value. so we ignore them when checking whether the hash is empty.
        # this could be a bad idea. but the current situation (excess record entry) seems worse.
        next true if column and [:boolean, :datetime].include?(column.type)

        # defaults are pre-filled on the form. we can't use them to determine if the user intends a new row.
        next true if column and value == column.default

        value.is_a?(Hash) ? attributes_hash_is_empty?(value, klass) : value.empty?
      end
    end
  end
end