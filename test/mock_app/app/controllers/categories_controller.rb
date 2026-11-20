class CategoriesController < ApplicationController
  active_scaffold do |conf|
    conf.subform.columns = [:name]
    conf.sti_children = [:special_category]
    conf.create.refresh_list = true
    conf.delete.refresh_list = true
  end
end
