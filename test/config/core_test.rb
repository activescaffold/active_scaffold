require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::CoreTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end
  
  def test_default_options
    assert !@config.add_sti_create_links?
    assert !@config.sti_children
    assert_equal [:create, :list, :search, :update, :delete, :show, :nested, :subform], @config.actions.to_a
    assert_equal :default, @config.frontend
    assert_equal :default, @config.theme
    assert_equal 'ModelStub', @config.label(:count => 1)
    assert_equal 'ModelStubs', @config.label
  end
  
  def test_add_sti_children
    @config.sti_create_links = true
    assert !@config.add_sti_create_links?
    @config.sti_children = [:a]
    assert @config.add_sti_create_links?
  end
  
  def test_sti_children
    @config.sti_children = [:a]
    assert_equal [:a], @config.sti_children
  end
  
  def test_actions
    assert @config.actions.include?(:create)
    @config.actions = [:list]
    assert !@config.actions.include?(:create)
    assert_equal [:list], @config.actions.to_a
  end
  
  def test_form_ui_in_sti
    @config.columns << :type
    
    @config.sti_children = [:model_stub]
    @config._configure_sti
    assert_equal :select, @config.columns[:type].form_ui
    assert_equal [['Modelstub', 'ModelStub']], @config.columns[:type].options[:options]
    
    @config.columns[:type].form_ui = nil
    @config.sti_create_links = true
    @config._configure_sti
    assert_equal :hidden, @config.columns[:type].form_ui
  end
  
  def test_sti_children_links
    @config.sti_children = [:model_stub]
    @config.sti_create_links = true
    @config.action_links.add @config.create.link
    @config._add_sti_create_links
    assert_equal 'Create Modelstub', @config.action_links[:new].label
  end
end
