# frozen_string_literal: true

module ActiveScaffold::Actions
  module Core
    module RecordBuilding
      protected

      def create_on_through_singular(record, association, parent_record)
        through = parent_record.send(association.through_reflection.name) ||
                  parent_record.send(:"build_#{association.through_reflection.name}")
        if association.source_reflection.reverse_association.collection?
          record.send(association.source_reflection.reverse) << through
        else
          record.send(:"#{association.source_reflection.reverse}=", through)
        end
      end

      def empty_model
        relation = beginning_of_chain
        if nested? && nested.plural_association? && nested.match_model?(active_scaffold_config.model)
          build_options = sti_nested_build_options(relation.klass)
        end
        relation.respond_to?(:build) ? relation.build(build_options || {}) : relation.new
      end

      def new_model
        empty_model.tap do |record|
          assign_default_attributes record
        end
      end

      def assign_default_attributes(record)
        active_scaffold_config.columns.each do |column|
          record.write_attribute column.name, column.default_value if column.default_value?
        end
      end

      def sti_nested_build_options(klass)
        config = active_scaffold_config_for(klass)
        return unless config

        column = klass.inheritance_column
        return unless column && config._columns_hash[column]

        model_name = params.delete(column) # in new action inheritance_column must be in params
        model_name ||= params[:record]&.delete(column) # in create action must be inside record key
        model_name = model_name.camelize if model_name
        model_name ||= active_scaffold_config.model.name
        {column.to_sym => model_name} if model_name
      end
    end
  end
end
