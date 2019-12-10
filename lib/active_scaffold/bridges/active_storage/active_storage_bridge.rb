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

          model.active_storage_fields.each do |field|
            configure_active_storage_field(field.to_sym)
          end
        end

        private

        def configure_active_storage_field(field)
          columns << field
          columns[field].form_ui ||= :active_storage
          columns[field].params.add "delete_#{field}"
        end
      end
    end
  end
end
