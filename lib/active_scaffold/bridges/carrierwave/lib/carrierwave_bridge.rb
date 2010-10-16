module ActiveScaffold
  module Bridges
    module Carrierwave
      module Lib
        module CarrierwaveBridge
          def initialize_with_carrierwave(model_id)
            initialize_without_carrierwave(model_id)
            return unless self.model.respond_to?(:uploaders) && self.model.uploaders.present?
      
            self.update.multipart = true
            self.create.multipart = true
      
            self.model.uploaders.keys.each do |field|
              configure_carrierwave_field(field.to_sym)
              # define the "delete" helper for use with active scaffold, unless it's already defined
              ActiveScaffold::Bridges::Carrierwave::Lib::CarrierwaveBridgeHelpers.generate_delete_helper(self.model, field)
            end
          end
      
          def self.included(base)
            base.alias_method_chain :initialize, :carrierwave
          end
      
          private
          def configure_carrierwave_field(field)
            self.columns << field
            self.columns[field].form_ui ||= :carrierwave
            self.columns[field].params.add "delete_#{field}"
      
#            [:file_name, :content_type, :file_size, :updated_at].each do |f|
#              self.columns.exclude("#{field}_#{f}".to_sym)
#            end
          end
        end
      end
    end
  end
end
