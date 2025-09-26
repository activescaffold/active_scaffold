# frozen_string_literal: true

require 'test_helper'

module Config
  class UpdateTest < ActiveSupport::TestCase
    include ActiveScaffold::Helpers::ControllerHelpers

    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
    end

    def test_copy_columns_from_create
      @config.create.columns = %i[a c d]
      assert_equal %i[a d], @config.create.columns.visible_columns_names
      @config.update.columns = @config.create.columns
      assert_equal %i[a c d], @config.update.columns.visible_columns_names
    end

    def test__params_for_columns__returns_all_params
      @config.columns[:a].params.add :keep_a, :a_temp
      assert @config.columns[:a].params.include?(:keep_a)
      assert @config.columns[:a].params.include?(:a_temp)
    end

    def test_default_options
      assert_not @config.update.persistent
      assert_not @config.update.nested_links
      assert_equal 'Model stub', @config.update.label
    end

    def test_persistent
      @config.update.persistent = true
      assert @config.update.persistent
    end

    def test_nested_links
      old = @config.update.nested_links
      @config.update.nested_links = true
      assert @config.update.nested_links
      @config.update.nested_links = old
    end

    def test_label
      label = 'update new monkeys'
      @config.update.label = label
      assert_equal label, @config.update.label
      I18n.backend.store_translations :en, active_scaffold: {change_model: 'Change %<model>s'}
      @config.update.label = :change_model
      assert_equal 'Change Model stub', @config.update.label
      assert_equal 'Change record', @config.update.label('record')
    end
  end
end
