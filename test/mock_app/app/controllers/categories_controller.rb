class CategoriesController < ApplicationController
  before_action :configure_request

  active_scaffold do |conf|
    conf.subform.columns = [:name]
    conf.sti_children = [:special_category]
    conf.create.refresh_list = true
    conf.delete.refresh_list = true
  end

  protected

  def configure_request
    active_scaffold_config.update.multipart = true if params[:multipart_form]
  end
end
