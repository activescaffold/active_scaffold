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

    def test_default_formats_can_be_overridden_per_controller
      @config.default_formats = [:html]

      assert_equal [:html], @config.new_user_settings({}, {}).default_formats
      assert_equal %i[html js json xml], ActiveScaffold::Config::Core.default_formats
    end

    def test_parameter_filter_defaults_preserve_existing_behavior
      assert_nil @config.conditions_from_params_allowed_columns
      assert_empty @config.conditions_from_params_excluded_columns
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
      assert_equal 'config/core_test/model_stubs', @config.action_links[:new].parameters[:parent_sti]
    end

    def test_add_active_scaffold_path_adds_path_before_active_scaffold_views
      original_view_paths = ModelStubsController.view_paths
      active_scaffold_path = File.realpath(
        File.join(ActiveScaffold::Config::Core.plugin_directory, 'app', 'views')
      )
      plugin_path = Rails.root.join('plugin/app/views').to_s

      ModelStubsController.add_active_scaffold_path(plugin_path)

      paths = ModelStubsController.view_paths.map(&:to_s)
      assert_operator paths.index(plugin_path), :<, paths.index(active_scaffold_path)
    ensure
      ModelStubsController.view_paths = original_view_paths
    end

    def test_link_for_association_as_scope
      link = ModelStubsController.link_for_association_as_scope(:recent, position: :before)

      assert_equal 'index', link.action
      assert_equal 'Recent', link.label
      assert_equal :before, link.position
      assert_equal :member, link.type
      assert_equal ModelStubsController.controller_path, link.controller
      assert_equal({named_scope: :recent}, link.parameters)
    end

    def test_after_config_callback_as_proc_runs_in_controller_context
      callback_context = nil
      callback = proc { callback_context = self }
      ActiveScaffold::Config::Core.after_config_callbacks << callback

      ModelStubsController.send(:_run_after_config_callbacks)

      assert_same ModelStubsController, callback_context
    ensure
      ActiveScaffold::Config::Core.after_config_callbacks.delete(callback)
    end

    def test_load_action_module_adds_array_of_links
      links = [
        ActiveScaffold::DataStructures::ActionLink.new(:first, type: :collection),
        ActiveScaffold::DataStructures::ActionLink.new(:second, type: :collection)
      ]
      @config.actions = [:create]
      @config.create.link = links

      ModelStubsController.send(:_load_action_modules)

      assert_same links.first, @config.action_links[:first]
      assert_same links.second, @config.action_links[:second]
    end

    def test_column_type_cast_for_active_model_attribute
      model = Class.new(ModelStub) do
        attribute :virtual_count, :integer
      end
      column = ActiveScaffold::DataStructures::Column.new(:virtual_count, model)

      assert_kind_of ActiveModel::Attribute, column.column
      assert_equal 12, ActiveScaffold::Core.column_type_cast('12', column.column, model)
    end

    def test_column_type_cast_for_mongoid_field
      model = Class.new do
        include Mongoid::Document

        field :virtual_count, type: Integer
      end

      assert_equal 12, ActiveScaffold::Core.column_type_cast('12', model.fields['virtual_count'], model)
    end
  end
end
