# frozen_string_literal: true

require 'test_helper'

class AssetsHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::AssetsHelpers
  include ERB::Util

  def test_javascript_config_includes_plugins_and_jquery_ui_assets
    jquery_ui_was_defined = Jquery.const_defined?(:Ui, false)
    unless jquery_ui_was_defined
      jquery_ui = Module.new
      jquery_ui_rails = Module.new
      jquery_ui_rails.const_set(:VERSION, '8.0.1')
      jquery_ui.const_set(:Rails, jquery_ui_rails)
      Jquery.const_set(:Ui, jquery_ui)
    end
    ActiveScaffold.stubs(:js_config).returns(baseOption: true)
    ActiveScaffold.stubs(:javascripts).returns(%w[custom-plugin])
    ActiveScaffold.stubs(:jquery_ui_included?).returns(true)
    ActiveScaffold::Bridges.stubs(:all_javascripts).returns(%w[custom-bridge])
    ActiveScaffold::Bridges.stubs(:[]).with(:date_picker).returns(
      stub(localization_data: {closeText: 'Close'})
    )
    ActiveScaffold::Assets::JqueryUiManifest.stubs(:all_dependencies).returns(%w[jquery-ui/core])
    stubs(:content_security_policy_nonce).returns('test-nonce')
    stubs(:asset_path).with('custom-plugin', extname: '.js').returns('/assets/custom-plugin.js')
    stubs(:asset_path).with('custom-bridge', extname: '.js').returns('/assets/custom-bridge.js')
    stubs(:asset_path).with('jquery-ui/core', extname: '.js').returns('/assets/jquery-ui/core.js')

    html = send(:active_scaffold_javascript_config)

    assert_includes html, '"baseOption":true'
    assert_includes html, '"plugins":["/assets/custom-plugin.js"]'
    assert_includes html, '"bridges":["/assets/custom-bridge.js"]'
    assert_includes html, '"jqueryUiIncluded":true'
    assert_includes html, '"jqueryUi":["/assets/jquery-ui/core.js"]'
    assert_includes html, '"datepickerLocalization":{"closeText":"Close"}'
  ensure
    Jquery.send(:remove_const, :Ui) unless jquery_ui_was_defined
  end
end
