module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      def active_scaffold_column_active_storage(record, column)
        active_storage = record.send(column.name.to_s)
        return nil unless active_storage.attached?

        link_to(active_storage.filename, rails_blob_url(active_storage, disposition: 'attachment'), target: '_blank')
      end
    end
  end
end
