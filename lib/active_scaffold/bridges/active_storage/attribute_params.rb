module ActiveScaffold
  module Bridges
    class ActiveStorage
      module AttributeParams
        private

        def update_column_from_params(parent_record, column, attribute, avoid_changes = false)
          return if skip_active_storage_assignment?(column, attribute)

          super
        end

        def skip_active_storage_assignment?(column, attribute)
          return false unless active_storage_form_ui?(column)

          case column.form_ui
          when :active_storage_has_one
            attribute.blank?
          when :active_storage_has_many
            active_storage_values(attribute).empty?
          else
            false
          end
        end

        def active_storage_form_ui?(column)
          [:active_storage_has_one, :active_storage_has_many].include?(column.form_ui)
        end

        def active_storage_values(attribute)
          collection =
            case attribute
            when ::ActionController::Parameters
              attribute.to_unsafe_h.values
            when Hash
              attribute.values
            else
              Array(attribute)
            end
          collection.flatten.compact_blank
        end
      end
    end
  end
end

ActiveScaffold::AttributeParams.prepend ActiveScaffold::Bridges::ActiveStorage::AttributeParams
