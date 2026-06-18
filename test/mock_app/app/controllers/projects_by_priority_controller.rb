# Demonstrates tabs by a DB column with fixed options (:select form_ui).
# Tasks in the project subform are split into tabs by their :priority string column.
# active_scaffold_tab_options_for_project is overridden here to supply the select
# options, because the default implementation only handles association-based tabs.
class ProjectsByPriorityController < ApplicationController
  active_scaffold :project do |conf|
    conf.label = 'Projects (Tasks by Priority)'
    %i[create update].each do |action|
      conf.send(action).columns.add_subgroup('Tasks by Priority') do |group|
        group.add :tasks
        group.tabbed_by = :priority
      end
      # milestones are not part of this view; keep them out of the form.
      conf.send(action).columns.exclude :milestones
    end
  end
end