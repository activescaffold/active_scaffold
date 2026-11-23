# frozen_string_literal: true

require 'test_helper'

class AssociatedRecordAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(first_name: 'Visible person')
    @car = Car.create!(brand: 'Private brand', model: 'Private model')
    @role = Role.create!(name: 'Test role')
  end

  test 'edit_associated rejects records without read authorization' do
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with({crud_type: :read}).returns(false)

    get "/people/#{@person.id}/edit_associated.js", params: {child_association: 'car', associated_id: @car.id}, xhr: true

    assert_response :forbidden
    assert_not_includes response.body, 'Private model'
    assert_nil @car.reload.person_id
  end

  test 'edit_associated checks read authorization with a new parent' do
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with({crud_type: :read}).returns(false)

    get '/people/edit_associated.js', params: {child_association: 'car', associated_id: @car.id}, xhr: true

    assert_response :forbidden
    assert_not_includes response.body, 'Private model'
    assert_nil @car.reload.person_id
  end

  test 'edit_associated still renders readable existing records' do
    get "/people/#{@person.id}/edit_associated.js", params: {child_association: 'car', associated_id: @car.id}, xhr: true

    assert_response :success
    assert_includes response.body, 'Private model'
    assert_nil @car.reload.person_id
  end

  test 'edit_associated uses the overridable scope with the associated class and parent column' do
    PeopleController.any_instance.expects(:associated_record_scope).with do |klass, options|
      klass == Car && options[:column].name == :car
    end.returns(Car.where(id: []))

    get "/people/#{@person.id}/edit_associated.json", params: {child_association: 'car', associated_id: @car.id}

    assert_response :not_found
    assert_nil @car.reload.person_id
  end

  test 'edit_associated preserves parent update authorization' do
    Person.any_instance.stubs(:authorized_for?).returns(false)

    get "/people/#{@person.id}/edit_associated.js", params: {child_association: 'car', associated_id: @car.id}, xhr: true

    assert_response :forbidden
    assert_nil @car.reload.person_id
  end

  test 'add_existing rejects records without read authorization before attaching them' do
    Person.any_instance.stubs(:authorized_for?).returns(true)
    Person.any_instance.stubs(:authorized_for?).with({crud_type: :read}).returns(false)

    post '/people/add_existing.json', params: add_existing_params

    assert_response :forbidden
    assert_not_includes response.body, 'Visible person'
    assert_empty @role.people.reload
  end

  test 'add_existing can attach readable records outside the current nested collection' do
    assert_empty @role.people

    post '/people/add_existing.json', params: add_existing_params

    assert_response :success
    assert_equal [@person.id], @role.people.reload.ids
  end

  test 'add_existing uses the overridable scope with the candidate class and parent column' do
    PeopleController.any_instance.expects(:associated_record_scope).with do |klass, options|
      klass == Person && options[:column].name == :people && options[:column].association.klass == Person
    end.returns(Person.where(id: []))

    post '/people/add_existing.json', params: add_existing_params

    assert_response :not_found
    assert_empty @role.people.reload
  end

  test 'add_existing still checks read authorization when the scope includes the record' do
    PeopleController.any_instance.stubs(:associated_record_scope).returns(Person.where(id: @person.id))
    Person.any_instance.stubs(:authorized_for?).returns(true)
    Person.any_instance.stubs(:authorized_for?).with({crud_type: :read}).returns(false)

    post '/people/add_existing.json', params: add_existing_params

    assert_response :forbidden
    assert_empty @role.people.reload
  end

  test 'add_existing preserves parent update authorization' do
    Role.any_instance.stubs(:authorized_for?).returns(false)

    post '/people/add_existing.json', params: add_existing_params

    assert_response :forbidden
    assert_empty @role.people.reload
  end

  private

  def add_existing_params
    {parent_scaffold: 'roles', association: 'people', role_id: @role.id, associated_id: @person.id}
  end
end
