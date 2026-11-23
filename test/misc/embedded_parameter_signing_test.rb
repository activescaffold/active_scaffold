# frozen_string_literal: true

require 'test_helper'

class EmbeddedParameterSigningTest < ActionDispatch::IntegrationTest
  setup do
    @adult = Person.create!(first_name: 'Adult', adult: true)
    @child = Person.create!(first_name: 'Child', adult: false)
  end

  test 'unsigned SQL conditions are rejected' do
    get '/people.json', params: {embedded: {conditions: '1=1'}}

    assert_response :bad_request
  end

  test 'signed conditions filter the list' do
    get '/people.json', params: signed_options(conditions: {adult: true})

    assert_response :success
    assert_equal [@adult.id], response.parsed_body.pluck('id')
  end

  test 'changing conditions invalidates their signature' do
    options = signed_options(conditions: {adult: true})
    options[:embedded][:conditions] = '1=1'

    get '/people.json', params: options

    assert_response :bad_request
  end

  test 'unsigned constraints cannot bypass create columns' do
    assert_no_difference 'Person.count' do
      post '/people.json', params: {record: {first_name: 'Forged'}, embedded: {constraints: {created_at: '2000-01-01'}}}
    end

    assert_response :bad_request
  end

  test 'signed server constraints can set hidden create attributes' do
    options = signed_options(constraints: {created_at: '2000-01-01'})

    post '/people.json', params: options.merge(record: {first_name: 'Constrained'})

    assert_response :created
    assert_equal 2000, Person.find_by!(first_name: 'Constrained').created_at.year
  end

  test 'changing constraints is rejected before creating a record' do
    options = signed_options(constraints: {created_at: '2000-01-01'})
    options[:embedded][:constraints][:created_at] = '1990-01-01'

    assert_no_difference 'Person.count' do
      post '/people.json', params: options.merge(record: {first_name: 'Forged'})
    end
    assert_response :bad_request
  end

  test 'embedded signatures are bound to their controller' do
    get '/cars.json', params: signed_options(conditions: {adult: true})

    assert_response :bad_request
  end

  test 'loading can be removed without invalidating the signature' do
    options = signed_options(conditions: {adult: true}, loading: true)
    options[:embedded].delete(:loading)

    get '/people.json', params: options

    assert_response :success
    assert_equal [@adult.id], response.parsed_body.pluck('id')
  end

  test 'invalid embedded shapes and signatures are rejected' do
    ['conditions', ['conditions'], {conditions: '1=1'}].each do |embedded|
      get '/people.json', params: {embedded: embedded, eid: ['invalid']}
      assert_response :bad_request
    end
  end

  test 'identifiers are stable across hash ordering and URL round trips' do
    controller = PeopleController.new
    original = {constraints: {adult: true, id: [@adult.id, @child.id]}, label: 'People'}
    reordered = {label: 'People', constraints: {id: [@adult.id, @child.id], adult: true}}
    options = controller.signed_embedded_options(controller: '/people', embedded: original)
    round_trip = Rack::Utils.parse_nested_query(options.to_query).with_indifferent_access

    assert_match(/\A[0-9a-f]{64}\z/, options[:eid])
    assert_equal options[:eid], controller.signed_embedded_options(controller: '/people', embedded: reordered)[:eid]
    assert_equal options[:eid], controller.signed_embedded_options(round_trip)[:eid]
    assert_not_equal options[:eid], controller.signed_embedded_options(controller: '/people', embedded: {label: 'Other'})[:eid]
  end

  private

  def signed_options(embedded)
    PeopleController.new.signed_embedded_options(controller: '/people', embedded: embedded).except(:controller)
  end
end
