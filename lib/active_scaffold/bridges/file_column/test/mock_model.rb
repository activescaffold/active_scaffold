class MockModel
  attr_accessor :name
  attr_accessor :bio

  attr_accessor :band_image
  attr_accessor :band_image_just_uploaded
  def band_image_just_uploaded?
    band_image_just_uploaded
  end
end
