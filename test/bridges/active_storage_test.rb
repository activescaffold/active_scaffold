# frozen_string_literal: true

require 'test_helper'

ActiveScaffold::Bridges::ActiveStorage.install

class ActiveStorageProject < Project
  has_one_attached :document
  has_many_attached :images
end

class ActiveStorageTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers

  def test_bridge_configures_real_active_storage_attachments
    config = ActiveScaffold::Config::Core.new(:active_storage_project)

    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :active_storage_has_one, config.columns[:document].form_ui
    assert_equal :active_storage_has_many, config.columns[:images].form_ui
    assert_equal %i[document_attachment document_blob], config.columns[:document].includes
    assert_includes config.columns[:document].params, :delete_document
    assert_includes config.columns[:images].params, :delete_images
    assert_respond_to ActiveStorageProject.new, :delete_document=
    assert_respond_to ActiveStorageProject.new, :delete_images=
  end

  def test_list_helper_links_an_attachment
    config = ActiveScaffold::Config::Core.new(:active_storage_project)
    column = config.columns[:document]
    attachment = stub(attached?: true, variable?: false, filename: 'document.pdf')
    record = stub(document: attachment)
    stubs(:rails_blob_url).with(attachment, disposition: 'attachment').returns('/document.pdf')

    html = active_scaffold_column_active_storage_has_one(record, column)

    assert_includes html, '>document.pdf</a>'
    assert_includes html, 'href="/document.pdf"'
    assert_includes html, 'rel="noopener noreferrer"'
  end
end
