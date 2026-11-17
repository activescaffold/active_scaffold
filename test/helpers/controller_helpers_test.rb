# frozen_string_literal: true

require 'test_helper'

class ControllerHelpersTest < ActiveSupport::TestCase
  include ActiveScaffold::Helpers::ControllerHelpers

  def setup
    @params_for = nil
    @search_params = 'active search'
    stubs(:params).returns(ActionController::Parameters.new(controller: 'model_stubs', search: @search_params))
    stubs(:controller_path).returns('model_stubs')
    stubs(:active_scaffold_config).returns(stub(store_user_settings: false, actions: []))
  end

  def test_params_for_adds_active_search_when_search_is_not_specified
    assert_equal 'active search', params_for[:search]
  end

  def test_params_for_does_not_add_active_search_when_search_is_explicitly_removed
    assert_nil params_for(search: nil)[:search]
  end

  private

  attr_reader :search_params

  def controller_params?(_value)
    false
  end
end
