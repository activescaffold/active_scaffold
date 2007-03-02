module ActiveScaffold
  module FormAssociations
    protected

    # Takes attributes (as from params[:record]) and applies them to the parent_record. Also looks for
    # association attributes and attempts to instantiate them as associated objects.
    #
    # This is a secure way to apply params to a record, because it's based on a loop over the columns
    # set. The columns set will not yield unauthorized columns, and it will not yield unregistered columns.
    # this very effectively replaces the params[:record] filtering i set up before.
    def update_record_from_params(parent_record, columns, attributes)
      columns.each :flatten => true do |column|
        next unless attributes.has_key? column.name
        value = attributes[column.name]

        # convert the value, possibly by instantiating associated objects
        value = if column.singular_association? and column.ui_type == :select
          column.association.klass.find(value)

        elsif column.singular_association?
          hash = value
          record = find_or_create_for_params(hash, column.association.klass)
          record_columns = active_scaffold_config_for(column.association.klass).send(record.new_record? ? :create : :update).columns
          update_record_from_params(record, record_columns, hash)
          record

        elsif column.plural_association?
          value.collect do |key_value_pair|
            hash = key_value_pair[1]
            record = find_or_create_for_params(hash, column.association.klass)
            record_columns = active_scaffold_config_for(column.association.klass).send(record.new_record? ? :create : :update).columns
            update_record_from_params(record, record_columns, hash)
            record
          end

        else
          value
        end

        parent_record.send("#{column.name}=", value)
      end
      parent_record
    end

    # Attempts to create or find an instance of klass (which must be an ActiveRecord object) from the
    # request parameters given. If params[:id] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, klass)
      return nil if params.empty?

      if params.has_key? :id
        return find_if_allowed(params[:id], 'update', klass)
      else
        # TODO check that user is authorized to create a record of this klass
        return klass.new
      end
    end
  end
end