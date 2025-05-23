module ActiveScaffold
  module Bridges
    class Dragonfly
      module DragonflyBridge
        def initialize(model_id)
          super
          return unless model.respond_to?(:dragonfly_attachment_classes) && model.dragonfly_attachment_classes.present?

          update.multipart = true
          create.multipart = true

          model.dragonfly_attachment_classes.each do |attachment|
            configure_dragonfly_field(attachment.attribute)
          end
        end

        private

        def configure_dragonfly_field(field)
          columns << field
          columns[field].form_ui ||= :dragonfly
          columns[field].params.add "remove_#{field}"

          %i[name uid].each do |f|
            columns.exclude(:"#{field}_#{f}")
          end
        end
      end
    end
  end
end
