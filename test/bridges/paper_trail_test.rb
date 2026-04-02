# frozen_string_literal: true

require 'test_helper'
ActiveScaffold::Bridges::PaperTrail.prepare

class PaperTrailTest < ActionController::TestCase
  tests AddressesController

  def test_deleted_route
    with_routing do |map|
      map.draw do
        concern :active_scaffold, ActiveScaffold::Routing::Basic.new
        resources :addresses, concerns: :active_scaffold
      end
      assert_routing '/addresses/deleted', controller: 'addresses', action: 'deleted'
    end
  end
end
