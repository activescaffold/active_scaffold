module ActiveScaffold
  module Helpers
    module AssociationHelpers
      # Cache the options for select
      def cache_association_options(association, conditions, klass, cache = true)
        if active_scaffold_config.cache_association_options && cache
          @_associations_cache ||= Hash.new { |h, k| h[k] = {} }
          key = [association.name, association.active_record.name, klass.name].join('/')
          @_associations_cache[key][conditions] ||= yield
        else
          yield
        end
      end

      # Provides a way to honor the :conditions on an association while searching the association's klass
      def association_options_find(association, conditions = nil, klass = nil, record = nil)
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, call with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed
        if klass.nil? && association.options[:polymorphic]
          class_name = record.send(association.foreign_type)
          if class_name.present?
            klass = class_name.constantize
          else
            return []
          end
          cache = !block_given?
        else
          cache = !block_given? && klass.nil?
          klass ||= association.klass
        end

        if conditions.nil?
          if method(:options_for_association_conditions).arity.abs == 2
            conditions = options_for_association_conditions(association, record)
          else
            ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include record in your options_for_association_conditions overrided method.', caller if record.nil? # TODO: Remove when relying on @record is removed
            conditions = options_for_association_conditions(association)
          end
        end
        cache_association_options(association, conditions, klass, cache) do
          klass = association_klass_scoped(association, klass, record)
          relation = klass.where(conditions).where(association.options[:conditions])
          relation = relation.includes(association.options[:include]) if association.options[:include]
          column = column_for_association(association, record)
          if column && column.try(:sort) && column.sort[:sql]
            if column.includes
              include_assoc = column.includes.find { |assoc| assoc.is_a?(Hash) && assoc.include?(association.name) }
              relation = relation.includes(include_assoc[association.name]) if include_assoc
            end
            relation = relation.order(column.sort[:sql])
          end
          relation = yield(relation) if block_given?
          relation.to_a
        end
      end

      def column_for_association(association, record)
        active_scaffold_config_for(record.class).columns[association.name] rescue nil
      end

      def association_klass_scoped(association, klass, record)
        if nested? && nested.through_association? && nested.child_association.try(:through_reflection) == association
          if nested.association.through_reflection.collection?
            nested_parent_record.send(nested.association.through_reflection.name)
          else
            klass.where(association.association_primary_key => nested_parent_record.send(nested.association.through_reflection.name).try(:id))
          end
        else
          klass
        end
      end

      # Sorts the options for select
      def sorted_association_options_find(association, conditions = nil, record = nil)
        options = association_options_find(association, conditions, nil, record)
        column = column_for_association(association, record)
        unless column && column.try(:sort) && column.sort[:sql]
          method = column.options[:label_method] if column
          options = options.sort_by(&(method || :to_label).to_sym)
        end
        options
      end

      def association_options_count(association, conditions = nil)
        association.klass.where(conditions).where(association.options[:conditions]).count
      end

      def options_for_association_count(association, record)
        if method(:options_for_association_conditions).arity.abs == 2
          conditions = options_for_association_conditions(association, record)
        else
          ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include record in your options_for_association_conditions overrided method.', caller if record.nil? # TODO: Remove when relying on @record is removed
          conditions = options_for_association_conditions(association)
        end
        association_options_count(association, conditions)
      end

      # A useful override for customizing the records present in an association dropdown.
      # Should work in both the subform and form_ui=>:select modes.
      # Check association.name to specialize the conditions per-column.
      def options_for_association_conditions(association, record = nil)
        return nil if association.options[:through]
        case association.macro
          when :has_one, :has_many
            # Find only orphaned objects
            {association.foreign_key => nil}
          when :belongs_to, :has_and_belongs_to_many
            # Find all
            nil
        end
      end

      def record_select_params_for_add_existing(association, edit_associated_url_options, record)
        {:onselect => "ActiveScaffold.record_select_onselect(#{url_for(edit_associated_url_options).to_json}, #{active_scaffold_id.to_json}, id);"}
      end
    end
  end
end
