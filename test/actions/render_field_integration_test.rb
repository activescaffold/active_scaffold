# frozen_string_literal: true

require 'test_helper'

class RenderFieldIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    [Contact, Building, Person, Car, Category].each(&:delete_all)
  end

  teardown do
    [Contact, Building, Person, Car, Category].each(&:delete_all)
    RequestStore.clear!
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

  test 'render field refreshes configured dependent form columns' do
    post '/people/render_field.js', params: {
      update_columns: true,
      column: 'first_name',
      value: 'Ada',
      source_id: 'person_first_name'
    }, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.render_form_field'
    assert_includes response.body, 'person_first_name'
    assert_includes response.body, 'last_name-input'
  end

  test 'render field traverses configured dependent column trees' do
    post '/people/render_field.js', params: {
      nested_update_columns: true,
      column: 'first_name',
      source_id: 'person_first_name',
      record: {first_name: 'Ada', last_name: 'Lovelace'}
    }, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.render_form_field'
    assert_includes response.body, 'last_name-input'
    assert_includes response.body, 'Lovelace'
  end

  test 'render field traverses an association hash in update columns' do
    post '/people/render_field.js', params: {
      hash_update_columns: true,
      column: 'first_name',
      source_id: 'person_first_name',
      record: {
        first_name: 'Ada',
        contacts: {'new-contact' => {first_name: 'Grace', last_name: 'Hopper'}}
      }
    }, xhr: true

    assert_response :success
    assert_includes response.body, 'ActiveScaffold.render_form_field'
    assert_includes response.body, 'contacts-sub-form'
    assert_includes response.body, 'last_name-input'
    assert_includes response.body, 'Hopper'
  end

  test 'render field chains association columns and refreshes a subform' do
    post '/people/render_field.js', params: {
      chained_hash_update_columns: true,
      column: 'first_name',
      source_id: 'person_first_name',
      record: {
        first_name: 'Ada',
        contacts: {'new-contact' => {first_name: 'Grace', last_name: 'Hopper'}},
        buildings: {'new-building' => {name: 'Tower'}}
      }
    }, xhr: true

    assert_response :success
    assert_includes response.body, 'contacts-sub-form'
    assert_includes response.body, 'last_name-input'
    assert_includes response.body, 'first_name-input'
    assert_includes response.body, 'Grace'
    assert_includes response.body, 'buildings-sub-form'
    assert_includes response.body, 'Tower'
  end

  test 'render field adds a tab for a tabbed association' do
    category = Category.create!(name: 'Frontend')

    post '/projects/render_field.js', params: {
      tabbed_by: 'category', column: 'Assignments', value: category.id, form_action: 'create'
    }, xhr: true

    assert_response :success
    assert_includes response.body, 'Frontend'
  end
end
