# frozen_string_literal: true

require_relative 'test_helper'

class InstalledPaperTrailProject < Project
  has_paper_trail
end

class InstalledPaperTrailBridgeTest < InstalledBridgeTestCase
  def test_paper_trail_bridge_adds_deleted_records_to_versioned_models
    bridge = assert_installed_bridge(:paper_trail)
    bridge.prepare
    config = ActiveScaffold::Config::Core.new(:installed_paper_trail_project)

    assert_equal :get, ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING.dig(:collection, :deleted)
    assert_includes config.actions, :deleted_records
    assert_equal :read, config.deleted_records.crud_type
    assert_equal :changes, config.deleted_records.nested_link_label
    assert_equal 'member', config.deleted_records.nested_link_group
  end

  def test_paper_trail_deleted_route
    ActiveScaffold::Bridges::PaperTrail.prepare

    with_routing do |map|
      map.draw do
        concern :active_scaffold, ActiveScaffold::Routing::Basic.new
        resources :addresses, concerns: :active_scaffold
      end
      assert_routing '/addresses/deleted', controller: 'addresses', action: 'deleted'
    end
  end

  def test_paper_trail_deleted_action_authorization
    action = paper_trail_deleted_records_action
    action.expects(:list_authorized?).returns(:authorized)
    assert_equal :authorized, action.send(:deleted_authorized?)

    action.stubs(:deleted_authorized?).returns(false)
    assert_raises ActiveScaffold::ActionNotAllowed do
      action.send(:deleted_authorized_filter)
    end
  end

  def test_paper_trail_deleted_query_uses_real_version_api
    action = paper_trail_deleted_records_action
    action.stubs(:nested?).returns(false)
    destroys = mock
    query = mock
    PaperTrail::Version.expects(:destroys).returns(destroys)
    destroys.expects(:where).with(item_type: 'InstalledPaperTrailProject').returns(query)

    assert_same query, action.send(:deleted_records_query)
  end

  def test_paper_trail_deleted_action_reifies_a_paginated_version
    assert_installed_bridge(:paper_trail)
    restored_record = InstalledPaperTrailProject.new(name: 'Restored')
    version = stub(reify: restored_record)
    query = mock
    query.stubs(:count).returns(1)
    query.stubs(:offset).returns(query)
    query.stubs(:limit).returns([version])
    action = paper_trail_deleted_records_action
    action.stubs(:deleted_records_query).returns(query)
    action.stubs(:params).returns({})
    action.expects(:respond_to_action).with(:list).returns(:rendered)

    assert_equal :rendered, action.deleted
    assert_equal :deleted, action.instance_variable_get(:@pagination_action)
    assert_equal [restored_record], action.instance_variable_get(:@records)
  end

  def test_paper_trail_helper_filters_links_only_for_deleted_records
    base = Class.new do
      def display_action_links(action_links, *)
        action_links
      end
    end
    helper_class = Class.new(base) do
      include ActiveScaffold::Bridges::PaperTrail::Helper

      attr_accessor :current_action

      alias action_name current_action

      def filter_action_links_for_deleted(action_links, *)
        action_links.first(1)
      end
    end
    helper = helper_class.new
    helper.current_action = 'deleted'
    assert_equal [:show], helper.display_action_links(%i[show edit], nil, {})

    helper.current_action = 'list'
    assert_equal %i[show edit], helper.display_action_links(%i[show edit], nil, {})
  end

  private

  def paper_trail_deleted_records_action
    config = stub(
      actions: [],
      model: InstalledPaperTrailProject,
      list: stub(per_page: 15)
    )
    action_class = Class.new do
      define_singleton_method(:before_action) { |*| nil }
      define_singleton_method(:active_scaffold_config) { config }
      define_method(:active_scaffold_config) { config }
      include ActiveScaffold::Actions::DeletedRecords
    end
    action_class.new
  end
end
