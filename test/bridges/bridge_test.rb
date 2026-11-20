# frozen_string_literal: true

require 'test_helper'

class BridgeTest < ActiveSupport::TestCase
  def setup
    @const_store = {}
  end

  def teardown; end

  def test__shouldnt_throw_errors
    assert_nothing_raised { ActiveScaffold::Bridges.run_all }
  end

  def test__date_picker_bridge
    ConstMocker.mock('Jquery') do |jquery|
      jquery.declare
      ConstMocker.mock('Rails', jquery.const) do |rails|
        rails.declare
        ConstMocker.mock('Ui', jquery.const) do |cm|
          cm.remove
          assert_not(bridge_will_be_installed?('DatePicker'))
          cm.declare
          assert(bridge_will_be_installed?('DatePicker'))
        end
      end
    end
  end

  def test__date_picker_bridge_can_be_forced_for_cdn_assets
    ActiveScaffold.jquery_ui_loaded = true

    assert bridge_will_be_installed?('DatePicker')
  ensure
    ActiveScaffold.jquery_ui_loaded = false
  end

  protected

  def find_bridge(name)
    ActiveScaffold::Bridges[name.to_s.underscore.to_sym]
  end

  def bridge_will_be_installed?(name)
    assert bridge = find_bridge(name), "No bridge found matching #{name}"

    bridge.install?
  end
end
