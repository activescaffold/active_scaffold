# frozen_string_literal: true

require 'test_helper'

class ListRenderingIntegrationTest < ActionDispatch::IntegrationTest
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

  test 'list renders configured column calculations in its footer' do
    Car.create!(brand: 'Ford', model: 'Focus')
    Car.create!(brand: 'Ford', model: 'Mondeo')

    get '/cars'

    assert_response :success
    assert_select 'tfoot .active-scaffold-calculations', text: /Count:\s*2/
  end

  test 'list renders inplace editing for a string column' do
    car = Car.create!(brand: 'Ford', model: 'Focus')

    get '/cars'

    assert_response :success
    assert_select 'th.model-column_heading[data-ie-url*="/cars/__id__/update_column"]'
    assert_select 'td.model-column.in_place_editor_field' do
      assert_select 'span.handle'
      assert_select "span.in_place_editor_field[data-ie-id=\"#{car.id}\"]", text: 'Focus'
    end
  end

  test 'list heading renders the inplace cloning control for a form ui' do
    Car.create!(brand: 'Ford', model: 'Focus')

    get '/cars', params: {inplace_form_ui: true}

    assert_response :success
    assert_select 'th.model-column_heading' do
      assert_select 'div.as_inplace_pattern[style="display:none;"]' do
        assert_select 'select.model-input.inplace_field[data-id="record_model_"]' do
          assert_select 'option[value="Focus"]', text: 'Focus'
          assert_select 'option[value="Mondeo"]', text: 'Mondeo'
        end
      end
    end
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

  test 'xhr auto pagination hides its indicator after the last page' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people.js', params: {auto_pagination: true, limit: 1, page: 2}, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.append'
    assert_includes response.body, 'ActiveScaffold.hide'
    assert_includes response.body, 'Bob'
    assert_not_includes response.body, 'ActiveScaffold.auto_load_page'
  end

  test 'xhr auto pagination hides its indicator when the page is empty' do
    get '/people.js', params: {auto_pagination: true, limit: 1, page: 1}, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.hide'
    assert_not_includes response.body, 'ActiveScaffold.append'
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

    options = PeopleController.new.signed_embedded_options(embedded: {loading: true})
    get '/people', params: options

    assert_response :success
    assert_not_includes response.body, 'ActiveScaffold test app'
    assert_select '.active-scaffold', text: /Alice/
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

  test 'column parameters do not filter the list by default' do
    Person.create!(first_name: 'Alice', last_name: 'Example')
    Person.create!(first_name: 'Bob', last_name: 'Example')

    get '/people', params: {first_name: 'Alice'}

    assert_response :success
    assert_select 'tbody.records .first_name-column', text: 'Alice', count: 1
    assert_select 'tbody.records .first_name-column', text: 'Bob', count: 1
  end

  test 'column parameters filter the list through finder parameter conditions' do
    config = PeopleController.active_scaffold_config.dup
    config.conditions_from_params_allowed_columns = %i[first_name buildings_count]
    PeopleController.stubs(:active_scaffold_config).returns(config)

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
    config = PeopleController.active_scaffold_config.dup
    config.conditions_from_params_allowed_columns = [:first_name]
    PeopleController.stubs(:active_scaffold_config).returns(config)

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

  test 'locally sortable list cells include their unformatted sort value' do
    Person.create!(first_name: 'Alice', last_name: 'Example', adult: true)
    Person.create!(first_name: 'Bob', last_name: 'Example', adult: false)

    get '/people', params: {local_sorting: true}

    assert_response :success
    assert_select 'table.list-table.local-sorting'
    assert_select 'td.adult-column[data-sort-value="0"]'
    assert_select 'td.adult-column[data-sort-value="1"]'
  end
end
