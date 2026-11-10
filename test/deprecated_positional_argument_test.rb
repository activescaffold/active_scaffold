# frozen_string_literal: true

require 'test_helper'

class DeprecatedPositionalArgumentTest < ActiveSupport::TestCase
  def test_positional_argument_warns_and_returns_value
    ActiveScaffold.deprecator.expects(:warn).with(
      'Passing `force` positionally to `update_columns_options` is deprecated; ' \
      'use `force:` instead. Positional support will be removed in ActiveScaffold 4.5. ' \
      'Overrides must accept both forms during 4.4 and pass the argument to `super` as a keyword. ' \
      'See https://github.com/activescaffold/active_scaffold/blob/4-4-stable/CHANGELOG.rdoc'
    )

    value = ActiveScaffold.deprecated_positional_argument(
      true, ActiveScaffold::POSITIONAL_ARGUMENT_NOT_GIVEN,
      method_name: :update_columns_options, argument_name: :force, default: false
    )

    assert value
  end

  def test_keyword_argument_does_not_warn
    ActiveScaffold.deprecator.expects(:warn).never

    value = ActiveScaffold.deprecated_positional_argument(
      ActiveScaffold::POSITIONAL_ARGUMENT_NOT_GIVEN, true,
      method_name: :update_columns_options, argument_name: :force, default: false
    )

    assert value
  end

  def test_default_does_not_warn
    ActiveScaffold.deprecator.expects(:warn).never

    value = ActiveScaffold.deprecated_positional_argument(
      ActiveScaffold::POSITIONAL_ARGUMENT_NOT_GIVEN, ActiveScaffold::POSITIONAL_ARGUMENT_NOT_GIVEN,
      method_name: :update_columns_options, argument_name: :force, default: false
    )

    assert_not value
  end

  def test_argument_cannot_be_given_twice
    error = assert_raises ArgumentError do
      ActiveScaffold.deprecated_positional_argument(
        false, true,
        method_name: :update_columns_options, argument_name: :force, default: false
      )
    end

    assert_equal 'force was given both positionally and as a keyword', error.message
  end
end
