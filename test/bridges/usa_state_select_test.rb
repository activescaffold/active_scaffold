# frozen_string_literal: true

require 'test_helper'

ActiveScaffold::Bridges::UsaStateSelect.install

class UsaStateSelectTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::UsaStateSelectHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::UsaStateSelectOptionsHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::FormColumnHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::SearchColumnHelpers

  def test_form_helper_renders_states_and_priority_states
    column = ActiveScaffold::Config::Core.new(:company).columns[:name]
    column.options[:priority] = [%w[California CA]]

    html = active_scaffold_input_usa_state(
      column,
      {name: 'record[name]', id: 'record_name', object: Company.new}
    )

    assert_includes html, '<select'
    assert_includes html, '>California</option>'
    assert_includes html, 'disabled="disabled"'
    assert_includes html, '>-------------</option>'
    assert_operator html.index('>California</option>'), :<, html.index('>Alabama</option>')
  end

  def test_search_helper_selects_the_current_value
    column = ActiveScaffold::Config::Core.new(:company).columns[:name]

    html = active_scaffold_search_usa_state(
      column,
      {name: 'search[name]', id: 'search_name', value: 'NY', object: Company.new}
    )

    assert_includes html, 'selected="selected" value="NY"'
  end
end
