# frozen_string_literal: true

class ContactsController < ApplicationController
  active_scaffold do |conf|
    conf.actions << :field_search
    conf.list.always_show_search = :search
    conf.field_search.columns = %i[first_name last_name birthday]
    conf.field_search.link.parameters = {kind: :field_search}
  end
end
