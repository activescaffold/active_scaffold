# frozen_string_literal: true

ActiveScaffold::DataStructures::Column.class_eval do
  attr_accessor :file_column_display
end

class ActiveScaffold::Bridges::FileColumn
  module FileColumnBridge
    attr_accessor :file_column_fields

    def initialize(model_id)
      super

      return unless ActiveScaffold::Bridges::FileColumn::FileColumnHelpers.klass_has_file_column_fields?(model)

      model.send :extend, ActiveScaffold::Bridges::FileColumn::FileColumnHelpers

      # include the "delete" helpers for use with active scaffold, unless they are already included
      model.generate_delete_helpers

      # switch on multipart
      update.multipart = true
      create.multipart = true

      model.file_column_fields.each { |field| configure_file_column_field(field) }
    end

    def configure_file_column_field(field)
      # set list_ui first because it gets its default value from form_ui
      columns[field].list_ui ||=
        if model.field_has_image_version?(field, 'thumb')
          :thumbnail
        else
          :download_link_with_filename
        end
      columns[field].form_ui ||= :file_column

      # Allow the two helper attributes that file-column needs Active Scaffold to assign to the model.
      columns[field].params.add "#{field}_temp", "delete_#{field}"

      # set null to false so active_scaffold wont set it to null
      # delete_file_column will take care of deleting a file or not.
      _columns_hash[field.to_s].instance_variable_set(:@null, false)
    rescue StandardError
      false
    end
  end
end
ActiveScaffold::Config::Core.prepend ActiveScaffold::Bridges::FileColumn::FileColumnBridge
