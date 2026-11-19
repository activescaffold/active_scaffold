# frozen_string_literal: true

class CarsController < ApplicationController
  before_action :configure_request

  active_scaffold do |conf|
    columns[:model].inplace_edit = true
    conf.columns[:model].calculate = :count
  end

  protected

  def configure_request
    return unless params[:inplace_edit_update]

    active_scaffold_config.columns.override(:model) do |column|
      column.inplace_edit_update = params.expect(:inplace_edit_update).to_sym
      column.update_columns = [:brand] if column.inplace_edit_update == :columns
    end
  end
end
