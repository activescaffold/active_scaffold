ActiveScaffold::Bridges.bridge "CarrierWave" do
  install do
    require File.join(File.dirname(__FILE__), "lib/form_ui")
    require File.join(File.dirname(__FILE__), "lib/list_ui")
    require File.join(File.dirname(__FILE__), "lib/carrierwave_bridge_helpers")
    require File.join(File.dirname(__FILE__), "lib/carrierwave_bridge")
    ActiveScaffold::Config::Core.send :include, ActiveScaffold::Bridges::Carrierwave::Lib::CarrierwaveBridge
  end
end