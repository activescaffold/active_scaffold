# frozen_string_literal: true

require_relative 'test_helper'

class InstalledBridgeDetectionTest < InstalledBridgeTestCase
  def test_all_optional_gems_are_detected
    InstalledBridgeAssertions::BRIDGE_GEMS.each_key do |bridge_name|
      assert_installed_bridge(bridge_name)
    end
  end
end
