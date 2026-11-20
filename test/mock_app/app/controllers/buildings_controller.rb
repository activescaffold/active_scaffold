# frozen_string_literal: true

class BuildingsController < ApplicationController
  active_scaffold do |conf|
    conf.columns.exclude :files
    conf.columns[:floors_count].calculate = :sum
    conf.update.columns = %i[name floors]
    conf.subform.columns = [:name]
    conf.subform.columns.add_subgroup('Counts') do |group|
      group.add :floors_count
    end
  end
end
