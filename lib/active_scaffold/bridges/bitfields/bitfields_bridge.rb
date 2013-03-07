module ActiveScaffold
  module Bridges
    class Bitfields
      module BitfieldsBridge
        def initialize_with_bitfields(model_id)
          initialize_without_bitfields(model_id)
          return unless self.model.respond_to?(:bitfields) and self.model.bitfields.present?

          self.model.bitfields.each do |column_name, options|
            self.columns << options.keys
            options.each do |column, value|
              self.columns[column].form_ui = :checkbox
              self.columns[column].weight = 1000 + value.to_s(2).size
            end
          end
        end
        
        def _load_action_columns_with_bitfields
          self.model.bitfields.each do |column_name, options|
            columns = options.keys.sort_by { |column| self.columns[column].weight }
            [:create, :update, :show, :subform].each do |action|
              if self.actions.include? action
                self.send(action).columns.exclude column_name
                self.send(action).columns.add_subgroup(column_name) { |group| group.add *columns }
              end
            end
          end if self.model.respond_to?(:bitfields) and self.model.bitfields.present?
          
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
