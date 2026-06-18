class MilestonesController < ApplicationController
  active_scaffold do |conf|
    conf.columns[:section].form_ui = :select
  end
end