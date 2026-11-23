# frozen_string_literal: true

require 'test_helper'

class ReturnToSigningTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(first_name: 'Visible person')
  end

  test 'unsigned destinations are rejected before rendering links' do
    get "/people/#{@person.id}", params: {return_to: 'javascript:alert(1)'}

    assert_response :bad_request
    assert_not_includes response.body, 'href="javascript:'
  end

  test 'signed local destinations appear on close links' do
    get "/people/#{@person.id}", params: signed_options('/dashboard?tab=people')

    assert_response :success
    assert_select 'a.as_cancel[href=?]', '/dashboard?tab=people'
  end

  test 'signed external destinations appear on close links' do
    destination = 'https://example.org/dashboard'
    get "/people/#{@person.id}", params: signed_options(destination)

    assert_response :success
    assert_select 'a.as_cancel[href=?]', destination
  end

  test 'changing a destination invalidates its signature' do
    options = signed_options('/dashboard')
    options[:return_to] = 'javascript:alert(1)'

    get "/people/#{@person.id}", params: options

    assert_response :bad_request
  end

  test 'malformed destinations and signatures are rejected' do
    [['/dashboard'], {path: '/dashboard'}].each do |destination|
      get '/people', params: {return_to: destination, return_to_signature: ['invalid']}
      assert_response :bad_request
    end
  end

  test 'unsigned destinations cannot obtain signatures by visiting the list' do
    get '/people', params: {return_to: 'javascript:alert(1)'}

    assert_response :bad_request
    assert_select 'a[href*="return_to_signature="]', count: 0
  end

  test 'invalid destinations are rejected before mutation' do
    assert_no_difference 'Person.count' do
      post '/people', params: {record: {first_name: 'Forged'}, return_to: '/dashboard'}
    end

    assert_response :bad_request
  end

  test 'forms preserve the destination and signature through submission' do
    address = Address.create!(street: 'Original')
    options = signed_options('/dashboard?tab=people')
    get "/addresses/#{address.id}/edit", params: options

    assert_response :success
    action = css_select('form.as_form').first['action']
    query = Rack::Utils.parse_nested_query(URI.parse(action).query)
    assert_equal options[:return_to], query['return_to']
    assert_equal options[:return_to_signature], query['return_to_signature']

    patch action, params: {record: {street: 'Changed'}}

    assert_redirected_to '/dashboard?tab=people'
    assert_equal 'Changed', address.reload.street
  end

  test 'successful updates can redirect to signed external destinations' do
    destination = 'https://example.org/dashboard'
    patch "/people/#{@person.id}", params: signed_options(destination).merge(record: {first_name: 'Changed'})

    assert_redirected_to destination
  end

  test 'embedded signatures cannot be reused for return destinations' do
    embedded = PeopleController.new.signed_embedded_options(controller: '/people', embedded: {conditions: '1=1'})

    get '/people', params: {return_to: '/dashboard', return_to_signature: embedded[:eid]}

    assert_response :bad_request
  end

  test 'removing a destination removes its signature without mutating original options' do
    options = signed_options('/dashboard')
    removed = options.merge(return_to: nil)
    generated = PeopleController.new.signed_return_to_options(removed)

    assert_not generated.key?(:return_to_signature)
    assert removed.key?(:return_to_signature)
    assert options.key?(:return_to_signature)
  end

  private

  def signed_options(destination)
    PeopleController.new.signed_return_to_options(return_to: destination)
  end
end

class ReturnToLinkGenerationTest < ActionController::TestCase
  setup do
    @controller = PeopleController.new
    @person = Person.create!(first_name: 'Visible person')
  end

  test 'action link overrides are signed for cached URLs after they return' do
    assert_override_signed(cache: true)
  end

  test 'action link overrides are signed for uncached URLs after they return' do
    assert_override_signed(cache: false)
  end

  test 'removing return_to in an option override does not leave a signature' do
    get :show, params: {id: @person.id}
    RequestStore.store[:attr_Registry_cache]&.delete(:action_link_url_options)
    view = @controller.view_context
    view.define_singleton_method(:action_link_url_options) do |link, record|
      options = super(link, record)
      options[:return_to] = '/dashboard'
      options.delete(:return_to)
      options
    end

    config = @controller.send(:active_scaffold_config)
    query = query_for(view.action_link_url(config.update.link, @person))

    assert_not query.key?('return_to')
    assert_not query.key?('return_to_signature')
  end

  test 'nested singular listings sign the generated return path' do
    car = Car.create!(model: 'Car', person: @person)
    get :index
    view = @controller.view_context
    view.stubs(:nested_singular_association?).returns(true)
    view.stubs(:action_name).returns('index')
    view.stubs(:params_for).returns(controller: '/cars', action: 'index', id: car.id)
    link = @controller.send(:active_scaffold_config).update.link

    _, query = view.query_string_for_action_links(link)
    parameters = Rack::Utils.parse_nested_query(query.delete_prefix('&'))

    assert_equal @controller.request.fullpath, parameters['return_to']
    assert_valid_signature(parameters)
  end

  private

  def assert_override_signed(cache:)
    incoming = @controller.signed_return_to_options(return_to: '/previous')
    get :show, params: incoming.merge(id: @person.id)
    RequestStore.store[:attr_Registry_cache]&.delete(:action_link_url_options)
    view = @controller.view_context
    view.define_singleton_method(:action_link_url_options) do |link, record|
      options = super(link, record)
      options[:return_to] = '/application-override'
      options
    end
    config = @controller.send(:active_scaffold_config)
    config.stubs(:cache_action_link_urls).returns(cache)

    query = query_for(view.action_link_url(config.update.link, @person))

    assert_equal '/application-override', query['return_to']
    assert_valid_signature(query)
  end

  def query_for(url)
    Rack::Utils.parse_nested_query(URI.parse(url).query)
  end

  def assert_valid_signature(query)
    assert ActiveScaffold::ParameterSigning.valid_signature?(query['return_to'], query['return_to_signature'], purpose: :return_to)
  end
end
