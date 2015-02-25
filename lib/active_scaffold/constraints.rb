module ActiveScaffold
  module Constraints
    def self.included(base)
      base.helper_method :active_scaffold_constraints
    end

    protected

    # Returns the current constraints
    def active_scaffold_constraints
      @active_scaffold_constraints ||= active_scaffold_session_storage['constraints'] || {}
    end

    # For each enabled action, adds the constrained columns to the ActionColumns object (if it exists).
    # This lets the ActionColumns object skip constrained columns.
    #
    # If the constraint value is a Hash, then we assume the constraint is a multi-level association constraint (the reverse of a has_many :through) and we do NOT register the constraint column.
    def register_constraints_with_action_columns(constrained_fields = nil)
      constrained_fields ||= []
      constrained_fields |= active_scaffold_constraints.reject { |_, v| v.is_a? Hash }.keys.collect(&:to_sym)
      exclude_actions = []
      [:list, :update].each do |action_name|
        if active_scaffold_config.actions.include? action_name
          exclude_actions << action_name unless active_scaffold_config.send(action_name).hide_nested_column
        end
      end

      # we actually want to do this whether constrained_fields exist or not, so that we can reset the array when they don't
      active_scaffold_config.actions.each do |action_name|
        next if exclude_actions.include?(action_name)
        action = active_scaffold_config.send(action_name)
        next unless action.respond_to? :columns
        action.columns.constraint_columns = constrained_fields
      end
    end

    # Returns search conditions based on the current scaffold constraints.
    #
    # Supports constraints based on either a column name (in which case it checks for an association
    # or just uses the search_sql) or a database field name.
    #
    # All of this work is primarily to support nested scaffolds in a manner generally useful for other
    # embedded scaffolds.
    def conditions_from_constraints
      hash_conditions = {}
      conditions = [hash_conditions]
      active_scaffold_constraints.each do |k, v|
        column = active_scaffold_config.columns[k]
        if column
          # Assume this is a multi-level association constraint.
          # example:
          #   data model: Park -> Den -> Bear
          #   constraint: :den => {:park => 5}
          if v.is_a? Hash
            far_association = column.association.klass.reflect_on_association(v.keys.first)
            field = far_association.klass.primary_key
            table = far_association.table_name

            active_scaffold_references.concat([{k => far_association.name}]) # e.g. {:den => :park}
            hash_conditions.merge!("#{table}.#{field}" => v.values.first)

          # association column constraint
          elsif column.association
            if column.association.macro == :has_and_belongs_to_many
              active_scaffold_habtm_joins.concat column.includes
            elsif !column.association.options[:polymorphic]
              if column.association.macro == :belongs_to
                active_scaffold_preload.concat column.includes
              else
                active_scaffold_references.concat column.includes
              end
            end
            hash_conditions.merge!(condition_from_association_constraint(column.association, v))

          # regular column constraints
          elsif column.searchable? && params[column.name] != v
            active_scaffold_references.concat column.references if column.includes.present?
            conditions << [column.search_sql.collect { |search_sql| "#{search_sql} = ?" }.join(' OR '), *([v] * column.search_sql.size)]
          end
        # unknown-to-activescaffold-but-real-database-column constraint
        elsif active_scaffold_config.model.columns_hash[k.to_s] && params[column.name] != v
          hash_conditions.merge!(k => v)
        else
          raise ActiveScaffold::MalformedConstraint, constraint_error(active_scaffold_config.model, k), caller
        end
      end
      conditions.reject(&:blank?)
    end

    # We do NOT want to use .search_sql. If anything, search_sql will refer
    # to a human-searchable value on the associated record.
    def condition_from_association_constraint(association, value)
      # when the reverse association is a :belongs_to, the id for the associated object only exists as
      # the primary_key on the other table. so for :has_one and :has_many (when the reverse is :belongs_to),
      # we have to use the other model's primary_key.
      #
      # please see the relevant tests for concrete examples.

      field =
        if [:has_one, :has_many, :has_and_belongs_to_many].include?(association.macro)
          association.klass.primary_key
        else
          association.options[:foreign_key] || association.name.to_s.foreign_key
        end

      table = case association.macro
        when :belongs_to then active_scaffold_config.model.table_name
        else association.table_name
      end

      if association.options[:primary_key]
        value = association.klass.find(value).send(association.options[:primary_key])
      end

      condition = {"#{table}.#{field}" => value}
      if association.options[:polymorphic]
        raise ActiveScaffold::MalformedConstraint, polymorphic_constraint_error(association), caller unless params[:parent_model]
        condition["#{table}.#{association.name}_type"] = params[:parent_model].constantize.to_s
      end

      condition
    end

    def polymorphic_constraint_error(association)
      "Malformed constraint. You have added a constraint for #{association.name} polymorphic association but parent_model is not set."
    end

    def constraint_error(klass, column_name)
      "Malformed constraint `#{klass}##{column_name}'. If it's a legitimate column, and you are using a nested scaffold, please specify or double-check the reverse association name."
    end

    # Applies constraints to the given record.
    #
    # Searches through the known columns for association columns. If the given constraint is an association,
    # it assumes that the constraint value is an id. It then does a association.klass.find with the value
    # and adds the associated object to the record.
    #
    # For some operations ActiveRecord will automatically update the database. That's not always ok.
    # If it *is* ok (e.g. you're in a transaction), then set :allow_autosave to true.
    def apply_constraints_to_record(record, options = {})
      options[:allow_autosave] = false if options[:allow_autosave].nil?

      active_scaffold_constraints.each do |k, v|
        column = active_scaffold_config.columns[k]
        if column && column.association
          if column.plural_association?
            record.send("#{k}").send(:<<, column.association.klass.find(v))
          elsif column.association.options[:polymorphic]
            raise ActiveScaffold::MalformedConstraint, polymorphic_constraint_error(column.association), caller unless params[:parent_model]
            record.send("#{k}=", params[:parent_model].constantize.find(v))
          else # regular singular association
            record.send("#{k}=", column.association.klass.find(v))

            # setting the belongs_to side of a has_one isn't safe. if the has_one was already
            # specified, rails won't automatically clear out the previous associated record.
            #
            # note that we can't take the extra step to correct this unless we're permitted to
            # run operations where activerecord auto-saves the object.
            reverse = column.association.klass.reflect_on_association(column.association.reverse)
            if reverse.macro == :has_one && options[:allow_autosave]
              record.send(k).send("#{column.association.reverse}=", record)
            end
          end
        else
          record.send("#{k}=", v)
        end
      end
    end
  end
end
