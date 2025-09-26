# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_dragonfly(record, column, ui_options: column.options)
        attachment = record.send(column.name.to_s)
        return nil if attachment.blank?

        content =
          if attachment.image?
            image_tag(attachment.thumb(ui_options[:thumb] || ActiveScaffold::Bridges::Dragonfly::DragonflyBridgeHelpers.thumbnail_style).url, border: 0)
          else
            attachment.name
          end
        link_to(content, dragonfly_url_for_attachment(attachment, record, column, ui_options: ui_options), target: '_blank', rel: 'noopener noreferrer')
      end

      def dragonfly_url_for_attachment(attachment, record, column, ui_options: column.options)
        url_method = ui_options[:private_store] ? :url : :remote_url
        attachment.send(url_method)
      end
    end
  end
end
