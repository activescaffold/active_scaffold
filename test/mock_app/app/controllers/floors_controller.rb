class FloorsController < ApplicationController
  active_scaffold do |conf|
    conf.columns << :number_required
    conf.subform.columns << :number_required
  end
end
