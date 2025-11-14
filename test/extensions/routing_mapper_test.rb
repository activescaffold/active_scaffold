# frozen_string_literal: true

require 'test_helper'

class RoutingMapperTest < ActionDispatch::IntegrationTest
  test 'rails routes' do
    assert_routing 'addresses', controller: 'addresses', action: 'index'
    assert_routing 'addresses/1', controller: 'addresses', action: 'show', id: '1'
    assert_routing 'addresses/1/list', controller: 'addresses', action: 'index', id: '1'
    assert_routing 'addresses/1/edit', controller: 'addresses', action: 'edit', id: '1'
    assert_routing({method: :patch, path: 'addresses/1'}, {controller: 'addresses', action: 'update', id: '1'})
    assert_routing({method: :delete, path: 'addresses/1'}, {controller: 'addresses', action: 'destroy', id: '1'})
    assert_routing({method: :post, path: 'addresses'}, {controller: 'addresses', action: 'create'})
  end

  test 'active scaffold routes' do
    assert_routing 'addresses/show_search', controller: 'addresses', action: 'show_search'
    assert_routing({method: 'post', path: 'addresses/mark'}, {controller: 'addresses', action: 'mark'})
    assert_routing({method: 'post', path: 'addresses/2/mark'}, {controller: 'addresses', action: 'mark', id: '2'})
    assert_routing({method: 'post', path: 'addresses/render_field'}, {controller: 'addresses', action: 'render_field'})
    assert_routing({method: 'post', path: 'addresses/2/render_field'}, {controller: 'addresses', action: 'render_field', id: '2'})
    assert_routing({method: 'post', path: 'addresses/2/update_column'}, {controller: 'addresses', action: 'update_column', id: '2'})
    assert_routing 'addresses/2/render_field', controller: 'addresses', action: 'render_field', id: '2'
    assert_routing 'addresses/edit_associated', controller: 'addresses', action: 'edit_associated'
    assert_routing 'addresses/2/edit_associated', controller: 'addresses', action: 'edit_associated', id: '2'
    assert_routing 'addresses/new_existing', controller: 'addresses', action: 'new_existing'
    assert_routing({method: 'post', path: 'addresses/add_existing'}, {controller: 'addresses', action: 'add_existing'})
    assert_routing({method: 'delete', path: 'addresses/2/destroy_existing'}, {controller: 'addresses', action: 'destroy_existing', id: '2'})
  end

  test 'rails routes with except' do
    assert_routing 'buildings/1', controller: 'buildings', action: 'show', id: '1'
    assert_routing 'buildings/1/edit', controller: 'buildings', action: 'edit', id: '1'
    assert_routing({method: :patch, path: 'buildings/1'}, {controller: 'buildings', action: 'update', id: '1'})
    assert_routing({method: :delete, path: 'buildings/1'}, {controller: 'buildings', action: 'destroy', id: '1'})
    assert_routing({method: :post, path: 'buildings'}, {controller: 'buildings', action: 'create'})

    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/buildings' }
    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/buildings/1/list' }
  end

  test 'active scaffold routes with except' do
    assert_routing 'buildings/show_search', controller: 'buildings', action: 'show_search'
    assert_routing({method: 'post', path: 'buildings/render_field'}, {controller: 'buildings', action: 'render_field'})
    assert_routing({method: 'post', path: 'buildings/2/render_field'}, {controller: 'buildings', action: 'render_field', id: '2'})
    assert_routing({method: 'post', path: 'buildings/2/update_column'}, {controller: 'buildings', action: 'update_column', id: '2'})
    assert_routing 'buildings/2/render_field', controller: 'buildings', action: 'render_field', id: '2'
    assert_routing 'buildings/edit_associated', controller: 'buildings', action: 'edit_associated'
    assert_routing 'buildings/2/edit_associated', controller: 'buildings', action: 'edit_associated', id: '2'

    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/buildings/2/mark', method: :post }
    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/buildings/2/destroy_existing', method: :delete }
  end

  test 'rails routes with only' do
    assert_routing 'cars/1/edit', controller: 'cars', action: 'edit', id: '1'
    assert_routing({method: :patch, path: 'cars/1'}, {controller: 'cars', action: 'update', id: '1'})

    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/cars', method: :post }
    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/cars/1' }
    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/cars/1/destroy', method: :delete }
  end

  test 'active scaffold routes with only' do
    assert_routing 'cars/show_search', controller: 'cars', action: 'show_search'
    assert_routing({method: 'post', path: 'cars/render_field'}, {controller: 'cars', action: 'render_field'})
    assert_routing({method: 'post', path: 'cars/2/render_field'}, {controller: 'cars', action: 'render_field', id: '2'})
    assert_routing({method: 'post', path: 'cars/2/update_column'}, {controller: 'cars', action: 'update_column', id: '2'})
    assert_routing 'cars/2/render_field', controller: 'cars', action: 'render_field', id: '2'

    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/cars/2/edit_associated' }
    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/cars/2/mark', method: :post }
    assert_raises(ActionController::RoutingError) { @routes.recognize_path '/cars/2/destroy_existing', method: :delete }
  end
end
