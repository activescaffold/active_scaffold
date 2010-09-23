require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::NestedTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end
  
  def test_default_options
    assert !@config.nested.shallow_delete
    assert_equal 'Add Existing ModelStub', @config.nested.label
  end
  
  def test_label
    label = 'nested monkeys'
    @config.nested.label = label
    assert_equal label, @config.nested.label
    I18n.backend.store_translations :en, :active_scaffold => {:create_model => 'Add new %{model}'}
    @config.nested.label = :create_model
    assert_equal 'Add new ModelStub', @config.nested.label
  end
  
  def test_shallow_delete
    @config.nested.shallow_delete = true
    assert @config.nested.shallow_delete
  end
  
  def test_add_link_deprecation
    ActiveSupport::Deprecation.silence { @config.nested.add_link :custom_link, [:assoc_1, :assoc_2] }
    link = @config.action_links['nested']
    assert_equal 'Custom Link', link.label
    assert_equal 'nested', link.action
    assert_equal :after, link.position
    assert !link.page?
    assert !link.popup?
    assert !link.confirm?
    assert link.inline?
    assert_equal :assoc_1, link.parameters[:associations]
    assert_equal 'assoc_1', link.html_options[:class]
    assert_equal :get, link.method
    assert_equal :member, link.type
    assert_equal :read, link.crud_type
    assert_equal :nested_authorized?, link.security_method
  end

  def test_add_link
    @config.nested.add_link :custom_link, :assoc_1
    link = @config.action_links['nested']
    assert_equal 'Custom Link', link.label
    assert_equal 'nested', link.action
    assert_equal :after, link.position
    assert !link.page?
    assert !link.popup?
    assert !link.confirm?
    assert link.inline?
    assert_equal :assoc_1, link.parameters[:associations]
    assert_equal 'assoc_1', link.html_options[:class]
    assert_equal :get, link.method
    assert_equal :member, link.type
    assert_equal :read, link.crud_type
    assert_equal :nested_authorized?, link.security_method
  end
end
