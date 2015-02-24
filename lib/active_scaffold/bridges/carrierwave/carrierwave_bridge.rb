module ActiveScaffold
  module Bridges
    class Carrierwave
      module CarrierwaveBridge
        def initialize_with_carrierwave(model_id)
          initialize_without_carrierwave(model_id)
          return unless model.respond_to?(:uploaders) && model.uploaders.present?

          update.multipart = true
          create.multipart = true

          model.uploaders.keys.each do |field|
            configure_carrierwave_field(field.to_sym)
          end
        end

        def self.included(base)
          base.alias_method_chain :initialize, :carrierwave
        end

        private

        def configure_carrierwave_field(field)
          columns << field
          columns[field].form_ui ||= :carrierwave # :TODO thumbnail
          columns[field].params.add "#{field}_cache"
          columns[field].params.add "remove_#{field}"
        end
      end
    end
  end
end
