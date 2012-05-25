require File.join(File.dirname(__FILE__), '../test_helper.rb')

class Config::UpdateTest < Test::Unit::TestCase
  def setup
    @config = ActiveScaffold::Config::Core.new :model_stub
  end
  
  def test__params_for_columns__returns_all_params
    @config._load_action_columns
    @config.columns[:a].params.add :keep_a, :a_temp
    assert @config.columns[:a].params.include?(:keep_a)
    assert @config.columns[:a].params.include?(:a_temp)
  end
  
  def test_default_options
    assert !@config.update.persistent
    assert !@config.update.nested_links
    assert_equal 'Update ModelStub', @config.update.label
  end
  
  def test_persistent
    @config.update.persistent = true
    assert @config.update.persistent
  end
  
  def test_nested_links
    @config.update.nested_links = true
    assert @config.update.nested_links
  end
  
  def test_label
    label = 'update new monkeys'
    @config.update.label = label
    assert_equal label, @config.update.label
    I18n.backend.store_translations :en, :active_scaffold => {:change_model => 'Change %{model}'}
    @config.update.label = :change_model
    assert_equal 'Change ModelStub', @config.update.label
    assert_equal 'Change record', @config.update.label('record')
  end
end