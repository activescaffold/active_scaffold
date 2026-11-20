# frozen_string_literal: true

require 'test_helper'

class CreateIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    [Contact, Person, Car, Category, Role].each(&:delete_all)
  end

  teardown do
    [Contact, Person, Car, Category, Role].each(&:delete_all)
    RequestStore.clear!
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

  test 'list can show the create form through request configuration' do
    get '/people', params: {always_show_create: true}

    assert_response :success
    assert_select 'form.as_form.create'
    assert_select 'form.as_form.create a.as_cancel', count: 0
  end

  test 'xhr create resets an always visible create form' do
    assert_difference('Person.count') do
      post '/people.js', params: {
        always_show_create: true,
        record: {first_name: 'Alice', last_name: 'Example'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.create_record_row'
    assert_includes response.body, 'ActiveScaffold.reset_form'
    assert_includes response.body, 'people-create--form'
  end

  test 'xhr create can update the association field that launched it' do
    assert_difference('Person.count') do
      post '/people.js', params: {
        from_field: 'role_people',
        parent_model: 'Role',
        parent_column: 'people',
        parent_scope: 'record[people]',
        record: {first_name: 'Alice', last_name: 'Example'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, "var field = jQuery('#role_people')"
    assert_includes response.body, "field.is('select')"
    assert_includes response.body, "field.is('.checkbox-list')"
    assert_includes response.body, 'field.trigger(\'change\')'
  end

  test 'xhr create refreshes a singular nested parent' do
    person = Person.create!(first_name: 'Alice')

    assert_difference('Car.count') do
      post '/cars/create_nested.js', params: {
        parent_scaffold: 'people', association: 'car', person_id: person.id, eid: 'people',
        record: {brand: 'Ford', model: 'Focus'}
      }, xhr: true
    end

    assert_response :success
    assert_equal 'Focus', person.reload.car.model
    assert_includes response.body, 'action_link.close(true)'
    assert_not_includes response.body, 'ActiveScaffold.create_record_row('
  end

  test 'xhr STI create inserts its parent row from the parent URL' do
    assert_difference('SpecialPerson.count') do
      post '/special_people.js', params: {
        parent_sti: 'people', record: {first_name: 'Alice', last_name: 'Example'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.create_record_row_from_url'
    assert_includes response.body, '/people'
    assert_not_includes response.body, 'ActiveScaffold.reload'
  end

  test 'xhr STI create reloads a parent configured to refresh its list' do
    assert_difference('SpecialCategory.count') do
      post '/special_categories.js', params: {
        parent_sti: 'categories', record: {name: 'Example'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.reload'
    assert_includes response.body, '/categories'
    assert_not_includes response.body, 'ActiveScaffold.create_record_row_from_url'
  end

  test 'xhr create can refresh the complete list' do
    assert_difference('Category.count') do
      post '/categories.js', params: {record: {name: 'Example'}}, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.replace_html'
    assert_includes response.body, 'as_categories-content'
    assert_not_includes response.body, 'ActiveScaffold.create_record_row('
  end

  test 'xhr create refreshes an action link from a parent controller' do
    assert_difference('Contact.count') do
      post '/contacts.js', params: {
        parent_controller: 'people', record: {first_name: 'Nested', last_name: 'Contact'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'if (action_link) action_link.refresh()'
    assert_not_includes response.body, 'ActiveScaffold.create_record_row('
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

  test 'xhr create with dont_close inserts the record and replaces the create form' do
    assert_difference('Person.count') do
      post '/people.js', params: {
        dont_close: true,
        record: {first_name: 'Alice', last_name: 'Example'}
      }, xhr: true
    end

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.create_record_row'
    assert_includes response.body, 'ActiveScaffold.replace'
    assert_includes response.body, 'people-create--form'
    assert_includes response.body, 'ActiveScaffold.focus_first_element_of_form'
    assert_not_includes response.body, 'action_link.close()'
  end
end
