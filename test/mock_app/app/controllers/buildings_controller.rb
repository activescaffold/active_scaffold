class BuildingsController < ApplicationController
  active_scaffold do |conf|
    conf.columns.exclude :files
    conf.subform.columns.exclude :tenants
  end
end
