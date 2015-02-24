module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_paperclip(record, column)
        paperclip = record.send("#{column.name}")
        return nil unless paperclip.file?
        content =
          if paperclip.styles.include?(ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style)
            image_tag(paperclip.url(ActiveScaffold::Bridges::Paperclip::PaperclipBridgeHelpers.thumbnail_style), :border => 0)
          else
            paperclip.original_filename
          end
        link_to(content, paperclip.url, :target => '_blank')
      end
    end
  end
end
