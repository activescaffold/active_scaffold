require File.join(File.dirname(__FILE__), '../test_helper.rb')

class DeleteFileColumnTest < MiniTest::Test
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
    refute_nil @model.band_image
  end

  def test__delete_band_image__string_false__shouldnt_delete
    @model.delete_band_image = 'false'
    refute_nil @model.band_image
  end

  def test__just_uploaded__shouldnt_delete
    @model.band_image_just_uploaded = true
    @model.delete_band_image = 'true'
    refute_nil(@model.band_image)
  end
end
