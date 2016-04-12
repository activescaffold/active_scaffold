class ActiveScaffold::Bridges::CountrySelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'country_select/country_select_bridge_helper.rb')
  end
end
