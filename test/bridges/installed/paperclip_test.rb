# frozen_string_literal: true

require_relative 'test_helper'

class InstalledPaperclipProject < Project
  has_attached_file :document, do_not_validate_attachment_file_type: true
end

class InstalledPaperclipBridgeTest < InstalledBridgeTestCase
  def test_paperclip_bridge_configures_uploads_deletes_and_renders_a_thumbnail
    assert_installed_bridge(:paperclip)
    config = ActiveScaffold::Config::Core.new(:installed_paperclip_project)
    column = config.columns[:document]
    paperclip = stub(file?: true, styles: {thumbnail: '40x40'}, original_filename: 'document.png')
    paperclip.stubs(:url).returns('/documents/original.png')
    paperclip.stubs(:url).with(:thumbnail).returns('/documents/thumb.png')
    record = InstalledPaperclipProject.new
    record.stubs(:document).returns(paperclip)

    assert config.create.multipart?
    assert_equal :paperclip, column.form_ui
    assert_equal [:delete_document], column.params.to_a

    html = active_scaffold_column_paperclip(record, column)
    assert_includes html, 'src="/documents/thumb.png"'
    assert_includes html, 'href="/documents/original.png"'

    form = active_scaffold_input_paperclip(
      column,
      {name: 'record[document]', id: 'record_document', object: record}
    )
    assert_includes form, 'paperclip_controls'
    assert_includes form, 'name="record[delete_document]"'

    clean_attachment = stub(dirty?: false)
    record.unstub(:document)
    record.stubs(:document).returns(clean_attachment)
    record.expects(:document=).with(nil)
    record.delete_document = 'true' # rubocop:disable Lint/UselessSetterCall
  end
end
