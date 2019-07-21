class PeopleController < ApplicationController
  active_scaffold do |conf|
    conf.columns[:buildings].includes = nil
    conf.columns[:buildings].associated_limit = 0
  end
end
