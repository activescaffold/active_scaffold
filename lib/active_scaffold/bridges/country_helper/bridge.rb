ActiveScaffold::Bridges.bridge "CountryHelper" do
  install do
    require File.join(File.dirname(__FILE__), "lib/country_helper_bridge.rb")
  end

  install? do
    true
  end
end
