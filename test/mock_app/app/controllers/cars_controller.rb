class CarsController < ApplicationController
  active_scaffold do
    columns[:model].inplace_edit = true
  end
end
