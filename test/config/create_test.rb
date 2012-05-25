require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::CreateTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
    @default_link = @config.create.link
  end
  
  def teardown
    @config.create.link = @default_link
  end
  
  def test_default_options
    assert !@config.create.persistent
    assert @config.create.action_after_create.nil?
    assert_equal 'Create ModelStub', @config.create.label
  end

  def test_link_defaults
    link = @config.create.link
    assert !link.page?
    assert !link.popup?
    assert !link.confirm?
    assert_equal "new", link.action
    assert_equal "Create New", link.label
    assert link.inline?
    blank = {}
    assert_equal blank, link.html_options
    assert_equal :get, link.method
    assert_equal :collection, link.type
    assert_equal :create, link.crud_type
    assert_equal :create_authorized?, link.security_method
  end
  
  def test_setting_link
    @config.create.link = ActiveScaffold::DataStructures::ActionLink.new('update', :label => 'Monkeys')
    assert_not_equal(@default_link, @config.create.link)
  end
  
  def test_label
    label = 'create new monkeys'
    @config.create.label = label
    assert_equal label, @config.create.label
    I18n.backend.store_translations :en, :active_scaffold => {:create_new_model => 'Create new %{model}'}
    @config.create.label = :create_new_model
    assert_equal 'Create new ModelStub', @config.create.label
  end
  
  def test_persistent
    @config.create.persistent = true
    assert @config.create.persistent
  end
 
  def test_action_after_create
    @config.create.action_after_create = :edit
    assert_equal :edit, @config.create.action_after_create
  end
end
