# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_paperclip(record, column, ui_options: column.options)
        paperclip = record.send(column.name.to_s)
        return nil unless paperclip.file?

        content =
          if paperclip.styles.include?(ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style)
            image_tag(paperclip.url(ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style), border: 0, alt: nil)
          else
            paperclip.original_filename
          end
        link_to(content, paperclip.url, target: '_blank', rel: 'noopener')
      end
    end
  end
end
