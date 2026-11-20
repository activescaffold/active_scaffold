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

  test 'custom xhr action can render the update row view' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    get "/people/#{person.id}/refresh_row.js", xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.update_row'
    assert_includes response.body, "people-list-#{person.id}-row"
    assert_includes response.body, 'Alice'
  end

  test 'successful xhr action link closes with the updated row' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    post "/people/#{person.id}/archive.js", xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.find_action_link'
    assert_includes response.body, "if (link) link.close('"
    assert_includes response.body, 'Alice'
  end

  test 'failed xhr action link updates its form messages' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')

    post "/people/#{person.id}/archive.js", params: {force_action_failure: true}, xhr: true

    assert_response :success
    assert_includes response.body, 'link.update_flash_messages'
    assert_includes response.body, 'ActiveScaffold.enable_form'
    assert_includes response.body, 'custom action failed'
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

  test 'list renders configured column calculations in its footer' do
    Car.create!(brand: 'Ford', model: 'Focus')
    Car.create!(brand: 'Ford', model: 'Mondeo')

    get '/cars'

    assert_response :success
    assert_select 'tfoot .active-scaffold-calculations', text: /Count:\s*2/
  end

  test 'xhr row refresh updates configured column calculations' do
    car = Car.create!(brand: 'Ford', model: 'Focus')
    Car.create!(brand: 'Ford', model: 'Mondeo')

    get '/cars.js', params: {id: car.id}, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.update_row'
    assert_includes response.body, 'ActiveScaffold.replace'
    assert_includes response.body, 'calculations'
    assert_includes response.body, 'Count: 2'
  end

  test 'xhr list refresh replaces its content and records browser history' do
    Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people.js', xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'ActiveScaffold.add_to_history'
    assert_includes response.body, 'Alice'
  end

  test 'xhr list refresh can include the header through request configuration' do
    Person.create!(first_name: 'Alice', last_name: 'Example')

    get '/people.js', params: {refresh_with_header: true}, xhr: true

    assert_response :success
    assert_includes response.body, "ActiveScaffold.replace('as_people-active-scaffold'"
    assert_includes response.body, 'active-scaffold-header'
    assert_includes response.body, 'Alice'
  end

  test 'xhr auto pagination appends records and loads the next page' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people.js', params: {auto_pagination: true, limit: 1, page: 1}, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.append'
    assert_includes response.body, 'ActiveScaffold.auto_load_page'
    assert_includes response.body, 'Alice'
    assert_not_includes response.body, 'ActiveScaffold.add_to_history'
  end

  test 'xhr paginated list on page two renders a previous-page link' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')
    Person.create!(first_name: 'Carol', last_name: 'Example')

    get '/people.js', params: {limit: 1, page: 2}, xhr: true

    assert_response :success
    assert_includes response.body, 'previous'
    assert_includes response.body, 'page=1'
    assert_includes response.body, 'Bob'
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

  test 'field search supports multiple layout with optional columns' do
    get '/contacts/show_search', params: {kind: 'field_search', multiple_field_search: true}

    assert_response :success
    assert_select '.search-view .form-columns' do
      assert_select '> ol.form', count: 2
      assert_select '[name^=?]', 'search[first_name]'
      assert_select '[name^=?]', 'search[last_name]'
      assert_select '[name^=?]', 'search[birthday]'
      assert_select '.sub-section', minimum: 2
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

  test 'xhr nested create updates its nested scaffold' do
    person = Person.create!(first_name: 'Alice')

    assert_difference('Contact.count') do
      post '/contacts.js', params: {
        parent_scaffold: 'people', association: 'contacts', person_id: person.id,
        record: {first_name: 'Nested'}
      }, xhr: true
    end

    assert_response :success
    assert_equal person, Contact.order(:id).last.contactable
    assert_includes response.body, 'ActiveScaffold.create_record_row'
    assert_includes response.body, "as_people-#{person.id}-contacts-active-scaffold"
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

  test 'show renders a tabbed subgroup with horizontal association UIs' do
    backend = Category.create!(name: 'Backend')
    frontend = Category.create!(name: 'Frontend')
    project = Project.create!(name: 'Application')
    project.tasks.create!(name: 'Build API', priority: 'high', category: backend)
    project.tasks.create!(name: 'Build UI', priority: 'medium', category: frontend)
    project.milestones.create!(name: 'First release', section: backend)

    get "/projects/#{project.id}"

    assert_response :success
    assert_select 'dt', text: 'Assignments'
    assert_select '.nav-tabs .nav-link', text: 'Backend'
    assert_select '.nav-tabs .nav-link', text: 'Frontend'
    assert_select '.tab-content .tab-pane', count: 2
    assert_select '.tasks-view table' do
      assert_select 'td.name-column', text: /Build API|Build UI/, count: 2
      assert_select 'tbody > tr', count: 4
      assert_select 'td[colspan]', text: /High|Medium/, count: 2
    end
    assert_select '.milestones-view table td.name-column', text: 'First release'
  ensure
    Task.delete_all
    Milestone.delete_all
    Project.delete_all
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

  test 'edit renders a vertical subform with a subgroup and add-existing footer' do
    person = Person.create!(first_name: 'Alice', last_name: 'Example')
    person.buildings.create!(name: 'Tower')
    Building.create!(name: 'Available building')

    get "/people/#{person.id}/edit", params: {vertical_subform: true}

    assert_response :success
    assert_select '.buildings-sub-form.vertical-sub-form' do
      assert_select '.sub-form-record > ol.association-record', minimum: 1
      assert_select '.sub-form-record > ol.associated-record > li .floors_count-input', minimum: 1
    end
    assert_select '.buildings-sub-form .footer-wrapper' do
      assert_select 'select[name=?]', 'associated_id'
      assert_select 'a.as_add_existing'
    end
  end

  test 'create form supports multiple column layout' do
    get '/people/new', params: {multiple_form: true}

    assert_response :success
    assert_select '.create-view .form-columns' do
      assert_select '> ol.form', count: 2
      assert_select 'input[name=?]', 'record[first_name]'
      assert_select 'input[name=?]', 'record[last_name]'
      assert_select 'input[name=?]', 'record[adult]'
    end
  end
end
