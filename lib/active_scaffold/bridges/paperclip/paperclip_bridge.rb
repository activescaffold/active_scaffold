module ActiveScaffold
  module Bridges
    class Paperclip
      module PaperclipBridge
        def initialize_with_paperclip(model_id)
          initialize_without_paperclip(model_id)
          return unless self.model.respond_to?(:attachment_definitions) && !self.model.attachment_definitions.nil? 

          self.update.multipart = true
          self.create.multipart = true

          self.model.attachment_definitions.keys.each do |field|
            configure_paperclip_field(field.to_sym)
            # define the "delete" helper for use with active scaffold, unless it's already defined
            ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.generate_delete_helper(self.model, field)
          end
        end

        def self.included(base)
          base.alias_method_chain :initialize, :paperclip
        end

        private
        def configure_paperclip_field(field)
          self.columns << field
          self.columns[field].form_ui ||= :paperclip
          self.columns[field].params.add "delete_#{field}"

          [:file_name, :content_type, :file_size, :updated_at].each do |f|
            self.columns.exclude("#{field}_#{f}".to_sym)
          end
        end
      end
    end
  end
end
