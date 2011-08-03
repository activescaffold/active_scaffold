ActiveScaffold::Bridges.bridge "Ancestry" do
  install do
    require File.join(File.dirname(__FILE__), "lib/ancestry_bridge.rb")
  end
end
