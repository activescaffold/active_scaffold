require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::ListTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end

  def test_default_options
    assert_equal 15, @config.list.per_page
    assert_equal '-', @config.list.empty_field_text
    assert !@config.list.always_show_create
  end
  
  def test_per_page
    per_page = 35
    @config.list.per_page = per_page
    assert_equal per_page, @config.list.per_page
  end
  
  def test_always_show_create
    always_show_create = true
    @config.list.always_show_create = always_show_create
    assert_equal always_show_create, @config.list.always_show_create
    @config.actions.exclude :create
    assert_equal false, @config.list.always_show_create
  end
  
  def test_always_show_create_when_create_is_not_enabled
    always_show_create = true
    @config.list.always_show_create = always_show_create
    @config.actions.exclude :create
    assert_equal false, @config.list.always_show_create
  end
end
