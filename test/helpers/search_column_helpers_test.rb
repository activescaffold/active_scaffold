# frozen_string_literal: true

require 'test_helper'

class SearchColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormUiHelpers
  include ActiveScaffold::Helpers::SearchColumnHelpers

  def setup
    @column = ActiveScaffold::DataStructures::Column.new(:adult, Person)
    @record = Person.new
  end

  def test_choices_for_boolean_search_ui
    opts = {object: @record, name: 'search[adult]', value: '0'}
    assert_dom_equal "<select name=\"search[adult]\"><option value=\"\">- select -</option>\n<option value=\"true\">True</option>\n<option value=\"false\" selected=\"selected\">False</option></select>", active_scaffold_search_boolean(@column, opts)
  end

  def test_multi_select_search_uses_explicit_empty_association_conditions
    association = stub
    @column.stubs(:association).returns(association)
    stubs(:association_helper_method).with(association, :sorted_association_options_find).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(association, {}, @record).returns([])

    active_scaffold_search_multi_select(@column, {object: @record, value: nil})
  end

  def test_select_search_uses_explicit_empty_association_conditions
    association = stub(belongs_to?: false)
    @column.stubs(:association).returns(association)
    stubs(:association_helper_method).with(association, :sorted_association_options_find).returns(:sorted_association_options_find)
    expects(:sorted_association_options_find).with(association, {}, @record).returns([])

    active_scaffold_search_select(@column, {object: @record, value: nil}, {}, ui_options: {null_comparators: false})
  end
end
