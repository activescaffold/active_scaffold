# frozen_string_literal: true

class MockModel
  attr_accessor :name, :bio, :band_image, :band_image_just_uploaded

  def band_image_just_uploaded?
    band_image_just_uploaded
  end
end
