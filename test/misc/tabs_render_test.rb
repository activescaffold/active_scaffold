# frozen_string_literal: true

require 'test_helper'

class ProjectsTabsRenderTest < ActionDispatch::IntegrationTest

  setup do
    [Task, Milestone, Category, Project].each(&:delete_all)
    @cat1 = Category.create!(name: 'Frontend')
    @cat2 = Category.create!(name: 'Backend')
  end

  teardown do
    [Task, Milestone, Category, Project].each(&:delete_all)
  end

  test 'new project form renders category select and add-tab link' do
    get '/projects/new'
    assert_select 'select.category-input' do
      assert_select 'option[value=?]', @cat1.id.to_s, text: @cat1.to_label
      assert_select 'option[value=?]', @cat2.id.to_s, text: @cat2.to_label
    end
    assert_select '.add-tab'
  end

  test 'edit form renders tab nav items for each category used in tasks' do
    project = Project.create!(name: 'My Project')
    Task.create!(project: project, category: @cat1, name: 'A')
    Task.create!(project: project, category: @cat2, name: 'B')

    get "/projects/#{project.id}/edit"
    assert_select 'ul.nav.nav-tabs'
    assert_select '.nav-item .nav-link', text: @cat1.to_label
    assert_select '.nav-item .nav-link', text: @cat2.to_label
  end
end

class ProjectsByPriorityTabsRenderTest < ActionDispatch::IntegrationTest
  setup do
    [Task, Category, Project].each(&:delete_all)
    @cat = Category.create!(name: 'Default')
  end

  teardown do
    [Task, Category, Project].each(&:delete_all)
    RequestStore.clear!
  end

  test 'new form renders priority select and add-tab link' do
    get '/projects_by_priority/new'
    assert_select 'select.priority-input' do
      Task::PRIORITIES.each do |label, value|
        assert_select 'option[value=?]', value, text: label
      end
    end
    assert_select '.add-tab'
  end

  test 'edit form renders tab nav for tasks with different priorities' do
    project = Project.create!(name: 'P')
    # category must be set on tasks so the nested category subform does not
    # build a blank Category record, which would otherwise recurse through
    # Category#milestones → Milestone#project → ProjectsByPriorityController tasks.
    Task.create!(project: project, priority: 'high', name: 'H', category: @cat)
    Task.create!(project: project, priority: 'low', name: 'L', category: @cat)

    get "/projects_by_priority/#{project.id}/edit"
    assert_select 'ul.nav.nav-tabs'
    assert_select '.nav-item .nav-link', text: 'High'
    assert_select '.nav-item .nav-link', text: 'Low'
  end
end
