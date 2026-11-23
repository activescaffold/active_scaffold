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

  def test_params_for_preserves_page_and_sorting_for_the_requested_controller
    column = stub(name: :first_name)
    sorting = stub(first: [column, :desc])
    user = stub(user_sorting?: true, sorting: sorting)
    list = stub(user: user)
    config = stub(store_user_settings: false, actions: [:list], list: list)
    stubs(:active_scaffold_config).returns(config)
    stubs(:controller_path).returns('admin/model_stubs')
    stubs(:params).returns(ActionController::Parameters.new(controller: 'admin/model_stubs', page: 3))

    generated = params_for(controller: 'model_stubs')

    assert_equal 3, generated[:page]
    assert_equal :first_name, generated[:sort]
    assert_equal :desc, generated[:sort_direction]
  end

  def test_main_path_to_return_uses_an_explicit_return_location
    options = signed_return_to_options(return_to: '/dashboard')
    stubs(:params).returns(ActionController::Parameters.new(options))

    assert_equal '/dashboard', main_path_to_return
  end

  def test_main_path_to_return_targets_the_parent_of_a_singular_nested_scaffold
    nested = stub(
      belongs_to?: true,
      has_one?: false,
      param_name: :person_id,
      to_params: {person_id: '7'}
    )
    stubs(:nested?).returns(true)
    stubs(:nested).returns(nested)
    stubs(:params).returns(
      ActionController::Parameters.new(
        controller: 'contacts', parent_scaffold: 'people', association: 'contacts', person_id: '7'
      )
    )

    generated = main_path_to_return

    assert_equal 'people', generated[:controller]
    assert_equal 'index', generated[:action]
    assert_not generated.key?(:person_id)
    assert_not generated.key?(:association)
    assert_not generated.key?(:parent_scaffold)
  end

  def test_render_parent_options_targets_a_singular_nested_parent
    parent_scaffold = stub(controller_path: 'people')
    nested = stub(belongs_to?: false, has_one?: true, parent_scaffold: parent_scaffold, parent_id: '7')
    stubs(:nested?).returns(true)
    stubs(:nested).returns(nested)

    assert_equal({controller: 'people', action: :index, id: '7'}, render_parent_options)
  end

  def test_parent_sti_refresh_action_uses_the_parent_action_configuration
    create = stub(refresh_list: true)
    config = stub(actions: [:create], create: create)
    parent_controller = stub(active_scaffold_config: config)
    stubs(:parent_sti_controller).returns(parent_controller)
    stubs(:action_name).returns('create')

    assert_equal :index, render_parent_action
    assert_equal :index, render_parent_action
  end

  def test_render_parent_options_can_refresh_a_parent_sti_row
    parent_controller = stub(controller_path: 'vehicles')
    stubs(:nested?).returns(false)
    stubs(:parent_sti_controller).returns(parent_controller)
    stubs(:render_parent_action).returns(:row)
    stubs(:params_for).returns(controller: 'vehicles', action: :row, parent_sti: nil)
    instance_variable_set(:@record, stub(to_param: '9'))

    assert_equal({controller: 'vehicles', action: :index, parent_sti: nil, id: '9'}, render_parent_options)
  end

  def test_builds_through_a_singular_intermediate_association
    source = stub
    through = stub(collection?: false, name: :building)
    association = stub(through_reflection: through, source_reflection: source)
    parent = stub(building: :building)
    expects(:build_associated).with(source, :building).returns(:record)

    assert_equal :record, send(:build_through_associated, association, parent)
  end

  def test_builds_a_collection_through_chain_and_sets_the_inverse
    through = stub
    reverse = stub
    source = stub(reverse_association: reverse)
    association = stub(through_reflection: through, source_reflection: source)
    expects(:build_associated).with(through, :parent).returns(:intermediate)
    expects(:build_associated).with(source, :intermediate).returns(:record)
    expects(:save_record_to_association).with(:record, reverse, :intermediate)
    through.stubs(:collection?).returns(true)

    assert_equal :record, send(:build_through_associated, association, :parent)
  end

  def test_save_record_to_association_handles_collection_and_reverse_belongs_to
    target = []
    record = stub(association: stub(target: target))
    collection = stub(collection?: true, name: :people)
    send(:save_record_to_association, record, collection, :person)
    assert_equal [:person], target

    value = mock
    value.expects(:owner=).with(record)
    singular = stub(collection?: false)
    reverse = stub(belongs_to?: true, name: :owner)
    send(:save_record_to_association, record, singular, value, reverse)
  end

  private

  attr_reader :search_params

  def controller_params?(_value)
    false
  end
end
