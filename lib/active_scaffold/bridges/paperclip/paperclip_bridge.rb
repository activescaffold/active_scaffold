module ActiveScaffold
  module Bridges
    class Paperclip
      module PaperclipBridge
        def initialize_with_paperclip(model_id)
          initialize_without_paperclip(model_id)
          return unless model.respond_to?(:attachment_definitions) && !model.attachment_definitions.nil?

          update.multipart = true
          create.multipart = true

          model.attachment_definitions.keys.each do |field|
            configure_paperclip_field(field.to_sym)
            # define the "delete" helper for use with active scaffold, unless it's already defined
            ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.generate_delete_helper(model, field)
          end
        end

        def self.included(base)
          base.alias_method_chain :initialize, :paperclip
        end

        private

        def configure_paperclip_field(field)
          columns << field
          columns[field].form_ui ||= :paperclip
          columns[field].params.add "delete_#{field}"

          [:file_name, :content_type, :file_size, :updated_at].each do |f|
            columns.exclude("#{field}_#{f}".to_sym)
          end
        end
      end
    end
  end
end
