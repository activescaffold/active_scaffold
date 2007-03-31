module ActiveScaffold
  module Constraints
    def self.included(base)
      base.module_eval do
        before_filter :register_constraints_with_action_columns
      end
    end

    protected

    # Returns the current constraints
    def active_scaffold_constraints
      return active_scaffold_session_storage[:constraints] || {}
    end

    # For each enabled action, adds the constrained columns to the ActionColumns object (if it exists).
    # This lets the ActionColumns object skip constrained columns.
    def register_constraints_with_action_columns
      constrained_fields = active_scaffold_constraints.keys.collect {|c| c.to_sym}

      if self.class.uses_active_scaffold? and not constrained_fields.empty?
        active_scaffold_config.actions.each do |action_name|
          action = active_scaffold_config.send(action_name)
          next unless action.respond_to? :columns
          action.columns.constraint_columns = constrained_fields
        end
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
      conditions = nil
      active_scaffold_constraints.each do |k, v|
        column = active_scaffold_config.columns[k]
        constraint_condition = if column
          # If a column is an association, then we do NOT want to use .search_sql. If anything,
          # search_sql will refer to a human-searchable value on the associated record.
          if column.association
            field = column.association.options[:foreign_key] || column.association.association_foreign_key
            table = case column.association.macro
              when :has_and_belongs_to_many
              column.association.options[:join_table]

              when :belongs_to
              active_scaffold_config.model.table_name

              when :has_many
              if column.association.options[:through]
                column.association.through_reflection.table_name
              else
                column.association.table_name
              end

              else
              column.association.table_name
            end

            active_scaffold_joins.concat column.includes
            ["#{table}.#{field} = ?", v]
          elsif column.searchable?
            active_scaffold_joins.concat column.includes
            ["#{column.search_sql} = ?", v]
          end
        elsif active_scaffold_config.model.column_names.include? k.to_s
          ["#{k.to_s} = ?", v]
        else
          raise ActiveScaffold::MalformedConstraint, constraint_error(k), caller
        end

        conditions = merge_conditions(conditions, constraint_condition)
      end

      conditions
    end

    def constraint_error(column_name)
      "Malformed constraint `#{column_name}'. If you are using a nested scaffold, please specify or double-check the reverse association name."
    end

    # Applies constraints to the given record.
    #
    # Searches through the known columns for association columns. If the given constraint is an association,
    # it assumes that the constraint value is an id. It then does a association.klass.find with the value
    # and adds the associated object to the record.
    def apply_constraints_to_record(record)
      active_scaffold_constraints.each do |k, v|
        if column = active_scaffold_config.columns[k] and column.association
          if column.plural_association?
            record.send("#{k}").send(:<<, column.association.klass.find(v))
          else # singular_association
            record.send("#{k}=", column.association.klass.find(v))
          end
        else
          record.send("#{k}=", v)
        end
      end
    end
  end
end
