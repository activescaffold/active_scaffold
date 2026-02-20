# frozen_string_literal: true

module ActiveScaffold
  module Constraints
    def self.included(base)
      base.helper_method :active_scaffold_constraints
    end

    protected

    # Returns the current constraints
    def active_scaffold_constraints
      @active_scaffold_constraints ||= active_scaffold_embedded_params[:constraints]&.to_unsafe_h || {}
    end

    def columns_from_constraint(column_name, value)
      return if params_hash?(value)

      if value.is_a?(Array)
        column = active_scaffold_config.columns[column_name]
        if column&.association&.polymorphic?
          [column.association.foreign_type.to_sym, (column.name if value.size == 2)].compact
        elsif column && value.size == 1
          column.name
        end
      else
        column_name.to_sym
      end
    end

    # For each enabled action, adds the constrained columns to the ActionColumns object (if it exists).
    # This lets the ActionColumns object skip constrained columns.
    #
    # If the constraint value is a Hash, then we assume the constraint is a multi-level association constraint
    # (the reverse of a has_many :through) and we do NOT register the constraint column.
    # If the constraint value is an Array, or Array with more than 2 items for polymorphic column,
    # we do NOT register the constraint column, as records will have different values in the column.
    def register_constraints_with_action_columns(constrained_fields = nil)
      constrained_fields ||= []
      constrained_fields |= active_scaffold_constraints.flat_map { |k, v| columns_from_constraint(k, v) }.compact
      exclude_actions = []
      %i[list update].each do |action_name|
        if active_scaffold_config.actions.include?(action_name) && !active_scaffold_config.send(action_name).hide_nested_column
          exclude_actions << action_name
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
          #   constraint: den: {park: 5}
          if params_hash? v
            far_association = column.association.klass.reflect_on_association(v.keys.first)
            field = far_association.klass.primary_key
            table = far_association.table_name

            active_scaffold_references.push({k => far_association.name}) # e.g. {den: :park}
            hash_conditions.deep_merge!(table => {field => v.values.first})

          # association column constraint
          elsif column.association
            join_from_association_constraint(column)
            hash_conditions.deep_merge!(condition_from_association_constraint(column.association, v))

          # regular column constraints
          elsif column.searchable? && params[column.name] != v
            active_scaffold_references.concat column.references if column.includes.present?
            condition = column.search_sql.collect { |search_sql| "#{search_sql} = ?" }.join(' OR ')
            condition = ([condition] * v.size).join(' OR ') if Array(v).many?
            conditions << [condition, *(Array(v) * column.search_sql.size)]
          end
        # unknown-to-activescaffold-but-real-database-column constraint
        elsif active_scaffold_config._columns_hash[k.to_s] && params[column.name] != v
          hash_conditions.deep_merge!(k => v)
        else
          raise ActiveScaffold::MalformedConstraint, constraint_error(active_scaffold_config.model, k), caller
        end
      end
      conditions.compact_blank
    end

    def join_from_association_constraint(column)
      if column.association.habtm?
        active_scaffold_joins.concat column.includes
      elsif !column.association.polymorphic?
        if column.association.belongs_to?
          active_scaffold_preload.concat column.includes
        else
          active_scaffold_references.concat column.includes
        end
      end
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
        if association.belongs_to?
          association.foreign_key
        else
          association.klass.primary_key
        end

      table = association.belongs_to? ? active_scaffold_config.model.table_name : association.table_name
      value = Array(association.klass.find(value)).map(&association.primary_key.to_sym) if association.primary_key

      if association.polymorphic?
        unless value.is_a?(Array) && value.size >= 2
          raise ActiveScaffold::MalformedConstraint, polymorphic_constraint_error(association), caller
        end

        condition = {table => {association.foreign_type => value[0], field => value.size == 2 ? value[1] : value[1..]}}
      else
        condition = {table => {field.to_s => value}}
      end

      condition
    end

    def polymorphic_constraint_error(association)
      "Malformed constraint. You have added a constraint for #{association.name} polymorphic association but value is not an array of class name and id."
    end

    def constraint_error(klass, column_name)
      "Malformed constraint `#{klass}##{column_name}'. If it's a legitimate column, and you are using a nested scaffold, please specify or double-check the reverse association name."
    end

    def apply_constraint_on_association(record, association, value, allow_autosave: false)
      if association.through_singular? && association.source_reflection.reverse
        create_on_through_singular(record, association, association.klass.find(value))
      elsif association.collection?
        record.send(k.to_s).send(:<<, association.klass.find(value)) unless association.nested?
      elsif association.polymorphic?
        apply_constraint_on_polymorphic_association(record, association, value)
      elsif !association.source_reflection&.through? && # regular singular association, or one-level through association
            !value.is_a?(Array)
        record.send(:"#{k}=", association.klass.find(value))

        # setting the belongs_to side of a has_one isn't safe. if the has_one was already
        # specified, rails won't automatically clear out the previous associated record.
        #
        # note that we can't take the extra step to correct this unless we're permitted to
        # run operations where activerecord auto-saves the object.
        reverse = association.reverse_association
        if reverse&.singular? && !reverse.belongs_to? && allow_autosave
          record.send(k).send(:"#{reverse.name}=", record)
        end
      end
    end

    def apply_constraint_on_polymorphic_association(record, association, value)
      unless value.is_a?(Array) && value.size >= 2
        raise ActiveScaffold::MalformedConstraint, polymorphic_constraint_error(association), caller
      end

      if value.size == 2
        record.send(:"#{association.name}=", value[0].constantize.find(value[1]))
      else
        record.send(:"#{association.foreign_type}=", value[0])
      end
    end

    # Applies constraints to the given record.
    #
    # Searches through the known columns for association columns. If the given constraint is an association,
    # it assumes that the constraint value is an id. It then does a association.klass.find with the value
    # and adds the associated object to the record.
    #
    # For some operations ActiveRecord will automatically update the database. That's not always ok.
    # If it *is* ok (e.g. you're in a transaction), then set :allow_autosave to true.
    def apply_constraints_to_record(record, allow_autosave: false, constraints: active_scaffold_constraints)
      config = record.is_a?(active_scaffold_config.model) ? active_scaffold_config : active_scaffold_config_for(record.class)
      constraints.each do |k, v|
        column = config.columns[k]
        if column&.association
          apply_constraint_on_association(record, column.association, v, allow_autosave: allow_autosave)
        else
          record.send(:"#{k}=", v)
        end
      end
    end
  end
end
