require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::ListeTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end

  def test_default_options
    assert_equal 15, @config.list.per_page
    assert_equal '-', @config.list.empty_field_text
    assert_equal 'Create Model Stub', @config.create.label
  end
  
  def test_label
    per_page = 35
    @config.list.per_page = per_page
    assert_equal per_page, @config.list.per_page
  end
end
