ActiveScaffold::Bridges.bridge "Dragonfly" do
  install do
    require File.join(File.dirname(__FILE__), "lib/form_ui")
    require File.join(File.dirname(__FILE__), "lib/list_ui")
    require File.join(File.dirname(__FILE__), "lib/dragonfly_bridge_helpers")
    require File.join(File.dirname(__FILE__), "lib/dragonfly_bridge")
    ActiveScaffold::Config::Core.send :include, ActiveScaffold::Bridges::Dragonfly::Lib::DragonflyBridge
  end
end