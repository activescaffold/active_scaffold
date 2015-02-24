require 'test_helper'

module Config
  class NestedTest < MiniTest::Test
    class ModelStubsController < ActionController::Base
      include ActiveScaffold::Core
      active_scaffold
    end

    def setup
      @config = ActiveScaffold::Config::Core.new(:model_stub)
    end

    def test_default_options
      assert @config.nested.shallow_delete
      assert_equal 'Add Existing Model stub', @config.nested.label
    end

    def test_label
      label = 'nested monkeys'
      @config.nested.label = label
      assert_equal label, @config.nested.label
      I18n.backend.store_translations :en, :active_scaffold => {:test_create_model => 'Add new %{model}'}
      @config.nested.label = :test_create_model
      assert_equal 'Add new Model stub', @config.nested.label
    end

    def test_shallow_delete
      @config.nested.shallow_delete = true
      assert @config.nested.shallow_delete
    end

    def test_add_link
      assert_raises(ArgumentError) { @config.nested.add_link :assoc_1 }
      config = @config
      ModelStubsController.class_eval do
        config.configure { nested.add_link :other_models }
      end
      link = @config.action_links['index']
      assert_equal 'ModelStubs', link.label
      assert_equal 'index', link.action
      assert_equal :after, link.position
      refute link.page?
      refute link.popup?
      refute link.confirm?
      assert link.inline?
      assert link.refresh_on_close
      assert_equal :other_models, link.parameters[:association]
      assert_equal :get, link.method
      assert_equal :member, link.type
      assert_equal :read, link.crud_type
      assert_equal :nested_authorized?, link.security_method
    end
  end
end
