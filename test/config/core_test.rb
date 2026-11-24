# frozen_string_literal: true

require 'test_helper'

module Config
  class CoreTest < ActiveSupport::TestCase
    class ModelStubsController < ApplicationController
      include ActiveScaffold::Core
    end

    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
      ModelStubsController.instance_variable_set :@active_scaffold_config, @config
    end

    def test_default_options
      assert_not @config.add_sti_create_links?
      assert_not @config.sti_children
      assert_equal %i[create list search update delete show nested subform], @config.actions.to_a
      assert_equal :default, @config.theme
      assert_equal 'Model stub', @config.label(count: 1)
      assert_equal 'ModelStubs', @config.label
      assert_equal %i[html js json xml], @config.default_formats
    end

    def test_default_formats_inherit_global_configuration_without_sharing_the_array
      formats = %i[html js]
      ActiveScaffold::Config::Core.stubs(:default_formats).returns(formats)
      config = ActiveScaffold::Config::Core.new(:model_stub)
      config.default_formats << :json

      assert_equal %i[html js json], config.default_formats
      assert_equal %i[html js], formats
      assert_equal %i[html js json xml], @config.default_formats
    end

    def test_unsafe_api_associations_defaults_to_unspecified
      assert_nil @config.unsafe_api_associations
    end

    def test_unsafe_api_associations_inherits_the_global_setting
      ActiveScaffold::Config::Core.stubs(:unsafe_api_associations).returns(false)
      config = ActiveScaffold::Config::Core.new(:model_stub)

      assert_equal false, config.unsafe_api_associations
      assert_equal false, config.new_user_settings({}, {}).unsafe_api_associations
    end

    def test_unsafe_api_associations_can_be_overridden_per_controller
      @config.unsafe_api_associations = true

      assert_equal true, @config.new_user_settings({}, {}).unsafe_api_associations
      assert_nil ActiveScaffold::Config::Core.unsafe_api_associations
    end

    def test_default_formats_can_be_overridden_per_controller
      @config.default_formats = [:html]

      assert_equal [:html], @config.new_user_settings({}, {}).default_formats
      assert_equal %i[html js json xml], ActiveScaffold::Config::Core.default_formats
    end

    def test_parameter_filter_defaults_preserve_existing_behavior
      assert_nil @config.conditions_from_params_allowed_columns
      assert_nil @config.conditions_from_params_excluded_columns
    end

    def test_parameter_filter_lists_inherit_without_sharing_arrays
      allowed = [:a]
      excluded = [:b]
      ActiveScaffold::Config::Core.stubs(:conditions_from_params_allowed_columns).returns(allowed)
      ActiveScaffold::Config::Core.stubs(:conditions_from_params_excluded_columns).returns(excluded)
      config = ActiveScaffold::Config::Core.new(:model_stub)

      config.conditions_from_params_allowed_columns << :id
      config.conditions_from_params_excluded_columns << :a

      assert_equal [:a], allowed
      assert_equal [:b], excluded
      assert_equal %i[a id], config.new_user_settings({}, {}).conditions_from_params_allowed_columns
      assert_equal %i[b a], config.user.conditions_from_params_excluded_columns
    end

    def test_add_sti_children
      @config.sti_create_links = true
      assert_not @config.add_sti_create_links?
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
      assert_not @config.actions.include?(:create)
      assert_equal [:list], @config.actions.to_a
      assert_raises(ArgumentError) { @config.new_user_settings({}, {}).create }
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
