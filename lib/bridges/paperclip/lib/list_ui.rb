module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_paperclip(column, record)
        paperclip = record.send("#{column.name}")
        return nil unless paperclip.file?
        content = if paperclip.styles.include?(PaperclipBridgeHelpers.thumbnail_style)
          image_tag(paperclip.url(PaperclipBridgeHelpers.thumbnail_style), :border => 0)
        else
          paperclip.original_filename
        end
        link_to(content, paperclip.url, :popup => true)
      end
    end
  end
end