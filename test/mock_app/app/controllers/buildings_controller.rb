# frozen_string_literal: true

class BuildingsController < ApplicationController
  active_scaffold do |conf|
    conf.columns.exclude :files
    conf.columns[:floors_count].calculate = :sum
    conf.subform.columns.exclude :tenants
  end
end
