require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::CreateTest < Test::Unit::TestCase
  def setup
    @core = ActiveScaffold::Config::Core.new :model_stub
  end
  def test_custom_formats
    assert_equal [], @core.custom_formats

    @core.custom_formats << :pdf
    assert_equal [:pdf], @core.custom_formats
    @core.custom_formats = [:html]
    assert_equal [:html], @core.custom_formats
  end
end
