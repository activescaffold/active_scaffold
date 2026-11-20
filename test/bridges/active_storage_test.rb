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

  def test_delete_helpers_purge_only_truthy_values
    record = ActiveStorageProject.new
    document = mock
    images = mock
    record.stubs(document: document, images: images)

    record.delete_document = 'false'
    record.delete_images = false

    document.expects(:purge).once
    images.expects(:purge).once
    record.delete_document = 'true'
    record.delete_images = true # rubocop:disable Lint/UselessSetterCall
  end

  def test_has_one_form_renders_existing_attachment_and_remove_controls
    column = ActiveScaffold::Config::Core.new(:active_storage_project).columns[:document]
    attachment = stub(attached?: true, variable?: false, filename: 'document.pdf')
    record = stub(document: attachment)
    stubs(:rails_blob_url).with(attachment, disposition: 'attachment').returns('/document.pdf')

    html = active_scaffold_input_active_storage_has_one(
      column,
      {name: 'record[document]', id: 'record_document', object: record}
    )

    assert_includes html, 'active_storage_controls file-input-controls'
    assert_includes html, 'name="record[delete_document]"'
    assert_includes html, 'class="remove_file"'
    assert_includes html, 'style="display: none"'
    assert_includes html, 'href="/document.pdf"'
  end

  def test_has_one_form_renders_a_visible_file_field_without_an_attachment
    column = ActiveScaffold::Config::Core.new(:active_storage_project).columns[:document]
    record = stub(document: stub(attached?: false))

    html = active_scaffold_input_active_storage_has_one(
      column,
      {name: 'record[document]', id: 'record_document', object: record}
    )

    assert_includes html, 'type="file"'
    assert_not_includes html, 'active_storage_controls'
    assert_not_includes html, 'display: none'
  end

  def test_has_many_form_preserves_existing_signed_ids_and_accepts_multiple_files
    column = ActiveScaffold::Config::Core.new(:active_storage_project).columns[:images]
    first = stub(signed_id: 'first-signed-id', variable?: false, filename: 'first.png')
    second = stub(signed_id: 'second-signed-id', variable?: false, filename: 'second.png')
    record = stub(images: [first, second])
    _view.stubs(:rails_blob_url).with(first, disposition: 'attachment').returns('/first.png')
    _view.stubs(:rails_blob_url).with(second, disposition: 'attachment').returns('/second.png')

    html = _view.active_scaffold_input_active_storage_has_many(
      column,
      {name: 'record[images]', id: 'record_images', object: record}
    )

    assert_includes html, 'name="record[images][]"'
    assert_includes html, 'value="first-signed-id"'
    assert_includes html, 'value="second-signed-id"'
    assert_includes html, 'multiple="multiple"'
    assert_equal 2, html.scan('active_storage_controls file-input-controls').size
  end

  def test_many_list_handles_empty_short_and_large_collections
    column = ActiveScaffold::Config::Core.new(:active_storage_project).columns[:images]
    assert_nil active_scaffold_column_active_storage_has_many(stub(images: stub(attached?: false)), column)

    first = stub(variable?: false, filename: 'first.png')
    second = stub(variable?: false, filename: 'second.png')
    stubs(:rails_blob_url).with(first, disposition: 'attachment').returns('/first.png')
    stubs(:rails_blob_url).with(second, disposition: 'attachment').returns('/second.png')
    stubs(:association_join_text).with(column).returns(', ')
    short = stub(images: stub(attached?: true, attachments: [first, second]))

    html = active_scaffold_column_active_storage_has_many(short, column)

    assert_includes html, 'first.png'
    assert_includes html, 'second.png'
    assert_includes html, ', '

    large = stub(images: stub(attached?: true, attachments: Array.new(4) { stub }))
    assert_equal '4 images', active_scaffold_column_active_storage_has_many(large, column)
  end

  def test_list_helper_renders_an_image_variant_when_requested
    column = ActiveScaffold::Config::Core.new(:active_storage_project).columns[:document]
    variant = stub
    attachment = stub(attached?: true, variable?: true, filename: 'image.png')
    attachment.expects(:variant).with({resize_to_limit: [100, 100]}).returns(variant)
    record = stub(document: attachment)
    stubs(:image_tag).with(variant).returns('<img class="thumbnail">'.html_safe)
    stubs(:rails_blob_url).with(attachment, disposition: 'attachment').returns('/image.png')

    html = active_scaffold_column_active_storage_has_one(
      record, column, ui_options: {thumb: {resize_to_limit: [100, 100]}}
    )

    assert_includes html, '<img class="thumbnail">'
  end
end
