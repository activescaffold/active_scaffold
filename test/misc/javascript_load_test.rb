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

  def test_callback_registry_loads_before_jquery_ui_and_core
    loader = File.read(File.join(ASSETS_PATH, 'load.js'))
    registry_source = File.read(File.join(ASSETS_PATH, 'callback_registry.js'))

    registry = loader.index("loadScript(RAILS_ASSET_URL('/active_scaffold/callback_registry.js'))")
    jquery_ui = loader.index('await loadJQueryUI();')
    core = loader.index("loadScript(RAILS_ASSET_URL('/active_scaffold/active_scaffold.js'))")

    assert_operator registry, :<, jquery_ui
    assert_operator registry, :<, core
    assert_equal 'active_scaffold/callback_registry', ActiveScaffold::Assets.active_scaffold_javascripts(:core).first
    assert_includes registry_source, 'ActiveScaffold.datepickerCallbacks'
    assert_includes registry_source, 'ActiveScaffold.tinymceCallbacks'
    assert_not_includes registry_source, 'eval('
    assert_not_includes registry_source, 'DEPRECATION WARNING'
  end

  def test_bridges_do_not_evaluate_inline_settings_directly
    datepicker = File.read(File.join(ASSETS_PATH, 'date_picker_bridge.js'))
    tinymce = File.read(File.join(ASSETS_PATH, 'tiny_mce_bridge.js'))
    timepicker = File.read(File.expand_path('../../vendor/assets/javascripts/jquery-ui-timepicker-addon.js', __dir__))

    assert_not_includes datepicker, 'eval('
    assert_not_includes tinymce, 'eval('
    assert_not_includes timepicker, 'eval('
    assert_includes datepicker, 'ActiveScaffold.resolveDatepickerSetting'
    assert_includes tinymce, "ActiveScaffold.resolveCallback('tinymceCallbacks'"
    assert_includes timepicker, 'ActiveScaffold.resolveDatepickerSetting'
    assert_not_includes tinymce, 'majorVersion'
    assert_not_includes tinymce, 'userInit'
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
