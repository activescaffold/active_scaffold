# frozen_string_literal: true

require 'test_helper'

class ListActionTest < ActiveSupport::TestCase
  def test_core_get_row_delegates_to_get_record
    action = core_action.new
    action.expects(:get_record).with({crud_type: :update}).returns(:record)

    assert_equal :record, action.send(:get_row, crud_type: :update)
  end

  def test_get_row_prepares_list_associations_and_counts
    action = list_action.new
    action.expects(:set_includes_for_columns)
    action.expects(:cache_column_counts).with([:record])

    action.send(:get_row)

    assert_equal :record, action.record
  end

  def test_show_gets_record_without_list_row_preparation
    action = show_action
    action.expects(:set_includes_for_columns).with(:show)
    action.expects(:get_record)
    action.expects(:get_row).never

    action.send(:do_show)
  end

  def test_apply_filters_tracks_applied_default_and_requested_filters
    filters = filter_set do |set|
      set.add(:visibility) do |filter|
        filter.add(:all, conditions: {visible: [true, false]})
        filter.add(:visible, conditions: {visible: true})
      end
      set.add(:status) { |filter| filter.add(:active, conditions: {active: true}) }
    end
    action = filters_action(filters, visibility: :visible, status: :active)
    query = mock
    filtered_query = mock
    query.expects(:where).with({visible: true}).returns(filtered_query)
    filtered_query.expects(:where).with({active: true}).returns(:result)

    assert_equal :result, action.send(:apply_filters, query)
    states = action.instance_variable_get(:@filter_states)
    assert_equal({option: filters[:visibility][:visible], status: :applied, default: false, requested: true}, states[:visibility])
    assert_equal({option: filters[:status][:active], status: :applied, default: true, requested: true}, states[:status])
  end

  def test_apply_filters_tracks_disallowed_options
    filters = filter_set do |set|
      set.add(:visibility) do |filter|
        filter.add(:all, conditions: {})
        filter.add(:private, conditions: {}, security_method: :private_filter_allowed?)
      end
    end
    action = filters_action(filters, visibility: :private)
    action.stubs(:private_filter_allowed?).returns(false)

    assert_same action.query, action.send(:apply_filters, action.query)
    states = action.instance_variable_get(:@filter_states)
    assert_equal :disallowed, states[:visibility][:status]
    assert_equal filters[:visibility][:private], states[:visibility][:option]
  end

  def test_apply_filters_only_tracks_disallowed_group_when_requested
    filters = filter_set do |set|
      set.add(:visibility) do |filter|
        filter.security_method = :visibility_filter_allowed?
        filter.add(:all, conditions: {})
      end
    end
    action = filters_action(filters)
    action.stubs(:visibility_filter_allowed?).returns(false)

    action.send(:apply_filters, action.query)
    assert_nil action.instance_variable_get(:@filter_states)

    action = filters_action(filters, visibility: :all)
    action.stubs(:visibility_filter_allowed?).returns(false)
    action.send(:apply_filters, action.query)
    assert_equal :disallowed, action.instance_variable_get(:@filter_states)[:visibility][:status]
  end

  private

  def core_action
    Class.new do
      class << self
        def before_action(...); end
        def after_action(...); end
        def around_action(...); end
        def rescue_from(...); end
        def helper_method(...); end
      end

      include ActiveScaffold::Actions::Core
    end
  end

  def list_action
    base = Class.new do
      class << self
        def before_action(...); end
        def helper_method(...); end
      end

      attr_reader :record

      def get_row(_crud_type_or_security_options = :read)
        @record = :record
      end
    end

    Class.new(base) do
      include ActiveScaffold::Actions::List
    end
  end

  def filter_set(&)
    ActiveScaffold::DataStructures::Filters.new.tap(&)
  end

  def filters_action(filters, parameters = {})
    list_config = Struct.new(:filters, :refresh_with_header).new(filters, false)
    config = Struct.new(:list).new(list_config)
    query = mock
    base = Class.new do
      class << self
        def before_action(...); end
        def helper_method(...); end
      end

      attr_reader :params, :query

      define_method(:initialize) do
        @params = ActionController::Parameters.new(parameters)
        @query = query
      end

      define_method(:active_scaffold_config) { config }
    end

    Class.new(base) { include ActiveScaffold::Actions::List }.new
  end

  def show_action
    model = Struct.new(:primary_key).new(:id)
    config = Struct.new(:model, :actions).new(model, [:list])
    base = Class.new do
      define_singleton_method(:active_scaffold_config) { config }

      class << self
        def before_action(...); end
        def helper_method(...); end
      end

      delegate :active_scaffold_config, to: :class

      def get_record(_crud_type_or_security_options = :read); end
    end

    Class.new(base) do
      include ActiveScaffold::Actions::List
      include ActiveScaffold::Actions::Show
    end.new
  end
end
