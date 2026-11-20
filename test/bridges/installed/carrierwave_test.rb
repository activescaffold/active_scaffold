# frozen_string_literal: true

require_relative 'test_helper'

class InstalledCarrierwaveUploader < CarrierWave::Uploader::Base
end

class InstalledCarrierwaveProject < Project
  mount_uploader :document, InstalledCarrierwaveUploader
end

class InstalledCarrierwaveBridgeTest < InstalledBridgeTestCase
  def test_carrierwave_bridge_configures_uploads_and_renders_a_thumbnail
    assert_installed_bridge(:carrierwave)
    config = ActiveScaffold::Config::Core.new(:installed_carrierwave_project)
    column = config.columns[:document]
    uploader = stub(file: Object.new, versions: {thumbnail: Object.new})
    uploader.stubs(:url).returns('/documents/original.png')
    uploader.stubs(:url).with(:thumbnail).returns('/documents/thumb.png')
    record = stub(document: uploader)

    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :carrierwave, column.form_ui
    assert_equal %i[document_cache remove_document], column.params.to_a

    html = active_scaffold_column_carrierwave(record, column)
    assert_includes html, 'src="/documents/thumb.png"'
    assert_includes html, 'href="/documents/original.png"'
    assert_includes html, 'rel="noopener noreferrer"'

    uploader.stubs(:to_s).returns('document.png')
    form = active_scaffold_input_carrierwave(
      column,
      {name: 'record[document]', id: 'record_document', object: record}
    )
    assert_includes form, 'carrierwave_controls'
    assert_includes form, 'name="record[document_cache]"'
    assert_includes form, 'name="record[remove_document]"'
  end
end
