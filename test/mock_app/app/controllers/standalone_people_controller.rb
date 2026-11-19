# frozen_string_literal: true

class StandalonePeopleController < ApplicationController
  active_scaffold :person do |conf|
    conf.actions.exclude :list, :nested
    conf.update.columns = %i[first_name last_name]
  end
end
