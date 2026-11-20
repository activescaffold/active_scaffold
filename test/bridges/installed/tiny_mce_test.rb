# frozen_string_literal: true

require_relative 'test_helper'

class InstalledTinyMceBridgeTest < InstalledBridgeTestCase
  include ActiveScaffold::Bridges::TinyMce::Helpers

  def test_tiny_mce_bridge_renders_configuration_and_html_safely
    bridge = assert_installed_bridge(:tiny_mce)
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:tinymce] = {toolbar: 'undo redo'}
    options = {name: 'record[name]', id: 'record_name', class: 'name-input', object: Company.new}

    assert_includes bridge.javascripts, 'active_scaffold/tiny_mce_bridge'
    assert_equal ['tiny_mce_bridge'], bridge.stylesheets

    html = active_scaffold_input_tinymce(column, options)
    assert_includes html, 'class="name-input mceEditor"'
    assert_includes html, '&quot;toolbar&quot;:&quot;undo redo&quot;'
    rendered = active_scaffold_show_tinymce(Struct.new(:name).new('<strong>Safe</strong>'), column)
    assert_predicate rendered, :html_safe?
  end

  def test_tiny_mce_bridge_supports_named_configuration_and_safe_javascript
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:tinymce_config] = :alternate
    options = {name: 'record[name]', id: 'record_name', object: Company.new}

    html = active_scaffold_input_tinymce(column, options)
    assert_includes html, '&quot;theme&quot;:&quot;alternate&quot;'
    assert_includes html, '&quot;toolbar&quot;:&quot;undo redo | format&quot;'

    source = File.read(File.join(ASSETS_PATH, 'tiny_mce_bridge.js'))
    registry = File.read(File.join(ASSETS_PATH, 'callback_registry.js'))
    assert_includes registry, 'ActiveScaffold.tinymceCallbacks'
    assert_not_includes source, 'eval('
    assert_includes source, "ActiveScaffold.resolveCallback('tinymceCallbacks'"
    assert_not_includes source, 'majorVersion'
    assert_not_includes source, 'userInit'
  end

  private

  def tinymce_configuration(config = :default)
    options =
      if config == :alternate
        {'theme' => 'alternate', 'toolbar' => 'undo redo | format'}
      else
        {'selector' => '.tinymce', 'theme' => 'silver'}
      end
    Struct.new(:options).new(options)
  end
end
