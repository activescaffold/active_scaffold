module ActiveScaffold
  module Bridges
    class ActiveStorage
      module ActiveStorageBridgeHelpers
        class << self
          # From active_storage/attached/macros
          # has_one :"#{name}_attachment", -> { where(name: name) }, class_name: "ActiveStorage::Attachment", as: :record, inverse_of: :record, dependent: false
          def active_storage_fields(klass)
            klass.reflect_on_all_associations(:has_one)&.select { |reflection| reflection.class_name == 'ActiveStorage::Attachment' } &.collect { |association| association.name[0..-12] }
          end

          def generate_delete_helpers(klass)
            active_storage_fields(klass).each do |field|
              klass.send :class_eval, <<-CODE, __FILE__, __LINE__ + 1 unless klass.method_defined?(:"#{field}_with_delete=")
                attr_reader :delete_#{field}

                def delete_#{field}=(value)
                  value = (value=="true") if String===value
                  return unless value

                  # passing nil to the file column causes the file to be deleted.
                  self.#{field}.purge
                end
              CODE
            end
          end

          def klass_has_active_storage_fields?(klass)
            true unless active_storage_fields(klass).empty?
          end
        end

        def active_storage_fields
          @active_storage_fields ||= ActiveStorageBridgeHelpers.active_storage_fields(self)
        end

        def generate_delete_helpers
          ActiveStorageBridgeHelpers.generate_delete_helpers(self)
        end
      end
    end
  end
end
