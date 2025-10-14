# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class ActiveStorage
      module ActiveStorageBridgeHelpers
        class << self
          # has_one :"#{name}_attachment", -> { where(name: name) }, class_name: "ActiveStorage::Attachment", as: :record, inverse_of: :record, dependent: false
          def active_storage_has_one_fields(klass)
            klass.reflect_on_all_associations(:has_one)
              &.select { |reflection| reflection.class_name == 'ActiveStorage::Attachment' }
              &.collect { |association| association.name[0..-12] } || []
          end

          # has_many :"#{name}_attachments", -> { where(name: name) }, as: :record, class_name: "ActiveStorage::Attachment", inverse_of: :record, dependent: false do
          def active_storage_has_many_fields(klass)
            klass.reflect_on_all_associations(:has_many)
              &.select { |reflection| reflection.class_name == 'ActiveStorage::Attachment' }
              &.collect { |association| association.name[0..-13] } || []
          end

          def klass_has_active_storage_fields?(klass)
            active_storage_has_one_fields(klass).present? || active_storage_has_many_fields(klass).present?
          end

          def generate_delete_helpers(klass)
            (active_storage_has_one_fields(klass) | active_storage_has_many_fields(klass)).each do |field|
              next if klass.method_defined?(:"#{field}_with_delete=")
              klass.attr_reader :"delete_#{field}"
              klass.define_method "delete_#{field}=" do |value|
                value = (value == "true") if String === value
                return unless value

                # passing nil to the file column causes the file to be deleted.
                self.send(field).purge
              end
            end
          end
        end

        def active_storage_has_one_fields
          @active_storage_has_one_fields ||= ActiveStorageBridgeHelpers.active_storage_has_one_fields(self)
        end

        def active_storage_has_many_fields
          @active_storage_has_many_fields ||= ActiveStorageBridgeHelpers.active_storage_has_many_fields(self)
        end

        def generate_delete_helpers
          ActiveStorageBridgeHelpers.generate_delete_helpers(self)
        end
      end
    end
  end
end
