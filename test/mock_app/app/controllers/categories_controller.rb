class CategoriesController < ApplicationController
  active_scaffold do |conf|
    conf.subform.columns = [:name]
  end
end
