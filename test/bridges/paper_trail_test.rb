# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold/bridges/paper_trail/actions'
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

class PaperTrailActionsTest < ActiveSupport::TestCase
  def test_deleted_action_has_own_authorization_filter
    base = deleted_records_action_base
    base.expects(:before_action).with(:deleted_authorized_filter, only: :deleted)

    base.include ActiveScaffold::Actions::DeletedRecords
  end

  def test_deleted_authorization_defaults_to_list_authorization
    action = deleted_records_action
    action.expects(:list_authorized?).returns(:authorized)

    assert_equal :authorized, action.send(:deleted_authorized?)
  end

  def test_deleted_authorization_filter_raises_when_unauthorized
    action = deleted_records_action
    action.stubs(:deleted_authorized?).returns(false)

    assert_raises ActiveScaffold::ActionNotAllowed do
      action.send(:deleted_authorized_filter)
    end
  end

  def test_deleted_records_query_can_be_overridden
    action = deleted_records_action
    action.define_singleton_method(:deleted_records_query) { :overridden_query }

    assert_equal :overridden_query, action.send(:deleted_records_query)
  end

  def test_deleted_records_query_returns_destroy_versions_for_model
    action = deleted_records_action
    action.stubs(:nested?).returns(false)
    destroys = mock
    query = mock

    ConstMocker.mock('PaperTrail') do |paper_trail|
      paper_trail.declare
      ConstMocker.mock('Version', paper_trail.const) do |version_mocker|
        version = version_mocker.declare
        version.expects(:destroys).returns(destroys)
        destroys.expects(:where).with(item_type: 'Address').returns(query)

        assert_same query, action.send(:deleted_records_query)
      end
    end
  end

  private

  def deleted_records_action
    base = deleted_records_action_base
    base.stubs(:before_action)
    base.include ActiveScaffold::Actions::DeletedRecords
    base.new
  end

  def deleted_records_action_base
    config = stub(actions: [], model: stub(name: 'Address'))
    Class.new do
      define_singleton_method(:active_scaffold_config) { config }

      delegate :active_scaffold_config, to: :class
    end
  end
end
