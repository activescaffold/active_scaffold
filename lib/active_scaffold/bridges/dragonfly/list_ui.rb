module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_dragonfly(record, column)
        attachment = record.send(column.name.to_s)
        return nil if attachment.blank?
        content =
          if attachment.image?
            image_tag(attachment.thumb(column.options[:thumb] || ActiveScaffold::Bridges::Dragonfly::DragonflyBridgeHelpers.thumbnail_style).url, :border => 0)
          else
            attachment.name
          end
        link_to(content, dragonfly_url_for_attachment(attachment, record, column), :target => '_blank', rel: 'noopener noreferrer')
      end

      def dragonfly_url_for_attachment(attachment, record, column)
        url_method = column.options[:private_store] ? :url : :remote_url
        attachment.send(url_method)
      end
    end
  end
end
