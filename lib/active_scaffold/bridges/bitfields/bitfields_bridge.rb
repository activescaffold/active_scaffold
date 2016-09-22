module ActiveScaffold
  module Bridges
    class Bitfields
      module BitfieldsBridge
        def initialize_with_bitfields(model_id)
          initialize_without_bitfields(model_id)
          return unless model.respond_to?(:bitfields) && model.bitfields.present?

          model.bitfields.each do |_, options|
            columns << options.keys
            options.each do |column, value|
              columns[column].form_ui = :checkbox
              columns[column].weight = 1000 + value.to_s(2).size
            end
          end
        end

        def _load_action_columns_with_bitfields
          model.bitfields.each do |column_name, options|
            columns = options.keys.sort_by { |column| self.columns[column].weight }
            [:create, :update, :show, :subform].each do |action|
              if actions.include? action
                if send(action).columns.include? column_name
                  send(action).columns.exclude column_name
                  send(action).columns.add_subgroup(column_name) { |group| group.add *columns }
                else
                  send(action).columns.exclude *columns
                end
              end
            end
          end if model.respond_to?(:bitfields) && model.bitfields.present?

          _load_action_columns_without_bitfields
        end

        def self.included(base)
          base.alias_method_chain :initialize, :bitfields
          base.alias_method_chain :_load_action_columns, :bitfields
        end
      end
    end
  end
end
