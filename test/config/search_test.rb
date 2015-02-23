require 'test_helper'

module Config
  class SearchTest < MiniTest::Test
    def setup
      @config = ActiveScaffold::Config::Core.new :model_stub
      @default_link = @config.search.link
    end

    def teardown
      @config.search.link = @default_link
    end

    def test_default_options
      assert_equal :full, @config.search.text_search
      refute @config.search.live?
      assert_equal ' ', @config.search.split_terms
    end

    def test_text_search
      @config.search.text_search = :start
      assert_equal :start, @config.search.text_search
      @config.search.text_search = :end
      assert_equal :end, @config.search.text_search
      @config.search.text_search = false
      refute @config.search.text_search
    end

    def test_live
      @config.search.live = true
      assert @config.search.live?
    end

    def test_split_terms
      @config.search.split_terms = nil
      assert @config.search.split_terms.nil?
      @config.search.split_terms = ','
      assert_equal ',', @config.search.split_terms
    end

    def test_link_defaults
      link = @config.search.link
      refute link.page?
      refute link.popup?
      refute link.confirm?
      assert_equal 'show_search', link.action
      assert_equal 'Search', link.label
      assert link.inline?
      blank = {}
      assert_equal blank, link.html_options
      assert_equal :get, link.method
      assert_equal :collection, link.type
      assert_equal :read, link.crud_type
      assert_equal :search_authorized?, link.security_method
    end

    def test_setting_link
      @config.search.link = ActiveScaffold::DataStructures::ActionLink.new('update', :label => 'Monkeys')
      refute_equal @default_link, @config.search.link
    end
  end
end
