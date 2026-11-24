# frozen_string_literal: true

require 'test_helper'

class ApiAssociationExportTest < ActionDispatch::IntegrationTest
  setup do
    ActiveScaffold::DataStructures::ActionColumns.any_instance.stubs(:visible_columns_names).returns(%i[first_name car contacts])
    Car.any_instance.stubs(:to_label).returns('Car label')
    Contact.any_instance.stubs(:to_label).returns('Contact label')
    @person = Person.create!(first_name: 'Parent')
    @car = Car.create!(person: @person, brand: 'Visible brand', model: 'Private model')
    @contact = Contact.create!(contactable: @person, first_name: 'Contact', last_name: 'Private surname')
  end

  test 'safe JSON exports only identifiers and labels for singular and collection associations' do
    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'to_label' => @car.to_label}, response.parsed_body['car'])
    assert_equal [{'id' => @contact.id, 'to_label' => @contact.to_label}], response.parsed_body['contacts']
    assert_equal 'Parent', response.parsed_body['first_name']
  end

  test 'safe JSON list uses the same compact association output' do
    get '/people.json'

    assert_response :success
    row = response.parsed_body.find { |record| record['id'] == @person.id }
    assert_equal({'id' => @car.id, 'to_label' => @car.to_label}, row['car'])
  end

  test 'safe XML supports singular responses and collections without leaking association attributes' do
    ["/people/#{@person.id}.xml", '/people.xml'].each do |path|
      get path

      assert_response :success
      xml = Nokogiri::XML(response.body)
      assert_equal @car.id.to_s, xml.at_xpath('//car/id').text
      assert_equal @car.to_label, xml.at_xpath('//car/to-label').text
      assert_nil xml.at_xpath('//car/model')
      assert_nil xml.at_xpath('//contacts/contact/last-name')
    end
  end

  test 'nil associations and empty collections retain their shapes' do
    @car.destroy!
    @contact.destroy!

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_nil response.parsed_body['car']
    assert_equal [], response.parsed_body['contacts']
  end

  test 'unreadable associated records are omitted before exporting their fields' do
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :read).returns(false)
    Contact.any_instance.stubs(:authorized_for?).returns(true)
    Contact.any_instance.stubs(:authorized_for?).with(crud_type: :read).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_nil response.parsed_body['car']
    assert_equal [], response.parsed_body['contacts']
  end

  test 'association fields honor column read authorization' do
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :read, column: :to_label).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id}, response.parsed_body['car'])
  end

  test 'denied parent association columns are not exported' do
    Person.any_instance.stubs(:authorized_for?).returns(true)
    Person.any_instance.stubs(:authorized_for?).with(crud_type: :read, column: :car).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_not response.parsed_body.key?('car')
  end

  test 'the controller hook selects additional association fields with authorization' do
    ActiveScaffold::DataStructures::ActionColumns.any_instance.stubs(:visible_columns_names).returns([:car])
    PeopleController.any_instance.expects(:api_association_columns).with do |column, record|
      column.name == :car && record.id == @car.id
    end.returns(%i[id brand model to_label])
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :read, column: :model).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'brand' => 'Visible brand', 'to_label' => @car.to_label}, response.parsed_body['car'])
  end

  test 'safe JSON preserves a configured model root' do
    Person.stubs(:include_root_in_json).returns(true)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'to_label' => @car.to_label}, response.parsed_body.fetch('person')['car'])
  end
end
