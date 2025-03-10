require 'test_helper'

module Config
  class ShowTest < ActiveSupport::TestCase
    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
      @default_link = @config.show.link
    end

    def teardown
      @config.show.link = @default_link
    end

    def test_link_defaults
      link = @config.show.link
      assert_not link.page?
      assert_not link.popup?
      assert_not link.confirm?
      assert_equal 'show', link.action
      assert_equal 'Show', link.label
      assert link.inline?
      blank = {}
      assert_equal blank, link.html_options
      assert_equal :get, link.method
      assert_equal :member, link.type
      assert_equal :read, link.crud_type
      assert_equal :show_authorized?, link.security_method
    end

    def test_setting_link
      @config.show.link = ActiveScaffold::DataStructures::ActionLink.new('update', label: 'Monkeys')
      assert_not_equal @default_link, @config.show.link
    end

    def test_label
      label = 'show monkeys'
      @config.show.label = label
      assert_equal label, @config.show.label
      I18n.backend.store_translations :en, active_scaffold: {view_model: 'View %<model>s'}
      @config.show.label = :view_model
      assert_equal 'View Model stub', @config.show.label
      assert_equal 'View record', @config.show.label('record')
    end
  end
end
