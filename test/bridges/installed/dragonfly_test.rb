# frozen_string_literal: true

require_relative 'test_helper'

class InstalledDragonflyProject < Project
  extend Dragonfly::Model

  dragonfly_accessor :document
end

class InstalledDragonflyBridgeTest < InstalledBridgeTestCase
  def test_dragonfly_bridge_configures_uploads_and_renders_public_and_private_urls
    assert_installed_bridge(:dragonfly)
    config = ActiveScaffold::Config::Core.new(:installed_dragonfly_project)
    column = config.columns[:document]
    thumb = stub(url: '/documents/thumb.png')
    attachment = stub(image?: true, thumb: thumb, remote_url: '/documents/remote.png', url: '/documents/private.png')
    record = stub(document: attachment)

    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :dragonfly, column.form_ui
    assert_equal [:remove_document], column.params.to_a

    html = active_scaffold_column_dragonfly(record, column, ui_options: {thumb: '100x100'})
    assert_includes html, 'src="/documents/thumb.png"'
    assert_includes html, 'href="/documents/remote.png"'
    assert_equal '/documents/private.png', dragonfly_url_for_attachment(
      attachment, record, column, ui_options: {private_store: true}
    )

    form = active_scaffold_input_dragonfly(
      column,
      {name: 'record[document]', id: 'record_document', object: record},
      ui_options: {thumb: '100x100'}
    )
    assert_includes form, 'dragonfly_controls'
    assert_includes form, 'name="record[remove_document]"'
  end
end
