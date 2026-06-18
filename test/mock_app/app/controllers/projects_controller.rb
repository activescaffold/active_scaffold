# Demonstrates two tabs use cases:
# 1. Association tabs: tasks subform split by belongs_to :category
# 2. Shared tabs: tasks and milestones share the same tab set (both use Category),
#    but milestones use a different FK column name (:section instead of :category)
class ProjectsController < ApplicationController
  active_scaffold do |conf|
    %i[create update].each do |action|
      conf.send(action).columns.add_subgroup('Assignments') do |group|
        group.add :tasks, :milestones
        group.tabbed_by = :category
      end
    end
    # milestones use :section (belongs_to :section, class_name: 'Category') instead of :category
    conf.columns[:milestones].options[:tabbed_by] = :section
  end
end