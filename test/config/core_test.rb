require 'test_helper'

module Config
  class CoreTest < MiniTest::Test
    class ModelStubsController < ActionController::Base
      include ActiveScaffold::Core
    end
    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
      ModelStubsController.instance_variable_set :@active_scaffold_config, @config
    end

    def test_default_options
      refute @config.add_sti_create_links?
      refute @config.sti_children
      assert_equal [:create, :list, :search, :update, :delete, :show, :nested, :subform], @config.actions.to_a
      assert_equal :default, @config.frontend
      assert_equal :default, @config.theme
      assert_equal 'Model stub', @config.label(:count => 1)
      assert_equal 'ModelStubs', @config.label
    end

    def test_add_sti_children
      @config.sti_create_links = true
      refute @config.add_sti_create_links?
      @config.sti_children = [:a]
      assert @config.add_sti_create_links?
    end

    def test_sti_children
      @config.sti_children = [:a]
      assert_equal [:a], @config.sti_children
    end

    def test_actions
      assert @config.actions.include?(:create)
      @config.actions = [:list]
      refute @config.actions.include?(:create)
      assert_equal [:list], @config.actions.to_a
    end

    def test_form_ui_in_sti
      @config.columns << :type

      @config.sti_create_links = false
      @config.sti_children = [:model_stub]
      @config._configure_sti
      assert_equal :select, @config.columns[:type].form_ui
      assert_equal [['Model stub', 'ModelStub']], @config.columns[:type].options[:options]

      @config.columns[:type].form_ui = nil
      @config.sti_create_links = true
      @config._configure_sti
      assert_equal :hidden, @config.columns[:type].form_ui
    end

    def test_sti_children_links
      @config.sti_children = [:model_stub]
      @config.sti_create_links = true
      @config.action_links.add @config.create.link
      ModelStubsController.send(:_add_sti_create_links)
      assert_equal 'Create Model stub', @config.action_links[:new].label
      assert_equal 'rb_config/core_test/model_stubs', @config.action_links[:new].parameters[:parent_sti]
    end
  end
end
