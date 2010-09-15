require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::DeleteTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
    @default_link = @config.delete.link
  end
  
  def teardown
    @config.delete.link = @default_link
  end

  def test_link_defaults
    link = @config.delete.link
    assert !link.page?
    assert !link.popup?
    assert link.confirm?
    assert_equal "delete", link.action
    assert_equal "Delete", link.label
    assert link.inline?
    blank = {}
    assert_equal blank, link.html_options
    assert_equal :delete, link.method
    assert_equal :member, link.type
    assert_equal :delete, link.crud_type
    assert_equal :delete_authorized?, link.security_method
  end
  
  def test_setting_link
    @config.delete.link = ActiveScaffold::DataStructures::ActionLink.new('update', :label => 'Monkeys')
    assert_not_equal(@default_link, @config.delete.link)
  end
end
