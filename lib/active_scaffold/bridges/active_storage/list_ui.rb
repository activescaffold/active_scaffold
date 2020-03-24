module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_active_storage_has_one(record, column)
        attachment = record.send(column.name.to_s)
        attachment.attached? ? link_for_attachment(attachment) : nil
      end

      def active_scaffold_column_active_storage_has_many(record, column)
        active_storage_files = record.send(column.name.to_s)
        return nil unless active_storage_files.attached?

        attachments = active_storage_files.attachments
        if attachments.size <= 3 # Lets display up to three links, otherwise just show the count.
          links = attachments.map { |attachment| link_for_attachment(attachment) }
          safe_join links, association_join_text
        else
          pluralize attachments.size, column.name.to_s
        end
      end

      private

      def link_for_attachment(attachment)
        variant = column.options[:thumb] || ActiveScaffold::Bridges::ActiveStorage::ActiveStorageBridgeHelpers.thumbnail_variant
        content =
          if variant && attachment.variable?
            image_tag(attachment.variant(variant))
          else
            attachment.filename
          end
        link_to(content, rails_blob_url(attachment, disposition: 'attachment'), target: '_blank', rel: 'noopener noreferrer')
      end
    end
  end
end
