# frozen_string_literal: true

require 'test_helper'

class ActionLinkUrlsTest < ActionController::TestCase
  setup do
    @controller = PeopleController.new
    @person = Person.create!(first_name: 'First')
    @other_person = Person.create!(first_name: 'Second')
    get :index, params: {status: 'open', context: 'dashboard', person_id: 'old-parent'}
    @view = @controller.view_context
    @config = @controller.send(:active_scaffold_config)
    filters = ActiveScaffold::DataStructures::Filters.new
    filters.add(:status) { |filter| filter.add(:open) }
    @config.list.stubs(:filters).returns(filters)
    RequestStore.store[:attr_Registry_cache]&.delete(:action_link_url_options)
  end

  [true, false].each do |cache| # rubocop:disable Metrics/BlockLength -- exercise both URL generation modes
    test "nested links exclude parent filters with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      link = nested_link

      [@person, @other_person].each do |person|
        query = query_for(@view.action_link_url(link, person))

        assert_not query.key?('status'), query.inspect
        assert_equal 'dashboard', query['context']
        assert_equal person.id.to_s, query['person_id']
      end
    end

    test "ordinary links retain filters with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)

      [@person, @other_person].each do |person|
        url = @view.action_link_url(@config.update.link, person)

        assert_equal 'open', query_for(url)['status']
        assert_equal "/people/#{person.id}/edit", URI.parse(url).path
      end
    end

    test "explicit nested filters take precedence with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      link = nested_link
      link.parameters[:status] = 'closed'

      assert_equal 'closed', query_for(@view.action_link_url(link, @person))['status']
    end

    test "overrides replace request parameters without duplicates with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      @view.define_singleton_method(:action_link_url_options) do |link, record|
        super(link, record).merge(status: 'closed', context: {tab: 'details'}, anchor: 'details')
      end

      [@person, @other_person].each do |person|
        url = @view.action_link_url(@config.update.link, person)
        query = query_for(url)

        assert_equal 'closed', query['status']
        assert_equal({'tab' => 'details'}, query['context'])
        assert_equal 'details', URI.parse(url).fragment
      end
    end

    test "links to the same action keep their own explicit parameters with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      tags = ['one', 'two & three']
      statuses = %w[open closed]
      links = statuses.map do |status|
        link = @config.update.link.dup
        link.parameters = {status: status, context: {tab: status}, tags: tags}
        link
      end

      [@person, @other_person].each do |person|
        links.each do |link|
          url = @view.action_link_url(link, person)
          query = query_for(url)

          assert_equal "/people/#{person.id}/edit", URI.parse(url).path
          assert_equal link.parameters[:status], query['status']
          assert_equal({'tab' => link.parameters[:status]}, query['context'])
          assert_equal ['one', 'two & three'], query['tags']
        end
      end
    end

    test "dynamic member parameters override explicit and inherited values with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      link = @config.update.link.dup
      link.parameters = {status: 'static', source: 'member'}
      link.dynamic_parameters = lambda do |person|
        {status: person.first_name, context: {person: person.id}, tags: [person.first_name, 'two & three']}
      end

      [@person, @other_person].each do |person|
        url = @view.action_link_url(link, person)
        query = query_for(url)

        assert_equal "/people/#{person.id}/edit", URI.parse(url).path
        assert_equal person.first_name, query['status']
        assert_equal 'member', query['source']
        assert_equal({'person' => person.id.to_s}, query['context'])
        assert_equal [person.first_name, 'two & three'], query['tags']
      end
    end

    test "dynamic nested parameters can clear an inherited filter with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      link = nested_link
      link.parameters[:status] = 'static'
      first_person = @person
      link.dynamic_parameters = ->(person) { {status: person == first_person ? nil : 'closed'} }

      assert_not query_for(@view.action_link_url(link, @person)).key?('status')
      assert_equal 'closed', query_for(@view.action_link_url(link, @other_person))['status']
      assert_not query_for(@view.action_link_url(link, @person)).key?('status')
    end

    test "dynamic collection parameters run in the view context without a record with URL caching #{cache}" do
      @config.stubs(:cache_action_link_urls).returns(cache)
      link = ActiveScaffold::DataStructures::ActionLink.new('index', parameters: {status: 'static', source: 'collection'})
      link.dynamic_parameters = -> { {status: params[:status], context: {source: 'view context'}} }

      2.times do
        url = @view.action_link_url(link, nil)
        query = query_for(url)

        assert_equal '/people', URI.parse(url).path
        assert_equal 'open', query['status']
        assert_equal 'collection', query['source']
        assert_equal({'source' => 'view context'}, query['context'])
      end
    end
  end

  test 'cached member URLs are generated once and reused across records' do
    @view.expects(:url_for).once.returns('/people/--ID--/edit?status=open')

    assert_equal "/people/#{@person.id}/edit?status=open", @view.action_link_url(@config.update.link, @person)
    assert_equal "/people/#{@other_person.id}/edit?status=open", @view.action_link_url(@config.update.link, @other_person)
  end

  test 'dynamic parameters are evaluated for each record even after caching a static link' do
    @view.action_link_url(@config.update.link, @person)
    link = @config.update.link.dup
    link.dynamic_parameters = ->(person) { {status: person.first_name} }

    [@person, @other_person].each do |person|
      assert_equal person.first_name, query_for(@view.action_link_url(link, person))['status']
    end
  end

  test 'STI links select their controller even after caching a base model link' do
    link = @config.update.link
    @view.action_link_url(link, @person)
    special_person = SpecialPerson.create!(first_name: 'Special')

    assert_equal "/special_people/#{special_person.id}/edit", URI.parse(@view.action_link_url(link, special_person)).path
    assert_equal "/people/#{@other_person.id}/edit", URI.parse(@view.action_link_url(link, @other_person)).path
  end

  private

  def nested_link
    ActiveScaffold::DataStructures::ActionLink.new(
      'index', controller: '/buildings', type: :member, column: @config.columns[:buildings]
    )
  end

  def query_for(url)
    query = URI.parse(url).query
    keys = URI.decode_www_form(query.to_s).map(&:first).reject { |key| key.end_with?('[]') }
    assert_equal keys.uniq, keys, "Duplicate query parameters in #{url}"
    Rack::Utils.parse_nested_query(query)
  end
end
