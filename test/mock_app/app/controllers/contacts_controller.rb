# frozen_string_literal: true

class ContactsController < ApplicationController
  before_action :configure_request

  active_scaffold do |conf|
    conf.actions << :field_search
    conf.list.always_show_search = :search
    conf.field_search.columns = %i[first_name last_name birthday]
    conf.field_search.link.parameters = {kind: :field_search}
    conf.field_search.default_params = proc do
      {first_name: {opt: '%?%', from: 'Alice'}} if params[:apply_default_search]
    end
  end

  protected

  def configure_request
    return unless params[:multiple_field_search]

    columns = active_scaffold_config.field_search.override_columns
    columns.layout = :multiple
    columns[0] = %i[first_name last_name]
    columns[1] = [:birthday]
    active_scaffold_config.field_search.optional_columns = %i[last_name birthday]
  end
end
