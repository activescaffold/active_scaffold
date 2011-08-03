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
            end
          end
      
          def self.included(base)
            base.alias_method_chain :initialize, :carrierwave
          end
      
          private
          def configure_carrierwave_field(field)
            self.columns << field
            self.columns[field].form_ui ||= :carrierwave # :TODO thumbnail
            self.columns[field].params.add "#{field}_cache"
            self.columns[field].params.add "remove_#{field}"
          end
        end
      end
    end
  end
end
