# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold/test_support/javascript'

class JavascriptTestCaseTest < ActiveScaffold::TestSupport::Javascript::TestCase
  def fixture_html
    '<div class="active-scaffold"><button id="fixture-button">Test</button></div>'
  end

  def test_default_fixture_html
    default_html = ActiveScaffold::TestSupport::Javascript::TestCase.instance_method(:fixture_html).bind_call(self)

    assert_equal '<div class="active-scaffold"></div>', default_html
  end

  def test_loads_active_scaffold_and_supports_dynamic_fixtures
    visit_javascript_fixture

    assert_javascript 'window.ActiveScaffold && document.querySelector("#fixture-button")'
    insert_fixture_html '<span id="inserted-fixture">Inserted</span>'
    assert_selector '#inserted-fixture', text: 'Inserted'
    execute_script <<~JS
      jQuery(document).on('as:element_updated', function(event) {
        event.target.dataset.eventReceived = 'true';
      });
    JS
    trigger_active_scaffold_event :element_updated, target: '#inserted-fixture'
    assert_selector '#inserted-fixture[data-event-received="true"]'
    assert_no_javascript_errors
  end
end
