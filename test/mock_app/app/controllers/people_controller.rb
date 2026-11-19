class PeopleController < ApplicationController
  active_scaffold do |conf|
    conf.columns.exclude :files
    conf.columns[:buildings].includes = nil
    conf.columns[:buildings].associated_limit = 0
    conf.create.columns.exclude :address, :home
  end

  def forbidden
    raise ActiveScaffold::ActionNotAllowed, 'forbidden by integration test'
  end
end
