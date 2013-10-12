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
    model = update_record_from_params(model, :update, :first_name, :last_name, :first_name => 'Name', :last_name => 'Last')
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.buildings.present?, 'buildings should not be cleared'
  end

  def test_saving_unexpected_column_is_ignored
    model = Person.new(:first_name => 'First', :last_name => 'Last')
    model.buildings.build(:name => '1st building')
    model = update_record_from_params(model, :update, :first_name, :first_name => 'Name', :last_name => 'Surname')
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.buildings.present?, 'buildings should not be cleared'
  end

  def test_saving_has_many_select
    Building.expects(:find).with(['1', '3']).returns([Building.new{|r| r.id = 1}, Building.new{|r| r.id = 3}])
    model = update_record_from_params(Person.new, :create, :first_name, :last_name, :buildings, :first_name => 'First', :last_name => '', :buildings => ['', '1', '3']) # checkbox_list always add a hidden tag with empty value
    assert_equal 'First', model.first_name
    assert_nil model.last_name
    assert_equal [1, 3], model.building_ids
    assert_equal 2, model.buildings.size

    model = update_record_from_params(model, :update, :first_name, :last_name, :buildings, :first_name => 'Name', :last_name => 'Last', :buildings => [''])
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.building_ids.blank?, 'buildings should be cleared'
    assert model.buildings.blank?, 'buildings should be cleared'
  end

  def test_saving_belongs_to_select
    Person.expects(:find).with('3').returns(Person.new{|r| r.id = 3})
    model = update_record_from_params(Floor.new, :create, :number, :tenant, :number => '1', :tenant => '3')
    assert_equal 1, model.number
    assert_equal 3, model.tenant_id
    assert model.tenant.present?

    model = update_record_from_params(model, :update, :number, :tenant, :number => '1', :tenant => '')
    assert_equal 1, model.number
    assert_nil model.tenant_id, 'tenant should be cleared'
    assert_nil model.tenant, 'tenant should be cleared'
  end

  def test_saving_has_one_select
    Floor.expects(:find).with('12').returns(Floor.new{|r| r.id = 12})
    model = update_record_from_params(Person.new, :create, :first_name, :floor, :first_name => 'Name', :floor => '12')
    assert_equal 'Name', model.first_name
    assert model.floor.present?
    assert_equal 12, model.floor.id

    model = update_record_from_params(model, :update, :first_name, :floor, :first_name => 'First', :floor => '')
    assert_equal 'First', model.first_name
    assert_nil model.floor, 'floor should be cleared'
  end

  def test_saving_has_many_crud_and_belongs_to_select
    Floor.expects(:find).with('12').returns(Floor.new{|r| r.id = 12})
    Person.expects(:find).with('3').returns(Person.new{|r| r.id = 3})
    Person.expects(:find).with('4').returns(Person.new{|r| r.id = 4})
    key = Time.now.to_i.to_s
    floors = {'0' => '', '1' => {:number => '1', :tenant => '', :id => '12'}, key => {:number => '2', 'tenant' => '3'}, key.succ => {:number => '4', 'tenant' => '4'}}
    model = update_record_from_params(Building.new, :create, :name, :floors, :name => 'First', :floors => floors)
    assert_equal 'First', model.name
    assert_equal 3, model.floors.size
    assert_equal [nil, 3, 4], model.floors.map(&:tenant_id)

    model = update_record_from_params(model, :update, :name, :floors, :name => 'Tower', :floors => {'0' => ''})
    assert_equal 'Tower', model.name
    assert model.floors.blank?, 'floors should be cleared'
  end

  def test_saving_belongs_to_crud
    Person.expects(:find).with('3').returns(Person.new{|r| r.id = 3})

    model = update_record_from_params(Car.new, :create, :brand, :person, :brand => 'Ford', :person => {:first_name => 'First'})
    assert_equal 'Ford', model.brand
    assert model.person.present?
    assert model.person.new_record?

    model = update_record_from_params(model, :update, :brand, :person, :brand => 'Ford', :person => {:first_name => 'First', :id => '3'})
    assert_equal 'Ford', model.brand
    assert model.person.present?
    assert_equal 3, model.person.id

    model = update_record_from_params(model, :update, :brand, :person, :brand => 'Mercedes', :person => {:first_name => ''})
    assert_equal 'Mercedes', model.brand
    assert model.person.blank?, 'person should be cleared'
  end

  def test_saving_has_one_crud
    Car.expects(:find).with('12').returns(Car.new{|r| r.id = 12})

    model = update_record_from_params(Person.new, :create, :first_name, :car, :first_name => 'First', :car => {:brand => 'Ford'})
    assert_equal 'First', model.first_name
    assert model.car.present?
    assert model.car.new_record?

    model = update_record_from_params(model, :update, :first_name, :car, :first_name => 'First', :car => {:brand => 'Mercedes', :id => '12'})
    assert_equal 'First', model.first_name
    assert model.car.present?
    assert_equal 12, model.car.id

    model = update_record_from_params(model, :update, :first_name, :car, :first_name => 'Name', :car => {:brand => ''})
    assert_equal 'Name', model.first_name
    assert model.car.blank?, 'car should be cleared'
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
