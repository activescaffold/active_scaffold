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
    assert model.save

    model.buildings.create(:name => '1st building')
    model = update_record_from_params(model, :update, :first_name, :last_name, :first_name => 'Name', :last_name => 'Last')
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.buildings.present?, 'buildings should not be cleared'
    assert model.save
  end

  def test_saving_unexpected_column_is_ignored
    model = Person.new(:first_name => 'First', :last_name => 'Last')
    model.buildings.build(:name => '1st building')
    assert model.save

    model = update_record_from_params(model, :update, :first_name, :first_name => 'Name', :last_name => 'Surname')
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.buildings.present?, 'buildings should not be cleared'
    assert model.save
  end

  def test_saving_multiparameter_attribute
    model = update_record_from_params(Contact.new, :update, :first_name, :birthday, :first_name => 'Christopher', :last_name => 'Columbus', 'birthday(1i)' => '1451', 'birthday(2i)' => '10', 'birthday(3i)' => '31')
    assert_equal 'Christopher', model.first_name
    assert_equal Date.new(1451, 10, 31), model.birthday
  end

  def test_saving_has_many_select
    buildings = 2.times.map { Building.create }
    model = update_record_from_params(Person.new, :create, :first_name, :last_name, :buildings, :first_name => 'First', :last_name => '', :buildings => ['', *buildings.map{|b| b.id.to_s}]) # checkbox_list always add a hidden tag with empty value
    assert_equal 'First', model.first_name
    assert_nil model.last_name
    assert_equal buildings.map(&:id), model.building_ids
    assert_equal buildings, model.buildings
    assert model.save

    model = update_record_from_params(model, :update, :first_name, :last_name, :buildings, :first_name => 'Name', :last_name => 'Last', :buildings => ['']) { raise ActiveRecord::Rollback }
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert_equal [model.id]*2, buildings.map{|b| b.reload.owner_id}, 'owners should not be saved'
    assert model.building_ids.blank?, 'buildings should be cleared'
    assert model.buildings.blank?, 'buildings should be cleared'

    model.reload
    model = update_record_from_params(model, :update, :first_name, :last_name, :buildings, :first_name => 'Name', :last_name => 'Last', :buildings => [''])
    assert_equal 'Name', model.first_name
    assert_equal 'Last', model.last_name
    assert model.building_ids.blank?, 'buildings should be cleared'
    assert model.buildings.blank?, 'buildings should be cleared'
    assert_equal [nil]*2, buildings.map{|b| b.reload.owner_id}, 'buildings should be saved'
    assert model.save
  end

  def test_saving_belongs_to_select
    person = Person.create
    assert person.persisted?

    model = update_record_from_params(Floor.new, :create, :number, :tenant, :number => '1', :tenant => person.id.to_s)
    assert_equal 1, model.number
    assert_equal person.id, model.tenant_id
    assert_equal person, model.tenant
    assert model.save

    model = update_record_from_params(model, :update, :number, :tenant, :number => '1', :tenant => '')
    assert_equal 1, model.number
    assert_nil model.tenant_id, 'tenant should be cleared'
    assert_nil model.tenant, 'tenant should be cleared'
    assert_equal person.id, Floor.find(model).tenant_id, 'floor should not be saved yet'
    assert model.save
    assert_nil Floor.find(model).tenant_id, 'floor should not be saved'
  end

  def test_saving_has_one_select
    floor = Floor.create
    assert floor.persisted?

    model = update_record_from_params(Person.new, :create, :first_name, :floor, :first_name => 'Name', :floor => floor.id.to_s)
    assert_equal 'Name', model.first_name
    assert model.floor.present?
    assert_equal floor.id, model.floor.id
    assert_nil floor.reload.tenant_id, 'tenant_id should not be saved yet'
    assert model.save
    assert_equal model.id, floor.reload.tenant_id, 'tenant_id should be saved'

    model = update_record_from_params(model, :update, :first_name, :floor, :first_name => 'First', :floor => '', :skip => Floor) { raise ActiveRecord::Rollback }
    assert_equal 'First', model.first_name
    assert_equal model.id, floor.reload.tenant_id, 'previous car should not be saved and nullified'
    assert_nil model.floor, 'floor should be cleared'

    model.reload
    model = update_record_from_params(model, :update, :first_name, :floor, :first_name => 'First', :floor => '', :skip => Floor)
    assert_equal 'First', model.first_name
    assert_nil floor.reload.tenant_id, 'previous car should be saved and nullified'
    assert_nil model.floor, 'floor should be cleared'
    assert model.save
  end

  def test_saving_has_one_through_select
    building = Building.create
    assert building.persisted?
    assert building.floors.create(:number => 2)

    model = update_record_from_params(Person.new, :create, :first_name, :home, :first_name => 'Name', :home => building.id.to_s)
    assert_equal 'Name', model.first_name
    assert model.home.present?
    assert model.floor.present?
    assert_equal [nil], building.floors(true).map(&:tenant_id), 'floor should not be saved yet'
    assert model.save
    assert_equal model.id, model.floor.tenant_id, 'tenant_id should be saved'
    assert_equal [nil, model.id], building.floors(true).map(&:tenant_id)

    model = update_record_from_params(model, :update, :first_name, :home, :first_name => 'First', :home => '') { raise ActiveRecord::Rollback }
    assert_equal 'First', model.first_name
    assert_equal [nil, model.id], building.floors(true).map(&:tenant_id), 'previous floor should not be deleted'
    assert_nil model.home, 'home should be cleared'

    model.reload
    model = update_record_from_params(model, :update, :first_name, :home, :first_name => 'First', :home => '')
    assert_equal 'First', model.first_name
    assert_equal [nil], building.floors(true).map(&:tenant_id), 'previous floor should be deleted'
    assert_nil model.home, 'home should be cleared'
    assert model.save
  end

  def test_saving_has_many_through_select
    people = 2.times.map { Person.create }
    assert people.all?(&:persisted?)

    model = update_record_from_params(Building.new, :create, :name, :tenants, :name => 'Tower', :tenants => ['', *people.map{|b| b.id.to_s}]) # checkbox_list always add a hidden tag with empty value
    assert_equal 'Tower', model.name
    assert model.tenants.present?
    assert_equal [nil]*2, people.map {|p| p.floor(true)}, 'floor should not be saved yet'
    assert model.save
    assert_equal [model.id]*2, model.floors.map(&:building_id)
    assert_equal [model.id]*2, people.map {|p| p.floor(true).building_id}, 'floor should be saved'

    model = update_record_from_params(model, :update, :name, :tenants, :name => 'Skyscrapper', :tenants => ['']) { raise ActiveRecord::Rollback }
    assert_equal 'Skyscrapper', model.name
    assert_equal [model.id]*2, people.map {|p| p.floor(true).building_id}, 'previous floor should not be deleted'
    assert model.tenants.empty?, 'tenants should be cleared'

    model.reload
    model = update_record_from_params(model, :update, :name, :tenants, :name => 'Skyscrapper', :tenants => [''])
    assert_equal 'Skyscrapper', model.name
    assert_equal [nil]*2, people.map {|p| p.floor(true)}, 'previous floor should be deleted'
    assert model.tenants.empty?, 'tenants should be cleared'
    assert model.save
  end

  def test_saving_has_many_crud_with_error
    building = Building.create(:name => 'First')
    key = Time.now.to_i.to_s
    floors = {'0' => '', key => {:number => '', 'tenant' => '', :number_required => true}}
    model = update_record_from_params(building, :create, :name, :floors, :name => 'First', :floors => floors)
    assert_equal 'First', model.name
    assert_equal 1, model.floors.size
    assert model.floors.first.errors.present?
    assert !model.floors.first.persisted?
  end

  def test_saving_has_many_crud_and_belongs_to_select
    floor = Floor.create
    people = 2.times.map { Person.create }
    key = Time.now.to_i.to_s
    floors = {'0' => '', '1' => {:number => '1', :tenant => '', :id => floor.id.to_s}, key => {:number => '2', 'tenant' => people.first.id.to_s}, key.succ => {:number => '4', 'tenant' => people.last.id.to_s}}
    model = update_record_from_params(Building.new, :create, :name, :floors, :name => 'First', :floors => floors)
    assert_equal 'First', model.name
    assert_equal 3, model.floors.size
    assert_equal floor.id, model.floors.first.id
    assert_equal [nil, *people.map(&:id)], model.floors.map(&:tenant_id)
    assert model.save

    model = update_record_from_params(model, :update, :name, :floors, :name => 'Tower', :floors => {'0' => ''})
    assert_equal 'Tower', model.name
    assert model.floors.blank?, 'floors should be cleared'
    assert model.save
  end

  def test_saving_belongs_to_crud
    person = Person.create
    assert person.persisted?

    model = update_record_from_params(Car.new, :create, :brand, :person, :brand => 'Ford', :person => {:first_name => 'First'})
    assert_equal 'Ford', model.brand
    assert model.person.present?
    assert model.person.new_record?
    assert model.save
    assert model.person.persisted?

    model = update_record_from_params(model, :update, :brand, :person, :brand => 'Ford', :person => {:first_name => 'First', :id => person.id.to_s})
    assert_equal 'Ford', model.brand
    assert model.person.present?
    assert_equal person.id, model.person.id
    assert model.save

    model = update_record_from_params(model, :update, :brand, :person, :brand => 'Mercedes', :person => {:first_name => ''})
    assert_equal 'Mercedes', model.brand
    assert model.person.blank?, 'person should be cleared'
    assert model.save
  end

  def test_saving_has_one_crud
    car = Car.create :brand => 'Renault'
    assert car.persisted?

    model = update_record_from_params(Person.new, :create, :first_name, :car, :first_name => 'First', :car => {:brand => 'Ford'})
    assert_equal 'First', model.first_name
    assert model.car.present?
    assert model.car.new_record?
    assert model.save
    assert model.car.persisted?

    model = update_record_from_params(Person.new, :create, :first_name, :car, :first_name => 'First', :car => {:brand => 'Peugeot', :id => car.id.to_s})
    assert_equal 'First', model.first_name
    assert model.car.present?
    assert_equal car.id, model.car.id
    assert_nil car.reload.person_id, 'person_id should not be saved yet'
    assert_equal 'Peugeot', model.car.brand
    assert_equal 'Renault', car.reload.brand, 'brand should not be saved yet'
    assert model.save
    assert_equal model.id, car.reload.person_id, 'person_id should be saved'

    model = update_record_from_params(model, :update, :first_name, :car, :first_name => 'First', :car => {:brand => 'Mercedes', :id => car.id.to_s})
    assert_equal 'First', model.first_name
    assert model.car.present?
    assert_equal 'Mercedes', model.car.brand
    assert model.save
    assert model.save_associated
    assert_equal 'Mercedes', car.reload.brand, 'brand should be saved'

    model = update_record_from_params(model, :update, :first_name, :car, :first_name => 'First', :car => {:brand => 'Mercedes'}, :skip => Car)
    assert_equal 'First', model.first_name
    assert_nil Car.where(:id => car.id).first, 'previous car should be deleted'
    assert model.car.present?
    assert_not_equal car.id, model.car.id
    assert model.save

    car = model.car.reload
    model = update_record_from_params(model, :update, :first_name, :car, :first_name => 'Name', :car => {:brand => ''}, :skip => Car)
    assert_equal 'Name', model.first_name
    assert_nil Car.where(:id => car.id).first, 'previous car should be deleted'
    assert model.car.blank?, 'car should be cleared'
    assert model.save
  end

  def test_saving_belongs_to_polymorphic_select
    person = Person.create
    assert person.persisted?

    model = update_record_from_params(Contact.new, :create, :first_name, :contactable_type, :contactable, :first_name => 'First', :contactable_type => person.class.name, :contactable => person.id.to_s)
    assert_equal 'First', model.first_name
    assert_equal person.class.name, model.contactable_type
    assert_equal person.id, model.contactable_id
    assert_equal person, model.contactable
    assert model.save

    model = update_record_from_params(model, :update, :first_name, :contactable_type, :contactable, :first_name => 'Name', :contactable_type => person.class.name, :contactable => '')
    assert_equal 'Name', model.first_name
    assert_nil model.contactable_type
    assert_nil model.contactable_id, 'contactable should be cleared'
    assert_nil model.contactable, 'contactable should be cleared'
    assert_equal person.id, Contact.find(model).contactable_id, 'contact should not be saved yet'
    assert model.save
    assert_nil Contact.find(model).contactable_id, 'contact should be saved'
  end

  protected
  MODELS = [Address, Building, Car, Contact, Floor, Person]
  def update_record_from_params(record, action, *columns, &block)
    params = columns.extract_options!.with_indifferent_access
    skip = params.delete(:skip)
    #(MODELS-Array(skip)).each { |model| model.any_instance.expects(:save).never }
    new_record = nil
    record.class.transaction do
      new_record = @controller.update_record_from_params(record, build_action_columns(record, action, columns), params)
      MODELS.each { |model| model.any_instance.unstub(:save) }
      yield if block_given?
      Thread.current[:constraint_columns] = nil
    end
    new_record
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
