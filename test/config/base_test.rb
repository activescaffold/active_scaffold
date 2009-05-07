require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::BaseTest < Test::Unit::TestCase
  def setup
    @base = ActiveScaffold::Config::Base.new
  end
  
  def test_custom_formats
    assert_equal [], @base.custom_formats

    @base.custom_formats << :pdf
    assert_equal [:pdf], @base.custom_formats
    @base.custom_formats = [:html]
    assert_equal [:html], @base.custom_formats
  end
end
