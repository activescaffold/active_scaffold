# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_carrierwave(record, column, ui_options: column.options)
        carrierwave = record.send(column.name.to_s)
        return nil if carrierwave.file.blank?

        thumbnail_style = ActiveScaffold::Bridges::Carrierwave::CarrierwaveBridgeHelpers.thumbnail_style
        content =
          if carrierwave.versions.key?(thumbnail_style)
            image_tag(carrierwave.url(thumbnail_style), border: 0)
          else
            record.send(record.send(:_mounter, column.name).send(:serialization_column))
          end
        link_to(content, carrierwave.url, target: '_blank', rel: 'noopener noreferrer')
      end
    end
  end
end
