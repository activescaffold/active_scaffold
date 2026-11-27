# frozen_string_literal: true

require 'test_helper'

class NestedRoutesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    @first = Person.create!(first_name: 'First parent')
    @second = Person.create!(first_name: 'Second parent')
    @first_building = Building.create!(name: 'First building', owner: @first, floors_count: 1)
    @other_building = Building.create!(name: 'Other building', owner: @first)
    @second_building = Building.create!(name: 'Second building', owner: @second)
    @car = Car.create!(model: 'First car', person: @first)
  end

  teardown do
    RequestStore.clear!
  end

  [true, false].each do |cache| # rubocop:disable Metrics/BlockLength -- exercise both URL generation modes
    test "collection links use nested routes and exclude filters with caching #{cache}" do
      get '/nested_routes/people', params: {status: 'active', cache_urls: cache.to_s}

      assert_response :success
      first_link = association_link(@first, 'buildings')
      second_link = association_link(@second, 'buildings')
      assert_equal "/nested_routes/people/#{@first.id}/buildings", URI.parse(first_link).path
      assert_equal "/nested_routes/people/#{@second.id}/buildings", URI.parse(second_link).path
      assert_not query_for(first_link).key?('status')
      assert_not query_for(second_link).key?('status')

      get first_link
      assert_response :success
      assert_includes response.body, 'First building'
      assert_not_includes response.body, 'Second building'
    end

    test "member links preserve nested parent and child IDs with caching #{cache}" do
      assert_building_links(@first, [@first_building, @other_building], cache)
      assert_building_links(@second, [@second_building], cache)
    end

    test "singular links handle existing and absent children with caching #{cache}" do
      get '/nested_routes/people', params: {status: 'active', cache_urls: cache.to_s}

      assert_response :success
      edit_link = association_link(@first, 'car')
      new_link = association_link(@second, 'car')
      assert_equal "/nested_routes/people/#{@first.id}/car/#{@car.id}/edit", URI.parse(edit_link).path
      assert_equal "/nested_routes/people/#{@second.id}/car/new", URI.parse(new_link).path
      assert_not query_for(edit_link).key?('status')
      assert_not query_for(new_link).key?('status')
      assert_not_includes new_link, '--CHILD_ID--'

      get edit_link
      assert_response :success
      get new_link
      assert_response :success
    end

    test "singular listing edit links return to the nested listing with caching #{cache}" do
      path = "/nested_routes/people/#{@first.id}/car"
      get path, params: {cache_urls: cache.to_s}

      assert_response :success
      link = css_select('a.edit.as_action').first
      assert link, 'Missing edit link'
      query = query_for(link['href'])
      assert_equal "#{path}?cache_urls=#{cache}", query['return_to']
      assert ActiveScaffold::ParameterSigning.valid_signature?(query['return_to'], query['return_to_signature'], purpose: :return_to)

      get link['href']
      assert_response :success
      assert_select 'a.as_cancel[href=?]', query['return_to']
    end

    test "explicit child filters and structured link parameters survive nested navigation with caching #{cache}" do
      get '/nested_routes/people', params: {status: 'active', cache_urls: cache.to_s}

      assert_response :success
      links = [@first, @second].map { |person| member_link(person, 'Selected buildings') }
      links.zip([@first, @second]).each do |link, person|
        assert_equal "/nested_routes/people/#{person.id}/buildings", URI.parse(link).path
        assert_child_link_parameters(query_for(link))
      end

      get links.first
      assert_response :success
      names = css_select('tbody.records .name-column').map { |node| node.text.strip }
      assert_equal ['First building'], names
      edit_link = css_select('a.edit.as_action').first['href']
      assert_child_link_parameters(query_for(edit_link))
      assert_filter_switch_keeps_other_parameters('All statuses', 'status', 'all', 'occupancy', 'occupied')
      assert_filter_switch_keeps_other_parameters('All occupancy', 'occupancy', 'all', 'status', 'first')

      get edit_link
      assert_response :success
      assert_child_link_parameters(query_for(css_select('form.as_form').first['action']))
    end

    test "dynamic nested filters are evaluated for each parent with caching #{cache}" do
      get '/nested_routes/people', params: {status: 'active', cache_urls: cache.to_s}

      assert_response :success
      first_link = member_link(@first, 'Dynamic buildings')
      second_link = member_link(@second, 'Dynamic buildings')
      assert_equal 'first', query_for(first_link)['status']
      assert_equal 'all', query_for(second_link)['status']
      [first_link, second_link].each do |link|
        query = query_for(link)
        assert_equal 'occupied', query['occupancy']
        assert_equal 'dynamic', query['source']
      end
      assert_equal "/nested_routes/people/#{@first.id}/buildings", URI.parse(first_link).path
      assert_equal "/nested_routes/people/#{@second.id}/buildings", URI.parse(second_link).path
    end
  end

  private

  def person_row(person)
    row = css_select('tbody.records > tr.record').find { |node| node.at_css('.first_name-column')&.text&.include?(person.first_name) }
    assert row, "Missing row for #{person.first_name}"
    row
  end

  def association_link(person, association)
    link = person_row(person).at_css(".#{association}-column a.as_action")
    assert link, "Missing #{association} link for #{person.first_name}"
    link['href']
  end

  def member_link(person, label)
    link = person_row(person).css('a').find { |node| node.text.strip == label }
    assert link, "Missing #{label} link for #{person.first_name}"
    link['href']
  end

  def assert_child_link_parameters(query)
    assert_equal 'first', query['status']
    assert_equal 'occupied', query['occupancy']
    assert_equal({'source' => 'parent link'}, query['context'])
    assert_equal ['one', 'two & three'], query['tags']
  end

  def assert_filter_switch_keeps_other_parameters(label, changed_key, changed_value, kept_key, kept_value)
    link = css_select('a').find { |node| node.text.strip == label }
    assert link, "Missing #{label} filter option"
    query = query_for(link['href'])
    assert_equal changed_value, query[changed_key]
    assert_equal kept_value, query[kept_key]
    assert_equal({'source' => 'parent link'}, query['context'])
    assert_equal ['one', 'two & three'], query['tags']
  end

  def assert_building_links(person, buildings, cache)
    get "/nested_routes/people/#{person.id}/buildings", params: {cache_urls: cache.to_s}

    assert_response :success
    links = css_select('a.edit.as_action').pluck('href')
    buildings.each do |building|
      link = links.find { |url| URI.parse(url).path.end_with?("/#{building.id}/edit") }
      assert link, 'Missing edit link'
      assert_equal "/nested_routes/people/#{person.id}/buildings/#{building.id}/edit", URI.parse(link).path
      query_for(link)
      get link
      assert_response :success
      assert_select 'input[value=?]', building.name
    end
  end

  def query_for(url)
    uri = URI.parse(url)
    keys = URI.decode_www_form(uri.query.to_s).map(&:first).reject { |key| key.end_with?('[]') }
    assert_equal keys.uniq, keys, "Duplicate query parameters in #{url}"
    Rack::Utils.parse_nested_query(uri.query)
  end
end
