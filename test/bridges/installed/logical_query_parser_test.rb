# frozen_string_literal: true

require_relative 'test_helper'

class InstalledLogicalQueryParserBridgeTest < InstalledBridgeTestCase
  def test_logical_query_parser_bridge_filters_records_for_each_comparator
    assert_installed_bridge(:logical_query_parser)
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    column.search_ui = :select
    column.logical_search = %i[first_name last_name]
    column.search_sql = nil
    ada_lovelace = Person.create!(first_name: 'Ada', last_name: 'Lovelace')
    ada_byron = Person.create!(first_name: 'Ada', last_name: 'Byron')
    grace_hopper = Person.create!(first_name: 'Grace', last_name: 'Hopper')

    all_tokens = ClassWithFinder.condition_for_column(
      column, {opt: 'all_tokens', from: 'Ada Lovelace'}, :full, {}
    )
    any_token = ClassWithFinder.condition_for_column(
      column, {opt: 'any_token', from: 'Byron Grace'}, :full, {}
    )
    logical = ClassWithFinder.condition_for_column(
      column, {opt: 'logical', from: 'Ada AND NOT Byron'}, :full, {}
    )

    assert_equal %w[all_tokens any_token logical], ActiveScaffold::Finder.logical_comparators
    assert_predicate column, :searchable?
    assert_equal [ada_lovelace.id], all_tokens.pluck(:id)
    assert_equal [ada_byron.id, grace_hopper.id].sort, any_token.pluck(:id).sort
    assert_equal [ada_lovelace.id], logical.pluck(:id)

    comparators = active_scaffold_search_range_comparator_options(column).to_h.invert
    assert_equal 'All keywords', comparators['all_tokens']
    assert_equal 'Any keyword', comparators['any_token']
    assert_equal 'Logical', comparators['logical']
  ensure
    Person.delete_all
  end
end
