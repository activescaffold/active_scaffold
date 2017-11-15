module ActiveScaffold
  module Bridges
    class Bitfields
      module BitfieldsBridge
        def initialize(model_id)
          super
          return unless model.respond_to?(:bitfields) && model.bitfields.present?

          model.bitfields.each do |_, options|
            columns << options.keys
            options.each do |column, value|
              columns[column].form_ui = :checkbox
              columns[column].weight = 1000 + value.to_s(2).size
            end
          end
        end

        def _load_action_columns
          if model.respond_to?(:bitfields) && model.bitfields.present?
            model.bitfields.each do |column_name, options|
              columns = options.keys.sort_by { |column| self.columns[column].weight }
              %i[create update show subform].each do |action|
                next unless actions.include? action
                if send(action).columns.include? column_name
                  send(action).columns.exclude column_name
                  send(action).columns.add_subgroup(column_name) { |group| group.add *columns }
                else
                  send(action).columns.exclude *columns
                end
              end
            end
          end

          super
        end
      end
    end
  end
end
