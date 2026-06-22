# frozen_string_literal: true

require 'test_helper'

class TabsHelpersTest < ActionView::TestCase
  # helper_method must be a no-op before including ControllerHelpers so that
  # the included hook does not register recursive delegates in a view test context.
  def self.helper_method(*); end

  include ActiveScaffold::Helpers::TabsHelpers
  include ActiveScaffold::Helpers::ControllerHelpers
  include ActiveScaffold::Helpers::ViewHelpers

  def setup
    [Task, Milestone, Category, Project].each(&:delete_all)
    @cat1 = Category.create!(name: 'Feature')
    @cat2 = Category.create!(name: 'Bug')
    @project = Project.new
  end

  def teardown
    [Task, Milestone, Category, Project].each(&:delete_all)
  end

  # Real ActionColumns subgroups from the actual controller configs.
  def assignments_group
    ProjectsController.active_scaffold_config.create.columns.find do |c|
      c.is_a?(ActiveScaffold::DataStructures::ActionColumns) && c.tabbed_by
    end
  end

  def priority_group
    ProjectsByPriorityController.active_scaffold_config.create.columns.find do |c|
      c.is_a?(ActiveScaffold::DataStructures::ActionColumns) && c.tabbed_by
    end
  end

  # --- active_scaffold_current_tabs ---

  def test_current_tabs_with_association_tabs_returns_category_pairs
    @project.tasks.build(category: @cat1)
    @project.tasks.build(category: @cat2)

    result = active_scaffold_current_tabs(assignments_group, @project, [])

    assert_includes result, [@cat1, @cat1.id.to_s]
    assert_includes result, [@cat2, @cat2.id.to_s]
    assert_equal 2, result.size
  end

  def test_current_tabs_with_association_tabs_deduplicates_repeated_values
    @project.tasks.build(category: @cat1)
    @project.tasks.build(category: @cat1)

    result = active_scaffold_current_tabs(assignments_group, @project, [])

    assert_equal 1, result.size
  end

  def test_current_tabs_with_db_column_returns_raw_values
    @project.tasks.build(priority: 'high')
    @project.tasks.build(priority: 'low')
    @project.tasks.build(priority: 'high')

    tab_options = Task::PRIORITIES.map { |label, value| [label, value, nil] }
    result = active_scaffold_current_tabs(priority_group, @project, tab_options)

    assert_includes result, 'high'
    assert_includes result, 'low'
    assert_equal 2, result.size
  end

  def test_current_tabs_with_db_column_unknown_value_returns_raw_value
    @project.tasks.build(priority: 'urgent')

    result = active_scaffold_current_tabs(priority_group, @project, [])

    assert_includes result, 'urgent'
    assert_equal 1, result.size
  end

  def test_current_tabs_shared_tabs_merges_both_subforms_via_different_fk_columns
    # tasks use :category, milestones use :section — both point to the same Category record
    @project.tasks.build(category: @cat1)
    @project.milestones.build(section: @cat1)

    result = active_scaffold_current_tabs(assignments_group, @project, [])

    assert_equal 1, result.size
    assert_includes result, [@cat1, @cat1.id.to_s]
  end

  def test_current_tabs_returns_empty_set_when_no_associated_records
    result = active_scaffold_current_tabs(assignments_group, @project, [])
    assert result.empty?
  end

  # --- active_scaffold_input_for_tabbed ---

  def test_input_for_tabbed_generates_select_with_correct_class_and_id
    tab_options = [[@cat1.to_label, @cat1.id, @cat1], [@cat2.to_label, @cat2.id, @cat2]]
    html = active_scaffold_input_for_tabbed(assignments_group, nil, 'my_section', tab_options, [])

    assert_match(/class="category-input"/, html)
    assert_match(/id="my_section_input"/, html)
    assert_match(/value="#{@cat1.id}"/, html)
    assert_match(/value="#{@cat2.id}"/, html)
    assert_no_match(/display: none/, html)
  end

  def test_input_for_tabbed_hides_already_used_tab_options
    tab_options = [[@cat1.to_label, @cat1.id, @cat1], [@cat2.to_label, @cat2.id, @cat2]]
    html = active_scaffold_input_for_tabbed(assignments_group, nil, 'sec', tab_options, [@cat1])

    assert_match(/value="#{@cat1.id}"[^>]*display: none/, html)
    assert_no_match(/value="#{@cat2.id}"[^>]*display: none/, html)
  end

  def test_input_for_tabbed_uses_raw_value_as_option_value_for_db_column_tabs
    tab_options = Task::PRIORITIES.map { |label, value| [label, value, nil] }
    html = active_scaffold_input_for_tabbed(priority_group, nil, 'tasks_section', tab_options, [])

    assert_match(/class="priority-input"/, html)
    assert_match(/value="low"/, html)
    assert_match(/value="medium"/, html)
    assert_match(/value="high"/, html)
  end
end

# Tests that the ProjectsByPriorityHelper override is correctly dispatched to
# when active_scaffold_tab_options is resolved via override_helper_per_model.
class ProjectsByPriorityHelperTest < ActionView::TestCase
  def self.helper_method(*); end

  include ActiveScaffold::Helpers::ViewHelpers
  include ProjectsByPriorityHelper

  def priority_column
    ProjectsByPriorityController.active_scaffold_config.create.columns.find do |c|
      c.is_a?(ActiveScaffold::DataStructures::ActionColumns) && c.tabbed_by == :priority
    end
  end

  def tab_options_for(column, record)
    send(override_helper_per_model(:active_scaffold_tab_options, Project), column, record)
  end

  def test_returns_one_entry_per_priority_level
    assert_equal Task::PRIORITIES.size, tab_options_for(priority_column, nil).size
  end

  def test_each_entry_has_label_value_and_nil_record
    tab_options_for(priority_column, nil).each do |(label, value, record)|
      assert_kind_of String, label
      assert_kind_of String, value
      assert_nil record
    end
  end

  def test_priority_values_match_task_priorities_constant
    values = tab_options_for(priority_column, nil).map { |(_label, value, _record)| value }
    assert_equal Task::PRIORITIES.map(&:last), values
  end
end
