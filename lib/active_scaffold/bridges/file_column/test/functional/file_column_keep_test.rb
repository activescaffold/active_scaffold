# frozen_string_literal: true

require 'test_helper'
require File.expand_path('../mock_model.rb', __dir__)
require File.expand_path('../../file_column_helpers.rb', __dir__)

class DeleteFileColumnTest < Minitest::Test
  def setup
    MockModel.extend ActiveScaffold::Bridges::FileColumn::FileColumnHelpers
    ActiveScaffold::Bridges::FileColumn::FileColumnHelpers.generate_delete_helpers(MockModel)
    @model = MockModel.new
    @model.band_image = 'coolio.jpg'
  end

  def test__file_column_fields
    assert_equal(1, @model.class.file_column_fields.length)
  end

  def test__delete_band_image__boolean__should_delete
    @model.delete_band_image = true
    assert_nil @model.band_image
  end

  def test__delete_band_image__string__should_delete
    @model.delete_band_image = 'true'
    assert_nil @model.band_image
  end

  def test__delete_band_image__boolean_false__shouldnt_delete
    @model.delete_band_image = false
    assert_not_nil @model.band_image
  end

  def test__delete_band_image__string_false__shouldnt_delete
    @model.delete_band_image = 'false'
    assert_not_nil @model.band_image
  end

  def test__just_uploaded__shouldnt_delete
    @model.band_image_just_uploaded = true
    @model.delete_band_image = 'true'
    assert_not_nil(@model.band_image)
  end
end
