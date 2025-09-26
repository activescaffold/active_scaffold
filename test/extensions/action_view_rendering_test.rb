# frozen_string_literal: true

require 'test_helper'

class ActionViewRenderingTest < ActionController::TestCase
  setup do
    @controller = PeopleController.new
  end

  test 'render :super twice' do
    get :index
    assert_select '#controller', 1
    assert_select '#app', 1
  end

  test 'render partial override with render :super twice' do
    get :new
    assert_select '#first_name_field', 1
    assert_select '#controller_form', 1
    assert_select '#app_form', 1
  end
end
