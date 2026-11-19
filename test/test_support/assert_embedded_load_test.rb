# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold/test_support/assert_embedded_load'

class AssertEmbeddedLoadTest < ActiveSupport::TestCase
  class AssertionContext
    include ActiveScaffold::TestSupport::AssertEmbeddedLoad

    attr_reader :requests, :responses, :selector, :options

    def initialize(elements)
      @elements = elements
      @requests = []
      @responses = []
    end

    def assert_select(selector, **options)
      @selector = selector
      @options = options
      yield @elements
    end

    def get(path)
      @requests << path
    end

    def assert_response(status)
      @responses << status
    end
  end

  def test_loads_each_embedded_component_and_asserts_success
    context = AssertionContext.new([{'href' => '/people'}, {'href' => '/projects'}])

    context.assert_embedded_load('#dashboard', count: 2)

    assert_equal '#dashboard .active-scaffold-component a.load-embedded[href]', context.selector
    assert_equal({count: 2}, context.options)
    assert_equal %w[/people /projects], context.requests
    assert_equal %i[success success], context.responses
  end

  def test_raises_when_no_supported_response_assertion_is_available
    context = Object.new.extend(ActiveScaffold::TestSupport::AssertEmbeddedLoad)

    error = assert_raises(RuntimeError) { context.assert_successful_response! }

    assert_equal 'No known assertion method for response', error.message
  end

  def test_legacy_require_path_warns_and_loads_the_new_implementation
    ActiveScaffold.deprecator.expects(:warn).with(
      'active_scaffold/testing/assert_embedded_load is deprecated; ' \
      'require active_scaffold/test_support/assert_embedded_load instead.'
    )

    load Rails.root.join('../../lib/active_scaffold/testing/assert_embedded_load.rb')

    assert_same ActiveScaffold::TestSupport::AssertEmbeddedLoad, ActiveScaffold::Testing::AssertEmbeddedLoad
  end
end
