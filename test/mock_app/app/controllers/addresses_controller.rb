# frozen_string_literal: true

class AddressesController < ApplicationController
  active_scaffold do |conf|
    conf.actions << :mark
  end
end
