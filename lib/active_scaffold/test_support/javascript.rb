# frozen_string_literal: true

# This file is intentionally not required by active_scaffold. Plugin test suites
# opt in with `require 'active_scaffold/test_support/javascript'`.
require 'active_scaffold/test_support/javascript/fixture_store'
require 'active_scaffold/test_support/javascript/application'
require 'active_scaffold/test_support/javascript/fixture_controller'
require 'active_scaffold/test_support/javascript/routes'

ActiveScaffold::TestSupport::Javascript::Application.boot!
ActiveScaffold::TestSupport::Javascript::Routes.install!

require 'active_scaffold/test_support/javascript/test_case'
