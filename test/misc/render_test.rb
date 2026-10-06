# frozen_string_literal: true

require 'test_helper'

class RenderTest < ActionController::TestCase
  tests AddressesController

  setup do
    @ui_elements = ActiveScaffold.ui_elements.deep_dup
  end

  teardown do
    ActiveScaffold.ui_elements.replace(@ui_elements)
    remove_adapter_helpers
  end

  test 'render activescaffold views' do
    get :index
    assert_select 'div.active-scaffold'
  end

  test 'render with a UI adapter using elements and helper overrides' do
    ActiveScaffold.set_element(:list_title, tag: :h1, attributes: {class: 'h3'})
    ActiveScaffold.add_element_attributes(:list_table, class: 'table table-striped')
    define_adapter_helper(:list_table_html) do |&block|
      content_tag(:div, capture(&block), class: 'table-responsive')
    end

    get :index

    assert_select 'h1.h3'
    assert_select 'div.table-responsive > table.list-table.table.table-striped'
  end

  private

  def define_adapter_helper(name, &)
    @adapter_helper_names ||= []
    @adapter_helper_names << name
    AddressesController._helpers.define_method(name, &)
  end

  def remove_adapter_helpers
    Array(@adapter_helper_names).each do |name|
      AddressesController._helpers.remove_method(name)
    end
  end
end
