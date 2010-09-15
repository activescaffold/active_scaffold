require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::SubformTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end

  def test_defaults
    assert_equal :horizontal, @config.subform.layout
  end
  
  def test_setting_layout
    layout = :vertical
    @config.subform.layout = layout
    assert_equal layout, @config.subform.layout
  end
end
