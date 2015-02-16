require 'test_helper'
ActiveScaffold::Bridges::PaperTrail.prepare

class PaperTrailTest < ActionController::TestCase
  tests AddressesController

  def test_deleted_route
    with_routing do |map|
      map.draw do
        resources :addresses do
          as_routes
        end
      end
      assert_routing '/addresses/deleted', :controller => 'addresses', :action => 'deleted'
    end
  end
end
