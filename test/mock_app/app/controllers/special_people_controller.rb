class SpecialPeopleController < ApplicationController
  active_scaffold :special_person do |conf|
    conf.create.action_after_create = :edit
  end
end
