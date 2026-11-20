class TasksController < ApplicationController
  active_scaffold do |conf|
    conf.columns[:priority].form_ui = :select
    conf.columns[:priority].options = {options: Task::PRIORITIES}
    conf.columns[:category].form_ui = :select
    conf.columns[:category].options[:add_new] = true
    conf.show.columns = [:name]
    conf.show.columns.add_subgroup('Details') do |group|
      group.add :priority
    end
  end
end
