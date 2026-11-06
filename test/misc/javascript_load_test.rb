# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class JavascriptLoadTest < ActiveSupport::TestCase
  ASSETS_PATH = File.expand_path('../../app/assets/javascripts/active_scaffold', __dir__)

  def test_initial_setup_is_deferred_until_plugins_and_bridges_are_loaded
    loader = File.read(File.join(ASSETS_PATH, 'load.js'))
    core = File.read(File.join(ASSETS_PATH, 'active_scaffold.js'))

    defer_setup = loader.index('config.deferInitialSetup = true;')
    load_core = loader.index("loadScript(RAILS_ASSET_URL('/active_scaffold/active_scaffold.js'))")
    load_plugins = loader.index('await loadScripts(config.plugins);')
    load_bridges = loader.index('await loadScripts(config.bridges);')
    initialize = loader.index('await initializeActiveScaffold();')

    assert_operator defer_setup, :<, load_core
    assert_operator load_core, :<, load_plugins
    assert_operator load_plugins, :<, load_bridges
    assert_operator load_bridges, :<, initialize
    assert_includes core, 'if (!ActiveScaffold.config.deferInitialSetup)'
  end

  def test_plugin_ready_callbacks_run_before_initial_setup
    loader = File.read(File.join(ASSETS_PATH, 'load.js'))
    initialization = loader[/const initializeActiveScaffold = \(\) => .*?^  \}\);/m]

    ready_callback = initialization.index('jQuery(function() {')
    release_ready = initialization.index('window.jQuery.holdReady(false);')
    release_setup = initialization.index('config.deferInitialSetup = false;')
    setup = initialization.index('ActiveScaffold.setup(document);')

    assert_operator ready_callback, :<, release_setup
    assert_operator release_setup, :<, setup
    assert_operator ready_callback, :<, release_ready
  end

  def test_repeated_script_loads_share_the_same_promise
    loader = File.read(File.join(ASSETS_PATH, 'load.js'))

    assert_includes loader, 'if (scriptLoads.has(path)) return scriptLoads.get(path);'
    assert_includes loader, 'scriptLoads.set(path, promise);'
  end

  def test_load_scripts_accepts_a_null_list
    loader = File.read(File.join(ASSETS_PATH, 'load.js'))

    assert_includes loader, 'for (const path of paths || [])'
  end

  def test_jquery_ready_is_held_while_dependencies_load
    loader = File.read(File.join(ASSETS_PATH, 'load.js'))

    hold_ready = loader.index('window.jQuery.holdReady(true);')
    load_dependencies = loader.index('const loadDependencies = async () =>')
    initialize = loader.index('await initializeActiveScaffold();')
    release_ready = loader.index('window.jQuery.holdReady(false);')

    assert_operator hold_ready, :<, load_dependencies
    assert_operator initialize, :<, release_ready
  end
end
