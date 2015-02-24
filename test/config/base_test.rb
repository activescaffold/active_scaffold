require 'test_helper'

module Config
  class BaseTest < MiniTest::Test
    def setup
      @base = ActiveScaffold::Config::Base.new(ActiveScaffold::Config::Core.new(:model_stub))
    end

    def test_formats
      assert_equal [], @base.formats
      @base.formats << :pdf
      assert_equal [:pdf], @base.formats
      @base.formats = [:html]
      assert_equal [:html], @base.formats
    end
  end
end
