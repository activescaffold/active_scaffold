# frozen_string_literal: true

require 'action_dispatch/system_test_case'
require 'json'

module ActiveScaffold
  module TestSupport
    module Javascript
      class TestCase < ActionDispatch::SystemTestCase
        driven_by :selenium, using: :headless_chrome, screen_size: [1200, 900]

        teardown do
          FixtureStore.delete(@active_scaffold_fixture_id) if @active_scaffold_fixture_id
        end

        def fixture_html
          '<div class="active-scaffold"></div>'
        end

        def visit_javascript_fixture(html = fixture_html)
          FixtureStore.delete(@active_scaffold_fixture_id) if @active_scaffold_fixture_id
          @active_scaffold_fixture_id = FixtureStore.add(html)
          visit "/active_scaffold/javascript_test/#{@active_scaffold_fixture_id}"
          assert_selector 'html[data-active-scaffold-loaded="true"]', visible: :all
        end

        def insert_fixture_html(html, into: '#active-scaffold-javascript-fixture')
          execute_script <<~JS
            document.querySelector(#{into.to_json}).insertAdjacentHTML('beforeend', #{html.to_json});
          JS
        end

        def trigger_active_scaffold_event(name, target: 'document')
          execute_script <<~JS
            jQuery(#{javascript_target(target)}).trigger(#{active_scaffold_event_name(name).to_json});
          JS
        end

        def assert_javascript(expression, message = nil)
          assert evaluate_script(expression), message || "Expected JavaScript expression to be truthy: #{expression}"
        end

        def assert_no_javascript_errors
          errors = evaluate_script('window.activeScaffoldTestErrors || []')
          assert_empty errors, "JavaScript errors were reported:\n#{errors.join("\n")}"
        end

        private

        def active_scaffold_event_name(name)
          name = name.to_s
          name.include?(':') ? name : "as:#{name}"
        end

        def javascript_target(target)
          target == 'document' ? 'document' : "document.querySelector(#{target.to_json})"
        end
      end
    end
  end
end
