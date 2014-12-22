require 'test_helper'

class RenderTest < ActionController::TestCase
  tests AddressesController
  test 'render activescaffold views' do
    get :index
    assert_template 'list'
  end
end
