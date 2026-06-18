class TasksController < ApplicationController
  active_scaffold do |conf|
    conf.columns[:priority].form_ui = :select
    conf.columns[:priority].options = {options: Task::PRIORITIES}
    conf.columns[:category].form_ui = :select
  end
end