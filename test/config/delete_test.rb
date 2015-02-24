require 'test_helper'

module Config
  class DeleteTest < MiniTest::Test
    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
      @default_link = @config.delete.link
    end

    def teardown
      @config.delete.link = @default_link
    end

    def test_link_defaults
      link = @config.delete.link
      refute link.page?
      refute link.popup?
      assert link.confirm?
      assert_equal 'destroy', link.action
      assert_equal 'Delete', link.label
      assert link.inline?
      blank = {}
      assert_equal blank, link.html_options
      assert_equal :delete, link.method
      assert_equal :member, link.type
      assert_equal :delete, link.crud_type
      assert_equal :delete_authorized?, link.security_method
    end

    def test_setting_link
      @config.delete.link = ActiveScaffold::DataStructures::ActionLink.new('update', :label => 'Monkeys')
      refute_equal @default_link, @config.delete.link
    end
  end
end
