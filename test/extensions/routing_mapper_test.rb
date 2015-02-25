require 'test_helper'

class RoutingMapperTest < ActionController::TestCase
  test 'rails routes' do
    assert_routing 'addresses', :controller => 'addresses', :action => 'index'
    assert_routing 'addresses/1', :controller => 'addresses', :action => 'show', :id => '1'
    assert_routing 'addresses/1/list', :controller => 'addresses', :action => 'index', :id => '1'
    assert_routing 'addresses/1/edit', :controller => 'addresses', :action => 'edit', :id => '1'
    assert_routing({:method => :put, :path => 'addresses/1'}, {:controller => 'addresses', :action => 'update', :id => '1'})
    assert_routing({:method => :delete, :path => 'addresses/1'}, {:controller => 'addresses', :action => 'destroy', :id => '1'})
    assert_routing({:method => :post, :path => 'addresses'}, {:controller => 'addresses', :action => 'create'})
  end

  test 'active scaffold routes' do
    assert_routing 'addresses/show_search', :controller => 'addresses', :action => 'show_search'
    assert_routing({:method => 'post', :path => 'addresses/render_field'}, {:controller => 'addresses', :action => 'render_field'})
    assert_routing({:method => 'post', :path => 'addresses/2/render_field'}, {:controller => 'addresses', :action => 'render_field', :id => '2'})
    assert_routing 'addresses/2/render_field', :controller => 'addresses', :action => 'render_field', :id => '2'
    assert_routing 'addresses/edit_associated', :controller => 'addresses', :action => 'edit_associated'
    assert_routing 'addresses/2/edit_associated', :controller => 'addresses', :action => 'edit_associated', :id => '2'
  end
end
