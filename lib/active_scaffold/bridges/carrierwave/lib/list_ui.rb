module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_carrierwave(column, record)
        carrierwave = record.send("#{column.name}")
        return nil unless carrierwave.file.present? && !carrierwave.file.empty?
        thumbnail_style = ActiveScaffold::Bridges::Carrierwave::Lib::CarrierwaveBridgeHelpers.thumbnail_style
        content = if carrierwave.versions.keys.include?(thumbnail_style)
          image_tag(carrierwave.url(thumbnail_style), :border => 0).html_safe
        else
          record.send(record.send(:_mounter, column.name).send(:serialization_column))
        end
        link_to(content, carrierwave.url, :target => '_blank')
      end
    end
  end
end
