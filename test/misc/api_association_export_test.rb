# frozen_string_literal: true

require 'test_helper'

class ApiAssociationExportTest < ActionDispatch::IntegrationTest
  setup do
    ActiveScaffold::Config::Core.any_instance.stubs(:unsafe_api_associations).returns(false)
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

  test 'default association fields do not require column authorization checks' do
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :read).returns(true)
    Car.any_instance.expects(:authorized_for?).with do |options|
      options.key?(:column)
    end.never

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'to_label' => @car.to_label}, response.parsed_body['car'])
  end

  test 'denied parent association columns are not exported' do
    Person.any_instance.stubs(:authorized_for?).returns(true)
    Person.any_instance.stubs(:authorized_for?).with(crud_type: :read, column: :car).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_not response.parsed_body.key?('car')
  end

  test 'controller serialization options are used without automatic column checks' do
    ActiveScaffold::DataStructures::ActionColumns.any_instance.stubs(:visible_columns_names).returns([:car])
    PeopleController.any_instance.expects(:api_association_options).with do |column, record|
      column.name == :car && record.id == @car.id
    end.returns(only: %i[id brand model], methods: [:to_label])
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :read, column: :model).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'brand' => 'Visible brand', 'model' => 'Private model', 'to_label' => @car.to_label}, response.parsed_body['car'])
  end

  test 'a custom controller hook can authorize additional fields per associated record' do
    PeopleController.define_method(:api_association_options) do |column, record|
      options = super(column, record)
      if column.name == :car
        columns = %i[brand model].select { |name| record.authorized_for?(crud_type: :read, column: name) }
        options = options.merge(only: Array(options[:only]) + columns)
      end
      options
    end
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :read, column: :model).returns(false)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'brand' => 'Visible brand', 'to_label' => @car.to_label}, response.parsed_body['car'])
    assert_equal [{'id' => @contact.id, 'to_label' => @contact.to_label}], response.parsed_body['contacts']
  ensure
    PeopleController.remove_method(:api_association_options)
  end

  test 'controller options can explicitly include nested associations' do
    PeopleController.define_method(:api_association_options) do |column, record|
      options = super(column, record)
      column.name == :car ? options.merge(include: {person: {only: [:first_name]}}) : options
    end

    get "/people/#{@person.id}.json"

    assert_response :success
    car = response.parsed_body['car']
    assert_equal({'first_name' => 'Parent'}, car['person'])
    assert_equal %w[id person to_label], car.keys.sort
    assert_not car['person'].key?('car')
  ensure
    PeopleController.remove_method(:api_association_options)
  end

  test 'nested JSON uses serializable_hash without association model roots' do
    Car.stubs(:include_root_in_json).returns(true)
    Car.any_instance.expects(:as_json).never

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'to_label' => @car.to_label}, response.parsed_body['car'])
  end

  test 'XML root options are preserved for records and collections without modifying the options' do
    config = PeopleController.active_scaffold_config
    [@person, [@person], []].each do |records|
      response = ActiveScaffold::Actions::Core::AuthorizedApiResponse.new(records, [:car], config)
      options = {root: 'custom-people'}.freeze
      xml = Nokogiri::XML(response.to_xml(options))

      assert_equal 'custom-people', xml.root.name
      assert_equal({root: 'custom-people'}, options)
      assert_equal 'Car label', xml.at_xpath('//car/to-label').text unless records == []
    end
  end

  test 'safe JSON preserves a configured model root' do
    Person.stubs(:include_root_in_json).returns(true)

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal({'id' => @car.id, 'to_label' => @car.to_label}, response.parsed_body.fetch('person')['car'])
  end

  test 'default legacy output warns once per response and retains all association attributes' do
    ActiveScaffold::Config::Core.any_instance.stubs(:unsafe_api_associations).returns(nil)
    ActiveScaffold.deprecator.expects(:warn).with do |message|
      message.include?('without checking associated record or column read authorization') &&
        message.include?('removed in ActiveScaffold 4.5') && message.include?('unsafe_api_associations = false')
    end.once

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal 'Private model', response.parsed_body['car']['model']
    assert_equal 'Private surname', response.parsed_body['contacts'].first['last_name']
  end

  test 'explicit legacy output retains association attributes without a warning' do
    ActiveScaffold::Config::Core.any_instance.stubs(:unsafe_api_associations).returns(true)
    ActiveScaffold.deprecator.expects(:warn).never

    get "/people/#{@person.id}.json"

    assert_response :success
    assert_equal 'Private model', response.parsed_body['car']['model']
  end

  test 'legacy mode does not warn when no associations are exported' do
    ActiveScaffold::Config::Core.any_instance.stubs(:unsafe_api_associations).returns(nil)
    ActiveScaffold::DataStructures::ActionColumns.any_instance.stubs(:visible_columns_names).returns([:first_name])
    ActiveScaffold.deprecator.expects(:warn).never

    get "/people/#{@person.id}.json"

    assert_response :success
  end
end
