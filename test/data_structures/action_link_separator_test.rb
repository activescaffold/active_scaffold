# frozen_string_literal: true

require 'test_helper'

class ActionLinkSeparatorTest < ActiveSupport::TestCase
  test 'exposes its weight and identifies itself as a separator' do
    separator = ActiveScaffold::DataStructures::ActionLinkSeparator.new(12)

    assert_equal 12, separator.weight
    assert_operator separator, :==, :separator
    assert_nil separator.name_to_cache
  end
end
