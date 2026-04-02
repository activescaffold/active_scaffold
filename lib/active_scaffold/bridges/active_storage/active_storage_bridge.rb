# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class ActiveStorage
      module ActiveStorageBridge
        def initialize(model_id)
          super
          return unless ActiveScaffold::Bridges::ActiveStorage::ActiveStorageBridgeHelpers.klass_has_active_storage_fields?(model)

          model.send :extend, ActiveScaffold::Bridges::ActiveStorage::ActiveStorageBridgeHelpers

          # include the "delete" helpers for use with active scaffold, unless they are already included
          model.generate_delete_helpers

          update.multipart = true
          create.multipart = true

          model.active_storage_has_one_fields.each { |field| configure_active_storage_field(field.to_sym, :has_one) }
          model.active_storage_has_many_fields.each { |field| configure_active_storage_field(field.to_sym, :has_many) }
        end

        private

        def configure_active_storage_field(field, field_type)
          columns << field
          columns.exclude :"#{field}_attachment#{'s' if field_type == :has_many}"
          columns.exclude :"#{field}_blob#{'s' if field_type == :has_many}"
          columns[field].includes ||= [:"#{field}_attachment#{'s' if field_type == :has_many}", :"#{field}_blob#{'s' if field_type == :has_many}"]
          columns[field].form_ui ||= :"active_storage_#{field_type}"
          columns[field].params.add "delete_#{field}"
        end
      end
    end
  end
end
