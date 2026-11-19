# frozen_string_literal: true

class CarsController < ApplicationController
  active_scaffold do |conf|
    columns[:model].inplace_edit = true
    conf.columns[:model].calculate = :count
  end
end
