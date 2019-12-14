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

          model.active_storage_has_one_fields.each { |field| configure_active_storage_has_one_field(field.to_sym) }
          model.active_storage_has_many_fields.each { |field| configure_active_storage_has_many_field(field.to_sym) }
        end

        private

        def configure_active_storage_has_one_field(field)
          columns << field
          columns.exclude "#{field}_attachment".to_sym
          columns.exclude "#{field}_blob".to_sym
          columns[field].form_ui ||= :active_storage_has_one
          columns[field].params.add "delete_#{field}"
        end

        def configure_active_storage_has_many_field(field)
          columns << field
          columns.exclude "#{field}_attachments".to_sym
          columns.exclude "#{field}_blobs".to_sym
          columns[field].form_ui ||= :active_storage_has_many
          columns[field].params.add "delete_#{field}"
        end
      end
    end
  end
end
