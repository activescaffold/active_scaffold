# frozen_string_literal: true

require 'test_helper'

class ActionsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    [Address, Contact, Building, Person, Car, Category, Role].each(&:delete_all)
  end

  teardown do
    [Address, Contact, Building, Person, Car, Category, Role].each(&:delete_all)
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

  test 'xhr list with an id refreshes one row' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people.js', params: {id: person.id}, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.update_row'
    assert_includes response.body, 'Alice'
    assert_includes response.body, "people-list-#{person.id}-row"
  end

  test 'xhr list renders a member action links menu' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people.js', params: {id: person.id, action_links: 'member'}, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.display_dynamic_action_group'
    assert_includes response.body, 'Edit'
    assert_includes response.body, 'Delete'
  end

  test 'list applies requested sorting' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people', params: {sort: 'first_name', sort_direction: 'desc'}

    assert_response :success
    sorted_names = css_select('tbody.records .first_name-column').map { |cell| cell.text.strip }
    assert_equal %w[Bob Alice], sorted_names
  end

  test 'list uses cached counts for an association without includes' do
    alice = Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')
    alice.roles << Role.create!(name: 'First')
    alice.roles << Role.create!(name: 'Second')

    get '/people'

    assert_response :success
    rows = css_select('tbody.records > tr.record').index_by { |row| row.at_css('.first_name-column').text.strip }
    assert_equal '2', rows.fetch('Alice').at_css('.roles-column').text.strip
    assert_equal '0', rows.fetch('Bob').at_css('.roles-column').text.strip
  end

  test 'embedded loading renders the list without the application layout' do
    Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people', params: {embedded: {loading: true}}

    assert_response :success
    assert_not_includes response.body, 'ActiveScaffold test app'
    assert_select '.active-scaffold', text: /Alice/
  end

  test 'action authorization errors are rescued as forbidden responses' do
    get '/people/forbidden'

    assert_response :forbidden
    assert_empty response.body
  end

  test 'xhr list can be wrapped in a rendering adapter' do
    Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people', params: {adapter: '_popup_adapter'}, xhr: true

    assert_response :success
    assert_select '.active-scaffold .index-view', text: /Alice/
  end

  test 'xhr list can be wrapped in the inline rendering adapter' do
    Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people', params: {adapter: '_list_inline_adapter'}, xhr: true

    assert_response :success
    assert_includes response.body, '<tr class="inline-adapter"'
    assert_includes response.body, '<td class="inline-adapter-cell">'
    assert_includes response.body, 'inline-adapter-close as_cancel'
    assert_includes response.body, 'Alice'
  end

  test 'search filters the list through the controller callback chain' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people', params: {search: 'Alice'}

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_not_includes response.body, 'Bob'
  end

  test 'column parameters filter the list through finder parameter conditions' do
    Person.create!(first_name: 'Alice', last_name: 'Example', buildings_count: 1)
    Person.create!(first_name: 'Bob', last_name: 'Example', buildings_count: 3)

    get '/people', params: {first_name: 'Alice'}

    assert_response :success
    assert_includes response.body, 'Alice'
    assert_not_includes response.body, 'Bob'

    get '/people', params: {buildings_count: '2..4'}

    assert_response :success
    assert_not_includes response.body, 'Alice'
    assert_includes response.body, 'Bob'
  end

  test 'column parameters ending in an exclamation mark exclude matching records' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people', params: {'first_name!' => 'Alice'}

    assert_response :success
    assert_select 'tbody.records .first_name-column', text: 'Alice', count: 0
    assert_select 'tbody.records .first_name-column', text: 'Bob', count: 1
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

  test 'search action renders its full page for an html request' do
    get '/contacts/show_search', params: {kind: 'search'}

    assert_response :success
    assert_select '.active-scaffold .search-view.contacts-view' do
      assert_select 'form.as_form.search'
      assert_select 'input[type=?][name=?]', 'search', 'search'
      assert_select 'a.as_cancel', text: 'Reset'
    end
  end

  test 'field search action renders its full page for an html request' do
    get '/contacts/show_search', params: {kind: 'field_search'}

    assert_response :success
    assert_select '.active-scaffold .search-view' do
      assert_select 'form.as_form.search'
      assert_select '[name^=?]', 'search[first_name]'
      assert_select '[name^=?]', 'search[last_name]'
      assert_select '[name^=?]', 'search[birthday]'
    end
  end

  test 'field search renders human conditions for the applied fields' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/integration_people', params: {search: {first_name: {opt: '%?%', from: 'Alice'}}}

    assert_response :success
    assert_select '.filtered-message', text: /First name.*Alice/
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

  test 'xhr show renders the show partial without the full page wrapper' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get "/people/#{person.id}.js", xhr: true

    assert_response :success
    assert_select '.show-view', count: 0
    assert_select 'h4', count: 1
    assert_select '.first_name-view', text: 'Alice'
    assert_select '.last_name-view', text: 'Example'
  end

  test 'show renders destroy confirmation for non-javascript fallback' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get "/people/#{person.id}", params: {destroy_action: true}

    assert_response :success
    assert_select '.delete-view form[action=?]', "/people/#{person.id}" do
      assert_select 'input[name=?][value=?]', '_method', 'delete'
      assert_select 'input[type=?]', 'submit'
    end
    assert_includes response.body, 'Are you sure you want to delete'
  end

  test 'show renders an override and horizontal and vertical association UIs' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')
    person.create_car!(brand: 'Ford', model: 'Focus')
    person.contacts.create!(first_name: 'Bob', last_name: 'Contact')
    person.buildings.create!(name: 'Headquarters', floors_count: 3)

    get "/integration_people/#{person.id}"

    assert_response :success
    assert_select '.show-view > .active-scaffold-header .actions' do
      assert_select 'a.edit', text: 'Edit'
      assert_select 'a.destroy', text: 'Delete'
    end
    assert_select 'dt', text: 'Identity'
    assert_select '.first_name-view', text: /Profile: Alice/
    assert_select '.car-view table' do
      assert_select 'th', text: 'Brand'
      assert_select 'td.brand-column', text: 'Ford'
      assert_select 'td.model-column', text: 'Focus'
    end
    assert_select '.contacts-view table' do
      assert_select 'td.first_name-column', text: 'Bob'
      assert_select 'td.last_name-column', text: 'Contact'
    end
    assert_select '.buildings-view' do
      assert_select '.name-view', text: 'Headquarters'
      assert_select '.floors_count-view', text: '3'
    end
  end

  test 'list filters render and restrict records' do
    Person.create!(first_name: 'Alice', adult: true)
    Person.create!(first_name: 'Bob', adult: false)

    get '/integration_people', params: {age: 'adults'}

    assert_response :success
    assert_select '.filters', text: /Age/
    assert_select '.filters a', text: 'Adults'
    assert_select '.applied-filters', text: /Adults/
    assert_select 'tbody.records .first_name-column', text: 'Alice', count: 1
    assert_select 'tbody.records .first_name-column', text: 'Bob', count: 0
  end

  test 'form renders configured radio and checkbox inputs' do
    admin = Role.create!(name: 'Admin')
    editor = Role.create!(name: 'Editor')

    get '/integration_people/new'

    assert_response :success
    assert_select 'input[type=?][name=?][value=?]', 'radio', 'record[adult]', 'true'
    assert_select 'input[type=?][name=?][value=?]', 'radio', 'record[adult]', 'false'
    assert_select '.roles-input.checkbox-list' do
      assert_select 'input[type=?][name=?][value=?]', 'checkbox', 'record[roles][]', admin.id.to_s
      assert_select 'input[type=?][name=?][value=?]', 'checkbox', 'record[roles][]', editor.id.to_s
    end
  end

  test 'show and edit work when list and nested actions are disabled' do
    person = Person.create!(first_name: 'Standalone', last_name: 'Example')

    get "/standalone_people/#{person.id}"

    assert_response :success
    assert_includes response.body, 'Standalone'

    get "/standalone_people/#{person.id}/edit"

    assert_response :success
    assert_select 'input[name=?][value=?]', 'record[first_name]', 'Standalone'
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

  test 'xhr create inserts a successful record into the list' do
    assert_difference('Person.count') do
      post '/people.js', params: {
        record: {first_name: 'Alice', last_name: 'Example'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.create_record_row'
    assert_includes response.body, 'Alice'
    assert_includes response.body, 'if (action_link) action_link.close();'
  end

  test 'xhr create replaces the form when validation fails' do
    assert_no_difference('Category.count') do
      post '/categories.js', params: {record: {name: 'x'}}, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.replace'
    assert_includes response.body, 'categories-create--form'
    assert_includes response.body, 'too short'
  end

  test 'create with dont_close persists and returns to a new form' do
    assert_difference('Person.count') do
      post '/people', params: {
        dont_close: true,
        record: {first_name: 'Alice', last_name: 'Example'}
      }
    end

    assert_redirected_to '/people/new'
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

  test 'xhr update replaces the form when validation fails' do
    category = Category.create!(name: 'Valid category')

    patch "/categories/#{category.id}.js", params: {record: {name: 'x'}}, xhr: true

    assert_response :success
    assert_equal 'Valid category', category.reload.name
    assert_includes response.body, 'ActiveScaffold.replace'
    assert_includes response.body, "categories-update-#{category.id}-form"
    assert_includes response.body, 'too short'
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

  test 'render field adds a tab for a tabbed association' do
    category = Category.create!(name: 'Frontend')

    post '/projects/render_field.js', params: {
      tabbed_by: 'category', column: 'Assignments', value: category.id, form_action: 'create'
    }, xhr: true

    assert_response :success
    assert_includes response.body, 'Frontend'
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
