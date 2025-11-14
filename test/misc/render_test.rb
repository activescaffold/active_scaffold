# frozen_string_literal: true

require 'test_helper'

class RenderTest < ActionController::TestCase
  tests AddressesController
  test 'render activescaffold views' do
    get :index
    assert_select 'div.active-scaffold'
  end
end
