require 'test_helper'

class AttributeParamsTest < Test::Unit::TestCase
  def setup
    @controller = Controller.new
  end

  def test_saving_simple_record
    model = update_record_from_params(Person.new, :create, :first_name, :last_name, :first_name => 'First', :last_name => '')
    assert_equal 'First', model.first_name
    assert_nil model.last_name
    assert model.buildings.blank?

    model.buildings.build(:name => '1st building')
    model = update_record_from_params(model, :create, :first_name, :last_name, :first_name => 'Name', :last_name => 'Last')
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.buildings.present?, 'buildings should not be cleared'
  end

  def test_saving_has_many_record
    Building.expects(:find).with('1').returns(Building.new)
    buildings = {'0' => '', '1' => {:name => '1st building', :id => '1'}, '11111' => {:name => '2nd'}}
    model = update_record_from_params(Person.new, :create, :first_name, :last_name, :buildings, :first_name => 'First', :last_name => '', :buildings => buildings)
    assert_equal 'First', model.first_name
    assert_nil model.last_name
    assert model.buildings.present?

    model = update_record_from_params(model, :create, :first_name, :last_name, :first_name => 'Name', :last_name => 'Last', :buildings => {'0' => ''})
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.buildings.blank?, 'buildings should be cleared'
  end

  protected
  def update_record_from_params(record, action, *columns)
    params = columns.extract_options!.with_indifferent_access
    @controller.update_record_from_params(record, build_action_columns(record, action, columns), params)
  end

  def build_action_columns(record, action, *columns)
    controller = ActiveScaffold::Core.active_scaffold_controller_for record.class
    controller.active_scaffold_config.send(action).columns = columns
    controller.active_scaffold_config.send(action).columns
  end
end

class Controller
  def self.helper_method(*args); end
  def self.before_filter(*args); end
  
  include ActiveScaffold::Core
  include ActiveScaffold::Helpers::ControllerHelpers
  include ActiveScaffold::AttributeParams
  public :update_record_from_params

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
