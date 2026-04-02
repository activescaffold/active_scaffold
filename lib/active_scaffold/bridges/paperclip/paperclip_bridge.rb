# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class Paperclip
      module PaperclipBridge
        def initialize(model_id)
          super
          return unless model.respond_to?(:attachment_definitions) && !model.attachment_definitions.nil?

          update.multipart = true
          create.multipart = true

          model.attachment_definitions.each_key do |field|
            configure_paperclip_field(field.to_sym)
            # define the "delete" helper for use with active scaffold, unless it's already defined
            ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.generate_delete_helper(model, field)
          end
        end

        private

        def configure_paperclip_field(field)
          columns << field
          columns[field].form_ui ||= :paperclip
          columns[field].params.add "delete_#{field}"

          %i[file_name content_type file_size updated_at].each do |f|
            columns.exclude(:"#{field}_#{f}")
          end
        end
      end
    end
  end
end
