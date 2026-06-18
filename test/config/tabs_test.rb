# frozen_string_literal: true

require 'test_helper'

module Config
  # Verifies that ProjectsController sets up association-based tabs and the
  # shared-tabs case where two subforms use the same category model but
  # different FK column names (:category vs :section).
  class ProjectsTabsTest < ActiveSupport::TestCase
    def setup
      @config = ProjectsController.active_scaffold_config
    end

    def test_create_columns_has_assignments_subgroup
      assert assignments_subgroup, 'Assignments subgroup not found in create columns'
    end

    def test_assignments_subgroup_tabbed_by_category
      assert_equal :category, assignments_subgroup.tabbed_by
    end

    def test_assignments_subgroup_contains_tasks
      assert assignments_subgroup.include?(:tasks)
    end

    def test_assignments_subgroup_contains_milestones
      assert assignments_subgroup.include?(:milestones)
    end

    def test_milestones_column_overrides_tabbed_by_to_section
      assert_equal :section, @config.columns[:milestones].options[:tabbed_by]
    end

    private

    def assignments_subgroup
      @config.create.columns.find do |c|
        c.is_a?(ActiveScaffold::DataStructures::ActionColumns) && c.tabbed_by
      end
    end
  end

  # Verifies that ProjectsByPriorityController sets up DB-column-based tabs
  # on the :priority column and targets the Project model.
  class ProjectsByPriorityTabsTest < ActiveSupport::TestCase
    def setup
      @config = ProjectsByPriorityController.active_scaffold_config
    end

    def test_model_is_project
      assert_equal Project, @config.model
    end

    def test_create_columns_has_tasks_by_priority_subgroup
      assert tasks_subgroup, 'Tasks by Priority subgroup not found in create columns'
    end

    def test_tasks_by_priority_subgroup_tabbed_by_priority
      assert_equal :priority, tasks_subgroup.tabbed_by
    end

    def test_tasks_by_priority_subgroup_contains_tasks
      assert tasks_subgroup.include?(:tasks)
    end

    private

    def tasks_subgroup
      @config.create.columns.find do |c|
        c.is_a?(ActiveScaffold::DataStructures::ActionColumns) && c.tabbed_by
      end
    end
  end
end