require 'test_helper'

module Config
  class UpdateTest < MiniTest::Test
    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
    end

    def test_copy_columns_from_create
      @config.create.columns = [:a, :c, :d]
      assert_equal [:a, :d], @config.create.columns.names
      @config.update.columns = @config.create.columns
      @config._load_action_columns
      assert_equal [:a, :c, :d], @config.update.columns.names
    end

    def test__params_for_columns__returns_all_params
      @config._load_action_columns
      @config.columns[:a].params.add :keep_a, :a_temp
      assert @config.columns[:a].params.include?(:keep_a)
      assert @config.columns[:a].params.include?(:a_temp)
    end

    def test_default_options
      refute @config.update.persistent
      refute @config.update.nested_links
      assert_equal 'Model stub', @config.update.label
    end

    def test_persistent
      @config.update.persistent = true
      assert @config.update.persistent
    end

    def test_nested_links
      old, @config.update.nested_links = @config.update.nested_links, true
      assert @config.update.nested_links
      @config.update.nested_links = old
    end

    def test_label
      label = 'update new monkeys'
      @config.update.label = label
      assert_equal label, @config.update.label
      I18n.backend.store_translations :en, :active_scaffold => {:change_model => 'Change %{model}'}
      @config.update.label = :change_model
      assert_equal 'Change Model stub', @config.update.label
      assert_equal 'Change record', @config.update.label('record')
    end
  end
end
