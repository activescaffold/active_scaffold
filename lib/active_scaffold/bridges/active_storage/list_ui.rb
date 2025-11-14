# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_active_storage_has_one(record, column, ui_options: column.options)
        attachment = record.send(column.name.to_s)
        attachment.attached? ? link_for_attachment(attachment, column, ui_options: ui_options) : nil
      end

      def active_scaffold_column_active_storage_has_many(record, column, ui_options: column.options)
        active_storage_files = record.send(column.name.to_s)
        return nil unless active_storage_files.attached?

        attachments = active_storage_files.attachments
        if attachments.size <= 3 # Lets display up to three links, otherwise just show the count.
          links = attachments.map { |attachment| link_for_attachment(attachment, column, ui_options: ui_options) }
          safe_join links, association_join_text(column)
        else
          pluralize attachments.size, column.name.to_s
        end
      end

      private

      def link_for_attachment(attachment, column, ui_options: column.options)
        variant = ui_options[:thumb] || ActiveScaffold::Bridges::ActiveStorage.thumbnail_variant
        content =
          if variant && attachment.variable? && ui_options[:thumb] != false
            image_tag(attachment.variant(variant))
          else
            attachment.filename
          end
        link_to(content, rails_blob_url(attachment, disposition: 'attachment'), target: '_blank', rel: 'noopener noreferrer')
      end
    end
  end
end
