# frozen_string_literal: true

require 'test_helper'

class GroupedSearchAuthorizationTest < ActiveSupport::TestCase
  class SearchController
    include ActiveScaffold::Actions::FieldSearch::InstanceMethods

    attr_accessor :search_params, :active_scaffold_config
  end

  setup do
    @controller = SearchController.new
    @field_search = stub(group_options: [['Name', :first_name], ['Year', 'created_at#year']])
    @controller.active_scaffold_config = stub(field_search: @field_search)
  end

  test 'configured grouping values are accepted' do
    @controller.search_params = {'active_scaffold_group' => 'first_name'}

    assert @controller.send(:grouped_search?)
    assert_equal 'first_name', @controller.send(:search_group_name)
    assert_nil @controller.send(:search_group_function)
  end

  test 'configured grouping functions are accepted' do
    @controller.search_params = {'active_scaffold_group' => 'created_at#year'}

    assert @controller.send(:grouped_search?)
    assert_equal 'created_at', @controller.send(:search_group_name)
    assert_equal 'year', @controller.send(:search_group_function)
  end

  test 'unconfigured columns functions and SQL are rejected' do
    ['last_name', 'created_at', 'created_at#month', '(SELECT email FROM users LIMIT 1)', 'Name'].each do |group|
      @controller.search_params = {'active_scaffold_group' => group}

      assert_not @controller.send(:grouped_search?), group
      assert_nil @controller.send(:search_group_name)
      assert_nil @controller.send(:search_group_function)
    end
  end

  test 'grouping is disabled without configured options' do
    @controller.search_params = {'active_scaffold_group' => 'first_name'}
    @field_search.stubs(:group_options).returns(nil)

    assert_not @controller.send(:grouped_search?)
  end

  test 'hash and label-only options match the generated select values' do
    @controller.search_params = {'active_scaffold_group' => 'first_name'}
    @field_search.stubs(:group_options).returns({'Name' => :first_name})
    assert @controller.send(:grouped_search?)

    @field_search.stubs(:group_options).returns([:first_name])
    assert @controller.send(:grouped_search?)
  end

  test 'absent and empty grouping do not enable grouping' do
    [nil, {}, {'active_scaffold_group' => ''}].each do |search|
      @controller.search_params = search
      assert_not @controller.send(:grouped_search?)
    end
  end
end
