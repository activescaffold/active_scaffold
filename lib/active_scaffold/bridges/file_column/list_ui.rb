module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ListColumnHelpers
      def active_scaffold_column_download_link_with_filename(record, column)
        return nil if record.send(column.name).nil?
        active_scaffold_column_download_link(record, column, File.basename(record.send(column.name)))
      end
      
      def active_scaffold_column_download_link(record, column, label = nil)
        return nil if record.send(column.name).nil?
        label||=as_(:download)
        link_to( label, url_for_file_column(record, column.name.to_s), :popup => true)
      end
      
      def active_scaffold_column_thumbnail(record, column)
        return nil if record.send(column.name).nil?
        link_to( 
          image_tag(url_for_file_column(record, column.name.to_s, "thumb"), :border => 0), 
          url_for_file_column(record, column.name.to_s), 
          :popup => true)
      end
      
    end
  end
end
