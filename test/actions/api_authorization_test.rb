# frozen_string_literal: true

require 'test_helper'

class ApiAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Person.class_eval do
      def last_name_authorized_for_read?
        adult?
      end
    end
    Person.instance_security_methods = {}
    Person.delete_all
  end

  teardown do
    Person.class_eval { remove_method :last_name_authorized_for_read? }
    Person.instance_security_methods = {}
    Person.delete_all
  end

  test 'JSON list applies column read authorization to each record' do
    denied = Person.create!(first_name: 'Child', last_name: 'Secret', adult: false)
    allowed = Person.create!(first_name: 'Adult', last_name: 'Visible', adult: true)

    get '/people.json'

    assert_response :success
    people = response.parsed_body.index_by { |person| person['id'] }
    assert_not people.fetch(denied.id).key?('last_name')
    assert_equal 'Visible', people.fetch(allowed.id).fetch('last_name')
  end

  test 'JSON show applies column read authorization to the record' do
    denied = Person.create!(first_name: 'Child', last_name: 'Secret', adult: false)
    allowed = Person.create!(first_name: 'Adult', last_name: 'Visible', adult: true)

    get "/people/#{denied.id}.json"
    assert_response :success
    assert_not response.parsed_body.key?('last_name')

    get "/people/#{allowed.id}.json"
    assert_response :success
    assert_equal 'Visible', response.parsed_body.fetch('last_name')
  end
end
