# frozen_string_literal: true

require_relative 'test_helper'

class InstalledDatePickerBridgeTest < InstalledBridgeTestCase
  def test_date_picker_bridge_is_automatically_enabled_by_jquery_ui_rails
    bridge = assert_installed_bridge(:date_picker)
    config = ActiveScaffold::Config::Core.new(:company)

    assert ActiveScaffold.jquery_ui_included?
    assert_equal :date_picker, config.columns[:date].form_ui
    assert_equal :datetime_picker, config.columns[:datetime].form_ui
    assert_equal I18n.locale.to_s, bridge.localization_data[:locale]
  end
end
