# frozen_string_literal: true

require 'test_helper'

class ActionsMutationIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    [Address, Contact, Floor, Building, Person, Car, Category, Role].each(&:delete_all)
  end

  teardown do
    [Address, Contact, Floor, Building, Person, Car, Category, Role].each(&:delete_all)
    RequestStore.clear!
  end

  test 'update persists configured attributes and redirects to the list' do
    person = Person.create!(first_name: 'Before', last_name: 'Example')

    patch "/people/#{person.id}", params: {record: {first_name: 'After'}}

    assert_redirected_to '/people'
    assert_equal 'After', person.reload.first_name
    assert_equal 'Example', person.last_name
  end

  test 'update with dont_close persists and renders the edit form' do
    category = Category.create!(name: 'Before category')

    patch "/categories/#{category.id}", params: {dont_close: true, record: {name: 'After category'}}

    assert_response :success
    assert_equal 'After category', category.reload.name
    assert_select 'input[name=?][value=?]', 'record[name]', 'After category'
  end

  test 'invalid update renders errors without changing the record' do
    category = Category.create!(name: 'Valid category')

    patch "/categories/#{category.id}", params: {record: {name: 'x'}}

    assert_response :success
    assert_equal 'Valid category', category.reload.name
    assert_select '.errorExplanation, .active-scaffold-record-errors, .association-record-errors'
    assert_includes response.body, 'too short'
  end

  test 'xhr update replaces the list row after a successful save' do
    person = Person.create!(first_name: 'Before', last_name: 'Example')

    patch "/people/#{person.id}.js", params: {record: {first_name: 'After'}}, xhr: true

    assert_response :success
    assert_equal 'After', person.reload.first_name
    assert_includes response.body, 'action_link.close'
    assert_includes response.body, 'After'
  end

  test 'xhr update closes the form and refreshes a singular nested parent' do
    person = Person.create!(first_name: 'Alice')
    car = person.create_car!(brand: 'Ford', model: 'Focus')

    patch "/cars/#{car.id}.js", params: {
      parent_scaffold: 'people', association: 'car', person_id: person.id, eid: 'people',
      record: {model: 'Mondeo'}
    }, xhr: true

    assert_response :success
    assert_equal 'Mondeo', car.reload.model
    assert_includes response.body, 'action_link.close(true)'
    assert_not_includes response.body, 'ActiveScaffold.update_row'
  end

  test 'xhr update removes a row that no longer matches the list conditions' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    patch "/people/#{person.id}.js", params: {
      visible_first_name: 'Alice', record: {first_name: 'Bob'}
    }, xhr: true

    assert_response :success
    assert_equal 'Bob', person.reload.first_name
    assert_includes response.body, 'action_link.close()'
    assert_includes response.body, 'ActiveScaffold.delete_record_row'
    assert_includes response.body, "people-list-#{person.id}-row"
  end

  test 'xhr update replaces the form when validation fails' do
    category = Category.create!(name: 'Valid category')

    patch "/categories/#{category.id}.js", params: {record: {name: 'x'}}, xhr: true

    assert_response :success
    assert_equal 'Valid category', category.reload.name
    assert_includes response.body, 'ActiveScaffold.replace'
    assert_includes response.body, "categories-update-#{category.id}-form"
    assert_includes response.body, 'too short'
  end

  test 'xhr persistent update refreshes the row and keeps the form enabled' do
    person = Person.create!(first_name: 'Before', last_name: 'Example')

    patch "/people/#{person.id}.js", params: {
      dont_close: true,
      iframe: 'true',
      record: {first_name: 'After'}
    }, xhr: true

    assert_response :success
    assert_equal 'After', person.reload.first_name
    assert_includes response.body, 'ActiveScaffold.update_row'
    assert_includes response.body, 'action_link.target'
    assert_includes response.body, 'ActiveScaffold.enable_form'
  end

  test 'edit can show the nested actions header through request configuration' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get "/people/#{person.id}/edit", params: {nested_links: true}

    assert_response :success
    assert_select '.update-view > .active-scaffold-header .actions' do
      assert_select 'a.index', text: 'Back to list'
    end
  end

  test 'xhr update renders validation errors from a subform record' do
    building = Building.create!(name: 'Tower')

    patch "/buildings/#{building.id}.js", params: {
      record: {
        name: 'Tower',
        floors: {'new-floor' => {number: '', number_required: '1'}}
      }
    }, xhr: true

    assert_response :success
    assert_equal 0, building.reload.floors.count
    assert_includes response.body, 'association-record-errors'
    assert_includes response.body, 'Number can&#39;t be blank'
  end

  test 'positionless xhr action updates its row without opening a form' do
    person = Person.create!(first_name: 'Alice', adult: false)

    post "/people/#{person.id}/activate.js", xhr: true

    assert_response :success
    assert_predicate person.reload, :adult?
    assert_includes response.body, 'ActiveScaffold.update_row'
    assert_includes response.body, "people-list-#{person.id}-row"
    assert_not_includes response.body, 'ActiveScaffold.find_action_link'
  end

  test 'failed positionless xhr action renders list messages' do
    person = Person.create!(first_name: 'Alice', adult: false)

    post "/people/#{person.id}/activate.js", params: {force_action_failure: true}, xhr: true

    assert_response :success
    assert_not person.reload.adult?
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'The activation failed'
    assert_not_includes response.body, 'ActiveScaffold.enable_form'
  end

  test 'collection xhr action refreshes the list' do
    people = [
      Person.create!(first_name: 'Alice', adult: false),
      Person.create!(first_name: 'Bob', adult: false)
    ]

    post '/people/activate_all.js', xhr: true

    assert_response :success
    assert(people.all? { |person| person.reload.adult? })
    assert_includes response.body, 'if (link) link.close()'
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'as_people-content'
  end

  test 'destroy removes the record and redirects to the list' do
    person = Person.create!(first_name: 'Alice')

    assert_difference('Person.count', -1) do
      delete "/people/#{person.id}"
    end

    assert_redirected_to '/people'
  end

  test 'xhr destroy removes the record and its list row' do
    person = Person.create!(first_name: 'Alice')

    assert_difference('Person.count', -1) do
      delete "/people/#{person.id}.js", xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.delete_record_row'
    assert_includes response.body, "people-list-#{person.id}-row"
  end

  test 'xhr destroy can refresh the complete list' do
    category = Category.create!(name: 'Example')

    assert_difference('Category.count', -1) do
      delete "/categories/#{category.id}.js", xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'as_categories-content'
    assert_not_includes response.body, 'ActiveScaffold.delete_record_row'
  end

  test 'xhr nested destroy updates its nested scaffold' do
    person = Person.create!(first_name: 'Alice')
    contact = person.contacts.create!(first_name: 'Nested')

    assert_difference('Contact.count', -1) do
      delete "/contacts/#{contact.id}.js", params: {
        parent_scaffold: 'people', association: 'contacts', person_id: person.id
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.delete_record_row'
    assert_includes response.body, "as_people-#{person.id}-contacts-list-#{contact.id}-row"
  end

  test 'failed xhr destroy keeps the record and renders its errors' do
    person = Person.create!(first_name: 'Alice')

    assert_no_difference('Person.count') do
      delete "/people/#{person.id}.js", params: {force_destroy_failure: true}, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'The forced destroy failed'
    assert_not_includes response.body, 'ActiveScaffold.delete_record_row'
  end

  test 'xhr destroy of a singular nested record renders its parent row' do
    person = Person.create!(first_name: 'Alice')
    car = person.create_car!(brand: 'Ford', model: 'Focus')

    assert_difference('Car.count', -1) do
      delete "/cars/#{car.id}.js", params: {
        parent_scaffold: 'people', association: 'car', person_id: person.id, eid: 'people'
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.delete_record_row'
    assert_includes response.body, "as_people-list-#{car.id}-row"
    assert_includes response.body, '/people.js'
  end

  test 'json list returns serialized records' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people.json'

    assert_response :success
    records = response.parsed_body
    assert_equal person.id, records.first['id']
    assert_equal 'Alice', records.first['first_name']
  end

  test 'inline update runs through the update column endpoint' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    post "/cars/#{car.id}/update_column.js", params: {column: 'model', value: 'Mondeo'}, xhr: true

    assert_response :success
    assert_equal 'Mondeo', car.reload.model
  end

  test 'failed inline update restores the persisted value and renders its error' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    post "/cars/#{car.id}/update_column.js", params: {
      column: 'model', value: 'Mondeo', force_inplace_failure: true
    }, xhr: true

    assert_response :success
    assert_equal 'Focus', car.reload.model
    assert_includes response.body, 'cannot be changed'
    assert_includes response.body, 'ActiveScaffold.update_inplace_edit'
    assert_includes response.body, 'Focus'
  end

  test 'inline update can refresh its complete row through request configuration' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    post "/cars/#{car.id}/update_column.js", params: {
      column: 'model', value: 'Mondeo', inplace_edit_update: 'row'
    }, xhr: true

    assert_response :success
    assert_equal 'Mondeo', car.reload.model
    assert_includes response.body, 'ActiveScaffold.update_row'
    assert_includes response.body, 'Mondeo'
  end

  test 'inline update can refresh its complete table through request configuration' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    post "/cars/#{car.id}/update_column.js", params: {
      column: 'model', value: 'Mondeo', inplace_edit_update: 'table'
    }, xhr: true

    assert_response :success
    assert_equal 'Mondeo', car.reload.model
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'as_cars-content'
    assert_includes response.body, 'Mondeo'
  end

  test 'inline update can refresh dependent columns through request configuration' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    post "/cars/#{car.id}/update_column.js", params: {
      column: 'model', value: 'Mondeo', inplace_edit_update: 'columns'
    }, xhr: true

    assert_response :success
    assert_equal 'Mondeo', car.reload.model
    assert_includes response.body, '.brand-column'
    assert_includes response.body, 'Ford'
  end

  test 'inline update recursively refreshes chained dependent columns' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')
    car = person.create_car!(brand: 'Ford', model: 'Focus')

    post "/cars/#{car.id}/update_column.js", params: {
      column: 'model',
      value: 'Mondeo',
      inplace_edit_update: 'columns',
      chained_update_columns: true
    }, xhr: true

    assert_response :success
    assert_equal 'Mondeo', car.reload.model
    assert_includes response.body, '.brand-column'
    assert_includes response.body, '.person-column'
    assert_includes response.body, "/people/#{person.id}/edit"
  end

  test 'subform action renders an associated record through the dummy application' do
    person = Person.create!(first_name: 'Alice')

    get "/people/#{person.id}/edit_associated.js",
        params: {child_association: 'buildings', generated_id: 'new-building'},
        xhr: true

    assert_response :success
    assert_includes response.body, 'record[buildings]'
  end

  test 'subform action builds a new parent when the form has not been persisted' do
    get '/people/edit_associated.js',
        params: {child_association: 'buildings', generated_id: 'new-person'},
        xhr: true

    assert_response :success
    assert_includes response.body, 'record[buildings]'
  end

  test 'subform action loads an existing associated record' do
    person = Person.create!(first_name: 'Alice')
    building = Building.create!(name: 'Existing building')

    get "/people/#{person.id}/edit_associated.js",
        params: {child_association: 'buildings', associated_id: building.id},
        xhr: true

    assert_response :success
    assert_includes response.body, 'Existing building'
    assert_nil building.reload.owner_id
  end

  test 'new existing renders its form for an xhr request' do
    person = Person.create!(first_name: 'Alice')
    role = Role.create!(name: 'Editor')

    get '/people/new_existing.js', params: add_existing_params(role, person), xhr: true

    assert_response :success
    assert_includes response.body, "as_roles-#{role.id}-people-add_existing-#{person.id}-form"
    assert_includes response.body, 'associated_id'
    assert_includes response.body, 'Add existing Person'
    assert_includes response.body, 'data-remote="true"'
  end

  test 'html add existing associates the record and redirects' do
    person = Person.create!(first_name: 'Alice')
    role = Role.create!(name: 'Editor')

    post '/people/add_existing', params: add_existing_params(role, person)

    assert_response :redirect
    assert_equal '/people', URI.parse(response.location).path
    assert_equal [person], role.reload.people
  end

  test 'xhr add existing associates the record and updates the list' do
    person = Person.create!(first_name: 'Alice')
    role = Role.create!(name: 'Editor')

    post '/people/add_existing.js', params: add_existing_params(role, person), xhr: true

    assert_response :success
    assert_equal [person], role.reload.people
    assert_includes response.body, 'ActiveScaffold.create_record_row'
    assert_includes response.body, 'ActiveScaffold.reset_form'
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'Alice'
  end

  test 'xhr add existing reports an association that already exists' do
    person = Person.create!(first_name: 'Alice')
    role = Role.create!(name: 'Editor')
    role.people << person

    assert_no_difference('role.reload.people.count') do
      post '/people/add_existing.js', params: add_existing_params(role, person), xhr: true
    end

    assert_response :success
    assert_not_includes response.body, 'ActiveScaffold.create_record_row'
    assert_includes response.body, 'ActiveScaffold.reset_form'
    assert_includes response.body, 'already been added'
  end

  test 'html add existing failure renders the form and its errors' do
    person = Person.create!(first_name: 'Alice')
    role = Role.create!(name: 'Editor')
    params = add_existing_params(role, person).merge(force_add_existing_failure: true)

    post '/people/add_existing', params: params

    assert_response :success
    assert_empty role.reload.people
    assert_select "form#as_roles-#{role.id}-people-add_existing-#{person.id}-form"
    assert_select '.errorExplanation, .active-scaffold-record-errors, .association-record-errors',
                  text: /custom add existing action failed/
  end

  test 'xhr add existing failure replaces the form messages' do
    person = Person.create!(first_name: 'Alice')
    role = Role.create!(name: 'Editor')
    params = add_existing_params(role, person).merge(force_add_existing_failure: true)

    post '/people/add_existing.js', params: params, xhr: true

    assert_response :success
    assert_empty role.reload.people
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, "as_roles-#{role.id}-people-add_existing-#{person.id}-messages"
    assert_includes response.body, 'custom add existing action failed'
  end

  test 'mark action persists marked state in the session' do
    address = Address.create!(street: 'Main Street', city: 'Madrid')

    post "/addresses/#{address.id}/mark.js", params: {value: 'true'}, xhr: true
    assert_response :success

    get '/addresses'
    assert_response :success
    assert_select 'input[name=?][checked]', 'record[as_marked]', count: 1

    post "/addresses/#{address.id}/mark.js", params: {value: 'false'}, xhr: true
    assert_response :success

    get '/addresses'
    assert_response :success
    assert_select 'input[name=?][checked]', 'record[as_marked]', count: 0
  end

  private

  def add_existing_params(role, person)
    {
      parent_scaffold: 'roles',
      association: 'people',
      role_id: role.id,
      associated_id: person.id
    }
  end
end
