module ActiveScaffold
  module Helpers
    module AssociationHelpers
      # Cache the optins for select
      def cache_association_options(association, conditions, klass, cache = true)
        if active_scaffold_config.cache_association_options && cache
          @_associations_cache ||= Hash.new { |h,k| h[k] = {} }
          key = [association.name, association.active_record.name, klass.name].join('/')
          @_associations_cache[key][conditions] ||= yield
        else
          yield
        end
      end

      # Provides a way to honor the :conditions on an association while searching the association's klass
      def association_options_find(association, conditions = nil, klass = nil, record = nil)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, call with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
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
            ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include record in your options_for_association_conditions overrided method.", caller if record.nil? # TODO Remove when relying on @record is removed
            conditions = options_for_association_conditions(association)
          end
        end
        cache_association_options(association, conditions, klass, cache) do
          relation = klass.where(conditions).where(association.options[:conditions])
          relation = relation.includes(association.options[:include]) if association.options[:include]
          relation = yield(relation) if block_given?
          relation.to_a
        end
      end

      # Sorts the options for select
      def sorted_association_options_find(association, conditions = nil, record = nil)
        association_options_find(association, conditions, nil, record).sort_by(&:to_label)
      end

      def association_options_count(association, conditions = nil)
        association.klass.where(conditions).where(association.options[:conditions]).count
      end

      def options_for_association_count(association, record)
        if method(:options_for_association_conditions).arity.abs == 2
          conditions = options_for_association_conditions(association, record)
        else
          ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include record in your options_for_association_conditions overrided method.", caller if record.nil? # TODO Remove when relying on @record is removed
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
            "#{association.foreign_key} IS NULL"
          when :belongs_to, :has_and_belongs_to_many
            # Find all
            nil
        end
      end
    end
  end
end
