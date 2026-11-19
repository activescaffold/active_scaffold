# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

unless Jquery.const_defined?(:Ui, false)
  jquery_ui = Module.new
  jquery_ui_rails = Module.new
  jquery_ui_rails.const_set(:VERSION, '8.0.1')
  jquery_ui.const_set(:Rails, jquery_ui_rails)
  Jquery.const_set(:Ui, jquery_ui)
  require 'active_scaffold/assets/jquery_ui_manifest'
  Jquery.send(:remove_const, :Ui)
end

class AssetsTest < ActiveSupport::TestCase
  setup do
    ActiveScaffold.stubs(:stylesheets).returns(%w[plugin.css])
    ActiveScaffold.stubs(:javascripts).returns(%w[plugin.js])
    ActiveScaffold.stubs(:jquery_ui_included?).returns(false)
    ActiveScaffold::Bridges.stubs(:all_stylesheets).returns(%w[bridge.css])
    ActiveScaffold::Bridges.stubs(:all_javascripts).returns(%w[bridge.js])
  end

  def test_selects_stylesheets_for_each_load_mode
    assert_equal ['active_scaffold/core'], ActiveScaffold::Assets.active_scaffold_stylesheets(:core)
    assert_equal ['plugin.css'], ActiveScaffold::Assets.active_scaffold_stylesheets(:plugins)
    assert_equal ['bridge.css'], ActiveScaffold::Assets.active_scaffold_stylesheets(:bridges)
    assert_equal [], ActiveScaffold::Assets.active_scaffold_stylesheets(:jquery_ui)
    assert_equal %w[plugin.css bridge.css], ActiveScaffold::Assets.active_scaffold_stylesheets(:deps)
    assert_equal ['active_scaffold/core', 'plugin.css', 'bridge.css'],
                 ActiveScaffold::Assets.active_scaffold_stylesheets
  end

  def test_selects_javascripts_for_each_load_mode
    core = ['active_scaffold/callback_registry', 'jquery.ba-throttle-debounce', 'jquery.visible.min',
            'active_scaffold/jquery.editinplace', 'active_scaffold/active_scaffold']

    assert_equal core, ActiveScaffold::Assets.active_scaffold_javascripts(:core)
    assert_equal ['plugin.js'], ActiveScaffold::Assets.active_scaffold_javascripts(:plugins)
    assert_equal ['bridge.js'], ActiveScaffold::Assets.active_scaffold_javascripts(:bridges)
    assert_equal ['active_scaffold/callback_registry'], ActiveScaffold::Assets.active_scaffold_javascripts(:jquery_ui)
    assert_equal ['active_scaffold/callback_registry', 'plugin.js', 'bridge.js'],
                 ActiveScaffold::Assets.active_scaffold_javascripts(:deps)
    assert_equal core + ['plugin.js', 'bridge.js'], ActiveScaffold::Assets.active_scaffold_javascripts
  end

  def test_builds_javascript_code_for_each_load_mode
    ActiveScaffold.stubs(:js_config).returns(foo: 'bar')

    assert_equal 'ActiveScaffold.config = {"foo":"bar"};', ActiveScaffold::Assets.active_scaffold_js_code(:core)
    assert_equal '', ActiveScaffold::Assets.active_scaffold_js_code(:deps)
    assert_equal '', ActiveScaffold::Assets.active_scaffold_js_code(:jquery_ui)
    assert_equal '', ActiveScaffold::Assets.active_scaffold_js_code(:plugins)
    assert_equal '', ActiveScaffold::Assets.active_scaffold_js_code(:bridges)
    assert_equal "\nActiveScaffold.config = {\"foo\":\"bar\"};", ActiveScaffold::Assets.active_scaffold_js_code(:all)
  end

  def test_rejects_unknown_load_modes
    assert_raises(ArgumentError) { ActiveScaffold::Assets.active_scaffold_stylesheets(:unknown) }
    assert_raises(ArgumentError) { ActiveScaffold::Assets.active_scaffold_javascripts(:unknown) }
    assert_raises(ArgumentError) { ActiveScaffold::Assets.active_scaffold_js_code(:unknown) }
  end

  def test_includes_jquery_ui_dependencies_and_localization
    jquery_ui_was_defined = Jquery.const_defined?(:Ui, false)
    Jquery.const_set(:Ui, Module.new) unless jquery_ui_was_defined
    ActiveScaffold.stubs(:jquery_ui_included?).returns(true)
    ActiveScaffold::Assets::JqueryUiManifest.stubs(:all_dependencies).returns(%w[jquery-ui/core jquery-ui/widget])
    ActiveScaffold::Bridges.stubs(:[]).with(:date_picker).returns(stub(localization: 'localized();'))

    assert_includes ActiveScaffold::Assets.active_scaffold_stylesheets(:jquery_ui), 'jquery-ui/datepicker'
    assert_includes ActiveScaffold::Assets.active_scaffold_stylesheets(:jquery_ui), 'jquery-ui-theme'
    assert_equal ['active_scaffold/callback_registry', 'jquery-ui/core', 'jquery-ui/widget',
                  'jquery-ui-timepicker-addon', 'active_scaffold/date_picker_bridge',
                  'active_scaffold/draggable_lists'],
                 ActiveScaffold::Assets.active_scaffold_javascripts(:jquery_ui)
    assert_equal 'localized();', ActiveScaffold::Assets.active_scaffold_js_code(:jquery_ui)
  ensure
    Jquery.send(:remove_const, :Ui) unless jquery_ui_was_defined
  end

  def test_jquery_ui_manifest_returns_all_or_selected_dependencies
    manifest = ActiveScaffold::Assets::JqueryUiManifest

    assert_includes manifest.all_dependencies, 'jquery-ui/widgets/datepicker'
    assert_equal manifest.all_dependencies.uniq, manifest.all_dependencies
    assert_includes manifest.widget_dependencies(:sortable), 'jquery-ui/widgets/sortable'
    assert_not_includes manifest.widget_dependencies(:sortable), 'jquery-ui/widgets/datepicker'
    assert_equal manifest::CORE_FILES, manifest.widget_dependencies(:unknown)
  end
end

class AssetGeneratorsTest < ActiveSupport::TestCase
  def test_theme_generator_class_methods_skip_when_jquery_ui_is_not_installed
    Gem.loaded_specs.stubs(:[]).with('jquery-ui-rails').returns(nil)

    assert_nil ActiveScaffold::Assets::JqueryUiThemeGenerator.generate_if_needed
    assert_nil ActiveScaffold::Assets::JqueryUiThemeGenerator.generate!
    assert_not ActiveScaffold::Assets::JqueryUiThemeGenerator.needs_generation?
  end

  def test_theme_generator_class_methods_delegate_to_an_instance
    Gem.loaded_specs.stubs(:[]).with('jquery-ui-rails').returns(stub)
    generator = mock
    ActiveScaffold::Assets::JqueryUiThemeGenerator.stubs(:new).returns(generator)
    generator.expects(:generate_if_needed).returns(:generated_if_needed)
    generator.expects(:generate!).with(force: true).returns(:generated)
    generator.expects(:needs_generation?).returns(true)

    assert_equal :generated_if_needed, ActiveScaffold::Assets::JqueryUiThemeGenerator.generate_if_needed
    assert_equal :generated, ActiveScaffold::Assets::JqueryUiThemeGenerator.generate!(force: true)
    assert ActiveScaffold::Assets::JqueryUiThemeGenerator.needs_generation?
  end

  def test_css_dependencies_generator_writes_all_dependency_imports
    Dir.mktmpdir do |directory|
      Rails.stubs(:root).returns(Pathname(directory))
      ActiveScaffold::Assets.stubs(:active_scaffold_stylesheets).with(:deps).returns(%w[first second])

      ActiveScaffold::Assets::CssDepsGenerator.generate!

      output = File.read(File.join(directory, 'app/assets/stylesheets/active_scaffold/deps.scss'))
      assert_includes output, 'File autogenerated by ActiveScaffold'
      assert_includes output, "@use 'first';"
      assert_includes output, "@use 'second';"
    end
  end

  def test_theme_generator_processes_asset_paths_and_removes_other_erb
    Dir.mktmpdir do |directory|
      source = File.join(directory, 'theme.css.erb')
      target = Pathname(directory).join('generated/theme.css')
      File.write(source, "url(<%= image_path('jquery-ui/icon.png') %>) <%= ignored %>\n")
      generator = ActiveScaffold::Assets::JqueryUiThemeGenerator.allocate
      generator.instance_variable_set(:@source_path, source)
      generator.instance_variable_set(:@theme_path, target)

      assert generator.generate!(force: true)
      assert_equal "url('/assets/jquery-ui/icon.png') \n", File.read(target)
      assert_not generator.generate!
      assert_not generator.needs_generation?

      FileUtils.touch(source, mtime: Time.now.utc + 2)
      assert_predicate generator, :needs_generation?
    end
  end

  def test_theme_generator_skips_missing_sources
    generator = ActiveScaffold::Assets::JqueryUiThemeGenerator.allocate
    generator.instance_variable_set(:@source_path, '/missing/jquery-ui-theme.css.erb')
    generator.instance_variable_set(:@theme_path, Pathname('/missing/theme.css'))

    assert_not generator.source_exists?
    assert_nil generator.generate_if_needed
    assert_nil generator.generate!
  end
end
