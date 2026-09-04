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
