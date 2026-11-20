# frozen_string_literal: true

require_relative 'test_helper'

class InstalledSelectBridgesTest < InstalledBridgeTestCase
  def test_installed_select_bridges_build_select_conditions
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)

    %i[country chosen multi_chosen].each do |search_ui|
      column.search_ui = search_ui

      assert_equal ['"people"."first_name" in (?)', %w[Alice Bob]],
                   ClassWithFinder.condition_for_column(column, ['Alice', '', 'Bob'], :full, {}), search_ui
      assert_equal ['"people"."first_name" >= ?', 'M'],
                   ClassWithFinder.condition_for_column(column, {opt: '>=', from: 'M'}, :full, {}), search_ui
      assert_nil ClassWithFinder.condition_for_column(column, [], :full, {}), search_ui
    end
  end
end
