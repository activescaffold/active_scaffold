module ActiveScaffold
  module Bridges
    class Dragonfly
      module DragonflyBridge
        def initialize_with_dragonfly(model_id)
          initialize_without_dragonfly(model_id)
          return unless self.model.respond_to?(:dragonfly_attachment_classes) && self.model.dragonfly_attachment_classes.present?

          self.update.multipart = true
          self.create.multipart = true

          self.model.dragonfly_attachment_classes.each do |attachment|
            configure_dragonfly_field(attachment.attribute)
          end
        end

        def self.included(base)
          base.alias_method_chain :initialize, :dragonfly
        end

        private
        def configure_dragonfly_field(field)
          self.columns << field
          self.columns[field].form_ui ||= :dragonfly
          self.columns[field].params.add "remove_#{field}"

          [:name, :uid].each do |f|
            self.columns.exclude("#{field}_#{f}".to_sym)
          end
        end
      end
    end
  end
end
