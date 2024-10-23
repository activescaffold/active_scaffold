class FloorsController < ApplicationController
  active_scaffold do |conf|
    conf.columns << :number_required
    conf.subform.columns = [:building, :number, :number_required, :tenant]
    conf.columns[:address].form_ui = :select
    conf.columns[:building].form_ui = :select
    conf.columns[:tenant].form_ui = :select
  end
end
