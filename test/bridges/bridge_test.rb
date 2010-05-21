def dbg; require "ruby-debug"; debugger; end;

require File.join(File.dirname(__FILE__), '../test_helper.rb')


class Bridges::BridgeTest < Test::Unit::TestCase
  def setup
    @const_store = {}
  end
  
  def teardown
  end
  
  def test__shouldnt_throw_errors
    ActiveScaffold::Bridge.run_all
  end
  
  def test__cds_bridge
    ConstMocker.mock("CalendarDateSelect") do |cm|
      cm.remove
      assert(! bridge_will_be_installed("CalendarDateSelect"))
      cm.declare
      assert(bridge_will_be_installed("CalendarDateSelect"))
    end
  end
  
  def test__file_column_bridge
    ConstMocker.mock("FileColumn") do |cm|
      cm.remove
      assert(! bridge_will_be_installed("FileColumn"))
      cm.declare
      assert(bridge_will_be_installed("FileColumn"))
    end
  end
  
  def test__dependent_protect_bridge
    ConstMocker.mock("DependentProtect") do |cm|
      cm.remove
      assert(! bridge_will_be_installed("DependentProtect"))
      cm.declare
      assert(bridge_will_be_installed("DependentProtect"))
    end
  end
  
  def test__paperclip_bridge
    ConstMocker.mock("Paperclip") do |cm|
      cm.remove
      assert(! bridge_will_be_installed("Paperclip"))
      cm.declare
      assert(bridge_will_be_installed("Paperclip"))
    end
  end
  
  def test__unobtrusive_date_picker_bridge
    ConstMocker.mock("UnobtrusiveDatePicker") do |cm|
      cm.remove
      assert(! bridge_will_be_installed("UnobtrusiveDatePicker"))
      cm.declare
      assert(bridge_will_be_installed("UnobtrusiveDatePicker"))
    end
  end
  
  def test__validation_reflection_bridge
    class << ActiveRecord::Base; undef_method :reflect_on_validations_for; end rescue nil
    assert(! bridge_will_be_installed("ValidationReflection"))
    class << ActiveRecord::Base; define_method :reflect_on_validations_for, lambda{}; end
    assert(bridge_will_be_installed("ValidationReflection"))
  end
  
  def test__semantic_attributes_bridge
    ConstMocker.mock("SemanticAttributes") do |cm|
      cm.remove
      assert(! bridge_will_be_installed("SemanticAttributes"))
      cm.declare
      assert(bridge_will_be_installed("SemanticAttributes"))
    end
  end

protected

  def find_bridge(name)
    ActiveScaffold::Bridge.bridges.find{|b| b.name.to_s==name.to_s}
  end
  
  def bridge_will_be_installed(name)
    assert bridge=find_bridge(name), "No bridge found matching #{name}"
    
    bridge.instance_variable_get("@install_if").call
  end
end