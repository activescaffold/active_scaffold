require 'test_helper'

class BridgeTest < Minitest::Test
  def setup
    @const_store = {}
  end

  def teardown; end

  def test__shouldnt_throw_errors
    ActiveScaffold::Bridges.run_all
  end

  def test__cds_bridge
    with_js_framework :prototype do
      ConstMocker.mock('CalendarDateSelect') do |cm|
        cm.remove
        assert(!bridge_will_be_installed('CalendarDateSelect'))
        cm.declare
        assert(bridge_will_be_installed('CalendarDateSelect'))
      end
    end
  end

  def test__file_column_bridge
    ConstMocker.mock('FileColumn') do |cm|
      cm.remove
      assert(!bridge_will_be_installed('FileColumn'))
      cm.declare
      assert(bridge_will_be_installed('FileColumn'))
    end
  end

  def test__paperclip_bridge
    ConstMocker.mock('Paperclip') do |cm|
      cm.remove
      assert(!bridge_will_be_installed('Paperclip'))
      cm.declare
      assert(bridge_will_be_installed('Paperclip'))
    end
  end

  def test__date_picker_bridge
    ConstMocker.mock('Jquery') do |jquery|
      jquery.declare
      ConstMocker.mock('Rails', jquery.const) do |rails|
        rails.declare
        ConstMocker.mock('Ui', jquery.const) do |cm|
          cm.remove
          assert(!bridge_will_be_installed('DatePicker'))
          cm.declare
          assert(bridge_will_be_installed('DatePicker'))
        end
      end
    end
    ActiveScaffold.js_framework = nil
  end

  def test__semantic_attributes_bridge
    ConstMocker.mock('SemanticAttributes') do |cm|
      cm.remove
      assert(!bridge_will_be_installed('SemanticAttributes'))
      cm.declare
      assert(bridge_will_be_installed('SemanticAttributes'))
    end
  end

  def test__paper_trail_bridge
    ConstMocker.mock('PaperTrail') do |cm|
      cm.remove
      assert(!bridge_will_be_installed('PaperTrail'))
      cm.declare
      assert(bridge_will_be_installed('PaperTrail'))
    end
  end

  protected

  def find_bridge(name)
    ActiveScaffold::Bridges[name.to_s.underscore.to_sym]
  end

  def bridge_will_be_installed(name)
    assert bridge = find_bridge(name), "No bridge found matching #{name}"

    bridge.install?
  end
end
