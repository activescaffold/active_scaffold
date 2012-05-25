require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::FieldSearchTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
    @config.actions.swap :search, :field_search
    @default_link = @config.field_search.link
  end
  
  def teardown
    @config.field_search.link = @default_link
  end
  
  def test_default_options
    assert_equal :full, @config.field_search.text_search
  end
  
  def test_text_search
    @config.field_search.text_search = :start
    assert_equal :start, @config.field_search.text_search
    @config.field_search.text_search = :end
    assert_equal :end, @config.field_search.text_search
    @config.field_search.text_search = false
    assert !@config.field_search.text_search
  end

  def test_link_defaults
    link = @config.field_search.link
    assert !link.page?
    assert !link.popup?
    assert !link.confirm?
    assert_equal "show_search", link.action
    assert_equal "Search", link.label
    assert link.inline?
    blank = {}
    assert_equal blank, link.html_options
    assert_equal :get, link.method
    assert_equal :collection, link.type
    assert_equal :read, link.crud_type
    assert_equal :search_authorized?, link.security_method
  end
  
  def test_setting_link
    @config.field_search.link = ActiveScaffold::DataStructures::ActionLink.new('update', :label => 'Monkeys')
    assert_not_equal(@default_link, @config.field_search.link)
  end
end
