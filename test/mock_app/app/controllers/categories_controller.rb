class CategoriesController < ApplicationController
  active_scaffold do |conf|
    conf.subform.columns = [:name]
    conf.delete.refresh_list = true
  end
end
