# frozen_string_literal: true

require 'test_helper'

class JavaScriptHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::JavascriptHelpers

  def test_javascript_literal_returns_html_safe_valid_json
    value = {
      html: '</script><script>alert("x")</script>',
      punctuation: "'\"\\&",
      separators: "\u2028\u2029"
    }

    literal = javascript_literal(value)

    assert_predicate literal, :html_safe?
    assert_equal value.deep_stringify_keys, JSON.parse(literal)
    assert_not_includes literal, '<'
    assert_not_includes literal, '>'
    assert_not_includes literal, '&'
    assert_not_includes literal, "\u2028"
    assert_not_includes literal, "\u2029"
  end
end
