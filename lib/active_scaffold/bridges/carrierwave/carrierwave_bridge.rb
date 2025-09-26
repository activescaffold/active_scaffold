# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class Carrierwave
      module CarrierwaveBridge
        def initialize(model_id)
          super
          return unless model.respond_to?(:uploaders) && model.uploaders.present?

          update.multipart = true
          create.multipart = true

          model.uploaders.each_key do |field|
            configure_carrierwave_field(field.to_sym)
          end
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
