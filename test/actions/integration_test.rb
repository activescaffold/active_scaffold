# frozen_string_literal: true

require 'test_helper'

class ActionsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    [Address, Contact, Building, Person, Car, Category].each(&:delete_all)
  end

  teardown do
    [Address, Contact, Building, Person, Car, Category].each(&:delete_all)
    RequestStore.clear!
  end

  test 'list renders records through the dummy application' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people'

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_includes response.body, 'Bob'
  end

  test 'search filters the list through the controller callback chain' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people', params: {search: 'Alice'}

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_not_includes response.body, 'Bob'
  end

  test 'list always shows search and links to field search with its kind' do
    get '/contacts'

    assert_response :success
    assert_select 'form.as_form.search input[type=?][name=?]', 'search', 'search'
    field_search_link = css_select('a').find do |link|
      link['href']&.include?('/contacts/show_search') && link['href'].include?('kind=field_search')
    end
    assert field_search_link, 'expected a field search action link with kind=field_search'
  end

  test 'field search action renders configured fields and filters the list' do
    Contact.create!(first_name: 'Alice', last_name: 'Example')
    Contact.create!(first_name: 'Bob', last_name: 'Example')

    get '/contacts/show_search.js', params: {kind: 'field_search'}, xhr: true

    assert_response :success
    assert_select 'form.as_form.search' do
      assert_select '[name^=?]', 'search[first_name]'
      assert_select '[name^=?]', 'search[last_name]'
      assert_select '[name^=?]', 'search[birthday]'
    end

    get '/contacts', params: {search: {first_name: {opt: '%?%', from: 'Alice'}}}

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_not_includes response.body, 'Bob'
  end

  test 'field search applies configured default params through the request callback' do
    Contact.create!(first_name: 'Alice', last_name: 'Example')
    Contact.create!(first_name: 'Bob', last_name: 'Example')

    get '/contacts', params: {apply_default_search: true}

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_not_includes response.body, 'Bob'
  end

  test 'nested list only renders records belonging to its parent' do
    person = Person.create!(first_name: 'Alice')
    person.contacts.create!(first_name: 'Nested')
    Contact.create!(first_name: 'Unrelated')

    get '/contacts', params: {
      parent_scaffold: 'people', association: 'contacts', person_id: person.id
    }

    assert_response :success
    assert_includes response.body, 'Nested'
    assert_not_includes response.body, 'Unrelated'
  end

  test 'nested create associates the new record with its parent' do
    person = Person.create!(first_name: 'Alice')

    assert_difference('Contact.count') do
      post '/contacts', params: {
        parent_scaffold: 'people', association: 'contacts', person_id: person.id,
        record: {first_name: 'Nested'}
      }
    end

    assert_equal person, Contact.order(:id).last.contactable
  end

  test 'show renders the requested record' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get "/people/#{person.id}"

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_includes response.body, 'Example'
  end

  test 'new and edit render forms for configured columns' do
    category = Category.create!(name: 'Example')

    get '/categories/new'
    assert_response :success
    assert_select 'input[name=?]', 'record[name]'

    get "/categories/#{category.id}/edit"
    assert_response :success
    assert_select 'input[name=?][value=?]', 'record[name]', 'Example'
  end

  test 'create persists configured attributes and redirects to the list' do
    assert_difference('Person.count') do
      post '/people', params: {record: {first_name: 'Alice', last_name: 'Example'}}
    end

    assert_redirected_to '/people'
    assert_equal %w[Alice Example], Person.order(:id).last.attributes.values_at('first_name', 'last_name')
  end

  test 'create renders validation errors without persisting the record' do
    assert_no_difference('Category.count') do
      post '/categories', params: {record: {name: 'x'}}
    end

    assert_response :success
    assert_select '.errorExplanation, .active-scaffold-record-errors, .association-record-errors'
    assert_includes response.body, 'too short'
  end

  test 'update persists configured attributes and redirects to the list' do
    person = Person.create!(first_name: 'Before', last_name: 'Example')

    patch "/people/#{person.id}", params: {record: {first_name: 'After'}}

    assert_redirected_to '/people'
    assert_equal 'After', person.reload.first_name
    assert_equal 'Example', person.last_name
  end

  test 'destroy removes the record and redirects to the list' do
    person = Person.create!(first_name: 'Alice')

    assert_difference('Person.count', -1) do
      delete "/people/#{person.id}"
    end

    assert_redirected_to '/people'
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

  test 'render field supports inplace editing requests' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    get "/cars/#{car.id}/render_field.js", params: {update_column: 'model'}, xhr: true

    assert_response :success
    assert_select 'input[name=?][value=?]', 'record[model]', 'Focus'
  end

  test 'render field processes update-column requests' do
    post '/people/render_field.js', params: {
      column: 'first_name', value: 'Ada', source_id: 'person_first_name'
    }, xhr: true

    assert_response :success
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
end
