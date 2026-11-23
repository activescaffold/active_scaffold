# frozen_string_literal: true

require 'test_helper'

class SubformActionTest < ActionController::TestCase
  tests ProjectsController

  test 'assigns a tab through a belongs-to association' do
    category = Category.create!(name: 'Backend')
    task = Task.new
    parent_column = @controller.active_scaffold_config.columns[:tasks]

    @controller.send(:assign_tabbed_by, task, parent_column, :category, category.id, nil)

    assert_equal category, task.category
  end

  test 'assigns a scalar tab value when there is no association' do
    task = Task.new
    parent_column = @controller.active_scaffold_config.columns[:tasks]

    @controller.send(:assign_tabbed_by, task, parent_column, :priority, 'high', nil)

    assert_equal 'high', task.priority
  end

  test 'builds an associated record with its requested tab' do
    category = Category.create!(name: 'Backend')
    options = @controller.signed_tab_selection_options(
      child_association: 'tasks', generated_id: 'new-project',
      tabbed_by: 'category', value: category.id.to_s
    )

    @controller.params = ActionController::Parameters.new(options)
    @controller.send(:do_edit_associated)

    task = @controller.instance_variable_get(:@record)
    assert_equal category, task.category
    assert_equal category.id.to_s, @controller.instance_variable_get(:@tab_id)
  end
end
