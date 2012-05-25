class ActiveScaffold::Bridges::CountryHelper < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "country_helper/country_helper_bridge.rb")
  end

  def self.install?
    true
  end
end
