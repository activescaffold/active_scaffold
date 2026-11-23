# frozen_string_literal: true

require 'test_helper'

class InplaceEditAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @car = Car.create!(brand: 'Private brand', model: 'Original model')
  end

  test 'inline updates reject columns without inplace_edit' do
    post "/cars/#{@car.id}/update_column.js", params: {column: 'brand', value: 'Changed'}

    assert_response :forbidden
    assert_equal 'Private brand', @car.reload.brand
    assert_not_includes response.body, 'Private brand'
  end

  test 'inline fields reject columns without inplace_edit' do
    get "/cars/#{@car.id}/render_field.js", params: {update_column: 'brand'}, xhr: true

    assert_response :forbidden
    assert_not_includes response.body, 'Private brand'
  end

  test 'inline endpoints reject unknown columns' do
    post "/cars/#{@car.id}/update_column.js", params: {column: 'unknown', value: 'Changed'}
    assert_response :forbidden

    get "/cars/#{@car.id}/render_field.js", params: {update_column: 'unknown'}, xhr: true
    assert_response :forbidden
  end

  test 'inline endpoints reject missing columns' do
    post "/cars/#{@car.id}/update_column.js", params: {value: 'Changed'}
    assert_response :forbidden

    get "/cars/#{@car.id}/render_field.js", xhr: true
    assert_response :forbidden
  end

  test 'inline updates still accept enabled columns' do
    post "/cars/#{@car.id}/update_column.js", params: {column: 'model', value: 'Changed model'}

    assert_response :success
    assert_equal 'Changed model', @car.reload.model
  end

  test 'inline fields still render enabled columns' do
    get "/cars/#{@car.id}/render_field.js", params: {update_column: 'model'}, xhr: true

    assert_response :success
    assert_includes response.body, 'Original model'
  end

  test 'inline updates still enforce column authorization' do
    Car.any_instance.stubs(:authorized_for?).returns(true)
    Car.any_instance.stubs(:authorized_for?).with(crud_type: :update, column: :model).returns(false)

    post "/cars/#{@car.id}/update_column.js", params: {column: 'model', value: 'Changed model'}

    assert_equal 'Original model', @car.reload.model
  end

  test 'inline fields still enforce column authorization' do
    Car.any_instance.stubs(:authorized_for?).returns(false)

    get "/cars/#{@car.id}/render_field.js", params: {update_column: 'model'}, xhr: true

    assert_response :forbidden
    assert_not_includes response.body, 'Original model'
  end
end
