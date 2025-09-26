# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class Bitfields
      module BitfieldsBridge
        def initialize(model_id)
          super
          return unless model.respond_to?(:bitfields) && model.bitfields.present?

          model.bitfields.each_value do |options|
            columns << options.keys
            options.each_key.with_index(1) do |column, i|
              columns[column].form_ui = :checkbox
              columns[column].weight = 1000 + i
            end
          end
        end

        def _setup_bitfields
          return unless model.respond_to?(:bitfields) && model.bitfields.present?

          supported_actions = %i[create update show subform]
          model.bitfields.each do |column_name, options|
            columns = options.keys.sort_by { |column| self.columns[column].weight }
            supported_actions.each do |action|
              next unless actions.include? action

              if send(action).columns.include? column_name
                send(action).columns.exclude column_name
                send(action).columns.add_subgroup(column_name) { |group| group.add(*columns) }
              else
                send(action).columns.exclude(*columns)
              end
            end
          end
        end
      end
    end
  end
end
