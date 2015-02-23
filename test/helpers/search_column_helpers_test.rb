require 'test_helper'

class SearchColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::SearchColumnHelpers

  def setup
    @column = ActiveScaffold::DataStructures::Column.new(:adult, Person)
    @record = Person.new
  end

  def test_choices_for_boolean_search_ui
    assert_dom_equal "<select name=\"search[adult]\"><option value=\"\">- select -</option>\n<option value=\"true\">True</option>\n<option value=\"false\" selected=\"selected\">False</option></select>", active_scaffold_search_boolean(@column, :object => @record, :name => 'search[adult]', :value => '0')
  end
end
